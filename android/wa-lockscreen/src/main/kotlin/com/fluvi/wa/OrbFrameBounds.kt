package com.fluvi.wa

import kotlin.math.roundToInt

data class OrbPlacement(val x: Float, val y: Float) {
    companion object {
        val CENTER = OrbPlacement(0.5f, 0.5f)
    }
}

internal data class OrbFrameBounds(
    val left: Int, val top: Int, val right: Int, val bottom: Int, val diameter: Int,
) {
    val fits: Boolean get() = diameter in 1..minOf(right - left, bottom - top)

    fun position(center: OrbPlacement): Pair<Int, Int> = clamp(
        (left + (right - left) * center.x - diameter / 2f).roundToInt(),
        (top + (bottom - top) * center.y - diameter / 2f).roundToInt(),
    )

    fun clamp(x: Int, y: Int): Pair<Int, Int> =
        x.coerceIn(left, right - diameter) to y.coerceIn(top, bottom - diameter)

    fun center(x: Int, y: Int) = OrbPlacement(
        (x + diameter / 2f - left) / (right - left),
        (y + diameter / 2f - top) / (bottom - top),
    )
}
