package com.fluvi.app.lockscreen

import android.Manifest
import android.app.KeyguardManager
import android.app.UiAutomation
import android.content.ComponentName
import android.os.Build
import android.os.ParcelFileDescriptor
import android.os.PowerManager
import android.os.SystemClock
import android.provider.Settings
import android.view.accessibility.AccessibilityWindowInfo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import java.io.File
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.atomic.AtomicReference
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

/** Parent source is unmodified. This fixture filters only actual windows and
 * invokes the parent's existing private output-ready scheduler. Reflection is
 * observational except for that one actual scheduling request. */
@RunWith(AndroidJUnit4::class)
class KeyguardR447ParentRedInstrumentationTest {
 @Test fun eligibleReadShouldSurviveProvenInternalOffer() {
  assertEquals(37, Build.VERSION.SDK_INT)
  val ins = InstrumentationRegistry.getInstrumentation()
  val context = ins.targetContext
  val ui = ins.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
  fun shell(command: String) = ParcelFileDescriptor.AutoCloseInputStream(ui.executeShellCommand(command)).bufferedReader().use { it.readText() }
  fun secure(key: String, value: String?) {
   ui.adoptShellPermissionIdentity(Manifest.permission.WRITE_SECURE_SETTINGS)
   try { check(Settings.Secure.putString(context.contentResolver, key, value)) } finally { ui.dropShellPermissionIdentity() }
  }
  fun waitFor(label: String, test: () -> Boolean) {
   val until = SystemClock.uptimeMillis() + 20_000
   while (SystemClock.uptimeMillis() < until) { if (test()) return; SystemClock.sleep(50) }
   throw AssertionError("NOT REACHED: $label")
  }
  fun <T> main(block: () -> T): T {
   val result = AtomicReference<T>(); ins.runOnMainSync { result.set(block()) }; return result.get()
  }
  fun start(owner: FluviKeyguardCardService): Map<String, Any?> {
   val done=CountDownLatch(1); val result=AtomicReference<Map<String, Any?>>(); val failure=AtomicReference<Throwable?>()
   ins.runOnMainSync { CoroutineScope(Dispatchers.Main.immediate).launch {
    try { result.set(owner.startR446PrintCapture("r447-parent-red", "debug", "FULL")) }
    catch (error: Throwable) { failure.set(error) } finally { done.countDown() }
   } }
   check(done.await(30, TimeUnit.SECONDS)) { "NOT REACHED: arm receipt" }
   failure.get()?.let { throw it }; return checkNotNull(result.get())
  }
  fun field(target: Any, name: String): Any? = target.javaClass.getDeclaredField(name).let { it.isAccessible=true; it.get(target) }
  val uuid=UUID.fromString(requireNotNull(InstrumentationRegistry.getArguments().getString("runUuid")))
  val out=File(context.filesDir,"keyguard-service-probe/r43/$uuid").apply { check(mkdirs()) }
  val power=context.getSystemService(PowerManager::class.java)
  val keyguard=context.getSystemService(KeyguardManager::class.java)
  val savedLock=shell("locksettings get-disabled").trim()
  val savedServices=Settings.Secure.getString(context.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
  val savedEnabled=Settings.Secure.getString(context.contentResolver, Settings.Secure.ACCESSIBILITY_ENABLED)
  val prefs=context.getSharedPreferences("fluvi_native_keyguard_card", android.content.Context.MODE_PRIVATE)
  val savedSettings=HashMap(prefs.all)
  val component=ComponentName(context, FluviKeyguardCardService::class.java)
  val acquired=CountDownLatch(1); val release=CountDownLatch(1); val applied=CountDownLatch(1)
  val first=AtomicLong(0); val offered=AtomicLong(0); val ingresses=AtomicInteger(0)
  val hosts=ConcurrentHashMap<Long, Int>()
  val note=StringBuilder("parent=398a5389 controlled=subset-of-real-inventory reflection=existing-scheduler stock=false physical=UNOBSERVED\n")
  var service: FluviKeyguardCardService?=null
  try {
   shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard")
   waitFor("unlocked setup") { !keyguard.isKeyguardLocked }
   main { FluviKeyguardCardSettings.update(context, mapOf("requested" to true, "showFinancialDetails" to true,
    "presentationMode" to "orb", "animationMode" to "orbOnly")) }
   val others=savedServices.orEmpty().split(':').filter { it.isNotBlank() && ComponentName.unflattenFromString(it)!=component }
   secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,(others+component.flattenToString()).joinToString(":"))
   secure(Settings.Secure.ACCESSIBILITY_ENABLED,"1")
   waitFor("service connected") { FluviKeyguardCardServiceRegistry.connected }
   service=checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation()); val owner=checkNotNull(service)
   assertEquals("NOT REACHED: armed input-ready presenter",true,start(owner)["printArmed"])
   val parentSeq=checkNotNull(field(owner,"firstAuthorizedOrb")) as KeyguardFirstAuthorizedOrb
   val parentLock=checkNotNull(field(owner,"queueLock"))
   val parentQueue=checkNotNull(field(owner,"inspectionQueue")) as KeyguardCardInspectionQueue
   owner.inspectionProbeForTest=object: KeyguardInspectionProbeForTest {
    override fun snapshots(request: KeyguardCardInspectionRequest, actual: List<KeyguardWindowSnapshot>): List<KeyguardWindowSnapshot> {
     val selected=actual.filter { it.packageName=="com.android.systemui" && it.type==AccessibilityWindowInfo.TYPE_SYSTEM &&
      it.displayId==0 && it.r444Active==true && it.r444Focused==true && it.r44?.active==true &&
      it.r44.verifiedRoot && it.r44.complete && !it.r44.foreignNode && it.r446Bounds?.valid==true }
     if (selected.size==1) hosts[request.id]=selected.single().windowId
     synchronized(note) { note.append("req=${request.id} actual=${actual.size} realHosts=${selected.size}\n") }
     return if (selected.size==1) selected else actual
    }
    override fun readCompleted(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility,
      reason: KeyguardSurfaceReason, rootUnavailable: Boolean, walkTruncated: Boolean,
      abortedStale: Boolean, startedAt: Long, finishedAt: Long) {
     synchronized(note) { note.append("read=${request.id} decision=$decision reason=$reason unavailable=$rootUnavailable truncated=$walkTruncated stale=$abortedStale\n") }
     val isLatest=synchronized(parentLock) {
      field(parentSeq,"newestRead")==request.id && field(parentSeq,"newestRequiredRead")==request.id && parentQueue.pendingRequest()==null
     }
     if (hosts.containsKey(request.id) && !rootUnavailable && !walkTruncated && !abortedStale && isLatest && first.compareAndSet(0,request.id)) {
      acquired.countDown(); check(release.await(20,TimeUnit.SECONDS)) { "NOT REACHED: release held completed read" }
     }
    }
    override fun ingress(meta: KeyguardAccessibilityEventMeta, receivedAt: Long, action: KeyguardEventAction, frameworkEvent: Boolean) {
     if (first.get()>0 && applied.count>0) ingresses.incrementAndGet()
    }
    override fun queueOffered(request: KeyguardCardInspectionRequest, previous: KeyguardCardInspectionRequest?, pending: KeyguardCardInspectionRequest?, startsWorker: Boolean) {
     if (request.trigger=="r18Ready" && first.get()>0) offered.compareAndSet(0,request.id)
    }
    override fun afterApply(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility) {
     if (request.id==first.get()) applied.countDown()
    }
   }
   shell("locksettings set-disabled false"); shell("input keyevent KEYCODE_SLEEP")
   waitFor("screen off") { !power.isInteractive }
   shell("input keyevent KEYCODE_WAKEUP")
   waitFor("real lockscreen") { power.isInteractive && keyguard.isKeyguardLocked }
   assertTrue("NOT REACHED: complete physical reader/Main boundary",acquired.await(20,TimeUnit.SECONDS))
   val sampler=checkNotNull(field(owner,"systemSampler"))
   waitFor("sampler idle") { main { field(sampler,"active")==null && field(sampler,"pending")==null && field(sampler,"delivering")==false } }
   fun order(): Triple<Long,Long,Long> = synchronized(parentLock) {
    Triple(field(parentSeq,"newestRead") as Long, field(parentSeq,"newestRequiredRead") as Long, parentSeq.sceneSerial())
   }
   val before=main { Pair(owner.inspectionStateForTest(),order()) }
   assertEquals("NOT REACHED: first read completed",first.get(),before.second.first)
   assertEquals("NOT REACHED: no earlier read obligation",first.get(),before.second.second)
   assertNull("NOT REACHED: queue initially empty",before.first.pending)
   assertEquals("NOT REACHED: no intervening ingress",0,ingresses.get())
   main {
    val m=owner.javaClass.declaredMethods.single { it.name=="requestSystemCheck" && it.parameterCount==10 }
    m.isAccessible=true
    m.invoke(owner,"r18Ready",SystemClock.uptimeMillis(),true,null,false,KeyguardWindowFreshness.FRAMEWORK_EVENT,null,null,null,0L)
   }
   waitFor("real internal output-ready successor queued") { offered.get()>first.get() }
   val after=main { Pair(owner.inspectionStateForTest(),order()) }
   synchronized(note) { note.append("first=${first.get()} successor=${offered.get()} before=$before after=$after ingresses=${ingresses.get()}\n") }
   assertEquals("NOT REACHED: same authority",before.first.authority,after.first.authority)
   assertEquals("NOT REACHED: same scene",before.second.third,after.second.third)
   assertEquals("NOT REACHED: newest completed remains A",first.get(),after.second.first)
   assertEquals("NOT REACHED: newest required is B",offered.get(),after.second.second)
   assertEquals("NOT REACHED: B pending",offered.get(),after.first.pending?.id)
   assertEquals("NOT REACHED: no real ingress",0,ingresses.get())
   release.countDown()
   assertTrue("NOT REACHED: A Main application",applied.await(20,TimeUnit.SECONDS))
   assertEquals("NOT REACHED: no ingress before A Main",0,ingresses.get())
   val report=AtomicReference<String>()
   waitFor("A eligibility exported") {
    val row=(KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String).lineSequence().firstOrNull {
     it.startsWith("R44_6_SAMPLE ") && it.contains("firstReq=${first.get()}") && it.contains("firstEligible=ELIGIBLE_SAMPLE") }
    if (row!=null) { report.set(row); true } else false
   }
   synchronized(note) { note.append("A_REPORT=${report.get()}\n") }
   assertFalse("RED: eligible A should issue despite proven identical internal offer",report.get().contains("firstBackend=NOT_ATTEMPTED"))
  } finally {
   release.countDown(); service?.inspectionProbeForTest=null
   if (KeyguardCardDiagnostics.activeCaptureId()!=null) {
    runCatching { File(out,"r447-parent-report.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"] as String) }
    KeyguardCardDiagnostics.clearCapture(context)
   }
   File(out,"r447-parent-evidence.txt").writeText(synchronized(note) { note.toString() })
   secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,savedServices); secure(Settings.Secure.ACCESSIBILITY_ENABLED,savedEnabled)
   shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard")
   if (savedLock.contains("true")) shell("locksettings set-disabled true")
   val edit=prefs.edit().clear()
   savedSettings.forEach { (key,value) -> when(value) {
    is Boolean -> edit.putBoolean(key,value); is Int -> edit.putInt(key,value); is Long -> edit.putLong(key,value)
    is Float -> edit.putFloat(key,value); is String -> edit.putString(key,value)
    is Set<*> -> edit.putStringSet(key,value.filterIsInstance<String>().toSet())
   } }
   check(edit.commit())
  }
 }
}
