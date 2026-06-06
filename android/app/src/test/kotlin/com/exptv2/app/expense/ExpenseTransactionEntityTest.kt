package com.exptv2.app.expense

import org.junit.Assert.assertEquals
import org.junit.Test

class ExpenseTransactionEntityTest {
    @Test
    fun mapsRecurringGeneratedTransactionId() {
        val row = ExpenseTransactionEntity(
            id = 26060501,
            date = "2026.06.05",
            time = "08:30",
            latitude = null,
            longitude = null,
            address = "Recurring transaction",
            merchant = "Fizetés",
            amount = 560000.0,
            userAssignedName = "Fizetés",
            transactionCategoryID = 1,
            recurringTransactionId = 9,
        )

        assertEquals(9, row.toMap()["recurringTransactionId"])
    }
}
