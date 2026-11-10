package com.fluvi.app.lockscreen

import org.junit.Assert.*
import org.junit.Test

class KeyguardSystemStateSamplerTest {
    private val eligible = KeyguardSystemState(100, 101, true, true, true, true, false, true, true)
    private class Fixture(var state: KeyguardSystemState) {
        var authority = KeyguardInspectionAuthority(1, 1, 1, 1, 1)
        val workers = ArrayDeque<() -> Unit>()
        val main = ArrayDeque<() -> Unit>()
        val received = mutableListOf<Pair<KeyguardSystemGateRequest, KeyguardSystemState>>()
        var reads = 0
        var fail = false
        val sampler = KeyguardSystemStateSampler(
            reader = { KeyguardSystemStateReader { purpose ->
                assertEquals(KeyguardSystemReadPurpose.RECURRING, purpose)
                reads++
                if (fail) error("controlled failure")
                state
            } },
            worker = { workers.addLast(it) }, main = { main.addLast(it) },
            current = { authority }, receive = { request, value -> received += request to value },
        )
        fun request(id: Long, evaluate: Boolean = true) = KeyguardSystemGateRequest(
            id, authority, "event:$id", id, id + 1, evaluate,
        )
        fun finish() { workers.removeFirst().invoke(); main.removeFirst().invoke() }
    }

    @Test fun `submission never executes the reader on the caller and burst does not starve active`() {
        val f = Fixture(eligible)
        f.sampler.offer(f.request(1))
        repeat(1000) { f.sampler.offer(f.request(it.toLong() + 2)) }
        assertEquals(0, f.reads)
        assertEquals(1, f.workers.size)
        f.finish()
        assertEquals(listOf(1L), f.received.map { it.first.id })
        assertEquals(1, f.workers.size)
        f.finish()
        assertEquals(listOf(1L, 1001L), f.received.map { it.first.id })
        assertEquals(2, f.reads)
        assertEquals(1, f.sampler.maximumActive)
        assertEquals(1, f.sampler.maximumPending)
        assertTrue(f.workers.isEmpty())
    }

    @Test fun `terminal invalidation while read outstanding clears successor and rejects positive`() {
        val f = Fixture(eligible)
        f.sampler.offer(f.request(1)); f.sampler.offer(f.request(2))
        f.authority = f.authority.copy(visibilityEpoch = 2, wakeGeneration = 2)
        f.sampler.clearPending()
        // No reader/result needs to run to revoke delivery. Actual local View
        // hiding is asserted by the real-service instrumentation, not faked here.
        assertEquals(0, f.reads)
        f.finish()
        assertTrue(f.received.isEmpty()); assertTrue(f.workers.isEmpty())
        assertEquals(1L, f.sampler.rejected)
    }

    @Test fun `old negative cannot withdraw replacement attachment for any changed identity`() {
        val old = KeyguardInspectionAuthority(1, 1, 1, 1, 1)
        val replacements = listOf(old.copy(serviceSession = 2), old.copy(visibilityEpoch = 2),
            old.copy(wakeGeneration = 2), old.copy(interactionEpoch = 2), old.copy(attachGeneration = 2))
        replacements.forEach { replacement ->
            val f = Fixture(eligible.copy(keyguardLocked = false))
            f.sampler.offer(f.request(1))
            f.authority = replacement
            f.finish()
            assertTrue("Negative result was stale for $replacement", f.received.isEmpty())
        }
    }

    @Test fun `attachment or privacy invalidation renews pending event with a fresh acquisition`() {
        val f = Fixture(eligible)
        f.sampler.offer(f.request(1))
        val pending = f.request(2).copy(freshness = KeyguardWindowFreshness.CONTRADICTORY_OBSERVATION)
        f.sampler.offer(pending)
        f.authority = f.authority.copy(attachGeneration = 2, visibilityEpoch = 2)
        f.sampler.renewPending { it.copy(id = 3, authority = f.authority, queuedAt = 200) }
        f.finish()
        assertTrue(f.received.isEmpty())
        f.finish()
        assertEquals(2, f.reads)
        val fresh = f.received.single().first
        assertEquals(3L, fresh.id)
        assertEquals(pending.reason, fresh.reason)
        assertEquals(pending.receivedAt, fresh.receivedAt)
        assertEquals(pending.freshness, fresh.freshness)
        assertEquals(f.authority, fresh.authority)
    }

    @Test fun `check only cannot suppress a pending real event or required freshness`() {
        val f = Fixture(eligible)
        f.sampler.offer(f.request(1))
        f.sampler.offer(f.request(2).copy(freshness = KeyguardWindowFreshness.MISSING_FRESHNESS_EVIDENCE))
        f.sampler.offer(f.request(3, evaluate = false))
        f.finish(); f.finish()
        assertEquals(3L, f.received.last().first.id)
        assertEquals("event:2", f.received.last().first.evaluationReason)
        assertEquals(2L, f.received.last().first.evaluationReceivedAt)
        assertEquals(KeyguardWindowFreshness.MISSING_FRESHNESS_EVIDENCE, f.received.last().first.freshness)
    }

    @Test fun `coalescing real events preserves screen on origin and unfulfilled freshness`() {
        val f = Fixture(eligible)
        f.sampler.offer(f.request(1))
        f.sampler.offer(f.request(2).copy(wakeSource = "wake", screenOnReceivedAt = 20,
            freshness = KeyguardWindowFreshness.LIFECYCLE_BOUNDARY))
        f.sampler.offer(f.request(3).copy(wakeSource = "display"))
        f.finish(); f.finish()
        val result = f.received.last().first
        assertEquals(3L, result.id)
        assertEquals(20L, result.screenOnReceivedAt)
        assertEquals(KeyguardWindowFreshness.LIFECYCLE_BOUNDARY, result.freshness)
    }

    @Test fun `dispose does not wait for worker and prevents delivery or further reads`() {
        val f = Fixture(eligible)
        f.sampler.offer(f.request(1)); f.sampler.offer(f.request(2))
        f.sampler.dispose(); f.sampler.offer(f.request(3))
        assertEquals(0, f.reads)
        f.finish()
        assertTrue(f.received.isEmpty()); assertTrue(f.workers.isEmpty())
    }

    @Test fun `idempotent terminal cleanup also revokes a later check without churning view epochs`() {
        val f = Fixture(eligible)
        f.sampler.offer(f.request(1))
        f.sampler.clearPending()
        // Same authority: repeated terminal cleanup need not mutate the root.
        f.sampler.renewPending { it.copy(id = 2) }
        f.finish()
        assertTrue(f.received.isEmpty())
        assertTrue(f.workers.isEmpty())
        assertEquals(1L, f.sampler.rejected)
    }

    @Test fun `reader failure and transition display never authorize admission or fake off`() {
        val f = Fixture(eligible)
        f.fail = true
        f.sampler.offer(f.request(1)); f.finish()
        assertFalse(f.received.single().second.eligible)
        assertFalse(f.received.single().second.excluded)
        val transitioning = eligible.copy(displayOn = false, displayOff = false)
        assertFalse(transitioning.eligible); assertFalse(transitioning.excluded)
        assertTrue(eligible.copy(displayOff = true, displayOn = false).excluded)
        val unknown = KeyguardCardSignals(true, true, true, true, true, false,
            true, KeyguardSurface.MAIN_KEYGUARD, true, displayOff = false)
        assertEquals(KeyguardCardVisibility.HIDDEN_UNKNOWN, KeyguardCardVisibilityPolicy.decide(unknown))
        assertEquals(KeyguardCardVisibility.HIDDEN_UNKNOWN,
            KeyguardCardVisibilityPolicy.decide(unknown.copy(systemStateAvailable = false)))
    }

    @Test fun `same permission avoids admission read but attach and disclosure increase require fresh state`() {
        val full = KeyguardCardVisibility.SHOW_FULL
        val discreet = KeyguardCardVisibility.SHOW_DISCREET
        assertFalse(KeyguardSystemAdmission.requiresFreshRead(true, full, full))
        assertFalse(KeyguardSystemAdmission.requiresFreshRead(true, discreet, discreet))
        assertFalse(KeyguardSystemAdmission.requiresFreshRead(true, full, discreet))
        assertTrue(KeyguardSystemAdmission.requiresFreshRead(false, full, full))
        assertTrue(KeyguardSystemAdmission.requiresFreshRead(true, discreet, full))
        assertFalse(KeyguardSystemAdmission.requiresFreshRead(true, full, KeyguardCardVisibility.HIDDEN_UNKNOWN))
        // A worker-positive is not the admission input. Current unlock wins.
        val admitted = KeyguardCardSignals(true, true, true, true, true, true,
            eligible.copy(keyguardLocked = false).keyguardLocked, KeyguardSurface.MAIN_KEYGUARD, true)
        assertEquals(KeyguardCardVisibility.HIDDEN_UNLOCKED, KeyguardCardVisibilityPolicy.decide(admitted))
    }
}
