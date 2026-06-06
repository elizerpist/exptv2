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

    @Test
    fun transactionMapIncludesRecurringRuleAndInstanceLinks() {
        val row = ExpenseTransactionEntity(
            id = 26060101,
            date = "2026.06.01",
            time = "09:10",
            latitude = null,
            longitude = null,
            address = "Push",
            merchant = "OTP Bank",
            amount = -120000.0,
            userAssignedName = "Lakáshitel",
            transactionCategoryID = 6,
            recurringTransactionId = 9,
            recurringRuleId = 90,
            recurringInstanceId = 900,
        )

        val map = row.toMap()

        assertEquals(9, map["recurringTransactionId"])
        assertEquals(90, map["recurringRuleId"])
        assertEquals(900, map["recurringInstanceId"])
    }
}
