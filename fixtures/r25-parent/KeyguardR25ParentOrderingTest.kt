package com.fluvi.app.lockscreen

import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Baseline JVM scheduler control. The real window scan and Main application
 * remain separately required device evidence; this test makes queue ownership
 * and the held continuation deterministic without sleeping or blocking Main. */
class KeyguardR25ParentOrderingTest {
    @Test fun completedOpeningDoesNotHoldReaderBehindMain() {
        val queue = KeyguardCardInspectionQueue()
        val lock = Any()
        val reader = Executors.newSingleThreadExecutor()
        val main = LinkedBlockingQueue<Runnable>()
        val readACompleted = CountDownLatch(1)
        val admissionPosted = CountDownLatch(1)
        val readBStarted = CountDownLatch(1)
        val a = request(1)
        val b = request(2)
        try {
            assertTrue(synchronized(lock) { queue.offer(a) })
            reader.execute {
                readACompleted.countDown()
                // Parent processInspectionQueue waits for this Main apply and
                // only then completes A and starts the pending request.
                main.put(Runnable {
                    val next = synchronized(lock) { queue.complete(a) }
                    if (next == b) reader.execute { readBStarted.countDown() }
                })
                admissionPosted.countDown()
            }
            assertTrue("A completed", readACompleted.await(10, TimeUnit.SECONDS))
            assertTrue("A admission posted", admissionPosted.await(10, TimeUnit.SECONDS))
            assertFalse("B is pending on the parent", synchronized(lock) { queue.offer(b) })
            assertEquals(a, synchronized(lock) { queue.activeRequest() })
            assertEquals(b, synchronized(lock) { queue.pendingRequest() })
            // An acknowledged task on the same worker proves all previously
            // queued worker work ran; the test never infers order from sleep.
            reader.submit {}.get(10, TimeUnit.SECONDS)
            assertEquals("B must start before releasing A's Main admission", 0L, readBStarted.count)
        } finally {
            main.poll()?.run()
            reader.shutdown()
            assertTrue("reader cleanup", reader.awaitTermination(10, TimeUnit.SECONDS))
        }
    }

    private fun request(id: Long) = KeyguardCardInspectionRequest(
        id = id, trigger = "window", session = 1, visibilityEpoch = 1,
        interactionEpoch = 1, attachGeneration = 1, wakeGeneration = 1,
        queuedAtUptimeMs = id,
    )
}
