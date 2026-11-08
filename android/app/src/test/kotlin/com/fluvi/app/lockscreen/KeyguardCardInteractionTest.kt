package com.fluvi.app.lockscreen

import org.junit.Assert.assertEquals
import org.junit.Test

class KeyguardCardInteractionTest {
    @Test fun `short root press remains a click`() {
        val gesture = KeyguardCardGestureStateMachine(touchSlop = 12f)
        gesture.down(7, 100f, 200f)

        assertEquals(KeyguardCardGestureResult.CLICK, gesture.up(7))
        assertEquals(KeyguardCardGestureState.IDLE, gesture.state)
    }

    @Test fun `long press never falls through to root or child click`() {
        val gesture = KeyguardCardGestureStateMachine(touchSlop = 12f)
        gesture.down(7, 100f, 200f)

        assertEquals(KeyguardCardGestureResult.START_DRAG, gesture.longPress())
        assertEquals(KeyguardCardGestureResult.COMMIT, gesture.up(7))
    }

    @Test fun `movement beyond slop before long press cancels instead of clicking later`() {
        val gesture = KeyguardCardGestureStateMachine(touchSlop = 12f)
        gesture.down(7, 100f, 200f)

        assertEquals(KeyguardCardGestureResult.CANCEL_CHILDREN, gesture.move(7, 120f, 200f))
        assertEquals(KeyguardCardGestureResult.CANCEL, gesture.up(7))
    }

    @Test fun `second pointer cancels an active drag without pointer substitution`() {
        val gesture = KeyguardCardGestureStateMachine(touchSlop = 12f)
        gesture.down(7, 100f, 200f)
        gesture.longPress()

        assertEquals(KeyguardCardGestureResult.CANCEL, gesture.cancel())
        assertEquals(KeyguardCardGestureState.IDLE, gesture.state)
    }
}
