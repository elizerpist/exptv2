package com.fluvi.app.widget.financial

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

class FluviFinancialSnapshotWidgetConfigurationTest {
    @Test
    fun `new AppWidget configuration is discreet and does not inherit notification privacy`() {
        val configuration = FluviFinancialSnapshotWidgetConfiguration()

        assertEquals(
            FinancialSnapshotFocus.Privacy.discreet,
            configuration.privacy,
        )
        assertFalse(configuration.isValid)
    }
}
