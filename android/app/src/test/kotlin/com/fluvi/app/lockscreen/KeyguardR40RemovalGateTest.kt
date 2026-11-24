package com.fluvi.app.lockscreen

import android.view.accessibility.AccessibilityEvent
import org.junit.Assert.*
import org.junit.Test

/** The real coordinator supplies the same ownership transitions as production. */
class KeyguardR40RemovalGateTest {
    private val previous = KeyguardInspectionAuthority(1, 2, 3, 4, 5)
    private val current = previous.copy(wakeGeneration = 4)
    private val lock = Any()
    private val coordinator = KeyguardOrbPresentationCoordinator(lock)
    private val gate = KeyguardR40RemovalGate(lock, coordinator)
    private val stamp = KeyguardOrbPresentationStamp(current, 100, 11, 12, 13, 168, 168, 420, true, 10, 20, 0)
    private val token = requireNotNull(coordinator.reserve(stamp, 1, previous, previous, true, true))
    private val host = Any()
    private val output = Any()
    private val evidence = KeyguardR40WindowEvidence(123, 0, 10123, 101, 9, 1101, 1110)

    private fun reveal(): KeyguardOrbPresentationCoordinator.Reveal {
        assertTrue(coordinator.adopt(token, stamp))
        assertTrue(coordinator.attachInertHost(token, host)); assertTrue(coordinator.hostReady(token, host))
        assertTrue(coordinator.attachPreparedOutput(token, output)); assertTrue(coordinator.imageReady(token, output))
        assertTrue(coordinator.grant(token, current, 100, true, true, true, 11, 12, 13))
        assertTrue(coordinator.armInput(token, host))
        return requireNotNull(coordinator.queueReveal(token, current, true, true, 11, 12, 13))
    }
    private fun event(window: Int = 123, display: Int = 0, at: Long? = 1111,
        type: Int = AccessibilityEvent.TYPE_WINDOWS_CHANGED,
        bits: Int = AccessibilityEvent.WINDOWS_CHANGE_REMOVED) =
        KeyguardAccessibilityEventMeta(type, window, display, bits, null, at)

    @Test fun provenanceCannotArmBeforeCrossDuringApplyOrBeforeAck() {
        val reveal = reveal()
        assertFalse(gate.armPresented(evidence, reveal, current, 9, 10123))
        assertTrue(coordinator.crossSubmitBoundary(reveal))
        assertFalse(gate.armPresented(evidence, reveal, current, 9, 10123))
        assertNotNull(coordinator.markNativeApplyReturned(reveal))
        assertFalse(gate.armPresented(evidence, reveal, current, 9, 10123))
        assertNull(gate.remove(event(), 1200, true, false, token, current, 10123))
        assertTrue(coordinator.revealSubmitted(reveal))
        assertTrue(gate.armPresented(evidence, reveal, current, 9, 10123))
    }

    @Test fun exactGenuineRemovalSealsOnlyThePresentedOwner() {
        val reveal = reveal(); assertTrue(coordinator.crossSubmitBoundary(reveal))
        assertNotNull(coordinator.markNativeApplyReturned(reveal)); assertTrue(coordinator.revealSubmitted(reveal))
        assertTrue(gate.armPresented(evidence, reveal, current, 9, 10123))
        assertNull(gate.remove(event(window = 999), 1200, true, false, token, current, 10123))
        assertNull(gate.remove(event(display = 1), 1200, true, false, token, current, 10123))
        assertNull(gate.remove(event(at = 1110), 1200, true, false, token, current, 10123))
        assertNull(gate.remove(event(at = null), 1200, true, false, token, current, 10123))
        assertNull(gate.remove(event(at = 1201), 1200, true, false, token, current, 10123))
        assertNull(gate.remove(event(bits = AccessibilityEvent.WINDOWS_CHANGE_ADDED), 1200, true, false, token, current, 10123))
        assertNull(gate.remove(event(), 1200, false, false, token, current, 10123))
        assertNull(gate.remove(event(), 1200, true, true, token, current, 10123))
        assertNull(gate.remove(event(), 1200, true, false, token, current.copy(wakeGeneration = 5), 10123))
        assertNull(gate.remove(event(), 1200, true, false, token, current, 10124))
        assertNotNull(gate.remove(event(), 1200, true, false, token, current, 10123))
        assertEquals(KeyguardOrbPresentationCoordinator.Grant.REVOKED, coordinator.snapshot().grant)
        assertFalse(gate.armPresented(evidence, reveal, current, 9, 10123))
    }

    @Test fun staleReadAndUnobservedWitnessCannotRearmRevokedGeneration() {
        val reveal = reveal(); assertTrue(coordinator.crossSubmitBoundary(reveal))
        assertNotNull(coordinator.markNativeApplyReturned(reveal)); assertTrue(coordinator.revealSubmitted(reveal))
        assertFalse(gate.armPresented(evidence, reveal, current, 10, 10123))
        assertFalse(gate.armPresented(evidence.copy(readStartedAt = 0), reveal, current, 9, 10123))
        assertFalse(gate.armPresented(evidence.copy(readFinishedAt = 1100), reveal, current, 9, 10123))
        assertNull(gate.remove(event(), 1200, true, false, token, current, 10123))
        assertNotNull(coordinator.seal(token, current, Long.MAX_VALUE, true))
        assertFalse(gate.armPresented(evidence, reveal, current, 9, 10123))
        assertTrue(coordinator.hostRemoved(token, host)); assertTrue(coordinator.retired(token))
        assertTrue(coordinator.outputDrained(token, output))
        val newer = current.copy(wakeGeneration = 5)
        val next = requireNotNull(coordinator.reserve(stamp.copy(authority = newer, hostGeneration = 11, outputGeneration = 21),
            2, current, current, true, true))
        assertNull(gate.remove(event(at = 1201), 1300, true, false, next, newer, 10123))
        assertSame(next, coordinator.snapshot().reservation)
    }
}
