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
