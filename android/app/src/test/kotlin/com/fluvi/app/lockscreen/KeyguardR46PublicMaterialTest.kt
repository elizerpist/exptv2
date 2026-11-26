package com.fluvi.app.lockscreen

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class KeyguardR46PublicMaterialTest {
    @Test fun publicFactoryKeepsOnlyTheCompiledDemoAndReturnsIndependentArrays() {
        val first = KeyguardR46PublicMaterial.demo().sceneProfile()
        assertArrayEquals(intArrayOf(0xff104f7c.toInt(), 0xff62c7dc.toInt(), 0xff8366dc.toInt()), first.colors)
        assertEquals("dualTide", first.effectId)
        assertTrue(first.animated)
        first.colors[0] = 0xff000000.toInt()
        first.commonSettings[0] = 100f
        val second = KeyguardR46PublicMaterial.demo().sceneProfile()
        assertEquals(0xff104f7c.toInt(), second.colors[0])
        assertEquals(.2f, second.commonSettings[0], 0f)
        assertArrayEquals(intArrayOf(0xff657489.toInt(), 0xff8592a4.toInt(), 0xff657489.toInt()),
            second.neutralized().colors)
    }

    @Test fun trialDisablesFinancialDetails() {
        KeyguardR44Trial.set(true, false)
        try { assertFalse(KeyguardR44Trial.settings(KeyguardCardSettings(showFinancialDetails = true)).showFinancialDetails) }
        finally { KeyguardR44Trial.set(false, false) }
    }
}
