package com.fluvi.app.lockscreen

import android.Manifest
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

/** Fixture-only scheduling barrier: the candidate service remains unchanged. */
@RunWith(AndroidJUnit4::class)
class KeyguardR442ReceiptRaceInstrumentationTest {
    @Test fun captureCreationRaceRejectsDoubleStartAndChangedMaterial() {
        assertEquals(37, Build.VERSION.SDK_INT)
        val ins = InstrumentationRegistry.getInstrumentation()
        val ctx = ins.targetContext
        val ui = ins.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        fun shell(cmd: String) = ParcelFileDescriptor.AutoCloseInputStream(ui.executeShellCommand(cmd))
            .bufferedReader().use { it.readText() }
        fun secure(key: String, value: String?) {
            ui.adoptShellPermissionIdentity(Manifest.permission.WRITE_SECURE_SETTINGS)
            try { check(Settings.Secure.putString(ctx.contentResolver, key, value)) }
            finally { ui.dropShellPermissionIdentity() }
        }
        fun waitFor(label: String, test: () -> Boolean) {
            val end = SystemClock.uptimeMillis() + 20_000
            while (SystemClock.uptimeMillis() < end) { if (test()) return; SystemClock.sleep(25) }
            throw AssertionError("NOT REACHED: $label")
        }
        fun <T> main(block: () -> T): T {
            val value = AtomicReference<T>()
            ins.runOnMainSync { value.set(block()) }
            return value.get()
        }
        fun asyncStart(service: FluviKeyguardCardService): Pair<CountDownLatch, AtomicReference<Map<String, Any?>>> {
            val done = CountDownLatch(1)
            val value = AtomicReference<Map<String, Any?>>()
            ins.runOnMainSync {
                CoroutineScope(Dispatchers.Main.immediate).launch {
                    try { value.set(service.startR442SampleCapture("race-fixture", "debug", "LIGHT")) }
                    finally { done.countDown() }
                }
            }
            return done to value
        }
        val originalServices = Settings.Secure.getString(ctx.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        val originalEnabled = Settings.Secure.getString(ctx.contentResolver, Settings.Secure.ACCESSIBILITY_ENABLED)
        val prefs = ctx.getSharedPreferences("fluvi_native_keyguard_card", android.content.Context.MODE_PRIVATE)
        val originalSettings = HashMap(prefs.all)
        val component = ComponentName(ctx, FluviKeyguardCardService::class.java)
        val entered = CountDownLatch(1)
        val release = CountDownLatch(1)
        try {
            shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard")
            waitFor("unlocked") { !ctx.getSystemService(KeyguardManager::class.java).isKeyguardLocked }
            main { FluviKeyguardCardSettings.update(ctx, mapOf("requested" to true,
                "showFinancialDetails" to true, "presentationMode" to "orb", "animationMode" to "orbOnly")) }
            val others = originalServices.orEmpty().split(':').filter {
                it.isNotBlank() && ComponentName.unflattenFromString(it) != component
            }
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, (others + component.flattenToString()).joinToString(":"))
            secure(Settings.Secure.ACCESSIBILITY_ENABLED, "1")
            waitFor("service connected") { FluviKeyguardCardServiceRegistry.connected }
            val service = checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation())
            val authority = main { service.inspectionStateForTest().authority }
            KeyguardCardDiagnostics.startCapture(ctx, "fixture-old", "debug", "LIGHT")
            val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(ctx, authority.serviceSession,
                authority.wakeGeneration, "fixture", SystemClock.uptimeMillis()))
            KeyguardCardDiagnostics.captureEventBatch(ctx, authority.serviceSession, authority.wakeGeneration,
                1, owner) {
                entered.countDown()
                check(release.await(15, TimeUnit.SECONDS)) { "NOT REACHED: release reducer" }
                emptyList()
            }
            assertTrue("NOT REACHED: capture reducer barrier", entered.await(5, TimeUnit.SECONDS))
            val first = asyncStart(service)
            waitFor("sample armed while capture waits") { KeyguardR44Trial.active }
            assertFalse("capture unexpectedly finished at barrier", first.first.await(200, TimeUnit.MILLISECONDS))
            val second = asyncStart(service)
            assertTrue("NOT REACHED: second start result", second.first.await(3, TimeUnit.SECONDS))
            assertEquals("startInProgress", second.second.get()["reason"])
            assertTrue(main { service.setR44SyntheticTrial(false) })
            release.countDown()
            assertTrue("NOT REACHED: first start completes", first.first.await(15, TimeUnit.SECONDS))
            assertEquals(false, first.second.get()["active"])
            assertEquals("serviceOrCaptureChanged", first.second.get()["reason"])
            assertEquals(false, main { service.r442SampleStatus()["active"] })
            assertFalse(KeyguardR44Trial.active)
        } finally {
            release.countDown()
            if (KeyguardCardDiagnostics.activeCaptureId() != null) KeyguardCardDiagnostics.clearCapture(ctx)
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, originalServices)
            secure(Settings.Secure.ACCESSIBILITY_ENABLED, originalEnabled)
            val edit = prefs.edit().clear()
            originalSettings.forEach { (key, value) -> when (value) {
                is Boolean -> edit.putBoolean(key, value); is Int -> edit.putInt(key, value)
                is Long -> edit.putLong(key, value); is Float -> edit.putFloat(key, value)
                is String -> edit.putString(key, value)
                is Set<*> -> edit.putStringSet(key, value.filterIsInstance<String>().toSet())
            } }
            check(edit.commit())
        }
    }
}
