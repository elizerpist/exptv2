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
import com.fluvi.app.lockscreen.material.FluviKeyguardMaterialStore
import com.fluvi.app.lockscreen.material.KeyguardOrbSurfaceTarget
import com.fluvi.app.lockscreen.material.KeyguardOrbSurfaceWorkerTestHooks
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
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

    /** Two independent instrumentation processes share only a committed
     * selector receipt and real preferences. Phase two observes the stored
     * route before the common service fixture writes any preference. */
    @Test fun routeSelectionSurvivesReattachAndRestart() {
        val args = InstrumentationRegistry.getArguments()
        val source = requireNotNull(args.getString("sourceSha"))
        require(source.matches(Regex("[0-9a-f]{40}")))
        val caseId = UUID.fromString(requireNotNull(args.getString("runUuid"))).toString()
        val target = KeyguardOrbRenderMode.entries.single { it.name == args.getString("r12Mode") }
        val phase = requireNotNull(args.getString("selectorPhase"))
        require(phase == "one" || phase == "two")
        val directory = File(context.filesDir, "keyguard-service-probe/r15-contract/$caseId/selector")
        check(directory.isDirectory || directory.mkdirs())
        val receipt = File(directory, "phase-one.properties")
        val rows = mutableListOf<String>()
        fun emit(stage: String, detail: String) {
            rows += "stage=$stage uptimeMs=${SystemClock.uptimeMillis()} source=$source case=$caseId route=${target.name} phase=$phase $detail"
        }
        val prefs = context.getSharedPreferences("fluvi_keyguard_orb_diagnostic_route", android.content.Context.MODE_PRIVATE)
        val pid = android.os.Process.myPid()
        val processStart = File("/proc/self/stat").readText().substringAfterLast(')').trim().split(Regex("\\s+"))[19]
        val properties = java.util.Properties()
        var phaseTwoReadFailure: Throwable? = null
        if (phase == "one") {
            check(!receipt.exists()) { "selector case UUID was reused" }
            properties.setProperty("source", source)
            properties.setProperty("case", caseId)
            properties.setProperty("target", target.name)
            properties.setProperty("pid", pid.toString())
            properties.setProperty("processStart", processStart)
            properties.setProperty("hadMode", prefs.contains("mode").toString())
            properties.setProperty("originalMode", prefs.getString("mode", "") ?: "")
            properties.setProperty("result", "INCOMPLETE")
            receipt.outputStream().use { properties.store(it, "R15 selector phase one") }
        } else {
            phaseTwoReadFailure = runCatching {
                check(receipt.isFile) { "phase-one receipt unavailable" }
                receipt.inputStream().use { properties.load(it) }
                val persisted = KeyguardOrbRenderModeStore.read(context)
                emit("PRE_FIXTURE_READ", "configured=${persisted.name} pid=$pid processStart=$processStart")
                check(properties.getProperty("source") == source && properties.getProperty("case") == caseId &&
                    properties.getProperty("target") == target.name && properties.getProperty("result") == "PASS") {
                    "phase-one source/case/result does not match"
                }
                check(properties.getProperty("pid") != pid.toString() || properties.getProperty("processStart") != processStart) {
                    "phase two did not start a new process"
                }
                check(persisted == target) { "selected route did not persist before fixture initialization" }
            }.exceptionOrNull()
        }
        automation = instrumentation.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        val originalScale = Settings.Global.getString(context.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE)
        require(originalScale == null || originalScale.matches(Regex("[0-9]+(?:\\.[0-9]+)?")))
        fun setScale(value: String?) {
            if (value == null) shell("settings delete global animator_duration_scale")
            else shell("settings put global animator_duration_scale $value")
            val actual = Settings.Global.getString(context.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE)
            check(if (value == null) actual == null else actual?.toFloatOrNull() == value.toFloatOrNull())
        }
        val timing = KeyguardR12ServiceTimingInstrumentationTest()
        timing.fixtureRunIdOverride = UUID.randomUUID().toString()
        timing.retainSelectionAfterTest = true
        timing.wakeCount = 2
        val initial = if (target == KeyguardOrbRenderMode.LEGACY_R11) KeyguardOrbRenderMode.SURFACE_LIVE else KeyguardOrbRenderMode.LEGACY_R11
        val firstAttachment = AtomicReference<Long?>()
        var failure: Throwable? = null
        try {
            phaseTwoReadFailure?.let { throw it }
            if (phase == "one") {
                setScale("1")
                timing.initialModeOverride = initial
                timing.expectedModeForWake = { index, _ -> if (index == 0) initial else target }
                timing.firstVisibleControl = { actual ->
                    check(actual == initial)
                    val first = sample()
                    firstAttachment.set(first.attachment)
                    instrumentation.runOnMainSync {
                        val service = checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation())
                        val before = service.renderModeStatus()
                        check(before.visible && before.configured == initial && before.effective == initial)
                        check(KeyguardOrbRenderModeStore.write(context, target))
                        service.onOrbRenderModeChanged()
                        val pending = service.renderModeStatus()
                        check(pending.visible && pending.configured == target && pending.attachedSelection == initial &&
                            pending.effective == initial && pending.pendingBoundary)
                        emit("PENDING", "attachment=${first.attachment} before=${before.configured} selected=${pending.configured} effective=${pending.effective} pending=true")
                    }
                }
                timing.wakeVisibleControl = { index, actual ->
                    if (index == 1) {
                        val second = sample()
                        check(actual == target && second.attachment > checkNotNull(firstAttachment.get()))
                        instrumentation.runOnMainSync {
                            val status = checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation()).renderModeStatus()
                            check(status.configured == target && status.attachedSelection == target && !status.pendingBoundary)
                        }
                        emit("REATTACHED", "attachment=${second.attachment} configured=${target.name} effective=${second.route} pending=false")
                    }
                }
            } else {
                val fallback = target != KeyguardOrbRenderMode.LEGACY_R11
                setScale(if (fallback) "0" else "1")
                timing.initialModeOverride = target
                if (!fallback) timing.wakeCount = 4
                timing.expectedModeForWake = { index, _ ->
                    if (fallback && index == 0) KeyguardOrbRenderMode.LEGACY_R11 else target
                }
                timing.firstVisibleControl = { actual ->
                    val state = sample()
                    check(actual == if (fallback) KeyguardOrbRenderMode.LEGACY_R11 else target)
                    emit("RESTARTED", "attachment=${state.attachment} configured=${KeyguardOrbRenderModeStore.read(context)} effective=$actual fallback=$fallback")
                    if (fallback) setScale("1")
                }
                timing.wakeVisibleControl = { index, actual ->
                    if (index == 1) {
                        check(actual == target)
                        emit("ELIGIBLE_AGAIN", "attachment=${sample().attachment} effective=$actual")
                        if (!fallback) {
                            instrumentation.runOnMainSync {
                                check(KeyguardOrbRenderModeStore.write(context, KeyguardOrbRenderMode.SURFACE_LIVE))
                                checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation()).onOrbRenderModeChanged()
                            }
                            setScale("0")
                        }
                    } else if (index == 2 && !fallback) {
                        instrumentation.runOnMainSync {
                            val service = checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation())
                            val status = service.renderModeStatus()
                            check(status.configured == KeyguardOrbRenderMode.SURFACE_LIVE &&
                                status.attachedSelection == KeyguardOrbRenderMode.SURFACE_LIVE &&
                                status.effective == KeyguardOrbRenderMode.LEGACY_R11)
                            emit("INELIGIBLE_FALLBACK", "configured=${status.configured} effective=${status.effective}")
                            check(KeyguardOrbRenderModeStore.write(context, target))
                            service.onOrbRenderModeChanged()
                        }
                        setScale("1")
                    }
                }
            }
            emit("FIXTURE_START", "timingRun=${timing.fixtureRunIdOverride}")
            timing.fourRealWakeCyclesUseRequestedRoute()
            if (phase == "one") {
                check(rows.any { it.startsWith("stage=PENDING ") } && rows.any { it.startsWith("stage=REATTACHED ") })
                check(KeyguardOrbRenderModeStore.read(context) == target)
                properties.setProperty("result", "PASS")
                receipt.outputStream().use { properties.store(it, "R15 selector phase one") }
            } else check(rows.any { it.startsWith("stage=RESTARTED ") } && rows.any { it.startsWith("stage=ELIGIBLE_AGAIN ") })
        } catch (error: Throwable) {
            failure = error
            emit("FAILURE", "type=${error.javaClass.simpleName} message=${error.message}")
            throw error
        } finally {
            runCatching { setScale(originalScale) }.onFailure { failure?.addSuppressed(it) ?: run { failure = it } }
            if (phase == "two" && properties.containsKey("hadMode")) runCatching {
                val edit = prefs.edit()
                if (properties.getProperty("hadMode") == "true") edit.putString("mode", properties.getProperty("originalMode"))
                else edit.remove("mode")
                check(edit.commit())
                emit("RESTORED", "hadMode=${properties.getProperty("hadMode")}")
            }.onFailure { failure?.addSuppressed(it) ?: run { failure = it } }
            File(directory, "phase-$phase.txt").writeText(rows.joinToString("\n", postfix = "\n"))
            if (failure != null && rows.none { it.startsWith("stage=FAILURE ") }) throw AssertionError("selector cleanup failed", failure)
        }
    }

    /** Sequential real reader/apply dispositions, scoped to the service's
     * actual financial work. A disposable database receives one synthetic
     * ledger entry through the public write boundary and removes it again. */
    @Test fun stableServiceMainConfirmationsDoNotDemandBitmaps() {
        val args = InstrumentationRegistry.getArguments()
        val source = requireNotNull(args.getString("sourceSha"))
        require(source.matches(Regex("[0-9a-f]{40}")))
        val runId = UUID.fromString(requireNotNull(args.getString("runUuid"))).toString()
        val route = KeyguardOrbRenderMode.entries.single { it.name == args.getString("r12Mode") }
        val output = File(context.filesDir, "keyguard-service-probe/r15-contract/$runId/financial-main")
        check(!output.exists() && output.mkdirs())
        data class Read(val request: KeyguardCardInspectionRequest, val decision: KeyguardCardVisibility,
                        val reason: KeyguardSurfaceReason, val complete: Boolean)
        data class Work(val request: Long?, val attachment: Long?, val route: Int, val noOp: Boolean,
                        val demand: Long, val paint: Long, val binds: Long, val completed: Boolean)
        val reads = java.util.concurrent.ConcurrentHashMap<Long, Read>()
        val current = java.util.concurrent.ConcurrentHashMap<Long, Boolean>()
        val applied = java.util.concurrent.ConcurrentHashMap<Long, KeyguardCardVisibility>()
        val offered = java.util.concurrent.ConcurrentHashMap<String, Long>()
        val work = java.util.Collections.synchronizedList(mutableListOf<Work>())
        val rows = java.util.Collections.synchronizedList(mutableListOf<String>())
        val paintCount = AtomicInteger()
        var createdEntry: String? = null
        val timing = KeyguardR12ServiceTimingInstrumentationTest().apply { wakeCount = 1 }
        timing.firstVisibleControl = { actualRoute ->
            check(actualRoute == route && keyguard.isKeyguardLocked)
            val service = checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation())
            val contentField = FluviKeyguardCardService::class.java.getDeclaredField("renderedFullContent").apply { isAccessible = true }
            fun content(): com.fluvi.app.runtime.FluviLockScreenCardContent? {
                var result: com.fluvi.app.runtime.FluviLockScreenCardContent? = null
                instrumentation.runOnMainSync { result = contentField.get(service) as? com.fluvi.app.runtime.FluviLockScreenCardContent }
                return result
            }
            await("real synthetic-account financial projection", 20_000) { content() != null }
            val initial = checkNotNull(content())
            val owner = sample()
            com.fluvi.app.runtime.FluviFinancialOrbPaintTestHook.onPaint = { paintCount.incrementAndGet() }
            KeyguardR15AcquisitionTestHooks.financialObserver = { request, scope ->
                work += Work(request, scope.attachment, scope.routeCode, scope.noOp, scope.demands,
                    scope.paints, scope.legacyBinds, scope.completed)
            }
            service.inspectionProbeForTest = object : KeyguardInspectionProbeForTest {
                override fun queueOffered(request: KeyguardCardInspectionRequest, previous: KeyguardCardInspectionRequest?,
                    pending: KeyguardCardInspectionRequest?, startsWorker: Boolean) {
                    if (request.trigger.startsWith("r15-stable-")) offered[request.trigger] = request.id
                }
                override fun readCompleted(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility,
                    reason: KeyguardSurfaceReason, rootUnavailable: Boolean, walkTruncated: Boolean,
                    abortedStale: Boolean, startedAt: Long, finishedAt: Long) {
                    if (request.trigger.startsWith("r15-stable-")) {
                        reads[request.id] = Read(request, decision, reason, !rootUnavailable && !walkTruncated && !abortedStale)
                    }
                }
                override fun beforeDecision(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility,
                    pending: KeyguardCardInspectionRequest?, authority: KeyguardInspectionAuthority) {
                    if (request.trigger.startsWith("r15-stable-")) current[request.id] = authority.matches(request)
                }
                override fun afterApply(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility) {
                    if (request.trigger.startsWith("r15-stable-")) applied[request.id] = decision
                }
            }
            try {
                val schedule = FluviKeyguardCardService::class.java.getDeclaredMethod("scheduleEvaluation",
                    String::class.java, java.lang.Long::class.java, java.lang.Long::class.java,
                    KeyguardWindowFreshness::class.java, KeyguardCardInspectionRequest::class.java).apply { isAccessible = true }
                val distinct = mutableSetOf<Long>()
                repeat(32) { index ->
                    if (index == 16) instrumentation.runOnMainSync {
                        val prior = FluviKeyguardCardSettings.read(context)
                        val next = FluviKeyguardCardSettings.patchLayout(context,
                            mapOf("orbPosition" to mapOf("xFraction" to 0.35f, "yFraction" to 0.61f)))
                        check(next.layoutRevision > prior.layoutRevision) { "geometry-only input did not change" }
                    }
                    val trigger = "r15-stable-$index"
                    instrumentation.runOnMainSync {
                        schedule.invoke(service, trigger, null, SystemClock.uptimeMillis(), KeyguardWindowFreshness.FRAMEWORK_EVENT, null)
                    }
                    val id = checkNotNull(offered[trigger]) { "inspection offer missing for $trigger" }
                    check(distinct.add(id)) { "inspection id was reused" }
                    await("completed current MAIN inspection $id", 12_000) { applied.containsKey(id) }
                    val read = checkNotNull(reads[id])
                    check(read.complete && read.reason == KeyguardSurfaceReason.MAIN_CONFIRMED &&
                        read.decision == KeyguardCardVisibility.SHOW_FULL && current[id] == true &&
                        applied[id] == KeyguardCardVisibility.SHOW_FULL) { "inspection $id was not a complete current MAIN confirmation" }
                    val owned = synchronized(work) { work.filter { it.request == id } }
                    check(owned.isNotEmpty() && owned.all { it.completed && it.attachment == owner.attachment }) {
                        "inspection $id has no immutable matching financial scope"
                    }
                    if (index != 16) check(owned.all { it.noOp }) { "unchanged inspection $id was not a no-op" }
                    if (route != KeyguardOrbRenderMode.LEGACY_R11) check(owned.all { it.demand == 0L && it.paint == 0L && it.binds == 0L }) {
                        "surface no-op demanded legacy financial pixels"
                    }
                    rows += "inspection=$id session=${read.request.session} wake=${read.request.wakeGeneration} attachment=${read.request.attachGeneration} " +
                        "complete=true reason=${read.reason} scopeCount=${owned.size} noOp=${owned.all { it.noOp }} " +
                        "demands=${owned.sumOf { it.demand }} paints=${owned.sumOf { it.paint }} binds=${owned.sumOf { it.binds }} geometryOnly=${index == 16}"
                }
                val paintBeforeChange = paintCount.get()
                val workBeforeChange = synchronized(work) { work.size }
                val core = com.fluvi.core.FluviCoreFactory.create(context)
                try {
                    createdEntry = kotlinx.coroutines.runBlocking {
                        val category = core.categories.list().single { it.isSystemUncategorized }
                        core.ledger.createManual(com.fluvi.core.model.CreateManualTransactionCommand(
                            partner = com.fluvi.core.model.ManualTransactionPartnerSelection.New("R15 synthetic $runId", category.id),
                            categorySelection = com.fluvi.core.model.LedgerCategorySelection.PartnerDefault,
                            direction = com.fluvi.core.model.LedgerDirection.expense,
                            amountScaled100 = 1234500L,
                            bookedLocalEpochDay = java.time.LocalDate.now().toEpochDay(),
                            bookedLocalTimeMinutes = 720,
                            occurredAtUtcMs = System.currentTimeMillis(), note = null,
                        )).id
                    }
                } finally { core.close() }
                await("changed real financial projection", 20_000) { content()?.primary != initial.primary }
                val changed = synchronized(work) { work.drop(workBeforeChange) }
                check(changed.any { it.completed && it.attachment == owner.attachment }) { "changed input had no owned presentation scope" }
                if (route == KeyguardOrbRenderMode.LEGACY_R11) {
                    check(paintCount.get() > paintBeforeChange && changed.any { it.demand > 0 && it.paint > 0 }) {
                        "legacy control did not demand a real bitmap for the changed financial input"
                    }
                } else check(changed.all { it.demand == 0L && it.paint == 0L && it.binds == 0L }) {
                    "surface route demanded legacy bitmap during changed financial input"
                }
                rows += "financialChange=OBSERVED entry=synthetic completedScopes=${changed.size} actualPaints=${paintCount.get() - paintBeforeChange} " +
                    "actualDemands=${changed.sumOf { it.demand }} actualBinds=${changed.sumOf { it.binds }} route=${route.name}"
            } finally {
                service.inspectionProbeForTest = null
                KeyguardR15AcquisitionTestHooks.financialObserver = null
                com.fluvi.app.runtime.FluviFinancialOrbPaintTestHook.onPaint = null
            }
        }
        try {
            timing.fourRealWakeCyclesUseRequestedRoute()
            assertEquals("32 distinct actual MAIN dispositions required", 32, rows.count { it.startsWith("inspection=") })
            assertTrue("changed financial input was not observed", rows.any { it.startsWith("financialChange=OBSERVED") })
        } finally {
            KeyguardR15AcquisitionTestHooks.financialObserver = null
            com.fluvi.app.runtime.FluviFinancialOrbPaintTestHook.onPaint = null
            timing.firstVisibleControl = null
            var cleanupError: Throwable? = null
            try {
                createdEntry?.let { id ->
                    val core = com.fluvi.core.FluviCoreFactory.create(context)
                    try { kotlinx.coroutines.runBlocking { core.ledger.delete(id) } } finally { core.close() }
                }
            } catch (error: Throwable) {
                cleanupError = error
                rows += "syntheticEntryCleanup=FAILED error=${error.javaClass.simpleName}"
            } finally {
                File(output, "fixture.txt").writeText(synchronized(rows) { rows.joinToString("\n", postfix = "\n") })
            }
            cleanupError?.let { throw AssertionError("synthetic financial entry cleanup failed", it) }
        }
    }

    /** Real holder callbacks and an independently released entered draw. The
     * compositor pixels are retained separately and remain unclassified. */
    @Test fun realHolderRevocationAcrossGeneration() {
        val args = InstrumentationRegistry.getArguments()
        val source = requireNotNull(args.getString("sourceSha"))
        require(source.matches(Regex("[0-9a-f]{40}")))
        val runId = UUID.fromString(requireNotNull(args.getString("runUuid"))).toString()
        val route = KeyguardOrbRenderMode.entries.single { it.name == args.getString("r12Mode") }
        val output = File(context.filesDir, "keyguard-service-probe/r15-contract/$runId/holder-generation")
        check(!output.exists() && output.mkdirs())
        automation = instrumentation.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        automation.serviceInfo = automation.serviceInfo.apply {
            flags = flags or AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
        }
        data class Boundary(val target: KeyguardOrbSurfaceTarget, val stage: String, val token: Long, val at: Long)
        val boundaries = java.util.Collections.synchronizedList(mutableListOf<Boundary>())
        val notes = java.util.Collections.synchronizedList(mutableListOf<String>())
        fun emit(stage: String, detail: String) {
            notes += "stage=$stage uptimeMs=${SystemClock.uptimeMillis()} source=$source run=$runId route=${route.name} $detail"
        }
        fun snapshot(): List<Boundary> = synchronized(boundaries) { boundaries.toList() }
        val timing = KeyguardR12ServiceTimingInstrumentationTest().apply { wakeCount = 1 }
        timing.serviceConnectedControl = {
            KeyguardOrbSurfaceWorkerTestHooks.holderBoundary = { target, stage, token ->
                boundaries += Boundary(target, stage, token, SystemClock.uptimeMillis())
            }
        }
        timing.firstVisibleControl = { actualRoute ->
            check(actualRoute == route && keyguard.isKeyguardLocked)
            val first = sample()
            val firstBounds = bounds(route)
            screenshot(output, "generation-1", ::emit)
            emit("FIRST_OWNER", "session=${first.session} wake=${first.wake} attachment=${first.attachment} bounds=${firstBounds.joinToString(",")} pixels=UNCLASSIFIED")
            val release = CountDownLatch(1)
            val held = CountDownLatch(1)
            val selected = AtomicReference<KeyguardOrbSurfaceTarget?>()
            val independentFailure = AtomicReference<Throwable?>()
            val claimed = AtomicBoolean(false)
            val oldAfterDestroy = AtomicBoolean(false)
            val heldOperation = java.util.concurrent.atomic.AtomicLong()
            var controller: Thread? = null
            var occluderStarted = false
            try {
                if (route != KeyguardOrbRenderMode.LEGACY_R11) {
                    KeyguardOrbSurfaceWorkerTestHooks.afterCanvasLock = { target ->
                        val old = selected.get()
                        if (old === target && snapshot().any { it.target === target && it.stage == "DESTROY_RETURN" }) {
                            oldAfterDestroy.set(true)
                        }
                        if (target.attachment == first.attachment && claimed.compareAndSet(false, true)) {
                            selected.set(target)
                            val operation = target.metrics?.holderSnapshot()
                            if (operation?.coherent != true || operation.id <= 0 || operation.lockReturn == null) {
                                independentFailure.compareAndSet(null, IllegalStateException("actual holder operation identity unavailable"))
                            } else {
                                heldOperation.set(operation.id)
                                emit("G1_LOCKED", "attachment=${target.attachment} generation=${target.generation} holder=${System.identityHashCode(target.holder)} operation=${operation.id} lockReturn=${operation.lockReturn}")
                            }
                            held.countDown()
                            if (!release.await(30, TimeUnit.SECONDS)) {
                                independentFailure.compareAndSet(null, IllegalStateException("entered holder operation was not independently released"))
                            }
                        }
                    }
                    if (route == KeyguardOrbRenderMode.SURFACE_STATIC) {
                        val next = timing.materialProfile().toMutableMap().apply {
                            put("publisherRevision", 2L)
                            put("colors", listOf(0xff5843a9.toInt(), 0xffbf6192.toInt(), 0xffdfb060.toInt()))
                        }
                        val prefs = context.getSharedPreferences("fluvi_keyguard_header_material", android.content.Context.MODE_PRIVATE)
                        val epoch = maxOf(SystemClock.elapsedRealtimeNanos(), prefs.getLong("publisherEpoch", -1L) + 1L)
                        check(FluviKeyguardMaterialStore.publish(context, next, epoch))
                    }
                    check(held.await(15, TimeUnit.SECONDS)) { "G1 did not enter an actual holder operation" }
                    val old = checkNotNull(selected.get())
                    emit("G1_HELD", "attachment=${old.attachment} generation=${old.generation} holder=${System.identityHashCode(old.holder)}")
                    controller = Thread({
                        try {
                            val deadline = SystemClock.uptimeMillis() + 20_000
                            while (!old.revoked && SystemClock.uptimeMillis() < deadline) SystemClock.sleep(20)
                            check(old.revoked) { "actual G1 revocation was not observed" }
                            val op = old.metrics?.holderSnapshot()
                            emit("INDEPENDENT_RELEASE", "attachment=${old.attachment} generation=${old.generation} holder=${System.identityHashCode(old.holder)} operation=${heldOperation.get()} revoked=${old.revoked} revokeReturn=${op?.revokeReturn ?: "UNOBSERVED"}")
                        } catch (error: Throwable) { independentFailure.compareAndSet(null, error) }
                        finally { release.countDown() }
                    }, "r15-independent-holder-release").apply { start() }
                }
                instrumentation.context.startActivity(Intent().setClassName("com.fluvi.app.test",
                    "com.fluvi.app.lockscreen.KeyguardR14ControlledOccluderActivity")
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                occluderStarted = true
                controller?.join(25_000)
                check(controller?.isAlive != true) { "independent holder release did not finish" }
                independentFailure.get()?.let { throw AssertionError("holder release fixture failed", it) }
                await("independent cover and service withdrawal", 15_000) { occluderWindowId() != null && !sample().attached }
                if (route != KeyguardOrbRenderMode.LEGACY_R11) {
                    val old = checkNotNull(selected.get())
                    await("G1 real surfaceDestroyed return", 15_000) {
                        snapshot().any { it.target === old && it.stage == "DESTROY_RETURN" }
                    }
                    check(old.revoked && !oldAfterDestroy.get())
                    val finished = checkNotNull(old.metrics?.holderSnapshot())
                    check(finished.coherent && finished.id == heldOperation.get() && finished.postReturn != null) {
                        "held G1 operation did not finish under its original identity"
                    }
                    emit("G1_FINISHED", "attachment=${old.attachment} generation=${old.generation} holder=${System.identityHashCode(old.holder)} operation=${finished.id} postReturn=${finished.postReturn}")
                } else {
                    check(snapshot().isEmpty()) { "legacy service unexpectedly registered a SurfaceView holder" }
                }
                screenshot(output, "covered", ::emit)
                check(automation.performGlobalAction(AccessibilityService.GLOBAL_ACTION_BACK))
                occluderStarted = false
                await("new service attachment after holder retirement", 20_000) {
                    val current = sample()
                    keyguard.isKeyguardLocked && current.attached && current.attachment > first.attachment &&
                        current.session == first.session && current.wake == first.wake && current.route == route
                }
                val second = sample()
                if (route != KeyguardOrbRenderMode.LEGACY_R11) {
                    val old = checkNotNull(selected.get())
                    await("G2 real holder created", 15_000) {
                        snapshot().any { it.target.attachment == second.attachment && it.stage == "CREATED" }
                    }
                    val fresh = snapshot().first { it.target.attachment == second.attachment && it.stage == "CREATED" }.target
                    check(fresh !== old && fresh.holder !== old.holder && !fresh.revoked)
                    await("G2 current producer submission", 15_000) {
                        var submitted = false
                        instrumentation.runOnMainSync {
                            submitted = (FluviKeyguardCardServiceRegistry.serviceForInstrumentation()?.surfaceMetricsForInstrumentation()?.submissions ?: 0L) > 0L
                        }
                        submitted
                    }
                    await("G2 actual Callback2 completion", 15_000) {
                        val events = snapshot()
                        events.any { request -> request.target === fresh && request.stage == "REDRAW_REQUEST" &&
                            events.count { it.target === fresh && it.stage == "REDRAW_COMPLETE" && it.token == request.token } == 1 }
                    }
                    val freshOperation = checkNotNull(fresh.metrics?.holderSnapshot())
                    check(freshOperation.coherent && freshOperation.id > 0 && freshOperation.postReturn != null)
                    emit("G2_OWNER", "attachment=${fresh.attachment} generation=${fresh.generation} holder=${System.identityHashCode(fresh.holder)} operation=${freshOperation.id} postReturn=${freshOperation.postReturn} producer=posted pixels=UNCLASSIFIED")
                }
                screenshot(output, "generation-2", ::emit)
                emit("RETURN", "session=${second.session} wake=${second.wake} firstAttachment=${first.attachment} attachment=${second.attachment} pixels=UNCLASSIFIED")
                check(!oldAfterDestroy.get()) { "old holder reached a canvas lock after surfaceDestroyed returned" }
            } finally {
                release.countDown()
                controller?.join(10_000)
                KeyguardOrbSurfaceWorkerTestHooks.afterCanvasLock = null
                if (occluderStarted) automation.performGlobalAction(AccessibilityService.GLOBAL_ACTION_BACK)
            }
        }
        try {
            timing.fourRealWakeCyclesUseRequestedRoute()
            assertTrue("holder fixture did not reach a new attachment", notes.any { it.startsWith("stage=RETURN ") })
            if (route != KeyguardOrbRenderMode.LEGACY_R11) {
                val events = snapshot()
                val requested = events.filter { it.stage == "REDRAW_REQUEST" }
                assertTrue("platform never requested an asynchronous holder redraw", requested.isNotEmpty())
                requested.forEach { request ->
                    assertEquals("each actual Callback2 redraw must complete exactly once", 1,
                        events.count { it.target === request.target && it.stage == "REDRAW_COMPLETE" && it.token == request.token })
                }
            }
        } finally {
            KeyguardOrbSurfaceWorkerTestHooks.afterCanvasLock = null
            KeyguardOrbSurfaceWorkerTestHooks.holderBoundary = null
            timing.firstVisibleControl = null
            timing.serviceConnectedControl = null
            val eventRows = snapshot().joinToString("\n") {
                "stage=${it.stage} uptimeMs=${it.at} attachment=${it.target.attachment} generation=${it.target.generation} holder=${System.identityHashCode(it.target.holder)} token=${it.token}"
            }
            File(output, "fixture.txt").writeText(synchronized(notes) { notes.joinToString("\n", postfix = "\n") } + eventRows +
                "\nvisualQualification=NOT_ESTABLISHED independentRecordingAndCalibrationRequired=true\n" +
                "earlyRevokedRedraw=NOT_ESTABLISHED unless an actual pending callback is present in the recorded boundaries\n")
        }
    }

    /** Exercises the actual selected lower-privacy configuration and a late
     * old material update. The host must classify its independent recording;
     * these service states and screenshots cannot prove privacy by themselves. */
    @Test fun serviceDowngradeRevokesOldFull() {
        val args = InstrumentationRegistry.getArguments()
        val source = requireNotNull(args.getString("sourceSha"))
        require(source.matches(Regex("[0-9a-f]{40}")))
        val runId = UUID.fromString(requireNotNull(args.getString("runUuid"))).toString()
        val route = KeyguardOrbRenderMode.entries.single { it.name == args.getString("r12Mode") }
        val output = File(context.filesDir, "keyguard-service-probe/r15-contract/$runId/privacy-downgrade")
        check(!output.exists() && output.mkdirs())
        automation = instrumentation.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        automation.serviceInfo = automation.serviceInfo.apply {
            flags = flags or AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
        }
        val rows = mutableListOf<String>()
        fun emit(stage: String, detail: String) {
            rows += "stage=$stage uptimeMs=${SystemClock.uptimeMillis()} source=$source run=$runId route=${route.name} $detail"
        }
        val timing = KeyguardR12ServiceTimingInstrumentationTest().apply { wakeCount = 1 }
        timing.firstVisibleControl = { actualRoute ->
            check(actualRoute == route && keyguard.isKeyguardLocked)
            val first = sample()
            check(first.attached && first.attachment > 0 && first.route == route)
            await("actual full presentation before downgrade", 10_000) { currentPresentationFull() == true }
            val originalProfile = checkNotNull(FluviKeyguardMaterialStore.read(context))
            val firstBounds = bounds(route)
            screenshot(output, "before-downgrade", ::emit)
            emit("FULL_OWNER", "session=${first.session} wake=${first.wake} attachment=${first.attachment} " +
                "bounds=${firstBounds.joinToString(",")} pixels=UNCLASSIFIED")
            val release = CountDownLatch(1)
            val entered = CountDownLatch(1)
            val claimed = AtomicBoolean(false)
            val barrierTimedOut = AtomicBoolean(false)
            val oldTarget = AtomicReference<KeyguardOrbSurfaceTarget?>()
            try {
                if (route != KeyguardOrbRenderMode.LEGACY_R11) {
                    KeyguardOrbSurfaceWorkerTestHooks.afterCanvasLock = { target ->
                        if (target.attachment == first.attachment && target.full && claimed.compareAndSet(false, true)) {
                            oldTarget.set(target)
                            entered.countDown()
                            if (!release.await(25, TimeUnit.SECONDS)) barrierTimedOut.set(true)
                        }
                    }
                    if (route == KeyguardOrbRenderMode.SURFACE_STATIC) {
                        val nextProfile = timing.materialProfile().toMutableMap().apply {
                            put("publisherRevision", 2L)
                            put("colors", listOf(0xff5843a9.toInt(), 0xffbf6192.toInt(), 0xffdfb060.toInt()))
                        }
                        val prefs = context.getSharedPreferences("fluvi_keyguard_header_material", android.content.Context.MODE_PRIVATE)
                        val epoch = maxOf(SystemClock.elapsedRealtimeNanos(), prefs.getLong("publisherEpoch", -1L) + 1L)
                        check(FluviKeyguardMaterialStore.publish(context, nextProfile, epoch))
                    }
                    check(entered.await(15, TimeUnit.SECONDS)) { "current full holder never entered the real draw boundary" }
                    val target = checkNotNull(oldTarget.get())
                    emit("HELD", "attachment=${target.attachment} generation=${target.generation} holder=${System.identityHashCode(target.holder)}")
                }
                val downgradeAt = SystemClock.uptimeMillis()
                instrumentation.runOnMainSync {
                    val result = FluviKeyguardCardSettings.update(context, mapOf("showFinancialDetails" to false))
                    check(!result.showFinancialDetails)
                }
                if (route != KeyguardOrbRenderMode.LEGACY_R11) {
                    val old = checkNotNull(oldTarget.get())
                    await("old full holder revoked", 12_000) { old.revoked }
                    check(!barrierTimedOut.get()) { "old holder barrier timed out before revocation" }
                    emit("OLD_REVOKED", "attachment=${old.attachment} generation=${old.generation} holder=${System.identityHashCode(old.holder)}")
                    release.countDown()
                }
                await("actual discreet presentation", 20_000) { sample().attached && currentPresentationFull() == false }
                val service = checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation())
                // This is the real service update entry point, with a captured
                // pre-downgrade profile intentionally delivered late.
                service.onMaterialProfileChangedFromApplication(originalProfile)
                await("discreet remains current after late old update", 10_000) { sample().attached && currentPresentationFull() == false }
                val after = sample()
                screenshot(output, "after-downgrade", ::emit)
                emit("DISCREET_OWNER", "downgrade=$downgradeAt session=${after.session} wake=${after.wake} " +
                    "attachment=${after.attachment} pixels=UNCLASSIFIED lateOldUpdate=true")
                val shadeAt = SystemClock.uptimeMillis()
                shell("cmd statusbar expand-notifications")
                await("independent SystemUI shade marker", 12_000) { shadeVisible() }
                await("service withdrawal on independent shade", 15_000) { !sample().attached }
                screenshot(output, "restricted-shade", ::emit)
                emit("RESTRICTED", "kind=shade requested=$shadeAt locked=${keyguard.isKeyguardLocked} pixels=UNCLASSIFIED")
            } finally {
                release.countDown()
                KeyguardOrbSurfaceWorkerTestHooks.afterCanvasLock = null
                runCatching { shell("cmd statusbar collapse") }
            }
        }
        try {
            timing.fourRealWakeCyclesUseRequestedRoute()
            assertTrue("privacy fixture did not reach the restricted surface", rows.any { it.startsWith("stage=RESTRICTED ") })
        } finally {
            KeyguardOrbSurfaceWorkerTestHooks.afterCanvasLock = null
            timing.firstVisibleControl = null
            File(output, "fixture.txt").writeText(rows.joinToString("\n", postfix = "\n") +
                "privacyQualification=NOT_ESTABLISHED independentRecordingAndCalibrationRequired=true\n")
        }
    }

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
        val timing = KeyguardR12ServiceTimingInstrumentationTest().apply { wakeCount = 1 }
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

    private fun currentPresentationFull(): Boolean? {
        var result: Boolean? = null
        instrumentation.runOnMainSync {
            val service = FluviKeyguardCardServiceRegistry.serviceForInstrumentation() ?: return@runOnMainSync
            val field = FluviKeyguardCardService::class.java.getDeclaredField("overlay").apply { isAccessible = true }
            result = (field.get(service) as? KeyguardCardWindow)?.currentPresentationFull()
        }
        return result
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

    private fun shadeVisible(): Boolean = automation.windows.any { window ->
        val root = window.root ?: return@any false
        try {
            if (root.packageName?.toString() != "com.android.systemui") return@any false
            listOf("com.android.systemui:id/quick_settings_panel", "com.android.systemui:id/quick_qs_panel",
                "com.android.systemui:id/qs_frame", "com.android.systemui:id/settings_button").any { id ->
                val matches = root.findAccessibilityNodeInfosByViewId(id)
                try { matches.any { it.isVisibleToUser } } finally { matches.forEach { it.recycle() } }
            }
        } finally { root.recycle() }
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
