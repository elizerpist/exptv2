package com.fluvi.app.widget.financial

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Shader
import com.fluvi.core.FluviCoreFactory
import com.fluvi.core.model.FluviFinancialLimitTarget
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.query.FluviPeriodSelection
import com.fluvi.core.query.FluviKeyguardBudgetAxis
import com.fluvi.core.query.resolveKeyguardCategoryLimit
import com.fluvi.core.query.FluviQueryScope
import java.text.NumberFormat
import java.time.LocalDate
import java.util.Locale

internal data class FinancialSnapshotFocus(
    val mode: Mode = Mode.budget,
    val timeAxis: TimeAxis = TimeAxis.month,
    val direction: Direction = Direction.expense,
    val categoryId: String? = null,
    val eventLine: EventLine = EventLine.related,
    val privacy: Privacy = Privacy.discreet,
) {
    enum class Mode { mind, balance, budget }
    enum class TimeAxis { sum, year, month, day }
    enum class Direction { income, expense }
    enum class EventLine { related, processed, hidden }
    enum class Privacy { discreet, full }

    val isValid: Boolean get() = mode != Mode.budget || !categoryId.isNullOrBlank()
}

internal data class FinancialSnapshotContent(
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

internal object FinancialSnapshotQueries {
    internal suspend fun categories(
        context: Context,
        direction: FinancialSnapshotFocus.Direction,
    ): List<Map<String, Any?>> {
        val core = FluviCoreFactory.create(context.applicationContext)
        return try {
            val names = core.categories.list().associateBy { it.id }
            val limits = core.financialLimits.list()
            limits.asSequence()
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
     * Canonical financial snapshot query. The provider applies its own disclosure preference.
     */
    internal suspend fun resolve(
        context: Context,
        configuration: FinancialSnapshotFocus,
    ): FinancialSnapshotContent {
        if (configuration.mode == FinancialSnapshotFocus.Mode.mind) {
            // Mind is currently a Flutter-only behavioural projection. Do not
            // invent a financial score off-screen; expose its true no-data
            // state until a revisioned shared projection is supplied.
            return FinancialSnapshotContent(
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
                FinancialSnapshotFocus.EventLine.related -> scoped
                FinancialSnapshotFocus.EventLine.processed -> scopeFor(direction, FinancialSnapshotFocus.TimeAxis.sum, now, null)
                FinancialSnapshotFocus.EventLine.hidden -> null
            }
            val event = eventScope?.let { core.query.readSlice(it, pageSize = 1).entries.firstOrNull() }
            val eventText = event?.let {
                "${if (it.direction == LedgerDirection.expense) "−" else "+"}${money(it.amountMinor)} · ${it.partnerDisplayName} · ${time(it.bookedLocalTimeMinutes)}"
            }
            val eventLabel = when (configuration.eventLine) {
                FinancialSnapshotFocus.EventLine.related -> "Utolsó kapcsolódó tétel"
                FinancialSnapshotFocus.EventLine.processed -> "Utolsó könyvelt tranzakció"
                FinancialSnapshotFocus.EventLine.hidden -> null
            }
            return when (configuration.mode) {
                FinancialSnapshotFocus.Mode.balance -> {
                    val income = core.query.total(scopeFor(LedgerDirection.income, configuration.timeAxis, now, null)).amountScaled100
                    val expense = core.query.total(scopeFor(LedgerDirection.expense, configuration.timeAxis, now, null)).amountScaled100
                    val net = income - expense
                    FinancialSnapshotContent(
                        focus = "Balance · ${periodLabel(configuration.timeAxis)}",
                        primary = (if (net >= 0) "+" else "−") + money(kotlin.math.abs(net)),
                        secondary = "${periodLabel(configuration.timeAxis)} nettó",
                        event = eventText,
                        eventLabel = eventLabel,
                        accentColor = if (net >= 0) Color.rgb(49, 130, 101) else Color.rgb(180, 83, 83),
                        available = true,
                    )
                }
                FinancialSnapshotFocus.Mode.budget -> {
                    val category = core.categories.getById(requireNotNull(categoryId))
                    if (category == null) return unavailableBudget()
                    val actual = core.query.total(scoped).amountScaled100
                    val limit = limitFor(core.financialLimits.list(), direction, category.id, configuration.timeAxis, now)
                    if (limit == null) return unavailableBudget(category.name)
                    val remaining = limit - actual
                    val progress = if (limit == 0L) 0 else (actual * 100L / limit)
                    val isExpense = direction == LedgerDirection.expense
                    FinancialSnapshotContent(
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
                FinancialSnapshotFocus.Mode.mind -> error("handled above")
            }
        } finally {
            core.close()
        }
    }

    private fun scopeFor(
        direction: LedgerDirection,
        axis: FinancialSnapshotFocus.TimeAxis,
        now: LocalDate,
        categoryId: String?,
    ): FluviQueryScope = FluviQueryScope(
        direction = direction,
        periodGroups = when (axis) {
            FinancialSnapshotFocus.TimeAxis.sum -> emptyList()
            FinancialSnapshotFocus.TimeAxis.year -> listOf(
                com.fluvi.core.query.FluviPeriodGroup("lock-year", setOf(FluviPeriodSelection.year(now.year.toString()))),
            )
            FinancialSnapshotFocus.TimeAxis.month -> listOf(
                com.fluvi.core.query.FluviPeriodGroup("lock-month", setOf(FluviPeriodSelection.month("%04d-%02d".format(now.year, now.monthValue)))),
            )
            FinancialSnapshotFocus.TimeAxis.day -> listOf(
                com.fluvi.core.query.FluviPeriodGroup("lock-day", setOf(FluviPeriodSelection.day(now.toString()))),
            )
        },
        categoryIds = categoryId?.let(::setOf).orEmpty(),
    )

    private fun limitFor(
        limits: List<com.fluvi.core.model.FluviFinancialLimit>,
        direction: LedgerDirection,
        categoryId: String,
        axis: FinancialSnapshotFocus.TimeAxis,
        now: LocalDate,
    ): Long? {
        return resolveKeyguardCategoryLimit(
            limits, direction, categoryId, FluviKeyguardBudgetAxis.valueOf(axis.name), now,
        )
    }

    private fun unavailableBudget(name: String = "Budget") = FinancialSnapshotContent(
        focus = name,
        primary = "Nincs aktív keret",
        secondary = "Válassz egy érvényes kategóriát és keretet",
        event = null,
        eventLabel = null,
        accentColor = Color.rgb(70, 105, 157),
        available = true,
    )

    private fun periodLabel(axis: FinancialSnapshotFocus.TimeAxis): String = when (axis) {
        FinancialSnapshotFocus.TimeAxis.sum -> "Összesen"
        FinancialSnapshotFocus.TimeAxis.year -> "Év"
        FinancialSnapshotFocus.TimeAxis.month -> "Hónap"
        FinancialSnapshotFocus.TimeAxis.day -> "Ma"
    }

    private fun money(scaled100: Long): String = NumberFormat.getIntegerInstance(Locale("hu", "HU"))
        .format(scaled100 / 100L) + " Ft"
    private fun time(minutes: Int): String = "%02d:%02d".format(minutes / 60, minutes % 60)
    private val FinancialSnapshotFocus.Direction.ledgerDirection: LedgerDirection
        get() = if (this == FinancialSnapshotFocus.Direction.expense) LedgerDirection.expense else LedgerDirection.income
}

internal fun renderFinancialOrbBitmap(accentColor: Int): Bitmap =
    Bitmap.createBitmap(96, 96, Bitmap.Config.ARGB_8888).also { bitmap ->
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = LinearGradient(0f, 0f, 96f, 96f, accentColor, Color.rgb(111, 178, 233), Shader.TileMode.CLAMP)
        }
        canvas.drawCircle(48f, 48f, 47f, paint)
    }
