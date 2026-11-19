package com.fluvi.app.lockscreen.material

import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Assert.assertEquals
import org.junit.Test

/** Host-side ownership controls only; actual SurfaceHolder, compositor and
 * accessibility-service behavior require the API 35 instrumentation. */
class KeyguardOrbSurfaceAccessGateTest {
    @Test fun revokeDoesNotWaitButDestroyDrainsAnEnteredHolderOperation() {
        val gate = KeyguardOrbSurfaceAccessGate()
        assertTrue(gate.tryEnter())
        val pool = Executors.newSingleThreadExecutor()
        val destroyEntered = CountDownLatch(1)
        val destroyReturned = CountDownLatch(1)
        var left = false
        try {
            gate.revoke()
            assertFalse(gate.tryEnter())
            pool.submit {
                destroyEntered.countDown()
                gate.destroyAndAwait()
                destroyReturned.countDown()
            }
            assertTrue(destroyEntered.await(2, TimeUnit.SECONDS))
            assertFalse("surfaceDestroyed cannot return while a holder call remains entered",
                destroyReturned.await(100, TimeUnit.MILLISECONDS))
            gate.leave()
            left = true
            assertTrue(destroyReturned.await(2, TimeUnit.SECONDS))
            assertFalse(gate.tryEnter())
        } finally {
            gate.revoke()
            if (!left) gate.leave()
            pool.shutdownNow()
        }
    }

    @Test fun oldGenerationRevocationCannotRevokeItsReplacement() {
        val old = KeyguardOrbSurfaceAccessGate()
        val current = KeyguardOrbSurfaceAccessGate()
        old.revoke()
        old.destroyAndAwait()
        assertFalse(old.tryEnter())
        assertTrue(current.tryEnter())
        current.leave()
        current.destroyAndAwait()
        assertFalse(current.tryEnter())
    }

    @Test fun redrawAcknowledgementIsCompletedExactlyOnce() {
        val callbacks = AtomicInteger()
        val completion = KeyguardOrbSurfaceRedrawCompletion { callbacks.incrementAndGet() }
        completion.complete()
        completion.complete()
        assertEquals(1, callbacks.get())
    }
}
