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
import android.os.SystemClock
import android.os.UserManager
import android.view.Display
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.view.accessibility.AccessibilityWindowInfo
import com.fluvi.app.MainActivity
import com.fluvi.app.runtime.FluviFinancialCardPresenter
import com.fluvi.app.runtime.FluviLockScreenCardContent
import com.fluvi.app.runtime.FluviLockScreenCardCoordinator
import com.fluvi.app.lockscreen.material.FluviKeyguardMaterialStore
import com.fluvi.app.lockscreen.material.KeyguardMaterialProfile
import java.util.concurrent.atomic.AtomicLong
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CancellationException
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
    /** Pointer interaction invalidates only inspections that began before the
     * touch. A new, genuine SystemUI event still starts a fresh inspection and
     * therefore retains full security authority while a finger is down. */
    private val interactionEpoch = AtomicLong(0L)
    /** Binder window traversal has its own one-wide lane. Financial Room work
     * cannot occupy it while a wake needs an eligibility decision. */
    private val serviceJob = SupervisorJob()
    private val surfaceDispatcher = Dispatchers.IO.limitedParallelism(1)
    private val financialDispatcher = Dispatchers.IO.limitedParallelism(1)
    private val inspectionScope = CoroutineScope(serviceJob + surfaceDispatcher)
    private val financialScope = CoroutineScope(serviceJob + financialDispatcher)
    private val queueLock = Any()
    private val inspectionQueue = KeyguardCardInspectionQueue()
    private val nextInspectionId = AtomicLong(0L)
    private var contentJob: Job? = null
    private var coreObservation: Job? = null
    private var observedFocusGeneration: Long? = null
    private var activeFocusGeneration: Long? = null
    private var renderedFullContent: FluviLockScreenCardContent? = null
    /** A deterministic invalid focus must not turn every SystemUI event into
     * another doomed database resolve. Cleared with a new focus or a
     * deliberate content invalidation. */
    private var terminalContentFailure: Pair<Long, String>? = null
    /** A transient query failure is retried only by a meaningful core
     * invalidation, focus change, or new visible session—not by a burst of
     * accessibility content events from the same lockscreen. */
    private var transientContentFailure: Pair<Long, String>? = null
    private var resolvingFocusGeneration: Long? = null
    private var resolveQueued = false
    private var receiverRegistered = false
    private var displayRegistered = false
    private var retryCount = 0
    private var retryRunnable: Runnable? = null
    @Volatile private var wakeEpoch = 0L
    @Volatile private var lastSettings: KeyguardCardSettings? = null
    @Volatile private var lastMaterialProfile: KeyguardMaterialProfile? = null
    private var showEvent = false
    private var appliedDecision = KeyguardCardVisibility.HIDDEN_DISCONNECTED
    private var overlayAttachGeneration = 0L
    private lateinit var overlay: KeyguardCardWindow

    private data class WakeTiming(
        val wakeGeneration: Long,
        val wakeReceivedAt: Long,
        val rootWasPrepared: Boolean,
        val profileWasDecoded: Boolean,
        val presentationMode: String,
        var inspectionQueuedAt: Long? = null,
        var inspectionStartedAt: Long? = null,
        var inspectionFinishedAt: Long? = null,
        var mainKeyguardConfirmedAt: Long? = null,
        var attachRequestedAt: Long? = null,
        var addViewReturnedAt: Long? = null,
        var firstRootDrawAt: Long? = null,
        var firstShaderDrawAt: Long? = null,
        var retryCount: Int = 0,
        var rejectedLateResults: Int = 0,
        var eventAgeMs: Long? = null,
    )

    /** A retry is tied to the exact hidden result which requested it. The
     * follow-up gets fresh inspection authority only if that wake/visibility
     * state still exists when its short backoff expires. */
    private data class RetryToken(
        val requestId: Long,
        val session: Long,
        val visibilityEpoch: Long,
        val wakeGeneration: Long,
    )

    private var wakeTiming: WakeTiming? = null
    /** The service state that owned the currently attached root's first-draw
     * diagnostics. Deferred draw work must match this original identity, not
     * merely whichever wake happens to be current when it returns. */
    private var firstDrawOwner: KeyguardFirstDrawOwner? = null

    private val powerManager by lazy { getSystemService(PowerManager::class.java) }
    private val keyguardManager by lazy { getSystemService(android.app.KeyguardManager::class.java) }
    private val userManager by lazy { getSystemService(UserManager::class.java) }
    private val displayManager by lazy { getSystemService(DisplayManager::class.java) }

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_SCREEN_OFF -> hideImmediately("screenOff")
                Intent.ACTION_USER_PRESENT -> hideImmediately("userPresent")
                Intent.ACTION_SCREEN_ON -> beginWakeCycle("wake")
            }
        }
    }

    private val displayListener = object : DisplayManager.DisplayListener {
        override fun onDisplayAdded(displayId: Int) = Unit
        override fun onDisplayRemoved(displayId: Int) = Unit
        override fun onDisplayChanged(displayId: Int) {
            if (displayId != Display.DEFAULT_DISPLAY) return
            if (fastHideIfSystemExcluded("display")) return
            scheduleEvaluation("display")
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
            onInteractionStarted = ::onOverlayInteractionStarted,
            onPositionCommitted = ::onOverlayPositionCommitted,
            onInteractionDiagnostic = { event, detail ->
                KeyguardCardDiagnostics.record(this, event, detail, overlay.isAttached)
            },
            onFirstRootDraw = ::recordFirstRootDraw,
            onFirstShaderDraw = ::recordFirstShaderDraw,
        )
        val settings = FluviKeyguardCardSettings.read(applicationContext)
        val profile = FluviKeyguardMaterialStore.read(applicationContext)
        lastSettings = settings
        lastMaterialProfile = profile
        registerRuntimeSignals()
        overlay.prepareRetainedView(settings, profile)
        KeyguardCardDiagnostics.record(this, "KG|SERVICE_CONNECTED", "connected", false)
        beginWakeCycle("connected")
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
            eventTimeUptimeMs = event.eventTime,
        )
        if (!KeyguardCardEventGate.isSurfaceEvent(meta.eventType)) return
        // This check intentionally precedes the stale-result gate: an already
        // unlocked device must not wait for a Binder tree walk to finish.
        if (fastHideIfSystemExcluded("accessibility")) return
        val own = ::overlay.isInitialized && overlay.isOwnAccessibilityWindow(meta.windowId, meta.displayId)
        when (KeyguardCardEventGate.decide(meta, own)) {
            KeyguardEventAction.IGNORE_OWN -> {
                KeyguardCardDiagnostics.record(this, "KG|OWN_EVENT_IGNORED", "ownSignal", overlay.isAttached)
                // The package-less post-add race reaches INSPECT, not an
                // eager detach. A positively matched own event needs no work.
            }
            KeyguardEventAction.INSPECT -> scheduleEvaluation("window", meta.eventTimeUptimeMs)
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
                overlay.updateMaterial(lastMaterialProfile, settings)
                scheduleEvaluation("settings")
            } else {
                // A position-only change is a WindowManager layout update,
                // not a financial invalidation or view-state reset.
                if (previous?.showFinancialDetails != settings.showFinancialDetails) showEvent = false
                overlay.updateMaterial(lastMaterialProfile, settings)
                scheduleEvaluation("settings")
            }
        }
    }

    /** Layout patches intentionally bypass the general settings/evaluation
     * lane: a drag has already updated the retained root and must not start a
     * financial resolve, material reload or focus-generation change. */
    internal fun onLayoutChangedFromApplication(settings: KeyguardCardSettings) {
        mainHandler.post {
            lastSettings = settings
            if (::overlay.isInitialized) overlay.updateLayoutSettings(settings)
        }
    }

    private fun onOverlayInteractionStarted() {
        // This only invalidates reads that predate the pointer stream. A later
        // real SystemUI event starts a fresh inspection and remains allowed to
        // hide the overlay even while the finger is down.
        interactionEpoch.incrementAndGet()
    }

    private fun onOverlayPositionCommitted(
        mode: KeyguardCardPresentationMode,
        card: KeyguardCardCardPosition,
        orb: KeyguardCardOrbPosition,
        expectedLayoutRevision: Long,
    ) {
        val settings = FluviKeyguardCardSettings.patchLayout(
            applicationContext,
            mapOf(
                "presentationMode" to mode.wireValue,
                "cardPosition" to mapOf("yFraction" to card.yFraction),
                "orbPosition" to mapOf("xFraction" to orb.xFraction, "yFraction" to orb.yFraction),
            ),
            expectedLayoutRevision = expectedLayoutRevision,
        )
        lastSettings = settings
        // A newer reset/layout patch won the race. Return the attached root
        // to that persisted geometry without entering the general settings
        // path or re-resolving financial content.
        if (settings.layoutRevision != expectedLayoutRevision + 1L) {
            overlay.updateLayoutSettings(settings)
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
            lastMaterialProfile = profile
            if (!::overlay.isInitialized) return@post
            overlay.updateMaterial(profile, lastSettings ?: FluviKeyguardCardSettings.read(applicationContext))
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

    private fun beginWakeCycle(source: String) {
        wakeEpoch += 1L
        firstDrawOwner = null
        retryCount = 0
        cancelWakeRetry()
        val settings = lastSettings ?: FluviKeyguardCardSettings.read(applicationContext)
        wakeTiming = WakeTiming(
            wakeGeneration = wakeEpoch,
            wakeReceivedAt = SystemClock.uptimeMillis(),
            rootWasPrepared = ::overlay.isInitialized && overlay.hasPreparedRoot,
            profileWasDecoded = lastMaterialProfile != null,
            presentationMode = settings.presentationMode.wireValue,
        )
        KeyguardCardDiagnostics.beginLockAttempt(this, session.get(), wakeEpoch)
        scheduleEvaluation(source)
    }

    /** A deliberately small main-thread fast path. Display transition states
     * are not treated as OFF: SCREEN_ON can arrive before STATE_ON settles. */
    private fun fastHideIfSystemExcluded(source: String): Boolean {
        if (!::overlay.isInitialized) return false
        val display = displayManager.getDisplay(Display.DEFAULT_DISPLAY)
        val shouldHide = KeyguardCardFastHideGate.shouldHide(
            displayInteractive = powerManager.isInteractive,
            displayOff = display?.state == Display.STATE_OFF,
            keyguardLocked = keyguardManager.isKeyguardLocked,
        )
        if (!shouldHide) return false
        hideImmediately(source)
        return true
    }

    private fun scheduleWakeRetry(cause: KeyguardCardInspectionRequest) {
        if (retryCount >= RETRY_DELAYS_MS.size) return
        cancelWakeRetry()
        val delay = RETRY_DELAYS_MS[retryCount]
        retryCount += 1
        val token = RetryToken(
            requestId = cause.id,
            session = cause.session,
            visibilityEpoch = visibilityEpoch.get(),
            wakeGeneration = cause.wakeGeneration,
        )
        wakeTiming?.takeIf { it.wakeGeneration == token.wakeGeneration }?.retryCount = retryCount
        retryRunnable = Runnable {
            retryRunnable = null
            if (token.session != session.get() ||
                token.visibilityEpoch != visibilityEpoch.get() ||
                token.wakeGeneration != wakeEpoch ||
                !FluviKeyguardCardServiceRegistry.connected
            ) return@Runnable
            if (fastHideIfSystemExcluded("retryGate")) return@Runnable
            scheduleEvaluation("surfaceRetry")
        }.also { mainHandler.postDelayed(it, delay) }
    }

    private fun cancelWakeRetry(): Boolean {
        val pending = retryRunnable ?: return false
        mainHandler.removeCallbacks(pending)
        retryRunnable = null
        return true
    }

    /** Captures authority at request creation, not when a delayed worker gets
     * CPU. At most one Binder traversal and one latest follow-up can exist. */
    private fun scheduleEvaluation(trigger: String, eventTimeUptimeMs: Long? = null) {
        if (!FluviKeyguardCardServiceRegistry.connected) return
        if (trigger != "surfaceRetry") cancelWakeRetry()
        val now = SystemClock.uptimeMillis()
        val request = KeyguardCardInspectionRequest(
            id = nextInspectionId.incrementAndGet(),
            trigger = trigger,
            session = session.get(),
            visibilityEpoch = visibilityEpoch.get(),
            interactionEpoch = interactionEpoch.get(),
            attachGeneration = overlayAttachGeneration,
            wakeGeneration = wakeEpoch,
            queuedAtUptimeMs = now,
            eventTimeUptimeMs = eventTimeUptimeMs,
        )
        wakeTiming?.takeIf { it.wakeGeneration == request.wakeGeneration }?.let {
            if (it.inspectionQueuedAt == null) it.inspectionQueuedAt = now
            request.eventTimeUptimeMs?.takeIf { eventTime -> eventTime <= now }?.let { eventTime ->
                it.eventAgeMs = now - eventTime
            }
        }
        val startWorker = synchronized(queueLock) { inspectionQueue.offer(request) }
        if (startWorker) inspectionScope.launch { processInspectionQueue(request) }
    }

    private suspend fun processInspectionQueue(first: KeyguardCardInspectionRequest) {
        var request: KeyguardCardInspectionRequest? = first
        while (request != null) {
            val active = request
            val startedAt = SystemClock.uptimeMillis()
            val result = inspectSurface(active)
            val finishedAt = SystemClock.uptimeMillis()
            withContext(Dispatchers.Main.immediate) {
                applyInspection(result, active, startedAt, finishedAt)
            }
            request = synchronized(queueLock) { inspectionQueue.complete(active) }
        }
    }

    private data class Inspection(
        val signals: KeyguardCardSignals,
        val decision: KeyguardCardVisibility,
        val surfaceReason: KeyguardSurfaceReason,
        val ownOverlayWindowId: Int? = null,
    )

    /** A missing Budget category is a user-visible configuration state, not a
     * generic exception.  Keeping this typed also prevents every window event
     * from restarting an impossible `requireNotNull` query. */
    private sealed interface FullContentResolveResult {
        val diagnosticCode: String
        data class Ready(val content: FluviLockScreenCardContent) : FullContentResolveResult {
            override val diagnosticCode = "ready"
        }
        data class InvalidFocus(override val diagnosticCode: String) : FullContentResolveResult
        object StaleRequest : FullContentResolveResult { override val diagnosticCode = "staleRequest" }
        data class Failure(override val diagnosticCode: String) : FullContentResolveResult
    }

    private data class SystemWindowsRead(
        val snapshots: List<KeyguardWindowSnapshot>,
        val rootUnavailable: Boolean,
        val walkTruncated: Boolean,
    )

    private data class VisibleIds(
        val ids: Set<String>,
        val truncated: Boolean,
    )

    private fun inspectSurface(request: KeyguardCardInspectionRequest): Inspection {
        // The settings/profile input is maintained on the service lifetime;
        // an inspection must not contend on preferences/JSON work at wake.
        val settings = lastSettings ?: FluviKeyguardCardSettings.read(applicationContext)
        val baseline = quickSignals(settings, KeyguardSurface.UNKNOWN)
        if (!baseline.requested || !baseline.serviceConnected || !baseline.userUnlocked ||
            !baseline.primaryDisplay || !baseline.interactive || !baseline.displayOn || !baseline.keyguardLocked
        ) {
            return Inspection(baseline, KeyguardCardVisibilityPolicy.decide(baseline), KeyguardSurfaceReason.NO_WINDOWS)
        }
        if (session.get() != request.session || visibilityEpoch.get() != request.visibilityEpoch ||
            wakeEpoch != request.wakeGeneration
        ) {
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
        request: KeyguardCardInspectionRequest,
        inspectionStartedAt: Long,
        inspectionFinishedAt: Long,
    ) {
        wakeTiming?.takeIf { it.wakeGeneration == request.wakeGeneration }?.apply {
            this.inspectionStartedAt = inspectionStartedAt
            this.inspectionFinishedAt = inspectionFinishedAt
        }
        // This current-state test deliberately runs even for an obsolete
        // payload. A phone that is already unlocked/off must not retain this
        // service's old overlay because its Binder answer arrived late.
        if (fastHideIfSystemExcluded("inspection:${request.trigger}")) {
            wakeTiming?.takeIf { it.wakeGeneration == request.wakeGeneration }?.let {
                it.rejectedLateResults += 1
            }
            return
        }
        // A stale Binder walk has no authority over a newer session/epoch.
        // In particular, it must not remove an overlay attached by a later
        // wake inspection.
        when (KeyguardCardInspectionGate.decide(
            expectedSession = request.session,
            currentSession = session.get(),
            expectedEpoch = request.visibilityEpoch,
            currentEpoch = visibilityEpoch.get(),
            expectedInteractionEpoch = request.interactionEpoch,
            currentInteractionEpoch = interactionEpoch.get(),
            expectedAttachGeneration = request.attachGeneration,
            currentAttachGeneration = overlayAttachGeneration,
            expectedWakeGeneration = request.wakeGeneration,
            currentWakeGeneration = wakeEpoch,
            displayEligibleNow = isDisplayOnAndInteractive(),
            keyguardLockedNow = keyguardManager.isKeyguardLocked,
        )) {
            KeyguardInspectionAction.DROP_STALE -> {
                wakeTiming?.takeIf { it.wakeGeneration == request.wakeGeneration }?.let {
                    it.rejectedLateResults += 1
                }
                KeyguardCardDiagnostics.record(this, "KG|INSPECTION_STALE", "surfaceEpoch", overlay.isAttached)
                return
            }
            KeyguardInspectionAction.HIDE_CURRENT_GATE -> {
                hideImmediately("currentGate")
                return
            }
            KeyguardInspectionAction.APPLY -> Unit
        }
        // Recording a window id is also a mutation of current overlay state,
        // so it belongs behind all session/epoch/attach checks.
        inspection.ownOverlayWindowId?.let { overlay.recordAccessibilityWindowId(it, request.attachGeneration) }
        val decision = inspection.decision
        KeyguardCardDiagnostics.record(this, "KG|SURFACE_DECISION", "${decision.name}:${inspection.surfaceReason.name}", overlay.isAttached)
        appliedDecision = decision
        when (decision) {
            KeyguardCardVisibility.SHOW_DISCREET -> {
                retryCount = 0
                cancelWakeRetry()
                wakeTiming?.takeIf { it.wakeGeneration == request.wakeGeneration }?.mainKeyguardConfirmedAt = SystemClock.uptimeMillis()
                stopFinancialObservation()
                showEvent = false
                applyPresentation(FluviFinancialCardPresenter.discreet(), "discreet:${request.trigger}")
            }
            KeyguardCardVisibility.SHOW_FULL -> {
                retryCount = 0
                cancelWakeRetry()
                wakeTiming?.takeIf { it.wakeGeneration == request.wakeGeneration }?.mainKeyguardConfirmedAt = SystemClock.uptimeMillis()
                val focus = (lastSettings ?: FluviKeyguardCardSettings.read(applicationContext)).focus
                showFullContent(request.session, request.visibilityEpoch, focus.generation, request.trigger)
            }
            else -> {
                val shouldRetry = decision == KeyguardCardVisibility.HIDDEN_UNKNOWN && retryCount < RETRY_DELAYS_MS.size &&
                    isDisplayOnAndInteractive() && keyguardManager.isKeyguardLocked
                hideImmediately(decision.name, terminalWake = !shouldRetry)
                if (shouldRetry) scheduleWakeRetry(request)
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
        terminalContentFailure?.takeIf { it.first == focusGeneration }?.let { (_, code) ->
            applyPresentation(FluviFinancialCardPresenter.unavailable(code), "invalidFocus:$trigger")
            return
        }
        transientContentFailure?.takeIf { it.first == focusGeneration }?.let { (_, code) ->
            applyPresentation(FluviFinancialCardPresenter.unavailable(code), "contentUnavailable:$trigger")
            return
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
        coreObservation = financialScope.launch {
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
        contentJob = financialScope.launch {
            val focus = (lastSettings ?: FluviKeyguardCardSettings.read(applicationContext)).focus
            val outcome = when {
                focus.generation != focusGeneration -> FullContentResolveResult.StaleRequest
                !focus.isValid -> FullContentResolveResult.InvalidFocus("missingCategory")
                else -> resolveKeyguardContent(focus)
            }
            withContext(Dispatchers.Main.immediate) {
                try {
                    val settings = lastSettings ?: FluviKeyguardCardSettings.read(applicationContext)
                    val stillCurrent = KeyguardCardContentPublicationPolicy.canApply(
                        KeyguardCardContentPublication(
                            requestSession = expectedSession,
                            currentSession = session.get(),
                            requestEpoch = expectedEpoch,
                            currentEpoch = visibilityEpoch.get(),
                            requestFocusGeneration = focusGeneration,
                            currentFocusGeneration = (lastSettings ?: FluviKeyguardCardSettings.read(applicationContext)).focus.generation,
                            currentlyFull = appliedDecision == KeyguardCardVisibility.SHOW_FULL,
                            detailsStillAllowed = settings.showFinancialDetails,
                            displayStillEligible = isDisplayOnAndInteractive() && keyguardManager.isKeyguardLocked,
                        ),
                    )
                    val content = (outcome as? FullContentResolveResult.Ready)?.content
                    if (!stillCurrent || content == null) {
                        if (stillCurrent && outcome is FullContentResolveResult.InvalidFocus) {
                            terminalContentFailure = focusGeneration to outcome.diagnosticCode
                            applyPresentation(
                                FluviFinancialCardPresenter.unavailable(outcome.diagnosticCode),
                                "invalidFocus:${outcome.diagnosticCode}",
                            )
                        } else if (stillCurrent && outcome is FullContentResolveResult.Failure) {
                            transientContentFailure = focusGeneration to outcome.diagnosticCode
                            applyPresentation(
                                FluviFinancialCardPresenter.unavailable(outcome.diagnosticCode),
                                "contentUnavailable:${outcome.diagnosticCode}",
                            )
                        }
                        KeyguardCardDiagnostics.record(
                            this@FluviKeyguardCardService,
                            "KG|CONTENT_STALE",
                            if (content == null) "resolve:${outcome.diagnosticCode}" else "contentEpoch",
                            overlay.isAttached,
                        )
                    } else {
                        renderedFullContent = content
                        activeFocusGeneration = focusGeneration
                        terminalContentFailure = null
                        transientContentFailure = null
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

    private suspend fun resolveKeyguardContent(focus: KeyguardCardFocus): FullContentResolveResult = try {
        FullContentResolveResult.Ready(
            FluviLockScreenCardCoordinator.resolve(applicationContext, focus.asFinancialFocus()),
        )
    } catch (error: CancellationException) {
        throw error
    } catch (error: IllegalArgumentException) {
        // The resolver's known invalid-focus paths are intentionally distinct
        // from an unavailable database. Do not retain the exception message:
        // it can include implementation details and is not useful on a lock
        // screen diagnostic surface.
        FullContentResolveResult.InvalidFocus("invalidFocus")
    } catch (_: Throwable) {
        FullContentResolveResult.Failure("queryFailure")
    }

    private fun applyPresentation(presentation: com.fluvi.app.runtime.FluviFinancialCardPresentation, reason: String) {
        val settings = lastSettings ?: FluviKeyguardCardSettings.read(applicationContext).also { lastSettings = it }
        // This only changes retained drawing input; no animation frame is
        // allowed to enter showOrUpdate or the financial presentation lane.
        overlay.updateMaterial(lastMaterialProfile, settings)
        wakeTiming?.takeIf { it.wakeGeneration == wakeEpoch && it.attachRequestedAt == null }?.attachRequestedAt =
            SystemClock.uptimeMillis()
        when (val result = overlay.showOrUpdate(presentation, settings)) {
            KeyguardCardWindow.Result.ATTACHED -> {
                overlayAttachGeneration = overlay.currentAttachGeneration
                firstDrawOwner = KeyguardFirstDrawOwner(
                    session = session.get(),
                    wakeGeneration = wakeEpoch,
                    attachGeneration = overlayAttachGeneration,
                )
                wakeTiming?.takeIf { it.wakeGeneration == wakeEpoch }?.addViewReturnedAt = SystemClock.uptimeMillis()
                KeyguardCardDiagnostics.attach(this, "attached")
                KeyguardCardDiagnostics.record(this, "KG|ATTACH", reason, true)
                publishWakeTiming("attached")
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
        val focus = FluviKeyguardCardSettings.read(applicationContext).focus
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

    /** Main-thread terminal path. It makes the retained root locally invisible
     * and removes it before cancelling database/diagnostic work. A late Binder
     * answer can only fail its captured authority checks afterwards. */
    private fun hideImmediately(reason: String, terminalWake: Boolean = true) {
        val exclusionAt = SystemClock.uptimeMillis()
        visibilityEpoch.incrementAndGet()
        interactionEpoch.incrementAndGet()
        // Invalidate publication before the retained root can be detached.
        // Its already-posted observer cleanup remains responsible for removing
        // only its own listener after the framework draw traversal ends.
        firstDrawOwner = null
        if (terminalWake) {
            wakeEpoch += 1L
            cancelWakeRetry()
            synchronized(queueLock) { inspectionQueue.clearPending() }
        }
        appliedDecision = KeyguardCardVisibility.HIDDEN_UNKNOWN
        showEvent = false
        val dragWasActive = ::overlay.isInitialized && overlay.isDragActive
        var removeReturnedAt: Long? = null
        if (::overlay.isInitialized) {
            val wasAttached = overlay.isAttached
            val removed = overlay.hide()
            removeReturnedAt = SystemClock.uptimeMillis()
            if (wasAttached && removed) KeyguardCardDiagnostics.record(this, "KG|DETACH", reason, false)
        }
        // Window visibility is already withdrawn; only now cancel potentially
        // blocking work and persist the compact diagnostic summary.
        stopFinancialObservation()
        KeyguardCardDiagnostics.record(
            this,
            "KG|HIDE_TIMING",
            "source=$reason|exclusionToHideRequestMs=0|exclusionToRemoveReturnMs=" +
                (removeReturnedAt?.minus(exclusionAt) ?: -1L) +
                "|cancelledWakeJobs=${if (terminalWake) 1 else 0}|dragWasActive=$dragWasActive|rollbackLayoutCallsDuringHide=0",
            false,
        )
    }

    /** Both callbacks arrive after their draw stacks have unwound. The event
     * still carries its original attach id, so a wake A callback cannot write
     * timing into wake B after a fast lock/unlock/reattach sequence. */
    private fun recordFirstRootDraw(event: KeyguardFirstDrawEvent) {
        val owner = firstDrawOwner ?: return
        if (!owner.accepts(event, session.get(), wakeEpoch, overlayAttachGeneration)) return
        val timing = wakeTiming?.takeIf { it.wakeGeneration == owner.wakeGeneration } ?: return
        if (timing.firstRootDrawAt == null) {
            timing.firstRootDrawAt = event.observedAtUptimeMs
            publishWakeTiming("firstRootDraw")
        }
    }

    private fun recordFirstShaderDraw(event: KeyguardFirstDrawEvent) {
        val owner = firstDrawOwner ?: return
        if (!owner.accepts(event, session.get(), wakeEpoch, overlayAttachGeneration)) return
        val timing = wakeTiming?.takeIf { it.wakeGeneration == owner.wakeGeneration } ?: return
        if (timing.firstShaderDrawAt == null) {
            timing.firstShaderDrawAt = event.observedAtUptimeMs
            publishWakeTiming("firstShaderDraw")
        }
    }

    private fun publishWakeTiming(stage: String) {
        val timing = wakeTiming ?: return
        val queue = timing.inspectionStartedAt?.minus(timing.inspectionQueuedAt ?: timing.inspectionStartedAt ?: 0L)
        val inspect = timing.inspectionFinishedAt?.minus(timing.inspectionStartedAt ?: timing.inspectionFinishedAt ?: 0L)
        val confirmedToAttach = timing.attachRequestedAt?.minus(timing.mainKeyguardConfirmedAt ?: timing.attachRequestedAt ?: 0L)
        val attachToDraw = timing.firstRootDrawAt?.minus(timing.addViewReturnedAt ?: timing.firstRootDrawAt ?: 0L)
        val callbackToDraw = timing.firstRootDrawAt?.minus(timing.wakeReceivedAt)
        KeyguardCardDiagnostics.record(
            this,
            "KG|WAKE_TIMING",
            "stage=$stage|wake=${timing.wakeGeneration}|eventAgeMs=${timing.eventAgeMs ?: -1L}|inspectionQueueMs=${queue ?: -1L}|" +
                "inspectionDurationMs=${inspect ?: -1L}|confirmedToAttachMs=${confirmedToAttach ?: -1L}|" +
                "attachToFirstDrawMs=${attachToDraw ?: -1L}|callbackToFirstDrawMs=${callbackToDraw ?: -1L}|" +
                "firstShaderDrawAt=${timing.firstShaderDrawAt ?: -1L}|" +
                "retryCount=${timing.retryCount}|rootWasPrepared=${timing.rootWasPrepared}|" +
                "profileWasDecoded=${timing.profileWasDecoded}|presentationMode=${timing.presentationMode}|" +
                "rejectedLateResults=${timing.rejectedLateResults}",
            overlay.isAttached,
        )
    }

    internal fun materialDiagnostics(): Map<String, Any?> {
        val values = if (::overlay.isInitialized) overlay.materialDiagnostics() else null
        val profile = FluviKeyguardMaterialStore.read(applicationContext)
        val focus = FluviKeyguardCardSettings.read(applicationContext).focus
        return mapOf(
            // `rendererBackend` remains for older Flutter diagnostics; the
            // requested/active pair tells whether AGSL actually compiled and
            // drew instead of merely being available on this API level.
            "rendererBackend" to values?.activeRenderer,
            "requestedRenderer" to values?.requestedRenderer,
            "activeRenderer" to values?.activeRenderer,
            "hardwareAccelerated" to (values?.hardwareAccelerated ?: false),
            "shaderCreationCount" to (values?.shaderCreationCount ?: 0),
            "animationStartCount" to (values?.animationStartCount ?: 0),
            "animationStopCount" to (values?.animationStopCount ?: 0),
            "drawCount" to (values?.frameCallbackCount ?: 0),
            "frameCallbackCount" to (values?.frameCallbackCount ?: 0),
            "frameIntervalP50" to (values?.frameIntervalP50 ?: 0),
            "frameIntervalP95" to (values?.frameIntervalP95 ?: 0),
            "largeFrameGapCount" to (values?.largeFrameGapCount ?: 0),
            "lastRendererFailure" to values?.rendererFailure,
            "shaderCompileAttempts" to ((values?.orb?.shaderCompileAttempts ?: 0) + (values?.background?.shaderCompileAttempts ?: 0)),
            "shaderCompileSuccesses" to ((values?.orb?.shaderCompileSuccesses ?: 0) + (values?.background?.shaderCompileSuccesses ?: 0)),
            "shaderCompileFailures" to ((values?.orb?.shaderCompileFailures ?: 0) + (values?.background?.shaderCompileFailures ?: 0)),
            "onDrawCount" to ((values?.orb?.onDrawCount ?: 0) + (values?.background?.onDrawCount ?: 0)),
            "shaderDrawCount" to ((values?.orb?.shaderDrawCount ?: 0) + (values?.background?.shaderDrawCount ?: 0)),
            "fallbackDrawCount" to ((values?.orb?.fallbackDrawCount ?: 0) + (values?.background?.fallbackDrawCount ?: 0)),
            "phaseAdvanceCount" to ((values?.orb?.phaseAdvanceCount ?: 0) + (values?.background?.phaseAdvanceCount ?: 0)),
            "transitionCompletedCount" to ((values?.orb?.transitionCompletedCount ?: 0) + (values?.background?.transitionCompletedCount ?: 0)),
            "lastFailureStage" to (values?.orb?.failureStage ?: values?.background?.failureStage),
            "lastFailureClass" to (values?.orb?.failureClass ?: values?.background?.failureClass),
            "lastFailureMessage" to (values?.orb?.failureMessage ?: values?.background?.failureMessage),
            "shaderSourceHash" to (profile?.sourceShaderHash ?: values?.orb?.generatedAgslHash),
            "generatedAgslHash" to (values?.orb?.generatedAgslHash ?: values?.background?.generatedAgslHash),
            "adapterVersion" to (values?.orb?.adapterVersion ?: values?.background?.adapterVersion),
            "profileStatus" to FluviKeyguardMaterialStore.status(applicationContext),
            "profileRevision" to (profile?.publisherRevision ?: -1L),
            "focusGeneration" to focus.generation,
            "effectId" to profile?.effectId,
            "animationMode" to FluviKeyguardCardSettings.read(applicationContext).animationMode.wireValue,
            "privacyMode" to if (FluviKeyguardCardSettings.read(applicationContext).showFinancialDetails) "full" else "discreet",
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
        terminalContentFailure = null
        transientContentFailure = null
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
            terminalContentFailure = null
            transientContentFailure = null
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
        serviceJob.cancel()
    }

    companion object {
        private val RETRY_DELAYS_MS = longArrayOf(16L, 32L, 64L)
        const val ACTION_OPEN_FOCUS = "com.fluvi.app.lockscreen.OPEN_FOCUS"
        const val EXTRA_MODE = "com.fluvi.app.lockscreen.MODE"
        const val EXTRA_AXIS = "com.fluvi.app.lockscreen.AXIS"
        const val EXTRA_DIRECTION = "com.fluvi.app.lockscreen.DIRECTION"
        const val EXTRA_CATEGORY = "com.fluvi.app.lockscreen.CATEGORY"
    }
}
