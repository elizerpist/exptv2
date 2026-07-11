package com.exptv2.app.expense

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index

@Entity(
    tableName = "stats_snapshots",
    primaryKeys = ["id"],
    indices = [Index(value = ["createdAt", "id"])],
)
data class StatsSnapshotEntity(
    val id: String,
    val name: String,
    val createdAt: Long,
    val updatedAt: Long,
    val includeCategoryScope: Boolean,
    val includeVendorScope: Boolean,
    val includeActiveType: Boolean,
    val includeThreshold: Boolean,
    val includeLayoutMode: Boolean,
    val includePageIndex: Boolean,
    val activeType: String?,
    val threshold: Double?,
    val layoutMode: String?,
    val activeYear: Int?,
    val activeMonth: Int?,
    val pageIndex: Int?,
) {
    fun toMap(
        categoryScopeIds: List<Int>,
        vendorScopeNames: List<String>,
    ): Map<String, Any?> = mapOf(
        "id" to id,
        "name" to name,
        "createdAt" to createdAt,
        "updatedAt" to updatedAt,
        "includeCategoryScope" to includeCategoryScope,
        "includeVendorScope" to includeVendorScope,
        "includeActiveType" to includeActiveType,
        "includeThreshold" to includeThreshold,
        "includeLayoutMode" to includeLayoutMode,
        "includePageIndex" to includePageIndex,
        "categoryScopeIds" to categoryScopeIds,
        "vendorScopeNames" to vendorScopeNames,
        "activeType" to activeType,
        "threshold" to threshold,
        "layoutMode" to layoutMode,
        "activeYear" to activeYear,
        "activeMonth" to activeMonth,
        "pageIndex" to pageIndex,
    )
}

@Entity(
    tableName = "stats_snapshot_categories",
    primaryKeys = ["snapshotId", "categoryId"],
    foreignKeys = [
        ForeignKey(
            entity = StatsSnapshotEntity::class,
            parentColumns = ["id"],
            childColumns = ["snapshotId"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [Index(value = ["snapshotId"])],
)
data class StatsSnapshotCategoryEntity(
    val snapshotId: String,
    val categoryId: Int,
)

@Entity(
    tableName = "stats_snapshot_vendors",
    primaryKeys = ["snapshotId", "vendorName"],
    foreignKeys = [
        ForeignKey(
            entity = StatsSnapshotEntity::class,
            parentColumns = ["id"],
            childColumns = ["snapshotId"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [Index(value = ["snapshotId"])],
)
data class StatsSnapshotVendorEntity(
    val snapshotId: String,
    val vendorName: String,
)

data class StatsSnapshotRecord(
    val snapshot: StatsSnapshotEntity,
    val categoryScopeIds: List<Int>,
    val vendorScopeNames: List<String>,
) {
    fun toMap(): Map<String, Any?> = snapshot.toMap(
        categoryScopeIds = categoryScopeIds,
        vendorScopeNames = vendorScopeNames,
    )
}
