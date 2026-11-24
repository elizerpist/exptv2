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

    private data class Route(val backend:String, val reservation:Long, val host:Long, val output:Long)
    private fun exercise(pendingBefore:Boolean, checkR41Bypass:Boolean = false) {
        assertEquals(35, Build.VERSION.SDK_INT)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        val args = InstrumentationRegistry.getArguments()
        val source = requireNotNull(args.getString("sourceSha"))
        require(source.matches(Regex("[0-9a-f]{40}")))
        val uuid = UUID.fromString(requireNotNull(args.getString("runUuid"))).toString()
        val name = if (checkR41Bypass) "r41-pending" else if (pendingBefore) "pending" else "stable-later-offer"
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
        val originalMain=AtomicLong(0); val originalExit=AtomicLong(0); val bStarted=AtomicLong(0); val bId=AtomicLong(0)
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
                        val count=readers.incrementAndGet(); maxReaders.updateAndGet { maxOf(it,count) }
                        val seq=order.incrementAndGet(); records.add("READ_START id=${request.id} seq=$seq")
                        if(request.id==bId.get() && request.id>0) { bStarted.set(seq); successorStarted.countDown() }
                    }
                    override fun yielded(request:KeyguardCardInspectionRequest, successor:KeyguardCardInspectionRequest, startedAt:Long, finishedAt:Long, visited:Int) { readers.decrementAndGet() }
                    override fun readCompleted(request:KeyguardCardInspectionRequest, decision:KeyguardCardVisibility,
                        reason:KeyguardSurfaceReason, rootUnavailable:Boolean, walkTruncated:Boolean,
                        abortedStale:Boolean, startedAt:Long, finishedAt:Long) {
                        readers.decrementAndGet()
                        if(!armed.get() || decision!=KeyguardCardVisibility.SHOW_FULL || reason!=KeyguardSurfaceReason.MAIN_CONFIRMED ||
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
            shell("input keyevent KEYCODE_SLEEP"); await("device sleeping") { !power.isInteractive && keyguard.isKeyguardLocked }
            armed.set(true); shell("input keyevent KEYCODE_WAKEUP")
            assertTrue("NOT REACHED: complete positive with real DIRECT snapshot",held.await(20,TimeUnit.SECONDS))
            val a=checkNotNull(candidate.get()); val original=checkNotNull(route.get())
            assertEquals("R18_DIRECT",original.backend)
            assertTrue("the real DIRECT read must select the milestone order",orderedReads.contains(a.id))
            assertTrue(original.reservation>0 && original.host>0 && original.output>0)
            assertEquals("NOT REACHED: exact original route changed",original,currentRoute(a))
            if(pendingBefore) instrumentation.runOnMainSync { offerSuccessor() }
            if(pendingBefore) {
                assertTrue("NOT REACHED: real B was not queued",bId.get()>a.id)
                assertEquals("NOT REACHED: route changed after offer",original,currentRoute(a))
            } else assertNull("NOT REACHED: stable A already had a pending request",actual.inspectionStateForTest().pending)
            release.countDown()
            assertTrue("NOT REACHED: A did not complete ordered Main",done.await(20,TimeUnit.SECONDS))
            assertTrue("NOT REACHED: later B was not queued",bId.get()>a.id)
            assertTrue("NOT REACHED: B did not start",successorStarted.await(20,TimeUnit.SECONDS))
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
            release.countDown(); KeyguardOrbSurfaceWorkerTestHooks.afterRevealCross=originalCross
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
