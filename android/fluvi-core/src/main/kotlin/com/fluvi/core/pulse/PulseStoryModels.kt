package com.fluvi.core.pulse

/**
 * D-phase is an immutable composition layer.  These types deliberately have
 * no delivery, shown, dismiss, or notification state: that belongs to E.
 */
enum class PulseStoryCertainty { observed, scheduled, projected, estimated, unavailable }

enum class PulseStoryFactKind {
    actualBudgetSpent,
    actualBudgetLimit,
    actualBudgetOverrun,
    projectedBudgetSpent,
    projectedBudgetOverrun,
    spendingPaceRatio,
    forecastCrossingDate,
    bookedIncome,
    bookedExpense,
    projectedNetCashflow,
    knownPendingObligation,
    knownDueDate,
    expectedIncomeAmount,
    expectedIncomeDueDate,
    expectedIncomeOverdueDays,
    actualReserveBalance,
    estimatedReserveDays,
    projectedNegativeBalanceDate,
    categoryBudgetAmount,
    categorySpentAmount,
    recurringBurdenAmount,
    subscriptionBurdenAmount,
    uncategorizedCount,
    uncategorizedAmount,
    uncategorizedOldestAge,
    pushReviewCount,
    processingBacklogCount,
    measuredRatio,
    measuredCount,
}

enum class PulseStoryClaimType {
    actualBreach,
    projectedBreach,
    highSpendingPace,
    unusualSpending,
    negativeCashflow,
    insufficientCoverage,
    overdueExpectedIncome,
    upcomingObligation,
    recurringBurden,
    dataQualityIssue,
    processingIssue,
    verifiedRecovery,
}

enum class PulseStoryFragmentRole { headline, evidence, timeCause, qualification, recovery }

enum class PulseStoryCompositionStatus {
    composed,
    insufficientFacts,
    unsupportedSituation,
    staleSnapshot,
    validationFailed,
}

/** Values retain their native money/date/count representation; no money is a Double. */
data class PulseStoryFact(
    val factKey: String,
    val kind: PulseStoryFactKind,
    val sourceSignalKeys: Set<String>,
    val sourceEvidenceKeys: Set<String>,
    val sourceFactKeys: Set<String>,
    val certainty: PulseStoryCertainty,
    val amountMinor: Long? = null,
    val decimalValue: Double? = null,
    val countValue: Int? = null,
    val dueLocalEpochDay: Long? = null,
    val periodKey: String? = null,
    val occurredAtUtcMs: Long? = null,
    val sourceCoreRevision: Long,
    /** True only when this fact is already a component of a forecast fact. */
    val includedInForecast: Boolean = false,
)

data class PulseStoryFactBundle(
    val situationKey: String,
    val sourceCoreRevision: Long,
    val facts: List<PulseStoryFact>,
    val missingFactKinds: Set<PulseStoryFactKind> = emptySet(),
)

data class PulseStoryContext(
    val priorityFrameId: String,
    val situation: PulseSituationSnapshot,
    val candidate: PulsePriorityCandidate,
    val facts: PulseStoryFactBundle,
    val evaluationMode: PulseSignalEvaluationMode,
    val generatedAtUtcMs: Long,
    /** Canonical application zone used for date-only Story facts and copy. */
    val localZoneId: String = "Europe/Budapest",
)

data class PulseStoryTemplateDefinition(
    val templateId: String,
    val version: Int,
    val domain: PulseSituationDomain,
    val claimType: PulseStoryClaimType,
    val requiredFactKinds: Set<PulseStoryFactKind>,
    val optionalFactKinds: Set<PulseStoryFactKind> = emptySet(),
    val allowedCertainties: Set<PulseStoryCertainty>,
    val maximumEvidenceFragments: Int = 2,
)

data class PulseStoryFragment(
    val role: PulseStoryFragmentRole,
    val templateId: String,
    val renderedText: String,
    val sourceSignalKeys: List<String>,
    val sourceEvidenceKeys: List<String>,
    val sourceFactKeys: List<String>,
    val certainty: PulseStoryCertainty,
)

data class PulseStoryExclusion(
    val factKey: String,
    val sourceSignalKey: String?,
    val sourceEvidenceKey: String?,
    val reasonCode: String,
    val explanationHu: String,
)

data class PulseStoryDraft(
    val storyKey: String,
    val situationKey: String,
    val candidateKind: PulsePriorityCandidateKind,
    val claimType: PulseStoryClaimType,
    val headline: String,
    val detail: String?,
    val fragments: List<PulseStoryFragment>,
    val exclusions: List<PulseStoryExclusion>,
    val priorityFrameId: String,
    val sourceCoreRevision: Long,
    val templateVersion: Int,
    val contentFingerprint: String,
    val materialFingerprint: String,
    val evaluationMode: PulseSignalEvaluationMode,
    val generatedAtUtcMs: Long,
)

data class PulseStoryCompositionResult(
    val status: PulseStoryCompositionStatus,
    val draft: PulseStoryDraft? = null,
    val reasonCode: String? = null,
    val explanationHu: String? = null,
)

data class PulseStoryInspectionSnapshot(
    val result: PulseStoryCompositionResult,
    val facts: PulseStoryFactBundle?,
    val priorityFrameId: String,
    val sourceCoreRevision: Long,
)
