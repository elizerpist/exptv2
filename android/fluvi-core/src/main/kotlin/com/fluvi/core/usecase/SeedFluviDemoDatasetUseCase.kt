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
import com.fluvi.core.model.FluviFinancialLimit
import com.fluvi.core.model.FluviFinancialLimitKey
import com.fluvi.core.model.FluviFinancialLimitPeriod
import com.fluvi.core.model.FluviFinancialLimitTarget
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.repository.FluviCategoryRepository
import com.fluvi.core.repository.FluviCoreRevisionRepository
import com.fluvi.core.repository.FluviLedgerRepository
import com.fluvi.core.repository.FluviFinancialLimitRepository
import com.fluvi.core.repository.FluviPartnerRepository
import com.fluvi.core.repository.PartnerAliasNormalizer
import com.fluvi.core.sync.LedgerChangePublisher
import com.fluvi.core.sync.LedgerSyncOutboxRepository
import java.time.LocalDate

/**
 * Debug/development dataset writer. It deliberately has no Flutter or UI
 * dependency and writes through the same Room invariants as normal ledger data.
 */
class SeedFluviDemoDatasetUseCase internal constructor(
    private val database: FluviDatabase,
    private val categories: FluviCategoryRepository,
    private val partners: FluviPartnerRepository,
    private val ledger: FluviLedgerRepository,
    private val financialLimits: FluviFinancialLimitRepository,
    private val changePublisher: LedgerChangePublisher,
    private val outbox: LedgerSyncOutboxRepository,
    private val clock: FluviClock,
    private val generator: DemoDatasetGenerator = DemoDatasetGenerator(),
    private val revisionRepository: FluviCoreRevisionRepository =
        FluviCoreRevisionRepository(database),
) {
    suspend fun seed(
        forceReset: Boolean = false,
        financialLimitYearWindow: IntRange = DemoDatasetVersion.defaultFinancialLimitYearWindow,
    ): DemoSeedReport {
        require(!financialLimitYearWindow.isEmpty()) {
            "Demo financial-limit year window must not be empty."
        }
        val startedAt = System.nanoTime()
        val plan = generator.generate()
        return database.withTransaction {
            val settings = requireNotNull(database.appSettingsDao().current()) {
                "The Fluvi app settings row is missing."
            }
            val manifest = DemoManifest(plan, financialLimitYearWindow)
            val complete = settings.demoSeedVersion == DemoDatasetVersion.current &&
                manifest.isComplete(categories, partners, ledger, financialLimits)

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

            val hasKnownRows = manifest.hasAnyRows(categories, partners, ledger, financialLimits)
            if (hasKnownRows || settings.demoSeedVersion != null) {
                val deterministicFixtureUpgrade =
                    settings.demoSeedVersion != null &&
                        settings.demoSeedVersion != DemoDatasetVersion.current
                require(forceReset || deterministicFixtureUpgrade) {
                    "A partial Fluvi demo dataset exists; rerun with forceReset=true."
                }
                manifest.remove(categories, partners, ledger, financialLimits, outbox)
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
            financialLimits.upsertAll(
                demoFinancialLimits(
                    entries = entries,
                    years = financialLimitYearWindow,
                ),
            )
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

    /**
     * Every prepared Budget target receives one base monthly value plus
     * deterministic concrete-month overrides. Annual and SUM records are not
     * seeded because they are derived presentation scopes, never storage.
     */
    private fun demoFinancialLimits(
        entries: List<FluviLedgerEntryEntity>,
        years: IntRange,
    ): List<FluviFinancialLimit> {
        val now = clock.nowUtcMs()
        val overrides = buildList<FluviFinancialLimitPeriod> {
            years.forEach { year ->
                for (month in 1..12) add(FluviFinancialLimitPeriod.MonthOverride(year, month))
            }
        }
        return buildList {
            LedgerDirection.entries.forEach { direction ->
                val targetIds = listOf<String?>(null) + entries.asSequence()
                    .filter { it.direction == direction }
                    .map { it.categoryId }
                    .distinct()
                    .toList()
                var positiveTargetOrdinal = 0
                targetIds.forEachIndexed { targetIndex, categoryId ->
                    val target = categoryId?.let(FluviFinancialLimitTarget::Category)
                        ?: FluviFinancialLimitTarget.Aggregate
                    val totalActual = entries.asSequence()
                        .filter { entry ->
                            entry.direction == direction &&
                                (categoryId == null || entry.categoryId == categoryId)
                        }
                        .sumOf { it.amountScaled100 }
                    val relation = if (totalActual > 0L) {
                        positiveTargetOrdinal++ % 3
                    } else {
                        targetIndex % 3
                    }
                    add(
                        FluviFinancialLimit(
                            key = FluviFinancialLimitKey(
                                direction,
                                target,
                                FluviFinancialLimitPeriod.BaseMonthly,
                            ),
                            amountScaled100 = demoLimitFor(
                                // BaseMonthly is the typical inherited month,
                                // never a hidden annual/SUM denominator.
                                totalActual / (years.count().coerceAtLeast(1) * 12L),
                                relation,
                                targetIndex,
                                0,
                            ),
                            createdAtUtcMs = now,
                            updatedAtUtcMs = now,
                        ),
                    )
                    overrides.forEachIndexed { periodIndex, period ->
                        val actual = entries.asSequence()
                            .filter { entry ->
                                entry.direction == direction &&
                                    (categoryId == null || entry.categoryId == categoryId) &&
                                    matchesOverride(entry.bookedLocalEpochDay, period)
                            }
                            .sumOf { it.amountScaled100 }
                        // Sparse overrides exercise inheritance without
                        // turning every month into an independent stored row.
                        if ((periodIndex + targetIndex) % 3 == 0) add(
                            FluviFinancialLimit(
                                key = FluviFinancialLimitKey(direction, target, period),
                                amountScaled100 = demoLimitFor(actual, relation, targetIndex, periodIndex),
                                createdAtUtcMs = now,
                                updatedAtUtcMs = now,
                            ),
                        )
                    }
                }
            }
        }
    }

    private fun matchesOverride(epochDay: Long, period: FluviFinancialLimitPeriod): Boolean {
        val date = LocalDate.ofEpochDay(epochDay)
        return when (period) {
            FluviFinancialLimitPeriod.BaseMonthly -> false
            is FluviFinancialLimitPeriod.MonthOverride ->
                date.year == period.year && date.monthValue == period.month
        }
    }

    private fun demoLimitFor(
        actual: Long,
        relation: Int,
        targetIndex: Int,
        periodIndex: Int,
    ): Long {
        if (actual <= 0L) {
            // Positive deterministic HUF fallback; zero actual remains a real
            // no-spend/no-income state rather than an accidental missing row.
            return (25_000L + targetIndex * 7_000L + periodIndex * 1_000L) * 100L
        }
        return when (relation) {
            0 -> (actual * 125L / 100L).coerceAtLeast(100L)
            1 -> actual
            else -> (actual * 80L / 100L).coerceAtLeast(100L)
        }
    }

    private class DemoManifest(
        private val plan: DemoDatasetPlan,
        private val financialLimitYearWindow: IntRange,
    ) {
        private val categoryIds = plan.categories.map { it.id }
        private val partnerIds = plan.partners.map { it.id }
        private val entryIds = plan.entries.map { it.id }

        suspend fun isComplete(
            categories: FluviCategoryRepository,
            partners: FluviPartnerRepository,
            ledger: FluviLedgerRepository,
            financialLimits: FluviFinancialLimitRepository,
        ): Boolean = categoryIds.all { categories.findById(it) != null } &&
            partnerIds.all { runCatching { partners.requireById(it) }.isSuccess } &&
            entryIds.all { runCatching { ledger.requireById(it) }.isSuccess } &&
            financialLimits.count() >= expectedFinancialLimitCount()

        suspend fun hasAnyRows(
            categories: FluviCategoryRepository,
            partners: FluviPartnerRepository,
            ledger: FluviLedgerRepository,
            financialLimits: FluviFinancialLimitRepository,
        ): Boolean = categoryIds.any { categories.findById(it) != null } ||
            partnerIds.any { runCatching { partners.requireById(it) }.isSuccess } ||
            entryIds.any { runCatching { ledger.requireById(it) }.isSuccess } ||
            financialLimits.count() > 0L

        suspend fun remove(
            categories: FluviCategoryRepository,
            partners: FluviPartnerRepository,
            ledger: FluviLedgerRepository,
            financialLimits: FluviFinancialLimitRepository,
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
            financialLimits.deleteAll()
        }

        private fun expectedFinancialLimitCount(): Long {
            val yearCount = financialLimitYearWindow.last - financialLimitYearWindow.first + 1
            // One base row plus one sparse override for every third concrete
            // month. The window always contains a multiple of three months,
            // so each target receives the same deterministic row count.
            val periodCount = 1 + yearCount * 4
            val directionCategoryTargetCount = plan.entries
                .groupBy { it.direction }
                .values
                .sumOf { entries -> entries.map { it.categoryId }.toSet().size }
            return (LedgerDirection.entries.size + directionCategoryTargetCount).toLong() *
                periodCount
        }
    }
}
