package com.fluvi.app.lockscreen

import android.Manifest
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.KeyguardManager
import android.app.UiAutomation
import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.os.Handler
import android.os.Looper
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
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.atomic.AtomicReference
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

/** Real service and Android reader. Injected event metadata is explicitly
 * labelled; neither visibility decisions nor pixels are supplied by a test. */
@RunWith(AndroidJUnit4::class)
class KeyguardR25ServiceInstrumentationTest {
    @Test fun heldCompletePositiveReleasesReaderToRealSuccessor() = runScenario("held")
    @Test fun heldCompletePositiveUsesGenericStockOrbRoute() = runScenario("heldStock")
    @Test fun pendingBeforeCompletionPromotesActualSuccessor() = runScenario("pending")
    @Test fun stableCompletePositiveStillReachesMainOnce() = runScenario("stable")
    @Test fun rejectedMainPostUsesOrderedFallback() = runScenario("postRejected")
    @Test fun heldPositiveCannotShowAfterRealTerminalUnlock() = runScenario("unlock")
    @Test fun heldPositiveCannotShowAfterRealShadeWithCompositorSamples() = runScenario("shade")
    @Test fun heldPositiveIsRetiredOnPrivacyTightening() = runScenario("privacy")
    @Test fun oldHeldContinuationCannotMutateReplacementService() = runScenario("teardown")

    private data class Fact(val decision: KeyguardCardVisibility, val reason: KeyguardSurfaceReason,
        val unavailable: Boolean, val truncated: Boolean, val stale: Boolean, val start: Long, val end: Long) {
        fun eligible() = decision == KeyguardCardVisibility.SHOW_FULL && reason == KeyguardSurfaceReason.MAIN_CONFIRMED &&
            !unavailable && !truncated && !stale
    }

    private fun runScenario(scenario: String) {
        assertEquals("fixture requires the approved API 35 image", 35, Build.VERSION.SDK_INT)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        val args = InstrumentationRegistry.getArguments()
        val baseline = args.getString("r25Variant") == "baseline"
        val source = requireNotNull(args.getString("sourceSha"))
        require(source.matches(Regex("[0-9a-f]{40}")))
        val runId = UUID.fromString(requireNotNull(args.getString("runUuid"))).toString()
        val dir = File(context.filesDir, "keyguard-service-probe/r25/$runId/$scenario")
        check(dir.mkdirs())
        val automation = instrumentation.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        automation.serviceInfo = automation.serviceInfo.apply {
            flags = flags or AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
        }
        fun shell(command: String) = ParcelFileDescriptor.AutoCloseInputStream(
            automation.executeShellCommand(command)).bufferedReader().use { it.readText() }
        fun secure(key: String, value: String?) {
            automation.adoptShellPermissionIdentity(Manifest.permission.WRITE_SECURE_SETTINGS)
            try { check(Settings.Secure.putString(context.contentResolver, key, value)) }
            finally { automation.dropShellPermissionIdentity() }
        }
        fun waitUntil(label: String, timeoutMs: Long = 15_000, condition: () -> Boolean) {
            val end = SystemClock.uptimeMillis() + timeoutMs
            while (SystemClock.uptimeMillis() < end) {
                if (condition()) return
                SystemClock.sleep(50)
            }
            error("NOT REACHED: $label")
        }
        fun save(name: String) = context.getSharedPreferences(name, Context.MODE_PRIVATE).let { it to HashMap(it.all) }
        fun restore(saved: Pair<SharedPreferences, Map<String, *>>) {
            val edit = saved.first.edit().clear()
            saved.second.forEach { (key, value) -> when (value) {
                is Boolean -> edit.putBoolean(key, value); is Int -> edit.putInt(key, value)
                is Long -> edit.putLong(key, value); is Float -> edit.putFloat(key, value)
                is String -> edit.putString(key, value)
                is Set<*> -> edit.putStringSet(key, value.filterIsInstance<String>().toSet())
            } }
            check(edit.commit())
        }
        fun shadeWindow(): Int? {
            val markers = listOf("com.android.systemui:id/quick_settings_panel",
                "com.android.systemui:id/quick_qs_panel", "com.android.systemui:id/qs_frame",
                "com.android.systemui:id/settings_button", "com.android.systemui:id/split_shade_status_bar")
            for (window in automation.windows) {
                val root = runCatching { window.root }.getOrNull() ?: continue
                try {
                    if (window.displayId != Display.DEFAULT_DISPLAY || root.packageName?.toString() != "com.android.systemui") continue
                    for (marker in markers) {
                        val nodes = runCatching { root.findAccessibilityNodeInfosByViewId(marker) }.getOrDefault(emptyList())
                        val visible = try { nodes.any { it.isVisibleToUser } } finally { nodes.forEach { it.recycle() } }
                        if (visible) return window.id
                    }
                } finally { root.recycle() }
            }
            return null
        }
        val resolver = context.contentResolver
        val savedServices = Settings.Secure.getString(resolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        val savedEnabled = Settings.Secure.getString(resolver, Settings.Secure.ACCESSIBILITY_ENABLED)
        val savedLock = shell("locksettings get-disabled").trim()
        val savedSettings = save("fluvi_native_keyguard_card")
        val savedMaterial = save("fluvi_keyguard_header_material")
        val savedMode = save("fluvi_keyguard_orb_diagnostic_route")
        val component = ComponentName(context, FluviKeyguardCardService::class.java)
        val other = savedServices.orEmpty().split(':').filter {
            it.isNotBlank() && ComponentName.unflattenFromString(it) != component
        }.joinToString(":")
        val keyguard = context.getSystemService(KeyguardManager::class.java)
        val power = context.getSystemService(PowerManager::class.java)
        val records = Collections.synchronizedList(mutableListOf<String>())
        val armed = AtomicBoolean(false)
        val facts = ConcurrentHashMap<Long, Fact>()
        val starts = ConcurrentHashMap<Long, Long>()
        val applied = Collections.synchronizedList(mutableListOf<Long>())
        val held = AtomicReference<Pair<KeyguardCardInspectionRequest, Runnable>?>()
        val original = AtomicReference<KeyguardCardInspectionRequest?>()
        val candidateSeen = CountDownLatch(1)
        val releaseReader = CountDownLatch(1)
        val inputAt = AtomicLong(0L)
        val successor = AtomicLong(0L)
        val pendingOfferedId = AtomicLong(0L)
        val activeAfterId = AtomicLong(0L)
        val supersededId = AtomicLong(0L)
        val readerCount = AtomicInteger()
        val maximumReaders = AtomicInteger()
        val workerTimeout = AtomicBoolean(false)
        val exclusionArmed = AtomicBoolean(false)
        val exclusionResult = CountDownLatch(1)
        val ordinal = AtomicLong()
        val frameworkIngress = Collections.synchronizedList(mutableListOf<Pair<Int, Long>>())
        val fullEdges = Collections.synchronizedList(mutableListOf<Pair<Int?, Long>>())
        val savedRevealCross = KeyguardOrbSurfaceWorkerTestHooks.afterRevealCross
        var calibration: KeyguardR22VisualCalibration? = null
        val main = Handler(Looper.getMainLooper())
        var service: FluviKeyguardCardService? = null
        var capture = false
        var failure: Throwable? = null
        try {
            check(!FluviKeyguardCardServiceRegistry.connected)
            check(!keyguard.isDeviceSecure)
            check(savedLock == "true" || savedLock == "false")
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, other)
            shell("input keyevent KEYCODE_WAKEUP")
            shell("wm dismiss-keyguard")
            waitUntil("unlocked before service setup") { power.isInteractive && !keyguard.isKeyguardLocked }
            shell("locksettings set-disabled false")
            check(context.getSharedPreferences("fluvi_keyguard_orb_diagnostic_route", Context.MODE_PRIVATE)
                .edit().putString("mode", if (scenario == "heldStock") "LEGACY_R11" else "SURFACE_LIVE").commit())
            instrumentation.runOnMainSync {
                FluviKeyguardCardSettings.update(context, mapOf("requested" to true,
                    "showFinancialDetails" to true, "presentationMode" to "orb", "animationMode" to "orbOnly"))
                val epoch = maxOf(SystemClock.elapsedRealtimeNanos(),
                    (savedMaterial.second["publisherEpoch"] as? Long ?: -1L) + 1L)
                check(FluviKeyguardMaterialStore.publish(context,
                    KeyguardR12ServiceTimingInstrumentationTest().materialProfile(), epoch))
            }
            if (scenario == "shade") {
                calibration = KeyguardR22VisualCalibration(instrumentation, dir, automation).also { it.calibrate() }
                KeyguardOrbSurfaceWorkerTestHooks.fixedMaterialTime = KeyguardR22VisualCalibration.timeA
                KeyguardOrbSurfaceWorkerTestHooks.postedMaterialTime = { target, _, _ ->
                    if (exclusionArmed.get() && target.full)
                        fullEdges.add(target.directOutput?.childId to ordinal.incrementAndGet())
                }
                KeyguardOrbSurfaceWorkerTestHooks.afterRevealCross = { output ->
                    if (exclusionArmed.get()) fullEdges.add(output.childId to ordinal.incrementAndGet())
                    savedRevealCross?.invoke(output)
                }
            }
            KeyguardCardDiagnostics.startCapture(context, source, "debug", "LIGHT")
            capture = true
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
                listOf(other, component.flattenToString()).filter(String::isNotBlank).joinToString(":"))
            secure(Settings.Secure.ACCESSIBILITY_ENABLED, "1")
            waitUntil("real service connection") { FluviKeyguardCardServiceRegistry.connected }
            val actual = checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation())
            service = actual
            instrumentation.runOnMainSync {
                actual.inspectionProbeForTest = object : KeyguardInspectionProbeForTest {
                    override fun started(request: KeyguardCardInspectionRequest) {
                        starts[request.id] = SystemClock.uptimeMillis()
                        val count = readerCount.incrementAndGet()
                        maximumReaders.updateAndGet { maxOf(it, count) }
                        records.add("READ_START id=${request.id} wake=${request.wakeGeneration} at=${starts[request.id]} readers=$count")
                    }
                    override fun yielded(request: KeyguardCardInspectionRequest, next: KeyguardCardInspectionRequest,
                        startedAt: Long, finishedAt: Long, visited: Int) {
                        readerCount.decrementAndGet()
                        records.add("YIELDED ${request.id}->${next.id} at=$finishedAt")
                    }
                    override fun readCompleted(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility,
                        reason: KeyguardSurfaceReason, rootUnavailable: Boolean, walkTruncated: Boolean,
                        abortedStale: Boolean, startedAt: Long, finishedAt: Long) {
                        readerCount.decrementAndGet()
                        val fact = Fact(decision, reason, rootUnavailable, walkTruncated, abortedStale, startedAt, finishedAt)
                        facts[request.id] = fact
                        records.add("READ_END id=${request.id} wake=${request.wakeGeneration} fact=$fact")
                        if (exclusionArmed.get() && !abortedStale && decision in setOf(
                                KeyguardCardVisibility.HIDDEN_SHADE, KeyguardCardVisibility.HIDDEN_CREDENTIAL,
                                KeyguardCardVisibility.HIDDEN_UNLOCKED)) exclusionResult.countDown()
                        if (armed.get() && scenario == "pending" && fact.eligible() && original.compareAndSet(null, request)) {
                            candidateSeen.countDown()
                            if (!releaseReader.await(20, TimeUnit.SECONDS)) workerTimeout.set(true)
                        }
                    }
                    override fun r25QueueTransition(request: KeyguardCardInspectionRequest,
                        pendingAtOffer: KeyguardCardInspectionRequest?, activeAfter: KeyguardCardInspectionRequest?,
                        superseded: KeyguardCardInspectionRequest?) {
                        if (request.eventTimeUptimeMs == inputAt.get() && inputAt.get() != 0L) {
                            successor.set(request.id)
                            pendingOfferedId.set(pendingAtOffer?.id ?: 0L)
                            activeAfterId.set(activeAfter?.id ?: 0L)
                            supersededId.set(superseded?.id ?: 0L)
                            records.add("OFFER id=${request.id} pending=${pendingAtOffer?.id} active=${activeAfter?.id} superseded=${superseded?.id} origin=controlledMetadata")
                        }
                    }
                    override fun beforeApply(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility) {
                        applied.add(request.id)
                        records.add("MAIN_ENTER id=${request.id} decision=$decision at=${SystemClock.uptimeMillis()}")
                    }
                    override fun ingress(meta: KeyguardAccessibilityEventMeta, receivedAt: Long,
                        action: KeyguardEventAction, frameworkEvent: Boolean) {
                        if (exclusionArmed.get() && frameworkEvent && action == KeyguardEventAction.INSPECT)
                            frameworkIngress.add(meta.windowId to ordinal.incrementAndGet())
                    }
                }
                actual.r25MainDispatchForTest = { request, continuation ->
                    val fact = facts[request.id]
                    if (armed.get() && scenario != "pending" && fact?.eligible() == true && original.compareAndSet(null, request)) {
                        held.set(request to continuation)
                        records.add("MAIN_POST_HELD id=${request.id} at=${SystemClock.uptimeMillis()}")
                        candidateSeen.countDown()
                        if (scenario == "postRejected") false else true
                    } else main.post(continuation)
                }
            }
            shell("input keyevent KEYCODE_SLEEP")
            waitUntil("device asleep and locked") { !power.isInteractive && keyguard.isKeyguardLocked }
            armed.set(true)
            shell("input keyevent KEYCODE_WAKEUP")
            waitUntil("device awake and locked") { power.isInteractive && keyguard.isKeyguardLocked }
            assertTrue("NOT REACHED: no complete eligible positive at the selected boundary", candidateSeen.await(20, TimeUnit.SECONDS))
            val a = checkNotNull(original.get())
            assertTrue("NOT REACHED: A lacked a complete real MAIN/FULL classification", facts[a.id]?.eligible() == true)
            var originalAuthorityCurrent = false
            instrumentation.runOnMainSync { originalAuthorityCurrent = actual.inspectionStateForTest().authority.matches(a) }
            assertTrue("NOT REACHED: A's original service/wake/visibility/attachment authority changed", originalAuthorityCurrent)
            records.add("A_CONFIRMED id=${a.id} fact=${facts[a.id]}")
            if (scenario == "held" || scenario == "heldStock" || scenario == "pending") {
                instrumentation.runOnMainSync {
                    val now = SystemClock.uptimeMillis()
                    inputAt.set(now)
                    actual.acceptAccessibilityMetadataForTest(KeyguardAccessibilityEventMeta(
                        AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED, -1, Display.DEFAULT_DISPLAY, 0,
                        "com.android.systemui", now))
                }
                val b = successor.get()
                assertTrue("NOT REACHED: a new service request was not offered", b > a.id)
                assertEquals("the actual request must have entered the one pending slot", b, pendingOfferedId.get())
                if ((scenario == "held" || scenario == "heldStock") && !baseline) {
                    assertEquals("the exact held A was superseded", a.id, supersededId.get())
                    assertEquals("the actual offered B owns the reader", b, activeAfterId.get())
                }
                if (scenario == "pending") releaseReader.countDown()
                if (scenario == "held" || scenario == "heldStock") {
                    val barrier = CountDownLatch(1)
                    actual.r25ReaderBarrierForTest { barrier.countDown() }
                    assertTrue("NOT REACHED: reader-lane barrier was not acknowledged", barrier.await(15, TimeUnit.SECONDS))
                    if (baseline) {
                        assertEquals("stock active request remains A", a.id, activeAfterId.get())
                        assertFalse("stock B must remain behind held A", starts.containsKey(b))
                    } else assertTrue("candidate B started before Main release", starts.containsKey(b))
                } else waitUntil("successor physically starts") { starts.containsKey(b) }
                assertEquals("single physical reader", 1, maximumReaders.get())
                assertFalse("obsolete A must not have entered Main", applied.contains(a.id))
                records.add("BEFORE_A_RELEASE variant=${if (baseline) "baseline" else "candidate"} a=${a.id} b=$b start=${starts[b] ?: "UNOBSERVED"} active=${activeAfterId.get()} superseded=${supersededId.get()}")
            } else if (scenario == "unlock") {
                shell("wm dismiss-keyguard")
                waitUntil("actual terminal unlock") { power.isInteractive && !keyguard.isKeyguardLocked }
                var visible = true
                instrumentation.runOnMainSync { visible = actual.renderModeStatus().visible }
                assertFalse("terminal unlock must withdraw the orb", visible)
            } else if (scenario == "privacy") {
                instrumentation.runOnMainSync {
                    val tightened = FluviKeyguardCardSettings.update(context, mapOf("showFinancialDetails" to false))
                    assertFalse("NOT REACHED: privacy preference was not tightened", tightened.showFinancialDetails)
                    actual.onSettingsChangedFromApplication(tightened)
                }
                instrumentation.runOnMainSync { } // acknowledge the posted settings transition
                var sameAuthority = true
                instrumentation.runOnMainSync { sameAuthority = actual.inspectionStateForTest().authority.matches(a) }
                assertFalse("NOT REACHED: privacy transition did not invalidate A", sameAuthority)
            } else if (scenario == "teardown") {
                secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, other)
                waitUntil("old service disconnected") { !FluviKeyguardCardServiceRegistry.connected }
                held.get()?.second?.let { continuation -> instrumentation.runOnMainSync { continuation.run() } }
                secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
                    listOf(other, component.flattenToString()).filter(String::isNotBlank).joinToString(":"))
                waitUntil("replacement service connected") {
                    val current = FluviKeyguardCardServiceRegistry.serviceForInstrumentation()
                    current != null && current !== actual
                }
            } else if (scenario == "shade") {
                var identity: KeyguardR22VisualIdentityForTest? = null
                waitUntil("staged real output identity") {
                    instrumentation.runOnMainSync { identity = actual.r22VisualIdentityForTest() }
                    identity != null
                }
                val owner = checkNotNull(identity)
                val visual = checkNotNull(calibration)
                exclusionArmed.set(true)
                File(dir, "shade-command.txt").writeText(shell("cmd statusbar expand-notifications"))
                var shade: Int? = null
                waitUntil("independent SystemUI shade") { shade = shadeWindow(); shade != null }
                waitUntil("real framework ingress for shade") {
                    synchronized(frameworkIngress) { frameworkIngress.any { it.first == shade } }
                }
                val cause = synchronized(frameworkIngress) { frameworkIngress.first { it.first == shade } }
                val samples = (0 until 12).map { index ->
                    if (index == 4) held.get()?.second?.let { continuation -> instrumentation.runOnMainSync { continuation.run() } }
                    visual.captureCrop("shade-sample-$index", owner.bounds).also { SystemClock.sleep(40) }
                }
                assertTrue("NOT REACHED: no complete real exclusion result", exclusionResult.await(15, TimeUnit.SECONDS))
                var visible = true
                instrumentation.runOnMainSync { visible = actual.renderModeStatus().visible }
                assertFalse("shade must leave the orb withdrawn", visible)
                val beforeDisconnect = visual.captureCrop("shade-before-disconnect", owner.bounds)
                secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, other)
                waitUntil("service disconnected for independent shade underlay") { !FluviKeyguardCardServiceRegistry.connected }
                assertEquals("NOT REACHED: shade changed before underlay reference", shade, shadeWindow())
                val underlay = visual.captureCrop("shade-independent-underlay", owner.bounds)
                assertTrue("NOT REACHED: removal did not match independent underlay",
                    KeyguardR22VisualCalibration.compare(beforeDisconnect, underlay).nearlyEqual())
                val categories = visual.classifyAfterExclusion(samples, underlay)
                File(dir, "shade-categories.txt").writeText(categories.joinToString("\n", postfix = "\n"))
                assertFalse("old FULL content after exclusion", categories.contains("OLD_FULL"))
                assertFalse("NOT REACHED: at least one sample was unclassified", categories.contains("UNCLASSIFIED"))
                val late = synchronized(fullEdges) { fullEdges.filter { it.first == owner.childIdentity && it.second > cause.second } }
                assertTrue("stale FULL post or reveal after shade ingress: $late", late.isEmpty())
                records.add("SHADE_VISUAL window=$shade categories=$categories compositor=OBSERVED physical=UNOBSERVED")
            }
            releaseReader.countDown()
            held.get()?.second?.let { continuation -> instrumentation.runOnMainSync { continuation.run() } }
            if (scenario == "held" && baseline) {
                waitUntil("baseline A enters ordered Main") { applied.contains(a.id) }
                waitUntil("baseline successor physically starts after release") { starts.containsKey(successor.get()) }
            }
            if (scenario == "stable" || scenario == "postRejected") {
                waitUntil("stable original enters Main") { applied.contains(a.id) }
                assertEquals("one Main admission for A", 1, synchronized(applied) { applied.count { it == a.id } })
            } else if (!(scenario == "held" && baseline)) {
                assertFalse("obsolete positive A entered Main", applied.contains(a.id))
            }
            if (scenario == "unlock") {
                shell("input keyevent KEYCODE_SLEEP")
                waitUntil("fresh relock") { !power.isInteractive && keyguard.isKeyguardLocked }
                shell("input keyevent KEYCODE_WAKEUP")
                waitUntil("fresh relock awake") { power.isInteractive && keyguard.isKeyguardLocked }
                waitUntil("fresh relock reaches a new Main admission") {
                    synchronized(applied) { applied.any { it > a.id } }
                }
                assertFalse("retired A remained excluded after relock", applied.contains(a.id))
            }
            assertFalse("NOT REACHED: held physical reader timed out", workerTimeout.get())
            records.add("RESULT scenario=$scenario maxReaders=${maximumReaders.get()} physicalPixel=UNOBSERVED")
        } catch (error: Throwable) {
            failure = error
            records.add("FAIL ${error.javaClass.simpleName}:${error.message}")
        } finally {
            releaseReader.countDown()
            held.get()?.second?.run()
            if (scenario == "shade") runCatching { shell("cmd statusbar collapse") }
            KeyguardOrbSurfaceWorkerTestHooks.fixedMaterialTime = null
            KeyguardOrbSurfaceWorkerTestHooks.postedMaterialTime = null
            KeyguardOrbSurfaceWorkerTestHooks.afterRevealCross = savedRevealCross
            runCatching { calibration?.close() }
            runCatching { instrumentation.runOnMainSync {
                service?.r25MainDispatchForTest = null
                service?.inspectionProbeForTest = null
            } }
            if (capture) runCatching {
                File(dir, "capture.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"] as String)
            }
            File(dir, "sequence.txt").writeText(synchronized(records) { records.joinToString("\n", postfix = "\n") })
            runCatching {
                secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, other)
                waitUntil("service disconnected") { !FluviKeyguardCardServiceRegistry.connected }
                restore(savedSettings); restore(savedMaterial); restore(savedMode)
                shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard")
                if (savedLock == "true" || savedLock == "false") shell("locksettings set-disabled $savedLock")
                secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, savedServices)
                secure(Settings.Secure.ACCESSIBILITY_ENABLED, savedEnabled)
            }.onFailure { if (failure == null) failure = it else records.add("CLEANUP_FAIL ${it.message}") }
            File(dir, "result.txt").writeText("source=$source scenario=$scenario verdict=${if (failure == null) "PASS" else "FAIL_OR_NOT_REACHED"} physical=UNOBSERVED\n")
        }
        failure?.let { throw it }
    }
}
