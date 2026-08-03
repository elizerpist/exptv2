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
import com.fluvi.core.model.QuerySnapshotSlot
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
    fun dashboardDayGroupPageKeepsEveryDayWholeAndUsesDateKeysetPaging() = runBlocking {
        val oldestDay = LocalDate.of(2026, 3, 11)
        val middleDay = LocalDate.of(2026, 3, 12)
        val newestDay = LocalDate.of(2026, 3, 13)
        val newestFirst = insertEntry(
            categoryId = foodId,
            bookedDay = newestDay.toEpochDay(),
            bookedMinutes = 800,
            amount = 500_000L,
        )
        val newestSecond = insertEntry(
            categoryId = foodId,
            bookedDay = newestDay.toEpochDay(),
            bookedMinutes = 700,
            amount = 401_489L,
        )
        insertEntry(
            categoryId = clothesId,
            bookedDay = middleDay.toEpochDay(),
            amount = 200L,
        )
        insertEntry(
            categoryId = foodId,
            bookedDay = oldestDay.toEpochDay(),
            amount = 100L,
        )
        val scope = FluviQueryScope(direction = LedgerDirection.expense)

        val first = readService.dashboardDayGroupPage(scope, maxDayGroups = 2)
        val second = readService.dashboardDayGroupPage(
            scope,
            beforeLocalEpochDayExclusive = requireNotNull(first.nextBeforeLocalEpochDayExclusive),
            maxDayGroups = 2,
        )

        assertEquals(2, first.groups.size)
        assertEquals(newestDay.toEpochDay(), first.groups.first().bookedLocalEpochDay)
        assertEquals(
            listOf(newestFirst, newestSecond),
            first.groups.first().rows.map { it.entryId },
        )
        assertEquals(901_489L, first.groups.first().rows.sumOf { it.amountMinor })
        assertEquals(middleDay.toEpochDay(), first.groups.last().bookedLocalEpochDay)
        assertEquals(oldestDay.toEpochDay(), second.groups.single().bookedLocalEpochDay)
        assertEquals(null, second.nextBeforeLocalEpochDayExclusive)
    }

    @Test
    fun timeChildSummaryIndexUsesCanonicalParentPredicateAndSparseDayBuckets() = runBlocking {
        insertEntry(
            categoryId = foodId,
            bookedDay = LocalDate.of(2026, 3, 14).toEpochDay(),
            amount = 100L,
            note = "groceries",
        )
        insertEntry(
            categoryId = foodId,
            bookedDay = LocalDate.of(2026, 3, 15).toEpochDay(),
            amount = 250L,
            note = "groceries",
        )
        insertEntry(
            categoryId = clothesId,
            bookedDay = LocalDate.of(2026, 3, 15).toEpochDay(),
            amount = 999L,
            note = "clothes",
        )
        insertEntry(
            categoryId = foodId,
            bookedDay = LocalDate.of(2026, 4, 1).toEpochDay(),
            amount = 500L,
            note = "groceries",
        )
        val scope = FluviQueryScope(
            direction = LedgerDirection.expense,
            periodGroups = listOf(
                FluviPeriodGroup(
                    key = "time",
                    selections = setOf(FluviPeriodSelection.month("2026-03")),
                ),
            ),
            categoryIds = setOf(foodId),
            refinements = FluviQueryRefinements(noteContains = "groceries"),
        )

        val index = readService.timeChildSummaryIndex(scope, QueryPeriodKind.day)
        val values = index.values.associateBy { it.childPeriodValue }

        assertEquals(scope.direction, index.direction)
        assertEquals(QueryPeriodKind.day, index.childPeriodKind)
        assertTrue(index.isComplete)
        assertEquals(100L, values.getValue("2026-03-14").totalMinor)
        assertEquals(1L, values.getValue("2026-03-14").entryCount)
        assertEquals(250L, values.getValue("2026-03-15").totalMinor)
        assertEquals(1L, values.getValue("2026-03-15").entryCount)
        assertFalse(values.containsKey("2026-03-16"))
        assertEquals(
            "expense|day:2026-03-15|categories:$foodId|partners:|refinements:noteContains=groceries",
            values.getValue("2026-03-15").childQueryKey,
        )
    }

    @Test
    fun groupedChildSummaryKeepsAmountAndCountInTheSameMonthDay13Row() = runBlocking {
        listOf(200_000L, 200_000L, 200_000L, 301_489L).forEach { amount ->
            insertEntry(
                categoryId = foodId,
                bookedDay = LocalDate.of(2026, 3, 13).toEpochDay(),
                amount = amount,
            )
        }
        insertEntry(
            categoryId = foodId,
            bookedDay = LocalDate.of(2026, 3, 14).toEpochDay(),
            amount = 65_898_422L,
        )
        repeat(89) {
            insertEntry(
                categoryId = foodId,
                bookedDay = LocalDate.of(2026, 3, 14).toEpochDay(),
                amount = 1L,
            )
        }
        val parentScope = FluviQueryScope(
            direction = LedgerDirection.expense,
            periodGroups = listOf(
                FluviPeriodGroup(
                    key = "time",
                    selections = setOf(FluviPeriodSelection.month("2026-03")),
                ),
            ),
        )

        val parent = readService.total(parentScope)
        val index = readService.timeChildSummaryIndex(
            parentScope,
            QueryPeriodKind.day,
        )
        val child = index.values.single { it.childPeriodValue == "2026-03-13" }

        assertEquals(66_800_000L, parent.amountScaled100)
        assertEquals(94L, parent.entryCount)
        assertEquals(901_489L, child.totalMinor)
        assertEquals(4L, child.entryCount)
        assertEquals(
            "expense|day:2026-03-13|categories:|partners:|refinements:",
            child.childQueryKey,
        )
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

        val snapshotId = snapshots.save(QuerySnapshotSlot.snapshot1, scope)

        assertEquals(scope, snapshots.load(snapshotId, LedgerDirection.expense).scope)
        assertThrows(IllegalArgumentException::class.java) {
            runBlocking {
                snapshots.load(snapshotId, LedgerDirection.income)
            }
        }
        assertEquals(1, database.querySnapshotDao().allSnapshots().size)
        assertEquals(
            setOf(QuerySnapshotSlot.snapshot1),
            database.querySnapshotDao().allSnapshots().mapTo(linkedSetOf()) { it.slot },
        )
    }

    @Test
    fun twoFixedSnapshotSlotsReplaceOnlyTheirOwnSavedQuery() = runBlocking {
        val firstSnapshotId = snapshots.save(
            QuerySnapshotSlot.snapshot1,
            FluviQueryScope(
                direction = LedgerDirection.expense,
                categoryIds = setOf(foodId),
            ),
        )
        val replacementSnapshotId = snapshots.save(
            QuerySnapshotSlot.snapshot1,
            FluviQueryScope(
                direction = LedgerDirection.expense,
                categoryIds = setOf(clothesId),
            ),
        )
        val secondSlotSnapshotId = snapshots.save(
            QuerySnapshotSlot.snapshot2,
            FluviQueryScope(
                direction = LedgerDirection.expense,
                categoryIds = setOf(foodId),
            ),
        )

        assertNotEquals(firstSnapshotId, replacementSnapshotId)
        assertEquals(2, database.querySnapshotDao().allSnapshots().size)
        assertEquals(
            setOf(clothesId),
            snapshots.load(QuerySnapshotSlot.snapshot1, LedgerDirection.expense).scope.categoryIds,
        )
        assertEquals(
            secondSlotSnapshotId,
            snapshots.load(QuerySnapshotSlot.snapshot2, LedgerDirection.expense).id,
        )
    }

    @Test
    fun categoryDeletionRetargetsOnlySnapshotsThatContainTheDeletedCategory() = runBlocking {
        val foodSnapshotId = snapshots.save(
            QuerySnapshotSlot.snapshot1,
            FluviQueryScope(
                direction = LedgerDirection.expense,
                categoryIds = setOf(foodId),
            ),
        )
        val fallbackSnapshotId = snapshots.save(
            QuerySnapshotSlot.snapshot2,
            FluviQueryScope(
                direction = LedgerDirection.expense,
                categoryIds = setOf(FluviSystemIds.UNCATEGORIZED_CATEGORY),
            ),
        )

        categories.delete(foodId)

        assertEquals(
            setOf(FluviSystemIds.UNCATEGORIZED_CATEGORY),
            snapshots.load(foodSnapshotId, LedgerDirection.expense).scope.categoryIds,
        )
        assertEquals(
            setOf(FluviSystemIds.UNCATEGORIZED_CATEGORY),
            snapshots.load(fallbackSnapshotId, LedgerDirection.expense).scope.categoryIds,
        )
    }

    private suspend fun insertEntry(
        categoryId: String,
        bookedDay: Long,
        amount: Long,
        bookedMinutes: Int = 600,
        note: String? = null,
        partnerId: String = tescoId,
    ): String {
        val id = idGenerator.next()
        database.ledgerDao().insert(
            FluviLedgerEntryEntity(
                id = id,
                partnerId = partnerId,
                categoryId = categoryId,
                categoryAssignmentMode = CategoryAssignmentMode.partnerDefault,
                note = note,
                direction = LedgerDirection.expense,
                amountScaled100 = amount,
                bookedLocalEpochDay = bookedDay,
                bookedLocalTimeMinutes = bookedMinutes,
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
