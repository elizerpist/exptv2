package com.fluvi.app.lockscreen

import org.junit.Assert.*
import org.junit.Test

class KeyguardR40ClockProvenanceTest {
    private fun window(p: KeyguardR40ClockProvenance, id: Int, verified: Boolean = true,
                       pkg: String = "com.android.systemui", type: Int = 3,
                       markers: List<String> = emptyList()) {
        p.beginWindow(id, 0, pkg, type, verified)
        markers.forEach(p::marker)
        p.endWindow()
    }
    private val clock = "com.android.systemui:id/keyguard_clock_switch"
    private val carrier = "com.android.systemui:id/keyguard_carrier_text"
    @Test fun uniqueVerifiedSystemClockIsAttributed() {
        val p = KeyguardR40ClockProvenance()
        window(p, 12, markers = listOf(clock, carrier))
        assertEquals(12, p.result { it == 12 })
    }
    @Test fun incompleteAmbiguousNonSystemOrUnverifiedNeverAttributes() {
        val absent = KeyguardR40ClockProvenance(); window(absent, 12, markers = listOf(carrier))
        assertNull(absent.result { true })
        val mismatch = KeyguardR40ClockProvenance(); window(mismatch, 12, false, markers = listOf(clock))
        assertNull(mismatch.result { true })
        val wrongPackage = KeyguardR40ClockProvenance(); window(wrongPackage, 12, pkg = "com.android.keyguard", markers = listOf(clock))
        assertNull(wrongPackage.result { true })
        val duplicate = KeyguardR40ClockProvenance(); window(duplicate, 12, markers = listOf(clock)); window(duplicate, 13, markers = listOf(carrier))
        assertNull(duplicate.result { true })
        val duplicateId = KeyguardR40ClockProvenance(); window(duplicateId, 12, markers = listOf(clock))
        assertNull(duplicateId.result { false })
    }
}
