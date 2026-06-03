package com.exptv2.app.expense

object RecurringNotificationCardFactory {
    fun activationCard(
        recurring: RecurringTransactionEntity,
        ghost: RecurringGhostTransactionEntity,
        transaction: ExpenseTransactionEntity,
        now: Long,
    ): NotificationCardEntity {
        return ExpenseNotificationCardFactory.recurringActivated(
            recurring = recurring,
            ghost = ghost,
            transaction = transaction,
            now = now,
        )
    }
}
