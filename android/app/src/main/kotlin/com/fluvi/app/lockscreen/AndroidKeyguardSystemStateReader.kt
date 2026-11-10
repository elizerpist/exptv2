package com.fluvi.app.lockscreen

import android.app.KeyguardManager
import android.content.Context
import android.hardware.display.DisplayManager
import android.os.PowerManager
import android.os.SystemClock
import android.os.UserManager
import android.view.Display

internal class AndroidKeyguardSystemStateReader(context: Context) : KeyguardSystemStateReader {
    private val displays = context.getSystemService(DisplayManager::class.java)
    private val power = context.getSystemService(PowerManager::class.java)
    private val keyguard = context.getSystemService(KeyguardManager::class.java)
    private val user = context.getSystemService(UserManager::class.java)

    override fun read(purpose: KeyguardSystemReadPurpose): KeyguardSystemState {
        val started = SystemClock.uptimeMillis()
        return try {
            val display = displays.getDisplay(Display.DEFAULT_DISPLAY)
            val state = display?.state
            val primary = display?.displayId == Display.DEFAULT_DISPLAY
            val interactive = power.isInteractive
            val locked = keyguard.isKeyguardLocked
            val unlocked = user.isUserUnlocked
            KeyguardSystemState(started, SystemClock.uptimeMillis(), true,
                primary, interactive, state == Display.STATE_ON, state == Display.STATE_OFF, locked, unlocked)
        } catch (_: Exception) {
            KeyguardSystemState(started, SystemClock.uptimeMillis(), available = false)
        }
    }
}
