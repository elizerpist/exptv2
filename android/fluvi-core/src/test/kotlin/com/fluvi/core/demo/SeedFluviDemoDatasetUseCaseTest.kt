package com.fluvi.core.demo

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.fluvi.core.FluviCore
import com.fluvi.core.FluviCoreFactory
import com.fluvi.core.model.CreateLedgerEntryCommand
import com.fluvi.core.model.LedgerCategorySelection
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.LedgerOriginKind
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
