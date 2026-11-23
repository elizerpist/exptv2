package com.fluvi.app.lockscreen.host

import android.content.Context
import com.fluvi.app.lockscreen.FluviKeyguardCardSettings
import com.fluvi.app.lockscreen.material.FluviKeyguardMaterialStore
import com.fluvi.app.lockscreen.material.KeyguardMaterialProfile
import org.junit.After
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

/** Exercises the real native material-store entry point; this is not a host or pixel test. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class R35MaterialPublicationTest {
    private val context: Context = RuntimeEnvironment.getApplication()
    private class MemoryStore : R29Ownership.Store {
        var value = R29Ownership.Persisted(false, 0)
        override fun read() = value
        override fun write(value: R29Ownership.Persisted): Boolean { this.value = value; return true }
    }
    private val owner = R29Ownership(MemoryStore())
    private val events = mutableListOf<String>()
    private var received: KeyguardMaterialProfile? = null
    private var receivedEvidence: R35MaterialEvidence? = null
    private val consumer = object : R35MaterialPublication.Consumer {
        override fun onInputsChanging() { events += "changing" }
        override fun onProfileAccepted(profile: KeyguardMaterialProfile, evidence: R35MaterialEvidence?) {
            events += "accepted"
            received = profile
            receivedEvidence = evidence
        }
    }

    @After fun cleanup() { R35MaterialPublication.remove(consumer) }

    private fun enroll() {
        val epoch = requireNotNull(owner.beginEnrollment())
        assertTrue(owner.oldOwnerDrained(epoch))
        assertTrue(owner.hostOwns(epoch))
        assertTrue(R35MaterialPublication.install(owner, epoch, "0123456789abcdef0123456789abcdef", consumer))
    }

    @Test fun actualAcceptedStorePublicationForwardsOnlyCapturedProvenance() {
        context.getSharedPreferences("fluvi_keyguard_header_material", Context.MODE_PRIVATE).edit().clear().commit()
        enroll()
        val evidence = mutableMapOf<String, Any?>(
            "targetCoreRevision" to 7L, "visualCoreRevision" to 7L, "currentCoreRevision" to 7L,
            "focusGeneration" to 2L, "layoutRevision" to 4L, "privacyRevision" to 5L,
            "visualProjectionFull" to true, "privateUnusedField" to "must not be forwarded",
        )
        assertTrue(FluviKeyguardMaterialStore.publish(context, profile(1L) + ("r29Evidence" to evidence), 1L))
        assertEquals(listOf("changing", "accepted"), events)
        assertEquals(7L, receivedEvidence?.targetCoreRevision)
        assertNotNull(received)
        evidence["targetCoreRevision"] = 9L
        assertEquals(7L, receivedEvidence?.targetCoreRevision)
        // The old publisher revision is rejected before notifying the host.
        assertFalse(FluviKeyguardMaterialStore.publish(context, profile(1L) + ("r29Evidence" to evidence), 1L))
        assertEquals(listOf("changing", "accepted"), events)
    }

    @Test fun settingsAndLayoutChangesInvalidateBeforeTheirCommit() {
        val settings = context.getSharedPreferences("fluvi_native_keyguard_card", Context.MODE_PRIVATE)
        settings.edit().clear().commit()
        var beforeCommit: Boolean? = null
        val checking = object : R35MaterialPublication.Consumer {
            override fun onInputsChanging() { beforeCommit = FluviKeyguardCardSettings.read(context).requested }
            override fun onProfileAccepted(profile: KeyguardMaterialProfile, evidence: R35MaterialEvidence?) = Unit
        }
        val epoch = requireNotNull(owner.beginEnrollment())
        assertTrue(owner.oldOwnerDrained(epoch))
        assertTrue(owner.hostOwns(epoch))
        assertTrue(R35MaterialPublication.install(owner, epoch, "0123456789abcdef0123456789abcdef", checking))
        try {
            FluviKeyguardCardSettings.update(context, mapOf("requested" to true))
            assertEquals(false, beforeCommit)
            assertTrue(FluviKeyguardCardSettings.read(context).requested)
            beforeCommit = null
            FluviKeyguardCardSettings.patchLayout(context, mapOf("orbPosition" to mapOf("xFraction" to .4, "yFraction" to .7)))
            assertEquals(true, beforeCommit)
        } finally { R35MaterialPublication.remove(checking) }
    }

    @Test fun missingOrFractionalProvenanceIsUnavailable() {
        val values = mapOf("targetCoreRevision" to 7.5, "visualCoreRevision" to 7L,
            "currentCoreRevision" to 7L, "focusGeneration" to 2L, "layoutRevision" to 4L,
            "privacyRevision" to 5L, "visualProjectionFull" to true)
        assertNull(R35MaterialEvidence.fromWire(values))
        assertNull(R35MaterialEvidence.fromWire(null))
    }

    private fun profile(revision: Long): Map<String, Any> {
        val portal = mapOf("enabled" to false, "effectIndex" to 0, "phase" to 0.0, "phaseSpeed" to 0.0,
            "paletteCenterPercent" to 50.0, "paletteWindowPercent" to 68.0,
            "rotationEnabled" to false, "rotationSpeed" to 0.0, "settings" to List(12) { .2 })
        return mapOf("schemaVersion" to 1, "shaderAbiVersion" to 6,
            "sourceShaderHash" to KeyguardMaterialProfile.SOURCE_SHADER_HASH,
            "publisherSession" to "r35-test", "publisherRevision" to revision,
            "sceneIdentity" to "budget|month|expense|demo|2", "effectId" to "dualTide", "effectShaderId" to 1,
            "phase" to .25, "elapsedSeconds" to 1.0, "phaseSpeed" to .4,
            "colors" to listOf(0xff104f7c.toInt(), 0xff62c7dc.toInt()), "stops" to listOf(0.0, 1.0),
            "opacity" to 1.0, "paletteSplitPercent" to 50.0, "commonSettings" to List(40) { .2 },
            "background" to portal, "interior" to portal, "referenceWidth" to 390.0, "referenceHeight" to 220.0)
    }
}
