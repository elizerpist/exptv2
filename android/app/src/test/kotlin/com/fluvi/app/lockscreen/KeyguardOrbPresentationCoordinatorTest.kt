package com.fluvi.app.lockscreen

import org.junit.Assert.*
import org.junit.Test

class KeyguardOrbPresentationCoordinatorTest {
    private val old = KeyguardInspectionAuthority(1, 2, 3, 4, 5)
    private fun stamp(authority: KeyguardInspectionAuthority = old.copy(wakeGeneration = 4),
                      full: Boolean = false, host: Long = 10, output: Long = 20) =
        KeyguardOrbPresentationStamp(authority, 100, 11, 12, 13, 168, 168, 420, full, host, output, 0)
    private fun reserve(c: KeyguardOrbPresentationCoordinator, s: KeyguardOrbPresentationStamp = stamp(),
                        sample: Long = 1, previous: KeyguardInspectionAuthority = old) =
        requireNotNull(c.reserve(s, sample, previous, previous, sampleEligible = true, routeEligible = true))
    private fun grant(c: KeyguardOrbPresentationCoordinator, token: KeyguardOrbPresentationCoordinator.Reservation,
                      request: Long = 100) = c.grant(token, token.stamp.authority, request, completeMain = true,
        finalSystemEligible = true, disclosedFull = token.stamp.full, selectionRevision = 11, materialRevision = 12, dataRevision = 13)
    private fun reveal(c: KeyguardOrbPresentationCoordinator, token: KeyguardOrbPresentationCoordinator.Reservation,
                       eligible: Boolean = true) = c.queueReveal(token, token.stamp.authority,
        completeMainStillCurrent = true, finalSystemEligible = eligible, selectionRevision = 11, materialRevision = 12, dataRevision = 13)

    @Test fun unqualifiedSampleCannotReserveOrGrant() {
        val c = KeyguardOrbPresentationCoordinator()
        assertNull(c.reserve(stamp(), 1, old, old, sampleEligible = false, routeEligible = true))
        assertNull(c.reserve(stamp(), 1, old, old, sampleEligible = true, routeEligible = false))
        assertNull(c.reserve(stamp(), 1, old, old.copy(interactionEpoch = 99), true, true))
        val token = reserve(c)
        assertNull(c.reserve(stamp(), 1, old, old, true, true))
        assertFalse(grant(c, token)) // reserve is not admission
        assertNull(reveal(c, token))
    }

    @Test fun r21AppliedBeforeMainAckSurvivesOrdinaryIngressButExpiresProof() {
        val lock = Any(); val c = KeyguardOrbPresentationCoordinator(lock); val proof = KeyguardFirstAuthorizedOrb(lock)
        val token = reserve(c, stamp(full = true)); val host = Any(); val image = Any()
        assertTrue(c.adopt(token, token.stamp)); assertTrue(c.attachInertHost(token, host)); assertTrue(c.hostReady(token, host))
        assertTrue(c.attachPreparedOutput(token, image)); assertTrue(c.imageReady(token, image)); assertTrue(grant(c, token))
        assertTrue(c.armInput(token, host)); val permit = requireNotNull(reveal(c, token))
        assertTrue(c.crossSubmitBoundary(permit)); val applied = requireNotNull(c.markNativeApplyReturned(permit))
        assertEquals(KeyguardOrbPresentationCoordinator.Grant.REVEAL_QUEUED, c.snapshot().grant)
        val decision = synchronized(lock) { proof.externalIngress(); c.arbitrateIngress(token, host, image, true) }
        assertEquals(KeyguardOrbPresentationCoordinator.IngressAction.KEEP_SUBMITTED, decision.action)
        assertTrue(decision.ordinal > applied); assertTrue(c.mayAct(token, host))
        assertNull(c.markNativeApplyReturned(permit)); assertTrue(c.revealSubmitted(permit))
        assertFalse(c.revealSubmitted(permit)); assertEquals(KeyguardOrbPresentationCoordinator.Grant.PRESENTED, c.snapshot().grant)
    }

    @Test fun r21PreCrossAndInflightCancellationCannotBeRevived() {
        for (cross in listOf(false, true)) {
            val c = KeyguardOrbPresentationCoordinator(); val token = reserve(c, stamp(full = true)); val host = Any(); val image = Any()
            assertTrue(c.adopt(token, token.stamp)); assertTrue(c.attachInertHost(token, host)); assertTrue(c.hostReady(token, host))
            assertTrue(c.attachPreparedOutput(token, image)); assertTrue(c.imageReady(token, image)); assertTrue(grant(c, token))
            assertTrue(c.armInput(token, host)); val permit = requireNotNull(reveal(c, token))
            if (cross) assertTrue(c.crossSubmitBoundary(permit))
            val decision = c.arbitrateIngress(token, host, image, true)
            assertEquals(KeyguardOrbPresentationCoordinator.IngressAction.CANCEL_PENDING, decision.action)
            assertFalse(c.crossSubmitBoundary(permit)); assertNull(c.markNativeApplyReturned(permit)); assertFalse(c.revealSubmitted(permit))
            val withdrawal = requireNotNull(c.seal(token, token.stamp.authority, 101, true))
            assertEquals(cross, withdrawal.crossedSubmitBoundary)
            assertTrue(c.hostRemoved(token, host)); assertTrue(c.retired(token)); assertTrue(c.outputDrained(token, image))
        }
    }

    @Test fun r21ExclusionAndOldOwnerRemainFailClosedAfterApplied() {
        val c = KeyguardOrbPresentationCoordinator(); val a = reserve(c, stamp(full = true)); val host = Any(); val image = Any()
        assertTrue(c.adopt(a, a.stamp)); assertTrue(c.attachInertHost(a, host)); assertTrue(c.hostReady(a, host))
        assertTrue(c.attachPreparedOutput(a, image)); assertTrue(c.imageReady(a, image)); assertTrue(grant(c, a))
        assertTrue(c.armInput(a, host)); val permit = requireNotNull(reveal(c, a)); assertTrue(c.crossSubmitBoundary(permit))
        assertNotNull(c.markNativeApplyReturned(permit)); assertNotNull(c.seal(a, a.stamp.authority, 101, true))
        assertFalse(c.revealSubmitted(permit)); assertTrue(c.hostRemoved(a, host)); assertTrue(c.retired(a)); assertTrue(c.outputDrained(a, image))
        val previous = a.stamp.authority; val b = reserve(c, stamp(previous.copy(wakeGeneration = 5), full = true, host = 11, output = 21), 2, previous)
        assertEquals(KeyguardOrbPresentationCoordinator.IngressAction.IGNORE, c.arbitrateIngress(a, host, image, true).action)
        assertNull(c.markNativeApplyReturned(permit)); assertFalse(c.revealSubmitted(permit)); assertSame(b, c.snapshot().reservation)
    }

    @Test fun r21InteractionAfterCrossStillAllowsNativeReturnButNotOldAuthoritySeal() {
        val c = KeyguardOrbPresentationCoordinator(); val token = reserve(c, stamp(full = true)); val host = Any(); val image = Any()
        assertTrue(c.adopt(token, token.stamp)); assertTrue(c.attachInertHost(token, host)); assertTrue(c.hostReady(token, host))
        assertTrue(c.attachPreparedOutput(token, image)); assertTrue(c.imageReady(token, image)); assertTrue(grant(c, token))
        assertTrue(c.armInput(token, host)); val permit = requireNotNull(reveal(c, token)); assertTrue(c.crossSubmitBoundary(permit))
        val touched = token.stamp.authority.copy(interactionEpoch = token.stamp.authority.interactionEpoch + 1)
        assertTrue(c.advanceInteraction(token, token.stamp.authority, touched)); assertNotNull(c.markNativeApplyReturned(permit))
        assertTrue(c.revealSubmitted(permit)); assertNull(c.seal(token, token.stamp.authority, 101, true))
        assertNotNull(c.seal(token, touched, 101, true))
    }

    @Test fun stagedHostAndFrameCannotActBeforeAdoptionAndFullProof() {
        val c = KeyguardOrbPresentationCoordinator(); val token = reserve(c); val host = Any(); val image = Any()
        assertTrue(c.attachInertHost(token, host)); assertTrue(c.hostReady(token, host))
        assertTrue(c.attachPreparedOutput(token, image)); assertTrue(c.imageReady(token, image))
        assertFalse(c.armInput(token, host)); assertFalse(c.mayAct(token, host)); assertNull(reveal(c, token))
        assertFalse(c.adopt(token, token.stamp.copy(authority = token.stamp.authority.copy(wakeGeneration = 9))))
        assertTrue(c.adopt(token, token.stamp)); assertFalse(c.adopt(token, token.stamp))
        assertFalse(c.grant(token, token.stamp.authority, 100, false, true, false, 11, 12, 13))
        assertFalse(c.grant(token, token.stamp.authority, 100, true, false, false, 11, 12, 13))
        assertFalse(c.mayAct(token, host))
    }

    @Test fun delayedReadinessRechecksAuthorityAndInputBeforeSubmit() {
        val c = KeyguardOrbPresentationCoordinator(); val token = reserve(c); val host = Any(); val image = Any()
        assertTrue(c.adopt(token, token.stamp)); assertTrue(grant(c, token))
        assertTrue(c.attachInertHost(token, host)); assertTrue(c.hostReady(token, host))
        assertFalse(c.armInput(token, host)) // a missing first image must not swallow a touch
        assertTrue(c.attachPreparedOutput(token, image)); assertTrue(c.imageReady(token, image))
        assertTrue(c.armInput(token, host)); assertNull(reveal(c, token, eligible = false))
        assertNull(c.queueReveal(token, token.stamp.authority, true, true, 11, 99, 13))
        val permit = requireNotNull(reveal(c, token)); assertTrue(c.crossSubmitBoundary(permit))
        assertFalse(c.crossSubmitBoundary(permit)); assertFalse(c.revealSubmitted(permit))
        assertNotNull(c.markNativeApplyReturned(permit)); assertTrue(c.revealSubmitted(permit)); assertTrue(c.mayAct(token, host))
    }

    @Test fun staleNegativeAndWrongDisclosureCannotAuthorizeOrRetire() {
        val c = KeyguardOrbPresentationCoordinator(); val token = reserve(c); val host = Any(); val image = Any()
        assertTrue(c.adopt(token, token.stamp)); assertTrue(c.attachInertHost(token, host)); assertTrue(c.hostReady(token, host))
        assertTrue(c.attachPreparedOutput(token, image)); assertTrue(c.imageReady(token, image))
        assertFalse(c.grant(token, token.stamp.authority, 100, true, true, true, 11, 12, 13))
        assertTrue(grant(c, token, 105)); assertTrue(c.armInput(token, host))
        assertNull(c.seal(token, token.stamp.authority, 104, true))
        assertNull(c.seal(token, token.stamp.authority.copy(wakeGeneration = 99), 106, true))
        assertTrue(c.mayAct(token, host))
    }

    @Test fun sealBeforeSubmitBlocksOldRevealAndRequiresExactHostRemoval() {
        val c = KeyguardOrbPresentationCoordinator(); val token = reserve(c); val host = Any(); val image = Any()
        assertTrue(c.adopt(token, token.stamp)); assertTrue(c.attachInertHost(token, host)); assertTrue(c.hostReady(token, host))
        assertTrue(c.attachPreparedOutput(token, image)); assertTrue(c.imageReady(token, image)); assertTrue(grant(c, token))
        assertTrue(c.armInput(token, host)); val permit = requireNotNull(reveal(c, token))
        val withdrawal = requireNotNull(c.seal(token, token.stamp.authority, 101, true))
        assertFalse(withdrawal.crossedSubmitBoundary); assertFalse(c.crossSubmitBoundary(permit)); assertFalse(c.mayAct(token, host))
        assertFalse(c.hostRemoved(token, Any())); assertFalse(c.retired(token)); assertTrue(c.hostRemoved(token, host))
        assertTrue(c.retired(token)); assertTrue(c.outputDrained(token, image)); assertFalse(c.outputDrained(token, image))
    }

    @Test fun crossedShowIsRetiredInOrderAndLateCallbackCannotRevive() {
        val c = KeyguardOrbPresentationCoordinator(); val token = reserve(c); val host = Any(); val image = Any()
        assertTrue(c.adopt(token, token.stamp)); assertTrue(c.attachInertHost(token, host)); assertTrue(c.hostReady(token, host))
        assertTrue(c.attachPreparedOutput(token, image)); assertTrue(c.imageReady(token, image)); assertTrue(grant(c, token))
        assertTrue(c.armInput(token, host)); val permit = requireNotNull(reveal(c, token)); assertTrue(c.crossSubmitBoundary(permit))
        val withdrawal = requireNotNull(c.seal(token, token.stamp.authority, 101, true))
        assertTrue(withdrawal.crossedSubmitBoundary); assertFalse(c.revealSubmitted(permit)); assertFalse(c.imageReady(token, image))
        assertTrue(c.hostRemoved(token, host)); assertTrue(c.retired(token)); assertTrue(c.outputDrained(token, image))
    }

    @Test fun atMostTwoNativeOwnersRemainUntilTheirActualDrain() {
        val c = KeyguardOrbPresentationCoordinator(); val a = reserve(c); val first = Any()
        assertTrue(c.attachPreparedOutput(a, first)); assertNotNull(c.seal(a, a.stamp.authority, 100, true)); assertTrue(c.retired(a))
        val previous = a.stamp.authority; val bStamp = stamp(previous.copy(wakeGeneration = 5), host = 11, output = 21)
        val b = reserve(c, bStamp, 2, previous); val second = Any()
        assertTrue(c.attachPreparedOutput(b, second)); assertEquals(2, c.snapshot().activeOutputs)
        assertNotNull(c.seal(b, b.stamp.authority, 100, true)); assertTrue(c.retired(b))
        val thirdPrevious = b.stamp.authority; val third = stamp(thirdPrevious.copy(wakeGeneration = 6), host = 12, output = 22)
        assertNull(c.reserve(third, 3, thirdPrevious, thirdPrevious, true, true))
        assertFalse(c.outputDrained(a, second)); assertTrue(c.outputDrained(a, first))
        assertNotNull(c.reserve(third, 3, thirdPrevious, thirdPrevious, true, true))
    }

    @Test fun presentedAttachmentChangesOnlyItsExactAuthority() {
        val c = KeyguardOrbPresentationCoordinator(); val token = reserve(c); val host = Any(); val image = Any()
        assertTrue(c.adopt(token, token.stamp)); assertTrue(c.attachInertHost(token, host)); assertTrue(c.hostReady(token, host))
        assertTrue(c.attachPreparedOutput(token, image)); assertTrue(c.imageReady(token, image)); assertTrue(grant(c, token))
        assertTrue(c.armInput(token, host))
        val before = token.stamp.authority
        val after = before.copy(attachGeneration = before.attachGeneration + 1)
        assertFalse(c.bindPresentedAttachment(token, before, after.copy(interactionEpoch = before.interactionEpoch + 1)))
        assertTrue(c.bindPresentedAttachment(token, before, after))
        assertNull(c.queueReveal(token, before, true, true, 11, 12, 13))
        val permit = requireNotNull(c.queueReveal(token, after, true, true, 11, 12, 13))
        assertTrue(c.crossSubmitBoundary(permit)); assertNotNull(c.markNativeApplyReturned(permit)); assertTrue(c.revealSubmitted(permit))
        assertNull(c.seal(token, before, 101, true))
        assertNotNull(c.seal(token, after, 101, true))
    }

    @Test fun unshownDisclosureReplacementNeedsNewProofAndDrainsOldOutput() {
        val c = KeyguardOrbPresentationCoordinator(); val a = reserve(c); val host = Any(); val oldImage = Any()
        assertTrue(c.adopt(a, a.stamp)); assertTrue(c.attachInertHost(a, host)); assertTrue(c.hostReady(a, host))
        assertTrue(c.attachPreparedOutput(a, oldImage)); assertTrue(c.imageReady(a, oldImage))
        val newStamp = a.stamp.copy(full = true, outputGeneration = 21, firstRequestId = 101)
        val replacement = requireNotNull(c.replaceUnshown(a, newStamp)); val b = replacement.reservation
        assertSame(oldImage, replacement.retiredOutput)
        assertFalse(c.imageReady(a, oldImage)); assertFalse(c.armInput(a, host)); assertFalse(grant(c, a))
        val freshImage = Any(); assertTrue(c.attachPreparedOutput(b, freshImage)); assertTrue(c.imageReady(b, freshImage))
        assertFalse(c.armInput(b, host))
        assertTrue(grant(c, b, 101)); assertTrue(c.armInput(b, host))
        assertTrue(c.outputDrained(a, oldImage)); assertFalse(c.outputDrained(a, freshImage))
    }

    @Test fun sameWakeReadmissionNeedsFreshAuthorityAndDoesNotReuseGrant() {
        val c = KeyguardOrbPresentationCoordinator(); val a = reserve(c); val oldImage = Any()
        assertTrue(c.attachPreparedOutput(a, oldImage)); assertNotNull(c.seal(a, a.stamp.authority, 100, true)); assertTrue(c.retired(a))
        val nextAuthority = a.stamp.authority.copy(visibilityEpoch = a.stamp.authority.visibilityEpoch + 1)
        val next = stamp(nextAuthority, host = 11, output = 21).copy(firstRequestId = 102)
        assertNull(c.reserveReadmission(next, 2, nextAuthority, false, true))
        val b = requireNotNull(c.reserveReadmission(next, 2, nextAuthority, true, true))
        assertNull(reveal(c, b)); assertFalse(c.mayAct(b, Any()))
        assertTrue(c.outputDrained(a, oldImage))
    }

    @Test fun interactionBeforeSubmissionInvalidatesThatPendingReveal() {
        val c = KeyguardOrbPresentationCoordinator(); val token = reserve(c); val host = Any(); val image = Any()
        assertTrue(c.adopt(token, token.stamp)); assertTrue(c.attachInertHost(token, host)); assertTrue(c.hostReady(token, host))
        assertTrue(c.attachPreparedOutput(token, image)); assertTrue(c.imageReady(token, image)); assertTrue(grant(c, token))
        assertTrue(c.armInput(token, host))
        val before = token.stamp.authority
        val attached = before.copy(attachGeneration = before.attachGeneration + 1)
        assertTrue(c.bindPresentedAttachment(token, before, attached))
        val pending = requireNotNull(c.queueReveal(token, attached, true, true, 11, 12, 13))
        val touched = attached.copy(interactionEpoch = attached.interactionEpoch + 1)
        assertTrue(c.advanceInteraction(token, attached, touched))
        assertFalse(c.crossSubmitBoundary(pending))
        assertNull(c.seal(token, attached, 101, true))
        assertNotNull(c.seal(token, touched, 101, true))
    }

    @Test fun abandonedUnpublishedGrantDoesNotAuthorizeInput() {
        val c = KeyguardOrbPresentationCoordinator(); val token = reserve(c); val host = Any(); val image = Any()
        assertTrue(c.adopt(token, token.stamp)); assertTrue(c.attachInertHost(token, host)); assertTrue(c.hostReady(token, host))
        assertTrue(c.attachPreparedOutput(token, image)); assertTrue(c.imageReady(token, image)); assertTrue(grant(c, token))
        assertTrue(c.discardUnpublishedGrant(token)); assertFalse(c.mayAct(token, host)); assertNull(reveal(c, token))
        assertTrue(grant(c, token, 101)); assertTrue(c.armInput(token, host))
        assertFalse(c.discardUnpublishedGrant(token))
    }
}
