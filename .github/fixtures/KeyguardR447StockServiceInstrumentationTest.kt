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
import android.graphics.Color
import android.graphics.Rect
import com.fluvi.app.R
import kotlin.math.abs
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
        var calibration: KeyguardR22VisualCalibration? = null
        var underlay: Bitmap? = null
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
            val profile = main {
                KeyguardR44Trial.set(true, true)
                checkNotNull(KeyguardR44Trial.profile(null)).also { KeyguardR44Trial.set(false, false) }
            }
            calibration = KeyguardR22VisualCalibration(ins, out, ui, profile, discloseFull = false).also { it.calibrate() }
            val reference = checkNotNull(calibration)
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
            val settings = FluviKeyguardCardSettings.read(context)
            val metrics = context.resources.displayMetrics
            val geometry = resolveKeyguardOverlayGeometry(KeyguardUsableBounds(0, 0, metrics.widthPixels, metrics.heightPixels),
                metrics.density, context.resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_card_height),
                KeyguardCardPresentationMode.ORB, settings.cardPosition, settings.orbPosition, settings.verticalOffsetDp,
                context.resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_orb_size))
            val bounds = Rect(geometry.left, geometry.top, geometry.left + geometry.width, geometry.top + geometry.height)
            val waitEnd = SystemClock.uptimeMillis() + 15_000
            var armedWake: String? = null
            var selectedRow: String? = null
            var matching = 0
            var changed = 0
            var sampled = 0
            var underlayEnd = 0L
            val samples = StringBuilder("same-wake stock control; physical=UNOBSERVED bounds=$bounds\n")
            fun numeric(row: String, name: String) = Regex("(?:^| )$name=([0-9]+)(?: |$)")
                .find(row)?.groupValues?.get(1)?.toLongOrNull()
            while (SystemClock.uptimeMillis() < waitEnd) {
                val text = KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String
                val rows = text.lineSequence().filter { it.startsWith("R44_6_SAMPLE ") }.toList()
                if (armedWake == null) armedWake = rows.firstOrNull {
                    it.contains("armState=ARMED") || numeric(it, "arm") != null
                }?.let { Regex("(?:^| )wake=([0-9]+)").find(it)?.groupValues?.get(1) }
                selectedRow = rows.firstOrNull { armedWake != null && it.contains("wake=$armedWake ") }
                val row = selectedRow
                val start = SystemClock.uptimeMillis()
                val shot = ui.takeScreenshot()
                val end = SystemClock.uptimeMillis()
                if (shot != null) {
                    if (sampled < 20) File(out, "r447-stock-$sampled.png").outputStream().use {
                        shot.compress(Bitmap.CompressFormat.PNG, 100, it)
                    }
                    sampled++
                    val issue = row?.let { numeric(it, "issue") }
                    if (issue == null && underlay == null) {
                        underlay = shot.copy(Bitmap.Config.ARGB_8888, false)
                        underlayEnd = end
                    }
                    val before = underlay
                    if (issue != null && before != null && underlayEnd < issue && bounds.left >= 0 && bounds.top >= 0 &&
                        bounds.right <= shot.width && bounds.bottom <= shot.height &&
                        reference.a.width == bounds.width() && reference.a.height == bounds.height()) {
                        var count = 0; var differences = 0
                        for (y in 0 until bounds.height() step 2) for (x in 0 until bounds.width() step 2) {
                            val base = before.getPixel(bounds.left + x, bounds.top + y)
                            val actual = shot.getPixel(bounds.left + x, bounds.top + y)
                            fun delta(a: Int, b: Int) = maxOf(abs(Color.red(a) - Color.red(b)),
                                abs(Color.green(a) - Color.green(b)), abs(Color.blue(a) - Color.blue(b)))
                            val expected = listOf(reference.a.getPixel(x, y), reference.b.getPixel(x, y))
                            if (expected.any { delta(it, base) >= 20 && delta(it, actual) <= 8 }) count++
                            if (delta(actual, base) >= 20) differences++
                        }
                        matching = maxOf(matching, count); changed = maxOf(changed, differences)
                    }
                    samples.append("index=$sampled before=$start after=$end issue=$issue wake=$armedWake matching=$matching changed=$changed row=$row\n")
                    shot.recycle()
                }
                if (row != null && numeric(row, "frame") != null && matching >= 64 && changed >= 64) break
                if (row != null && numeric(row, "withdraw") != null) break
                SystemClock.sleep(150)
            }
            File(out, "r447-stock-samples.txt").writeText(samples.toString())
            ui.takeScreenshot()?.let { shot ->
                File(out, "r446-stock-wake.png").outputStream().use { shot.compress(Bitmap.CompressFormat.PNG, 100, it) }
                shot.recycle()
            }
            val beforeStop = KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String
            File(out, "r446-stock-before-stop.txt").writeText(beforeStop)
            main { service.stopR444Trial("fixtureStop") }
            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
            File(out, "r446-stock-frozen.txt").writeText(report)
            val row = checkNotNull(selectedRow) { "NOT REACHED: same armed wake sample observation\n$report" }
            assertTrue("stock wake did not issue a ticket\n$row", numeric(row, "issue") != null)
            assertTrue("stock wake did not submit its sample\n$row", numeric(row, "submit") != null)
            assertTrue("stock wake did not observe a shader draw\n$row", numeric(row, "frame") != null)
            assertNotNull("NOT REACHED: pre-submit same-wake background", underlay)
            assertTrue("NOT REACHED: background acquisition finished before issue", underlayEnd < checkNotNull(numeric(row, "issue")))
            assertTrue("no independently matching calibrated sample; matching=$matching changed=$changed\n$row",
                matching >= 64 && changed >= 64)
            assertTrue("sample submission is not physical presentation", row.contains("physical=UNOBSERVED"))
        } finally {
            underlay?.recycle()
            calibration?.close()
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
