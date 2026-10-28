package com.fluvi.core.demo

import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.entity.FluviCategoryEntity
import com.fluvi.core.database.entity.FluviLedgerEntryEntity
import com.fluvi.core.database.entity.FluviPartnerAliasEntity
import com.fluvi.core.database.entity.FluviPartnerEntity
import com.fluvi.core.database.entity.FluviPushRecurringRuleConfigEntity
import com.fluvi.core.database.entity.FluviRecurrenceOccurrenceEntity
import com.fluvi.core.database.entity.FluviRecurrenceRuleEntity
import com.fluvi.core.model.CategoryAssignmentMode
import com.fluvi.core.model.FluviClock
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.LedgerOriginKind
import com.fluvi.core.model.RecurrenceAmountPolicy
import com.fluvi.core.model.RecurrenceOccurrenceStatus
import com.fluvi.core.model.RecurrenceRealizationKind
import com.fluvi.core.model.RecurrenceTriggerKind
import com.fluvi.core.repository.FluviCategoryRepository
import com.fluvi.core.repository.FluviLedgerRepository
import com.fluvi.core.repository.FluviPartnerRepository
import com.fluvi.core.repository.PartnerAliasNormalizer
import java.time.LocalDate
import java.time.ZoneId

/**
 * An append-only, independently versioned ghost fixture.  It intentionally
 * does not take part in the base demo manifest: installations that already
 * have dataset v8 receive it without resetting their normal demo data.
 *
 * Its rules use unbound push triggers.  They remain active for the dashboard's
 * pending-occurrence join, while the time scheduler cannot accidentally book
 * past examples when the app starts.
 */
internal class GhostDemoDatasetFixture(
    private val database: FluviDatabase,
    private val categories: FluviCategoryRepository,
    private val partners: FluviPartnerRepository,
    private val ledger: FluviLedgerRepository,
    private val clock: FluviClock,
) {
    suspend fun ensure(): GhostDemoSeedResult {
        val now = clock.nowUtcMs()
        var createdCategories = 0
        var createdPartners = 0
        var createdRules = 0
        var createdOccurrences = 0
        val createdLedgerEntries = mutableListOf<FluviLedgerEntryEntity>()

        categoryDefinitions.forEach { definition ->
            if (categories.findById(definition.id) == null) {
                categories.requireNameAvailable(definition.name)
                categories.insert(
                    FluviCategoryEntity(
                        id = definition.id,
                        name = definition.name,
                        colorId = definition.colorId,
                        iconId = definition.iconId,
                        isSystemUncategorized = false,
                        createdAtUtcMs = now,
                        updatedAtUtcMs = now,
                    ),
                )
                createdCategories += 1
            }
        }

        partnerDefinitions.forEach { definition ->
            if (runCatching { partners.requireById(definition.id) }.getOrNull() == null) {
                require(
                    partners.findByNormalizedAlias(
                        PartnerAliasNormalizer.normalize(definition.name),
                    ) == null,
                ) { "Ghost demo partner alias already exists: ${definition.name}" }
                partners.insert(
                    partner = FluviPartnerEntity(
                        id = definition.id,
                        originalName = definition.name,
                        displayNameOverride = null,
                        defaultCategoryId = definition.categoryId,
                        mergedIntoPartnerId = null,
                        createdAtUtcMs = now,
                        updatedAtUtcMs = now,
                    ),
                    alias = FluviPartnerAliasEntity(
                        id = definition.aliasId,
                        partnerId = definition.id,
                        normalizedAlias = PartnerAliasNormalizer.normalize(definition.name),
                        sourceName = definition.name,
                        createdAtUtcMs = now,
                        updatedAtUtcMs = now,
                    ),
                )
                createdPartners += 1
            }
        }

        val recurrence = database.recurrenceDao()
        ruleDefinitions.forEach { definition ->
            if (recurrence.rule(definition.id) == null) {
                recurrence.insertRule(
                    FluviRecurrenceRuleEntity(
                        id = definition.id,
                        name = definition.name,
                        triggerKind = RecurrenceTriggerKind.push,
                        partnerId = definition.partnerId,
                        categoryId = definition.categoryId,
                        categoryAssignmentMode = CategoryAssignmentMode.partnerDefault,
                        note = definition.note,
                        direction = definition.direction,
                        amountPolicy = RecurrenceAmountPolicy.fixed,
                        amountScaled100 = definition.amountScaled100,
                        dayOfMonth = DAY_OF_MONTH,
                        localTimeMinutes = definition.localTimeMinutes,
                        startLocalEpochDay = LocalDate.of(FIRST_YEAR, 1, DAY_OF_MONTH).toEpochDay(),
                        endLocalEpochDay = LocalDate.of(LAST_YEAR, 12, DAY_OF_MONTH).toEpochDay(),
                        timezoneId = ZONE.id,
                        ruleVersion = 1,
                        archivedAtUtcMs = null,
                        isActive = true,
                        createdAtUtcMs = now,
                        updatedAtUtcMs = now,
                    ),
                )
                // An unbound push rule is active and visible but cannot match a
                // real notification.  It also stays outside the time scheduler.
                recurrence.upsertPushConfig(
                    FluviPushRecurringRuleConfigEntity(
                        ruleId = definition.id,
                        pushProfileId = null,
                        pushRuleId = null,
                        expectedLocalTimeMinutes = definition.localTimeMinutes,
                        amountToleranceScaled100 = 0L,
                        dayWindow = 0,
                        parserMatchText = null,
                    ),
                )
                createdRules += 1
            }
        }

        ruleDefinitions.forEachIndexed { ruleOrdinal, definition ->
            monthKeys.forEachIndexed { monthOrdinal, month ->
                val expectedAtUtcMs = month.atDay(DAY_OF_MONTH)
                    .atTime(definition.localTimeMinutes / 60, definition.localTimeMinutes % 60)
                    .atZone(ZONE)
                    .toInstant()
                    .toEpochMilli()
                val occurrenceId = DemoDeterministicUlid.id(
                    NAMESPACE_OCCURRENCE,
                    ruleOrdinal * monthKeys.size + monthOrdinal,
                )
                val occurrence = FluviRecurrenceOccurrenceEntity(
                    id = occurrenceId,
                    ruleId = definition.id,
                    occurrenceKey = "%04d-%02d".format(month.year, month.monthValue),
                    ruleVersion = 1,
                    expectedLocalEpochDay = month.atDay(DAY_OF_MONTH).toEpochDay(),
                    expectedLocalTimeMinutes = definition.localTimeMinutes,
                    expectedAtUtcMs = expectedAtUtcMs,
                    timezoneId = ZONE.id,
                    partnerId = definition.partnerId,
                    categoryId = definition.categoryId,
                    categoryAssignmentMode = CategoryAssignmentMode.partnerDefault,
                    direction = definition.direction,
                    expectedAmountScaled100 = definition.amountScaled100,
                    amountPolicy = RecurrenceAmountPolicy.fixed,
                    note = definition.note,
                    triggerKind = RecurrenceTriggerKind.push,
                    status = definition.status,
                    realizationKind = definition.realizationKind,
                    resolvedAtUtcMs = if (definition.status == RecurrenceOccurrenceStatus.realized) {
                        expectedAtUtcMs
                    } else {
                        null
                    },
                    createdAtUtcMs = now,
                    updatedAtUtcMs = now,
                    revision = 1L,
                )
                if (recurrence.insertOccurrence(occurrence) != -1L) {
                    createdOccurrences += 1
                    if (definition.status == RecurrenceOccurrenceStatus.realized) {
                        val entry = FluviLedgerEntryEntity(
                            id = DemoDeterministicUlid.id(
                                NAMESPACE_LEDGER,
                                ruleOrdinal * monthKeys.size + monthOrdinal,
                            ),
                            partnerId = definition.partnerId,
                            categoryId = definition.categoryId,
                            categoryAssignmentMode = CategoryAssignmentMode.partnerDefault,
                            note = definition.note,
                            direction = definition.direction,
                            amountScaled100 = definition.amountScaled100,
                            bookedLocalEpochDay = occurrence.expectedLocalEpochDay,
                            bookedLocalTimeMinutes = definition.localTimeMinutes,
                            occurredAtUtcMs = expectedAtUtcMs,
                            originKind = LedgerOriginKind.recurring,
                            notificationInboxId = null,
                            recurrenceOccurrenceId = occurrenceId,
                            createdAtUtcMs = now,
                            updatedAtUtcMs = now,
                            revision = 1L,
                        )
                        ledger.insert(entry)
                        createdLedgerEntries += entry
                    }
                }
            }
        }

        val fixtureOccurrences = ruleDefinitions.flatMap { definition ->
            recurrence.occurrencesForRule(definition.id)
        }
        val realizedOccurrenceIds = fixtureOccurrences
            .filter { it.status == RecurrenceOccurrenceStatus.realized }
            .map { it.id }
        val fixtureLedgerEntryCount = realizedOccurrenceIds.count { occurrenceId ->
            database.ledgerDao().findByRecurrenceOccurrenceId(occurrenceId) != null
        }

        return GhostDemoSeedResult(
            createdCategoryCount = createdCategories,
            createdPartnerCount = createdPartners,
            createdRuleCount = createdRules,
            createdOccurrenceCount = createdOccurrences,
            createdLedgerEntries = createdLedgerEntries,
            occurrenceCount = fixtureOccurrences.size,
            pendingOccurrenceCount = fixtureOccurrences.count {
                it.status == RecurrenceOccurrenceStatus.pending
            },
            realizedOccurrenceCount = realizedOccurrenceIds.size,
            ledgerEntryCount = fixtureLedgerEntryCount,
        )
    }

    private data class CategoryDefinition(
        val id: String,
        val name: String,
        val colorId: String,
        val iconId: String,
    )

    private data class PartnerDefinition(
        val id: String,
        val aliasId: String,
        val name: String,
        val categoryId: String,
    )

    private data class RuleDefinition(
        val id: String,
        val name: String,
        val note: String,
        val partnerId: String,
        val categoryId: String,
        val status: RecurrenceOccurrenceStatus,
        val realizationKind: RecurrenceRealizationKind?,
        val direction: LedgerDirection,
        val amountScaled100: Long,
        val localTimeMinutes: Int,
    )

    companion object {
        private const val FIRST_YEAR = 2026
        private const val LAST_YEAR = 2027
        private const val DAY_OF_MONTH = 28
        private const val NAMESPACE_CATEGORY = 41
        private const val NAMESPACE_PARTNER = 42
        private const val NAMESPACE_ALIAS = 43
        private const val NAMESPACE_OCCURRENCE = 44
        private const val NAMESPACE_LEDGER = 45
        private val ZONE: ZoneId = ZoneId.of(DemoDatasetVersion.localZoneId)

        private val incomeCategoryId = DemoDeterministicUlid.id(NAMESPACE_CATEGORY, 0)
        private val expenseCategoryId = DemoDeterministicUlid.id(NAMESPACE_CATEGORY, 1)
        private val incomePartnerId = DemoDeterministicUlid.id(NAMESPACE_PARTNER, 0)
        private val expensePartnerId = DemoDeterministicUlid.id(NAMESPACE_PARTNER, 1)

        private val categoryDefinitions = listOf(
            CategoryDefinition(incomeCategoryId, "Demo ghost bevétel", "color_06", "icon_18"),
            CategoryDefinition(expenseCategoryId, "Demo ghost kiadás", "color_18", "icon_28"),
        )
        private val partnerDefinitions = listOf(
            PartnerDefinition(
                incomePartnerId,
                DemoDeterministicUlid.id(NAMESPACE_ALIAS, 0),
                "Fluvi demo ghost bevétel",
                incomeCategoryId,
            ),
            PartnerDefinition(
                expensePartnerId,
                DemoDeterministicUlid.id(NAMESPACE_ALIAS, 1),
                "Fluvi demo ghost kiadás",
                expenseCategoryId,
            ),
        )
        private val ruleDefinitions = listOf(
            RuleDefinition(
                id = DemoDeterministicUlid.id(NAMESPACE_OCCURRENCE, 100),
                name = "Demo ghost bevétel · várható",
                note = "Demo ghost bevétel · várható",
                partnerId = incomePartnerId,
                categoryId = incomeCategoryId,
                status = RecurrenceOccurrenceStatus.pending,
                realizationKind = null,
                direction = LedgerDirection.income,
                amountScaled100 = 10_000L * 100L,
                localTimeMinutes = 8 * 60,
            ),
            RuleDefinition(
                id = DemoDeterministicUlid.id(NAMESPACE_OCCURRENCE, 101),
                name = "Demo teljesített bevétel",
                note = "Demo teljesített bevétel",
                partnerId = incomePartnerId,
                categoryId = incomeCategoryId,
                status = RecurrenceOccurrenceStatus.realized,
                realizationKind = RecurrenceRealizationKind.manual,
                direction = LedgerDirection.income,
                amountScaled100 = 25_000L * 100L,
                localTimeMinutes = 10 * 60,
            ),
            RuleDefinition(
                id = DemoDeterministicUlid.id(NAMESPACE_OCCURRENCE, 102),
                name = "Demo ghost kiadás · várható",
                note = "Demo ghost kiadás · várható",
                partnerId = expensePartnerId,
                categoryId = expenseCategoryId,
                status = RecurrenceOccurrenceStatus.pending,
                realizationKind = null,
                direction = LedgerDirection.expense,
                amountScaled100 = 4_500L * 100L,
                localTimeMinutes = 12 * 60,
            ),
            RuleDefinition(
                id = DemoDeterministicUlid.id(NAMESPACE_OCCURRENCE, 103),
                name = "Demo teljesített kiadás",
                note = "Demo teljesített kiadás",
                partnerId = expensePartnerId,
                categoryId = expenseCategoryId,
                status = RecurrenceOccurrenceStatus.realized,
                realizationKind = RecurrenceRealizationKind.manual,
                direction = LedgerDirection.expense,
                amountScaled100 = 9_800L * 100L,
                localTimeMinutes = 18 * 60,
            ),
        )
        private val monthKeys = buildList {
            for (year in FIRST_YEAR..LAST_YEAR) {
                for (month in 1..12) add(java.time.YearMonth.of(year, month))
            }
        }
    }
}

internal data class GhostDemoSeedResult(
    val createdCategoryCount: Int,
    val createdPartnerCount: Int,
    val createdRuleCount: Int,
    val createdOccurrenceCount: Int,
    val createdLedgerEntries: List<FluviLedgerEntryEntity>,
    val occurrenceCount: Int,
    val pendingOccurrenceCount: Int,
    val realizedOccurrenceCount: Int,
    val ledgerEntryCount: Int,
) {
    val createdLedgerEntryCount: Int get() = createdLedgerEntries.size
    val changed: Boolean get() = createdCategoryCount > 0 || createdPartnerCount > 0 ||
        createdRuleCount > 0 || createdOccurrenceCount > 0
}
