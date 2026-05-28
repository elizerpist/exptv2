package com.exptv2.app.expense

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

class NotificationCardEntityTest {
    @Test
    fun mapsRecurringNotificationCardToFlutterPayload() {
        val row = NotificationCardEntity(
            id = 3,
            type = "recurring_transaction_alert",
            title = "Ismétlődő tranzakció",
            message = "Rent automatikusan hozzáadva",
            timestamp = 1778803200000,
            isRead = false,
            isActive = true,
            priority = "medium",
            categoryId = 6,
            categoryName = "Lakhatás",
            categoryColor = "#dc2626",
            categoryIconSlot = 2,
            recurringTransactionId = 9,
            transactionId = 26051501,
            amount = 120000.0,
            triggerDate = "2026-05-15T00:00:00.000",
            nextDueDate = "2026-06-15T00:00:00.000",
            createdAt = 1778803200000,
            updatedAt = 1778803200000,
        )

        val map = row.toMap()

        assertEquals("recurring_transaction_alert", map["type"])
        assertEquals("Lakhatás", map["categoryName"])
        assertEquals(120000.0, map["amount"])
        assertFalse(map["isRead"] as Boolean)
    }
}
