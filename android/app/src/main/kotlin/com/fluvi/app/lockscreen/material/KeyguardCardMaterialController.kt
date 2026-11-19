package com.fluvi.app.lockscreen.material

import android.graphics.Bitmap
import android.os.Build
import android.database.ContentObserver
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
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

/** A bounded, attachment-owned observation. It is never visibility or buffer
 * release authority and contains no scene, buffer, fence or child object. */
internal data class KeyguardIsolatedFirstHandoffSnapshot(
    val attachment: Long,
    val generation: Long,
    val slotId: Long,
    val useGeneration: Long,
    val childIdentity: Int,
    val times: KeyguardOrbFirstPublicationTimes,
    val commitReceiptAtUptimeMs: Long? = null,
    val commitMainAtUptimeMs: Long? = null,
    val bootstrapRetiredAtUptimeMs: Long? = null,
)

/** Frozen with an attachment and capture owner, never used as authority. */
internal data class KeyguardOrbRecoveryEpisode(
    val rendererId: Long,
    val originAttachment: Long,
    val originGeneration: Long,
    val childId: Int,
    val grantId: Int,
    val reason: KeyguardOrbPressureReason,
    val startedAt: Long,
    val offeredAt: Long,
    val opportunities: Int,
    val slots: List<KeyguardOrbOwnershipSlotSnapshot>,
    val attachment: Long,
    val inherited: Boolean,
    val claimedAt: Long?,
    val firstViewDrawAt: Long? = null,
    val restoredAt: Long? = null,
    val anchor: KeyguardMaterialTime? = null,
    val transitionPreserved: Boolean = false,
)

private fun KeyguardOrbPressureTicket.episode(
    attachment: Long, inherited: Boolean, claimedAt: Long?, restoredAt: Long? = null,
    anchor: KeyguardMaterialTime? = null,
) = KeyguardOrbRecoveryEpisode(rendererId, lease.attachment, lease.generation,
    System.identityHashCode(child), System.identityHashCode(grant), reason, startedAt, offeredAt,
    opportunities, slots, attachment, inherited, claimedAt, restoredAt = restoredAt, anchor = anchor)

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
    /** Test-only producer readback seam. The controller captures it once;
     * runtime hook changes cannot affect an established attachment. */
    private val isolatedOrbFrameObserver: KeyguardOrbBufferFrameObserver =
        KeyguardOrbBufferRendererTestHooks.frameObserver,
    /** Test-only Main submission observation. It carries no presentation
     * authority and is captured with the producer observer. */
    private val isolatedOrbPublicationObserver: KeyguardOrbBufferPublicationObserver =
        KeyguardOrbBufferRendererTestHooks.publicationObserver,
    /** Captured at controller construction; never a cross-thread user input. */
    private val isolatedOrbMaterialTimeSource: KeyguardOrbMaterialTimeSource =
        KeyguardOrbBufferRendererTestHooks.materialTimeSource,
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
    private var attachmentPositionSubmittedStart = 0
    private var attachmentPositionSuppressedStart = 0
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
    /** Separate from a producer error: old physical uses can remain owned
     * across visual-key changes and new attachments on this same renderer. */
    private var pressureLatch: KeyguardOrbPressureTicket? = null
    private var pressureClaimedAt: Long? = null
    private var pressureRestoredAt: Long? = null
    private var pressureRetryAfterAttachment = 0L
    private var recoveryEpisode: KeyguardOrbRecoveryEpisode? = null
    private var recoveryEpisodeTicket: KeyguardOrbPressureTicket? = null
    private var recoveryEpisodeOwner: Any? = null
    private var withdrawalWorkerSnapshot: KeyguardOrbBufferRendererSnapshot? = null
    private var withdrawalWorkerOwner: Any? = null
    private val isolatedOrbEffective: Boolean
        get() = isolatedOrbRequested && !isolatedOrbFailed && pressureLatch == null
    private val effectiveRoute: String
        get() = when {
            mode == KeyguardCardAnimationMode.OFF || profile == null -> "UNAVAILABLE"
            isolatedOrbRequested && pressureLatch != null -> "PRESSURE_VIEW"
            isolatedOrbEffective -> "ISOLATED"
            isolatedOrbFailedVisualKey != null -> "PRODUCER_ERROR_VIEW"
            else -> "COMPATIBLE_VIEW"
        }
    /** True only when the detached retained-root path selected preparation of
     * the persistent isolated producer itself. */
    private var detachedIsolatedBackendSelected = false
    // An explicit detached preparation is a one-shot request, never a display
    // grant. In particular, callbacks during an authorized add must not
    // silently start another detached render.
    private var detachedPrimeArmed = false
    private var authorizedShowPending = false
    private var submittedVisibleScene: KeyguardMaterialScene? = null
    private var submittedVisibleArtifact: KeyguardShaderArtifact? = null
    private var submittedVisibleAttachment = 0L
    private var submittedVisibleRoot: View? = null
    private var withdrawalAttachment = 0L
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
    private var restrictiveTransitionActive = false
    private var restrictiveReconcilePending = false
    private var currentFirstPublication: KeyguardOrbFirstPublicationToken? = null
    private var firstHandoffToken: KeyguardOrbFirstPublicationToken? = null
    private var firstHandoffCaptureOwner: Any? = null
    private var firstHandoff: KeyguardIsolatedFirstHandoffSnapshot? = null
    private val isolatedOrbRendererDelegate = lazy {
        KeyguardOrbBufferRenderer(
            onFirstPublished = ::onIsolatedOrbFirstPublished,
            onFirstCommitReceived = ::onIsolatedOrbFirstCommitReceived,
            onFirstCommitted = ::onIsolatedOrbFirstCommitted,
            onFailure = ::onIsolatedOrbFailure,
            onPressure = ::onIsolatedOrbPressure,
            onCapacityRestored = ::onIsolatedOrbCapacityRestored,
            onSizeChanged = ::onIsolatedOrbSizeChanged,
            barrier = isolatedOrbRenderBarrier,
            frameObserver = isolatedOrbFrameObserver,
            publicationObserver = isolatedOrbPublicationObserver,
            materialTimeSource = isolatedOrbMaterialTimeSource,
            timingOwner = drawEvidenceOwner,
            onLayerHideSubmitted = { submission ->
                onIsolatedLayerHideSubmitted?.invoke(submission)
            },
            onDetachedBackendPrepared = { lease, observedAtUptimeMs ->
                // A detached completion proves the actual persistent
                // HardwareBufferRenderer path is prepared.  It still has no
                // attachment/layer, and the later current lease must render
                // and publish independently after authorization.
                if (!attached && isolatedOrbRequested && activeOrbLease == lease) {
                    onPreparationStage?.invoke(
                        "MATERIAL_ISOLATED_BACKEND_PREPARED",
                        mapOf(
                            "programKey" to lease.programKey,
                            "leaseAttachment" to lease.attachment,
                            "leaseGeneration" to lease.generation,
                            "width" to lease.width,
                            "height" to lease.height,
                            "preparedAtUptimeMs" to observedAtUptimeMs,
                        ),
                    )
                }
            },
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
    /** Main-only observation of the exact lease whose child-layer withdrawal
     * was submitted. It cannot change the renderer's visibility decision or
     * worker/fence ownership. */
    var onIsolatedLayerHideSubmitted: ((KeyguardOrbLayerHideSubmission) -> Unit)? = null
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
            if (pressureLatch != null && recoveryEpisodeOwner != null &&
                recoveryEpisodeOwner === drawEvidenceOwner() && recoveryEpisode?.firstViewDrawAt == null
            ) recoveryEpisode = recoveryEpisode?.copy(firstViewDrawAt = observedAtUptimeMs)
            onFirstOrbShaderDraw?.invoke(observedAtUptimeMs)
        }
        orb.onCurrentShaderDraw = { scene ->
            if (attached && activeAttachment > 0L && attachedRoot?.isAttachedToWindow == true &&
                !isolatedOrbEffective && latestOrbScene?.profile?.visualKey == scene.profile.visualKey &&
                latestOrbScene?.full == scene.full
            ) {
                submittedVisibleScene = latestOrbScene
                submittedVisibleArtifact = latestOrbArtifact
                submittedVisibleAttachment = activeAttachment
                submittedVisibleRoot = attachedRoot
            }
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
        val priorConfiguration = appliedConfiguration
        val restrictiveTransition = priorConfiguration?.full == true && !isFull
        if (restrictiveTransition) restrictiveTransitionActive = true
        var coherentRestrictedView = false
        try {
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
        val visible = submittedVisibleScene?.takeIf {
            attached && activeAttachment > 0L && submittedVisibleAttachment == activeAttachment &&
                submittedVisibleRoot === attachedRoot && attachedRoot?.isAttachedToWindow == true &&
                priorConfiguration?.presentationMode == presentationMode &&
                priorConfiguration.animationMode == animationMode &&
                isolatedScene != null && it.full == isolatedScene.full
        }
        val sameDesiredVisual = oldIsolatedScene != null && isolatedScene != null &&
            oldIsolatedScene.full == isolatedScene.full &&
            oldIsolatedScene.profile.visualKey == isolatedScene.profile.visualKey
        val keepTransition = visible != null && sameDesiredVisual && latestOrbPreviousScene != null &&
            isolatedTransitionStartedNanos > 0L
        val isolatedPrevious = when {
            keepTransition -> latestOrbPreviousScene
            visible != null && isolatedScene != null &&
                visible.profile.visualKey != isolatedScene.profile.visualKey -> visible
            else -> null
        }
        val previousArtifact = when {
            keepTransition -> latestOrbPreviousArtifact
            isolatedPrevious != null -> submittedVisibleArtifact ?: oldIsolatedArtifact
            else -> null
        }
        val transitionStart = if (keepTransition) isolatedTransitionStartedNanos
            else if (isolatedPrevious != null) sceneAppliedAtNanos else 0L
        if (visible == null) {
            submittedVisibleScene = null
            submittedVisibleArtifact = null
            submittedVisibleAttachment = 0L
            submittedVisibleRoot = null
        }
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
            detachedIsolatedBackendSelected = false
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
        val recoveryView = isolatedOrbRequested && (pressureLatch != null || isolatedOrbFailed)
        val needsBootstrap = canAnimate && scene?.profile?.animated == true &&
            exercisedVisualKey != sceneVisualKey && !recoveryView
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
        // View setup can synchronously notify the controller (for example
        // when a prepared program is promoted). Publish only the currently
        // permitted scene before any such notification can reconcile a new
        // child, especially after full-to-discreet retirement.
        latestOrbScene = isolatedScene
        latestOrbPreviousScene = isolatedPrevious
        latestOrbPreviousArtifact = previousArtifact
        isolatedTransitionStartedNanos = transitionStart
        orb.setStaticBitmap(staticOrb)
        orb.setScene(scene, enabled = canAnimate)
        // While the buffer producer obtains its first completed frame the
        // retained View supplies the same palette-correct bootstrap.  It is
        // not a commit dependency for the isolated route.
        orb.setBootstrapActive(needsBootstrap || isolatedOrbEffective)
        if (restrictiveTransition && attached && presentationMode == KeyguardCardPresentationMode.ORB) {
            // The selected scene and static input are already neutral. Keep
            // it visible before any deferred callback can configure another
            // child; a pressure View stays on its permitted animated route.
            orb.setBootstrapActive(!recoveryView && canAnimate)
            orb.visibility = View.VISIBLE
            orb.invalidate()
        }
        coherentRestrictedView = true
        if (attached && isolatedOrbEffective &&
            (activeOrbLease == null || activeOrbLease?.visualKey != sceneVisualKey)
        ) {
            // The View has already accepted the currently permitted scene.
            // In particular, a privacy downgrade cannot restore old colour.
            orb.visibility = View.VISIBLE
        }
        val backgroundVisible = selectedBackgroundVisible
        background.setScene(scene, enabled = canAnimate && backgroundVisible)
        background.setBootstrapActive(needsBootstrap && backgroundVisible)
        background.visibility = if (backgroundVisible) View.VISIBLE else View.GONE
        // OFF and orb-only retain the precise, already validated static-card
        // appearance. The readability veil only belongs above an animated
        // material background.
        backgroundVeil.visibility = if (backgroundVisible) View.VISIBLE else View.GONE
        prepareSelectedPrograms(
            profile,
            animationMode,
            presentationMode,
            isFull,
            installViewProgram = !needsBootstrap || isolatedOrbEffective,
        )
        reconcileIsolatedOrbTarget()
        reconcileClock(canAnimate)
        } finally {
            if (restrictiveTransition) {
                restrictiveTransitionActive = false
                val pending = restrictiveReconcilePending
                restrictiveReconcilePending = false
                if (coherentRestrictedView && pending) {
                    reconcileIsolatedOrbTarget()
                    reconcileClock()
                } else if (!coherentRestrictedView) {
                    // An exception must not resurrect the previous full scene.
                    currentFirstPublication = null
                    activeOrbLease = null
                    if (isolatedOrbRendererDelegate.isInitialized()) {
                        runCatching { isolatedOrbRenderer.retire("privacy-transition-failure") }
                    }
                    runCatching { orb.setStaticBitmap(null); orb.setScene(null, enabled = false) }
                    if (attached && presentationMode == KeyguardCardPresentationMode.ORB) {
                        orb.visibility = View.VISIBLE
                        orb.invalidate()
                    }
                }
            }
        }
    }

    /** True means the caller must register its frame-commit observation before
     * the invalidation below can traverse the bootstrap frame. */
    fun requiresBootstrapForNextAttach(): Boolean =
        !isolatedOrbEffective && coldPresentationState != ColdPresentationState.LIVE

    /** Immutable ownership for a single bootstrap/commit/live transition. */
    fun currentBootstrapToken(): KeyguardBootstrapFrameToken? =
        bootstrapVisualKey?.let { visualKey ->
            if (coldPresentationState == ColdPresentationState.LIVE) null
            else KeyguardBootstrapFrameToken(bootstrapGeneration, visualKey)
        }

    fun onAttached(attachment: Long = 0L, root: View? = null) {
        detachedPrimeArmed = false
        if (root != null && pressureLatch != null && pressureRestoredAt != null &&
            attachment > 0 && attachment != pressureRetryAfterAttachment && isolatedOrbRequested
        ) {
            // A drained pool can be selected only at a later distinct
            // authorized attachment, never in the running recovery episode.
            pressureLatch = null
            pressureClaimedAt = null
            pressureRestoredAt = null
            pressureRetryAfterAttachment = 0L
        }
        // Controller-only tests and detached compatibility callers do not
        // own an accessibility-overlay root. A child SurfaceControl cannot
        // be safely parented there, so retain the established View route.
        // Production KeyguardCardWindow always supplies its retained root.
        if (isolatedOrbRequested && root == null) {
            isolatedOrbRequested = false
            isolatedOrbFailed = false
            detachedIsolatedBackendSelected = false
            orb.setBootstrapActive(false)
        }
        if (!attached) {
            submittedVisibleScene = null
            submittedVisibleArtifact = null
            submittedVisibleAttachment = 0L
            submittedVisibleRoot = null
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
            attachmentPositionSubmittedStart = buffer?.positionSubmissions ?: 0
            attachmentPositionSuppressedStart = buffer?.positionSuppressions ?: 0
            currentFirstPublication = null
            firstHandoffToken = null
            firstHandoffCaptureOwner = null
            firstHandoff = null
            withdrawalWorkerSnapshot = null
            withdrawalWorkerOwner = null
            val inherited = pressureLatch
            val captureOwner = drawEvidenceOwner()
            recoveryEpisodeOwner = captureOwner
            recoveryEpisodeTicket = inherited
            recoveryEpisode = if (inherited != null && captureOwner != null && isolatedOrbRequested) {
                inherited.episode(attachment, inherited = true, claimedAt = pressureClaimedAt,
                    restoredAt = pressureRestoredAt)
            } else null
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
        if (isolatedOrbEffective) {
            // A new layer generation must not expose the legacy shader while
            // its first buffer is still pending. The bootstrap is visually
            // compatible but has no frame-commit/promotion authority here.
            orb.visibility = View.VISIBLE
            orb.setBootstrapActive(true)
        }
        if (!isolatedOrbEffective && coldPresentationState != ColdPresentationState.LIVE) {
            bootstrapCommitReceived = false
            orb.setBootstrapActive(true)
            background.setBootstrapActive(selectedBackgroundVisible)
        }
        // Invalidate once so the first Canvas draw can prove whether this
        // actual overlay is hardware accelerated.  No animation callback is
        // required for this traversal.
        orb.invalidate()
        background.invalidate()
        if (isolatedOrbEffective && root != null) {
            reconcileIsolatedOrbTarget(root)
        }
        reconcileClock()
    }

    fun onDetached(reason: String, onLayerHideCommitted: ((Long) -> Unit)? = null,
                   onRetirementEvent: ((KeyguardOrbRetirementEvent) -> Unit)? = null) {
        detachedPrimeArmed = false
        authorizedShowPending = false
        submittedVisibleScene = null
        submittedVisibleArtifact = null
        submittedVisibleAttachment = 0L
        submittedVisibleRoot = null
        withdrawalAttachment = activeAttachment
        if (attached && isolatedOrbRendererDelegate.isInitialized()) {
            val owner = drawEvidenceOwner()
            if (owner != null) {
                // Freeze the latest coherent Worker observation before the
                // revoke/reset can relabel a zero-output episode as detached.
                withdrawalWorkerOwner = owner
                withdrawalWorkerSnapshot = isolatedOrbRenderer.snapshot()
            }
        }
        if (isolatedOrbRequested) {
            val now = System.nanoTime()
            isolatedOrbPausedTime = if (pressureLatch != null) orb.currentMaterialTime(now)
                else latestOrbScene?.timeAt(now)
        }
        attached = false
        activeAttachment = 0L
        attachedRoot = null
        activeOrbLease = null
        currentFirstPublication = null
        firstHandoffToken = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE &&
            isolatedOrbRendererDelegate.isInitialized()
        ) {
            isolatedOrbRenderer.retire(reason, onLayerHideCommitted, onRetirementEvent)
        }
        // The child SurfaceControl is retired before WindowManager removes its
        // parent. Restore the View for a later legacy/fallback attachment.
        orb.visibility = View.VISIBLE
        if (isolatedOrbEffective) orb.setBootstrapActive(true)
        orb.pause()
        background.pause()
        clock.stop()
        orb.endAttachmentDrawEvidence()
        background.endAttachmentDrawEvidence()
    }

    fun stop(reason: String, onLayerHideCommitted: ((Long) -> Unit)? = null,
             onRetirementEvent: ((KeyguardOrbRetirementEvent) -> Unit)? = null) =
        onDetached(reason, onLayerHideCommitted, onRetirementEvent)

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
        positionSubmissions = buffer?.let { it.positionSubmissions - attachmentPositionSubmittedStart } ?: 0,
        positionSuppressions = buffer?.let { it.positionSuppressions - attachmentPositionSuppressedStart } ?: 0,
        firstWork = (withdrawalWorkerSnapshot ?: buffer)?.firstWork?.takeIf {
            it.captureOwner === drawEvidenceOwner() &&
                it.attachment == (if (attached) activeAttachment else withdrawalAttachment)
        },
        coldWork = (withdrawalWorkerSnapshot ?: buffer)?.coldWork?.filter {
            it.owner === drawEvidenceOwner() &&
                (it.attachment == (if (attached) activeAttachment else withdrawalAttachment) ||
                    (it.attachment == 0L && (if (attached) activeAttachment else withdrawalAttachment) == 1L))
        } ?: emptyList(),
        isolatedFirstHandoff = firstHandoff?.takeIf {
            firstHandoffCaptureOwner != null && firstHandoffCaptureOwner === drawEvidenceOwner()
        },
        recovery = recoveryEpisode?.takeIf {
            recoveryEpisodeOwner != null && recoveryEpisodeOwner === drawEvidenceOwner()
        },
        effectiveRoute = effectiveRoute,
        worker = withdrawalWorkerSnapshot?.takeIf {
            withdrawalWorkerOwner != null && withdrawalWorkerOwner === drawEvidenceOwner()
        } ?: buffer,
        observedAt = SystemClock.uptimeMillis(),
    )
    }

    fun dispose() {
        runCatching { orb.context.contentResolver.unregisterContentObserver(animatorScaleObserver) }
        stop("dispose")
        pressureLatch = null
        pressureClaimedAt = null
        pressureRestoredAt = null
        recoveryEpisode = null
        recoveryEpisodeTicket = null
        recoveryEpisodeOwner = null
        withdrawalWorkerSnapshot = null
        withdrawalWorkerOwner = null
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
    ) {
        // The artifact store may complete synchronously. Select the persistent
        // isolated producer first so its callback cannot also start the
        // disposable HardwareRenderer/ImageReader warmup for this same ORB.
        prepareDetachedIsolatedOrbBackend(profile, animationMode, presentationMode, isFull)
        prepareSelectedPrograms(profile, animationMode, presentationMode, isFull, installViewProgram = true)
    }

    fun beginAuthorizedShow() {
        authorizedShowPending = true
        detachedPrimeArmed = false
        if (isolatedOrbRendererDelegate.isInitialized()) isolatedOrbRenderer.beginAuthorizedShow()
    }

    fun endAuthorizedShow() {
        authorizedShowPending = false
    }

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
            isolatedOrbEffective -> "HardwareBufferRenderer/SurfaceControl"
            coldPresentationState != ColdPresentationState.LIVE -> "BOOTSTRAP_PALETTE"
            orb.rendererFailure() != null -> "COMPILE_OR_UNIFORM_FAILED"
            orb.isRendererReady() -> "RuntimeShader/AGSL"
            else -> "WAITING_FOR_ATTACH_OR_DRAW"
        },
        hardwareAccelerated = (isolatedOrbEffective &&
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
        isolatedWorkerRunning = buffer?.workerRunning ?: false,
        isolatedWorkerDesiredAttachment = buffer?.workerDesiredAttachment ?: -1L,
        isolatedWorkerDesiredGeneration = buffer?.workerDesiredGeneration ?: -1L,
        isolatedWorkerAttachedAttachment = buffer?.workerAttachedAttachment ?: -1L,
        isolatedWorkerAttachedGeneration = buffer?.workerAttachedGeneration ?: -1L,
        isolatedCompletionGapMaxMs = buffer?.completionGapMaxMs ?: 0L,
        effectiveRoute = effectiveRoute,
        attachment = activeAttachment,
        recoveryGeneration = pressureLatch?.lease?.generation ?: 0L,
        recoveryRestoredAt = pressureRestoredAt,
        attachmentShaderCalls = orb.attachmentShaderCalls(),
        attachmentShaderTraversals = orb.attachmentDrawCadence().frames,
        attachmentPhaseAdvances = orb.attachmentPhaseAdvances(),
    )
    }

    private fun reconcileClock(forceCanAnimate: Boolean? = null) {
        if (restrictiveTransitionActive) { restrictiveReconcilePending = true; return }
        val canAnimate = forceCanAnimate ?: (profile != null && mode != KeyguardCardAnimationMode.OFF && animationsAllowed)
        // A genuinely static Header scene is rendered once; the selected
        // visual mode alone must not leave a 60 Hz callback running.
        if (!attached || !canAnimate || profile?.animated != true) {
            orb.pause()
            background.pause()
            clock.stop()
            return
        }
        if (isolatedOrbEffective) {
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
        val skipLegacyOrbGpuPreparation = shouldSkipLegacyOrbGpuPreparation(orb)
        expectedGpuPreparationCount = if (
            presentationMode == KeyguardCardPresentationMode.CARD &&
                animationMode == KeyguardCardAnimationMode.ORB_AND_BACKGROUND
        ) 2 else if (skipLegacyOrbGpuPreparation) 0 else 1
        prepareFor(orb, effective, installViewProgram)
        if (presentationMode == KeyguardCardPresentationMode.CARD &&
            animationMode == KeyguardCardAnimationMode.ORB_AND_BACKGROUND
        ) prepareFor(background, effective, installViewProgram)
        else {
            requestedProgramKeys.remove(background)
            deferredViewArtifacts.remove(background)
        }
    }

    /**
     * Prepares the exact bounded isolated producer selected for an ORB-only
     * presentation while the retained root is detached.  This is deliberately
     * separate from attachment authorization: it never creates a child layer,
     * sets root visibility, or starts the recurring renderer loop.  The first
     * authorized attachment receives a distinct lease and must still publish
     * a current buffer before it can replace the View bootstrap.
     */
    private fun prepareDetachedIsolatedOrbBackend(
        profile: KeyguardMaterialProfile?,
        animationMode: KeyguardCardAnimationMode,
        presentationMode: KeyguardCardPresentationMode,
        isFull: Boolean,
    ) {
        if (attached || authorizedShowPending) return
        detachedPrimeArmed = false
        if (pressureLatch != null) {
            detachedIsolatedBackendSelected = false
            return
        }
        if (profile == null) {
            detachedIsolatedBackendSelected = false
            return
        }
        val effective = if (isFull) profile else profile.neutralized()
        val scene = KeyguardMaterialScene(
            profile = effective,
            full = isFull,
            appliedAtNanos = System.nanoTime(),
        )
        val canAnimate = animationMode != KeyguardCardAnimationMode.OFF && animationsAllowed
        if (!canUseIsolatedOrb(scene, animationMode, presentationMode, canAnimate)) {
            detachedIsolatedBackendSelected = false
            return
        }

        // A new visual selection is the only retry boundary after a producer
        // failure.  This exactly mirrors update(), but happens without an
        // attachment or a presentation grant.
        if (isolatedOrbFailedVisualKey != scene.profile.visualKey) {
            isolatedOrbFailed = false
            isolatedOrbFailedVisualKey = null
        }
        if (isolatedOrbFailed) return

        isolatedOrbRequested = true
        detachedIsolatedBackendSelected = true
        detachedPrimeArmed = true
        latestOrbScene = scene
        latestOrbPreviousScene = null
        latestOrbPreviousArtifact = null
        isolatedTransitionStartedNanos = 0L
        onPreparationStage?.invoke(
            "MATERIAL_ISOLATED_BACKEND_PREPARE_REQUESTED",
            mapOf(
                "effectId" to scene.profile.effectId,
                "visualKey" to scene.profile.visualKey,
                "surface" to "orb",
            ),
        )
        // If the artifact callback was synchronous (or an unchanged program
        // was already retained), this starts the actual Worker immediately.
        // Otherwise prepareFor's existing artifact callback reaches this same
        // reconciliation point.  Neither route creates a visible layer.
        reconcileIsolatedOrbTarget()
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
                    // The detached eligible ORB prepares the persistent
                    // HardwareBufferRenderer path. Do not also create and
                    // destroy the legacy HardwareRenderer/ImageReader warmup
                    // for that same route; CARD and legacy View routes keep
                    // their established preparation.
                    if (shouldSkipLegacyOrbGpuPreparation(view)) {
                        onPreparationStage?.invoke(
                            "MATERIAL_GPU_PREPARATION_SKIPPED",
                            mapOf(
                                "programKey" to artifact.programKey,
                                "surface" to surfaceName(view),
                                "reason" to "isolated-backend",
                            ),
                        )
                    } else {
                        prepareGpuProgram(view, profile, artifact, requestedKey)
                    }
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

    /** The retained root selected the persistent producer while detached, so
     * that producer is the one GPU warmup for this ORB. Other View routes
     * retain the legacy preparer. */
    private fun shouldSkipLegacyOrbGpuPreparation(view: KeyguardHeaderMaterialView): Boolean =
        view === orb && detachedIsolatedBackendSelected &&
            isolatedOrbEffective

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
        if (restrictiveTransitionActive) { restrictiveReconcilePending = true; return }
        if (!attached && (!detachedPrimeArmed || authorizedShowPending)) return
        if (!isolatedOrbEffective ||
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
        if (attached && previous != null && previous != lease) {
            // The current View scene is already selected. It is a static
            // bootstrap only; the new child stays the sole animated owner.
            currentFirstPublication = null
            orb.setBootstrapActive(true)
            orb.visibility = View.VISIBLE
        }
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
        if (!attached) detachedPrimeArmed = false
        if (attached && root != null && root.isAttachedToWindow && attachment != 0L) {
            isolatedOrbRenderer.attach(root, orb, attachment)
        }
    }

    private fun onIsolatedOrbFirstPublished(token: KeyguardOrbFirstPublicationToken, times: KeyguardOrbFirstPublicationTimes) {
        val lease = token.lease
        if (!attached || !isolatedOrbEffective || activeOrbLease != lease ||
            activeAttachment != lease.attachment || attachedRoot?.isAttachedToWindow != true
        ) return
        currentFirstPublication = token
        submittedVisibleScene = latestOrbScene?.takeIf { it.profile.visualKey == lease.visualKey }
        submittedVisibleArtifact = latestOrbArtifact
        submittedVisibleAttachment = activeAttachment
        submittedVisibleRoot = attachedRoot
        val captureOwner = drawEvidenceOwner()
        if (firstHandoff == null && captureOwner != null) {
            firstHandoffCaptureOwner = captureOwner
            firstHandoffToken = token
            firstHandoff = KeyguardIsolatedFirstHandoffSnapshot(
                lease.attachment, lease.generation, token.slotId, token.useGeneration,
                System.identityHashCode(token.child), times,
            )
        }
        // Compatibility first-output marker is the direct CPU submission.
        // The static View remains until this exact transaction commits.
        coldPresentationState = ColdPresentationState.LIVE
        bootstrapVisualKey = null
        bootstrapCommitReceived = false
        exercisedVisualKey = lease.visualKey
        onFirstOrbShaderDraw?.invoke(times.applyEndAtUptimeMs)
        onPreparationStage?.invoke(
            "MATERIAL_BUFFER_FIRST_OUTPUT",
            mapOf("programKey" to lease.programKey, "surface" to "orb"),
        )
    }

    private fun onIsolatedOrbFirstCommitReceived(token: KeyguardOrbFirstPublicationToken, receiptAt: Long, mainAt: Long) {
        if (firstHandoffToken !== token || firstHandoffCaptureOwner == null ||
            firstHandoffCaptureOwner !== drawEvidenceOwner()
        ) return
        firstHandoff = firstHandoff?.copy(commitReceiptAtUptimeMs = receiptAt, commitMainAtUptimeMs = mainAt)
    }

    private fun onIsolatedOrbFirstCommitted(token: KeyguardOrbFirstPublicationToken) {
        val lease = token.lease
        if (!attached || !isolatedOrbEffective || activeOrbLease != lease ||
            activeAttachment != lease.attachment || attachedRoot?.isAttachedToWindow != true ||
            currentFirstPublication !== token || !isolatedOrbRenderer.ownsFirstPublication(token)
        ) return
        currentFirstPublication = null
        orb.setBootstrapActive(false)
        orb.visibility = View.INVISIBLE
        if (firstHandoffToken === token && firstHandoffCaptureOwner != null &&
            firstHandoffCaptureOwner === drawEvidenceOwner()
        ) firstHandoff = firstHandoff?.copy(bootstrapRetiredAtUptimeMs = SystemClock.uptimeMillis())
    }

    /** Main-only response to an attached View layout change. The old child
     * layer is retired by the renderer before a differently sized lease can
     * be published, so a late buffer cannot be stretched into new bounds. */
    private fun onIsolatedOrbSizeChanged() {
        if (!attached || !isolatedOrbEffective) return
        val current = activeOrbLease
        val (width, height) = warmupDimensions(orb)
        if (current != null && current.width == width && current.height == height) return
        reconcileIsolatedOrbTarget(attachedRoot)
    }

    private fun onIsolatedOrbFailure(lease: KeyguardOrbBufferLease, error: Throwable) {
        if (activeOrbLease != lease) return
        isolatedOrbFailed = true
        currentFirstPublication = null
        isolatedOrbFailedVisualKey = lease.visualKey
        detachedIsolatedBackendSelected = false
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
        prepareLegacyOrbFallback()
        orb.invalidate()
        reconcileClock()
    }

    private fun onIsolatedOrbPressure(ticket: KeyguardOrbPressureTicket) {
        val scene = latestOrbScene ?: run { ticket.claim.cancel(); return }
        val artifact = latestOrbArtifact ?: run { ticket.claim.cancel(); return }
        val lease = ticket.lease
        val root = attachedRoot
        if (!attached || root?.isAttachedToWindow != true || !isolatedOrbEffective ||
            activeAttachment != lease.attachment || activeOrbLease != lease ||
            !animationsAllowed || mode != KeyguardCardAnimationMode.ORB_ONLY ||
            presentationMode != KeyguardCardPresentationMode.ORB || !scene.profile.animated ||
            scene.profile.visualKey != lease.visualKey || scene.visualKey != ticket.sceneKey ||
            scene.full != ticket.sceneFull || scene.profile.effectId != ticket.effectId ||
            scene.profile.usesPortal != ticket.usesPortal || artifact.programKey != lease.programKey ||
            artifact.effectId != scene.profile.effectId || artifact.usesPortal != scene.profile.usesPortal ||
            orb.width != lease.width || orb.height != lease.height ||
            !isolatedOrbRenderer.claimPressure(ticket)
        ) {
            ticket.claim.cancel()
            return
        }

        val claimedAt = SystemClock.uptimeMillis()
        val now = System.nanoTime()
        val anchor = scene.timeAt(now)
        // Publish the route before any View/artifact callback can reenter.
        pressureLatch = ticket
        pressureClaimedAt = claimedAt
        pressureRestoredAt = null
        pressureRetryAfterAttachment = activeAttachment
        detachedIsolatedBackendSelected = false
        activeOrbLease = null
        currentFirstPublication = null
        coldPresentationState = ColdPresentationState.LIVE
        bootstrapVisualKey = null
        bootstrapCommitReceived = false
        val captureOwner = drawEvidenceOwner()
        recoveryEpisodeOwner = captureOwner
        recoveryEpisodeTicket = ticket
        if (captureOwner != null) recoveryEpisode = ticket.episode(activeAttachment,
            inherited = false, claimedAt = claimedAt, anchor = anchor)
        // Revocation/clear stay asynchronous with respect to buffer release;
        // Main never waits for Worker, GPU, a commit, or a fence here.
        isolatedOrbRenderer.retire("retired-use-pressure")
        isolatedOrbRenderer.acceptPressure(ticket)
        val keptTransition = orb.adoptRecoveryScene(scene, latestOrbPreviousScene,
            isolatedTransitionStartedNanos, now)
        if (recoveryEpisodeOwner != null && recoveryEpisodeOwner === drawEvidenceOwner()) {
            recoveryEpisode = recoveryEpisode?.copy(transitionPreserved = keptTransition)
        }
        orb.visibility = View.VISIBLE
        orb.setBootstrapActive(false)
        requestedProgramKeys[orb]?.let { installViewProgram(orb, artifact, it) }
        prepareLegacyOrbFallback()
        orb.invalidate()
        reconcileClock()
    }

    private fun onIsolatedOrbCapacityRestored(ticket: KeyguardOrbPressureTicket, observedAt: Long) {
        if (pressureLatch !== ticket) return
        pressureRestoredAt = observedAt
        pressureRetryAfterAttachment = if (attached) activeAttachment else 0L
        if (recoveryEpisodeOwner != null && recoveryEpisodeOwner === drawEvidenceOwner() &&
            recoveryEpisodeTicket === ticket
        ) recoveryEpisode = recoveryEpisode?.copy(restoredAt = observedAt)
    }

    /** A persistent-producer failure returns to the established View route.
     * Start its bounded legacy preparation only at this real fallback
     * boundary; the successful isolated route must not pay for both paths. */
    private fun prepareLegacyOrbFallback() {
        val scene = latestOrbScene ?: return
        val artifact = latestOrbArtifact?.takeIf {
            it.effectId == scene.profile.effectId && it.usesPortal == scene.profile.usesPortal
        } ?: return
        val requestedKey = requestedProgramKeys[orb] ?: return
        prepareGpuProgram(orb, scene.profile, artifact, requestedKey)
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
    val positionSubmissions: Int,
    val positionSuppressions: Int,
    val firstWork: KeyguardOrbFirstWorkSnapshot?,
    val coldWork: List<KeyguardOrbColdWorkSnapshot> = emptyList(),
    val isolatedFirstHandoff: KeyguardIsolatedFirstHandoffSnapshot?,
    val recovery: KeyguardOrbRecoveryEpisode? = null,
    val effectiveRoute: String = "UNAVAILABLE",
    val worker: KeyguardOrbBufferRendererSnapshot? = null,
    val observedAt: Long = 0L,
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
    val isolatedWorkerRunning: Boolean,
    val isolatedWorkerDesiredAttachment: Long,
    val isolatedWorkerDesiredGeneration: Long,
    val isolatedWorkerAttachedAttachment: Long,
    val isolatedWorkerAttachedGeneration: Long,
    val isolatedCompletionGapMaxMs: Long,
    val effectiveRoute: String,
    val attachment: Long,
    val recoveryGeneration: Long,
    val recoveryRestoredAt: Long?,
    val attachmentShaderCalls: Int,
    val attachmentShaderTraversals: Long,
    val attachmentPhaseAdvances: Int,
)
