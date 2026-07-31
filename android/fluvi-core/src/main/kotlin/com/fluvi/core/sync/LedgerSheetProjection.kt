package com.fluvi.core.sync

import com.fluvi.core.database.entity.FluviLedgerEntryEntity
import com.fluvi.core.repository.FluviCategoryRepository
import com.fluvi.core.repository.FluviPartnerRepository

internal class LedgerSheetProjection(
    private val partnerRepository: FluviPartnerRepository,
    private val categoryRepository: FluviCategoryRepository,
) {
    suspend fun project(entry: FluviLedgerEntryEntity): LedgerSheetRow {
        val canonicalPartnerId = partnerRepository.resolveCanonicalPartnerId(entry.partnerId)
        val canonicalPartner = partnerRepository.requireById(canonicalPartnerId)
        val category = categoryRepository.requireById(entry.categoryId)
        val displayName = canonicalPartner.displayNameOverride ?: canonicalPartner.originalName

        return LedgerSheetRow(
            entryId = entry.id,
            bookedLocalEpochDay = entry.bookedLocalEpochDay,
            bookingYear = LedgerSheetRow.bookingYearFor(entry.bookedLocalEpochDay),
            bookedLocalTimeMinutes = entry.bookedLocalTimeMinutes,
            occurredAtUtcMs = entry.occurredAtUtcMs,
            direction = entry.direction,
            amountScaled100 = entry.amountScaled100,
            note = entry.note,
            partnerId = entry.partnerId,
            partnerDisplayName = displayName,
            categoryId = entry.categoryId,
            categoryName = category.name,
            categoryAssignmentMode = entry.categoryAssignmentMode,
            originKind = entry.originKind,
            revision = entry.revision,
        )
    }
}
