package com.fluvi.core.usecase

import androidx.room.withTransaction
import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.entity.FluviLedgerDeletionArchiveEntity
import com.fluvi.core.database.entity.FluviLedgerEntryEntity
import com.fluvi.core.model.CategoryAssignmentMode
import com.fluvi.core.model.CreateLedgerEntryCommand
import com.fluvi.core.model.FluviClock
import com.fluvi.core.model.FluviIdGenerator
import com.fluvi.core.model.LedgerCategorySelection
import com.fluvi.core.repository.FluviCategoryRepository
import com.fluvi.core.repository.FluviCoreRevisionRepository
import com.fluvi.core.repository.FluviLedgerDeletionArchiveRepository
import com.fluvi.core.repository.FluviLedgerRepository
import com.fluvi.core.repository.FluviPartnerRepository
import com.fluvi.core.sync.LedgerChangePublisher
import com.fluvi.core.sync.LedgerCheckpointCoordinator

class FluviLedgerWriteUseCase internal constructor(
    private val database: FluviDatabase,
    private val ledgerRepository: FluviLedgerRepository,
    private val archiveRepository: FluviLedgerDeletionArchiveRepository,
    private val partnerRepository: FluviPartnerRepository,
    private val categoryRepository: FluviCategoryRepository,
    private val changePublisher: LedgerChangePublisher,
    private val checkpointCoordinator: LedgerCheckpointCoordinator,
    private val idGenerator: FluviIdGenerator,
    private val clock: FluviClock,
    private val revisionRepository: FluviCoreRevisionRepository = FluviCoreRevisionRepository(database),
) {
    suspend fun create(command: CreateLedgerEntryCommand): FluviLedgerEntryEntity =
        database.withTransaction {
            validate(command)
            val canonicalPartnerId = partnerRepository.resolveCanonicalPartnerId(command.partnerId)
            val category = resolveCategory(
                partnerId = canonicalPartnerId,
                selection = command.categorySelection,
            )
            val now = clock.nowUtcMs()
            val entry = FluviLedgerEntryEntity(
                id = idGenerator.next(),
                partnerId = canonicalPartnerId,
                categoryId = category.id,
                categoryAssignmentMode = category.mode,
                note = command.note?.trim()?.ifEmpty { null },
                direction = command.direction,
                amountScaled100 = command.amountScaled100,
                bookedLocalEpochDay = command.bookedLocalEpochDay,
                bookedLocalTimeMinutes = command.bookedLocalTimeMinutes,
                occurredAtUtcMs = command.occurredAtUtcMs,
                originKind = command.originKind,
                notificationInboxId = command.notificationInboxId,
                createdAtUtcMs = now,
                updatedAtUtcMs = now,
                revision = 1L,
            )
            ledgerRepository.insert(entry)
            revisionRepository.advance(now)
            changePublisher.publishUpsert(entry)
            entry
        }

    suspend fun updateAmount(
        entryId: String,
        amountScaled100: Long,
    ): FluviLedgerEntryEntity = database.withTransaction {
        require(amountScaled100 > 0L) { "Ledger amount must be positive." }
        val now = clock.nowUtcMs()
        val updated = ledgerRepository.updateAmount(
            entryId = entryId,
            amountScaled100 = amountScaled100,
            updatedAtUtcMs = now,
        )
        revisionRepository.advance(now)
        changePublisher.publishUpsert(updated)
        updated
    }

    suspend fun updateCategory(
        entryId: String,
        selection: LedgerCategorySelection,
    ): FluviLedgerEntryEntity = database.withTransaction {
        updateCategoryInTransaction(entryId, selection)
    }

    suspend fun clearCategoryOverride(entryId: String): FluviLedgerEntryEntity =
        database.withTransaction {
            updateCategoryInTransaction(
                entryId = entryId,
                selection = LedgerCategorySelection.PartnerDefault,
            )
        }

    suspend fun delete(entryId: String) {
        database.withTransaction {
            val entry = ledgerRepository.requireById(entryId)
            val checkpoint = checkpointCoordinator.prepareBeforeDestructiveInTransaction()
            val lastProjection = changePublisher.project(entry)
            archiveRepository.upsert(
                FluviLedgerDeletionArchiveEntity(
                    entryId = entry.id,
                    ledgerSheetRowPayload = lastProjection.toPayloadJson(),
                    deletedAtUtcMs = clock.nowUtcMs(),
                    requiredCheckpointId = checkpoint.id,
                ),
            )
            ledgerRepository.delete(entry.id)
            revisionRepository.advance(clock.nowUtcMs())
            changePublisher.publishDelete(lastProjection)
        }
    }

    private suspend fun updateCategoryInTransaction(
        entryId: String,
        selection: LedgerCategorySelection,
    ): FluviLedgerEntryEntity {
        val entry = ledgerRepository.requireById(entryId)
        val category = resolveCategory(
            partnerId = entry.partnerId,
            selection = selection,
        )
        val now = clock.nowUtcMs()
        val updated = ledgerRepository.updateCategory(
            entryId = entry.id,
            categoryId = category.id,
            mode = category.mode,
            updatedAtUtcMs = now,
        )
        revisionRepository.advance(now)
        changePublisher.publishUpsert(updated)
        return updated
    }

    private suspend fun resolveCategory(
        partnerId: String,
        selection: LedgerCategorySelection,
    ): ResolvedCategory {
        val canonicalPartnerId = partnerRepository.resolveCanonicalPartnerId(partnerId)
        return when (selection) {
            LedgerCategorySelection.PartnerDefault -> {
                val partner = partnerRepository.requireById(canonicalPartnerId)
                ResolvedCategory(
                    id = partner.defaultCategoryId,
                    mode = CategoryAssignmentMode.partnerDefault,
                )
            }

            is LedgerCategorySelection.EntryOverride -> {
                categoryRepository.requireById(selection.categoryId)
                ResolvedCategory(
                    id = selection.categoryId,
                    mode = CategoryAssignmentMode.entryOverride,
                )
            }
        }
    }

    private fun validate(command: CreateLedgerEntryCommand) {
        require(command.partnerId.isNotBlank()) { "Ledger Partner ID must not be blank." }
        require(command.amountScaled100 > 0L) { "Ledger amount must be positive." }
        require(command.bookedLocalTimeMinutes in 0..1_439) {
            "Ledger local time must be between 0 and 1439 minutes."
        }
    }

    private data class ResolvedCategory(
        val id: String,
        val mode: CategoryAssignmentMode,
    )
}
