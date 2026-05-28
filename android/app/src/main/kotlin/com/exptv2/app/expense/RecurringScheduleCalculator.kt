package com.exptv2.app.expense

import java.util.Calendar
import java.util.TimeZone

data class RecurringScheduleDecision(
    val isDue: Boolean,
    val periodKey: String,
    val effectiveDayOfMonth: Int,
)

object RecurringScheduleCalculator {
    fun decision(
        targetMillis: Long,
        dayOfMonth: Int,
        lastProcessedPeriodKey: String?,
        timeZone: TimeZone = TimeZone.getDefault(),
    ): RecurringScheduleDecision {
        val calendar = Calendar.getInstance(timeZone).apply { timeInMillis = targetMillis }
        val year = calendar.get(Calendar.YEAR)
        val month = calendar.get(Calendar.MONTH)
        val today = calendar.get(Calendar.DAY_OF_MONTH)
        val maxDay = calendar.getActualMaximum(Calendar.DAY_OF_MONTH)
        val effectiveDay = dayOfMonth.coerceIn(1, maxDay)
        val periodKey = "%04d-%02d".format(year, month + 1)
        val due = today == effectiveDay && lastProcessedPeriodKey != periodKey
        return RecurringScheduleDecision(
            isDue = due,
            periodKey = periodKey,
            effectiveDayOfMonth = effectiveDay,
        )
    }
}
