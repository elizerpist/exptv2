package com.fluvi.core.query

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.FluviDatabaseFactory
import com.fluvi.core.database.entity.FluviCategoryEntity
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
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class FluviLedgerLargeDatasetTest {
    private lateinit var database: FluviDatabase
    private lateinit var readService: FluviLedgerReadService

    @Before
    fun setUp() = runBlocking {
        val context = ApplicationProvider.getApplicationContext<Context>()
        database = FluviDatabaseFactory.createInMemory(
            context = context,
            clock = FluviClock { 1_700_000_000_000L },
        )
        val categories = (0 until CATEGORY_COUNT).map { ordinal ->
            FluviCategoryEntity(
                id = (ordinal + 10).toString().padStart(26, '0'),
                name = "Scale $ordinal",
                colorId = "color_0${ordinal + 2}",
                iconId = "icon_0${ordinal + 2}",
                isSystemUncategorized = false,
                createdAtUtcMs = 1_700_000_000_000L,
                updatedAtUtcMs = 1_700_000_000_000L,
            )
        }
        for (category in categories) {
            database.categoryDao().insert(category)
        }
        val partners = categories.mapIndexed { ordinal, category ->
            FluviPartnerEntity(
                id = (ordinal + 100).toString().padStart(26, '0'),
                originalName = "Scale Partner $ordinal",
                displayNameOverride = null,
                defaultCategoryId = category.id,
                mergedIntoPartnerId = null,
                createdAtUtcMs = 1_700_000_000_000L,
                updatedAtUtcMs = 1_700_000_000_000L,
            )
        }
        for (partner in partners) {
            database.partnerDao().insert(partner)
        }
        val entries = (0 until ENTRY_COUNT).map { index ->
            val category = categories[index % categories.size]
            val partner = partners[index % partners.size]
            FluviLedgerEntryEntity(
                id = (index + 100).toString().padStart(26, '0'),
                partnerId = partner.id,
                categoryId = category.id,
                categoryAssignmentMode = CategoryAssignmentMode.partnerDefault,
                note = null,
                direction = if (index % 2 == 0) LedgerDirection.expense else LedgerDirection.income,
                amountScaled100 = (index + 1).toLong(),
                bookedLocalEpochDay = LocalDate.of(
                    2018 + (index % YEAR_COUNT),
                    // March–December retains thirty valid day slots while
                    // January and February stay intentionally empty.
                    3 + ((index / YEAR_COUNT) % POPULATED_MONTHS_PER_YEAR),
                    1 + ((index / (YEAR_COUNT * POPULATED_MONTHS_PER_YEAR)) % POPULATED_DAY_COUNT),
                ).toEpochDay(),
                bookedLocalTimeMinutes = index % 1_440,
                occurredAtUtcMs = 1_700_000_000_000L + index,
                originKind = LedgerOriginKind.manual,
                notificationInboxId = null,
                createdAtUtcMs = 1_700_000_000_000L,
                updatedAtUtcMs = 1_700_000_000_000L,
                revision = 1L,
            )
        }
        entries.chunked(500).forEach { chunk -> database.ledgerDao().insertAll(chunk) }
        database.appSettingsDao().incrementCoreRevision(
            settingsId = FluviSystemIds.APP_SETTINGS,
            updatedAtUtcMs = 1_700_000_000_000L,
        )
        readService = FluviLedgerReadService(
            database = database,
            partnerRepository = FluviPartnerRepository(database),
            categoryRepository = FluviCategoryRepository(database),
        )
    }

    @After
    fun tearDown() {
        database.close()
    }

    @Test
    fun hundredThousandRowsReturnABoundedKeysetPageAndSqlTotal() = runBlocking {
        val scope = FluviQueryScope(direction = LedgerDirection.expense)

        val firstPage = readService.timeline(scope, pageSize = 75)
        val secondPage = readService.timeline(
            scope = scope,
            after = requireNotNull(firstPage.nextCursor),
            pageSize = 75,
        )
        val total = readService.total(scope)

        assertEquals(75, firstPage.entries.size)
        assertEquals(75, secondPage.entries.size)
        assertEquals(ENTRY_COUNT.toLong() / 2L, total.entryCount)
        assertEquals(sumOddValues(1, ENTRY_COUNT.toLong()), total.amountScaled100)
    }

    @Test
    fun sevenHundredToHundredThousandRowsKeepGlobalIndexMaterializationBounded() =
        runBlocking {
            val cases = listOf(700, 10_000, 50_000, 100_000)

            cases.forEach { expectedCount ->
                val minimum = ENTRY_COUNT - expectedCount + 1L
                val heapBefore = usedHeapBytes()
                val buildStartedAt = System.nanoTime()
                val index = readService.preparedDashboardIndex(
                    categoryIds = emptySet(),
                    partnerIds = emptySet(),
                    refinements = FluviQueryRefinements(
                        minimumAmountScaled100 = minimum,
                    ),
                    previewPageSize = PREVIEW_PAGE_SIZE,
                    yearWindow = FluviPreparedYearWindow(2014, 2038),
                )
                val elapsedNanos = System.nanoTime() - buildStartedAt
                val heapAfter = usedHeapBytes()
                val peakHeapObservedBytes = maxOf(heapBefore, heapAfter)
                val expenseFrames = index.frames.filter {
                    it.direction == LedgerDirection.expense
                }
                val all = expenseFrames.single { it.timeScopeKey == "all" }
                val daily = expenseFrames.filter { it.timeScopeKey.startsWith("day:") }

                assertEquals(expenseEntryCount(minimum, ENTRY_COUNT.toLong()), all.entryCount)
                assertEquals(sumOddValues(minimum, ENTRY_COUNT.toLong()), all.totalMinor)
                assertTrue(daily.isNotEmpty())
                assertEquals(5, index.buildMetrics.sqlCallCount)
                assertEquals(expectedCount, index.buildMetrics.scannedLedgerRowCount)
                assertTrue(index.buildMetrics.aggregateBucketCount > 0)
                assertTrue(
                    index.rows.size <= index.frames.size * PREVIEW_PAGE_SIZE,
                )
                assertEquals(index.rows.size, index.buildMetrics.uniquePreviewRowCount)
                val estimatedIndexBytes =
                    index.rows.size * 256L +
                        index.frames.size * 192L +
                        index.frames.sumOf { it.rowIndices.size } * Int.SIZE_BYTES
                println(
                    "[DASHBOARD_STRESS] " +
                        "entries=$expectedCount sqlCalls=${index.buildMetrics.sqlCallCount} " +
                        "sqlMicros=${index.buildMetrics.sqlDurationNanos / 1_000L} " +
                        "scannedRows=${index.buildMetrics.scannedLedgerRowCount} " +
                        "aggregateBuckets=${index.buildMetrics.aggregateBucketCount} " +
                        "queryMicros=${index.buildMetrics.queryDurationNanos / 1_000L} " +
                        "aggregationMicros=${index.buildMetrics.aggregationDurationNanos / 1_000L} " +
                        "mappingMicros=${index.buildMetrics.mappingDurationNanos / 1_000L} " +
                        "elapsedMicros=${elapsedNanos / 1_000L} " +
                        "rows=${index.rows.size} frames=${index.frames.size} " +
                        "estimatedIndexBytes=$estimatedIndexBytes " +
                        "heapBeforeBytes=$heapBefore heapAfterBytes=$heapAfter " +
                        "peakHeapObservedBytes=$peakHeapObservedBytes",
                )
            }
        }

    private fun usedHeapBytes(): Long = Runtime.getRuntime().let { runtime ->
        runtime.totalMemory() - runtime.freeMemory()
    }

    private fun expenseEntryCount(first: Long, last: Long): Long =
        (last + 1L) / 2L - first / 2L

    private fun sumOddValues(first: Long, last: Long): Long =
        sumOddsThrough(last) - sumOddsThrough(first - 1L)

    private fun sumOddsThrough(value: Long): Long {
        if (value <= 0L) return 0L
        val oddCount = (value + 1L) / 2L
        return oddCount * oddCount
    }

    private companion object {
        const val ENTRY_COUNT = 100_000
        const val CATEGORY_COUNT = 4
        const val YEAR_COUNT = 8
        const val POPULATED_MONTHS_PER_YEAR = 10
        const val POPULATED_DAY_COUNT = 30
        const val PREVIEW_PAGE_SIZE = 3
    }
}
