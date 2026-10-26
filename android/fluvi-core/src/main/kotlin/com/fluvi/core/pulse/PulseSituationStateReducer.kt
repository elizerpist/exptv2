package com.fluvi.core.pulse

/** Pure lifecycle reducer; persistence is deliberately handled by the service. */
object PulseSituationStateReducer {
    data class Input(
        val previous: PulseSituationState?,
        val hasEvaluableInputs: Boolean,
        val hasFormationEvidence: Boolean,
        val matchedRule: String?,
        val configurationOnlyChange: Boolean,
    )

    fun reduce(input: Input): PulseSituationState {
        val regularMatch = input.matchedRule?.takeUnless {
            it == PulseTriageRuleCatalog.verifiedRecovery
        }
        return when {
            !input.hasEvaluableInputs -> PulseSituationState.suspended
            // A user moving a threshold is a policy change, not proof of a
            // financial recovery.  It may still change the visible state,
            // but the persistence layer records a configuration event.
            input.configurationOnlyChange && regularMatch == null -> when (input.previous) {
                PulseSituationState.ready,
                PulseSituationState.improving,
                PulseSituationState.forming,
                -> PulseSituationState.resolved
                else -> if (input.hasFormationEvidence) PulseSituationState.forming else PulseSituationState.resolved
            }
            regularMatch != null -> PulseSituationState.ready
            input.matchedRule == PulseTriageRuleCatalog.verifiedRecovery -> PulseSituationState.improving
            input.previous == PulseSituationState.ready && input.hasFormationEvidence && !input.configurationOnlyChange ->
                PulseSituationState.improving
            input.previous == PulseSituationState.improving && !input.hasFormationEvidence && !input.configurationOnlyChange ->
                PulseSituationState.resolved
            input.previous == PulseSituationState.ready && !input.hasFormationEvidence && !input.configurationOnlyChange ->
                PulseSituationState.improving
            input.hasFormationEvidence -> PulseSituationState.forming
            input.previous == PulseSituationState.suspended -> PulseSituationState.forming
            else -> PulseSituationState.resolved
        }
    }
}
