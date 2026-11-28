package com.fluvi.wa

import android.app.KeyguardManager
import android.content.Context
import android.hardware.display.DisplayManager
import android.os.PowerManager
import android.view.Display

internal data class WaSystemState(
    val displayState: Int = Display.STATE_UNKNOWN,
    val interactive: Boolean? = null,
    val locked: Boolean? = null,
) {
    val ready: Boolean
        get() = displayState == Display.STATE_ON && interactive == true && locked == true

    val isDozing: Boolean
        get() = displayState == Display.STATE_DOZE || displayState == Display.STATE_DOZE_SUSPEND

    val terminal: WaHideReason?
        get() = when {
            displayState != Display.STATE_UNKNOWN && displayState != Display.STATE_ON -> WaHideReason.DISPLAY
            interactive == false -> WaHideReason.NONINTERACTIVE
            locked == false -> WaHideReason.UNLOCKED
            else -> null
        }

    companion object {
        const val DISPLAY_MISSING = -1
        val UNKNOWN = WaSystemState()
    }
}

internal class WaSystemReader(context: Context) {
    private val displays = context.getSystemService(DisplayManager::class.java)
    private val power = context.getSystemService(PowerManager::class.java)
    private val keyguard = context.getSystemService(KeyguardManager::class.java)

    fun read(complete: Boolean = false, includeAmbient: Boolean = false): WaSystemState {
        val display = seen { displays.getDisplay(Display.DEFAULT_DISPLAY)?.state ?: WaSystemState.DISPLAY_MISSING }
            ?: Display.STATE_UNKNOWN
        val ambient = includeAmbient && (display == Display.STATE_DOZE || display == Display.STATE_DOZE_SUSPEND)
        if (!complete && !ambient && display != Display.STATE_ON) return WaSystemState(display)
        val interactive = seen { power.isInteractive }
        if (!complete && !ambient && interactive != true) return WaSystemState(display, interactive)
        return WaSystemState(display, interactive, seen { keyguard.isKeyguardLocked })
    }

    private inline fun <T> seen(read: () -> T): T? = try {
        read()
    } catch (_: RuntimeException) {
        null
    }
}

internal enum class WaBarrier { DISCONNECTED, BOOTSTRAP, OPEN, SLEEP, UNLOCKED }

/** Main-thread authority. Tree results and the current display state must both qualify. */
internal class WaWakeEpisode {
    var id = 0L
        private set
    var barrier = WaBarrier.DISCONNECTED
        private set
    var entranceAdmitted = false
        private set
    private var observedBoundary = false
    private var screenOn = false

    fun connect() {
        close(WaBarrier.BOOTSTRAP)
    }

    fun wakeSignal() {
        if (barrier == WaBarrier.SLEEP) screenOn = true
    }

    fun close(next: WaBarrier, observed: Boolean = false, newSleepSignal: Boolean = false) {
        if (barrier != next || newSleepSignal) {
            observedBoundary = false
            screenOn = false
        }
        barrier = next
        observedBoundary = observedBoundary || observed
    }

    fun admit(state: WaSystemState): Boolean {
        if (!state.ready) return false
        when (barrier) {
            WaBarrier.DISCONNECTED -> return false
            WaBarrier.OPEN -> return true
            WaBarrier.SLEEP -> if (!screenOn && !observedBoundary) return false
            WaBarrier.UNLOCKED -> if (!observedBoundary) return false
            WaBarrier.BOOTSTRAP -> Unit
        }
        barrier = WaBarrier.OPEN
        id++
        entranceAdmitted = false
        observedBoundary = false
        screenOn = false
        return true
    }

    fun owns(episode: Long): Boolean = barrier == WaBarrier.OPEN && id == episode

    fun attached(episode: Long) {
        if (owns(episode)) entranceAdmitted = true
    }
}

enum class WaHideReason {
    NONE, SCREEN_OFF, USER_PRESENT, DISPLAY, NONINTERACTIVE, UNLOCKED, DISCONNECT,
    UNKNOWN, CONTENT, RESTRICTED, POWER_MENU, INTERRUPT, REPLACE, ATTACH_FAILED,
    NO_FIT, RESIZE_OPTIONS_FAILED, RESIZE_FAILED, DRAG_RESTORE_FAILED,
}
