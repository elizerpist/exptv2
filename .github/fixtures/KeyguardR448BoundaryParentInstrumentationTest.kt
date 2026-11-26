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
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import java.io.File
import java.util.UUID
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

/** Parent-only observation: actual service and platform wake, without invented
 * classification. A missing early display/read boundary is NOT REACHED. */
@RunWith(AndroidJUnit4::class)
class KeyguardR448BoundaryParentInstrumentationTest {
 @Test fun preScreenReadMustNotConsumeArmedPostScreenObligation() {
  assertEquals(37,Build.VERSION.SDK_INT)
  val ins=InstrumentationRegistry.getInstrumentation(); val context=ins.targetContext
  val ui=ins.getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES)
  fun shell(command:String)=ParcelFileDescriptor.AutoCloseInputStream(ui.executeShellCommand(command)).bufferedReader().use { it.readText() }
  fun secure(key:String,value:String?) { ui.adoptShellPermissionIdentity(Manifest.permission.WRITE_SECURE_SETTINGS); try { check(Settings.Secure.putString(context.contentResolver,key,value)) } finally { ui.dropShellPermissionIdentity() } }
  fun waitFor(label:String, predicate:()->Boolean) { val end=SystemClock.uptimeMillis()+20_000; while(SystemClock.uptimeMillis()<end) { if(predicate())return; SystemClock.sleep(40) }; throw AssertionError("NOT REACHED: $label") }
  fun <T> main(block:()->T):T { val value=AtomicReference<T>(); ins.runOnMainSync { value.set(block()) }; return value.get() }
  fun field(target:Any,name:String):Any?=target.javaClass.getDeclaredField(name).let { it.isAccessible=true; it.get(target) }
  fun start(owner:FluviKeyguardCardService):Map<String,Any?> {
   val done=CountDownLatch(1); val result=AtomicReference<Map<String,Any?>>(); val failure=AtomicReference<Throwable?>()
   ins.runOnMainSync { CoroutineScope(Dispatchers.Main.immediate).launch { try { result.set(owner.startR446PrintCapture("r448-parent-boundary","debug","FULL")) } catch(t:Throwable) { failure.set(t) } finally { done.countDown() } } }
   check(done.await(30,TimeUnit.SECONDS)); failure.get()?.let { throw it }; return checkNotNull(result.get())
  }
  val uuid=UUID.fromString(requireNotNull(InstrumentationRegistry.getArguments().getString("runUuid")))
  val out=File(context.filesDir,"keyguard-service-probe/r43/$uuid").apply { check(mkdirs()) }
  val power=context.getSystemService(PowerManager::class.java); val keyguard=context.getSystemService(KeyguardManager::class.java)
  val savedLock=shell("locksettings get-disabled").trim()
  val savedServices=Settings.Secure.getString(context.contentResolver,Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
  val savedEnabled=Settings.Secure.getString(context.contentResolver,Settings.Secure.ACCESSIBILITY_ENABLED)
  val prefs=context.getSharedPreferences("fluvi_native_keyguard_card",android.content.Context.MODE_PRIVATE); val savedSettings=HashMap(prefs.all)
  val component=ComponentName(context,FluviKeyguardCardService::class.java)
  val early=CountDownLatch(1); val release=CountDownLatch(1); val post=CountDownLatch(1)
  val earlyId=AtomicLong(0); val postId=AtomicLong(0); val screenAt=AtomicLong(0); val unrelated=AtomicInteger(0)
  val note=StringBuilder("applicationIdentity=source.txt actualService=true actualPlatformWake=true syntheticClassification=false controlledEventSubscription=true\n")
  var service:FluviKeyguardCardService?=null
  try {
   shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard"); waitFor("unlocked setup") { !keyguard.isKeyguardLocked }
   main { FluviKeyguardCardSettings.update(context,mapOf("requested" to true,"showFinancialDetails" to true,"presentationMode" to "orb","animationMode" to "orbOnly")) }
   val others=savedServices.orEmpty().split(':').filter { it.isNotBlank() && ComponentName.unflattenFromString(it)!=component }
   secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,(others+component.flattenToString()).joinToString(":")); secure(Settings.Secure.ACCESSIBILITY_ENABLED,"1")
   waitFor("service connected") { FluviKeyguardCardServiceRegistry.connected }
   service=checkNotNull(FluviKeyguardCardServiceRegistry.serviceForInstrumentation()); val owner=checkNotNull(service)
   assertEquals("NOT REACHED: arm receipt",true,start(owner)["printArmed"])
   shell("locksettings set-disabled false"); shell("input keyevent KEYCODE_SLEEP"); waitFor("screen off") { !power.isInteractive }
   owner.inspectionProbeForTest=object:KeyguardInspectionProbeForTest {
    override fun started(request:KeyguardCardInspectionRequest) {
     val now=SystemClock.uptimeMillis(); val boundary=screenAt.get()
     synchronized(note) { note.append("start=${request.id} trigger=${request.trigger} queued=${request.queuedAtUptimeMs} callback=$now boundary=$boundary\n") }
     val actualScreen=field(owner,"r442ScreenOn")
     if(actualScreen==null && earlyId.compareAndSet(0,request.id)) {
      // Controlled queue-only run: remove incidental accessibility event
      // subscriptions before SCREEN_ON. A different source can still open
      // the pre-screen walk; no classifier or system state is fabricated.
      ins.runOnMainSync {
       check(field(owner,"r442ScreenOn")==null) { "NOT REACHED: screen arrived before event suppression" }
       val info=owner.serviceInfo
       val oldTypes=info.eventTypes
       info.eventTypes=0
       owner.serviceInfo=info
       check(owner.serviceInfo.eventTypes==0) { "NOT REACHED: event suppression not accepted" }
       synchronized(note) { note.append("eventSubscriptionBefore=$oldTypes after=${owner.serviceInfo.eventTypes}\n") }
      }
      early.countDown(); check(release.await(20,TimeUnit.SECONDS)) { "NOT REACHED: release early read" }
     } else if(boundary>0 && request.queuedAtUptimeMs>=boundary && postId.compareAndSet(0,request.id)) post.countDown()
    }
    override fun ingress(meta:KeyguardAccessibilityEventMeta, receivedAt:Long, action:KeyguardEventAction, frameworkEvent:Boolean) {
     if(screenAt.get()>0 && postId.get()==0L && frameworkEvent) unrelated.incrementAndGet()
     synchronized(note) { note.append("ingressAt=$receivedAt action=$action framework=$frameworkEvent\n") }
    }
    override fun queueOffered(request:KeyguardCardInspectionRequest, previous:KeyguardCardInspectionRequest?, pending:KeyguardCardInspectionRequest?, startsWorker:Boolean) {
     synchronized(note) { note.append("offer=${request.id} trigger=${request.trigger} queued=${request.queuedAtUptimeMs} pending=${pending?.id} starts=$startsWorker\n") }
    }
    override fun r447SampleReadCompleted(request:KeyguardCardInspectionRequest, eligibility:KeyguardR446Eligibility?, stale:Boolean) {
     synchronized(note) { note.append("sample=${request.id} eligibility=${eligibility?.reason} stale=$stale\n") }
    }
   }
   shell("input keyevent KEYCODE_WAKEUP")
   assertTrue("NOT REACHED: physical read started before SCREEN_ON",early.await(20,TimeUnit.SECONDS))
   waitFor("SCREEN_ON boundary") { field(owner,"r442ScreenOn")!=null }
   val screen=checkNotNull(field(owner,"r442ScreenOn")); screenAt.set(field(screen,"uptime") as Long)
   assertTrue("NOT REACHED: locked current screen",power.isInteractive && keyguard.isKeyguardLocked)
   synchronized(note) { note.append("early=${earlyId.get()} screen=${screenAt.get()}\n") }
   release.countDown()
   val observed=post.await(15,TimeUnit.SECONDS)
   assertEquals("NOT REACHED: unrelated framework ingress",0,unrelated.get())
   assertTrue("RED: no fresh post-SCREEN_ON request without another event",observed)
   synchronized(note) { note.append("post=${postId.get()}\n") }
  } finally {
   release.countDown(); service?.inspectionProbeForTest=null
   if(KeyguardCardDiagnostics.activeCaptureId()!=null) { runCatching { File(out,"r448-parent-report.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"] as String) }; KeyguardCardDiagnostics.clearCapture(context) }
   File(out,"r448-parent-evidence.txt").writeText(synchronized(note) { note.toString() })
   secure(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,savedServices); secure(Settings.Secure.ACCESSIBILITY_ENABLED,savedEnabled)
   shell("input keyevent KEYCODE_WAKEUP"); shell("wm dismiss-keyguard"); if(savedLock.contains("true")) shell("locksettings set-disabled true")
   val edit=prefs.edit().clear(); savedSettings.forEach { (k,v)->when(v) { is Boolean->edit.putBoolean(k,v); is Int->edit.putInt(k,v); is Long->edit.putLong(k,v); is Float->edit.putFloat(k,v); is String->edit.putString(k,v); is Set<*>->edit.putStringSet(k,v.filterIsInstance<String>().toSet()) } }; check(edit.commit())
  }
 }
}
