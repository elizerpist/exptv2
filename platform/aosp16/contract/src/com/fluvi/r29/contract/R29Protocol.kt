package com.fluvi.r29.contract

import java.util.Collections
import kotlin.math.roundToInt

/** Data-only contract: no labels, amounts, database rows, executable shader or URI. */
internal enum class R29Disclosure { FULL, NEUTRAL }
internal enum class R29Motion { LIVE, STATIC }
internal enum class R29Period { DAY, WEEK, MONTH, YEAR, ALL }

internal data class R29Portal(
    val enabled: Boolean,
    val effectIndex: Int,
    val phase: Float,
    val phaseSpeed: Float,
    val paletteCenterPercent: Float,
    val paletteWindowPercent: Float,
    val rotationEnabled: Boolean,
    val rotationSpeed: Float,
    val settings: List<Float>,
)

internal data class R29Material(
    val effectId: String,
    val effectShaderId: Int,
    val phase: Float,
    val elapsedSeconds: Float,
    val phaseSpeed: Float,
    val colors: List<Int>,
    val stops: List<Float>,
    val opacity: Float,
    val paletteSplitPercent: Float,
    val commonSettings: List<Float>,
    val background: R29Portal,
    val interior: R29Portal,
    val referenceWidth: Float,
    val referenceHeight: Float,
    val schemaVersion: Int = 1,
    val shaderAbiVersion: Int = 6,
    val sourceShaderHash: String = R29Protocol.SOURCE_SHADER_SHA256,
)

internal data class R29Descriptor(
    val session: String,
    val sequence: Long,
    val visualRevision: Long,
    val dataRevision: Long,
    val focusGeneration: Long,
    val layoutRevision: Long,
    val privacyRevision: Long,
    val validFromEpochMs: Long,
    val validUntilEpochMs: Long,
    val userId: Int,
    val displayId: Int,
    val displayWidth: Int,
    val displayHeight: Int,
    val densityDpi: Int,
    val orbSizePx: Int,
    val xFraction: Float,
    val yFraction: Float,
    val disclosure: R29Disclosure,
    val projectionCurrent: Boolean,
    val material: R29Material,
    val motion: R29Motion = R29Motion.LIVE,
    val period: R29Period = R29Period.MONTH,
    val timeZoneId: String = "UTC",
    val schemaVersion: Int = 1,
)

internal data class R29PublisherIdentity(
    val callingUid: Int,
    val packageUid: Int,
    val userId: Int,
    val packages: List<String>,
    val certificates: List<String>,
    val enrolled: Boolean,
    val debuggableHost: Boolean,
)

internal object R29Protocol {
    const val PUBLISHER_CERT_SHA256 = "faedbe8483532ebb1412bf4d8387c36ff6bbcd4b1da560ba0eabbaea9bad49fb"
    const val SOURCE_SHADER_SHA256 = "6be3e84d3e3ae6bffde549171b7319524768d67dbab1d55b74d565a4c76d4e7f"
    const val MAX_PARCEL_BYTES = 32 * 1024
    private val nonce = Regex("[0-9a-f]{32}")
    private val effects = listOf(
        "staticEffect", "dualTide", "magneticMembrane", "breathingLens", "cellularField",
        "balanceMembrane", "balanceCounterflow", "balanceCharges", "deepDrift", "freeFlow",
        "chaoticAdvection", "elasticSpace", "braidedCurrent", "volumetricCurrent", "metricBloom",
        "gravitationalFabric", "breathingMetric", "tidalCurvature",
    )

    fun validSession(value: String): Boolean = nonce.matches(value)

    fun trustedPublisher(identity: R29PublisherIdentity): Boolean =
        identity.debuggableHost && identity.enrolled && identity.userId == 0 &&
            identity.callingUid >= 0 && identity.callingUid == identity.packageUid &&
            identity.packages == listOf("com.fluvi.app") &&
            identity.certificates == listOf(PUBLISHER_CERT_SHA256)

    /** parcelBytes must come from the receiving Binder's actual Parcel, not from the sender. */
    fun invalidReason(value: R29Descriptor, nowEpochMs: Long, parcelBytes: Int): String? {
        if (parcelBytes !in 1..MAX_PARCEL_BYTES) return "parcelSize"
        if (value.schemaVersion != 1 || !validSession(value.session) || value.sequence <= 0) return "sessionOrSchema"
        if (value.visualRevision < 0 || value.dataRevision <= 0 || value.focusGeneration < 0 ||
            value.layoutRevision < 0 || value.privacyRevision < 0) return "revision"
        if (value.validFromEpochMs <= 0 || value.validUntilEpochMs <= value.validFromEpochMs ||
            nowEpochMs < value.validFromEpochMs || nowEpochMs >= value.validUntilEpochMs) return "validity"
        if (value.timeZoneId.length !in 1..64 || !value.timeZoneId.all { it.isLetterOrDigit() || it in "_+/-" }) return "timeZone"
        if (value.userId != 0 || value.displayId != 0) return "userOrDisplay"
        if (value.displayWidth !in 320..8192 || value.displayHeight !in 320..8192 ||
            value.displayWidth >= value.displayHeight || value.densityDpi !in 72..1000) return "display"
        if (value.orbSizePx != (64f * value.densityDpi / 160f).roundToInt() ||
            value.orbSizePx > minOf(value.displayWidth, value.displayHeight)) return "orbSize"
        if (!value.xFraction.isFinite() || !value.yFraction.isFinite() ||
            value.xFraction !in 0f..1f || value.yFraction !in 0f..1f) return "position"
        if (value.disclosure == R29Disclosure.FULL && !value.projectionCurrent) return "projection"
        return invalidMaterial(value.material)
    }

    private fun invalidMaterial(m: R29Material): String? {
        if (m.schemaVersion != 1 || m.shaderAbiVersion != 6 || m.sourceShaderHash != SOURCE_SHADER_SHA256 ||
            effects.getOrNull(m.effectShaderId) != m.effectId) return "materialSchema"
        if (!m.phase.isFinite() || !m.elapsedSeconds.isFinite() || m.elapsedSeconds < 0f ||
            !m.phaseSpeed.isFinite() || m.phaseSpeed < 0f || !m.opacity.isFinite() || m.opacity !in 0f..1f ||
            !m.paletteSplitPercent.isFinite() || m.paletteSplitPercent !in 0f..100f) return "materialRange"
        if (!m.referenceWidth.isFinite() || m.referenceWidth <= 0f || m.referenceWidth > 10000f ||
            !m.referenceHeight.isFinite() || m.referenceHeight <= 0f || m.referenceHeight > 10000f) return "referenceSize"
        if (m.colors.size !in 2..10 || m.stops.size != m.colors.size ||
            m.stops.indices.any { i -> !m.stops[i].isFinite() || m.stops[i] !in 0f..1f ||
                (i > 0 && m.stops[i] < m.stops[i - 1]) }) return "palette"
        if (m.commonSettings.size != 40 || m.commonSettings.any { !it.isFinite() }) return "settings"
        if (!validPortal(m.background) || !validPortal(m.interior)) return "portal"
        return null
    }

    private fun validPortal(p: R29Portal): Boolean = p.effectIndex in 0..4 && p.phase.isFinite() &&
        p.phaseSpeed.isFinite() && p.phaseSpeed >= 0f && p.paletteCenterPercent.isFinite() &&
        p.paletteCenterPercent in 0f..100f && p.paletteWindowPercent.isFinite() &&
        p.paletteWindowPercent in 10f..100f && p.rotationSpeed.isFinite() && p.rotationSpeed in 0f..100f &&
        p.settings.size == 12 && p.settings.all { it.isFinite() }

    fun immutable(value: R29Descriptor): R29Descriptor {
        fun <T> frozen(values: List<T>): List<T> = Collections.unmodifiableList(ArrayList(values))
        fun portal(value: R29Portal) = value.copy(settings = frozen(value.settings))
        val m = value.material
        return value.copy(material = m.copy(colors = frozen(m.colors), stops = frozen(m.stops),
            commonSettings = frozen(m.commonSettings), background = portal(m.background), interior = portal(m.interior)))
    }
}
