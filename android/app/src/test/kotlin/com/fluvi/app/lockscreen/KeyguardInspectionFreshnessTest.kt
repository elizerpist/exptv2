package com.fluvi.app.lockscreen

import org.junit.Assert.*
import org.junit.Test

class KeyguardInspectionFreshnessTest {
    private val authority = KeyguardInspectionAuthority(1, 2, 3, 4, 5)
    private fun request(id: Long, owner: KeyguardInspectionAuthority = authority) = KeyguardCardInspectionRequest(
        id, "window", owner.serviceSession, owner.visibilityEpoch, owner.interactionEpoch,
        owner.attachGeneration, owner.wakeGeneration, queuedAtUptimeMs = id,
    )

    @Test fun `event replacing retry keeps boundary until reader actually clears cache`() {
        val freshness = KeyguardInspectionFreshness().also { it.publish(authority) }
        val queue = KeyguardCardInspectionQueue()
        val cause = request(1)
        queue.offer(cause)
        // Production UNKNOWN handling records this before choosing a timer.
        freshness.require(authority, KeyguardWindowFreshness.MISSING_FRESHNESS_EVIDENCE)
        queue.complete(cause)
        // A real event cancels that timer. Its ordinary request has no explicit
        // cache-clear flag; acquisition must still fulfil the outstanding one.
        val event = request(2)
        assertTrue(queue.offer(event))
        val ticket = requireNotNull(freshness.beforeRead(event))
        assertEquals(KeyguardWindowFreshness.MISSING_FRESHNESS_EVIDENCE, ticket.reason)
        // A failed clear / missing root is NOT an acknowledgement.
        var clearCalls = 0
        val failed = KeyguardWindowSnapshotReaderPolicy.establishFreshness(
            ticket.reason, 35, true, { true },
            clearCache = { clearCalls++; false },
            onEstablished = { freshness.boundaryEstablished(ticket) },
        )
        assertEquals("clearReturnedFalse", failed)
        queue.complete(event)
        val next = request(3)
        queue.offer(next)
        assertEquals(ticket.reason, freshness.beforeRead(next)?.reason)
        val retry = requireNotNull(freshness.beforeRead(next))
        val cleared = KeyguardWindowSnapshotReaderPolicy.establishFreshness(
            retry.reason, 35, true, { true },
            clearCache = { clearCalls++; true },
            onEstablished = { freshness.boundaryEstablished(retry) },
        )
        assertEquals("cleared:MISSING_FRESHNESS_EVIDENCE", cleared)
        queue.complete(next)
        val ordinary = requireNotNull(freshness.beforeRead(request(4)))
        assertEquals(KeyguardWindowFreshness.FRAMEWORK_EVENT, ordinary.reason)
        KeyguardWindowSnapshotReaderPolicy.establishFreshness(
            ordinary.reason, 35, true, { true }, { clearCalls++; true }, {},
        )
        assertEquals(2, clearCalls) // failed + successful, not every event
    }

    @Test fun `suppressed retry upgrades already queued successor without another request`() {
        val freshness = KeyguardInspectionFreshness().also { it.publish(authority) }
        val queue = KeyguardCardInspectionQueue()
        val cause = request(1)
        val pending = request(2)
        queue.offer(cause)
        queue.offer(pending)
        val transition = KeyguardAwaitingSurfacePolicy.onUnknown(
            KeyguardSurfacePresentationState.AWAITING_MAIN_SURFACE, false, true, true,
        )
        assertEquals(KeyguardUnknownSurfaceFollowup.CONTINUE_PENDING, transition.followup)
        freshness.require(authority, KeyguardWindowFreshness.MISSING_FRESHNESS_EVIDENCE)
        // Later same-authority events coalesce normally, without erasing debt.
        repeat(20) { queue.offer(request(3L + it)) }
        val successor = requireNotNull(queue.complete(cause))
        assertEquals(22L, successor.id)
        assertNull(queue.pendingRequest())
        assertEquals(KeyguardWindowFreshness.MISSING_FRESHNESS_EVIDENCE, freshness.beforeRead(successor)?.reason)
    }

    @Test fun `withdrawal records fresh authority and allows legitimate same wake recovery`() {
        val freshness = KeyguardInspectionFreshness().also { it.publish(authority) }
        val queue = KeyguardCardInspectionQueue()
        val old = request(1)
        queue.offer(old)
        queue.offer(request(2))
        val withdrawn = authority.copy(visibilityEpoch = 3, interactionEpoch = 5)
        freshness.publish(withdrawn)
        freshness.require(withdrawn, KeyguardWindowFreshness.CONTRADICTORY_OBSERVATION)
        assertNull(freshness.beforeRead(old))
        // Reconciliation reacquires; it does not relabel the old result.
        val replacement = checkNotNull(checkNotNull(queue.pendingRequest()).reacquireAfterWithdrawal(
            withdrawn, 3, 3, KeyguardWindowFreshness.CONTRADICTORY_OBSERVATION,
        ))
        queue.offer(replacement)
        assertEquals(replacement, queue.complete(old))
        val ticket = requireNotNull(freshness.beforeRead(replacement))
        assertEquals(KeyguardWindowFreshness.CONTRADICTORY_OBSERVATION, ticket.reason)
        freshness.boundaryEstablished(ticket)
        assertTrue(withdrawn.matches(replacement))
        assertEquals(authority.wakeGeneration, withdrawn.wakeGeneration)
        assertEquals(KeyguardWindowFreshness.FRAMEWORK_EVENT, freshness.beforeRead(request(4, withdrawn))?.reason)
    }

    @Test fun `unlock rejects late read and does not transfer debt to another wake`() {
        val freshness = KeyguardInspectionFreshness().also { it.publish(authority) }
        freshness.require(authority, KeyguardWindowFreshness.CONTRADICTORY_OBSERVATION)
        val old = requireNotNull(freshness.beforeRead(request(1)))
        val nextWake = authority.copy(wakeGeneration = 4, visibilityEpoch = 3)
        freshness.publish(nextWake)
        freshness.require(nextWake, KeyguardWindowFreshness.LIFECYCLE_BOUNDARY)
        freshness.boundaryEstablished(old)
        assertNull(freshness.beforeRead(request(1)))
        assertEquals(KeyguardWindowFreshness.LIFECYCLE_BOUNDARY, freshness.beforeRead(request(2, nextWake))?.reason)
        val newSession = nextWake.copy(serviceSession = 2)
        freshness.publish(newSession)
        assertEquals(KeyguardWindowFreshness.FRAMEWORK_EVENT, freshness.beforeRead(request(3, newSession))?.reason)
    }

    @Test fun `late boundary acknowledgement cannot consume a newer requirement`() {
        val freshness = KeyguardInspectionFreshness().also { it.publish(authority) }
        freshness.require(authority, KeyguardWindowFreshness.LIFECYCLE_BOUNDARY)
        val old = requireNotNull(freshness.beforeRead(request(1)))
        freshness.require(authority, KeyguardWindowFreshness.MISSING_FRESHNESS_EVIDENCE)
        freshness.boundaryEstablished(old)
        assertEquals(KeyguardWindowFreshness.MISSING_FRESHNESS_EVIDENCE, freshness.beforeRead(request(2))?.reason)
    }

    @Test fun `retry exhaustion cannot erase an unfulfilled boundary`() {
        val freshness = KeyguardInspectionFreshness().also { it.publish(authority) }
        val transition = KeyguardAwaitingSurfacePolicy.onUnknown(
            KeyguardSurfacePresentationState.AWAITING_MAIN_SURFACE, false, false, false,
        )
        assertEquals(KeyguardUnknownSurfaceFollowup.WAIT_FOR_EVENT, transition.followup)
        freshness.require(authority, KeyguardWindowFreshness.MISSING_FRESHNESS_EVIDENCE)
        freshness.publish(authority) // unchanged publication must not reset it
        assertEquals(KeyguardWindowFreshness.MISSING_FRESHNESS_EVIDENCE, freshness.beforeRead(request(1))?.reason)
    }

    @Test fun `unlock during cache clear rejects completion without consuming new wake boundary`() {
        val freshness = KeyguardInspectionFreshness().also { it.publish(authority) }
        freshness.require(authority, KeyguardWindowFreshness.MISSING_FRESHNESS_EVIDENCE)
        val ticket = requireNotNull(freshness.beforeRead(request(1)))
        var current = true
        var acknowledgements = 0
        val next = authority.copy(wakeGeneration = 4)
        KeyguardWindowSnapshotReaderPolicy.establishFreshness(
            ticket.reason, 35, true, { current },
            clearCache = {
                current = false
                freshness.publish(next)
                freshness.require(next, KeyguardWindowFreshness.LIFECYCLE_BOUNDARY)
                true
            },
            onEstablished = { acknowledgements++; freshness.boundaryEstablished(ticket) },
        )
        assertEquals(0, acknowledgements)
        assertEquals(KeyguardWindowFreshness.LIFECYCLE_BOUNDARY, freshness.beforeRead(request(2, next))?.reason)
    }
}
