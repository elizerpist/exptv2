package com.fluvi.core.pulse

/** C-phase is a ranking decision only. It has no delivery or notification semantics. */
enum class PulsePriorityCandidateKind { ready, recovery }

enum class PulsePriorityEventKind { initialSelection, selectionChanged, selectionCleared, selectionRestored }

data class PulsePriorityModifier(
    val id: String,
    val value: Int,
    val applied: Boolean,
    val reasonCode: String,
    val explanationHu: String,
    val observedImpactMinor: Long? = null,
)

data class PulsePriorityTieBreakFacts(
    val dueLocalEpochDay: Long?,
    val dueDistanceDays: Long?,
    val severityRank: Int,
    val comparableImpactMinor: Long?,
    val lastMaterialChangeAtUtcMs: Long?,
)

data class PulsePriorityCandidate(
    val situation: PulseSituationSnapshot,
    val kind: PulsePriorityCandidateKind,
    val leadingEvidenceKey: String,
    val leadingSignalKey: String,
    val leadingIndicatorId: String,
    val basePriority: Int,
    val modifiers: List<PulsePriorityModifier>,
    val rawTotal: Int,
    val finalScore: Int,
    val tieBreakFacts: PulsePriorityTieBreakFacts,
    val sourceSituationVersion: String,
    val policyVersion: Int,
    val rank: Int = 0,
)

data class PulsePrioritySelectionReason(
    val reasonCode: String,
    val explanationHu: String,
    val tieBreakApplied: Boolean,
    val tieBreakExplanationHu: String? = null,
)

data class PulsePriorityFrame(
    val sourceCoreRevision: Long,
    val sourceTriageFrameId: String,
    val policyVersion: Int,
    val evaluationMode: PulseSignalEvaluationMode,
    val evaluatedAtUtcMs: Long,
    val rankedCandidates: List<PulsePriorityCandidate>,
    val selectedSituationKey: String?,
    val selectionReason: PulsePrioritySelectionReason?,
)

data class PulsePriorityEvent(
    val eventId: String,
    val kind: PulsePriorityEventKind,
    val previousSelectedSituationKey: String?,
    val nextSelectedSituationKey: String?,
    val previousScore: Int?,
    val nextScore: Int?,
    val selectionReason: String,
    val sourceCoreRevision: Long,
    val sourceTriageFrameId: String,
    val policyVersion: Int,
    val transitionSequence: Long,
    val createdAtUtcMs: Long,
)

data class PulsePriorityInspectionSnapshot(
    val frame: PulsePriorityFrame,
    val situations: List<PulseSituationSnapshot>,
    val events: List<PulsePriorityEvent>,
)

data class PulsePriorityDashboardSnapshot(
    val triage: PulseTriageDashboardSnapshot,
    val priority: PulsePriorityFrame,
)
