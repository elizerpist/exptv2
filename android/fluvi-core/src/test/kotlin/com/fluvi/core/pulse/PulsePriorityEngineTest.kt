package com.fluvi.core.pulse

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class PulsePriorityEngineTest {
    @Test
    fun onlyReadySituationsBecomeCandidates() {
        val ready = situation("monthly-budget/2026-10", PulseSituationState.ready, "PULSE-001")
        val forming = situation("monthly-budget/2026-11", PulseSituationState.forming, "PULSE-001")
        val suspended = situation("monthly-budget/2026-12", PulseSituationState.suspended, "PULSE-001")

        val resolved = PulsePriorityCandidateResolver.resolve(listOf(forming, suspended, ready), emptySet())

        assertEquals(listOf(ready.situationKey), resolved.map { it.situation.situationKey })
    }

    @Test
    fun scoreAppliesEveryBonusAtMostOnceAndClampsFinalValue() {
        val source = situation(
            key = "monthly-budget/2026-10",
            state = PulseSituationState.ready,
            indicatorId = "PULSE-001",
            strength = PulseSignalStrength.critical,
            actualImpact = 1_500_000L,
            affectedBudget = 10_000_000L,
            withIndependentSupport = true,
        )
        val candidate = PulsePriorityCandidateResolver.resolve(listOf(source), emptySet()).single()
        val score = PulsePriorityScorer.score(candidate, todayEpochDay = 20)

        assertEquals(100, score.basePriority)
        assertEquals(15, score.modifiers.single { it.id == "material-impact" }.value)
        assertEquals(10, score.modifiers.single { it.id == "independent-evidence" }.value)
        assertEquals(125, score.rawTotal)
        assertEquals(100, score.finalScore)
        assertEquals(0, score.modifiers.single { it.id == "due-soon" }.value)
    }

    @Test
    fun confirmedOccurrenceDueWithinThreeDaysGetsUrgencyOnce() {
        val source = situation(
            key = "upcoming-obligation/ghost-01",
            state = PulseSituationState.ready,
            indicatorId = "PULSE-017",
            dueDay = 23,
        )
        val candidate = PulsePriorityCandidateResolver.resolve(listOf(source), emptySet()).single()
        val score = PulsePriorityScorer.score(candidate, todayEpochDay = 20)

        assertEquals(10, score.modifiers.single { it.id == "due-soon" }.value)
        assertTrue(score.modifiers.single { it.id == "due-soon" }.applied)
    }

    @Test
    fun deterministicTieBreakerUsesStableSituationKeyLast() {
        val a = situation("categorization-quality/a/2026-10", PulseSituationState.ready, "PULSE-018")
        val b = situation("categorization-quality/b/2026-10", PulseSituationState.ready, "PULSE-018")
        fun frame(items: List<PulseSituationSnapshot>) = PulsePrioritySelector.select(
            sourceCoreRevision = 4,
            sourceTriageFrameId = "frame",
            mode = PulseSignalEvaluationMode.live,
            evaluatedAtUtcMs = 10,
            candidates = PulsePriorityCandidateResolver.resolve(items, emptySet()).map {
                PulsePriorityScorer.score(it, 20)
            },
        )

        assertEquals(a.situationKey, frame(listOf(b, a)).selectedSituationKey)
        assertEquals(a.situationKey, frame(listOf(a, b)).selectedSituationKey)
        assertTrue(frame(listOf(a, b)).selectionReason!!.tieBreakApplied)
    }

    @Test
    fun supportingOnlyIndicatorCannotInventLeadingCandidate() {
        val source = situation("monthly-budget/2026-10", PulseSituationState.ready, "PULSE-003")
        assertTrue(PulsePriorityCandidateResolver.resolve(listOf(source), emptySet()).isEmpty())
    }

    @Test
    fun noCandidateProducesNoSelection() {
        val frame = PulsePrioritySelector.select(1, "empty", PulseSignalEvaluationMode.live, 1, emptyList())
        assertNull(frame.selectedSituationKey)
        assertFalse(frame.rankedCandidates.isNotEmpty())
    }

    @Test
    fun stateReducerIsIdempotentAndAllowsAtoBtoASelectionCycles() {
        val initial = PulsePriorityStateReducer.reduce(null, "A", "frame-a")
        assertEquals(PulsePriorityEventKind.initialSelection, initial.eventKind)
        val retry = PulsePriorityStateReducer.reduce(
            PulsePriorityStateReducer.Previous("A", "frame-a"),
            "A",
            "frame-a",
        )
        assertFalse(retry.write)
        val toB = PulsePriorityStateReducer.reduce(
            PulsePriorityStateReducer.Previous("A", "frame-a"),
            "B",
            "frame-b",
        )
        assertEquals(PulsePriorityEventKind.selectionChanged, toB.eventKind)
        val backToA = PulsePriorityStateReducer.reduce(
            PulsePriorityStateReducer.Previous("B", "frame-b"),
            "A",
            "frame-c",
        )
        assertEquals(PulsePriorityEventKind.selectionChanged, backToA.eventKind)
    }

    private fun situation(
        key: String,
        state: PulseSituationState,
        indicatorId: String,
        strength: PulseSignalStrength = PulseSignalStrength.medium,
        actualImpact: Long? = null,
        affectedBudget: Long? = null,
        dueDay: Long? = null,
        withIndependentSupport: Boolean = false,
    ): PulseSituationSnapshot {
        val leading = PulseEvidenceUnit(
            evidenceKey = "$key/leading",
            situationKey = key,
            sourceSignalKeys = setOf("$indicatorId/global/2026-10/default"),
            sourceFactKeys = setOf("fact/$key"),
            evidenceFamily = "test",
            strength = strength,
            role = PulseEvidenceRole.leading,
            independence = PulseEvidenceIndependence.independent,
            countableForFormation = true,
            standaloneEligible = true,
            reasonCodes = emptyList(),
            indicatorId = indicatorId,
            titleHu = "Teszt",
            measuredValue = 1.0,
            dataQuality = PulseSignalDataQuality.sufficient,
            actualImpactMinor = actualImpact,
            projectedImpactMinor = null,
            affectedBudgetMinor = affectedBudget,
            affectedObligationMinor = null,
            impactRatio = null,
            dueLocalEpochDay = dueDay,
        )
        val support = if (!withIndependentSupport) emptyList() else listOf(
            leading.copy(
                evidenceKey = "$key/support",
                sourceSignalKeys = setOf("PULSE-017/ghost/2026-10/default"),
                sourceFactKeys = setOf("occurrence/ghost"),
                role = PulseEvidenceRole.independentSupport,
                indicatorId = "PULSE-017",
            ),
        )
        return PulseSituationSnapshot(
            situationKey = key,
            domain = PulseSituationDomain.monthlyBudget,
            targetKey = "target",
            periodKey = "2026-10",
            state = state,
            formationRule = "medium-pair",
            relatedSignalKeys = listOf("$indicatorId/global/2026-10/default"),
            leadingSignalKey = "$indicatorId/global/2026-10/default",
            supportingSignalKeys = support.flatMap { it.sourceSignalKeys },
            evidenceUnits = listOf(leading) + support,
            independentEvidenceCount = 1 + support.size,
            decisionTrace = PulseTriageDecisionTrace(
                situationKey = key,
                evaluatedRules = emptyList(),
                matchedRule = "medium-pair",
                relatedSignalCount = 1 + support.size,
                independentEvidenceCount = 1 + support.size,
                countedEvidenceKeys = emptyList(),
                supportingEvidenceKeys = emptyList(),
                excludedEvidence = emptyList(),
                missingRequirements = emptyList(),
                explanationHu = emptyList(),
                policyVersion = 1,
            ),
            sourceCoreRevision = 1,
            sourceSignalGeneration = 1,
            policyVersion = 1,
            firstObservedAtUtcMs = 1,
            lastEvaluatedAtUtcMs = 2,
            lastMaterialChangeAtUtcMs = 2,
            semanticFingerprint = key,
            historicalInspection = false,
        )
    }
}
