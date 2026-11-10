package com.fluvi.app.lockscreen.material

import com.fluvi.app.lockscreen.KeyguardMainWorkEvidence
import org.junit.Assert.*
import org.junit.Test

class KeyguardDrawGapEvidenceTest {
    @Test fun retainedGapCopiesOnlyItsOverlappingWorkAndFitsAWholeExportRecord() {
        val work = KeyguardMainWorkEvidence(); work.resetSession(2, 12345)
        val p = KeyguardDrawGapEvidence(); p.begin(9)
        val t = 429390245000000L
        p.drawn(9, t, t + 1, 0, 0, 0)
        repeat(5) { i -> work.record(1, i.toLong(), t + 2, t + 8 + i, -1) }
        p.callback(9, t + 10, t + 11, t + 12)
        p.drawn(9, t + 15, t + 16, 1, 1, 0, work,
            "deepDrift|true|" + "a".repeat(64) + "|adapter-v1", 160, 160)
        val snapshot = p.snapshot()
        assertEquals(3, snapshot.gaps.single().work!!.spans.size)
        assertEquals(2, snapshot.gaps.single().work!!.omittedOverlapping)
        work.resetSession(3, 99)
        assertEquals(2L, snapshot.gaps.single().work!!.serviceSession)
        assertTrue(snapshot.compact().contains(":NA:"))
        assertTrue(snapshot.compact().toByteArray(Charsets.UTF_8).size <= 1200)
    }
    @Test fun callbackDelayAndTraversalDelayRemainDistinct() {
        val p = KeyguardDrawGapEvidence()
        p.begin(8)
        p.callback(8, 10, 11, 12); p.drawn(8, 13, 14, 1, 1, 0)
        p.callback(8, 20, 90, 91); p.drawn(8, 92, 94, 1, 1, 1)
        p.callback(8, 100, 101, 102); p.drawn(8, 180, 184, 2, 1, 1)
        val gaps = p.snapshot().gaps
        assertEquals(2, gaps.size)
        val lateDraw = gaps.first()
        assertEquals(94L, lateDraw.previousEndNs)
        assertEquals(78L, lateDraw.currentStartNs - lateDraw.callbackExitNs)
        val lateCallback = gaps.last()
        assertEquals(70L, lateCallback.callbackEntryNs - lateCallback.frameNs)
        assertEquals(1L, lateCallback.currentStartNs - lateCallback.callbackExitNs)
        assertEquals(8L, p.snapshot().attachment)
    }
    @Test fun initialUnpairedAndCoalescedCallbacksAreHonest() {
        val p = KeyguardDrawGapEvidence(); p.begin(1)
        p.drawn(1, 1, 2, 1, 0, 1)
        p.callback(1, 3, 4, 5); p.callback(1, 6, 7, 8)
        p.drawn(1, 9, 10, 1, 0, 1)
        p.drawn(1, 11, 12, 1, 0, 1)
        assertEquals(2L, p.snapshot().unpairedDraws)
        assertEquals(1L, p.snapshot().coalescedCallbacks)
        assertEquals(2L, p.snapshot().gaps.first().callbacksSinceDraw)
        assertEquals(0L, p.snapshot().gaps.last().paired)
    }
    @Test fun hiddenIdleOldOwnerAndRemovedBeforeDrawCannotBecomeOutput() {
        val p = KeyguardDrawGapEvidence(); p.begin(1)
        p.drawn(1, 1, 2, 1, 0, 1); p.end()
        p.callback(1, 3, 4, 5); p.drawn(1, 6, 7, 1, 0, 1)
        p.begin(2); p.callback(1, 9, 10, 11); p.drawn(1, 12, 13, 1, 0, 1)
        assertEquals(0L, p.snapshot().observedDraws)
        assertTrue(p.snapshot().gaps.isEmpty())
        p.drawn(2, 900, 901, 1, 0, 1)
        assertTrue(p.snapshot().gaps.isEmpty())
        assertEquals(2L, p.snapshot().rejected)
    }
    @Test fun fixedWorstSlotsAndCaptureOffBreakExcludeUnobservedIdle() {
        val p = KeyguardDrawGapEvidence(); p.begin(3)
        for (i in 1L..100L) p.drawn(3, i * i * 10, i * i * 10 + 1, 1, 0, 1)
        assertEquals(3, p.snapshot().gaps.size)
        assertEquals(96L, p.snapshot().omittedGaps)
        p.samplingOff(); p.drawn(3, 999999, 1000000, 1, 0, 1)
        assertEquals(96L, p.snapshot().omittedGaps)
        assertEquals(1L, p.snapshot().samplingBreaks)
        assertEquals(1990L, p.snapshot().gaps.first().gapNs)
    }
}
