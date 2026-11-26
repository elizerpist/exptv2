package com.fluvi.app.lockscreen

import org.junit.Assert.assertEquals
import org.junit.Test

class KeyguardR448WakeReadBoundaryTest {
    private val current = KeyguardR448WakeReadBoundary.Work(1, true, true)

    @Test fun preScreenReaderWithoutSuccessorRequiresOneFreshOffer() {
        assertEquals(KeyguardR448WakeReadBoundary.Decision.OFFER,
            KeyguardR448WakeReadBoundary.decide(current, null, 1, false))
    }

    @Test fun unstartedOrPostBoundaryReaderIsAlreadySuitable() {
        assertEquals(KeyguardR448WakeReadBoundary.Decision.ACTIVE_NOT_STARTED,
            KeyguardR448WakeReadBoundary.decide(current, null, null, false))
        assertEquals(KeyguardR448WakeReadBoundary.Decision.ACTIVE_AFTER_BOUNDARY,
            KeyguardR448WakeReadBoundary.decide(current, null, 1, true))
    }

    @Test fun currentPendingWorkWillStartAfterBoundaryWithoutReplacement() {
        val pending = KeyguardR448WakeReadBoundary.Work(2, true, true)
        assertEquals(KeyguardR448WakeReadBoundary.Decision.CURRENT_PENDING,
            KeyguardR448WakeReadBoundary.decide(current, pending, 1, false))
    }

    @Test fun oldAuthorityOrCaptureDoesNotSatisfyNewArm() {
        val oldCapture = KeyguardR448WakeReadBoundary.Work(1, true, false)
        val oldWake = KeyguardR448WakeReadBoundary.Work(2, false, true)
        assertEquals(KeyguardR448WakeReadBoundary.Decision.OFFER,
            KeyguardR448WakeReadBoundary.decide(oldCapture, oldWake, 1, true))
        assertEquals(KeyguardR448WakeReadBoundary.Decision.OFFER,
            KeyguardR448WakeReadBoundary.decide(null, oldWake, null, false))
    }
}
