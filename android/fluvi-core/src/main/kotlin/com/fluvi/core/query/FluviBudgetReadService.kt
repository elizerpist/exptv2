package com.fluvi.core.query

import androidx.room.withTransaction
import androidx.sqlite.db.SimpleSQLiteQuery
import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.model.FluviFinancialLimitPeriod
import com.fluvi.core.model.FluviFinancialLimitTarget
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.repository.FluviCategoryRepository
import com.fluvi.core.repository.FluviCoreRevisionRepository
import com.fluvi.core.repository.FluviFinancialLimitRepository
import com.fluvi.core.repository.FluviPartnerRepository
import com.fluvi.core.repository.canonicalPartnerIdOf
import java.time.LocalDate

/**
 * Query-independent, bounded native acquisition for the Budget dashboard.
 * One grouped ledger scan covers aggregate/category SUM/YEAR/MONTH values;
 * target count changes the dense output size, never the SQL-call count.
 */
class FluviBudgetReadService internal constructor(
    private val database: FluviDatabase,
    private val categories: FluviCategoryRepository,
    private val financialLimits: FluviFinancialLimitRepository,
    private val partners: FluviPartnerRepository,
    private val revisionRepository: FluviCoreRevisionRepository = FluviCoreRevisionRepository(database),
) {

    /**
     * Query-independent partner distribution acquisition. One ledger grouped
     * scan plus canonical partner/category snapshots covers both directions
     * and the complete SUM/YEAR/MONTH prepared window; partner/category count
     * never changes this bounded SQL-call shape.
     */
    suspend fun preparedPartnerDistributionSnapshot(
        expectedRevision: Long,
        yearWindow: FluviPreparedYearWindow,
    ): FluviPreparedBudgetPartnerDistributionSnapshot = database.withTransaction {
        require(expectedRevision > 0L)
        val startedAt = System.nanoTime()
        var sqlCalls = 0
        val revision = revisionRepository.current().also { sqlCalls += 1 }
        require(revision == expectedRevision) {
            "Partner distribution revision changed before acquisition: expected=$expectedRevision actual=$revision"
        }
        val partnersById = partners.allEntities().associateBy { it.id }.also { sqlCalls += 1 }
        val categoryOrder = categories.allEntities().map { it.id }.also { sqlCalls += 1 }
        val rows = database.openHelper.readableDatabase.query(
            SimpleSQLiteQuery(
                "SELECT direction, partner_id, category_id, booked_local_epoch_day, " +
                    "COALESCE(SUM(amount_scaled_100), 0) AS amount_scaled_100 " +
                    "FROM fluvi_ledger_entries " +
                    "GROUP BY direction, partner_id, category_id, booked_local_epoch_day",
            ),
        ).use { cursor ->
            buildList {
                while (cursor.moveToNext()) {
                    add(
                        PartnerLedgerDayRow(
                            direction = LedgerDirection.valueOf(cursor.getString(0)),
                            partnerId = cursor.getString(1),
                            categoryId = cursor.getString(2),
                            epochDay = cursor.getLong(3),
                            amountScaled100 = cursor.getLong(4),
                        ),
                    )
                }
            }
        }.also { sqlCalls += 1 }
        val representedByDirection = LedgerDirection.entries.associateWith {
            linkedSetOf<String>()
        }
        val representedCategoriesByDirection = LedgerDirection.entries.associateWith {
            linkedSetOf<String>()
        }
        rows.forEach { row ->
            representedByDirection.getValue(row.direction).add(
                canonicalPartnerIdOf(partnersById, row.partnerId),
            )
            representedCategoriesByDirection.getValue(row.direction).add(row.categoryId)
        }
        val banks = LedgerDirection.entries.associateWith { direction ->
            val ids = representedByDirection.getValue(direction).sorted()
            MutablePartnerDirectionBank(
                orderedPartnerIds = ids,
                orderedPartnerTitles = ids.map { id ->
                    val partner = requireNotNull(partnersById[id]) {
                        "Unknown canonical partner ID in prepared distribution: $id"
                    }
                    partner.displayNameOverride ?: partner.originalName
                },
                orderedCategoryIds = categoryOrder.filter(
                    representedCategoriesByDirection.getValue(direction)::contains,
                ),
                periodSliceCount = 1 +
                    (yearWindow.endYearInclusive - yearWindow.startYear + 1) +
                    (yearWindow.endYearInclusive - yearWindow.startYear + 1) * 12,
            )
        }
        rows.forEach { row ->
            if (row.amountScaled100 <= 0L) return@forEach
            val bank = banks.getValue(row.direction)
            val partnerId = canonicalPartnerIdOf(partnersById, row.partnerId)
            val handle = bank.handleByPartnerId[partnerId] ?: return@forEach
            fun add(slice: Int) = bank.add(
                slice = slice,
                partnerHandle = handle,
                categoryId = row.categoryId,
                amount = row.amountScaled100,
            )
            add(0)
            val date = LocalDate.ofEpochDay(row.epochDay)
            if (date.year !in yearWindow.startYear..yearWindow.endYearInclusive) return@forEach
            bank.addDay(
                epochDay = row.epochDay,
                partnerHandle = handle,
                categoryId = row.categoryId,
                amount = row.amountScaled100,
            )
            val yearCount = yearWindow.endYearInclusive - yearWindow.startYear + 1
            add(1 + date.year - yearWindow.startYear)
            add(1 + yearCount +
                (date.year - yearWindow.startYear) * 12 + date.monthValue - 1)
        }
        val finalRevision = revisionRepository.current().also { sqlCalls += 1 }
        require(finalRevision == revision) {
            "Partner distribution revision changed during acquisition: expected=$revision actual=$finalRevision"
        }
        FluviPreparedBudgetPartnerDistributionSnapshot(
            coreRevision = revision,
            yearWindow = yearWindow,
            incomeBank = banks.getValue(LedgerDirection.income).freeze(),
            expenseBank = banks.getValue(LedgerDirection.expense).freeze(),
            sqlCallCount = sqlCalls,
            sqlDurationNanos = System.nanoTime() - startedAt,
        )
    }
    suspend fun preparedLimitSnapshot(
        expectedRevision: Long,
        yearWindow: FluviPreparedYearWindow,
    ): FluviPreparedBudgetLimitSnapshot = database.withTransaction {
        require(expectedRevision > 0L)
        val startedAt = System.nanoTime()
        var sqlCalls = 0
        val revision = revisionRepository.current().also { sqlCalls += 1 }
        require(revision == expectedRevision) {
            "Budget snapshot revision changed before acquisition: expected=$expectedRevision actual=$revision"
        }
        val categoryOrder = categories.allEntities().map { it.id }.also { sqlCalls += 1 }
        val yearCount = yearWindow.endYearInclusive - yearWindow.startYear + 1
        val periodSliceCount = 1 + yearCount + yearCount * 12

        val monthlyRows = database.openHelper.readableDatabase.query(
            SimpleSQLiteQuery(
                "SELECT direction, category_id, booked_local_epoch_day, booked_local_time_minutes, " +
                    "COALESCE(SUM(amount_scaled_100), 0) AS amount_scaled_100 " +
                    "FROM fluvi_ledger_entries " +
                    "GROUP BY direction, category_id, booked_local_epoch_day, booked_local_time_minutes",
            ),
        ).use { cursor ->
            buildList {
                while (cursor.moveToNext()) {
                    add(
                        BudgetLedgerDayRow(
                            direction = LedgerDirection.valueOf(cursor.getString(0)),
                            categoryId = cursor.getString(1),
                            epochDay = cursor.getLong(2),
                            bookedLocalTimeMinutes = cursor.getInt(3),
                            amountScaled100 = cursor.getLong(4),
                        ),
                    )
                }
            }
        }.also { sqlCalls += 1 }

        // Direction membership is all-time ledger representation, never a
        // current-month value and never a financial-limit row. The grouped
        // scan already contains the canonical direction/category tuples, so
        // this remains one bounded native acquisition.
        val representedByDirection = LedgerDirection.entries.associateWith {
            linkedSetOf<String>()
        }
        monthlyRows.forEach { row ->
            representedByDirection.getValue(row.direction).add(row.categoryId)
        }
        val banks = LedgerDirection.entries.associateWith { direction ->
            val orderedCategoryIds = categoryOrder.filter(
                representedByDirection.getValue(direction)::contains,
            )
            MutableBudgetDirectionBank(
                orderedCategoryIds = orderedCategoryIds,
                periodSliceCount = periodSliceCount,
            )
        }

        monthlyRows.forEach { row ->
            val bank = banks.getValue(row.direction)
            val categoryHandle = bank.handleByCategoryId[row.categoryId] ?: return@forEach
            if (row.amountScaled100 > 0L) {
                bank.addSpendingRhythm(
                    targetHandle = 0,
                    epochDay = row.epochDay,
                    bookedLocalTimeMinutes = row.bookedLocalTimeMinutes,
                    amount = row.amountScaled100,
                )
                bank.addSpendingRhythm(
                    targetHandle = categoryHandle,
                    epochDay = row.epochDay,
                    bookedLocalTimeMinutes = row.bookedLocalTimeMinutes,
                    amount = row.amountScaled100,
                )
            }
            val date = LocalDate.ofEpochDay(row.epochDay)
            val sumSlice = 0
            addActual(bank.actualScaled100, bank.targetCount, sumSlice, 0, row.amountScaled100)
            addActual(bank.actualScaled100, bank.targetCount, sumSlice, categoryHandle, row.amountScaled100)
            if (date.year !in yearWindow.startYear..yearWindow.endYearInclusive) return@forEach
            val yearSlice = 1 + date.year - yearWindow.startYear
            val monthSlice = 1 + yearCount + (date.year - yearWindow.startYear) * 12 + date.monthValue - 1
            for (slice in intArrayOf(yearSlice, monthSlice)) {
                addActual(bank.actualScaled100, bank.targetCount, slice, 0, row.amountScaled100)
                addActual(bank.actualScaled100, bank.targetCount, slice, categoryHandle, row.amountScaled100)
            }
        }

        // Persisted truth is base-month plus concrete override only. The
        // prepared YEAR/SUM cells below are derived cache values, never rows
        // that can be independently read or edited.
        val baseByDirectionHandle = LedgerDirection.entries.associateWith {
            hashMapOf<Int, Long>()
        }
        val overridesByDirectionHandleMonth = LedgerDirection.entries.associateWith {
            hashMapOf<Triple<Int, Int, Int>, Long>()
        }
        financialLimits.forPreparedYearWindow(yearWindow.startYear, yearWindow.endYearInclusive)
            .also { sqlCalls += 1 }
            .forEach { limit ->
                val bank = banks.getValue(limit.key.direction)
                val handle = when (val target = limit.key.target) {
                    FluviFinancialLimitTarget.Aggregate -> 0
                    is FluviFinancialLimitTarget.Category ->
                        bank.handleByCategoryId[target.categoryId] ?: return@forEach
                }
                when (val period = limit.key.period) {
                    FluviFinancialLimitPeriod.BaseMonthly ->
                        baseByDirectionHandle.getValue(limit.key.direction)[handle] =
                            limit.amountScaled100
                    is FluviFinancialLimitPeriod.MonthOverride ->
                        overridesByDirectionHandleMonth.getValue(limit.key.direction)[
                            Triple(handle, period.year, period.month)
                        ] = limit.amountScaled100
                }
            }
        LedgerDirection.entries.forEach { direction ->
            val bank = banks.getValue(direction)
            val bases = baseByDirectionHandle.getValue(direction)
            val overrides = overridesByDirectionHandleMonth.getValue(direction)
            (0 until bank.targetCount).forEach { handle ->
                val base = bases[handle]
                bank.limitScaled100[cellIndex(bank.targetCount, 0, handle)] = base ?: -1L
                bank.limitSource[cellIndex(bank.targetCount, 0, handle)] =
                    if (base == null) 0 else 1
                (0 until yearCount).forEach { yearOffset ->
                    val year = yearWindow.startYear + yearOffset
                    var annual = 0L
                    var allMonthsResolved = true
                    (1..12).forEach { month ->
                        val overrideKey = Triple(handle, year, month)
                        val override = overrides[overrideKey]
                        val resolved = override ?: base
                        val monthSlice = 1 + yearCount + yearOffset * 12 + month - 1
                        val resolvedCellIndex = cellIndex(bank.targetCount, monthSlice, handle)
                        bank.limitScaled100[resolvedCellIndex] = resolved ?: -1L
                        bank.limitSource[resolvedCellIndex] = when {
                            override != null -> 2
                            base != null -> 1
                            else -> 0
                        }
                        if (resolved != null) {
                            annual += resolved
                        } else {
                            allMonthsResolved = false
                        }
                    }
                    val yearSlice = 1 + yearOffset
                    bank.limitScaled100[cellIndex(bank.targetCount, yearSlice, handle)] =
                        if (allMonthsResolved) annual else -1L
                    bank.limitSource[cellIndex(bank.targetCount, yearSlice, handle)] =
                        if (allMonthsResolved) 1 else 0
                }
            }
        }

        val finalRevision = revisionRepository.current().also { sqlCalls += 1 }
        require(finalRevision == revision) {
            "Budget snapshot revision changed during acquisition: expected=$revision actual=$finalRevision"
        }
        FluviPreparedBudgetLimitSnapshot(
            coreRevision = revision,
            yearWindow = yearWindow,
            incomeBank = banks.getValue(LedgerDirection.income).freeze(),
            expenseBank = banks.getValue(LedgerDirection.expense).freeze(),
            spendingRhythmSnapshot = FluviPreparedSpendingRhythmSnapshot(
                coreRevision = revision,
                incomeBank = banks.getValue(LedgerDirection.income).freezeSpendingRhythm(),
                expenseBank = banks.getValue(LedgerDirection.expense).freezeSpendingRhythm(),
            ),
            sqlCallCount = sqlCalls,
            sqlDurationNanos = System.nanoTime() - startedAt,
        )
    }

    private fun addActual(
        actuals: LongArray,
        targetCount: Int,
        slice: Int,
        handle: Int,
        amount: Long,
    ) {
        actuals[cellIndex(targetCount, slice, handle)] += amount
    }

    private fun cellIndex(
        targetCount: Int,
        slice: Int,
        handle: Int,
    ): Int = slice * targetCount + handle

    private data class BudgetLedgerDayRow(
        val direction: LedgerDirection,
        val categoryId: String,
        val epochDay: Long,
        val bookedLocalTimeMinutes: Int,
        val amountScaled100: Long,
    )

    private data class PartnerLedgerDayRow(
        val direction: LedgerDirection,
        val partnerId: String,
        val categoryId: String,
        val epochDay: Long,
        val amountScaled100: Long,
    )

    private data class PartnerCategoryCellKey(
        val cellIndex: Int,
        val categoryId: String,
    )

    private data class PartnerDayKey(
        val epochDay: Long,
        val partnerHandle: Int,
    )

    private data class PartnerDayCategoryKey(
        val epochDay: Long,
        val partnerHandle: Int,
        val categoryId: String,
    )

    private data class MutablePartnerDirectionBank(
        val orderedPartnerIds: List<String>,
        val orderedPartnerTitles: List<String>,
        val orderedCategoryIds: List<String>,
        val periodSliceCount: Int,
        val handleByPartnerId: Map<String, Int> = orderedPartnerIds
            .withIndex()
            .associate { (index, id) -> id to index },
        val actualScaled100: LongArray = LongArray(periodSliceCount * orderedPartnerIds.size),
        val dominantCategoryIds: Array<String> =
            Array(periodSliceCount * orderedPartnerIds.size) { "" },
        val dominantCategoryAmounts: LongArray =
            LongArray(periodSliceCount * orderedPartnerIds.size),
        val categoryAmounts: MutableMap<PartnerCategoryCellKey, Long> = hashMapOf(),
        val dayActualScaled100: MutableMap<PartnerDayKey, Long> = hashMapOf(),
        val dayCategoryAmounts: MutableMap<PartnerDayCategoryKey, Long> = hashMapOf(),
    ) {
        val partnerCount: Int get() = orderedPartnerIds.size

        fun add(
            slice: Int,
            partnerHandle: Int,
            categoryId: String,
            amount: Long,
        ) {
            val index = slice * partnerCount + partnerHandle
            actualScaled100[index] += amount
            val categoryKey = PartnerCategoryCellKey(index, categoryId)
            val categoryAmount = (categoryAmounts[categoryKey] ?: 0L) + amount
            categoryAmounts[categoryKey] = categoryAmount
            val currentCategory = dominantCategoryIds[index]
            if (categoryAmount > dominantCategoryAmounts[index] ||
                (categoryAmount == dominantCategoryAmounts[index] &&
                    (currentCategory.isEmpty() || categoryId < currentCategory))
            ) {
                dominantCategoryAmounts[index] = categoryAmount
                dominantCategoryIds[index] = categoryId
            }
        }

        fun addDay(
            epochDay: Long,
            partnerHandle: Int,
            categoryId: String,
            amount: Long,
        ) {
            val key = PartnerDayKey(epochDay, partnerHandle)
            dayActualScaled100[key] = (dayActualScaled100[key] ?: 0L) + amount
            val categoryKey = PartnerDayCategoryKey(epochDay, partnerHandle, categoryId)
            dayCategoryAmounts[categoryKey] =
                (dayCategoryAmounts[categoryKey] ?: 0L) + amount
        }

        fun freeze(): FluviPreparedBudgetPartnerDistributionDirectionBank {
            val offsets = IntArray(periodSliceCount * orderedCategoryIds.size + 1)
            val contributions = ArrayList<FluviPreparedBudgetPartnerCategoryContribution>()
            var offsetIndex = 0
            (0 until periodSliceCount).forEach { slice ->
                orderedCategoryIds.forEach { categoryId ->
                    (0 until partnerCount).forEach { partnerHandle ->
                        val amount = categoryAmounts[
                            PartnerCategoryCellKey(slice * partnerCount + partnerHandle, categoryId)
                        ] ?: 0L
                        if (amount > 0L) {
                            contributions += FluviPreparedBudgetPartnerCategoryContribution(
                                partnerHandle = partnerHandle,
                                actualScaled100 = amount,
                            )
                        }
                    }
                    offsets[++offsetIndex] = contributions.size
                }
            }
            val days = dayActualScaled100.keys
                .asSequence()
                .map { it.epochDay }
                .distinct()
                .sorted()
                .toList()
            val dayAggregateOffsets = IntArray(days.size + 1)
            val dayAggregateCells = ArrayList<FluviPreparedBudgetPartnerDayCell>()
            val dayCategoryOffsets = IntArray(days.size * orderedCategoryIds.size + 1)
            val dayCategoryContributions = ArrayList<FluviPreparedBudgetPartnerCategoryContribution>()
            days.forEachIndexed { dayIndex, epochDay ->
                (0 until partnerCount).forEach { partnerHandle ->
                    val amount = dayActualScaled100[PartnerDayKey(epochDay, partnerHandle)] ?: 0L
                    if (amount <= 0L) return@forEach
                    var dominantCategoryId = ""
                    var dominantAmount = 0L
                    orderedCategoryIds.forEach { categoryId ->
                        val categoryAmount = dayCategoryAmounts[
                            PartnerDayCategoryKey(epochDay, partnerHandle, categoryId)
                        ] ?: 0L
                        if (categoryAmount > dominantAmount ||
                            (categoryAmount == dominantAmount &&
                                (dominantCategoryId.isEmpty() || categoryId < dominantCategoryId))
                        ) {
                            dominantAmount = categoryAmount
                            dominantCategoryId = categoryId
                        }
                    }
                    if (dominantCategoryId.isNotEmpty()) {
                        dayAggregateCells += FluviPreparedBudgetPartnerDayCell(
                            partnerHandle = partnerHandle,
                            actualScaled100 = amount,
                            dominantCategoryId = dominantCategoryId,
                        )
                    }
                }
                dayAggregateOffsets[dayIndex + 1] = dayAggregateCells.size
                orderedCategoryIds.forEachIndexed { categoryIndex, categoryId ->
                    (0 until partnerCount).forEach { partnerHandle ->
                        val amount = dayCategoryAmounts[
                            PartnerDayCategoryKey(epochDay, partnerHandle, categoryId)
                        ] ?: 0L
                        if (amount > 0L) {
                            dayCategoryContributions += FluviPreparedBudgetPartnerCategoryContribution(
                                partnerHandle = partnerHandle,
                                actualScaled100 = amount,
                            )
                        }
                    }
                    dayCategoryOffsets[
                        dayIndex * orderedCategoryIds.size + categoryIndex + 1
                    ] = dayCategoryContributions.size
                }
            }
            return FluviPreparedBudgetPartnerDistributionDirectionBank(
                orderedPartnerIds = orderedPartnerIds,
                orderedPartnerTitles = orderedPartnerTitles,
                cells = actualScaled100.indices.map { index ->
                    FluviPreparedBudgetPartnerDistributionCell(
                        actualScaled100 = actualScaled100[index],
                        dominantCategoryId = dominantCategoryIds[index],
                    )
                },
                orderedCategoryIds = orderedCategoryIds,
                categoryContributionOffsets = offsets,
                categoryContributions = contributions,
                dayEpochDays = days.toLongArray(),
                dayAggregateOffsets = dayAggregateOffsets,
                dayAggregateCells = dayAggregateCells,
                dayCategoryContributionOffsets = dayCategoryOffsets,
                dayCategoryContributions = dayCategoryContributions,
            )
        }
    }

    private data class MutableBudgetDirectionBank(
        val orderedCategoryIds: List<String>,
        val periodSliceCount: Int,
        val handleByCategoryId: Map<String, Int> = orderedCategoryIds
            .withIndex()
            .associate { (index, id) -> id to index + 1 },
        val actualScaled100: LongArray = LongArray(periodSliceCount * (orderedCategoryIds.size + 1)),
        val limitScaled100: LongArray = LongArray(periodSliceCount * (orderedCategoryIds.size + 1)) { -1L },
        val limitSource: ByteArray = ByteArray(periodSliceCount * (orderedCategoryIds.size + 1)),
        val spendingRhythmByTarget: MutableMap<Int, MutableMap<Long, MutableSpendingRhythmDay>> = hashMapOf(),
    ) {
        val targetCount: Int get() = orderedCategoryIds.size + 1

        fun freeze(): FluviPreparedBudgetDirectionBank = FluviPreparedBudgetDirectionBank(
            orderedCategoryIds = orderedCategoryIds,
            actualScaled100 = actualScaled100,
            limitScaled100 = limitScaled100,
            limitSource = limitSource,
        )

        fun addSpendingRhythm(
            targetHandle: Int,
            epochDay: Long,
            bookedLocalTimeMinutes: Int,
            amount: Long,
        ) {
            require(targetHandle in 0 until targetCount)
            require(amount > 0L)
            val days = spendingRhythmByTarget.getOrPut(targetHandle) { hashMapOf() }
            val day = days.getOrPut(epochDay) { MutableSpendingRhythmDay() }
            day.actualScaled100 += amount
            val part = BudgetRhythmDayPartClassifier.classify(bookedLocalTimeMinutes)
            day.dayPartActualScaled100[part.ordinal] += amount
        }

        fun freezeSpendingRhythm(): FluviPreparedSpendingRhythmDirectionBank {
            val offsets = IntArray(targetCount + 1)
            val points = ArrayList<FluviPreparedSpendingRhythmPoint>()
            (0 until targetCount).forEach { handle ->
                spendingRhythmByTarget[handle]
                    .orEmpty()
                    .toSortedMap()
                    .forEach { (epochDay, day) ->
                        points += FluviPreparedSpendingRhythmPoint(
                            epochDay = epochDay,
                            actualScaled100 = day.actualScaled100,
                            dayPartActualScaled100 = day.dayPartActualScaled100,
                        )
                    }
                offsets[handle + 1] = points.size
            }
            return FluviPreparedSpendingRhythmDirectionBank(
                targetCount = targetCount,
                targetOffsets = offsets,
                points = points,
            )
        }

        private class MutableSpendingRhythmDay(
            var actualScaled100: Long = 0L,
            val dayPartActualScaled100: LongArray =
                LongArray(SpendingRhythmDayPart.entries.size),
        )
    }
}
