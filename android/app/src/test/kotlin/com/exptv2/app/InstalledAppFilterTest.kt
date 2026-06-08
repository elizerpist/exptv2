package com.exptv2.app

import android.content.pm.ApplicationInfo
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class InstalledAppFilterTest {
    @Test
    fun includesUserInstalledApps() {
        assertTrue(
            InstalledAppFilter.shouldShow(
                packageName = "hu.bank.mobile",
                flags = 0,
            ),
        )
    }

    @Test
    fun excludesGenericAndroidSystemApps() {
        assertFalse(
            InstalledAppFilter.shouldShow(
                packageName = "com.android.cts.ctsshim",
                flags = ApplicationInfo.FLAG_SYSTEM,
            ),
        )
    }

    @Test
    fun includesGooglePaymentSystemApps() {
        assertTrue(
            InstalledAppFilter.shouldShow(
                packageName = "com.google.android.apps.walletnfcrel",
                flags = ApplicationInfo.FLAG_SYSTEM,
            ),
        )
        assertTrue(
            InstalledAppFilter.shouldShow(
                packageName = "com.google.android.apps.nbu.paisa.user",
                flags = ApplicationInfo.FLAG_SYSTEM,
            ),
        )
    }
}
