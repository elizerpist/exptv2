package com.fluvi.core.query

import com.fluvi.core.model.LedgerDirection

/** One dense partner amount and the category which deterministically owns its
 * presentation colour for this exact direction/period. */
data class FluviPreparedBudgetPartnerDistributionCell(
    val actualScaled100: Long,
    val dominantCategoryId: String,
) {
    init {
        require(actualScaled100 >= 0L)
    }
}

/** Direction-local canonical partner domain. There is intentionally no
 * aggregate handle: a partner distribution denominator is its positive rows. */
data class FluviPreparedBudgetPartnerDistributionDirectionBank(
    val orderedPartnerIds: List<String>,
    val orderedPartnerTitles: List<String>,
    val cells: List<FluviPreparedBudgetPartnerDistributionCell>,
) {
    val partnerCount: Int get() = orderedPartnerIds.size

    fun requireLayout(periodSliceCount: Int) {
        require(orderedPartnerIds.size == orderedPartnerTitles.size)
        require(orderedPartnerIds.distinct().size == orderedPartnerIds.size)
        require(orderedPartnerIds.none { it.isBlank() })
        require(orderedPartnerTitles.none { it.isBlank() })
        require(cells.size == periodSliceCount * partnerCount)
    }
}

/** Compact, query-independent exact-revision source for Budget partner Card2.
 * It deliberately mirrors the prepared Budget period universe without sharing
 * its financial-limit target handles. */
data class FluviPreparedBudgetPartnerDistributionSnapshot(
    val coreRevision: Long,
    val yearWindow: FluviPreparedYearWindow,
    val incomeBank: FluviPreparedBudgetPartnerDistributionDirectionBank,
    val expenseBank: FluviPreparedBudgetPartnerDistributionDirectionBank,
    val sqlCallCount: Int,
    val sqlDurationNanos: Long,
) {
    val yearCount: Int get() = yearWindow.endYearInclusive - yearWindow.startYear + 1
    val periodSliceCount: Int get() = 1 + yearCount + yearCount * 12

    fun directionBank(direction: LedgerDirection): FluviPreparedBudgetPartnerDistributionDirectionBank = when (direction) {
        LedgerDirection.income -> incomeBank
        LedgerDirection.expense -> expenseBank
    }

    init {
        require(coreRevision > 0L)
        require(sqlCallCount >= 0)
        require(sqlDurationNanos >= 0L)
        incomeBank.requireLayout(periodSliceCount)
        expenseBank.requireLayout(periodSliceCount)
    }
}
