package com.fluvi.core.usecase

import androidx.room.withTransaction
import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.entity.FluviLedgerDeletionArchiveEntity
import com.fluvi.core.database.entity.FluviLedgerEntryEntity
import com.fluvi.core.database.entity.FluviPartnerAliasEntity
import com.fluvi.core.database.entity.FluviPartnerEntity
import com.fluvi.core.model.CategoryAssignmentMode
import com.fluvi.core.model.CreateManualTransactionCommand
import com.fluvi.core.model.CreateLedgerEntryCommand
import com.fluvi.core.model.CreatePushLedgerEntryCommand
import com.fluvi.core.model.CreateRecurringLedgerEntryCommand
import com.fluvi.core.model.FluviClock
import com.fluvi.core.model.FluviIdGenerator
import com.fluvi.core.model.FluviLedgerEntryDetail
import com.fluvi.core.model.LedgerRevisionConflictException
import com.fluvi.core.model.LedgerCategorySelection
import com.fluvi.core.model.ManualTransactionPartnerSelection
import com.fluvi.core.model.UpdateLedgerEntryCommand
import com.fluvi.core.repository.FluviCategoryRepository
import com.fluvi.core.repository.FluviCoreRevisionRepository
import com.fluvi.core.repository.FluviLedgerDeletionArchiveRepository
import com.fluvi.core.repository.FluviLedgerRepository
import com.fluvi.core.repository.FluviPartnerRepository
import com.fluvi.core.repository.PartnerAliasNormalizer
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
    suspend fun getLedgerEntryById(entryId: String): FluviLedgerEntryDetail =
        database.withTransaction { ledgerRepository.requireById(entryId).toDetail() }

    /**
     * Creates a manual entry and, when necessary, its partner in one Room
     * transaction. A cancelled editor therefore cannot leave an orphan
     * partner, and one successful save advances the revision once.
     */
    suspend fun createManual(command: CreateManualTransactionCommand): FluviLedgerEntryEntity =
        database.withTransaction {
            validateManual(command.amountScaled100, command.bookedLocalTimeMinutes)
            val partnerId = when (val selection = command.partner) {
                is ManualTransactionPartnerSelection.Existing ->
                    partnerRepository.resolveCanonicalPartnerId(selection.partnerId)
                is ManualTransactionPartnerSelection.New ->
                    findOrCreatePartnerInTransaction(
                        name = selection.displayName,
                        defaultCategoryId = selection.defaultCategoryId,
                    )
            }
            val category = resolveCategory(partnerId, command.categorySelection)
            val now = clock.nowUtcMs()
            val entry = FluviLedgerEntryEntity(
                id = idGenerator.next(),
                partnerId = partnerId,
                categoryId = category.id,
                categoryAssignmentMode = category.mode,
                note = command.note?.trim()?.ifEmpty { null },
                direction = command.direction,
                amountScaled100 = command.amountScaled100,
                bookedLocalEpochDay = command.bookedLocalEpochDay,
                bookedLocalTimeMinutes = command.bookedLocalTimeMinutes,
                occurredAtUtcMs = command.occurredAtUtcMs,
                originKind = com.fluvi.core.model.LedgerOriginKind.manual,
                notificationInboxId = null,
                recurrenceOccurrenceId = null,
                createdAtUtcMs = now,
                updatedAtUtcMs = now,
                revision = 1L,
            )
            ledgerRepository.insert(entry)
            revisionRepository.advance(now)
            changePublisher.publishUpsert(entry)
            entry
        }

    /** Applies all editor-owned fields once, without changing source identity. */
    suspend fun updateEntry(command: UpdateLedgerEntryCommand): FluviLedgerEntryEntity =
        database.withTransaction {
            validateManual(command.amountScaled100, command.bookedLocalTimeMinutes)
            val current = ledgerRepository.requireById(command.entryId)
            if (current.revision != command.expectedRevision) {
                throw LedgerRevisionConflictException(command.entryId)
            }
            val partnerId = when (val selection = command.partner) {
                is ManualTransactionPartnerSelection.Existing ->
                    partnerRepository.resolveCanonicalPartnerId(selection.partnerId)
                is ManualTransactionPartnerSelection.New ->
                    findOrCreatePartnerInTransaction(
                        name = selection.displayName,
                        defaultCategoryId = selection.defaultCategoryId,
                    )
            }
            val category = resolveCategory(partnerId, command.categorySelection)
            val cleanedNote = command.note?.trim()?.ifEmpty { null }
            // Preserve the original event instant for imported records. The
            // editor only supplies a new instant for manual records.
            val occurredAt = if (current.originKind == com.fluvi.core.model.LedgerOriginKind.manual) {
                command.occurredAtUtcMs
            } else {
                current.occurredAtUtcMs
            }
            if (
                current.partnerId == partnerId &&
                    current.categoryId == category.id &&
                    current.categoryAssignmentMode == category.mode &&
                    current.note == cleanedNote &&
                    current.amountScaled100 == command.amountScaled100 &&
                    current.bookedLocalEpochDay == command.bookedLocalEpochDay &&
                    current.bookedLocalTimeMinutes == command.bookedLocalTimeMinutes &&
                    current.occurredAtUtcMs == occurredAt
            ) {
                return@withTransaction current
            }
            val now = clock.nowUtcMs()
            if (!ledgerRepository.updateEditorEntry(
                    entryId = current.id,
                    expectedRevision = command.expectedRevision,
                    partnerId = partnerId,
                    categoryId = category.id,
                    categoryAssignmentMode = category.mode,
                    note = cleanedNote,
                    amountScaled100 = command.amountScaled100,
                    bookedLocalEpochDay = command.bookedLocalEpochDay,
                    bookedLocalTimeMinutes = command.bookedLocalTimeMinutes,
                    occurredAtUtcMs = occurredAt,
                    updatedAtUtcMs = now,
                )
            ) {
                throw LedgerRevisionConflictException(command.entryId)
            }
            val updated = ledgerRepository.requireById(current.id)
            revisionRepository.advance(now)
            changePublisher.publishUpsert(updated)
            updated
        }

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
                recurrenceOccurrenceId = null,
                createdAtUtcMs = now,
                updatedAtUtcMs = now,
                revision = 1L,
            )
            ledgerRepository.insert(entry)
            revisionRepository.advance(now)
            changePublisher.publishUpsert(entry)
            entry
        }

    /**
     * Parser imports use the same ledger invariants as manual entries while
     * preserving their push provenance and the source inbox foreign key.
     */
    suspend fun createPush(command: CreatePushLedgerEntryCommand): FluviLedgerEntryEntity =
        database.withTransaction {
            validateManual(command.amountScaled100, command.bookedLocalTimeMinutes)
            val partnerId = findOrCreatePartnerInTransaction(
                name = command.merchantName,
                defaultCategoryId = com.fluvi.core.model.FluviSystemIds.UNCATEGORIZED_CATEGORY,
            )
            val category = resolveCategory(partnerId, LedgerCategorySelection.PartnerDefault)
            val now = clock.nowUtcMs()
            val entry = FluviLedgerEntryEntity(
                id = idGenerator.next(), partnerId = partnerId, categoryId = category.id,
                categoryAssignmentMode = category.mode, note = command.note?.trim()?.ifEmpty { null },
                direction = command.direction, amountScaled100 = command.amountScaled100,
                bookedLocalEpochDay = command.bookedLocalEpochDay,
                bookedLocalTimeMinutes = command.bookedLocalTimeMinutes,
                occurredAtUtcMs = command.occurredAtUtcMs,
                originKind = com.fluvi.core.model.LedgerOriginKind.push,
                notificationInboxId = command.notificationInboxId,
                recurrenceOccurrenceId = null,
                createdAtUtcMs = now, updatedAtUtcMs = now, revision = 1L,
            )
            ledgerRepository.insert(entry)
            revisionRepository.advance(now)
            changePublisher.publishUpsert(entry)
            entry
        }

    /** Realizes exactly one occurrence. The unique ledger FK is the last database-level duplicate guard. */
    suspend fun createRecurring(command: CreateRecurringLedgerEntryCommand): FluviLedgerEntryEntity =
        database.withTransaction {
            validateManual(command.amountScaled100, command.bookedLocalTimeMinutes)
            val canonicalPartnerId = partnerRepository.resolveCanonicalPartnerId(command.partnerId)
            val category = resolveCategory(canonicalPartnerId, command.categorySelection)
            val now = clock.nowUtcMs()
            val entry = FluviLedgerEntryEntity(
                id = idGenerator.next(), partnerId = canonicalPartnerId, categoryId = category.id,
                categoryAssignmentMode = category.mode, note = command.note?.trim()?.ifEmpty { null },
                direction = command.direction, amountScaled100 = command.amountScaled100,
                bookedLocalEpochDay = command.bookedLocalEpochDay,
                bookedLocalTimeMinutes = command.bookedLocalTimeMinutes,
                occurredAtUtcMs = command.occurredAtUtcMs, originKind = command.originKind,
                notificationInboxId = command.notificationInboxId,
                recurrenceOccurrenceId = command.occurrenceId,
                createdAtUtcMs = now, updatedAtUtcMs = now, revision = 1L,
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

    private fun validateManual(amountScaled100: Long, bookedLocalTimeMinutes: Int) {
        require(amountScaled100 > 0L) { "Ledger amount must be positive." }
        require(bookedLocalTimeMinutes in 0..1_439) {
            "Ledger local time must be between 0 and 1439 minutes."
        }
    }

    private suspend fun findOrCreatePartnerInTransaction(
        name: String,
        defaultCategoryId: String,
    ): String {
        val displayName = PartnerAliasNormalizer.displayName(name)
        val normalizedAlias = PartnerAliasNormalizer.normalize(displayName)
        val existing = partnerRepository.findByNormalizedAlias(normalizedAlias)
        if (existing != null) return partnerRepository.resolveCanonicalPartnerId(existing.id)
        categoryRepository.requireById(defaultCategoryId)
        val now = clock.nowUtcMs()
        val partnerId = idGenerator.next()
        partnerRepository.insert(
            partner = FluviPartnerEntity(
                id = partnerId,
                originalName = displayName,
                displayNameOverride = null,
                defaultCategoryId = defaultCategoryId,
                mergedIntoPartnerId = null,
                createdAtUtcMs = now,
                updatedAtUtcMs = now,
            ),
            alias = FluviPartnerAliasEntity(
                id = idGenerator.next(),
                partnerId = partnerId,
                normalizedAlias = normalizedAlias,
                sourceName = displayName,
                createdAtUtcMs = now,
                updatedAtUtcMs = now,
            ),
        )
        return partnerId
    }

    private fun FluviLedgerEntryEntity.toDetail() = FluviLedgerEntryDetail(
        entryId = id,
        partnerId = partnerId,
        categoryId = categoryId,
        categoryAssignmentMode = categoryAssignmentMode,
        direction = direction,
        amountScaled100 = amountScaled100,
        bookedLocalEpochDay = bookedLocalEpochDay,
        bookedLocalTimeMinutes = bookedLocalTimeMinutes,
        occurredAtUtcMs = occurredAtUtcMs,
        note = note,
        originKind = originKind,
        notificationInboxId = notificationInboxId,
        recurrenceOccurrenceId = recurrenceOccurrenceId,
        revision = revision,
    )

    private data class ResolvedCategory(
        val id: String,
        val mode: CategoryAssignmentMode,
    )
}
