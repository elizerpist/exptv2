package com.fluvi.app.lockscreen

import android.Manifest
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.KeyguardManager
import android.app.UiAutomation
import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.os.ParcelFileDescriptor
import android.os.PowerManager
import android.os.SystemClock
import android.provider.Settings
import android.view.Display
import android.view.accessibility.AccessibilityEvent
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.fluvi.app.lockscreen.material.FluviKeyguardMaterialStore
import com.fluvi.app.lockscreen.material.KeyguardMaterialTime
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

/** Real-service fixture. Controlled metadata remains explicitly labelled;
 * only Android's own reader/classifier can produce a visibility decision. */
internal class KeyguardR22FirstInspectionFixture {
    private data class PostedFrame(val attachment: Long, val generation: Long, val child: Int?,
        val width: Int, val height: Int, val densityDpi: Int,
        val time: KeyguardMaterialTime, val at: Long, val full: Boolean)
    private data class VisualEdge(val ordinal: Long, val at: Long, val kind: String, val child: Int?, val full: Boolean)
    private data class IngressEdge(val ordinal: Long, val at: Long, val window: Int)

    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val context get() = instrumentation.targetContext
    private lateinit var automation: UiAutomation

    fun run(scenario: String) {
        require(scenario in setOf("positive", "negative", "stable", "natural", "automation", "r31_system", "r31_ambiguous", "r31_negative", "r31_system_structural", "r31_ambiguous_structural"))
        val r31 = scenario.startsWith("r31_")
        val structuralOnly = scenario.endsWith("_structural")
        val negativeScene = scenario == "negative" || scenario == "r31_negative"
        assertEquals(35, Build.VERSION.SDK_INT)
        val args = InstrumentationRegistry.getArguments()
        val source = requireNotNull(args.getString("sourceSha"))
        require(source.matches(Regex("[0-9a-f]{40}")))
        val uuid = UUID.fromString(requireNotNull(args.getString("runUuid"))).toString()
        val dir = File(context.filesDir, "keyguard-service-probe/r22/$uuid/$scenario")
        check(dir.mkdirs())
        automation = instrumentation.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        automation.serviceInfo = automation.serviceInfo.apply {
            flags = flags or AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
        }
        val keyguard = context.getSystemService(KeyguardManager::class.java)
        val power = context.getSystemService(PowerManager::class.java)
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
        val records = Collections.synchronizedList(mutableListOf<String>())
        val entryArmed = AtomicBoolean(false)
        val entryStarted = CountDownLatch(1)
        val releaseEntry = CountDownLatch(1)
        val entered = CountDownLatch(1)
        val release = CountDownLatch(1)
        val firstChildHeld = AtomicBoolean(false)
        val firstChildObserved = AtomicBoolean(false)
        val independentWindowId = AtomicLong(-1L)
        val entryTimedOut = AtomicBoolean(false)
        val childTimedOut = AtomicBoolean(false)
        val bEntryTimedOut = AtomicBoolean(false)
        val stableReading = AtomicBoolean(false)
        val stableExternal = AtomicBoolean(false)
        val completed = CountDownLatch(1)
        val bStarted = CountDownLatch(1)
        val a = AtomicReference<KeyguardCardInspectionRequest?>()
        val reservation = AtomicLong(0L)
        val posted = AtomicReference<PostedFrame?>()
        val visualOrdinal = AtomicLong(0)
        val visualEdges = Collections.synchronizedList(mutableListOf<VisualEdge>())
        val ingressEdges = Collections.synchronizedList(mutableListOf<IngressEdge>())
        val visualOverflow = AtomicBoolean(false)
        val savedRevealCross = KeyguardOrbSurfaceWorkerTestHooks.afterRevealCross
        val observedPostClaim = AtomicReference<KeyguardOpeningInspectionHandoff.PostClaimSnapshot?>()
        var calibration: KeyguardR22VisualCalibration? = null
        var visualIdentity: KeyguardR22VisualIdentityForTest? = null
        var visualUnderlay: android.graphics.Bitmap? = null
        var visualUnderlayFull: android.graphics.Bitmap? = null
        var underlayBefore = 0L
        var underlayAfter = 0L
        var underlayBounds: android.graphics.Rect? = null
        val inventorySamples = mutableListOf<String>()
        var visualCalibration = "NOT_REACHED"
        val b = AtomicLong(0L)
        val injectedAt = AtomicLong(0L)
        val afterB = AtomicBoolean(false)
        val nextChild = AtomicBoolean(false)
        val recordObservation = AtomicReference<KeyguardR15AcquisitionTestHooks.Observation?>()
        val bFinished = CountDownLatch(1)
        val cFinished = CountDownLatch(1)
        val secondOfferAt = AtomicLong(0L)
        val c = AtomicLong(0L)
        val bYieldedTo = AtomicLong(0L)
        val cThread = AtomicLong(0L)
        val bChildHeld = AtomicBoolean(false)
        val secondOffered = AtomicBoolean(false)
        val bCallsAfterOffer = AtomicLong(0L)
        val resultC = AtomicReference<String?>()
        val bEntered = CountDownLatch(1)
        val releaseB = CountDownLatch(1)
        val realNegativeEvent = CountDownLatch(1)
        val realNegativePending = CountDownLatch(1)
        val pendingWindows = Collections.synchronizedList(mutableListOf<Pair<Long, Int>>())
        val negativeResult = CountDownLatch(1)
        val negativeArmed = AtomicBoolean(false)
        val resultB = AtomicReference<String?>()
        val yieldedTo = AtomicLong(0L)
        val aThread = AtomicLong(0L)
        val bThread = AtomicLong(0L)
        var capture = false
        var report: String? = null
        val errors = mutableListOf<String>()
        try {
            check(!FluviKeyguardCardServiceRegistry.connected)
            check(!keyguard.isDeviceSecure)
            check(savedLock == "true" || savedLock == "false")
            setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, other)
            await("previous service disconnected", 8_000) { !FluviKeyguardCardServiceRegistry.connected }
            shell("input keyevent KEYCODE_WAKEUP")
            shell("wm dismiss-keyguard")
            await("unlocked", 5_000) { power.isInteractive && !keyguard.isKeyguardLocked }
            shell("locksettings set-disabled false")
            check(context.getSharedPreferences("fluvi_keyguard_orb_diagnostic_route", Context.MODE_PRIVATE)
                .edit().putString("mode", "SURFACE_LIVE").commit())
            instrumentation.runOnMainSync {
                FluviKeyguardCardSettings.update(context, mapOf("requested" to true,
                    "showFinancialDetails" to true, "presentationMode" to "orb", "animationMode" to "orbOnly"))
                val epoch = maxOf(SystemClock.elapsedRealtimeNanos(),
                    (savedMaterial.second["publisherEpoch"] as? Long ?: -1L) + 1L)
                check(FluviKeyguardMaterialStore.publish(context,
                    KeyguardR12ServiceTimingInstrumentationTest().materialProfile(), epoch))
            }
            if (scenario != "natural") {
                automationEvidence(dir, "before-calibration")
                calibration = KeyguardR22VisualCalibration(instrumentation, dir, automation).also { it.calibrate() }
                automationEvidence(dir, "after-calibration")
                visualCalibration = "REFERENCE_CALIBRATED_SERVICE_NOT_REACHED"
                KeyguardOrbSurfaceWorkerTestHooks.fixedMaterialTime = KeyguardR22VisualCalibration.timeA
                KeyguardOrbSurfaceWorkerTestHooks.postedMaterialTime = { target, time, at ->
                    posted.set(PostedFrame(target.attachment, target.generation, target.directOutput?.childId,
                        target.width, target.height, target.densityDpi, time, at, target.full))
                    if (negativeArmed.get()) synchronized(visualEdges) {
                        if (visualEdges.size < 512) visualEdges += VisualEdge(visualOrdinal.incrementAndGet(),
                            at, "POST", target.directOutput?.childId, target.full)
                        else visualOverflow.set(true)
                    }
                }
                KeyguardOrbSurfaceWorkerTestHooks.afterRevealCross = { output ->
                    if (negativeArmed.get()) synchronized(visualEdges) {
                        if (visualEdges.size < 512) visualEdges += VisualEdge(visualOrdinal.incrementAndGet(),
                            SystemClock.uptimeMillis(), "CROSS", output.childId, true)
                        else visualOverflow.set(true)
                    }
                    savedRevealCross?.invoke(output)
                }
            }
            KeyguardCardDiagnostics.startCapture(context, source, "debug", "LIGHT")
            capture = true
            KeyguardR15AcquisitionTestHooks.stockArm = true
            KeyguardR15AcquisitionTestHooks.historicalRootOnlyOptIn = false
            KeyguardR15AcquisitionTestHooks.observeIneligible = true
            KeyguardR15AcquisitionTestHooks.observer = { observation ->
                if (observation.request.id == a.get()?.id) {
                    recordObservation.set(observation)
                    records.add("A_RESULT id=${observation.request.id} eligible=${observation.eligible} " +
                        "decision=${observation.decision} reason=${observation.reason} " +
                        "unavailable=${observation.result.rootUnavailable} truncated=${observation.result.walkTruncated} " +
                        "stale=${observation.result.abortedStale} children=${observation.result.timing.childAcquisitionCount}")
                }
            }
            setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
                listOf(other, component.flattenToString()).filter(String::isNotBlank).joinToString(":"))
            setSecure(Settings.Secure.ACCESSIBILITY_ENABLED, "1")
            await("service connected", 10_000) { FluviKeyguardCardServiceRegistry.connected }
            val service = checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation())
            automationEvidence(dir, "service-connected")
            records.add("AUTOMATION_CONNECTED actual=true handle=${System.identityHashCode(automation)} at=${SystemClock.uptimeMillis()}")
            instrumentation.runOnMainSync {
                service.inspectionProbeForTest = object : KeyguardInspectionProbeForTest {
                    override fun openingReserved(request: KeyguardCardInspectionRequest, reservationId: Long, armed: Boolean) {
                        records.add("RESERVED id=${request.id} wake=${request.wakeGeneration} reservation=$reservationId armed=$armed at=${SystemClock.uptimeMillis()}")
                        if (entryArmed.get() && armed && a.compareAndSet(null, request)) reservation.set(reservationId)
                    }
                    override fun started(request: KeyguardCardInspectionRequest) {
                        records.add("START id=${request.id} wake=${request.wakeGeneration} at=${SystemClock.uptimeMillis()} thread=${Thread.currentThread().id}")
                        if (request == a.get()) {
                            aThread.set(Thread.currentThread().id)
                            entryStarted.countDown()
                            if (scenario != "natural" && !releaseEntry.await(20, TimeUnit.SECONDS)) {
                                entryTimedOut.set(true); records.add("A_ENTRY_TIMEOUT")
                            }
                        }
                        if (request.id == bYieldedTo.get() && request.id != 0L) cThread.set(Thread.currentThread().id)
                        if (request.id == yieldedTo.get() && request.id != 0L) {
                            bThread.set(Thread.currentThread().id)
                            bStarted.countDown()
                            if (scenario == "negative") {
                                bEntered.countDown()
                                if (!releaseB.await(20, TimeUnit.SECONDS)) {
                                    bEntryTimedOut.set(true); records.add("B_ENTRY_TIMEOUT")
                                }
                            }
                        }
                    }
                    override fun openingChildBefore(request: KeyguardCardInspectionRequest, windowId: Int, index: Int) {
                        if (afterB.get() && request == a.get()) {
                            nextChild.set(true)
                            records.add("A_NEXT_CHILD_BEFORE id=${request.id} window=$windowId index=$index at=${SystemClock.uptimeMillis()}")
                        }
                    }
                    override fun openingChildReturned(request: KeyguardCardInspectionRequest, windowId: Int, index: Int, present: Boolean) {
                        if (present && request == a.get() && firstChildObserved.compareAndSet(false, true)) {
                            records.add("A_FIRST_CHILD_RETURN id=${request.id} wake=${request.wakeGeneration} window=$windowId index=$index at=${SystemClock.uptimeMillis()}")
                            // Preserve the historical non-suppressing handle
                            // witness; controlled cases use the later eligible checkpoint.
                            if (scenario == "automation") {
                                firstChildHeld.set(true)
                                entered.countDown()
                                if (!release.await(20, TimeUnit.SECONDS)) {
                                    childTimedOut.set(true); records.add("A_CHILD_TIMEOUT")
                                }
                            }
                        }
                    }
                    override fun openingEligibleCheckpoint(request: KeyguardCardInspectionRequest, windowId: Int, nextIndex: Int) {
                        if ((r31 || scenario in setOf("positive", "negative", "stable")) && request == a.get() &&
                            firstChildObserved.get() && windowId.toLong() == independentWindowId.get() &&
                            firstChildHeld.compareAndSet(false, true)) {
                            records.add("A_ELIGIBLE_CHECKPOINT id=${request.id} window=$windowId next=$nextIndex at=${SystemClock.uptimeMillis()}")
                            entered.countDown()
                            if (!release.await(20, TimeUnit.SECONDS)) {
                                childTimedOut.set(true); records.add("A_CHECKPOINT_TIMEOUT")
                            }
                        }
                    }
                    override fun postClaimObserved(snapshot: KeyguardOpeningInspectionHandoff.PostClaimSnapshot) {
                        observedPostClaim.updateAndGet { previous ->
                            if (previous == null || snapshot.ordinal > previous.ordinal) snapshot else previous
                        }
                        records.add("POST_CLAIM ordinal=${snapshot.ordinal} first=${snapshot.first?.id} latest=${snapshot.latest?.id} offers=${snapshot.offers} replacements=${snapshot.replacements}")
                    }
                    override fun yielded(request: KeyguardCardInspectionRequest, successor: KeyguardCardInspectionRequest,
                        startedAt: Long, finishedAt: Long, visited: Int) {
                        if (request.id == a.get()?.id) {
                            yieldedTo.set(successor.id)
                            records.add("YIELDED A=${request.id} B=${successor.id} start=$startedAt end=$finishedAt visited=$visited")
                            completed.countDown()
                        } else if (r31 && request.id == yieldedTo.get() && request.id != 0L) {
                            bYieldedTo.set(successor.id)
                            records.add("R31_YIELDED B=${request.id} C=${successor.id} start=$startedAt end=$finishedAt visited=$visited")
                            bFinished.countDown()
                        }
                    }
                    override fun readCompleted(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility,
                        reason: KeyguardSurfaceReason, rootUnavailable: Boolean, walkTruncated: Boolean,
                        abortedStale: Boolean, startedAt: Long, finishedAt: Long) {
                        records.add("END id=${request.id} decision=$decision reason=$reason root=$rootUnavailable truncated=$walkTruncated stale=$abortedStale")
                        if (request.id == a.get()?.id) {
                            stableReading.set(false)
                            resultB.compareAndSet(null, "A:$decision/$reason/$rootUnavailable/$walkTruncated/$abortedStale")
                            completed.countDown()
                        }
                        if (request.id == yieldedTo.get() && request.id > 0L) {
                            resultB.set("B:$decision/$reason/$rootUnavailable/$walkTruncated/$abortedStale")
                            bFinished.countDown()
                        }
                        if (r31 && request.id == bYieldedTo.get() && request.id > 0L) {
                            resultC.set("C:$decision/$reason/$rootUnavailable/$walkTruncated/$abortedStale")
                            cFinished.countDown()
                        }
                        if (negativeArmed.get() && !abortedStale && decision in setOf(
                                KeyguardCardVisibility.HIDDEN_SHADE, KeyguardCardVisibility.HIDDEN_CREDENTIAL,
                                KeyguardCardVisibility.HIDDEN_UNLOCKED)) negativeResult.countDown()
                    }
                    override fun ingress(meta: KeyguardAccessibilityEventMeta, receivedAt: Long,
                        action: KeyguardEventAction, frameworkEvent: Boolean) {
                        if (negativeArmed.get() && frameworkEvent && action == KeyguardEventAction.INSPECT &&
                            (meta.displayId == Display.DEFAULT_DISPLAY || meta.displayId < 0)) {
                            ingressEdges.add(IngressEdge(visualOrdinal.incrementAndGet(), receivedAt, meta.windowId))
                            records.add("REAL_NEGATIVE_EVENT type=${meta.eventType} window=${meta.windowId} display=${meta.displayId} at=$receivedAt")
                            realNegativeEvent.countDown()
                        }
                    }
                    override fun ingressOffered(meta: KeyguardAccessibilityEventMeta, request: KeyguardCardInspectionRequest,
                        previous: KeyguardCardInspectionRequest?, pending: KeyguardCardInspectionRequest?,
                        startsWorker: Boolean, frameworkEvent: Boolean) {
                        if (scenario == "stable" && stableReading.get() && frameworkEvent) stableExternal.set(true)
                        if (negativeArmed.get() && frameworkEvent && !startsWorker && pending?.id == request.id) {
                            pendingWindows.add(request.id to meta.windowId)
                            records.add("REAL_NEGATIVE_PENDING id=${request.id} window=${meta.windowId} previous=${previous?.id} at=${SystemClock.uptimeMillis()}")
                            realNegativePending.countDown()
                        }
                        if (r31 && !frameworkEvent && secondOfferAt.get() != 0L && meta.eventTimeUptimeMs == secondOfferAt.get()) {
                            c.set(request.id)
                            records.add("R31_C_OFFER id=${request.id} pending=${pending?.id} origin=${request.r14Ingress?.origin} previous=${previous?.id} at=${SystemClock.uptimeMillis()}")
                            if (pending?.id == request.id && !startsWorker) secondOffered.set(true)
                        }
                        if (!frameworkEvent && meta.eventTimeUptimeMs == injectedAt.get() &&
                            (!r31 || secondOfferAt.get() == 0L)) {
                            b.set(request.id)
                            records.add("B_OFFER id=${request.id} pending=${pending?.id} activeWorker=${!startsWorker} " +
                                "wake=${request.wakeGeneration} at=${SystemClock.uptimeMillis()} framework=false")
                            if (pending?.id == request.id && !startsWorker) afterB.set(true)
                        }
                    }
                }
            }
            if (r31) {
                KeyguardR15AcquisitionTestHooks.beforeChildCall = { request, window, index ->
                    if (request.id == yieldedTo.get() && secondOffered.get()) {
                        bCallsAfterOffer.incrementAndGet()
                        records.add("R31_B_CHILD_AFTER_C window=$window index=$index at=${SystemClock.uptimeMillis()}")
                    }
                }
                KeyguardR15AcquisitionTestHooks.afterReturnedChild = { request, window, index, present, _ ->
                    if (request.id == yieldedTo.get() && request.id != 0L && present &&
                        window.toLong() == independentWindowId.get() && bChildHeld.compareAndSet(false, true)) {
                        records.add("R31_B_CHILD_RETURN id=${request.id} window=$window index=$index at=${SystemClock.uptimeMillis()}")
                        bEntered.countDown()
                        if (!releaseB.await(20, TimeUnit.SECONDS)) { bEntryTimedOut.set(true); records.add("R31_B_CHILD_TIMEOUT") }
                    }
                }
            }
            fun verifyExclusionPixels(visual: KeyguardR22VisualCalibration,
                identity: KeyguardR22VisualIdentityForTest, samples: List<android.graphics.Bitmap>,
                shadeWindow: Int, label: String) {
                val cause = synchronized(ingressEdges) { ingressEdges.firstOrNull { it.window == shadeWindow } }
                assertNotNull("NOT REACHED: no real ingress for observed shade window", cause)
                val beforeDisconnect = visual.captureCrop("$label-before-service-disconnect", identity.bounds)
                setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, other)
                await("service disconnected for independent shade underlay", 8_000) { !FluviKeyguardCardServiceRegistry.connected }
                assertEquals("NOT REACHED: shade disappeared before underlay reference",
                    shadeWindow, independentShadeWindow())
                val independentUnderlay = visual.captureCrop("$label-independent-shade-underlay", identity.bounds)
                assertTrue("NOT REACHED: actual removal did not match independent shade underlay",
                    KeyguardR22VisualCalibration.compare(beforeDisconnect, independentUnderlay).nearlyEqual())
                val categories = visual.classifyAfterExclusion(samples, independentUnderlay)
                File(dir, "$label-visual-categories.txt").writeText(categories.joinToString("\n", postfix = "\n"))
                assertFalse("old FULL was observed after exclusion", categories.contains("OLD_FULL"))
                assertFalse("NOT REACHED: exclusion images remained unclassified", categories.contains("UNCLASSIFIED"))
                assertFalse("NOT REACHED: visual edge history overflowed", visualOverflow.get())
                val late = synchronized(visualEdges) {
                    visualEdges.filter { it.ordinal > checkNotNull(cause).ordinal &&
                        it.child == identity.childIdentity && (it.kind == "CROSS" || (it.kind == "POST" && it.full)) }
                }
                assertTrue("stale full paint or reveal after shade ingress: $late", late.isEmpty())
                records.add("EXCLUSION_VISUAL label=$label shadeWindow=$shadeWindow ingress=$cause categories=$categories compositorRemoval=OBSERVED physical=UNOBSERVED")
            }

            shell("input keyevent KEYCODE_SLEEP")
            await("sleep/locked", 8_000) { !power.isInteractive && keyguard.isKeyguardLocked }
            entryArmed.set(true)
            shell("input keyevent KEYCODE_WAKEUP")
            await("locked/interactive", 5_000) { power.isInteractive && keyguard.isKeyguardLocked }
            if (scenario == "natural") {
                assertTrue("NOT REACHED: no original reserved opening was observed", entryStarted.await(20, TimeUnit.SECONDS))
                assertTrue("NOT REACHED: natural opening did not finish or yield", completed.await(20, TimeUnit.SECONDS))
                val original = checkNotNull(a.get())
                val snapshot = KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String
                File(dir, "before-freeze.txt").writeText(snapshot)
                assertTrue("NOT REACHED: missing exact natural opening core", snapshot.lineSequence().any {
                    it.startsWith(" R22_CORE ") && it.contains("opening=${original.id}/")
                })
                automation.takeScreenshot()?.let { image ->
                    File(dir, "natural-unclassified.png").outputStream().use {
                        image.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, it)
                    }
                    image.recycle()
                }
                records.add("NATURAL_UNHELD A=${original.id} yieldedTo=${yieldedTo.get()} injected=false physical=UNOBSERVED")
            } else if (scenario == "automation") {
                assertTrue("NOT REACHED: no original reserved opening entered its physical read", entryStarted.await(20, TimeUnit.SECONDS))
                val original = checkNotNull(a.get())
                records.add("AUTOMATION_ORIGINAL_A id=${original.id} wake=${original.wakeGeneration} reservation=${reservation.get()}")
                var independent = ""
                await("NOT REACHED: independent locked SystemUI MAIN window", 8_000) {
                    independent = independentOpeningScene(service)
                    independent.startsWith("VALID ")
                }
                File(dir, "independent-window-inventory.txt").writeText(independent + "\n")
                records.add("AUTOMATION_WINDOW $independent")
                assertFalse("NOT REACHED: original A entry barrier expired", entryTimedOut.get())
                releaseEntry.countDown()
                assertTrue("NOT REACHED: original opening returned no real child", entered.await(20, TimeUnit.SECONDS))
                assertFalse("NOT REACHED: original child barrier expired", childTimedOut.get())
                release.countDown()
                records.add("AUTOMATION_CONTROL_REACHED A=${original.id} reservation=${reservation.get()} physical=UNOBSERVED")
            } else {
            assertTrue("NOT REACHED: the exact reserved opening did not enter its physical read", entryStarted.await(20, TimeUnit.SECONDS))
            val original = checkNotNull(a.get())
            var independent = ""
            await("NOT REACHED: independently complete locked SystemUI tree", 8_000) {
                independent = independentOpeningScene(service, requireComplete = true)
                inventorySamples += "at=${SystemClock.uptimeMillis()} $independent"
                independent.startsWith("VALID ")
            }
            records.add("INDEPENDENT_BEFORE_READ $independent")
            val windowId = Regex("activeSystemUi=([0-9]+)").find(independent)?.groupValues?.get(1)?.toLongOrNull()
            independentWindowId.set(checkNotNull(windowId) { "independent active SystemUI identity missing" })
            await("NOT REACHED: original owner host/output geometry", 8_000) {
                instrumentation.runOnMainSync { visualIdentity = service.r22VisualIdentityForTest() }
                visualIdentity?.let { it.reservationId == reservation.get() &&
                    it.openingRequestId == original.id } == true
            }
            assertFalse("NOT REACHED: original A entry barrier expired", entryTimedOut.get())
            val identity = checkNotNull(visualIdentity)
            // Acquire immutable geometry and pixels before A proceeds, but do
            // not encode PNGs or write files while its real reader is held.
            underlayBounds = android.graphics.Rect(identity.bounds)
            underlayBefore = SystemClock.uptimeMillis()
            visualUnderlayFull = checkNotNull(automation.takeScreenshot())
            underlayAfter = SystemClock.uptimeMillis()
            val screen = checkNotNull(visualUnderlayFull)
            val bounds = checkNotNull(underlayBounds)
            check(bounds.left >= 0 && bounds.top >= 0 && bounds.right <= screen.width && bounds.bottom <= screen.height)
            visualUnderlay = android.graphics.Bitmap.createBitmap(screen, bounds.left, bounds.top, bounds.width(), bounds.height())
            records.add("VISUAL_OWNER_BEFORE_READ $identity acquisition=$underlayBefore/$underlayAfter")
            stableReading.set(scenario == "stable")
            if (scenario == "stable") {
                var pendingBefore: KeyguardCardInspectionRequest? = null
                instrumentation.runOnMainSync { pendingBefore = service.inspectionStateForTest().pending }
                records.add("STABLE_BEFORE_RELEASE pending=${pendingBefore?.id} origin=${pendingBefore?.r14Ingress?.origin ?: "NONE"}")
                assertNull("NOT REACHED: stable preparation has an existing pending request", pendingBefore)
            }
            releaseEntry.countDown()
            assertTrue("NOT REACHED: original opening reached no clean eligible post-marker checkpoint", entered.await(20, TimeUnit.SECONDS))
            assertFalse("NOT REACHED: original A child barrier expired", childTimedOut.get())
            if (scenario == "stable") {
                var pending: KeyguardCardInspectionRequest? = null
                instrumentation.runOnMainSync { pending = service.inspectionStateForTest().pending }
                records.add("STABLE_PREEXISTING_PENDING id=${pending?.id} origin=${pending?.r14Ingress?.origin ?: "SYNTHETIC_OR_NONE"} strictQuiet=${pending == null}")
                release.countDown()
                assertTrue("NOT REACHED: stable opening did not complete", completed.await(20, TimeUnit.SECONDS))
                assertEquals("NOT REACHED: no stable complete MAIN/FULL result",
                    "A:SHOW_FULL/MAIN_CONFIRMED/false/false/false", resultB.get())
                assertEquals("stable A must not be yielded", 0L, yieldedTo.get())
                assertFalse("NOT REACHED: external ingress invalidated the stable read", stableExternal.get())
            } else {
                instrumentation.runOnMainSync {
                    val now = SystemClock.uptimeMillis()
                    injectedAt.set(now)
                    service.acceptAccessibilityMetadataForTest(KeyguardAccessibilityEventMeta(
                        AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED, -1, Display.DEFAULT_DISPLAY, 0,
                        "com.android.systemui", now))
                }
                assertTrue("NOT REACHED: controlled real-queue B was not offered", afterB.get())
                assertTrue("NOT REACHED: B id did not advance", b.get() > original.id)
                assertFalse("NOT REACHED: A child barrier expired before B was offered", childTimedOut.get())
                release.countDown()
                assertTrue("NOT REACHED: A reached no useful handoff checkpoint", completed.await(20, TimeUnit.SECONDS))
                assertEquals("NOT REACHED: controlled B was replaced or A finished normally", b.get(), yieldedTo.get())
                assertTrue("NOT REACHED: claimed B did not physically start", bStarted.await(15, TimeUnit.SECONDS))
                assertEquals("B must run on the same physical reader", aThread.get(), bThread.get())
                assertFalse("A requested another child after B was claimed", nextChild.get())
                if (r31 && !negativeScene) {
                    assertTrue("NOT REACHED: B did not return a real SystemUI child", bEntered.await(15, TimeUnit.SECONDS))
                    instrumentation.runOnMainSync {
                        val now = SystemClock.uptimeMillis(); secondOfferAt.set(now)
                        val window = if (scenario.startsWith("r31_system")) independentWindowId.get().toInt() else -1
                        service.acceptAccessibilityMetadataForTest(KeyguardAccessibilityEventMeta(
                            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED, window, Display.DEFAULT_DISPLAY, 0,
                            "com.android.systemui", now))
                    }
                    assertTrue("NOT REACHED: controlled C was not the actual pending occupant", secondOffered.get())
                    assertFalse("NOT REACHED: B child barrier expired", bEntryTimedOut.get())
                    releaseB.countDown()
                    assertTrue("NOT REACHED: B neither yielded nor completed", bFinished.await(20, TimeUnit.SECONDS))
                    records.add("R31_B_TERMINAL result=${resultB.get()} yield=${bYieldedTo.get()} afterC=${bCallsAfterOffer.get()}")
                    if (bYieldedTo.get() == 0L) assertEquals("NOT REACHED: B did not finish a complete FULL read",
                        "B:SHOW_FULL/MAIN_CONFIRMED/false/false/false", resultB.get())
                    assertEquals("R31 RED: B continued instead of transferring to the actual C", c.get(), bYieldedTo.get())
                    assertEquals("B acquired another child after C was offered", 0L, bCallsAfterOffer.get())
                    assertTrue("NOT REACHED: promoted C did not finish", cFinished.await(20, TimeUnit.SECONDS))
                    assertEquals("NOT REACHED: C did not return complete MAIN/FULL", "C:SHOW_FULL/MAIN_CONFIRMED/false/false/false", resultC.get())
                    assertEquals("C must use the one physical reader", aThread.get(), cThread.get())
                } else if (negativeScene) {
                    assertTrue("NOT REACHED: claimed B did not reach the real read-entry boundary", bEntered.await(15, TimeUnit.SECONDS))
                    negativeArmed.set(true)
                    File(dir, "shade-command.txt").writeText(shell("cmd statusbar expand-notifications"))
                    assertTrue("NOT REACHED: no real framework exclusion ingress", realNegativeEvent.await(10, TimeUnit.SECONDS))
                    assertTrue("NOT REACHED: no actual pending exclusion successor", realNegativePending.await(10, TimeUnit.SECONDS))
                    var shadeWindow: Int? = null
                    await("NOT REACHED: independent shade marker", 8_000) {
                        shadeWindow = independentShadeWindow()
                        shadeWindow != null
                    }
                    await("NOT REACHED: real pending ingress for observed shade window", 8_000) {
                        synchronized(pendingWindows) { pendingWindows.any { it.second == shadeWindow } }
                    }
                    assertFalse("NOT REACHED: B entry barrier expired before shade was established", bEntryTimedOut.get())
                    records.add("OBSERVED_SHADE_WINDOW id=$shadeWindow pending=${synchronized(pendingWindows) { pendingWindows.toList() }}")
                    val visual = checkNotNull(calibration)
                    val identity = checkNotNull(visualIdentity)
                    val samples = mutableListOf<android.graphics.Bitmap>()
                    repeat(12) { index ->
                        if (index == 4) releaseB.countDown()
                        samples += visual.captureCrop("negative-after-exclusion-$index", identity.bounds)
                        SystemClock.sleep(40)
                    }
                    assertTrue("NOT REACHED: no complete real shade/credential/unlock result", negativeResult.await(15, TimeUnit.SECONDS))
                    var visible = true
                    instrumentation.runOnMainSync { visible = service.renderModeStatus().visible }
                    assertFalse("negative scene must not expose the orb", visible)
                    verifyExclusionPixels(visual, identity, samples, checkNotNull(shadeWindow), "negative")
                    visualCalibration = "PASS_NEGATIVE"
                } else {
                    assertTrue("NOT REACHED: B did not complete a fresh physical read", bFinished.await(20, TimeUnit.SECONDS))
                    assertEquals("NOT REACHED: B did not return a complete MAIN/FULL classification",
                        "B:SHOW_FULL/MAIN_CONFIRMED/false/false/false", resultB.get())
                }
            }
            if (!negativeScene) {
                await("NOT REACHED: exact direct reveal was not submitted", 15_000) {
                    val current = KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String
                    val winner = if (scenario == "stable") original.id else if (r31) c.get() else b.get()
                    current.lineSequence().any { line ->
                        line.startsWith(" R21_CORE ") && line.contains("/ACCEPTED ingress=") &&
                            line.contains(" reservation=${reservation.get()} ") && line.contains(" consumedReq=$winner ")
                    }
                }
            }
            val snapshot = KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String
            File(dir, "before-freeze.txt").writeText(snapshot)
            val core = snapshot.lineSequence().firstOrNull { it.startsWith(" R22_CORE ") &&
                it.contains("opening=${original.id}/") }
            assertNotNull("missing protected R22 acquisition core", core)
            assertTrue("wrong reservation in protected core", checkNotNull(core).contains("opening=${original.id}/${reservation.get()} "))
            if (scenario == "stable") assertTrue(core.contains("outcome=A_FINISHED/"))
            else {
                assertTrue(core.contains("outcome=YIELDED/"))
                assertTrue(core.contains("claimed=${yieldedTo.get()}@"))
                assertFalse("a yielded A must have no completion classification", core.contains("aResult=SHOW_FULL"))
                if (negativeScene) {
                    val post = checkNotNull(observedPostClaim.get()) { "NOT REACHED: no observed post-claim pending item" }
                    assertTrue("protected core lost the actual first post-claim request", core.contains("postFirst=${post.first?.id}@"))
                    assertTrue("post-claim identity belongs to another reservation", post.reservationId == reservation.get())
                }
            }
            if (!negativeScene) {
                val visual = checkNotNull(calibration)
                val identity = checkNotNull(visualIdentity)
                val underlay = checkNotNull(visualUnderlay)
                val winner = if (scenario == "stable") original.id else if (r31) c.get() else b.get()
                val winningCore = snapshot.lineSequence().singleOrNull { it.startsWith(" R21_CORE ") &&
                    it.contains(" reservation=${reservation.get()} ") && it.contains(" consumedReq=$winner ") }
                assertNotNull("NOT REACHED: no exact protected winner", winningCore)
                val applyAt = Regex(" apply=([0-9]+)/").find(checkNotNull(winningCore))
                    ?.groupValues?.get(1)?.toLongOrNull()
                assertNotNull("NOT REACHED: no exact native apply return", applyAt)
                fun waitPosted(time: KeyguardMaterialTime) {
                    await("NOT REACHED: matching actual worker post $time", 10_000) {
                        var current: KeyguardR22VisualIdentityForTest? = null
                        instrumentation.runOnMainSync { current = service.r22VisualIdentityForTest() }
                        val item = posted.get()
                        val owner = current
                        owner != null && owner.reservationId == identity.reservationId &&
                            owner.openingRequestId == original.id && owner.winningRequestId == winner &&
                            owner.hostIdentity == identity.hostIdentity && owner.attachment == identity.attachment &&
                            owner.outputGeneration == identity.outputGeneration &&
                            owner.childIdentity == identity.childIdentity && owner.bounds == identity.bounds &&
                            item != null && item.attachment == identity.attachment &&
                            item.generation == identity.outputGeneration && item.child == identity.childIdentity &&
                            item.width == identity.bounds.width() && item.height == identity.bounds.height() &&
                            item.densityDpi == context.resources.displayMetrics.densityDpi &&
                            item.full && item.time == time && item.at >= checkNotNull(applyAt)
                    }
                    records.add("MATCHED_WORKER_POST ${posted.get()}")
                }
                waitPosted(KeyguardR22VisualCalibration.timeA)
                visual.awaitServiceMatch("service-phase-A", identity.bounds, visual.a, underlay)
                KeyguardOrbSurfaceWorkerTestHooks.fixedMaterialTime = KeyguardR22VisualCalibration.timeB
                waitPosted(KeyguardR22VisualCalibration.timeB)
                visual.awaitServiceMatch("service-phase-B", identity.bounds, visual.b, underlay)
                KeyguardOrbSurfaceWorkerTestHooks.fixedMaterialTime = KeyguardR22VisualCalibration.timeA
                waitPosted(KeyguardR22VisualCalibration.timeA)
                visual.awaitServiceMatch("service-phase-A-return", identity.bounds, visual.a, underlay)
                if (!structuralOnly) {
                negativeArmed.set(true)
                File(dir, "visual-shade-command.txt").writeText(shell("cmd statusbar expand-notifications"))
                assertTrue("NOT REACHED: no real shade ingress for visual withdrawal", realNegativeEvent.await(10, TimeUnit.SECONDS))
                var shadeWindow: Int? = null
                await("NOT REACHED: independent shade for visual withdrawal", 8_000) {
                    shadeWindow = independentShadeWindow()
                    shadeWindow != null
                }
                val samples = (0 until 12).map { index ->
                    visual.captureCrop("withdrawal-after-exclusion-$index", identity.bounds).also { SystemClock.sleep(40) }
                }
                await("NOT REACHED: actual orb withdrawal", 10_000) {
                    var visible = true
                    instrumentation.runOnMainSync { visible = service.renderModeStatus().visible }
                    !visible
                }
                verifyExclusionPixels(visual, identity, samples, checkNotNull(shadeWindow), "withdrawal")
                visualCalibration = "PASS"
                } else {
                    visualCalibration = "STRUCTURAL_A_B_A_ONLY_SHADE_NOT_RUN"
                }
            }
            val screenshot = automation.takeScreenshot()
            screenshot?.let { image -> File(dir, "service-unclassified.png").outputStream().use {
                image.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, it)
            }; image.recycle() }
            records.add("SERVICE_CONTROL scenario=$scenario A=${original.id} B=${yieldedTo.get()} physical=UNOBSERVED")
            }
        } catch (error: Throwable) {
            errors += "${error.javaClass.simpleName}:${error.message}"
            visualCalibration = "INCOMPLETE_$visualCalibration"
        } finally {
            releaseEntry.countDown()
            release.countDown()
            releaseB.countDown()
            // The held reader has been released before any PNG encoding or
            // inventory write. Keep even failed precondition samples.
            runCatching {
                if (inventorySamples.isNotEmpty()) File(dir, "independent-window-inventory.txt")
                    .writeText(inventorySamples.joinToString("\n", postfix = "\n"))
                visualUnderlayFull?.let { image ->
                    File(dir, "service-underlay-before-A-full.png").outputStream().use {
                        image.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, it)
                    }
                }
                visualUnderlay?.let { image ->
                    File(dir, "service-underlay-before-A.png").outputStream().use {
                        image.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, it)
                    }
                    File(dir, "service-underlay-before-A-time.txt").writeText(
                        "before=$underlayBefore after=$underlayAfter bounds=$underlayBounds\n")
                }
            }.onFailure { errors += "underlayEvidence:${it.javaClass.simpleName}:${it.message}" }
            visualUnderlayFull?.recycle()
            visualUnderlay?.recycle()
            if (negativeScene) runCatching { shell("cmd statusbar collapse") }
            KeyguardR15AcquisitionTestHooks.afterReturnedChild = null
            KeyguardR15AcquisitionTestHooks.beforeChildCall = null
            KeyguardR15AcquisitionTestHooks.observer = null
            KeyguardR15AcquisitionTestHooks.observeIneligible = false
            KeyguardOrbSurfaceWorkerTestHooks.fixedMaterialTime = null
            KeyguardOrbSurfaceWorkerTestHooks.postedMaterialTime = null
            KeyguardOrbSurfaceWorkerTestHooks.afterRevealCross = savedRevealCross
            File(dir, "visual-edges.txt").writeText(
                (synchronized(ingressEdges) { ingressEdges.toList() } + synchronized(visualEdges) { visualEdges.toList() })
                    .joinToString("\n", postfix = "\n") + "overflow=${visualOverflow.get()}\n")
            runCatching { calibration?.close() }.onFailure { errors += "visualCleanup:${it.javaClass.simpleName}:${it.message}" }
            runCatching { instrumentation.runOnMainSync {
                FluviKeyguardCardServiceRegistry.serviceForInstrumentation()?.inspectionProbeForTest = null
            } }
            runCatching {
                if (capture) {
                    report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
                    File(dir, "capture.txt").writeText(checkNotNull(report))
                }
            }.onFailure { errors += "freeze:${it.javaClass.simpleName}:${it.message}" }
            File(dir, "sequence.txt").writeText(synchronized(records) { records.joinToString("\n", postfix = "\n") })
            runCatching {
                setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, other)
                await("service disconnected", 8_000) { !FluviKeyguardCardServiceRegistry.connected }
                restore(savedSettings); restore(savedMaterial); restore(savedMode)
                shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard")
                if (savedLock == "true" || savedLock == "false") shell("locksettings set-disabled $savedLock")
                setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, savedServices)
                setSecure(Settings.Secure.ACCESSIBILITY_ENABLED, savedEnabled)
            }.onFailure { errors += "cleanup:${it.javaClass.simpleName}:${it.message}" }
            if (errors.isNotEmpty() && !visualCalibration.startsWith("INCOMPLETE")) visualCalibration = "INCOMPLETE_$visualCalibration"
            File(dir, "result.txt").writeText("source=$source uuid=$uuid scenario=$scenario injectedFrameworkEvent=false visualCalibration=$visualCalibration errors=${errors.joinToString(" | ")}\n")
        }
        assertTrue("R22 candidate service: ${errors.joinToString(" | ")}", errors.isEmpty())
    }

    /** Independent test observer. Its facts never enter the production reader
     * or any grant; extra unresolved/foreign windows disqualify the specimen. */
    private fun independentOpeningScene(service: FluviKeyguardCardService, requireComplete: Boolean = false): String {
        val windows = runCatching { automation.windows }.getOrElse { return "INVALID windows=${it.javaClass.simpleName}" }
        val own = service.knownOwnOverlayIdentityForTest()
        var mainId: Int? = null
        var unresolved = 0
        var nonOwnDefaultWindows = 0
        var activeTree = "UNOBSERVED"
        var activeTreeComplete = false
        val rows = mutableListOf<String>()
        windows.forEach { window ->
            val root = runCatching { window.root }.getOrNull()
            try {
                val pkg = root?.packageName?.toString()
                val exactOwn = own != null && own.windowId == window.id && own.displayId == window.displayId &&
                    window.type == android.view.accessibility.AccessibilityWindowInfo.TYPE_ACCESSIBILITY_OVERLAY
                val category = when { exactOwn -> "OWN"; pkg == "com.android.systemui" -> "SYSTEMUI";
                    root == null -> "UNRESOLVED"; else -> "FOREIGN" }
                if (window.displayId == Display.DEFAULT_DISPLAY && !exactOwn) {
                    nonOwnDefaultWindows += 1
                    if (root == null || pkg != "com.android.systemui") unresolved += 1
                }
                val markers = if (root == null) 0 else listOf(
                    "com.android.systemui:id/keyguard_status_view",
                    "com.android.systemui:id/keyguard_clock_switch",
                    "com.android.systemui:id/keyguard_carrier_text",
                ).sumOf { id ->
                    val matches = runCatching { root.findAccessibilityNodeInfosByViewId(id) }.getOrDefault(emptyList())
                    val count = matches.count { it.isVisibleToUser }
                    matches.forEach { it.recycle() }
                    count
                }
                if (window.displayId == Display.DEFAULT_DISPLAY && window.isActive && pkg == "com.android.systemui" && markers > 0) {
                    mainId = window.id
                    if (requireComplete && root != null) {
                        val result = independentlyWalkActiveTree(root)
                        activeTreeComplete = result.first
                        activeTree = result.second
                    }
                }
                rows += "id=${window.id}/type=${window.type}/display=${window.displayId}/active=${window.isActive}/layer=${window.layer}/category=$category/mainMarkers=$markers"
            } finally { root?.recycle() }
        }
        val prefix = if (mainId != null && unresolved == 0 && nonOwnDefaultWindows == 1 &&
            (!requireComplete || activeTreeComplete)) "VALID" else "INVALID"
        return "$prefix activeSystemUi=$mainId unresolved=$unresolved nonOwnDefault=$nonOwnDefaultWindows " +
            "own=$own independentTree=$activeTree windows=${rows.joinToString(";")}"
    }

    /** Independent bounded walk: its result is a test precondition, never a
     * production authorization. Null, exception, depth or node limits fail it. */
    private fun independentlyWalkActiveTree(root: android.view.accessibility.AccessibilityNodeInfo): Pair<Boolean, String> {
        var visited = 0
        var nonLeaf = 0
        var firstChild = "UNOBSERVED"
        var failure: String? = null
        fun walk(node: android.view.accessibility.AccessibilityNodeInfo, depth: Int) {
            if (failure != null) return
            if (depth > 48 || visited >= 512) { failure = "LIMIT depth=$depth visited=$visited"; return }
            visited++
            try {
                if (!node.isVisibleToUser) return
                val count = node.childCount
                if (count > 0) nonLeaf++
                for (index in 0 until count) {
                    val child = try { node.getChild(index) } catch (error: Exception) {
                        if (depth == 0 && index == 0) firstChild = "EXCEPTION:${error.javaClass.simpleName}"
                        failure = "CHILD_EXCEPTION depth=$depth index=$index class=${error.javaClass.simpleName}"
                        return
                    }
                    if (depth == 0 && index == 0) firstChild = if (child == null) "NULL" else "PRESENT"
                    if (child == null) { failure = "NULL_CHILD depth=$depth index=$index"; return }
                    try { walk(child, depth + 1) } finally { child.recycle() }
                    if (failure != null) return
                }
            } catch (error: Exception) {
                failure = "NODE_EXCEPTION depth=$depth class=${error.javaClass.simpleName}"
            }
        }
        walk(root, 0)
        val complete = failure == null && firstChild == "PRESENT" && nonLeaf > 0
        return complete to "strategy=independentWindowRoot/legacyChild,visited=$visited,nonLeaf=$nonLeaf,child0=$firstChild,failure=${failure ?: "none"}"
    }

    private fun independentVisibleMarkerWindow(id: String): Int? {
        for (window in automation.windows) {
            val root = runCatching { window.root }.getOrNull() ?: continue
            try {
                if (window.displayId == Display.DEFAULT_DISPLAY && root.packageName?.toString() == "com.android.systemui") {
                    val nodes = runCatching { root.findAccessibilityNodeInfosByViewId(id) }.getOrDefault(emptyList())
                    val visible = try { nodes.any { it.isVisibleToUser } } finally { nodes.forEach { it.recycle() } }
                    if (visible) return window.id
                }
            } finally { root.recycle() }
        }
        return null
    }

    private fun independentShadeWindow(): Int? = listOf(
        "com.android.systemui:id/quick_settings_panel",
        "com.android.systemui:id/quick_qs_panel",
        "com.android.systemui:id/qs_frame",
        "com.android.systemui:id/settings_button",
        "com.android.systemui:id/notification_shade_shortcut",
        "com.android.systemui:id/split_shade_status_bar",
    ).firstNotNullOfOrNull(::independentVisibleMarkerWindow)

    /** Platform state is independent evidence; querying it never grants display authority. */
    private fun automationEvidence(dir: File, stage: String) {
        val enabled = Settings.Secure.getString(context.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        val header = "stage=$stage requestedFlags=${UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES} " +
            "handle=${System.identityHashCode(automation)} connected=${FluviKeyguardCardServiceRegistry.connected} " +
            "enabled=$enabled at=${SystemClock.uptimeMillis()}\n"
        File(dir, "automation-$stage.txt").writeText(header + shell("dumpsys accessibility"))
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
