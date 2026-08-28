package com.fluvi.core.query

import com.fluvi.core.model.LedgerDirection

/**
 * The one canonical ordinal catalogue for a local calendar day's Spending
 * Rhythm. The ordinal is transported to Flutter, where the same display
 * catalogue is used; do not change its order without a transport version.
 */
enum class SpendingRhythmDayPart {
    MIDNIGHT,
    DAWN,
    MORNING,
    LATE_MORNING,
    EARLY_AFTERNOON,
    AFTERNOON,
    EVENING,
    LATE_EVENING,
}

/** Classifies each valid local minute into exactly one contiguous 3-hour part. */
object BudgetRhythmDayPartClassifier {
    const val MINUTES_PER_PART: Int = 180

    fun classify(bookedLocalTimeMinutes: Int): SpendingRhythmDayPart {
        require(bookedLocalTimeMinutes in 0..1439) {
            "Local transaction minute must be in 0..1439."
        }
        return SpendingRhythmDayPart.entries[bookedLocalTimeMinutes / MINUTES_PER_PART]
    }
}

/** One sparse positive local calendar day with all eight retained parts. */
class FluviPreparedSpendingRhythmPoint(
    val epochDay: Long,
    val actualScaled100: Long,
    dayPartActualScaled100: LongArray,
) {
    val dayPartActualScaled100: LongArray = dayPartActualScaled100.copyOf()

    init {
        require(actualScaled100 > 0L)
        require(this.dayPartActualScaled100.size == SpendingRhythmDayPart.entries.size)
        require(this.dayPartActualScaled100.all { it >= 0L })
        require(this.dayPartActualScaled100.sum() == actualScaled100)
    }
}

/**
 * Target-offset compact native source. A target's point range is sorted by
 * local epoch day and shares the direction-local Budget target handle domain.
 */
class FluviPreparedSpendingRhythmDirectionBank(
    val targetCount: Int,
    targetOffsets: IntArray,
    points: List<FluviPreparedSpendingRhythmPoint>,
) {
    val targetOffsets: IntArray = targetOffsets.copyOf()
    val points: List<FluviPreparedSpendingRhythmPoint> = points.toList()

    init {
        require(targetCount > 0)
        require(this.targetOffsets.size == targetCount + 1)
        require(this.targetOffsets.first() == 0)
        require(this.targetOffsets.last() == this.points.size)
        (0 until targetCount).forEach { handle ->
            val start = this.targetOffsets[handle]
            val end = this.targetOffsets[handle + 1]
            require(start in 0..end && end <= this.points.size)
            var previousEpochDay = Long.MIN_VALUE
            (start until end).forEach { index ->
                val point = this.points[index]
                require(point.epochDay > previousEpochDay)
                previousEpochDay = point.epochDay
            }
        }
    }
}

/** Query-independent, exact-revision prepared source for scope rhythm. */
class FluviPreparedSpendingRhythmSnapshot(
    val coreRevision: Long,
    val incomeBank: FluviPreparedSpendingRhythmDirectionBank,
    val expenseBank: FluviPreparedSpendingRhythmDirectionBank,
) {
    init {
        require(coreRevision > 0L)
    }

    fun directionBank(direction: LedgerDirection): FluviPreparedSpendingRhythmDirectionBank = when (direction) {
        LedgerDirection.income -> incomeBank
        LedgerDirection.expense -> expenseBank
    }
}
