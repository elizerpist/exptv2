package com.fluvi.app.lockscreen.material

import com.fluvi.app.lockscreen.KeyguardMainWorkEvidence

/** Main-owner numeric probe, not a clock or renderer. All Ns timestamps use
 * System.nanoTime / Choreographer's documented timebase. CPU is thread CPU,
 * not elapsed time. Successful Canvas shader submission is not presentation.
 * Three primitive slots; only retained candidates snapshot bounded own work. */
internal class KeyguardDrawGapEvidence {
    private var owner = 0L
    private var active = false
    private var sequence = 0L
    private var consumed = 0L
    private var frame = 0L
    private var entry = 0L
    private var exit = 0L
    private var previousEntry = 0L
    private var lastDrawEnd = 0L
    private var lastDrawCallback = 0L
    private var observed = 0L
    private var unpaired = 0L
    private var coalesced = 0L
    private var candidates = 0L
    private var rejected = 0L
    private var observerNs = 0L
    private var samplingBreaks = 0L
    private val slots = Array(3) { LongArray(15) }
    private val work = arrayOfNulls<KeyguardMainWorkEvidence.Snapshot>(3)
    private val programs = arrayOfNulls<String>(3)
    private val sizes = Array(3) { IntArray(2) }
    private var count = 0

    fun begin(attachment: Long) {
        owner = attachment; active = true; sequence = 0; consumed = 0
        frame = 0; entry = 0; exit = 0; previousEntry = 0
        lastDrawEnd = 0; lastDrawCallback = 0; observed = 0; unpaired = 0
        coalesced = 0; candidates = 0; rejected = 0; count = 0; observerNs = 0; samplingBreaks = 0
        work.fill(null); programs.fill(null)
    }
    fun end() { active = false }
    fun samplingOff() {
        if (lastDrawEnd != 0L || sequence != consumed) samplingBreaks++
        lastDrawEnd = 0; lastDrawCallback = 0; consumed = 0; sequence = 0
        frame = 0; entry = 0; exit = 0; previousEntry = 0
    }
    fun callback(attachment: Long, frameNs: Long, enteredNs: Long, exitedNs: Long) {
        if (!active || attachment != owner || exitedNs < enteredNs) { rejected++; return }
        previousEntry = entry; entry = enteredNs; exit = exitedNs; frame = frameNs; sequence++
    }
    fun addObserverCost(ns: Long) { observerNs += ns }

    fun drawn(attachment: Long, startNs: Long, endNs: Long, cpuNs: Long,
        configureNs: Long, submitNs: Long, ownWork: KeyguardMainWorkEvidence? = null,
        program: String? = null, width: Int = 0, height: Int = 0) {
        if (!active || attachment != owner || endNs < startNs ||
            (lastDrawEnd != 0L && startNs < lastDrawEnd)) { rejected++; return }
        val fresh = sequence > consumed
        val callbacks = sequence - consumed
        observed++
        if (!fresh) unpaired++
        if (callbacks > 1) coalesced += callbacks - 1
        if (lastDrawEnd != 0L) {
            candidates++
            val gap = endNs - lastDrawEnd
            var slot = if (count < slots.size) count else 0
            if (count == slots.size) for (i in 1 until slots.size) {
                if (slots[i][14] < slots[slot][14]) slot = i
            }
            if (count < slots.size || gap > slots[slot][14]) {
                if (count < slots.size) count++
                val s = slots[slot]
                s[0] = lastDrawEnd; s[1] = startNs; s[2] = endNs; s[3] = lastDrawCallback
                s[4] = if (fresh) frame else 0; s[5] = if (fresh) entry else 0
                s[6] = if (fresh) exit else 0; s[7] = if (fresh) previousEntry else 0
                s[8] = callbacks; s[9] = if (fresh) 1 else 0
                s[10] = cpuNs; s[11] = configureNs; s[12] = submitNs
                s[13] = observed; s[14] = gap
                work[slot] = ownWork?.snapshotOverlapping(lastDrawEnd, endNs)
                programs[slot] = program; sizes[slot][0] = width; sizes[slot][1] = height
            }
        }
        consumed = sequence; lastDrawEnd = endNs; lastDrawCallback = if (fresh) entry else 0
    }

    fun snapshot() = Snapshot(owner, observed, unpaired, coalesced, candidates - count,
        rejected, observerNs, samplingBreaks, (0 until count).map { index ->
            val s = slots[index]
            Gap(s[0], s[1], s[2], s[3], s[4], s[5], s[6], s[7], s[8], s[9],
                s[10], s[11], s[12], s[13], s[14], work[index], programs[index], sizes[index][0], sizes[index][1])
        }.sortedByDescending { it.currentEndNs - it.previousEndNs })

    data class Snapshot(val attachment: Long, val observedDraws: Long, val unpairedDraws: Long,
        val coalescedCallbacks: Long, val omittedGaps: Long, val rejected: Long,
        val observerNs: Long, val samplingBreaks: Long, val gaps: List<Gap>) {
        /** Called on the diagnostic consumer, never from Canvas/Choreographer. */
        fun compact(): String = gaps.joinToString("\n") { g ->
            "attach=$attachment prevEndNs=${g.previousEndNs} startNs=${g.currentStartNs} endNs=${g.currentEndNs}" +
                " prevCbNs=${g.previousDrawCallbackNs} frameNs=${g.frameNs} cbInNs=${g.callbackEntryNs} cbOutNs=${g.callbackExitNs}" +
                " priorCbNs=${g.previousCallbackEntryNs} callbacks=${g.callbacksSinceDraw} paired=${g.paired == 1L}" +
                " cpuNs=${g.cpuNs.takeIf { it >= 0 } ?: "UNOBSERVED"} configureNs=${g.configureNs} submitNs=${g.submitNs} seq=${g.drawSequence}" +
                " gapNs=${g.gapNs} currentProgram=${g.program ?: "UNOBSERVED"} px=${g.width}x${g.height}" + (g.work?.let { w ->
                    " workSession=${w.serviceSession} tid=${w.ownerThreadId} workOmitted=${w.omittedOverlapping}" +
                        " workEvicted=${w.overwrittenSpans} workIncomplete=${w.coverageIncomplete}" +
                        " work=" + w.spans.joinToString(";") { s ->
                            "${s.kind}:${s.requestId}:${s.startedNs}:${s.endedNs}:${s.cpuNs.takeIf { it >= 0 } ?: "NA"}:${s.overlapNs}"
                        }
                } ?: " work=UNOBSERVED")
        }
    }
    data class Gap(val previousEndNs: Long, val currentStartNs: Long, val currentEndNs: Long,
        val previousDrawCallbackNs: Long, val frameNs: Long, val callbackEntryNs: Long,
        val callbackExitNs: Long, val previousCallbackEntryNs: Long, val callbacksSinceDraw: Long,
        val paired: Long, val cpuNs: Long, val configureNs: Long, val submitNs: Long,
        val drawSequence: Long, val gapNs: Long, val work: KeyguardMainWorkEvidence.Snapshot?,
        val program: String?, val width: Int, val height: Int)
}
