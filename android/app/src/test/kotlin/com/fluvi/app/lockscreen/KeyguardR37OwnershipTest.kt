package com.fluvi.app.lockscreen

import org.junit.Assert.assertFalse
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class KeyguardR37OwnershipTest {
    private val target = KeyguardInspectionAuthority(3, 7, 11, 13, 17)
    private val token = Any()
    private val stamp = KeyguardR37ReservationStamp(token, 101, target, 23, 29)

    @Test fun exactReservationAcrossTheSingleAdoptionIsEligibleForSchedulingOnly() {
        assertTrue(KeyguardR37Ownership.sameAdoption(stamp, token, 101, target, 24, 29))
    }

    @Test fun replacementWakeOrInterveningMutationNeverReusesTheStamp() {
        assertFalse(KeyguardR37Ownership.sameAdoption(stamp, Any(), 101, target, 24, 29))
        assertFalse(KeyguardR37Ownership.sameAdoption(stamp, token, 102, target, 24, 29))
        assertFalse(KeyguardR37Ownership.sameAdoption(stamp, token, 101, target.copy(wakeGeneration = 12), 24, 29))
        assertFalse(KeyguardR37Ownership.sameAdoption(stamp, token, 101, target.copy(attachGeneration = 18), 24, 29))
        assertFalse(KeyguardR37Ownership.sameAdoption(stamp, token, 101, target, 23, 29))
        assertFalse(KeyguardR37Ownership.sameAdoption(stamp, token, 101, target, 25, 29))
        assertFalse(KeyguardR37Ownership.sameAdoption(stamp, token, 101, target, 24, 30))
    }
    @Test fun latestRealQueueOccupantWinsAndOldUnwindCannotReleaseIt() {
        fun request(id: Long) = KeyguardCardInspectionRequest(id, "window", 3, 7, 13, 17, 11, id)
        val queue = KeyguardCardInspectionQueue()
        val a = request(101); val b = request(102); val c = request(103)
        assertTrue(queue.offer(a))
        assertFalse(queue.offer(b))
        assertFalse(queue.offer(c))
        assertNull(queue.handoffOpening(a, b))
        assertEquals(c, queue.handoffOpening(a, c))
        assertEquals(c, queue.activeRequest())
        assertNull(queue.complete(a))
        assertEquals(c, queue.recoverUnwoundReader(a)?.next)
        assertEquals(c, queue.activeRequest())
        assertNull(queue.complete(c))
    }

}
