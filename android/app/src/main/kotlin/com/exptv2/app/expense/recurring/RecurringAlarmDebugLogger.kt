package com.exptv2.app.expense.recurring

import android.content.Context
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class RecurringAlarmDebugLogger(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences(
        "recurring_alarm_debug",
        Context.MODE_PRIVATE,
    )
    private val formatter = SimpleDateFormat("HH:mm:ss.SS", Locale.US)

    fun log(message: String) {
        val current = prefs.getStringSet(KEY_ENTRIES, emptySet()).orEmpty()
            .sorted()
            .takeLast(MAX_ENTRIES - 1)
            .toMutableList()
        val sequence = prefs.getInt(KEY_SEQUENCE, 0) + 1
        val entry = "%06d [%s] %s".format(sequence, formatter.format(Date()), message)
        current.add(entry)
        prefs.edit()
            .putInt(KEY_SEQUENCE, sequence)
            .putStringSet(KEY_ENTRIES, current.toSet())
            .apply()
    }

    fun entries(): List<String> {
        return prefs.getStringSet(KEY_ENTRIES, emptySet()).orEmpty()
            .sorted()
            .map { it.substringAfter(' ') }
    }

    fun clear() {
        prefs.edit().remove(KEY_ENTRIES).apply()
    }

    companion object {
        private const val KEY_ENTRIES = "entries"
        private const val KEY_SEQUENCE = "sequence"
        private const val MAX_ENTRIES = 300
    }
}
