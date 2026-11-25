package com.fluvi.app.lockscreen

import android.Manifest
import android.app.KeyguardManager
import android.app.UiAutomation
import android.content.ComponentName
import android.graphics.Bitmap
import android.os.Build
import android.os.ParcelFileDescriptor
import android.os.PowerManager
import android.os.SystemClock
import android.provider.Settings
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import java.io.File
import java.util.UUID
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

/** Disposable AOSP emulator; screenshots are synthetic lab evidence only. */
@RunWith(AndroidJUnit4::class)
class KeyguardR43Api37LiveProbeTest {
    @Test fun timedHoldsRetainActualServiceEvidence() {
        assertEquals(37, Build.VERSION.SDK_INT)
        val ins = InstrumentationRegistry.getInstrumentation()
        val context = ins.targetContext
        val ui = ins.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        fun shell(command: String) = ParcelFileDescriptor.AutoCloseInputStream(ui.executeShellCommand(command)).bufferedReader().use { it.readText() }
        fun secure(key: String, value: String?) {
            ui.adoptShellPermissionIdentity(Manifest.permission.WRITE_SECURE_SETTINGS)
            try { check(Settings.Secure.putString(context.contentResolver, key, value)) }
            finally { ui.dropShellPermissionIdentity() }
        }
        fun await(label: String, condition: () -> Boolean) {
            val until = SystemClock.uptimeMillis() + 20_000
            while (SystemClock.uptimeMillis() < until) { if (condition()) return; SystemClock.sleep(50) }
            throw AssertionError("NOT REACHED: $label")
        }
        fun until(at: Long) { val remaining = at - SystemClock.uptimeMillis(); if (remaining > 0) SystemClock.sleep(remaining) }
        val uuid = UUID.fromString(requireNotNull(InstrumentationRegistry.getArguments().getString("runUuid"))).toString()
        val source = requireNotNull(InstrumentationRegistry.getArguments().getString("sourceSha"))
        val out = File(context.filesDir, "keyguard-service-probe/r43/$uuid").apply { check(mkdirs()) }
        val component = ComponentName(context, FluviKeyguardCardService::class.java)
        val savedServices = Settings.Secure.getString(context.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        val savedEnabled = Settings.Secure.getString(context.contentResolver, Settings.Secure.ACCESSIBILITY_ENABLED)
        val savedLock = shell("locksettings get-disabled").trim()
        val power = context.getSystemService(PowerManager::class.java)
        val keyguard = context.getSystemService(KeyguardManager::class.java)
        var capture = false; var pinSet = false
        fun screenshot(name: String) {
            val bitmap = ui.takeScreenshot() ?: return
            out.resolve("$name.png").outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
            bitmap.recycle()
            out.resolve("$name-window.txt").writeText(shell("dumpsys window windows"))
        }
        try {
            check(!keyguard.isDeviceSecure)
            shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard")
            await("unlocked setup") { power.isInteractive && !keyguard.isKeyguardLocked }
            shell("locksettings set-disabled false")
            shell("locksettings set-pin 2468"); pinSet = keyguard.isDeviceSecure
            assertTrue("NOT REACHED: disposable synthetic PIN setup", pinSet)
            ins.runOnMainSync { FluviKeyguardCardSettings.update(context, mapOf("requested" to true,
                "showFinancialDetails" to true, "presentationMode" to "orb", "animationMode" to "orbOnly")) }
            val others = savedServices.orEmpty().split(':').filter { it.isNotBlank() && ComponentName.unflattenFromString(it) != component }
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, (others + component.flattenToString()).joinToString(":"))
            secure(Settings.Secure.ACCESSIBILITY_ENABLED, "1")
            await("real service connected") { FluviKeyguardCardServiceRegistry.connected }
            KeyguardCardDiagnostics.startCapture(context, source, "debug", "LIGHT", true); capture = true
            ins.waitForIdleSync()
            shell("input keyevent KEYCODE_SLEEP")
            await("screen off and locked") { !power.isInteractive && keyguard.isKeyguardLocked }
            shell("input keyevent KEYCODE_WAKEUP")
            await("screen on and locked") { power.isInteractive && keyguard.isKeyguardLocked }
            val start = SystemClock.uptimeMillis()
            until(start + 5_000); screenshot("clock-1")
            // The orb occupies the centre bottom of the lock screen. Begin
            // outside it so the gesture reaches SystemUI, not Fluvi's panel.
            until(start + 6_000); shell("input swipe 200 2200 200 500 350")
            until(start + 11_000); screenshot("pin")
            until(start + 12_000); shell("input keyevent KEYCODE_BACK")
            until(start + 17_000); screenshot("clock-2")
            until(start + 18_000)
            shell("input swipe 180 12 180 1500 450")
            shell("input swipe 180 32 180 1800 450")
            out.resolve("shade-command.txt").writeText(shell("cmd statusbar expand-settings"))
            until(start + 23_000); screenshot("shade")
            until(start + 25_000)
            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String; capture = false
            out.resolve("frozen.txt").writeText(report)
            assertTrue(report.contains("R43_CAPTURE enabled=true"))
            listOf("CLOCK_1", "PIN", "CLOCK_2", "SHADE").forEach { label ->
                assertTrue("NOT REACHED: hold record $label", report.contains("hold=$label"))
            }
            assertTrue("effective report-id flag missing", report.contains("reportIds=true"))
            assertTrue("effective interactive-window flag missing", report.contains("retrieveWindows=true"))
            assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32_768)
        } finally {
            if (capture) runCatching { out.resolve("partial.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"] as String) }
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, savedServices)
            secure(Settings.Secure.ACCESSIBILITY_ENABLED, savedEnabled)
            if (pinSet) shell("locksettings clear --old 2468")
            shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard")
            if (savedLock == "true" || savedLock == "false") shell("locksettings set-disabled $savedLock")
        }
    }
}
