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
import android.view.SurfaceView
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.view.inspector.WindowInspector
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.fluvi.app.lockscreen.material.FluviKeyguardMaterialStore
import com.fluvi.app.lockscreen.material.KeyguardMaterialProfile
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.util.UUID

/** A real-service timing control. It observes producer/holder activity and
 * removal, not composited pixels or physical presentation. Each invocation
 * must be launched by the host in a fresh process for one requested mode. */
@RunWith(AndroidJUnit4::class)
class KeyguardR12ServiceTimingInstrumentationTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val context get() = instrumentation.targetContext
    private val keyguard get() = context.getSystemService(KeyguardManager::class.java)
    private val power get() = context.getSystemService(PowerManager::class.java)
    private lateinit var automation: UiAutomation
    private lateinit var output: File
    private val evidence = StringBuilder()
    private var naturalComparison = false
    /** Optional test-only control at the first real authorized attachment. */
    internal var firstVisibleControl: ((KeyguardOrbRenderMode) -> Unit)? = null
    internal var serviceConnectedControl: ((FluviKeyguardCardService) -> Unit)? = null

    /** One process/arm only. The host must run both reverse-order blocks on
     * one device and collect independent video; this method is not a visual
     * or performance pass by itself. */
    @Test fun r15BalancedFirstAcquisition() {
        val args = InstrumentationRegistry.getArguments()
        val arm = requireNotNull(args.getString("r15Arm"))
        require(arm == "stock" || arm == "candidate")
        val block = requireNotNull(args.getString("r15Block")).toInt()
        require(block in 1..2)
        val runId = UUID.fromString(requireNotNull(args.getString("runUuid"))).toString()
        val source = requireNotNull(args.getString("sourceSha"))
        require(source.matches(Regex("[0-9a-f]{40}")))
        val observations = java.util.Collections.synchronizedList(mutableListOf<KeyguardR15AcquisitionTestHooks.Observation>())
        val overflow = java.util.concurrent.atomic.AtomicInteger()
        check(!FluviKeyguardCardServiceRegistry.connected)
        KeyguardR15AcquisitionTestHooks.stockArm = arm == "stock"
        KeyguardR15AcquisitionTestHooks.observer = { item ->
            synchronized(observations) {
                if (observations.size < 64) observations.add(item) else overflow.incrementAndGet()
            }
        }
        naturalComparison = true
        try {
            fourRealWakeCyclesUseRequestedRoute()
        } finally {
            KeyguardR15AcquisitionTestHooks.observer = null
            KeyguardR15AcquisitionTestHooks.stockArm = false
            naturalComparison = false
            val directory = File(context.filesDir, "keyguard-service-probe/r15/$runId/acquisition")
            check(directory.mkdirs() || directory.isDirectory)
            val lines = synchronized(observations) { observations.toList() }.map { item ->
                val request = item.request
                val timing = item.result.timing
                org.json.JSONObject().apply {
                    put("source", source); put("runUuid", runId); put("arm", arm); put("block", block)
                    put("pid", android.os.Process.myPid()); put("session", request.session); put("wake", request.wakeGeneration)
                    put("request", request.id); put("capture", request.diagnosticContext?.captureId ?: org.json.JSONObject.NULL)
                    put("visibilityEpoch", request.visibilityEpoch); put("interactionEpoch", request.interactionEpoch)
                    put("attachment", request.attachGeneration); put("freshness", item.ticket.reason.name)
                    put("freshnessRevision", item.ticket.revision); put("authorityMatches", item.ticket.authority.matches(request))
                    put("authorityAtCompletion", item.authorityAtCompletion)
                    put("queued", request.queuedAtUptimeMs); put("inspectionStart", item.inspectionStarted)
                    put("readStart", item.started); put("readEnd", item.finished); put("inspectionEnd", item.inspectionFinished)
                    put("eligible", item.eligible); put("rootCalled", timing.activeRootCallCount > 0)
                    put("rootFlags", timing.activeRootPrefetchFlags ?: org.json.JSONObject.NULL)
                    put("windowId", item.candidate?.id ?: org.json.JSONObject.NULL)
                    put("windowType", item.candidate?.type ?: org.json.JSONObject.NULL)
                    put("displayId", item.candidate?.displayId ?: org.json.JSONObject.NULL)
                    put("childCalled", item.firstChildCalled); put("childCalls", timing.childAcquisitionCount)
                    put("firstChildWindow", item.firstChildWindow ?: org.json.JSONObject.NULL)
                    put("firstChildIndex", item.firstChildIndex ?: org.json.JSONObject.NULL)
                    put("firstChildFlags", item.firstChildFlags ?: org.json.JSONObject.NULL)
                    put("visited", item.result.visitedNodeCount); put("reader", timing.readerStrategy)
                    put("cacheClear", timing.cacheClearResult); put("fallback", timing.fallbackReason ?: org.json.JSONObject.NULL)
                    put("rootUnavailable", item.result.rootUnavailable); put("walkTruncated", item.result.walkTruncated)
                    put("abortedStale", item.result.abortedStale); put("decision", item.decision.name); put("reason", item.reason.name)
                    put("windows", org.json.JSONArray().apply {
                        item.result.snapshots.forEach { snapshot ->
                            put(org.json.JSONObject().put("id", snapshot.windowId).put("type", snapshot.type)
                                .put("display", snapshot.displayId).put("own", snapshot.ownOverlay))
                        }
                    })
                }.toString()
            }
            File(directory, "$arm-block$block.jsonl").writeText(lines.joinToString("\n", postfix = if (lines.isEmpty()) "" else "\n"))
            File(directory, "$arm-block$block-overflow.txt").writeText("${overflow.get()}\n")
        }
        val rows = synchronized(observations) { observations.toList() }
        assertEquals("bounded first-read observer overflow", 0, overflow.get())
        assertTrue("no eligible first active-root call; later stock calls are not a substitute",
            rows.any { it.result.timing.activeRootCallCount > 0 && it.result.timing.activeRootPrefetchFlags == if (arm == "stock") 36 else 0 })
        assertTrue(rows.all { it.stock == (arm == "stock") && it.ticket.authority.matches(it.request) &&
            (it.firstChildCalled || it.result.timing.childAcquisitionCount == 0) })
    }

    /** A real-service acquisition control only. This does not qualify first
     * composited pixels, device-visible motion or a performance improvement. */
    @Test fun r15FirstReadIsRootOnlyAndLaterReadRemainsStock() {
        assertEquals("SURFACE_LIVE", InstrumentationRegistry.getArguments().getString("r12Mode"))
        fourRealWakeCyclesUseRequestedRoute()
        val report = File(output, "capture.txt").readText()
        val causes = report.lineSequence().filter {
            it.startsWith(" FIRST_INSPECTION ") || it.startsWith(" SHOWING_INSPECTION ") ||
                it.startsWith(" ACTUAL_WITHDRAWAL_INSPECTION ")
        }.toList()
        File(output, "r15-acquisition-causes.txt").writeText(causes.joinToString("\n", postfix = "\n"))
        assertTrue("no first physical active-root call used 0 with accepted children 36",
            causes.any { it.startsWith(" FIRST_INSPECTION ") && it.contains("rootFlags=0 ") && it.contains("acceptedChildFlags=36 ") })
        assertTrue("no later physical active-root call retained the stock strategy",
            causes.any { !it.startsWith(" FIRST_INSPECTION ") && it.contains("rootFlags=36 ") })
    }

    @Test fun fourRealWakeCyclesUseRequestedRoute() {
        assertEquals(35, Build.VERSION.SDK_INT)
        val args = InstrumentationRegistry.getArguments()
        val source = requireNotNull(args.getString("sourceSha"))
        require(source.matches(Regex("[0-9a-f]{40}"))) { "missing exact source SHA" }
        val modeText = requireNotNull(args.getString("r12Mode"))
        val mode = KeyguardOrbRenderMode.entries.single { it.name == modeText }
        val runId = UUID.fromString(requireNotNull(args.getString("runUuid"))).toString()
        automation = instrumentation.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        automation.serviceInfo = automation.serviceInfo.apply {
            flags = flags or AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
        }
        output = File(context.filesDir, "keyguard-service-probe/r12-timing/$runId").apply {
            check(!exists() && mkdirs()) { "run directory was reused" }
        }
        val resolver = context.contentResolver
        val savedServices = Settings.Secure.getString(resolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        val savedEnabled = Settings.Secure.getString(resolver, Settings.Secure.ACCESSIBILITY_ENABLED)
        val savedLock = shell("locksettings get-disabled").trim()
        val savedSettings = preferences("fluvi_native_keyguard_card")
        val savedMaterial = preferences("fluvi_keyguard_header_material")
        val savedMode = preferences("fluvi_keyguard_orb_diagnostic_route")
        val failures = mutableListOf<String>()
        var captureStarted = false
        var captureId = "UNOBSERVED"
        val component = ComponentName(context, FluviKeyguardCardService::class.java)
        fun otherServices(): String = savedServices.orEmpty().split(':').filter {
            it.isNotBlank() && ComponentName.unflattenFromString(it) != component
        }.joinToString(":")
        fun sample(): Pair<KeyguardOrbRenderModeStatus?, com.fluvi.app.lockscreen.material.KeyguardOrbSurfaceMetrics.Snapshot?> {
            var result: Pair<KeyguardOrbRenderModeStatus?, com.fluvi.app.lockscreen.material.KeyguardOrbSurfaceMetrics.Snapshot?> = null to null
            instrumentation.runOnMainSync {
                val service = FluviKeyguardCardServiceRegistry.serviceForInstrumentation()
                result = service?.renderModeStatus() to service?.surfaceMetricsForInstrumentation()
            }
            return result
        }
        try {
            assertFalse("service must start in a fresh process", FluviKeyguardCardServiceRegistry.connected)
            assertFalse("test requires a disposable insecure keyguard", keyguard.isDeviceSecure)
            check(savedLock == "true" || savedLock == "false")
            setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, otherServices())
            await("old service disconnected", 8_000) { !FluviKeyguardCardServiceRegistry.connected }
            shell("input keyevent KEYCODE_WAKEUP")
            shell("wm dismiss-keyguard")
            await("initial unlocked state", 5_000) { power.isInteractive && !keyguard.isKeyguardLocked }
            shell("locksettings set-disabled false")
            check(context.getSharedPreferences("fluvi_keyguard_orb_diagnostic_route", Context.MODE_PRIVATE)
                .edit().putString("mode", mode.name).commit())
            instrumentation.runOnMainSync {
                FluviKeyguardCardSettings.update(context, mapOf("requested" to true,
                    "showFinancialDetails" to true, "presentationMode" to "orb", "animationMode" to "orbOnly"))
                val epoch = maxOf(SystemClock.elapsedRealtimeNanos(), (savedMaterial.second["publisherEpoch"] as? Long ?: -1L) + 1L)
                check(FluviKeyguardMaterialStore.publish(context, materialProfile(), epoch))
            }
            val capture = KeyguardCardDiagnostics.startCapture(context, source, "debug", "FULL")
            captureStarted = true
            captureId = capture["captureId"].toString()
            record("PROCESS", "source=$source run=$runId capture=$captureId mode=${mode.name} pid=${android.os.Process.myPid()}")
            val services = listOf(otherServices(), component.flattenToString()).filter { it.isNotBlank() }.joinToString(":")
            setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, services)
            setSecure(Settings.Secure.ACCESSIBILITY_ENABLED, "1")
            await("real accessibility service connected", 10_000) { FluviKeyguardCardServiceRegistry.connected }
            serviceConnectedControl?.invoke(checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation()))
            repeat(4) { index ->
                val name = if (index == 0) "cold" else "warm$index"
                try {
                    synchronizedKey(KeyEvent.KEYCODE_SLEEP)
                    await("$name completed sleep admission", 8_000) {
                        val display = context.getSystemService(DisplayManager::class.java).getDisplay(Display.DEFAULT_DISPLAY)
                        !power.isInteractive && display?.state == Display.STATE_OFF && keyguard.isKeyguardLocked
                    }
                    await("$name previous service window withdrawn", 5_000) { sample().first?.visible != true }
                    if (naturalComparison || firstVisibleControl != null) recordClock(name, "preWake")
                    val wake = SystemClock.uptimeMillis()
                    synchronizedKey(KeyEvent.KEYCODE_WAKEUP)
                    await("$name public wake eligibility", 5_000) { power.isInteractive && keyguard.isKeyguardLocked }
                    if (naturalComparison || firstVisibleControl != null) recordClock(name, "awake")
                    // The injected input is synchronous. Global accessibility
                    // idle is not the service's admission or visibility gate.
                    check(power.isInteractive && keyguard.isKeyguardLocked) { "$name public wake lost eligibility after input" }
                    await("$name actual locked service window", 20_000) {
                        val state = sample().first
                        power.isInteractive && keyguard.isKeyguardLocked && state?.visible == true && state.effective == mode
                    }
                    val attached = SystemClock.uptimeMillis()
                    var surfaceCount = -1
                    instrumentation.runOnMainSync {
                        fun count(view: View): Int = (if (view is SurfaceView && view.holder.surface.isValid) 1 else 0) +
                            (if (view is ViewGroup) (0 until view.childCount).sumOf { count(view.getChildAt(it)) } else 0)
                        surfaceCount = WindowInspector.getGlobalWindowViews().filter {
                            (it.layoutParams as? WindowManager.LayoutParams)?.type == WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
                        }.sumOf(::count)
                    }
                    assertEquals("real service must own the selected holder route", if (mode == KeyguardOrbRenderMode.LEGACY_R11) 0 else 1, surfaceCount)
                    if (mode != KeyguardOrbRenderMode.LEGACY_R11) {
                        await("$name first current target post", 15_000) { (sample().second?.submissions ?: 0L) > 0L }
                        val first = checkNotNull(sample().second)
                        if (mode == KeyguardOrbRenderMode.SURFACE_LIVE) {
                            await("$name distinct successor submission", 10_000) { sample().second?.firstDistinctUptimeMs != null }
                        }
                        if (index == 1 && !naturalComparison) {
                            val intervalStart = SystemClock.uptimeMillis()
                            SystemClock.sleep(5_000)
                            val end = checkNotNull(sample().second)
                            check(end.coherent && end.submissions >= first.submissions)
                            if (mode == KeyguardOrbRenderMode.SURFACE_LIVE) check(end.submissions > first.submissions)
                            record("LOCKED_INTERVAL", "name=$name start=$intervalStart end=${SystemClock.uptimeMillis()} postsStart=${first.submissions} postsEnd=${end.submissions}")
                        }
                        record("WAKE", "name=$name wake=$wake attached=$attached firstPost=${first.firstPostUptimeMs} distinct=${sample().second?.firstDistinctUptimeMs ?: "UNOBSERVED"} meaning=producer_not_presentation")
                    } else {
                        if (index == 1 && !naturalComparison) {
                            val intervalStart = SystemClock.uptimeMillis()
                            SystemClock.sleep(5_000)
                            val state = sample().first
                            check(power.isInteractive && keyguard.isKeyguardLocked && state?.visible == true && state.effective == mode) {
                                "legacy locked interval lost its actual service owner"
                            }
                            record("LOCKED_INTERVAL", "name=$name start=$intervalStart end=${SystemClock.uptimeMillis()} postsStart=UNOBSERVED postsEnd=UNOBSERVED route=LEGACY_R11")
                        }
                        record("WAKE", "name=$name wake=$wake attached=$attached firstPost=UNOBSERVED distinct=UNOBSERVED route=LEGACY_R11")
                    }
                    if (index == 0) firstVisibleControl?.invoke(mode)
                } catch (error: Throwable) {
                    failures += "$name:${error.javaClass.simpleName}:${error.message}"
                    record("FAILURE", "${failures.last()} interactive=${power.isInteractive} locked=${keyguard.isKeyguardLocked} route=${sample().first}")
                } finally {
                    runCatching {
                        if (naturalComparison || firstVisibleControl != null) recordClock(name, "preUnlock")
                        val hide = SystemClock.uptimeMillis()
                        shell("wm dismiss-keyguard")
                        await("$name unlocked and detached", 8_000) { !keyguard.isKeyguardLocked && sample().first?.visible != true }
                        if (naturalComparison || firstVisibleControl != null) recordClock(name, "postUnlock")
                        record("WITHDRAWN", "name=$name trigger=$hide detached=${SystemClock.uptimeMillis()} physicalRemoval=UNOBSERVED")
                    }.onFailure { failures += "$name-cleanup:${it.javaClass.simpleName}:${it.message}" }
                }
            }
        } catch (error: Throwable) {
            failures += "setup:${error.javaClass.simpleName}:${error.message}"
            record("FAILURE", failures.last())
        } finally {
            if (captureStarted) runCatching {
                File(output, "capture.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"].toString())
            }.onFailure { failures += "freeze:${it.javaClass.simpleName}:${it.message}" }
            runCatching {
                setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, otherServices())
                await("service disconnect", 8_000) { !FluviKeyguardCardServiceRegistry.connected }
                restore(savedSettings); restore(savedMaterial); restore(savedMode)
                shell("input keyevent KEYCODE_WAKEUP")
                shell("wm dismiss-keyguard")
                if (savedLock == "true" || savedLock == "false") shell("locksettings set-disabled $savedLock")
                setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, savedServices)
                setSecure(Settings.Secure.ACCESSIBILITY_ENABLED, savedEnabled)
            }.onFailure { failures += "cleanup:${it.javaClass.simpleName}:${it.message}" }
            record("RESULT", if (failures.isEmpty()) "PASS timing_control_only" else "FAIL ${failures.joinToString(" | ")}")
            File(output, "fixture.txt").writeText(evidence.toString())
        }
        assertTrue("R12 service timing failures: ${failures.joinToString(" | ")}", failures.isEmpty())
    }

    private fun record(stage: String, detail: String) { evidence.appendLine("$stage up=${SystemClock.uptimeMillis()} $detail") }
    private fun recordClock(wake: String, phase: String) {
        val before = SystemClock.uptimeMillis()
        val elapsedNs = SystemClock.elapsedRealtimeNanos()
        val after = SystemClock.uptimeMillis()
        record("CLOCK", "name=$wake phase=$phase uptimeBeforeMs=$before elapsedNs=$elapsedNs uptimeAfterMs=$after")
    }
    private fun shell(command: String): String = ParcelFileDescriptor.AutoCloseInputStream(automation.executeShellCommand(command)).bufferedReader().use { it.readText() }
    private fun synchronizedKey(keyCode: Int) {
        val downAt = SystemClock.uptimeMillis()
        for (action in intArrayOf(KeyEvent.ACTION_DOWN, KeyEvent.ACTION_UP)) {
            val event = KeyEvent(downAt, SystemClock.uptimeMillis(), action, keyCode, 0, 0, -1, 0, 0, InputDevice.SOURCE_KEYBOARD)
            check(automation.injectInputEvent(event, true)) { "synchronized key $keyCode was rejected" }
        }
    }
    private fun setSecure(key: String, value: String?) {
        automation.adoptShellPermissionIdentity(Manifest.permission.WRITE_SECURE_SETTINGS)
        try { check(Settings.Secure.putString(context.contentResolver, key, value)) } finally { automation.dropShellPermissionIdentity() }
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
    private fun materialProfile(): Map<String, Any> = mapOf(
        "schemaVersion" to 1, "shaderAbiVersion" to 6, "sourceShaderHash" to KeyguardMaterialProfile.SOURCE_SHADER_HASH,
        "publisherSession" to "r12-service-timing", "publisherRevision" to 1L, "sceneIdentity" to "fixture|balance|month",
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
