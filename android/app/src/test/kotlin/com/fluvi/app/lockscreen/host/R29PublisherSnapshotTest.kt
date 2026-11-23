package com.fluvi.app.lockscreen.host

import com.fluvi.app.lockscreen.KeyguardCardAnimationMode
import com.fluvi.app.lockscreen.KeyguardCardFocus
import com.fluvi.app.lockscreen.KeyguardCardPresentationMode
import com.fluvi.app.lockscreen.KeyguardCardSettings
import com.fluvi.app.lockscreen.material.KeyguardMaterialPortal
import com.fluvi.app.lockscreen.material.KeyguardMaterialProfile
import com.fluvi.app.runtime.FluviKeyguardMaterialSceneTarget
import com.fluvi.app.runtime.FluviLockScreenCardConfiguration
import com.fluvi.r29.contract.R29Disclosure
import com.fluvi.r29.contract.R29Motion
import com.fluvi.r29.contract.R29Period
import org.junit.Assert.*
import org.junit.Test

class R29PublisherSnapshotTest {
    private val now = 1_700_000_000_000L
    private val nonce = "0123456789abcdef0123456789abcdef"
    private val focus = KeyguardCardFocus(mode = FluviLockScreenCardConfiguration.Mode.budget,
        timeAxis = FluviLockScreenCardConfiguration.TimeAxis.month,
        direction = FluviLockScreenCardConfiguration.Direction.expense, categoryId = "private-category", generation = 2)
    private val settings = KeyguardCardSettings(requested = true, showFinancialDetails = true,
        presentationMode = KeyguardCardPresentationMode.ORB, focus = focus, layoutRevision = 4, generation = 5)
    private val target = FluviKeyguardMaterialSceneTarget(focus.mode, focus.timeAxis, focus.direction,
        focus.categoryId, "blue", 55.0, true, focus.generation, coreRevision = 7)
    private val portal = KeyguardMaterialPortal(false, 0, 0f, 0f, 50f, 68f, false, 0f, FloatArray(12))
    private val profile = KeyguardMaterialProfile(1, 6, KeyguardMaterialProfile.SOURCE_SHADER_HASH,
        "flutter-session", 42, "budget|month|expense|private-category|2", "deepDrift", 8, .3f, 11f, .5f,
        intArrayOf(0xff123456.toInt(), 0xffabcdef.toInt()), floatArrayOf(0f, 1f), .7f, 60f,
        FloatArray(40), portal, portal, 1080f, 2400f)
    private val evidence = R29ProjectionEvidence(7, 7, 7, 2, 4, 5, true, now - 1_000, now + 60_000,
        "Europe/Budapest", R29Period.MONTH)
    private val geometry = R29Geometry(0, 0, 1080, 2400, 420, 168, .5f, .8f)

    private fun create(profile: KeyguardMaterialProfile = this.profile,
        target: FluviKeyguardMaterialSceneTarget = this.target,
        settings: KeyguardCardSettings = this.settings,
        evidence: R29ProjectionEvidence = this.evidence,
        geometry: R29Geometry = this.geometry) =
        R29PublisherSnapshot.create(nonce, 1, profile, target, settings, evidence, geometry, now)

    @Test fun currentProjectionProducesDataOnlyFullMaterial() {
        val value = requireNotNull(create())
        assertEquals(R29Disclosure.FULL, value.disclosure)
        assertEquals(R29Motion.LIVE, value.motion)
        assertEquals(7L, value.dataRevision)
        assertEquals(2L, value.focusGeneration)
        assertFalse(value.toString().contains("private-category"))
        assertFalse(value.toString().contains("55.0"))
        assertEquals(profile.colors.toList(), value.material.colors)
    }

    @Test fun staleDataScopeOrPeriodCannotProduceFull() {
        assertNull(create(evidence = evidence.copy(currentCoreRevision = 8)))
        assertNull(create(evidence = evidence.copy(visualCoreRevision = 8)))
        assertNull(create(evidence = evidence.copy(targetCoreRevision = 0)))
        assertNull(create(evidence = evidence.copy(visualFocusGeneration = 3)))
        assertNull(create(evidence = evidence.copy(visualLayoutRevision = 5)))
        assertNull(create(evidence = evidence.copy(visualPrivacyRevision = 6)))
        assertNull(create(evidence = evidence.copy(visualProjectionFull = false)))
        assertNull(create(evidence = evidence.copy(validUntilEpochMs = now)))
        assertNull(create(evidence = evidence.copy(period = R29Period.DAY)))
        assertNull(create(target = target.copy(focusGeneration = 3)))
        assertNull("target must be bound to the same core revision", create(target = target.copy(coreRevision = 8)))
        assertNull("missing target revision is not current", create(target = target.copy(coreRevision = null)))
        assertNull(create(profile = profile.copy(sceneIdentity = "budget|month|expense|old|2")))
        assertNull(create(settings = settings.copy(requested = false)))
        assertNull(create(geometry = geometry.copy(displayId = 1)))
    }

    @Test fun unavailableOrPrivateProjectionIsExplicitlyNeutral() {
        for (candidate in listOf(create(settings = settings.copy(showFinancialDetails = false)),
                create(target = target.copy(projectionAvailable = false)))) {
            val value = requireNotNull(candidate)
            assertEquals(R29Disclosure.NEUTRAL, value.disclosure)
            assertEquals(profile.neutralized().colors.toList(), value.material.colors)
            assertNotEquals(profile.colors.toList(), value.material.colors)
        }
    }

    @Test fun reducedMotionIsRepresentedWithoutInventingAnotherPalette() {
        val value = requireNotNull(create(settings = settings.copy(animationMode = KeyguardCardAnimationMode.OFF)))
        assertEquals(R29Motion.STATIC, value.motion)
        assertEquals(profile.colors.toList(), value.material.colors)
    }
}
