package com.fluvi.app.lockscreen

import android.view.accessibility.AccessibilityWindowInfo
import org.junit.Assert.*
import org.junit.Test

class KeyguardR446PrintPolicyTest {
    private val bounds = KeyguardR446Bounds(0, 0, 1080, 2400)
    private fun window(id: Int, layer: Int, active: Boolean, focused: Boolean = active,
                       verified: Boolean = true, owner: String = "com.android.systemui") =
        KeyguardWindowSnapshot(owner, AccessibilityWindowInfo.TYPE_SYSTEM, layer, 0, windowId = id,
            r44 = KeyguardR44WindowEvidence(verified, active, null, null, false, true, false),
            r444Active = active, r444Focused = focused, r446Bounds = bounds)
    private val missingPositive = KeyguardSurfaceClassification(KeyguardSurface.UNKNOWN,
        KeyguardSurfaceReason.NO_MAIN_MARKER, r444Gate = KeyguardR444Gate.NO_CONTENT)

    @Test fun missingClockAllowsOnlySeparatelyTypedSampleForOneOrTwoVerifiedWindows() {
        for (base in listOf(1, 100, 4000)) {
            val host = window(base, base * 2, true)
            val companion = window(base + 17, base * 2 + 40, false)
            for (windows in listOf(listOf(host), listOf(companion, host))) {
                val result = KeyguardR446PrintPolicy.evaluate(windows, missingPositive, false, false)
                assertEquals("ELIGIBLE_SAMPLE", result.reason)
                assertEquals(host.windowId, result.target?.windowId)
                assertEquals(KeyguardSurface.UNKNOWN, missingPositive.surface)
            }
        }
        val host = window(77, 3, true)
        assertNotNull(KeyguardR446PrintPolicy.evaluate(listOf(host),
            missingPositive.copy(r444Gate = KeyguardR444Gate.NO_HOST), false, false).target)
        assertNotNull(KeyguardR446PrintPolicy.evaluate(listOf(host, window(88, 9, false)),
            missingPositive.copy(r444Gate = KeyguardR444Gate.COVER_VETO), false, false).target)
    }

    @Test fun restrictionIncompleteOrUnverifiedWindowsNeverYieldTicket() {
        val host = window(2, 5, true)
        val bad = listOf(
            KeyguardSurfaceClassification(KeyguardSurface.CREDENTIAL, KeyguardSurfaceReason.CREDENTIAL_MARKER),
            KeyguardSurfaceClassification(KeyguardSurface.SHADE, KeyguardSurfaceReason.SHADE_MARKER),
            KeyguardSurfaceClassification(KeyguardSurface.OCCLUDED, KeyguardSurfaceReason.FOREIGN_ABOVE),
            missingPositive.copy(r444Gate = KeyguardR444Gate.INCOMPLETE),
        )
        bad.forEach { assertNull(KeyguardR446PrintPolicy.evaluate(listOf(host), it, false, false).target) }
        assertNull(KeyguardR446PrintPolicy.evaluate(listOf(host), missingPositive, true, false).target)
        assertNull(KeyguardR446PrintPolicy.evaluate(listOf(host), missingPositive, false, true).target)
        assertNull(KeyguardR446PrintPolicy.evaluate(listOf(host, window(3, 8, false, owner = "other")), missingPositive, false, false).target)
        assertNull(KeyguardR446PrintPolicy.evaluate(listOf(host, window(3, 8, false, verified = false)), missingPositive, false, false).target)
        assertNull(KeyguardR446PrintPolicy.evaluate(listOf(host, window(3, 8, false, focused = true)), missingPositive, false, false).target)
        assertNull(KeyguardR446PrintPolicy.evaluate(listOf(host, window(3, 8, false), window(4, 9, false)), missingPositive, false, false).target)
    }

    @Test fun capabilityBindsCaptureWakeSceneAndExpiresWithoutRearming() {
        val owner = KeyguardR446PrintOwner()
        owner.arm(8, "capture-a")
        assertFalse(owner.wake(8, "capture-a"))
        owner.screenOff()
        assertFalse(owner.wake(8, "other"))
        assertTrue(owner.wake(8, "capture-a"))
        val target = KeyguardR446Target(7, 0, bounds)
        val ticket = requireNotNull(owner.issue(8, "capture-a", 5, 22, 9, target, 1000))
        assertTrue(owner.current(ticket, 8, "capture-a", 5, 9, 2999))
        assertFalse(owner.current(ticket, 8, "capture-a", 5, 9, 3000))
        assertFalse(owner.current(ticket, 8, "capture-b", 5, 9, 1001))
        assertFalse(owner.current(ticket, 8, "capture-a", 6, 9, 1001))
        assertFalse(owner.current(ticket, 8, "capture-a", 5, 10, 1001))
        assertNull(owner.issue(8, "capture-a", 5, 23, 9, target, 1001))
        owner.revoke()
        assertFalse(owner.current(ticket, 8, "capture-a", 5, 9, 1001))
        owner.screenOff()
        assertFalse(owner.wake(8, "capture-a"))
    }
}
