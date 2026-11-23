package com.fluvi.core.query

import com.fluvi.core.model.FluviFinancialLimit
import com.fluvi.core.model.FluviFinancialLimitPeriod
import com.fluvi.core.model.FluviFinancialLimitTarget
import com.fluvi.core.model.LedgerDirection
import java.time.LocalDate
import java.time.YearMonth

/** Only the non-textual visual projection leaves the core read transaction. */
data class FluviKeyguardBudgetProjection(
    val coreRevision: Long,
    val categoryColorId: String?,
    val remainingPercent: Double?,
    val projectionAvailable: Boolean,
)

enum class FluviKeyguardBudgetAxis { sum, year, month, day }

/** Shared with the existing notification/card resolver; the persisted limit remains the authority. */
fun resolveKeyguardCategoryLimit(
    limits: List<FluviFinancialLimit>,
    direction: LedgerDirection,
    categoryId: String,
    axis: FluviKeyguardBudgetAxis,
    now: LocalDate,
): Long? {
    val selected = limits.filter {
        it.key.direction == direction &&
            (it.key.target as? FluviFinancialLimitTarget.Category)?.categoryId == categoryId
    }
    fun monthLimit(month: YearMonth): Long? {
        selected.firstOrNull { limit ->
            (limit.key.period as? FluviFinancialLimitPeriod.MonthOverride)?.let {
                it.year == month.year && it.month == month.monthValue
            } == true
        }?.let { return it.amountScaled100 }
        return selected.filter { it.key.period is FluviFinancialLimitPeriod.BaseMonthlyRevision }
            .filter { limit ->
                (limit.key.period as FluviFinancialLimitPeriod.BaseMonthlyRevision).let {
                    it.effectiveFromYear < month.year ||
                        it.effectiveFromYear == month.year && it.effectiveFromMonth <= month.monthValue
                }
            }
            .maxWithOrNull(compareBy { limit ->
                (limit.key.period as FluviFinancialLimitPeriod.BaseMonthlyRevision).let {
                    it.effectiveFromYear * 12 + it.effectiveFromMonth
                }
            })?.amountScaled100
    }
    return when (axis) {
        FluviKeyguardBudgetAxis.month -> monthLimit(YearMonth.from(now))
        FluviKeyguardBudgetAxis.day -> monthLimit(YearMonth.from(now))?.div(now.lengthOfMonth().toLong())
        // SUM has no independent stored limit; preserve the existing annual projection.
        FluviKeyguardBudgetAxis.year, FluviKeyguardBudgetAxis.sum ->
            (1..12).mapNotNull { monthLimit(YearMonth.of(now.year, it)) }
                .takeIf { it.size == 12 }?.sum()
    }
}
