package com.fluvi.app.lockscreen.material

import android.graphics.Bitmap
import android.os.Build
import android.database.ContentObserver
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.View
import com.fluvi.app.R
import com.fluvi.app.lockscreen.KeyguardCardAnimationMode
import com.fluvi.app.lockscreen.KeyguardCardPresentationMode
import com.fluvi.app.lockscreen.KeyguardMainWorkEvidence
import java.util.IdentityHashMap

/** Identifies the exact bootstrap material which is permitted to enter LIVE
 * after a committed frame. The visual key carries privacy/effect selection;
 * the monotonic generation prevents an old callback from promoting a newer
 * scene that happens to share a View. */
internal data class KeyguardBootstrapFrameToken(
    val bootstrapGeneration: Long,
    val visualKey: String,
)

/** Owns scene application and one Choreographer clock for both retained
 * decorative views. It deliberately has no WindowManager or financial API. */
internal class KeyguardCardMaterialController(
    private val orb: KeyguardHeaderMaterialView,
    private val background: KeyguardHeaderMaterialView,
    private val backgroundVeil: View,
    private val artifacts: KeyguardShaderArtifactStore = KeyguardShaderArtifactStore(orb.context),
    private val gpuPreparer: KeyguardGpuMaterialPreparer = AndroidKeyguardGpuMaterialPreparer(),
    private val drawEvidenceEnabled: () -> Boolean = { false },
    private val mainWorkEvidence: KeyguardMainWorkEvidence? = null,
    private val drawEvidenceOwner: () -> Any? = { null },
    /** Test seam for the real isolated producer boundary. Production keeps
     * this as a no-op; it never participates in visibility policy. */
    private val isolatedOrbRenderBarrier: KeyguardOrbRenderBarrier = NoopKeyguardOrbRenderBarrier,
) {
    enum class ColdPresentationState { BOOTSTRAP, BOOTSTRAP_SUBMITTED, LIVE }

    private val clock = KeyguardMaterialClock(
        evidenceEnabled = drawEvidenceEnabled,
        onCallbackObserved = { frame, entry, exit ->
            if (attached) {
                orb.recordClockCallback(frame, entry, exit)
                if (background.visibility == View.VISIBLE) background.recordClockCallback(frame, entry, exit)
            }
        },
    ) { nanos ->
        orb.frame(nanos)
        background.frame(nanos)
    }
    private var attached = false
    private var attachmentCallbacksStart = 0
    private var attachmentStartsStart = 0
    private var attachmentStopsStart = 0
    private var attachmentIsolatedProducedStart = 0
    private var attachmentIsolatedPublishedStart = 0
    private var attachmentIsolatedDroppedStart = 0
    private var profile: KeyguardMaterialProfile? = null
    private var mode = KeyguardCardAnimationMode.ORB_ONLY
    private var presentationMode = KeyguardCardPresentationMode.CARD
    private var appliedConfiguration: MaterialConfiguration? = null
    private var animationsAllowed = readAnimationsEnabled()
    private var updateCount = 0
    private var noOpUpdateCount = 0
    private var preparationRequests = 0
    private var preparationCompletions = 0
    private var preparationFailures = 0
    private var gpuPreparationRequests = 0
    private var gpuPreparationCompletions = 0
    private var gpuPreparationFailures = 0
    private var coldPresentationState = ColdPresentationState.LIVE
    private var selectedVisualKey: String? = null
    private var exercisedVisualKey: String? = null
    /** A bootstrap commit belongs to an exact semantic material selection, not
     * merely to whatever scene happens to be current when a renderer callback
     * is delivered. */
    private var bootstrapGeneration = 0L
    private var bootstrapVisualKey: String? = null
    private var bootstrapCommitReceived = false
    /**
     * The API-34 standalone ORB producer is deliberately separate from the
     * legacy ViewRoot/Choreographer path.  It is only selected for the one
     * presentation we can isolate without changing the card, accessibility,
     * or interaction contracts.
     */
    private var isolatedOrbRequested = false
    private var isolatedOrbFailed = false
    /** A failed visual key stays on the established View route until the
     * semantic material actually changes; this avoids endless GPU retries. */
    private var isolatedOrbFailedVisualKey: String? = null
    private var isolatedOrbLeaseGeneration = 0L
    private var activeAttachment = 0L
    private var attachedRoot: View? = null
    private var latestOrbArtifact: KeyguardShaderArtifact? = null
    private var latestOrbScene: KeyguardMaterialScene? = null
    private var latestOrbPreviousScene: KeyguardMaterialScene? = null
    private var latestOrbPreviousArtifact: KeyguardShaderArtifact? = null
    private var isolatedTransitionStartedNanos = 0L
    private var isolatedOrbPausedTime: KeyguardMaterialTime? = null
    private var activeOrbLease: KeyguardOrbBufferLease? = null
    private val isolatedOrbRendererDelegate = lazy {
        KeyguardOrbBufferRenderer(
            onFirstPublished = ::onIsolatedOrbFirstPublished,
            onFailure = ::onIsolatedOrbFailure,
            onSizeChanged = ::onIsolatedOrbSizeChanged,
            barrier = isolatedOrbRenderBarrier,
        )
    }
    private val isolatedOrbRenderer: KeyguardOrbBufferRenderer
        get() = isolatedOrbRendererDelegate.value
    private var selectedBackgroundVisible = false
    private var expectedGpuPreparationCount = 0
    private val requiredGpuPreparationKeys = linkedSetOf<String>()
    private val readyGpuPreparationKeys = object : LinkedHashSet<String>() {
        override fun add(element: String): Boolean {
            val changed = super.add(element)
            while (size > 2) remove(first())
            return changed
        }
    }
    /** Artifact callbacks are asynchronous. This per-View selection prevents
     * an older effect/portal completion from occupying the sole prepared slot
     * after a newer configuration has been selected. */
    private val requestedProgramKeys = IdentityHashMap<KeyguardHeaderMaterialView, String>()
    /** A late artifact must not make the first authorized attach construct a
     * View-owned RuntimeShader on the visibility path. It is retained until
     * the already-visible bootstrap has committed. */
    private val deferredViewArtifacts = IdentityHashMap<KeyguardHeaderMaterialView, Pair<KeyguardShaderArtifact, String>>()
    private val animatorScaleObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
        override fun onChange(selfChange: Boolean) {
            val next = readAnimationsEnabled()
            if (next == animationsAllowed) return
            animationsAllowed = next
            // This is a user animation preference transition, not a new
            // material scene. Keep the scene/phase and only reconcile clock.
            reconcileClock()
        }
    }
    var onFirstOrbShaderDraw: ((Long) -> Unit)? = null
    /** Functional, per-bootstrap-draw acknowledgement. This must stay
     * separate from the one-shot diagnostic callback below. */
    var onBootstrapGeometryDrawn: ((KeyguardBootstrapFrameToken) -> Unit)? = null
    var onFirstBootstrapOrbDraw: ((Long) -> Unit)? = null
    var onLivePromoted: ((KeyguardBootstrapFrameToken) -> Unit)? = null
    /** Observational only; it never changes visibility or scene ownership. */
    var onPreparationStage: ((String, Map<String, Any?>) -> Unit)? = null

    private data class MaterialConfiguration(
        val profileVisualKey: String?,
        val animationMode: KeyguardCardAnimationMode,
        val presentationMode: KeyguardCardPresentationMode,
        val full: Boolean,
        /** Bitmap's object identity is the relevant fallback input. */
        val staticOrb: Bitmap?,
    )

    init {
        orb.drawEvidenceEnabled = drawEvidenceEnabled
        background.drawEvidenceEnabled = drawEvidenceEnabled
        orb.drawEvidenceOwner = drawEvidenceOwner
        background.drawEvidenceOwner = drawEvidenceOwner
        orb.mainWorkEvidence = mainWorkEvidence
        background.mainWorkEvidence = mainWorkEvidence
        orb.shape = KeyguardHeaderMaterialView.Shape.ORB
        background.shape = KeyguardHeaderMaterialView.Shape.CARD_BACKGROUND
        // addView() returning is not proof that a hardware Canvas exists.
        // The retained child views publish attach/size/first-draw readiness;
        // all notifications stay within this controller and never touch the
        // WindowManager or the financial resolver.
        orb.onRendererStateChanged = {
            reconcileIsolatedOrbTarget()
            reconcileClock()
        }
        background.onRendererStateChanged = { reconcileClock() }
        orb.onFirstShaderDraw = { observedAtUptimeMs ->
            // The shader draw can only happen after the explicit bootstrap
            // gate opened. Remembering this exact semantic scene lets a
            // compatible later attachment retain the established warm path.
            exercisedVisualKey = selectedVisualKey
            onFirstOrbShaderDraw?.invoke(observedAtUptimeMs)
        }
        orb.onBootstrapGeometryDrawn = {
            currentBootstrapToken()?.let { token -> onBootstrapGeometryDrawn?.invoke(token) }
        }
        orb.onFirstBootstrapDraw = { observedAtUptimeMs -> onFirstBootstrapOrbDraw?.invoke(observedAtUptimeMs) }
        orb.onPreparedProgramPromoted = { key ->
            onPreparationStage?.invoke("MATERIAL_PROGRAM_PROMOTED", mapOf("programKey" to key, "surface" to "orb"))
        }
        background.onPreparedProgramPromoted = { key ->
            onPreparationStage?.invoke("MATERIAL_PROGRAM_PROMOTED", mapOf("programKey" to key, "surface" to "background"))
        }
        runCatching {
            orb.context.contentResolver.registerContentObserver(
                Settings.Global.getUriFor(Settings.Global.ANIMATOR_DURATION_SCALE),
                false,
                animatorScaleObserver,
            )
        }
    }

    fun update(
        profile: KeyguardMaterialProfile?,
        animationMode: KeyguardCardAnimationMode,
        presentationMode: KeyguardCardPresentationMode = KeyguardCardPresentationMode.CARD,
        isFull: Boolean,
        staticOrb: Bitmap?,
    ) {
        val configuration = MaterialConfiguration(
            profileVisualKey = profile?.let { if (isFull) it.visualKey else it.neutralized().visualKey },
            animationMode = animationMode,
            presentationMode = presentationMode,
            full = isFull,
            staticOrb = staticOrb,
        )
        this.profile = profile
        this.mode = animationMode
        this.presentationMode = presentationMode
        if (appliedConfiguration == configuration) {
            noOpUpdateCount += 1
            reconcileClock()
            return
        }
        appliedConfiguration = configuration
        updateCount += 1
        val sceneAppliedAtNanos = System.nanoTime()
        val scene = profile?.let {
            KeyguardMaterialScene(
                profile = if (isFull) it else it.neutralized(),
                full = isFull,
                appliedAtNanos = sceneAppliedAtNanos,
            )
        }
        // The View has always retained phase across same-effect scene
        // updates and blended non-privacy transitions for 180 ms. Keep that
        // semantic contract in the isolated producer without reading/mutating
        // a View-owned RuntimeShader from its worker.
        val oldIsolatedScene = latestOrbScene
        val oldIsolatedArtifact = latestOrbArtifact
        val isolatedScene = scene?.let { candidate ->
            if (oldIsolatedScene != null && oldIsolatedScene.full == candidate.full &&
                oldIsolatedScene.profile.effectId == candidate.profile.effectId
            ) {
                val at = isolatedOrbPausedTime ?: oldIsolatedScene.timeAt(sceneAppliedAtNanos)
                candidate.anchoredAt(at, sceneAppliedAtNanos)
            } else candidate
        }
        val isolatedPrevious = if (oldIsolatedScene != null && isolatedScene != null &&
            oldIsolatedScene.full == isolatedScene.full
        ) oldIsolatedScene else null
        val canAnimate = scene != null && animationMode != KeyguardCardAnimationMode.OFF && animationsAllowed
        val sceneVisualKey = scene?.profile?.visualKey
        selectedVisualKey = sceneVisualKey
        selectedBackgroundVisible = presentationMode == KeyguardCardPresentationMode.CARD &&
            animationMode == KeyguardCardAnimationMode.ORB_AND_BACKGROUND && scene != null
        isolatedOrbRequested = canUseIsolatedOrb(scene, animationMode, presentationMode, canAnimate)
        if (isolatedOrbRequested && isolatedOrbFailedVisualKey != sceneVisualKey) {
            isolatedOrbFailed = false
            isolatedOrbFailedVisualKey = null
        }
        if (isolatedOrbRequested && latestOrbScene?.full == true && scene?.full == false &&
            isolatedOrbRendererDelegate.isInitialized()
        ) {
            // The old full-colour child layer must be retired before any
            // asynchronous artifact/layout callback can observe the neutral
            // scene. The View bootstrap is immediately privacy-effective.
            activeOrbLease = null
            isolatedOrbRenderer.retire("privacy-tightening")
        }
        if (!isolatedOrbRequested) {
            isolatedOrbFailed = false
            isolatedOrbFailedVisualKey = null
            activeOrbLease = null
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE &&
                isolatedOrbRendererDelegate.isInitialized()
            ) {
                isolatedOrbRenderer.retire("legacy-route")
            }
            // A legacy View needs to be restored after an eligible ORB route
            // is changed to CARD/static/older compatibility behavior.
            orb.visibility = View.VISIBLE
        }
        // Keep the legacy bootstrap token until an actual overlay root is
        // supplied. Controller-only callers/tests have no legal
        // AttachedSurfaceControl parent and therefore continue to exercise
        // the established bootstrap contract. The production isolated route
        // drops this gate only at real attachment.
        val needsBootstrap = canAnimate && scene?.profile?.animated == true &&
            exercisedVisualKey != sceneVisualKey
        if (needsBootstrap) {
            if (coldPresentationState == ColdPresentationState.LIVE ||
                bootstrapVisualKey != sceneVisualKey
            ) {
                bootstrapGeneration += 1L
                bootstrapVisualKey = sceneVisualKey
                coldPresentationState = ColdPresentationState.BOOTSTRAP
                bootstrapCommitReceived = false
            }
        } else {
            coldPresentationState = ColdPresentationState.LIVE
            bootstrapCommitReceived = false
            bootstrapVisualKey = null
        }
        orb.setStaticBitmap(staticOrb)
        orb.setScene(scene, enabled = canAnimate)
        // While the buffer producer obtains its first completed frame the
        // retained View supplies the same palette-correct bootstrap.  It is
        // not a commit dependency for the isolated route.
        orb.setBootstrapActive(needsBootstrap || isolatedOrbRequested)
        val backgroundVisible = selectedBackgroundVisible
        background.setScene(scene, enabled = canAnimate && backgroundVisible)
        background.setBootstrapActive(needsBootstrap && backgroundVisible)
        background.visibility = if (backgroundVisible) View.VISIBLE else View.GONE
        // OFF and orb-only retain the precise, already validated static-card
        // appearance. The readability veil only belongs above an animated
        // material background.
        backgroundVeil.visibility = if (backgroundVisible) View.VISIBLE else View.GONE
        latestOrbScene = isolatedScene
        latestOrbPreviousScene = isolatedPrevious
        latestOrbPreviousArtifact = if (isolatedPrevious != null) oldIsolatedArtifact else null
        isolatedTransitionStartedNanos = if (isolatedPrevious != null) sceneAppliedAtNanos else 0L
        prepareSelectedPrograms(
            profile,
            animationMode,
            presentationMode,
            isFull,
            installViewProgram = !needsBootstrap || isolatedOrbRequested,
        )
        reconcileIsolatedOrbTarget()
        reconcileClock(canAnimate)
    }

    /** True means the caller must register its frame-commit observation before
     * the invalidation below can traverse the bootstrap frame. */
    fun requiresBootstrapForNextAttach(): Boolean =
        !isolatedOrbRequested && coldPresentationState != ColdPresentationState.LIVE

    /** Immutable ownership for a single bootstrap/commit/live transition. */
    fun currentBootstrapToken(): KeyguardBootstrapFrameToken? =
        bootstrapVisualKey?.let { visualKey ->
            if (coldPresentationState == ColdPresentationState.LIVE) null
            else KeyguardBootstrapFrameToken(bootstrapGeneration, visualKey)
        }

    fun onAttached(attachment: Long = 0L, root: View? = null) {
        // Controller-only tests and detached compatibility callers do not
        // own an accessibility-overlay root. A child SurfaceControl cannot
        // be safely parented there, so retain the established View route.
        // Production KeyguardCardWindow always supplies its retained root.
        if (isolatedOrbRequested && root == null) {
            isolatedOrbRequested = false
            isolatedOrbFailed = false
            orb.setBootstrapActive(false)
        }
        if (!attached) {
            // add/remove can finish before View.onAttachedToWindow dispatch.
            // Such an undrawn attachment must not inherit the prior cadence.
            orb.beginAttachmentDrawEvidence(attachment)
            background.beginAttachmentDrawEvidence(attachment)
            attachmentCallbacksStart = clock.callbackCount
            attachmentStartsStart = clock.startCount
            attachmentStopsStart = clock.stopCount
            val buffer = if (isolatedOrbRendererDelegate.isInitialized()) isolatedOrbRenderer.snapshot() else null
            attachmentIsolatedProducedStart = buffer?.framesProduced ?: 0
            attachmentIsolatedPublishedStart = buffer?.framesPublished ?: 0
            attachmentIsolatedDroppedStart = buffer?.framesDropped ?: 0
        }
        attached = true
        activeAttachment = attachment
        attachedRoot = root
        if (isolatedOrbRequested && root != null) {
            // The dedicated producer has its own completed-buffer boundary;
            // a View bootstrap commit must never hold it in the legacy state.
            coldPresentationState = ColdPresentationState.LIVE
            bootstrapVisualKey = null
            bootstrapCommitReceived = false
        }
        if (isolatedOrbRequested) {
            isolatedOrbPausedTime?.let { paused ->
                latestOrbScene = latestOrbScene?.anchoredAt(paused, System.nanoTime())
                // A detached root owns no transition presentation. Retain
                // phase, but do not replay a stale colour transition into a
                // new authorization/attachment.
                latestOrbPreviousScene = null
                latestOrbPreviousArtifact = null
                isolatedTransitionStartedNanos = 0L
            }
            isolatedOrbPausedTime = null
        }
        if (isolatedOrbRequested && !isolatedOrbFailed) {
            // A new layer generation must not expose the legacy shader while
            // its first buffer is still pending. The bootstrap is visually
            // compatible but has no frame-commit/promotion authority here.
            orb.visibility = View.VISIBLE
            orb.setBootstrapActive(true)
        }
        if (!isolatedOrbRequested && coldPresentationState != ColdPresentationState.LIVE) {
            bootstrapCommitReceived = false
            orb.setBootstrapActive(true)
            background.setBootstrapActive(selectedBackgroundVisible)
        }
        // Invalidate once so the first Canvas draw can prove whether this
        // actual overlay is hardware accelerated.  No animation callback is
        // required for this traversal.
        orb.invalidate()
        background.invalidate()
        if (isolatedOrbRequested && root != null) {
            reconcileIsolatedOrbTarget(root)
        }
        reconcileClock()
    }

    fun onDetached(reason: String) {
        if (isolatedOrbRequested) {
            isolatedOrbPausedTime = latestOrbScene?.timeAt(System.nanoTime())
        }
        attached = false
        activeAttachment = 0L
        attachedRoot = null
        activeOrbLease = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE &&
            isolatedOrbRendererDelegate.isInitialized()
        ) {
            isolatedOrbRenderer.retire(reason)
        }
        // The child SurfaceControl is retired before WindowManager removes its
        // parent. Restore the View for a later legacy/fallback attachment.
        orb.visibility = View.VISIBLE
        if (isolatedOrbRequested && !isolatedOrbFailed) orb.setBootstrapActive(true)
        orb.pause()
        background.pause()
        clock.stop()
        orb.endAttachmentDrawEvidence()
        background.endAttachmentDrawEvidence()
    }

    fun stop(reason: String) = onDetached(reason)

    /** Snapshot only at an attachment boundary, after visibility work. No
     * percentile sorting or material-key construction on the draw path. */
    fun attachmentRenderSummary(): KeyguardAttachmentRenderSummary {
        val buffer = if (isolatedOrbRendererDelegate.isInitialized()) isolatedOrbRenderer.snapshot() else null
        return KeyguardAttachmentRenderSummary(
        clockCallbacks = clock.callbackCount - attachmentCallbacksStart,
        shaderCalls = orb.attachmentShaderCalls(),
        phaseAdvances = orb.attachmentPhaseAdvances(),
        animationStarts = clock.startCount - attachmentStartsStart,
        animationStops = clock.stopCount - attachmentStopsStart,
        clockRunning = clock.isRunning,
        liveState = coldPresentationState.name,
        orb = orb.attachmentDrawCadence(),
        background = background.attachmentDrawCadence(),
        orbGaps = orb.attachmentDrawGaps(),
        backgroundGaps = background.attachmentDrawGaps(),
        isolatedFramesProduced = (buffer?.framesProduced ?: 0) - attachmentIsolatedProducedStart,
        isolatedFramesPublished = (buffer?.framesPublished ?: 0) - attachmentIsolatedPublishedStart,
        isolatedFramesDropped = (buffer?.framesDropped ?: 0) - attachmentIsolatedDroppedStart,
        isolatedCompletionGapMaxMs = buffer?.completionGapMaxMs ?: 0L,
    )
    }

    fun dispose() {
        runCatching { orb.context.contentResolver.unregisterContentObserver(animatorScaleObserver) }
        stop("dispose")
        artifacts.dispose()
        gpuPreparer.dispose()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE &&
            isolatedOrbRendererDelegate.isInitialized()
        ) {
            isolatedOrbRenderer.dispose()
        }
    }

    /** Starts build-scoped source loading while the retained root is detached.
     * It grants neither visibility nor touch authority. */
    fun prepare(
        profile: KeyguardMaterialProfile?,
        animationMode: KeyguardCardAnimationMode,
        presentationMode: KeyguardCardPresentationMode,
        isFull: Boolean = true,
    ) = prepareSelectedPrograms(profile, animationMode, presentationMode, isFull, installViewProgram = true)

    /** Called only after a verified bootstrap commit for the current attached
     * root. GPU readiness never causes visibility or attachment by itself. */
    fun onBootstrapFrameCommitted(token: KeyguardBootstrapFrameToken): Boolean {
        if (!attached || coldPresentationState != ColdPresentationState.BOOTSTRAP ||
            currentBootstrapToken() != token
        ) return false
        bootstrapCommitReceived = true
        coldPresentationState = ColdPresentationState.BOOTSTRAP_SUBMITTED
        promoteLiveIfReady()
        return true
    }

    fun diagnostics(): KeyguardMaterialDiagnostics {
        val buffer = if (isolatedOrbRendererDelegate.isInitialized()) isolatedOrbRenderer.snapshot() else null
        return KeyguardMaterialDiagnostics(
        requestedRenderer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) "RuntimeShader/AGSL" else "static-fallback",
        activeRenderer = when {
            mode == KeyguardCardAnimationMode.OFF -> "STATIC_BY_SETTING"
            isolatedOrbRequested && !isolatedOrbFailed -> "HardwareBufferRenderer/SurfaceControl"
            coldPresentationState != ColdPresentationState.LIVE -> "BOOTSTRAP_PALETTE"
            orb.rendererFailure() != null -> "COMPILE_OR_UNIFORM_FAILED"
            orb.isRendererReady() -> "RuntimeShader/AGSL"
            else -> "WAITING_FOR_ATTACH_OR_DRAW"
        },
        hardwareAccelerated = (isolatedOrbRequested && !isolatedOrbFailed &&
            (buffer?.framesPublished ?: 0) > 0
            ) || orb.lastCanvasHardwareAcceleratedForDiagnostics(),
        shaderCreationCount = orb.shaderCreationCount() + background.shaderCreationCount(),
        animationStartCount = clock.startCount,
        animationStopCount = clock.stopCount,
        frameCallbackCount = clock.callbackCount,
        frameIntervalP50 = clock.framePercentile(.5),
        frameIntervalP95 = clock.framePercentile(.95),
        largeFrameGapCount = clock.largeGapCount,
        configurationUpdateCount = updateCount,
        configurationNoOpCount = noOpUpdateCount,
        preparationRequests = preparationRequests,
        preparationCompletions = preparationCompletions,
        preparationFailures = preparationFailures,
        gpuPreparationRequests = gpuPreparationRequests,
        gpuPreparationCompletions = gpuPreparationCompletions,
        gpuPreparationFailures = gpuPreparationFailures,
        coldPresentationState = coldPresentationState.name,
        artifactLoadCount = artifacts.diagnostics().assetLoadCount,
        artifactMetadataParseCount = artifacts.diagnostics().metadataParseCount,
        rendererFailure = orb.rendererFailure() ?: background.rendererFailure(),
        orb = orb.diagnostics(),
        background = background.diagnostics(),
        isolatedFramesProduced = buffer?.framesProduced ?: 0,
        isolatedFramesPublished = buffer?.framesPublished ?: 0,
        isolatedFramesDropped = buffer?.framesDropped ?: 0,
        isolatedFramesInFlight = buffer?.inFlight ?: 0,
        isolatedFramesReady = buffer?.ready ?: 0,
        isolatedFramesCompositorOwned = buffer?.compositorOwned ?: 0,
        isolatedCompletionGapMaxMs = buffer?.completionGapMaxMs ?: 0L,
    )
    }

    private fun reconcileClock(forceCanAnimate: Boolean? = null) {
        val canAnimate = forceCanAnimate ?: (profile != null && mode != KeyguardCardAnimationMode.OFF && animationsAllowed)
        // A genuinely static Header scene is rendered once; the selected
        // visual mode alone must not leave a 60 Hz callback running.
        if (!attached || !canAnimate || profile?.animated != true) {
            orb.pause()
            background.pause()
            clock.stop()
            return
        }
        if (isolatedOrbRequested && !isolatedOrbFailed) {
            // The dedicated renderer owns its own Choreographer. Main still
            // owns WindowManager, privacy, interaction and layer lifetime,
            // but never submits recurring ORB frames through this ViewRoot.
            orb.pause()
            background.pause()
            clock.stop()
            return
        }
        if (coldPresentationState != ColdPresentationState.LIVE) {
            // Bootstrap is a draw gate, not a new scene or phase origin. Keep
            // the current monotonic anchor intact for the first live frame.
            clock.stop()
            return
        }
        // Do not use View.isHardwareAccelerated as an eager attach-time gate:
        // it is false until the first actual Canvas draw for some overlays.
        val rendererReady = orb.canAnimateMaterial() &&
            (presentationMode != KeyguardCardPresentationMode.CARD ||
                mode != KeyguardCardAnimationMode.ORB_AND_BACKGROUND || background.canAnimateMaterial())
        if (rendererReady) {
            orb.resume()
            background.resume()
            clock.start()
        } else {
            orb.pause()
            background.pause()
            clock.stop()
        }
    }

    private fun readAnimationsEnabled(): Boolean = Settings.Global.getFloat(
        orb.context.contentResolver,
        Settings.Global.ANIMATOR_DURATION_SCALE,
        1f,
    ) > 0f

    /** Only the selected program is prepared. Artifact loading happens on its
     * own bounded lane; every destination View owns its RuntimeShader. */
    private fun prepareSelectedPrograms(
        profile: KeyguardMaterialProfile?,
        animationMode: KeyguardCardAnimationMode,
        presentationMode: KeyguardCardPresentationMode,
        isFull: Boolean,
        installViewProgram: Boolean,
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            profile == null || animationMode == KeyguardCardAnimationMode.OFF
        ) {
            requestedProgramKeys.clear()
            deferredViewArtifacts.clear()
            requiredGpuPreparationKeys.clear()
            expectedGpuPreparationCount = 0
            return
        }
        val effective = if (isFull) profile else profile.neutralized()
        requiredGpuPreparationKeys.clear()
        expectedGpuPreparationCount = if (
            presentationMode == KeyguardCardPresentationMode.CARD &&
                animationMode == KeyguardCardAnimationMode.ORB_AND_BACKGROUND
        ) 2 else 1
        prepareFor(orb, effective, installViewProgram)
        if (presentationMode == KeyguardCardPresentationMode.CARD &&
            animationMode == KeyguardCardAnimationMode.ORB_AND_BACKGROUND
        ) prepareFor(background, effective, installViewProgram)
        else {
            requestedProgramKeys.remove(background)
            deferredViewArtifacts.remove(background)
        }
    }

    private fun prepareFor(
        view: KeyguardHeaderMaterialView,
        profile: KeyguardMaterialProfile,
        installViewProgram: Boolean,
    ) {
        val requestedKey = "${profile.visualKey}|${profile.effectId}|${profile.usesPortal}|${view.shape}"
        requestedProgramKeys[view] = requestedKey
        preparationRequests += 1
        onPreparationStage?.invoke(
            "MATERIAL_PREPARE_REQUESTED",
            mapOf("effectId" to profile.effectId, "usesPortal" to profile.usesPortal),
        )
        artifacts.prepare(profile.effectId, profile.usesPortal) { result ->
            result.onSuccess { artifact ->
                preparationCompletions += 1
                onPreparationStage?.invoke("MATERIAL_ARTIFACT_READY", mapOf("programKey" to artifact.programKey))
                // Callback is delivered on the main looper. The worker never
                // mutates this instance after handoff.
                if (requestedProgramKeys[view] != requestedKey) {
                    onPreparationStage?.invoke("MATERIAL_PROGRAM_STALE", mapOf("programKey" to artifact.programKey))
                } else {
                    if (view === orb) latestOrbArtifact = artifact
                    if (installViewProgram) {
                        installViewProgram(view, artifact, requestedKey)
                    } else {
                        // Install the promotion input before asking the
                        // injected/worker preparer to run. The production
                        // preparer completes asynchronously, but this order
                        // is also required for an immediate successful
                        // completion: it must never open LIVE while the
                        // matching View-owned shader has not yet been
                        // retained for promotion.
                        deferredViewArtifacts[view] = artifact to requestedKey
                    }
                    // The worker-owned offscreen draw is independent of the
                    // View instance and can begin before any visible attach.
                    prepareGpuProgram(view, profile, artifact, requestedKey)
                    reconcileIsolatedOrbTarget()
                }
                reconcileClock()
            }.onFailure { error ->
                preparationFailures += 1
                onPreparationStage?.invoke("MATERIAL_PREPARE_FAILED", mapOf("error" to error.javaClass.simpleName))
            }
        }
    }

    private fun installViewProgram(
        view: KeyguardHeaderMaterialView,
        artifact: KeyguardShaderArtifact,
        requestedKey: String,
    ): Boolean {
        if (requestedProgramKeys[view] != requestedKey) return false
        return when (view.installPreparedShader(artifact)) {
            KeyguardHeaderMaterialView.ProgramPreparationResult.COMPILED,
            KeyguardHeaderMaterialView.ProgramPreparationResult.REUSED -> {
                deferredViewArtifacts.remove(view)
                onPreparationStage?.invoke(
                    "MATERIAL_PROGRAM_PREPARED",
                    mapOf("programKey" to artifact.programKey, "surface" to surfaceName(view)),
                )
                true
            }
            KeyguardHeaderMaterialView.ProgramPreparationResult.STALE -> {
                onPreparationStage?.invoke("MATERIAL_PROGRAM_STALE", mapOf("programKey" to artifact.programKey))
                false
            }
            KeyguardHeaderMaterialView.ProgramPreparationResult.FAILED -> {
                preparationFailures += 1
                onPreparationStage?.invoke("MATERIAL_PREPARE_FAILED", mapOf("programKey" to artifact.programKey))
                false
            }
            KeyguardHeaderMaterialView.ProgramPreparationResult.NOT_APPLICABLE -> false
        }
    }

    private fun prepareGpuProgram(
        view: KeyguardHeaderMaterialView,
        profile: KeyguardMaterialProfile,
        artifact: KeyguardShaderArtifact,
        requestedKey: String,
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU || requestedProgramKeys[view] != requestedKey) return
        val (width, height) = warmupDimensions(view)
        val cornerRadiusPx = 22f * orb.resources.displayMetrics.density
        val gpuKey = "${artifact.programKey}|${profile.visualKey}|${view.shape}|${width}x${height}|r=$cornerRadiusPx"
        requiredGpuPreparationKeys += gpuKey
        if (readyGpuPreparationKeys.contains(gpuKey)) {
            promoteLiveIfReady()
            return
        }
        gpuPreparationRequests += 1
        onPreparationStage?.invoke("MATERIAL_GPU_PREPARATION_STARTED", mapOf("programKey" to artifact.programKey, "surface" to surfaceName(view)))
        gpuPreparer.prepare(
            KeyguardGpuMaterialPreparationRequest(
                gpuKey,
                artifact,
                profile,
                view.shape,
                width,
                height,
                cornerRadiusPx = cornerRadiusPx,
            ),
        ) completion@{ result ->
            // The requested key captures both the selected program and the
            // effective (full/neutral) profile. A service-start prewarm is
            // therefore retained even before the first visible scene exists.
            if (requestedProgramKeys[view] != requestedKey) return@completion
            when (result.status) {
                KeyguardGpuMaterialPreparationStatus.READY -> {
                    gpuPreparationCompletions += 1
                    readyGpuPreparationKeys += result.request.key
                    onPreparationStage?.invoke("MATERIAL_GPU_PREPARATION_COMPLETED", mapOf("programKey" to artifact.programKey, "surface" to surfaceName(view)))
                    promoteLiveIfReady()
                }
                KeyguardGpuMaterialPreparationStatus.FAILED,
                KeyguardGpuMaterialPreparationStatus.NOT_SUPPORTED -> {
                    gpuPreparationFailures += 1
                    onPreparationStage?.invoke(
                        "MATERIAL_GPU_PREPARATION_FAILED",
                        mapOf(
                            "programKey" to artifact.programKey,
                            "surface" to surfaceName(view),
                            "reason" to (result.failure?.javaClass?.simpleName ?: result.status.name),
                        ),
                    )
                }
            }
        }
    }

    private fun warmupDimensions(view: KeyguardHeaderMaterialView): Pair<Int, Int> {
        if (view.width > 0 && view.height > 0) return view.width to view.height
        val resources = orb.resources
        return if (view.shape == KeyguardHeaderMaterialView.Shape.ORB) {
            val size = resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_orb_size)
            size to size
        } else {
            val density = resources.displayMetrics.density
            val width = (resources.displayMetrics.widthPixels - (32f * density).toInt()).coerceAtLeast(1)
            width to resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_card_height)
        }
    }

    private fun surfaceName(view: KeyguardHeaderMaterialView): String = if (view === orb) "orb" else "background"

    private fun canUseIsolatedOrb(
        scene: KeyguardMaterialScene?,
        animationMode: KeyguardCardAnimationMode,
        mode: KeyguardCardPresentationMode,
        canAnimate: Boolean,
    ): Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE &&
        mode == KeyguardCardPresentationMode.ORB &&
        animationMode == KeyguardCardAnimationMode.ORB_ONLY &&
        canAnimate && scene?.profile?.animated == true

    /**
     * This is called only from Main-owned controller/view lifecycle points.
     * It turns immutable material input into a lease for the dedicated
     * producer; it never gives that producer permission to attach a window or
     * to make a hidden root visible.
     */
    private fun reconcileIsolatedOrbTarget(rootOverride: View? = null) {
        if (!isolatedOrbRequested || isolatedOrbFailed ||
            Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE
        ) return
        val scene = latestOrbScene ?: return
        val artifact = latestOrbArtifact?.takeIf {
            it.effectId == scene.profile.effectId && it.usesPortal == scene.profile.usesPortal
        } ?: return
        val root = rootOverride ?: attachedRoot
        val (width, height) = warmupDimensions(orb)
        val attachment = if (attached) activeAttachment else 0L
        val previous = activeOrbLease
        val lease = if (previous != null && previous.attachment == attachment &&
            previous.visualKey == scene.profile.visualKey &&
            previous.programKey == artifact.programKey &&
            previous.width == width && previous.height == height
        ) previous else KeyguardOrbBufferLease(
            attachment = attachment,
            generation = ++isolatedOrbLeaseGeneration,
            visualKey = scene.profile.visualKey,
            programKey = artifact.programKey,
            width = width,
            height = height,
        )
        activeOrbLease = lease
        isolatedOrbRenderer.configure(
            KeyguardOrbBufferRenderSpec(
                lease = lease,
                artifact = artifact,
                scene = scene,
                previousScene = latestOrbPreviousScene,
                previousArtifact = latestOrbPreviousArtifact,
                transitionStartedNanos = isolatedTransitionStartedNanos,
            ),
        )
        if (attached && root != null && root.isAttachedToWindow && attachment != 0L) {
            isolatedOrbRenderer.attach(root, orb, attachment)
        }
    }

    private fun onIsolatedOrbFirstPublished(lease: KeyguardOrbBufferLease, observedAtUptimeMs: Long) {
        if (!attached || isolatedOrbFailed || activeOrbLease != lease ||
            activeAttachment != lease.attachment || attachedRoot?.isAttachedToWindow != true
        ) return
        // Unlike the legacy View route, this producer has no View bootstrap
        // commit to wait for.  This exact completed buffer transaction is its
        // first authorized live output.  A later scene update can legitimately
        // establish a new bootstrap, but the old View token must not strand an
        // already-publishing current layer in BOOTSTRAP.
        coldPresentationState = ColdPresentationState.LIVE
        bootstrapVisualKey = null
        bootstrapCommitReceived = false
        // The buffer layer exactly occupies the ORB child. Leaving the View
        // visible would create two animated producers underneath one root.
        // The placeholder remains only until a real completed buffer is
        // published; it is never a lifecycle/commit gate for this route.
        orb.setBootstrapActive(false)
        orb.visibility = View.INVISIBLE
        exercisedVisualKey = lease.visualKey
        onFirstOrbShaderDraw?.invoke(observedAtUptimeMs)
        onPreparationStage?.invoke(
            "MATERIAL_BUFFER_FIRST_OUTPUT",
            mapOf("programKey" to lease.programKey, "surface" to "orb"),
        )
    }

    /** Main-only response to an attached View layout change. The old child
     * layer is retired by the renderer before a differently sized lease can
     * be published, so a late buffer cannot be stretched into new bounds. */
    private fun onIsolatedOrbSizeChanged() {
        if (!attached || !isolatedOrbRequested || isolatedOrbFailed) return
        val current = activeOrbLease
        val (width, height) = warmupDimensions(orb)
        if (current != null && current.width == width && current.height == height) return
        activeOrbLease = null
        reconcileIsolatedOrbTarget(attachedRoot)
    }

    private fun onIsolatedOrbFailure(lease: KeyguardOrbBufferLease, error: Throwable) {
        if (activeOrbLease != lease) return
        isolatedOrbFailed = true
        isolatedOrbFailedVisualKey = lease.visualKey
        // A permanent bootstrap would turn a transient platform/output error
        // into a static ORB. Fall back to the established, already-prepared
        // View renderer immediately; a different material key may try the
        // bounded isolated route again, but this exact key will not spin.
        isolatedOrbRequested = false
        coldPresentationState = ColdPresentationState.LIVE
        bootstrapVisualKey = null
        bootstrapCommitReceived = false
        isolatedOrbRenderer.retire("producer-failure")
        orb.visibility = View.VISIBLE
        orb.setBootstrapActive(false)
        onPreparationStage?.invoke(
            "MATERIAL_BUFFER_FAILED",
            mapOf("programKey" to lease.programKey, "reason" to error.javaClass.simpleName),
        )
        // Compatibility fallback is the pre-existing View renderer. It uses
        // the same prepared artifact/scene and does not wait for a renderer
        // lock or alter visibility authority.
        orb.invalidate()
        reconcileClock()
    }

    private fun promoteLiveIfReady() {
        if (!attached || !bootstrapCommitReceived || coldPresentationState != ColdPresentationState.BOOTSTRAP_SUBMITTED) return
        if (requiredGpuPreparationKeys.size < expectedGpuPreparationCount ||
            !readyGpuPreparationKeys.containsAll(requiredGpuPreparationKeys)
        ) return
        val deferred = deferredViewArtifacts.entries.toList()
        if (deferred.any { (view, pending) -> !installViewProgram(view, pending.first, pending.second) }) return
        val promotedToken = currentBootstrapToken() ?: return
        coldPresentationState = ColdPresentationState.LIVE
        bootstrapVisualKey = null
        orb.setBootstrapActive(false)
        background.setBootstrapActive(false)
        val now = System.nanoTime()
        orb.prepareFirstLiveFrame(now)
        background.prepareFirstLiveFrame(now)
        onLivePromoted?.invoke(promotedToken)
        orb.invalidate()
        background.invalidate()
        reconcileClock()
    }
}

internal data class KeyguardAttachmentRenderSummary(
    val clockCallbacks: Int, val shaderCalls: Int, val phaseAdvances: Int,
    val animationStarts: Int, val animationStops: Int, val clockRunning: Boolean,
    val liveState: String, val orb: KeyguardDrawCadence.Snapshot, val background: KeyguardDrawCadence.Snapshot,
    val orbGaps: KeyguardDrawGapEvidence.Snapshot, val backgroundGaps: KeyguardDrawGapEvidence.Snapshot,
    val isolatedFramesProduced: Int, val isolatedFramesPublished: Int, val isolatedFramesDropped: Int,
    val isolatedCompletionGapMaxMs: Long,
)

internal data class KeyguardMaterialDiagnostics(
    val requestedRenderer: String,
    val activeRenderer: String,
    val hardwareAccelerated: Boolean,
    val shaderCreationCount: Int,
    val animationStartCount: Int,
    val animationStopCount: Int,
    val frameCallbackCount: Int,
    val frameIntervalP50: Long,
    val frameIntervalP95: Long,
    val largeFrameGapCount: Int,
    val configurationUpdateCount: Int,
    val configurationNoOpCount: Int,
    val preparationRequests: Int,
    val preparationCompletions: Int,
    val preparationFailures: Int,
    val gpuPreparationRequests: Int,
    val gpuPreparationCompletions: Int,
    val gpuPreparationFailures: Int,
    val coldPresentationState: String,
    val artifactLoadCount: Int,
    val artifactMetadataParseCount: Int,
    val rendererFailure: String?,
    val orb: KeyguardHeaderMaterialViewDiagnostics,
    val background: KeyguardHeaderMaterialViewDiagnostics,
    val isolatedFramesProduced: Int,
    val isolatedFramesPublished: Int,
    val isolatedFramesDropped: Int,
    val isolatedFramesInFlight: Int,
    val isolatedFramesReady: Int,
    val isolatedFramesCompositorOwned: Int,
    val isolatedCompletionGapMaxMs: Long,
)
