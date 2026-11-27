package tk.zwander.lockscreenwidgets

import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import android.database.ContentObserver
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.preference.PreferenceManager
import com.fluvi.app.widget.orb.FluviHeaderOrbWidgetProvider
import tk.zwander.common.util.PrefManager
import tk.zwander.lockscreenwidgets.services.Accessibility
import tk.zwander.lockscreenwidgets.util.WidgetFrameDelegate

private val safeFramePreferences = mapOf(
    PrefManager.KEY_HIDE_ON_SECURITY_PAGE to true,
    PrefManager.KEY_HIDE_ON_NOTIFICATION_SHADE to true,
    PrefManager.KEY_SHOW_ON_MAIN_LOCK_SCREEN to true,
    PrefManager.KEY_SHOW_IN_NOTIFICATION_CENTER to false,
    PrefManager.KEY_FORCE_SHOW_FRAME to false,
)

private var changeListener: SharedPreferences.OnSharedPreferenceChangeListener? = null

/** The original WA onboarding and window policy own the frame and its visibility. */
internal fun installFluviHostDefaults(context: Context) {
    val prefs = PreferenceManager.getDefaultSharedPreferences(context)
    val frame = context.getSharedPreferences("frame_prefs_${WidgetFrameDelegate.ID}", Context.MODE_PRIVATE)
    val installedKey = "fluvi_wa_defaults_v1"
    if (!prefs.getBoolean(installedKey, false)) {
        val frameEditor = frame.edit()
        safeFramePreferences.forEach { (key, value) -> frameEditor.putBoolean(key, value) }
        check(frameEditor.commit())

        val editor = prefs.edit()
        safeFramePreferences.forEach { (key, value) -> editor.putBoolean(key, value) }
        check(editor
            .putBoolean(PrefManager.KEY_ENABLE_BUGSNAG, false)
            .putBoolean(PrefManager.KEY_WIDGET_FRAME_ENABLED, false)
            .putBoolean(installedKey, true)
            .commit())
    }
    // Drop the shared content when the owner disables the native frame or its
    // privacy configuration. The original host still handles the window.
    val listener = SharedPreferences.OnSharedPreferenceChangeListener { changed, key ->
        if (key == null) {
            FluviHeaderOrbWidgetProvider.revokeSharing(context)
            return@OnSharedPreferenceChangeListener
        }
        val disabled = key == PrefManager.KEY_WIDGET_FRAME_ENABLED &&
            !changed.getBoolean(PrefManager.KEY_WIDGET_FRAME_ENABLED, false)
        val unsafe = safeFramePreferences[key]?.let { changed.getBoolean(key, it) != it } ?: false
        if (disabled || unsafe) FluviHeaderOrbWidgetProvider.revokeSharing(context)
    }
    changeListener = listener
    prefs.registerOnSharedPreferenceChangeListener(listener)
    frame.registerOnSharedPreferenceChangeListener(listener)

    val setting = Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
    val component = ComponentName(context, Accessibility::class.java)
    fun granted() = Settings.Secure.getString(context.contentResolver, setting)
        .orEmpty().split(':').any { ComponentName.unflattenFromString(it) == component }

    var wasGranted = granted()
    context.contentResolver.registerContentObserver(
        Settings.Secure.getUriFor(setting), false, object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean) {
                val enabled = granted()
                if (wasGranted && !enabled) FluviHeaderOrbWidgetProvider.revokeSharing(context)
                wasGranted = enabled
            }
        },
    )
}
