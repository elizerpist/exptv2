package com.fluvi.app.lockscreen

import android.Manifest
import android.app.Dialog
import android.app.KeyguardManager
import android.app.UiAutomation
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.graphics.Bitmap
import android.os.Build
import android.os.ParcelFileDescriptor
import android.os.PowerManager
import android.os.SystemClock
import android.provider.Settings
import android.view.Display
import android.view.accessibility.AccessibilityEvent
import android.widget.TextView
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.fluvi.app.MainActivity
import com.fluvi.app.lockscreen.material.FluviKeyguardMaterialStore
import java.io.File
import java.util.Collections
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

/** Separates a real app-dialog event shape from the natural system-clock case.
 * Neither case fabricates AccessibilityEvent metadata or classifier results. */
@RunWith(AndroidJUnit4::class)
class KeyguardR39RealWindowInstrumentationTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val context = instrumentation.targetContext
    private fun shell(automation: UiAutomation, command: String): String =
        ParcelFileDescriptor.AutoCloseInputStream(automation.executeShellCommand(command)).bufferedReader().use { it.readText() }
    private fun await(label: String, timeout: Long = 20_000, condition: () -> Boolean) {
        val end = SystemClock.uptimeMillis() + timeout
        while (SystemClock.uptimeMillis() < end) { if (condition()) return; SystemClock.sleep(50) }
        throw AssertionError("NOT REACHED: $label")
    }
    private fun directory(label: String): File {
        val args = InstrumentationRegistry.getArguments()
        val uuid = UUID.fromString(requireNotNull(args.getString("runUuid"))).toString()
        return File(context.filesDir, "keyguard-service-probe/r39/$uuid/$label").also { check(it.mkdirs()) }
    }

    @Test fun frameworkReportsAnActualDialogWindowRemoval() {
        assertEquals(35, Build.VERSION.SDK_INT)
        val dir = directory("event-shape")
        val ui = instrumentation.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        val events = Collections.synchronizedList(mutableListOf<String>())
        data class Sample(val id: Int, val display: Int, val changes: Int, val at: Long)
        val samples = Collections.synchronizedList(mutableListOf<Sample>())
        var dialog: Dialog? = null
        var activity: android.app.Activity? = null
        try {
            ui.serviceInfo = ui.serviceInfo.apply {
                flags = flags or AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
                eventTypes = eventTypes or AccessibilityEvent.TYPE_WINDOWS_CHANGED
            }
            ui.setOnAccessibilityEventListener { event ->
                if (event.eventType == AccessibilityEvent.TYPE_WINDOWS_CHANGED) {
                    val s = Sample(event.windowId, event.displayId, event.windowChanges, event.eventTime)
                    samples.add(s); events.add("WINDOW id=${s.id} display=${s.display} changes=${s.changes} eventAt=${s.at}")
                }
            }
            activity = instrumentation.startActivitySync(Intent(context, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            val current = checkNotNull(activity)
            instrumentation.waitForIdleSync()
            val beforeIds = ui.windows.map { it.id }.toSet()
            events.add("BEFORE windows=" + ui.windows.joinToString { "${it.id}:${it.type}:${it.title}" })
            instrumentation.runOnMainSync {
                dialog = Dialog(current).apply {
                    setContentView(TextView(current).apply { text = "R39 event fixture"; setTextColor(Color.WHITE) })
                    window?.setTitle("FluviR39IndependentWindow")
                    show()
                }
            }
            var windowId = -1
            await("independent app dialog appears in framework window inventory") {
                val windows = ui.windows
                val matching = windows.filter { it.id !in beforeIds &&
                    it.type == android.view.accessibility.AccessibilityWindowInfo.TYPE_APPLICATION &&
                    it.root?.packageName?.toString() == context.packageName }
                if (matching.size == 1) { windowId = matching.single().id; true } else false
            }
            events.add("AFTER windows=" + ui.windows.joinToString { "${it.id}:${it.type}:${it.title}" })
            val observedId = windowId
            await("framework ADDED for exact test dialog") {
                synchronized(samples) { samples.any { it.id == observedId && it.display == Display.DEFAULT_DISPLAY &&
                    it.changes and AccessibilityEvent.WINDOWS_CHANGE_ADDED != 0 } }
            }
            val before = SystemClock.uptimeMillis()
            instrumentation.runOnMainSync { checkNotNull(dialog).dismiss() }
            await("framework REMOVED for exact test dialog") {
                synchronized(samples) { samples.any { it.id == observedId && it.display == Display.DEFAULT_DISPLAY &&
                    it.changes and AccessibilityEvent.WINDOWS_CHANGE_REMOVED != 0 && it.at >= before } }
            }
            events.add("PASS real framework app-dialog removal id=$observedId; NOT a SystemUI clock witness")
        } finally {
            runCatching { instrumentation.runOnMainSync { dialog?.dismiss(); activity?.finish() } }
            ui.setOnAccessibilityEventListener(null)
            File(dir, "events.txt").writeText(synchronized(events) { events.joinToString("\n", postfix = "\n") })
        }
    }

    @Test fun visibleSystemClockRemovalSealsBeforeHeldInspection() {
        assertEquals(35, Build.VERSION.SDK_INT)
        val dir = directory("natural-unlock")
        val args = InstrumentationRegistry.getArguments()
        val source = requireNotNull(args.getString("sourceSha"))
        val ui = instrumentation.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        fun secure(key: String, value: String?) {
            ui.adoptShellPermissionIdentity(Manifest.permission.WRITE_SECURE_SETTINGS)
            try { check(Settings.Secure.putString(context.contentResolver, key, value)) }
            finally { ui.dropShellPermissionIdentity() }
        }
        fun save(name: String) = context.getSharedPreferences(name, Context.MODE_PRIVATE).let { it to HashMap(it.all) }
        fun restore(saved: Pair<SharedPreferences, Map<String, *>>) {
            val e = saved.first.edit().clear()
            saved.second.forEach { (key, value) -> when (value) {
                is Boolean -> e.putBoolean(key, value); is Int -> e.putInt(key, value); is Long -> e.putLong(key, value)
                is Float -> e.putFloat(key, value); is String -> e.putString(key, value)
                is Set<*> -> e.putStringSet(key, value.filterIsInstance<String>().toSet())
            } }
            check(e.commit())
        }
        val savedServices = Settings.Secure.getString(context.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        val savedEnabled = Settings.Secure.getString(context.contentResolver, Settings.Secure.ACCESSIBILITY_ENABLED)
        val lockDisabled = shell(ui, "locksettings get-disabled").trim()
        val prefs = listOf(save("fluvi_native_keyguard_card"), save("fluvi_keyguard_header_material"), save("fluvi_keyguard_orb_diagnostic_route"))
        val component = ComponentName(context, FluviKeyguardCardService::class.java)
        val others = savedServices.orEmpty().split(':').filter { it.isNotBlank() && ComponentName.unflattenFromString(it) != component }.joinToString(":")
        val keyguard = context.getSystemService(KeyguardManager::class.java)
        val power = context.getSystemService(PowerManager::class.java)
        val events = Collections.synchronizedList(mutableListOf<String>())
        val release = CountDownLatch(1); val held = CountDownLatch(1); val arm = AtomicBoolean(false); val once = AtomicBoolean(false)
        var service: FluviKeyguardCardService? = null
        var capture = false
        var report = ""
        var failure: Throwable? = null
        try {
            check(!FluviKeyguardCardServiceRegistry.connected && !keyguard.isDeviceSecure)
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, others)
            shell(ui, "input keyevent KEYCODE_WAKEUP"); shell(ui, "wm dismiss-keyguard")
            await("unlocked fixture") { power.isInteractive && !keyguard.isKeyguardLocked }
            shell(ui, "locksettings set-disabled false")
            check(context.getSharedPreferences("fluvi_keyguard_orb_diagnostic_route", Context.MODE_PRIVATE).edit().putString("mode", "SURFACE_LIVE").commit())
            instrumentation.runOnMainSync {
                FluviKeyguardCardSettings.update(context, mapOf("requested" to true, "showFinancialDetails" to true,
                    "presentationMode" to "orb", "animationMode" to "orbOnly"))
                val epoch = maxOf(SystemClock.elapsedRealtimeNanos(), (prefs[1].second["publisherEpoch"] as? Long ?: -1L) + 1)
                check(FluviKeyguardMaterialStore.publish(context, KeyguardR12ServiceTimingInstrumentationTest().materialProfile(), epoch))
            }
            KeyguardCardDiagnostics.startCapture(context, source, "debug", "LIGHT"); capture = true
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, listOf(others, component.flattenToString()).filter(String::isNotBlank).joinToString(":"))
            secure(Settings.Secure.ACCESSIBILITY_ENABLED, "1")
            await("real service connected") { FluviKeyguardCardServiceRegistry.connected }
            service = checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation())
            val actual = checkNotNull(service)
            instrumentation.runOnMainSync {
                actual.inspectionProbeForTest = object : KeyguardInspectionProbeForTest {
                    override fun ingress(meta: KeyguardAccessibilityEventMeta, receivedAt: Long,
                                         action: KeyguardEventAction, frameworkEvent: Boolean) {
                        if (frameworkEvent && meta.eventType == AccessibilityEvent.TYPE_WINDOWS_CHANGED)
                            events.add("FRAMEWORK id=${meta.windowId} display=${meta.displayId} changes=${meta.windowChanges} eventAt=${meta.eventTimeUptimeMs} callback=$receivedAt action=$action")
                    }
                    override fun started(request: KeyguardCardInspectionRequest) {
                        if (arm.get() && once.compareAndSet(false, true)) {
                            events.add("HELD_READ request=${request.id} at=${SystemClock.uptimeMillis()}")
                            held.countDown(); release.await(15, TimeUnit.SECONDS)
                        }
                    }
                }
            }
            // Preflight may leave the fixture Activity above the lockscreen.
            // Move it home without changing any privacy or visibility policy.
            shell(ui, "input keyevent KEYCODE_HOME")
            SystemClock.sleep(2000)
            shell(ui, "input keyevent KEYCODE_SLEEP")
            await("dark locked fixture") { !power.isInteractive && keyguard.isKeyguardLocked }
            shell(ui, "input keyevent KEYCODE_WAKEUP")
            await("current FULL direct output and uniquely attributable system clock", 35_000) {
                report = KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String
                report.lineSequence().any { it.startsWith(" R26_DIRECT ") &&
                    it.contains("witness=ARMED/") && !it.contains("reveal=UNOBSERVED/") }
            }
            File(dir, "before.txt").writeText(report)
            runCatching { ui.takeScreenshot()?.let { File(dir, "before.png").outputStream().use { out -> it.compress(Bitmap.CompressFormat.PNG, 100, out) }; it.recycle() } }
            arm.set(true)
            events.add("UNLOCK_REQUEST at=${SystemClock.uptimeMillis()}")
            shell(ui, "wm dismiss-keyguard")
            assertTrue("NOT REACHED: a subsequent inspection could not be held", held.await(12, TimeUnit.SECONDS))
            await("real exact clock removal sealed before held inspection", 12_000) {
                report = KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String
                report.lineSequence().any { it.startsWith(" R26_DIRECT ") && it.contains("SEALED:r40ClockWindowRemoved") &&
                    it.contains("removal=1/") }
            }
            events.add("PASS exact framework clock removal sealed with ordinary read held")
            release.countDown()
            runCatching { ui.takeScreenshot()?.let { File(dir, "after.png").outputStream().use { out -> it.compress(Bitmap.CompressFormat.PNG, 100, out) }; it.recycle() } }
        } catch (t: Throwable) { failure = t; events.add("FAIL_OR_NOT_REACHED ${t.javaClass.simpleName}:${t.message}") }
        finally {
            release.countDown()
            runCatching { instrumentation.runOnMainSync { service?.inspectionProbeForTest = null } }
            if (capture) runCatching { report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String }
            File(dir, "capture.txt").writeText(report)
            runCatching {
                secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, others)
                await("service disconnected") { !FluviKeyguardCardServiceRegistry.connected }
                prefs.forEach(::restore); shell(ui, "input keyevent KEYCODE_WAKEUP"); shell(ui, "wm dismiss-keyguard")
                shell(ui, "locksettings set-disabled $lockDisabled")
                secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, savedServices); secure(Settings.Secure.ACCESSIBILITY_ENABLED, savedEnabled)
            }.onFailure { if (failure == null) failure = it else events.add("CLEANUP_FAIL ${it.message}") }
            File(dir, "events.txt").writeText(synchronized(events) { events.joinToString("\n", postfix = "\n") })
            File(dir, "result.txt").writeText("source=$source verdict=${if (failure == null) "PASS" else "FAIL_OR_NOT_REACHED"} physical=UNOBSERVED\n")
        }
        failure?.let { throw it }
    }
}
