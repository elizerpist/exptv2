package com.fluvi.app.lockscreen

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class KeyguardFirstDrawOwnerTest {
    private val event = KeyguardFirstDrawEvent(attachGeneration = 41L, observedAtUptimeMs = 1234L)
    private val owner = KeyguardFirstDrawOwner(
        session = 7L,
        wakeGeneration = 12L,
        attachGeneration = 41L,
    )

    @Test fun `owner accepts only its original session wake and attach`() {
        assertTrue(owner.accepts(event, currentSession = 7L, currentWakeGeneration = 12L, currentAttachGeneration = 41L))
        assertFalse(owner.accepts(event, currentSession = 8L, currentWakeGeneration = 12L, currentAttachGeneration = 41L))
        assertFalse(owner.accepts(event, currentSession = 7L, currentWakeGeneration = 13L, currentAttachGeneration = 41L))
        assertFalse(owner.accepts(event, currentSession = 7L, currentWakeGeneration = 12L, currentAttachGeneration = 42L))
    }

    @Test fun `event from old attach cannot be published into replacement attach`() {
        val replacement = KeyguardFirstDrawOwner(
            session = 7L,
            wakeGeneration = 13L,
            attachGeneration = 42L,
        )

        assertFalse(
            replacement.accepts(
                event,
                currentSession = 7L,
                currentWakeGeneration = 13L,
                currentAttachGeneration = 42L,
            ),
        )
    }
}
