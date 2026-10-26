package com.fluvi.core.pulse

/** Domains are stable machine identities, not labels or navigation tabs. */
enum class PulseSituationDomain(val titleHu: String, val operational: Boolean = false) {
    monthlyBudget("Havi kerethelyzet"),
    categoryBudget("Kategóriakeret helyzet"),
    spendingBehavior("Költési viselkedés"),
    monthlyCashflow("Havi pénzáramlás"),
    liquidity("Likviditási helyzet"),
    expectedIncome("Várt bevétel"),
    recurringBurden("Ismétlődő terhek"),
    subscriptionLoad("Előfizetés-terhelés"),
    upcomingObligation("Közelgő kötelezettség"),
    categorizationQuality("Kategorizálási minőség", operational = true),
    parserReview("Push felismerési felülvizsgálat", operational = true),
    processingHealth("Feldolgozási állapot", operational = true),
}

enum class PulseSituationSignalRole {
    leadingEligible,
    supporting,
    derived,
    contextOnly,
}

enum class PulseEvidenceRole {
    leading,
    independentSupport,
    derivedSupport,
    overlappingSupport,
    contextOnly,
    excluded,
}

enum class PulseEvidenceIndependence {
    independent,
    derived,
    overlapping,
    unresolved,
}

enum class PulseSituationState {
    forming,
    ready,
    improving,
    resolved,
    suspended,
}

enum class PulseSituationEventKind {
    formed,
    ready,
    strengthened,
    weakened,
    improving,
    resolved,
    suspended,
    reopened,
    configurationChanged,
}

data class PulseSituationDescriptor(
    val situationKey: String,
    val domain: PulseSituationDomain,
    val targetKey: String,
    val periodKey: String,
    val role: PulseSituationSignalRole,
)

data class PulseEvidenceUnit(
    val evidenceKey: String,
    val situationKey: String,
    val sourceSignalKeys: Set<String>,
    val sourceFactKeys: Set<String>,
    val evidenceFamily: String,
    val strength: PulseSignalStrength?,
    val role: PulseEvidenceRole,
    val independence: PulseEvidenceIndependence,
    val countableForFormation: Boolean,
    /** Eligible for a single-signal gate; distinct from pair/triple independence. */
    val standaloneEligible: Boolean,
    val reasonCodes: List<String>,
    val indicatorId: String,
    val titleHu: String,
    val measuredValue: Double?,
    val dataQuality: PulseSignalDataQuality,
    val actualImpactMinor: Long?,
    val projectedImpactMinor: Long?,
)

data class PulseEvidenceExclusion(
    val evidenceKey: String,
    val signalKey: String,
    val reasonCode: String,
    val explanationHu: String,
)

data class PulseTriageRuleResult(
    val ruleId: String,
    val applicable: Boolean,
    val passed: Boolean,
    val requiredEvidenceCount: Int,
    val actualEvidenceCount: Int,
    val requiredStrength: PulseSignalStrength? = null,
    val dataQualityPassed: Boolean,
    val materialImpactPassed: Boolean?,
    val reasonCodes: List<String>,
)

data class PulseTriageDecisionTrace(
    val situationKey: String,
    val evaluatedRules: List<PulseTriageRuleResult>,
    val matchedRule: String?,
    val relatedSignalCount: Int,
    val independentEvidenceCount: Int,
    val countedEvidenceKeys: List<String>,
    val supportingEvidenceKeys: List<String>,
    val excludedEvidence: List<PulseEvidenceExclusion>,
    val missingRequirements: List<String>,
    val explanationHu: List<String>,
    val policyVersion: Int,
)

data class PulseSituationSnapshot(
    val situationKey: String,
    val domain: PulseSituationDomain,
    val targetKey: String,
    val periodKey: String,
    val state: PulseSituationState,
    val formationRule: String?,
    val relatedSignalKeys: List<String>,
    val leadingSignalKey: String?,
    val supportingSignalKeys: List<String>,
    val evidenceUnits: List<PulseEvidenceUnit>,
    val independentEvidenceCount: Int,
    val decisionTrace: PulseTriageDecisionTrace,
    val sourceCoreRevision: Long,
    val sourceSignalGeneration: Long,
    val policyVersion: Int,
    val firstObservedAtUtcMs: Long?,
    val lastEvaluatedAtUtcMs: Long,
    val lastMaterialChangeAtUtcMs: Long?,
    val semanticFingerprint: String,
    val historicalInspection: Boolean,
)

data class PulseSituationEvent(
    val eventId: String,
    val situationKey: String,
    val kind: PulseSituationEventKind,
    val previousState: PulseSituationState?,
    val nextState: PulseSituationState,
    val previousFormationRule: String?,
    val nextFormationRule: String?,
    val previousEvidenceCount: Int,
    val nextEvidenceCount: Int,
    val causeCode: String,
    val explanationHu: List<String>,
    val sourceCoreRevision: Long,
    val policyVersion: Int,
    val transitionSequence: Long,
    val createdAtUtcMs: Long,
)

data class PulseSituationInspectionSnapshot(
    val situation: PulseSituationSnapshot,
    val events: List<PulseSituationEvent>,
)

data class PulseTriageDashboardSnapshot(
    val dashboard: PulseDashboardSnapshot,
    val situations: List<PulseSituationSnapshot>,
    val frame: PulseSignalFrame,
)
