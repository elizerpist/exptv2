package com.exptv2.app.expense.recurring

import org.junit.Assert.assertEquals
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

class RecurringDebugClockNormalizerTest {
    private val utc = TimeZone.getTimeZone("UTC")

    @Test
    fun normalizesAnyTimeToOneMinuteAfterMidnight() {
        val source = millis(2026, Calendar.JUNE, 1, 18, 45)
        val normalized = RecurringDebugClockNormalizer.normalizeToTriggerMillis(source, utc)

        assertEquals(millis(2026, Calendar.JUNE, 1, 0, 1), normalized)
    }

    private fun millis(year: Int, month: Int, day: Int, hour: Int, minute: Int): Long {
        return Calendar.getInstance(utc).apply {
            clear()
            set(year, month, day, hour, minute, 0)
        }.timeInMillis
    }
}
