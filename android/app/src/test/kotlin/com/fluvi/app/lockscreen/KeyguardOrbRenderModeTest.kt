package com.fluvi.app.lockscreen

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class KeyguardOrbRenderModeTest {
    @Test fun defaultAndUnknownSelectionsNeverTurnOffTheProductionRoute() {
        assertEquals(KeyguardOrbRenderMode.SURFACE_LIVE, KeyguardOrbRenderMode.parse(null))
        assertEquals(KeyguardOrbRenderMode.SURFACE_LIVE, KeyguardOrbRenderMode.parse("unknown"))
        assertEquals(KeyguardOrbRenderMode.SURFACE_STATIC, KeyguardOrbRenderMode.parse("SURFACE_STATIC"))
        assertEquals(KeyguardOrbRenderMode.LEGACY_R11, KeyguardOrbRenderMode.parse("LEGACY_R11"))
    }

    @Test fun preferenceTakesEffectOnlyAtAHiddenBoundary() {
        val visible = KeyguardOrbRenderModeStatus(
            configured = KeyguardOrbRenderMode.SURFACE_STATIC,
            effective = KeyguardOrbRenderMode.SURFACE_LIVE,
            visible = true,
        )
        assertTrue(visible.pendingBoundary)
        assertFalse(visible.copy(visible = false).pendingBoundary)
        assertFalse(visible.copy(effective = visible.configured, attachedSelection = visible.configured).pendingBoundary)
    }
}
