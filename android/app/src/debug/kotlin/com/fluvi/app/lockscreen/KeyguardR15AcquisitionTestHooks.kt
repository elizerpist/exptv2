package com.fluvi.app.lockscreen

import android.os.SystemClock

/** Test-only scalar observations. This cannot grant visibility or trigger a
 * read. The instrumentation owner sets its arm before service connection. */
internal object KeyguardR15AcquisitionTestHooks {
    const val ENABLED = true
    // Historical R15 instrumentation may opt in explicitly; a normal debug
    // service, like profile/release, keeps the established root argument.
    @Volatile var stockArm = true
    @Volatile var historicalRootOnlyOptIn = false
    @Volatile var observer: ((Observation) -> Unit)? = null
    @Volatile var observeIneligible = false
    @Volatile var motionObserver: ((Boolean) -> Unit)? = null
    @Volatile var financialObserver: ((Long?, com.fluvi.app.runtime.FluviFinancialOrbWork.Scope) -> Unit)? = null

    fun financialCompleted(requestId: Long?, scope: com.fluvi.app.runtime.FluviFinancialOrbWork.Scope) {
        runCatching { financialObserver?.invoke(requestId, scope) }
    }

    data class Observation(
        val request: KeyguardCardInspectionRequest,
        val ticket: KeyguardInspectionFreshness.Ticket,
        val stock: Boolean,
        val eligible: Boolean,
        val started: Long,
        val finished: Long,
        val candidate: KeyguardWindowReaderWindowMetadata?,
        val firstChildCalled: Boolean,
        val firstChildWindow: Int?,
        val firstChildIndex: Int?,
        val firstChildFlags: Int?,
        val result: KeyguardWindowSnapshotReader.Result,
        val decision: KeyguardCardVisibility,
        val reason: KeyguardSurfaceReason,
        val authorityAtCompletion: Boolean,
        val inspectionStarted: Long,
        val inspectionFinished: Long,
    )

    private data class Pending(
        val request: KeyguardCardInspectionRequest,
        val ticket: KeyguardInspectionFreshness.Ticket,
        val stock: Boolean,
        val eligible: Boolean,
        val started: Long,
        var candidate: KeyguardWindowReaderWindowMetadata? = null,
        var childCalled: Boolean = false,
        var childWindow: Int? = null,
        var childIndex: Int? = null,
        var childFlags: Int? = null,
        var result: KeyguardWindowSnapshotReader.Result? = null,
        var finished: Long = 0,
    )

    private val active = ThreadLocal<Pending?>()

    fun motionChanged(allowed: Boolean) { runCatching { motionObserver?.invoke(allowed) } }

    /** Called only after the normal queue-locked opportunity was consumed. */
    fun begin(request: KeyguardCardInspectionRequest, ticket: KeyguardInspectionFreshness.Ticket?, eligible: Boolean): Boolean {
        active.remove()
        if (ticket == null) return eligible
        val stock = stockArm
        if (observer != null && (eligible || observeIneligible)) {
            active.set(Pending(request, ticket, stock, eligible, SystemClock.uptimeMillis()))
        }
        return eligible && historicalRootOnlyOptIn && !stock
    }

    fun candidate(metadata: KeyguardWindowReaderWindowMetadata) {
        active.get()?.candidate = metadata
    }

    fun child(window: Int, index: Int, flags: Int?) {
        val pending = active.get() ?: return
        if (!pending.childCalled) {
            pending.childCalled = true
            pending.childWindow = window
            pending.childIndex = index
            pending.childFlags = flags
        }
    }

    fun finish(result: KeyguardWindowSnapshotReader.Result) {
        active.get()?.let {
            it.result = result
            it.finished = SystemClock.uptimeMillis()
        }
    }

    fun outcome(requestId: Long, decision: KeyguardCardVisibility, reason: KeyguardSurfaceReason,
                authorityCurrent: Boolean, started: Long, finished: Long) {
        val pending = active.get()
        active.remove()
        val result = pending?.result ?: return
        if (pending.request.id == requestId) runCatching {
            observer?.invoke(Observation(pending.request, pending.ticket, pending.stock, pending.eligible, pending.started,
                pending.finished, pending.candidate, pending.childCalled, pending.childWindow,
                pending.childIndex, pending.childFlags, result, decision, reason, authorityCurrent, started, finished))
        }
    }
}
