package com.fluvi.core.pulse

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Test

class PulseDeliveryIdentityResolverTest {
    @Test
    fun episodeIsStableAcrossCoreRevisionsAndEvaluationTimes() {
        val original = situation(firstObservedAt = 100L)
        val refreshed = original.copy(
            sourceCoreRevision = 99L,
            lastEvaluatedAtUtcMs = 9_999L,
            lastMaterialChangeAtUtcMs = 9_000L,
        )

        assertEquals(
            PulseDeliveryIdentityResolver.situationEpisodeId(original),
            PulseDeliveryIdentityResolver.situationEpisodeId(refreshed),
        )
    }

    @Test
    fun reopenedSituationWithNewObservationStartsAnotherEpisode() {
        assertNotEquals(
            PulseDeliveryIdentityResolver.situationEpisodeId(situation(firstObservedAt = 100L)),
            PulseDeliveryIdentityResolver.situationEpisodeId(situation(firstObservedAt = 200L)),
        )
    }

    @Test
    fun deliveryKeyRequiresMaterialChangeOrExplicitSnoozeIntent() {
        val episode = PulseDeliveryIdentityResolver.situationEpisodeId(situation(firstObservedAt = 100L))
        val automatic = PulseDeliveryIdentityResolver.deliveryKey(episode, "story/monthly-budget/risk", "material-a", "automatic")
        val smallCopyRefresh = PulseDeliveryIdentityResolver.deliveryKey(episode, "story/monthly-budget/risk", "material-a", "automatic")
        val escalated = PulseDeliveryIdentityResolver.deliveryKey(episode, "story/monthly-budget/risk", "material-b", "automatic")
        val granted = PulseDeliveryIdentityResolver.deliveryKey(episode, "story/monthly-budget/risk", "material-a", "snooze-grant-1")

        assertEquals(automatic, smallCopyRefresh)
        assertNotEquals(automatic, escalated)
        assertNotEquals(automatic, granted)
    }

    private fun situation(firstObservedAt: Long): PulseSituationSnapshot {
        val evidence = PulseEvidenceUnit(
            evidenceKey = "monthly-budget/leading",
            situationKey = "monthly-budget/2026-10",
            sourceSignalKeys = setOf("PULSE-004/global/2026-10/default"),
            sourceFactKeys = setOf("aggregate/monthly-budget"),
            evidenceFamily = "spending-projection",
            strength = PulseSignalStrength.strong,
            role = PulseEvidenceRole.leading,
            independence = PulseEvidenceIndependence.independent,
            countableForFormation = true,
            standaloneEligible = true,
            reasonCodes = emptyList(),
            indicatorId = "PULSE-004",
            titleHu = "Hónapvégi forecast",
            measuredValue = 1.12,
            dataQuality = PulseSignalDataQuality.sufficient,
            actualImpactMinor = null,
            projectedImpactMinor = 2_400_000L,
            affectedBudgetMinor = 20_000_000L,
            affectedObligationMinor = null,
            impactRatio = 1.12,
            dueLocalEpochDay = null,
        )
        return PulseSituationSnapshot(
            situationKey = "monthly-budget/2026-10",
            domain = PulseSituationDomain.monthlyBudget,
            targetKey = "aggregate",
            periodKey = "2026-10",
            state = PulseSituationState.ready,
            formationRule = "strong-material",
            relatedSignalKeys = evidence.sourceSignalKeys.toList(),
            leadingSignalKey = evidence.sourceSignalKeys.first(),
            supportingSignalKeys = emptyList(),
            evidenceUnits = listOf(evidence),
            independentEvidenceCount = 1,
            decisionTrace = PulseTriageDecisionTrace(
                "monthly-budget/2026-10", emptyList(), "strong-material", 1, 1,
                listOf(evidence.evidenceKey), emptyList(), emptyList(), emptyList(), emptyList(), 1,
            ),
            sourceCoreRevision = 1,
            sourceSignalGeneration = 1,
            policyVersion = 1,
            firstObservedAtUtcMs = firstObservedAt,
            lastEvaluatedAtUtcMs = firstObservedAt + 1,
            lastMaterialChangeAtUtcMs = firstObservedAt + 1,
            semanticFingerprint = "monthly-budget",
            historicalInspection = false,
        )
    }
}
