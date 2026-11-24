package com.fluvi.app.lockscreen

/** Consumer-owned, bounded scalar evidence. It has no visibility authority.
 * Missing values use a sentinel and are never exported as zero. */
internal class KeyguardR41AttemptLedger {
    private val ids = LongArray(CAPACITY) { MISSING }
    private val times = LongArray(CAPACITY * PHASES) { MISSING }
    private val tids = LongArray(CAPACITY * PHASES) { MISSING }
    private val grantReservation = LongArray(CAPACITY) { MISSING }
    private val grantOutput = LongArray(CAPACITY) { MISSING }
    private val winnerReservation = LongArray(CAPACITY) { MISSING }
    private val winnerOutput = LongArray(CAPACITY) { MISSING }
    private var count = 0
    var wakeNs: Long = MISSING; private set
    var screenNs: Long = MISSING; private set
    var wakeTid: Long = MISSING; private set
    var screenTid: Long = MISSING; private set
    var wakeUptimeMs: Long = MISSING; private set
    var wakeSource: Long = MISSING; private set
    var wakeEventMs: Long = MISSING; private set
    var eligible: Int = -1; private set
    var omitted: Long = 0; private set
    var invalid: Long = 0; private set
    var orderedBypasses: Long = 0; private set
    var shadowOffers: Long = 0; private set
    var shadowPartialMatches: Long = 0; private set
    private var shadowLastRequest: Long = MISSING
    private var shadowLastFlags: Long = MISSING

    fun record(phase: String, request: Long?, atNs: Long, reservation: Long? = null, output: Long? = null,
               tid: Long? = null, uptimeMs: Long? = null, source: Long? = null, eventTimeMs: Long? = null) {
        if (atNs == MISSING) { invalid++; return }
        if (phase == "ORDERED_SHADOW_OFFER") {
            if (request == null || request <= 0 || reservation == null || reservation <= 0) {
                invalid++
            } else {
                shadowOffers++
                shadowLastRequest = reservation
                shadowLastFlags = output ?: 0L
                if (shadowLastFlags == 15L) shadowPartialMatches++
            }
            return
        }
        when (phase) {
            "WAKE" -> {
                wakeNs = once(wakeNs, atNs)
                if (tid != null) wakeTid = once(wakeTid, tid)
                if (uptimeMs != null) wakeUptimeMs = once(wakeUptimeMs, uptimeMs)
                if (source != null) wakeSource = once(wakeSource, source)
                if (eventTimeMs != null) wakeEventMs = once(wakeEventMs, eventTimeMs)
                return
            }
            "SCREEN" -> {
                screenNs = once(screenNs, atNs)
                if (tid != null) screenTid = once(screenTid, tid)
                return
            }
            "ELIGIBLE" -> { if (eligible == 0) invalid++; eligible = 1; return }
            "DENIED" -> { if (eligible == 1) invalid++; eligible = 0; return }
        }
        val column = when (phase) {
            "OFFER" -> OFFER; "WORKER_START" -> WORKER; "READ_START" -> READ_START; "READ_END" -> READ_END
            "DISPATCH" -> DISPATCH; "MAIN" -> MAIN; "GRANT" -> GRANT
            "WINNER" -> WINNER; "CANCEL" -> CANCEL
            "ORDERED_BYPASS" -> BYPASS
            else -> return
        }
        if (request == null || request < 0) { invalid++; return }
        var slot = (0 until count).firstOrNull { ids[it] == request } ?: -1
        if (slot < 0) {
            if (count == CAPACITY) { omitted++; return }
            slot = count++
            ids[slot] = request
        }
        val index = slot * PHASES + column
        if (column == BYPASS && times[index] == MISSING) orderedBypasses++
        times[index] = once(times[index], atNs)
        if (tid != null) tids[index] = once(tids[index], tid)
        if (column == GRANT || column == WINNER) {
            if (reservation == null || output == null || reservation < 0 || output < 0) {
                invalid++
            } else if (column == GRANT) {
                grantReservation[slot] = once(grantReservation[slot], reservation)
                grantOutput[slot] = once(grantOutput[slot], output)
            } else {
                winnerReservation[slot] = once(winnerReservation[slot], reservation)
                winnerOutput[slot] = once(winnerOutput[slot], output)
            }
        }
    }

    private fun once(previous: Long, next: Long): Long {
        if (previous != MISSING && previous != next) invalid++
        return if (previous == MISSING) next else previous
    }

    private fun time(slot: Int, phase: Int): Long = if (slot < 0) MISSING else times[slot * PHASES + phase]
    private fun value(value: Long): String = if (value == MISSING) "UNOBSERVED" else value.toString()

    fun core(attempt: Long, session: Long, wake: Long, captureLoss: Long): String {
        val winner = (0 until count).filter { time(it, WINNER) != MISSING }.minByOrNull { time(it, WINNER) }
        val slot = winner ?: (0 until count).firstOrNull { time(it, READ_START) != MISSING } ?: -1
        val matching = winner != null && grantReservation[slot] != MISSING && grantOutput[slot] != MISSING &&
            grantReservation[slot] == winnerReservation[slot] && grantOutput[slot] == winnerOutput[slot] &&
            time(slot, GRANT) != MISSING && time(slot, WINNER) >= time(slot, GRANT) &&
            (time(slot, CANCEL) == MISSING || time(slot, CANCEL) > time(slot, WINNER))
        val owner = if (matching) "${grantReservation[slot]}/${grantOutput[slot]}/${ids[slot]}" else "UNOBSERVED"
        val outcome = if (matching) "SUCCESS" else if (slot >= 0 && time(slot, CANCEL) != MISSING) "CANCELLED" else "UNOBSERVED"
        val loss = captureLoss + omitted + invalid
        return " R41_CORE attempt=$attempt session=$session wake=$wake eligible=${when (eligible) { 1 -> "true"; 0 -> "false"; else -> "UNOBSERVED" }}" +
            " outcome=$outcome owner=$owner readOwner=${if (matching && time(slot, READ_START) != MISSING && time(slot, READ_END) != MISSING) owner else "UNOBSERVED"}" +
            " dispatchOwner=${if (matching && time(slot, DISPATCH) != MISSING && time(slot, MAIN) != MISSING) owner else "UNOBSERVED"}" +
            " grantOwner=$owner request=${if (slot < 0) "UNOBSERVED" else ids[slot]} wakeNs=${value(wakeNs)} screenNs=${value(screenNs)}" +
            " wakeTid=${value(wakeTid)} screenTid=${value(screenTid)} wakeUpMs=${value(wakeUptimeMs)} source=${value(wakeSource)} eventMs=${value(wakeEventMs)}" +
            " offerNs=${value(time(slot, OFFER))} workerNs=${value(time(slot, WORKER))} readStartNs=${value(time(slot, READ_START))} readEndNs=${value(time(slot, READ_END))}" +
            " dispatchNs=${value(time(slot, DISPATCH))} mainNs=${value(time(slot, MAIN))} grantNs=${value(time(slot, GRANT))}" +
            " winnerNs=${value(time(slot, WINNER))} cancelNs=${value(time(slot, CANCEL))} orderedBypassNs=${value(time(slot, BYPASS))}" +
            " orderedBypasses=$orderedBypasses h2ShadowOffers=$shadowOffers h2PartialMatches=$shadowPartialMatches" +
            " h2LastRequest=${value(shadowLastRequest)} h2LastFlags=${value(shadowLastFlags)} h2Claims=0 h2Enabled=false" +
            " h2ShadowCoverage=partialGuardsDispatchUnverified" +
            " requests=$count omitted=$omitted invalid=$invalid dropped=$loss" +
            " coverage=INCOMPLETE clock=System.nanoTime physical=UNOBSERVED\n"
    }

    fun requestRows(attempt: Long): List<String> = (0 until count).map { slot ->
        " R41_REQ attempt=$attempt req=${ids[slot]} offerNs=${value(time(slot, OFFER))} workerNs=${value(time(slot, WORKER))} read=${value(time(slot, READ_START))}/${value(time(slot, READ_END))}" +
            " handoff=${value(time(slot, DISPATCH))}/${value(time(slot, MAIN))} grant=${value(time(slot, GRANT))}@${value(grantReservation[slot])}/${value(grantOutput[slot])}" +
            " winner=${value(time(slot, WINNER))}@${value(winnerReservation[slot])}/${value(winnerOutput[slot])} cancel=${value(time(slot, CANCEL))}" +
            " orderedBypassNs=${value(time(slot, BYPASS))} tids=${(0 until PHASES).joinToString("/") { value(tids[slot * PHASES + it]) }}\n"
    }

    fun snapshot(): KeyguardR41AttemptLedger = KeyguardR41AttemptLedger().also { copy ->
        ids.copyInto(copy.ids); times.copyInto(copy.times); tids.copyInto(copy.tids)
        grantReservation.copyInto(copy.grantReservation); grantOutput.copyInto(copy.grantOutput)
        winnerReservation.copyInto(copy.winnerReservation); winnerOutput.copyInto(copy.winnerOutput)
        copy.count = count; copy.wakeNs = wakeNs; copy.screenNs = screenNs; copy.eligible = eligible
        copy.wakeTid = wakeTid; copy.screenTid = screenTid; copy.wakeUptimeMs = wakeUptimeMs
        copy.wakeSource = wakeSource; copy.wakeEventMs = wakeEventMs
        copy.omitted = omitted; copy.invalid = invalid; copy.orderedBypasses = orderedBypasses
        copy.shadowOffers = shadowOffers; copy.shadowPartialMatches = shadowPartialMatches
        copy.shadowLastRequest = shadowLastRequest; copy.shadowLastFlags = shadowLastFlags
    }

    companion object {
        private const val CAPACITY = 16
        private const val OFFER = 0
        private const val WORKER = 1
        private const val READ_START = 2
        private const val READ_END = 3
        private const val DISPATCH = 4
        private const val MAIN = 5
        private const val GRANT = 6
        private const val WINNER = 7
        private const val CANCEL = 8
        private const val BYPASS = 9
        private const val PHASES = 10
        private const val MISSING = Long.MIN_VALUE
    }
}
