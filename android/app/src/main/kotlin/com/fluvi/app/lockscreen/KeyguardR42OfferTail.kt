package com.fluvi.app.lockscreen

import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.atomic.AtomicLongArray

/** Recent offer evidence after verbose-mailbox overflow. This is capture-owned
 * diagnostic data, never a source of visibility or scheduling authority.
 * First and recent attempts have independent fixed slots. A producer never
 * waits for another writer or formats a value. */
internal class KeyguardR42OfferTail {
    private val attempts = AtomicLongArray(ATTEMPTS)
    private val versions = AtomicLongArray(SLOTS)
    private val data = AtomicLongArray(SLOTS * STRIDE)
    private val state = AtomicLong()
    val contention = AtomicLong()
    val overwritten = AtomicLong()
    val late = AtomicLong()
    val offerWallNs = AtomicLong()
    val offerMaxWallNs = AtomicLong()
    val offerTimingInvalid = AtomicLong()

    fun offer(attempt: Long, session: Long, wake: Long, request: Long, atNs: Long, tid: Long) {
        if (attempt <= 0 || request <= 0) return
        val startedNs = System.nanoTime()
        try {
            offerInside(attempt, session, wake, request, atNs, tid)
        } finally {
            val elapsed = System.nanoTime() - startedNs
            if (elapsed < 0) offerTimingInvalid.incrementAndGet() else {
                offerWallNs.addAndGet(elapsed)
                while (true) {
                    val previous = offerMaxWallNs.get()
                    if (elapsed <= previous || offerMaxWallNs.compareAndSet(previous, elapsed)) break
                }
            }
        }
    }

    private fun offerInside(attempt: Long, session: Long, wake: Long, request: Long, atNs: Long, tid: Long) {
        while (true) {
            val value = state.get()
            if (value < 0) { late.incrementAndGet(); return }
            if (state.compareAndSet(value, value + 1)) break
        }
        try {
            val group = if (attempt == 1L) 0 else 1 + ((attempt - 2) % (ATTEMPTS - 1)).toInt()
            val ordinal = attempts.getAndIncrement(group)
            val slot = group * PER_ATTEMPT + (ordinal % PER_ATTEMPT).toInt()
            val version = versions.get(slot)
            if ((version and 1L) != 0L || !versions.compareAndSet(slot, version, version + 1)) {
                contention.incrementAndGet()
                return
            }
            try {
                if (version != 0L) overwritten.incrementAndGet()
                val base = slot * STRIDE
                data.set(base, attempt); data.set(base + 1, session); data.set(base + 2, wake)
                data.set(base + 3, request); data.set(base + 4, atNs); data.set(base + 5, tid)
            } finally {
                versions.set(slot, version + 2)
            }
        } finally {
            state.decrementAndGet()
        }
    }

    /** Freeze never waits for a writer; a live writer is an explicit gap. */
    fun cut(): Long {
        while (true) {
            val value = state.get()
            if (value < 0) return value and Long.MAX_VALUE
            if (state.compareAndSet(value, value or Long.MIN_VALUE)) return value
        }
    }

    fun inFlight(): Long = state.get() and Long.MAX_VALUE

    /** Consumer only. An in-flight overwrite is never treated as a record. */
    fun read(slot: Int): Record? {
        val before = versions.get(slot)
        if (before == 0L || (before and 1L) != 0L) return null
        val base = slot * STRIDE
        val result = Record(before, data.get(base), data.get(base + 1), data.get(base + 2),
            data.get(base + 3), data.get(base + 4), data.get(base + 5))
        return result.takeIf { versions.get(slot) == before }
    }

    data class Record(val version: Long, val attempt: Long, val session: Long, val wake: Long,
                      val request: Long, val atNs: Long, val tid: Long)

    companion object {
        private const val ATTEMPTS = 33 // first plus the existing recent-attempt bound
        private const val PER_ATTEMPT = 32
        private const val STRIDE = 6
        const val SLOTS = ATTEMPTS * PER_ATTEMPT
    }
}
