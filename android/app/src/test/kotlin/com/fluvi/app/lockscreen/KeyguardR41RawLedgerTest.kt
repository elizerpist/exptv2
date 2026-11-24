package com.fluvi.app.lockscreen

import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import org.junit.Assert.*
import org.junit.Test

class KeyguardR41RawLedgerTest {
    @Test fun boundedCapturePreservesScalarsAndDeclaresOverflowAndLateWrites() {
        val ledger = KeyguardR41RawLedger(2)
        assertEquals(1L, ledger.offer(KeyguardR41RawLedger.PROVISIONAL, 0, 3, 4, 0, 100, 9, 2, 7, 11))
        assertEquals(2L, ledger.offer(KeyguardR41RawLedger.OFFER, 1, 3, 4, 12, 110, 10))
        assertEquals(0L, ledger.offer(KeyguardR41RawLedger.MAIN, 1, 3, 4, 12, 120, 11))
        assertEquals(1L, ledger.overflow.get())
        val first = checkNotNull(ledger.read(0))
        assertEquals(100L, first.atNs)
        assertEquals(7L, first.extra2)
        assertEquals(12L, checkNotNull(ledger.read(1)).request)
        assertEquals(0L, ledger.offerTimingInvalid.get())
        assertTrue(ledger.offerWallNs.get() >= ledger.offerMaxWallNs.get())
        assertEquals(0L, ledger.cut())
        assertEquals(0L, ledger.offer(KeyguardR41RawLedger.MAIN, 1, 3, 4, 12, 120, 11))
        assertEquals(1L, ledger.late.get())
        assertNull(ledger.read(2))
    }

    @Test fun concurrentWritersPublishWholeRecordsWithoutDuplicateOrdinals() {
        val ledger = KeyguardR41RawLedger(512)
        val start = CountDownLatch(1)
        val pool = Executors.newFixedThreadPool(4)
        try {
            val futures = (0 until 4).map { thread -> pool.submit {
                check(start.await(5, TimeUnit.SECONDS))
                repeat(100) { index ->
                    val id = thread * 100L + index
                    check(ledger.offer(KeyguardR41RawLedger.READ_START, id, 8, 9, id, id + 1, thread.toLong()) > 0)
                }
            } }
            start.countDown()
            futures.forEach { it.get(5, TimeUnit.SECONDS) }
            assertEquals(0L, ledger.cut())
            val records = (0 until ledger.size()).map { checkNotNull(ledger.read(it)) }
            assertEquals(400, records.size)
            assertEquals(400, records.map { it.request }.toSet().size)
            assertTrue(records.all { it.atNs == it.request + 1 && it.session == 8L && it.wake == 9L })
            assertEquals(0L, ledger.overflow.get())
        } finally {
            start.countDown()
            pool.shutdownNow()
        }
    }
}
