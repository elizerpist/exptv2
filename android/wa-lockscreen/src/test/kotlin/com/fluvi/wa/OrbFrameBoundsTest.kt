package com.fluvi.wa

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class OrbFrameBoundsTest {
    @Test
    fun bothSizesClampTheEntireRootAgainstAllFourInsets() {
        for (diameter in listOf(140, 280)) {
            val bounds = OrbFrameBounds(9, 31, 1014, 2144, diameter)
            assertTrue(bounds.fits)
            assertEquals(9 to 31, bounds.clamp(-90, -90))
            assertEquals((1014 - diameter) to (2144 - diameter), bounds.clamp(4000, 4000))
            assertEquals(9 to (2144 - diameter), bounds.clamp(-90, 4000))
            assertEquals((1014 - diameter) to 31, bounds.clamp(4000, -90))
            val applied = bounds.position(OrbPlacement(0.9f, 0.3f))
            assertEquals(applied, bounds.position(bounds.center(applied.first, applied.second)))
        }
    }

    @Test
    fun resizeUsesSavedNormalizedCenterAndSuspendsWhenTooWide() {
        val initial = OrbFrameBounds(10, 15, 1010, 2015, 56)
        val center = initial.center(954, 800)
        val resized = initial.copy(diameter = 112)
        assertEquals(898, resized.position(center).first)
        assertFalse(resized.copy(right = 97).fits)
    }
}
