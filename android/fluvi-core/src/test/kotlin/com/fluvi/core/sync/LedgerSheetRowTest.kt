package com.fluvi.core.sync

import com.fluvi.core.model.CategoryAssignmentMode
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.LedgerOriginKind
import java.time.LocalDate
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class LedgerSheetRowTest {
    @Test
    fun flatRowCarriesItsWorkspaceYearAndEscapedCurrentLedgerValues() {
        val row = LedgerSheetRow(
            entryId = "00000000000000000000000010",
            bookedLocalEpochDay = LocalDate.of(2026, 2, 1).toEpochDay(),
            bookingYear = LedgerSheetRow.bookingYearFor(LocalDate.of(2026, 2, 1).toEpochDay()),
            bookedLocalTimeMinutes = 600,
            occurredAtUtcMs = 1_700_000_000_000L,
            direction = LedgerDirection.expense,
            amountScaled100 = 12_345L,
            note = "A \"quoted\" note",
            partnerId = "00000000000000000000000011",
            partnerDisplayName = "Tesco",
            categoryId = "00000000000000000000000012",
            categoryName = "Food",
            categoryAssignmentMode = CategoryAssignmentMode.entryOverride,
            originKind = LedgerOriginKind.manual,
            revision = 7L,
        )

        val payload = row.toPayloadJson()

        assertEquals(2026, row.bookingYear)
        assertTrue(payload.contains("\"bookingYear\":2026"))
        assertTrue(payload.contains("A \\\"quoted\\\" note"))
        assertTrue(payload.contains("\"amountScaled100\":12345"))
    }
}
