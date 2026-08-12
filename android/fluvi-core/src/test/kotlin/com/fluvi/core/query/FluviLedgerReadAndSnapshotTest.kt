package com.fluvi.core.query

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.FluviDatabaseFactory
import com.fluvi.core.database.entity.FluviLedgerEntryEntity
import com.fluvi.core.model.CategoryAssignmentMode
import com.fluvi.core.model.FluviClock
import com.fluvi.core.model.FluviIdGenerator
import com.fluvi.core.model.FluviSystemIds
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.LedgerOriginKind
import com.fluvi.core.model.QueryPeriodKind
import com.fluvi.core.repository.FluviCategoryRepository
import com.fluvi.core.repository.FluviLedgerRepository
import com.fluvi.core.repository.FluviPartnerRepository
import com.fluvi.core.sync.LedgerChangePublisher
import com.fluvi.core.sync.LedgerSheetProjection
import com.fluvi.core.sync.LedgerSyncOutboxRepository
import com.fluvi.core.usecase.FluviCategoryUseCase
import com.fluvi.core.usecase.FluviPartnerUseCase
import com.fluvi.core.usecase.FluviQuerySnapshotUseCase
import java.time.LocalDate
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class FluviLedgerReadAndSnapshotTest {
    private lateinit var database: FluviDatabase
    private lateinit var categories: FluviCategoryUseCase
    private lateinit var partners: FluviPartnerUseCase
    private lateinit var ledgerRepository: FluviLedgerRepository
    private lateinit var readService: FluviLedgerReadService
    private lateinit var snapshots: FluviQuerySnapshotUseCase
    private lateinit var idGenerator: TestIdGenerator

    private lateinit var foodId: String
    private lateinit var clothesId: String
    private lateinit var tescoId: String

    @Before
    fun setUp() = runBlocking {
        idGenerator = TestIdGenerator()
        val clock = FluviClock { 1_700_000_000_000L }
        val context = ApplicationProvider.getApplicationContext<Context>()
        database = FluviDatabaseFactory.createInMemory(context, clock)
        val categoryRepository = FluviCategoryRepository(database)
        val partnerRepository = FluviPartnerRepository(database)
        ledgerRepository = FluviLedgerRepository(database)
        val publisher = LedgerChangePublisher(
            LedgerSheetProjection(partnerRepository, categoryRepository),
            LedgerSyncOutboxRepository(database, clock),
        )
        categories = FluviCategoryUseCase(
            database = database,
            repository = categoryRepository,
            ledgerRepository = ledgerRepository,
            changePublisher = publisher,
            idGenerator = idGenerator,
            clock = clock,
        )
        partners = FluviPartnerUseCase(
            database = database,
            repository = partnerRepository,
            categoryRepository = categoryRepository,
            ledgerRepository = ledgerRepository,
            changePublisher = publisher,
            idGenerator = idGenerator,
            clock = clock,
        )
        readService = FluviLedgerReadService(database, partnerRepository, categoryRepository)
        snapshots = FluviQuerySnapshotUseCase(
            database = database,
            idGenerator = idGenerator,
            clock = clock,
        )

        foodId = categories.create("Food", "color_02", "icon_02")
        clothesId = categories.create("Clothes", "color_03", "icon_03")
        tescoId = partners.findOrCreate("Tesco", foodId)
    }

    @After
    fun tearDown() {
        database.close()
    }

    @Test
    fun explicitMonthsAreOrWithinOneTimeGroupAndTimePrefiltersFacets() = runBlocking {
        val januaryId = insertEntry(
            categoryId = foodId,
            bookedDay = LocalDate.of(2024, 1, 15).toEpochDay(),
            amount = 100L,
        )
        val ignoredMarchId = insertEntry(
            categoryId = foodId,
            bookedDay = LocalDate.of(2024, 3, 1).toEpochDay(),
            amount = 200L,
        )
        val februaryId = insertEntry(
            categoryId = clothesId,
            bookedDay = LocalDate.of(2026, 2, 2).toEpochDay(),
            amount = 300L,
        )
        val periodGroup = FluviPeriodGroup(
            key = "menu",
            selections = setOf(
                FluviPeriodSelection.month("2024-01"),
                FluviPeriodSelection.month("2026-02"),
            ),
        )
        val scope = FluviQueryScope(
            direction = LedgerDirection.expense,
            periodGroups = listOf(periodGroup),
        )

        val timeline = readService.timeline(scope, pageSize = 10)
        val facets = readService.timePrefilteredFacets(
            direction = LedgerDirection.expense,
            periodGroups = listOf(periodGroup),
        )

        assertEquals(setOf(januaryId, februaryId), timeline.entries.map { it.id }.toSet())
        assertFalse(timeline.entries.any { it.id == ignoredMarchId })
        assertEquals(setOf(foodId, clothesId), facets.categoryIds)
        assertEquals(setOf(tescoId), facets.partnerIds)
        assertEquals(2L, readService.total(scope).entryCount)
        assertEquals(400L, readService.total(scope).amountScaled100)
    }

    @Test
    fun explicitDaySelectionUsesTheSameHalfOpenLocalDatePredicate() = runBlocking {
        val matchingId = insertEntry(
            categoryId = foodId,
            bookedDay = LocalDate.of(2026, 2, 2).toEpochDay(),
            amount = 125L,
        )
        insertEntry(
            categoryId = foodId,
            bookedDay = LocalDate.of(2026, 2, 3).toEpochDay(),
            amount = 250L,
        )

        val scope = FluviQueryScope(
            direction = LedgerDirection.expense,
            periodGroups = listOf(
                FluviPeriodGroup(
                    key = "day",
                    selections = setOf(FluviPeriodSelection.day("2026-02-02")),
                ),
            ),
        )

        assertEquals(listOf(matchingId), readService.timeline(scope).entries.map { it.id })
        assertEquals(125L, readService.total(scope).amountScaled100)
    }

    @Test
    fun periodPredicateUsesIndexedEpochDayRangesWithOrInsideAndAcrossGroups() {
        val predicate = readService.periodGroupEpochDayPredicate(
            listOf(
                FluviPeriodGroup(
                    key = "months",
                    selections = setOf(
                        FluviPeriodSelection.month("2026-06"),
                        FluviPeriodSelection.month("2026-08"),
                    ),
                ),
                FluviPeriodGroup(
                    key = "day",
                    selections = setOf(FluviPeriodSelection.day("2026-08-01")),
                ),
            ),
            epochDayColumn = "ledger.booked_local_epoch_day",
        )!!

        assertFalse(predicate.sql.contains("strftime"))
        assertTrue(predicate.sql.contains(" OR "))
        assertTrue(predicate.sql.contains(" AND "))
        assertTrue(predicate.sql.contains("ledger.booked_local_epoch_day >= ?"))
        assertEquals(6, predicate.arguments.size)
    }

    @Test
    fun a156EntryCommittedMonthAdvancesBeyondIts24RowRootPage() = runBlocking {
        repeat(156) { ordinal ->
            insertEntry(
                categoryId = foodId,
                bookedDay = LocalDate.of(2025, 4, 18).toEpochDay(),
                amount = 100L + ordinal,
            )
        }
        val scope = FluviQueryScope(
            direction = LedgerDirection.expense,
            periodGroups = listOf(
                FluviPeriodGroup(
                    key = "navigation",
                    selections = setOf(FluviPeriodSelection.month("2025-04")),
                ),
            ),
        )

        val root = readService.readSlice(scope, pageSize = 24)
        val ordinalOne = readService.readSlice(
            scope,
            pageSize = 24,
            after = requireNotNull(root.nextCursor),
        )
        val ordinalTwo = readService.readSlice(
            scope,
            pageSize = 24,
            after = requireNotNull(ordinalOne.nextCursor),
        )

        assertEquals(156L, root.entryCount)
        assertEquals(24, root.entries.size)
        assertEquals(24, ordinalOne.entries.size)
        assertEquals(24, ordinalTwo.entries.size)
        assertEquals("month:2025-04", root.timeScopeKey)
        assertEquals(root.timeScopeKey, ordinalOne.timeScopeKey)
        assertEquals(root.queryKey, ordinalOne.queryKey)
        assertEquals(root.queryKey, ordinalTwo.queryKey)
        assertTrue(root.nextCursor != null)
        assertTrue(ordinalOne.nextCursor != null)
    }

    @Test
    fun committedPageUsesAuthoritativeAggregateAndKeepsExactKeysetRows() = runBlocking {
        val oldest = insertEntry(
            categoryId = foodId,
            bookedDay = LocalDate.of(2026, 6, 1).toEpochDay(),
            amount = 100L,
        )
        val middle = insertEntry(
            categoryId = clothesId,
            bookedDay = LocalDate.of(2026, 7, 1).toEpochDay(),
            amount = 200L,
        )
        val newest = insertEntry(
            categoryId = foodId,
            bookedDay = LocalDate.of(2026, 8, 1).toEpochDay(),
            amount = 300L,
        )
        val scope = FluviQueryScope(
            direction = LedgerDirection.expense,
            periodGroups = listOf(
                FluviPeriodGroup(
                    key = "time",
                    selections = setOf(
                        FluviPeriodSelection.month("2026-06"),
                        FluviPeriodSelection.month("2026-08"),
                    ),
                ),
            ),
        )
        val authoritative = readService.total(scope)
        val first = readService.readCommittedPage(
            scope = scope,
            pageSize = 1,
            after = null,
            expectedRevision = readService.currentCoreRevision(),
            authoritativeTotalMinor = authoritative.amountScaled100,
            authoritativeEntryCount = authoritative.entryCount,
        ).slice
        val second = readService.readCommittedPage(
            scope = scope,
            pageSize = 1,
            after = requireNotNull(first.nextCursor),
            expectedRevision = readService.currentCoreRevision(),
            authoritativeTotalMinor = authoritative.amountScaled100,
            authoritativeEntryCount = authoritative.entryCount,
        ).slice

        assertEquals(listOf(newest), first.entries.map { it.entryId })
        assertEquals(listOf(oldest), second.entries.map { it.entryId })
        assertEquals(2L, first.entryCount)
        assertEquals(400L, first.totalMinor)
        assertEquals(2L, second.entryCount)
        assertEquals(400L, second.totalMinor)
        assertFalse(first.entries.any { it.entryId == middle })
    }

    @Test
    fun committedPageRejectsARevisionThatIsNotTheCommittedSnapshot() = runBlocking {
        insertEntry(
            categoryId = foodId,
            bookedDay = LocalDate.of(2026, 6, 1).toEpochDay(),
            amount = 100L,
        )
        val scope = FluviQueryScope(direction = LedgerDirection.expense)

        assertThrows(IllegalArgumentException::class.java) {
            runBlocking {
                readService.readCommittedPage(
                    scope = scope,
                    pageSize = 24,
                    after = null,
                    expectedRevision = readService.currentCoreRevision() + 1,
                    authoritativeTotalMinor = 100L,
                    authoritativeEntryCount = 1L,
                )
            }
        }
        Unit
    }

    @Test
    fun committedPageKeepsCategoryPartnerPeriodAndRefinementPredicatesExact() = runBlocking {
        val bookshopId = partners.findOrCreate("Bookshop", clothesId)
        val matchingId = insertEntry(
            categoryId = foodId,
            partnerId = tescoId,
            bookedDay = LocalDate.of(2026, 8, 1).toEpochDay(),
            amount = 150L,
            note = "Lunch delivery",
        )
        insertEntry(
            categoryId = clothesId,
            partnerId = tescoId,
            bookedDay = LocalDate.of(2026, 8, 1).toEpochDay(),
            amount = 150L,
            note = "Lunch delivery",
        )
        insertEntry(
            categoryId = foodId,
            partnerId = bookshopId,
            bookedDay = LocalDate.of(2026, 8, 1).toEpochDay(),
            amount = 150L,
            note = "Lunch delivery",
        )
        insertEntry(
            categoryId = foodId,
            partnerId = tescoId,
            bookedDay = LocalDate.of(2026, 7, 1).toEpochDay(),
            amount = 150L,
            note = "Lunch delivery",
        )
        val scope = FluviQueryScope(
            direction = LedgerDirection.expense,
            periodGroups = listOf(
                FluviPeriodGroup(
                    key = "month",
                    selections = setOf(FluviPeriodSelection.month("2026-08")),
                ),
            ),
            categoryIds = setOf(foodId),
            partnerIds = setOf(tescoId),
            refinements = FluviQueryRefinements(
                minimumAmountScaled100 = 100L,
                maximumAmountScaled100 = 200L,
                noteContains = "delivery",
            ),
        )
        val authoritative = readService.total(scope)

        val page = readService.readCommittedPage(
            scope = scope,
            pageSize = 24,
            after = null,
            expectedRevision = readService.currentCoreRevision(),
            authoritativeTotalMinor = authoritative.amountScaled100,
            authoritativeEntryCount = authoritative.entryCount,
        ).slice

        assertEquals(listOf(matchingId), page.entries.map { it.entryId })
        assertEquals(1L, page.entryCount)
        assertEquals(150L, page.totalMinor)
    }

    @Test
    fun queryMenuFacetsUseTemporalSqlAggregatesAndCategoryVisualMetadata() = runBlocking {
        insertEntry(
            categoryId = foodId,
            bookedDay = LocalDate.of(2026, 2, 2).toEpochDay(),
            amount = 125L,
        )
        insertEntry(
            categoryId = clothesId,
            bookedDay = LocalDate.of(2025, 2, 2).toEpochDay(),
            amount = 250L,
        )
        insertEntry(
            categoryId = foodId,
            bookedDay = LocalDate.of(2027, 1, 2).toEpochDay(),
            amount = 500L,
            direction = LedgerDirection.income,
        )

        val facets = readService.queryMenuFacets(
            FluviQueryScope(
                direction = LedgerDirection.expense,
                periodGroups = listOf(
                    FluviPeriodGroup(
                        key = "time",
                        selections = setOf(FluviPeriodSelection.month("2026-02")),
                    ),
                ),
            ),
        )

        assertEquals(1L, facets.result.entryCount)
        assertEquals(125L, facets.result.amountScaled100)
        assertEquals(125L, facets.amountDomain.minimumAmountScaled100)
        assertEquals(125L, facets.amountDomain.maximumAmountScaled100)
        // Time choices remain real and direction-scoped, but are not narrowed
        // by the draft's own selected month: the user must be able to replace
        // February with another represented month in the same sheet.
        assertEquals(
            listOf(
                FluviQueryAvailableMonth(year = 2025, month = 2),
                FluviQueryAvailableMonth(year = 2026, month = 2),
            ),
            facets.availableMonths,
        )
        assertEquals(listOf(foodId), facets.categories.map { it.id })
        assertEquals("Food", facets.categories.single().displayName)
        assertEquals("color_02", facets.categories.single().colorId)
        assertEquals(listOf(tescoId), facets.partners.map { it.id })
        assertEquals(foodId, facets.partners.single().categoryId)
        assertEquals("color_02", facets.partners.single().categoryColorId)
    }

    @Test
    fun queryMenuFacetsRemainDirectionAffineForTheSameTemporalScope() = runBlocking {
        val salaryId = categories.create("Salary", "color_10", "icon_10")
        val employerId = partners.findOrCreate("Employer", salaryId)
        val bookshopId = partners.findOrCreate("Bookshop", clothesId)
        insertEntry(
            categoryId = foodId,
            partnerId = tescoId,
            bookedDay = LocalDate.of(2025, 7, 2).toEpochDay(),
            amount = 125L,
            direction = LedgerDirection.expense,
        )
        insertEntry(
            categoryId = clothesId,
            partnerId = bookshopId,
            bookedDay = LocalDate.of(2025, 7, 3).toEpochDay(),
            amount = 250L,
            direction = LedgerDirection.expense,
        )
        insertEntry(
            categoryId = foodId,
            partnerId = tescoId,
            bookedDay = LocalDate.of(2025, 6, 3).toEpochDay(),
            amount = 40L,
            direction = LedgerDirection.expense,
        )
        insertEntry(
            categoryId = salaryId,
            partnerId = employerId,
            bookedDay = LocalDate.of(2025, 7, 4).toEpochDay(),
            amount = 1_000L,
            direction = LedgerDirection.income,
        )
        insertEntry(
            categoryId = salaryId,
            partnerId = employerId,
            bookedDay = LocalDate.of(2025, 8, 4).toEpochDay(),
            amount = 1_200L,
            direction = LedgerDirection.income,
        )
        val periodGroups = listOf(
            FluviPeriodGroup(
                key = "time",
                selections = setOf(FluviPeriodSelection.month("2025-07")),
            ),
        )

        val expense = readService.queryMenuFacets(
            FluviQueryScope(
                direction = LedgerDirection.expense,
                periodGroups = periodGroups,
            ),
        )
        val income = readService.queryMenuFacets(
            FluviQueryScope(
                direction = LedgerDirection.income,
                periodGroups = periodGroups,
            ),
        )

        assertEquals(2L, expense.result.entryCount)
        assertEquals(setOf(foodId, clothesId), expense.categories.map { it.id }.toSet())
        assertEquals(setOf(tescoId, bookshopId), expense.partners.map { it.id }.toSet())
        assertEquals(1L, income.result.entryCount)
        assertEquals(listOf(salaryId), income.categories.map { it.id })
        assertEquals(listOf(employerId), income.partners.map { it.id })
        assertEquals(
            listOf(
                FluviQueryAvailableMonth(year = 2025, month = 6),
                FluviQueryAvailableMonth(year = 2025, month = 7),
            ),
            expense.availableMonths,
        )
        assertEquals(
            listOf(
                FluviQueryAvailableMonth(year = 2025, month = 7),
                FluviQueryAvailableMonth(year = 2025, month = 8),
            ),
            income.availableMonths,
        )
    }

    @Test
    fun categoryPartnerAndRefinementFacetsUseOrWithinAndAcrossSemantics() = runBlocking {
        val anotherPartnerId = partners.findOrCreate("Bookshop", clothesId)
        val matchingId = insertEntry(
            categoryId = foodId,
            bookedDay = LocalDate.of(2025, 1, 2).toEpochDay(),
            amount = 250L,
            note = "weekly groceries",
        )
        insertEntry(
            categoryId = clothesId,
            bookedDay = LocalDate.of(2025, 1, 3).toEpochDay(),
            amount = 250L,
            note = "book",
            partnerId = anotherPartnerId,
        )
        insertEntry(
            categoryId = foodId,
            bookedDay = LocalDate.of(2025, 1, 4).toEpochDay(),
            amount = 20L,
            note = "small groceries",
        )

        val page = readService.timeline(
            FluviQueryScope(
                direction = LedgerDirection.expense,
                categoryIds = setOf(foodId, clothesId),
                partnerIds = setOf(tescoId),
                refinements = FluviQueryRefinements(
                    minimumAmountScaled100 = 100L,
                    noteContains = "groceries",
                ),
            ),
            pageSize = 10,
        )

        assertEquals(listOf(matchingId), page.entries.map { it.id })
    }

    @Test
    fun queryTextRefinementSearchesPartnerCategoryAndNoteInSql() = runBlocking {
        val bookshopId = partners.findOrCreate("Bookshop", clothesId)
        val partnerMatch = insertEntry(
            categoryId = foodId,
            partnerId = tescoId,
            bookedDay = LocalDate.of(2026, 2, 1).toEpochDay(),
            amount = 100L,
            note = null,
        )
        val categoryMatch = insertEntry(
            categoryId = clothesId,
            partnerId = bookshopId,
            bookedDay = LocalDate.of(2026, 2, 2).toEpochDay(),
            amount = 200L,
            note = null,
        )
        val noteMatch = insertEntry(
            categoryId = foodId,
            partnerId = bookshopId,
            bookedDay = LocalDate.of(2026, 2, 3).toEpochDay(),
            amount = 300L,
            note = "weekly refill",
        )

        suspend fun ids(search: String): Set<String> = readService.timeline(
            FluviQueryScope(
                direction = LedgerDirection.expense,
                refinements = FluviQueryRefinements(noteContains = search),
            ),
            pageSize = 10,
        ).entries.mapTo(linkedSetOf()) { it.id }

        assertEquals(setOf(partnerMatch), ids("Tesco"))
        assertEquals(setOf(categoryMatch), ids("Clothes"))
        assertEquals(setOf(noteMatch), ids("refill"))
    }

    @Test
    fun timelineUsesStableKeysetPagesAndSqlAggregates() = runBlocking {
        val oldestId = insertEntry(
            categoryId = foodId,
            bookedDay = LocalDate.of(2025, 1, 1).toEpochDay(),
            amount = 100L,
        )
        val middleId = insertEntry(
            categoryId = clothesId,
            bookedDay = LocalDate.of(2025, 1, 2).toEpochDay(),
            amount = 200L,
        )
        val newestId = insertEntry(
            categoryId = foodId,
            bookedDay = LocalDate.of(2025, 1, 3).toEpochDay(),
            amount = 300L,
        )
        val scope = FluviQueryScope(direction = LedgerDirection.expense)

        val firstPage = readService.timeline(scope, pageSize = 2)
        val secondPage = readService.timeline(
            scope = scope,
            after = requireNotNull(firstPage.nextCursor),
            pageSize = 2,
        )
        val categorySummary = readService.summaryByCategory(scope)

        assertEquals(listOf(newestId, middleId), firstPage.entries.map { it.id })
        assertEquals(listOf(oldestId), secondPage.entries.map { it.id })
        assertEquals(3L, readService.total(scope).entryCount)
        assertEquals(600L, readService.total(scope).amountScaled100)
        assertEquals(400L, categorySummary.single { it.id == foodId }.amountScaled100)
        assertEquals(200L, categorySummary.single { it.id == clothesId }.amountScaled100)
    }


    @Test
    fun savedSnapshotIsDirectionAffineAndDoesNotPersistCurrentQueryState() = runBlocking {
        val scope = FluviQueryScope(
            direction = LedgerDirection.expense,
            periodGroups = listOf(
                FluviPeriodGroup(
                    key = "menu",
                    selections = setOf(FluviPeriodSelection.year("2025")),
                ),
            ),
            categoryIds = setOf(foodId),
            partnerIds = setOf(tescoId),
            refinements = FluviQueryRefinements(noteContains = "weekly"),
        )

        val saved = snapshots.create("Heti kiadások", scope)
        val snapshotId = saved.id

        assertEquals(scope, snapshots.load(snapshotId, LedgerDirection.expense).scope)
        assertThrows(IllegalArgumentException::class.java) {
            runBlocking {
                snapshots.load(snapshotId, LedgerDirection.income)
            }
        }
        assertEquals(1, database.querySnapshotDao().allSnapshots().size)
        assertEquals("Heti kiadások", snapshots.list(LedgerDirection.expense).single().name)
    }

    @Test
    fun namedSavedQueriesAreIndependentAndCanBeUpdatedWithoutReplacingAnother() = runBlocking {
        val grocery = snapshots.create(
            name = "Havi élelmiszer",
            scope = FluviQueryScope(
                direction = LedgerDirection.expense,
                categoryIds = setOf(foodId),
            ),
        )
        val clothes = snapshots.create(
            name = "Ruházat",
            scope = FluviQueryScope(
                direction = LedgerDirection.expense,
                categoryIds = setOf(clothesId),
            ),
        )

        snapshots.update(
            snapshotId = grocery.id,
            name = "Havi bevásárlás",
            scope = grocery.scope.copy(
                partnerIds = setOf(tescoId),
            ),
        )

        val saved = snapshots.list(LedgerDirection.expense)
        assertEquals(listOf("Havi bevásárlás", "Ruházat"), saved.map { it.name })
        assertEquals(setOf(tescoId), snapshots.load(grocery.id, LedgerDirection.expense).scope.partnerIds)
        assertEquals(clothes.id, snapshots.load(clothes.id, LedgerDirection.expense).id)
    }

    @Test
    fun renameChangesOnlySavedQueryMetadataAndKeepsTypedConfiguration() = runBlocking {
        val saved = snapshots.create(
            name = "Élelmiszer",
            scope = FluviQueryScope(
                direction = LedgerDirection.expense,
                categoryIds = setOf(foodId),
                partnerIds = setOf(tescoId),
            ),
        )

        val renamed = snapshots.rename(saved.id, "Havi élelmiszer")

        assertEquals("Havi élelmiszer", renamed.name)
        assertEquals(saved.scope, renamed.scope)
        assertEquals(saved.scope, snapshots.load(saved.id, LedgerDirection.expense).scope)
    }

    @Test
    fun savedQueryMetadataOperationsDoNotAdvanceTheLedgerRevision() = runBlocking {
        val revisionBefore = requireNotNull(database.appSettingsDao().current()).coreRevision
        val saved = snapshots.create(
            name = "Élelmiszer",
            scope = FluviQueryScope(
                direction = LedgerDirection.expense,
                categoryIds = setOf(foodId),
            ),
        )

        snapshots.rename(saved.id, "Havi élelmiszer")
        snapshots.update(
            snapshotId = saved.id,
            name = "Havi élelmiszer",
            scope = saved.scope.copy(partnerIds = setOf(tescoId)),
        )
        snapshots.delete(saved.id)

        assertEquals(
            revisionBefore,
            requireNotNull(database.appSettingsDao().current()).coreRevision,
        )
    }

    @Test
    fun categoryDeletionRetargetsOnlySnapshotsThatContainTheDeletedCategory() = runBlocking {
        val foodSnapshotId = snapshots.create(
            "Étel",
            FluviQueryScope(
                direction = LedgerDirection.expense,
                categoryIds = setOf(foodId),
            ),
        )
        val fallbackSnapshotId = snapshots.create(
            "Nem kategorizált",
            FluviQueryScope(
                direction = LedgerDirection.expense,
                categoryIds = setOf(FluviSystemIds.UNCATEGORIZED_CATEGORY),
            ),
        )

        categories.delete(foodId)

        assertEquals(
            setOf(FluviSystemIds.UNCATEGORIZED_CATEGORY),
            snapshots.load(foodSnapshotId.id, LedgerDirection.expense).scope.categoryIds,
        )
        assertEquals(
            setOf(FluviSystemIds.UNCATEGORIZED_CATEGORY),
            snapshots.load(fallbackSnapshotId.id, LedgerDirection.expense).scope.categoryIds,
        )
    }

    private suspend fun insertEntry(
        categoryId: String,
        bookedDay: Long,
        amount: Long,
        note: String? = null,
        partnerId: String = tescoId,
        direction: LedgerDirection = LedgerDirection.expense,
    ): String {
        val id = idGenerator.next()
        database.ledgerDao().insert(
            FluviLedgerEntryEntity(
                id = id,
                partnerId = partnerId,
                categoryId = categoryId,
                categoryAssignmentMode = CategoryAssignmentMode.partnerDefault,
                note = note,
                direction = direction,
                amountScaled100 = amount,
                bookedLocalEpochDay = bookedDay,
                bookedLocalTimeMinutes = 600,
                occurredAtUtcMs = 1_700_000_000_000L,
                originKind = LedgerOriginKind.manual,
                notificationInboxId = null,
                createdAtUtcMs = 1_700_000_000_000L,
                updatedAtUtcMs = 1_700_000_000_000L,
                revision = 1L,
            ),
        )
        return id
    }

    private class TestIdGenerator : FluviIdGenerator {
        private var nextValue = 1_000L

        override fun next(): String = nextValue++.toString().padStart(26, '0')
    }
}
