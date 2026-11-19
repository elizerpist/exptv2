package com.fluvi.app.lockscreen.material

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** These controls advance child lifecycle only; none can release a buffer. */
class KeyguardOrbRetirementBarrierTest {
    @Test fun commitBeforeMainAndWorkerMessagesWaitsForBothAttempts() {
        val a = KeyguardOrbRetirementBarrier()
        a.commitObserved()
        assertFalse(a.shouldUnlink())
        a.mainHideCompleted()
        assertFalse(a.shouldUnlink())
        a.finalClearCompleted(applied = true)
        assertTrue(a.shouldUnlink())
        a.unlinkAttempted(success = true)
        a.commitObserved()
        assertFalse(a.shouldUnlink())
    }

    @Test fun actualDrainBeforeFailedFinalClearStillWaitsForWorkerAndMain() {
        val a = KeyguardOrbRetirementBarrier()
        a.leaseDrained()
        a.mainHideCompleted()
        assertFalse(a.shouldUnlink())
        a.finalClearCompleted(applied = false)
        assertTrue(a.shouldUnlink())
    }

    @Test fun failedApplyOrMissingCommitCannotUnlinkUntilActualDrain() {
        val a = KeyguardOrbRetirementBarrier()
        a.mainHideCompleted()
        a.finalClearCompleted(applied = false)
        a.commitObserved()
        assertFalse(a.shouldUnlink())
        a.leaseDrained()
        assertTrue(a.shouldUnlink())
        val b = KeyguardOrbRetirementBarrier()
        b.mainHideCompleted()
        b.finalClearCompleted(applied = true)
        assertFalse(b.shouldUnlink())
        b.leaseDrained()
        assertTrue(b.shouldUnlink())
    }

    @Test fun failedUnlinkMayRetryOnceAfterActualDrainOnly() {
        val a = KeyguardOrbRetirementBarrier()
        a.mainHideCompleted()
        a.finalClearCompleted(applied = true)
        a.commitObserved()
        a.unlinkAttempted(success = false)
        assertFalse(a.shouldUnlink())
        a.leaseDrained()
        assertTrue(a.shouldUnlink())
        a.unlinkAttempted(success = false)
        a.leaseDrained()
        assertFalse(a.shouldUnlink())
    }

    @Test fun twoRetirementsAndDisposeHaveIndependentCompletionAuthority() {
        val a = KeyguardOrbRetirementBarrier()
        val b = KeyguardOrbRetirementBarrier()
        a.mainHideCompleted(); a.finalClearCompleted(applied = true); a.commitObserved()
        b.mainHideCompleted(); b.finalClearCompleted(applied = true)
        assertTrue(a.shouldUnlink())
        assertFalse(b.shouldUnlink())
        a.unlinkAttempted(success = true) // owner may already be disposed
        b.leaseDrained()
        assertTrue(b.shouldUnlink())
        assertFalse(a.shouldUnlink())
    }
}
