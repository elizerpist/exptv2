package com.exptv2.app.expense

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class PushRecurringMatcherTest {
    @Test
    fun scoresMatchingRuleHigherThanOutOfToleranceRule() {
        val rule = PushRecurringMatchRule(
            ruleId = 1,
            instanceId = 10,
            estimatedDate = "2026.06.10",
            estimatedAmount = 120000.0,
            transactionType = "expense",
            appFilterText = "^OTP$",
            packageName = "hu.otpbank.mobile",
            appLabel = "OTP",
            dateToleranceDays = 5,
            amountTolerancePercent = 20.0,
            amountToleranceMin = 5000.0,
            merchantSelection = "OTP Lakashitel",
        )
        val event = PushRecurringMatchEvent(
            notificationEventId = 77,
            appLabel = "OTP",
            packageName = "hu.otpbank.mobile",
            date = "2026.06.12",
            amount = 121550.0,
            merchant = "OTP Lakashitel",
            transactionType = "expense",
        )

        val score = PushRecurringMatcher.score(rule, event)

        assertTrue(score.matches)
        assertTrue(score.confidence >= 0.85)
        assertEquals(10, score.instanceId)
    }

    @Test
    fun invalidAppFilterDoesNotMatch() {
        val rule = PushRecurringMatchRule(
            ruleId = 1,
            instanceId = 10,
            estimatedDate = "2026.06.10",
            estimatedAmount = 120000.0,
            transactionType = "expense",
            appFilterText = "[",
            packageName = "hu.otpbank.mobile",
            appLabel = "OTP",
            dateToleranceDays = 5,
            amountTolerancePercent = 20.0,
            amountToleranceMin = 5000.0,
            merchantSelection = "OTP Lakashitel",
        )
        val event = PushRecurringMatchEvent(
            notificationEventId = 77,
            appLabel = "OTP",
            packageName = "hu.otpbank.mobile",
            date = "2026.06.12",
            amount = 121550.0,
            merchant = "OTP Lakashitel",
            transactionType = "expense",
        )

        val score = PushRecurringMatcher.score(rule, event)

        assertEquals(false, score.matches)
        assertEquals(0.0, score.confidence, 0.0)
    }

    @Test
    fun merchantSelectionRejectsOtherLoanFromSameBank() {
        val rule = PushRecurringMatchRule(
            ruleId = 1,
            instanceId = 10,
            estimatedDate = "2026.06.10",
            estimatedAmount = 120000.0,
            transactionType = "expense",
            appFilterText = "^OTP$",
            packageName = "hu.otpbank.mobile",
            appLabel = "OTP",
            dateToleranceDays = 5,
            amountTolerancePercent = 20.0,
            amountToleranceMin = 5000.0,
            merchantSelection = "OTP Lakashitel A",
        )
        val event = PushRecurringMatchEvent(
            notificationEventId = 77,
            appLabel = "OTP",
            packageName = "hu.otpbank.mobile",
            date = "2026.06.12",
            amount = 121550.0,
            merchant = "OTP Lakashitel B",
            transactionType = "expense",
        )

        val score = PushRecurringMatcher.score(rule, event)

        assertEquals(false, score.matches)
        assertEquals(0.0, score.confidence, 0.0)
    }
}
