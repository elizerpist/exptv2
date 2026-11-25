package com.fluvi.app.lockscreen

import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.atomic.AtomicLongArray

/** Capture-owned primitive mailbox. Producers never retain Views, nodes or
 * financial data and never wait for its diagnostic consumer. The last store
 * publishes each record; a freeze with an unfinished writer is incomplete. */
internal class KeyguardR41RawLedger(private val capacity: Int = 2048) {
    private val data = AtomicLongArray(capacity * STRIDE)
    private val next = AtomicLong()
    private val state = AtomicLong()
    val overflow = AtomicLong()
    val late = AtomicLong()
    val offerWallNs = AtomicLong()
    val offerMaxWallNs = AtomicLong()
    val offerTimingInvalid = AtomicLong()

    init { require(capacity > 0) }

    /** Returns a one-based immutable record ordinal, or zero on loss/closure. */
    fun offer(phase: Int, attempt: Long, session: Long, wake: Long, request: Long,
              atNs: Long, tid: Long, extra1: Long = 0, extra2: Long = 0,
              uptimeMs: Long = 0): Long {
        require(phase > 0)
        val startedNs = System.nanoTime()
        while (true) {
            val value = state.get()
            if (value < 0) { late.incrementAndGet(); recordOfferWall(startedNs); return 0 }
            if (state.compareAndSet(value, value + 1)) break
        }
        try {
            val index = next.getAndIncrement()
            if (index >= capacity) { overflow.incrementAndGet(); return 0 }
            val base = index.toInt() * STRIDE
            data.set(base + 1, attempt); data.set(base + 2, session); data.set(base + 3, wake)
            data.set(base + 4, request); data.set(base + 5, atNs); data.set(base + 6, tid)
            data.set(base + 7, extra1); data.set(base + 8, extra2); data.set(base + 9, uptimeMs)
            data.set(base, phase.toLong()) // release/publish after every scalar
            return index + 1
        } finally {
            recordOfferWall(startedNs)
            state.decrementAndGet()
        }
    }

    /** Sum of mailbox-call wall durations, never an elapsed or CPU total. */
    private fun recordOfferWall(startedNs: Long) {
        val elapsed = System.nanoTime() - startedNs
        if (elapsed < 0) { offerTimingInvalid.incrementAndGet(); return }
        offerWallNs.addAndGet(elapsed)
        while (true) {
            val previous = offerMaxWallNs.get()
            if (elapsed <= previous || offerMaxWallNs.compareAndSet(previous, elapsed)) return
        }
    }

    /** No wait for a producer. Any writer already inside is declared pending. */
    fun cut(): Long {
        while (true) {
            val value = state.get()
            if (value < 0) return value and Long.MAX_VALUE
            if (state.compareAndSet(value, value or Long.MIN_VALUE)) return value
        }
    }

    fun size(): Int = minOf(next.get(), capacity.toLong()).toInt()
    fun inFlight(): Long = state.get() and Long.MAX_VALUE

    /** Consumer only; null means an unfinished slot, never a zero timestamp. */
    fun read(index: Int): Record? {
        if (index < 0 || index >= size()) return null
        val base = index * STRIDE
        val phase = data.get(base).toInt()
        if (phase == 0) return null
        return Record(phase, data.get(base + 1), data.get(base + 2), data.get(base + 3),
            data.get(base + 4), data.get(base + 5), data.get(base + 6), data.get(base + 7),
            data.get(base + 8), data.get(base + 9))
    }

    data class Record(val phase: Int, val attempt: Long, val session: Long, val wake: Long,
                      val request: Long, val atNs: Long, val tid: Long, val extra1: Long,
                      val extra2: Long, val uptimeMs: Long)

    companion object {
        private const val STRIDE = 10
        const val PROVISIONAL = 1
        const val BIND_WAKE = 2
        const val BIND_SCREEN = 3
        const val OFFER = 4
        const val WORKER = 5
        const val READ_START = 6
        const val READ_END = 7
        const val DISPATCH = 8
        const val MAIN = 9
        const val GRANT = 10
        const val WINNER = 11
        const val CANCEL = 12
        const val ELIGIBLE = 13
        const val DENIED = 14
        const val ORDERED_BYPASS = 15
        const val SAMPLE_OFFER = 20
        const val SAMPLE_REPLACED = 21
        const val SAMPLE_SUBMIT = 22
        const val SAMPLE_WORKER = 23
        const val SAMPLE_READ_START = 24
        const val SAMPLE_READ_END = 25
        const val SAMPLE_DISPATCH = 26
        const val SAMPLE_MAIN = 27
        const val SAMPLE_DELIVER = 28
        const val SAMPLE_REJECT = 29
        const val ORDERED_SHADOW_OFFER = 30
        const val SYSTEM_ELIGIBLE = 31
        const val FALLBACK_CANDIDATE = 32
        const val FALLBACK_POST_RECEIPT = 33
        const val R42_PRESTART = 34
        const val R42_STALE_POSITIVE = 35
        const val R42_STALE_DETAIL = 36
    }
}
