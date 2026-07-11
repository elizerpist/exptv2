package com.exptv2.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class NativeImeSheetDragModelTest {
    @Test
    fun clampsDragOffsetToSheetBounds() {
        assertEquals(0f, NativeImeSheetDragModel.clampOffset(-12f, 401f))
        assertEquals(120f, NativeImeSheetDragModel.clampOffset(120f, 401f))
        assertEquals(401f, NativeImeSheetDragModel.clampOffset(480f, 401f))
    }

    @Test
    fun dismissesWhenOffsetPassesThreshold() {
        assertFalse(
            NativeImeSheetDragModel.shouldDismiss(
                offsetPx = 72f,
                velocityYPxPerSecond = 0f,
                thresholdPx = 90f,
                velocityThresholdPxPerSecond = 1200f,
            ),
        )
        assertTrue(
            NativeImeSheetDragModel.shouldDismiss(
                offsetPx = 92f,
                velocityYPxPerSecond = 0f,
                thresholdPx = 90f,
                velocityThresholdPxPerSecond = 1200f,
            ),
        )
    }

    @Test
    fun dismissesWhenDownwardVelocityIsHigh() {
        assertTrue(
            NativeImeSheetDragModel.shouldDismiss(
                offsetPx = 24f,
                velocityYPxPerSecond = 1300f,
                thresholdPx = 90f,
                velocityThresholdPxPerSecond = 1200f,
            ),
        )
        assertFalse(
            NativeImeSheetDragModel.shouldDismiss(
                offsetPx = 24f,
                velocityYPxPerSecond = -1300f,
                thresholdPx = 90f,
                velocityThresholdPxPerSecond = 1200f,
            ),
        )
    }

    @Test
    fun combinesImeTranslationWithDragOffset() {
        assertEquals(-252f, NativeImeSheetDragModel.translationY(252, 0f))
        assertEquals(-132f, NativeImeSheetDragModel.translationY(252, 120f))
        assertEquals(40f, NativeImeSheetDragModel.translationY(0, 40f))
    }
}
