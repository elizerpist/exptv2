package com.fluvi.app.lockscreen

import org.junit.Assert.assertEquals
import org.junit.Test

class KeyguardCardClickRouterTest {
    @Test fun `standalone orb short taps are consumed without opening Fluvi`() {
        var opens = 0
        var consumed = 0
        val router = KeyguardCardClickRouter(
            onCardOpen = { opens += 1 },
            onOrbTapConsumed = { consumed += 1 },
        )

        repeat(10) { router.onRootClick(KeyguardCardPresentationMode.ORB) }

        assertEquals(0, opens)
        assertEquals(10, consumed)
    }

    @Test fun `retained root routes according to its current presentation`() {
        var opens = 0
        var consumed = 0
        val router = KeyguardCardClickRouter(
            onCardOpen = { opens += 1 },
            onOrbTapConsumed = { consumed += 1 },
        )

        router.onRootClick(KeyguardCardPresentationMode.CARD)
        router.onRootClick(KeyguardCardPresentationMode.ORB)
        router.onRootClick(KeyguardCardPresentationMode.CARD)

        assertEquals(2, opens)
        assertEquals(1, consumed)
    }
}
