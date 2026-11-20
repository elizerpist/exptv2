package com.fluvi.app.lockscreen

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.KeyguardManager
import android.app.UiAutomation
import android.content.Intent
import android.graphics.Bitmap
import android.os.SystemClock
import android.os.ParcelFileDescriptor
import android.os.PowerManager
import android.provider.Settings
import android.view.Display
import android.view.SurfaceView
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.view.inspector.WindowInspector
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.fluvi.app.R
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

/** Real service controls only. Screenshots here are geometry/fixture aids;
 * an independent host recording and calibrated analysis own visual verdicts. */
@RunWith(AndroidJUnit4::class)
class KeyguardR15ServiceContractInstrumentationTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val context get() = instrumentation.targetContext
    private val keyguard get() = context.getSystemService(KeyguardManager::class.java)
    private lateinit var automation: UiAutomation

    /** Holds the real service worker immediately before its physical read.
     * The controller changes the actual setting and independently releases the
     * worker after the real observer has invalidated that wake's opportunity. */
    @Test fun r15MotionOffInvalidatesIssuedServiceOpportunity() {
        val args = InstrumentationRegistry.getArguments()
        val source = requireNotNull(args.getString("sourceSha"))
        require(source.matches(Regex("[0-9a-f]{40}")))
        assertEquals("SURFACE_LIVE", args.getString("r12Mode"))
        val runId = UUID.fromString(requireNotNull(args.getString("runUuid"))).toString()
        val output = File(context.filesDir, "keyguard-service-probe/r15-contract/$runId/motion-service")
        check(!output.exists() && output.mkdirs())
        automation = instrumentation.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        val originalScale = Settings.Global.getString(context.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE)
        require(originalScale == null || originalScale.matches(Regex("[0-9]+(?:\\.[0-9]+)?")))
        val held = CountDownLatch(1)
        val release = CountDownLatch(1)
        val observerOff = CountDownLatch(1)
        val readFinished = CountDownLatch(1)
        val claimed = AtomicBoolean(false)
        val requestRef = AtomicReference<KeyguardCardInspectionRequest?>()
        val observationRef = AtomicReference<KeyguardR15AcquisitionTestHooks.Observation?>()
        val failure = AtomicReference<Throwable?>()
        val serviceRef = AtomicReference<FluviKeyguardCardService?>()
        val rows = java.util.Collections.synchronizedList(mutableListOf<String>())
        fun record(message: String) { rows += "up=${SystemClock.uptimeMillis()} $message" }
        fun setScale(value: String?) {
            if (value == null) shell("settings delete global animator_duration_scale")
            else shell("settings put global animator_duration_scale $value")
            val actual = Settings.Global.getString(context.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE)
            check(if (value == null) actual == null else actual?.toFloatOrNull() == value.toFloatOrNull()) {
                "motion setting did not reach the requested value"
            }
        }
        fun gateState(service: FluviKeyguardCardService): Pair<KeyguardInspectionAuthority?, Boolean> {
            val lock = checkNotNull(FluviKeyguardCardService::class.java.getDeclaredField("queueLock").apply { isAccessible = true }.get(service))
            val gate = checkNotNull(FluviKeyguardCardService::class.java.getDeclaredField("firstAcquisition").apply { isAccessible = true }.get(service))
            return synchronized(lock) {
                val type = gate.javaClass
                val owner = type.getDeclaredField("owner").apply { isAccessible = true }.get(gate) as KeyguardInspectionAuthority?
                val eligible = type.getDeclaredField("eligible").apply { isAccessible = true }.getBoolean(gate)
                val consumed = type.getDeclaredField("consumed").apply { isAccessible = true }.getBoolean(gate)
                owner to (eligible && !consumed)
            }
        }
        setScale("1")
        KeyguardR15AcquisitionTestHooks.stockArm = false
        KeyguardR15AcquisitionTestHooks.observeIneligible = true
        KeyguardR15AcquisitionTestHooks.motionObserver = { allowed -> if (!allowed) observerOff.countDown() }
        KeyguardR15AcquisitionTestHooks.observer = { observation ->
            if (observation.request.id == requestRef.get()?.id) {
                observationRef.set(observation)
                readFinished.countDown()
            }
        }
        val timing = KeyguardR12ServiceTimingInstrumentationTest()
        timing.serviceConnectedControl = { service ->
            serviceRef.set(service)
            service.inspectionProbeForTest = object : KeyguardInspectionProbeForTest {
                override fun started(request: KeyguardCardInspectionRequest) {
                    val state = gateState(service)
                    if (state.second && state.first?.matches(request) == true && claimed.compareAndSet(false, true)) {
                        requestRef.set(request)
                        record("HELD req=${request.id} session=${request.session} wake=${request.wakeGeneration} eligible=true")
                        held.countDown()
                        if (!release.await(20, TimeUnit.SECONDS)) {
                            failure.compareAndSet(null, IllegalStateException("independent controller did not release reader"))
                        }
                    }
                }
            }
        }
        val controller = Thread({
            try {
                check(held.await(35, TimeUnit.SECONDS)) { "no issued eligible service opportunity reached the read boundary" }
                val service = checkNotNull(serviceRef.get())
                val request = checkNotNull(requestRef.get())
                val power = context.getSystemService(PowerManager::class.java)
                await("awake locked display while reader held", 8_000) { power.isInteractive && keyguard.isKeyguardLocked }
                setScale("0")
                check(observerOff.await(8, TimeUnit.SECONDS)) { "service's motion observer did not run" }
                val after = gateState(service)
                check(after.first?.matches(request) == true && !after.second) { "issued authority changed or remained eligible" }
                record("OBSERVER_OFF req=${request.id} authorityCurrent=true eligible=false")
                release.countDown()
                check(readFinished.await(20, TimeUnit.SECONDS)) { "held request did not complete its actual read" }
                val observation = checkNotNull(observationRef.get())
                val t = observation.result.timing
                record("READ req=${request.id} eligible=${observation.eligible} rootCalls=${t.activeRootCallCount} " +
                    "rootFlags=${t.activeRootPrefetchFlags ?: "UNOBSERVED"} childCalled=${observation.firstChildCalled} " +
                    "childFlags=${observation.firstChildFlags ?: "UNOBSERVED"} decision=${observation.decision} reason=${observation.reason}")
                check(!observation.eligible) { "motion-off request still consumed the experimental hint" }
                check(t.activeRootCallCount == 1 && t.activeRootPrefetchFlags == 36) {
                    "fixture did not observe the expected real stock-argument root call"
                }
            } catch (error: Throwable) {
                failure.compareAndSet(null, error)
                record("CONTROL_FAILURE ${error.javaClass.simpleName}:${error.message}")
            } finally {
                release.countDown()
                runCatching { setScale("1") }.onFailure { failure.compareAndSet(null, it) }
            }
        }, "r15-motion-independent-controller")
        controller.start()
        var fixtureFailure: Throwable? = null
        try {
            timing.fourRealWakeCyclesUseRequestedRoute()
            controller.join(45_000)
            check(!controller.isAlive) { "motion controller survived the fixture" }
            failure.get()?.let { throw AssertionError("actual-service motion control failed", it) }
            assertTrue("actual service did not complete the held request", observationRef.get() != null)
        } catch (error: Throwable) {
            fixtureFailure = error
            throw error
        } finally {
            release.countDown()
            controller.interrupt()
            controller.join(10_000)
            if (controller.isAlive) failure.compareAndSet(null, IllegalStateException("motion controller survived cleanup"))
            serviceRef.get()?.inspectionProbeForTest = null
            timing.serviceConnectedControl = null
            KeyguardR15AcquisitionTestHooks.observer = null
            KeyguardR15AcquisitionTestHooks.observeIneligible = false
            KeyguardR15AcquisitionTestHooks.motionObserver = null
            KeyguardR15AcquisitionTestHooks.stockArm = false
            runCatching { setScale(originalScale) }.onFailure { failure.compareAndSet(null, it) }
            File(output, "fixture.txt").writeText(synchronized(rows) { rows.joinToString("\n", postfix = "\n") })
            failure.get()?.let {
                if (fixtureFailure != null) fixtureFailure.addSuppressed(it)
                else throw AssertionError("actual-service motion control or cleanup failed", it)
            }
        }
    }

    private fun shell(command: String): String =
        ParcelFileDescriptor.AutoCloseInputStream(automation.executeShellCommand(command)).bufferedReader().use { it.readText() }

    @Test fun firstCorrectServiceComposite() {
        val args = InstrumentationRegistry.getArguments()
        val source = requireNotNull(args.getString("sourceSha"))
        require(source.matches(Regex("[0-9a-f]{40}")))
        val runId = UUID.fromString(requireNotNull(args.getString("runUuid"))).toString()
        val route = KeyguardOrbRenderMode.entries.single { it.name == args.getString("r12Mode") }
        val output = File(context.filesDir, "keyguard-service-probe/r15-contract/$runId/first-composite")
        check(!output.exists() && output.mkdirs())
        automation = instrumentation.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        automation.serviceInfo = automation.serviceInfo.apply {
            flags = flags or AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
        }
        val rows = mutableListOf<String>()
        fun emit(stage: String, detail: String) {
            rows += "stage=$stage uptimeMs=${SystemClock.uptimeMillis()} source=$source run=$runId route=${route.name} $detail"
        }
        val timing = KeyguardR12ServiceTimingInstrumentationTest()
        timing.firstVisibleControl = { actualRoute ->
            check(actualRoute == route && keyguard.isKeyguardLocked)
            val first = sample()
            check(first.attached && first.attachment > 0 && first.wake > 0 && first.route == route)
            val beforeBounds = bounds(route)
            screenshot(output, "first-visible", ::emit)
            emit("FIRST", "session=${first.session} wake=${first.wake} attachment=${first.attachment} display=0 bounds=${beforeBounds.joinToString(",")} pixels=UNCLASSIFIED")
            var occluderStarted = false
            try {
                val started = SystemClock.uptimeMillis()
                instrumentation.context.startActivity(Intent().setClassName("com.fluvi.app.test",
                    "com.fluvi.app.lockscreen.KeyguardR14ControlledOccluderActivity")
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                occluderStarted = true
                await("independent test window", 10_000) { occluderWindowId() != null }
                val window = checkNotNull(occluderWindowId())
                await("independent green control pixels", 10_000) { greenControlVisible() }
                screenshot(output, "actual-cover", ::emit)
                emit("COVER", "window=$window display=0 started=$started locked=${keyguard.isKeyguardLocked}")
                await("actual service withdrawal under independent cover", 15_000) { !sample().attached }
                check(keyguard.isKeyguardLocked)
                check(automation.performGlobalAction(AccessibilityService.GLOBAL_ACTION_BACK))
                occluderStarted = false
                await("independent cover removed", 10_000) { occluderWindowId() == null }
                await("same-wake service return", 20_000) {
                    val state = sample()
                    keyguard.isKeyguardLocked && state.attached && state.attachment > first.attachment && state.route == route &&
                        state.session == first.session && state.wake == first.wake
                }
                val returned = sample()
                val returnBounds = bounds(route)
                screenshot(output, "returned-visible", ::emit)
                emit("RETURN", "session=${returned.session} wake=${returned.wake} firstAttachment=${first.attachment} attachment=${returned.attachment} display=0 " +
                    "bounds=${returnBounds.joinToString(",")} pixels=UNCLASSIFIED")
                assertTrue("same-wake return must use a fresh attachment", returned.attachment > first.attachment)
            } finally {
                if (occluderStarted) automation.performGlobalAction(AccessibilityService.GLOBAL_ACTION_BACK)
            }
        }
        try {
            timing.fourRealWakeCyclesUseRequestedRoute()
            assertTrue("first/cover/return fixture did not run", rows.any { it.startsWith("stage=RETURN ") })
        } finally {
            timing.firstVisibleControl = null
            File(output, "fixture.txt").writeText(rows.joinToString("\n", postfix = "\n") +
                "visualQualification=NOT_ESTABLISHED independentRecordingRequired=true\n")
        }
    }

    private data class ServiceSample(val attached: Boolean, val attachment: Long, val session: Long,
                                     val wake: Long, val route: KeyguardOrbRenderMode?)

    private fun sample(): ServiceSample {
        var value = ServiceSample(false, 0, 0, 0, null)
        instrumentation.runOnMainSync {
            val service = FluviKeyguardCardServiceRegistry.serviceForInstrumentation()
            if (service != null) {
                val state = service.inspectionStateForTest()
                value = ServiceSample(state.attached, state.authority.attachGeneration, state.authority.serviceSession,
                    state.authority.wakeGeneration, service.renderModeStatus().effective)
            }
        }
        return value
    }

    private fun bounds(route: KeyguardOrbRenderMode): List<Int> {
        var result: List<Int>? = null
        instrumentation.runOnMainSync {
            val roots = WindowInspector.getGlobalWindowViews().filter {
                (it.layoutParams as? WindowManager.LayoutParams)?.type == WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
            }
            fun surfaces(view: View): List<SurfaceView> =
                (if (view is SurfaceView && view.isAttachedToWindow && view.holder.surface.isValid) listOf(view) else emptyList()) +
                    (if (view is ViewGroup) (0 until view.childCount).flatMap { surfaces(view.getChildAt(it)) } else emptyList())
            val view = if (route == KeyguardOrbRenderMode.LEGACY_R11) {
                roots.mapNotNull { it.findViewById<View>(R.id.fluvi_financial_snapshot_orb) }
                    .single { it.isAttachedToWindow && it.visibility == View.VISIBLE }
            } else roots.flatMap(::surfaces).single()
            check(view.display?.displayId == Display.DEFAULT_DISPLAY && view.width > 0 && view.height > 0)
            val location = IntArray(2)
            view.getLocationOnScreen(location)
            result = listOf(location[0], location[1], location[0] + view.width, location[1] + view.height)
        }
        return checkNotNull(result)
    }

    private fun screenshot(output: File, label: String, emit: (String, String) -> Unit) {
        val begin = SystemClock.uptimeMillis()
        val bitmap = checkNotNull(automation.takeScreenshot())
        val end = SystemClock.uptimeMillis()
        try {
            check(File(output, "$label.png").outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) })
            emit("SCREEN", "name=$label begin=$begin end=$end width=${bitmap.width} height=${bitmap.height} display=0 class=UNCLASSIFIED")
        } finally { bitmap.recycle() }
    }

    private fun occluderWindowId(): Int? = automation.windows.firstOrNull { window ->
        val root = window.root ?: return@firstOrNull false
        try { root.packageName?.toString() == "com.fluvi.app.test" } finally { root.recycle() }
    }?.takeIf { it.displayId == Display.DEFAULT_DISPLAY }?.id

    private fun greenControlVisible(): Boolean {
        val bitmap = automation.takeScreenshot() ?: return false
        return try {
            var count = 0
            val cx = bitmap.width / 2
            val cy = bitmap.height / 2
            for (y in cy - 16 until cy + 16) for (x in cx - 16 until cx + 16) {
                val color = bitmap.getPixel(x, y)
                val red = android.graphics.Color.red(color)
                val green = android.graphics.Color.green(color)
                val blue = android.graphics.Color.blue(color)
                if (green > 120 && green > 2 * red && 2 * green > 3 * blue) count++
            }
            count >= 900
        } finally { bitmap.recycle() }
    }

    private fun await(label: String, timeout: Long, condition: () -> Boolean) {
        val deadline = SystemClock.uptimeMillis() + timeout
        while (SystemClock.uptimeMillis() < deadline) {
            if (condition()) return
            SystemClock.sleep(50)
        }
        error("$label timed out")
    }
}
