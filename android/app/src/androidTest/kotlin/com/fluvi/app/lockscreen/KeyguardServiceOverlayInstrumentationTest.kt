package com.fluvi.app.lockscreen

import android.Manifest
import android.app.KeyguardManager
import android.app.UiAutomation
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.ColorSpace
import android.graphics.Rect
import android.hardware.display.DisplayManager
import android.hardware.HardwareBuffer
import android.hardware.SyncFence
import android.os.Build
import android.os.ParcelFileDescriptor
import android.os.PowerManager
import android.os.SystemClock
import android.os.Trace
import android.provider.Settings
import android.util.Log
import android.view.MotionEvent
import android.view.InputDevice
import android.view.KeyEvent
import android.view.WindowManager
import android.view.Display
import android.view.inspector.WindowInspector
import android.view.accessibility.AccessibilityWindowInfo
import android.view.accessibility.AccessibilityEvent
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.fluvi.app.R
import com.fluvi.app.lockscreen.material.FluviKeyguardMaterialStore
import com.fluvi.app.lockscreen.material.KeyguardOrbBufferFrameObserver
import com.fluvi.app.lockscreen.material.KeyguardOrbBufferPublicationObserver
import com.fluvi.app.lockscreen.material.KeyguardOrbBufferProducerFrame
import com.fluvi.app.lockscreen.material.KeyguardOrbBufferRendererTestHooks
import com.fluvi.app.lockscreen.material.KeyguardOrbMaterialTimeSource
import com.fluvi.app.lockscreen.material.KeyguardMaterialTime
import com.fluvi.app.lockscreen.material.NoopKeyguardOrbBufferFrameObserver
import com.fluvi.app.lockscreen.material.NoopKeyguardOrbBufferPublicationObserver
import com.fluvi.app.lockscreen.material.SystemKeyguardOrbMaterialTimeSource
import com.fluvi.app.lockscreen.material.KeyguardMaterialProfile
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.time.Duration
import java.util.concurrent.TimeUnit

/**
 * Disposable API-35 emulator fixture, NOT a replacement host or a phone
 * performance assertion. Android binds the production AccessibilityService;
 * its actual reader/classifier must authorize the actual accessibility window.
 * No window manager, clock, GPU preparer, or commit callback is faked. The
 * ordered occlusion regression appends one controlled NEGATIVE snapshot;
 * positive recovery still requires the real reader/classifier/admission.
 *
 * The CI runner sets density=420 before launching this process and starts a
 * finite system trace. Only effect/Portal/mode/raster size match the known
 * phone workload: the synthetic palette/Portal controls below are NOT claimed
 * to reproduce the user's unprovided full material profile.
 */
@RunWith(AndroidJUnit4::class)
class KeyguardServiceOverlayInstrumentationTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val context get() = instrumentation.targetContext
    private lateinit var automation: UiAutomation
    private lateinit var output: File
    private var deadline = 0L
    private var captureId = "not-started"
    private val evidence = StringBuilder()
    private val knownOwnWindowIds = mutableSetOf<Int>()
    private val terminalObservationRetention = TerminalObservationRetention()
    private var nextTerminalObservationId = 0L
    private var nextSleepAdmissionEpisodeId = 0L
    private var occlusionProbe: OcclusionSuccessorProbe? = null
    private val keyguard get() = context.getSystemService(KeyguardManager::class.java)
    private val power get() = context.getSystemService(PowerManager::class.java)
    private val component get() = ComponentName(context, FluviKeyguardCardService::class.java).flattenToString()

    @Test fun connectedProductionServiceRendersPortalOrbAcrossRealKeyguardCycles() {
        assertEquals("This fixture is pinned to API 35", 35, Build.VERSION.SDK_INT)
        // This must be the FIRST UiAutomation request. The default flags
        // suppress the very accessibility service this test needs to exercise.
        automation = instrumentation.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        automation.serviceInfo = automation.serviceInfo.apply {
            flags = flags or AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
        }
        output = File(context.filesDir, "keyguard-service-probe").apply { mkdirs() }
        // This is one budget for the whole real-service scenario, including
        // 30 independently attached/showing/live/withdrawn rapid cycles.
        // Per-boundary waits below deliberately retain their tighter limits;
        // this is not a relaxation of any individual failure condition.
        deadline = SystemClock.uptimeMillis() + SERVICE_SCENARIO_BUDGET_MS
        val resolver = context.contentResolver
        val savedServices = Settings.Secure.getString(resolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        val savedEnabled = Settings.Secure.getString(resolver, Settings.Secure.ACCESSIBILITY_ENABLED)
        val savedLockDisabled = shell("locksettings get-disabled").trim()
        val savedSettings = snapshotPreferences("fluvi_native_keyguard_card")
        val savedMaterial = snapshotPreferences("fluvi_keyguard_header_material")
        var captureStarted = false
        var testFailure: Throwable? = null
        // The real service is constructed below by Android.  This bounded
        // probe reads exactly two completed current-attachment producer
        // buffers off Main, then lets the existing compositor assertion tell
        // us whether the producer or the layer/transaction boundary froze.
        val producerProbe = ProducerPixelProbe()
        val controlledTime = ControlledMaterialTimeSource(materialTime(PHASE_A))
        KeyguardOrbBufferRendererTestHooks.frameObserver = producerProbe
        KeyguardOrbBufferRendererTestHooks.publicationObserver = producerProbe
        KeyguardOrbBufferRendererTestHooks.materialTimeSource = controlledTime
        try {
            terminalObservationRetention.reset()
            assertFalse("Secure credentials require a different, explicit fixture", keyguard.isDeviceSecure)
            assertTrue("Cannot safely restore unknown lockscreen setting: $savedLockDisabled",
                savedLockDisabled == "true" || savedLockDisabled == "false")
            assertEquals("Runner must set density=420; do not resize the production View", 168,
                context.resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_orb_size))
            // Preserve unrelated services, and remove only our component while
            // constructing a genuine new service/renderer lifetime.
            setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, withoutOurService(savedServices))
            await("previous service disconnected", 8_000) { !FluviKeyguardCardServiceRegistry.connected }
            shell("input keyevent KEYCODE_WAKEUP")
            shell("wm dismiss-keyguard")
            await("initial unlocked state", 5_000) { power.isInteractive && !keyguard.isKeyguardLocked }
            shell("locksettings set-disabled false")
            instrumentation.runOnMainSync {
                val settings = FluviKeyguardCardSettings.update(context, mapOf(
                    "requested" to true,
                    "showFinancialDetails" to true,
                    "presentationMode" to "orb",
                    "animationMode" to "orbOnly",
                ))
                assertTrue("Fixture must authorize full palette while unlocked", settings.showFinancialDetails)
                val epoch = maxOf(SystemClock.elapsedRealtimeNanos(),
                    (savedMaterial.second["publisherEpoch"] as? Long ?: -1L) + 1L)
                assertTrue("Production profile decoder rejected controlled Portal workload",
                    FluviKeyguardMaterialStore.publish(context, materialProfile(), epoch))
            }
            val profile = requireNotNull(FluviKeyguardMaterialStore.read(context))
            assertTrue(profile.usesPortal)
            assertEquals("dualTide", profile.effectId)
            val started = KeyguardCardDiagnostics.startCapture(context,
                InstrumentationRegistry.getArguments().getString("sourceSha") ?: "instrumentation-source-unprovided",
                "debug", "LIGHT")
            captureStarted = true
            captureId = started["captureId"].toString()
            record("SETUP", "pid=${android.os.Process.myPid()} api=${Build.VERSION.SDK_INT}" +
                " densityDpi=${context.resources.displayMetrics.densityDpi} raster=168x168" +
                " effect=dualTide portal=true animationMode=orbOnly presentation=ORB" +
                " paletteAndPortalControls=SYNTHETIC_NOT_EXACT_PHONE_PROFILE")
            marked("service-connect") {
                val services = withoutOurService(savedServices).split(':').filter { it.isNotBlank() } + component
                setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, services.joinToString(":"))
                setSecure(Settings.Secure.ACCESSIBILITY_ENABLED, "1")
                await("Android-bound production service", 10_000) { FluviKeyguardCardServiceRegistry.connected }
            }

            // One controlled NEGATIVE snapshot establishes the exact older
            // OCCLUDED -> newer pending event -> Main apply ordering. Recovery
            // still uses the real reader, classifier and fresh admission.
            occlusionProbe = OcclusionSuccessorProbe(wasVisible = false).also { it.install() }
            val cold = episode("cold", occlusionProbe)
            occlusionProbe?.close()
            occlusionProbe = null
            val currentLease = producerProbe.awaitCurrentLease()
            val requestA = producerProbe.arm(currentLease, PHASE_A)
            controlledTime.submit(requestA.requestId, materialTime(PHASE_A))
            val producerA = producerProbe.await(requestA)
            producerProbe.persist(output, "producer-a", producerA)
            producerProbe.awaitSubmitted(requestA)
            val liveA = awaitLive("phase-a-current-lease", cold.material, minimumAdvances = 1, expectedWindowId = cold.window.id)
            val firstImage = awaitOrb(cold.window, "cold-orb-a.png") { hasColoredMaterial(it) }
            val requestC = producerProbe.arm(currentLease, PHASE_C)
            controlledTime.submit(requestC.requestId, materialTime(PHASE_C))
            val producerC = producerProbe.await(requestC)
            producerProbe.persist(output, "producer-c", producerC)
            producerProbe.awaitSubmitted(requestC)
            val liveC = awaitLive("phase-c-current-lease", liveA, minimumAdvances = 1, expectedWindowId = cold.window.id)
            val imageC = awaitOrb(cold.window, "cold-orb-c.png") {
                compareOrbPixels(firstImage, it).nearlyEqual()
            }
            // A quiet, explicitly marked interval, not a FPS target. No
            // diagnostic polling, input, screenshots or window reads during
            // this interval; system trace owns its frame/thread attribution.
            marked("steady-live") {
                assertTrue("Insufficient fixture budget for the full quiet interval",
                    deadline - SystemClock.uptimeMillis() >= 10_000L)
                SystemClock.sleep(10_000)
            }
            val steady = snapshot("after-steady-live")
            assertEquals("LIVE must survive the quiet interval", "LIVE", steady.state)
            assertTrue("Quiet interval must produce additional current-renderer output",
                steady.actualOutputCount() > cold.material.actualOutputCount() &&
                    steady.actualProgressCount() > cold.material.actualProgressCount())
            assertEquals("API-35 standalone ORB must use the isolated production renderer",
                "HardwareBufferRenderer/SurfaceControl", steady.activeRenderer)
            val requestB = producerProbe.arm(currentLease, PHASE_B)
            controlledTime.submit(requestB.requestId, materialTime(PHASE_B))
            val producerB = producerProbe.await(requestB)
            producerProbe.persist(output, "producer-b", producerB)
            producerProbe.awaitSubmitted(requestB)
            val liveB = awaitLive("phase-b-current-lease", steady, minimumAdvances = 1, expectedWindowId = cold.window.id)
            val secondImage = awaitOrb(requireOverlay(), "cold-orb-b.png") {
                compareOrbPixels(firstImage, it).meaningful()
            }
            val requestReturnA = producerProbe.arm(currentLease, PHASE_A)
            controlledTime.submit(requestReturnA.requestId, materialTime(PHASE_A))
            val producerReturn = producerProbe.await(requestReturnA)
            producerProbe.persist(output, "producer-return-a", producerReturn)
            producerProbe.awaitSubmitted(requestReturnA)
            val liveReturnA = awaitLive("phase-return-a-current-lease", liveB, minimumAdvances = 1, expectedWindowId = cold.window.id)
            val imageReturnA = awaitOrb(requireOverlay(), "cold-orb-return-a.png") {
                compareOrbPixels(firstImage, it).nearlyEqual()
            }

            // All producer buffers and actual composed crops are persisted
            // before an oracle assertion can stop this lifecycle scenario.
            val plateau = producerProbe.compare(producerA, producerC)
            val producer = producerProbe.compare(producerA, producerB)
            val returnDelta = producerProbe.compare(producerA, producerReturn)
            record(
                "PRODUCER_READBACK",
                "aToC=$plateau aToB=$producer returnToA=$returnDelta " +
                    "requestIds=${producerA.frame.testRequestId}/${producerC.frame.testRequestId}/" +
                    "${producerB.frame.testRequestId}/${producerReturn.frame.testRequestId} testOnlyOffMain=true",
            )
            try {
                assertTrue("A/C producer plateau exceeded equality tolerance: $plateau", plateau.nearlyEqual())
                assertTrue(
                    "Producer shader buffer did not change across canonical phases " +
                        "(changed=${producer.changedPixels}, delta=${producer.pixelDelta})",
                    producer.meaningful(),
                )
                assertTrue("A-B-A producer return exceeded equality tolerance: $returnDelta", returnDelta.nearlyEqual())
                val compositorA = firstImage
                val compositorC = imageC
                val compositorB = secondImage
                val compositorReturnA = imageReturnA
                assertTrue("A compositor crop contains no nonempty material", hasColoredMaterial(compositorA))
                assertTrue("B compositor crop contains no nonempty material", hasColoredMaterial(compositorB))
                val compositorPlateau = compareOrbPixels(compositorA, compositorC)
                val compositorMotion = compareOrbPixels(compositorA, compositorB)
                val compositorReturn = compareOrbPixels(compositorA, compositorReturnA)
                assertTrue("A/C compositor plateau exceeded equality tolerance: $compositorPlateau", compositorPlateau.nearlyEqual())
                assertTrue("Actual composited orb did not change A to B: $compositorMotion", compositorMotion.meaningful())
                assertTrue("A-B-A compositor return exceeded equality tolerance: $compositorReturn", compositorReturn.nearlyEqual())
                record("PIXEL_SAMPLE", "aToC=$compositorPlateau aToB=$compositorMotion returnToA=$compositorReturn" +
                    " progressA=${liveA.actualProgressCount()} progressC=${liveC.actualProgressCount()}" +
                    " progressB=${liveB.actualProgressCount()} progressReturn=${liveReturnA.actualProgressCount()}" +
                    " note=display-crops-not-a-physical-phone-FPS-proof")
            } finally {
                firstImage?.recycle()
                imageC?.recycle()
                secondImage?.recycle()
                imageReturnA?.recycle()
            }
            // A real touch is delivered to the production accessibility root.
            marked("orb-short-tap") { tap(cold.window.bounds) }
            awaitLive("after-tap", steady, minimumAdvances = 1, expectedWindowId = cold.window.id)
            assertEquals("Short orb tap must retain its attachment", cold.window.id, requireOverlay().id)
            val recoveredCold = recoverFromVisibleOcclusion(cold)
            blockedRecurringReaderDoesNotOwnMain(recoveredCold)
            unlockAndAssertWithdrawn("cold-unlock")
            // Retention intentionally keeps first + latest three attempts;
            // setup/terminal signals can otherwise evict this actual cold
            // episode before the final export. Save one bounded existing
            // snapshot while detached, off main, outside timing scenarios.
            marked("cold-report-checkpoint") {
                instrumentation.runOnMainSync { }
                File(output, "cold-capture.txt").writeText(
                    KeyguardCardDiagnostics.captureSnapshot(context)["report"].toString(),
                )
            }

            val warm = episode("warm")
            blockedRecurringReaderDoesNotOwnMain(warm, unknownWithdrawal = true)
            unlockAndAssertWithdrawn("warm-unlock")
            // Start a real wake and revoke it promptly, without waiting for
            // acquisition/preparation. A late result must not leave a window
            // on the unlocked display. No synthetic inspection is injected.
            marked("rapid-wake-unlock") {
                screenOff()
                shell("input keyevent KEYCODE_WAKEUP")
                await("rapid display wake", 3_000) { power.isInteractive }
                shell("wm dismiss-keyguard")
                await("rapid unlock", 3_000) { !keyguard.isKeyguardLocked }
                await("rapid terminal withdrawal", 5_000) { overlaysWithdrawn() }
            }
            // wm dismiss-keyguard returns before SystemUI finishes its
            // asynchronous exit. This is a bounded accepted observation, not
            // a claim that Android remains unlocked after it. The independent
            // episode below owns a fresh locked admission and current output.
            marked("fixture-platform-settle") {
                val settleDeadline = minOf(deadline, SystemClock.uptimeMillis() + 5_000L)
                val initialRemaining = settleDeadline - SystemClock.uptimeMillis()
                assertTrue("Fixture budget exhausted before platform settling", initialRemaining >= 500L)
                record("FIXTURE_TERMINAL_DISMISS", "globalIdle=notRequired")
                shell("wm dismiss-keyguard")
                val terminalRemaining = settleDeadline - SystemClock.uptimeMillis()
                assertTrue("Fixture budget exhausted before terminal platform state", terminalRemaining > 0L)
                var acceptedObservation: TerminalReentryObservation? = null
                await("independent reentry terminal unlocked withdrawal", terminalRemaining) {
                    val observation = collectTerminalReentryObservation(
                        observationId = ++nextTerminalObservationId,
                        terminalDeadlineUptimeMs = settleDeadline,
                    )
                    terminalObservationRetention.retain(observation)
                    if (observation.accepted) {
                        acceptedObservation = observation
                        true
                    } else false
                }
                val terminalObservation = requireNotNull(acceptedObservation) {
                    "terminal observation await returned without an accepted sample"
                }
                terminalObservationRetention.finish(terminalObservation)
                assertTrue("Accepted terminal observation must be unlocked and locally withdrawn",
                    terminalObservation.accepted)
                assertFalse("Accepted terminal observation must retain its first keyguard reading",
                    terminalObservation.keyguardLockedBefore)
                assertFalse("Accepted terminal observation must retain its second keyguard reading",
                    terminalObservation.keyguardLockedAfter)
                assertFalse("Accepted terminal observation must withdraw the service attachment",
                    terminalObservation.serviceAttached)
                assertEquals("Accepted terminal observation must withdraw the process root", 0,
                    terminalObservation.processOverlayRootCount)
                record("FIXTURE_TERMINAL_OBSERVATION_ACCEPTED", terminalObservation.evidenceFields())
                // This public fixture's next wake needs the app-owned layer
                // withdrawn, not eventual convergence of UiAutomation's
                // remote window metadata. API35 can retain a known, already
                // removed accessibility-window id after removeViewImmediate;
                // the strict remote-metadata predicate remains required by
                // every production withdrawal assertion below.
                record("FIXTURE_TERMINAL_WITHDRAWAL",
                    "observationId=${terminalObservation.observationId}" +
                        " serviceAttached=${terminalObservation.serviceAttached}" +
                        " processOverlayRootCount=${terminalObservation.processOverlayRootCount}" +
                        " remoteOverlayIds=${terminalObservation.remoteOverlayIds}")
            }
            val reentry = episode("reattach-after-rapid")
            assertTrue("Warm reentry must advance actual current-renderer output",
                reentry.material.actualOutputCount() > warm.material.actualOutputCount())
            unlockAndAssertWithdrawn("final-unlock")
            exerciseRapidLifecycleCycles(reentry)
            record("RESULT", "OUTPUT_LIVENESS_PASS performanceAndNothingDevice=UNVERIFIED")
        } catch (failure: Throwable) {
            testFailure = failure
            record("RESULT", "FAIL ${failure.javaClass.simpleName}:${failure.message}")
            throw failure
        } finally {
            KeyguardOrbBufferRendererTestHooks.frameObserver = NoopKeyguardOrbBufferFrameObserver
            KeyguardOrbBufferRendererTestHooks.publicationObserver = NoopKeyguardOrbBufferPublicationObserver
            KeyguardOrbBufferRendererTestHooks.materialTimeSource = SystemKeyguardOrbMaterialTimeSource
            occlusionProbe?.close()
            occlusionProbe = null
            terminalObservationRetention.emit { detail ->
                record("FIXTURE_TERMINAL_OBSERVATION", detail)
            }
            var cleanupFailure: Throwable? = null
            // Freeze before restoring settings so the report retains only the
            // controlled workload. Never block the main thread on export.
            if (captureStarted) runCatching {
                val report = KeyguardCardDiagnostics.freezeCapture(context)["report"].toString()
                File(output, "capture.txt").writeText(report)
                if (testFailure == null) {
                    // This fixture explicitly finishes with terminal removal.
                    // Require its Main-owned withdrawal evidence, not just
                    // disappearance from the accessibility metadata list.
                    val episodes = report.lineSequence().filter { it.startsWith(" EPISODE ") }.toList()
                    assertTrue("Completed fixture lost all episode evidence", episodes.isNotEmpty())
                    // The bounded reducer may retain a newly opened current
                    // episode beside completed ones when the capture freezes.
                    // Each terminal and rapid-cycle withdrawal is asserted at
                    // its actual window/root boundary above. The final export
                    // must retain at least one completed actual withdrawal;
                    // it must not reinterpret a concurrent open episode as a
                    // failed terminal removal.
                    assertTrue("Completed terminal fixture lacks retained withdrawal evidence", episodes.any {
                        !it.contains(" withdrawal=NA") && !it.contains(" removeReturn=NA")
                    })
                }
                report.lineSequence().filter { it.startsWith("ATTEMPT ") || it.startsWith(" EPISODE ") ||
                    it.startsWith("DRAW_") || it.startsWith("RENDER_") }.forEach { Log.i(TAG, it) }
            }.onFailure {
                cleanupFailure = it
                record("EXPORT_FAILED", it.javaClass.simpleName + ":" + it.message)
            }
            runCatching {
                setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, withoutOurService(savedServices))
                val end = SystemClock.uptimeMillis() + 5_000L
                while (FluviKeyguardCardServiceRegistry.connected && SystemClock.uptimeMillis() < end) SystemClock.sleep(50)
                assertFalse("Service must stop before preference restoration", FluviKeyguardCardServiceRegistry.connected)
                restorePreferences(savedSettings)
                restorePreferences(savedMaterial)
            }.onFailure {
                cleanupFailure = it
                record("RESTORE_FAILED", it.javaClass.simpleName + ":" + it.message)
            }
            runCatching {
                shell("input keyevent KEYCODE_WAKEUP")
                shell("wm dismiss-keyguard")
                if (savedLockDisabled == "true" || savedLockDisabled == "false") {
                    shell("locksettings set-disabled $savedLockDisabled")
                }
                setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, savedServices)
                setSecure(Settings.Secure.ACCESSIBILITY_ENABLED, savedEnabled)
            }.onFailure {
                cleanupFailure = it
                record("RESTORE_FAILED", it.javaClass.simpleName + ":" + it.message)
            }
            File(output, "fixture.txt").writeText(evidence.toString())
            cleanupFailure?.let { if (testFailure == null) throw AssertionError("Fixture cleanup/export failed", it) }
        }
    }

    private data class Material(
        /** Legacy View-owned actual shader draw count. */
        val shader: Long,
        /** Legacy View-owned phase advance count. */
        val phase: Long,
        /** Exact child-layer buffer submissions for the API-34 isolated path. */
        val isolatedPublished: Long,
        /** Bounded worker-slot state, sampled only at test observation boundaries. */
        val isolatedProduced: Long,
        val isolatedDropped: Long,
        val isolatedInFlight: Long,
        val isolatedReady: Long,
        val isolatedCompositorOwned: Long,
        val isolatedWorkerRunning: Boolean,
        val isolatedWorkerDesiredAttachment: Long,
        val isolatedWorkerDesiredGeneration: Long,
        val isolatedWorkerAttachedAttachment: Long,
        val isolatedWorkerAttachedGeneration: Long,
        val state: String,
        val hardware: Boolean,
        val activeRenderer: String?,
        val effect: String?,
        val generatedAgslHash: String?,
    ) {
        /** The isolated path must not borrow old View counters to pass its
         * output assertion.  The legacy route retains its established proof. */
        fun actualOutputCount(): Long = if (isolatedPublished > 0L) isolatedPublished else shader
        fun actualProgressCount(): Long = if (isolatedPublished > 0L) isolatedPublished else phase
    }

    /**
     * Boundary evidence only: the renderer calls this on its HandlerThread
     * after HardwareBufferRenderer reports SUCCESS.  The supplied fence is
     * awaited but never closed here because the real SurfaceControl
     * transaction remains its owner. It copies only an explicitly requested
     * phase, so readback is bounded and absent from performance runs.
     */
    /**
     * The renderer worker reads one immutable test sample per submission. The
     * ThreadLocal retains that exact sample only long enough for the renderer
     * to attach its request id to the resulting producer frame; the whole
     * source is test-only and the global hook is restored in finally.
     */
    private class ControlledMaterialTimeSource(initial: KeyguardMaterialTime) : KeyguardOrbMaterialTimeSource {
        private data class Sample(val requestId: Long?, val materialTime: KeyguardMaterialTime)

        private val selected = java.util.concurrent.atomic.AtomicReference(Sample(null, initial))
        private val submittedOnRenderer = ThreadLocal<Sample?>()

        fun submit(requestId: Long, materialTime: KeyguardMaterialTime) {
            selected.set(Sample(requestId, materialTime))
        }

        override fun timeAt(scene: com.fluvi.app.lockscreen.material.KeyguardMaterialScene, frameTimeNanos: Long): KeyguardMaterialTime {
            val sample = selected.get()
            submittedOnRenderer.set(sample)
            return sample.materialTime
        }

        override fun testRequestIdFor(materialTime: KeyguardMaterialTime): Long? =
            submittedOnRenderer.get()?.takeIf { it.materialTime === materialTime }?.requestId
    }

    private class ProducerPixelProbe :
        KeyguardOrbBufferFrameObserver,
        KeyguardOrbBufferPublicationObserver {
        data class Sample(
            val frame: KeyguardOrbBufferProducerFrame,
            val pixels: IntArray,
        )

        data class Result(
            val leaseAttachment: Long,
            val leaseGeneration: Long,
            val firstSlot: Long,
            val secondSlot: Long,
            val firstUse: Long,
            val secondUse: Long,
            val firstPhase: Float,
            val secondPhase: Float,
            val pixelDelta: Long,
            val changedPixels: Int,
            val maximumDelta: Int,
            val firstSignature: PixelSignature,
            val secondSignature: PixelSignature,
        ) {
            fun meaningful(): Boolean = changedPixels >= 64 && pixelDelta >= 2_048L
            fun nearlyEqual(): Boolean = maximumDelta <= 2 && pixelDelta <= 2_048L
        }

        /** Compact content evidence that distinguishes a frozen material from
         * a transparent/no-op RenderNode result without retaining pixels. */
        data class PixelSignature(
            val hash: Int,
            val nonTransparent: Int,
            val nonBlack: Int,
        )

        private val requests = KeyguardProducerSampleRequestBook<Sample>()
        private val pendingPublication = java.util.concurrent.atomic.AtomicReference<SubmissionRequest?>(null)
        private val latestFrame = java.util.concurrent.atomic.AtomicReference<KeyguardOrbBufferProducerFrame?>(null)

        private class SubmissionRequest(
            private val producer: KeyguardProducerSampleRequestBook.Request<Sample>,
        ) {
            private val completed = java.util.concurrent.CountDownLatch(1)
            private val submitted = java.util.concurrent.atomic.AtomicReference<KeyguardOrbBufferProducerFrame?>(null)

            fun matches(frame: KeyguardOrbBufferProducerFrame): Boolean =
                producer.expectedLease == frame.lease &&
                    producer.requestId == frame.testRequestId &&
                    kotlin.math.abs(producer.expectedPhase - frame.materialTime.phase) <= .0001f

            fun complete(frame: KeyguardOrbBufferProducerFrame) {
                submitted.set(frame)
                completed.countDown()
            }

            fun await(timeoutMs: Long): KeyguardOrbBufferProducerFrame {
                check(completed.await(timeoutMs, TimeUnit.MILLISECONDS)) {
                    "requested frame was not submitted request=${producer.requestId} " +
                        "phase=${producer.expectedPhase}"
                }
                return requireNotNull(submitted.get()) { "submission completed without a frame" }
            }
        }

        data class Request(
            val producer: KeyguardProducerSampleRequestBook.Request<Sample>,
            private val submission: SubmissionRequest,
            private val clearPending: () -> Unit,
        ) {
            val requestId: Long get() = producer.requestId

            fun awaitSubmission(timeoutMs: Long): KeyguardOrbBufferProducerFrame =
                submission.await(timeoutMs)

            fun clearPendingSubmission() = clearPending()
        }

        override fun onProduced(
            frame: KeyguardOrbBufferProducerFrame,
            buffer: HardwareBuffer,
            completionFence: SyncFence?,
        ) {
            latestFrame.set(frame)
            // Retain the exact request object through the readback. Its
            // request id was captured at submission with this material time;
            // a later A/B/A request cannot be inferred from a phase value.
            val request = requests.current() ?: return
            if (!requests.matches(request, frame)) return
            try {
                // The public renderer contract requires waiting before the
                // buffer is consumed.  This runs off Main and does not take
                // ownership of (or close) the fence handed to SurfaceControl.
                check(completionFence?.await(Duration.ofSeconds(2)) != false) {
                    "producer completion fence did not signal"
                }
                val hardware = checkNotNull(Bitmap.wrapHardwareBuffer(
                    buffer,
                    ColorSpace.get(ColorSpace.Named.SRGB),
                )) { "HardwareBuffer readback returned null" }
                val software = try {
                    checkNotNull(hardware.copy(Bitmap.Config.ARGB_8888, false)) {
                        "HardwareBuffer software copy returned null"
                    }
                } finally {
                    hardware.recycle()
                }
                try {
                    val pixels = IntArray(software.width * software.height)
                    software.getPixels(pixels, 0, software.width, 0, 0, software.width, software.height)
                    val sample = Sample(frame, pixels)
                    requests.completeIfCurrent(request, frame, sample)
                } finally {
                    software.recycle()
                }
            } catch (error: Throwable) {
                // A stale readback may finish after the caller has replaced
                // its request. It must not report failure into the successor.
                requests.failIfCurrent(request, error)
            }
        }

        override fun onSubmitted(frame: KeyguardOrbBufferProducerFrame) {
            val request = pendingPublication.get() ?: return
            if (!request.matches(frame) || !pendingPublication.compareAndSet(request, null)) return
            request.complete(frame)
        }

        fun awaitCurrentLease(): com.fluvi.app.lockscreen.material.KeyguardOrbBufferLease {
            val deadline = SystemClock.uptimeMillis() + 8_000L
            var latest = latestFrame.get()
            while ((latest == null || latest.lease.attachment == 0L) && SystemClock.uptimeMillis() < deadline) {
                SystemClock.sleep(20)
                latest = latestFrame.get()
            }
            return requireNotNull(latest?.lease) { "producer never observed a current lease" }
        }

        fun arm(
            lease: com.fluvi.app.lockscreen.material.KeyguardOrbBufferLease,
            phase: Float,
        ): Request {
            val producer = requests.arm(lease, phase)
            val submission = SubmissionRequest(producer)
            check(pendingPublication.compareAndSet(null, submission)) {
                "a publication acknowledgement is already pending"
            }
            return Request(producer, submission) {
                pendingPublication.compareAndSet(submission, null)
            }
        }

        fun await(request: Request): Sample = requests.await(request.producer)

        fun awaitSubmitted(request: Request): KeyguardOrbBufferProducerFrame =
            try {
                request.awaitSubmission(8_000L)
            } finally {
                request.clearPendingSubmission()
            }

        fun compare(first: Sample, second: Sample): Result {
            assertEquals("Producer samples must belong to the same current lease",
                first.frame.lease, second.frame.lease)
            var changed = 0
            var delta = 0L
            var maximum = 0
            first.pixels.indices.forEach { index ->
                val a = first.pixels[index]
                val b = second.pixels[index]
                val current = maxOf(
                    kotlin.math.abs((a ushr 16 and 0xff) - (b ushr 16 and 0xff)),
                    kotlin.math.abs((a ushr 8 and 0xff) - (b ushr 8 and 0xff)),
                    kotlin.math.abs((a and 0xff) - (b and 0xff)),
                )
                if (current >= 7) changed += 1
                delta += current
                maximum = maxOf(maximum, current)
            }
            return Result(
                leaseAttachment = first.frame.lease.attachment,
                leaseGeneration = first.frame.lease.generation,
                firstSlot = first.frame.slotId,
                secondSlot = second.frame.slotId,
                firstUse = first.frame.useGeneration,
                secondUse = second.frame.useGeneration,
                firstPhase = first.frame.materialTime.phase,
                secondPhase = second.frame.materialTime.phase,
                pixelDelta = delta,
                changedPixels = changed,
                maximumDelta = maximum,
                firstSignature = signature(first.pixels),
                secondSignature = signature(second.pixels),
            )
        }

        fun persist(directory: File, label: String, sample: Sample) {
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

        private fun signature(pixels: IntArray): PixelSignature {
            var nonTransparent = 0
            var nonBlack = 0
            pixels.forEach { pixel ->
                if ((pixel ushr 24) != 0) nonTransparent += 1
                if ((pixel and 0x00ffffff) != 0) nonBlack += 1
            }
            return PixelSignature(pixels.contentHashCode(), nonTransparent, nonBlack)
        }
    }

    private inner class OcclusionSuccessorProbe(private val wasVisible: Boolean) : KeyguardInspectionProbeForTest {
        private val service = checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation())
        private val selected = java.util.concurrent.atomic.AtomicReference<KeyguardCardInspectionRequest?>()
        private val expected = java.util.concurrent.atomic.AtomicReference<KeyguardCardInspectionRequest?>()
        private val failure = java.util.concurrent.atomic.AtomicReference<Throwable?>()
        private val applied = java.util.concurrent.CountDownLatch(1)
        private val successorStarted = java.util.concurrent.CountDownLatch(1)
        private var before: KeyguardInspectionStateForTest? = null
        private var pendingEvent: KeyguardCardInspectionRequest? = null

        fun install() { service.inspectionProbeForTest = this }
        fun close() { if (service.inspectionProbeForTest === this) service.inspectionProbeForTest = null }

        override fun snapshots(request: KeyguardCardInspectionRequest, actual: List<KeyguardWindowSnapshot>): List<KeyguardWindowSnapshot> {
            if (selected.get() != null) return actual
            // Data-minimized acquisition fixture, explicitly NOT a real foreign
            // window/performance sample. The production classifier decides it.
            return actual + KeyguardWindowSnapshot(
                packageName = "fixture.foreign.occluder", type = 1, layer = Int.MAX_VALUE,
                displayId = 0, windowId = 990035,
            )
        }

        override fun beforeApply(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility) {
            if (decision != KeyguardCardVisibility.HIDDEN_OCCLUDED ||
                !service.inspectionStateForTest().authority.matches(request) ||
                !selected.compareAndSet(null, request)) return
            runCatching {
                assertEquals("Controlled acquisition must reach the production occlusion classifier", KeyguardCardVisibility.HIDDEN_OCCLUDED, decision)
                val state = service.inspectionStateForTest()
                assertTrue("Older negative must still own its delivery", state.authority.matches(request))
                assertEquals(wasVisible, state.attached)
                assertTrue("A real eligible wake must already exist", state.wake != null)
                before = state
                val event = AccessibilityEvent.obtain(AccessibilityEvent.TYPE_WINDOWS_CHANGED)
                try {
                    event.packageName = "com.android.systemui"
                    event.eventTime = SystemClock.uptimeMillis() - 1L
                    // Runs the actual event gate/scheduler while the cause is
                    // still active. No positive classification is injected.
                    service.onAccessibilityEvent(event)
                } finally { event.recycle() }
                pendingEvent = service.inspectionStateForTest().pending
                assertTrue("Newer event must be pending before older exclusion applies", pendingEvent != null)
            }.onFailure { failure.compareAndSet(null, it) }
        }

        override fun afterApply(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility) {
            if (selected.get()?.id != request.id) return
            runCatching {
                failure.get()?.let { throw it }
                val previous = checkNotNull(before)
                val intent = checkNotNull(pendingEvent)
                val current = service.inspectionStateForTest()
                assertFalse("Occlusion must remain excluded", current.attached)
                assertEquals("Local root is withdrawn before any successor can show", 0,
                    WindowInspector.getGlobalWindowViews().count {
                        (it.layoutParams as? WindowManager.LayoutParams)?.type == WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
                    })
                assertTrue("Recoverable occlusion erased the newer unserved inspection", current.pending != null)
                assertEquals("Recoverable occlusion must not end the wake", previous.wake, current.wake)
                val next = checkNotNull(current.pending)
                assertTrue(current.authority.matches(next))
                if (wasVisible) {
                    assertFalse("Withdrawn generation must be revoked", current.authority.matches(request))
                    assertTrue("Visible withdrawal requires a NEW acquisition request", next.id != intent.id)
                    assertEquals(previous.authority.visibilityEpoch + 1L, current.authority.visibilityEpoch)
                    assertEquals(previous.authority.interactionEpoch + 1L, current.authority.interactionEpoch)
                    assertEquals(KeyguardWindowFreshness.CONTRADICTORY_OBSERVATION, next.windowFreshness)
                } else {
                    assertEquals(previous.authority, current.authority)
                    assertEquals(intent.id, next.id)
                }
                assertEquals(intent.eventTimeUptimeMs, next.eventTimeUptimeMs)
                assertEquals(intent.triggerReceivedUptimeMs, next.triggerReceivedUptimeMs)
                assertEquals(intent.trigger, next.trigger)
                assertEquals(intent.diagnosticContext, next.diagnosticContext)
                assertEquals("Occlusion must not replenish fallback budget", previous.retryCount, current.retryCount)
                expected.set(next)
            }.onFailure { failure.compareAndSet(null, it) }
            applied.countDown()
        }

        override fun started(request: KeyguardCardInspectionRequest) {
            val next = expected.get() ?: return
            // Later real events may coalesce, but never an older owner/result.
            if (request.id >= next.id && request.session == next.session &&
                request.wakeGeneration == next.wakeGeneration && request.visibilityEpoch == next.visibilityEpoch &&
                request.interactionEpoch == next.interactionEpoch && request.attachGeneration == next.attachGeneration) {
                successorStarted.countDown()
            }
        }

        fun awaitSuccessor() {
            assertTrue("Controlled OCCLUDED must reach actual service apply", applied.await(6, java.util.concurrent.TimeUnit.SECONDS))
            failure.get()?.let { throw it }
            assertTrue("Preserved successor must actually start without another test event", successorStarted.await(3, java.util.concurrent.TimeUnit.SECONDS))
            record("OCCLUSION_SUCCESSOR", "visible=$wasVisible cause=${selected.get()?.id} next=${expected.get()?.id} wake=${expected.get()?.wakeGeneration} exclusionRetained=true")
        }
    }
    /** The real service/TYPE_ACCESSIBILITY_OVERLAY must keep drawing BEFORE
     * release of the injected platform read. Independent release bounds RED
     * execution too: the old synchronous Main call cannot hang the runner.
     */
    private fun blockedRecurringReaderDoesNotOwnMain(episode: Episode, unknownWithdrawal: Boolean = false) {
        val entered = java.util.concurrent.CountDownLatch(1)
        val release = java.util.concurrent.CountDownLatch(1)
        val watchdog = java.util.concurrent.Executors.newSingleThreadScheduledExecutor()
        val service = checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation())
        val real = AndroidKeyguardSystemStateReader(context)
        val old = service.systemStateReaderOverride
        val workerRead = java.util.concurrent.atomic.AtomicBoolean(false)
        val unavailableInspection = java.util.concurrent.atomic.AtomicBoolean(false)
        val denyAdmission = java.util.concurrent.atomic.AtomicBoolean(false)
        val withholdNewChecks = java.util.concurrent.atomic.AtomicBoolean(false)
        val admissionRead = java.util.concurrent.CountDownLatch(1)
        service.systemStateReaderOverride = KeyguardSystemStateReader { purpose ->
            // Capture the old positive before blocking. Later *new* checks
            // are separately controlled so a legitimate new wake cannot be
            // mistaken for publication of this revoked answer.
            val withhold = purpose == KeyguardSystemReadPurpose.RECURRING && withholdNewChecks.get()
            val acquired = real.read(purpose)
            if (purpose == KeyguardSystemReadPurpose.RECURRING) {
                workerRead.set(android.os.Looper.myLooper() != android.os.Looper.getMainLooper())
                entered.countDown()
                check(release.await(10, java.util.concurrent.TimeUnit.SECONDS))
            }
            if (withhold || (purpose == KeyguardSystemReadPurpose.INSPECTION && unavailableInspection.get())) {
                KeyguardSystemState(SystemClock.uptimeMillis(), SystemClock.uptimeMillis(), available = false)
            } else {
                val state = acquired
                if (purpose == KeyguardSystemReadPurpose.ADMISSION && denyAdmission.get()) {
                    assertEquals("Admission remains on the View owner", android.os.Looper.getMainLooper(), android.os.Looper.myLooper())
                    admissionRead.countDown()
                    state.copy(keyguardLocked = false)
                } else state
            }
        }
        watchdog.schedule({ release.countDown() }, 8, java.util.concurrent.TimeUnit.SECONDS)
        try {
            val before = snapshot("blocked-reader-before")
            instrumentation.runOnMainSync { service.requestSystemCheckForTest() }
            assertTrue("Recurring reader entered", entered.await(2, java.util.concurrent.TimeUnit.SECONDS))
            assertEquals("Main callback must return before reader release", 1L, release.count)
            assertTrue("Recurring system acquisition must be worker-owned", workerRead.get())
            val blockedBaseline = snapshot("reader-entered-before-draw")
            val after = awaitLive("blocked-reader-live", blockedBaseline, 2, episode.window.id)
            assertEquals("Actual shader output/phase must advance while read remains blocked", 1L, release.count)
            assertTrue(after.actualOutputCount() > blockedBaseline.actualOutputCount() &&
                after.actualProgressCount() > blockedBaseline.actualProgressCount())
            if (unknownWithdrawal) {
                unavailableInspection.set(true)
                instrumentation.runOnMainSync {
                    val event = android.view.accessibility.AccessibilityEvent.obtain(
                        android.view.accessibility.AccessibilityEvent.TYPE_WINDOWS_CHANGED)
                    try { service.onAccessibilityEvent(event) } finally { event.recycle() }
                }
                await("UNKNOWN withdraws before retry eligibility acquisition", 2_000) { overlaysWithdrawn() }
                assertEquals("UNKNOWN withdrawal must not join recurring eligibility work", 1L, release.count)
                instrumentation.runOnMainSync { service.onInterrupt() }
                record("SYSTEM_GATE_REGRESSION", "unknownWithdrawalBeforeRelease=true outputDelta=" +
                    "${after.actualOutputCount() - before.actualOutputCount()}")
                return
            }
            val discreet = FluviKeyguardCardSettings.read(context).copy(showFinancialDetails = false)
            instrumentation.runOnMainSync { service.onSettingsChangedFromApplication(discreet) }
            instrumentation.runOnMainSync {
                val state = service.materialDiagnostics()
                assertEquals("Privacy tightening redacts the existing root", "SHOW_DISCREET", state["appliedVisibility"])
                assertEquals(true, state["overlayAttached"])
                assertEquals("No recurring system read belongs to Main", 0L, state["systemRecurringMainReads"])
                assertEquals(1L, release.count)
            }
            withholdNewChecks.set(true)
            instrumentation.runOnMainSync {
                service.onInterrupt()
                assertEquals("Terminal hide must detach the owner before returning", false,
                    service.materialDiagnostics()["overlayAttached"])
                assertEquals("Actual local WindowManager root must be removed before reader release", 0,
                    WindowInspector.getGlobalWindowViews().count {
                        (it.layoutParams as? WindowManager.LayoutParams)?.type ==
                            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
                    })
                assertEquals(1L, release.count)
            }
            // UiAutomation's remote accessibility-window list can still
            // contain the removed window after removeViewImmediate returned.
            // Require convergence too, without confusing it with local hide.
            await("Terminal remote window metadata removed before reader release", 2_000) { overlaysWithdrawn() }
            assertEquals("Terminal hide never joins the reader", 1L, release.count)
            instrumentation.runOnMainSync { service.onSettingsChangedFromApplication(discreet) }
            instrumentation.runOnMainSync {
                assertEquals("Tightening privacy must not attach a detached root", false,
                    service.materialDiagnostics()["overlayAttached"])
            }
            record("SYSTEM_GATE_REGRESSION", "workerRead=true outputDelta=" +
                "${after.actualOutputCount() - before.actualOutputCount()} progressDelta=" +
                "${after.actualProgressCount() - before.actualProgressCount()} " +
                "hideBeforeRelease=true privacyBeforeRelease=true recurringMainReads=0")
            var rejectedBefore = 0L
            instrumentation.runOnMainSync {
                rejectedBefore = service.materialDiagnostics()["systemSamplerStaleRejected"] as Long
            }
            release.countDown()
            await("late sampler positive rejected after terminal hide", 2_000) {
                var rejected = 0L
                instrumentation.runOnMainSync { rejected = service.materialDiagnostics()["systemSamplerStaleRejected"] as Long }
                rejected > rejectedBefore
            }
            assertTrue("Late positive cannot reattach", overlaysWithdrawn())
            // New event and genuine tree classification may propose SHOW;
            // fresh admission must still veto it after worker-positive delay.
            denyAdmission.set(true)
            withholdNewChecks.set(false)
            instrumentation.runOnMainSync {
                val event = android.view.accessibility.AccessibilityEvent.obtain(
                    android.view.accessibility.AccessibilityEvent.TYPE_WINDOWS_CHANGED)
                try { service.onAccessibilityEvent(event) } finally { event.recycle() }
            }
            assertTrue("Actual new attachment must reach fresh admission", admissionRead.await(6, java.util.concurrent.TimeUnit.SECONDS))
            instrumentation.runOnMainSync { }
            assertTrue("Worker-positive cannot bypass fresh negative admission", overlaysWithdrawn())
            record("SYSTEM_GATE_REGRESSION", "latePositiveRejected=true freshAdmissionVeto=true")
        } finally {
            release.countDown()
            service.systemStateReaderOverride = old
            watchdog.shutdownNow()
        }
    }

    private data class Overlay(val id: Int, val bounds: Rect)
    private data class Episode(val material: Material, val window: Overlay)

    /** Retains only bounded fixture evidence. Records are emitted through the
     * existing finally/export path, so a failed terminal wait keeps its first,
     * state-changing, and final sample without adding work to Main. */
    private class TerminalObservationRetention {
        private val retained = java.util.ArrayDeque<TerminalReentryObservation>()
        private var omitted = 0
        private var latest: TerminalReentryObservation? = null
        private var previousState: String? = null

        fun reset() {
            retained.clear()
            omitted = 0
            latest = null
            previousState = null
        }

        fun retain(observation: TerminalReentryObservation) {
            latest = observation
            val state = observationState(observation)
            if (retained.isEmpty() || state != previousState) offer(observation)
            previousState = state
        }

        fun finish(observation: TerminalReentryObservation) {
            latest = observation
            ensureRetained(observation)
        }

        fun emit(record: (String) -> Unit) {
            val final = latest ?: return
            ensureRetained(final)
            retained.forEachIndexed { index, observation ->
                record("kind=attempt index=$index ${observation.evidenceFields()}")
            }
            record(
                "kind=summary retained=${retained.size} omitted=$omitted " +
                    "finalObservationId=${final.observationId} ${final.evidenceFields()}",
            )
        }

        private fun offer(observation: TerminalReentryObservation) {
            if (retained.size < MAX_TERMINAL_OBSERVATION_RECORDS) retained.addLast(observation)
            else omitted += 1
        }

        private fun ensureRetained(observation: TerminalReentryObservation) {
            if (retained.any { it.observationId == observation.observationId }) return
            if (retained.size == MAX_TERMINAL_OBSERVATION_RECORDS) {
                retained.removeLast()
                omitted += 1
            }
            retained.addLast(observation)
        }

        private fun observationState(observation: TerminalReentryObservation): String =
            "${observation.keyguardLockedBefore}/${observation.keyguardLockedAfter}/" +
                "${observation.serviceAttached}/${observation.processOverlayRootCount}/" +
                "${observation.remoteOverlayIds}/${observation.accepted}/${observation.rejectionReason}"
    }

    private fun recoverFromVisibleOcclusion(previous: Episode): Episode = marked("visible-occlusion-recovery") {
        val service = checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation())
        val probe = OcclusionSuccessorProbe(wasVisible = true)
        occlusionProbe = probe
        try {
            instrumentation.runOnMainSync {
                assertTrue("Visible regression begins on the current live root", service.inspectionStateForTest().attached)
                probe.install()
                val event = AccessibilityEvent.obtain(AccessibilityEvent.TYPE_WINDOWS_CHANGED)
                try {
                    event.packageName = "com.android.systemui"
                    event.eventTime = SystemClock.uptimeMillis()
                    service.onAccessibilityEvent(event)
                } finally { event.recycle() }
            }
            probe.awaitSuccessor()
            // Remote metadata can lag local removal. Do not accidentally
            // accept the old window/cumulative renderer counters as recovery.
            await("withdrawn window metadata replaced", 5_000) {
                val windows = ownOverlays()
                windows.size == 1 && windows.single().id != previous.window.id
            }
            val window = requireOverlay()
            val baseline = snapshot("recovered-attachment-${window.id}")
            val live = awaitLive("occlusion-fresh-recovery", baseline, 2, window.id)
            assertEquals(previous.window.bounds, window.bounds)
            assertEquals("dualTide", live.effect)
            assertEquals(EXPECTED_PORTAL_HASH, live.generatedAgslHash)
            instrumentation.runOnMainSync {
                assertEquals("Recovery retains exactly one actual process root", 1,
                    WindowInspector.getGlobalWindowViews().count {
                        (it.layoutParams as? WindowManager.LayoutParams)?.type == WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
                    })
            }
            record("OCCLUSION_RECOVERY", "oldWindow=${previous.window.id} newWindow=${window.id}" +
                " freshOutputDelta=${live.actualOutputCount() - baseline.actualOutputCount()}" +
                " freshProgressDelta=${live.actualProgressCount() - baseline.actualProgressCount()}")
            Episode(live, window)
        } finally {
            probe.close()
            occlusionProbe = null
        }
    }

    private fun episode(name: String, probe: OcclusionSuccessorProbe? = null): Episode = marked(name) {
        // An unlocked KeyguardManager flag is not completion of the previous
        // remote animation. Runs42856983444 and42865721964 relocked while
        // SystemUI still finished that exit and subsequently returned to GONE.
        // Use the public UiAutomation input contract for independent episodes:
        // it synchronizes window animations/transactions before DOWN and after
        // UP. This is fixture setup, not an app delay, synthetic SHOW, or a
        // physical-presentation measurement. The rapid scenario intentionally
        // retains unsynchronized shell input and immediate exclusion assertions.
        marked("$name-synchronized-sleep") { screenOff(synchronizeInput = true) }
        wakeForIndependentEpisode(name)
        probe?.awaitSuccessor()
        // Material counters and last LIVE/hardware state survive detach.
        // A prior episode's snapshot can therefore be satisfied by draws
        // that happened before its removal. Observe THIS actual attachment
        // first, then require fresh output beyond its own counter baseline.
        val window = awaitOverlay(name)
        val baseline = snapshot("$name-attached-window-${window.id}")
        val material = awaitLive(name, baseline, minimumAdvances = 2, expectedWindowId = window.id)
        assertEquals("Episode must retain the observed attachment", window.id, requireOverlay().id)
        assertEquals("Production overlay width", 168, window.bounds.width())
        assertEquals("Production overlay height", 168, window.bounds.height())
        assertEquals("Actually drawn effect identity", "dualTide", material.effect)
        assertEquals("Actually retained Portal program must match the known phone program",
            EXPECTED_PORTAL_HASH, material.generatedAgslHash)
        assertEquals("API-35 real accessibility overlay must select the isolated ORB backend",
            "HardwareBufferRenderer/SurfaceControl", material.activeRenderer)
        assertTrue("Actual accessibility-overlay attachment published no current buffer output",
            material.isolatedPublished > 0L)
        assertTrue(
            "Actual isolated renderer exceeded its global three-slot resource cap",
            material.isolatedInFlight + material.isolatedReady + material.isolatedCompositorOwned <=
                MAX_ISOLATED_BUFFER_SLOTS,
        )
        record("EPISODE", "name=$name windowId=${window.id} type=TYPE_ACCESSIBILITY_OVERLAY bounds=${window.bounds}" +
            " shader=${material.shader} phase=${material.phase} isolatedPublished=${material.isolatedPublished}" +
            " state=${material.state} hardware=${material.hardware} renderer=${material.activeRenderer}" +
            " effect=${material.effect} generatedAgslHash=${material.generatedAgslHash}")
        Episode(material, window)
    }

    /**
     * Repeats the real service/window path after the calibrated pixel portion
     * has completed. Each iteration has a fresh accessibility attachment,
     * requires current-attachment output, then proves both remote metadata
     * and the owning process root withdrew. No synthetic visibility callback,
     * renderer allocation, or per-cycle resource allowance is introduced.
     */
    private fun exerciseRapidLifecycleCycles(initial: Episode) {
        var previous = initial
        val firstOutput = initial.material.actualOutputCount()
        repeat(RAPID_LIFECYCLE_CYCLES) { index ->
            val name = "rapid-cycle-${index + 1}"
            val current = episode(name)
            assertTrue(
                "$name must advance output beyond the preceding detached attachment",
                current.material.actualOutputCount() > previous.material.actualOutputCount(),
            )
            unlockAndAssertWithdrawn("$name-unlock")
            previous = current
        }
        record(
            "RAPID_LIFECYCLE",
            "cycles=$RAPID_LIFECYCLE_CYCLES firstOutput=$firstOutput " +
                "finalOutput=${previous.material.actualOutputCount()} " +
                "globalSlotCap=$MAX_ISOLATED_BUFFER_SLOTS",
        )
    }

    private fun screenOff(synchronizeInput: Boolean = false) {
        var sleepInputStartedAt = 0L
        if (synchronizeInput) {
            assertTrue("Fixture budget exhausted before independent episode", SystemClock.uptimeMillis() < deadline)
            val downAt = SystemClock.uptimeMillis()
            sleepInputStartedAt = downAt
            for (action in intArrayOf(KeyEvent.ACTION_DOWN, KeyEvent.ACTION_UP)) {
                val event = KeyEvent(downAt, SystemClock.uptimeMillis(), action, KeyEvent.KEYCODE_SLEEP,
                    0, 0, -1, 0, 0, InputDevice.SOURCE_KEYBOARD)
                assertTrue("Synchronized sleep input was rejected", automation.injectInputEvent(event, true))
            }
        } else {
            shell("input keyevent KEYCODE_SLEEP")
        }
        if (synchronizeInput) {
            val budget = IndependentSleepAdmissionBudget(SystemClock.uptimeMillis(), deadline)
            val episodeId = ++nextSleepAdmissionEpisodeId
            record("SLEEP_ADMISSION_BUDGET", "episodeId=$episodeId inputStartedAtUptimeMs=$sleepInputStartedAt waitStartedAtUptimeMs=${budget.startedAtUptimeMs} nonInteractiveDeadlineUptimeMs=${budget.nonInteractiveDeadlineUptimeMs} admissionDeadlineUptimeMs=${budget.admissionDeadlineUptimeMs}")
            val retention = IndependentSleepAdmissionRetention()
            var observationId = 0L
            var accepted: IndependentSleepAdmissionObservation? = null
            var firstNonInteractiveAt: Long? = null
            var failure: Throwable? = null
            try {
                firstNonInteractiveAt = awaitIndependentSleepNonInteractive(
                    deadlineUptimeMs = budget.nonInteractiveDeadlineUptimeMs,
                    uptimeMillis = SystemClock::uptimeMillis,
                    interactive = { power.isInteractive },
                    pauseMillis = SystemClock::sleep,
                )
                if (firstNonInteractiveAt == null) {
                    record("TIMEOUT", "screen off reason=${KeyguardCardDiagnostics.lastReason(context)}")
                    recordFailureWindows("screen off")
                    throw AssertionError("screen off timed out; no classifier or callback bypass is permitted")
                }
                val collector = IndependentSleepAdmissionCollector(
                    uptimeMillis = SystemClock::uptimeMillis,
                    interactive = { power.isInteractive },
                    displayState = {
                        context.getSystemService(DisplayManager::class.java)
                            ?.getDisplay(Display.DEFAULT_DISPLAY)?.state ?: Display.STATE_UNKNOWN
                    },
                    keyguardLocked = { keyguard.isKeyguardLocked },
                )
                while (SystemClock.uptimeMillis() < budget.admissionDeadlineUptimeMs && accepted == null) {
                    val observation = collector.collect(episodeId, ++observationId, budget.admissionDeadlineUptimeMs)
                    retention.retain(observation)
                    if (observation.accepted) {
                        accepted = observation
                    } else {
                        SystemClock.sleep(minOf(100L, (budget.admissionDeadlineUptimeMs - SystemClock.uptimeMillis()).coerceAtLeast(0L)))
                    }
                }
                if (accepted == null) {
                    throw AssertionError("screen-off completed admission timed out; no classifier or callback bypass is permitted")
                }
                // This exact immutable observation is evidence for this setup
                // only; it is never read again or reused as later show authority.
                record("SLEEP_ADMISSION_ACCEPTED", accepted.evidenceFields())
            } catch (error: Throwable) {
                failure = error
                throw error
            } finally {
                retention.observations().forEach {
                    record("SLEEP_ADMISSION_OBSERVATION", it.evidenceFields())
                }
                val final = retention.observations().lastOrNull()
                record(
                    "SLEEP_ADMISSION_FINAL",
                    "episodeId=$episodeId inputStartedAtUptimeMs=$sleepInputStartedAt " +
                        "waitStartedAtUptimeMs=${budget.startedAtUptimeMs} " +
                        "nonInteractiveDeadlineUptimeMs=${budget.nonInteractiveDeadlineUptimeMs} " +
                        "admissionDeadlineUptimeMs=${budget.admissionDeadlineUptimeMs} " +
                        "firstNonInteractiveAtUptimeMs=${firstNonInteractiveAt ?: "NONE"} " +
                        "finalObservationId=${final?.observationId ?: "NONE"} " +
                        "finalAccepted=${accepted?.accepted ?: false} " +
                        "completedObservationCount=${retention.totalCompleted} " +
                        "retainedObservationCount=${retention.observations().size} " +
                        "omittedCompleted=${retention.omittedCompleted()} " +
                        "failure=${failure?.javaClass?.name ?: "NONE"}:${failure?.message ?: "NONE"}",
                )
            }
            // A completed injected SLEEP input and a non-interactive display
            // do not order SystemUI's asynchronous keyguard transition. In
            // run 43242829409, the next synchronized WAKE arrived after the
            // display was OFF but before SystemUI processed STARTED_GOING_TO_
            // SLEEP; it consequently cancelled an old dismissal and never
            // reached the production admission gate. Require the same public
            // KeyguardManager condition that the following wake must satisfy
            // before issuing that next input. The unsynchronised rapid-race
            // scenario deliberately remains unchanged.
            // The immutable OFF/locked/non-interactive bracket above is the
            // complete public admission; it does not authorize later output.
        } else {
            await("screen off", 3_000) { !power.isInteractive }
        }
        await("screen-off withdrawal", 4_000) { overlaysWithdrawn() }
    }

    /**
     * Establishes the public input/idle boundary for an independent episode.
     *
     * A synchronized SLEEP alone does not order the following shell WAKEUP
     * against the tail of SystemUI's preceding dismissal.  Run 43220246563
     * reached the KeyguardManager predicate, then received a late terminal
     * accessibility state which correctly revoked the new episode before it
     * attached.  This is fixture setup only: the rapid wake/unlock regression
     * above deliberately retains its unsynchronised production-event path.
     */
    private fun wakeForIndependentEpisode(name: String) = marked("$name-synchronized-wake") {
        assertTrue("Fixture budget exhausted before independent wake", SystemClock.uptimeMillis() < deadline)
        val downAt = SystemClock.uptimeMillis()
        for (action in intArrayOf(KeyEvent.ACTION_DOWN, KeyEvent.ACTION_UP)) {
            val event = KeyEvent(downAt, SystemClock.uptimeMillis(), action, KeyEvent.KEYCODE_WAKEUP,
                0, 0, -1, 0, 0, InputDevice.SOURCE_KEYBOARD)
            assertTrue("Synchronized wake input was rejected", automation.injectInputEvent(event, true))
        }
        await("$name keyguard eligible device gates", 5_000) {
            power.isInteractive && keyguard.isKeyguardLocked
        }
        val settleDeadline = minOf(deadline, SystemClock.uptimeMillis() + 5_000L)
        val remaining = settleDeadline - SystemClock.uptimeMillis()
        assertTrue("Fixture budget exhausted before independent wake idle", remaining >= 500L)
        // This is an event-idle boundary, not a sleep. It makes late SystemUI
        // terminal events visible before the new real-service episode begins.
        automation.waitForIdle(500L, remaining)
        val postIdleRemaining = settleDeadline - SystemClock.uptimeMillis()
        assertTrue("Fixture budget exhausted after independent wake idle", postIdleRemaining > 0L)
        await("$name keyguard eligibility after public input idle", postIdleRemaining) {
            power.isInteractive && keyguard.isKeyguardLocked
        }
        record("FIXTURE_INDEPENDENT_WAKE_IDLE", "name=$name afterPublicInputIdle=true")
    }

    private fun unlockAndAssertWithdrawn(label: String) = marked(label) {
        shell("wm dismiss-keyguard")
        await("$label unlocked", 4_000) { !keyguard.isKeyguardLocked }
        await("$label overlay removed", 5_000) { overlaysWithdrawn() }
        record("WITHDRAWN", "name=$label keyguardLocked=${keyguard.isKeyguardLocked}" +
            " accessibilityOverlayCount=0 processOverlayRootCount=0")
    }

    private fun overlaysWithdrawn(): Boolean {
        if (ownOverlays().isNotEmpty()) return false
        var roots = -1
        instrumentation.runOnMainSync {
            // Public API29+, actual process WindowManager roots. Accessibility
            // metadata can disappear before removal/diagnostic publication
            // finishes. Observe the owning Main path too, not a fake hide.
            roots = WindowInspector.getGlobalWindowViews().count {
                (it.layoutParams as? WindowManager.LayoutParams)?.type ==
                    WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
            }
        }
        return roots == 0
    }

    /**
     * Terminal setup records one accepted observation. It brackets exactly one
     * Main-owned local-root read with public keyguard reads on the
     * instrumentation thread. Remote metadata has its own timestamp and is
     * evidence only: strict production withdrawal checks continue to use
     * [overlaysWithdrawn].
     */
    private fun collectTerminalReentryObservation(
        observationId: Long,
        terminalDeadlineUptimeMs: Long,
    ): TerminalReentryObservation = TerminalReentryObservationCollector(
        uptimeMillis = { SystemClock.uptimeMillis() },
        keyguardLocked = { keyguard.isKeyguardLocked },
        localObservation = {
            lateinit var local: TerminalReentryLocalObservation
            instrumentation.runOnMainSync {
                val service = checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation()) {
                    "Accessibility service disconnected during terminal fixture"
                }
                local = TerminalReentryLocalObservation(
                    observedAtUptimeMs = SystemClock.uptimeMillis(),
                    serviceAttached = service.inspectionStateForTest().attached,
                    processOverlayRootCount = WindowInspector.getGlobalWindowViews().count {
                        (it.layoutParams as? WindowManager.LayoutParams)?.type ==
                            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
                    },
                )
            }
            local
        },
        remoteObservation = {
            TerminalReentryRemoteObservation(
                observedAtUptimeMs = SystemClock.uptimeMillis(),
                overlayIds = ownOverlays().map { it.id }.toList(),
            )
        },
    ).collect(observationId, terminalDeadlineUptimeMs)

    private fun awaitLive(label: String, baseline: Material, minimumAdvances: Long, expectedWindowId: Int): Material {
        var latest = baseline
        await("$label actual live shader/phase output", 18_000, pollMs = 500) {
            assertEquals("LIVE output must belong to the current attachment", expectedWindowId, requireOverlay().id)
            latest = snapshot(label)
            val advanced = latest.state == "LIVE" && latest.hardware &&
                latest.actualOutputCount() > baseline.actualOutputCount() &&
                latest.actualProgressCount() >= baseline.actualProgressCount() + minimumAdvances
            if (advanced) assertEquals("Attachment must still own the sampled LIVE output", expectedWindowId, requireOverlay().id)
            advanced
        }
        return latest
    }

    private fun awaitOverlay(label: String): Overlay {
        var current: Overlay? = null
        await("$label actual accessibility attachment", 18_000, pollMs = 500) {
            val overlays = ownOverlays()
            assertTrue("Never permit duplicate Fluvi accessibility overlays", overlays.size <= 1)
            current = overlays.singleOrNull()
            current != null
        }
        return checkNotNull(current)
    }

    private fun snapshot(label: String): Material {
        lateinit var material: Material
        instrumentation.runOnMainSync {
            // Explicit test-observer span: coarse waiting/boundary samples,
            // never a production/per-frame poll or an unlabelled Main delay.
            Trace.beginSection("KGProbe.snapshot")
            try {
                val values = FluviKeyguardCardServiceRegistry.materialDiagnostics()
                material = Material(
                    shader = (values["shaderDrawCount"] as? Number)?.toLong() ?: 0L,
                    phase = (values["phaseAdvanceCount"] as? Number)?.toLong() ?: 0L,
                    isolatedPublished = (values["isolatedOrbFramesPublished"] as? Number)?.toLong() ?: 0L,
                    isolatedProduced = (values["isolatedOrbFramesProduced"] as? Number)?.toLong() ?: 0L,
                    isolatedDropped = (values["isolatedOrbFramesDropped"] as? Number)?.toLong() ?: 0L,
                    isolatedInFlight = (values["isolatedOrbFramesInFlight"] as? Number)?.toLong() ?: 0L,
                    isolatedReady = (values["isolatedOrbFramesReady"] as? Number)?.toLong() ?: 0L,
                    isolatedCompositorOwned =
                        (values["isolatedOrbFramesCompositorOwned"] as? Number)?.toLong() ?: 0L,
                    isolatedWorkerRunning = values["isolatedOrbWorkerRunning"] == true,
                    isolatedWorkerDesiredAttachment =
                        (values["isolatedOrbWorkerDesiredAttachment"] as? Number)?.toLong() ?: -1L,
                    isolatedWorkerDesiredGeneration =
                        (values["isolatedOrbWorkerDesiredGeneration"] as? Number)?.toLong() ?: -1L,
                    isolatedWorkerAttachedAttachment =
                        (values["isolatedOrbWorkerAttachedAttachment"] as? Number)?.toLong() ?: -1L,
                    isolatedWorkerAttachedGeneration =
                        (values["isolatedOrbWorkerAttachedGeneration"] as? Number)?.toLong() ?: -1L,
                    state = values["coldPresentationState"].toString(),
                    hardware = values["hardwareAccelerated"] == true,
                    activeRenderer = values["activeRenderer"] as? String,
                    effect = values["effectId"] as? String,
                    generatedAgslHash = values["generatedAgslHash"] as? String,
                )
            } finally { Trace.endSection() }
        }
        record("BOUNDARY", "name=$label shader=${material.shader} phase=${material.phase}" +
            " isolatedProduced=${material.isolatedProduced}" +
            " isolatedPublished=${material.isolatedPublished}" +
            " isolatedDropped=${material.isolatedDropped}" +
            " isolatedSlots=inFlight:${material.isolatedInFlight},ready:${material.isolatedReady}," +
            "compositorOwned:${material.isolatedCompositorOwned}" +
            " worker=running:${material.isolatedWorkerRunning}," +
            "desired:${material.isolatedWorkerDesiredAttachment}/${material.isolatedWorkerDesiredGeneration}," +
            "attached:${material.isolatedWorkerAttachedAttachment}/${material.isolatedWorkerAttachedGeneration}" +
            " renderer=${material.activeRenderer}" +
            " state=${material.state}")
        return material
    }

    private fun ownOverlays(): List<Overlay> {
        val windows = automation.windows
        return try {
            windows.filter { it.type == AccessibilityWindowInfo.TYPE_ACCESSIBILITY_OVERLAY }.mapNotNull { window ->
                // Once known, window metadata is enough to observe removal.
                // A temporarily unavailable root must NOT become a false
                // assertion that this still-listed overlay disappeared.
                val known = window.id in knownOwnWindowIds || window.title?.toString() == "FluviKeyguardCard"
                val root = if (known) null else window.root
                val own = try { known || root?.packageName?.toString() == context.packageName }
                    finally { root?.recycle() }
                if (!own) null else {
                    knownOwnWindowIds += window.id
                    Overlay(window.id, Rect().also(window::getBoundsInScreen))
                }
            }
        } finally { windows.forEach { it.recycle() } }
    }

    private fun requireOverlay(): Overlay {
        val overlays = ownOverlays()
        assertEquals("Exactly one actual Fluvi accessibility overlay", 1, overlays.size)
        return overlays.single()
    }

    /**
     * Exact Main submission identifies the requested frame, but it does not
     * latch UiAutomation's next compositor screenshot. Keep the controlled
     * time fixed and accept only a crop that meets the requested phase's
     * predicate. This is test-only observation, not physical presentation.
     */
    private fun awaitOrb(
        window: Overlay,
        name: String,
        accepts: (Bitmap) -> Boolean,
    ): Bitmap {
        val end = minOf(deadline, SystemClock.uptimeMillis() + 8_000L)
        var last: Bitmap? = null
        while (SystemClock.uptimeMillis() < end) {
            val candidate = captureOrb(window)
            if (candidate != null) {
                if (accepts(candidate)) {
                    last?.recycle()
                    persistOrb(name, candidate)
                    return candidate
                }
                last?.recycle()
                last = candidate
            }
            // Only yield for a fresh composed observation. The selected
            // request time is held constant and no renderer/fence wait is
            // introduced into production.
            SystemClock.sleep(32)
        }
        try {
            last?.let { persistOrb("$name.observation-timeout", it) }
        } finally {
            last?.recycle()
        }
        throw AssertionError("$name compositor crop never met its request-bound predicate")
    }

    private fun captureOrb(window: Overlay): Bitmap? {
        val screen = automation.takeScreenshot() ?: run {
            record("SCREENSHOT_UNOBSERVED", "reason=UiAutomationReturnedNull")
            return null
        }
        return try {
            val bounds = Rect(window.bounds)
            if (!bounds.intersect(0, 0, screen.width, screen.height) || bounds.width() != 168 || bounds.height() != 168) {
                record("SCREENSHOT_UNOBSERVED", "reason=unexpectedBounds")
                null
            } else Bitmap.createBitmap(screen, bounds.left, bounds.top, bounds.width(), bounds.height())
        } finally { screen.recycle() }
    }

    private fun persistOrb(name: String, crop: Bitmap) {
        File(output, name).outputStream().use { crop.compress(Bitmap.CompressFormat.PNG, 100, it) }
    }

    private data class OrbPixelComparison(
        val changedPixels: Int,
        val totalDelta: Long,
        val maximumDelta: Int,
    ) {
        fun meaningful(): Boolean = changedPixels >= 64 && totalDelta >= 2_048L
        fun nearlyEqual(): Boolean = maximumDelta <= 2 && totalDelta <= 2_048L
    }

    /** Ignore transparent corners: wallpaper/SystemUI pixels outside the orb
     * are not evidence. The positive and equality controls use this same
     * interior mask and retain the established substantive threshold. */
    private fun compareOrbPixels(first: Bitmap, second: Bitmap): OrbPixelComparison {
        require(first.width == second.width && first.height == second.height)
        var substantive = 0
        var totalDelta = 0L
        var maximum = 0
        for (y in 0 until first.height) for (x in 0 until first.width) {
            if (!insideOrb(x, y, first.width)) continue
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
        return OrbPixelComparison(substantive, totalDelta, maximum)
    }

    private fun hasColoredMaterial(bitmap: Bitmap): Boolean {
        var firstColor: Int? = null
        for (y in 0 until bitmap.height) for (x in 0 until bitmap.width) {
            if (!insideOrb(x, y, bitmap.width)) continue
            val color = bitmap.getPixel(x, y)
            if ((color ushr 24) == 0 || (color and 0x00ffffff) == 0) continue
            if (firstColor == null) firstColor = color
            else if (color != firstColor) return true
        }
        return false
    }

    private fun insideOrb(x: Int, y: Int, size: Int): Boolean {
        val dx = x + .5f - size / 2f
        val dy = y + .5f - size / 2f
        val radius = size * .42f
        return dx * dx + dy * dy < radius * radius
    }

    private fun tap(bounds: Rect) {
        val downAt = SystemClock.uptimeMillis()
        val down = MotionEvent.obtain(downAt, downAt, MotionEvent.ACTION_DOWN, bounds.exactCenterX(), bounds.exactCenterY(), 0)
        val up = MotionEvent.obtain(downAt, SystemClock.uptimeMillis(), MotionEvent.ACTION_UP, bounds.exactCenterX(), bounds.exactCenterY(), 0)
        down.source = InputDevice.SOURCE_TOUCHSCREEN
        up.source = InputDevice.SOURCE_TOUCHSCREEN
        try {
            assertTrue(automation.injectInputEvent(down, true))
            assertTrue(automation.injectInputEvent(up, true))
        } finally { down.recycle(); up.recycle() }
    }

    private fun await(label: String, timeoutMs: Long, pollMs: Long = 100, condition: () -> Boolean) {
        val end = minOf(deadline, SystemClock.uptimeMillis() + timeoutMs)
        while (SystemClock.uptimeMillis() < end) {
            if (condition()) return
            SystemClock.sleep(pollMs)
        }
        record("TIMEOUT", "$label reason=${KeyguardCardDiagnostics.lastReason(context)}")
        recordFailureWindows(label)
        throw AssertionError("$label timed out; no classifier or callback bypass is permitted")
    }

    private fun awaitUntil(label: String, absoluteDeadlineUptimeMs: Long, condition: () -> Boolean) {
        while (SystemClock.uptimeMillis() < absoluteDeadlineUptimeMs) {
            if (condition()) return
            SystemClock.sleep(minOf(100L, (absoluteDeadlineUptimeMs - SystemClock.uptimeMillis()).coerceAtLeast(0L)))
        }
        record("TIMEOUT", "$label reason=${KeyguardCardDiagnostics.lastReason(context)}")
        recordFailureWindows(label)
        throw AssertionError("$label timed out; no classifier or callback bypass is permitted")
    }

    /** Test failure evidence only, after the measured scenario has failed.
     * This is NOT the rejecting inspection's snapshot. No text, descriptions,
     * titles or node subtrees are read, and no window is whitelisted. */
    private fun recordFailureWindows(label: String) {
        val lines = StringBuilder("FAILURE_SNAPSHOT label=$label capture=$captureId" +
            " observedAt=${SystemClock.uptimeMillis()} notInspectionSnapshot=true\n")
        runCatching {
            val windows = automation.windows
            try {
                lines.appendLine("windowCount=${windows.size} omittedWindows=${(windows.size - 16).coerceAtLeast(0)}")
                windows.take(16).forEachIndexed { index, window ->
                    val bounds = Rect().also(window::getBoundsInScreen)
                    lines.append("window=$index id=${window.id} type=${window.type} layer=${window.layer}" +
                        " display=${window.displayId} active=${window.isActive} focused=${window.isFocused}" +
                        " bounds=$bounds")
                    if (index < 8) {
                        val started = SystemClock.uptimeMillis()
                        runCatching {
                            val root = window.root
                            try {
                                lines.append(" rootWindow=${root?.windowId} package=${root?.packageName}" +
                                    " visible=${root?.isVisibleToUser} rootCallMs=${SystemClock.uptimeMillis() - started}")
                            } finally { root?.recycle() }
                        }.onFailure { lines.append(" rootError=${it.javaClass.simpleName}") }
                    } else lines.append(" root=NOT_READ_BOUNDED")
                    lines.appendLine()
                }
            } finally { windows.forEach { it.recycle() } }
        }.onFailure { lines.appendLine("snapshotError=${it.javaClass.simpleName}") }
        runCatching { File(output, "failure-windows.txt").writeText(lines.toString()) }
            .onFailure { record("FAILURE_EVIDENCE_UNAVAILABLE", it.javaClass.simpleName) }
    }

    private inline fun <T> marked(label: String, action: () -> T): T {
        Trace.beginSection("KGProbe.$label")
        record("SCENARIO_BEGIN", label)
        return try { action() } finally {
            record("SCENARIO_END", label)
            Trace.endSection()
        }
    }

    private fun record(stage: String, detail: String) {
        val line = "$stage capture=$captureId up=${SystemClock.uptimeMillis()} monoNs=${System.nanoTime()}" +
            " bootNs=${SystemClock.elapsedRealtimeNanos()} tid=${android.os.Process.myTid()} $detail"
        evidence.appendLine(line)
        Log.i(TAG, line)
    }

    private fun shell(command: String): String = ParcelFileDescriptor.AutoCloseInputStream(
        automation.executeShellCommand(command),
    ).bufferedReader().use { it.readText() }

    private fun setSecure(key: String, value: String?) {
        // UiAutomation executes commands through Runtime.exec(String), not a
        // shell: shell-style quotes would become part of the stored component
        // or numeric value. Write exact nullable values through the public
        // provider API under this short-lived instrumentation-only identity.
        automation.adoptShellPermissionIdentity(Manifest.permission.WRITE_SECURE_SETTINGS)
        try {
            assertTrue("Secure setting write failed: $key", Settings.Secure.putString(context.contentResolver, key, value))
            assertEquals("Secure setting must round-trip without command quoting: $key",
                value, Settings.Secure.getString(context.contentResolver, key))
        } finally {
            automation.dropShellPermissionIdentity()
        }
    }

    private fun withoutOurService(value: String?): String = value.orEmpty().split(':').filter {
        it.isNotBlank() && ComponentName.unflattenFromString(it) != ComponentName(context, FluviKeyguardCardService::class.java)
    }.joinToString(":")

    private fun snapshotPreferences(name: String): Pair<SharedPreferences, Map<String, *>> {
        val prefs = context.getSharedPreferences(name, Context.MODE_PRIVATE)
        return prefs to HashMap(prefs.all)
    }

    private fun restorePreferences(saved: Pair<SharedPreferences, Map<String, *>>) {
        val edit = saved.first.edit().clear()
        saved.second.forEach { (key, value) -> when (value) {
            is Boolean -> edit.putBoolean(key, value)
            is Int -> edit.putInt(key, value)
            is Long -> edit.putLong(key, value)
            is Float -> edit.putFloat(key, value)
            is String -> edit.putString(key, value)
            is Set<*> -> edit.putStringSet(key, value.filterIsInstance<String>().toSet())
        } }
        assertTrue("Restore exact fixture-owned preferences", edit.commit())
    }

    private fun materialProfile(): Map<String, Any> = mapOf(
        "schemaVersion" to 1, "shaderAbiVersion" to 6,
        "sourceShaderHash" to KeyguardMaterialProfile.SOURCE_SHADER_HASH,
        "publisherSession" to "connected-service-fixture", "publisherRevision" to 1L,
        "sceneIdentity" to "fixture|balance|month", "effectId" to "dualTide", "effectShaderId" to 1,
        "phase" to .25, "elapsedSeconds" to 1.0, "phaseSpeed" to .4,
        "colors" to listOf(0xff104f7c.toInt(), 0xff62c7dc.toInt(), 0xff8366dc.toInt()),
        "stops" to listOf(0.0, .5, 1.0), "opacity" to 1.0, "paletteSplitPercent" to 50.0,
        "commonSettings" to List(40) { .2 }, "background" to portal(true), "interior" to portal(false),
        "referenceWidth" to 390.0, "referenceHeight" to 220.0,
    )

    private fun portal(enabled: Boolean): Map<String, Any> = mapOf(
        "enabled" to enabled, "effectIndex" to 0, "phase" to 0.0, "phaseSpeed" to .2,
        "paletteCenterPercent" to 50.0, "paletteWindowPercent" to 68.0,
        "rotationEnabled" to false, "rotationSpeed" to 0.0, "settings" to List(12) { .2 },
    )

    private fun materialTime(phase: Float) = KeyguardMaterialTime(
        elapsedSeconds = phase,
        phase = phase,
        backgroundPhase = phase,
        interiorPhase = phase,
    )

    companion object {
        private const val TAG = "FluviServiceProbe"
        private const val RAPID_LIFECYCLE_CYCLES = 30
        private const val MAX_TERMINAL_OBSERVATION_RECORDS = 64
        private const val MAX_ISOLATED_BUFFER_SLOTS = 3L
        private const val SERVICE_SCENARIO_BUDGET_MS = 330_000L
        private const val PHASE_A = 1.196795f
        private const val PHASE_C = 1.5234617f
        private const val PHASE_B = 3.75f
        private const val EXPECTED_PORTAL_HASH = "004559458d996ae0f4c8778ed4ad0055bbe87624e43297783c8ab19f94dcab21"
    }
}
