package com.fluvi.app.lockscreen

import android.Manifest
import android.app.KeyguardManager
import android.app.UiAutomation
import android.content.ComponentName
import android.os.Build
import android.os.ParcelFileDescriptor
import android.os.PowerManager
import android.os.SystemClock
import android.provider.Settings
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import java.io.File
import java.util.UUID
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/** Ordinary real-service observation; no fabricated MAIN or renderer signal. */
@RunWith(AndroidJUnit4::class)
class KeyguardR43Api37BaselineTest {
    @Test fun ordinaryFirstAndLaterWake() {
        assertEquals(37, Build.VERSION.SDK_INT)
        val ins = InstrumentationRegistry.getInstrumentation()
        val context = ins.targetContext
        val automation = ins.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        fun shell(command: String) = ParcelFileDescriptor.AutoCloseInputStream(automation.executeShellCommand(command)).bufferedReader().use { it.readText() }
        fun secure(key: String, value: String?) {
            automation.adoptShellPermissionIdentity(Manifest.permission.WRITE_SECURE_SETTINGS)
            try { check(Settings.Secure.putString(context.contentResolver, key, value)) }
            finally { automation.dropShellPermissionIdentity() }
        }
        fun await(label: String, predicate: () -> Boolean) {
            val end = SystemClock.uptimeMillis() + 20_000
            while (SystemClock.uptimeMillis() < end) { if (predicate()) return; SystemClock.sleep(50) }
            throw AssertionError("NOT REACHED: $label")
        }
        val uuid = UUID.fromString(requireNotNull(InstrumentationRegistry.getArguments().getString("runUuid"))).toString()
        val source = requireNotNull(InstrumentationRegistry.getArguments().getString("sourceSha"))
        val out = File(context.filesDir, "keyguard-service-probe/r43/$uuid").apply { check(mkdirs()) }
        val component = ComponentName(context, FluviKeyguardCardService::class.java)
        val savedServices = Settings.Secure.getString(context.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        val savedEnabled = Settings.Secure.getString(context.contentResolver, Settings.Secure.ACCESSIBILITY_ENABLED)
        val savedLock = shell("locksettings get-disabled").trim()
        val power = context.getSystemService(PowerManager::class.java)
        val keyguard = context.getSystemService(KeyguardManager::class.java)
        var capture = false
        try {
            check(!keyguard.isDeviceSecure)
            shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard")
            await("unlocked") { power.isInteractive && !keyguard.isKeyguardLocked }
            shell("locksettings set-disabled false")
            ins.runOnMainSync {
                FluviKeyguardCardSettings.update(context, mapOf("requested" to true, "showFinancialDetails" to true,
                    "presentationMode" to "orb", "animationMode" to "orbOnly"))
            }
            val others = savedServices.orEmpty().split(':').filter { it.isNotBlank() && ComponentName.unflattenFromString(it) != component }
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, (others + component.flattenToString()).joinToString(":"))
            secure(Settings.Secure.ACCESSIBILITY_ENABLED, "1")
            await("real service connected") { FluviKeyguardCardServiceRegistry.connected }
            KeyguardCardDiagnostics.startCapture(context, source, "debug", "LIGHT"); capture = true
            repeat(2) { index ->
                shell("input keyevent KEYCODE_SLEEP")
                await("screen off and locked") { !power.isInteractive && keyguard.isKeyguardLocked }
                shell("input keyevent KEYCODE_WAKEUP")
                await("screen on and locked") { power.isInteractive && keyguard.isKeyguardLocked }
                // Explicitly held lab scene; not part of application scheduling.
                SystemClock.sleep(5_000)
                out.resolve("wake-${index + 1}.txt").writeText(KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String)
            }
            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String; capture = false
            out.resolve("frozen.txt").writeText(report)
            out.resolve("device.txt").writeText("api=${Build.VERSION.SDK_INT} id=${Build.ID} fingerprint=${Build.FINGERPRINT}\n")
            assertTrue(report.contains("FLUVI_KEYGUARD_TIMING_CAPTURE_V1"))
        } finally {
            if (capture) runCatching { out.resolve("partial.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"] as String) }
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, savedServices)
            secure(Settings.Secure.ACCESSIBILITY_ENABLED, savedEnabled)
            shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard")
            if (savedLock == "true" || savedLock == "false") shell("locksettings set-disabled $savedLock")
        }
    }
}
