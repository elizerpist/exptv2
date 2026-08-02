package com.fluvi.app.dashboard

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class DashboardObservationSessionTest {
    @Test
    fun lateCancellationForOldListenerDoesNotStopNewestObservation() {
        val cancelled = mutableListOf<String>()
        val session = DashboardObservationSession<String>(cancelled::add)

        session.replace(subscriptionId = "listener-1", observation = "job-1")
        session.replace(subscriptionId = "listener-2", observation = "job-2")

        assertTrue(session.cancelIfActive("listener-1").not())
        assertEquals("listener-2", session.activeSubscriptionId)
        assertEquals(listOf("job-1"), cancelled)

        assertTrue(session.cancelIfActive("listener-2"))
        assertEquals(null, session.activeSubscriptionId)
        assertEquals(listOf("job-1", "job-2"), cancelled)
    }

    @Test
    fun replacingTheSameListenerCancelsOnlyItsPreviousObservation() {
        val cancelled = mutableListOf<String>()
        val session = DashboardObservationSession<String>(cancelled::add)

        session.replace(subscriptionId = "listener-1", observation = "job-1")
        session.replace(subscriptionId = "listener-1", observation = "job-2")

        assertEquals("listener-1", session.activeSubscriptionId)
        assertEquals(listOf("job-1"), cancelled)
        assertFalse(session.cancelIfActive("listener-other"))
    }
}
