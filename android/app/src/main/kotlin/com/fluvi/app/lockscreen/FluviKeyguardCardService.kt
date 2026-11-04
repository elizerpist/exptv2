package com.fluvi.app.lockscreen

import android.accessibilityservice.AccessibilityService
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.display.DisplayManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.UserManager
import android.view.Display
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.view.accessibility.AccessibilityWindowInfo
import com.fluvi.app.MainActivity
import com.fluvi.app.runtime.FluviFinancialCardPresenter
import com.fluvi.app.runtime.FluviLockScreenCardCoordinator
import com.fluvi.app.widget.financial.FluviFinancialSnapshotWidgetCoordinator
import com.fluvi.app.lockscreen.material.FluviKeyguardMaterialStore
import com.fluvi.app.lockscreen.material.KeyguardMaterialProfile
import java.util.concurrent.atomic.AtomicLong
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * A single Fluvi-owned, opt-in accessibility overlay. It never reads node
 * text/content descriptions, captures screenshots, performs global actions,
 * or hosts third-party widgets. The service is attached only by Android after
 * the user enables this exact component in Accessibility settings.
 */
class FluviKeyguardCardService : AccessibilityService() {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val session = AtomicLong(0L)
    private val visibilityEpoch = AtomicLong(0L)
    private val surfaceDispatcher = Dispatchers.IO.limitedParallelism(1)
    private val scope = CoroutineScope(SupervisorJob() + surfaceDispatcher)
    private val queueLock = Any()
    private var evaluating = false
    private var reevaluationQueued = false
    private var contentJob: Job? = null
    private var coreObservation: Job? = null
    private var observedFocusGeneration: Long? = null
    private var activeFocusGeneration: Long? = null
    private var renderedFullContent: com.fluvi.app.runtime.FluviLockScreenCardContent? = null
    private var resolvingFocusGeneration: Long? = null
    private var resolveQueued = false
    private var receiverRegistered = false
    private var displayRegistered = false
    private var retryCount = 0
    private var wakeEpoch = 0L
    private var lastSettings: KeyguardCardSettings? = null
    private var showEvent = false
    private var appliedDecision = KeyguardCardVisibility.HIDDEN_DISCONNECTED
    private lateinit var overlay: KeyguardCardWindow

    private val powerManager by lazy { getSystemService(PowerManager::class.java) }
    private val keyguardManager by lazy { getSystemService(android.app.KeyguardManager::class.java) }
    private val userManager by lazy { getSystemService(UserManager::class.java) }
    private val displayManager by lazy { getSystemService(DisplayManager::class.java) }

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_SCREEN_OFF, Intent.ACTION_USER_PRESENT -> hideImmediately(intent.action ?: "screen")
                Intent.ACTION_SCREEN_ON -> {
                    retryCount = 0
                    wakeEpoch += 1L
                    KeyguardCardDiagnostics.beginLockAttempt(this@FluviKeyguardCardService, session.get(), wakeEpoch)
                    scheduleEvaluation("wake")
                }
            }
        }
    }

    private val displayListener = object : DisplayManager.DisplayListener {
        override fun onDisplayAdded(displayId: Int) = Unit
        override fun onDisplayRemoved(displayId: Int) = Unit
        override fun onDisplayChanged(displayId: Int) {
            if (displayId != Display.DEFAULT_DISPLAY) return
            if (!isDisplayOnAndInteractive()) hideImmediately("display") else scheduleEvaluation("display")
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        session.incrementAndGet()
        FluviKeyguardCardServiceRegistry.connected(this)
        overlay = KeyguardCardWindow(
            serviceContext = this,
            onOpen = ::openFocusedFluvi,
            onToggle = ::toggleView,
        )
        lastSettings = FluviKeyguardCardSettings.read(applicationContext)
        overlay.updateMaterial(FluviKeyguardMaterialStore.read(applicationContext), requireNotNull(lastSettings))
        registerRuntimeSignals()
        wakeEpoch += 1L
        KeyguardCardDiagnostics.beginLockAttempt(this, session.get(), wakeEpoch)
        KeyguardCardDiagnostics.record(this, "KG|SERVICE_CONNECTED", "connected", false)
        scheduleEvaluation("connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        // Copy only non-sensitive metadata while Android owns the event. In
        // particular, do not hand AccessibilityEvent itself to the worker.
        val meta = KeyguardAccessibilityEventMeta(
            eventType = event.eventType,
            windowId = event.windowId,
            displayId = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) event.displayId else Display.DEFAULT_DISPLAY,
            windowChanges = if (event.eventType == AccessibilityEvent.TYPE_WINDOWS_CHANGED) event.windowChanges else 0,
            packageName = event.packageName?.toString(),
        )
        if (!KeyguardCardEventGate.isSurfaceEvent(meta.eventType)) return
        val own = ::overlay.isInitialized && overlay.isOwnAccessibilityWindow(meta.windowId)
        when (KeyguardCardEventGate.decide(meta, own)) {
            KeyguardEventAction.IGNORE_OWN -> {
                KeyguardCardDiagnostics.record(this, "KG|OWN_WINDOW", "ownSignal", overlay.isAttached)
                // The package-less post-add race reaches INSPECT, not an
                // eager detach. A positively matched own event needs no work.
            }
            KeyguardEventAction.INSPECT -> scheduleEvaluation("window")
        }
    }

    override fun onInterrupt() {
        hideImmediately("interrupt")
    }

    override fun onUnbind(intent: Intent?): Boolean {
        cleanup("unbind")
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        cleanup("destroy")
        super.onDestroy()
    }

    /** Called by the unlocked Flutter Activity through the process-local
     * registry. This is only an invalidation signal; preferences remain the
     * durable source of truth. */
    internal fun onSettingsChangedFromApplication(settings: KeyguardCardSettings) {
        mainHandler.post {
            val previous = lastSettings
            lastSettings = settings
            if (!settings.requested) {
                hideImmediately("settings")
                disableSelf()
            } else if (!settings.showFinancialDetails) {
                // Privacy tightening must redact the existing root before an
                // asynchronous query can return. It is not a window detach.
                redactImmediately("settings")
                overlay.updateMaterial(FluviKeyguardMaterialStore.read(applicationContext), settings)
                scheduleEvaluation("settings")
            } else {
                // A position-only change is a WindowManager layout update,
                // not a financial invalidation or view-state reset.
                if (previous?.showFinancialDetails != settings.showFinancialDetails) showEvent = false
                overlay.updateMaterial(FluviKeyguardMaterialStore.read(applicationContext), settings)
                scheduleEvaluation("settings")
            }
        }
    }

    internal fun onFinancialFocusChangedFromApplication() {
        mainHandler.post {
            showEvent = false
            invalidateFullContent()
            // A focus change may make a visible amount misleading. Redact in
            // place when possible; do not bounce the overlay root.
            if (overlay.isAttached && appliedDecision == KeyguardCardVisibility.SHOW_FULL) {
                applyPresentation(FluviFinancialCardPresenter.loading(), "focusChanged")
            }
            scheduleEvaluation("focusChanged")
        }
    }

    /** Profile publication is a retained-view mutation only. It must not
     * cause an inspection, financial resolve, or WindowManager operation. */
    internal fun onMaterialProfileChangedFromApplication(profile: KeyguardMaterialProfile) {
        mainHandler.post {
            if (!::overlay.isInitialized) return@post
            overlay.updateMaterial(profile, FluviKeyguardCardSettings.read(applicationContext))
            KeyguardCardDiagnostics.record(this, "KG|MATERIAL_SCENE", "profile:${profile.publisherRevision}", overlay.isAttached)
        }
    }

    private fun registerRuntimeSignals() {
        if (!receiverRegistered) {
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_OFF)
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_USER_PRESENT)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(screenReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                @Suppress("UnspecifiedRegisterReceiverFlag")
                registerReceiver(screenReceiver, filter)
            }
            receiverRegistered = true
        }
        if (!displayRegistered) {
            displayManager.registerDisplayListener(displayListener, mainHandler)
            displayRegistered = true
        }
    }

    private fun scheduleEvaluation(trigger: String) {
        if (!FluviKeyguardCardServiceRegistry.connected) return
        synchronized(queueLock) {
            if (evaluating) {
                reevaluationQueued = true
                return
            }
            evaluating = true
        }
        scope.launch {
            var nextTrigger = trigger
            while (true) {
                // Capture the currently valid session/epoch for this pass.
                // A later wake, hide, or disconnect invalidates it before it
                // can mutate the main-thread window state.
                val expectedSession = session.get()
                val expectedEpoch = visibilityEpoch.get()
                val result = inspectSurface(expectedSession, expectedEpoch)
                withContext(Dispatchers.Main.immediate) {
                    applyInspection(result, expectedSession, expectedEpoch, nextTrigger)
                }
                synchronized(queueLock) {
                    if (!reevaluationQueued) {
                        evaluating = false
                        break
                    }
                    reevaluationQueued = false
                }
                nextTrigger = "coalesced"
            }
        }
    }

    private data class Inspection(
        val signals: KeyguardCardSignals,
        val decision: KeyguardCardVisibility,
        val surfaceReason: KeyguardSurfaceReason,
        val ownOverlayWindowId: Int? = null,
    )

    private data class SystemWindowsRead(
        val snapshots: List<KeyguardWindowSnapshot>,
        val rootUnavailable: Boolean,
        val walkTruncated: Boolean,
    )

    private data class VisibleIds(
        val ids: Set<String>,
        val truncated: Boolean,
    )

    private fun inspectSurface(expectedSession: Long, expectedEpoch: Long): Inspection {
        val settings = FluviKeyguardCardSettings.read(applicationContext)
        val baseline = quickSignals(settings, KeyguardSurface.UNKNOWN)
        if (!baseline.requested || !baseline.serviceConnected || !baseline.userUnlocked ||
            !baseline.primaryDisplay || !baseline.interactive || !baseline.displayOn || !baseline.keyguardLocked
        ) {
            return Inspection(baseline, KeyguardCardVisibilityPolicy.decide(baseline), KeyguardSurfaceReason.NO_WINDOWS)
        }
        if (session.get() != expectedSession || visibilityEpoch.get() != expectedEpoch) {
            return Inspection(baseline, KeyguardCardVisibility.HIDDEN_UNKNOWN, KeyguardSurfaceReason.NO_WINDOWS)
        }
        val read = readSystemWindows()
        val classification = KeyguardSurfaceClassifier.classifyDetailed(
            read.snapshots,
            unavailableRoot = read.rootUnavailable,
            walkTruncated = read.walkTruncated,
        )
        val signals = quickSignals(settings, classification.surface)
        return Inspection(
            signals,
            KeyguardCardVisibilityPolicy.decide(signals),
            classification.reason,
            read.snapshots.firstOrNull { it.ownOverlay }?.windowId?.takeIf { it >= 0 },
        )
    }

    private fun quickSignals(settings: KeyguardCardSettings, surface: KeyguardSurface): KeyguardCardSignals {
        val display = displayManager.getDisplay(Display.DEFAULT_DISPLAY)
        return KeyguardCardSignals(
            requested = settings.requested,
            serviceConnected = FluviKeyguardCardServiceRegistry.connected,
            userUnlocked = userManager.isUserUnlocked,
            primaryDisplay = display?.displayId == Display.DEFAULT_DISPLAY,
            interactive = powerManager.isInteractive,
            displayOn = display?.state == Display.STATE_ON,
            keyguardLocked = keyguardManager.isKeyguardLocked,
            surface = surface,
            showFinancialDetails = settings.showFinancialDetails,
        )
    }

    private fun readSystemWindows(): SystemWindowsRead = runCatching {
        val currentWindows = windows
        var unavailableRoot = false
        var walkTruncated = false
        val snapshots = currentWindows.map { window ->
            val root = runCatching { window.root }.getOrNull()
            if (root == null) unavailableRoot = true
            val rootPackage = root?.packageName?.toString()
            val own = rootPackage == this.packageName && window.type == AccessibilityWindowInfo.TYPE_ACCESSIBILITY_OVERLAY
            val displayId = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) window.displayId else Display.DEFAULT_DISPLAY
            val ids = if (rootPackage in setOf("com.android.systemui", "com.android.keyguard", "android")) {
                root?.let(::visibleResourceIds)?.also { walkTruncated = walkTruncated || it.truncated }?.ids.orEmpty()
            } else {
                emptySet()
            }
            root?.recycle()
            KeyguardWindowSnapshot(
                windowId = window.id,
                packageName = rootPackage,
                type = window.type,
                layer = window.layer,
                displayId = displayId,
                ownOverlay = own,
                visibleViewIds = ids,
            )
        }
        SystemWindowsRead(snapshots, unavailableRoot, walkTruncated)
    }.getOrDefault(SystemWindowsRead(emptyList(), rootUnavailable = false, walkTruncated = false))

    /** Bounded, ID-only traversal. Never read node.text, event.text,
     * contentDescription, input values, screenshots, or foreign app trees. */
    private fun visibleResourceIds(root: AccessibilityNodeInfo): VisibleIds {
        val ids = linkedSetOf<String>()
        var visited = 0
        var truncated = false
        fun visit(node: AccessibilityNodeInfo?) {
            if (node == null) return
            if (visited >= 96) {
                truncated = true
                return
            }
            visited += 1
            try {
                if (!node.isVisibleToUser) return
                node.viewIdResourceName?.let(ids::add)
                node.className?.toString()?.takeIf { it.contains("BouncerContent") }?.let { ids.add("element:BouncerContent") }
                for (index in 0 until node.childCount) {
                    val child = node.getChild(index)
                    visit(child)
                    child?.recycle()
                }
            } catch (_: Exception) {
                // A stale node produces UNKNOWN rather than an unsafe show.
            }
        }
        visit(root)
        return VisibleIds(ids, truncated)
    }

    private fun applyInspection(
        inspection: Inspection,
        expectedSession: Long,
        expectedEpoch: Long,
        trigger: String,
    ) {
        inspection.ownOverlayWindowId?.let(overlay::recordAccessibilityWindowId)
        // A stale Binder walk has no authority over a newer session/epoch.
        // In particular, it must not remove an overlay attached by a later
        // wake inspection.
        when (KeyguardCardInspectionGate.decide(
            expectedSession = expectedSession,
            currentSession = session.get(),
            expectedEpoch = expectedEpoch,
            currentEpoch = visibilityEpoch.get(),
            displayEligibleNow = isDisplayOnAndInteractive(),
            keyguardLockedNow = keyguardManager.isKeyguardLocked,
        )) {
            KeyguardInspectionAction.DROP_STALE -> {
                KeyguardCardDiagnostics.record(this, "KG|DROP_STALE", "surfaceEpoch", overlay.isAttached)
                return
            }
            KeyguardInspectionAction.HIDE_CURRENT_GATE -> {
                hideImmediately("currentGate")
                return
            }
            KeyguardInspectionAction.APPLY -> Unit
        }
        val decision = inspection.decision
        KeyguardCardDiagnostics.record(this, "KG|SURFACE_DECISION", "${decision.name}:${inspection.surfaceReason.name}", overlay.isAttached)
        appliedDecision = decision
        when (decision) {
            KeyguardCardVisibility.SHOW_DISCREET -> {
                retryCount = 0
                stopFinancialObservation()
                showEvent = false
                applyPresentation(FluviFinancialCardPresenter.discreet(), "discreet:$trigger")
            }
            KeyguardCardVisibility.SHOW_FULL -> {
                retryCount = 0
                val focus = FluviFinancialSnapshotWidgetCoordinator.configuration(applicationContext)
                showFullContent(expectedSession, expectedEpoch, focus.generation, trigger)
            }
            else -> {
                hideImmediately(decision.name)
                if (decision == KeyguardCardVisibility.HIDDEN_UNKNOWN && retryCount < 2 &&
                    isDisplayOnAndInteractive() && keyguardManager.isKeyguardLocked
                ) {
                    retryCount += 1
                    mainHandler.postDelayed({ scheduleEvaluation("surfaceRetry") }, 180L)
                }
            }
        }
    }

    private fun showFullContent(
        expectedSession: Long,
        expectedEpoch: Long,
        focusGeneration: Long,
        trigger: String,
    ) {
        val focusChanged = activeFocusGeneration != focusGeneration
        if (focusChanged) {
            showEvent = false
            invalidateFullContent()
            activeFocusGeneration = focusGeneration
        }
        val cached = renderedFullContent
        val plan = KeyguardCardContentRefreshPolicy.firstOrSurfacePlan(
            focusChanged = focusChanged,
            hasCurrentContent = cached != null && !focusChanged,
            resolveInFlightForFocus = resolvingFocusGeneration == focusGeneration,
        )
        if (cached != null && !focusChanged) {
            applyPresentation(FluviFinancialCardPresenter.full(cached, showEvent), "cached:$trigger")
        } else if (plan.publishLoading) {
            // First full render only. Repeated same-surface inspection keeps
            // the current amount or existing loading presentation untouched.
            applyPresentation(FluviFinancialCardPresenter.loading(), "loading:$trigger")
        }
        beginFinancialObservation(expectedSession, expectedEpoch, focusGeneration)
        if (plan.startResolve) {
            resolveFullContent(expectedSession, expectedEpoch, focusGeneration, "first")
        }
    }

    private fun beginFinancialObservation(expectedSession: Long, expectedEpoch: Long, focusGeneration: Long) {
        if (coreObservation?.isActive == true && observedFocusGeneration == focusGeneration) return
        stopFinancialObservation(keepRenderedContent = true)
        observedFocusGeneration = focusGeneration
        coreObservation = scope.launch {
            val core = com.fluvi.core.FluviCoreFactory.create(applicationContext)
            try {
                var firstEmission = true
                core.query.observeCoreRevision().collectLatest {
                    if (firstEmission) {
                        firstEmission = false
                        return@collectLatest
                    }
                    withContext(Dispatchers.Main.immediate) {
                        resolveFullContent(expectedSession, expectedEpoch, focusGeneration, "coreRevision")
                    }
                }
            } finally {
                core.close()
            }
        }
    }

    private fun resolveFullContent(
        expectedSession: Long,
        expectedEpoch: Long,
        focusGeneration: Long,
        reason: String,
    ) {
        check(android.os.Looper.myLooper() == android.os.Looper.getMainLooper())
        if (contentJob?.isActive == true) {
            if (resolvingFocusGeneration == focusGeneration) {
                // A core observer's initial emission commonly follows the
                // explicit first resolve. Coalesce it instead of cancelling
                // the in-flight query and flashing loading again.
                resolveQueued = true
                return
            }
            contentJob?.cancel()
        }
        resolvingFocusGeneration = focusGeneration
        resolveQueued = false
        KeyguardCardDiagnostics.record(this, "KG|RESOLVE_STARTED", reason, overlay.isAttached)
        contentJob = scope.launch {
            val focus = FluviFinancialSnapshotWidgetCoordinator.configuration(applicationContext)
            val content = if (focus.generation == focusGeneration) {
                runCatching {
                    FluviLockScreenCardCoordinator.resolve(applicationContext, focus.asFinancialFocus())
                }.getOrNull()
            } else {
                null
            }
            withContext(Dispatchers.Main.immediate) {
                try {
                    val settings = FluviKeyguardCardSettings.read(applicationContext)
                    val stillCurrent = KeyguardCardContentPublicationPolicy.canApply(
                        KeyguardCardContentPublication(
                            requestSession = expectedSession,
                            currentSession = session.get(),
                            requestEpoch = expectedEpoch,
                            currentEpoch = visibilityEpoch.get(),
                            requestFocusGeneration = focusGeneration,
                            currentFocusGeneration = FluviFinancialSnapshotWidgetCoordinator.configuration(applicationContext).generation,
                            currentlyFull = appliedDecision == KeyguardCardVisibility.SHOW_FULL,
                            detailsStillAllowed = settings.showFinancialDetails,
                            displayStillEligible = isDisplayOnAndInteractive() && keyguardManager.isKeyguardLocked,
                        ),
                    )
                    if (!stillCurrent || content == null) {
                        KeyguardCardDiagnostics.record(
                            this@FluviKeyguardCardService,
                            "KG|CONTENT_STALE",
                            if (content == null) "resolveUnavailable" else "contentEpoch",
                            overlay.isAttached,
                        )
                    } else {
                        renderedFullContent = content
                        activeFocusGeneration = focusGeneration
                        applyPresentation(FluviFinancialCardPresenter.full(content, showEvent), "content")
                        KeyguardCardDiagnostics.record(this@FluviKeyguardCardService, "KG|CONTENT_APPLIED", "full", overlay.isAttached)
                    }
                } finally {
                    val rerun = resolveQueued && activeFocusGeneration == focusGeneration
                    resolveQueued = false
                    resolvingFocusGeneration = null
                    contentJob = null
                    if (rerun) resolveFullContent(expectedSession, expectedEpoch, focusGeneration, "coalescedRevision")
                }
            }
        }
    }

    private fun applyPresentation(presentation: com.fluvi.app.runtime.FluviFinancialCardPresentation, reason: String) {
        val settings = FluviKeyguardCardSettings.read(applicationContext)
        // This only changes retained drawing input; no animation frame is
        // allowed to enter showOrUpdate or the financial presentation lane.
        overlay.updateMaterial(FluviKeyguardMaterialStore.read(applicationContext), settings)
        when (val result = overlay.showOrUpdate(presentation, settings.verticalOffsetDp)) {
            KeyguardCardWindow.Result.ATTACHED -> {
                KeyguardCardDiagnostics.attach(this, "attached")
                KeyguardCardDiagnostics.record(this, "KG|ATTACH", reason, true)
            }
            KeyguardCardWindow.Result.CONTENT_UPDATED,
            KeyguardCardWindow.Result.REDACTED -> KeyguardCardDiagnostics.record(this, "KG|CONTENT_UPDATE", "$reason:${result.name}", true)
            KeyguardCardWindow.Result.LAYOUT_UPDATED -> KeyguardCardDiagnostics.record(this, "KG|LAYOUT_UPDATE", reason, true)
            KeyguardCardWindow.Result.NO_OP -> Unit
            KeyguardCardWindow.Result.FAILED -> {
                KeyguardCardDiagnostics.attach(this, "failed")
                KeyguardCardDiagnostics.record(this, "KG|ATTACH_FAILED", "window", false)
            }
        }
    }

    private fun toggleView() {
        if (appliedDecision != KeyguardCardVisibility.SHOW_FULL) return
        val content = renderedFullContent ?: return
        showEvent = !showEvent
        applyPresentation(FluviFinancialCardPresenter.full(content, showEvent), "toggle")
    }

    private fun openFocusedFluvi() {
        if (appliedDecision != KeyguardCardVisibility.SHOW_FULL &&
            appliedDecision != KeyguardCardVisibility.SHOW_DISCREET
        ) return
        val focus = FluviFinancialSnapshotWidgetCoordinator.configuration(applicationContext)
        hideImmediately("open")
        startActivity(
            Intent(this, MainActivity::class.java).apply {
                action = ACTION_OPEN_FOCUS
                putExtra(EXTRA_MODE, focus.mode.name)
                putExtra(EXTRA_AXIS, focus.timeAxis.name)
                putExtra(EXTRA_DIRECTION, focus.direction.name)
                putExtra(EXTRA_CATEGORY, focus.categoryId)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            },
        )
    }

    private fun hideImmediately(reason: String) {
        visibilityEpoch.incrementAndGet()
        appliedDecision = KeyguardCardVisibility.HIDDEN_UNKNOWN
        showEvent = false
        stopFinancialObservation()
        if (::overlay.isInitialized) {
            val wasAttached = overlay.isAttached
            val removed = overlay.hide()
            if (wasAttached && removed) KeyguardCardDiagnostics.record(this, "KG|DETACH", reason, false)
        }
    }

    internal fun materialDiagnostics(): Map<String, Any?> {
        val values = if (::overlay.isInitialized) overlay.materialDiagnostics() else null
        return mapOf(
            "rendererBackend" to values?.rendererBackend,
            "hardwareAccelerated" to (values?.hardwareAccelerated ?: false),
            "shaderCreationCount" to (values?.shaderCreationCount ?: 0),
            "animationStartCount" to (values?.animationStartCount ?: 0),
            "animationStopCount" to (values?.animationStopCount ?: 0),
            "drawCount" to (values?.drawCount ?: 0),
            "frameIntervalP50" to (values?.frameIntervalP50 ?: 0),
            "frameIntervalP95" to (values?.frameIntervalP95 ?: 0),
            "largeFrameGapCount" to (values?.largeFrameGapCount ?: 0),
            "lastRendererFailure" to values?.rendererFailure,
        )
    }

    private fun redactImmediately(reason: String) {
        visibilityEpoch.incrementAndGet()
        showEvent = false
        stopFinancialObservation()
        appliedDecision = KeyguardCardVisibility.SHOW_DISCREET
        if (::overlay.isInitialized && overlay.isAttached && isDisplayOnAndInteractive() && keyguardManager.isKeyguardLocked) {
            applyPresentation(FluviFinancialCardPresenter.discreet(), "redact:$reason")
        }
    }

    private fun invalidateFullContent() {
        renderedFullContent = null
        activeFocusGeneration = null
        resolveQueued = false
        resolvingFocusGeneration = null
        contentJob?.cancel()
        contentJob = null
    }

    private fun stopFinancialObservation(keepRenderedContent: Boolean = false) {
        contentJob?.cancel()
        contentJob = null
        coreObservation?.cancel()
        coreObservation = null
        observedFocusGeneration = null
        resolvingFocusGeneration = null
        resolveQueued = false
        if (!keepRenderedContent) {
            renderedFullContent = null
            activeFocusGeneration = null
        }
    }

    private fun isDisplayOnAndInteractive(): Boolean {
        val display = displayManager.getDisplay(Display.DEFAULT_DISPLAY)
        return powerManager.isInteractive && display?.state == Display.STATE_ON
    }

    private fun cleanup(reason: String) {
        hideImmediately(reason)
        if (receiverRegistered) {
            runCatching { unregisterReceiver(screenReceiver) }
            receiverRegistered = false
        }
        if (displayRegistered) {
            displayManager.unregisterDisplayListener(displayListener)
            displayRegistered = false
        }
        if (::overlay.isInitialized) overlay.dispose()
        FluviKeyguardCardServiceRegistry.disconnected(this)
        KeyguardCardDiagnostics.record(this, "KG|SERVICE_DISCONNECTED", reason, false)
        scope.cancel()
    }

    companion object {
        const val ACTION_OPEN_FOCUS = "com.fluvi.app.lockscreen.OPEN_FOCUS"
        const val EXTRA_MODE = "com.fluvi.app.lockscreen.MODE"
        const val EXTRA_AXIS = "com.fluvi.app.lockscreen.AXIS"
        const val EXTRA_DIRECTION = "com.fluvi.app.lockscreen.DIRECTION"
        const val EXTRA_CATEGORY = "com.fluvi.app.lockscreen.CATEGORY"
    }
}
