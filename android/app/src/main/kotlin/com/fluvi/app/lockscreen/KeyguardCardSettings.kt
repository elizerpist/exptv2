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
    private const val CAPTURE_REPORT = "timingCapture.report"
    private const val CAPTURE_ID = "timingCapture.id"
    private const val CAPTURE_STATE = "timingCapture.state"
    private const val CAPTURE_PERSISTED_SEQ = "timingCapture.persistedSeq"
    private const val MAX_EVENTS = 512
    private const val MAX_EVENT_BYTES = 128 * 1024
    private const val MAX_ATTEMPTS = 10
    private const val ACTIVE_CAPTURE_MS = 5 * 60 * 1000L
    private const val CHECKPOINT_INTERVAL_MS = 12_000L
    private val captureLock = Any()
    private val captureWriter = Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "fluvi-keyguard-diagnostic-writer").apply { isDaemon = true }
    }
    private var capture: TimingCapture? = null
    private var recovered: RecoveredCapture? = null
    private var nextCaptureGeneration = 0L

    /** A compact event is intentionally technical-only.  It never accepts a
     * node text, content description, financial value, or foreign package
     * name.  All formatting is deferred until a user asks for a snapshot. */
    private data class TimingEvent(
        val seq: Long,
        val uptimeMs: Long,
        val elapsedMs: Long,
        val attemptId: Long?,
        val serviceSession: Long?,
        val wakeEpoch: Long?,
        val requestId: Long?,
        val attachGeneration: Long?,
        val stage: String,
        val reason: String,
        val fields: Map<String, String>,
        var firstUptimeMs: Long = uptimeMs,
        var lastUptimeMs: Long = uptimeMs,
        var count: Int = 1,
    ) {
        fun byteSize(): Int = toLine().toByteArray(Charsets.UTF_8).size

        fun canCoalesce(other: TimingEvent): Boolean =
            stage == other.stage && reason == other.reason && attemptId == other.attemptId &&
                requestId == other.requestId && attachGeneration == other.attachGeneration &&
                fields == other.fields && stage !in NON_COALESCIBLE_STAGES

        fun toLine(): String = buildString {
            append("seq=").append(seq)
            append(" up=").append(uptimeMs)
            append(" el=").append(elapsedMs)
            attemptId?.let { append(" attempt=").append(it) }
            serviceSession?.let { append(" session=").append(it) }
            wakeEpoch?.let { append(" wake=").append(it) }
            requestId?.let { append(" req=").append(it) }
            attachGeneration?.let { append(" attach=").append(it) }
            append(" stage=").append(stage)
            append(" reason=").append(reason)
            if (count > 1) append(" count=").append(count)
                .append(" firstUp=").append(firstUptimeMs)
                .append(" lastUp=").append(lastUptimeMs)
            fields.forEach { (key, value) -> append(' ').append(key).append('=').append(value) }
        }
    }

    private data class TimingAttempt(
        val id: Long,
        val serviceSession: Long,
        val wakeEpoch: Long,
        val startedUptimeMs: Long,
        var presentationMode: String = "NA",
        var wakeSource: String = "NA",
        var firstInspectionRequestId: Long? = null,
        var showingInspectionRequestId: Long? = null,
        var inspectionCount: Int = 0,
        var staleInspectionCount: Int = 0,
        var retryScheduledCount: Int = 0,
        var retryFiredCount: Int = 0,
        var retryCancelledCount: Int = 0,
        var attachCount: Int = 0,
        var detachCount: Int = 0,
        var firstRootDrawAt: Long? = null,
        var firstShaderDrawAt: Long? = null,
        var showDecisionAt: Long? = null,
        var addViewBeginAt: Long? = null,
        var addViewReturnAt: Long? = null,
        var hideSignalAt: Long? = null,
        var hideDecisionAt: Long? = null,
        var removeViewReturnAt: Long? = null,
        var finalState: String = "INCOMPLETE",
    )

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
        var state: String = "REC",
        var nextSeq: Long = 1L,
        var nextAttemptId: Long = 1L,
        var retainedBytes: Int = 0,
        var eventsEvicted: Int = 0,
        var eventsCoalesced: Int = 0,
        var lastPersistedSeq: Long = 0L,
        var lastCheckpointElapsedMs: Long = startedElapsedMs,
        var unflushedTailMayBeMissing: Boolean = false,
        val events: ArrayDeque<TimingEvent> = ArrayDeque(),
        val attempts: ArrayDeque<TimingAttempt> = ArrayDeque(),
    )

    private data class RecoveredCapture(
        val id: String,
        val report: String,
        val lastPersistedSeq: Long,
    )

    private val NON_COALESCIBLE_STAGES = setOf(
        "SHOW_DECIDED", "ADD_VIEW_BEGIN", "ADD_VIEW_RETURN", "FIRST_ROOT_DRAW",
        "FIRST_SHADER_DRAW", "HIDE_DECIDED", "LOCAL_HIDE_BEGIN", "LOCAL_HIDE_APPLIED",
        "REMOVE_VIEW_BEGIN", "REMOVE_VIEW_RETURN", "RETRY_SCHEDULED", "RETRY_FIRED",
        "RETRY_CANCELLED", "INSPECTION_QUEUED", "INSPECTION_COALESCED",
        "INSPECTION_STARTED", "INSPECTION_FINISHED", "INSPECTION_APPLIED", "INSPECTION_REJECTED",
    )

    /** Starts a capture owned by Android, not by a Flutter widget or stream.
     * The only Flutter supplied values are immutable build labels for the
     * human-readable header. */
    fun startCapture(context: Context, build: String?, buildMode: String?): Map<String, Any?> = synchronized(captureLock) {
        ensureRecoveredLoadedLocked(context)
        val settings = FluviKeyguardCardSettings.read(context)
        val runtime = FluviRuntimeCoordinator.status(context)
        val id = UUID.randomUUID().toString()
        val nowUp = SystemClock.uptimeMillis()
        val nowElapsed = SystemClock.elapsedRealtime()
        val created = TimingCapture(
            id = id,
            generation = ++nextCaptureGeneration,
            build = build?.takeIf { it.isNotBlank() } ?: "unknown",
            buildMode = buildMode?.takeIf { it.isNotBlank() } ?: "unknown",
            processInstanceId = "${Process.myPid()}-${UUID.randomUUID().toString().substring(0, 8)}",
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
        )
        capture = created
        recovered = null
        appendLocked(created, "CAPTURE_STARTED", "user", fields = mapOf("source" to "runtimeMethod"))
        persistLocked(context, created, force = true)
        snapshotLocked(context, created)
    }

    fun freezeCapture(context: Context): Map<String, Any?> = synchronized(captureLock) {
        ensureRecoveredLoadedLocked(context)
        val active = capture
        if (active != null && active.state == "REC") {
            active.state = "FROZEN"
            appendLocked(active, "CAPTURE_FROZEN", "user")
            persistLocked(context, active, force = true)
        }
        snapshotLocked(context, active)
    }

    fun captureSnapshot(context: Context): Map<String, Any?> = synchronized(captureLock) {
        ensureRecoveredLoadedLocked(context)
        val active = capture
        if (active?.state == "REC") expireIfNeededLocked(context, active)
        snapshotLocked(context, capture)
    }

    fun clearCapture(context: Context): Map<String, Any?> = synchronized(captureLock) {
        capture = null
        recovered = null
        val clearGeneration = ++nextCaptureGeneration
        captureWriter.execute {
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
    }

    /** Called at the first line of each new wake attempt. Existing active
     * capture history is deliberately retained; only the legacy compact
     * status line is replaced for the ordinary settings screen. */
    fun beginLockAttempt(context: Context, session: Long, wakeEpoch: Long, source: String = "unknown") {
        val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val line = "${SystemClock.elapsedRealtime()}|KG|WAKE|session=$session|wake=$wakeEpoch"
        prefs.edit()
            .putString(EVENTS, line)
            .putString(ATTEMPT, "session=$session|wake=$wakeEpoch")
            .remove(LAST_EVENT)
            .putInt(LAST_EVENT_COUNT, 0)
            .apply()
        synchronized(captureLock) {
            val active = capture ?: return@synchronized
            if (active.state != "REC" || expireIfNeededLocked(context, active)) return@synchronized
            while (active.attempts.size >= MAX_ATTEMPTS) active.attempts.removeFirst()
            val attempt = TimingAttempt(active.nextAttemptId++, session, wakeEpoch, SystemClock.uptimeMillis())
            attempt.presentationMode = active.configuration["presentationMode"] ?: "NA"
            attempt.wakeSource = source
            active.attempts.addLast(attempt)
            appendLocked(active, "WAKE_ATTEMPT", "begin", serviceSession = session, wakeEpoch = wakeEpoch)
        }
    }

    /** Hot-path record. It only mutates a small in-memory ring while capture
     * is active; persistence is checkpointed separately and never happens in
     * an onDraw callback. */
    fun captureEvent(
        context: Context,
        stage: String,
        reason: String,
        serviceSession: Long? = null,
        wakeEpoch: Long? = null,
        requestId: Long? = null,
        attachGeneration: Long? = null,
        observedUptimeMs: Long? = null,
        fields: Map<String, Any?> = emptyMap(),
    ) = synchronized(captureLock) {
        val active = capture ?: return@synchronized
        if (active.state != "REC" || expireIfNeededLocked(context, active)) return@synchronized
        appendLocked(
            active = active,
            stage = stage,
            reason = reason,
            serviceSession = serviceSession,
            wakeEpoch = wakeEpoch,
            requestId = requestId,
            attachGeneration = attachGeneration,
            observedUptimeMs = observedUptimeMs,
            fields = fields.mapNotNull { (key, value) -> value?.let { key to technicalValue(it) } }.toMap(),
        )
        maybeCheckpointLocked(context, active)
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
        fields: Map<String, String> = emptyMap(),
    ) {
        val event = TimingEvent(
            seq = active.nextSeq++,
            uptimeMs = observedUptimeMs ?: SystemClock.uptimeMillis(),
            elapsedMs = SystemClock.elapsedRealtime(),
            attemptId = active.attempts.toList().lastOrNull { it.serviceSession == serviceSession && it.wakeEpoch == wakeEpoch }?.id,
            serviceSession = serviceSession,
            wakeEpoch = wakeEpoch,
            requestId = requestId,
            attachGeneration = attachGeneration,
            stage = stage,
            reason = reason,
            fields = fields,
        )
        val last = active.events.lastOrNull()
        if (last != null && last.canCoalesce(event)) {
            last.lastUptimeMs = event.uptimeMs
            last.count += 1
            active.eventsCoalesced += 1
            return
        }
        val size = event.byteSize()
        while (active.events.isNotEmpty() && (active.events.size >= MAX_EVENTS || active.retainedBytes + size > MAX_EVENT_BYTES)) {
            active.retainedBytes -= active.events.removeFirst().byteSize()
            active.eventsEvicted += 1
        }
        active.events.addLast(event)
        active.retainedBytes += size
        active.attempts.toList().lastOrNull { it.id == event.attemptId }?.let { attempt ->
            when (stage) {
                "INSPECTION_QUEUED" -> {
                    attempt.inspectionCount += 1
                    if (attempt.firstInspectionRequestId == null) attempt.firstInspectionRequestId = requestId
                }
                "INSPECTION_REJECTED" -> attempt.staleInspectionCount += 1
                "RETRY_SCHEDULED" -> attempt.retryScheduledCount += 1
                "RETRY_FIRED" -> attempt.retryFiredCount += 1
                "RETRY_CANCELLED" -> attempt.retryCancelledCount += 1
                "SHOW_DECIDED" -> {
                    attempt.showingInspectionRequestId = requestId
                    attempt.showDecisionAt = event.uptimeMs
                    attempt.finalState = "SHOW_DECIDED"
                }
                "ADD_VIEW_BEGIN" -> attempt.addViewBeginAt = event.uptimeMs
                "ADD_VIEW_RETURN" -> { attempt.addViewReturnAt = event.uptimeMs; attempt.attachCount += 1; attempt.finalState = "ATTACHED" }
                "FIRST_ROOT_DRAW" -> attempt.firstRootDrawAt = event.uptimeMs
                "FIRST_SHADER_DRAW" -> attempt.firstShaderDrawAt = event.uptimeMs
                "HIDE_DECIDED" -> { attempt.hideDecisionAt = event.uptimeMs; attempt.finalState = "HIDE_DECIDED" }
                "REMOVE_VIEW_RETURN" -> { attempt.removeViewReturnAt = event.uptimeMs; attempt.detachCount += 1; attempt.finalState = "DETACHED" }
            }
            if (stage in setOf("SCREEN_OFF_RECEIVED", "USER_PRESENT_RECEIVED", "ACCESSIBILITY_EVENT") && attempt.hideSignalAt == null) {
                attempt.hideSignalAt = event.uptimeMs
            }
        }
    }

    private fun expireIfNeededLocked(context: Context, active: TimingCapture): Boolean {
        if (SystemClock.elapsedRealtime() - active.startedElapsedMs <= ACTIVE_CAPTURE_MS) return false
        active.state = "EXPIRED"
        appendLocked(active, "CAPTURE_EXPIRED", "timeout")
        persistLocked(context, active, force = true)
        return true
    }

    private fun maybeCheckpointLocked(context: Context, active: TimingCapture) {
        if (SystemClock.elapsedRealtime() - active.lastCheckpointElapsedMs < CHECKPOINT_INTERVAL_MS) return
        persistLocked(context, active, force = false)
    }

    private fun persistLocked(context: Context, active: TimingCapture, force: Boolean) {
        if (!force && active.state != "REC") return
        active.lastCheckpointElapsedMs = SystemClock.elapsedRealtime()
        val id = active.id
        val generation = active.generation
        val persistedSeq = active.events.lastOrNull()?.seq ?: 0L
        active.lastPersistedSeq = persistedSeq
        val report = formatReport(active, recoveredFromDisk = false, exportLimitBytes = Int.MAX_VALUE)
        captureWriter.execute {
            synchronized(captureLock) {
                // A later clear/new capture owns durability. A stale queued
                // checkpoint must not resurrect or replace it.
                if (capture?.generation != generation) return@execute
            }
            context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putString(CAPTURE_REPORT, report)
                .putString(CAPTURE_ID, id)
                .putString(CAPTURE_STATE, active.state)
                .putLong(CAPTURE_PERSISTED_SEQ, persistedSeq)
                .commit()
        }
    }

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

    private fun snapshotLocked(context: Context, active: TimingCapture?): Map<String, Any?> {
        if (active == null) {
            val restored = recovered
            return if (restored == null) mapOf(
                "available" to true, "captureState" to "IDLE", "captureId" to "-", "attemptCount" to 0,
                "eventsRecorded" to 0, "eventsRetained" to 0, "eventsEvicted" to 0, "eventsCoalesced" to 0,
                "report" to "",
            ) else mapOf(
                "available" to true, "captureState" to "RECOVERED", "captureId" to restored.id,
                "attemptCount" to "NA", "eventsRecorded" to "NA", "eventsRetained" to "NA", "eventsEvicted" to "NA",
                "eventsCoalesced" to "NA", "recoveredFromDisk" to true,
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
            "recoveredFromDisk" to false,
            "report" to report,
        )
    }

    private fun recoveredReport(report: String): String = report
        .replaceFirst(Regex("captureState=[^\\n]*"), "captureState=RECOVERED")
        .replaceFirst("RETENTION\n", "RETENTION\nrecoveredFromDisk=true\n")

    private fun formatReport(active: TimingCapture, recoveredFromDisk: Boolean, exportLimitBytes: Int): String {
        val header = buildString {
            appendLine("FLUVI_KEYGUARD_TIMING_CAPTURE_V1")
            appendLine("build=${active.build}")
            appendLine("buildMode=${active.buildMode}")
            appendLine("captureId=${active.id}")
            appendLine("captureState=${active.state}")
            appendLine("processInstance=${active.processInstanceId}")
            appendLine("pid=${active.pid}")
            appendLine("androidApi=${Build.VERSION.SDK_INT}")
            appendLine("manufacturer=${Build.MANUFACTURER}")
            appendLine("model=${Build.MODEL}")
            appendLine("startedAt=${SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ", Locale.US).format(Date(active.startedWallMs))}")
            appendLine("durationElapsedMs=${SystemClock.elapsedRealtime() - active.startedElapsedMs}")
            active.configuration.forEach { (key, value) -> appendLine("$key=$value") }
            appendLine("CLOCKS")
            appendLine("uptimeMs=monotonic_excludes_deep_sleep")
            appendLine("elapsedMs=monotonic_includes_deep_sleep")
            appendLine("systemWakeVisualStart=UNOBSERVED")
            appendLine("systemUnlockAnimationStart=UNOBSERVED")
            appendLine("physicalOverlayPresentation=UNOBSERVED")
            appendLine("physicalOverlayRemoval=UNOBSERVED")
            appendLine("RETENTION")
            appendLine("eventsRecorded=${active.nextSeq - 1L}")
            appendLine("eventsRetained=${active.events.size}")
            appendLine("eventsEvicted=${active.eventsEvicted}")
            appendLine("eventsCoalesced=${active.eventsCoalesced}")
            appendLine("exportTruncated=false")
            appendLine("recoveredFromDisk=$recoveredFromDisk")
            appendLine("lastPersistedSeq=${active.lastPersistedSeq}")
            appendLine("unflushedTailMayBeMissing=${active.state == "REC" || active.unflushedTailMayBeMissing}")
            appendLine("ATTEMPT_SUMMARIES")
            active.attempts.forEach { append(attemptSummary(it)) }
            appendLine("EVENTS")
        }
        val footer = "END_FLUVI_KEYGUARD_TIMING_CAPTURE_V1\n"
        val eventLines = active.events.map { it.toLine() }
        val kept = ArrayList<String>()
        var bytes = (header + footer).toByteArray(Charsets.UTF_8).size
        // Preserve whole newest events first: a failure near the end must not
        // disappear silently under the export size cap.
        for (line in eventLines.asReversed()) {
            val size = (line + '\n').toByteArray(Charsets.UTF_8).size
            if (bytes + size > exportLimitBytes) break
            kept.add(line)
            bytes += size
        }
        kept.reverse()
        val omitted = eventLines.size - kept.size
        val retention = if (omitted == 0) header else header.replace("exportTruncated=false", "exportTruncated=true\nomittedEventLines=$omitted")
        return buildString {
            append(retention)
            kept.forEach { appendLine(it) }
            append(footer)
        }
    }

    private fun attemptSummary(attempt: TimingAttempt): String = buildString {
        fun delta(end: Long?, start: Long?): String = if (end == null || start == null) "NA(missingEndpoint)" else (end - start).toString()
        appendLine("attemptId=${attempt.id} wakeSource=${attempt.wakeSource} presentationMode=${attempt.presentationMode} session=${attempt.serviceSession} wake=${attempt.wakeEpoch}")
        appendLine(" firstInspectionRequestId=${attempt.firstInspectionRequestId ?: "NA"} showingInspectionRequestId=${attempt.showingInspectionRequestId ?: "NA"} inspectionCount=${attempt.inspectionCount} staleInspectionCount=${attempt.staleInspectionCount}")
        appendLine(" retries=scheduled:${attempt.retryScheduledCount},fired:${attempt.retryFiredCount},cancelled:${attempt.retryCancelledCount} attachCount=${attempt.attachCount} detachCount=${attempt.detachCount} finalState=${attempt.finalState}")
        appendLine(" wakeCallbackToFirstRootDrawMs=${delta(attempt.firstRootDrawAt, attempt.startedUptimeMs)} wakeCallbackToFirstShaderDrawMs=${delta(attempt.firstShaderDrawAt, attempt.startedUptimeMs)}")
        appendLine(" showDecisionToAddViewBeginMs=${delta(attempt.addViewBeginAt, attempt.showDecisionAt)} addViewCallMs=${delta(attempt.addViewReturnAt, attempt.addViewBeginAt)} addViewReturnToFirstRootDrawMs=${delta(attempt.firstRootDrawAt, attempt.addViewReturnAt)}")
        appendLine(" hideSignalToDecisionMs=${delta(attempt.hideDecisionAt, attempt.hideSignalAt)} hideDecisionToLocalHideMs=NA(notSeparatelyObserved) hideSignalToRemoveReturnMs=${delta(attempt.removeViewReturnAt, attempt.hideSignalAt)}")
        appendLine(
            " firstRootDrawObserved=${attempt.firstRootDrawAt != null} " +
                "firstRootDrawStatus=${if (attempt.firstRootDrawAt == null) "NO_DRAW_OBSERVED" else "OBSERVED"} " +
                "firstShaderDrawObserved=${attempt.firstShaderDrawAt != null} " +
                "firstShaderDrawStatus=${if (attempt.firstShaderDrawAt == null) "NO_DRAW_OBSERVED" else "OBSERVED"}",
        )
    }

    private fun technicalValue(value: Any): String = value.toString()
        .replace(Regex("[\\r\\n|=]"), "_")
        .take(160)

    fun beginLockAttempt(context: Context, session: Long, wakeEpoch: Long) {
        beginLockAttempt(context, session, wakeEpoch, "unknown")
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
