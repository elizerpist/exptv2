package com.fluvi.app

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import org.json.JSONArray
import org.json.JSONObject

/**
 * Small, privacy-safe diagnostic ledger for the notification path.
 *
 * It intentionally stores event codes, timestamps and source package names
 * only. Notification bodies, titles, amounts, OTPs and account information
 * never enter this store or its Flutter projection. SharedPreferences keeps a
 * useful history when a listener callback happens while Flutter is absent.
 */
internal object FluviPushDiagnostics {
    private const val PREFERENCES = "fluvi_push_diagnostics"
    private const val EVENTS = "events"
    private const val LISTENER_CONNECTED = "listener_connected"
    private const val LAST_CONNECTED = "last_connected"
    private const val LAST_DISCONNECTED = "last_disconnected"
    private const val APP_LIST_MODE = "app_list_mode"
    private const val APP_LIST_FOUND = "app_list_found"
    private const val APP_LIST_VISIBLE = "app_list_visible"
    private const val APP_LIST_UPDATED = "app_list_updated"
    private const val APP_LIST_ERROR = "app_list_error"
    private const val TEST_ID = "test_id"
    private const val TEST_SOURCE = "test_source"
    private const val TEST_STEP = "test_step"
    private const val TEST_UPDATED = "test_updated"
    private const val TEST_RESULT = "test_result"
    private const val MAX_EVENTS = 80

    @Synchronized
    fun record(
        context: Context,
        code: String,
        message: String,
        sourcePackage: String? = null,
        probeId: String? = null,
    ) {
        val prefs = prefs(context)
        val entries = runCatching { JSONArray(prefs.getString(EVENTS, "[]")) }
            .getOrElse { JSONArray() }
        val item = JSONObject()
            .put("code", code)
            .put("message", message)
            .put("atUtcMs", System.currentTimeMillis())
        if (!sourcePackage.isNullOrBlank()) item.put("sourcePackage", sourcePackage)
        if (!probeId.isNullOrBlank()) item.put("probeId", probeId)
        entries.put(item)
        while (entries.length() > MAX_EVENTS) entries.remove(0)
        prefs.edit().putString(EVENTS, entries.toString()).apply()
        if (probeId != null) noteTest(context, probeId, sourcePackage, code, message)
        FluviAutomationUpdates.publish(mapOf("kind" to "push", "code" to code))
    }

    fun listenerConnected(context: Context) {
        prefs(context).edit()
            .putBoolean(LISTENER_CONNECTED, true)
            .putLong(LAST_CONNECTED, System.currentTimeMillis())
            .apply()
        record(context, "LISTENER_CONNECTED", "A listener csatlakozott.")
    }

    fun listenerDisconnected(context: Context) {
        prefs(context).edit()
            .putBoolean(LISTENER_CONNECTED, false)
            .putLong(LAST_DISCONNECTED, System.currentTimeMillis())
            .apply()
        record(context, "LISTENER_DISCONNECTED", "A listener kapcsolat megszakadt.")
    }

    fun appList(
        context: Context,
        found: Int,
        visible: Int,
        error: String? = null,
    ) {
        prefs(context).edit()
            .putString(APP_LIST_MODE, "getInstalledApplications")
            .putInt(APP_LIST_FOUND, found)
            .putInt(APP_LIST_VISIBLE, visible)
            .putLong(APP_LIST_UPDATED, System.currentTimeMillis())
            .putString(APP_LIST_ERROR, error)
            .apply()
        record(
            context,
            if (error == null) "APP_LIST_READY" else "APP_LIST_ERROR",
            if (error == null) "Telepített alkalmazáslista frissítve." else "Az alkalmazáslista lekérése nem sikerült.",
        )
    }

    fun beginTest(context: Context, probeId: String) {
        prefs(context).edit()
            .putString(TEST_ID, probeId)
            .putString(TEST_SOURCE, context.packageName)
            .putString(TEST_STEP, "TEST_REQUESTED")
            .putLong(TEST_UPDATED, System.currentTimeMillis())
            .putString(TEST_RESULT, "requested")
            .apply()
        record(context, "TEST_REQUESTED", "Saját tesztértesítés kérése elindult.", context.packageName, probeId)
    }

    fun isCurrentOwnTest(context: Context, packageName: String, channelId: String?, text: String): String? {
        if (packageName != context.packageName || channelId != FluviAutomationPlatform.TEST_CHANNEL) return null
        val probeId = prefs(context).getString(TEST_ID, null) ?: return null
        return probeId.takeIf { text.contains(it) }
    }

    fun snapshot(context: Context): Map<String, Any?> {
        val prefs = prefs(context)
        val events = runCatching { JSONArray(prefs.getString(EVENTS, "[]")) }
            .getOrElse { JSONArray() }
        val mappedEvents = buildList<Map<String, Any?>>(events.length()) {
            for (index in 0 until events.length()) {
                val item = events.optJSONObject(index) ?: continue
                add(
                    mapOf(
                        "code" to item.optString("code"),
                        "message" to item.optString("message"),
                        "atUtcMs" to item.optLong("atUtcMs"),
                        "sourcePackage" to item.optString("sourcePackage").ifBlank { null },
                        "probeId" to item.optString("probeId").ifBlank { null },
                    ),
                )
            }
        }.reversed()
        return mapOf(
            "listenerConnected" to prefs.getBoolean(LISTENER_CONNECTED, false),
            "lastConnectedAtUtcMs" to prefs.getLong(LAST_CONNECTED, 0L).takeIf { it > 0L },
            "lastDisconnectedAtUtcMs" to prefs.getLong(LAST_DISCONNECTED, 0L).takeIf { it > 0L },
            "applicationListMode" to (prefs.getString(APP_LIST_MODE, null) ?: "not_requested"),
            "applicationListFound" to prefs.getInt(APP_LIST_FOUND, 0),
            "applicationListVisible" to prefs.getInt(APP_LIST_VISIBLE, 0),
            "applicationListUpdatedAtUtcMs" to prefs.getLong(APP_LIST_UPDATED, 0L).takeIf { it > 0L },
            "applicationListError" to prefs.getString(APP_LIST_ERROR, null),
            "lastTestProbeId" to prefs.getString(TEST_ID, null),
            "lastTestSourcePackage" to prefs.getString(TEST_SOURCE, null),
            "lastTestStep" to prefs.getString(TEST_STEP, null),
            "lastTestAtUtcMs" to prefs.getLong(TEST_UPDATED, 0L).takeIf { it > 0L },
            "lastTestResult" to prefs.getString(TEST_RESULT, null),
            "events" to mappedEvents,
        )
    }

    fun clear(context: Context) {
        prefs(context).edit().remove(EVENTS).apply()
        FluviAutomationUpdates.publish(mapOf("kind" to "push", "code" to "DIAGNOSTICS_CLEARED"))
    }

    private fun noteTest(
        context: Context,
        probeId: String,
        sourcePackage: String?,
        step: String,
        result: String,
    ) {
        prefs(context).edit()
            .putString(TEST_ID, probeId)
            .putString(TEST_SOURCE, sourcePackage ?: context.packageName)
            .putString(TEST_STEP, step)
            .putLong(TEST_UPDATED, System.currentTimeMillis())
            .putString(TEST_RESULT, result)
            .apply()
    }

    private fun prefs(context: Context) = context.applicationContext
        .getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
}

/** A best-effort live wake-up. The persisted diagnostic/core data remains the
 * source of truth if no Flutter listener exists. */
internal object FluviAutomationUpdates {
    private val mainHandler = Handler(Looper.getMainLooper())
    @Volatile private var sink: EventChannel.EventSink? = null

    fun attach(value: EventChannel.EventSink) { sink = value }
    fun detach() { sink = null }
    fun publish(value: Map<String, Any?>) {
        mainHandler.post { sink?.success(value) }
    }
}
