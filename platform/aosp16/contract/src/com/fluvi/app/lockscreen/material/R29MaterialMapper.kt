package com.fluvi.app.lockscreen.material

import com.fluvi.r29.contract.R29Material
import com.fluvi.r29.contract.R29Portal

/** Maps only canonical visual parameters. No scene identity or financial data crosses this boundary. */
internal object R29MaterialMapper {
    fun fromProfile(p: KeyguardMaterialProfile): R29Material = R29Material(
        effectId = p.effectId,
        effectShaderId = p.effectShaderId,
        phase = p.phase,
        elapsedSeconds = p.elapsedSeconds,
        phaseSpeed = p.phaseSpeed,
        colors = p.colors.toList(),
        stops = p.stops.toList(),
        opacity = p.opacity,
        paletteSplitPercent = p.paletteSplitPercent,
        commonSettings = p.commonSettings.toList(),
        background = fromPortal(p.background),
        interior = fromPortal(p.interior),
        referenceWidth = p.referenceWidth,
        referenceHeight = p.referenceHeight,
        schemaVersion = p.schemaVersion,
        shaderAbiVersion = p.shaderAbiVersion,
        sourceShaderHash = p.sourceShaderHash,
    )

    /** Call only after the complete descriptor, identity and freshness have been validated. */
    fun toProfile(m: R29Material, session: String, sequence: Long): KeyguardMaterialProfile =
        KeyguardMaterialProfile(
            schemaVersion = m.schemaVersion,
            shaderAbiVersion = m.shaderAbiVersion,
            sourceShaderHash = m.sourceShaderHash,
            publisherSession = session,
            publisherRevision = sequence,
            sceneIdentity = "r29:$sequence",
            effectId = m.effectId,
            effectShaderId = m.effectShaderId,
            phase = m.phase,
            elapsedSeconds = m.elapsedSeconds,
            phaseSpeed = m.phaseSpeed,
            colors = m.colors.toIntArray(),
            stops = m.stops.toFloatArray(),
            opacity = m.opacity,
            paletteSplitPercent = m.paletteSplitPercent,
            commonSettings = m.commonSettings.toFloatArray(),
            background = toPortal(m.background),
            interior = toPortal(m.interior),
            referenceWidth = m.referenceWidth,
            referenceHeight = m.referenceHeight,
        )

    private fun fromPortal(p: KeyguardMaterialPortal) = R29Portal(p.enabled, p.effectIndex, p.phase,
        p.phaseSpeed, p.paletteCenterPercent, p.paletteWindowPercent, p.rotationEnabled, p.rotationSpeed,
        p.settings.toList())

    private fun toPortal(p: R29Portal) = KeyguardMaterialPortal(p.enabled, p.effectIndex, p.phase,
        p.phaseSpeed, p.paletteCenterPercent, p.paletteWindowPercent, p.rotationEnabled, p.rotationSpeed,
        p.settings.toFloatArray())
}
