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
import android.os.SystemClock
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
import java.util.concurrent.atomic.AtomicInteger
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
    private val platformSystemStateReader by lazy { AndroidKeyguardSystemStateReader(this) }
    @Volatile internal var systemStateReaderOverride: KeyguardSystemStateReader? = null
    /** Optional instrumentation seam. It orders a negative acquisition/result;
     * it never skips the production classifier, authority gate or admission. */
    @Volatile internal var inspectionProbeForTest: KeyguardInspectionProbeForTest? = null
    internal fun inspectionStateForTest() = KeyguardInspectionStateForTest(
        inspectionAuthority, synchronized(queueLock) { inspectionQueue.pendingRequest() },
        wakeCycleOwner.current()?.id, ::overlay.isInitialized && overlay.isAttached, retryCount,
    )
    private val systemReads = java.util.concurrent.atomic.AtomicLongArray(KeyguardSystemReadPurpose.entries.size)
    private val mainSystemReads = java.util.concurrent.atomic.AtomicLongArray(KeyguardSystemReadPurpose.entries.size)
    private fun readSystemState(purpose: KeyguardSystemReadPurpose): KeyguardSystemState {
        systemReads.incrementAndGet(purpose.ordinal)
        if (Looper.myLooper() == Looper.getMainLooper()) mainSystemReads.incrementAndGet(purpose.ordinal)
        return withMainWorkEvidence(KeyguardMainWorkEvidence.SYSTEM_GATE) {
            (systemStateReaderOverride ?: platformSystemStateReader).read(purpose)
        }
    }

    internal fun requestSystemCheckForTest() { requestSystemCheck("blockedReaderRegression") }
    private var nextSystemGateId = 0L
    private val systemGateExecutor = java.util.concurrent.Executors.newSingleThreadExecutor { task ->
        Thread(task, "Fluvi-system-gate")
    }
    private val systemSampler = KeyguardSystemStateSampler(
        reader = { KeyguardSystemStateReader(::readSystemState) },
        worker = { systemGateExecutor.execute(it) },
        main = { mainHandler.post(it) },
        current = { inspectionAuthority },
        receive = ::applySystemState,
    )
    private val mainWorkEvidence = KeyguardMainWorkEvidence()
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
    private var retryToken: RetryToken? = null
    private var nextRetryId = 0L
    @Volatile private var wakeEpoch = 0L
    /** One physical wake can be signalled by DisplayManager, accessibility and
     * ACTION_SCREEN_ON in either order. The pure owner prevents the late
     * broadcast from invalidating a compatible early inspection. */
    private val wakeCycleOwner = KeyguardWakeCycleOwner()
    /** Published from the main-thread lifecycle owner.  Binder traversal uses
     * this immutable snapshot instead of sampling five generations halfway
     * through a node walk. */
    @Volatile private var inspectionAuthority = KeyguardInspectionAuthority(
        serviceSession = 0L,
        visibilityEpoch = 0L,
        wakeGeneration = 0L,
        interactionEpoch = 0L,
        attachGeneration = 0L,
    )
    @Volatile private var knownOwnOverlayIdentity: KeyguardOwnOverlayIdentity? = null
    private val inspectionFreshness = KeyguardInspectionFreshness()
    /** The reader owns no visibility authority.  It only receives immutable
     * request identity and cooperatively stops after this service publishes a
     * newer authority snapshot. */
    private val windowSnapshotReader by lazy {
        KeyguardWindowSnapshotReader(this, packageName)
    }
    private val inspectionsAbortedBeforeRead = AtomicLong(0L)
    private val inspectionsAbortedDuringWalk = AtomicLong(0L)
    private val nodeReadsAfterInvalidation = AtomicLong(0L)
    private val freshReconciliationsScheduled = AtomicLong(0L)
    private val activeInspectionCount = AtomicInteger(0)
    private val maximumConcurrentInspections = AtomicInteger(0)
    private val maximumPendingInspections = AtomicInteger(0)
    @Volatile private var lastSettings: KeyguardCardSettings? = null
    @Volatile private var lastMaterialProfile: KeyguardMaterialProfile? = null
    private var showEvent = false
    private var appliedDecision = KeyguardCardVisibility.HIDDEN_DISCONNECTED
    /** Surface uncertainty is distinct from a terminal device exclusion.  The
     * window lifecycle remains authoritative for attachment; this state keeps
     * UNKNOWN results from churning authority while that lifecycle is already
     * detached. */
    private var surfacePresentationState = KeyguardSurfacePresentationState.TERMINALLY_EXCLUDED
    private var overlayAttachGeneration = 0L
    private lateinit var overlay: KeyguardCardWindow
    /** These identities are diagnostic-only and stay stable across the
     * generation invalidation that a terminal hide must perform. */
    private var currentDiagnosticAttempt: KeyguardDiagnosticContext? = null
    private var activeWindowDiagnosticOperation: KeyguardDiagnosticOperation? = null
    private var terminalHideState: KeyguardTerminalHideState? = null

    /** Must be called by the main-thread lifecycle owner after every
     * generation transition.  It never reads View state and is safe for the
     * one-wide Binder worker to consume. */
    private fun publishInspectionAuthority(renewSystemWork: Boolean = true) {
        val current = KeyguardInspectionAuthority(
            serviceSession = session.get(),
            visibilityEpoch = visibilityEpoch.get(),
            wakeGeneration = wakeEpoch,
            interactionEpoch = interactionEpoch.get(),
            attachGeneration = overlayAttachGeneration,
        )
        inspectionFreshness.publish(current)
        inspectionAuthority = current
        if (renewSystemWork) systemSampler.renewPending { old ->
            old.copy(id = ++nextSystemGateId, authority = current, queuedAt = SystemClock.uptimeMillis())
        }
    }

    private fun authorityIsCurrent(request: KeyguardCardInspectionRequest): Boolean =
        inspectionAuthority.matches(request)

    private fun recordMaximum(counter: AtomicInteger, value: Int) {
        var observed = counter.get()
        while (value > observed && !counter.compareAndSet(observed, value)) observed = counter.get()
    }

    /** Numeric, bounded attachment-gap evidence, never a visibility input.
     * These nested scopes are retained separately and must not be summed.
     * nanoTime matches the renderer/Choreographer observation clock; CPU is
     * this thread's whole-scope CPU, not a claim about Binder or GPU work. */
    private inline fun <T> withMainWorkEvidence(kind: Int, requestId: Long = 0L, operation: () -> T): T {
        if (Looper.myLooper() != Looper.getMainLooper() || !KeyguardCardDiagnostics.wantsEvent("MAIN_WORK")) {
            return operation()
        }
        val startedNs = System.nanoTime()
        val startedCpuNs = android.os.Debug.threadCpuTimeNanos()
        try {
            return operation()
        } finally {
            val endedNs = System.nanoTime()
            val cpuNs = keyguardThreadCpuDelta(startedCpuNs, android.os.Debug.threadCpuTimeNanos())
            mainWorkEvidence.record(kind, requestId, startedNs, endedNs, cpuNs)
        }
    }

    /** An authority change may make an external surface request stale.  Keep
     * exactly one current reconciliation behind the active Binder call rather
     * than relabelling that old result as current.  Terminal exclusions call
     * clearPending instead and never reach this path. */
    private fun preservePendingReconciliation(
        reason: String,
        requirePending: Boolean,
        freshness: KeyguardWindowFreshness = KeyguardWindowFreshness.FRAMEWORK_EVENT,
    ) {
        if (!FluviKeyguardCardServiceRegistry.connected || !::overlay.isInitialized) return
        val needsReconciliation = synchronized(queueLock) {
            if (requirePending) inspectionQueue.pendingRequest() != null
            else inspectionQueue.activeRequest() != null || inspectionQueue.pendingRequest() != null
        }
        if (!needsReconciliation || wakeCycleOwner.current() == null || lastSettings?.requested != true) return
        freshReconciliationsScheduled.incrementAndGet()
        scheduleEvaluation(
            "authorityReconcile:$reason",
            triggerReceivedUptimeMs = SystemClock.uptimeMillis(),
            freshness = freshness,
        )
    }

    /** Capture instrumentation is intentionally observational: callers pass
     * their already-known identifiers and it never requests a new inspection,
     * material profile, content resolve, or window operation. */
    private fun traceKeyguard(
        stage: String,
        reason: String,
        request: KeyguardCardInspectionRequest? = null,
        requestId: Long? = null,
        attachGeneration: Long? = null,
        observedUptimeMs: Long? = null,
        diagnosticContext: KeyguardDiagnosticContext? = null,
        operation: KeyguardDiagnosticOperation? = null,
        fields: Map<String, Any?> = emptyMap(),
        deferredFields: (() -> Map<String, Any?>)? = null,
    ) {
        if (!KeyguardCardDiagnostics.wantsEvent(stage)) return
        withMainWorkEvidence(
            KeyguardMainWorkEvidence.DIAGNOSTIC_PRODUCER,
            request?.id ?: requestId ?: operation?.causingInspectionRequestId ?: 0L,
        ) {
            val capturedContext = operation?.context ?: diagnosticContext ?: request?.diagnosticContext ?: currentDiagnosticAttempt
            KeyguardCardDiagnostics.captureEvent(
                context = this,
                stage = stage,
                reason = reason,
                serviceSession = request?.session ?: session.get(),
                wakeEpoch = request?.wakeGeneration ?: wakeEpoch,
                requestId = request?.id ?: requestId ?: operation?.causingInspectionRequestId,
                attachGeneration = attachGeneration,
                observedUptimeMs = observedUptimeMs,
                diagnosticContext = capturedContext,
                operation = operation,
                fields = fields,
                deferredFields = deferredFields,
            )
        }
    }

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
        val draws: KeyguardDrawPublication = KeyguardDrawPublication(),
        var retryCount: Int = 0,
        var rejectedLateResults: Int = 0,
        var eventAgeMs: Long? = null,
    )

    /** A retry is tied to the exact hidden result which requested it. The
     * follow-up gets fresh inspection authority only if that wake/visibility
     * state still exists when its short backoff expires. */
    private data class RetryToken(
        val retryId: Long,
        val retryIndex: Int,
        val requestId: Long,
        val session: Long,
        val visibilityEpoch: Long,
        val interactionEpoch: Long,
        val attachGeneration: Long,
        val wakeGeneration: Long,
        val scheduledAtUptimeMs: Long,
        val dueAtUptimeMs: Long,
        val windowFreshness: KeyguardWindowFreshness,
        val diagnosticContext: KeyguardDiagnosticContext?,
    )

    private var wakeTiming: WakeTiming? = null
    /** The service state that owned the currently attached root's first-draw
     * diagnostics. Deferred draw work must match this original identity, not
     * merely whichever wake happens to be current when it returns. */
    private var firstDrawOwner: KeyguardFirstDrawOwner? = null

    private val displayManager by lazy { getSystemService(DisplayManager::class.java) }

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val receivedAt = SystemClock.uptimeMillis()
            when (intent.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    hideImmediately("screenOff", triggerReceivedUptimeMs = receivedAt)
                    traceKeyguard("SCREEN_OFF_RECEIVED", "broadcast", observedUptimeMs = receivedAt, fields = mapOf("sourceEventTime" to "NA", "sourceTimeUnavailable" to true))
                }
                Intent.ACTION_USER_PRESENT -> {
                    hideImmediately("userPresent", triggerReceivedUptimeMs = receivedAt)
                    traceKeyguard("USER_PRESENT_RECEIVED", "broadcast", observedUptimeMs = receivedAt, fields = mapOf("sourceEventTime" to "NA", "sourceTimeUnavailable" to true))
                }
                Intent.ACTION_SCREEN_ON -> beginOrJoinWakeCycle("wake", receivedAt)
            }
        }
    }

    private val displayListener = object : DisplayManager.DisplayListener {
        override fun onDisplayAdded(displayId: Int) = Unit
        override fun onDisplayRemoved(displayId: Int) = Unit
        override fun onDisplayChanged(displayId: Int) {
            if (displayId != Display.DEFAULT_DISPLAY) return
            val receivedAt = SystemClock.uptimeMillis()
            traceKeyguard("DISPLAY_EVENT", "changed", observedUptimeMs = receivedAt, fields = mapOf("displayId" to displayId))
            val cycle = beginOrJoinWakeCycle("display", receivedAt, schedule = false)
            if (cycle == null) return
            scheduleEvaluation(
                "display",
                triggerReceivedUptimeMs = receivedAt,
                freshness = if (cycle?.started == true) {
                    KeyguardWindowFreshness.LIFECYCLE_BOUNDARY
                } else {
                    KeyguardWindowFreshness.FRAMEWORK_EVENT
                },
            )
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        session.incrementAndGet()
        mainWorkEvidence.resetSession(session.get(), android.os.Process.myTid().toLong())
        KeyguardCardDiagnostics.recordColdPreparation(session.get(), "SERVICE_CONNECTED")
        publishInspectionAuthority()
        FluviKeyguardCardServiceRegistry.connected(this)
        overlay = KeyguardCardWindow(
            serviceContext = this,
            mainWorkEvidence = mainWorkEvidence,
            onOpen = ::openFocusedFluvi,
            onToggle = ::toggleView,
            onInteractionStarted = ::onOverlayInteractionStarted,
            onPositionCommitted = ::onOverlayPositionCommitted,
            onInteractionDiagnostic = { event, detail ->
                val attached = overlay.isAttached
                val attach = overlay.currentAttachGeneration
                mainHandler.post {
                    KeyguardCardDiagnostics.record(this, event, detail, attached)
                    traceKeyguard(event.removePrefix("KG|"), detail, attachGeneration = attach)
                }
            },
            onWindowDiagnostic = { stage, detail, attach, observedAt, fields ->
                // Window callbacks can occur immediately beside add/remove.
                // Capture-store mutation is deferred with the immutable
                // timestamp/owner so it cannot sit in front of that operation.
                val capturedOperation = activeWindowDiagnosticOperation
                val capturedFields = fields
                mainHandler.post {
                    if (stage.startsWith("MATERIAL_") || stage.startsWith("BOOTSTRAP_") || stage == "ADD_VIEW_RETURN") {
                        KeyguardCardDiagnostics.recordColdPreparation(
                            session.get(),
                            if (stage == "ADD_VIEW_RETURN") "FIRST_ATTACH" else stage,
                            observedAt,
                        )
                    }
                    if (stage == "ADD_VIEW_RETURN") {
                        wakeTiming?.takeIf { it.wakeGeneration == wakeEpoch && it.addViewReturnedAt == null }
                            ?.addViewReturnedAt = observedAt
                    }
                    traceKeyguard(
                        stage,
                        detail,
                        attachGeneration = attach,
                        observedUptimeMs = observedAt,
                        operation = capturedOperation,
                        fields = capturedFields,
                    )
                }
            },
            onFirstRootDraw = ::recordFirstRootDraw,
            onFirstShaderDraw = ::recordFirstShaderDraw,
            onBootstrapDraw = ::recordBootstrapDraw,
            onBootstrapCommit = ::recordBootstrapCommit,
            onLivePromotion = ::recordLivePromotion,
            onFrameCommit = ::recordFirstFrameCommit,
        )
        KeyguardCardDiagnostics.recordColdPreparation(session.get(), "SETTINGS_LOAD_START")
        val settings = FluviKeyguardCardSettings.read(applicationContext)
        KeyguardCardDiagnostics.recordColdPreparation(session.get(), "SETTINGS_LOAD_END")
        KeyguardCardDiagnostics.recordColdPreparation(session.get(), "PROFILE_LOAD_START")
        val profile = FluviKeyguardMaterialStore.read(applicationContext)
        KeyguardCardDiagnostics.recordColdPreparation(session.get(), "PROFILE_LOAD_END")
        lastSettings = settings
        lastMaterialProfile = profile
        registerRuntimeSignals()
        KeyguardCardDiagnostics.recordColdPreparation(session.get(), "ROOT_PREPARE_START")
        overlay.prepareRetainedView(settings, profile)
        KeyguardCardDiagnostics.recordColdPreparation(session.get(), "ROOT_PREPARE_END")
        KeyguardCardDiagnostics.record(this, "KG|SERVICE_CONNECTED", "connected", false)
        traceKeyguard("SERVICE_CONNECTED", "connected")
        beginOrJoinWakeCycle("connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        val callbackReceivedAt = SystemClock.uptimeMillis()
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
        val eventAge = meta.eventTimeUptimeMs
            ?.takeIf { it in 1..callbackReceivedAt }
            ?.let { callbackReceivedAt - it }
        val own = ::overlay.isInitialized && overlay.isOwnAccessibilityWindow(meta.windowId, meta.displayId)
        val action = KeyguardCardEventGate.decide(meta, own)
        if (KeyguardCardDiagnostics.wantsEvent("ACCESSIBILITY_EVENT")) traceKeyguard(
            "ACCESSIBILITY_EVENT",
            if (action == KeyguardEventAction.IGNORE_OWN) "ownIgnored" else "surface",
            observedUptimeMs = callbackReceivedAt,
            fields = mapOf(
                "eventType" to meta.eventType,
                "windowChanges" to meta.windowChanges,
                "windowId" to meta.windowId,
                "displayId" to meta.displayId,
                "eventTimeUptimeMs" to (meta.eventTimeUptimeMs?.takeIf { it > 0 } ?: "NA"),
                "eventAgeMs" to (eventAge ?: "NA_invalidOrFuture"),
                "classification" to if (action == KeyguardEventAction.IGNORE_OWN) "own" else "unclassified",
                "overlayState" to if (::overlay.isInitialized && overlay.isAttached) "attached" else "hidden",
            ),
        )
        when (action) {
            KeyguardEventAction.IGNORE_OWN -> {
                requestSystemCheck("accessibilityOwn", callbackReceivedAt, eventTime = meta.eventTimeUptimeMs)
                KeyguardCardDiagnostics.record(this, "KG|OWN_EVENT_IGNORED", "ownSignal", overlay.isAttached)
                // The package-less post-add race reaches INSPECT, not an
                // eager detach. A positively matched own event needs no work.
            }
            KeyguardEventAction.INSPECT -> {
                val cycle = beginOrJoinWakeCycle("accessibility", callbackReceivedAt, schedule = false,
                    eventTime = meta.eventTimeUptimeMs)
                if (cycle == null) return
                scheduleEvaluation(
                    "window",
                    meta.eventTimeUptimeMs,
                    triggerReceivedUptimeMs = callbackReceivedAt,
                    freshness = if (cycle?.started == true) {
                        KeyguardWindowFreshness.LIFECYCLE_BOUNDARY
                    } else {
                        KeyguardWindowFreshness.FRAMEWORK_EVENT
                    },
                )
            }
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
                if (overlay.isAttached) scheduleEvaluation("settings")
                else requestSystemCheck("privacyTightened")
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
        publishInspectionAuthority()
        preservePendingReconciliation("interaction", requirePending = false)
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

    /** Opens only a genuinely new eligible wake. SCREEN_ON joins a cycle that
     * was already established by a fresh Display/accessibility signal. */
    private fun beginOrJoinWakeCycle(
        source: String,
        receivedAtUptimeMs: Long = SystemClock.uptimeMillis(),
        schedule: Boolean = true,
        freshState: KeyguardSystemState? = null,
        eventTime: Long? = null,
    ): KeyguardWakeCycleTransition? {
        val existing = wakeCycleOwner.current()
        if (existing != null) {
            if (freshState == null) requestSystemCheck(source, receivedAtUptimeMs, eventTime = eventTime)
            val transition = if (source == "wake") {
                val joined = wakeCycleOwner.beginOrJoin(existing.id, source, receivedAtUptimeMs)
                traceKeyguard(
                    "SCREEN_ON_RECEIVED",
                    "joined:${joined.cycle.firstSignal}",
                    observedUptimeMs = receivedAtUptimeMs,
                    fields = mapOf("wakeCycleId" to joined.cycle.id, "joinedExistingCycle" to true),
                )
                joined
            } else {
                KeyguardWakeCycleTransition(existing, started = false, screenOnJoined = false)
            }
            // The early inspection already owns the current authority. Do
            // not replace it merely because another signal names the same
            // wake; schedule only when no compatible work exists.
            if (schedule && !hasCompatibleCycleInspection()) {
                scheduleEvaluation(source, triggerReceivedUptimeMs = receivedAtUptimeMs)
            }
            return transition
        }
        if (freshState == null) {
            requestSystemCheck(source, receivedAtUptimeMs, evaluate = true, wakeSource = source, eventTime = eventTime)
            return null
        }
        if (!freshState.eligible || lastSettings?.requested != true) return null
        val cycleTransition = wakeCycleOwner.beginOrJoin(wakeEpoch + 1L, source, receivedAtUptimeMs)
        val cycle = cycleTransition.cycle
        wakeEpoch = cycle.id
        // A new wake is a new eligible cycle; a prior terminal exclusion must
        // not suppress its first authoritative inspection.
        terminalHideState = null
        surfacePresentationState = KeyguardSurfacePresentationState.AWAITING_MAIN_SURFACE
        publishInspectionAuthority()
        firstDrawOwner = null
        retryCount = 0
        cancelWakeRetry()
        val settings = lastSettings ?: FluviKeyguardCardSettings.read(applicationContext)
        wakeTiming = WakeTiming(
            wakeGeneration = wakeEpoch,
            wakeReceivedAt = receivedAtUptimeMs,
            rootWasPrepared = ::overlay.isInitialized && overlay.hasPreparedRoot,
            profileWasDecoded = lastMaterialProfile != null,
            presentationMode = settings.presentationMode.wireValue,
        )
        currentDiagnosticAttempt = KeyguardCardDiagnostics.beginLockAttempt(
            this,
            session.get(),
            wakeEpoch,
            source,
            receivedAtUptimeMs,
        )
        synchronized(queueLock) { inspectionQueue.activeRequest() }?.let { occupied ->
            traceKeyguard(
                "WORKER_OCCUPIED_AT_WAKE",
                occupied.trigger,
                requestId = occupied.id,
                diagnosticContext = currentDiagnosticAttempt,
                observedUptimeMs = receivedAtUptimeMs,
                fields = mapOf(
                    "activeOriginalSession" to occupied.session,
                    "activeOriginalWake" to occupied.wakeGeneration,
                    "activeOriginalVisibilityEpoch" to occupied.visibilityEpoch,
                    "activeOriginalInteractionEpoch" to occupied.interactionEpoch,
                    "activeOriginalAttachGeneration" to occupied.attachGeneration,
                    "activeQueuedAtUptimeMs" to occupied.queuedAtUptimeMs,
                ),
            )
        }
        traceKeyguard(
            if (source == "wake") "SCREEN_ON_RECEIVED" else "WAKE_CYCLE_STARTED",
            source,
            observedUptimeMs = receivedAtUptimeMs,
            fields = mapOf("sourceEventTime" to "NA", "sourceTimeUnavailable" to true),
        )
        if (schedule) {
            scheduleEvaluation(
                source,
                triggerReceivedUptimeMs = receivedAtUptimeMs,
                freshness = KeyguardWindowFreshness.LIFECYCLE_BOUNDARY,
            )
        }
        return cycleTransition
    }

    private fun hasCompatibleCycleInspection(excludingId: Long? = null): Boolean = synchronized(queueLock) {
        inspectionQueue.hasCurrentWork(inspectionAuthority, excludingId)
    }

    /** No View/platform acquisition on this main-owned submission path. */
    private fun requestSystemCheck(
        reason: String,
        receivedAt: Long = SystemClock.uptimeMillis(),
        evaluate: Boolean = false,
        wakeSource: String? = null,
        retry: Boolean = false,
        freshness: KeyguardWindowFreshness = KeyguardWindowFreshness.FRAMEWORK_EVENT,
        eventTime: Long? = null,
        completedInspectionId: Long? = null,
    ) {
        if (!FluviKeyguardCardServiceRegistry.connected || lastSettings?.requested != true) return
        systemSampler.offer(KeyguardSystemGateRequest(++nextSystemGateId, inspectionAuthority,
            reason, receivedAt, SystemClock.uptimeMillis(), evaluate, wakeSource,
            eventTime = eventTime, retry = retry, freshness = freshness, completedInspectionId = completedInspectionId))
    }

    private fun applySystemState(request: KeyguardSystemGateRequest, state: KeyguardSystemState) {
        // The sampler checks every identity, even for a negative answer.
        if (!FluviKeyguardCardServiceRegistry.connected || lastSettings?.requested != true) return
        if (state.excluded) {
            hideImmediately("systemGate:${request.reason}", triggerReceivedUptimeMs = request.receivedAt)
            return
        }
        if (!state.eligible || !request.evaluate) return
        val cycle = request.wakeSource?.let {
            beginOrJoinWakeCycle(it, request.evaluationReceivedAt, schedule = false, freshState = state)
        }
        if (request.wakeSource != "wake") request.screenOnReceivedAt?.let {
            beginOrJoinWakeCycle("wake", it, schedule = false, freshState = state)
        }
        if (wakeCycleOwner.current() == null) return
        if (request.retry && hasCompatibleCycleInspection(request.completedInspectionId)) return
        scheduleEvaluation(request.evaluationReason, request.eventTime, request.evaluationReceivedAt,
            if (cycle?.started == true) KeyguardWindowFreshness.LIFECYCLE_BOUNDARY else request.freshness)
    }

    private fun scheduleWakeRetry(
        cause: KeyguardCardInspectionRequest,
        freshness: KeyguardWindowFreshness,
        reason: String = "hiddenUnknown",
    ) {
        if (retryCount >= RETRY_DELAYS_MS.size) return
        cancelWakeRetry("replaced")
        val delay = RETRY_DELAYS_MS[retryCount]
        retryCount += 1
        val scheduledAt = SystemClock.uptimeMillis()
        val token = RetryToken(
            retryId = ++nextRetryId,
            retryIndex = retryCount,
            requestId = cause.id,
            session = cause.session,
            visibilityEpoch = visibilityEpoch.get(),
            interactionEpoch = interactionEpoch.get(),
            attachGeneration = overlayAttachGeneration,
            wakeGeneration = cause.wakeGeneration,
            scheduledAtUptimeMs = scheduledAt,
            dueAtUptimeMs = scheduledAt + delay,
            windowFreshness = freshness,
            diagnosticContext = cause.diagnosticContext,
        )
        retryToken = token
        wakeTiming?.takeIf { it.wakeGeneration == token.wakeGeneration }?.retryCount = retryCount
        traceKeyguard(
            "RETRY_SCHEDULED",
            reason,
            cause,
            fields = mapOf(
                "retryId" to token.retryId,
                "retryIndex" to token.retryIndex,
                "requestedDelayMs" to delay,
                "scheduledAtUptimeMs" to token.scheduledAtUptimeMs,
                "dueAtUptimeMs" to token.dueAtUptimeMs,
                "causingRequestId" to cause.id,
            ),
        )
        retryRunnable = Runnable {
            retryRunnable = null
            retryToken = null
            val firedAt = SystemClock.uptimeMillis()
            traceKeyguard(
                "RETRY_FIRED",
                "timer",
                requestId = token.requestId,
                observedUptimeMs = firedAt,
                diagnosticContext = token.diagnosticContext,
                fields = mapOf(
                    "retryId" to token.retryId,
                    "retryIndex" to token.retryIndex,
                    "scheduledAtUptimeMs" to token.scheduledAtUptimeMs,
                    "dueAtUptimeMs" to token.dueAtUptimeMs,
                    "schedulerLatenessMs" to (firedAt - token.dueAtUptimeMs),
                    "causingRequestId" to token.requestId,
                ),
            )
            if (token.session != session.get() ||
                token.visibilityEpoch != visibilityEpoch.get() ||
                token.interactionEpoch != interactionEpoch.get() ||
                token.attachGeneration != overlayAttachGeneration ||
                token.wakeGeneration != wakeEpoch ||
                !FluviKeyguardCardServiceRegistry.connected
            ) return@Runnable
            // A terminal state observed by the retry is caused by this
            // callback, not by the timer's ideal due time. Lateness is
            // recorded separately above.
            if (hasCompatibleCycleInspection(token.requestId)) {
                traceKeyguard(
                    "RETRY_SUPPRESSED_FOR_PENDING",
                    "compatibleWork",
                    requestId = token.requestId,
                    observedUptimeMs = firedAt,
                    diagnosticContext = token.diagnosticContext,
                    fields = mapOf("retryId" to token.retryId, "retryIndex" to token.retryIndex),
                )
                return@Runnable
            }
            requestSystemCheck(
                "surfaceRetry",
                receivedAt = firedAt,
                evaluate = true,
                retry = true,
                freshness = token.windowFreshness,
                completedInspectionId = token.requestId,
            )
        }.also { mainHandler.postDelayed(it, delay) }
    }

    private fun cancelWakeRetry(reason: String = "superseded"): Boolean {
        val pending = retryRunnable ?: return false
        mainHandler.removeCallbacks(pending)
        retryRunnable = null
        retryToken?.let { token ->
            traceKeyguard(
                "RETRY_CANCELLED",
                reason,
                requestId = token.requestId,
                diagnosticContext = token.diagnosticContext,
                fields = mapOf(
                    "retryId" to token.retryId,
                    "retryIndex" to token.retryIndex,
                    "scheduledAtUptimeMs" to token.scheduledAtUptimeMs,
                    "dueAtUptimeMs" to token.dueAtUptimeMs,
                    "causingRequestId" to token.requestId,
                    "cancelReason" to reason,
                ),
            )
        }
        retryToken = null
        return true
    }

    /** Captures authority at request creation, not when a delayed worker gets
     * CPU. At most one Binder traversal and one latest follow-up can exist. */
    private fun scheduleEvaluation(
        trigger: String,
        eventTimeUptimeMs: Long? = null,
        triggerReceivedUptimeMs: Long? = null,
        freshness: KeyguardWindowFreshness = KeyguardWindowFreshness.FRAMEWORK_EVENT,
        reconciliationIntent: KeyguardCardInspectionRequest? = null,
    ) {
        if (!FluviKeyguardCardServiceRegistry.connected) return
        val now = SystemClock.uptimeMillis()
        val authority = inspectionAuthority
        val nextId = nextInspectionId.incrementAndGet()
        val request = if (reconciliationIntent != null) {
            reconciliationIntent.reacquireAfterWithdrawal(authority, nextId, now, freshness) ?: return
        } else KeyguardCardInspectionRequest(
            id = nextId,
            trigger = trigger,
            session = authority.serviceSession,
            visibilityEpoch = authority.visibilityEpoch,
            interactionEpoch = authority.interactionEpoch,
            attachGeneration = authority.attachGeneration,
            wakeGeneration = authority.wakeGeneration,
            queuedAtUptimeMs = now,
            windowFreshness = freshness,
            eventTimeUptimeMs = eventTimeUptimeMs,
            diagnosticContext = currentDiagnosticAttempt,
            triggerReceivedUptimeMs = triggerReceivedUptimeMs,
        )
        if (request.trigger != "surfaceRetry") cancelWakeRetry("supersededBy:${request.trigger}")
        inspectionFreshness.require(authority, request.windowFreshness)
        wakeTiming?.takeIf { it.wakeGeneration == request.wakeGeneration }?.let {
            if (it.inspectionQueuedAt == null) it.inspectionQueuedAt = now
            request.eventTimeUptimeMs?.takeIf { eventTime -> eventTime <= now }?.let { eventTime ->
                it.eventAgeMs = now - eventTime
            }
        }
        val queueOffer = synchronized(queueLock) {
            val replacedPending = inspectionQueue.pendingRequest()?.id
            val startsWorker = inspectionQueue.offer(request)
            if (inspectionQueue.pendingRequest() != null) {
                recordMaximum(maximumPendingInspections, 1)
            }
            startsWorker to replacedPending
        }
        traceKeyguard(
            if (queueOffer.first) "INSPECTION_QUEUED" else "INSPECTION_COALESCED",
            trigger,
            request,
            fields = mapOf(
                "queuedAtUptimeMs" to now,
                "triggerReceivedUptimeMs" to (request.triggerReceivedUptimeMs ?: "NA"),
                "eventTimeUptimeMs" to (request.eventTimeUptimeMs ?: "NA"),
                "replacedPendingRequestId" to (queueOffer.second ?: "NA"),
                "requestVisibilityEpoch" to request.visibilityEpoch,
                "requestInteractionEpoch" to request.interactionEpoch,
                "requestWakeGeneration" to request.wakeGeneration,
                "windowFreshness" to request.windowFreshness.name,
            ),
        )
        if (queueOffer.first) inspectionScope.launch { processInspectionQueue(request) }
    }

    private suspend fun processInspectionQueue(first: KeyguardCardInspectionRequest) {
        var request: KeyguardCardInspectionRequest? = first
        while (request != null) {
            val active = request
            val concurrent = activeInspectionCount.incrementAndGet()
            recordMaximum(maximumConcurrentInspections, concurrent)
            val startedAt = SystemClock.uptimeMillis()
            inspectionProbeForTest?.started(active)
            traceKeyguard(
                "INSPECTION_STARTED",
                active.trigger,
                active,
                observedUptimeMs = startedAt,
                fields = mapOf(
                    "queueMs" to (startedAt - active.queuedAtUptimeMs),
                    "queuedAtUptimeMs" to active.queuedAtUptimeMs,
                    "authorityCurrentAtStart" to authorityIsCurrent(active),
                ),
            )
            val result = inspectSurface(active)
            val finishedAt = SystemClock.uptimeMillis()
            activeInspectionCount.decrementAndGet()
            if (result.abortedStale) {
                mainHandler.post {
                    if (::overlay.isInitialized && overlay.isAttached) {
                        requestSystemCheck("abortedInspection:${active.id}")
                    }
                }
                // No main-thread delivery is necessary for a result which has
                // already lost authority.  Releasing this slot here lets the
                // one latest valid request begin immediately instead of
                // waiting behind a guaranteed stale rejection.
                val next = synchronized(queueLock) { inspectionQueue.complete(active) }
                traceInspectionResult(active, result, startedAt, finishedAt)
                traceKeyguard(
                    "INSPECTION_REJECTED",
                    "abortedStale",
                    active,
                    observedUptimeMs = finishedAt,
                    fields = mapOf("rejectionReason" to "abortedStale"),
                )
                request = next
            } else {
                // Full diagnostic reduction is deliberately outside this
                // handoff.  Nothing may run between the requested timestamp
                // and Dispatchers.Main so the resulting interval is honest.
                val diagnosticPreparationFinishedAt = SystemClock.uptimeMillis()
                val mainHandoffRequestedAt = SystemClock.uptimeMillis()
                withContext(Dispatchers.Main.immediate) {
                    val mainApplyEnteredAt = SystemClock.uptimeMillis()
                    inspectionProbeForTest?.beforeApply(active, result.decision)
                    applyInspection(
                        inspection = result,
                        request = active,
                        inspectionStartedAt = startedAt,
                        inspectionFinishedAt = finishedAt,
                        diagnosticPreparationFinishedAt = diagnosticPreparationFinishedAt,
                        mainHandoffRequestedAt = mainHandoffRequestedAt,
                        mainApplyEnteredAt = mainApplyEnteredAt,
                    )
                    inspectionProbeForTest?.afterApply(active, result.decision)
                }
                // The visibility operation has completed, so release the
                // serial reader slot. Capture reduction has its own bounded
                // consumer; this loop only enqueues references and proceeds
                // to the next acquisition without waiting for that consumer.
                val next = synchronized(queueLock) { inspectionQueue.complete(active) }
                traceInspectionResult(active, result, startedAt, finishedAt)
                traceKeyguard(
                    "INSPECTION_MAIN_APPLY_POSTED",
                    active.trigger,
                    active,
                    observedUptimeMs = mainHandoffRequestedAt,
                    fields = mapOf(
                        "inspectionFinishedAtUptimeMs" to finishedAt,
                        "diagnosticPreparationFinishedAtUptimeMs" to diagnosticPreparationFinishedAt,
                        "mainHandoffRequestedAtUptimeMs" to mainHandoffRequestedAt,
                    ),
                )
                request = next
            }
        }
    }

    /** Capture immutable results, build verbose fields on the diagnostic
     * consumer. No reduction/formatting runs ahead of the next tree walk. */
    private fun traceInspectionResult(
        request: KeyguardCardInspectionRequest,
        result: Inspection,
        startedAt: Long,
        finishedAt: Long,
    ) {
        if (!KeyguardCardDiagnostics.wantsEvent("INSPECTION_FINISHED")) return
        val abortedBefore = inspectionsAbortedBeforeRead.get()
        val abortedDuring = inspectionsAbortedDuringWalk.get()
        val readsAfter = nodeReadsAfterInvalidation.get()
        val fields = { mapOf(
            "queuedAtUptimeMs" to request.queuedAtUptimeMs,
            "startedAtUptimeMs" to startedAt,
            "triggerReceivedUptimeMs" to (request.triggerReceivedUptimeMs ?: "NA"),
            "eventTimeUptimeMs" to (request.eventTimeUptimeMs ?: "NA"),
            "requestVisibilityEpoch" to request.visibilityEpoch,
            "requestInteractionEpoch" to request.interactionEpoch,
            "requestWakeGeneration" to request.wakeGeneration,
            "inspectionTotalMs" to (finishedAt - startedAt),
            "windowsReadMs" to (result.windowsReadMs ?: "NA"),
            "treeScanMs" to (result.treeScanMs ?: "NA"),
            "windowCount" to result.windowCount,
            "visitedNodeCount" to result.visitedNodeCount,
            "rootUnavailable" to result.rootUnavailable,
            "walkTruncated" to result.walkTruncated,
            "getWindowsMs" to result.windowTiming.getWindowsMs,
            "relevantWindowCount" to result.windowTiming.relevantWindowCount,
            "rootAcquisitionCount" to result.windowTiming.rootAcquisitionCount,
            "rootAcquisitionTotalMs" to result.windowTiming.rootAcquisitionTotalMs,
            "rootAcquisitionMaxMs" to result.windowTiming.rootAcquisitionMaxMs,
            "readerStrategy" to result.windowTiming.readerStrategy,
            "prefetchFlags" to result.windowTiming.prefetchFlags,
            "cacheEnabled" to (result.windowTiming.cacheEnabled ?: "NA"),
            "freshnessPolicy" to result.windowTiming.freshnessPolicy,
            "cacheClearResult" to result.windowTiming.cacheClearResult,
            "activeCandidateWindowId" to (result.windowTiming.activeCandidateWindowId ?: "NA"),
            "returnedRootWindowId" to (result.windowTiming.returnedRootWindowId ?: "NA"),
            "activeRootAccepted" to result.windowTiming.activeRootAccepted,
            "fallbackReason" to (result.windowTiming.fallbackReason ?: "NA"),
            "activeRootCallCount" to result.windowTiming.activeRootCallCount,
            "activeRootTotalMs" to result.windowTiming.activeRootTotalMs,
            "perWindowRootCallCount" to result.windowTiming.rootAcquisitionCount,
            "perWindowRootTotalMs" to result.windowTiming.rootAcquisitionTotalMs,
            "childAcquisitionCount" to result.windowTiming.childAcquisitionCount,
            "childAcquisitionTotalMs" to result.windowTiming.childAcquisitionTotalMs,
            "childAcquisitionMaxMs" to result.windowTiming.childAcquisitionMaxMs,
            "localProcessingMs" to result.windowTiming.localProcessingMs,
            "slowWindowCalls" to result.windowTiming.slowCalls.joinToString(";"),
            "walkTruncationReasons" to result.windowTiming.walkTruncationReasons.joinToString(",").ifEmpty { "none" },
            "surfaceClassification" to result.decision.name,
            "surfaceMarkers" to result.surfaceMarkers,
            "abortedStale" to result.abortedStale,
            "inspectionsAbortedBeforeRead" to abortedBefore,
            "inspectionsAbortedDuringWalk" to abortedDuring,
            "nodeReadsAfterInvalidation" to readsAfter,
        ) }
        traceKeyguard("WINDOWS_READ_FINISHED", "apiCall", request, observedUptimeMs = finishedAt, deferredFields = fields)
        traceKeyguard("TREE_SCAN_FINISHED", "idOnly", request, observedUptimeMs = finishedAt, deferredFields = fields)
        traceKeyguard("INSPECTION_FINISHED", result.surfaceReason.name, request, observedUptimeMs = finishedAt, deferredFields = fields)
    }

    private data class Inspection(
        val signals: KeyguardCardSignals,
        val decision: KeyguardCardVisibility,
        val surfaceReason: KeyguardSurfaceReason,
        val surfaceMarkers: String = KeyguardSurfaceMarkers().compact(),
        val ownOverlayWindowId: Int? = null,
        val windowCount: Int = 0,
        val visitedNodeCount: Int = 0,
        val rootUnavailable: Boolean = false,
        val walkTruncated: Boolean = false,
        val windowsReadMs: Long? = null,
        val treeScanMs: Long? = null,
        val windowTiming: KeyguardWindowSnapshotReader.Timing = KeyguardWindowSnapshotReader.Timing(),
        val abortedStale: Boolean = false,
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
        val windowsReadMs: Long,
        val treeScanMs: Long,
        val visitedNodeCount: Int,
        val timing: KeyguardWindowSnapshotReader.Timing = KeyguardWindowSnapshotReader.Timing(),
        val abortedStale: Boolean = false,
    )

    /** Technical-only operation timing. It measures API call duration, not
     * presumed Binder cost: framework cache hits are intentionally possible. */
    private data class WindowReadTiming(
        val getWindowsMs: Long = 0L,
        val relevantWindowCount: Int = 0,
        val rootAcquisitionCount: Int = 0,
        val rootAcquisitionTotalMs: Long = 0L,
        val rootAcquisitionMaxMs: Long = 0L,
        val childAcquisitionCount: Int = 0,
        val childAcquisitionTotalMs: Long = 0L,
        val childAcquisitionMaxMs: Long = 0L,
        val localProcessingMs: Long = 0L,
        val slowCalls: List<String> = emptyList(),
    )

    private class WindowReadTimingAccumulator(private val getWindowsMs: Long) {
        var relevantWindows = 0
        var rootCount = 0
        var rootTotal = 0L
        var rootMax = 0L
        var childCount = 0
        var childTotal = 0L
        var childMax = 0L
        private val slow = mutableListOf<Pair<Long, String>>()

        fun root(window: AccessibilityWindowInfo, displayId: Int, elapsedMs: Long) {
            rootCount += 1; rootTotal += elapsedMs; rootMax = maxOf(rootMax, elapsedMs)
            slow += elapsedMs to "root:w=${window.id},t=${window.type},d=$displayId,$elapsedMs"
        }

        fun child(windowId: Int, index: Int, elapsedMs: Long) {
            childCount += 1; childTotal += elapsedMs; childMax = maxOf(childMax, elapsedMs)
            slow += elapsedMs to "child:w=$windowId,i=$index,$elapsedMs"
        }

        fun snapshot(treeElapsedMs: Long): KeyguardWindowSnapshotReader.Timing = KeyguardWindowSnapshotReader.Timing(
            getWindowsMs = getWindowsMs,
            relevantWindowCount = relevantWindows,
            rootAcquisitionCount = rootCount,
            rootAcquisitionTotalMs = rootTotal,
            rootAcquisitionMaxMs = rootMax,
            childAcquisitionCount = childCount,
            childAcquisitionTotalMs = childTotal,
            childAcquisitionMaxMs = childMax,
            localProcessingMs = (treeElapsedMs - rootTotal - childTotal).coerceAtLeast(0L),
            slowCalls = slow.sortedByDescending { it.first }.take(3).map { it.second },
        )
    }

    private data class VisibleIds(
        val ids: Set<String>,
        val truncated: Boolean,
        val visitedNodeCount: Int,
        val abortedStale: Boolean = false,
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
        if (!authorityIsCurrent(request)) {
            inspectionsAbortedBeforeRead.incrementAndGet()
            return Inspection(
                baseline,
                KeyguardCardVisibility.HIDDEN_UNKNOWN,
                KeyguardSurfaceReason.NO_WINDOWS,
                abortedStale = true,
            )
        }
        val read = readSystemWindows(request)
        if (read.abortedStale || !authorityIsCurrent(request)) {
            if (!read.abortedStale) inspectionsAbortedDuringWalk.incrementAndGet()
            return Inspection(
                baseline,
                KeyguardCardVisibility.HIDDEN_UNKNOWN,
                KeyguardSurfaceReason.NO_WINDOWS,
                windowCount = read.snapshots.size,
                visitedNodeCount = read.visitedNodeCount,
                rootUnavailable = read.rootUnavailable,
                walkTruncated = read.walkTruncated,
                windowsReadMs = read.windowsReadMs,
                treeScanMs = read.treeScanMs,
                windowTiming = read.timing,
                abortedStale = true,
            )
        }
        val classification = KeyguardSurfaceClassifier.classifyDetailed(
            inspectionProbeForTest?.snapshots(request, read.snapshots) ?: read.snapshots,
            unavailableRoot = read.rootUnavailable,
            walkTruncated = read.walkTruncated,
        )
        val signals = quickSignals(settings, classification.surface)
        return Inspection(
            signals,
            KeyguardCardVisibilityPolicy.decide(signals),
            classification.reason,
            classification.markers.compact(),
            read.snapshots.firstOrNull { it.ownOverlay }?.windowId?.takeIf { it >= 0 },
            windowCount = read.snapshots.size,
            visitedNodeCount = read.visitedNodeCount,
            rootUnavailable = read.rootUnavailable,
            walkTruncated = read.walkTruncated,
            windowsReadMs = read.windowsReadMs,
            treeScanMs = read.treeScanMs,
            windowTiming = read.timing,
        )
    }

    private fun quickSignals(settings: KeyguardCardSettings, surface: KeyguardSurface): KeyguardCardSignals {
        val state = readSystemState(KeyguardSystemReadPurpose.INSPECTION)
        return signalsFromSystemState(settings, surface, state)
    }

    private fun signalsFromSystemState(settings: KeyguardCardSettings, surface: KeyguardSurface, state: KeyguardSystemState): KeyguardCardSignals {
        return KeyguardCardSignals(
            requested = settings.requested,
            serviceConnected = FluviKeyguardCardServiceRegistry.connected,
            userUnlocked = state.available && state.userUnlocked,
            primaryDisplay = state.available && state.primaryDisplay,
            interactive = state.available && state.interactive,
            displayOn = state.available && state.displayOn,
            keyguardLocked = state.available && state.keyguardLocked,
            surface = surface,
            showFinancialDetails = settings.showFinancialDetails,
            systemStateAvailable = state.available,
            displayOff = state.displayOff,
        )
    }

    private fun readSystemWindows(request: KeyguardCardInspectionRequest): SystemWindowsRead {
        // Resolve the outstanding requirement at acquisition, not when an
        // event happened to replace a timer/pending request. A successful
        // boundary is consumed once, without clearing on every later event.
        val freshness = inspectionFreshness.beforeRead(request)
        val result = windowSnapshotReader.read(
            request = KeyguardWindowSnapshotReader.Request(
                knownOwn = knownOwnOverlayIdentity,
                attachGeneration = request.attachGeneration,
                freshness = freshness?.reason ?: KeyguardWindowFreshness.FRAMEWORK_EVENT,
            ),
            authorityIsCurrent = { freshness != null && authorityIsCurrent(request) },
            onFreshnessEstablished = { freshness?.let(inspectionFreshness::boundaryEstablished) },
        )
        if (result.abortedStale) inspectionsAbortedDuringWalk.incrementAndGet()
        if (result.nodeReadsAfterInvalidation > 0) {
            nodeReadsAfterInvalidation.addAndGet(result.nodeReadsAfterInvalidation.toLong())
        }
        return SystemWindowsRead(
            snapshots = result.snapshots,
            rootUnavailable = result.rootUnavailable,
            walkTruncated = result.walkTruncated,
            windowsReadMs = result.windowsReadMs,
            treeScanMs = result.treeScanMs,
            visitedNodeCount = result.visitedNodeCount,
            timing = result.timing,
            abortedStale = result.abortedStale,
        )
    }

    /** Kept temporarily as a narrow, testable reference while the API-33
     * reader owns production acquisition.  It is never called by production
     * classification; uncertain active-root reads fall back inside the reader
     * before a surface decision is made. */
    @Suppress("unused")
    private fun readSystemWindowsLegacy(request: KeyguardCardInspectionRequest): SystemWindowsRead = runCatching {
        if (!authorityIsCurrent(request)) {
            inspectionsAbortedBeforeRead.incrementAndGet()
            return@runCatching SystemWindowsRead(
                emptyList(), rootUnavailable = false, walkTruncated = false,
                windowsReadMs = 0L, treeScanMs = 0L, visitedNodeCount = 0, abortedStale = true,
            )
        }
        val readStartedAt = SystemClock.uptimeMillis()
        val currentWindows = windows
        val windowsReadMs = SystemClock.uptimeMillis() - readStartedAt
        val treeStartedAt = SystemClock.uptimeMillis()
        val timing = WindowReadTimingAccumulator(windowsReadMs)
        var unavailableRoot = false
        var walkTruncated = false
        var visitedNodeCount = 0
        val knownOwn = knownOwnOverlayIdentity
        val snapshots = mutableListOf<KeyguardWindowSnapshot>()
        for (window in currentWindows) {
            if (!authorityIsCurrent(request)) {
                inspectionsAbortedDuringWalk.incrementAndGet()
                return@runCatching SystemWindowsRead(
                    snapshots, unavailableRoot, walkTruncated, windowsReadMs,
                    SystemClock.uptimeMillis() - treeStartedAt, visitedNodeCount, abortedStale = true,
                )
            }
            val displayId = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) window.displayId else Display.DEFAULT_DISPLAY
            // Secondary displays cannot decide this default-display overlay's
            // eligibility, so do not pay a root Binder call for them.
            if (displayId != Display.DEFAULT_DISPLAY) continue
            timing.relevantWindows += 1
            val exactKnownOwn = knownOwn != null && knownOwn.windowId == window.id &&
                knownOwn.displayId == displayId && knownOwn.attachGeneration == request.attachGeneration &&
                window.type == AccessibilityWindowInfo.TYPE_ACCESSIBILITY_OVERLAY
            if (exactKnownOwn) {
                snapshots += KeyguardWindowSnapshot(
                    windowId = window.id,
                    packageName = packageName,
                    type = window.type,
                    layer = window.layer,
                    displayId = displayId,
                    ownOverlay = true,
                    visibleViewIds = emptySet(),
                )
                continue
            }
            if (!authorityIsCurrent(request)) {
                inspectionsAbortedDuringWalk.incrementAndGet()
                return@runCatching SystemWindowsRead(
                    snapshots, unavailableRoot, walkTruncated, windowsReadMs,
                    SystemClock.uptimeMillis() - treeStartedAt, visitedNodeCount, abortedStale = true,
                )
            }
            val rootStartedAt = SystemClock.uptimeMillis()
            val root = runCatching { window.root }.getOrNull()
            timing.root(window, displayId, SystemClock.uptimeMillis() - rootStartedAt)
            if (!authorityIsCurrent(request)) {
                root?.recycle()
                inspectionsAbortedDuringWalk.incrementAndGet()
                return@runCatching SystemWindowsRead(
                    snapshots, unavailableRoot, walkTruncated, windowsReadMs,
                    SystemClock.uptimeMillis() - treeStartedAt, visitedNodeCount, abortedStale = true,
                )
            }
            if (root == null) unavailableRoot = true
            val rootPackage = root?.packageName?.toString()
            val own = rootPackage == this.packageName && window.type == AccessibilityWindowInfo.TYPE_ACCESSIBILITY_OVERLAY
            val ids = if (rootPackage in setOf("com.android.systemui", "com.android.keyguard", "android")) {
                root?.let { visibleResourceIds(it, request, window.id, timing) }?.also {
                    walkTruncated = walkTruncated || it.truncated
                    visitedNodeCount += it.visitedNodeCount
                    if (it.abortedStale) {
                        root.recycle()
                        inspectionsAbortedDuringWalk.incrementAndGet()
                        return@runCatching SystemWindowsRead(
                            snapshots, unavailableRoot, walkTruncated, windowsReadMs,
                            SystemClock.uptimeMillis() - treeStartedAt, visitedNodeCount, abortedStale = true,
                        )
                    }
                }?.ids.orEmpty()
            } else {
                emptySet()
            }
            root?.recycle()
            snapshots += KeyguardWindowSnapshot(
                windowId = window.id,
                packageName = rootPackage,
                type = window.type,
                layer = window.layer,
                displayId = displayId,
                ownOverlay = own,
                visibleViewIds = ids,
            )
        }
        val treeElapsedMs = SystemClock.uptimeMillis() - treeStartedAt
        SystemWindowsRead(snapshots, unavailableRoot, walkTruncated, windowsReadMs, treeElapsedMs, visitedNodeCount, timing.snapshot(treeElapsedMs))
    }.getOrDefault(SystemWindowsRead(emptyList(), rootUnavailable = false, walkTruncated = false, windowsReadMs = 0L, treeScanMs = 0L, visitedNodeCount = 0))

    /** Bounded, ID-only traversal. Never read node.text, event.text,
     * contentDescription, input values, screenshots, or foreign app trees. */
    private fun visibleResourceIds(
        root: AccessibilityNodeInfo,
        request: KeyguardCardInspectionRequest,
        windowId: Int,
        timing: WindowReadTimingAccumulator,
    ): VisibleIds {
        val ids = linkedSetOf<String>()
        var visited = 0
        var truncated = false
        var abortedStale = false
        fun visit(node: AccessibilityNodeInfo?) {
            if (node == null) return
            if (!authorityIsCurrent(request)) {
                abortedStale = true
                return
            }
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
                    if (!authorityIsCurrent(request)) {
                        abortedStale = true
                        return
                    }
                    val childStartedAt = SystemClock.uptimeMillis()
                    val child = node.getChild(index)
                    timing.child(windowId, index, SystemClock.uptimeMillis() - childStartedAt)
                    if (!authorityIsCurrent(request)) {
                        nodeReadsAfterInvalidation.incrementAndGet()
                        child?.recycle()
                        abortedStale = true
                        return
                    }
                    visit(child)
                    child?.recycle()
                    if (abortedStale) return
                }
            } catch (_: Exception) {
                // A stale node produces UNKNOWN rather than an unsafe show.
            }
        }
        visit(root)
        return VisibleIds(ids, truncated, visited, abortedStale)
    }

    private fun applyInspection(
        inspection: Inspection,
        request: KeyguardCardInspectionRequest,
        inspectionStartedAt: Long,
        inspectionFinishedAt: Long,
        diagnosticPreparationFinishedAt: Long,
        mainHandoffRequestedAt: Long,
        mainApplyEnteredAt: Long,
    ) {
        withMainWorkEvidence(KeyguardMainWorkEvidence.INSPECTION_APPLY, request.id) {
        var decisionObservedAt: Long? = null
        try {
        wakeTiming?.takeIf { it.wakeGeneration == request.wakeGeneration }?.apply {
            this.inspectionStartedAt = inspectionStartedAt
            this.inspectionFinishedAt = inspectionFinishedAt
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
            // Unknown acquisition/transition is not a fabricated terminal
            // exclusion. The surface policy below withdraws it nonterminally.
            displayEligibleNow = !inspection.signals.systemStateAvailable ||
                (inspection.signals.interactive && !inspection.signals.displayOff),
            keyguardLockedNow = !inspection.signals.systemStateAvailable || inspection.signals.keyguardLocked,
        )) {
            KeyguardInspectionAction.DROP_STALE -> {
                // Reject the old surface answer, but independently acquire a
                // CURRENT exclusion check. It cannot hide using old authority.
                requestSystemCheck("staleInspection:${request.id}")
                wakeTiming?.takeIf { it.wakeGeneration == request.wakeGeneration }?.let {
                    it.rejectedLateResults += 1
                }
                KeyguardCardDiagnostics.record(this, "KG|INSPECTION_STALE", "surfaceEpoch", overlay.isAttached)
                traceKeyguard("INSPECTION_REJECTED", "stale", request, fields = mapOf("rejectionReason" to "surfaceEpoch"))
                return
            }
            KeyguardInspectionAction.HIDE_CURRENT_GATE -> {
                hideImmediately(
                    "currentGate",
                    triggerReceivedUptimeMs = request.triggerReceivedUptimeMs,
                    diagnosticContext = request.diagnosticContext,
                    causingInspectionRequestId = request.id,
                )
                return
            }
            KeyguardInspectionAction.APPLY -> Unit
        }
        // Recording a window id is also a mutation of current overlay state,
        // so it belongs behind all session/epoch/attach checks.
        inspection.ownOverlayWindowId?.let { windowId ->
            overlay.recordAccessibilityWindowId(windowId, request.attachGeneration)
            if (overlay.isAttached && request.attachGeneration == overlayAttachGeneration) {
                knownOwnOverlayIdentity = KeyguardOwnOverlayIdentity(
                    windowId = windowId,
                    displayId = Display.DEFAULT_DISPLAY,
                    attachGeneration = overlayAttachGeneration,
                )
            }
        }
        val settings = lastSettings ?: FluviKeyguardCardSettings.read(applicationContext)
        var signals = inspection.signals.copy(requested = settings.requested,
            serviceConnected = FluviKeyguardCardServiceRegistry.connected,
            showFinancialDetails = settings.showFinancialDetails)
        var decision = KeyguardCardVisibilityPolicy.decide(signals)
        if (KeyguardSystemAdmission.requiresFreshRead(overlay.isAttached, appliedDecision, decision)) {
            // The only inspection-apply Main acquisition: actual admission or
            // disclosure increase. One snapshot feeds all final system gates.
            val admission = readSystemState(KeyguardSystemReadPurpose.ADMISSION)
            signals = signalsFromSystemState(settings, signals.surface, admission)
            decision = KeyguardCardVisibilityPolicy.decide(signals)
        }
        decisionObservedAt = SystemClock.uptimeMillis()
        appliedDecision = decision
        when (decision) {
            KeyguardCardVisibility.SHOW_DISCREET -> {
                retryCount = 0
                cancelWakeRetry("shown")
                wakeTiming?.takeIf { it.wakeGeneration == request.wakeGeneration }?.mainKeyguardConfirmedAt = SystemClock.uptimeMillis()
                stopFinancialObservation()
                showEvent = false
                applyPresentation(
                    FluviFinancialCardPresenter.discreet(),
                    "discreet:${request.trigger}",
                    diagnosticContext = request.diagnosticContext,
                    causingInspectionRequestId = request.id,
                )
            }
            KeyguardCardVisibility.SHOW_FULL -> {
                retryCount = 0
                cancelWakeRetry("shown")
                wakeTiming?.takeIf { it.wakeGeneration == request.wakeGeneration }?.mainKeyguardConfirmedAt = SystemClock.uptimeMillis()
                val focus = (lastSettings ?: FluviKeyguardCardSettings.read(applicationContext)).focus
                showFullContent(
                    request.session,
                    request.visibilityEpoch,
                    focus.generation,
                    request.trigger,
                    request.diagnosticContext,
                    request.id,
                )
            }
            else -> {
                if (decision == KeyguardCardVisibility.HIDDEN_UNKNOWN || decision == KeyguardCardVisibility.HIDDEN_OCCLUDED) {
                    handleRecoverableSurface(inspection, request, decision)
                } else {
                    hideImmediately(
                        decision.name,
                        triggerReceivedUptimeMs = request.triggerReceivedUptimeMs,
                        diagnosticContext = request.diagnosticContext,
                        causingInspectionRequestId = request.id,
                    )
                }
            }
        }
        // Detail is deliberately published only after show/hide/awaiting
        // work.  The original decision timestamp remains attached.
        KeyguardCardDiagnostics.record(this, "KG|SURFACE_DECISION", "${decision.name}:${inspection.surfaceReason.name}", overlay.isAttached)
        traceKeyguard(
            "INSPECTION_APPLIED",
            inspection.surfaceReason.name,
            request,
            observedUptimeMs = decisionObservedAt,
            fields = mapOf(
                "decision" to decision.name,
                "surfaceClassification" to inspection.surfaceReason.name,
                "surfaceMarkers" to inspection.surfaceMarkers,
                "systemStateAvailable" to signals.systemStateAvailable,
                "visibilityEpochAtApply" to visibilityEpoch.get(),
                "pendingRequestIdAtApply" to (synchronized(queueLock) { inspectionQueue.pendingRequest()?.id } ?: "NA"),
            ),
        )
        } finally {
            traceKeyguard(
                "INSPECTION_MAIN_APPLY_STARTED",
                request.trigger,
                request,
                observedUptimeMs = mainApplyEnteredAt,
                fields = mapOf(
                    "inspectionFinishedAtUptimeMs" to inspectionFinishedAt,
                    "diagnosticPreparationFinishedAtUptimeMs" to diagnosticPreparationFinishedAt,
                    "mainHandoffRequestedAtUptimeMs" to mainHandoffRequestedAt,
                    "mainApplyEnteredAtUptimeMs" to mainApplyEnteredAt,
                    "inspectionFinishToHandoffMs" to (mainHandoffRequestedAt - inspectionFinishedAt),
                    "handoffToMainEntryMs" to (mainApplyEnteredAt - mainHandoffRequestedAt),
                    "mainEntryToDecisionMs" to (decisionObservedAt?.let { it - mainApplyEnteredAt } ?: "NA"),
                ),
            )
        }
        }
    }

    /**
     * UNKNOWN and OCCLUDED exclude presentation without proving that the
     * physical wake ended. A detached observation must not invalidate newer
     * work. Real withdrawal revokes the old answer, then reacquires the intent.
     */
    private fun handleRecoverableSurface(
        inspection: Inspection,
        request: KeyguardCardInspectionRequest,
        decision: KeyguardCardVisibility,
    ) {
        val compatiblePending = synchronized(queueLock) {
            inspectionQueue.pendingRequest()?.takeIf(inspectionAuthority::matches)
        }
        val hadCompatiblePending = compatiblePending != null
        // This is only the timer budget. Eligibility is sampled when the
        // fallback fires, independently of local withdrawal and tree work.
        val retryAvailable = retryCount < RETRY_DELAYS_MS.size
        val wasAttached = overlay.isAttached
        val awaitingReason = if (decision == KeyguardCardVisibility.HIDDEN_OCCLUDED) "occluded" else "unknown"
        // A missing/incomplete tree needs one deliberate freshness boundary
        // before a timer retry. A normal event-driven NO_MAIN observation does
        // not: the framework already invalidated the cache for that event.
        // Withdrawing a currently visible presentation is contradictory
        // evidence and therefore also receives a fresh successor.
        val successorFreshness = when {
            wasAttached -> KeyguardWindowFreshness.CONTRADICTORY_OBSERVATION
            inspection.rootUnavailable || inspection.walkTruncated ->
                KeyguardWindowFreshness.MISSING_FRESHNESS_EVIDENCE
            else -> KeyguardWindowFreshness.FRAMEWORK_EVENT
        }
        val beforeVisibilityEpoch = visibilityEpoch.get()
        val transition = KeyguardAwaitingSurfacePolicy.onUnknown(
            current = surfacePresentationState,
            overlayAttached = wasAttached,
            hasCompatiblePendingRequest = hadCompatiblePending,
            retryAvailable = retryAvailable,
        )
        surfacePresentationState = transition.nextState
        if (transition.withdrawVisibleOverlay) {
            hideImmediately(
                reason = "${decision.name}:${inspection.surfaceReason.name}",
                terminalWake = false,
                triggerReceivedUptimeMs = request.triggerReceivedUptimeMs,
                diagnosticContext = request.diagnosticContext,
                causingInspectionRequestId = request.id,
                awaitingSurfaceWithdrawal = true,
            )
        }
        traceKeyguard(
            "AWAITING_MAIN_SURFACE",
            inspection.surfaceReason.name,
            request,
            fields = mapOf(
                "decision" to decision.name,
                "overlayAttached" to wasAttached,
                "presentationState" to transition.nextState.name,
                "followupAction" to transition.followup.name,
                "pendingRequestId" to (compatiblePending?.id ?: "NA"),
                "visibilityEpochBefore" to beforeVisibilityEpoch,
                // The detached branch deliberately leaves authority alone.
                "visibilityEpochAfter" to visibilityEpoch.get(),
            ),
        )

        if (transition.withdrawVisibleOverlay) {
            // Withdrawal changed authority. Record the obligation under the
            // new authority even when the retry budget is exhausted.
            inspectionFreshness.require(inspectionAuthority, successorFreshness)
            when (transition.followup) {
                KeyguardUnknownSurfaceFollowup.CONTINUE_PENDING -> {
                    // The queued request was captured under the withdrawn
                    // generation. Replace it exactly once under current
                    // authority; never relabel its old answer as fresh.
                    if (decision == KeyguardCardVisibility.HIDDEN_UNKNOWN) traceKeyguard(
                        "PENDING_REPLACED_AFTER_UNKNOWN",
                        "withdrawalAuthorityChanged",
                        requestId = compatiblePending?.id,
                        diagnosticContext = request.diagnosticContext,
                        fields = mapOf("causingRequestId" to request.id),
                    )
                    val intent = checkNotNull(compatiblePending)
                    freshReconciliationsScheduled.incrementAndGet()
                    scheduleEvaluation(
                        intent.trigger,
                        freshness = successorFreshness,
                        reconciliationIntent = intent,
                    )
                }
                KeyguardUnknownSurfaceFollowup.SCHEDULE_FALLBACK ->
                    scheduleWakeRetry(request, successorFreshness, awaitingReason)
                KeyguardUnknownSurfaceFollowup.WAIT_FOR_EVENT -> traceKeyguard(
                    "RETRY_BUDGET_EXHAUSTED_AWAITING",
                    "${awaitingReason}Visible",
                    request,
                )
            }
            return
        }

        // Already hidden: do not call hideImmediately. A compatible pending
        // request has the same authority and can run as soon as this active
        // request completes. The active cause itself never counts as future
        // work here.
        inspectionFreshness.require(inspectionAuthority, successorFreshness)
        when (transition.followup) {
            KeyguardUnknownSurfaceFollowup.CONTINUE_PENDING -> traceKeyguard(
                "RETRY_SUPPRESSED_FOR_PENDING",
                "${awaitingReason}AlreadyHidden",
                request,
            )
            KeyguardUnknownSurfaceFollowup.SCHEDULE_FALLBACK ->
                scheduleWakeRetry(request, successorFreshness, awaitingReason)
            KeyguardUnknownSurfaceFollowup.WAIT_FOR_EVENT -> traceKeyguard(
                "RETRY_BUDGET_EXHAUSTED_AWAITING",
                "${awaitingReason}AlreadyHidden",
                request,
            )
        }
    }

    private fun showFullContent(
        expectedSession: Long,
        expectedEpoch: Long,
        focusGeneration: Long,
        trigger: String,
        diagnosticContext: KeyguardDiagnosticContext?,
        causingInspectionRequestId: Long?,
    ) {
        val focusChanged = activeFocusGeneration != focusGeneration
        if (focusChanged) {
            showEvent = false
            invalidateFullContent()
            activeFocusGeneration = focusGeneration
        }
        terminalContentFailure?.takeIf { it.first == focusGeneration }?.let { (_, code) ->
            applyPresentation(FluviFinancialCardPresenter.unavailable(code), "invalidFocus:$trigger", diagnosticContext, causingInspectionRequestId)
            return
        }
        transientContentFailure?.takeIf { it.first == focusGeneration }?.let { (_, code) ->
            applyPresentation(FluviFinancialCardPresenter.unavailable(code), "contentUnavailable:$trigger", diagnosticContext, causingInspectionRequestId)
            return
        }
        val cached = renderedFullContent
        val plan = KeyguardCardContentRefreshPolicy.firstOrSurfacePlan(
            focusChanged = focusChanged,
            hasCurrentContent = cached != null && !focusChanged,
            resolveInFlightForFocus = resolvingFocusGeneration == focusGeneration,
        )
        if (cached != null && !focusChanged) {
            applyPresentation(FluviFinancialCardPresenter.full(cached, showEvent), "cached:$trigger", diagnosticContext, causingInspectionRequestId)
        } else if (plan.publishLoading) {
            // First full render only. Repeated same-surface inspection keeps
            // the current amount or existing loading presentation untouched.
            applyPresentation(FluviFinancialCardPresenter.loading(), "loading:$trigger", diagnosticContext, causingInspectionRequestId)
        }
        beginFinancialObservation(
            expectedSession,
            expectedEpoch,
            focusGeneration,
            diagnosticContext,
            causingInspectionRequestId,
        )
        if (plan.startResolve) {
            resolveFullContent(expectedSession, expectedEpoch, focusGeneration, "first", diagnosticContext, causingInspectionRequestId)
        }
    }

    private fun beginFinancialObservation(
        expectedSession: Long,
        expectedEpoch: Long,
        focusGeneration: Long,
        diagnosticContext: KeyguardDiagnosticContext?,
        causingInspectionRequestId: Long?,
    ) {
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
                        resolveFullContent(expectedSession, expectedEpoch, focusGeneration, "coreRevision", diagnosticContext, causingInspectionRequestId)
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
        diagnosticContext: KeyguardDiagnosticContext?,
        causingInspectionRequestId: Long?,
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
                    val ownsPublication = KeyguardCardContentPublicationPolicy.canApply(
                        KeyguardCardContentPublication(
                            requestSession = expectedSession,
                            currentSession = session.get(),
                            requestEpoch = expectedEpoch,
                            currentEpoch = visibilityEpoch.get(),
                            requestFocusGeneration = focusGeneration,
                            currentFocusGeneration = (lastSettings ?: FluviKeyguardCardSettings.read(applicationContext)).focus.generation,
                            currentlyFull = appliedDecision == KeyguardCardVisibility.SHOW_FULL,
                            detailsStillAllowed = settings.showFinancialDetails,
                            displayStillEligible = true,
                        ),
                    )
                    // A rejected financial result needs no remote read. A
                    // genuine new publication still receives its fresh guard.
                    val publicationState = if (ownsPublication) readSystemState(KeyguardSystemReadPurpose.PUBLICATION) else null
                    if (publicationState?.excluded == true) hideImmediately("publicationGate")
                    val stillCurrent = ownsPublication && publicationState?.eligible == true
                    val content = (outcome as? FullContentResolveResult.Ready)?.content
                    if (!stillCurrent || content == null) {
                        if (stillCurrent && outcome is FullContentResolveResult.InvalidFocus) {
                            terminalContentFailure = focusGeneration to outcome.diagnosticCode
                            applyPresentation(
                                FluviFinancialCardPresenter.unavailable(outcome.diagnosticCode),
                                "invalidFocus:${outcome.diagnosticCode}",
                                diagnosticContext,
                                causingInspectionRequestId,
                            )
                        } else if (stillCurrent && outcome is FullContentResolveResult.Failure) {
                            transientContentFailure = focusGeneration to outcome.diagnosticCode
                            applyPresentation(
                                FluviFinancialCardPresenter.unavailable(outcome.diagnosticCode),
                                "contentUnavailable:${outcome.diagnosticCode}",
                                diagnosticContext,
                                causingInspectionRequestId,
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
                        applyPresentation(FluviFinancialCardPresenter.full(content, showEvent), "content", diagnosticContext, causingInspectionRequestId)
                        KeyguardCardDiagnostics.record(this@FluviKeyguardCardService, "KG|CONTENT_APPLIED", "full", overlay.isAttached)
                    }
                } finally {
                    val rerun = resolveQueued && activeFocusGeneration == focusGeneration
                    resolveQueued = false
                    resolvingFocusGeneration = null
                    contentJob = null
                    if (rerun) resolveFullContent(expectedSession, expectedEpoch, focusGeneration, "coalescedRevision", diagnosticContext, causingInspectionRequestId)
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

    private fun applyPresentation(
        presentation: com.fluvi.app.runtime.FluviFinancialCardPresentation,
        reason: String,
        diagnosticContext: KeyguardDiagnosticContext? = currentDiagnosticAttempt,
        causingInspectionRequestId: Long? = null,
    ) {
        val settings = lastSettings ?: FluviKeyguardCardSettings.read(applicationContext).also { lastSettings = it }
        // `showOrUpdate` applies material only after a real content/layout
        // mutation (or attach). A repeated MAIN_CONFIRMED must not push the
        // same scene through the renderer before it can be called NO_OP.
        wakeTiming?.takeIf { it.wakeGeneration == wakeEpoch && it.attachRequestedAt == null }?.attachRequestedAt =
            SystemClock.uptimeMillis()
        val showOperation = if (!overlay.isAttached) {
            KeyguardCardDiagnostics.newShowOperation(
                context = diagnosticContext,
                attachGeneration = overlayAttachGeneration + 1L,
                causingInspectionRequestId = causingInspectionRequestId,
            )
        } else null
        val showDecisionAt = SystemClock.uptimeMillis()
        activeWindowDiagnosticOperation = showOperation
        val result = try {
            overlay.showOrUpdate(presentation, settings)
        } finally {
            activeWindowDiagnosticOperation = null
        }
        // The operation ID is allocated before attachment, but all capture
        // processing follows WindowManager.addView/showOrUpdate.
        if (showOperation != null) {
            traceKeyguard(
                "SHOW_FOR_ATTACH",
                reason,
                requestId = causingInspectionRequestId,
                attachGeneration = overlayAttachGeneration + 1L,
                observedUptimeMs = showDecisionAt,
                diagnosticContext = diagnosticContext,
                operation = showOperation,
                fields = mapOf(
                    "presentationMode" to settings.presentationMode.name,
                    "rootWasPrepared" to overlay.hasPreparedRoot,
                    "profileWasDecoded" to (lastMaterialProfile != null),
                ),
            )
            val material = overlay.materialDiagnostics()
            traceKeyguard(
                "SHOW_ATTACH_RENDER_INPUT",
                reason,
                requestId = causingInspectionRequestId,
                attachGeneration = overlayAttachGeneration + 1L,
                diagnosticContext = diagnosticContext,
                operation = showOperation,
                fields = mapOf(
                    "hardwareAccelerated" to (material?.hardwareAccelerated ?: "NA"),
                    "rendererBackend" to (material?.activeRenderer ?: "NA"),
                ),
            )
        }
        when (result) {
            KeyguardCardWindow.Result.ATTACHED -> {
                overlayAttachGeneration = overlay.currentAttachGeneration
                surfacePresentationState = KeyguardSurfacePresentationState.VISIBLE
                knownOwnOverlayIdentity = null
                publishInspectionAuthority()
                preservePendingReconciliation("attach", requirePending = true)
                firstDrawOwner = KeyguardFirstDrawOwner(
                    session = session.get(),
                    wakeGeneration = wakeEpoch,
                    attachGeneration = overlayAttachGeneration,
                    diagnosticOperation = showOperation,
                )
                wakeTiming?.draws?.attach(requireNotNull(firstDrawOwner).identity)
                KeyguardCardDiagnostics.attach(this, "attached")
                KeyguardCardDiagnostics.record(this, "KG|ATTACH", reason, true)
                traceKeyguard(
                    "ATTACH_CONFIRMED",
                    reason,
                    requestId = causingInspectionRequestId,
                    attachGeneration = overlayAttachGeneration,
                    diagnosticContext = diagnosticContext,
                    operation = showOperation,
                )
                publishWakeTiming("attached")
            }
            KeyguardCardWindow.Result.CONTENT_UPDATED,
            KeyguardCardWindow.Result.REDACTED -> {
                if (overlay.isAttached) surfacePresentationState = KeyguardSurfacePresentationState.VISIBLE
                KeyguardCardDiagnostics.record(this, "KG|CONTENT_UPDATE", "$reason:${result.name}", true)
                traceKeyguard("CONTENT_UPDATED", reason, requestId = causingInspectionRequestId, diagnosticContext = diagnosticContext)
            }
            KeyguardCardWindow.Result.LAYOUT_UPDATED -> {
                if (overlay.isAttached) surfacePresentationState = KeyguardSurfacePresentationState.VISIBLE
                KeyguardCardDiagnostics.record(this, "KG|LAYOUT_UPDATE", reason, true)
            }
            KeyguardCardWindow.Result.NO_OP -> {
                if (overlay.isAttached) surfacePresentationState = KeyguardSurfacePresentationState.VISIBLE
                traceKeyguard("SURFACE_RECONFIRMED", reason, requestId = causingInspectionRequestId, diagnosticContext = diagnosticContext)
            }
            KeyguardCardWindow.Result.FAILED -> {
                surfacePresentationState = KeyguardSurfacePresentationState.AWAITING_MAIN_SURFACE
                KeyguardCardDiagnostics.attach(this, "failed")
                KeyguardCardDiagnostics.record(this, "KG|ATTACH_FAILED", "window", false)
                traceKeyguard(
                    "ATTACH_FAILED",
                    "window",
                    requestId = causingInspectionRequestId,
                    attachGeneration = overlayAttachGeneration + 1L,
                    diagnosticContext = diagnosticContext,
                    operation = showOperation,
                )
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
    private fun hideImmediately(
        reason: String,
        terminalWake: Boolean = true,
        awaitingSurfaceWithdrawal: Boolean = false,
        triggerReceivedUptimeMs: Long? = null,
        diagnosticContext: KeyguardDiagnosticContext? = currentDiagnosticAttempt,
        causingInspectionRequestId: Long? = null,
    ) {
        val wasAttachedBefore = ::overlay.isInitialized && overlay.isAttached
        // Also revoke checks created since an already-idempotent terminal
        // cleanup. This does not wait for their platform calls to return.
        if (terminalWake) systemSampler.clearPending()
        if (!KeyguardTerminalHideGate.shouldProcess(
                terminalWake = terminalWake,
                overlayAttached = wasAttachedBefore,
                serviceSession = session.get(),
                visibilityEpoch = visibilityEpoch.get(),
                previous = terminalHideState,
            )
        ) {
            // The first terminal transition already invalidated all attach
            // authority. Repeating it would only churn epochs, diagnostics and
            // material cleanup while the root is known detached.
            KeyguardCardDiagnostics.recordHiddenNoop(this)
            return
        }
        val exclusionAt = SystemClock.uptimeMillis()
        val hideOperation = KeyguardCardDiagnostics.newHideOperation(
            context = diagnosticContext,
            attachGeneration = overlayAttachGeneration.takeIf { it > 0 },
            causingInspectionRequestId = causingInspectionRequestId,
            triggerReceivedUptimeMs = triggerReceivedUptimeMs,
        )
        val invalidatedVisibilityEpoch = visibilityEpoch.incrementAndGet()
        interactionEpoch.incrementAndGet()
        // Invalidate publication before the retained root can be detached.
        // Its already-posted observer cleanup remains responsible for removing
        // only its own listener after the framework draw traversal ends.
        firstDrawOwner = null
        wakeTiming?.draws?.detach()
        if (terminalWake) {
            // A later SCREEN_ON must allocate a new physical cycle. A visible
            // surface change inside the same wake does not pass this path.
            wakeCycleOwner.end()
            wakeEpoch += 1L
            cancelWakeRetry("terminalHide")
            synchronized(queueLock) { inspectionQueue.clearPending() }
        }
        knownOwnOverlayIdentity = null
        publishInspectionAuthority(renewSystemWork = !terminalWake)
        surfacePresentationState = if (terminalWake) {
            KeyguardSurfacePresentationState.TERMINALLY_EXCLUDED
        } else {
            KeyguardSurfacePresentationState.WITHDRAWN_AWAITING_SURFACE
        }
        appliedDecision = KeyguardCardVisibility.HIDDEN_UNKNOWN
        showEvent = false
        val dragWasActive = ::overlay.isInitialized && overlay.isDragActive
        var removeReturnedAt: Long? = null
        var localHideBeginAt: Long? = null
        if (::overlay.isInitialized) {
            localHideBeginAt = SystemClock.uptimeMillis()
            activeWindowDiagnosticOperation = hideOperation
            val removed = try {
                overlay.hide()
            } finally {
                activeWindowDiagnosticOperation = null
            }
            removeReturnedAt = SystemClock.uptimeMillis()
            if (wasAttachedBefore && KeyguardCardDiagnostics.wantsEvent("ATTACHMENT_RENDER_SUMMARY")) {
                val summary = overlay.attachmentRenderSummary()
                if (summary != null) traceKeyguard(
                    "ATTACHMENT_RENDER_SUMMARY", "withdrawalBoundary",
                    requestId = causingInspectionRequestId,
                    observedUptimeMs = removeReturnedAt,
                    operation = hideOperation,
                    deferredFields = { mapOf(
                        "clockCallbacks" to summary.clockCallbacks,
                        "isolatedFramesProduced" to summary.isolatedFramesProduced,
                        "isolatedFramesPublished" to summary.isolatedFramesPublished,
                        "isolatedFramesDropped" to summary.isolatedFramesDropped,
                        "isolatedCompletionGapMaxMs" to summary.isolatedCompletionGapMaxMs,
                        "shaderFrames" to summary.orb.frames,
                        "shaderCalls" to summary.shaderCalls,
                        "phaseAdvances" to summary.phaseAdvances,
                        "firstPhase" to (summary.orb.firstPhase ?: "NA"),
                        "lastPhase" to (summary.orb.lastPhase ?: "NA"),
                        "firstShaderTraversalAt" to (summary.orb.firstAt ?: "NA"),
                        "lastShaderTraversalAt" to (summary.orb.lastAt ?: "NA"),
                        "drawGapCount" to summary.orb.gaps,
                        "drawGapTotalMs" to summary.orb.gapTotalMs,
                        "drawGapMaxMs" to summary.orb.gapMaxMs,
                        "drawInvalidOrder" to summary.orb.invalidOrder,
                        "backgroundFrames" to summary.background.frames,
                        "animationStarts" to summary.animationStarts,
                        "animationStops" to summary.animationStops,
                        "clockRunning" to summary.clockRunning,
                        "liveState" to summary.liveState,
                        "drawEvidenceMode" to "cpuSubmissionNotPresentation",
                        "drawEvidenceOmitted" to (summary.orbGaps.omittedGaps + summary.backgroundGaps.omittedGaps),
                        "drawObserverNs" to (summary.orbGaps.observerNs + summary.backgroundGaps.observerNs),
                        "drawObservedFrames" to summary.orbGaps.observedDraws,
                        "drawUnpairedFrames" to summary.orbGaps.unpairedDraws,
                        "drawCoalescedCallbacks" to summary.orbGaps.coalescedCallbacks,
                        "drawEvidenceBreaks" to summary.orbGaps.samplingBreaks,
                        "drawEvidenceRejected" to summary.orbGaps.rejected,
                        "orbDrawGaps" to summary.orbGaps.compact(),
                        "backgroundDrawGaps" to summary.backgroundGaps.compact(),
                    ) },
                )
            }
            if (wasAttachedBefore && removed) KeyguardCardDiagnostics.record(this, "KG|DETACH", reason, false)
            if (!wasAttachedBefore) traceKeyguard(
                "HIDE_NOOP_ALREADY_HIDDEN",
                reason,
                requestId = causingInspectionRequestId,
                observedUptimeMs = removeReturnedAt,
                diagnosticContext = diagnosticContext,
                operation = hideOperation,
            )
            // A failed remove still leaves meaningful terminal cleanup to a
            // later exclusion signal; do not install the idempotent guard.
            if (terminalWake && (!wasAttachedBefore || removed || !overlay.isAttached)) {
                terminalHideState = KeyguardTerminalHideState(session.get(), invalidatedVisibilityEpoch)
            }
        }
        // Visibility and removal have already run.  Publish the exact
        // timestamps afterwards so recording cannot delay the critical path.
        traceKeyguard(
            "HIDE_DECIDED",
            reason,
            requestId = causingInspectionRequestId,
            observedUptimeMs = exclusionAt,
            attachGeneration = overlayAttachGeneration.takeIf { it > 0 },
            diagnosticContext = diagnosticContext,
            operation = hideOperation,
            fields = mapOf(
                "triggerReceivedUptimeMs" to (triggerReceivedUptimeMs ?: "NA"),
                "terminalWake" to terminalWake,
                "awaitingSurfaceWithdrawal" to awaitingSurfaceWithdrawal,
                "visibilityEpochBefore" to (invalidatedVisibilityEpoch - 1L),
            ),
        )
        localHideBeginAt?.let { localHideAt ->
            traceKeyguard(
                "LOCAL_HIDE_BEGIN",
                reason,
                requestId = causingInspectionRequestId,
                observedUptimeMs = localHideAt,
                attachGeneration = overlayAttachGeneration.takeIf { it > 0 },
                diagnosticContext = diagnosticContext,
                operation = hideOperation,
                fields = mapOf(
                    "attachedBefore" to wasAttachedBefore,
                    "dragActive" to dragWasActive,
                    "awaitingSurfaceWithdrawal" to awaitingSurfaceWithdrawal,
                ),
            )
        }
        // Window visibility is already withdrawn; only now cancel potentially
        // blocking work and persist the compact diagnostic summary.
        stopFinancialObservation()
        KeyguardCardDiagnostics.record(
            this,
            "KG|HIDE_TIMING",
            "source=$reason|exclusionToHideRequestMs=" +
                (triggerReceivedUptimeMs?.let { exclusionAt - it } ?: -1L) +
                "|exclusionToRemoveReturnMs=" +
                (removeReturnedAt?.minus(exclusionAt) ?: -1L) +
                "|cancelledWakeJobs=${if (terminalWake) 1 else 0}|dragWasActive=$dragWasActive|rollbackLayoutCallsDuringHide=0",
            false,
        )
        traceKeyguard(
            "HIDE_COMPLETED",
            reason,
            requestId = causingInspectionRequestId,
            observedUptimeMs = removeReturnedAt ?: SystemClock.uptimeMillis(),
            diagnosticContext = diagnosticContext,
            operation = hideOperation,
            fields = mapOf(
                "signalToDecisionMs" to (triggerReceivedUptimeMs?.let { exclusionAt - it } ?: "NA"),
                "signalToRemoveReturnMs" to (triggerReceivedUptimeMs?.let { signal -> removeReturnedAt?.minus(signal) } ?: "NA"),
                "attachedAfter" to (::overlay.isInitialized && overlay.isAttached),
                "dragActive" to dragWasActive,
            ),
        )
    }

    /** Both callbacks arrive after their draw stacks have unwound. The event
     * still carries its original attach id, so a wake A callback cannot write
     * timing into wake B after a fast lock/unlock/reattach sequence. */
    private fun recordFirstRootDraw(event: KeyguardFirstDrawEvent) {
        val owner = firstDrawOwner ?: return
        if (!owner.accepts(event, session.get(), wakeEpoch, overlayAttachGeneration)) return
        val timing = wakeTiming?.takeIf { it.wakeGeneration == owner.wakeGeneration } ?: return
        timing.draws.record(owner.identity, KeyguardDrawPublication.Stage.ROOT, event.observedAtUptimeMs) {
            KeyguardCardDiagnostics.recordColdPreparation(session.get(), "FIRST_ROOT_DRAW", event.observedAtUptimeMs)
            traceKeyguard(
                "FIRST_ROOT_DRAW",
                "observed",
                attachGeneration = event.attachGeneration,
                observedUptimeMs = event.observedAtUptimeMs,
                operation = owner.diagnosticOperation,
            )
            publishWakeTiming("firstRootDraw")
        }
    }

    private fun recordFirstShaderDraw(event: KeyguardFirstDrawEvent) {
        val owner = firstDrawOwner ?: return
        if (!owner.accepts(event, session.get(), wakeEpoch, overlayAttachGeneration)) return
        val timing = wakeTiming?.takeIf { it.wakeGeneration == owner.wakeGeneration } ?: return
        timing.draws.record(owner.identity, KeyguardDrawPublication.Stage.SHADER, event.observedAtUptimeMs) {
            KeyguardCardDiagnostics.recordColdPreparation(session.get(), "FIRST_SHADER_DRAW", event.observedAtUptimeMs)
            KeyguardCardDiagnostics.recordColdPreparation(session.get(), "FIRST_CURRENT_MATERIAL_DRAW", event.observedAtUptimeMs)
            KeyguardCardDiagnostics.recordColdPreparation(session.get(), "FIRST_LIVE_DRAW", event.observedAtUptimeMs)
            traceKeyguard(
                "FIRST_SHADER_DRAW",
                "observed",
                attachGeneration = event.attachGeneration,
                observedUptimeMs = event.observedAtUptimeMs,
                operation = owner.diagnosticOperation,
            )
            traceKeyguard(
                "FIRST_CURRENT_MATERIAL_DRAW",
                "observed",
                attachGeneration = event.attachGeneration,
                observedUptimeMs = event.observedAtUptimeMs,
                operation = owner.diagnosticOperation,
            )
            traceKeyguard(
                "FIRST_LIVE_DRAW",
                "observed",
                attachGeneration = event.attachGeneration,
                observedUptimeMs = event.observedAtUptimeMs,
                operation = owner.diagnosticOperation,
            )
            publishWakeTiming("firstShaderDraw")
        }
    }

    private fun recordBootstrapDraw(event: KeyguardFirstDrawEvent) {
        val owner = firstDrawOwner ?: return
        if (!owner.accepts(event, session.get(), wakeEpoch, overlayAttachGeneration)) return
        KeyguardCardDiagnostics.recordColdPreparation(session.get(), "BOOTSTRAP_DRAW", event.observedAtUptimeMs)
        traceKeyguard(
            "BOOTSTRAP_DRAW",
            "paletteFallbackNotPhysicalPresentation",
            attachGeneration = event.attachGeneration,
            observedUptimeMs = event.observedAtUptimeMs,
            operation = owner.diagnosticOperation,
        )
    }

    private fun recordBootstrapCommit(event: KeyguardFirstDrawEvent) {
        val owner = firstDrawOwner ?: return
        if (!owner.accepts(event, session.get(), wakeEpoch, overlayAttachGeneration)) return
        KeyguardCardDiagnostics.recordColdPreparation(
            session.get(),
            "BOOTSTRAP_COMMIT_CALLBACK_RECEIVED",
            event.observedAtUptimeMs,
        )
        traceKeyguard(
            "BOOTSTRAP_COMMIT_CALLBACK_RECEIVED",
            "rendererCommittedNotPhysicalPresentation",
            attachGeneration = event.attachGeneration,
            observedUptimeMs = event.observedAtUptimeMs,
            operation = owner.diagnosticOperation,
        )
    }

    private fun recordLivePromotion(event: KeyguardFirstDrawEvent) {
        val owner = firstDrawOwner ?: return
        if (!owner.accepts(event, session.get(), wakeEpoch, overlayAttachGeneration)) return
        KeyguardCardDiagnostics.recordColdPreparation(session.get(), "MATERIAL_LIVE_PROMOTED", event.observedAtUptimeMs)
        traceKeyguard(
            "MATERIAL_LIVE_PROMOTED",
            "sameRetainedAttachment",
            attachGeneration = event.attachGeneration,
            observedUptimeMs = event.observedAtUptimeMs,
            operation = owner.diagnosticOperation,
        )
    }

    /** Frame commit is closer to renderer completion than Canvas.onDraw, but
     * is still not a physical-display presentation timestamp. */
    private fun recordFirstFrameCommit(event: KeyguardFirstDrawEvent) {
        val owner = firstDrawOwner ?: return
        if (!owner.accepts(event, session.get(), wakeEpoch, overlayAttachGeneration)) return
        KeyguardCardDiagnostics.recordColdPreparation(
            session.get(),
            "FRAME_COMMIT_CALLBACK_RECEIVED",
            event.observedAtUptimeMs,
        )
        traceKeyguard(
            "FRAME_COMMIT_CALLBACK_RECEIVED",
            "rendererCommittedNotPhysicalPresentation",
            attachGeneration = event.attachGeneration,
            observedUptimeMs = event.observedAtUptimeMs,
            operation = owner.diagnosticOperation,
        )
    }

    private fun publishWakeTiming(stage: String) {
        val timing = wakeTiming ?: return
        val queue = timing.inspectionStartedAt?.minus(timing.inspectionQueuedAt ?: timing.inspectionStartedAt ?: 0L)
        val inspect = timing.inspectionFinishedAt?.minus(timing.inspectionStartedAt ?: timing.inspectionFinishedAt ?: 0L)
        val confirmedToAttach = timing.attachRequestedAt?.minus(timing.mainKeyguardConfirmedAt ?: timing.attachRequestedAt ?: 0L)
        val attachToDraw = timing.draws.firstRootAt?.minus(timing.addViewReturnedAt ?: timing.draws.firstRootAt ?: 0L)
        val callbackToDraw = timing.draws.firstRootAt?.minus(timing.wakeReceivedAt)
        KeyguardCardDiagnostics.record(
            this,
            "KG|WAKE_TIMING",
            "stage=$stage|wake=${timing.wakeGeneration}|eventAgeMs=${timing.eventAgeMs ?: -1L}|inspectionQueueMs=${queue ?: -1L}|" +
                "inspectionDurationMs=${inspect ?: -1L}|confirmedToAttachMs=${confirmedToAttach ?: -1L}|" +
                "attachToFirstDrawMs=${attachToDraw ?: -1L}|callbackToFirstDrawMs=${callbackToDraw ?: -1L}|" +
                "firstShaderDrawAt=${timing.draws.firstShaderAt ?: -1L}|" +
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
            "overlayAttached" to (::overlay.isInitialized && overlay.isAttached),
            "appliedVisibility" to appliedDecision.name,
            "systemRecurringReads" to systemReads.get(KeyguardSystemReadPurpose.RECURRING.ordinal),
            "systemRecurringMainReads" to mainSystemReads.get(KeyguardSystemReadPurpose.RECURRING.ordinal),
            "systemAdmissionMainReads" to mainSystemReads.get(KeyguardSystemReadPurpose.ADMISSION.ordinal),
            "systemPublicationMainReads" to mainSystemReads.get(KeyguardSystemReadPurpose.PUBLICATION.ordinal),
            "systemSamplerMaximumActive" to systemSampler.maximumActive,
            "systemSamplerMaximumPending" to systemSampler.maximumPending,
            "systemSamplerStaleRejected" to systemSampler.rejected,
            // `rendererBackend` remains for older Flutter diagnostics; the
            // requested/active pair tells whether AGSL actually compiled and
            // drew instead of merely being available on this API level.
            "rendererBackend" to values?.activeRenderer,
            "requestedRenderer" to values?.requestedRenderer,
            "activeRenderer" to values?.activeRenderer,
            "hardwareAccelerated" to (values?.hardwareAccelerated ?: false),
            "shaderCreationCount" to (values?.shaderCreationCount ?: 0),
            "shaderPreparationRequests" to (values?.preparationRequests ?: 0),
            "shaderPreparationCompletions" to (values?.preparationCompletions ?: 0),
            "shaderPreparationFailures" to (values?.preparationFailures ?: 0),
            "gpuPreparationRequests" to (values?.gpuPreparationRequests ?: 0),
            "gpuPreparationCompletions" to (values?.gpuPreparationCompletions ?: 0),
            "gpuPreparationFailures" to (values?.gpuPreparationFailures ?: 0),
            "coldPresentationState" to values?.coldPresentationState,
            "shaderArtifactLoadCount" to (values?.artifactLoadCount ?: 0),
            "shaderArtifactMetadataParseCount" to (values?.artifactMetadataParseCount ?: 0),
            "animationStartCount" to (values?.animationStartCount ?: 0),
            "animationStopCount" to (values?.animationStopCount ?: 0),
            "drawCount" to (values?.frameCallbackCount ?: 0),
            "frameCallbackCount" to (values?.frameCallbackCount ?: 0),
            // The standalone API-34 ORB uses its renderer-thread
            // Choreographer, so its actual completed/published buffer counts
            // must not be represented as ViewRoot callbacks.
            "isolatedOrbFramesProduced" to (values?.isolatedFramesProduced ?: 0),
            "isolatedOrbFramesPublished" to (values?.isolatedFramesPublished ?: 0),
            "isolatedOrbFramesDropped" to (values?.isolatedFramesDropped ?: 0),
            "isolatedOrbFramesInFlight" to (values?.isolatedFramesInFlight ?: 0),
            "isolatedOrbFramesReady" to (values?.isolatedFramesReady ?: 0),
            "isolatedOrbFramesCompositorOwned" to (values?.isolatedFramesCompositorOwned ?: 0),
            "isolatedOrbWorkerRunning" to (values?.isolatedWorkerRunning ?: false),
            "isolatedOrbWorkerDesiredAttachment" to (values?.isolatedWorkerDesiredAttachment ?: -1L),
            "isolatedOrbWorkerDesiredGeneration" to (values?.isolatedWorkerDesiredGeneration ?: -1L),
            "isolatedOrbWorkerAttachedAttachment" to (values?.isolatedWorkerAttachedAttachment ?: -1L),
            "isolatedOrbWorkerAttachedGeneration" to (values?.isolatedWorkerAttachedGeneration ?: -1L),
            "isolatedOrbCompletionGapMaxMs" to (values?.isolatedCompletionGapMaxMs ?: 0L),
            "frameIntervalP50" to (values?.frameIntervalP50 ?: 0),
            "frameIntervalP95" to (values?.frameIntervalP95 ?: 0),
            "largeFrameGapCount" to (values?.largeFrameGapCount ?: 0),
            "materialConfigurationUpdateCount" to (values?.configurationUpdateCount ?: 0),
            "materialConfigurationNoOpCount" to (values?.configurationNoOpCount ?: 0),
            "lastRendererFailure" to values?.rendererFailure,
            "shaderCompileAttempts" to ((values?.orb?.shaderCompileAttempts ?: 0) + (values?.background?.shaderCompileAttempts ?: 0)),
            "shaderCompileSuccesses" to ((values?.orb?.shaderCompileSuccesses ?: 0) + (values?.background?.shaderCompileSuccesses ?: 0)),
            "shaderCompileFailures" to ((values?.orb?.shaderCompileFailures ?: 0) + (values?.background?.shaderCompileFailures ?: 0)),
            "onDrawCount" to ((values?.orb?.onDrawCount ?: 0) + (values?.background?.onDrawCount ?: 0)),
            "shaderDrawCount" to ((values?.orb?.shaderDrawCount ?: 0) + (values?.background?.shaderDrawCount ?: 0)),
            "bootstrapDrawCount" to ((values?.orb?.bootstrapDrawCount ?: 0) + (values?.background?.bootstrapDrawCount ?: 0)),
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
        publishInspectionAuthority()
        showEvent = false
        appliedDecision = KeyguardCardVisibility.SHOW_DISCREET
        if (::overlay.isInitialized && overlay.isAttached) {
            applyPresentation(FluviFinancialCardPresenter.discreet(), "redact:$reason")
        }
        stopFinancialObservation()
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

    private fun cleanup(reason: String) {
        traceKeyguard(if (reason == "destroy") "SERVICE_DESTROYED" else "SERVICE_UNBOUND", reason)
        hideImmediately(reason)
        systemSampler.dispose()
        // No join/await: an in-flight framework call may finish later. Its
        // disposed result cannot mutate this service's root or authority.
        systemGateExecutor.shutdown()
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
