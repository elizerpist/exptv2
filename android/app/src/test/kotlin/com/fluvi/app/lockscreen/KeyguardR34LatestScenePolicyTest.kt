package com.fluvi.app.lockscreen

import org.junit.Assert.assertEquals
import org.junit.Test

class KeyguardR34LatestScenePolicyTest {
    private fun decide(scene: Long? = 10, current: Long = 11, owner: Boolean = true,
                       safe: Boolean = true, restrictive: Boolean = false,
                       pending: Long? = 11, genuine: Boolean = true) =
        KeyguardR34LatestScenePolicy.decide(scene, current, owner, safe, restrictive, pending, genuine)

    @Test fun onlyTheExactLatestGenuineOfferTransfers() {
        assertEquals(KeyguardR34LatestScenePolicy.Action.TRANSFER, decide())
        assertEquals(KeyguardR34LatestScenePolicy.Action.WAIT_FOR_OFFER, decide(pending = null, genuine = false))
        assertEquals(KeyguardR34LatestScenePolicy.Action.WAIT_FOR_OFFER, decide(pending = 10))
        assertEquals(KeyguardR34LatestScenePolicy.Action.KEEP_READING, decide(pending = 12))
        assertEquals(KeyguardR34LatestScenePolicy.Action.KEEP_READING, decide(genuine = false))
    }

    @Test fun equalSceneOrAnyUnsafeBoundaryNeverSuppressesEvidence() {
        val keep = KeyguardR34LatestScenePolicy.Action.KEEP_READING
        assertEquals(keep, decide(scene = null))
        assertEquals(keep, decide(current = 10, pending = 10))
        assertEquals(keep, decide(owner = false))
        assertEquals(keep, decide(safe = false))
        assertEquals(keep, decide(restrictive = true))
    }

    @Test fun monotonicSceneRejectsAnAbaReversion() {
        assertEquals(KeyguardR34LatestScenePolicy.Action.TRANSFER, decide(scene = 10, current = 12, pending = 12))
        assertEquals(KeyguardR34LatestScenePolicy.Action.WAIT_FOR_OFFER, decide(scene = 10, current = 12, pending = 11))
    }
}
