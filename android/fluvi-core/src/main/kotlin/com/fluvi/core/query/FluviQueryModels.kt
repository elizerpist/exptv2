package com.fluvi.core.query

import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.QueryPeriodKind
import com.fluvi.core.model.CategoryAssignmentMode
import com.fluvi.core.model.LedgerOriginKind

data class FluviQueryScope(
    val direction: LedgerDirection,
    val periodGroups: List<FluviPeriodGroup> = emptyList(),
    val categoryIds: Set<String> = emptySet(),
    val partnerIds: Set<String> = emptySet(),
    val refinements: FluviQueryRefinements = FluviQueryRefinements(),
) {
    init {
        require(periodGroups.map { it.key }.distinct().size == periodGroups.size) {
            "Each Fluvi Query time group must have a unique key."
        }
        require(categoryIds.none { it.isBlank() }) { "Category IDs must not be blank." }
        require(partnerIds.none { it.isBlank() }) { "Partner IDs must not be blank." }
    }
}

/** Two independent directional predicates represented by one dashboard index. */
data class FluviDashboardDirectionalQuerySet(
    val income: FluviQueryScope,
    val expense: FluviQueryScope,
) {
    init {
        require(income.direction == LedgerDirection.income) {
            "Income dashboard filter must have income direction."
        }
        require(expense.direction == LedgerDirection.expense) {
            "Expense dashboard filter must have expense direction."
        }
    }

    fun scopeFor(direction: LedgerDirection): FluviQueryScope = when (direction) {
        LedgerDirection.income -> income
        LedgerDirection.expense -> expense
    }
}

data class FluviPeriodGroup(
    val key: String,
    val selections: Set<FluviPeriodSelection>,
) {
    init {
        require(key.isNotBlank()) { "A Fluvi Query time group needs a key." }
        require(selections.isNotEmpty()) { "A Fluvi Query time group cannot be empty." }
    }
}

data class FluviPeriodSelection(
    val kind: QueryPeriodKind,
    val value: String,
) {
    init {
        val valid = when (kind) {
            QueryPeriodKind.year -> YEAR.matches(value)
            QueryPeriodKind.month -> MONTH.matches(value)
            QueryPeriodKind.day -> DAY.matches(value)
        }
        require(valid) { "Invalid " + kind.name + " period value: " + value }
    }

    companion object {
        private val YEAR = Regex("[0-9]{4}")
        private val MONTH = Regex("[0-9]{4}-(0[1-9]|1[0-2])")

        fun year(value: String): FluviPeriodSelection =
            FluviPeriodSelection(QueryPeriodKind.year, value)

        fun month(value: String): FluviPeriodSelection =
            FluviPeriodSelection(QueryPeriodKind.month, value)

        fun day(value: String): FluviPeriodSelection =
            FluviPeriodSelection(QueryPeriodKind.day, value)

        private val DAY = Regex("[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])")
    }
}

data class FluviQueryRefinements(
    val minimumAmountScaled100: Long? = null,
    val maximumAmountScaled100: Long? = null,
    val noteContains: String? = null,
) {
    init {
        require(minimumAmountScaled100 == null || minimumAmountScaled100 >= 0L) {
            "Minimum amount cannot be negative."
        }
        require(maximumAmountScaled100 == null || maximumAmountScaled100 >= 0L) {
            "Maximum amount cannot be negative."
        }
        require(
            minimumAmountScaled100 == null || maximumAmountScaled100 == null ||
                minimumAmountScaled100 <= maximumAmountScaled100,
        ) {
            "Minimum amount cannot exceed maximum amount."
        }
    }
}

data class FluviTimelineCursor(
    val bookedLocalEpochDay: Long,
    val bookedLocalTimeMinutes: Int,
    val entryId: String,
)

data class FluviLedgerTimelinePage<T>(
    val entries: List<T>,
    val nextCursor: FluviTimelineCursor?,
)

data class FluviDashboardLedgerRow(
    val entryId: String,
    val direction: LedgerDirection,
    val amountMinor: Long,
    val bookedLocalEpochDay: Long,
    val bookedLocalTimeMinutes: Int,
    val occurredAtUtcMs: Long,
    val partnerId: String,
    val partnerDisplayName: String,
    val categoryId: String,
    val categoryDisplayName: String,
    val categoryColorId: String,
    val categoryIconId: String,
    val assignmentMode: CategoryAssignmentMode,
    val originKind: LedgerOriginKind,
    val note: String?,
)

data class FluviDashboardLedgerSlice(
    val queryKey: String,
    val coreRevision: Long,
    val direction: LedgerDirection,
    val timeScopeKey: String,
    val totalMinor: Long,
    val entryCount: Long,
    val entries: List<FluviDashboardLedgerRow>,
    val nextCursor: FluviTimelineCursor?,
)

/** Native phase metrics for one bounded committed vertical page. */
data class FluviCommittedDashboardPageRead(
    val slice: FluviDashboardLedgerSlice,
    val sqlDurationNanos: Long,
    val mappingDurationNanos: Long,
)

data class FluviLedgerTotal(
    val entryCount: Long,
    val amountScaled100: Long,
)

/** SQL-derived amount domain for a Query draft. It is never a UI-local scan. */
data class FluviQueryAmountDomain(
    val minimumAmountScaled100: Long,
    val maximumAmountScaled100: Long,
)

/** One category represented by the time-prefiltered ledger domain. */
data class FluviQueryFacetCategory(
    val id: String,
    val displayName: String,
    val colorId: String,
    val iconId: String,
    val entryCount: Long,
)

/** One partner with visual treatment inherited from its default category. */
data class FluviQueryFacetPartner(
    val id: String,
    val displayName: String,
    val categoryId: String,
    val categoryColorId: String,
    val categoryIconId: String,
    val entryCount: Long,
)

/** A month represented by real ledger data for the active direction. */
data class FluviQueryAvailableMonth(
    val year: Int,
    val month: Int,
)

/** Bounded, real data needed to open and edit the production Query sheet. */
data class FluviQueryMenuFacets(
    val result: FluviLedgerTotal,
    val amountDomain: FluviQueryAmountDomain,
    val availableMonths: List<FluviQueryAvailableMonth>,
    val categories: List<FluviQueryFacetCategory>,
    val partners: List<FluviQueryFacetPartner>,
)

data class FluviLedgerGroupedSummary(
    val id: String,
    val entryCount: Long,
    val amountScaled100: Long,
)

data class FluviTimePrefilteredFacets(
    val categoryIds: Set<String>,
    val partnerIds: Set<String>,
)

/** A named, direction-affine saved Query configuration, never a result set. */
data class FluviSavedQuery(
    val id: String,
    val name: String,
    val scope: FluviQueryScope,
    val createdAtUtcMs: Long,
    val updatedAtUtcMs: Long,
)
