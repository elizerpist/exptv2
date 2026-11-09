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
    val eventTimeUptimeMs: Long? = null,
    /** Captured before the worker is queued; a late callback must not be
     * relabelled with the wake/attempt that happens to be current later. */
    val diagnosticContext: KeyguardDiagnosticContext? = null,
    val triggerReceivedUptimeMs: Long? = null,
)

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
        pending = request
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
