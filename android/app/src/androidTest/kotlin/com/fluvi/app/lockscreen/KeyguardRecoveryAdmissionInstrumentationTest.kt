package com.fluvi.app.lockscreen

import android.Manifest
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.KeyguardManager
import android.app.UiAutomation
import android.content.ComponentName
import android.content.Context
import android.content.Intent
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
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.view.inspector.WindowInspector
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.fluvi.app.lockscreen.material.FluviKeyguardMaterialStore
import com.fluvi.app.lockscreen.material.KeyguardMaterialProfile
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

/** Controlled ordering on the real service. The negative which first withdraws
 * the root is explicitly injected into the classifier, while the decisive
 * exclusion is an independently visible test-APK window. Event B is a
 * labelled metadata copy through the same adapter as a framework callback. */
@RunWith(AndroidJUnit4::class)
class KeyguardRecoveryAdmissionInstrumentationTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val context get() = instrumentation.targetContext
    private val keyguard get() = context.getSystemService(KeyguardManager::class.java)
    private val power get() = context.getSystemService(PowerManager::class.java)
    private lateinit var automation: UiAutomation
    private lateinit var output: File
    private val records = StringBuilder()

    @Test fun supersededExternalEventSuppressesOnlyTheRecoveryAdd() = scenario("exclusion", true, false, resume = true)
    @Test fun freshMainSuccessorRestoresExactlyOnce() = scenario("fresh-main", false, false, resume = true)
    @Test fun postAttachOnlyExclusionNeverDefersPriorAdmission() = scenario("late-only", true, true, resume = true)
    @Test fun temporaryRealOcclusionReturnsToMain() = scenario("real-return", true, true, realReturn = true)
    @Test fun terminalWithdrawalDiscardsPendingWork() = scenario("terminal-stale", false, false, terminal = true)
    @Test fun matchedNegativeForensicStages() = scenario("matched-negative", true, false, forensic = true)
    @Test fun matchedNegativeProbeDisabledControl() = scenario("matched-negative-disabled", true, false, forensic = true, probeDisabled = true)

    private fun scenario(name: String, exclude: Boolean, lateOnly: Boolean,
        realReturn: Boolean = false, terminal: Boolean = false, forensic: Boolean = false, resume: Boolean = false,
        probeDisabled: Boolean = false) {
        assertEquals("fixture needs API35", 35, Build.VERSION.SDK_INT)
        val args = InstrumentationRegistry.getArguments()
        val expectedCandidate = args.getString("r14Expected") == "candidate"
        val source = requireNotNull(args.getString("sourceSha"))
        require(source.matches(Regex("[0-9a-f]{40}")))
        val runId = UUID.fromString(requireNotNull(args.getString("runUuid"))).toString()
        automation = instrumentation.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        automation.serviceInfo = automation.serviceInfo.apply { flags = flags or AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS }
        output = File(context.filesDir, "keyguard-service-probe/r14/$runId/$name")
        check(!output.exists() && output.mkdirs()) { "run/method reused" }
        val resolver = context.contentResolver
        val savedServices = Settings.Secure.getString(resolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        val savedEnabled = Settings.Secure.getString(resolver, Settings.Secure.ACCESSIBILITY_ENABLED)
        val savedLock = shell("locksettings get-disabled").trim()
        val savedSettings = preferences("fluvi_native_keyguard_card")
        val savedMaterial = preferences("fluvi_keyguard_header_material")
        val savedMode = preferences("fluvi_keyguard_orb_diagnostic_route")
        val component = ComponentName(context, FluviKeyguardCardService::class.java)
        fun otherServices() = savedServices.orEmpty().split(':').filter {
            it.isNotBlank() && ComponentName.unflattenFromString(it) != component
        }.joinToString(":")
        val workerHeld = CountDownLatch(1)
        val releaseWorker = CountDownLatch(1)
        val aApplied = CountDownLatch(1)
        val failure = AtomicReference<Throwable?>()
        val a = AtomicReference<KeyguardCardInspectionRequest?>()
        val b = AtomicReference<KeyguardCardInspectionRequest?>()
        val c = AtomicReference<KeyguardCardInspectionRequest?>()
        val replacement = AtomicReference<KeyguardCardInspectionRequest?>()
        val reads = java.util.concurrent.ConcurrentHashMap.newKeySet<Long>()
        val applied = java.util.concurrent.ConcurrentHashMap<Long, KeyguardCardVisibility>()
        val aStarted = java.util.concurrent.atomic.AtomicLong()
        val aAttached = java.util.concurrent.atomic.AtomicBoolean()
        val aGeneration = java.util.concurrent.atomic.AtomicLong()
        val originalGeneration = java.util.concurrent.atomic.AtomicLong()
        val systemWindowBefore = java.util.concurrent.atomic.AtomicInteger(-1)
        val frameworkEvents = java.util.concurrent.atomic.AtomicInteger()
        val frameworkCopies = java.util.concurrent.atomic.AtomicInteger()
        val withdrawalDone = java.util.concurrent.atomic.AtomicBoolean()
        val holdTerminalRead = java.util.concurrent.atomic.AtomicBoolean()
        val negativeRead = java.util.concurrent.atomic.AtomicLong()
        val negativeFinished = java.util.concurrent.atomic.AtomicLong()
        val samplerStop = java.util.concurrent.atomic.AtomicBoolean()
        val ingressByRequest = java.util.concurrent.ConcurrentHashMap<Long, KeyguardAccessibilityEventMeta>()
        val frameworkRequest = java.util.concurrent.ConcurrentHashMap<Long, Boolean>()
        data class Selection(val authority: KeyguardInspectionAuthority, val closeRequested: Long)
        data class ReadSample(val request: KeyguardCardInspectionRequest, val decision: KeyguardCardVisibility,
            val reason: KeyguardSurfaceReason, val unavailable: Boolean, val truncated: Boolean,
            val stale: Boolean, val start: Long, val end: Long)
        data class Boundary(val request: KeyguardCardInspectionRequest, val decision: KeyguardCardVisibility,
            val pending: KeyguardCardInspectionRequest?, val authority: KeyguardInspectionAuthority, val at: Long)
        val selection = AtomicReference<Selection?>()
        val boundary = AtomicReference<Boundary?>()
        val afterAState = AtomicReference<KeyguardInspectionStateForTest?>()
        val readSamples = java.util.concurrent.ConcurrentHashMap<Long, ReadSample>()
        val decided = java.util.concurrent.ConcurrentHashMap<Long, KeyguardCardVisibility>()
        val parents = java.util.concurrent.ConcurrentHashMap<Long, Long>()
        val offeredRequests = java.util.concurrent.ConcurrentHashMap<Long, KeyguardCardInspectionRequest>()
        val offerOverflow = java.util.concurrent.atomic.AtomicInteger()
        val readOverflow = java.util.concurrent.atomic.AtomicInteger()
        val genuineSystemUi = java.util.concurrent.atomic.AtomicBoolean()
        val genuineExample = AtomicReference<Pair<KeyguardAccessibilityEventMeta, KeyguardCardInspectionRequest>?>()
        val forensicAfter = java.util.concurrent.atomic.AtomicLong()
        var service: FluviKeyguardCardService? = null
        var captureStarted = false
        var controlledOccluderStarted = false
        var captureId = "UNOBSERVED"
        var primaryFailure: Throwable? = null
        var sampler: Thread? = null
        fun schedule(owner: FluviKeyguardCardService, trigger: String) {
            val method = FluviKeyguardCardService::class.java.getDeclaredMethod(
                "scheduleEvaluation", String::class.java, java.lang.Long::class.java,
                java.lang.Long::class.java, KeyguardWindowFreshness::class.java,
                KeyguardCardInspectionRequest::class.java,
            ).apply { isAccessible = true }
            method.invoke(owner, trigger, null, SystemClock.uptimeMillis(), KeyguardWindowFreshness.FRAMEWORK_EVENT, null)
        }
        val probe = object : KeyguardInspectionProbeForTest {
            override fun frameworkCopy(meta: KeyguardAccessibilityEventMeta, type: Int, window: Int,
                display: Int, changes: Int, packageName: String?, eventTime: Long) {
                if (meta.eventType != type || meta.windowId != window || meta.displayId != display ||
                    meta.windowChanges != changes || meta.packageName != packageName || meta.eventTimeUptimeMs != eventTime) {
                    failure.compareAndSet(null, IllegalStateException("framework metadata copy mismatch"))
                }
                frameworkCopies.incrementAndGet()
            }
            override fun ingressOffered(meta: KeyguardAccessibilityEventMeta, request: KeyguardCardInspectionRequest,
                previous: KeyguardCardInspectionRequest?, pending: KeyguardCardInspectionRequest?,
                startsWorker: Boolean, frameworkEvent: Boolean) {
                if (!resume || ingressByRequest.size < 1_024) {
                    ingressByRequest[request.id] = meta
                    frameworkRequest[request.id] = frameworkEvent
                } else offerOverflow.incrementAndGet()
                if (frameworkEvent && meta.packageName == "com.android.systemui" && meta.displayId == Display.DEFAULT_DISPLAY &&
                    meta.windowId >= 0 && meta.eventTimeUptimeMs != null && meta.eventTimeUptimeMs > 0 &&
                    meta.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
                    request.trigger == "window" &&
                    meta.eventTimeUptimeMs <= (request.triggerReceivedUptimeMs ?: -1L) && request.eventTimeUptimeMs == meta.eventTimeUptimeMs &&
                    KeyguardCardEventGate.decide(meta, false) == KeyguardEventAction.INSPECT) {
                    genuineSystemUi.set(true)
                    genuineExample.compareAndSet(null, meta to request)
                }
                if (!resume && !forensic) record("INGRESS_OFFER", "req=${request.id} before=${previous?.id ?: "none"} after=${pending?.id ?: "none"} started=$startsWorker framework=$frameworkEvent systemui=${meta.packageName == "com.android.systemui"} display=${meta.displayId} window=${meta.windowId}")
            }
            override fun queueOffered(request: KeyguardCardInspectionRequest, previous: KeyguardCardInspectionRequest?,
                pending: KeyguardCardInspectionRequest?, startsWorker: Boolean) {
                if (!resume) return
                if (offeredRequests.size >= 1_024) { offerOverflow.incrementAndGet(); return }
                offeredRequests[request.id] = request
                parents[request.id] = previous?.id ?: 0L
            }
            override fun ingress(meta: KeyguardAccessibilityEventMeta, receivedAt: Long, action: KeyguardEventAction, frameworkEvent: Boolean) {
                if (frameworkEvent) frameworkEvents.incrementAndGet()
                if (!resume && !forensic) record("INGRESS", "framework=$frameworkEvent type=${meta.eventType} window=${meta.windowId} display=${meta.displayId} systemui=${meta.packageName == "com.android.systemui"} event=${meta.eventTimeUptimeMs} callback=$receivedAt action=$action")
            }
            override fun snapshots(request: KeyguardCardInspectionRequest, actual: List<KeyguardWindowSnapshot>): List<KeyguardWindowSnapshot> =
                if (request.trigger == "r14-controlled-withdraw") actual + KeyguardWindowSnapshot(
                    packageName = "fixture.controlled.negative", type = 1, layer = Int.MAX_VALUE,
                    displayId = Display.DEFAULT_DISPLAY, windowId = 990035,
                ) else actual
            override fun readCompleted(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility,
                reason: KeyguardSurfaceReason, rootUnavailable: Boolean, walkTruncated: Boolean,
                abortedStale: Boolean, startedAt: Long, finishedAt: Long) {
                if (resume || forensic) {
                    if (readSamples.size < 1_024) readSamples[request.id] = ReadSample(request, decision, reason, rootUnavailable, walkTruncated, abortedStale, startedAt, finishedAt)
                    else readOverflow.incrementAndGet()
                } else record("READ", "req=${request.id} trigger=${request.trigger} decision=$decision reason=$reason rootUnavailable=$rootUnavailable truncated=$walkTruncated stale=$abortedStale start=$startedAt end=$finishedAt")
                reads.add(request.id)
                if (forensic && request.trigger == "r14-controlled-withdraw") {
                    negativeRead.set(request.id)
                    negativeFinished.set(finishedAt)
                    return
                }
                if (resume) {
                    val token = selection.get() ?: return
                    if (!KeyguardR14SelectionGate.eligible(token.authority, request, token.closeRequested, startedAt,
                            decision, reason, rootUnavailable, walkTruncated, abortedStale) || !a.compareAndSet(null, request)) return
                    aStarted.set(startedAt)
                    workerHeld.countDown()
                    if (!releaseWorker.await(20, TimeUnit.SECONDS)) failure.compareAndSet(null, IllegalStateException("eligible A barrier timed out"))
                    return
                }
                // An actual framework callback may coalesce the tagged intent
                // before its read begins. Select the first real post-withdrawal
                // read and validate its complete classification and authority.
                if ((!withdrawalDone.get() && !holdTerminalRead.get()) || !a.compareAndSet(null, request)) return
                runCatching {
                    check(decision == KeyguardCardVisibility.SHOW_FULL && reason == KeyguardSurfaceReason.MAIN_CONFIRMED &&
                        !rootUnavailable && !walkTruncated && !abortedStale) { "A incomplete/non-MAIN: $decision/$reason" }
                    aStarted.set(startedAt)
                    workerHeld.countDown()
                    check(releaseWorker.await(25, TimeUnit.SECONDS)) { "A worker barrier timed out" }
                }.onFailure { failure.compareAndSet(null, it); workerHeld.countDown() }
            }
            override fun beforeDecision(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility,
                pending: KeyguardCardInspectionRequest?, authority: KeyguardInspectionAuthority) {
                if (!resume) return
                decided[request.id] = decision
                if (request.id == a.get()?.id) boundary.compareAndSet(null, Boundary(request, decision, pending, authority, SystemClock.uptimeMillis()))
            }
            override fun afterApply(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility) {
                if (forensic) {
                    forensicAfter.set(request.id)
                    return
                }
                val owner = service ?: return
                val state = owner.inspectionStateForTest()
                if (resume) {
                    // A positive classification returned while still detached
                    // is not evidence that the candidate applied a SHOW.
                    if (!(expectedCandidate && request.id == a.get()?.id && !state.attached)) {
                        decided[request.id]?.let { applied[request.id] = it }
                    }
                    if (request.id == a.get()?.id) {
                        aAttached.set(state.attached)
                        aGeneration.set(state.authority.attachGeneration)
                        afterAState.set(state)
                        if (state.pending?.trigger == "authorityReconcile:attach") replacement.set(state.pending)
                        aApplied.countDown()
                    }
                    return
                }
                applied[request.id] = decision
                val roots = WindowInspector.getGlobalWindowViews().count {
                    (it.layoutParams as? WindowManager.LayoutParams)?.type == WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
                }
                record("APPLIED", "req=${request.id} trigger=${request.trigger} raw=$decision attached=${state.attached} roots=$roots pending=${state.pending?.id ?: "none"} pendingTrigger=${state.pending?.trigger ?: "none"} authority=${state.authority}")
                if (request.trigger == "r14-controlled-withdraw") {
                    runCatching {
                        check(decision == KeyguardCardVisibility.HIDDEN_OCCLUDED && !state.attached && roots == 0) { "controlled withdrawal did not remove the real root" }
                        check(state.wake != null && state.authority.attachGeneration == originalGeneration.get())
                        withdrawalDone.set(true)
                        schedule(owner, "r14-positive-a")
                        check(owner.inspectionStateForTest().pending?.trigger == "r14-positive-a") { "A not pending after actual withdrawal" }
                    }.onFailure { failure.compareAndSet(null, it); workerHeld.countDown() }
                }
                if (request.id == a.get()?.id) {
                    aAttached.set(state.attached)
                    aGeneration.set(state.authority.attachGeneration)
                    if (roots != if (state.attached) 1 else 0) failure.compareAndSet(null, IllegalStateException("A root count inconsistent: $roots"))
                    if (state.pending?.trigger == "authorityReconcile:attach") replacement.set(state.pending)
                    // On stock, attach-reconciliation may have replaced B. A
                    // further labelled C checks the real pending replacement,
                    // rather than pretending that B itself was read.
                    if (exclude && !lateOnly && state.attached) runCatching {
                        val previous = state.pending
                        check(previous?.trigger == "authorityReconcile:attach") { "stock add lacked observed attach reconciliation: ${previous?.trigger}" }
                        sendControlled(owner, "C", aStarted.get(), previous.id, c, systemWindowBefore.get())
                    }.onFailure { failure.compareAndSet(null, it) }
                    aApplied.countDown()
                }
            }
        }
        try {
            record("RUN", "source=$source run=$runId case=$name pid=${android.os.Process.myPid()} mode=SURFACE_LIVE")
            assertFalse("fresh service required", FluviKeyguardCardServiceRegistry.connected)
            assertFalse("disposable insecure keyguard required", keyguard.isDeviceSecure)
            check(savedLock == "true" || savedLock == "false")
            setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, otherServices())
            await("old service disconnected", 8_000) { !FluviKeyguardCardServiceRegistry.connected }
            shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard")
            await("unlocked", 5_000) { power.isInteractive && !keyguard.isKeyguardLocked }
            shell("locksettings set-disabled false")
            check(context.getSharedPreferences("fluvi_keyguard_orb_diagnostic_route", Context.MODE_PRIVATE).edit().putString("mode", "SURFACE_LIVE").commit())
            instrumentation.runOnMainSync {
                FluviKeyguardCardSettings.update(context, mapOf("requested" to true, "showFinancialDetails" to true, "presentationMode" to "orb", "animationMode" to "orbOnly"))
                val epoch = maxOf(SystemClock.elapsedRealtimeNanos(), (savedMaterial.second["publisherEpoch"] as? Long ?: -1L) + 1L)
                check(FluviKeyguardMaterialStore.publish(context, materialProfile(), epoch))
            }
            captureId = KeyguardCardDiagnostics.startCapture(context, source, "debug", "FULL")["captureId"].toString()
            captureStarted = true
            setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, listOf(otherServices(), component.flattenToString()).filter { it.isNotBlank() }.joinToString(":"))
            setSecure(Settings.Secure.ACCESSIBILITY_ENABLED, "1")
            await("service connected", 10_000) { FluviKeyguardCardServiceRegistry.connected }
            service = checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation())
            synchronizedKey(KeyEvent.KEYCODE_SLEEP)
            await("locked display off", 8_000) {
                val display = context.getSystemService(DisplayManager::class.java).getDisplay(Display.DEFAULT_DISPLAY)
                !power.isInteractive && display?.state == Display.STATE_OFF && keyguard.isKeyguardLocked
            }
            synchronizedKey(KeyEvent.KEYCODE_WAKEUP)
            await("initial real LIVE attachment", 20_000) { sample(service!!).let { it.first.attached && it.second.effective == KeyguardOrbRenderMode.SURFACE_LIVE } }
            if (forensic) {
                val owner = checkNotNull(service)
                val initial = sample(owner).first
                check(initial.attached && initial.wake != null)
                await("initial actual Surface producer output", 15_000) {
                    (mainWithinDeadline { owner.surfaceMetricsForInstrumentation()?.submissions } ?: 0L) > 0
                }
                if (!probeDisabled) {
                    KeyguardR14ForensicProbe.arm(initial.authority.attachGeneration)
                    await("prearmed holder observation", 8_000) { KeyguardR14ForensicProbe.workerStage != 0 }
                }
                sampler = Thread({
                    val start = SystemClock.uptimeMillis()
                    while (!samplerStop.get() && negativeFinished.get() == 0L && SystemClock.uptimeMillis() - start < 20_000) SystemClock.sleep(10)
                    val readAt = negativeFinished.get()
                    if (readAt > 0) for (index in 1..2) {
                        val targetAt = readAt + index * 4_000L
                        while (!samplerStop.get() && SystemClock.uptimeMillis() < targetAt) SystemClock.sleep(10)
                        if (samplerStop.get()) break
                        val req = negativeRead.get()
                        val marks = KeyguardR14ForensicProbe.snapshot()
                        val complete = forensicAfter.get() == req || marks.any { it.request == req && (it.stage == KeyguardR14ForensicProbe.MAIN_EXIT || it.stage == KeyguardR14ForensicProbe.REJECT || it.stage == KeyguardR14ForensicProbe.HIDE_RETURN) }
                        if (!complete) {
                            val begin = SystemClock.uptimeMillis()
                            val stacks = runCatching { Thread.getAllStackTraces() }
                            val rows = buildString {
                                appendLine("run=$runId pid=${android.os.Process.myPid()} request=$req target=$targetAt begin=$begin collectionDelayMs=${begin - targetAt} readEnd=$readAt")
                                appendLine("holderStage=${KeyguardR14ForensicProbe.workerStage} holderAt=${KeyguardR14ForensicProbe.workerAt} holderTid=${KeyguardR14ForensicProbe.workerThreadId} attach=${KeyguardR14ForensicProbe.workerAttachment} generation=${KeyguardR14ForensicProbe.workerGeneration} holder=${KeyguardR14ForensicProbe.workerHolder} snapshot=latestVolatile")
                                marks.forEach { appendLine(it.toString()) }
                                stacks.exceptionOrNull()?.let { appendLine("stackCollectionUnavailable=${it.javaClass.name}:${it.message}") }
                                stacks.getOrDefault(emptyMap()).entries.filter { (thread, _) -> thread.name == "main" || thread.name.contains("keyguard", true) || thread.name.contains("binder", true) || thread.name.contains("instrument", true) || thread.name.contains("render", true) || thread.name.contains("dispatcher", true) || thread.name.contains("surface", true) || thread.name.contains("fluvi", true) }
                                    .sortedBy { it.key.name }.take(48).forEach { (thread, frames) ->
                                        appendLine("thread=${thread.name} javaId=${thread.id} state=${thread.state}")
                                        frames.take(64).forEach { appendLine("  $it") }
                                    }
                                appendLine("end=${SystemClock.uptimeMillis()} clock=uptimeMs")
                            }
                            java.io.File(output, "forensic-snapshot-$index.txt").writeText(rows)
                        }
                    }
                }, "r14-independent-stack-sampler").apply { isDaemon = true; start() }
                mainWithinDeadline { owner.inspectionProbeForTest = probe; schedule(owner, "r14-controlled-withdraw") }
                await("controlled negative read", 20_000) { negativeFinished.get() > 0 }
                val negative = checkNotNull(readSamples[negativeRead.get()])
                record("FORENSIC_READ", "req=${negative.request.id} decision=${negative.decision} reason=${negative.reason} start=${negative.start} end=${negative.end} unavailable=${negative.unavailable} truncated=${negative.truncated} stale=${negative.stale}")
                await("negative terminal application boundary", 20_000) {
                    val req = negativeRead.get()
                    (probeDisabled && forensicAfter.get() == req) || KeyguardR14ForensicProbe.snapshot().any { it.request == req &&
                        (it.stage == KeyguardR14ForensicProbe.MAIN_EXIT || it.stage == KeyguardR14ForensicProbe.REJECT || it.stage == KeyguardR14ForensicProbe.HIDE_RETURN) }
                }
                record("FORENSIC_COMPLETED", "req=${negativeRead.get()} readEnd=${negativeFinished.get()} afterApplyRaw=${forensicAfter.get()} elapsed=${SystemClock.uptimeMillis() - negativeFinished.get()} probeEnabled=${!probeDisabled} dispositionRequiresMarks=${!probeDisabled} physical=UNOBSERVED")
                return
            }
            if (resume) {
                val owner = checkNotNull(service)
                val initial = sample(owner).first
                check(initial.attached && initial.wake != null && initial.authority.attachGeneration > 0)
                await("initial actual Surface producer output", 15_000) {
                    (mainWithinDeadline { owner.surfaceMetricsForInstrumentation()?.submissions } ?: 0L) > 0
                }
                val initialMetrics = checkNotNull(mainWithinDeadline { owner.surfaceMetricsForInstrumentation() })
                record("G1_LIVE", "session=${initial.authority.serviceSession} wake=${initial.wake} attach=${initial.authority.attachGeneration} firstPost=${initialMetrics.firstPostUptimeMs ?: "UNOBSERVED"} submissions=${initialMetrics.submissions}")
                systemWindowBefore.set(systemUiWindowId())
                // The candidate fixture needs service/window operation marks;
                // the stock-only holder sampler does not alter this renderer.
                KeyguardR14ForensicProbe.arm(initial.authority.attachGeneration)
                mainWithinDeadline { owner.inspectionProbeForTest = probe }
                controlledOccluderStarted = true
                establishOccluder("g1-cover")
                await("actual recoverable G1 root withdrawal", 20_000) { !sample(owner).first.attached }
                val withdrawn = sample(owner).first
                check(withdrawn.wake == initial.wake && withdrawn.authority.attachGeneration == initial.authority.attachGeneration)
                val withdrawalMarks = KeyguardR14ForensicProbe.snapshot()
                val actualHide = withdrawalMarks.lastOrNull { it.stage == KeyguardR14ForensicProbe.HIDE_ENTER && it.request > 0 }
                val actualRemoval = withdrawalMarks.firstOrNull { actualHide != null && it.stage == KeyguardR14ForensicProbe.REMOVE_RETURN && it.attachment == initial.authority.attachGeneration && it.sequence > actualHide.sequence && it.extra == 1 }
                check(actualHide != null && actualRemoval != null) {
                    "actual G1 inspection withdrawal/remove not observed"
                }
                File(output, "g1-withdrawal-marks.txt").writeText(withdrawalMarks.joinToString("\n", postfix = "\n"))
                await("G1 withdrawal decision returned", 5_000) { applied.containsKey(actualHide.request) }
                val g1Read = checkNotNull(readSamples[actualHide.request]) { "actual G1 hide read not retained" }
                record("G1_WITHDRAWN", "request=${actualHide.request} decision=${applied[actualHide.request] ?: "UNOBSERVED"} reason=${g1Read.reason} remove=${actualRemoval.uptimeMs} session=${withdrawn.authority.serviceSession} wake=${withdrawn.wake} attach=${withdrawn.authority.attachGeneration} authority=${withdrawn.authority}")
                val closeAt = SystemClock.uptimeMillis()
                selection.set(Selection(withdrawn.authority, closeAt))
                record("RETURN_ARMED", "closeRequested=$closeAt authority=${withdrawn.authority}")
                synchronizedKey(KeyEvent.KEYCODE_BACK)
                assertTrue("eligible complete current A was not observed", workerHeld.await(20, TimeUnit.SECONDS))
                failure.get()?.let { throw AssertionError("INVALID eligible A barrier", it) }
                await("first foreign window removed", 8_000) { testOccluderWindowId() == null }
                controlledOccluderStarted = false
                val held = checkNotNull(a.get())
                val heldState = sample(owner).first
                check(!heldState.attached && withdrawn.authority == heldState.authority && heldState.authority.matches(held)) {
                    "eligible A lost detached current authority"
                }
                record("A_HELD", "req=${held.id} start=${aStarted.get()} decision=SHOW_FULL reason=MAIN_CONFIRMED session=${heldState.authority.serviceSession} visibility=${heldState.authority.visibilityEpoch} wake=${heldState.authority.wakeGeneration} interaction=${heldState.authority.interactionEpoch} attach=${heldState.authority.attachGeneration}")
                if (exclude && !lateOnly) {
                    controlledOccluderStarted = true
                    establishOccluder("before-a")
                }
                val preDecisionOccluder = if (exclude && !lateOnly) checkNotNull(testOccluderIdentity()) else null
                if (!lateOnly) {
                    check(SystemClock.uptimeMillis() > aStarted.get())
                    mainWithinDeadline { sendControlled(owner, "B", aStarted.get(), null, b, systemWindowBefore.get()) }
                    val sent = checkNotNull(b.get())
                    record("CONTROLLED_B", "req=${sent.id} origin=controlled_framework_metadata window=${systemWindowBefore.get()} event=${sent.eventTimeUptimeMs} callback=${sent.triggerReceivedUptimeMs}")
                }
                check(genuineSystemUi.get()) { "genuine framework SystemUI ingress/offer equivalence not observed" }
                val (frameworkMeta, frameworkReq) = checkNotNull(genuineExample.get())
                record("FRAMEWORK_EQUIVALENCE", "req=${frameworkReq.id} framework=true type=${frameworkMeta.eventType} window=${frameworkMeta.windowId} display=${frameworkMeta.displayId} package=systemui event=${frameworkMeta.eventTimeUptimeMs} callback=${frameworkReq.triggerReceivedUptimeMs} trigger=${frameworkReq.trigger}")
                check(offerOverflow.get() == 0 && readOverflow.get() == 0) { "queue/read observation overflow" }
                releaseWorker.countDown()
                assertTrue("A did not reach the normal Main path", aApplied.await(20, TimeUnit.SECONDS))
                failure.get()?.let { throw AssertionError("A handoff fixture failed", it) }
                val snapshot = checkNotNull(boundary.get()) { "A was rejected before actual decision; raw classification is not admission" }
                check(snapshot.decision == KeyguardCardVisibility.SHOW_FULL && snapshot.authority.matches(held)) { "A lost current positive authority" }
                val actualA = checkNotNull(afterAState.get())
                if (preDecisionOccluder != null) {
                    check(preDecisionOccluder.second == Display.DEFAULT_DISPLAY)
                    val shotBegin = SystemClock.uptimeMillis()
                    val shot = checkNotNull(automation.takeScreenshot())
                    val shotEnd = SystemClock.uptimeMillis()
                    try {
                        check(greenPixels(shot) >= 900 && keyguard.isKeyguardLocked)
                        check(testOccluderIdentity() == preDecisionOccluder) { "excluding window changed across A" }
                        File(output, "after-a-occluder.png").outputStream().use { shot.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, it) }
                    } finally { shot.recycle() }
                    record("POST_A_WITNESS", "window=${preDecisionOccluder.first} display=${preDecisionOccluder.second} start=$shotBegin end=$shotEnd screenshot=after-a-occluder.png physicalOrb=UNOBSERVED")
                }
                fun qualifies(request: KeyguardCardInspectionRequest?): Boolean {
                    if (request == null) return false
                    val meta = ingressByRequest[request.id] ?: return false
                    val event = request.eventTimeUptimeMs ?: return false
                    val callback = request.triggerReceivedUptimeMs ?: return false
                    return request.id != held.id && snapshot.authority.matches(request) && request.trigger == "window" &&
                        meta.packageName == "com.android.systemui" && meta.displayId == Display.DEFAULT_DISPLAY && meta.windowId >= 0 &&
                        (meta.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED || meta.eventType == AccessibilityEvent.TYPE_WINDOWS_CHANGED) &&
                        event > 0 && event <= callback && event >= aStarted.get() && callback > aStarted.get() && callback <= snapshot.at
                }
                val pending = snapshot.pending
                if (lateOnly) {
                    if (pending != null && pending.trigger == "window") check(ingressByRequest.containsKey(pending.id)) { "late-only pending origin unknown" }
                    check(!qualifies(pending)) { "late-only contaminated by qualifying pre-A event" }
                } else check(qualifies(pending)) { "qualifying B not physically pending at A decision" }
                if (!expectedCandidate || lateOnly) check(actualA.attached && actualA.authority.attachGeneration == initial.authority.attachGeneration + 1) {
                    "stock/late A did not perform a real G2 add"
                } else check(!actualA.attached) { "candidate did not defer A" }
                record("A_DECISION", "a=${held.id} decision=${snapshot.decision} pending=${pending?.id ?: "none"} pendingOrigin=${pending?.let { if (frameworkRequest[it.id] == true) "framework" else "controlled" } ?: "none"} event=${pending?.eventTimeUptimeMs ?: "none"} callback=${pending?.triggerReceivedUptimeMs ?: "none"} at=${snapshot.at} session=${snapshot.authority.serviceSession} visibility=${snapshot.authority.visibilityEpoch} wake=${snapshot.authority.wakeGeneration} interaction=${snapshot.authority.interactionEpoch} authorityAttach=${snapshot.authority.attachGeneration} actualAttached=${actualA.attached} attach=${actualA.authority.attachGeneration} replacement=${replacement.get()?.id ?: "none"}")
                if (lateOnly) {
                    controlledOccluderStarted = true
                    val lateCoverAt = SystemClock.uptimeMillis()
                    establishOccluder("after-a")
                    var lateRequest = 0L
                    await("late actual exclusion read and withdrawal", 20_000) {
                        lateRequest = applied.entries.sortedBy { it.key }.firstOrNull { (id, value) ->
                            id != held.id && (readSamples[id]?.start ?: Long.MIN_VALUE) >= lateCoverAt &&
                                (value == KeyguardCardVisibility.HIDDEN_OCCLUDED || value == KeyguardCardVisibility.HIDDEN_UNKNOWN)
                        }?.key ?: 0L
                        lateRequest > 0 && !sample(owner).first.attached
                    }
                    val lateRead = checkNotNull(readSamples[lateRequest])
                    record("LATE_WITHDRAWN", "a=${held.id} request=$lateRequest decision=${applied[lateRequest]} reason=${lateRead.reason} start=${lateRead.start} lateCover=actual_foreign_window physical=UNOBSERVED")
                    return
                }
                fun descendsFrom(requestId: Long, ancestor: Long): Boolean {
                    var cursor = requestId
                    repeat(1_024) {
                        if (cursor == ancestor) return true
                        cursor = parents[cursor] ?: return false
                        if (cursor == 0L) return false
                    }
                    return false
                }
                val ancestor = checkNotNull(pending).id
                var successor = 0L
                await("actual coalesced successor read and applied", 20_000) {
                    successor = applied.entries.sortedBy { it.key }.firstOrNull { (id, value) ->
                        id != held.id && readSamples.containsKey(id) && descendsFrom(id, ancestor) &&
                            if (exclude) value == KeyguardCardVisibility.HIDDEN_OCCLUDED && readSamples[id]?.reason == KeyguardSurfaceReason.FOREIGN_ABOVE
                            else value == KeyguardCardVisibility.SHOW_FULL && readSamples[id]?.reason == KeyguardSurfaceReason.MAIN_CONFIRMED
                    }?.key ?: 0L
                    successor > 0 && (if (exclude) !sample(owner).first.attached else sample(owner).first.attached)
                }
                val successorRead = checkNotNull(readSamples[successor])
                val final = sample(owner).first
                check(final.wake == initial.wake)
                if (exclude && !expectedCandidate) {
                    val successorMarks = KeyguardR14ForensicProbe.snapshot()
                    val hide = successorMarks.lastOrNull { it.stage == KeyguardR14ForensicProbe.HIDE_ENTER && it.request == successor }
                    val removal = successorMarks.firstOrNull { hide != null && it.stage == KeyguardR14ForensicProbe.REMOVE_RETURN &&
                        it.attachment == initial.authority.attachGeneration + 1 && it.sequence > hide.sequence && it.extra == 1 }
                    check(hide != null && removal != null) { "successor did not remove the actual G2 root" }
                    File(output, "successor-withdrawal-marks.txt").writeText(successorMarks.joinToString("\n", postfix = "\n"))
                }
                if (exclude) {
                    if (expectedCandidate) check(final.authority.attachGeneration == initial.authority.attachGeneration) {
                        "candidate exclusion created a new attachment"
                    }
                    val identity = checkNotNull(preDecisionOccluder)
                    check(testOccluderIdentity() == identity && keyguard.isKeyguardLocked) { "exclusion changed before successor outcome" }
                    val begin = SystemClock.uptimeMillis()
                    val shot = checkNotNull(automation.takeScreenshot())
                    val end = SystemClock.uptimeMillis()
                    try {
                        check(greenPixels(shot) >= 900)
                        File(output, "after-successor-occluder.png").outputStream().use { shot.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, it) }
                    } finally { shot.recycle() }
                    record("POST_SUCCESSOR_WITNESS", "window=${identity.first} display=${identity.second} start=$begin end=$end screenshot=after-successor-occluder.png successor=$successor locked=${keyguard.isKeyguardLocked}")
                }
                if (!exclude) check(final.authority.attachGeneration == initial.authority.attachGeneration + 1 && countOverlayRoots() == 1)
                record("RESULT", "a=${held.id} b=$ancestor r=${replacement.get()?.id ?: "none"} successor=$successor successorTrigger=${successorRead.request.trigger} successorDecision=${applied[successor]} successorReason=${successorRead.reason} lineage=true aAttached=${actualA.attached} aGeneration=${actualA.authority.attachGeneration} finalAttached=${final.attached} finalGeneration=${final.authority.attachGeneration} physical=UNOBSERVED")
                if (exclude && !expectedCandidate) assertFalse("R14 candidate assertion: pending B must suppress the excess A add", actualA.attached)
                return
            }
            if (realReturn) {
                val initial = sample(checkNotNull(service)).first
                check(initial.attached && initial.wake != null)
                await("initial actual Surface producer output", 15_000) {
                    var count = 0L
                    instrumentation.runOnMainSync { count = checkNotNull(service).surfaceMetricsForInstrumentation()?.submissions ?: 0L }
                    count > 0
                }
                instrumentation.runOnMainSync { checkNotNull(service).inspectionProbeForTest = probe }
                controlledOccluderStarted = true
                establishOccluder("independent")
                var actualExclusion = 0L
                await("real framework exclusion and root withdrawal", 12_000) {
                    actualExclusion = applied.entries.firstOrNull { (id, value) ->
                        frameworkRequest[id] == true && value == KeyguardCardVisibility.HIDDEN_OCCLUDED
                    }?.key ?: 0L
                    actualExclusion > 0 && !sample(checkNotNull(service)).first.attached
                }
                val beforeReturn = sample(checkNotNull(service)).first
                check(beforeReturn.wake == initial.wake) { "actual occlusion unexpectedly ended the wake" }
                synchronizedKey(KeyEvent.KEYCODE_BACK)
                await("foreign occluder removed", 5_000) { testOccluderWindowId() == null }
                controlledOccluderStarted = false
                var actualReturn = 0L
                await("fresh real framework MAIN return", 20_000) {
                    actualReturn = applied.entries.firstOrNull { (id, value) ->
                        id > actualExclusion && frameworkRequest[id] == true && value == KeyguardCardVisibility.SHOW_FULL
                    }?.key ?: 0L
                    actualReturn > 0 && sample(checkNotNull(service)).first.attached
                }
                val afterReturn = sample(checkNotNull(service)).first
                check(afterReturn.wake == initial.wake)
                check(afterReturn.authority.attachGeneration == initial.authority.attachGeneration + 1)
                check(countOverlayRoots() == 1)
                val returned = checkNotNull(automation.takeScreenshot())
                try {
                    check(greenPixels(returned) < 16) { "foreign occluder still appears in returned screenshot" }
                    File(output, "after-real-return.png").outputStream().use {
                        returned.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, it)
                    }
                } finally { returned.recycle() }
                record("REAL_RETURN", "exclusionReq=$actualExclusion returnReq=$actualReturn origin=framework sameWake=${afterReturn.wake} attach=${afterReturn.authority.attachGeneration} screenshot=after-real-return.png visualOrb=UNOBSERVED")
                return
            }
            if (terminal) {
                val owner = checkNotNull(service)
                val initial = sample(owner).first
                check(initial.attached && initial.wake != null)
                systemWindowBefore.set(systemUiWindowId())
                instrumentation.runOnMainSync {
                    owner.inspectionProbeForTest = probe
                    holdTerminalRead.set(true)
                    schedule(owner, "r14-terminal-held-a")
                }
                assertTrue("terminal A acquisition barrier not reached", workerHeld.await(20, TimeUnit.SECONDS))
                failure.get()?.let { throw AssertionError("INVALID terminal A fixture", it) }
                val aRequest = checkNotNull(a.get())
                val pendingBefore = AtomicReference<KeyguardCardInspectionRequest?>()
                instrumentation.runOnMainSync {
                    val before = owner.inspectionStateForTest()
                    check(before.attached && before.authority.matches(aRequest)) { "terminal A lost its live authority" }
                    sendControlled(owner, "B", aStarted.get(), null, b, systemWindowBefore.get())
                    pendingBefore.set(owner.inspectionStateForTest().pending)
                    check(pendingBefore.get()?.id == b.get()?.id) { "terminal B is not physically pending" }
                    record("TERMINAL_ARMED", "a=${aRequest.id} b=${b.get()?.id} wake=${before.wake} authority=${before.authority}")
                }
                shell("wm dismiss-keyguard")
                await("actual unlocked and detached terminal state", 8_000) {
                    !keyguard.isKeyguardLocked && !sample(owner).first.attached
                }
                val terminalState = sample(owner).first
                check(!terminalState.authority.matches(aRequest)) { "terminal state did not revoke A" }
                releaseWorker.countDown()
                assertTrue("stale A did not reach the normal Main gate", aApplied.await(15, TimeUnit.SECONDS))
                failure.get()?.let { throw AssertionError("terminal fixture failure", it) }
                val afterStale = sample(owner).first
                check(!afterStale.attached && countOverlayRoots() == 0 && !afterStale.authority.matches(aRequest))
                check(afterStale.pending?.id != pendingBefore.get()?.id) { "terminal cleanup kept the old pending B" }
                record("TERMINAL_STALE", "a=${aRequest.id} b=${pendingBefore.get()?.id} locked=${keyguard.isKeyguardLocked} roots=0 oldAuthority=false wake=${afterStale.wake ?: "none"} physicalRemoval=UNOBSERVED")
                return
            }
            instrumentation.runOnMainSync {
                val owner = checkNotNull(service)
                val state = owner.inspectionStateForTest()
                check(state.attached && state.wake != null)
                originalGeneration.set(state.authority.attachGeneration)
                owner.inspectionProbeForTest = probe
                schedule(owner, "r14-controlled-withdraw")
            }
            assertTrue("A acquisition barrier not reached", workerHeld.await(20, TimeUnit.SECONDS))
            failure.get()?.let { throw AssertionError("INVALID fixture before A handoff", it) }
            val aRequest = checkNotNull(a.get())
            instrumentation.runOnMainSync {
                val state = checkNotNull(service).inspectionStateForTest()
                check(!state.attached && state.authority.matches(aRequest)) { "A lacks current detached authority" }
                check(WindowInspector.getGlobalWindowViews().none { (it.layoutParams as? WindowManager.LayoutParams)?.type == WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY }) { "A has an actual attached accessibility root" }
                record("A_HELD", "req=${aRequest.id} start=${aStarted.get()} pending=${state.pending?.id ?: "none"} authority=${state.authority}")
                if (lateOnly && state.pending != null) {
                    // The old Fluvi window can emit a delayed framework
                    // callback. Its exact queue-offer identity, not a nearest
                    // timestamp, proves it is not a qualifying SystemUI B.
                    val origin = checkNotNull(ingressByRequest[state.pending.id]) { "late-only pending origin unavailable" }
                    check(origin.packageName != "com.android.systemui" || origin.displayId != Display.DEFAULT_DISPLAY) {
                        "late-only control already has a qualifying external SystemUI event"
                    }
                    record("LATE_PENDING_CONTROL", "req=${state.pending.id} origin=nonSystemUI_or_nonPrimary")
                }
            }
            systemWindowBefore.set(systemUiWindowId())
            if (exclude && !lateOnly) {
                controlledOccluderStarted = true
                establishOccluder("before-a")
            }
            if (!lateOnly) instrumentation.runOnMainSync {
                sendControlled(checkNotNull(service), "B", aStarted.get(), null, b, systemWindowBefore.get())
            }
            check(frameworkEvents.get() > 0) { "no framework ingress mapping observed" }
            check(frameworkCopies.get() > 0) { "no framework metadata copy checked" }
            releaseWorker.countDown()
            assertTrue("A Main apply not reached", aApplied.await(15, TimeUnit.SECONDS))
            failure.get()?.let { throw AssertionError("INVALID fixture at A apply", it) }
            if (lateOnly) {
                check(aAttached.get()) { "late-only A did not attach" }
                controlledOccluderStarted = true
                establishOccluder("after-a")
                instrumentation.runOnMainSync {
                    sendControlled(checkNotNull(service), "C", aStarted.get(), null, c, systemWindowBefore.get())
                }
            }
            val actualSuccessor = if (lateOnly || (exclude && aAttached.get())) c.get()
                else if (aAttached.get()) replacement.get() else b.get()
            val successor = checkNotNull(actualSuccessor) { "actual successor identity missing" }
            await("the identified successor's actual application", 20_000) { applied.containsKey(successor.id) }
            failure.get()?.let { throw AssertionError("INVALID fixture after successor", it) }
            if (exclude) await("actual later withdrawal", 10_000) { !sample(checkNotNull(service)).first.attached }
            else await("fresh MAIN restores once", 10_000) { sample(checkNotNull(service)).first.attached }
            val final = sample(checkNotNull(service))
            val roots = countOverlayRoots()
            check(reads.contains(successor.id)) { "actual successor ${successor.id} was not physically read" }
            val successorDecision = checkNotNull(applied[successor.id]) { "actual successor was not applied" }
            if (exclude) check(successorDecision == KeyguardCardVisibility.HIDDEN_OCCLUDED) { "independent foreign window was not the applied exclusion: $successorDecision" }
            else check(successorDecision == KeyguardCardVisibility.SHOW_FULL) { "MAIN successor not applied: $successorDecision" }
            record("RESULT", "a=${aRequest.id} b=${b.get()?.id ?: "none"} r=${replacement.get()?.id ?: "none"} c=${c.get()?.id ?: "none"} read=${successor.id} readDecision=$successorDecision initialGeneration=${originalGeneration.get()} aAttached=${aAttached.get()} aGeneration=${aGeneration.get()} finalGeneration=${final.first.authority.attachGeneration} finalAttached=${final.first.attached} roots=$roots exclusionWitness=$exclude physicalPresentation=UNOBSERVED")
            if (exclude && !lateOnly) {
                assertFalse("R14 candidate assertion: pending B must suppress the excess A add", aAttached.get())
                assertEquals("withheld episode creates no new attachment", originalGeneration.get(), aGeneration.get())
                assertEquals("no residual accessibility root", 0, roots)
            } else if (!exclude) {
                assertEquals("one fresh return only", originalGeneration.get() + 1, final.first.authority.attachGeneration)
                assertEquals(1, roots)
            } else assertEquals("late-only A attaches once", originalGeneration.get() + 1, aGeneration.get())
        } catch (error: Throwable) {
            primaryFailure = error
            record("FAILURE", "type=${error.javaClass.simpleName} message=${error.message?.replace(' ', '_') ?: "none"}")
            throw error
        } finally {
            releaseWorker.countDown()
            service?.inspectionProbeForTest = null
            samplerStop.set(true)
            val cleanup = KeyguardR14FixtureCleanup(primaryFailure) { label, error ->
                if (error == null) record("CLEANUP_OK", label)
                else record("CLEANUP_FAILURE", "$label:${error.javaClass.simpleName}:${error.message}")
            }
            fun cleanupStep(label: String, action: () -> Unit) = cleanup.attempt(label, action)
            cleanupStep("sampler_join") { sampler?.join(1_000) }
            if (captureStarted) cleanupStep("freeze") {
                File(output, "capture.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"].toString())
            }
            if (controlledOccluderStarted) cleanupStep("occluder") {
                synchronizedKey(KeyEvent.KEYCODE_BACK)
                await("controlled occluder removed", 5_000) { testOccluderWindowId() == null }
            }
            cleanupStep("disconnect_request") { setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, otherServices()) }
            cleanupStep("disconnect_wait") { await("service disconnect", 8_000) { !FluviKeyguardCardServiceRegistry.connected } }
            cleanupStep("settings") { restore(savedSettings) }
            cleanupStep("material") { restore(savedMaterial) }
            cleanupStep("route") { restore(savedMode) }
            cleanupStep("unlock") { shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard") }
            cleanupStep("lock") { if (savedLock == "true" || savedLock == "false") shell("locksettings set-disabled $savedLock") }
            cleanupStep("services") { setSecure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, savedServices) }
            cleanupStep("enabled") { setSecure(Settings.Secure.ACCESSIBILITY_ENABLED, savedEnabled) }
            cleanupStep("verify_secure_settings") {
                check(Settings.Secure.getString(resolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES) == savedServices)
                check(Settings.Secure.getString(resolver, Settings.Secure.ACCESSIBILITY_ENABLED) == savedEnabled)
            }
            cleanupStep("verify_preferences") {
                check(HashMap(savedSettings.first.all) == savedSettings.second)
                check(HashMap(savedMaterial.first.all) == savedMaterial.second)
                check(HashMap(savedMode.first.all) == savedMode.second)
            }
            cleanupStep("verify_lock") {
                if (savedLock == "true" || savedLock == "false") check(shell("locksettings get-disabled").trim() == savedLock)
            }
            if (resume) cleanupStep("resume_evidence") {
                File(output, "queue-and-reads.txt").writeText(buildString {
                    appendLine("run=$runId pid=${android.os.Process.myPid()} offerOverflow=${offerOverflow.get()} readOverflow=${readOverflow.get()}")
                    offeredRequests.values.sortedBy { it.id }.forEach { request ->
                        val meta = ingressByRequest[request.id]
                        appendLine("offer=${request.id} parent=${parents[request.id] ?: "UNOBSERVED"} trigger=${request.trigger} session=${request.session} visibility=${request.visibilityEpoch} wake=${request.wakeGeneration} interaction=${request.interactionEpoch} attach=${request.attachGeneration} framework=${frameworkRequest[request.id] ?: "UNOBSERVED"} systemui=${meta?.packageName == "com.android.systemui"} type=${meta?.eventType ?: "UNOBSERVED"} window=${meta?.windowId ?: "UNOBSERVED"} display=${meta?.displayId ?: "UNOBSERVED"} event=${request.eventTimeUptimeMs ?: "UNOBSERVED"} callback=${request.triggerReceivedUptimeMs ?: "UNOBSERVED"}")
                    }
                    readSamples.values.sortedBy { it.request.id }.forEach { sample ->
                        appendLine("read=${sample.request.id} decision=${sample.decision} reason=${sample.reason} unavailable=${sample.unavailable} truncated=${sample.truncated} stale=${sample.stale} start=${sample.start} end=${sample.end} applied=${applied[sample.request.id] ?: "UNOBSERVED"}")
                    }
                })
            }
            if (forensic || resume) {
                cleanupStep("forensic_final") {
                    File(output, "forensic-final-marks.txt").writeText(KeyguardR14ForensicProbe.snapshot().joinToString("\n", postfix = "\n"))
                }
                KeyguardR14ForensicProbe.disarm()
            }
            cleanupStep("fixture") { File(output, "fixture.txt").writeText(records.toString()) }
            cleanup.finish()
        }
    }

    /** Capture the actual pending slot under Main. The SystemUI identity is
     * controlled metadata, explicitly distinct from observed framework rows. */
    private fun sendControlled(owner: FluviKeyguardCardService, role: String, aStart: Long,
        expectedPrevious: Long?, target: AtomicReference<KeyguardCardInspectionRequest?>, systemWindowId: Int) {
        check(SystemClock.uptimeMillis() > aStart) { "controlled event is not later than A read start" }
        val before = owner.inspectionStateForTest()
        if (expectedPrevious != null) check(before.pending?.id == expectedPrevious)
        val window = systemWindowId
        check(window >= 0) { "the prior real SystemUI window identity was not captured" }
        val eventAt = SystemClock.uptimeMillis()
        owner.acceptAccessibilityMetadataForTest(KeyguardAccessibilityEventMeta(
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED, window, Display.DEFAULT_DISPLAY, 0,
            "com.android.systemui", eventAt,
        ))
        val after = owner.inspectionStateForTest()
        val next = checkNotNull(after.pending) { "$role not physically pending" }
        check(next.trigger == "window" && next.eventTimeUptimeMs == eventAt && after.authority.matches(next))
        target.set(next)
    }

    private fun establishOccluder(label: String) {
        val reference = android.graphics.Bitmap.createBitmap(32, 32, android.graphics.Bitmap.Config.ARGB_8888)
        try {
            reference.eraseColor(android.graphics.Color.rgb(20, 180, 74))
            File(output, "$label-green-reference.png").outputStream().use {
                reference.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, it)
            }
        } finally { reference.recycle() }
        val before = checkNotNull(automation.takeScreenshot())
        try {
            check(greenPixels(before) < 16) { "baseline region already matches controlled green" }
            File(output, "$label-before.png").outputStream().use { before.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, it) }
        } finally { before.recycle() }
        val started = SystemClock.uptimeMillis()
        instrumentation.context.startActivity(Intent().setClassName("com.fluvi.app.test",
            "com.fluvi.app.lockscreen.KeyguardR14ControlledOccluderActivity").addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        await("actual foreign test window", 8_000) { testOccluderWindowId() != null }
        var visible = false
        await("actual controlled surface pixels", 8_000) {
            val shot = automation.takeScreenshot() ?: return@await false
            try { visible = greenPixels(shot) >= 900; visible } finally { shot.recycle() }
        }
        val screenshotStart = SystemClock.uptimeMillis()
        val bitmap = checkNotNull(automation.takeScreenshot())
        val screenshotEnd = SystemClock.uptimeMillis()
        try {
            check(greenPixels(bitmap) >= 900)
            File(output, "$label-occluder.png").outputStream().use { bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, it) }
        } finally { bitmap.recycle() }
        val identity = checkNotNull(testOccluderIdentity())
        check(visible && keyguard.isKeyguardLocked && identity.second == Display.DEFAULT_DISPLAY)
        record("INDEPENDENT_EXCLUSION", "kind=actual_foreign_test_window visual=true started=$started screenshotStart=$screenshotStart screenshotEnd=$screenshotEnd screenshot=$label-occluder.png before=$label-before.png reference=$label-green-reference.png roi=center32 window=${identity.first} display=${identity.second} locked=${keyguard.isKeyguardLocked}")
    }
    private fun greenPixels(bitmap: android.graphics.Bitmap): Int {
        val cx = bitmap.width / 2
        val cy = bitmap.height / 2
        var count = 0
        for (y in cy - 16 until cy + 16) for (x in cx - 16 until cx + 16) {
            val pixel = bitmap.getPixel(x, y)
            val r = android.graphics.Color.red(pixel)
            val g = android.graphics.Color.green(pixel)
            val b = android.graphics.Color.blue(pixel)
            if (g > 120 && g > 2 * r && 2 * g > 3 * b) count++
        }
        return count
    }
    private fun testOccluderIdentity(): Pair<Int, Int>? = automation.windows.firstOrNull { window ->
        val root: AccessibilityNodeInfo = window.root ?: return@firstOrNull false
        try { root.packageName?.toString() == "com.fluvi.app.test" } finally { root.recycle() }
    }?.let { it.id to it.displayId }
    private fun testOccluderWindowId(): Int? = testOccluderIdentity()?.first
    private fun systemUiWindowId(): Int = automation.windows.firstOrNull { window ->
        val root = window.root ?: return@firstOrNull false
        try { root.packageName?.toString() == "com.android.systemui" } finally { root.recycle() }
    }?.id ?: error("actual SystemUI window not observed")
    private fun sample(owner: FluviKeyguardCardService): Pair<KeyguardInspectionStateForTest, KeyguardOrbRenderModeStatus> {
        return mainWithinDeadline { owner.inspectionStateForTest() to owner.renderModeStatus() }
    }
    private fun countOverlayRoots(): Int {
        return mainWithinDeadline { WindowInspector.getGlobalWindowViews().count { (it.layoutParams as? WindowManager.LayoutParams)?.type == WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY } }
    }
    private fun <T> mainWithinDeadline(action: () -> T): T {
        val result = AtomicReference<Result<T>>()
        val done = CountDownLatch(1)
        check(android.os.Handler(android.os.Looper.getMainLooper()).post {
            result.set(runCatching(action)); done.countDown()
        })
        check(done.await(4, TimeUnit.SECONDS)) { "Main observation timed out" }
        return checkNotNull(result.get()).getOrThrow()
    }
    private fun record(stage: String, detail: String) = synchronized(records) { records.appendLine("R14 stage=$stage up=${SystemClock.uptimeMillis()} $detail") }
    private fun shell(command: String): String = ParcelFileDescriptor.AutoCloseInputStream(automation.executeShellCommand(command)).bufferedReader().use { it.readText() }
    private fun synchronizedKey(code: Int) {
        val down = SystemClock.uptimeMillis()
        for (action in intArrayOf(KeyEvent.ACTION_DOWN, KeyEvent.ACTION_UP)) {
            check(automation.injectInputEvent(KeyEvent(down, SystemClock.uptimeMillis(), action, code, 0, 0, -1, 0, 0, InputDevice.SOURCE_KEYBOARD), true))
        }
    }
    private fun setSecure(key: String, value: String?) {
        automation.adoptShellPermissionIdentity(Manifest.permission.WRITE_SECURE_SETTINGS)
        try { check(Settings.Secure.putString(context.contentResolver, key, value)) } finally { automation.dropShellPermissionIdentity() }
    }
    private fun await(label: String, timeout: Long, condition: () -> Boolean) {
        val end = SystemClock.uptimeMillis() + timeout
        while (SystemClock.uptimeMillis() < end) { if (condition()) return; SystemClock.sleep(50) }
        error("$label timed out")
    }
    private fun preferences(name: String): Pair<SharedPreferences, Map<String, *>> = context.getSharedPreferences(name, Context.MODE_PRIVATE).let { it to HashMap(it.all) }
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
        "publisherSession" to "r14-recovery", "publisherRevision" to 1L, "sceneIdentity" to "fixture|balance|month",
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
