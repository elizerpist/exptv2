package com.exptv2.app.expense

import org.junit.Assert.assertEquals
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

class RecurringRuleInstancePlannerTest {
    private val utc = TimeZone.getTimeZone("UTC")

    @Test
    fun createsCurrentMonthInstanceFromExpectedDayAndAmount() {
        val plan = RecurringRuleInstancePlanner.plan(
            targetMillis = millis(2026, Calendar.JUNE, 6),
            expectedDayOfMonth = 15,
            estimatedAmount = 120000.0,
            timeZone = utc,
        )

        assertEquals("2026-06", plan.periodKey)
        assertEquals("2026.06.15", plan.estimatedDate)
        assertEquals(120000.0, plan.estimatedAmount, 0.0)
    }

    @Test
    fun clampsExpectedDayToLastDayOfShortMonth() {
        val plan = RecurringRuleInstancePlanner.plan(
            targetMillis = millis(2026, Calendar.FEBRUARY, 1),
            expectedDayOfMonth = 31,
            estimatedAmount = 9900.0,
            timeZone = utc,
        )

        assertEquals("2026-02", plan.periodKey)
        assertEquals("2026.02.28", plan.estimatedDate)
    }

    private fun millis(year: Int, month: Int, day: Int): Long {
        return Calendar.getInstance(utc).apply {
            clear()
            set(year, month, day, 12, 0, 0)
        }.timeInMillis
    }
}
