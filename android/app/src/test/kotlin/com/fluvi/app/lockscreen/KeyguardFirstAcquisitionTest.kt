package com.fluvi.app.lockscreen

import org.junit.Assert.*
import org.junit.Test

class KeyguardFirstAcquisitionTest {
    private val owner = KeyguardInspectionAuthority(1, 2, 3, 4, 5)
    private fun request(id: Long, authority: KeyguardInspectionAuthority = owner) =
        KeyguardCardInspectionRequest(id, "window", authority.serviceSession, authority.visibilityEpoch,
            authority.interactionEpoch, authority.attachGeneration, authority.wakeGeneration, id)
    private fun ticket(authority: KeyguardInspectionAuthority = owner,
                       reason: KeyguardWindowFreshness = KeyguardWindowFreshness.LIFECYCLE_BOUNDARY) =
        KeyguardInspectionFreshness.Ticket(authority, 1L, reason)

    @Test fun coalescedOfferConsumesOnlyAtTheFirstActualRead() {
        val gate = KeyguardFirstAcquisition().also { it.begin(owner, true) }
        val queue = KeyguardCardInspectionQueue()
        val blocked = request(1, owner.copy(wakeGeneration = 2))
        queue.offer(blocked)
        queue.offer(request(2))
        queue.offer(request(3))
        assertFalse(gate.take(blocked, null)) // abandoned stale work never entered the reader
        val first = requireNotNull(queue.complete(blocked))
        assertEquals(3L, first.id)
        assertTrue(gate.take(first, ticket()))
        assertFalse(gate.take(request(4), ticket()))
    }

    @Test fun ineligibleOrFailedFirstAttemptNeverRearmsWithinTheWake() {
        val gate = KeyguardFirstAcquisition().also { it.begin(owner, true) }
        assertFalse(gate.take(request(1), ticket(reason = KeyguardWindowFreshness.MISSING_FRESHNESS_EVIDENCE)))
        assertFalse(gate.take(request(2), ticket()))
        gate.begin(owner.copy(wakeGeneration = 4), false)
        val next = owner.copy(wakeGeneration = 4)
        assertFalse(gate.take(request(3, next), ticket(next)))
        assertFalse(gate.take(request(4, next), ticket(next)))
    }

    @Test fun changedAuthorityOrConfigurationFailsClosedUntilANewWake() {
        val gate = KeyguardFirstAcquisition().also { it.begin(owner, true) }
        gate.invalidate()
        assertFalse(gate.take(request(1), ticket()))
        val next = owner.copy(wakeGeneration = 4)
        gate.begin(next, true)
        val changed = next.copy(interactionEpoch = 9)
        assertFalse(gate.take(request(2, changed), ticket(changed)))
        assertFalse(gate.take(request(3, next), ticket(next)))
        val later = next.copy(wakeGeneration = 5)
        gate.begin(later, true)
        assertTrue(gate.take(request(4, later), ticket(later)))
    }

    @Test fun staleTicketCannotSpendAnotherWake() {
        val gate = KeyguardFirstAcquisition().also { it.begin(owner, true) }
        val stale = owner.copy(visibilityEpoch = 90)
        assertFalse(gate.take(request(1, stale), ticket()))
        assertTrue(gate.take(request(2), ticket()))
    }
}
