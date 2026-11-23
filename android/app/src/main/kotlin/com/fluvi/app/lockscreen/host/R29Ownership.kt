package com.fluvi.app.lockscreen.host

/**
 * Reference-host ownership gate. The persistent flag is committed BEFORE
 * draining the app's old owner and cleared only after a matching host-empty
 * acknowledgement. A caller must wire [appMayShow] into BOTH admission and
 * final submission before using [hostMayBeRequested] to pair a real host.
 *
 * This class by itself does not change the production window path.
 */
internal class R29Ownership(private val store: Store) {
    interface Store {
        fun read(): Persisted
        fun write(value: Persisted): Boolean
    }

    data class Persisted(val suppressed: Boolean, val epoch: Long, val valid: Boolean = true)
    enum class Phase { STOCK, DRAINING, QUIESCENT, HOST, LEAVING, BLOCKED }

    private val restored = store.read()
    private var epoch = restored.epoch
    private var phase = when {
        !restored.valid || restored.epoch < 0 -> Phase.BLOCKED
        restored.suppressed -> Phase.DRAINING
        else -> Phase.STOCK
    }

    @Synchronized fun phase(): Phase = phase
    @Synchronized fun epoch(): Long = epoch
    @Synchronized fun appMayShow(): Boolean = phase == Phase.STOCK
    @Synchronized fun hostMayBeRequested(): Boolean = phase == Phase.QUIESCENT || phase == Phase.HOST
    @Synchronized fun isCurrentHost(value: Long): Boolean = phase == Phase.HOST && epoch == value

    /** Returns the epoch to drain, or null when durable suppression failed. */
    @Synchronized fun beginEnrollment(): Long? {
        if (phase != Phase.STOCK || epoch == Long.MAX_VALUE) return null
        val next = epoch + 1L
        if (!store.write(Persisted(suppressed = true, epoch = next))) return null
        epoch = next
        phase = Phase.DRAINING
        return next
    }

    /** Only a real completed drain for this epoch grants host-side eligibility. */
    @Synchronized fun oldOwnerDrained(value: Long): Boolean {
        if (phase != Phase.DRAINING || value != epoch) return false
        phase = Phase.QUIESCENT
        return true
    }

    @Synchronized fun hostOwns(value: Long): Boolean {
        if (phase != Phase.QUIESCENT || value != epoch) return false
        phase = Phase.HOST
        return true
    }

    /** Binder loss never re-enables the legacy owner. */
    @Synchronized fun hostUnavailable() {
        if (phase == Phase.HOST || phase == Phase.QUIESCENT) phase = Phase.DRAINING
    }

    /** A late disconnect from an earlier enrollment must not revoke a newer host. */
    @Synchronized fun hostUnavailable(value: Long) {
        if (value == epoch && (phase == Phase.HOST || phase == Phase.QUIESCENT)) phase = Phase.DRAINING
    }

    @Synchronized fun beginExit(): Long? {
        if (phase == Phase.STOCK || phase == Phase.BLOCKED || phase == Phase.LEAVING) return null
        phase = Phase.LEAVING
        return epoch
    }

    /** A lost/stale/failed empty ACK leaves suppression in force. */
    @Synchronized fun hostConfirmedEmpty(value: Long): Boolean {
        if (phase != Phase.LEAVING || value != epoch) return false
        if (!store.write(Persisted(suppressed = false, epoch = epoch))) return false
        phase = Phase.STOCK
        return true
    }
}
