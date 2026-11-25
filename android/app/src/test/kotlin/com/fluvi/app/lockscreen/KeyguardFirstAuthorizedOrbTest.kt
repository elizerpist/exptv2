package com.fluvi.app.lockscreen

import org.junit.Assert.*
import org.junit.Test

/** Scalar proof gates only: real Android output, worker and compositor are
 * covered separately by the service and compositor instrumentation. */
class KeyguardFirstAuthorizedOrbTest {
    private val authority = KeyguardInspectionAuthority(1, 2, 3, 4, 5)
    private fun proof(gate: KeyguardFirstAuthorizedOrb, request: Long = 10,
                      scene: Long = gate.sceneSerial(), full: Boolean = true) =
        gate.offer(request, authority, scene, 7, 11, 12, 13, 14, 15, full,
            completeMain = true, freshSystemEligible = true)

    @Test fun `read-only Main check rejects newer requirement and changed scene`() {
        val owner = KeyguardFirstAuthorizedOrb()
        owner.requireRead(1)
        owner.readCompleted(1)
        assertTrue(owner.isUnclaimedReadCurrent(1, 0))
        owner.requireRead(2)
        assertFalse(owner.isUnclaimedReadCurrent(1, 0))
        assertTrue(owner.isUnclaimedReadCurrent(2, 0))
        owner.externalIngress()
        assertFalse(owner.isUnclaimedReadCurrent(2, 0))
        assertFalse(owner.isUnclaimedReadCurrent(2, null))
    }

    @Test fun `obsolete positive cannot become successor permission after repeated ingress`() {
        val owner = KeyguardFirstAuthorizedOrb()
        owner.requireRead(135)
        val oldScene = owner.sceneSerial()
        owner.readCompleted(135)
        repeat(3) { owner.externalIngress() }
        owner.requireRead(139)
        assertFalse(owner.isUnclaimedReadCurrent(135, oldScene))
        assertNull(proof(owner, 135, oldScene))
        assertNull(owner.current())
        owner.readCompleted(139)
        val fresh = requireNotNull(proof(owner, 139, owner.sceneSerial()))
        assertEquals(139L, fresh.requestId)
        assertTrue(owner.isCurrent(fresh))
    }

    @Test fun preferenceIsIntentAndDoesNotAuthorizePaint() {
        assertEquals(KeyguardFirstAuthorizedOrb.Intent.EMPTY_AWAITING_DISCLOSURE,
            KeyguardFirstAuthorizedOrb.intent(true))
        assertEquals(KeyguardFirstAuthorizedOrb.Intent.DISCREET_PREPOSTED,
            KeyguardFirstAuthorizedOrb.intent(false))
        val gate = KeyguardFirstAuthorizedOrb()
        assertNull(gate.current())
        assertNull(gate.offer(10, authority, gate.sceneSerial(), 7, 11, 12, 13, 14, 15, true,
            completeMain = false, freshSystemEligible = true))
        assertNull(gate.offer(10, authority, gate.sceneSerial(), 7, 11, 12, 13, 14, 15, true,
            completeMain = true, freshSystemEligible = false))
        assertNull(gate.current())
    }

    @Test fun sceneChangeBeforeCompletionAndBetweenArmAndSubmitRejectsOldProof() {
        val gate = KeyguardFirstAuthorizedOrb(); val readScene = gate.sceneSerial()
        gate.externalIngress()
        assertNull(proof(gate, scene = readScene))
        val current = requireNotNull(proof(gate, 11))
        assertTrue(gate.isCurrent(current))
        assertTrue(gate.consume(current))
        assertFalse(gate.consume(current))
        gate.externalIngress()
        assertFalse(gate.isCurrent(current))
        assertFalse(gate.consume(current))
        val successor = requireNotNull(proof(gate, 12))
        assertTrue(gate.isCurrent(successor))
    }

    @Test fun newerQueuedReadInvalidatesBeforeItStartsAndCannotBeBypassedAtSubmit() {
        val gate = KeyguardFirstAuthorizedOrb()
        gate.requireRead(10); gate.readCompleted(10)
        val proof = requireNotNull(proof(gate, 10))
        assertTrue(gate.consume(proof))
        gate.requireRead(11)
        assertFalse(gate.isCurrent(proof))
        assertNull(proof(gate, 10))
        gate.readCompleted(11)
        assertNotNull(proof(gate, 11))
    }

    @Test fun newerDecisionInvalidatesButEarlierReadAheadPredecessorDoesNot() {
        val gate = KeyguardFirstAuthorizedOrb()
        gate.readCompleted(12)
        val latest = requireNotNull(proof(gate, 12))
        gate.readCompleted(11)
        assertTrue(gate.isCurrent(latest))
        gate.readCompleted(13)
        assertFalse(gate.isCurrent(latest))
        assertNull(proof(gate, 12))
        assertNotNull(proof(gate, 13))
    }

    @Test fun blankOutputCannotArmInputUntilMatchingFirstPostAndRealProof() {
        val lock = Any()
        val gate = KeyguardFirstAuthorizedOrb(lock)
        val coordinator = KeyguardOrbPresentationCoordinator(lock)
        val previous = authority.copy(wakeGeneration = authority.wakeGeneration - 1)
        val stamp = KeyguardOrbPresentationStamp(authority, 10, 13, 14, 15, 168, 168, 420,
            true, 11, 12, 0)
        val token = requireNotNull(coordinator.reserve(stamp, 1, previous, previous, true, true))
        val host = Any(); val output = Any()
        assertTrue(coordinator.adopt(token, stamp))
        assertTrue(coordinator.attachInertHost(token, host)); assertTrue(coordinator.hostReady(token, host))
        assertTrue(coordinator.attachPreparedOutput(token, output))
        gate.readCompleted(10)
        val proof = requireNotNull(gate.offer(10, authority, gate.sceneSerial(), 7, 11, 12, 13, 14, 15,
            true, completeMain = true, freshSystemEligible = true))
        assertTrue(coordinator.grant(token, authority, 10, true, true, true, 13, 14, 15))
        assertFalse("an allocated blank is not frame-ready", coordinator.armInput(token, host))
        assertFalse(coordinator.mayAct(token, host))
        assertTrue(coordinator.imageReady(token, output))
        assertTrue(gate.consume(proof)); assertTrue(coordinator.armInput(token, host))
        val reveal = requireNotNull(coordinator.queueReveal(token, authority, gate.isCurrent(proof), true, 13, 14, 15))
        assertTrue(synchronized(lock) { gate.isCurrent(proof) && coordinator.crossSubmitBoundary(reveal) })
        assertFalse(gate.consume(proof))
    }

    @Test fun externalEventBetweenInputAndSubmitRevokesTheRealCoordinatorBoundary() {
        val lock = Any()
        val gate = KeyguardFirstAuthorizedOrb(lock)
        val coordinator = KeyguardOrbPresentationCoordinator(lock)
        val previous = authority.copy(wakeGeneration = authority.wakeGeneration - 1)
        val stamp = KeyguardOrbPresentationStamp(authority, 10, 13, 14, 15, 168, 168, 420,
            true, 11, 12, 0)
        val token = requireNotNull(coordinator.reserve(stamp, 1, previous, previous, true, true))
        val host = Any(); val output = Any()
        assertTrue(coordinator.adopt(token, stamp)); assertTrue(coordinator.attachInertHost(token, host))
        assertTrue(coordinator.hostReady(token, host)); assertTrue(coordinator.attachPreparedOutput(token, output))
        gate.readCompleted(10)
        val proof = requireNotNull(gate.offer(10, authority, gate.sceneSerial(), 7, 11, 12, 13, 14, 15,
            true, completeMain = true, freshSystemEligible = true))
        assertTrue(coordinator.imageReady(token, output)); assertTrue(gate.consume(proof))
        assertTrue(coordinator.grant(token, authority, 10, true, true, true, 13, 14, 15))
        assertTrue(coordinator.armInput(token, host))
        val reveal = requireNotNull(coordinator.queueReveal(token, authority, gate.isCurrent(proof), true, 13, 14, 15))
        gate.externalIngress()
        assertFalse(synchronized(lock) { gate.isCurrent(proof) && coordinator.crossSubmitBoundary(reveal) })
        assertNotNull(coordinator.seal(token, authority, 11, true))
        assertFalse(coordinator.mayAct(token, host))
    }

    @Test fun r21AppliedOwnerSurvivesWhileTheConsumedProofExpires() {
        val lock = Any(); val gate = KeyguardFirstAuthorizedOrb(lock); val coordinator = KeyguardOrbPresentationCoordinator(lock)
        val previous = authority.copy(wakeGeneration = authority.wakeGeneration - 1)
        val stamp = KeyguardOrbPresentationStamp(authority, 10, 13, 14, 15, 168, 168, 420, true, 11, 12, 0)
        val token = requireNotNull(coordinator.reserve(stamp, 1, previous, previous, true, true))
        val host = Any(); val output = Any()
        assertTrue(coordinator.adopt(token, stamp)); assertTrue(coordinator.attachInertHost(token, host))
        assertTrue(coordinator.hostReady(token, host)); assertTrue(coordinator.attachPreparedOutput(token, output))
        gate.readCompleted(10); val old = requireNotNull(proof(gate, 10)); assertTrue(gate.consume(old))
        assertTrue(coordinator.imageReady(token, output))
        assertTrue(coordinator.grant(token, authority, 10, true, true, true, 13, 14, 15))
        assertTrue(coordinator.armInput(token, host))
        val reveal = requireNotNull(coordinator.queueReveal(token, authority, gate.isCurrent(old), true, 13, 14, 15))
        assertTrue(coordinator.crossSubmitBoundary(reveal)); assertNotNull(coordinator.markNativeApplyReturned(reveal))
        val event = synchronized(lock) { gate.externalIngress(); coordinator.arbitrateIngress(token, host, output, true) }
        assertFalse(gate.isCurrent(old)); assertEquals(KeyguardOrbPresentationCoordinator.IngressAction.KEEP_SUBMITTED, event.action)
        assertTrue(coordinator.revealSubmitted(reveal)); gate.requireRead(11); gate.readCompleted(11)
        val fresh = requireNotNull(proof(gate, 11)); assertTrue(gate.isCurrent(fresh)); assertFalse(gate.isCurrent(old))
    }

    @Test fun terminalOrFreshnessChangeInvalidatesAndOldTicketCannotReappear() {
        val gate = KeyguardFirstAuthorizedOrb(); val first = requireNotNull(proof(gate))
        gate.invalidate()
        assertFalse(gate.isCurrent(first))
        val next = requireNotNull(proof(gate, 11))
        assertFalse(gate.isCurrent(first)); assertTrue(gate.isCurrent(next))
        assertTrue(gate.consume(next)); assertFalse(gate.consume(next))
    }
}
