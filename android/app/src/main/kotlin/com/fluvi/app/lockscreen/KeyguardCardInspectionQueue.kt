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
