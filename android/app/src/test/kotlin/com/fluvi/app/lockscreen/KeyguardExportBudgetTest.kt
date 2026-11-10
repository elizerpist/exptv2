package com.fluvi.app.lockscreen

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class KeyguardExportBudgetTest {
    @Test fun protectedHeaderCannotSilentlyRaiseTheWholeReportLimit() {
        assertFalse(KeyguardExportBudget.canAppend(35_667, 0, 32 * 1024))
    }

    @Test fun metadataAndFooterCountAndUtf8IsNotCharacterCount() {
        val header = "build=test\n"
        val footer = "END\n"
        val omissions = "omitted=none\n"
        val record = "ébresztés=őű\n"
        val alreadyReserved = (header + footer + omissions).toByteArray(Charsets.UTF_8).size
        val recordBytes = record.toByteArray(Charsets.UTF_8).size
        assertTrue(KeyguardExportBudget.canAppend(alreadyReserved, recordBytes, alreadyReserved + recordBytes))
        assertFalse(KeyguardExportBudget.canAppend(alreadyReserved, recordBytes, alreadyReserved + recordBytes - 1))
    }
}
