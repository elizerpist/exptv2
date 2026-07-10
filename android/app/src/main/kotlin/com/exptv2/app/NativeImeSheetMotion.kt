package com.exptv2.app

object NativeImeSheetMotion {
    fun translationYForIme(imeBottomPx: Int): Float {
        return -imeBottomPx.coerceAtLeast(0).toFloat()
    }
}
