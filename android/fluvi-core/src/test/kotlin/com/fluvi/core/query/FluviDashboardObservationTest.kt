package com.fluvi.core.query

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.fluvi.core.FluviCore
import com.fluvi.core.FluviCoreFactory
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.QueryPeriodKind
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.async
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
class FluviDashboardObservationTest {
    private lateinit var core: FluviCore

    @Before
    fun setUp() {
        core = FluviCoreFactory.createInMemory(
            ApplicationProvider.getApplicationContext<Context>(),
        )
    }

    @After
    fun tearDown() {
        core.close()
    }

    @Test
    fun sliceUsesOneScopeForTotalAndStableLedgerPage() = runBlocking {
        core.demoSeed.seed()
        val scope = monthScope(LedgerDirection.expense, 7)

        val slice = core.query.readSlice(scope, pageSize = 50)

        assertEquals("expense|month:2026-07|categories:|partners:|refinements:", slice.queryKey)
        assertEquals(94, slice.entryCount)
        assertEquals(689_000L * 100L, slice.totalMinor)
        assertEquals(50, slice.entries.size)
        assertNotNull(slice.nextCursor)
        assertTrue(slice.entries.all { it.categoryColorId.startsWith("color_") })
        assertTrue(slice.entries.all { it.categoryIconId.startsWith("icon_") })
        assertTrue(slice.entries.zipWithNext().all { (left, right) ->
            left.bookedLocalEpochDay >= right.bookedLocalEpochDay
        })
    }

    @Test
    fun committedDashboardNavigationIdentityNeverSerializesItsTransportGroup() = runBlocking {
        core.demoSeed.seed()

        val month = core.query.readSlice(
            navigationScope(
                direction = LedgerDirection.expense,
                selection = FluviPeriodSelection.month("2026-07"),
            ),
            pageSize = 24,
        )
        val year = core.query.readSlice(
            navigationScope(
                direction = LedgerDirection.expense,
                selection = FluviPeriodSelection.year("2026"),
            ),
        )
        val day = core.query.readSlice(
            navigationScope(
                direction = LedgerDirection.expense,
                selection = FluviPeriodSelection.day("2026-07-01"),
            ),
        )

        assertEquals("month:2026-07", month.timeScopeKey)
        assertEquals(
            "expense|month:2026-07|categories:|partners:|refinements:",
            month.queryKey,
        )
        assertEquals("year:2026", year.timeScopeKey)
        assertEquals(
            "expense|year:2026|categories:|partners:|refinements:",
            year.queryKey,
        )
        assertEquals("day:2026-07-01", day.timeScopeKey)
        assertEquals(
            "expense|day:2026-07-01|categories:|partners:|refinements:",
            day.queryKey,
        )
    }

    @Test
    fun committedNavigationAndQueryPeriodsHaveOneSharedPreparedIdentity() = runBlocking {
        core.demoSeed.seed()
        val queryPeriods = listOf(
            FluviPeriodGroup(
                key = "time",
                selections = setOf(FluviPeriodSelection.month("2026-07")),
            ),
        )
        val committedScope = navigationScope(
            direction = LedgerDirection.expense,
            selection = FluviPeriodSelection.month("2026-07"),
            queryPeriods = queryPeriods,
        )

        val slice = core.query.readSlice(committedScope, pageSize = 24)
        val prepared = core.query.preparedDashboardIndex(
            periodGroups = queryPeriods,
            categoryIds = emptySet(),
            partnerIds = emptySet(),
            refinements = FluviQueryRefinements(),
            previewPageSize = 24,
            yearWindow = FluviPreparedYearWindow(2026, 2026),
        )
        val preparedMonth = prepared.frames.single { frame ->
            frame.direction == LedgerDirection.expense &&
                frame.timeScopeKey == "month:2026-07"
        }

        assertEquals("month:2026-07", slice.timeScopeKey)
        assertEquals(
            "expense|month:2026-07|categories:|partners:|refinements:" +
                "|periods:time=month:2026-07",
            slice.queryKey,
        )
        assertEquals(preparedMonth.queryKey, slice.queryKey)
        assertEquals(24, slice.entries.size)
        assertNotNull(slice.nextCursor)
    }

    @Test
    fun navigationAndRestrictiveQueryPeriodsAreCombinedByAnd() = runBlocking {
        core.demoSeed.seed()
        val scope = navigationScope(
            direction = LedgerDirection.expense,
            selection = FluviPeriodSelection.month("2026-07"),
            queryPeriods = listOf(
                FluviPeriodGroup(
                    key = "time",
                    selections = setOf(FluviPeriodSelection.month("2026-06")),
                ),
            ),
        )

        val slice = core.query.readSlice(scope, pageSize = 24)

        assertEquals(0L, slice.entryCount)
        assertEquals("month:2026-07", slice.timeScopeKey)
        assertEquals(
            "expense|month:2026-07|categories:|partners:|refinements:" +
                "|periods:time=month:2026-06",
            slice.queryKey,
        )
    }

    @Test
    fun coreRevisionObserverDoesNotMaterializeAnExactDashboardSlice() = runBlocking {
        val before = core.query.currentCoreRevision()
        val observer = async {
            core.query.observeCoreRevision().first { it > before }
        }

        core.demoSeed.seed()

        assertTrue(observer.await() > before)
    }

    @Test
    fun directReadServiceUsesTheDemoDatabaseForJulyYearAndAllTimeScopes() = runBlocking {
        core.demoSeed.seed()

        val julyIncome = core.query.readSlice(monthScope(LedgerDirection.income, 7))
        val julyExpense = core.query.readSlice(monthScope(LedgerDirection.expense, 7))
        val yearIncome = core.query.readSlice(yearScope(LedgerDirection.income))
        val yearExpense = core.query.readSlice(yearScope(LedgerDirection.expense))
        val denseYearIncome = core.query.readSlice(yearScope(LedgerDirection.income, 2025))
        val denseYearExpense = core.query.readSlice(yearScope(LedgerDirection.expense, 2025))
        val allIncome = core.query.readSlice(FluviQueryScope(direction = LedgerDirection.income))
        val allExpense = core.query.readSlice(FluviQueryScope(direction = LedgerDirection.expense))

        assertEquals(70_700_000L, julyIncome.totalMinor)
        assertEquals(6, julyIncome.entryCount)
        assertEquals(68_900_000L, julyExpense.totalMinor)
        assertEquals(94, julyExpense.entryCount)
        assertEquals(493_800_000L, yearIncome.totalMinor)
        assertEquals(42, yearIncome.entryCount)
        assertEquals(492_500_000L, yearExpense.totalMinor)
        assertEquals(658, yearExpense.entryCount)
        assertEquals(1_804, denseYearIncome.entryCount)
        assertEquals(1_800, denseYearExpense.entryCount)
        assertEquals(1_846, allIncome.entryCount)
        assertEquals(2_458, allExpense.entryCount)
        assertEquals(783_300_000L, denseYearIncome.totalMinor)
        assertEquals(
            yearIncome.totalMinor + denseYearIncome.totalMinor,
            allIncome.totalMinor,
        )
        assertEquals(
            yearIncome.entryCount + denseYearIncome.entryCount,
            allIncome.entryCount,
        )
        assertEquals(
            yearExpense.entryCount + denseYearExpense.entryCount,
            allExpense.entryCount,
        )
    }

    private fun monthScope(direction: LedgerDirection, month: Int): FluviQueryScope =
        navigationScope(
            direction = direction,
            selection = FluviPeriodSelection.month(
                "2026-${month.toString().padStart(2, '0')}",
            ),
        )

    private fun navigationScope(
        direction: LedgerDirection,
        selection: FluviPeriodSelection,
        queryPeriods: List<FluviPeriodGroup> = emptyList(),
    ): FluviQueryScope = FluviQueryScope(
        direction = direction,
        periodGroups = queryPeriods + FluviPeriodGroup(
            key = "navigation",
            selections = setOf(selection),
        ),
    )

    private fun yearScope(
        direction: LedgerDirection,
        year: Int = 2026,
    ): FluviQueryScope =
        navigationScope(
            direction = direction,
            selection = FluviPeriodSelection(
                kind = QueryPeriodKind.year,
                value = year.toString(),
            ),
        )
}
