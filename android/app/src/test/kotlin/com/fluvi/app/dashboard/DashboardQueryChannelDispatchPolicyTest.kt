package com.fluvi.app.dashboard

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class DashboardQueryChannelDispatchPolicyTest {
    @Test
    fun `dashboard Query channel uses one serial background queue`() {
        assertTrue(DashboardQueryChannelDispatchPolicy.usesBackgroundTaskQueue)
        assertTrue(DashboardQueryChannelDispatchPolicy.serializesIncomingCalls)
    }

    @Test
    fun `committed pages and Query replies do not require the Android main dispatcher`() {
        assertFalse(DashboardQueryChannelDispatchPolicy.requiresMainDispatcherForCommittedPages)
        assertFalse(DashboardQueryChannelDispatchPolicy.requiresMainDispatcherForResultDelivery)
    }
}
