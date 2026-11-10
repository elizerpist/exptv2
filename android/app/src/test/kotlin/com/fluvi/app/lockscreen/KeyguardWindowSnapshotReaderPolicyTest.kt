package com.fluvi.app.lockscreen

import android.view.Display
import android.view.accessibility.AccessibilityWindowInfo
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class KeyguardWindowSnapshotReaderPolicyTest {
    @Test fun activeSystemUiCandidateIsSelectedAndRequiresMatchingReturnedRoot() {
        val candidate = window(id = 41, active = true)
        val selected = KeyguardWindowSnapshotReaderPolicy.activeCandidate(
            windows = listOf(candidate), knownOwn = null, attachGeneration = 7L,
        )

        assertEquals(candidate, selected)
        assertTrue(
            KeyguardWindowSnapshotReaderPolicy.acceptsActiveRoot(
                requireNotNull(selected), returnedWindowId = 41,
                returnedPackageName = "com.android.systemui", currentWindows = listOf(candidate),
            ),
        )
        assertFalse(
            KeyguardWindowSnapshotReaderPolicy.acceptsActiveRoot(
                requireNotNull(selected), returnedWindowId = 99,
                returnedPackageName = "com.android.systemui", currentWindows = listOf(candidate),
            ),
        )
    }

    @Test fun exactKnownOwnOverlayIsNeverTheActiveRootCandidate() {
        val own = window(id = 7, active = true, type = AccessibilityWindowInfo.TYPE_ACCESSIBILITY_OVERLAY)
        val identity = KeyguardOwnOverlayIdentity(windowId = 7, displayId = Display.DEFAULT_DISPLAY, attachGeneration = 9L)

        assertNull(KeyguardWindowSnapshotReaderPolicy.activeCandidate(listOf(own), identity, 9L))
        // A stale attach generation is intentionally not own-overlay proof:
        // the window must remain eligible for normal discovery.
        assertEquals(own, KeyguardWindowSnapshotReaderPolicy.activeCandidate(listOf(own), identity, 10L))
    }

    @Test fun ambiguousAndSecondaryActiveWindowsUseTheSafeFallback() {
        val first = window(id = 1, active = true)
        val second = window(id = 2, active = true)
        val secondary = window(id = 3, active = true, displayId = 1)

        assertNull(KeyguardWindowSnapshotReaderPolicy.activeCandidate(listOf(first, second), null, 1L))
        assertNull(KeyguardWindowSnapshotReaderPolicy.activeCandidate(listOf(secondary), null, 1L))
    }

    @Test fun activeRootMustStillBelongToThePrimaryWindowMetadata() {
        val candidate = window(id = 11, active = true)
        assertFalse(
            KeyguardWindowSnapshotReaderPolicy.acceptsActiveRoot(
                candidate, returnedWindowId = 11, returnedPackageName = "com.android.systemui",
                currentWindows = listOf(window(id = 11, active = true, displayId = 1)),
            ),
        )
    }

    @Test fun ordinary_events_keep_framework_cache_and_lifecycle_evidence_can_clear_it() {
        assertFalse(
            KeyguardWindowSnapshotReaderPolicy.shouldClearCache(
                KeyguardWindowFreshness.FRAMEWORK_EVENT,
            ),
        )
        assertTrue(
            KeyguardWindowSnapshotReaderPolicy.shouldClearCache(
                KeyguardWindowFreshness.LIFECYCLE_BOUNDARY,
            ),
        )
        assertTrue(
            KeyguardWindowSnapshotReaderPolicy.shouldClearCache(
                KeyguardWindowFreshness.CONTRADICTORY_OBSERVATION,
            ),
        )
        assertTrue(
            KeyguardWindowSnapshotReaderPolicy.shouldClearCache(
                KeyguardWindowFreshness.MISSING_FRESHNESS_EVIDENCE,
            ),
        )
    }

    @Test fun active_root_strategy_is_not_coupled_to_a_cache_clear_result() {
        // A normal event does not clear the whole cache, but can still use
        // the validated active-root path when Android reports the cache live.
        assertTrue(
            KeyguardWindowSnapshotReaderPolicy.canUseBatchedActiveRoot(
                apiLevel = 35,
                cacheEnabled = true,
                hasUnambiguousCandidate = true,
                freshnessBoundaryEstablished = true,
            ),
        )
        assertFalse(
            KeyguardWindowSnapshotReaderPolicy.canUseBatchedActiveRoot(
                apiLevel = 35,
                cacheEnabled = false,
                hasUnambiguousCandidate = true,
                freshnessBoundaryEstablished = true,
            ),
        )
        assertFalse(
            KeyguardWindowSnapshotReaderPolicy.canUseBatchedActiveRoot(
                apiLevel = 32,
                cacheEnabled = true,
                hasUnambiguousCandidate = true,
                freshnessBoundaryEstablished = true,
            ),
        )
        // A deliberate clear that fails falls back to per-window acquisition;
        // normal events do not require that explicit boundary in the first
        // place.
        assertFalse(
            KeyguardWindowSnapshotReaderPolicy.canUseBatchedActiveRoot(
                apiLevel = 35,
                cacheEnabled = true,
                hasUnambiguousCandidate = true,
                freshnessBoundaryEstablished = false,
            ),
        )
    }

    @Test fun prefetch_configuration_matches_measured_batched_baseline_not_a_speed_assertion() {
        val flags = KeyguardWindowSnapshotReaderPolicy.batchedPrefetchFlags(apiLevel = 35)
        assertTrue(
            (flags and android.view.accessibility.AccessibilityNodeInfo.FLAG_PREFETCH_DESCENDANTS_HYBRID) != 0,
        )
        assertTrue(
            (flags and android.view.accessibility.AccessibilityNodeInfo.FLAG_PREFETCH_UNINTERRUPTIBLE) != 0,
        )
        assertEquals(0, KeyguardWindowSnapshotReaderPolicy.batchedPrefetchFlags(apiLevel = 32))
    }

    private fun window(
        id: Int,
        active: Boolean,
        type: Int = AccessibilityWindowInfo.TYPE_APPLICATION,
        displayId: Int = Display.DEFAULT_DISPLAY,
    ) = KeyguardWindowReaderWindowMetadata(id, type, displayId, active)
}
