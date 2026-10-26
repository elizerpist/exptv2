package com.fluvi.core.pulse

import androidx.room.withTransaction
import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.entity.FluviPulseSignalEventEntity
import com.fluvi.core.database.entity.FluviPulseSignalStateEntity
import com.fluvi.core.model.FluviClock
import java.security.MessageDigest
import java.time.Instant
import java.time.ZoneId
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.roundToLong

/**
 * Evaluates raw signals from native Pulse measurements. It deliberately has no
 * triage, message, notification, or financial-write capability.
 */
class FluviPulseSignalService internal constructor(
    private val database: FluviDatabase,
    private val measurements: FluviPulseReadService,
    private val clock: FluviClock,
) {
    suspend fun dashboard(
        year: Int,
        month: Int,
        mode: PulseSignalEvaluationMode? = null,
    ): PulseDashboardSnapshot {
        val snapshot = measurements.dashboard(year, month)
        val evaluations = evaluateDashboard(snapshot, mode ?: defaultMode(year, month))
        val byIndicator = evaluations.groupBy { it.signal.indicatorId }
        return snapshot.copy(
            indicators = snapshot.indicators.map { indicator ->
                indicator.copy(
                    signalSummaries = byIndicator[indicator.id]
                        ?.map { it.signal }
                        ?.let(::summaryFor)
                        ?.let(::listOf)
                        ?: emptyList(),
                )
            },
        )
    }

    suspend fun inspect(
        year: Int,
        month: Int,
        indicatorId: String,
        historyLimit: Int = 30,
    ): List<PulseSignalInspectionSnapshot> {
        require(historyLimit in 1..100) { "Pulse signal history limit must be 1..100." }
        val snapshot = measurements.dashboard(year, month)
        val evaluations = evaluateDashboard(
            snapshot,
            defaultMode(year, month),
            PulseIndicatorId.fromStableId(indicatorId),
        )
        return evaluations.map { evaluation ->
            val events = database.pulseSignalDao().eventPage(evaluation.signal.signalKey, historyLimit)
                .map(::eventFromEntity)
            val state = database.pulseSignalDao().state(evaluation.signal.signalKey)?.let(::stateFromEntity)
            PulseSignalInspectionSnapshot(evaluation.signal, events, state)
        }
    }

    /** Intended for lifecycle resume/day rollover; it never mutates Core revision. */
    suspend fun reevaluateCurrent(): PulseDashboardSnapshot {
        val today = localToday()
        return dashboard(today.year, today.monthValue, PulseSignalEvaluationMode.live)
    }

    private data class TargetMeasurement(
        val key: String = "",
        val value: Double?,
        val actualImpactMinor: Long? = null,
        val projectedImpactMinor: Long? = null,
        val affectedBudgetMinor: Long? = null,
        val affectedObligationMinor: Long? = null,
        val impactRatio: Double? = null,
    )

    private data class Evaluation(val signal: PulseRawSignal)

    private suspend fun evaluateDashboard(
        dashboard: PulseDashboardSnapshot,
        mode: PulseSignalEvaluationMode,
        onlyIndicator: PulseIndicatorId? = null,
    ): List<Evaluation> {
        val settings = database.pulseIndicatorSettingsDao().all()
            .associateBy { Triple(it.indicatorId, it.targetKey, it.thresholdKey) }
        val today = localToday()
        val evaluations = dashboard.indicators.asSequence()
            .filter { onlyIndicator == null || it.id == onlyIndicator }
            .flatMap { indicator ->
                val rule = PulseSignalRuleCatalog.ruleFor(indicator.id)
                targetsFor(indicator, rule, today).asSequence().map { target ->
                    val thresholdKey = indicator.thresholds.firstOrNull()?.key ?: "primary"
                    val setting = settings[Triple(indicator.id.stableId, target.key, thresholdKey)]
                        // Target-specific values are optional. A normal Pulse
                        // threshold applies to every category/partner target.
                        ?: settings[Triple(indicator.id.stableId, "", thresholdKey)]
                    val threshold = setting?.value
                        ?: indicator.thresholds.firstOrNull()?.value
                    evaluate(
                        dashboard = dashboard,
                        indicator = indicator,
                        rule = rule,
                        target = target,
                        threshold = threshold,
                        configRevision = setting?.updatedAtUtcMs ?: 0L,
                    )
                }
            }
            .toList()
        return if (mode == PulseSignalEvaluationMode.live) {
            buildList(evaluations.size) {
                evaluations.forEach { add(persist(it)) }
            }
        } else {
            evaluations
        }
    }

    private fun targetsFor(
        indicator: PulseIndicatorSnapshot,
        rule: PulseSignalRuleDefinition,
        today: java.time.LocalDate,
    ): List<TargetMeasurement> = when (rule.targetStrategy) {
        PulseSignalTargetStrategy.category -> indicator.series.firstOrNull { it.key == "categories" }
            ?.points?.mapNotNull { point ->
                val actual = point.actual ?: return@mapNotNull null
                val limit = point.reference ?: return@mapNotNull null
                point.targetKey?.let {
                    TargetMeasurement(
                        key = it,
                        value = actual * 100.0 / max(1L, limit),
                        actualImpactMinor = (actual - limit).coerceAtLeast(0L),
                        affectedBudgetMinor = limit,
                        impactRatio = actual.toDouble() / max(1L, limit),
                    )
                }
            }.orEmpty()
        PulseSignalTargetStrategy.partner -> indicator.series.firstOrNull { it.key == "overrides" }
            ?.points?.mapNotNull { point ->
                val overridden = point.actual ?: return@mapNotNull null
                val count = point.reference ?: return@mapNotNull null
                point.targetKey?.let {
                    TargetMeasurement(
                        key = it,
                        value = overridden * 100.0 / max(1L, count),
                        impactRatio = overridden.toDouble() / max(1L, count),
                    )
                }
            }.orEmpty()
        PulseSignalTargetStrategy.occurrence -> indicator.series.firstOrNull { it.key == "lateIncome" }
            ?.points?.mapNotNull { point ->
                point.targetKey?.let {
                    TargetMeasurement(
                        key = it,
                        value = (today.toEpochDay() - point.x).toDouble(),
                        actualImpactMinor = point.actual,
                        affectedObligationMinor = point.actual,
                    )
                }
            }.orEmpty()
        PulseSignalTargetStrategy.global -> listOf(globalTarget(indicator))
    }.ifEmpty { listOf(globalTarget(indicator)) }

    private fun globalTarget(indicator: PulseIndicatorSnapshot): TargetMeasurement {
        val gauge = indicator.series.firstOrNull { it.key == "gauge" }?.points?.firstOrNull()
        val actual = gauge?.actual
        val reference = gauge?.reference
        val value = indicator.signalMetricValue
        val impact = when (indicator.id) {
            PulseIndicatorId.monthlyBudgetUtilization ->
                actual?.let { spent -> reference?.let { (spent - it).coerceAtLeast(0L) } }
            PulseIndicatorId.monthEndForecast -> value?.roundToLong()?.coerceAtLeast(0L)
            PulseIndicatorId.netCashflowForecast -> value?.roundToLong()?.let { (-it).coerceAtLeast(0L) }
            PulseIndicatorId.lateIncome -> indicator.series.firstOrNull()?.points?.sumOf { it.actual ?: 0L }
            PulseIndicatorId.recurringBurden,
            PulseIndicatorId.subscriptionLoad,
            PulseIndicatorId.upcomingGhostLoad,
            -> value?.roundToLong()
            else -> null
        }
        return TargetMeasurement(
            value = value,
            actualImpactMinor = if (indicator.id == PulseIndicatorId.monthlyBudgetUtilization) impact else null,
            projectedImpactMinor = when (indicator.id) {
                PulseIndicatorId.monthEndForecast,
                PulseIndicatorId.netCashflowForecast,
                PulseIndicatorId.recurringBurden,
                PulseIndicatorId.subscriptionLoad,
                PulseIndicatorId.upcomingGhostLoad,
                -> impact
                else -> null
            },
            affectedBudgetMinor = reference,
            affectedObligationMinor = if (indicator.id == PulseIndicatorId.lateIncome) impact else null,
            impactRatio = if (actual != null && reference != null) actual.toDouble() / max(1L, reference) else null,
        )
    }

    private fun evaluate(
        dashboard: PulseDashboardSnapshot,
        indicator: PulseIndicatorSnapshot,
        rule: PulseSignalRuleDefinition,
        target: TargetMeasurement,
        threshold: Double?,
        configRevision: Long,
    ): Evaluation {
        val periodKey = "%04d-%02d".format(java.util.Locale.ROOT, dashboard.year, dashboard.month)
        val scenarioKey = if (indicator.id == PulseIndicatorId.monthEndForecast) "baseline" else "default"
        val signalKey = listOf(indicator.id.stableId, target.key.ifBlank { "global" }, periodKey, scenarioKey).joinToString("/")
        val configured = threshold != null && (!rule.requiresPositiveThreshold || threshold > 0.0)
        val quality = if (!configured && rule.requiresPositiveThreshold) {
            PulseSignalDataQuality.insufficient
        } else {
            qualityFor(indicator.availability)
        }
        val met = (quality == PulseSignalDataQuality.sufficient || quality == PulseSignalDataQuality.limited) &&
            configured && condition(rule.comparisonOperator, target.value, threshold)
        val missing = buildList {
            addAll(indicator.missingReasonsHu)
            if (!configured) add("A jelhez pozitív, felhasználó által konfigurált küszöb szükséges.")
            if (target.value == null && quality != PulseSignalDataQuality.notApplicable) add("Nincs kiértékelhető mérési érték.")
        }.distinct()
        val evidence = PulseSignalEvidence(
            situationKey = situationKey(indicator.id, target.key, periodKey),
            evidenceFamily = rule.evidenceFamily,
            dependencyIds = rule.dependencyIds,
            affectedTarget = target.key,
            actualImpactMinor = target.actualImpactMinor,
            projectedImpactMinor = target.projectedImpactMinor,
            affectedBudgetMinor = target.affectedBudgetMinor,
            affectedObligationMinor = target.affectedObligationMinor,
            impactRatio = target.impactRatio,
        )
        val fingerprint = fingerprint(
            listOf(
                signalKey, target.value, threshold, met, indicator.availability.name,
                dashboard.coreRevision, evidence.actualImpactMinor, evidence.projectedImpactMinor,
                configRevision,
            ).joinToString("|"),
        )
        return Evaluation(
            PulseRawSignal(
                signalKey = signalKey,
                indicatorId = indicator.id,
                targetKey = target.key,
                periodKey = periodKey,
                scenarioKey = scenarioKey,
                measuredValue = target.value,
                evaluatedMetricKey = rule.metricKey,
                thresholdValue = threshold,
                comparisonOperator = rule.comparisonOperator,
                availability = indicator.availability,
                activityState = if (quality == PulseSignalDataQuality.sufficient || quality == PulseSignalDataQuality.limited) PulseSignalActivityState.normal else PulseSignalActivityState.evaluationSuspended,
                strength = null,
                dataQuality = quality,
                evidence = evidence,
                observedDuration = 0,
                trendDirection = trendDirection(indicator),
                firstObservedAtUtcMs = null,
                lastEvaluatedAtUtcMs = dashboard.generatedAtUtcMs,
                lastMaterialChangeAtUtcMs = null,
                sourceCoreRevision = dashboard.coreRevision,
                configRevision = configRevision,
                evaluationFingerprint = fingerprint,
                trace = PulseSignalEvaluationTrace(
                    measuredMetricKey = rule.metricKey,
                    measuredValue = target.value,
                    thresholdValue = threshold,
                    comparisonOperator = rule.comparisonOperator,
                    thresholdConditionMet = met,
                    confirmationRequired = rule.confirmationsRequired,
                    confirmationCount = 0,
                    missingInputsHu = missing,
                    explanationHu = listOf(
                        if (met) "A küszöbfeltétel teljesült." else "A küszöbfeltétel nem teljesült.",
                        "A kiértékelés csak nyers jelállapotot vezet; nem indít üzenetet vagy pénzügyi műveletet.",
                    ),
                ),
            ),
        )
    }

    private suspend fun persist(evaluation: Evaluation): Evaluation = database.withTransaction {
        val raw = evaluation.signal
        val previous = database.pulseSignalDao().state(raw.signalKey)?.let(::stateFromEntity)
        val reduction = PulseSignalStateReducer.reduce(previous, raw, PulseSignalRuleCatalog.ruleFor(raw.indicatorId))
        val signal = raw.copy(
            activityState = reduction.next.activityState,
            strength = reduction.next.strength,
            observedDuration = reduction.next.confirmationCount,
            firstObservedAtUtcMs = reduction.next.firstObservedAtUtcMs,
            lastMaterialChangeAtUtcMs = reduction.next.lastMaterialChangeAtUtcMs,
            trace = raw.trace.copy(confirmationCount = reduction.next.confirmationCount),
        )
        database.pulseSignalDao().upsertState(stateEntity(signal, reduction.next))
        reduction.event?.let { event ->
            database.pulseSignalDao().insertEvent(eventEntity(signal, previous, event, reduction.cause))
        }
        Evaluation(signal)
    }

    private fun stateEntity(signal: PulseRawSignal, state: PulseSignalState) = FluviPulseSignalStateEntity(
        signalKey = signal.signalKey,
        indicatorId = signal.indicatorId.stableId,
        targetKey = signal.targetKey,
        periodKey = signal.periodKey,
        scenarioKey = signal.scenarioKey,
        activityState = state.activityState.name,
        strength = state.strength?.name,
        previousStrength = state.previousStrength?.name,
        dataQuality = state.dataQuality.name,
        confirmationCount = state.confirmationCount,
        measuredValue = signal.measuredValue,
        thresholdValue = signal.thresholdValue,
        firstObservedAtUtcMs = state.firstObservedAtUtcMs,
        lastEvaluatedAtUtcMs = state.lastEvaluatedAtUtcMs,
        lastMaterialChangeAtUtcMs = state.lastMaterialChangeAtUtcMs,
        lastInputRevision = state.lastInputRevision,
        lastConfigRevision = state.lastConfigRevision,
        evaluationFingerprint = state.evaluationFingerprint,
        situationKey = signal.evidence.situationKey,
        evidenceFamily = signal.evidence.evidenceFamily,
        tracePayload = tracePayload(signal),
        updatedAtUtcMs = signal.lastEvaluatedAtUtcMs,
    )

    private fun eventEntity(
        signal: PulseRawSignal,
        previous: PulseSignalState?,
        kind: PulseSignalEventKind,
        cause: String,
    ) = FluviPulseSignalEventEntity(
        eventId = fingerprint(signal.signalKey + "|" + signal.evaluationFingerprint + "|" + kind.name),
        signalKey = signal.signalKey,
        eventKind = kind.name,
        previousState = previous?.activityState?.name,
        nextState = signal.activityState.name,
        previousStrength = previous?.strength?.name,
        nextStrength = signal.strength?.name,
        measuredValue = signal.measuredValue,
        thresholdValue = signal.thresholdValue,
        inputRevision = signal.sourceCoreRevision,
        configRevision = signal.configRevision,
        cause = cause,
        evaluationFingerprint = signal.evaluationFingerprint,
        tracePayload = tracePayload(signal),
        createdAtUtcMs = signal.lastEvaluatedAtUtcMs,
    )

    private fun stateFromEntity(entity: FluviPulseSignalStateEntity) = PulseSignalState(
        signalKey = entity.signalKey,
        activityState = PulseSignalActivityState.valueOf(entity.activityState),
        strength = entity.strength?.let(PulseSignalStrength::valueOf),
        previousStrength = entity.previousStrength?.let(PulseSignalStrength::valueOf),
        dataQuality = PulseSignalDataQuality.valueOf(entity.dataQuality),
        confirmationCount = entity.confirmationCount,
        firstObservedAtUtcMs = entity.firstObservedAtUtcMs,
        lastEvaluatedAtUtcMs = entity.lastEvaluatedAtUtcMs,
        lastMaterialChangeAtUtcMs = entity.lastMaterialChangeAtUtcMs,
        lastInputRevision = entity.lastInputRevision,
        lastConfigRevision = entity.lastConfigRevision,
        evaluationFingerprint = entity.evaluationFingerprint,
    )

    private fun eventFromEntity(entity: FluviPulseSignalEventEntity) = PulseSignalEvent(
        eventId = entity.eventId,
        signalKey = entity.signalKey,
        kind = PulseSignalEventKind.valueOf(entity.eventKind),
        previousState = entity.previousState?.let(PulseSignalActivityState::valueOf),
        nextState = PulseSignalActivityState.valueOf(entity.nextState),
        previousStrength = entity.previousStrength?.let(PulseSignalStrength::valueOf),
        nextStrength = entity.nextStrength?.let(PulseSignalStrength::valueOf),
        measuredValue = entity.measuredValue,
        thresholdValue = entity.thresholdValue,
        timestampUtcMs = entity.createdAtUtcMs,
        inputRevision = entity.inputRevision,
        configRevision = entity.configRevision,
        cause = entity.cause,
        evaluationFingerprint = entity.evaluationFingerprint,
    )

    private fun summaryFor(signals: List<PulseRawSignal>): PulseSignalSummary {
        val leader = signals.maxWithOrNull(
            compareBy<PulseRawSignal> { it.strength?.ordinal ?: -1 }.thenBy { it.activityState.ordinal },
        ) ?: signals.first()
        return PulseSignalSummary(
            activityState = leader.activityState,
            strength = leader.strength,
            dataQuality = leader.dataQuality,
            activeSignalCount = signals.count {
                it.activityState == PulseSignalActivityState.active ||
                    it.activityState == PulseSignalActivityState.recovering
            },
            totalSignalCount = signals.size,
        )
    }

    private fun qualityFor(availability: PulseAvailability) = when (availability) {
        PulseAvailability.available -> PulseSignalDataQuality.sufficient
        PulseAvailability.earlyEstimate -> PulseSignalDataQuality.limited
        PulseAvailability.waitingForData, PulseAvailability.calculationError -> PulseSignalDataQuality.insufficient
        PulseAvailability.notApplicable -> PulseSignalDataQuality.notApplicable
    }

    private fun condition(operator: PulseSignalComparisonOperator, value: Double?, threshold: Double?): Boolean {
        if (value == null || threshold == null) return false
        return when (operator) {
            PulseSignalComparisonOperator.greaterThan -> value > threshold
            PulseSignalComparisonOperator.greaterThanOrEqual,
            PulseSignalComparisonOperator.deviationAbove,
            PulseSignalComparisonOperator.overdueBy,
            -> value >= threshold
            PulseSignalComparisonOperator.lessThan -> value < threshold
            PulseSignalComparisonOperator.lessThanOrEqual -> value <= threshold
            PulseSignalComparisonOperator.dueWithin -> value >= 0.0 && value <= threshold
            PulseSignalComparisonOperator.outsideRange -> abs(value) >= abs(threshold)
        }
    }

    private fun situationKey(id: PulseIndicatorId, target: String, period: String): String = when (id) {
        PulseIndicatorId.monthlyBudgetUtilization,
        PulseIndicatorId.spendingMomentum,
        PulseIndicatorId.monthEndForecast,
        PulseIndicatorId.limitCrossing,
        -> "monthly-budget/" + period
        PulseIndicatorId.categoryBudgetUtilization -> "category-budget/" + target + "/" + period
        PulseIndicatorId.lateIncome -> "recurring-due/" + target
        PulseIndicatorId.uncertainPushRecognition -> "parser-review/" + period
        PulseIndicatorId.processingBacklog -> "processing-health/" + period
        PulseIndicatorId.netCashflowForecast,
        PulseIndicatorId.incomeExpenseRatio,
        PulseIndicatorId.cashflowStability,
        PulseIndicatorId.fixedBurdenCoverage,
        PulseIndicatorId.reserveCoverDays,
        PulseIndicatorId.negativeTrajectory,
        -> "cashflow/" + period
        else -> id.stableId.lowercase() + "/" + target.ifBlank { "global" } + "/" + period
    }

    private fun trendDirection(indicator: PulseIndicatorSnapshot): String = when {
        indicator.secondaryValue == null || indicator.value == null -> "ismeretlen"
        indicator.secondaryValue > indicator.value -> "erősödő"
        indicator.secondaryValue < indicator.value -> "gyengülő"
        else -> "stabil"
    }

    private fun tracePayload(signal: PulseRawSignal): String = listOf(
        "v1",
        signal.evaluatedMetricKey,
        signal.measuredValue,
        signal.thresholdValue,
        signal.comparisonOperator.name,
        signal.activityState.name,
        signal.strength?.name,
        signal.dataQuality.name,
        signal.evidence.situationKey,
        signal.evidence.evidenceFamily,
    ).joinToString("|")

    private suspend fun defaultMode(year: Int, month: Int): PulseSignalEvaluationMode {
        val today = localToday()
        return if (today.year == year && today.monthValue == month) {
            PulseSignalEvaluationMode.live
        } else {
            PulseSignalEvaluationMode.historicalInspection
        }
    }

    private suspend fun localToday(): java.time.LocalDate {
        val app = requireNotNull(database.appSettingsDao().current())
        return Instant.ofEpochMilli(clock.nowUtcMs()).atZone(ZoneId.of(app.localZoneId)).toLocalDate()
    }

    private fun fingerprint(value: String): String = MessageDigest.getInstance("SHA-256")
        .digest(value.toByteArray())
        .joinToString("") { "%02x".format(it) }
}

/** Pure state reducer. Repeating an identical fingerprint is a no-op. */
object PulseSignalStateReducer {
    data class Result(
        val next: PulseSignalState,
        val event: PulseSignalEventKind?,
        val cause: String,
    )

    fun reduce(
        previous: PulseSignalState?,
        raw: PulseRawSignal,
        rule: PulseSignalRuleDefinition,
    ): Result {
        if (previous?.evaluationFingerprint == raw.evaluationFingerprint) {
            return Result(previous, null, "Azonos bemeneti és konfigurációs revízió.")
        }
        val now = raw.lastEvaluatedAtUtcMs
        val evaluable = raw.dataQuality == PulseSignalDataQuality.sufficient ||
            raw.dataQuality == PulseSignalDataQuality.limited
        if (!evaluable) {
            val next = state(raw, previous, PulseSignalActivityState.evaluationSuspended, previous?.strength, previous?.confirmationCount ?: 0, previous?.firstObservedAtUtcMs, now)
            val event = if (previous?.activityState != PulseSignalActivityState.evaluationSuspended) PulseSignalEventKind.evaluationSuspended else null
            return Result(next, event, "A méréshez szükséges adat átmenetileg nem elérhető.")
        }

        val met = raw.trace.thresholdConditionMet
        val resolvedThreshold = resolutionCondition(raw, rule)
        val prior = previous?.activityState ?: PulseSignalActivityState.normal
        val confirmations = if (met) {
            if (previous == null || previous.lastInputRevision != raw.sourceCoreRevision) (previous?.confirmationCount ?: 0) + 1 else previous.confirmationCount
        } else 0
        val candidate = if (met) strengthFor(raw, rule) else null
        val activity = when {
            met && prior == PulseSignalActivityState.normal ->
                if (confirmations >= rule.confirmationsRequired) PulseSignalActivityState.active else PulseSignalActivityState.pendingConfirmation
            met && prior == PulseSignalActivityState.pendingConfirmation ->
                if (confirmations >= rule.confirmationsRequired) PulseSignalActivityState.active else PulseSignalActivityState.pendingConfirmation
            met && (prior == PulseSignalActivityState.recovering || prior == PulseSignalActivityState.resolved) -> PulseSignalActivityState.active
            met && prior == PulseSignalActivityState.evaluationSuspended ->
                if (confirmations >= rule.confirmationsRequired) PulseSignalActivityState.active else PulseSignalActivityState.pendingConfirmation
            met -> prior
            prior == PulseSignalActivityState.active && resolvedThreshold -> PulseSignalActivityState.recovering
            prior == PulseSignalActivityState.active -> PulseSignalActivityState.active
            prior == PulseSignalActivityState.recovering && resolvedThreshold -> PulseSignalActivityState.resolved
            prior == PulseSignalActivityState.recovering -> PulseSignalActivityState.recovering
            prior == PulseSignalActivityState.pendingConfirmation -> PulseSignalActivityState.normal
            prior == PulseSignalActivityState.evaluationSuspended -> PulseSignalActivityState.normal
            else -> PulseSignalActivityState.normal
        }
        val strength = when (activity) {
            PulseSignalActivityState.active -> candidate
            PulseSignalActivityState.recovering -> previous?.strength
            else -> null
        }
        val next = state(
            raw,
            previous,
            activity,
            strength,
            confirmations,
            if (activity == PulseSignalActivityState.pendingConfirmation || activity == PulseSignalActivityState.active) previous?.firstObservedAtUtcMs ?: now else previous?.firstObservedAtUtcMs,
            if (prior != activity || previous?.strength != strength) now else previous?.lastMaterialChangeAtUtcMs,
        )
        val event = eventFor(previous, activity, strength, raw)
        val cause = when {
            previous != null && previous.lastConfigRevision != raw.configRevision -> "A felhasználói küszöb vagy konfiguráció megváltozott."
            met -> "A kiértékelt küszöbfeltétel teljesült."
            else -> "A feloldási feltétel teljesült vagy a megerősítés megszakadt."
        }
        return Result(next, event, cause)
    }

    /**
     * Activation always uses the user threshold. Resolution moves beyond a
     * documented indicator-specific dead band so a value hovering at the
     * threshold cannot flap active/resolved on consecutive revisions.
     */
    private fun resolutionCondition(
        raw: PulseRawSignal,
        rule: PulseSignalRuleDefinition,
    ): Boolean {
        val value = raw.measuredValue ?: return true
        val threshold = raw.thresholdValue ?: return true
        val margin = abs(threshold) * rule.resolutionHysteresisRatio
        return when (raw.comparisonOperator) {
            PulseSignalComparisonOperator.greaterThan,
            PulseSignalComparisonOperator.greaterThanOrEqual,
            PulseSignalComparisonOperator.deviationAbove,
            PulseSignalComparisonOperator.overdueBy,
            -> value < threshold - margin
            PulseSignalComparisonOperator.lessThan,
            PulseSignalComparisonOperator.lessThanOrEqual,
            -> value > threshold + max(1.0, margin)
            PulseSignalComparisonOperator.dueWithin -> value > threshold
            PulseSignalComparisonOperator.outsideRange -> abs(value) < abs(threshold) - margin
        }
    }

    private fun state(
        raw: PulseRawSignal,
        previous: PulseSignalState?,
        activity: PulseSignalActivityState,
        strength: PulseSignalStrength?,
        confirmations: Int,
        firstObserved: Long?,
        changedAt: Long?,
    ) = PulseSignalState(
        signalKey = raw.signalKey,
        activityState = activity,
        strength = strength,
        previousStrength = previous?.strength,
        dataQuality = raw.dataQuality,
        confirmationCount = confirmations,
        firstObservedAtUtcMs = firstObserved,
        lastEvaluatedAtUtcMs = raw.lastEvaluatedAtUtcMs,
        lastMaterialChangeAtUtcMs = changedAt,
        lastInputRevision = raw.sourceCoreRevision,
        lastConfigRevision = raw.configRevision,
        evaluationFingerprint = raw.evaluationFingerprint,
    )

    private fun eventFor(
        previous: PulseSignalState?,
        next: PulseSignalActivityState,
        strength: PulseSignalStrength?,
        raw: PulseRawSignal,
    ): PulseSignalEventKind? {
        val prior = previous?.activityState
        if (previous == null) {
            return when (next) {
                PulseSignalActivityState.active -> PulseSignalEventKind.activated
                PulseSignalActivityState.evaluationSuspended -> PulseSignalEventKind.evaluationSuspended
                else -> null
            }
        }
        // A threshold/settings change is diagnostic configuration evidence. It
        // must not be represented as a newly observed financial incident.
        if (previous.lastConfigRevision != raw.configRevision) {
            return PulseSignalEventKind.configurationChanged
        }
        if (prior == PulseSignalActivityState.evaluationSuspended && next != prior) return PulseSignalEventKind.evaluationRestored
        if (next == PulseSignalActivityState.evaluationSuspended && prior != next) return PulseSignalEventKind.evaluationSuspended
        if (prior == PulseSignalActivityState.resolved && next == PulseSignalActivityState.active) return PulseSignalEventKind.reactivated
        if (next == PulseSignalActivityState.active && prior != PulseSignalActivityState.active) return PulseSignalEventKind.activated
        if (next == PulseSignalActivityState.resolved && prior != next) return PulseSignalEventKind.resolved
        if (prior == PulseSignalActivityState.active && next == PulseSignalActivityState.recovering) return PulseSignalEventKind.weakened
        if (previous.strength != null && strength != null && strength.ordinal > previous.strength.ordinal) return PulseSignalEventKind.strengthened
        if (previous.strength != null && strength != null && strength.ordinal < previous.strength.ordinal) return PulseSignalEventKind.weakened
        return null
    }

    fun strengthFor(raw: PulseRawSignal, rule: PulseSignalRuleDefinition): PulseSignalStrength {
        val value = raw.measuredValue ?: return PulseSignalStrength.weak
        val threshold = raw.thresholdValue ?: return PulseSignalStrength.weak
        val distance = when (raw.comparisonOperator) {
            PulseSignalComparisonOperator.lessThan,
            PulseSignalComparisonOperator.lessThanOrEqual,
            -> (threshold - value) / max(1.0, abs(threshold))
            PulseSignalComparisonOperator.dueWithin -> max(0.0, threshold - value) / max(1.0, threshold)
            else -> (value - threshold) / max(1.0, abs(threshold))
        }.coerceAtLeast(0.0)
        val impact = max(
            raw.evidence.actualImpactMinor?.let { abs(it).toDouble() / 100_000.0 } ?: 0.0,
            raw.evidence.projectedImpactMinor?.let { abs(it).toDouble() / 100_000.0 } ?: 0.0,
        )
        var level = when {
            distance >= 1.5 || impact >= 10.0 -> PulseSignalStrength.critical
            distance >= .75 || impact >= 3.0 -> PulseSignalStrength.strong
            distance >= .25 || impact >= 1.0 -> PulseSignalStrength.medium
            else -> PulseSignalStrength.weak
        }
        if (raw.dataQuality == PulseSignalDataQuality.limited && level.ordinal > PulseSignalStrength.medium.ordinal) level = PulseSignalStrength.medium
        if (level.ordinal > rule.maximumStandaloneStrength.ordinal) level = rule.maximumStandaloneStrength
        return level
    }
}
