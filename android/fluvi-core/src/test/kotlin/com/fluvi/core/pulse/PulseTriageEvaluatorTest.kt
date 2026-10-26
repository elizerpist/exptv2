package com.fluvi.core.pulse

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class PulseTriageEvaluatorTest {
    @Test
    fun forecastChainDoesNotCreateThreeIndependentEvidenceUnits() {
        val input = listOf(
            signal(PulseIndicatorId.spendingMomentum, "ledger-variable-spend/2026-10"),
            signal(
                PulseIndicatorId.monthEndForecast,
                "ledger-variable-spend/2026-10",
                upstream = setOf("PULSE-003/global/2026-10/default"),
            ),
            signal(
                PulseIndicatorId.limitCrossing,
                "ledger-variable-spend/2026-10",
                upstream = setOf("PULSE-004/global/2026-10/baseline"),
            ),
        ).map { PulseEvidenceIndependenceEvaluator.Input(it, descriptorFor(it)) }

        val result = PulseEvidenceIndependenceEvaluator.evaluate(input)

        assertEquals(1, result.units.count { it.countableForFormation })
        assertTrue(result.units.any { it.independence == PulseEvidenceIndependence.derived })
        assertFalse(result.units.drop(1).any { it.countableForFormation })
    }

    @Test
    fun momentumAndSeparatePendingGhostCreateMediumPair() {
        val input = listOf(
            signal(PulseIndicatorId.spendingMomentum, "ledger-variable-spend/2026-10"),
            signal(PulseIndicatorId.upcomingGhostLoad, "occurrence/ghost-01"),
        ).map { PulseEvidenceIndependenceEvaluator.Input(it, descriptorFor(it)) }
        val independence = PulseEvidenceIndependenceEvaluator.evaluate(input)
        val trace = PulseTriageEvaluator.evaluate(
            descriptor = input.first().descriptor,
            signals = input.map { it.signal },
            units = independence.units,
            exclusions = independence.exclusions,
        )

        assertEquals(2, trace.independentEvidenceCount)
        assertEquals(PulseTriageRuleCatalog.mediumPair, trace.matchedRule)
    }

    @Test
    fun threeOverlappingWeakSignalsDoNotOpenWeakTripleGate() {
        val input = listOf(
            signal(PulseIndicatorId.spendingMomentum, "ledger-variable-spend/2026-10", strength = PulseSignalStrength.weak),
            signal(PulseIndicatorId.monthEndForecast, "ledger-variable-spend/2026-10", strength = PulseSignalStrength.weak),
            signal(PulseIndicatorId.limitCrossing, "ledger-variable-spend/2026-10", strength = PulseSignalStrength.weak),
        ).map { PulseEvidenceIndependenceEvaluator.Input(it, descriptorFor(it)) }
        val independence = PulseEvidenceIndependenceEvaluator.evaluate(input)
        val trace = PulseTriageEvaluator.evaluate(input.first().descriptor, input.map { it.signal }, independence.units, independence.exclusions)

        assertFalse(trace.evaluatedRules.first { it.ruleId == PulseTriageRuleCatalog.weakTriple }.passed)
    }

    @Test
    fun validCriticalLeadingSignalOpensCriticalSingleGate() {
        val raw = signal(PulseIndicatorId.monthlyBudgetUtilization, "ledger-aggregate/2026-10", strength = PulseSignalStrength.critical)
        val descriptor = descriptorFor(raw)
        val independence = PulseEvidenceIndependenceEvaluator.evaluate(listOf(PulseEvidenceIndependenceEvaluator.Input(raw, descriptor)))
        val trace = PulseTriageEvaluator.evaluate(descriptor, listOf(raw), independence.units, independence.exclusions)

        assertEquals(PulseTriageRuleCatalog.criticalSingle, trace.matchedRule)
    }

    @Test
    fun materialForecastCanOpenSingleGateButNotInflateIndependentCount() {
        val forecast = signal(
            PulseIndicatorId.monthEndForecast,
            "ledger-variable-spend/2026-10",
            upstream = setOf("PULSE-003/global/2026-10/default"),
            strength = PulseSignalStrength.strong,
        )
        val raw = forecast.copy(
            evidence = forecast.evidence.copy(
                projectedImpactMinor = 1_500_000L,
                affectedBudgetMinor = 10_000_000L,
            ),
        )
        val descriptor = descriptorFor(raw)
        val independence = PulseEvidenceIndependenceEvaluator.evaluate(
            listOf(PulseEvidenceIndependenceEvaluator.Input(raw, descriptor)),
        )
        val trace = PulseTriageEvaluator.evaluate(
            descriptor,
            listOf(raw),
            independence.units,
            independence.exclusions,
        )

        assertEquals(0, trace.independentEvidenceCount)
        assertEquals(PulseTriageRuleCatalog.strongMaterial, trace.matchedRule)
    }

    @Test
    fun unavailableSupportingMetricDoesNotBlockCriticalIndependentFact() {
        val critical = signal(
            PulseIndicatorId.monthlyBudgetUtilization,
            "ledger-aggregate/2026-10",
            strength = PulseSignalStrength.critical,
        )
        val unavailable = signal(
            PulseIndicatorId.spendingMomentum,
            "ledger-variable-spend/2026-10",
        ).copy(dataQuality = PulseSignalDataQuality.insufficient)
        val descriptor = descriptorFor(critical)
        val independence = PulseEvidenceIndependenceEvaluator.evaluate(
            listOf(
                PulseEvidenceIndependenceEvaluator.Input(critical, descriptor),
                PulseEvidenceIndependenceEvaluator.Input(unavailable, descriptorFor(unavailable)),
            ),
        )
        val trace = PulseTriageEvaluator.evaluate(
            descriptor,
            listOf(critical, unavailable),
            independence.units,
            independence.exclusions,
        )

        assertEquals(PulseTriageRuleCatalog.criticalSingle, trace.matchedRule)
    }

    @Test
    fun situationReducerPreservesSuspensionAndUsesVerifiedRecovery() {
        assertEquals(
            PulseSituationState.forming,
            PulseSituationStateReducer.reduce(
                PulseSituationStateReducer.Input(
                    previous = null,
                    hasEvaluableInputs = true,
                    hasFormationEvidence = true,
                    matchedRule = null,
                    configurationOnlyChange = false,
                ),
            ),
        )
        assertEquals(
            PulseSituationState.ready,
            PulseSituationStateReducer.reduce(
                PulseSituationStateReducer.Input(
                    previous = PulseSituationState.forming,
                    hasEvaluableInputs = true,
                    hasFormationEvidence = true,
                    matchedRule = PulseTriageRuleCatalog.mediumPair,
                    configurationOnlyChange = false,
                ),
            ),
        )
        assertEquals(
            PulseSituationState.suspended,
            PulseSituationStateReducer.reduce(
                PulseSituationStateReducer.Input(
                    previous = PulseSituationState.ready,
                    hasEvaluableInputs = false,
                    hasFormationEvidence = false,
                    matchedRule = null,
                    configurationOnlyChange = false,
                ),
            ),
        )
        assertEquals(
            PulseSituationState.improving,
            PulseSituationStateReducer.reduce(
                PulseSituationStateReducer.Input(
                    previous = PulseSituationState.ready,
                    hasEvaluableInputs = true,
                    hasFormationEvidence = false,
                    matchedRule = PulseTriageRuleCatalog.verifiedRecovery,
                    configurationOnlyChange = false,
                ),
            ),
        )
    }

    @Test
    fun thresholdConfigurationChangeIsNotRecordedAsFinancialRecovery() {
        val trace = PulseTriageEvaluator.evaluate(
            descriptor = descriptorFor(signal(PulseIndicatorId.spendingMomentum, "ledger-variable-spend/2026-10")),
            signals = listOf(signal(PulseIndicatorId.spendingMomentum, "ledger-variable-spend/2026-10")),
            units = emptyList(),
            exclusions = emptyList(),
            previousState = PulseSituationState.ready,
            configurationOnlyChange = true,
        )
        assertFalse(trace.evaluatedRules.first {
            it.ruleId == PulseTriageRuleCatalog.verifiedRecovery
        }.passed)
        assertEquals(
            PulseSituationState.resolved,
            PulseSituationStateReducer.reduce(
                PulseSituationStateReducer.Input(
                    previous = PulseSituationState.ready,
                    hasEvaluableInputs = true,
                    hasFormationEvidence = false,
                    matchedRule = trace.matchedRule,
                    configurationOnlyChange = true,
                ),
            ),
        )
    }

    private fun descriptorFor(signal: PulseRawSignal) = PulseSituationCatalog.descriptors(signal)
        .first { it.domain == PulseSituationDomain.monthlyBudget }

    private fun signal(
        id: PulseIndicatorId,
        root: String,
        upstream: Set<String> = emptySet(),
        strength: PulseSignalStrength = PulseSignalStrength.medium,
    ): PulseRawSignal {
        val descriptor = PulseSituationCatalog.descriptors(
            prototype(id, root, upstream, strength),
        ).first { it.domain == PulseSituationDomain.monthlyBudget }
        return prototype(id, root, upstream, strength).copy(
            evidence = prototype(id, root, upstream, strength).evidence.copy(situationKey = descriptor.situationKey),
        )
    }

    private fun prototype(
        id: PulseIndicatorId,
        root: String,
        upstream: Set<String>,
        strength: PulseSignalStrength,
    ) = PulseRawSignal(
        signalKey = "${id.stableId}/global/2026-10/${if (id == PulseIndicatorId.monthEndForecast) "baseline" else "default"}",
        indicatorId = id,
        targetKey = "",
        periodKey = "2026-10",
        scenarioKey = "default",
        measuredValue = 1.8,
        evaluatedMetricKey = "test",
        thresholdValue = 1.2,
        comparisonOperator = PulseSignalComparisonOperator.greaterThanOrEqual,
        availability = PulseAvailability.available,
        activityState = PulseSignalActivityState.active,
        strength = strength,
        dataQuality = PulseSignalDataQuality.sufficient,
        evidence = PulseSignalEvidence(
            situationKey = "monthly-budget/2026-10",
            evidenceFamily = "test",
            dependencyIds = emptyList(),
            affectedTarget = "",
            provenance = PulseEvidenceProvenance(
                evidenceKey = "${id.stableId}/global/2026-10",
                sourceKind = PulseEvidenceSourceKind.bookedLedgerAggregate,
                sourceFactKeys = setOf(root),
                upstreamEvidenceKeys = upstream,
                calculationKey = "test",
                observationWindowKey = "2026-10",
                sourceRevision = 10,
            ),
        ),
        observedDuration = 2,
        trendDirection = "erősödő",
        firstObservedAtUtcMs = 1,
        lastEvaluatedAtUtcMs = 2,
        lastMaterialChangeAtUtcMs = 1,
        sourceCoreRevision = 10,
        configRevision = 0,
        evaluationFingerprint = "${id.stableId}-$root-$strength",
        trace = PulseSignalEvaluationTrace(
            measuredMetricKey = "test",
            measuredValue = 1.8,
            thresholdValue = 1.2,
            comparisonOperator = PulseSignalComparisonOperator.greaterThanOrEqual,
            thresholdConditionMet = true,
            confirmationRequired = 1,
            confirmationCount = 1,
            missingInputsHu = emptyList(),
            explanationHu = emptyList(),
        ),
    )
}
