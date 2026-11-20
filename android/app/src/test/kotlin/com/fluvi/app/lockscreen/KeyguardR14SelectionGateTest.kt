package com.fluvi.app.lockscreen

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class KeyguardR14SelectionGateTest {
    private val authority = KeyguardInspectionAuthority(1, 2, 3, 4, 5)
    private fun request(id: Long = 10, trigger: String = "window", attach: Long = 5) =
        KeyguardCardInspectionRequest(id, trigger, 1, 2, 4, attach, 3, 100)
    private fun check(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility = KeyguardCardVisibility.SHOW_FULL,
        reason: KeyguardSurfaceReason = KeyguardSurfaceReason.MAIN_CONFIRMED, unavailable: Boolean = false,
        truncated: Boolean = false, stale: Boolean = false, started: Long = 101) =
        KeyguardR14SelectionGate.eligible(authority, request, 100, started, decision, reason, unavailable, truncated, stale)

    @Test fun incompleteReadDoesNotPreventALaterCompleteCurrentRead() {
        assertFalse(check(request(), KeyguardCardVisibility.HIDDEN_UNKNOWN, KeyguardSurfaceReason.ROOT_UNAVAILABLE, unavailable = true))
        assertTrue(check(request(11)))
    }
    @Test fun coalescedTagIsNotRequiredButGenerationAndTimeAre() {
        assertTrue(check(request(12, trigger = "window")))
        assertFalse(check(request(13, attach = 6)))
        assertFalse(check(request(14), started = 99))
        assertFalse(check(request(15), truncated = true))
        assertFalse(check(request(16), stale = true))
    }
}

class KeyguardR14FixtureCleanupTest {
    @Test fun failedPrerequisiteDoesNotSkipOtherRestorationsOrReplacePrimary() {
        val primary = IllegalStateException("first failure")
        val visited = mutableListOf<String>()
        val coordinator = KeyguardR14FixtureCleanup(primary) { label, _ -> visited += label }
        coordinator.attempt("disconnect") { error("disconnect failure") }
        coordinator.attempt("settings") { }
        coordinator.attempt("services") { }
        coordinator.finish()
        org.junit.Assert.assertEquals(listOf("disconnect", "settings", "services"), visited)
        org.junit.Assert.assertEquals("disconnect failure", primary.suppressed.single().message)
    }
}
