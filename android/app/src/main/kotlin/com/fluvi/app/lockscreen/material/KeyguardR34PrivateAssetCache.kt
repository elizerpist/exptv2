package com.fluvi.app.lockscreen.material

import java.util.concurrent.atomic.AtomicBoolean

/** One desired private resource and one ready resource. A lease is separate
 * from cache authority, so eviction cannot dispose a resource in use. */
internal class KeyguardR34PrivateAssetCache<K : Any, V : Any>(
    private val release: (V) -> Unit,
) {
    class Ticket<K : Any> internal constructor(val generation: Long, val key: K)
    private class Entry<K : Any, V : Any>(val ticket: Ticket<K>, val value: V) {
        var leases = 0
        var retired = false
    }
    class Lease<V : Any> internal constructor(val value: V, private val finish: () -> Unit) : AutoCloseable {
        private val closed = AtomicBoolean(false)
        override fun close() { if (closed.compareAndSet(false, true)) finish() }
    }

    private val lock = Any()
    private var generation = 0L
    private var desired: Ticket<K>? = null
    private var ready: Entry<K, V>? = null
    // At most the two existing native output generations can borrow an image.
    // A missing platform release therefore blocks admission instead of growing
    // a chain of retired buffers without bound.
    private var outstandingLeases = 0
    private var closed = false

    /** Equal re-publication preserves the same request. Any real transition,
     * including A/B/A, gets a new identity even if A's values reappear. */
    fun request(key: K): Ticket<K>? {
        var retired: V? = null
        val next = synchronized(lock) {
            if (closed || desired?.key == key) return@synchronized null
            ready?.let { entry ->
                entry.retired = true
                if (entry.leases == 0) retired = entry.value
            }
            ready = null
            Ticket(++generation, key).also { desired = it }
        }
        retired?.let(release)
        return next
    }

    fun isCurrent(ticket: Ticket<K>): Boolean = synchronized(lock) { !closed && desired === ticket }

    /** Takes ownership of value whether accepted or rejected. */
    fun publish(ticket: Ticket<K>, value: V): Boolean {
        val accepted = synchronized(lock) {
            if (closed || desired !== ticket || ready != null) false
            else { ready = Entry(ticket, value); true }
        }
        if (!accepted) release(value)
        return accepted
    }

    fun failed(ticket: Ticket<K>) {
        synchronized(lock) { if (desired === ticket && ready == null) desired = null }
    }

    fun acquire(key: K): Lease<V>? = synchronized(lock) {
        val entry = ready ?: return@synchronized null
        if (closed || entry.retired || desired !== entry.ticket || entry.ticket.key != key ||
            outstandingLeases >= MAX_LEASES) return@synchronized null
        entry.leases++
        outstandingLeases++
        Lease(entry.value) { releaseLease(entry) }
    }

    private fun releaseLease(entry: Entry<K, V>) {
        val released = synchronized(lock) {
            check(entry.leases > 0 && outstandingLeases > 0)
            entry.leases--
            outstandingLeases--
            if (entry.retired && entry.leases == 0) entry.value else null
        }
        released?.let(release)
    }

    fun clear() = retire(close = false)
    fun close() = retire(close = true)

    private companion object { const val MAX_LEASES = 2 }

    private fun retire(close: Boolean) {
        var retired: V? = null
        synchronized(lock) {
            generation++
            desired = null
            if (close) closed = true
            ready?.let { entry ->
                entry.retired = true
                if (entry.leases == 0) retired = entry.value
            }
            ready = null
        }
        retired?.let(release)
    }
}
