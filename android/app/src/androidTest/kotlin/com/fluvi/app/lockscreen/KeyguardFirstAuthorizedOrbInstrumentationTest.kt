package com.fluvi.app.lockscreen

import android.Manifest
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.KeyguardManager
import android.app.UiAutomation
import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
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
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.atomic.AtomicReference
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

/** Actual accessibility service, real reader, hidden host and native producer.
 * Screenshots are retained unclassified; this control is not a pixel/privacy
 * or handset-performance pass. The host must use a disposable API35 device. */
@RunWith(AndroidJUnit4::class)
class KeyguardFirstAuthorizedOrbInstrumentationTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val context get() = instrumentation.targetContext
    private lateinit var automation: UiAutomation

    @Test fun stableInitialFullUsesOneVirginOutputWithoutReadinessRead() = runService(false)
    @Test fun r40HeldOptionalWorkDoesNotBlockFirstCorrectOrbAndUnlock() = runService(false, null, true)
    @Test fun r41WarmHeldOptionalWorkDoesNotBlockFirstCorrectOrbAndUnlock() = runService(false, null, true, true)
    @Test fun r41PreparedRouteHeldOptionalWorkDoesNotBlockFirstCorrectOrbAndUnlock() =
        runService(false, null, true, true, false, true)
    @Test fun r41SystemWarmFreshServiceKeepsVisualAndUnlockControls() =
        runService(false, null, true, false, false, false, true)
    @Test fun r41SystemWarmLiveOrbShowsTwoCalibratedFramesThenWithdraws() =
        runService(false, null, true, false, false, false, true, true)
    @Test fun r41SystemWarmPreparedLiveOrbShowsCalibratedFramesThenWithdraws() =
        runService(false, null, true, false, false, true, true, true)
    @Test fun r41SystemWarmPreparedLiveOrbRecordsArrivalAndMotionThenWithdraws() =
        runService(changeScene = false, r40 = true, r41WaitForPreparedRoute = true,
            r41WarmSystemBeforeService = true, r41LiveMotion = true, r41LiveWaitForA = true)
    @Test fun r41SystemWarmBenignIngressBeforeRealMainAck() =
        runService(false, false, false, false, false, false, true)
    @Test fun r41SystemWarmExclusionBeforeRealMainAck() =
        runService(false, true, false, false, false, false, true)
    @Test fun r41SystemWarmSwipeShadeBeforeRealMainAck() =
        runService(false, true, false, false, false, false, true, false, true)
    @Test fun r41SystemWarmPinBeforeRealMainAck() =
        runService(false, true, false, false, false, false, true, false, false, true)
    @Test fun r41SystemWarmPinMenuBeforeRealMainAck() =
        runService(false, true, false, false, false, false, true, false, false, true, true)
    @Test fun r41SystemWarmPreparedPinMenuBeforeRealMainAck() =
        runService(changeScene = false, r21Negative = true, r41WaitForPreparedRoute = true,
            r41WarmSystemBeforeService = true, r21Pin = true, r21PinUseMenu = true)
    @Test fun r41ActualFallbackRetainsCandidateAndPostReceipt() = runService(false, null, false, false, true)
    @Test fun r41ActualWarmFallbackRetainsCandidateAndPostReceipt() = runService(false, null, false, true, true)
    @Test fun r41TwentyUnheldWakeAttempts() = runNaturalWakeBatch()
    @Test fun externalIngressWhileFirstPaintIsHeldCannotUseOldProof() = runService(true)
    @Test fun r21SubmittedDirectOrbSurvivesBenignIngressBeforeMainAck() = runService(false, false)
    @Test fun r21ExclusionRetiresSubmittedOrbWithMainAckHeld() = runService(false, true)

    @Test fun r32ObsoleteDirectOverlapsPhysicalSuccessor() = KeyguardR22FirstInspectionFixture().run("r32_overlap")
    @Test fun r34RealIngressesReplaceObsoleteOpeningOnOneReader() = KeyguardR22FirstInspectionFixture().run("r34_latest")
    @Test fun r37ReturnedChildHandsOffToRealLatestOnOneReader() = KeyguardR22FirstInspectionFixture().run("r37_after_child")

    @Test fun r31ActualSuccessorTransfersToSystemUiIngress() = KeyguardR22FirstInspectionFixture().run("r31_system")
    @Test fun r31ActualSuccessorTransfersToAmbiguousIngress() = KeyguardR22FirstInspectionFixture().run("r31_ambiguous")
    @Test fun r31RestrictiveIngressWhileSuccessorChildIsHeld() = KeyguardR22FirstInspectionFixture().run("r31_negative")

    @Test fun r22CalibrationPreservesNonSuppressingAutomation() = KeyguardR22FirstInspectionFixture().run("automation")
    @Test fun r22SupersededOpeningWalkYieldsToFreshInspection() = KeyguardR22FirstInspectionFixture().run("positive")
    @Test fun r22YieldedWalkCannotGrantAfterExclusion() = KeyguardR22FirstInspectionFixture().run("negative")
    @Test fun r22StableOpeningReadIsNotYielded() = KeyguardR22FirstInspectionFixture().run("stable")
    @Test fun r22UnstagedOpeningObservation() = KeyguardR22FirstInspectionFixture().run("natural")

    /** Unheld disposable-device observation, not a privacy or latency pass.
     * Every attempted wake has a separate frozen report, including timeouts.
     * The test callback observes a canvas post, which can still be hidden. */
    private fun runNaturalWakeBatch() {
        assertEquals(35, Build.VERSION.SDK_INT)
        val args = InstrumentationRegistry.getArguments()
        val source = requireNotNull(args.getString("sourceSha"))
        require(source.matches(Regex("[0-9a-f]{40}")))
        val run = UUID.fromString(requireNotNull(args.getString("runUuid"))).toString()
        val dir = File(context.filesDir, "keyguard-service-probe/r19/$run/r41-natural")
        check(dir.mkdirs())
        automation = instrumentation.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        val resolver = context.contentResolver
        val savedServices = Settings.Secure.getString(resolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        val savedEnabled = Settings.Secure.getString(resolver, Settings.Secure.ACCESSIBILITY_ENABLED)
        val savedLock = shell("locksettings get-disabled").trim()
        val savedSettings = preferences("fluvi_native_keyguard_card")
        val savedMaterial = preferences("fluvi_keyguard_header_material")
        val savedMode = preferences("fluvi_keyguard_orb_diagnostic_route")
        val component = ComponentName(context, FluviKeyguardCardService::class.java)
        val other = savedServices.orEmpty().split(':').filter {
            it.isNotBlank() && ComponentName.unflattenFromString(it) != component
        }.joinToString(":")
        val keyguard = context.getSystemService(KeyguardManager::class.java)
        val power = context.getSystemService(PowerManager::class.java)
        val postLatch = AtomicReference<CountDownLatch?>()
        val firstPostNs = AtomicLong(0)
        val lastPostAttachment = AtomicLong(0)
        val lastPostGeneration = AtomicLong(0)
        val savedPost = KeyguardOrbSurfaceWorkerTestHooks.afterCanvasPost
        val rows = mutableListOf<String>()
        val errors = mutableListOf<String>()
        var capture = false
        try {
            check(!FluviKeyguardCardServiceRegistry.connected && !keyguard.isDeviceSecure)
            check(savedLock == "true" || savedLock == "false")
            setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, other)
            shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard")
            await("unlocked setup", 8_000) { power.isInteractive && !keyguard.isKeyguardLocked }
            shell("locksettings set-disabled false")
            check(context.getSharedPreferences("fluvi_keyguard_orb_diagnostic_route", Context.MODE_PRIVATE)
                .edit().putString("mode", "SURFACE_LIVE").commit())
            instrumentation.runOnMainSync {
                FluviKeyguardCardSettings.update(context, mapOf("requested" to true, "showFinancialDetails" to true,
                    "presentationMode" to "orb", "animationMode" to "orbOnly"))
                val epoch = maxOf(SystemClock.elapsedRealtimeNanos(),
                    (savedMaterial.second["publisherEpoch"] as? Long ?: -1L) + 1L)
                check(FluviKeyguardMaterialStore.publish(context, KeyguardR12ServiceTimingInstrumentationTest().materialProfile(), epoch))
            }
            setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
                listOf(other, component.flattenToString()).filter(String::isNotBlank).joinToString(":"))
            setSecure(Settings.Secure.ACCESSIBILITY_ENABLED, "1")
            await("actual service connected", 10_000) { FluviKeyguardCardServiceRegistry.connected }
            val service = checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation())
            KeyguardOrbSurfaceWorkerTestHooks.afterCanvasPost = { target ->
                val latch = postLatch.get()
                // A late callback from the preceding wake must never satisfy
                // the next trial. This is test observation only; it does not
                // supply or change the application's presentation authority.
                if (latch != null && target.attachment > 0 && target.full && !target.revoked &&
                    (target.attachment != lastPostAttachment.get() || target.generation != lastPostGeneration.get()) &&
                    firstPostNs.compareAndSet(0, System.nanoTime())) {
                    lastPostAttachment.set(target.attachment)
                    lastPostGeneration.set(target.generation)
                    latch.countDown()
                }
                savedPost?.invoke(target)
            }
            repeat(20) { index ->
                shell("input keyevent KEYCODE_SLEEP")
                await("sleep, keyguard and old window withdrawal ${index + 1}", 8_000) {
                    var visible = true
                    instrumentation.runOnMainSync { visible = service.renderModeStatus().visible }
                    !power.isInteractive && keyguard.isKeyguardLocked && !visible
                }
                KeyguardCardDiagnostics.startCapture(context, source, "debug", "LIGHT"); capture = true
                firstPostNs.set(0)
                val latch = CountDownLatch(1)
                postLatch.set(latch)
                val wakeCommandNs = System.nanoTime()
                shell("input keyevent KEYCODE_WAKEUP")
                val posted = latch.await(7, TimeUnit.SECONDS)
                var visible = false
                if (posted) runCatching {
                    await("service visible ${index + 1}", 3_000) {
                        instrumentation.runOnMainSync { visible = service.renderModeStatus().visible }
                        visible && power.isInteractive && keyguard.isKeyguardLocked
                    }
                }
                postLatch.set(null)
                val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
                capture = false
                File(dir, "capture-${index + 1}.txt").writeText(report)
                rows.add("trial=${index + 1} class=${if (index == 0) "fresh-service" else "warm"} " +
                    "commandNs=$wakeCommandNs workerPostNs=${firstPostNs.get().takeIf { it > 0 } ?: "UNOBSERVED"} " +
                    "workerPost=$posted attachment=${if (posted) lastPostAttachment.get() else "UNOBSERVED"} " +
                    "generation=${if (posted) lastPostGeneration.get() else "UNOBSERVED"} " +
                    "visible=$visible optical=UNOBSERVED verdict=INCOMPLETE")
                File(dir, "trials.txt").writeText(rows.joinToString("\n", postfix = "\n"))
            }
        } catch (error: Throwable) {
            errors.add("${error.javaClass.simpleName}:${error.message}")
        } finally {
            postLatch.set(null)
            KeyguardOrbSurfaceWorkerTestHooks.afterCanvasPost = savedPost
            if (capture) runCatching { File(dir, "interrupted.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"] as String) }
            runCatching {
                setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, other)
                await("service disconnected", 10_000) { !FluviKeyguardCardServiceRegistry.connected }
                restore(savedSettings); restore(savedMaterial); restore(savedMode)
                shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard")
                if (savedLock == "true" || savedLock == "false") shell("locksettings set-disabled $savedLock")
                setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, savedServices)
                setSecure(Settings.Secure.ACCESSIBILITY_ENABLED, savedEnabled)
            }.onFailure { errors.add("cleanup:${it.javaClass.simpleName}:${it.message}") }
            File(dir, "result.txt").writeText("source=$source attempts=${rows.size} errors=${errors.joinToString("|")} " +
                "canvasPostIsNotVisiblePixel=true observerMainPollingAfterPost=true physical=UNOBSERVED\n")
        }
        assertEquals("natural batch interrupted: $errors", 20, rows.size)
        assertTrue("natural batch cleanup failed: $errors", errors.isEmpty())
    }

    private fun runService(changeScene: Boolean, r21Negative: Boolean? = null, r40: Boolean = false,
                           r41Warm: Boolean = false, r41Fallback: Boolean = false,
                           r41WaitForPreparedRoute: Boolean = false,
                           r41WarmSystemBeforeService: Boolean = false,
                           r41LiveMotion: Boolean = false,
                           r21SwipeShade: Boolean = false,
                           r21Pin: Boolean = false,
                           r21PinUseMenu: Boolean = false,
                           r41LiveWaitForA: Boolean = false) {
        assertEquals(35, Build.VERSION.SDK_INT)
        val args = InstrumentationRegistry.getArguments()
        val source = requireNotNull(args.getString("sourceSha"))
        require(source.matches(Regex("[0-9a-f]{40}")))
        val run = args.getString("runUuid")?.let { UUID.fromString(it).toString() } ?: UUID.randomUUID().toString()
        val specimen = if (r41Fallback) "r41-fallback" else if (r21Negative == null) { if (changeScene) "changed" else "stable" }
            else if (r21Negative) "r21-negative" else "r21-positive"
        val dir = File(context.filesDir, "keyguard-service-probe/r19/$run/$specimen")
        check(!dir.exists() && dir.mkdirs())
        val keyguard = context.getSystemService(KeyguardManager::class.java)
        val power = context.getSystemService(PowerManager::class.java)
        automation = instrumentation.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        automation.serviceInfo = automation.serviceInfo.apply { flags = flags or AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS }
        val resolver = context.contentResolver
        val savedServices = Settings.Secure.getString(resolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        val savedEnabled = Settings.Secure.getString(resolver, Settings.Secure.ACCESSIBILITY_ENABLED)
        val savedLock = shell("locksettings get-disabled").trim()
        val savedSettings = preferences("fluvi_native_keyguard_card")
        val savedMaterial = preferences("fluvi_keyguard_header_material")
        val savedMode = preferences("fluvi_keyguard_orb_diagnostic_route")
        val component = ComponentName(context, FluviKeyguardCardService::class.java)
        val other = savedServices.orEmpty().split(':').filter {
            it.isNotBlank() && ComponentName.unflattenFromString(it) != component
        }.joinToString(":")
        val reads = Collections.synchronizedList(mutableListOf<String>())
        val secondRead = CountDownLatch(1)
        val injectedAt = AtomicLong(0L)
        val injectedRequest = AtomicLong(0L)
        val paintEntered = CountDownLatch(1)
        val releasePaint = CountDownLatch(1)
        val held = AtomicBoolean(false)
        val acknowledgement = AtomicReference<Runnable?>()
        val acknowledgementHeld = CountDownLatch(1)
        val injectedFinished = CountDownLatch(1)
        val injectedResult = AtomicReference<String?>()
        val negativeEnabled = AtomicBoolean(false)
        val negativeFinished = CountDownLatch(1)
        val negativeResult = AtomicReference<String?>()
        val savedDispatcher = KeyguardOrbSurfaceWorkerTestHooks.dispatchRevealDone
        val savedCross = KeyguardOrbSurfaceWorkerTestHooks.afterRevealCross
        val r40Calls = java.util.concurrent.atomic.AtomicInteger()
        val r41WarmReady = AtomicBoolean(!r41Warm)
        val callsAtFirstCross = java.util.concurrent.atomic.AtomicInteger(-1)
        val r40Started = CountDownLatch(1)
        val r40Release = CountDownLatch(1)
        var r40Visual: KeyguardR22VisualCalibration? = null
        var captureStarted = false
        var report: String? = null
        val errors = mutableListOf<String>()
        try {
            check(!FluviKeyguardCardServiceRegistry.connected) { "service must start in a fresh process" }
            check(!keyguard.isDeviceSecure) { "requires a disposable insecure keyguard" }
            check(savedLock == "true" || savedLock == "false")
            setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, other)
            await("old service disconnected", 8_000) { !FluviKeyguardCardServiceRegistry.connected }
            shell("input keyevent KEYCODE_WAKEUP")
            shell("wm dismiss-keyguard")
            await("unlocked", 5_000) { power.isInteractive && !keyguard.isKeyguardLocked }
            saveScreenshot(File(dir, "01-unlocked-background.png"))
            shell("locksettings set-disabled false")
            if (r21Pin) {
                // Disposable API-35 fixture only: start from an insecure
                // keyguard and always remove this synthetic PIN in finally.
                File(dir, "pin-setup.txt").writeText(shell("locksettings set-pin 2468"))
                await("synthetic PIN enrolled", 8_000) { keyguard.isDeviceSecure }
            }
            check(context.getSharedPreferences("fluvi_keyguard_orb_diagnostic_route", Context.MODE_PRIVATE)
                .edit().putString("mode", "SURFACE_LIVE").commit())
            instrumentation.runOnMainSync {
                FluviKeyguardCardSettings.update(context, mapOf("requested" to true, "showFinancialDetails" to true,
                    "presentationMode" to "orb", "animationMode" to "orbOnly"))
                val epoch = maxOf(SystemClock.elapsedRealtimeNanos(), (savedMaterial.second["publisherEpoch"] as? Long ?: -1L) + 1L)
                check(FluviKeyguardMaterialStore.publish(context, KeyguardR12ServiceTimingInstrumentationTest().materialProfile(), epoch))
            }
            if (r40) {
                r40Visual = KeyguardR22VisualCalibration(instrumentation, dir, automation).also { it.calibrate() }
                // The first trial showed the calibration Activity's actual
                // window persisted until the sleep/wake transition. Wait for
                // its platform removal; never substitute an app decision.
                shell("input keyevent KEYCODE_HOME")
                await("calibration Activity window removed before service wake", 12_000) {
                    !shell("dumpsys window windows").contains("KeyguardMaterialTestActivity")
                }
                File(dir, "r40-before-service-windows.txt").writeText(shell("dumpsys window windows"))
                KeyguardOrbSurfaceWorkerTestHooks.fixedMaterialTime = KeyguardR22VisualCalibration.timeA
                KeyguardOrbSurfaceWorkerTestHooks.afterRevealCross = { output ->
                    if (r41WarmReady.get()) callsAtFirstCross.compareAndSet(-1, r40Calls.get())
                    savedCross?.invoke(output)
                }
            }
            if (r41WarmSystemBeforeService) {
                // Warm only the platform keyguard while Fluvi's service is
                // still disconnected. The subsequent test starts the real
                // service from fresh state and keeps every original visual,
                // admission and unlock assertion unchanged.
                shell("input keyevent KEYCODE_SLEEP")
                await("platform warm-up sleeping", 8_000) { !power.isInteractive && keyguard.isKeyguardLocked }
                shell("input keyevent KEYCODE_WAKEUP")
                await("platform warm-up locked wake", 8_000) { power.isInteractive && keyguard.isKeyguardLocked }
                File(dir, "r41-platform-warm-windows.txt").writeText(shell("dumpsys window windows"))
                shell("input keyevent KEYCODE_SLEEP")
                await("platform warm-up withdrawal", 8_000) { !power.isInteractive && keyguard.isKeyguardLocked }
                check(!FluviKeyguardCardServiceRegistry.connected)
            }
            KeyguardCardDiagnostics.startCapture(context, source, "debug", "LIGHT")
            captureStarted = true
            if (changeScene) KeyguardOrbSurfaceWorkerTestHooks.afterCanvasLock = { target ->
                if (target.directOutput != null && target.full && held.compareAndSet(false, true)) {
                    paintEntered.countDown()
                    check(releasePaint.await(20, TimeUnit.SECONDS)) { "first paint barrier timed out" }
                }
            }
            setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
                listOf(other, component.flattenToString()).filter(String::isNotBlank).joinToString(":"))
            setSecure(Settings.Secure.ACCESSIBILITY_ENABLED, "1")
            await("actual service connected", 10_000) { FluviKeyguardCardServiceRegistry.connected }
            val service = checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation())
            instrumentation.runOnMainSync {
                service.inspectionProbeForTest = object : KeyguardInspectionProbeForTest {
                    override fun r40ProvenanceStarted(request: KeyguardCardInspectionRequest) {
                        if (r40 && r41WarmReady.get()) {
                            r40Calls.incrementAndGet()
                            reads.add("R40_OPTIONAL_STARTED id=${request.id} at=${SystemClock.uptimeMillis()}")
                            r40Started.countDown()
                            r40Release.await(20, TimeUnit.SECONDS)
                        }
                    }
                    override fun started(request: KeyguardCardInspectionRequest) {
                        reads.add("start id=${request.id} trigger=${request.trigger} wake=${request.wakeGeneration}")
                        if (request.id == injectedRequest.get() && request.id != 0L) secondRead.countDown()
                    }
                    override fun ingressOffered(meta: KeyguardAccessibilityEventMeta, request: KeyguardCardInspectionRequest,
                        previous: KeyguardCardInspectionRequest?, pending: KeyguardCardInspectionRequest?,
                        startsWorker: Boolean, frameworkEvent: Boolean) {
                        if (!frameworkEvent && meta.eventTimeUptimeMs == injectedAt.get()) injectedRequest.set(request.id)
                    }
                    override fun readCompleted(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility,
                        reason: KeyguardSurfaceReason, rootUnavailable: Boolean, walkTruncated: Boolean,
                        abortedStale: Boolean, startedAt: Long, finishedAt: Long) {
                        reads.add("end id=${request.id} decision=$decision reason=$reason rootUnavailable=$rootUnavailable " +
                            "truncated=$walkTruncated stale=$abortedStale start=$startedAt end=$finishedAt")
                        if (request.id == injectedRequest.get() && request.id != 0L) {
                            injectedResult.set("$decision/$reason/$rootUnavailable/$walkTruncated/$abortedStale")
                            injectedFinished.countDown()
                        }
                        if (negativeEnabled.get() && decision in setOf(KeyguardCardVisibility.HIDDEN_SHADE,
                                KeyguardCardVisibility.HIDDEN_CREDENTIAL) && !abortedStale) {
                            negativeResult.set("${request.id}/$decision/$reason/$rootUnavailable/$walkTruncated")
                            negativeFinished.countDown()
                        }
                    }
                }
            }
            if (r21Negative != null) {
                KeyguardOrbSurfaceWorkerTestHooks.dispatchRevealDone = { task ->
                    if (acknowledgement.compareAndSet(null, task)) acknowledgementHeld.countDown()
                    else Handler(Looper.getMainLooper()).post(task)
                }
            }
            if (r41Warm) {
                // Record the complete warm-up separately. The actual safety
                // trial below retains every original assertion and threshold.
                shell("input keyevent KEYCODE_SLEEP")
                await("warm-up sleeping", 8_000) { !power.isInteractive && keyguard.isKeyguardLocked }
                shell("input keyevent KEYCODE_WAKEUP")
                val postedAndMoving = Regex(" winner=(?!R18_DIRECT_ATTEMPT/)[A-Z0-9_]+/[0-9]+/[0-9]+(?: |$)")
                await("warm-up first post and distinct motion", 20_000) {
                    val text = KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String
                    power.isInteractive && keyguard.isKeyguardLocked && text.lineSequence().any {
                        it.startsWith(" R21_CORE ") && postedAndMoving.containsMatchIn(it)
                    }
                }
                File(dir, "r41-warm-up.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"] as String)
                File(dir, "r41-warm-up-reads.txt").writeText(synchronized(reads) { reads.joinToString("\n", postfix = "\n") })
                shell("input keyevent KEYCODE_SLEEP")
                await("warm-up withdrawal", 8_000) {
                    var visible = true
                    instrumentation.runOnMainSync { visible = service.renderModeStatus().visible }
                    !power.isInteractive && keyguard.isKeyguardLocked && !visible
                }
                synchronized(reads) { reads.clear() }
                KeyguardCardDiagnostics.startCapture(context, source, "debug", "LIGHT")
                r41WarmReady.set(true)
            }
            shell("input keyevent KEYCODE_SLEEP")
            await("sleep and keyguard", 8_000) { !power.isInteractive && keyguard.isKeyguardLocked }
            if (r41WaitForPreparedRoute) {
                // Safety fixture precondition only: observe the real detached
                // route. Do not prepare it, change visibility or manufacture a
                // reservation. A timeout is NOT REACHED, not a product pass.
                val lock = service.javaClass.getDeclaredField("queueLock").apply { isAccessible = true }.get(service)
                val route = service.javaClass.getDeclaredField("r18RouteSnapshot").apply { isAccessible = true }
                val enabled = service.javaClass.getDeclaredField("r18RouteEnabled").apply { isAccessible = true }
                val active = service.javaClass.getDeclaredField("r18Active").apply { isAccessible = true }
                val provisional = service.javaClass.getDeclaredField("r18ProvisionalWake").apply { isAccessible = true }
                val wakeOpen = service.javaClass.getDeclaredField("r18WakeOpen").apply { isAccessible = true }
                var observed = "UNOBSERVED"
                try {
                    await("NOT REACHED: real detached prepared DIRECT route", 15_000) {
                        val ready = synchronized(lock) {
                            val hasRoute = route.get(service) != null
                            val isEnabled = enabled.getBoolean(service)
                            val activeOwner = active.get(service) != null
                            val pendingOwner = provisional.get(service) != null
                            val isWakeOpen = wakeOpen.getBoolean(service)
                            observed = "route=$hasRoute enabled=$isEnabled active=$activeOwner provisional=$pendingOwner wakeOpen=$isWakeOpen"
                            hasRoute && isEnabled && !activeOwner && !pendingOwner && !isWakeOpen
                        }
                        ready && !power.isInteractive && keyguard.isKeyguardLocked
                    }
                } finally {
                    File(dir, "r41-prewake-route.txt").writeText("$observed\n")
                }
            }
            shell("input keyevent KEYCODE_WAKEUP")
            await("locked wake", 5_000) { power.isInteractive && keyguard.isKeyguardLocked }
            if (r21Negative != null) {
                assertTrue("NOT REACHED: real reveal acknowledgement was never queued", acknowledgementHeld.await(20, TimeUnit.SECONDS))
                var before: String? = null
                await("real accepted native apply before Main acknowledgement", 10_000) {
                    val text = KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String
                    before = text.lineSequence().firstOrNull { it.startsWith(" R21_CORE ") &&
                        it.contains("/ACCEPTED ingress=") && it.contains(" ack=UNOBSERVED/") }
                    before != null
                }
                val first = checkNotNull(before)
                val owner = first.substringAfter(" direct=").substringBefore(' ')
                assertFalse("NOT REACHED: exact direct owner missing", owner.contains("UNOBSERVED"))
                assertTrue("NOT REACHED: no original input-arm show", !first.contains(" firstShow=UNOBSERVED/"))
                assertTrue("device is not locked and interactive", power.isInteractive && keyguard.isKeyguardLocked)
                File(dir, "before-ingress.txt").writeText(first + "\n")
                saveScreenshot(File(dir, "02-before-ingress.png"))
                if (!r21Negative) {
                    instrumentation.runOnMainSync {
                        val at = SystemClock.uptimeMillis()
                        injectedAt.set(at)
                        service.acceptAccessibilityMetadataForTest(KeyguardAccessibilityEventMeta(
                            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED, -1, Display.DEFAULT_DISPLAY, 0,
                            "com.android.systemui", at))
                    }
                    assertTrue("NOT REACHED: injected request did not finish (it may have been coalesced)",
                        injectedFinished.await(10, TimeUnit.SECONDS))
                    assertEquals("fresh actual reader was not a complete MAIN/FULL decision",
                        "SHOW_FULL/MAIN_CONFIRMED/false/false/false", injectedResult.get())
                    assertTrue("injected event did not receive a request ID", injectedRequest.get() > 0)
                    val after = KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String
                    File(dir, "after-ingress.txt").writeText(after)
                    val same = after.lineSequence().firstOrNull { it.startsWith(" R21_CORE ") && it.contains(" direct=$owner ") }
                    assertNotNull("submitted exact owner was replaced", same)
                    assertTrue("ordinary ingress did not schedule its fresh request", checkNotNull(same).contains(" offered=${injectedRequest.get()} read="))
                    assertTrue("old owner took a fallback", same.contains(" fallback=UNOBSERVED/"))
                    assertTrue("a second show was observed while acknowledgement was held", same.contains(" following=UNOBSERVED/"))
                } else {
                    negativeEnabled.set(true)
                    if (r21Pin) {
                        if (r21PinUseMenu) {
                            File(dir, "pin-gesture.txt").writeText("input keyevent KEYCODE_MENU\n")
                            shell("input keyevent KEYCODE_MENU")
                        } else {
                            val screen = context.getSystemService(android.view.WindowManager::class.java).currentWindowMetrics.bounds
                            // Avoid the actual ORB hit region while opening bouncer.
                            val x = screen.left + screen.width() / 5
                            val fromY = screen.top + screen.height() * 85 / 100
                            val toY = screen.top + screen.height() / 4
                            File(dir, "pin-gesture.txt").writeText("bounds=$screen from=$x,$fromY to=$x,$toY durationMs=400\n")
                            shell("input swipe $x $fromY $x $toY 400")
                        }
                    } else if (r21SwipeShade) {
                        val screen = context.getSystemService(android.view.WindowManager::class.java).currentWindowMetrics.bounds
                        val x = screen.centerX()
                        val fromY = screen.top + 1
                        val toY = screen.top + screen.height() * 3 / 4
                        File(dir, "shade-gesture.txt").writeText("bounds=$screen from=$x,$fromY to=$x,$toY durationMs=400\n")
                        shell("input swipe $x $fromY $x $toY 400")
                    } else File(dir, "shade-command.txt").writeText(shell("cmd statusbar expand-notifications"))
                    // Capture the actual attempted shade state even if the
                    // classifier never reaches its required negative result.
                    File(dir, "shade-attempt-windows.txt").writeText(shell("dumpsys window windows"))
                    saveScreenshot(File(dir, "02-shade-attempt.png"))
                    assertTrue("NOT REACHED: real shade/credential decision was not observed", negativeFinished.await(12, TimeUnit.SECONDS))
                    await("actual negative withdrew service window", 10_000) {
                        var visible = true
                        instrumentation.runOnMainSync { visible = service.renderModeStatus().visible }
                        !visible
                    }
                    await("exact submitted owner sealed and native retirement returned", 10_000) {
                        val text = KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String
                        val row = text.lineSequence().firstOrNull { it.startsWith(" R21_CORE ") && it.contains(" direct=$owner ") }
                        row != null && !row.contains(" seal=UNOBSERVED/") && !row.contains(" retire=UNOBSERVED/")
                    }
                    File(dir, "after-negative.txt").writeText(KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String)
                    File(dir, "negative.txt").writeText("${negativeResult.get()}\n")
                    saveScreenshot(File(dir, "03-negative-with-ack-held.png"))
                }
                val task = checkNotNull(acknowledgement.getAndSet(null))
                instrumentation.runOnMainSync { task.run() }
                if (r21Negative) {
                    if (r21PinUseMenu) {
                        File(dir, "after-ack-windows.txt").writeText(shell("dumpsys window windows"))
                        saveScreenshot(File(dir, "04-after-ack.png"))
                    }
                    var visible = true
                    instrumentation.runOnMainSync { visible = service.renderModeStatus().visible }
                    assertFalse("late acknowledgement resurrected a withdrawn host", visible)
                }
            }
            if (changeScene) {
                assertTrue("real first FULL paint was not reached", paintEntered.await(20, TimeUnit.SECONDS))
                instrumentation.runOnMainSync {
                    val at = SystemClock.uptimeMillis()
                    injectedAt.set(at)
                    service.acceptAccessibilityMetadataForTest(KeyguardAccessibilityEventMeta(
                        AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED, -1, Display.DEFAULT_DISPLAY, 0,
                        "com.android.systemui", at))
                }
                assertTrue("new scene inspection did not start", secondRead.await(10, TimeUnit.SECONDS))
                var visible = true
                instrumentation.runOnMainSync { visible = service.renderModeStatus().visible }
                assertFalse("old proof enabled the service while first paint was held", visible)
                saveScreenshot(File(dir, "02-held-after-ingress.png"))
                releasePaint.countDown()
            }
            if (r41Fallback) {
                var fallbackAttempt: String? = null
                val posted = Regex(" winner=SURFACE_LIVE/[0-9]+/[0-9]+(?: |$)")
                await("actual fallback post and distinct motion", 20_000) {
                    val text = KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String
                    fallbackAttempt = text.lineSequence().firstOrNull {
                        it.startsWith(" R21_CORE ") && posted.containsMatchIn(it)
                    }?.substringAfter("attempt=")?.substringBefore(' ')
                    fallbackAttempt != null
                }
                report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
                File(dir, "capture.txt").writeText(checkNotNull(report))
                val core = checkNotNull(report).lineSequence().firstOrNull {
                    it.startsWith(" R41_CORE attempt=${checkNotNull(fallbackAttempt)} ")
                }
                assertNotNull("actual fallback attempt has no compact R41 row", core)
                val fallbackCore = checkNotNull(core)
                assertTrue("actual fallback candidate and same-show post receipt were not both retained: $core",
                    !fallbackCore.contains("fallbackCandidateAndPostReceipt=UNOBSERVED"))
                assertTrue("fallback observation must not be mislabelled as an effective grant: $core",
                    fallbackCore.contains("fallbackGrant=UNOBSERVED"))
            } else {
            if (r21Negative != true) await("actual service window", 20_000) {
                var visible = false
                instrumentation.runOnMainSync { visible = service.renderModeStatus().visible }
                visible && keyguard.isKeyguardLocked
            }
            // A WindowManager attach is insufficient. Wait for the actual
            // output's own native apply receipt, under the same attempt.
            if (r21Negative != true) await("direct reveal receipt", 15_000) {
                val text = KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String
                text.lineSequence().any { it.startsWith(" R18_PIPELINE ") &&
                    !it.contains("revealApply=UNOBSERVED/") && !it.contains("bufferReady=UNOBSERVED") }
            }
            if (r40) {
                assertEquals("first native boundary must precede any optional provenance work", 0, callsAtFirstCross.get())
                var identity: KeyguardR22VisualIdentityForTest? = null
                await("exact visible native owner with geometry", 8_000) {
                    instrumentation.runOnMainSync { identity = service.r22VisualIdentityForTest() }
                    identity != null
                }
                val visual = checkNotNull(r40Visual)
                fun assertSameVisualOwner() {
                    if (!r41LiveWaitForA) return
                    var current: KeyguardR22VisualIdentityForTest? = null
                    instrumentation.runOnMainSync { current = service.r22VisualIdentityForTest() }
                    val before = checkNotNull(identity)
                    val after = checkNotNull(current) { "NOT REACHED: visual owner disappeared during sampling" }
                    assertEquals("reservation changed during sampling", before.reservationId, after.reservationId)
                    assertEquals("attachment changed during sampling", before.attachment, after.attachment)
                    assertEquals("output generation changed during sampling", before.outputGeneration, after.outputGeneration)
                    assertEquals("child changed during sampling", before.childIdentity, after.childIdentity)
                    assertEquals("bounds changed during sampling", before.bounds, after.bounds)
                }
                var crop = visual.captureCrop("r40-first-full", checkNotNull(identity).bounds)
                if (r41LiveWaitForA && !KeyguardR22VisualCalibration.compare(visual.a, crop).nearlyEqual()) {
                    // Keep the immediate sample and each later compositor sample.
                    // This separate witness does not turn the original immediate
                    // crop assertion into an initial-frame or latency pass.
                    for (sample in 0 until 30) {
                        SystemClock.sleep(100)
                        crop = visual.captureCrop("r41-arrival-a-$sample", checkNotNull(identity).bounds)
                        if (KeyguardR22VisualCalibration.compare(visual.a, crop).nearlyEqual()) break
                    }
                }
                assertTrue("NOT REACHED: compositor crop did not match the calibrated configured FULL orb",
                    KeyguardR22VisualCalibration.compare(visual.a, crop).nearlyEqual())
                assertSameVisualOwner()
                if (r41LiveMotion) {
                    // Advance only the test's material clock; do not inject a
                    // new scene, permission, frame or presentation callback.
                    // Keep every compositor sample, including mismatches.
                    KeyguardOrbSurfaceWorkerTestHooks.fixedMaterialTime = KeyguardR22VisualCalibration.timeB
                    var matched = false
                    for (sample in 0 until 30) {
                        SystemClock.sleep(100)
                        val image = visual.captureCrop("r41-live-b-$sample", checkNotNull(identity).bounds)
                        if (KeyguardR22VisualCalibration.compare(visual.b, image).nearlyEqual()) {
                            assertTrue("second live crop is not distinct", KeyguardR22VisualCalibration.compare(crop, image).meaningful())
                            matched = true
                            break
                        }
                    }
                    assertTrue("NOT REACHED: real live ORB never reached the calibrated B compositor frame", matched)
                    assertSameVisualOwner()
                }
                if (r40Started.count > 0) instrumentation.runOnMainSync {
                    val at = SystemClock.uptimeMillis()
                    service.acceptAccessibilityMetadataForTest(KeyguardAccessibilityEventMeta(
                        AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED, -1, Display.DEFAULT_DISPLAY, 0,
                        "com.android.systemui", at))
                }
                assertTrue("NOT REACHED: subsequent real reader did not enter optional work", r40Started.await(10, TimeUnit.SECONDS))
                // While the single reader remains held, unlock must still flow
                // through the ordinary negative system/visibility owner.
                shell("wm dismiss-keyguard")
                await("unlock while optional read held", 10_000) { power.isInteractive && !keyguard.isKeyguardLocked }
                await("ordinary privacy withdrawal while optional read held", 10_000) {
                    var visible = true
                    instrumentation.runOnMainSync { visible = service.renderModeStatus().visible }
                    !visible
                }
                val afterUnlock = visual.captureCrop("r40-after-unlock", checkNotNull(identity).bounds)
                if (r41LiveMotion) {
                    assertFalse("calibrated old A still occupies the post-withdrawal crop",
                        KeyguardR22VisualCalibration.compare(visual.a, afterUnlock).nearlyEqual())
                    assertFalse("calibrated old B still occupies the post-withdrawal crop",
                        KeyguardR22VisualCalibration.compare(visual.b, afterUnlock).nearlyEqual())
                    // This sample follows the observed invisible state; it is
                    // not the first forbidden physical frame.
                }
                r40Release.countDown()
            }
            saveScreenshot(File(dir, "03-visible-unclassified.png"))
            report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
            File(dir, "capture.txt").writeText(checkNotNull(report))
            // A stock baseline is RED only after its real direct output and
            // reveal were reached; a fallback/timeout is not a RED result.
            val row = checkNotNull(report).lineSequence().firstOrNull {
                it.startsWith(" R18_PIPELINE ") && it.contains("r19Intent=EMPTY") &&
                    !it.contains("revealApply=UNOBSERVED/") && !it.contains("bufferReady=UNOBSERVED")
            }
            assertNotNull("real direct reveal used no virgin FULL target", row)
            val currentRow = checkNotNull(row)
            assertFalse("missing full proof", currentRow.contains("firstPositive=UNOBSERVED"))
            assertFalse("missing authorized paint", currentRow.contains("paint=UNOBSERVED/"))
            assertFalse("missing continuation", currentRow.contains("consumed=UNOBSERVED"))
            val attempt = currentRow.substringAfter("attempt=").substringBefore(' ')
            assertEquals("stable initial show must use a single native target", 1,
                checkNotNull(report).lineSequence().count { it.startsWith(" R18_PIPELINE attempt=$attempt ") })
            val consumed = currentRow.substringAfter("consumedReq=").substringBefore(' ').toLong()
            val showing = currentRow.substringAfter(" proof=").substringBefore(' ').toLong()
            assertEquals("showing grant must use the consumed proof", consumed, showing)
            assertFalse("readiness alone requested a new tree walk", synchronized(reads) { reads.any { it.contains("trigger=r18Ready") } })
            if (changeScene) {
                val initial = currentRow.substringAfter("firstPositive=").substringBefore('@').toLong()
                assertTrue("old proof was consumed after external ingress", consumed > initial)
                assertTrue("consumed proof predates the injected event's real request", consumed >= injectedRequest.get())
            }
            }
        } catch (error: Throwable) {
            errors += "${error.javaClass.simpleName}:${error.message}"
        } finally {
            r40Release.countDown()
            KeyguardOrbSurfaceWorkerTestHooks.afterRevealCross = savedCross
            KeyguardOrbSurfaceWorkerTestHooks.fixedMaterialTime = null
            runCatching { r40Visual?.close() }
            KeyguardOrbSurfaceWorkerTestHooks.dispatchRevealDone = savedDispatcher
            acknowledgement.getAndSet(null)?.let { task -> Handler(Looper.getMainLooper()).post(task) }
            releasePaint.countDown()
            KeyguardOrbSurfaceWorkerTestHooks.afterCanvasLock = null
            runCatching { if (captureStarted && report == null) {
                report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
                File(dir, "capture.txt").writeText(checkNotNull(report))
            } }.onFailure { errors += "freeze:${it.javaClass.simpleName}:${it.message}" }
            File(dir, "reads.txt").writeText(synchronized(reads) { reads.joinToString("\n", postfix = "\n") })
            runCatching {
                if (r21Pin) {
                    File(dir, "pin-cleanup.txt").writeText(shell("locksettings clear --old 2468"))
                    check(!keyguard.isDeviceSecure) { "synthetic PIN cleanup failed" }
                }
            }.onFailure { errors += "pin-cleanup:${it.javaClass.simpleName}:${it.message}" }
            runCatching {
                if (r21Negative == true) shell("cmd statusbar collapse")
                setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, other)
                await("service disconnected", 8_000) { !FluviKeyguardCardServiceRegistry.connected }
                restore(savedSettings); restore(savedMaterial); restore(savedMode)
                shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard")
                if (savedLock == "true" || savedLock == "false") shell("locksettings set-disabled $savedLock")
                setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, savedServices)
                setSecure(Settings.Secure.ACCESSIBILITY_ENABLED, savedEnabled)
            }.onFailure { errors += "cleanup:${it.javaClass.simpleName}:${it.message}" }
            File(dir, "result.txt").writeText("source=$source run=$run changed=$changeScene errors=${errors.joinToString(" | ")} physical=UNOBSERVED\n")
        }
        assertTrue("R19 service specimen failures: ${errors.joinToString(" | ")}", errors.isEmpty())
    }

    /** Controlled fixed-phase compositor test. The full-screen files need
     * independent offline scanning before this becomes a visual safety PASS. */
    @Test fun r26VisibleDirectUnlockAndRapidRelock() {
        assertEquals(35, Build.VERSION.SDK_INT)
        val args = InstrumentationRegistry.getArguments()
        val source = requireNotNull(args.getString("sourceSha"))
        require(source.matches(Regex("[0-9a-f]{40}")))
        val run = UUID.fromString(requireNotNull(args.getString("runUuid"))).toString()
        val dir = File(context.filesDir, "keyguard-service-probe/r26/$run/visible-unlock")
        check(dir.mkdirs())
        val keyguard = context.getSystemService(KeyguardManager::class.java)
        val power = context.getSystemService(PowerManager::class.java)
        automation = instrumentation.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        val resolver = context.contentResolver
        val savedServices = Settings.Secure.getString(resolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        val savedEnabled = Settings.Secure.getString(resolver, Settings.Secure.ACCESSIBILITY_ENABLED)
        val savedLock = shell("locksettings get-disabled").trim()
        val savedSettings = preferences("fluvi_native_keyguard_card")
        val savedMaterial = preferences("fluvi_keyguard_header_material")
        val savedMode = preferences("fluvi_keyguard_orb_diagnostic_route")
        val component = ComponentName(context, FluviKeyguardCardService::class.java)
        val other = savedServices.orEmpty().split(':').filter {
            it.isNotBlank() && ComponentName.unflattenFromString(it) != component
        }.joinToString(":")
        data class Frame(val index:Int, val before:Long, val after:Long, val crop:Bitmap)
        val frames = Collections.synchronizedList(mutableListOf<Frame>())
        val errors = Collections.synchronizedList(mutableListOf<String>())
        val stop = AtomicBoolean(false); val first = CountDownLatch(1)
        val ack = AtomicReference<Runnable?>(); val ackHeld = CountDownLatch(1)
        val savedDispatcher = KeyguardOrbSurfaceWorkerTestHooks.dispatchRevealDone
        val savedTime = KeyguardOrbSurfaceWorkerTestHooks.fixedMaterialTime
        var visual: KeyguardR22VisualCalibration? = null; var collector: Thread? = null
        var service: FluviKeyguardCardService? = null; var capture = false
        try {
            check(!FluviKeyguardCardServiceRegistry.connected && !keyguard.isDeviceSecure)
            check(savedLock == "true" || savedLock == "false")
            setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, other)
            shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard")
            await("unlocked setup", 8_000) { power.isInteractive && !keyguard.isKeyguardLocked }
            saveScreenshot(File(dir, "unlocked-before-lock.png"))
            shell("locksettings set-disabled false")
            check(context.getSharedPreferences("fluvi_keyguard_orb_diagnostic_route", Context.MODE_PRIVATE)
                .edit().putString("mode", "SURFACE_LIVE").commit())
            instrumentation.runOnMainSync {
                FluviKeyguardCardSettings.update(context, mapOf("requested" to true, "showFinancialDetails" to true,
                    "presentationMode" to "orb", "animationMode" to "orbOnly"))
                val epoch = maxOf(SystemClock.elapsedRealtimeNanos(), (savedMaterial.second["publisherEpoch"] as? Long ?: -1L) + 1L)
                check(FluviKeyguardMaterialStore.publish(context, KeyguardR12ServiceTimingInstrumentationTest().materialProfile(), epoch))
            }
            visual = KeyguardR22VisualCalibration(instrumentation, dir, automation).also { it.calibrate() }
            KeyguardOrbSurfaceWorkerTestHooks.fixedMaterialTime = KeyguardR22VisualCalibration.timeA
            KeyguardOrbSurfaceWorkerTestHooks.dispatchRevealDone = { task ->
                if (ack.compareAndSet(null, task)) ackHeld.countDown() else Handler(Looper.getMainLooper()).post(task)
            }
            KeyguardCardDiagnostics.startCapture(context, source, "debug", "LIGHT"); capture = true
            setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
                listOf(other, component.flattenToString()).filter(String::isNotBlank).joinToString(":"))
            setSecure(Settings.Secure.ACCESSIBILITY_ENABLED, "1")
            await("service connected", 10_000) { FluviKeyguardCardServiceRegistry.connected }
            val actual = checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation()); service = actual
            shell("input keyevent KEYCODE_SLEEP"); await("locked sleep", 8_000) { !power.isInteractive && keyguard.isKeyguardLocked }
            shell("input keyevent KEYCODE_WAKEUP")
            assertTrue("NOT REACHED: direct reveal acknowledgement", ackHeld.await(20, TimeUnit.SECONDS))
            var identity:KeyguardR22VisualIdentityForTest? = null
            await("attached exact direct owner", 15_000) {
                instrumentation.runOnMainSync { identity=actual.r22VisualIdentityForTest() }
                identity != null && keyguard.isKeyguardLocked
            }
            val old = checkNotNull(identity)
            var positiveFile:String? = null
            repeat(24) { index ->
                if (positiveFile == null) {
                    val label = "visible-positive-$index"
                    val crop = checkNotNull(visual).captureCrop(label, old.bounds)
                    if (KeyguardR22VisualCalibration.compare(checkNotNull(visual).a, crop).nearlyEqual()) positiveFile = "$label-full.png"
                }
            }
            assertNotNull("NOT REACHED: actual composed FULL reference", positiveFile)
            var row = ""
            fun exactRow(report:String):String? = report.lineSequence().firstOrNull {
                it.startsWith(" R26_DIRECT ") && it.contains("owner=${old.reservationId}/") &&
                    it.contains("/${old.outputGeneration}/${old.attachment} ")
            }
            await("actual direct reveal receipt", 15_000) {
                row = exactRow(KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String) ?: ""
                row.isNotEmpty() && !row.contains("reveal=UNOBSERVED/") && !row.contains("showing=UNOBSERVED/")
            }
            File(dir,"before-unlock-capture.txt").writeText(KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String)
            val sourceVisual = checkNotNull(visual)
            collector = Thread({
                try {
                    var index=0
                    while(!stop.get() && index<24) {
                        val before=SystemClock.uptimeMillis()
                        val crop=sourceVisual.captureCrop("unlock-sample-$index",old.bounds)
                        val after=SystemClock.uptimeMillis()
                        frames.add(Frame(index,before,after,crop)); first.countDown(); index++
                    }
                } catch(t:Throwable) { errors.add("collector:${t.javaClass.simpleName}:${t.message}"); first.countDown() }
            },"r26-unlock-screenshots").apply { isDaemon=true; start() }
            assertTrue("NOT REACHED: first full-screen sample", first.await(15,TimeUnit.SECONDS))
            val commandAt=SystemClock.uptimeMillis()
            shell("wm dismiss-keyguard")
            await("actual unlocked state", 10_000) { power.isInteractive && !keyguard.isKeyguardLocked }
            val unlockedObserved=SystemClock.uptimeMillis()
            var removeAt=0L
            await("exact owner sealed, retired and removed", 15_000) {
                row=exactRow(KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String) ?: ""
                val remove=Regex("localRemove=([0-9]+)/([0-9]+)").find(row)?.groupValues?.get(2)?.toLongOrNull()
                val ready=remove!=null && !row.contains("seal=UNOBSERVED/") && !row.contains("retire=UNOBSERVED/")
                if(ready) removeAt=checkNotNull(remove)
                ready
            }
            instrumentation.runOnMainSync { checkNotNull(ack.getAndSet(null)).run() }
            val ackDelivered=SystemClock.uptimeMillis(); val cutoff=maxOf(removeAt,ackDelivered)
            KeyguardOrbSurfaceWorkerTestHooks.dispatchRevealDone=savedDispatcher
            await("three complete post-removal frames", 15_000) {
                synchronized(frames) { frames.count { it.before>cutoff }>=3 } || errors.isNotEmpty() || collector?.isAlive==false
            }
            stop.set(true); collector?.join(15_000)
            assertFalse("NOT REACHED: screenshot worker did not stop",collector?.isAlive==true)
            assertTrue("NOT REACHED: screenshot worker failed: $errors",errors.isEmpty())
            val savedFrames=synchronized(frames) { frames.toList() }
            assertTrue("NOT REACHED: no frame preceding unlock command",savedFrames.any { it.after<commandAt })
            assertTrue("NOT REACHED: fewer than three post-removal frames",savedFrames.count { it.before>cutoff }>=3)
            File(dir,"after-unlock-capture.txt").writeText(KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String)
            // Relock on the same service before obtaining a disconnected
            // underlay, so generation identities remain comparable.
            assertTrue("NOT REACHED: original service changed before relock",FluviKeyguardCardServiceRegistry.serviceForInstrumentation() === actual)
            shell("input keyevent KEYCODE_SLEEP"); await("rapid relock sleep", 8_000) { !power.isInteractive && keyguard.isKeyguardLocked }
            shell("input keyevent KEYCODE_WAKEUP")
            var fresh:KeyguardR22VisualIdentityForTest?=null
            await("fresh direct generation after relock",20_000) {
                instrumentation.runOnMainSync { fresh=actual.r22VisualIdentityForTest() }
                fresh?.let { it.winningRequestId != null && it.reservationId!=old.reservationId && (it.attachment!=old.attachment || it.outputGeneration!=old.outputGeneration || it.childIdentity!=old.childIdentity) } == true
            }
            var freshPositive:String?=null
            repeat(24) { index ->
                if(freshPositive==null) {
                    val label="fresh-relock-$index"
                    val crop=sourceVisual.captureCrop(label,checkNotNull(fresh).bounds)
                    if(KeyguardR22VisualCalibration.compare(sourceVisual.a,crop).nearlyEqual()) freshPositive="$label-full.png"
                }
            }
            assertNotNull("NOT REACHED: fresh relock did not compose FULL",freshPositive)
            shell("wm dismiss-keyguard"); await("unlocked before independent underlay",10_000) { power.isInteractive && !keyguard.isKeyguardLocked }
            setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,other)
            await("service disconnected for unlocked underlay", 10_000) { !FluviKeyguardCardServiceRegistry.connected }
            val underlay=sourceVisual.captureCrop("independent-unlocked-underlay",old.bounds)
            assertFalse("NOT REACHED: underlay matches old full content",KeyguardR22VisualCalibration.compare(sourceVisual.a,underlay).nearlyEqual())
            val categories=sourceVisual.classifyAfterExclusion(savedFrames.map { it.crop },underlay)
            val afterIndices=savedFrames.indices.filter { savedFrames[it].before>cutoff }
            assertTrue("old FULL or ambiguous output after actual removal: ${afterIndices.map { categories[it] }}",
                afterIndices.all { categories[it]=="UNDERLAY" })
            val evidence = org.json.JSONObject()
            evidence.put("source",source).put("scenario","visible-unlock").put("reservation",old.reservationId)
                .put("attachment",old.attachment).put("output",old.outputGeneration).put("child",old.childIdentity)
                .put("target_rect",org.json.JSONArray(listOf(old.bounds.left,old.bounds.top,old.bounds.right,old.bounds.bottom)))
                .put("positive",positiveFile).put("reference_a","reference-A.png").put("reference_b","reference-B.png")
                .put("underlay","independent-unlocked-underlay-full.png").put("command_at",commandAt)
                .put("unlocked_observed",unlockedObserved).put("remove_return",removeAt).put("ack_delivered",ackDelivered)
                .put("fresh_reservation",checkNotNull(fresh).reservationId).put("fresh_positive",freshPositive)
                .put("fresh_rect",org.json.JSONArray(listOf(checkNotNull(fresh).bounds.left,checkNotNull(fresh).bounds.top,
                    checkNotNull(fresh).bounds.right,checkNotNull(fresh).bounds.bottom))).put("fixed_phase",true)
                .put("samples",org.json.JSONArray(savedFrames.mapIndexed { index,frame -> org.json.JSONObject()
                    .put("index",frame.index).put("before",frame.before).put("after",frame.after)
                    .put("file","unlock-sample-${frame.index}-full.png").put("crop_category",categories[index]) }))
            File(dir,"manifest.json").writeText(evidence.toString(2))
            File(dir,"result.txt").writeText("source=$source scenario=visible-unlock verdict=PASS_PENDING_OFFLINE physical=UNOBSERVED\n")
        } catch(t:Throwable) { errors.add("${t.javaClass.simpleName}:${t.message}") }
        finally {
            stop.set(true); collector?.join(15_000)
            ack.getAndSet(null)?.let { task -> Handler(Looper.getMainLooper()).post(task) }
            KeyguardOrbSurfaceWorkerTestHooks.dispatchRevealDone=savedDispatcher
            KeyguardOrbSurfaceWorkerTestHooks.fixedMaterialTime=savedTime
            if(capture) runCatching { File(dir,"frozen.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"] as String) }
            runCatching { visual?.close() }
            runCatching {
                setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,other)
                await("service disconnected",8_000) { !FluviKeyguardCardServiceRegistry.connected }
                restore(savedSettings); restore(savedMaterial); restore(savedMode)
                shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard")
                if(savedLock=="true" || savedLock=="false") shell("locksettings set-disabled $savedLock")
                setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,savedServices)
                setSecure(Settings.Secure.ACCESSIBILITY_ENABLED,savedEnabled)
            }.onFailure { errors.add("cleanup:${it.javaClass.simpleName}:${it.message}") }
            if(errors.isNotEmpty()) File(dir,"result.txt").writeText("source=$source scenario=visible-unlock verdict=FAIL_OR_NOT_REACHED physical=UNOBSERVED\n")
            File(dir,"errors.txt").writeText(synchronized(errors) { errors.joinToString("\n",postfix="\n") })
        }
        assertTrue("R26 visible unlock specimen: ${errors.joinToString(" | ")}",errors.isEmpty())
    }

    private fun saveScreenshot(file: File) {
        val image = checkNotNull(automation.takeScreenshot())
        file.outputStream().use { check(image.compress(Bitmap.CompressFormat.PNG, 100, it)) }
        image.recycle()
    }
    private fun shell(command: String): String = ParcelFileDescriptor.AutoCloseInputStream(
        automation.executeShellCommand(command)).bufferedReader().use { it.readText() }
    private fun setSecure(key: String, value: String?) {
        automation.adoptShellPermissionIdentity(Manifest.permission.WRITE_SECURE_SETTINGS)
        try { check(Settings.Secure.putString(context.contentResolver, key, value)) }
        finally { automation.dropShellPermissionIdentity() }
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
}
