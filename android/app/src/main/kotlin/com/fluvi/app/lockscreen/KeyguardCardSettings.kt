package com.fluvi.app.lockscreen

import android.content.ComponentName
import android.content.Context
import android.os.Build
import android.os.Process
import android.os.SystemClock
import android.provider.Settings
import com.fluvi.app.runtime.FluviLockScreenCardConfiguration
import com.fluvi.app.runtime.FluviRuntimeCoordinator
import com.fluvi.app.widget.financial.FluviFinancialSnapshotWidgetCoordinator
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicLong

/**
 * The accessibility overlay owns this focus.  It may share the financial
 * projector enum with the widget and notification, but it never shares their
 * storage authority.  In particular, a null Budget category remains an
 * explicit incomplete choice instead of silently becoming another category.
 */
internal data class KeyguardCardFocus(
    val mode: FluviLockScreenCardConfiguration.Mode = FluviLockScreenCardConfiguration.Mode.balance,
    val timeAxis: FluviLockScreenCardConfiguration.TimeAxis = FluviLockScreenCardConfiguration.TimeAxis.month,
    val direction: FluviLockScreenCardConfiguration.Direction = FluviLockScreenCardConfiguration.Direction.expense,
    val categoryId: String? = null,
    val eventLine: FluviLockScreenCardConfiguration.EventLine = FluviLockScreenCardConfiguration.EventLine.related,
    val generation: Long = 0L,
) {
    val isValid: Boolean get() = mode != FluviLockScreenCardConfiguration.Mode.budget || !categoryId.isNullOrBlank()

    fun asFinancialFocus() = FluviLockScreenCardConfiguration(
        enabled = true,
        mode = mode,
        timeAxis = timeAxis,
        direction = direction,
        categoryId = categoryId,
        eventLine = eventLine,
        privacy = FluviLockScreenCardConfiguration.Privacy.full,
        generation = generation,
    )

    fun toMap(): Map<String, Any?> = mapOf(
        "mode" to mode.name,
        "timeAxis" to timeAxis.name,
        "direction" to direction.name,
        "categoryId" to categoryId,
        "eventLine" to eventLine.name,
        "generation" to generation,
        "valid" to isValid,
    )
}

/** Persistent user consent only.  Live service/window facts deliberately do
 * not live here, so a stale setting can never claim physical visibility. */
internal data class KeyguardCardSettings(
    val requested: Boolean = false,
    val showFinancialDetails: Boolean = false,
    val verticalOffsetDp: Int = 0,
    val animationMode: KeyguardCardAnimationMode = KeyguardCardAnimationMode.ORB_ONLY,
    val presentationMode: KeyguardCardPresentationMode = KeyguardCardPresentationMode.CARD,
    /** Null means that the legacy bottom-gravity offset has not yet been
     * converted against a real display/inset geometry. */
    val cardPosition: KeyguardCardCardPosition? = null,
    val orbPosition: KeyguardCardOrbPosition? = null,
    /** Deliberately independent from focus.generation. A drag must never
     * invalidate financial content or make a late focus request current. */
    val layoutRevision: Long = 0L,
    val focus: KeyguardCardFocus = KeyguardCardFocus(),
    val generation: Long = 0L,
)

internal enum class KeyguardCardPresentationMode(val wireValue: String) {
    CARD("card"),
    ORB("orb");

    companion object {
        fun fromWire(value: Any?): KeyguardCardPresentationMode = entries.firstOrNull {
            it.wireValue == value as? String
        } ?: CARD
    }
}

/** Positions are fractions of the usable *travel* range, rather than pixels
 * or dp. They therefore survive density, inset and display-size changes. */
internal data class KeyguardCardCardPosition(val yFraction: Float) {
    fun normalized() = copy(yFraction = yFraction.finiteFraction())
}

internal data class KeyguardCardOrbPosition(val xFraction: Float, val yFraction: Float) {
    fun normalized() = copy(
        xFraction = xFraction.finiteFraction(),
        yFraction = yFraction.finiteFraction(),
    )
}

internal fun Float.finiteFraction(): Float = if (isFinite()) coerceIn(0f, 1f) else .5f

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
    private const val PRESENTATION_MODE = "presentationMode"
    private const val CARD_Y_FRACTION = "cardPosition.yFraction"
    private const val ORB_X_FRACTION = "orbPosition.xFraction"
    private const val ORB_Y_FRACTION = "orbPosition.yFraction"
    private const val LAYOUT_REVISION = "layoutRevision"
    private const val FOCUS_MIGRATED = "focusMigrated"
    private const val FOCUS_MODE = "focus.mode"
    private const val FOCUS_AXIS = "focus.axis"
    private const val FOCUS_DIRECTION = "focus.direction"
    private const val FOCUS_CATEGORY = "focus.categoryId"
    private const val FOCUS_EVENT_LINE = "focus.eventLine"
    private const val FOCUS_GENERATION = "focus.generation"
    private const val GENERATION = "generation"

    fun read(context: Context): KeyguardCardSettings {
        val prefs = prefs(context)
        migrateFocusIfNeeded(context, prefs)
        return KeyguardCardSettings(
            requested = prefs.getBoolean(REQUESTED, false),
            showFinancialDetails = prefs.getBoolean(DETAILS, false),
            verticalOffsetDp = prefs.getInt(OFFSET, 0).coerceIn(-96, 96),
            animationMode = KeyguardCardAnimationMode.fromWire(prefs.getString(ANIMATION_MODE, null)),
            presentationMode = KeyguardCardPresentationMode.fromWire(prefs.getString(PRESENTATION_MODE, null)),
            cardPosition = prefs.takeIf { it.contains(CARD_Y_FRACTION) }?.let {
                KeyguardCardCardPosition(it.getFloat(CARD_Y_FRACTION, .5f)).normalized()
            },
            orbPosition = prefs.takeIf { it.contains(ORB_X_FRACTION) && it.contains(ORB_Y_FRACTION) }?.let {
                KeyguardCardOrbPosition(
                    it.getFloat(ORB_X_FRACTION, .5f),
                    it.getFloat(ORB_Y_FRACTION, .5f),
                ).normalized()
            },
            layoutRevision = prefs.getLong(LAYOUT_REVISION, 0L),
            focus = KeyguardCardFocus(
                mode = enumValue(prefs.getString(FOCUS_MODE, null), FluviLockScreenCardConfiguration.Mode.balance),
                timeAxis = enumValue(prefs.getString(FOCUS_AXIS, null), FluviLockScreenCardConfiguration.TimeAxis.month),
                direction = enumValue(prefs.getString(FOCUS_DIRECTION, null), FluviLockScreenCardConfiguration.Direction.expense),
                categoryId = prefs.getString(FOCUS_CATEGORY, null),
                eventLine = enumValue(prefs.getString(FOCUS_EVENT_LINE, null), FluviLockScreenCardConfiguration.EventLine.related),
                generation = prefs.getLong(FOCUS_GENERATION, 0L),
            ),
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
        val presentationMode = if (values.containsKey("presentationMode")) {
            KeyguardCardPresentationMode.fromWire(values["presentationMode"])
        } else old.presentationMode
        val focus = focusFromMap(values, old.focus)
        val focusChanged = focus.copy(generation = 0L) != old.focus.copy(generation = 0L)
        val committedFocus = focus.copy(generation = if (focusChanged) old.focus.generation + 1L else old.focus.generation)
        val layoutChanged = presentationMode != old.presentationMode
        val next = KeyguardCardSettings(
            requested = requested,
            showFinancialDetails = details,
            verticalOffsetDp = offset,
            animationMode = animationMode,
            presentationMode = presentationMode,
            cardPosition = old.cardPosition,
            orbPosition = old.orbPosition,
            layoutRevision = old.layoutRevision + if (layoutChanged) 1L else 0L,
            focus = committedFocus,
            generation = old.generation + 1L,
        )
        prefs(context).edit()
            .putBoolean(REQUESTED, next.requested)
            .putBoolean(DETAILS, next.showFinancialDetails)
            .putInt(OFFSET, next.verticalOffsetDp)
            .putString(ANIMATION_MODE, next.animationMode.wireValue)
            .putString(PRESENTATION_MODE, next.presentationMode.wireValue)
            .putLong(LAYOUT_REVISION, next.layoutRevision)
            .putBoolean(FOCUS_MIGRATED, true)
            .putString(FOCUS_MODE, next.focus.mode.name)
            .putString(FOCUS_AXIS, next.focus.timeAxis.name)
            .putString(FOCUS_DIRECTION, next.focus.direction.name)
            .putString(FOCUS_CATEGORY, next.focus.categoryId)
            .putString(FOCUS_EVENT_LINE, next.focus.eventLine.name)
            .putLong(FOCUS_GENERATION, next.focus.generation)
            .putLong(GENERATION, next.generation)
            .apply()
        if (!next.showFinancialDetails) {
            com.fluvi.app.lockscreen.material.FluviKeyguardMaterialStore.redact(context)
        } else if (!old.showFinancialDetails) {
            com.fluvi.app.lockscreen.material.FluviKeyguardMaterialBridgeRegistry.requestSceneRefresh()
        }
        if (focusChanged) {
            FluviKeyguardCardServiceRegistry.notifyFocusChanged()
            com.fluvi.app.lockscreen.material.FluviKeyguardMaterialBridgeRegistry.requestSceneRefresh()
        }
        FluviKeyguardCardServiceRegistry.notifySettingsChanged(next)
        return next
    }

    /** Narrow layout authority used by the overlay and by the settings page.
     * It never sends a full configuration snapshot, changes focus generation,
     * or emits a financial/content invalidation. */
    fun patchLayout(
        context: Context,
        values: Map<*, *>,
        expectedLayoutRevision: Long? = null,
    ): KeyguardCardSettings {
        val old = read(context)
        if (expectedLayoutRevision != null && expectedLayoutRevision != old.layoutRevision) return old
        val mode = if (values.containsKey("presentationMode")) {
            KeyguardCardPresentationMode.fromWire(values["presentationMode"])
        } else old.presentationMode
        val reset = values["resetPosition"] as? Boolean == true
        val card = when {
            reset && mode == KeyguardCardPresentationMode.CARD -> null
            values.containsKey("cardPosition") -> cardPositionFrom(values["cardPosition"]) ?: old.cardPosition
            else -> old.cardPosition
        }
        val orb = when {
            reset && mode == KeyguardCardPresentationMode.ORB -> null
            values.containsKey("orbPosition") -> orbPositionFrom(values["orbPosition"]) ?: old.orbPosition
            else -> old.orbPosition
        }
        if (mode == old.presentationMode && card == old.cardPosition && orb == old.orbPosition) return old
        val next = old.copy(
            presentationMode = mode,
            cardPosition = card,
            orbPosition = orb,
            layoutRevision = old.layoutRevision + 1L,
        )
        writeLayout(context, next)
        FluviKeyguardCardServiceRegistry.notifyLayoutChanged(next)
        return next
    }

    fun migrateCardPosition(context: Context, value: KeyguardCardCardPosition): KeyguardCardSettings {
        val old = read(context)
        if (old.cardPosition != null) return old
        return patchLayout(context, mapOf("cardPosition" to mapOf("yFraction" to value.normalized().yFraction)))
    }

    private fun writeLayout(context: Context, value: KeyguardCardSettings) {
        prefs(context).edit()
            .putString(PRESENTATION_MODE, value.presentationMode.wireValue)
            .putLong(LAYOUT_REVISION, value.layoutRevision)
            .apply {
                value.cardPosition?.let { putFloat(CARD_Y_FRACTION, it.normalized().yFraction) }
                    ?: remove(CARD_Y_FRACTION)
                value.orbPosition?.let {
                    putFloat(ORB_X_FRACTION, it.normalized().xFraction)
                    putFloat(ORB_Y_FRACTION, it.normalized().yFraction)
                } ?: run {
                    remove(ORB_X_FRACTION)
                    remove(ORB_Y_FRACTION)
                }
            }
            .apply()
    }

    fun statusMap(context: Context): Map<String, Any?> {
        val value = read(context)
        return mapOf(
            "requested" to value.requested,
            "showFinancialDetails" to value.showFinancialDetails,
            "verticalOffsetDp" to value.verticalOffsetDp,
            "animationMode" to value.animationMode.wireValue,
            "presentationMode" to value.presentationMode.wireValue,
            "cardPosition" to value.cardPosition?.let { mapOf("yFraction" to it.yFraction) },
            "orbPosition" to value.orbPosition?.let { mapOf("xFraction" to it.xFraction, "yFraction" to it.yFraction) },
            "layoutRevision" to value.layoutRevision,
            "focus" to value.focus.toMap(),
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

    private fun migrateFocusIfNeeded(context: Context, prefs: android.content.SharedPreferences) {
        if (prefs.getBoolean(FOCUS_MIGRATED, false)) return
        // The old implementation accidentally treated the AppWidget focus as
        // the overlay focus.  Copy it once only if it is meaningful.  A
        // legacy invalid Budget selection stays explicitly incomplete rather
        // than being silently redirected to a different category or metric.
        val legacy = FluviFinancialSnapshotWidgetCoordinator.configuration(context.applicationContext)
        val hadLegacyChoice = context.applicationContext
            .getSharedPreferences("fluvi_financial_snapshot_widget", Context.MODE_PRIVATE)
            .contains("mode")
        val copied = if (legacy.isValid) {
            KeyguardCardFocus(
                mode = legacy.mode,
                timeAxis = legacy.timeAxis,
                direction = legacy.direction,
                categoryId = legacy.categoryId,
                eventLine = legacy.eventLine,
                generation = 1L,
            )
        } else if (hadLegacyChoice) {
            // Preserve the incomplete Budget intent so the editor can ask for
            // a category. Never silently turn it into a different metric.
            KeyguardCardFocus(
                mode = legacy.mode,
                timeAxis = legacy.timeAxis,
                direction = legacy.direction,
                categoryId = null,
                eventLine = legacy.eventLine,
                generation = 1L,
            )
        } else {
            KeyguardCardFocus(generation = 1L)
        }
        prefs.edit()
            .putBoolean(FOCUS_MIGRATED, true)
            .putString(FOCUS_MODE, copied.mode.name)
            .putString(FOCUS_AXIS, copied.timeAxis.name)
            .putString(FOCUS_DIRECTION, copied.direction.name)
            .putString(FOCUS_CATEGORY, copied.categoryId)
            .putString(FOCUS_EVENT_LINE, copied.eventLine.name)
            .putLong(FOCUS_GENERATION, copied.generation)
            .apply()
    }

    private fun focusFromMap(values: Map<*, *>, old: KeyguardCardFocus): KeyguardCardFocus {
        val nested = values["focus"] as? Map<*, *>
        val source = nested ?: values
        fun text(key: String, fallback: String): String = source[key] as? String ?: fallback
        val categoryProvided = source.containsKey("categoryId") || values.containsKey("focusCategoryId")
        val category = when {
            source.containsKey("categoryId") -> source["categoryId"] as? String
            values.containsKey("focusCategoryId") -> values["focusCategoryId"] as? String
            else -> old.categoryId
        }
        return KeyguardCardFocus(
            mode = enumValue(text("mode", values["focusMode"] as? String ?: old.mode.name), old.mode),
            timeAxis = enumValue(text("timeAxis", values["focusTimeAxis"] as? String ?: old.timeAxis.name), old.timeAxis),
            direction = enumValue(text("direction", values["focusDirection"] as? String ?: old.direction.name), old.direction),
            categoryId = if (categoryProvided) category else old.categoryId,
            eventLine = enumValue(text("eventLine", values["focusEventLine"] as? String ?: old.eventLine.name), old.eventLine),
            generation = old.generation,
        )
    }

    private fun cardPositionFrom(value: Any?): KeyguardCardCardPosition? {
        val map = value as? Map<*, *> ?: return null
        val y = (map["yFraction"] as? Number)?.toFloat() ?: return null
        return KeyguardCardCardPosition(y).normalized()
    }

    private fun orbPositionFrom(value: Any?): KeyguardCardOrbPosition? {
        val map = value as? Map<*, *> ?: return null
        val x = (map["xFraction"] as? Number)?.toFloat() ?: return null
        val y = (map["yFraction"] as? Number)?.toFloat() ?: return null
        return KeyguardCardOrbPosition(x, y).normalized()
    }

    private inline fun <reified T : Enum<T>> enumValue(value: String?, fallback: T): T =
        enumValues<T>().firstOrNull { it.name == value } ?: fallback
}

/** Immutable diagnostic ownership captured at a wake boundary.  It is never
 * used for visibility authority: its only purpose is to keep a later
 * generation change from relabelling an already-started operation. */
internal data class KeyguardDiagnosticContext(
    val captureId: String?,
    val attemptId: Long?,
    val serviceSession: Long,
    val originWakeEpoch: Long,
)

/** The operation identity is deliberately distinct from a wake epoch. A
 * terminal hide invalidates the latter before its WindowManager callbacks
 * return, but all callbacks still belong to this one diagnostic operation. */
internal data class KeyguardDiagnosticOperation(
    val context: KeyguardDiagnosticContext?,
    val showOperationId: Long? = null,
    val hideOperationId: Long? = null,
    val attachGeneration: Long? = null,
    val causingInspectionRequestId: Long? = null,
    val triggerReceivedUptimeMs: Long? = null,
)

/** Capture collection changes evidence retention only.  It never changes an
 * inspection, visibility decision, retry, renderer or WindowManager path. */
internal enum class KeyguardDiagnosticCaptureMode {
    LIGHT,
    FULL;

    companion object {
        fun fromWire(value: String?): KeyguardDiagnosticCaptureMode =
            entries.firstOrNull { it.name.equals(value, ignoreCase = true) } ?: LIGHT
    }
}

/** A bounded, technical-only log for diagnostic builds. No node tree, text,
 * financial field, or foreign application identity is ever retained. */
internal object KeyguardCardDiagnostics {
    /** One identity per Android process. Cold preparation and a later user
     * capture must not look like two process starts merely because each used
     * to generate its own UUID suffix. */
    private val processInstanceId = "${Process.myPid()}-${UUID.randomUUID().toString().substring(0, 8)}"
    private const val PREFS = "fluvi_native_keyguard_card_diagnostics"
    private const val EVENTS = "events"
    private const val LAST_REASON = "lastReason"
    private const val LAST_ATTACH = "lastAttach"
    private const val LAST_EVENT = "lastEvent"
    private const val LAST_EVENT_COUNT = "lastEventCount"
    private const val ATTEMPT = "attempt"
    private const val CAPTURE_REPORT = "timingCapture.report"
    private const val CAPTURE_ID = "timingCapture.id"
    private const val CAPTURE_STATE = "timingCapture.state"
    private const val CAPTURE_PERSISTED_SEQ = "timingCapture.persistedSeq"
    private const val MAX_EVENTS = 512
    private const val MAX_EVENT_BYTES = 128 * 1024
    private const val MAX_ATTEMPTS = 10
    private const val MAX_INSPECTION_LEDGER = 16
    private const val ACTIVE_CAPTURE_MS = 5 * 60 * 1000L
    private const val CHECKPOINT_INTERVAL_MS = 12_000L
    private val captureLock = Any()
    private val reduction = KeyguardDiagnosticQueue(Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "fluvi-keyguard-diagnostic-reducer").apply { isDaemon = true }
    })
    private class CaptureIngress(
        val id: String,
        val mode: KeyguardDiagnosticCaptureMode,
        val droppedAtStart: Long,
        val failuresAtStart: Long,
    ) {
        val nextAttempt = AtomicLong(1L)
        val hiddenNoops = AtomicLong()
        val producerTotalNs = AtomicLong()
        val producerMaxNs = AtomicLong()
        val legacyProducerTotalNs = AtomicLong()
        val skippedRecords = AtomicLong()
    }
    @Volatile private var ingress: CaptureIngress? = null
    // Retain counters after ingress is closed, so a frozen snapshot includes
    // the final producer totals without requiring any producer-side lock.
    private var lastIngress: CaptureIngress? = null
    private val captureWriter = Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "fluvi-keyguard-diagnostic-writer").apply { isDaemon = true }
    }
    /** The legacy status shown by older debug surfaces must never rebuild a
     * SharedPreferences string or call apply() from visibility callbacks. */
    private const val MAX_LEGACY_EVENTS = 48
    private val legacyLock = Any()
    private data class LegacyState(
        var loaded: Boolean = false,
        val events: ArrayDeque<String> = ArrayDeque(),
        var lastReason: String = "Nincs zárképernyő-próba",
        var lastAttach: String = "Nincs csatolási kísérlet",
        var attempt: String? = null,
        var lastEvent: String? = null,
        var lastEventCount: Int = 1,
        var revision: Long = 0L,
        var persistedRevision: Long = 0L,
        var writeQueued: Boolean = false,
    )
    private data class LegacySnapshot(
        val events: String,
        val lastReason: String,
        val lastAttach: String,
        val attempt: String?,
        val lastEvent: String?,
        val lastEventCount: Int,
        val revision: Long,
    )
    private val legacy = LegacyState()
    @Volatile private var latestLegacyReason: String? = null
    @Volatile private var latestLegacyAttach: String? = null
    private var capture: TimingCapture? = null
    private var recovered: RecoveredCapture? = null
    private var nextCaptureGeneration = 0L
    /** Operation IDs are allocated before a visibility mutation but must not
     * wait for the capture store.  Ownership remains immutable and capture
     * availability does not affect the window lifecycle. */
    private val nextOperationId = AtomicLong(0L)
    /** One service-lifetime record remains available when the user starts a
     * capture after the slow first presentation already happened. */
    private data class ColdPreparationRecord(
        val serviceSession: Long,
        val processInstanceId: String,
        val stages: LinkedHashMap<String, Long> = linkedMapOf(),
    )
    private var coldPreparation: ColdPreparationRecord? = null

    /** A compact event is intentionally technical-only.  It never accepts a
     * node text, content description, financial value, or foreign package
     * name.  All formatting is deferred until a user asks for a snapshot. */
    private data class TimingEvent(
        val captureId: String,
        val processInstanceId: String,
        val seq: Long,
        val uptimeMs: Long,
        val elapsedMs: Long,
        val attemptId: Long?,
        val serviceSession: Long?,
        val wakeEpoch: Long?,
        val requestId: Long?,
        val attachGeneration: Long?,
        val showOperationId: Long?,
        val hideOperationId: Long?,
        val triggerReceivedUptimeMs: Long?,
        val stage: String,
        val reason: String,
        var fields: Map<String, String>,
        var firstUptimeMs: Long = uptimeMs,
        var lastUptimeMs: Long = uptimeMs,
        var count: Int = 1,
    ) {
        /** A conservative structured-data estimate. Formatting belongs to
         * export, not the high-frequency capture path. */
        fun byteSize(): Int = 176 + stage.length + reason.length +
            fields.entries.sumOf { it.key.length + it.value.length + 2 }

        fun canCoalesce(other: TimingEvent): Boolean {
            if (stage != "ACCESSIBILITY_EVENT" || other.stage != "ACCESSIBILITY_EVENT") return false
            if (fields["overlayState"] != "hidden" || other.fields["overlayState"] != "hidden") return false
            // eventTime/eventAge/sequence are expected to differ for every
            // callback and must never defeat hidden-state noise aggregation.
            val stableKeys = setOf("eventType", "windowChanges", "windowId", "displayId", "classification", "overlayState")
            return reason == other.reason && attemptId == other.attemptId &&
                stableKeys.all { fields[it] == other.fields[it] }
        }

        fun isTransition(): Boolean = stage in KeyguardCardDiagnostics.TRANSITION_STAGES

        fun toLine(compact: Boolean = true): String = buildString {
            append("seq=").append(seq)
            if (!compact) {
                append(" capture=").append(captureId)
                append(" process=").append(processInstanceId)
            }
            append(" up=").append(uptimeMs)
            append(" el=").append(elapsedMs)
            attemptId?.let { append(" attempt=").append(it) }
            serviceSession?.let { append(" session=").append(it) }
            wakeEpoch?.let { append(" wake=").append(it) }
            requestId?.let { append(" req=").append(it) }
            attachGeneration?.let { append(" attach=").append(it) }
            showOperationId?.let { append(" showOp=").append(it) }
            hideOperationId?.let { append(" hideOp=").append(it) }
            triggerReceivedUptimeMs?.let { append(" triggerUp=").append(it) }
            append(" stage=").append(stage)
            append(" reason=").append(reason)
            if (count > 1) append(" count=").append(count)
                .append(" firstUp=").append(firstUptimeMs)
                .append(" lastUp=").append(lastUptimeMs)
            // Detailed gap records have their own optional, whole-line budget
            // below. Never duplicate multiline payloads into a raw event row.
            fields.filterKeys { it !in DRAW_GAP_KEYS }.forEach { (key, value) -> append(' ').append(key).append('=').append(value) }
        }
    }

    private data class ShowEpisode(
        val operationId: Long,
        val requestId: Long?,
        val attachGeneration: Long?,
        val decisionAtUptimeMs: Long,
        var addBeginAtUptimeMs: Long? = null,
        var addReturnAtUptimeMs: Long? = null,
        var firstRootDrawAtUptimeMs: Long? = null,
        var firstShaderDrawAtUptimeMs: Long? = null,
        var firstCurrentMaterialDrawAtUptimeMs: Long? = null,
        var bootstrapDrawAtUptimeMs: Long? = null,
        var bootstrapCommitCallbackAtUptimeMs: Long? = null,
        var livePromotedAtUptimeMs: Long? = null,
        var firstLiveDrawAtUptimeMs: Long? = null,
        var frameCommitCallbackAtUptimeMs: Long? = null,
        /** The operation owns its cause independently of the rolling request
         * ledger. Later INSPECTION_FINISHED records complete this same object. */
        var cause: InspectionTimeline? = null,
        var renderSummary: Map<String, String> = emptyMap(),
    )

    private data class HideEpisode(
        val operationId: Long,
        val requestId: Long?,
        val attachGeneration: Long?,
        val triggerReceivedAtUptimeMs: Long?,
        val decisionAtUptimeMs: Long,
        var localHideAppliedAtUptimeMs: Long? = null,
        var isolatedLayerHideSubmittedAtUptimeMs: Long? = null,
        var isolatedLayerTransactionApplied: Boolean? = null,
        var removeBeginAtUptimeMs: Long? = null,
        var removeReturnAtUptimeMs: Long? = null,
        var attachedBefore: Boolean? = null,
        var detachFailed: Boolean = false,
        var cause: InspectionTimeline? = null,
    )

    private data class InspectionTimeline(
        val requestId: Long,
        var queuedAtUptimeMs: Long? = null,
        var startedAtUptimeMs: Long? = null,
        var authorityCurrentAtStart: Boolean? = null,
        var finishedAtUptimeMs: Long? = null,
        var diagnosticPreparationFinishedAtUptimeMs: Long? = null,
        var mainHandoffRequestedAtUptimeMs: Long? = null,
        var mainApplyStartedAtUptimeMs: Long? = null,
        var appliedAtUptimeMs: Long? = null,
        var windowsReadMs: Long? = null,
        var treeScanMs: Long? = null,
        var getWindowsMs: Long? = null,
        var readerStrategy: String? = null,
        var prefetchFlags: String? = null,
        var cacheEnabled: String? = null,
        var freshnessPolicy: String? = null,
        var cacheClearResult: String? = null,
        var activeCandidateWindowId: String? = null,
        var returnedRootWindowId: String? = null,
        var activeRootAccepted: String? = null,
        var fallbackReason: String? = null,
        var activeRootCallCount: Long? = null,
        var activeRootTotalMs: Long? = null,
        var perWindowRootCallCount: Long? = null,
        var perWindowRootTotalMs: Long? = null,
        var rootAcquisitionTotalMs: Long? = null,
        var rootAcquisitionMaxMs: Long? = null,
        var childAcquisitionTotalMs: Long? = null,
        var childAcquisitionMaxMs: Long? = null,
        var childAcquisitionCount: Long? = null,
        var localProcessingMs: Long? = null,
        var trigger: String? = null,
        var triggerReceivedUptimeMs: Long? = null,
        var eventTimeUptimeMs: Long? = null,
        var visibilityEpochAtRequest: Long? = null,
        var visibilityEpochAtApply: Long? = null,
        var pendingRequestIdAtApply: Long? = null,
        var surfaceReason: String? = null,
        var surfaceClassification: String? = null,
        var surfaceMarkers: String? = null,
        var rootUnavailable: String? = null,
        var walkTruncated: String? = null,
        var walkTruncationReasons: String? = null,
        var slowWindowCalls: String? = null,
        var visitedNodeCount: Long? = null,
        var rejectionReason: String? = null,
        var followupAction: String? = null,
    )

    private data class TimingAttempt(
        val id: Long,
        val serviceSession: Long,
        val wakeEpoch: Long,
        val startedUptimeMs: Long,
        var presentationMode: String = "NA",
        var wakeSource: String = "NA",
        var screenOnReceivedAtUptimeMs: Long? = null,
        var firstInspectionRequestId: Long? = null,
        var showingInspectionRequestId: Long? = null,
        var requestsReceived: Int = 0,
        var requestsReplaced: Int = 0,
        var inspectionsStarted: Int = 0,
        var inspectionsApplied: Int = 0,
        var inspectionsRejected: Int = 0,
        var staleInspectionCount: Int = 0,
        var retryScheduledCount: Int = 0,
        var retryFiredCount: Int = 0,
        var retryCancelledCount: Int = 0,
        var unknownWhileHiddenCount: Int = 0,
        var unknownWhileHiddenEpochChanges: Int = 0,
        var pendingPreservedAfterUnknown: Int = 0,
        var pendingRejectedAfterUnknown: Int = 0,
        var visibleWithdrawalCount: Int = 0,
        var retrySuppressedForPendingWork: Int = 0,
        var retryBudgetExhaustedWhileAwaiting: Int = 0,
        var attachCount: Int = 0,
        var detachCount: Int = 0,
        var omittedShowEpisodes: Int = 0,
        var omittedHideEpisodes: Int = 0,
        var omittedSpineEvents: Int = 0,
        val shows: ArrayDeque<ShowEpisode> = ArrayDeque(),
        val hides: ArrayDeque<HideEpisode> = ArrayDeque(),
        val inspections: LinkedHashMap<Long, InspectionTimeline> = linkedMapOf(),
        /** This compact causal spine is independent of the raw event ring.
         * A later hidden-state storm cannot evict an earlier wake/attach/hide
         * operation that explains a physical attempt. */
        val causalSpine: ArrayDeque<CausalSpineEvent> = ArrayDeque(),
        var finalState: String = "INCOMPLETE",
    )

    private data class CausalSpineEvent(
        val semanticKey: String,
        val seq: Long,
        val uptimeMs: Long,
        val stage: String,
        val reason: String,
        val requestId: Long?,
        val attachGeneration: Long?,
        val showOperationId: Long?,
        val hideOperationId: Long?,
        val fields: Map<String, String>,
    ) {
        fun toLine(): String = buildString {
            append("seq=").append(seq).append(" up=").append(uptimeMs)
            requestId?.let { append(" req=").append(it) }
            attachGeneration?.let { append(" attach=").append(it) }
            showOperationId?.let { append(" showOp=").append(it) }
            hideOperationId?.let { append(" hideOp=").append(it) }
            append(" stage=").append(stage).append(" reason=").append(reason)
            fields.forEach { (key, value) -> append(' ').append(key).append('=').append(value) }
        }
    }

    private data class TimingCapture(
        val id: String,
        val generation: Long,
        val build: String,
        val buildMode: String,
        val processInstanceId: String,
        val pid: Int,
        val startedUptimeMs: Long,
        val startedElapsedMs: Long,
        val startedWallMs: Long,
        val configuration: Map<String, String>,
        val captureMode: KeyguardDiagnosticCaptureMode,
        var state: String = "REC",
        // A frozen or expired capture must export the same immutable duration
        // on every subsequent read.  REC deliberately keeps a live duration.
        var endedElapsedMs: Long? = null,
        var nextSeq: Long = 1L,
        var retainedBytes: Int = 0,
        var eventsEvicted: Int = 0,
        var eventsCoalesced: Int = 0,
        var hiddenNoopCount: Int = 0,
        var diagnosticDroppedRecords: Int = 0,
        var diagnosticQueueOverflow: Long = 0L,
        var diagnosticConsumerFailures: Long = 0L,
        var captureLockWaitNs: Long = 0L,
        var captureLockHeldNs: Long = 0L,
        var diagnosticProducerTotalNs: Long = 0L,
        var diagnosticProducerMaxNs: Long = 0L,
        var legacyDiagnosticProducerTotalNs: Long = 0L,
        var legacyWriteCount: Long = 0L,
        var checkpointCount: Long = 0L,
        var queuedForPersistenceSeq: Long = 0L,
        var lastSuccessfullyPersistedSeq: Long = 0L,
        var lastCheckpointElapsedMs: Long = startedElapsedMs,
        var unflushedTailMayBeMissing: Boolean = false,
        var frozenExport: TimingCapture? = null,
        val coldPreparation: ColdPreparationRecord? = null,
        /** First observed wake is retained independently of the rolling ten
         * attempt window so a later event storm cannot erase cold evidence. */
        var firstAttempt: TimingAttempt? = null,
        val events: ArrayDeque<TimingEvent> = ArrayDeque(),
        val attempts: ArrayDeque<TimingAttempt> = ArrayDeque(),
    )

    private data class RecoveredCapture(
        val id: String,
        val report: String,
        val lastPersistedSeq: Long,
    )

    private val TRANSITION_STAGES = setOf(
        "SCREEN_ON_RECEIVED", "WAKE_CYCLE_STARTED", "WORKER_OCCUPIED_AT_WAKE", "INSPECTION_QUEUED", "INSPECTION_COALESCED",
        "INSPECTION_STARTED", "INSPECTION_FINISHED", "INSPECTION_MAIN_APPLY_POSTED", "INSPECTION_MAIN_APPLY_STARTED", "INSPECTION_APPLIED",
        "INSPECTION_REJECTED", "RETRY_SCHEDULED", "RETRY_FIRED", "RETRY_CANCELLED",
        "AWAITING_MAIN_SURFACE", "PENDING_REPLACED_AFTER_UNKNOWN", "RETRY_SUPPRESSED_FOR_PENDING", "RETRY_BUDGET_EXHAUSTED_AWAITING",
        "SHOW_FOR_ATTACH", "ADD_VIEW_BEGIN", "ADD_VIEW_RETURN", "ATTACH_FAILED", "FIRST_ROOT_DRAW",
        "FIRST_SHADER_DRAW", "FIRST_CURRENT_MATERIAL_DRAW", "FIRST_LIVE_DRAW", "FRAME_COMMIT_CALLBACK_RECEIVED", "BOOTSTRAP_DRAW", "BOOTSTRAP_COMMIT_CALLBACK_RECEIVED", "MATERIAL_LIVE_PROMOTED", "HIDE_DECIDED", "LOCAL_HIDE_BEGIN", "LOCAL_HIDE_APPLIED",
        "ISOLATED_LAYER_HIDE_SUBMITTED", "REMOVE_VIEW_BEGIN", "REMOVE_VIEW_RETURN", "DETACH_FAILED", "HIDE_COMPLETED", "CAPTURE_FROZEN",
    )
    private val CAUSAL_SPINE_FIELD_KEYS = setOf(
        "queueMs", "inspectionTotalMs", "windowsReadMs", "treeScanMs", "mainApplyQueueMs",
        "inspectionFinishToHandoffMs", "handoffToMainEntryMs", "mainEntryToDecisionMs",
        "diagnosticPreparationFinishedAtUptimeMs", "mainHandoffRequestedAtUptimeMs", "mainApplyEnteredAtUptimeMs",
        "rejectionReason", "decision", "abortedStale", "attachedBefore",
        "attachedAfter", "triggerReceivedUptimeMs", "terminalWake", "retryId", "retryIndex",
        "requestedDelayMs", "schedulerLatenessMs", "causingRequestId", "rootWasPrepared",
        "profileWasDecoded", "presentationMode", "surfaceClassification",
        "activeOriginalSession", "activeOriginalWake", "activeOriginalVisibilityEpoch",
        "activeOriginalInteractionEpoch", "activeOriginalAttachGeneration", "activeQueuedAtUptimeMs",
        "surfaceMarkers", "rootUnavailable", "walkTruncated", "visitedNodeCount", "followupAction",
        "pendingRequestId", "pendingRequestIdAtApply", "visibilityEpochBefore", "visibilityEpochAfter",
    )
    private val RENDER_SUMMARY_KEYS = setOf(
        "clockCallbacks", "isolatedFramesProduced", "isolatedFramesPublished", "isolatedFramesDropped",
        "isolatedCompletionGapMaxMs",
        "shaderFrames", "shaderCalls", "phaseAdvances", "firstPhase", "lastPhase",
        "drawGapCount", "drawGapTotalMs", "drawGapMaxMs", "animationStarts", "animationStops",
        "clockRunning", "liveState", "backgroundFrames", "firstShaderTraversalAt", "lastShaderTraversalAt", "drawInvalidOrder",
        "drawEvidenceMode", "drawEvidenceOmitted", "drawObserverNs", "drawObservedFrames",
        "drawUnpairedFrames", "drawCoalescedCallbacks", "drawEvidenceBreaks", "drawEvidenceRejected", "drawGapCaptureOmitted",
        "orbDrawGaps", "backgroundDrawGaps",
    )
    private val DRAW_GAP_KEYS = setOf("orbDrawGaps", "backgroundDrawGaps")

    /** Only the attachment summary admits these bounded technical records.
     * They are already formatted on the diagnostic worker, not in onDraw.
     * Preserve whole records: the generic 160-character value cap would cut
     * the final ownership/timing fields in the middle of a record. */
    private fun captureTechnicalFields(stage: String, fields: Map<String, Any?>): Map<String, String> {
        val result = linkedMapOf<String, String>()
        var gapRecordsOmitted = 0
        fields.forEach { (key, value) ->
            if (value == null) return@forEach
            if (stage == "ATTACHMENT_RENDER_SUMMARY" && key in DRAW_GAP_KEYS) {
                val retained = mutableListOf<String>()
                value.toString().lineSequence().filter(String::isNotBlank).forEach { line ->
                    if (retained.size < 3 && line.length <= 1_200) retained += line.replace('\r', ' ')
                    else gapRecordsOmitted += 1
                }
                result[key] = retained.joinToString("\n")
            } else result[key] = technicalValue(value)
        }
        if (stage == "ATTACHMENT_RENDER_SUMMARY") result["drawGapCaptureOmitted"] = gapRecordsOmitted.toString()
        return result
    }

    fun recordColdPreparation(serviceSession: Long, stage: String, observedUptimeMs: Long = SystemClock.uptimeMillis()) {
        reduction.offer {
        synchronized(captureLock) {
            val current = coldPreparation?.takeIf { it.serviceSession == serviceSession }
                ?: ColdPreparationRecord(
                    serviceSession = serviceSession,
                    processInstanceId = processInstanceId,
                ).also { coldPreparation = it }
            current.stages.putIfAbsent(stage, observedUptimeMs)
        }
        }
    }

    /** Pin only operation milestones. Inspection confirmations are represented
     * by their compact timelines/counters, not by an unbounded event FIFO. */
    private fun causalSpineKey(event: TimingEvent): String? = when (event.stage) {
        "WAKE_ATTEMPT", "SCREEN_ON_RECEIVED", "WAKE_CYCLE_STARTED", "WORKER_OCCUPIED_AT_WAKE" -> event.stage
        "INSPECTION_QUEUED", "INSPECTION_COALESCED" -> "FIRST_INSPECTION_REQUEST"
        "INSPECTION_STARTED" -> "FIRST_INSPECTION_STARTED"
        "INSPECTION_FINISHED" -> "FIRST_INSPECTION_FINISHED"
        "INSPECTION_MAIN_APPLY_POSTED" -> "FIRST_MAIN_RESULT_POSTED"
        "INSPECTION_MAIN_APPLY_STARTED" -> "FIRST_MAIN_APPLY_STARTED"
        "AWAITING_MAIN_SURFACE" -> "FIRST_AWAITING_MAIN_SURFACE"
        "SHOW_FOR_ATTACH", "ADD_VIEW_BEGIN", "ADD_VIEW_RETURN", "ATTACH_FAILED", "FIRST_ROOT_DRAW", "FIRST_SHADER_DRAW", "FIRST_CURRENT_MATERIAL_DRAW", "FIRST_LIVE_DRAW", "FRAME_COMMIT_CALLBACK_RECEIVED", "BOOTSTRAP_DRAW", "BOOTSTRAP_COMMIT_CALLBACK_RECEIVED", "MATERIAL_LIVE_PROMOTED" ->
            "${event.stage}:${event.showOperationId ?: "none"}"
        "HIDE_DECIDED", "LOCAL_HIDE_APPLIED", "ISOLATED_LAYER_HIDE_SUBMITTED", "REMOVE_VIEW_BEGIN", "REMOVE_VIEW_RETURN", "DETACH_FAILED", "HIDE_COMPLETED" ->
            "${event.stage}:${event.hideOperationId ?: "none"}"
        else -> null
    }

    /** Starts a capture owned by Android, not by a Flutter widget or stream.
     * The only Flutter supplied values are immutable build labels for the
     * human-readable header. */
    fun startCapture(
        context: Context,
        build: String?,
        buildMode: String?,
        mode: String? = null,
    ): Map<String, Any?> = reduction.read {
        val export = synchronized(captureLock) {
        ensureRecoveredLoadedLocked(context)
        val settings = FluviKeyguardCardSettings.read(context)
        val runtime = FluviRuntimeCoordinator.status(context)
        val id = UUID.randomUUID().toString()
        val nowUp = SystemClock.uptimeMillis()
        val nowElapsed = SystemClock.elapsedRealtime()
        val captureMode = KeyguardDiagnosticCaptureMode.fromWire(mode)
        val created = TimingCapture(
            id = id,
            generation = ++nextCaptureGeneration,
            build = build?.takeIf { it.isNotBlank() }?.let(::technicalValue) ?: "unknown",
            buildMode = buildMode?.takeIf { it.isNotBlank() }?.let(::technicalValue) ?: "unknown",
            processInstanceId = processInstanceId,
            pid = Process.myPid(),
            startedUptimeMs = nowUp,
            startedElapsedMs = nowElapsed,
            startedWallMs = System.currentTimeMillis(),
            configuration = linkedMapOf(
                "serviceConnected" to FluviKeyguardCardServiceRegistry.connected.toString(),
                "keyguardRequested" to settings.requested.toString(),
                "foregroundRequested" to runtime.foregroundRequested.toString(),
                "backgroundRequested" to runtime.backgroundRequested.toString(),
                "presentationMode" to settings.presentationMode.name,
                "animationMode" to settings.animationMode.wireValue,
                "privacyMode" to if (settings.showFinancialDetails) "full" else "discreet",
                "notificationTimeoutMs" to "0",
            ),
            captureMode = captureMode,
            coldPreparation = coldPreparation?.let { it.copy(stages = LinkedHashMap(it.stages)) },
        )
        capture = created
        CaptureIngress(id, captureMode, reduction.dropped.get(), reduction.failed.get()).also {
            lastIngress = it
            ingress = it
        }
        recovered = null
        appendLocked(created, "CAPTURE_STARTED", "user", fields = mapOf("source" to "runtimeMethod"))
        persistLocked(context, created, force = true)
            snapshotForExportLocked(created)
        }
        snapshotMap(export, null)
    }

    fun freezeCapture(context: Context): Map<String, Any?> = reduction.read {
        ingress = null
        val read = synchronized(captureLock) {
            ensureRecoveredLoadedLocked(context)
            val active = capture
            if (active != null && active.state == "REC") {
                active.endedElapsedMs = SystemClock.elapsedRealtime()
                active.state = "FROZEN"
                appendLocked(active, "CAPTURE_FROZEN", "user")
                persistLocked(context, active, force = true)
                // Repeated Copy calls must yield the exact same frozen report,
                // even if an asynchronous durability acknowledgement arrives.
                active.frozenExport = snapshotForExportLocked(active)
            }
            (active?.frozenExport ?: active?.let(::snapshotForExportLocked)) to recovered
        }
        snapshotMap(read.first, read.second)
    }

    fun captureSnapshot(context: Context): Map<String, Any?> = reduction.read {
        val read = synchronized(captureLock) {
            ensureRecoveredLoadedLocked(context)
            val active = capture
            if (active?.state == "REC") expireIfNeededLocked(context, active)
            val current = capture
            (current?.frozenExport ?: current?.let(::snapshotForExportLocked)) to recovered
        }
        snapshotMap(read.first, read.second)
    }

    fun clearCapture(context: Context): Map<String, Any?> = reduction.read { synchronized(captureLock) {
        ingress = null
        lastIngress = null
        capture = null
        recovered = null
        val clearGeneration = ++nextCaptureGeneration
        captureWriter.execute {
            synchronized(captureLock) {
                // A start that followed Clear owns persistence; an old clear
                // must not delete its recovered report or checkpoint.
                if (capture != null || nextCaptureGeneration != clearGeneration) return@execute
            }
            context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .remove(CAPTURE_REPORT).remove(CAPTURE_ID).remove(CAPTURE_STATE).remove(CAPTURE_PERSISTED_SEQ).commit()
        }
        mapOf(
            "available" to true,
            "captureState" to "IDLE",
            "captureId" to "-",
            "attemptCount" to 0,
            "eventsRetained" to 0,
            "eventsEvicted" to 0,
            "eventsRecorded" to 0,
            "clearGeneration" to clearGeneration,
            "report" to "",
        )
    } }

    /** Called at the first line of each new wake attempt. Existing active
     * capture history is deliberately retained; only the legacy compact
     * status line is replaced for the ordinary settings screen. */
    fun beginLockAttempt(
        context: Context,
        session: Long,
        wakeEpoch: Long,
        source: String = "unknown",
        receivedAtUptimeMs: Long = SystemClock.uptimeMillis(),
    ): KeyguardDiagnosticContext? {
        val receivedElapsedMs = SystemClock.elapsedRealtime()
        latestLegacyReason = "session=$session|wake=$wakeEpoch"
        val token = ingress
        val ownership = token?.let { KeyguardDiagnosticContext(it.id, it.nextAttempt.getAndIncrement(), session, wakeEpoch) }
        reduction.offer {
            resetLegacyAttempt(context, "$receivedElapsedMs|KG|WAKE|session=$session|wake=$wakeEpoch", "session=$session|wake=$wakeEpoch")
            synchronized(captureLock) {
            val active = capture?.takeIf { it.id == token?.id } ?: return@synchronized
            if (active.state != "REC" || expireIfNeededLocked(context, active)) return@synchronized
            while (active.attempts.size >= MAX_ATTEMPTS) active.attempts.removeFirst()
            val attempt = TimingAttempt(requireNotNull(ownership?.attemptId), session, wakeEpoch, receivedAtUptimeMs)
            if (active.firstAttempt == null) active.firstAttempt = attempt
            attempt.presentationMode = active.configuration["presentationMode"] ?: "NA"
            attempt.wakeSource = source
            active.attempts.addLast(attempt)
            appendLocked(
                active,
                "WAKE_ATTEMPT",
                "begin",
                serviceSession = session,
                wakeEpoch = wakeEpoch,
                observedUptimeMs = receivedAtUptimeMs,
                observedElapsedMs = receivedElapsedMs,
                diagnosticContext = ownership,
            )
            }
        }
        return ownership
    }

    fun newShowOperation(
        context: KeyguardDiagnosticContext?,
        attachGeneration: Long?,
        causingInspectionRequestId: Long?,
    ): KeyguardDiagnosticOperation =
        KeyguardDiagnosticOperation(
            context = context,
            showOperationId = nextOperationId.incrementAndGet(),
            attachGeneration = attachGeneration,
            causingInspectionRequestId = causingInspectionRequestId,
        )

    fun newHideOperation(
        context: KeyguardDiagnosticContext?,
        attachGeneration: Long?,
        causingInspectionRequestId: Long?,
        triggerReceivedUptimeMs: Long?,
    ): KeyguardDiagnosticOperation =
        KeyguardDiagnosticOperation(
            context = context,
            hideOperationId = nextOperationId.incrementAndGet(),
            attachGeneration = attachGeneration,
            causingInspectionRequestId = causingInspectionRequestId,
            triggerReceivedUptimeMs = triggerReceivedUptimeMs,
        )

    fun recordHiddenNoop(@Suppress("UNUSED_PARAMETER") context: Context) { ingress?.hiddenNoops?.incrementAndGet() }

    /** Opaque capture identity only: no lock, snapshot or diagnostic work.
     * Attachment-owned numeric probes use it to avoid crossing captures. */
    fun drawEvidenceOwner(): Any? = ingress

    /** Check before constructing optional verbose fields. LIGHT keeps the
     * complete INSPECTION_FINISHED aggregate instead of three copies. */
    fun wantsEvent(stage: String): Boolean {
        val token = ingress ?: return false
        return token.mode == KeyguardDiagnosticCaptureMode.FULL ||
            stage !in LIGHT_REDUNDANT_STAGES
    }

    private val LIGHT_REDUNDANT_STAGES = setOf("ACCESSIBILITY_EVENT", "WINDOWS_READ_FINISHED", "TREE_SCAN_FINISHED")

    /** Producers enqueue immutable ownership and original times. String/map
     * conversion, timeline reduction and retention run on the sole consumer. */
    fun captureEvent(
        context: Context,
        stage: String,
        reason: String,
        serviceSession: Long? = null,
        wakeEpoch: Long? = null,
        requestId: Long? = null,
        attachGeneration: Long? = null,
        observedUptimeMs: Long? = null,
        diagnosticContext: KeyguardDiagnosticContext? = null,
        operation: KeyguardDiagnosticOperation? = null,
        fields: Map<String, Any?> = emptyMap(),
        deferredFields: (() -> Map<String, Any?>)? = null,
    ) {
        val producerStartedAtNs = SystemClock.elapsedRealtimeNanos()
        val token = ingress ?: return
        if (!wantsEvent(stage)) { token.skippedRecords.incrementAndGet(); return }
        val observedAt = observedUptimeMs ?: SystemClock.uptimeMillis()
        val observedElapsed = SystemClock.elapsedRealtime()
        reduction.offer {
        val lockRequestedAtNs = SystemClock.elapsedRealtimeNanos()
        synchronized(captureLock) {
        val lockAcquiredAtNs = SystemClock.elapsedRealtimeNanos()
        val active = capture?.takeIf { it.id == token.id } ?: return@synchronized
        if (active.state != "REC" || expireIfNeededLocked(context, active)) return@synchronized
        val capturedFields = captureTechnicalFields(stage, deferredFields?.invoke() ?: fields)
            .let { base ->
                if (stage == "ACCESSIBILITY_EVENT" && base["overlayState"] == "hidden") {
                    base["eventAgeMs"]?.toLongOrNull()?.let { age ->
                        base + mapOf("eventAgeMinMs" to age.toString(), "eventAgeMaxMs" to age.toString())
                    } ?: base
                } else base
            }
        appendLocked(
            active = active,
            stage = stage,
            reason = reason,
            serviceSession = serviceSession,
            wakeEpoch = wakeEpoch,
            requestId = requestId ?: operation?.causingInspectionRequestId,
            attachGeneration = attachGeneration,
            observedUptimeMs = observedAt,
            observedElapsedMs = observedElapsed,
            diagnosticContext = diagnosticContext,
            operation = operation,
            fields = capturedFields,
        )
        // Captures are durably checkpointed at explicit lifecycle boundaries
        // (start/freeze/expiry).  Building a full export snapshot here would
        // put lock-held copy work on the show/hide callback path.
        val finishedAtNs = SystemClock.elapsedRealtimeNanos()
        val heldNs = (finishedAtNs - lockAcquiredAtNs).coerceAtLeast(0L)
        active.captureLockWaitNs += lockAcquiredAtNs - lockRequestedAtNs
        active.captureLockHeldNs += heldNs
        }
        }
        val producerNs = SystemClock.elapsedRealtimeNanos() - producerStartedAtNs
        token.producerTotalNs.addAndGet(producerNs)
        token.producerMaxNs.updateAndGet { maxOf(it, producerNs) }
    }

    private fun appendLocked(
        active: TimingCapture,
        stage: String,
        reason: String,
        serviceSession: Long? = null,
        wakeEpoch: Long? = null,
        requestId: Long? = null,
        attachGeneration: Long? = null,
        observedUptimeMs: Long? = null,
        observedElapsedMs: Long? = null,
        diagnosticContext: KeyguardDiagnosticContext? = null,
        operation: KeyguardDiagnosticOperation? = null,
        fields: Map<String, String> = emptyMap(),
    ) {
        // A completion that belonged to a capture cleared/restarted by the
        // user must not be relabelled as attempt 1 of the new capture merely
        // because attempt identifiers are local counters.  Operation context
        // wins because it is the identity carried through Window callbacks.
        val ownership = operation?.context ?: diagnosticContext
        if (ownership?.captureId != null && ownership.captureId != active.id) return
        val event = TimingEvent(
            captureId = active.id,
            processInstanceId = active.processInstanceId,
            seq = active.nextSeq++,
            uptimeMs = observedUptimeMs ?: SystemClock.uptimeMillis(),
            elapsedMs = observedElapsedMs ?: SystemClock.elapsedRealtime(),
            attemptId = ownership?.attemptId ?: active.attempts.toList().lastOrNull {
                it.serviceSession == serviceSession && it.wakeEpoch == wakeEpoch
            }?.id,
            serviceSession = ownership?.serviceSession ?: serviceSession,
            wakeEpoch = ownership?.originWakeEpoch ?: wakeEpoch,
            requestId = requestId,
            attachGeneration = operation?.attachGeneration ?: attachGeneration,
            showOperationId = operation?.showOperationId,
            hideOperationId = operation?.hideOperationId,
            triggerReceivedUptimeMs = operation?.triggerReceivedUptimeMs,
            stage = stage,
            reason = reason,
            fields = fields,
        )
        val retainRawEvent = active.captureMode == KeyguardDiagnosticCaptureMode.FULL || stage in TRANSITION_STAGES
        if (retainRawEvent) {
            val last = active.events.lastOrNull()
            if (last != null && last.canCoalesce(event)) {
                last.lastUptimeMs = event.uptimeMs
                last.count += 1
                val age = event.fields["eventAgeMs"]?.toLongOrNull()
                if (age != null) {
                    val min = last.fields["eventAgeMinMs"]?.toLongOrNull()?.coerceAtMost(age) ?: age
                    val max = last.fields["eventAgeMaxMs"]?.toLongOrNull()?.coerceAtLeast(age) ?: age
                    last.fields = last.fields + mapOf("eventAgeMinMs" to min.toString(), "eventAgeMaxMs" to max.toString())
                }
                active.eventsCoalesced += 1
            } else {
                val size = event.byteSize()
                while (active.events.isNotEmpty() && (active.events.size >= MAX_EVENTS || active.retainedBytes + size > MAX_EVENT_BYTES)) {
                    // Preserve causal transitions ahead of repetitive observational
                    // noise. If all retained records are transitions, fall back to
                    // the oldest record and mark the export as truncated instead of
                    // pretending the attempt is complete.
                    val entries = active.events.toMutableList()
                    val index = entries.indexOfFirst { !it.isTransition() }.takeIf { it >= 0 } ?: 0
                    val evicted = entries.removeAt(index)
                    active.events.clear()
                    active.events.addAll(entries)
                    active.retainedBytes -= evicted.byteSize()
                    active.eventsEvicted += 1
                }
                active.events.addLast(event)
                active.retainedBytes += size
            }
        } else {
            // LIGHT keeps the scalar reducer and protected milestones but not
            // an event line for ordinary high-frequency observations.
            active.diagnosticDroppedRecords += 1
        }
        active.attempts.toList().lastOrNull { it.id == event.attemptId }?.let { attempt ->
            causalSpineKey(event)?.let { semanticKey ->
                // A causal spine is a semantic record, not a second FIFO.
                // Repeated confirmations may fill the raw ring, but they can
                // never evict a wake/attach/draw/withdrawal milestone.
                if (attempt.causalSpine.none { it.semanticKey == semanticKey }) {
                attempt.causalSpine.addLast(
                    CausalSpineEvent(
                        semanticKey = semanticKey,
                        seq = event.seq,
                        uptimeMs = event.uptimeMs,
                        stage = stage,
                        reason = reason,
                        requestId = event.requestId,
                        attachGeneration = event.attachGeneration,
                        showOperationId = event.showOperationId,
                        hideOperationId = event.hideOperationId,
                        fields = event.fields.filterKeys { key -> key in CAUSAL_SPINE_FIELD_KEYS },
                    ),
                )
                }
            }
            fun inspectionTimeline(): InspectionTimeline? = event.requestId?.let { request ->
                // Finishes may arrive after SHOW/HIDE because detailed capture
                // is deliberately deferred until visibility work has finished.
                val owned = attempt.shows.firstOrNull { it.cause?.requestId == request }?.cause
                    ?: attempt.hides.firstOrNull { it.cause?.requestId == request }?.cause
                if (owned != null) return@let owned
                if (request !in attempt.inspections && attempt.inspections.size >= MAX_INSPECTION_LEDGER) {
                    attempt.inspections.keys.firstOrNull { it != attempt.firstInspectionRequestId }
                        ?.let(attempt.inspections::remove)
                }
                attempt.inspections.getOrPut(request) { InspectionTimeline(request) }.also { timeline ->
                    if (timeline.trigger == null) timeline.trigger = reason
                }
            }
            fun showEpisode(): ShowEpisode? = event.showOperationId?.let { operationId ->
                attempt.shows.toList().lastOrNull {
                    it.operationId == operationId && it.attachGeneration == event.attachGeneration
                }
            }
            fun hideEpisode(): HideEpisode? = event.hideOperationId?.let { operationId ->
                attempt.hides.toList().lastOrNull {
                    it.operationId == operationId && it.attachGeneration == event.attachGeneration
                }
            }
            when (stage) {
                "SCREEN_ON_RECEIVED" -> if (attempt.screenOnReceivedAtUptimeMs == null) attempt.screenOnReceivedAtUptimeMs = event.uptimeMs
                "INSPECTION_QUEUED" -> {
                    attempt.requestsReceived += 1
                    if (attempt.firstInspectionRequestId == null) attempt.firstInspectionRequestId = requestId
                    // The request captured its enqueue timestamp before it
                    // was offered to the worker. Capture-lock ordering can
                    // legitimately log it after INSPECTION_STARTED.
                    inspectionTimeline()?.queuedAtUptimeMs =
                        fields["queuedAtUptimeMs"]?.toLongOrNull() ?: event.uptimeMs
                    inspectionTimeline()?.apply {
                        eventTimeUptimeMs = fields["eventTimeUptimeMs"]?.toLongOrNull()
                        triggerReceivedUptimeMs = fields["triggerReceivedUptimeMs"]?.toLongOrNull()
                        visibilityEpochAtRequest = fields["requestVisibilityEpoch"]?.toLongOrNull()
                    }
                }
                "INSPECTION_COALESCED" -> {
                    attempt.requestsReceived += 1
                    if (fields["replacedPendingRequestId"] != "NA") attempt.requestsReplaced += 1
                    if (attempt.firstInspectionRequestId == null) attempt.firstInspectionRequestId = requestId
                    inspectionTimeline()?.queuedAtUptimeMs =
                        fields["queuedAtUptimeMs"]?.toLongOrNull() ?: event.uptimeMs
                    inspectionTimeline()?.apply {
                        eventTimeUptimeMs = fields["eventTimeUptimeMs"]?.toLongOrNull()
                        triggerReceivedUptimeMs = fields["triggerReceivedUptimeMs"]?.toLongOrNull()
                        visibilityEpochAtRequest = fields["requestVisibilityEpoch"]?.toLongOrNull()
                    }
                }
                "INSPECTION_STARTED" -> {
                    attempt.inspectionsStarted += 1
                    inspectionTimeline()?.apply {
                        startedAtUptimeMs = event.uptimeMs
                        authorityCurrentAtStart = when (fields["authorityCurrentAtStart"]) {
                            "true" -> true
                            "false" -> false
                            else -> null
                        }
                    }
                }
                "INSPECTION_FINISHED" -> inspectionTimeline()?.apply {
                    // The request timestamps are authoritative even when
                    // bounded pressure evicted an earlier non-owning ledger
                    // entry before this operation pinned its cause.
                    queuedAtUptimeMs = fields["queuedAtUptimeMs"]?.toLongOrNull() ?: queuedAtUptimeMs
                    startedAtUptimeMs = fields["startedAtUptimeMs"]?.toLongOrNull() ?: startedAtUptimeMs
                    triggerReceivedUptimeMs = fields["triggerReceivedUptimeMs"]?.toLongOrNull() ?: triggerReceivedUptimeMs
                    eventTimeUptimeMs = fields["eventTimeUptimeMs"]?.toLongOrNull() ?: eventTimeUptimeMs
                    visibilityEpochAtRequest = fields["requestVisibilityEpoch"]?.toLongOrNull() ?: visibilityEpochAtRequest
                    finishedAtUptimeMs = event.uptimeMs
                    windowsReadMs = fields["windowsReadMs"]?.toLongOrNull()
                    treeScanMs = fields["treeScanMs"]?.toLongOrNull()
                    getWindowsMs = fields["getWindowsMs"]?.toLongOrNull()
                    readerStrategy = fields["readerStrategy"]
                    prefetchFlags = fields["prefetchFlags"]
                    cacheEnabled = fields["cacheEnabled"]
                    freshnessPolicy = fields["freshnessPolicy"]
                    cacheClearResult = fields["cacheClearResult"]
                    activeCandidateWindowId = fields["activeCandidateWindowId"]
                    returnedRootWindowId = fields["returnedRootWindowId"]
                    activeRootAccepted = fields["activeRootAccepted"]
                    fallbackReason = fields["fallbackReason"]
                    activeRootCallCount = fields["activeRootCallCount"]?.toLongOrNull()
                    activeRootTotalMs = fields["activeRootTotalMs"]?.toLongOrNull()
                    perWindowRootCallCount = fields["perWindowRootCallCount"]?.toLongOrNull()
                    perWindowRootTotalMs = fields["perWindowRootTotalMs"]?.toLongOrNull()
                    rootAcquisitionTotalMs = fields["rootAcquisitionTotalMs"]?.toLongOrNull()
                    rootAcquisitionMaxMs = fields["rootAcquisitionMaxMs"]?.toLongOrNull()
                    childAcquisitionTotalMs = fields["childAcquisitionTotalMs"]?.toLongOrNull()
                    childAcquisitionMaxMs = fields["childAcquisitionMaxMs"]?.toLongOrNull()
                    childAcquisitionCount = fields["childAcquisitionCount"]?.toLongOrNull()
                    localProcessingMs = fields["localProcessingMs"]?.toLongOrNull()
                    surfaceReason = reason
                    surfaceClassification = fields["surfaceClassification"]
                    surfaceMarkers = fields["surfaceMarkers"]
                    rootUnavailable = fields["rootUnavailable"]
                    walkTruncated = fields["walkTruncated"]
                    walkTruncationReasons = fields["walkTruncationReasons"]
                    slowWindowCalls = fields["slowWindowCalls"]
                    visitedNodeCount = fields["visitedNodeCount"]?.toLongOrNull()
                }
                "INSPECTION_MAIN_APPLY_POSTED" -> inspectionTimeline()?.apply {
                    diagnosticPreparationFinishedAtUptimeMs = fields["diagnosticPreparationFinishedAtUptimeMs"]?.toLongOrNull()
                    mainHandoffRequestedAtUptimeMs = fields["mainHandoffRequestedAtUptimeMs"]?.toLongOrNull()
                }
                "INSPECTION_MAIN_APPLY_STARTED" -> inspectionTimeline()?.apply {
                    mainApplyStartedAtUptimeMs = event.uptimeMs
                    diagnosticPreparationFinishedAtUptimeMs = fields["diagnosticPreparationFinishedAtUptimeMs"]?.toLongOrNull()
                    mainHandoffRequestedAtUptimeMs = fields["mainHandoffRequestedAtUptimeMs"]?.toLongOrNull()
                }
                "INSPECTION_APPLIED" -> {
                    attempt.inspectionsApplied += 1
                    inspectionTimeline()?.apply {
                        appliedAtUptimeMs = event.uptimeMs
                        visibilityEpochAtApply = fields["visibilityEpochAtApply"]?.toLongOrNull()
                        pendingRequestIdAtApply = fields["pendingRequestIdAtApply"]?.toLongOrNull()
                        surfaceClassification = fields["surfaceClassification"] ?: surfaceClassification
                        surfaceMarkers = fields["surfaceMarkers"] ?: surfaceMarkers
                    }
                }
                "INSPECTION_REJECTED" -> {
                    attempt.inspectionsRejected += 1
                    attempt.staleInspectionCount += 1
                    inspectionTimeline()?.rejectionReason = fields["rejectionReason"] ?: reason
                }
                "RETRY_SCHEDULED" -> attempt.retryScheduledCount += 1
                "RETRY_FIRED" -> attempt.retryFiredCount += 1
                "RETRY_CANCELLED" -> attempt.retryCancelledCount += 1
                "PENDING_REPLACED_AFTER_UNKNOWN" -> attempt.pendingRejectedAfterUnknown += 1
                "RETRY_SUPPRESSED_FOR_PENDING" -> attempt.retrySuppressedForPendingWork += 1
                "RETRY_BUDGET_EXHAUSTED_AWAITING" -> attempt.retryBudgetExhaustedWhileAwaiting += 1
                "AWAITING_MAIN_SURFACE" -> {
                    // Older records omit decision and describe UNKNOWN only.
                    // Recoverable OCCLUDED retains its identity, not an UNKNOWN count.
                    val unknown = fields["decision"] == null || fields["decision"] == "HIDDEN_UNKNOWN"
                    if (unknown && fields["overlayAttached"] == "false") {
                        attempt.unknownWhileHiddenCount += 1
                        val before = fields["visibilityEpochBefore"]?.toLongOrNull()
                        val after = fields["visibilityEpochAfter"]?.toLongOrNull()
                        if (before != null && after != null && before != after) attempt.unknownWhileHiddenEpochChanges += 1
                    }
                    inspectionTimeline()?.followupAction = fields["followupAction"]
                    when (fields["followupAction"]) {
                        "CONTINUE_PENDING" -> if (unknown) attempt.pendingPreservedAfterUnknown += 1
                        "SCHEDULE_FALLBACK", "WAIT_FOR_EVENT" -> Unit
                    }
                }
                "SHOW_FOR_ATTACH" -> event.showOperationId?.let { operationId ->
                    if (showEpisode() == null) {
                        while (attempt.shows.size >= 8) {
                            // Keep the first observed milestones, not just the
                            // newest add. A later no-draw reattach cannot erase
                            // the cycle's successful first presentation.
                            val pinned = listOfNotNull(
                                attempt.shows.firstOrNull(),
                                firstDrawEpisode(attempt) { it.firstRootDrawAtUptimeMs },
                                firstDrawEpisode(attempt) { it.firstShaderDrawAtUptimeMs },
                                firstDrawEpisode(attempt) { it.firstLiveDrawAtUptimeMs },
                            ).toSet()
                            attempt.shows.remove(attempt.shows.first { it !in pinned })
                            attempt.omittedShowEpisodes += 1
                        }
                        attempt.shows.addLast(
                            ShowEpisode(
                                operationId = operationId,
                                requestId = event.requestId,
                                attachGeneration = event.attachGeneration,
                                decisionAtUptimeMs = event.uptimeMs,
                                cause = inspectionTimeline(),
                            ),
                        )
                    }
                    attempt.showingInspectionRequestId = event.requestId
                    attempt.finalState = "SHOW_DECIDED"
                }
                "ADD_VIEW_BEGIN" -> showEpisode()?.addBeginAtUptimeMs = event.uptimeMs
                "ADD_VIEW_RETURN" -> showEpisode()?.let {
                    it.addReturnAtUptimeMs = event.uptimeMs
                    attempt.attachCount += 1
                    attempt.finalState = "ATTACHED"
                }
                "FIRST_ROOT_DRAW" -> showEpisode()?.let { if (it.firstRootDrawAtUptimeMs == null) it.firstRootDrawAtUptimeMs = event.uptimeMs }
                "FIRST_SHADER_DRAW" -> showEpisode()?.let { if (it.firstShaderDrawAtUptimeMs == null) it.firstShaderDrawAtUptimeMs = event.uptimeMs }
                "FIRST_CURRENT_MATERIAL_DRAW" -> showEpisode()?.let { if (it.firstCurrentMaterialDrawAtUptimeMs == null) it.firstCurrentMaterialDrawAtUptimeMs = event.uptimeMs }
                "FIRST_LIVE_DRAW" -> showEpisode()?.let { if (it.firstLiveDrawAtUptimeMs == null) it.firstLiveDrawAtUptimeMs = event.uptimeMs }
                "FRAME_COMMIT_CALLBACK_RECEIVED" -> showEpisode()?.let { if (it.frameCommitCallbackAtUptimeMs == null) it.frameCommitCallbackAtUptimeMs = event.uptimeMs }
                "BOOTSTRAP_DRAW" -> showEpisode()?.let { if (it.bootstrapDrawAtUptimeMs == null) it.bootstrapDrawAtUptimeMs = event.uptimeMs }
                "BOOTSTRAP_COMMIT_CALLBACK_RECEIVED" -> showEpisode()?.let { if (it.bootstrapCommitCallbackAtUptimeMs == null) it.bootstrapCommitCallbackAtUptimeMs = event.uptimeMs }
                "MATERIAL_LIVE_PROMOTED" -> showEpisode()?.let { if (it.livePromotedAtUptimeMs == null) it.livePromotedAtUptimeMs = event.uptimeMs }
                "ATTACHMENT_RENDER_SUMMARY" -> (showEpisode() ?: attempt.shows.lastOrNull {
                    event.attachGeneration != null && it.attachGeneration == event.attachGeneration
                })?.let {
                    it.renderSummary = fields.filterKeys { key -> key in RENDER_SUMMARY_KEYS }
                }
                "HIDE_DECIDED" -> event.hideOperationId?.let { operationId ->
                    if (hideEpisode() == null) {
                        // Eight retained shows can each own a withdrawal;
                        // one additional slot retains the latest detached
                        // terminal cleanup without displacing those causes.
                        while (attempt.hides.size >= 9) {
                            // A retained show keeps its matching actual
                            // withdrawal ahead of detached cleanup noise.
                            val discard = attempt.hides.firstOrNull { hide ->
                                hide.attachedBefore != true || attempt.shows.none {
                                    it.attachGeneration == hide.attachGeneration
                                }
                            } ?: attempt.hides.first()
                            attempt.hides.remove(discard)
                            attempt.omittedHideEpisodes += 1
                        }
                        attempt.hides.addLast(
                            HideEpisode(
                                operationId = operationId,
                                requestId = event.requestId,
                                attachGeneration = event.attachGeneration,
                                triggerReceivedAtUptimeMs = event.triggerReceivedUptimeMs,
                                decisionAtUptimeMs = event.uptimeMs,
                                cause = inspectionTimeline(),
                            ),
                        )
                    }
                    inspectionTimeline()
                    attempt.finalState = "HIDE_DECIDED"
                }
                "LOCAL_HIDE_BEGIN" -> hideEpisode()?.let { hide ->
                    val attached = when (fields["attachedBefore"]) {
                        "true" -> true
                        "false" -> false
                        else -> null
                    }
                    hide.attachedBefore = attached
                    if (attached == true && fields["awaitingSurfaceWithdrawal"] == "true") {
                        attempt.visibleWithdrawalCount += 1
                    }
                }
                "LOCAL_HIDE_APPLIED" -> hideEpisode()?.localHideAppliedAtUptimeMs = event.uptimeMs
                "ISOLATED_LAYER_HIDE_SUBMITTED" -> hideEpisode()?.let { hide ->
                    hide.isolatedLayerHideSubmittedAtUptimeMs = event.uptimeMs
                    hide.isolatedLayerTransactionApplied = fields["transactionApplied"]?.toBooleanStrictOrNull()
                }
                "REMOVE_VIEW_BEGIN" -> hideEpisode()?.removeBeginAtUptimeMs = event.uptimeMs
                "REMOVE_VIEW_RETURN" -> hideEpisode()?.let {
                    it.removeReturnAtUptimeMs = event.uptimeMs
                    if (it.attachedBefore == true) attempt.detachCount += 1
                    attempt.finalState = "DETACHED"
                }
                "DETACH_FAILED" -> hideEpisode()?.detachFailed = true
            }
            // The semantic spine has the same bounded operation ownership as
            // its episode records. It is not an unbounded historical cache.
            val obsoleteSpine = attempt.causalSpine.filter { milestone ->
                (milestone.showOperationId != null && attempt.shows.none { it.operationId == milestone.showOperationId }) ||
                    (milestone.hideOperationId != null && attempt.hides.none { it.operationId == milestone.hideOperationId })
            }
            attempt.causalSpine.removeAll(obsoleteSpine.toSet())
            attempt.omittedSpineEvents += obsoleteSpine.size
        }
    }

    private fun expireIfNeededLocked(context: Context, active: TimingCapture): Boolean {
        if (SystemClock.elapsedRealtime() - active.startedElapsedMs <= ACTIVE_CAPTURE_MS) return false
        active.endedElapsedMs = SystemClock.elapsedRealtime()
        active.state = "EXPIRED"
        if (ingress?.id == active.id) ingress = null
        appendLocked(active, "CAPTURE_EXPIRED", "timeout")
        persistLocked(context, active, force = true)
        active.frozenExport = snapshotForExportLocked(active)
        return true
    }

    private fun maybeCheckpointLocked(context: Context, active: TimingCapture) {
        if (SystemClock.elapsedRealtime() - active.lastCheckpointElapsedMs < CHECKPOINT_INTERVAL_MS) return
        persistLocked(context, active, force = false)
    }

    private fun persistLocked(context: Context, active: TimingCapture, force: Boolean) {
        if (!force && active.state != "REC") return
        active.checkpointCount += 1L
        active.lastCheckpointElapsedMs = SystemClock.elapsedRealtime()
        val id = active.id
        val generation = active.generation
        val persistedSeq = active.events.lastOrNull()?.seq ?: 0L
        active.queuedForPersistenceSeq = maxOf(active.queuedForPersistenceSeq, persistedSeq)
        // Capturing this structured copy is small and bounded. Report
        // formatting happens on the single writer so hide/attach paths never
        // hold captureLock while serialising hundreds of events.
        val snapshot = snapshotForExportLocked(active)
        captureWriter.execute {
            val report = formatReport(snapshot, recoveredFromDisk = false, exportLimitBytes = 32 * 1024)
            synchronized(captureLock) {
                // A later clear/new capture owns durability. A stale queued
                // checkpoint must not resurrect or replace it.
                if (capture?.generation != generation) return@execute
            }
            val committed = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putString(CAPTURE_REPORT, report)
                .putString(CAPTURE_ID, id)
                .putString(CAPTURE_STATE, snapshot.state)
                .putLong(CAPTURE_PERSISTED_SEQ, persistedSeq)
                .commit()
            if (committed) synchronized(captureLock) {
                capture?.takeIf { it.generation == generation }?.let { current ->
                    current.lastSuccessfullyPersistedSeq = maxOf(current.lastSuccessfullyPersistedSeq, persistedSeq)
                    current.unflushedTailMayBeMissing = current.events.lastOrNull()?.seq != current.lastSuccessfullyPersistedSeq
                }
            }
        }
    }

    private fun snapshotForExportLocked(active: TimingCapture): TimingCapture = active.copy(
        diagnosticDroppedRecords = active.diagnosticDroppedRecords + (lastIngress?.takeIf { it.id == active.id }?.skippedRecords?.get()?.toInt() ?: 0),
        hiddenNoopCount = lastIngress?.takeIf { it.id == active.id }?.hiddenNoops?.get()?.toInt() ?: active.hiddenNoopCount,
        diagnosticProducerTotalNs = lastIngress?.takeIf { it.id == active.id }?.producerTotalNs?.get() ?: active.diagnosticProducerTotalNs,
        diagnosticProducerMaxNs = lastIngress?.takeIf { it.id == active.id }?.producerMaxNs?.get() ?: active.diagnosticProducerMaxNs,
        legacyDiagnosticProducerTotalNs = lastIngress?.takeIf { it.id == active.id }?.legacyProducerTotalNs?.get() ?: active.legacyDiagnosticProducerTotalNs,
        diagnosticQueueOverflow = lastIngress?.takeIf { it.id == active.id }?.let { reduction.dropped.get() - it.droppedAtStart } ?: active.diagnosticQueueOverflow,
        diagnosticConsumerFailures = lastIngress?.takeIf { it.id == active.id }?.let { reduction.failed.get() - it.failuresAtStart } ?: active.diagnosticConsumerFailures,
        frozenExport = null,
        coldPreparation = coldPreparation?.let { it.copy(stages = LinkedHashMap(it.stages)) }
            ?: active.coldPreparation?.let { it.copy(stages = LinkedHashMap(it.stages)) },
        firstAttempt = active.firstAttempt?.let(::copyAttempt),
        events = ArrayDeque(active.events.map { it.copy(fields = it.fields.toMap()) }),
        attempts = ArrayDeque(active.attempts.map(::copyAttempt)),
    )

    private fun copyAttempt(attempt: TimingAttempt): TimingAttempt = attempt.copy(
        shows = ArrayDeque(attempt.shows.map { it.copy(cause = it.cause?.copy(), renderSummary = it.renderSummary.toMap()) }),
        hides = ArrayDeque(attempt.hides.map { it.copy(cause = it.cause?.copy()) }),
        inspections = LinkedHashMap(attempt.inspections.mapValues { (_, timeline) -> timeline.copy() }),
        causalSpine = ArrayDeque(attempt.causalSpine.map { it.copy(fields = it.fields.toMap()) }),
    )

    private fun ensureRecoveredLoadedLocked(context: Context) {
        if (capture != null || recovered != null) return
        val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val report = prefs.getString(CAPTURE_REPORT, null) ?: return
        recovered = RecoveredCapture(
            id = prefs.getString(CAPTURE_ID, "recovered") ?: "recovered",
            report = report,
            lastPersistedSeq = prefs.getLong(CAPTURE_PERSISTED_SEQ, 0L),
        )
    }

    /** Formats an already-copied capture outside captureLock. */
    private fun snapshotMap(active: TimingCapture?, restored: RecoveredCapture?): Map<String, Any?> {
        if (active == null) {
            return if (restored == null) mapOf(
                "available" to true, "captureState" to "IDLE", "captureId" to "-", "attemptCount" to 0,
                "eventsRecorded" to 0, "eventsRetained" to 0, "eventsEvicted" to 0, "eventsCoalesced" to 0,
                "diagnosticDroppedRecords" to 0,
                "captureMode" to KeyguardDiagnosticCaptureMode.LIGHT.name,
                "report" to "",
            ) else mapOf(
                "available" to true, "captureState" to "RECOVERED", "captureId" to restored.id,
                "attemptCount" to "NA", "eventsRecorded" to "NA", "eventsRetained" to "NA", "eventsEvicted" to "NA",
                "eventsCoalesced" to "NA", "recoveredFromDisk" to true,
                "diagnosticDroppedRecords" to "NA",
                "captureMode" to "RECOVERED",
                "report" to recoveredReport(restored.report),
            )
        }
        val report = formatReport(active, recoveredFromDisk = false, exportLimitBytes = 32 * 1024)
        return mapOf(
            "available" to true,
            "captureState" to active.state,
            "captureId" to active.id,
            "attemptCount" to active.attempts.size,
            "eventsRecorded" to (active.nextSeq - 1L),
            "eventsRetained" to active.events.size,
            "eventsEvicted" to active.eventsEvicted,
            "eventsCoalesced" to active.eventsCoalesced,
            "diagnosticDroppedRecords" to active.diagnosticDroppedRecords,
            "captureMode" to active.captureMode.name,
            "recoveredFromDisk" to false,
            "report" to report,
        )
    }

    private fun recoveredReport(report: String): String {
        var restored = report.replaceFirst(Regex("captureState=[^\\n]*"), "captureState=RECOVERED")
            .replaceFirst("recoveredFromDisk=false", "recoveredFromDisk=true")
        // Earlier installed builds persisted unbudgeted headers. Such an old
        // report cannot acquire missing evidence on recovery. Keep complete
        // lines and state its loss explicitly instead of violating Copy's cap.
        if (restored.toByteArray(Charsets.UTF_8).size > 32 * 1024 - 64) {
            val lines = restored.lineSequence().filter { it != "END_FLUVI_KEYGUARD_TIMING_CAPTURE_V1" }.toList()
            var used = 0
            val kept = lines.takeWhile {
                val next = (it + '\n').toByteArray(Charsets.UTF_8).size
                KeyguardExportBudget.canAppend(used, next, 32 * 1024 - 512).also { fits -> if (fits) used += next }
            }
            restored = kept.joinToString("\n", postfix = "\n")
                .replace("causalSpineComplete=true", "causalSpineComplete=false") +
                "legacyRecoveredEvidenceTruncated=true omittedRecoveredLines=${lines.size - kept.size} recoverySelection=legacyPrefix\nEND_FLUVI_KEYGUARD_TIMING_CAPTURE_V1\n"
        }
        return withExportBytes(restored)
    }

    private fun withExportBytes(report: String): String {
        val sizeLine = Regex("exportBytes=[^\\n]*")
        var sized = report.replaceFirst(sizeLine, "exportBytes=0")
        repeat(3) { sized = report.replaceFirst(sizeLine, "exportBytes=${sized.toByteArray(Charsets.UTF_8).size}") }
        return sized
    }

    private fun formatReport(active: TimingCapture, recoveredFromDisk: Boolean, exportLimitBytes: Int): String {
        val attemptsForCausalEvidence = active.attempts.toList().let { attempts ->
            (listOfNotNull(active.firstAttempt ?: attempts.firstOrNull()) + attempts.takeLast(3)).distinctBy { it.id }
        }
        val header = buildString {
            appendLine("FLUVI_KEYGUARD_TIMING_CAPTURE_V1")
            appendLine("build=${active.build}")
            appendLine("buildMode=${active.buildMode}")
            appendLine("captureId=${active.id}")
            appendLine("captureState=${active.state}")
            appendLine("captureMode=${active.captureMode.name}")
            appendLine("processInstance=${active.processInstanceId}")
            appendLine("pid=${active.pid}")
            appendLine("androidApi=${Build.VERSION.SDK_INT}")
            appendLine("manufacturer=${technicalValue(Build.MANUFACTURER)}")
            appendLine("model=${technicalValue(Build.MODEL)}")
            appendLine("startedAt=${SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ", Locale.US).format(Date(active.startedWallMs))}")
            val durationEndElapsedMs = active.endedElapsedMs ?: SystemClock.elapsedRealtime()
            appendLine("durationElapsedMs=${durationEndElapsedMs - active.startedElapsedMs}")
            active.configuration.forEach { (key, value) -> appendLine("$key=$value") }
            appendLine("CLOCKS")
            appendLine("uptimeMs=monotonic_excludes_deep_sleep")
            appendLine("elapsedMs=monotonic_includes_deep_sleep")
            appendLine("systemWakeVisualStart=UNOBSERVED")
            appendLine("systemUnlockAnimationStart=UNOBSERVED")
            appendLine("physicalOverlayPresentation=UNOBSERVED")
            appendLine("physicalOverlayRemoval=UNOBSERVED")
            appendLine("frameCommitMeaning=callback_receipt_not_physical_presentation liveFrameCommit=UNOBSERVED")
            appendLine("drawObservationMeaning=NO_DRAW_OBSERVED_is_not_proof_of_no_rendering")
            appendLine("drawGapClock=System.nanoTime frameNs=Choreographer cpuNs=threadCPU cbOut=ownedCallbackWorkEndBeforeProbe submit=CPUCanvasCall")
            appendLine("workKinds=1:systemGate,2:inspectionApply,3:diagnosticProducer nestedWorkNotAdditive=true workCoverage=ownedScopesOnly drawObserverNs=bookkeepingOnly")
            appendLine("COLD_PREPARATION")
            val cold = active.coldPreparation
            if (cold == null) {
                appendLine("state=UNOBSERVED")
            } else {
                appendLine("serviceSession=${cold.serviceSession} processInstance=${cold.processInstanceId} observedBeforeCapture=${cold.stages.values.any { it < active.startedUptimeMs }}")
                listOf(
                    "SERVICE_CONNECTED", "SETTINGS_LOAD_START", "SETTINGS_LOAD_END", "PROFILE_LOAD_START", "PROFILE_LOAD_END",
                    "ROOT_PREPARE_START", "ROOT_PREPARE_END", "MATERIAL_PREPARE_REQUESTED", "MATERIAL_ARTIFACT_READY",
                    "MATERIAL_PROGRAM_PREPARED", "MATERIAL_PROGRAM_PROMOTED", "MATERIAL_GPU_PREPARATION_STARTED", "MATERIAL_GPU_PREPARATION_COMPLETED", "MATERIAL_GPU_PREPARATION_FAILED", "FIRST_ATTACH", "FIRST_ROOT_DRAW", "BOOTSTRAP_DRAW", "BOOTSTRAP_COMMIT_CALLBACK_RECEIVED", "MATERIAL_LIVE_PROMOTED", "FIRST_SHADER_DRAW",
                    "FIRST_CURRENT_MATERIAL_DRAW", "FIRST_LIVE_DRAW", "FRAME_COMMIT_CALLBACK_RECEIVED",
                ).forEach { stage -> appendLine("$stage=${cold.stages[stage] ?: "UNOBSERVED"}") }
            }
            appendLine("RETENTION")
            appendLine("eventsRecorded=${active.nextSeq - 1L}")
            appendLine("eventsRetained=${active.events.size}")
            appendLine("eventsEvicted=${active.eventsEvicted}")
            appendLine("eventsCoalesced=${active.eventsCoalesced}")
            appendLine("exportTruncated=false")
            appendLine("exportBytes=PENDING")
            appendLine("recoveredFromDisk=$recoveredFromDisk")
            appendLine("hiddenNoopCount=${active.hiddenNoopCount}")
            appendLine("queuedForPersistenceSeq=${active.queuedForPersistenceSeq}")
            appendLine("lastPersistedSeq=${active.lastSuccessfullyPersistedSeq}")
            appendLine("unflushedTailMayBeMissing=${active.unflushedTailMayBeMissing || active.events.lastOrNull()?.seq != active.lastSuccessfullyPersistedSeq}")
            appendLine("DIAGNOSTIC_COST")
            appendLine("diagnosticReductionThread=dedicatedWorker")
            appendLine("captureLockMeasurementOwner=diagnosticConsumer")
            appendLine("captureLockWaitNs=${active.captureLockWaitNs}")
            appendLine("captureLockHeldNs=${active.captureLockHeldNs}")
            appendLine("diagnosticProducerTotalNs=${active.diagnosticProducerTotalNs}")
            appendLine("diagnosticProducerMaxNs=${active.diagnosticProducerMaxNs}")
            appendLine("legacyDiagnosticProducerTotalNs=${active.legacyDiagnosticProducerTotalNs}")
            appendLine("legacyWriteCount=${active.legacyWriteCount}")
            appendLine("checkpointCount=${active.checkpointCount}")
            appendLine("diagnosticDroppedRecords=${active.diagnosticDroppedRecords}")
            appendLine("diagnosticQueueOverflow=${active.diagnosticQueueOverflow}")
            appendLine("diagnosticConsumerFailures=${active.diagnosticConsumerFailures}")
            appendLine("nativeDrawObservations=callbackAndCanvas flutterBuildRasterTiming=N/A")
        }
        val footer = "END_FLUVI_KEYGUARD_TIMING_CAPTURE_V1\n"
        val events = active.events.toList()
        // Header, section labels, omission metadata and footer all consume
        // the same UTF-8 budget. Protected evidence is compact, not exempt.
        val selected = linkedMapOf<String, String>()
        val omittedRecords = mutableListOf<String>()
        val incompleteAttempts = linkedSetOf<Long>()
        var bytes = (header + footer + "ATTEMPT_SUMMARIES\nEPISODES\nDRAW_GAPS\nCAUSAL_SPINES\nEVENTS\n").toByteArray(Charsets.UTF_8).size
        val metadataReserve = 2_048
        val contentLimit = exportLimitBytes - metadataReserve - 64 // recovery/header byte-count replacements
        fun select(id: String, text: String, attemptId: Long? = null): Boolean {
            val size = text.toByteArray(Charsets.UTF_8).size
            if (!KeyguardExportBudget.canAppend(bytes, size, contentLimit)) {
                omittedRecords += id
                attemptId?.let(incompleteAttempts::add)
                return false
            }
            selected[id] = text
            bytes += size
            return true
        }
        // First reserve every selected attempt's short cycle summary. Then
        // retain whole episode/cause blocks round-robin, so one pathological
        // attempt cannot silently replace the other wakes' evidence.
        attemptsForCausalEvidence.forEach { attempt ->
            select("a${attempt.id}:summary", attemptSummary(attempt), attempt.id)
        }
        val episodeBlocks = attemptsForCausalEvidence.associateWith(::episodeRecords)
        repeat(episodeBlocks.values.maxOfOrNull { it.size } ?: 0) { index ->
            attemptsForCausalEvidence.forEach { attempt ->
                episodeBlocks.getValue(attempt).getOrNull(index)?.let { (id, text) -> select(id, text, attempt.id) }
            }
        }
        // Gap attribution is optional evidence, never a prerequisite for the
        // retained show's/withdrawal's causal block or its completeness.
        // Admit the worst orb gap from each episode before later samples.
        // Balance episodes across attempts so a busy cold attempt cannot
        // consume all optional evidence before the warm wakes are visited.
        val gapBlocks = mutableListOf<List<Pair<String, String>>>()
        repeat(attemptsForCausalEvidence.maxOfOrNull { it.shows.size } ?: 0) { episodeIndex ->
            attemptsForCausalEvidence.forEach { attempt ->
                val episode = attempt.shows.getOrNull(episodeIndex) ?: return@forEach
                val episodeId = "a${attempt.id}:show${episode.operationId}"
                val records = mutableListOf<Pair<String, String>>()
                DRAW_GAP_KEYS.forEach { key ->
                    val surface = if (key == "orbDrawGaps") "orb" else "background"
                    episode.renderSummary[key]?.lineSequence()?.filter(String::isNotBlank)?.forEachIndexed { index, line ->
                        val id = "$episodeId:drawGap:$surface:$index"
                        if (episodeId !in selected) omittedRecords += id
                        else records += id to " DRAW_GAP attempt=${attempt.id} showOp=${episode.operationId} attach=${episode.attachGeneration ?: "NA"} surface=$surface sample=$index $line\n"
                    }
                }
                gapBlocks += records
            }
        }
        repeat(gapBlocks.maxOfOrNull { it.size } ?: 0) { sampleIndex ->
            gapBlocks.forEach { records ->
                records.getOrNull(sampleIndex)?.let { (id, text) -> select(id, text) }
            }
        }
        // Original milestone rows are optional because the complete episode
        // records above carry their timestamps and operation ownership.
        attemptsForCausalEvidence.forEach { attempt ->
            val lines = attempt.causalSpine.joinToString("") { " attempt=${attempt.id} ${it.toLine()}\n" }
            select("a${attempt.id}:spineRows", lines)
        }
        val keptEvents = linkedSetOf<TimingEvent>()
        attemptsForCausalEvidence.asReversed().forEach { attempt ->
            val group = events.filter { it.attemptId == attempt.id }
            if (select("a${attempt.id}:raw", group.joinToString("") { it.toLine() + "\n" })) keptEvents.addAll(group)
        }
        val unassigned = events.filter { it.attemptId == null }
        if (select("unassigned:raw", unassigned.joinToString("") { it.toLine() + "\n" })) keptEvents.addAll(unassigned)
        val omittedEvents = events.filterNot(keptEvents::contains)
        val omittedAttempts = omittedEvents.mapNotNull { it.attemptId }.distinct().sorted()
        val metadata = buildString {
            appendLine("retainedAttemptIds=${attemptsForCausalEvidence.joinToString(",") { it.id.toString() }}")
            appendLine("omittedEventLines=${omittedEvents.size}")
            appendLine("omittedAttemptIds=${omittedAttempts.joinToString(",").ifBlank { "none" }}")
            appendLine("omittedSeqs=${compactSequenceRanges(omittedEvents.map { it.seq }.sorted(), 384)}")
            appendLine("omittedEvidenceRecords=${omittedRecords.size}")
            val criticalOmissions = omittedRecords.filterNot { it.endsWith(":raw") || it.endsWith(":spineRows") || ":drawGap:" in it }
            val omittedGaps = omittedRecords.filter { ":drawGap:" in it }
            appendLine("omittedCriticalRecordIds=${compactRecordIds(criticalOmissions, 384)}")
            appendLine("drawGapEvidenceExported=${selected.keys.count { ":drawGap:" in it }} drawGapEvidenceOmitted=${omittedGaps.size}")
            appendLine("omittedDrawGapRecordIds=${compactRecordIds(omittedGaps, 384)}")
            appendLine("incompleteExportAttemptIds=${incompleteAttempts.joinToString(",").ifBlank { "none" }}")
            appendLine("rawEventsTruncated=${omittedEvents.isNotEmpty()} rawOmissionDoesNotMeanNoDraw=true")
        }
        check(metadata.toByteArray(Charsets.UTF_8).size <= metadataReserve)
        val report = buildString {
            append(header.replace("exportTruncated=false", "exportTruncated=${omittedEvents.isNotEmpty() || omittedRecords.isNotEmpty()}"))
            append(metadata)
            appendLine("ATTEMPT_SUMMARIES")
            selected.filterKeys { it.endsWith(":summary") }.forEach { (id, text) ->
                val attemptId = id.substringAfter('a').substringBefore(':').toLong()
                append(if (attemptId in incompleteAttempts) text.replace("causalSpineComplete=true", "causalSpineComplete=false") else text)
            }
            appendLine("EPISODES")
            selected.filterKeys { !it.endsWith(":summary") && !it.endsWith(":spineRows") && !it.endsWith(":raw") && ":drawGap:" !in it }.values.forEach(::append)
            appendLine("DRAW_GAPS")
            selected.filterKeys { ":drawGap:" in it }.values.forEach(::append)
            appendLine("CAUSAL_SPINES")
            selected.filterKeys { it.endsWith(":spineRows") }.values.forEach(::append)
            appendLine("EVENTS")
            keptEvents.sortedBy { it.seq }.forEach { appendLine(it.toLine()) }
            append(footer)
        }
        val sized = withExportBytes(report)
        check(sized.toByteArray(Charsets.UTF_8).size <= exportLimitBytes)
        return sized
    }

    private fun firstDrawEpisode(attempt: TimingAttempt, time: (ShowEpisode) -> Long?): ShowEpisode? =
        attempt.shows.filter { time(it) != null }.minByOrNull { time(it)!! }

    private fun firstPresentation(attempt: TimingAttempt): ShowEpisode? =
        firstDrawEpisode(attempt) { it.firstLiveDrawAtUptimeMs }
            ?: firstDrawEpisode(attempt) { it.firstRootDrawAtUptimeMs }
            ?: attempt.shows.firstOrNull { it.addReturnAtUptimeMs != null }
            ?: attempt.shows.firstOrNull()

    private fun delta(end: Long?, start: Long?): String = when {
        end == null || start == null -> "NA(missingEndpoint)"
        end < start -> "INVALID_EVENT_ORDER"
        else -> (end - start).toString()
    }

    private fun actualWithdrawal(attempt: TimingAttempt, show: ShowEpisode): HideEpisode? =
        attempt.hides.firstOrNull {
            show.attachGeneration != null && it.attachGeneration == show.attachGeneration &&
                it.attachedBefore == true && it.removeReturnAtUptimeMs != null &&
                it.decisionAtUptimeMs >= show.decisionAtUptimeMs
        }

    /** Compact cycle aggregates are independent of every attachment's own
     * evidence. Missing/omitted episodes never overwrite the earliest draw. */
    private fun attemptSummary(attempt: TimingAttempt): String = buildString {
        val show = firstPresentation(attempt)
        val firstRoot = firstDrawEpisode(attempt) { it.firstRootDrawAtUptimeMs }
        val firstShader = firstDrawEpisode(attempt) { it.firstShaderDrawAtUptimeMs }
        val firstLive = firstDrawEpisode(attempt) { it.firstLiveDrawAtUptimeMs }
        val withdrawal = show?.let { actualWithdrawal(attempt, it) }
            ?: attempt.hides.lastOrNull { it.attachedBefore == true && it.removeReturnAtUptimeMs != null }
        val showing = show?.cause
        val firstInspection = attempt.firstInspectionRequestId?.let(attempt.inspections::get)
        appendLine("attemptId=${attempt.id} wakeSource=${attempt.wakeSource} wakeCycleStartedAt=${attempt.startedUptimeMs} screenOnReceivedAt=${attempt.screenOnReceivedAtUptimeMs ?: "NA"} presentationMode=${attempt.presentationMode} session=${attempt.serviceSession} wake=${attempt.wakeEpoch}")
        appendLine(" firstInspectionRequestId=${attempt.firstInspectionRequestId ?: "NA"} showingInspectionRequestId=${show?.requestId ?: "NA"} requestsReceived=${attempt.requestsReceived} requestsReplaced=${attempt.requestsReplaced} inspectionsStarted=${attempt.inspectionsStarted} inspectionsApplied=${attempt.inspectionsApplied} inspectionsRejected=${attempt.inspectionsRejected} staleInspectionCount=${attempt.staleInspectionCount}")
        appendLine(" retries=scheduled:${attempt.retryScheduledCount},fired:${attempt.retryFiredCount},cancelled:${attempt.retryCancelledCount},pending:${(attempt.retryScheduledCount - attempt.retryFiredCount - attempt.retryCancelledCount).coerceAtLeast(0)} attachCount=${attempt.attachCount} detachCount=${attempt.detachCount} finalState=${attempt.finalState}")
        appendLine(" awaiting=unknownWhileHidden:${attempt.unknownWhileHiddenCount},unknownWhileHiddenEpochChanges:${attempt.unknownWhileHiddenEpochChanges},pendingPreservedAfterUnknown:${attempt.pendingPreservedAfterUnknown},pendingRejectedAfterUnknown:${attempt.pendingRejectedAfterUnknown},visibleWithdrawalCount:${attempt.visibleWithdrawalCount},retrySuppressedForPendingWork:${attempt.retrySuppressedForPendingWork},retryBudgetExhaustedWhileAwaiting:${attempt.retryBudgetExhaustedWhileAwaiting}")
        appendLine(" cycleFirstRootShowOp=${firstRoot?.operationId ?: "NA"} cycleFirstShaderShowOp=${firstShader?.operationId ?: "NA"} cycleFirstLiveShowOp=${firstLive?.operationId ?: "NA"} firstRootDrawObserved=${firstRoot != null} firstShaderDrawObserved=${firstShader != null}")
        appendLine(" cycleToFirstRootDrawMs=${delta(firstRoot?.firstRootDrawAtUptimeMs, attempt.startedUptimeMs)} cycleToFirstShaderDrawMs=${delta(firstShader?.firstShaderDrawAtUptimeMs, attempt.startedUptimeMs)} cycleToFirstLiveDrawMs=${delta(firstLive?.firstLiveDrawAtUptimeMs, attempt.startedUptimeMs)}")
        appendLine(" screenOnToFirstRootDrawMs=${delta(firstRoot?.firstRootDrawAtUptimeMs, attempt.screenOnReceivedAtUptimeMs)} screenOnToFirstShaderDrawMs=${delta(firstShader?.firstShaderDrawAtUptimeMs, attempt.screenOnReceivedAtUptimeMs)} screenOnToFirstLiveDrawMs=${delta(firstLive?.firstLiveDrawAtUptimeMs, attempt.screenOnReceivedAtUptimeMs)} wakeCallbackToFirstRootDrawMs=${delta(firstRoot?.firstRootDrawAtUptimeMs, attempt.startedUptimeMs)} wakeCallbackToFirstShaderDrawMs=${delta(firstShader?.firstShaderDrawAtUptimeMs, attempt.startedUptimeMs)}")
        appendLine(" queueMs=${delta(showing?.startedAtUptimeMs, showing?.queuedAtUptimeMs)} inspectionTotalMs=${delta(showing?.finishedAtUptimeMs, showing?.startedAtUptimeMs)} inspectionFinishToHandoffMs=${delta(showing?.mainHandoffRequestedAtUptimeMs, showing?.finishedAtUptimeMs)} handoffToMainEntryMs=${delta(showing?.mainApplyStartedAtUptimeMs, showing?.mainHandoffRequestedAtUptimeMs)} mainEntryToDecisionMs=${delta(show?.decisionAtUptimeMs, showing?.mainApplyStartedAtUptimeMs)} showDecisionToAddViewBeginMs=${delta(show?.addBeginAtUptimeMs, show?.decisionAtUptimeMs)}")
        appendLine(" actualWithdrawalHideOp=${withdrawal?.operationId ?: "NA"} terminalCleanupHideOp=${attempt.hides.lastOrNull()?.operationId ?: "NA"} triggerToLocalHideMs=${delta(withdrawal?.localHideAppliedAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)} triggerToLayerHideSubmitMs=${delta(withdrawal?.isolatedLayerHideSubmittedAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)} triggerToRemoveReturnMs=${delta(withdrawal?.removeReturnAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)} hideDecisionToLocalHideMs=${delta(withdrawal?.localHideAppliedAtUptimeMs, withdrawal?.decisionAtUptimeMs)} localHideToLayerHideSubmitMs=${delta(withdrawal?.isolatedLayerHideSubmittedAtUptimeMs, withdrawal?.localHideAppliedAtUptimeMs)} layerHideSubmitToRemoveBeginMs=${delta(withdrawal?.removeBeginAtUptimeMs, withdrawal?.isolatedLayerHideSubmittedAtUptimeMs)} removeViewCallMs=${delta(withdrawal?.removeReturnAtUptimeMs, withdrawal?.removeBeginAtUptimeMs)} hideSignalToDecisionMs=${delta(withdrawal?.decisionAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)} hideSignalToRemoveReturnMs=${delta(withdrawal?.removeReturnAtUptimeMs, withdrawal?.triggerReceivedAtUptimeMs)}")
        appendLine(" causalSpineComplete=${causalSpineComplete(attempt)} causalSpineIndependentOfRawRing=true retainedShowEpisodes=${attempt.shows.size} retainedHideEpisodes=${attempt.hides.size} omittedShowEpisodes=${attempt.omittedShowEpisodes} omittedHideEpisodes=${attempt.omittedHideEpisodes} omittedSpineEvents=${attempt.omittedSpineEvents}")
        append(inspectionCause("FIRST_INSPECTION", firstInspection))
    }

    private fun inspectionCause(label: String, cause: InspectionTimeline?): String = buildString {
        append(" $label req=${cause?.requestId ?: "NA"}")
        if (cause == null) { appendLine(" evidence=MISSING_REQUEST"); return@buildString }
        append(" trigger=${cause.trigger ?: "NA"} callbackReceived=${cause.triggerReceivedUptimeMs ?: "NA(missingTrigger)"} eventTime=${cause.eventTimeUptimeMs ?: "NA(sourceUnavailable)"}")
        append(" queued=${cause.queuedAtUptimeMs ?: "NA"} started=${cause.startedAtUptimeMs ?: "NA"} finished=${cause.finishedAtUptimeMs ?: "NA"} handoff=${cause.mainHandoffRequestedAtUptimeMs ?: "NA"} mainApply=${cause.mainApplyStartedAtUptimeMs ?: "NA"} applied=${cause.appliedAtUptimeMs ?: "NA"}")
        append(" authorityAtStart=${cause.authorityCurrentAtStart ?: "NA"} visibilityEpochAtRequest=${cause.visibilityEpochAtRequest ?: "NA"} visibilityEpochAtApply=${cause.visibilityEpochAtApply ?: "NA"} pendingAtApply=${cause.pendingRequestIdAtApply ?: "NA"}")
        append(" classification=${cause.surfaceClassification ?: "NA"} reason=${cause.surfaceReason ?: "NA"} markers=${cause.surfaceMarkers ?: "NA"} rootUnavailable=${cause.rootUnavailable ?: "NA"} walkTruncated=${cause.walkTruncated ?: "NA"} truncationReasons=${cause.walkTruncationReasons ?: "UNOBSERVED"} visited=${cause.visitedNodeCount ?: "NA"}")
        append(" reader=${cause.readerStrategy ?: "NA"} freshness=${cause.freshnessPolicy ?: "NA"} cacheClear=${cause.cacheClearResult ?: "NA"} fallback=${cause.fallbackReason ?: "NA"}")
        append(" activeCandidate=${cause.activeCandidateWindowId ?: "NA"} returnedRoot=${cause.returnedRootWindowId ?: "NA"} activeAccepted=${cause.activeRootAccepted ?: "NA"} activeRootMs=${cause.activeRootTotalMs ?: "NA"} perWindowRootMs=${cause.perWindowRootTotalMs ?: "NA"} childCalls=${cause.childAcquisitionCount ?: "NA"} childMs=${cause.childAcquisitionTotalMs ?: "NA"} childMaxMs=${cause.childAcquisitionMaxMs ?: "NA"} localMs=${cause.localProcessingMs ?: "NA"}")
        appendLine(" slowCalls=${cause.slowWindowCalls ?: "NA"} rejected=${cause.rejectionReason ?: "NA"} followup=${cause.followupAction ?: "NA"}")
    }

    private fun episodeRecords(attempt: TimingAttempt): List<Pair<String, String>> {
        val first = firstPresentation(attempt)
        val pairedHides = mutableSetOf<Long>()
        val records = attempt.shows.map { episode ->
            val withdrawal = actualWithdrawal(attempt, episode)
            withdrawal?.let { pairedHides += it.operationId }
            "a${attempt.id}:show${episode.operationId}" to buildString {
                appendLine(" EPISODE attempt=${attempt.id} showOp=${episode.operationId} attach=${episode.attachGeneration ?: "NA"} req=${episode.requestId ?: "NA"} decision=${episode.decisionAtUptimeMs} add=${episode.addBeginAtUptimeMs ?: "NA"}/${episode.addReturnAtUptimeMs ?: "NA"} root=${episode.firstRootDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} shader=${episode.firstShaderDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} currentMaterial=${episode.firstCurrentMaterialDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} live=${episode.firstLiveDrawAtUptimeMs ?: "NO_DRAW_OBSERVED"} bootstrapDrawAt=${episode.bootstrapDrawAtUptimeMs ?: "NO_BOOTSTRAP_DRAW_OBSERVED"} bootstrapCommit=${episode.bootstrapCommitCallbackAtUptimeMs ?: "UNOBSERVED"} promoted=${episode.livePromotedAtUptimeMs ?: "UNOBSERVED"} frameCommit=${episode.frameCommitCallbackAtUptimeMs ?: "UNOBSERVED"} withdrawal=${withdrawal?.operationId ?: "NA"} localHide=${withdrawal?.localHideAppliedAtUptimeMs ?: "NA"} layerHideSubmit=${withdrawal?.isolatedLayerHideSubmittedAtUptimeMs ?: "NA"}/${withdrawal?.isolatedLayerTransactionApplied ?: "NA"} removeReturn=${withdrawal?.removeReturnAtUptimeMs ?: "NA"}")
                append(inspectionCause(if (episode == first) "SHOWING_INSPECTION" else "SHOW_CAUSE", episode.cause))
                if (withdrawal != null) {
                    append(hideRecord(withdrawal))
                    append(inspectionCause(if (episode == first) "ACTUAL_WITHDRAWAL_INSPECTION" else "WITHDRAWAL_CAUSE", withdrawal.cause))
                }
                append(" RENDER attach=${episode.attachGeneration ?: "NA"} showOp=${episode.operationId}")
                if (episode.renderSummary.isEmpty()) append(" evidence=UNOBSERVED")
                else episode.renderSummary.filterKeys { it !in DRAW_GAP_KEYS }.forEach { (key, value) -> append(" $key=$value") }
                appendLine()
            }
        }.toMutableList()
        attempt.hides.filter { it.operationId !in pairedHides }.forEach { hide ->
            records += "a${attempt.id}:hide${hide.operationId}" to
                (hideRecord(hide) + inspectionCause("HIDE_CAUSE", hide.cause))
        }
        return records
    }

    private fun hideRecord(hide: HideEpisode): String =
        " WITHDRAWAL hideOp=${hide.operationId} attach=${hide.attachGeneration ?: "NA"} req=${hide.requestId ?: "NA"} attachedBefore=${hide.attachedBefore ?: "NA"} trigger=${hide.triggerReceivedAtUptimeMs ?: "NA(missingTrigger)"} decision=${hide.decisionAtUptimeMs} local=${hide.localHideAppliedAtUptimeMs ?: "NA"} layerSubmit=${hide.isolatedLayerHideSubmittedAtUptimeMs ?: "NA"}/${hide.isolatedLayerTransactionApplied ?: "NA"} remove=${hide.removeBeginAtUptimeMs ?: "NA"}/${hide.removeReturnAtUptimeMs ?: "NA"} detachFailed=${hide.detachFailed}\n"

    private fun causalSpineComplete(attempt: TimingAttempt): Boolean {
        fun has(stage: String, show: Long? = null, hide: Long? = null, attach: Long? = null) = attempt.causalSpine.any {
            it.stage == stage && it.showOperationId == show && it.hideOperationId == hide && it.attachGeneration == attach
        }
        fun completeCause(cause: InspectionTimeline?) = cause != null &&
            cause.queuedAtUptimeMs != null && cause.startedAtUptimeMs != null &&
            cause.finishedAtUptimeMs != null && cause.surfaceClassification != null
        return has("WAKE_ATTEMPT") && attempt.omittedShowEpisodes == 0 && attempt.omittedHideEpisodes == 0 &&
            attempt.shows.all { show ->
                has("SHOW_FOR_ATTACH", show.operationId, attach = show.attachGeneration) &&
                    (show.addReturnAtUptimeMs != null && has("ADD_VIEW_RETURN", show.operationId, attach = show.attachGeneration) ||
                        has("ATTACH_FAILED", show.operationId, attach = show.attachGeneration)) &&
                    (show.requestId == null || (show.cause?.requestId == show.requestId && completeCause(show.cause)))
            } && attempt.hides.filter { it.attachedBefore == true }.all { hide ->
                has("HIDE_DECIDED", hide = hide.operationId, attach = hide.attachGeneration) &&
                    (hide.removeReturnAtUptimeMs != null && has("REMOVE_VIEW_RETURN", hide = hide.operationId, attach = hide.attachGeneration) || hide.detachFailed) &&
                    (hide.requestId == null || (hide.cause?.requestId == hide.requestId && completeCause(hide.cause)))
            }
    }

    /** Never truncate a comma-separated sequence in the middle of an ID. */
    private fun compactRecordIds(ids: List<String>, maxCharacters: Int): String {
        if (ids.isEmpty()) return "none"
        val output = StringBuilder()
        ids.forEachIndexed { index, id ->
            if (output.length + id.length + 24 > maxCharacters) {
                output.append(",more:").append(ids.size - index)
                return output.toString()
            }
            if (output.isNotEmpty()) output.append(',')
            output.append(id)
        }
        return output.toString()
    }

    private fun compactSequenceRanges(sequences: List<Long>, maxCharacters: Int): String {
        if (sequences.isEmpty()) return "none"
        val tokens = mutableListOf<String>()
        var start = sequences.first()
        var previous = start
        fun flush() {
            tokens += if (start == previous) start.toString() else "$start-$previous"
        }
        sequences.drop(1).forEach { current ->
            if (current == previous + 1L) previous = current
            else {
                flush()
                start = current
                previous = current
            }
        }
        flush()
        val result = StringBuilder()
        tokens.forEach { token ->
            val prefix = if (result.isEmpty()) "" else ","
            if (result.length + prefix.length + token.length > maxCharacters) {
                if (result.isNotEmpty()) result.append(",")
                result.append("more")
                return result.toString()
            }
            result.append(prefix).append(token)
        }
        return result.toString()
    }

    private val technicalSeparators = Regex("[\\r\\n|=]")
    private fun technicalValue(value: Any): String = value.toString()
        .replace(technicalSeparators, "_")
        .take(160)

    fun beginLockAttempt(context: Context, session: Long, wakeEpoch: Long) {
        beginLockAttempt(context, session, wakeEpoch, "unknown")
    }

    fun record(context: Context, event: String, reason: String, attached: Boolean? = null) {
        val startedAtNs = SystemClock.elapsedRealtimeNanos()
        latestLegacyReason = reason
        val token = ingress
        val observedElapsedMs = SystemClock.elapsedRealtime()
        reduction.offer {
        val state = "$event|$reason|${attached ?: "-"}"
        // LIGHT is the default performance capture. Keep the existing
        // in-memory legacy summary current, but do not turn every ordinary
        // event into a background SharedPreferences write. FULL and normal
        // operation retain the durable legacy behavior.
        val suppressLegacyPersistence = token?.mode == KeyguardDiagnosticCaptureMode.LIGHT
        val schedule = synchronized(legacyLock) {
            ensureLegacyLoadedLocked(context)
            if (legacy.lastEvent == state) {
                legacy.lastEventCount += 1
            } else {
                while (legacy.events.size >= MAX_LEGACY_EVENTS) legacy.events.removeFirst()
                legacy.events.addLast("$observedElapsedMs|$state")
                legacy.lastEvent = state
                legacy.lastEventCount = 1
            }
            legacy.lastReason = reason
            legacy.revision += 1L
            if (!suppressLegacyPersistence) queueLegacyWriteLocked() else false
        }
        if (schedule) persistLegacyAsync(context.applicationContext)
        }
        val elapsedNs = (SystemClock.elapsedRealtimeNanos() - startedAtNs).coerceAtLeast(0L)
        token?.legacyProducerTotalNs?.addAndGet(elapsedNs)
    }

    fun attach(context: Context, result: String) {
        latestLegacyAttach = result
        reduction.offer {
        val schedule = synchronized(legacyLock) {
            ensureLegacyLoadedLocked(context)
            legacy.lastAttach = result
            legacy.revision += 1L
            queueLegacyWriteLocked()
        }
        if (schedule) persistLegacyAsync(context.applicationContext)
        }
    }

    fun lastReason(context: Context): String = latestLegacyReason ?: synchronized(legacyLock) {
        ensureLegacyLoadedLocked(context)
        legacy.lastReason
    }

    fun lastAttachResult(context: Context): String = latestLegacyAttach ?: synchronized(legacyLock) {
        ensureLegacyLoadedLocked(context)
        legacy.lastAttach
    }

    fun summary(context: Context): String = synchronized(legacyLock) {
        ensureLegacyLoadedLocked(context)
        val events = legacy.events.joinToString("\n")
        if (legacy.lastEventCount > 1) "$events\nrepeat=${legacy.lastEventCount}" else events
    }

    private fun resetLegacyAttempt(context: Context, line: String, attempt: String) {
        val schedule = synchronized(legacyLock) {
            ensureLegacyLoadedLocked(context)
            legacy.events.clear()
            legacy.events.addLast(line)
            legacy.lastReason = attempt
            legacy.attempt = attempt
            legacy.lastEvent = null
            legacy.lastEventCount = 0
            legacy.revision += 1L
            queueLegacyWriteLocked()
        }
        if (schedule) persistLegacyAsync(context.applicationContext)
    }

    private fun ensureLegacyLoadedLocked(context: Context) {
        if (legacy.loaded) return
        val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        prefs.getString(EVENTS, "").orEmpty().lineSequence().filter(String::isNotBlank)
            .toList().takeLast(MAX_LEGACY_EVENTS).forEach { legacy.events.addLast(it) }
        legacy.lastReason = prefs.getString(LAST_REASON, legacy.lastReason) ?: legacy.lastReason
        legacy.lastAttach = prefs.getString(LAST_ATTACH, legacy.lastAttach) ?: legacy.lastAttach
        legacy.attempt = prefs.getString(ATTEMPT, null)
        legacy.lastEvent = prefs.getString(LAST_EVENT, null)
        legacy.lastEventCount = prefs.getInt(LAST_EVENT_COUNT, 1)
        legacy.loaded = true
    }

    /** @return whether this caller acquired the one bounded writer slot. */
    private fun queueLegacyWriteLocked(): Boolean {
        if (legacy.writeQueued) return false
        legacy.writeQueued = true
        return true
    }

    /** Runs only on the existing serial diagnostic writer.  The visibility
     * caller has already released [legacyLock], and no event causes a second
     * queued writer while this snapshot is pending. */
    private fun persistLegacyAsync(applicationContext: Context) {
        captureWriter.execute {
            val snapshot = synchronized(legacyLock) {
                LegacySnapshot(
                    events = legacy.events.joinToString("\n"),
                    lastReason = legacy.lastReason,
                    lastAttach = legacy.lastAttach,
                    attempt = legacy.attempt,
                    lastEvent = legacy.lastEvent,
                    lastEventCount = legacy.lastEventCount,
                    revision = legacy.revision,
                )
            }
            val committed = applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putString(EVENTS, snapshot.events)
                .putString(LAST_REASON, snapshot.lastReason)
                .putString(LAST_ATTACH, snapshot.lastAttach)
                .putString(ATTEMPT, snapshot.attempt)
                .putString(LAST_EVENT, snapshot.lastEvent)
                .putInt(LAST_EVENT_COUNT, snapshot.lastEventCount)
                .commit()
            var scheduleAgain = false
            synchronized(legacyLock) {
                if (committed) legacy.persistedRevision = maxOf(legacy.persistedRevision, snapshot.revision)
                legacy.writeQueued = false
                // A successful write may have raced newer in-memory events.
                // Queue exactly one successor; a failed write remains dirty
                // and is retried by the next ordinary diagnostic mutation.
                if (committed && legacy.revision > legacy.persistedRevision) {
                    legacy.writeQueued = true
                    scheduleAgain = true
                }
            }
            if (committed) synchronized(captureLock) {
                capture?.takeIf { it.state == "REC" }?.let { it.legacyWriteCount += 1L }
            }
            if (scheduleAgain) persistLegacyAsync(applicationContext)
        }
    }
}

internal object FluviKeyguardCardServiceRegistry {
    @Volatile var connected: Boolean = false
        private set
    @Volatile private var service: FluviKeyguardCardService? = null
    internal fun serviceForInstrumentation(): FluviKeyguardCardService? = service

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

    fun notifyLayoutChanged(settings: KeyguardCardSettings) {
        service?.onLayoutChangedFromApplication(settings)
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
            "requestedRenderer" to "not-connected",
            "activeRenderer" to "not-connected",
            "hardwareAccelerated" to false,
            "shaderCreationCount" to 0,
            "animationStartCount" to 0,
            "animationStopCount" to 0,
            "drawCount" to 0,
            "frameCallbackCount" to 0,
            "frameIntervalP50" to 0,
            "frameIntervalP95" to 0,
            "largeFrameGapCount" to 0,
            "lastRendererFailure" to null,
            "shaderCompileAttempts" to 0,
            "shaderCompileSuccesses" to 0,
            "shaderCompileFailures" to 0,
            "onDrawCount" to 0,
            "shaderDrawCount" to 0,
            "fallbackDrawCount" to 0,
            "phaseAdvanceCount" to 0,
            "transitionCompletedCount" to 0,
            "lastFailureStage" to null,
            "lastFailureClass" to null,
            "lastFailureMessage" to null,
            "shaderSourceHash" to null,
            "generatedAgslHash" to null,
            "adapterVersion" to null,
            "effectId" to null,
        )
}
