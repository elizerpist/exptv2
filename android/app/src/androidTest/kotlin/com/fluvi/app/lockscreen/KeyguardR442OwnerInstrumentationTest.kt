package com.fluvi.app.lockscreen

import android.Manifest
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.KeyguardManager
import android.app.UiAutomation
import android.content.ComponentName
import android.os.Build
import android.os.ParcelFileDescriptor
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
class KeyguardR442OwnerInstrumentationTest {
    @Test fun serviceOwnsSampleCaptureReceiptAndInvalidatesIt() {
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
                    try { answer.set(owner.startR442SampleCapture("fixture", "debug", "LIGHT")) }
                    catch (error: Throwable) { failure.set(error) }
                    finally { done.countDown() }
                }
            }
            check(done.await(30, TimeUnit.SECONDS)) { "NOT REACHED: owner receipt" }
            failure.get()?.let { throw it }
            return checkNotNull(answer.get())
        }
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
            val originalFlags = main { checkNotNull(service.serviceInfo).flags }
            val receipt = start(service)
            assertEquals("armed", receipt["reason"])
            assertEquals(true, receipt["active"])
            assertEquals("fixedSample", receipt["materialDomain"])
            assertTrue(receipt["profile"] == "STANDARD" || receipt["profile"] == "STANDARD_ALREADY_INCLUDED")
            assertEquals(originalFlags and AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS != 0,
                receipt["includeNotImportant"])
            assertEquals(originalFlags, receipt["previousFlags"])
            assertEquals(originalFlags, receipt["actualFlags"])
            assertTrue(receipt["profileRevision"] is Long)
            assertEquals(KeyguardCardDiagnostics.activeCaptureId(), receipt["captureId"])
            assertEquals(receipt["captureId"], main { service.r442SampleStatus()["captureId"] })
            assertTrue(KeyguardR44Trial.active)
            assertNotNull(KeyguardR44Trial.profile(null))
            assertFalse(KeyguardR44Trial.settings(KeyguardCardSettings(showFinancialDetails = true)).showFinancialDetails)
            val duplicate = start(service)
            assertEquals("trialAlreadyActive", duplicate["reason"])
            assertEquals(true, main { service.r442SampleStatus()["active"] })

            // A different capture invalidates this receipt; it is not silently
            // re-associated with the new recording.
            KeyguardCardDiagnostics.startCapture(context, "other", "debug", "LIGHT")
            assertEquals(false, main { service.r442SampleStatus()["active"] })
            assertEquals("serviceOrCaptureChanged", main { service.r442SampleStatus()["reason"] })
            val restored = main { checkNotNull(service.serviceInfo).flags }
            val bit = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
            assertEquals(originalFlags and bit, restored and bit)
            assertFalse(KeyguardR44Trial.active)
            assertTrue(main { service.setR44SyntheticTrial(false) })
            val again = start(service)
            assertEquals(true, again["active"])
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, others.joinToString(":"))
            waitFor("service disconnected") { !FluviKeyguardCardServiceRegistry.connected }
            assertEquals(false, main { service.r442SampleStatus()["active"] })
            assertFalse(KeyguardR44Trial.active)
        } finally {
            if (KeyguardCardDiagnostics.activeCaptureId() != null) KeyguardCardDiagnostics.clearCapture(context)
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, savedServices)
            secure(Settings.Secure.ACCESSIBILITY_ENABLED, savedEnabled)
            shell("input keyevent KEYCODE_WAKEUP")
            shell("wm dismiss-keyguard")
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
