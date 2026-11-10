package com.fluvi.app.lockscreen

/** Android returns -1 when thread CPU measurement is unsupported. */
internal fun keyguardThreadCpuDelta(start: Long, end: Long): Long =
    if (start < 0L || end < start) -1L else end - start

/** Main-owner-only numeric evidence. It is not a scheduler or visibility gate.
 * Recording allocates nothing and takes no lock. All readers are the same
 * main-thread owner; immutable snapshots alone may leave that thread. */
internal class KeyguardMainWorkEvidence {
    private var serviceSession = 0L
    private var ownerThreadId = 0L
    private val kinds = IntArray(CAPACITY)
    private val requests = LongArray(CAPACITY)
    private val starts = LongArray(CAPACITY)
    private val ends = LongArray(CAPACITY)
    private val cpus = LongArray(CAPACITY)
    private var size = 0
    private var next = 0
    private var overwritten = 0L
    private var invalid = 0L
    private var discardedFromNs = Long.MAX_VALUE
    private var discardedToNs = Long.MIN_VALUE

    fun resetSession(serviceSession: Long, ownerThreadId: Long) {
        this.serviceSession = serviceSession
        this.ownerThreadId = ownerThreadId
        size = 0
        next = 0
        overwritten = 0
        invalid = 0
        discardedFromNs = Long.MAX_VALUE
        discardedToNs = Long.MIN_VALUE
    }

    /** requestId=0 means no request owns this synchronous callback. CPU covers
     * the entire scope, including any nested scope; never sum nested spans. */
    fun record(kind: Int, requestId: Long, startedNs: Long, endedNs: Long, cpuNs: Long) {
        if (endedNs < startedNs || cpuNs < -1L) {
            invalid++
            return
        }
        if (size == CAPACITY) {
            overwritten++
            discardedFromNs = minOf(discardedFromNs, starts[next])
            discardedToNs = maxOf(discardedToNs, ends[next])
        } else size++
        kinds[next] = kind
        requests[next] = requestId
        starts[next] = startedNs
        ends[next] = endedNs
        cpus[next] = cpuNs
        next = (next + 1) % CAPACITY
    }

    /** Called only when the material owner retains a bounded slow-gap sample,
     * not on every draw. Selecting overlapping scopes is evidence correlation,
     * not proof that their execution explains the whole observed draw gap. */
    fun snapshotOverlapping(fromNs: Long, toNs: Long): Snapshot {
        var overlapCount = 0
        var first = -1
        var second = -1
        var third = -1
        var firstOverlap = 0L
        var secondOverlap = 0L
        var thirdOverlap = 0L
        if (toNs > fromNs) for (index in 0 until size) {
            val overlap = minOf(toNs, ends[index]) - maxOf(fromNs, starts[index])
            if (overlap <= 0) continue
            overlapCount++
            if (ranksBefore(index, overlap, first, firstOverlap)) {
                third = second; thirdOverlap = secondOverlap
                second = first; secondOverlap = firstOverlap
                first = index; firstOverlap = overlap
            } else if (ranksBefore(index, overlap, second, secondOverlap)) {
                third = second; thirdOverlap = secondOverlap
                second = index; secondOverlap = overlap
            } else if (ranksBefore(index, overlap, third, thirdOverlap)) {
                third = index; thirdOverlap = overlap
            }
        }
        // Do not allocate one object per retained ring slot or sort it on the
        // draw owner. Only the three selected immutable records leave here.
        val selected = ArrayList<Span>(MAX_OVERLAPS)
        if (first >= 0) selected += copySpan(first, firstOverlap)
        if (second >= 0) selected += copySpan(second, secondOverlap)
        if (third >= 0) selected += copySpan(third, thirdOverlap)
        return Snapshot(
            serviceSession = serviceSession,
            ownerThreadId = ownerThreadId,
            spans = selected,
            omittedOverlapping = overlapCount - selected.size,
            overwrittenSpans = overwritten,
            coverageIncomplete = toNs <= fromNs ||
                (overwritten > 0 && fromNs < discardedToNs && toNs > discardedFromNs),
            invalidSpans = invalid,
        )
    }

    private fun ranksBefore(index: Int, overlap: Long, retained: Int, retainedOverlap: Long): Boolean =
        retained < 0 || overlap > retainedOverlap ||
            (overlap == retainedOverlap && starts[index] < starts[retained])

    private fun copySpan(index: Int, overlap: Long) = Span(
        kinds[index], requests[index], starts[index], ends[index], cpus[index], overlap,
    )

    data class Span(
        val kind: Int,
        val requestId: Long,
        val startedNs: Long,
        val endedNs: Long,
        val cpuNs: Long,
        val overlapNs: Long,
    )

    data class Snapshot(
        val serviceSession: Long,
        val ownerThreadId: Long,
        val spans: List<Span>,
        val omittedOverlapping: Int,
        val overwrittenSpans: Long,
        val coverageIncomplete: Boolean,
        val invalidSpans: Long,
    )

    companion object {
        private const val CAPACITY = 32
        private const val MAX_OVERLAPS = 3
        const val SYSTEM_GATE = 1
        const val INSPECTION_APPLY = 2
        const val DIAGNOSTIC_PRODUCER = 3

        fun kindName(kind: Int): String = when (kind) {
            SYSTEM_GATE -> "systemGate"
            INSPECTION_APPLY -> "inspectionApply"
            DIAGNOSTIC_PRODUCER -> "diagnosticProducer"
            else -> "unknown"
        }
    }
}
