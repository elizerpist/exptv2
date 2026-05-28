package com.exptv2.app.expense

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

class RecurringGhostPlannerTest {
    private val utc = TimeZone.getTimeZone("UTC")

    @Test
    fun createsPendingGhostForCurrentMonthBeforeTriggerDate() {
        val plan = RecurringGhostPlanner.plan(
            targetMillis = millis(2026, Calendar.MAY, 10),
            dayOfMonth = 15,
            lastProcessedPeriodKey = "2026-04",
            timeZone = utc,
        )

        assertEquals("2026-05", plan.periodKey)
        assertEquals("2026.05.15", plan.date)
        assertFalse(plan.shouldActivate)
        assertTrue(plan.shouldShowGhost)
    }

    @Test
    fun activatesGhostWhenTargetReachesTriggerDate() {
        val plan = RecurringGhostPlanner.plan(
            targetMillis = millis(2026, Calendar.MAY, 15),
            dayOfMonth = 15,
            lastProcessedPeriodKey = "2026-04",
            timeZone = utc,
        )

        assertEquals("2026-05", plan.periodKey)
        assertEquals("2026.05.15", plan.date)
        assertTrue(plan.shouldActivate)
        assertTrue(plan.shouldShowGhost)
    }

    @Test
    fun doesNotShowOrActivateProcessedPeriodAgain() {
        val plan = RecurringGhostPlanner.plan(
            targetMillis = millis(2026, Calendar.MAY, 20),
            dayOfMonth = 15,
            lastProcessedPeriodKey = "2026-05",
            timeZone = utc,
        )

        assertFalse(plan.shouldShowGhost)
        assertFalse(plan.shouldActivate)
    }

    @Test
    fun rollsPendingGhostToTheNextMonth() {
        val plan = RecurringGhostPlanner.plan(
            targetMillis = millis(2026, Calendar.JUNE, 1),
            dayOfMonth = 15,
            lastProcessedPeriodKey = "2026-05",
            timeZone = utc,
        )

        assertEquals("2026-06", plan.periodKey)
        assertEquals("2026.06.15", plan.date)
        assertFalse(plan.shouldActivate)
        assertTrue(plan.shouldShowGhost)
    }

    private fun millis(year: Int, month: Int, day: Int): Long {
        return Calendar.getInstance(utc).apply {
            clear()
            set(year, month, day, 9, 0, 0)
        }.timeInMillis
    }
}
