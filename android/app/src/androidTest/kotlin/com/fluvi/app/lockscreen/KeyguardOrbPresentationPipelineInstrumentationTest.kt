package com.fluvi.app.lockscreen

import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.InputDevice
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.FrameLayout
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.fluvi.app.R
import com.fluvi.app.lockscreen.material.KeyguardMaterialProfile
import com.fluvi.app.lockscreen.material.KeyguardMaterialTestActivity
import com.fluvi.app.lockscreen.material.KeyguardOrbDirectOutput
import com.fluvi.app.lockscreen.material.KeyguardOrbSurfacePresenter
import com.fluvi.app.lockscreen.material.KeyguardOrbSurfaceWorkerTestHooks
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference
import org.junit.Assert.*
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

/** Android boundary controls. The panel test uses real WMS, compositor and
 * native producer; it is explicitly not a real-keyguard service result. */
@RunWith(AndroidJUnit4::class)
class KeyguardOrbPresentationPipelineInstrumentationTest {
    private val instrumentation get() = InstrumentationRegistry.getInstrumentation()

    @Test fun r18SamplerCanStartReservedWorkWhileMainIsHeld() {
        assumeTrue(Build.VERSION.SDK_INT == 35)
        val worker = Executors.newSingleThreadExecutor()
        val reader = Executors.newSingleThreadExecutor()
        val sampleGate = CountDownLatch(1); val mainHeld = CountDownLatch(1); val releaseMain = CountDownLatch(1)
        val readStarted = CountDownLatch(1); val adopted = CountDownLatch(1); val starts = AtomicInteger()
        val authority = KeyguardInspectionAuthority(1, 2, 3, 4, 5)
        val main = Handler(Looper.getMainLooper())
        val sampler = KeyguardSystemStateSampler(
            reader = { KeyguardSystemStateReader {
                check(sampleGate.await(10, TimeUnit.SECONDS))
                KeyguardSystemState(1, 2, true, true, true, true, false, true, true)
            } }, worker = { worker.execute(it) }, main = { main.post(it) }, current = { authority },
            receive = { _, _ -> adopted.countDown() }, reserveBeforeMain = { _, state ->
                if (!state.eligible) null else ({ reader.execute { starts.incrementAndGet(); readStarted.countDown() } })
            },
        )
        try {
            instrumentation.runOnMainSync {
                sampler.offer(KeyguardSystemGateRequest(1, authority, "wake", 1, 1, true, "wake"))
                main.post { mainHeld.countDown(); releaseMain.await(10, TimeUnit.SECONDS) }
            }
            assertTrue("Main hold did not begin", mainHeld.await(5, TimeUnit.SECONDS))
            sampleGate.countDown()
            assertTrue("reserved worker did not start while Main was held", readStarted.await(5, TimeUnit.SECONDS))
            assertEquals(1, starts.get())
            assertEquals("Main adoption cannot have run while held", 1L, adopted.count)
            releaseMain.countDown()
            assertTrue("matching sample was not adopted", adopted.await(5, TimeUnit.SECONDS))
        } finally {
            sampleGate.countDown(); releaseMain.countDown()
            instrumentation.runOnMainSync { sampler.dispose() }
            worker.shutdownNow(); reader.shutdownNow()
        }
    }

    @Test fun r18RealPanelHiddenBufferTouchAndHeldBorrowerRetirement() {
        assumeTrue(Build.VERSION.SDK_INT == 35)
        val context = instrumentation.targetContext
        val activity = instrumentation.startActivitySync(Intent(context, KeyguardMaterialTestActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) as KeyguardMaterialTestActivity
        val underlayClicks = AtomicInteger(); val orbClicks = AtomicInteger()
        val ready = CountDownLatch(1); val buffer = CountDownLatch(1); val bound = CountDownLatch(1)
        val revealed = CountDownLatch(1); val retired = CountDownLatch(1); val drained = CountDownLatch(1)
        val hostWaiters = ConcurrentHashMap<Long, CountDownLatch>().apply { put(1, ready) }
        val bufferWaiters = ConcurrentHashMap<Long, CountDownLatch>().apply { put(1, buffer) }
        val retireWaiters = ConcurrentHashMap<Long, CountDownLatch>().apply { put(1, retired) }
        val drainWaiters = ConcurrentHashMap<Long, CountDownLatch>().apply { put(1, drained) }
        val error = AtomicReference<String?>(); val failureCleanup = AtomicReference<(() -> Unit)?>(null)
        val hostView = AtomicReference<View?>(); val hostId = AtomicInteger(-1)
        var host: KeyguardOrbInertHost? = null
        var presenter: KeyguardOrbSurfacePresenter? = null
        var borrowed: KeyguardOrbDirectOutput? = null
        val releaseMain = CountDownLatch(1)
        val mainHeld = CountDownLatch(1)
        val drawHeld = CountDownLatch(1); val releaseDraw = CountDownLatch(1); val latePosted = CountDownLatch(1)
        val holdArmed = AtomicBoolean(true); val retiredBeforePost = AtomicBoolean(false)
        val runDir = File(context.filesDir, "keyguard-service-probe/r18/panel-${SystemClock.elapsedRealtime()}").apply { mkdirs() }
        try {
            instrumentation.runOnMainSync {
                val underlay = FrameLayout(activity).apply {
                    setBackgroundColor(Color.rgb(11, 177, 67))
                    setOnClickListener { underlayClicks.incrementAndGet() }
                }
                activity.setContentView(underlay)
            }
            instrumentation.waitForIdleSync()
            val before = checkNotNull(instrumentation.uiAutomation.takeScreenshot())
            before.save(File(runDir, "01-before.png"))
            val size = context.resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_orb_size)
            val bounds = KeyguardUsableBounds(0, 0, before.width, before.height)
            val geometry = KeyguardOverlayGeometry(size, size, 100, 250, bounds,
                KeyguardCardCardPosition(.5f), KeyguardCardOrbPosition(.5f, .5f))
            lateinit var panel: KeyguardOrbInertHost
            lateinit var producer: KeyguardOrbSurfacePresenter
            lateinit var content: FrameLayout
            instrumentation.runOnMainSync {
                content = FrameLayout(activity).apply {
                    setBackgroundColor(Color.TRANSPARENT)
                    setOnClickListener { orbClicks.incrementAndGet() }
                }
                panel = KeyguardOrbInertHost(activity, PanelWindowManager(activity),
                    onReady = { generation, view, id -> hostView.set(view); hostId.set(id); hostWaiters[generation]?.countDown() },
                    onFailure = { generation, reason -> error.set(reason); hostWaiters[generation]?.countDown() })
                host = panel
                producer = KeyguardOrbSurfacePresenter(activity, content, onFirstPosted = { _, _ -> },
                    onFailure = { error.set(it) }, isCaptureActive = { true },
                    onR18Prepared = { _, generation, _ -> bufferWaiters[generation]?.countDown() },
                    onR18Failure = { _, _, reason, cleanup -> error.set(reason); failureCleanup.set(cleanup) },
                    onR18Receipt = { _, generation, receipt ->
                        if (receipt.operation == "RETIRE" && receipt.applyReturnUptimeMs != null) retireWaiters[generation]?.countDown()
                    }, onR18Drained = { _, generation, _ -> drainWaiters[generation]?.countDown() })
                presenter = producer
                assertTrue("private producer did not start", producer.prepareR18(1, 1, profile(), size, size))
                assertTrue("panel add failed", panel.stage(1, geometry))
            }
            assertTrue("real measured panel/identity did not become ready", ready.await(20, TimeUnit.SECONDS))
            assertNull("host failed: ${error.get()}", error.get())
            assertTrue("private first buffer did not post", buffer.await(20, TimeUnit.SECONDS))
            val actualHost = checkNotNull(hostView.get())
            assertTrue("host must have actual window identity", hostId.get() >= 0)
            val location = IntArray(2)
            instrumentation.runOnMainSync { actualHost.getLocationOnScreen(location) }
            val cx = location[0] + size / 2; val cy = location[1] + size / 2
            assertTrue("panel sample must be within display", cx in 0 until before.width && cy in 0 until before.height)
            val background = before.getPixel(cx, cy)
            val staged = checkNotNull(instrumentation.uiAutomation.takeScreenshot())
            staged.save(File(runDir, "02-staged.png"))
            assertColorNear("inert host changed underlay", background, staged.getPixel(cx, cy))
            tap(cx, cy)
            assertTrue("inert panel consumed the underlying tap", awaitCount(underlayClicks, 1))
            instrumentation.runOnMainSync {
                producer.bindR18(actualHost, 1, 1) { success -> if (!success) error.set("bindFailed"); bound.countDown() }
            }
            assertTrue("hidden bind callback missing", bound.await(10, TimeUnit.SECONDS)); assertNull(error.get())
            instrumentation.runOnMainSync {
                assertTrue("actual input root did not arm", panel.promote(1, content, geometry))
                producer.revealR18(1, 1, crossGrantBoundary = { true }) { success ->
                    if (!success) error.set("revealFailed"); revealed.countDown()
                }
            }
            assertTrue("reveal did not complete", revealed.await(10, TimeUnit.SECONDS)); assertNull(error.get())
            val live = awaitScreenshot(10_000) { bitmap -> colorDistance(background, bitmap.getPixel(cx, cy)) > 45 }
            live.save(File(runDir, "03-live.png"))
            tap(cx, cy)
            assertTrue("input was not usable for the visible image", awaitCount(orbClicks, 1))
            val direct = instrumentation.runOnMainValue {
                producer.r18PreparedOutput(1, 1, profile(), false, size, size) as? KeyguardOrbDirectOutput
            }
            assertNotNull("exact direct output unavailable", direct)
            borrowed = direct
            assertNotNull("real borrower was not acquired", direct!!.borrow())
            KeyguardOrbSurfaceWorkerTestHooks.afterCanvasLock = { target ->
                if (target.directOutput === direct && holdArmed.compareAndSet(true, false)) {
                    drawHeld.countDown()
                    releaseDraw.await(10, TimeUnit.SECONDS)
                }
            }
            KeyguardOrbSurfaceWorkerTestHooks.afterCanvasPost = { target ->
                if (target.directOutput === direct && retiredBeforePost.get()) latePosted.countDown()
            }
            assertTrue("real worker did not reach the held Canvas boundary", drawHeld.await(8, TimeUnit.SECONDS))
            Handler(Looper.getMainLooper()).post { mainHeld.countDown(); releaseMain.await(10, TimeUnit.SECONDS) }
            assertTrue("Main hold did not start", mainHeld.await(5, TimeUnit.SECONDS))
            // This is the production exact-generation seal, with Main held.
            producer.sealR18(1, 1)
            assertTrue("retire transaction did not return while Main was held", retired.await(5, TimeUnit.SECONDS))
            val hidden = awaitScreenshot(5_000) { bitmap -> colorDistance(background, bitmap.getPixel(cx, cy)) <= 15 }
            hidden.save(File(runDir, "04-retired-main-held.png"))
            assertColorNear("old ORB/black tile persisted during the held borrower", background, hidden.getPixel(cx, cy))
            retiredBeforePost.set(true)
            releaseDraw.countDown()
            assertTrue("entered real worker did not finish its late post", latePosted.await(5, TimeUnit.SECONDS))
            val afterLate = awaitScreenshot(5_000) { bitmap -> colorDistance(background, bitmap.getPixel(cx, cy)) <= 15 }
            afterLate.save(File(runDir, "05-late-post-main-held.png"))
            afterLate.recycle()
            direct.releaseBorrow(); borrowed = null
            assertTrue("real borrowed owner did not drain", drained.await(5, TimeUnit.SECONDS))
            releaseMain.countDown()
            instrumentation.runOnMainSync { assertTrue("exact panel removal failed", panel.remove(1)) }
            tap(cx, cy)
            assertTrue("touch-through did not return after removal", awaitCount(underlayClicks, 2))
            KeyguardOrbSurfaceWorkerTestHooks.afterCanvasLock = null
            KeyguardOrbSurfaceWorkerTestHooks.afterCanvasPost = null
            // Three replacements on the SAME producer and compositor lane.
            // A late generation-1 seal must not affect the current image.
            repeat(3) { index ->
                val generation = index + 2L
                val hostReady = CountDownLatch(1); val imageReady = CountDownLatch(1)
                val bindDone = CountDownLatch(1); val revealDone = CountDownLatch(1)
                val retireDone = CountDownLatch(1); val drainDone = CountDownLatch(1)
                hostWaiters[generation] = hostReady; bufferWaiters[generation] = imageReady
                retireWaiters[generation] = retireDone; drainWaiters[generation] = drainDone
                instrumentation.runOnMainSync {
                    assertTrue(producer.prepareR18(generation, generation, profile(), size, size))
                    assertTrue(panel.stage(generation, geometry))
                }
                assertTrue("replacement host $generation was not ready", hostReady.await(20, TimeUnit.SECONDS))
                assertTrue("replacement buffer $generation was not ready", imageReady.await(20, TimeUnit.SECONDS))
                assertNull(error.get())
                val nextHost = checkNotNull(hostView.get())
                val nextContent = FrameLayout(activity).apply { setBackgroundColor(Color.TRANSPARENT); setOnClickListener { } }
                instrumentation.runOnMainSync {
                    producer.bindR18(nextHost, generation, generation) { success ->
                        if (!success) error.set("replacementBind:$generation"); bindDone.countDown()
                    }
                }
                assertTrue(bindDone.await(10, TimeUnit.SECONDS)); assertNull(error.get())
                instrumentation.runOnMainSync {
                    assertTrue(panel.promote(generation, nextContent, geometry))
                    producer.revealR18(generation, generation, crossGrantBoundary = { true }) { success ->
                        if (!success) error.set("replacementReveal:$generation"); revealDone.countDown()
                    }
                }
                assertTrue(revealDone.await(10, TimeUnit.SECONDS)); assertNull(error.get())
                val locationB = IntArray(2)
                instrumentation.runOnMainSync { nextHost.getLocationOnScreen(locationB) }
                val bx = locationB[0] + size / 2; val by = locationB[1] + size / 2
                val bg = before.getPixel(bx, by)
                val frame = awaitScreenshot(10_000) { bitmap -> colorDistance(bg, bitmap.getPixel(bx, by)) > 45 }
                frame.save(File(runDir, "06-replacement-$generation.png")); frame.recycle()
                producer.sealR18(1, 1)
                SystemClock.sleep(100)
                val afterOld = checkNotNull(instrumentation.uiAutomation.takeScreenshot())
                assertTrue("stale A seal hid replacement $generation", colorDistance(bg, afterOld.getPixel(bx, by)) > 45)
                afterOld.recycle()
                producer.sealR18(generation, generation)
                assertTrue("replacement retire $generation missing", retireDone.await(5, TimeUnit.SECONDS))
                val clean = awaitScreenshot(5_000) { bitmap -> colorDistance(bg, bitmap.getPixel(bx, by)) <= 15 }
                clean.save(File(runDir, "07-replacement-$generation-retired.png")); clean.recycle()
                assertTrue("replacement $generation did not drain", drainDone.await(5, TimeUnit.SECONDS))
                instrumentation.runOnMainSync { assertTrue(panel.remove(generation)) }
            }
            before.recycle(); staged.recycle(); live.recycle(); hidden.recycle()
        } finally {
            KeyguardOrbSurfaceWorkerTestHooks.afterCanvasLock = null
            KeyguardOrbSurfaceWorkerTestHooks.afterCanvasPost = null
            releaseDraw.countDown()
            borrowed?.releaseBorrow()
            releaseMain.countDown()
            instrumentation.runOnMainSync {
                host?.remove(1)
                failureCleanup.getAndSet(null)?.invoke()
                presenter?.dispose()
                activity.finish()
            }
        }
    }

    private class PanelWindowManager(private val activity: KeyguardMaterialTestActivity) :
        WindowManager by activity.getSystemService(WindowManager::class.java) {
        private val delegate = activity.getSystemService(WindowManager::class.java)
        private fun toPanel(value: ViewGroup.LayoutParams) = WindowManager.LayoutParams().apply {
            copyFrom(value as WindowManager.LayoutParams)
            type = WindowManager.LayoutParams.TYPE_APPLICATION_PANEL
            token = activity.window.decorView.windowToken
        }
        override fun addView(view: View, params: ViewGroup.LayoutParams) = delegate.addView(view, toPanel(params))
        override fun updateViewLayout(view: View, params: ViewGroup.LayoutParams) = delegate.updateViewLayout(view, toPanel(params))
        override fun removeViewImmediate(view: View) = delegate.removeViewImmediate(view)
    }

    private fun profile() = requireNotNull(KeyguardMaterialProfile.fromMap(mapOf(
        "schemaVersion" to 1, "shaderAbiVersion" to 6, "sourceShaderHash" to KeyguardMaterialProfile.SOURCE_SHADER_HASH,
        "publisherSession" to "r18-panel", "publisherRevision" to 1L, "sceneIdentity" to "r18|fixture",
        "effectId" to "dualTide", "effectShaderId" to 1, "phase" to .25, "elapsedSeconds" to 1.0,
        "phaseSpeed" to .4, "colors" to listOf(0xff104f7c.toInt(), 0xff62c7dc.toInt(), 0xff8366dc.toInt()),
        "stops" to listOf(0.0, .5, 1.0), "opacity" to 1.0, "paletteSplitPercent" to 50.0,
        "commonSettings" to List(40) { .2 }, "background" to portal(), "interior" to portal(),
        "referenceWidth" to 390.0, "referenceHeight" to 220.0,
    )))

    private fun portal() = mapOf("enabled" to false, "effectIndex" to 0, "phase" to 0.0, "phaseSpeed" to 0.0,
        "paletteCenterPercent" to 50.0, "paletteWindowPercent" to 68.0, "rotationEnabled" to false,
        "rotationSpeed" to 0.0, "settings" to List(12) { 0.0 })

    private fun Bitmap.save(file: File) { file.outputStream().use { check(compress(Bitmap.CompressFormat.PNG, 100, it)) } }
    private fun colorDistance(a: Int, b: Int) = kotlin.math.abs(Color.red(a) - Color.red(b)) +
        kotlin.math.abs(Color.green(a) - Color.green(b)) + kotlin.math.abs(Color.blue(a) - Color.blue(b))
    private fun assertColorNear(message: String, expected: Int, actual: Int) = assertTrue(message, colorDistance(expected, actual) <= 15)
    private fun awaitCount(counter: AtomicInteger, target: Int): Boolean {
        val deadline = SystemClock.uptimeMillis() + 5_000
        while (counter.get() < target && SystemClock.uptimeMillis() < deadline) SystemClock.sleep(20)
        return counter.get() >= target
    }
    private fun tap(x: Int, y: Int) {
        val now = SystemClock.uptimeMillis()
        val down = MotionEvent.obtain(now, now, MotionEvent.ACTION_DOWN, x.toFloat(), y.toFloat(), 0)
        val up = MotionEvent.obtain(now, now + 20, MotionEvent.ACTION_UP, x.toFloat(), y.toFloat(), 0)
        down.source = InputDevice.SOURCE_TOUCHSCREEN; up.source = InputDevice.SOURCE_TOUCHSCREEN
        try { check(instrumentation.uiAutomation.injectInputEvent(down, true)); check(instrumentation.uiAutomation.injectInputEvent(up, true)) }
        finally { down.recycle(); up.recycle() }
    }
    private fun awaitScreenshot(timeout: Long, predicate: (Bitmap) -> Boolean): Bitmap {
        val deadline = SystemClock.uptimeMillis() + timeout
        do {
            val bitmap = checkNotNull(instrumentation.uiAutomation.takeScreenshot())
            if (predicate(bitmap)) return bitmap
            bitmap.recycle()
            SystemClock.sleep(25)
        } while (SystemClock.uptimeMillis() < deadline)
        throw AssertionError("compositor crop did not reach expected state")
    }
    private fun <T> android.app.Instrumentation.runOnMainValue(block: () -> T): T {
        val result = AtomicReference<T>()
        runOnMainSync { result.set(block()) }
        return result.get()
    }
}
