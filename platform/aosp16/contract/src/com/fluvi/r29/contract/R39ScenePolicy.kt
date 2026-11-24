package com.fluvi.r29.contract

/** Inputs come from the persistent SystemUI scene owner, not the app. */
data class R39SceneFacts(
    val idleLockscreen: Boolean,
    val wakingFromOff: Boolean,
    val fromAbsent: Boolean,
    val toLockscreen: Boolean,
    val noOverlays: Boolean,
    val userDriven: Boolean,
)

object R39ScenePolicy {
    /** Other transitions, including AOD, remain fail-closed pending frame tests. */
    fun allow(facts: R39SceneFacts): Boolean = facts.noOverlays &&
        (facts.idleLockscreen || (facts.wakingFromOff && facts.fromAbsent &&
            facts.toLockscreen && !facts.userDriven))
}
