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
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityWindowInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import java.io.File
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.atomic.AtomicReference
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

/** The real service, system reader, classifier and presenter. The controlled
 * topology is explicitly a subset of the actual inventory; it is not a stock
 * privacy assertion and does not synthesize a MAIN result or a target window. */
@RunWith(AndroidJUnit4::class)
class KeyguardR447HandoffServiceInstrumentationTest {
    @Test fun internalDuplicateAfterPhysicalReadIssuesOnce() = exercise(false)
    @Test fun sameHostExternalIngressRejectsOldRead() = exercise(true)
    @Test fun selectedWidgetsAnywhereUsesIndependentSampleFrame() = exercise(false, true)

    private fun exercise(external: Boolean, widgetsAnywhere: Boolean = false) {
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
        fun waitFor(label: String, test: () -> Boolean) {
            val until = SystemClock.uptimeMillis() + 20_000
            while (SystemClock.uptimeMillis() < until) {
                if (test()) return
                SystemClock.sleep(50)
            }
            throw AssertionError("NOT REACHED: $label")
        }
        fun <T> main(block: () -> T): T {
            val result = AtomicReference<T>()
            ins.runOnMainSync { result.set(block()) }
            return result.get()
        }
        fun start(owner: FluviKeyguardCardService): Map<String, Any?> {
            val done = CountDownLatch(1)
            val result = AtomicReference<Map<String, Any?>>()
            val failure = AtomicReference<Throwable?>()
            ins.runOnMainSync { CoroutineScope(Dispatchers.Main.immediate).launch {
                try { result.set(owner.startR446PrintCapture("r447-fixture", "debug", "FULL")) }
                catch (error: Throwable) { failure.set(error) }
                finally { done.countDown() }
            } }
            check(done.await(30, TimeUnit.SECONDS)) { "NOT REACHED: arm receipt" }
            failure.get()?.let { throw it }
            return checkNotNull(result.get())
        }
        val uuid = UUID.fromString(requireNotNull(InstrumentationRegistry.getArguments().getString("runUuid")))
        val out = File(context.filesDir, "keyguard-service-probe/r43/$uuid").apply { check(mkdirs()) }
        val power = context.getSystemService(PowerManager::class.java)
        val keyguard = context.getSystemService(KeyguardManager::class.java)
        val savedLock = shell("locksettings get-disabled").trim()
        val savedServices = Settings.Secure.getString(context.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        val savedEnabled = Settings.Secure.getString(context.contentResolver, Settings.Secure.ACCESSIBILITY_ENABLED)
        val prefs = context.getSharedPreferences("fluvi_native_keyguard_card", android.content.Context.MODE_PRIVATE)
        val savedSettings = HashMap(prefs.all)
        val component = ComponentName(context, FluviKeyguardCardService::class.java)
        val acquired = CountDownLatch(1)
        val release = CountDownLatch(1)
        val first = AtomicLong(0)
        val host = AtomicInteger(-1)
        val offered = AtomicLong(0)
        val invocations = mutableListOf<Long>()
        val note = StringBuilder("controlled=subset-of-real-inventory stock=false external=$external widgetsAnywhere=$widgetsAnywhere physical=UNOBSERVED\n")
        var service: FluviKeyguardCardService? = null
        try {
            shell("input keyevent KEYCODE_WAKEUP")
            shell("wm dismiss-keyguard")
            waitFor("unlocked setup") { !keyguard.isKeyguardLocked }
            main { FluviKeyguardCardSettings.update(context, mapOf("requested" to true,
                "showFinancialDetails" to true, "presentationMode" to "orb", "animationMode" to "orbOnly")) }
            val others = savedServices.orEmpty().split(':').filter {
                it.isNotBlank() && ComponentName.unflattenFromString(it) != component
            }
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, (others + component.flattenToString()).joinToString(":"))
            secure(Settings.Secure.ACCESSIBILITY_ENABLED, "1")
            waitFor("service connected") { FluviKeyguardCardServiceRegistry.connected }
            service = checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation())
            val owner = checkNotNull(service)
            if (widgetsAnywhere) assertTrue("NOT REACHED: native route selection", main {
                owner.setR448DisplayRoute(KeyguardR448DisplayRoute.WIDGETS_ANYWHERE)
            })
            val receipt = start(owner)
            assertEquals("NOT REACHED: armed input-ready presenter", true, receipt["printArmed"])
            if (widgetsAnywhere) assertEquals("original target presenter must not be prepared", null,
                main { owner.r446PresenterForInstrumentation() })
            owner.inspectionProbeForTest = object : KeyguardInspectionProbeForTest {
                override fun r447ControlledSampleTopology() = true
                override fun snapshots(request: KeyguardCardInspectionRequest, actual: List<KeyguardWindowSnapshot>): List<KeyguardWindowSnapshot> {
                    val hosts = actual.filter { it.packageName == "com.android.systemui" &&
                        it.type == AccessibilityWindowInfo.TYPE_SYSTEM && it.displayId == 0 &&
                        it.r444Active == true && it.r444Focused == true && it.r44?.active == true &&
                        it.r44.verifiedRoot && it.r44.complete && !it.r44.foreignNode && it.r446Bounds?.valid == true }
                    synchronized(note) { note.append("req=${request.id} actual=${actual.size} controlledHosts=${hosts.size}\n") }
                    return if (hosts.size == 1) hosts else actual
                }
                override fun r447SampleReadCompleted(request: KeyguardCardInspectionRequest,
                    eligibility: KeyguardR446Eligibility?, stale: Boolean) {
                    synchronized(note) { note.append("read=${request.id} eligible=${eligibility?.reason} stale=$stale\n") }
                    if (!stale && eligibility?.target != null && first.compareAndSet(0, request.id)) {
                        host.set(eligibility.target.windowId)
                        acquired.countDown()
                        check(release.await(20, TimeUnit.SECONDS)) { "NOT REACHED: release physical read" }
                    }
                }
                override fun queueOffered(request: KeyguardCardInspectionRequest, previous: KeyguardCardInspectionRequest?,
                    pending: KeyguardCardInspectionRequest?, startsWorker: Boolean) {
                    if (request.trigger == "r18Ready" && first.get() > 0) offered.compareAndSet(0, request.id)
                }
                override fun r447PresenterInvoked(request: Long) {
                    synchronized(invocations) { invocations.add(request) }
                }
            }
            shell("locksettings set-disabled false")
            shell("input keyevent KEYCODE_SLEEP")
            waitFor("screen off") { !power.isInteractive }
            shell("input keyevent KEYCODE_WAKEUP")
            waitFor("real lockscreen") { power.isInteractive && keyguard.isKeyguardLocked }
            assertTrue("NOT REACHED: real eligible inventory and reader/Main boundary", acquired.await(20, TimeUnit.SECONDS))
            waitFor("sampler idle") { main { owner.r447SamplerIdleForTest() } }
            main { owner.r447ScheduleOutputReadyForTest() }
            waitFor("internal successor queued") { offered.get() > 0 }
            val order = main { owner.r447SampleOrderForTest(first.get()) }
            synchronized(note) { note.append("first=${first.get()} next=${offered.get()} order=$order host=${host.get()}\n") }
            assertEquals("NOT REACHED: proven internal offer", KeyguardFirstAuthorizedOrb.SampleOffer.INTERNAL_DUPLICATE, order.origin)
            if (external) main { owner.acceptAccessibilityMetadataForTest(KeyguardAccessibilityEventMeta(
                eventType = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED, windowId = host.get(), displayId = 0,
                windowChanges = 0, packageName = "com.android.systemui", eventTimeUptimeMs = SystemClock.uptimeMillis())) }
            release.countDown()
            if (external) {
                waitFor("old completed read reaches a rejecting Main decision") {
                    val report = KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String
                    report.lineSequence().any { it.startsWith("R44_6_SAMPLE ") &&
                        it.contains("firstReq=${first.get()}") &&
                        (it.contains("firstHandoff=SCENE_CHANGED") || it.contains("firstHandoff=STALE_AUTHORITY") ||
                            it.contains("firstHandoff=RESTRICTION_OBSERVED") || it.contains("firstHandoff=ARM_MISMATCH")) }
                }
                assertFalse("old read reached presenter after external ingress", synchronized(invocations) { invocations.contains(first.get()) })
            } else {
                waitFor("first read reaches service presenter") { synchronized(invocations) { invocations.contains(first.get()) } }
                waitFor(if (widgetsAnywhere) "independent sample frame draws" else "first read submits") {
                    val report = KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String
                    report.lineSequence().any { it.startsWith("R44_6_SAMPLE ") &&
                        it.contains("progressReq=${first.get()}") &&
                        if (widgetsAnywhere) it.contains("backend=WA_SHADER_DRAW") && !it.contains("frame=UNOBSERVED")
                        else it.contains("submit=") && !it.contains("submit=UNOBSERVED") }
                }
                assertEquals("only one presenter call", 1, synchronized(invocations) { invocations.size })
                ui.takeScreenshot()?.let { shot ->
                    File(out, "r447-controlled-sample.png").outputStream().use { shot.compress(Bitmap.CompressFormat.PNG, 100, it) }
                    shot.recycle()
                }
            }
        } finally {
            release.countDown()
            service?.inspectionProbeForTest = null
            if (KeyguardCardDiagnostics.activeCaptureId() != null) {
                runCatching { File(out, "r447-report.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"] as String) }
                KeyguardCardDiagnostics.clearCapture(context)
            }
            File(out, "r447-evidence.txt").writeText(synchronized(note) { note.toString() } +
                "invocations=${synchronized(invocations) { invocations.toList() }}\n")
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
