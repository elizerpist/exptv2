package com.fluvi.core.query

import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class FluviPreparedSpendingRhythmSnapshotTest {
    @Test
    fun classifierCoversEveryThreeHourBoundaryExactlyOnce() {
        SpendingRhythmDayPart.entries.forEachIndexed { index, part ->
            val start = index * BudgetRhythmDayPartClassifier.MINUTES_PER_PART
            val end = start + BudgetRhythmDayPartClassifier.MINUTES_PER_PART - 1
            assertEquals(part, BudgetRhythmDayPartClassifier.classify(start))
            assertEquals(part, BudgetRhythmDayPartClassifier.classify(end))
        }
        (0..1439).forEach { minute ->
            assertEquals(
                SpendingRhythmDayPart.entries[minute / BudgetRhythmDayPartClassifier.MINUTES_PER_PART],
                BudgetRhythmDayPartClassifier.classify(minute),
            )
        }
        assertThrows(IllegalArgumentException::class.java) {
            BudgetRhythmDayPartClassifier.classify(-1)
        }
        assertThrows(IllegalArgumentException::class.java) {
            BudgetRhythmDayPartClassifier.classify(1440)
        }
    }
}
