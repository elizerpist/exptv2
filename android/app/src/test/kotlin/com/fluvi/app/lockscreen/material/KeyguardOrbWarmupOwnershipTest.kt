package com.fluvi.app.lockscreen.material

import android.os.Looper
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.LooperMode

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], manifest = Config.NONE)
@LooperMode(LooperMode.Mode.PAUSED)
class KeyguardOrbWarmupOwnershipTest {
    private val context get() = RuntimeEnvironment.getApplication()
    private fun artifact(effect: String, portal: Boolean) = KeyguardShaderArtifact(effect, portal, "test",
        KeyguardHeaderShader.Metadata("source", "hash", "9"))
    private fun pumpUntil(message: String, condition: () -> Boolean) {
        val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(5)
        while (!condition() && System.nanoTime() < deadline) {
            shadowOf(Looper.getMainLooper()).idle()
            Thread.sleep(5)
        }
        shadowOf(Looper.getMainLooper()).idle()
        assertTrue(message, condition())
    }

    @Test fun retirementClosesTheStoreAndReportsOnlyAfterItsRealReadSettles() {
        val entered = CountDownLatch(1); val release = CountDownLatch(1)
        val callbacks = AtomicInteger(); val settled = AtomicInteger()
        val store = KeyguardShaderArtifactStore(context, KeyguardShaderArtifactReader { _, effect, portal ->
            entered.countDown(); check(release.await(5, TimeUnit.SECONDS)); artifact(effect, portal)
        })
        try {
            store.prepare("dualTide", false) { callbacks.incrementAndGet() }
            assertTrue(entered.await(5, TimeUnit.SECONDS))
            store.retireWhenSettled { settled.incrementAndGet() }
            shadowOf(Looper.getMainLooper()).idle()
            assertEquals("retirement cannot report drain during active I/O", 0, settled.get())
            release.countDown()
            pumpUntil("retired store never settled") { settled.get() == 1 }
            assertEquals(0, callbacks.get())
            assertEquals(0, store.diagnostics().cachedArtifactCount)
            assertEquals(0, store.diagnostics().pendingPreparationCount)
        } finally { release.countDown(); store.dispose() }
    }

    @Test fun replacedAToBToAUsesOnlyLatestOwnerAndNeverOverlapsLoads() {
        val firstEntered = CountDownLatch(1); val releaseFirst = CountDownLatch(1)
        val loads = AtomicInteger(); val active = AtomicInteger(); val maxActive = AtomicInteger()
        val accepted = mutableListOf<KeyguardOrbSurfaceTarget>()
        val reader = KeyguardShaderArtifactReader { _, effect, portal ->
            val concurrency = active.incrementAndGet()
            maxActive.updateAndGet { maxOf(it, concurrency) }
            try {
                if (loads.incrementAndGet() == 1) {
                    firstEntered.countDown(); check(releaseFirst.await(5, TimeUnit.SECONDS))
                }
                artifact(effect, portal)
            } finally { active.decrementAndGet() }
        }
        val manager = KeyguardOrbDirectProgramWarmup(context,
            submit = { target, _, _, current -> if (current()) accepted += target },
            newStore = { _ -> KeyguardShaderArtifactStore(context, reader) })
        fun target(generation: Long) = KeyguardOrbSurfaceTarget(1, generation, null, 1, 1, 1, true, true)
        val a = target(1); val b = target(2); val again = target(3)
        val selectorA = KeyguardOrbProgramSelector("dualTide", false)
        val selectorB = KeyguardOrbProgramSelector("magneticMembrane", false)
        try {
            manager.request(a, selectorA) { !a.revoked }
            assertTrue(firstEntered.await(5, TimeUnit.SECONDS))
            a.revoked = true; manager.retire(a); shadowOf(Looper.getMainLooper()).idle()
            manager.request(b, selectorB) { !b.revoked }
            b.revoked = true; manager.retire(b); shadowOf(Looper.getMainLooper()).idle()
            manager.request(again, selectorA) { !again.revoked }
            assertEquals("the pending owner cannot start a concurrent load", 1, loads.get())
            releaseFirst.countDown()
            pumpUntil("latest owner did not receive its own artifact") { accepted.size == 1 }
            assertSame(again, accepted.single())
            assertEquals(2, loads.get())
            assertEquals(1, maxActive.get())
        } finally { releaseFirst.countDown(); manager.dispose() }
    }
}
