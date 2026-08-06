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
        val allIncome = core.query.readSlice(FluviQueryScope(direction = LedgerDirection.income))

        assertEquals(70_700_000L, julyIncome.totalMinor)
        assertEquals(6, julyIncome.entryCount)
        assertEquals(68_900_000L, julyExpense.totalMinor)
        assertEquals(94, julyExpense.entryCount)
        assertEquals(493_800_000L, yearIncome.totalMinor)
        assertEquals(42, yearIncome.entryCount)
        assertEquals(492_500_000L, yearExpense.totalMinor)
        assertEquals(658, yearExpense.entryCount)
        assertEquals(yearIncome.totalMinor, allIncome.totalMinor)
        assertEquals(yearIncome.entryCount, allIncome.entryCount)
    }

    private fun monthScope(direction: LedgerDirection, month: Int): FluviQueryScope =
        FluviQueryScope(
            direction = direction,
            periodGroups = listOf(
                FluviPeriodGroup(
                    key = "time",
                    selections = setOf(
                        FluviPeriodSelection.month(
                            "2026-${month.toString().padStart(2, '0')}",
                        ),
                    ),
                ),
            ),
        )

    private fun yearScope(direction: LedgerDirection): FluviQueryScope =
        FluviQueryScope(
            direction = direction,
            periodGroups = listOf(
                FluviPeriodGroup(
                    key = "time",
                    selections = setOf(
                        FluviPeriodSelection(
                            kind = QueryPeriodKind.year,
                            value = "2026",
                        ),
                    ),
                ),
            ),
        )
}
