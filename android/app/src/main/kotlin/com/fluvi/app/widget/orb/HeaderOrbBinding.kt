package com.fluvi.app.widget.orb

import android.app.Activity
import android.app.KeyguardManager
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProviderInfo
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.database.ContentObserver
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.provider.Settings
import android.util.AtomicFile
import android.util.Log
import com.fluvi.wa.OrbPlacement
import com.fluvi.wa.WaOrbHost
import com.fluvi.wa.WaOrbStyle
import org.json.JSONArray
import java.io.File
import java.util.UUID

/** Main owns service consent and the one fixed widget binding. Safe snapshots go to the frame queue. */
internal class HeaderOrbBinding private constructor(private val context: Context) {
    private val main = Handler(Looper.getMainLooper())
    private val prefs = context.getSharedPreferences("fluvi_balance_orb", Context.MODE_PRIVATE)
    private val widgetManager = AppWidgetManager.getInstance(context)
    private val provider = ComponentName(context, FluviHeaderOrbWidgetProvider::class.java)
    private val service = ComponentName(context.packageName, "tk.zwander.lockscreenwidgets.services.Accessibility")
    val host = WaOrbHost.get(context)
    private val listeners = mutableSetOf<() -> Unit>()
    private var enabled = serviceEnabled()
    private var intended = prefs.getBoolean("intended", true)
    private var sizeDp = prefs.getInt("sizeDp", 56)
    private var active = prefs.getInt("active", INVALID)
    private var pending = prefs.getInt("pending", INVALID)
    private var pendingCode = prefs.getInt("pendingCode", 0)
    private var autoBind = prefs.getBoolean("autoBind", true)
    private var epoch = prefs.getString("epoch", null) ?: UUID.randomUUID().toString()
    private var ready = false
    private var connection = 0L

    data class Authority(val epoch: String, val id: Int)

    @Volatile
    var authority: Authority? = null
        private set

    init {
        migrate()
        if (prefs.getBoolean("enabled", false) && !enabled) revoke()
        else {
            reconcile()
            persist()
            publishState()
        }
        context.contentResolver.registerContentObserver(
            Settings.Secure.getUriFor(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES),
            false,
            object : ContentObserver(main) {
                override fun onChange(selfChange: Boolean) = syncService()
            },
        )
    }

    private fun migrate() {
        if (prefs.getBoolean("migrated", false)) return
        val legacy = context.getSharedPreferences("${context.packageName}_preferences", Context.MODE_PRIVATE)
        val sharing = File(context.noBackupFilesDir, "header-orb-sharing-v1")
        if (legacy.contains("widget_frame_enabled") || legacy.contains("current_widgets") || sharing.exists()) {
            intended = legacy.getBoolean("widget_frame_enabled", false) && sharing.isFile
            // Intersect migration records with OS-owned host 1003 IDs. Never touch other hosts
            // or records from the obsolete drawer and secondary frames.
            val recorded = runCatching {
                val array = JSONArray(legacy.getString("current_widgets", "[]") ?: "[]")
                (0 until array.length()).mapNotNull { index ->
                    array.optJSONObject(index)?.takeIf {
                        it.isNull("type") || it.optString("type") == "WIDGET"
                    }?.optInt("id", INVALID)
                }.filter { it != INVALID }.distinct()
            }.getOrDefault(emptyList())
            val owned = recorded.filter(::owned)
            active = owned.firstOrNull { binding(it) != null } ?: INVALID
            persist()
            owned.filter { it != active }.forEach(::deleteOwned)
            Log.i(TAG, "migrated active=$active intent=$intended obsolete=${owned.count { it != active }}")
        }
        AtomicFile(File(context.noBackupFilesDir, "header-orb-frames-v1")).delete()
        sharing.delete()
        prefs.edit().putBoolean("migrated", true).commit()
    }

    private fun persist() {
        check(prefs.edit()
            .putBoolean("enabled", enabled).putBoolean("intended", intended).putBoolean("autoBind", autoBind)
            .putInt("sizeDp", sizeDp).putInt("active", active).putInt("pending", pending)
            .putInt("pendingCode", pendingCode).putString("epoch", epoch).commit())
    }

    private fun serviceEnabled(): Boolean = Settings.Secure.getString(
        context.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
    ).orEmpty().split(':').any { ComponentName.unflattenFromString(it) == service }

    fun syncService() {
        val now = serviceEnabled()
        if (now == enabled) return
        enabled = now
        if (!enabled) revoke()
        else {
            autoBind = true
            reconcile()
            persist()
            publishState()
        }
    }

    fun connected() {
        syncService()
        connection++
        notifyChanged()
    }

    private fun revoke() {
        val previous = active
        // Immediately close authority before invalidating queued frame work.
        authority = null
        ready = false
        epoch = UUID.randomUUID().toString()
        if (pending != INVALID) abandonPending()
        autoBind = true
        persist()
        HeaderOrbWidgetContent.execute { HeaderOrbWidgetContent.revoke(context, previous) }
        notifyChanged()
    }

    fun observe(listener: () -> Unit): () -> Unit {
        listeners += listener
        listener()
        return { listeners -= listener }
    }

    private fun notifyChanged() = listeners.toList().forEach { it() }

    private fun publishState() {
        val previous = authority
        val current = Authority(epoch, active).takeIf { enabled && intended && active != INVALID }
        authority = current
        if (previous != current) {
            ready = false
            if (current != null) {
                HeaderOrbWidgetContent.execute { HeaderOrbWidgetContent.refresh(context, this) }
            }
        }
        notifyChanged()
    }

    fun markReady(owner: Authority, value: Boolean) {
        main.post {
            if (authority == owner && value != ready) {
                ready = value
                notifyChanged()
            }
        }
    }

    fun readyId(): Int? = authority?.id?.takeIf { ready }
    fun sizeDp(): Int = sizeDp

    fun style(dp: Int): WaOrbStyle {
        val stored = prefs.getString(styleKey(dp), null)
        return WaOrbStyle.entries.firstOrNull { it.value == stored } ?: WaOrbStyle.ORB
    }

    fun selectStyle(dp: Int, style: WaOrbStyle) {
        val key = styleKey(dp)
        if (style(dp) == style) return
        check(prefs.edit().putString(key, style.value).commit())
        notifyChanged()
    }

    private fun styleKey(dp: Int): String {
        require(dp == 56 || dp == 112)
        return "style$dp"
    }

    fun placement(): OrbPlacement = OrbPlacement(
        prefs.getFloat("centerX", 0.5f), prefs.getFloat("centerY", 0.5f),
    )

    fun savePlacement(center: OrbPlacement) {
        prefs.edit().putFloat("centerX", center.x).putFloat("centerY", center.y).apply()
    }

    fun status(): Map<String, Any> = mapOf(
        "accessibilityEnabled" to enabled,
        "sizeDp" to sizeDp,
        "style56" to style(56).value,
        "style112" to style(112).value,
        "state" to when {
            !enabled -> "disabled"
            !intended -> "dormant"
            pending != INVALID -> "pendingBind"
            active == INVALID -> "needsBind"
            ready -> "ready"
            else -> "waitingForHeader"
        },
        "epoch" to (authority?.epoch ?: ""),
        "connection" to connection,
    )

    fun openAccessibility(activity: Activity) {
        activity.startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
    }

    fun settingsResumed(activity: Activity, resumed: Boolean) {
        syncService()
        if (reconcile()) {
            persist()
            publishState()
        }
        if (enabled && intended && autoBind) maybeBind(activity, resumed)
    }

    fun selectSize(activity: Activity, resumed: Boolean, dp: Int) {
        require(dp == 56 || dp == 112)
        syncService()
        sizeDp = dp
        intended = true
        if (pending != INVALID && binding(pending) == null && resumed && unlocked(activity)) abandonPending()
        reconcile()
        persist()
        publishState()
        if (active != INVALID) {
            try {
                widgetManager.updateAppWidgetOptions(active, WaOrbHost.options(sizeDp))
            } catch (error: RuntimeException) {
                Log.w(TAG, "size options deferred: ${error.javaClass.simpleName}")
            }
        }
        if (enabled) maybeBind(activity, resumed)
    }

    private fun unlocked(activity: Activity): Boolean =
        !activity.getSystemService(KeyguardManager::class.java).isKeyguardLocked

    @Suppress("DEPRECATION")
    private fun maybeBind(activity: Activity, resumed: Boolean) {
        if (!resumed || !unlocked(activity) || activity.isFinishing || active != INVALID || pending != INVALID) return
        pending = host.allocateAppWidgetId()
        val previousCode = prefs.getInt("lastRequestCode", 23000)
        pendingCode = if (previousCode in 23000..23998) previousCode + 1 else 23000
        prefs.edit().putInt("lastRequestCode", pendingCode).apply()
        autoBind = false
        persist()
        val options = WaOrbHost.options(sizeDp)
        try {
            if (widgetManager.bindAppWidgetIdIfAllowed(pending, Process.myUserHandle(), provider, options)) {
                check(reconcile())
                persist()
                publishState()
                return
            }
            activity.startActivityForResult(Intent(AppWidgetManager.ACTION_APPWIDGET_BIND).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, pending)
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_PROVIDER, provider)
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_PROVIDER_PROFILE, Process.myUserHandle())
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_OPTIONS, options)
            }, pendingCode)
            notifyChanged()
        } catch (error: RuntimeException) {
            abandonPending()
            persist()
            publishState()
            throw error
        }
    }

    fun bindResult(requestCode: Int, result: Int, data: Intent?) {
        syncService()
        if (requestCode != pendingCode || pending == INVALID) return
        val returned = data?.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, pending) ?: pending
        if (result != Activity.RESULT_OK || returned != pending || !enabled || !intended || !reconcile()) {
            abandonPending()
        }
        persist()
        publishState()
    }

    /** Recover the very same allocated ID when the framework already recorded a completed grant. */
    private fun reconcile(): Boolean {
        var changed = false
        if (active != INVALID && binding(active) == null) {
            active = INVALID
            epoch = UUID.randomUUID().toString()
            changed = true
        }
        if (enabled && intended && pending != INVALID && binding(pending) != null) {
            active = pending
            pending = INVALID
            pendingCode = 0
            changed = true
            Log.i(TAG, "bound host=${WaOrbHost.HOST_ID} id=$active")
        }
        return changed
    }

    fun binding(id: Int): AppWidgetProviderInfo? =
        if (id == INVALID || !owned(id)) null else widgetManager.getAppWidgetInfo(id)?.takeIf {
            it.provider == provider && it.profile == Process.myUserHandle()
        }

    private fun owned(id: Int): Boolean = id != INVALID && if (Build.VERSION.SDK_INT >= 26) {
        id in host.appWidgetIds
    } else {
        id == active || id == pending
    }

    private fun deleteOwned(id: Int) {
        if (owned(id)) host.deleteAppWidgetId(id)
    }

    private fun abandonPending() {
        if (pending != INVALID) host.deleteAppWidgetId(pending)
        pending = INVALID
        pendingCode = 0
    }

    companion object {
        private const val TAG = "FluviBalanceOrb"
        private const val INVALID = AppWidgetManager.INVALID_APPWIDGET_ID
        private var instance: HeaderOrbBinding? = null

        fun get(context: Context): HeaderOrbBinding =
            instance ?: HeaderOrbBinding(context.applicationContext).also { instance = it }
    }
}
