package com.fluvi.app.lockscreen

import android.view.accessibility.AccessibilityEvent

/** Minimal event copy used only while Android owns the original event. */
internal data class KeyguardAccessibilityEventMeta(
    val eventType: Int,
    val windowId: Int,
    val displayId: Int,
    val windowChanges: Int,
    val packageName: String?,
    /** AccessibilityEvent.eventTime uses the same uptime time base as the
     * service receive timestamp, unlike elapsedRealtime during deep sleep. */
    val eventTimeUptimeMs: Long? = null,
)

internal enum class KeyguardEventAction { IGNORE_OWN, INSPECT }

/**
 * Never treats an unknown package-less event as Fluvi-owned. Its important
 * consequence is that an unknown event schedules a serial inspection instead
 * of eagerly removing a visible overlay. A positively matched own window is
 * ignored; a concurrent PIN/shade event has a different window and remains
 * inspectable. A Fluvi Activity is not treated as overlay feedback merely
 * because it shares a package name.
 */
internal object KeyguardCardEventGate {
    fun decide(event: KeyguardAccessibilityEventMeta, ownWindow: Boolean): KeyguardEventAction =
        if (ownWindow && (
            event.eventType != AccessibilityEvent.TYPE_WINDOWS_CHANGED ||
                event.windowChanges != 0
        )) {
            KeyguardEventAction.IGNORE_OWN
        } else {
            KeyguardEventAction.INSPECT
        }

    fun isSurfaceEvent(eventType: Int): Boolean = eventType == AccessibilityEvent.TYPE_WINDOWS_CHANGED ||
        eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED ||
        eventType == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
}

/** API 37 unknown external surface changes are not a fresh presentation grant.
 * Withdraw visible content before a potentially blocking inspection. */
internal object KeyguardR441RestrictionIngress {
    fun mustWithdraw(api: Int, event: KeyguardAccessibilityEventMeta, ownWindow: Boolean, attached: Boolean): Boolean =
        api >= 37 && attached && !ownWindow && (event.displayId == 0 || event.displayId < 0) &&
            KeyguardCardEventGate.isSurfaceEvent(event.eventType)
}
