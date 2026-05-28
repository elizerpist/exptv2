package com.exptv2.app.expense.recurring

import java.util.Calendar
import java.util.TimeZone

object RecurringDebugClockNormalizer {
    fun normalizeToTriggerMillis(
        targetMillis: Long,
        timeZone: TimeZone = TimeZone.getDefault(),
    ): Long {
        return Calendar.getInstance(timeZone).apply {
            timeInMillis = targetMillis
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 1)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
    }
}
