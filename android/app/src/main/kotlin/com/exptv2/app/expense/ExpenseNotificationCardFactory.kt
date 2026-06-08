package com.exptv2.app.expense

import java.util.Calendar
import kotlin.math.abs
import kotlin.math.roundToLong

data class ExpenseLimitAlert(
    val type: String,
    val title: String,
    val targetLabel: String,
    val category: TransactionCategoryEntity?,
    val transaction: ExpenseTransactionEntity?,
    val limitAmount: Double,
    val spentAmount: Double,
    val remainingAmount: Double,
    val usageRatio: Double,
    val targetType: String = "category",
    val targetId: Int = 0,
    val triggerDate: String? = null,
    val periodLabel: String = "",
)

object ExpenseNotificationCardFactory {
    fun transactionCreated(
        transaction: ExpenseTransactionEntity,
        category: TransactionCategoryEntity,
        now: Long,
    ): NotificationCardEntity {
        val amount = abs(transaction.amount)
        val displayName = transaction.userAssignedName?.takeIf { it.isNotBlank() } ?: transaction.merchant
        val typeLabel = if (transaction.amount >= 0.0) "bevétel" else "kiadás"
        return NotificationCardEntity(
            type = "transaction_created",
            title = "Új tranzakció",
            message = "$displayName: ${formatHuf(amount)} Ft $typeLabel rögzítve.",
            timestamp = now,
            isRead = false,
            isActive = true,
            priority = "normal",
            categoryId = category.transactionCategoryID,
            categoryName = category.name,
            categoryColor = category.backgroundColor ?: CategoryColorSlotManager.colorForSlot(category.colorSlot),
            categoryIconSlot = category.iconSlot ?: 0,
            recurringTransactionId = null,
            transactionId = transaction.id,
            amount = amount,
            triggerDate = transaction.date,
            nextDueDate = null,
            createdAt = now,
            updatedAt = now,
        )
    }

    fun recurringActivated(
        recurring: RecurringTransactionEntity,
        ghost: RecurringGhostTransactionEntity,
        transaction: ExpenseTransactionEntity,
        now: Long,
    ): NotificationCardEntity {
        return NotificationCardEntity(
            type = "recurring_transaction_alert",
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
            amount = abs(transaction.amount),
            triggerDate = ghost.date,
            nextDueDate = nextDueDate(ghost.periodKey, recurring.dayOfMonth),
            createdAt = now,
            updatedAt = now,
        )
    }

    fun recurringRuleActivated(
        rule: RecurringRuleEntity,
        instance: RecurringRuleInstanceEntity,
        transaction: ExpenseTransactionEntity,
        now: Long,
    ): NotificationCardEntity {
        return NotificationCardEntity(
            type = "recurring_transaction_alert",
            title = "Ismétlődő tranzakció aktiválva",
            message = "${rule.name} teljes értékű tranzakcióként rögzítve.",
            timestamp = now,
            isRead = false,
            isActive = true,
            priority = "info",
            categoryId = instance.categoryIdSnapshot,
            categoryName = instance.categoryNameSnapshot,
            categoryColor = instance.categoryColorSnapshot,
            categoryIconSlot = instance.categoryIconSlotSnapshot,
            recurringTransactionId = rule.id,
            transactionId = transaction.id,
            amount = abs(transaction.amount),
            triggerDate = instance.estimatedDate,
            nextDueDate = nextDueDate(instance.periodKey, rule.expectedDayOfMonth),
            createdAt = now,
            updatedAt = now,
        )
    }

    fun limitAlert(alert: ExpenseLimitAlert, now: Long): NotificationCardEntity {
        val category = alert.category
        val transaction = alert.transaction
        val fallbackCategoryId = when {
            transaction != null -> transaction.transactionCategoryID
            alert.targetType == "category" && alert.targetId > 0 -> alert.targetId
            else -> null
        }
        val prefix = listOf(alert.periodLabel, alert.targetLabel)
            .map { it.trim() }
            .filter { it.isNotEmpty() }
            .joinToString(" ")
        val message = when {
            alert.remainingAmount > 0.0 ->
                "$prefix: ${formatHuf(alert.remainingAmount)} Ft maradt a limitből."
            alert.remainingAmount == 0.0 ->
                "$prefix: Elérted a limitet, 0 Ft maradt."
            else ->
                "$prefix: ${formatHuf(abs(alert.remainingAmount))} Ft-tal túllépted a limitet."
        }
        return NotificationCardEntity(
            type = alert.type,
            title = alert.title,
            message = message,
            timestamp = now,
            isRead = false,
            isActive = true,
            priority = if (alert.type == "limit_100") "critical" else "warning",
            categoryId = category?.transactionCategoryID ?: fallbackCategoryId,
            categoryName = category?.name ?: alert.targetLabel,
            categoryColor = category?.backgroundColor
                ?: category?.colorSlot?.let { CategoryColorSlotManager.colorForSlot(it) },
            categoryIconSlot = category?.iconSlot ?: 0,
            recurringTransactionId = null,
            transactionId = transaction?.id,
            amount = abs(transaction?.amount ?: alert.spentAmount),
            triggerDate = alert.triggerDate ?: transaction?.date,
            nextDueDate = null,
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

    private fun formatHuf(value: Double): Long = abs(value).roundToLong()
}
