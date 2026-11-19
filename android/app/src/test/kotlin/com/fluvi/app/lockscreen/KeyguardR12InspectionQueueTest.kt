package com.fluvi.app.lockscreen

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Pure queue ownership controls. Real Binder and Main ordering is checked by
 * the independent service instrumentation; this class cannot prove pixels or
 * any Android lifecycle transition. */
class KeyguardR12InspectionQueueTest {
    private fun request(id: Long) = KeyguardCardInspectionRequest(
        id = id, trigger = "r12-test", session = 1L, visibilityEpoch = 2L,
        interactionEpoch = 3L, attachGeneration = 4L, wakeGeneration = 5L,
        queuedAtUptimeMs = id,
    )

    @Test fun reservedSuccessorRemainsThePrecedingDecisionFollowup() {
        val queue = KeyguardCardInspectionQueue()
        val a = request(1)
        val b = request(2)
        val c = request(3)
        assertTrue(queue.offer(a))
        assertFalse(queue.offer(b))

        assertEquals(b, queue.reserveSuccessor(a) { true })
        assertEquals(b, queue.activeRequest())
        assertEquals(b, queue.successorForPreceding(a))
        assertFalse(queue.offer(c))
        assertEquals(c, queue.pendingRequest())
        assertEquals("new latest C must not replace A's reserved B", b, queue.successorForPreceding(a))
        assertNull("early B cannot release its reader slot before ordered A completes", queue.complete(b))

        assertTrue(queue.finishPreceding(a))
        assertFalse(queue.finishPreceding(a))
        assertEquals(c, queue.complete(b))
        assertNull(queue.complete(c))
    }

    @Test fun failedProofKeepsTheOrdinarySerialQueue() {
        val queue = KeyguardCardInspectionQueue()
        val a = request(1)
        val b = request(2)
        assertTrue(queue.offer(a))
        assertFalse(queue.offer(b))

        assertNull(queue.reserveSuccessor(a) { false })
        assertNull(queue.reserveSuccessor(request(99)) { true })
        assertEquals(a, queue.activeRequest())
        assertEquals(b, queue.pendingRequest())
        assertEquals(b, queue.complete(a))
    }

    @Test fun terminalClearsLatestButCannotReviveOrReleaseReservedReader() {
        val queue = KeyguardCardInspectionQueue()
        val a = request(1)
        val b = request(2)
        queue.offer(a)
        queue.offer(b)
        assertEquals(b, queue.reserveSuccessor(a) { true })
        queue.offer(request(3))
        queue.clearPending()
        assertNull(queue.pendingRequest())
        assertEquals(b, queue.activeRequest())
        assertNull(queue.reserveSuccessor(b) { true })
        assertNull(queue.complete(a))
        assertTrue(queue.finishPreceding(a))
        assertNull(queue.complete(b))
        assertNull(queue.activeRequest())
    }
}
