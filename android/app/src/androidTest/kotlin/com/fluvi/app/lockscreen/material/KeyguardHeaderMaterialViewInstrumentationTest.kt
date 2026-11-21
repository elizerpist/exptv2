package com.fluvi.app.lockscreen.material

import android.app.Instrumentation
import android.content.Intent
import android.content.Context
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
import com.fluvi.app.lockscreen.KeyguardCardInteractionLayout
import com.fluvi.app.lockscreen.KeyguardCardContentOverflow
import com.fluvi.app.lockscreen.KeyguardFrameCommitObservation
import com.fluvi.app.lockscreen.KeyguardCardWindow
import com.fluvi.app.lockscreen.KeyguardR15AcquisitionTestHooks
import com.fluvi.app.lockscreen.KeyguardFirstAcquisition
import com.fluvi.app.lockscreen.KeyguardInspectionAuthority
import com.fluvi.app.lockscreen.KeyguardInspectionFreshness
import com.fluvi.app.lockscreen.KeyguardCardInspectionRequest
import com.fluvi.app.lockscreen.KeyguardWindowFreshness
import com.fluvi.app.lockscreen.KeyguardDrawPublication
import com.fluvi.app.lockscreen.KeyguardFirstDrawOwner
import com.fluvi.app.lockscreen.KeyguardFirstDrawEvent
import com.fluvi.app.lockscreen.KeyguardCardSettings
import com.fluvi.app.lockscreen.KeyguardCardDiagnostics
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
import org.junit.After
import org.junit.Before
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
    private var priorRoute: String? = null
    private var priorRoutePresent = false

    @Before fun selectLegacyForExistingPanelControls() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val prefs = context.getSharedPreferences("fluvi_keyguard_orb_diagnostic_route", Context.MODE_PRIVATE)
        priorRoutePresent = prefs.contains("mode")
        priorRoute = prefs.getString("mode", null)
        check(prefs.edit().putString("mode", "LEGACY_R11").commit())
    }

    @After fun restoreDiagnosticRoute() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val prefs = context.getSharedPreferences("fluvi_keyguard_orb_diagnostic_route", Context.MODE_PRIVATE)
        val edit = prefs.edit()
        if (priorRoutePresent) edit.putString("mode", priorRoute) else edit.remove("mode")
        check(edit.commit())
    }

    /** Deterministic detached-route RED before any motion eligibility guard.
     * The callback proves the production observer consumed the real setting. */
    @Test fun r15DetachedMotionOffRevokesPreparedLiveEligibility() {
        assumeTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        val resolver = context.contentResolver
        val automation = instrumentation.uiAutomation
        val saved = android.provider.Settings.Global.getString(resolver,
            android.provider.Settings.Global.ANIMATOR_DURATION_SCALE)
        fun setScale(value: String?) {
            automation.adoptShellPermissionIdentity(android.Manifest.permission.WRITE_SECURE_SETTINGS)
            try {
                check(android.provider.Settings.Global.putString(resolver,
                    android.provider.Settings.Global.ANIMATOR_DURATION_SCALE, value))
            } finally { automation.dropShellPermissionIdentity() }
        }
        val args = InstrumentationRegistry.getArguments()
        val runId = java.util.UUID.fromString(requireNotNull(args.getString("runUuid"))).toString()
        val evidence = File(context.filesDir, "keyguard-service-probe/r15/$runId/motion-red.txt")
        check(evidence.parentFile?.mkdirs() == true || evidence.parentFile?.isDirectory == true)
        val latch = CountDownLatch(1)
        val observedAt = java.util.concurrent.atomic.AtomicLong(-1)
        val invalidations = AtomicInteger()
        val queueLock = Any()
        val firstGate = KeyguardFirstAcquisition()
        val restoredGate = KeyguardFirstAcquisition()
        val authority = KeyguardInspectionAuthority(1, 2, 3, 4, 5)
        fun request(owner: KeyguardInspectionAuthority, id: Long) = KeyguardCardInspectionRequest(
            id = id, trigger = "wake", session = owner.serviceSession, visibilityEpoch = owner.visibilityEpoch,
            interactionEpoch = owner.interactionEpoch, attachGeneration = owner.attachGeneration,
            wakeGeneration = owner.wakeGeneration, queuedAtUptimeMs = 100)
        fun ticket(owner: KeyguardInspectionAuthority) =
            KeyguardInspectionFreshness.Ticket(owner, 1, KeyguardWindowFreshness.LIFECYCLE_BOUNDARY)
        var window: KeyguardCardWindow? = null
        var activity: KeyguardMaterialTestActivity? = null
        try {
            setScale("1")
            check(context.getSharedPreferences("fluvi_keyguard_orb_diagnostic_route", Context.MODE_PRIVATE)
                .edit().putString("mode", "SURFACE_LIVE").commit())
            activity = instrumentation.startActivitySync(Intent(context, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) as KeyguardMaterialTestActivity
            val targetActivity = activity
            val settings = KeyguardCardSettings(requested = true, showFinancialDetails = true,
                presentationMode = KeyguardCardPresentationMode.ORB, animationMode = KeyguardCardAnimationMode.ORB_ONLY)
            val profile = calibratedOrbProfile()
            var eligibleBefore = false
            instrumentation.runOnMainSync {
                val target = KeyguardCardWindow(targetActivity, onOpen = {}, onToggle = {}, onInteractionStarted = {},
                    onPositionCommitted = { _, _, _, _ -> }, onInteractionDiagnostic = { _, _ -> },
                    onSurfaceMotionIneligible = {
                        synchronized(queueLock) { firstGate.invalidate(); restoredGate.invalidate() }
                        invalidations.incrementAndGet()
                    })
                window = target
                target.prepareRetainedView(settings, profile)
                check(target.renderModeStatus().effective.name == "SURFACE_LIVE")
                eligibleBefore = target.preparedInitialLiveOrb(settings, profile)
                synchronized(queueLock) { firstGate.begin(authority, eligibleBefore); restoredGate.begin(authority, eligibleBefore) }
            }
            check(eligibleBefore) { "fixture did not reach detached prepared LIVE eligibility" }
            KeyguardR15AcquisitionTestHooks.motionObserver = { allowed ->
                if (!allowed) { observedAt.set(SystemClock.uptimeMillis()); latch.countDown() }
            }
            val changedAt = SystemClock.uptimeMillis()
            setScale("0")
            check(latch.await(8, TimeUnit.SECONDS)) { "production motion observer was not reached" }
            var eligibleAfter = true
            instrumentation.runOnMainSync { eligibleAfter = checkNotNull(window).preparedInitialLiveOrb(settings, profile) }
            val consumedWhileOff = synchronized(queueLock) { firstGate.take(request(authority, 1), ticket(authority)) }
            val enabled = CountDownLatch(1)
            KeyguardR15AcquisitionTestHooks.motionObserver = { allowed -> if (allowed) enabled.countDown() }
            setScale("1")
            check(enabled.await(8, TimeUnit.SECONDS)) { "production re-enable observer was not reached" }
            var eligibleRestored = false
            instrumentation.runOnMainSync { eligibleRestored = checkNotNull(window).preparedInitialLiveOrb(settings, profile) }
            val revivedSameWake = synchronized(queueLock) { restoredGate.take(request(authority, 2), ticket(authority)) }
            val newAuthority = authority.copy(wakeGeneration = authority.wakeGeneration + 1)
            val allowedNextWake = synchronized(queueLock) {
                restoredGate.begin(newAuthority, eligibleRestored)
                restoredGate.take(request(newAuthority, 3), ticket(newAuthority))
            }
            val staleObserver = KeyguardCardWindow::class.java.getDeclaredField("surfaceAnimationObserver").apply {
                isAccessible = true
            }.get(checkNotNull(window)) as android.database.ContentObserver
            instrumentation.runOnMainSync { checkNotNull(window).dispose(); window = null }
            val invalidationsBeforeStale = invalidations.get()
            setScale("0")
            instrumentation.runOnMainSync { staleObserver.onChange(false) }
            val staleIgnored = invalidations.get() == invalidationsBeforeStale
            evidence.writeText("source=${args.getString("sourceSha")} run=$runId prepared=true route=SURFACE_LIVE " +
                "changed=$changedAt observer=${observedAt.get()} eligibleBefore=$eligibleBefore eligibleAfter=$eligibleAfter " +
                "invalidations=${invalidations.get()} consumedWhileOff=$consumedWhileOff eligibleRestored=$eligibleRestored " +
                "revivedSameWake=$revivedSameWake allowedNextWake=$allowedNextWake staleAfterDisposeIgnored=$staleIgnored\n")
            assertFalse("motion-off must revoke detached LIVE eligibility after the real observer", eligibleAfter)
            assertTrue("motion-off must invalidate the already-issued opportunity", invalidations.get() > 0)
            assertFalse("issued opportunity must not be taken after motion-off", consumedWhileOff)
            assertTrue("re-enable permits a new wake", eligibleRestored && allowedNextWake)
            assertFalse("re-enable must not revive the old wake", revivedSameWake)
            assertTrue("a disposed observer must not invalidate a later session", staleIgnored)
        } finally {
            KeyguardR15AcquisitionTestHooks.motionObserver = null
            instrumentation.runOnMainSync { window?.dispose(); activity?.finish() }
            setScale(saved)
        }
    }

    /** Real retained panel/route ownership; this is not a service compositor gate. */
    @Test fun r13FinancialDemandAndPrivacyAcrossRetainedRouteChanges() {
        assumeTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        check(context.getSharedPreferences("fluvi_keyguard_orb_diagnostic_route", Context.MODE_PRIVATE)
            .edit().putString("mode", "SURFACE_STATIC").commit())
        val activity = instrumentation.startActivitySync(Intent(context, KeyguardMaterialTestActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) as KeyguardMaterialTestActivity
        val settings = KeyguardCardSettings(requested = true, showFinancialDetails = true,
            presentationMode = KeyguardCardPresentationMode.ORB, animationMode = KeyguardCardAnimationMode.ORB_ONLY)
        val legacy = settings.copy(animationMode = KeyguardCardAnimationMode.OFF)
        val content = com.fluvi.app.runtime.FluviLockScreenCardContent("focus", "amount", "detail",
            "event", "label", android.graphics.Color.rgb(210, 72, 43), true)
        var window: KeyguardCardWindow? = null
        lateinit var manager: TestPanelWindowManager
        lateinit var target: KeyguardCardWindow
        lateinit var expectedRoot: View
        try {
            instrumentation.runOnMainSync {
                activity.setContentView(FrameLayout(activity))
                manager = TestPanelWindowManager(activity)
                target = KeyguardCardWindow(activity, onOpen = {}, onToggle = {}, onInteractionStarted = {},
                    onPositionCommitted = { _, _, _, _ -> }, onInteractionDiagnostic = { _, _ -> }, manager = manager)
                window = target
                target.prepareRetainedView(settings, calibratedOrbProfile())
                val work = com.fluvi.app.runtime.FluviFinancialOrbWork.begin()
                try {
                    assertEquals(KeyguardCardWindow.Result.ATTACHED,
                        target.showOrUpdate(FluviFinancialCardPresenter.full(content, false), settings))
                    assertTrue("test requires the real Surface owner", target.surfaceForTest() != null)
                    expectedRoot = requireNotNull(manager.currentRoot)
                    assertEquals(1L, work.constructions)
                    assertEquals(0L, work.paints)
                    assertEquals(0L, work.legacyBinds)
                } finally { com.fluvi.app.runtime.FluviFinancialOrbWork.end(work) }
            }
            // addView can return before Android dispatches the real attach and
            // creates the holder. Keep Main free, then sample one identity on
            // Main until that same root and Surface are ready and measured.
            val deadline = SystemClock.uptimeMillis() + 25_000L
            var ready = false
            while (!ready && SystemClock.uptimeMillis() < deadline) {
                instrumentation.runOnMainSync {
                    val surface = target.surfaceForTest()
                    ready = manager.currentRoot === expectedRoot && expectedRoot.isAttachedToWindow &&
                        expectedRoot.width > 0 && expectedRoot.height > 0 && surface != null &&
                        surface.isAttachedToWindow && surface.width > 0 && surface.height > 0 && surface.holder.surface.isValid
                }
                if (!ready) SystemClock.sleep(25)
            }
            assertTrue("fixture must reach the same attached, measured root and valid Surface", ready)
            instrumentation.runOnMainSync {
                assertTrue("root identity must survive the readiness sample", manager.currentRoot === expectedRoot)
                val work = com.fluvi.app.runtime.FluviFinancialOrbWork.begin()
                try {
                    repeat(32) {
                        assertEquals(KeyguardCardWindow.Result.NO_OP,
                            target.showOrUpdate(FluviFinancialCardPresenter.full(content, false), settings))
                    }
                    assertEquals(32L, work.constructions)
                    assertEquals(0L, work.paints)
                    assertEquals(0L, work.legacyBinds)
                } finally { com.fluvi.app.runtime.FluviFinancialOrbWork.end(work) }
                val view = requireNotNull(manager.currentRoot)
                    .findViewById<KeyguardHeaderMaterialView>(R.id.fluvi_financial_snapshot_orb)
                assertEquals(null, view.staticBitmapForTest())

                val authorized = FluviFinancialCardPresenter.full(content, false)
                assertEquals(KeyguardCardWindow.Result.LAYOUT_UPDATED, target.showOrUpdate(authorized, legacy))
                val fullBitmap = requireNotNull(view.staticBitmapForTest())
                org.junit.Assert.assertSame(authorized.orb, fullBitmap)
                val discreet = FluviFinancialCardPresenter.discreet()
                target.showOrUpdate(discreet, legacy.copy(showFinancialDetails = false))
                val neutralBitmap = requireNotNull(view.staticBitmapForTest())
                org.junit.Assert.assertSame(discreet.orb, neutralBitmap)
                assertTrue("neutral and full fallback must differ", fullBitmap.getPixel(48, 48) != neutralBitmap.getPixel(48, 48))

                val clearVisibilities = mutableListOf<Int>()
                view.onStaticBitmapClearedForTest = { clearVisibilities += it }
                target.showOrUpdate(discreet, settings.copy(showFinancialDetails = false))
                assertTrue("transition must select Surface", target.surfaceForTest() != null)
                assertEquals(View.GONE, view.visibility)
                assertEquals("retired legacy View must release fallback", null, view.staticBitmapForTest())
                assertEquals("the old fallback must be cleared once, while its View is hidden",
                    listOf(View.GONE), clearVisibilities)
                view.onStaticBitmapClearedForTest = null
                val authorizedNeutral = FluviFinancialCardPresenter.discreet()
                target.showOrUpdate(authorizedNeutral, legacy.copy(showFinancialDetails = false))
                org.junit.Assert.assertSame("legacy must synchronously receive current neutral fallback",
                    authorizedNeutral.orb, view.staticBitmapForTest())
                assertTrue(target.hide())
            }
        } finally {
            instrumentation.runOnMainSync { window?.dispose(); activity.finish() }
        }
    }

    /** Producer-only positive/negative control. A real View screenshot is the
     * independent reference; this does not claim SurfaceView composition or
     * replace the separately required service/privacy screen samples. */
    @Test fun r12PreparedPictureMatchesCanonicalHardwareCanvasAcrossPhases() {
        assumeTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        val profile = calibratedOrbProfile()
        val controlled = AtomicReference(calibratedMaterialTime(PHASE_A))
        val activity = instrumentation.startActivitySync(
            Intent(context, KeyguardMaterialTestActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        val thread = android.os.HandlerThread("r12-poster-control").apply { start() }
        val handler = android.os.Handler(thread.looper)
        val references = mutableListOf<Bitmap>()
        val posters = java.util.concurrent.CopyOnWriteArrayList<Bitmap>()
        val failure = AtomicReference<Throwable?>()
        lateinit var view: KeyguardHeaderMaterialView
        try {
            val artifact = AndroidKeyguardShaderArtifactReader.load(context, profile.effectId, profile.usesPortal)
            instrumentation.runOnMainSync {
                view = KeyguardHeaderMaterialView(activity,
                    materialTimeSource = KeyguardMaterialTimeSource { _, _ -> controlled.get() }).apply {
                    layoutParams = FrameLayout.LayoutParams(168, 168, Gravity.CENTER)
                    setScene(KeyguardMaterialScene(profile, true, 0L), enabled = true)
                    setBootstrapActive(false)
                    assertEquals(KeyguardHeaderMaterialView.ProgramPreparationResult.COMPILED, installPreparedShader(artifact))
                }
                activity.setContentView(FrameLayout(activity).apply { addView(view) })
                view.frame(1L)
            }
            assertTrue("reference hardware Canvas was not ready", waitForPreparedShader(instrumentation, view))
            assertTrue("reference bounds were not established", waitForMaterialViewScreenBounds(instrumentation, view))
            val phases = listOf(PHASE_A, PHASE_C, PHASE_B, PHASE_A)
            phases.forEachIndexed { index, phase ->
                var before = 0
                instrumentation.runOnMainSync {
                    before = view.diagnostics().shaderDrawCount
                    controlled.set(calibratedMaterialTime(phase))
                    view.frame(System.nanoTime())
                }
                assertTrue("reference phase $index did not draw", waitForShaderDraw(instrumentation, view, before))
                val reference = awaitCompositorCrop("r12-reference-$index", { copyMaterialView(instrumentation, view) },
                    { label, bitmap -> persistPanelEvidence(activity, label, bitmap) },
                    { candidate -> if (index == 0) hasVisibleMaterial(candidate) else if (index == 2)
                        compareMaterialPixels(references[0], candidate).meaningful() else
                        compareMaterialPixels(references[0], candidate).nearlyEqual() }, {})
                references += reference
            }
            val ready = CountDownLatch(1)
            handler.post {
                try {
                    val painter = KeyguardOrbSurfacePainter(context, profile.copyForSurface(), 168, 168)
                    phases.forEach { phase ->
                        val hardware = painter.makePoster(calibratedMaterialTime(phase))
                        try { posters += checkNotNull(hardware.copy(Bitmap.Config.ARGB_8888, false)) }
                        finally { hardware.recycle() }
                    }
                } catch (error: Throwable) { failure.set(error) }
                finally { ready.countDown() }
            }
            assertTrue("worker picture control did not finish", ready.await(30, TimeUnit.SECONDS))
            failure.get()?.let { throw AssertionError("worker picture preparation failed", it) }
            assertEquals(4, posters.size)
            posters.forEachIndexed { index, bitmap -> persistPanelEvidence(activity, "r12-poster-$index", bitmap) }
            assertTrue("reference A/C plateau was not calibrated", compareMaterialPixels(references[0], references[1]).nearlyEqual())
            assertTrue("reference A/B positive control was not calibrated", compareMaterialPixels(references[0], references[2]).meaningful())
            assertTrue("reference return-A was not calibrated", compareMaterialPixels(references[0], references[3]).nearlyEqual())
            posters.forEachIndexed { index, bitmap ->
                assertEquals("poster exterior must be transparent", 0, android.graphics.Color.alpha(bitmap.getPixel(0, 0)))
                assertTrue("poster interior must be opaque", android.graphics.Color.alpha(bitmap.getPixel(84, 84)) >= 240)
                assertTrue("poster $index differs from canonical reference: ${compareMaterialPixels(references[index], bitmap)}",
                    compareMaterialPixels(references[index], bitmap).nearlyEqual())
            }
        } finally {
            references.forEach(Bitmap::recycle)
            posters.forEach(Bitmap::recycle)
            thread.quitSafely()
            instrumentation.runOnMainSync { activity.finish() }
        }
    }

    /** Real WindowManager panel and screen-composited reference. This is a
     * panel control, not the separate production AccessibilityService gate. */
    @Test fun r12StaticSurfaceMatchesFullAndNeutralReferenceOnRealPanel() {
        assumeTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        context.getSharedPreferences("fluvi_keyguard_orb_diagnostic_route", Context.MODE_PRIVATE)
            .edit().putString("mode", "SURFACE_STATIC").commit()
        KeyguardCardDiagnostics.startCapture(context, "r12-panel-control", "debug", "FULL")
        val activity = instrumentation.startActivitySync(
            Intent(context, KeyguardMaterialTestActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        val profile = calibratedOrbProfile()
        val time = KeyguardMaterialTime(profile.elapsedSeconds, profile.phase, profile.background.phase, profile.interior.phase)
        val events = java.util.concurrent.CopyOnWriteArrayList<KeyguardOrbSurfaceObservation>()
        val failure = AtomicReference<String?>()
        lateinit var manager: TestPanelWindowManager
        lateinit var window: KeyguardCardWindow
        var createdWindow: KeyguardCardWindow? = null
        lateinit var referenceView: KeyguardHeaderMaterialView
        var fullReference: Bitmap? = null
        var neutralReference: Bitmap? = null
        var fullCrop: Bitmap? = null
        var neutralCrop: Bitmap? = null
        var gate: ViewTreeObserver.OnPreDrawListener? = null
        var gateObserver: ViewTreeObserver? = null
        try {
            val artifact = AndroidKeyguardShaderArtifactReader.load(context, profile.effectId, profile.usesPortal)
            instrumentation.runOnMainSync {
                referenceView = KeyguardHeaderMaterialView(activity,
                    materialTimeSource = KeyguardMaterialTimeSource { _, _ -> time }).apply {
                    layoutParams = FrameLayout.LayoutParams(168, 168, Gravity.CENTER)
                    setScene(KeyguardMaterialScene(profile, true, 0L), enabled = true)
                    setBootstrapActive(false)
                    assertEquals(KeyguardHeaderMaterialView.ProgramPreparationResult.COMPILED, installPreparedShader(artifact))
                }
                activity.setContentView(FrameLayout(activity).apply {
                    setBackgroundColor(android.graphics.Color.WHITE)
                    addView(referenceView)
                })
                referenceView.frame(1L)
            }
            assertTrue(waitForPreparedShader(instrumentation, referenceView))
            assertTrue(waitForMaterialViewScreenBounds(instrumentation, referenceView))
            fullReference = awaitCompositorCrop("r12-panel-full-reference", { copyMaterialView(instrumentation, referenceView) },
                { label, bitmap -> persistPanelEvidence(activity, label, bitmap) }, { hasVisibleMaterial(it) }, {})
            var before = 0
            instrumentation.runOnMainSync {
                before = referenceView.diagnostics().shaderDrawCount
                referenceView.setScene(KeyguardMaterialScene(profile.neutralized(), false, 0L), enabled = true)
                referenceView.frame(System.nanoTime())
            }
            assertTrue(waitForShaderDraw(instrumentation, referenceView, before))
            neutralReference = awaitCompositorCrop("r12-panel-neutral-reference", { copyMaterialView(instrumentation, referenceView) },
                { label, bitmap -> persistPanelEvidence(activity, label, bitmap) },
                { hasVisibleMaterial(it) && compareMaterialPixels(requireNotNull(fullReference), it).meaningful() }, {})
            assertTrue("neutral and full reference controls must differ",
                compareMaterialPixels(requireNotNull(fullReference), requireNotNull(neutralReference)).meaningful())
            val settings = KeyguardCardSettings(requested = true, showFinancialDetails = true,
                presentationMode = KeyguardCardPresentationMode.ORB, animationMode = KeyguardCardAnimationMode.ORB_ONLY)
            instrumentation.runOnMainSync {
                activity.setContentView(FrameLayout(activity).apply { setBackgroundColor(android.graphics.Color.WHITE) })
                manager = TestPanelWindowManager(activity)
                window = KeyguardCardWindow(activity, onOpen = {}, onToggle = {}, onInteractionStarted = {},
                    onPositionCommitted = { _, _, _, _ -> }, onInteractionDiagnostic = { _, _ -> },
                    armSurfaceDiagnostic = { _ -> { event -> events += event } },
                    onSurfaceFailure = { failure.set(it) }, manager = manager).also { createdWindow = it }
                window.prepareRetainedView(settings, profile)
                assertEquals(KeyguardCardWindow.Result.ATTACHED, window.showOrUpdate(FluviFinancialCardPresenter.loading(), settings))
            }
            fun await(label: String, predicate: () -> Boolean) {
                val deadline = SystemClock.uptimeMillis() + 25_000L
                while (SystemClock.uptimeMillis() < deadline && !predicate()) {
                    failure.get()?.let { throw AssertionError("$label failed: $it") }
                    SystemClock.sleep(25)
                }
                assertTrue("$label was not reached", predicate())
            }
            fun crop(): Bitmap {
                lateinit var bounds: Rect
                instrumentation.runOnMainSync {
                    val target = checkNotNull(window.surfaceForTest())
                    check(target.isAttachedToWindow && target.holder.surface.isValid)
                    val location = IntArray(2)
                    target.getLocationOnScreen(location)
                    bounds = Rect(location[0], location[1], location[0] + target.width, location[1] + target.height)
                }
                assertEquals(168, bounds.width())
                assertEquals(168, bounds.height())
                val screen = checkNotNull(instrumentation.uiAutomation.takeScreenshot())
                try {
                    check(bounds.left >= 0 && bounds.top >= 0 && bounds.right <= screen.width && bounds.bottom <= screen.height)
                    return Bitmap.createBitmap(screen, bounds.left, bounds.top, bounds.width(), bounds.height())
                } finally { screen.recycle() }
            }
            await("first static post") { events.any { it.stage == "FIRST_POST" } }
            fullCrop = awaitCompositorCrop("r12-panel-full", ::crop,
                { label, bitmap -> persistPanelEvidence(activity, label, bitmap) },
                { compareMaterialPixels(requireNotNull(fullReference), it).nearlyEqual() }, {})
            val withheld = AtomicInteger()
            instrumentation.runOnMainSync {
                val panel = checkNotNull(manager.currentRoot)
                gate = ViewTreeObserver.OnPreDrawListener { withheld.incrementAndGet(); false }
                gateObserver = panel.viewTreeObserver
                gateObserver!!.addOnPreDrawListener(requireNotNull(gate))
                panel.invalidate()
            }
            await("withheld root traversal") { withheld.get() > 0 }
            val stillVisible = crop()
            try {
                persistPanelEvidence(activity, "r12-panel-static-withheld", stillVisible)
                assertTrue(compareMaterialPixels(requireNotNull(fullReference), stillVisible).nearlyEqual())
            } finally { stillVisible.recycle() }
            instrumentation.runOnMainSync {
                gate?.let { listener -> gateObserver?.takeIf { it.isAlive }?.removeOnPreDrawListener(listener) }
                gate = null
                manager.currentRoot?.invalidate()
                window.showOrUpdate(FluviFinancialCardPresenter.discreet(), settings.copy(showFinancialDetails = false))
            }
            await("neutral target producer confirmation") { events.any { it.stage == "GUARD_RETIRED" } }
            neutralCrop = awaitCompositorCrop("r12-panel-neutral", ::crop,
                { label, bitmap -> persistPanelEvidence(activity, label, bitmap) },
                { compareMaterialPixels(requireNotNull(neutralReference), it).nearlyEqual() }, {})
            assertTrue("neutral target must differ from the full scene",
                compareMaterialPixels(requireNotNull(fullCrop), requireNotNull(neutralCrop)).meaningful())
            instrumentation.runOnMainSync {
                assertTrue(window.hide())
                assertFalse(window.isAttached)
            }
        } finally {
            instrumentation.runOnMainSync {
                gate?.let { listener -> gateObserver?.takeIf { it.isAlive }?.removeOnPreDrawListener(listener) }
                createdWindow?.dispose()
                activity.finish()
            }
            KeyguardCardDiagnostics.clearCapture(context)
            fullReference?.recycle(); neutralReference?.recycle(); fullCrop?.recycle(); neutralCrop?.recycle()
        }
    }
    @Test fun r11OfferBeforeGrantTransfersInsideGrantWithNudgeHeld() = exerciseR11FirstOfferOrder(true)
    @Test fun r11GrantBeforeOfferTransfersViaOrdinaryNudge() = exerciseR11FirstOfferOrder(false)

    @Test fun r11PrivacyChangeWithIdenticalVisualStillGetsFreshLease() {
        withOrbRetirementFixture("r11-identical-privacy") { fixture ->
            val initial = fixture.awaitFirstToken(fixture.initialLease.attachment)
            val neutralProfile = calibratedOrbProfile().neutralized()
            fixture.instrumentation.runOnMainSync {
                fixture.window.updateMaterial(neutralProfile, fixture.settings)
            }
            val fullNeutral = fixture.awaitReplacementToken(initial)
            fixture.instrumentation.runOnMainSync {
                fixture.window.showOrUpdate(FluviFinancialCardPresenter.discreet(),
                    fixture.settings.copy(showFinancialDetails = false))
            }
            val discreet = fixture.awaitReplacementToken(fullNeutral)
            assertEquals(fullNeutral.lease.visualKey, discreet.lease.visualKey)
            fixture.instrumentation.runOnMainSync {
                fixture.window.showOrUpdate(FluviFinancialCardPresenter.loading(), fixture.settings)
            }
            val fullAgain = fixture.awaitReplacementToken(discreet)
            assertEquals(discreet.lease.attachment, fullAgain.lease.attachment)
            assertEquals(discreet.lease.visualKey, fullAgain.lease.visualKey)
            assertTrue("privacy change reused the previous first-offer lifetime",
                fullAgain.lease.generation > discreet.lease.generation)
            fixture.ownership.assertBoundedSingleRenderer()
        }
    }

    @Test fun r11PendingPositiveRetiredBeforeGrantCannotSubmitIntoReplacement() {
        assumeTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val activity = instrumentation.startActivitySync(
            Intent(instrumentation.targetContext, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        val controlled = ControlledOrbTimeSource(calibratedMaterialTime(PHASE_A))
        val submissions = SubmittedFrameTracker()
        val ownership = OrbOwnershipHistory()
        val held = AtomicReference<(() -> Unit)?>()
        val heldSignal = CountDownLatch(1)
        val firstOutput = java.util.concurrent.CopyOnWriteArrayList<KeyguardOrbFirstPublicationToken>()
        lateinit var renderer: KeyguardOrbBufferRenderer
        var createdRenderer: KeyguardOrbBufferRenderer? = null
        lateinit var manager: TestPanelWindowManager
        var root: FrameLayout? = null
        var added = false
        try {
            val profile = calibratedOrbProfile()
            val artifact = AndroidKeyguardShaderArtifactReader.load(activity, profile.effectId, profile.usesPortal)
            val a = KeyguardOrbBufferLease(1, 1, profile.visualKey, artifact.programKey, 168, 168)
            val b = a.copy(attachment = 2, generation = 2)
            controlled.submit(1, calibratedMaterialTime(PHASE_A))
            submissions.expect(1, PHASE_A, 1)
            instrumentation.runOnMainSync {
                manager = TestPanelWindowManager(activity)
                renderer = KeyguardOrbBufferRenderer(
                    onFirstPublished = { token, _ -> firstOutput += token },
                    onFirstCommitReceived = { _, _, _ -> }, onFirstCommitted = { },
                    onFailure = { _, failure -> throw AssertionError("renderer failure", failure) },
                    onSizeChanged = { throw AssertionError("unexpected size replacement") },
                    publicationObserver = submissions, ownershipObserver = ownership,
                    materialTimeSource = controlled,
                    firstNudgeHook = KeyguardOrbFirstNudgeTestHook { lease, post ->
                        if (lease == a) { check(held.compareAndSet(null, post)); heldSignal.countDown() }
                        else post()
                    },
                    recoveryHook = NoopKeyguardOrbRecoveryTestHook,
                )
                createdRenderer = renderer
                renderer.configure(KeyguardOrbBufferRenderSpec(a, artifact,
                    KeyguardMaterialScene(profile, true, System.nanoTime())))
            }
            assertTrue("A was not actually offered before grant", heldSignal.await(12, TimeUnit.SECONDS))
            controlled.submit(2, calibratedMaterialTime(PHASE_B))
            submissions.expect(2, PHASE_B, 2)
            lateinit var orb: View
            instrumentation.runOnMainSync {
                renderer.retire("hide-before-child")
                renderer.configure(KeyguardOrbBufferRenderSpec(b, artifact,
                    KeyguardMaterialScene(profile, true, System.nanoTime())))
                val panel = FrameLayout(activity).apply { setBackgroundColor(android.graphics.Color.WHITE) }
                orb = View(activity).apply { id = R.id.fluvi_financial_snapshot_orb }
                panel.addView(orb, FrameLayout.LayoutParams(168, 168, Gravity.CENTER))
                root = panel
                manager.addView(panel, WindowManager.LayoutParams(500, 500).apply { gravity = Gravity.CENTER })
                added = true
            }
            assertTrue(waitForPanelOrbScreenBounds(instrumentation, manager))
            instrumentation.runOnMainSync { renderer.attach(requireNotNull(root), orb, 2) }
            val current = submissions.await(2)
            assertEquals(b, current.lease)
            checkNotNull(held.get()).invoke()
            instrumentation.runOnMainSync { }
            assertFalse("revoked A submitted after B's grant", submissions.hasSubmitted(1))
            assertTrue(firstOutput.all { it.lease == b })
            val drained = ownership.awaitLease("lease-drained", a)
            assertTrue(drained.slots.none { it.lease == a && it.state != "FREE" })
            ownership.assertBoundedSingleRenderer()
        } finally {
            held.get()?.invoke()
            instrumentation.runOnMainSync {
                createdRenderer?.dispose()
                if (added) manager.removeViewImmediate(requireNotNull(root))
                activity.finish()
            }
        }
    }

    /** Both orders use an actual renderer, GPU buffer and real panel child.
     * The nudge gate stores only a scheduling continuation and never blocks
     * Main. A real first steady buffer is held while A pixels are sampled. */
    private fun exerciseR11FirstOfferOrder(offerFirst: Boolean) {
        assumeTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val activity = instrumentation.startActivitySync(
            Intent(instrumentation.targetContext, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        val produced = CalibratedProducerSamples()
        val submissions = SubmittedFrameTracker()
        val controlled = ControlledOrbTimeSource(calibratedMaterialTime(PHASE_A))
        val enteredRender = CountDownLatch(1)
        val releaseRender = CountDownLatch(1)
        val enteredSteady = CountDownLatch(1)
        val releaseSteady = CountDownLatch(1)
        val nudgeHeld = CountDownLatch(1)
        val committed = CountDownLatch(1)
        val heldNudge = AtomicReference<(() -> Unit)?>()
        val outputCount = AtomicInteger()
        val observations = java.util.concurrent.CopyOnWriteArrayList<KeyguardOrbFirstOfferObservation>()
        val error = AtomicReference<Throwable?>()
        lateinit var renderer: KeyguardOrbBufferRenderer
        var createdRenderer: KeyguardOrbBufferRenderer? = null
        lateinit var manager: TestPanelWindowManager
        var root: FrameLayout? = null
        var added = false
        try {
            val profile = calibratedOrbProfile()
            val artifact = AndroidKeyguardShaderArtifactReader.load(activity, profile.effectId, profile.usesPortal)
            val lease = KeyguardOrbBufferLease(1, 1, profile.visualKey, artifact.programKey, 168, 168)
            produced.expect(1, 1)
            submissions.expect(1, PHASE_A, 1)
            controlled.submit(1, calibratedMaterialTime(PHASE_A))
            val renderGate = KeyguardOrbRenderBarrier { current ->
                if (!offerFirst && current == lease) {
                    enteredRender.countDown()
                    check(releaseRender.await(8, TimeUnit.SECONDS)) { "R11 grant-first render gate timed out" }
                }
            }
            val nudgeGate = KeyguardOrbFirstNudgeTestHook { current, post ->
                if (offerFirst && current == lease) {
                    check(heldNudge.compareAndSet(null, post))
                    nudgeHeld.countDown()
                } else post()
            }
            val firstSteady = java.util.concurrent.atomic.AtomicBoolean(true)
            instrumentation.runOnMainSync {
                manager = TestPanelWindowManager(activity)
                renderer = KeyguardOrbBufferRenderer(
                    onFirstPublished = { token, _ -> if (token.lease == lease) outputCount.incrementAndGet() },
                    onFirstCommitReceived = { token, _, _ -> if (token.lease == lease) committed.countDown() }, onFirstCommitted = { },
                    onFailure = { _, failure -> error.set(failure) },
                    onSizeChanged = { error.set(AssertionError("unexpected size replacement")) },
                    barrier = renderGate, frameObserver = produced, publicationObserver = submissions,
                    materialTimeSource = controlled,
                    firstOfferReporter = { { observation ->
                        observations += observation
                        if (offerFirst && observation.stage == "applyEnd") {
                            throw IllegalStateException("injected-r11-observer-after-transfer")
                        }
                    } },
                    steadyPublicationBarrier = KeyguardOrbSteadyPublicationBarrier { frame ->
                        if (frame.lease == lease && firstSteady.compareAndSet(true, false)) {
                            enteredSteady.countDown()
                            check(releaseSteady.await(8, TimeUnit.SECONDS)) { "R11 steady fixture gate timed out" }
                        }
                    },
                    firstNudgeHook = nudgeGate,
                    recoveryHook = NoopKeyguardOrbRecoveryTestHook,
                )
                createdRenderer = renderer
                renderer.configure(KeyguardOrbBufferRenderSpec(lease, artifact,
                    KeyguardMaterialScene(profile, full = true, appliedAtNanos = System.nanoTime())))
            }
            if (offerFirst) {
                assertTrue("first positive nudge was not held", nudgeHeld.await(12, TimeUnit.SECONDS))
            } else {
                assertTrue("first producer did not reach the pre-submit gate", enteredRender.await(12, TimeUnit.SECONDS))
            }
            lateinit var orb: View
            instrumentation.runOnMainSync {
                val panel = FrameLayout(activity).apply { setBackgroundColor(android.graphics.Color.WHITE) }
                orb = View(activity).apply { id = R.id.fluvi_financial_snapshot_orb }
                panel.addView(orb, FrameLayout.LayoutParams(168, 168, Gravity.CENTER))
                root = panel
                manager.addView(panel, WindowManager.LayoutParams(500, 500).apply { gravity = Gravity.CENTER })
                added = true
            }
            assertTrue("invalid fixture: no real panel geometry", waitForPanelOrbScreenBounds(instrumentation, manager))
            instrumentation.runOnMainSync {
                val panel = requireNotNull(root)
                assertTrue("invalid fixture: root surface missing", panel.rootSurfaceControl != null)
                renderer.attach(panel, orb, 1)
                if (offerFirst) assertEquals("grant returned before consuming the waiting use", 1, outputCount.get())
                else assertEquals("grant manufactured a frame before producer completion", 0, outputCount.get())
            }
            if (offerFirst) {
                checkNotNull(heldNudge.get()).invoke()
                instrumentation.runOnMainSync { }
            } else releaseRender.countDown()
            val first = submissions.await(1)
            val firstPixels = produced.await(1)
            assertEquals(first, firstPixels.frame)
            assertEquals("the first use was transferred twice", 1, outputCount.get())
            assertTrue("first direct transaction did not commit", committed.await(8, TimeUnit.SECONDS))
            assertTrue("real first steady use did not reach its gate", enteredSteady.await(8, TimeUnit.SECONDS))
            assertEquals("transparent first-buffer corner was filled", 0, firstPixels.pixels.first() ushr 24)
            val referenceA = Bitmap.createBitmap(firstPixels.pixels, 168, 168, Bitmap.Config.ARGB_8888)
            try {
                assertTrue("first producer reference contains no material", hasVisibleMaterial(referenceA))
                val image = awaitCompositorCrop("r11-first-${if (offerFirst) "grant" else "nudge"}",
                    { copyPanelOrb(instrumentation, manager) },
                    { label, bitmap -> persistPanelEvidence(activity, label, bitmap) },
                    { candidate -> compareMaterialPixels(referenceA, candidate).nearlyEqual() }, {})
                image.recycle()
            } finally { referenceA.recycle() }
            produced.expect(2, 1)
            submissions.expect(2, PHASE_B, 1)
            controlled.submit(2, calibratedMaterialTime(PHASE_B))
            releaseSteady.countDown()
            val successor = submissions.await(2)
            val successorPixels = produced.await(2)
            assertEquals(successor, successorPixels.frame)
            assertTrue("first and successor must be genuinely distinct", compareProducerPixels(firstPixels, successorPixels).meaningful())
            val referenceB = Bitmap.createBitmap(successorPixels.pixels, 168, 168, Bitmap.Config.ARGB_8888)
            try {
                val image = awaitCompositorCrop("r11-successor-${if (offerFirst) "grant" else "nudge"}",
                    { copyPanelOrb(instrumentation, manager) },
                    { label, bitmap -> persistPanelEvidence(activity, label, bitmap) },
                    { candidate -> compareMaterialPixels(referenceB, candidate).nearlyEqual() }, {})
                image.recycle()
            } finally { referenceB.recycle() }
            assertEquals(null, error.get())
            assertTrue("claim came from the wrong caller", observations.any {
                it.stage == "claim" && it.slot == first.slotId && it.use == first.useGeneration &&
                    it.origin == if (offerFirst) "grant" else "nudge"
            })
        } finally {
            releaseRender.countDown()
            releaseSteady.countDown()
            heldNudge.get()?.invoke()
            instrumentation.runOnMainSync {
                createdRenderer?.dispose()
                if (added) manager.removeViewImmediate(requireNotNull(root))
                activity.finish()
            }
        }
    }

    /** Real positive producer output may precede the first usable child.
     * Drain the ordinary Main nudge before creating a real panel; the exact
     * existing READY use must survive, then transfer to that panel once. */
    @Test fun r11PositiveReadyBeforeGrantSurvivesEarlyNudge() {
        assumeTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val activity = instrumentation.startActivitySync(
            Intent(instrumentation.targetContext, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        val first = AtomicReference<KeyguardOrbBufferProducerFrame?>()
        val produced = CountDownLatch(1)
        val submitted = CountDownLatch(1)
        val transferred = java.util.concurrent.CopyOnWriteArrayList<KeyguardOrbBufferProducerFrame>()
        val detachedCallbacks = AtomicInteger()
        val failure = AtomicReference<Throwable?>()
        lateinit var renderer: KeyguardOrbBufferRenderer
        var createdRenderer: KeyguardOrbBufferRenderer? = null
        lateinit var manager: TestPanelWindowManager
        var root: FrameLayout? = null
        var added = false
        try {
            val profile = calibratedOrbProfile()
            val artifact = AndroidKeyguardShaderArtifactReader.load(activity, profile.effectId, profile.usesPortal)
            val lease = KeyguardOrbBufferLease(1, 1, profile.visualKey, artifact.programKey, 168, 168)
            instrumentation.runOnMainSync {
                manager = TestPanelWindowManager(activity)
                renderer = KeyguardOrbBufferRenderer(
                    onFirstPublished = { _, _ -> }, onFirstCommitReceived = { _, _, _ -> },
                    onFirstCommitted = { }, onFailure = { _, error -> failure.set(error) },
                    onSizeChanged = { failure.set(AssertionError("unexpected size replacement")) },
                    frameObserver = object : KeyguardOrbBufferFrameObserver {
                        override fun onProduced(frame: KeyguardOrbBufferProducerFrame, buffer: HardwareBuffer, completionFence: SyncFence?) {
                            if (frame.lease == lease && first.compareAndSet(null, frame)) produced.countDown()
                        }
                    },
                    publicationObserver = KeyguardOrbBufferPublicationObserver { frame ->
                        if (frame == first.get()) { transferred += frame; submitted.countDown() }
                    },
                    onDetachedBackendPrepared = { _, _ -> detachedCallbacks.incrementAndGet() },
                    recoveryHook = NoopKeyguardOrbRecoveryTestHook,
                )
                createdRenderer = renderer
                renderer.configure(KeyguardOrbBufferRenderSpec(lease, artifact,
                    KeyguardMaterialScene(profile, full = true, appliedAtNanos = System.nanoTime())))
            }
            assertTrue("positive producer result was never reached", produced.await(12, TimeUnit.SECONDS))
            // The observer runs within Worker's result callback, just before
            // onFrameReady. A following Worker marker proves that the nudge
            // has actually been posted before the Main queue barrier below.
            val apiField = KeyguardOrbBufferRenderer::class.java.getDeclaredField("api34").apply { isAccessible = true }
            val api = requireNotNull(apiField.get(renderer))
            val workerField = api.javaClass.getDeclaredField("worker").apply { isAccessible = true }
            val worker = requireNotNull(workerField.get(api))
            val post = worker.javaClass.getDeclaredMethod("post", Runnable::class.java).apply { isAccessible = true }
            val workerMarker = CountDownLatch(1)
            post.invoke(worker, Runnable { workerMarker.countDown() })
            assertTrue("Worker did not finish posting its first nudge", workerMarker.await(8, TimeUnit.SECONDS))
            instrumentation.runOnMainSync { }
            val earlyDetached = detachedCallbacks.get()
            val earlyReady = renderer.snapshot().ready
            instrumentation.runOnMainSync {
                val panel = FrameLayout(activity)
                val orb = View(activity).apply { id = R.id.fluvi_financial_snapshot_orb }
                panel.addView(orb, FrameLayout.LayoutParams(168, 168, Gravity.CENTER))
                root = panel
                manager.addView(panel, WindowManager.LayoutParams(500, 500).apply { gravity = Gravity.CENTER })
                added = true
                renderer.attach(panel, orb, 1)
            }
            assertTrue("invalid fixture: real panel never obtained the expected geometry",
                waitForPanelOrbScreenBounds(instrumentation, manager))
            instrumentation.runOnMainSync {
                assertTrue("invalid fixture: real panel has no root surface",
                    requireNotNull(root).isAttachedToWindow && requireNotNull(root).rootSurfaceControl != null)
            }
            val panelSample = copyPanelOrb(instrumentation, manager)
            try { persistPanelEvidence(activity, "r11-ready-before-grant-panel", panelSample) }
            finally { panelSample.recycle() }
            assertEquals("positive lease was incorrectly classified as detached", 0, earlyDetached)
            assertEquals("the exact positive READY use was lost before a legal grant", 1, earlyReady)
            assertTrue("original READY use was not submitted on the real child", submitted.await(12, TimeUnit.SECONDS))
            assertEquals(listOf(first.get()), transferred.toList())
            assertEquals(null, failure.get())
        } finally {
            instrumentation.runOnMainSync {
                createdRenderer?.dispose()
                if (added) manager.removeViewImmediate(requireNotNull(root))
                activity.finish()
            }
        }
    }

    /** Baseline-compatible observation of the controller's actual render
     * input: detached preparation is not evidence of a previously displayed
     * layer. This is separate from the attached compositor control. */
    @Test fun r10PreparedOnlySceneCannotSeedVisibleBlend() {
        assumeTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val activity = instrumentation.startActivitySync(
            Intent(instrumentation.targetContext, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        var controller: KeyguardCardMaterialController? = null
        try {
            instrumentation.runOnMainSync {
                val orb = KeyguardHeaderMaterialView(activity)
                controller = KeyguardCardMaterialController(orb, KeyguardHeaderMaterialView(activity), View(activity))
                val profile = calibratedOrbProfile()
                controller!!.prepare(profile, KeyguardCardAnimationMode.ORB_ONLY, KeyguardCardPresentationMode.ORB, true)
                controller!!.update(profile, KeyguardCardAnimationMode.ORB_ONLY,
                    KeyguardCardPresentationMode.ORB, true, null)
                val previous = KeyguardCardMaterialController::class.java
                    .getDeclaredField("latestOrbPreviousScene").apply { isAccessible = true }.get(controller)
                assertEquals("a preparation-only scene must not be a visible previous layer", null, previous)
            }
        } finally {
            instrumentation.runOnMainSync { controller?.dispose(); activity.finish() }
        }
    }

    @Test fun r10DetachedNoopHidePreservesExplicitPendingPreparation() {
        assumeTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val activity = instrumentation.startActivitySync(
            Intent(instrumentation.targetContext, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        val readerEntered = CountDownLatch(1)
        val releaseReader = CountDownLatch(1)
        val prepared = CountDownLatch(1)
        val store = KeyguardShaderArtifactStore(activity, KeyguardShaderArtifactReader { context, effect, portal ->
            readerEntered.countDown()
            check(releaseReader.await(18, TimeUnit.SECONDS)) { "artifact fixture gate timed out" }
            AndroidKeyguardShaderArtifactReader.load(context, effect, portal)
        })
        var controller: KeyguardCardMaterialController? = null
        try {
            instrumentation.runOnMainSync {
                controller = KeyguardCardMaterialController(KeyguardHeaderMaterialView(activity),
                    KeyguardHeaderMaterialView(activity), View(activity), artifacts = store)
                controller!!.onPreparationStage = { stage, fields ->
                    if (stage == "MATERIAL_ISOLATED_BACKEND_PREPARED" && fields["leaseAttachment"] == 0L) {
                        prepared.countDown()
                    }
                }
                controller!!.prepare(calibratedOrbProfile(), KeyguardCardAnimationMode.ORB_ONLY,
                    KeyguardCardPresentationMode.ORB, true)
            }
            assertTrue("real artifact load did not reach the async fixture gate", readerEntered.await(8, TimeUnit.SECONDS))
            instrumentation.runOnMainSync { controller!!.stop("hide") }
            releaseReader.countDown()
            assertTrue("already-detached hide revoked the explicitly requested prime", prepared.await(18, TimeUnit.SECONDS))
            instrumentation.runOnMainSync {
                val diagnostics = controller!!.diagnostics()
                assertTrue("the actual detached producer did not complete", diagnostics.isolatedFramesProduced >= 1)
                assertEquals("detached preparation must not publish", 0, diagnostics.isolatedFramesPublished)
            }
        } finally {
            releaseReader.countDown()
            instrumentation.runOnMainSync { controller?.dispose(); activity.finish() }
        }
    }

    @Test fun r10AuthorizedFirstShowDoesNotStartAnotherDetachedRender() {
        assumeTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val activity = instrumentation.startActivitySync(
            Intent(instrumentation.targetContext, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        val renderEntries = java.util.concurrent.CopyOnWriteArrayList<Pair<Long, Long>>()
        val positiveEntered = CountDownLatch(1)
        val releasePositive = CountDownLatch(1)
        val firstPositive = java.util.concurrent.atomic.AtomicBoolean(true)
        val barrier = KeyguardOrbRenderBarrier { lease ->
            renderEntries.add(lease.attachment to SystemClock.uptimeMillis())
            if (lease.attachment > 0 && firstPositive.compareAndSet(true, false)) {
                positiveEntered.countDown()
                check(releasePositive.await(8, TimeUnit.SECONDS)) { "first positive fixture gate timed out" }
            }
        }
        val produced = java.util.concurrent.CopyOnWriteArrayList<KeyguardOrbBufferProducerFrame>()
        val observer = object : KeyguardOrbBufferFrameObserver {
            override fun onProduced(frame: KeyguardOrbBufferProducerFrame, buffer: HardwareBuffer, completionFence: SyncFence?) {
                produced.add(frame)
            }
        }
        val settings = KeyguardCardSettings(requested = true, showFinancialDetails = true,
            presentationMode = KeyguardCardPresentationMode.ORB, animationMode = KeyguardCardAnimationMode.ORB_ONLY,
            orbPosition = KeyguardCardOrbPosition(.5f, .5f))
        var window: KeyguardCardWindow? = null
        try {
            KeyguardCardDiagnostics.startCapture(activity, "r10-panel", "debug", "FULL")
            KeyguardOrbBufferRendererTestHooks.frameObserver = observer
            instrumentation.runOnMainSync {
                window = KeyguardCardWindow(serviceContext = activity, onOpen = {}, onToggle = {},
                    onInteractionStarted = {}, onPositionCommitted = { _, _, _, _ -> },
                    onInteractionDiagnostic = { _, _ -> }, manager = TestPanelWindowManager(activity),
                    isolatedOrbRenderBarrier = barrier)
                window!!.prepareRetainedView(settings, calibratedOrbProfile())
            }
            assertTrue("actual detached prime did not complete", waitForDetachedIsolatedBackend(instrumentation, window!!))
            val before = renderEntries.count { it.first == 0L }
            assertEquals("one actual detached warmup must be sufficient", 1, before)
            var showAt = 0L
            instrumentation.runOnMainSync {
                showAt = SystemClock.uptimeMillis()
                assertEquals(KeyguardCardWindow.Result.ATTACHED,
                    window!!.showOrUpdate(FluviFinancialCardPresenter.loading(), settings))
            }
            assertTrue("first authorized render did not reach the Worker seam", positiveEntered.await(8, TimeUnit.SECONDS))
            assertTrue("the authorized show must not start a lease-0 render",
                renderEntries.none { it.first == 0L && it.second >= showAt })
            releasePositive.countDown()
            assertTrue("first positive output was not published", waitForIsolatedOutput(instrumentation, window!!))
            val until = SystemClock.uptimeMillis() + 8_000L
            while (produced.count { it.lease.attachment > 0L } < 2 && SystemClock.uptimeMillis() < until) Thread.sleep(24)
            assertTrue("two fresh positive uses are required", produced.count { it.lease.attachment > 0L } >= 2)
            assertTrue("positive frames must have distinct slot/use identities",
                produced.filter { it.lease.attachment > 0L }.take(2).map { it.slotId to it.useGeneration }.distinct().size == 2)
            val coldSamples = AtomicReference<List<KeyguardOrbColdWorkSnapshot>>()
            instrumentation.runOnMainSync { coldSamples.set(window!!.attachmentRenderSummary()?.coldWork ?: emptyList()) }
            val firstLive = coldSamples.get().firstOrNull { it.attachment > 0L }
            assertTrue("first current scene must issue exactly one shader pass: $firstLive",
                firstLive != null && firstLive.passes == 1 && !firstLive.previousValid)
            assertTrue("a later callback started obsolete detached work",
                renderEntries.none { it.first == 0L && it.second >= showAt })
        } finally {
            releasePositive.countDown()
            instrumentation.runOnMainSync { window?.dispose(); activity.finish() }
            KeyguardOrbBufferRendererTestHooks.frameObserver = NoopKeyguardOrbBufferFrameObserver
            KeyguardCardDiagnostics.clearCapture(activity)
        }
    }

    @Test fun r10UnsubmittedDetachedWorkYieldsToAuthorizedAttach() {
        assumeTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val activity = instrumentation.startActivitySync(
            Intent(instrumentation.targetContext, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        val entered = CountDownLatch(1)
        val release = CountDownLatch(1)
        val gateOnce = java.util.concurrent.atomic.AtomicBoolean(true)
        val completed = java.util.concurrent.CopyOnWriteArrayList<KeyguardOrbBufferProducerFrame>()
        val barrier = KeyguardOrbRenderBarrier { lease ->
            if (lease.attachment == 0L && gateOnce.compareAndSet(true, false)) {
                entered.countDown()
                check(release.await(15, TimeUnit.SECONDS)) { "detached submission gate timed out" }
            }
        }
        val observer = object : KeyguardOrbBufferFrameObserver {
            override fun onProduced(frame: KeyguardOrbBufferProducerFrame, buffer: HardwareBuffer, completionFence: SyncFence?) {
                completed.add(frame)
            }
        }
        val settings = KeyguardCardSettings(requested = true, showFinancialDetails = true,
            presentationMode = KeyguardCardPresentationMode.ORB, animationMode = KeyguardCardAnimationMode.ORB_ONLY,
            orbPosition = KeyguardCardOrbPosition(.5f, .5f))
        var window: KeyguardCardWindow? = null
        try {
            KeyguardOrbBufferRendererTestHooks.frameObserver = observer
            instrumentation.runOnMainSync {
                window = KeyguardCardWindow(serviceContext = activity, onOpen = {}, onToggle = {},
                    onInteractionStarted = {}, onPositionCommitted = { _, _, _, _ -> },
                    onInteractionDiagnostic = { _, _ -> }, manager = TestPanelWindowManager(activity),
                    isolatedOrbRenderBarrier = barrier)
                window!!.prepareRetainedView(settings, calibratedOrbProfile())
            }
            assertTrue("real detached work never reached the pre-submit boundary", entered.await(10, TimeUnit.SECONDS))
            instrumentation.runOnMainSync {
                assertEquals(KeyguardCardWindow.Result.ATTACHED,
                    window!!.showOrUpdate(FluviFinancialCardPresenter.loading(), settings))
            }
            release.countDown()
            assertTrue("authorized lease must produce real current output", waitForIsolatedOutput(instrumentation, window!!))
            val until = SystemClock.uptimeMillis() + 8_000L
            while (completed.count { it.lease.attachment > 0L } < 2 && SystemClock.uptimeMillis() < until) Thread.sleep(24)
            assertTrue("superseded detached work must not reach a GPU completion", completed.none { it.lease.attachment == 0L })
            assertTrue("the current lease needs two fresh results", completed.count { it.lease.attachment > 0L } >= 2)
        } finally {
            release.countDown()
            instrumentation.runOnMainSync { window?.dispose(); activity.finish() }
            KeyguardOrbBufferRendererTestHooks.frameObserver = NoopKeyguardOrbBufferFrameObserver
        }
    }

    @Test fun r10VisiblePaletteChangeKeepsBlendButPrivacyChangeDoesNot() {
        assumeTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val activity = instrumentation.startActivitySync(
            Intent(instrumentation.targetContext, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        val settings = KeyguardCardSettings(requested = true, showFinancialDetails = true,
            presentationMode = KeyguardCardPresentationMode.ORB, animationMode = KeyguardCardAnimationMode.ORB_ONLY,
            orbPosition = KeyguardCardOrbPosition(.5f, .5f))
        var window: KeyguardCardWindow? = null
        try {
            lateinit var manager: TestPanelWindowManager
            val profileA = calibratedOrbProfile()
            val profileB = profileA.copy(colors = intArrayOf(0xff9a3525.toInt(), 0xffe39b23.toInt(), 0xfff0c94d.toInt()))
            fun controller(): KeyguardCardMaterialController = KeyguardCardWindow::class.java
                .getDeclaredField("materialController").apply { isAccessible = true }.get(window) as KeyguardCardMaterialController
            fun previous(): Any? = KeyguardCardMaterialController::class.java
                .getDeclaredField("latestOrbPreviousScene").apply { isAccessible = true }.get(controller())
            instrumentation.runOnMainSync {
                manager = TestPanelWindowManager(activity)
                window = KeyguardCardWindow(serviceContext = activity, onOpen = {}, onToggle = {},
                    onInteractionStarted = {}, onPositionCommitted = { _, _, _, _ -> },
                    onInteractionDiagnostic = { _, _ -> }, manager = manager)
                window!!.prepareRetainedView(settings, profileA)
            }
            assertTrue(waitForDetachedIsolatedBackend(instrumentation, window!!))
            instrumentation.runOnMainSync {
                assertEquals(KeyguardCardWindow.Result.ATTACHED,
                    window!!.showOrUpdate(FluviFinancialCardPresenter.loading(), settings))
                assertEquals("first authorized scene cannot blend a prime", null, previous())
            }
            assertTrue(waitForIsolatedOutput(instrumentation, window!!))
            assertTrue(waitForPanelOrbScreenBounds(instrumentation, manager))
            val original = awaitCompositorCrop("r10-palette-before", { copyPanelOrb(instrumentation, manager) },
                { name, image -> persistPanelEvidence(activity, name, image) }, { hasVisibleMaterial(it) }, {})
            try {
                instrumentation.runOnMainSync {
                    window!!.updateMaterial(profileA, settings)
                    assertEquals("same visual must not create a previous pass", null, previous())
                    window!!.updateMaterial(profileB, settings)
                    assertTrue("a genuinely different visible palette must preserve a blend", previous() != null)
                }
                val changed = awaitCompositorCrop("r10-palette-after", { copyPanelOrb(instrumentation, manager) },
                    { name, image -> persistPanelEvidence(activity, name, image) },
                    { hasVisibleMaterial(it) && compareMaterialPixels(original, it).meaningful() }, {})
                changed.recycle()
                instrumentation.runOnMainSync {
                    window!!.showOrUpdate(FluviFinancialCardPresenter.discreet(), settings.copy(showFinancialDetails = false))
                    assertEquals("privacy tightening cannot retain a full previous pass", null, previous())
                }
            } finally { original.recycle() }
        } finally {
            instrumentation.runOnMainSync { window?.dispose(); activity.finish() }
        }
    }

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

    @Test fun oldUsesPreventSuccessorButCurrentOrbKeepsMoving() {
        com.fluvi.app.lockscreen.KeyguardCardDiagnostics.clearCapture(
            InstrumentationRegistry.getInstrumentation().targetContext,
        )
        val receipts = RealReleaseGate().apply { delayTickets = true }
        withOrbRetirementFixture("r08-held-receipts", receipts) { fixture ->
            fun diagnostics(): KeyguardMaterialDiagnostics {
                var value: KeyguardMaterialDiagnostics? = null
                fixture.instrumentation.runOnMainSync { value = fixture.window.materialDiagnostics() }
                return requireNotNull(value)
            }
            fun showFirst(): KeyguardOrbBufferProducerFrame {
                val request = fixture.prepareFirst(PHASE_A)
                var attach = 0L
                fixture.instrumentation.runOnMainSync {
                    assertEquals(KeyguardCardWindow.Result.ATTACHED,
                        fixture.window.showOrUpdate(FluviFinancialCardPresenter.loading(), fixture.settings))
                    attach = fixture.window.currentAttachGeneration
                }
                return fixture.submitted(request).also { assertEquals(attach, it.lease.attachment) }
            }
            fun hide() {
                var stoppedFrames = 0L
                fixture.instrumentation.runOnMainSync {
                    assertTrue("actual root hide must return while receipts are held", fixture.window.hide())
                    assertFalse(fixture.window.isAttached)
                    val summary = requireNotNull(fixture.window.attachmentRenderSummary())
                    assertFalse("hidden View clock remained active", summary.clockRunning)
                    stoppedFrames = summary.orb.frames
                }
                Thread.sleep(120)
                fixture.instrumentation.runOnMainSync {
                    assertEquals("a hidden View must not keep drawing", stoppedFrames,
                        requireNotNull(fixture.window.attachmentRenderSummary()).orb.frames)
                }
            }

            val first = fixture.awaitFirstToken(fixture.initialLease.attachment)
            val a = KeyguardOrbBufferProducerFrame(first.lease, first.slotId, first.useGeneration,
                0L, calibratedMaterialTime(PHASE_A))
            hide()
            receipts.awaitActualReceipt(a)
            val b = showFirst()
            hide()
            receipts.awaitActualReceipt(b)
            val c = showFirst()
            val pressure = fixture.ownership.awaitLease("pressure-offered", c.lease)
            assertTrue("the offered snapshot must contain the two real retired uses", pressure.slots.count {
                it.retired && (it.lease == a.lease || it.lease == b.lease) &&
                    it.state == "PUBLISHED" && !it.callbackReceived
            } >= 2)
            assertTrue("real release receipts must remain withheld during recovery", receipts.heldCount() >= 2)
            receipts.awaitTicket(c.lease.attachment)
            assertTrue("recovery panel has no measured bounds", waitForPanelOrbScreenBounds(fixture.instrumentation, fixture.manager))
            assertTrue("first-direct commit must already have retired C's bootstrap",
                waitForIsolatedBootstrapReplacement(fixture.instrumentation, fixture.manager))
            val isolatedReference = copyPanelOrb(fixture.instrumentation, fixture.manager)
            try {
                persistPanelEvidence(fixture.activity, "r08-isolated-reference-a", isolatedReference)
                assertTrue("first-direct reference has no visible material", hasVisibleMaterial(isolatedReference))
                val transitionSamples = mutableListOf<Bitmap>()
                val transitionTimes = mutableListOf<String>()
                try {
                    fun captureTransition() {
                        val before = SystemClock.uptimeMillis()
                        val bitmap = copyPanelOrb(fixture.instrumentation, fixture.manager)
                        val after = SystemClock.uptimeMillis()
                        transitionSamples += bitmap
                        persistPanelEvidence(fixture.activity, "r08-recovery-transition-${transitionSamples.lastIndex}", bitmap)
                        var bounds: Rect? = null
                        fixture.instrumentation.runOnMainSync { bounds = fixture.manager.currentOrbBounds() }
                        transitionTimes += "sample=${transitionSamples.lastIndex} before=$before after=$after bounds=$bounds expected=visible-current"
                    }
                    captureTransition()
                    fixture.instrumentation.runOnMainSync { receipts.deliverTicket(c.lease.attachment) }
                    repeat(6) {
                        captureTransition()
                        Thread.sleep(16)
                    }
                    File(fixture.activity.filesDir, "keyguard-material-smoke/r11-recovery-transition-times.txt")
                        .writeText(transitionTimes.joinToString("\n", postfix = "\n"))
                    assertTrue("sampled handoff included an empty orb crop", transitionSamples.all(::hasVisibleMaterial))
                } finally {
                    transitionSamples.forEach(Bitmap::recycle)
                }
                val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(8)
                while (diagnostics().effectiveRoute != "PRESSURE_VIEW" && System.nanoTime() < deadline) Thread.sleep(24)
                assertEquals("current authorized attachment did not take the recovery route", "PRESSURE_VIEW", diagnostics().effectiveRoute)
                val afterSwitch = fixture.ownership.awaitLease("revocation-processed", c.lease)
                assertTrue("the same old uses must remain quarantined after takeover", listOf(a, b).all { old ->
                    afterSwitch.slots.any { it.lease == old.lease && it.slotId == old.slotId &&
                        it.useGeneration == old.useGeneration && it.retired && it.state == "PUBLISHED" &&
                        !it.callbackReceived && !it.fencePending }
                })
                val before = diagnostics()
                Thread.sleep(600)
                val middle = diagnostics()
                Thread.sleep(600)
                val after = diagnostics()
                assertTrue("first window lacks real View shader traversals", middle.attachmentShaderTraversals - before.attachmentShaderTraversals >= 3)
                assertTrue("first window lacks View phase advances", middle.attachmentPhaseAdvances - before.attachmentPhaseAdvances >= 2)
                assertTrue("second window lacks real View shader traversals", after.attachmentShaderTraversals - middle.attachmentShaderTraversals >= 3)
                assertTrue("second window lacks View phase advances", after.attachmentPhaseAdvances - middle.attachmentPhaseAdvances >= 2)
                assertTrue("old receipts were released before motion was measured", receipts.heldCount() >= 2)
                // Independent two-second visible hold: no screenshots or
                // per-frame polling while measuring these two adjacent intervals.
                val holdStart = SystemClock.uptimeMillis()
                val hold0 = diagnostics()
                Thread.sleep(1_000)
                val hold1 = diagnostics()
                val holdMid = SystemClock.uptimeMillis()
                Thread.sleep(1_000)
                val hold2 = diagnostics()
                val holdEnd = SystemClock.uptimeMillis()
                val firstSecond = hold1.attachmentShaderTraversals - hold0.attachmentShaderTraversals
                val secondSecond = hold2.attachmentShaderTraversals - hold1.attachmentShaderTraversals
                android.util.Log.i("FluviR08Motion", "firstMs=${holdMid - holdStart} firstDraws=$firstSecond " +
                    "secondMs=${holdEnd - holdMid} secondDraws=$secondSecond " +
                    "phase1=${hold1.attachmentPhaseAdvances - hold0.attachmentPhaseAdvances} " +
                    "phase2=${hold2.attachmentPhaseAdvances - hold1.attachmentPhaseAdvances}")
                assertTrue("two-second recovery hold plateaued", firstSecond >= 3 && secondSecond >= 3 &&
                    hold1.attachmentPhaseAdvances - hold0.attachmentPhaseAdvances >= 2 &&
                    hold2.attachmentPhaseAdvances - hold1.attachmentPhaseAdvances >= 2)
                val crop = copyPanelOrb(fixture.instrumentation, fixture.manager)
                try {
                    persistPanelEvidence(fixture.activity, "r08-held-recovery-moving", crop)
                    assertTrue("recovery crop lacks visible material", hasVisibleMaterial(crop))
                }
                finally { crop.recycle() }
                // Reuse the calibrated A/C/B/A compositor oracle on the actual
                // recovery View and the same retained window, with a fixed phase
                // source installed only for this test segment.
                lateinit var recoveryView: KeyguardHeaderMaterialView
                val controlled = AtomicReference(calibratedMaterialTime(PHASE_A))
                fixture.instrumentation.runOnMainSync {
                    recoveryView = requireNotNull(fixture.manager.currentRoot)
                        .findViewById(R.id.fluvi_financial_snapshot_orb)
                    recoveryView.setMaterialTimeSourceForTest(KeyguardMaterialTimeSource { _, _ -> controlled.get() })
                }
                val images = mutableListOf<Bitmap>()
                try {
                    fun sample(phase: Float, label: String, accepts: (Bitmap) -> Boolean): Bitmap {
                        var beforeDraw = 0
                        fixture.instrumentation.runOnMainSync {
                            assertEquals(c.lease.attachment, fixture.window.currentAttachGeneration)
                            beforeDraw = recoveryView.diagnostics().shaderDrawCount
                            controlled.set(calibratedMaterialTime(phase))
                            recoveryView.frame(System.nanoTime())
                        }
                        assertTrue("recovery View did not submit controlled $label",
                            waitForShaderDraw(fixture.instrumentation, recoveryView, beforeDraw))
                        return awaitCompositorCrop(label,
                            capture = { copyPanelOrb(fixture.instrumentation, fixture.manager) },
                            persist = { evidenceLabel, image -> persistPanelEvidence(fixture.activity, evidenceLabel, image) },
                            accepts = accepts,
                            onTimeout = { persistPanelCompositorTimeout(fixture.activity, fixture.instrumentation,
                                label, fixture.manager, c) },
                        ).also(images::add)
                    }
                    val aImage = sample(PHASE_A, "r08-recovery-a") {
                        hasVisibleMaterial(it) && compareMaterialPixels(isolatedReference, it).nearlyEqual()
                    }
                    val cImage = sample(PHASE_C, "r08-recovery-c") { compareMaterialPixels(aImage, it).nearlyEqual() }
                    val bImage = sample(PHASE_B, "r08-recovery-b") { compareMaterialPixels(aImage, it).meaningful() }
                    val returnImage = sample(PHASE_A, "r08-recovery-return-a") { compareMaterialPixels(aImage, it).nearlyEqual() }
                    assertTrue(compareMaterialPixels(aImage, cImage).nearlyEqual())
                    assertTrue(compareMaterialPixels(aImage, bImage).meaningful())
                    assertTrue(compareMaterialPixels(aImage, returnImage).nearlyEqual())
                    assertTrue("pixel control released old receipts", receipts.heldCount() >= 2)
                } finally {
                    fixture.instrumentation.runOnMainSync {
                        recoveryView.setMaterialTimeSourceForTest(SystemKeyguardMaterialTimeSource)
                    }
                    images.forEach(Bitmap::recycle)
                }
                hide()
                // The same controller must keep a working View route on fresh
                // authorized attachments while the old platform receipts remain
                // withheld. Each hide still returns on Main independently.
                repeat(3) { cycle ->
                    fixture.instrumentation.runOnMainSync {
                        assertEquals(KeyguardCardWindow.Result.ATTACHED,
                            fixture.window.showOrUpdate(FluviFinancialCardPresenter.loading(), fixture.settings))
                    }
                    assertEquals("PRESSURE_VIEW", diagnostics().effectiveRoute)
                    val start = diagnostics()
                    Thread.sleep(600)
                    val current = diagnostics()
                    assertTrue("recovery episode $cycle did not draw", current.attachmentShaderTraversals - start.attachmentShaderTraversals >= 3)
                    assertTrue("recovery episode $cycle did not move", current.attachmentPhaseAdvances - start.attachmentPhaseAdvances >= 2)
                    assertTrue("real receipts escaped before episode $cycle completed", receipts.heldCount() >= 2)
                    if (cycle == 2) {
                        receipts.releaseAll()
                        val restoredDeadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(8)
                        while (diagnostics().recoveryRestoredAt == null && System.nanoTime() < restoredDeadline) Thread.sleep(24)
                        assertTrue("actual receipt/fence drain was not observed", diagnostics().recoveryRestoredAt != null)
                        assertEquals("drain cannot change a running recovery episode", "PRESSURE_VIEW", diagnostics().effectiveRoute)
                    }
                    hide()
                }
                val next = showFirst()
                assertEquals("a later eligible attachment may use the drained pool", "ISOLATED", diagnostics().effectiveRoute)
                assertTrue("new attachment reused the old lease", next.lease != c.lease)
                fixture.ownership.assertBoundedSingleRenderer()
            } finally { isolatedReference.recycle() }
        }
    }

    @Test fun r09RetiredChildUnlinksAfterOrderedClearWithReleaseHeld() {
        val gate = RealReleaseGate()
        withOrbRetirementFixture("r09-retire-held-receipt", gate) { fixture ->
            val first = fixture.awaitFirstToken(fixture.initialLease.attachment)
            gate.heldLease = first.lease
            gate.allowContinuous = true
            val blocked = fixture.holdSteady(first.lease)
            val steady = blocked.awaitEntered()
            val accepted = fixture.ownership.awaitUse("steady-accepted", steady)
            val nextRequest = fixture.prepareFirst(PHASE_A)
            fixture.instrumentation.runOnMainSync {
                assertTrue(fixture.window.hide())
                assertFalse(fixture.window.isAttached)
                assertEquals(KeyguardCardWindow.Result.ATTACHED,
                    fixture.window.showOrUpdate(FluviFinancialCardPresenter.loading(), fixture.settings))
            }
            blocked.assertStillHeld("hide and replacement show")
            blocked.release.countDown()
            val submitted = fixture.ownership.awaitUse("steady-submitted", steady)
            val cleared = fixture.ownership.awaitLease("retirement-clear-applied", first.lease)
            assertEquals(accepted.childIdentity, cleared.childIdentity)
            assertTrue(fixture.ownership.snapshot().indexOf(submitted) < fixture.ownership.snapshot().indexOf(cleared))
            gate.awaitActualReceipt(steady)
            val committed = gate.awaitRetirement(first.lease, "final-clear-committed")
            val unlinked = gate.awaitRetirement(first.lease, "child-unlinked")
            assertEquals(System.identityHashCode(first.child), committed.child)
            assertEquals(committed.child, unlinked.child)
            assertTrue("unlink preceded the exact final-clear receipt", unlinked.at >= committed.at)
            assertTrue("old genuine receipt escaped before the unlink check", gate.heldCount() >= 1)
            val replacement = fixture.submitted(nextRequest)
            assertTrue(replacement.lease.attachment != first.lease.attachment)
            val reference = fixture.capture(PHASE_A, "replacement-a", ::hasVisibleMaterial)
            try { fixture.assertMotion(reference, "replacement", replacement.lease) }
            finally { reference.bitmap.recycle() }
            gate.releaseAll()
            fixture.ownership.awaitUse("release-received", steady)
            fixture.ownership.awaitUse("release-fence-complete", steady)
            fixture.ownership.assertBoundedSingleRenderer()
        }
    }

    @Test fun r09MixedSizeHeldOldUseLeavesCurrentSuccessorCapacity() {
        val gate = RealReleaseGate()
        withOrbRetirementFixture("r09-mixed-size-held", gate) { fixture ->
            val old = fixture.awaitFirstToken(fixture.initialLease.attachment)
            gate.heldLease = old.lease
            fixture.instrumentation.runOnMainSync { assertTrue(fixture.window.hide()) }
            gate.awaitActualReceipt(KeyguardOrbBufferProducerFrame(old.lease, old.slotId, old.useGeneration,
                0L, calibratedMaterialTime(PHASE_A)))
            gate.allowContinuous = true
            val request = fixture.prepareFirst(PHASE_A)
            fixture.instrumentation.runOnMainSync {
                assertEquals(KeyguardCardWindow.Result.ATTACHED,
                    fixture.window.showOrUpdate(FluviFinancialCardPresenter.loading(), fixture.settings))
            }
            val current = fixture.submitted(request)
            val token = fixture.awaitFirstToken(current.lease.attachment)
            lateinit var orb: KeyguardHeaderMaterialView
            fixture.instrumentation.runOnMainSync {
                orb = requireNotNull(fixture.manager.currentRoot).findViewById(R.id.fluvi_financial_snapshot_orb)
                orb.layout(orb.left, orb.top, orb.right + 4, orb.bottom + 4)
            }
            val resized = fixture.awaitReplacementToken(token)
            assertEquals(token.lease.width + 4, resized.lease.width)
            val first = fixture.capture(PHASE_A, "resized-a", ::hasVisibleMaterial)
            try {
                assertEquals(resized.lease, first.frame.lease)
                fixture.assertMotion(first, "resized", resized.lease)
            } finally { first.bitmap.recycle() }
            assertTrue("old use must remain held during current-size output", gate.heldCount() >= 1)
            fixture.instrumentation.runOnMainSync {
                orb.layout(orb.left, orb.top, orb.right - 4, orb.bottom - 4)
            }
            val reversed = fixture.awaitReplacementToken(resized)
            assertEquals(token.lease.width, reversed.lease.width)
            val returned = fixture.capture(PHASE_A, "reverse-a", ::hasVisibleMaterial)
            try {
                assertEquals(reversed.lease, returned.frame.lease)
                fixture.assertMotion(returned, "reverse", reversed.lease)
            } finally { returned.bitmap.recycle() }
            assertTrue(gate.heldCount() >= 1)
            fixture.ownership.assertBoundedSingleRenderer()
        }
    }

    @Test fun r09UnchangedPlacementSkipsRedundantTransactions() {
        val gate = RealReleaseGate().apply { releaseAll() }
        withOrbRetirementFixture("r09-placement", gate) { fixture ->
            val initial = fixture.awaitFirstToken(fixture.initialLease.attachment)
            val first = gate.placements.filter { it.lease == initial.lease }
            assertTrue("the real initial child placement was not observed", first.any { it.submitted })
            val before = first.count { it.submitted }
            fixture.instrumentation.runOnMainSync {
                val orb = requireNotNull(fixture.manager.currentRoot)
                    .findViewById<KeyguardHeaderMaterialView>(R.id.fluvi_financial_snapshot_orb)
                // Change layout coordinates while compensating translation so
                // the actual surface position remains identical.
                orb.translationX = -1f
                orb.layout(orb.left + 1, orb.top, orb.right + 1, orb.bottom)
            }
            val unchanged = gate.placements.filter { it.lease == initial.lease }
            assertTrue("unchanged reconciliation was not exercised", unchanged.any { !it.submitted })
            assertEquals(before, unchanged.count { it.submitted })
            fixture.instrumentation.runOnMainSync {
                val orb = requireNotNull(fixture.manager.currentRoot)
                    .findViewById<KeyguardHeaderMaterialView>(R.id.fluvi_financial_snapshot_orb)
                orb.layout(orb.left + 1, orb.top, orb.right + 1, orb.bottom)
            }
            assertEquals(before + 1, gate.placements.count { it.lease == initial.lease && it.submitted })
            val image = fixture.capture(PHASE_A, "after-move", ::hasVisibleMaterial)
            try { fixture.assertMotion(image, "after-move", initial.lease) }
            finally { image.bitmap.recycle() }
            val request = fixture.prepareFirst(PHASE_A)
            fixture.instrumentation.runOnMainSync {
                assertTrue(fixture.window.hide())
                assertEquals(KeyguardCardWindow.Result.ATTACHED,
                    fixture.window.showOrUpdate(FluviFinancialCardPresenter.loading(), fixture.settings))
            }
            val replacement = fixture.submitted(request)
            assertTrue(replacement.lease.attachment != initial.lease.attachment)
            assertTrue(gate.placements.any { it.lease == replacement.lease && it.submitted && it.child != System.identityHashCode(initial.child) })
            fixture.ownership.assertBoundedSingleRenderer()
        }
    }

    @Test fun r09NeutralPrivacyTransitionHasPositivePixels() {
        assumeTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        for ((label, background) in listOf("white" to android.graphics.Color.WHITE, "black" to android.graphics.Color.BLACK)) {
            // A separately mounted neutral bootstrap and a background-only
            // image calibrate the actual compositor, not a checksum or a
            // screenshot chosen after seeing the transition.
            val activity = instrumentation.startActivitySync(
                Intent(instrumentation.targetContext, KeyguardMaterialTestActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            ) as KeyguardMaterialTestActivity
            lateinit var referenceView: KeyguardHeaderMaterialView
            lateinit var referenceRoot: FrameLayout
            lateinit var fiducial: View
            lateinit var neutral: Bitmap
            lateinit var empty: Bitmap
            try {
                instrumentation.runOnMainSync {
                    referenceView = KeyguardHeaderMaterialView(activity).apply {
                        shape = KeyguardHeaderMaterialView.Shape.ORB
                        layoutParams = FrameLayout.LayoutParams(168, 168, Gravity.CENTER)
                        setScene(KeyguardMaterialScene(calibratedOrbProfile().neutralized(), false, System.nanoTime()), true)
                        setBootstrapActive(true)
                        visibility = View.INVISIBLE
                    }
                    fiducial = View(activity).apply {
                        setBackgroundColor(android.graphics.Color.MAGENTA)
                        layoutParams = FrameLayout.LayoutParams(24, 24, Gravity.TOP or Gravity.START).apply {
                            leftMargin = 24; topMargin = 24
                        }
                    }
                    referenceRoot = FrameLayout(activity).apply {
                        setBackgroundColor(background)
                        addView(referenceView)
                        addView(fiducial)
                    }
                    activity.setContentView(referenceRoot)
                }
                fun awaitReferenceCommit() {
                    val committed = CountDownLatch(1)
                    instrumentation.runOnMainSync {
                        referenceRoot.viewTreeObserver.registerFrameCommitCallback { committed.countDown() }
                        referenceRoot.invalidate()
                    }
                    assertTrue("reference frame commit was not observed", committed.await(8, TimeUnit.SECONDS))
                }
                awaitReferenceCommit()
                empty = copyMaterialView(instrumentation, referenceView)
                persistPanelEvidence(activity, "r09-empty-reference-$label", empty)
                instrumentation.runOnMainSync { referenceView.visibility = View.VISIBLE }
                assertTrue("independent neutral reference never drew", waitForBootstrap(instrumentation, referenceView))
                awaitReferenceCommit()
                val marker = IntArray(2)
                instrumentation.runOnMainSync { fiducial.getLocationOnScreen(marker) }
                val fullReference = requireNotNull(instrumentation.uiAutomation.takeScreenshot())
                try {
                    val color = fullReference.getPixel(marker[0] + 12, marker[1] + 12)
                    persistPanelEvidence(activity, "r11-neutral-reference-fiducial-$label", fullReference)
                    File(activity.filesDir, "keyguard-material-smoke/r11-neutral-fiducial-$label.txt").writeText(
                        "uptime=${SystemClock.uptimeMillis()} marker=${marker.toList()} color=$color " +
                            "screen=${fullReference.width}x${fullReference.height} expected=magenta source=UiAutomation\n")
                    assertTrue("external reference fiducial was not presented",
                        (color ushr 16 and 255) > 180 && (color ushr 8 and 255) < 100 && (color and 255) > 180)
                } finally { fullReference.recycle() }
                neutral = awaitCompositorCrop("r10-neutral-calibration-$label",
                    { copyMaterialView(instrumentation, referenceView) },
                    { name, image -> persistPanelEvidence(activity, name, image) },
                    { hasVisibleMaterial(it) && compareMaterialPixels(empty, it).meaningful() }, {})
                persistPanelEvidence(activity, "r09-neutral-reference-$label", neutral)
            } finally { instrumentation.runOnMainSync { activity.finish() } }
            val white = Bitmap.createBitmap(168, 168, Bitmap.Config.ARGB_8888).apply { eraseColor(android.graphics.Color.WHITE) }
            try {
                assertTrue("neutral reference is indistinguishable from empty $label", compareMaterialPixels(neutral, empty).meaningful())
                assertFalse("archived all-white sample accepted as neutral", compareMaterialPixels(neutral, white).nearlyEqual())
                val gate = RealReleaseGate().apply { releaseAll() }
                withOrbRetirementFixture("r09-neutral-$label", gate) { fixture ->
                    val old = fixture.awaitFirstToken(fixture.initialLease.attachment)
                    fixture.instrumentation.runOnMainSync {
                        fixture.activity.findViewById<View>(android.R.id.content).setBackgroundColor(background)
                    }
                    val full = copyPanelOrb(fixture.instrumentation, fixture.manager)
                    try {
                        persistPanelEvidence(fixture.activity, "r09-full-reference-$label", full)
                        assertTrue("full and neutral references are not distinguishable", compareMaterialPixels(full, neutral).meaningful())
                        lateinit var orb: KeyguardHeaderMaterialView
                        var priorDraws = 0
                        fixture.holdReady(old.lease.attachment)
                        fixture.instrumentation.runOnMainSync {
                            orb = requireNotNull(fixture.manager.currentRoot)
                                .findViewById(R.id.fluvi_financial_snapshot_orb)
                            priorDraws = orb.diagnostics().bootstrapDrawCount
                            val result = fixture.window.showOrUpdate(FluviFinancialCardPresenter.discreet(),
                                fixture.settings.copy(showFinancialDetails = false))
                            assertTrue(result == KeyguardCardWindow.Result.REDACTED || result == KeyguardCardWindow.Result.CONTENT_UPDATED)
                        }
                        val initialSampleAt = SystemClock.uptimeMillis()
                        val initialSample = copyPanelOrb(fixture.instrumentation, fixture.manager)
                        try { persistPanelEvidence(fixture.activity, "r10-neutral-initial-$label", initialSample) }
                        finally { initialSample.recycle() }
                        File(fixture.activity.filesDir, "keyguard-material-smoke/r10-neutral-initial-$label-time.txt")
                            .writeText("uptimeMs=$initialSampleAt boundary=before-ready-classification\n")
                        val ready = fixture.awaitReady(old.lease.attachment)
                        assertEquals(calibratedOrbProfile().neutralized().visualKey, ready.frame.lease.visualKey)
                        val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(8)
                        var drewNeutral = false
                        while (System.nanoTime() < deadline && !drewNeutral) {
                            fixture.instrumentation.runOnMainSync { drewNeutral = orb.diagnostics().bootstrapDrawCount > priorDraws }
                            if (!drewNeutral) Thread.sleep(24)
                        }
                        assertTrue("current neutral bootstrap did not draw", drewNeutral)
                        val samples = mutableListOf<Bitmap>()
                        val times = mutableListOf<Long>()
                        try {
                            repeat(6) { index ->
                                times += SystemClock.uptimeMillis()
                                val sample = copyPanelOrb(fixture.instrumentation, fixture.manager)
                                samples += sample
                                persistPanelEvidence(fixture.activity, "r09-neutral-$label-$index", sample)
                                Thread.sleep(16)
                            }
                            File(fixture.activity.filesDir, "keyguard-material-smoke/r09-neutral-$label-times.txt")
                                .writeText(times.joinToString("\n"))
                            samples.forEach { sample ->
                                assertTrue("neutral interior differs from independently rendered reference $label",
                                    compareMaterialPixels(neutral, sample).nearlyEqual())
                                assertTrue("background-only or old full pixels were accepted $label",
                                    compareMaterialPixels(sample, empty).meaningful() && compareMaterialPixels(sample, full).meaningful())
                                val corners = listOf(0 to 0, 167 to 0, 0 to 167, 167 to 167)
                                assertTrue("transparent orb surroundings differ from background $label",
                                    corners.all { (x, y) -> sample.getPixel(x, y) == empty.getPixel(x, y) })
                            }
                        } finally { samples.forEach(Bitmap::recycle) }
                        fixture.deliverReady(old.lease.attachment)
                    } finally { full.recycle() }
                }
            } finally { neutral.recycle(); empty.recycle(); white.recycle() }
        }
        // Exercise the existing held-real-receipt/stale-ticket path separately;
        // it cannot substitute for the calibrated neutral control above.
        stalePressureCannotRestoreFullContentAfterPrivacyAndSizeChanges()
    }

    private data class PassiveReferences(val standby: Bitmap, val neutral: Bitmap, val empty: Bitmap, val full: Bitmap) {
        fun recycle() { standby.recycle(); neutral.recycle(); empty.recycle(); full.recycle() }
    }

    /** Independent hardware-View references on the same white panel and
     * dimensions. No candidate crop or callback is used to create them. */
    private fun passiveReferences(): PassiveReferences {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val activity = instrumentation.startActivitySync(Intent(instrumentation.targetContext,
            KeyguardMaterialTestActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) as KeyguardMaterialTestActivity
        val size = activity.resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_orb_size)
        lateinit var root: FrameLayout
        lateinit var expected: View
        lateinit var material: KeyguardHeaderMaterialView
        try {
            instrumentation.runOnMainSync {
                val paint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG).apply {
                    shader = android.graphics.LinearGradient(0f, size.toFloat(), size.toFloat(), 0f,
                        intArrayOf(0xff657489.toInt(), 0xff8592a4.toInt(), 0xff657489.toInt()),
                        floatArrayOf(0f, .5f, 1f), android.graphics.Shader.TileMode.CLAMP)
                }
                expected = object : View(activity) {
                    override fun onDraw(canvas: Canvas) {
                        super.onDraw(canvas)
                        canvas.drawCircle(size / 2f, size / 2f, size / 2f - 2f, paint)
                    }
                }.apply { layoutParams = FrameLayout.LayoutParams(size, size, Gravity.CENTER); visibility = View.INVISIBLE }
                material = KeyguardHeaderMaterialView(activity, materialTimeSource =
                    KeyguardMaterialTimeSource { _, _ -> calibratedMaterialTime(PHASE_A) }).apply {
                    shape = KeyguardHeaderMaterialView.Shape.ORB
                    layoutParams = FrameLayout.LayoutParams(size, size, Gravity.CENTER)
                    visibility = View.INVISIBLE
                }
                root = FrameLayout(activity).apply {
                    setBackgroundColor(android.graphics.Color.WHITE)
                    addView(expected); addView(material)
                }
                activity.setContentView(root)
            }
            fun parentFrame() {
                val receipt = CountDownLatch(1)
                instrumentation.runOnMainSync {
                    root.viewTreeObserver.registerFrameCommitCallback { receipt.countDown() }
                    root.invalidate()
                }
                assertTrue("independent reference parent commit missing", receipt.await(8, TimeUnit.SECONDS))
            }
            parentFrame()
            val empty = copyMaterialView(instrumentation, expected)
            instrumentation.runOnMainSync { expected.visibility = View.VISIBLE }
            parentFrame()
            val standby = copyMaterialView(instrumentation, expected)
            instrumentation.runOnMainSync {
                expected.visibility = View.INVISIBLE
                material.setScene(KeyguardMaterialScene(calibratedOrbProfile().neutralized(), false, System.nanoTime()), true)
                material.setBootstrapActive(true)
                material.visibility = View.VISIBLE
            }
            assertTrue("neutral reference never drew", waitForBootstrap(instrumentation, material))
            parentFrame()
            val neutral = copyMaterialView(instrumentation, material)
            val profile = calibratedOrbProfile()
            val artifact = AndroidKeyguardShaderArtifactReader.load(activity, profile.effectId, profile.usesPortal)
            var before = 0
            instrumentation.runOnMainSync {
                material.setScene(KeyguardMaterialScene(profile, true, System.nanoTime()), true)
                material.setBootstrapActive(false)
                assertEquals(KeyguardHeaderMaterialView.ProgramPreparationResult.COMPILED, material.installPreparedShader(artifact))
                before = material.diagnostics().shaderDrawCount
                material.frame(System.nanoTime())
            }
            assertTrue("independent full reference did not draw", waitForShaderDraw(instrumentation, material, before))
            parentFrame()
            val full = copyMaterialView(instrumentation, material)
            persistPanelEvidence(activity, "r22-2-reference-standby", standby)
            persistPanelEvidence(activity, "r22-2-reference-neutral", neutral)
            persistPanelEvidence(activity, "r22-2-reference-empty", empty)
            persistPanelEvidence(activity, "r22-2-reference-full", full)
            assertTrue("standby must differ from empty", compareMaterialPixels(standby, empty).meaningful())
            assertTrue("full must differ from neutral", compareMaterialPixels(full, neutral).meaningful())
            return PassiveReferences(standby, neutral, empty, full)
        } finally {
            instrumentation.runOnMainSync { activity.finish() }
            instrumentation.waitForIdleSync()
        }
    }

    /** Compare every ROI pixel, including the two-pixel contour, using the
     * same predeclared channel/total tolerance as the interior comparator. */
    private fun wholeRoiDifference(expected: Bitmap, actual: Bitmap): MaterialPixelComparison {
        require(expected.width == actual.width && expected.height == actual.height)
        var max = 0; var total = 0L; var changed = 0
        for (y in 0 until expected.height) for (x in 0 until expected.width) {
            val a = expected.getPixel(x, y); val b = actual.getPixel(x, y)
            val d = maxOf(kotlin.math.abs((a shr 16 and 255) - (b shr 16 and 255)),
                kotlin.math.abs((a shr 8 and 255) - (b shr 8 and 255)),
                kotlin.math.abs((a and 255) - (b and 255)))
            max = maxOf(max, d); total += d
            if (d >= 7) changed++
        }
        return MaterialPixelComparison(changed, total, max)
    }

    private fun assertWholeRoiNear(expected: Bitmap, actual: Bitmap, label: String) {
        val difference = wholeRoiDifference(expected, actual)
        assertTrue("$label full ROI/ring differs $difference", difference.nearlyEqual())
    }

    @Test fun isolatedOpaqueOrbHasNeutralParentAtRetire() {
        val refs = passiveReferences()
        val gate = RealReleaseGate().apply { delayTickets = true }
        try {
            withOrbRetirementFixture("r22-2-held-parent", gate) { fixture ->
                val (current, ticket) = fixture.twoHeldUsesAndCurrentTicket(gate)
                assertTrue(waitForIsolatedBootstrapReplacement(fixture.instrumentation, fixture.manager))
                lateinit var root: KeyguardCardInteractionLayout
                val parentCommit = CountDownLatch(1)
                fixture.instrumentation.runOnMainSync {
                    root = requireNotNull(fixture.manager.currentRoot) as KeyguardCardInteractionLayout
                    root.viewTreeObserver.registerFrameCommitCallback { parentCommit.countDown() }
                    root.invalidate()
                }
                assertTrue("NOT REACHED: standby parent commit", parentCommit.await(8, TimeUnit.SECONDS))
                fixture.instrumentation.runOnMainSync {
                    val state = requireNotNull(root.passiveStandbyObservation())
                    assertEquals(current.lease.attachment, state.attachment)
                    assertEquals(current.lease.generation, state.generation)
                    assertTrue("NOT REACHED: exact standby never drew", state.hasDrawn)
                }
                val fullScreen = requireNotNull(fixture.instrumentation.uiAutomation.takeScreenshot())
                lateinit var bounds: Rect
                fixture.instrumentation.runOnMainSync { bounds = fixture.manager.currentOrbBounds() }
                val full = Bitmap.createBitmap(fullScreen, bounds.left, bounds.top, bounds.width(), bounds.height())
                val withheld = CountDownLatch(1)
                val active = java.util.concurrent.atomic.AtomicBoolean(true)
                val expired = java.util.concurrent.atomic.AtomicBoolean(false)
                val listener = ViewTreeObserver.OnPreDrawListener { if (active.get()) { withheld.countDown(); false } else true }
                val handler = android.os.Handler(android.os.Looper.getMainLooper())
                val watchdog = Runnable {
                    if (active.compareAndSet(true, false)) {
                        expired.set(true)
                        if (root.viewTreeObserver.isAlive) root.viewTreeObserver.removeOnPreDrawListener(listener)
                        root.invalidate()
                    }
                }
                try {
                    persistPanelEvidence(fixture.activity, "r22-2-held-full", fullScreen)
                    assertTrue("independent FULL reference mismatch", compareMaterialPixels(refs.full, full).nearlyEqual())
                    fixture.instrumentation.runOnMainSync {
                        root.viewTreeObserver.addOnPreDrawListener(listener)
                        root.invalidate()
                        handler.postDelayed(watchdog, 15_000)
                    }
                    assertTrue("NOT REACHED: subsequent parent traversal was not held", withheld.await(8, TimeUnit.SECONDS))
                    val redactionAt = SystemClock.uptimeMillis()
                    fixture.instrumentation.runOnMainSync {
                        val result = fixture.window.showOrUpdate(FluviFinancialCardPresenter.discreet(),
                            fixture.settings.copy(showFinancialDetails = false))
                        assertTrue(result == KeyguardCardWindow.Result.REDACTED || result == KeyguardCardWindow.Result.CONTENT_UPDATED)
                    }
                    val clear = gate.awaitRetirement(current.lease, "final-clear-committed")
                    assertEquals("retirement must be for the captured child", System.identityHashCode(ticket.child), clear.child)
                    assertFalse("NOT REACHED: held traversal watchdog expired", expired.get())
                    val before = SystemClock.uptimeMillis()
                    val afterScreen = requireNotNull(fixture.instrumentation.uiAutomation.takeScreenshot())
                    val after = SystemClock.uptimeMillis()
                    try {
                        val afterCrop = Bitmap.createBitmap(afterScreen, bounds.left, bounds.top, bounds.width(), bounds.height())
                        try {
                            persistPanelEvidence(fixture.activity, "r22-2-held-retire-full", afterScreen)
                            persistPanelEvidence(fixture.activity, "r22-2-held-retire-crop", afterCrop)
                            val directory = File(fixture.activity.filesDir, "keyguard-material-smoke")
                            File(directory, "r22-2-held-boundaries.txt").writeText(
                                "redaction=$redactionAt clearCommit=${clear.at} screenshot=$before/$after root=${System.identityHashCode(root)} " +
                                    "attach=${current.lease.attachment} generation=${current.lease.generation} child=${clear.child} bounds=$bounds held=${active.get()} expired=${expired.get()}\n")
                            assertTrue("NOT REACHED: draw hold ended before sample", active.get() && !expired.get())
                            assertWholeRoiNear(refs.standby, afterCrop, "exposed standby")
                            assertTrue("exposed parent must not be old FULL", compareMaterialPixels(full, afterCrop).meaningful())
                            assertTrue("exposed parent must not be empty", compareMaterialPixels(refs.empty, afterCrop).meaningful())
                            assertEquals(fullScreen.width, afterScreen.width); assertEquals(fullScreen.height, afterScreen.height)
                            var outsideChanges = 0
                            for (y in 0 until fullScreen.height) for (x in 0 until fullScreen.width) {
                                if (!bounds.contains(x, y) && fullScreen.getPixel(x, y) != afterScreen.getPixel(x, y)) outsideChanges++
                            }
                            assertEquals("same-frame outside ROI changed", 0, outsideChanges)
                        } finally { afterCrop.recycle() }
                    } finally { afterScreen.recycle() }
                } finally {
                    fixture.instrumentation.runOnMainSync {
                        active.set(false)
                        handler.removeCallbacks(watchdog)
                        if (root.viewTreeObserver.isAlive) root.viewTreeObserver.removeOnPreDrawListener(listener)
                        root.invalidate()
                    }
                    full.recycle(); fullScreen.recycle()
                }
                fixture.ownership.assertBoundedSingleRenderer()
            }
        } finally { refs.recycle() }
    }

    @Test fun isolatedStandbyPreservesAuthorizedComposition() {
        for (background in listOf(android.graphics.Color.WHITE, android.graphics.Color.BLACK)) {
            lateinit var translucentReference: Bitmap
            val referenceGate = RealReleaseGate().apply { releaseAll() }
            withOrbRetirementFixture("r22-2-translucent-reference-$background", referenceGate,
                initialProfile = calibratedOrbProfile().copy(opacity = .5f)) { reference ->
                val backgroundCommit = CountDownLatch(1)
                reference.instrumentation.runOnMainSync {
                    val content = reference.activity.findViewById<View>(android.R.id.content)
                    content.viewTreeObserver.registerFrameCommitCallback { backgroundCommit.countDown() }
                    content.setBackgroundColor(background)
                    content.invalidate()
                    val referenceRoot = requireNotNull(reference.manager.currentRoot) as KeyguardCardInteractionLayout
                    assertEquals("fresh translucent route must not arm standby", null, referenceRoot.passiveStandbyObservation())
                }
                assertTrue("NOT REACHED: reference background commit", backgroundCommit.await(8, TimeUnit.SECONDS))
                val captured = reference.capture(PHASE_A, "translucent-reference", ::hasVisibleMaterial)
                translucentReference = captured.bitmap
            }
            val gate = RealReleaseGate().apply { releaseAll() }
            try { withOrbRetirementFixture("r22-2-composition-$background", gate) { fixture ->
                val token = fixture.awaitFirstToken(fixture.initialLease.attachment)
                lateinit var root: KeyguardCardInteractionLayout
                lateinit var orb: View
                var childCount = 0
                var windowAdds = 0
                fun parentFrame() {
                    val done = CountDownLatch(1)
                    fixture.instrumentation.runOnMainSync {
                        root.viewTreeObserver.registerFrameCommitCallback { done.countDown() }
                        root.invalidate()
                    }
                    assertTrue("NOT REACHED: parent commit", done.await(8, TimeUnit.SECONDS))
                }
                val backgroundCommit = CountDownLatch(1)
                fixture.instrumentation.runOnMainSync {
                    val content = fixture.activity.findViewById<View>(android.R.id.content)
                    content.viewTreeObserver.registerFrameCommitCallback { backgroundCommit.countDown() }
                    content.setBackgroundColor(background)
                    content.invalidate()
                    root = requireNotNull(fixture.manager.currentRoot) as KeyguardCardInteractionLayout
                    orb = root.findViewById(R.id.fluvi_financial_snapshot_orb)
                    childCount = root.childCount
                    windowAdds = fixture.manager.adds
                }
                assertTrue("NOT REACHED: candidate background commit", backgroundCommit.await(8, TimeUnit.SECONDS))
                parentFrame()
                fixture.instrumentation.runOnMainSync {
                    val state = requireNotNull(root.passiveStandbyObservation())
                    assertEquals(token.lease.attachment, state.attachment)
                    assertEquals(token.lease.generation, state.generation)
                    assertTrue("production standby was not drawn", state.hasDrawn)
                    root.clearPassiveStandby()
                    orb.alpha = .5f
                    assertEquals("GEOMETRY_INELIGIBLE", root.configurePassiveStandby(orb, token.lease.attachment,
                        token.lease.generation, token.lease.width, token.lease.height, false))
                    orb.alpha = 1f
                    root.scaleX = .9f
                    assertEquals("GEOMETRY_INELIGIBLE", root.configurePassiveStandby(orb, token.lease.attachment,
                        token.lease.generation, token.lease.width, token.lease.height, false))
                    root.scaleX = 1f
                    assertEquals("standby must not add a View", childCount, root.childCount)
                    assertEquals("standby must not add a Window", windowAdds, fixture.manager.adds)
                }
                parentFrame()
                val phases = listOf(PHASE_A, PHASE_C, PHASE_B, PHASE_A)
                val without = mutableListOf<OrbRetirementCapture>()
                val with = mutableListOf<OrbRetirementCapture>()
                try {
                    phases.forEachIndexed { index, phase ->
                        without += fixture.capture(phase, "without-standby-$index", ::hasVisibleMaterial)
                    }
                    assertTrue(compareMaterialPixels(without[0].bitmap, without[1].bitmap).nearlyEqual())
                    assertTrue(compareMaterialPixels(without[0].bitmap, without[2].bitmap).meaningful())
                    assertTrue(compareMaterialPixels(without[0].bitmap, without[3].bitmap).nearlyEqual())
                    fixture.instrumentation.runOnMainSync {
                        assertEquals("ELIGIBLE", root.configurePassiveStandby(orb, token.lease.attachment,
                            token.lease.generation, token.lease.width, token.lease.height, false))
                    }
                    parentFrame()
                    phases.forEachIndexed { index, phase ->
                        with += fixture.capture(phase, "with-standby-$index") {
                            compareMaterialPixels(without[index].bitmap, it).nearlyEqual()
                        }
                        assertWholeRoiNear(without[index].bitmap, with[index].bitmap,
                            "opaque FULL phase $index with/without standby")
                    }
                    assertTrue(compareMaterialPixels(with[0].bitmap, with[1].bitmap).nearlyEqual())
                    assertTrue(compareMaterialPixels(with[0].bitmap, with[2].bitmap).meaningful())
                    assertTrue(compareMaterialPixels(with[0].bitmap, with[3].bitmap).nearlyEqual())
                } finally {
                    without.forEach { it.bitmap.recycle() }
                    with.forEach { it.bitmap.recycle() }
                }
                // A physical short tap follows the same original View input
                // route with the passive parent present; it remains consumed.
                fixture.instrumentation.runOnMainSync {
                    val now = SystemClock.uptimeMillis()
                    val down = android.view.MotionEvent.obtain(now, now, android.view.MotionEvent.ACTION_DOWN,
                        root.width / 2f, root.height / 2f, 0)
                    val up = android.view.MotionEvent.obtain(now, now + 1, android.view.MotionEvent.ACTION_UP,
                        root.width / 2f, root.height / 2f, 0)
                    try { assertTrue(root.dispatchTouchEvent(down)); assertTrue(root.dispatchTouchEvent(up)) }
                    finally { down.recycle(); up.recycle() }
                    assertTrue("standby changed the ORB tap route", fixture.interactionEvents.contains("KG|ORB_TAP"))
                    fixture.window.updateMaterial(calibratedOrbProfile().copy(opacity = .5f), fixture.settings)
                    assertEquals("nonopaque blend must disarm standby immediately", null, root.passiveStandbyObservation())
                }
                parentFrame()
                val translucentToken = fixture.awaitReplacementToken(token)
                val translucent = fixture.capture(PHASE_A, "translucent-guard-off") {
                    compareMaterialPixels(translucentReference, it).nearlyEqual()
                }
                try {
                    assertWholeRoiNear(translucentReference, translucent.bitmap,
                        "translucent after guarded FULL versus independently unguarded route")
                    fixture.instrumentation.runOnMainSync {
                        assertEquals("translucent replacement must remain guard-free", null, root.passiveStandbyObservation())
                        root.clearPassiveStandby()
                    }
                    parentFrame()
                    val again = fixture.capture(PHASE_A, "translucent-explicit-clear") {
                        compareMaterialPixels(translucent.bitmap, it).nearlyEqual()
                    }
                    try { assertWholeRoiNear(translucent.bitmap, again.bitmap, "translucent guard-off output") }
                    finally { again.bitmap.recycle() }
                } finally { translucent.bitmap.recycle() }
                fixture.instrumentation.runOnMainSync {
                    fixture.window.updateMaterial(calibratedOrbProfile(), fixture.settings)
                    assertEquals("return crossfade must begin without standby", null, root.passiveStandbyObservation())
                }
                val returned = fixture.awaitReplacementToken(translucentToken)
                val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(8)
                var qualified = false
                while (!qualified && System.nanoTime() < deadline) {
                    fixture.instrumentation.runOnMainSync {
                        qualified = root.passiveStandbyObservation()?.let {
                            it.attachment == returned.lease.attachment && it.generation == returned.lease.generation
                        } == true
                    }
                    if (!qualified) Thread.sleep(24)
                }
                assertTrue("opaque replacement did not requalify its own standby", qualified)
                parentFrame()
                lateinit var terminalBounds: Rect
                fixture.instrumentation.runOnMainSync {
                    terminalBounds = fixture.manager.currentOrbBounds()
                    fixture.window.hide()
                    assertEquals("terminal hide must clear standby", null, root.passiveStandbyObservation())
                    assertEquals("OWNER_UNAVAILABLE", root.configurePassiveStandby(orb, token.lease.attachment,
                        token.lease.generation, token.lease.width, token.lease.height, false))
                    assertEquals("terminal hide must not add another Window", windowAdds, fixture.manager.adds)
                }
                fixture.assertNormalHideOrder(returned.lease)
                val terminalScreen = requireNotNull(fixture.instrumentation.uiAutomation.takeScreenshot())
                try {
                    val terminal = Bitmap.createBitmap(terminalScreen, terminalBounds.left, terminalBounds.top,
                        terminalBounds.width(), terminalBounds.height())
                    val underlay = Bitmap.createBitmap(terminal.width, terminal.height, Bitmap.Config.ARGB_8888)
                    try {
                        underlay.eraseColor(background)
                        persistPanelEvidence(fixture.activity, "r22-2-terminal-hide-$background-screen", terminalScreen)
                        persistPanelEvidence(fixture.activity, "r22-2-terminal-hide-$background-crop", terminal)
                        assertWholeRoiNear(underlay, terminal, "terminal hide must expose only actual underlay")
                    } finally { underlay.recycle(); terminal.recycle() }
                } finally { terminalScreen.recycle() }
                fixture.ownership.assertBoundedSingleRenderer()
            } } finally { translucentReference.recycle() }
        }
    }

    @Test fun stalePressureCannotSwitchReplacement() {
        val gate = RealReleaseGate().apply { delayTickets = true }
        withOrbRetirementFixture("r08-stale-ticket", gate) { fixture ->
            fun show(): Pair<Long, Long> {
                val request = fixture.prepareFirst(PHASE_A)
                var attachment = 0L
                fixture.instrumentation.runOnMainSync {
                    assertEquals(KeyguardCardWindow.Result.ATTACHED,
                        fixture.window.showOrUpdate(FluviFinancialCardPresenter.loading(), fixture.settings))
                    attachment = fixture.window.currentAttachGeneration
                }
                return request to attachment
            }
            fun hide() = fixture.instrumentation.runOnMainSync { assertTrue(fixture.window.hide()) }
            fun route(): String {
                var value = ""
                fixture.instrumentation.runOnMainSync { value = requireNotNull(fixture.window.materialDiagnostics()).effectiveRoute }
                return value
            }
            val a = fixture.awaitFirstToken(fixture.initialLease.attachment)
            hide()
            gate.awaitActualReceipt(KeyguardOrbBufferProducerFrame(a.lease, a.slotId, a.useGeneration,
                0L, calibratedMaterialTime(PHASE_A)))
            val (bRequest, _) = show()
            val b = fixture.submitted(bRequest)
            hide()
            gate.awaitActualReceipt(b)
            val (cRequest, cAttachment) = show()
            val c = fixture.submitted(cRequest)
            val oldTicket = gate.awaitTicket(cAttachment)
            assertEquals(c.lease, oldTicket.lease)
            hide()
            val (_, dAttachment) = show()
            val replacement = gate.awaitTicket(dAttachment)
            assertEquals(KeyguardOrbPressureReason.ALL_OLD_UNRELEASED, replacement.reason)
            fixture.instrumentation.runOnMainSync { gate.deliverTicket(cAttachment) }
            assertEquals("late A ticket must not switch or reveal replacement", "ISOLATED", route())
            fixture.instrumentation.runOnMainSync {
                assertTrue(fixture.window.isAttached)
                assertEquals(dAttachment, fixture.window.currentAttachGeneration)
                gate.deliverTicket(dAttachment)
            }
            val end = System.nanoTime() + TimeUnit.SECONDS.toNanos(8)
            while (route() != "PRESSURE_VIEW" && System.nanoTime() < end) Thread.sleep(24)
            assertEquals("the current ticket should be accepted independently", "PRESSURE_VIEW", route())
            var before: KeyguardMaterialDiagnostics? = null
            var after: KeyguardMaterialDiagnostics? = null
            fixture.instrumentation.runOnMainSync { before = fixture.window.materialDiagnostics() }
            Thread.sleep(600)
            fixture.instrumentation.runOnMainSync { after = fixture.window.materialDiagnostics() }
            assertTrue("replacement without any first isolated frame must draw a live View",
                requireNotNull(after).attachmentShaderTraversals - requireNotNull(before).attachmentShaderTraversals >= 3)
            assertTrue("replacement without any first isolated frame must advance phase",
                requireNotNull(after).attachmentPhaseAdvances - requireNotNull(before).attachmentPhaseAdvances >= 2)
            assertTrue("the original real receipts must still be withheld", gate.heldCount() >= 2)
            fixture.ownership.assertBoundedSingleRenderer()
        }
    }

    @Test fun stalePressureCannotRestoreFullContentAfterPrivacyAndSizeChanges() {
        val refs = passiveReferences()
        val gate = RealReleaseGate().apply { delayTickets = true }
        try { withOrbRetirementFixture("r08-stale-privacy-size", gate) { fixture ->
            fun show(): KeyguardOrbBufferProducerFrame {
                val request = fixture.prepareFirst(PHASE_A)
                fixture.instrumentation.runOnMainSync {
                    assertEquals(KeyguardCardWindow.Result.ATTACHED,
                        fixture.window.showOrUpdate(FluviFinancialCardPresenter.loading(), fixture.settings))
                }
                return fixture.submitted(request)
            }
            fun hide() = fixture.instrumentation.runOnMainSync { assertTrue(fixture.window.hide()) }
            val a = fixture.awaitFirstToken(fixture.initialLease.attachment)
            hide()
            gate.awaitActualReceipt(KeyguardOrbBufferProducerFrame(a.lease, a.slotId, a.useGeneration,
                0L, calibratedMaterialTime(PHASE_A)))
            val b = show()
            hide()
            gate.awaitActualReceipt(b)
            val c = show()
            val fullTicket = gate.awaitTicket(c.lease.attachment)
            assertTrue(waitForIsolatedBootstrapReplacement(fixture.instrumentation, fixture.manager))
            val fullCrop = copyPanelOrb(fixture.instrumentation, fixture.manager)
            val parentEvents = java.util.concurrent.CopyOnWriteArrayList<String>()
            var observedOrb: View? = null
            var parentListener: ViewTreeObserver.OnDrawListener? = null
            try {
                persistPanelEvidence(fixture.activity, "r08-full-before-redaction", fullCrop)
                lateinit var root: View
                fixture.instrumentation.runOnMainSync {
                    root = requireNotNull(fixture.manager.currentRoot)
                    val orb = root.findViewById<View>(R.id.fluvi_financial_snapshot_orb)
                    observedOrb = orb
                    val drawSequence = AtomicInteger()
                    val epoch = SystemClock.uptimeMillis()
                    val listener = ViewTreeObserver.OnDrawListener {
                        val draw = drawSequence.incrementAndGet()
                        if (draw <= 16) parentEvents += "parentDraw epoch=$epoch seq=$draw uptimeMs=${SystemClock.uptimeMillis()} visibility=${orb.visibility} size=${orb.width}x${orb.height}"
                    }
                    parentListener = listener
                    orb.viewTreeObserver.addOnDrawListener(listener)
                    // Register before the redaction can invalidate or draw;
                    // receipt is not a physical presentation timestamp.
                    runCatching { root.viewTreeObserver.registerFrameCommitCallback {
                        parentEvents += "parentFrameCommitReceipt epoch=$epoch drawSeq=${drawSequence.get()} sameRoot=${root === fixture.manager.currentRoot} attachment=${c.lease.attachment} generation=${c.lease.generation} uptimeMs=${SystemClock.uptimeMillis()}"
                    } }.onFailure { parentEvents += "parentCommitRegistrationFailed ${it.javaClass.simpleName}" }
                    parentEvents += "redactionRequest uptimeMs=$epoch root=${System.identityHashCode(root)} attachment=${c.lease.attachment} generation=${c.lease.generation} leaseSize=${c.lease.width}x${c.lease.height}"
                    val result = fixture.window.showOrUpdate(FluviFinancialCardPresenter.discreet(),
                        fixture.settings.copy(showFinancialDetails = false))
                    assertTrue(result == KeyguardCardWindow.Result.REDACTED || result == KeyguardCardWindow.Result.CONTENT_UPDATED)
                }
                val neutralTicket = gate.awaitTicket(c.lease.attachment, fullTicket.lease.generation)
                assertEquals(calibratedOrbProfile().neutralized().visualKey, neutralTicket.lease.visualKey)
                fun safeNeutral(candidate: Bitmap): Boolean {
                    if (!hasVisibleMaterial(candidate)) return false
                    val reference = Bitmap.createScaledBitmap(fullCrop, candidate.width, candidate.height, true)
                    return try { compareMaterialPixels(reference, candidate).meaningful() }
                    finally { if (reference !== fullCrop) reference.recycle() }
                }
                fun recordSafeStrip(label: String) {
                    val samples = mutableListOf<Bitmap>()
                    val times = mutableListOf<String>()
                    val categories = mutableListOf<String>()
                    try {
                        repeat(6) { index ->
                            var bounds: Rect? = null
                            fixture.instrumentation.runOnMainSync { bounds = fixture.manager.currentOrbBounds() }
                            val b = checkNotNull(bounds)
                            val before = SystemClock.uptimeMillis()
                            val screen = requireNotNull(fixture.instrumentation.uiAutomation.takeScreenshot())
                            val after = SystemClock.uptimeMillis()
                            try {
                                assertTrue("orb bounds outside screenshot: $b", b.left >= 0 && b.top >= 0 &&
                                    b.right <= screen.width && b.bottom <= screen.height && b.width() > 0 && b.height() > 0)
                                val sample = Bitmap.createBitmap(screen, b.left, b.top, b.width(), b.height())
                                samples += sample
                                persistPanelEvidence(fixture.activity, "$label-full-$index", screen)
                                persistPanelEvidence(fixture.activity, "$label-$index", sample)
                                val reference = Bitmap.createScaledBitmap(fullCrop, sample.width, sample.height, true)
                                val comparison = try { compareMaterialPixels(reference, sample) }
                                    finally { if (reference !== fullCrop) reference.recycle() }
                                val centerY = (b.top + b.height() / 2).coerceIn(0, screen.height - 1)
                                val leftX = (b.left - 4).coerceIn(0, screen.width - 1)
                                val rightX = (b.right + 4).coerceIn(0, screen.width - 1)
                                var whitePixels = 0
                                for (y in 0 until sample.height) for (x in 0 until sample.width) {
                                    if (sample.getPixel(x, y) and 0x00ffffff == 0x00ffffff) whitePixels += 1
                                }
                                fun scaled(source: Bitmap): Bitmap =
                                    if (source.width == sample.width && source.height == sample.height) source
                                    else Bitmap.createScaledBitmap(source, sample.width, sample.height, true)
                                val standby = scaled(refs.standby)
                                val neutral = scaled(refs.neutral)
                                val empty = scaled(refs.empty)
                                val standbyDelta = wholeRoiDifference(standby, sample)
                                val neutralDelta = wholeRoiDifference(neutral, sample)
                                val emptyDelta = wholeRoiDifference(empty, sample)
                                val category = when {
                                    comparison.nearlyEqual() -> "OLD_FULL"
                                    standbyDelta.nearlyEqual() -> "SAFE_STANDBY"
                                    neutralDelta.nearlyEqual() -> "SAFE_NEUTRAL"
                                    emptyDelta.nearlyEqual() -> "BLANK"
                                    else -> "UNCLASSIFIED"
                                }
                                if (standby !== refs.standby) standby.recycle()
                                if (neutral !== refs.neutral) neutral.recycle()
                                if (empty !== refs.empty) empty.recycle()
                                categories += category
                                times += "sample=$index before=$before after=$after bounds=$b size=${sample.width}x${sample.height} " +
                                    "category=$category whitePixels=$whitePixels oldFull=$comparison standby=$standbyDelta neutral=$neutralDelta empty=$emptyDelta " +
                                    "reference=r22-2-reference-standby,r22-2-reference-neutral,r22-2-reference-empty fiducials=$leftX,$centerY:${screen.getPixel(leftX, centerY)};" +
                                    "$rightX,$centerY:${screen.getPixel(rightX, centerY)} expected=safe-neutral"
                            } finally { screen.recycle() }
                            Thread.sleep(16)
                        }
                        val directory = File(fixture.activity.filesDir, "keyguard-material-smoke")
                        File(directory, "$label-times.txt").writeText(times.joinToString("\n", postfix = "\n"))
                        File(directory, "$label-boundaries.txt").writeText(
                            (parentEvents + gate.retirementSnapshot().map { "retirement $it" } +
                                fixture.ownership.snapshot().filter { it.lease == c.lease }.map { "ownership $it" })
                                .joinToString("\n", postfix = "\n"))
                        assertTrue("$label contained a blank or prior full-detail orb", samples.all(::safeNeutral))
                        assertTrue("$label was not independently classified as safe: $categories",
                            categories.all { it == "SAFE_STANDBY" || it == "SAFE_NEUTRAL" })
                    } finally { samples.forEach(Bitmap::recycle) }
                }
                recordSafeStrip("r08-neutral-transition")
                val neutralCrop = awaitCompositorCrop("r08-neutral-before-stale-ticket",
                    capture = { copyPanelOrb(fixture.instrumentation, fixture.manager) },
                    persist = { label, bitmap -> persistPanelEvidence(fixture.activity, label, bitmap) },
                    accepts = ::safeNeutral,
                    onTimeout = { persistPanelCompositorTimeout(fixture.activity, fixture.instrumentation,
                        "r08-neutral-timeout", fixture.manager, c) })
                try {
                    fixture.instrumentation.runOnMainSync {
                        gate.deliverTicket(fullTicket)
                        assertTrue(root === fixture.manager.currentRoot)
                        val orb = root.findViewById<KeyguardHeaderMaterialView>(R.id.fluvi_financial_snapshot_orb)
                        assertTrue("old full ticket must not hide neutral bootstrap", orb.isBootstrapActive())
                        assertEquals(View.VISIBLE, orb.visibility)
                        assertEquals("ISOLATED", requireNotNull(fixture.window.materialDiagnostics()).effectiveRoute)
                        orb.layout(orb.left, orb.top, orb.right + 4, orb.bottom + 4)
                    }
                    val resizedTicket = gate.awaitTicket(c.lease.attachment, neutralTicket.lease.generation)
                    assertEquals(neutralTicket.lease.visualKey, resizedTicket.lease.visualKey)
                    assertTrue(resizedTicket.lease.width != neutralTicket.lease.width ||
                        resizedTicket.lease.height != neutralTicket.lease.height)
                    fixture.instrumentation.runOnMainSync {
                        gate.deliverTicket(neutralTicket)
                        val orb = root.findViewById<KeyguardHeaderMaterialView>(R.id.fluvi_financial_snapshot_orb)
                        assertTrue("old size ticket must not hide the permitted bootstrap", orb.isBootstrapActive())
                        assertEquals("ISOLATED", requireNotNull(fixture.window.materialDiagnostics()).effectiveRoute)
                        gate.deliverTicket(resizedTicket)
                    }
                    val end = System.nanoTime() + TimeUnit.SECONDS.toNanos(8)
                    var route = ""
                    while (System.nanoTime() < end) {
                        fixture.instrumentation.runOnMainSync { route = requireNotNull(fixture.window.materialDiagnostics()).effectiveRoute }
                        if (route == "PRESSURE_VIEW") break
                        Thread.sleep(24)
                    }
                    assertEquals("PRESSURE_VIEW", route)
                    recordSafeStrip("r08-neutral-recovery-transition")
                    val after = awaitCompositorCrop("r08-neutral-recovery",
                        capture = { copyPanelOrb(fixture.instrumentation, fixture.manager) },
                        persist = { label, bitmap -> persistPanelEvidence(fixture.activity, label, bitmap) },
                        accepts = ::safeNeutral,
                        onTimeout = { persistPanelCompositorTimeout(fixture.activity, fixture.instrumentation,
                            "r08-neutral-recovery-timeout", fixture.manager, c) })
                    after.recycle()
                    assertTrue("old receipts were delivered during privacy test", gate.heldCount() >= 2)
                } finally { neutralCrop.recycle() }
            } finally {
                fixture.instrumentation.runOnMainSync {
                    val orb = observedOrb
                    val listener = parentListener
                    if (orb != null && listener != null && orb.viewTreeObserver.isAlive) {
                        orb.viewTreeObserver.removeOnDrawListener(listener)
                    }
                }
                fullCrop.recycle()
            }
            fixture.ownership.assertBoundedSingleRenderer()
        } } finally { refs.recycle() }
    }

    @Test fun restoredCapacityCancelsUnclaimedPressureTicket() {
        val gate = RealReleaseGate().apply { delayTickets = true }
        withOrbRetirementFixture("r08-ticket-cancel-capacity", gate) { fixture ->
            val (current, ticket) = fixture.twoHeldUsesAndCurrentTicket(gate)
            gate.releaseAll()
            val request = fixture.prepareFirst(PHASE_B)
            val resumed = fixture.submitted(request)
            assertEquals(current.lease, resumed.lease)
            fixture.ownership.awaitUse("steady-submitted", resumed)
            fixture.instrumentation.runOnMainSync {
                gate.deliverTicket(ticket)
                assertTrue(fixture.window.isAttached)
                assertEquals("release and fresh output must cancel an unclaimed offer",
                    "ISOLATED", requireNotNull(fixture.window.materialDiagnostics()).effectiveRoute)
                assertEquals(current.lease.attachment, fixture.window.currentAttachGeneration)
            }
            fixture.ownership.assertBoundedSingleRenderer()
        }
    }

    @Test fun disposedWindowCannotBeRevivedByDelayedPressureTicket() {
        val gate = RealReleaseGate().apply { delayTickets = true }
        withOrbRetirementFixture("r08-ticket-dispose", gate) { fixture ->
            val (_, ticket) = fixture.twoHeldUsesAndCurrentTicket(gate)
            fixture.instrumentation.runOnMainSync {
                fixture.window.dispose()
                gate.deliverTicket(ticket)
                assertFalse("old pressure ticket revived a disposed window", fixture.window.isAttached)
                assertEquals(null, fixture.manager.currentRoot)
            }
            assertTrue("the test must still hold actual old receipts", gate.heldCount() >= 2)
            fixture.ownership.assertBoundedSingleRenderer()
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

    /** The root has already drawn its bootstrap and owns a real surface. A
     * subsequent pre-draw is then withheld without blocking Main; no steady
     * publication may stand in for the exact first buffer being sampled. */
    @Test fun isolatedOrbFirstDirectAppearsWhileNextRootDrawIsWithheld() {
        assumeTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val activity = instrumentation.startActivitySync(
            Intent(instrumentation.targetContext, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        val holdFirst = java.util.concurrent.atomic.AtomicBoolean(false)
        val firstEntered = CountDownLatch(1)
        val releaseFirst = CountDownLatch(1)
        val holdSteady = java.util.concurrent.atomic.AtomicBoolean(false)
        val steadyEntered = CountDownLatch(1)
        val releaseSteady = CountDownLatch(1)
        val targetAttach = java.util.concurrent.atomic.AtomicLong(0L)
        val withheld = CountDownLatch(1)
        val submissions = SubmittedFrameTracker()
        val samples = CalibratedProducerSamples()
        val controlled = ControlledOrbTimeSource(calibratedMaterialTime(PHASE_A))
        val firstIdentities = java.util.concurrent.CopyOnWriteArrayList<KeyguardOrbFirstPublicationToken>()
        val commits = java.util.concurrent.CopyOnWriteArrayList<KeyguardOrbFirstPublicationToken>()
        val firstCommit = CountDownLatch(1)
        val barrier = KeyguardOrbRenderBarrier { lease ->
            if (lease.attachment > 0 && lease.attachment == targetAttach.get() &&
                holdFirst.compareAndSet(true, false)
            ) {
                firstEntered.countDown()
                check(releaseFirst.await(8, TimeUnit.SECONDS)) { "first render gate timed out" }
            }
        }
        KeyguardOrbBufferRendererTestHooks.materialTimeSource = controlled
        KeyguardOrbBufferRendererTestHooks.publicationObserver = submissions
        KeyguardOrbBufferRendererTestHooks.frameObserver = samples
        KeyguardOrbBufferRendererTestHooks.steadyPublicationBarrier = KeyguardOrbSteadyPublicationBarrier { frame ->
            if (frame.lease.attachment == targetAttach.get() && holdSteady.compareAndSet(true, false)) {
                steadyEntered.countDown()
                check(releaseSteady.await(8, TimeUnit.SECONDS)) { "steady publication gate timed out" }
            }
        }
        KeyguardOrbBufferRendererTestHooks.firstPublicationHook = object : KeyguardOrbFirstPublicationTestHook {
            override fun afterSubmitted(token: KeyguardOrbFirstPublicationToken) { firstIdentities += token }
            override fun dispatchCommit(token: KeyguardOrbFirstPublicationToken, receivedAtUptimeMs: Long, deliver: () -> Unit) {
                commits += token
                if (token.lease.attachment == targetAttach.get()) firstCommit.countDown()
                deliver()
            }
        }
        lateinit var window: KeyguardCardWindow
        lateinit var manager: TestPanelWindowManager
        var createdWindow: KeyguardCardWindow? = null
        var reference: Bitmap? = null
        var bootstrap: Bitmap? = null
        var gatedRoot: View? = null
        var gate: ViewTreeObserver.OnPreDrawListener? = null
        val settings = KeyguardCardSettings(requested = true, showFinancialDetails = true,
            presentationMode = KeyguardCardPresentationMode.ORB, animationMode = KeyguardCardAnimationMode.ORB_ONLY,
            orbPosition = KeyguardCardOrbPosition(.5f, .5f))
        try {
            submissions.expect(1L, PHASE_A)
            controlled.submit(1L, calibratedMaterialTime(PHASE_A))
            instrumentation.runOnMainSync {
                manager = TestPanelWindowManager(activity)
                window = KeyguardCardWindow(serviceContext = activity, onOpen = {}, onToggle = {},
                    onInteractionStarted = {}, onPositionCommitted = { _, _, _, _ -> },
                    onInteractionDiagnostic = { _, _ -> }, manager = manager, isolatedOrbRenderBarrier = barrier)
                createdWindow = window
                window.prepareRetainedView(settings, calibratedOrbProfile())
                assertEquals(KeyguardCardWindow.Result.ATTACHED,
                    window.showOrUpdate(FluviFinancialCardPresenter.loading(), settings))
            }
            submissions.await(1L)
            assertTrue("positive control did not replace bootstrap", waitForIsolatedBootstrapReplacement(instrumentation, manager))
            assertTrue("positive control bounds missing", waitForPanelOrbScreenBounds(instrumentation, manager))
            // Calibrate both controls from separately requested producer
            // frames on the first attachment. A merely nonempty screenshot
            // can still be the bootstrap or a different phase (R09).
            samples.expect(3L, 1L)
            submissions.expect(3L, PHASE_B, 1L)
            controlled.submit(3L, calibratedMaterialTime(PHASE_B))
            val producerB = samples.await(3L)
            submissions.await(3L)
            val expectedB = Bitmap.createBitmap(producerB.pixels, producerB.frame.lease.width,
                producerB.frame.lease.height, Bitmap.Config.ARGB_8888)
            try {
                val compositorB = awaitCompositorCrop("r10-first-reference-b", { copyPanelOrb(instrumentation, manager) },
                    { label, bitmap -> persistPanelEvidence(activity, label, bitmap) },
                    { compareMaterialPixels(expectedB, it).nearlyEqual() }, {})
                try {
                    samples.expect(4L, 1L)
                    submissions.expect(4L, PHASE_A, 1L)
                    controlled.submit(4L, calibratedMaterialTime(PHASE_A))
                    val producerA = samples.await(4L)
                    submissions.await(4L)
                    assertTrue("independent producer A/B controls must differ", compareProducerPixels(producerA, producerB).meaningful())
                    val expectedA = Bitmap.createBitmap(producerA.pixels, producerA.frame.lease.width,
                        producerA.frame.lease.height, Bitmap.Config.ARGB_8888)
                    try {
                        persistPanelEvidence(activity, "r10-first-reference-a-producer", expectedA)
                        reference = awaitCompositorCrop("r10-first-reference-a-compositor", { copyPanelOrb(instrumentation, manager) },
                            { label, bitmap -> persistPanelEvidence(activity, label, bitmap) },
                            { compareMaterialPixels(expectedA, it).nearlyEqual() }, {})
                        assertTrue("A/B compositor references must differ",
                            compareMaterialPixels(requireNotNull(reference), compositorB).meaningful())
                    } finally { expectedA.recycle() }
                } finally { compositorB.recycle() }
            } finally { expectedB.recycle() }

            var bootstrapCountBefore = 0
            instrumentation.runOnMainSync {
                assertTrue(window.hide())
                targetAttach.set(window.currentAttachGeneration + 1L)
                holdFirst.set(true)
                holdSteady.set(true)
                submissions.expect(2L, PHASE_A, targetAttach.get())
                samples.expect(2L, targetAttach.get())
                controlled.submit(2L, calibratedMaterialTime(PHASE_A))
                assertEquals(KeyguardCardWindow.Result.ATTACHED,
                    window.showOrUpdate(FluviFinancialCardPresenter.loading(), settings))
                assertEquals("fixture gated the wrong attachment", targetAttach.get(), window.currentAttachGeneration)
                val root = requireNotNull(manager.currentRoot)
                gatedRoot = root
                bootstrapCountBefore = root.findViewById<KeyguardHeaderMaterialView>(R.id.fluvi_financial_snapshot_orb)
                    .diagnostics().bootstrapDrawCount
            }
            assertTrue("attached first render did not reach the real Worker barrier", firstEntered.await(8, TimeUnit.SECONDS))
            assertTrue("withheld fixture never acquired valid panel bounds", waitForPanelOrbScreenBounds(instrumentation, manager))
            val drawDeadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(8)
            var drewBootstrap = false
            while (!drewBootstrap && System.nanoTime() < drawDeadline) {
                instrumentation.runOnMainSync {
                    val root = requireNotNull(gatedRoot)
                    val orb = root.findViewById<KeyguardHeaderMaterialView>(R.id.fluvi_financial_snapshot_orb)
                    drewBootstrap = root.isAttachedToWindow && root.rootSurfaceControl != null &&
                        orb.diagnostics().bootstrapDrawCount > bootstrapCountBefore
                }
                if (!drewBootstrap) Thread.sleep(24)
            }
            assertTrue("invalid fixture: no actual bootstrap draw with a usable root surface", drewBootstrap)
            var previousBootstrap: Bitmap? = null
            try {
                bootstrap = awaitCompositorCrop("r07-first-bootstrap", { copyPanelOrb(instrumentation, manager) },
                    { label, bitmap -> persistPanelEvidence(activity, label, bitmap) }, { candidate ->
                        val eligible = hasVisibleMaterial(candidate) &&
                            compareMaterialPixels(candidate, requireNotNull(reference)).meaningful()
                        val stable = eligible && previousBootstrap?.let {
                            compareMaterialPixels(it, candidate).nearlyEqual()
                        } == true
                        previousBootstrap?.recycle()
                        previousBootstrap = if (eligible) candidate.copy(Bitmap.Config.ARGB_8888, false) else null
                        stable
                    }, {})
            } finally { previousBootstrap?.recycle() }
            instrumentation.runOnMainSync {
                val root = requireNotNull(gatedRoot)
                gate = ViewTreeObserver.OnPreDrawListener { withheld.countDown(); false }
                root.viewTreeObserver.addOnPreDrawListener(requireNotNull(gate))
                root.invalidate()
            }
            assertTrue("fixture did not actually withhold a subsequent root draw", withheld.await(8, TimeUnit.SECONDS))
            releaseFirst.countDown()
            val first = submissions.await(2L)
            val produced = samples.await(2L)
            assertEquals(first, produced.frame)
            assertEquals("transparent producer corner was filled", 0, produced.pixels.first() ushr 24)
            assertTrue("no real first transaction commit receipt", firstCommit.await(8, TimeUnit.SECONDS))
            assertTrue("the first steady publication was not held", steadyEntered.await(8, TimeUnit.SECONDS))
            val token = firstIdentities.single { it.lease == first.lease }
            assertEquals(first.slotId, token.slotId)
            assertEquals(first.useGeneration, token.useGeneration)
            assertTrue("commit must identify the exact first child/token", commits.any { it === token })
            assertEquals(1L, releaseSteady.count)
            var referenceObserved = false
            repeat(12) { index ->
                val sample = copyPanelOrb(instrumentation, manager)
                try {
                    persistPanelEvidence(activity, "r07-first-strip-${index.toString().padStart(2, '0')}", sample)
                    if (compareMaterialPixels(requireNotNull(reference), sample).nearlyEqual()) referenceObserved = true
                } finally { sample.recycle() }
                Thread.sleep(32)
            }
            assertTrue("first direct buffer did not reach the compositor with root draw withheld", referenceObserved)
            assertEquals("steady frame was released before first-phase sampling", 1L, releaseSteady.count)
        } finally {
            releaseFirst.countDown()
            releaseSteady.countDown()
            instrumentation.runOnMainSync {
                val root = gatedRoot
                val listener = gate
                if (root != null && listener != null && root.viewTreeObserver.isAlive) {
                    root.viewTreeObserver.removeOnPreDrawListener(listener)
                    root.invalidate()
                }
                createdWindow?.dispose()
                activity.finish()
            }
            KeyguardOrbBufferRendererTestHooks.firstPublicationHook = NoopKeyguardOrbFirstPublicationTestHook
            KeyguardOrbBufferRendererTestHooks.materialTimeSource = SystemKeyguardOrbMaterialTimeSource
            KeyguardOrbBufferRendererTestHooks.publicationObserver = NoopKeyguardOrbBufferPublicationObserver
            KeyguardOrbBufferRendererTestHooks.frameObserver = NoopKeyguardOrbBufferFrameObserver
            KeyguardOrbBufferRendererTestHooks.steadyPublicationBarrier = NoopKeyguardOrbSteadyPublicationBarrier
            reference?.recycle()
            bootstrap?.recycle()
        }
    }

    @Test fun isolatedOrbFirstDirectRetiresAcrossThreeSameRendererReplacements() {
        withOrbRetirementFixture("first-direct-replacement") { fixture ->
            // Calibrate the accepted A image while the initial attachment is
            // already showing A. A merely nonempty crop after the preceding
            // B request can still be B, even after the next A submission.
            val canonicalA = fixture.capture(PHASE_A, "canonical-a") { hasVisibleMaterial(it) }
            try {
            repeat(3) { cycle ->
                val reference = fixture.capture(PHASE_A, "first-$cycle-reference") {
                    compareMaterialPixels(canonicalA.bitmap, it).nearlyEqual()
                }
                try {
                    var attachmentA = 0L
                    fixture.instrumentation.runOnMainSync {
                        assertTrue(fixture.window.hide())
                        attachmentA = fixture.window.currentAttachGeneration + 1L
                    }
                    val held = fixture.holdFirstCommitAndSteady(attachmentA)
                    val requestA = fixture.prepareFirst(PHASE_A)
                    fixture.instrumentation.runOnMainSync {
                        assertEquals(KeyguardCardWindow.Result.ATTACHED,
                            fixture.window.showOrUpdate(FluviFinancialCardPresenter.loading(), fixture.settings))
                        assertEquals(attachmentA, fixture.window.currentAttachGeneration)
                    }
                    val first = fixture.submitted(requestA)
                    val token = fixture.awaitFirstToken(attachmentA)
                    assertEquals(first.lease, token.lease)
                    assertEquals(first.slotId, token.slotId)
                    assertEquals(first.useGeneration, token.useGeneration)
                    assertTrue("first steady A did not reach the real Worker boundary", held.entered.await(8, TimeUnit.SECONDS))
                    val commit = fixture.awaitDeferredCommit(attachmentA)
                    assertTrue("commit did not retain the exact A token", commit.token === token)
                    assertTrue("first A never reached the expected compositor crop", waitForPanelOrbScreenBounds(fixture.instrumentation, fixture.manager))
                    val firstA = awaitCompositorCrop("r07-first-$cycle-a", { copyPanelOrb(fixture.instrumentation, fixture.manager) },
                        { label, bitmap -> persistPanelEvidence(fixture.activity, label, bitmap) },
                        { compareMaterialPixels(reference.bitmap, it).nearlyEqual() }, {})
                    firstA.recycle()
                    var attachmentB = 0L
                    val requestB = fixture.prepareFirst(PHASE_B)
                    fixture.instrumentation.runOnMainSync {
                        assertTrue("A withdrawal must return while Worker is held", fixture.window.hide())
                        fixture.assertHiddenExactlyOnce(first.lease)
                        fixture.assertNormalHideOrder(first.lease)
                        assertEquals(1L, held.returned.count)
                        assertEquals(KeyguardCardWindow.Result.ATTACHED,
                            fixture.window.showOrUpdate(FluviFinancialCardPresenter.loading(), fixture.settings))
                        attachmentB = fixture.window.currentAttachGeneration
                        assertTrue(attachmentB != attachmentA)
                        assertFalse("B must begin with its own placeholder", fixture.manager.isOrbBootstrapSuppressed())
                    }
                    // Consume the real but stale A commit only after B owns
                    // the retained root. It cannot hide B's bootstrap.
                    fixture.deliverDeferredCommit(attachmentA)
                    fixture.instrumentation.runOnMainSync {
                        assertTrue(fixture.window.isAttached)
                        assertEquals(attachmentB, fixture.window.currentAttachGeneration)
                        assertFalse("stale A commit suppressed B's placeholder", fixture.manager.isOrbBootstrapSuppressed())
                    }
                    assertEquals("Main waited for the held steady use", 1L, held.returned.count)
                    held.release.countDown()
                    val receipt = fixture.ownership.awaitUse("release-received", first)
                    val fence = fixture.ownership.awaitUse("release-fence-complete", first)
                    val drain = fixture.ownership.awaitLease("lease-drained", first.lease)
                    assertEquals(System.identityHashCode(token.child), receipt.childIdentity)
                    assertTrue("actual first-use receipt missing", receipt.slots.any {
                        it.slotId == first.slotId && it.useGeneration == first.useGeneration && it.callbackReceived
                    })
                    assertTrue("old first use still owned after drain", drain.slots.none {
                        it.lease == first.lease && it.state != "FREE"
                    })
                    val history = fixture.ownership.snapshot()
                    assertTrue(history.indexOf(receipt) <= history.indexOf(fence))
                    assertTrue(history.indexOf(fence) < history.indexOf(drain))
                    assertFalse("first steady gate timed out", held.timedOut.get())
                    val firstB = fixture.submitted(requestB)
                    assertEquals(attachmentB, firstB.lease.attachment)
                    val moved = fixture.capture(PHASE_B, "first-$cycle-b") {
                        compareMaterialPixels(reference.bitmap, it).meaningful()
                    }
                    try {
                        assertEquals(attachmentB, moved.frame.lease.attachment)
                        fixture.instrumentation.runOnMainSync {
                            assertTrue(fixture.window.isAttached)
                            assertEquals(attachmentB, fixture.window.currentAttachGeneration)
                            assertFalse("old A hide affected B", fixture.hides.any { it.attachment == attachmentB })
                        }
                    } finally { moved.bitmap.recycle() }
                    fixture.ownership.assertBoundedSingleRenderer()
                } finally { reference.bitmap.recycle() }
            }
            } finally { canonicalA.bitmap.recycle() }
        }
    }

    @Test fun isolatedOrbFirstDirectDisposeDoesNotWaitForWorkerOrOldCommit() {
        withOrbRetirementFixture("first-direct-dispose") { fixture ->
            var attachment = 0L
            fixture.instrumentation.runOnMainSync {
                assertTrue(fixture.window.hide())
                attachment = fixture.window.currentAttachGeneration + 1L
            }
            val gate = fixture.holdFirstCommitAndSteady(attachment)
            val request = fixture.prepareFirst(PHASE_A)
            fixture.instrumentation.runOnMainSync {
                assertEquals(KeyguardCardWindow.Result.ATTACHED,
                    fixture.window.showOrUpdate(FluviFinancialCardPresenter.loading(), fixture.settings))
            }
            val first = fixture.submitted(request)
            val token = fixture.awaitFirstToken(attachment)
            assertTrue(gate.entered.await(8, TimeUnit.SECONDS))
            assertTrue(fixture.awaitDeferredCommit(attachment).token === token)
            fixture.instrumentation.runOnMainSync {
                fixture.window.dispose()
                assertFalse(fixture.window.isAttached)
                assertEquals(null, fixture.manager.currentRoot)
                assertEquals(1L, gate.returned.count)
            }
            fixture.deliverDeferredCommit(attachment)
            gate.release.countDown()
            fixture.ownership.awaitUse("release-received", first)
            fixture.ownership.awaitUse("release-fence-complete", first)
            val drained = fixture.ownership.awaitLease("lease-drained", first.lease)
            assertTrue(drained.slots.none { it.lease == first.lease && it.state != "FREE" })
            assertFalse(gate.timedOut.get())
            fixture.instrumentation.runOnMainSync {
                assertFalse(fixture.window.isAttached)
                assertEquals(null, fixture.manager.currentRoot)
            }
            fixture.ownership.assertBoundedSingleRenderer()
        }
    }

    @Test fun isolatedOrbReadyFrameCannotSubmitAfterItsAttachmentIsRetired() {
        withOrbRetirementFixture("first-stale-ready") { fixture ->
            var attachmentA = 0L
            fixture.instrumentation.runOnMainSync {
                assertTrue(fixture.window.hide())
                attachmentA = fixture.window.currentAttachGeneration + 1L
            }
            fixture.holdReady(attachmentA)
            val requestA = fixture.prepareFirst(PHASE_A)
            fixture.instrumentation.runOnMainSync {
                assertEquals(KeyguardCardWindow.Result.ATTACHED,
                    fixture.window.showOrUpdate(FluviFinancialCardPresenter.loading(), fixture.settings))
            }
            val pending = fixture.awaitReady(attachmentA)
            assertEquals(attachmentA, pending.frame.lease.attachment)
            assertFalse("held READY frame has already been submitted", fixture.hasSubmitted(requestA))
            var attachmentB = 0L
            fixture.instrumentation.runOnMainSync {
                assertTrue(fixture.window.hide())
                assertEquals(KeyguardCardWindow.Result.ATTACHED,
                    fixture.window.showOrUpdate(FluviFinancialCardPresenter.loading(), fixture.settings))
                attachmentB = fixture.window.currentAttachGeneration
            }
            fixture.deliverReady(attachmentA)
            assertFalse("retired A's ready runnable submitted a buffer", fixture.hasSubmitted(requestA))
            val drained = fixture.ownership.awaitLease("lease-drained", pending.frame.lease)
            assertTrue(drained.slots.none { it.lease == pending.frame.lease && it.state != "FREE" })
            val replacement = fixture.awaitAttachment(attachmentB)
            assertEquals(attachmentB, replacement.attachment)
            fixture.instrumentation.runOnMainSync {
                assertTrue(fixture.window.isAttached)
                assertEquals(attachmentB, fixture.window.currentAttachGeneration)
                assertFalse(fixture.hides.any { it.attachment == attachmentB })
            }
            fixture.ownership.assertBoundedSingleRenderer()
        }
    }

    @Test fun isolatedOrbPreApplyFailureAndPostTransferObserverFailureHaveDifferentOwnership() {
        withOrbRetirementFixture("first-pre-apply-failure") { fixture ->
            var attachment = 0L
            fixture.instrumentation.runOnMainSync {
                assertTrue(fixture.window.hide())
                attachment = fixture.window.currentAttachGeneration + 1L
            }
            fixture.failBeforeApply(attachment)
            val request = fixture.prepareFirst(PHASE_A)
            fixture.instrumentation.runOnMainSync {
                assertEquals(KeyguardCardWindow.Result.ATTACHED,
                    fixture.window.showOrUpdate(FluviFinancialCardPresenter.loading(), fixture.settings))
            }
            val attempted = fixture.awaitAttemptedFirst(attachment)
            val drained = fixture.ownership.awaitLease("lease-drained", attempted.lease)
            assertFalse("failure before apply transferred a frame", fixture.hasSubmitted(request))
            assertTrue(drained.slots.none { it.lease == attempted.lease && it.state != "FREE" })
            fixture.instrumentation.runOnMainSync {
                assertTrue(fixture.window.isAttached)
                assertFalse("failed isolated route remained selected",
                    fixture.window.materialDiagnostics()?.activeRenderer == "HardwareBufferRenderer/SurfaceControl")
            }
            fixture.ownership.assertBoundedSingleRenderer()
        }
        withOrbRetirementFixture("first-post-transfer-failure") { fixture ->
            var attachment = 0L
            fixture.instrumentation.runOnMainSync {
                assertTrue(fixture.window.hide())
                attachment = fixture.window.currentAttachGeneration + 1L
            }
            fixture.failAfterTransfer(attachment)
            val request = fixture.prepareFirst(PHASE_A)
            fixture.instrumentation.runOnMainSync {
                assertEquals(KeyguardCardWindow.Result.ATTACHED,
                    fixture.window.showOrUpdate(FluviFinancialCardPresenter.loading(), fixture.settings))
            }
            val first = fixture.submitted(request)
            fixture.awaitFirstToken(attachment)
            val published = fixture.ownership.awaitUse("first-submitted", first)
            assertTrue("transferred first use was not PUBLISHED", published.slots.any {
                it.slotId == first.slotId && it.useGeneration == first.useGeneration && it.state == "PUBLISHED"
            })
            fixture.instrumentation.runOnMainSync { assertTrue(fixture.window.hide()) }
            fixture.ownership.awaitUse("release-received", first)
            fixture.ownership.awaitUse("release-fence-complete", first)
            val drained = fixture.ownership.awaitLease("lease-drained", first.lease)
            assertTrue(drained.slots.none { it.lease == first.lease && it.state != "FREE" })
            fixture.ownership.assertBoundedSingleRenderer()
        }
    }

    @Test fun isolatedOrbStaleFirstCommitCannotUndoSameRootPrivacyOrSizeReplacement() {
        withOrbRetirementFixture("first-privacy-size") { fixture ->
            var attachment = 0L
            fixture.instrumentation.runOnMainSync {
                assertTrue(fixture.window.hide())
                attachment = fixture.window.currentAttachGeneration + 1L
            }
            val fullGate = fixture.holdFirstCommitAndSteady(attachment)
            val fullRequest = fixture.prepareFirst(PHASE_A)
            fixture.instrumentation.runOnMainSync {
                assertEquals(KeyguardCardWindow.Result.ATTACHED,
                    fixture.window.showOrUpdate(FluviFinancialCardPresenter.loading(), fixture.settings))
            }
            val full = fixture.submitted(fullRequest)
            val fullToken = fixture.awaitFirstToken(attachment)
            assertEquals(full.lease, fullToken.lease)
            assertTrue(fullGate.entered.await(8, TimeUnit.SECONDS))
            assertTrue(fixture.awaitDeferredCommit(attachment).token === fullToken)
            lateinit var retainedRoot: View
            fixture.instrumentation.runOnMainSync {
                retainedRoot = requireNotNull(fixture.manager.currentRoot)
                val result = fixture.window.showOrUpdate(FluviFinancialCardPresenter.discreet(),
                    fixture.settings.copy(showFinancialDetails = false))
                assertTrue("privacy downgrade did not update the retained root",
                    result == KeyguardCardWindow.Result.REDACTED || result == KeyguardCardWindow.Result.CONTENT_UPDATED)
                val orb = retainedRoot.findViewById<KeyguardHeaderMaterialView>(R.id.fluvi_financial_snapshot_orb)
                assertTrue("discreet replacement requires a static safe bootstrap", orb.isBootstrapActive())
                assertEquals(View.VISIBLE, orb.visibility)
            }
            fixture.deliverDeferredCommit(attachment)
            fixture.instrumentation.runOnMainSync {
                assertTrue(retainedRoot === fixture.manager.currentRoot)
                val orb = retainedRoot.findViewById<KeyguardHeaderMaterialView>(R.id.fluvi_financial_snapshot_orb)
                assertTrue("old full commit suppressed the neutral bootstrap", orb.isBootstrapActive())
                assertEquals(View.VISIBLE, orb.visibility)
            }
            // The next generation has the same retained root and attachment.
            // Hold its real commit while a size change revokes that lease too.
            val neutralGate = fixture.holdFirstCommitAndSteady(attachment)
            fullGate.release.countDown()
            val neutralToken = fixture.awaitReplacementToken(fullToken)
            assertEquals(attachment, neutralToken.lease.attachment)
            assertEquals(calibratedOrbProfile().neutralized().visualKey, neutralToken.lease.visualKey)
            assertTrue(neutralGate.entered.await(8, TimeUnit.SECONDS))
            assertTrue(fixture.awaitDeferredCommit(attachment).token === neutralToken)
            fixture.instrumentation.runOnMainSync {
                assertTrue(retainedRoot === fixture.manager.currentRoot)
                assertEquals(attachment, fixture.window.currentAttachGeneration)
                val orb = retainedRoot.findViewById<KeyguardHeaderMaterialView>(R.id.fluvi_financial_snapshot_orb)
                orb.layout(orb.left, orb.top, orb.right + 4, orb.bottom + 4)
            }
            fixture.instrumentation.runOnMainSync { }
            fixture.deliverDeferredCommit(attachment)
            fixture.instrumentation.runOnMainSync {
                val orb = retainedRoot.findViewById<KeyguardHeaderMaterialView>(R.id.fluvi_financial_snapshot_orb)
                assertTrue("old size commit suppressed replacement bootstrap", orb.isBootstrapActive())
                assertEquals(View.VISIBLE, orb.visibility)
            }
            neutralGate.release.countDown()
            fixture.ownership.awaitUse("release-received", full)
            fixture.ownership.awaitUse("release-fence-complete", full)
            fixture.ownership.awaitLease("lease-drained", full.lease)
            val resized = fixture.awaitReplacementToken(neutralToken)
            assertEquals(attachment, resized.lease.attachment)
            assertEquals(neutralToken.lease.visualKey, resized.lease.visualKey)
            assertTrue("size change did not produce a new buffer geometry",
                resized.lease.width != neutralToken.lease.width || resized.lease.height != neutralToken.lease.height)
            assertFalse(fullGate.timedOut.get())
            assertFalse(neutralGate.timedOut.get())
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

    private class FirstSteadyGate(val attachment: Long) {
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
    }

    private data class DeferredFirstCommit(
        val token: KeyguardOrbFirstPublicationToken,
        val receivedAtUptimeMs: Long,
        val delivery: () -> Unit,
    )

    private data class DeferredReadyFrame(
        val frame: KeyguardOrbBufferProducerFrame,
        val delivery: () -> Unit,
    )

    /** Holds delivery of actual platform receipts without blocking their
     * callback thread. No test manufactures a release or a fence. */
    private class RealReleaseGate : KeyguardOrbRecoveryTestHook {
        private data class Receipt(val lease: KeyguardOrbBufferLease, val slot: Long, val use: Long,
                                   val delivery: () -> Unit)
        private data class Offered(val ticket: KeyguardOrbPressureTicket, val delivery: () -> Unit)
        private val firstRender = java.util.concurrent.ConcurrentHashMap.newKeySet<KeyguardOrbBufferLease>()
        private val held = java.util.concurrent.ConcurrentLinkedQueue<Receipt>()
        private val tickets = java.util.concurrent.ConcurrentLinkedQueue<Offered>()
        private val opened = java.util.concurrent.atomic.AtomicBoolean(false)
        @Volatile var allowContinuous = false
        @Volatile var delayTickets = false
        @Volatile var heldLease: KeyguardOrbBufferLease? = null
        data class RetirementBoundary(val lease: KeyguardOrbBufferLease, val child: Int, val event: String, val at: Long)
        private val retirements = java.util.concurrent.CopyOnWriteArrayList<RetirementBoundary>()
        data class PlacementBoundary(val lease: KeyguardOrbBufferLease, val child: Int, val submitted: Boolean)
        val placements = java.util.concurrent.CopyOnWriteArrayList<PlacementBoundary>()

        override fun onPlacement(lease: KeyguardOrbBufferLease, childIdentity: Int, submitted: Boolean) {
            placements += PlacementBoundary(lease, childIdentity, submitted)
        }

        override fun onRetirementEvent(lease: KeyguardOrbBufferLease, childIdentity: Int, event: String, uptimeMs: Long) {
            retirements += RetirementBoundary(lease, childIdentity, event, uptimeMs)
        }

        fun retirementSnapshot(): List<RetirementBoundary> = retirements.toList()

        fun awaitRetirement(lease: KeyguardOrbBufferLease, event: String): RetirementBoundary {
            val end = System.nanoTime() + TimeUnit.SECONDS.toNanos(8)
            while (System.nanoTime() < end) {
                retirements.firstOrNull { it.lease == lease && it.event == event }?.let { return it }
                Thread.sleep(24)
            }
            throw AssertionError("missing actual retirement boundary $event for $lease; observed=$retirements")
        }

        override fun allowRender(lease: KeyguardOrbBufferLease): Boolean =
            allowContinuous || lease.attachment <= 0L || firstRender.add(lease)

        override fun dispatchRelease(lease: KeyguardOrbBufferLease, slotId: Long, use: Long,
                                     fence: android.hardware.SyncFence?, deliver: () -> Unit) {
            if (opened.get() || (heldLease != null && heldLease != lease)) { deliver(); return }
            val receipt = Receipt(lease, slotId, use, deliver)
            held.add(receipt)
            if (opened.get() && held.remove(receipt)) deliver()
        }

        override fun dispatchTicket(ticket: KeyguardOrbPressureTicket, deliver: () -> Unit) {
            if (!delayTickets) { deliver(); return }
            tickets.add(Offered(ticket, deliver))
        }

        fun awaitTicket(attachment: Long, afterGeneration: Long = -1L): KeyguardOrbPressureTicket {
            val end = System.nanoTime() + TimeUnit.SECONDS.toNanos(8)
            while (System.nanoTime() < end) {
                tickets.firstOrNull { it.ticket.lease.attachment == attachment &&
                    it.ticket.lease.generation > afterGeneration }?.let { return it.ticket }
                Thread.sleep(24)
            }
            throw AssertionError("no actual pressure offer for attachment=$attachment")
        }

        fun deliverTicket(attachment: Long) {
            val offered = tickets.firstOrNull { it.ticket.lease.attachment == attachment }
                ?: throw AssertionError("missing held pressure offer attachment=$attachment")
            check(tickets.remove(offered))
            offered.delivery()
        }

        fun deliverTicket(ticket: KeyguardOrbPressureTicket) {
            val offered = tickets.firstOrNull { it.ticket === ticket }
                ?: throw AssertionError("missing held exact pressure offer ${ticket.lease}")
            check(tickets.remove(offered))
            offered.delivery()
        }

        fun awaitActualReceipt(frame: KeyguardOrbBufferProducerFrame) {
            val end = System.nanoTime() + TimeUnit.SECONDS.toNanos(8)
            while (System.nanoTime() < end) {
                if (held.any { it.lease == frame.lease && it.slot == frame.slotId && it.use == frame.useGeneration }) return
                Thread.sleep(24)
            }
            throw AssertionError("No real platform receipt arrived for ${frame.lease} ${frame.slotId}/${frame.useGeneration}; not a withheld-receipt RED")
        }

        fun heldCount(): Int = held.size

        fun heldSummary(): List<String> = held.map {
            "lease=${it.lease.attachment}/${it.lease.generation} slot=${it.slot} use=${it.use} receipt=held"
        }
        fun releaseAll() {
            allowContinuous = true
            opened.set(true)
            while (true) (held.poll() ?: break).delivery()
        }
        fun releaseTickets() {
            delayTickets = false
            while (true) (tickets.poll() ?: break).delivery()
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

    private fun withOrbRetirementFixture(
        label: String,
        recoveryHook: KeyguardOrbRecoveryTestHook = NoopKeyguardOrbRecoveryTestHook,
        initialProfile: KeyguardMaterialProfile = calibratedOrbProfile(),
        exercise: (OrbRetirementFixture) -> Unit,
    ) {
        assumeTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
        val fixture = OrbRetirementFixture(label, recoveryHook, initialProfile)
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
    private inner class OrbRetirementFixture(
        private val label: String,
        private val recoveryHook: KeyguardOrbRecoveryTestHook,
        private val initialProfile: KeyguardMaterialProfile,
    ) {
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
        val windowBoundaries = mutableListOf<Triple<Long?, String, Int?>>()
        val interactionEvents = java.util.concurrent.CopyOnWriteArrayList<String>()
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
        private val firstSteadyGate = AtomicReference<FirstSteadyGate?>()
        private val firstSteadyGates = mutableListOf<FirstSteadyGate>()
        private val deferredAttachment = java.util.concurrent.atomic.AtomicLong(-1L)
        private val submittedFirst = java.util.concurrent.CopyOnWriteArrayList<KeyguardOrbFirstPublicationToken>()
        private val deferredCommits = java.util.concurrent.ConcurrentHashMap<Long, DeferredFirstCommit>()
        private val firstCommitEvidence = java.util.concurrent.CopyOnWriteArrayList<String>()
        private val readyAttachment = java.util.concurrent.atomic.AtomicLong(-1L)
        private val deferredReady = java.util.concurrent.ConcurrentHashMap<Long, DeferredReadyFrame>()
        private val failBeforeAttachment = java.util.concurrent.atomic.AtomicLong(-1L)
        private val failAfterAttachment = java.util.concurrent.atomic.AtomicLong(-1L)
        private val attemptedFirst = java.util.concurrent.ConcurrentHashMap<Long, KeyguardOrbFirstPublicationToken>()
        private var nextRequest = 0L

        fun start() {
            KeyguardOrbBufferRendererTestHooks.recoveryHook = recoveryHook
            KeyguardOrbBufferRendererTestHooks.materialTimeSource = controlledTime
            KeyguardOrbBufferRendererTestHooks.publicationObserver = submissions
            KeyguardOrbBufferRendererTestHooks.frameObserver = samples
            KeyguardOrbBufferRendererTestHooks.ownershipObserver = ownership
            KeyguardOrbBufferRendererTestHooks.firstPublicationHook = object : KeyguardOrbFirstPublicationTestHook {
                override fun dispatchReady(frame: KeyguardOrbBufferProducerFrame, deliver: () -> Unit) {
                    if (readyAttachment.get() == frame.lease.attachment) {
                        check(deferredReady.putIfAbsent(frame.lease.attachment, DeferredReadyFrame(frame, deliver)) == null)
                    } else deliver()
                }
                override fun beforeApply(token: KeyguardOrbFirstPublicationToken) {
                    attemptedFirst[token.lease.attachment] = token
                    if (failBeforeAttachment.compareAndSet(token.lease.attachment, -1L)) {
                        throw IllegalStateException("injected-before-apply")
                    }
                }
                override fun afterSubmitted(token: KeyguardOrbFirstPublicationToken) {
                    submittedFirst += token
                    if (failAfterAttachment.compareAndSet(token.lease.attachment, -1L)) {
                        throw IllegalStateException("injected-after-transfer")
                    }
                }
                override fun dispatchCommit(token: KeyguardOrbFirstPublicationToken, receivedAtUptimeMs: Long, deliver: () -> Unit) {
                    if (deferredAttachment.get() == token.lease.attachment) {
                        firstCommitEvidence += "receipt attachment=${token.lease.attachment} generation=${token.lease.generation} " +
                            "child=${System.identityHashCode(token.child)} slot=${token.slotId} use=${token.useGeneration} uptimeMs=$receivedAtUptimeMs"
                        check(deferredCommits.putIfAbsent(token.lease.attachment,
                            DeferredFirstCommit(token, receivedAtUptimeMs, deliver)) == null)
                    } else deliver()
                }
            }
            KeyguardOrbBufferRendererTestHooks.steadyPublicationBarrier = KeyguardOrbSteadyPublicationBarrier { frame ->
                val first = firstSteadyGate.get()
                if (first != null && frame.lease.attachment == first.attachment &&
                    firstSteadyGate.compareAndSet(first, null)
                ) first.hold(frame)
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
                    onInteractionDiagnostic = { stage, _ -> interactionEvents += stage },
                    onWindowDiagnostic = { stage, _, attachment, observedAt, fields ->
                        if (stage == "LOCAL_HIDE_APPLIED" || stage == "ISOLATED_LAYER_HIDE_SUBMITTED" ||
                            stage == "REMOVE_VIEW_BEGIN" || stage == "REMOVE_VIEW_RETURN"
                        ) windowBoundaries += Triple(attachment, stage, manager.currentRoot?.visibility)
                        if (stage == "ISOLATED_LAYER_HIDE_SUBMITTED") {
                            hides += OrbRetirementHide(attachment, fields["leaseGeneration"] as? Long,
                                observedAt, fields["transactionApplied"] == true)
                        }
                    },
                    manager = TestPanelWindowManager(activity).also { manager = it },
                )
                createdWindow = window
                window.prepareRetainedView(settings, initialProfile)
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

        fun prepareFirst(phase: Float): Long = request(phase)
        fun submitted(requestId: Long): KeyguardOrbBufferProducerFrame = submissions.await(requestId)
        fun hasSubmitted(requestId: Long): Boolean = submissions.hasSubmitted(requestId)
        fun holdReady(attachment: Long) { readyAttachment.set(attachment) }
        fun failBeforeApply(attachment: Long) { failBeforeAttachment.set(attachment) }
        fun failAfterTransfer(attachment: Long) { failAfterAttachment.set(attachment) }

        fun awaitReady(attachment: Long): DeferredReadyFrame {
            val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(8)
            while (System.nanoTime() < deadline) {
                deferredReady[attachment]?.let { return it }
                Thread.sleep(24)
            }
            throw AssertionError("first ready handoff missing for attachment=$attachment")
        }

        fun deliverReady(attachment: Long) {
            val pending = requireNotNull(deferredReady.remove(attachment))
            readyAttachment.set(-1L)
            instrumentation.runOnMainSync { pending.delivery() }
        }

        fun awaitAttemptedFirst(attachment: Long): KeyguardOrbFirstPublicationToken {
            val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(8)
            while (System.nanoTime() < deadline) {
                attemptedFirst[attachment]?.let { return it }
                Thread.sleep(24)
            }
            throw AssertionError("first apply attempt missing for attachment=$attachment")
        }

        fun holdFirstCommitAndSteady(attachment: Long): FirstSteadyGate {
            deferredAttachment.set(attachment)
            val gate = FirstSteadyGate(attachment)
            firstSteadyGates += gate
            check(firstSteadyGate.compareAndSet(null, gate))
            return gate
        }

        fun awaitFirstToken(attachment: Long): KeyguardOrbFirstPublicationToken {
            val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(8)
            while (System.nanoTime() < deadline) {
                submittedFirst.firstOrNull { it.lease.attachment == attachment }?.let { return it }
                Thread.sleep(24)
            }
            throw AssertionError("first submission missing for attachment=$attachment")
        }

        fun twoHeldUsesAndCurrentTicket(gate: RealReleaseGate): Pair<KeyguardOrbBufferProducerFrame, KeyguardOrbPressureTicket> {
            fun hide() = instrumentation.runOnMainSync { assertTrue(window.hide()) }
            fun show(): KeyguardOrbBufferProducerFrame {
                val request = prepareFirst(PHASE_A)
                instrumentation.runOnMainSync {
                    assertEquals(KeyguardCardWindow.Result.ATTACHED,
                        window.showOrUpdate(FluviFinancialCardPresenter.loading(), settings))
                }
                return submitted(request)
            }
            val first = awaitFirstToken(initialLease.attachment)
            hide()
            gate.awaitActualReceipt(KeyguardOrbBufferProducerFrame(first.lease, first.slotId,
                first.useGeneration, 0L, calibratedMaterialTime(PHASE_A)))
            val second = show()
            hide()
            gate.awaitActualReceipt(second)
            val current = show()
            val ticket = gate.awaitTicket(current.lease.attachment)
            assertEquals(current.lease, ticket.lease)
            return current to ticket
        }

        fun awaitReplacementToken(old: KeyguardOrbFirstPublicationToken): KeyguardOrbFirstPublicationToken {
            val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(8)
            while (System.nanoTime() < deadline) {
                submittedFirst.firstOrNull { it.lease.attachment == old.lease.attachment &&
                    it.lease.generation > old.lease.generation }
                    ?.let { return it }
                Thread.sleep(24)
            }
            throw AssertionError("same-attachment replacement lease missing after ${old.lease}")
        }

        fun awaitDeferredCommit(attachment: Long): DeferredFirstCommit {
            val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(8)
            while (System.nanoTime() < deadline) {
                deferredCommits[attachment]?.let { return it }
                Thread.sleep(24)
            }
            throw AssertionError("real first commit was not delivered to the test dispatcher attach=$attachment")
        }

        fun deliverDeferredCommit(attachment: Long) {
            val pending = requireNotNull(deferredCommits.remove(attachment))
            deferredAttachment.compareAndSet(attachment, -1L)
            instrumentation.runOnMainSync {
                val token = pending.token
                firstCommitEvidence += "delivery attachment=${token.lease.attachment} generation=${token.lease.generation} " +
                    "child=${System.identityHashCode(token.child)} slot=${token.slotId} use=${token.useGeneration} uptimeMs=${SystemClock.uptimeMillis()}"
                pending.delivery()
            }
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
            val submitted = try { submissions.await(requestId) } catch (error: Throwable) {
                var diagnostics: KeyguardMaterialDiagnostics? = null
                instrumentation.runOnMainSync { diagnostics = window.materialDiagnostics() }
                val directory = File(activity.filesDir, "keyguard-material-smoke").apply { mkdirs() }
                File(directory, "r11-$label-$suffix-request-failure.txt").writeText(
                    "uptime=${SystemClock.uptimeMillis()} request=$requestId phase=$phase " +
                        "route=${diagnostics?.effectiveRoute ?: "UNOBSERVED"} " +
                        "held=${(recoveryHook as? RealReleaseGate)?.heldSummary() ?: emptyList<String>()}\n" +
                        "latestWorkerSnapshot=${ownership.snapshot().lastOrNull() ?: "UNOBSERVED"}\n" +
                        "failure=${error.javaClass.simpleName}:${error.message}\n")
                throw error
            }
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

        fun assertNormalHideOrder(lease: KeyguardOrbBufferLease) {
            val events = windowBoundaries.filter { it.first == lease.attachment }
            val local = events.indexOfFirst { it.second == "LOCAL_HIDE_APPLIED" }
            val child = events.indexOfFirst { it.second == "ISOLATED_LAYER_HIDE_SUBMITTED" }
            val removeBegin = events.indexOfFirst { it.second == "REMOVE_VIEW_BEGIN" }
            val removeReturn = events.indexOfFirst { it.second == "REMOVE_VIEW_RETURN" }
            assertTrue("root/child/remove boundaries out of order: $events",
                local >= 0 && local < child && child < removeBegin && removeBegin < removeReturn)
            assertEquals("root was visible when its child hide was submitted", View.INVISIBLE, events[child].third)
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
            (recoveryHook as? RealReleaseGate)?.let {
                it.releaseAll()
                instrumentation.runOnMainSync { it.releaseTickets() }
            }
            nextGate.set(null)
            gates.forEach { it.release.countDown() }
            firstSteadyGate.set(null)
            firstSteadyGates.forEach { it.release.countDown() }
            deferredReady.values.toList().forEach { pending ->
                instrumentation.runOnMainSync { pending.delivery() }
            }
            deferredReady.clear()
            deferredCommits.keys.toList().forEach(::deliverDeferredCommit)
        }

        fun resetHooks() {
            KeyguardOrbBufferRendererTestHooks.materialTimeSource = SystemKeyguardOrbMaterialTimeSource
            KeyguardOrbBufferRendererTestHooks.publicationObserver = NoopKeyguardOrbBufferPublicationObserver
            KeyguardOrbBufferRendererTestHooks.frameObserver = NoopKeyguardOrbBufferFrameObserver
            KeyguardOrbBufferRendererTestHooks.steadyPublicationBarrier = NoopKeyguardOrbSteadyPublicationBarrier
            KeyguardOrbBufferRendererTestHooks.ownershipObserver = NoopKeyguardOrbOwnershipObserver
            KeyguardOrbBufferRendererTestHooks.firstPublicationHook = NoopKeyguardOrbFirstPublicationTestHook
            KeyguardOrbBufferRendererTestHooks.recoveryHook = NoopKeyguardOrbRecoveryTestHook
        }

        fun persistOwnershipEvidence() {
            val directory = File(activity.filesDir, "keyguard-material-smoke").apply { mkdirs() }
            val details = StringBuilder()
            instrumentation.runOnMainSync { hides.forEach { details.appendLine("mainHide=$it") } }
            gates.forEach { details.appendLine("gate request=${it.requestId} frame=${it.frame.get()} timedOut=${it.timedOut.get()}") }
            firstSteadyGates.forEach { details.appendLine("firstSteady attachment=${it.attachment} frame=${it.frame.get()} timedOut=${it.timedOut.get()}") }
            submittedFirst.forEach { token -> details.appendLine("firstSubmitted attachment=${token.lease.attachment} token=$token") }
            firstCommitEvidence.forEach { details.appendLine("firstCommit $it") }
            deferredCommits.forEach { (attachment, pending) -> details.appendLine("firstCommit attachment=$attachment token=${pending.token} received=${pending.receivedAtUptimeMs}") }
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
        private val expectedAttachments = java.util.concurrent.ConcurrentHashMap<Long, Long>()

        fun expect(requestId: Long, attachment: Long? = null) {
            check(latches.putIfAbsent(requestId, CountDownLatch(1)) == null) {
                "duplicate producer request=$requestId"
            }
            if (attachment != null) expectedAttachments[requestId] = attachment
        }

        override fun onProduced(
            frame: KeyguardOrbBufferProducerFrame,
            buffer: HardwareBuffer,
            completionFence: SyncFence?,
        ) {
            val requestId = frame.testRequestId ?: return
            if (expectedAttachments[requestId]?.let { it != frame.lease.attachment } == true) return
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
        private val expectedAttachments = java.util.concurrent.ConcurrentHashMap<Long, Long>()

        fun expect(requestId: Long, phase: Float, attachment: Long? = null) {
            check(expectedPhases.putIfAbsent(requestId, phase) == null) { "duplicate request=$requestId" }
            check(latches.putIfAbsent(requestId, CountDownLatch(1)) == null) { "duplicate latch=$requestId" }
            if (attachment != null) expectedAttachments[requestId] = attachment
        }

        override fun onSubmitted(frame: KeyguardOrbBufferProducerFrame) {
            val requestId = frame.testRequestId ?: return
            if (expectedAttachments[requestId]?.let { it != frame.lease.attachment } == true) return
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
