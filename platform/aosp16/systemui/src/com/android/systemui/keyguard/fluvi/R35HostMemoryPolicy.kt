package com.android.systemui.keyguard.fluvi

/**
 * ComponentCallbacks2.UI_HIDDEN (20) is a lifecycle signal, not an eviction
 * request. Retain an acknowledged detached image through normal sleep; drop it
 * under running-low/critical and background-or-worse memory pressure.
 */
internal object R35HostMemoryPolicy {
    fun shouldEvict(level: Int): Boolean = level in 10 until 20 || level >= 40
}
