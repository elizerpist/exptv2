package com.fluvi.core.query

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.FluviDatabaseFactory
import com.fluvi.core.database.entity.FluviCategoryEntity
import com.fluvi.core.database.entity.FLUVI_LEDGER_CHRONOLOGICAL_INDEX
import com.fluvi.core.database.entity.FLUVI_LEDGER_DASHBOARD_PREVIEW_INDEX
import com.fluvi.core.database.entity.FluviLedgerEntryEntity
import com.fluvi.core.database.entity.FluviPartnerEntity
import com.fluvi.core.model.CategoryAssignmentMode
import com.fluvi.core.model.FluviClock
import com.fluvi.core.model.FluviSystemIds
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.LedgerOriginKind
import com.fluvi.core.repository.FluviCategoryRepository
import com.fluvi.core.repository.FluviPartnerRepository
import java.time.LocalDate
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class FluviPreparedDashboardIndexTest {
    private lateinit var database: FluviDatabase
    private lateinit var readService: FluviLedgerReadService

    @Before
    fun setUp() = runBlocking {
        val context = ApplicationProvider.getApplicationContext<Context>()
        database = FluviDatabaseFactory.createInMemory(
            context = context,
            clock = FluviClock { NOW },
        )
        database.categoryDao().insert(
            FluviCategoryEntity(
                id = CATEGORY_ID,
                name = "Index",
                colorId = "color_02",
                iconId = "icon_02",
                isSystemUncategorized = false,
                createdAtUtcMs = NOW,
                updatedAtUtcMs = NOW,
            ),
        )
        database.partnerDao().insert(
            FluviPartnerEntity(
                id = PARTNER_ID,
                originalName = "Index Partner",
                displayNameOverride = null,
                defaultCategoryId = CATEGORY_ID,
                mergedIntoPartnerId = null,
                createdAtUtcMs = NOW,
                updatedAtUtcMs = NOW,
            ),
        )
        database.ledgerDao().insertAll(
            listOf(
                entry(1, LedgerDirection.income, LocalDate.of(2025, 5, 2), 100L),
                entry(2, LedgerDirection.income, LocalDate.of(2026, 3, 14), 200L),
                entry(3, LedgerDirection.expense, LocalDate.of(2026, 3, 14), 300L),
                entry(4, LedgerDirection.expense, LocalDate.of(2026, 3, 14), 400L),
                entry(5, LedgerDirection.expense, LocalDate.of(2026, 3, 31), 500L),
            ),
        )
        database.appSettingsDao().incrementCoreRevision(
            FluviSystemIds.APP_SETTINGS,
            NOW,
        )
        readService = FluviLedgerReadService(
            database = database,
            partnerRepository = FluviPartnerRepository(database),
            categoryRepository = FluviCategoryRepository(database),
        )
    }

    @After
    fun tearDown() = database.close()

    @Test
    fun oneConstantQueryBatchBuildsBothDirectionsAndEveryTemporalLevel() = runBlocking {
        val index = readService.preparedDashboardIndex(
            categoryIds = emptySet(),
            partnerIds = emptySet(),
            refinements = FluviQueryRefinements(),
            previewPageSize = 1,
            yearWindow = FluviPreparedYearWindow(2014, 2038),
            requestGeneration = 9L,
        )

        assertEquals(2L, index.coreRevision)
        assertEquals(9L, index.requestGeneration)
        assertEquals(5, index.buildMetrics.sqlCallCount)
        assertEquals(4, index.buildMetrics.aggregateBucketCount)

        val incomeAll = index.frame(LedgerDirection.income, "all")
        assertEquals(2L, incomeAll.entryCount)
        assertEquals(300L, incomeAll.totalMinor)
        assertEquals(1, incomeAll.rowIndices.size)
        assertNotNull(incomeAll.nextCursor)

        val expenseYear = index.frame(LedgerDirection.expense, "year:2026")
        val expenseMonth = index.frame(LedgerDirection.expense, "month:2026-03")
        val expenseDay = index.frame(LedgerDirection.expense, "day:2026-03-14")
        assertEquals(3L, expenseYear.entryCount)
        assertEquals(1_200L, expenseYear.totalMinor)
        assertEquals(expenseYear.entryCount, expenseMonth.entryCount)
        assertEquals(2L, expenseDay.entryCount)
        assertEquals(700L, expenseDay.totalMinor)
        assertNotNull(expenseDay.nextCursor)

        // The bounded row table contains only rows visible on a frame's first
        // page. The fifth ledger row is retained only to produce nextCursor.
        assertEquals(4, index.rows.size)
        assertEquals(index.rows.size, index.rows.map { it.entryId }.distinct().size)
        assertTrue(index.frames.sumOf { it.rowIndices.size } > index.rows.size)
        assertEquals(index.rows.size, index.buildMetrics.uniquePreviewRowCount)
        assertEquals(index.frames.size, index.buildMetrics.frameCount)
    }

    @Test
    fun filteredIndexStillUsesTheSameSqlCountAndOmitsZeroFrames() = runBlocking {
        val index = readService.preparedDashboardIndex(
            categoryIds = emptySet(),
            partnerIds = emptySet(),
            refinements = FluviQueryRefinements(minimumAmountScaled100 = 400L),
            previewPageSize = 2,
            yearWindow = FluviPreparedYearWindow(2014, 2038),
        )

        assertEquals(5, index.buildMetrics.sqlCallCount)
        assertEquals(2L, index.frame(LedgerDirection.expense, "all").entryCount)
        assertTrue(index.frames.none { it.timeScopeKey == "day:2026-03-15" })
        assertTrue(index.frames.none { it.direction == LedgerDirection.income })
    }

    @Test
    fun restrictivePeriodsAreAppliedBeforePreparedFrameAggregation() = runBlocking {
        val index = readService.preparedDashboardIndex(
            periodGroups = listOf(
                FluviPeriodGroup(
                    key = "query-time",
                    selections = setOf(FluviPeriodSelection.month("2026-03")),
                ),
            ),
            categoryIds = emptySet(),
            partnerIds = emptySet(),
            refinements = FluviQueryRefinements(),
            previewPageSize = 2,
            yearWindow = FluviPreparedYearWindow(2026, 2026),
        )

        assertEquals(3L, index.frame(LedgerDirection.expense, "all").entryCount)
        assertTrue(index.frames.none { it.timeScopeKey.contains("2025") })
        // PreparedDashboardIndex deliberately keeps both direction lanes warm;
        // the restrictive period predicate applies to both, while the applied
        // dashboard scope selects the visible direction later.
        assertEquals(1L, index.frame(LedgerDirection.income, "all").entryCount)
    }

    @Test
    fun directionalFiltersBuildOneIndexWithIndependentIncomeAndExpenseUniverses() = runBlocking {
        val index = readService.preparedDashboardIndex(
            directionalFilters = FluviDashboardDirectionalQuerySet(
                income = FluviQueryScope(direction = LedgerDirection.income),
                expense = FluviQueryScope(
                    direction = LedgerDirection.expense,
                    periodGroups = listOf(
                        FluviPeriodGroup(
                            key = "time",
                            selections = setOf(FluviPeriodSelection.month("2026-03")),
                        ),
                    ),
                    categoryIds = setOf(CATEGORY_ID),
                ),
            ),
            previewPageSize = 2,
            yearWindow = FluviPreparedYearWindow(2025, 2027),
        )

        assertEquals(5, index.buildMetrics.sqlCallCount)
        assertEquals(2L, index.frame(LedgerDirection.income, "all").entryCount)
        assertEquals(3L, index.frame(LedgerDirection.expense, "all").entryCount)
        assertTrue(index.frames.none {
            it.direction == LedgerDirection.expense && it.timeScopeKey == "year:2025"
        })
        assertTrue(index.frames.any {
            it.direction == LedgerDirection.income && it.timeScopeKey == "year:2025"
        })
        assertTrue(index.frames.single {
            it.direction == LedgerDirection.expense && it.timeScopeKey == "all"
        }.queryKey.contains("periods:time=month:2026-03"))
        assertTrue(index.frames.single {
            it.direction == LedgerDirection.income && it.timeScopeKey == "all"
        }.queryKey.contains("periods:").not())
    }

    @Test
    fun directionalPartitionBuildsOnlyTheRequestedExpenseUniverse() = runBlocking {
        val filters = FluviDashboardDirectionalQuerySet(
            income = FluviQueryScope(direction = LedgerDirection.income),
            expense = FluviQueryScope(
                direction = LedgerDirection.expense,
                periodGroups = listOf(
                    FluviPeriodGroup(
                        key = "time",
                        selections = setOf(FluviPeriodSelection.month("2026-03")),
                    ),
                ),
            ),
        )

        val partition = readService.preparedDashboardIndexPartition(
            direction = LedgerDirection.expense,
            directionalFilters = filters,
            previewPageSize = 2,
            yearWindow = FluviPreparedYearWindow(2025, 2027),
        )

        assertTrue(partition.rows.all { it.direction == LedgerDirection.expense })
        assertTrue(partition.frames.all { it.direction == LedgerDirection.expense })
        assertEquals(3L, partition.frame(LedgerDirection.expense, "all").entryCount)
        assertTrue(partition.frames.none { it.direction == LedgerDirection.income })
    }

    @Test
    fun cancelled_preparation_stops_before_later_native_mapping_phases() = runBlocking {
        var checkpointCount = 0
        val cancellable = FluviLedgerReadService(
            database = database,
            partnerRepository = FluviPartnerRepository(database),
            categoryRepository = FluviCategoryRepository(database),
            preparationCheckpoint = {
                checkpointCount += 1
                if (checkpointCount == 9) {
                    throw CancellationException("Synthetic supersession.")
                }
            },
        )

        var cancelled = false
        try {
            cancellable.preparedDashboardIndex(
                categoryIds = emptySet(),
                partnerIds = emptySet(),
                refinements = FluviQueryRefinements(),
                previewPageSize = 2,
                yearWindow = FluviPreparedYearWindow(2014, 2038),
            )
        } catch (_: CancellationException) {
            cancelled = true
        }

        assertTrue(cancelled)
        assertEquals(9, checkpointCount)
    }

    @Test
    fun boundedYearWindowKeepsAllTimeTotalsButOmitsOutsidePeriodFrames() = runBlocking {
        val index = readService.preparedDashboardIndex(
            categoryIds = emptySet(),
            partnerIds = emptySet(),
            refinements = FluviQueryRefinements(),
            previewPageSize = 1,
            yearWindow = FluviPreparedYearWindow(2026, 2026),
        )

        assertEquals(2L, index.frame(LedgerDirection.income, "all").entryCount)
        assertEquals(300L, index.frame(LedgerDirection.income, "all").totalMinor)
        assertTrue(index.frames.none { it.timeScopeKey.contains("2025") })
        assertTrue(index.frames.any { it.timeScopeKey == "year:2026" })
        assertEquals(5, index.buildMetrics.sqlCallCount)
    }

    @Test
    fun aggregateAndPreviewQueryPlansAvoidTemporarySortTrees() {
        val aggregate = explain(
            "SELECT direction, booked_local_epoch_day, COUNT(*), " +
                "COALESCE(SUM(amount_scaled_100), 0) " +
                "FROM fluvi_ledger_entries INDEXED BY " +
                FLUVI_LEDGER_CHRONOLOGICAL_INDEX +
                " GROUP BY direction, booked_local_epoch_day " +
                "ORDER BY direction ASC, booked_local_epoch_day ASC",
        )
        val preview = explain(
            "SELECT * FROM fluvi_ledger_entries INDEXED BY " +
                FLUVI_LEDGER_DASHBOARD_PREVIEW_INDEX +
                " ORDER BY direction ASC, booked_local_epoch_day DESC, " +
                "booked_local_time_minutes DESC, id DESC",
        )

        assertTrue(aggregate.any { it.contains(FLUVI_LEDGER_CHRONOLOGICAL_INDEX) })
        assertTrue(preview.any { it.contains(FLUVI_LEDGER_DASHBOARD_PREVIEW_INDEX) })
        assertTrue(aggregate.none { it.contains("TEMP B-TREE") })
        assertTrue(preview.none { it.contains("TEMP B-TREE") })
    }

    private fun explain(sql: String): List<String> {
        val details = mutableListOf<String>()
        database.openHelper.readableDatabase.query("EXPLAIN QUERY PLAN $sql").use { cursor ->
            val detailColumn = cursor.getColumnIndexOrThrow("detail")
            while (cursor.moveToNext()) details += cursor.getString(detailColumn)
        }
        return details
    }

    private fun FluviPreparedDashboardIndex.frame(
        direction: LedgerDirection,
        timeScopeKey: String,
    ): FluviPreparedDashboardIndexFrame = frames.single {
        it.direction == direction && it.timeScopeKey == timeScopeKey
    }

    private fun entry(
        ordinal: Int,
        direction: LedgerDirection,
        date: LocalDate,
        amount: Long,
    ) = FluviLedgerEntryEntity(
        id = (ordinal + 100).toString().padStart(26, '0'),
        partnerId = PARTNER_ID,
        categoryId = CATEGORY_ID,
        categoryAssignmentMode = CategoryAssignmentMode.partnerDefault,
        note = null,
        direction = direction,
        amountScaled100 = amount,
        bookedLocalEpochDay = date.toEpochDay(),
        bookedLocalTimeMinutes = 600 + ordinal,
        occurredAtUtcMs = NOW + ordinal,
        originKind = LedgerOriginKind.manual,
        notificationInboxId = null,
        createdAtUtcMs = NOW,
        updatedAtUtcMs = NOW,
        revision = 1L,
    )

    private companion object {
        const val NOW = 1_700_000_000_000L
        const val CATEGORY_ID = "00000000000000000000000010"
        const val PARTNER_ID = "00000000000000000000000011"
    }
}
