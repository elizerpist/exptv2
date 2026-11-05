package com.fluvi.app.lockscreen

import com.fluvi.app.runtime.FluviLockScreenCardConfiguration
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class KeyguardCardFocusTest {
    @Test fun `new keyguard focus defaults to an independently valid balance month`() {
        val focus = KeyguardCardFocus()

        assertEquals(FluviLockScreenCardConfiguration.Mode.balance, focus.mode)
        assertEquals(FluviLockScreenCardConfiguration.TimeAxis.month, focus.timeAxis)
        assertTrue(focus.isValid)
    }

    @Test fun `budget without category remains explicitly incomplete`() {
        val focus = KeyguardCardFocus(
            mode = FluviLockScreenCardConfiguration.Mode.budget,
            categoryId = null,
        )

        assertFalse(focus.isValid)
        assertNull(focus.asFinancialFocus().categoryId)
    }

    @Test fun `focus projection preserves selected category without widget authority`() {
        val focus = KeyguardCardFocus(
            mode = FluviLockScreenCardConfiguration.Mode.budget,
            timeAxis = FluviLockScreenCardConfiguration.TimeAxis.year,
            categoryId = "food",
            generation = 7L,
        )

        val projected = focus.asFinancialFocus()
        assertEquals("food", projected.categoryId)
        assertEquals(7L, projected.generation)
        assertEquals(FluviLockScreenCardConfiguration.TimeAxis.year, projected.timeAxis)
    }
}
