package com.exptv2.app.expense

import java.util.Calendar

object RecurringNotificationCardFactory {
    fun activationCard(
        recurring: RecurringTransactionEntity,
        ghost: RecurringGhostTransactionEntity,
        transaction: ExpenseTransactionEntity,
        now: Long,
    ): NotificationCardEntity {
        return NotificationCardEntity(
            type = "recurring_activation",
            title = "Ismétlődő tranzakció aktiválva",
            message = "${recurring.name} teljes értékű tranzakcióként rögzítve.",
            timestamp = now,
            isRead = false,
            isActive = true,
            priority = "info",
            categoryId = ghost.categoryId,
            categoryName = ghost.categoryName,
            categoryColor = ghost.categoryColor,
            categoryIconSlot = ghost.categoryIconSlot,
            recurringTransactionId = recurring.id,
            transactionId = transaction.id,
            amount = kotlin.math.abs(transaction.amount),
            triggerDate = ghost.date,
            nextDueDate = nextDueDate(ghost.periodKey, recurring.dayOfMonth),
            createdAt = now,
            updatedAt = now,
        )
    }

    private fun nextDueDate(periodKey: String, dayOfMonth: Int): String {
        val parts = periodKey.split("-")
        val year = parts.getOrNull(0)?.toIntOrNull() ?: return ""
        val month = parts.getOrNull(1)?.toIntOrNull() ?: return ""
        val calendar = Calendar.getInstance().apply {
            clear()
            set(Calendar.YEAR, year)
            set(Calendar.MONTH, month)
            set(Calendar.DAY_OF_MONTH, 1)
        }
        val maxDay = calendar.getActualMaximum(Calendar.DAY_OF_MONTH)
        calendar.set(Calendar.DAY_OF_MONTH, dayOfMonth.coerceIn(1, maxDay))
        return "%04d.%02d.%02d".format(
            calendar.get(Calendar.YEAR),
            calendar.get(Calendar.MONTH) + 1,
            calendar.get(Calendar.DAY_OF_MONTH),
        )
    }
}
