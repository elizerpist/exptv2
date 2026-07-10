package com.exptv2.app

object NativeImeSheetMotion {
    fun translationYForIme(imeBottomPx: Int): Float {
        val bottom = imeBottomPx.coerceAtLeast(0)
        return if (bottom == 0) 0f else -bottom.toFloat()
    }
}
