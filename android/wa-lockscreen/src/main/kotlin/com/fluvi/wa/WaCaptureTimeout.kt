package com.fluvi.wa

/** The current service connection owns this controller on Main. */
internal class WaCaptureTimeout(
    private val readTimeout: () -> Long?,
    private val writeTimeout: (Long) -> Unit,
) {
    enum class Error {
        SERVICE_UNAVAILABLE, FOREGROUND_REQUIRED, WINDOW_ACTIVE, INVALID_ARM, ALREADY_RECORDING,
        BASELINE_MISMATCH, ARM_READBACK_FAILED, TIMEOUT_CHANGED, SERVICE_DISCONNECTED, CAPTURE_SETUP_FAILED,
    }

    enum class Restoration { NONE, ACTIVE, PENDING, RESTORED, NORMALIZED }

    class Lease(val capture: String, val baseline: Long, val requested: Long) {
        var readback: Long? = null
            internal set
        var restoreReadback: Long? = null
            internal set
        var error: Error? = null
            internal set
        var restoration = Restoration.ACTIVE
            internal set
    }

    internal data class ArmResult(val lease: Lease?, val error: Error?)

    private var current: Lease? = null
    var normalization = Restoration.NONE
        private set

    fun read(): Long? = runCatching(readTimeout).getOrNull()

    fun normalize() {
        if (current != null) return
        normalization = if (read() == ORDINARY || apply(ORDINARY) == ORDINARY) {
            Restoration.NORMALIZED
        } else Restoration.PENDING
    }

    fun arm(capture: String, requested: Long): ArmResult {
        if (current != null) return ArmResult(null, Error.ALREADY_RECORDING)
        if (requested != 0L && requested != ORDINARY) return ArmResult(null, Error.INVALID_ARM)
        val baseline = read()
        if (baseline != ORDINARY || normalization != Restoration.NORMALIZED) {
            return ArmResult(null, Error.BASELINE_MISMATCH)
        }
        val lease = Lease(capture, baseline, requested)
        current = lease
        lease.readback = apply(requested)
        if (lease.readback != requested) {
            lease.error = Error.ARM_READBACK_FAILED
            restore(lease)
        }
        return ArmResult(lease, lease.error)
    }

    fun verify(lease: Lease) {
        if (current !== lease || lease.restoration != Restoration.ACTIVE) return
        if (read() != lease.requested && lease.error == null) lease.error = Error.TIMEOUT_CHANGED
    }

    fun restore(lease: Lease, disconnected: Boolean = false) {
        if (current !== lease) return
        if (disconnected && lease.error == null) lease.error = Error.SERVICE_DISCONNECTED
        verify(lease)
        lease.restoreReadback = if (lease.error != Error.ARM_READBACK_FAILED && read() == lease.baseline) {
            lease.baseline
        } else apply(lease.baseline)
        if (lease.restoreReadback == lease.baseline) {
            lease.restoration = Restoration.RESTORED
            current = null
        } else {
            lease.restoration = Restoration.PENDING
        }
    }

    fun retryPendingRestoration() {
        current?.takeIf { it.restoration == Restoration.PENDING }?.let(::restore)
    }

    private fun apply(value: Long): Long? = try {
        writeTimeout(value)
        read()
    } catch (_: RuntimeException) {
        null
    }

    companion object {
        const val ORDINARY = 50L
    }
}
