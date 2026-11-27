package com.fluvi.wa

/** The first six accepted attachments retain evidence independently of the raw rings. */
internal class WaWithdrawalEvidence {
    private val windows = ArrayList<Window>(MAX_WINDOWS)
    private var omittedWindows = 0
    private var latestCallback: Stamp? = null
    private val counts = IntArray(WaStage.entries.size)
    private var outstandingScans = 0
    private var peakScans = 0
    private var probeReads = 0
    private var crossedProbes = 0
    private var maxProbeReadNs = 0L
    private var maxProbeGapNs = 0L
    private var lastProbeEnd = 0L
    private var lastProbeOwner: WaAttachment? = null

    @Synchronized
    fun observe(row: WaTraceRing.Row) {
        counts[row.stage.ordinal]++
        when (row.stage) {
            WaStage.CALLBACK -> {
                val stamp = latestCallback ?: Stamp().also { latestCallback = it }
                stamp.set(row)
            }
            WaStage.SCAN_START -> {
                outstandingScans++
                peakScans = maxOf(peakScans, outstandingScans)
            }
            WaStage.EPISODE_OPEN -> windows.forEach { window ->
                if (window.sameService(row) && row.episode > window.owner.episode &&
                    window.localHide.seen && !window.nextWake.seen) window.nextWake.set(row)
            }
            WaStage.ATTACH, WaStage.ROOT_ATTACHED -> {
                val owner = row.owner ?: return
                windows.forEach { window ->
                    if (window.sameService(row) && window.owner != owner &&
                        window.localHide.seen && !window.laterAttach.seen) window.laterAttach.set(row)
                }
                if (windows.none { it.owner === owner }) {
                    if (windows.size < MAX_WINDOWS) windows += Window(owner)
                    else if (row.stage == WaStage.ATTACH) omittedWindows++
                }
            }
            else -> Unit
        }
        if (row.owner == null) return
        val window = windows.firstOrNull { it.owner === row.owner } ?: return
        when (row.stage) {
            WaStage.CALLBACK -> if (!window.localHide.seen && !window.firstCallback.seen) window.firstCallback.set(row)
            WaStage.STATE_READ -> {
                if (!window.localHide.seen) {
                    if (!window.firstState.seen) window.firstState.set(row)
                    window.lastState.set(row)
                    if (row.state?.terminal != null && !window.firstPublicNegative.seen) {
                        window.firstPublicNegative.set(row)
                    }
                    if (row.state?.ready == true && row.type in CONTROL_TYPES) window.lastLockedControl.set(row)
                }
            }
            WaStage.ATTACH -> window.attach.set(row)
            WaStage.ROOT_ATTACHED -> window.rootAttached.set(row)
            WaStage.FIRST_NONZERO -> window.nonzero.set(row)
            WaStage.ENTRANCE_BEGIN -> window.entranceBegin.set(row)
            WaStage.ENTRANCE_END -> window.entranceEnd.set(row)
            WaStage.ENTRANCE_CANCEL -> window.entranceCancel.set(row)
            WaStage.DECISION -> {
                if (!window.localHide.seen && !window.decision.seen) {
                    window.decision.set(row)
                    latestCallback?.takeIf {
                        it.owner === row.owner && it.up == row.received && it.source == row.source
                    }?.let(window.trigger::copyFrom)
                }
            }
            WaStage.REVOKE -> window.revoke.set(row)
            WaStage.LOCAL_HIDE -> window.localHide.set(row)
            WaStage.DETACHED -> if (!window.detach.seen) window.detach.set(row)
            WaStage.REMOVE_RETURN -> {
                if (!window.firstRemove.seen) window.firstRemove.set(row)
                window.lastRemove.set(row)
            }
            WaStage.REMOVE_ERROR -> {
                if (!window.firstRemove.seen) window.firstRemove.set(row)
                window.removeError.set(row)
            }
            WaStage.HOST_STOP_END, WaStage.HOST_STOP_ERROR -> window.hostStop.set(row)
            WaStage.TERMINAL, WaStage.DENIED -> if (row.hide != 0L && row.hide == window.localHide.hide) {
                window.terminal.set(row)
            }
            else -> Unit
        }
    }

    @Synchronized
    fun scanEnded() {
        if (outstandingScans > 0) outstandingScans--
    }

    @Synchronized
    fun probe(owner: WaAttachment, up: Long, begin: Long, end: Long, state: WaSystemState, crossed: Boolean, seq: Long) {
        probeReads++
        maxProbeReadNs = maxOf(maxProbeReadNs, end - begin)
        val window = windows.firstOrNull { it.owner === owner }
        if (crossed || window?.localHide?.seen == true) {
            crossedProbes++
            if (window != null) window.crossedProbe = true
            return
        }
        if (lastProbeOwner === owner && begin >= lastProbeEnd) {
            maxProbeGapNs = maxOf(maxProbeGapNs, begin - lastProbeEnd)
        }
        lastProbeOwner = owner
        lastProbeEnd = end
        if (window == null) return
        if (state.terminal != null && !window.probeNegative.seen) {
            window.probeNegative.setProbe(up, begin, end, state, seq)
        }
        if (state.ready) window.probeAllowed.setProbe(up, begin, end, state, seq)
    }

    @Synchronized
    fun lines(): String = buildString {
        append("summaryWindows=${windows.size} summaryOmittedWindows=$omittedWindows")
        append(" callbacks=${counts[WaStage.CALLBACK.ordinal]} ingressAccepted=${counts[WaStage.INGRESS.ordinal]}")
        append(" filtered=${counts[WaStage.FILTERED.ordinal]} stateReads=${counts[WaStage.STATE_READ.ordinal]}")
        append(" scanOffer=${counts[WaStage.SCAN_OFFER.ordinal]} scanStart=${counts[WaStage.SCAN_START.ordinal]}")
        append(" scanCancel=${counts[WaStage.SCAN_CANCEL.ordinal]} scanApply=${counts[WaStage.SCAN_APPLY.ordinal]}")
        append(" scanOutstanding=$outstandingScans scanOutstandingPeak=$peakScans")
        append(" measuredProbes=$probeReads crossedProbes=$crossedProbes")
        append(" maxObservedProbeReadNs=${if (probeReads > 0) maxProbeReadNs else "UNOBSERVED"}")
        append(" maxObservedProbeGapNs=${if (maxProbeGapNs > 0) maxProbeGapNs else "UNOBSERVED"}\n")
        windows.forEach { append(it.line()) }
    }

    private class Window(val owner: WaAttachment) {
        val attach = Stamp()
        val rootAttached = Stamp()
        val nonzero = Stamp()
        val entranceBegin = Stamp()
        val entranceEnd = Stamp()
        val entranceCancel = Stamp()
        val firstCallback = Stamp()
        val trigger = Stamp()
        val firstState = Stamp()
        val lastState = Stamp()
        val firstPublicNegative = Stamp()
        val lastLockedControl = Stamp()
        val probeAllowed = Stamp()
        val probeNegative = Stamp()
        val decision = Stamp()
        val revoke = Stamp()
        val localHide = Stamp()
        val detach = Stamp()
        val firstRemove = Stamp()
        val lastRemove = Stamp()
        val removeError = Stamp()
        val hostStop = Stamp()
        val terminal = Stamp()
        val laterAttach = Stamp()
        val nextWake = Stamp()
        var crossedProbe = false

        fun sameService(row: WaTraceRing.Row) = owner.service == row.service

        fun line(): String = buildString {
            append("WINDOW_SUMMARY s=${owner.service} e=${owner.episode} w=${owner.window} id=${owner.widget} dp=${owner.dp}")
            append(" hide=${if (localHide.seen) localHide.hide else "UNOBSERVED"}")
            append(" reason=${if (localHide.seen) localHide.reason else "UNOBSERVED"} sceneBefore=${decision.scene ?: terminal.scene ?: "UNOBSERVED"}")
            append(" crossedProbe=$crossedProbe displayId=0")
            mapOf(
                "attach" to attach, "rootAttached" to rootAttached, "nonzero" to nonzero, "entranceBegin" to entranceBegin,
                "entranceEnd" to entranceEnd, "entranceCancel" to entranceCancel, "firstCallback" to firstCallback, "trigger" to trigger,
                "firstState" to firstState, "lastState" to lastState, "publicNegative" to firstPublicNegative,
                "lockedControl" to lastLockedControl, "probeAllowed" to probeAllowed, "probeNegative" to probeNegative,
                "decision" to decision, "revoke" to revoke, "localHide" to localHide, "detach" to detach,
                "firstRemove" to firstRemove, "lastRemove" to lastRemove, "removeError" to removeError,
                "hostStop" to hostStop, "terminal" to terminal, "laterAttach" to laterAttach, "nextWake" to nextWake,
            ).forEach { (name, stamp) ->
                append(" $name=")
                if (stamp.seen) append(stamp.value(name)) else append("UNOBSERVED")
            }
            append('\n')
        }
    }

    private class Stamp {
        private var seq = 0L
        private var episode = 0L
        var owner: WaAttachment? = null
            private set
        var up = 0L
            private set
        var source = WaSource.WINDOW
            private set
        var hide = 0L
            private set
        var reason = WaHideReason.NONE
            private set
        var scene: WaLockscreenScene? = null
            private set
        private var elapsed = 0L
        private var begin = 0L
        private var end = 0L
        private var state: WaSystemState? = null
        private var type = 0
        private var eventUp = 0L
        private var displayId = 0
        private var alias = 0
        private var eventClass = WaEventClass.UNKNOWN
        private var windowChanges = -1
        private var contentChanges = -1
        val seen get() = seq != 0L

        fun set(row: WaTraceRing.Row) {
            seq = row.sequence
            owner = row.owner
            episode = row.episode
            up = row.up
            elapsed = row.elapsed
            hide = row.hide
            source = row.source
            reason = row.reason
            scene = row.scene
            begin = row.detail
            end = row.detailEnd
            state = row.state
            type = row.type
            eventUp = row.eventTime
            displayId = row.displayId
            alias = row.windowAlias
            eventClass = row.eventClass
            windowChanges = row.windowChanges
            contentChanges = row.contentChanges
        }

        fun copyFrom(other: Stamp) {
            seq = other.seq
            owner = other.owner
            episode = other.episode
            up = other.up
            elapsed = other.elapsed
            hide = other.hide
            source = other.source
            reason = other.reason
            scene = other.scene
            begin = other.begin
            end = other.end
            state = other.state
            type = other.type
            eventUp = other.eventUp
            displayId = other.displayId
            alias = other.alias
            eventClass = other.eventClass
            windowChanges = other.windowChanges
            contentChanges = other.contentChanges
        }

        fun setProbe(up: Long, begin: Long, end: Long, state: WaSystemState, seq: Long) {
            this.seq = seq
            this.up = up
            elapsed = begin
            this.begin = begin
            this.end = end
            this.state = state
        }

        fun value(label: String): String = buildString {
            append("$seq,$up,$elapsed")
            if (label == "nextWake" || label == "laterAttach") append(",$episode,${owner?.window ?: "UNOBSERVED"}")
            if (label == "firstCallback" || label == "trigger") {
                append(",$source,$type,${if (eventUp > 0L) eventUp else "UNOBSERVED"}")
                append(",${if (displayId < 0) "UNOBSERVED" else displayId},$eventClass,${if (alias == 0) "UNOBSERVED" else alias}")
                append(",${if (windowChanges < 0) "UNOBSERVED" else windowChanges},${if (contentChanges < 0) "UNOBSERVED" else contentChanges}")
            }
            if (label == "firstRemove" || label == "lastRemove" || label == "removeError") append(",${begin == 1L}")
            if (label in STATE_LABELS) append(",$begin,$end,${state?.displayState ?: "UNOBSERVED"},${state?.interactive ?: "UNOBSERVED"},${state?.locked ?: "UNOBSERVED"}")
        }
    }

    companion object {
        private const val MAX_WINDOWS = 6
        private val CONTROL_TYPES = intArrayOf(32, 2048)
        private val STATE_LABELS = setOf("firstState", "lastState", "publicNegative", "lockedControl", "probeAllowed", "probeNegative")
    }
}
