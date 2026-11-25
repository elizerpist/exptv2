package com.fluvi.app.lockscreen

import android.Manifest
import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import android.app.KeyguardManager
import android.app.UiAutomation
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
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.atomic.AtomicReference
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

/** Controlled real-service ordering test. The route snapshot is produced by
 * the service and is never supplied or overridden by this fixture. */
@RunWith(AndroidJUnit4::class)
class KeyguardR26DirectOrderingInstrumentationTest {
    @Test fun pendingDirectWaitsForOrderedMainThenStartsRealSuccessor() = exercise(true)
    @Test fun stableDirectUsesOrderedMainAndLaterOfferWaits() = exercise(false)
    @Test fun orderedDirectSkipsInapplicableR25Evaluation() = exercise(true, true)
    @Test fun warmOrderedDirectSkipsInapplicableR25Evaluation() = exercise(true, true, warmup = true)
    @Test fun readyWorkDoesNotWaitForDiagnosticPublication() = exercise(true, true, warmup = true, checkReport = true)
    @Test fun r42PreStartSelectsActualLatestRequest() = exercise(true, preStart = true)
    @Test fun r42StalePositiveExitsAfterOrderedRestrictions() = exercise(true, warmup = true, duringRead = true)
    @Test fun r42StalePositiveAfterRealReadExitsBeforePositivePath() = exercise(true, afterRead = true)

    private data class Route(val backend:String, val reservation:Long, val host:Long, val output:Long)
    private fun exercise(pendingBefore:Boolean, checkR41Bypass:Boolean = false, warmup:Boolean = false, checkReport:Boolean = false, preStart:Boolean = false, duringRead:Boolean = false, afterRead:Boolean = false) {
        assertEquals(35, Build.VERSION.SDK_INT)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        val args = InstrumentationRegistry.getArguments()
        val source = requireNotNull(args.getString("sourceSha"))
        require(source.matches(Regex("[0-9a-f]{40}")))
        val uuid = UUID.fromString(requireNotNull(args.getString("runUuid"))).toString()
        val name = if (preStart) "r42-pre-start" else if (duringRead) "r42-stale-positive" else if (afterRead) "r42-stale-after-read" else if (checkReport) "r41-report" else if (warmup) "r41-warm-pending" else if (checkR41Bypass) "r41-pending" else if (pendingBefore) "pending" else "stable-later-offer"
        val dir = File(context.filesDir, "keyguard-service-probe/r26/$uuid/$name")
        check(dir.mkdirs())
        val automation = instrumentation.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
        fun shell(command:String) = ParcelFileDescriptor.AutoCloseInputStream(automation.executeShellCommand(command)).bufferedReader().use { it.readText() }
        fun secure(key:String, value:String?) {
            automation.adoptShellPermissionIdentity(Manifest.permission.WRITE_SECURE_SETTINGS)
            try { check(Settings.Secure.putString(context.contentResolver, key, value)) }
            finally { automation.dropShellPermissionIdentity() }
        }
        fun await(label:String, condition:()->Boolean) {
            val until=SystemClock.uptimeMillis()+15_000
            while(SystemClock.uptimeMillis()<until) { if(condition()) return; SystemClock.sleep(50) }
            throw AssertionError("NOT REACHED: $label")
        }
        fun save(name:String) = context.getSharedPreferences(name,Context.MODE_PRIVATE).let { it to HashMap(it.all) }
        fun restore(saved:Pair<SharedPreferences,Map<String,*>>) {
            val edit=saved.first.edit().clear()
            saved.second.forEach { (key,value) -> when(value) {
                is Boolean -> edit.putBoolean(key,value); is Int -> edit.putInt(key,value); is Long -> edit.putLong(key,value)
                is Float -> edit.putFloat(key,value); is String -> edit.putString(key,value)
                is Set<*> -> edit.putStringSet(key,value.filterIsInstance<String>().toSet())
            } }
            check(edit.commit())
        }
        val savedServices=Settings.Secure.getString(context.contentResolver,Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        val savedEnabled=Settings.Secure.getString(context.contentResolver,Settings.Secure.ACCESSIBILITY_ENABLED)
        val savedLock=shell("locksettings get-disabled").trim()
        val prefs=listOf(save("fluvi_native_keyguard_card"),save("fluvi_keyguard_header_material"),save("fluvi_keyguard_orb_diagnostic_route"))
        val component=ComponentName(context,FluviKeyguardCardService::class.java)
        val other=savedServices.orEmpty().split(':').filter { it.isNotBlank() && ComponentName.unflattenFromString(it)!=component }.joinToString(":")
        val keyguard=context.getSystemService(KeyguardManager::class.java); val power=context.getSystemService(PowerManager::class.java)
        val armed=AtomicBoolean(false); val candidate=AtomicReference<KeyguardCardInspectionRequest?>()
        val route=AtomicReference<Route?>(); val held=CountDownLatch(1); val release=CountDownLatch(1)
        val workerTimeout=AtomicBoolean(false); val done=CountDownLatch(1); val successorStarted=CountDownLatch(1)
        val reportHeld=CountDownLatch(1); val reportRelease=CountDownLatch(1); val reportTimeout=AtomicBoolean(false)
        val originalMain=AtomicLong(0); val originalExit=AtomicLong(0); val bStarted=AtomicLong(0); val bId=AtomicLong(0)
        val preReaderHeld=CountDownLatch(1); val preReaderRelease=CountDownLatch(1)
        val firstPhysical=AtomicLong(0); val firstPhysicalStarted=CountDownLatch(1)
        val realPositive=AtomicBoolean(false); val positivePathEntries=AtomicInteger(0)
        val r25Evaluations=AtomicLong(0); val r25AtAExit=AtomicLong(-1)
        val order=AtomicLong(0); val oldProofAtExit=AtomicLong(0); val maxReaders=AtomicInteger(0); val readers=AtomicInteger(0)
        val r25Posts=AtomicInteger(0); val earlyReveal=AtomicInteger(0); val records=Collections.synchronizedList(mutableListOf<String>())
        val orderedReads=Collections.synchronizedSet(mutableSetOf<Long>())
        val originalCross=KeyguardOrbSurfaceWorkerTestHooks.afterRevealCross
        var service:FluviKeyguardCardService?=null; var failure:Throwable?=null; var capture=false
        try {
            check(!FluviKeyguardCardServiceRegistry.connected && !keyguard.isDeviceSecure)
            check(savedLock=="true" || savedLock=="false")
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,other)
            shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard")
            await("unlocked setup") { power.isInteractive && !keyguard.isKeyguardLocked }
            shell("locksettings set-disabled false")
            check(context.getSharedPreferences("fluvi_keyguard_orb_diagnostic_route",Context.MODE_PRIVATE).edit().putString("mode","SURFACE_LIVE").commit())
            instrumentation.runOnMainSync {
                FluviKeyguardCardSettings.update(context,mapOf("requested" to true,"showFinancialDetails" to true,"presentationMode" to "orb","animationMode" to "orbOnly"))
                val epoch=maxOf(SystemClock.elapsedRealtimeNanos(),(prefs[1].second["publisherEpoch"] as? Long ?: -1L)+1L)
                check(FluviKeyguardMaterialStore.publish(context,KeyguardR12ServiceTimingInstrumentationTest().materialProfile(),epoch))
            }
            KeyguardCardDiagnostics.startCapture(context,source,"debug","LIGHT"); capture=true
            secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,listOf(other,component.flattenToString()).filter(String::isNotBlank).joinToString(":"))
            secure(Settings.Secure.ACCESSIBILITY_ENABLED,"1")
            await("service connected") { FluviKeyguardCardServiceRegistry.connected }
            val actual=checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation()); service=actual
            val lockField=actual.javaClass.getDeclaredField("queueLock").also { it.isAccessible=true }
            val snapshot=actual.javaClass.getDeclaredMethod("r25SnapshotLocked",KeyguardCardInspectionRequest::class.java).also { it.isAccessible=true }
            val gateField=actual.javaClass.getDeclaredField("firstAuthorizedOrb").also { it.isAccessible=true }
            val queueField=actual.javaClass.getDeclaredField("inspectionQueue").also { it.isAccessible=true }
            val emptyDirect=actual.javaClass.getDeclaredMethod("r34EmptyDirectLocked",KeyguardCardInspectionRequest::class.java).also { it.isAccessible=true }
            val queueLock=checkNotNull(lockField.get(actual))
            fun currentRoute(request:KeyguardCardInspectionRequest):Route? = synchronized(queueLock) {
                val value=snapshot.invoke(actual,request) ?: return@synchronized null
                fun field(name:String):Any? = value.javaClass.getDeclaredField(name).also { it.isAccessible=true }.get(value)
                val backend=field("backend") as? String ?: return@synchronized null
                val reservation=field("reservationId") as? Long ?: return@synchronized null
                val host=field("hostGeneration") as? Long ?: return@synchronized null
                val output=field("outputGeneration") as? Long ?: return@synchronized null
                Route(backend,reservation,host,output)
            }
            fun offerSuccessor() {
                val at=SystemClock.uptimeMillis()
                actual.acceptAccessibilityMetadataForTest(KeyguardAccessibilityEventMeta(
                    AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,-1,Display.DEFAULT_DISPLAY,0,"com.android.systemui",at))
                val pending=actual.inspectionStateForTest().pending
                if(pending!=null) { bId.set(pending.id); records.add("B_OFFER id=${pending.id} at=$at") }
            }
            KeyguardOrbSurfaceWorkerTestHooks.afterRevealCross = { output ->
                if(candidate.get()!=null && bId.get()>0 && bStarted.get()==0L) earlyReveal.incrementAndGet()
                originalCross?.invoke(output)
            }
            instrumentation.runOnMainSync {
                actual.r41R25EvaluationsForTest = r25Evaluations
                actual.inspectionProbeForTest=object:KeyguardInspectionProbeForTest {
                    override fun openingOrderSelected(request:KeyguardCardInspectionRequest, milestoneOrdered:Boolean) {
                        if(milestoneOrdered) orderedReads.add(request.id)
                        records.add("ORDER_SELECTED id=${request.id} milestone=$milestoneOrdered")
                    }
                    override fun started(request:KeyguardCardInspectionRequest) {
                        if (preStart && armed.get() && firstPhysical.compareAndSet(0, request.id)) firstPhysicalStarted.countDown()
                        val count=readers.incrementAndGet(); maxReaders.updateAndGet { maxOf(it,count) }
                        val seq=order.incrementAndGet(); records.add("READ_START id=${request.id} seq=$seq")
                        if(request.id==bId.get() && request.id>0) { bStarted.set(seq); successorStarted.countDown() }
                    }
                    override fun yielded(request:KeyguardCardInspectionRequest, successor:KeyguardCardInspectionRequest, startedAt:Long, finishedAt:Long, visited:Int) { readers.decrementAndGet() }
                    override fun openingChildBefore(request:KeyguardCardInspectionRequest, windowId:Int, index:Int) {
                        if (!duringRead || !armed.get() || candidate.get() != null) return
                        val found=currentRoute(request) ?: return
                        if (found.backend != "R18_DIRECT" || !candidate.compareAndSet(null,request)) return
                        route.set(found); r25Evaluations.set(0)
                        records.add("A_REAL_CHILD_HELD id=${request.id} window=$windowId index=$index route=$found")
                        held.countDown()
                        if (!release.await(20,TimeUnit.SECONDS)) workerTimeout.set(true)
                    }
                    override fun readCompleted(request:KeyguardCardInspectionRequest, decision:KeyguardCardVisibility,
                        reason:KeyguardSurfaceReason, rootUnavailable:Boolean, walkTruncated:Boolean,
                        abortedStale:Boolean, startedAt:Long, finishedAt:Long) {
                        readers.decrementAndGet()
                        if (duringRead && candidate.get()?.id == request.id) {
                            realPositive.set(decision==KeyguardCardVisibility.SHOW_FULL && reason==KeyguardSurfaceReason.MAIN_CONFIRMED &&
                                !rootUnavailable && !walkTruncated && !abortedStale)
                            records.add("A_REAL_READ id=${request.id} result=$decision/$reason unavailable=$rootUnavailable truncated=$walkTruncated stale=$abortedStale")
                            return
                        }
                        if (duringRead) return
                        if(preStart || !armed.get() || decision!=KeyguardCardVisibility.SHOW_FULL || reason!=KeyguardSurfaceReason.MAIN_CONFIRMED ||
                            rootUnavailable || walkTruncated || abortedStale) return
                        val found=currentRoute(request) ?: return
                        if(found.backend!="R18_DIRECT" || !candidate.compareAndSet(null,request)) return
                        r25Evaluations.set(0)
                        route.set(found); records.add("A_HELD id=${request.id} route=$found end=$finishedAt")
                        held.countDown()
                        if(!release.await(20,TimeUnit.SECONDS)) workerTimeout.set(true)
                    }
                    override fun beforeApply(request:KeyguardCardInspectionRequest, decision:KeyguardCardVisibility) {
                        if(request.id==candidate.get()?.id) { originalMain.set(order.incrementAndGet()); records.add("A_MAIN id=${request.id} seq=${originalMain.get()}") }
                    }
                    override fun positiveApplyAttempt(request:KeyguardCardInspectionRequest, decision:KeyguardCardVisibility) {
                        if ((duringRead || afterRead) && request.id == candidate.get()?.id) positivePathEntries.incrementAndGet()
                    }
                    override fun beforeOptionalInspectionReport(request:KeyguardCardInspectionRequest) {
                        if (checkReport && request.id == candidate.get()?.id) {
                            records.add("A_OPTIONAL_REPORT_HELD id=${request.id}")
                            reportHeld.countDown()
                            if (!reportRelease.await(20,TimeUnit.SECONDS)) reportTimeout.set(true)
                        }
                    }
                    override fun afterApply(request:KeyguardCardInspectionRequest, decision:KeyguardCardVisibility) {
                        if(request.id!=candidate.get()?.id) return
                        r25AtAExit.set(r25Evaluations.get())
                        val proof=(gateField.get(actual) as KeyguardFirstAuthorizedOrb).current()
                        if(proof?.requestId==request.id) oldProofAtExit.set(request.id)
                        if(!pendingBefore) offerSuccessor()
                        originalExit.set(order.incrementAndGet()); done.countDown()
                    }
                }
                actual.r25MainDispatchForTest={ request, task ->
                    if(request.id==candidate.get()?.id) r25Posts.incrementAndGet()
                    Handler(Looper.getMainLooper()).post(task)
                }
            }
            if (warmup) {
                // Independent warm-up: retain the real initial fallback or
                // first output, then start a separate unmodified locked wake.
                // This never substitutes a synthetic positive classification.
                shell("input keyevent KEYCODE_SLEEP")
                await("warm-up sleeping") { !power.isInteractive && keyguard.isKeyguardLocked }
                shell("input keyevent KEYCODE_WAKEUP")
                var warmReport = ""
                await("warm-up real first output") {
                    warmReport = KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String
                    val postedAndMoving = Regex(" winner=(?!R18_DIRECT_ATTEMPT/)[A-Z0-9_]+/[0-9]+/[0-9]+(?: |$)")
                    power.isInteractive && keyguard.isKeyguardLocked && warmReport.lineSequence().any {
                        it.startsWith(" R21_CORE ") && postedAndMoving.containsMatchIn(it)
                    }
                }
                File(dir, "warm-up.txt").writeText(warmReport)
                records.add("WARM_UP_FIRST_OUTPUT_RECORDED")
            }
            shell("input keyevent KEYCODE_SLEEP"); await("device sleeping") { !power.isInteractive && keyguard.isKeyguardLocked }
            if (warmup) await("warm-up owner withdrawn") {
                var visible = true
                instrumentation.runOnMainSync { visible = actual.renderModeStatus().visible }
                !visible
            }
            if (preStart) {
                actual.r25ReaderBarrierForTest {
                    preReaderHeld.countDown()
                    if (!preReaderRelease.await(25, TimeUnit.SECONDS)) workerTimeout.set(true)
                }
                assertTrue("NOT REACHED: single physical reader barrier", preReaderHeld.await(10, TimeUnit.SECONDS))
            }
            armed.set(true); shell("input keyevent KEYCODE_WAKEUP")
            if (preStart) {
                var scheduled:KeyguardCardInspectionRequest? = null
                await("adopted empty DIRECT request scheduled before physical read") {
                    synchronized(queueLock) {
                        val queue=queueField.get(actual) as KeyguardCardInspectionQueue
                        val active=queue.activeRequest()
                        if (active != null && emptyDirect.invoke(actual,active) != null) scheduled=active
                        scheduled != null
                    }
                }
                val a=checkNotNull(scheduled)
                val original=checkNotNull(currentRoute(a))
                assertEquals("R18_DIRECT", original.backend)
                assertEquals("NOT REACHED: reader began before release", 0L, firstPhysical.get())
                instrumentation.runOnMainSync { offerSuccessor() }
                val b=bId.get()
                instrumentation.runOnMainSync { offerSuccessor() }
                val c=bId.get()
                assertTrue("NOT REACHED: B and C must be distinct actual offers", c>b && b>a.id)
                assertEquals("NOT REACHED: exact DIRECT owner changed", original, currentRoute(a))
                records.add("PRE_START a=${a.id} b=$b c=$c route=$original aFreshness=${a.windowFreshness}")
                preReaderRelease.countDown()
                assertTrue("NOT REACHED: physical reader did not start", firstPhysicalStarted.await(20,TimeUnit.SECONDS))
                records.add("FIRST_PHYSICAL id=${firstPhysical.get()} expected=$c")
                assertFalse("NOT REACHED: reader barrier timed out", workerTimeout.get())
                assertEquals("R42: the actual latest C must start, before any A or B physical read", c, firstPhysical.get())
                return
            }
            assertTrue("NOT REACHED: complete positive with real DIRECT snapshot",held.await(20,TimeUnit.SECONDS))
            val a=checkNotNull(candidate.get()); val original=checkNotNull(route.get())
            assertEquals("R18_DIRECT",original.backend)
            assertTrue("the real DIRECT read must select the milestone order",orderedReads.contains(a.id))
            assertTrue(original.reservation>0 && original.host>0 && original.output>0)
            assertEquals("NOT REACHED: exact original route changed",original,currentRoute(a))
            if(pendingBefore) instrumentation.runOnMainSync { offerSuccessor() }
            if(duringRead) instrumentation.runOnMainSync { offerSuccessor() }
            if(pendingBefore) {
                assertTrue("NOT REACHED: real B was not queued",bId.get()>a.id)
                assertEquals("NOT REACHED: route changed after offer",original,currentRoute(a))
            } else assertNull("NOT REACHED: stable A already had a pending request",actual.inspectionStateForTest().pending)
            release.countDown()
            assertTrue("NOT REACHED: A did not complete ordered Main",done.await(20,TimeUnit.SECONDS))
            if (duringRead) {
                assertTrue("NOT REACHED: held real tree did not finish complete SHOW_FULL/MAIN_CONFIRMED", realPositive.get())
            }
            if (duringRead || afterRead) {
                records.add("A_POSITIVE_PATH_ENTRIES=${positivePathEntries.get()}")
                assertEquals("R42: obsolete A must exit before positive-only handling",0,positivePathEntries.get())
            }
            assertTrue("NOT REACHED: later B was not queued",bId.get()>a.id)
            if (checkReport) {
                if (!successorStarted.await(8,TimeUnit.SECONDS)) {
                    assertTrue("NOT REACHED: A optional report boundary", reportHeld.await(2,TimeUnit.SECONDS))
                    fail("B did not start while A optional reporting was held")
                }
                assertTrue("NOT REACHED: A optional report boundary", reportHeld.await(10,TimeUnit.SECONDS))
                assertFalse("NOT REACHED: optional report barrier timed out", reportTimeout.get())
                records.add("B_STARTED_BEFORE_A_REPORT_RELEASE")
                reportRelease.countDown()
            } else assertTrue("NOT REACHED: B did not start",successorStarted.await(20,TimeUnit.SECONDS))
            assertTrue("B started before A completed Main",originalMain.get()>0 && originalExit.get()>originalMain.get() && bStarted.get()>originalExit.get())
            assertEquals("the physical reader must remain single-owner",1,maxReaders.get())
            assertEquals("DIRECT A must not post an R25 completed-positive notice",0,r25Posts.get())
            if(pendingBefore) {
                assertEquals("stale A obtained a current proof",0L,oldProofAtExit.get())
                assertEquals("stale A revealed before B started",0,earlyReveal.get())
            }
            assertFalse("NOT REACHED: reader barrier timeout",workerTimeout.get())
            assertEquals("ordered DIRECT must not evaluate the inapplicable R25 route",0L,r25AtAExit.get())
            var report=""
            await("R41 bypass diagnostic for the actual A") {
                report=KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String
                report.lineSequence().any { it.startsWith(" R41_REQ ") && it.contains("req=${a.id} ") &&
                    it.contains("orderedBypassNs=") && !it.contains("orderedBypassNs=UNOBSERVED") }
            }
            File(dir,"capture.txt").writeText(report)
            records.add("PASS a=${a.id} b=${bId.get()} route=$original main=${originalMain.get()}/${originalExit.get()} bStart=${bStarted.get()} earlyReveal=${earlyReveal.get()}")
        } catch(t:Throwable) { failure=t; records.add("FAIL ${t.javaClass.simpleName}:${t.message}") }
        finally {
            release.countDown(); reportRelease.countDown(); preReaderRelease.countDown(); KeyguardOrbSurfaceWorkerTestHooks.afterRevealCross=originalCross
            runCatching { instrumentation.runOnMainSync { service?.inspectionProbeForTest=null; service?.r25MainDispatchForTest=null; service?.r41R25EvaluationsForTest=null } }
            if(capture) runCatching { File(dir,"frozen.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"] as String) }
            runCatching {
                secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,other)
                await("service disconnected") { !FluviKeyguardCardServiceRegistry.connected }
                prefs.forEach(::restore); shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard")
                shell("locksettings set-disabled $savedLock"); secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,savedServices)
                secure(Settings.Secure.ACCESSIBILITY_ENABLED,savedEnabled)
            }.onFailure { if(failure==null) failure=it else records.add("CLEANUP_FAIL ${it.message}") }
            File(dir,"sequence.txt").writeText(synchronized(records) { records.joinToString("\n",postfix="\n") })
            File(dir,"result.txt").writeText("source=$source scenario=$name verdict=${if(failure==null) "PASS" else "FAIL_OR_NOT_REACHED"} physical=UNOBSERVED\n")
        }
        failure?.let { throw it }
    }
}
