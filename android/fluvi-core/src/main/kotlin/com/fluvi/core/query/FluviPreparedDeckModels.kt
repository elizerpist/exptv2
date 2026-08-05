package com.fluvi.core.query

import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.QueryPeriodKind

data class FluviPreparedYearWindow(
    val startYear: Int,
    val endYearInclusive: Int,
) {
    init {
        require(startYear in 1..9999)
        require(endYearInclusive in startYear..9999)
        require(endYearInclusive - startYear <= 100) { "Prepared year window is too large." }
    }

    val values: List<String>
        get() = (startYear..endYearInclusive).map(Int::toString)
}

data class FluviPreparedDeck(
    val parentQueryKey: String,
    val direction: LedgerDirection,
    val childPeriodKind: QueryPeriodKind,
    val coreRevision: Long,
    val previewPageSize: Int,
    val requestGeneration: Long,
    val parentSlice: FluviDashboardLedgerSlice,
    val children: List<FluviDashboardChildPreview>,
    val buildMetrics: FluviPreparedDeckBuildMetrics,
) {
    init {
        require(coreRevision > 0L) { "A prepared deck requires a seeded revision." }
        require(parentSlice.queryKey == parentQueryKey)
        require(parentSlice.coreRevision == coreRevision)
        require(children.all { it.slice.coreRevision == coreRevision })
    }
}

data class FluviPreparedDeckBuildMetrics(
    val sqlCallCount: Int,
    val aggregateBucketCount: Int,
    val scannedLedgerRowCount: Int,
    val materializedPreviewRowCount: Int,
    val queryDurationNanos: Long,
    val mappingDurationNanos: Long,
)
