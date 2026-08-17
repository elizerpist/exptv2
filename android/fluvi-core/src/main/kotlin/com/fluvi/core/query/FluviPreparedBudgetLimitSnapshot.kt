package com.fluvi.core.query

/** Compact native source for the prepared Flutter Budget limit bank. */
data class FluviPreparedBudgetLimitSnapshot(
    val coreRevision: Long,
    val yearWindow: FluviPreparedYearWindow,
    val orderedCategoryIds: List<String>,
    val actualScaled100: LongArray,
    /** -1 means no persisted limit; zero remains a valid real limit. */
    val limitScaled100: LongArray,
    val sqlCallCount: Int,
    val sqlDurationNanos: Long,
) {
    val targetCount: Int get() = orderedCategoryIds.size + 1
    val yearCount: Int get() = yearWindow.endYearInclusive - yearWindow.startYear + 1
    val periodSliceCount: Int get() = 1 + yearCount + yearCount * 12
    val cellCount: Int get() = actualScaled100.size

    init {
        val expected = 2 * periodSliceCount * targetCount
        require(actualScaled100.size == expected)
        require(limitScaled100.size == expected)
        require(limitScaled100.all { it >= -1L })
    }
}
