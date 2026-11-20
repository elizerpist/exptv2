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
import com.fluvi.app.lockscreen.material.KeyguardOrbRetirementEvent
import com.fluvi.app.lockscreen.material.FluviKeyguardMaterialStore
import com.fluvi.app.lockscreen.material.KeyguardMaterialProfile
import com.fluvi.app.lockscreen.material.KeyguardOrbOwnershipSlotSnapshot
import com.fluvi.app.lockscreen.material.KeyguardOrbColdWorkSnapshot
import com.fluvi.app.lockscreen.material.KeyguardOrbFirstOfferObservation
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.async
import kotlinx.coroutines.cancel
import kotlinx.coroutines.coroutineScope
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

    internal fun renderModeStatus(): KeyguardOrbRenderModeStatus {
        check(Looper.myLooper() == Looper.getMainLooper())
        val configured = KeyguardOrbRenderModeStore.read(applicationContext)
        return if (::overlay.isInitialized) overlay.renderModeStatus()
        else KeyguardOrbRenderModeStatus(configured, configured, visible = false)
    }

    /** Bounded test observation of the current authorized target. The
     * service and the Window remain the only owners of display authority. */
    internal fun surfaceMetricsForInstrumentation() =
        if (::overlay.isInitialized) overlay.surfaceMetricsForTest() else null

    /** A selector changes no active presentation. Detached preparation may
     * use the new choice before the next independently authorized show. */
    internal fun onOrbRenderModeChanged() {
        check(Looper.myLooper() == Looper.getMainLooper())
        if (r18Active != null) sealR18(inspectionAuthority, Long.MAX_VALUE, "routeChanged")
        synchronized(queueLock) { firstAcquisition.invalidate() }
        publishReadAheadState(invalidate = true)
        clearR14Recovery("routeChanged")
        val hadR18 = r18Active != null
        if (hadR18) hideImmediately("r18RouteChanged", terminalWake = false)
        if (::overlay.isInitialized && !overlay.isAttached) {
            overlay.prepareRetainedView(lastSettings ?: FluviKeyguardCardSettings.read(applicationContext), lastMaterialProfile)
        }
        refreshR18RouteOnMain()
        if (hadR18) requestSystemCheck("r18RouteChanged", evaluate = true)
    }
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
        reserveBeforeMain = ::reserveR18WakeBeforeMain,
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
    private val firstAcquisition = KeyguardFirstAcquisition()
    // Main publishes eligibility; the sampler can reserve only a successor
    // of that exact authority under the inspection queue lock. A reservation
    // is a reader/host preparation opportunity, not an admission to show.
    private data class R18ProvisionalWake(
        val sampleId: Long,
        val previousAuthority: KeyguardInspectionAuthority,
        val targetAuthority: KeyguardInspectionAuthority,
        val routeRevision: Long,
        val firstRequestId: Long,
        val receivedAt: Long,
        val reservedAt: Long,
        val source: String,
        val token: KeyguardOrbPresentationCoordinator.Reservation,
        val preparation: KeyguardCardWindow.R18Preparation,
        @Volatile var diagnosticContext: KeyguardDiagnosticContext? = null,
    )
    @Volatile private var r18ProvisionalWake: R18ProvisionalWake? = null
    @Volatile private var r18RouteEnabled = false
    @Volatile private var r18WakeOpen = false
    private var r18RouteRevision = 0L // queueLock
    private var r18AdoptedSampleId: Long? = null // Main
    private data class R18RouteSnapshot(val preparation: KeyguardCardWindow.R18Preparation,
        val settingsRevision: Long, val materialRevision: Long, val dataRevision: Long, val layoutRevision: Long)
    private data class R18Identity(val token: KeyguardOrbPresentationCoordinator.Reservation,
        val preparation: KeyguardCardWindow.R18Preparation)
    private class R18Active(token: KeyguardOrbPresentationCoordinator.Reservation,
                            preparation: KeyguardCardWindow.R18Preparation,
                            val diagnosticContext: KeyguardDiagnosticContext?) {
        @Volatile var identity = R18Identity(token, preparation)
        val token get() = identity.token
        val preparation get() = identity.preparation
        @Volatile var host: android.view.View? = null
        var hostReady = false
        var hostWindowId: Int? = null
        var binding = false
        var bound = false
        @Volatile var output: Any? = null
    }
    private class R18DrainBinding(val token: KeyguardOrbPresentationCoordinator.Reservation,
        val diagnosticContext: KeyguardDiagnosticContext?, val attachment: Long, val generation: Long, val output: Any) {
        var drained = false // queueLock; retained for a possible late receipt
    }
    private val r18Coordinator = KeyguardOrbPresentationCoordinator(queueLock)
    private val r18DrainBindings = arrayOfNulls<R18DrainBinding>(2) // queueLock
    private var r18RouteSnapshot: R18RouteSnapshot? = null // queueLock
    private var r18NextHostGeneration = 0L // queueLock
    @Volatile private var r18Active: R18Active? = null
    private var r18FallbackWake: Long? = null // Main
    private var r18ProofRequestId: Long? = null // Main, current complete inspection only
    // Main-owned diagnostic observation only. It never grants visibility or
    // initiates another system read, and carries its own original authority.
    private var latestSamplerEvidence: KeyguardSamplerEvidence? = null
    // Published only by Main, guarded by the same lock as reservation. The
    // reader may consume this immutable snapshot but cannot change a View.
    private var readAheadStateRevision = 0L
    private var readAheadShowInProgress = false
    private var readAheadSnapshot: KeyguardReadAheadSnapshot? = null
    private val nextInspectionId = AtomicLong(0L)
    private var nextR14IngressId = 0L
    private var nextR14RecoveryId = 0L
    /** Main owns the one-use, authority-qualified token; it never owns a View. */
    private var r14Recovery: KeyguardR14Recovery? = null
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
        synchronized(queueLock) {
            if (inspectionAuthority != current) {
                readAheadStateRevision += 1L
                val early = r18ProvisionalWake
                val adopting = early != null && early.previousAuthority == inspectionAuthority &&
                    early.targetAuthority == current && early.routeRevision == r18RouteRevision
                if (!adopting) {
                    cancelR18ReservationLocked()
                    firstAcquisition.invalidate()
                }
            }
            inspectionFreshness.publish(current)
            inspectionAuthority = current
            publishReadAheadSnapshotLocked()
        }
        if (renewSystemWork) systemSampler.renewPending { old ->
            old.copy(id = ++nextSystemGateId, authority = current, queuedAt = SystemClock.uptimeMillis())
        }
    }

    /** Main owns the sampled fields. Lock ordering is queue then freshness;
     * neither lock is held across a Binder call or a Main handoff. */
    private fun publishReadAheadSnapshotLocked() {
        val freshness = inspectionFreshness.revisionFor(inspectionAuthority)
        readAheadSnapshot = freshness?.let {
            KeyguardReadAheadSnapshot(
                authority = inspectionAuthority,
                freshnessRevision = it,
                stateRevision = readAheadStateRevision,
                detached = ::overlay.isInitialized && !overlay.isAttached,
                showInProgress = readAheadShowInProgress,
                surfaceState = surfacePresentationState,
            )
        }
    }

    private fun publishReadAheadState(invalidate: Boolean = false) {
        synchronized(queueLock) {
            if (invalidate) {
                readAheadStateRevision += 1L
                r18RouteRevision += 1L
                cancelR18ReservationLocked()
                firstAcquisition.invalidate()
            }
            publishReadAheadSnapshotLocked()
        }
    }

    private fun setReadAheadShowInProgress(value: Boolean) {
        synchronized(queueLock) {
            readAheadStateRevision += 1L
            readAheadShowInProgress = value
            publishReadAheadSnapshotLocked()
        }
    }

    private fun readAheadStillCurrent(snapshot: KeyguardReadAheadSnapshot): Boolean =
        synchronized(queueLock) {
            readAheadSnapshot == snapshot && inspectionAuthority == snapshot.authority &&
                inspectionFreshness.revisionFor(snapshot.authority) == snapshot.freshnessRevision
        }

    private fun authorityIsCurrent(request: KeyguardCardInspectionRequest): Boolean {
        val published = inspectionAuthority
        val provisional = r18ProvisionalWake
        return if (provisional != null && published == provisional.previousAuthority) {
            provisional.targetAuthority.matches(request)
        } else published.matches(request)
    }

    /** Caller holds queueLock; platform and View operations are forbidden. */
    private fun cancelR18ReservationLocked() {
        val early = r18ProvisionalWake ?: return
        r18ProvisionalWake = null
        r18Coordinator.seal(early.token, early.targetAuthority, early.firstRequestId, true)
        r18Coordinator.retired(early.token)
        if (inspectionAuthority == early.previousAuthority) inspectionFreshness.publish(inspectionAuthority)
        firstAcquisition.invalidate()
    }

    /** Called on Main only, outside queueLock. This publishes scalar route
     * eligibility for a later worker sample; it performs no screen admission. */
    private fun refreshR18RouteOnMain() {
        val settings = lastSettings
        val profile = lastMaterialProfile
        val eligible = Build.VERSION.SDK_INT == 35 && settings != null && profile != null &&
            ::overlay.isInitialized && overlay.preparedInitialLiveOrb(settings, profile)
        val preparation = if (eligible) overlay.r18Preparation() ?: overlay.prepareR18() else null
        val next = if (preparation != null && settings != null && profile != null &&
            settings.generation >= 0 && profile.publisherRevision >= 0 && settings.focus.generation >= 0) {
            R18RouteSnapshot(preparation, settings.generation, profile.publisherRevision,
                settings.focus.generation, settings.layoutRevision)
        } else null
        synchronized(queueLock) {
            if (r18RouteSnapshot != next) {
                r18RouteSnapshot = next
                r18RouteEnabled = next != null
                r18RouteRevision += 1L
                cancelR18ReservationLocked()
            }
        }
    }

    /** Called on the system sampler, never Main. The queue still has exactly
     * one physical reader. Main must adopt this exact next-wake authority
     * before the result can affect a View or a financial subscription. */
    private fun reserveR18WakeBeforeMain(
        sample: KeyguardSystemGateRequest, state: KeyguardSystemState,
    ): (() -> Unit)? {
        if (state.excluded) {
            sealR18(sample.authority, Long.MAX_VALUE, "systemSample")
            return null
        }
        if (!state.eligible || !sample.evaluate || sample.wakeSource == null ||
            !FluviKeyguardCardServiceRegistry.connected || lastSettings?.requested != true) return null
        val queuedAt = SystemClock.uptimeMillis()
        val requestId = nextInspectionId.incrementAndGet()
        val early = synchronized(queueLock) {
            val route = r18RouteSnapshot ?: return@synchronized null
            if (!r18RouteEnabled || r18WakeOpen || r18ProvisionalWake != null ||
                inspectionAuthority != sample.authority) return@synchronized null
            val target = sample.authority.copy(wakeGeneration = sample.authority.wakeGeneration + 1)
            val prep = route.preparation
            val stamp = KeyguardOrbPresentationStamp(target, requestId, r18RouteRevision,
                route.materialRevision, route.dataRevision, prep.width, prep.height, prep.densityDpi,
                prep.full, ++r18NextHostGeneration, prep.outputGeneration, Display.DEFAULT_DISPLAY)
            val token = r18Coordinator.reserve(stamp, sample.id, sample.authority, inspectionAuthority,
                sampleEligible = true, routeEligible = true) ?: return@synchronized null
            R18ProvisionalWake(sample.id, sample.authority, target, r18RouteRevision, requestId,
                sample.evaluationReceivedAt, queuedAt, sample.wakeSource, token, prep).also { r18ProvisionalWake = it }
        } ?: return null
        // Diagnostic allocation is outside the queue/authority lock and keeps
        // its original wake identity. A cancelled reservation is not a grant.
        val capture = sample.diagnosticCaptureId
        if (capture != null && capture == KeyguardCardDiagnostics.activeCaptureId()) {
            early.diagnosticContext = runCatching {
                KeyguardCardDiagnostics.beginLockAttempt(this, early.targetAuthority.serviceSession,
                    early.targetAuthority.wakeGeneration, early.source, early.receivedAt)
            }.getOrNull()
        }
        val authority = early.targetAuthority
        val request = KeyguardCardInspectionRequest(
            id = early.firstRequestId, trigger = sample.evaluationReason,
            session = authority.serviceSession, visibilityEpoch = authority.visibilityEpoch,
            interactionEpoch = authority.interactionEpoch, attachGeneration = authority.attachGeneration,
            wakeGeneration = authority.wakeGeneration, queuedAtUptimeMs = queuedAt,
            windowFreshness = KeyguardWindowFreshness.LIFECYCLE_BOUNDARY,
            eventTimeUptimeMs = sample.eventTime, diagnosticContext = early.diagnosticContext,
            triggerReceivedUptimeMs = sample.evaluationReceivedAt,
        )
        val offer = synchronized(queueLock) {
            if (r18ProvisionalWake !== early || inspectionAuthority != early.previousAuthority ||
                r18WakeOpen || !r18RouteEnabled || r18RouteRevision != early.routeRevision) {
                if (r18ProvisionalWake === early) cancelR18ReservationLocked()
                return@synchronized null
            }
            inspectionFreshness.publish(authority)
            inspectionFreshness.require(authority, KeyguardWindowFreshness.LIFECYCLE_BOUNDARY)
            firstAcquisition.begin(authority, preparedLiveOrb = true)
            inspectionQueue.offer(request)
        } ?: return null
        return {
            // A cancellation after posting Main cannot relabel this work.
            // An offered active item must run even if cancelled in the gap;
            // its stale-read branch drains the single-owner queue.
            if (offer) inspectionScope.launch { processInspectionQueue(request) }
        }
    }

    /** Immutable capture ownership is carried even when receipt delivery is
     * later than withdrawal or another wake. The reducer applies its capture
     * token/freeze gate before retaining this bounded boundary observation. */
    private fun recordR18(owner: R18Active, phase: String, observedAt: Long = SystemClock.uptimeMillis(),
                          proof: Long? = null, sample: KeyguardSystemState? = null, reservedAt: Long? = null) {
        val context = owner.diagnosticContext ?: return
        if (context.captureId == null || !KeyguardCardDiagnostics.wantsEvent("R18_PIPELINE")) return
        val identity = owner.identity
        val token = identity.token
        val prep = identity.preparation
        val child = (owner.output as? com.fluvi.app.lockscreen.material.KeyguardOrbDirectOutput)?.childId
        val nsBefore = System.nanoTime()
        val alignedUptime = SystemClock.uptimeMillis()
        val nsAfter = System.nanoTime()
        KeyguardCardDiagnostics.captureEvent(this, "R18_PIPELINE", phase,
            serviceSession = token.stamp.authority.serviceSession, wakeEpoch = token.stamp.authority.wakeGeneration,
            requestId = proof ?: token.stamp.firstRequestId, attachGeneration = prep.attachment,
            observedUptimeMs = observedAt, diagnosticContext = context,
            deferredFields = { mapOf("r18Host" to token.stamp.hostGeneration, "r18Output" to prep.outputGeneration,
                "r18Child" to (child ?: "UNOBSERVED"), "r18Privacy" to if (prep.full) "full" else "discreet",
                "r18Phase" to phase, "r18Proof" to (proof ?: "UNOBSERVED"),
                "r18SampleStart" to (sample?.startedAt ?: "UNOBSERVED"),
                "r18SampleEnd" to (sample?.finishedAt ?: "UNOBSERVED"),
                "r18Reservation" to (reservedAt ?: "UNOBSERVED"),
                "r18AlignUptime" to alignedUptime, "r18AlignNano" to (nsBefore + (nsAfter - nsBefore) / 2),
                "r18AlignUncertaintyNs" to ((nsAfter - nsBefore) / 2 + 1_000_000L)) })
    }

    private fun startR18Stage(token: KeyguardOrbPresentationCoordinator.Reservation,
                              prep: KeyguardCardWindow.R18Preparation, settings: KeyguardCardSettings,
                              context: KeyguardDiagnosticContext?, sample: KeyguardSystemState? = null,
                              reservedAt: Long? = null) {
        val owner = R18Active(token, prep, context)
        r18Active = owner
        recordR18(owner, "WAKE_ADOPTED", sample = sample, reservedAt = reservedAt)
        recordR18(owner, "HOST_ADD_BEGIN")
        if (!overlay.stageR18Host(token.stamp.hostGeneration, settings)) {
            failR18Stage(owner, "hostStageFailed"); return
        }
        val host = overlay.stagedR18Host(token.stamp.hostGeneration)
        if (host == null || !r18Coordinator.attachInertHost(token, host)) {
            failR18Stage(owner, "hostIdentityChanged"); return
        }
        owner.host = host
        recordR18(owner, "HOST_ADDED")
        maybeBindR18(owner)
    }

    private fun onR18HostReady(generation: Long, host: android.view.View, windowId: Int) {
        val owner = r18Active ?: return
        val token = owner.token
        if (token.stamp.hostGeneration != generation || owner.host !== host ||
            !r18Coordinator.hostReady(token, host)) return
        owner.hostReady = true
        owner.hostWindowId = windowId
        knownOwnOverlayIdentity = KeyguardOwnOverlayIdentity(windowId, Display.DEFAULT_DISPLAY,
            token.stamp.authority.attachGeneration)
        recordR18(owner, "HOST_READY")
        maybeBindR18(owner)
    }

    private fun onR18BufferReady(attachment: Long, generation: Long, at: Long) {
        val owner = r18Active ?: return
        if (owner.preparation.attachment != attachment || owner.preparation.outputGeneration != generation) return
        recordR18(owner, "BUFFER_READY", at)
        maybeBindR18(owner)
    }

    private fun maybeBindR18(owner: R18Active) {
        if (r18Active !== owner || owner.binding || owner.bound) return
        val token = owner.token
        val prep = owner.preparation
        val output = overlay.r18PreparedOutput(prep) ?: return
        if (owner.output !== output) {
            val accepted = synchronized(queueLock) {
                val empty = r18DrainBindings.indexOfFirst { it == null }
                val free = if (empty >= 0) empty else r18DrainBindings.indexOfFirst { it?.drained == true }
                if (free < 0 || !r18Coordinator.attachPreparedOutput(token, output) ||
                    !r18Coordinator.imageReady(token, output)) false
                else {
                    r18DrainBindings[free] = R18DrainBinding(token, owner.diagnosticContext,
                        prep.attachment, prep.outputGeneration, output)
                    true
                }
            }
            if (!accepted) { failR18Stage(owner, "outputCapacityOrIdentity"); return }
            owner.output = output
            overlay.r18ReadyAt(prep)?.let { recordR18(owner, "BUFFER_READY", it) }
        }
        if (!owner.hostReady) return
        owner.binding = true
        overlay.bindR18Host(token.stamp.hostGeneration, prep) { success ->
            if (r18Active !== owner || owner.token !== token || owner.preparation != prep) return@bindR18Host
            owner.binding = false
            if (!success) { failR18Stage(owner, "hiddenBindFailed"); return@bindR18Host }
            owner.bound = true
            recordR18(owner, "HIDDEN_BOUND")
            // If readiness followed an earlier positive, reacquire rather than
            // storing that positive across this asynchronous boundary.
            requestSystemCheck("r18Ready", evaluate = true)
        }
    }

    private fun onR18Failure(attachment: Long, generation: Long, reason: String) {
        val owner = r18Active
        if (owner == null) {
            synchronized(queueLock) {
                r18RouteEnabled = false
                r18RouteSnapshot = null
                r18RouteRevision += 1L
                cancelR18ReservationLocked()
            }
            return
        }
        if (owner.preparation.attachment == attachment && owner.preparation.outputGeneration == generation)
            failR18Stage(owner, reason)
    }

    private fun onR18Drained(attachment: Long, generation: Long, output: Any) {
        mainHandler.post {
            if (r18Active == null && r18FallbackWake == wakeEpoch && FluviKeyguardCardServiceRegistry.connected)
                requestSystemCheck("r18DrainReady", evaluate = true)
        }
        val binding = synchronized(queueLock) {
            val index = r18DrainBindings.indexOfFirst {
                it?.attachment == attachment && it.generation == generation && it.output === output
            }
            if (index < 0) null else r18DrainBindings[index]?.takeIf { !it.drained }?.also {
                it.drained = true
                r18Coordinator.outputDrained(it.token, output)
            }
        } ?: return
        val context = binding.diagnosticContext ?: return
        if (context.captureId == null || !KeyguardCardDiagnostics.wantsEvent("R18_PIPELINE")) return
        KeyguardCardDiagnostics.captureEvent(this, "R18_PIPELINE", "OUTPUT_DRAINED",
            serviceSession = binding.token.stamp.authority.serviceSession,
            wakeEpoch = binding.token.stamp.authority.wakeGeneration,
            requestId = binding.token.stamp.firstRequestId, attachGeneration = attachment,
            diagnosticContext = context, deferredFields = { mapOf("r18Host" to binding.token.stamp.hostGeneration,
                "r18Output" to generation, "r18Phase" to "OUTPUT_DRAINED") })
    }

    private fun onR18Receipt(attachment: Long, generation: Long,
                             receipt: com.fluvi.app.lockscreen.material.KeyguardOrbPresentationLane.Receipt) {
        val binding = synchronized(queueLock) { r18DrainBindings.firstOrNull {
            it?.attachment == attachment && it.generation == generation
        } } ?: return
        val context = binding.diagnosticContext ?: return
        if (context.captureId == null || !KeyguardCardDiagnostics.wantsEvent("R18_PIPELINE")) return
        KeyguardCardDiagnostics.captureEvent(this, "R18_PIPELINE", "${receipt.operation}_RECEIPT",
            serviceSession = binding.token.stamp.authority.serviceSession,
            wakeEpoch = binding.token.stamp.authority.wakeGeneration,
            requestId = binding.token.stamp.firstRequestId, attachGeneration = attachment,
            observedUptimeMs = receipt.committedUptimeMs ?: receipt.applyReturnUptimeMs ?: receipt.submitStartUptimeMs,
            diagnosticContext = context, deferredFields = { mapOf(
                "r18Host" to binding.token.stamp.hostGeneration, "r18Output" to generation,
                "r18Phase" to receipt.operation, "r18ApplyBegin" to receipt.submitStartUptimeMs,
                "r18ApplyEnd" to (receipt.applyReturnUptimeMs ?: "UNOBSERVED"),
                "r18Commit" to (receipt.committedUptimeMs ?: "UNOBSERVED"),
                "r18LatchNs" to (receipt.latchNanos ?: "UNOBSERVED"),
                "r18PresentNs" to (receipt.presentSignalNanos ?: "UNOBSERVED"),
                "r18PresentState" to receipt.presentState,
            ) })
    }

    /** The positive being applied is the only place a missing full scene may
     * be requested. If it or the host is delayed, a later independent read
     * must supply another complete MAIN and fresh final system proof. */
    private fun prepareR18Decision(owner: R18Active, request: KeyguardCardInspectionRequest,
                                   inspection: Inspection, decision: KeyguardCardVisibility,
                                   settings: KeyguardCardSettings): Boolean {
        val token = owner.token
        val stamp = token.stamp
        val profile = lastMaterialProfile ?: run { failR18Stage(owner, "profileMissing"); return false }
        val revisionCurrent = synchronized(queueLock) { r18RouteRevision == stamp.selectionRevision }
        if (!revisionCurrent || inspectionAuthority != stamp.authority ||
            profile.publisherRevision != stamp.materialRevision || settings.focus.generation != stamp.dataRevision ||
            inspection.surfaceReason != KeyguardSurfaceReason.MAIN_CONFIRMED || inspection.rootUnavailable ||
            inspection.walkTruncated || inspection.abortedStale) {
            failR18Stage(owner, "positiveOrRevisionChanged"); return false
        }
        val full = decision == KeyguardCardVisibility.SHOW_FULL
        if (owner.preparation.full != full) {
            val next = overlay.prepareR18(full = full, authorizedFull = full) { prep ->
                val nextStamp = stamp.copy(firstRequestId = request.id, full = full,
                    outputGeneration = prep.outputGeneration)
                val replacement = r18Coordinator.replaceUnshown(token, nextStamp) ?: return@prepareR18 false
                owner.identity = R18Identity(replacement.reservation, prep)
                owner.output = null
                owner.binding = false
                owner.bound = false
                true
            }
            if (next == null) failR18Stage(owner, "disclosurePreparationFailed")
            else recordR18(owner, if (full) "PREPARE_FULL" else "PREPARE_DISCREET")
            return false
        }
        val expectedVisual = if (full) profile.visualKey else profile.neutralized().visualKey
        if (owner.preparation.visualKey != expectedVisual || overlay.r18Preparation() != owner.preparation) {
            failR18Stage(owner, "visualIdentityChanged"); return false
        }
        if (!owner.bound || !overlay.isR18Bound(stamp.hostGeneration, owner.preparation) ||
            overlay.r18PreparedOutput(owner.preparation) !== owner.output || owner.output == null) {
            maybeBindR18(owner)
            recordR18(owner, "WAITING_INPUTS")
            return false
        }
        return true
    }

    /** Same-wake recovery owns a fresh host/output and must re-read after
     * asynchronous readiness; the old visible grant is never revived. */
    private fun tryStartR18Readmission(request: KeyguardCardInspectionRequest,
                                       inspection: Inspection, settings: KeyguardCardSettings): Boolean {
        if (r18Active != null || overlay.isAttached || r18FallbackWake == wakeEpoch ||
            inspection.surfaceReason != KeyguardSurfaceReason.MAIN_CONFIRMED || inspection.rootUnavailable ||
            inspection.walkTruncated || inspection.abortedStale) return false
        val previous = r18Coordinator.snapshot()
        if (previous.grant != KeyguardOrbPresentationCoordinator.Grant.RETIRED ||
            previous.reservation?.stamp?.authority?.wakeGeneration != wakeEpoch) return false
        refreshR18RouteOnMain()
        val reserved = synchronized(queueLock) {
            val route = r18RouteSnapshot ?: return@synchronized null
            val prep = route.preparation
            val stamp = KeyguardOrbPresentationStamp(inspectionAuthority, request.id, r18RouteRevision,
                route.materialRevision, route.dataRevision, prep.width, prep.height, prep.densityDpi, prep.full,
                ++r18NextHostGeneration, prep.outputGeneration, Display.DEFAULT_DISPLAY)
            val token = r18Coordinator.reserveReadmission(stamp, request.id, inspectionAuthority,
                sampleEligible = true, routeEligible = r18RouteEnabled) ?: return@synchronized null
            token to prep
        } ?: return false
        startR18Stage(reserved.first, reserved.second, settings, request.diagnosticContext)
        return true
    }

    private fun failR18Stage(owner: R18Active, reason: String) {
        if (r18Active !== owner) return
        r18FallbackWake = wakeEpoch
        recordR18(owner, "FALLBACK:$reason")
        hideImmediately("r18Fallback:$reason", terminalWake = false,
            diagnosticContext = owner.diagnosticContext, causingInspectionRequestId = owner.token.stamp.firstRequestId)
        // A failed exact host removal is not permission to create another
        // window or an automatic retry loop. A later real event can retry.
        if (r18Active === owner) { recordR18(owner, "FALLBACK_BLOCKED_HOST"); return }
        requestSystemCheck("r18Fallback", evaluate = true, freshness = KeyguardWindowFreshness.MISSING_FRESHNESS_EVIDENCE)
    }

    /** Pure authority transition first; native hide is queued immediately and
     * never waits for the Main reconciliation or a borrower. */
    private fun sealR18(authority: KeyguardInspectionAuthority, requestId: Long, reason: String): R18Active? {
        val owner = r18Active ?: return null
        val identity = owner.identity
        val token = identity.token
        if (r18Coordinator.seal(token, authority, requestId, true) == null) return null
        overlay.sealR18FromAnyThread(identity.preparation.attachment, identity.preparation.outputGeneration)
        recordR18(owner, "SEALED:$reason")
        return owner
    }

    private fun finishR18AfterWindow(owner: R18Active?) {
        if (owner == null || r18Active !== owner) return
        val token = owner.token
        if (overlay.hasR18Host(token.stamp.hostGeneration)) return
        owner.host?.let { r18Coordinator.hostRemoved(token, it) }
        if (r18Coordinator.retired(token)) r18Active = null
    }

    private fun r18ActionAllowed(): Boolean {
        val owner = r18Active ?: return true
        val host = owner.host ?: return false
        return r18Coordinator.mayAct(owner.token, host)
    }

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
        surfaceMetrics: com.fluvi.app.lockscreen.material.KeyguardOrbSurfaceMetrics? = null,
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
                surfaceMetrics = surfaceMetrics,
            )
        }
    }

    /** Technical, capture-qualified recovery evidence. Formatting happens on
     * the diagnostic consumer; no display or acquisition work is triggered. */
    private fun recordR14Recovery(
        action: String, recovery: KeyguardR14Recovery, request: KeyguardCardInspectionRequest? = null,
        pending: KeyguardCardInspectionRequest? = null, displaced: Long? = null,
        observedAt: Long? = null, readStart: Long? = null, readEnd: Long? = null,
        requestId: Long? = null, showOperation: Long? = null,
    ) {
        if (!KeyguardCardDiagnostics.wantsEvent("R14_RECOVERY")) return
        val context = if (request != null) request.diagnosticContext else currentDiagnosticAttempt
        if (context?.captureId == null || context != recovery.diagnosticContext) return
        val origin = pending?.r14Ingress
        traceKeyguard("R14_RECOVERY", action, request = request, requestId = requestId,
            observedUptimeMs = observedAt, diagnosticContext = context,
            deferredFields = { mapOf(
                "r14Recovery" to recovery.id,
                "r14PreviousHide" to (recovery.hideOperationId ?: "UNOBSERVED"),
                "r14PreviousAttach" to recovery.previousAttachment,
                "r14Authority" to "${recovery.authority.serviceSession}/${recovery.authority.wakeGeneration}/${recovery.authority.visibilityEpoch}/${recovery.authority.interactionEpoch}/${recovery.authority.attachGeneration}",
                "r14DeferredA" to (recovery.deferredRequestId ?: "UNOBSERVED"),
                "r14Current" to (request?.id ?: requestId ?: "UNOBSERVED"),
                "r14OriginalB" to (recovery.pendingRequestId ?: "UNOBSERVED"),
                "r14Pending" to (pending?.id ?: "UNOBSERVED"),
                "r14Displaced" to (displaced ?: "UNOBSERVED"),
                "r14Ingress" to (origin?.id ?: "UNOBSERVED"),
                "r14Origin" to when (origin?.origin) {
                    KeyguardR14Origin.SYSTEM_UI -> "systemUi"
                    KeyguardR14Origin.OWN -> "own"
                    KeyguardR14Origin.AMBIGUOUS -> "ambiguous"
                    KeyguardR14Origin.OTHER -> "other"
                    null -> "syntheticOrUnavailable"
                },
                "r14Window" to (origin?.windowId ?: "UNOBSERVED"),
                "r14Display" to (origin?.displayId ?: "UNOBSERVED"),
                "r14Event" to (origin?.eventAt ?: "UNOBSERVED"),
                "r14Callback" to (origin?.callbackAt ?: "UNOBSERVED"),
                "r14ReadStart" to (readStart ?: "UNOBSERVED"),
                "r14ReadEnd" to (readEnd ?: "UNOBSERVED"),
                "r14Show" to (showOperation ?: "UNOBSERVED"),
                "r14ReplacementOmitted" to (recovery.replacements - 4).coerceAtLeast(0),
                "r14Physical" to "UNOBSERVED",
            ) })
    }

    private fun clearR14Recovery(reason: String) {
        val previous = r14Recovery ?: return
        recordR14Recovery("END_$reason", previous)
        r14Recovery = null
    }

    private data class WakeTiming(
        val wakeGeneration: Long,
        val wakeReceivedAt: Long,
        val rootWasPrepared: Boolean,
        val profileWasDecoded: Boolean,
        val presentationMode: String,
        val eligibility: KeyguardWakeEligibilityEvidence? = null,
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

    private data class RetiredSurfaceEvidence(
        val attachment: Long, val generation: Long,
        val metrics: com.fluvi.app.lockscreen.material.KeyguardOrbSurfaceMetrics,
        val atRevoke: com.fluvi.app.lockscreen.material.KeyguardOrbSurfaceMetrics.HolderOperation,
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
                    val owner = currentDiagnosticAttempt
                    hideImmediately("screenOff", triggerReceivedUptimeMs = receivedAt)
                    if (owner != null) traceKeyguard("SCREEN_OFF_RECEIVED", "broadcast", observedUptimeMs = receivedAt,
                        diagnosticContext = owner, fields = mapOf("sourceEventTime" to "NA", "sourceTimeUnavailable" to true))
                }
                Intent.ACTION_USER_PRESENT -> {
                    val owner = currentDiagnosticAttempt
                    hideImmediately("userPresent", triggerReceivedUptimeMs = receivedAt)
                    if (::overlay.isInitialized && !overlay.isAttached && lastSettings?.requested == true) {
                        overlay.prepareR18()
                        refreshR18RouteOnMain()
                    }
                    if (owner != null) traceKeyguard("USER_PRESENT_RECEIVED", "broadcast", observedUptimeMs = receivedAt,
                        diagnosticContext = owner, fields = mapOf("sourceEventTime" to "NA", "sourceTimeUnavailable" to true))
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
            onOpen = { if (r18ActionAllowed()) openFocusedFluvi() },
            onToggle = { if (r18ActionAllowed()) toggleView() },
            onInteractionStarted = { if (r18ActionAllowed()) onOverlayInteractionStarted() },
            onSurfaceMotionIneligible = {
                synchronized(queueLock) { firstAcquisition.invalidate() }
                if (r18Active != null) {
                    sealR18(inspectionAuthority, Long.MAX_VALUE, "motionIneligible")
                    mainHandler.post {
                        hideImmediately("r18MotionIneligible", terminalWake = false)
                        requestSystemCheck("r18MotionIneligible", evaluate = true)
                    }
                }
            },
            onPositionCommitted = { mode, card, orb, revision ->
                if (r18ActionAllowed()) onOverlayPositionCommitted(mode, card, orb, revision)
            },
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
            armColdRootDiagnostic = { attach ->
                val owner = activeWindowDiagnosticOperation
                if (attach != 1L || owner?.context?.captureId == null) null
                else { stage, at, fields ->
                    mainHandler.post {
                        traceKeyguard(stage, "r10ColdRoot", observedUptimeMs = at,
                            attachGeneration = attach, operation = owner, fields = fields)
                    }
                }
            },
            armFirstOfferDiagnostic = { attach ->
                val operation = activeWindowDiagnosticOperation
                val captureOwner = KeyguardCardDiagnostics.drawEvidenceOwner()
                if (operation?.context?.captureId == null || captureOwner == null) null
                else { observation: KeyguardOrbFirstOfferObservation ->
                    // Retain the original capture and show operation. A late
                    // Worker/commit callback cannot be relabelled by a new
                    // attachment or capture, and formatting stays on reducer.
                    if (KeyguardCardDiagnostics.drawEvidenceOwner() === captureOwner) {
                        KeyguardCardDiagnostics.captureEvent(
                            context = this,
                            stage = "R11_FIRST",
                            reason = observation.stage,
                            serviceSession = operation.context.serviceSession,
                            wakeEpoch = operation.context.originWakeEpoch,
                            attachGeneration = attach,
                            observedUptimeMs = observation.at,
                            operation = operation,
                            deferredFields = { mapOf(
                                "r11Renderer" to observation.renderer,
                                "r11Attachment" to observation.lease.attachment,
                                "r11Generation" to observation.lease.generation,
                                "r11Slot" to observation.slot,
                                "r11Use" to observation.use,
                                "r11Ready" to observation.readyAt,
                                "r11Offer" to observation.offeredAt,
                                "r11Grant" to observation.grantAt,
                                "r11Child" to observation.childId,
                                "r11GrantId" to observation.grantId,
                                "r11Origin" to observation.origin,
                                "r11Detail" to observation.detail,
                                "r11ExtraAt" to observation.extraAt,
                                "r11ShaderHit" to observation.shaderHit,
                                "r11ShaderConstructed" to observation.shaderConstructed,
                                "r11ShaderWallNs" to observation.shaderWallNs,
                                "r11ShaderCpuNs" to observation.shaderCpuNs,
                            ) },
                        )
                    }
                }
            },
            armSurfaceDiagnostic = { attach ->
                val operation = activeWindowDiagnosticOperation
                val owner = KeyguardCardDiagnostics.drawEvidenceOwner()
                if (operation?.context?.captureId == null || owner == null) null
                else { observation ->
                    if (KeyguardCardDiagnostics.drawEvidenceOwner() === owner) {
                        KeyguardCardDiagnostics.captureEvent(
                            context = this,
                            stage = "R12_SURFACE",
                            reason = observation.stage,
                            serviceSession = operation.context.serviceSession,
                            wakeEpoch = operation.context.originWakeEpoch,
                            attachGeneration = attach,
                            observedUptimeMs = observation.observedAtUptimeMs,
                            operation = operation,
                            surfaceMetrics = observation.metrics,
                            deferredFields = { mapOf(
                                "r12Attachment" to observation.attachment,
                                "r12Generation" to observation.generation,
                                "r12Detail" to observation.detail,
                                "r12Privacy" to if (observation.full) "full" else "discreet",
                            ) },
                        )
                    }
                }
            },
            onSurfaceFailure = { reason -> hideImmediately("r12SurfaceFailure:$reason") },
            onR18HostReady = ::onR18HostReady,
            onR18HostAttached = { generation, at ->
                r18Active?.takeIf { it.token.stamp.hostGeneration == generation }?.let { recordR18(it, "HOST_ATTACHED", at) }
            },
            onR18BufferReady = ::onR18BufferReady,
            onR18Failure = ::onR18Failure,
            onR18Receipt = ::onR18Receipt,
            onR18Drained = ::onR18Drained,
            r18PipelineEnabled = true,
            onFirstRootPreDraw = ::recordFirstRootPreDraw,
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
        refreshR18RouteOnMain()
        publishReadAheadState()
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
        inspectionProbeForTest?.frameworkCopy(meta, event.eventType, event.windowId,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) event.displayId else Display.DEFAULT_DISPLAY,
            if (event.eventType == AccessibilityEvent.TYPE_WINDOWS_CHANGED) event.windowChanges else 0,
            event.packageName?.toString(), event.eventTime)
        acceptAccessibilityMetadata(meta, callbackReceivedAt, frameworkEvent = true)
    }

    /** A controlled fixture enters through the same metadata adapter as the
     * real framework callback. It never supplies a classification/decision. */
    internal fun acceptAccessibilityMetadataForTest(meta: KeyguardAccessibilityEventMeta) {
        check(Looper.myLooper() == Looper.getMainLooper())
        acceptAccessibilityMetadata(meta, SystemClock.uptimeMillis(), frameworkEvent = false)
    }

    private fun acceptAccessibilityMetadata(
        meta: KeyguardAccessibilityEventMeta,
        callbackReceivedAt: Long,
        frameworkEvent: Boolean,
    ) {
        if (!KeyguardCardEventGate.isSurfaceEvent(meta.eventType)) return
        val eventAge = meta.eventTimeUptimeMs
            ?.takeIf { it in 1..callbackReceivedAt }
            ?.let { callbackReceivedAt - it }
        val own = ::overlay.isInitialized && overlay.isOwnAccessibilityWindow(meta.windowId, meta.displayId)
        val r14Origin = KeyguardR14IngressClassifier.classify(meta, own)
        val action = KeyguardCardEventGate.decide(meta, own)
        inspectionProbeForTest?.ingress(meta, callbackReceivedAt, action, frameworkEvent)
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
                "classification" to r14Origin.name,
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
                val ingress = KeyguardR14Ingress(
                    id = ++nextR14IngressId,
                    externalSystemUi = r14Origin == KeyguardR14Origin.SYSTEM_UI,
                    windowId = meta.windowId, displayId = meta.displayId, eventType = meta.eventType,
                    eventAt = meta.eventTimeUptimeMs, callbackAt = callbackReceivedAt, origin = r14Origin,
                )
                val cycle = beginOrJoinWakeCycle("accessibility", callbackReceivedAt, schedule = false,
                    eventTime = meta.eventTimeUptimeMs)
                if (cycle == null) return
                scheduleEvaluationFromIngress(
                    "window",
                    meta.eventTimeUptimeMs,
                    triggerReceivedUptimeMs = callbackReceivedAt,
                    freshness = if (cycle?.started == true) {
                        KeyguardWindowFreshness.LIFECYCLE_BOUNDARY
                    } else {
                        KeyguardWindowFreshness.FRAMEWORK_EVENT
                    },
                    meta = meta,
                    frameworkEvent = frameworkEvent,
                    ingress = ingress,
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
            if (r18Active != null && lastSettings != settings) sealR18(inspectionAuthority, Long.MAX_VALUE, "settingsChanged")
            clearR14Recovery("settingsChanged")
            publishReadAheadState(invalidate = true)
            try {
            val previous = lastSettings
            lastSettings = settings
            if (r18Active != null && previous != settings) hideImmediately("r18SettingsChanged", terminalWake = false)
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
            } finally {
                publishReadAheadState(invalidate = true)
                refreshR18RouteOnMain()
            }
        }
    }

    /** Layout patches intentionally bypass the general settings/evaluation
     * lane: a drag has already updated the retained root and must not start a
     * financial resolve, material reload or focus-generation change. */
    internal fun onLayoutChangedFromApplication(settings: KeyguardCardSettings) {
        mainHandler.post {
            publishReadAheadState(invalidate = true)
            try {
            lastSettings = settings
            if (::overlay.isInitialized) overlay.updateLayoutSettings(settings)
            } finally {
                publishReadAheadState(invalidate = true)
            }
        }
    }

    private fun onOverlayInteractionStarted() {
        // This only invalidates reads that predate the pointer stream. A later
        // real SystemUI event starts a fresh inspection and remains allowed to
        // hide the overlay even while the finger is down.
        val before = inspectionAuthority
        interactionEpoch.incrementAndGet()
        val after = before.copy(interactionEpoch = interactionEpoch.get())
        val owner = r18Active
        if (owner != null && !r18Coordinator.advanceInteraction(owner.token, before, after)) {
            sealR18(before, Long.MAX_VALUE, "interactionAuthority")
            hideImmediately("r18InteractionAuthority", terminalWake = false)
            return
        }
        publishInspectionAuthority()
        preservePendingReconciliation("interaction", requirePending = false)
    }

    private fun onOverlayPositionCommitted(
        mode: KeyguardCardPresentationMode,
        card: KeyguardCardCardPosition,
        orb: KeyguardCardOrbPosition,
        expectedLayoutRevision: Long,
    ) {
        clearR14Recovery("layoutChanged")
        publishReadAheadState(invalidate = true)
        try {
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
        } finally {
            publishReadAheadState(invalidate = true)
        }
    }

    internal fun onFinancialFocusChangedFromApplication() {
        mainHandler.post {
            if (r18Active != null) sealR18(inspectionAuthority, Long.MAX_VALUE, "focusChanged")
            clearR14Recovery("focusChanged")
            publishReadAheadState(invalidate = true)
            try {
            showEvent = false
            if (r18Active != null) hideImmediately("r18FocusChanged", terminalWake = false)
            invalidateFullContent()
            // A focus change may make a visible amount misleading. Redact in
            // place when possible; do not bounce the overlay root.
            if (overlay.isAttached && appliedDecision == KeyguardCardVisibility.SHOW_FULL) {
                applyPresentation({ FluviFinancialCardPresenter.loading() }, "focusChanged")
            }
            scheduleEvaluation("focusChanged")
            } finally {
                publishReadAheadState(invalidate = true)
            }
        }
    }

    /** Profile publication is a retained-view mutation only. It must not
     * cause an inspection, financial resolve, or WindowManager operation. */
    internal fun onMaterialProfileChangedFromApplication(profile: KeyguardMaterialProfile) {
        mainHandler.post {
            if (r18Active != null) sealR18(inspectionAuthority, Long.MAX_VALUE, "materialChanged")
            synchronized(queueLock) { firstAcquisition.invalidate() }
            clearR14Recovery("materialChanged")
            lastMaterialProfile = profile
            if (!::overlay.isInitialized) return@post
            val hadR18 = r18Active != null
            if (hadR18) hideImmediately("r18MaterialChanged", terminalWake = false)
            overlay.updateMaterial(profile, lastSettings ?: FluviKeyguardCardSettings.read(applicationContext))
            publishReadAheadState(invalidate = true)
            refreshR18RouteOnMain()
            if (hadR18) requestSystemCheck("r18MaterialChanged", evaluate = true)
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
        sampleRequest: KeyguardSystemGateRequest? = null,
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
        val early = synchronized(queueLock) {
            r18ProvisionalWake?.takeIf {
                it.sampleId == sampleRequest?.id && it.previousAuthority == inspectionAuthority &&
                    it.targetAuthority.wakeGeneration == wakeEpoch + 1L && it.routeRevision == r18RouteRevision
            }
        }
        val cycleTransition = wakeCycleOwner.beginOrJoin(wakeEpoch + 1L, source, receivedAtUptimeMs)
        val cycle = cycleTransition.cycle
        r18WakeOpen = true
        clearR14Recovery("newWake")
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
        val preparedInitialLive = ::overlay.isInitialized &&
            overlay.preparedInitialLiveOrb(settings, lastMaterialProfile)
        synchronized(queueLock) {
            if (early == null || early.targetAuthority != inspectionAuthority || r18ProvisionalWake !== early) {
                firstAcquisition.begin(inspectionAuthority, preparedInitialLive)
            } else if (r18Coordinator.adopt(early.token, early.token.stamp)) {
                r18AdoptedSampleId = early.sampleId
                r18ProvisionalWake = null
            } else {
                cancelR18ReservationLocked()
                firstAcquisition.begin(inspectionAuthority, preparedInitialLive)
            }
        }
        wakeTiming = WakeTiming(
            wakeGeneration = wakeEpoch,
            wakeReceivedAt = receivedAtUptimeMs,
            rootWasPrepared = ::overlay.isInitialized && overlay.hasPreparedRoot,
            profileWasDecoded = lastMaterialProfile != null,
            presentationMode = settings.presentationMode.wireValue,
            eligibility = if (sampleRequest?.diagnosticCaptureId != null &&
                sampleRequest.diagnosticCaptureId == KeyguardCardDiagnostics.activeCaptureId())
                KeyguardWakeEligibilityEvidence(sampleRequest?.id, sampleRequest?.authority,
                    receivedAtUptimeMs, freshState.startedAt, freshState.finishedAt, SystemClock.uptimeMillis(),
                    sampleRequest.diagnosticCaptureId)
            else null,
        )
        currentDiagnosticAttempt = early?.diagnosticContext ?: KeyguardCardDiagnostics.beginLockAttempt(
            this,
            session.get(),
            wakeEpoch,
            source,
            receivedAtUptimeMs,
        )
        if (early != null && r18AdoptedSampleId == early.sampleId) {
            r18FallbackWake = null
            startR18Stage(early.token, early.preparation, settings, currentDiagnosticAttempt, freshState, early.reservedAt)
        }
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
            eventTime = eventTime, retry = retry, freshness = freshness, completedInspectionId = completedInspectionId,
            diagnosticCaptureId = KeyguardCardDiagnostics.activeCaptureId()))
    }

    private fun applySystemState(request: KeyguardSystemGateRequest, state: KeyguardSystemState) {
        // The sampler checks every identity, even for a negative answer.
        if (!FluviKeyguardCardServiceRegistry.connected || lastSettings?.requested != true) return
        latestSamplerEvidence = if (request.diagnosticCaptureId != null &&
            request.diagnosticCaptureId == KeyguardCardDiagnostics.activeCaptureId())
            KeyguardSamplerEvidence(request.id, request.authority, state.startedAt, state.finishedAt,
                SystemClock.uptimeMillis(), state.eligible, state.excluded, request.diagnosticCaptureId)
        else null
        if (state.excluded) {
            hideImmediately("systemGate:${request.reason}", triggerReceivedUptimeMs = request.receivedAt)
            return
        }
        if (!state.eligible || !request.evaluate) return
        val cycle = request.wakeSource?.let {
            beginOrJoinWakeCycle(it, request.evaluationReceivedAt, schedule = false, freshState = state, sampleRequest = request)
        }
        if (request.wakeSource != "wake") request.screenOnReceivedAt?.let {
            beginOrJoinWakeCycle("wake", it, schedule = false, freshState = state, sampleRequest = request)
        }
        if (wakeCycleOwner.current() == null) return
        if (r18AdoptedSampleId == request.id) {
            r18AdoptedSampleId = null
            if (hasCompatibleCycleInspection()) return
        }
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
        scheduleEvaluationCommon(trigger, eventTimeUptimeMs, triggerReceivedUptimeMs, freshness,
            reconciliationIntent, null, false)
    }

    private fun scheduleEvaluationFromIngress(trigger: String, eventTimeUptimeMs: Long?,
        triggerReceivedUptimeMs: Long?, freshness: KeyguardWindowFreshness,
        meta: KeyguardAccessibilityEventMeta, frameworkEvent: Boolean, ingress: KeyguardR14Ingress) {
        scheduleEvaluationCommon(trigger, eventTimeUptimeMs, triggerReceivedUptimeMs, freshness,
            null, meta, frameworkEvent, ingress)
    }

    private fun scheduleEvaluationCommon(trigger: String, eventTimeUptimeMs: Long?,
        triggerReceivedUptimeMs: Long?, freshness: KeyguardWindowFreshness,
        reconciliationIntent: KeyguardCardInspectionRequest?, meta: KeyguardAccessibilityEventMeta?,
        frameworkEvent: Boolean, ingress: KeyguardR14Ingress? = null) {
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
            r14Ingress = ingress,
            wakeEligibility = wakeTiming?.takeIf { it.wakeGeneration == authority.wakeGeneration }?.eligibility
                ?.takeIf { it.captureId == currentDiagnosticAttempt?.captureId && it.captureId == KeyguardCardDiagnostics.activeCaptureId() },
            latestSamplerEvidence = latestSamplerEvidence?.takeIf {
                it.belongsTo(authority, currentDiagnosticAttempt?.captureId) && it.captureId == KeyguardCardDiagnostics.activeCaptureId()
            },
        )
        if (request.trigger != "surfaceRetry") cancelWakeRetry("supersededBy:${request.trigger}")
        wakeTiming?.takeIf { it.wakeGeneration == request.wakeGeneration }?.let {
            if (it.inspectionQueuedAt == null) it.inspectionQueuedAt = now
            request.eventTimeUptimeMs?.takeIf { eventTime -> eventTime <= now }?.let { eventTime ->
                it.eventAgeMs = now - eventTime
            }
        }
        val queueOffer = synchronized(queueLock) {
            inspectionFreshness.require(authority, request.windowFreshness)
            publishReadAheadSnapshotLocked()
            val replacedPending = inspectionQueue.pendingRequest()
            val startsWorker = inspectionQueue.offer(request)
            if (inspectionQueue.pendingRequest() != null) {
                recordMaximum(maximumPendingInspections, 1)
            }
            Triple(startsWorker, replacedPending, inspectionQueue.pendingRequest())
        }
        inspectionProbeForTest?.queueOffered(request, queueOffer.second, queueOffer.third, queueOffer.first)
        if (meta != null) inspectionProbeForTest?.ingressOffered(meta, request, queueOffer.second,
            queueOffer.third, queueOffer.first, frameworkEvent)
        val recovery = r14Recovery
        if (recovery?.used == true && queueOffer.second != null && queueOffer.third != null) {
            val next = recovery.copy(replacements = recovery.replacements + 1)
            r14Recovery = next
            if (next.replacements <= 4) recordR14Recovery("REPLACED", next, request, queueOffer.third,
                displaced = queueOffer.second?.id)
        }
        traceKeyguard(
            if (queueOffer.first) "INSPECTION_QUEUED" else "INSPECTION_COALESCED",
            trigger,
            request,
            fields = mapOf(
                "queuedAtUptimeMs" to now,
                "triggerReceivedUptimeMs" to (request.triggerReceivedUptimeMs ?: "NA"),
                "eventTimeUptimeMs" to (request.eventTimeUptimeMs ?: "NA"),
                "replacedPendingRequestId" to (queueOffer.second?.id ?: "NA"),
                "requestVisibilityEpoch" to request.visibilityEpoch,
                "requestInteractionEpoch" to request.interactionEpoch,
                "requestWakeGeneration" to request.wakeGeneration,
                "windowFreshness" to request.windowFreshness.name,
            ),
        )
        if (queueOffer.first) inspectionScope.launch { processInspectionQueue(request) }
    }

    private data class CompletedInspection(
        val request: KeyguardCardInspectionRequest,
        val result: Inspection,
        val startedAt: Long,
        val finishedAt: Long,
    )

    private data class InspectionHandoff(
        val diagnosticPreparationFinishedAt: Long,
        val requestedAt: Long,
        val requestedAtNs: Long,
    )

    private data class ReadAheadDecision(
        val snapshot: KeyguardReadAheadSnapshot?,
        val successor: KeyguardCardInspectionRequest?,
        val pendingId: Long?,
        val reason: String,
        val currentFreshnessRevision: Long?,
        val outstandingFreshness: KeyguardWindowFreshness?,
        val negativeFreshnessRevision: Long?,
    )

    private fun readInspection(request: KeyguardCardInspectionRequest): CompletedInspection {
        val concurrent = activeInspectionCount.incrementAndGet()
        recordMaximum(maximumConcurrentInspections, concurrent)
        val started = SystemClock.uptimeMillis()
        KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.READ_START, request.id, request.attachGeneration)
        val result = try {
            inspectionProbeForTest?.started(request)
            traceKeyguard("INSPECTION_STARTED", request.trigger, request, observedUptimeMs = started,
                fields = mapOf("queueMs" to (started - request.queuedAtUptimeMs),
                    "queuedAtUptimeMs" to request.queuedAtUptimeMs,
                    "authorityCurrentAtStart" to authorityIsCurrent(request)))
            inspectSurface(request)
        } finally { activeInspectionCount.decrementAndGet() }
        val finished = SystemClock.uptimeMillis()
        val visibleOrArmed = r18Active?.let { owner -> owner.host?.let { r18Coordinator.mayAct(owner.token, it) } } == true
        val disqualifying = result.decision != KeyguardCardVisibility.SHOW_FULL &&
            result.decision != KeyguardCardVisibility.SHOW_DISCREET &&
            (result.decision != KeyguardCardVisibility.HIDDEN_UNKNOWN || visibleOrArmed)
        if (disqualifying && !result.abortedStale && authorityIsCurrent(request)) {
            val current = KeyguardInspectionAuthority(request.session, request.visibilityEpoch, request.wakeGeneration,
                request.interactionEpoch, request.attachGeneration)
            sealR18(current, request.id, result.surfaceReason.name)
        }
        KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.READ_END, request.id, request.attachGeneration)
        if (KeyguardR15AcquisitionTestHooks.ENABLED) {
            KeyguardR15AcquisitionTestHooks.outcome(request.id, result.decision, result.surfaceReason,
                authorityIsCurrent(request), started, finished)
        }
        inspectionProbeForTest?.readCompleted(request, result.decision, result.surfaceReason,
            result.rootUnavailable, result.walkTruncated, result.abortedStale, started, finished)
        return CompletedInspection(request, result, started, finished)
    }

    private fun newInspectionHandoff(): InspectionHandoff {
        val prepared = SystemClock.uptimeMillis()
        return InspectionHandoff(prepared, SystemClock.uptimeMillis(), System.nanoTime())
    }

    /** Main is still the only authority to accept an answer or mutate Views.
     * A stale speculative pair triggers normal reconciliation, never SHOW. */
    private fun applyCompletedInspection(
        read: CompletedInspection,
        handoff: InspectionHandoff,
        readAhead: KeyguardReadAheadSnapshot? = null,
        reservedSuccessor: KeyguardCardInspectionRequest? = null,
    ): Boolean {
        val entered = SystemClock.uptimeMillis()
        val enteredNs = System.nanoTime()
        val request = read.request
        KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.MAIN_ENTER, request.id, request.attachGeneration)
        inspectionProbeForTest?.beforeApply(request, read.result.decision)
        val reservationMatches = reservedSuccessor == null || synchronized(queueLock) {
            inspectionQueue.successorForPreceding(request) == reservedSuccessor
        }
        if (readAhead != null && (!reservationMatches || !readAheadStillCurrent(readAhead))) {
            KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.REJECT, request.id, request.attachGeneration, extra = 1)
            traceKeyguard("INSPECTION_REJECTED", "readAheadAuthorityChanged", request,
                fields = mapOf("rejectionReason" to "readAheadAuthorityChanged"))
            preservePendingReconciliation("readAheadAuthorityChanged", requirePending = false)
            return false
        }
        applyInspection(
            inspection = read.result,
            request = request,
            inspectionStartedAt = read.startedAt,
            inspectionFinishedAt = read.finishedAt,
            diagnosticPreparationFinishedAt = handoff.diagnosticPreparationFinishedAt,
            mainHandoffRequestedAt = handoff.requestedAt,
            mainApplyEnteredAt = entered,
            mainHandoffRequestedAtNs = handoff.requestedAtNs,
            mainApplyEnteredAtNs = enteredNs,
        )
        inspectionProbeForTest?.afterApply(request, read.result.decision)
        KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.MAIN_EXIT, request.id, request.attachGeneration)
        return true
    }

    private fun traceCompletedInspection(read: CompletedInspection, handoff: InspectionHandoff?) {
        traceInspectionResult(read.request, read.result, read.startedAt, read.finishedAt)
        if (handoff != null) traceKeyguard("INSPECTION_MAIN_APPLY_POSTED", read.request.trigger,
            read.request, observedUptimeMs = handoff.requestedAt,
            fields = mapOf("inspectionFinishedAtUptimeMs" to read.finishedAt,
                "diagnosticPreparationFinishedAtUptimeMs" to handoff.diagnosticPreparationFinishedAt,
                "mainHandoffRequestedAtUptimeMs" to handoff.requestedAt))
    }

    private fun traceAbortedInspection(read: CompletedInspection) {
        mainHandler.post {
            if (::overlay.isInitialized && overlay.isAttached) requestSystemCheck("abortedInspection:${read.request.id}")
        }
        traceCompletedInspection(read, null)
        traceKeyguard("INSPECTION_REJECTED", "abortedStale", read.request,
            observedUptimeMs = read.finishedAt, fields = mapOf("rejectionReason" to "abortedStale"))
    }

    private fun traceReadAhead(read: CompletedInspection, decision: ReadAheadDecision, handoff: InspectionHandoff) {
        if (!KeyguardCardDiagnostics.wantsEvent("R12_ADMISSION")) return
        traceKeyguard("R12_ADMISSION", decision.reason, read.request, observedUptimeMs = read.finishedAt,
            deferredFields = { mapOf(
                "r12Pending" to (decision.pendingId ?: "UNOBSERVED"),
                "r12Reserved" to (decision.successor?.id ?: "UNOBSERVED"),
                "r12FreshnessRevision" to (decision.snapshot?.freshnessRevision ?: "UNOBSERVED"),
                "r12PriorApplyQueued" to handoff.requestedAt,
            ) })
    }

    private suspend fun processInspectionQueue(first: KeyguardCardInspectionRequest) {
        var request: KeyguardCardInspectionRequest? = first
        while (request != null) {
            val active = request
            val read = readInspection(active)
            if (read.result.abortedStale) {
                val next = synchronized(queueLock) { inspectionQueue.complete(active) }
                traceAbortedInspection(read)
                request = next
                continue
            }
            val decision = synchronized(queueLock) {
                val snapshot = readAheadSnapshot
                val freshness = snapshot?.let { inspectionFreshness.beforeRead(active) }
                val negative = KeyguardReadAheadNegative(read.result.decision, read.result.surfaceReason,
                    read.result.rootUnavailable, read.result.walkTruncated, read.result.abortedStale,
                    read.result.freshnessRevision)
                val pending = inspectionQueue.pendingRequest()
                val reason = when {
                    pending == null -> "noPending"
                    snapshot == null -> "snapshotUnavailable"
                    freshness == null -> "authority"
                    else -> KeyguardReadAheadPolicy.rejection(snapshot, negative, active, pending,
                        freshness.revision, freshness.reason)
                }
                val successor = if (reason != "eligible" || snapshot == null || freshness == null) null else
                    inspectionQueue.reserveSuccessor(active) { candidate ->
                        KeyguardReadAheadPolicy.permits(snapshot, negative, active, candidate,
                            freshness.revision, freshness.reason)
                    }
                ReadAheadDecision(snapshot, successor, pending?.id,
                    if (reason == "eligible" && successor == null) "reservationLost" else reason,
                    freshness?.revision, freshness?.reason, negative.freshnessRevision)
            }
            inspectionProbeForTest?.readAheadDecision(active, decision.pendingId, decision.successor?.id,
                decision.reason, decision.snapshot, decision.currentFreshnessRevision,
                decision.outstandingFreshness, decision.negativeFreshnessRevision)
            val handoff = newInspectionHandoff()
            KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.HANDOFF, active.id, active.attachGeneration)
            if (decision.successor == null || decision.snapshot == null) {
                withContext(Dispatchers.Main.immediate) { applyCompletedInspection(read, handoff) }
                request = synchronized(queueLock) { inspectionQueue.complete(active) }
                traceCompletedInspection(read, handoff)
                traceReadAhead(read, decision, handoff)
                continue
            }

            // Only B may use the one physical reader while A waits for its
            // ordered Main apply. C remains a single coalesced pending item.
            val snapshot = decision.snapshot
            val successor = decision.successor
            val next = coroutineScope {
                val earlierApply = async(Dispatchers.Main) {
                    applyCompletedInspection(read, handoff, snapshot, successor)
                }
                val successorRead: CompletedInspection
                val earlierAccepted = try {
                    successorRead = readInspection(successor)
                    earlierApply.await()
                } finally {
                    synchronized(queueLock) { inspectionQueue.finishPreceding(active) }
                }
                traceCompletedInspection(read, handoff)
                traceReadAhead(read, decision, handoff)
                if (successorRead.result.abortedStale) {
                    traceAbortedInspection(successorRead)
                } else if (!earlierAccepted) {
                    traceCompletedInspection(successorRead, null)
                    traceKeyguard("INSPECTION_REJECTED", "readAheadPredecessorRejected", successor,
                        fields = mapOf("rejectionReason" to "readAheadPredecessorRejected"))
                } else {
                    val nextHandoff = newInspectionHandoff()
                    withContext(Dispatchers.Main.immediate) {
                        applyCompletedInspection(successorRead, nextHandoff, snapshot)
                    }
                    traceCompletedInspection(successorRead, nextHandoff)
                }
                synchronized(queueLock) { inspectionQueue.complete(successor) }
            }
            request = next
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
            "eventType" to (request.r14Ingress?.eventType ?: "UNOBSERVED"),
            "wakeCallbackAt" to (request.wakeEligibility?.callbackAt ?: "UNOBSERVED"),
            "wakeSampleStart" to (request.wakeEligibility?.startedAt ?: "UNOBSERVED"),
            "wakeSampleEnd" to (request.wakeEligibility?.finishedAt ?: "UNOBSERVED"),
            "wakeSampleMain" to (request.wakeEligibility?.deliveredAt ?: "UNOBSERVED"),
            "wakeSampleRequest" to (request.wakeEligibility?.sampleRequestId ?: "UNOBSERVED"),
            "wakeSampleAuthority" to (request.wakeEligibility?.sampleAuthority?.let {
                "${it.serviceSession}/${it.wakeGeneration}/${it.visibilityEpoch}/${it.interactionEpoch}/${it.attachGeneration}"
            } ?: "UNOBSERVED"),
            "latestSampler" to (request.latestSamplerEvidence?.let {
                "${it.requestId}:${it.startedAt}/${it.finishedAt}/${it.deliveredAt}:${it.eligible}/${it.excluded}"
            } ?: "UNOBSERVED"),
            "latestSamplerAuthority" to (request.latestSamplerEvidence?.authority?.let {
                "${it.serviceSession}/${it.wakeGeneration}/${it.visibilityEpoch}/${it.interactionEpoch}/${it.attachGeneration}"
            } ?: "UNOBSERVED"),
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
            "activeRootFlags" to (result.windowTiming.activeRootPrefetchFlags ?: "UNOBSERVED"),
            "acceptedChildFlags" to (result.windowTiming.acceptedChildPrefetchFlags ?: "UNOBSERVED"),
            "cacheEnabled" to (result.windowTiming.cacheEnabled ?: "NA"),
            "freshnessPolicy" to result.windowTiming.freshnessPolicy,
            "cacheClearResult" to result.windowTiming.cacheClearResult,
            "activeCandidateWindowId" to (result.windowTiming.activeCandidateWindowId ?: "NA"),
            "returnedRootWindowId" to (result.windowTiming.returnedRootWindowId ?: "NA"),
            "activeRootAccepted" to result.windowTiming.activeRootAccepted,
            "fallbackReason" to (result.windowTiming.fallbackReason ?: "NA"),
            "ownAttributionAmbiguous" to result.windowTiming.ownAttributionAmbiguous,
            "activeRootCallCount" to result.windowTiming.activeRootCallCount,
            "activeRootTotalMs" to result.windowTiming.activeRootTotalMs,
            "perWindowRootCallCount" to result.windowTiming.rootAcquisitionCount,
            "perWindowRootTotalMs" to result.windowTiming.rootAcquisitionTotalMs,
            "childAcquisitionCount" to result.windowTiming.childAcquisitionCount,
            "childAcquisitionTotalMs" to result.windowTiming.childAcquisitionTotalMs,
            "firstChildAcquisitionMs" to (result.windowTiming.firstChildAcquisitionMs ?: "UNOBSERVED"),
            "childAcquisitionMaxMs" to result.windowTiming.childAcquisitionMaxMs,
            "firstNullRootId" to (result.windowTiming.firstNullRootId ?: "UNOBSERVED"),
            "firstNullRootType" to (result.windowTiming.firstNullRootType ?: "UNOBSERVED"),
            "firstNullRootDisplay" to (result.windowTiming.firstNullRootDisplay ?: "UNOBSERVED"),
            "firstNullRootLayer" to (result.windowTiming.firstNullRootRelativeLayer ?: "UNOBSERVED"),
            "firstNullRootSource" to (result.windowTiming.firstNullRootSource ?: "UNOBSERVED"),
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
        val freshnessRevision: Long? = null,
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
        val freshnessRevision: Long? = null,
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
                freshnessRevision = read.freshnessRevision,
            )
        }
        val classification = KeyguardSurfaceClassifier.classifyDetailed(
            inspectionProbeForTest?.snapshots(request, read.snapshots) ?: read.snapshots,
            unavailableRoot = read.rootUnavailable,
            walkTruncated = read.walkTruncated,
            strictOwnAttribution = r18Active != null ||
                r18ProvisionalWake?.targetAuthority?.matches(request) == true,
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
            freshnessRevision = read.freshnessRevision,
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
        val freshness = synchronized(queueLock) { inspectionFreshness.beforeRead(request) }
        // Selection happens at the eligible physical call, not while reading
        // an empty inventory or a per-window fallback. A superseding freshness
        // revision or authority cannot consume a newer wake's opportunity.
        val selectRootStrategy = {
            val initial = synchronized(queueLock) {
                val current = inspectionFreshness.beforeRead(request)
                val compatible = freshness != null && current != null &&
                    current.authority == freshness.authority && current.revision == freshness.revision &&
                    authorityIsCurrent(request)
                firstAcquisition.take(request, if (compatible) freshness else null)
            }
            val historicalZero = if (KeyguardR15AcquisitionTestHooks.ENABLED) {
                KeyguardR15AcquisitionTestHooks.begin(request, freshness, initial)
            } else false
            when {
                historicalZero -> KeyguardActiveRootStrategy.R15_HISTORICAL_ZERO
                initial && Build.VERSION.SDK_INT == 35 -> KeyguardActiveRootStrategy.R18_INITIAL_HYBRID
                else -> KeyguardActiveRootStrategy.STOCK
            }
        }
        val result = windowSnapshotReader.read(
            request = KeyguardWindowSnapshotReader.Request(
                knownOwn = knownOwnOverlayIdentity,
                attachGeneration = request.attachGeneration,
                freshness = freshness?.reason ?: KeyguardWindowFreshness.FRAMEWORK_EVENT,
                activeRootStrategyAtCall = selectRootStrategy,
                knownOwnAtInventory = { knownOwnOverlayIdentity },
                strictOwnAttribution = r18Active != null ||
                    r18ProvisionalWake?.targetAuthority?.matches(request) == true,
                onDecisiveSystemMarker = {
                    if (authorityIsCurrent(request)) sealR18(
                        KeyguardInspectionAuthority(request.session, request.visibilityEpoch, request.wakeGeneration,
                            request.interactionEpoch, request.attachGeneration), request.id, "decisiveSystemMarker")
                },
            ),
            authorityIsCurrent = { freshness != null && authorityIsCurrent(request) },
            onFreshnessEstablished = { freshness?.let(inspectionFreshness::boundaryEstablished) },
        )
        if (KeyguardR15AcquisitionTestHooks.ENABLED) KeyguardR15AcquisitionTestHooks.finish(result)
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
            freshnessRevision = freshness?.revision,
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
        mainHandoffRequestedAtNs: Long,
        mainApplyEnteredAtNs: Long,
    ) {
        // Captured at Main entry before policy/diagnostic work. This can only
        // correlate Fluvi-owned spans; a missing or partial snapshot is not
        // evidence that the uncovered time belongs to GPU, Binder, or the
        // scheduler.
        val mainHandoffEvidence = slowMainHandoffEvidenceFields(
            mainHandoffRequestedAtNs,
            mainApplyEnteredAtNs,
        )
        withMainWorkEvidence(KeyguardMainWorkEvidence.INSPECTION_APPLY, request.id) {
        var decisionObservedAt: Long? = null
        try {
        wakeTiming?.takeIf { it.wakeGeneration == request.wakeGeneration }?.apply {
            this.inspectionStartedAt = inspectionStartedAt
            this.inspectionFinishedAt = inspectionFinishedAt
        }
        // A provisional successor can revoke the old detached read before
        // Main adopts its wake; the old answer cannot act in that interval.
        if (!authorityIsCurrent(request)) {
            traceKeyguard("INSPECTION_REJECTED", "r18AuthorityChanged", request,
                fields = mapOf("rejectionReason" to "r18AuthorityChanged"))
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
            // Unknown acquisition/transition is not a fabricated terminal
            // exclusion. The surface policy below withdraws it nonterminally.
            displayEligibleNow = !inspection.signals.systemStateAvailable ||
                (inspection.signals.interactive && !inspection.signals.displayOff),
            keyguardLockedNow = !inspection.signals.systemStateAvailable || inspection.signals.keyguardLocked,
        )) {
            KeyguardInspectionAction.DROP_STALE -> {
                KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.REJECT, request.id, request.attachGeneration, extra = 2)
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
                KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.REJECT, request.id, request.attachGeneration, extra = 3)
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
        // An unresolved same-package/overlay root cannot be attributed to
        // the staged host. Remove it and reacquire normally before showing.
        val r18Owner = r18Active
        if (r18Owner != null && inspection.windowTiming?.ownAttributionAmbiguous == true) {
            failR18Stage(r18Owner, "ambiguousOwnWindow")
            return
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
        val recovery = r14Recovery
        val boundary = if (recovery != null || inspectionProbeForTest != null) synchronized(queueLock) {
            inspectionQueue.pendingRequest() to SystemClock.uptimeMillis()
        } else null
        inspectionProbeForTest?.beforeDecision(request, decision, boundary?.first, inspectionAuthority)
        decisionObservedAt = boundary?.second ?: SystemClock.uptimeMillis()
        val completeMain = inspection.surfaceReason == KeyguardSurfaceReason.MAIN_CONFIRMED &&
            !inspection.rootUnavailable && !inspection.walkTruncated && !inspection.abortedStale
        val mayDefer = recovery != null && !recovery.used && !overlay.isAttached && completeMain &&
            (decision == KeyguardCardVisibility.SHOW_FULL || decision == KeyguardCardVisibility.SHOW_DISCREET)
        if (recovery != null && boundary != null && KeyguardR14ReadmissionPolicy.shouldDefer(
                recovery, inspectionAuthority, settings,
                mayDefer && overlay.eligibleLiveReadmission(settings, lastMaterialProfile), overlay.isAttached,
                surfacePresentationState, completeMain, decision, request, inspectionStartedAt,
                boundary.second, boundary.first,
            )) {
            val used = recovery.copy(used = true, deferredRequestId = request.id,
                pendingRequestId = boundary.first?.id)
            r14Recovery = used
            recordR14Recovery("DEFERRED", used, request, boundary.first,
                observedAt = boundary.second, readStart = inspectionStartedAt, readEnd = inspectionFinishedAt)
            return
        }
        if (recovery?.used == true && !recovery.successorRecorded && recovery.authority.matches(request)) {
            val next = recovery.copy(successorRecorded = true)
            r14Recovery = next
            recordR14Recovery("SUCCESSOR_${decision.name}", next, request, boundary?.first,
                observedAt = decisionObservedAt, readStart = inspectionStartedAt, readEnd = inspectionFinishedAt)
        }
        KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.DECISION, request.id, request.attachGeneration, extra = decision.ordinal)
        val staged = r18Active
        if (staged != null && !overlay.isAttached &&
            (decision == KeyguardCardVisibility.SHOW_DISCREET || decision == KeyguardCardVisibility.SHOW_FULL)) {
            if (!prepareR18Decision(staged, request, inspection, decision, settings)) return
            r18ProofRequestId = request.id
        } else if (staged == null && !overlay.isAttached &&
            (decision == KeyguardCardVisibility.SHOW_DISCREET || decision == KeyguardCardVisibility.SHOW_FULL) &&
            tryStartR18Readmission(request, inspection, settings)) return
        appliedDecision = decision
        when (decision) {
            KeyguardCardVisibility.SHOW_DISCREET -> {
                retryCount = 0
                cancelWakeRetry("shown")
                wakeTiming?.takeIf { it.wakeGeneration == request.wakeGeneration }?.mainKeyguardConfirmedAt = SystemClock.uptimeMillis()
                stopFinancialObservation()
                showEvent = false
                applyPresentation(
                    { FluviFinancialCardPresenter.discreet() },
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
                "pendingRequestIdAtApply" to (synchronized(queueLock) {
                    (inspectionQueue.successorForPreceding(request) ?: inspectionQueue.pendingRequest())?.id
                } ?: "NA"),
            ),
        )
        } finally {
            if (r18ProofRequestId == request.id) r18ProofRequestId = null
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
                ) + mainHandoffEvidence,
            )
        }
        }
    }

    /**
     * Retains at most three overlapping, owned Main scopes for a slow handoff
     * in a FULL diagnostic capture.  Endpoint clock is System.nanoTime;
     * nearby Uptime values remain the cross-event timeline clock.  CPU spans
     * are deliberately not summed because they may be nested.
     */
    private fun slowMainHandoffEvidenceFields(fromNs: Long, toNs: Long): Map<String, Any?> {
        if (!KeyguardCardDiagnostics.wantsFullEvidence() || toNs <= fromNs) return emptyMap()
        val durationNs = toNs - fromNs
        if (durationNs < SLOW_MAIN_HANDOFF_EVIDENCE_NS) return emptyMap()
        val snapshot = mainWorkEvidence.snapshotOverlapping(fromNs, toNs)
        fun span(index: Int): String = snapshot.spans.getOrNull(index)?.let { value ->
            "${KeyguardMainWorkEvidence.kindName(value.kind)}:${value.requestId}:" +
                "${value.startedNs}:${value.endedNs}:${value.cpuNs}:${value.overlapNs}"
        } ?: "NONE"
        return mapOf(
            "mainHandoffEvidenceMode" to "ownedMainScopesOnly",
            "mainHandoffClock" to "System.nanoTime",
            "mainHandoffDurationNs" to durationNs,
            "mainHandoffWorkSession" to snapshot.serviceSession,
            "mainHandoffWorkThreadId" to snapshot.ownerThreadId,
            "mainHandoffWorkOmitted" to snapshot.omittedOverlapping,
            "mainHandoffWorkEvicted" to snapshot.overwrittenSpans,
            "mainHandoffWorkCoverageIncomplete" to snapshot.coverageIncomplete,
            "mainHandoffWorkInvalid" to snapshot.invalidSpans,
            "mainHandoffWorkSpan0" to span(0),
            "mainHandoffWorkSpan1" to span(1),
            "mainHandoffWorkSpan2" to span(2),
        )
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
            (inspectionQueue.successorForPreceding(request) ?: inspectionQueue.pendingRequest())
                ?.takeIf(inspectionAuthority::matches)
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
            val settings = lastSettings ?: FluviKeyguardCardSettings.read(applicationContext)
            val previousFull = overlay.currentPresentationFull()
            val previousAttach = overlayAttachGeneration
            val qualifies = overlay.visibleRootForReadmission() && previousFull != null &&
                overlay.renderModeStatus().effective == KeyguardOrbRenderMode.SURFACE_LIVE &&
                overlay.eligibleLiveReadmission(settings, lastMaterialProfile)
            val hidden = hideImmediately(
                reason = "${decision.name}:${inspection.surfaceReason.name}",
                terminalWake = false,
                triggerReceivedUptimeMs = request.triggerReceivedUptimeMs,
                diagnosticContext = request.diagnosticContext,
                causingInspectionRequestId = request.id,
                awaitingSurfaceWithdrawal = true,
            )
            if (qualifies && hidden != null && !overlay.isAttached && inspectionAuthority.wakeGeneration == request.wakeGeneration) {
                val recovery = KeyguardR14Recovery(
                    id = ++nextR14RecoveryId, authority = inspectionAuthority,
                    settingsGeneration = settings.generation, layoutRevision = settings.layoutRevision,
                    focusGeneration = settings.focus.generation, full = settings.showFinancialDetails,
                    previousFull = requireNotNull(previousFull), hideOperationId = hidden.hideOperationId,
                    previousAttachment = previousAttach, diagnosticContext = hidden.context,
                )
                r14Recovery = recovery
                recordR14Recovery("WITHDRAWN", recovery, request)
            }
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
            synchronized(queueLock) {
                inspectionFreshness.require(inspectionAuthority, successorFreshness)
                publishReadAheadSnapshotLocked()
            }
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
        synchronized(queueLock) {
            inspectionFreshness.require(inspectionAuthority, successorFreshness)
            publishReadAheadSnapshotLocked()
        }
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
            applyPresentation({ FluviFinancialCardPresenter.unavailable(code) }, "invalidFocus:$trigger", diagnosticContext, causingInspectionRequestId)
            return
        }
        transientContentFailure?.takeIf { it.first == focusGeneration }?.let { (_, code) ->
            applyPresentation({ FluviFinancialCardPresenter.unavailable(code) }, "contentUnavailable:$trigger", diagnosticContext, causingInspectionRequestId)
            return
        }
        val cached = renderedFullContent
        val plan = KeyguardCardContentRefreshPolicy.firstOrSurfacePlan(
            focusChanged = focusChanged,
            hasCurrentContent = cached != null && !focusChanged,
            resolveInFlightForFocus = resolvingFocusGeneration == focusGeneration,
        )
        if (cached != null && !focusChanged) {
            applyPresentation({ FluviFinancialCardPresenter.full(cached, showEvent) }, "cached:$trigger", diagnosticContext, causingInspectionRequestId)
        } else if (plan.publishLoading) {
            // First full render only. Repeated same-surface inspection keeps
            // the current amount or existing loading presentation untouched.
            applyPresentation({ FluviFinancialCardPresenter.loading() }, "loading:$trigger", diagnosticContext, causingInspectionRequestId)
        }
        if (r18Active != null && !overlay.isAttached) return
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
                                { FluviFinancialCardPresenter.unavailable(outcome.diagnosticCode) },
                                "invalidFocus:${outcome.diagnosticCode}",
                                diagnosticContext,
                                causingInspectionRequestId,
                            )
                        } else if (stillCurrent && outcome is FullContentResolveResult.Failure) {
                            transientContentFailure = focusGeneration to outcome.diagnosticCode
                            applyPresentation(
                                { FluviFinancialCardPresenter.unavailable(outcome.diagnosticCode) },
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
                        applyPresentation({ FluviFinancialCardPresenter.full(content, showEvent) }, "content", diagnosticContext, causingInspectionRequestId)
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

    private inline fun applyPresentation(
        presentationFactory: () -> com.fluvi.app.runtime.FluviFinancialCardPresentation,
        reason: String,
        diagnosticContext: KeyguardDiagnosticContext? = currentDiagnosticAttempt,
        causingInspectionRequestId: Long? = null,
    ) {
        val owner = if (diagnosticContext?.captureId != null) KeyguardCardDiagnostics.drawEvidenceOwner() else null
        val scope = owner?.let { com.fluvi.app.runtime.FluviFinancialOrbWork.begin() }
        var operation: KeyguardDiagnosticOperation? = null
        try {
            operation = applyResolvedPresentation(presentationFactory(), reason, diagnosticContext,
                causingInspectionRequestId, scope)
        } finally {
            if (scope != null) {
                if (!scope.completed) scope.finish(false, false, returned = false)
                com.fluvi.app.runtime.FluviFinancialOrbWork.end(scope)
                if (KeyguardR15AcquisitionTestHooks.ENABLED) {
                    KeyguardR15AcquisitionTestHooks.financialCompleted(causingInspectionRequestId, scope)
                }
                if (owner === KeyguardCardDiagnostics.drawEvidenceOwner()) {
                    // Fields are converted to strings by the diagnostic worker.
                    // A capture rotation cannot attach this scope to the new owner.
                    runCatching {
                        KeyguardCardDiagnostics.captureEvent(
                            context = this, stage = "R13_FINANCIAL", reason = "scoped",
                            requestId = causingInspectionRequestId, diagnosticContext = diagnosticContext,
                            operation = operation, attachGeneration = scope.attachment,
                            observedUptimeMs = scope.endUptimeMs,
                            deferredFields = { mapOf(
                                "r13Start" to scope.startUptimeMs, "r13End" to scope.endUptimeMs,
                                "r13WallNs" to scope.wallNs, "r13CpuNs" to scope.cpuNs,
                                "r13Construct" to scope.constructions, "r13Demand" to scope.demands,
                                "r13Paint" to scope.paints, "r13PaintDone" to scope.paintCompletions,
                                "r13Bind" to scope.legacyBinds, "r13Noop" to scope.noOp,
                                "r13Returned" to scope.resultReturned, "r13Success" to scope.successful,
                                "r13PaintWallNs" to scope.paintWallNs, "r13PaintCpuNs" to scope.paintCpuNs,
                                "r13PaintMaxWallNs" to scope.paintMaxWallNs,
                                "r13PaintMaxCpuNs" to scope.paintMaxCpuNs,
                                "r13PaintStart" to scope.firstPaintStartUptimeMs,
                                "r13PaintEnd" to scope.lastPaintEndUptimeMs,
                                "r13Route" to scope.routeCode,
                            ) },
                        )
                    }
                }
            }
        }
    }

    private fun applyResolvedPresentation(
        presentation: com.fluvi.app.runtime.FluviFinancialCardPresentation,
        reason: String,
        diagnosticContext: KeyguardDiagnosticContext?,
        causingInspectionRequestId: Long?,
        scope: com.fluvi.app.runtime.FluviFinancialOrbWork.Scope?,
    ): KeyguardDiagnosticOperation? {
        val settings = lastSettings ?: FluviKeyguardCardSettings.read(applicationContext).also { lastSettings = it }
        val directOwner = r18Active?.takeIf { !overlay.isAttached }
        val directToken = directOwner?.token
        if (directOwner != null && directToken != null) {
            val proof = r18ProofRequestId
            if (proof == null || proof != causingInspectionRequestId || directOwner.preparation.full != presentation.full) return null
            val stamp = directToken.stamp
            if (!r18Coordinator.grant(directToken, inspectionAuthority, proof, completeMain = true,
                    finalSystemEligible = true, disclosedFull = presentation.full,
                    selectionRevision = stamp.selectionRevision, materialRevision = stamp.materialRevision,
                    dataRevision = stamp.dataRevision)) {
                failR18Stage(directOwner, "grantRejected")
                return null
            }
            recordR18(directOwner, "GRANT", proof = proof)
        }
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
        setReadAheadShowInProgress(true)
        val result = try {
            overlay.showOrUpdate(presentation, settings, directToken?.stamp?.hostGeneration)
        } finally {
            setReadAheadShowInProgress(false)
            activeWindowDiagnosticOperation = null
        }
        scope?.let {
            it.attachment = showOperation?.attachGeneration ?: overlay.currentAttachGeneration
            it.routeCode = overlay.effectiveRouteForFinancialDiagnostics()
            it.finish(result == KeyguardCardWindow.Result.NO_OP,
                result != KeyguardCardWindow.Result.FAILED && result != KeyguardCardWindow.Result.PENDING)
        }
        if (directOwner != null && directToken != null) {
            if (result != KeyguardCardWindow.Result.ATTACHED) {
                r18Coordinator.discardUnpublishedGrant(directToken)
                if (result == KeyguardCardWindow.Result.FAILED) failR18Stage(directOwner, "inputActivationFailed")
                return null
            }
            val host = directOwner.host
            if (host == null || !r18Coordinator.armInput(directToken, host)) {
                failR18Stage(directOwner, "inputAuthorityFailed")
                return null
            }
        }
        if (result == KeyguardCardWindow.Result.PENDING) {
            if (directOwner == null) r18FallbackWake = wakeEpoch
            return null
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
                    "r12Configured" to overlay.renderModeStatus().configured.name,
                    "r12Effective" to overlay.renderModeStatus().effective.name,
                    "r12Privacy" to if (presentation.full) "full" else "discreet",
                    "r12DisplayHz" to (overlay.displayRefreshRate() ?: "UNOBSERVED"),
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
                val previousAuthority = inspectionAuthority
                overlayAttachGeneration = overlay.currentAttachGeneration
                if (directOwner != null && directToken != null &&
                    !r18Coordinator.bindPresentedAttachment(directToken, previousAuthority,
                        previousAuthority.copy(attachGeneration = overlayAttachGeneration))) {
                    failR18Stage(directOwner, "attachmentAuthorityChanged")
                    return null
                }
                surfacePresentationState = KeyguardSurfacePresentationState.VISIBLE
                knownOwnOverlayIdentity = directOwner?.hostWindowId?.let {
                    KeyguardOwnOverlayIdentity(it, Display.DEFAULT_DISPLAY, overlayAttachGeneration)
                }
                publishInspectionAuthority()
                if (directOwner != null && directToken != null) {
                    // The input host is now enabled. Re-sample the system at
                    // the actual join rather than reusing the wake sample.
                    val finalSystem = readSystemState(KeyguardSystemReadPurpose.ADMISSION)
                    val stamp = directToken.stamp
                    val permit = if (finalSystem.eligible) r18Coordinator.queueReveal(directToken,
                        inspectionAuthority, completeMainStillCurrent = true, finalSystemEligible = true,
                        selectionRevision = stamp.selectionRevision, materialRevision = stamp.materialRevision,
                        dataRevision = stamp.dataRevision) else null
                    if (permit == null) {
                        failR18Stage(directOwner, "finalPublicationCheck")
                        return null
                    }
                    recordR18(directOwner, "INPUT_ARMED")
                    recordR18(directOwner, "REVEAL_QUEUED")
                    overlay.revealR18(directOwner.preparation,
                        boundary = { r18Coordinator.crossSubmitBoundary(permit) }, done = { success ->
                            if (r18Active !== directOwner || directOwner.token !== directToken) return@revealR18
                            if (success && r18Coordinator.revealSubmitted(permit)) recordR18(directOwner, "REVEAL_APPLIED")
                            else if (r18Coordinator.snapshot().grant != KeyguardOrbPresentationCoordinator.Grant.REVOKED &&
                                r18Coordinator.snapshot().grant != KeyguardOrbPresentationCoordinator.Grant.RETIRED)
                                failR18Stage(directOwner, "revealFailed")
                        })
                }
                r14Recovery?.let { recordR14Recovery("ATTACHED", it, requestId = causingInspectionRequestId,
                    showOperation = showOperation?.showOperationId) }
                preservePendingReconciliation("attach", requirePending = true)
                r14Recovery = null
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
            KeyguardCardWindow.Result.PENDING -> Unit
            KeyguardCardWindow.Result.FAILED -> {
                r14Recovery?.let { recordR14Recovery("ATTACH_FAILED", it, requestId = causingInspectionRequestId,
                    showOperation = showOperation?.showOperationId) }
                r14Recovery = null
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
        return showOperation
    }

    private fun toggleView() {
        if (appliedDecision != KeyguardCardVisibility.SHOW_FULL) return
        val content = renderedFullContent ?: return
        showEvent = !showEvent
        applyPresentation({ FluviFinancialCardPresenter.full(content, showEvent) }, "toggle")
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
    private fun recoverySlot(slot: KeyguardOrbOwnershipSlotSnapshot?): String = slot?.let {
        "slot:${it.slotId},use:${it.useGeneration},lease:${it.lease?.attachment ?: "NA"}/${it.lease?.generation ?: "NA"},state:${it.state},retired:${it.retired},receipt:${it.callbackReceived},fence:${it.fencePending}"
    } ?: "UNOBSERVED"

    /** Formatted only on the diagnostic consumer from bounded Worker samples. */
    private fun coldWork(sample: KeyguardOrbColdWorkSnapshot?, part: Int): String {
        if (sample == null) return "UNOBSERVED"
        return when (part) {
            0 -> "renderer:${sample.renderer},lease:${sample.attachment}/${sample.generation},slot:${sample.slot}/${sample.use},key:${sample.keyHash},program:${sample.programHash},size:${sample.width}x${sample.height},passes:${sample.passes},prev:${sample.previousValid},primed:${sample.primed}"
            1 -> "config:${sample.configuredAt},callback:${sample.callbackAt ?: "UNOBSERVED"},pending:${sample.callbackPending},frame:${sample.frameAt},frameNs:${sample.frameNs},workerQueue:${sample.workerQueueAt ?: "UNOBSERVED"}"
            2 -> "resources:${sample.resourcesStart}/${sample.resourcesEnd},shader:${sample.shaderStart}/${sample.shaderEnd},submit:${sample.submitBegin ?: "UNOBSERVED"}/${sample.submitEnd ?: "UNOBSERVED"}"
            else -> "result:${sample.resultAt ?: "UNOBSERVED"},status:${sample.resultStatus ?: "UNOBSERVED"},fence:${sample.fenceValid ?: "UNOBSERVED"},state:${sample.disposition}"
        }
    }

    private fun hideImmediately(
        reason: String,
        terminalWake: Boolean = true,
        awaitingSurfaceWithdrawal: Boolean = false,
        triggerReceivedUptimeMs: Long? = null,
        diagnosticContext: KeyguardDiagnosticContext? = currentDiagnosticAttempt,
        causingInspectionRequestId: Long? = null,
    ): KeyguardDiagnosticOperation? {
        KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.HIDE_ENTER, causingInspectionRequestId ?: 0L, overlayAttachGeneration)
        val r18AtHide = r18Active
        sealR18(inspectionAuthority, Long.MAX_VALUE, reason)
        publishReadAheadState(invalidate = true)
        val wasAttachedBefore = ::overlay.isInitialized && overlay.isAttached
        if (terminalWake || wasAttachedBefore) clearR14Recovery(if (terminalWake) "terminal" else "newWithdrawal")
        // Also revoke checks created since an already-idempotent terminal
        // cleanup. This does not wait for their platform calls to return.
        if (terminalWake) systemSampler.clearPending()
        if (!KeyguardTerminalHideGate.shouldProcess(
                terminalWake = terminalWake,
                overlayAttached = wasAttachedBefore || r18AtHide != null,
                serviceSession = session.get(),
                visibilityEpoch = visibilityEpoch.get(),
                previous = terminalHideState,
            )
        ) {
            // The first terminal transition already invalidated all attach
            // authority. Repeating it would only churn epochs, diagnostics and
            // material cleanup while the root is known detached.
            KeyguardCardDiagnostics.recordHiddenNoop(this)
            KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.HIDE_RETURN, causingInspectionRequestId ?: 0L, overlayAttachGeneration, extra = 1)
            return null
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
            r18WakeOpen = false
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
        publishReadAheadState()
        appliedDecision = KeyguardCardVisibility.HIDDEN_UNKNOWN
        showEvent = false
        val dragWasActive = ::overlay.isInitialized && overlay.isDragActive
        var removeReturnedAt: Long? = null
        var localHideBeginAt: Long? = null
        var attachedRootRemoved = false
        var retiredSurface: RetiredSurfaceEvidence? = null
        if (::overlay.isInitialized) {
            localHideBeginAt = SystemClock.uptimeMillis()
            activeWindowDiagnosticOperation = hideOperation
            val removed = try {
                val onLayerHideCommitted: ((Long) -> Unit)? =
                    if (wasAttachedBefore && hideOperation.context?.captureId != null &&
                        KeyguardCardDiagnostics.wantsEvent("ISOLATED_LAYER_HIDE_COMMIT_RECEIVED")
                    ) { receivedAt ->
                        // This closure is bound to the original operation;
                        // never recover ownership from a later active hide.
                        traceKeyguard(
                            "ISOLATED_LAYER_HIDE_COMMIT_RECEIVED", "transactionCommitNotPhysicalRemoval",
                            observedUptimeMs = receivedAt,
                            attachGeneration = hideOperation.attachGeneration,
                            operation = hideOperation,
                        )
                    } else null
                val onRetirementEvent: ((KeyguardOrbRetirementEvent) -> Unit)? =
                    if (wasAttachedBefore && hideOperation.context?.captureId != null &&
                        KeyguardCardDiagnostics.wantsEvent("R09_RETIREMENT")
                    ) { event ->
                        traceKeyguard("R09_RETIREMENT", event.reason,
                            observedUptimeMs = event.observedAtUptimeMs,
                            attachGeneration = hideOperation.attachGeneration,
                            operation = hideOperation,
                            deferredFields = { mapOf(
                                "r09Stage" to event.stage,
                                "r09Lease" to "${event.lease.attachment}/${event.lease.generation}",
                                "r09Child" to event.childIdentity,
                                "r09Slot" to (event.slotId ?: "UNOBSERVED"),
                                "r09Use" to (event.useGeneration ?: "UNOBSERVED"),
                            ) })
                    } else null
                val onSurfaceRevoked: ((Long, Long, com.fluvi.app.lockscreen.material.KeyguardOrbSurfaceMetrics,
                    com.fluvi.app.lockscreen.material.KeyguardOrbSurfaceMetrics.HolderOperation) -> Unit)? =
                    if (wasAttachedBefore && hideOperation.context?.captureId != null &&
                        KeyguardCardDiagnostics.wantsEvent("R15_SURFACE_REVOKED")) {
                        { attach, generation, metrics, atRevoke ->
                            retiredSurface = RetiredSurfaceEvidence(attach, generation, metrics, atRevoke)
                        }
                    } else null
                overlay.hide(onLayerHideCommitted, onRetirementEvent, onSurfaceRevoked)
            } finally {
                activeWindowDiagnosticOperation = null
            }
            removeReturnedAt = SystemClock.uptimeMillis()
            attachedRootRemoved = wasAttachedBefore && removed && !overlay.isAttached
            finishR18AfterWindow(r18AtHide)
            if (r18Active == null && !overlay.isAttached && FluviKeyguardCardServiceRegistry.connected &&
                lastSettings?.requested == true && r18FallbackWake != wakeEpoch &&
                reason != "unbind" && reason != "destroy" && reason != "settings") {
                overlay.prepareR18()
                refreshR18RouteOnMain()
            }
            publishReadAheadState()
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
                        "r09Placement" to "submitted:${summary.positionSubmissions},suppressed:${summary.positionSuppressions}",
                        "r10Cold0" to coldWork(summary.coldWork.filter { it.attachment == 0L }.getOrNull(0), 0),
                        "r10Cold0b" to coldWork(summary.coldWork.filter { it.attachment == 0L }.getOrNull(0), 1),
                        "r10Cold0c" to coldWork(summary.coldWork.filter { it.attachment == 0L }.getOrNull(0), 2),
                        "r10Cold0d" to coldWork(summary.coldWork.filter { it.attachment == 0L }.getOrNull(0), 3),
                        "r10Cold1" to coldWork(summary.coldWork.filter { it.attachment == 0L }.getOrNull(1), 0),
                        "r10Cold1b" to coldWork(summary.coldWork.filter { it.attachment == 0L }.getOrNull(1), 1),
                        "r10Cold1c" to coldWork(summary.coldWork.filter { it.attachment == 0L }.getOrNull(1), 2),
                        "r10Cold1d" to coldWork(summary.coldWork.filter { it.attachment == 0L }.getOrNull(1), 3),
                        "r10Live0" to coldWork(summary.coldWork.filter { it.attachment > 0L }.getOrNull(0), 0),
                        "r10Live0b" to coldWork(summary.coldWork.filter { it.attachment > 0L }.getOrNull(0), 1),
                        "r10Live0c" to coldWork(summary.coldWork.filter { it.attachment > 0L }.getOrNull(0), 2),
                        "r10Live0d" to coldWork(summary.coldWork.filter { it.attachment > 0L }.getOrNull(0), 3),
                        "r10Live1" to coldWork(summary.coldWork.filter { it.attachment > 0L }.getOrNull(1), 0),
                        "r10Live1b" to coldWork(summary.coldWork.filter { it.attachment > 0L }.getOrNull(1), 1),
                        "r10Live1c" to coldWork(summary.coldWork.filter { it.attachment > 0L }.getOrNull(1), 2),
                        "r10Live1d" to coldWork(summary.coldWork.filter { it.attachment > 0L }.getOrNull(1), 3),
                        "r09FirstWork" to (summary.firstWork?.let {
                            "attach:${it.attachment},gen:${it.generation},request:${it.requestedAt},start:${it.startedAt ?: "UNOBSERVED"},result:${it.resultAt ?: "UNOBSERVED"},status:${it.resultStatus ?: "UNOBSERVED"}"
                        } ?: "UNOBSERVED"),
                        "r09FirstFrames" to (summary.firstWork?.let {
                            "workerAck:${it.firstAt ?: "UNOBSERVED"}:${it.firstSlot ?: "UNOBSERVED"}/${it.firstUse ?: "UNOBSERVED"},steadyApply:${it.secondAt ?: "UNOBSERVED"}:${it.secondSlot ?: "UNOBSERVED"}/${it.secondUse ?: "UNOBSERVED"}"
                        } ?: "UNOBSERVED"),
                        "isolatedFirstIdentity" to (summary.isolatedFirstHandoff?.let {
                            "first/direct:attach:${it.attachment},generation:${it.generation},slot:${it.slotId},use:${it.useGeneration},child:${it.childIdentity}"
                        } ?: "UNOBSERVED"),
                        "isolatedFirstReady" to (summary.isolatedFirstHandoff?.times?.let {
                            "ready:${it.readyAtUptimeMs},post:${it.postedAtUptimeMs},main:${it.mainEntryAtUptimeMs},applyBegin:${it.applyBeginAtUptimeMs},applyEnd:${it.applyEndAtUptimeMs}"
                        } ?: "UNOBSERVED"),
                        "isolatedFirstCommit" to (summary.isolatedFirstHandoff?.let {
                            "receipt:${it.commitReceiptAtUptimeMs ?: "UNOBSERVED"},main:${it.commitMainAtUptimeMs ?: "UNOBSERVED"},bootstrapRetired:${it.bootstrapRetiredAtUptimeMs ?: "UNOBSERVED"}"
                        } ?: "UNOBSERVED"),
                        "r08Route" to summary.effectiveRoute,
                        "r08Origin" to (summary.recovery?.let {
                            "${if (it.inherited) "inherited" else "entered"}:renderer:${it.rendererId},attach:${it.originAttachment},gen:${it.originGeneration},child:${it.childId},grant:${it.grantId},cause:${it.reason}"
                        } ?: "UNOBSERVED"),
                        "r08Times" to (summary.recovery?.let {
                            "start:${it.startedAt},offer:${it.offeredAt},claim:${it.claimedAt ?: "UNOBSERVED"},draw:${it.firstViewDrawAt ?: "UNOBSERVED"},restore:${it.restoredAt ?: "UNOBSERVED"},n:${it.opportunities}"
                        } ?: "UNOBSERVED"),
                        "r08Anchor" to (summary.recovery?.anchor?.let {
                            "elapsed:${it.elapsedSeconds},phase:${it.phase},background:${it.backgroundPhase},interior:${it.interiorPhase}"
                        } ?: "UNOBSERVED"),
                        "r08Transition" to (summary.recovery?.transitionPreserved ?: "UNOBSERVED"),
                        "r08Slot0" to recoverySlot(summary.recovery?.slots?.getOrNull(0)),
                        "r08Slot1" to recoverySlot(summary.recovery?.slots?.getOrNull(1)),
                        "r08Slot2" to recoverySlot(summary.recovery?.slots?.getOrNull(2)),
                        "r08Worker" to (summary.worker?.takeIf { it.workerSampleAtUptimeMs > 0L }?.let {
                            val reason = when (it.workerBlockReason) {
                                1 -> "notEligible"; 2 -> "readyMain"; 3 -> "noFree"; 4 -> "wrongSize"; 5 -> "active"; else -> "unknown"
                            }
                            "seq:${it.workerSampleSequence},age:${(summary.observedAt - it.workerSampleAtUptimeMs).coerceAtLeast(0L)},desired:${it.workerDesiredAttachment}/${it.workerDesiredGeneration},attached:${it.workerAttachedAttachment}/${it.workerAttachedGeneration},reason:$reason"
                        } ?: "UNOBSERVED"),
                        "r08Grant" to (summary.worker?.takeIf { it.workerSampleAtUptimeMs > 0L }?.let {
                            "id:${it.workerGrantIdentity},lease:${it.workerGrantAttachment}/${it.workerGrantGeneration},active:${it.workerGrantActive},running:${it.workerRunning}"
                        } ?: "UNOBSERVED"),
                        "r08Progress" to (summary.worker?.takeIf { it.workerSampleAtUptimeMs > 0L }?.let {
                            "completedAt:${it.workerLastCompletionAtUptimeMs.takeIf { value -> value > 0L } ?: "UNOBSERVED"},inFlight:${it.inFlight},ready:${it.ready},owned:${it.compositorOwned}"
                        } ?: "UNOBSERVED"),
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
        retiredSurface?.let { (attachment, generation, metrics, atRevoke) ->
            // Bound to the actual captured child and hide operation. Worker
            // completion after removal can update only this generation's
            // primitive metrics, not the current service operation.
            traceKeyguard("R15_SURFACE_REVOKED", "synchronousAccessClosure",
                observedUptimeMs = removeReturnedAt, attachGeneration = attachment,
                operation = hideOperation, surfaceMetrics = metrics, deferredFields = { mapOf(
                    "r15TargetAttachment" to attachment, "r15Generation" to generation,
                    "r15AtRevoke" to "${atRevoke.coherent}:${atRevoke.id}:${atRevoke.lockEnter ?: "UNOBSERVED"}/${atRevoke.lockReturn ?: "UNOBSERVED"}:${atRevoke.drawReturn ?: "UNOBSERVED"}:${atRevoke.postEnter ?: "UNOBSERVED"}/${atRevoke.postReturn ?: "UNOBSERVED"}:${atRevoke.recordAt ?: "UNOBSERVED"}",
                ) })
        }
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
        KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.HIDE_RETURN, causingInspectionRequestId ?: 0L, overlayAttachGeneration)
        return hideOperation.takeIf { attachedRootRemoved }
    }

    /** Both callbacks arrive after their draw stacks have unwound. The event
     * still carries its original attach id, so a wake A callback cannot write
     * timing into wake B after a fast lock/unlock/reattach sequence. */
    private fun recordFirstRootPreDraw(event: KeyguardFirstDrawEvent) {
        val owner = firstDrawOwner ?: return
        if (!owner.accepts(event, session.get(), wakeEpoch, overlayAttachGeneration)) return
        traceKeyguard("FIRST_ROOT_PREDRAW", "observed", attachGeneration = event.attachGeneration,
            observedUptimeMs = event.observedAtUptimeMs, operation = owner.diagnosticOperation,
            deferredFields = { mapOf("r09RootSize" to "${event.rootWidth}x${event.rootHeight}",
                "r09TargetSize" to if (event.targetWidth > 0 && event.targetHeight > 0)
                    "${event.targetWidth}x${event.targetHeight}" else "UNOBSERVED",
                "r09AttachState" to event.attachStateAtRegistration) })
    }

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
            "r08EffectiveRoute" to values?.effectiveRoute,
            "r08Attachment" to (values?.attachment ?: 0L),
            "r08RecoveryGeneration" to (values?.recoveryGeneration ?: 0L),
            "r08RecoveryRestoredAt" to values?.recoveryRestoredAt,
            "r08AttachmentShaderCalls" to (values?.attachmentShaderCalls ?: 0),
            "r08AttachmentShaderTraversals" to (values?.attachmentShaderTraversals ?: 0L),
            "r08AttachmentPhaseAdvances" to (values?.attachmentPhaseAdvances ?: 0),
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
        if (r18Active != null) {
            hideImmediately("r18Redact:$reason", terminalWake = false)
            stopFinancialObservation()
            return
        }
        visibilityEpoch.incrementAndGet()
        publishInspectionAuthority()
        showEvent = false
        appliedDecision = KeyguardCardVisibility.SHOW_DISCREET
        if (::overlay.isInitialized && overlay.isAttached) {
            applyPresentation({ FluviFinancialCardPresenter.discreet() }, "redact:$reason")
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
        KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.CLEANUP_ENTER, attachment = overlayAttachGeneration)
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
        KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.CLEANUP_EXIT, attachment = overlayAttachGeneration)
    }

    companion object {
        private val RETRY_DELAYS_MS = longArrayOf(16L, 32L, 64L)
        /** One display interval: below this scalar handoff timing remains
         * available, but a FULL capture does not copy correlation spans. */
        private const val SLOW_MAIN_HANDOFF_EVIDENCE_NS = 16_000_000L
        const val ACTION_OPEN_FOCUS = "com.fluvi.app.lockscreen.OPEN_FOCUS"
        const val EXTRA_MODE = "com.fluvi.app.lockscreen.MODE"
        const val EXTRA_AXIS = "com.fluvi.app.lockscreen.AXIS"
        const val EXTRA_DIRECTION = "com.fluvi.app.lockscreen.DIRECTION"
        const val EXTRA_CATEGORY = "com.fluvi.app.lockscreen.CATEGORY"
    }
}
