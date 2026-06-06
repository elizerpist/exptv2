package com.exptv2.app.expense

import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone
import java.util.concurrent.TimeUnit
import kotlin.math.abs

data class PushRecurringMatchRule(
    val ruleId: Int,
    val instanceId: Int,
    val estimatedDate: String,
    val estimatedAmount: Double,
    val transactionType: String,
    val appFilterText: String,
    val packageName: String,
    val appLabel: String,
    val dateToleranceDays: Int,
    val amountTolerancePercent: Double,
    val amountToleranceMin: Double,
    val merchantSelection: String,
)

data class PushRecurringMatchEvent(
    val notificationEventId: Long,
    val appLabel: String,
    val packageName: String,
    val date: String,
    val amount: Double,
    val merchant: String,
    val transactionType: String,
)

data class PushRecurringMatchScore(
    val instanceId: Int,
    val matches: Boolean,
    val confidence: Double,
)

object PushRecurringMatcher {

    fun score(rule: PushRecurringMatchRule, event: PushRecurringMatchEvent): PushRecurringMatchScore {
        if (rule.transactionType != event.transactionType) return PushRecurringMatchScore(rule.instanceId, false, 0.0)
        if (rule.packageName.isNotBlank() && rule.packageName != event.packageName) {
            return PushRecurringMatchScore(rule.instanceId, false, 0.0)
        }
        val appMatches = rule.appFilterText.isBlank() || runCatching {
            Regex(rule.appFilterText, RegexOption.IGNORE_CASE).containsMatchIn(event.appLabel)
        }.getOrDefault(false)
        if (!appMatches) {
            return PushRecurringMatchScore(rule.instanceId, false, 0.0)
        }
        val days = abs(TimeUnit.MILLISECONDS.toDays(parseDateMillis(event.date) - parseDateMillis(rule.estimatedDate)))
        if (days > rule.dateToleranceDays) return PushRecurringMatchScore(rule.instanceId, false, 0.0)
        val allowedAmountDelta = maxOf(rule.estimatedAmount * rule.amountTolerancePercent / 100.0, rule.amountToleranceMin)
        val amountDelta = abs(rule.estimatedAmount - event.amount)
        if (amountDelta > allowedAmountDelta) return PushRecurringMatchScore(rule.instanceId, false, 0.0)
        val merchantScore = merchantScore(rule.merchantSelection, event.merchant)
        if (merchantScore == null) return PushRecurringMatchScore(rule.instanceId, false, 0.0)
        val dateScore = 1.0 - (days.toDouble() / rule.dateToleranceDays.coerceAtLeast(1).toDouble() * 0.2)
        val amountScore = if (allowedAmountDelta <= 0.0) {
            1.0
        } else 1.0 - (amountDelta / allowedAmountDelta * 0.2)
        return PushRecurringMatchScore(
            instanceId = rule.instanceId,
            matches = true,
            confidence = ((dateScore + amountScore + merchantScore) / 3.0).coerceIn(0.0, 1.0),
        )
    }

    private fun merchantScore(expected: String, actual: String): Double? {
        val expectedText = normalize(expected)
        if (expectedText.isEmpty()) return 1.0
        val actualText = normalize(actual)
        if (actualText == expectedText) return 1.0
        if (actualText.contains(expectedText) || expectedText.contains(actualText)) return 0.9
        return null
    }

    private fun normalize(value: String): String = value
        .replace('\u00A0', ' ')
        .replace('\u202F', ' ')
        .replace(Regex("\\s+"), " ")
        .trim()
        .lowercase(Locale.ROOT)

    private fun parseDateMillis(date: String): Long {
        return SimpleDateFormat("yyyy.MM.dd", Locale.US).apply {
            isLenient = false
            timeZone = TimeZone.getTimeZone("UTC")
        }.parse(date)?.time ?: throw IllegalArgumentException("Invalid date: $date")
    }
}
