package com.exptv2.app.expense

import java.util.Calendar
import kotlin.math.abs

data class ExpenseLimitPeriods(
    val monthKey: String,
    val yearKey: String,
    val monthStart: String,
    val monthEnd: String,
    val yearStart: String,
    val yearEnd: String,
)

object ExpenseLimitNotificationEvaluator {
    fun periodsFor(transactionDate: String): ExpenseLimitPeriods {
        val parts = transactionDate.replace('-', '.').split('.')
        val year = parts.getOrNull(0)?.toIntOrNull() ?: 1970
        val month = parts.getOrNull(1)?.toIntOrNull() ?: 1
        val calendar = Calendar.getInstance().apply {
            clear()
            set(Calendar.YEAR, year)
            set(Calendar.MONTH, month - 1)
            set(Calendar.DAY_OF_MONTH, 1)
        }
        val monthEndDay = calendar.getActualMaximum(Calendar.DAY_OF_MONTH)
        return ExpenseLimitPeriods(
            monthKey = "%04d-%02d".format(year, month),
            yearKey = "%04d".format(year),
            monthStart = "%04d.%02d.01".format(year, month),
            monthEnd = "%04d.%02d.%02d".format(year, month, monthEndDay),
            yearStart = "%04d.01.01".format(year),
            yearEnd = "%04d.12.31".format(year),
        )
    }

    fun evaluate(
        limit: CategoryLimitEntity,
        targetLabel: String,
        category: TransactionCategoryEntity?,
        transaction: ExpenseTransactionEntity,
        spentAmount: Double,
    ): ExpenseLimitAlert? {
        if (!limit.hasLimit || !limit.alertActive || limit.limitAmount <= 0.0) return null
        val usageRatio = spentAmount / limit.limitAmount
        val remainingAmount = limit.limitAmount - spentAmount
        val type = when {
            usageRatio >= 1.0 -> "limit_100"
            usageRatio >= 0.75 -> "limit_75"
            else -> return null
        }
        return ExpenseLimitAlert(
            type = type,
            title = if (type == "limit_100") "Limit elérve" else "Limit 75%",
            targetLabel = targetLabel,
            category = category,
            transaction = transaction,
            limitAmount = limit.limitAmount,
            spentAmount = abs(spentAmount),
            remainingAmount = remainingAmount,
            usageRatio = usageRatio,
        )
    }
}
