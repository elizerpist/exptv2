package com.fluvi.core.query

import com.fluvi.core.model.LedgerDirection

data class FluviPreparedYearWindow(
    val startYear: Int,
    val endYearInclusive: Int,
) {
    init {
        require(startYear in 1..9999)
        require(endYearInclusive in startYear..9999)
        require(endYearInclusive - startYear <= 100) {
            "Prepared year window is too large."
        }
    }
}

data class FluviPreparedDashboardIndex(
    val coreRevision: Long,
    val previewPageSize: Int,
    val requestGeneration: Long,
    val yearWindow: FluviPreparedYearWindow,
    val rows: List<FluviDashboardLedgerRow>,
    val frames: List<FluviPreparedDashboardIndexFrame>,
    val buildMetrics: FluviPreparedDashboardIndexBuildMetrics,
) {
    init {
        require(coreRevision > 0L)
        require(previewPageSize in 1..200)
        require(requestGeneration > 0L)
        require(rows.map { it.entryId }.distinct().size == rows.size)
        require(frames.map { it.queryKey }.distinct().size == frames.size)
        require(frames.all { frame ->
            frame.rowIndices.all { it in rows.indices }
        })
    }
}

data class FluviPreparedDashboardIndexFrame(
    val queryKey: String,
    val direction: LedgerDirection,
    val timeScopeKey: String,
    val totalMinor: Long,
    val entryCount: Long,
    val rowIndices: List<Int>,
    val nextCursor: FluviTimelineCursor?,
)

data class FluviPreparedDashboardIndexBuildMetrics(
    val sqlCallCount: Int,
    val sqlDurationNanos: Long,
    val aggregateBucketCount: Int,
    val scannedLedgerRowCount: Int,
    val uniquePreviewRowCount: Int,
    val frameCount: Int,
    val queryDurationNanos: Long,
    val aggregationDurationNanos: Long,
    val mappingDurationNanos: Long,
)
