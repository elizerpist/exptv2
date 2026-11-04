package com.fluvi.app.runtime

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Shader
import com.fluvi.core.FluviCoreFactory
import com.fluvi.core.model.FluviFinancialLimitPeriod
import com.fluvi.core.model.FluviFinancialLimitTarget
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.query.FluviPeriodSelection
import com.fluvi.core.query.FluviQueryScope
import java.text.NumberFormat
import java.time.LocalDate
import java.time.YearMonth
import java.util.Locale
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/** Durable, Activity-independent lock-screen focus. The default is off; the
 * suggested Budget/month/expense selection intentionally waits for a real
 * category choice before it can replace an already visible card. */
internal data class FluviLockScreenCardConfiguration(
    val enabled: Boolean = false,
    val mode: Mode = Mode.budget,
    val timeAxis: TimeAxis = TimeAxis.month,
    val direction: Direction = Direction.expense,
    val categoryId: String? = null,
    val eventLine: EventLine = EventLine.related,
    val privacy: Privacy = Privacy.discreet,
    val generation: Long = 0,
) {
    enum class Mode { mind, balance, budget }
    enum class TimeAxis { sum, year, month, day }
    enum class Direction { income, expense }
    enum class EventLine { related, processed, hidden }
    enum class Privacy { discreet, full }

    val isValid: Boolean get() = mode != Mode.budget || !categoryId.isNullOrBlank()
}

internal class FluviLockScreenCardStore(context: Context) {
    private val preferences = context.applicationContext.getSharedPreferences(
        "fluvi_lock_screen_card",
        Context.MODE_PRIVATE,
    )

    fun read(): FluviLockScreenCardConfiguration = runCatching {
        FluviLockScreenCardConfiguration(
            enabled = preferences.getBoolean("enabled", false),
            mode = enum("mode", FluviLockScreenCardConfiguration.Mode.budget),
            timeAxis = enum("axis", FluviLockScreenCardConfiguration.TimeAxis.month),
            direction = enum("direction", FluviLockScreenCardConfiguration.Direction.expense),
            categoryId = preferences.getString("categoryId", null),
            eventLine = enum("eventLine", FluviLockScreenCardConfiguration.EventLine.related),
            privacy = enum("privacy", FluviLockScreenCardConfiguration.Privacy.discreet),
            generation = preferences.getLong("generation", 0L),
        )
    }.getOrDefault(FluviLockScreenCardConfiguration())

    fun save(next: FluviLockScreenCardConfiguration): FluviLockScreenCardConfiguration {
        val committed = next.copy(generation = read().generation + 1)
        preferences.edit()
            .putBoolean("enabled", committed.enabled)
            .putString("mode", committed.mode.name)
            .putString("axis", committed.timeAxis.name)
            .putString("direction", committed.direction.name)
            .putString("categoryId", committed.categoryId)
            .putString("eventLine", committed.eventLine.name)
            .putString("privacy", committed.privacy.name)
            .putLong("generation", committed.generation)
            .apply()
        return committed
    }

    fun saveFromMap(values: Map<*, *>): FluviLockScreenCardConfiguration {
        val previous = read()
        fun text(name: String, fallback: String) = (values[name] as? String) ?: fallback
        return save(
            previous.copy(
                enabled = values["enabled"] as? Boolean ?: previous.enabled,
                mode = enumValue(text("mode", previous.mode.name), previous.mode),
                timeAxis = enumValue(text("timeAxis", previous.timeAxis.name), previous.timeAxis),
                direction = enumValue(text("direction", previous.direction.name), previous.direction),
                categoryId = if (values.containsKey("categoryId")) {
                    values["categoryId"] as? String
                } else {
                    previous.categoryId
                },
                eventLine = enumValue(text("eventLine", previous.eventLine.name), previous.eventLine),
                privacy = enumValue(text("privacy", previous.privacy.name), previous.privacy),
            ),
        )
    }

    fun toMap(configuration: FluviLockScreenCardConfiguration): Map<String, Any?> = mapOf(
        "enabled" to configuration.enabled,
        "mode" to configuration.mode.name,
        "timeAxis" to configuration.timeAxis.name,
        "direction" to configuration.direction.name,
        "categoryId" to configuration.categoryId,
        "eventLine" to configuration.eventLine.name,
        "privacy" to configuration.privacy.name,
        "generation" to configuration.generation,
        "valid" to configuration.isValid,
    )

    private inline fun <reified T : Enum<T>> enum(name: String, fallback: T): T =
        enumValue(preferences.getString(name, null), fallback)

    private inline fun <reified T : Enum<T>> enumValue(value: String?, fallback: T): T =
        enumValues<T>().firstOrNull { it.name == value } ?: fallback
}

/** The persisted render model lets service startForeground remain immediate.
 * Full values are app-private storage; public Android notification fields are
 * derived afresh from this model and never include them in discreet mode. */
internal data class FluviLockScreenCardContent(
    val focus: String,
    val primary: String,
    val secondary: String,
    val event: String?,
    val eventLabel: String?,
    val accentColor: Int,
    val available: Boolean,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "focus" to focus,
        "primary" to primary,
        "secondary" to secondary,
        "event" to event,
        "eventLabel" to eventLabel,
        "accentColor" to accentColor,
        "available" to available,
    )
}

internal class FluviLockScreenCardContentStore(context: Context) {
    private val preferences = context.applicationContext.getSharedPreferences(
        "fluvi_lock_screen_card_content",
        Context.MODE_PRIVATE,
    )

    fun read(): FluviLockScreenCardContent? {
        if (!preferences.getBoolean("available", false)) return null
        return FluviLockScreenCardContent(
            focus = preferences.getString("focus", "Fluvi") ?: "Fluvi",
            primary = preferences.getString("primary", "") ?: "",
            secondary = preferences.getString("secondary", "") ?: "",
            event = preferences.getString("event", null),
            eventLabel = preferences.getString("eventLabel", null),
            accentColor = preferences.getInt("accent", Color.rgb(33, 68, 130)),
            available = true,
        )
    }

    fun write(content: FluviLockScreenCardContent) {
        preferences.edit()
            .putBoolean("available", content.available)
            .putString("focus", content.focus)
            .putString("primary", content.primary)
            .putString("secondary", content.secondary)
            .putString("event", content.event)
            .putString("eventLabel", content.eventLabel)
            .putInt("accent", content.accentColor)
            .apply()
    }
}

internal object FluviLockScreenCardCoordinator {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    @Volatile private var observing = false

    fun configuration(context: Context): FluviLockScreenCardConfiguration =
        FluviLockScreenCardStore(context).read()

    fun update(context: Context, values: Map<*, *>): FluviLockScreenCardConfiguration {
        val next = FluviLockScreenCardStore(context).saveFromMap(values)
        if (!next.enabled || next.privacy == FluviLockScreenCardConfiguration.Privacy.discreet) {
            // Privacy tightening and disabling take effect synchronously from
            // cache; no outstanding full-data task may republish stale text.
            FluviRuntimeNotificationController.publish(context, FluviRuntimeCoordinator.status(context))
        }
        if (next.enabled && next.isValid) refreshAsync(context, "configuration", next.generation)
        else FluviRuntimeNotificationController.reconcileVisible(context, FluviRuntimeCoordinator.status(context))
        reconcileCoreObserver(context)
        return next
    }

    fun refreshAsync(context: Context, reason: String, expectedGeneration: Long? = null) {
        val application = context.applicationContext
        val expected = expectedGeneration ?: configuration(application).generation
        scope.launch {
            val configuration = configuration(application)
            if (!configuration.enabled || !configuration.isValid || configuration.generation != expected) return@launch
            val content = runCatching { resolve(application, configuration) }.getOrNull() ?: return@launch
            if (configuration(application).generation != expected) return@launch
            FluviLockScreenCardContentStore(application).write(content)
            FluviRuntimeNotificationController.publish(application, FluviRuntimeCoordinator.status(application))
        }
    }

    fun reconcileCoreObserver(context: Context) {
        if (observing || !configuration(context).enabled) return
        observing = true
        val application = context.applicationContext
        scope.launch {
            val core = FluviCoreFactory.create(application)
            try {
                core.query.observeCoreRevision().collectLatest {
                    refreshAsync(application, "coreRevision")
                }
            } finally {
                core.close()
                observing = false
            }
        }
    }

    suspend fun preview(context: Context): Map<String, Any?> = withContext(Dispatchers.IO) {
        val configuration = configuration(context)
        val categories = categories(context, configuration.direction)
        val cached = FluviLockScreenCardContentStore(context).read()
        val content = if (configuration.enabled && configuration.isValid) {
            runCatching { resolve(context, configuration) }.getOrNull() ?: cached
        } else {
            cached
        }
        mapOf(
            "configuration" to FluviLockScreenCardStore(context).toMap(configuration),
            "content" to (content?.toMap() ?: previewContent(configuration).toMap()),
            "categories" to categories,
            "postNotificationsGranted" to FluviRuntimeCoordinator.status(context).postNotificationsGranted,
            "statusChannelEnabled" to FluviRuntimeNotificationController.statusChannelEnabled(context),
            "statusChannelImportance" to FluviRuntimeNotificationController.statusChannelImportanceLabel(context),
            "statusChannelLockscreenVisibility" to FluviRuntimeNotificationController.statusChannelLockscreenVisibilityLabel(context),
        )
    }

    internal suspend fun categories(
        context: Context,
        direction: FluviLockScreenCardConfiguration.Direction,
    ): List<Map<String, Any?>> {
        val core = FluviCoreFactory.create(context.applicationContext)
        return try {
            val names = core.categories.list().associateBy { it.id }
            core.financialLimits.list().asSequence()
                .filter { limit ->
                    limit.key.direction == direction.ledgerDirection &&
                        limit.key.target is FluviFinancialLimitTarget.Category
                }
                .mapNotNull { limit ->
                    val id = (limit.key.target as FluviFinancialLimitTarget.Category).categoryId
                    names[id]?.let { mapOf("id" to id, "name" to it.name) }
                }
                .distinctBy { it.getValue("id") }
                .sortedBy { it.getValue("name") as String }
                .toList()
        } finally {
            core.close()
        }
    }

    /**
     * Canonical native financial projection shared by the optional Android
     * notification and by AppWidget hosts.  Presentation privacy is applied
     * only after this value is read, at each output boundary.
     */
    internal suspend fun resolve(
        context: Context,
        configuration: FluviLockScreenCardConfiguration,
    ): FluviLockScreenCardContent {
        if (configuration.mode == FluviLockScreenCardConfiguration.Mode.mind) {
            // Mind is currently a Flutter-only behavioural projection. Do not
            // invent a financial score off-screen; expose its true no-data
            // state until a revisioned shared projection is supplied.
            return FluviLockScreenCardContent(
                focus = "Mind · ${periodLabel(configuration.timeAxis)}",
                primary = "Nincs elegendő adat",
                secondary = "A Mind-pontszám még nem áll rendelkezésre",
                event = null,
                eventLabel = null,
                accentColor = Color.rgb(70, 105, 157),
                available = true,
            )
        }
        val core = FluviCoreFactory.create(context.applicationContext)
        try {
            val now = LocalDate.now()
            val direction = configuration.direction.ledgerDirection
            val categoryId = configuration.categoryId
            val scoped = scopeFor(direction, configuration.timeAxis, now, categoryId)
            val eventScope = when (configuration.eventLine) {
                FluviLockScreenCardConfiguration.EventLine.related -> scoped
                FluviLockScreenCardConfiguration.EventLine.processed -> scopeFor(direction, FluviLockScreenCardConfiguration.TimeAxis.sum, now, null)
                FluviLockScreenCardConfiguration.EventLine.hidden -> null
            }
            val event = eventScope?.let { core.query.readSlice(it, pageSize = 1).entries.firstOrNull() }
            val eventText = event?.let {
                "${if (it.direction == LedgerDirection.expense) "−" else "+"}${money(it.amountMinor)} · ${it.partnerDisplayName} · ${time(it.bookedLocalTimeMinutes)}"
            }
            val eventLabel = when (configuration.eventLine) {
                FluviLockScreenCardConfiguration.EventLine.related -> "Utolsó kapcsolódó tétel"
                FluviLockScreenCardConfiguration.EventLine.processed -> "Utolsó könyvelt tranzakció"
                FluviLockScreenCardConfiguration.EventLine.hidden -> null
            }
            return when (configuration.mode) {
                FluviLockScreenCardConfiguration.Mode.balance -> {
                    val income = core.query.total(scopeFor(LedgerDirection.income, configuration.timeAxis, now, null)).amountScaled100
                    val expense = core.query.total(scopeFor(LedgerDirection.expense, configuration.timeAxis, now, null)).amountScaled100
                    val net = income - expense
                    FluviLockScreenCardContent(
                        focus = "Balance · ${periodLabel(configuration.timeAxis)}",
                        primary = (if (net >= 0) "+" else "−") + money(kotlin.math.abs(net)),
                        secondary = "${periodLabel(configuration.timeAxis)} nettó",
                        event = eventText,
                        eventLabel = eventLabel,
                        accentColor = if (net >= 0) Color.rgb(49, 130, 101) else Color.rgb(180, 83, 83),
                        available = true,
                    )
                }
                FluviLockScreenCardConfiguration.Mode.budget -> {
                    val category = core.categories.getById(requireNotNull(categoryId))
                    if (category == null) return unavailableBudget()
                    val actual = core.query.total(scoped).amountScaled100
                    val limit = limitFor(core.financialLimits.list(), direction, category.id, configuration.timeAxis, now)
                    if (limit == null) return unavailableBudget(category.name)
                    val remaining = limit - actual
                    val progress = if (limit == 0L) 0 else (actual * 100L / limit)
                    val isExpense = direction == LedgerDirection.expense
                    FluviLockScreenCardContent(
                        focus = "${category.name} · ${periodLabel(configuration.timeAxis)}",
                        primary = when {
                            isExpense && remaining < 0 -> "${money(-remaining)}-tal a keret felett"
                            isExpense -> "${money(remaining)} maradt"
                            remaining <= 0 -> "A cél teljesült"
                            else -> "${money(actual)} összegyűlt"
                        },
                        secondary = if (isExpense) "A keret $progress%-a felhasználva" else "A cél $progress%-a teljesült",
                        event = eventText,
                        eventLabel = eventLabel,
                        accentColor = if (isExpense && remaining < 0) Color.rgb(180, 83, 83) else Color.rgb(49, 130, 101),
                        available = true,
                    )
                }
                FluviLockScreenCardConfiguration.Mode.mind -> error("handled above")
            }
        } finally {
            core.close()
        }
    }

    private fun scopeFor(
        direction: LedgerDirection,
        axis: FluviLockScreenCardConfiguration.TimeAxis,
        now: LocalDate,
        categoryId: String?,
    ): FluviQueryScope = FluviQueryScope(
        direction = direction,
        periodGroups = when (axis) {
            FluviLockScreenCardConfiguration.TimeAxis.sum -> emptyList()
            FluviLockScreenCardConfiguration.TimeAxis.year -> listOf(
                com.fluvi.core.query.FluviPeriodGroup("lock-year", setOf(FluviPeriodSelection.year(now.year.toString()))),
            )
            FluviLockScreenCardConfiguration.TimeAxis.month -> listOf(
                com.fluvi.core.query.FluviPeriodGroup("lock-month", setOf(FluviPeriodSelection.month("%04d-%02d".format(now.year, now.monthValue)))),
            )
            FluviLockScreenCardConfiguration.TimeAxis.day -> listOf(
                com.fluvi.core.query.FluviPeriodGroup("lock-day", setOf(FluviPeriodSelection.day(now.toString()))),
            )
        },
        categoryIds = categoryId?.let(::setOf).orEmpty(),
    )

    private fun limitFor(
        limits: List<com.fluvi.core.model.FluviFinancialLimit>,
        direction: LedgerDirection,
        categoryId: String,
        axis: FluviLockScreenCardConfiguration.TimeAxis,
        now: LocalDate,
    ): Long? {
        val selected = limits.filter {
            it.key.direction == direction &&
                (it.key.target as? FluviFinancialLimitTarget.Category)?.categoryId == categoryId
        }
        fun monthLimit(month: YearMonth): Long? {
            selected.firstOrNull { it.key.period is FluviFinancialLimitPeriod.MonthOverride &&
                (it.key.period as FluviFinancialLimitPeriod.MonthOverride).let { p -> p.year == month.year && p.month == month.monthValue }
            }?.let { return it.amountScaled100 }
            return selected.filter { it.key.period is FluviFinancialLimitPeriod.BaseMonthlyRevision }
                .filter { (it.key.period as FluviFinancialLimitPeriod.BaseMonthlyRevision).let { p -> p.effectiveFromYear < month.year || p.effectiveFromYear == month.year && p.effectiveFromMonth <= month.monthValue } }
                .maxWithOrNull(compareBy { (it.key.period as FluviFinancialLimitPeriod.BaseMonthlyRevision).effectiveFromYear * 12 + (it.key.period as FluviFinancialLimitPeriod.BaseMonthlyRevision).effectiveFromMonth })
                ?.amountScaled100
        }
        return when (axis) {
            FluviLockScreenCardConfiguration.TimeAxis.month -> monthLimit(YearMonth.from(now))
            FluviLockScreenCardConfiguration.TimeAxis.day -> monthLimit(YearMonth.from(now))?.div(now.lengthOfMonth().toLong())
            FluviLockScreenCardConfiguration.TimeAxis.year -> (1..12).mapNotNull { monthLimit(YearMonth.of(now.year, it)) }.takeIf { it.size == 12 }?.sum()
            // SUM has no persisted independent limit truth. The app's current
            // annual projection is the meaningful non-fabricated baseline.
            FluviLockScreenCardConfiguration.TimeAxis.sum -> (1..12).mapNotNull { monthLimit(YearMonth.of(now.year, it)) }.takeIf { it.size == 12 }?.sum()
        }
    }

    private fun previewContent(configuration: FluviLockScreenCardConfiguration) = FluviLockScreenCardContent(
        focus = if (configuration.mode == FluviLockScreenCardConfiguration.Mode.budget) "Budget · Hónap" else configuration.mode.name.replaceFirstChar(Char::uppercase),
        primary = "Mintaadat",
        secondary = "A valós adatok betöltése után frissül",
        event = null,
        eventLabel = null,
        accentColor = Color.rgb(70, 105, 157),
        available = false,
    )

    private fun unavailableBudget(name: String = "Budget") = FluviLockScreenCardContent(
        focus = name,
        primary = "Nincs aktív keret",
        secondary = "Válassz egy érvényes kategóriát és keretet",
        event = null,
        eventLabel = null,
        accentColor = Color.rgb(70, 105, 157),
        available = true,
    )

    private fun periodLabel(axis: FluviLockScreenCardConfiguration.TimeAxis): String = when (axis) {
        FluviLockScreenCardConfiguration.TimeAxis.sum -> "Összesen"
        FluviLockScreenCardConfiguration.TimeAxis.year -> "Év"
        FluviLockScreenCardConfiguration.TimeAxis.month -> "Hónap"
        FluviLockScreenCardConfiguration.TimeAxis.day -> "Ma"
    }

    private fun money(scaled100: Long): String = NumberFormat.getIntegerInstance(Locale("hu", "HU"))
        .format(scaled100 / 100L) + " Ft"
    private fun time(minutes: Int): String = "%02d:%02d".format(minutes / 60, minutes % 60)
    private val FluviLockScreenCardConfiguration.Direction.ledgerDirection: LedgerDirection
        get() = if (this == FluviLockScreenCardConfiguration.Direction.expense) LedgerDirection.expense else LedgerDirection.income
}

internal fun FluviLockScreenCardContent.orbBitmap(): Bitmap = Bitmap.createBitmap(96, 96, Bitmap.Config.ARGB_8888).also { bitmap ->
    val canvas = Canvas(bitmap)
    val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        shader = LinearGradient(0f, 0f, 96f, 96f, accentColor, Color.rgb(111, 178, 233), Shader.TileMode.CLAMP)
    }
    canvas.drawCircle(48f, 48f, 47f, paint)
}
