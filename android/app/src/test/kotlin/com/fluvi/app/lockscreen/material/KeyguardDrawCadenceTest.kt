package com.fluvi.app.lockscreen.material

import org.junit.Assert.*
import org.junit.Test

class KeyguardDrawCadenceTest {
    @Test fun actualTraversalGapsRemainSeparateFromIdleAndCallbackIntervals() {
        val cadence = KeyguardDrawCadence()
        assertNull(cadence.snapshot().firstAt)
        cadence.drawn(100, .25f)
        cadence.drawn(116, .26f)
        cadence.drawn(166, .30f)
        val first = cadence.snapshot()
        assertEquals(3L, first.frames)
        assertEquals(2L, first.gaps)
        assertEquals(66L, first.gapTotalMs)
        assertEquals(50L, first.gapMaxMs)
        assertEquals(.25f, first.firstPhase)
        assertEquals(.30f, first.lastPhase)
        cadence.reset()
        cadence.drawn(9000, .31f)
        assertEquals(1L, cadence.snapshot().frames)
        assertEquals(0L, cadence.snapshot().gaps)
        assertEquals(0L, cadence.snapshot().gapMaxMs)
        assertEquals(3L, first.frames) // immutable previous episode
    }

    @Test fun missingDrawIsNotZeroAndInvalidOrderIsExplicit() {
        val cadence = KeyguardDrawCadence()
        assertEquals(0L, cadence.snapshot().frames)
        assertNull(cadence.snapshot().lastPhase)
        cadence.drawn(10, Float.NaN)
        cadence.drawn(9, Float.NaN)
        assertEquals(1L, cadence.snapshot().invalidOrder)
        assertEquals(0L, cadence.snapshot().gaps)
    }
}
