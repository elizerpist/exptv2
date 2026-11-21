package com.fluvi.app.lockscreen

import android.Manifest
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.KeyguardManager
import android.app.UiAutomation
import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
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
import java.io.File
import java.util.Collections
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.atomic.AtomicReference
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

/** Real-service fixture. Controlled metadata remains explicitly labelled;
 * only Android's own reader/classifier can produce a visibility decision. */
internal class KeyguardR22FirstInspectionFixture {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val context get() = instrumentation.targetContext
    private lateinit var automation: UiAutomation

    fun run(scenario: String) {
        require(scenario in setOf("positive", "negative", "stable"))
        assertEquals(35, Build.VERSION.SDK_INT)
        val args = InstrumentationRegistry.getArguments()
        val source = requireNotNull(args.getString("sourceSha"))
        require(source.matches(Regex("[0-9a-f]{40}")))
        val uuid = UUID.fromString(requireNotNull(args.getString("runUuid"))).toString()
        val dir = File(context.filesDir, "keyguard-service-probe/r22/$uuid/$scenario")
        check(dir.mkdirs())
        automation = instrumentation.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        automation.serviceInfo = automation.serviceInfo.apply {
            flags = flags or AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
        }
        val keyguard = context.getSystemService(KeyguardManager::class.java)
        val power = context.getSystemService(PowerManager::class.java)
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
        val records = Collections.synchronizedList(mutableListOf<String>())
        val entered = CountDownLatch(1)
        val release = CountDownLatch(1)
        val completed = CountDownLatch(1)
        val bStarted = CountDownLatch(1)
        val a = AtomicReference<KeyguardCardInspectionRequest?>()
        val b = AtomicLong(0L)
        val injectedAt = AtomicLong(0L)
        val afterB = AtomicBoolean(false)
        val nextChild = AtomicBoolean(false)
        val recordObservation = AtomicReference<KeyguardR15AcquisitionTestHooks.Observation?>()
        val bFinished = CountDownLatch(1)
        val bEntered = CountDownLatch(1)
        val releaseB = CountDownLatch(1)
        val realNegativeEvent = CountDownLatch(1)
        val negativeResult = CountDownLatch(1)
        val negativeArmed = AtomicBoolean(false)
        val resultB = AtomicReference<String?>()
        val yieldedTo = AtomicLong(0L)
        val aThread = AtomicLong(0L)
        val bThread = AtomicLong(0L)
        var capture = false
        var report: String? = null
        val errors = mutableListOf<String>()
        try {
            check(!FluviKeyguardCardServiceRegistry.connected)
            check(!keyguard.isDeviceSecure)
            check(savedLock == "true" || savedLock == "false")
            setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, other)
            await("previous service disconnected", 8_000) { !FluviKeyguardCardServiceRegistry.connected }
            shell("input keyevent KEYCODE_WAKEUP")
            shell("wm dismiss-keyguard")
            await("unlocked", 5_000) { power.isInteractive && !keyguard.isKeyguardLocked }
            shell("locksettings set-disabled false")
            check(context.getSharedPreferences("fluvi_keyguard_orb_diagnostic_route", Context.MODE_PRIVATE)
                .edit().putString("mode", "SURFACE_LIVE").commit())
            instrumentation.runOnMainSync {
                FluviKeyguardCardSettings.update(context, mapOf("requested" to true,
                    "showFinancialDetails" to true, "presentationMode" to "orb", "animationMode" to "orbOnly"))
                val epoch = maxOf(SystemClock.elapsedRealtimeNanos(),
                    (savedMaterial.second["publisherEpoch"] as? Long ?: -1L) + 1L)
                check(FluviKeyguardMaterialStore.publish(context,
                    KeyguardR12ServiceTimingInstrumentationTest().materialProfile(), epoch))
            }
            KeyguardCardDiagnostics.startCapture(context, source, "debug", "LIGHT")
            capture = true
            KeyguardR15AcquisitionTestHooks.stockArm = true
            KeyguardR15AcquisitionTestHooks.historicalRootOnlyOptIn = false
            KeyguardR15AcquisitionTestHooks.observeIneligible = true
            KeyguardR15AcquisitionTestHooks.observer = { observation ->
                if (observation.request.id == a.get()?.id) {
                    recordObservation.set(observation)
                    records.add("A_RESULT id=${observation.request.id} eligible=${observation.eligible} " +
                        "decision=${observation.decision} reason=${observation.reason} " +
                        "unavailable=${observation.result.rootUnavailable} truncated=${observation.result.walkTruncated} " +
                        "stale=${observation.result.abortedStale} children=${observation.result.timing.childAcquisitionCount}")
                }
            }
            KeyguardR15AcquisitionTestHooks.beforeChildCall = { request, window, index ->
                if (afterB.get() && request.id == a.get()?.id) {
                    nextChild.set(true)
                    records.add("A_NEXT_CHILD_BEFORE id=${request.id} window=$window index=$index at=${SystemClock.uptimeMillis()} thread=${Thread.currentThread().id}")
                }
            }
            KeyguardR15AcquisitionTestHooks.afterReturnedChild = { request, window, index, present, eligible ->
                if (present && eligible && a.compareAndSet(null, request)) {
                    aThread.set(Thread.currentThread().id)
                    records.add("A_FIRST_CHILD_RETURN id=${request.id} wake=${request.wakeGeneration} " +
                        "window=$window index=$index at=${SystemClock.uptimeMillis()} thread=${Thread.currentThread().id}")
                    entered.countDown()
                    if (!release.await(20, TimeUnit.SECONDS)) records.add("A_BARRIER_TIMEOUT")
                } else if (scenario == "negative" && present && request.id == yieldedTo.get() && request.id > 0) {
                    records.add("B_CHILD_RETURN id=${request.id} window=$window index=$index at=${SystemClock.uptimeMillis()}")
                    bEntered.countDown()
                    if (!releaseB.await(20, TimeUnit.SECONDS)) records.add("B_BARRIER_TIMEOUT")
                }
            }
            setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
                listOf(other, component.flattenToString()).filter(String::isNotBlank).joinToString(":"))
            setSecure(Settings.Secure.ACCESSIBILITY_ENABLED, "1")
            await("service connected", 10_000) { FluviKeyguardCardServiceRegistry.connected }
            val service = checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation())
            instrumentation.runOnMainSync {
                service.inspectionProbeForTest = object : KeyguardInspectionProbeForTest {
                    override fun started(request: KeyguardCardInspectionRequest) {
                        records.add("START id=${request.id} wake=${request.wakeGeneration} at=${SystemClock.uptimeMillis()} thread=${Thread.currentThread().id}")
                        if (request.id == yieldedTo.get() && request.id != 0L) {
                            bThread.set(Thread.currentThread().id)
                            bStarted.countDown()
                        }
                    }
                    override fun yielded(request: KeyguardCardInspectionRequest, successor: KeyguardCardInspectionRequest,
                        startedAt: Long, finishedAt: Long, visited: Int) {
                        if (request.id == a.get()?.id) {
                            yieldedTo.set(successor.id)
                            records.add("YIELDED A=${request.id} B=${successor.id} start=$startedAt end=$finishedAt visited=$visited")
                            completed.countDown()
                        }
                    }
                    override fun readCompleted(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility,
                        reason: KeyguardSurfaceReason, rootUnavailable: Boolean, walkTruncated: Boolean,
                        abortedStale: Boolean, startedAt: Long, finishedAt: Long) {
                        records.add("END id=${request.id} decision=$decision reason=$reason root=$rootUnavailable truncated=$walkTruncated stale=$abortedStale")
                        if (request.id == a.get()?.id) { resultB.compareAndSet(null, "A:$decision/$reason/$rootUnavailable/$walkTruncated/$abortedStale"); completed.countDown() }
                        if (request.id == yieldedTo.get() && request.id > 0L) {
                            resultB.set("B:$decision/$reason/$rootUnavailable/$walkTruncated/$abortedStale")
                            bFinished.countDown()
                        }
                        if (negativeArmed.get() && !abortedStale && decision in setOf(
                                KeyguardCardVisibility.HIDDEN_SHADE, KeyguardCardVisibility.HIDDEN_CREDENTIAL,
                                KeyguardCardVisibility.HIDDEN_UNLOCKED)) negativeResult.countDown()
                    }
                    override fun ingress(meta: KeyguardAccessibilityEventMeta, receivedAt: Long,
                        action: KeyguardEventAction, frameworkEvent: Boolean) {
                        if (negativeArmed.get() && frameworkEvent && action == KeyguardEventAction.INSPECT &&
                            (meta.displayId == Display.DEFAULT_DISPLAY || meta.displayId < 0)) {
                            records.add("REAL_NEGATIVE_EVENT type=${meta.eventType} window=${meta.windowId} display=${meta.displayId} at=$receivedAt")
                            realNegativeEvent.countDown()
                        }
                    }
                    override fun ingressOffered(meta: KeyguardAccessibilityEventMeta, request: KeyguardCardInspectionRequest,
                        previous: KeyguardCardInspectionRequest?, pending: KeyguardCardInspectionRequest?,
                        startsWorker: Boolean, frameworkEvent: Boolean) {
                        if (!frameworkEvent && meta.eventTimeUptimeMs == injectedAt.get()) {
                            b.set(request.id)
                            records.add("B_OFFER id=${request.id} pending=${pending?.id} activeWorker=${!startsWorker} " +
                                "wake=${request.wakeGeneration} at=${SystemClock.uptimeMillis()} framework=false")
                            if (pending?.id == request.id && !startsWorker) afterB.set(true)
                        }
                    }
                }
            }
            shell("input keyevent KEYCODE_SLEEP")
            await("sleep/locked", 8_000) { !power.isInteractive && keyguard.isKeyguardLocked }
            shell("input keyevent KEYCODE_WAKEUP")
            await("locked/interactive", 5_000) { power.isInteractive && keyguard.isKeyguardLocked }
            assertTrue("NOT REACHED: eligible opening call did not return a child", entered.await(20, TimeUnit.SECONDS))
            val original = checkNotNull(a.get())
            if (scenario == "stable") {
                var pending: KeyguardCardInspectionRequest? = null
                instrumentation.runOnMainSync { pending = service.inspectionStateForTest().pending }
                assertNull("NOT REACHED: stable A already has pending work", pending)
                release.countDown()
                assertTrue("NOT REACHED: stable opening did not complete", completed.await(20, TimeUnit.SECONDS))
                assertEquals("NOT REACHED: no stable complete MAIN/FULL result",
                    "A:SHOW_FULL/MAIN_CONFIRMED/false/false/false", resultB.get())
                assertEquals("stable A must not be yielded", 0L, yieldedTo.get())
            } else {
                instrumentation.runOnMainSync {
                    val now = SystemClock.uptimeMillis()
                    injectedAt.set(now)
                    service.acceptAccessibilityMetadataForTest(KeyguardAccessibilityEventMeta(
                        AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED, -1, Display.DEFAULT_DISPLAY, 0,
                        "com.android.systemui", now))
                }
                assertTrue("NOT REACHED: controlled real-queue B was not offered", afterB.get())
                assertTrue("NOT REACHED: B id did not advance", b.get() > original.id)
                release.countDown()
                assertTrue("NOT REACHED: A reached no useful handoff checkpoint", completed.await(20, TimeUnit.SECONDS))
                assertEquals("NOT REACHED: controlled B was replaced or A finished normally", b.get(), yieldedTo.get())
                assertTrue("NOT REACHED: claimed B did not physically start", bStarted.await(15, TimeUnit.SECONDS))
                assertEquals("B must run on the same physical reader", aThread.get(), bThread.get())
                assertFalse("A requested another child after B was claimed", nextChild.get())
                if (scenario == "negative") {
                    assertTrue("NOT REACHED: B did not reach its returned-child boundary", bEntered.await(15, TimeUnit.SECONDS))
                    negativeArmed.set(true)
                    File(dir, "shade-command.txt").writeText(shell("cmd statusbar expand-notifications"))
                    assertTrue("NOT REACHED: no real framework exclusion ingress", realNegativeEvent.await(10, TimeUnit.SECONDS))
                    releaseB.countDown()
                    assertTrue("NOT REACHED: no complete real shade/credential/unlock result", negativeResult.await(15, TimeUnit.SECONDS))
                    var visible = true
                    instrumentation.runOnMainSync { visible = service.renderModeStatus().visible }
                    assertFalse("negative scene must not expose the orb", visible)
                } else {
                    assertTrue("NOT REACHED: B did not complete a fresh physical read", bFinished.await(20, TimeUnit.SECONDS))
                    assertEquals("NOT REACHED: B did not return a complete MAIN/FULL classification",
                        "B:SHOW_FULL/MAIN_CONFIRMED/false/false/false", resultB.get())
                }
            }
            if (scenario != "negative") {
                await("NOT REACHED: exact direct reveal was not submitted", 15_000) {
                    val current = KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String
                    current.lineSequence().any { line ->
                        line.startsWith(" R21_CORE ") && line.contains("/ACCEPTED ingress=") &&
                            !line.contains(" consumedReq=UNOBSERVED ") &&
                            (scenario == "stable" || !line.contains(" consumedReq=${original.id} "))
                    }
                }
            }
            val snapshot = KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String
            File(dir, "before-freeze.txt").writeText(snapshot)
            val row = snapshot.lineSequence().firstOrNull { it.startsWith(" R18_PIPELINE ") &&
                it.contains("reservedReq=${original.id} ") && it.contains("r19Intent=EMPTY") }
            assertNotNull("NOT REACHED: A was not the exact EMPTY reservation", row)
            val core = snapshot.lineSequence().firstOrNull { it.startsWith(" R22_CORE ") &&
                it.contains("opening=${original.id}/") }
            assertNotNull("missing protected R22 acquisition core", core)
            if (scenario == "stable") assertTrue(checkNotNull(core).contains("outcome=A_FINISHED/"))
            else {
                assertTrue(checkNotNull(core).contains("outcome=YIELDED/"))
                assertTrue(checkNotNull(core).contains("claimed=${yieldedTo.get()}@"))
                assertFalse("a yielded A must have no completion classification", checkNotNull(core).contains("aResult=SHOW_FULL"))
            }
            val screenshot = automation.takeScreenshot()
            screenshot?.let { image -> File(dir, "service-unclassified.png").outputStream().use {
                image.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, it)
            }; image.recycle() }
            records.add("SERVICE_CONTROL scenario=$scenario A=${original.id} B=${yieldedTo.get()} physical=UNOBSERVED")
        } catch (error: Throwable) {
            errors += "${error.javaClass.simpleName}:${error.message}"
        } finally {
            release.countDown()
            releaseB.countDown()
            if (scenario == "negative") runCatching { shell("cmd statusbar collapse") }
            KeyguardR15AcquisitionTestHooks.afterReturnedChild = null
            KeyguardR15AcquisitionTestHooks.beforeChildCall = null
            KeyguardR15AcquisitionTestHooks.observer = null
            KeyguardR15AcquisitionTestHooks.observeIneligible = false
            runCatching {
                if (capture) {
                    report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
                    File(dir, "capture.txt").writeText(checkNotNull(report))
                }
            }.onFailure { errors += "freeze:${it.javaClass.simpleName}:${it.message}" }
            File(dir, "sequence.txt").writeText(synchronized(records) { records.joinToString("\n", postfix = "\n") })
            runCatching {
                setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, other)
                await("service disconnected", 8_000) { !FluviKeyguardCardServiceRegistry.connected }
                restore(savedSettings); restore(savedMaterial); restore(savedMode)
                shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard")
                if (savedLock == "true" || savedLock == "false") shell("locksettings set-disabled $savedLock")
                setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, savedServices)
                setSecure(Settings.Secure.ACCESSIBILITY_ENABLED, savedEnabled)
            }.onFailure { errors += "cleanup:${it.javaClass.simpleName}:${it.message}" }
            File(dir, "result.txt").writeText("source=$source uuid=$uuid scenario=$scenario injectedFrameworkEvent=false visualCalibration=UNESTABLISHED errors=${errors.joinToString(" | ")}\n")
        }
        assertTrue("R22 candidate service: ${errors.joinToString(" | ")}", errors.isEmpty())
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
