package com.fluvi.app.lockscreen

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class KeyguardR47PrivateAdmissionTest {
    private val main = KeyguardCardSignals(
        requested = true, serviceConnected = true, userUnlocked = true,
        primaryDisplay = true, interactive = true, displayOn = true,
        keyguardLocked = true, surface = KeyguardSurface.MAIN_KEYGUARD,
        showFinancialDetails = true,
    )

    @Test fun freshFullMainAndExactMaterialAreRequired() {
        assertTrue(KeyguardR47PrivateAdmission.allows(main, complete = true, materialCurrent = true))
        assertFalse(KeyguardR47PrivateAdmission.allows(main, complete = false, materialCurrent = true))
        assertFalse(KeyguardR47PrivateAdmission.allows(main, complete = true, materialCurrent = false))
        assertFalse(KeyguardR47PrivateAdmission.allows(main.copy(showFinancialDetails = false), true, true))
        assertFalse(KeyguardR47PrivateAdmission.allows(main.copy(requested = false), true, true))
    }

    @Test fun unknownAndAllRestrictionStatesRemainHidden() {
        for (surface in listOf(KeyguardSurface.UNKNOWN, KeyguardSurface.CREDENTIAL,
                KeyguardSurface.SHADE, KeyguardSurface.OCCLUDED)) {
            assertFalse(KeyguardR47PrivateAdmission.allows(main.copy(surface = surface), true, true))
        }
        assertFalse(KeyguardR47PrivateAdmission.allows(main.copy(keyguardLocked = false), true, true))
        assertFalse(KeyguardR47PrivateAdmission.allows(main.copy(userUnlocked = false), true, true))
        assertFalse(KeyguardR47PrivateAdmission.allows(main.copy(displayOn = false, displayOff = true), true, true))
    }
}
