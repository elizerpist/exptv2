package com.fluvi.app.lockscreen

import org.junit.Assert.*
import org.junit.Test

/** Boundary controls; service and compositor instrumentation are separate. */
class KeyguardR30TransitionPolicyTest {
    private fun childFlags(
        api: Int = 35,
        strategy: KeyguardActiveRootStrategy = KeyguardActiveRootStrategy.R18_INITIAL_HYBRID,
        accepted: Boolean = true,
        exactWindow: Boolean = true,
        packageName: String? = "com.android.systemui",
        inventory: Boolean = true,
        opening: Boolean = true,
    ) = KeyguardWindowSnapshotReaderPolicy.r30ChildPrefetchFlags(
        api, strategy, accepted, exactWindow, packageName, inventory, opening,
    )

    @Test fun onlyExactVirginApi35SystemUiOpeningUsesInterruptibleHybrid() {
        assertEquals(4, childFlags())
        assertEquals(36, childFlags(strategy = KeyguardActiveRootStrategy.STOCK))
        assertEquals(36, childFlags(strategy = KeyguardActiveRootStrategy.R15_HISTORICAL_ZERO))
        assertEquals(36, childFlags(exactWindow = false))
        assertEquals(36, childFlags(packageName = "com.android.keyguard"))
        assertEquals(36, childFlags(packageName = null))
        assertEquals(36, childFlags(inventory = false))
        assertEquals(36, childFlags(opening = false))
        assertEquals(36, childFlags(api = 34))
        assertNull(childFlags(accepted = false))
    }

    private val old = KeyguardInspectionAuthority(1, 2, 3, 4, 5)
    private fun reserve(c: KeyguardOrbPresentationCoordinator): KeyguardOrbPresentationCoordinator.Reservation {
        val stamp = KeyguardOrbPresentationStamp(old.copy(wakeGeneration = 4), 100, 11, 12, 13,
            168, 168, 420, true, 10, 20, 0)
        return requireNotNull(c.reserve(stamp, 1, old, old, sampleEligible = true, routeEligible = true))
    }

    @Test fun earlySealRequiresExactPresentedOwnerAndProofAndCannotRepeat() {
        val c = KeyguardOrbPresentationCoordinator()
        val token = reserve(c)
        val host = Any()
        val image = Any()
        val authority = token.stamp.authority
        assertTrue(c.adopt(token, token.stamp))
        assertTrue(c.attachInertHost(token, host))
        assertTrue(c.hostReady(token, host))
        assertTrue(c.attachPreparedOutput(token, image))
        assertTrue(c.imageReady(token, image))
        assertTrue(c.grant(token, authority, 105, true, true, true, 11, 12, 13))
        assertTrue(c.armInput(token, host))
        assertNull(c.r30PresentedOwner(token, authority, host, image))
        val reveal = requireNotNull(c.queueReveal(token, authority, true, true, 11, 12, 13))
        assertTrue(c.crossSubmitBoundary(reveal))
        assertNotNull(c.markNativeApplyReturned(reveal))
        assertTrue(c.revealSubmitted(reveal))
        assertNull(c.r30PresentedOwner(token, authority, Any(), image))
        assertNull(c.r30PresentedOwner(token, authority, host, Any()))
        assertNull(c.r30PresentedOwner(token, authority.copy(wakeGeneration = 99), host, image))
        val identity = requireNotNull(c.r30PresentedOwner(token, authority, host, image))
        assertEquals(105L, identity.proofRequestId)
        assertNull(c.r30SealPresented(identity, authority, 104))
        assertNull(c.r30SealPresented(identity, authority.copy(wakeGeneration = 99), 106))
        assertSame(image, requireNotNull(c.r30SealPresented(identity, authority, 106)).output)
        assertNull(c.r30SealPresented(identity, authority, 106))
        assertFalse(c.revealSubmitted(reveal))
        assertTrue(c.hostRemoved(token, host))
        assertTrue(c.retired(token))
        assertTrue(c.outputDrained(token, image))
        val nextAuthority = authority.copy(visibilityEpoch = authority.visibilityEpoch + 1)
        val nextStamp = token.stamp.copy(authority = nextAuthority, firstRequestId = 107,
            hostGeneration = 11, outputGeneration = 21)
        val replacement = requireNotNull(c.reserveReadmission(nextStamp, 2, nextAuthority, true, true))
        val nextHost = Any(); val nextImage = Any()
        assertTrue(c.attachInertHost(replacement, nextHost))
        assertTrue(c.hostReady(replacement, nextHost))
        assertTrue(c.attachPreparedOutput(replacement, nextImage))
        assertTrue(c.imageReady(replacement, nextImage))
        assertTrue(c.grant(replacement, nextAuthority, 107, true, true, true, 11, 12, 13))
        assertTrue(c.armInput(replacement, nextHost))
        val nextReveal = requireNotNull(c.queueReveal(replacement, nextAuthority, true, true, 11, 12, 13))
        assertTrue(c.crossSubmitBoundary(nextReveal))
        assertNotNull(c.markNativeApplyReturned(nextReveal))
        assertTrue(c.revealSubmitted(nextReveal))
        assertNull(c.r30SealPresented(identity, authority, 108))
        assertNotNull(c.r30PresentedOwner(replacement, nextAuthority, nextHost, nextImage))
    }
}
