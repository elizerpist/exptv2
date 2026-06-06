package com.exptv2.app.expense

object ExpenseFastInfoConfigNormalizer {
    fun normalize(args: Map<*, *>): Map<String, Any?> = mapOf(
        "layoutMode" to normalizeLayoutMode(args["layoutMode"]),
        "upperRowPresentation" to normalizeRowPresentation(
            args["upperRowPresentation"],
            defaultValue = "pill",
        ),
        "lowerRowPresentation" to normalizeRowPresentation(
            args["lowerRowPresentation"],
            defaultValue = "box",
        ),
        "pills" to fixedSlots(args["pills"]),
        "boxes" to fixedSlots(args["boxes"]),
    )

    fun defaultConfig(): Map<String, Any?> = mapOf(
        "layoutMode" to "mixed",
        "upperRowPresentation" to "pill",
        "lowerRowPresentation" to "box",
        "pills" to listOf(
            mapOf("id" to "megtakaritas", "label" to "Megtakarítás", "value" to "156,780 Ft", "type" to "pill"),
            null,
            null,
        ),
        "boxes" to listOf(
            mapOf("id" to "mai_nap", "label" to "Mai nap", "value" to "2 db", "extra" to "-4,500 Ft", "type" to "box"),
            mapOf("id" to "havi_limit", "label" to "Havi limit", "value" to "180k / 200k", "progress" to 0.9, "type" to "box"),
            mapOf("id" to "trend", "label" to "Trend", "value" to "+12%", "type" to "box"),
        ),
    )

    private fun normalizeLayoutMode(value: Any?): String {
        return if (value?.toString() == "sixBoxes") "sixBoxes" else "mixed"
    }

    private fun normalizeRowPresentation(value: Any?, defaultValue: String): String {
        return when (value?.toString()) {
            "pill" -> "pill"
            "box" -> "box"
            else -> defaultValue
        }
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
}
