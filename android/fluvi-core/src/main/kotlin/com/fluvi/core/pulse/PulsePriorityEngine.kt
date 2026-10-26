package com.fluvi.core.pulse

import kotlin.math.abs

/** Resolves C-phase candidates strictly from B-phase situation snapshots. */
object PulsePriorityCandidateResolver {
    fun resolve(
        situations: List<PulseSituationSnapshot>,
        recoverySituationKeys: Set<String>,
    ): List<Resolved> = situations.asSequence()
        .mapNotNull { situation ->
            val kind = when {
                situation.state == PulseSituationState.ready -> PulsePriorityCandidateKind.ready
                situation.state == PulseSituationState.improving && situation.situationKey in recoverySituationKeys -> PulsePriorityCandidateKind.recovery
                else -> return@mapNotNull null
            }
            val leading = situation.evidenceUnits.firstOrNull {
                it.role == PulseEvidenceRole.leading &&
                    (situation.leadingSignalKey == null || situation.leadingSignalKey in it.sourceSignalKeys)
            } ?: situation.evidenceUnits.firstOrNull { it.role == PulseEvidenceRole.leading }
                ?: return@mapNotNull null
            val base = PulsePriorityPolicyCatalog.base(leading.indicatorId, leading.strength)
                ?: return@mapNotNull null
            if (kind == PulsePriorityCandidateKind.recovery && !PulsePriorityPolicyCatalog.recoveryEligibleBase(base)) {
                return@mapNotNull null
            }
            Resolved(situation, kind, leading, base)
        }
        .sortedBy { it.situation.situationKey }
        .toList()

    data class Resolved(
        val situation: PulseSituationSnapshot,
        val kind: PulsePriorityCandidateKind,
        val leading: PulseEvidenceUnit,
        val base: Int,
    )
}

object PulsePriorityMaterialImpactEvaluator {
    fun evaluate(candidate: PulsePriorityCandidateResolver.Resolved): PulsePriorityModifier {
        val unit = candidate.leading
        val threshold = PulsePriorityPolicyCatalog.materialThreshold(unit.indicatorId, unit.affectedBudgetMinor)
            ?: return PulsePriorityModifier(
                id = "material-impact", value = 0, applied = false,
                reasonCode = "material-impact-not-applicable",
                explanationHu = "Ehhez a helyzettípushoz a policy nem alkalmaz külön pénzügyi hatásbónuszt.",
            )
        val impact = listOfNotNull(unit.actualImpactMinor, unit.projectedImpactMinor).maxOrNull()
            ?: return PulsePriorityModifier(
                id = "material-impact", value = 0, applied = false,
                reasonCode = "material-impact-not-available",
                explanationHu = "A deduplikált pénzügyi hatás nem áll rendelkezésre.",
            )
        val applied = impact >= threshold
        return PulsePriorityModifier(
            id = "material-impact", value = if (applied) PulsePriorityPolicyCatalog.materialModifier else 0,
            applied = applied,
            reasonCode = if (applied) "material-impact-material" else "material-impact-below-threshold",
            explanationHu = if (applied) "A hitelesített pénzügyi hatás eléri a helyzet saját jelentőségi határát."
            else "A hitelesített pénzügyi hatás nem éri el a helyzet saját jelentőségi határát.",
            observedImpactMinor = impact,
        )
    }
}

object PulsePriorityUrgencyEvaluator {
    fun evaluate(
        candidate: PulsePriorityCandidateResolver.Resolved,
        todayEpochDay: Long,
    ): PulsePriorityModifier {
        val due = candidate.leading.dueLocalEpochDay
        if (!PulsePriorityPolicyCatalog.allowsDueSoon(candidate.leading.indicatorId)) {
            return PulsePriorityModifier("due-soon", 0, false, "due-soon-not-applicable", "A helyzet nem igazolt, konkrét esedékességből ered.")
        }
        if (due == null) {
            return PulsePriorityModifier("due-soon", 0, false, "due-soon-not-available", "Nem áll rendelkezésre kanonikus helyi esedékességi dátum.")
        }
        // An overdue expected income remains a concrete, unresolved due event.
        val applied = due <= todayEpochDay + 3L
        return PulsePriorityModifier(
            "due-soon", if (applied) PulsePriorityPolicyCatalog.dueSoonModifier else 0, applied,
            if (applied) "due-soon-confirmed" else "due-soon-outside-window",
            if (applied) "Az igazolt esedékesség három napon belül van vagy már lejárt."
            else "Az igazolt esedékesség még több mint három napra van.",
        )
    }
}

object PulsePriorityEvidenceModifierEvaluator {
    fun evaluate(candidate: PulsePriorityCandidateResolver.Resolved): PulsePriorityModifier {
        if (!PulsePriorityPolicyCatalog.allowsIndependentModifier(candidate.leading.indicatorId)) {
            return PulsePriorityModifier("independent-evidence", 0, false, "independent-evidence-not-applicable", "Operatív adatminőségi helyzethez ez a bónusz nem alkalmazható.")
        }
        val hasIndependentSupport = candidate.situation.evidenceUnits.any { unit ->
            unit.evidenceKey != candidate.leading.evidenceKey &&
                unit.role == PulseEvidenceRole.independentSupport &&
                unit.independence == PulseEvidenceIndependence.independent &&
                unit.countableForFormation &&
                unit.dataQuality == PulseSignalDataQuality.sufficient
        }
        return PulsePriorityModifier(
            "independent-evidence",
            if (hasIndependentSupport) PulsePriorityPolicyCatalog.independentEvidenceModifier else 0,
            hasIndependentSupport,
            if (hasIndependentSupport) "independent-evidence-confirmed" else "independent-evidence-not-confirmed",
            if (hasIndependentSupport) "Legalább egy önálló, releváns alátámasztó bizonyíték igazolt."
            else "Nincs külön beszámítható, független alátámasztó bizonyíték.",
        )
    }
}

object PulsePriorityScorer {
    fun score(
        resolved: PulsePriorityCandidateResolver.Resolved,
        todayEpochDay: Long,
    ): PulsePriorityCandidate {
        val modifiers = listOf(
            PulsePriorityMaterialImpactEvaluator.evaluate(resolved),
            PulsePriorityUrgencyEvaluator.evaluate(resolved, todayEpochDay),
            PulsePriorityEvidenceModifierEvaluator.evaluate(resolved),
        )
        val raw = resolved.base + modifiers.sumOf { it.value }
        val unit = resolved.leading
        return PulsePriorityCandidate(
            situation = resolved.situation,
            kind = resolved.kind,
            leadingEvidenceKey = unit.evidenceKey,
            leadingSignalKey = unit.sourceSignalKeys.sorted().firstOrNull().orEmpty(),
            leadingIndicatorId = unit.indicatorId,
            basePriority = resolved.base,
            modifiers = modifiers,
            rawTotal = raw,
            finalScore = raw.coerceIn(0, 100),
            tieBreakFacts = PulsePriorityTieBreakFacts(
                dueLocalEpochDay = unit.dueLocalEpochDay,
                dueDistanceDays = unit.dueLocalEpochDay?.let { abs(it - todayEpochDay) },
                severityRank = strengthRank(unit.strength),
                comparableImpactMinor = listOfNotNull(unit.actualImpactMinor, unit.projectedImpactMinor).maxOrNull(),
                lastMaterialChangeAtUtcMs = resolved.situation.lastMaterialChangeAtUtcMs,
            ),
            sourceSituationVersion = resolved.situation.semanticFingerprint,
            policyVersion = PulsePriorityPolicyCatalog.policyVersion,
        )
    }

    fun strengthRank(strength: PulseSignalStrength?): Int = when (strength) {
        PulseSignalStrength.critical -> 4
        PulseSignalStrength.strong -> 3
        PulseSignalStrength.medium -> 2
        PulseSignalStrength.weak -> 1
        null -> 0
    }
}

object PulsePriorityTieBreaker {
    /** Highest score first, then real due date, severity, comparable money, change, stable identity. */
    val comparator: Comparator<PulsePriorityCandidate> = Comparator { left, right ->
        compareValues(right.finalScore, left.finalScore)
            .takeIf { it != 0 }
            ?: compareNullableAscending(left.tieBreakFacts.dueDistanceDays, right.tieBreakFacts.dueDistanceDays)
                .takeIf { it != 0 }
            ?: compareValues(right.tieBreakFacts.severityRank, left.tieBreakFacts.severityRank).takeIf { it != 0 }
            ?: compareNullableDescending(left.tieBreakFacts.comparableImpactMinor, right.tieBreakFacts.comparableImpactMinor).takeIf { it != 0 }
            ?: compareNullableDescending(left.tieBreakFacts.lastMaterialChangeAtUtcMs, right.tieBreakFacts.lastMaterialChangeAtUtcMs).takeIf { it != 0 }
            ?: left.situation.situationKey.compareTo(right.situation.situationKey)
    }

    fun explanation(first: PulsePriorityCandidate, second: PulsePriorityCandidate?): PulsePrioritySelectionReason {
        if (second == null) return PulsePrioritySelectionReason(
            "only-eligible-candidate", "Ez az egyetlen jelenleg rangsorolható kész helyzet.", false,
        )
        if (first.finalScore != second.finalScore) return PulsePrioritySelectionReason(
            "higher-priority-score", "A kiválasztott helyzet pontszáma magasabb a következő versenyzőénél.", false,
        )
        val (code, text) = when {
            first.tieBreakFacts.dueDistanceDays != second.tieBreakFacts.dueDistanceDays ->
                "tie-break-due-date" to "Azonos pontszámnál a közelebbi, igazolt pénzügyi esedékesség döntött."
            first.tieBreakFacts.severityRank != second.tieBreakFacts.severityRank ->
                "tie-break-severity" to "Azonos pontszámnál a hitelesített súlyossági zóna döntött."
            first.tieBreakFacts.comparableImpactMinor != second.tieBreakFacts.comparableImpactMinor ->
                "tie-break-impact" to "Azonos pontszámnál a nagyobb, összehasonlítható pénzügyi hatás döntött."
            first.tieBreakFacts.lastMaterialChangeAtUtcMs != second.tieBreakFacts.lastMaterialChangeAtUtcMs ->
                "tie-break-material-change" to "Azonos pontszámnál a frissebb lényeges helyzetváltozás döntött."
            else -> "tie-break-stable-key" to "Azonos döntési tényeknél a stabil helyzetazonosító biztosít determinisztikus sorrendet."
        }
        return PulsePrioritySelectionReason(code, text, true, text)
    }

    private fun compareNullableAscending(left: Long?, right: Long?): Int = when {
        left == null && right == null -> 0
        left == null -> 1
        right == null -> -1
        else -> left.compareTo(right)
    }

    private fun compareNullableDescending(left: Long?, right: Long?): Int = when {
        left == null && right == null -> 0
        left == null -> 1
        right == null -> -1
        else -> right.compareTo(left)
    }
}

object PulsePrioritySelector {
    fun select(
        sourceCoreRevision: Long,
        sourceTriageFrameId: String,
        mode: PulseSignalEvaluationMode,
        evaluatedAtUtcMs: Long,
        candidates: List<PulsePriorityCandidate>,
    ): PulsePriorityFrame {
        val ranked = candidates.sortedWith(PulsePriorityTieBreaker.comparator).mapIndexed { index, candidate -> candidate.copy(rank = index + 1) }
        val selected = ranked.firstOrNull()
        return PulsePriorityFrame(
            sourceCoreRevision = sourceCoreRevision,
            sourceTriageFrameId = sourceTriageFrameId,
            policyVersion = PulsePriorityPolicyCatalog.policyVersion,
            evaluationMode = mode,
            evaluatedAtUtcMs = evaluatedAtUtcMs,
            rankedCandidates = ranked,
            selectedSituationKey = selected?.situation?.situationKey,
            selectionReason = selected?.let { PulsePriorityTieBreaker.explanation(it, ranked.getOrNull(1)) },
        )
    }
}

/** Pure persistence decision so retries cannot manufacture selection events. */
object PulsePriorityStateReducer {
    data class Previous(
        val selectedSituationKey: String?,
        val selectionFingerprint: String,
    )

    data class Decision(
        val write: Boolean,
        val eventKind: PulsePriorityEventKind?,
    )

    fun reduce(previous: Previous?, nextSelectionKey: String?, fingerprint: String): Decision {
        if (previous?.selectionFingerprint == fingerprint) return Decision(write = false, eventKind = null)
        val event = when {
            previous == null && nextSelectionKey == null -> null
            previous == null -> PulsePriorityEventKind.initialSelection
            previous.selectedSituationKey != null && nextSelectionKey == null -> PulsePriorityEventKind.selectionCleared
            previous.selectedSituationKey == null -> PulsePriorityEventKind.selectionRestored
            previous.selectedSituationKey != nextSelectionKey -> PulsePriorityEventKind.selectionChanged
            else -> null
        }
        return Decision(write = true, eventKind = event)
    }
}
