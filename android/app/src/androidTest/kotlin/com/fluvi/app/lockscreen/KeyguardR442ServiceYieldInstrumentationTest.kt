package com.fluvi.app.lockscreen

import android.Manifest
import android.app.KeyguardManager
import android.app.UiAutomation
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Intent
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
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.atomic.AtomicReference
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

/** A fixture-controlled SCREEN_ON callback and a real service-owned reader.
 * This tests scheduling only; it supplies no surface classification. */
@RunWith(AndroidJUnit4::class)
class KeyguardR442ServiceYieldInstrumentationTest {
    @Test fun heldPreScreenReaderHandsOffToLatestPendingRequest() {
        assertEquals(37, Build.VERSION.SDK_INT)
        val ins = InstrumentationRegistry.getInstrumentation()
        val ctx = ins.targetContext
        val ui = ins.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        val power = ctx.getSystemService(PowerManager::class.java)
        val keyguard = ctx.getSystemService(KeyguardManager::class.java)
        val uuid = UUID.fromString(requireNotNull(InstrumentationRegistry.getArguments().getString("runUuid")))
        val out = File(ctx.filesDir, "keyguard-service-probe/r43/$uuid").apply { check(mkdirs()) }
        val lines = mutableListOf<String>()
        fun note(line: String) { synchronized(lines) { lines += line } }
        fun shell(cmd: String) = ParcelFileDescriptor.AutoCloseInputStream(ui.executeShellCommand(cmd))
            .bufferedReader().use { it.readText() }
        fun secure(key: String, value: String?) {
            ui.adoptShellPermissionIdentity(Manifest.permission.WRITE_SECURE_SETTINGS)
            try { check(Settings.Secure.putString(ctx.contentResolver, key, value)) }
            finally { ui.dropShellPermissionIdentity() }
        }
        fun waitFor(ms: Long = 20_000, test: () -> Boolean): Boolean {
            val end = SystemClock.uptimeMillis() + ms
            while (SystemClock.uptimeMillis() < end) { if (test()) return true; SystemClock.sleep(30) }
            return false
        }
        fun <T> main(block: () -> T): T {
            val result = AtomicReference<T>()
            ins.runOnMainSync { result.set(block()) }
            return result.get()
        }
        val savedServices = Settings.Secure.getString(ctx.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        val savedEnabled = Settings.Secure.getString(ctx.contentResolver, Settings.Secure.ACCESSIBILITY_ENABLED)
        val savedLock = shell("locksettings get-disabled").trim()
        val prefs = ctx.getSharedPreferences("fluvi_native_keyguard_card", android.content.Context.MODE_PRIVATE)
        val savedSettings = HashMap(prefs.all)
        val component = ComponentName(ctx, FluviKeyguardCardService::class.java)
        val oldObserver = KeyguardR15AcquisitionTestHooks.observer
        val oldChild = KeyguardR15AcquisitionTestHooks.beforeChildCall
        val oldIneligible = KeyguardR15AcquisitionTestHooks.observeIneligible
        val held = CountDownLatch(1)
        val release = CountDownLatch(1)
        val yielded = CountDownLatch(1)
        val oldId = AtomicLong(-1)
        val offeredId = AtomicLong(-1)
        val claimedId = AtomicLong(-1)
        val gateUsed = AtomicBoolean(false)
        var service: FluviKeyguardCardService? = null
        var pinSet = false
        try {
            check(!keyguard.isDeviceSecure)
            shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard")
            assertTrue("NOT REACHED: unlocked", waitFor { power.isInteractive && !keyguard.isKeyguardLocked })
            shell("locksettings set-disabled false"); shell("locksettings set-pin 2468")
            pinSet = keyguard.isDeviceSecure
            assertTrue("NOT REACHED: disposable PIN", pinSet)
            main { FluviKeyguardCardSettings.update(ctx, mapOf("requested" to true,
                "showFinancialDetails" to false, "presentationMode" to "orb", "animationMode" to "orbOnly")) }
            val others = savedServices.orEmpty().split(':').filter {
                it.isNotBlank() && ComponentName.unflattenFromString(it) != component
            }
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, (others + component.flattenToString()).joinToString(":"))
            secure(Settings.Secure.ACCESSIBILITY_ENABLED, "1")
            assertTrue("NOT REACHED: connected service", waitFor { FluviKeyguardCardServiceRegistry.connected })
            service = checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation())
            val owner = checkNotNull(service)
            assertTrue("NOT REACHED: sample preparation", main { owner.setR44SyntheticTrial(true) })
            KeyguardCardDiagnostics.startCapture(ctx, "r442-yield-fixture", "debug", "LIGHT")
            shell("input keyevent KEYCODE_SLEEP")
            assertTrue("NOT REACHED: screen off", waitFor { !power.isInteractive && keyguard.isKeyguardLocked })
            shell("input keyevent KEYCODE_WAKEUP")
            assertTrue("NOT REACHED: clock wake", waitFor { power.isInteractive && keyguard.isKeyguardLocked })
            assertTrue("NOT REACHED: cycle established", waitFor { main { owner.inspectionStateForTest().wake != null } })
            KeyguardR15AcquisitionTestHooks.observeIneligible = true
            KeyguardR15AcquisitionTestHooks.observer = { }
            KeyguardR15AcquisitionTestHooks.beforeChildCall = { request, window, index ->
                if (request.id == oldId.get() && gateUsed.compareAndSet(false, true)) {
                    note("old=${request.id} child=$window/$index held=${SystemClock.uptimeMillis()}")
                    held.countDown()
                    if (!release.await(20, TimeUnit.SECONDS)) note("HOLD_TIMEOUT")
                }
            }
            owner.inspectionProbeForTest = object : KeyguardInspectionProbeForTest {
                override fun queueOffered(request: KeyguardCardInspectionRequest, previous: KeyguardCardInspectionRequest?,
                                          pending: KeyguardCardInspectionRequest?, startsWorker: Boolean) {
                    if (request.trigger == "r442-fixture-old") oldId.set(request.id)
                    if (request.trigger == "r442-fixture-new") offeredId.set(pending?.id ?: -1)
                    note("offered=${request.id} trigger=${request.trigger} pending=${pending?.id ?: -1}")
                }
                override fun r37BoundaryClaimed(original: KeyguardCardInspectionRequest, successor: KeyguardCardInspectionRequest,
                                                boundary: String, at: Long) {
                    if (original.id == oldId.get()) {
                        claimedId.set(successor.id)
                        note("claimed=${successor.id} boundary=$boundary at=$at")
                    }
                }
                override fun yielded(original: KeyguardCardInspectionRequest, successor: KeyguardCardInspectionRequest,
                                     startedAt: Long, finishedAt: Long, visited: Int) {
                    if (original.id == oldId.get()) { note("yielded=${successor.id} oldEnd=$finishedAt visited=$visited"); yielded.countDown() }
                }
                override fun readCompleted(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility,
                    reason: KeyguardSurfaceReason, rootUnavailable: Boolean, walkTruncated: Boolean,
                    abortedStale: Boolean, startedAt: Long, finishedAt: Long) {
                    note("read=${request.id} decision=$decision reason=$reason unavailable=$rootUnavailable truncated=$walkTruncated stale=$abortedStale")
                }
            }
            val schedule = FluviKeyguardCardService::class.java.getDeclaredMethod("scheduleEvaluation", String::class.java,
                java.lang.Long::class.java, java.lang.Long::class.java, KeyguardWindowFreshness::class.java,
                KeyguardCardInspectionRequest::class.java).apply { isAccessible = true }
            main { schedule.invoke(owner, "r442-fixture-old", null, SystemClock.uptimeMillis(),
                KeyguardWindowFreshness.FRAMEWORK_EVENT, null) }
            assertTrue("NOT REACHED: old real tree and first child", held.await(15, TimeUnit.SECONDS))
            val before = main { owner.inspectionStateForTest().authority }
            main {
                val field = FluviKeyguardCardService::class.java.getDeclaredField("screenReceiver").apply { isAccessible = true }
                (field.get(owner) as BroadcastReceiver).onReceive(owner, Intent(Intent.ACTION_SCREEN_ON))
                schedule.invoke(owner, "r442-fixture-new", null, SystemClock.uptimeMillis(),
                    KeyguardWindowFreshness.FRAMEWORK_EVENT, null)
            }
            val after = main { owner.inspectionStateForTest().authority }
            assertEquals("NOT REACHED: same wake authority", before, after)
            assertTrue("NOT REACHED: newer actual queue offer", offeredId.get() > oldId.get())
            release.countDown()
            assertTrue("NOT REACHED: clean eligible reader boundary; see retained observations", yielded.await(15, TimeUnit.SECONDS))
            assertTrue("newer exact request was not claimed", claimedId.get() >= offeredId.get())
            note("result=PASS syntheticScreenCallback=true physicalTiming=UNOBSERVED")
        } finally {
            release.countDown()
            service?.inspectionProbeForTest = null
            KeyguardR15AcquisitionTestHooks.observer = oldObserver
            KeyguardR15AcquisitionTestHooks.beforeChildCall = oldChild
            KeyguardR15AcquisitionTestHooks.observeIneligible = oldIneligible
            if (KeyguardCardDiagnostics.activeCaptureId() != null) runCatching {
                out.resolve("capture.txt").writeText(KeyguardCardDiagnostics.freezeCapture(ctx)["report"] as String)
            }
            out.resolve("yield-observations.txt").writeText(synchronized(lines) { lines.joinToString("\n", postfix = "\n") })
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
