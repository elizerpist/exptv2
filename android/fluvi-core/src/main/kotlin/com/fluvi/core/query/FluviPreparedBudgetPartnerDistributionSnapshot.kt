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

/** Sparse exact category contribution to one direction-local partner. */
data class FluviPreparedBudgetPartnerCategoryContribution(
    val partnerHandle: Int,
    val actualScaled100: Long,
) {
    init {
        require(partnerHandle >= 0)
        require(actualScaled100 > 0L)
    }
}

/** Direction-local canonical partner domain. There is intentionally no
 * aggregate handle: a partner distribution denominator is its positive rows. */
data class FluviPreparedBudgetPartnerDistributionDirectionBank(
    val orderedPartnerIds: List<String>,
    val orderedPartnerTitles: List<String>,
    val cells: List<FluviPreparedBudgetPartnerDistributionCell>,
    val orderedCategoryIds: List<String> = emptyList(),
    val categoryContributionOffsets: IntArray = IntArray(1),
    val categoryContributions: List<FluviPreparedBudgetPartnerCategoryContribution> = emptyList(),
) {
    val partnerCount: Int get() = orderedPartnerIds.size

    fun requireLayout(periodSliceCount: Int) {
        require(orderedPartnerIds.size == orderedPartnerTitles.size)
        require(orderedPartnerIds.distinct().size == orderedPartnerIds.size)
        require(orderedPartnerIds.none { it.isBlank() })
        require(orderedPartnerTitles.none { it.isBlank() })
        require(cells.size == periodSliceCount * partnerCount)
        require(orderedCategoryIds.distinct().size == orderedCategoryIds.size)
        val contributionTargets = periodSliceCount * orderedCategoryIds.size
        require(categoryContributionOffsets.size == contributionTargets + 1)
        require(categoryContributionOffsets.first() == 0)
        require(categoryContributionOffsets.last() == categoryContributions.size)
        (0 until contributionTargets).forEach { index ->
            val start = categoryContributionOffsets[index]
            val end = categoryContributionOffsets[index + 1]
            require(start in 0..end && end <= categoryContributions.size)
            var previousPartnerHandle = -1
            (start until end).forEach { contributionIndex ->
                val contribution = categoryContributions[contributionIndex]
                require(contribution.partnerHandle > previousPartnerHandle)
                require(contribution.partnerHandle < partnerCount)
                previousPartnerHandle = contribution.partnerHandle
            }
        }
    }

    fun contributionsFor(
        periodSliceIndex: Int,
        targetHandle: Int,
    ): List<FluviPreparedBudgetPartnerCategoryContribution> {
        if (targetHandle == 0) return emptyList()
        require(targetHandle in 1..orderedCategoryIds.size)
        val index = periodSliceIndex * orderedCategoryIds.size + targetHandle - 1
        return categoryContributions.subList(
            categoryContributionOffsets[index],
            categoryContributionOffsets[index + 1],
        )
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
