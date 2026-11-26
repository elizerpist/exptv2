package com.fluvi.app.lockscreen.material

import org.junit.Assert.*
import org.junit.Test

class KeyguardR47SourceOrderTest {
    @Test fun pendingOldRenderCannotCrossANewerInvalidation() {
        val order = KeyguardR47SourceOrder()
        assertTrue(order.bind(1, 1, "dashboard-a"))
        assertTrue(order.accept(1, 1, "dashboard-a", 1))
        assertTrue(order.invalidate(1, 1, "dashboard-a", 3))
        assertFalse(order.accept(1, 1, "dashboard-a", 2))
        assertTrue(order.accept(1, 1, "dashboard-a", 3))
        assertFalse(order.invalidate(1, 1, "dashboard-a", 2))
        assertFalse(order.accept(1, 1, "dashboard-a", 3))
    }

    @Test fun newerEngineRevokesOldEngineAndItsLateMessages() {
        val order = KeyguardR47SourceOrder()
        assertTrue(order.bind(1, 1, "dashboard-a"))
        assertTrue(order.accept(1, 1, "dashboard-a", 7))
        assertTrue(order.bind(1, 2, "dashboard-b"))
        assertFalse(order.bind(1, 1, "dashboard-a"))
        assertFalse(order.invalidate(1, 1, "dashboard-a", 8))
        assertFalse(order.accept(1, 1, "dashboard-a", 9))
        assertTrue(order.accept(1, 2, "dashboard-b", 1))
        assertTrue(order.bind(2, 1, "dashboard-c"))
        assertFalse(order.bind(1, 99, "dashboard-old"))
        assertTrue(order.accept(2, 1, "dashboard-c", 1))
    }
}
