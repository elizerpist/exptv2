package com.fluvi.app.lockscreen.host

import android.app.KeyguardManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.Parcel
import android.os.Process
import android.os.SystemClock
import android.provider.Settings
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.fluvi.app.lockscreen.FluviKeyguardCardSettings
import com.fluvi.app.lockscreen.KeyguardR12ServiceTimingInstrumentationTest
import com.fluvi.app.lockscreen.material.FluviKeyguardMaterialStore
import com.fluvi.app.runtime.FluviLockScreenCardCoordinator
import com.fluvi.core.FluviCoreFactory
import com.fluvi.r29.contract.R29WireCodec
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executor
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference
import kotlinx.coroutines.runBlocking
import org.junit.Assert.*
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Demo-only, separate-process publication control. Its offscreen buffer is not
 * a primary lockscreen frame and cannot establish the physical 10 ms target.
 */
@RunWith(AndroidJUnit4::class)
class R35ResidentPublisherInstrumentationTest {
    private class MemoryStore : R29Ownership.Store {
        private var value = R29Ownership.Persisted(false, 0)
        override fun read() = value
        override fun write(value: R29Ownership.Persisted): Boolean { this.value = value; return true }
    }
    private data class Probe(val pid: Int, val nonce: String?, val sequence: Long, val digest: String?, val pixels: Int)

    @Test fun actualMaterialStorePublishesChangedImagesToSeparateDemoProcessAndReceivesEmpty() = runBlocking {
        assumeTrue("Disposable API 35 emulator only", Build.VERSION.SDK_INT >= 35 &&
            (Build.FINGERPRINT.contains("generic") || Build.HARDWARE.contains("ranchu")))
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        assumeTrue("Fixture must start unlocked", context.getSystemService(KeyguardManager::class.java)?.isKeyguardLocked == false)
        val settingsPrefs = context.getSharedPreferences("fluvi_native_keyguard_card", Context.MODE_PRIVATE)
        val profilePrefs = context.getSharedPreferences("fluvi_keyguard_header_material", Context.MODE_PRIVATE)
        val savedSettings = HashMap(settingsPrefs.all)
        val savedProfile = HashMap(profilePrefs.all)
        val resolver = context.contentResolver
        val previousServices = Settings.Secure.getString(resolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        val previousEnabled = Settings.Secure.getInt(resolver, Settings.Secure.ACCESSIBILITY_ENABLED, 0)
        val component = ComponentName(context, R35DebugResidentService::class.java)
        val ready = LinkedBlockingQueue<Pair<String, Long>>()
        val empty = LinkedBlockingQueue<Triple<String, Long, Long>>()
        val connected = CountDownLatch(1)
        val serviceBound = CountDownLatch(1)
        val probeBinder = AtomicReference<IBinder>()
        val connection = object : ServiceConnection {
            override fun onServiceConnected(name: ComponentName, service: IBinder) {
                probeBinder.set(service)
                serviceBound.countDown()
            }
            override fun onServiceDisconnected(name: ComponentName) { probeBinder.set(null) }
        }
        var publisher: R35ResidentPublisher? = null
        var bound = false
        val automation = instrumentation.uiAutomation
        automation.adoptShellPermissionIdentity("android.permission.WRITE_SECURE_SETTINGS")
        try {
            assertTrue(Settings.Secure.putString(resolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
                "com.fluvi.app/com.fluvi.app.lockscreen.FluviKeyguardCardService"))
            assertTrue(Settings.Secure.putInt(resolver, Settings.Secure.ACCESSIBILITY_ENABLED, 1))
            assertTrue(FluviKeyguardCardSettings.systemServiceEnabled(context))
            val core = FluviCoreFactory.create(context)
            val categories = try { core.demoSeed.seed(); core.categories.list() } finally { core.close() }
            var found = false
            for (category in categories) {
                val settings = FluviKeyguardCardSettings.update(context, mapOf(
                    "requested" to true, "showFinancialDetails" to true, "presentationMode" to "orb",
                    "focus" to mapOf("mode" to "budget", "timeAxis" to "month", "direction" to "expense",
                        "categoryId" to category.id),
                ))
                val target = FluviLockScreenCardCoordinator.materialSceneTarget(context, settings.focus.asFinancialFocus())
                if (target.projectionAvailable && target.coreRevision != null && target.remainingPercent != null &&
                    target.categoryColorId != null) { found = true; break }
            }
            assertTrue("Seeded category with an actual current Budget projection required", found)
            profilePrefs.edit().clear().commit()
            bound = context.bindService(Intent().setComponent(component), connection, Context.BIND_AUTO_CREATE)
            assertTrue(bound)
            assertTrue("debug receiver did not bind", serviceBound.await(10, TimeUnit.SECONDS))
            val binder = requireNotNull(probeBinder.get())
            val owner = R29Ownership(MemoryStore())
            val epoch = requireNotNull(owner.beginEnrollment())
            // This is a disposable fixture with no locked-screen output, not a
            // production proof that the real overlay has drained.
            assertTrue(owner.oldOwnerDrained(epoch))
            val main = Executor { command -> Handler(Looper.getMainLooper()).post(command) }
            publisher = R35ResidentPublisher(context, owner, main, object : R35ResidentPublisher.Listener {
                override fun onConnected(session: String, epoch: Long) { connected.countDown() }
                override fun onReady(session: String, sequence: Long) { ready.offer(session to sequence) }
                override fun onUnavailable() = Unit
                override fun onEmpty(session: String, sequence: Long, epoch: Long) { empty.offer(Triple(session, sequence, epoch)) }
            }, component)
            publisher.connectAfterDrain(epoch)
            assertTrue("verified test session did not install the producer", connected.await(15, TimeUnit.SECONDS))
            val firstEvidence = publishProfile(context, 1, listOf(0xff104f7c.toInt(), 0xff62c7dc.toInt()))
            if (InstrumentationRegistry.getArguments().getString("r35ParentFixture") == "true") {
                // Parent-only fixture precondition: seed A using the same
                // staged transport. B must use the unchanged real store path.
                println("R35_PARENT_FIXTURE: A seeded explicitly; B uses unchanged production store")
                R35MaterialPublication.inputsChanging()
                R35MaterialPublication.profileAccepted(requireNotNull(FluviKeyguardMaterialStore.read(context)), firstEvidence)
            }
            val a = requireNotNull(ready.poll(35, TimeUnit.SECONDS)) { "A never reached independently prepared READY" }
            val imageA = waitForProbe(binder) { it.nonce == a.first && it.sequence == a.second && it.pixels > 0 }
            println("R35_DEMO_A sequence=${a.second} receiverPid=${imageA.pid} changedPixels=${imageA.pixels} sha256=${imageA.digest}")
            assertNotEquals("receiver must be a separate process", Process.myPid(), imageA.pid)
            publishProfile(context, 2, listOf(0xfff1414b.toInt(), 0xffe4c048.toInt()))
            val storedB = requireNotNull(FluviKeyguardMaterialStore.read(context))
            assertEquals("r35-instrumentation", storedB.publisherSession)
            assertEquals(2L, storedB.publisherRevision)
            println("R35_DEMO_B_ATTEMPT storedRevision=${storedB.publisherRevision}")
            val nextReady = ready.poll(35, TimeUnit.SECONDS)
            if (nextReady == null && InstrumentationRegistry.getArguments().getString("r35ParentFixture") == "true") {
                // A useful parent RED requires a live receiver still showing
                // the same acknowledged A after the real B store accepted it.
                assertTrue("receiver died before B could be checked", binder.pingBinder())
                val afterB = requireNotNull(probe(binder))
                assertEquals(imageA.pid, afterB.pid)
                assertEquals(a.first, afterB.nonce)
                assertEquals(a.second, afterB.sequence)
                assertEquals(imageA.digest, afterB.digest)
                assertTrue(afterB.pixels > 0)
                println("R35_PARENT_B_NO_READY storedRevision=2 receiverPid=${afterB.pid} retainedSequence=${afterB.sequence} changedPixels=${afterB.pixels} sha256=${afterB.digest}")
            }
            val b = requireNotNull(nextReady) { "B never reached independently prepared READY" }
            assertEquals(a.first, b.first)
            assertTrue(b.second > a.second)
            val imageB = waitForProbe(binder) { it.nonce == b.first && it.sequence == b.second && it.pixels > 0 }
            println("R35_DEMO_B sequence=${b.second} receiverPid=${imageB.pid} changedPixels=${imageB.pixels} sha256=${imageB.digest}")
            assertNotEquals("changed configured palette must change the rendered image", imageA.digest, imageB.digest)
            FluviKeyguardCardSettings.update(context, mapOf("showFinancialDetails" to false))
            waitForProbe(binder) { it.pixels == 0 }
            assertTrue(publisher.requestEmpty())
            val receipt = requireNotNull(empty.poll(15, TimeUnit.SECONDS)) { "test output did not produce EMPTY" }
            assertEquals(b.first, receipt.first)
            assertEquals(epoch, receipt.third)
            assertTrue(owner.appMayShow())
            val last = waitForProbe(binder) { it.nonce == receipt.first && it.sequence == receipt.second && it.pixels == 0 }
            println("R35_DEMO_EMPTY sequence=${receipt.second} receiverPid=${last.pid} changedPixels=${last.pixels} sha256=${last.digest}")
            assertEquals(imageB.pid, last.pid)
        } finally {
            publisher?.close()
            if (bound) context.unbindService(connection)
            restore(settingsPrefs, savedSettings)
            restore(profilePrefs, savedProfile)
            Settings.Secure.putString(resolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, previousServices)
            Settings.Secure.putInt(resolver, Settings.Secure.ACCESSIBILITY_ENABLED, previousEnabled)
            automation.dropShellPermissionIdentity()
        }
    }

    private suspend fun publishProfile(context: Context, revision: Long, colors: List<Int>): Map<String, Any> {
        val settings = FluviKeyguardCardSettings.read(context)
        val target = FluviLockScreenCardCoordinator.materialSceneTarget(context, settings.focus.asFinancialFocus())
        val core = FluviCoreFactory.create(context)
        val current = try { core.query.currentCoreRevision() } finally { core.close() }
        assertEquals(target.coreRevision, current)
        val profile = KeyguardR12ServiceTimingInstrumentationTest().materialProfile().toMutableMap()
        profile["publisherSession"] = "r35-instrumentation"
        profile["publisherRevision"] = revision
        profile["sceneIdentity"] = listOf(target.mode.name, target.timeAxis.name, target.direction.name,
            target.categoryId, target.focusGeneration).joinToString("|")
        profile["colors"] = colors
        profile["stops"] = listOf(0.0, 1.0)
        val evidence = mapOf("targetCoreRevision" to current, "visualCoreRevision" to current,
            "currentCoreRevision" to current, "focusGeneration" to settings.focus.generation,
            "layoutRevision" to settings.layoutRevision, "privacyRevision" to settings.generation,
            "visualProjectionFull" to true)
        profile["r29Evidence"] = evidence
        assertTrue(FluviKeyguardMaterialStore.publish(context, profile, 1L))
        return evidence
    }

    private fun probe(binder: IBinder, code: Int = R35DebugResidentService.PROBE): Probe? {
        val data = Parcel.obtain()
        val reply = Parcel.obtain()
        return try {
            data.writeInterfaceToken(R29WireCodec.INTERFACE)
            check(binder.transact(code, data, reply, 0))
            reply.readException()
            if (code == R35DebugResidentService.PROBE) Probe(reply.readInt(), reply.readString(), reply.readLong(),
                reply.readString(), reply.readInt()) else null
        } finally { data.recycle(); reply.recycle() }
    }

    private fun waitForProbe(binder: IBinder, condition: (Probe) -> Boolean): Probe {
        var last: Probe? = null
        waitFor("rendered demo buffer") {
            last = probe(binder)
            last?.let(condition) == true
        }
        return requireNotNull(last)
    }

    private fun waitFor(label: String, condition: () -> Boolean) {
        val deadline = SystemClock.elapsedRealtime() + 20_000
        while (SystemClock.elapsedRealtime() < deadline) {
            if (condition()) return
            Thread.sleep(50)
        }
        fail("Timed out waiting for $label")
    }

    private fun restore(prefs: android.content.SharedPreferences, values: Map<String, *>) {
        val edit = prefs.edit().clear()
        values.forEach { (key, value) -> when (value) {
            is Boolean -> edit.putBoolean(key, value)
            is Int -> edit.putInt(key, value)
            is Long -> edit.putLong(key, value)
            is Float -> edit.putFloat(key, value)
            is String -> edit.putString(key, value)
            is Set<*> -> edit.putStringSet(key, value.filterIsInstance<String>().toSet())
        } }
        check(edit.commit())
    }
}
