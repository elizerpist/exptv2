package com.fluvi.app.lockscreen

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class KeyguardCardInspectionQueueTest {
    @Test fun `withdrawal reacquires latest event without rewriting its origins`() {
        val owner = KeyguardInspectionAuthority(1, 1, 1, 1, 1)
        val withdrawn = owner.copy(visibilityEpoch = 2, interactionEpoch = 2)
        val context = KeyguardDiagnosticContext("capture", 6, 1, 1)
        val cause = request(35, "olderOcclusion")
        val event = request(36, "window").copy(
            queuedAtUptimeMs = 171291, eventTimeUptimeMs = 171287,
            triggerReceivedUptimeMs = 171291, diagnosticContext = context,
            windowFreshness = KeyguardWindowFreshness.MISSING_FRESHNESS_EVIDENCE,
            latestSamplerEvidence = KeyguardSamplerEvidence(10, owner, 171280, 171282, 171283,
                eligible = true, excluded = false, captureId = "capture"),
        )
        val queue = KeyguardCardInspectionQueue()
        queue.offer(cause)
        queue.offer(event)
        val next = checkNotNull(event.reacquireAfterWithdrawal(
            withdrawn, 37, 171292, KeyguardWindowFreshness.CONTRADICTORY_OBSERVATION,
        ))
        assertFalse(withdrawn.matches(cause))
        assertFalse(withdrawn.matches(event))
        assertTrue(withdrawn.matches(next))
        assertEquals(event.trigger, next.trigger)
        assertEquals(event.eventTimeUptimeMs, next.eventTimeUptimeMs)
        assertEquals(event.triggerReceivedUptimeMs, next.triggerReceivedUptimeMs)
        assertEquals(event.diagnosticContext, next.diagnosticContext)
        assertNull(next.latestSamplerEvidence) // old observation must not acquire a new authority
        assertEquals(171292L, next.queuedAtUptimeMs)
        assertEquals(KeyguardWindowFreshness.CONTRADICTORY_OBSERVATION, next.windowFreshness)
        assertFalse(queue.offer(next)) // one worker, never a parallel walk
        assertEquals(next, queue.complete(cause))
        assertNull(queue.pendingRequest())
        assertNull(queue.complete(cause)) // late completion cannot release the successor
    }

    @Test fun `independent sampler observation is bound to its authority and capture`() {
        val owner = KeyguardInspectionAuthority(1, 2, 3, 4, 5)
        val evidence = KeyguardSamplerEvidence(10, owner, 100, 101, 102,
            eligible = true, excluded = false, captureId = "capture-one")
        assertTrue(evidence.belongsTo(owner, "capture-one"))
        assertFalse(evidence.belongsTo(owner, "capture-two"))
        assertFalse(evidence.belongsTo(owner, null))
        assertFalse(evidence.belongsTo(owner.copy(visibilityEpoch = 6), "capture-one"))
    }

    @Test fun `reconciliation cannot carry an event across terminal session or wake boundaries`() {
        val event = request(36, "window")
        val authority = KeyguardInspectionAuthority(1, 2, 1, 2, 1)
        for (terminal in listOf(authority.copy(serviceSession = 2), authority.copy(wakeGeneration = 2))) {
            assertNull(event.reacquireAfterWithdrawal(terminal, 37, 100, KeyguardWindowFreshness.CONTRADICTORY_OBSERVATION))
        }
        val queue = KeyguardCardInspectionQueue()
        queue.offer(request(35, "occlusion"))
        queue.offer(checkNotNull(event.reacquireAfterWithdrawal(authority, 37, 100, KeyguardWindowFreshness.CONTRADICTORY_OBSERVATION)))
        queue.clearPending() // the existing terminal owner cancels intent, not an IPC
        assertNull(queue.complete(checkNotNull(queue.activeRequest())))
    }

    @Test fun `recovery event bursts retain one latest request and unperformed freshness`() {
        val authority = KeyguardInspectionAuthority(1, 2, 1, 2, 1)
        val cause = request(35, "occlusion")
        val next = checkNotNull(request(36, "window").copy(
            windowFreshness = KeyguardWindowFreshness.MISSING_FRESHNESS_EVIDENCE,
        ).reacquireAfterWithdrawal(authority, 37, 100, KeyguardWindowFreshness.FRAMEWORK_EVENT))
        val queue = KeyguardCardInspectionQueue()
        queue.offer(cause)
        queue.offer(next)
        repeat(100) { index ->
            assertFalse(queue.offer(next.copy(id = 38L + index, windowFreshness = KeyguardWindowFreshness.FRAMEWORK_EVENT)))
            assertEquals(cause, queue.activeRequest())
        }
        val latest = checkNotNull(queue.complete(cause))
        assertEquals(137L, latest.id)
        assertTrue(authority.matches(latest))
        assertEquals(KeyguardWindowFreshness.MISSING_FRESHNESS_EVIDENCE, latest.windowFreshness)
        assertNull(queue.pendingRequest())
    }

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

    @Test fun `parked obsolete reader keeps its pending freshness until a real later offer`() {
        val queue = KeyguardCardInspectionQueue()
        val active = request(1, "wake")
        val older = request(2, "window").copy(windowFreshness = KeyguardWindowFreshness.LIFECYCLE_BOUNDARY)
        val latest = request(3, "window")
        assertTrue(queue.offer(active))
        assertFalse(queue.offer(older))
        assertTrue(queue.parkObsoleteAfterRead(active))
        assertNull(queue.activeRequest())
        assertEquals(older, queue.pendingRequest())
        assertFalse(queue.parkObsoleteAfterRead(active))
        assertTrue(queue.offer(latest))
        assertEquals(latest.id, queue.activeRequest()?.id)
        assertEquals(KeyguardWindowFreshness.LIFECYCLE_BOUNDARY, queue.activeRequest()?.windowFreshness)
        assertNull(queue.pendingRequest())
        assertNull(queue.complete(active))
        assertEquals(latest.id, queue.activeRequest()?.id)
    }

    @Test fun `cancelled unwinding preserves claimed reader and newer pending event`() {
        val queue = KeyguardCardInspectionQueue()
        val a = request(1, "wake"); val b = request(2, "window"); val c = request(3, "window")
        assertTrue(queue.offer(a)); assertFalse(queue.offer(b))
        assertEquals(b, queue.handoffOpening(a, b))
        assertFalse(queue.offer(c))
        assertEquals(b, queue.recoverUnwoundReader(a)?.next)
        assertEquals(b, queue.activeRequest())
        assertEquals(c, queue.pendingRequest())
        assertNull(queue.recoverUnwoundReader(a))
        assertEquals(c, queue.recoverUnwoundReader(b)?.next)
        assertEquals(c, queue.activeRequest())
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

    @Test fun `repeated occlusion with exhausted fallback remains excluded and event recoverable`() {
        val owner = KeyguardWakeCycleOwner()
        val cycle = owner.beginOrJoin(1, "display", 100).cycle
        val queue = KeyguardCardInspectionQueue()
        val main = KeyguardWindowSnapshot("com.android.systemui", 1, 1, 0,
            visibleViewIds = setOf("com.android.systemui:id/keyguard_clock_switch"))
        val foreign = KeyguardWindowSnapshot("other.app", 1, 2, 0)
        repeat(8) { index ->
            val observation = request(index + 1L, "window")
            assertTrue(queue.offer(observation))
            assertEquals(KeyguardSurface.OCCLUDED, KeyguardSurfaceClassifier.classify(listOf(main, foreign)))
            val transition = KeyguardAwaitingSurfacePolicy.onUnknown(
                KeyguardSurfacePresentationState.WITHDRAWN_AWAITING_SURFACE,
                overlayAttached = false, hasCompatiblePendingRequest = false, retryAvailable = false,
            )
            assertFalse(transition.withdrawVisibleOverlay)
            assertEquals(KeyguardUnknownSurfaceFollowup.WAIT_FOR_EVENT, transition.followup)
            assertNull(queue.complete(observation))
            assertEquals(cycle, owner.current())
        }
        val laterEvent = request(9, "window")
        assertTrue(queue.offer(laterEvent))
        assertFalse(owner.beginOrJoin(2, "window", 200).started)
        assertEquals(KeyguardSurface.MAIN_KEYGUARD, KeyguardSurfaceClassifier.classify(listOf(main)))
        assertEquals(laterEvent, queue.activeRequest())
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

    @Test fun `opening handoff claims only its exact active and pending pair`() {
        val queue = KeyguardCardInspectionQueue()
        val a = request(1, "wake")
        val b = request(2, "window")
        assertTrue(queue.offer(a))
        assertFalse(queue.offer(b))
        assertNull(queue.handoffOpening(request(9, "wrong"), b))
        assertNull(queue.handoffOpening(a, request(3, "wrong")))
        assertEquals(a, queue.activeRequest())
        assertEquals(b, queue.pendingRequest())
        assertEquals(b, queue.handoffOpening(a, b))
        assertEquals(b, queue.activeRequest())
        assertNull(queue.pendingRequest())
        assertNull(queue.handoffOpening(a, b))
        assertNull(queue.complete(a))
    }

    @Test fun `replacement before claim is not relabelled but after claim remains pending`() {
        val queue = KeyguardCardInspectionQueue()
        val a = request(1, "wake")
        val b = request(2, "window")
        val c = request(3, "window")
        queue.offer(a); queue.offer(b); queue.offer(c)
        assertNull(queue.handoffOpening(a, b))
        assertEquals(c, queue.handoffOpening(a, c))
        val later = request(4, "window")
        assertFalse(queue.offer(later))
        assertEquals(c, queue.activeRequest())
        assertEquals(later, queue.pendingRequest())
        assertEquals(later, queue.complete(c))
    }

    @Test fun `completed read ahead predecessor cannot be reclassified as opening handoff`() {
        val queue = KeyguardCardInspectionQueue()
        val a = request(1, "wake")
        val b = request(2, "window")
        val c = request(3, "window")
        queue.offer(a); queue.offer(b)
        assertEquals(b, queue.reserveSuccessor(a) { true })
        queue.offer(c)
        assertNull(queue.handoffOpening(b, c))
        assertEquals(b, queue.successorForPreceding(a))
        assertTrue(queue.finishPreceding(a))
        assertEquals(c, queue.complete(b))
    }

    @Test fun `late teardown cannot remove a newer active request`() {
        val queue = KeyguardCardInspectionQueue()
        val a = request(1, "wake")
        val b = request(2, "window")
        queue.offer(a); queue.offer(b)
        assertEquals(b, queue.handoffOpening(a, b))
        assertFalse(queue.abandonSessionIfActive(a))
        assertEquals(b, queue.activeRequest())
        assertTrue(queue.abandonSessionIfActive(b))
        assertNull(queue.activeRequest())
    }

    @Test fun `teardown during old reader unwind finds only exact promoted owner`() {
        val queue = KeyguardCardInspectionQueue()
        val a = request(1, "wake")
        val b = request(2, "window")
        val c = request(3, "window")
        queue.offer(a); queue.offer(b)
        assertEquals(b, queue.handoffOpening(a, b))
        queue.offer(c)
        assertFalse(queue.abandonOpeningTransferIfActive(c))
        assertEquals(b, queue.activeRequest())
        assertTrue(queue.abandonOpeningTransferIfActive(a))
        assertNull(queue.activeRequest())
        assertNull(queue.pendingRequest())
    }

    @Test fun `late unwind cleanup cannot discard a successor after promoted owner completed`() {
        val queue = KeyguardCardInspectionQueue()
        val a = request(1, "wake")
        val b = request(2, "window")
        val c = request(3, "window")
        queue.offer(a); queue.offer(b)
        assertEquals(b, queue.handoffOpening(a, b))
        queue.offer(c)
        assertEquals(c, queue.complete(b))
        assertFalse(queue.abandonOpeningTransferIfActive(a))
        assertEquals(c, queue.activeRequest())
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
