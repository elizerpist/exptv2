package com.fluvi.app.lockscreen

import android.view.accessibility.AccessibilityWindowInfo
import org.junit.Assert.*
import org.junit.Test

class KeyguardR39WindowProvenanceTest {
    private fun clock(id: Int = 73, verified: Boolean = true, display: Int = 0,
                      pkg: String = "com.android.systemui", type: Int = AccessibilityWindowInfo.TYPE_SYSTEM,
                      own: Boolean = false, marker: String = "com.android.systemui:id/keyguard_clock_switch") =
        KeyguardWindowSnapshot(pkg, type, 20, display, own, setOf(marker), id, verified)

    @Test fun onlyAUniqueVerifiedSystemClockWindowProvidesNegativeWitness() {
        val positive = KeyguardSurfaceClassifier.classifyDetailed(listOf(clock()))
        assertEquals(KeyguardSurface.MAIN_KEYGUARD, positive.surface)
        assertEquals(73, positive.authorizingClockWindowId)
        assertNull(KeyguardSurfaceClassifier.classifyDetailed(listOf(clock(verified = false))).authorizingClockWindowId)
        assertNull(KeyguardSurfaceClassifier.classifyDetailed(listOf(clock(type = AccessibilityWindowInfo.TYPE_APPLICATION))).authorizingClockWindowId)
        assertNull(KeyguardSurfaceClassifier.classifyDetailed(listOf(clock(pkg = "android"))).authorizingClockWindowId)
        assertNull(KeyguardSurfaceClassifier.classifyDetailed(listOf(clock(), clock(74))).authorizingClockWindowId)
        assertNull(KeyguardSurfaceClassifier.classifyDetailed(listOf(clock(), clock(own = true))).authorizingClockWindowId)
        assertNull(KeyguardSurfaceClassifier.classifyDetailed(listOf(clock()), unavailableRoot = true).authorizingClockWindowId)
        assertNull(KeyguardSurfaceClassifier.classifyDetailed(listOf(clock()), walkTruncated = true).authorizingClockWindowId)
        val carrierOnly = clock(marker = "com.android.systemui:id/keyguard_carrier_text")
        assertEquals(KeyguardSurface.MAIN_KEYGUARD, KeyguardSurfaceClassifier.classifyDetailed(listOf(carrierOnly)).surface)
        assertNull(KeyguardSurfaceClassifier.classifyDetailed(listOf(carrierOnly)).authorizingClockWindowId)
    }

    @Test fun restrictiveMarkerStillDominatesVerifiedClock() {
        val root = clock().copy(visibleViewIds = setOf("com.android.systemui:id/keyguard_clock_switch",
            "com.android.systemui:id/keyguard_security_container"))
        val result = KeyguardSurfaceClassifier.classifyDetailed(listOf(root))
        assertEquals(KeyguardSurface.CREDENTIAL, result.surface)
        assertNull(result.authorizingClockWindowId)
    }
}
