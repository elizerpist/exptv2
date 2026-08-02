package com.fluvi.core.sync

import com.fluvi.core.database.entity.FluviLedgerEntryEntity
import com.fluvi.core.database.entity.FluviPartnerEntity
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

    suspend fun projectBatch(entries: Iterable<FluviLedgerEntryEntity>): List<LedgerSheetRow> {
        val entryList = entries.toList()
        if (entryList.isEmpty()) return emptyList()

        val categoriesById = categoryRepository.allEntities().associateBy { it.id }
        val partnersById = partnerRepository.allEntities().associateBy { it.id }
        val canonicalPartnerIds = entryList
            .asSequence()
            .map { it.partnerId }
            .distinct()
            .associateWith { partnerId ->
                partnerRepository.resolveCanonicalPartnerId(partnerId)
            }
        val canonicalPartners = canonicalPartnerIds.values
            .asSequence()
            .distinct()
            .associateWith { partnerId ->
                requireNotNull(partnersById[partnerId]) {
                    "Unknown canonical partner ID: $partnerId"
                }
            }

        return entryList.map { entry ->
            val category = requireNotNull(categoriesById[entry.categoryId]) {
                "Unknown category ID: ${entry.categoryId}"
            }
            val canonicalPartnerId = requireNotNull(canonicalPartnerIds[entry.partnerId]) {
                "Unknown partner ID: ${entry.partnerId}"
            }
            val canonicalPartner = requireNotNull(canonicalPartners[canonicalPartnerId]) {
                "Unknown canonical partner ID: $canonicalPartnerId"
            }
            toRow(entry, category.name, canonicalPartner)
        }
    }

    private fun toRow(
        entry: FluviLedgerEntryEntity,
        categoryName: String,
        canonicalPartner: FluviPartnerEntity,
    ): LedgerSheetRow {
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
            categoryName = categoryName,
            categoryAssignmentMode = entry.categoryAssignmentMode,
            originKind = entry.originKind,
            revision = entry.revision,
        )
    }
}
