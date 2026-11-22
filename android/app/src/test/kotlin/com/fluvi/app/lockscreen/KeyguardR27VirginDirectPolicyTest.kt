package com.fluvi.app.lockscreen

import org.junit.Assert.*
import org.junit.Test

class KeyguardR27VirginDirectPolicyTest {
    private val authority = KeyguardInspectionAuthority(1, 2, 3, 4, 5)
    private val request = KeyguardCardInspectionRequest(11, "wake", 1, 2, 4, 5, 3, 100)
    private val prep = KeyguardCardWindow.R18Preparation(5, 22, true, "fixture", 168, 168, 420, true)
    private val stamp = KeyguardOrbPresentationStamp(authority, 11, 7, 1, 2,
        prep.width, prep.height, prep.densityDpi, true, 21, prep.outputGeneration, 0)
    private val coordinator = KeyguardOrbPresentationCoordinator()
    private val previous = authority.copy(wakeGeneration = 2)
    private val token = checkNotNull(coordinator.reserve(stamp, 1, previous, previous, true, true))

    private fun matches(active: KeyguardOrbPresentationCoordinator.Reservation? = null,
                        activePrep: KeyguardCardWindow.R18Preparation? = null,
                        provisional: KeyguardOrbPresentationCoordinator.Reservation? = null,
                        provisionalPrep: KeyguardCardWindow.R18Preparation? = null,
                        route: KeyguardCardWindow.R18Preparation? = null,
                        revision: Long = 7,
                        request: KeyguardCardInspectionRequest = this.request) =
        KeyguardR27VirginDirectPolicy.matches(request, coordinator.snapshot(), revision,
            active, activePrep, provisional, provisionalPrep, route)

    @Test fun reservedBeforeMainAdoptionRetainsExactVirginTarget() {
        assertTrue(matches(provisional = token, provisionalPrep = prep))
        assertFalse(matches(provisionalPrep = prep))
        assertFalse(matches(provisional = token, provisionalPrep = prep.copy(outputGeneration = 23)))
    }

    @Test fun adoptedBeforeOwnerPublicationUsesOnlyExactRetainedRoute() {
        assertTrue(coordinator.adopt(token, stamp))
        assertTrue(matches(route = prep))
        assertFalse(matches(route = null))
        assertFalse(matches(route = prep.copy(width = 169)))
        assertTrue(matches(active = token, activePrep = prep))
    }

    @Test fun staleOwnerRouteAuthorityOrNonVirginPreparationCannotTransfer() {
        val otherCoordinator = KeyguardOrbPresentationCoordinator()
        val otherToken = checkNotNull(otherCoordinator.reserve(stamp, 2, previous, previous, true, true))
        assertFalse(matches(active = otherToken, activePrep = prep, provisional = token, provisionalPrep = prep))
        assertFalse(matches(provisional = otherToken, provisionalPrep = prep))
        assertFalse(matches(provisional = token, provisionalPrep = prep, revision = 8))
        assertFalse(matches(provisional = token, provisionalPrep = prep,
            request = request.copy(wakeGeneration = 9)))
        assertFalse(matches(provisional = token, provisionalPrep = prep,
            request = request.copy(id = 12)))
        assertFalse(matches(provisional = token, provisionalPrep = prep.copy(full = false)))
        assertFalse(matches(provisional = token, provisionalPrep = prep.copy(emptyAwaitingDisclosure = false)))
    }
}
