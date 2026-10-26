package com.fluvi.core.pulse

/**
 * Builds countable evidence units conservatively.  A different indicator or
 * chart family is never, by itself, proof of independent information.
 */
object PulseEvidenceIndependenceEvaluator {
    data class Input(
        val signal: PulseRawSignal,
        val descriptor: PulseSituationDescriptor,
    )

    data class Result(
        val units: List<PulseEvidenceUnit>,
        val exclusions: List<PulseEvidenceExclusion>,
    )

    fun evaluate(inputs: List<Input>): Result {
        val seenSignals = linkedSetOf<String>()
        val acceptedRoots = linkedSetOf<String>()
        val units = mutableListOf<PulseEvidenceUnit>()
        val exclusions = mutableListOf<PulseEvidenceExclusion>()
        inputs.sortedWith(compareBy<Input> { it.signal.indicatorId.stableId }.thenBy { it.signal.signalKey })
            .forEach { input ->
                val signal = input.signal
                val evidence = signal.evidence
                val provenance = evidence.provenance
                val unitKey = provenance?.evidenceKey
                    ?: "unresolved/${signal.signalKey}"
                val reasons = mutableListOf<String>()
                var independence = PulseEvidenceIndependence.unresolved
                var role = PulseEvidenceRole.excluded
                val signalDuplicate = !seenSignals.add(signal.signalKey)
                val evaluable = signal.dataQuality == PulseSignalDataQuality.sufficient ||
                    signal.dataQuality == PulseSignalDataQuality.limited
                val active = signal.activityState == PulseSignalActivityState.active
                val sourceRoots = provenance?.sourceFactKeys.orEmpty()
                when {
                    signalDuplicate -> {
                        reasons += "duplicate-signal"
                        role = PulseEvidenceRole.excluded
                    }
                    !evaluable -> {
                        reasons += "data-quality-${signal.dataQuality.name}"
                        role = PulseEvidenceRole.excluded
                    }
                    !active -> {
                        reasons += "signal-not-active"
                        role = if (signal.activityState == PulseSignalActivityState.pendingConfirmation) {
                            PulseEvidenceRole.contextOnly
                        } else {
                            PulseEvidenceRole.excluded
                        }
                    }
                    provenance == null || sourceRoots.isEmpty() ||
                        provenance.sourceKind == PulseEvidenceSourceKind.unresolved -> {
                        reasons += "provenance-unresolved"
                        independence = PulseEvidenceIndependence.unresolved
                        role = PulseEvidenceRole.contextOnly
                    }
                    input.descriptor.role == PulseSituationSignalRole.derived ||
                        provenance.upstreamEvidenceKeys.isNotEmpty() -> {
                        reasons += "directly-derived"
                        independence = PulseEvidenceIndependence.derived
                        role = PulseEvidenceRole.derivedSupport
                    }
                    sourceRoots.any { it in acceptedRoots } -> {
                        reasons += "shared-source-facts"
                        independence = PulseEvidenceIndependence.overlapping
                        role = PulseEvidenceRole.overlappingSupport
                    }
                    else -> {
                        independence = PulseEvidenceIndependence.independent
                        role = when (input.descriptor.role) {
                            PulseSituationSignalRole.leadingEligible -> PulseEvidenceRole.leading
                            PulseSituationSignalRole.supporting -> PulseEvidenceRole.independentSupport
                            PulseSituationSignalRole.derived -> PulseEvidenceRole.derivedSupport
                            PulseSituationSignalRole.contextOnly -> PulseEvidenceRole.contextOnly
                        }
                        acceptedRoots += sourceRoots
                        reasons += "independent-source-facts"
                    }
                }
                val countable = independence == PulseEvidenceIndependence.independent &&
                    role in setOf(PulseEvidenceRole.leading, PulseEvidenceRole.independentSupport) && active
                val standaloneEligible = active && evaluable &&
                    input.descriptor.role == PulseSituationSignalRole.leadingEligible &&
                    independence != PulseEvidenceIndependence.unresolved
                val unit = PulseEvidenceUnit(
                    evidenceKey = unitKey,
                    situationKey = input.descriptor.situationKey,
                    sourceSignalKeys = setOf(signal.signalKey),
                    sourceFactKeys = sourceRoots,
                    evidenceFamily = evidence.evidenceFamily,
                    strength = signal.strength,
                    role = role,
                    independence = independence,
                    countableForFormation = countable,
                    standaloneEligible = standaloneEligible,
                    reasonCodes = reasons,
                    indicatorId = signal.indicatorId.stableId,
                    titleHu = signal.indicatorId.titleHu,
                    measuredValue = signal.measuredValue,
                    dataQuality = signal.dataQuality,
                    actualImpactMinor = evidence.actualImpactMinor,
                    projectedImpactMinor = evidence.projectedImpactMinor,
                )
                units += unit
                if (!countable) {
                    exclusions += PulseEvidenceExclusion(
                        evidenceKey = unit.evidenceKey,
                        signalKey = signal.signalKey,
                        reasonCode = reasons.firstOrNull() ?: "not-countable",
                        explanationHu = exclusionExplanation(reasons.firstOrNull()),
                    )
                }
            }
        return Result(units, exclusions)
    }

    private fun exclusionExplanation(reason: String?): String = when (reason) {
        "directly-derived" -> "A jel egy másik bemeneti számításból származik, ezért nem külön bizonyíték."
        "shared-source-facts" -> "A jel már figyelembe vett forrásadatokra támaszkodik."
        "provenance-unresolved" -> "A jel független forrása nem igazolható."
        "signal-not-active" -> "A nyers jel még nem aktív vagy már feloldódó állapotban van."
        else -> "A jel jelenleg nem számítható be önálló bizonyítékként."
    }
}
