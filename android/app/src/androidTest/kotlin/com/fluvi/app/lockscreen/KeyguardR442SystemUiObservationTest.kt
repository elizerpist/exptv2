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
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

/** Observes actual AOSP SystemUI through the candidate service. This is not
 * an optical acceptance test and does not synthesize a positive tree. */
@RunWith(AndroidJUnit4::class)
class KeyguardR442SystemUiObservationTest {
    @Test fun actualSystemUiSampleClockAndRestrictionObservations() {
        assertEquals(37, Build.VERSION.SDK_INT)
        val ins = InstrumentationRegistry.getInstrumentation()
        val ctx = ins.targetContext
        val ui = ins.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        val power = ctx.getSystemService(PowerManager::class.java)
        val keyguard = ctx.getSystemService(KeyguardManager::class.java)
        val uuid = UUID.fromString(requireNotNull(InstrumentationRegistry.getArguments().getString("runUuid")))
        val out = File(ctx.filesDir, "keyguard-service-probe/r43/$uuid").apply { check(mkdirs()) }
        fun shell(cmd: String) = ParcelFileDescriptor.AutoCloseInputStream(ui.executeShellCommand(cmd))
            .bufferedReader().use { it.readText() }
        fun secure(key: String, value: String?) {
            ui.adoptShellPermissionIdentity(Manifest.permission.WRITE_SECURE_SETTINGS)
            try { check(Settings.Secure.putString(ctx.contentResolver, key, value)) }
            finally { ui.dropShellPermissionIdentity() }
        }
        fun waitFor(ms: Long = 20_000, condition: () -> Boolean): Boolean {
            val end = SystemClock.uptimeMillis() + ms
            while (SystemClock.uptimeMillis() < end) { if (condition()) return true; SystemClock.sleep(40) }
            return false
        }
        fun <T> main(block: () -> T): T {
            val answer = AtomicReference<T>()
            ins.runOnMainSync { answer.set(block()) }
            return answer.get()
        }
        fun screenshot(name: String) {
            ui.takeScreenshot()?.let { bitmap ->
                out.resolve("$name.png").outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
                bitmap.recycle()
            }
        }
        val savedServices = Settings.Secure.getString(ctx.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        val savedEnabled = Settings.Secure.getString(ctx.contentResolver, Settings.Secure.ACCESSIBILITY_ENABLED)
        val savedLock = shell("locksettings get-disabled").trim()
        val prefs = ctx.getSharedPreferences("fluvi_native_keyguard_card", android.content.Context.MODE_PRIVATE)
        val savedSettings = HashMap(prefs.all)
        val component = ComponentName(ctx, FluviKeyguardCardService::class.java)
        val entries = mutableListOf<String>()
        var owner: FluviKeyguardCardService? = null
        var pinSet = false
        var frozen = false
        try {
            check(!keyguard.isDeviceSecure)
            shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard")
            assertTrue("NOT REACHED: unlocked setup", waitFor { power.isInteractive && !keyguard.isKeyguardLocked })
            shell("locksettings set-disabled false")
            shell("locksettings set-pin 2468")
            pinSet = keyguard.isDeviceSecure
            assertTrue("NOT REACHED: disposable PIN", pinSet)
            main { FluviKeyguardCardSettings.update(ctx, mapOf("requested" to true,
                "showFinancialDetails" to true, "presentationMode" to "orb", "animationMode" to "orbOnly")) }
            val others = savedServices.orEmpty().split(':').filter {
                it.isNotBlank() && ComponentName.unflattenFromString(it) != component
            }
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, (others + component.flattenToString()).joinToString(":"))
            secure(Settings.Secure.ACCESSIBILITY_ENABLED, "1")
            assertTrue("NOT REACHED: service", waitFor { FluviKeyguardCardServiceRegistry.connected })
            owner = checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation())
            val service = checkNotNull(owner)
            service.inspectionProbeForTest = object : KeyguardInspectionProbeForTest {
                override fun readCompleted(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility,
                    reason: KeyguardSurfaceReason, rootUnavailable: Boolean, walkTruncated: Boolean,
                    abortedStale: Boolean, startedAt: Long, finishedAt: Long) {
                    synchronized(entries) { if (entries.size < 100) entries +=
                        "req=${request.id} wake=${request.wakeGeneration} decision=$decision reason=$reason unavailable=$rootUnavailable truncated=$walkTruncated stale=$abortedStale start=$startedAt end=$finishedAt" }
                }
            }
            val receipt = AtomicReference<Map<String, Any?>>()
            val done = CountDownLatch(1)
            ins.runOnMainSync { CoroutineScope(Dispatchers.Main.immediate).launch {
                try { receipt.set(service.startR442SampleCapture("systemui-observation", "debug", "LIGHT")) }
                finally { done.countDown() }
            } }
            assertTrue("NOT REACHED: sample start completed", done.await(30, TimeUnit.SECONDS))
            assertEquals("NOT REACHED: native sample receipt", true, receipt.get()["active"])
            assertEquals("fixedSample", receipt.get()["materialDomain"])
            shell("input keyevent KEYCODE_SLEEP")
            assertTrue("NOT REACHED: sleeping locked device", waitFor { !power.isInteractive && keyguard.isKeyguardLocked })
            shell("input keyevent KEYCODE_WAKEUP")
            assertTrue("NOT REACHED: actual clock wake", waitFor { power.isInteractive && keyguard.isKeyguardLocked })
            val readReached = waitFor(10_000) { synchronized(entries) { entries.isNotEmpty() } }
            screenshot("clock")
            val clockState = main { service.inspectionStateForTest() }
            val posts = service.surfaceMetricsForInstrumentation()?.submissions
            out.resolve("clock-state.txt").writeText("realSystemUi=true injected=false readReached=$readReached attached=${clockState.attached} posts=${posts ?: "UNOBSERVED"} optical=UNOBSERVED\n")

            // Retain the real scene commands and evidence even when the clock
            // did not authorize an ORB; those cases cannot pass W-HIDE.
            shell("input swipe 200 2000 200 500 350")
            val pinSeen = waitFor(8_000) { synchronized(entries) { entries.any { it.contains("CREDENTIAL") } } }
            screenshot("pin-attempt")
            shell("input keyevent KEYCODE_BACK")
            shell("input swipe 180 12 180 1500 450")
            shell("cmd statusbar expand-settings")
            val shadeSeen = waitFor(8_000) { synchronized(entries) { entries.any { it.contains("SHADE") } } }
            screenshot("shade-attempt")
            out.resolve("real-reads.txt").writeText(synchronized(entries) { entries.joinToString("\n", postfix = "\n") })
            out.resolve("scenes.txt").writeText("clockRead=$readReached pinDecision=$pinSeen shadeDecision=$shadeSeen opticalFirstPixel=UNOBSERVED firstForbiddenFrame=UNOBSERVED\n")
            val report = KeyguardCardDiagnostics.freezeCapture(ctx)["report"] as String
            frozen = true
            out.resolve("frozen.txt").writeText(report)
            assertTrue("NOT REACHED: actual first inspection", readReached)
            assertTrue("NOT REACHED: trial's first wake report", report.contains("R44_2_TRIAL requested=true"))
            assertTrue("NOT REACHED: synthetic trial classifier", report.contains("mode=syntheticTrial"))
            // Passing this observation does not pass W-SHOW or W-HIDE.
        } finally {
            owner?.inspectionProbeForTest = null
            if (!frozen && KeyguardCardDiagnostics.activeCaptureId() != null) runCatching {
                out.resolve("partial.txt").writeText(KeyguardCardDiagnostics.freezeCapture(ctx)["report"] as String)
            }
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, savedServices)
            secure(Settings.Secure.ACCESSIBILITY_ENABLED, savedEnabled)
            if (pinSet) shell("locksettings clear --old 2468")
            shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard")
            if (savedLock == "true" || savedLock == "false") shell("locksettings set-disabled $savedLock")
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
