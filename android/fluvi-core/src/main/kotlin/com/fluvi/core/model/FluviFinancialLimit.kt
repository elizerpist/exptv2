package com.fluvi.core.model

/** A non-category overview target or one real category target. */
sealed interface FluviFinancialLimitTarget {
    data object Aggregate : FluviFinancialLimitTarget

    data class Category(val categoryId: String) : FluviFinancialLimitTarget {
        init {
            require(categoryId.isNotBlank())
        }
    }
}

/**
 * The two canonical persisted limit scopes. YEAR, DAY and SUM are analytical
 * projections over these rows; they can never become competing stored truth.
 */
sealed interface FluviFinancialLimitPeriod {
    data object BaseMonthly : FluviFinancialLimitPeriod

    data class MonthOverride(val year: Int, val month: Int) : FluviFinancialLimitPeriod {
        init {
            require(year in 1..9999)
            require(month in 1..12)
        }
    }
}

data class FluviFinancialLimitKey(
    val direction: LedgerDirection,
    val target: FluviFinancialLimitTarget,
    val period: FluviFinancialLimitPeriod,
) {
    val targetKind: FluviFinancialLimitTargetKind
        get() = when (target) {
            FluviFinancialLimitTarget.Aggregate -> FluviFinancialLimitTargetKind.aggregate
            is FluviFinancialLimitTarget.Category -> FluviFinancialLimitTargetKind.category
        }

    val canonicalTargetKey: String
        get() = when (target) {
            FluviFinancialLimitTarget.Aggregate -> "aggregate"
            is FluviFinancialLimitTarget.Category -> target.categoryId
        }

    val categoryId: String?
        get() = (target as? FluviFinancialLimitTarget.Category)?.categoryId

    val periodKind: FluviFinancialLimitPeriodKind
        get() = when (period) {
            FluviFinancialLimitPeriod.BaseMonthly -> FluviFinancialLimitPeriodKind.base
            is FluviFinancialLimitPeriod.MonthOverride -> FluviFinancialLimitPeriodKind.month
        }

    val canonicalPeriodKey: String
        get() = when (period) {
            FluviFinancialLimitPeriod.BaseMonthly -> "base"
            is FluviFinancialLimitPeriod.MonthOverride -> "month:${period.year}-${period.month}"
        }

    val year: Int?
        get() = when (period) {
            FluviFinancialLimitPeriod.BaseMonthly -> null
            is FluviFinancialLimitPeriod.MonthOverride -> period.year
        }

    val month: Int?
        get() = (period as? FluviFinancialLimitPeriod.MonthOverride)?.month
}

enum class FluviFinancialLimitTargetKind { aggregate, category }

enum class FluviFinancialLimitPeriodKind { base, month }

data class FluviFinancialLimit(
    val key: FluviFinancialLimitKey,
    val amountScaled100: Long,
    val createdAtUtcMs: Long,
    val updatedAtUtcMs: Long,
) {
    init {
        require(amountScaled100 >= 0L)
    }
}
