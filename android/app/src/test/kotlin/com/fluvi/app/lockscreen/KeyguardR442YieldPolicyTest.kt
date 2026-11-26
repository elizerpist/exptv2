package com.fluvi.app.lockscreen

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class KeyguardR442YieldPolicyTest {
    private val authority = KeyguardInspectionAuthority(1, 2, 3, 4, 5)
    private val old = KeyguardCardInspectionRequest(
        id = 10, trigger = "window", session = 1, visibilityEpoch = 2,
        interactionEpoch = 4, attachGeneration = 5, wakeGeneration = 3,
        queuedAtUptimeMs = 100, triggerReceivedUptimeMs = 100,
    )
    private val newer = old.copy(id = 11, trigger = "window", queuedAtUptimeMs = 250,
        triggerReceivedUptimeMs = 240)

    private fun permit(api: Int = 37, orb: Boolean = true, screen: Long? = 200,
                       session: Long? = 1, started: Long = 150,
                       active: KeyguardCardInspectionRequest? = old,
                       next: KeyguardCardInspectionRequest? = newer) =
        KeyguardR442YieldPolicy.permits(api, orb, screen, session, started, authority, active, old, next)

    @Test fun preScreenOwnerCanHandOffOnlyToCurrentPostScreenOffer() {
        assertTrue(permit())
        assertFalse(permit(next = null))
        assertFalse(permit(active = old.copy()))
        assertFalse(permit(next = newer.copy(visibilityEpoch = 99)))
        assertFalse(permit(next = newer.copy(wakeGeneration = 99)))
        assertFalse(permit(next = newer.copy(triggerReceivedUptimeMs = 199)))
        assertFalse(permit(next = newer.copy(triggerReceivedUptimeMs = null)))
        assertFalse(permit(next = newer.copy(trigger = "surfaceRetry")))
    }

    @Test fun usefulOrNonTargetReadsAreNeverDiscarded() {
        assertFalse(permit(api = 35))
        assertFalse(permit(orb = false))
        assertFalse(permit(screen = null))
        assertFalse(permit(session = 2))
        assertFalse(permit(started = 200))
        assertFalse(permit(next = newer.copy(id = old.id)))
    }
}
