package com.exptv2.app.expense.recurring

import android.content.Context

class RecurringDebugClockStore(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences(
        "recurring_debug_clock",
        Context.MODE_PRIVATE,
    )

    fun effectiveNow(realNow: Long = System.currentTimeMillis()): Long {
        return prefs.getLong(KEY_OVERRIDE_MILLIS, 0L).takeIf { it > 0L } ?: realNow
    }

    fun setOverride(targetMillis: Long): Long {
        val normalized = RecurringDebugClockNormalizer.normalizeToTriggerMillis(targetMillis)
        prefs.edit().putLong(KEY_OVERRIDE_MILLIS, normalized).apply()
        return normalized
    }

    fun clearOverride() {
        prefs.edit().remove(KEY_OVERRIDE_MILLIS).apply()
    }

    fun state(realNow: Long = System.currentTimeMillis()): Map<String, Any?> {
        val override = prefs.getLong(KEY_OVERRIDE_MILLIS, 0L).takeIf { it > 0L }
        return mapOf(
            "overrideMillis" to override,
            "effectiveMillis" to (override ?: realNow),
            "usingOverride" to (override != null),
        )
    }

    companion object {
        private const val KEY_OVERRIDE_MILLIS = "override_millis"
    }
}
