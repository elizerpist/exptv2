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
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.LedgerOriginKind
import com.fluvi.core.model.QueryPeriodKind
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
        val categoryId = "00000000000000000000000010"
        val partnerId = "00000000000000000000000011"
        database.categoryDao().insert(
            FluviCategoryEntity(
                id = categoryId,
                name = "Scale",
                colorId = "color_02",
                iconId = "icon_02",
                isSystemUncategorized = false,
                createdAtUtcMs = 1_700_000_000_000L,
                updatedAtUtcMs = 1_700_000_000_000L,
            ),
        )
        database.partnerDao().insert(
            FluviPartnerEntity(
                id = partnerId,
                originalName = "Scale Partner",
                displayNameOverride = null,
                defaultCategoryId = categoryId,
                mergedIntoPartnerId = null,
                createdAtUtcMs = 1_700_000_000_000L,
                updatedAtUtcMs = 1_700_000_000_000L,
            ),
        )
        val entries = (0 until ENTRY_COUNT).map { index ->
            FluviLedgerEntryEntity(
                id = (index + 100).toString().padStart(26, '0'),
                partnerId = partnerId,
                categoryId = categoryId,
                categoryAssignmentMode = CategoryAssignmentMode.partnerDefault,
                note = null,
                direction = LedgerDirection.expense,
                amountScaled100 = (index + 1).toLong(),
                bookedLocalEpochDay = LocalDate.of(
                    2026,
                    3,
                    1 + (index % POPULATED_DAY_COUNT),
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
        assertEquals(ENTRY_COUNT.toLong(), total.entryCount)
        assertEquals(sumFromOneTo(ENTRY_COUNT), total.amountScaled100)
    }

    @Test
    fun fiveTwentyAndHundredThousandRowsKeepChildPreviewMaterializationBounded() =
        runBlocking {
            val march = FluviPeriodGroup(
                key = "time",
                selections = setOf(FluviPeriodSelection.month("2026-03")),
            )
            val cases = listOf(5_000, 20_000, 100_000)

            cases.forEach { expectedCount ->
                val minimum = ENTRY_COUNT - expectedCount + 1L
                val scope = FluviQueryScope(
                    direction = LedgerDirection.expense,
                    periodGroups = listOf(march),
                    refinements = FluviQueryRefinements(
                        minimumAmountScaled100 = minimum,
                    ),
                )

                val bundle = readService.childPreviewBundle(
                    scope = scope,
                    childPeriodKind = QueryPeriodKind.day,
                    previewPageSize = PREVIEW_PAGE_SIZE,
                )

                assertEquals(31, bundle.children.size)
                assertEquals(
                    expectedCount.toLong(),
                    bundle.children.sumOf { it.slice.entryCount },
                )
                assertEquals(
                    sumRange(minimum, ENTRY_COUNT.toLong()),
                    bundle.children.sumOf { it.slice.totalMinor },
                )
                assertEquals(
                    0L,
                    bundle.children.single {
                        it.childPeriodValue == "2026-03-31"
                    }.slice.entryCount,
                )
                assertEquals(POPULATED_DAY_COUNT, bundle.buildMetrics.aggregateBucketCount)
                assertTrue(
                    bundle.children.sumOf { it.slice.entries.size } <=
                        POPULATED_DAY_COUNT * PREVIEW_PAGE_SIZE,
                )
                assertTrue(
                    bundle.buildMetrics.materializedPreviewRowCount <=
                        POPULATED_DAY_COUNT * (PREVIEW_PAGE_SIZE + 1),
                )
            }
        }

    private fun sumFromOneTo(value: Int): Long =
        value.toLong() * (value + 1L) / 2L

    private fun sumRange(first: Long, last: Long): Long =
        (first + last) * (last - first + 1L) / 2L

    private companion object {
        const val ENTRY_COUNT = 100_000
        const val POPULATED_DAY_COUNT = 30
        const val PREVIEW_PAGE_SIZE = 3
    }
}
