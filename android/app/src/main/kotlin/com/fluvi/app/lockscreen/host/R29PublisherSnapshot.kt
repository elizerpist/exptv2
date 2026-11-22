package com.fluvi.app.lockscreen.host

import com.fluvi.app.lockscreen.KeyguardCardAnimationMode
import com.fluvi.app.lockscreen.KeyguardCardPresentationMode
import com.fluvi.app.lockscreen.KeyguardCardSettings
import com.fluvi.app.lockscreen.material.KeyguardMaterialProfile
import com.fluvi.app.lockscreen.material.R29MaterialMapper
import com.fluvi.app.runtime.FluviKeyguardMaterialSceneTarget
import com.fluvi.app.runtime.FluviLockScreenCardConfiguration
import com.fluvi.r29.contract.R29Descriptor
import com.fluvi.r29.contract.R29Disclosure
import com.fluvi.r29.contract.R29Motion
import com.fluvi.r29.contract.R29Period
import com.fluvi.r29.contract.R29Protocol

/** The three revisions must be captured at their real source, not inferred from preferences. */
internal data class R29ProjectionEvidence(
    val targetCoreRevision: Long,
    val visualCoreRevision: Long,
    val currentCoreRevision: Long,
    val visualFocusGeneration: Long,
    val visualLayoutRevision: Long,
    val visualPrivacyRevision: Long,
    val visualProjectionFull: Boolean,
    val validFromEpochMs: Long,
    val validUntilEpochMs: Long,
    val timeZoneId: String,
    val period: R29Period,
)

internal data class R29Geometry(
    val userId: Int,
    val displayId: Int,
    val width: Int,
    val height: Int,
    val densityDpi: Int,
    val orbSizePx: Int,
    val xTravelFraction: Float,
    val yTravelFraction: Float,
)

/** Builds a bounded data-only descriptor only from one proven projection and current settings. */
internal object R29PublisherSnapshot {
    fun create(
        session: String,
        sequence: Long,
        profile: KeyguardMaterialProfile,
        target: FluviKeyguardMaterialSceneTarget,
        settings: KeyguardCardSettings,
        evidence: R29ProjectionEvidence,
        geometry: R29Geometry,
        nowEpochMs: Long,
    ): R29Descriptor? {
        if (!settings.requested || settings.presentationMode != KeyguardCardPresentationMode.ORB ||
            !settings.focus.isValid || target.focusGeneration != settings.focus.generation ||
            target.mode != settings.focus.mode || target.timeAxis != settings.focus.timeAxis ||
            target.direction != settings.focus.direction || target.categoryId != settings.focus.categoryId ||
            evidence.targetCoreRevision <= 0 || evidence.targetCoreRevision != evidence.visualCoreRevision ||
            evidence.targetCoreRevision != evidence.currentCoreRevision ||
            evidence.visualFocusGeneration != settings.focus.generation ||
            evidence.visualLayoutRevision != settings.layoutRevision ||
            evidence.visualPrivacyRevision != settings.generation ||
            (settings.showFinancialDetails && target.projectionAvailable && !evidence.visualProjectionFull)) return null
        val expectedPeriod = when (target.timeAxis) {
            FluviLockScreenCardConfiguration.TimeAxis.sum -> R29Period.ALL
            FluviLockScreenCardConfiguration.TimeAxis.year -> R29Period.YEAR
            FluviLockScreenCardConfiguration.TimeAxis.month -> R29Period.MONTH
            FluviLockScreenCardConfiguration.TimeAxis.day -> R29Period.DAY
        }
        if (evidence.period != expectedPeriod) return null
        // This identity remains local: it may contain a category ID.
        val expectedScene = listOf(target.mode.name, target.timeAxis.name, target.direction.name,
            target.categoryId, target.focusGeneration).joinToString("|")
        if (profile.sceneIdentity != expectedScene) return null
        val full = settings.showFinancialDetails && target.projectionAvailable
        val permittedProfile = if (full) profile else profile.neutralized()
        val descriptor = R29Descriptor(
            session = session,
            sequence = sequence,
            visualRevision = profile.publisherRevision,
            dataRevision = evidence.currentCoreRevision,
            focusGeneration = target.focusGeneration,
            layoutRevision = settings.layoutRevision,
            privacyRevision = settings.generation,
            validFromEpochMs = evidence.validFromEpochMs,
            validUntilEpochMs = evidence.validUntilEpochMs,
            userId = geometry.userId,
            displayId = geometry.displayId,
            displayWidth = geometry.width,
            displayHeight = geometry.height,
            densityDpi = geometry.densityDpi,
            orbSizePx = geometry.orbSizePx,
            xFraction = geometry.xTravelFraction,
            yFraction = geometry.yTravelFraction,
            disclosure = if (full) R29Disclosure.FULL else R29Disclosure.NEUTRAL,
            projectionCurrent = target.projectionAvailable,
            material = R29MaterialMapper.fromProfile(permittedProfile),
            motion = if (settings.animationMode == KeyguardCardAnimationMode.OFF || !permittedProfile.animated)
                R29Motion.STATIC else R29Motion.LIVE,
            period = evidence.period,
            timeZoneId = evidence.timeZoneId,
        )
        return descriptor.takeIf { R29Protocol.invalidReason(it, nowEpochMs, 1) == null }
    }
}
