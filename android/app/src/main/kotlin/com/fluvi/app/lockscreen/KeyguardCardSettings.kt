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
    val animationMode: KeyguardCardAnimationMode = KeyguardCardAnimationMode.ORB_ONLY,
    val generation: Long = 0L,
)

/** Unknown persisted values use the documented migration default rather than
 * guessing a future background-rendering mode after a downgrade/upgrade. */
internal enum class KeyguardCardAnimationMode(val wireValue: String) {
    OFF("off"),
    ORB_ONLY("orbOnly"),
    ORB_AND_BACKGROUND("orbAndBackground");

    companion object {
        fun fromWire(value: Any?): KeyguardCardAnimationMode = entries.firstOrNull {
            it.wireValue == value as? String
        } ?: ORB_ONLY
    }
}

internal object FluviKeyguardCardSettings {
    private const val PREFS = "fluvi_native_keyguard_card"
    private const val REQUESTED = "requested"
    private const val DETAILS = "details"
    private const val OFFSET = "verticalOffsetDp"
    private const val ANIMATION_MODE = "animationMode"
    private const val GENERATION = "generation"

    fun read(context: Context): KeyguardCardSettings {
        val prefs = prefs(context)
        return KeyguardCardSettings(
            requested = prefs.getBoolean(REQUESTED, false),
            showFinancialDetails = prefs.getBoolean(DETAILS, false),
            verticalOffsetDp = prefs.getInt(OFFSET, 0).coerceIn(-96, 96),
            animationMode = KeyguardCardAnimationMode.fromWire(prefs.getString(ANIMATION_MODE, null)),
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
        val animationMode = if (values.containsKey("animationMode")) {
            KeyguardCardAnimationMode.fromWire(values["animationMode"])
        } else old.animationMode
        val next = KeyguardCardSettings(requested, details, offset, animationMode, old.generation + 1L)
        prefs(context).edit()
            .putBoolean(REQUESTED, next.requested)
            .putBoolean(DETAILS, next.showFinancialDetails)
            .putInt(OFFSET, next.verticalOffsetDp)
            .putString(ANIMATION_MODE, next.animationMode.wireValue)
            .putLong(GENERATION, next.generation)
            .apply()
        if (!next.showFinancialDetails) {
            com.fluvi.app.lockscreen.material.FluviKeyguardMaterialStore.redact(context)
        } else if (!old.showFinancialDetails) {
            com.fluvi.app.lockscreen.material.FluviKeyguardMaterialBridgeRegistry.requestSceneRefresh()
        }
        FluviKeyguardCardServiceRegistry.notifySettingsChanged(next)
        return next
    }

    fun statusMap(context: Context): Map<String, Any?> {
        val value = read(context)
        return mapOf(
            "requested" to value.requested,
            "showFinancialDetails" to value.showFinancialDetails,
            "verticalOffsetDp" to value.verticalOffsetDp,
            "animationMode" to value.animationMode.wireValue,
            "generation" to value.generation,
            "systemServiceEnabled" to systemServiceEnabled(context),
            "serviceConnected" to FluviKeyguardCardServiceRegistry.connected,
            "lastDecisionReason" to KeyguardCardDiagnostics.lastReason(context),
            "lastAttachResult" to KeyguardCardDiagnostics.lastAttachResult(context),
            "diagnosticSummary" to KeyguardCardDiagnostics.summary(context),
            "materialDiagnostics" to FluviKeyguardCardServiceRegistry.materialDiagnostics(),
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
    private const val LAST_EVENT_COUNT = "lastEventCount"
    private const val ATTEMPT = "attempt"

    fun beginLockAttempt(context: Context, session: Long, wakeEpoch: Long) {
        val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val line = "${android.os.SystemClock.elapsedRealtime()}|KG|WAKE|session=$session|wake=$wakeEpoch"
        prefs.edit()
            .putString(EVENTS, line)
            .putString(ATTEMPT, "session=$session|wake=$wakeEpoch")
            .remove(LAST_EVENT)
            .putInt(LAST_EVENT_COUNT, 0)
            .apply()
    }

    fun record(context: Context, event: String, reason: String, attached: Boolean? = null) {
        val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val state = "$event|$reason|${attached ?: "-"}"
        if (prefs.getString(LAST_EVENT, null) == state) {
            prefs.edit().putInt(LAST_EVENT_COUNT, prefs.getInt(LAST_EVENT_COUNT, 1) + 1).apply()
            return
        }
        val line = "${android.os.SystemClock.elapsedRealtime()}|$state"
        // Sequence has no takeLast extension on the Kotlin version used by
        // this project. The diagnostic buffer is deliberately tiny, so make
        // the bounded list explicit before retaining the most recent lines.
        val old = prefs.getString(EVENTS, "").orEmpty().lineSequence()
            .filter(String::isNotBlank)
            .toList()
            .takeLast(47)
        prefs.edit()
            .putString(EVENTS, (old + line).joinToString("\n"))
            .putString(LAST_REASON, reason)
            .putString(LAST_EVENT, state)
            .putInt(LAST_EVENT_COUNT, 1)
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

    fun summary(context: Context): String {
        val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val events = prefs.getString(EVENTS, "").orEmpty()
        val repeated = prefs.getInt(LAST_EVENT_COUNT, 1)
        return if (repeated > 1) "$events\nrepeat=$repeated" else events
    }
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

    fun notifyMaterialChanged(profile: com.fluvi.app.lockscreen.material.KeyguardMaterialProfile) {
        service?.onMaterialProfileChangedFromApplication(profile)
    }

    fun materialDiagnostics(): Map<String, Any?> = service?.materialDiagnostics()
        ?: mapOf(
            "rendererBackend" to "not-connected",
            "hardwareAccelerated" to false,
            "shaderCreationCount" to 0,
            "animationStartCount" to 0,
            "animationStopCount" to 0,
            "drawCount" to 0,
            "frameIntervalP50" to 0,
            "frameIntervalP95" to 0,
            "largeFrameGapCount" to 0,
            "lastRendererFailure" to null,
        )
}
