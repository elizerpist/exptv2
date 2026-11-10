package com.fluvi.app.lockscreen

import org.junit.Assert.*
import org.junit.Test

class KeyguardMainWorkEvidenceTest {
    @Test fun preservesAbsoluteEndpointsCpuAndNestedScopesForTheActualGap() {
        val evidence = KeyguardMainWorkEvidence()
        evidence.resetSession(7, 23)
        evidence.record(KeyguardMainWorkEvidence.INSPECTION_APPLY, 91, 100, 180, 9)
        evidence.record(KeyguardMainWorkEvidence.SYSTEM_GATE, 91, 110, 170, 3)
        evidence.record(KeyguardMainWorkEvidence.DIAGNOSTIC_PRODUCER, 91, 175, 179, 2)
        evidence.record(KeyguardMainWorkEvidence.SYSTEM_GATE, 92, 200, 250, 40)

        val gap = evidence.snapshotOverlapping(120, 190)
        assertEquals(7L, gap.serviceSession)
        assertEquals(23L, gap.ownerThreadId)
        assertEquals(3, gap.spans.size)
        val parent = gap.spans.single { it.kind == KeyguardMainWorkEvidence.INSPECTION_APPLY }
        assertEquals(91L, parent.requestId)
        assertEquals(100L, parent.startedNs)
        assertEquals(180L, parent.endedNs)
        assertEquals(9L, parent.cpuNs) // Whole-scope CPU, not invented overlap CPU.
        assertEquals(60L, parent.overlapNs)
        assertEquals(3L, gap.spans.single { it.kind == KeyguardMainWorkEvidence.SYSTEM_GATE }.cpuNs)
        assertEquals(0, gap.omittedOverlapping)
        assertFalse(gap.coverageIncomplete)
    }

    @Test fun keepsOnlyThreeOverlappingSpansAndDeclaresOmissions() {
        val evidence = KeyguardMainWorkEvidence()
        repeat(8) { index -> evidence.record(1, index.toLong(), 100, 101L + index, 1) }
        val gap = evidence.snapshotOverlapping(100, 200)
        assertEquals(listOf(7L, 6L, 5L), gap.spans.map { it.requestId })
        assertEquals(5, gap.omittedOverlapping)
        // Touching the endpoint is not an overlap.
        assertTrue(evidence.snapshotOverlapping(108, 200).spans.isEmpty())
    }

    @Test fun fixedRingAndSessionResetDoNotInventCompleteHistory() {
        val evidence = KeyguardMainWorkEvidence()
        evidence.resetSession(1, 20)
        repeat(40) { index -> evidence.record(1, index.toLong(), index * 10L, index * 10L + 5, 2) }
        val oldGap = evidence.snapshotOverlapping(0, 400)
        assertEquals(8L, oldGap.overwrittenSpans)
        assertTrue(oldGap.coverageIncomplete)
        assertEquals(29, oldGap.omittedOverlapping)
        val recentGap = evidence.snapshotOverlapping(390, 400)
        assertFalse(recentGap.coverageIncomplete)
        assertEquals(39L, recentGap.spans.single().requestId)

        evidence.resetSession(2, 21)
        val reset = evidence.snapshotOverlapping(0, 400)
        assertEquals(2L, reset.serviceSession)
        assertEquals(21L, reset.ownerThreadId)
        assertTrue(reset.spans.isEmpty())
        assertEquals(0L, reset.overwrittenSpans)
        // Previously exported evidence is immutable across service reset.
        assertEquals(1L, oldGap.serviceSession)
        assertEquals(3, oldGap.spans.size)
    }

    @Test fun missingAndInvalidMeasurementsStayExplicit() {
        val evidence = KeyguardMainWorkEvidence()
        assertTrue(evidence.snapshotOverlapping(1, 100).spans.isEmpty())
        evidence.record(1, 1, 200, 100, 1)
        evidence.record(1, 2, 100, 200, -2)
        val sample = evidence.snapshotOverlapping(1, 300)
        assertTrue(sample.spans.isEmpty())
        assertEquals(2L, sample.invalidSpans)
    }

    @Test fun unavailableCpuIsNotInventedZeroOrLostWallEvidence() {
        assertEquals(-1L, keyguardThreadCpuDelta(-1, -1))
        assertEquals(-1L, keyguardThreadCpuDelta(10, 9))
        assertEquals(0L, keyguardThreadCpuDelta(10, 10))
        val evidence = KeyguardMainWorkEvidence()
        evidence.record(1, 2, 100, 200, -1)
        assertEquals(-1L, evidence.snapshotOverlapping(110, 190).spans.single().cpuNs)
    }
}
