package com.exptv2.app.expense

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

class ExpenseSettingsStore(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences("expense_settings", Context.MODE_PRIVATE)

    fun loadSettings(): Map<String, Any?> = mapOf(
        "themeSettings" to loadThemeSettings(),
        "fastInfoConfig" to loadFastInfoConfig(),
    )

    fun loadThemeSettings(): Map<String, Any?> {
        return mapOf(
            "magnetType" to prefs.getString(KEY_MAGNET_TYPE, "fade"),
            "cardColor" to prefs.getString(KEY_CARD_COLOR, "lightgray"),
            "theme" to prefs.getString(KEY_THEME, "Türkiz"),
            "backgroundColor" to prefs.getString(KEY_BACKGROUND_COLOR, "gray"),
            "boxColor" to prefs.getString(KEY_BOX_COLOR, "gray"),
        )
    }

    fun updateThemeSettings(args: Map<*, *>): Map<String, Any?> {
        prefs.edit()
            .putString(KEY_MAGNET_TYPE, args["magnetType"]?.toString() ?: "fade")
            .putString(KEY_CARD_COLOR, args["cardColor"]?.toString() ?: "lightgray")
            .putString(KEY_THEME, args["theme"]?.toString() ?: "Türkiz")
            .putString(KEY_BACKGROUND_COLOR, args["backgroundColor"]?.toString() ?: "gray")
            .putString(KEY_BOX_COLOR, args["boxColor"]?.toString() ?: "gray")
            .apply()
        return loadThemeSettings()
    }

    fun loadFastInfoConfig(): Map<String, Any?> {
        val raw = prefs.getString(KEY_FAST_INFO, null) ?: return defaultFastInfoConfig()
        return runCatching { jsonObjectToMap(JSONObject(raw)) }.getOrDefault(defaultFastInfoConfig())
    }

    fun updateFastInfoConfig(args: Map<*, *>): Map<String, Any?> {
        val normalized = mapOf(
            "pills" to fixedSlots(args["pills"]),
            "boxes" to fixedSlots(args["boxes"]),
        )
        prefs.edit().putString(KEY_FAST_INFO, JSONObject(normalized).toString()).apply()
        return normalized
    }

    private fun fixedSlots(value: Any?): List<Any?> {
        val raw = value as? List<*> ?: emptyList<Any?>()
        val slots = raw.take(3).map { item ->
            when (item) {
                is Map<*, *> -> item.entries.associate { it.key.toString() to it.value }
                else -> null
            }
        }.toMutableList<Any?>()
        while (slots.size < 3) slots.add(null)
        return slots
    }

    private fun defaultFastInfoConfig(): Map<String, Any?> = mapOf(
        "pills" to listOf(
            mapOf("id" to "havi_koltes", "label" to "Havi költés", "value" to "184k", "type" to "pill", "pillValue" to "184k", "boxValue" to "184k / 250k", "boxSubtitle" to "A havi keret 74%-a", "progress" to 0.74, "visualType" to "progress"),
            mapOf("id" to "mai_maradek_keret", "label" to "Mai maradék keret", "value" to "8.5k", "type" to "pill", "pillValue" to "8.5k", "boxValue" to "8 500 Ft", "boxSubtitle" to "Mai ajánlott keretből", "progress" to 0.68, "visualType" to "progress"),
            mapOf("id" to "koltesi_trend", "label" to "Költési trend", "value" to "+12%", "type" to "pill", "pillValue" to "+12%", "boxValue" to "+12%", "boxSubtitle" to "Az előző időszakhoz képest", "visualType" to "trend"),
        ),
        "boxes" to listOf(
            mapOf("id" to "mai_koltes", "label" to "Mai költés", "value" to "4 500 Ft", "type" to "box", "pillValue" to "4.5k", "boxValue" to "4 500 Ft", "boxSubtitle" to "2 tranzakció ma", "progress" to 0.22, "visualType" to "bar"),
            mapOf("id" to "havi_limit_allapot", "label" to "Havi limit állapot", "value" to "184k / 250k", "type" to "box", "pillValue" to "74%", "boxValue" to "184k / 250k", "boxSubtitle" to "66k maradt", "progress" to 0.74, "visualType" to "progress"),
            mapOf("id" to "kovetkezo_ismetlo_kiadas", "label" to "Következő ismétlődő kiadás", "value" to "Lakbér", "type" to "box", "pillValue" to "Lakbér", "boxValue" to "Lakbér", "boxSubtitle" to "3 nap múlva", "visualType" to "status"),
        ),
    )

    private fun jsonObjectToMap(json: JSONObject): Map<String, Any?> {
        return json.keys().asSequence().associateWith { key -> jsonValue(json.get(key)) }
    }

    private fun jsonArrayToList(array: JSONArray): List<Any?> {
        return (0 until array.length()).map { index -> jsonValue(array.get(index)) }
    }

    private fun jsonValue(value: Any?): Any? = when (value) {
        JSONObject.NULL -> null
        is JSONObject -> jsonObjectToMap(value)
        is JSONArray -> jsonArrayToList(value)
        else -> value
    }

    companion object {
        private const val KEY_MAGNET_TYPE = "magnetType"
        private const val KEY_CARD_COLOR = "cardColor"
        private const val KEY_THEME = "theme"
        private const val KEY_BACKGROUND_COLOR = "backgroundColor"
        private const val KEY_BOX_COLOR = "boxColor"
        private const val KEY_FAST_INFO = "fastInfoConfig"
    }
}
