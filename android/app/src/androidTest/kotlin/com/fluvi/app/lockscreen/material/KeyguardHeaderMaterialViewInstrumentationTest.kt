package com.fluvi.app.lockscreen.material

import android.app.Instrumentation
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.ColorSpace
import android.graphics.PixelFormat
import android.graphics.Rect
import android.hardware.HardwareBuffer
import android.hardware.SyncFence
import android.os.Build
import android.os.SystemClock
import android.view.Gravity
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
import java.time.Duration
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
    @Test fun retainedPreparationWarmsActualIsolatedBackendBeforeFirstShow() {
        assumeTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val activity = instrumentation.startActivitySync(
            Intent(instrumentation.targetContext, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        lateinit var window: KeyguardCardWindow
        var createdWindow: KeyguardCardWindow? = null
        val preparationEvents = mutableListOf<Pair<String, Map<String, Any?>>>()
        try {
            instrumentation.runOnMainSync {
                window = KeyguardCardWindow(
                    serviceContext = activity,
                    onOpen = {}, onToggle = {}, onInteractionStarted = {},
                    onPositionCommitted = { _, _, _, _ -> },
                    onInteractionDiagnostic = { _, _ -> },
                    onWindowDiagnostic = { stage, _, _, _, fields ->
                        preparationEvents += stage to fields
                    },
                    manager = TestPanelWindowManager(activity),
                )
                createdWindow = window
                val settings = KeyguardCardSettings(
                    requested = true,
                    showFinancialDetails = true,
                    presentationMode = KeyguardCardPresentationMode.ORB,
                    animationMode = KeyguardCardAnimationMode.ORB_ONLY,
                    orbPosition = KeyguardCardOrbPosition(.5f, .5f),
                )
                // This is the exact retained-root service preparation path;
                // no WindowManager attach or presentation authorization exists
                // while the bounded isolated producer warms its own slots.
                window.prepareRetainedView(settings, calibratedOrbProfile())
                assertFalse(window.isAttached)
            }
            assertTrue(
                "service preparation did not warm the actual isolated ORB backend",
                waitForDetachedIsolatedBackend(instrumentation, window),
            )
            var producedBeforeShow = 0
            instrumentation.runOnMainSync {
                val diagnostics = requireNotNull(window.materialDiagnostics())
                assertEquals("HardwareBufferRenderer/SurfaceControl", diagnostics.activeRenderer)
                assertTrue(diagnostics.isolatedFramesProduced >= 1)
                assertEquals(
                    "the detached isolated backend must replace, not duplicate, the disposable GPU warmup",
                    0,
                    diagnostics.gpuPreparationRequests,
                )
                assertEquals(
                    "detached preparation must not publish or expose a layer",
                    0,
                    diagnostics.isolatedFramesPublished,
                )
                assertFalse(window.isAttached)
                producedBeforeShow = diagnostics.isolatedFramesProduced
                val prepared = preparationEvents.lastOrNull { it.first == "MATERIAL_ISOLATED_BACKEND_PREPARED" }
                assertTrue("actual detached backend completion was not reported", prepared != null)
                assertEquals(0L, prepared?.second?.get("leaseAttachment"))
                assertTrue((prepared?.second?.get("leaseGeneration") as? Long ?: 0L) > 0L)
            }
            instrumentation.runOnMainSync {
                val settings = KeyguardCardSettings(
                    requested = true,
                    showFinancialDetails = true,
                    presentationMode = KeyguardCardPresentationMode.ORB,
                    animationMode = KeyguardCardAnimationMode.ORB_ONLY,
                    orbPosition = KeyguardCardOrbPosition(.5f, .5f),
                )
                assertEquals(
                    KeyguardCardWindow.Result.ATTACHED,
                    window.showOrUpdate(FluviFinancialCardPresenter.loading(), settings),
                )
            }
            assertTrue(
                "first authorized attachment did not publish its own current buffer",
                waitForIsolatedOutput(instrumentation, window),
            )
            instrumentation.runOnMainSync {
                val diagnostics = requireNotNull(window.materialDiagnostics())
                assertTrue(diagnostics.isolatedFramesProduced > producedBeforeShow)
                assertTrue(diagnostics.isolatedFramesPublished >= 1)
            }
        } finally {
            instrumentation.runOnMainSync {
                createdWindow?.dispose()
                activity.finish()
            }
        }
    }

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
                    // Do not let the screenshot crop overlap the status bar:
                    // that would turn SystemUI clock pixels into a Canvas
                    // material oracle. The view itself remains 168x168.
                    layoutParams = FrameLayout.LayoutParams(168, 168, Gravity.CENTER)
                    setScene(KeyguardMaterialScene(profile, full = true, appliedAtNanos = 0L), enabled = true)
                    setBootstrapActive(false)
                    assertEquals(KeyguardHeaderMaterialView.ProgramPreparationResult.COMPILED, installPreparedShader(artifact))
                }
                root.addView(view)
                activity.setContentView(root)
                view.frame(1L)
            }
            assertTrue("production View never reached a hardware Canvas", waitForPreparedShader(instrumentation, view))
            // A manual frame() can produce a hardware draw before Android has
            // laid out this Activity on the display. The compositor control
            // must not crop the display origin in that interval: that is the
            // status-bar/background, not the production material View.
            assertTrue(
                "production material View never acquired its on-screen bounds",
                waitForMaterialViewScreenBounds(instrumentation, view),
            )
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
                    onTimeout = {
                        persistMaterialCompositorTimeout(
                            activity = activity,
                            instrumentation = instrumentation,
                            label = label,
                            view = view,
                            phase = phase,
                        )
                    },
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
        data class WindowEvent(
            val stage: String,
            val attach: Long?,
            val observedAtUptimeMs: Long,
            val fields: Map<String, Any?>,
        )
        val windowEvents = mutableListOf<WindowEvent>()
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
                    onWindowDiagnostic = { stage, _, attach, observedAt, fields ->
                        windowEvents += WindowEvent(stage, attach, observedAt, fields)
                    },
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
                val attachedBeforeWithdrawal = window.currentAttachGeneration
                assertTrue("withdrawal waited for renderer", window.hide())
                assertFalse(window.isAttached)
                val layerSubmission = windowEvents.singleOrNull {
                    it.stage == "ISOLATED_LAYER_HIDE_SUBMITTED"
                }
                assertTrue("current isolated layer did not submit a hide transaction", layerSubmission != null)
                assertEquals(attachedBeforeWithdrawal, layerSubmission?.attach)
                assertEquals(true, layerSubmission?.fields?.get("transactionApplied"))
                assertTrue(
                    "layer submission must have an exact nonzero lease generation",
                    (layerSubmission?.fields?.get("leaseGeneration") as? Long ?: 0L) > 0L,
                )
                val localHideIndex = windowEvents.indexOfFirst { it.stage == "LOCAL_HIDE_APPLIED" }
                val layerHideIndex = windowEvents.indexOfFirst { it.stage == "ISOLATED_LAYER_HIDE_SUBMITTED" }
                val removeBeginIndex = windowEvents.indexOfFirst { it.stage == "REMOVE_VIEW_BEGIN" }
                assertTrue("root invisibility must precede child-layer withdrawal", localHideIndex in 0 until layerHideIndex)
                assertTrue("child-layer withdrawal must precede window removal", layerHideIndex in 0 until removeBeginIndex)
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
            instrumentation.runOnMainSync {
                assertEquals(
                    "old blocked completion must not withdraw the fresh attachment",
                    1,
                    windowEvents.count { it.stage == "ISOLATED_LAYER_HIDE_SUBMITTED" },
                )
            }
        } finally {
            releaseBlockedFrame.countDown()
            instrumentation.runOnMainSync {
                createdWindow?.dispose()
                activity.finish()
            }
        }
    }

    /** Holds the already accepted steady publication, not the earlier GPU
     * request. Main withdraws A and grants B before that exact A use resumes. */
    @Test fun isolatedOrbRevocationDrainsLateSteadyPublication() {
        withOrbRetirementFixture("revocation") { fixture ->
            repeat(3) { cycle ->
                val before = fixture.capture(PHASE_A, "cycle-$cycle-old-a") { hasVisibleMaterial(it) }
                try {
                    val gate = fixture.holdSteady(before.frame.lease)
                    val held = gate.awaitEntered()
                    val accepted = fixture.ownership.awaitUse("steady-accepted", held)
                    var replacementAttachment = 0L
                    fixture.instrumentation.runOnMainSync {
                        assertTrue(fixture.window.hide())
                        assertFalse(fixture.window.isAttached)
                        fixture.assertHiddenExactlyOnce(held.lease)
                        assertEquals(KeyguardCardWindow.Result.ATTACHED,
                            fixture.window.showOrUpdate(FluviFinancialCardPresenter.loading(), fixture.settings))
                        replacementAttachment = fixture.window.currentAttachGeneration
                        assertTrue(fixture.window.isAttached)
                    }
                    gate.assertStillHeld("Main hide and reattach")
                    assertTrue("replacement must own a new attachment", replacementAttachment != held.lease.attachment)
                    gate.release.countDown()
                    fixture.assertRetiredUseDrained(held, accepted)
                    val replacementLease = fixture.awaitAttachment(replacementAttachment)

                    val replacementA = fixture.capture(PHASE_A, "cycle-$cycle-new-a") {
                        compareMaterialPixels(before.bitmap, it).nearlyEqual()
                    }
                    try {
                        assertEquals(replacementAttachment, replacementA.frame.lease.attachment)
                        assertEquals(replacementLease, replacementA.frame.lease)
                        assertTrue("replacement output reused old lease", replacementA.frame.lease != held.lease)
                        fixture.assertMotion(replacementA, "cycle-$cycle-new", replacementA.frame.lease)
                        fixture.instrumentation.runOnMainSync {
                            assertTrue("old retirement withdrew B", fixture.window.isAttached)
                            assertEquals(replacementAttachment, fixture.window.currentAttachGeneration)
                            assertFalse("old retirement hid B", fixture.hides.any {
                                it.attachment == replacementAttachment
                            })
                        }
                    } finally {
                        replacementA.bitmap.recycle()
                    }
                    fixture.ownership.assertBoundedSingleRenderer()
                } finally {
                    before.bitmap.recycle()
                }
            }
        }
    }

    @Test fun isolatedOrbSameLeaseLayoutRetainsAcceptedSteadyGrant() {
        withOrbRetirementFixture("same-lease-layout") { fixture ->
            val before = fixture.capture(PHASE_A, "layout-before-a") { hasVisibleMaterial(it) }
            try {
                val gate = fixture.holdSteady(before.frame.lease)
                val held = gate.awaitEntered()
                val accepted = fixture.ownership.awaitUse("steady-accepted", held)
                fixture.instrumentation.runOnMainSync {
                    val orb = requireNotNull(fixture.manager.currentRoot)
                        .findViewById<View>(R.id.fluvi_financial_snapshot_orb)
                    val left = orb.left
                    val top = orb.top
                    val right = orb.right
                    val bottom = orb.bottom
                    repeat(3) {
                        // Real layout callbacks, unchanged dimensions/lease.
                        orb.layout(left + 1, top, right + 1, bottom)
                        orb.layout(left, top, right, bottom)
                    }
                    assertTrue(fixture.hides.isEmpty())
                }
                gate.assertStillHeld("same-child layout")
                gate.release.countDown()
                val submitted = fixture.ownership.awaitUse("steady-submitted", held)
                assertTrue("accepted grant identity missing", accepted.grantIdentity != null)
                assertEquals(accepted.grantIdentity, submitted.grantIdentity)
                assertEquals("same-child layout replaced the active grant",
                    accepted.grantIdentity, submitted.currentGrantIdentity)
                assertEquals(accepted.childIdentity, submitted.currentGrantChildIdentity)
                assertEquals(held.lease, submitted.currentGrantLease)
                assertTrue(submitted.currentGrantActive)
                fixture.assertMotion(before, "layout-after", held.lease)
                fixture.instrumentation.runOnMainSync {
                    assertTrue(fixture.window.isAttached)
                    assertTrue("same lease was withdrawn during layout", fixture.hides.isEmpty())
                }
                fixture.ownership.assertBoundedSingleRenderer()
            } finally {
                before.bitmap.recycle()
            }
        }
    }

    @Test fun isolatedOrbDisposeDrainsAcceptedSteadyPublicationWithoutWaitingOnMain() {
        withOrbRetirementFixture("dispose") { fixture ->
            val gate = fixture.holdSteady(fixture.initialLease)
            val held = gate.awaitEntered()
            val accepted = fixture.ownership.awaitUse("steady-accepted", held)
            fixture.instrumentation.runOnMainSync {
                fixture.window.dispose()
                assertFalse(fixture.window.isAttached)
                assertEquals(null, fixture.manager.currentRoot)
                fixture.assertHiddenExactlyOnce(held.lease)
            }
            gate.assertStillHeld("Main dispose")
            gate.release.countDown()
            fixture.assertRetiredUseDrained(held, accepted)
            fixture.instrumentation.waitForIdleSync()
            fixture.instrumentation.runOnMainSync {
                assertFalse("dispose reopened the window", fixture.window.isAttached)
                assertEquals(null, fixture.manager.currentRoot)
                assertEquals(1, fixture.manager.adds)
                assertEquals(1, fixture.manager.removes)
                fixture.assertHiddenExactlyOnce(held.lease)
            }
            val drained = fixture.ownership.awaitLease("lease-drained", held.lease)
            assertEquals("disposed child regained publication authority", null, drained.currentGrantLease)
            fixture.ownership.assertBoundedSingleRenderer()
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
        val producerSamples = CalibratedProducerSamples()
        // First publication replaces a palette-compatible View bootstrap.
        // It is a real A submission but cannot be the screenshot reference:
        // the submission observer runs before Main suppresses that View.
        // Prime the layer, observe that handoff, then submit a second exact A
        // for the A/C/B/A compositor reference sequence below.
        submissions.expect(1L, PHASE_A)
        controlledTime.submit(1L, calibratedMaterialTime(PHASE_A))
        KeyguardOrbBufferRendererTestHooks.materialTimeSource = controlledTime
        KeyguardOrbBufferRendererTestHooks.frameObserver = producerSamples
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
            assertTrue(
                "isolated panel ORB never acquired its on-screen bounds",
                waitForPanelOrbScreenBounds(instrumentation, manager),
            )
            assertTrue("isolated ORB never completed a buffer", waitForIsolatedOutput(instrumentation, window))
            submissions.await(1L)
            assertTrue(
                "first isolated buffer did not replace the View bootstrap before reference sampling",
                waitForIsolatedBootstrapReplacement(instrumentation, manager),
            )
            val publishedPrimer = isolatedPublished(instrumentation, window)

            submissions.expect(2L, PHASE_A)
            producerSamples.expect(2L)
            controlledTime.submit(2L, calibratedMaterialTime(PHASE_A))
            submissions.await(2L)
            val producerA = producerSamples.await(2L)
            persistProducerEvidence(activity, "isolated-producer-a", producerA)
            assertTrue(
                "isolated ORB did not publish reference A after bootstrap replacement",
                waitForIsolatedOutput(instrumentation, window, publishedPrimer),
            )
            // The ORB is in a separate TYPE_APPLICATION_PANEL, not in the
            // Activity Window. Capture the compositor's actual panel bounds;
            // PixelCopy(activity.window) cannot validate that child surface.
            imageA = awaitCompositorCrop(
                label = "isolated-orb-a",
                capture = { copyPanelOrb(instrumentation, manager) },
                persist = { evidenceLabel, bitmap -> persistPanelEvidence(activity, evidenceLabel, bitmap) },
                accepts = { hasVisibleMaterial(it) },
                onTimeout = {
                    persistPanelCompositorTimeout(
                        activity = activity,
                        instrumentation = instrumentation,
                        label = "isolated-orb-a",
                        manager = manager,
                        frame = producerA.frame,
                    )
                },
            )
            val publishedA = isolatedPublished(instrumentation, window)

            submissions.expect(3L, PHASE_C)
            producerSamples.expect(3L)
            controlledTime.submit(3L, calibratedMaterialTime(PHASE_C))
            submissions.await(3L)
            val producerC = producerSamples.await(3L)
            persistProducerEvidence(activity, "isolated-producer-c", producerC)
            assertTrue("isolated ORB did not publish controlled C", waitForIsolatedOutput(instrumentation, window, publishedA))
            imageC = awaitCompositorCrop(
                label = "isolated-orb-c",
                capture = { copyPanelOrb(instrumentation, manager) },
                persist = { evidenceLabel, bitmap -> persistPanelEvidence(activity, evidenceLabel, bitmap) },
                accepts = { compareMaterialPixels(requireNotNull(imageA), it).nearlyEqual() },
                onTimeout = {
                    persistPanelCompositorTimeout(
                        activity = activity,
                        instrumentation = instrumentation,
                        label = "isolated-orb-c",
                        manager = manager,
                        frame = producerC.frame,
                    )
                },
            )
            val publishedC = isolatedPublished(instrumentation, window)

            submissions.expect(4L, PHASE_B)
            producerSamples.expect(4L)
            controlledTime.submit(4L, calibratedMaterialTime(PHASE_B))
            submissions.await(4L)
            val producerB = producerSamples.await(4L)
            persistProducerEvidence(activity, "isolated-producer-b", producerB)
            assertTrue("isolated ORB did not publish controlled B", waitForIsolatedOutput(instrumentation, window, publishedC))
            imageB = awaitCompositorCrop(
                label = "isolated-orb-b",
                capture = { copyPanelOrb(instrumentation, manager) },
                persist = { evidenceLabel, bitmap -> persistPanelEvidence(activity, evidenceLabel, bitmap) },
                accepts = { compareMaterialPixels(requireNotNull(imageA), it).meaningful() },
                onTimeout = {
                    persistPanelCompositorTimeout(
                        activity = activity,
                        instrumentation = instrumentation,
                        label = "isolated-orb-b",
                        manager = manager,
                        frame = producerB.frame,
                    )
                },
            )
            val publishedB = isolatedPublished(instrumentation, window)

            submissions.expect(5L, PHASE_A)
            producerSamples.expect(5L)
            controlledTime.submit(5L, calibratedMaterialTime(PHASE_A))
            submissions.await(5L)
            val producerReturnA = producerSamples.await(5L)
            persistProducerEvidence(activity, "isolated-producer-return-a", producerReturnA)
            assertTrue("isolated ORB did not return to controlled A", waitForIsolatedOutput(instrumentation, window, publishedB))
            imageReturnA = awaitCompositorCrop(
                label = "isolated-orb-return-a",
                capture = { copyPanelOrb(instrumentation, manager) },
                persist = { evidenceLabel, bitmap -> persistPanelEvidence(activity, evidenceLabel, bitmap) },
                accepts = { compareMaterialPixels(requireNotNull(imageA), it).nearlyEqual() },
                onTimeout = {
                    persistPanelCompositorTimeout(
                        activity = activity,
                        instrumentation = instrumentation,
                        label = "isolated-orb-return-a",
                        manager = manager,
                        frame = producerReturnA.frame,
                    )
                },
            )

            // Persist every crop before asserting, so an oracle failure keeps
            // paired evidence. A/C deliberately samples the known plateau;
            // A/B is the positive control and the final A is reversibility.
            val plateau = compareMaterialPixels(requireNotNull(imageA), requireNotNull(imageC))
            val positive = compareMaterialPixels(requireNotNull(imageA), requireNotNull(imageB))
            val returned = compareMaterialPixels(requireNotNull(imageA), requireNotNull(imageReturnA))
            val producerPlateau = compareProducerPixels(producerA, producerC)
            val producerPositive = compareProducerPixels(producerA, producerB)
            val producerReturned = compareProducerPixels(producerA, producerReturnA)
            assertEquals("all controlled producer samples must retain one current lease", producerA.frame.lease, producerC.frame.lease)
            assertEquals("all controlled producer samples must retain one current lease", producerA.frame.lease, producerB.frame.lease)
            assertEquals("all controlled producer samples must retain one current lease", producerA.frame.lease, producerReturnA.frame.lease)
            assertTrue("producer A/C must remain within equality tolerance: $producerPlateau", producerPlateau.nearlyEqual())
            assertTrue("producer A/B must reach the calibrated meaningful-motion threshold: $producerPositive", producerPositive.meaningful())
            assertTrue("producer A-B-A must return within equality tolerance: $producerReturned", producerReturned.nearlyEqual())
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
            KeyguardOrbBufferRendererTestHooks.frameObserver = NoopKeyguardOrbBufferFrameObserver
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

    private data class OrbRetirementHide(
        val attachment: Long?,
        val generation: Long?,
        val uptimeMs: Long,
        val applied: Boolean,
    )

    private data class OrbRetirementCapture(
        val frame: KeyguardOrbBufferProducerFrame,
        val bitmap: Bitmap,
    )

    private class OrbSteadyGate(val requestId: Long, val lease: KeyguardOrbBufferLease) {
        val entered = CountDownLatch(1)
        val release = CountDownLatch(1)
        val returned = CountDownLatch(1)
        val frame = AtomicReference<KeyguardOrbBufferProducerFrame?>()
        val timedOut = java.util.concurrent.atomic.AtomicBoolean(false)

        fun hold(value: KeyguardOrbBufferProducerFrame) {
            frame.set(value)
            entered.countDown()
            if (!release.await(8, TimeUnit.SECONDS)) timedOut.set(true)
            returned.countDown()
        }

        fun awaitEntered(): KeyguardOrbBufferProducerFrame {
            assertTrue("steady publication never reached armed gate request=$requestId",
                entered.await(8, TimeUnit.SECONDS))
            return requireNotNull(frame.get()).also {
                assertEquals(lease, it.lease)
                assertEquals(requestId, it.testRequestId)
            }
        }

        fun assertStillHeld(operation: String) {
            assertFalse("$operation exhausted the worker latch budget", timedOut.get())
            assertEquals("$operation waited for the accepted worker submission", 1L, returned.count)
            assertEquals("test released the worker before $operation returned", 1L, release.count)
        }
    }

    /** Test-owned immutable history. Overflow is a failure, never missing
     * evidence interpreted as a successful drain or absence of ownership. */
    private class OrbOwnershipHistory : KeyguardOrbOwnershipObserver {
        private val records = mutableListOf<KeyguardOrbOwnershipEvent>()
        private var overflow = false

        @Synchronized override fun onEvent(event: KeyguardOrbOwnershipEvent) {
            if (records.size < 16_384) records += event else overflow = true
        }

        @Synchronized fun snapshot(): List<KeyguardOrbOwnershipEvent> = records.toList()

        fun awaitUse(event: String, frame: KeyguardOrbBufferProducerFrame): KeyguardOrbOwnershipEvent =
            await("$event lease=${frame.lease.attachment}/${frame.lease.generation} slot=${frame.slotId}/${frame.useGeneration}") {
                it.event == event && it.lease == frame.lease &&
                    it.slotId == frame.slotId && it.useGeneration == frame.useGeneration
            }

        fun awaitLease(event: String, lease: KeyguardOrbBufferLease): KeyguardOrbOwnershipEvent =
            await("$event lease=${lease.attachment}/${lease.generation}") {
                it.event == event && it.lease == lease
            }

        private fun await(label: String, accepts: (KeyguardOrbOwnershipEvent) -> Boolean): KeyguardOrbOwnershipEvent {
            val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(8)
            while (System.nanoTime() < deadline) {
                snapshot().firstOrNull(accepts)?.let { return it }
                Thread.sleep(24)
            }
            throw AssertionError("ownership event missing: $label; last=${snapshot().takeLast(6)}")
        }

        @Synchronized fun assertBoundedSingleRenderer() {
            assertFalse("ownership observation history overflowed", overflow)
            assertTrue("ownership observer did not receive events", records.isNotEmpty())
            assertEquals("reattach replaced the renderer instead of draining its fixed pool",
                1, records.map { it.rendererId }.toSet().size)
            assertTrue("global slot pool exceeded three including retired uses", records.all { it.slots.size <= 3 })
            assertTrue("duplicate stable slots in one worker snapshot", records.all {
                it.slots.map { slot -> slot.slotId }.toSet().size == it.slots.size
            })
        }
    }

    private fun withOrbRetirementFixture(label: String, exercise: (OrbRetirementFixture) -> Unit) {
        assumeTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
        val fixture = OrbRetirementFixture(label)
        try {
            fixture.start()
            exercise(fixture)
        } finally {
            fixture.releaseGates()
            fixture.resetHooks()
            try {
                fixture.persistOwnershipEvidence()
            } finally {
                fixture.instrumentation.runOnMainSync {
                    fixture.createdWindow?.dispose()
                    fixture.activity.finish()
                }
            }
        }
    }

    /** Reuses the existing real-window and calibrated pixel oracles. This
     * fixture never supplies a release callback, fence or visibility grant. */
    private inner class OrbRetirementFixture(private val label: String) {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val activity = instrumentation.startActivitySync(
            Intent(instrumentation.targetContext, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        lateinit var window: KeyguardCardWindow
        var createdWindow: KeyguardCardWindow? = null
        lateinit var manager: TestPanelWindowManager
        lateinit var initialLease: KeyguardOrbBufferLease
        val ownership = OrbOwnershipHistory()
        val hides = mutableListOf<OrbRetirementHide>()
        val settings = KeyguardCardSettings(
            requested = true,
            showFinancialDetails = true,
            presentationMode = KeyguardCardPresentationMode.ORB,
            animationMode = KeyguardCardAnimationMode.ORB_ONLY,
            orbPosition = KeyguardCardOrbPosition(.5f, .5f),
        )
        private val controlledTime = ControlledOrbTimeSource(calibratedMaterialTime(PHASE_A))
        private val submissions = SubmittedFrameTracker()
        private val samples = CalibratedProducerSamples()
        private val nextGate = AtomicReference<OrbSteadyGate?>()
        private val gates = mutableListOf<OrbSteadyGate>()
        private var nextRequest = 0L

        fun start() {
            KeyguardOrbBufferRendererTestHooks.materialTimeSource = controlledTime
            KeyguardOrbBufferRendererTestHooks.publicationObserver = submissions
            KeyguardOrbBufferRendererTestHooks.frameObserver = samples
            KeyguardOrbBufferRendererTestHooks.ownershipObserver = ownership
            KeyguardOrbBufferRendererTestHooks.steadyPublicationBarrier = KeyguardOrbSteadyPublicationBarrier { frame ->
                val gate = nextGate.get()
                if (gate != null && frame.testRequestId == gate.requestId &&
                    nextGate.compareAndSet(gate, null)
                ) gate.hold(frame)
            }
            val primer = request(PHASE_A)
            instrumentation.runOnMainSync {
                window = KeyguardCardWindow(
                    serviceContext = activity,
                    onOpen = {}, onToggle = {}, onInteractionStarted = {},
                    onPositionCommitted = { _, _, _, _ -> },
                    onInteractionDiagnostic = { _, _ -> },
                    onWindowDiagnostic = { stage, _, attachment, observedAt, fields ->
                        if (stage == "ISOLATED_LAYER_HIDE_SUBMITTED") {
                            hides += OrbRetirementHide(attachment, fields["leaseGeneration"] as? Long,
                                observedAt, fields["transactionApplied"] == true)
                        }
                    },
                    manager = TestPanelWindowManager(activity).also { manager = it },
                )
                createdWindow = window
                window.prepareRetainedView(settings, calibratedOrbProfile())
                assertEquals(KeyguardCardWindow.Result.ATTACHED,
                    window.showOrUpdate(FluviFinancialCardPresenter.loading(), settings))
            }
            initialLease = submissions.await(primer).lease
            assertTrue("initial isolated output missing", waitForIsolatedOutput(instrumentation, window))
            assertTrue("initial panel bounds missing", waitForPanelOrbScreenBounds(instrumentation, manager))
            assertTrue("initial View bootstrap was not replaced",
                waitForIsolatedBootstrapReplacement(instrumentation, manager))
            // The established renderer must retain its captured dependencies;
            // subsequent global-hook changes cannot redirect that renderer.
            resetHooks()
        }

        private fun request(phase: Float): Long {
            val requestId = ++nextRequest
            submissions.expect(requestId, phase)
            controlledTime.submit(requestId, calibratedMaterialTime(phase))
            return requestId
        }

        fun awaitAttachment(attachment: Long): KeyguardOrbBufferLease {
            val frame = submissions.await(request(PHASE_A))
            assertEquals("new request was submitted by an old attachment", attachment, frame.lease.attachment)
            assertTrue("replacement panel bounds missing", waitForPanelOrbScreenBounds(instrumentation, manager))
            assertTrue("replacement View bootstrap was not replaced",
                waitForIsolatedBootstrapReplacement(instrumentation, manager))
            return frame.lease
        }

        fun holdSteady(lease: KeyguardOrbBufferLease): OrbSteadyGate {
            val requestId = ++nextRequest
            val gate = OrbSteadyGate(requestId, lease)
            gates += gate
            check(nextGate.compareAndSet(null, gate)) { "another steady gate is armed" }
            submissions.expect(requestId, PHASE_A)
            controlledTime.submit(requestId, calibratedMaterialTime(PHASE_A))
            return gate
        }

        fun capture(phase: Float, suffix: String, accepts: (Bitmap) -> Boolean): OrbRetirementCapture {
            val requestId = ++nextRequest
            submissions.expect(requestId, phase)
            samples.expect(requestId)
            controlledTime.submit(requestId, calibratedMaterialTime(phase))
            val submitted = submissions.await(requestId)
            val produced = samples.await(requestId)
            assertEquals("producer evidence must identify the submitted frame", produced.frame, submitted)
            persistProducerEvidence(activity, "r06-$label-$suffix-producer", produced)
            val bitmap = awaitCompositorCrop(
                label = "r06-$label-$suffix",
                capture = { copyPanelOrb(instrumentation, manager) },
                persist = { evidenceLabel, image -> persistPanelEvidence(activity, evidenceLabel, image) },
                accepts = accepts,
                onTimeout = {
                    persistPanelCompositorTimeout(activity, instrumentation, "r06-$label-$suffix", manager, submitted)
                },
            )
            return OrbRetirementCapture(submitted, bitmap)
        }

        fun assertMotion(reference: OrbRetirementCapture, suffix: String, lease: KeyguardOrbBufferLease) {
            val moved = capture(PHASE_B, "$suffix-b") { compareMaterialPixels(reference.bitmap, it).meaningful() }
            try {
                assertEquals("motion must belong to the replacement lease", lease, moved.frame.lease)
                val returned = capture(PHASE_A, "$suffix-return-a") {
                    compareMaterialPixels(reference.bitmap, it).nearlyEqual()
                }
                try {
                    assertEquals(lease, returned.frame.lease)
                    assertTrue(compareMaterialPixels(reference.bitmap, moved.bitmap).meaningful())
                    assertTrue(compareMaterialPixels(reference.bitmap, returned.bitmap).nearlyEqual())
                } finally {
                    returned.bitmap.recycle()
                }
            } finally {
                moved.bitmap.recycle()
            }
        }

        fun assertHiddenExactlyOnce(lease: KeyguardOrbBufferLease) {
            val matching = hides.filter { it.attachment == lease.attachment && it.generation == lease.generation }
            assertEquals("exact Main-owned child was not hidden once", 1, matching.size)
            assertTrue("Main hide transaction failed", matching.single().applied)
        }

        fun assertRetiredUseDrained(frame: KeyguardOrbBufferProducerFrame, accepted: KeyguardOrbOwnershipEvent) {
            val submitted = ownership.awaitUse("steady-submitted", frame)
            val clearStarted = ownership.awaitLease("retirement-clear-started", frame.lease)
            val cleared = ownership.awaitLease("retirement-clear-applied", frame.lease)
            val receipt = ownership.awaitUse("release-received", frame)
            val completed = ownership.awaitUse("release-fence-complete", frame)
            val drained = ownership.awaitLease("lease-drained", frame.lease)
            val records = ownership.snapshot()
            assertTrue("accepted use was not submitted late", records.indexOf(accepted) < records.indexOf(submitted))
            assertTrue("final clear did not follow the accepted submission",
                records.indexOf(submitted) < records.indexOf(clearStarted))
            assertTrue("held use's real release did not follow the ordered clear",
                records.indexOf(clearStarted) < records.indexOf(receipt))
            assertTrue("release fence completed without the matching receipt",
                records.indexOf(receipt) <= records.indexOf(completed))
            assertTrue("lease drained before its exact held use completed",
                records.indexOf(completed) < records.indexOf(drained))
            assertTrue("accepted child identity missing", accepted.childIdentity != null)
            assertEquals("retirement cleared a different child", accepted.childIdentity, cleared.childIdentity)
            val releasedSlot = completed.slots.single { it.slotId == frame.slotId && it.useGeneration == frame.useGeneration }
            assertEquals(frame.lease, releasedSlot.lease)
            assertTrue("fence completion lacked a real compositor receipt", releasedSlot.callbackReceived)
            assertFalse("drained use still has a pending release fence", releasedSlot.fencePending)
            assertTrue("lease drain left an owned old use", drained.slots.none {
                it.lease == frame.lease && it.state != "FREE"
            })
            instrumentation.runOnMainSync {
                assertHiddenExactlyOnce(frame.lease)
                val hide = hides.single { it.attachment == frame.lease.attachment && it.generation == frame.lease.generation }
                assertTrue("Main did not hide inside the held-publication interval",
                    accepted.uptimeMs <= hide.uptimeMs && hide.uptimeMs <= submitted.uptimeMs)
            }
            gates.forEach { assertFalse("worker latch timed out instead of test release", it.timedOut.get()) }
        }

        fun releaseGates() {
            nextGate.set(null)
            gates.forEach { it.release.countDown() }
        }

        fun resetHooks() {
            KeyguardOrbBufferRendererTestHooks.materialTimeSource = SystemKeyguardOrbMaterialTimeSource
            KeyguardOrbBufferRendererTestHooks.publicationObserver = NoopKeyguardOrbBufferPublicationObserver
            KeyguardOrbBufferRendererTestHooks.frameObserver = NoopKeyguardOrbBufferFrameObserver
            KeyguardOrbBufferRendererTestHooks.steadyPublicationBarrier = NoopKeyguardOrbSteadyPublicationBarrier
            KeyguardOrbBufferRendererTestHooks.ownershipObserver = NoopKeyguardOrbOwnershipObserver
        }

        fun persistOwnershipEvidence() {
            val directory = File(activity.filesDir, "keyguard-material-smoke").apply { mkdirs() }
            val details = StringBuilder()
            instrumentation.runOnMainSync { hides.forEach { details.appendLine("mainHide=$it") } }
            gates.forEach { details.appendLine("gate request=${it.requestId} frame=${it.frame.get()} timedOut=${it.timedOut.get()}") }
            ownership.snapshot().forEach { details.appendLine(it) }
            File(directory, "r06-$label-ownership.txt").writeText(details.toString())
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

    private fun waitForDetachedIsolatedBackend(
        instrumentation: Instrumentation,
        window: KeyguardCardWindow,
    ): Boolean {
        val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(12)
        while (System.nanoTime() < deadline) {
            var ready = false
            instrumentation.runOnMainSync {
                val diagnostics = window.materialDiagnostics()
                ready = !window.isAttached &&
                    diagnostics?.activeRenderer == "HardwareBufferRenderer/SurfaceControl" &&
                    (diagnostics.isolatedFramesProduced >= 1) &&
                    diagnostics.isolatedFramesPublished == 0 &&
                    // Detached preparation initializes the actual renderer,
                    // but it must drain its unauthorised READY_FOR_MAIN use
                    // rather than occupying a fixed-pool handoff slot until
                    // some future attachment happens to arrive.
                    diagnostics.isolatedFramesReady == 0 &&
                    diagnostics.isolatedFramesInFlight == 0 &&
                    diagnostics.isolatedFramesCompositorOwned == 0
            }
            if (ready) return true
            Thread.sleep(24)
        }
        return false
    }

    /** The first exact isolated submission is ordered before Main suppresses
     * the retained View placeholder. A screenshot collected in that gap is a
     * valid bootstrap image but not evidence for the buffer/compositor route. */
    private fun waitForIsolatedBootstrapReplacement(
        instrumentation: Instrumentation,
        manager: TestPanelWindowManager,
    ): Boolean {
        val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(8)
        while (System.nanoTime() < deadline) {
            var replaced = false
            instrumentation.runOnMainSync { replaced = manager.isOrbBootstrapSuppressed() }
            if (replaced) return true
            Thread.sleep(24)
        }
        return false
    }

    /** A producer completion can precede WindowManager layout. Keep the
     * screenshot crop tied to the actual displayed View/panel geometry rather
     * than accepting the display origin while its location is still 0,0. */
    private fun waitForMaterialViewScreenBounds(
        instrumentation: Instrumentation,
        view: View,
    ): Boolean {
        val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(8)
        while (System.nanoTime() < deadline) {
            var laidOut = false
            instrumentation.runOnMainSync {
                val location = IntArray(2)
                view.getLocationOnScreen(location)
                laidOut = view.isAttachedToWindow && view.isShown &&
                    view.width == 168 && view.height == 168 &&
                    location[0] > 0 && location[1] > 0
            }
            if (laidOut) return true
            Thread.sleep(24)
        }
        return false
    }

    private fun waitForPanelOrbScreenBounds(
        instrumentation: Instrumentation,
        manager: TestPanelWindowManager,
    ): Boolean {
        val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(8)
        while (System.nanoTime() < deadline) {
            var laidOut = false
            instrumentation.runOnMainSync { laidOut = manager.hasOrbScreenBounds() }
            if (laidOut) return true
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

    /**
     * Copies only the four request-tagged producer frames used by the
     * calibrated A/C/B/A control. The renderer owns the buffer and fence;
     * this observer waits for completion but never closes either resource.
     */
    private class CalibratedProducerSamples : KeyguardOrbBufferFrameObserver {
        data class Sample(
            val frame: KeyguardOrbBufferProducerFrame,
            val pixels: IntArray,
        )

        private val latches = java.util.concurrent.ConcurrentHashMap<Long, CountDownLatch>()
        private val samples = java.util.concurrent.ConcurrentHashMap<Long, Sample>()
        private val failures = java.util.concurrent.ConcurrentHashMap<Long, Throwable>()

        fun expect(requestId: Long) {
            check(latches.putIfAbsent(requestId, CountDownLatch(1)) == null) {
                "duplicate producer request=$requestId"
            }
        }

        override fun onProduced(
            frame: KeyguardOrbBufferProducerFrame,
            buffer: HardwareBuffer,
            completionFence: SyncFence?,
        ) {
            val requestId = frame.testRequestId ?: return
            val latch = latches[requestId] ?: return
            if (samples.containsKey(requestId) || failures.containsKey(requestId)) return
            try {
                check(completionFence?.await(Duration.ofSeconds(2)) != false) {
                    "producer completion fence did not signal request=$requestId"
                }
                val hardware = checkNotNull(Bitmap.wrapHardwareBuffer(
                    buffer,
                    ColorSpace.get(ColorSpace.Named.SRGB),
                )) { "HardwareBuffer readback returned null request=$requestId" }
                val software = try {
                    checkNotNull(hardware.copy(Bitmap.Config.ARGB_8888, false)) {
                        "HardwareBuffer software copy returned null request=$requestId"
                    }
                } finally {
                    hardware.recycle()
                }
                try {
                    val pixels = IntArray(software.width * software.height)
                    software.getPixels(pixels, 0, software.width, 0, 0, software.width, software.height)
                    samples.putIfAbsent(requestId, Sample(frame, pixels))
                } finally {
                    software.recycle()
                }
            } catch (error: Throwable) {
                failures.putIfAbsent(requestId, error)
            } finally {
                latch.countDown()
            }
        }

        fun await(requestId: Long): Sample {
            val latch = requireNotNull(latches[requestId]) { "unarmed producer request=$requestId" }
            check(latch.await(8, TimeUnit.SECONDS)) {
                "producer did not complete request=$requestId"
            }
            failures.remove(requestId)?.let { throw AssertionError("producer readback failed request=$requestId", it) }
            return requireNotNull(samples[requestId]) {
                "producer completion missing sample request=$requestId"
            }
        }
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

        fun isOrbBootstrapSuppressed(): Boolean = requireNotNull(currentRoot)
            .findViewById<View>(R.id.fluvi_financial_snapshot_orb)
            .visibility == View.INVISIBLE

        fun hasOrbScreenBounds(): Boolean {
            val root = currentRoot ?: return false
            val orb = root.findViewById<View>(R.id.fluvi_financial_snapshot_orb)
            val location = IntArray(2)
            orb.getLocationOnScreen(location)
            return root.isAttachedToWindow && orb.width == 168 && orb.height == 168 &&
                location[0] > 0 && location[1] > 0
        }

        fun compositorGeometry(activity: KeyguardMaterialTestActivity): String {
            val root = requireNotNull(currentRoot) { "panel root missing" }
            val orb = root.findViewById<View>(R.id.fluvi_financial_snapshot_orb)
            val orbScreen = IntArray(2)
            val orbWindow = IntArray(2)
            val rootScreen = IntArray(2)
            orb.getLocationOnScreen(orbScreen)
            orb.getLocationInWindow(orbWindow)
            root.getLocationOnScreen(rootScreen)
            val metrics = activity.resources.displayMetrics
            return listOf(
                "activityWindowFocus=${activity.hasWindowFocus()}",
                "panel=adds:$adds,removes:$removes,lastSize:${lastWidth}x${lastHeight}",
                "orb=attached:${orb.isAttachedToWindow},shown:${orb.isShown},visibility:${orb.visibility},windowVisibility:${orb.windowVisibility},size:${orb.width}x${orb.height},screen:${orbScreen[0]},${orbScreen[1]},window:${orbWindow[0]},${orbWindow[1]}",
                "root=attached:${root.isAttachedToWindow},shown:${root.isShown},visibility:${root.visibility},windowVisibility:${root.windowVisibility},size:${root.width}x${root.height},screen:${rootScreen[0]},${rootScreen[1]}",
                "display=metrics:${metrics.widthPixels}x${metrics.heightPixels},density:${metrics.density},rotation:${orb.display?.rotation}",
            ).joinToString("\n")
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
        onTimeout: () -> Unit,
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
            onTimeout()
        } finally {
            last?.recycle()
        }
        throw AssertionError("$label compositor crop never met its request-bound predicate")
    }

    /**
     * A crop predicate failure is not evidence that the renderer is frozen.
     * Preserve the exact target geometry, ViewRoot state and one full-display
     * screenshot before throwing, so a later investigation can distinguish a
     * bad crop from a missing composed layer without adding work to a passing
     * or performance run.
     */
    private fun persistMaterialCompositorTimeout(
        activity: KeyguardMaterialTestActivity,
        instrumentation: Instrumentation,
        label: String,
        view: View,
        phase: Float,
    ) {
        persistCompositorTimeout(
            activity = activity,
            instrumentation = instrumentation,
            label = label,
            target = "hardware-canvas",
            identity = "phase=$phase",
            geometry = { materialCompositorGeometry(activity, view) },
        )
    }

    private fun persistPanelCompositorTimeout(
        activity: KeyguardMaterialTestActivity,
        instrumentation: Instrumentation,
        label: String,
        manager: TestPanelWindowManager,
        frame: KeyguardOrbBufferProducerFrame,
    ) {
        persistCompositorTimeout(
            activity = activity,
            instrumentation = instrumentation,
            label = label,
            target = "isolated-panel",
            identity = "lease=${frame.lease.attachment}/${frame.lease.generation} " +
                "slot=${frame.slotId} use=${frame.useGeneration} " +
                "requestId=${frame.testRequestId} phase=${frame.materialTime.phase}",
            geometry = { manager.compositorGeometry(activity) },
        )
    }

    private fun persistCompositorTimeout(
        activity: KeyguardMaterialTestActivity,
        instrumentation: Instrumentation,
        label: String,
        target: String,
        identity: String,
        geometry: () -> String,
    ) {
        val directory = File(activity.filesDir, "keyguard-material-smoke").apply { mkdirs() }
        val details = StringBuilder().apply {
            appendLine("target=$target")
            appendLine(identity)
            appendLine("elapsedRealtimeMs=${SystemClock.elapsedRealtime()}")
        }
        runCatching {
            var measured = "UNOBSERVED:mainGeometryDidNotRun"
            instrumentation.runOnMainSync { measured = geometry() }
            details.appendLine(measured)
        }.onFailure { details.appendLine("geometry=UNOBSERVED:${it.javaClass.simpleName}:${it.message}") }
        val screen = instrumentation.uiAutomation.takeScreenshot()
        if (screen == null) {
            details.appendLine("screenshot=UNOBSERVED:UiAutomationReturnedNull")
        } else {
            try {
                details.appendLine("screenshot=${screen.width}x${screen.height} config=${screen.config}")
                File(directory, "$label-observation-timeout-screen.png").outputStream().use {
                    screen.compress(Bitmap.CompressFormat.PNG, 100, it)
                }
            } finally {
                screen.recycle()
            }
        }
        File(directory, "$label-observation-timeout.txt").writeText(details.toString())
    }

    private fun materialCompositorGeometry(activity: KeyguardMaterialTestActivity, view: View): String {
        val viewScreen = IntArray(2)
        val viewWindow = IntArray(2)
        val rootScreen = IntArray(2)
        view.getLocationOnScreen(viewScreen)
        view.getLocationInWindow(viewWindow)
        val root = view.rootView
        root.getLocationOnScreen(rootScreen)
        val metrics = activity.resources.displayMetrics
        return listOf(
            "activityWindowFocus=${activity.hasWindowFocus()}",
            "view=attached:${view.isAttachedToWindow},shown:${view.isShown},visibility:${view.visibility},windowVisibility:${view.windowVisibility},size:${view.width}x${view.height},screen:${viewScreen[0]},${viewScreen[1]},window:${viewWindow[0]},${viewWindow[1]}",
            "root=attached:${root.isAttachedToWindow},shown:${root.isShown},visibility:${root.visibility},windowVisibility:${root.windowVisibility},size:${root.width}x${root.height},screen:${rootScreen[0]},${rootScreen[1]}",
            "display=metrics:${metrics.widthPixels}x${metrics.heightPixels},density:${metrics.density},rotation:${view.display?.rotation}",
        ).joinToString("\n")
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

    private fun compareProducerPixels(
        first: CalibratedProducerSamples.Sample,
        second: CalibratedProducerSamples.Sample,
    ): MaterialPixelComparison {
        require(first.pixels.size == second.pixels.size)
        var substantive = 0
        var totalDelta = 0L
        var maximum = 0
        first.pixels.indices.forEach { index ->
            val a = first.pixels[index]
            val b = second.pixels[index]
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

    private fun persistProducerEvidence(
        activity: KeyguardMaterialTestActivity,
        label: String,
        sample: CalibratedProducerSamples.Sample,
    ) {
        val directory = File(activity.filesDir, "keyguard-material-smoke").apply { mkdirs() }
        val bitmap = Bitmap.createBitmap(
            sample.pixels,
            sample.frame.lease.width,
            sample.frame.lease.height,
            Bitmap.Config.ARGB_8888,
        )
        try {
            File(directory, "$label.png").outputStream().use {
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
            }
            File(directory, "$label.txt").writeText(
                "lease=${sample.frame.lease.attachment}/${sample.frame.lease.generation} " +
                    "slot=${sample.frame.slotId} use=${sample.frame.useGeneration} " +
                    "requestId=${sample.frame.testRequestId} phase=${sample.frame.materialTime.phase}\n",
            )
        } finally {
            bitmap.recycle()
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
