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

    @Test fun prewakePosterDoesNotCountAsAnActiveMotionGap() {
        val metrics = KeyguardOrbSurfaceMetrics()
        metrics.record(1_000, 1_000_000_000, false, 1, 1, 1, 1, 1, 1)
        metrics.beginDirectPresentation(45_000)
        metrics.record(45_016, 45_016_000_000, true, 1, 1, 1, 1, 1, 1)
        metrics.record(45_032, 45_032_000_000, true, 1, 1, 1, 1, 1, 1)
        val result = metrics.snapshot()
        assertEquals(1_000L, result.firstPostUptimeMs)
        assertEquals(45_000L, result.activeStartedAtUptimeMs)
        assertEquals(45_016L, result.firstDistinctUptimeMs)
        assertEquals(2L, result.activeSubmissions)
        assertEquals(1, result.retainedGaps)
        assertEquals(16_000_000L, result.worstGapNs)
        assertEquals(0L, result.gapsOver50Ms)
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
