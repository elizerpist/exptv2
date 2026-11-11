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

    @Test fun `rejects empty or malformed palette rather than manufacturing zero uniforms`() {
        assertEquals(null, KeyguardMaterialProfile.fromMap(profile().plus("colors" to emptyList<Int>())))
        assertEquals(null, KeyguardMaterialProfile.fromMap(profile().plus("stops" to listOf(0.0, 1.2, 1.0))))
        assertEquals(null, KeyguardMaterialProfile.fromMap(profile().plus("commonSettings" to List(39) { 0.0 })))
    }

    @Test fun `rejects effect names that do not match their stable shader id`() {
        assertEquals(
            null,
            KeyguardMaterialProfile.fromMap(profile().plus("effectShaderId" to 7)),
        )
        assertEquals(
            null,
            KeyguardMaterialProfile.fromMap(profile().plus("effectId" to "unknownEffect")),
        )
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
        assertEquals(.5f + .25f * 9f, scene.timeAt(10_000_000_000L).phase, .0001f)
    }

    @Test fun `scene time derives deltas from one nanosecond timebase`() {
        val value = requireNotNull(KeyguardMaterialProfile.fromMap(profile(speed = .25)))
        val scene = KeyguardMaterialScene(value, full = true, appliedAtNanos = 9_000_000_000_000L)
        val before = scene.timeAt(9_000_000_000_000L)
        val after = scene.timeAt(9_001_000_000_000L)
        assertEquals(0.25f, after.phase - before.phase, .0001f)
        assertEquals(1f, after.elapsedSeconds - before.elapsedSeconds, .0001f)
    }

    @Test fun `old publication retirement cannot revoke a newer exact grant`() {
        val grants = KeyguardOrbPublicationGrantStore<Any>()
        val oldGrant = Any()
        val newGrant = Any()
        grants.install(oldGrant)
        grants.install(newGrant)

        assertFalse("queued retirement of A must not clear B", grants.revokeExact(oldGrant))
        assertTrue("B grant must survive A retirement", grants.current() === newGrant)
        assertTrue(grants.revokeExact(newGrant))
        assertEquals(null, grants.current())
    }

    @Test fun `early null fence receipt remains present until exact use consumes it`() {
        val receipts = KeyguardOrbEarlyReleaseReceiptStore<Any>()
        val exactUse = 7L to 11L
        assertTrue(receipts.record(exactUse, null))
        assertFalse("duplicate callback cannot replace the first receipt", receipts.record(exactUse, Any()))

        val receipt = requireNotNull(receipts.take(exactUse))
        assertEquals(null, receipt.value)
        assertEquals(null, receipts.take(exactUse))
        assertEquals(null, receipts.take(7L to 12L))
    }

    @Test fun `new bridge session accepts revision one but old session cannot overwrite it`() {
        assertTrue(
            KeyguardMaterialPublicationOrder.accepts(
                storedEpoch = 4L,
                storedSession = "publisher-a",
                storedRevision = 21L,
                incomingEpoch = 5L,
                incomingSession = "publisher-b",
                incomingRevision = 1L,
            ),
        )
        assertFalse(
            KeyguardMaterialPublicationOrder.accepts(
                storedEpoch = 5L,
                storedSession = "publisher-b",
                storedRevision = 1L,
                incomingEpoch = 4L,
                incomingSession = "publisher-a",
                incomingRevision = 22L,
            ),
        )
    }
}
