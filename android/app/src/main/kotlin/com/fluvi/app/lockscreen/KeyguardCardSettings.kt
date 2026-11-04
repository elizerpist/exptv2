package com.fluvi.app.lockscreen

import android.content.ComponentName
import android.content.Context
import android.provider.Settings

/** Persistent user consent only.  Live service/window facts deliberately do
 * not live here, so a stale setting can never claim physical visibility. */
internal data class KeyguardCardSettings(
    val requested: Boolean = false,
    val showFinancialDetails: Boolean = false,
    val verticalOffsetDp: Int = 0,
    val generation: Long = 0L,
)

internal object FluviKeyguardCardSettings {
    private const val PREFS = "fluvi_native_keyguard_card"
    private const val REQUESTED = "requested"
    private const val DETAILS = "details"
    private const val OFFSET = "verticalOffsetDp"
    private const val GENERATION = "generation"

    fun read(context: Context): KeyguardCardSettings {
        val prefs = prefs(context)
        return KeyguardCardSettings(
            requested = prefs.getBoolean(REQUESTED, false),
            showFinancialDetails = prefs.getBoolean(DETAILS, false),
            verticalOffsetDp = prefs.getInt(OFFSET, 0).coerceIn(-96, 96),
            generation = prefs.getLong(GENERATION, 0L),
        )
    }

    /** Full details can only be persisted from an unlocked Activity. */
    fun update(context: Context, values: Map<*, *>): KeyguardCardSettings {
        val old = read(context)
        val requested = values["requested"] as? Boolean ?: old.requested
        val requestedDetails = values["showFinancialDetails"] as? Boolean ?: old.showFinancialDetails
        val locked = context.getSystemService(android.app.KeyguardManager::class.java)?.isKeyguardLocked == true
        val details = if (requestedDetails && locked) old.showFinancialDetails else requestedDetails
        val offset = (values["verticalOffsetDp"] as? Number)?.toInt()?.coerceIn(-96, 96) ?: old.verticalOffsetDp
        val next = KeyguardCardSettings(requested, details, offset, old.generation + 1L)
        prefs(context).edit()
            .putBoolean(REQUESTED, next.requested)
            .putBoolean(DETAILS, next.showFinancialDetails)
            .putInt(OFFSET, next.verticalOffsetDp)
            .putLong(GENERATION, next.generation)
            .apply()
        FluviKeyguardCardServiceRegistry.notifySettingsChanged(next)
        return next
    }

    fun statusMap(context: Context): Map<String, Any?> {
        val value = read(context)
        return mapOf(
            "requested" to value.requested,
            "showFinancialDetails" to value.showFinancialDetails,
            "verticalOffsetDp" to value.verticalOffsetDp,
            "generation" to value.generation,
            "systemServiceEnabled" to systemServiceEnabled(context),
            "serviceConnected" to FluviKeyguardCardServiceRegistry.connected,
            "lastDecisionReason" to KeyguardCardDiagnostics.lastReason(context),
            "lastAttachResult" to KeyguardCardDiagnostics.lastAttachResult(context),
            "diagnosticSummary" to KeyguardCardDiagnostics.summary(context),
        )
    }

    fun systemServiceEnabled(context: Context): Boolean {
        val component = ComponentName(context, FluviKeyguardCardService::class.java).flattenToString()
        val enabled = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        ) ?: return false
        return enabled.split(':').any { entry ->
            entry.equals(component, ignoreCase = true) ||
                ComponentName.unflattenFromString(entry)?.flattenToString() == component
        }
    }

    internal fun prefs(context: Context) = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}

/** A bounded, technical-only log for diagnostic builds. No node tree, text,
 * financial field, or foreign application identity is ever retained. */
internal object KeyguardCardDiagnostics {
    private const val PREFS = "fluvi_native_keyguard_card_diagnostics"
    private const val EVENTS = "events"
    private const val LAST_REASON = "lastReason"
    private const val LAST_ATTACH = "lastAttach"
    private const val LAST_EVENT = "lastEvent"

    fun record(context: Context, event: String, reason: String, attached: Boolean? = null) {
        val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val state = "$event|$reason|${attached ?: "-"}"
        if (prefs.getString(LAST_EVENT, null) == state) return
        val line = "${android.os.SystemClock.elapsedRealtime()}|$state"
        val old = prefs.getString(EVENTS, "").orEmpty().lineSequence().filter(String::isNotBlank).takeLast(15).toList()
        prefs.edit()
            .putString(EVENTS, (old + line).joinToString("\n"))
            .putString(LAST_REASON, reason)
            .putString(LAST_EVENT, state)
            .apply()
    }

    fun attach(context: Context, result: String) {
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putString(LAST_ATTACH, result).apply()
    }

    fun lastReason(context: Context): String = context.applicationContext
        .getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(LAST_REASON, "Nincs zárképernyő-próba") ?: "Nincs zárképernyő-próba"

    fun lastAttachResult(context: Context): String = context.applicationContext
        .getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(LAST_ATTACH, "Nincs csatolási kísérlet") ?: "Nincs csatolási kísérlet"

    fun summary(context: Context): String = context.applicationContext
        .getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(EVENTS, "") ?: ""
}

internal object FluviKeyguardCardServiceRegistry {
    @Volatile var connected: Boolean = false
        private set
    @Volatile private var service: FluviKeyguardCardService? = null

    fun connected(service: FluviKeyguardCardService) {
        this.service = service
        connected = true
    }

    fun disconnected(service: FluviKeyguardCardService) {
        if (this.service === service) this.service = null
        connected = false
    }

    fun notifySettingsChanged(settings: KeyguardCardSettings) {
        service?.onSettingsChangedFromApplication(settings)
    }

    fun notifyFocusChanged() {
        service?.onFinancialFocusChangedFromApplication()
    }
}
