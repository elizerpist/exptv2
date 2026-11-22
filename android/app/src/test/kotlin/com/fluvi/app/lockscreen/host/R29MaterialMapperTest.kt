package com.fluvi.app.lockscreen.host

import com.fluvi.app.lockscreen.material.KeyguardMaterialPortal
import com.fluvi.app.lockscreen.material.KeyguardMaterialProfile
import com.fluvi.app.lockscreen.material.R29MaterialMapper
import org.junit.Assert.*
import org.junit.Test

class R29MaterialMapperTest {
    private val portal = KeyguardMaterialPortal(true, 2, .8f, .2f, 55f, 70f, true, 15f, FloatArray(12) { it / 20f })
    private val profile = KeyguardMaterialProfile(1, 6, KeyguardMaterialProfile.SOURCE_SHADER_HASH,
        "flutter-session", 42, "budget|month|expense|private-category|2", "deepDrift", 8, .3f, 11f, .5f,
        intArrayOf(0xff123456.toInt(), 0xffabcdef.toInt()), floatArrayOf(0f, 1f), .7f, 60f,
        FloatArray(40) { it / 40f }, portal, portal.copy(enabled = false), 1080f, 2400f)

    @Test fun preservesAllCanonicalInputsWithoutLeakingSceneIdentity() {
        val material = R29MaterialMapper.fromProfile(profile)
        val result = R29MaterialMapper.toProfile(material, "0123456789abcdef0123456789abcdef", 17)
        assertEquals(profile.effectId, result.effectId)
        assertEquals(profile.effectShaderId, result.effectShaderId)
        assertEquals(profile.phase, result.phase, 0f)
        assertEquals(profile.elapsedSeconds, result.elapsedSeconds, 0f)
        assertEquals(profile.phaseSpeed, result.phaseSpeed, 0f)
        assertArrayEquals(profile.colors, result.colors)
        assertArrayEquals(profile.stops, result.stops, 0f)
        assertArrayEquals(profile.commonSettings, result.commonSettings, 0f)
        assertArrayEquals(profile.background.settings, result.background.settings, 0f)
        assertArrayEquals(profile.interior.settings, result.interior.settings, 0f)
        assertEquals(profile.background.phase, result.background.phase, 0f)
        assertEquals(profile.interior.phaseSpeed, result.interior.phaseSpeed, 0f)
        assertEquals(profile.opacity, result.opacity, 0f)
        assertEquals(profile.paletteSplitPercent, result.paletteSplitPercent, 0f)
        assertEquals(profile.referenceWidth, result.referenceWidth, 0f)
        assertEquals(profile.referenceHeight, result.referenceHeight, 0f)
        assertFalse(material.toString().contains("private-category"))
        assertFalse(result.sceneIdentity.contains("private-category"))
    }

    @Test fun mappedMaterialHasNoSharedPublisherArrays() {
        val value = profile.copy(colors = profile.colors.copyOf(), stops = profile.stops.copyOf(),
            commonSettings = profile.commonSettings.copyOf(),
            background = profile.background.copy(settings = profile.background.settings.copyOf()))
        val mapped = R29MaterialMapper.fromProfile(value)
        val firstColor = mapped.colors[0]
        val firstStop = mapped.stops[0]
        val firstCommon = mapped.commonSettings[0]
        val firstPortal = mapped.background.settings[0]
        value.colors[0] = 0
        value.stops[0] = .4f
        value.commonSettings[0] = 4f
        value.background.settings[0] = 4f
        assertEquals(firstColor, mapped.colors[0])
        assertEquals(firstStop, mapped.stops[0], 0f)
        assertEquals(firstCommon, mapped.commonSettings[0], 0f)
        assertEquals(firstPortal, mapped.background.settings[0], 0f)
    }
}
