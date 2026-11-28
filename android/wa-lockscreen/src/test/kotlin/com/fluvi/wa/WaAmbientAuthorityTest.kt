package com.fluvi.wa

import android.view.Display
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class WaAmbientAuthorityTest {
    private val doze = WaSystemState(Display.STATE_DOZE, interactive = false, locked = true)
    private val suspended = doze.copy(displayState = Display.STATE_DOZE_SUSPEND)
    private val material = WaAmbientIdentity(9, "palette-1", 56, WaOrbStyle.FLUVI_MASK, OrbPlacement.CENTER)

    private fun gate(
        state: WaSystemState,
        enabled: Boolean = true,
        fenced: Boolean = false,
        valid: Boolean = true,
        interactiveOwner: Boolean = false,
    ) = WaAmbientGate.read(enabled, fenced, state, valid, interactiveOwner)

    @Test fun onlyActualDrawableLockscreenAodGrantsFirstPublication() {
        assertEquals(WaAmbientGate.DISABLED, gate(doze, enabled = false))
        assertEquals(WaAmbientGate.SCREEN_OFF, gate(doze.copy(displayState = Display.STATE_OFF)))
        assertEquals(WaAmbientGate.AWAKE, gate(doze.copy(displayState = Display.STATE_ON, interactive = true)))
        assertEquals(WaAmbientGate.UNKNOWN, gate(doze.copy(displayState = Display.STATE_UNKNOWN)))
        assertEquals(WaAmbientGate.UNKNOWN, gate(doze.copy(interactive = null)))
        assertEquals(WaAmbientGate.UNKNOWN, gate(doze.copy(locked = null)))
        assertEquals(WaAmbientGate.UNLOCKED, gate(doze.copy(locked = false)))
        assertEquals(WaAmbientGate.WAKE_FENCED, gate(doze, fenced = true))
        assertEquals(WaAmbientGate.INTERACTIVE_OWNER, gate(doze, interactiveOwner = true))
        assertEquals(WaAmbientGate.WAIT_MATERIAL, gate(doze, valid = false))
        assertEquals(WaAmbientGate.DOZE, gate(doze))
    }

    @Test fun suspensionKeepsOnlyTheAlreadyPublishedGeneration() {
        val owner = WaAmbientAuthority()
        val ticket = owner.begin(material)
        assertFalse(owner.publish(ticket, gate(suspended), material))
        assertFalse(owner.retains(ticket, gate(suspended), material))
        assertTrue(owner.publish(ticket, gate(doze), material))
        assertTrue(owner.retains(ticket, gate(suspended), material))
        assertFalse(owner.publish(ticket, gate(doze), material))
        assertFalse(owner.retains(ticket, gate(doze, interactiveOwner = true), material))
    }

    @Test fun delayedCallbacksCannotPublishAfterRevocationOrReplaceNextOwner() {
        val authority = WaAmbientAuthority()
        val revocations = listOf(
            gate(doze.copy(locked = false)), gate(doze, fenced = true), gate(doze, enabled = false),
            gate(WaSystemState.UNKNOWN), gate(doze, valid = false),
        )
        for (revocation in revocations) {
            val stale = authority.begin(material)
            assertFalse(authority.retains(stale, revocation, material))
            authority.revoke()
            val next = authority.begin(material)
            assertTrue(next.generation > stale.generation)
            assertFalse(authority.publish(stale, gate(doze), material))
            assertTrue(authority.publish(next, gate(doze), material))
            authority.revoke()
        }
    }

    @Test fun packetBindingSizeStyleAndPositionArePartOfTheExactOwner() {
        for (dp in listOf(56, 112)) for (style in WaOrbStyle.entries) {
            val key = material.copy(sizeDp = dp, style = style)
            val owner = WaAmbientAuthority()
            val old = owner.begin(key)
            val updated = key.copy(packet = "palette-2")
            assertFalse(owner.canPublish(old, gate(doze), updated))
            assertFalse(owner.canPublish(old, gate(doze), key.copy(widget = 13)))
            assertFalse(owner.canPublish(old, gate(doze), key.copy(sizeDp = 168 - dp)))
            assertFalse(owner.canPublish(old, gate(doze), key.copy(style = WaOrbStyle.entries.first { it != style })))
            assertFalse(owner.canPublish(old, gate(doze), key.copy(placement = OrbPlacement(0.25f, 0.5f))))
            owner.revoke()
            val fresh = owner.begin(updated)
            assertTrue(owner.publish(fresh, gate(doze), updated))
            assertFalse(owner.retains(fresh, gate(suspended), key))
        }
    }
}
