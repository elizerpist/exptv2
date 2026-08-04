package com.fluvi.core.query

import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.QueryPeriodKind
import com.fluvi.core.model.QuerySnapshotSlot
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

data class FluviLedgerTotal(
    val entryCount: Long,
    val amountScaled100: Long,
)

data class FluviLedgerGroupedSummary(
    val id: String,
    val entryCount: Long,
    val amountScaled100: Long,
)

data class FluviDashboardTimeChildSummary(
    val childPeriodValue: String,
    val childQueryKey: String,
    val totalMinor: Long,
    val entryCount: Long,
)

data class FluviDashboardTimeChildSummaryIndex(
    val parentQueryKey: String,
    val direction: LedgerDirection,
    val childPeriodKind: QueryPeriodKind,
    val coreRevision: Long,
    val isComplete: Boolean,
    val values: List<FluviDashboardTimeChildSummary>,
)

data class FluviDashboardChildPreview(
    val childPeriodValue: String,
    val slice: FluviDashboardLedgerSlice,
)

data class FluviDashboardChildPreviewBundle(
    val parentQueryKey: String,
    val direction: LedgerDirection,
    val childPeriodKind: QueryPeriodKind,
    val coreRevision: Long,
    val previewPageSize: Int,
    val children: List<FluviDashboardChildPreview>,
    val buildMetrics: FluviDashboardChildPreviewBuildMetrics,
)

/**
 * Native build evidence. Materialized rows include the one-row keyset
 * lookahead, so the hard upper bound is children * (pageSize + 1).
 */
data class FluviDashboardChildPreviewBuildMetrics(
    val aggregateBucketCount: Int,
    val materializedPreviewRowCount: Int,
    val queryDurationNanos: Long,
    val mappingDurationNanos: Long,
)

data class FluviTimePrefilteredFacets(
    val categoryIds: Set<String>,
    val partnerIds: Set<String>,
)

data class FluviSavedQuerySnapshot(
    val id: String,
    val slot: QuerySnapshotSlot,
    val scope: FluviQueryScope,
)
