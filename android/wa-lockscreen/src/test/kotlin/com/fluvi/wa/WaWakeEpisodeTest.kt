package com.fluvi.wa

import android.view.Display
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class WaWakeEpisodeTest {
    private val main = WaSystemState(Display.STATE_ON, interactive = true, locked = true)

    @Test fun requiresLiveDisplayInteractiveAndLocked() {
        val noninteractive = main.copy(interactive = false)
        assertEquals(WaHideReason.NONINTERACTIVE, noninteractive.terminal)
        assertEquals(WaHideReason.UNLOCKED, main.copy(locked = false).terminal)
        assertEquals(WaHideReason.DISPLAY, main.copy(displayState = Display.STATE_DOZE).terminal)
        assertEquals(WaHideReason.DISPLAY, main.copy(displayState = WaSystemState.DISPLAY_MISSING).terminal)
        val episode = WaWakeEpisode().apply { connect() }
        for (uncertain in listOf(
            noninteractive, main.copy(interactive = null), main.copy(locked = null),
            main.copy(displayState = Display.STATE_UNKNOWN),
        )) {
            assertFalse(episode.admit(uncertain))
            assertEquals(0L, episode.id)
        }
        assertTrue(episode.admit(main))
    }

    @Test fun explicitSleepClosesEvenWithStaleOnState() {
        val episode = WaWakeEpisode().apply { connect(); assertTrue(admit(main)) }
        val old = episode.id
        episode.close(WaBarrier.SLEEP, newSleepSignal = true)
        assertFalse(episode.owns(old))
        repeat(5) { assertFalse(episode.admit(main)) }
        episode.wakeSignal()
        assertFalse(episode.admit(main.copy(displayState = Display.STATE_OFF)))
        episode.close(WaBarrier.SLEEP, observed = true)
        assertTrue(episode.admit(main))
        assertFalse(episode.owns(old))
        assertEquals(old + 1, episode.id)
        episode.attached(old)
        assertFalse(episode.entranceAdmitted)
    }

    @Test fun verifiedDefaultDisplayEdgePermitsNewWakeWithoutBroadcast() {
        val episode = WaWakeEpisode().apply { connect(); assertTrue(admit(main)) }
        val old = episode.id
        episode.close(WaBarrier.SLEEP, observed = true)
        assertFalse(episode.admit(main.copy(locked = null)))
        assertTrue(episode.admit(main))
        assertFalse(episode.owns(old))
        assertTrue(episode.owns(old + 1))
    }

    @Test fun unlockNeedsRealLockTransitionOrSubsequentSleepAndWake() {
        val episode = WaWakeEpisode().apply { connect(); assertTrue(admit(main)) }
        val old = episode.id
        episode.close(WaBarrier.UNLOCKED)
        episode.wakeSignal()
        assertFalse(episode.admit(main))
        episode.close(WaBarrier.UNLOCKED, observed = true)
        assertFalse(episode.admit(main.copy(locked = false)))
        assertTrue(episode.admit(main))
        assertFalse(episode.owns(old))
        episode.close(WaBarrier.UNLOCKED)
        episode.close(WaBarrier.SLEEP, newSleepSignal = true)
        episode.wakeSignal()
        assertTrue(episode.admit(main))
    }

    @Test fun temporaryRestrictionRetainsSingleEntranceAndDisconnectInvalidatesIt() {
        val episode = WaWakeEpisode().apply { connect(); assertTrue(admit(main)) }
        val old = episode.id
        episode.attached(old)
        repeat(3) {
            assertTrue(episode.admit(main))
            assertEquals(old, episode.id)
            assertTrue(episode.entranceAdmitted)
        }
        episode.close(WaBarrier.DISCONNECTED)
        assertFalse(episode.admit(main))
        episode.connect()
        assertTrue(episode.admit(main))
        assertFalse(episode.entranceAdmitted)
    }
}
