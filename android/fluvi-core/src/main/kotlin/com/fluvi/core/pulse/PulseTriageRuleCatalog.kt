package com.fluvi.core.pulse

/** Versioned formation policy.  It classifies a single situation only; it does not rank situations. */
object PulseTriageRuleCatalog {
    const val policyVersion: Int = PulseSituationCatalog.policyVersion
    const val criticalSingle = "critical-single"
    const val strongMaterial = "strong-material"
    const val mediumPair = "medium-pair"
    const val weakTriple = "weak-triple"
    const val verifiedRecovery = "verified-recovery"
    const val dataQualityOperational = "data-quality-operational"

    /** Amounts are scaled by 100. A material amount is domain-aware, never a global hidden magic number. */
    fun materialThresholdMinor(
        domain: PulseSituationDomain,
        unit: PulseEvidenceUnit,
        affectedBudgetMinor: Long?,
    ): Long? = when (domain) {
        PulseSituationDomain.monthlyBudget,
        PulseSituationDomain.categoryBudget,
        -> affectedBudgetMinor?.let { maxOf(1_000_000L, it / 10L) } ?: 1_000_000L
        PulseSituationDomain.expectedIncome,
        PulseSituationDomain.recurringBurden,
        PulseSituationDomain.subscriptionLoad,
        PulseSituationDomain.upcomingObligation,
        -> 3_000_000L
        PulseSituationDomain.monthlyCashflow,
        PulseSituationDomain.liquidity,
        -> 1_000_000L
        else -> null
    }
}

object PulseTriageEvaluator {
    fun evaluate(
        descriptor: PulseSituationDescriptor,
        signals: List<PulseRawSignal>,
        units: List<PulseEvidenceUnit>,
        exclusions: List<PulseEvidenceExclusion>,
        previousState: PulseSituationState? = null,
        configurationOnlyChange: Boolean = false,
    ): PulseTriageDecisionTrace {
        val countable = units.filter { it.countableForFormation }
        val adequate = countable.filter {
            it.dataQuality == PulseSignalDataQuality.sufficient || it.dataQuality == PulseSignalDataQuality.limited
        }
        // A leading Forecast may be derived from its inputs yet still be a
        // single, materially meaningful finding.  It cannot increase pair or
        // triple independence, which remains restricted to `adequate` units.
        val singleEligible = units.filter {
            it.standaloneEligible &&
                (it.dataQuality == PulseSignalDataQuality.sufficient ||
                    it.dataQuality == PulseSignalDataQuality.limited)
        }
        val operational = descriptor.domain.operational
        val critical = singleEligible.filter { it.strength == PulseSignalStrength.critical }
        val strong = singleEligible.filter { (it.strength?.ordinal ?: -1) >= PulseSignalStrength.strong.ordinal }
        val medium = adequate.filter { (it.strength?.ordinal ?: -1) >= PulseSignalStrength.medium.ordinal }
        val weak = adequate.filter { (it.strength?.ordinal ?: -1) >= PulseSignalStrength.weak.ordinal }
        val material = strong.filter { unit ->
            val amount = maxOf(unit.actualImpactMinor ?: 0L, unit.projectedImpactMinor ?: 0L)
            val threshold = PulseTriageRuleCatalog.materialThresholdMinor(
                descriptor.domain,
                unit,
                signals.firstOrNull { it.signalKey in unit.sourceSignalKeys }?.evidence?.affectedBudgetMinor,
            )
            threshold != null && amount >= threshold
        }
        // An unrelated, unavailable supporting metric cannot invalidate a
        // sufficient, countable leading fact.  Quality is evaluated for the
        // evidence used by each gate, not as a blanket domain-wide penalty.
        val independentQuality = adequate.isNotEmpty()
        val singleQuality = singleEligible.isNotEmpty()
        val regularRules = listOf(
            rule(
                PulseTriageRuleCatalog.criticalSingle,
                applicable = !operational,
                passed = critical.isNotEmpty() && singleQuality,
                required = 1,
                actual = critical.size,
                strength = PulseSignalStrength.critical,
                quality = singleQuality,
                material = null,
                reasons = if (critical.isEmpty()) listOf("no-critical-leading-evidence") else emptyList(),
            ),
            rule(
                PulseTriageRuleCatalog.strongMaterial,
                applicable = !operational,
                passed = material.isNotEmpty() && singleQuality,
                required = 1,
                actual = material.size,
                strength = PulseSignalStrength.strong,
                quality = singleQuality,
                material = material.isNotEmpty(),
                reasons = if (material.isEmpty()) listOf("material-impact-not-reached") else emptyList(),
            ),
            rule(
                PulseTriageRuleCatalog.mediumPair,
                applicable = !operational,
                passed = medium.size >= 2 && independentQuality,
                required = 2,
                actual = medium.size,
                strength = PulseSignalStrength.medium,
                quality = independentQuality,
                material = null,
                reasons = if (medium.size < 2) listOf("independent-medium-evidence-missing") else emptyList(),
            ),
            rule(
                PulseTriageRuleCatalog.weakTriple,
                applicable = !operational,
                passed = weak.size >= 3 && independentQuality,
                required = 3,
                actual = weak.size,
                strength = PulseSignalStrength.weak,
                quality = independentQuality,
                material = null,
                reasons = if (weak.size < 3) listOf("independent-weak-evidence-missing") else emptyList(),
            ),
            rule(
                PulseTriageRuleCatalog.verifiedRecovery,
                applicable = !configurationOnlyChange && previousState == PulseSituationState.ready && countable.isEmpty() && signals.any { it.dataQuality == PulseSignalDataQuality.sufficient },
                passed = !configurationOnlyChange && previousState == PulseSituationState.ready && countable.isEmpty() && signals.any { it.dataQuality == PulseSignalDataQuality.sufficient },
                required = 0,
                actual = countable.size,
                strength = null,
                quality = signals.any { it.dataQuality == PulseSignalDataQuality.sufficient },
                material = null,
                reasons = if (configurationOnlyChange) listOf("configuration-change-is-not-recovery") else emptyList(),
            ),
            rule(
                PulseTriageRuleCatalog.dataQualityOperational,
                applicable = operational,
                passed = operational && adequate.any { it.role == PulseEvidenceRole.leading && (it.strength?.ordinal ?: -1) >= PulseSignalStrength.medium.ordinal },
                required = 1,
                actual = adequate.count { it.role == PulseEvidenceRole.leading && (it.strength?.ordinal ?: -1) >= PulseSignalStrength.medium.ordinal },
                strength = PulseSignalStrength.medium,
                quality = independentQuality,
                material = null,
                reasons = if (operational && adequate.none { it.role == PulseEvidenceRole.leading && (it.strength?.ordinal ?: -1) >= PulseSignalStrength.medium.ordinal }) listOf("operational-leading-evidence-missing") else emptyList(),
            ),
        )
        val selectionOrder = listOf(
            PulseTriageRuleCatalog.criticalSingle,
            PulseTriageRuleCatalog.strongMaterial,
            PulseTriageRuleCatalog.mediumPair,
            PulseTriageRuleCatalog.weakTriple,
            PulseTriageRuleCatalog.dataQualityOperational,
            PulseTriageRuleCatalog.verifiedRecovery,
        )
        val matched = selectionOrder.firstOrNull { id -> regularRules.first { it.ruleId == id }.passed }
        val missing = regularRules.filter { it.applicable && !it.passed }
            .flatMap { it.reasonCodes }.distinct()
        val explanations = buildList {
            if (matched != null) add("A ${matched} helyzetképzési szabály teljesült.")
            else add("A helyzethez tartozó bizonyítékok még nem teljesítik egyik helyzetképzési kaput sem.")
            exclusions.take(3).forEach { add(it.explanationHu) }
        }
        return PulseTriageDecisionTrace(
            situationKey = descriptor.situationKey,
            evaluatedRules = regularRules,
            matchedRule = matched,
            relatedSignalCount = signals.size,
            independentEvidenceCount = countable.size,
            countedEvidenceKeys = countable.map(PulseEvidenceUnit::evidenceKey),
            supportingEvidenceKeys = units.filterNot { it.countableForFormation }.map(PulseEvidenceUnit::evidenceKey),
            excludedEvidence = exclusions,
            missingRequirements = missing,
            explanationHu = explanations,
            policyVersion = PulseTriageRuleCatalog.policyVersion,
        )
    }

    private fun rule(
        id: String,
        applicable: Boolean,
        passed: Boolean,
        required: Int,
        actual: Int,
        strength: PulseSignalStrength?,
        quality: Boolean,
        material: Boolean?,
        reasons: List<String>,
    ) = PulseTriageRuleResult(
        ruleId = id,
        applicable = applicable,
        passed = applicable && passed,
        requiredEvidenceCount = required,
        actualEvidenceCount = actual,
        requiredStrength = strength,
        dataQualityPassed = quality,
        materialImpactPassed = material,
        reasonCodes = reasons,
    )
}
