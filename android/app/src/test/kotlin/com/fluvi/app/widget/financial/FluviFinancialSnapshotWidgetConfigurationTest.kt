package com.fluvi.app.widget.financial

import com.fluvi.app.runtime.FluviLockScreenCardConfiguration
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

class FluviFinancialSnapshotWidgetConfigurationTest {
    @Test
    fun `new AppWidget configuration is discreet and does not inherit notification privacy`() {
        val configuration = FluviFinancialSnapshotWidgetConfiguration()

        assertEquals(
            FluviLockScreenCardConfiguration.Privacy.discreet,
            configuration.privacy,
        )
        assertFalse(configuration.isValid)
    }
}
