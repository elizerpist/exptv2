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
import com.fluvi.app.runtime.FluviFinancialCardPresentation

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
    private val onWindowDiagnostic: (String, String, Long?, Long) -> Unit = { _, _, _, _ -> },
    private val onFirstRootDraw: (KeyguardFirstDrawEvent) -> Unit = {},
    private val onFirstShaderDraw: (KeyguardFirstDrawEvent) -> Unit = {},
    private val onBootstrapDraw: (KeyguardFirstDrawEvent) -> Unit = {},
    private val onBootstrapCommit: (KeyguardFirstDrawEvent) -> Unit = {},
    private val onLivePromotion: (KeyguardFirstDrawEvent) -> Unit = {},
    private val onFrameCommit: (KeyguardFirstDrawEvent) -> Unit = {},
    private val manager: WindowManager = serviceContext.getSystemService(WindowManager::class.java),
) {
    enum class Result { ATTACHED, CONTENT_UPDATED, LAYOUT_UPDATED, REDACTED, NO_OP, FAILED }

    private var root: KeyguardCardInteractionLayout? = null
    private val lifecycle = KeyguardCardWindowLifecycle()
    private var appliedPresentation: FluviFinancialCardPresentation? = null
    private var appliedGeometry: KeyguardOverlayGeometry? = null
    private var accessibilityWindowId: Int? = null
    private var attachGeneration = 0L
    private val mainHandler = Handler(Looper.getMainLooper())
    private var firstRootDrawObservation: KeyguardFirstDrawObservation? = null
    private var firstFrameCommitObservation: KeyguardFrameCommitObservation? = null
    /** The most recently accepted functional commit. Diagnostic publication is
     * posted after that transition and must not describe a superseded scene. */
    private var acceptedBootstrapToken: KeyguardBootstrapFrameToken? = null
    private var firstShaderDrawAttachGeneration: Long? = null
    private var materialController: KeyguardCardMaterialController? = null
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

    internal fun presentationConfigurationApplicationsForTest(): Int = presentationConfigurationApplyCount

    /** Timestamp at the operation boundary; delivery is deliberately allowed
     * to be deferred by the service so capture bookkeeping never precedes a
     * visibility-critical WindowManager call. */
    private fun reportWindowDiagnostic(
        stage: String,
        detail: String,
        generation: Long?,
        observedAtUptimeMs: Long = SystemClock.uptimeMillis(),
    ) = onWindowDiagnostic(stage, detail, generation, observedAtUptimeMs)

    fun isOwnAccessibilityWindow(windowId: Int, displayId: Int): Boolean {
        checkMainThread()
        return lifecycle.isAttached() && displayId == android.view.Display.DEFAULT_DISPLAY && accessibilityWindowId == windowId
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
        // Begin immutable source/metadata loading while detached. A later
        // authorized attach may install the prepared program without first
        // opening assets from Canvas.onDraw.
        materialController?.prepare(
            profile,
            settings.animationMode,
            settings.presentationMode,
            isFull = settings.showFinancialDetails,
        )
        current.visibility = View.VISIBLE
    }

    fun showOrUpdate(presentation: FluviFinancialCardPresentation, settings: KeyguardCardSettings): Result {
        checkMainThread()
        val modeChanged = appliedPresentationConfiguration?.mode?.let { it != settings.presentationMode } == true
        materialSettings = settings
        val current = root ?: createRoot().also { root = it }
        if (modeChanged) {
            current.cancelInteraction("presentationChanged")
            onInteractionDiagnostic("KG|PRESENTATION_CHANGED", settings.presentationMode.wireValue)
        }
        val presentationConfigurationChanged = configurePresentation(current, settings.presentationMode)
        val resolvedGeometry = dragPreview ?: geometry(settings, current)

        if (!lifecycle.isAttached()) {
            // A terminal hide makes the retained root locally invisible before
            // removal. Restore it only after the fresh surface decision has
            // reached this checked attach path.
            current.visibility = View.VISIBLE
            apply(current, presentation, force = true, mode = settings.presentationMode)
            // Configure the retained scene while detached. If the bounded
            // artifact lane is already ready, RuntimeShader construction is
            // complete before WindowManager.addView and cannot tax first draw.
            updateMaterialForPresentation(presentation)
            val nextAttach = attachGeneration + 1L
            // Arm before addView. On overlay hosts where attach finishes after
            // addView returns, the observation retains this request through
            // the attach callback and installs pre-draw on the real observer.
            val bootstrapToken = materialController?.currentBootstrapToken()
            if (bootstrapToken != null) {
                ensureFrameCommitObservation(current, nextAttach, bootstrapToken).startBeforeNextDraw()
            }
            reportWindowDiagnostic("ADD_VIEW_BEGIN", "windowManager", nextAttach)
            return runCatching {
                manager.addView(current, parameters(resolvedGeometry))
                // This boundary deliberately excludes lifecycle/material and
                // first-draw observer setup. The timing report must not label
                // those post-add operations as WindowManager.addView time.
                reportWindowDiagnostic("ADD_VIEW_RETURN", "success", nextAttach)
            }.fold(
                onSuccess = {
                    lifecycle.onAttachSucceeded()
                    attachGeneration += 1L
                    appliedPresentation = presentation
                    appliedGeometry = resolvedGeometry
                    firstShaderDrawAttachGeneration = attachGeneration
                    // The pre-attach arm above must remain intact. Re-arm
                    // only if material selection changed synchronously during
                    // addView; never wait for a later accessibility event.
                    observeBootstrapBeforeNextDraw()
                    materialController?.onAttached()
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
        if (current.visibility != View.VISIBLE) current.visibility = View.VISIBLE

        val contentChanged = appliedPresentation?.visualKey != presentation.visualKey
        val geometryChanged = appliedGeometry != resolvedGeometry
        if (lifecycle.renderOperation(contentChanged, geometryChanged) == KeyguardCardWindowLifecycle.Operation.NONE) {
            // A no-op surface confirmation must not strand a bootstrap whose
            // pre-attach observer raced the actual View attachment.
            observeBootstrapBeforeNextDraw()
            return if (presentationConfigurationChanged) Result.LAYOUT_UPDATED else Result.NO_OP
        }
        if (contentChanged) apply(current, presentation, force = false, mode = settings.presentationMode)
        if (geometryChanged && !updateLayout(current, resolvedGeometry)) return Result.FAILED
        val wasFull = appliedPresentation?.full == true
        appliedPresentation = presentation
        updateMaterialForPresentation(presentation)
        observeBootstrapBeforeNextDraw()
        return when {
            contentChanged && wasFull && !presentation.full -> Result.REDACTED
            contentChanged -> Result.CONTENT_UPDATED
            else -> Result.LAYOUT_UPDATED
        }
    }

    /** Called by the narrow layout patch path. It performs a retained-root
     * layout update only; no inspection and no financial resolver are touched. */
    fun updateLayoutSettings(settings: KeyguardCardSettings) {
        checkMainThread()
        val current = root ?: return
        val modeChanged = appliedPresentationConfiguration?.mode?.let { it != settings.presentationMode } == true
        materialSettings = settings
        if (modeChanged) {
            current.cancelInteraction("presentationChanged")
            onInteractionDiagnostic("KG|PRESENTATION_CHANGED", settings.presentationMode.wireValue)
        }
        configurePresentation(current, settings.presentationMode)
        val presentation = appliedPresentation ?: return
        val next = geometry(settings, current)
        if (lifecycle.isAttached() && dragPreview == null && appliedGeometry != next) updateLayout(current, next)
        if (modeChanged) updateMaterialForPresentation(presentation)
    }

    /** Terminal hide: stop local visibility first and never restore a drag
     * preview before removeViewImmediate. Normal CANCEL still restores. */
    fun hide(): Boolean {
        checkMainThread()
        val current = root ?: return false
        if (lifecycle.isAttached()) {
            current.visibility = View.INVISIBLE
            reportWindowDiagnostic("LOCAL_HIDE_APPLIED", "invisible", attachGeneration)
        }
        firstRootDrawObservation?.cancel()
        firstRootDrawObservation = null
        firstFrameCommitObservation?.cancel()
        firstFrameCommitObservation = null
        acceptedBootstrapToken = null
        pendingCardPositionMigration = null
        firstShaderDrawAttachGeneration = null
        current.cancelInteraction("detach", restorePosition = false)
        clearDragFrame()
        materialController?.stop("hide")
        if (lifecycle.hideOperation() == KeyguardCardWindowLifecycle.Operation.NONE) return false
        reportWindowDiagnostic("REMOVE_VIEW_BEGIN", "windowManager", attachGeneration)
        val removed = runCatching { manager.removeViewImmediate(current) }
        val stillAttached = current.isAttachedToWindow
        if (removed.isSuccess || !stillAttached) {
            lifecycle.onDetached()
            appliedPresentation = null
            appliedGeometry = null
            accessibilityWindowId = null
        } else lifecycle.onUpdateFailed(stillAttached = true)
        if (removed.isSuccess) {
            reportWindowDiagnostic("REMOVE_VIEW_RETURN", "success", attachGeneration)
        } else {
            reportWindowDiagnostic("DETACH_FAILED", "${removed.exceptionOrNull()?.javaClass?.simpleName ?: "unknown"}", attachGeneration)
        }
        return removed.isSuccess
    }

    fun dispose() {
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
        root = null
        materialController = null
        appliedPresentationConfiguration = null
    }

    fun updateMaterial(profile: KeyguardMaterialProfile?, settings: KeyguardCardSettings) {
        checkMainThread()
        materialProfile = profile
        materialSettings = settings
        materialController?.prepare(
            profile,
            settings.animationMode,
            settings.presentationMode,
            isFull = settings.showFinancialDetails,
        )
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
        materialController = KeyguardCardMaterialController(
            orb = created.findViewById(R.id.fluvi_financial_snapshot_orb),
            background = created.findViewById(R.id.fluvi_keyguard_material_background),
            backgroundVeil = created.findViewById(R.id.fluvi_keyguard_material_veil),
        ).also { controller ->
            controller.onPreparationStage = { stage, fields ->
                reportWindowDiagnostic(stage, fields["programKey"]?.toString() ?: "material", null)
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
        return created
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
        if (force || previous?.visualKey != presentation.visualKey) {
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
        val updated = runCatching { manager.updateViewLayout(root, parameters(geometry)) }
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
                if (materialController?.requiresBootstrapForNextAttach() != true) {
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
        val bootstrapToken = materialController?.currentBootstrapToken() ?: return
        ensureFrameCommitObservation(current, capturedAttach, bootstrapToken).startBeforeNextDraw()
    }

    private fun checkMainThread() {
        check(android.os.Looper.myLooper() == android.os.Looper.getMainLooper()) {
            "KeyguardCardWindow must be called on the main thread"
        }
    }
}
