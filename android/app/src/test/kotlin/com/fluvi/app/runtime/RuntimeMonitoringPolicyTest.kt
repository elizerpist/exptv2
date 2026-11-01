package com.fluvi.app.runtime

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class RuntimeMonitoringPolicyTest {
    @Test
    fun `both switches off blocks capture after surface closes`() {
        val evaluation = evaluate(FluviRuntimePreferences())

        assertFalse(evaluation.captureAllowed)
        assertEquals("off", evaluation.state)
    }

    @Test
    fun `foreground session permits capture with hidden surface only when running`() {
        val settings = FluviRuntimePreferences(foregroundRequested = true)

        assertFalse(evaluate(settings, foregroundRunning = false).captureAllowed)
        assertTrue(evaluate(settings, foregroundRunning = true).captureAllowed)
    }

    @Test
    fun `background mode permits Android listener without foreground service`() {
        val evaluation = evaluate(
            FluviRuntimePreferences(backgroundRequested = true),
            listenerConnected = true,
        )

        assertTrue(evaluation.captureAllowed)
        assertEquals("active", evaluation.state)
    }

    @Test
    fun `explicit stop overrides both requested switches`() {
        val evaluation = evaluate(
            FluviRuntimePreferences(
                foregroundRequested = true,
                backgroundRequested = true,
                stoppedByUser = true,
            ),
            foregroundRunning = true,
        )

        assertFalse(evaluation.captureAllowed)
        assertEquals("stopped", evaluation.state)
    }

    private fun evaluate(
        settings: FluviRuntimePreferences,
        foregroundRunning: Boolean = false,
        listenerConnected: Boolean = false,
    ): RuntimeMonitoringEvaluation = RuntimeMonitoringPolicy.evaluate(
        preferences = settings,
        listenerGranted = true,
        foregroundServiceRunning = foregroundRunning,
        foregroundStartFailed = false,
        postNotificationsGranted = true,
        statusChannelEnabled = true,
        appSurfaceVisible = false,
        listenerConnected = listenerConnected,
    )
}
