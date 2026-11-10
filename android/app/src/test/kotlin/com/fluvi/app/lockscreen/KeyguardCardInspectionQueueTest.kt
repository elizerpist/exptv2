package com.fluvi.app.lockscreen

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class KeyguardCardInspectionQueueTest {
    @Test fun `latest event cannot erase an unperformed wake freshness boundary`() {
        val queue = KeyguardCardInspectionQueue()
        val old = request(1, "oldWake").copy(wakeGeneration = 1L)
        val wake = request(2, "wake").copy(wakeGeneration = 2L, windowFreshness = KeyguardWindowFreshness.LIFECYCLE_BOUNDARY)
        val window = wake.copy(id = 3L, trigger = "window", queuedAtUptimeMs = 30L, windowFreshness = KeyguardWindowFreshness.FRAMEWORK_EVENT)
        queue.offer(old)
        queue.offer(wake)
        queue.offer(window)
        val next = requireNotNull(queue.complete(old))
        assertEquals(window.id, next.id)
        assertEquals(window.queuedAtUptimeMs, next.queuedAtUptimeMs)
        assertEquals(window.wakeGeneration, next.wakeGeneration)
        assertEquals(KeyguardWindowFreshness.LIFECYCLE_BOUNDARY, next.windowFreshness)
    }

    @Test fun `freshness obligation from another authority is not relabelled`() {
        val queue = KeyguardCardInspectionQueue()
        val active = request(1, "active")
        queue.offer(active)
        queue.offer(request(2, "wake").copy(windowFreshness = KeyguardWindowFreshness.LIFECYCLE_BOUNDARY))
        val current = request(3, "window").copy(visibilityEpoch = active.visibilityEpoch + 1L)
        queue.offer(current)
        assertEquals(current, queue.complete(active))
    }

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

    @Test fun `published authority invalidates an old traversal without relabelling it current`() {
        val request = request(44, "window")
        val current = KeyguardInspectionAuthority(
            serviceSession = 1L,
            visibilityEpoch = 1L,
            wakeGeneration = 1L,
            interactionEpoch = 1L,
            attachGeneration = 1L,
        )
        assertTrue(current.matches(request))
        assertFalse(current.copy(interactionEpoch = 2L).matches(request))
        assertFalse(current.copy(attachGeneration = 2L).matches(request))
        assertFalse(current.copy(wakeGeneration = 2L).matches(request))
    }

    @Test fun `same-authority burst keeps active work and only newest pending request`() {
        val queue = KeyguardCardInspectionQueue()
        val active = request(1, "wake")
        assertTrue(queue.offer(active))
        repeat(50) { index ->
            assertFalse(queue.offer(request(index + 2L, "window")))
            assertEquals(active, queue.activeRequest())
        }
        assertEquals(51L, queue.pendingRequest()?.id)
        assertEquals(51L, queue.complete(active)?.id)
    }

    @Test fun `screen on joins an early eligible wake without replacing its authority`() {
        val owner = KeyguardWakeCycleOwner()
        val early = owner.beginOrJoin(nextId = 7L, source = "display", observedAtUptimeMs = 100L)
        val screenOn = owner.beginOrJoin(nextId = 8L, source = "wake", observedAtUptimeMs = 112L)

        assertTrue(early.started)
        assertFalse(screenOn.started)
        assertTrue(screenOn.screenOnJoined)
        assertEquals(7L, screenOn.cycle.id)
        assertEquals(112L, screenOn.cycle.screenOnReceivedAtUptimeMs)

        owner.end()
        assertTrue(owner.beginOrJoin(nextId = 9L, source = "wake", observedAtUptimeMs = 300L).started)
    }

    @Test fun `unknown while detached preserves compatible pending inspection without authority churn`() {
        val queue = KeyguardCardInspectionQueue()
        val active = request(1, "wake")
        val successor = request(2, "window")
        val authority = KeyguardInspectionAuthority(1, 1, 1, 1, 1)
        assertTrue(queue.offer(active))
        assertFalse(queue.offer(successor))

        val transition = KeyguardAwaitingSurfacePolicy.onUnknown(
            current = KeyguardSurfacePresentationState.AWAITING_MAIN_SURFACE,
            overlayAttached = false,
            hasCompatiblePendingRequest = authority.matches(checkNotNull(queue.pendingRequest())),
            retryAvailable = true,
        )

        assertFalse(transition.withdrawVisibleOverlay)
        assertFalse(transition.invalidatesVisibleAuthority)
        assertEquals(KeyguardUnknownSurfaceFollowup.CONTINUE_PENDING, transition.followup)
        assertEquals(successor, queue.complete(active))
        assertTrue(authority.matches(checkNotNull(queue.activeRequest())))
    }

    @Test fun `detached unknown schedules fallback only when no successor exists`() {
        val queue = KeyguardCardInspectionQueue()
        val active = request(1, "wake")
        assertTrue(queue.offer(active))

        val transition = KeyguardAwaitingSurfacePolicy.onUnknown(
            current = KeyguardSurfacePresentationState.AWAITING_MAIN_SURFACE,
            overlayAttached = false,
            hasCompatiblePendingRequest = queue.pendingRequest() != null,
            retryAvailable = true,
        )

        assertEquals(KeyguardUnknownSurfaceFollowup.SCHEDULE_FALLBACK, transition.followup)
        assertNull(queue.complete(active))
        // The completed active cause was not counted as future work, so a
        // bounded fallback is still permitted to make progress.
    }

    @Test fun `fresh event beats scheduled fallback without adding another pending request`() {
        val queue = KeyguardCardInspectionQueue()
        val active = request(1, "wake")
        val event = request(2, "window")
        assertTrue(queue.offer(active))
        assertFalse(queue.offer(event))

        val timerTransition = KeyguardAwaitingSurfacePolicy.onUnknown(
            current = KeyguardSurfacePresentationState.AWAITING_MAIN_SURFACE,
            overlayAttached = false,
            hasCompatiblePendingRequest = queue.pendingRequest() != null,
            retryAvailable = true,
        )

        assertEquals(KeyguardUnknownSurfaceFollowup.CONTINUE_PENDING, timerTransition.followup)
        assertEquals(event, queue.complete(active))
        assertNull(queue.pendingRequest())
    }

    @Test fun `retry exhaustion leaves physical wake open awaiting a later event`() {
        val owner = KeyguardWakeCycleOwner()
        val cycle = owner.beginOrJoin(10L, "display", 100L).cycle

        val transition = KeyguardAwaitingSurfacePolicy.onUnknown(
            current = KeyguardSurfacePresentationState.AWAITING_MAIN_SURFACE,
            overlayAttached = false,
            hasCompatiblePendingRequest = false,
            retryAvailable = false,
        )

        assertEquals(KeyguardUnknownSurfaceFollowup.WAIT_FOR_EVENT, transition.followup)
        assertEquals(KeyguardSurfacePresentationState.AWAITING_MAIN_SURFACE, transition.nextState)
        assertEquals(cycle, owner.current())
        assertFalse(owner.beginOrJoin(11L, "window", 120L).started)
    }

    @Test fun `visible unknown withdraws once then subsequent detached unknown is awaiting only`() {
        val first = KeyguardAwaitingSurfacePolicy.onUnknown(
            current = KeyguardSurfacePresentationState.VISIBLE,
            overlayAttached = true,
            hasCompatiblePendingRequest = false,
            retryAvailable = true,
        )
        val second = KeyguardAwaitingSurfacePolicy.onUnknown(
            current = first.nextState,
            overlayAttached = false,
            hasCompatiblePendingRequest = false,
            retryAvailable = true,
        )

        assertTrue(first.withdrawVisibleOverlay)
        assertTrue(first.invalidatesVisibleAuthority)
        assertEquals(KeyguardSurfacePresentationState.WITHDRAWN_AWAITING_SURFACE, first.nextState)
        assertFalse(second.withdrawVisibleOverlay)
        assertFalse(second.invalidatesVisibleAuthority)
        assertEquals(KeyguardSurfacePresentationState.WITHDRAWN_AWAITING_SURFACE, second.nextState)
    }

    @Test fun `applied unknown cause is not future work that can suppress fallback`() {
        val queue = KeyguardCardInspectionQueue()
        val authority = KeyguardInspectionAuthority(1, 1, 1, 1, 1)
        val cause = request(1, "unknown")
        queue.offer(cause)
        assertFalse(queue.hasCurrentWork(authority, excludingId = cause.id))
        queue.offer(request(2, "window"))
        assertTrue(queue.hasCurrentWork(authority, excludingId = cause.id))
        queue.complete(cause)
        assertTrue(queue.hasCurrentWork(authority, excludingId = cause.id))
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
