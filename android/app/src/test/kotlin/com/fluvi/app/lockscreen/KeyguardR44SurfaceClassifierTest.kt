package com.fluvi.app.lockscreen

import android.view.accessibility.AccessibilityWindowInfo
import org.junit.Assert.assertEquals
import org.junit.Test

/** Controlled typed input only; it does not qualify an OEM display profile. */
class KeyguardR44SurfaceClassifierTest {
    private val host = KeyguardR44Witness(KeyguardR44Markers.Marker.HOST, KeyguardR44Markers.Carrier.VIEW_ID, 1)
    private val entry = KeyguardR44Witness(KeyguardR44Markers.Marker.DEVICE_ENTRY, KeyguardR44Markers.Carrier.VIEW_ID, 2)
    private fun evidence(
        host: KeyguardR44Witness? = this.host, content: KeyguardR44Witness? = entry,
        below: Boolean = true, complete: Boolean = true, foreign: Boolean = false,
        verified: Boolean = true, active: Boolean = true, passive: Boolean = false,
    ) = KeyguardR44WindowEvidence(verified, active, host, content, below, complete, foreign, passive)
    private fun window(id: Int = 10, layer: Int = 10, display: Int = 0,
                       pkg: String = "com.android.systemui", ids: Set<String> = emptySet(),
                       e: KeyguardR44WindowEvidence? = evidence()) = KeyguardWindowSnapshot(
        packageName = pkg, type = AccessibilityWindowInfo.TYPE_SYSTEM, layer = layer,
        displayId = display, visibleViewIds = ids, windowId = id, r44 = e)
    private fun decide(vararg windows: KeyguardWindowSnapshot, trial: Boolean = true,
                       unavailable: Boolean = false, truncated: Boolean = false) =
        KeyguardR44SurfaceClassifier.classify(windows.toList(), unavailable, truncated, false, trial).surface

    @Test fun qualifiedDistinctPairIsSyntheticOnly() {
        assertEquals(KeyguardSurface.MAIN_KEYGUARD, decide(window()))
        assertEquals(KeyguardSurface.UNKNOWN, decide(window(), trial = false))
    }

    @Test fun missingSpoofedPartialOrMismatchedProofCannotGrant() {
        listOf(
            evidence(host = null), evidence(content = null), evidence(below = false),
            evidence(content = entry.copy(ordinal = 1)), evidence(complete = false),
            evidence(foreign = true), evidence(verified = false), evidence(active = false),
        ).forEach { assertEquals(KeyguardSurface.UNKNOWN, decide(window(e = it))) }
        assertEquals(KeyguardSurface.UNKNOWN, decide(window(display = 1)))
        assertEquals(KeyguardSurface.UNKNOWN, decide(window(pkg = "com.other.app")))
        assertEquals(KeyguardSurface.UNKNOWN, decide(window(), unavailable = true))
        assertEquals(KeyguardSurface.UNKNOWN, decide(window(), truncated = true))
        assertEquals(KeyguardSurface.UNKNOWN, decide(window(e = evidence(content = null)),
            window(id = 11, layer = 9, e = evidence(host = null))))
    }

    @Test fun knownRestrictionsAlwaysPrecedeBothPositivePaths() {
        listOf("overlay:bouncer", "com.android.systemui:id/password_entry").forEach {
            assertEquals(KeyguardSurface.CREDENTIAL, decide(window(ids = setOf(it))))
        }
        listOf("overlay:notifications_shade", "overlay:quick_settings_shade", "scene:shade", "scene:quick_settings").forEach {
            assertEquals(KeyguardSurface.SHADE, decide(window(ids = setOf(it))))
        }
        assertEquals(KeyguardSurface.OCCLUDED,
            decide(window(ids = setOf("com.android.systemui:id/keyguard_camera_view"))))
        assertEquals(KeyguardSurface.SHADE, decide(window(ids = setOf(
            "com.android.systemui:id/keyguard_status_view", "scene:shade")), trial = false))
    }

    @Test fun higherFingerprintDoesNotHideAnInterveningCamera() {
        val fingerprint = window(id = 30, layer = 30, e = evidence(host = null, content = null,
            active = false, passive = true))
        val camera = window(id = 20, layer = 20, pkg = "com.android.camera", e = null)
        assertEquals(KeyguardSurface.MAIN_KEYGUARD, decide(window(), fingerprint))
        assertEquals(KeyguardSurface.UNKNOWN, decide(window(), camera, fingerprint))
        assertEquals(KeyguardSurface.UNKNOWN, decide(window(), fingerprint.copy(r44 = fingerprint.r44?.copy(verifiedPassive = false))))
    }

    @Test fun exactPublicTagsAreCaseSensitiveAndNarrow() {
        assertEquals(KeyguardR44Markers.Marker.HOST, KeyguardR44Markers.exact("element:lockscreen"))
        assertEquals(KeyguardR44Markers.Marker.LARGE_CLOCK, KeyguardR44Markers.exact("element:LargeClock"))
        assertEquals(null, KeyguardR44Markers.exact("element:largeclock"))
        assertEquals(null, KeyguardR44Markers.exact("com.fake:id/element:lockscreen"))
        assertEquals(null, KeyguardR44Markers.exact("com.android.systemui:id/udfps_view"))
    }
}
