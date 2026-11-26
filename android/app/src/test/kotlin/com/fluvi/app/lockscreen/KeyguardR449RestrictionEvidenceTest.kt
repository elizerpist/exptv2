package com.fluvi.app.lockscreen

import org.junit.Assert.assertEquals
import org.junit.Test

class KeyguardR449RestrictionEvidenceTest {
    private fun host(ids: Set<String> = emptySet(), complete: Boolean = true) = KeyguardWindowSnapshot(
        packageName = "com.android.systemui", type = 3, layer = 1, displayId = 0,
        visibleViewIds = ids, windowId = 4, r444Active = true, r444Focused = true,
        r44 = KeyguardR44WindowEvidence(true, true, null, null, false, complete, false))

    @Test fun completeHostWithoutClockIsClearForPublicAdmission() {
        val result = KeyguardR449RestrictionEvidence.fromInventory(listOf(host()), 50, false, false)
        assertEquals("CLEAR", result.reason)
        assertEquals(KeyguardR448Admission.Presence.CLEAR, result.exclusions.credential)
        assertEquals(KeyguardR448Admission.Presence.CLEAR, result.exclusions.shade)
        assertEquals(KeyguardR448Admission.Presence.CLEAR, result.exclusions.foreign)
        assertEquals(KeyguardR448Admission.Presence.CLEAR, result.exclusions.powerMenu)
    }

    @Test fun missingOrIncompleteWindowNeverMeansClear() {
        val upper = KeyguardWindowSnapshot(null, 3, 2, 0, windowId = 8)
        for (windows in listOf(emptyList(), listOf(host(emptySet(), false)), listOf(host(), upper))) {
            val result = KeyguardR449RestrictionEvidence.fromInventory(windows, 50, false, false)
            assertEquals(KeyguardR448Admission.Presence.UNKNOWN, result.exclusions.foreign)
        }
    }

    @Test fun actualRestrictionBeatsIncompleteInventory() {
        val pin = KeyguardR449RestrictionEvidence.fromInventory(
            listOf(host(setOf("element:BouncerContent"))), 50, true, false)
        assertEquals(KeyguardR448Admission.Presence.PRESENT, pin.exclusions.credential)
        val shade = KeyguardR449RestrictionEvidence.fromInventory(
            listOf(host(setOf("scene:shade"))), 50, false, true)
        assertEquals(KeyguardR448Admission.Presence.PRESENT, shade.exclusions.shade)
        val power = KeyguardR449RestrictionEvidence.fromInventory(
            listOf(host(setOf("com.android.systemui:id/global_actions_container"))), 50, false, false)
        assertEquals(KeyguardR448Admission.Presence.PRESENT, power.exclusions.powerMenu)
    }

    @Test fun foreignAndUnverifiedUpperNeverGrant() {
        val other = KeyguardWindowSnapshot("other.app", 1, 2, 0, windowId = 7)
        val result = KeyguardR449RestrictionEvidence.fromInventory(listOf(host(), other), 50, false, false)
        assertEquals(KeyguardR448Admission.Presence.PRESENT, result.exclusions.foreign)
    }
}
