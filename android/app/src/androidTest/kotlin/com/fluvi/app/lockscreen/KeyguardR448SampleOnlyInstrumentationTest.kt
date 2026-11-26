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
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

/** Guard control for the sample-only build variant, not an optical privacy pass. */
@RunWith(AndroidJUnit4::class)
class KeyguardR448SampleOnlyInstrumentationTest {
    @Test fun normalPresentationIsClosedAndFixedSampleCanArm() {
        assertEquals(37, Build.VERSION.SDK_INT)
        val ins = InstrumentationRegistry.getInstrumentation()
        val context = ins.targetContext
        val ui = ins.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        fun shell(cmd: String) = ParcelFileDescriptor.AutoCloseInputStream(ui.executeShellCommand(cmd)).bufferedReader().use { it.readText() }
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
            val value = AtomicReference<T>()
            ins.runOnMainSync { value.set(block()) }
            return value.get()
        }
        val services = Settings.Secure.getString(context.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        val enabled = Settings.Secure.getString(context.contentResolver, Settings.Secure.ACCESSIBILITY_ENABLED)
        val prefs = context.getSharedPreferences("fluvi_native_keyguard_card", android.content.Context.MODE_PRIVATE)
        val saved = HashMap(prefs.all)
        val routePrefs = context.getSharedPreferences("fluvi_keyguard_r448_display_route", android.content.Context.MODE_PRIVATE)
        val routePresent = routePrefs.contains("route")
        val oldRoute = routePrefs.getString("route", null)
        val component = ComponentName(context, FluviKeyguardCardService::class.java)
        val savedLock = shell("locksettings get-disabled").trim()
        var service: FluviKeyguardCardService? = null
        try {
            assertTrue("NOT REACHED: sample-only variant resource", KeyguardR448Safety.sampleOnly(context))
            shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard")
            waitFor("unlocked setup") { !context.getSystemService(KeyguardManager::class.java).isKeyguardLocked }
            main { FluviKeyguardCardSettings.update(context, mapOf("requested" to true,
                "showFinancialDetails" to true, "presentationMode" to "orb", "animationMode" to "orbOnly")) }
            assertTrue(KeyguardR448DisplayRouteStore.write(context, KeyguardR448DisplayRoute.FLUVI_STREAM))
            val others = services.orEmpty().split(':').filter { it.isNotBlank() && ComponentName.unflattenFromString(it) != component }
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, (others + component.flattenToString()).joinToString(":"))
            secure(Settings.Secure.ACCESSIBILITY_ENABLED, "1")
            waitFor("real service") { FluviKeyguardCardServiceRegistry.connected }
            service = checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation())
            val owner = checkNotNull(service)
            assertEquals(Triple(true, false, false), main { owner.r448SafetyForInstrumentation() })
            val candidate = main {
                KeyguardR44Trial.set(true, true)
                val p = checkNotNull(KeyguardR44Trial.profile(null))
                KeyguardR44Trial.set(false, false)
                p
            }
            owner.onMaterialProfileChangedFromApplication(candidate)
            ins.waitForIdleSync()
            assertEquals("published material cannot enter normal service path", Triple(true, false, false),
                main { owner.r448SafetyForInstrumentation() })
            val done = CountDownLatch(1)
            val receipt = AtomicReference<Map<String, Any?>>()
            val failure = AtomicReference<Throwable?>()
            ins.runOnMainSync { CoroutineScope(Dispatchers.Main.immediate).launch {
                try { receipt.set(owner.startR446PrintCapture("r448-safe-test", "debug", "LIGHT")) }
                catch (error: Throwable) { failure.set(error) }
                finally { done.countDown() }
            } }
            assertTrue("NOT REACHED: sample arm completion", done.await(30, TimeUnit.SECONDS))
            failure.get()?.let { throw it }
            assertEquals("explicit fixed sample is armed", true, receipt.get()["printArmed"])
            assertTrue(main { owner.stopR444Trial("oneWakeComplete") })
            KeyguardCardDiagnostics.clearCapture(context)
            val sessionDone = CountDownLatch(1)
            val sessionReceipt = AtomicReference<Map<String, Any?>>()
            val sessionFailure = AtomicReference<Throwable?>()
            ins.runOnMainSync { CoroutineScope(Dispatchers.Main.immediate).launch {
                try { sessionReceipt.set(owner.startR449SampleCapture("r449-session-test", "debug", "LIGHT",
                    "SESSION", "FLUVI_STREAM")) }
                catch (error: Throwable) { sessionFailure.set(error) }
                finally { sessionDone.countDown() }
            } }
            assertTrue("NOT REACHED: explicit session arm", sessionDone.await(30, TimeUnit.SECONDS))
            sessionFailure.get()?.let { throw it }
            assertEquals("SESSION", sessionReceipt.get()["actionKind"])
            assertEquals("FLUVI_STREAM", sessionReceipt.get()["routeConfirmed"])
            assertEquals(true, sessionReceipt.get()["printArmed"])
            shell("locksettings set-disabled false")
            shell("input keyevent KEYCODE_SLEEP")
            waitFor("first session screen off") { !context.getSystemService(PowerManager::class.java).isInteractive }
            shell("input keyevent KEYCODE_WAKEUP")
            waitFor("first session locked wake") { context.getSystemService(KeyguardManager::class.java).isKeyguardLocked }
            shell("wm dismiss-keyguard")
            waitFor("session unlock") { !context.getSystemService(KeyguardManager::class.java).isKeyguardLocked }
            waitFor("session rearmed for a new wake") {
                val status = main { owner.r442SampleStatus() }
                status["actionKind"] == "SESSION" && status["printState"] == "WAIT_OFF" && status["printArmed"] == true
            }
        } finally {
            service?.let { owner -> runCatching { main { owner.stopR444Trial("safeTestCleanup") } } }
            KeyguardCardDiagnostics.clearCapture(context)
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, services)
            secure(Settings.Secure.ACCESSIBILITY_ENABLED, enabled)
            shell("locksettings set-disabled ${if (savedLock.contains("true")) "true" else "false"}")
            val routeEdit = routePrefs.edit()
            if (routePresent) routeEdit.putString("route", oldRoute) else routeEdit.remove("route")
            assertTrue(routeEdit.commit())
            val edit = prefs.edit().clear()
            saved.forEach { (key, value) -> when (value) {
                is Boolean -> edit.putBoolean(key, value); is Int -> edit.putInt(key, value)
                is Long -> edit.putLong(key, value); is Float -> edit.putFloat(key, value)
                is String -> edit.putString(key, value)
                is Set<*> -> edit.putStringSet(key, value.filterIsInstance<String>().toSet())
            } }
            assertTrue(edit.commit())
        }
    }
}
