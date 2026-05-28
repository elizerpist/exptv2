package com.exptv2.app.expense

import java.util.Calendar
import java.util.TimeZone

data class RecurringGhostPlan(
    val periodKey: String,
    val date: String,
    val effectiveDayOfMonth: Int,
    val triggerMillis: Long,
    val shouldShowGhost: Boolean,
    val shouldActivate: Boolean,
)

object RecurringGhostPlanner {
    fun plan(
        targetMillis: Long,
        dayOfMonth: Int,
        lastProcessedPeriodKey: String?,
        timeZone: TimeZone = TimeZone.getDefault(),
    ): RecurringGhostPlan {
        val calendar = Calendar.getInstance(timeZone).apply { timeInMillis = targetMillis }
        val year = calendar.get(Calendar.YEAR)
        val month = calendar.get(Calendar.MONTH)
        val today = calendar.get(Calendar.DAY_OF_MONTH)
        val maxDay = calendar.getActualMaximum(Calendar.DAY_OF_MONTH)
        val effectiveDay = dayOfMonth.coerceIn(1, maxDay)
        val periodKey = "%04d-%02d".format(year, month + 1)
        val date = "%04d.%02d.%02d".format(year, month + 1, effectiveDay)
        val processedThisPeriod = lastProcessedPeriodKey == periodKey
        val trigger = Calendar.getInstance(timeZone).apply {
            clear()
            set(year, month, effectiveDay, 0, 0, 0)
            set(Calendar.MILLISECOND, 0)
        }
        return RecurringGhostPlan(
            periodKey = periodKey,
            date = date,
            effectiveDayOfMonth = effectiveDay,
            triggerMillis = trigger.timeInMillis,
            shouldShowGhost = !processedThisPeriod,
            shouldActivate = !processedThisPeriod && today >= effectiveDay,
        )
    }
}
