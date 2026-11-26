package com.fluvi.app.lockscreen

import org.junit.Assert.assertEquals
import org.junit.Test

class KeyguardR448DisplayRouteTest {
    @Test fun missingOrUnknownPreferenceDefaultsToFluvi() {
        assertEquals(KeyguardR448DisplayRoute.FLUVI_STREAM, KeyguardR448DisplayRoute.parse(null))
        assertEquals(KeyguardR448DisplayRoute.FLUVI_STREAM, KeyguardR448DisplayRoute.parse("unknown"))
    }

    @Test fun bothPersistedWireValuesRoundTrip() {
        KeyguardR448DisplayRoute.entries.forEach { assertEquals(it, KeyguardR448DisplayRoute.parse(it.name)) }
    }
}
