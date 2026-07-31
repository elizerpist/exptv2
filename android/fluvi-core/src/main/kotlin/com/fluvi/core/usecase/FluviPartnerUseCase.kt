package com.fluvi.core.usecase

import androidx.room.withTransaction
import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.entity.FluviPartnerAliasEntity
import com.fluvi.core.database.entity.FluviPartnerEntity
import com.fluvi.core.model.FluviClock
import com.fluvi.core.model.FluviIdGenerator
import com.fluvi.core.repository.FluviCategoryRepository
import com.fluvi.core.repository.FluviCoreRevisionRepository
import com.fluvi.core.repository.FluviLedgerRepository
import com.fluvi.core.repository.FluviPartnerRepository
import com.fluvi.core.repository.PartnerAliasNormalizer
import com.fluvi.core.sync.LedgerChangePublisher

class FluviPartnerUseCase internal constructor(
    private val database: FluviDatabase,
    private val repository: FluviPartnerRepository,
    private val categoryRepository: FluviCategoryRepository,
    private val ledgerRepository: FluviLedgerRepository,
    private val changePublisher: LedgerChangePublisher,
    private val idGenerator: FluviIdGenerator,
    private val clock: FluviClock,
    private val revisionRepository: FluviCoreRevisionRepository = FluviCoreRevisionRepository(database),
) {
    suspend fun findOrCreate(
        name: String,
        defaultCategoryId: String,
    ): String = database.withTransaction {
        val displayName = PartnerAliasNormalizer.displayName(name)
        val normalizedAlias = PartnerAliasNormalizer.normalize(displayName)
        val existing = repository.findByNormalizedAlias(normalizedAlias)
        if (existing != null) {
            return@withTransaction repository.resolveCanonicalPartnerId(existing.id)
        }

        categoryRepository.requireById(defaultCategoryId)
        val now = clock.nowUtcMs()
        val partnerId = idGenerator.next()
        repository.insert(
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
        revisionRepository.advance(now)
        partnerId
    }

    suspend fun changeDefaultCategory(
        partnerId: String,
        categoryId: String,
    ) {
        database.withTransaction {
            val canonicalPartnerId = repository.resolveCanonicalPartnerId(partnerId)
            val affectedPartnerIds = repository.partnerIdsResolvingTo(canonicalPartnerId)
            categoryRepository.requireById(categoryId)
            val now = clock.nowUtcMs()
            repository.changeDefaultCategory(
                partnerId = canonicalPartnerId,
                categoryId = categoryId,
                updatedAtUtcMs = now,
            )
            val changedEntries = ledgerRepository.retargetInheritedPartnerEntries(
                partnerIds = affectedPartnerIds,
                categoryId = categoryId,
                updatedAtUtcMs = now,
            )
            repository.retargetInheritedRecurrenceRules(
                partnerIds = affectedPartnerIds,
                categoryId = categoryId,
                updatedAtUtcMs = now,
            )
            changePublisher.publishUpserts(changedEntries)
            revisionRepository.advance(now)
        }
    }

    suspend fun setDisplayNameOverride(
        partnerId: String,
        displayNameOverride: String?,
    ) {
        database.withTransaction {
            val canonicalPartnerId = repository.resolveCanonicalPartnerId(partnerId)
            val affectedPartnerIds = repository.partnerIdsResolvingTo(canonicalPartnerId)
            val cleanedOverride = displayNameOverride?.let(PartnerAliasNormalizer::displayName)
            repository.setDisplayNameOverride(
                partnerId = canonicalPartnerId,
                displayNameOverride = cleanedOverride,
                updatedAtUtcMs = clock.nowUtcMs(),
            )
            changePublisher.publishUpserts(
                ledgerRepository.entriesByPartnerIds(affectedPartnerIds),
            )
            revisionRepository.advance(clock.nowUtcMs())
        }
    }

    suspend fun merge(
        donorId: String,
        recipientId: String,
    ) {
        database.withTransaction {
            val donor = repository.requireById(donorId)
            require(donor.mergedIntoPartnerId == null) {
                "A merged donor must be unmerged before it can be merged again."
            }
            val canonicalRecipientId = repository.resolveCanonicalPartnerId(recipientId)
            require(donor.id != canonicalRecipientId) {
                "A partner cannot merge into itself."
            }
            val affectedPartnerIds = repository.partnerIdsInMergeSubtree(donor.id)
            repository.setMergeTarget(
                donorId = donor.id,
                recipientId = canonicalRecipientId,
                updatedAtUtcMs = clock.nowUtcMs(),
            )
            changePublisher.publishUpserts(
                ledgerRepository.entriesByPartnerIds(affectedPartnerIds),
            )
            revisionRepository.advance(clock.nowUtcMs())
        }
    }

    suspend fun unmerge(donorId: String) {
        database.withTransaction {
            repository.requireById(donorId)
            val affectedPartnerIds = repository.partnerIdsInMergeSubtree(donorId)
            repository.setMergeTarget(
                donorId = donorId,
                recipientId = null,
                updatedAtUtcMs = clock.nowUtcMs(),
            )
            changePublisher.publishUpserts(
                ledgerRepository.entriesByPartnerIds(affectedPartnerIds),
            )
            revisionRepository.advance(clock.nowUtcMs())
        }
    }

    suspend fun resolveCanonicalPartnerId(partnerId: String): String =
        database.withTransaction {
            repository.resolveCanonicalPartnerId(partnerId)
        }
}
