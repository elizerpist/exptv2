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
            "backheaderStyle" to prefs.getString(KEY_BACKHEADER_STYLE, "classic"),
        )
    }

    fun updateThemeSettings(args: Map<*, *>): Map<String, Any?> {
        prefs.edit()
            .putString(KEY_MAGNET_TYPE, args["magnetType"]?.toString() ?: "fade")
            .putString(KEY_CARD_COLOR, args["cardColor"]?.toString() ?: "lightgray")
            .putString(KEY_THEME, args["theme"]?.toString() ?: "Türkiz")
            .putString(KEY_BACKGROUND_COLOR, args["backgroundColor"]?.toString() ?: "gray")
            .putString(KEY_BOX_COLOR, args["boxColor"]?.toString() ?: "gray")
            .putString(KEY_BACKHEADER_STYLE, args["backheaderStyle"]?.toString() ?: "classic")
            .apply()
        return loadThemeSettings()
    }

    fun loadFastInfoConfig(): Map<String, Any?> {
        val raw = prefs.getString(KEY_FAST_INFO, null) ?: return defaultFastInfoConfig()
        return runCatching { jsonObjectToMap(JSONObject(raw)) }.getOrDefault(defaultFastInfoConfig())
    }

    fun updateFastInfoConfig(args: Map<*, *>): Map<String, Any?> {
        val normalized = ExpenseFastInfoConfigNormalizer.normalize(args)
        prefs.edit().putString(KEY_FAST_INFO, JSONObject(normalized).toString()).apply()
        return normalized
    }

    private fun defaultFastInfoConfig(): Map<String, Any?> = ExpenseFastInfoConfigNormalizer.defaultConfig()

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
        private const val KEY_BACKHEADER_STYLE = "backheaderStyle"
        private const val KEY_FAST_INFO = "fastInfoConfig"
    }
}
