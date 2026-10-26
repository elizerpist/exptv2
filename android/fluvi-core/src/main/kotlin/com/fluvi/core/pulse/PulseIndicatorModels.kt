package com.fluvi.core.pulse

/** Stable financial-measurement catalog. These are intentionally not signal or triage IDs. */
enum class PulseIndicatorId(
    val stableId: String,
    val group: PulseIndicatorGroup,
    val titleHu: String,
    val descriptionHu: String,
    val unit: PulseValueUnit,
    val chartKind: PulseChartKind,
    val threshold: PulseThresholdDefinition,
) {
    monthlyBudgetUtilization("PULSE-001", PulseIndicatorGroup.spending, "Havi keretkihasználtság", "Könyvelt kiadás a havi kerethez viszonyítva.", PulseValueUnit.percent, PulseChartKind.arcGauge, PulseThresholdDefinition.percent(90.0, 0.0, 150.0, 1.0)),
    categoryBudgetUtilization("PULSE-002", PulseIndicatorGroup.spending, "Kategóriakeretek kihasználtsága", "Kategóriánkénti tényleges költés és keret.", PulseValueUnit.percent, PulseChartKind.thresholdBar, PulseThresholdDefinition.percent(90.0, 0.0, 150.0, 1.0)),
    spendingMomentum("PULSE-003", PulseIndicatorGroup.spending, "Költési ütem", "Rövid távú költés a fenntartható ütemhez viszonyítva.", PulseValueUnit.ratio, PulseChartKind.trend, PulseThresholdDefinition.ratio(1.20, 0.0, 3.0, .05)),
    monthEndForecast("PULSE-004", PulseIndicatorGroup.spending, "Hónapvégi költési forecast", "Tényleges költés, két forgatókönyv és ismert ghost terhek.", PulseValueUnit.currency, PulseChartKind.forecast, PulseThresholdDefinition.currency(0.0, 0.0, 10_000_000.0, 1_000.0)),
    limitCrossing("PULSE-005", PulseIndicatorGroup.spending, "Várható limitátlépés", "A forecast szerinti első limitátlépési dátum.", PulseValueUnit.days, PulseChartKind.timeline, PulseThresholdDefinition.days(3.0, 0.0, 31.0, 1.0)),
    spendingOutlier("PULSE-006", PulseIndicatorGroup.spending, "Szokatlan költési kiugrás", "Napi költés eltérése robusztus történeti referenciától.", PulseValueUnit.percent, PulseChartKind.trend, PulseThresholdDefinition.percent(50.0, 0.0, 500.0, 5.0)),
    spendingConcentration("PULSE-007", PulseIndicatorGroup.spending, "Költési koncentráció", "A legnagyobb partner részesedése a releváns kiadásból.", PulseValueUnit.percent, PulseChartKind.ratio, PulseThresholdDefinition.percent(40.0, 0.0, 100.0, 1.0)),
    incomeExpenseRatio("PULSE-008", PulseIndicatorGroup.cashflow, "Bevétel–kiadás arány", "Könyvelt havi kiadás a könyvelt havi bevételhez viszonyítva.", PulseValueUnit.percent, PulseChartKind.ratio, PulseThresholdDefinition.percent(90.0, 0.0, 200.0, 1.0)),
    netCashflowForecast("PULSE-009", PulseIndicatorGroup.cashflow, "Nettó cashflow forecast", "Várható havi bevétel mínusz várható havi kiadás.", PulseValueUnit.currency, PulseChartKind.forecast, PulseThresholdDefinition.currency(0.0, -10_000_000.0, 10_000_000.0, 1_000.0)),
    fixedBurdenCoverage("PULSE-010", PulseIndicatorGroup.cashflow, "Fix terhek fedezete", "Közelgő kötelezettségek és explicit pénzeszköz-forrás viszonya.", PulseValueUnit.percent, PulseChartKind.ratio, PulseThresholdDefinition.percent(100.0, 0.0, 200.0, 1.0)),
    lateIncome("PULSE-011", PulseIndicatorGroup.cashflow, "Késő bevétel", "Esedékes, de még nem teljesült bevételi occurrence-ok.", PulseValueUnit.days, PulseChartKind.timeline, PulseThresholdDefinition.days(1.0, 0.0, 31.0, 1.0)),
    reserveCoverDays("PULSE-012", PulseIndicatorGroup.cashflow, "Tartalékfedezet napokban", "Explicit pénzeszköz-egyenleg és napi költési ütem.", PulseValueUnit.days, PulseChartKind.arcGauge, PulseThresholdDefinition.days(14.0, 0.0, 180.0, 1.0)),
    negativeTrajectory("PULSE-013", PulseIndicatorGroup.cashflow, "Negatív pénzügyi pálya", "Explicit nyitóegyenleg és várható cashflow nullakeresztezése.", PulseValueUnit.days, PulseChartKind.forecast, PulseThresholdDefinition.days(7.0, 0.0, 180.0, 1.0)),
    cashflowStability("PULSE-014", PulseIndicatorGroup.cashflow, "Cashflow stabilitás", "Heti nettó pénzmozgások normalizált volatilitása.", PulseValueUnit.ratio, PulseChartKind.trend, PulseThresholdDefinition.ratio(.35, 0.0, 3.0, .05)),
    recurringBurden("PULSE-015", PulseIndicatorGroup.systems, "Ismétlődő terhek aránya", "Havi recurring kiadás a referencia-bevételhez viszonyítva.", PulseValueUnit.percent, PulseChartKind.ratio, PulseThresholdDefinition.percent(50.0, 0.0, 150.0, 1.0)),
    subscriptionLoad("PULSE-016", PulseIndicatorGroup.systems, "Előfizetés-terhelés", "Kifejezetten felhasználó által előfizetésként jelölt szabályok terhe.", PulseValueUnit.currency, PulseChartKind.trend, PulseThresholdDefinition.currency(0.0, 0.0, 10_000_000.0, 1_000.0)),
    upcomingGhostLoad("PULSE-017", PulseIndicatorGroup.systems, "Közelgő ghost terhelés", "A következő 7 és 30 nap pending ghost kiadásai.", PulseValueUnit.currency, PulseChartKind.timeline, PulseThresholdDefinition.currency(0.0, 0.0, 10_000_000.0, 1_000.0)),
    uncategorizedTransactions("PULSE-018", PulseIndicatorGroup.systems, "Kategorizálatlan tranzakciók", "Kategorizálatlan könyvelt tételek száma, összege és életkora.", PulseValueUnit.count, PulseChartKind.thresholdBar, PulseThresholdDefinition.count(5.0, 0.0, 500.0, 1.0)),
    categoryOverrideAnomaly("PULSE-019", PulseIndicatorGroup.systems, "Category Override anomália", "Explicit kategóriafelülírások aránya partnerenként.", PulseValueUnit.percent, PulseChartKind.ratio, PulseThresholdDefinition.percent(30.0, 0.0, 100.0, 1.0)),
    uncertainPushRecognition("PULSE-020", PulseIndicatorGroup.systems, "Bizonytalan push felismerések", "Felülvizsgálatra váró Push Parser és matcher döntések.", PulseValueUnit.count, PulseChartKind.ratio, PulseThresholdDefinition.count(1.0, 0.0, 1000.0, 1.0)),
    processingBacklog("PULSE-021", PulseIndicatorGroup.systems, "Feldolgozási backlog", "Feldolgozatlan vagy hibás technikai Inbox-elemek.", PulseValueUnit.count, PulseChartKind.timeline, PulseThresholdDefinition.count(5.0, 0.0, 10_000.0, 1.0)),
    ;

    companion object {
        fun fromStableId(value: String): PulseIndicatorId = entries.firstOrNull { it.stableId == value }
            ?: throw IllegalArgumentException("Unknown Pulse indicator: $value")
    }
}

enum class PulseIndicatorGroup(val titleHu: String) {
    spending("Költés és előrejelzés"),
    cashflow("Cashflow és pénzügyi biztonság"),
    systems("Ismétlődések és adatminőség"),
}

enum class PulseValueUnit { percent, currency, ratio, days, count }
enum class PulseChartKind { arcGauge, thresholdBar, trend, forecast, ratio, timeline }
enum class PulseAvailability { available, earlyEstimate, waitingForData, notApplicable, calculationError }

data class PulseThresholdDefinition(
    val key: String = "primary",
    val unit: PulseValueUnit,
    val defaultValue: Double,
    val minimum: Double,
    val maximum: Double,
    val step: Double,
) {
    companion object {
        fun percent(default: Double, minimum: Double, maximum: Double, step: Double) =
            PulseThresholdDefinition(unit = PulseValueUnit.percent, defaultValue = default, minimum = minimum, maximum = maximum, step = step)
        fun currency(default: Double, minimum: Double, maximum: Double, step: Double) =
            PulseThresholdDefinition(unit = PulseValueUnit.currency, defaultValue = default, minimum = minimum, maximum = maximum, step = step)
        fun ratio(default: Double, minimum: Double, maximum: Double, step: Double) =
            PulseThresholdDefinition(unit = PulseValueUnit.ratio, defaultValue = default, minimum = minimum, maximum = maximum, step = step)
        fun days(default: Double, minimum: Double, maximum: Double, step: Double) =
            PulseThresholdDefinition(unit = PulseValueUnit.days, defaultValue = default, minimum = minimum, maximum = maximum, step = step)
        fun count(default: Double, minimum: Double, maximum: Double, step: Double) =
            PulseThresholdDefinition(unit = PulseValueUnit.count, defaultValue = default, minimum = minimum, maximum = maximum, step = step)
    }
}

data class PulsePoint(
    val x: Long,
    val label: String? = null,
    /** Canonical category, partner or occurrence ID for target-aware signals. */
    val targetKey: String? = null,
    val actual: Long? = null,
    val baseline: Long? = null,
    val momentum: Long? = null,
    val reference: Long? = null,
)

data class PulseSeries(
    val key: String,
    val labelHu: String,
    val points: List<PulsePoint>,
)

data class PulseThresholdValue(
    val key: String,
    val value: Double,
    val definition: PulseThresholdDefinition,
    val isUserDefined: Boolean,
)

data class PulseIndicatorSnapshot(
    val id: PulseIndicatorId,
    val availability: PulseAvailability,
    val value: Double?,
    val secondaryValue: Double? = null,
    val summaryHu: String,
    val missingReasonsHu: List<String> = emptyList(),
    val sampleCount: Int = 0,
    val series: List<PulseSeries> = emptyList(),
    val thresholds: List<PulseThresholdValue>,
    val sources: List<String>,
    /** Measurement used by the raw-signal evaluator when it differs from card value. */
    val signalMetricKey: String = "primary",
    val signalMetricValue: Double? = value,
    /** Compact raw-signal state; detailed trace is fetched on demand. */
    val signalSummaries: List<PulseSignalSummary> = emptyList(),
)

data class PulseSourceOption(
    val targetKey: String,
    val labelHu: String,
    val kind: String,
    val isSelected: Boolean,
)

data class PulseDashboardSnapshot(
    val year: Int,
    val month: Int,
    val coreRevision: Long,
    val generatedAtUtcMs: Long,
    val indicators: List<PulseIndicatorSnapshot>,
    val subscriptionOptions: List<PulseSourceOption> = emptyList(),
)
