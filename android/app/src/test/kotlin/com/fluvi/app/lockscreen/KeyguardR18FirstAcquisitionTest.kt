package com.fluvi.app.lockscreen

import org.junit.Assert.*
import org.junit.Test

/** These controls exercise the actual call adapter and scalar opportunity;
 * neither a short root read nor a submitted frame proves physical output. */
class KeyguardR18FirstAcquisitionTest {
    private val owner = KeyguardInspectionAuthority(1, 2, 3, 4, 5)
    private fun request(id: Long, authority: KeyguardInspectionAuthority = owner) =
        KeyguardCardInspectionRequest(id, "wake", authority.serviceSession, authority.visibilityEpoch,
            authority.interactionEpoch, authority.attachGeneration, authority.wakeGeneration, id)
    private fun ticket(authority: KeyguardInspectionAuthority = owner) =
        KeyguardInspectionFreshness.Ticket(authority, 1L, KeyguardWindowFreshness.LIFECYCLE_BOUNDARY)

    @Test fun firstEligiblePhysicalRootUsesHybridAndChildrenRemainBatched() {
        val gate = KeyguardFirstAcquisition().also { it.begin(owner, true) }
        val calls = mutableListOf<String>()
        fun root(id: Long): String? {
            val strategy = if (gate.take(request(id), ticket())) KeyguardActiveRootStrategy.R18_INITIAL_HYBRID
                else KeyguardActiveRootStrategy.STOCK
            return KeyguardWindowAcquisitionCalls.activeRoot(strategy, 35) { flags ->
                calls += "root:$flags"; if (id == 1L) null else "root"
            }
        }
        assertNull(root(1)) // an actual null return still consumes this wake
        assertEquals("root", root(2))
        KeyguardWindowAcquisitionCalls.child(36, 35, { calls += "child:$it" }, { calls += "fallback" })
        assertEquals(listOf("root:4", "root:36", "child:36"), calls)
    }

    @Test fun emptyInventoryAndFallbackDoNotConsumeThePhysicalRootOpportunity() {
        val gate = KeyguardFirstAcquisition().also { it.begin(owner, true) }
        val calls = mutableListOf<String>()
        // Both cases use the reader's actual gating policy; no root callback
        // is invoked before a valid active, primary candidate exists.
        val empty = KeyguardWindowSnapshotReaderPolicy.activeCandidate(emptyList(), null, owner.attachGeneration)
        assertNull(empty)
        assertFalse(KeyguardWindowSnapshotReaderPolicy.canUseBatchedActiveRoot(35, true, false, true))
        assertFalse(KeyguardWindowSnapshotReaderPolicy.canUseBatchedActiveRoot(35, false, true, true))
        calls += "fallback:window.root"
        val strategy = if (gate.take(request(2), ticket())) KeyguardActiveRootStrategy.R18_INITIAL_HYBRID
            else KeyguardActiveRootStrategy.STOCK
        KeyguardWindowAcquisitionCalls.activeRoot(strategy, 35) { calls += "root:$it" }
        assertEquals(listOf("fallback:window.root", "root:4"), calls)
    }

    @Test fun staleWakeAndInvalidatedEligibilityCannotSpendTheNextWake() {
        val gate = KeyguardFirstAcquisition().also { it.begin(owner, true) }
        val later = owner.copy(wakeGeneration = owner.wakeGeneration + 1)
        gate.begin(later, true)
        assertFalse(gate.take(request(1), ticket(owner)))
        assertTrue(gate.take(request(2, later), ticket(later)))
        val next = later.copy(wakeGeneration = later.wakeGeneration + 1)
        gate.begin(next, true)
        gate.invalidate()
        assertFalse(gate.take(request(3, next), ticket(next)))
    }

    @Test fun non35AndHistoricalPathsKeepTheirSeparateArguments() {
        assertEquals(36, KeyguardWindowSnapshotReaderPolicy.activeRootPrefetchFlags(KeyguardActiveRootStrategy.R18_INITIAL_HYBRID, 34))
        assertEquals(4, KeyguardWindowSnapshotReaderPolicy.activeRootPrefetchFlags(KeyguardActiveRootStrategy.R18_INITIAL_HYBRID, 35))
        assertEquals(36, KeyguardWindowSnapshotReaderPolicy.activeRootPrefetchFlags(KeyguardActiveRootStrategy.STOCK, 35))
        assertEquals(0, KeyguardWindowSnapshotReaderPolicy.activeRootPrefetchFlags(KeyguardActiveRootStrategy.R15_HISTORICAL_ZERO, 35))
    }

    @Test fun strictOwnAttributionDoesNotUseAnUnidentifiedActiveOverlay() {
        val overlay = KeyguardWindowReaderWindowMetadata(17, 4, 0, true)
        val system = KeyguardWindowReaderWindowMetadata(18, 1, 0, true)
        assertFalse(KeyguardWindowSnapshotReaderPolicy.canUseCandidateWithStrictOwnAttribution(true, overlay))
        assertTrue(KeyguardWindowSnapshotReaderPolicy.canUseCandidateWithStrictOwnAttribution(true, system))
        assertTrue(KeyguardWindowSnapshotReaderPolicy.canUseCandidateWithStrictOwnAttribution(false, overlay))
    }

    @Test fun earlyExclusionPredicatesMatchTheExistingClassifierPriority() {
        val decisive = listOf("com.android.systemui:id/keyguard_security_container",
            "com.android.systemui:id/quick_settings_panel", "com.android.systemui:id/global_actions_container",
            "element:BouncerContent")
        decisive.forEach { assertTrue(it, KeyguardSurfaceClassifier.isDecisiveExclusionMarker(it)) }
        assertFalse(KeyguardSurfaceClassifier.isDecisiveExclusionMarker("com.android.systemui:id/keyguard_clock_switch"))
        assertFalse(KeyguardSurfaceClassifier.isDecisiveExclusionMarker("com.example:id/ordinary"))
    }

    @Test fun strictClassificationDoesNotIgnoreAnExternalSamePackageWindow() {
        val system = KeyguardWindowSnapshot("com.android.systemui", 1, 10, 0,
            visibleViewIds = setOf("com.android.systemui:id/keyguard_clock_switch"))
        val otherFluvi = KeyguardWindowSnapshot("com.fluvi.app", 1, 11, 0, ownOverlay = false)
        assertEquals(KeyguardSurface.MAIN_KEYGUARD,
            KeyguardSurfaceClassifier.classifyDetailed(listOf(system, otherFluvi)).surface)
        assertEquals(KeyguardSurface.OCCLUDED,
            KeyguardSurfaceClassifier.classifyDetailed(listOf(system, otherFluvi), strictOwnAttribution = true).surface)
        val exactOwn = otherFluvi.copy(type = 4, ownOverlay = true)
        assertEquals(KeyguardSurface.MAIN_KEYGUARD,
            KeyguardSurfaceClassifier.classifyDetailed(listOf(system, exactOwn), strictOwnAttribution = true).surface)
    }
}
