package com.fluvi.app.lockscreen

import org.junit.Assert.assertEquals
import org.junit.Test

class KeyguardR448AdmissionTest {
    private val stamp = KeyguardR448Admission.Stamp(2, 3, 4)
    private val clear = KeyguardR448Admission.Presence.CLEAR
    private val present = KeyguardR448Admission.Presence.PRESENT
    private val unknown = KeyguardR448Admission.Presence.UNKNOWN
    private val system = KeyguardSystemState(101, 102, true, true, true, true, false, true, true)
    private val exclusions = KeyguardR448Admission.Exclusions(103, clear, clear, clear, clear)
    private val base = KeyguardR448Admission.Inputs(stamp, 100, system, exclusions,
        KeyguardR448Admission.Domain.PUBLIC_SAMPLE, true)
    private fun decide(inputs: KeyguardR448Admission.Inputs = base, current: KeyguardR448Admission.Stamp = stamp) =
        KeyguardR448Admission.evaluate(inputs, current, 110)

    @Test fun publicSampleDoesNotRequireAClockMarker() {
        assertEquals(KeyguardR448Admission.Decision.ALLOW, decide())
    }

    @Test fun allRestrictionKindsOverrideThePublicSample() {
        val restrictions = listOf(exclusions.copy(credential = present), exclusions.copy(shade = present),
            exclusions.copy(foreign = present), exclusions.copy(powerMenu = present))
        restrictions.forEach { assertEquals(KeyguardR448Admission.Decision.RESTRICTED, decide(base.copy(exclusions = it))) }
    }

    @Test fun unknownOrPreWakeEvidenceNeverBecomesPermission() {
        assertEquals(KeyguardR448Admission.Decision.EXCLUSION_UNKNOWN,
            decide(base.copy(exclusions = exclusions.copy(shade = unknown))))
        assertEquals(KeyguardR448Admission.Decision.EXCLUSION_UNKNOWN,
            decide(base.copy(exclusions = exclusions.copy(observedAt = 99))))
        assertEquals(KeyguardR448Admission.Decision.SYSTEM_UNKNOWN,
            decide(base.copy(system = system.copy(startedAt = 99))))
        assertEquals(KeyguardR448Admission.Decision.OWNER_CHANGED, decide(current = stamp.copy(wake = 5)))
    }

    @Test fun privateMaterialRequiresItsOwnAuthority() {
        val private = base.copy(domain = KeyguardR448Admission.Domain.PRIVATE)
        assertEquals(KeyguardR448Admission.Decision.MATERIAL_UNAUTHORIZED,
            decide(private.copy(materialAuthorized = false)))
        assertEquals(KeyguardR448Admission.Decision.MATERIAL_UNAUTHORIZED,
            decide(private.copy(system = system.copy(userUnlocked = false))))
    }
}
