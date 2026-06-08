package com.exptv2.app

import android.content.pm.ApplicationInfo

object InstalledAppFilter {
    private val allowedSystemPackages = setOf(
        "com.google.android.apps.walletnfcrel",
        "com.google.android.apps.nbu.paisa.user",
    )

    fun shouldShow(packageName: String, flags: Int): Boolean {
        if (packageName.isBlank()) return false
        val systemApp = flags and ApplicationInfo.FLAG_SYSTEM != 0
        return !systemApp || packageName in allowedSystemPackages
    }
}
