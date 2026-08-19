package com.fluvi.core.query

import com.fluvi.core.model.LedgerDirection

/** One direction-local dense Budget target domain. Handles are never shared
 * across directions: zero is aggregate and category handles follow this
 * bank's own authoritative category order. */
data class FluviPreparedBudgetDirectionBank(
    val orderedCategoryIds: List<String>,
    val actualScaled100: LongArray,
    /** -1 means no persisted limit; zero remains a valid real limit. */
    val limitScaled100: LongArray,
) {
    val targetCount: Int get() = orderedCategoryIds.size + 1

    fun requireLayout(periodSliceCount: Int) {
        require(orderedCategoryIds.distinct().size == orderedCategoryIds.size)
        val expected = periodSliceCount * targetCount
        require(actualScaled100.size == expected)
        require(limitScaled100.size == expected)
        require(limitScaled100.all { it >= -1L })
    }
}

/** Sparse positive daily actuals keyed by the same direction-local Budget
 * target handles as [FluviPreparedBudgetDirectionBank]. */
data class FluviPreparedBudgetRhythmPoint(
    val epochDay: Long,
    val actualScaled100: Long,
) {
    init {
        require(actualScaled100 > 0L)
    }
}

data class FluviPreparedBudgetRhythmDirectionBank(
    val targetCount: Int,
    val targetOffsets: IntArray,
    val points: List<FluviPreparedBudgetRhythmPoint>,
) {
    init {
        require(targetCount > 0)
        require(targetOffsets.size == targetCount + 1)
        require(targetOffsets.first() == 0)
        require(targetOffsets.last() == points.size)
        (0 until targetCount).forEach { handle ->
            val start = targetOffsets[handle]
            val end = targetOffsets[handle + 1]
            require(start in 0..end && end <= points.size)
            var previous = Long.MIN_VALUE
            (start until end).forEach { index ->
                val point = points[index]
                require(point.epochDay > previous)
                previous = point.epochDay
            }
        }
    }
}

data class FluviPreparedBudgetRhythmSnapshot(
    val coreRevision: Long,
    val incomeBank: FluviPreparedBudgetRhythmDirectionBank,
    val expenseBank: FluviPreparedBudgetRhythmDirectionBank,
) {
    fun directionBank(direction: LedgerDirection): FluviPreparedBudgetRhythmDirectionBank = when (direction) {
        LedgerDirection.income -> incomeBank
        LedgerDirection.expense -> expenseBank
    }
}

/** Compact native source for the prepared Flutter Budget limit bank. */
data class FluviPreparedBudgetLimitSnapshot(
    val coreRevision: Long,
    val yearWindow: FluviPreparedYearWindow,
    val incomeBank: FluviPreparedBudgetDirectionBank,
    val expenseBank: FluviPreparedBudgetDirectionBank,
    val rhythmSnapshot: FluviPreparedBudgetRhythmSnapshot,
    val sqlCallCount: Int,
    val sqlDurationNanos: Long,
) {
    val yearCount: Int get() = yearWindow.endYearInclusive - yearWindow.startYear + 1
    val periodSliceCount: Int get() = 1 + yearCount + yearCount * 12

    fun directionBank(direction: LedgerDirection): FluviPreparedBudgetDirectionBank = when (direction) {
        LedgerDirection.income -> incomeBank
        LedgerDirection.expense -> expenseBank
    }

    init {
        incomeBank.requireLayout(periodSliceCount)
        expenseBank.requireLayout(periodSliceCount)
        require(rhythmSnapshot.coreRevision == coreRevision)
        require(rhythmSnapshot.incomeBank.targetCount == incomeBank.targetCount)
        require(rhythmSnapshot.expenseBank.targetCount == expenseBank.targetCount)
    }
}
