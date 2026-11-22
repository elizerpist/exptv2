package com.fluvi.app.lockscreen

import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import org.junit.Assert.*
import org.junit.Test

class KeyguardOpeningPublicationTest {
    @Test fun successorStartsWhileFirstMainNoticeIsHeld() {
        val queue = KeyguardCardInspectionQueue()
        val opening = KeyguardOpeningPublication<String>()
        val lock = Any()
        val worker = Executors.newSingleThreadExecutor()
        val started = CountDownLatch(1)
        val a = request(1); val b = request(2)
        try {
            assertTrue(synchronized(lock) { queue.offer(a) })
            val notice = synchronized(lock) { opening.park(queue, a, "complete A")!!.noticeToPost!! }
            val actual = synchronized(lock) {
                assertFalse(queue.offer(b))
                opening.supersede(queue, a, queue.pendingRequest()!!)!!.successor
            }
            worker.execute { if (actual == b) started.countDown() }
            worker.submit {}.get(10, TimeUnit.SECONDS) // acknowledged worker barrier
            assertEquals(0L, started.count)
            assertEquals(b, synchronized(lock) { queue.activeRequest() })
            assertNull(synchronized(lock) { opening.claim(queue, notice) })
        } finally {
            worker.shutdown()
            assertTrue(worker.awaitTermination(10, TimeUnit.SECONDS))
        }
    }

    @Test fun pendingBeforeCompletionPromotesOnlyExactCurrentRequest() {
        val q = KeyguardCardInspectionQueue(); val a = request(1); val b = request(2); val c = request(3)
        q.offer(a); q.offer(b); q.offer(c)
        assertNull(q.handoffCompleted(a, b))
        assertEquals(c, q.handoffCompleted(a, c))
        assertNull(q.complete(a))
        assertEquals(c, q.activeRequest())
    }

    @Test fun mainClaimMakesLaterOfferWaitAndAppliesAtMostOnce() {
        val q = KeyguardCardInspectionQueue(); val p = KeyguardOpeningPublication<String>()
        val a = request(1); val b = request(2)
        q.offer(a); val n = p.park(q, a, "a")!!.noticeToPost!!
        assertEquals(a, p.claim(q, n)!!.request)
        assertFalse(q.offer(b))
        assertNull(p.supersede(q, a, b))
        assertNull(p.claim(q, n))
        assertEquals(b, p.finish(q, a))
        assertNull(p.finish(q, a))
        assertEquals(b, q.activeRequest())
    }

    @Test fun stableAnswerCanBeClaimedOnceWithoutNewRead() {
        val q = KeyguardCardInspectionQueue(); val p = KeyguardOpeningPublication<String>(); val a = request(1)
        q.offer(a); val n = p.park(q, a, "original")!!.noticeToPost!!
        assertEquals("original", p.claim(q, n)!!.value)
        assertNull(p.claim(q, n))
        assertNull(p.finish(q, a))
        assertNull(q.activeRequest())
    }

    @Test fun latestPendingCopyRetainsItsActualFreshness() {
        val q = KeyguardCardInspectionQueue(); val p = KeyguardOpeningPublication<String>()
        val a = request(1); val b = request(2).copy(windowFreshness = KeyguardWindowFreshness.LIFECYCLE_BOUNDARY)
        val c = request(3)
        q.offer(a); p.park(q, a, "a")
        q.offer(b); q.offer(c)
        val actual = q.pendingRequest()!!
        assertEquals(c.id, actual.id)
        assertEquals(KeyguardWindowFreshness.LIFECYCLE_BOUNDARY, actual.windowFreshness)
        assertNull(p.supersede(q, a, b))
        assertEquals(actual, p.supersede(q, a, actual)!!.successor)
    }

    @Test fun oldNoticeCanOnlyClaimCurrentTicketInSameSession() {
        val q = KeyguardCardInspectionQueue(); val p = KeyguardOpeningPublication<String>()
        val a = request(1); val b = request(2); val c = request(3, session = 2)
        q.offer(a); val old = p.park(q, a, "a")!!.noticeToPost!!
        q.offer(b); assertEquals(b, p.supersede(q, a, b)!!.successor)
        // Old notification may drain the latest completed ticket in its own
        // session; it never carries the old A observation into B.
        assertNull(p.park(q, b, "b")!!.noticeToPost)
        assertEquals("b", p.claim(q, old)!!.value)
        assertNull(p.finish(q, b))
        q.offer(c); val fresh = p.park(q, c, "c")!!.noticeToPost!!
        assertNull(p.claim(q, old))
        assertEquals("c", p.claim(q, fresh)!!.value)
    }

    @Test fun consumedNoticeBeforeSuccessorFinishesDoesNotLoseWakeup() {
        val q = KeyguardCardInspectionQueue(); val p = KeyguardOpeningPublication<String>()
        val a = request(1); val b = request(2)
        q.offer(a); val old = p.park(q, a, "a")!!.noticeToPost!!
        q.offer(b); assertEquals(b, p.supersede(q, a, b)!!.successor)
        assertNull(p.claim(q, old)) // B is still physically reading.
        val fresh = p.park(q, b, "b")!!.noticeToPost!!
        assertNotEquals(old, fresh)
        assertEquals(b, p.claim(q, fresh)!!.request)
    }

    @Test fun oldNoticeCannotConsumeNewSessionAfterDiscard() {
        val q = KeyguardCardInspectionQueue(); val p = KeyguardOpeningPublication<String>()
        val a = request(1); val b = request(2, session = 2)
        q.offer(a); val old = p.park(q, a, "a")!!.noticeToPost!!
        assertNotNull(p.discard(q, a)); q.offer(b)
        val fresh = p.park(q, b, "b")!!.noticeToPost!!
        assertNull(p.claim(q, old))
        assertEquals(b, p.claim(q, fresh)!!.request)
    }

    @Test fun oldWakeNoticeDrainsOnlyTheNewWakeTicketWithinItsSession() {
        val q = KeyguardCardInspectionQueue(); val p = KeyguardOpeningPublication<String>()
        val a = request(1); val b = request(2).copy(wakeGeneration = 2)
        q.offer(a); val old = p.park(q, a, "a")!!.noticeToPost!!
        assertNotNull(p.discard(q, a)); q.offer(b)
        // The notification carries no old result or grant. Reuse it for the
        // exact current B rather than queuing one notification per wake.
        assertNull(p.park(q, b, "b")!!.noticeToPost)
        assertEquals(b, p.claim(q, old)!!.request)
        assertNull(p.claim(q, old))
    }

    @Test fun failedPostReleasesExactOwnerAndSuccessorPostsItsOwnNotice() {
        val q = KeyguardCardInspectionQueue(); val p = KeyguardOpeningPublication<String>()
        val a = request(1); val b = request(2)
        q.offer(a); val failed = p.park(q, a, "a")!!.noticeToPost!!; q.offer(b)
        assertEquals(b, p.discardFailedNotice(q, failed)!!.successor)
        val fresh = p.park(q, b, "b")!!.noticeToPost!!
        assertNull(p.discardFailedNotice(q, failed))
        assertEquals(b, p.claim(q, fresh)!!.request)
    }

    @Test fun discardOnlyTouchesExactUnclaimedOwner() {
        val q = KeyguardCardInspectionQueue(); val p = KeyguardOpeningPublication<String>()
        val a = request(1); val b = request(2); val c = request(3)
        q.offer(a); p.park(q, a, "a"); q.offer(b)
        assertNull(p.discard(q, c))
        assertEquals(b, p.discard(q, a)!!.successor)
        assertNull(p.discard(q, a))
        assertEquals(b, q.activeRequest())
    }

    @Test fun reservedPredecessorCannotEnterCompletedPositiveHandoff() {
        val q = KeyguardCardInspectionQueue(); val p = KeyguardOpeningPublication<String>()
        val a = request(1); val b = request(2); val c = request(3)
        q.offer(a); q.offer(b); assertEquals(b, q.reserveSuccessor(a) { true }); q.offer(c)
        assertNull(p.park(q, b, "b"))
        assertNull(q.handoffCompleted(b, c))
        assertTrue(q.finishPreceding(a))
        assertEquals(c, q.complete(b))
    }

    private fun request(id: Long, session: Long = 1L) = KeyguardCardInspectionRequest(
        id = id, trigger = "window", session = session, visibilityEpoch = 1,
        interactionEpoch = 1, attachGeneration = 1, wakeGeneration = 1, queuedAtUptimeMs = id,
    )
}
