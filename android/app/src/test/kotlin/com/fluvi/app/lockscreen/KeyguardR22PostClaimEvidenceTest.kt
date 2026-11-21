package com.fluvi.app.lockscreen

import org.junit.Assert.*
import org.junit.Test

/** Queue ownership, not a simulated successor, supplies each observed fact. */
class KeyguardR22PostClaimEvidenceTest {
    private class Fixture(capture: Boolean = true) {
        val authority = KeyguardInspectionAuthority(1, 2, 3, 4, 5)
        val context = KeyguardDiagnosticContext("capture-a", 1, 1, 3)
        val token = Any()
        val queue = KeyguardCardInspectionQueue()
        val gate = KeyguardOpeningInspectionHandoff()
        val safe = KeyguardOpeningInspectionHandoff.Conditions(
            true, true, true, true, true, true, true, true, true, true)
        fun request(id: Long, external: Boolean, freshness: KeyguardWindowFreshness =
            KeyguardWindowFreshness.FRAMEWORK_EVENT) = KeyguardCardInspectionRequest(
            id, if (external) "window" else "wake", 1, 2, 4, 5, 3, 10,
            windowFreshness = freshness, diagnosticContext = context,
            r14Ingress = if (external) KeyguardR14Ingress(id, true, 10, 0, 32, 10, 10,
                KeyguardR14Origin.SYSTEM_UI) else null)
        val a = request(1, false)
        val b = request(2, true)
        init {
            assertTrue(queue.offer(a))
            assertTrue(gate.arm(token, 5, a, authority, 7))
            gate.readStarted(a, 10, 100)
            gate.externalInvalidation(11, 110)
            queue.offer(b)
            gate.offered(b, queue.pendingRequest(), 11, 11, true)
            assertEquals(b, gate.claim(queue, a, token, 7, 11, safe, "beforeChild", 120,
                observationCaptureId = if (capture) context.captureId else null))
            gate.readFinished(a, 121)
        }
        fun offer(request: KeyguardCardInspectionRequest, framework: Boolean = true,
                  metadataPresent: Boolean = request.r14Ingress != null):
            KeyguardOpeningInspectionHandoff.PostClaimSnapshot? {
            val old = queue.pendingRequest()
            gate.externalInvalidation(12, 122)
            queue.offer(request)
            gate.offered(request, queue.pendingRequest(), 12, 12, framework)
            return gate.observePostClaimOffer(request, old, queue.activeRequest(), queue.pendingRequest(), framework,
                metadataPresent)
        }
    }

    @Test fun pendingAfterClaimIsReportedWithoutChangingActiveSuccessor() {
        val f = Fixture()
        val c = f.request(3, true)
        val observation = checkNotNull(f.offer(c))
        val recorded = checkNotNull(f.gate.snapshot(f.a.id))
        assertEquals("B must remain the active physical read", f.b, f.queue.activeRequest())
        assertEquals("C must remain the actual pending request", c, f.queue.pendingRequest())
        assertEquals("the claim must still identify B", f.b.id, recorded.claimedId)
        assertEquals("pre-claim evidence must still identify B", f.b.id, recorded.latestOfferedId)
        assertEquals("protected post-claim evidence must identify C", c.id, observation.first?.id)
        assertEquals(c.id, observation.latest?.id)
        assertEquals(32, observation.first?.eventType)
        assertEquals(0, observation.first?.display)
        assertEquals(1, observation.offers)
        assertEquals(0, observation.replacements)
        assertNull("first pending C does not replace active B", observation.first?.displacedId)
    }

    @Test fun offersBeforeAndDuringBTrackActualReplacementAndCopiedFreshness() {
        val f = Fixture()
        val c = f.request(3, true, KeyguardWindowFreshness.LIFECYCLE_BOUNDARY)
        val first = checkNotNull(f.offer(c))
        val started = checkNotNull(f.gate.successorStarted(f.b, 130))
        val d = f.request(4, false)
        val latest = checkNotNull(f.offer(d, framework = false))
        assertTrue(first.ordinal < started.ordinal && started.ordinal < latest.ordinal)
        assertEquals(c.id, latest.first?.id)
        assertEquals(d.id, latest.latest?.id)
        assertEquals(c.id, latest.latest?.displacedId)
        assertEquals("SYNTHETIC", latest.latest?.origin)
        assertTrue(checkNotNull(latest.latest).freshnessCopied)
        assertEquals(KeyguardWindowFreshness.LIFECYCLE_BOUNDARY, latest.latest?.freshness)
        assertEquals(2, latest.offers)
        assertEquals(1, latest.replacements)
        val closed = checkNotNull(f.gate.successorFinished(f.b, 140))
        assertEquals(130L, closed.bStartedAt)
        assertEquals(140L, closed.bFinishedAt)
        assertEquals("FINISHED", closed.closedReason)
        assertNull(f.offer(f.request(5, true)))
        assertEquals(closed, checkNotNull(f.gate.snapshot(f.a.id)).postClaim)
    }

    @Test fun syntheticReacquisitionPreservesOriginalIngressWithoutRelabellingItsOrigin() {
        val f = Fixture()
        val c = f.request(3, true)
        f.offer(c)
        val d = f.request(4, false).copy(r14Ingress = c.r14Ingress)
        val observation = checkNotNull(f.offer(d, framework = false, metadataPresent = false))
        assertEquals("SYNTHETIC", observation.latest?.origin)
        assertEquals(c.r14Ingress?.id, observation.latest?.ingressId)
        assertEquals("SYSTEM_UI", observation.latest?.ingressOrigin)
        assertEquals(c.id, observation.latest?.displacedId)
    }

    @Test fun noOfferAndCaptureOffAreDistinctFromMissingCoverage() {
        val f = Fixture()
        f.gate.successorStarted(f.b, 130)
        val closed = checkNotNull(f.gate.successorFinished(f.b, 140))
        assertEquals(0, closed.offers)
        assertNull(closed.first)
        assertEquals("FINISHED", closed.closedReason)
        val off = Fixture(capture = false)
        assertNull(off.offer(off.request(3, true)))
        assertNull(checkNotNull(off.gate.snapshot(off.a.id)).postClaim)
        assertEquals(off.b, off.queue.activeRequest())
    }

    @Test fun equalUptimeOffersAndCloseUseLogicalOrderAndCannotBeReplayed() {
        val f = Fixture()
        val c = f.request(3, true)
        val first = checkNotNull(f.offer(c))
        val d = f.request(4, true)
        val second = checkNotNull(f.offer(d))
        assertEquals(first.first?.queuedAt, second.latest?.queuedAt)
        assertTrue(second.ordinal > first.ordinal)
        assertEquals(c.id, second.latest?.displacedId)
        assertNull(f.gate.observePostClaimOffer(d, c, f.queue.activeRequest(), f.queue.pendingRequest(), true))
        val closed = checkNotNull(f.gate.successorFinished(f.b, 10))
        assertTrue(closed.ordinal > second.ordinal)
        assertNull(f.offer(f.request(5, true)))
        assertEquals(2, checkNotNull(f.gate.snapshot(f.a.id)).postClaim?.offers)
        assertEquals(1, checkNotNull(f.gate.snapshot(f.a.id)).postClaim?.replacements)
    }

    @Test fun laterWakeWithSameLocalIdCannotBeMutatedByOldSuccessor() {
        val f = Fixture()
        val old = checkNotNull(f.offer(f.request(3, true)))
        val nextAuthority = f.authority.copy(wakeGeneration = 4)
        val nextA = f.a.copy(wakeGeneration = 4,
            diagnosticContext = f.context.copy(captureId = "capture-b", originWakeEpoch = 4))
        val nextToken = Any()
        assertTrue(f.gate.arm(nextToken, 6, nextA, nextAuthority, 8))
        assertNull(f.gate.successorStarted(f.b, 130))
        assertNull(f.gate.successorFinished(f.b, 140))
        val current = checkNotNull(f.gate.snapshot(nextA.id))
        assertEquals(6L, current.reservationId)
        assertNull(current.claimedId)
        assertNull(current.postClaim)
        assertEquals("capture-a", old.context.captureId)
        assertNull(f.gate.claim(f.queue, nextA, f.token, 8, 11, f.safe, "old-token", 150))
        assertNull(checkNotNull(f.gate.snapshot(nextA.id)).lastCheckpoint)
    }

    @Test fun wrongOwnerCannotWriteCheckpointOrCloseObservation() {
        val f = Fixture()
        val c = f.request(3, true)
        val first = checkNotNull(f.offer(c))
        val foreignB = f.b.copy(session = 9)
        assertNull(f.gate.successorStarted(foreignB, 130))
        assertNull(f.gate.successorFinished(foreignB, 140))
        assertEquals(first, checkNotNull(f.gate.snapshot(f.a.id)).postClaim)
        assertNull(f.gate.claim(f.queue, f.a, Any(), 7, 12, f.safe, "wrong", 150))
        assertEquals("beforeChild", checkNotNull(f.gate.snapshot(f.a.id)).lastCheckpoint)
    }
}
