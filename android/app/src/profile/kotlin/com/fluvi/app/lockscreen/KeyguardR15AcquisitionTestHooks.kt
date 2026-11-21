package com.fluvi.app.lockscreen

/** Compile-time disabled; no comparison switch is available in profile. */
internal object KeyguardR15AcquisitionTestHooks {
    const val ENABLED = false
    fun financialCompleted(requestId: Long?, scope: com.fluvi.app.runtime.FluviFinancialOrbWork.Scope) = Unit
    fun motionChanged(allowed: Boolean) = Unit
    fun begin(request: KeyguardCardInspectionRequest, ticket: KeyguardInspectionFreshness.Ticket?, eligible: Boolean) = eligible
    fun candidate(metadata: KeyguardWindowReaderWindowMetadata) = Unit
    fun child(window: Int, index: Int, flags: Int?) = Unit
    fun returnedChild(window: Int, index: Int, present: Boolean) = Unit
    fun yielded(requestId: Long) = Unit
    fun finish(result: KeyguardWindowSnapshotReader.Result) = Unit
    fun outcome(requestId: Long, decision: KeyguardCardVisibility, reason: KeyguardSurfaceReason,
                authorityCurrent: Boolean, started: Long, finished: Long) = Unit
}
