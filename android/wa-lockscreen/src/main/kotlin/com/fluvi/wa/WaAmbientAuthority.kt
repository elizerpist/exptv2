package com.fluvi.wa

import android.graphics.Bitmap
import android.view.Display

/** A decoded frame from the same verified packet as the AppWidget. */
data class WaAmbientFrame(val packet: String, val bitmap: Bitmap)

data class WaAmbientMaterial(
    val widget: Int,
    val frame: WaAmbientFrame,
    val sizeDp: Int,
    val style: WaOrbStyle,
    val placement: OrbPlacement,
) {
    internal val identity get() = WaAmbientIdentity(widget, frame.packet, sizeDp, style, placement)
}

internal data class WaAmbientIdentity(
    val widget: Int, val packet: String, val sizeDp: Int, val style: WaOrbStyle, val placement: OrbPlacement,
)

internal enum class WaAmbientGate {
    DISABLED, WAKE_FENCED, SCREEN_OFF, AWAKE, UNLOCKED, UNKNOWN, WAIT_MATERIAL,
    INTERACTIVE_OWNER, DOZE, DOZE_SUSPEND;

    companion object {
        fun read(
            enabled: Boolean, fenced: Boolean, state: WaSystemState, material: Boolean, interactiveOwner: Boolean,
        ): WaAmbientGate = when {
            !enabled -> DISABLED
            state.locked == false -> UNLOCKED
            state.displayState == Display.STATE_OFF -> SCREEN_OFF
            state.displayState == Display.STATE_ON || state.interactive == true -> AWAKE
            !state.isDozing || state.interactive != false || state.locked != true -> UNKNOWN
            fenced -> WAKE_FENCED
            interactiveOwner -> INTERACTIVE_OWNER
            !material -> WAIT_MATERIAL
            state.displayState == Display.STATE_DOZE -> DOZE
            else -> DOZE_SUSPEND
        }
    }
}

/** All publication and revocation are on Main, under an exact window token. */
internal class WaAmbientAuthority {
    data class Ticket(val generation: Long, val identity: WaAmbientIdentity)

    private var generation = 0L
    private var current: Ticket? = null
    private var published = false

    fun begin(identity: WaAmbientIdentity): Ticket {
        check(current == null)
        return Ticket(++generation, identity).also { current = it }
    }

    fun canPublish(ticket: Ticket, gate: WaAmbientGate, identity: WaAmbientIdentity?): Boolean =
        current === ticket && !published && gate == WaAmbientGate.DOZE && identity == ticket.identity

    fun publish(ticket: Ticket, gate: WaAmbientGate, identity: WaAmbientIdentity?): Boolean {
        if (!canPublish(ticket, gate, identity)) return false
        published = true
        return true
    }

    fun retains(ticket: Ticket, gate: WaAmbientGate, identity: WaAmbientIdentity?): Boolean =
        current === ticket && identity == ticket.identity &&
            (gate == WaAmbientGate.DOZE || (gate == WaAmbientGate.DOZE_SUSPEND && published))

    fun revoke() {
        current = null
        published = false
    }
}
