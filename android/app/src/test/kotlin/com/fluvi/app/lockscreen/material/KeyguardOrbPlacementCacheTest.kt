package com.fluvi.app.lockscreen.material

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class KeyguardOrbPlacementCacheTest {
    private fun lease(attachment: Long, generation: Long) =
        KeyguardOrbBufferLease(attachment, generation, "visual", "program", 168, 168)

    @Test fun onlySuccessfulIdenticalChildRootLeaseAndPositionAreSuppressed() {
        val cache = KeyguardOrbPlacementCache()
        val child = Any(); val root = Any(); val a = lease(1, 1)
        assertTrue(cache.needsSubmission(child, root, a, 10, 20))
        cache.submitted(child, root, a, 10, 20)
        assertFalse(cache.needsSubmission(child, root, a, 10, 20))
        assertTrue(cache.needsSubmission(child, root, a, 11, 20))
        assertTrue(cache.needsSubmission(Any(), root, a, 10, 20))
        assertTrue(cache.needsSubmission(child, Any(), a, 10, 20))
        assertTrue(cache.needsSubmission(child, root, lease(2, 2), 10, 20))
        cache.invalidate()
        assertTrue(cache.needsSubmission(child, root, a, 10, 20))
    }
}
