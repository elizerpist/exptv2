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
    private var receiverRegistered = false
    private var displayRegistered = false
    private var retryCount = 0
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
        registerRuntimeSignals()
        KeyguardCardDiagnostics.record(this, "KG|SERVICE_CONNECTED", "connected", false)
        scheduleEvaluation("connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        // Only copy non-sensitive metadata while Android owns the event. The
        // actual tree walk is serialised and never uses event text.
        if (event.packageName?.toString() == packageName) return
        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,
            AccessibilityEvent.TYPE_WINDOWS_CHANGED -> hideImmediately("surfaceChanging")
        }
        scheduleEvaluation("window")
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
            if (!settings.requested) {
                hideImmediately("settings")
                disableSelf()
            } else if (!settings.showFinancialDetails) {
                // Privacy tightening first removes all full View fields, then
                // repaints the safe discrete card from no financial data.
                hideImmediately("settings")
                scheduleEvaluation("settings")
            } else {
                // Do not leave the old event sub-view around after a focus or
                // privacy change.
                showEvent = false
                scheduleEvaluation("settings")
            }
        }
    }

    internal fun onFinancialFocusChangedFromApplication() {
        mainHandler.post {
            showEvent = false
            hideImmediately("focusChanged")
            scheduleEvaluation("focusChanged")
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
                // Each coalesced pass owns a fresh epoch. A previous wake's
                // late Binder result can therefore never suppress the next
                // wake's valid evidence.
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
    )

    private fun inspectSurface(expectedSession: Long, expectedEpoch: Long): Inspection {
        val settings = FluviKeyguardCardSettings.read(applicationContext)
        val baseline = quickSignals(settings, KeyguardSurface.UNKNOWN)
        if (!baseline.requested || !baseline.serviceConnected || !baseline.userUnlocked ||
            !baseline.primaryDisplay || !baseline.interactive || !baseline.displayOn || !baseline.keyguardLocked
        ) {
            return Inspection(baseline, KeyguardCardVisibilityPolicy.decide(baseline))
        }
        if (session.get() != expectedSession || visibilityEpoch.get() != expectedEpoch) {
            return Inspection(baseline, KeyguardCardVisibility.HIDDEN_UNKNOWN)
        }
        val snapshots = readSystemWindows()
        val surface = KeyguardSurfaceClassifier.classify(snapshots)
        val signals = quickSignals(settings, surface)
        return Inspection(signals, KeyguardCardVisibilityPolicy.decide(signals))
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

    private fun readSystemWindows(): List<KeyguardWindowSnapshot> = runCatching {
        windows.mapNotNull { window ->
            val root = runCatching { window.root }.getOrNull()
            val rootPackage = root?.packageName?.toString()
            val own = rootPackage == this.packageName && window.type == AccessibilityWindowInfo.TYPE_ACCESSIBILITY_OVERLAY
            val displayId = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) window.displayId else Display.DEFAULT_DISPLAY
            val ids = if (rootPackage in setOf("com.android.systemui", "com.android.keyguard", "android")) {
                root?.let(::visibleResourceIds).orEmpty()
            } else {
                emptySet()
            }
            root?.recycle()
            KeyguardWindowSnapshot(
                packageName = rootPackage,
                type = window.type,
                layer = window.layer,
                displayId = displayId,
                ownOverlay = own,
                visibleViewIds = ids,
            )
        }
    }.getOrDefault(emptyList())

    /** Bounded, ID-only traversal. Never read node.text, event.text,
     * contentDescription, input values, screenshots, or foreign app trees. */
    private fun visibleResourceIds(root: AccessibilityNodeInfo): Set<String> {
        val ids = linkedSetOf<String>()
        var visited = 0
        fun visit(node: AccessibilityNodeInfo?) {
            if (node == null || visited >= 96) return
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
        return ids
    }

    private fun applyInspection(
        inspection: Inspection,
        expectedSession: Long,
        expectedEpoch: Long,
        trigger: String,
    ) {
        if (session.get() != expectedSession || visibilityEpoch.get() != expectedEpoch ||
            !isDisplayOnAndInteractive() || !keyguardManager.isKeyguardLocked
        ) {
            hideImmediately("staleGate")
            return
        }
        val decision = inspection.decision
        KeyguardCardDiagnostics.record(this, "KG|SURFACE_DECISION", decision.name, overlay.isAttached)
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
                applyPresentation(FluviFinancialCardPresenter.loading(), "loading:$trigger")
                beginFinancialObservation(expectedSession, expectedEpoch, focus.generation)
                resolveFullContent(expectedSession, expectedEpoch, focus.generation)
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

    private fun beginFinancialObservation(expectedSession: Long, expectedEpoch: Long, focusGeneration: Long) {
        if (coreObservation?.isActive == true) return
        coreObservation = scope.launch {
            val core = com.fluvi.core.FluviCoreFactory.create(applicationContext)
            try {
                core.query.observeCoreRevision().collectLatest {
                    resolveFullContent(expectedSession, expectedEpoch, focusGeneration)
                }
            } finally {
                core.close()
            }
        }
    }

    private fun resolveFullContent(expectedSession: Long, expectedEpoch: Long, focusGeneration: Long) {
        contentJob?.cancel()
        contentJob = scope.launch {
            val focus = FluviFinancialSnapshotWidgetCoordinator.configuration(applicationContext)
            if (focus.generation != focusGeneration) return@launch
            val content = runCatching {
                FluviLockScreenCardCoordinator.resolve(applicationContext, focus.asFinancialFocus())
            }.getOrNull() ?: return@launch
            withContext(Dispatchers.Main.immediate) {
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
                if (!stillCurrent) {
                    KeyguardCardDiagnostics.record(this@FluviKeyguardCardService, "KG|CONTENT_STALE", "contentEpoch", overlay.isAttached)
                    return@withContext
                }
                applyPresentation(FluviFinancialCardPresenter.full(content, showEvent), "content")
                KeyguardCardDiagnostics.record(this@FluviKeyguardCardService, "KG|CONTENT_APPLIED", "full", overlay.isAttached)
            }
        }
    }

    private fun applyPresentation(presentation: com.fluvi.app.runtime.FluviFinancialCardPresentation, reason: String) {
        val settings = FluviKeyguardCardSettings.read(applicationContext)
        val success = overlay.showOrUpdate(presentation, settings.verticalOffsetDp)
        if (success) {
            KeyguardCardDiagnostics.attach(this, "attached")
            KeyguardCardDiagnostics.record(this, "KG|ATTACH", reason, true)
        } else {
            KeyguardCardDiagnostics.attach(this, "failed")
            KeyguardCardDiagnostics.record(this, "KG|ATTACH_FAILED", "window", false)
        }
    }

    private fun toggleView() {
        if (appliedDecision != KeyguardCardVisibility.SHOW_FULL) return
        showEvent = !showEvent
        val expected = session.get()
        val epoch = visibilityEpoch.get()
        val focusGeneration = FluviFinancialSnapshotWidgetCoordinator.configuration(applicationContext).generation
        resolveFullContent(expected, epoch, focusGeneration)
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
            overlay.hide()
            if (wasAttached) KeyguardCardDiagnostics.record(this, "KG|DETACH", reason, false)
        }
    }

    private fun stopFinancialObservation() {
        contentJob?.cancel()
        contentJob = null
        coreObservation?.cancel()
        coreObservation = null
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
