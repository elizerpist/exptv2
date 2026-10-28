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
import com.fluvi.core.query.FluviGhostFilterMode
import com.fluvi.core.query.FluviPeriodGroup
import com.fluvi.core.query.FluviPeriodSelection
import com.fluvi.core.query.FluviQueryRefinements
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
import java.time.LocalDate
import java.time.ZoneId

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
        assertEquals(11, report.createdCategoryCount)
        assertEquals(33, report.createdPartnerCount)
        assertEquals(5_519, report.createdEntryCount)
        assertEquals(14, core.categories.list().size)

        val income = core.query.total(yearScope(LedgerDirection.income))
        val expense = core.query.total(yearScope(LedgerDirection.expense))

        assertEquals(523_800_000L, income.amountScaled100)
        assertEquals(581_085_800L, expense.amountScaled100)
        assertEquals(54L, income.entryCount)
        assertEquals(1_785L, expense.entryCount)
        assertEquals(732_000L * 100L, core.query.total(monthScope(LedgerDirection.income, 7)).amountScaled100)
        assertEquals(698_800L * 100L, core.query.total(monthScope(LedgerDirection.expense, 7)).amountScaled100)
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
        assertEquals(96, first.createdGhostOccurrenceCount)
        assertEquals(48, first.createdGhostLedgerEntryCount)
        assertEquals(96, first.ghostOccurrenceCount)
        assertEquals(48, first.ghostPendingOccurrenceCount)
        assertEquals(48, first.ghostRealizedOccurrenceCount)
        assertEquals(48, first.ghostLedgerEntryCount)
        assertEquals(0, second.createdGhostOccurrenceCount)
        assertEquals(0, second.createdGhostLedgerEntryCount)
        assertEquals(96, second.ghostOccurrenceCount)
        assertEquals(48, second.ghostLedgerEntryCount)
        assertEquals(
            5_567L,
            core.query.total(FluviQueryScope(direction = LedgerDirection.income)).entryCount +
                core.query.total(FluviQueryScope(direction = LedgerDirection.expense)).entryCount,
        )
    }

    @Test
    fun ghostFixtureWritesEvery2026And2027MonthThroughTheNormalOccurrenceAndLedgerPaths() = runBlocking {
        core.demoSeed.seed()

        val occurrences = core.recurrences.occurrences(limit = 200)
            .filter { it.note?.startsWith("Demo ") == true }
        assertEquals(96, occurrences.size)
        assertEquals(48, occurrences.count { it.status == com.fluvi.core.model.RecurrenceOccurrenceStatus.pending })
        assertEquals(48, occurrences.count { it.status == com.fluvi.core.model.RecurrenceOccurrenceStatus.realized })
        assertEquals(
            (2026..2027).flatMap { year -> (1..12).map { month -> year to month } }.toSet(),
            occurrences.map { occurrence ->
                val date = LocalDate.ofEpochDay(occurrence.expectedLocalEpochDay)
                date.year to date.monthValue
            }.toSet(),
        )
        occurrences.groupBy { LocalDate.ofEpochDay(it.expectedLocalEpochDay) }.forEach { (day, monthly) ->
            assertEquals(28, day.dayOfMonth)
            assertEquals(4, monthly.size)
            assertEquals(2, monthly.count { it.status == com.fluvi.core.model.RecurrenceOccurrenceStatus.pending })
            assertEquals(2, monthly.count { it.status == com.fluvi.core.model.RecurrenceOccurrenceStatus.realized })
        }
        occurrences.forEach { occurrence ->
            val date = LocalDate.ofEpochDay(occurrence.expectedLocalEpochDay)
            assertEquals(
                date.atTime(
                    occurrence.expectedLocalTimeMinutes / 60,
                    occurrence.expectedLocalTimeMinutes % 60,
                ).atZone(ZoneId.of("Europe/Budapest")).toInstant().toEpochMilli(),
                occurrence.expectedAtUtcMs,
            )
        }
        occurrences.groupBy { occurrence ->
            occurrence.direction to occurrence.status
        }.forEach { (group, examples) ->
            val (direction, status) = group
            val (amount, minute) = when (direction to status) {
                LedgerDirection.income to com.fluvi.core.model.RecurrenceOccurrenceStatus.pending ->
                    10_000L * 100L to 8 * 60
                LedgerDirection.income to com.fluvi.core.model.RecurrenceOccurrenceStatus.realized ->
                    25_000L * 100L to 10 * 60
                LedgerDirection.expense to com.fluvi.core.model.RecurrenceOccurrenceStatus.pending ->
                    4_500L * 100L to 12 * 60
                LedgerDirection.expense to com.fluvi.core.model.RecurrenceOccurrenceStatus.realized ->
                    9_800L * 100L to 18 * 60
                else -> error("Unexpected ghost fixture group: $direction / $status")
            }
            assertEquals(24, examples.size)
            assertTrue(examples.all { it.expectedAmountScaled100 == amount })
            assertTrue(examples.all { it.expectedLocalTimeMinutes == minute })
        }

        val realized = occurrences.filter {
            it.status == com.fluvi.core.model.RecurrenceOccurrenceStatus.realized
        }
        assertEquals(48, realized.map { core.recurrences.realizedLedgerEntryId(it.occurrenceId) }.distinct().size)
        assertTrue(realized.all { core.recurrences.realizedLedgerEntryId(it.occurrenceId) != null })

        // All fixture rules are unbound push recurrences, so a scheduler pass
        // cannot turn the past pending examples into booked Ledger rows.
        assertTrue(core.recurrences.realizeDueTimeOccurrences(Long.MAX_VALUE).isEmpty())
        assertEquals(
            48,
            core.recurrences.occurrences(limit = 200)
                .count { it.note?.startsWith("Demo ") == true && it.status == com.fluvi.core.model.RecurrenceOccurrenceStatus.pending },
        )

        assertMonthlyGhostPresentation(
            direction = LedgerDirection.income,
            realizedAmountScaled100 = 25_000L * 100L,
        )
        assertMonthlyGhostPresentation(
            direction = LedgerDirection.expense,
            realizedAmountScaled100 = 9_800L * 100L,
        )

        // This is the same retained preview lane consumed by the LogBox
        // renderer. Pending and realized rows must share its chronological
        // ordering; grouping pending rows ahead of booked rows makes Dart's
        // prepared projection correctly reject the frame.
        val prepared = core.query.preparedDashboardIndex(
            periodGroups = listOf(
                FluviPeriodGroup(
                    key = "time",
                    selections = setOf(FluviPeriodSelection.month("2026-07")),
                ),
            ),
            categoryIds = emptySet(),
            partnerIds = emptySet(),
            refinements = FluviQueryRefinements(),
            previewPageSize = 200,
            yearWindow = FluviPreparedYearWindow(2026, 2027),
        )
        LedgerDirection.entries.forEach { direction ->
            val frame = prepared.frames.single {
                it.direction == direction && it.timeScopeKey == "month:2026-07"
            }
            val rows = frame.rowIndices.map(prepared.rows::get)
            assertEquals(2, rows.count { it.recurrenceOccurrenceId != null })
            assertChronologicalRendererOrder(rows)
        }
    }

    @Test
    fun seedExposesTheExact2027FastfoodMirrorThroughNormalCategoryPartnerAndRangeQueries() = runBlocking {
        core.demoSeed.seed()

        val category = core.categories.list().single { it.name == "Gyorsétterem" }
        val categoryScope = FluviQueryScope(
            direction = LedgerDirection.expense,
            categoryIds = setOf(category.id),
            periodGroups = listOf(
                FluviPeriodGroup(
                    key = "time",
                    selections = setOf(FluviPeriodSelection.year("2027")),
                ),
            ),
        )
        val categoryTotal = core.query.total(categoryScope)
        assertEquals(100L, categoryTotal.entryCount)
        assertEquals(645_560L * 100L, categoryTotal.amountScaled100)

        val subway = core.query.queryMenuFacets(categoryScope).partners
            .single { it.displayName == "Subway" }
        val partnerTotal = core.query.total(categoryScope.copy(partnerIds = setOf(subway.id)))
        assertEquals(23L, partnerTotal.entryCount)
        assertEquals(136_970L * 100L, partnerTotal.amountScaled100)

        val highAmountTotal = core.query.total(
            categoryScope.copy(
                refinements = FluviQueryRefinements(
                    minimumAmountScaled100 = 10_000L * 100L,
                    maximumAmountScaled100 = 13_500L * 100L,
                ),
            ),
        )
        assertEquals(18L, highAmountTotal.entryCount)
        assertEquals(213_150L * 100L, highAmountTotal.amountScaled100)
    }

    @Test
    fun sumExpensePagingKeepsOneAllTimeIdentityWhileItsNewestHundredRowsAreThe2027FastfoodMirror() = runBlocking {
        core.demoSeed.seed()

        val fastfoodCategory = core.categories.list().single { it.name == "Gyorsétterem" }
        val sumScope = FluviQueryScope(
            direction = LedgerDirection.expense,
            categoryIds = setOf(fastfoodCategory.id),
        )
        val total = core.query.total(sumScope)
        assertTrue(total.entryCount > 100L)
        val revision = core.query.currentCoreRevision()
        var cursor = null as com.fluvi.core.query.FluviTimelineCursor?
        var firstQueryKey: String? = null
        val newestHundred = mutableListOf<com.fluvi.core.query.FluviDashboardLedgerRow>()
        var sawOlderYear = false

        // This follows the same keyset cursor used by Flutter's committed
        // LogBox pages. Four full 24-row pages plus the next page exhaust the
        // demo's 100 newest 2027 records; the latter page must then enter the
        // normal older all-time ledger rather than remain Year-scoped.
        while (newestHundred.size < 100 || !sawOlderYear) {
            val page = core.query.readCommittedPage(
                scope = sumScope,
                pageSize = 24,
                after = cursor,
                expectedRevision = revision,
                authoritativeTotalMinor = total.amountScaled100,
                authoritativeEntryCount = total.entryCount,
            ).slice
            firstQueryKey = firstQueryKey ?: page.queryKey
            assertEquals(firstQueryKey, page.queryKey)
            assertEquals(total.entryCount, page.entryCount)
            assertEquals(total.amountScaled100, page.totalMinor)

            page.entries.forEach { entry ->
                val year = LocalDate.ofEpochDay(entry.bookedLocalEpochDay).year
                if (year == 2027 && newestHundred.size < 100) {
                    newestHundred += entry
                }
                if (year < 2027) sawOlderYear = true
            }
            cursor = page.nextCursor
            assertTrue(
                "All-time paging must continue after the newest 2027 mirror.",
                cursor != null || sawOlderYear,
            )
        }

        assertEquals(100, newestHundred.size)
        assertTrue(newestHundred.all { entry ->
            LocalDate.ofEpochDay(entry.bookedLocalEpochDay).year == 2027 &&
                entry.categoryDisplayName == "Gyorsétterem"
        })
        assertTrue(sawOlderYear)
    }

    @Test
    fun seedUsesTheRequestedDashboardPreparedYearWindowForEveryLimitTarget() = runBlocking {
        core.demoSeed.seed(financialLimitYearWindow = 2024..2024)

        val limits = core.financialLimits.list()
        // The visible target domain is aggregate plus ledger-represented
        // categories for its own direction: 2 Income + 8 Expense categories.
        // One base plus four sparse explicit month overrides per target keeps
        // inheritance exercised without recreating annual/SUM rows.
        val baseCount = limits.count {
            it.key.period is FluviFinancialLimitPeriod.BaseMonthlyRevision
        }
        assertEquals(baseCount * 5, limits.size)
        assertTrue(limits.all { limit ->
            when (val period = limit.key.period) {
                is FluviFinancialLimitPeriod.BaseMonthlyRevision -> true
                is FluviFinancialLimitPeriod.MonthOverride -> period.year == 2024
            }
        })
        assertTrue(limits.all { it.amountScaled100 > 0L })
    }

    @Test
    fun seedProvidesUnderEqualAndOverMonthExamplesForEveryDirection() = runBlocking {
        core.demoSeed.seed(financialLimitYearWindow = 2025..2026)
        // A freshly created core starts at revision 1; the seed transaction
        // intentionally advances it exactly once after the coherent fixture.
        val snapshot = core.budget.preparedLimitSnapshot(
            expectedRevision = 2L,
            yearWindow = FluviPreparedYearWindow(2025, 2026),
        )
        val monthSlices = (1 + snapshot.yearCount until snapshot.periodSliceCount).toList()

        LedgerDirection.entries.forEach { direction ->
            val bank = snapshot.directionBank(direction)
            // This fixture deliberately supplies each monthly health band.
            // YEAR is a sum of independently resolved months, so an exact
            // annual ratio is neither required nor generally possible from
            // sparse overrides. Slice zero retains raw all-time data; SUM
            // derives its typical-month analysis from that data instead of
            // treating it as an independently persisted limit.
            for (slices in listOf(monthSlices)) {
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
    fun preparedBudgetSnapshotRetainsSparseDayPartRhythmsFromTheSameAcquisition() = runBlocking {
        core.demoSeed.seed(financialLimitYearWindow = 2025..2026)
        val snapshot = core.budget.preparedLimitSnapshot(
            expectedRevision = 2L,
            yearWindow = FluviPreparedYearWindow(2025, 2026),
        )
        val rhythm = snapshot.spendingRhythmSnapshot
        assertEquals(snapshot.coreRevision, rhythm.coreRevision)
        LedgerDirection.entries.forEach { direction ->
            val dense = snapshot.directionBank(direction)
            val sparse = rhythm.directionBank(direction)
            assertEquals(dense.targetCount, sparse.targetCount)
            assertEquals(0, sparse.targetOffsets.first())
            assertEquals(sparse.points.size, sparse.targetOffsets.last())
            val aggregateSum = sparse.points
                .subList(sparse.targetOffsets[0], sparse.targetOffsets[1])
                .sumOf { it.actualScaled100 }
            assertEquals(dense.actualScaled100[0], aggregateSum)
            assertTrue(sparse.points.all { it.actualScaled100 > 0L })
            assertTrue(sparse.points.all { point ->
                point.dayPartActualScaled100.sum() == point.actualScaled100
            })
        }
        // The rhythm is folded while the existing grouped native row set is
        // present; it does not introduce a per-bar/category SQL shape.
        assertEquals(5, snapshot.sqlCallCount)
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
        val incomeNames = setOf(
            "Fizetés",
            "Egyéb bevétel",
            "Demo ghost bevétel",
        )
        val expenseNames = setOf(
            "Lakhatás",
            "Élelmiszer",
            "Közlekedés",
            "Rezsi",
            "Egészség",
            "Szórakozás",
            "Vásárlás",
            "Előfizetések",
            "Gyorsétterem",
            "Demo ghost kiadás",
        )
        // The Budget bank must retain the authoritative category-repository
        // order, not the demo generator declaration order.
        val incomeIds = categoryInventory.filter { it.name in incomeNames }.map { it.id }
        val expenseIds = categoryInventory.filter { it.name in expenseNames }.map { it.id }

        val income = snapshot.directionBank(LedgerDirection.income)
        val expense = snapshot.directionBank(LedgerDirection.expense)

        assertEquals(incomeIds, income.orderedCategoryIds)
        assertEquals(expenseIds, expense.orderedCategoryIds)
        assertEquals(4, income.targetCount)
        assertEquals(11, expense.targetCount)
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
            1_786L,
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

    private suspend fun assertMonthlyGhostPresentation(
        direction: LedgerDirection,
        realizedAmountScaled100: Long,
    ) {
        val base = FluviQueryScope(
            direction = direction,
            periodGroups = listOf(
                FluviPeriodGroup(
                    key = "time",
                    selections = setOf(FluviPeriodSelection.day("2026-07-28")),
                ),
            ),
        )
        val onlyGhost = core.query.readSlice(
            base.copy(ghostFilterMode = FluviGhostFilterMode.onlyGhost),
        )
        val nonGhost = core.query.readSlice(
            base.copy(ghostFilterMode = FluviGhostFilterMode.nonGhost),
        )
        val both = core.query.readSlice(base)

        assertEquals(2L, onlyGhost.presentationEntryCount)
        assertEquals(1L, onlyGhost.entryCount)
        assertEquals(realizedAmountScaled100, onlyGhost.totalMinor)
        assertEquals(1, onlyGhost.entries.count { it.isPendingGhost })
        assertEquals(1, onlyGhost.entries.count { !it.isPendingGhost && it.recurrenceOccurrenceId != null })
        assertChronologicalRendererOrder(onlyGhost.entries)

        val onlyGhostScope = base.copy(ghostFilterMode = FluviGhostFilterMode.onlyGhost)
        val revision = core.query.currentCoreRevision()
        val firstCommitted = core.query.readCommittedPage(
            scope = onlyGhostScope,
            pageSize = 1,
            after = null,
            expectedRevision = revision,
            authoritativeTotalMinor = onlyGhost.totalMinor,
            authoritativeEntryCount = onlyGhost.entryCount,
            authoritativePresentationEntryCount = onlyGhost.presentationEntryCount,
        ).slice
        val secondCommitted = core.query.readCommittedPage(
            scope = onlyGhostScope,
            pageSize = 1,
            after = requireNotNull(firstCommitted.nextCursor),
            expectedRevision = revision,
            authoritativeTotalMinor = onlyGhost.totalMinor,
            authoritativeEntryCount = onlyGhost.entryCount,
            authoritativePresentationEntryCount = onlyGhost.presentationEntryCount,
        ).slice
        assertChronologicalRendererOrder(firstCommitted.entries + secondCommitted.entries)
        assertEquals(2, (firstCommitted.entries + secondCommitted.entries).map { it.entryId }.distinct().size)

        assertTrue(nonGhost.entries.none { it.note?.startsWith("Demo ") == true })
        assertEquals(nonGhost.presentationEntryCount + 2L, both.presentationEntryCount)
        assertEquals(nonGhost.entryCount + 1L, both.entryCount)
        assertEquals(nonGhost.totalMinor + realizedAmountScaled100, both.totalMinor)
    }

    private fun assertChronologicalRendererOrder(
        rows: List<com.fluvi.core.query.FluviDashboardLedgerRow>,
    ) {
        assertTrue(
            rows.zipWithNext().all { (left, right) ->
                left.bookedLocalEpochDay > right.bookedLocalEpochDay ||
                    (left.bookedLocalEpochDay == right.bookedLocalEpochDay &&
                        (left.bookedLocalTimeMinutes > right.bookedLocalTimeMinutes ||
                            (left.bookedLocalTimeMinutes == right.bookedLocalTimeMinutes &&
                                left.entryId > right.entryId)))
            },
        )
    }
}
