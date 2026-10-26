package com.fluvi.core.pulse

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class PulseSignalStateReducerTest {
    @Test
    fun catalogDefinesAllTwentyOneIndicatorsExactlyOnce() {
        assertEquals(21, PulseSignalRuleCatalog.all().size)
        assertEquals(21, PulseSignalRuleCatalog.all().map { it.indicatorId }.toSet().size)
        assertEquals(
            PulseSignalComparisonOperator.lessThanOrEqual,
            PulseSignalRuleCatalog.ruleFor(PulseIndicatorId.netCashflowForecast).comparisonOperator,
        )
        assertTrue(PulseSignalRuleCatalog.ruleFor(PulseIndicatorId.subscriptionLoad).requiresPositiveThreshold)
    }

    @Test
    fun catalogKeepsTheIndicatorSpecificThresholdDirections() {
        val expected = mapOf(
            PulseIndicatorId.monthlyBudgetUtilization to PulseSignalComparisonOperator.greaterThanOrEqual,
            PulseIndicatorId.categoryBudgetUtilization to PulseSignalComparisonOperator.greaterThanOrEqual,
            PulseIndicatorId.spendingMomentum to PulseSignalComparisonOperator.greaterThanOrEqual,
            PulseIndicatorId.monthEndForecast to PulseSignalComparisonOperator.greaterThanOrEqual,
            PulseIndicatorId.limitCrossing to PulseSignalComparisonOperator.dueWithin,
            PulseIndicatorId.spendingOutlier to PulseSignalComparisonOperator.deviationAbove,
            PulseIndicatorId.spendingConcentration to PulseSignalComparisonOperator.greaterThanOrEqual,
            PulseIndicatorId.incomeExpenseRatio to PulseSignalComparisonOperator.greaterThanOrEqual,
            PulseIndicatorId.netCashflowForecast to PulseSignalComparisonOperator.lessThanOrEqual,
            PulseIndicatorId.fixedBurdenCoverage to PulseSignalComparisonOperator.lessThanOrEqual,
            PulseIndicatorId.lateIncome to PulseSignalComparisonOperator.overdueBy,
            PulseIndicatorId.reserveCoverDays to PulseSignalComparisonOperator.lessThanOrEqual,
            PulseIndicatorId.negativeTrajectory to PulseSignalComparisonOperator.dueWithin,
            PulseIndicatorId.cashflowStability to PulseSignalComparisonOperator.greaterThanOrEqual,
            PulseIndicatorId.recurringBurden to PulseSignalComparisonOperator.greaterThanOrEqual,
            PulseIndicatorId.subscriptionLoad to PulseSignalComparisonOperator.greaterThanOrEqual,
            PulseIndicatorId.upcomingGhostLoad to PulseSignalComparisonOperator.greaterThanOrEqual,
            PulseIndicatorId.uncategorizedTransactions to PulseSignalComparisonOperator.greaterThanOrEqual,
            PulseIndicatorId.categoryOverrideAnomaly to PulseSignalComparisonOperator.greaterThanOrEqual,
            PulseIndicatorId.uncertainPushRecognition to PulseSignalComparisonOperator.greaterThanOrEqual,
            PulseIndicatorId.processingBacklog to PulseSignalComparisonOperator.greaterThanOrEqual,
        )

        expected.forEach { (indicator, operator) ->
            assertEquals(operator, PulseSignalRuleCatalog.ruleFor(indicator).comparisonOperator)
        }
        assertEquals(
            PulseSignalTargetStrategy.category,
            PulseSignalRuleCatalog.ruleFor(PulseIndicatorId.categoryBudgetUtilization).targetStrategy,
        )
        assertEquals(
            PulseSignalTargetStrategy.partner,
            PulseSignalRuleCatalog.ruleFor(PulseIndicatorId.categoryOverrideAnomaly).targetStrategy,
        )
        assertEquals(
            PulseSignalTargetStrategy.occurrence,
            PulseSignalRuleCatalog.ruleFor(PulseIndicatorId.lateIncome).targetStrategy,
        )
    }

    @Test
    fun confirmationHysteresisAndIdempotencyAreDeterministic() {
        val rule = PulseSignalRuleCatalog.ruleFor(PulseIndicatorId.spendingMomentum)
        val first = raw(value = 1.45, revision = 1)
        val pending = PulseSignalStateReducer.reduce(null, first, rule)
        assertEquals(PulseSignalActivityState.pendingConfirmation, pending.next.activityState)

        val second = raw(value = 1.45, revision = 2)
        val active = PulseSignalStateReducer.reduce(pending.next, second, rule)
        assertEquals(PulseSignalActivityState.active, active.next.activityState)
        assertEquals(PulseSignalEventKind.activated, active.event)

        // 1.27 is below activation 1.30 but not below the 5% resolution
        // threshold (1.235); the active state is preserved instead of flapping.
        val withinDeadBand = raw(value = 1.27, revision = 3, condition = false)
        val stable = PulseSignalStateReducer.reduce(active.next, withinDeadBand, rule)
        assertEquals(PulseSignalActivityState.active, stable.next.activityState)

        val recovered = raw(value = 1.10, revision = 4, condition = false)
        val recovering = PulseSignalStateReducer.reduce(stable.next, recovered, rule)
        assertEquals(PulseSignalActivityState.recovering, recovering.next.activityState)
        val resolved = PulseSignalStateReducer.reduce(recovering.next, raw(value = 1.10, revision = 5, condition = false), rule)
        assertEquals(PulseSignalActivityState.resolved, resolved.next.activityState)

        val noop = PulseSignalStateReducer.reduce(resolved.next, raw(value = 1.10, revision = 5, condition = false), rule)
        assertNull(noop.event)
        assertEquals(resolved.next, noop.next)
    }

    @Test
    fun suspendedEvaluationNeverSilentlyResolvesAnActiveSignal() {
        val rule = PulseSignalRuleCatalog.ruleFor(PulseIndicatorId.spendingMomentum)
        val active = PulseSignalStateReducer.reduce(
            null,
            raw(value = 1.8, revision = 1, condition = true, confirmationRequired = 1),
            rule.copy(confirmationsRequired = 1),
        ).next
        val suspendedRaw = raw(
            value = null,
            revision = 2,
            condition = false,
            quality = PulseSignalDataQuality.insufficient,
        )
        val suspended = PulseSignalStateReducer.reduce(active, suspendedRaw, rule)
        assertEquals(PulseSignalActivityState.evaluationSuspended, suspended.next.activityState)
        assertEquals(PulseSignalStrength.medium, suspended.next.strength)
    }

    @Test
    fun thresholdConfigurationChangeIsNotRecordedAsANewFinancialActivation() {
        val rule = PulseSignalRuleCatalog.ruleFor(PulseIndicatorId.spendingMomentum).copy(confirmationsRequired = 1)
        val active = PulseSignalStateReducer.reduce(
            null,
            raw(value = 1.8, revision = 1, confirmationRequired = 1),
            rule,
        ).next

        val changed = PulseSignalStateReducer.reduce(
            active,
            raw(value = 1.8, revision = 2, confirmationRequired = 1, configRevision = 2),
            rule,
        )

        assertEquals(PulseSignalActivityState.active, changed.next.activityState)
        assertEquals(PulseSignalEventKind.configurationChanged, changed.event)
    }

    private fun raw(
        value: Double?,
        revision: Long,
        condition: Boolean = true,
        quality: PulseSignalDataQuality = PulseSignalDataQuality.sufficient,
        confirmationRequired: Int = 2,
        configRevision: Long = 0,
    ) = PulseRawSignal(
        signalKey = "PULSE-003/global/2026-10/default",
        indicatorId = PulseIndicatorId.spendingMomentum,
        targetKey = "",
        periodKey = "2026-10",
        scenarioKey = "default",
        measuredValue = value,
        evaluatedMetricKey = "paceRatio",
        thresholdValue = 1.30,
        comparisonOperator = PulseSignalComparisonOperator.greaterThanOrEqual,
        availability = PulseAvailability.available,
        activityState = PulseSignalActivityState.normal,
        strength = null,
        dataQuality = quality,
        evidence = PulseSignalEvidence(
            situationKey = "monthly-budget/2026-10",
            evidenceFamily = "spending-velocity",
            dependencyIds = emptyList(),
            affectedTarget = "",
        ),
        observedDuration = 0,
        trendDirection = "stabil",
        firstObservedAtUtcMs = null,
        lastEvaluatedAtUtcMs = revision * 1_000,
        lastMaterialChangeAtUtcMs = null,
        sourceCoreRevision = revision,
        configRevision = configRevision,
        evaluationFingerprint = "fp-$revision-$value-$condition-$quality-$confirmationRequired",
        trace = PulseSignalEvaluationTrace(
            measuredMetricKey = "paceRatio",
            measuredValue = value,
            thresholdValue = 1.30,
            comparisonOperator = PulseSignalComparisonOperator.greaterThanOrEqual,
            thresholdConditionMet = condition,
            confirmationRequired = confirmationRequired,
            confirmationCount = 0,
            missingInputsHu = emptyList(),
            explanationHu = emptyList(),
        ),
    )
}
