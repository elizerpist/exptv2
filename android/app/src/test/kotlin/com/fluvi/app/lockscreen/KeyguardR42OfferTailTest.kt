package com.fluvi.app.lockscreen

import java.util.concurrent.CountDownLatch
import org.junit.Assert.*
import org.junit.Test

class KeyguardR42OfferTailTest {
    @Test fun `overflow in one attempt cannot overwrite another attempt's latest offer`() {
        val tail = KeyguardR42OfferTail()
        repeat(80) { tail.offer(1, 10, 11, 100L + it, 1000L + it, 12) }
        tail.offer(2, 20, 21, 200, 2000, 22)
        val rows = (0 until KeyguardR42OfferTail.SLOTS).mapNotNull(tail::read)
        assertTrue(rows.any { it.attempt == 1L && it.request == 179L && it.atNs == 1079L })
        assertTrue(rows.any { it.attempt == 2L && it.session == 20L && it.wake == 21L && it.request == 200L })
        assertEquals(48L, tail.overwritten.get())
        assertEquals(0L, tail.cut())
        tail.offer(2, 20, 21, 201, 2001, 22)
        assertEquals(1L, tail.late.get())
        assertFalse((0 until KeyguardR42OfferTail.SLOTS).mapNotNull(tail::read).any { it.request == 201L })
    }

    @Test fun `concurrent writers never publish a mixed scalar record`() {
        val tail = KeyguardR42OfferTail()
        val start = CountDownLatch(1)
        val threads = (1L..4L).map { attempt ->
            Thread {
                start.await()
                repeat(500) { index ->
                    val request = attempt * 10_000 + index
                    tail.offer(attempt, attempt * 10, attempt * 100, request, request + 1, request + 2)
                }
            }.also { it.start() }
        }
        start.countDown()
        threads.forEach { it.join() }
        assertEquals(0L, tail.cut())
        val rows = (0 until KeyguardR42OfferTail.SLOTS).mapNotNull(tail::read)
        assertTrue(rows.isNotEmpty())
        rows.forEach {
            assertEquals(it.attempt * 10, it.session)
            assertEquals(it.attempt * 100, it.wake)
            assertEquals(it.request + 1, it.atNs)
            assertEquals(it.request + 2, it.tid)
        }
    }
}
