package com.fluvi.app

import org.junit.Assert.assertEquals
import org.junit.Test

class FluviNotificationIconTest {
    @Test
    fun `missing or invalid storage value defaults to the existing outline icon`() {
        assertEquals(FluviNotificationSmallIconStyle.outline, FluviNotificationSmallIconStyle.fromPersisted(null))
        assertEquals(FluviNotificationSmallIconStyle.outline, FluviNotificationSmallIconStyle.fromPersisted("unexpected"))
        assertEquals(R.drawable.ic_stat_fluvi, FluviNotificationIconResolver.smallIconRes(FluviNotificationSmallIconStyle.outline))
    }

    @Test
    fun `filled selection resolves to its separate monochrome asset`() {
        assertEquals(FluviNotificationSmallIconStyle.filled, FluviNotificationSmallIconStyle.fromPersisted("filled"))
        assertEquals(R.drawable.ic_stat_fluvi_filled, FluviNotificationIconResolver.smallIconRes(FluviNotificationSmallIconStyle.filled))
    }
}
