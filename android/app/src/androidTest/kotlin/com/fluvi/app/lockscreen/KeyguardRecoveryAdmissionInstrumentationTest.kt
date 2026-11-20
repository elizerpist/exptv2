package com.fluvi.app.lockscreen

import android.Manifest
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.KeyguardManager
import android.app.UiAutomation
import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import android.hardware.display.DisplayManager
import android.os.Build
import android.os.ParcelFileDescriptor
import android.os.PowerManager
import android.os.SystemClock
import android.provider.Settings
import android.view.Display
import android.view.InputDevice
import android.view.KeyEvent
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.view.inspector.WindowInspector
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.fluvi.app.lockscreen.material.FluviKeyguardMaterialStore
import com.fluvi.app.lockscreen.material.KeyguardMaterialProfile
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

/** Controlled ordering on the real service. The negative which first withdraws
 * the root is explicitly injected into the classifier, while the decisive
 * exclusion is an independently opened SystemUI shade. Event B is a labelled
 * metadata copy through the same ingress adapter as a framework callback. */
@RunWith(AndroidJUnit4::class)
class KeyguardRecoveryAdmissionInstrumentationTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val context get() = instrumentation.targetContext
    private val keyguard get() = context.getSystemService(KeyguardManager::class.java)
    private val power get() = context.getSystemService(PowerManager::class.java)
    private lateinit var automation: UiAutomation
    private lateinit var output: File
    private val records = StringBuilder()

    @Test fun supersededExternalEventSuppressesOnlyTheRecoveryAdd() = scenario("exclusion", true, false)
    @Test fun freshMainSuccessorRestoresExactlyOnce() = scenario("fresh-main", false, false)
    @Test fun postAttachOnlyExclusionNeverDefersPriorAdmission() = scenario("late-only", true, true)

    private fun scenario(name: String, exclude: Boolean, lateOnly: Boolean) {
        assertEquals("fixture needs API35", 35, Build.VERSION.SDK_INT)
        val args = InstrumentationRegistry.getArguments()
        val source = requireNotNull(args.getString("sourceSha"))
        require(source.matches(Regex("[0-9a-f]{40}")))
        val runId = UUID.fromString(requireNotNull(args.getString("runUuid"))).toString()
        automation = instrumentation.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        automation.serviceInfo = automation.serviceInfo.apply { flags = flags or AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS }
        output = File(context.filesDir, "keyguard-service-probe/r14/$runId/$name")
        check(!output.exists() && output.mkdirs()) { "run/method reused" }
        val resolver = context.contentResolver
        val savedServices = Settings.Secure.getString(resolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        val savedEnabled = Settings.Secure.getString(resolver, Settings.Secure.ACCESSIBILITY_ENABLED)
        val savedLock = shell("locksettings get-disabled").trim()
        val savedSettings = preferences("fluvi_native_keyguard_card")
        val savedMaterial = preferences("fluvi_keyguard_header_material")
        val savedMode = preferences("fluvi_keyguard_orb_diagnostic_route")
        val component = ComponentName(context, FluviKeyguardCardService::class.java)
        fun otherServices() = savedServices.orEmpty().split(':').filter {
            it.isNotBlank() && ComponentName.unflattenFromString(it) != component
        }.joinToString(":")
        val workerHeld = CountDownLatch(1)
        val releaseWorker = CountDownLatch(1)
        val aApplied = CountDownLatch(1)
        val failure = AtomicReference<Throwable?>()
        val a = AtomicReference<KeyguardCardInspectionRequest?>()
        val b = AtomicReference<KeyguardCardInspectionRequest?>()
        val c = AtomicReference<KeyguardCardInspectionRequest?>()
        val replacement = AtomicReference<KeyguardCardInspectionRequest?>()
        val reads = java.util.concurrent.ConcurrentHashMap.newKeySet<Long>()
        val applied = java.util.concurrent.ConcurrentHashMap<Long, KeyguardCardVisibility>()
        val aStarted = java.util.concurrent.atomic.AtomicLong()
        val aAttached = java.util.concurrent.atomic.AtomicBoolean()
        val aGeneration = java.util.concurrent.atomic.AtomicLong()
        val originalGeneration = java.util.concurrent.atomic.AtomicLong()
        val frameworkEvents = java.util.concurrent.atomic.AtomicInteger()
        var service: FluviKeyguardCardService? = null
        var captureStarted = false
        var captureId = "UNOBSERVED"
        fun schedule(owner: FluviKeyguardCardService, trigger: String) {
            val method = FluviKeyguardCardService::class.java.getDeclaredMethod(
                "scheduleEvaluation", String::class.java, java.lang.Long::class.java,
                java.lang.Long::class.java, KeyguardWindowFreshness::class.java,
                KeyguardCardInspectionRequest::class.java,
            ).apply { isAccessible = true }
            method.invoke(owner, trigger, null, SystemClock.uptimeMillis(), KeyguardWindowFreshness.FRAMEWORK_EVENT, null)
        }
        val probe = object : KeyguardInspectionProbeForTest {
            override fun ingress(meta: KeyguardAccessibilityEventMeta, receivedAt: Long, action: KeyguardEventAction, frameworkEvent: Boolean) {
                if (frameworkEvent) frameworkEvents.incrementAndGet()
                record("INGRESS", "framework=$frameworkEvent type=${meta.eventType} window=${meta.windowId} display=${meta.displayId} systemui=${meta.packageName == "com.android.systemui"} event=${meta.eventTimeUptimeMs} callback=$receivedAt action=$action")
            }
            override fun snapshots(request: KeyguardCardInspectionRequest, actual: List<KeyguardWindowSnapshot>): List<KeyguardWindowSnapshot> =
                if (request.trigger == "r14-controlled-withdraw") actual + KeyguardWindowSnapshot(
                    packageName = "fixture.controlled.negative", type = 1, layer = Int.MAX_VALUE,
                    displayId = Display.DEFAULT_DISPLAY, windowId = 990035,
                ) else actual
            override fun readCompleted(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility,
                reason: KeyguardSurfaceReason, rootUnavailable: Boolean, walkTruncated: Boolean,
                abortedStale: Boolean, startedAt: Long, finishedAt: Long) {
                record("READ", "req=${request.id} trigger=${request.trigger} decision=$decision reason=$reason rootUnavailable=$rootUnavailable truncated=$walkTruncated stale=$abortedStale start=$startedAt end=$finishedAt")
                reads.add(request.id)
                if (request.trigger != "r14-positive-a" || !a.compareAndSet(null, request)) return
                runCatching {
                    check(decision == KeyguardCardVisibility.SHOW_FULL && reason == KeyguardSurfaceReason.MAIN_CONFIRMED &&
                        !rootUnavailable && !walkTruncated && !abortedStale) { "A incomplete/non-MAIN: $decision/$reason" }
                    aStarted.set(startedAt)
                    workerHeld.countDown()
                    check(releaseWorker.await(25, TimeUnit.SECONDS)) { "A worker barrier timed out" }
                }.onFailure { failure.compareAndSet(null, it); workerHeld.countDown() }
            }
            override fun afterApply(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility) {
                val owner = service ?: return
                val state = owner.inspectionStateForTest()
                applied[request.id] = decision
                val roots = WindowInspector.getGlobalWindowViews().count {
                    (it.layoutParams as? WindowManager.LayoutParams)?.type == WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
                }
                record("APPLIED", "req=${request.id} trigger=${request.trigger} raw=$decision attached=${state.attached} roots=$roots pending=${state.pending?.id ?: "none"} pendingTrigger=${state.pending?.trigger ?: "none"} authority=${state.authority}")
                if (request.trigger == "r14-controlled-withdraw") {
                    runCatching {
                        check(decision == KeyguardCardVisibility.HIDDEN_OCCLUDED && !state.attached && roots == 0) { "controlled withdrawal did not remove the real root" }
                        check(state.wake != null && state.authority.attachGeneration == originalGeneration.get())
                        schedule(owner, "r14-positive-a")
                        check(owner.inspectionStateForTest().pending?.trigger == "r14-positive-a") { "A not pending after actual withdrawal" }
                    }.onFailure { failure.compareAndSet(null, it); workerHeld.countDown() }
                }
                if (request.id == a.get()?.id) {
                    aAttached.set(state.attached)
                    aGeneration.set(state.authority.attachGeneration)
                    if (roots != if (state.attached) 1 else 0) failure.compareAndSet(null, IllegalStateException("A root count inconsistent: $roots"))
                    if (state.pending?.trigger == "authorityReconcile:attach") replacement.set(state.pending)
                    // On stock, attach-reconciliation may have replaced B. A
                    // further labelled C checks the real pending replacement,
                    // rather than pretending that B itself was read.
                    if (exclude && !lateOnly && state.attached) runCatching {
                        val previous = state.pending
                        check(previous?.trigger == "authorityReconcile:attach") { "stock add lacked observed attach reconciliation: ${previous?.trigger}" }
                        sendControlled(owner, "C", aStarted.get(), previous.id, c)
                    }.onFailure { failure.compareAndSet(null, it) }
                    aApplied.countDown()
                }
            }
        }
        try {
            record("RUN", "source=$source run=$runId case=$name pid=${android.os.Process.myPid()} mode=SURFACE_LIVE")
            assertFalse("fresh service required", FluviKeyguardCardServiceRegistry.connected)
            assertFalse("disposable insecure keyguard required", keyguard.isDeviceSecure)
            check(savedLock == "true" || savedLock == "false")
            setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, otherServices())
            await("old service disconnected", 8_000) { !FluviKeyguardCardServiceRegistry.connected }
            shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard")
            await("unlocked", 5_000) { power.isInteractive && !keyguard.isKeyguardLocked }
            shell("locksettings set-disabled false")
            check(context.getSharedPreferences("fluvi_keyguard_orb_diagnostic_route", Context.MODE_PRIVATE).edit().putString("mode", "SURFACE_LIVE").commit())
            instrumentation.runOnMainSync {
                FluviKeyguardCardSettings.update(context, mapOf("requested" to true, "showFinancialDetails" to true, "presentationMode" to "orb", "animationMode" to "orbOnly"))
                val epoch = maxOf(SystemClock.elapsedRealtimeNanos(), (savedMaterial.second["publisherEpoch"] as? Long ?: -1L) + 1L)
                check(FluviKeyguardMaterialStore.publish(context, materialProfile(), epoch))
            }
            captureId = KeyguardCardDiagnostics.startCapture(context, source, "debug", "FULL")["captureId"].toString()
            captureStarted = true
            setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, listOf(otherServices(), component.flattenToString()).filter { it.isNotBlank() }.joinToString(":"))
            setSecure(Settings.Secure.ACCESSIBILITY_ENABLED, "1")
            await("service connected", 10_000) { FluviKeyguardCardServiceRegistry.connected }
            service = checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation())
            synchronizedKey(KeyEvent.KEYCODE_SLEEP)
            await("locked display off", 8_000) {
                val display = context.getSystemService(DisplayManager::class.java).getDisplay(Display.DEFAULT_DISPLAY)
                !power.isInteractive && display?.state == Display.STATE_OFF && keyguard.isKeyguardLocked
            }
            synchronizedKey(KeyEvent.KEYCODE_WAKEUP)
            await("initial real LIVE attachment", 20_000) { sample(service!!).let { it.first.attached && it.second.effective == KeyguardOrbRenderMode.SURFACE_LIVE } }
            instrumentation.runOnMainSync {
                val owner = checkNotNull(service)
                val state = owner.inspectionStateForTest()
                check(state.attached && state.wake != null)
                originalGeneration.set(state.authority.attachGeneration)
                owner.inspectionProbeForTest = probe
                schedule(owner, "r14-controlled-withdraw")
            }
            assertTrue("A acquisition barrier not reached", workerHeld.await(20, TimeUnit.SECONDS))
            failure.get()?.let { throw AssertionError("INVALID fixture before A handoff", it) }
            val aRequest = checkNotNull(a.get())
            instrumentation.runOnMainSync {
                val state = checkNotNull(service).inspectionStateForTest()
                check(!state.attached && state.authority.matches(aRequest)) { "A lacks current detached authority" }
                check(WindowInspector.getGlobalWindowViews().none { (it.layoutParams as? WindowManager.LayoutParams)?.type == WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY }) { "A has an actual attached accessibility root" }
                record("A_HELD", "req=${aRequest.id} start=${aStarted.get()} pending=${state.pending?.id ?: "none"} authority=${state.authority}")
                if (lateOnly) check(state.pending == null) { "late-only control already has pending work" }
            }
            if (exclude && !lateOnly) establishShade("before-a")
            if (!lateOnly) instrumentation.runOnMainSync {
                sendControlled(checkNotNull(service), "B", aStarted.get(), null, b)
            }
            check(frameworkEvents.get() > 0) { "no framework ingress mapping observed" }
            releaseWorker.countDown()
            assertTrue("A Main apply not reached", aApplied.await(15, TimeUnit.SECONDS))
            failure.get()?.let { throw AssertionError("INVALID fixture at A apply", it) }
            if (lateOnly) {
                check(aAttached.get()) { "late-only A did not attach" }
                establishShade("after-a")
                instrumentation.runOnMainSync { sendControlled(checkNotNull(service), "C", aStarted.get(), null, c) }
            }
            val actualSuccessor = if (lateOnly || (exclude && aAttached.get())) c.get()
                else if (aAttached.get()) replacement.get() else b.get()
            val successor = checkNotNull(actualSuccessor) { "actual successor identity missing" }
            await("the identified successor's actual application", 20_000) { applied.containsKey(successor.id) }
            failure.get()?.let { throw AssertionError("INVALID fixture after successor", it) }
            if (exclude) await("actual later withdrawal", 10_000) { !sample(checkNotNull(service)).first.attached }
            else await("fresh MAIN restores once", 10_000) { sample(checkNotNull(service)).first.attached }
            val final = sample(checkNotNull(service))
            val roots = countOverlayRoots()
            check(reads.contains(successor.id)) { "actual successor ${successor.id} was not physically read" }
            val successorDecision = checkNotNull(applied[successor.id]) { "actual successor was not applied" }
            if (exclude) check(successorDecision == KeyguardCardVisibility.HIDDEN_SHADE) { "independent shade was not the applied exclusion: $successorDecision" }
            else check(successorDecision == KeyguardCardVisibility.SHOW_FULL) { "MAIN successor not applied: $successorDecision" }
            record("RESULT", "a=${aRequest.id} b=${b.get()?.id ?: "none"} r=${replacement.get()?.id ?: "none"} c=${c.get()?.id ?: "none"} read=${successor.id} readDecision=$successorDecision initialGeneration=${originalGeneration.get()} aAttached=${aAttached.get()} aGeneration=${aGeneration.get()} finalGeneration=${final.first.authority.attachGeneration} finalAttached=${final.first.attached} roots=$roots exclusionWitness=$exclude physicalPresentation=UNOBSERVED")
            if (exclude && !lateOnly) {
                assertFalse("R14 candidate assertion: pending B must suppress the excess A add", aAttached.get())
                assertEquals("withheld episode creates no new attachment", originalGeneration.get(), aGeneration.get())
                assertEquals("no residual accessibility root", 0, roots)
            } else if (!exclude) {
                assertEquals("one fresh return only", originalGeneration.get() + 1, final.first.authority.attachGeneration)
                assertEquals(1, roots)
            } else assertEquals("late-only A attaches once", originalGeneration.get() + 1, aGeneration.get())
        } catch (error: Throwable) {
            record("FAILURE", "type=${error.javaClass.simpleName} message=${error.message?.replace(' ', '_') ?: "none"}")
            throw error
        } finally {
            releaseWorker.countDown()
            service?.inspectionProbeForTest = null
            var cleanupFailure: Throwable? = null
            if (captureStarted) runCatching { File(output, "capture.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"].toString()) }
                .onFailure { cleanupFailure = it; record("FREEZE_FAILURE", it.javaClass.simpleName) }
            runCatching {
                shell("cmd statusbar collapse")
                setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, otherServices())
                await("service disconnect", 8_000) { !FluviKeyguardCardServiceRegistry.connected }
                restore(savedSettings); restore(savedMaterial); restore(savedMode)
                shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard")
                if (savedLock == "true" || savedLock == "false") shell("locksettings set-disabled $savedLock")
                setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, savedServices)
                setSecure(Settings.Secure.ACCESSIBILITY_ENABLED, savedEnabled)
            }.onFailure { cleanupFailure = cleanupFailure ?: it; record("CLEANUP_FAILURE", "${it.javaClass.simpleName}:${it.message}") }
            File(output, "fixture.txt").writeText(records.toString())
            cleanupFailure?.let { throw AssertionError("R14 freeze or cleanup failed", it) }
        }
    }

    /** Capture the actual pending slot under Main. The SystemUI identity is
     * controlled metadata, explicitly distinct from observed framework rows. */
    private fun sendControlled(owner: FluviKeyguardCardService, role: String, aStart: Long,
        expectedPrevious: Long?, target: AtomicReference<KeyguardCardInspectionRequest?>) {
        while (SystemClock.uptimeMillis() <= aStart) SystemClock.sleep(1)
        val before = owner.inspectionStateForTest()
        if (expectedPrevious != null) check(before.pending?.id == expectedPrevious)
        val window = systemUiWindowId()
        val eventAt = SystemClock.uptimeMillis()
        owner.acceptAccessibilityMetadataForTest(KeyguardAccessibilityEventMeta(
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED, window, Display.DEFAULT_DISPLAY, 0,
            "com.android.systemui", eventAt,
        ))
        val after = owner.inspectionStateForTest()
        val next = checkNotNull(after.pending) { "$role not physically pending" }
        check(next.trigger == "window" && next.eventTimeUptimeMs == eventAt && after.authority.matches(next))
        target.set(next)
        record("OFFER", "role=$role origin=controlled_framework_metadata window=$window event=$eventAt callback=${next.triggerReceivedUptimeMs} before=${before.pending?.id ?: "none"} after=${next.id} authority=${after.authority}")
    }

    private fun establishShade(label: String) {
        shell("cmd statusbar expand-settings")
        var witnessed = false
        await("independent SystemUI shade marker", 8_000) {
            witnessed = shadeMarkerSeen()
            witnessed
        }
        check(witnessed)
        val bitmap = checkNotNull(automation.takeScreenshot())
        File(output, "$label-shade.png").outputStream().use { bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, it) }
        bitmap.recycle()
        record("INDEPENDENT_EXCLUSION", "kind=actual_systemui_shade marker=true screenshot=$label-shade.png window=${systemUiWindowId()} locked=${keyguard.isKeyguardLocked}")
        check(keyguard.isKeyguardLocked)
    }
    private fun shadeMarkerSeen(): Boolean {
        val ids = listOf("com.android.systemui:id/quick_settings_panel", "com.android.systemui:id/quick_qs_panel", "com.android.systemui:id/qs_frame", "com.android.systemui:id/settings_button", "com.android.systemui:id/notification_shade_shortcut", "com.android.systemui:id/split_shade_status_bar")
        return automation.windows.any { window ->
            val root: AccessibilityNodeInfo = window.root ?: return@any false
            try { root.packageName?.toString() == "com.android.systemui" && ids.any { id -> root.findAccessibilityNodeInfosByViewId(id).any { it.isVisibleToUser } } }
            finally { root.recycle() }
        }
    }
    private fun systemUiWindowId(): Int = automation.windows.firstOrNull { window ->
        val root = window.root ?: return@firstOrNull false
        try { root.packageName?.toString() == "com.android.systemui" } finally { root.recycle() }
    }?.id ?: error("actual SystemUI window not observed")
    private fun sample(owner: FluviKeyguardCardService): Pair<KeyguardInspectionStateForTest, KeyguardOrbRenderModeStatus> {
        lateinit var result: Pair<KeyguardInspectionStateForTest, KeyguardOrbRenderModeStatus>
        instrumentation.runOnMainSync { result = owner.inspectionStateForTest() to owner.renderModeStatus() }
        return result
    }
    private fun countOverlayRoots(): Int {
        var count = 0
        instrumentation.runOnMainSync { count = WindowInspector.getGlobalWindowViews().count { (it.layoutParams as? WindowManager.LayoutParams)?.type == WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY } }
        return count
    }
    private fun record(stage: String, detail: String) = synchronized(records) { records.appendLine("R14 stage=$stage up=${SystemClock.uptimeMillis()} $detail") }
    private fun shell(command: String): String = ParcelFileDescriptor.AutoCloseInputStream(automation.executeShellCommand(command)).bufferedReader().use { it.readText() }
    private fun synchronizedKey(code: Int) {
        val down = SystemClock.uptimeMillis()
        for (action in intArrayOf(KeyEvent.ACTION_DOWN, KeyEvent.ACTION_UP)) {
            check(automation.injectInputEvent(KeyEvent(down, SystemClock.uptimeMillis(), action, code, 0, 0, -1, 0, 0, InputDevice.SOURCE_KEYBOARD), true))
        }
    }
    private fun setSecure(key: String, value: String?) {
        automation.adoptShellPermissionIdentity(Manifest.permission.WRITE_SECURE_SETTINGS)
        try { check(Settings.Secure.putString(context.contentResolver, key, value)) } finally { automation.dropShellPermissionIdentity() }
    }
    private fun await(label: String, timeout: Long, condition: () -> Boolean) {
        val end = SystemClock.uptimeMillis() + timeout
        while (SystemClock.uptimeMillis() < end) { if (condition()) return; SystemClock.sleep(50) }
        error("$label timed out")
    }
    private fun preferences(name: String): Pair<SharedPreferences, Map<String, *>> = context.getSharedPreferences(name, Context.MODE_PRIVATE).let { it to HashMap(it.all) }
    private fun restore(saved: Pair<SharedPreferences, Map<String, *>>) {
        val edit = saved.first.edit().clear()
        saved.second.forEach { (key, value) -> when (value) {
            is Boolean -> edit.putBoolean(key, value); is Int -> edit.putInt(key, value); is Long -> edit.putLong(key, value)
            is Float -> edit.putFloat(key, value); is String -> edit.putString(key, value)
            is Set<*> -> edit.putStringSet(key, value.filterIsInstance<String>().toSet())
        } }
        check(edit.commit())
    }
    private fun materialProfile(): Map<String, Any> = mapOf(
        "schemaVersion" to 1, "shaderAbiVersion" to 6, "sourceShaderHash" to KeyguardMaterialProfile.SOURCE_SHADER_HASH,
        "publisherSession" to "r14-recovery", "publisherRevision" to 1L, "sceneIdentity" to "fixture|balance|month",
        "effectId" to "dualTide", "effectShaderId" to 1, "phase" to .25, "elapsedSeconds" to 1.0, "phaseSpeed" to .4,
        "colors" to listOf(0xff104f7c.toInt(), 0xff62c7dc.toInt(), 0xff8366dc.toInt()),
        "stops" to listOf(0.0, .5, 1.0), "opacity" to 1.0, "paletteSplitPercent" to 50.0,
        "commonSettings" to List(40) { .2 }, "background" to portal(true), "interior" to portal(false),
        "referenceWidth" to 390.0, "referenceHeight" to 220.0,
    )
    private fun portal(enabled: Boolean): Map<String, Any> = mapOf("enabled" to enabled, "effectIndex" to 0,
        "phase" to 0.0, "phaseSpeed" to .2, "paletteCenterPercent" to 50.0, "paletteWindowPercent" to 68.0,
        "rotationEnabled" to false, "rotationSpeed" to 0.0, "settings" to List(12) { .2 })
}
