package com.fluvi.app.lockscreen

/** Immutable authority captured when an inspection is requested, rather than
 * when its worker eventually gets CPU time. */
internal data class KeyguardCardInspectionRequest(
    val id: Long,
    val trigger: String,
    val session: Long,
    val visibilityEpoch: Long,
    val interactionEpoch: Long,
    val attachGeneration: Long,
    val wakeGeneration: Long,
    val queuedAtUptimeMs: Long,
    /** Freshness is captured with this request. It directs only reader cache
     * invalidation; it never grants visibility from a previous surface. */
    val windowFreshness: KeyguardWindowFreshness = KeyguardWindowFreshness.FRAMEWORK_EVENT,
    val eventTimeUptimeMs: Long? = null,
    /** Captured before the worker is queued; a late callback must not be
     * relabelled with the wake/attempt that happens to be current later. */
    val diagnosticContext: KeyguardDiagnosticContext? = null,
    val triggerReceivedUptimeMs: Long? = null,
) {
    /** Carry an unserved event, never an acquired answer, across a local
     * withdrawal in the SAME service/wake. The new request must reacquire
     * under current authority; event/callback origins remain immutable. */
    fun reacquireAfterWithdrawal(
        authority: KeyguardInspectionAuthority,
        newId: Long,
        queuedAt: Long,
        freshness: KeyguardWindowFreshness,
    ): KeyguardCardInspectionRequest? {
        if (session != authority.serviceSession || wakeGeneration != authority.wakeGeneration) return null
        require(newId != id)
        return copy(
            id = newId,
            visibilityEpoch = authority.visibilityEpoch,
            interactionEpoch = authority.interactionEpoch,
            attachGeneration = authority.attachGeneration,
            queuedAtUptimeMs = queuedAt,
            windowFreshness = if (windowFreshness.requiresCacheClear && !freshness.requiresCacheClear) windowFreshness else freshness,
        )
    }
}

/**
 * The worker never reads the service's individual mutable generation fields.
 * Its owner publishes this one immutable value whenever lifecycle authority
 * changes, so a Binder call that cannot be interrupted still stops before the
 * next platform/node request when it returns.
 */
internal data class KeyguardInspectionAuthority(
    val serviceSession: Long,
    val visibilityEpoch: Long,
    val wakeGeneration: Long,
    val interactionEpoch: Long,
    val attachGeneration: Long,
) {
    fun matches(request: KeyguardCardInspectionRequest): Boolean =
        serviceSession == request.session &&
            visibilityEpoch == request.visibilityEpoch &&
            wakeGeneration == request.wakeGeneration &&
            interactionEpoch == request.interactionEpoch &&
            attachGeneration == request.attachGeneration
}

/** Inert unless the Android instrumentation fixture installs it. Acquisition
 * and start observations are worker-owned; apply observations are Main-owned.
 * No live Event, node or View is retained in this boundary. */
internal interface KeyguardInspectionProbeForTest {
    fun snapshots(request: KeyguardCardInspectionRequest, actual: List<KeyguardWindowSnapshot>): List<KeyguardWindowSnapshot> = actual
    fun started(request: KeyguardCardInspectionRequest) {}
    fun beforeApply(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility) {}
    fun afterApply(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility) {}
}

internal data class KeyguardInspectionStateForTest(
    val authority: KeyguardInspectionAuthority,
    val pending: KeyguardCardInspectionRequest?,
    val wake: Long?,
    val attached: Boolean,
    val retryCount: Int,
)

/** Known, positively identified accessibility-overlay ownership.  It is
 * deliberately narrower than a package match: an Activity or another service
 * overlay must still follow the safe discovery path. */
internal data class KeyguardOwnOverlayIdentity(
    val windowId: Int,
    val displayId: Int,
    val attachGeneration: Long,
)

/** Pure owner for the one physical wake observed through several Android
 * callbacks. It has no knowledge of Views or accessibility nodes, so ordering
 * behaviour is testable without turning callbacks into a debounce. */
internal data class KeyguardWakeCycle(
    val id: Long,
    val firstSignal: String,
    val firstObservedAtUptimeMs: Long,
    val screenOnReceivedAtUptimeMs: Long? = null,
)

internal data class KeyguardWakeCycleTransition(
    val cycle: KeyguardWakeCycle,
    val started: Boolean,
    val screenOnJoined: Boolean,
)

internal class KeyguardWakeCycleOwner {
    private var open: KeyguardWakeCycle? = null

    fun beginOrJoin(nextId: Long, source: String, observedAtUptimeMs: Long): KeyguardWakeCycleTransition {
        val existing = open
        if (existing != null) {
            val updated = if (source == "wake" && existing.screenOnReceivedAtUptimeMs == null) {
                existing.copy(screenOnReceivedAtUptimeMs = observedAtUptimeMs)
            } else existing
            open = updated
            return KeyguardWakeCycleTransition(updated, started = false, screenOnJoined = source == "wake")
        }
        val created = KeyguardWakeCycle(
            id = nextId,
            firstSignal = source,
            firstObservedAtUptimeMs = observedAtUptimeMs,
            screenOnReceivedAtUptimeMs = observedAtUptimeMs.takeIf { source == "wake" },
        )
        open = created
        return KeyguardWakeCycleTransition(created, started = true, screenOnJoined = false)
    }

    fun current(): KeyguardWakeCycle? = open
    fun end() { open = null }
}

/** A service owns one of these behind its queue lock. It permits one Binder
 * walk and one latest replacement request; it can never grow a wake-event
 * backlog. */
internal class KeyguardCardInspectionQueue {
    private var active: KeyguardCardInspectionRequest? = null
    private var pending: KeyguardCardInspectionRequest? = null

    /** @return true only when the caller must start a worker immediately. */
    fun offer(request: KeyguardCardInspectionRequest): Boolean {
        if (active == null) {
            active = request
            return true
        }
        // Coalescing may replace an unstarted wake request with an ordinary
        // window event. Preserve its still-unperformed freshness boundary,
        // while keeping the new event/time/authority as the actual request.
        val previous = pending
        pending = if (previous != null && previous.windowFreshness.requiresCacheClear &&
            !request.windowFreshness.requiresCacheClear &&
            previous.session == request.session && previous.wakeGeneration == request.wakeGeneration &&
            previous.visibilityEpoch == request.visibilityEpoch &&
            previous.interactionEpoch == request.interactionEpoch &&
            previous.attachGeneration == request.attachGeneration
        ) request.copy(windowFreshness = previous.windowFreshness) else request
        return false
    }

    /** Completes [request] and returns exactly one coalesced successor. */
    fun complete(request: KeyguardCardInspectionRequest): KeyguardCardInspectionRequest? {
        if (active != request) return null
        val next = pending
        pending = null
        active = next
        return next
    }

    fun clearPending() {
        pending = null
    }

    fun activeRequest(): KeyguardCardInspectionRequest? = active
    fun pendingRequest(): KeyguardCardInspectionRequest? = pending

    /** Applying UNKNOWN has not released active yet. That completed cause is
     * not future work capable of replacing its fallback observation. */
    fun hasCurrentWork(authority: KeyguardInspectionAuthority, excludingId: Long? = null): Boolean =
        (active?.let { it.id != excludingId && authority.matches(it) } == true) ||
            (pending?.let { it.id != excludingId && authority.matches(it) } == true)
}

/** Fast hide is intentionally based only on immediately knowable terminal
 * state. It never treats a Fluvi pointer event as exclusion. */
internal object KeyguardCardFastHideGate {
    fun shouldHide(displayInteractive: Boolean, displayOff: Boolean, keyguardLocked: Boolean): Boolean =
        !displayInteractive || displayOff || !keyguardLocked
}

/** Tracks a completed terminal exclusion separately from attachment state.
 * A detached root can still have a live inspection before the first hide;
 * only the same already-invalidated state is a genuine no-op. */
internal data class KeyguardTerminalHideState(
    val serviceSession: Long,
    val invalidatedVisibilityEpoch: Long,
)

internal object KeyguardTerminalHideGate {
    fun shouldProcess(
        terminalWake: Boolean,
        overlayAttached: Boolean,
        serviceSession: Long,
        visibilityEpoch: Long,
        previous: KeyguardTerminalHideState?,
    ): Boolean = !terminalWake || overlayAttached || previous?.serviceSession != serviceSession ||
        previous.invalidatedVisibilityEpoch != visibilityEpoch
}

/**
 * Surface uncertainty is not itself a terminal device transition.  Keep this
 * deliberately small and close to the inspection queue: it describes only
 * what an already-authorised inspection may do after it cannot prove the
 * main keyguard surface.  The service remains the owner of the actual Window
 * lifecycle and the terminal gates.
 */
internal enum class KeyguardSurfacePresentationState {
    AWAITING_MAIN_SURFACE,
    VISIBLE,
    WITHDRAWN_AWAITING_SURFACE,
    TERMINALLY_EXCLUDED,
}

internal enum class KeyguardUnknownSurfaceFollowup {
    CONTINUE_PENDING,
    SCHEDULE_FALLBACK,
    WAIT_FOR_EVENT,
}

internal data class KeyguardUnknownSurfaceTransition(
    val nextState: KeyguardSurfacePresentationState,
    val withdrawVisibleOverlay: Boolean,
    val invalidatesVisibleAuthority: Boolean,
    val followup: KeyguardUnknownSurfaceFollowup,
)

/** Production waiting policy for UNKNOWN and recoverable OCCLUDED, used by
 * [FluviKeyguardCardService]. Neither is permission to show. In
 * particular, the active request which is currently being applied is never
 * passed as [hasCompatiblePendingRequest]; only a queued successor counts as
 * future work. */
internal object KeyguardAwaitingSurfacePolicy {
    fun onUnknown(
        current: KeyguardSurfacePresentationState,
        overlayAttached: Boolean,
        hasCompatiblePendingRequest: Boolean,
        retryAvailable: Boolean,
    ): KeyguardUnknownSurfaceTransition {
        val withdrawing = overlayAttached
        val next = if (withdrawing) {
            KeyguardSurfacePresentationState.WITHDRAWN_AWAITING_SURFACE
        } else if (current == KeyguardSurfacePresentationState.WITHDRAWN_AWAITING_SURFACE) {
            KeyguardSurfacePresentationState.WITHDRAWN_AWAITING_SURFACE
        } else {
            KeyguardSurfacePresentationState.AWAITING_MAIN_SURFACE
        }
        val followup = when {
            hasCompatiblePendingRequest -> KeyguardUnknownSurfaceFollowup.CONTINUE_PENDING
            retryAvailable -> KeyguardUnknownSurfaceFollowup.SCHEDULE_FALLBACK
            else -> KeyguardUnknownSurfaceFollowup.WAIT_FOR_EVENT
        }
        return KeyguardUnknownSurfaceTransition(
            nextState = next,
            withdrawVisibleOverlay = withdrawing,
            invalidatesVisibleAuthority = withdrawing,
            followup = followup,
        )
    }
}
