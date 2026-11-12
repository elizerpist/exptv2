package com.fluvi.app.lockscreen.material

import android.app.Instrumentation
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.PixelFormat
import android.graphics.Rect
import android.os.Build
import android.os.SystemClock
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.view.WindowManager
import android.widget.FrameLayout
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.fluvi.app.lockscreen.KeyguardCardAnimationMode
import com.fluvi.app.lockscreen.KeyguardCardContentOverflow
import com.fluvi.app.lockscreen.KeyguardFrameCommitObservation
import com.fluvi.app.lockscreen.KeyguardCardWindow
import com.fluvi.app.lockscreen.KeyguardDrawPublication
import com.fluvi.app.lockscreen.KeyguardFirstDrawOwner
import com.fluvi.app.lockscreen.KeyguardFirstDrawEvent
import com.fluvi.app.lockscreen.KeyguardCardSettings
import com.fluvi.app.lockscreen.KeyguardCardPresentationMode
import com.fluvi.app.lockscreen.KeyguardCardCardPosition
import com.fluvi.app.lockscreen.KeyguardCardOrbPosition
import com.fluvi.app.runtime.FluviFinancialCardPresenter
import com.fluvi.app.lockscreen.keyguardCardWindowParameters
import com.fluvi.app.lockscreen.resolveKeyguardCardGeometry
import com.fluvi.app.R
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicReference
import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * This is deliberately a production-asset smoke, not a toy AGSL string.  It
 * proves RuntimeShader construction and one actual hardware Canvas draw on
 * an API-33+ device/emulator; compositor screenshots observe the window
 * rather than a software Bitmap Canvas substitute.
 */
@RunWith(AndroidJUnit4::class)
class KeyguardHeaderMaterialViewInstrumentationTest {
    @Test fun detachedPreparationConstructsAndPromotesTheSelectedProgram() {
        assumeTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val activity = instrumentation.startActivitySync(
            Intent(instrumentation.targetContext, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        lateinit var view: KeyguardHeaderMaterialView
        var controller: KeyguardCardMaterialController? = null
        try {
            instrumentation.runOnMainSync {
                view = KeyguardHeaderMaterialView(activity).apply {
                    layoutParams = FrameLayout.LayoutParams(160, 160)
                }
                controller = KeyguardCardMaterialController(
                    view,
                    KeyguardHeaderMaterialView(activity),
                    View(activity),
                    gpuPreparer = ImmediateGpuPreparer(),
                )
                // This is the retained-root path before any setScene(),
                // attachment, or hardware Canvas. A successful compilation
                // must be real, not the old null-scene no-op diagnostic.
                controller!!.prepare(
                    profile(), KeyguardCardAnimationMode.ORB_ONLY,
                    com.fluvi.app.lockscreen.KeyguardCardPresentationMode.ORB,
                )
            }
            assertTrue("detached view never prepared a program", waitForDetachedPrepared(instrumentation, view))
            var attemptsBeforeAttach = 0
            instrumentation.runOnMainSync {
                attemptsBeforeAttach = view.diagnostics().shaderCompileAttempts
                assertEquals(0, controller!!.diagnostics().frameCallbackCount)
                controller!!.update(
                    profile = profile(), animationMode = KeyguardCardAnimationMode.ORB_ONLY,
                    presentationMode = com.fluvi.app.lockscreen.KeyguardCardPresentationMode.ORB,
                    isFull = true, staticOrb = null,
                )
                activity.setContentView(FrameLayout(activity).apply { addView(view) })
                controller!!.onAttached()
                controller!!.onBootstrapFrameCommitted(requireNotNull(controller!!.currentBootstrapToken()))
            }
            assertTrue("prepared program was not promoted to a shader draw", waitForPreparedShader(instrumentation, view))
            instrumentation.runOnMainSync {
                assertEquals(attemptsBeforeAttach, view.diagnostics().shaderCompileAttempts)
            }
        } finally {
            instrumentation.runOnMainSync {
                controller?.dispose()
                activity.finish()
            }
        }
    }

    @Test fun preparedProductionViewDoesNoAssetOrCompileWorkAcrossFrames() {
        assumeTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val activity = instrumentation.startActivitySync(
            Intent(instrumentation.targetContext, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        lateinit var view: KeyguardHeaderMaterialView
        var controller: KeyguardCardMaterialController? = null
        val artifactLoads = AtomicInteger(0)
        try {
            instrumentation.runOnMainSync {
                view = KeyguardHeaderMaterialView(activity).apply {
                    layoutParams = FrameLayout.LayoutParams(160, 160)
                }
                val background = KeyguardHeaderMaterialView(activity)
                val reader = KeyguardShaderArtifactReader { context, effectId, usesPortal ->
                    artifactLoads.incrementAndGet()
                    AndroidKeyguardShaderArtifactReader.load(context, effectId, usesPortal)
                }
                controller = KeyguardCardMaterialController(
                    view, background, View(activity),
                    artifacts = KeyguardShaderArtifactStore(activity, reader),
                    gpuPreparer = ImmediateGpuPreparer(),
                )
                controller!!.update(
                    profile = profile(), animationMode = KeyguardCardAnimationMode.ORB_ONLY,
                    presentationMode = com.fluvi.app.lockscreen.KeyguardCardPresentationMode.ORB,
                    isFull = true, staticOrb = null,
                )
                activity.setContentView(FrameLayout(activity).apply { addView(view) })
                controller!!.onAttached()
                controller!!.onBootstrapFrameCommitted(requireNotNull(controller!!.currentBootstrapToken()))
            }
            // A hardware Canvas can draw the safe fallback before the artifact
            // lane has handed its result back to the main-thread View.  Start
            // the 120-frame invariant only after the prepared RuntimeShader
            // actually drew, otherwise the test would count the intentional
            // one-time preparation as frame-path work.
            assertTrue("prepared view never reached a shader draw", waitForPreparedShader(instrumentation, view))
            val before = view.diagnostics()
            val loadsBeforeFrames = artifactLoads.get()
            instrumentation.runOnMainSync {
                val canvas = Canvas(Bitmap.createBitmap(160, 160, Bitmap.Config.ARGB_8888))
                repeat(120) { view.draw(canvas) }
            }
            val after = view.diagnostics()
            assertEquals(loadsBeforeFrames, artifactLoads.get())
            assertEquals(before.shaderCompileAttempts, after.shaderCompileAttempts)
            assertEquals(0, after.assetOpenCountDuringDraw)
            assertEquals(0, after.metadataParseCountDuringDraw)
            assertEquals(0, after.shaderCompileCountDuringDraw)
            assertTrue(after.phaseAdvanceCount >= before.phaseAdvanceCount)
        } finally {
            instrumentation.runOnMainSync {
                controller?.dispose()
                activity.finish()
            }
        }
    }

    @Test fun identicalMaterialInputDoesNotReplaceTheRetainedScene() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val activity = instrumentation.startActivitySync(
            Intent(instrumentation.targetContext, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        try {
            instrumentation.runOnMainSync {
                val controller = KeyguardCardMaterialController(
                    KeyguardHeaderMaterialView(activity),
                    KeyguardHeaderMaterialView(activity),
                    View(activity),
                )
                repeat(10) {
                    controller.update(
                        profile = profile(),
                        animationMode = KeyguardCardAnimationMode.ORB_ONLY,
                        presentationMode = com.fluvi.app.lockscreen.KeyguardCardPresentationMode.ORB,
                        isFull = true,
                        staticOrb = null,
                    )
                }
                val same = controller.diagnostics()
                assertEquals(1, same.configurationUpdateCount)
                assertEquals(9, same.configurationNoOpCount)
                controller.update(
                    profile = profile(),
                    animationMode = KeyguardCardAnimationMode.ORB_ONLY,
                    presentationMode = com.fluvi.app.lockscreen.KeyguardCardPresentationMode.ORB,
                    isFull = false,
                    staticOrb = null,
                )
                assertEquals(2, controller.diagnostics().configurationUpdateCount)
                controller.dispose()
            }
        } finally {
            instrumentation.runOnMainSync { activity.finish() }
        }
    }

    @Test fun productionKeyguardCardHasOneFixedMeasuredWindowExtent() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val activity = instrumentation.startActivitySync(
            Intent(instrumentation.targetContext, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        try {
            instrumentation.runOnMainSync {
                val resources = activity.resources
                val height = resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_card_height)
                val geometry = resolveKeyguardCardGeometry(
                    displayWidthPx = (392 * resources.displayMetrics.density).toInt(),
                    density = resources.displayMetrics.density,
                    heightPx = height,
                    verticalOffsetDp = 0,
                )
                assertEquals(height, keyguardCardWindowParameters(geometry).height)
                val narrow = resolveKeyguardCardGeometry(
                    displayWidthPx = (200 * resources.displayMetrics.density).toInt(),
                    density = resources.displayMetrics.density,
                    heightPx = height,
                    verticalOffsetDp = 0,
                )
                assertEquals(
                    (200 * resources.displayMetrics.density).toInt() -
                        (16 * resources.displayMetrics.density).toInt() * 2,
                    narrow.width,
                )

                // These cover every presentation and material state that can
                // change visibility.  They are measured inside the same fixed
                // parent extent used by the real WindowManager window.
                listOf(
                    CardState("loading", false, false, "Betöltés", "…", ""),
                    CardState("discreet", false, false, "Fluvi", "Rejtett", ""),
                    CardState("full", true, true, "Balance · Hónap", "+15 200 Ft", "Hónap nettó"),
                    CardState("last-item", true, true, "Balance · Hónap", "+15 200 Ft", "Hónap nettó"),
                    CardState("no-data", false, false, "Balance", "Nincs adat", "Frissítés után megjelenik"),
                    CardState("content-error", false, false, "Balance", "Nem elérhető", "Próbáld újra az appban"),
                    CardState("orb-only", false, false, "Balance", "+15 200 Ft", "Hónap nettó"),
                    CardState("orb-and-background", false, false, "Balance", "+15 200 Ft", "Hónap nettó"),
                    CardState("animation-off", false, false, "Balance", "+15 200 Ft", "Hónap nettó"),
                ).forEach { state ->
                    val card = inflatedCard(activity)
                    populate(card, state)
                    measureFromXmlDefinition(card, geometry.width, height)
                    assertCardExtent(card, height, state.name)
                    measureInWindowParent(card, geometry.width, height)
                    assertCardExtent(card, height, state.name)
                    assertNoReservedAreaOverlap(card, state.name)
                }

                // Font scaling remains enabled. The two optional lines yield
                // in priority order rather than changing the card extent or
                // wrapping the primary value.
                val largeTextContext = activity.createConfigurationContext(
                    Configuration(resources.configuration).apply { fontScale = 2f },
                )
                val longCard = inflatedCard(largeTextContext)
                populate(
                    longCard,
                    CardState(
                        "large-text",
                        true,
                        true,
                        "Balance · Hónap · nagyon hosszú fókuszcímke",
                        "+15 200 000 Ft nagyon hosszú elsődleges érték",
                        "Hosszú másodlagos magyarázó sor",
                    ),
                )
                measureFromXmlDefinition(longCard, geometry.width, height)
                assertCardExtent(longCard, height, "large-text")
                measureInWindowParent(longCard, geometry.width, height)
                KeyguardCardContentOverflow.fit(longCard)
                measureInWindowParent(longCard, geometry.width, height)
                KeyguardCardContentOverflow.fit(longCard)
                measureInWindowParent(longCard, geometry.width, height)
                assertCardExtent(longCard, height, "large-text")
                assertNoReservedAreaOverlap(longCard, "large-text")
            }
        } finally {
            instrumentation.runOnMainSync { activity.finish() }
        }
    }

    @Test fun productionAssetCompilesAndDrawsCalibratedHardwareCanvas() {
        assumeTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        // Every generated, packaged production effect program must construct.
        // This catches a strict-SkSL program-size or syntax regression in a
        // less-common Header effect before the selected profile reaches a
        // physical lockscreen.
        KeyguardMaterialProfile.effectIds.forEach { effectId ->
            KeyguardHeaderShader(context, effectId, false)
        }

        val profile = calibratedOrbProfile()
        val controlledTime = AtomicReference(calibratedMaterialTime(PHASE_A))
        lateinit var view: KeyguardHeaderMaterialView
        var imageA: Bitmap? = null
        var imageFrozenA: Bitmap? = null
        var imageC: Bitmap? = null
        var imageB: Bitmap? = null
        var imageReturnA: Bitmap? = null
        val activity = instrumentation.startActivitySync(
            // startActivitySync launches in the target application. This
            // debug-only host is consequently declared in src/debug rather
            // than in the instrumentation APK's manifest.
            Intent(context, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        try {
            val artifact = AndroidKeyguardShaderArtifactReader.load(context, profile.effectId, profile.usesPortal)
            instrumentation.runOnMainSync {
                activity.window.setFormat(PixelFormat.TRANSLUCENT)
                val root = FrameLayout(activity)
                view = KeyguardHeaderMaterialView(
                    activity,
                    materialTimeSource = KeyguardMaterialTimeSource { _, _ -> controlledTime.get() },
                ).apply {
                    layoutParams = FrameLayout.LayoutParams(168, 168)
                    setScene(KeyguardMaterialScene(profile, full = true, appliedAtNanos = 0L), enabled = true)
                    setBootstrapActive(false)
                    assertEquals(KeyguardHeaderMaterialView.ProgramPreparationResult.COMPILED, installPreparedShader(artifact))
                }
                root.addView(view)
                activity.setContentView(root)
                view.frame(1L)
            }
            assertTrue("production View never reached a hardware Canvas", waitForPreparedShader(instrumentation, view))
            fun capture(
                phase: Float,
                label: String,
                accepts: (Bitmap) -> Boolean,
            ): Bitmap {
                var before = 0
                instrumentation.runOnMainSync {
                    before = view.diagnostics().shaderDrawCount
                    controlledTime.set(calibratedMaterialTime(phase))
                    view.frame(System.nanoTime())
                }
                assertTrue("hardware Canvas did not draw controlled $label", waitForShaderDraw(instrumentation, view, before))
                return awaitCompositorCrop(
                    label = label,
                    capture = { copyMaterialView(instrumentation, view) },
                    persist = { evidenceLabel, bitmap -> persistPanelEvidence(activity, evidenceLabel, bitmap) },
                    accepts = accepts,
                )
            }

            imageA = capture(PHASE_A, "canvas-a") { hasVisibleMaterial(it) }
            imageFrozenA = capture(PHASE_A, "canvas-a-frozen") {
                compareMaterialPixels(requireNotNull(imageA), it).nearlyEqual()
            }
            imageC = capture(PHASE_C, "canvas-c") {
                compareMaterialPixels(requireNotNull(imageA), it).nearlyEqual()
            }
            imageB = capture(PHASE_B, "canvas-b") {
                compareMaterialPixels(requireNotNull(imageA), it).meaningful()
            }
            imageReturnA = capture(PHASE_A, "canvas-return-a") {
                compareMaterialPixels(requireNotNull(imageA), it).nearlyEqual()
            }

            // Every image is retained before assertion. The frozen and A/C
            // controls must not satisfy the meaningful-motion predicate.
            val frozen = compareMaterialPixels(requireNotNull(imageA), requireNotNull(imageFrozenA))
            val plateau = compareMaterialPixels(requireNotNull(imageA), requireNotNull(imageC))
            val positive = compareMaterialPixels(requireNotNull(imageA), requireNotNull(imageB))
            val returned = compareMaterialPixels(requireNotNull(imageA), requireNotNull(imageReturnA))
            lateinit var diagnostics: KeyguardHeaderMaterialViewDiagnostics
            instrumentation.runOnMainSync { diagnostics = view.diagnostics() }
            assertTrue(diagnostics.lastCanvasHardwareAccelerated == true)
            assertTrue("production shader did not draw", diagnostics.shaderDrawCount > 0)
            assertTrue("controlled hardware Canvas did not advance phase", diagnostics.phaseAdvanceCount > 0)
            assertTrue("frozen phase unexpectedly met motion threshold: $frozen", frozen.nearlyEqual() && !frozen.meaningful())
            assertTrue("A/C must remain within equality tolerance: $plateau", plateau.nearlyEqual())
            assertTrue("A/B must meet meaningful-motion threshold: $positive", positive.meaningful())
            assertTrue("A-B-A must return within equality tolerance: $returned", returned.nearlyEqual())
        } finally {
            imageA?.recycle()
            imageFrozenA?.recycle()
            imageC?.recycle()
            imageB?.recycle()
            imageReturnA?.recycle()
            instrumentation.runOnMainSync {
                activity.finish()
            }
        }
    }

    @Test fun bootstrapDrawsBeforeLiveShaderAndPromotesWithoutReplacingRoot() {
        assumeTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val activity = instrumentation.startActivitySync(
            Intent(instrumentation.targetContext, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        lateinit var view: KeyguardHeaderMaterialView
        lateinit var root: FrameLayout
        var controller: KeyguardCardMaterialController? = null
        val livePromotion = CountDownLatch(1)
        try {
            instrumentation.runOnMainSync {
                view = KeyguardHeaderMaterialView(activity).apply {
                    layoutParams = FrameLayout.LayoutParams(160, 160)
                }
                root = FrameLayout(activity).apply { addView(view) }
                controller = KeyguardCardMaterialController(
                    view,
                    KeyguardHeaderMaterialView(activity),
                    View(activity),
                    gpuPreparer = ImmediateGpuPreparer(),
                )
                controller!!.update(
                    profile = profile(),
                    animationMode = KeyguardCardAnimationMode.ORB_ONLY,
                    presentationMode = com.fluvi.app.lockscreen.KeyguardCardPresentationMode.ORB,
                    isFull = true,
                    staticOrb = null,
                )
                val token = requireNotNull(controller!!.currentBootstrapToken())
                lateinit var commit: KeyguardFrameCommitObservation
                commit = KeyguardFrameCommitObservation(
                    root = view,
                    attachGeneration = 1L,
                    bootstrapToken = token,
                ) { event ->
                    // This is the same functional route used by the retained
                    // keyguard root: a real bootstrap Canvas draw marks the
                    // observation, then Android delivers the frame commit.
                    controller!!.onBootstrapFrameCommitted(event.bootstrapToken)
                }
                controller!!.onBootstrapGeometryDrawn = { drawToken ->
                    commit.markExpectedDrawObserved(1L, drawToken)
                }
                controller!!.onLivePromoted = { promoted ->
                    if (promoted == token) livePromotion.countDown()
                }
                // The View is still detached here. The production observer
                // must retain this arm through the real Window attachment.
                commit.startBeforeNextDraw()
                activity.setContentView(root)
                controller!!.onAttached()
            }
            assertTrue("bootstrap never drew", waitForBootstrap(instrumentation, view))
            assertTrue("real frame commit did not promote live material", livePromotion.await(8, TimeUnit.SECONDS))
            assertTrue("live shader never followed bootstrap commit", waitForPreparedShader(instrumentation, view))
            instrumentation.runOnMainSync {
                assertFalse(view.isBootstrapActive())
                assertEquals("promotion must keep the same retained root", 1, root.childCount)
            }
        } finally {
            instrumentation.runOnMainSync {
                controller?.dispose()
                activity.finish()
            }
        }
    }

    @Test fun productionOrbWindowAutomaticallyCommitsAndRendersLiveAcrossReattach() {
        exerciseProductionWindow(KeyguardCardPresentationMode.ORB)
    }

    @Test fun productionCardWindowAutomaticallyStartsItsAnimatedBackground() {
        exerciseProductionWindow(KeyguardCardPresentationMode.CARD)
    }

    @Test fun productionOrbCaptureOffStillDrawsWithoutDetailedProbeWork() {
        exerciseProductionWindow(KeyguardCardPresentationMode.ORB, evidence = false)
    }

    /**
     * Execution-isolation regression: this holds the real API-34 buffer
     * producer only after it has published output.  Window withdrawal is the
     * production Main-owned operation and must complete without waiting for
     * the renderer thread. This is deliberately not a synthetic claim about
     * a device GPU driver's latency.
     */
    @Test fun isolatedOrbWithdrawalDoesNotWaitForBlockedRendererFrame() {
        assumeTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val activity = instrumentation.startActivitySync(
            Intent(instrumentation.targetContext, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        val enteredBlockedFrame = CountDownLatch(1)
        val releaseBlockedFrame = CountDownLatch(1)
        val blockNextRender = java.util.concurrent.atomic.AtomicBoolean(false)
        val barrier = KeyguardOrbRenderBarrier {
            // Detached preparation is allowed to render before attachment.
            // Arm only after the test has observed a real current-layer
            // output, so the held work is unquestionably a live producer
            // frame rather than a prewarm completion.
            // Consume the test gate for exactly one already-live A frame.
            // Leaving it armed would also withhold B after reattach, so the
            // test would deliberately deny the safe capacity it requires to
            // verify B-owned recovery.
            if (blockNextRender.compareAndSet(true, false)) {
                enteredBlockedFrame.countDown()
                // Bounded release keeps a broken implementation from hanging
                // an emulator job while still exposing a wait-on-renderer bug.
                releaseBlockedFrame.await(8, TimeUnit.SECONDS)
            }
        }
        lateinit var window: KeyguardCardWindow
        var createdWindow: KeyguardCardWindow? = null
        lateinit var settings: KeyguardCardSettings
        var publishedBeforeHide = 0
        try {
            instrumentation.runOnMainSync {
                window = KeyguardCardWindow(
                    serviceContext = activity,
                    onOpen = {}, onToggle = {}, onInteractionStarted = {},
                    onPositionCommitted = { _, _, _, _ -> },
                    onInteractionDiagnostic = { _, _ -> },
                    manager = TestPanelWindowManager(activity),
                    isolatedOrbRenderBarrier = barrier,
                )
                createdWindow = window
                settings = KeyguardCardSettings(
                    requested = true,
                    showFinancialDetails = true,
                    presentationMode = KeyguardCardPresentationMode.ORB,
                    animationMode = KeyguardCardAnimationMode.ORB_ONLY,
                    orbPosition = KeyguardCardOrbPosition(.5f, .5f),
                )
                window.prepareRetainedView(settings, profile())
                assertEquals(
                    KeyguardCardWindow.Result.ATTACHED,
                    window.showOrUpdate(FluviFinancialCardPresenter.loading(), settings),
                )
            }
            assertTrue("isolated ORB never published actual output", waitForIsolatedOutput(instrumentation, window))
            instrumentation.runOnMainSync {
                publishedBeforeHide = requireNotNull(window.materialDiagnostics()).isolatedFramesPublished
            }
            blockNextRender.set(true)
            assertTrue("second renderer frame never reached the real barrier",
                enteredBlockedFrame.await(8, TimeUnit.SECONDS))
            // This is the same Main-owned withdrawal path used after a
            // current negative eligibility decision. It must not join the
            // worker's in-flight HardwareBufferRenderer request.
            instrumentation.runOnMainSync {
                assertTrue("withdrawal waited for renderer", window.hide())
                assertFalse(window.isAttached)
                // Reattach before releasing the old worker completion. The
                // old lease is no longer allowed to publish into this root.
                assertEquals(
                    KeyguardCardWindow.Result.ATTACHED,
                    window.showOrUpdate(FluviFinancialCardPresenter.loading(), settings),
                )
                assertTrue(window.isAttached)
            }
            releaseBlockedFrame.countDown()
            assertTrue("new attachment did not obtain its own current output after stale release",
                waitForIsolatedOutput(instrumentation, window, publishedBeforeHide))
        } finally {
            releaseBlockedFrame.countDown()
            instrumentation.runOnMainSync {
                createdWindow?.dispose()
                activity.finish()
            }
        }
    }

    @Test fun isolatedOrbPublishesCalibratedCompositorPixels() {
        assumeTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val activity = instrumentation.startActivitySync(
            Intent(instrumentation.targetContext, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        lateinit var window: KeyguardCardWindow
        var createdWindow: KeyguardCardWindow? = null
        lateinit var manager: TestPanelWindowManager
        var imageA: Bitmap? = null
        var imageC: Bitmap? = null
        var imageB: Bitmap? = null
        var imageReturnA: Bitmap? = null
        val controlledTime = ControlledOrbTimeSource(calibratedMaterialTime(PHASE_A))
        val submissions = SubmittedFrameTracker()
        submissions.expect(1L, PHASE_A)
        controlledTime.submit(1L, calibratedMaterialTime(PHASE_A))
        KeyguardOrbBufferRendererTestHooks.materialTimeSource = controlledTime
        KeyguardOrbBufferRendererTestHooks.publicationObserver = submissions
        try {
            instrumentation.runOnMainSync {
                window = KeyguardCardWindow(
                    serviceContext = activity,
                    onOpen = {}, onToggle = {}, onInteractionStarted = {},
                    onPositionCommitted = { _, _, _, _ -> },
                    onInteractionDiagnostic = { _, _ -> },
                    manager = TestPanelWindowManager(activity).also { manager = it },
                )
                createdWindow = window
                val settings = KeyguardCardSettings(
                    requested = true,
                    showFinancialDetails = true,
                    presentationMode = KeyguardCardPresentationMode.ORB,
                    animationMode = KeyguardCardAnimationMode.ORB_ONLY,
                    orbPosition = KeyguardCardOrbPosition(.5f, .5f),
                )
                window.prepareRetainedView(settings, calibratedOrbProfile())
                assertEquals(KeyguardCardWindow.Result.ATTACHED,
                    window.showOrUpdate(FluviFinancialCardPresenter.loading(), settings))
            }
            assertTrue("isolated ORB never completed a buffer", waitForIsolatedOutput(instrumentation, window))
            submissions.await(1L)
            // The ORB is in a separate TYPE_APPLICATION_PANEL, not in the
            // Activity Window. Capture the compositor's actual panel bounds;
            // PixelCopy(activity.window) cannot validate that child surface.
            imageA = awaitCompositorCrop(
                label = "isolated-orb-a",
                capture = { copyPanelOrb(instrumentation, manager) },
                persist = { evidenceLabel, bitmap -> persistPanelEvidence(activity, evidenceLabel, bitmap) },
                accepts = { hasVisibleMaterial(it) },
            )
            val publishedA = isolatedPublished(instrumentation, window)

            submissions.expect(2L, PHASE_C)
            controlledTime.submit(2L, calibratedMaterialTime(PHASE_C))
            submissions.await(2L)
            assertTrue("isolated ORB did not publish controlled C", waitForIsolatedOutput(instrumentation, window, publishedA))
            imageC = awaitCompositorCrop(
                label = "isolated-orb-c",
                capture = { copyPanelOrb(instrumentation, manager) },
                persist = { evidenceLabel, bitmap -> persistPanelEvidence(activity, evidenceLabel, bitmap) },
                accepts = { compareMaterialPixels(requireNotNull(imageA), it).nearlyEqual() },
            )
            val publishedC = isolatedPublished(instrumentation, window)

            submissions.expect(3L, PHASE_B)
            controlledTime.submit(3L, calibratedMaterialTime(PHASE_B))
            submissions.await(3L)
            assertTrue("isolated ORB did not publish controlled B", waitForIsolatedOutput(instrumentation, window, publishedC))
            imageB = awaitCompositorCrop(
                label = "isolated-orb-b",
                capture = { copyPanelOrb(instrumentation, manager) },
                persist = { evidenceLabel, bitmap -> persistPanelEvidence(activity, evidenceLabel, bitmap) },
                accepts = { compareMaterialPixels(requireNotNull(imageA), it).meaningful() },
            )
            val publishedB = isolatedPublished(instrumentation, window)

            submissions.expect(4L, PHASE_A)
            controlledTime.submit(4L, calibratedMaterialTime(PHASE_A))
            submissions.await(4L)
            assertTrue("isolated ORB did not return to controlled A", waitForIsolatedOutput(instrumentation, window, publishedB))
            imageReturnA = awaitCompositorCrop(
                label = "isolated-orb-return-a",
                capture = { copyPanelOrb(instrumentation, manager) },
                persist = { evidenceLabel, bitmap -> persistPanelEvidence(activity, evidenceLabel, bitmap) },
                accepts = { compareMaterialPixels(requireNotNull(imageA), it).nearlyEqual() },
            )

            // Persist every crop before asserting, so an oracle failure keeps
            // paired evidence. A/C deliberately samples the known plateau;
            // A/B is the positive control and the final A is reversibility.
            val plateau = compareMaterialPixels(requireNotNull(imageA), requireNotNull(imageC))
            val positive = compareMaterialPixels(requireNotNull(imageA), requireNotNull(imageB))
            val returned = compareMaterialPixels(requireNotNull(imageA), requireNotNull(imageReturnA))
            assertTrue("A/C must remain within compositor equality tolerance: $plateau", plateau.nearlyEqual())
            assertTrue("A/B must reach the calibrated meaningful-motion threshold: $positive", positive.meaningful())
            assertTrue("A-B-A must return within compositor equality tolerance: $returned", returned.nearlyEqual())
            instrumentation.runOnMainSync {
                val d = requireNotNull(window.materialDiagnostics())
                assertEquals("HardwareBufferRenderer/SurfaceControl", d.activeRenderer)
                assertTrue(d.isolatedFramesPublished > 1)
                assertEquals(0, d.frameCallbackCount)
                assertTrue("only one buffer render may be in flight", d.isolatedFramesInFlight <= 1)
                assertTrue("triple pool exceeded compositor ownership bound", d.isolatedFramesCompositorOwned <= 3)
            }
        } finally {
            KeyguardOrbBufferRendererTestHooks.materialTimeSource = SystemKeyguardOrbMaterialTimeSource
            KeyguardOrbBufferRendererTestHooks.publicationObserver = NoopKeyguardOrbBufferPublicationObserver
            imageA?.recycle()
            imageC?.recycle()
            imageB?.recycle()
            imageReturnA?.recycle()
            instrumentation.runOnMainSync {
                createdWindow?.dispose()
                activity.finish()
            }
        }
    }

    /**
     * Reproduces the attribution hole in the real window/worker path: an old
     * A frame can advance the aggregate publication counter after B is armed.
     * The new exact submission observer must leave B unsatisfied until its own
     * request-tagged frame passes the Main SurfaceControl submission boundary.
     */
    @Test fun isolatedOrbDoesNotAttributeDelayedOldPublicationToNewRequest() {
        assumeTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val activity = instrumentation.startActivitySync(
            Intent(instrumentation.targetContext, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        data class Gate(val entered: CountDownLatch = CountDownLatch(1), val release: CountDownLatch = CountDownLatch(1))
        val nextGate = AtomicReference<Gate?>(null)
        val barrier = KeyguardOrbRenderBarrier {
            nextGate.getAndSet(null)?.let { gate ->
                gate.entered.countDown()
                gate.release.await(8, TimeUnit.SECONDS)
            }
        }
        val controlledTime = ControlledOrbTimeSource(calibratedMaterialTime(PHASE_A))
        val submissions = SubmittedFrameTracker()
        submissions.expect(1L, PHASE_A)
        controlledTime.submit(1L, calibratedMaterialTime(PHASE_A))
        KeyguardOrbBufferRendererTestHooks.materialTimeSource = controlledTime
        KeyguardOrbBufferRendererTestHooks.publicationObserver = submissions
        lateinit var window: KeyguardCardWindow
        var createdWindow: KeyguardCardWindow? = null
        var oldGate: Gate? = null
        var newGate: Gate? = null
        try {
            instrumentation.runOnMainSync {
                window = KeyguardCardWindow(
                    serviceContext = activity,
                    onOpen = {}, onToggle = {}, onInteractionStarted = {},
                    onPositionCommitted = { _, _, _, _ -> },
                    onInteractionDiagnostic = { _, _ -> },
                    manager = TestPanelWindowManager(activity),
                    isolatedOrbRenderBarrier = barrier,
                )
                createdWindow = window
                val settings = KeyguardCardSettings(
                    requested = true,
                    showFinancialDetails = true,
                    presentationMode = KeyguardCardPresentationMode.ORB,
                    animationMode = KeyguardCardAnimationMode.ORB_ONLY,
                    orbPosition = KeyguardCardOrbPosition(.5f, .5f),
                )
                window.prepareRetainedView(settings, calibratedOrbProfile())
                assertEquals(KeyguardCardWindow.Result.ATTACHED,
                    window.showOrUpdate(FluviFinancialCardPresenter.loading(), settings))
            }
            assertTrue("initial controlled A was not submitted", waitForIsolatedOutput(instrumentation, window))
            submissions.await(1L)
            val initialPublished = isolatedPublished(instrumentation, window)

            oldGate = Gate()
            nextGate.set(oldGate)
            submissions.expect(2L, PHASE_A)
            controlledTime.submit(2L, calibratedMaterialTime(PHASE_A))
            assertTrue("old A never reached the renderer barrier", oldGate!!.entered.await(8, TimeUnit.SECONDS))

            submissions.expect(3L, PHASE_B)
            controlledTime.submit(3L, calibratedMaterialTime(PHASE_B))
            newGate = Gate()
            nextGate.set(newGate)
            oldGate!!.release.countDown()

            submissions.await(2L)
            assertTrue(
                "delayed old A did not advance the aggregate publication counter",
                waitForIsolatedOutput(instrumentation, window, initialPublished),
            )
            assertFalse("old A publication must not satisfy armed B", submissions.hasSubmitted(3L))
            assertTrue("armed B never reached its held renderer boundary", newGate!!.entered.await(8, TimeUnit.SECONDS))
            assertFalse("held B must remain unsubmitted", submissions.hasSubmitted(3L))

            val afterOldA = isolatedPublished(instrumentation, window)
            newGate!!.release.countDown()
            submissions.await(3L)
            assertTrue("exact B submission did not advance output", waitForIsolatedOutput(instrumentation, window, afterOldA))
        } finally {
            oldGate?.release?.countDown()
            newGate?.release?.countDown()
            KeyguardOrbBufferRendererTestHooks.materialTimeSource = SystemKeyguardOrbMaterialTimeSource
            KeyguardOrbBufferRendererTestHooks.publicationObserver = NoopKeyguardOrbBufferPublicationObserver
            instrumentation.runOnMainSync {
                createdWindow?.dispose()
                activity.finish()
            }
        }
    }

    private fun exerciseProductionWindow(mode: KeyguardCardPresentationMode, evidence: Boolean = true) {
        assumeTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val activity = instrumentation.startActivitySync(
            Intent(instrumentation.targetContext, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        lateinit var window: KeyguardCardWindow
        var createdWindow: KeyguardCardWindow? = null
        lateinit var manager: TestPanelWindowManager
        val live = CountDownLatch(1)
        val secondLive = CountDownLatch(1)
        val publications = KeyguardDrawPublication()
        var drawOwner: KeyguardFirstDrawOwner? = null
        val roots = mutableListOf<KeyguardFirstDrawEvent>()
        val shaders = mutableListOf<KeyguardFirstDrawEvent>()
        fun record(event: KeyguardFirstDrawEvent, stage: KeyguardDrawPublication.Stage) {
            val owner = drawOwner ?: return
            if (!owner.accepts(event, 1, 5, window.currentAttachGeneration)) return
            // The exact owner/reducer invoked by the service, not a test copy
            // of its former cycle-first publication condition.
            publications.record(owner.identity, stage, event.observedAtUptimeMs) {
                if (stage == KeyguardDrawPublication.Stage.ROOT) roots += event else {
                    shaders += event
                    if (shaders.size == 1) live.countDown() else secondLive.countDown()
                }
            }
        }
        fun ownAttachment() {
            drawOwner = KeyguardFirstDrawOwner(1, 5, window.currentAttachGeneration)
            publications.attach(requireNotNull(drawOwner).identity)
        }
        val committed = AtomicInteger()
        val promoted = AtomicInteger()
        val settings = KeyguardCardSettings(
            requested = true,
            showFinancialDetails = true,
            presentationMode = mode,
            animationMode = KeyguardCardAnimationMode.ORB_AND_BACKGROUND,
            cardPosition = KeyguardCardCardPosition(.5f),
            orbPosition = KeyguardCardOrbPosition(.5f, .5f),
        )
        try {
            instrumentation.runOnMainSync {
                manager = TestPanelWindowManager(activity)
                window = KeyguardCardWindow(
                    serviceContext = activity,
                    onOpen = {},
                    onToggle = {},
                    onInteractionStarted = {},
                    onPositionCommitted = { _, _, _, _ -> },
                    onInteractionDiagnostic = { _, _ -> },
                    onFirstRootDraw = { record(it, KeyguardDrawPublication.Stage.ROOT) },
                    onFirstShaderDraw = { record(it, KeyguardDrawPublication.Stage.SHADER) },
                    onBootstrapCommit = { committed.incrementAndGet() },
                    onLivePromotion = { promoted.incrementAndGet() },
                    manager = manager,
                    drawEvidenceEnabled = { evidence },
                )
                createdWindow = window
                // The production window creates its controller, prepares on
                // the real GPU lane, registers before attach and promotes
                // from Android's actual commit callback. This test never
                // invokes or replaces a functional commit/promotion callback.
                window.prepareRetainedView(settings, profile())
                assertEquals(KeyguardCardWindow.Result.ATTACHED,
                    window.showOrUpdate(FluviFinancialCardPresenter.loading(), settings))
                ownAttachment()
            }
            assertTrue("production window did not automatically reach live shader drawing",
                live.await(12, TimeUnit.SECONDS))
            instrumentation.waitForIdleSync()
            lateinit var retainedRoot: View
            instrumentation.runOnMainSync {
                retainedRoot = requireNotNull(manager.currentRoot)
                val d = requireNotNull(window.materialDiagnostics())
                assertTrue(d.hardwareAccelerated)
                assertEquals("LIVE", d.coldPresentationState)
                assertTrue(d.orb.bootstrapDrawCount > 0)
                assertTrue(d.orb.shaderDrawCount > 0)
                if (mode == KeyguardCardPresentationMode.CARD) assertTrue(d.background.shaderDrawCount > 0)
                assertEquals("expected a real bootstrap commit", 1, committed.get())
                assertEquals("expected one automatic live promotion", 1, promoted.get())
                assertEquals(1, manager.adds)
                assertEquals(0, manager.removes)
                assertEquals(manager.lastWidth, retainedRoot.width)
                assertEquals(manager.lastHeight, retainedRoot.height)
            }
            awaitWindowPhaseAdvance(instrumentation, retainedRoot)
            instrumentation.runOnMainSync {
                publications.detach()
                drawOwner = null
                assertTrue(window.hide())
                assertFalse(window.isAttached)
                val episode = requireNotNull(window.attachmentRenderSummary())
                assertTrue(episode.orb.frames > 2)
                assertTrue(episode.shaderCalls >= episode.orb.frames)
                assertTrue(episode.clockCallbacks > 0)
                assertTrue(episode.orb.gaps > 0)
                assertTrue(episode.orb.lastPhase != episode.orb.firstPhase)
                assertFalse(episode.clockRunning)
                val probe = episode.orbGaps
                if (evidence) {
                    assertEquals(1L, probe.attachment)
                    assertEquals(episode.orb.frames, probe.observedDraws)
                    assertTrue(probe.gaps.isNotEmpty())
                    assertTrue(probe.gaps.size <= 3)
                    assertTrue(probe.gaps.any { it.paired == 1L })
                    assertTrue(probe.gaps.all { it.previousEndNs <= it.currentStartNs &&
                        it.currentStartNs <= it.currentEndNs && it.width > 0 && it.height > 0 &&
                        it.program != null })
                    assertTrue(probe.gaps.filter { it.paired == 1L }.all {
                        it.frameNs <= it.callbackEntryNs && it.callbackEntryNs <= it.callbackExitNs &&
                            it.callbackExitNs <= it.currentStartNs
                    })
                    assertEquals(0L, probe.rejected)
                } else {
                    assertEquals(0L, probe.observedDraws)
                    assertEquals(0L, probe.observerNs)
                    assertTrue(probe.gaps.isEmpty())
                }
                // Numeric probe cost is not total instrumentation overhead;
                // timer reads and emulator scheduling remain separate. This
                // is a workload control, not a Nothing performance verdict.
                android.util.Log.i("FluviDrawProbe", "mode=$mode evidence=$evidence cold=true" +
                    " frames=${episode.orb.frames} phase=${episode.phaseAdvances}" +
                    " maxGapMs=${episode.orb.gapMaxMs} observerNs=${probe.observerNs}")
                assertEquals(1, manager.adds)
                assertEquals(1, manager.removes)
                assertEquals(KeyguardCardWindow.Result.ATTACHED,
                    window.showOrUpdate(FluviFinancialCardPresenter.loading(), settings))
                ownAttachment()
                assertTrue("reattach must reuse the retained root", retainedRoot === manager.currentRoot)
            }
            assertTrue("second actual shader draw was suppressed by the service publication owner",
                secondLive.await(8, TimeUnit.SECONDS))
            awaitWindowPhaseAdvance(instrumentation, retainedRoot)
            instrumentation.runOnMainSync {
                assertEquals(2, manager.adds)
                assertEquals(1, manager.removes)
                assertEquals("warm reattach must not repeat cold bootstrap", 1, committed.get())
                assertEquals(1, promoted.get())
                assertEquals(manager.lastWidth, retainedRoot.width)
                assertEquals(manager.lastHeight, retainedRoot.height)
                assertEquals(listOf(1L, 2L), roots.map { it.attachGeneration })
                assertEquals(listOf(1L, 2L), shaders.map { it.attachGeneration })
                assertEquals(roots.first().observedAtUptimeMs, publications.firstRootAt)
                assertEquals(shaders.first().observedAtUptimeMs, publications.firstShaderAt)
                publications.detach()
                drawOwner = null
                assertTrue(window.hide())
                val warm = requireNotNull(window.attachmentRenderSummary())
                if (evidence) {
                    assertEquals(2L, warm.orbGaps.attachment)
                    assertTrue(warm.orbGaps.gaps.all { it.previousEndNs > 0 })
                    assertEquals(0L, warm.orbGaps.rejected)
                }
                android.util.Log.i("FluviDrawProbe", "mode=$mode evidence=$evidence cold=false" +
                    " frames=${warm.orb.frames} phase=${warm.phaseAdvances}" +
                    " maxGapMs=${warm.orb.gapMaxMs} observerNs=${warm.orbGaps.observerNs}")
                // An add/remove entirely before traversal must remain without
                // draws; owning an attachment does not synthesize evidence.
                assertEquals(KeyguardCardWindow.Result.ATTACHED,
                    window.showOrUpdate(FluviFinancialCardPresenter.loading(), settings))
                ownAttachment()
                publications.detach()
                drawOwner = null
                assertTrue(window.hide())
            }
            instrumentation.waitForIdleSync()
            instrumentation.runOnMainSync {
                assertEquals(2, roots.size)
                assertEquals(2, shaders.size)
                assertEquals(3, manager.adds)
                assertEquals(3, manager.removes)
                assertEquals(0L, requireNotNull(window.attachmentRenderSummary()).orb.frames)
                assertEquals(null, requireNotNull(window.attachmentRenderSummary()).orb.firstAt)
                assertEquals(0L, requireNotNull(window.attachmentRenderSummary()).orbGaps.observedDraws)
                assertTrue(requireNotNull(window.attachmentRenderSummary()).orbGaps.gaps.isEmpty())
            }
        } finally {
            instrumentation.runOnMainSync {
                createdWindow?.dispose()
                activity.finish()
            }
        }
    }

    private fun awaitWindowPhaseAdvance(
        instrumentation: Instrumentation,
        root: View,
    ) {
        val advanced = CountDownLatch(1)
        lateinit var material: KeyguardHeaderMaterialView
        var phaseBefore = 0
        val listener = ViewTreeObserver.OnDrawListener {
            // Scalar production counter only. Full materialDiagnostics sorts
            // callback percentiles and must not perturb this pacing fixture.
            if (material.attachmentPhaseAdvances() > phaseBefore + 120) {
                advanced.countDown()
            }
        }
        instrumentation.runOnMainSync {
            material = root.findViewById(R.id.fluvi_financial_snapshot_orb)
            phaseBefore = material.attachmentPhaseAdvances()
            root.viewTreeObserver.addOnDrawListener(listener)
        }
        try {
            // This is a fixed-output correctness workload, not a minimum-FPS
            // assertion. The former 8s deadline belonged to a >2-frame test;
            // requiring >120 frames under it accidentally imposed a speed
            // target on the CI software-GPU emulator. Keep every output check
            // and a finite liveness deadline, without changing production.
            val completed = advanced.await(60, TimeUnit.SECONDS)
            var observed = 0
            instrumentation.runOnMainSync {
                observed = material.attachmentPhaseAdvances() - phaseBefore
            }
            android.util.Log.i("FluviDrawProbe", "phaseWorkload required=121 observed=$observed completed=$completed")
            assertTrue("live clock workload incomplete: required=121 observed=$observed", completed)
        } finally {
            instrumentation.runOnMainSync {
                if (root.viewTreeObserver.isAlive) root.viewTreeObserver.removeOnDrawListener(listener)
            }
        }
    }

    private fun waitForIsolatedOutput(
        instrumentation: Instrumentation,
        window: KeyguardCardWindow,
        minimumPublishedExclusive: Int = 0,
    ): Boolean {
        val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(12)
        while (System.nanoTime() < deadline) {
            var published = 0
            var active: String? = null
            instrumentation.runOnMainSync {
                val diagnostics = window.materialDiagnostics()
                published = diagnostics?.isolatedFramesPublished ?: 0
                active = diagnostics?.activeRenderer
            }
            if (active == "HardwareBufferRenderer/SurfaceControl" && published > minimumPublishedExclusive) return true
            Thread.sleep(24)
        }
        return false
    }

    /** Captures the request id from the same immutable test-time sample that
     * the renderer uses to record a frame. Production keeps its monotonic
     * source and returns no test id. */
    private class ControlledOrbTimeSource(initial: KeyguardMaterialTime) : KeyguardOrbMaterialTimeSource {
        private data class Sample(val requestId: Long?, val time: KeyguardMaterialTime)

        private val selected = AtomicReference(Sample(null, initial))
        private val sampled = ThreadLocal<Sample?>()

        fun submit(requestId: Long, time: KeyguardMaterialTime) {
            selected.set(Sample(requestId, time))
        }

        override fun timeAt(scene: KeyguardMaterialScene, frameTimeNanos: Long): KeyguardMaterialTime {
            val sample = selected.get()
            sampled.set(sample)
            return sample.time
        }

        override fun testRequestIdFor(materialTime: KeyguardMaterialTime): Long? =
            sampled.get()?.takeIf { it.time === materialTime }?.requestId
    }

    /** Waits for Main to submit the exact frame identity. It intentionally
     * does not reinterpret submission as physical presentation. */
    private class SubmittedFrameTracker : KeyguardOrbBufferPublicationObserver {
        private val expectedPhases = java.util.concurrent.ConcurrentHashMap<Long, Float>()
        private val latches = java.util.concurrent.ConcurrentHashMap<Long, CountDownLatch>()
        private val submitted = java.util.concurrent.ConcurrentHashMap<Long, KeyguardOrbBufferProducerFrame>()

        fun expect(requestId: Long, phase: Float) {
            check(expectedPhases.putIfAbsent(requestId, phase) == null) { "duplicate request=$requestId" }
            check(latches.putIfAbsent(requestId, CountDownLatch(1)) == null) { "duplicate latch=$requestId" }
        }

        override fun onSubmitted(frame: KeyguardOrbBufferProducerFrame) {
            val requestId = frame.testRequestId ?: return
            val expectedPhase = expectedPhases[requestId] ?: return
            if (kotlin.math.abs(expectedPhase - frame.materialTime.phase) > .0001f) return
            if (submitted.putIfAbsent(requestId, frame) == null) latches[requestId]?.countDown()
        }

        fun await(requestId: Long): KeyguardOrbBufferProducerFrame {
            val latch = requireNotNull(latches[requestId]) { "unarmed request=$requestId" }
            check(latch.await(8, TimeUnit.SECONDS)) { "requested frame was not submitted request=$requestId" }
            return requireNotNull(submitted[requestId]) { "submission signal without frame request=$requestId" }
        }

        fun hasSubmitted(requestId: Long): Boolean = submitted.containsKey(requestId)
    }

    /** Adapts only the privileged overlay token to the test Activity's panel
     * token. Real WindowManager, ViewRoot, hardware traversal, commit delivery
     * and removal all run with the production retained root. */
    private class TestPanelWindowManager(private val activity: KeyguardMaterialTestActivity) :
        WindowManager by activity.getSystemService(WindowManager::class.java) {
        private val delegate = activity.getSystemService(WindowManager::class.java)
        var adds = 0
        var removes = 0
        var lastWidth = 0
        var lastHeight = 0
        var currentRoot: View? = null

        private fun panelParameters(params: ViewGroup.LayoutParams) = WindowManager.LayoutParams().apply {
            copyFrom(params as WindowManager.LayoutParams)
            type = WindowManager.LayoutParams.TYPE_APPLICATION_PANEL
            token = activity.window.decorView.windowToken
            lastWidth = width
            lastHeight = height
        }

        override fun addView(view: View, params: ViewGroup.LayoutParams) {
            delegate.addView(view, panelParameters(params))
            adds += 1
            currentRoot = view
        }

        override fun updateViewLayout(view: View, params: ViewGroup.LayoutParams) =
            delegate.updateViewLayout(view, panelParameters(params))

        override fun removeViewImmediate(view: View) {
            delegate.removeViewImmediate(view)
            removes += 1
            currentRoot = null
        }

        /** This panel is a separate Window from the Activity. Its screen
         * bounds are therefore the only valid screenshot target for its child
         * SurfaceControl; Activity PixelCopy intentionally cannot be used. */
        fun currentOrbBounds(): Rect {
            val orb = requireNotNull(currentRoot)
                .findViewById<View>(R.id.fluvi_financial_snapshot_orb)
            val location = IntArray(2)
            orb.getLocationOnScreen(location)
            return Rect(location[0], location[1], location[0] + orb.width, location[1] + orb.height)
        }
    }

    @Test fun productionOffscreenPreparationAcquiresGpuOutput() {
        assumeTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val artifact = AndroidKeyguardShaderArtifactReader.load(context, "dualTide", false)
        val completed = CountDownLatch(1)
        var result: KeyguardGpuMaterialPreparationResult? = null
        val preparer = AndroidKeyguardGpuMaterialPreparer()
        try {
            preparer.prepare(
                KeyguardGpuMaterialPreparationRequest(
                    key = "instrumentation-offscreen",
                    artifact = artifact,
                    profile = profile(),
                    shape = KeyguardHeaderMaterialView.Shape.ORB,
                    width = 96,
                    height = 96,
                    cornerRadiusPx = 0f,
                ),
            ) {
                result = it
                completed.countDown()
            }
            assertTrue("offscreen renderer did not complete", completed.await(12, TimeUnit.SECONDS))
            assertEquals(KeyguardGpuMaterialPreparationStatus.READY, requireNotNull(result).status)
            assertTrue("offscreen renderer did not acquire ImageReader output", requireNotNull(result).outputAcquired)
        } finally {
            preparer.dispose()
        }
    }

    @Test fun delayedPreparationCannotPromoteAfterDetach() {
        assumeTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val activity = instrumentation.startActivitySync(
            Intent(instrumentation.targetContext, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        lateinit var view: KeyguardHeaderMaterialView
        val preparer = DeferredGpuPreparer()
        var controller: KeyguardCardMaterialController? = null
        try {
            instrumentation.runOnMainSync {
                view = KeyguardHeaderMaterialView(activity).apply {
                    layoutParams = FrameLayout.LayoutParams(160, 160)
                }
                controller = KeyguardCardMaterialController(
                    view,
                    KeyguardHeaderMaterialView(activity),
                    View(activity),
                    gpuPreparer = preparer,
                )
                controller!!.update(
                    profile = profile(),
                    animationMode = KeyguardCardAnimationMode.ORB_ONLY,
                    presentationMode = com.fluvi.app.lockscreen.KeyguardCardPresentationMode.ORB,
                    isFull = true,
                    staticOrb = null,
                )
                activity.setContentView(FrameLayout(activity).apply { addView(view) })
                controller!!.onAttached()
            }
            assertTrue("preparation was never requested", preparer.requested.await(8, TimeUnit.SECONDS))
            assertTrue("bootstrap must remain visible while preparation is pending", waitForBootstrap(instrumentation, view))
            instrumentation.runOnMainSync {
                controller!!.onBootstrapFrameCommitted(requireNotNull(controller!!.currentBootstrapToken()))
                controller!!.onDetached("test-unlock")
                preparer.complete()
            }
            instrumentation.waitForIdleSync()
            instrumentation.runOnMainSync {
                assertTrue("late preparation must not open the live gate", view.isBootstrapActive())
                assertEquals(0, view.diagnostics().shaderDrawCount)
            }
        } finally {
            instrumentation.runOnMainSync {
                controller?.dispose()
                activity.finish()
            }
        }
    }

    private fun copyMaterialView(instrumentation: Instrumentation, view: View): Bitmap {
        lateinit var bounds: Rect
        instrumentation.runOnMainSync {
            val location = IntArray(2)
            view.getLocationOnScreen(location)
            bounds = Rect(location[0], location[1], location[0] + view.width, location[1] + view.height)
        }
        val screen = requireNotNull(instrumentation.uiAutomation.takeScreenshot()) {
            "UiAutomation did not return a Hardware Canvas screenshot"
        }
        try {
            assertTrue("material view bounds outside screenshot: $bounds",
                bounds.intersect(0, 0, screen.width, screen.height))
            assertEquals(168, bounds.width())
            assertEquals(168, bounds.height())
            return Bitmap.createBitmap(screen, bounds.left, bounds.top, bounds.width(), bounds.height())
        } finally {
            screen.recycle()
        }
    }

    private fun copyPanelOrb(instrumentation: Instrumentation, manager: TestPanelWindowManager): Bitmap {
        lateinit var bounds: Rect
        instrumentation.runOnMainSync { bounds = manager.currentOrbBounds() }
        val screen = requireNotNull(instrumentation.uiAutomation.takeScreenshot()) {
            "UiAutomation did not return a compositor screenshot"
        }
        try {
            assertTrue("panel orb bounds outside screenshot: $bounds",
                bounds.intersect(0, 0, screen.width, screen.height))
            assertTrue("unexpected standalone orb bounds: $bounds", bounds.width() > 0 && bounds.height() > 0)
            return Bitmap.createBitmap(screen, bounds.left, bounds.top, bounds.width(), bounds.height())
        } finally {
            screen.recycle()
        }
    }

    /**
     * A SurfaceControl submission is not a screenshot latch. Keep the
     * requested test time fixed and observe compositor crops until their
     * phase-specific predicate is true. This is bounded test-only readback;
     * it is not a transaction callback or a claim about physical display
     * presentation.
     */
    private fun awaitCompositorCrop(
        label: String,
        capture: () -> Bitmap,
        persist: (String, Bitmap) -> Unit,
        accepts: (Bitmap) -> Boolean,
    ): Bitmap {
        val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(8)
        var last: Bitmap? = null
        while (System.nanoTime() < deadline) {
            val candidate = capture()
            if (accepts(candidate)) {
                last?.recycle()
                persist(label, candidate)
                return candidate
            }
            last?.recycle()
            last = candidate
            // Yield only for another composed screenshot; test time remains
            // fixed and no production frame/fence wait is introduced.
            Thread.sleep(32)
        }
        try {
            last?.let { persist("$label-observation-timeout", it) }
        } finally {
            last?.recycle()
        }
        throw AssertionError("$label compositor crop never met its request-bound predicate")
    }

    private data class MaterialPixelComparison(
        val changedPixels: Int,
        val totalDelta: Long,
        val maximumDelta: Int,
    ) {
        fun meaningful(): Boolean = changedPixels >= 64 && totalDelta >= 2_048L

        /** Screenshots have at most small compositor conversion noise. This
         * rejects a widespread phase change while allowing <=2/255 residuals. */
        fun nearlyEqual(): Boolean = maximumDelta <= 2 && totalDelta <= 2_048L
    }

    /** Uses the same interior and meaningful-motion threshold for A/C/B/A
     * compositor controls. It intentionally ignores transparent corners. */
    private fun compareMaterialPixels(first: Bitmap, second: Bitmap): MaterialPixelComparison {
        require(first.width == second.width && first.height == second.height)
        var substantive = 0
        var totalDelta = 0L
        var maximum = 0
        for (y in 0 until first.height) for (x in 0 until first.width) {
            val dx = x + .5f - first.width / 2f
            val dy = y + .5f - first.height / 2f
            if (dx * dx + dy * dy >= first.width * first.width * .1764f) continue
            val a = first.getPixel(x, y)
            val b = second.getPixel(x, y)
            val delta = maxOf(
                kotlin.math.abs((a ushr 16 and 0xff) - (b ushr 16 and 0xff)),
                kotlin.math.abs((a ushr 8 and 0xff) - (b ushr 8 and 0xff)),
                kotlin.math.abs((a and 0xff) - (b and 0xff)),
            )
            if (delta >= 7) substantive += 1
            totalDelta += delta
            maximum = maxOf(maximum, delta)
        }
        return MaterialPixelComparison(substantive, totalDelta, maximum)
    }

    private fun hasVisibleMaterial(bitmap: Bitmap): Boolean {
        var first: Int? = null
        for (y in 0 until bitmap.height) for (x in 0 until bitmap.width) {
            val dx = x + .5f - bitmap.width / 2f
            val dy = y + .5f - bitmap.height / 2f
            if (dx * dx + dy * dy >= bitmap.width * bitmap.width * .1764f) continue
            val color = bitmap.getPixel(x, y)
            if ((color ushr 24) == 0) continue
            if (first == null) first = color else if (first != color) return true
        }
        return false
    }

    private fun isolatedPublished(instrumentation: Instrumentation, window: KeyguardCardWindow): Int {
        var published = 0
        instrumentation.runOnMainSync { published = window.materialDiagnostics()?.isolatedFramesPublished ?: 0 }
        return published
    }

    private fun persistPanelEvidence(activity: KeyguardMaterialTestActivity, label: String, bitmap: Bitmap) {
        val directory = File(activity.filesDir, "keyguard-material-smoke").apply { mkdirs() }
        File(directory, "$label.png").outputStream().use {
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
        }
    }

    private fun waitForShaderDraw(
        instrumentation: Instrumentation,
        view: KeyguardHeaderMaterialView,
        previousCalls: Int,
    ): Boolean {
        val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(8)
        while (System.nanoTime() < deadline) {
            var drawn = false
            instrumentation.runOnMainSync {
                val diagnostics = view.diagnostics()
                drawn = diagnostics.lastCanvasHardwareAccelerated == true &&
                    diagnostics.shaderDrawCount > previousCalls
            }
            if (drawn) return true
            Thread.sleep(32)
        }
        return false
    }

    private fun waitForPreparedShader(
        instrumentation: Instrumentation,
        view: KeyguardHeaderMaterialView,
    ): Boolean {
        val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(8)
        while (System.nanoTime() < deadline) {
            var ready = false
            instrumentation.runOnMainSync {
                val diagnostics = view.diagnostics()
                ready = diagnostics.lastCanvasHardwareAccelerated == true &&
                    diagnostics.shaderCompileSuccesses > 0 &&
                    diagnostics.shaderDrawCount > 0
            }
            if (ready) return true
            Thread.sleep(32)
        }
        return false
    }

    private fun waitForDetachedPrepared(
        instrumentation: Instrumentation,
        view: KeyguardHeaderMaterialView,
    ): Boolean {
        val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(8)
        while (System.nanoTime() < deadline) {
            var prepared = false
            instrumentation.runOnMainSync {
                val diagnostics = view.diagnostics()
                prepared = !view.isAttachedToWindow && diagnostics.shaderCompileSuccesses > 0 &&
                    diagnostics.shaderDrawCount == 0
            }
            if (prepared) return true
            Thread.sleep(32)
        }
        return false
    }

    private fun waitForBootstrap(
        instrumentation: Instrumentation,
        view: KeyguardHeaderMaterialView,
    ): Boolean {
        val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(8)
        while (System.nanoTime() < deadline) {
            var ready = false
            instrumentation.runOnMainSync { ready = view.diagnostics().bootstrapDrawCount > 0 }
            if (ready) return true
            Thread.sleep(32)
        }
        return false
    }

    private class ImmediateGpuPreparer : KeyguardGpuMaterialPreparer {
        override fun prepare(
            request: KeyguardGpuMaterialPreparationRequest,
            onCompleted: (KeyguardGpuMaterialPreparationResult) -> Unit,
        ) = onCompleted(
            KeyguardGpuMaterialPreparationResult(
                request,
                KeyguardGpuMaterialPreparationStatus.READY,
                outputAcquired = true,
            ),
        )

        override fun dispose() = Unit
    }

    private class DeferredGpuPreparer : KeyguardGpuMaterialPreparer {
        val requested = CountDownLatch(1)
        private val pending = AtomicReference<Pair<KeyguardGpuMaterialPreparationRequest, (KeyguardGpuMaterialPreparationResult) -> Unit>?>()

        override fun prepare(
            request: KeyguardGpuMaterialPreparationRequest,
            onCompleted: (KeyguardGpuMaterialPreparationResult) -> Unit,
        ) {
            pending.set(request to onCompleted)
            requested.countDown()
        }

        fun complete() {
            val next = requireNotNull(pending.getAndSet(null))
            next.second(
                KeyguardGpuMaterialPreparationResult(
                    next.first,
                    KeyguardGpuMaterialPreparationStatus.READY,
                    outputAcquired = true,
                ),
            )
        }

        override fun dispose() = Unit
    }

    private fun profile() = requireNotNull(
        KeyguardMaterialProfile.fromMap(
            mapOf(
                "schemaVersion" to 1,
                "shaderAbiVersion" to 6,
                "sourceShaderHash" to KeyguardMaterialProfile.SOURCE_SHADER_HASH,
                "publisherSession" to "instrumentation",
                "publisherRevision" to 1L,
                "sceneIdentity" to "instrumentation|balance|month",
                "effectId" to "dualTide",
                "effectShaderId" to 1,
                "phase" to .25,
                "elapsedSeconds" to 1.0,
                "phaseSpeed" to .4,
                "colors" to listOf(0xff104f7c.toInt(), 0xff62c7dc.toInt(), 0xff8366dc.toInt()),
                "stops" to listOf(0.0, .5, 1.0),
                "opacity" to 1.0,
                "paletteSplitPercent" to 50.0,
                "commonSettings" to List(40) { .2 },
                "background" to portal(false),
                "interior" to portal(false),
                "referenceWidth" to 390.0,
                "referenceHeight" to 220.0,
            ),
        ),
    )

    /** Same synthetic Portal profile and dimensions as the service A/C/B/A
     * fixture. Only its test clock is controlled; shader math is untouched. */
    private fun calibratedOrbProfile() = requireNotNull(
        KeyguardMaterialProfile.fromMap(
            mapOf(
                "schemaVersion" to 1,
                "shaderAbiVersion" to 6,
                "sourceShaderHash" to KeyguardMaterialProfile.SOURCE_SHADER_HASH,
                "publisherSession" to "instrumentation-calibrated",
                "publisherRevision" to 1L,
                "sceneIdentity" to "fixture|balance|month",
                "effectId" to "dualTide",
                "effectShaderId" to 1,
                "phase" to .25,
                "elapsedSeconds" to 1.0,
                "phaseSpeed" to .4,
                "colors" to listOf(0xff104f7c.toInt(), 0xff62c7dc.toInt(), 0xff8366dc.toInt()),
                "stops" to listOf(0.0, .5, 1.0),
                "opacity" to 1.0,
                "paletteSplitPercent" to 50.0,
                "commonSettings" to List(40) { .2 },
                "background" to calibratedPortal(true),
                "interior" to calibratedPortal(false),
                "referenceWidth" to 390.0,
                "referenceHeight" to 220.0,
            ),
        ),
    )

    private fun calibratedPortal(enabled: Boolean) = mapOf(
        "enabled" to enabled,
        "effectIndex" to 0,
        "phase" to 0.0,
        "phaseSpeed" to .2,
        "paletteCenterPercent" to 50.0,
        "paletteWindowPercent" to 68.0,
        "rotationEnabled" to false,
        "rotationSpeed" to 0.0,
        "settings" to List(12) { .2 },
    )

    private fun calibratedMaterialTime(phase: Float) = KeyguardMaterialTime(
        elapsedSeconds = phase,
        phase = phase,
        backgroundPhase = phase,
        interiorPhase = phase,
    )

    private fun portal(enabled: Boolean) = mapOf(
        "enabled" to enabled,
        "effectIndex" to 0,
        "phase" to 0.0,
        "phaseSpeed" to 0.0,
        "paletteCenterPercent" to 50.0,
        "paletteWindowPercent" to 68.0,
        "rotationEnabled" to false,
        "rotationSpeed" to 0.0,
        "settings" to List(12) { 0.0 },
    )

    private data class CardState(
        val name: String,
        val eventVisible: Boolean,
        val toggleVisible: Boolean,
        val focus: String,
        val primary: String,
        val secondary: String,
    )

    private fun inflatedCard(context: android.content.Context): View {
        // Supplying the real parent type makes Android parse the root's
        // layout_height into FrameLayout.LayoutParams. Inflating against null
        // would discard that production XML contract before measurement.
        val parent = FrameLayout(context)
        return LayoutInflater.from(context).inflate(R.layout.fluvi_keyguard_card, parent, false)
    }

    private fun populate(card: View, state: CardState) {
        card.findViewById<android.widget.TextView>(R.id.fluvi_financial_snapshot_focus).text = state.focus
        card.findViewById<android.widget.TextView>(R.id.fluvi_financial_snapshot_primary).text = state.primary
        card.findViewById<android.widget.TextView>(R.id.fluvi_financial_snapshot_secondary).text = state.secondary
        card.findViewById<android.widget.TextView>(R.id.fluvi_financial_snapshot_event).apply {
            text = "Utolsó tétel: rendkívül hosszú tranzakciós kategória és megjegyzés"
            visibility = if (state.eventVisible) View.VISIBLE else View.GONE
        }
        card.findViewById<android.widget.TextView>(R.id.fluvi_financial_snapshot_toggle).apply {
            text = "Utolsó tétel"
            visibility = if (state.toggleVisible) View.VISIBLE else View.GONE
        }
    }

    private fun measureInWindowParent(card: View, width: Int, height: Int) {
        (card.parent as? ViewGroup)?.removeView(card)
        val parent = FrameLayout(card.context).apply {
            addView(
                card,
                FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT,
                ),
            )
        }
        parent.measure(
            View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.EXACTLY),
        )
        parent.layout(0, 0, width, height)
    }

    private fun measureFromXmlDefinition(card: View, width: Int, height: Int) {
        (card.parent as? ViewGroup)?.removeView(card)
        val parent = FrameLayout(card.context).apply { addView(card) }
        parent.measure(
            View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(height * 3, View.MeasureSpec.AT_MOST),
        )
        parent.layout(0, 0, width, parent.measuredHeight)
    }

    private fun assertCardExtent(card: View, expectedHeight: Int, label: String) {
        assertEquals("$label root height", expectedHeight, card.measuredHeight)
        assertEquals(
            "$label material background height",
            expectedHeight,
            card.findViewById<View>(R.id.fluvi_keyguard_material_background).measuredHeight,
        )
        assertEquals(
            "$label veil height",
            expectedHeight,
            card.findViewById<View>(R.id.fluvi_keyguard_material_veil).measuredHeight,
        )
    }

    private fun assertNoReservedAreaOverlap(card: View, label: String) {
        val orb = card.findViewById<View>(R.id.fluvi_financial_snapshot_orb)
        val toggle = card.findViewById<View>(R.id.fluvi_financial_snapshot_toggle)
        listOf(
            R.id.fluvi_financial_snapshot_focus,
            R.id.fluvi_financial_snapshot_primary,
            R.id.fluvi_financial_snapshot_secondary,
        ).map { card.findViewById<View>(it) }
            .filter { it.visibility == View.VISIBLE }
            .forEach { text ->
                assertTrue("$label text reached orb", text.right <= orb.left)
            }
        val event = card.findViewById<View>(R.id.fluvi_financial_snapshot_event)
        if (event.visibility == View.VISIBLE && toggle.visibility == View.VISIBLE) {
            assertTrue("$label event reached toggle", event.right <= toggle.left)
        }
        if (event.visibility == View.VISIBLE) {
            val secondary = card.findViewById<View>(R.id.fluvi_financial_snapshot_secondary)
            assertTrue("$label event overlaps secondary", event.top >= secondary.bottom)
        }
        assertTrue("$label orb and toggle overlap", orb.bottom <= toggle.top || toggle.bottom <= orb.top)
    }

    private companion object {
        const val PHASE_A = 1.196795f
        const val PHASE_C = 1.5234617f
        const val PHASE_B = 3.75f
    }
}
