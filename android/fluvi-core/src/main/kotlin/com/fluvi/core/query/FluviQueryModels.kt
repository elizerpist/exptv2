package com.fluvi.core.query

import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.QueryPeriodKind
import com.fluvi.core.model.QuerySnapshotSlot

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

data class FluviLedgerTotal(
    val entryCount: Long,
    val amountScaled100: Long,
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

data class FluviSavedQuerySnapshot(
    val id: String,
    val slot: QuerySnapshotSlot,
    val scope: FluviQueryScope,
)
