package com.fluvi.core.repository

import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.entity.FluviLedgerEntryEntity
import com.fluvi.core.model.CategoryAssignmentMode

internal class FluviLedgerRepository(
    private val database: FluviDatabase,
) {
    private val ledger = database.ledgerDao()

    suspend fun insert(entry: FluviLedgerEntryEntity) {
        ledger.insert(entry)
    }

    suspend fun requireById(entryId: String): FluviLedgerEntryEntity = requireNotNull(
        ledger.findById(entryId),
    ) {
        "Unknown ledger entry ID: " + entryId
    }

    suspend fun updateAmount(
        entryId: String,
        amountScaled100: Long,
        updatedAtUtcMs: Long,
    ): FluviLedgerEntryEntity {
        check(
            ledger.updateAmount(
                entryId = entryId,
                amountScaled100 = amountScaled100,
                updatedAtUtcMs = updatedAtUtcMs,
            ) == 1,
        ) {
            "Ledger amount update did not affect exactly one row."
        }
        return requireById(entryId)
    }

    suspend fun updateCategory(
        entryId: String,
        categoryId: String,
        mode: CategoryAssignmentMode,
        updatedAtUtcMs: Long,
    ): FluviLedgerEntryEntity {
        check(
            ledger.updateCategory(
                entryId = entryId,
                categoryId = categoryId,
                mode = mode,
                updatedAtUtcMs = updatedAtUtcMs,
            ) == 1,
        ) {
            "Ledger category update did not affect exactly one row."
        }
        return requireById(entryId)
    }

    suspend fun delete(entryId: String) {
        check(ledger.delete(entryId) == 1) {
            "Ledger delete did not affect exactly one row."
        }
    }

    suspend fun retargetInheritedPartnerEntries(
        partnerIds: Collection<String>,
        categoryId: String,
        updatedAtUtcMs: Long,
    ): List<FluviLedgerEntryEntity> {
        if (partnerIds.isEmpty()) {
            return emptyList()
        }
        val affectedIds = ledger.entriesByPartnerIds(partnerIds.toList())
            .asSequence()
            .filter { it.categoryAssignmentMode == CategoryAssignmentMode.partnerDefault }
            .map { it.id }
            .toList()
        ledger.retargetInheritedPartnerEntries(
            partnerIds = partnerIds.toList(),
            categoryId = categoryId,
            mode = CategoryAssignmentMode.partnerDefault,
            updatedAtUtcMs = updatedAtUtcMs,
        )
        return buildList {
            affectedIds.forEach { entryId ->
                add(requireById(entryId))
            }
        }
    }

    suspend fun entriesByPartnerIds(partnerIds: Collection<String>): List<FluviLedgerEntryEntity> =
        if (partnerIds.isEmpty()) {
            emptyList()
        } else {
            ledger.entriesByPartnerIds(partnerIds.toList())
        }

    suspend fun entriesByCategory(categoryId: String): List<FluviLedgerEntryEntity> =
        ledger.entriesByCategory(categoryId)

    suspend fun retargetCategory(
        fromCategoryId: String,
        toCategoryId: String,
        updatedAtUtcMs: Long,
    ): List<FluviLedgerEntryEntity> {
        val affectedIds = ledger.entriesByCategory(fromCategoryId).map { it.id }
        ledger.retargetCategory(
            fromCategoryId = fromCategoryId,
            toCategoryId = toCategoryId,
            updatedAtUtcMs = updatedAtUtcMs,
        )
        val updated = mutableListOf<FluviLedgerEntryEntity>()
        for (entryId in affectedIds) {
            updated += requireById(entryId)
        }
        return updated
    }
}
