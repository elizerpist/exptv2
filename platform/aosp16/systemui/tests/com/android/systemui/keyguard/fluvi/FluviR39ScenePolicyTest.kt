package com.android.systemui.keyguard.fluvi

import com.fluvi.r29.contract.R39SceneFacts
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
}
