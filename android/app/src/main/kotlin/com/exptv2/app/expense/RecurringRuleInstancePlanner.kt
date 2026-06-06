package com.exptv2.app.expense

import java.util.Calendar
import java.util.TimeZone

data class RecurringRuleInstancePlan(
    val periodKey: String,
    val estimatedDate: String,
    val estimatedAmount: Double,
)

object RecurringRuleInstancePlanner {
    fun plan(
        targetMillis: Long,
        expectedDayOfMonth: Int,
        estimatedAmount: Double,
        timeZone: TimeZone = TimeZone.getDefault(),
    ): RecurringRuleInstancePlan {
        val calendar = Calendar.getInstance(timeZone).apply { timeInMillis = targetMillis }
        val year = calendar.get(Calendar.YEAR)
        val month = calendar.get(Calendar.MONTH)
        val maxDay = calendar.getActualMaximum(Calendar.DAY_OF_MONTH)
        val effectiveDay = expectedDayOfMonth.coerceIn(1, maxDay)
        return RecurringRuleInstancePlan(
            periodKey = "%04d-%02d".format(year, month + 1),
            estimatedDate = "%04d.%02d.%02d".format(year, month + 1, effectiveDay),
            estimatedAmount = estimatedAmount,
        )
    }
}
