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
        val orderedCategoryIds = categories.allEntities().map { it.id }.also { sqlCalls += 1 }
        val targetCount = orderedCategoryIds.size + 1
        val yearCount = yearWindow.endYearInclusive - yearWindow.startYear + 1
        val periodSliceCount = 1 + yearCount + yearCount * 12
        val cellsPerDirection = periodSliceCount * targetCount
        val actuals = LongArray(LedgerDirection.entries.size * cellsPerDirection)
        val limits = LongArray(LedgerDirection.entries.size * cellsPerDirection) { -1L }
        val handleByCategoryId = orderedCategoryIds.withIndex().associate { (index, id) -> id to index + 1 }

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

        monthlyRows.forEach { row ->
            val categoryHandle = handleByCategoryId[row.categoryId] ?: return@forEach
            val date = LocalDate.ofEpochDay(row.epochDay)
            val sumSlice = 0
            addActual(actuals, cellsPerDirection, targetCount, row.direction, sumSlice, 0, row.amountScaled100)
            addActual(actuals, cellsPerDirection, targetCount, row.direction, sumSlice, categoryHandle, row.amountScaled100)
            if (date.year !in yearWindow.startYear..yearWindow.endYearInclusive) return@forEach
            val yearSlice = 1 + date.year - yearWindow.startYear
            val monthSlice = 1 + yearCount + (date.year - yearWindow.startYear) * 12 + date.monthValue - 1
            for (slice in intArrayOf(yearSlice, monthSlice)) {
                addActual(actuals, cellsPerDirection, targetCount, row.direction, slice, 0, row.amountScaled100)
                addActual(actuals, cellsPerDirection, targetCount, row.direction, slice, categoryHandle, row.amountScaled100)
            }
        }

        financialLimits.forPreparedYearWindow(yearWindow.startYear, yearWindow.endYearInclusive)
            .also { sqlCalls += 1 }
            .forEach { limit ->
                val handle = when (val target = limit.key.target) {
                    FluviFinancialLimitTarget.Aggregate -> 0
                    is FluviFinancialLimitTarget.Category -> handleByCategoryId[target.categoryId] ?: return@forEach
                }
                val slice = sliceIndex(limit.key.period, yearWindow, yearCount)
                limits[cellIndex(cellsPerDirection, targetCount, limit.key.direction, slice, handle)] =
                    limit.amountScaled100
            }

        val finalRevision = revisionRepository.current().also { sqlCalls += 1 }
        require(finalRevision == revision) {
            "Budget snapshot revision changed during acquisition: expected=$revision actual=$finalRevision"
        }
        FluviPreparedBudgetLimitSnapshot(
            coreRevision = revision,
            yearWindow = yearWindow,
            orderedCategoryIds = orderedCategoryIds,
            actualScaled100 = actuals,
            limitScaled100 = limits,
            sqlCallCount = sqlCalls,
            sqlDurationNanos = System.nanoTime() - startedAt,
        )
    }

    private fun addActual(
        actuals: LongArray,
        cellsPerDirection: Int,
        targetCount: Int,
        direction: LedgerDirection,
        slice: Int,
        handle: Int,
        amount: Long,
    ) {
        actuals[cellIndex(cellsPerDirection, targetCount, direction, slice, handle)] += amount
    }

    private fun cellIndex(
        cellsPerDirection: Int,
        targetCount: Int,
        direction: LedgerDirection,
        slice: Int,
        handle: Int,
    ): Int = direction.ordinal * cellsPerDirection + slice * targetCount + handle

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
}
