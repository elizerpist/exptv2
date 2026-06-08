package com.exptv2.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class NotificationCaptureEligibilityTest {
    @Test
    fun acceptsExactPackageMatchFromEnabledProfile() {
        val result = NotificationCaptureEligibility.evaluate(
            profiles = listOf(
                captureProfile(
                    id = "bank-a",
                    packageName = "hu.bank.a",
                    appLabel = "Bank A",
                    appFilterText = "^Bank A$",
                ),
            ),
            packageName = "hu.bank.a",
            appLabel = "Different visible label",
        )

        assertTrue(result.allowed)
        assertEquals("package", result.reason)
        assertEquals("bank-a", result.profileId)
    }

    @Test
    fun rejectsDifferentPackageEvenWhenNotificationTextLooksValid() {
        val result = NotificationCaptureEligibility.evaluate(
            profiles = listOf(
                captureProfile(
                    id = "bank-a",
                    packageName = "hu.bank.a",
                    appLabel = "Bank A",
                    appFilterText = "^Bank A$",
                ),
            ),
            packageName = "org.kustom.widget",
            appLabel = "Kustom Widget",
        )

        assertFalse(result.allowed)
        assertEquals("no_profile_match", result.reason)
    }

    @Test
    fun acceptsLabelRegexOnlyWhenProfileHasNoPackageName() {
        val result = NotificationCaptureEligibility.evaluate(
            profiles = listOf(
                captureProfile(
                    id = "legacy-bank",
                    packageName = "",
                    appLabel = "",
                    appFilterText = "^Legacy Bank$",
                ),
            ),
            packageName = "hu.legacy.bank",
            appLabel = "Legacy Bank",
        )

        assertTrue(result.allowed)
        assertEquals("app_filter", result.reason)
        assertEquals("legacy-bank", result.profileId)
    }

    @Test
    fun acceptsLegacyPackageRegexOnlyWhenProfileHasNoPackageName() {
        val result = NotificationCaptureEligibility.evaluate(
            profiles = listOf(
                captureProfile(
                    id = "legacy-package",
                    packageName = "",
                    appLabel = "",
                    appFilterText = "legacy\\.bank",
                ),
            ),
            packageName = "hu.legacy.bank",
            appLabel = "Unexpected Label",
        )

        assertTrue(result.allowed)
        assertEquals("app_filter", result.reason)
        assertEquals("legacy-package", result.profileId)
    }

    @Test
    fun reportsDisabledProfileWhenOnlyProfileIsDisabled() {
        val result = NotificationCaptureEligibility.evaluate(
            profiles = listOf(
                captureProfile(
                    id = "bank-a",
                    enabled = false,
                    packageName = "hu.bank.a",
                    appLabel = "Bank A",
                    appFilterText = "^Bank A$",
                ),
            ),
            packageName = "hu.bank.a",
            appLabel = "Bank A",
        )

        assertFalse(result.allowed)
        assertEquals("profile_disabled", result.reason)
        assertEquals("bank-a", result.profileId)
    }

    @Test
    fun reportsDisabledProfileWhenOnlyMatchingProfileIsDisabled() {
        val result = NotificationCaptureEligibility.evaluate(
            profiles = listOf(
                captureProfile(
                    id = "erste",
                    enabled = false,
                    packageName = "hu.erste.bank",
                    appLabel = "Erste",
                    appFilterText = "^Erste$",
                ),
                captureProfile(
                    id = "revolut",
                    enabled = true,
                    packageName = "com.revolut.revolut",
                    appLabel = "Revolut",
                    appFilterText = "^Revolut$",
                ),
            ),
            packageName = "hu.erste.bank",
            appLabel = "Erste",
        )

        assertFalse(result.allowed)
        assertEquals("profile_disabled", result.reason)
        assertEquals("erste", result.profileId)
    }

    @Test
    fun disabledDifferentProfileDoesNotBlockEnabledProfile() {
        val result = NotificationCaptureEligibility.evaluate(
            profiles = listOf(
                captureProfile(
                    id = "erste",
                    enabled = false,
                    packageName = "hu.erste.bank",
                    appLabel = "Erste",
                    appFilterText = "^Erste$",
                ),
                captureProfile(
                    id = "revolut",
                    enabled = true,
                    packageName = "com.revolut.revolut",
                    appLabel = "Revolut",
                    appFilterText = "^Revolut$",
                ),
            ),
            packageName = "com.revolut.revolut",
            appLabel = "Revolut",
        )

        assertTrue(result.allowed)
        assertEquals("package", result.reason)
        assertEquals("revolut", result.profileId)
    }
}

private fun captureProfile(
    id: String,
    enabled: Boolean = true,
    packageName: String,
    appLabel: String,
    appFilterText: String,
): NotificationCaptureProfile = NotificationCaptureProfile(
    id = id,
    name = id,
    enabled = enabled,
    packageName = packageName,
    appLabel = appLabel,
    appFilterText = appFilterText,
)
