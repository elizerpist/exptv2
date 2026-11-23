package com.fluvi.r29.contract

/** Booleans are authoritative only after every source has supplied an observation. */
data class R29FrameInputs(
    val inputsKnown: Boolean,
    val ordinaryLockscreen: Boolean,
    val primaryUser: Boolean,
    val defaultDisplay: Boolean,
    val defaultBlueprint: Boolean,
    val geometryValid: Boolean,
    val policyAllowsFull: Boolean,
    val currentReadyRevision: Boolean,
    val dozing: Boolean,
    val dreaming: Boolean,
    val occluded: Boolean,
    val goingAway: Boolean,
    val credential: Boolean,
    val shadeOrQs: Boolean,
    val restrictiveTransition: Boolean,
)

object R29FramePolicy {
    fun allow(input: R29FrameInputs): Boolean = input.inputsKnown && input.ordinaryLockscreen &&
        input.primaryUser && input.defaultDisplay && input.defaultBlueprint && input.geometryValid &&
        input.policyAllowsFull && input.currentReadyRevision && !input.dozing && !input.dreaming &&
        !input.occluded && !input.goingAway && !input.credential && !input.shadeOrQs &&
        !input.restrictiveTransition
}
