package com.fluvi.core.usecase

import androidx.room.withTransaction
import com.fluvi.core.catalog.FluviCategoryCatalog
import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.entity.FluviCategoryEntity
import com.fluvi.core.database.entity.FluviLedgerEntryEntity
import com.fluvi.core.database.entity.FluviPartnerAliasEntity
import com.fluvi.core.database.entity.FluviPartnerEntity
import com.fluvi.core.demo.DemoDatasetGenerator
import com.fluvi.core.demo.DemoDatasetPlan
import com.fluvi.core.demo.DemoDatasetVersion
import com.fluvi.core.demo.DemoSeedReport
import com.fluvi.core.model.CategoryAssignmentMode
import com.fluvi.core.model.FluviClock
import com.fluvi.core.model.FluviSystemIds
import com.fluvi.core.model.LedgerOriginKind
import com.fluvi.core.repository.FluviCategoryRepository
import com.fluvi.core.repository.FluviCoreRevisionRepository
import com.fluvi.core.repository.FluviLedgerRepository
import com.fluvi.core.repository.FluviPartnerRepository
import com.fluvi.core.repository.PartnerAliasNormalizer
import com.fluvi.core.sync.LedgerChangePublisher
import com.fluvi.core.sync.LedgerSyncOutboxRepository

/**
 * Debug/development dataset writer. It deliberately has no Flutter or UI
 * dependency and writes through the same Room invariants as normal ledger data.
 */
class SeedFluviDemoDatasetUseCase internal constructor(
    private val database: FluviDatabase,
    private val categories: FluviCategoryRepository,
    private val partners: FluviPartnerRepository,
    private val ledger: FluviLedgerRepository,
    private val changePublisher: LedgerChangePublisher,
    private val outbox: LedgerSyncOutboxRepository,
    private val clock: FluviClock,
    private val generator: DemoDatasetGenerator = DemoDatasetGenerator(),
    private val revisionRepository: FluviCoreRevisionRepository =
        FluviCoreRevisionRepository(database),
) {
    suspend fun seed(forceReset: Boolean = false): DemoSeedReport {
        val startedAt = System.nanoTime()
        val plan = generator.generate()
        return database.withTransaction {
            val settings = requireNotNull(database.appSettingsDao().current()) {
                "The Fluvi app settings row is missing."
            }
            val manifest = DemoManifest(plan)
            val complete = settings.demoSeedVersion == DemoDatasetVersion.current &&
                manifest.isComplete(categories, partners, ledger)

            if (complete && !forceReset) {
                return@withTransaction report(
                    plan = plan,
                    createdCategoryCount = 0,
                    createdPartnerCount = 0,
                    createdEntryCount = 0,
                    alreadySeeded = true,
                    startedAt = startedAt,
                )
            }

            val hasKnownRows = manifest.hasAnyRows(categories, partners, ledger)
            if (hasKnownRows || settings.demoSeedVersion != null) {
                require(forceReset) {
                    "A partial Fluvi demo dataset exists; rerun with forceReset=true."
                }
                manifest.remove(categories, partners, ledger, outbox)
                check(
                    database.appSettingsDao().clearDemoSeedMetadata(
                        settingsId = FluviSystemIds.APP_SETTINGS,
                        updatedAtUtcMs = clock.nowUtcMs(),
                    ) == 1,
                )
            }

            insertCategories(plan)
            insertPartners(plan)
            val entries = plan.entries.map { draft ->
                FluviLedgerEntryEntity(
                    id = draft.id,
                    partnerId = draft.partnerId,
                    categoryId = draft.categoryId,
                    categoryAssignmentMode = draft.assignmentMode,
                    note = draft.note,
                    direction = draft.direction,
                    amountScaled100 = draft.amountScaled100,
                    bookedLocalEpochDay = draft.bookedLocalEpochDay,
                    bookedLocalTimeMinutes = draft.bookedLocalTimeMinutes,
                    occurredAtUtcMs = draft.occurredAtUtcMs,
                    originKind = LedgerOriginKind.manual,
                    notificationInboxId = null,
                    createdAtUtcMs = clock.nowUtcMs(),
                    updatedAtUtcMs = clock.nowUtcMs(),
                    revision = 1L,
                )
            }
            ledger.insertAll(entries)
            revisionRepository.advance(clock.nowUtcMs())
            changePublisher.publishUpserts(entries)
            check(
                database.appSettingsDao().markDemoSeedCompleted(
                    settingsId = FluviSystemIds.APP_SETTINGS,
                    version = DemoDatasetVersion.current,
                    completedAtUtcMs = clock.nowUtcMs(),
                    updatedAtUtcMs = clock.nowUtcMs(),
                ) == 1,
            )
            report(
                plan = plan,
                createdCategoryCount = plan.categories.size,
                createdPartnerCount = plan.partners.size,
                createdEntryCount = entries.size,
                alreadySeeded = false,
                startedAt = startedAt,
            )
        }
    }

    private suspend fun insertCategories(plan: DemoDatasetPlan) {
        plan.categories.forEach { draft ->
            require(draft.colorId in FluviCategoryCatalog.colorIds) {
                "Unknown Fluvi demo category color ID: ${draft.colorId}"
            }
            require(draft.iconId in FluviCategoryCatalog.iconIds) {
                "Unknown Fluvi demo category icon ID: ${draft.iconId}"
            }
            require(categories.findById(draft.id) == null) {
                "Demo category ID already exists: ${draft.id}"
            }
            categories.requireNameAvailable(draft.name)
            val now = clock.nowUtcMs()
            categories.insert(
                FluviCategoryEntity(
                    id = draft.id,
                    name = draft.name,
                    colorId = draft.colorId,
                    iconId = draft.iconId,
                    isSystemUncategorized = false,
                    createdAtUtcMs = now,
                    updatedAtUtcMs = now,
                ),
            )
        }
    }

    private suspend fun insertPartners(plan: DemoDatasetPlan) {
        plan.partners.forEach { draft ->
            require(partners.findByNormalizedAlias(PartnerAliasNormalizer.normalize(draft.name)) == null) {
                "Demo partner alias already exists: ${draft.name}"
            }
            categories.requireById(draft.defaultCategoryId)
            val now = clock.nowUtcMs()
            partners.insert(
                partner = FluviPartnerEntity(
                    id = draft.id,
                    originalName = draft.name,
                    displayNameOverride = null,
                    defaultCategoryId = draft.defaultCategoryId,
                    mergedIntoPartnerId = null,
                    createdAtUtcMs = now,
                    updatedAtUtcMs = now,
                ),
                alias = FluviPartnerAliasEntity(
                    id = draft.aliasId,
                    partnerId = draft.id,
                    normalizedAlias = PartnerAliasNormalizer.normalize(draft.name),
                    sourceName = draft.name,
                    createdAtUtcMs = now,
                    updatedAtUtcMs = now,
                ),
            )
        }
    }

    private fun report(
        plan: DemoDatasetPlan,
        createdCategoryCount: Int,
        createdPartnerCount: Int,
        createdEntryCount: Int,
        alreadySeeded: Boolean,
        startedAt: Long,
    ): DemoSeedReport = DemoSeedReport(
        seedVersion = plan.version,
        prngSeed = plan.prngSeed,
        createdCategoryCount = createdCategoryCount,
        createdPartnerCount = createdPartnerCount,
        createdEntryCount = createdEntryCount,
        monthlyReports = plan.monthlyReports,
        earliestEntryAtUtcMs = plan.entries.minOf { it.occurredAtUtcMs },
        latestEntryAtUtcMs = plan.entries.maxOf { it.occurredAtUtcMs },
        alreadySeeded = alreadySeeded,
        durationMs = (System.nanoTime() - startedAt) / 1_000_000L,
    )

    private class DemoManifest(private val plan: DemoDatasetPlan) {
        private val categoryIds = plan.categories.map { it.id }
        private val partnerIds = plan.partners.map { it.id }
        private val entryIds = plan.entries.map { it.id }

        suspend fun isComplete(
            categories: FluviCategoryRepository,
            partners: FluviPartnerRepository,
            ledger: FluviLedgerRepository,
        ): Boolean = categoryIds.all { categories.findById(it) != null } &&
            partnerIds.all { runCatching { partners.requireById(it) }.isSuccess } &&
            entryIds.all { runCatching { ledger.requireById(it) }.isSuccess }

        suspend fun hasAnyRows(
            categories: FluviCategoryRepository,
            partners: FluviPartnerRepository,
            ledger: FluviLedgerRepository,
        ): Boolean = categoryIds.any { categories.findById(it) != null } ||
            partnerIds.any { runCatching { partners.requireById(it) }.isSuccess } ||
            entryIds.any { runCatching { ledger.requireById(it) }.isSuccess }

        suspend fun remove(
            categories: FluviCategoryRepository,
            partners: FluviPartnerRepository,
            ledger: FluviLedgerRepository,
            outbox: LedgerSyncOutboxRepository,
        ) {
            val entryIdsSet = entryIds.toSet()
            categoryIds.forEach { categoryId ->
                val externalEntries = ledger.entriesByCategory(categoryId)
                    .filterNot { it.id in entryIdsSet }
                require(externalEntries.isEmpty()) {
                    "Cannot reset demo category with user ledger references: $categoryId"
                }
            }
            val externalPartnerEntries = ledger.entriesByPartnerIds(partnerIds)
                .filterNot { it.id in entryIdsSet }
            require(externalPartnerEntries.isEmpty()) {
                "Cannot reset demo partners with user ledger references."
            }
            outbox.deleteAll(entryIds)
            ledger.deleteAll(entryIds)
            partners.deleteAll(partnerIds)
            categories.deleteAll(categoryIds)
        }
    }
}
