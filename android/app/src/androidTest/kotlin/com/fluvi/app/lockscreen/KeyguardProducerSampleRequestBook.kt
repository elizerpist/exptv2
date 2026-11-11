package com.fluvi.app.lockscreen

import com.fluvi.app.lockscreen.material.KeyguardOrbBufferLease
import com.fluvi.app.lockscreen.material.KeyguardOrbBufferProducerFrame
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.atomic.AtomicReference
import kotlin.math.abs

/**
 * Test-only acknowledgement ownership for producer readback. A numeric phase
 * describes a frame but is deliberately not a request identity: equal A1 and
 * A2 phases must still be independently acknowledged.
 */
internal class KeyguardProducerSampleRequestBook<T : Any> {
    class Request<T : Any> internal constructor(
        val requestId: Long,
        val expectedLease: KeyguardOrbBufferLease,
        val expectedPhase: Float,
    ) {
        private val completed = CountDownLatch(1)
        private val resolved = AtomicBoolean(false)
        private val result = AtomicReference<T?>(null)
        private val failure = AtomicReference<Throwable?>(null)

        internal fun complete(value: T) {
            if (resolved.compareAndSet(false, true)) {
                result.set(value)
                completed.countDown()
            }
        }

        internal fun fail(error: Throwable) {
            if (resolved.compareAndSet(false, true)) {
                failure.set(error)
                completed.countDown()
            }
        }

        internal fun await(timeoutMs: Long): T {
            if (!completed.await(timeoutMs, TimeUnit.MILLISECONDS)) {
                throw AssertionError(
                    "producer did not reach request=$requestId phase=$expectedPhase " +
                        "lease=${expectedLease.attachment}/${expectedLease.generation}",
                )
            }
            failure.get()?.let { throw AssertionError("producer readback failed for request=$requestId", it) }
            return requireNotNull(result.get()) { "request=$requestId completed without a result" }
        }
    }

    private val nextRequestId = AtomicLong(0L)
    private val pending = AtomicReference<Request<T>?>(null)

    fun arm(lease: KeyguardOrbBufferLease, phase: Float): Request<T> {
        require(lease.attachment != 0L) { "producer request requires a current lease" }
        val request = Request<T>(nextRequestId.incrementAndGet(), lease, phase)
        check(pending.compareAndSet(null, request)) { "a producer request is already pending" }
        return request
    }

    /** Replaces only the exact currently pending request. */
    fun supersede(expected: Request<T>, lease: KeyguardOrbBufferLease, phase: Float): Request<T> {
        val replacement = Request<T>(nextRequestId.incrementAndGet(), lease, phase)
        check(pending.compareAndSet(expected, replacement)) { "request=${expected.requestId} is no longer pending" }
        expected.fail(InterruptedException("request=${expected.requestId} was superseded"))
        return replacement
    }

    fun current(): Request<T>? = pending.get()

    /** Frame matching is numeric only; acknowledgement remains exact-object CAS. */
    fun matches(request: Request<T>, frame: KeyguardOrbBufferProducerFrame): Boolean =
        request.expectedLease == frame.lease &&
            request.requestId == frame.testRequestId &&
            abs(request.expectedPhase - frame.materialTime.phase) <= .0001f

    /**
     * The request reference was captured before readback. This exact CAS keeps
     * a late callback from clearing or completing a newer request.
     */
    fun completeIfCurrent(request: Request<T>, frame: KeyguardOrbBufferProducerFrame, value: T): Boolean {
        if (!matches(request, frame) || !pending.compareAndSet(request, null)) return false
        request.complete(value)
        return true
    }

    fun failIfCurrent(request: Request<T>, error: Throwable): Boolean {
        if (!pending.compareAndSet(request, null)) return false
        request.fail(error)
        return true
    }

    fun cancelIfCurrent(request: Request<T>, error: Throwable): Boolean = failIfCurrent(request, error)

    fun await(request: Request<T>, timeoutMs: Long = 8_000L): T {
        return try {
            request.await(timeoutMs)
        } catch (error: Throwable) {
            cancelIfCurrent(request, error)
            throw error
        }
    }
}
