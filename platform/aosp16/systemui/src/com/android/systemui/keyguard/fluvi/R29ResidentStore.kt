package com.android.systemui.keyguard.fluvi

import com.fluvi.r29.contract.R29Descriptor
import com.fluvi.r29.contract.R29HostReducer
import com.fluvi.r29.contract.R29Protocol
import java.util.concurrent.Executor
import java.util.concurrent.atomic.AtomicReference

/**
 * Host-owned, in-memory ready state. Authentication and authoritative system
 * restriction observations belong to the caller. There is no disk restore.
 */
internal class R29ResidentStore(
    private val renderer: R29HostRenderer,
    private val worker: Executor,
    private val main: Executor,
    private val onChanged: () -> Unit,
) {
    private val lock = Any()
    private val reducer = R29HostReducer()
    private val ready = AtomicReference<R29PreparedOrb?>(null)
    private var session: String? = null
    private var attached = false
    private var latestSequence = 0L
    private var callback: ((String, Long) -> Unit)? = null

    fun beginSession(nonce: String, onReady: (String, Long) -> Unit): Boolean {
        val accepted = synchronized(lock) {
            if (!reducer.beginSession(nonce)) return@synchronized false
            session = nonce
            attached = true
            latestSequence = 0L
            callback = onReady
            ready.set(null)
            true
        }
        if (accepted) changed()
        return accepted
    }

    /** Caller must already have verified the Binder caller and enrollment. */
    fun prepare(descriptor: R29Descriptor, nowEpochMs: Long, actualParcelBytes: Int): Boolean {
        var next: R29Descriptor? = null
        val valid = synchronized(lock) {
            if (!attached || descriptor.session != session || descriptor.sequence <= latestSequence) return@synchronized false
            latestSequence = descriptor.sequence
            // Authenticated semantic replacement immediately revokes old FULL.
            ready.set(null)
            val error = R29Protocol.invalidReason(descriptor, nowEpochMs, actualParcelBytes)
            next = reducer.prepare(descriptor, nowEpochMs, actualParcelBytes)
            error == null
        }
        changed()
        next?.let(::enqueue)
        return valid
    }

    fun invalidate(nonce: String, sequence: Long): Boolean {
        val applied = synchronized(lock) {
            if (!attached || nonce != session || sequence <= latestSequence) return@synchronized false
            if (!reducer.invalidate(nonce, sequence)) return@synchronized false
            latestSequence = sequence
            ready.set(null)
            true
        }
        if (applied) changed()
        return applied
    }

    /** Only previously adopted output survives a clean publisher disconnect. */
    fun detach(nonce: String) = synchronized(lock) {
        if (nonce == session) {
            reducer.detach(nonce)
            attached = false
            callback = null
        }
    }

    fun reset() {
        synchronized(lock) {
            reducer.reset()
            session = null
            attached = false
            latestSequence = 0L
            callback = null
            ready.set(null)
        }
        changed()
    }

    /** An actual draw must additionally apply the trusted same-frame scene policy. */
    fun current(nowEpochMs: Long): R29PreparedOrb? = synchronized(lock) {
        val value = ready.get() ?: return@synchronized null
        val eligible = reducer.current(nowEpochMs)
        if (eligible == null || eligible.session != value.descriptor.session ||
            eligible.sequence != value.descriptor.sequence) {
            ready.set(null)
            return@synchronized null
        }
        value
    }

    private fun enqueue(work: R29Descriptor) {
        worker.execute {
            renderer.prepare(work) { result ->
                var next: R29Descriptor? = null
                var notify: ((String, Long) -> Unit)? = null
                synchronized(lock) {
                    next = reducer.workerFinished(work.session, work.sequence)
                    val output = result.getOrNull()
                    if (output != null && reducer.adopt(work.session, work.sequence, System.currentTimeMillis())) {
                        ready.set(output)
                        if (session == work.session) notify = callback
                    }
                }
                if (notify != null) {
                    changed()
                    val captured = notify
                    main.execute { runCatching { captured?.invoke(work.session, work.sequence) } }
                }
                next?.let(::enqueue)
            }
        }
    }

    private fun changed() { main.execute { onChanged() } }
}
