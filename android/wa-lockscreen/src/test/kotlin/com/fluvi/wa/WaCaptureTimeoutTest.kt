package com.fluvi.wa

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class WaCaptureTimeoutTest {
    private class Service {
        var timeout: Long? = 50
        var flags = 0x20
        var blocked = false
        var forceReadback: Long? = null
        var writes = mutableListOf<Long>()
        val policy = WaCaptureTimeout({ forceReadback ?: timeout }) { value ->
            writes.add(value)
            check(!blocked)
            timeout = value
        }.also(WaCaptureTimeout::normalize)
    }

    @Test fun bothArmsAcknowledgeAnActualSetterAndPreserveFlags() {
        val service = Service()
        val a = service.policy.arm("a", 50)
        assertNull(a.error)
        assertEquals(50L, a.lease!!.readback)
        assertEquals(WaCaptureTimeout.Error.ALREADY_RECORDING, service.policy.arm("double", 0).error)
        service.policy.restore(a.lease)
        val b = service.policy.arm("b", 0).lease!!
        service.flags = 0x30
        service.policy.restore(a.lease)
        assertEquals(0L, service.timeout)
        service.policy.restore(b)
        assertEquals(50L, b.restoreReadback)
        assertEquals(WaCaptureTimeout.Restoration.RESTORED, b.restoration)
        assertEquals(listOf(50L, 0L, 50L), service.writes)
        assertEquals(0x30, service.flags)
    }

    @Test fun failedArmReadbackNeverBecomesValid() {
        val service = Service()
        service.forceReadback = 50
        val failed = service.policy.arm("b", 0)
        assertEquals(WaCaptureTimeout.Error.ARM_READBACK_FAILED, failed.error)
        // The platform can claim the old value without actually applying the
        // new one. A failed arm must still actively request the baseline.
        assertEquals(50L, service.timeout)
        service.forceReadback = null
        assertEquals(50L, service.policy.read())
    }

    @Test fun failedRestoreIsPendingAndReconnectNormalizesOnlyItsOwnTimeout() {
        val old = Service()
        val b = old.policy.arm("b", 0).lease!!
        old.blocked = true
        old.policy.restore(b, disconnected = true)
        assertEquals(WaCaptureTimeout.Error.SERVICE_DISCONNECTED, b.error)
        assertEquals(WaCaptureTimeout.Restoration.PENDING, b.restoration)
        val fresh = Service()
        fresh.timeout = old.timeout // Framework retained the dead connection's dynamic info.
        fresh.policy.normalize()
        assertEquals(50L, fresh.timeout)
        val next = fresh.policy.arm("next", 0).lease!!
        fresh.policy.restore(b)
        assertEquals(0L, fresh.timeout)
        assertEquals(WaCaptureTimeout.Restoration.ACTIVE, next.restoration)
    }

    @Test fun externalTimeoutDriftIsInvalidEvenAfterRestorationSucceeds() {
        val service = Service()
        val b = service.policy.arm("b", 0).lease!!
        service.timeout = 25
        service.policy.verify(b)
        assertEquals(WaCaptureTimeout.Error.TIMEOUT_CHANGED, b.error)
        service.policy.restore(b)
        assertEquals(50L, service.timeout)
        assertEquals(WaCaptureTimeout.Restoration.RESTORED, b.restoration)
    }

    @Test fun unknownBaselineAndRejectedSetterFailClosed() {
        val service = Service()
        service.timeout = null
        assertEquals(WaCaptureTimeout.Error.BASELINE_MISMATCH, service.policy.arm("bad-baseline", 0).error)
        service.timeout = 50
        service.blocked = true
        assertEquals(WaCaptureTimeout.Error.ARM_READBACK_FAILED, service.policy.arm("bad-setter", 0).error)
    }
}
