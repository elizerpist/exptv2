package com.fluvi.app.lockscreen

import android.view.Display
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class IndependentSleepAdmissionObservationInstrumentationTest {
    private fun collect(
        episodeId: Long = 1L,
        observationId: Long = 1L,
        start: Long = 0L,
        finish: Long = 1L,
        deadline: Long = 6_000L,
        interactiveBefore: Boolean = false,
        displayBefore: Int = Display.STATE_OFF,
        lockedBefore: Boolean = true,
        lockedAfter: Boolean = true,
        displayAfter: Int = Display.STATE_OFF,
        interactiveAfter: Boolean = false,
    ): IndependentSleepAdmissionObservation {
        val times = ArrayDeque(listOf(start, finish))
        val interactive = ArrayDeque(listOf(interactiveBefore, interactiveAfter))
        val displays = ArrayDeque(listOf(displayBefore, displayAfter))
        val locks = ArrayDeque(listOf(lockedBefore, lockedAfter))
        return IndependentSleepAdmissionCollector(
            { times.removeFirst() },
            { interactive.removeFirst() },
            { displays.removeFirst() },
            { locks.removeFirst() },
        ).collect(episodeId, observationId, deadline)
    }

    @Test fun nonInteractiveDoesNotMeanDisplayOff() {
        listOf(Display.STATE_ON, Display.STATE_DOZE, Display.STATE_UNKNOWN).forEach { state ->
            assertFalse(collect(displayBefore = state, displayAfter = state).accepted)
        }
        assertFalse(collect(lockedBefore = false, lockedAfter = false).accepted)
    }

    @Test fun delayedCompletedSleepUsesRemainingAggregateBudget() {
        val budget = IndependentSleepAdmissionBudget(0L, 9_000L)
        assertEquals(3_000L, budget.nonInteractiveDeadlineUptimeMs)
        assertEquals(6_000L, budget.admissionDeadlineUptimeMs)
        assertFalse(collect(start = 3_300L, finish = 3_300L, deadline = 3_300L).accepted)
        assertTrue(collect(start = 3_900L, finish = 4_000L, deadline = budget.admissionDeadlineUptimeMs).accepted)
        assertFalse(collect(start = 3_900L, finish = 4_000L, deadline = 3_300L).accepted)
    }

    @Test fun incompleteOrLateAdmissionFailsClosed() {
        assertFalse(collect(lockedBefore = false, lockedAfter = false).accepted)
        assertTrue(collect(finish = 6_000L).accepted)
        assertFalse(collect(finish = 6_001L).accepted)
    }

    @Test fun phaseAndGlobalDeadlinesDoNotRestart() {
        val budget = IndependentSleepAdmissionBudget(100L, 5_500L)
        assertEquals(3_100L, budget.nonInteractiveDeadlineUptimeMs)
        assertEquals(5_500L, budget.admissionDeadlineUptimeMs)
        var time = 3_099L
        assertNull(awaitIndependentSleepNonInteractive(3_100L, { time }, { time = 3_101L; false }, {}))
        time = 3_099L
        assertEquals(3_100L, awaitIndependentSleepNonInteractive(3_100L, { time }, { time = 3_100L; false }, {}))
        var reads = 0
        assertNull(awaitIndependentSleepNonInteractive(3_100L, { 3_100L }, { reads += 1; false }, {}))
        assertEquals(0, reads)
        assertTrue(5_600L > budget.admissionDeadlineUptimeMs)
    }

    @Test fun transitionDuringSampleIsRejected() {
        assertFalse(collect(interactiveAfter = true).accepted)
        assertFalse(collect(displayAfter = Display.STATE_DOZE).accepted)
        assertFalse(collect(lockedAfter = false).accepted)
        assertTrue(collect(episodeId = 2L, observationId = 2L, start = 2L, finish = 3L).accepted)
    }

    @Test fun failedAcquisitionCannotBecomeAdmission() {
        val expected = IllegalStateException("read")
        val collector = IndependentSleepAdmissionCollector(
            { 0L }, { throw expected }, { Display.STATE_UNKNOWN }, { true },
        )
        var failure: Throwable? = null
        try {
            collector.collect(1L, 1L, 6_000L)
        } catch (error: Throwable) {
            failure = error
        }
        assertSame("read failure must propagate", expected, failure)

        val retention = IndependentSleepAdmissionRetention()
        val rejected = collect(observationId = 7L, lockedBefore = false, lockedAfter = false)
        retention.retain(rejected)
        assertEquals(1, retention.totalCompleted)
        assertEquals(7L, retention.observations().single().observationId)
        assertEquals(0, retention.omittedCompleted())
    }

    @Test fun acceptedRecordIsImmutableAndEpisodeSpecific() {
        var now = 0L
        var interactive = false
        var display = Display.STATE_OFF
        var locked = true
        var reads = 0
        val collector = IndependentSleepAdmissionCollector(
            { now += 1L; now },
            { reads += 1; interactive },
            { reads += 1; display },
            { reads += 1; locked },
        )
        val first = collector.collect(1L, 1L, 6_000L)
        assertTrue(first.accepted)
        val afterFirstReads = reads
        locked = false
        repeat(3) {
            assertTrue(first.accepted)
            assertEquals("historical record must not requery", afterFirstReads, reads)
            assertTrue(first.evidenceFields().contains("episodeId=1"))
        }
        val second = collector.collect(2L, 1L, 6_100L)
        assertFalse(second.accepted)
        assertNotEquals(first.episodeId, second.episodeId)
        assertNotEquals(first.startedAtUptimeMs, second.startedAtUptimeMs)

        val retention = IndependentSleepAdmissionRetention()
        repeat(10) { index ->
            retention.retain(collect(observationId = (index + 1).toLong(), start = index.toLong(), finish = index + 1L,
                lockedBefore = index % 2 == 0, lockedAfter = index % 2 == 0))
        }
        assertTrue(retention.observations().size <= 8)
        assertEquals(1L, retention.observations().first().observationId)
        assertEquals(10L, retention.observations().last().observationId)
        assertEquals(10 - retention.observations().size, retention.omittedCompleted())
    }
}
