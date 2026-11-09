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
) {
    enum class ColdPresentationState { BOOTSTRAP, BOOTSTRAP_SUBMITTED, LIVE }

    private val clock = KeyguardMaterialClock { nanos ->
        orb.frame(nanos)
        background.frame(nanos)
    }
    private var attached = false
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
        orb.shape = KeyguardHeaderMaterialView.Shape.ORB
        background.shape = KeyguardHeaderMaterialView.Shape.CARD_BACKGROUND
        // addView() returning is not proof that a hardware Canvas exists.
        // The retained child views publish attach/size/first-draw readiness;
        // all notifications stay within this controller and never touch the
        // WindowManager or the financial resolver.
        orb.onRendererStateChanged = { reconcileClock() }
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
        val scene = profile?.let {
            KeyguardMaterialScene(
                profile = if (isFull) it else it.neutralized(),
                full = isFull,
                appliedAtNanos = System.nanoTime(),
            )
        }
        val canAnimate = scene != null && animationMode != KeyguardCardAnimationMode.OFF && animationsAllowed
        val sceneVisualKey = scene?.profile?.visualKey
        selectedVisualKey = sceneVisualKey
        selectedBackgroundVisible = presentationMode == KeyguardCardPresentationMode.CARD &&
            animationMode == KeyguardCardAnimationMode.ORB_AND_BACKGROUND && scene != null
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
        orb.setBootstrapActive(needsBootstrap)
        val backgroundVisible = selectedBackgroundVisible
        background.setScene(scene, enabled = canAnimate && backgroundVisible)
        background.setBootstrapActive(needsBootstrap && backgroundVisible)
        background.visibility = if (backgroundVisible) View.VISIBLE else View.GONE
        // OFF and orb-only retain the precise, already validated static-card
        // appearance. The readability veil only belongs above an animated
        // material background.
        backgroundVeil.visibility = if (backgroundVisible) View.VISIBLE else View.GONE
        prepareSelectedPrograms(profile, animationMode, presentationMode, isFull, installViewProgram = !needsBootstrap)
        reconcileClock(canAnimate)
    }

    /** True means the caller must register its frame-commit observation before
     * the invalidation below can traverse the bootstrap frame. */
    fun requiresBootstrapForNextAttach(): Boolean = coldPresentationState != ColdPresentationState.LIVE

    /** Immutable ownership for a single bootstrap/commit/live transition. */
    fun currentBootstrapToken(): KeyguardBootstrapFrameToken? =
        bootstrapVisualKey?.let { visualKey ->
            if (coldPresentationState == ColdPresentationState.LIVE) null
            else KeyguardBootstrapFrameToken(bootstrapGeneration, visualKey)
        }

    fun onAttached() {
        attached = true
        if (coldPresentationState != ColdPresentationState.LIVE) {
            bootstrapCommitReceived = false
            orb.setBootstrapActive(true)
            background.setBootstrapActive(selectedBackgroundVisible)
        }
        // Invalidate once so the first Canvas draw can prove whether this
        // actual overlay is hardware accelerated.  No animation callback is
        // required for this traversal.
        orb.invalidate()
        background.invalidate()
        reconcileClock()
    }

    fun onDetached(reason: String) {
        attached = false
        orb.pause()
        background.pause()
        clock.stop()
    }

    fun stop(reason: String) = onDetached(reason)

    fun dispose() {
        runCatching { orb.context.contentResolver.unregisterContentObserver(animatorScaleObserver) }
        stop("dispose")
        artifacts.dispose()
        gpuPreparer.dispose()
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

    fun diagnostics(): KeyguardMaterialDiagnostics = KeyguardMaterialDiagnostics(
        requestedRenderer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) "RuntimeShader/AGSL" else "static-fallback",
        activeRenderer = when {
            mode == KeyguardCardAnimationMode.OFF -> "STATIC_BY_SETTING"
            coldPresentationState != ColdPresentationState.LIVE -> "BOOTSTRAP_PALETTE"
            orb.rendererFailure() != null -> "COMPILE_OR_UNIFORM_FAILED"
            orb.isRendererReady() -> "RuntimeShader/AGSL"
            else -> "WAITING_FOR_ATTACH_OR_DRAW"
        },
        hardwareAccelerated = orb.lastCanvasHardwareAcceleratedForDiagnostics(),
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
    )

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
)
