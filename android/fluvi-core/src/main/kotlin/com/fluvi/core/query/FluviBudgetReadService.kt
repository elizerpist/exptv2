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
    private val revisionRepository: FluviCoreRevisionRepository = FluviCoreRevisionRepository(database),
) {
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
                "SELECT direction, category_id, booked_local_epoch_day, " +
                    "COALESCE(SUM(amount_scaled_100), 0) AS amount_scaled_100 " +
                    "FROM fluvi_ledger_entries " +
                    "GROUP BY direction, category_id, booked_local_epoch_day",
            ),
        ).use { cursor ->
            buildList {
                while (cursor.moveToNext()) {
                    add(
                        BudgetLedgerDayRow(
                            direction = LedgerDirection.valueOf(cursor.getString(0)),
                            categoryId = cursor.getString(1),
                            epochDay = cursor.getLong(2),
                            amountScaled100 = cursor.getLong(3),
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

        financialLimits.forPreparedYearWindow(yearWindow.startYear, yearWindow.endYearInclusive)
            .also { sqlCalls += 1 }
            .forEach { limit ->
                val bank = banks.getValue(limit.key.direction)
                val handle = when (val target = limit.key.target) {
                    FluviFinancialLimitTarget.Aggregate -> 0
                    is FluviFinancialLimitTarget.Category ->
                        bank.handleByCategoryId[target.categoryId] ?: return@forEach
                }
                val slice = sliceIndex(limit.key.period, yearWindow, yearCount)
                bank.limitScaled100[cellIndex(bank.targetCount, slice, handle)] = limit.amountScaled100
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

    private fun sliceIndex(
        period: FluviFinancialLimitPeriod,
        window: FluviPreparedYearWindow,
        yearCount: Int,
    ): Int = when (period) {
        FluviFinancialLimitPeriod.Sum -> 0
        is FluviFinancialLimitPeriod.Year -> 1 + (period.year - window.startYear)
        is FluviFinancialLimitPeriod.Month ->
            1 + yearCount + (period.year - window.startYear) * 12 + period.month - 1
    }.also { index ->
        require(index in 0 until (1 + yearCount + yearCount * 12)) {
            "Financial limit period lies outside prepared Budget window."
        }
    }

    private data class BudgetLedgerDayRow(
        val direction: LedgerDirection,
        val categoryId: String,
        val epochDay: Long,
        val amountScaled100: Long,
    )

    private data class MutableBudgetDirectionBank(
        val orderedCategoryIds: List<String>,
        val periodSliceCount: Int,
        val handleByCategoryId: Map<String, Int> = orderedCategoryIds
            .withIndex()
            .associate { (index, id) -> id to index + 1 },
        val actualScaled100: LongArray = LongArray(periodSliceCount * (orderedCategoryIds.size + 1)),
        val limitScaled100: LongArray = LongArray(periodSliceCount * (orderedCategoryIds.size + 1)) { -1L },
    ) {
        val targetCount: Int get() = orderedCategoryIds.size + 1

        fun freeze(): FluviPreparedBudgetDirectionBank = FluviPreparedBudgetDirectionBank(
            orderedCategoryIds = orderedCategoryIds,
            actualScaled100 = actualScaled100,
            limitScaled100 = limitScaled100,
        )
    }
}
