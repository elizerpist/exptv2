package com.fluvi.app.lockscreen.material

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class KeyguardOrbSurfaceMetricsTest {
    @Test fun boundedSnapshotKeepsFirstDistinctAndWorstSubmissionGap() {
        val metrics = KeyguardOrbSurfaceMetrics()
        metrics.record(100, 100_000_000, false, 1, 2, 3, 4, 5, 6)
        metrics.record(116, 116_000_000, true, 7, 8, 9, 10, 11, 12)
        metrics.record(196, 196_000_000, true, 3, 4, 5, 6, 7, 8)
        val snapshot = metrics.snapshot()
        assertEquals(3, snapshot.submissions)
        assertEquals(100L, snapshot.firstPostUptimeMs)
        assertEquals(116L, snapshot.firstDistinctUptimeMs)
        assertEquals(80_000_000L, snapshot.worstGapNs)
        assertEquals(1, snapshot.gapsOver50Ms)
        assertEquals(7, snapshot.maxLockWallNs)
        assertEquals(10, snapshot.maxLockCpuNs)
    }

    @Test fun emptyOrStaticMetricsNeverInventADistinctFrame() {
        val metrics = KeyguardOrbSurfaceMetrics()
        assertNull(metrics.snapshot().firstPostUptimeMs)
        metrics.record(5, 5_000_000, false, 1, 1, 1, 1, 1, 1)
        assertNull(metrics.snapshot().firstDistinctUptimeMs)
        repeat(1000) { index -> metrics.record(6L + index, 6_000_000L + index * 1_000_000L, false, 1, 1, 1, 1, 1, 1) }
        assertTrue(metrics.snapshot().retainedGaps <= 720)
    }

    @Test fun holderSnapshotSeparatesRevocationFromAnEnteredOperationFinishingLater() {
        val metrics = KeyguardOrbSurfaceMetrics()
        metrics.beginHolderOperation(100)
        metrics.holderLockReturned(101)
        metrics.revokeStarted(102)
        metrics.revokeReturned(103)
        val during = metrics.snapshot().holderOperation
        assertTrue(during.coherent)
        assertEquals(1L, during.id)
        assertNull(during.postReturn)
        assertEquals(102L, during.revokeBegin)
        assertEquals(103L, during.revokeReturn)
        metrics.holderDrawReturned(104)
        metrics.holderPostEntered(105)
        metrics.holderPostReturned(106)
        metrics.holderRecordObserved(107)
        val after = metrics.snapshot().holderOperation
        assertEquals(101L, after.lockReturn)
        assertEquals(106L, after.postReturn)
        assertEquals(107L, after.recordAt)
        assertEquals(103L, after.revokeReturn)
    }
}
