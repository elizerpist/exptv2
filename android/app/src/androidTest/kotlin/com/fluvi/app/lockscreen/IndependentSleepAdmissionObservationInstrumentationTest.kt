package com.fluvi.app.lockscreen

import android.view.Display
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class IndependentSleepAdmissionObservationInstrumentationTest {
    private fun sample(values: MutableList<Any>, now: MutableList<Long>, deadline: Long = 6_000L) =
        IndependentSleepAdmissionCollector({ now.removeAt(0) }, { values.removeAt(0) as Boolean },
            { values.removeAt(0) as Int }, { values.removeAt(0) as Boolean }).collect(1, 1, deadline)

    @Test fun nonInteractiveDoesNotMeanDisplayOff() {
        listOf(Display.STATE_ON, Display.STATE_DOZE, Display.STATE_UNKNOWN).forEach { state ->
            assertFalse(sample(mutableListOf(false, state, true, true, state, false), mutableListOf(0, 1)).accepted)
        }
        assertFalse(sample(mutableListOf(false, Display.STATE_OFF, false, false, Display.STATE_OFF, false), mutableListOf(0, 1)).accepted)
    }
    @Test fun delayedCompletedSleepUsesRemainingAggregateBudget() {
        val budget = IndependentSleepAdmissionBudget(0, 9_000)
        assertEquals(3_000, budget.nonInteractiveDeadlineUptimeMs)
        assertTrue(sample(mutableListOf(false, Display.STATE_OFF, true, true, Display.STATE_OFF, false), mutableListOf(3_300, 4_000), budget.admissionDeadlineUptimeMs).accepted)
    }
    @Test fun incompleteOrLateAdmissionFailsClosed() {
        assertFalse(sample(mutableListOf(false, Display.STATE_OFF, false, false, Display.STATE_OFF, false), mutableListOf(0, 6_000)).accepted)
        assertFalse(sample(mutableListOf(false, Display.STATE_OFF, true, true, Display.STATE_OFF, false), mutableListOf(0, 6_001)).accepted)
    }
    @Test fun phaseAndGlobalDeadlinesDoNotRestart() {
        val b = IndependentSleepAdmissionBudget(100, 5_500)
        assertEquals(3_100, b.nonInteractiveDeadlineUptimeMs); assertEquals(5_500, b.admissionDeadlineUptimeMs)
        assertFalse(5_600 <= b.admissionDeadlineUptimeMs)
    }
    @Test fun transitionDuringSampleIsRejected() {
        assertFalse(sample(mutableListOf(false, Display.STATE_OFF, true, false, Display.STATE_OFF, false), mutableListOf(0, 1)).accepted)
        assertTrue(sample(mutableListOf(false, Display.STATE_OFF, true, true, Display.STATE_OFF, false), mutableListOf(2, 3)).accepted)
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
    }
    @Test fun acceptedRecordIsImmutableAndEpisodeSpecific() {
        val accepted = sample(mutableListOf(false, Display.STATE_OFF, true, true, Display.STATE_OFF, false), mutableListOf(0, 1))
        assertTrue(accepted.accepted); assertEquals(1, accepted.episodeId)
        val next = accepted.copy(episodeId = 2, observationId = 2, startedAtUptimeMs = 9, admissionDeadlineUptimeMs = 6_009)
        assertNotEquals(accepted.episodeId, next.episodeId)
    }
}
