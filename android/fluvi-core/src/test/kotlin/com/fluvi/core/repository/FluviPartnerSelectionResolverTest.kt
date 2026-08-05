package com.fluvi.core.repository

import com.fluvi.core.database.entity.FluviPartnerEntity
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class FluviPartnerSelectionResolverTest {
    @Test
    fun expandsSelectedPartnerAgainstOneImmutableSnapshot() {
        val partners = listOf(
            partner(id = "canonical"),
            partner(id = "donor-a", mergedIntoPartnerId = "canonical"),
            partner(id = "donor-b", mergedIntoPartnerId = "canonical"),
            partner(id = "other"),
        )

        assertEquals(
            linkedSetOf("canonical", "donor-a", "donor-b"),
            expandPartnerSelection(
                selectedPartnerIds = setOf("donor-a"),
                allPartners = partners,
            ),
        )
    }

    @Test
    fun rejectsMissingMergeTargetsFromTheSameSnapshot() {
        val partners = listOf(
            partner(id = "donor", mergedIntoPartnerId = "missing"),
        )

        assertThrows(IllegalArgumentException::class.java) {
            expandPartnerSelection(
                selectedPartnerIds = setOf("donor"),
                allPartners = partners,
            )
        }
    }

    private fun partner(
        id: String,
        mergedIntoPartnerId: String? = null,
    ) = FluviPartnerEntity(
        id = id,
        originalName = id,
        displayNameOverride = null,
        defaultCategoryId = "category",
        mergedIntoPartnerId = mergedIntoPartnerId,
        createdAtUtcMs = 1L,
        updatedAtUtcMs = 1L,
    )
}
