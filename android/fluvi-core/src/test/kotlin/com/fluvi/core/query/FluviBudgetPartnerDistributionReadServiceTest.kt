package com.fluvi.core.query

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.FluviDatabaseFactory
import com.fluvi.core.database.entity.FluviCategoryEntity
import com.fluvi.core.database.entity.FluviLedgerEntryEntity
import com.fluvi.core.database.entity.FluviPartnerEntity
import com.fluvi.core.database.entity.FluviRecurrenceOccurrenceEntity
import com.fluvi.core.database.entity.FluviRecurrenceRuleEntity
import com.fluvi.core.model.CategoryAssignmentMode
import com.fluvi.core.model.FluviClock
import com.fluvi.core.model.FluviFinancialLimitKey
import com.fluvi.core.model.FluviFinancialLimitPeriod
import com.fluvi.core.model.FluviFinancialLimitTarget
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.LedgerOriginKind
import com.fluvi.core.model.RecurrenceAmountPolicy
import com.fluvi.core.model.RecurrenceOccurrenceStatus
import com.fluvi.core.model.RecurrenceTriggerKind
import com.fluvi.core.repository.FluviCategoryRepository
import com.fluvi.core.repository.FluviCoreRevisionRepository
import com.fluvi.core.repository.FluviFinancialLimitRepository
import com.fluvi.core.repository.FluviPartnerRepository
import com.fluvi.core.usecase.FluviFinancialLimitUseCase
import java.time.LocalDate
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class FluviBudgetPartnerDistributionReadServiceTest {
    private lateinit var database: FluviDatabase
    private lateinit var budget: FluviBudgetReadService
    private lateinit var revisions: FluviCoreRevisionRepository

    @Before
    fun setUp() = runBlocking {
        val context = ApplicationProvider.getApplicationContext<Context>()
        database = FluviDatabaseFactory.createInMemory(context, FluviClock { NOW })
        for (category in listOf(
            category(FOOD, "Food"),
            category(HOUSING, "Housing"),
            category(SALARY, "Salary"),
        )) {
            database.categoryDao().insert(category)
        }
        for (partner in listOf(
            partner(SHOP, "Bolt", FOOD, override = "Bolt partner"),
            partner(RENT, "Rent", HOUSING),
            partner(EMPLOYER, "Employer", SALARY),
        )) {
            database.partnerDao().insert(partner)
        }
        database.ledgerDao().insertAll(
            listOf(
                entry(1, LedgerDirection.expense, SHOP, FOOD, LocalDate.of(2026, 1, 10), 300),
                entry(2, LedgerDirection.expense, SHOP, HOUSING, LocalDate.of(2026, 1, 11), 300),
                entry(3, LedgerDirection.expense, RENT, HOUSING, LocalDate.of(2026, 2, 1), 500),
                entry(4, LedgerDirection.income, EMPLOYER, SALARY, LocalDate.of(2026, 1, 5), 1_000),
            ),
        )
        revisions = FluviCoreRevisionRepository(database)
        revisions.advance(NOW)
        budget = FluviBudgetReadService(
            database = database,
            categories = FluviCategoryRepository(database),
            financialLimits = FluviFinancialLimitRepository(database),
            partners = FluviPartnerRepository(database),
        )
    }

    @After
    fun tearDown() = database.close()

    @Test
    fun preparesBothDirectionsAndEveryPeriodWithOneBoundedGroupedScan() = runBlocking {
        val snapshot = budget.preparedPartnerDistributionSnapshot(
            expectedRevision = revisions.current(),
            yearWindow = FluviPreparedYearWindow(2026, 2026),
        )

        // Revision + partners + canonical categories + one grouped ledger
        // scan + final revision: bounded independently of partner/category/
        // period counts.
        assertEquals(5, snapshot.sqlCallCount)
        assertEquals(listOf(EMPLOYER), snapshot.incomeBank.orderedPartnerIds)
        assertEquals(listOf(SHOP, RENT), snapshot.expenseBank.orderedPartnerIds)
        assertEquals(listOf(FOOD, HOUSING), snapshot.expenseBank.orderedCategoryIds)
        assertEquals("Bolt partner", snapshot.expenseBank.orderedPartnerTitles[0])
        val januarySlice = 2
        val shopJanuary = snapshot.expenseBank.cells[januarySlice * 2]
        assertEquals(600L, shopJanuary.actualScaled100)
        assertEquals(2L, shopJanuary.transactionCount)
        assertEquals(
            "equal category contribution resolves by stable category ID",
            FOOD,
            shopJanuary.dominantCategoryId,
        )
        assertEquals(
            "SUM remains independent of a current Query/month selection",
            1_100L,
            snapshot.expenseBank.cells[1].actualScaled100 +
                snapshot.expenseBank.cells[0].actualScaled100,
        )
        val yearSlice = 1
        assertEquals(600L, snapshot.expenseBank.cells[yearSlice * 2].actualScaled100)
        assertEquals(500L, snapshot.expenseBank.cells[yearSlice * 2 + 1].actualScaled100)
        val foodJanuary = snapshot.expenseBank.contributionsFor(
            periodSliceIndex = januarySlice,
            targetHandle = 1,
        )
        val housingJanuary = snapshot.expenseBank.contributionsFor(
            periodSliceIndex = januarySlice,
            targetHandle = 2,
        )
        assertEquals(listOf(0), foodJanuary.map { it.partnerHandle })
        assertEquals(listOf(300L), foodJanuary.map { it.actualScaled100 })
        assertEquals(listOf(1L), foodJanuary.map { it.transactionCount })
        assertEquals(listOf(0), housingJanuary.map { it.partnerHandle })
        assertEquals(listOf(300L), housingJanuary.map { it.actualScaled100 })
        assertEquals(listOf(1L), housingJanuary.map { it.transactionCount })
        val january10 = LocalDate.of(2026, 1, 10).toEpochDay()
        val january11 = LocalDate.of(2026, 1, 11).toEpochDay()
        assertEquals(listOf(january10, january11, LocalDate.of(2026, 2, 1).toEpochDay()),
            snapshot.expenseBank.dayEpochDays.toList())
        assertEquals(listOf(0), snapshot.expenseBank.dayAggregateFor(january10).map { it.partnerHandle })
        assertEquals(listOf(1L), snapshot.expenseBank.dayAggregateFor(january10).map { it.transactionCount })
        assertEquals(FOOD, snapshot.expenseBank.dayAggregateFor(january10).single().dominantCategoryId)
        assertEquals(listOf(0), snapshot.expenseBank.dayContributionsFor(january11, 2).map { it.partnerHandle })
        assertEquals(emptyList<Int>(), snapshot.expenseBank.dayContributionsFor(january11, 1).map { it.partnerHandle })
    }

    @Test
    fun preparesLimitCountsBesideAmountsWithoutAnotherLedgerAcquisition() = runBlocking {
        val snapshot = budget.preparedLimitSnapshot(
            expectedRevision = revisions.current(),
            yearWindow = FluviPreparedYearWindow(2026, 2026),
        )

        // revision + categories + the one grouped ledger scan + limits + final
        // revision. COUNT(*) is part of the existing acquisition, not a second
        // Budget request.
        assertEquals(5, snapshot.sqlCallCount)
        val expense = snapshot.expenseBank
        assertEquals(listOf(FOOD, HOUSING), expense.orderedCategoryIds)
        val targetCount = expense.targetCount
        val januarySlice = 2
        assertEquals(
            "Aggregate January count represents both exact ledger transactions.",
            2L,
            expense.transactionCount[januarySlice * targetCount],
        )
        assertEquals(
            "Food January count remains target-local.",
            1L,
            expense.transactionCount[januarySlice * targetCount + 1],
        )
        assertEquals(
            "Housing January count remains target-local.",
            1L,
            expense.transactionCount[januarySlice * targetCount + 2],
        )

        val january10 = LocalDate.of(2026, 1, 10).toEpochDay()
        val rhythm = snapshot.spendingRhythmSnapshot.expenseBank
        val aggregatePoints = rhythm.points.subList(
            rhythm.targetOffsets[0],
            rhythm.targetOffsets[1],
        )
        assertEquals(
            "DAY count remains an exact transaction count, not an active-day count.",
            1L,
            aggregatePoints.single { it.epochDay == january10 }.transactionCount,
        )
    }

    @Test
    fun preparesFinancialBudgetBanksForTheExactBookedGhostMembership() = runBlocking {
        database.recurrenceDao().insertRule(
            recurrenceRule(
                id = "realized-rule",
                partnerId = SHOP,
                categoryId = FOOD,
            ),
        )
        database.recurrenceDao().insertOccurrence(
            realizedOccurrence(
                id = "realized-occurrence",
                ruleId = "realized-rule",
                partnerId = SHOP,
                categoryId = FOOD,
                date = LocalDate.of(2026, 1, 12),
                amount = 700,
            ),
        )
        database.ledgerDao().insert(
            entry(
                ordinal = 5,
                direction = LedgerDirection.expense,
                partnerId = SHOP,
                categoryId = FOOD,
                date = LocalDate.of(2026, 1, 12),
                amount = 700,
                recurrenceOccurrenceId = "realized-occurrence",
            ),
        )
        revisions.advance(NOW + 1L)
        val revision = revisions.current()

        val nonGhost = budget.preparedLimitSnapshot(
            expectedRevision = revision,
            yearWindow = FluviPreparedYearWindow(2026, 2026),
            ghostFilterMode = FluviGhostFilterMode.nonGhost,
        )
        val onlyGhost = budget.preparedLimitSnapshot(
            expectedRevision = revision,
            yearWindow = FluviPreparedYearWindow(2026, 2026),
            ghostFilterMode = FluviGhostFilterMode.onlyGhost,
        )
        val both = budget.preparedLimitSnapshot(
            expectedRevision = revision,
            yearWindow = FluviPreparedYearWindow(2026, 2026),
            ghostFilterMode = FluviGhostFilterMode.both,
        )
        val januarySlice = 2

        fun aggregateActual(snapshot: FluviPreparedBudgetLimitSnapshot): Long =
            snapshot.expenseBank.actualScaled100[
                januarySlice * snapshot.expenseBank.targetCount
            ]

        assertEquals(FluviGhostFilterMode.nonGhost, nonGhost.ghostFilterMode)
        assertEquals(FluviGhostFilterMode.onlyGhost, onlyGhost.ghostFilterMode)
        assertEquals(FluviGhostFilterMode.both, both.ghostFilterMode)
        assertEquals(600L, aggregateActual(nonGhost))
        assertEquals(700L, aggregateActual(onlyGhost))
        assertEquals(1_300L, aggregateActual(both))

        val onlyGhostPartners = budget.preparedPartnerDistributionSnapshot(
            expectedRevision = revision,
            yearWindow = FluviPreparedYearWindow(2026, 2026),
            ghostFilterMode = FluviGhostFilterMode.onlyGhost,
        )
        assertEquals(FluviGhostFilterMode.onlyGhost, onlyGhostPartners.ghostFilterMode)
        assertEquals(700L, onlyGhostPartners.expenseBank.cells[
            januarySlice * onlyGhostPartners.expenseBank.orderedPartnerIds.size
        ].actualScaled100)
    }

    @Test
    fun resolvesEffectiveDatedBaseHistoryBeforeConcreteMonthOverrides() = runBlocking {
        val limits = FluviFinancialLimitUseCase(database, FluviClock { NOW })
        fun key(period: FluviFinancialLimitPeriod) = FluviFinancialLimitKey(
            direction = LedgerDirection.expense,
            target = FluviFinancialLimitTarget.Aggregate,
            period = period,
        )
        limits.upsert(key(FluviFinancialLimitPeriod.BaseMonthlyRevision(2026, 1)), 18_000L)
        limits.upsert(key(FluviFinancialLimitPeriod.BaseMonthlyRevision(2026, 10)), 20_000L)
        limits.upsert(key(FluviFinancialLimitPeriod.MonthOverride(2026, 3)), 22_000L)
        limits.upsert(key(FluviFinancialLimitPeriod.MonthOverride(2026, 12)), 25_000L)

        val snapshot = budget.preparedLimitSnapshot(
            expectedRevision = revisions.current(),
            yearWindow = FluviPreparedYearWindow(2026, 2026),
        )
        val targetCount = snapshot.expenseBank.targetCount
        fun resolved(month: Int): Long = snapshot.expenseBank.limitScaled100[
            (1 + snapshot.yearCount + month - 1) * targetCount
        ]
        assertEquals(18_000L, resolved(2))
        assertEquals(22_000L, resolved(3))
        assertEquals(18_000L, resolved(9))
        assertEquals(20_000L, resolved(10))
        assertEquals(25_000L, resolved(12))
    }

    private fun category(id: String, name: String) = FluviCategoryEntity(
        id = id,
        name = name,
        colorId = "color_02",
        iconId = "icon_02",
        isSystemUncategorized = false,
        createdAtUtcMs = NOW,
        updatedAtUtcMs = NOW,
    )

    private fun partner(
        id: String,
        name: String,
        categoryId: String,
        override: String? = null,
    ) = FluviPartnerEntity(
        id = id,
        originalName = name,
        displayNameOverride = override,
        defaultCategoryId = categoryId,
        mergedIntoPartnerId = null,
        createdAtUtcMs = NOW,
        updatedAtUtcMs = NOW,
    )

    private fun recurrenceRule(
        id: String,
        partnerId: String,
        categoryId: String,
    ) = FluviRecurrenceRuleEntity(
        id = id,
        name = "Test recurrence",
        triggerKind = RecurrenceTriggerKind.time,
        partnerId = partnerId,
        categoryId = categoryId,
        categoryAssignmentMode = CategoryAssignmentMode.partnerDefault,
        note = null,
        direction = LedgerDirection.expense,
        amountPolicy = RecurrenceAmountPolicy.fixed,
        amountScaled100 = 700,
        dayOfMonth = 12,
        localTimeMinutes = 600,
        startLocalEpochDay = LocalDate.of(2026, 1, 1).toEpochDay(),
        endLocalEpochDay = null,
        timezoneId = "Europe/Budapest",
        ruleVersion = 1,
        archivedAtUtcMs = null,
        isActive = true,
        createdAtUtcMs = NOW,
        updatedAtUtcMs = NOW,
    )

    private fun realizedOccurrence(
        id: String,
        ruleId: String,
        partnerId: String,
        categoryId: String,
        date: LocalDate,
        amount: Long,
    ) = FluviRecurrenceOccurrenceEntity(
        id = id,
        ruleId = ruleId,
        occurrenceKey = "${date.year}-${date.monthValue}",
        ruleVersion = 1,
        expectedLocalEpochDay = date.toEpochDay(),
        expectedLocalTimeMinutes = 600,
        expectedAtUtcMs = NOW,
        timezoneId = "Europe/Budapest",
        partnerId = partnerId,
        categoryId = categoryId,
        categoryAssignmentMode = CategoryAssignmentMode.partnerDefault,
        direction = LedgerDirection.expense,
        expectedAmountScaled100 = amount,
        amountPolicy = RecurrenceAmountPolicy.fixed,
        note = null,
        triggerKind = RecurrenceTriggerKind.time,
        status = RecurrenceOccurrenceStatus.realized,
        realizationKind = null,
        resolvedAtUtcMs = NOW,
        createdAtUtcMs = NOW,
        updatedAtUtcMs = NOW,
        revision = 1L,
    )

    private fun entry(
        ordinal: Int,
        direction: LedgerDirection,
        partnerId: String,
        categoryId: String,
        date: LocalDate,
        amount: Long,
        recurrenceOccurrenceId: String? = null,
    ) = FluviLedgerEntryEntity(
        id = ordinal.toString().padStart(26, '0'),
        partnerId = partnerId,
        categoryId = categoryId,
        categoryAssignmentMode = CategoryAssignmentMode.partnerDefault,
        note = null,
        direction = direction,
        amountScaled100 = amount,
        bookedLocalEpochDay = date.toEpochDay(),
        bookedLocalTimeMinutes = 600 + ordinal,
        occurredAtUtcMs = NOW + ordinal,
        originKind = LedgerOriginKind.manual,
        notificationInboxId = null,
        recurrenceOccurrenceId = recurrenceOccurrenceId,
        createdAtUtcMs = NOW,
        updatedAtUtcMs = NOW,
        revision = 1L,
    )

    private companion object {
        const val NOW = 1_700_000_000_000L
        const val FOOD = "00000000000000000000000010"
        const val HOUSING = "00000000000000000000000011"
        const val SALARY = "00000000000000000000000012"
        const val SHOP = "00000000000000000000000020"
        const val RENT = "00000000000000000000000021"
        const val EMPLOYER = "00000000000000000000000022"
    }
}
