package com.fluvi.app.lockscreen

import android.content.Context
import android.os.Build
import android.view.Choreographer
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.WindowInsets
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.TextView
import com.fluvi.app.R
import com.fluvi.app.lockscreen.material.KeyguardCardMaterialController
import com.fluvi.app.lockscreen.material.KeyguardBootstrapFrameToken
import com.fluvi.app.lockscreen.material.KeyguardHeaderMaterialView
import com.fluvi.app.lockscreen.material.KeyguardMaterialDiagnostics
import com.fluvi.app.lockscreen.material.KeyguardMaterialProfile
import com.fluvi.app.lockscreen.material.KeyguardOrbRenderBarrier
import com.fluvi.app.lockscreen.material.KeyguardOrbRetirementEvent
import com.fluvi.app.lockscreen.material.NoopKeyguardOrbRenderBarrier
import com.fluvi.app.lockscreen.material.KeyguardOrbBufferFrameObserver
import com.fluvi.app.lockscreen.material.KeyguardOrbBufferPublicationObserver
import com.fluvi.app.lockscreen.material.KeyguardOrbBufferRendererTestHooks
import com.fluvi.app.lockscreen.material.KeyguardOrbMaterialTimeSource
import com.fluvi.app.runtime.FluviFinancialCardPresentation
import com.fluvi.app.lockscreen.material.KeyguardOrbFirstOfferObservation
import com.fluvi.app.lockscreen.material.KeyguardOrbSurfaceObservation
import com.fluvi.app.lockscreen.material.KeyguardR19FirstPaintTicket
import com.fluvi.app.lockscreen.material.KeyguardOrbSurfaceMetrics
import com.fluvi.app.lockscreen.material.KeyguardOrbSurfacePresenter
import com.fluvi.app.lockscreen.material.KeyguardOrbPresentationLane

/** Main-thread owner of one, and only one, accessibility overlay root. Drag
 * changes only call updateViewLayout; they never remove/re-add this root,
 * recreate its material controller, or re-enter financial presentation. */
internal class KeyguardCardWindow(
    private val serviceContext: Context,
    private val onOpen: () -> Unit,
    private val onToggle: () -> Unit,
    private val onInteractionStarted: () -> Unit,
    private val onPositionCommitted: (
        KeyguardCardPresentationMode,
        KeyguardCardCardPosition,
        KeyguardCardOrbPosition,
        Long,
    ) -> Unit,
    private val onInteractionDiagnostic: (String, String) -> Unit,
    /** Window operations are reported after the operation boundary, never by
     * a renderer/onDraw callback. The service adds its captured wake/session
     * identity before storing a diagnostic event. */
    private val onWindowDiagnostic: (String, String, Long?, Long, Map<String, Any?>) -> Unit =
        { _, _, _, _, _ -> },
    /** Captures the original show operation before add; returned callback is
     * observational and cannot grant attachment or change visibility. */
    private val armColdRootDiagnostic: (Long) -> ((String, Long, Map<String, Any?>) -> Unit)? = { null },
    private val armFirstOfferDiagnostic: (Long) -> ((KeyguardOrbFirstOfferObservation) -> Unit)? = { null },
    private val armSurfaceDiagnostic: (Long) -> ((KeyguardOrbSurfaceObservation) -> Unit)? = { null },
    private val onSurfaceFailure: (String) -> Unit = {},
    private val onFirstRootPreDraw: (KeyguardFirstDrawEvent) -> Unit = {},
    private val onFirstRootDraw: (KeyguardFirstDrawEvent) -> Unit = {},
    private val onFirstShaderDraw: (KeyguardFirstDrawEvent) -> Unit = {},
    private val onBootstrapDraw: (KeyguardFirstDrawEvent) -> Unit = {},
    private val onBootstrapCommit: (KeyguardFirstDrawEvent) -> Unit = {},
    private val onLivePromotion: (KeyguardFirstDrawEvent) -> Unit = {},
    private val onFrameCommit: (KeyguardFirstDrawEvent) -> Unit = {},
    private val manager: WindowManager = serviceContext.getSystemService(WindowManager::class.java),
    private val mainWorkEvidence: KeyguardMainWorkEvidence? = null,
    private val drawEvidenceEnabled: () -> Boolean = { KeyguardCardDiagnostics.wantsEvent("DRAW_GAP") },
    /** Injectable only for the execution-isolation instrumentation boundary.
     * Production never blocks the dedicated renderer intentionally. */
    private val isolatedOrbRenderBarrier: KeyguardOrbRenderBarrier = NoopKeyguardOrbRenderBarrier,
    /** Captured only for instrumentation before this window/controller is
     * created; production resolves to the no-op observer. */
    private val isolatedOrbFrameObserver: KeyguardOrbBufferFrameObserver =
        KeyguardOrbBufferRendererTestHooks.frameObserver,
    /** Captured with the producer observer; it observes submission only. */
    private val isolatedOrbPublicationObserver: KeyguardOrbBufferPublicationObserver =
        KeyguardOrbBufferRendererTestHooks.publicationObserver,
    /** Captured with the observer for deterministic renderer-only tests. */
    private val isolatedOrbMaterialTimeSource: KeyguardOrbMaterialTimeSource =
        KeyguardOrbBufferRendererTestHooks.materialTimeSource,
    /** Main notifies the service when an already-issued first-read hint can
     * no longer describe the prepared animated route. */
    private val onSurfaceMotionIneligible: () -> Unit = {},
    private val onR18HostReady: (Long, View, Int) -> Unit = { _, _, _ -> },
    private val onR18HostAttached: (Long, Long) -> Unit = { _, _ -> },
    private val onR18BufferReady: (Long, Long, Long) -> Unit = { _, _, _ -> },
    private val onR18Failure: (Long, Long, String) -> Unit = { _, _, _ -> },
    private val onR18Receipt: (Long, Long, KeyguardOrbPresentationLane.Receipt) -> Unit = { _, _, _ -> },
    private val onR18Drained: (Long, Long, Any) -> Unit = { _, _, _ -> },
    private val onR19Allocated: (Long, Long, Long) -> Unit = { _, _, _ -> },
    private val onR19Observation: (KeyguardOrbSurfaceObservation) -> Unit = {},
    private val r18PipelineEnabled: Boolean = false,
) {
    enum class Result { ATTACHED, CONTENT_UPDATED, LAYOUT_UPDATED, REDACTED, NO_OP, PENDING, FAILED }

    private var root: KeyguardCardInteractionLayout? = null
    private val lifecycle = KeyguardCardWindowLifecycle()
    private var appliedPresentation: FluviFinancialCardPresentation? = null
    private var appliedGeometry: KeyguardOverlayGeometry? = null
    private var accessibilityWindowId: Int? = null
    private var attachGeneration = 0L
    private val mainHandler = Handler(Looper.getMainLooper())
    private var surfaceAnimationObserverRegistered = false
    private var surfaceMotionAllowed = false
    private val surfaceAnimationObserver = object : android.database.ContentObserver(mainHandler) {
        override fun onChange(selfChange: Boolean) {
            if (!surfaceAnimationObserverRegistered) return
            val allowed = android.provider.Settings.Global.getFloat(serviceContext.contentResolver,
                android.provider.Settings.Global.ANIMATOR_DURATION_SCALE, 1f) > 0f
            surfaceMotionAllowed = allowed
            if (!allowed) onSurfaceMotionIneligible()
            surfacePresenter?.setMotionAllowed(allowed)
            if (KeyguardR15AcquisitionTestHooks.ENABLED) KeyguardR15AcquisitionTestHooks.motionChanged(allowed)
        }
    }
    private var firstRootDrawObservation: KeyguardFirstDrawObservation? = null
    private var coldRootObservation: KeyguardColdRootObservation? = null
    private var firstFrameCommitObservation: KeyguardFrameCommitObservation? = null
    /** The most recently accepted functional commit. Diagnostic publication is
     * posted after that transition and must not describe a superseded scene. */
    private var acceptedBootstrapToken: KeyguardBootstrapFrameToken? = null
    private var firstShaderDrawAttachGeneration: Long? = null
    private var materialController: KeyguardCardMaterialController? = null
    private class TransitionTrace(
        val kind: String, val root: Int, val attachment: Long, val ingress: Long,
        val generation: Long?, var child: Int?, val firstSlot: Long?, val firstUse: Long?, val firstSubmit: Long?,
    ) {
        var revoke: Long? = null
        var hideSubmit: Long? = null
        var hideReturn: Long? = null
        var hideApplied: Boolean? = null
        var localHide: Long? = null
        var bind = "UNOBSERVED"
        var layout = "UNOBSERVED"
        var outcome = "UNOBSERVED"
    }
    private var terminalTransitionTrace: TransitionTrace? = null
    private class WindowRestriction(
        val root: KeyguardCardInteractionLayout,
        val attachment: Long,
        val controller: KeyguardCardMaterialController,
        val trace: TransitionTrace?,
    ) {
        var token: KeyguardCardMaterialController.RestrictiveTransition? = null
        var pendingMaterial: Pair<KeyguardMaterialProfile?, KeyguardCardSettings>? = null
        var pendingLayout: KeyguardCardSettings? = null
    }
    private var windowRestriction: WindowRestriction? = null
    /** A failed neutral bind may leave a hidden retained root after WM rejects
     * removal. Its next authorized presentation must be rebound before show. */
    private var secureRebindRequired = false
    @Volatile private var surfacePresenter: KeyguardOrbSurfacePresenter? = null
    internal data class R18Preparation(val attachment: Long, val outputGeneration: Long,
        val full: Boolean, val visualKey: String, val width: Int, val height: Int, val densityDpi: Int,
        val emptyAwaitingDisclosure: Boolean = false)
    private var r18Preparation: R18Preparation? = null
    private var nextR18OutputGeneration = 0L
    private var r18HostGeneration: Long? = null
    private var r18BoundOutputGeneration: Long? = null
    private var r18RemovedOutputGeneration: Long? = null
    private var r18Host: KeyguardOrbInertHost? = null
    private var surfaceDiagnostic: ((KeyguardOrbSurfaceObservation) -> Unit)? = null
    private var attachedConfiguredMode = KeyguardOrbRenderMode.SURFACE_LIVE
    private var effectiveRenderMode = KeyguardOrbRenderMode.LEGACY_R11
    private var materialProfile: KeyguardMaterialProfile? = null
    private var materialSettings = KeyguardCardSettings()
    /** Legacy position migration reads and writes SharedPreferences. It is
     * retained, but never allowed to sit between addView() and the first
     * requested traversal. */
    private var pendingCardPositionMigration: Pair<Long, KeyguardCardCardPosition>? = null
    /** `configurePresentation` mutates real View layout/visibility state.
     * Repeated MAIN_CONFIRMED inspections therefore need an explicit semantic
     * key instead of discovering they were no-ops after those mutations. */
    private var appliedPresentationConfiguration: PresentationConfigurationKey? = null
    private var presentationConfigurationApplyCount = 0
    private var dragStart: KeyguardOverlayGeometry? = null
    private var dragPreview: KeyguardOverlayGeometry? = null
    private var dragLayoutRevision = 0L
    private var dragMoveCount = 0
    private var dragLayoutUpdateCount = 0
    private var dragFrameScheduled = false
    private val rootClickRouter = KeyguardCardClickRouter(
        onCardOpen = onOpen,
        onOrbTapConsumed = { onInteractionDiagnostic("KG|ORB_TAP", "action=consumed") },
    )
    private val dragFrameCallback = Choreographer.FrameCallback {
        dragFrameScheduled = false
        dragPreview?.let(::applyDragPreview)
    }

    val isAttached: Boolean get() = lifecycle.isAttached()
    val isDragActive: Boolean get() = root?.isDragging == true
    val hasPreparedRoot: Boolean get() = root != null
    val currentAttachGeneration: Long get() = attachGeneration
    fun visibleRootForReadmission(): Boolean = lifecycle.isAttached() && root?.visibility == View.VISIBLE
    fun currentPresentationFull(): Boolean? = appliedPresentation?.full

    private fun newTransitionTrace(kind: String, current: View,
                                   controller: KeyguardCardMaterialController?): TransitionTrace? {
        if (controller == null || !KeyguardCardDiagnostics.wantsEvent("R22_4_TRANSITION")) return null
        return runCatching {
            val evidence = controller.restrictionEvidence()
            TransitionTrace(kind, System.identityHashCode(current), attachGeneration, SystemClock.uptimeMillis(),
                evidence.generation, evidence.child, evidence.firstSlot, evidence.firstUse, evidence.firstSubmitAt)
        }.getOrNull()
    }

    private fun reportTransitionTrace(trace: TransitionTrace?) {
        if (trace == null) return
        runCatching {
            reportWindowDiagnostic("R22_4_TRANSITION", trace.kind, trace.attachment, trace.ingress,
                mapOf("root" to trace.root, "generation" to (trace.generation ?: "UNOBSERVED"),
                    "child" to (trace.child ?: "UNOBSERVED"), "oldFirstSlot" to (trace.firstSlot ?: "UNOBSERVED"),
                    "oldFirstUse" to (trace.firstUse ?: "UNOBSERVED"), "oldFirstSubmit" to (trace.firstSubmit ?: "UNOBSERVED"),
                    "oldLastSubmit" to "UNOBSERVED", "revoke" to (trace.revoke ?: "UNOBSERVED"),
                    "hideSubmit" to (trace.hideSubmit ?: "UNOBSERVED"), "hideReturn" to (trace.hideReturn ?: "UNOBSERVED"),
                    "hideApplied" to (trace.hideApplied ?: "UNOBSERVED"), "localHide" to (trace.localHide ?: "UNOBSERVED"),
                    "bind" to trace.bind, "layout" to trace.layout, "outcome" to trace.outcome))
        }
    }

    /** Main-owned prepared route only. This is a scalar observation of the
     * already selected owner, never another preference or system-state read. */
    fun preparedInitialLiveOrb(settings: KeyguardCardSettings, profile: KeyguardMaterialProfile?): Boolean {
        checkMainThread()
        return settings.requested && !lifecycle.isAttached() && root != null &&
            materialSettings == settings && materialProfile === profile && profile?.animated == true &&
            settings.presentationMode == KeyguardCardPresentationMode.ORB &&
            settings.animationMode == KeyguardCardAnimationMode.ORB_ONLY &&
            effectiveRenderMode == KeyguardOrbRenderMode.SURFACE_LIVE && surfacePresenter != null && surfaceMotionAllowed
    }
    fun attachmentRenderSummary() = materialController?.attachmentRenderSummary()
    fun displayRefreshRate(): Float? = root?.display?.refreshRate

    fun renderModeStatus(): KeyguardOrbRenderModeStatus = KeyguardOrbRenderModeStatus(
        configured = KeyguardOrbRenderModeStore.read(serviceContext),
        effective = effectiveRenderMode,
        visible = lifecycle.isAttached(),
        attachedSelection = attachedConfiguredMode,
    )

    private fun surfaceConfigurationEligible(settings: KeyguardCardSettings, profile: KeyguardMaterialProfile?,
                                             selection: KeyguardOrbRenderMode): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE &&
            settings.presentationMode == KeyguardCardPresentationMode.ORB &&
            settings.animationMode == KeyguardCardAnimationMode.ORB_ONLY &&
            profile?.animated == true && selection != KeyguardOrbRenderMode.LEGACY_R11

    private fun usesSurface(settings: KeyguardCardSettings, profile: KeyguardMaterialProfile?,
                            selection: KeyguardOrbRenderMode): Boolean {
        if (!surfaceConfigurationEligible(settings, profile, selection)) {
            val wasAllowed = surfaceMotionAllowed
            surfaceMotionAllowed = false
            if (wasAllowed) onSurfaceMotionIneligible()
            return false
        }
        // Register first so a change between this existing settings read and
        // detached preparation cannot be missed. Failure to observe changes
        // disables only the experimental first-read hint, not the route.
        if (!surfaceAnimationObserverRegistered) {
            surfaceAnimationObserverRegistered = runCatching {
                serviceContext.contentResolver.registerContentObserver(
                    android.provider.Settings.Global.getUriFor(android.provider.Settings.Global.ANIMATOR_DURATION_SCALE),
                    false, surfaceAnimationObserver,
                )
            }.isSuccess
        }
        val allowed = android.provider.Settings.Global.getFloat(serviceContext.contentResolver,
            android.provider.Settings.Global.ANIMATOR_DURATION_SCALE, 1f) > 0f
        val wasAllowed = surfaceMotionAllowed
        surfaceMotionAllowed = allowed && surfaceAnimationObserverRegistered
        if (wasAllowed && !surfaceMotionAllowed) onSurfaceMotionIneligible()
        return allowed
    }

    /** Reuse the actual route rule; the previous effective route is captured
     * separately while the old root still owns its presentation. */
    fun eligibleLiveReadmission(settings: KeyguardCardSettings, profile: KeyguardMaterialProfile?): Boolean {
        val selection = KeyguardOrbRenderModeStore.read(serviceContext)
        return selection == KeyguardOrbRenderMode.SURFACE_LIVE &&
            surfaceConfigurationEligible(settings, profile, selection) && android.animation.ValueAnimator.areAnimatorsEnabled()
    }

    private fun selectRenderRoute(current: KeyguardCardInteractionLayout, settings: KeyguardCardSettings,
                                  selection: KeyguardOrbRenderMode): Boolean {
        val previous = effectiveRenderMode
        val hadOwner = surfacePresenter != null || materialController != null
        val orb = current.findViewById<KeyguardHeaderMaterialView>(R.id.fluvi_financial_snapshot_orb)
        if (usesSurface(settings, materialProfile, selection)) {
            // Hide the old View before retiring its controller or releasing
            // its fallback reference; Surface owns presentation from here.
            orb.visibility = View.GONE
            materialController?.let {
                it.dispose()
                // Legacy disposal restores View visibility for its ordinary
                // fallback path. Surface is the new owner, so hide it again
                // before clearing any retained bitmap reference.
                orb.visibility = View.GONE
                materialController = null
                val background = current.findViewById<KeyguardHeaderMaterialView>(R.id.fluvi_keyguard_material_background)
                for (view in listOf(orb, background)) {
                    view.onRendererStateChanged = null
                    view.onFirstShaderDraw = null
                    view.onCurrentShaderDraw = null
                    view.onPreparedProgramPromoted = null
                    view.onBootstrapGeometryDrawn = null
                    view.onFirstBootstrapDraw = null
                    view.setScene(null, enabled = false)
                }
                orb.setStaticBitmap(null)
            }
            // A retained legacy root must not carry its passive paint into
            // a different presentation owner.
            current.clearPassiveStandby()
            if (surfacePresenter == null) surfacePresenter = KeyguardOrbSurfacePresenter(
                context = serviceContext,
                root = current,
                onFirstPosted = { attachment, _ ->
                    if (lifecycle.isAttached() && root === current && attachGeneration == attachment) {
                        migrateCardPositionAfterFirstRootDraw(current, attachment)
                    }
                },
                onFailure = onSurfaceFailure,
                isCaptureActive = { KeyguardCardDiagnostics.wantsEvent("R12_SURFACE") },
                onR18Prepared = { attachment, generation, at ->
                    if (r18Preparation?.let { it.attachment == attachment && it.outputGeneration == generation } == true) {
                        onR18BufferReady(attachment, generation, at)
                    }
                },
                onR18Failure = { attachment, generation, reason, releaseAfterRemoval ->
                    val bound = r18BoundOutputGeneration == generation
                    val hostGeneration = r18HostGeneration
                    val removed = if (bound && hostGeneration != null) removeR18Host(hostGeneration) else
                        r18RemovedOutputGeneration == generation || !bound
                    if (removed) releaseAfterRemoval()
                    if (r18Preparation?.outputGeneration == generation) r18Preparation = null
                    onR18Failure(attachment, generation, reason)
                },
                onR18Receipt = onR18Receipt,
                onR18Drained = onR18Drained,
                onR18Allocated = { attachment, generation, at ->
                    if (r18Preparation?.let { it.attachment == attachment && it.outputGeneration == generation } == true)
                        onR19Allocated(attachment, generation, at)
                },
                onR19Observation = onR19Observation,
            )
            orb.visibility = View.GONE
            effectiveRenderMode = selection
        } else {
            val switching = surfacePresenter != null || materialController == null
            surfacePresenter?.dispose()
            surfacePresenter = null
            if (surfaceAnimationObserverRegistered) {
                runCatching { serviceContext.contentResolver.unregisterContentObserver(surfaceAnimationObserver) }
                surfaceAnimationObserverRegistered = false
            }
            ensureLegacyController(current)
            if (switching) orb.visibility = View.VISIBLE
            effectiveRenderMode = KeyguardOrbRenderMode.LEGACY_R11
        }
        return !hadOwner || previous != effectiveRenderMode
    }

    private fun surfaceSize(): Int = serviceContext.resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_orb_size)

    internal fun presentationConfigurationApplicationsForTest(): Int = presentationConfigurationApplyCount
    internal fun effectiveRouteForFinancialDiagnostics(): Int = effectiveRenderMode.ordinal
    internal fun surfaceForTest() = surfacePresenter?.surfaceForTest()
    internal fun surfaceMetricsForTest() = surfacePresenter?.metricsForTest()

    /** Timestamp at the operation boundary; delivery is deliberately allowed
     * to be deferred by the service so capture bookkeeping never precedes a
     * visibility-critical WindowManager call. */
    private fun reportWindowDiagnostic(
        stage: String,
        detail: String,
        generation: Long?,
        observedAtUptimeMs: Long = SystemClock.uptimeMillis(),
        fields: Map<String, Any?> = emptyMap(),
    ) = onWindowDiagnostic(stage, detail, generation, observedAtUptimeMs, fields)

    fun isOwnAccessibilityWindow(windowId: Int, displayId: Int): Boolean {
        checkMainThread()
        if (displayId != android.view.Display.DEFAULT_DISPLAY) return false
        val stagedGeneration = r18HostGeneration
        return (lifecycle.isAttached() && accessibilityWindowId == windowId) ||
            (stagedGeneration != null && r18Host?.windowId(stagedGeneration) == windowId)
    }

    /** A completed inspection may name an overlay only if that exact attach is
     * still current. This prevents a stale result from claiming a later root. */
    fun recordAccessibilityWindowId(windowId: Int, expectedAttachGeneration: Long) {
        checkMainThread()
        if (lifecycle.isAttached() && expectedAttachGeneration == attachGeneration && windowId >= 0) {
            accessibilityWindowId = windowId
        }
    }

    /** Creates/configures the one retained root while detached. It has no
     * WindowManager presence and therefore grants neither visibility nor touch
     * authority on an unlocked device. */
    fun prepareRetainedView(settings: KeyguardCardSettings, profile: KeyguardMaterialProfile?) {
        checkMainThread()
        materialSettings = settings
        materialProfile = profile
        val current = root ?: createRoot().also { root = it }
        configurePresentation(current, settings.presentationMode)
        selectRenderRoute(current, settings, KeyguardOrbRenderModeStore.read(serviceContext))
        // Begin immutable source/metadata loading while detached. A later
        // authorized attach may install the prepared program without first
        // opening assets from Canvas.onDraw.
        materialController?.prepare(
            profile,
            settings.animationMode,
            settings.presentationMode,
            isFull = settings.showFinancialDetails,
        )
        if (r18PipelineEnabled && Build.VERSION.SDK_INT == 35 && effectiveRenderMode == KeyguardOrbRenderMode.SURFACE_LIVE && surfaceMotionAllowed) {
            prepareR18()
        } else surfacePresenter?.prepare(profile, surfaceSize(), surfaceSize(), settings.showFinancialDetails)
        current.visibility = View.VISIBLE
    }

    /** Request one private direct output; FULL is legal only after a current
     * positive admission has independently allowed that disclosure. */
    fun prepareR18(full: Boolean? = null, authorizedFull: Boolean = false,
                   beforeReplace: (R18Preparation) -> Boolean = { true }): R18Preparation? {
        checkMainThread()
        val profile = materialProfile ?: return null
        val intent = KeyguardFirstAuthorizedOrb.intent(materialSettings.showFinancialDetails)
        val wantsFull = full ?: (intent == KeyguardFirstAuthorizedOrb.Intent.EMPTY_AWAITING_DISCLOSURE)
        val empty = full == null && wantsFull && !authorizedFull
        if (!r18PipelineEnabled || Build.VERSION.SDK_INT != 35 || lifecycle.isAttached() || !materialSettings.requested ||
            effectiveRenderMode != KeyguardOrbRenderMode.SURFACE_LIVE || !surfaceMotionAllowed ||
            (wantsFull && !authorizedFull && !empty)) return null
        val unlocked = runCatching { serviceContext.getSystemService(android.os.UserManager::class.java).isUserUnlocked }
            .getOrDefault(false)
        if (!unlocked) return null
        val presenter = surfacePresenter ?: return null
        val size = surfaceSize()
        val visual = if (wantsFull) profile.visualKey else profile.neutralized().visualKey
        val existing = r18Preparation
        if (existing != null && existing.attachment == attachGeneration + 1L && existing.full == wantsFull &&
            existing.emptyAwaitingDisclosure == empty && existing.visualKey == visual && existing.width == size && existing.height == size &&
            existing.densityDpi == serviceContext.resources.displayMetrics.densityDpi) return existing
        val next = R18Preparation(attachGeneration + 1L, ++nextR18OutputGeneration, wantsFull, visual,
            size, size, serviceContext.resources.displayMetrics.densityDpi, empty)
        if (!beforeReplace(next)) return null
        r18Preparation = next
        r18BoundOutputGeneration = null
        if (!presenter.prepareR18(next.attachment, next.outputGeneration, profile, size, size, wantsFull, authorizedFull, empty)) {
            r18Preparation = null
            return null
        }
        return next
    }

    fun r18Preparation(): R18Preparation? { checkMainThread(); return r18Preparation }

    /** Bindable ownership does not assert that any frame exists. */
    fun r19AllocatedOutput(preparation: R18Preparation): Any? {
        checkMainThread()
        if (r18Preparation != preparation) return null
        return surfacePresenter?.r18AllocatedOutput(preparation.attachment, preparation.outputGeneration,
            preparation.full, preparation.width, preparation.height)
    }

    fun authorizeR19First(preparation: R18Preparation, ticket: KeyguardR19FirstPaintTicket): Boolean {
        checkMainThread()
        if (r18Preparation != preparation || !preparation.emptyAwaitingDisclosure || !preparation.full) return false
        val profile = materialProfile ?: return false
        if (profile.visualKey != preparation.visualKey) return false
        return surfacePresenter?.authorizeR19First(preparation.attachment, preparation.outputGeneration, profile, ticket) == true
    }

    fun r19AllocatedAt(preparation: R18Preparation): Long? {
        checkMainThread()
        return if (r18Preparation == preparation) surfacePresenter?.r19AllocatedAt(preparation.attachment, preparation.outputGeneration) else null
    }

    fun r18ReadyAt(preparation: R18Preparation): Long? {
        checkMainThread()
        return if (r18Preparation == preparation) surfacePresenter?.r18ReadyAt(preparation.attachment, preparation.outputGeneration) else null
    }

    fun r18PreparedOutput(preparation: R18Preparation): Any? {
        checkMainThread()
        if (r18Preparation != preparation) return null
        val profile = materialProfile ?: return null
        return surfacePresenter?.r18PreparedOutput(preparation.attachment, preparation.outputGeneration,
            profile, preparation.full, preparation.width, preparation.height)
    }

    fun stageR18Host(generation: Long, settings: KeyguardCardSettings): Boolean {
        checkMainThread()
        if (lifecycle.isAttached() || r18HostGeneration != null || r18Preparation == null) return false
        val currentRoot = root ?: return false
        val host = r18Host ?: KeyguardOrbInertHost(serviceContext, manager,
            onReady = { actual, view, id ->
                mainHandler.post { if (r18HostGeneration == actual) onR18HostReady(actual, view, id) }
            },
            onFailure = { actual, reason ->
                if (r18HostGeneration == actual) {
                    val removed = removeR18Host(actual)
                    if (!removed && r18Host?.stagedView(actual) == null) r18HostGeneration = null
                    onR18Failure(attachGeneration + 1L, r18Preparation?.outputGeneration ?: 0L, reason)
                }
            }, onAttached = { actual, at ->
                if (r18HostGeneration == actual) onR18HostAttached(actual, at)
            }).also { r18Host = it }
        r18HostGeneration = generation
        if (!host.stage(generation, geometry(settings, currentRoot))) {
            r18HostGeneration = null
            return false
        }
        return true
    }

    fun hasR18Host(generation: Long): Boolean { checkMainThread(); return r18HostGeneration == generation }

    fun stagedR18Host(generation: Long): View? {
        checkMainThread()
        return if (r18HostGeneration == generation) r18Host?.stagedView(generation) else null
    }

    fun bindR18Host(hostGeneration: Long, preparation: R18Preparation, done: (Boolean) -> Unit) {
        checkMainThread()
        val host = r18Host?.readyView(hostGeneration)
        if (r18HostGeneration != hostGeneration || r18Preparation != preparation || host == null) {
            done(false); return
        }
        surfacePresenter?.bindR18(host, preparation.attachment, preparation.outputGeneration) { success ->
            if (success && r18HostGeneration == hostGeneration && r18Preparation == preparation)
                r18BoundOutputGeneration = preparation.outputGeneration
            done(success && r18HostGeneration == hostGeneration && r18Preparation == preparation)
        } ?: done(false)
    }

    fun isR18Bound(hostGeneration: Long, preparation: R18Preparation): Boolean {
        checkMainThread()
        return r18HostGeneration == hostGeneration && r18Preparation == preparation &&
            r18BoundOutputGeneration == preparation.outputGeneration && r18Host?.readyView(hostGeneration) != null
    }

    fun removeR18Host(generation: Long): Boolean {
        checkMainThread()
        if (r18HostGeneration != generation) return false
        val hostView = r18Host?.stagedView(generation)
        val removed = r18Host?.remove(generation) == true
        if (removed) {
            val content = root
            if (content != null && content.parent === hostView) (hostView as? ViewGroup)?.removeView(content)
            r18RemovedOutputGeneration = r18BoundOutputGeneration
            r18BoundOutputGeneration = null
            r18HostGeneration = null
        }
        return removed
    }

    fun revealR18(preparation: R18Preparation, boundary: () -> Boolean, nativeApplied: () -> Boolean, done: (Boolean) -> Unit) {
        checkMainThread()
        if (r18Preparation != preparation || !lifecycle.isAttached()) { done(false); return }
        surfacePresenter?.revealR18(preparation.attachment, preparation.outputGeneration, boundary, nativeApplied, done) ?: done(false)
    }

    /** Called under exact coordinator authority; safe even with Main held. */
    fun sealR18FromAnyThread(attachment: Long, outputGeneration: Long) {
        surfacePresenter?.sealR18(attachment, outputGeneration)
    }

    fun showOrUpdate(presentation: FluviFinancialCardPresentation, settings: KeyguardCardSettings,
                     directHostGeneration: Long? = null): Result {
        checkMainThread()
        // A synchronous callback is not a new authorization. The outer
        // restriction retains authority until its permitted content is bound.
        if (windowRestriction != null) return Result.PENDING
        val previousPresentation = appliedPresentation
        val current = root ?: createRoot().also { root = it }
        val pendingAttach = !lifecycle.isAttached()
        val previousController = materialController
        val restriction = if (!pendingAttach && current.isAttachedToWindow && previousController != null &&
            appliedPresentationConfiguration?.mode == KeyguardCardPresentationMode.ORB &&
            previousPresentation?.full == true && !presentation.full) {
            WindowRestriction(current, attachGeneration, previousController,
                newTransitionTrace("DOWNGRADE", current, previousController)).also {
                // Publish the permitted object before any callback or lazy
                // bitmap can be reached by a settings-only refresh.
                appliedPresentation = presentation
                windowRestriction = it
            }
        } else null
        var coherentRestriction = false
        try {
        if (restriction != null) {
            restriction.trace?.revoke = SystemClock.uptimeMillis()
            restriction.token = restriction.controller.enterRestrictiveTransition()
            if (KeyguardR224RestrictionTestHooks.ENABLED) KeyguardR224RestrictionTestHooks.afterRevocation()
        }
        val modeChanged = appliedPresentationConfiguration?.mode?.let { it != settings.presentationMode } == true
        materialSettings = settings
        val directPreparation = r18Preparation
        val useR18 = pendingAttach && directHostGeneration != null && directPreparation != null &&
            isR18Bound(directHostGeneration, directPreparation) && directPreparation.full == presentation.full &&
            r18PreparedOutput(directPreparation) != null
        if (pendingAttach && directHostGeneration != null && !useR18) return Result.PENDING
        if (pendingAttach && directHostGeneration == null && r18HostGeneration != null) return Result.PENDING
        if (pendingAttach && directHostGeneration == null && surfacePresenter?.r18OutputsOutstanding() == true) {
            surfacePresenter?.sealR18()
            return Result.PENDING
        }
        if (useR18 && (KeyguardOrbRenderModeStore.read(serviceContext) != KeyguardOrbRenderMode.SURFACE_LIVE ||
                !eligibleLiveReadmission(settings, materialProfile))) return Result.FAILED
        if (pendingAttach) attachedConfiguredMode = KeyguardOrbRenderModeStore.read(serviceContext)
        val routeChanged = selectRenderRoute(current, settings, attachedConfiguredMode)
        if (pendingAttach && surfacePresenter != null) {
            surfaceDiagnostic = armSurfaceDiagnostic(attachGeneration + 1L)
        }
        if (pendingAttach) materialController?.beginAuthorizedShow()
        try {
        if (modeChanged) {
            current.cancelInteraction("presentationChanged")
            onInteractionDiagnostic("KG|PRESENTATION_CHANGED", settings.presentationMode.wireValue)
        }
        val presentationConfigurationChanged = configurePresentation(current, settings.presentationMode)
        val resolvedGeometry = dragPreview ?: geometry(settings, current)

        // Revoke the old full target before any other in-place disclosure
        // mutation; the presenter installs the permitted neutral guard.
        if (!pendingAttach && appliedPresentation?.full == true && !presentation.full && surfacePresenter != null) {
            updateMaterialForPresentation(presentation)
        }

        if (!lifecycle.isAttached()) {
            // A terminal hide makes the retained root locally invisible before
            // removal. Restore it only after the fresh surface decision has
            // reached this checked attach path.
            current.visibility = View.VISIBLE
            apply(current, presentation, force = true, mode = settings.presentationMode)
            // Configure the retained scene while detached. If the bounded
            // artifact lane is already ready, RuntimeShader construction is
            // complete before WindowManager.addView and cannot tax first draw.
            if (!useR18) updateMaterialForPresentation(presentation)
            val nextAttach = attachGeneration + 1L
            materialController?.bindFirstOfferReporter(armFirstOfferDiagnostic(nextAttach))
            coldRootObservation?.cancel()
            coldRootObservation = armColdRootDiagnostic(nextAttach)?.let { publish ->
                KeyguardColdRootObservation(current, publish).also { it.start() }
            }
            // Arm before addView. On overlay hosts where attach finishes after
            // addView returns, the observation retains this request through
            // the attach callback and installs pre-draw on the real observer.
            val bootstrapToken = materialController
                ?.takeIf { it.requiresBootstrapForNextAttach() }
                ?.currentBootstrapToken()
            if (bootstrapToken != null) {
                ensureFrameCommitObservation(current, nextAttach, bootstrapToken).startBeforeNextDraw()
            }
            if (!useR18) reportWindowDiagnostic("ADD_VIEW_BEGIN", "windowManager", nextAttach)
            return runCatching {
                if (useR18) {
                    check(r18Host?.promote(requireNotNull(directHostGeneration), current, resolvedGeometry) == true)
                } else {
                    manager.addView(current, parameters(resolvedGeometry))
                    // This marks the real WindowManager.addView return.
                    reportWindowDiagnostic("ADD_VIEW_RETURN", "success", nextAttach)
                }
            }.fold(
                onSuccess = {
                    lifecycle.onAttachSucceeded()
                    attachGeneration += 1L
                    if (KeyguardCardDiagnostics.wantsEvent("VIEW_ATTACH_STATE")) {
                        reportWindowDiagnostic("VIEW_ATTACH_STATE",
                            if (current.isAttachedToWindow) "alreadyAttached" else "pending", attachGeneration)
                    }
                    appliedPresentation = presentation
                    appliedGeometry = resolvedGeometry
                    firstShaderDrawAttachGeneration = attachGeneration
                    // The pre-attach arm above must remain intact. Re-arm
                    // only if material selection changed synchronously during
                    // addView; never wait for a later accessibility event.
                    observeBootstrapBeforeNextDraw()
                    // Main keeps WindowManager/layer ownership.  The
                    // controller receives the actual retained root so the
                    // API-34 standalone ORB producer can parent one
                    // non-input child SurfaceControl below this overlay
                    // instead of opening a second window.
                    materialController?.onAttached(attachGeneration, current)
                    observeFirstRootDraw(current, attachGeneration)
                    reportWindowDiagnostic("POST_ADD_SETUP_COMPLETE", "success", attachGeneration)
                    if (settings.cardPosition == null) {
                        // Only an attached window has reliable insets. Defer
                        // this one-time preference migration until the first
                        // root draw has completed; it is not needed to render
                        // the initially authorized geometry.
                        pendingCardPositionMigration = attachGeneration to resolvedGeometry.cardPosition
                    }
                    Result.ATTACHED
                },
                onFailure = {
                    // A SurfaceView may already have been authorized while
                    // the retained root was detached. Failed addView must
                    // revoke that exact target rather than leaving pending
                    // preparation or holder work alive without a window.
                    surfacePresenter?.detached()
                    surfaceDiagnostic = null
                    coldRootObservation?.cancel()
                    coldRootObservation = null
                    bootstrapToken?.let { token ->
                        firstFrameCommitObservation
                            ?.takeIf { observation -> observation.matches(current, nextAttach, token) }
                            ?.also { observation ->
                                observation.cancel()
                                firstFrameCommitObservation = null
                            }
                    }
                    lifecycle.onAttachFailed()
                    appliedPresentation = null
                    appliedGeometry = null
                    accessibilityWindowId = null
                    reportWindowDiagnostic("ATTACH_FAILED", "${it.javaClass.simpleName}", nextAttach)
                    Result.FAILED
                },
            )
        }

        // An exceptional remove failure can leave the retained root attached
        // but locally hidden. Only a new, already-authorized presentation may
        // make that existing window visible again.
        if (secureRebindRequired) {
            // A prior neutral-bind failure hid this same root. Bind the new
            // authorized scene completely before making it visible again.
            try {
                apply(current, presentation, force = true, mode = settings.presentationMode)
                updateMaterialForPresentation(presentation)
                // Failed removal can leave the real root attached while its
                // stopped controller is detached. A fresh authorization is
                // the only point at which it may regain this attachment.
                materialController?.onAttached(attachGeneration, current)
                secureRebindRequired = false
            } catch (_: Throwable) {
                current.visibility = View.INVISIBLE
                return Result.FAILED
            }
        }
        if (current.visibility != View.VISIBLE) current.visibility = View.VISIBLE

        val contentBaseline = if (restriction != null) previousPresentation else appliedPresentation
        val contentChanged = restriction != null || contentBaseline?.visualKey != presentation.visualKey
        val geometryChanged = appliedGeometry != resolvedGeometry
        if (lifecycle.renderOperation(contentChanged, geometryChanged) == KeyguardCardWindowLifecycle.Operation.NONE) {
            if (routeChanged || presentationConfigurationChanged && surfacePresenter != null) updateMaterialForPresentation(presentation)
            // A no-op surface confirmation must not strand a bootstrap whose
            // pre-attach observer raced the actual View attachment.
            observeBootstrapBeforeNextDraw()
            return if (presentationConfigurationChanged || routeChanged) Result.LAYOUT_UPDATED else Result.NO_OP
        }
        if (restriction != null) {
            // The previous object remains only the diff baseline. Force the
            // restrictive text, accessibility and bitmap bind once, then
            // select its neutral material before fallible WM geometry work.
            apply(current, presentation, force = true, mode = settings.presentationMode)
            updateMaterialForPresentation(presentation)
            coherentRestriction = true
            restriction.trace?.bind = "OK"
            if (root !== current || attachGeneration != restriction.attachment || !lifecycle.isAttached()) {
                restriction.trace?.outcome = "OWNER_CHANGED"
                return Result.FAILED
            }
        } else if (contentChanged) {
            apply(current, presentation, force = false, mode = settings.presentationMode)
        }
        if (geometryChanged) {
            if (!updateLayout(current, resolvedGeometry)) {
                restriction?.trace?.layout = "FAILED"
                restriction?.trace?.outcome = "FAILED"
                if (restriction != null && !current.isAttachedToWindow) {
                    restriction.controller.stop("privacy-layout-detached")
                }
                return Result.FAILED
            }
            restriction?.trace?.layout = "APPLIED"
        } else restriction?.trace?.layout = "UNCHANGED"
        if (restriction != null && (root !== current || attachGeneration != restriction.attachment ||
                !lifecycle.isAttached() || !current.isAttachedToWindow)) {
            restriction.trace?.outcome = "OWNER_CHANGED"
            return Result.FAILED
        }
        val wasFull = contentBaseline?.full == true
        appliedPresentation = presentation
        if (restriction == null) updateMaterialForPresentation(presentation)
        observeBootstrapBeforeNextDraw()
        val outcome = when {
            contentChanged && wasFull && !presentation.full -> Result.REDACTED
            contentChanged -> Result.CONTENT_UPDATED
            else -> Result.LAYOUT_UPDATED
        }
        restriction?.trace?.outcome = outcome.name
        return outcome
        } finally {
            if (pendingAttach) materialController?.endAuthorizedShow()
        }
        } catch (error: Throwable) {
            if (restriction == null) throw error
            if (!coherentRestriction) {
                restriction.trace?.bind = "FAILED"
                failRestrictedUpdate(restriction, presentation)
            }
            restriction.trace?.outcome = "FAILED"
            return Result.FAILED
        } finally {
            if (restriction != null) {
                val sameOwner = root === restriction.root && attachGeneration == restriction.attachment && lifecycle.isAttached()
                try {
                    restriction.controller.finishRestrictiveTransition(restriction.token, coherentRestriction && sameOwner)
                } catch (_: Throwable) {
                    failRestrictedUpdate(restriction, presentation)
                    if (windowRestriction === restriction) windowRestriction = null
                    restriction.trace?.outcome = "FINISH_FAILED"
                    reportTransitionTrace(restriction.trace)
                    return Result.FAILED
                }
                if (windowRestriction === restriction) windowRestriction = null
                if (coherentRestriction && sameOwner && root === restriction.root &&
                    attachGeneration == restriction.attachment && lifecycle.isAttached()) {
                    // Reentrant profile/layout calls are replayed only after
                    // the old FULL owner has lost authority and the guard is
                    // finished; they consume the durable permitted object.
                    try {
                        restriction.pendingMaterial?.let { (profile, latest) -> updateMaterial(profile, latest) }
                        restriction.pendingLayout?.let(::updateLayoutSettings)
                    } catch (_: Throwable) {
                        failRestrictedUpdate(restriction, presentation)
                        restriction.trace?.outcome = "REFRESH_FAILED"
                        reportTransitionTrace(restriction.trace)
                        return Result.FAILED
                    }
                }
                reportTransitionTrace(restriction.trace)
            }
        }
    }

    private fun failRestrictedUpdate(owner: WindowRestriction, permitted: FluviFinancialCardPresentation) {
        if (root !== owner.root || attachGeneration != owner.attachment || !lifecycle.isAttached()) return
        appliedPresentation = permitted
        secureRebindRequired = true
        owner.root.visibility = View.INVISIBLE
        acceptedBootstrapToken = null
        firstFrameCommitObservation?.cancel()
        firstFrameCommitObservation = null
        // Existing stop/hide performs exact-child retirement and removal. If
        // removal throws, keep both the permitted state and invisible root.
        runCatching { hide() }
        if (root === owner.root && owner.root.isAttachedToWindow) {
            appliedPresentation = permitted
            owner.root.visibility = View.INVISIBLE
            secureRebindRequired = true
        }
    }

    /** Called by the narrow layout patch path. It performs a retained-root
     * layout update only; no inspection and no financial resolver are touched. */
    fun updateLayoutSettings(settings: KeyguardCardSettings) {
        checkMainThread()
        windowRestriction?.let { it.pendingLayout = settings; return }
        val current = root ?: return
        val modeChanged = appliedPresentationConfiguration?.mode?.let { it != settings.presentationMode } == true
        materialSettings = settings
        if (modeChanged) {
            current.cancelInteraction("presentationChanged")
            onInteractionDiagnostic("KG|PRESENTATION_CHANGED", settings.presentationMode.wireValue)
        }
        val presentationConfigurationChanged = configurePresentation(current, settings.presentationMode)
        val routeChanged = selectRenderRoute(current, settings, if (lifecycle.isAttached()) attachedConfiguredMode
            else KeyguardOrbRenderModeStore.read(serviceContext))
        val presentation = appliedPresentation ?: return
        val next = geometry(settings, current)
        if (lifecycle.isAttached() && dragPreview == null && appliedGeometry != next) updateLayout(current, next)
        if (modeChanged || presentationConfigurationChanged || routeChanged) updateMaterialForPresentation(presentation)
    }

    /** Terminal hide: stop local visibility first and never restore a drag
     * preview before removeViewImmediate. Normal CANCEL still restores. */
    fun hide(onIsolatedLayerHideCommitted: ((Long) -> Unit)? = null,
             onRetirementEvent: ((KeyguardOrbRetirementEvent) -> Unit)? = null,
             onSurfaceRevoked: ((Long, Long, KeyguardOrbSurfaceMetrics, KeyguardOrbSurfaceMetrics.HolderOperation) -> Unit)? = null): Boolean {
        checkMainThread()
        val current = root ?: return false
        val trace = if (lifecycle.isAttached() && appliedPresentationConfiguration?.mode == KeyguardCardPresentationMode.ORB)
            newTransitionTrace("HIDE", current, materialController) else null
        val priorTrace = terminalTransitionTrace
        terminalTransitionTrace = trace
        try {
        KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.REVOKE, attachment = attachGeneration)
        // Both routes seal their exact worker/output before root removal.
        surfacePresenter?.sealR18()
        r18Preparation = null
        // Revoke the worker first, then change the root's visibility before
        // any child-destruction callback can wait for an entered holder call.
        surfacePresenter?.revokeCurrent(hideChild = false, onRevoked = onSurfaceRevoked)
        if (lifecycle.isAttached()) {
            current.visibility = View.INVISIBLE
            trace?.localHide = SystemClock.uptimeMillis()
            KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.INVISIBLE, attachment = attachGeneration)
            reportWindowDiagnostic("LOCAL_HIDE_APPLIED", "invisible", attachGeneration)
        }
        coldRootObservation?.cancel()
        coldRootObservation = null
        firstRootDrawObservation?.cancel()
        firstRootDrawObservation = null
        firstFrameCommitObservation?.cancel()
        firstFrameCommitObservation = null
        acceptedBootstrapToken = null
        pendingCardPositionMigration = null
        firstShaderDrawAttachGeneration = null
        current.cancelInteraction("detach", restorePosition = false)
        clearDragFrame()
        trace?.revoke = SystemClock.uptimeMillis()
        materialController?.stop("hide", onIsolatedLayerHideCommitted, onRetirementEvent)
        if (lifecycle.hideOperation() == KeyguardCardWindowLifecycle.Operation.NONE) {
            r18HostGeneration?.let(::removeR18Host)
            return false
        }
        reportWindowDiagnostic("REMOVE_VIEW_BEGIN", "windowManager", attachGeneration)
        KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.REMOVE_BEGIN, attachment = attachGeneration)
        val directHost = r18HostGeneration
        val removed = runCatching {
            if (directHost != null) check(removeR18Host(directHost)) else manager.removeViewImmediate(current)
        }
        KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.REMOVE_RETURN, attachment = attachGeneration, extra = if (removed.isSuccess) 1 else 0)
        val stillAttached = current.isAttachedToWindow
        if (removed.isSuccess || !stillAttached) {
            lifecycle.onDetached()
            secureRebindRequired = false
            appliedPresentation = null
            appliedGeometry = null
            accessibilityWindowId = null
        } else lifecycle.onUpdateFailed(stillAttached = true)
        surfacePresenter?.detached()
        surfaceDiagnostic = null
        if (removed.isSuccess) {
            reportWindowDiagnostic("REMOVE_VIEW_RETURN", "success", attachGeneration)
        } else {
            reportWindowDiagnostic("DETACH_FAILED", "${removed.exceptionOrNull()?.javaClass?.simpleName ?: "unknown"}", attachGeneration)
        }
        trace?.outcome = if (removed.isSuccess) "REMOVED" else if (stillAttached) "REMOVE_FAILED_ATTACHED" else "DETACHED"
        return removed.isSuccess
        } finally {
            terminalTransitionTrace = priorTrace
            reportTransitionTrace(trace)
        }
    }

    fun dispose() {
        coldRootObservation?.cancel()
        coldRootObservation = null
        firstRootDrawObservation?.cancel()
        firstRootDrawObservation = null
        firstFrameCommitObservation?.cancel()
        firstFrameCommitObservation = null
        acceptedBootstrapToken = null
        pendingCardPositionMigration = null
        firstShaderDrawAttachGeneration = null
        root?.cancelInteraction("dispose", restorePosition = false)
        clearDragFrame()
        materialController?.stop("dispose")
        hide()
        materialController?.dispose()
        surfacePresenter?.dispose()
        if (surfaceAnimationObserverRegistered) {
            runCatching { serviceContext.contentResolver.unregisterContentObserver(surfaceAnimationObserver) }
            surfaceAnimationObserverRegistered = false
        }
        surfaceMotionAllowed = false
        root = null
        secureRebindRequired = false
        materialController = null
        surfacePresenter = null
        appliedPresentationConfiguration = null
    }

    fun updateMaterial(profile: KeyguardMaterialProfile?, settings: KeyguardCardSettings) {
        checkMainThread()
        windowRestriction?.let { it.pendingMaterial = profile to settings; return }
        materialProfile = profile
        materialSettings = settings
        root?.let { current ->
            selectRenderRoute(current, settings, if (lifecycle.isAttached()) attachedConfiguredMode
                else KeyguardOrbRenderModeStore.read(serviceContext))
        }
        materialController?.prepare(
            profile,
            settings.animationMode,
            settings.presentationMode,
            isFull = settings.showFinancialDetails,
        )
        if (r18PipelineEnabled && Build.VERSION.SDK_INT == 35 && effectiveRenderMode == KeyguardOrbRenderMode.SURFACE_LIVE &&
            surfaceMotionAllowed && !lifecycle.isAttached()) prepareR18()
        else surfacePresenter?.prepare(profile, surfaceSize(), surfaceSize(), settings.showFinancialDetails)
        appliedPresentation?.let {
            updateMaterialForPresentation(it)
            observeBootstrapBeforeNextDraw()
        }
    }

    fun materialDiagnostics(): KeyguardMaterialDiagnostics? {
        checkMainThread()
        return materialController?.diagnostics()
    }

    private fun createRoot(): KeyguardCardInteractionLayout {
        val created = LayoutInflater.from(serviceContext).inflate(
            R.layout.fluvi_keyguard_card,
            null,
            false,
        ) as KeyguardCardInteractionLayout
        // The retained root survives presentation switches; route at click
        // time instead of capturing the initial presentation in this listener.
        created.setOnClickListener {
            rootClickRouter.onRootClick(materialSettings.presentationMode)
        }
        created.findViewById<View>(R.id.fluvi_financial_snapshot_toggle).setOnClickListener { onToggle() }
        created.listener = object : KeyguardCardInteractionLayout.Listener {
            override fun onPointerDown() {
                onInteractionStarted()
                onInteractionDiagnostic("KG|POINTER_DOWN", "attach=$attachGeneration")
            }

            override fun onLongPress() {
                beginDrag()
                onInteractionDiagnostic("KG|LONG_PRESS", "attach=$attachGeneration")
            }

            override fun onDrag(deltaRawX: Float, deltaRawY: Float) {
                val start = dragStart ?: return
                dragMoveCount += 1
                dragPreview = previewKeyguardOverlayGeometry(
                    start,
                    materialSettings.presentationMode,
                    deltaRawX,
                    deltaRawY,
                )
                scheduleDragFrame()
            }

            override fun onDragEnd() = commitDrag()

            override fun onDragCancel(reason: String, restorePosition: Boolean) =
                cancelDrag(reason, restorePosition)

            override fun onInteractionFinished() = Unit
        }
        return created
    }

    private fun ensureLegacyController(created: KeyguardCardInteractionLayout) {
        if (materialController != null) return
        materialController = KeyguardCardMaterialController(
            orb = created.findViewById(R.id.fluvi_financial_snapshot_orb),
            background = created.findViewById(R.id.fluvi_keyguard_material_background),
            backgroundVeil = created.findViewById(R.id.fluvi_keyguard_material_veil),
            drawEvidenceEnabled = drawEvidenceEnabled,
            mainWorkEvidence = mainWorkEvidence,
            drawEvidenceOwner = KeyguardCardDiagnostics::drawEvidenceOwner,
            isolatedOrbRenderBarrier = isolatedOrbRenderBarrier,
            isolatedOrbFrameObserver = isolatedOrbFrameObserver,
            isolatedOrbPublicationObserver = isolatedOrbPublicationObserver,
            isolatedOrbMaterialTimeSource = isolatedOrbMaterialTimeSource,
        ).also { controller ->
            controller.onPreparationStage = { stage, fields ->
                reportWindowDiagnostic(
                    stage,
                    fields["programKey"]?.toString() ?: "material",
                    null,
                    fields = fields,
                )
            }
            controller.onIsolatedLayerHideSubmitted = { submission ->
                val trace = terminalTransitionTrace ?: windowRestriction?.trace
                if (trace != null && trace.attachment == submission.lease.attachment &&
                    (trace.generation == null || trace.generation == submission.lease.generation)) {
                    trace.child = submission.childIdentity
                    trace.hideSubmit = submission.submittedAtUptimeMs
                    trace.hideReturn = submission.applyReturnedAtUptimeMs
                    trace.hideApplied = submission.transactionApplied
                }
                reportWindowDiagnostic(
                    stage = "ISOLATED_LAYER_HIDE_SUBMITTED",
                    detail = "isolatedSurfaceControl",
                    generation = submission.lease.attachment,
                    observedAtUptimeMs = submission.submittedAtUptimeMs,
                    fields = mapOf(
                        "leaseGeneration" to submission.lease.generation,
                        "transactionApplied" to submission.transactionApplied,
                        "applyReturnedAtUptimeMs" to (submission.applyReturnedAtUptimeMs ?: "UNOBSERVED"),
                        "programKey" to submission.lease.programKey,
                        "width" to submission.lease.width,
                        "height" to submission.lease.height,
                    ),
                )
            }
            controller.onBootstrapGeometryDrawn = bootstrapGeometry@{ token ->
                val capturedAttach = firstShaderDrawAttachGeneration ?: return@bootstrapGeometry
                val currentRoot = root ?: return@bootstrapGeometry
                if (!lifecycle.isAttached() || attachGeneration != capturedAttach) return@bootstrapGeometry
                // Canvas.onDraw uses this tiny, functional acknowledgement on
                // every bootstrap traversal. It does not take diagnostics
                // locks and it remains valid even if the diagnostic
                // first-bootstrap callback already fired before an observer
                // was armed.
                firstFrameCommitObservation
                    ?.takeIf { it.matches(currentRoot, capturedAttach, token) }
                    ?.markExpectedDrawObserved(capturedAttach, token)
            }
            controller.onFirstBootstrapOrbDraw = bootstrapDraw@{ observedAtUptimeMs ->
                val capturedAttach = firstShaderDrawAttachGeneration ?: return@bootstrapDraw
                val currentRoot = root
                if (currentRoot != null && attachGeneration == capturedAttach && lifecycle.isAttached()) {
                    // The material View invokes this while Canvas draw is in
                    // progress. Functional acknowledgement is deliberately
                    // separate above; keep diagnostics outside dispatch.
                    mainHandler.post {
                        if (lifecycle.isAttached() && root === currentRoot && attachGeneration == capturedAttach) {
                            onBootstrapDraw(KeyguardFirstDrawEvent(capturedAttach, observedAtUptimeMs))
                        }
                    }
                }
            }
            controller.onLivePromoted = livePromoted@{ token ->
                val capturedAttach = firstShaderDrawAttachGeneration
                val currentRoot = root
                // This is the functional state-transition boundary. Preserve
                // it before posting diagnostics so a busy main queue cannot
                // make LIVE look later than it actually became drawable.
                val promotedAtUptimeMs = SystemClock.uptimeMillis()
                // The controller transition is already complete at this
                // point. Defer capture publication so it never extends the
                // frame-commit-to-LIVE critical path.
                mainHandler.post {
                    if (capturedAttach != null && currentRoot != null &&
                        lifecycle.isAttached() && root === currentRoot &&
                        attachGeneration == capturedAttach && acceptedBootstrapToken == token
                    ) onLivePromotion(KeyguardFirstDrawEvent(capturedAttach, promotedAtUptimeMs))
                }
            }
            controller.onFirstOrbShaderDraw = shaderDraw@{ observedAtUptimeMs ->
                val capturedAttach = firstShaderDrawAttachGeneration ?: return@shaderDraw
                val currentRoot = root ?: return@shaderDraw
                // KeyguardHeaderMaterialView invokes this while Canvas draw is
                // in progress. Service diagnostics must run only after that
                // dispatch has unwound, and only for this exact attach.
                mainHandler.post {
                    if (firstShaderDrawAttachGeneration != capturedAttach ||
                        !lifecycle.isAttached() ||
                        root !== currentRoot ||
                        attachGeneration != capturedAttach
                    ) return@post
                    onFirstShaderDraw(
                        KeyguardFirstDrawEvent(
                            attachGeneration = capturedAttach,
                            observedAtUptimeMs = observedAtUptimeMs,
                        ),
                    )
                    // The one-time legacy position persistence is unrelated
                    // to the first visible shader frame. Keep it behind that
                    // frame rather than between bootstrap commit and LIVE.
                    migrateCardPositionAfterFirstRootDraw(currentRoot, capturedAttach)
                }
            }
        }
    }

    private fun apply(
        root: KeyguardCardInteractionLayout,
        presentation: FluviFinancialCardPresentation,
        force: Boolean,
        mode: KeyguardCardPresentationMode,
    ) {
        val previous = appliedPresentation
        fun changed(selector: (FluviFinancialCardPresentation) -> Any?): Boolean =
            force || previous == null || selector(previous) != selector(presentation)
        if (changed { it.focus }) root.findViewById<TextView>(R.id.fluvi_financial_snapshot_focus).text = presentation.focus
        if (changed { it.primary }) root.findViewById<TextView>(R.id.fluvi_financial_snapshot_primary).text = presentation.primary
        if (changed { it.secondary }) root.findViewById<TextView>(R.id.fluvi_financial_snapshot_secondary).text = presentation.secondary
        if (changed { it.contentDescription }) {
            root.contentDescription = if (mode == KeyguardCardPresentationMode.CARD) {
                presentation.contentDescription
            } else {
                "Fluvi · animált orb"
            }
        }
        if (surfacePresenter == null && (force || previous?.visualKey != presentation.visualKey)) {
            root.findViewById<KeyguardHeaderMaterialView>(R.id.fluvi_financial_snapshot_orb).setStaticBitmap(presentation.orb)
        }
        val eventText = presentation.event?.let { "${presentation.eventLabel ?: "Utolsó tétel"}: $it" } ?: ""
        if (changed { it.event } || changed { it.eventLabel }) {
            root.findViewById<TextView>(R.id.fluvi_financial_snapshot_event).apply {
                text = eventText
                visibility = if (presentation.event == null) View.GONE else View.VISIBLE
            }
        }
        if (changed { it.showToggle } || changed { it.toggleLabel }) {
            root.findViewById<TextView>(R.id.fluvi_financial_snapshot_toggle).apply {
                text = presentation.toggleLabel
                visibility = if (presentation.showToggle) View.VISIBLE else View.GONE
                contentDescription = if (presentation.showToggle) presentation.toggleLabel else null
            }
        }
        if (mode == KeyguardCardPresentationMode.CARD) root.post { fitCardContent(root) }
    }

    private fun fitCardContent(root: View) {
        if (!root.isAttachedToWindow || !KeyguardCardContentOverflow.fit(root)) return
        root.post { if (root.isAttachedToWindow) KeyguardCardContentOverflow.fit(root) }
    }

    private data class PresentationConfigurationKey(
        val mode: KeyguardCardPresentationMode,
        val densityDpi: Int,
        val orientation: Int,
        val screenWidthDp: Int,
        val screenHeightDp: Int,
        val layoutDirection: Int,
    )

    private fun configurePresentation(root: KeyguardCardInteractionLayout, mode: KeyguardCardPresentationMode): Boolean {
        val configuration = serviceContext.resources.configuration
        val key = PresentationConfigurationKey(
            mode = mode,
            densityDpi = serviceContext.resources.displayMetrics.densityDpi,
            orientation = configuration.orientation,
            screenWidthDp = configuration.screenWidthDp,
            screenHeightDp = configuration.screenHeightDp,
            layoutDirection = root.layoutDirection,
        )
        if (appliedPresentationConfiguration == key) return false
        appliedPresentationConfiguration = key
        presentationConfigurationApplyCount += 1
        val content = root.findViewById<View>(R.id.fluvi_financial_snapshot_content)
        val background = root.findViewById<View>(R.id.fluvi_keyguard_material_background)
        val veil = root.findViewById<View>(R.id.fluvi_keyguard_material_veil)
        val orb = root.findViewById<KeyguardHeaderMaterialView>(R.id.fluvi_financial_snapshot_orb)
        val size = if (mode == KeyguardCardPresentationMode.ORB) {
            serviceContext.resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_orb_size)
        } else (38f * serviceContext.resources.displayMetrics.density).toInt()
        orb.layoutParams = FrameLayout.LayoutParams(
            size,
            size,
            if (mode == KeyguardCardPresentationMode.ORB) Gravity.CENTER else Gravity.TOP or Gravity.END,
        ).apply {
            if (mode == KeyguardCardPresentationMode.CARD) {
                val margin = (12f * serviceContext.resources.displayMetrics.density).toInt()
                setMargins(margin, margin, margin, margin)
            }
        }
        val card = mode == KeyguardCardPresentationMode.CARD
        content.visibility = if (card) View.VISIBLE else View.GONE
        // The material controller owns actual animated-background visibility;
        // standalone orb starts with both card-only layers absent.
        if (!card) {
            background.visibility = View.GONE
            veil.visibility = View.GONE
        }
        root.setBackgroundResource(if (card) R.drawable.fluvi_financial_snapshot_background else android.R.color.transparent)
        root.clipToOutline = card
        root.contentDescription = if (card) "Fluvi · Pénzügyi pillanatkép" else "Fluvi · animált orb"
        return true
    }

    private fun geometry(settings: KeyguardCardSettings, root: View?): KeyguardOverlayGeometry =
        resolveKeyguardOverlayGeometry(
            bounds = usableBounds(root),
            density = serviceContext.resources.displayMetrics.density,
            cardHeightPx = serviceContext.resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_card_height),
            presentationMode = settings.presentationMode,
            cardPosition = settings.cardPosition,
            orbPosition = settings.orbPosition,
            legacyVerticalOffsetDp = settings.verticalOffsetDp,
            orbSizePx = serviceContext.resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_orb_size),
        )

    private fun usableBounds(root: View?): KeyguardUsableBounds {
        val metrics = serviceContext.resources.displayMetrics
        var width = metrics.widthPixels
        var height = metrics.heightPixels
        var leftInset = 0
        var topInset = 0
        var rightInset = 0
        var bottomInset = 0
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val insets = root?.rootWindowInsets?.getInsetsIgnoringVisibility(
                WindowInsets.Type.systemBars() or WindowInsets.Type.displayCutout(),
            )
            if (insets != null) {
                leftInset = insets.left
                topInset = insets.top
                rightInset = insets.right
                bottomInset = insets.bottom
            }
            runCatching { manager.currentWindowMetrics.bounds }.getOrNull()?.let { bounds ->
                width = bounds.width()
                height = bounds.height()
            }
        }
        val safeLeft = leftInset.coerceIn(0, (width - 1).coerceAtLeast(0))
        val safeTop = topInset.coerceIn(0, (height - 1).coerceAtLeast(0))
        val safeRight = (width - rightInset).coerceAtLeast(safeLeft + 1)
        val safeBottom = (height - bottomInset).coerceAtLeast(safeTop + 1)
        return KeyguardUsableBounds(safeLeft, safeTop, safeRight, safeBottom)
    }

    private fun parameters(geometry: KeyguardOverlayGeometry): WindowManager.LayoutParams =
        keyguardCardWindowParameters(geometry)

    private fun updateLayout(root: View, geometry: KeyguardOverlayGeometry): Boolean {
        val directHost = r18HostGeneration
        val updated = runCatching {
            if (directHost != null) check(r18Host?.updateGeometry(directHost, geometry) == true)
            else manager.updateViewLayout(root, parameters(geometry))
        }
        if (updated.isFailure) {
            val stillAttached = root.isAttachedToWindow
            lifecycle.onUpdateFailed(stillAttached)
            if (!stillAttached) {
                appliedPresentation = null
                appliedGeometry = null
                accessibilityWindowId = null
            }
            return false
        }
        appliedGeometry = geometry
        return true
    }

    private fun beginDrag() {
        val start = appliedGeometry ?: return
        dragStart = start
        dragPreview = start
        dragLayoutRevision = materialSettings.layoutRevision
        dragMoveCount = 0
        dragLayoutUpdateCount = 0
        onInteractionDiagnostic("KG|DRAG_BEGIN", "${materialSettings.presentationMode.wireValue}|attach=$attachGeneration")
    }

    private fun scheduleDragFrame() {
        if (!dragFrameScheduled) {
            dragFrameScheduled = true
            Choreographer.getInstance().postFrameCallback(dragFrameCallback)
        }
    }

    private fun applyDragPreview(geometry: KeyguardOverlayGeometry) {
        val current = root ?: return
        if (lifecycle.isAttached() && updateLayout(current, geometry)) dragLayoutUpdateCount += 1
    }

    private fun commitDrag() {
        val start = dragStart ?: return
        clearDragFrame(flush = true)
        val end = dragPreview ?: start
        dragStart = null
        dragPreview = null
        if (end != start) {
            appliedGeometry = end
            onPositionCommitted(materialSettings.presentationMode, end.cardPosition, end.orbPosition, dragLayoutRevision)
            onInteractionDiagnostic(
                "KG|POSITION_COMMIT",
                "${materialSettings.presentationMode.wireValue}|moves=$dragMoveCount|updates=$dragLayoutUpdateCount",
            )
        }
        onInteractionDiagnostic("KG|DRAG_END", "moves=$dragMoveCount|updates=$dragLayoutUpdateCount")
    }

    private fun cancelDrag(reason: String, restorePosition: Boolean = true) {
        val start = dragStart
        clearDragFrame()
        dragStart = null
        dragPreview = null
        if (restorePosition && start != null && lifecycle.isAttached()) root?.let { updateLayout(it, start) }
        onInteractionDiagnostic("KG|DRAG_CANCEL", reason)
    }

    private fun observeFirstRootDraw(current: View, capturedAttach: Long) {
        firstRootDrawObservation?.cancel()
        lateinit var observation: KeyguardFirstDrawObservation
        observation = KeyguardFirstDrawObservation(
            root = current,
            attachGeneration = capturedAttach,
            onPreDraw = if (KeyguardCardDiagnostics.wantsEvent("FIRST_ROOT_PREDRAW")) { event ->
                if (firstRootDrawObservation === observation && lifecycle.isAttached() &&
                    root === current && attachGeneration == event.attachGeneration) onFirstRootPreDraw(event)
            } else null,
            targetSize = {
                val target = current.findViewById<View>(R.id.fluvi_financial_snapshot_orb)
                surfacePresenter?.targetSize() ?: ((target?.width ?: 0) to (target?.height ?: 0))
            },
            onFirstDraw = rootDraw@{ event ->
                if (firstRootDrawObservation !== observation) return@rootDraw
                // Clear our own reference before publishing. A late callback
                // from a detached/replaced root cannot retain or affect a new
                // attach.
                firstRootDrawObservation = null
                if (!lifecycle.isAttached() || root !== current || attachGeneration != event.attachGeneration) return@rootDraw
                onFirstRootDraw(event)
                // Static/no-animation presentations have no later live
                // shader draw. Animated bootstrap waits until that live draw
                // so preference I/O cannot delay frame commitment/promotion.
                if (surfacePresenter == null && materialController?.requiresBootstrapForNextAttach() != true) {
                    migrateCardPositionAfterFirstRootDraw(current, event.attachGeneration)
                }
            },
        )
        firstRootDrawObservation = observation
        observation.start()
    }

    private fun migrateCardPositionAfterFirstRootDraw(current: View, capturedAttach: Long) {
        val pending = pendingCardPositionMigration
            ?.takeIf { (generation, _) -> generation == capturedAttach }
            ?: return
        pendingCardPositionMigration = null
        mainHandler.post {
            if (lifecycle.isAttached() && root === current && attachGeneration == capturedAttach) {
                FluviKeyguardCardSettings.migrateCardPosition(serviceContext, pending.second)
            }
        }
    }

    /** Registration occurs from root pre-draw before bootstrap Canvas work.
     * The eventual callback is one-shot and may arrive after a detach, so its
     * owner check mirrors the first-draw observation rather than treating a
     * renderer callback as visibility authority. */
    private fun ensureFrameCommitObservation(
        current: View,
        capturedAttach: Long,
        bootstrapToken: KeyguardBootstrapFrameToken,
    ): KeyguardFrameCommitObservation {
        firstFrameCommitObservation?.let { existing ->
            if (existing.matches(current, capturedAttach, bootstrapToken)) return existing
            existing.cancel()
            firstFrameCommitObservation = null
        }
        acceptedBootstrapToken = null
        lateinit var observation: KeyguardFrameCommitObservation
        observation = KeyguardFrameCommitObservation(
            root = current,
            attachGeneration = capturedAttach,
            bootstrapToken = bootstrapToken,
            onCommitted = frameCommit@{ event ->
                if (firstFrameCommitObservation !== observation) return@frameCommit
                val transition = transition@{
                    if (firstFrameCommitObservation !== observation ||
                        !lifecycle.isAttached() || root !== current ||
                        attachGeneration != event.attachGeneration ||
                        materialController?.currentBootstrapToken() != event.bootstrapToken
                    ) return@transition
                    // Run the functional controller transition as soon as the
                    // commit reaches the View owner. Capture work is posted
                    // only after this small, owned state change.
                    if (materialController?.onBootstrapFrameCommitted(event.bootstrapToken) != true) {
                        firstFrameCommitObservation = null
                        return@transition
                    }
                    firstFrameCommitObservation = null
                    acceptedBootstrapToken = event.bootstrapToken
                    mainHandler.post diagnostic@{
                        if (!lifecycle.isAttached() || root !== current ||
                            attachGeneration != event.attachGeneration ||
                            acceptedBootstrapToken != event.bootstrapToken
                        ) return@diagnostic
                        val diagnosticEvent = KeyguardFirstDrawEvent(
                            attachGeneration = event.attachGeneration,
                            observedAtUptimeMs = event.observedAtUptimeMs,
                        )
                        onBootstrapCommit(diagnosticEvent)
                        // This callback commits the bootstrap frame. It is
                        // not evidence that the later LIVE shader frame was
                        // committed, so keep it out of the generic/live
                        // FRAME_COMMIT milestone.
                    }
                }
                if (Looper.myLooper() == Looper.getMainLooper()) transition()
                else mainHandler.post(transition)
            },
        )
        firstFrameCommitObservation = observation
        return observation
    }

    private fun clearDragFrame(flush: Boolean = false) {
        if (dragFrameScheduled) {
            Choreographer.getInstance().removeFrameCallback(dragFrameCallback)
            dragFrameScheduled = false
        }
        if (flush) dragPreview?.let(::applyDragPreview)
    }

    private fun updateMaterialForPresentation(presentation: FluviFinancialCardPresentation) {
        val presenter = surfacePresenter
        val profile = materialProfile
        if (presenter != null && profile != null) {
            if (lifecycle.isAttached() && r18HostGeneration != null) return
            val attachment = if (lifecycle.isAttached()) attachGeneration else attachGeneration + 1L
            val size = surfaceSize()
            presenter.show(attachment, profile, presentation.full,
                live = effectiveRenderMode == KeyguardOrbRenderMode.SURFACE_LIVE,
                width = size, height = size, reporter = surfaceDiagnostic)
            return
        }
        materialController?.update(
            profile = materialProfile,
            animationMode = materialSettings.animationMode,
            presentationMode = materialSettings.presentationMode,
            isFull = presentation.full,
            staticOrb = presentation.orb,
        )
    }

    /** A semantic profile/privacy change can require a safe bootstrap while
     * the retained root remains attached. Register the matching commit before
     * its next traversal, exactly as on the first attachment. */
    private fun observeBootstrapBeforeNextDraw() {
        val current = root ?: return
        val capturedAttach = firstShaderDrawAttachGeneration ?: return
        if (!lifecycle.isAttached() || attachGeneration != capturedAttach) return
        val bootstrapToken = materialController
            ?.takeIf { it.requiresBootstrapForNextAttach() }
            ?.currentBootstrapToken()
            ?: return
        ensureFrameCommitObservation(current, capturedAttach, bootstrapToken).startBeforeNextDraw()
    }

    private fun checkMainThread() {
        check(android.os.Looper.myLooper() == android.os.Looper.getMainLooper()) {
            "KeyguardCardWindow must be called on the main thread"
        }
    }
}
