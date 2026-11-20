package com.fluvi.app.lockscreen

/** One scalar opportunity belongs to one wake, not to a queued request.
 * Main publishes it and the serial inspection worker consumes it under the
 * service queue lock, immediately before a physical tree read. */
internal class KeyguardFirstAcquisition {
    private var owner: KeyguardInspectionAuthority? = null
    private var eligible = false
    private var consumed = false

    fun begin(authority: KeyguardInspectionAuthority, preparedLiveOrb: Boolean) {
        owner = authority
        eligible = preparedLiveOrb
        consumed = false
    }

    /** A changed owner/configuration cannot later revive this wake's hint. */
    fun invalidate() { eligible = false }

    /** A stale/abandoned offer with no current freshness ticket did not enter
     * a physical read and therefore cannot consume the current wake. */
    fun take(
        request: KeyguardCardInspectionRequest,
        ticket: KeyguardInspectionFreshness.Ticket?,
    ): Boolean {
        val initial = owner ?: return false
        if (ticket == null || !ticket.authority.matches(request) ||
            request.session != initial.serviceSession || request.wakeGeneration != initial.wakeGeneration
        ) return false
        val useRootOnly = !consumed && eligible && ticket.authority == initial &&
            ticket.reason == KeyguardWindowFreshness.LIFECYCLE_BOUNDARY
        // Even an ineligible or failing physical acquisition is the first
        // attempt: later same-wake reads must retain the established route.
        consumed = true
        return useRootOnly
    }
}
