package com.fluvi.app.lockscreen

import org.junit.Assert.*
import org.junit.Test

class KeyguardR43SurfaceEvidenceTest {
    @Test fun onlyVerifiedSystemOwnedResourceEntriesSurvive() {
        val evidence = KeyguardR43SurfaceEvidence()
        val window = requireNotNull(evidence.window(7, 3, 10, 0, true, false, "com.android.systemui", true))
        window.node(true, true, "com.android.systemui:id/keyguard_clock", 1, 0, 0)
        window.node(true, false, "com.android.systemui:id/keyguard_clock", 2, 1, 1)
        window.node(true, true, "com.android.systemui:id/private_test_tag", 3, 1, 1)
        window.node(true, true, "com.other:id/secret", 4, 1, 1)
        window.node(true, true, null, 5, 1, 1)
        window.node(false, true, "com.android.systemui:id/hidden", 6, 1, 1)
        val safe = evidence.verifiedEntries(window) { it == "keyguard_clock" }
        assertEquals(listOf("keyguard_clock"), safe.map { it.entry })
        assertEquals(6, window.visited)
        assertEquals(5, window.visible)
        assertEquals(1, window.nullId)
        assertEquals(1, window.foreignNode)
        assertFalse(safe.toString().contains("secret"))
        assertFalse(safe.toString().contains("private_test_tag"))
    }

    @Test fun untrustedRootsAndBoundedInputNeverBecomeEvidence() {
        val evidence = KeyguardR43SurfaceEvidence()
        val untrusted = requireNotNull(evidence.window(1, 3, 0, 0, true, false, "com.android.systemui", false))
        untrusted.node(true, true, "com.android.systemui:id/keyguard_clock", 1, 0, 0)
        assertTrue(evidence.verifiedEntries(untrusted) { true }.isEmpty())
        val trusted = requireNotNull(evidence.window(2, 3, 0, 0, true, false, "com.android.systemui", true))
        repeat(20) { trusted.node(true, true, "com.android.systemui:id/id_$it", it + 1, 0, 1) }
        assertEquals(KeyguardR43SurfaceEvidence.MAX_IDS, trusted.candidates.size)
        assertEquals(8, trusted.candidatesOmitted)
        evidence.window(3, 3, 0, 0, false, false, "foreign.secret", false)
        evidence.window(4, 3, 0, 1, false, false, null, false)
        assertNull(evidence.window(5, 3, 0, 0, false, false, "com.android.systemui", true))
        assertEquals(1, evidence.omittedWindows)
        assertFalse(evidence.windows().toString().contains("foreign.secret"))
    }
}
