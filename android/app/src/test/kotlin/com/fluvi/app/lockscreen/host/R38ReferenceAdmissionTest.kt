package com.fluvi.app.lockscreen.host

import org.junit.Assert.*
import org.junit.Test

class R38ReferenceAdmissionTest {
    private class Store : R29Ownership.Store {
        var value = R29Ownership.Persisted(false, 0)
        var allow = true
        override fun read() = value
        override fun write(value: R29Ownership.Persisted): Boolean {
            if (!allow) return false
            this.value = value
            return true
        }
    }
    private val clean = R38ReferenceAdmission.Evidence(
        trustedHost = true, firstServiceOnFreshInstall = true, unlocked = true,
        noLocalPresentation = true, noReservation = true, noOwnedOutput = true,
    )

    @Test fun verifiedFreshEmptyOwnerIsSuppressedBeforeHostMayConnect() {
        val store = Store(); val ownership = R29Ownership(store)
        val admission = R38ReferenceAdmission(ownership)
        val epoch = admission.begin(clean)
        assertNotNull(epoch)
        assertTrue(store.value.suppressed)
        assertFalse(ownership.appMayShow())
        assertTrue(ownership.hostMayBeRequested())
        assertTrue(ownership.hostOwns(requireNotNull(epoch)))
        assertNull(admission.begin(clean))
    }

    @Test fun missingTrustUnlockedStateOrAnyPriorOwnerPreventsSuppression() {
        val cases = listOf(clean.copy(trustedHost = false), clean.copy(firstServiceOnFreshInstall = false),
            clean.copy(unlocked = false), clean.copy(noLocalPresentation = false),
            clean.copy(noReservation = false), clean.copy(noOwnedOutput = false))
        for (input in cases) {
            val store = Store(); val ownership = R29Ownership(store)
            assertNull(R38ReferenceAdmission(ownership).begin(input))
            assertTrue(ownership.appMayShow())
            assertFalse(ownership.hostMayBeRequested())
            assertFalse(store.value.suppressed)
        }
    }

    @Test fun failedDurableSuppressionNeverConnectsHost() {
        val store = Store().apply { allow = false }; val ownership = R29Ownership(store)
        assertNull(R38ReferenceAdmission(ownership).begin(clean))
        assertTrue(ownership.appMayShow())
        assertFalse(ownership.hostMayBeRequested())
    }

    @Test fun lostHostNeverReactivatesLocalPixelsWithoutMatchingEmpty() {
        val store = Store(); val ownership = R29Ownership(store)
        val epoch = requireNotNull(R38ReferenceAdmission(ownership).begin(clean))
        assertTrue(ownership.hostOwns(epoch))
        ownership.hostUnavailable(epoch)
        assertFalse(ownership.appMayShow())
        assertFalse(R29Ownership(store).appMayShow())
    }

    @Test fun racingOldOwnerAfterSuppressionRemainsBlockedWithoutConnecting() {
        val store = Store(); val ownership = R29Ownership(store)
        assertNull(R38ReferenceAdmission(ownership).begin(clean) { false })
        assertTrue(store.value.suppressed)
        assertFalse(ownership.appMayShow())
        assertFalse(ownership.hostMayBeRequested())
    }
}
