package tk.zwander.lockscreenwidgets

import android.content.Context
import androidx.preference.PreferenceManager
import tk.zwander.common.util.PrefManager

/** The stock frame and first-view tutorial still require normal onboarding. */
internal fun installFluviHostDefaults(context: Context) {
    val prefs = PreferenceManager.getDefaultSharedPreferences(context)
    val installedKey = "fluvi_wa_defaults_v1"
    if (prefs.getBoolean(installedKey, false)) return

    val required = mapOf(
        PrefManager.KEY_HIDE_ON_SECURITY_PAGE to true,
        PrefManager.KEY_HIDE_ON_NOTIFICATION_SHADE to true,
        PrefManager.KEY_SHOW_ON_MAIN_LOCK_SCREEN to true,
        PrefManager.KEY_SHOW_IN_NOTIFICATION_CENTER to false,
        PrefManager.KEY_FORCE_SHOW_FRAME to false,
    )
    val frame = context.getSharedPreferences("frame_prefs_-1", Context.MODE_PRIVATE)
    val frameEditor = frame.edit()
    required.forEach { (key, value) -> frameEditor.putBoolean(key, value) }
    check(frameEditor.commit())

    val editor = prefs.edit()
    required.forEach { (key, value) -> editor.putBoolean(key, value) }
    check(editor
        .putBoolean(PrefManager.KEY_ENABLE_BUGSNAG, false)
        .putBoolean(PrefManager.KEY_WIDGET_FRAME_ENABLED, false)
        .putBoolean(installedKey, true)
        .commit())
}
