package com.fluvi.core.pulse

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

class PulseStoryComposerTest {
    @Test
    fun projectedBudgetBreachUsesConditionalHeadlineAndCopyMap() {
        val result = PulseStoryComposer.compose(context(facts = listOf(
            fact(PulseStoryFactKind.projectedBudgetOverrun, PulseStoryCertainty.projected, amount = 2_400_000L),
            fact(PulseStoryFactKind.actualBudgetLimit, PulseStoryCertainty.observed, amount = 20_000_000L),
        )))

        assertEquals(PulseStoryCompositionStatus.composed, result.status)
        assertEquals("A hónap végére túllépheted a kereted.", result.draft!!.headline)
        assertTrue(result.draft!!.detail!!.contains("24 000 Ft"))
        assertEquals(PulseStoryFragmentRole.headline, result.draft!!.fragments.first().role)
        assertTrue(result.draft!!.fragments.all { it.sourceFactKeys.isNotEmpty() })
    }

    @Test
    fun actualBreachDoesNotUseForecastWording() {
        val result = PulseStoryComposer.compose(context(
            leadingIndicator = "PULSE-001",
            facts = listOf(fact(PulseStoryFactKind.actualBudgetOverrun, PulseStoryCertainty.observed, amount = 100_000L)),
        ))

        assertEquals(PulseStoryCompositionStatus.composed, result.status)
        assertEquals("Túllépted a havi kereted.", result.draft!!.headline)
        assertFalse(result.draft!!.headline.contains("túllépheted"))
    }

    @Test
    fun includedGhostIsExplainedAsForecastLineageNotAddedAgain() {
        val result = PulseStoryComposer.compose(context(facts = listOf(
            fact(PulseStoryFactKind.projectedBudgetOverrun, PulseStoryCertainty.projected, amount = 2_400_000L),
            fact(PulseStoryFactKind.actualBudgetLimit, PulseStoryCertainty.observed, amount = 20_000_000L),
            fact(PulseStoryFactKind.knownPendingObligation, PulseStoryCertainty.scheduled, amount = 1_800_000L, included = true),
        )))

        assertEquals(PulseStoryCompositionStatus.composed, result.status)
        assertFalse(result.draft!!.detail!!.contains("18 000 Ft"))
        assertEquals("same-forecast-lineage", result.draft!!.exclusions.single().reasonCode)
    }

    @Test
    fun missingRequiredFactsNeverCreatesFallbackFinancialSentence() {
        val result = PulseStoryComposer.compose(context(facts = emptyList()))

        assertEquals(PulseStoryCompositionStatus.insufficientFacts, result.status)
        assertEquals("missing-headline-facts", result.reasonCode)
        assertTrue(result.draft == null)
    }

    @Test
    fun hungarianFormatterUsesGroupedForintsAndRelativeDates() {
        assertEquals("1 250 000 Ft", PulseHungarianFormatter.money(125_000_000L))
        assertEquals("18,5%", PulseHungarianFormatter.percent(18.5))
        assertEquals("két nap múlva", PulseHungarianFormatter.relativeDate(20_002L, 20_000L * 86_400_000L, "Europe/Budapest"))
    }

    private fun context(
        leadingIndicator: String = "PULSE-004",
        facts: List<PulseStoryFact>,
    ): PulseStoryContext {
        val leading = PulseEvidenceUnit(
            evidenceKey = "evidence/$leadingIndicator", situationKey = "monthly-budget/2026-10",
            sourceSignalKeys = setOf("$leadingIndicator/global/2026-10/default"), sourceFactKeys = setOf("aggregate/monthly-budget"),
            evidenceFamily = "spending-projection", strength = PulseSignalStrength.strong,
            role = PulseEvidenceRole.leading, independence = PulseEvidenceIndependence.independent,
            countableForFormation = true, standaloneEligible = true, reasonCodes = emptyList(), indicatorId = leadingIndicator,
            titleHu = "Hónapvégi forecast", measuredValue = 1.12, dataQuality = PulseSignalDataQuality.sufficient,
            actualImpactMinor = null, projectedImpactMinor = 2_400_000L, affectedBudgetMinor = 20_000_000L,
            affectedObligationMinor = null, impactRatio = 1.12, dueLocalEpochDay = null,
        )
        val situation = PulseSituationSnapshot(
            situationKey = "monthly-budget/2026-10", domain = PulseSituationDomain.monthlyBudget, targetKey = "aggregate", periodKey = "2026-10",
            state = PulseSituationState.ready, formationRule = "strong-material", relatedSignalKeys = leading.sourceSignalKeys.toList(),
            leadingSignalKey = leading.sourceSignalKeys.first(), supportingSignalKeys = emptyList(), evidenceUnits = listOf(leading), independentEvidenceCount = 1,
            decisionTrace = PulseTriageDecisionTrace("monthly-budget/2026-10", emptyList(), "strong-material", 1, 1, listOf(leading.evidenceKey), emptyList(), emptyList(), emptyList(), emptyList(), 1),
            sourceCoreRevision = 7, sourceSignalGeneration = 2, policyVersion = 1, firstObservedAtUtcMs = 1, lastEvaluatedAtUtcMs = 2,
            lastMaterialChangeAtUtcMs = 2, semanticFingerprint = "s", historicalInspection = false,
        )
        val candidate = PulsePriorityCandidate(situation, PulsePriorityCandidateKind.ready, leading.evidenceKey, leading.sourceSignalKeys.first(), leadingIndicator,
            85, emptyList(), 85, 85, PulsePriorityTieBreakFacts(null, null, 3, 2_400_000L, 2), "s", 1, 1)
        return PulseStoryContext("frame", situation, candidate, PulseStoryFactBundle(situation.situationKey, 7, facts), PulseSignalEvaluationMode.live, 1_700_000_000_000L)
    }

    private fun fact(kind: PulseStoryFactKind, certainty: PulseStoryCertainty, amount: Long? = null, included: Boolean = false) = PulseStoryFact(
        factKey = "fact/${kind.name}", kind = kind, sourceSignalKeys = setOf("PULSE-004/global/2026-10/default"),
        sourceEvidenceKeys = setOf("evidence/PULSE-004"), sourceFactKeys = setOf("aggregate/${kind.name}"), certainty = certainty,
        amountMinor = amount, sourceCoreRevision = 7, includedInForecast = included,
    )
}
