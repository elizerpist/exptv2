package com.fluvi.app.lockscreen.material

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class KeyguardR47FrameContractTest {
    @Test fun rejectsAnimatedStarterAndOutOfBudgetPackages() {
        assertEquals("incompleteSequence", KeyguardR47FrameContract.validate(true, 1, 32, 32, 100))
        assertEquals("incompleteSequence", KeyguardR47FrameContract.validate(false, 3, 32, 32, 100))
        assertEquals("byteBudgetExceeded", KeyguardR47FrameContract.validate(true, 175, 128, 32, 100))
        assertEquals("byteBudgetExceeded", KeyguardR47FrameContract.validate(true, 3, 32, 32, 2_097_153))
        assertEquals("invalidGeometry", KeyguardR47FrameContract.validate(true, 3, 32, 0, 100))
        assertNull(KeyguardR47FrameContract.validate(true, 3, 32, 32, 100))
        assertNull(KeyguardR47FrameContract.validate(false, 1, 128, 1000, 100))
    }

    @Test fun sameGenerationUsesTheSameMonotonicPhaseOnResume() {
        val origin = 1_000_000_000L
        assertEquals(0, KeyguardR47FrameContract.frameIndex(origin - 1, origin, 100, 3))
        assertEquals(1, KeyguardR47FrameContract.frameIndex(origin + 100_000_000L, origin, 100, 3))
        assertEquals(2, KeyguardR47FrameContract.frameIndex(origin + 500_000_000L, origin, 100, 3))
    }
}
