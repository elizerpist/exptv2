package com.fluvi.app.lockscreen.material

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.concurrent.CountDownLatch
import java.util.concurrent.atomic.AtomicBoolean

/** These examples describe decisions, not release: none can free a buffer. */
class KeyguardOrbPressurePolicyTest {
    private val grant = Any()
    private val policy = KeyguardOrbPressurePolicy()

    private fun sample(
        time: Long, grant: Any? = this.grant, eligible: Boolean = true,
        oldUnreleased: Int = 0, oldOwned: Int = 0, free: Int = 0,
        currentInFlight: Boolean = false, wrongSizeOld: Boolean = false,
        currentCompatible: Boolean = false, progress: Int = 0,
        opportunity: Boolean = true,
    ) = policy.observe(grant, eligible, 3, oldUnreleased, oldOwned, free,
        currentInFlight, wrongSizeOld, currentCompatible, progress, time, opportunity)

    @Test fun threeRetiredUnreleasedUsesBlockImmediatelyButRequireAnExactGrant() {
        assertNull(sample(100, grant = null, eligible = false, oldUnreleased = 3, oldOwned = 3))
        assertEquals(KeyguardOrbPressureReason.ALL_OLD_UNRELEASED,
            sample(101, oldUnreleased = 3, oldOwned = 3, opportunity = false))
    }

    @Test fun twoOldUsesNeedContinuousNoSuccessorAndThreeOpportunitiesForFiftyMs() {
        assertNull(sample(100, oldOwned = 2))
        assertNull(sample(149, oldOwned = 2))
        assertNull(sample(150, oldOwned = 2, opportunity = false))
        assertEquals(KeyguardOrbPressureReason.NO_SUCCESSOR, sample(151, oldOwned = 2))
    }

    @Test fun normalTripleBufferingFreeCapacityAndCurrentWorkAreNotPressure() {
        repeat(10) { n ->
            assertNull(sample(100L + n * 20, oldOwned = 0, progress = n))
            assertNull(sample(101L + n * 20, oldOwned = 2, free = 1))
            assertNull(sample(102L + n * 20, oldOwned = 2, currentInFlight = true))
            assertNull(sample(103L + n * 20, oldOwned = 1))
        }
    }

    @Test fun progressReleaseGrantAndConditionChangesResetTheInterval() {
        assertNull(sample(100, oldOwned = 2))
        assertNull(sample(140, oldOwned = 2))
        assertNull(sample(151, oldOwned = 2, progress = 1))
        assertNull(sample(190, oldOwned = 2, progress = 1))
        assertNull(sample(202, oldOwned = 2, free = 1, progress = 1))
        assertNull(sample(250, oldOwned = 2, grant = Any(), progress = 1))
        assertNull(sample(300, oldOwned = 2, progress = 1))
        assertNull(sample(320, oldOwned = 2, progress = 1))
        assertEquals(KeyguardOrbPressureReason.NO_SUCCESSOR,
            sample(350, oldOwned = 2, progress = 1))
    }

    @Test fun incompatibleRetiredSizeIsNotRecoveryWhileCompatibleCurrentWorkExists() {
        repeat(4) { assertNull(sample(100L + it * 30, oldOwned = 1,
            wrongSizeOld = true, currentCompatible = true, currentInFlight = true)) }
        assertNull(sample(300, oldOwned = 1, wrongSizeOld = true))
        assertNull(sample(325, oldOwned = 1, wrongSizeOld = true))
        assertEquals(KeyguardOrbPressureReason.WRONG_SIZE_OLD,
            sample(350, oldOwned = 1, wrongSizeOld = true))
    }

    @Test fun oldWrongSizeDoesNotCausePressureWhenTwoFreeSlotsCanBeRebuilt() {
        // One genuinely owned old buffer leaves two independently replaceable
        // FREE slots. Time and repeated opportunities must not turn capacity
        // into WRONG_SIZE_OLD merely because that old buffer is still held.
        repeat(5) { n ->
            assertNull("free slots remain productive despite an old-size use",
                sample(100L + n * 30, oldOwned = 1, free = 2,
                    wrongSizeOld = true, currentCompatible = false))
        }
    }

    @Test fun oldWrongSizeDoesNotCausePressureWhenPoolHasUnallocatedCapacity() {
        repeat(5) { n ->
            assertNull("unallocated slots remain productive despite an old-size use",
                policy.observe(grant, true, 1, 0, 1, 0, false,
                    true, false, 0, 100L + n * 30, true))
        }
    }

    @Test fun onePublishedCurrentFrameDoesNotProveThereIsSuccessorCapacity() {
        assertNull(sample(100, oldOwned = 1, wrongSizeOld = true, currentCompatible = true))
        assertNull(sample(130, oldOwned = 1, wrongSizeOld = true, currentCompatible = true))
        assertEquals(KeyguardOrbPressureReason.WRONG_SIZE_OLD,
            sample(160, oldOwned = 1, wrongSizeOld = true, currentCompatible = true))
    }

    @Test fun cancellationAndClaimHaveExactlyOneWinnerEvenWhenConcurrent() {
        repeat(100) {
            val claim = KeyguardOrbPressureClaim()
            val start = CountDownLatch(1)
            val claimed = AtomicBoolean()
            val cancelled = AtomicBoolean()
            val a = Thread { start.await(); claimed.set(claim.claim()) }
            val b = Thread { start.await(); cancelled.set(claim.cancel()) }
            a.start(); b.start(); start.countDown(); a.join(); b.join()
            assertTrue("exactly one outcome must own this ticket", claimed.get() xor cancelled.get())
            assertEquals(false, claim.claim())
            assertEquals(false, claim.cancel())
        }
    }
}
