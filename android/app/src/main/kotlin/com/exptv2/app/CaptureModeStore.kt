package com.exptv2.app

import android.content.Context

class CaptureModeStore(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences(
        "pushparser_settings",
        Context.MODE_PRIVATE,
    )

    fun getMode(): CaptureMode = CaptureMode.fromValue(
        prefs.getString(KEY_MODE, CaptureMode.BOTH.value),
    )

    fun setMode(mode: CaptureMode) {
        prefs.edit().putString(KEY_MODE, mode.value).apply()
    }

    companion object {
        private const val KEY_MODE = "capture_mode"
    }
}
