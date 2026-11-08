package com.fluvi.app.lockscreen

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class KeyguardCardGeometryTest {
    private val bounds = KeyguardUsableBounds(10, 24, 410, 824)

    @Test fun `card keeps fixed height centered x and migrates bottom gravity y`() {
        val geometry = resolveKeyguardOverlayGeometry(
            bounds, 1f, 120, KeyguardCardPresentationMode.CARD, null, null, 0,
        )

        assertEquals(120, geometry.height)
        assertEquals(30, geometry.left) // (400 - 360) / 2 + safeLeft
        assertEquals(556, geometry.top) // old bottom y=148 => 824 - 120 - 148
        assertTrue(geometry.cardPosition.yFraction in 0f..1f)
    }

    @Test fun `card drag changes y but keeps x fixed and clamps every boundary`() {
        val start = resolveKeyguardOverlayGeometry(
            bounds, 1f, 120, KeyguardCardPresentationMode.CARD,
            KeyguardCardCardPosition(.5f), null, 0,
        )
        val moved = previewKeyguardOverlayGeometry(start, KeyguardCardPresentationMode.CARD, 300f, -5000f)

        assertEquals(start.left, moved.left)
        assertEquals(bounds.safeTop, moved.top)
    }

    @Test fun `orb is a fixed 64dp square and freely clamps x and y`() {
        val start = resolveKeyguardOverlayGeometry(
            bounds, 1f, 120, KeyguardCardPresentationMode.ORB, null,
            KeyguardCardOrbPosition(.5f, .5f), 0,
        )
        val moved = previewKeyguardOverlayGeometry(start, KeyguardCardPresentationMode.ORB, 5000f, 5000f)

        assertEquals(64, start.width)
        assertEquals(64, start.height)
        assertEquals(bounds.safeRight - 64, moved.left)
        assertEquals(bounds.safeBottom - 64, moved.top)
    }

    @Test fun `zero travel range has finite normalized positions`() {
        val tiny = KeyguardUsableBounds(0, 0, 1, 1)
        val geometry = resolveKeyguardOverlayGeometry(
            tiny, 1f, 120, KeyguardCardPresentationMode.ORB, null, null, 0,
        )

        assertTrue(geometry.orbPosition.xFraction.isFinite())
        assertTrue(geometry.orbPosition.yFraction.isFinite())
    }
}
