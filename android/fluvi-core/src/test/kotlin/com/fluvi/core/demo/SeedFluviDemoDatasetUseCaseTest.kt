package com.fluvi.core.demo

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.fluvi.core.FluviCore
import com.fluvi.core.FluviCoreFactory
import com.fluvi.core.model.CreateLedgerEntryCommand
import com.fluvi.core.model.LedgerCategorySelection
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.LedgerOriginKind
import com.fluvi.core.model.FluviFinancialLimitPeriod
import com.fluvi.core.query.FluviPreparedYearWindow
import com.fluvi.core.query.FluviPeriodGroup
import com.fluvi.core.query.FluviPeriodSelection
import com.fluvi.core.query.FluviQueryScope
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class SeedFluviDemoDatasetUseCaseTest {
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
    fun seedWritesRealRoomRowsThatTheExistingReadServiceAggregates() = runBlocking {
        val report = core.demoSeed.seed()

        assertFalse(report.alreadySeeded)
        assertEquals(10, report.createdCategoryCount)
        assertEquals(27, report.createdPartnerCount)
        assertEquals(4_304, report.createdEntryCount)
        assertEquals(11, core.categories.list().size)

        val income = core.query.total(yearScope(LedgerDirection.income))
        val expense = core.query.total(yearScope(LedgerDirection.expense))

        assertEquals(493_800_000L, income.amountScaled100)
        assertEquals(492_500_000L, expense.amountScaled100)
        assertEquals(42L, income.entryCount)
        assertEquals(658L, expense.entryCount)
        assertEquals(707_000L * 100L, core.query.total(monthScope(LedgerDirection.income, 7)).amountScaled100)
        assertEquals(689_000L * 100L, core.query.total(monthScope(LedgerDirection.expense, 7)).amountScaled100)
        val highDensityReports = report.monthlyReports.filter { it.year == 2025 }
        assertEquals(12, highDensityReports.size)
        highDensityReports.forEach { month ->
            assertTrue(month.entryCount in 280..320)
            assertTrue(month.incomeTotalScaled100 in 600_000L * 100..700_000L * 100)
            assertTrue(month.expenseTotalScaled100 in 600_000L * 100..700_000L * 100)
            assertTrue(
                kotlin.math.abs(month.incomeTotalScaled100 - month.expenseTotalScaled100) <=
                    50_000L * 100,
            )
        }
        assertEquals(7_833_000L * 100L, core.query.total(yearScope(LedgerDirection.income, 2025)).amountScaled100)
        assertEquals(7_832_000L * 100L, core.query.total(yearScope(LedgerDirection.expense, 2025)).amountScaled100)
    }

    @Test
    fun runningTheSameSeedAgainIsAnIdempotentNoOp() = runBlocking {
        val first = core.demoSeed.seed()
        val second = core.demoSeed.seed()

        assertFalse(first.alreadySeeded)
        assertTrue(second.alreadySeeded)
        assertEquals(0, second.createdCategoryCount)
        assertEquals(0, second.createdPartnerCount)
        assertEquals(0, second.createdEntryCount)
        assertEquals(
            4_304L,
            core.query.total(FluviQueryScope(direction = LedgerDirection.income)).entryCount +
                core.query.total(FluviQueryScope(direction = LedgerDirection.expense)).entryCount,
        )
    }

    @Test
    fun seedUsesTheRequestedDashboardPreparedYearWindowForEveryLimitTarget() = runBlocking {
        core.demoSeed.seed(financialLimitYearWindow = 2024..2024)

        val limits = core.financialLimits.list()
        // The visible target domain is aggregate plus ledger-represented
        // categories for its own direction: 2 Income + 8 Expense categories.
        // SUM + one YEAR + twelve MONTH cells remain deterministic.
        assertEquals(12 * 14, limits.size)
        assertTrue(limits.all { limit ->
            when (val period = limit.key.period) {
                FluviFinancialLimitPeriod.Sum -> true
                is FluviFinancialLimitPeriod.Year -> period.year == 2024
                is FluviFinancialLimitPeriod.Month -> period.year == 2024
            }
        })
        assertTrue(limits.all { it.amountScaled100 > 0L })
    }

    @Test
    fun seedProvidesUnderEqualAndOverExamplesForEveryDirectionAndPlane() = runBlocking {
        core.demoSeed.seed(financialLimitYearWindow = 2025..2026)
        // A freshly created core starts at revision 1; the seed transaction
        // intentionally advances it exactly once after the coherent fixture.
        val snapshot = core.budget.preparedLimitSnapshot(
            expectedRevision = 2L,
            yearWindow = FluviPreparedYearWindow(2025, 2026),
        )
        val sumSlices = listOf(0)
        val yearSlices = (1 until 1 + snapshot.yearCount).toList()
        val monthSlices = (1 + snapshot.yearCount until snapshot.periodSliceCount).toList()

        LedgerDirection.entries.forEach { direction ->
            val bank = snapshot.directionBank(direction)
            for (slices in listOf(sumSlices, yearSlices, monthSlices)) {
                val relations = mutableSetOf<Int>()
                slices.forEach { slice ->
                    for (handle in 0 until bank.targetCount) {
                        val offset = slice * bank.targetCount + handle
                        val actual = bank.actualScaled100[offset]
                        val limit = bank.limitScaled100[offset]
                        if (actual <= 0L) continue
                        relations += actual.compareTo(limit)
                    }
                }
                assertTrue("expected under-limit fixture", relations.any { it < 0 })
                assertTrue("expected exact-limit fixture", relations.any { it == 0 })
                assertTrue("expected over-limit fixture", relations.any { it > 0 })
            }
        }
    }

    @Test
    fun preparedBudgetSnapshotMatchesUnfilteredAggregateAndCategoryActuals() = runBlocking {
        core.demoSeed.seed(financialLimitYearWindow = 2025..2026)
        val snapshot = core.budget.preparedLimitSnapshot(
            expectedRevision = 2L,
            yearWindow = FluviPreparedYearWindow(2025, 2026),
        )
        val monthSlice = 1 + snapshot.yearCount + 12 + 6 // July 2026
        fun actual(direction: LedgerDirection, slice: Int, handle: Int): Long {
            val bank = snapshot.directionBank(direction)
            return bank.actualScaled100[slice * bank.targetCount + handle]
        }

        val aggregate = core.query.total(monthScope(LedgerDirection.expense, 7))
        assertEquals(aggregate.amountScaled100, actual(LedgerDirection.expense, monthSlice, 0))

        val expenseBank = snapshot.directionBank(LedgerDirection.expense)
        val categoryHandle = (1 until expenseBank.targetCount).first { handle ->
            actual(LedgerDirection.expense, monthSlice, handle) > 0L
        }
        val categoryId = expenseBank.orderedCategoryIds[categoryHandle - 1]
        val categoryTotal = core.query.total(
            FluviQueryScope(
                direction = LedgerDirection.expense,
                categoryIds = setOf(categoryId),
                periodGroups = listOf(
                    FluviPeriodGroup(
                        key = "time",
                        selections = setOf(FluviPeriodSelection.month("2026-07")),
                    ),
                ),
            ),
        )
        assertEquals(categoryTotal.amountScaled100, actual(LedgerDirection.expense, monthSlice, categoryHandle))
    }

    @Test
    fun preparedBudgetSnapshotKeepsIncomeAndExpenseCategoryDomainsDirectionLocal() = runBlocking {
        core.demoSeed.seed(financialLimitYearWindow = 2025..2026)
        val snapshot = core.budget.preparedLimitSnapshot(
            expectedRevision = 2L,
            yearWindow = FluviPreparedYearWindow(2025, 2026),
        )
        val categoryInventory = core.categories.list()
        val categoryById = categoryInventory.associateBy { it.id }
        val incomeNames = setOf("Fizetés", "Egyéb bevétel")
        val expenseNames = setOf(
            "Lakhatás",
            "Élelmiszer",
            "Közlekedés",
            "Rezsi",
            "Egészség",
            "Szórakozás",
            "Vásárlás",
            "Előfizetések",
        )
        // The Budget bank must retain the authoritative category-repository
        // order, not the demo generator declaration order.
        val incomeIds = categoryInventory.filter { it.name in incomeNames }.map { it.id }
        val expenseIds = categoryInventory.filter { it.name in expenseNames }.map { it.id }

        val income = snapshot.directionBank(LedgerDirection.income)
        val expense = snapshot.directionBank(LedgerDirection.expense)

        assertEquals(incomeIds, income.orderedCategoryIds)
        assertEquals(expenseIds, expense.orderedCategoryIds)
        assertEquals(3, income.targetCount)
        assertEquals(9, expense.targetCount)
        assertEquals(
            incomeNames,
            income.orderedCategoryIds.map { categoryById.getValue(it).name }.toSet(),
        )
        assertEquals(
            expenseNames,
            expense.orderedCategoryIds.map { categoryById.getValue(it).name }.toSet(),
        )
        assertTrue(income.orderedCategoryIds.intersect(expense.orderedCategoryIds.toSet()).isEmpty())
    }

    @Test
    fun forceResetKeepsUserOwnedRowsOutsideTheDeterministicManifest() = runBlocking {
        val userCategoryId = core.categories.create(
            name = "Saját kategória",
            colorId = "color_21",
            iconId = "icon_50",
        )
        val userPartnerId = core.partners.findOrCreate(
            name = "Saját partner",
            defaultCategoryId = userCategoryId,
        )
        core.ledger.create(
            CreateLedgerEntryCommand(
                partnerId = userPartnerId,
                categorySelection = LedgerCategorySelection.PartnerDefault,
                note = "Saját rekord",
                direction = LedgerDirection.expense,
                amountScaled100 = 12_345L,
                bookedLocalEpochDay = 20_655L,
                bookedLocalTimeMinutes = 720,
                occurredAtUtcMs = 1_782_900_000_000L,
                originKind = LedgerOriginKind.manual,
                notificationInboxId = null,
            ),
        )
        core.demoSeed.seed()

        core.demoSeed.seed(forceReset = true)

        assertTrue(core.categories.getById(userCategoryId) != null)
        assertEquals(
            659L,
            core.query.total(yearScope(LedgerDirection.expense)).entryCount,
        )
    }

    private fun yearScope(
        direction: LedgerDirection,
        year: Int = 2026,
    ): FluviQueryScope = FluviQueryScope(
        direction = direction,
        periodGroups = listOf(
            FluviPeriodGroup(
                key = "time",
                selections = setOf(FluviPeriodSelection.year(year.toString())),
            ),
        ),
    )

    private fun monthScope(direction: LedgerDirection, month: Int): FluviQueryScope = FluviQueryScope(
        direction = direction,
        periodGroups = listOf(
            FluviPeriodGroup(
                key = "time",
                selections = setOf(
                    FluviPeriodSelection.month("2026-${month.toString().padStart(2, '0')}"),
                ),
            ),
        ),
    )
}
