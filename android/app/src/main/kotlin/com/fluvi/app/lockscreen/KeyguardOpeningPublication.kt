package com.fluvi.app.lockscreen

/** Route choice for the completed-positive path. The service supplies its
 * validated, Main-published route snapshot; this is never a visibility grant. */
internal object KeyguardOpeningRoutePolicy {
    fun useCompletedHandoff(backend: String): Boolean = backend == "STOCK"
}

/** A bounded completed-read handoff. The owner serializes every operation
 * with the same lock as [KeyguardCardInspectionQueue]; this class does not
 * post, render, inspect platform objects, or grant visibility. */
internal class KeyguardOpeningPublication<T> {
    data class Ticket<T>(val request: KeyguardCardInspectionRequest, val value: T)
    data class Notice(val session: Long, val serial: Long)
    data class Parked(val noticeToPost: Notice?)
    data class Superseded<T>(val ticket: Ticket<T>, val successor: KeyguardCardInspectionRequest)
    data class Discarded<T>(val ticket: Ticket<T>, val successor: KeyguardCardInspectionRequest?)

    private var waiting: Ticket<T>? = null
    private var claimed: Ticket<T>? = null
    private var scheduled: Notice? = null
    private var nextSerial = 0L

    /** The worker has finished physically reading. A pending request must be
     * reconciled or promoted before this can become a Main-owned ticket. */
    fun park(queue: KeyguardCardInspectionQueue, request: KeyguardCardInspectionRequest, value: T): Parked? {
        if (waiting != null || claimed != null || !queue.canPublishCompleted(request) ||
            queue.pendingRequest() != null) return null
        waiting = Ticket(request, value)
        val existing = scheduled
        val notice = if (existing == null || existing.session != request.session) {
            Notice(request.session, ++nextSerial).also { scheduled = it }
        } else null
        return Parked(notice)
    }

    /** Called only after the caller has checked current route, freshness and
     * authority and the real newer request is already in the queue. */
    fun supersede(queue: KeyguardCardInspectionQueue,
                  expected: KeyguardCardInspectionRequest,
                  successor: KeyguardCardInspectionRequest): Superseded<T>? {
        val old = waiting?.takeIf { it.request == expected } ?: return null
        val next = queue.handoffCompleted(expected, successor) ?: return null
        waiting = null
        return Superseded(old, next)
    }

    /** A notice can claim only a current ticket from its own service session.
     * A late notice finding no ticket consumes only itself, never newer work. */
    fun claim(queue: KeyguardCardInspectionQueue, notice: Notice): Ticket<T>? {
        if (scheduled != notice) return null
        scheduled = null
        val ticket = waiting ?: return null
        if (ticket.request.session != notice.session || !queue.canPublishCompleted(ticket.request)) {
            waiting = null
            return null
        }
        waiting = null
        claimed = ticket
        return ticket
    }

    fun finish(queue: KeyguardCardInspectionQueue, request: KeyguardCardInspectionRequest): KeyguardCardInspectionRequest? {
        if (claimed?.request != request) return null
        claimed = null
        return queue.complete(request)
    }

    /** Hide/lifecycle changes invalidate an unpublished ticket, not a claimed
     * Main operation or the active owner of any subsequent physical read. */
    fun discard(queue: KeyguardCardInspectionQueue, expected: KeyguardCardInspectionRequest): Discarded<T>? {
        val ticket = waiting?.takeIf { it.request == expected } ?: return null
        if (!queue.canPublishCompleted(expected)) return null
        waiting = null
        return Discarded(ticket, queue.complete(expected))
    }

    fun waitingTicket(): Ticket<T>? = waiting
    fun waitingRequest(): KeyguardCardInspectionRequest? = waiting?.request
    fun claimedRequest(): KeyguardCardInspectionRequest? = claimed?.request
    fun waitingForNotice(notice: Notice): KeyguardCardInspectionRequest? =
        waiting?.request?.takeIf {
            scheduled == notice && it.session == notice.session
        }

    /** The only notification for this ticket failed; allow a successor to
     * arrange its own notification instead of inheriting a dead one. */
    fun discardFailedNotice(queue: KeyguardCardInspectionQueue, notice: Notice): Discarded<T>? {
        val request = waitingForNotice(notice) ?: return null
        val discarded = discard(queue, request) ?: return null
        scheduled = null
        return discarded
    }
}
