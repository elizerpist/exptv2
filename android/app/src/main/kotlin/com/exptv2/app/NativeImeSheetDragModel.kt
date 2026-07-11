package com.exptv2.app

object NativeImeSheetDragModel {
    fun clampOffset(offsetPx: Float, maxOffsetPx: Float): Float {
        return offsetPx.coerceIn(0f, maxOffsetPx.coerceAtLeast(0f))
    }

    fun shouldDismiss(
        offsetPx: Float,
        velocityYPxPerSecond: Float,
        thresholdPx: Float,
        velocityThresholdPxPerSecond: Float,
    ): Boolean {
        return offsetPx >= thresholdPx ||
            velocityYPxPerSecond >= velocityThresholdPxPerSecond
    }

    fun translationY(imeBottomPx: Int, dragOffsetPx: Float): Float {
        return NativeImeSheetMotion.translationYForIme(imeBottomPx) +
            dragOffsetPx.coerceAtLeast(0f)
    }
}
