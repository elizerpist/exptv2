package com.exptv2.app

import android.content.Context

class NotificationParserRuleStore(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences(
        "pushparser_settings",
        Context.MODE_PRIVATE,
    )

    fun load(): Map<String, Any?> = mapOf(
        "enabled" to prefs.getBoolean(KEY_ENABLED, true),
        "sampleText" to prefs.getString(KEY_SAMPLE_TEXT, DEFAULT_SAMPLE_TEXT).orEmpty(),
        "includeKeyword" to prefs.getString(KEY_INCLUDE_KEYWORD, DEFAULT_INCLUDE_KEYWORD).orEmpty(),
        "amountPattern" to prefs.getString(KEY_AMOUNT_PATTERN, DEFAULT_AMOUNT_PATTERN).orEmpty(),
        "merchantPattern" to prefs.getString(KEY_MERCHANT_PATTERN, DEFAULT_MERCHANT_PATTERN).orEmpty(),
    )

    fun save(args: Map<*, *>): Map<String, Any?> {
        val current = load()
        val enabled = args["enabled"] as? Boolean ?: current["enabled"] as Boolean
        val sampleText = args["sampleText"]?.toString() ?: current["sampleText"].orEmptyString()
        val includeKeyword = args["includeKeyword"]?.toString()
            ?: current["includeKeyword"].orEmptyString()
        val amountPattern = args["amountPattern"]?.toString()
            ?: current["amountPattern"].orEmptyString()
        val merchantPattern = args["merchantPattern"]?.toString()
            ?: current["merchantPattern"].orEmptyString()

        prefs.edit()
            .putBoolean(KEY_ENABLED, enabled)
            .putString(KEY_SAMPLE_TEXT, sampleText)
            .putString(KEY_INCLUDE_KEYWORD, includeKeyword)
            .putString(KEY_AMOUNT_PATTERN, amountPattern)
            .putString(KEY_MERCHANT_PATTERN, merchantPattern)
            .apply()
        return load()
    }

    private fun Any?.orEmptyString(): String = this?.toString().orEmpty()

    companion object {
        private const val KEY_ENABLED = "parser_enabled"
        private const val KEY_SAMPLE_TEXT = "parser_sample_text"
        private const val KEY_INCLUDE_KEYWORD = "parser_include_keyword"
        private const val KEY_AMOUNT_PATTERN = "parser_amount_pattern"
        private const val KEY_MERCHANT_PATTERN = "parser_merchant_pattern"

        private const val DEFAULT_SAMPLE_TEXT = "🍽️ 1\u00A0085\u00A0Ft összeget fizettél itt: Csepp Bu:fe'.\n" +
            "A(z) HUF Zseb egyenlege: 71\u00A0795,87\u00A0Ft."
        private const val DEFAULT_INCLUDE_KEYWORD = "fizettél"
        private const val DEFAULT_AMOUNT_PATTERN = "(?<amount>\\d[\\d\\s.,]*)(?:\\s*(?:Ft|HUF))"
        private const val DEFAULT_MERCHANT_PATTERN = "itt:\\s*(?<merchant>.+?)(?:\\.|$)"
    }
}
