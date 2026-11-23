package com.fluvi.app.lockscreen

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/** Scalar eligibility is not display authority; the service test observes the real reader. */
class KeyguardR32OverlapPolicyTest {
    private val authority = KeyguardInspectionAuthority(1, 2, 3, 4, 5)
    private fun request(id: Long) = KeyguardCardInspectionRequest(id, "window", 1, 2, 4, 5, 3, 100)
    private val valid = KeyguardR32OverlapPolicy.Facts(
        first = request(10), successor = request(11), authority = authority,
        actualActive = request(10), actualPending = request(11), noPreceding = true,
        genuineFrameworkIngress = true, ingressDisplay = 0, ingressOrigin = KeyguardR14Origin.SYSTEM_UI,
        detached = true, noShowInProgress = true, direct = true, emptyAwaitingDisclosure = true,
        reservationCurrent = true, routeCurrent = true, hostSafe = true, grantNone = true,
        noPaintOrProof = true, noRecovery = true, noQueuedPublication = true,
        freshnessEstablished = true, firstFreshnessRevision = 7, currentFreshnessRevision = 7,
        completeFullMain = true, systemEligible = true, ownUnambiguous = true,
        readScene = 21, currentScene = 22,
    )

    @Test fun actualNewerFrameworkRequestMayOverlapOnlyAfterSceneChanges() {
        assertNull(KeyguardR32OverlapPolicy.rejection(valid))
        assertEquals("scene", KeyguardR32OverlapPolicy.rejection(valid.copy(currentScene = 21)))
        assertEquals("scene", KeyguardR32OverlapPolicy.rejection(valid.copy(readScene = null)))
        assertEquals("scene", KeyguardR32OverlapPolicy.rejection(valid.copy(readScene = 23)))
    }

    @Test fun syntheticWrongDisplayForeignAndEarlierOwnersCannotQualify() {
        val invalid = listOf(
            valid.copy(genuineFrameworkIngress = false),
            valid.copy(ingressDisplay = -1),
            valid.copy(ingressOrigin = KeyguardR14Origin.OWN),
            valid.copy(ingressOrigin = KeyguardR14Origin.OTHER),
            valid.copy(actualActive = request(9)),
            valid.copy(actualPending = request(12)),
            valid.copy(successor = request(9), actualPending = request(9)),
            valid.copy(successor = request(11).copy(wakeGeneration = 9), actualPending = request(11).copy(wakeGeneration = 9)),
            valid.copy(noPreceding = false),
        )
        invalid.forEach { assertEquals(false, KeyguardR32OverlapPolicy.rejection(it) == null) }
    }

    @Test fun anyExistingVisibilityOrDisclosureStateDisallowsOverlap() {
        val invalid = listOf(
            valid.copy(detached = false), valid.copy(noShowInProgress = false), valid.copy(direct = false),
            valid.copy(emptyAwaitingDisclosure = false), valid.copy(reservationCurrent = false),
            valid.copy(routeCurrent = false), valid.copy(hostSafe = false), valid.copy(grantNone = false),
            valid.copy(noPaintOrProof = false), valid.copy(noRecovery = false), valid.copy(noQueuedPublication = false),
        )
        invalid.forEach { assertEquals(false, KeyguardR32OverlapPolicy.rejection(it) == null) }
    }

    @Test fun exactPairCleanupCannotDiscardLatestOrNewerOwner() {
        val queue = KeyguardCardInspectionQueue()
        val a = request(1); val b = request(2); val c = request(3)
        queue.offer(a); queue.offer(b)
        assertEquals(b, queue.reserveSuccessor(a) { true })
        queue.offer(c)
        assertEquals(false, queue.finishPrecedingExact(a, c))
        assertEquals(b, queue.successorForPreceding(a))
        assertEquals(true, queue.finishPrecedingExact(a, b))
        assertEquals(c, queue.complete(b))
        assertEquals(false, queue.finishPrecedingExact(a, b))
        assertEquals(c, queue.activeRequest())
    }

    @Test fun copiedReconciliationDoesNotInheritTheOriginalFrameworkOffer() {
        val event = request(11).copy(r32FrameworkIngressId = 77)
        val reacquired = checkNotNull(event.reacquireAfterWithdrawal(authority, 12, 101,
            KeyguardWindowFreshness.FRAMEWORK_EVENT))
        assertNull(reacquired.r32FrameworkIngressId)
    }

    @Test fun incompleteOrStaleFreshnessCannotBecomePermission() {
        val invalid = listOf(
            valid.copy(freshnessEstablished = false), valid.copy(firstFreshnessRevision = 6),
            valid.copy(firstFreshnessRevision = null), valid.copy(completeFullMain = false),
            valid.copy(systemEligible = false), valid.copy(ownUnambiguous = false),
            valid.copy(successor = request(11).copy(windowFreshness = KeyguardWindowFreshness.LIFECYCLE_BOUNDARY),
                actualPending = request(11).copy(windowFreshness = KeyguardWindowFreshness.LIFECYCLE_BOUNDARY)),
        )
        invalid.forEach { assertEquals(false, KeyguardR32OverlapPolicy.rejection(it) == null) }
    }
}
