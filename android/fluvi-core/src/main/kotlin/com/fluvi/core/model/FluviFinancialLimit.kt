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

/** The three typed financial-limit periods supported by the dashboard. */
sealed interface FluviFinancialLimitPeriod {
    data object Sum : FluviFinancialLimitPeriod

    data class Year(val year: Int) : FluviFinancialLimitPeriod {
        init {
            require(year in 1..9999)
        }
    }

    data class Month(val year: Int, val month: Int) : FluviFinancialLimitPeriod {
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
            FluviFinancialLimitPeriod.Sum -> FluviFinancialLimitPeriodKind.sum
            is FluviFinancialLimitPeriod.Year -> FluviFinancialLimitPeriodKind.year
            is FluviFinancialLimitPeriod.Month -> FluviFinancialLimitPeriodKind.month
        }

    val canonicalPeriodKey: String
        get() = when (period) {
            FluviFinancialLimitPeriod.Sum -> "sum"
            is FluviFinancialLimitPeriod.Year -> "year:${period.year}"
            is FluviFinancialLimitPeriod.Month -> "month:${period.year}-${period.month}"
        }

    val year: Int?
        get() = when (period) {
            FluviFinancialLimitPeriod.Sum -> null
            is FluviFinancialLimitPeriod.Year -> period.year
            is FluviFinancialLimitPeriod.Month -> period.year
        }

    val month: Int?
        get() = (period as? FluviFinancialLimitPeriod.Month)?.month
}

enum class FluviFinancialLimitTargetKind { aggregate, category }

enum class FluviFinancialLimitPeriodKind { sum, year, month }

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
