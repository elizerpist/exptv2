package com.exptv2.app.expense

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class RecurringRuleInstanceEntityTest {
    @Test
    fun pendingInstanceMapsToLegacyGhostShapeForExistingDartUi() {
        val row = RecurringRuleInstanceEntity(
            id = 42,
            ruleId = 7,
            periodKey = "2026-06",
            status = RecurringRuleInstanceStatus.PENDING,
            estimatedDate = "2026.06.18",
            estimatedTime = "20:15",
            estimatedAmount = 28500.0,
            triggerTypeSnapshot = RecurringTriggerType.PUSH,
            transactionTypeSnapshot = "expense",
            nameSnapshot = "Gázszámla",
            categoryIdSnapshot = 6,
            categoryNameSnapshot = "Rezsi",
            categoryColorSnapshot = "#22c55e",
            categoryIconSlotSnapshot = 3,
            activatedTransactionId = null,
            activatedAt = null,
            matchedNotificationEventId = null,
            matchConfidence = null,
            createdAt = 1000L,
            updatedAt = 2000L,
        )

        val map = row.toLegacyGhostMap()

        assertEquals(42, map["id"])
        assertEquals(7, map["recurringTransactionId"])
        assertEquals("2026-06", map["periodKey"])
        assertEquals("Gázszámla", map["name"])
        assertEquals(28500.0, map["amount"])
        assertEquals(RecurringTriggerType.PUSH, map["triggerTypeSnapshot"])
        assertEquals("expense", map["transactionType"])
        assertEquals("2026.06.18", map["date"])
        assertEquals("20:15", map["estimatedTime"])
        assertEquals("20:15", map["time"])
        assertEquals(6, map["categoryId"])
        assertEquals(false, map["isActivated"])
        assertTrue((map["triggerMillis"] as Long) > 0L)
    }
}
