package com.android.systemui.keyguard.fluvi

import com.fluvi.r29.contract.R39SceneFacts
import com.fluvi.r29.contract.R39EmptyEvidence
import com.fluvi.r29.contract.R39EmptyPolicy
import com.fluvi.r29.contract.R39ScenePolicy
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Local authority policy only. This is not a compositor or optical test. */
class FluviR39ScenePolicyTest {
    private val incoming = R39SceneFacts(idleLockscreen = false, wakingFromOff = true,
        fromAbsent = true, toLockscreen = true, noOverlays = true, userDriven = false)
    @Test fun onlyAQualifiedIncomingOffToClockCanOpen() {
        assertTrue(R39ScenePolicy.allow(incoming))
        listOf(incoming.copy(wakingFromOff = false), incoming.copy(fromAbsent = false),
            incoming.copy(toLockscreen = false), incoming.copy(noOverlays = false),
            incoming.copy(userDriven = true)).forEach { assertFalse(R39ScenePolicy.allow(it)) }
    }
    @Test fun idleClockRejectsOverlayAndUnknownStates() {
        val idle = incoming.copy(idleLockscreen = true, wakingFromOff = false,
            fromAbsent = false, toLockscreen = false)
        assertTrue(R39ScenePolicy.allow(idle))
        assertFalse(R39ScenePolicy.allow(idle.copy(noOverlays = false)))
        assertFalse(R39ScenePolicy.allow(idle.copy(idleLockscreen = false)))
    }
    @Test fun emptyReceiptRejectsMissingFenceAndEveryStaleOwnerBoundary() {
        val complete = R39EmptyEvidence(true, true, true, true, true, true, true)
        assertTrue(R39EmptyPolicy.mayAcknowledge(complete))
        listOf(complete.copy(validFenceSignalled = false), complete.copy(sameAttachedRoot = false),
            complete.copy(samePendingRequest = false), complete.copy(nextEmptyDrawObserved = false),
            complete.copy(singleOriginalOwner = false), complete.copy(noLaterOrbDraw = false),
            complete.copy(sameEmptyGeneration = false)).forEach { assertFalse(R39EmptyPolicy.mayAcknowledge(it)) }
    }
}
