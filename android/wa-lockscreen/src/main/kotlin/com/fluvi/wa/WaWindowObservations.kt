package com.fluvi.wa

import android.view.Display

internal enum class WaScanDisposition { IN_FLIGHT, APPLIED, CANCELED, STALE, GATE_DENIED }
internal enum class WaWithdrawalCause { APP_WINDOW_PRESENT, PUBLIC_NEGATIVE, USER_PRESENT }

internal data class WaWindowObservation(
    val scan: Long,
    val fetchBeginNs: Long,
    val fetchEndNs: Long,
    val metadataEndNs: Long,
    val appWindow: Boolean?,
    val gateAtMetadata: WaGateRead?,
    val disposition: WaScanDisposition,
    val dispositionNs: Long,
)

/** Worker order and Main delivery order can differ during supersession. Only the serial reader
 * writes this immutable selection; Main never waits for it. Attempts contain scalar fields only. */
internal data class WaMetadataOrder(
    val count: Int = 0, val firstPositive: WaWindowAttempt? = null, val priorNegative: WaWindowAttempt? = null,
)

internal class WaWindowAttempts {
    @Volatile var latestRead: WaGateRead? = null
    @Volatile var order = WaMetadataOrder()
        private set

    fun metadata(attempt: WaWindowAttempt, app: Boolean) {
        val before = order
        order = WaMetadataOrder(before.count + 1, before.firstPositive ?: attempt.takeIf { app },
            if (!app && before.firstPositive == null) attempt else before.priorNegative)
    }
}

/** The serial reader writes measurement scalars. Main alone assigns the final disposition. */
internal class WaWindowAttempt(
    val scan: Long, private val attempts: WaWindowAttempts,
) {
    var fetchBeginNs = 0L
    var fetchEndNs = 0L
    private var metadataEndNs = 0L
    private var previousRead: WaGateRead? = null
    private var appWindow: Boolean? = null
    private var result: WaWindowObservation? = null

    fun metadata(app: Boolean, atNs: Long) {
        previousRead = attempts.latestRead?.takeIf { it.end.elapsedNs <= atNs }
        metadataEndNs = atNs
        appWindow = app
        attempts.metadata(this, app)
    }

    private fun row(disposition: WaScanDisposition, atNs: Long) = WaWindowObservation(
        scan, fetchBeginNs, fetchEndNs, metadataEndNs, appWindow, previousRead, disposition, atNs,
    )

    fun snapshot() = result ?: row(WaScanDisposition.IN_FLIGHT, 0)

    fun finish(disposition: WaScanDisposition, atNs: Long): WaWindowObservation =
        row(disposition, atNs).also { result = it }
}

internal data class WaWindowSummary(
    val generation: Long, val attempted: Int, val completed: Int, val canceled: Int, val stale: Int,
    val firstPositive: WaWindowObservation?, val lastPriorNegative: WaWindowObservation?,
    val last: WaWindowObservation?, val previousRead: WaGateRead?,
)

/** One actual attachment. Only Main updates its counters, gate samples and report. */
internal class WaWindowHistory(val owner: WaAttachment, val generation: Long) {
    var previousRead: WaGateRead?
        get() = attempts.latestRead
        set(value) { attempts.latestRead = value }
    var draft: WaUnlockDraft? = null
    private var attempted = 0
    private val attempts = WaWindowAttempts()
    private var canceled = 0
    private var stale = 0
    private var outstanding = 0
    private var last: WaWindowObservation? = null

    fun begin(scan: Long): WaWindowAttempt {
        ++attempted
        ++outstanding
        return WaWindowAttempt(scan, attempts)
    }

    fun finish(observation: WaWindowObservation) {
        --outstanding
        if (observation.disposition == WaScanDisposition.CANCELED) ++canceled
        if (observation.disposition == WaScanDisposition.STALE) ++stale
        if (observation.scan >= (last?.scan ?: 0)) last = observation
        // A public denial can beat the worker's Main callback. Publish the first late positive and
        // the drained snapshot only. Ordinary scan traffic never writes a file.
        draft?.let { receipt ->
            receipt.refreshScans(snapshot(), publish = outstanding == 0 || observation.scan == attempts.order.firstPositive?.scan)
        }
    }

    fun snapshot(): WaWindowSummary {
        val order = attempts.order
        return WaWindowSummary(generation, attempted, order.count, canceled, stale,
            order.firstPositive?.snapshot(), order.priorNegative?.snapshot(), last, previousRead)
    }
}

internal data class WaUnlockConfirmation(val reason: WaHideReason, val source: WaSource, val at: WaTime, val read: WaGateRead?)

/** Main-thread association only. No read of platform state, scheduled hide, or eligibility decision. */
internal class WaUnlockTracking {
    var generation = 0L
        private set
    private var service = 0L
    private var live = false
    private var current: WaWindowHistory? = null
    private var pending: WaUnlockDraft? = null

    fun connect(session: Long): Boolean {
        if (session <= service) return false
        invalidate(service)
        service = session
        live = true
        return true
    }

    fun disconnect(session: Long) {
        if (session != service) return
        invalidate(session)
        live = false
    }

    fun attached(owner: WaAttachment, display: Int) {
        if (!live || owner.service != service) return
        invalidate(owner.service)
        ++generation
        if (display == Display.DEFAULT_DISPLAY) current = WaWindowHistory(owner, generation)
    }

    fun history(owner: WaAttachment?) = current?.takeIf { it.owner == owner }

    fun withdrew(draft: WaUnlockDraft) {
        val record = draft.record ?: return
        val history = history(record.trigger.owner) ?: return
        history.draft = draft
        if (record.trigger.cause == WaWithdrawalCause.APP_WINDOW_PRESENT) pending = draft
    }

    fun awaiting(session: Long) = service == session && pending != null

    fun hasPending(session: Long, nowNs: Long): Boolean {
        if (session != service) return false
        val decision = pending?.record?.trigger?.decision?.elapsedNs ?: return false
        if (nowNs - decision !in 0..CONFIRM_NS) discardPending(session)
        return pending != null
    }

    fun confirm(
        session: Long, episode: Long, currentOwner: WaAttachment?, reason: WaHideReason, source: WaSource,
        at: WaTime, read: WaGateRead?,
    ): Boolean {
        if (!hasPending(session, at.elapsedNs)) return false
        val draft = pending ?: return false
        val record = draft.record ?: return false
        val trigger = record.trigger
        if (session != service || session != trigger.owner.service || episode != trigger.owner.episode ||
            record.display != Display.DEFAULT_DISPLAY || currentOwner != null || history(trigger.owner)?.draft !== draft
        ) return false
        val valid = when (reason) {
            WaHideReason.UNLOCKED -> read != null && read.state.terminal == WaHideReason.UNLOCKED &&
                read.begin.elapsedNs >= trigger.decision.elapsedNs && read.end.elapsedNs in read.begin.elapsedNs..at.elapsedNs
            WaHideReason.USER_PRESENT -> source == WaSource.USER_PRESENT
            else -> false
        }
        if (!valid) return false
        pending = null
        draft.update { it.copy(confirmation = WaUnlockConfirmation(reason, source, read?.end ?: at, read)) }
        return true
    }

    fun discardPending(session: Long) {
        if (session != service) return
        val old = pending ?: return
        if (current?.draft === old) current?.draft = null
        pending = null
    }

    fun invalidate(session: Long) {
        if (session != service) return
        discardPending(session)
        current = null
    }

    companion object {
        const val CONFIRM_NS = 3_000_000_000L
    }
}
