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
import com.fluvi.core.model.QueryPeriodKind
import com.fluvi.core.repository.FluviCategoryRepository
import com.fluvi.core.repository.FluviPartnerRepository
import java.time.LocalDate
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
class FluviPreparedDeckTest {
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
                name = "Prepared",
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
                originalName = "Prepared Partner",
                displayNameOverride = null,
                defaultCategoryId = CATEGORY_ID,
                mergedIntoPartnerId = null,
                createdAtUtcMs = NOW,
                updatedAtUtcMs = NOW,
            ),
        )
        val dates = listOf(
            LocalDate.of(2025, 5, 2),
            LocalDate.of(2026, 2, 28),
            LocalDate.of(2026, 3, 14),
            LocalDate.of(2026, 3, 14),
            LocalDate.of(2026, 3, 31),
            LocalDate.of(2026, 12, 9),
        )
        database.ledgerDao().insertAll(
            dates.mapIndexed { index, date -> entry(index, date) },
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
    fun monthDeckUsesConstantQueriesAndBoundedCompleteChildren() = runBlocking {
        val february = readService.preparedDeck(
            scope = monthScope(2),
            childPeriodKind = QueryPeriodKind.day,
            previewPageSize = 1,
            requestGeneration = 4L,
        )
        val march = readService.preparedDeck(
            scope = monthScope(3),
            childPeriodKind = QueryPeriodKind.day,
            previewPageSize = 1,
            requestGeneration = 5L,
        )

        assertEquals(28, february.children.size)
        assertEquals(31, march.children.size)
        assertEquals(6, february.buildMetrics.sqlCallCount)
        assertEquals(february.buildMetrics.sqlCallCount, march.buildMetrics.sqlCallCount)
        assertEquals(3L, march.parentSlice.entryCount)
        assertEquals(1_200L, march.parentSlice.totalMinor)
        val day14 = march.children.single { it.childPeriodValue == "2026-03-14" }.slice
        assertEquals(2L, day14.entryCount)
        assertEquals(700L, day14.totalMinor)
        assertEquals(1, day14.entries.size)
        assertNotNull(day14.nextCursor)
        assertEquals(0L, march.children.single {
            it.childPeriodValue == "2026-03-15"
        }.slice.entryCount)
        assertTrue(
            march.buildMetrics.materializedPreviewRowCount <=
                (march.children.size + 1) * 2,
        )
    }

    @Test
    fun yearAndSumDecksHaveFixedCatalogsAndTheSameSqlCount() = runBlocking {
        val year = readService.preparedDeck(
            scope = yearScope(2026),
            childPeriodKind = QueryPeriodKind.month,
            previewPageSize = 2,
        )
        val sum = readService.preparedDeck(
            scope = FluviQueryScope(direction = LedgerDirection.expense),
            childPeriodKind = QueryPeriodKind.year,
            previewPageSize = 2,
            yearWindow = FluviPreparedYearWindow(2014, 2038),
        )

        assertEquals(12, year.children.size)
        assertEquals(25, sum.children.size)
        assertEquals(6, year.buildMetrics.sqlCallCount)
        assertEquals(year.buildMetrics.sqlCallCount, sum.buildMetrics.sqlCallCount)
        assertEquals(1L, year.children.single {
            it.childPeriodValue == "2026-02"
        }.slice.entryCount)
        assertEquals(3L, year.children.single {
            it.childPeriodValue == "2026-03"
        }.slice.entryCount)
        assertEquals(1L, sum.children.single {
            it.childPeriodValue == "2025"
        }.slice.entryCount)
        assertEquals(5L, sum.children.single {
            it.childPeriodValue == "2026"
        }.slice.entryCount)
    }

    private fun monthScope(month: Int) = FluviQueryScope(
        direction = LedgerDirection.expense,
        periodGroups = listOf(
            FluviPeriodGroup(
                key = "time",
                selections = setOf(FluviPeriodSelection.month("2026-%02d".format(month))),
            ),
        ),
    )

    private fun yearScope(year: Int) = FluviQueryScope(
        direction = LedgerDirection.expense,
        periodGroups = listOf(
            FluviPeriodGroup(
                key = "time",
                selections = setOf(FluviPeriodSelection.year(year.toString())),
            ),
        ),
    )

    private fun entry(index: Int, date: LocalDate) = FluviLedgerEntryEntity(
        id = (index + 100).toString().padStart(26, '0'),
        partnerId = PARTNER_ID,
        categoryId = CATEGORY_ID,
        categoryAssignmentMode = CategoryAssignmentMode.partnerDefault,
        note = if (index == 3) "second" else null,
        direction = LedgerDirection.expense,
        amountScaled100 = (index + 1L) * 100L,
        bookedLocalEpochDay = date.toEpochDay(),
        bookedLocalTimeMinutes = 600 + index,
        occurredAtUtcMs = NOW + index,
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
