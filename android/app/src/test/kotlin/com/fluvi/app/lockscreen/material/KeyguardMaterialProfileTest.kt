package com.fluvi.app.lockscreen.material

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

class KeyguardMaterialProfileTest {
    private fun profile(
        session: String = "publisher-a",
        revision: Long = 4L,
        speed: Double = .3,
    ): Map<String, Any?> = mapOf(
        "schemaVersion" to 1,
        "shaderAbiVersion" to 6,
        "sourceShaderHash" to KeyguardMaterialProfile.SOURCE_SHADER_HASH,
        "publisherSession" to session,
        "publisherRevision" to revision,
        "sceneIdentity" to "budget|month|expense|food|$revision",
        "effectId" to "deepDrift",
        "effectShaderId" to 8,
        "phase" to .5,
        "elapsedSeconds" to 8.0,
        "phaseSpeed" to speed,
        "colors" to listOf(0xff102030.toInt(), 0xff405060.toInt(), 0xff708090.toInt()),
        "stops" to listOf(0.0, .5, 1.0),
        "opacity" to 1.0,
        "paletteSplitPercent" to 50.0,
        "commonSettings" to List(40) { .2 },
        "background" to mapOf("enabled" to true, "effectIndex" to 2, "phase" to .2, "phaseSpeed" to .4, "paletteCenterPercent" to 50.0, "paletteWindowPercent" to 68.0, "rotationEnabled" to false, "rotationSpeed" to 0.0, "settings" to List(12) { 0.0 }),
        "interior" to mapOf("enabled" to false, "effectIndex" to 0, "phase" to 0.0, "phaseSpeed" to 0.0, "paletteCenterPercent" to 50.0, "paletteWindowPercent" to 68.0, "rotationEnabled" to false, "rotationSpeed" to 0.0, "settings" to List(12) { 0.0 }),
        "referenceWidth" to 390.0,
        "referenceHeight" to 220.0,
    )

    @Test fun `accepts bounded v6 profile and preserves portal clock`() {
        val value = KeyguardMaterialProfile.fromMap(profile())
        assertNotNull(value)
        requireNotNull(value)
        assertEquals(40, value.commonSettings.size)
        assertEquals(.4f, value.background.phaseSpeed, 0f)
        assertTrue(value.animated)
    }

    @Test fun `rejects source or ABI mismatch rather than rendering guessed uniforms`() {
        assertEquals(null, KeyguardMaterialProfile.fromMap(profile().plus("sourceShaderHash" to "wrong")))
        assertEquals(null, KeyguardMaterialProfile.fromMap(profile().plus("shaderAbiVersion" to 5)))
    }

    @Test fun `neutral profile removes financial palette while retaining animation grammar`() {
        val value = requireNotNull(KeyguardMaterialProfile.fromMap(profile()))
        val neutral = value.neutralized()
        assertFalse(neutral.colors.contentEquals(value.colors))
        assertEquals(value.effectId, neutral.effectId)
        assertEquals(value.commonSettings.toList(), neutral.commonSettings.toList())
    }

    @Test fun `scene time preserves phase speed without a finite loop`() {
        val value = requireNotNull(KeyguardMaterialProfile.fromMap(profile(speed = .25)))
        val scene = KeyguardMaterialScene(value, full = true, appliedAtNanos = 1_000_000_000L)
        assertEquals(.5f + .25f * 9f, scene.timeAt(10_000_000_000L).phase, 0f)
    }
}
