package com.fluvi.app.lockscreen

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Eligibility cannot grant presentation; it only permits a single read. */
class KeyguardR12ReadAheadPolicyTest {
    private val authority = KeyguardInspectionAuthority(1, 2, 5, 3, 4)
    private val a = request(1)
    private val b = request(2)
    private val snapshot = KeyguardReadAheadSnapshot(
        authority = authority,
        freshnessRevision = 7,
        stateRevision = 9,
        detached = true,
        showInProgress = false,
        surfaceState = KeyguardSurfacePresentationState.AWAITING_MAIN_SURFACE,
    )
    private val negative = KeyguardReadAheadNegative(
        decision = KeyguardCardVisibility.HIDDEN_UNKNOWN,
        reason = KeyguardSurfaceReason.NO_MAIN_MARKER,
        rootUnavailable = false,
        walkTruncated = false,
        abortedStale = false,
        freshnessRevision = 7,
    )
    private fun request(id: Long) = KeyguardCardInspectionRequest(
        id = id, trigger = "r12-test", session = 1, visibilityEpoch = 2,
        interactionEpoch = 3, attachGeneration = 4, wakeGeneration = 5,
        queuedAtUptimeMs = id,
    )
    private fun permits(
        snapshot: KeyguardReadAheadSnapshot = this.snapshot,
        negative: KeyguardReadAheadNegative = this.negative,
        first: KeyguardCardInspectionRequest = a,
        next: KeyguardCardInspectionRequest = b,
        revision: Long = 7,
        outstanding: KeyguardWindowFreshness = KeyguardWindowFreshness.FRAMEWORK_EVENT,
    ) = KeyguardReadAheadPolicy.permits(snapshot, negative, first, next, revision, outstanding)

    @Test fun completeDetachedNegativePermitsOnlyACompatibleRead() {
        assertTrue(permits())
        assertFalse(permits(snapshot = snapshot.copy(detached = false)))
        assertFalse(permits(snapshot = snapshot.copy(showInProgress = true)))
        assertFalse(permits(snapshot = snapshot.copy(surfaceState = KeyguardSurfacePresentationState.VISIBLE)))
        assertFalse(permits(first = a.copy(wakeGeneration = 6)))
        assertFalse(permits(next = b.copy(visibilityEpoch = 3)))
        assertFalse(permits(revision = 8))
        assertFalse(permits(negative = negative.copy(freshnessRevision = 6)))
        assertFalse(permits(negative = negative.copy(freshnessRevision = null)))
        assertFalse(permits(next = b.copy(windowFreshness = KeyguardWindowFreshness.CONTRADICTORY_OBSERVATION)))
        assertFalse(permits(outstanding = KeyguardWindowFreshness.MISSING_FRESHNESS_EVIDENCE))
    }

    @Test fun unavailableTruncatedStaleOrOtherClassificationsNeverReadAhead() {
        assertFalse(permits(negative = negative.copy(rootUnavailable = true)))
        assertFalse(permits(negative = negative.copy(walkTruncated = true)))
        assertFalse(permits(negative = negative.copy(abortedStale = true)))
        assertFalse(permits(negative = negative.copy(reason = KeyguardSurfaceReason.ROOT_UNAVAILABLE)))
        assertFalse(permits(negative = negative.copy(reason = KeyguardSurfaceReason.WALK_TRUNCATED)))
        assertFalse(permits(negative = negative.copy(decision = KeyguardCardVisibility.SHOW_FULL)))
    }
}
