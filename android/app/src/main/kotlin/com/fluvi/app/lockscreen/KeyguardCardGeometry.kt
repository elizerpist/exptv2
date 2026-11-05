package com.fluvi.app.lockscreen

import android.graphics.PixelFormat
import android.view.Gravity
import android.view.WindowManager
import kotlin.math.min

/** The single physical extent owned by the compact accessibility overlay. */
internal data class KeyguardCardGeometry(
    val width: Int,
    val height: Int,
    val y: Int,
)

internal fun resolveKeyguardCardGeometry(
    displayWidthPx: Int,
    density: Float,
    heightPx: Int,
    verticalOffsetDp: Int,
): KeyguardCardGeometry {
    fun dp(value: Int): Int = (value * density).toInt()
    val margin = dp(16)
    return KeyguardCardGeometry(
        // Preserve both side margins even on a display narrower than the old
        // decorative minWidth; the real window must never spill outside them.
        width = min(dp(360), (displayWidthPx - margin * 2).coerceAtLeast(1)),
        height = heightPx,
        y = dp(148 + verticalOffsetDp.coerceIn(-96, 96)),
    )
}

/** Kept separate from rendering so tests exercise the actual window contract. */
internal fun keyguardCardWindowParameters(geometry: KeyguardCardGeometry): WindowManager.LayoutParams =
    WindowManager.LayoutParams(
        geometry.width,
        geometry.height,
        WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
            WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
        PixelFormat.TRANSLUCENT,
    ).apply {
        gravity = Gravity.CENTER_HORIZONTAL or Gravity.BOTTOM
        y = geometry.y
        title = "FluviKeyguardCard"
    }
