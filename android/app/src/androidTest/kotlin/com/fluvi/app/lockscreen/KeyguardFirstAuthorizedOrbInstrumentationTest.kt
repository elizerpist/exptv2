package com.fluvi.app.lockscreen

import android.Manifest
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.KeyguardManager
import android.app.UiAutomation
import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.os.Build
import android.os.ParcelFileDescriptor
import android.os.PowerManager
import android.os.SystemClock
import android.provider.Settings
import android.view.Display
import android.view.accessibility.AccessibilityEvent
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.fluvi.app.lockscreen.material.FluviKeyguardMaterialStore
import com.fluvi.app.lockscreen.material.KeyguardOrbSurfaceWorkerTestHooks
import java.io.File
import java.util.Collections
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicLong
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

/** Actual accessibility service, real reader, hidden host and native producer.
 * Screenshots are retained unclassified; this control is not a pixel/privacy
 * or handset-performance pass. The host must use a disposable API35 device. */
@RunWith(AndroidJUnit4::class)
class KeyguardFirstAuthorizedOrbInstrumentationTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val context get() = instrumentation.targetContext
    private lateinit var automation: UiAutomation

    @Test fun stableInitialFullUsesOneVirginOutputWithoutReadinessRead() = runService(false)
    @Test fun externalIngressWhileFirstPaintIsHeldCannotUseOldProof() = runService(true)

    private fun runService(changeScene: Boolean) {
        assertEquals(35, Build.VERSION.SDK_INT)
        val args = InstrumentationRegistry.getArguments()
        val source = requireNotNull(args.getString("sourceSha"))
        require(source.matches(Regex("[0-9a-f]{40}")))
        val run = args.getString("runUuid")?.let { UUID.fromString(it).toString() } ?: UUID.randomUUID().toString()
        val dir = File(context.filesDir, "keyguard-service-probe/r19/$run/${if (changeScene) "changed" else "stable"}")
        check(!dir.exists() && dir.mkdirs())
        val keyguard = context.getSystemService(KeyguardManager::class.java)
        val power = context.getSystemService(PowerManager::class.java)
        automation = instrumentation.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        automation.serviceInfo = automation.serviceInfo.apply { flags = flags or AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS }
        val resolver = context.contentResolver
        val savedServices = Settings.Secure.getString(resolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        val savedEnabled = Settings.Secure.getString(resolver, Settings.Secure.ACCESSIBILITY_ENABLED)
        val savedLock = shell("locksettings get-disabled").trim()
        val savedSettings = preferences("fluvi_native_keyguard_card")
        val savedMaterial = preferences("fluvi_keyguard_header_material")
        val savedMode = preferences("fluvi_keyguard_orb_diagnostic_route")
        val component = ComponentName(context, FluviKeyguardCardService::class.java)
        val other = savedServices.orEmpty().split(':').filter {
            it.isNotBlank() && ComponentName.unflattenFromString(it) != component
        }.joinToString(":")
        val reads = Collections.synchronizedList(mutableListOf<String>())
        val secondRead = CountDownLatch(1)
        val injectedAt = AtomicLong(0L)
        val injectedRequest = AtomicLong(0L)
        val paintEntered = CountDownLatch(1)
        val releasePaint = CountDownLatch(1)
        val held = AtomicBoolean(false)
        var captureStarted = false
        var report: String? = null
        val errors = mutableListOf<String>()
        try {
            check(!FluviKeyguardCardServiceRegistry.connected) { "service must start in a fresh process" }
            check(!keyguard.isDeviceSecure) { "requires a disposable insecure keyguard" }
            check(savedLock == "true" || savedLock == "false")
            setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, other)
            await("old service disconnected", 8_000) { !FluviKeyguardCardServiceRegistry.connected }
            shell("input keyevent KEYCODE_WAKEUP")
            shell("wm dismiss-keyguard")
            await("unlocked", 5_000) { power.isInteractive && !keyguard.isKeyguardLocked }
            saveScreenshot(File(dir, "01-unlocked-background.png"))
            shell("locksettings set-disabled false")
            check(context.getSharedPreferences("fluvi_keyguard_orb_diagnostic_route", Context.MODE_PRIVATE)
                .edit().putString("mode", "SURFACE_LIVE").commit())
            instrumentation.runOnMainSync {
                FluviKeyguardCardSettings.update(context, mapOf("requested" to true, "showFinancialDetails" to true,
                    "presentationMode" to "orb", "animationMode" to "orbOnly"))
                val epoch = maxOf(SystemClock.elapsedRealtimeNanos(), (savedMaterial.second["publisherEpoch"] as? Long ?: -1L) + 1L)
                check(FluviKeyguardMaterialStore.publish(context, KeyguardR12ServiceTimingInstrumentationTest().materialProfile(), epoch))
            }
            KeyguardCardDiagnostics.startCapture(context, source, "debug", "LIGHT")
            captureStarted = true
            if (changeScene) KeyguardOrbSurfaceWorkerTestHooks.afterCanvasLock = { target ->
                if (target.directOutput != null && target.full && held.compareAndSet(false, true)) {
                    paintEntered.countDown()
                    check(releasePaint.await(20, TimeUnit.SECONDS)) { "first paint barrier timed out" }
                }
            }
            setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
                listOf(other, component.flattenToString()).filter(String::isNotBlank).joinToString(":"))
            setSecure(Settings.Secure.ACCESSIBILITY_ENABLED, "1")
            await("actual service connected", 10_000) { FluviKeyguardCardServiceRegistry.connected }
            val service = checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation())
            instrumentation.runOnMainSync {
                service.inspectionProbeForTest = object : KeyguardInspectionProbeForTest {
                    override fun started(request: KeyguardCardInspectionRequest) {
                        reads.add("start id=${request.id} trigger=${request.trigger} wake=${request.wakeGeneration}")
                        if (request.id == injectedRequest.get() && request.id != 0L) secondRead.countDown()
                    }
                    override fun ingressOffered(meta: KeyguardAccessibilityEventMeta, request: KeyguardCardInspectionRequest,
                        previous: KeyguardCardInspectionRequest?, pending: KeyguardCardInspectionRequest?,
                        startsWorker: Boolean, frameworkEvent: Boolean) {
                        if (!frameworkEvent && meta.eventTimeUptimeMs == injectedAt.get()) injectedRequest.set(request.id)
                    }
                    override fun readCompleted(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility,
                        reason: KeyguardSurfaceReason, rootUnavailable: Boolean, walkTruncated: Boolean,
                        abortedStale: Boolean, startedAt: Long, finishedAt: Long) {
                        reads.add("end id=${request.id} decision=$decision reason=$reason rootUnavailable=$rootUnavailable " +
                            "truncated=$walkTruncated stale=$abortedStale start=$startedAt end=$finishedAt")
                    }
                }
            }
            shell("input keyevent KEYCODE_SLEEP")
            await("sleep and keyguard", 8_000) { !power.isInteractive && keyguard.isKeyguardLocked }
            shell("input keyevent KEYCODE_WAKEUP")
            await("locked wake", 5_000) { power.isInteractive && keyguard.isKeyguardLocked }
            if (changeScene) {
                assertTrue("real first FULL paint was not reached", paintEntered.await(20, TimeUnit.SECONDS))
                instrumentation.runOnMainSync {
                    val at = SystemClock.uptimeMillis()
                    injectedAt.set(at)
                    service.acceptAccessibilityMetadataForTest(KeyguardAccessibilityEventMeta(
                        AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED, -1, Display.DEFAULT_DISPLAY, 0,
                        "com.android.systemui", at))
                }
                assertTrue("new scene inspection did not start", secondRead.await(10, TimeUnit.SECONDS))
                var visible = true
                instrumentation.runOnMainSync { visible = service.renderModeStatus().visible }
                assertFalse("old proof enabled the service while first paint was held", visible)
                saveScreenshot(File(dir, "02-held-after-ingress.png"))
                releasePaint.countDown()
            }
            await("actual service window", 20_000) {
                var visible = false
                instrumentation.runOnMainSync { visible = service.renderModeStatus().visible }
                visible && keyguard.isKeyguardLocked
            }
            // A WindowManager attach is insufficient. Wait for the actual
            // output's own native apply receipt, under the same attempt.
            await("direct reveal receipt", 15_000) {
                val text = KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String
                text.lineSequence().any { it.startsWith(" R18_PIPELINE ") &&
                    !it.contains("revealApply=UNOBSERVED/") && !it.contains("bufferReady=UNOBSERVED") }
            }
            saveScreenshot(File(dir, "03-visible-unclassified.png"))
            report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
            File(dir, "capture.txt").writeText(checkNotNull(report))
            // A stock baseline is RED only after its real direct output and
            // reveal were reached; a fallback/timeout is not a RED result.
            val row = checkNotNull(report).lineSequence().firstOrNull {
                it.startsWith(" R18_PIPELINE ") && it.contains("r19Intent=EMPTY") &&
                    !it.contains("revealApply=UNOBSERVED/") && !it.contains("bufferReady=UNOBSERVED")
            }
            assertNotNull("real direct reveal used no virgin FULL target", row)
            val currentRow = checkNotNull(row)
            assertFalse("missing full proof", currentRow.contains("firstPositive=UNOBSERVED"))
            assertFalse("missing authorized paint", currentRow.contains("paint=UNOBSERVED/"))
            assertFalse("missing continuation", currentRow.contains("consumed=UNOBSERVED"))
            val attempt = currentRow.substringAfter("attempt=").substringBefore(' ')
            assertEquals("stable initial show must use a single native target", 1,
                checkNotNull(report).lineSequence().count { it.startsWith(" R18_PIPELINE attempt=$attempt ") })
            val consumed = currentRow.substringAfter("consumedReq=").substringBefore(' ').toLong()
            val showing = currentRow.substringAfter(" proof=").substringBefore(' ').toLong()
            assertEquals("showing grant must use the consumed proof", consumed, showing)
            assertFalse("readiness alone requested a new tree walk", synchronized(reads) { reads.any { it.contains("trigger=r18Ready") } })
            if (changeScene) {
                val initial = currentRow.substringAfter("firstPositive=").substringBefore('@').toLong()
                assertTrue("old proof was consumed after external ingress", consumed > initial)
                assertTrue("consumed proof predates the injected event's real request", consumed >= injectedRequest.get())
            }
        } catch (error: Throwable) {
            errors += "${error.javaClass.simpleName}:${error.message}"
        } finally {
            releasePaint.countDown()
            KeyguardOrbSurfaceWorkerTestHooks.afterCanvasLock = null
            runCatching { if (captureStarted && report == null) {
                report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
                File(dir, "capture.txt").writeText(checkNotNull(report))
            } }.onFailure { errors += "freeze:${it.javaClass.simpleName}:${it.message}" }
            File(dir, "reads.txt").writeText(synchronized(reads) { reads.joinToString("\n", postfix = "\n") })
            runCatching {
                setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, other)
                await("service disconnected", 8_000) { !FluviKeyguardCardServiceRegistry.connected }
                restore(savedSettings); restore(savedMaterial); restore(savedMode)
                shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard")
                if (savedLock == "true" || savedLock == "false") shell("locksettings set-disabled $savedLock")
                setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, savedServices)
                setSecure(Settings.Secure.ACCESSIBILITY_ENABLED, savedEnabled)
            }.onFailure { errors += "cleanup:${it.javaClass.simpleName}:${it.message}" }
            File(dir, "result.txt").writeText("source=$source run=$run changed=$changeScene errors=${errors.joinToString(" | ")} physical=UNOBSERVED\n")
        }
        assertTrue("R19 service specimen failures: ${errors.joinToString(" | ")}", errors.isEmpty())
    }

    private fun saveScreenshot(file: File) {
        val image = checkNotNull(automation.takeScreenshot())
        file.outputStream().use { check(image.compress(Bitmap.CompressFormat.PNG, 100, it)) }
        image.recycle()
    }
    private fun shell(command: String): String = ParcelFileDescriptor.AutoCloseInputStream(
        automation.executeShellCommand(command)).bufferedReader().use { it.readText() }
    private fun setSecure(key: String, value: String?) {
        automation.adoptShellPermissionIdentity(Manifest.permission.WRITE_SECURE_SETTINGS)
        try { check(Settings.Secure.putString(context.contentResolver, key, value)) }
        finally { automation.dropShellPermissionIdentity() }
    }
    private fun await(label: String, timeout: Long, condition: () -> Boolean) {
        val end = SystemClock.uptimeMillis() + timeout
        while (SystemClock.uptimeMillis() < end) { if (condition()) return; SystemClock.sleep(100) }
        error("$label timed out")
    }
    private fun preferences(name: String): Pair<SharedPreferences, Map<String, *>> =
        context.getSharedPreferences(name, Context.MODE_PRIVATE).let { it to HashMap(it.all) }
    private fun restore(saved: Pair<SharedPreferences, Map<String, *>>) {
        val edit = saved.first.edit().clear()
        saved.second.forEach { (key, value) -> when (value) {
            is Boolean -> edit.putBoolean(key, value); is Int -> edit.putInt(key, value); is Long -> edit.putLong(key, value)
            is Float -> edit.putFloat(key, value); is String -> edit.putString(key, value)
            is Set<*> -> edit.putStringSet(key, value.filterIsInstance<String>().toSet())
        } }
        check(edit.commit())
    }
}
