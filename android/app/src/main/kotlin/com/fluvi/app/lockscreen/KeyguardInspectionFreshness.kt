package com.fluvi.app.lockscreen

/** A freshness boundary belongs to publication authority, not to a retry
 * timer. Cancelling/coalescing a request cannot fulfil it. The one reader
 * takes a ticket immediately before acquisition and acknowledges only an
 * actually established cache boundary. No platform work runs under this lock.
 */
internal class KeyguardInspectionFreshness {
    data class Ticket(
        val authority: KeyguardInspectionAuthority,
        val revision: Long,
        val reason: KeyguardWindowFreshness,
    )

    private var authority: KeyguardInspectionAuthority? = null
    private var revision = 0L
    private var required = KeyguardWindowFreshness.FRAMEWORK_EVENT

    @Synchronized fun publish(current: KeyguardInspectionAuthority) {
        if (authority == current) return
        authority = current
        revision += 1L
        required = KeyguardWindowFreshness.FRAMEWORK_EVENT
    }

    @Synchronized fun require(current: KeyguardInspectionAuthority, reason: KeyguardWindowFreshness) {
        if (authority != current || !reason.requiresCacheClear) return
        revision += 1L
        required = reason
    }

    @Synchronized fun beforeRead(request: KeyguardCardInspectionRequest): Ticket? {
        val current = authority?.takeIf { it.matches(request) } ?: return null
        return Ticket(current, revision, required)
    }

    @Synchronized fun boundaryEstablished(ticket: Ticket) {
        // A late clear cannot consume a newer contradiction, nor a boundary
        // belonging to another wake/attachment/session.
        if (authority != ticket.authority || revision != ticket.revision) return
        required = KeyguardWindowFreshness.FRAMEWORK_EVENT
    }
}
