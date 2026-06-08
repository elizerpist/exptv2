package com.exptv2.app.expense

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ExpenseNotificationCardFactoryTest {
    private val now = 1778803200000L
    private val category = TransactionCategoryEntity(
        transactionCategoryID = 6,
        name = "Élelmiszer",
        type = "kiadás",
        colorSlot = 4,
        iconSlot = 2,
        backgroundColor = "#dc2626",
        icon = null,
        notification = null,
        hasLimit = false,
        limitAmount = 0.0,
        alertActive = false,
        isCustomIcon = true,
        originalIcon = null,
    )
    private val transaction = ExpenseTransactionEntity(
        id = 26051501,
        date = "2026.05.15",
        time = "09:12",
        latitude = null,
        longitude = null,
        address = "Unknown location",
        merchant = "Tesco",
        amount = -4200.0,
        userAssignedName = null,
        transactionCategoryID = 6,
    )

    @Test
    fun buildsTransactionCreatedCard() {
        val card = ExpenseNotificationCardFactory.transactionCreated(
            transaction = transaction,
            category = category,
            now = now,
        )

        assertEquals("transaction_created", card.type)
        assertEquals("Új tranzakció", card.title)
        assertTrue(card.message.contains("Tesco"))
        assertTrue(card.message.contains("4200"))
        assertEquals("normal", card.priority)
        assertEquals(6, card.categoryId)
        assertEquals("Élelmiszer", card.categoryName)
        assertEquals(26051501, card.transactionId)
        assertEquals(4200.0, card.amount!!, 0.0)
        assertFalse(card.isRead)
        assertTrue(card.isActive)
    }

    @Test
    fun buildsLimitCardWithoutTransactionForLimitChange() {
        val alert = ExpenseLimitAlert(
            type = "limit_100",
            title = "Limit elérve",
            targetLabel = "Kiadási budget",
            category = null,
            transaction = null,
            limitAmount = 10000.0,
            spentAmount = 12000.0,
            remainingAmount = -2000.0,
            usageRatio = 1.2,
            targetType = "overview",
            targetId = 0,
            triggerDate = "2026-05",
            periodLabel = "összlimit",
        )

        val card = ExpenseNotificationCardFactory.limitAlert(alert, now)

        assertEquals("limit_100", card.type)
        assertEquals("Kiadási budget", card.categoryName)
        assertEquals(null, card.categoryId)
        assertEquals(null, card.transactionId)
        assertEquals(12000.0, card.amount!!, 0.0)
        assertEquals("2026-05", card.triggerDate)
        assertTrue(card.message.contains("összlimit Kiadási budget"))
        assertTrue(card.message.contains("2000 Ft-tal túllépted"))
    }

    @Test
    fun buildsLimitCardsWithRemainingAndOverageText() {
        val remaining = ExpenseLimitAlert(
            type = "limit_75",
            title = "Limit 75%",
            targetLabel = "Élelmiszer",
            category = category,
            transaction = transaction,
            limitAmount = 10000.0,
            spentAmount = 7600.0,
            remainingAmount = 2400.0,
            usageRatio = 0.76,
            periodLabel = "2026 májusi",
        )
        val over = remaining.copy(
            type = "limit_100",
            title = "Limit elérve",
            spentAmount = 11000.0,
            remainingAmount = -1000.0,
            usageRatio = 1.1,
        )

        val remainingCard = ExpenseNotificationCardFactory.limitAlert(remaining, now)
        val overCard = ExpenseNotificationCardFactory.limitAlert(over, now)

        assertEquals("limit_75", remainingCard.type)
        assertTrue(remainingCard.message.contains("2026 májusi Élelmiszer"))
        assertTrue(remainingCard.message.contains("2400 Ft maradt"))
        assertEquals("warning", remainingCard.priority)
        assertEquals("limit_100", overCard.type)
        assertTrue(overCard.message.contains("1000 Ft-tal túllépted"))
        assertEquals("critical", overCard.priority)
    }
}
