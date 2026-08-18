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

/** Compact native source for the prepared Flutter Budget limit bank. */
data class FluviPreparedBudgetLimitSnapshot(
    val coreRevision: Long,
    val yearWindow: FluviPreparedYearWindow,
    val incomeBank: FluviPreparedBudgetDirectionBank,
    val expenseBank: FluviPreparedBudgetDirectionBank,
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
    }
}
