package com.fluvi.app.lockscreen

import org.junit.Assert.*
import org.junit.Test

class KeyguardOpeningInspectionHandoffTest {
    private val authority = KeyguardInspectionAuthority(1, 2, 3, 4, 5)
    private fun request(id: Long, external: Boolean = false) = KeyguardCardInspectionRequest(
        id, if (external) "window" else "wake", 1, 2, 4, 5, 3, id,
        r14Ingress = if (external) KeyguardR14Ingress(id, true, 10, 0, 32, id, id,
            KeyguardR14Origin.SYSTEM_UI) else null,
    )
    private val safe = KeyguardOpeningInspectionHandoff.Conditions(
        reservationCurrent = true, routeCurrent = true, authorityCurrent = true,
        hostSafe = true, grantNone = true, noPaint = true, noVisibleOrShowing = true,
        freshnessEstablished = true, noObservedDisqualifier = true, workRemaining = true,
    )
    private class Fixture {
        val authority = KeyguardInspectionAuthority(1, 2, 3, 4, 5)
        val a = KeyguardCardInspectionRequest(1, "wake", 1, 2, 4, 5, 3, 1)
        val queue = KeyguardCardInspectionQueue()
        val gate = KeyguardOpeningInspectionHandoff()
        val token = Any()
        init { queue.offer(a); assertTrue(gate.arm(token, 5, a, authority, 7)); gate.readStarted(a, 10, 100) }
        fun external(id: Long, scene: Long, frameworkEvent: Boolean = false): KeyguardCardInspectionRequest {
            val r = KeyguardCardInspectionRequest(id, "window", 1, 2, 4, 5, 3, id,
                r14Ingress = KeyguardR14Ingress(id, true, 10, 0, 32, id, id, KeyguardR14Origin.SYSTEM_UI))
            gate.externalInvalidation(scene, 110 + id)
            queue.offer(r)
            gate.offered(r, queue.pendingRequest(), scene, scene, frameworkEvent)
            return r
        }
        fun claim(conditions: KeyguardOpeningInspectionHandoff.Conditions) =
            gate.claim(queue, a, token, 7, 11, conditions, "child", 120)
    }

    @Test fun `one actual external B is atomically promoted while A finishes`() {
        val f = Fixture(); val b = f.external(2, 11)
        assertEquals(b, f.claim(safe))
        assertEquals(b, f.queue.activeRequest())
        assertNull(f.queue.pendingRequest())
        assertFalse(f.gate.hasHint)
        val c = f.external(3, 12)
        assertNull(f.claim(safe))
        assertEquals(c, f.queue.pendingRequest())
        f.gate.readFinished(f.a, 121)
        assertEquals(2L, f.gate.snapshot(1)?.claimedId)
        assertEquals(c, f.queue.complete(b))
    }

    @Test fun `no event or unoffered or synthetic successor never yields`() {
        val f = Fixture()
        assertNull(f.claim(safe))
        f.gate.externalInvalidation(11, 105)
        assertNull(f.claim(safe))
        val timer = request(2)
        f.queue.offer(timer)
        f.gate.offered(timer, f.queue.pendingRequest(), null, 11)
        assertFalse(f.gate.hasHint)
        assertNull(f.claim(safe))
    }

    @Test fun `only an independently qualifying replacement can supersede B`() {
        val f = Fixture(); val b = f.external(2, 11)
        val timer = request(3)
        f.queue.offer(timer); f.gate.offered(timer, f.queue.pendingRequest(), null, 11)
        assertFalse(f.gate.hasHint)
        assertNull(f.claim(safe))
        assertEquals(timer, f.queue.pendingRequest())
        val c = f.external(4, 12)
        assertNull(f.gate.claim(f.queue, f.a, f.token, 7, 11, safe, "child", 121))
        assertEquals(c, f.gate.claim(f.queue, f.a, f.token, 7, 12, safe, "child", 122))
        assertNotEquals(b, c)
    }

    @Test fun `every authority and safety boundary is fail closed`() {
        val cases = listOf(
            safe.copy(reservationCurrent = false), safe.copy(routeCurrent = false),
            safe.copy(authorityCurrent = false), safe.copy(hostSafe = false), safe.copy(grantNone = false),
            safe.copy(noPaint = false), safe.copy(noVisibleOrShowing = false),
            safe.copy(freshnessEstablished = false), safe.copy(noObservedDisqualifier = false),
            safe.copy(workRemaining = false),
        )
        for (conditions in cases) {
            val f = Fixture(); val b = f.external(2, 11)
            assertNull(f.claim(conditions))
            assertEquals(f.a, f.queue.activeRequest())
            assertEquals(b, f.queue.pendingRequest())
        }
    }

    @Test fun `incomplete transfer requires virgin owner and no retained proof`() {
        val eligible = safe.copy(virginDirect = true, noRetainedProof = true)
        val cases = listOf(eligible.copy(virginDirect = false), eligible.copy(noRetainedProof = false),
            eligible.copy(noPaint = false), eligible.copy(grantNone = false),
            eligible.copy(noVisibleOrShowing = false), eligible.copy(freshnessEstablished = false),
            eligible.copy(noObservedDisqualifier = false), eligible.copy(workRemaining = false))
        for (condition in cases) {
            val f = Fixture(); val b = f.external(2, 11, frameworkEvent = true)
            assertNull(f.gate.claim(f.queue, f.a, f.token, 7, 11, condition, "child", 120,
                yieldReason = KeyguardOpeningYieldReason.INCOMPLETE_NULL_CHILD))
            assertEquals(f.a, f.queue.activeRequest()); assertEquals(b, f.queue.pendingRequest())
        }
    }

    @Test fun `incomplete transfer requires genuine latest framework ingress and consumes shared allowance`() {
        val eligible = safe.copy(virginDirect = true, noRetainedProof = true)
        val synthetic = Fixture(); val pending = synthetic.external(2, 11, frameworkEvent = false)
        assertNull(synthetic.gate.claim(synthetic.queue, synthetic.a, synthetic.token, 7, 11, eligible,
            "child", 120, yieldReason = KeyguardOpeningYieldReason.INCOMPLETE_NULL_CHILD))
        assertEquals(pending, synthetic.queue.pendingRequest())
        val rejected = checkNotNull(synthetic.gate.snapshot(synthetic.a.id))
        assertEquals(1, rejected.incompleteChecks); assertEquals(0, rejected.incompleteEligible)
        assertEquals(1, rejected.incompleteRejected); assertEquals("incompleteNotFramework", rejected.firstIncompleteRejection)
        val f = Fixture(); val b = f.external(2, 11, frameworkEvent = true)
        assertEquals(b, f.gate.claim(f.queue, f.a, f.token, 7, 11, eligible, "child", 120,
            yieldReason = KeyguardOpeningYieldReason.INCOMPLETE_NULL_CHILD))
        val accepted = checkNotNull(f.gate.snapshot(f.a.id))
        assertEquals(1, accepted.incompleteChecks); assertEquals(1, accepted.incompleteEligible)
        assertEquals(1, accepted.incompleteYielded)
        val c = f.external(3, 12, frameworkEvent = true)
        assertNull(f.gate.claim(f.queue, b, f.token, 7, 12, eligible, "child", 121,
            yieldReason = KeyguardOpeningYieldReason.INCOMPLETE_NULL_CHILD))
        assertEquals(c, f.queue.pendingRequest())
    }

    @Test fun `stale reservation route scene and completed A cannot transfer`() {
        val f = Fixture(); f.external(2, 11)
        assertNull(f.gate.claim(f.queue, f.a, Any(), 7, 11, safe, "child", 120))
        assertNull(f.gate.claim(f.queue, f.a, f.token, 8, 11, safe, "child", 120))
        assertNull(f.gate.claim(f.queue, f.a, f.token, 7, 12, safe, "child", 120))
        f.gate.readFinished(f.a, 121)
        assertNull(f.claim(safe))
        assertFalse(f.gate.arm(f.token, 9, f.a, f.authority, 7))
    }

    @Test fun `natural completed A retains exact offered B evidence without claiming it`() {
        val f = Fixture(); val b = f.external(2, 11)
        f.gate.readFinished(f.a, 130)
        val evidence = f.gate.snapshotForSuccessor(b)
        assertEquals(b.id, evidence?.latestOfferedId)
        assertNull(evidence?.claimedId)
        assertEquals(130L, evidence?.completedAt)
        assertEquals(f.a, f.queue.activeRequest())
        assertEquals(b, f.queue.pendingRequest())
    }

    @Test fun `invalidation before the physical A start cannot arm a handoff`() {
        val queue = KeyguardCardInspectionQueue()
        val a = request(1)
        val b = request(2, external = true)
        val gate = KeyguardOpeningInspectionHandoff()
        val token = Any()
        queue.offer(a)
        assertTrue(gate.arm(token, 5, a, authority, 7))
        gate.externalInvalidation(11, 99)
        gate.readStarted(a, 11, 100)
        queue.offer(b)
        gate.offered(b, queue.pendingRequest(), 11, 11)
        assertFalse(gate.hasHint)
        assertNull(gate.claim(queue, a, token, 7, 11, safe, "child", 120))
    }

    @Test fun `foreign authority and prior R12 predecessor cannot be promoted`() {
        val f = Fixture(); val b = f.external(2, 11)
        val wrong = b.copy(wakeGeneration = 9)
        f.queue.offer(wrong); f.gate.offered(wrong, f.queue.pendingRequest(), null, 11)
        assertNull(f.claim(safe))
        val g = Fixture(); val b2 = g.external(2, 11)
        assertEquals(b2, g.queue.reserveSuccessor(g.a) { true })
        val c = g.external(3, 12)
        assertNull(g.gate.claim(g.queue, b2, g.token, 7, 12, safe, "child", 122))
        assertEquals(c, g.queue.pendingRequest())
    }
}
