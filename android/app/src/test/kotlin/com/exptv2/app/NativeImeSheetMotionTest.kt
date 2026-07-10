package com.exptv2.app

import org.junit.Assert.assertEquals
import org.junit.Test

class NativeImeSheetMotionTest {
    @Test
    fun translatesImeBottomToNegativeSheetOffset() {
        assertEquals(-252f, NativeImeSheetMotion.translationYForIme(252))
    }

    @Test
    fun clampsNegativeImeBottomToRestingOffset() {
        assertEquals(0f, NativeImeSheetMotion.translationYForIme(-4))
    }
}
