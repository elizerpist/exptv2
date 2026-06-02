package com.exptv2.app

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

class NotificationParserRuleStore(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences(
        "pushparser_settings",
        Context.MODE_PRIVATE,
    )

    fun loadProfiles(): Map<String, Any?> = mapOf(
        "profiles" to loadProfileRows(),
    )

    fun saveProfiles(args: Map<*, *>): Map<String, Any?> {
        val rows = args["profiles"] as? List<*> ?: emptyList<Any?>()
        val json = JSONArray()
        rows.forEach { row ->
            if (row is Map<*, *>) json.put(JSONObject(row.toStringMap()))
        }
        prefs.edit().putString(KEY_PROFILES_JSON, json.toString()).apply()
        return loadProfiles()
    }

    fun load(): Map<String, Any?> = loadProfileRows().firstOrNull()?.let { row ->
        mapOf(
            "enabled" to (row["enabled"] as? Boolean ?: true),
            "sampleText" to row["sampleText"].orEmptyString(),
            "includeKeyword" to row["includeKeyword"].orEmptyString(),
            "amountPattern" to row["amountPattern"].orEmptyString(),
            "merchantPattern" to row["merchantPattern"].orEmptyString(),
            "amountSelection" to row["amountSelection"].orEmptyString(),
            "transactionType" to row["transactionType"].orExpenseType(),
            "merchantSelection" to row["merchantSelection"].orEmptyString(),
        )
    } ?: defaultProfile()

    fun save(args: Map<*, *>): Map<String, Any?> {
        val current = loadProfileRows().firstOrNull() ?: defaultProfile()
        val row = current.toMutableMap().apply {
            put("enabled", args["enabled"] as? Boolean ?: current["enabled"] as Boolean)
            put("sampleText", args["sampleText"]?.toString() ?: current["sampleText"].orEmptyString())
            put("includeKeyword", args["includeKeyword"]?.toString() ?: current["includeKeyword"].orEmptyString())
            put("amountPattern", args["amountPattern"]?.toString() ?: current["amountPattern"].orEmptyString())
            put("merchantPattern", args["merchantPattern"]?.toString() ?: current["merchantPattern"].orEmptyString())
            put("amountSelection", args["amountSelection"]?.toString() ?: current["amountSelection"].orEmptyString())
            put("transactionType", args["transactionType"]?.toString()?.toExpenseType() ?: current["transactionType"].orExpenseType())
            put("merchantSelection", args["merchantSelection"]?.toString() ?: current["merchantSelection"].orEmptyString())
        }
        saveProfiles(mapOf("profiles" to listOf(row)))
        return load()
    }

    private fun loadProfileRows(): List<Map<String, Any?>> {
        val stored = prefs.getString(KEY_PROFILES_JSON, null)
        if (!stored.isNullOrBlank()) {
            return runCatching {
                val json = JSONArray(stored)
                List(json.length()) { index -> json.getJSONObject(index).toMap() }
                    .ifEmpty { listOf(defaultProfile()) }
            }.getOrDefault(listOf(defaultProfile()))
        }
        return listOf(defaultProfile())
    }

    private fun defaultProfile(): Map<String, Any?> = mapOf(
        "id" to "profile-1",
        "name" to "Profil",
        "enabled" to prefs.getBoolean(KEY_ENABLED, true),
        "appFilterText" to "",
        "packageName" to "",
        "appLabel" to "",
        "sampleText" to prefs.getString(KEY_SAMPLE_TEXT, DEFAULT_SAMPLE_TEXT).orEmpty(),
        "includeKeyword" to prefs.getString(KEY_INCLUDE_KEYWORD, DEFAULT_INCLUDE_KEYWORD).orEmpty(),
        "amountPattern" to prefs.getString(KEY_AMOUNT_PATTERN, DEFAULT_AMOUNT_PATTERN).orEmpty(),
        "merchantPattern" to prefs.getString(KEY_MERCHANT_PATTERN, DEFAULT_MERCHANT_PATTERN).orEmpty(),
        "amountSelection" to prefs.getString(KEY_AMOUNT_SELECTION, "").orEmpty(),
        "transactionType" to prefs.getString(KEY_TRANSACTION_TYPE, DEFAULT_TRANSACTION_TYPE).orExpenseType(),
        "merchantSelection" to prefs.getString(KEY_MERCHANT_SELECTION, "").orEmpty(),
    )

    private fun Map<*, *>.toStringMap(): Map<String, Any?> = entries.associate { entry ->
        entry.key.toString() to entry.value
    }

    private fun JSONObject.toMap(): Map<String, Any?> {
        val row = mutableMapOf<String, Any?>()
        keys().forEach { key ->
            row[key] = when (val value = get(key)) {
                JSONObject.NULL -> null
                else -> value
            }
        }
        return row
    }

    private fun Any?.orEmptyString(): String = this?.toString().orEmpty()

    private fun Any?.orExpenseType(): String = this?.toString().toExpenseType()

    private fun String?.toExpenseType(): String = when (this?.trim()?.lowercase()) {
        "income", "bevétel" -> "income"
        else -> "expense"
    }

    companion object {
        private const val KEY_PROFILES_JSON = "parser_profiles_json"
        private const val KEY_ENABLED = "parser_enabled"
        private const val KEY_SAMPLE_TEXT = "parser_sample_text"
        private const val KEY_INCLUDE_KEYWORD = "parser_include_keyword"
        private const val KEY_AMOUNT_PATTERN = "parser_amount_pattern"
        private const val KEY_MERCHANT_PATTERN = "parser_merchant_pattern"
        private const val KEY_AMOUNT_SELECTION = "parser_amount_selection"
        private const val KEY_MERCHANT_SELECTION = "parser_merchant_selection"
        private const val KEY_TRANSACTION_TYPE = "parser_transaction_type"

        private const val DEFAULT_SAMPLE_TEXT = "🍽️ 1\u00A0085\u00A0Ft összeget fizettél itt: Csepp Bu:fe'.\n" +
            "A(z) HUF Zseb egyenlege: 71\u00A0795,87\u00A0Ft."
        private const val DEFAULT_INCLUDE_KEYWORD = "fizettél"
        private const val DEFAULT_AMOUNT_PATTERN = "(?<amount>\\d[\\d\\s.,]*)(?:\\s*(?:Ft|HUF))"
        private const val DEFAULT_MERCHANT_PATTERN = "itt:\\s*(?<merchant>.+?)(?:\\.|$)"
        private const val DEFAULT_TRANSACTION_TYPE = "expense"
    }
}
