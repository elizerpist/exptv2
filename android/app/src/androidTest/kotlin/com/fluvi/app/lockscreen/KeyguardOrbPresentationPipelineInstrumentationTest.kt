package com.fluvi.app.lockscreen

import android.app.Activity
import android.app.Application
import android.content.ComponentCallbacks2
import android.content.Intent
import android.os.Bundle
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
import com.fluvi.app.runtime.FluviFinancialCardPresenter
import com.fluvi.app.lockscreen.material.KeyguardMaterialProfile
import com.fluvi.app.lockscreen.material.AndroidKeyguardShaderArtifactReader
import com.fluvi.app.lockscreen.material.KeyguardHeaderMaterialView
import com.fluvi.app.lockscreen.material.KeyguardMaterialScene
import com.fluvi.app.lockscreen.material.KeyguardMaterialTime
import com.fluvi.app.lockscreen.material.KeyguardMaterialTimeSource
import com.fluvi.app.lockscreen.material.KeyguardR19FirstPaintTicket
import com.fluvi.app.lockscreen.material.KeyguardR20FirstFrameObservation
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

    /** The real retained-window entry point must prepare the configured FULL
     * image before wake, while the native output is still unshown. This is a
     * readiness control, not a privacy admission or a physical-pixel test. */
    @Test fun r34RetainedWindowPreparesConfiguredPosterBeforeWake() {
        assumeTrue(Build.VERSION.SDK_INT == 35)
        val context = instrumentation.targetContext
        assumeTrue(context.getSystemService(android.os.UserManager::class.java).isUserUnlocked)
        val preferences = context.getSharedPreferences("fluvi_keyguard_orb_diagnostic_route", android.content.Context.MODE_PRIVATE)
        val previous = preferences.getString("mode", null)
        val activity = instrumentation.startActivitySync(Intent(context, KeyguardMaterialTestActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) as KeyguardMaterialTestActivity
        val ready = CountDownLatch(1)
        val allocated = CountDownLatch(1)
        var window: KeyguardCardWindow? = null
        try {
            check(preferences.edit().putString("mode", "SURFACE_LIVE").commit())
            KeyguardOrbSurfaceWorkerTestHooks.afterWarmPosterCreated = { full -> if (full) ready.countDown() }
            instrumentation.runOnMainSync {
                val target = KeyguardCardWindow(activity, onOpen = {}, onToggle = {}, onInteractionStarted = {},
                    onPositionCommitted = { _, _, _, _ -> }, onInteractionDiagnostic = { _, _ -> },
                    manager = PanelWindowManager(activity), r18PipelineEnabled = true,
                    onR19Allocated = { _, _, _ -> allocated.countDown() })
                window = target
                target.prepareRetainedView(KeyguardCardSettings(requested = true, showFinancialDetails = true,
                    presentationMode = KeyguardCardPresentationMode.ORB,
                    animationMode = KeyguardCardAnimationMode.ORB_ONLY), r20CalibratedProfile())
                assertEquals(KeyguardOrbRenderMode.SURFACE_LIVE, target.renderModeStatus().effective)
                assertNotNull("fixture did not reach the virgin DIRECT preparation", target.r18Preparation())
                assertFalse("preparation must not attach a display window", target.isAttached)
            }
            assertTrue("virgin DIRECT allocation was not reached", allocated.await(20, TimeUnit.SECONDS))
            assertTrue("configured private FULL poster was not ready before wake", ready.await(20, TimeUnit.SECONDS))
            instrumentation.runOnMainSync { assertFalse(checkNotNull(window).isAttached) }
        } finally {
            KeyguardOrbSurfaceWorkerTestHooks.afterWarmPosterCreated = null
            instrumentation.runOnMainSync { window?.dispose(); activity.finish() }
            val edit = preferences.edit()
            if (previous == null) edit.remove("mode") else edit.putString("mode", previous)
            check(edit.commit())
        }
    }

    @Test fun r34UiHiddenKeepsConfiguredPosterForAuthorizedWindow() = r34WindowPoster("SHOW")
    @Test fun r34PressureInvalidatesLeasedPosterBeforeSubmit() = r34WindowPoster("PRESSURE")
    @Test fun r34RestrictionBeforeSubmitCannotRevealPoster() = r34WindowPoster("RESTRICT")
    @Test fun r34RestrictionAfterGrantBeforeNativeApplyCannotRevealPoster() = r34WindowPoster("RESTRICT_AFTER_CROSS")

    /** Uses the production retained window, native host and compositor. The
     * permission callback is a controlled positive, not a service-privacy pass. */
    private fun r34WindowPoster(scenario: String) {
        assumeTrue(Build.VERSION.SDK_INT == 35)
        val context = instrumentation.targetContext
        assumeTrue(context.getSystemService(android.os.UserManager::class.java).isUserUnlocked)
        val preferences = context.getSharedPreferences("fluvi_keyguard_orb_diagnostic_route", android.content.Context.MODE_PRIVATE)
        val previous = preferences.getString("mode", null)
        val activity = instrumentation.startActivitySync(Intent(context, KeyguardMaterialTestActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) as KeyguardMaterialTestActivity
        val stopped = CountDownLatch(1); val resumed = CountDownLatch(1); val restoring = AtomicBoolean(false)
        val warmed = CountDownLatch(1); val allocated = CountDownLatch(1)
        val hostReady = CountDownLatch(1); val bound = CountDownLatch(1); val imageReady = CountDownLatch(1)
        val heldLive = CountDownLatch(1); val releaseLive = CountDownLatch(1)
        val beforeCross = CountDownLatch(1); val releaseCross = CountDownLatch(1); val revealed = CountDownLatch(1)
        val result = AtomicReference<Boolean>(); val host = AtomicReference<View>(); val failure = AtomicReference<String?>()
        val route = AtomicReference<String>(); val applied = AtomicInteger(); val firstPosts = AtomicInteger()
        val closedActivity = object : Application.ActivityLifecycleCallbacks {
            override fun onActivityCreated(a: Activity, state: Bundle?) = Unit
            override fun onActivityStarted(a: Activity) = Unit
            override fun onActivityResumed(a: Activity) { if (a === activity && restoring.get()) resumed.countDown() }
            override fun onActivityPaused(a: Activity) = Unit
            override fun onActivityStopped(a: Activity) { if (a === activity) stopped.countDown() }
            override fun onActivitySaveInstanceState(a: Activity, state: Bundle) = Unit
            override fun onActivityDestroyed(a: Activity) = Unit
        }
        var window: KeyguardCardWindow? = null
        var reference: Bitmap? = null
        val runDir = File(context.filesDir, "keyguard-service-probe/r20/r34-$scenario-${SystemClock.elapsedRealtime()}").apply { mkdirs() }
        try {
            check(preferences.edit().putString("mode", "SURFACE_LIVE").commit())
            activity.application.registerActivityLifecycleCallbacks(closedActivity)
            val size = context.resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_orb_size)
            val green = Color.rgb(11, 177, 67)
            val base = r20CalibratedProfile()
            val phase = 1.196795f
            val selected = base.copy(phase = phase, elapsedSeconds = phase,
                background = base.background.copy(phase = phase), interior = base.interior.copy(phase = phase))
            val fixed = KeyguardMaterialTime(phase, phase, phase, phase)
            lateinit var root: FrameLayout
            lateinit var referenceView: KeyguardHeaderMaterialView
            val artifact = AndroidKeyguardShaderArtifactReader.load(context, selected.effectId, selected.usesPortal)
            instrumentation.runOnMainSync {
                root = FrameLayout(activity).apply { setBackgroundColor(green) }
                referenceView = KeyguardHeaderMaterialView(activity,
                    materialTimeSource = KeyguardMaterialTimeSource { _, _ -> fixed }).apply {
                    layoutParams = FrameLayout.LayoutParams(size, size).apply { leftMargin = 100; topMargin = 250 }
                    setScene(KeyguardMaterialScene(selected, true, 0L), enabled = true)
                    setBootstrapActive(false)
                    assertEquals(KeyguardHeaderMaterialView.ProgramPreparationResult.COMPILED, installPreparedShader(artifact))
                }
                root.addView(referenceView); activity.setContentView(root); referenceView.frame(System.nanoTime())
            }
            fun crop(view: View, screen: Bitmap): Bitmap {
                val location = IntArray(2)
                instrumentation.runOnMainSync { view.getLocationOnScreen(location) }
                check(view.width == size && view.height == size && location[0] >= 0 && location[1] >= 0 &&
                    location[0] + size <= screen.width && location[1] + size <= screen.height)
                return Bitmap.createBitmap(screen, location[0], location[1], size, size)
            }
            assertTrue("reference view did not draw", r20Wait(10_000) {
                instrumentation.runOnMainValue { referenceView.diagnostics().lastCanvasHardwareAccelerated == true &&
                    referenceView.diagnostics().shaderDrawCount > 0 && referenceView.width == size }
            })
            val refScreen = awaitScreenshot(8_000) { screen ->
                val sample = crop(referenceView, screen)
                try { colorDistance(green, sample.getPixel(0, 0)) <= 15 &&
                    colorDistance(green, sample.getPixel(size / 2, size / 2)) > 45 } finally { sample.recycle() }
            }
            reference = crop(referenceView, refScreen); refScreen.recycle()
            checkNotNull(reference).save(File(runDir, "reference.png"))
            instrumentation.runOnMainSync { root.removeView(referenceView) }
            val settings = KeyguardCardSettings(requested = true, showFinancialDetails = true,
                presentationMode = KeyguardCardPresentationMode.ORB, animationMode = KeyguardCardAnimationMode.ORB_ONLY)
            val hostGeneration = 71L
            KeyguardOrbSurfaceWorkerTestHooks.afterWarmPosterCreated = { full -> if (full) warmed.countDown() }
            KeyguardOrbSurfaceWorkerTestHooks.beforeFirstLock = { target ->
                if (target.firstDirectAuthorization.get()?.requestId == 801L) {
                    heldLive.countDown(); check(releaseLive.await(30, TimeUnit.SECONDS))
                }
            }
            KeyguardOrbSurfaceWorkerTestHooks.onDirectProgramConstructor = { target, stage ->
                if (target.firstDirectAuthorization.get()?.requestId == 801L && stage == "R34_LIVE_AFTER_BLIT") {
                    heldLive.countDown(); check(releaseLive.await(30, TimeUnit.SECONDS))
                }
            }
            KeyguardOrbSurfaceWorkerTestHooks.afterCanvasPost = { target ->
                if (target.firstDirectAuthorization.get()?.requestId == 801L) firstPosts.incrementAndGet()
            }
            instrumentation.runOnMainSync {
                window = KeyguardCardWindow(activity, onOpen = {}, onToggle = {}, onInteractionStarted = {},
                    onPositionCommitted = { _, _, _, _ -> }, onInteractionDiagnostic = { _, _ -> },
                    manager = PanelWindowManager(activity), r18PipelineEnabled = true,
                    onR19Allocated = { _, _, _ -> allocated.countDown() },
                    onR18BufferReady = { _, _, _ -> imageReady.countDown() },
                    onR18HostReady = { generation, view, _ -> if (generation == hostGeneration) { host.set(view); hostReady.countDown() } },
                    onR18Failure = { _, _, why -> failure.set(why) },
                    onR19Observation = { observation -> if (observation.stage == "POSTER") route.set(observation.detail) })
                checkNotNull(window).prepareRetainedView(settings, selected)
                assertNotNull("missing virgin preparation", checkNotNull(window).r18Preparation())
            }
            assertTrue("private poster was not prepared", warmed.await(20, TimeUnit.SECONDS))
            assertTrue("DIRECT output was not allocated", allocated.await(20, TimeUnit.SECONDS))
            instrumentation.runOnMainSync { assertTrue("activity did not move to background", activity.moveTaskToBack(true)) }
            assertTrue("activity never stopped in the background", stopped.await(15, TimeUnit.SECONDS))
            instrumentation.runOnMainSync { checkNotNull(window).onMemoryTrim(ComponentCallbacks2.TRIM_MEMORY_UI_HIDDEN) }
            // startActivitySync waits for a new Activity instance, while
            // REORDER_TO_FRONT deliberately resumes the existing instance.
            restoring.set(true)
            context.startActivity(Intent(context, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT))
            assertTrue("retained Activity did not resume after UI_HIDDEN", resumed.await(15, TimeUnit.SECONDS))
            instrumentation.runOnMainSync { assertFalse("retained Activity was destroyed", activity.isFinishing || activity.isDestroyed) }
            instrumentation.runOnMainSync { assertTrue(checkNotNull(window).stageR18Host(hostGeneration, settings)) }
            assertTrue("real panel host did not become ready", hostReady.await(20, TimeUnit.SECONDS))
            val actualHost = checkNotNull(host.get())
            val hostLocation = IntArray(2)
            instrumentation.runOnMainSync { actualHost.getLocationOnScreen(hostLocation) }
            val before = awaitScreenshot(8_000) { image ->
                val x = hostLocation[0] + size / 2; val y = hostLocation[1] + size / 2
                x in 0 until image.width && y in 0 until image.height && colorDistance(green, image.getPixel(x, y)) <= 15
            }
            before.save(File(runDir, "before-reveal.png")); before.recycle()
            val prep = instrumentation.runOnMainValue { checkNotNull(checkNotNull(window).r18Preparation()) }
            instrumentation.runOnMainSync { checkNotNull(window).bindR18Host(hostGeneration, prep) {
                if (!it) failure.set("hiddenBindFailed"); bound.countDown()
            } }
            assertTrue("hidden host bind did not complete", bound.await(10, TimeUnit.SECONDS)); assertNull(failure.get())
            val ticket = KeyguardR19FirstPaintTicket(prep.attachment, prep.outputGeneration, 801, 1,
                settings.focus.generation, selected.visualKey)
            instrumentation.runOnMainSync { assertTrue(checkNotNull(window).authorizeR19First(prep, ticket)) }
            assertTrue("current private image was not selected", imageReady.await(20, TimeUnit.SECONDS)); assertNull(failure.get())
            assertTrue("opening did not select a private image: ${route.get()}", route.get()?.startsWith("R34_PRIVATE_") == true)
            instrumentation.runOnMainSync {
                assertEquals(KeyguardCardWindow.Result.ATTACHED,
                    checkNotNull(window).showOrUpdate(FluviFinancialCardPresenter.loading(), settings, hostGeneration))
                if (scenario == "PRESSURE") checkNotNull(window).onMemoryTrim(ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW)
                if (scenario == "RESTRICT") KeyguardOrbSurfaceWorkerTestHooks.beforeRevealCross = {
                    beforeCross.countDown(); check(releaseCross.await(20, TimeUnit.SECONDS))
                }
                if (scenario == "RESTRICT_AFTER_CROSS") KeyguardOrbSurfaceWorkerTestHooks.beforeRevealApply = {
                    beforeCross.countDown(); check(releaseCross.await(20, TimeUnit.SECONDS))
                }
                checkNotNull(window).revealR18(prep, boundary = { applied.incrementAndGet(); true },
                    nativeApplied = { true }) { result.set(it); revealed.countDown() }
            }
            if (scenario == "RESTRICT" || scenario == "RESTRICT_AFTER_CROSS") {
                assertTrue("native submit boundary was not reached", beforeCross.await(10, TimeUnit.SECONDS))
                instrumentation.runOnMainSync { checkNotNull(window).hide() }
                releaseCross.countDown()
            }
            assertTrue("reveal result missing", revealed.await(15, TimeUnit.SECONDS)); assertNull(failure.get())
            if (scenario == "SHOW") {
                assertEquals(true, result.get()); assertEquals(1, applied.get())
                assertTrue("live painter was not held after poster selection", heldLive.await(15, TimeUnit.SECONDS))
                val screen = awaitScreenshot(10_000) { image ->
                    val sample = crop(actualHost, image)
                    try { r20Compare(checkNotNull(reference), sample).nearlyEqual() } finally { sample.recycle() }
                }
                val shown = crop(actualHost, screen); screen.recycle(); shown.save(File(runDir, "cached-poster.png"))
                assertTrue("cached image differs from the calibrated configured scene", r20Compare(checkNotNull(reference), shown).nearlyEqual())
                assertTrue("poster exterior lost transparency", colorDistance(green, shown.getPixel(0, 0)) <= 15)
                if (route.get() == "R34_PRIVATE_COMPOSITOR_READY") assertEquals("live frame satisfied the poster check", 0, firstPosts.get())
                else assertEquals("fallback must blit exactly once before live work", 1, firstPosts.get())
                shown.recycle(); releaseLive.countDown()
            } else {
                assertEquals("stale/restricted poster must not reveal", false, result.get())
                assertEquals("unexpected permission boundary count", if (scenario == "RESTRICT_AFTER_CROSS") 1 else 0, applied.get())
                if (scenario == "PRESSURE") instrumentation.runOnMainSync { checkNotNull(window).hide() }
                val screen = awaitScreenshot(10_000) { image ->
                    val x = hostLocation[0] + size / 2; val y = hostLocation[1] + size / 2
                    x in 0 until image.width && y in 0 until image.height && colorDistance(green, image.getPixel(x, y)) <= 15
                }
                screen.save(File(runDir, "after-exclusion.png")); screen.recycle()
            }
            File(runDir, "fixture.txt").writeText("scenario=$scenario route=${route.get()} permissionCalls=${applied.get()} posts=${firstPosts.get()}\n")
        } finally {
            releaseLive.countDown(); releaseCross.countDown()
            KeyguardOrbSurfaceWorkerTestHooks.afterWarmPosterCreated = null
            KeyguardOrbSurfaceWorkerTestHooks.beforeFirstLock = null
            KeyguardOrbSurfaceWorkerTestHooks.onDirectProgramConstructor = null
            KeyguardOrbSurfaceWorkerTestHooks.afterCanvasPost = null
            KeyguardOrbSurfaceWorkerTestHooks.beforeRevealCross = null
            KeyguardOrbSurfaceWorkerTestHooks.beforeRevealApply = null
            reference?.recycle()
            activity.application.unregisterActivityLifecycleCallbacks(closedActivity)
            instrumentation.runOnMainSync { window?.dispose(); activity.finish() }
            val edit = preferences.edit()
            if (previous == null) edit.remove("mode") else edit.putString("mode", previous)
            check(edit.commit())
        }
    }

    @Test fun r19PrewakeAllocationRetainsExactTimeWithoutPostingFullPixels() {
        assumeTrue(Build.VERSION.SDK_INT == 35)
        val context = instrumentation.targetContext
        val activity = instrumentation.startActivitySync(Intent(context, KeyguardMaterialTestActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) as KeyguardMaterialTestActivity
        val allocated = CountDownLatch(1)
        val observed = AtomicReference<Long>()
        val failure = AtomicReference<String?>()
        var presenter: KeyguardOrbSurfacePresenter? = null
        try {
            val size = context.resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_orb_size)
            instrumentation.runOnMainSync {
                val root = FrameLayout(activity)
                activity.setContentView(root)
                presenter = KeyguardOrbSurfacePresenter(activity, root, onFirstPosted = { _, _ -> },
                    onFailure = { failure.set(it) }, isCaptureActive = { true },
                    onR18Allocated = { attachment, generation, at ->
                        if (attachment == 21L && generation == 34L) { observed.set(at); allocated.countDown() }
                    }, onR18Failure = { _, _, reason, cleanup -> failure.set(reason); cleanup() })
                assertTrue(checkNotNull(presenter).prepareR18(21, 34, profile(), size, size,
                    full = true, emptyAwaitingDisclosure = true))
            }
            assertTrue("virgin native output was not allocated", allocated.await(20, TimeUnit.SECONDS))
            assertNull(failure.get())
            instrumentation.runOnMainSync {
                val current = checkNotNull(presenter)
                assertEquals(observed.get(), current.r19AllocatedAt(21, 34))
                assertNull(current.r19AllocatedAt(21, 35))
                assertNotNull(current.r18AllocatedOutput(21, 34, true, size, size))
                assertNull("allocation alone must not post an authorized image",
                    current.r18PreparedOutput(21, 34, profile(), true, size, size))
                current.sealR18(21, 34)
                assertNull(current.r19AllocatedAt(21, 34))
            }
        } finally {
            instrumentation.runOnMainSync { presenter?.dispose(); activity.finish() }
        }
    }

    @Test fun r18RealPanelHiddenBufferTouchAndHeldBorrowerRetirement() {
        assumeTrue(Build.VERSION.SDK_INT == 35)
        val context = instrumentation.targetContext
        val activity = instrumentation.startActivitySync(Intent(context, KeyguardMaterialTestActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) as KeyguardMaterialTestActivity
        val underlayClicks = AtomicInteger(); val orbClicks = AtomicInteger()
        val nativeAppliedOwners = java.util.Collections.synchronizedSet(mutableSetOf<Long>())
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
                producer.revealR18(1, 1, crossGrantBoundary = { true }, nativeApplied = { nativeAppliedOwners.add(1); true }) { success ->
                    if (!success) error.set("revealFailed"); revealed.countDown()
                }
            }
            assertTrue("reveal did not complete", revealed.await(10, TimeUnit.SECONDS)); assertNull(error.get())
            assertTrue("native apply return was not reported", nativeAppliedOwners.contains(1))
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
                    producer.revealR18(generation, generation, crossGrantBoundary = { true }, nativeApplied = { nativeAppliedOwners.add(generation); true }) { success ->
                        if (!success) error.set("replacementReveal:$generation"); revealDone.countDown()
                    }
                }
                assertTrue(revealDone.await(10, TimeUnit.SECONDS)); assertNull(error.get())
                assertTrue("replacement native apply return missing", nativeAppliedOwners.contains(generation))
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

    /** Real direct child, authorized by the R19 entry point. The reference is
     * the independently rendered hardware View, sampled before revealing the
     * child. This is a panel control, not a keyguard-service privacy pass. */
    @Test fun r20AuthorizedFullFirstMissDrawsCanonicalPhaseOnExistingChild() = calibratedFirstFrame(false)
    @Test fun r27WarmDirectMissUsesPreparedProgramAndCanonicalPixels() =
        calibratedFirstFrame(false, expectWarm = true)
    @Test fun r27NoReadyDirectMissFallsBackColdWithCanonicalPixels() =
        calibratedFirstFrame(false, forceCold = true)

    @Test fun r21SubmittedPanelSurvivesBenignRecheckAndSealsBeforeLateAck() = calibratedFirstFrame(true)
    @Test fun r21PanelCancelsBeforeNativeCross() = calibratedFirstFrame(true, "PRE_CROSS")
    @Test fun r21PanelRetiresInFlightRevealInNativeLaneOrder() = calibratedFirstFrame(true, "IN_FLIGHT")

    private fun calibratedFirstFrame(r21: Boolean, boundary: String = "APPLIED",
                                     expectWarm: Boolean = false, forceCold: Boolean = false) {
        assumeTrue(Build.VERSION.SDK_INT == 35)
        val context = instrumentation.targetContext
        val activity = instrumentation.startActivitySync(Intent(context, KeyguardMaterialTestActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) as KeyguardMaterialTestActivity
        val runDir = File(context.filesDir, "keyguard-service-probe/r20/first-${SystemClock.elapsedRealtime()}").apply { mkdirs() }
        val fixture = File(runDir, "fixture.txt")
        val phaseA = 1.196795f; val phaseC = 1.5234617f; val phaseB = 3.75f
        val base = r20CalibratedProfile()
        val selected = base.copy(phase = phaseA, elapsedSeconds = phaseA,
            background = base.background.copy(phase = phaseA), interior = base.interior.copy(phase = phaseA))
        val controlled = AtomicReference(KeyguardMaterialTime(phaseA, phaseA, phaseA, phaseA))
        val referenceSourceReturned = AtomicReference<KeyguardMaterialTime?>()
        val allocated = CountDownLatch(1); val hostReady = CountDownLatch(1); val bound = CountDownLatch(1)
        val firstPosted = CountDownLatch(1); val reveal = CountDownLatch(1); val drained = CountDownLatch(1)
        val heldAck = AtomicReference<Runnable?>(); val ackQueued = CountDownLatch(1)
        val gateEntered = CountDownLatch(1); val releaseGate = CountDownLatch(1)
        val receipts = java.util.Collections.synchronizedList(mutableListOf<String>())
        val priorDispatcher = KeyguardOrbSurfaceWorkerTestHooks.dispatchRevealDone
        val hostView = AtomicReference<View?>(); val error = AtomicReference<String?>()
        val cleanup = AtomicReference<(() -> Unit)?>(null)
        val posterCount = AtomicInteger(); val firstDrawCount = AtomicInteger(); val postCount = AtomicInteger()
        val nativeApplyCount = AtomicInteger()
        val warmReady = CountDownLatch(1)
        val warmLoadEntered = CountDownLatch(1); val releaseWarmLoad = CountDownLatch(1)
        val programConstructors = java.util.Collections.synchronizedList(mutableListOf<String>())
        val r27First = AtomicReference<KeyguardR20FirstFrameObservation?>()
        val drawMethod = AtomicReference<String?>(); val childId = AtomicInteger(-1)
        val firstEntry = AtomicReference<Long>(); val firstPostAt = AtomicReference<Long>()
        val refs = mutableListOf<Bitmap>()
        var panel: KeyguardOrbInertHost? = null
        var presenter: KeyguardOrbSurfacePresenter? = null
        try {
            val size = context.resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_orb_size)
            val green = Color.rgb(11, 177, 67)
            val artifact = AndroidKeyguardShaderArtifactReader.load(context, selected.effectId, selected.usesPortal)
            lateinit var root: FrameLayout
            lateinit var reference: KeyguardHeaderMaterialView
            instrumentation.runOnMainSync {
                root = FrameLayout(activity).apply { setBackgroundColor(green) }
                reference = KeyguardHeaderMaterialView(activity,
                    materialTimeSource = KeyguardMaterialTimeSource { _, _ ->
                        controlled.get().also { referenceSourceReturned.set(it) }
                    }).apply {
                    layoutParams = FrameLayout.LayoutParams(size, size).apply { leftMargin = 100; topMargin = 250 }
                    setScene(KeyguardMaterialScene(selected, true, 0L), enabled = true)
                    setBootstrapActive(false)
                    assertEquals(KeyguardHeaderMaterialView.ProgramPreparationResult.COMPILED, installPreparedShader(artifact))
                }
                root.addView(reference); activity.setContentView(root); reference.frame(System.nanoTime())
            }
            assertTrue("canonical View never drew on a hardware canvas", r20Wait(10_000) {
                instrumentation.runOnMainValue { reference.diagnostics().lastCanvasHardwareAccelerated == true &&
                    reference.diagnostics().shaderDrawCount > 0 && reference.width == size && reference.height == size }
            })
            fun crop(view: View, screen: Bitmap): Bitmap {
                val loc = IntArray(2)
                instrumentation.runOnMainSync { view.getLocationOnScreen(loc) }
                check(loc[0] >= 0 && loc[1] >= 0 && loc[0] + size <= screen.width && loc[1] + size <= screen.height)
                return Bitmap.createBitmap(screen, loc[0], loc[1], size, size)
            }
            fun referenceAt(phase: Float, index: Int, accept: (Bitmap) -> Boolean): Bitmap {
                val before = instrumentation.runOnMainValue { reference.diagnostics().shaderDrawCount }
                instrumentation.runOnMainSync {
                    controlled.set(KeyguardMaterialTime(phase, phase, phase, phase)); reference.frame(System.nanoTime())
                }
                assertTrue("canonical phase $index did not draw", r20Wait(8_000) {
                    instrumentation.runOnMainValue { reference.diagnostics().shaderDrawCount > before }
                })
                var lastRejected: Bitmap? = null
                try {
                    val screen = awaitScreenshot(8_000) { screenshot ->
                        val sample = crop(reference, screenshot)
                        try {
                            val accepted = accept(sample)
                            if (!accepted) {
                                lastRejected?.recycle()
                                lastRejected = screenshot.copy(Bitmap.Config.ARGB_8888, false)
                            }
                            accepted
                        } finally { sample.recycle() }
                    }
                    return crop(reference, screen).also { screen.recycle(); it.save(File(runDir, "reference-$index.png")) }
                } catch (failure: AssertionError) {
                    lastRejected?.let { image ->
                        image.save(File(runDir, "reference-$index-last-rejected-full.png"))
                        val sample = crop(reference, image)
                        try {
                            sample.save(File(runDir, "reference-$index-last-rejected-crop.png"))
                            val diagnostics = instrumentation.runOnMainValue { reference.diagnostics() }
                            val location = IntArray(2)
                            instrumentation.runOnMainSync { reference.getLocationOnScreen(location) }
                            val metrics = refs.firstOrNull()?.let { r20Compare(it, sample).toString() } ?: "UNOBSERVED_NO_A"
                            File(runDir, "reference-$index-timeout.txt").writeText(
                                "requestedPhase=$phase sourceReturned=${referenceSourceReturned.get() ?: "UNOBSERVED"} " +
                                    "shaderDrawCount=${diagnostics.shaderDrawCount} bounds=${location[0]},${location[1]},$size,$size " +
                                    "corner=${sample.getPixel(0, 0)} center=${sample.getPixel(size / 2, size / 2)} metrics=$metrics\n")
                        } finally { sample.recycle() }
                    }
                    throw failure
                } finally { lastRejected?.recycle() }
            }
            // A hardware View draw can complete before the launch splash is
            // composited away. Accept A only when its transparent corner has
            // exposed the calibrated green underlay and its center is material.
            val refA = referenceAt(phaseA, 0) {
                colorDistance(green, it.getPixel(0, 0)) <= 15 &&
                    colorDistance(green, it.getPixel(size / 2, size / 2)) > 45 &&
                    colorDistance(Color.WHITE, it.getPixel(size / 2, size / 2)) > 45 &&
                    colorDistance(Color.BLACK, it.getPixel(size / 2, size / 2)) > 45
            }
            refs += refA
            val refC = referenceAt(phaseC, 1) { r20Compare(refA, it).nearlyEqual() }; refs += refC
            val refB = referenceAt(phaseB, 2) { r20Compare(refA, it).meaningful() }; refs += refB
            val refAgain = referenceAt(phaseA, 3) { r20Compare(refA, it).nearlyEqual() }; refs += refAgain
            assertTrue("A/C plateau not calibrated", r20Compare(refA, refC).nearlyEqual())
            assertTrue("A/B motion reference not calibrated", r20Compare(refA, refB).meaningful())
            assertTrue("return-A reference not calibrated", r20Compare(refA, refAgain).nearlyEqual())
            assertTrue("reference exterior is not the known underlay", colorDistance(green, refA.getPixel(0, 0)) <= 15)
            assertTrue("reference center is not distinct from black", colorDistance(Color.BLACK, refA.getPixel(size / 2, size / 2)) > 45)
            val beforeNeutral = instrumentation.runOnMainValue { reference.diagnostics().shaderDrawCount }
            instrumentation.runOnMainSync {
                reference.setScene(KeyguardMaterialScene(selected.neutralized(), false, 0L), enabled = true)
                reference.frame(System.nanoTime())
            }
            assertTrue("neutral canonical View did not draw", r20Wait(8_000) {
                instrumentation.runOnMainValue { reference.diagnostics().shaderDrawCount > beforeNeutral }
            })
            val neutralScreen = awaitScreenshot(8_000) { screenshot ->
                val sample = crop(reference, screenshot)
                try { r20Compare(refA, sample).meaningful() } finally { sample.recycle() }
            }
            val neutral = crop(reference, neutralScreen); neutralScreen.recycle()
            neutral.save(File(runDir, "reference-neutral.png"))
            assertTrue("neutral and FULL references were not distinguishable", r20Compare(refA, neutral).meaningful())
            refs += neutral
            instrumentation.runOnMainSync { root.removeView(reference) }
            val underlay = awaitScreenshot(8_000) { colorDistance(green, it.getPixel(100 + size / 2, 250 + size / 2)) <= 15 }
            val bounds = KeyguardUsableBounds(0, 0, underlay.width, underlay.height)
            underlay.save(File(runDir, "underlay.png")); underlay.recycle()
            val geometry = KeyguardOverlayGeometry(size, size, 100, 250, bounds,
                KeyguardCardCardPosition(.5f), KeyguardCardOrbPosition(.5f, .5f))
            lateinit var producer: KeyguardOrbSurfacePresenter
            lateinit var holder: KeyguardOrbInertHost
            val content = FrameLayout(activity).apply { setBackgroundColor(Color.TRANSPARENT) }
            if (expectWarm || forceCold) {
                if (expectWarm) KeyguardOrbSurfaceWorkerTestHooks.afterDirectProgramWarm = { target ->
                    if (target.attachment == 21L && target.generation == 34L) warmReady.countDown()
                }
                if (forceCold) KeyguardOrbSurfaceWorkerTestHooks.beforeDirectArtifactLoad = { target ->
                    if (target.attachment == 21L && target.generation == 34L) {
                        warmLoadEntered.countDown(); check(releaseWarmLoad.await(30, TimeUnit.SECONDS))
                    }
                }
                KeyguardOrbSurfaceWorkerTestHooks.onDirectProgramConstructor = { target, phase ->
                    if (target.attachment == 21L && target.generation == 34L) programConstructors.add(phase)
                }
            }
            KeyguardOrbSurfaceWorkerTestHooks.afterPosterCreated = { target ->
                if (target.firstDirectAuthorization.get()?.requestId == 201L) posterCount.incrementAndGet()
            }
            KeyguardOrbSurfaceWorkerTestHooks.afterFirstFrameDraw = { target, method ->
                if (target.firstDirectAuthorization.get()?.requestId == 201L) { firstDrawCount.incrementAndGet(); drawMethod.set(method) }
            }
            KeyguardOrbSurfaceWorkerTestHooks.afterCanvasPost = { target ->
                if (target.firstDirectAuthorization.get()?.requestId == 201L) {
                    if (postCount.incrementAndGet() == 1) firstPostAt.set(SystemClock.uptimeMillis())
                }
            }
            instrumentation.runOnMainSync {
                holder = KeyguardOrbInertHost(activity, PanelWindowManager(activity),
                    onReady = { _, view, _ -> hostView.set(view); hostReady.countDown() },
                    onFailure = { _, reason -> error.set(reason); hostReady.countDown() })
                panel = holder
                producer = KeyguardOrbSurfacePresenter(activity, content, onFirstPosted = { _, _ -> },
                    onFailure = { error.set(it) }, isCaptureActive = { true },
                    onR18Allocated = { _, _, _ -> allocated.countDown() },
                    onR18Prepared = { _, _, _ -> firstPosted.countDown() },
                    onR18Failure = { _, _, reason, done -> error.set(reason); cleanup.set(done); firstPosted.countDown() },
                    onR18Receipt = { _, _, receipt -> if (receipt.applyReturnUptimeMs != null)
                        receipts.add("${receipt.operation}:${receipt.submitStartUptimeMs}:${receipt.applyReturnUptimeMs}") },
                    onR18Drained = { _, _, _ -> drained.countDown() },
                    onR19Observation = {
                        if (it.stage == "R19_PAINT_ENTER") firstEntry.set(it.observedAtUptimeMs)
                        if (it.stage == "R20_FIRST_FRAME") r27First.set(it.firstFrame)
                    })
                presenter = producer
                assertTrue(producer.prepareR18(21, 34, selected, size, size, full = true, emptyAwaitingDisclosure = true))
                assertTrue(holder.stage(1, geometry))
            }
            assertTrue("actual virgin output was not allocated", allocated.await(20, TimeUnit.SECONDS))
            if (expectWarm) assertTrue("exact virgin DIRECT program was not prepared", warmReady.await(20, TimeUnit.SECONDS))
            if (forceCold) assertTrue("actual virgin asset load was not reached", warmLoadEntered.await(20, TimeUnit.SECONDS))
            assertTrue("measured host was not attached", hostReady.await(20, TimeUnit.SECONDS)); assertNull(error.get())
            val host = checkNotNull(hostView.get())
            val output = instrumentation.runOnMainValue { producer.r18AllocatedOutput(21, 34, true, size, size) as? KeyguardOrbDirectOutput }
            assertNotNull("exact child missing", output); childId.set(output!!.childId)
            instrumentation.runOnMainSync {
                producer.setMotionAllowed(false)
                assertNull("blank target cannot be ready", producer.r18PreparedOutput(21, 34, selected, true, size, size))
                producer.bindR18(host, 21, 34) { if (!it) error.set("bindFailed"); bound.countDown() }
            }
            assertTrue("hidden bind failed", bound.await(10, TimeUnit.SECONDS)); assertNull(error.get())
            val blank = checkNotNull(instrumentation.uiAutomation.takeScreenshot())
            val blankCrop = crop(host, blank); blank.recycle(); blankCrop.save(File(runDir, "blank.png"))
            assertTrue("unapproved FULL changed the underlay", colorDistance(green, blankCrop.getPixel(size / 2, size / 2)) <= 15)
            blankCrop.recycle()
            val ticket = KeyguardR19FirstPaintTicket(21, 34, 201, 1, 1, selected.visualKey)
            instrumentation.runOnMainSync { assertTrue("normal R19 authorization rejected", producer.authorizeR19First(21, 34, selected, ticket)) }
            assertTrue("actual first post did not complete", firstPosted.await(20, TimeUnit.SECONDS)); assertNull(error.get())
            if (forceCold) {
                assertTrue("cold first-frame timing was not observed", r20Wait(5_000) { r27First.get() != null })
                releaseWarmLoad.countDown()
            }
            assertSame("first post must retain the allocated child", output,
                instrumentation.runOnMainValue { producer.r18PreparedOutput(21, 34, selected, true, size, size) })
            // This panel deliberately supplies synthetic scene signals to the
            // production visibility policy. Its compositor and owner are real;
            // it is not evidence of a real accessibility-service read.
            val coordinator = KeyguardOrbPresentationCoordinator()
            val previousAuthority = KeyguardInspectionAuthority(1, 2, 3, 4, 5)
            val authority = previousAuthority.copy(wakeGeneration = 4)
            val stamp = KeyguardOrbPresentationStamp(authority, 201, 11, 12, 13, size, size,
                context.resources.displayMetrics.densityDpi, true, 21, 34, 0)
            val token = requireNotNull(coordinator.reserve(stamp, 1, previousAuthority, previousAuthority, true, true))
            assertTrue(coordinator.adopt(token, stamp)); assertTrue(coordinator.attachInertHost(token, host))
            assertTrue(coordinator.hostReady(token, host)); assertTrue(coordinator.attachPreparedOutput(token, output))
            assertTrue(coordinator.imageReady(token, output)); assertTrue(coordinator.grant(token, authority, 201,
                completeMain = true, finalSystemEligible = true, disclosedFull = true,
                selectionRevision = 11, materialRevision = 12, dataRevision = 13))
            assertTrue(coordinator.armInput(token, host))
            val permit = requireNotNull(coordinator.queueReveal(token, authority, true, true, 11, 12, 13))
            if (r21 && boundary == "APPLIED") KeyguardOrbSurfaceWorkerTestHooks.dispatchRevealDone = { task ->
                if (heldAck.compareAndSet(null, task)) ackQueued.countDown()
                else Handler(Looper.getMainLooper()).post(task)
            }
            if (boundary == "PRE_CROSS") KeyguardOrbSurfaceWorkerTestHooks.beforeRevealCross = {
                gateEntered.countDown(); check(releaseGate.await(15, TimeUnit.SECONDS))
            }
            if (boundary == "IN_FLIGHT") KeyguardOrbSurfaceWorkerTestHooks.afterRevealCross = {
                gateEntered.countDown(); check(releaseGate.await(15, TimeUnit.SECONDS))
            }
            instrumentation.runOnMainSync {
                assertTrue("input panel was not armed", holder.promote(1, content, geometry))
                producer.revealR18(21, 34, crossGrantBoundary = { !r21 || coordinator.crossSubmitBoundary(permit) },
                    nativeApplied = {
                        val accepted = !r21 || coordinator.markNativeApplyReturned(permit) != null
                        if (accepted) nativeApplyCount.incrementAndGet()
                        accepted
                    }) {
                    if (it && r21) assertTrue(coordinator.revealSubmitted(permit)) else if (!it && !r21) error.set("revealFailed")
                    reveal.countDown()
                }
            }
            if (r21 && boundary != "APPLIED") {
                assertTrue("requested native boundary was not reached", gateEntered.await(10, TimeUnit.SECONDS))
                val outcome = coordinator.arbitrateIngress(token, host, output, retainApplied = true)
                assertEquals(if (boundary == "PRE_CROSS") KeyguardOrbPresentationCoordinator.SubmitPhase.PRE_CROSS
                    else KeyguardOrbPresentationCoordinator.SubmitPhase.CROSSED, outcome.phase)
                assertEquals(KeyguardOrbPresentationCoordinator.IngressAction.CANCEL_PENDING, outcome.action)
                val withdrawal = requireNotNull(coordinator.seal(token, authority, 202, true))
                assertEquals(boundary == "IN_FLIGHT", withdrawal.crossedSubmitBoundary)
                // This call must return while the compositor is held; only the
                // lane itself waits. Its queued retirement follows any in-flight apply.
                producer.sealR18(21, 34)
                releaseGate.countDown()
                assertTrue("retired native output did not drain", drained.await(10, TimeUnit.SECONDS))
                assertTrue(coordinator.hostRemoved(token, host)); assertTrue(coordinator.retired(token))
                assertTrue(coordinator.outputDrained(token, output))
                instrumentation.runOnMainSync { holder.remove(1) }
                val after = awaitScreenshot(10_000) { screenshot ->
                    colorDistance(green, screenshot.getPixel(100 + size / 2, 250 + size / 2)) <= 15
                }
                after.save(File(runDir, "r21-$boundary-after-drain.png")); after.recycle()
                val trace = synchronized(receipts) { receipts.toList() }
                val retireAt = trace.indexOfFirst { it.startsWith("RETIRE:") }
                val revealAt = trace.indexOfFirst { it.startsWith("REVEAL:") }
                assertTrue("native retirement apply return missing: $trace", retireAt >= 0)
                if (boundary == "PRE_CROSS") assertEquals("cancelled pre-cross applied a show", -1, revealAt)
                else assertTrue("native hide did not follow the crossed show: $trace", revealAt >= 0 && revealAt < retireAt)
                assertFalse(coordinator.revealSubmitted(permit))
                fixture.writeText("scene=synthetic-policy boundary=$boundary child=${childId.get()} receipts=$trace physical=UNOBSERVED\n")
                return
            }
            if (r21) {
                assertTrue("actual native return and queued acknowledgement were not reached", ackQueued.await(10, TimeUnit.SECONDS))
                assertEquals(KeyguardOrbPresentationCoordinator.Grant.REVEAL_QUEUED, coordinator.snapshot().grant)
                val positive = KeyguardCardVisibilityPolicy.decide(KeyguardCardSignals(true, true, true, true,
                    true, true, true, KeyguardSurface.MAIN_KEYGUARD, true))
                assertEquals(KeyguardCardVisibility.SHOW_FULL, positive)
                val arbitration = coordinator.arbitrateIngress(token, host, output, retainApplied = true)
                assertEquals(KeyguardOrbPresentationCoordinator.SubmitPhase.APPLIED, arbitration.phase)
                assertEquals(KeyguardOrbPresentationCoordinator.IngressAction.KEEP_SUBMITTED, arbitration.action)
                assertSame("benign recheck changed the native child", output,
                    instrumentation.runOnMainValue { producer.r18PreparedOutput(21, 34, selected, true, size, size) })
                assertSame(token, coordinator.snapshot().reservation)
            } else assertTrue("real reveal did not complete", reveal.await(10, TimeUnit.SECONDS))
            assertNull(error.get())
            assertEquals("exact first native apply must be acknowledged once", 1, nativeApplyCount.get())
            var samples = 0
            val liveScreen = awaitScreenshot(10_000) { screenshot ->
                val sample = crop(host, screenshot)
                try {
                    if (samples++ < 8) sample.save(File(runDir, "first-sample-${samples}.png"))
                    r20Compare(refA, sample).nearlyEqual()
                } finally { sample.recycle() }
            }
            val live = crop(host, liveScreen); liveScreen.recycle(); live.save(File(runDir, "first-live.png"))
            assertTrue("first image differs from independent canonical phase", r20Compare(refA, live).nearlyEqual())
            assertTrue("first exterior changed from underlay", colorDistance(green, live.getPixel(0, 0)) <= 15)
            assertTrue("first center matches neutral background", colorDistance(green, live.getPixel(size / 2, size / 2)) > 45)
            assertTrue("first edge differs from reference", colorDistance(refA.getPixel(size / 2, 1), live.getPixel(size / 2, 1)) <= 15)
            instrumentation.runOnMainSync { producer.setMotionAllowed(true) }
            val motionScreen = awaitScreenshot(10_000) { screenshot ->
                val sample = crop(host, screenshot)
                try { r20Compare(refA, sample).meaningful() } finally { sample.recycle() }
            }
            val moving = crop(host, motionScreen); motionScreen.recycle(); moving.save(File(runDir, "first-motion.png")); moving.recycle()
            fixture.writeText("scene=${if (r21) "synthetic-policy-recheck" else "r20-control"} ticket=201 attachment=21 generation=34 child=${childId.get()} firstEntry=${firstEntry.get()} firstPost=${firstPostAt.get()} posterCreated=${posterCount.get()} firstDraw=${drawMethod.get()} firstDrawCount=${firstDrawCount.get()} posts=${postCount.get()} samples=$samples\n")
            if (expectWarm || forceCold) {
                assertTrue("first-frame timing was not observed", r20Wait(5_000) { r27First.get() != null })
                val first = checkNotNull(r27First.get())
                if (expectWarm) {
                    assertEquals("HIT", first.warmStatus)
                    assertTrue("program constructor was not timed", first.warmConstructorNs > 0)
                    assertEquals(listOf("WARM"), synchronized(programConstructors) { programConstructors.toList() })
                } else {
                    assertEquals("NO_READY", first.warmStatus)
                    assertEquals(listOf("COLD"), synchronized(programConstructors) { programConstructors.toList() })
                }
            }
            assertEquals("ticketed first miss must make no intermediate bitmap", 0, posterCount.get())
            assertEquals("the actual first draw must use direct miss", "DIRECT_MISS", drawMethod.get())
            assertEquals("ticket must draw its first frame exactly once", 1, firstDrawCount.get())
            assertTrue("animated target did not produce later posts", postCount.get() > 1)
            live.recycle()
            if (r21) {
                val negative = KeyguardCardVisibilityPolicy.decide(KeyguardCardSignals(true, true, true, true,
                    true, true, true, KeyguardSurface.SHADE, true))
                assertEquals(KeyguardCardVisibility.HIDDEN_SHADE, negative)
                assertNotNull(coordinator.seal(token, authority, 202, true))
            }
            producer.sealR18(21, 34)
            assertTrue("actual direct child did not drain", drained.await(10, TimeUnit.SECONDS))
            if (r21) {
                assertTrue(coordinator.hostRemoved(token, host)); assertTrue(coordinator.retired(token))
                assertTrue(coordinator.outputDrained(token, output))
                instrumentation.runOnMainSync { holder.remove(1) }
                val after = awaitScreenshot(10_000) { screenshot ->
                    colorDistance(green, screenshot.getPixel(100 + size / 2, 250 + size / 2)) <= 15
                }
                after.save(File(runDir, "r21-after-native-drain.png")); after.recycle()
                instrumentation.runOnMainSync { checkNotNull(heldAck.getAndSet(null)).run() }
                assertTrue("late acknowledgement did not return", reveal.await(5, TimeUnit.SECONDS))
                assertFalse("late acknowledgement revived the old permit", coordinator.revealSubmitted(permit))
                assertEquals(KeyguardOrbPresentationCoordinator.Grant.RETIRED, coordinator.snapshot().grant)
            }
        } finally {
            releaseGate.countDown()
            releaseWarmLoad.countDown()
            KeyguardOrbSurfaceWorkerTestHooks.beforeDirectArtifactLoad = null
            KeyguardOrbSurfaceWorkerTestHooks.beforeRevealCross = null
            KeyguardOrbSurfaceWorkerTestHooks.afterRevealCross = null
            KeyguardOrbSurfaceWorkerTestHooks.dispatchRevealDone = priorDispatcher
            heldAck.getAndSet(null)?.let { Handler(Looper.getMainLooper()).post(it) }
            KeyguardOrbSurfaceWorkerTestHooks.afterDirectProgramWarm = null
            KeyguardOrbSurfaceWorkerTestHooks.onDirectProgramConstructor = null
            KeyguardOrbSurfaceWorkerTestHooks.afterPosterCreated = null
            KeyguardOrbSurfaceWorkerTestHooks.afterFirstFrameDraw = null
            KeyguardOrbSurfaceWorkerTestHooks.afterCanvasPost = null
            refs.forEach(Bitmap::recycle)
            instrumentation.runOnMainSync { panel?.remove(1); cleanup.getAndSet(null)?.invoke(); presenter?.dispose(); activity.finish() }
        }
    }

    /** The FULL cache is primed through the existing authorized worker setup;
     * normal direct retirement discards FULL cache, so this is a scoped lookup
     * control rather than a claim of a cross-wake service hit. */
    @Test fun r20ExactAuthorizedPosterHitAvoidsAnotherBuild() {
        assumeTrue(Build.VERSION.SDK_INT == 35)
        val context = instrumentation.targetContext
        val activity = instrumentation.startActivitySync(Intent(context, KeyguardMaterialTestActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) as KeyguardMaterialTestActivity
        val warmed = CountDownLatch(1); val allocated = CountDownLatch(1); val posted = CountDownLatch(1)
        val drained = CountDownLatch(1); val builds = AtomicInteger(); val method = AtomicReference<String?>()
        val firstDraw = AtomicReference<String?>(); val failure = AtomicReference<String?>()
        var presenter: KeyguardOrbSurfacePresenter? = null
        try {
            val size = context.resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_orb_size)
            val selected = r20CalibratedProfile()
            KeyguardOrbSurfaceWorkerTestHooks.afterWarmPosterCreated = { full -> if (full) warmed.countDown() }
            instrumentation.runOnMainSync {
                val root = FrameLayout(activity); activity.setContentView(root)
                presenter = KeyguardOrbSurfacePresenter(activity, root, onFirstPosted = { _, _ -> },
                    onFailure = { failure.set(it) }, isCaptureActive = { true },
                    onR18Allocated = { _, _, _ -> allocated.countDown() },
                    onR18Prepared = { _, _, _ -> posted.countDown() },
                    onR18Drained = { _, _, _ -> drained.countDown() },
                    onR18Failure = { _, _, reason, done -> failure.set(reason); done(); posted.countDown() },
                    onR19Observation = { observation -> observation.firstFrame?.let { sample ->
                        method.set(sample.method)
                        throw IllegalStateException("injected-diagnostic-observer")
                    } })
                checkNotNull(presenter).prepare(selected, size, size, allowFull = true)
            }
            assertTrue("authorized exact FULL poster was not prepared", warmed.await(20, TimeUnit.SECONDS))
            KeyguardOrbSurfaceWorkerTestHooks.afterPosterCreated = { if (it.firstDirectAuthorization.get()?.requestId == 601L) builds.incrementAndGet() }
            KeyguardOrbSurfaceWorkerTestHooks.afterFirstFrameDraw = { target, path ->
                if (target.firstDirectAuthorization.get()?.requestId == 601L) firstDraw.set(path)
            }
            instrumentation.runOnMainSync { assertTrue(checkNotNull(presenter).prepareR18(61, 62, selected, size, size,
                full = true, emptyAwaitingDisclosure = true)) }
            assertTrue("hit-control target was not allocated", allocated.await(20, TimeUnit.SECONDS))
            instrumentation.runOnMainSync { assertTrue(checkNotNull(presenter).authorizeR19First(61, 62, selected,
                KeyguardR19FirstPaintTicket(61, 62, 601, 1, 1, selected.visualKey))) }
            assertTrue("hit-control actual post missing", posted.await(20, TimeUnit.SECONDS)); assertNull(failure.get())
            assertTrue("summary was not emitted", r20Wait(5_000) { method.get() != null })
            assertEquals("BITMAP_HIT", method.get()); assertEquals("BITMAP", firstDraw.get()); assertEquals(0, builds.get())
            instrumentation.runOnMainSync { assertNotNull(checkNotNull(presenter).r18PreparedOutput(61, 62, selected, true, size, size)) }
            presenter?.sealR18(61, 62)
            assertTrue("hit-control target failed to drain", drained.await(10, TimeUnit.SECONDS))
        } finally {
            KeyguardOrbSurfaceWorkerTestHooks.afterWarmPosterCreated = null
            KeyguardOrbSurfaceWorkerTestHooks.afterPosterCreated = null
            KeyguardOrbSurfaceWorkerTestHooks.afterFirstFrameDraw = null
            instrumentation.runOnMainSync { presenter?.dispose(); activity.finish() }
        }
    }

    @Test fun r20FailedFirstLockOrPostNeverPublishesReady() {
        assumeTrue(Build.VERSION.SDK_INT == 35)
        for (stage in listOf("LOCK", "POST")) {
            val context = instrumentation.targetContext
            val activity = instrumentation.startActivitySync(Intent(context, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) as KeyguardMaterialTestActivity
            val allocated = CountDownLatch(1); val failed = CountDownLatch(1); val drained = CountDownLatch(1)
            val readyCount = AtomicInteger(); val reason = AtomicReference<String?>()
            val firstSummary = AtomicReference<KeyguardR20FirstFrameObservation?>()
            var presenter: KeyguardOrbSurfacePresenter? = null
            try {
                val size = context.resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_orb_size)
                val selected = r20CalibratedProfile()
                if (stage == "LOCK") KeyguardOrbSurfaceWorkerTestHooks.beforeFirstLock = {
                    if (it.firstDirectAuthorization.get()?.requestId == 701L) error("injected-before-lock")
                } else KeyguardOrbSurfaceWorkerTestHooks.beforeFirstPost = {
                    if (it.firstDirectAuthorization.get()?.requestId == 701L) error("injected-before-post")
                }
                instrumentation.runOnMainSync {
                    val root = FrameLayout(activity); activity.setContentView(root)
                    presenter = KeyguardOrbSurfacePresenter(activity, root, onFirstPosted = { _, _ -> },
                        onFailure = { reason.set(it); failed.countDown() }, isCaptureActive = { true },
                        onR18Allocated = { _, _, _ -> allocated.countDown() },
                        onR18Prepared = { _, _, _ -> readyCount.incrementAndGet() },
                        onR18Drained = { _, _, _ -> drained.countDown() },
                        onR18Failure = { _, _, why, done -> reason.set(why); done(); failed.countDown() },
                        onR19Observation = { it.firstFrame?.let(firstSummary::set) })
                    assertTrue(checkNotNull(presenter).prepareR18(71, 72, selected, size, size,
                        full = true, emptyAwaitingDisclosure = true))
                }
                assertTrue("$stage target not allocated", allocated.await(20, TimeUnit.SECONDS))
                instrumentation.runOnMainSync { assertTrue(checkNotNull(presenter).authorizeR19First(71, 72, selected,
                    KeyguardR19FirstPaintTicket(71, 72, 701, 1, 1, selected.visualKey))) }
                assertTrue("$stage failure did not reach exact-owner callback", failed.await(20, TimeUnit.SECONDS))
                assertNotNull(reason.get()); assertEquals("$stage must not publish ready", 0, readyCount.get())
                assertTrue("$stage first summary missing", r20Wait(5_000) { firstSummary.get() != null })
                assertTrue("wrong failure stage: ${firstSummary.get()}", firstSummary.get()!!.failure?.startsWith(stage) == true)
                assertEquals(0L, firstSummary.get()!!.postReturnNs)
                assertNull(instrumentation.runOnMainValue { checkNotNull(presenter).r18PreparedOutput(71, 72, selected, true, size, size) })
                assertTrue("$stage failed owner did not drain", drained.await(10, TimeUnit.SECONDS))
            } finally {
                KeyguardOrbSurfaceWorkerTestHooks.beforeFirstLock = null
                KeyguardOrbSurfaceWorkerTestHooks.beforeFirstPost = null
                instrumentation.runOnMainSync { presenter?.dispose(); activity.finish() }
            }
        }
    }

    @Test fun r20HeldFirstWriteCannotReadyRetiredOwnerOrHideSuccessor() {
        assumeTrue(Build.VERSION.SDK_INT == 35)
        val context = instrumentation.targetContext
        val activity = instrumentation.startActivitySync(Intent(context, KeyguardMaterialTestActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) as KeyguardMaterialTestActivity
        val firstLock = CountDownLatch(1); val releaseFirst = CountDownLatch(1); val firstLatePost = CountDownLatch(1)
        val hosts = ConcurrentHashMap<Long, View>(); val hostWait = ConcurrentHashMap<Long, CountDownLatch>()
        val allocated = ConcurrentHashMap<Long, CountDownLatch>(); val posted = ConcurrentHashMap<Long, CountDownLatch>()
        val drained = ConcurrentHashMap<Long, CountDownLatch>(); val firstReady = AtomicInteger()
        val failure = AtomicReference<String?>(); val cleanup = AtomicReference<(() -> Unit)?>(null)
        val blocker = AtomicBoolean(true)
        var presenter: KeyguardOrbSurfacePresenter? = null; var panel: KeyguardOrbInertHost? = null
        try {
            val size = context.resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_orb_size)
            val selected = r20CalibratedProfile(); val green = Color.rgb(11, 177, 67)
            lateinit var producer: KeyguardOrbSurfacePresenter; lateinit var holder: KeyguardOrbInertHost
            lateinit var content: FrameLayout
            instrumentation.runOnMainSync {
                activity.setContentView(FrameLayout(activity).apply { setBackgroundColor(green) })
                content = FrameLayout(activity).apply { setBackgroundColor(Color.TRANSPARENT) }
                holder = KeyguardOrbInertHost(activity, PanelWindowManager(activity),
                    onReady = { generation, view, _ -> hosts[generation] = view; hostWait[generation]?.countDown() },
                    onFailure = { generation, why -> failure.set(why); hostWait[generation]?.countDown() })
                panel = holder
                producer = KeyguardOrbSurfacePresenter(activity, content, onFirstPosted = { _, _ -> },
                    onFailure = { failure.set(it) }, isCaptureActive = { true },
                    onR18Allocated = { _, generation, _ -> allocated[generation]?.countDown() },
                    onR18Prepared = { _, generation, _ -> if (generation == 81L) firstReady.incrementAndGet(); posted[generation]?.countDown() },
                    onR18Drained = { _, generation, _ -> drained[generation]?.countDown() },
                    onR18Failure = { _, _, why, done -> failure.set(why); cleanup.set(done) })
                presenter = producer
            }
            val screenshot = checkNotNull(instrumentation.uiAutomation.takeScreenshot())
            val geometry = KeyguardOverlayGeometry(size, size, 100, 250,
                KeyguardUsableBounds(0, 0, screenshot.width, screenshot.height), KeyguardCardCardPosition(.5f),
                KeyguardCardOrbPosition(.5f, .5f)); screenshot.recycle()
            for (g in listOf(81L, 82L)) { hostWait[g] = CountDownLatch(1); allocated[g] = CountDownLatch(1); posted[g] = CountDownLatch(1); drained[g] = CountDownLatch(1) }
            KeyguardOrbSurfaceWorkerTestHooks.afterCanvasLock = { target ->
                if (target.generation == 81L && blocker.compareAndSet(true, false)) { firstLock.countDown(); releaseFirst.await(15, TimeUnit.SECONDS) }
            }
            KeyguardOrbSurfaceWorkerTestHooks.afterCanvasPost = { if (it.generation == 81L && it.revoked) firstLatePost.countDown() }
            instrumentation.runOnMainSync {
                assertTrue(producer.prepareR18(81, 81, selected, size, size, full = true, emptyAwaitingDisclosure = true))
                assertTrue(holder.stage(81, geometry))
            }
            assertTrue(allocated.getValue(81).await(20, TimeUnit.SECONDS)); assertTrue(hostWait.getValue(81).await(20, TimeUnit.SECONDS))
            val boundA = CountDownLatch(1)
            instrumentation.runOnMainSync { producer.bindR18(checkNotNull(hosts[81]), 81, 81) { if (!it) failure.set("bindA"); boundA.countDown() } }
            assertTrue(boundA.await(10, TimeUnit.SECONDS)); assertNull(failure.get())
            instrumentation.runOnMainSync { assertTrue(producer.authorizeR19First(81, 81, selected,
                KeyguardR19FirstPaintTicket(81, 81, 801, 1, 1, selected.visualKey))) }
            assertTrue("first real lock was not held", firstLock.await(15, TimeUnit.SECONDS))
            instrumentation.runOnMainSync {
                producer.sealR18(81, 81); assertTrue(holder.remove(81))
                assertTrue(producer.prepareR18(82, 82, selected, size, size, full = true, emptyAwaitingDisclosure = true))
                assertTrue(holder.stage(82, geometry))
            }
            releaseFirst.countDown()
            assertTrue("entered old worker did not finish", firstLatePost.await(10, TimeUnit.SECONDS))
            assertTrue("old output did not drain", drained.getValue(81).await(10, TimeUnit.SECONDS))
            assertEquals("retired first write published ready", 0, firstReady.get())
            assertTrue(allocated.getValue(82).await(20, TimeUnit.SECONDS)); assertTrue(hostWait.getValue(82).await(20, TimeUnit.SECONDS))
            val boundB = CountDownLatch(1); val revealB = CountDownLatch(1)
            instrumentation.runOnMainSync {
                producer.setMotionAllowed(false)
                producer.bindR18(checkNotNull(hosts[82]), 82, 82) { if (!it) failure.set("bindB"); boundB.countDown() }
            }
            assertTrue(boundB.await(10, TimeUnit.SECONDS)); assertNull(failure.get())
            instrumentation.runOnMainSync { assertTrue(producer.authorizeR19First(82, 82, selected,
                KeyguardR19FirstPaintTicket(82, 82, 802, 1, 1, selected.visualKey))) }
            assertTrue("fresh successor did not post", posted.getValue(82).await(20, TimeUnit.SECONDS)); assertNull(failure.get())
            instrumentation.runOnMainSync {
                assertTrue(holder.promote(82, content, geometry))
                producer.revealR18(82, 82, { true }, { true }) { if (!it) failure.set("revealB"); revealB.countDown() }
            }
            assertTrue(revealB.await(10, TimeUnit.SECONDS)); assertNull(failure.get())
            val location = IntArray(2); instrumentation.runOnMainSync { checkNotNull(hosts[82]).getLocationOnScreen(location) }
            val cx = location[0] + size / 2; val cy = location[1] + size / 2
            val live = awaitScreenshot(10_000) { colorDistance(green, it.getPixel(cx, cy)) > 45 }; live.recycle()
            producer.sealR18(81, 81)
            val afterOld = checkNotNull(instrumentation.uiAutomation.takeScreenshot())
            assertTrue("stale old seal hid the new owner", colorDistance(green, afterOld.getPixel(cx, cy)) > 45); afterOld.recycle()
            producer.sealR18(82, 82); assertTrue(drained.getValue(82).await(10, TimeUnit.SECONDS))
        } finally {
            releaseFirst.countDown(); KeyguardOrbSurfaceWorkerTestHooks.afterCanvasLock = null
            KeyguardOrbSurfaceWorkerTestHooks.afterCanvasPost = null
            instrumentation.runOnMainSync { panel?.remove(81); panel?.remove(82); cleanup.getAndSet(null)?.invoke(); presenter?.dispose(); activity.finish() }
        }
    }

    private data class R20PixelComparison(val changed: Int, val total: Long, val max: Int) {
        fun nearlyEqual() = max <= 2 && total <= 2_048L
        fun meaningful() = changed >= 64 && total >= 2_048L
    }
    private fun r20Compare(a: Bitmap, b: Bitmap): R20PixelComparison {
        require(a.width == b.width && a.height == b.height)
        var changed = 0; var total = 0L; var maximum = 0
        for (y in 0 until a.height) for (x in 0 until a.width) {
            val dx = x + .5f - a.width / 2f; val dy = y + .5f - a.height / 2f
            if (dx * dx + dy * dy >= a.width * a.width * .1764f) continue
            val left = a.getPixel(x, y); val right = b.getPixel(x, y)
            val delta = maxOf(kotlin.math.abs(Color.red(left) - Color.red(right)),
                kotlin.math.abs(Color.green(left) - Color.green(right)), kotlin.math.abs(Color.blue(left) - Color.blue(right)))
            if (delta >= 7) changed += 1
            total += delta; maximum = maxOf(maximum, delta)
        }
        return R20PixelComparison(changed, total, maximum)
    }
    private fun r20Wait(timeoutMs: Long, predicate: () -> Boolean): Boolean {
        val deadline = SystemClock.uptimeMillis() + timeoutMs
        while (SystemClock.uptimeMillis() < deadline) { if (predicate()) return true; SystemClock.sleep(25) }
        return false
    }
    private fun r20CalibratedProfile(): KeyguardMaterialProfile {
        val base = profile()
        return base.copy(background = base.background.copy(enabled = true, phaseSpeed = .2f,
            settings = FloatArray(12) { .2f }), interior = base.interior.copy(phaseSpeed = .2f,
            settings = FloatArray(12) { .2f }))
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
