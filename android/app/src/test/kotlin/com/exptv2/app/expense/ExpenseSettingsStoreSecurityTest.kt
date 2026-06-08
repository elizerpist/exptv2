package com.exptv2.app.expense

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class ExpenseSettingsStoreSecurityTest {
    private lateinit var context: Context
    private lateinit var store: ExpenseSettingsStore

    @Before
    fun setUp() {
        context = ApplicationProvider.getApplicationContext()
        context.getSharedPreferences("expense_settings", Context.MODE_PRIVATE)
            .edit()
            .clear()
            .commit()
        store = ExpenseSettingsStore(context)
    }

    @Test
    fun securitySettingsDefaultToDisabled() {
        val settings = store.loadSecuritySettings()

        assertEquals(false, settings["pinEnabled"])
        assertEquals(false, settings["biometricEnabled"])
    }

    @Test
    fun setSecurityPinStoresHashAndVerifiesPin() {
        store.setSecurityPin("1234")

        val settings = store.loadSecuritySettings()
        assertEquals(true, settings["pinEnabled"])
        assertTrue(store.verifySecurityPin("1234"))
        assertFalse(store.verifySecurityPin("0000"))
    }

    @Test
    fun changingPinRequiresCurrentPin() {
        store.setSecurityPin("1234")
        val changed = store.changeSecurityPin("1234", "4567")

        assertEquals(true, changed["pinEnabled"])
        assertFalse(store.verifySecurityPin("1234"))
        assertTrue(store.verifySecurityPin("4567"))
    }

    @Test(expected = ExpenseValidationException::class)
    fun changingPinRejectsWrongCurrentPin() {
        store.setSecurityPin("1234")

        store.changeSecurityPin("0000", "4567")
    }

    @Test
    fun clearingPinAlsoClearsBiometric() {
        store.setSecurityPin("1234")
        store.setBiometricEnabled(enabled = true, biometricAvailable = true)

        val settings = store.clearSecurityPin("1234")

        assertEquals(false, settings["pinEnabled"])
        assertEquals(false, settings["biometricEnabled"])
        assertFalse(store.verifySecurityPin("1234"))
    }

    @Test(expected = ExpenseValidationException::class)
    fun biometricCannotBeEnabledWithoutPin() {
        store.setBiometricEnabled(enabled = true, biometricAvailable = true)
    }

    @Test
    fun saltChangesHashForSamePin() {
        val prefs = context.getSharedPreferences("expense_settings", Context.MODE_PRIVATE)

        store.setSecurityPin("1234")
        val first = prefs.getString("securityPinHash", null)
        store.clearSecurityPin("1234")
        store.setSecurityPin("1234")
        val second = prefs.getString("securityPinHash", null)

        assertNotEquals(first, second)
    }

    @Test
    fun themeSettingsPersistProfileNightModeAndAppColor() {
        val updated = store.updateThemeSettings(
            mapOf(
                "magnetType" to "adaptive",
                "cardColor" to "darkgray",
                "theme" to "Türkiz",
                "backgroundColor" to "white",
                "boxColor" to "gray",
                "buttonSurfaceStyle" to "neutralNeutral",
                "contentSurfaceStyle" to "neutralNeutral",
                "backheaderStyle" to "orbitBudget",
                "designProfile" to "neumorphism",
                "nightMode" to "amber",
                "appColor" to "pink",
            )
        )

        assertEquals("neumorphism", updated["designProfile"])
        assertEquals("amber", updated["nightMode"])
        assertEquals("pink", updated["appColor"])
        assertEquals("neumorphism", store.loadThemeSettings()["designProfile"])
    }

    @Test
    fun legacyThemeSettingsMigrateMissingProfileValues() {
        val prefs = context.getSharedPreferences("expense_settings", Context.MODE_PRIVATE)
        prefs.edit()
            .putString("theme", "Sötét")
            .putString("buttonSurfaceStyle", "raisedInset")
            .putString("contentSurfaceStyle", "neutralNeutral")
            .commit()

        val settings = store.loadThemeSettings()

        assertEquals("neumorphism", settings["designProfile"])
        assertEquals("cyan", settings["nightMode"])
        assertEquals("turquoise", settings["appColor"])
    }
}
