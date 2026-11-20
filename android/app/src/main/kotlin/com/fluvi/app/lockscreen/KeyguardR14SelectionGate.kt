package com.fluvi.app.lockscreen

/** Test-harness eligibility for an already completed acquisition. This does
 * not authorize display and is not called by the production admission path. */
internal object KeyguardR14SelectionGate {
    fun eligible(authority: KeyguardInspectionAuthority, request: KeyguardCardInspectionRequest,
        closeRequestedAt: Long, startedAt: Long, decision: KeyguardCardVisibility,
        reason: KeyguardSurfaceReason, unavailable: Boolean, truncated: Boolean, stale: Boolean): Boolean =
        startedAt >= closeRequestedAt && decision == KeyguardCardVisibility.SHOW_FULL &&
            reason == KeyguardSurfaceReason.MAIN_CONFIRMED && !unavailable && !truncated && !stale &&
            authority.matches(request)
}
