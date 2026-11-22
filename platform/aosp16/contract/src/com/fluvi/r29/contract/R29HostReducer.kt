package com.fluvi.r29.contract

/** Identity and readiness only. GPU ownership/release belongs to the renderer. */
internal class R29HostReducer {
    private data class Work(val descriptor: R29Descriptor, val epoch: Long)
    private var session: String? = null
    private var attached = false
    private var epoch = 0L
    private var lastSequence = 0L
    private var running: Work? = null
    private var desired: Work? = null
    private var awaitingAdoption: Work? = null
    private var ready: R29Descriptor? = null

    @Synchronized fun beginSession(value: String): Boolean {
        if (!R29Protocol.validSession(value) || value == session) return false
        epoch += 1
        session = value
        attached = true
        lastSequence = 0
        desired = null
        awaitingAdoption = null
        ready = null
        // A previous worker may still be finishing; no second worker starts until it drains.
        return true
    }

    /** Returns work to start now, or null when rejected or coalesced behind the sole worker. */
    @Synchronized fun prepare(value: R29Descriptor, nowEpochMs: Long, parcelBytes: Int): R29Descriptor? {
        if (!attached || value.session != session || value.sequence <= lastSequence) return null
        lastSequence = value.sequence
        // Even a malformed authenticated replacement cannot leave an older FULL visible.
        ready = null
        awaitingAdoption = null
        desired = null
        if (R29Protocol.invalidReason(value, nowEpochMs, parcelBytes) != null) return null
        val work = Work(R29Protocol.immutable(value), epoch)
        if (running != null) {
            desired = work
            return null
        }
        running = work
        return work.descriptor
    }

    /** Called after real worker completion. A matching result still requires main-owner adoption. */
    @Synchronized fun workerFinished(token: String, sequence: Long): R29Descriptor? {
        val work = running ?: return null
        if (work.descriptor.session != token || work.descriptor.sequence != sequence) return null
        running = null
        if (attached && work.epoch == epoch && token == session && sequence == lastSequence && desired == null) {
            awaitingAdoption = work
        }
        val next = desired
        desired = null
        if (next != null && attached && next.epoch == epoch && next.descriptor.session == session) {
            running = next
            return next.descriptor
        }
        return null
    }

    @Synchronized fun adopt(token: String, sequence: Long, nowEpochMs: Long): Boolean {
        val work = awaitingAdoption ?: return false
        if (!attached || token != session || work.epoch != epoch || work.descriptor.session != token ||
            work.descriptor.sequence != sequence || sequence != lastSequence ||
            R29Protocol.invalidReason(work.descriptor, nowEpochMs, 1) != null) return false
        ready = work.descriptor
        awaitingAdoption = null
        return true
    }

    @Synchronized fun invalidate(token: String, sequence: Long): Boolean {
        if (!attached || token != session || sequence <= lastSequence) return false
        lastSequence = sequence
        ready = null
        awaitingAdoption = null
        desired = null
        return true
    }

    /** A clean detach retains only an adopted, unexpired entry; unfinished work loses authority. */
    @Synchronized fun detach(token: String) {
        if (!attached || token != session) return
        attached = false
        epoch += 1
        desired = null
        awaitingAdoption = null
    }

    /** Host reset, user/display change or package change revokes all local authority. */
    @Synchronized fun reset() {
        epoch += 1
        session = null
        attached = false
        lastSequence = 0
        desired = null
        awaitingAdoption = null
        ready = null
        // Already-running work is still owned until its completion arrives.
    }

    @Synchronized fun current(nowEpochMs: Long): R29Descriptor? {
        val current = ready ?: return null
        if (R29Protocol.invalidReason(current, nowEpochMs, 1) != null) {
            ready = null
            return null
        }
        return current
    }
}
