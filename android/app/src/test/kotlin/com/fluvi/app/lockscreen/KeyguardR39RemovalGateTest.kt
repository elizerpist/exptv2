package com.fluvi.app.lockscreen

import android.view.accessibility.AccessibilityEvent
import org.junit.Assert.*
import org.junit.Test

/** Uses the production coordinator, not a fake authority or synthetic release. */
class KeyguardR39RemovalGateTest {
    private val old = KeyguardInspectionAuthority(1, 2, 3, 4, 5)
    private val current = old.copy(wakeGeneration = 4)
    private val lock = Any()
    private val coordinator = KeyguardOrbPresentationCoordinator(lock)
    private val gate = KeyguardR39RemovalGate(lock, coordinator)
    private val stamp = KeyguardOrbPresentationStamp(current, 100, 11, 12, 13, 168, 168, 420, true, 10, 20, 0)
    private val token = requireNotNull(coordinator.reserve(stamp, 1, old, old, true, true))
    private val host = Any()
    private val output = Any()
    private val evidence = KeyguardR39WindowEvidence(123, 0, 10123, 100, 9, 1000)

    private fun applied(ack: Boolean = false): KeyguardOrbPresentationCoordinator.Reveal {
        assertTrue(coordinator.adopt(token, stamp))
        assertTrue(coordinator.attachInertHost(token, host)); assertTrue(coordinator.hostReady(token, host))
        assertTrue(coordinator.attachPreparedOutput(token, output)); assertTrue(coordinator.imageReady(token, output))
        assertTrue(coordinator.grant(token, current, 100, true, true, true, 11, 12, 13))
        assertTrue(coordinator.armInput(token, host))
        val reveal = requireNotNull(coordinator.queueReveal(token, current, true, true, 11, 12, 13))
        assertTrue(coordinator.crossSubmitBoundary(reveal))
        assertNotNull(coordinator.markNativeApplyReturned(reveal))
        if (ack) assertTrue(coordinator.revealSubmitted(reveal))
        return reveal
    }

    private fun event(window: Int = 123, display: Int = 0,
        bits: Int = AccessibilityEvent.WINDOWS_CHANGE_REMOVED, at: Long? = 1101,
        type: Int = AccessibilityEvent.TYPE_WINDOWS_CHANGED) =
        KeyguardAccessibilityEventMeta(type, window, display, bits, null, at)

    @Test fun exactRemovalSealsAppliedOwnerBeforeLateAck() {
        val reveal = applied()
        assertTrue(gate.arm(evidence, reveal, current, 9, 10123, 1100))
        val removal = gate.remove(event(), 1200, true, false, token, current, 10123)
        assertNotNull(removal)
        assertSame(token, removal!!.reservation)
        assertEquals(KeyguardOrbPresentationCoordinator.Grant.REVOKED, coordinator.snapshot().grant)
        assertFalse(coordinator.revealSubmitted(reveal))
        assertNull(gate.remove(event(at = 1102), 1200, true, false, token, current, 10123))
    }

    @Test fun unrelatedAndAmbiguousEventsCannotRevokeAVisibleOwner() {
        val reveal = applied(true)
        assertTrue(gate.armPresented(evidence, reveal, current, 9, 10123, 1100))
        val negatives = listOf(event(window = 999), event(display = 1), event(bits = 0),
            event(bits = AccessibilityEvent.WINDOWS_CHANGE_ADDED), event(at = 1100),
            event(at = 1099), event(at = null), event(at = 1300),
            event(type = AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED))
        for (item in negatives) assertNull(gate.remove(item, 1200, true, false, token, current, 10123))
        assertNull(gate.remove(event(), 1200, false, false, token, current, 10123))
        assertNull(gate.remove(event(), 1200, true, true, token, current, 10123))
        assertNull(gate.remove(event(), 1200, true, false, token, current.copy(wakeGeneration = 5), 10123))
        assertNull(gate.remove(event(), 1200, true, false, token, current, 10124))
        assertTrue(coordinator.mayAct(token, host))
    }

    @Test fun oldReceiptCannotRearmAfterRetirementOrReusedWindow() {
        val reveal = applied()
        assertTrue(gate.arm(evidence, reveal, current, 9, 10123, 1100))
        assertNotNull(gate.remove(event(), 1200, true, false, token, current, 10123))
        assertFalse(gate.arm(evidence, reveal, current, 9, 10123, 1100))
        assertFalse(coordinator.revealSubmitted(reveal))
        assertTrue(coordinator.hostRemoved(token, host)); assertTrue(coordinator.retired(token))
        assertTrue(coordinator.outputDrained(token, output))
        val newer = current.copy(wakeGeneration = 5)
        val next = requireNotNull(coordinator.reserve(stamp.copy(authority = newer, hostGeneration = 11, outputGeneration = 21),
            2, current, current, true, true))
        assertNull(gate.remove(event(at = 1201), 1300, true, false, next, newer, 10123))
        assertSame(next, coordinator.snapshot().reservation)
    }

    @Test fun noArmWithoutMatchingCompleteCurrentEvidenceAndAppliedOutput() {
        val reveal = applied()
        assertFalse(gate.arm(evidence.copy(windowId = -1), reveal, current, 9, 10123, 1100))
        assertFalse(gate.arm(evidence.copy(displayId = 1), reveal, current, 9, 10123, 1100))
        assertFalse(gate.arm(evidence.copy(requestId = 99), reveal, current, 9, 10123, 1100))
        assertFalse(gate.arm(evidence, reveal, current, 10, 10123, 1100))
        assertFalse(gate.arm(evidence, reveal, current, 9, 10124, 1100))
        assertFalse(gate.arm(evidence, reveal, current, 9, 10123, 999))
        assertTrue(coordinator.mayAct(token, host))
    }
}
