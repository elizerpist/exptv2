package com.fluvi.app.lockscreen

import android.Manifest
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.KeyguardManager
import android.app.UiAutomation
import android.content.ComponentName
import android.os.Build
import android.os.ParcelFileDescriptor
import android.os.PowerManager
import android.graphics.Bitmap
import java.io.File
import java.util.UUID
import android.os.SystemClock
import android.provider.Settings
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

/** Exercises the real service's owner action, without an injected surface or
 * any claim that a compositor showed pixels. Runs on a disposable device. */
@RunWith(AndroidJUnit4::class)
class KeyguardR446StockServiceInstrumentationTest {
    @Test fun actualStockWakeUsesOwnerPrintAndStops() {
        assertEquals(37, Build.VERSION.SDK_INT)
        val ins = InstrumentationRegistry.getInstrumentation()
        val context = ins.targetContext
        val ui = ins.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        fun shell(command: String) = ParcelFileDescriptor.AutoCloseInputStream(ui.executeShellCommand(command))
            .bufferedReader().use { it.readText() }
        fun secure(key: String, value: String?) {
            ui.adoptShellPermissionIdentity(Manifest.permission.WRITE_SECURE_SETTINGS)
            try { check(Settings.Secure.putString(context.contentResolver, key, value)) }
            finally { ui.dropShellPermissionIdentity() }
        }
        fun waitFor(label: String, condition: () -> Boolean) {
            val end = SystemClock.uptimeMillis() + 20_000
            while (SystemClock.uptimeMillis() < end) { if (condition()) return; SystemClock.sleep(50) }
            throw AssertionError("NOT REACHED: $label")
        }
        fun <T> main(block: () -> T): T {
            val answer = AtomicReference<T>()
            ins.runOnMainSync { answer.set(block()) }
            return answer.get()
        }
        fun start(owner: FluviKeyguardCardService): Map<String, Any?> {
            val done = CountDownLatch(1)
            val answer = AtomicReference<Map<String, Any?>>()
            val failure = AtomicReference<Throwable?>()
            ins.runOnMainSync {
                CoroutineScope(Dispatchers.Main.immediate).launch {
                    try { answer.set(owner.startR446PrintCapture("fixture", "debug", "LIGHT")) }
                    catch (error: Throwable) { failure.set(error) }
                    finally { done.countDown() }
                }
            }
            check(done.await(30, TimeUnit.SECONDS)) { "NOT REACHED: owner receipt" }
            failure.get()?.let { throw it }
            return checkNotNull(answer.get())
        }
        val uuid = UUID.fromString(requireNotNull(InstrumentationRegistry.getArguments().getString("runUuid")))
        val out = File(context.filesDir, "keyguard-service-probe/r43/$uuid").apply { check(mkdirs()) }
        val power = context.getSystemService(PowerManager::class.java)
        val savedLock = shell("locksettings get-disabled").trim()
        val savedServices = Settings.Secure.getString(context.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        val savedEnabled = Settings.Secure.getString(context.contentResolver, Settings.Secure.ACCESSIBILITY_ENABLED)
        val prefs = context.getSharedPreferences("fluvi_native_keyguard_card", android.content.Context.MODE_PRIVATE)
        val savedSettings = HashMap(prefs.all)
        val component = ComponentName(context, FluviKeyguardCardService::class.java)
        var owner: FluviKeyguardCardService? = null
        try {
            shell("input keyevent KEYCODE_WAKEUP")
            shell("wm dismiss-keyguard")
            val keyguard = context.getSystemService(KeyguardManager::class.java)
            waitFor("unlocked device") { !keyguard.isKeyguardLocked }
            main { FluviKeyguardCardSettings.update(context, mapOf("requested" to true,
                "showFinancialDetails" to true, "presentationMode" to "orb", "animationMode" to "orbOnly")) }
            val others = savedServices.orEmpty().split(':').filter {
                it.isNotBlank() && ComponentName.unflattenFromString(it) != component
            }
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, (others + component.flattenToString()).joinToString(":"))
            secure(Settings.Secure.ACCESSIBILITY_ENABLED, "1")
            waitFor("service connected") { FluviKeyguardCardServiceRegistry.connected }
            owner = checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation())
            val service = checkNotNull(owner)
            val receipt = start(service)
            assertEquals("service acknowledged print", true, receipt["printArmed"])
            assertEquals("fixedSampleOneWake", receipt["printPurpose"])
            assertTrue(KeyguardR44Trial.active)
            assertFalse(KeyguardR44Trial.settings(KeyguardCardSettings(showFinancialDetails = true)).showFinancialDetails)
            shell("locksettings set-disabled false")
            shell("input keyevent KEYCODE_SLEEP")
            waitFor("screen off") { !power.isInteractive }
            shell("input keyevent KEYCODE_WAKEUP")
            waitFor("interactive real SystemUI keyguard") { power.isInteractive && keyguard.isKeyguardLocked }
            SystemClock.sleep(1500)
            ui.takeScreenshot()?.let { shot ->
                File(out, "r446-stock-wake.png").outputStream().use { shot.compress(Bitmap.CompressFormat.PNG, 100, it) }
                shot.recycle()
            }
            val beforeStop = KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String
            File(out, "r446-stock-before-stop.txt").writeText(beforeStop)
            main { service.stopR444Trial("fixtureStop") }
            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
            File(out, "r446-stock-frozen.txt").writeText(report)
            assertTrue("NOT REACHED: actual stock wake sample observation\n$report", report.contains("R44_6_SAMPLE"))
            assertTrue("actual stock service did not submit its sample\n$report", report.contains("backend=SUBMITTED"))
            assertTrue("sample submission is not physical presentation", report.contains("physical=UNOBSERVED"))
        } finally {
            if (KeyguardCardDiagnostics.activeCaptureId() != null) KeyguardCardDiagnostics.clearCapture(context)
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, savedServices)
            secure(Settings.Secure.ACCESSIBILITY_ENABLED, savedEnabled)
            shell("input keyevent KEYCODE_WAKEUP")
            shell("wm dismiss-keyguard")
            if (savedLock.contains("true")) shell("locksettings set-disabled true")
            val edit = prefs.edit().clear()
            savedSettings.forEach { (key, value) -> when (value) {
                is Boolean -> edit.putBoolean(key, value); is Int -> edit.putInt(key, value)
                is Long -> edit.putLong(key, value); is Float -> edit.putFloat(key, value)
                is String -> edit.putString(key, value)
                is Set<*> -> edit.putStringSet(key, value.filterIsInstance<String>().toSet())
            } }
            check(edit.commit())
        }
    }
}
