package com.exptv2.app.expense

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class ExpenseLimitNotificationEvaluatorTest {
    @Test
    fun computesPeriodKeysAndDateRangesFromTransactionDate() {
        val periods = ExpenseLimitNotificationEvaluator.periodsFor("2026.05.15")

        assertEquals("2026-05", periods.monthKey)
        assertEquals("2026", periods.yearKey)
        assertEquals("2026.05.01", periods.monthStart)
        assertEquals("2026.05.31", periods.monthEnd)
        assertEquals("2026.01.01", periods.yearStart)
        assertEquals("2026.12.31", periods.yearEnd)
    }

    @Test
    fun emitsNoAlertBelow75Percent() {
        val limit = limit(limitAmount = 10000.0)
        val result = ExpenseLimitNotificationEvaluator.evaluate(
            limit = limit,
            targetLabel = "Élelmiszer",
            category = null,
            transaction = transaction(),
            spentAmount = 7400.0,
        )

        assertNull(result)
    }

    @Test
    fun emits75AlertWithRemainingAmount() {
        val result = ExpenseLimitNotificationEvaluator.evaluate(
            limit = limit(limitAmount = 10000.0),
            targetLabel = "Élelmiszer",
            category = null,
            transaction = transaction(),
            spentAmount = 7600.0,
        )

        requireNotNull(result)
        assertEquals("limit_75", result.type)
        assertEquals("Limit 75%", result.title)
        assertEquals(2400.0, result.remainingAmount, 0.0)
        assertEquals(0.76, result.usageRatio, 0.001)
    }

    @Test
    fun emits100AlertWithOverageAmount() {
        val result = ExpenseLimitNotificationEvaluator.evaluate(
            limit = limit(limitAmount = 10000.0),
            targetLabel = "Élelmiszer",
            category = null,
            transaction = transaction(),
            spentAmount = 11250.0,
        )

        requireNotNull(result)
        assertEquals("limit_100", result.type)
        assertEquals("Limit elérve", result.title)
        assertEquals(-1250.0, result.remainingAmount, 0.0)
        assertEquals(1.125, result.usageRatio, 0.001)
    }

    private fun limit(limitAmount: Double) = CategoryLimitEntity(
        id = 4,
        targetType = "category",
        targetId = 6,
        transactionType = "expense",
        window = "monthly",
        periodKey = "2026-05",
        hasLimit = true,
        limitAmount = limitAmount,
        alertActive = true,
        createdAt = 1,
        updatedAt = 1,
    )

    private fun transaction() = ExpenseTransactionEntity(
        id = 26051501,
        date = "2026.05.15",
        time = "09:12",
        latitude = null,
        longitude = null,
        address = null,
        merchant = "Tesco",
        amount = -4200.0,
        userAssignedName = null,
        transactionCategoryID = 6,
    )
}
