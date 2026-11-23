package com.fluvi.app.lockscreen.material

import org.junit.Assert.*
import org.junit.Test

class KeyguardR34PrivateAssetCacheTest {
    @Test fun equalRequestIsRetainedButAbaNeverAcceptsAnOldCompletion() {
        val released = mutableListOf<String>()
        val cache = KeyguardR34PrivateAssetCache<String, String> { released += it }
        val a1 = checkNotNull(cache.request("A"))
        assertNull(cache.request("A"))
        val b = checkNotNull(cache.request("B"))
        val a2 = checkNotNull(cache.request("A"))
        assertTrue(a2.generation > b.generation && b.generation > a1.generation)
        assertFalse(cache.publish(a1, "old-A"))
        assertFalse(cache.publish(b, "old-B"))
        assertTrue(cache.publish(a2, "current-A"))
        assertEquals(listOf("old-A", "old-B"), released)
        val lease = checkNotNull(cache.acquire("A"))
        assertEquals("current-A", lease.value)
        lease.close()
        cache.close()
        assertEquals(listOf("old-A", "old-B", "current-A"), released)
    }

    @Test fun clearAndReplacementRetireOnlyAfterTheLastRealLease() {
        val released = mutableListOf<String>()
        val cache = KeyguardR34PrivateAssetCache<Int, String> { released += it }
        val first = checkNotNull(cache.request(1)); assertTrue(cache.publish(first, "first"))
        val x = checkNotNull(cache.acquire(1)); val y = checkNotNull(cache.acquire(1))
        val second = checkNotNull(cache.request(2))
        assertNull(cache.acquire(1)); assertTrue(cache.publish(second, "second"))
        cache.clear(); assertEquals(listOf("second"), released)
        x.close(); x.close(); assertEquals(listOf("second"), released)
        y.close(); assertEquals(listOf("second", "first"), released)
        assertNull(cache.acquire(2))
    }

    @Test fun missingReceiptsBoundOutstandingPrivateResources() {
        val released = mutableListOf<String>()
        val cache = KeyguardR34PrivateAssetCache<Int, String> { released += it }
        val first = checkNotNull(cache.request(1)); assertTrue(cache.publish(first, "first"))
        val heldFirst = checkNotNull(cache.acquire(1))
        val second = checkNotNull(cache.request(2)); assertTrue(cache.publish(second, "second"))
        val heldSecond = checkNotNull(cache.acquire(2))
        val third = checkNotNull(cache.request(3)); assertTrue(cache.publish(third, "third"))
        assertNull("missing receipts must not grow the ownership set", cache.acquire(3))
        heldFirst.close(); assertNotNull(cache.acquire(3)?.also { it.close() })
        heldSecond.close(); cache.close()
        assertEquals(setOf("first", "second", "third"), released.toSet())
    }

    @Test fun failureCanRetryAndClearRejectsAnInFlightCompletion() {
        val released = mutableListOf<String>()
        val cache = KeyguardR34PrivateAssetCache<String, String> { released += it }
        val failed = checkNotNull(cache.request("same")); cache.failed(failed)
        val retry = checkNotNull(cache.request("same"))
        assertTrue(retry.generation > failed.generation)
        cache.clear()
        assertFalse(cache.publish(retry, "late")); assertEquals(listOf("late"), released)
        cache.close(); assertNull(cache.request("closed"))
    }
}
