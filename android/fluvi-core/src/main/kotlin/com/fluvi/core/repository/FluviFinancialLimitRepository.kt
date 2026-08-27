package com.fluvi.core.repository

import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.entity.FluviFinancialLimitEntity
import com.fluvi.core.model.FluviFinancialLimit
import com.fluvi.core.model.FluviFinancialLimitKey
import com.fluvi.core.model.FluviFinancialLimitPeriod
import com.fluvi.core.model.FluviFinancialLimitPeriodKind
import com.fluvi.core.model.FluviFinancialLimitTarget
import com.fluvi.core.model.FluviFinancialLimitTargetKind

/** Internal Room adapter. Public callers only see typed keys through the use case. */
internal class FluviFinancialLimitRepository(
    database: FluviDatabase,
) {
    private val limits = database.financialLimitDao()

    suspend fun find(key: FluviFinancialLimitKey): FluviFinancialLimit? =
        limits.find(key.direction, key.canonicalTargetKey, key.canonicalPeriodKey)?.toDomain()

    suspend fun all(): List<FluviFinancialLimit> = limits.all().map { it.toDomain() }

    suspend fun forPreparedYearWindow(startYear: Int, endYear: Int): List<FluviFinancialLimit> =
        limits.forPreparedYearWindow(startYear, endYear).map { it.toDomain() }

    suspend fun upsert(limit: FluviFinancialLimit) {
        limits.upsert(limit.toEntity())
    }

    suspend fun upsertAll(values: List<FluviFinancialLimit>) {
        if (values.isNotEmpty()) limits.upsertAll(values.map { it.toEntity() })
    }

    suspend fun delete(key: FluviFinancialLimitKey): Boolean =
        limits.delete(key.direction, key.canonicalTargetKey, key.canonicalPeriodKey) == 1

    suspend fun deleteAll(): Int = limits.deleteAll()

    suspend fun count(): Long = limits.count()

    private fun FluviFinancialLimit.toEntity() = FluviFinancialLimitEntity(
        direction = key.direction,
        targetKind = key.targetKind,
        targetKey = key.canonicalTargetKey,
        categoryId = key.categoryId,
        periodKind = key.periodKind,
        periodKey = key.canonicalPeriodKey,
        year = key.year,
        month = key.month,
        limitAmountScaled100 = amountScaled100,
        createdAtUtcMs = createdAtUtcMs,
        updatedAtUtcMs = updatedAtUtcMs,
    )

    private fun FluviFinancialLimitEntity.toDomain(): FluviFinancialLimit {
        val target = when (targetKind) {
            FluviFinancialLimitTargetKind.aggregate -> FluviFinancialLimitTarget.Aggregate
            FluviFinancialLimitTargetKind.category ->
                FluviFinancialLimitTarget.Category(requireNotNull(categoryId))
        }
        val period = when (periodKind) {
            FluviFinancialLimitPeriodKind.base -> FluviFinancialLimitPeriod.BaseMonthly
            FluviFinancialLimitPeriodKind.month -> FluviFinancialLimitPeriod.MonthOverride(
                requireNotNull(year),
                requireNotNull(month),
            )
        }
        return FluviFinancialLimit(
            key = FluviFinancialLimitKey(direction, target, period),
            amountScaled100 = limitAmountScaled100,
            createdAtUtcMs = createdAtUtcMs,
            updatedAtUtcMs = updatedAtUtcMs,
        )
    }
}
