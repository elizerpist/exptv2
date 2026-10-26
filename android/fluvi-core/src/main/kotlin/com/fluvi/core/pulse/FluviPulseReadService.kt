package com.fluvi.core.pulse

import androidx.room.withTransaction
import androidx.sqlite.db.SimpleSQLiteQuery
import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.entity.FluviLedgerEntryEntity
import com.fluvi.core.database.entity.FluviNotificationInboxEntity
import com.fluvi.core.database.entity.FluviRecurrenceOccurrenceEntity
import com.fluvi.core.model.CategoryAssignmentMode
import com.fluvi.core.model.FluviClock
import com.fluvi.core.model.FluviFinancialLimit
import com.fluvi.core.model.FluviFinancialLimitPeriod
import com.fluvi.core.model.FluviFinancialLimitTarget
import com.fluvi.core.model.FluviSystemIds
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.NotificationParseStatus
import com.fluvi.core.model.NotificationProcessingStatus
import com.fluvi.core.model.PushReviewStatus
import com.fluvi.core.repository.FluviFinancialLimitRepository
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.roundToLong
import kotlin.math.sqrt

/**
 * One bounded native acquisition for the Pulse dashboard. The service never
 * materializes Ledger data in Flutter and never evaluates a signal, triage or
 * notification policy. Values are real scaled-100 money values when unit is
 * [PulseValueUnit.currency]; all other units are direct display values.
 */
class FluviPulseReadService internal constructor(
    private val database: FluviDatabase,
    private val financialLimits: FluviFinancialLimitRepository,
    private val clock: FluviClock,
) {
    suspend fun dashboard(year: Int, month: Int): PulseDashboardSnapshot = database.withTransaction {
        require(month in 1..12) { "Pulse month must be between 1 and 12." }
        val app = requireNotNull(database.appSettingsDao().current())
        val zone = ZoneId.of(app.localZoneId)
        val nowUtcMs = clock.nowUtcMs()
        val today = Instant.ofEpochMilli(nowUtcMs).atZone(zone).toLocalDate()
        val monthStart = LocalDate.of(year, month, 1)
        val monthEnd = monthStart.plusMonths(1).minusDays(1)
        val historyStart = monthStart.minusDays(90)
        val entries = database.ledgerDao().queryEntries(
            SimpleSQLiteQuery(
                "SELECT * FROM fluvi_ledger_entries WHERE booked_local_epoch_day BETWEEN ? AND ? " +
                    "ORDER BY booked_local_epoch_day ASC, booked_local_time_minutes ASC, id ASC",
                arrayOf(historyStart.toEpochDay(), monthEnd.toEpochDay()),
            ),
        )
        val monthEntries = entries.filter { it.bookedLocalEpochDay in monthStart.toEpochDay()..monthEnd.toEpochDay() }
        val pendingStart = minOf(monthStart, today.minusDays(7))
        val pendingEnd = maxOf(monthEnd, today.plusDays(30))
        val pending = database.recurrenceDao().activePendingBetween(
            atStartUtc(pendingStart, zone),
            atEndUtc(pendingEnd, zone),
        )
        val categories = database.categoryDao().allCategories()
        val partners = database.partnerDao().allPartners()
        val inbox = database.pushAutomationDao().inboxPage(limit = 500, offset = 0)
        val limits = financialLimits.all()
        val userSettings = database.pulseIndicatorSettingsDao().all()
            .associateBy { Triple(it.indicatorId, it.targetKey, it.thresholdKey) }
        val input = PulseInput(
            today = today,
            monthStart = monthStart,
            monthEnd = monthEnd,
            nowUtcMs = nowUtcMs,
            entries = entries,
            monthEntries = monthEntries,
            pending = pending,
            categories = categories.associateBy { it.id },
            partners = partners.associateBy { it.id },
            inbox = inbox,
            limits = limits,
            settings = userSettings,
        )
        val indicators = PulseIndicatorId.entries.map { id -> calculate(id, input) }
        PulseDashboardSnapshot(
            year = year,
            month = month,
            coreRevision = app.coreRevision,
            generatedAtUtcMs = nowUtcMs,
            indicators = indicators,
        )
    }

    private data class PulseInput(
        val today: LocalDate,
        val monthStart: LocalDate,
        val monthEnd: LocalDate,
        val nowUtcMs: Long,
        val entries: List<FluviLedgerEntryEntity>,
        val monthEntries: List<FluviLedgerEntryEntity>,
        val pending: List<FluviRecurrenceOccurrenceEntity>,
        val categories: Map<String, com.fluvi.core.database.entity.FluviCategoryEntity>,
        val partners: Map<String, com.fluvi.core.database.entity.FluviPartnerEntity>,
        val inbox: List<FluviNotificationInboxEntity>,
        val limits: List<FluviFinancialLimit>,
        val settings: Map<Triple<String, String, String>, com.fluvi.core.database.entity.FluviPulseIndicatorSettingEntity>,
    )

    private fun calculate(id: PulseIndicatorId, input: PulseInput): PulseIndicatorSnapshot {
        val thresholds = thresholdsFor(id, input)
        fun available(
            value: Double?,
            summary: String,
            series: List<PulseSeries> = emptyList(),
            secondary: Double? = null,
            sampleCount: Int = 0,
            sources: List<String> = listOf("Ledger tranzakciók"),
            early: Boolean = false,
        ) = PulseIndicatorSnapshot(
            id = id,
            availability = if (early) PulseAvailability.earlyEstimate else PulseAvailability.available,
            value = value,
            secondaryValue = secondary,
            summaryHu = summary,
            sampleCount = sampleCount,
            series = series,
            thresholds = thresholds,
            sources = sources,
        )
        fun unavailable(
            availability: PulseAvailability,
            summary: String,
            reasons: List<String>,
            sources: List<String>,
            series: List<PulseSeries> = emptyList(),
        ) = PulseIndicatorSnapshot(
            id = id,
            availability = availability,
            value = null,
            summaryHu = summary,
            missingReasonsHu = reasons,
            series = series,
            thresholds = thresholds,
            sources = sources,
        )

        val expense = input.monthEntries.filter { it.direction == LedgerDirection.expense }
        val income = input.monthEntries.filter { it.direction == LedgerDirection.income }
        val actualExpense = expense.sumOf { it.amountScaled100 }
        val actualIncome = income.sumOf { it.amountScaled100 }
        val aggregateExpenseLimit = resolveLimit(
            input.limits,
            LedgerDirection.expense,
            null,
            input.monthStart.year,
            input.monthStart.monthValue,
        )
        val forecast = buildForecast(input)

        return when (id) {
            PulseIndicatorId.monthlyBudgetUtilization -> {
                if (aggregateExpenseLimit == null || aggregateExpenseLimit <= 0L) {
                    unavailable(PulseAvailability.notApplicable, "Nincs érvényes havi kiadási keret.", listOf("Budget limit szükséges."), listOf("Budget limit", "Ledger tranzakciók"))
                } else {
                    val percent = actualExpense * 100.0 / aggregateExpenseLimit
                    available(percent, "${formatPercent(percent)} a havi keretből", listOf(gaugeSeries(actualExpense, aggregateExpenseLimit)), sources = listOf("Budget limit", "Könyvelt Ledger-kiadások"))
                }
            }
            PulseIndicatorId.categoryBudgetUtilization -> {
                val categoryLimits = input.categories.values.mapNotNull { category ->
                    resolveLimit(input.limits, LedgerDirection.expense, category.id, input.monthStart.year, input.monthStart.monthValue)
                        ?.takeIf { it > 0L }?.let { category to it }
                }
                if (categoryLimits.isEmpty()) {
                    unavailable(PulseAvailability.notApplicable, "Nincs kategóriakeret ebben a hónapban.", listOf("Kategória Budget limit szükséges."), listOf("Kategóriák", "Budget limitek"))
                } else {
                    val points = categoryLimits.map { (category, limit) ->
                        val spent = expense.filter { it.categoryId == category.id }.sumOf { it.amountScaled100 }
                        PulsePoint(category.id.hashCode().toLong(), category.name, actual = spent, reference = limit)
                    }
                    val highest = points.maxOf { (it.actual ?: 0L) * 100.0 / max(1L, it.reference ?: 1L) }
                    available(highest, "${points.size} kategóriakeret követhető", listOf(PulseSeries("categories", "Kategóriák", points)), sampleCount = points.size, sources = listOf("Kategóriák", "Budget limitek", "Könyvelt Ledger-kiadások"))
                }
            }
            PulseIndicatorId.spendingMomentum -> {
                val days = max(1, (minOf(input.today, input.monthEnd).toEpochDay() - input.monthStart.toEpochDay() + 1).toInt())
                val short = dailyAmounts(input.entries, LedgerDirection.expense, input.today.minusDays(6), input.today, excludeRealizedRecurring = true)
                val long = dailyAmounts(input.entries, LedgerDirection.expense, input.today.minusDays(27), input.today, excludeRealizedRecurring = true)
                val shortDaily = short.values.averageLongsOrZero()
                val sustainable = when {
                    aggregateExpenseLimit != null && input.today in input.monthStart..input.monthEnd ->
                        ((aggregateExpenseLimit - actualExpense).coerceAtLeast(0L).toDouble() / max(1, input.monthEnd.dayOfMonth - days))
                    long.isNotEmpty() -> long.values.averageLongsOrZero()
                    else -> 0.0
                }
                if (sustainable <= 0.0) {
                    unavailable(PulseAvailability.waitingForData, "Nincs pozitív fenntartható referencia.", listOf("Érvényes keret vagy legalább egy 28 napos költési referencia szükséges."), listOf("Ledger tranzakciók", "Budget limit"))
                } else {
                    val ratio = shortDaily / sustainable
                    available(ratio, "${formatRatio(ratio)} a fenntartható ütemhez képest", listOf(dailyTrendSeries(short, sustainable.roundToLong())), secondary = (ratio - 1) * 100, sampleCount = long.size, early = long.size < 14)
                }
            }
            PulseIndicatorId.monthEndForecast -> {
                if (forecast == null) {
                    unavailable(PulseAvailability.waitingForData, "Nincs elég adat forecast készítéséhez.", listOf("Legalább néhány történeti költési nap szükséges."), listOf("Ledger tranzakciók", "Pending ghost occurrence-ok"))
                } else {
                    available(forecast.baselineEnd.toDouble(), "Baseline: ${forecast.baselineEnd}; momentum forgatókönyv is látható.", forecast.series(aggregateExpenseLimit), secondary = forecast.momentumEnd.toDouble(), sampleCount = forecast.historySampleCount, sources = listOf("Könyvelt Ledger-kiadások", "Pending ghost occurrence-ok", "Budget limit"), early = forecast.historySampleCount < 14)
                }
            }
            PulseIndicatorId.limitCrossing -> {
                if (aggregateExpenseLimit == null || aggregateExpenseLimit <= 0L) {
                    unavailable(PulseAvailability.notApplicable, "Limit nélkül nincs túllépési dátum.", listOf("Érvényes havi kiadási keret szükséges."), listOf("Budget limit", "Forecast"))
                } else if (forecast == null) {
                    unavailable(PulseAvailability.waitingForData, "Nincs elég adat a dátum becsléséhez.", listOf("Forecast bemenet hiányzik."), listOf("Ledger tranzakciók", "Pending ghost occurrence-ok"))
                } else {
                    val crossing = forecast.firstCrossing(aggregateExpenseLimit)
                    if (crossing == null) available(null, "Ebben a forgatókönyvben nincs várható túllépés.", forecast.series(aggregateExpenseLimit), sources = listOf("Forecast", "Budget limit"))
                    else available((crossing.toEpochDay() - input.today.toEpochDay()).toDouble(), "Várható átlépés: $crossing", forecast.series(aggregateExpenseLimit), sources = listOf("Forecast", "Budget limit"))
                }
            }
            PulseIndicatorId.spendingOutlier -> {
                val daily = dailyAmounts(input.entries, LedgerDirection.expense, input.today.minusDays(27), input.today)
                if (daily.size < 7) unavailable(PulseAvailability.waitingForData, "Nincs elég napi minta.", listOf("Legalább 7 nap költési adat szükséges."), listOf("Ledger tranzakciók"))
                else {
                    val median = daily.values.sorted().let { values -> values[values.size / 2] }
                    val peak = daily.maxByOrNull { it.value }!!
                    val difference = if (median == 0L) null else (peak.value - median) * 100.0 / median
                    available(difference, "Legnagyobb napi eltérés: ${difference?.let(::formatPercent) ?: "nem értelmezhető"}", listOf(dailyTrendSeries(daily, median)), sampleCount = daily.size)
                }
            }
            PulseIndicatorId.spendingConcentration -> {
                if (actualExpense <= 0L) unavailable(PulseAvailability.notApplicable, "Nincs könyvelt kiadás az időszakban.", listOf("Pozitív kiadási összeg szükséges."), listOf("Ledger tranzakciók"))
                else {
                    val rows = expense.groupBy { it.partnerId }.map { (partnerId, values) ->
                        val partner = input.partners[partnerId]
                        PulsePoint(partnerId.hashCode().toLong(), partner?.displayNameOverride ?: partner?.originalName ?: partnerId, actual = values.sumOf { it.amountScaled100 }, reference = actualExpense)
                    }.sortedByDescending { it.actual }.take(5)
                    val lead = rows.first().actual!! * 100.0 / actualExpense
                    available(lead, "A legnagyobb partner részesedése ${formatPercent(lead)}.", listOf(PulseSeries("partners", "Top partnerek", rows)), sampleCount = rows.size, sources = listOf("Partner törzs", "Ledger tranzakciók"))
                }
            }
            PulseIndicatorId.incomeExpenseRatio -> {
                if (actualIncome <= 0L) unavailable(PulseAvailability.notApplicable, "Nincs könyvelt havi bevétel az arányhoz.", listOf("Pozitív könyvelt bevétel szükséges."), listOf("Ledger tranzakciók"))
                else {
                    val percent = actualExpense * 100.0 / actualIncome
                    available(percent, "${formatPercent(percent)} kiadás a havi bevételhez képest.", listOf(gaugeSeries(actualExpense, actualIncome)), sources = listOf("Könyvelt Ledger-bevételek és -kiadások"))
                }
            }
            PulseIndicatorId.netCashflowForecast -> {
                if (forecast == null) unavailable(PulseAvailability.waitingForData, "Nincs elég adat a cashflow forecast-hoz.", listOf("Kiadási forecast bemenet hiányzik."), listOf("Ledger tranzakciók", "Pending ghost occurrence-ok"))
                else {
                    val incomeHistory = dailyAmounts(input.entries, LedgerDirection.income, input.today.minusDays(27), input.today)
                    val dailyIncome = incomeHistory.values.averageLongsOrZero().roundToLong()
                    val pendingIncome = input.pending.filter { it.direction == LedgerDirection.income && it.expectedAmountScaled100 != null && dateOf(it) in input.monthStart..input.monthEnd }.sumOf { it.expectedAmountScaled100!! }
                    val remaining = max(0, input.monthEnd.dayOfMonth - minOf(input.today, input.monthEnd).dayOfMonth)
                    val projectedIncome = actualIncome + dailyIncome * remaining + pendingIncome
                    val net = projectedIncome - forecast.baselineEnd
                    available(net.toDouble(), "Várható nettó cashflow: $net", forecast.netSeries(projectedIncome), secondary = (projectedIncome - forecast.momentumEnd).toDouble(), sampleCount = incomeHistory.size, sources = listOf("Könyvelt Ledger-bevételek és -kiadások", "Pending ghost occurrence-ok"), early = incomeHistory.size < 7)
                }
            }
            PulseIndicatorId.fixedBurdenCoverage -> unavailable(PulseAvailability.notApplicable, "Adatforrás szükséges a tényleges fedezethez.", listOf("A Fluvi Core-ban még nincs explicit pénzeszköz-egyenleg forrás."), listOf("Pending ghost occurrence-ok", "Pénzeszköz-egyenleg forrás"))
            PulseIndicatorId.lateIncome -> {
                val overdue = input.pending.filter { it.direction == LedgerDirection.income && dateOf(it).isBefore(input.today) && it.expectedAmountScaled100 != null }
                val points = overdue.map { occurrence -> PulsePoint(occurrence.expectedAtUtcMs, dateOf(occurrence).toString(), actual = occurrence.expectedAmountScaled100) }
                val age = overdue.maxOfOrNull { (input.today.toEpochDay() - dateOf(it).toEpochDay()).toDouble() }
                available(age, if (overdue.isEmpty()) "Nincs késő bevétel." else "${overdue.size} késő bevétel vár teljesülésre.", listOf(PulseSeries("lateIncome", "Késő bevétel", points)), sampleCount = overdue.size, sources = listOf("Pending income occurrence-ok"))
            }
            PulseIndicatorId.reserveCoverDays -> unavailable(PulseAvailability.notApplicable, "Adatforrás szükséges a fedezeti napokhoz.", listOf("Explicit pénzeszköz-egyenleg nélkül nem vezetünk le bankszámla-fedezetet Ledger nettóból."), listOf("Pénzeszköz-egyenleg forrás", "Ledger tranzakciók"))
            PulseIndicatorId.negativeTrajectory -> unavailable(PulseAvailability.notApplicable, "Adatforrás szükséges a negatív pályához.", listOf("Explicit nyitó vagy aktuális pénzeszköz-egyenleg szükséges."), listOf("Pénzeszköz-egyenleg forrás", "Cashflow forecast"))
            PulseIndicatorId.cashflowStability -> {
                val weekly = weeklyNet(input.entries, input.today.minusDays(83), input.today)
                if (weekly.size < 4) unavailable(PulseAvailability.waitingForData, "Nincs elég heti minta.", listOf("Legalább 4 heti nettó pénzmozgás szükséges."), listOf("Ledger tranzakciók"))
                else {
                    val mean = weekly.values.averageLongsOrZero()
                    val deviation = sqrt(weekly.values.map { (it - mean) * (it - mean) }.averageDoublesOrZero())
                    val normalized = deviation / max(1.0, abs(mean))
                    available(normalized, "Normalizált heti volatilitás: ${formatRatio(normalized)}", listOf(PulseSeries("weeklyNet", "Heti nettó", weekly.map { PulsePoint(it.key.toEpochDay(), it.key.toString(), actual = it.value) })), sampleCount = weekly.size)
                }
            }
            PulseIndicatorId.recurringBurden -> {
                val realized = expense.filter { it.recurrenceOccurrenceId != null }.sumOf { it.amountScaled100 }
                val pendingRecurring = input.pending.filter { it.direction == LedgerDirection.expense && it.expectedAmountScaled100 != null && dateOf(it) in input.monthStart..input.monthEnd }.sumOf { it.expectedAmountScaled100!! }
                val recurring = realized + pendingRecurring
                val referenceIncome = actualIncome.takeIf { it > 0L } ?: dailyAmounts(input.entries, LedgerDirection.income, input.today.minusDays(27), input.today).values.sum()
                if (referenceIncome <= 0L) unavailable(PulseAvailability.notApplicable, "Nincs referencia-bevétel az arányhoz.", listOf("Pozitív könyvelt vagy történeti bevétel szükséges."), listOf("Recurring occurrence-ok", "Ledger bevételek"), listOf(gaugeSeries(recurring, 0)))
                else {
                    val percent = recurring * 100.0 / referenceIncome
                    available(percent, "Ismert recurring teher: $recurring", listOf(gaugeSeries(recurring, referenceIncome)), sources = listOf("Realized recurring Ledger-tételek", "Pending ghost occurrence-ok", "Ledger bevételek"))
                }
            }
            PulseIndicatorId.subscriptionLoad -> unavailable(PulseAvailability.notApplicable, "Előfizetés-jelölés szükséges.", listOf("A Pulse V1 nem minősít szöveg alapján előfizetést; még nincs kijelölt recurring szabály vagy kategória."), listOf("Felhasználói előfizetés-jelölések", "Recurring szabályok"))
            PulseIndicatorId.upcomingGhostLoad -> {
                val future = input.pending.filter { it.direction == LedgerDirection.expense && it.expectedAmountScaled100 != null && !dateOf(it).isBefore(input.today) }
                val next7 = future.filter { !dateOf(it).isAfter(input.today.plusDays(7)) }.sumOf { it.expectedAmountScaled100!! }
                val next30 = future.filter { !dateOf(it).isAfter(input.today.plusDays(30)) }.sumOf { it.expectedAmountScaled100!! }
                val points = future.filter { !dateOf(it).isAfter(input.today.plusDays(30)) }.map { PulsePoint(it.expectedAtUtcMs, dateOf(it).toString(), actual = it.expectedAmountScaled100) }
                available(next7.toDouble(), "7 nap: $next7 · 30 nap: $next30", listOf(PulseSeries("ghostLoad", "Várható ghost terhek", points)), secondary = next30.toDouble(), sampleCount = points.size, sources = listOf("Pending ghost occurrence-ok"))
            }
            PulseIndicatorId.uncategorizedTransactions -> {
                val uncategorizedId = input.categories.values.firstOrNull { it.isSystemUncategorized }?.id
                if (uncategorizedId == null) unavailable(PulseAvailability.calculationError, "A rendszer Kategorizálatlan kategóriája hiányzik.", listOf("System category ID nem található."), listOf("Kategória katalógus"))
                else {
                    val rows = input.monthEntries.filter { it.categoryId == uncategorizedId }
                    val oldest = rows.minOfOrNull { it.bookedLocalEpochDay }
                    val age = oldest?.let { input.today.toEpochDay() - it }
                    available(rows.size.toDouble(), "${rows.size} tétel · legrégebbi: ${age ?: 0} nap", listOf(PulseSeries("uncategorized", "Kategorizálatlan", rows.map { PulsePoint(it.bookedLocalEpochDay, actual = it.amountScaled100) })), secondary = rows.sumOf { it.amountScaled100 }.toDouble(), sampleCount = rows.size, sources = listOf("Kategória katalógus", "Ledger tranzakciók"))
                }
            }
            PulseIndicatorId.categoryOverrideAnomaly -> {
                val grouped = input.monthEntries.groupBy { it.partnerId }.mapNotNull { (partnerId, rows) ->
                    if (rows.size < 3) null else {
                        val overrides = rows.count { it.categoryAssignmentMode == CategoryAssignmentMode.entryOverride }
                        PulsePoint(partnerId.hashCode().toLong(), input.partners[partnerId]?.displayNameOverride ?: input.partners[partnerId]?.originalName ?: partnerId, actual = overrides.toLong(), reference = rows.size.toLong())
                    }
                }.sortedByDescending { (it.actual ?: 0L).toDouble() / max(1L, it.reference ?: 1L) }.take(5)
                if (grouped.isEmpty()) unavailable(PulseAvailability.waitingForData, "Nincs elegendő partneri minta.", listOf("Partnerenként legalább 3 tranzakció szükséges."), listOf("Ledger kategória-hozzárendelések", "Partner törzs"))
                else {
                    val top = grouped.first().actual!! * 100.0 / grouped.first().reference!!
                    available(top, "Legmagasabb override-arány: ${formatPercent(top)}", listOf(PulseSeries("overrides", "Partner override arány", grouped)), sampleCount = grouped.size, sources = listOf("Ledger categoryAssignmentMode", "Partner törzs"))
                }
            }
            PulseIndicatorId.uncertainPushRecognition -> {
                val review = input.inbox.filter { it.reviewStatus == PushReviewStatus.pending }
                val confidence = review.mapNotNull { it.confidence }
                val points = confidence.mapIndexed { index, value -> PulsePoint(index.toLong(), actual = (value * 100).roundToLong()) }
                available(review.size.toDouble(), "${review.size} felülvizsgálatra váró elem.", listOf(PulseSeries("confidence", "Confidence", points)), secondary = confidence.averageDoublesOrNull(), sampleCount = review.size, sources = listOf("Push Notification Inbox", "Parser diagnosztika"))
            }
            PulseIndicatorId.processingBacklog -> {
                val backlog = input.inbox.filter { it.processingStatus == NotificationProcessingStatus.unprocessed || it.parseStatus == NotificationParseStatus.invalid }
                val oldest = backlog.minOfOrNull { it.receivedAtUtcMs }
                val ageDays = oldest?.let { (input.nowUtcMs - it) / 86_400_000.0 }
                val points = backlog.sortedBy { it.receivedAtUtcMs }.map { PulsePoint(it.receivedAtUtcMs, actual = 1) }
                available(backlog.size.toDouble(), "${backlog.size} technikai feldolgozási tétel.", listOf(PulseSeries("backlog", "Feldolgozási backlog", points)), secondary = ageDays, sampleCount = backlog.size, sources = listOf("Push Notification Inbox"))
            }
        }
    }

    private fun thresholdsFor(id: PulseIndicatorId, input: PulseInput): List<PulseThresholdValue> {
        val definition = id.threshold
        val stored = input.settings[Triple(id.stableId, "", definition.key)]
        return listOf(PulseThresholdValue(definition.key, stored?.value ?: definition.defaultValue, definition, stored != null))
    }

    private fun resolveLimit(
        values: List<FluviFinancialLimit>,
        direction: LedgerDirection,
        categoryId: String?,
        year: Int,
        month: Int,
    ): Long? {
        val target = values.filter { value ->
            value.key.direction == direction && when (val candidate = value.key.target) {
                FluviFinancialLimitTarget.Aggregate -> categoryId == null
                is FluviFinancialLimitTarget.Category -> candidate.categoryId == categoryId
            }
        }
        target.firstOrNull { it.key.period is FluviFinancialLimitPeriod.MonthOverride &&
            (it.key.period as FluviFinancialLimitPeriod.MonthOverride).year == year &&
            (it.key.period as FluviFinancialLimitPeriod.MonthOverride).month == month
        }?.let { return it.amountScaled100 }
        val linear = year * 12 + month - 1
        return target.mapNotNull { limit ->
            (limit.key.period as? FluviFinancialLimitPeriod.BaseMonthlyRevision)?.let { period ->
                val candidate = period.effectiveFromYear * 12 + period.effectiveFromMonth - 1
                if (candidate <= linear) candidate to limit.amountScaled100 else null
            }
        }.maxByOrNull { it.first }?.second
    }

    private data class Forecast(
        val points: List<ForecastPoint>,
        val baselineEnd: Long,
        val momentumEnd: Long,
        val historySampleCount: Int,
    ) {
        fun series(limit: Long?): List<PulseSeries> = listOf(
            PulseSeries("actual", "Tényleges", points.map { PulsePoint(it.day.toEpochDay(), it.day.toString(), actual = it.actual) }),
            PulseSeries("baseline", "Baseline forecast", points.map { PulsePoint(it.day.toEpochDay(), it.day.toString(), baseline = it.baseline) }),
            PulseSeries("momentum", "Momentum forgatókönyv", points.map { PulsePoint(it.day.toEpochDay(), it.day.toString(), momentum = it.momentum) }),
        ) + if (limit == null) emptyList() else listOf(PulseSeries("limit", "Havi keret", points.map { PulsePoint(it.day.toEpochDay(), it.day.toString(), reference = limit) }))

        fun netSeries(projectedIncome: Long): List<PulseSeries> = listOf(
            PulseSeries("netBaseline", "Nettó baseline", points.map { point -> PulsePoint(point.day.toEpochDay(), point.day.toString(), baseline = point.baseline?.let { projectedIncome - it }) }),
            PulseSeries("netMomentum", "Nettó momentum", points.map { point -> PulsePoint(point.day.toEpochDay(), point.day.toString(), momentum = point.momentum?.let { projectedIncome - it }) }),
        )

        fun firstCrossing(limit: Long): LocalDate? = points.firstOrNull { (it.baseline ?: Long.MIN_VALUE) >= limit }?.day
    }

    private data class ForecastPoint(val day: LocalDate, val actual: Long?, val baseline: Long?, val momentum: Long?)

    private fun buildForecast(input: PulseInput): Forecast? {
        if (input.monthStart.year != input.today.year || input.monthStart.monthValue != input.today.monthValue) return null
        val historical = dailyAmounts(input.entries, LedgerDirection.expense, input.today.minusDays(28), input.today.minusDays(1), excludeRealizedRecurring = true)
        val actualDaily = dailyAmounts(input.monthEntries, LedgerDirection.expense, input.monthStart, minOf(input.today, input.monthEnd))
        if (historical.size < 3 && actualDaily.isEmpty()) return null
        val baselineDaily = historical.values.averageLongsOrZero().takeIf { it > 0 } ?: actualDaily.values.averageLongsOrZero()
        if (baselineDaily <= 0) return null
        val momentumDaily = dailyAmounts(input.entries, LedgerDirection.expense, input.today.minusDays(6), input.today, excludeRealizedRecurring = true).values.averageLongsOrZero().let { short ->
            // Conservative bounded momentum prevents one outlier from becoming a certainty.
            short.coerceIn(baselineDaily * .55, baselineDaily * 1.75)
        }
        val ghosts = input.pending.filter { it.direction == LedgerDirection.expense && it.expectedAmountScaled100 != null && dateOf(it) in input.monthStart..input.monthEnd }
            .groupBy { dateOf(it) }.mapValues { (_, values) -> values.sumOf { it.expectedAmountScaled100!! } }
        var actual = 0L
        var baseline = 0L
        var momentum = 0L
        val points = buildList {
            var day = input.monthStart
            while (!day.isAfter(input.monthEnd)) {
                val dayActual = actualDaily[day] ?: 0L
                if (!day.isAfter(input.today)) actual += dayActual
                if (day.isAfter(input.today)) {
                    baseline += baselineDaily.roundToLong() + (ghosts[day] ?: 0L)
                    momentum += momentumDaily.roundToLong() + (ghosts[day] ?: 0L)
                } else {
                    baseline = actual
                    momentum = actual
                }
                add(ForecastPoint(day, if (day.isAfter(input.today)) null else actual, baseline, momentum))
                day = day.plusDays(1)
            }
        }
        return Forecast(points, baselineEnd = baseline, momentumEnd = momentum, historySampleCount = historical.size)
    }

    private fun dailyAmounts(
        entries: List<FluviLedgerEntryEntity>,
        direction: LedgerDirection,
        from: LocalDate,
        to: LocalDate,
        excludeRealizedRecurring: Boolean = false,
    ): Map<LocalDate, Long> = entries.asSequence()
        .filter { it.direction == direction && it.bookedLocalEpochDay in from.toEpochDay()..to.toEpochDay() }
        .filter { !excludeRealizedRecurring || it.recurrenceOccurrenceId == null }
        .groupBy { LocalDate.ofEpochDay(it.bookedLocalEpochDay) }
        .mapValues { (_, values) -> values.sumOf { it.amountScaled100 } }

    private fun weeklyNet(entries: List<FluviLedgerEntryEntity>, from: LocalDate, to: LocalDate): Map<LocalDate, Long> = entries.asSequence()
        .filter { it.bookedLocalEpochDay in from.toEpochDay()..to.toEpochDay() }
        .groupBy { LocalDate.ofEpochDay(it.bookedLocalEpochDay).minusDays((LocalDate.ofEpochDay(it.bookedLocalEpochDay).dayOfWeek.value - 1).toLong()) }
        .mapValues { (_, values) -> values.sumOf { if (it.direction == LedgerDirection.income) it.amountScaled100 else -it.amountScaled100 } }

    private fun dailyTrendSeries(values: Map<LocalDate, Long>, reference: Long): PulseSeries = PulseSeries(
        "daily",
        "Napi értékek",
        values.entries.sortedBy { it.key }.map { PulsePoint(it.key.toEpochDay(), it.key.toString(), actual = it.value, reference = reference) },
    )

    private fun gaugeSeries(actual: Long, reference: Long): PulseSeries = PulseSeries(
        "gauge",
        "Aktuális és referencia",
        listOf(PulsePoint(0, actual = actual, reference = reference)),
    )

    private fun dateOf(occurrence: FluviRecurrenceOccurrenceEntity): LocalDate = LocalDate.ofEpochDay(occurrence.expectedLocalEpochDay)
    private fun atStartUtc(day: LocalDate, zone: ZoneId): Long = day.atStartOfDay(zone).toInstant().toEpochMilli()
    private fun atEndUtc(day: LocalDate, zone: ZoneId): Long = day.plusDays(1).atStartOfDay(zone).toInstant().toEpochMilli() - 1L
    private fun Iterable<Long>.averageLongsOrZero(): Double = if (none()) 0.0 else average()
    private fun Iterable<Double>.averageDoublesOrZero(): Double = if (none()) 0.0 else average()
    private fun Iterable<Double>.averageDoublesOrNull(): Double? = if (none()) null else average()
    private fun formatPercent(value: Double): String = "%.0f%%".format(java.util.Locale.ROOT, value)
    private fun formatRatio(value: Double): String = "%.2f×".format(java.util.Locale.ROOT, value)
}

class FluviPulseThresholdUseCase internal constructor(
    private val database: FluviDatabase,
    private val clock: FluviClock,
) {
    suspend fun set(
        indicatorId: String,
        targetKey: String = "",
        thresholdKey: String = "primary",
        value: Double,
    ) = database.withTransaction {
        val indicator = PulseIndicatorId.fromStableId(indicatorId)
        val definition = indicator.threshold
        require(thresholdKey == definition.key) { "Unsupported Pulse threshold key: $thresholdKey" }
        require(value in definition.minimum..definition.maximum) { "Pulse threshold is outside its permitted range." }
        database.pulseIndicatorSettingsDao().upsert(
            com.fluvi.core.database.entity.FluviPulseIndicatorSettingEntity(
                indicatorId = indicatorId,
                targetKey = targetKey,
                thresholdKey = thresholdKey,
                value = value,
                updatedAtUtcMs = clock.nowUtcMs(),
            ),
        )
        database.appSettingsDao().incrementCoreRevision(FluviSystemIds.APP_SETTINGS, clock.nowUtcMs())
    }

    suspend fun reset(
        indicatorId: String,
        targetKey: String = "",
        thresholdKey: String = "primary",
    ) = database.withTransaction {
        PulseIndicatorId.fromStableId(indicatorId)
        database.pulseIndicatorSettingsDao().delete(indicatorId, targetKey, thresholdKey)
        database.appSettingsDao().incrementCoreRevision(FluviSystemIds.APP_SETTINGS, clock.nowUtcMs())
    }
}
