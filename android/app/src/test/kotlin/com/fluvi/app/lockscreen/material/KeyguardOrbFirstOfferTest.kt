package com.fluvi.app.lockscreen.material

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

class KeyguardOrbFirstOfferTest {
    @Test fun offerThenClaimTransfersExactlyOnce() {
        val state = KeyguardOrbFirstOffer<Any>()
        val a = Any()
        assertTrue(state.offer(a, 42))
        assertFalse(state.offer(Any(), 43))
        val claim = requireNotNull(state.claim())
        assertSame(a, claim.value)
        assertEquals(42L, claim.offeredAt)
        assertNull(state.claim())
        assertTrue(state.settle(a))
        assertFalse(state.settle(a))
        assertNull(state.revoke())
    }

    @Test fun revokeBeforeOfferOrAfterPendingHasOneOwner() {
        val a = Any()
        val before = KeyguardOrbFirstOffer<Any>()
        assertNull(before.revoke())
        assertFalse(before.offer(a, 1))
        val pending = KeyguardOrbFirstOffer<Any>()
        assertTrue(pending.offer(a, 2))
        assertSame(a, pending.revoke())
        assertNull(pending.revoke())
        assertNull(pending.claim())
    }

    @Test fun delayedClaimCanBeRevokedWithoutDoubleDisposition() {
        val state = KeyguardOrbFirstOffer<Any>()
        val a = Any()
        assertTrue(state.offer(a, 7))
        assertSame(a, state.claim()?.value)
        assertTrue(state.isClaimed(a))
        assertSame(a, state.revoke())
        assertFalse(state.isClaimed(a))
        assertFalse(state.settle(a))
        assertNull(state.revoke())
    }

    @Test fun staleIdentityCannotSettleCurrentClaim() {
        val state = KeyguardOrbFirstOffer<Any>()
        val a = Any()
        assertTrue(state.offer(a, 10))
        assertSame(a, state.claim()?.value)
        assertFalse(state.settle(Any()))
        assertTrue(state.isClaimed(a))
        assertTrue(state.settle(a))
    }

    @Test fun failedWorkerNotificationCannotRevokeMainClaim() {
        val state = KeyguardOrbFirstOffer<Any>()
        val a = Any()
        assertTrue(state.offer(a, 12))
        assertSame(a, state.claim()?.value)
        assertNull(state.revokeUnclaimed())
        assertTrue(state.isClaimed(a))
        assertTrue(state.settle(a))
    }

    @Test fun simultaneousOfferAndRevocationNeverDuplicateOwnership() {
        repeat(500) {
            val state = KeyguardOrbFirstOffer<Any>()
            val a = Any()
            val start = java.util.concurrent.CountDownLatch(1)
            val accepted = java.util.concurrent.atomic.AtomicBoolean()
            val revoked = java.util.concurrent.atomic.AtomicReference<Any?>()
            val producer = Thread { start.await(); accepted.set(state.offer(a, 1)) }
            val main = Thread { start.await(); revoked.set(state.revoke()) }
            producer.start(); main.start(); start.countDown()
            producer.join(); main.join()
            if (accepted.get()) assertSame(a, revoked.get()) else assertNull(revoked.get())
            assertNull(state.claim())
            assertNull(state.revoke())
        }
    }
}
