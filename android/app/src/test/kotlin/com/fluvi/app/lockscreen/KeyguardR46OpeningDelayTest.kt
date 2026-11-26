package com.fluvi.app.lockscreen

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class KeyguardR46OpeningDelayTest {
    @Test fun newProofDoesNotRestartTheOriginalDelay() {
        val owner = KeyguardR46OpeningDelay()
        assertEquals(50L, owner.allow(1000L))
        // An unknown revision invalidates permission, not the deadline.
        assertEquals(49L, owner.allow(1001L))
        assertEquals(0L, owner.allow(1120L))
        assertEquals(1050L, owner.dueAt)
        owner.reset()
        assertNull(owner.dueAt)
        assertEquals(50L, owner.allow(1120L))
    }
}
