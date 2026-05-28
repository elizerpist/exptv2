package com.exptv2.app.expense

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class RecurringNotificationCardFactoryTest {
    @Test
    fun buildsActivationNotificationCardFromRecurringGhostAndTransaction() {
        val now = 1778803200000L
        val recurring = RecurringTransactionEntity(
            id = 9,
            name = "Rent",
            amount = 500.0,
            transactionType = "expense",
            dayOfMonth = 15,
            categoryId = 6,
            categoryName = "Q",
            categoryColor = "#dc2626",
            categoryIconSlot = 2,
            isActive = true,
            lastProcessedPeriodKey = null,
            lastProcessedAt = null,
            createdAt = now,
            updatedAt = now,
        )
        val ghost = RecurringGhostTransactionEntity(
            id = 4,
            recurringTransactionId = 9,
            periodKey = "2026-05",
            name = "Rent",
            amount = 500.0,
            transactionType = "expense",
            date = "2026.05.15",
            time = "00:00",
            categoryId = 6,
            categoryName = "Q",
            categoryColor = "#dc2626",
            categoryIconSlot = 2,
            triggerMillis = now,
            isActivated = false,
            activatedTransactionId = null,
            createdAt = now,
            updatedAt = now,
        )
        val transaction = ExpenseTransactionEntity(
            id = 26051501,
            date = "2026.05.15",
            time = "09:12",
            latitude = null,
            longitude = null,
            address = "Recurring transaction",
            merchant = "Rent",
            amount = -500.0,
            userAssignedName = "Rent",
            transactionCategoryID = 6,
        )

        val card = RecurringNotificationCardFactory.activationCard(
            recurring = recurring,
            ghost = ghost,
            transaction = transaction,
            now = now,
        )

        assertEquals("recurring_transaction_alert", card.type)
        assertEquals("Ismétlődő tranzakció aktiválva", card.title)
        assertTrue(card.message.contains("Rent"))
        assertFalse(card.isRead)
        assertTrue(card.isActive)
        assertEquals("info", card.priority)
        assertEquals(6, card.categoryId)
        assertEquals("Q", card.categoryName)
        assertEquals("#dc2626", card.categoryColor)
        assertEquals(2, card.categoryIconSlot)
        assertEquals(9, card.recurringTransactionId)
        assertEquals(26051501, card.transactionId)
        assertEquals(500.0, card.amount!!, 0.0)
        assertEquals("2026.05.15", card.triggerDate)
        assertEquals("2026.06.15", card.nextDueDate)
    }
}
