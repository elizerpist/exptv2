package com.exptv2.app.expense

data class PushRecurringParseResult(
    val amount: Double?,
    val merchant: String?,
    val error: String?,
)

object PushRecurringParser {
    fun parse(
        text: String,
        amountPattern: String,
        merchantPattern: String,
        includeKeyword: String,
    ): PushRecurringParseResult {
        val normalized = normalize(text)
        val keyword = normalize(includeKeyword)
        if (keyword.isNotEmpty() && !normalized.contains(keyword, ignoreCase = true)) {
            return PushRecurringParseResult(null, null, "keyword_missing")
        }
        val amountRegex = runCatching { Regex(amountPattern, RegexOption.IGNORE_CASE) }
            .getOrElse { return PushRecurringParseResult(null, null, "amount_regex_invalid") }
        val merchantRegex = runCatching { Regex(merchantPattern, RegexOption.IGNORE_CASE) }
            .getOrElse { return PushRecurringParseResult(null, null, "merchant_regex_invalid") }
        val amountText = capture(amountRegex.find(normalized), "amount")
        val merchant = capture(merchantRegex.find(normalized), "merchant")?.trim()
        val amount = parseAmount(amountText)
        return when {
            amount == null -> PushRecurringParseResult(null, merchant, "amount_missing")
            merchant.isNullOrBlank() -> PushRecurringParseResult(amount, null, "merchant_missing")
            else -> PushRecurringParseResult(amount, merchant, null)
        }
    }

    private fun normalize(value: String): String = value
        .replace('\u00A0', ' ')
        .replace('\u202F', ' ')
        .replace(Regex("\\s+"), " ")
        .trim()

    private fun capture(match: MatchResult?, name: String): String? {
        if (match == null) return null
        val named = (match.groups as? MatchNamedGroupCollection)?.get(name)?.value
        return named
            ?: if (match.groups.size > 1) match.groups[1]?.value else null
            ?: match.value
    }

    private fun parseAmount(raw: String?): Double? {
        if (raw == null) return null
        var cleaned = normalize(raw).replace(Regex("[^0-9,.]"), "")
        if (cleaned.isBlank()) return null
        val hasComma = cleaned.contains(',')
        val hasDot = cleaned.contains('.')
        cleaned = when {
            hasComma && hasDot -> cleaned.replace(".", "").replace(',', '.')
            hasDot && Regex("^\\d{1,3}(\\.\\d{3})+$").matches(cleaned) -> cleaned.replace(".", "")
            hasComma -> cleaned.replace(',', '.')
            else -> cleaned
        }
        return cleaned.toDoubleOrNull()
    }
}
