package com.fluvi.app.lockscreen

/** Scheduling identity only. It is never a display grant or a retained node. */
internal data class KeyguardR37ReservationStamp(
    val token: Any,
    val firstRequestId: Long,
    val target: KeyguardInspectionAuthority,
    val stateRevision: Long,
    val routeRevision: Long,
)

internal object KeyguardR37Ownership {
    /** A provisional read can be associated with an adopted owner only across
     * the single authority publication performed by that same adoption. Any
     * intervening state invalidation or a same-valued replacement fails closed. */
    fun sameAdoption(stamp: KeyguardR37ReservationStamp, token: Any?, firstRequestId: Long,
                     authority: KeyguardInspectionAuthority, stateRevision: Long,
                     routeRevision: Long): Boolean =
        token === stamp.token && firstRequestId == stamp.firstRequestId && authority == stamp.target &&
            stamp.stateRevision != Long.MAX_VALUE && stateRevision == stamp.stateRevision + 1 &&
            routeRevision == stamp.routeRevision
}
