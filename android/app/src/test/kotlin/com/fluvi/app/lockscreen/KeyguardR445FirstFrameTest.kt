package com.fluvi.app.lockscreen

import android.view.accessibility.AccessibilityWindowInfo
import org.junit.Assert.assertEquals
import org.junit.Test

/** The paired phone observations are separate fixtures, not a simulated phone result. */
class KeyguardR445FirstFrameTest {
    @Test fun realSmallClockIdHasARecognizedRole() {
        assertEquals(KeyguardR44Markers.Marker.SMALL_CLOCK,
            KeyguardR44Markers.exact("com.android.systemui:id/lockscreen_clock_view"))
    }

    @Test fun realLargeClockIdHasARecognizedRole() {
        assertEquals(KeyguardR44Markers.Marker.LARGE_CLOCK,
            KeyguardR44Markers.exact("com.android.systemui:id/lockscreen_clock_view_large"))
    }

    @Test fun measuredHostWithoutContentStaysHiddenEvenWithSensor() {
        val host = KeyguardR44Witness(KeyguardR44Markers.Marker.HOST,
            KeyguardR44Markers.Carrier.EXTRA_LAZY, 2)
        val hostEvidence = KeyguardR44WindowEvidence(true, true, host, null, false, true, false)
        val sensorEvidence = KeyguardR44WindowEvidence(true, false, null, null, false, true, false)
        val hostWindow = KeyguardWindowSnapshot("com.android.systemui", AccessibilityWindowInfo.TYPE_SYSTEM,
            20, 0, visibleViewIds = emptySet(), windowId = 1, r44 = hostEvidence)
        val sensorWindow = KeyguardWindowSnapshot("com.android.systemui", AccessibilityWindowInfo.TYPE_SYSTEM,
            21, 0, visibleViewIds = emptySet(), windowId = 2, r44 = sensorEvidence,
            r444Active = false, r444Focused = false, r444RootRole = "UDFPS_VERIFIED")
        for (expanded in listOf(false, true)) {
            val decision = KeyguardR44SurfaceClassifier.classify(listOf(hostWindow, sensorWindow),
                false, false, false, syntheticTrial = true, expanded = expanded)
            assertEquals(KeyguardSurface.UNKNOWN, decision.surface)
            assertEquals(KeyguardR444Gate.NO_CONTENT, decision.r444Gate)
        }
    }
}
