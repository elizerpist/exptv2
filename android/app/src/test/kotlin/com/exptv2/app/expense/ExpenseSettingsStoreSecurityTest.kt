package com.exptv2.app.expense

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
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
    fun themeSettingsPersistAppColorAndKeepProfileLegacyOnly() {
        val updated = store.updateThemeSettings(
            mapOf(
                "magnetType" to "adaptive",
                "cardColor" to "darkgray",
                "theme" to "Türkiz",
                "backgroundColor" to "white",
                "boxColor" to "gray",
                "buttonSurfaceStyle" to "neutralNeutral",
                "contentSurfaceStyle" to "neutralNeutral",
                "backheaderStyle" to "centerBadgeBudget",
                "centerBackheaderDesign" to "colored",
                "centerPartitionRingEnabled" to true,
                "centerBadgeDiscEnabled" to false,
                "centerBadgeBorderMode" to "always",
                "designProfile" to "neumorphism",
                "appColor" to "pink",
            )
        )

        assertEquals("normal", updated["designProfile"])
        assertFalse(updated.containsKey("nightMode"))
        assertEquals("pink", updated["appColor"])
        assertEquals("colored", updated["centerBackheaderDesign"])
        assertEquals(true, updated["centerPartitionRingEnabled"])
        assertEquals(false, updated["centerBadgeDiscEnabled"])
        assertEquals("always", updated["centerBadgeBorderMode"])
        assertEquals("normal", store.loadThemeSettings()["designProfile"])
        assertEquals("colored", store.loadThemeSettings()["centerBackheaderDesign"])
        assertEquals(true, store.loadThemeSettings()["centerPartitionRingEnabled"])
        assertEquals(false, store.loadThemeSettings()["centerBadgeDiscEnabled"])
        assertEquals("always", store.loadThemeSettings()["centerBadgeBorderMode"])
        assertEquals(
            null,
            context.getSharedPreferences("expense_settings", Context.MODE_PRIVATE)
                .getString("designProfile", null)
        )
    }

    @Test
    fun themeSettingsPersistCenterBadgeOpacityControls() {
        val updated = store.updateThemeSettings(
            mapOf(
                "backheaderStyle" to "centerBadgeBudget",
                "centerBackheaderDesign" to "colored",
                "centerBadgeWhiteDiscOpacities" to listOf(20, 30, 40, 50, 60),
                "centerBadgeWhiteIconOpacities" to listOf(100, 90, 80, 70, 60),
                "centerBadgeWhiteProgressOpacities" to listOf(55, 45, 35, 25, 15),
                "centerBadgeColoredBackgroundOpacity" to 64,
            )
        )

        assertEquals(listOf(20, 30, 40, 50, 60), updated["centerBadgeWhiteDiscOpacities"])
        assertEquals(listOf(100, 90, 80, 70, 60), updated["centerBadgeWhiteIconOpacities"])
        assertEquals(listOf(55, 45, 35, 25, 15), updated["centerBadgeWhiteProgressOpacities"])
        assertEquals(64, updated["centerBadgeColoredBackgroundOpacity"])

        val loaded = store.loadThemeSettings()
        assertEquals(listOf(20, 30, 40, 50, 60), loaded["centerBadgeWhiteDiscOpacities"])
        assertEquals(listOf(100, 90, 80, 70, 60), loaded["centerBadgeWhiteIconOpacities"])
        assertEquals(listOf(55, 45, 35, 25, 15), loaded["centerBadgeWhiteProgressOpacities"])
        assertEquals(64, loaded["centerBadgeColoredBackgroundOpacity"])
    }

    @Test
    fun themeSettingsPersistGhostLogboxControls() {
        val updated = store.updateThemeSettings(
            mapOf(
                "buttonSurfaceStyle" to "raisedInset",
                "contentSurfaceStyle" to "insetInset",
                "ghostLogboxSurfaceStyle" to "insetInset",
                "ghostLogboxSettings" to mapOf(
                    "borderStyle" to "normal",
                    "backgroundOpacityEnabled" to false,
                    "avatarOpacityEnabled" to true,
                    "textOpacityEnabled" to true,
                    "avatarBadgeEnabled" to false,
                    "textTone" to "gray",
                    "expectedLabelEnabled" to false,
                ),
            )
        )

        val nested = updated["ghostLogboxSettings"] as Map<*, *>
        assertEquals("insetInset", updated["ghostLogboxSurfaceStyle"])
        assertEquals("normal", nested["borderStyle"])
        assertEquals(false, nested["backgroundOpacityEnabled"])
        assertEquals(true, nested["avatarOpacityEnabled"])
        assertEquals(true, nested["textOpacityEnabled"])
        assertEquals(false, nested["avatarBadgeEnabled"])
        assertEquals("gray", nested["textTone"])
        assertEquals(false, nested["expectedLabelEnabled"])

        val loaded = store.loadThemeSettings()
        val loadedNested = loaded["ghostLogboxSettings"] as Map<*, *>
        assertEquals("insetInset", loaded["ghostLogboxSurfaceStyle"])
        assertEquals("gray", loadedNested["textTone"])
        assertEquals(false, loadedNested["expectedLabelEnabled"])
    }

    @Test
    fun themeSettingsPersistCategorySurfaceControls() {
        val updated = store.updateThemeSettings(
            mapOf(
                "categoryMenuColor" to "darkgray",
                "categoryMenuSurfaceStyle" to "insetInset",
                "categoryCardColor" to "white",
                "categoryCardSurfaceStyle" to "raisedInset",
            )
        )

        assertEquals("darkgray", updated["categoryMenuColor"])
        assertEquals("insetInset", updated["categoryMenuSurfaceStyle"])
        assertEquals("white", updated["categoryCardColor"])
        assertEquals("raisedInset", updated["categoryCardSurfaceStyle"])

        val loaded = store.loadThemeSettings()
        assertEquals("darkgray", loaded["categoryMenuColor"])
        assertEquals("insetInset", loaded["categoryMenuSurfaceStyle"])
        assertEquals("white", loaded["categoryCardColor"])
        assertEquals("raisedInset", loaded["categoryCardSurfaceStyle"])
    }

    @Test
    fun themeSettingsPersistCategoryPresentationAndShadowControls() {
        val updated = store.updateThemeSettings(
            mapOf(
                "categoryMenuPresentation" to "slideUpSheet",
                "categoryCardShadowEnabled" to false,
                "logboxShadowEnabled" to true,
                "headerPillShadowEnabled" to false,
                "summaryPillShadowEnabled" to false,
                "searchPillShadowEnabled" to false,
            )
        )

        assertEquals("slideUpSheet", updated["categoryMenuPresentation"])
        assertEquals(false, updated["categoryCardShadowEnabled"])
        assertEquals(true, updated["logboxShadowEnabled"])
        assertEquals(false, updated["headerPillShadowEnabled"])
        assertEquals(false, updated["summaryPillShadowEnabled"])
        assertEquals(false, updated["searchPillShadowEnabled"])

        val loaded = store.loadThemeSettings()
        assertEquals("slideUpSheet", loaded["categoryMenuPresentation"])
        assertEquals(false, loaded["categoryCardShadowEnabled"])
        assertEquals(true, loaded["logboxShadowEnabled"])
        assertEquals(false, loaded["headerPillShadowEnabled"])
        assertEquals(false, loaded["summaryPillShadowEnabled"])
        assertEquals(false, loaded["searchPillShadowEnabled"])
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
        assertEquals("Türkiz", settings["theme"])
        assertFalse(settings.containsKey("nightMode"))
        assertEquals("turquoise", settings["appColor"])
    }
}
