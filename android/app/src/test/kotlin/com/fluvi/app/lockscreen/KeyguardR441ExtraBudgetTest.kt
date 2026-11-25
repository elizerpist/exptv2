package com.fluvi.app.lockscreen

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import android.view.accessibility.AccessibilityEvent

class KeyguardR441ExtraBudgetTest {
    @Test fun capsCallsAcrossWindows() {
        val budget = KeyguardR44ExtraBudget()
        repeat(4) { assertTrue(budget.reserve()) }
        assertFalse(budget.reserve())
        assertEquals(4, budget.fetched)
        assertTrue(budget.budgetHit)
    }

    @Test fun slowReturnedCallStopsFurtherOptionalCalls() {
        val budget = KeyguardR44ExtraBudget()
        assertTrue(budget.reserve())
        budget.elapsedMs = 51
        assertFalse(budget.reserve())
        assertEquals(1, budget.fetched)
        assertTrue(budget.budgetHit)
    }

    @Test fun knownRestrictionStopsDiscoveryWithoutFakingBudgetExhaustion() {
        val budget = KeyguardR44ExtraBudget()
        budget.restrictionObserved = true
        assertFalse(budget.reserve())
        assertEquals(0, budget.fetched)
        assertFalse(budget.budgetHit)
    }

    @Test fun unknownStructuralRolesFailClosedRegardlessOfCarrier() {
        assertTrue(KeyguardR44Markers.unknownMayRestrict("overlay:future", true))
        assertTrue(KeyguardR44Markers.unknownMayRestrict("scene:future", false))
        assertFalse(KeyguardR44Markers.unknownMayRestrict("element:clock-decoration", true))
    }

    @Test fun externalPrimaryTransitionsWithdrawOnlyOnApi37WhenVisible() {
        for (kind in listOf(AccessibilityEvent.TYPE_WINDOWS_CHANGED,
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED, AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED)) {
            val event = KeyguardAccessibilityEventMeta(kind, 7, 0, 0, "com.android.systemui")
            assertTrue(KeyguardR441RestrictionIngress.mustWithdraw(37, event, ownWindow = false, attached = true))
            assertFalse(KeyguardR441RestrictionIngress.mustWithdraw(35, event, ownWindow = false, attached = true))
            assertFalse(KeyguardR441RestrictionIngress.mustWithdraw(37, event, ownWindow = true, attached = true))
            assertFalse(KeyguardR441RestrictionIngress.mustWithdraw(37, event, ownWindow = false, attached = false))
            assertFalse(KeyguardR441RestrictionIngress.mustWithdraw(37, event.copy(displayId = 2), ownWindow = false, attached = true))
        }
    }
}
