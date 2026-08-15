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
    /**
     * Exact raw rows of each already-filtered directional base scope.
     *
     * This is intentionally distinct from [rows], which remains the bounded
     * preview-frame table. Presentation uses this semantic membership only to
     * derive an ephemeral Category/Partner focus without a new Room read.
     */
    val focusRows: List<FluviDashboardLedgerRow> = emptyList(),
    val frames: List<FluviPreparedDashboardIndexFrame>,
    val verticalGeometryBuckets: List<FluviPreparedDashboardGeometryDayBucket>,
    val buildMetrics: FluviPreparedDashboardIndexBuildMetrics,
) {
    init {
        require(coreRevision > 0L)
        require(previewPageSize in 1..200)
        require(requestGeneration > 0L)
        require(rows.map { it.entryId }.distinct().size == rows.size)
        require(focusRows.map { it.entryId }.distinct().size == focusRows.size)
        require(frames.map { it.queryKey }.distinct().size == frames.size)
        require(frames.all { frame ->
            frame.rowIndices.all { it in rows.indices }
        })
        require(verticalGeometryBuckets.all { it.entryCount > 0L })
        require(verticalGeometryBuckets
            .groupBy { it.direction }
            .values
            .all { buckets ->
                buckets.zipWithNext().all { (previous, next) ->
                    previous.bookedLocalEpochDay > next.bookedLocalEpochDay
                }
            }
        )
    }
}

/**
 * Compact count-only vertical geometry seed. It is derived from the prepared
 * dashboard's existing daily aggregate query, never from full row payloads.
 */
data class FluviPreparedDashboardGeometryDayBucket(
    val direction: LedgerDirection,
    val bookedLocalEpochDay: Long,
    val entryCount: Long,
)

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
