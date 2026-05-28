package com.exptv2.app.expense

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

class RecurringScheduleCalculatorTest {
    private val utc = TimeZone.getTimeZone("UTC")

    @Test
    fun dueOnConfiguredDayWhenNotProcessedThisMonth() {
        val target = millis(2026, Calendar.MAY, 15)

        val decision = RecurringScheduleCalculator.decision(
            targetMillis = target,
            dayOfMonth = 15,
            lastProcessedPeriodKey = "2026-04",
            timeZone = utc,
        )

        assertTrue(decision.isDue)
        assertEquals("2026-05", decision.periodKey)
        assertEquals(15, decision.effectiveDayOfMonth)
    }

    @Test
    fun notDueTwiceInTheSameMonth() {
        val target = millis(2026, Calendar.MAY, 15)

        val decision = RecurringScheduleCalculator.decision(
            targetMillis = target,
            dayOfMonth = 15,
            lastProcessedPeriodKey = "2026-05",
            timeZone = utc,
        )

        assertFalse(decision.isDue)
    }

    @Test
    fun dayBeyondMonthLengthRunsOnLastDayOfMonth() {
        val target = millis(2026, Calendar.FEBRUARY, 28)

        val decision = RecurringScheduleCalculator.decision(
            targetMillis = target,
            dayOfMonth = 31,
            lastProcessedPeriodKey = null,
            timeZone = utc,
        )

        assertTrue(decision.isDue)
        assertEquals("2026-02", decision.periodKey)
        assertEquals(28, decision.effectiveDayOfMonth)
    }

    @Test
    fun notDueBeforeEffectiveDay() {
        val target = millis(2026, Calendar.MAY, 14)

        val decision = RecurringScheduleCalculator.decision(
            targetMillis = target,
            dayOfMonth = 15,
            lastProcessedPeriodKey = null,
            timeZone = utc,
        )

        assertFalse(decision.isDue)
    }

    private fun millis(year: Int, month: Int, day: Int): Long {
        return Calendar.getInstance(utc).apply {
            clear()
            set(year, month, day, 9, 0, 0)
        }.timeInMillis
    }
}
