package com.android.systemui.keyguard.fluvi

import com.fluvi.r29.contract.R29FrameInputs
import com.fluvi.r29.contract.R29FramePolicy
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Unit control only: it is not a composed-image or first-frame test. */
class FluviOrbFramePolicyTest {
    private val ordinary = R29FrameInputs(
        inputsKnown = true, ordinaryLockscreen = true, primaryUser = true, defaultDisplay = true,
        defaultBlueprint = true, geometryValid = true, policyAllowsFull = true, currentReadyRevision = true,
        dozing = false, dreaming = false, occluded = false, goingAway = false, credential = false,
        shadeOrQs = false, restrictiveTransition = false,
    )

    @Test fun allAuthoritiesMustBeKnownAndAffirmative() {
        assertTrue(R29FramePolicy.allow(ordinary))
        val rejected = listOf(ordinary.copy(inputsKnown = false), ordinary.copy(ordinaryLockscreen = false),
            ordinary.copy(primaryUser = false), ordinary.copy(defaultDisplay = false),
            ordinary.copy(defaultBlueprint = false), ordinary.copy(geometryValid = false),
            ordinary.copy(policyAllowsFull = false), ordinary.copy(currentReadyRevision = false))
        rejected.forEach { assertFalse(R29FramePolicy.allow(it)) }
    }

    @Test fun everyRestrictiveStateExcludesTheOutgoingImage() {
        val rejected = listOf(ordinary.copy(dozing = true), ordinary.copy(dreaming = true),
            ordinary.copy(occluded = true), ordinary.copy(goingAway = true),
            ordinary.copy(credential = true), ordinary.copy(shadeOrQs = true),
            ordinary.copy(restrictiveTransition = true))
        rejected.forEach { assertFalse(R29FramePolicy.allow(it)) }
    }
}
