package com.fluvi.app.lockscreen

import org.junit.Assert.*
import org.junit.Test

/** Scalar ownership controls; compositor and Android service are separate gates. */
class KeyguardR31OpeningHandoffTest {
    private class Fixture(private val capture: Boolean = false) {
        val authority = KeyguardInspectionAuthority(1, 2, 3, 4, 5)
        val token = Any()
        val queue = KeyguardCardInspectionQueue()
        val gate = KeyguardOpeningInspectionHandoff()
        val context = KeyguardDiagnosticContext("r31", 1, 1, 3)
        val safe = KeyguardOpeningInspectionHandoff.Conditions(
            true, true, true, true, true, true, true, true, true, true,
            virginDirect = true, noRetainedProof = true)
        fun request(id: Long, origin: KeyguardR14Origin? = KeyguardR14Origin.SYSTEM_UI,
                    display: Int = 0, freshness: KeyguardWindowFreshness = KeyguardWindowFreshness.FRAMEWORK_EVENT) =
            KeyguardCardInspectionRequest(id, if (origin == null) "wake" else "window", 1, 2, 4, 5, 3, 100,
                windowFreshness = freshness, diagnosticContext = if (capture) context else null,
                r14Ingress = origin?.let { KeyguardR14Ingress(id, it == KeyguardR14Origin.SYSTEM_UI,
                    10, display, 32, 100, 100, it) })
        val a = request(1, null)
        val b = request(2)
        var scene = 11L
        init {
            assertTrue(queue.offer(a)); assertTrue(gate.arm(token, 5, a, authority, 7))
            gate.readStarted(a, 10, 100); gate.externalInvalidation(scene, 100)
            assertFalse(queue.offer(b)); gate.offered(b, queue.pendingRequest(), scene, scene, true)
            assertEquals(b, gate.claim(queue, a, token, 7, scene, safe, "beforeChild", 100,
                observationCaptureId = if (capture) context.captureId else null))
            gate.readFinished(a, 100)
        }
        fun start() = gate.followReadStarted(queue, b, scene, 100)
        fun offer(value: KeyguardCardInspectionRequest, newScene: Long = scene + 1,
                  invalidate: Boolean = true, real: Boolean = true) {
            scene = newScene
            val previous = queue.pendingRequest()
            if (invalidate) gate.externalInvalidation(scene, 100)
            assertFalse(queue.offer(value))
            gate.offered(value, queue.pendingRequest(), if (real) scene else null, scene, true, previous)
        }
        fun claim(conditions: KeyguardOpeningInspectionHandoff.Conditions = safe,
                  owner: Any = token, route: Long = 7, currentScene: Long = scene) =
            gate.followHandle(b)?.let { gate.claimFollow(queue, it, owner, route, currentScene,
                conditions, "beforeChild", 100, 1) }
    }

    @Test fun latestEligibleOccupantWinsOnceEvenAtSameUptime() {
        val f = Fixture(); f.start()
        val c = f.request(3); f.offer(c)
        val latest = f.request(4, KeyguardR14Origin.AMBIGUOUS); f.offer(latest)
        assertEquals(latest, f.claim())
        assertEquals(latest, f.queue.activeRequest()); assertNull(f.queue.pendingRequest())
        assertNull(f.gate.followHandle(latest)); assertNull(f.claim())
    }

    @Test fun preStartOfferCannotTransferButNewPostStartOfferCan() {
        val f = Fixture(); val before = f.request(3); f.offer(before); f.start()
        assertNull(f.claim()); assertEquals(before, f.queue.pendingRequest())
        val after = f.request(4); f.offer(after); assertEquals(after, f.claim())
    }

    @Test fun rejectedIngressAndCopiedDebtCannotTransfer() {
        for (c in listOf(
            Fixture().request(3, KeyguardR14Origin.OWN),
            Fixture().request(3, KeyguardR14Origin.OTHER),
            Fixture().request(3, KeyguardR14Origin.SYSTEM_UI, -1),
            Fixture().request(3, null),
            Fixture().request(3, KeyguardR14Origin.SYSTEM_UI, 0, KeyguardWindowFreshness.LIFECYCLE_BOUNDARY),
        )) {
            val f = Fixture(); f.start(); f.offer(c)
            assertNull(f.claim()); assertEquals(f.b, f.queue.activeRequest())
        }
        val f = Fixture(); f.start()
        val debt = f.request(3, freshness = KeyguardWindowFreshness.LIFECYCLE_BOUNDARY); f.offer(debt)
        val next = f.request(4); f.offer(next)
        assertTrue(checkNotNull(f.queue.pendingRequest()).windowFreshness.requiresCacheClear)
        assertNull(f.claim()); assertEquals(f.b, f.queue.activeRequest())
    }

    @Test fun futureIngressAndNoMatchingOfferCannotTransfer() {
        val future = Fixture(); future.start()
        val invalid = future.request(3).let { it.copy(r14Ingress = checkNotNull(it.r14Ingress).copy(eventAt = 101)) }
        future.offer(invalid); assertNull(future.claim()); assertEquals(future.b, future.queue.activeRequest())
        val unoffered = Fixture(); unoffered.start()
        unoffered.offer(unoffered.request(3), real = false)
        assertNull(unoffered.claim()); assertEquals(unoffered.b, unoffered.queue.activeRequest())
    }

    @Test fun changedOwnerSceneOrAnySafetyGuardRejects() {
        val cases = listOf<(KeyguardOpeningInspectionHandoff.Conditions) -> KeyguardOpeningInspectionHandoff.Conditions>(
            { it.copy(reservationCurrent = false) }, { it.copy(routeCurrent = false) },
            { it.copy(authorityCurrent = false) }, { it.copy(hostSafe = false) }, { it.copy(grantNone = false) },
            { it.copy(noPaint = false) }, { it.copy(noVisibleOrShowing = false) },
            { it.copy(freshnessEstablished = false) }, { it.copy(noObservedDisqualifier = false) },
            { it.copy(workRemaining = false) }, { it.copy(virginDirect = false) }, { it.copy(noRetainedProof = false) })
        for (change in cases) {
            val f = Fixture(); f.start(); val c = f.request(3); f.offer(c)
            assertNull(f.claim(change(f.safe))); assertEquals(f.b, f.queue.activeRequest()); assertEquals(c, f.queue.pendingRequest())
        }
        val f = Fixture(); f.start(); val c = f.request(3); f.offer(c)
        assertNull(f.claim(owner = Any())); assertNull(f.claim(route = 8)); assertNull(f.claim(currentScene = f.scene + 1))
        assertEquals(c, f.claim())
    }

    @Test fun finishAndSyntheticReplacementCloseOrClearOpportunity() {
        val f = Fixture(); f.start(); f.offer(f.request(3))
        f.offer(f.request(4, null), real = false)
        assertNull(f.claim())
        f.gate.followReadFinished(f.b, 101, null, "FINISHED")
        f.offer(f.request(5))
        assertNull(f.claim()); assertEquals(f.b, f.queue.activeRequest())
    }

    @Test fun cancellationUnwindsExactPromotedOwnerWithoutClearingNewSession() {
        val f = Fixture(); f.start(); val c = f.request(3); f.offer(c); assertEquals(c, f.claim())
        assertFalse(f.queue.abandonSessionIfActive(f.b))
        assertTrue(f.queue.abandonOpeningTransferIfActive(f.b)); assertNull(f.queue.activeRequest())
        val g = Fixture(); g.start(); val next = g.request(3); g.offer(next); assertEquals(next, g.claim())
        val newSession = g.request(4).copy(session = 9); assertFalse(g.queue.offer(newSession))
        assertFalse(g.queue.abandonOpeningTransferIfActive(g.b)); assertEquals(next, g.queue.activeRequest())
        assertEquals(newSession, g.queue.pendingRequest())
    }

    @Test fun captureEvidenceDoesNotReplaceOriginalAClaim() {
        val f = Fixture(capture = true); f.start(); val c = f.request(3); f.offer(c)
        assertEquals(c, f.claim())
        f.gate.successorFinished(f.b, 101, "YIELDED_TO_C")
        val snapshot = requireNotNull(f.gate.followReadFinished(f.b, 102, 101, "YIELDED_TO_C"))
        assertEquals(f.a.id, snapshot.openingId); assertEquals(f.b.id, snapshot.claimedId)
        assertEquals("YIELDED_TO_C", snapshot.closedReason)
        assertEquals(c.id, snapshot.followOn?.claimedId); assertEquals(11L, snapshot.followOn?.startScene)
        val cStart = requireNotNull(f.gate.followCObservation(c, 103, null))
        val cEnd = requireNotNull(f.gate.followCObservation(c, 104, "SHOW_FULL/MAIN_CONFIRMED"))
        assertTrue(cEnd.ordinal > cStart.ordinal); assertEquals(103L, cEnd.followOn?.cStart)
    }
}
