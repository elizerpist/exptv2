package com.fluvi.core.pulse

/**
 * Signal models are deliberately separate from financial measurements. A signal
 * is a deterministic interpretation of a Pulse indicator; it does not create a
 * user message, notification, priority, or financial write.
 */
enum class PulseSignalComparisonOperator {
    greaterThan,
    greaterThanOrEqual,
    lessThan,
    lessThanOrEqual,
    outsideRange,
    dueWithin,
    overdueBy,
    deviationAbove,
}

enum class PulseSignalDataQuality {
    sufficient,
    limited,
    insufficient,
    notApplicable,
}

enum class PulseSignalActivityState {
    normal,
    pendingConfirmation,
    active,
    recovering,
    resolved,
    evaluationSuspended,
}

enum class PulseSignalStrength {
    weak,
    medium,
    strong,
    critical,
}

enum class PulseSignalEventKind {
    activated,
    strengthened,
    weakened,
    resolved,
    reactivated,
    evaluationSuspended,
    evaluationRestored,
    configurationChanged,
}

enum class PulseSignalEvaluationMode {
    live,
    historicalInspection,
}

data class PulseSignalRuleDefinition(
    val indicatorId: PulseIndicatorId,
    val metricKey: String,
    val comparisonOperator: PulseSignalComparisonOperator,
    val evidenceFamily: String,
    val dependencyIds: List<String>,
    val maximumStandaloneStrength: PulseSignalStrength,
    val confirmationsRequired: Int = 1,
    val requiresPositiveThreshold: Boolean = false,
    val resolutionHysteresisRatio: Double = .05,
    val targetStrategy: PulseSignalTargetStrategy = PulseSignalTargetStrategy.global,
)

enum class PulseSignalTargetStrategy {
    global,
    category,
    partner,
    occurrence,
}

data class PulseSignalEvidence(
    val situationKey: String,
    val evidenceFamily: String,
    val dependencyIds: List<String>,
    val affectedTarget: String,
    val actualImpactMinor: Long? = null,
    val projectedImpactMinor: Long? = null,
    val affectedBudgetMinor: Long? = null,
    val affectedObligationMinor: Long? = null,
    val impactRatio: Double? = null,
)

data class PulseSignalEvaluationTrace(
    val measuredMetricKey: String,
    val measuredValue: Double?,
    val thresholdValue: Double?,
    val comparisonOperator: PulseSignalComparisonOperator,
    val thresholdConditionMet: Boolean,
    val confirmationRequired: Int,
    val confirmationCount: Int,
    val missingInputsHu: List<String>,
    val explanationHu: List<String>,
)

data class PulseRawSignal(
    val signalKey: String,
    val indicatorId: PulseIndicatorId,
    val targetKey: String,
    val periodKey: String,
    val scenarioKey: String,
    val measuredValue: Double?,
    val evaluatedMetricKey: String,
    val thresholdValue: Double?,
    val comparisonOperator: PulseSignalComparisonOperator,
    val availability: PulseAvailability,
    val activityState: PulseSignalActivityState,
    val strength: PulseSignalStrength?,
    val dataQuality: PulseSignalDataQuality,
    val evidence: PulseSignalEvidence,
    val observedDuration: Int,
    val trendDirection: String,
    val firstObservedAtUtcMs: Long?,
    val lastEvaluatedAtUtcMs: Long,
    val lastMaterialChangeAtUtcMs: Long?,
    val sourceCoreRevision: Long,
    val configRevision: Long,
    val evaluationFingerprint: String,
    val trace: PulseSignalEvaluationTrace,
)

data class PulseSignalState(
    val signalKey: String,
    val activityState: PulseSignalActivityState,
    val strength: PulseSignalStrength?,
    val previousStrength: PulseSignalStrength?,
    val dataQuality: PulseSignalDataQuality,
    val confirmationCount: Int,
    val firstObservedAtUtcMs: Long?,
    val lastEvaluatedAtUtcMs: Long,
    val lastMaterialChangeAtUtcMs: Long?,
    val lastInputRevision: Long,
    val lastConfigRevision: Long,
    val evaluationFingerprint: String,
)

data class PulseSignalEvent(
    val eventId: String,
    val signalKey: String,
    val kind: PulseSignalEventKind,
    val previousState: PulseSignalActivityState?,
    val nextState: PulseSignalActivityState,
    val previousStrength: PulseSignalStrength?,
    val nextStrength: PulseSignalStrength?,
    val measuredValue: Double?,
    val thresholdValue: Double?,
    val timestampUtcMs: Long,
    val inputRevision: Long,
    val configRevision: Long,
    val cause: String,
    val evaluationFingerprint: String,
)

data class PulseSignalSummary(
    val activityState: PulseSignalActivityState,
    val strength: PulseSignalStrength?,
    val dataQuality: PulseSignalDataQuality,
    val activeSignalCount: Int,
    val totalSignalCount: Int,
)

data class PulseSignalInspectionSnapshot(
    val signal: PulseRawSignal,
    val events: List<PulseSignalEvent>,
    val lastPersistedState: PulseSignalState?,
)
