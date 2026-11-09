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

    private fun window(
        id: Int,
        active: Boolean,
        type: Int = AccessibilityWindowInfo.TYPE_APPLICATION,
        displayId: Int = Display.DEFAULT_DISPLAY,
    ) = KeyguardWindowReaderWindowMetadata(id, type, displayId, active)
}
