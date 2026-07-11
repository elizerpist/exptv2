package com.exptv2.app

import com.exptv2.app.expense.recurring.ReceiverPendingResultFinisher
import java.io.IOException
import java.util.concurrent.atomic.AtomicReference
import kotlinx.coroutines.CoroutineExceptionHandler
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class AndroidCoroutineLifecycleTest {
    @Test
    fun notificationListenerDestroyCancelsOwnedScope() {
        val controller = Robolectric.buildService(PushNotificationListenerService::class.java)
            .create()
        val service = controller.get()
        val scope = service.lifecycleScope()

        controller.destroy()

        assertFalse(scope.isActive)
    }

    @Test
    fun accessibilityDestroyCancelsOwnedScope() {
        val controller = Robolectric.buildService(PushAccessibilityService::class.java)
            .create()
        val service = controller.get()
        val scope = service.lifecycleScope()

        controller.destroy()

        assertFalse(scope.isActive)
    }

    @Test
    fun cancellingLifecycleScopeCancelsActiveChildren() = runBlocking {
        val scope = LifecycleCoroutineScope(Dispatchers.Unconfined)
        var childFinished = false
        val child = scope.launch {
            try {
                awaitCancellation()
            } finally {
                childFinished = true
            }
        }

        scope.cancel()
        child.join()

        assertTrue(child.isCancelled)
        assertTrue(childFinished)
        assertFalse(scope.isActive)
    }

    @Test
    fun guardedLaunchReportsFailureWithoutCallingUncaughtHandler() = runBlocking {
        val uncaught = AtomicReference<Throwable?>()
        val handler = CoroutineExceptionHandler { _, error -> uncaught.set(error) }
        val scope = LifecycleCoroutineScope(Dispatchers.Unconfined + handler)
        val expected = IOException("repository unavailable")
        var reported: Exception? = null

        val job = scope.launchGuarded(
            reportFailure = { reported = it },
        ) {
            throw expected
        }
        job.join()

        assertSame(expected, reported)
        assertNull(uncaught.get())
        scope.cancel()
    }

    @Test
    fun guardedLaunchContainsFailureReporterExceptions() = runBlocking {
        val uncaught = AtomicReference<Throwable?>()
        val handler = CoroutineExceptionHandler { _, error -> uncaught.set(error) }
        val scope = LifecycleCoroutineScope(Dispatchers.Unconfined + handler)

        val job = scope.launchGuarded(
            reportFailure = { throw IOException("logging unavailable") },
        ) {
            throw IOException("repository unavailable")
        }
        job.join()

        assertNull(uncaught.get())
        scope.cancel()
    }

    @Test
    fun guardedLaunchDoesNotReportLifecycleCancellation() = runBlocking {
        val scope = LifecycleCoroutineScope(Dispatchers.Unconfined)
        var reported: Exception? = null
        val job = scope.launchGuarded(
            reportFailure = { reported = it },
        ) {
            awaitCancellation()
        }

        scope.cancel()
        job.join()

        assertTrue(job.isCancelled)
        assertNull(reported)
    }

    @Test
    fun guardedLaunchAlwaysRunsReceiverFinalizerAfterFailure() = runBlocking {
        val scope = LifecycleCoroutineScope(Dispatchers.Unconfined)
        var finished = false
        val job = scope.launchGuarded(
            reportFailure = {},
            onFinally = {
                finished = true
                scope.cancel()
            },
        ) {
            throw IOException("alarm sync failed")
        }
        job.join()

        assertTrue(finished)
        assertFalse(scope.isActive)
    }

    @Test
    fun receiverFinisherFinishesAndCancelsExactlyOnce() {
        var finishCalls = 0
        var cancelCalls = 0
        val finisher = ReceiverPendingResultFinisher(
            finishPending = { finishCalls += 1 },
            cancelScope = { cancelCalls += 1 },
        )

        finisher.finish()
        finisher.finish()

        assertEquals(1, finishCalls)
        assertEquals(1, cancelCalls)
    }

    @Test
    fun receiverFinisherCancelsScopeWhenPendingFinishThrows() {
        var finishCalls = 0
        var cancelCalls = 0
        val expected = IOException("pending finish failed")
        val finisher = ReceiverPendingResultFinisher(
            finishPending = {
                finishCalls += 1
                throw expected
            },
            cancelScope = { cancelCalls += 1 },
        )

        var thrown: Throwable? = null
        try {
            finisher.finish()
        } catch (error: Throwable) {
            thrown = error
        }
        finisher.finish()

        assertSame(expected, thrown)
        assertEquals(1, finishCalls)
        assertEquals(1, cancelCalls)
    }

    private fun Any.lifecycleScope(): LifecycleCoroutineScope {
        val field = javaClass.getDeclaredField("scope")
        field.isAccessible = true
        return field.get(this) as LifecycleCoroutineScope
    }
}
