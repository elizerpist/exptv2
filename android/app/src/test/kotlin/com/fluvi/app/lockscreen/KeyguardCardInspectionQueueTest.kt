package com.fluvi.app.lockscreen

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class KeyguardCardInspectionQueueTest {
    @Test fun `one active inspection retains only the newest coalesced request`() {
        val queue = KeyguardCardInspectionQueue()
        val first = request(1, "wake")
        val second = request(2, "display")
        val newest = request(3, "window")

        assertTrue(queue.offer(first))
        assertFalse(queue.offer(second))
        assertFalse(queue.offer(newest))
        assertEquals(newest, queue.complete(first))
        assertEquals(newest, queue.activeRequest())
        assertNull(queue.complete(newest))
    }

    @Test fun `terminal hide drops the queued follow-up but not the running Binder call`() {
        val queue = KeyguardCardInspectionQueue()
        val first = request(1, "wake")
        assertTrue(queue.offer(first))
        queue.offer(request(2, "window"))

        queue.clearPending()

        assertNull(queue.pendingRequest())
        assertNull(queue.complete(first))
    }

    @Test fun `fast hide accepts only immediate terminal state`() {
        assertFalse(KeyguardCardFastHideGate.shouldHide(displayInteractive = true, displayOff = false, keyguardLocked = true))
        assertTrue(KeyguardCardFastHideGate.shouldHide(displayInteractive = true, displayOff = false, keyguardLocked = false))
        assertTrue(KeyguardCardFastHideGate.shouldHide(displayInteractive = false, displayOff = false, keyguardLocked = true))
        assertTrue(KeyguardCardFastHideGate.shouldHide(displayInteractive = true, displayOff = true, keyguardLocked = true))
    }

    @Test fun `old wake result cannot publish into a newer wake cycle`() {
        assertEquals(
            KeyguardInspectionAction.DROP_STALE,
            KeyguardCardInspectionGate.decide(
                expectedSession = 7,
                currentSession = 7,
                expectedEpoch = 3,
                currentEpoch = 3,
                displayEligibleNow = true,
                keyguardLockedNow = true,
                expectedWakeGeneration = 11,
                currentWakeGeneration = 12,
            ),
        )
    }

    @Test fun `terminal hidden state is idempotent but a new wake or failed detach is not suppressed`() {
        val completed = KeyguardTerminalHideState(serviceSession = 4, invalidatedVisibilityEpoch = 9)

        assertFalse(
            KeyguardTerminalHideGate.shouldProcess(
                terminalWake = true,
                overlayAttached = false,
                serviceSession = 4,
                visibilityEpoch = 9,
                previous = completed,
            ),
        )
        assertTrue(
            KeyguardTerminalHideGate.shouldProcess(
                terminalWake = true,
                overlayAttached = true,
                serviceSession = 4,
                visibilityEpoch = 9,
                previous = completed,
            ),
        )
        assertTrue(
            KeyguardTerminalHideGate.shouldProcess(
                terminalWake = true,
                overlayAttached = false,
                serviceSession = 4,
                visibilityEpoch = 10,
                previous = completed,
            ),
        )
        assertTrue(
            KeyguardTerminalHideGate.shouldProcess(
                terminalWake = false,
                overlayAttached = false,
                serviceSession = 4,
                visibilityEpoch = 9,
                previous = completed,
            ),
        )
    }

    private fun request(id: Long, trigger: String) = KeyguardCardInspectionRequest(
        id = id,
        trigger = trigger,
        session = 1,
        visibilityEpoch = 1,
        interactionEpoch = 1,
        attachGeneration = 1,
        wakeGeneration = 1,
        queuedAtUptimeMs = id,
    )
}
