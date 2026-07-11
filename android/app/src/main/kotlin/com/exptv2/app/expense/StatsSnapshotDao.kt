package com.exptv2.app.expense

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction

@Dao
abstract class StatsSnapshotDao {
    @Query("SELECT * FROM stats_snapshots ORDER BY createdAt ASC, id ASC")
    protected abstract suspend fun listSnapshots(): List<StatsSnapshotEntity>

    @Query(
        "SELECT categoryId FROM stats_snapshot_categories " +
            "WHERE snapshotId = :snapshotId ORDER BY categoryId ASC",
    )
    protected abstract suspend fun categoryIds(snapshotId: String): List<Int>

    @Query(
        "SELECT vendorName FROM stats_snapshot_vendors " +
            "WHERE snapshotId = :snapshotId ORDER BY vendorName ASC",
    )
    protected abstract suspend fun vendorNames(snapshotId: String): List<String>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    protected abstract suspend fun insertSnapshot(snapshot: StatsSnapshotEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    protected abstract suspend fun insertCategories(rows: List<StatsSnapshotCategoryEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    protected abstract suspend fun insertVendors(rows: List<StatsSnapshotVendorEntity>)

    @Query("DELETE FROM stats_snapshot_categories WHERE snapshotId = :snapshotId")
    protected abstract suspend fun deleteCategories(snapshotId: String)

    @Query("DELETE FROM stats_snapshot_vendors WHERE snapshotId = :snapshotId")
    protected abstract suspend fun deleteVendors(snapshotId: String)

    @Transaction
    open suspend fun list(): List<StatsSnapshotRecord> = listSnapshots().map { snapshot ->
        StatsSnapshotRecord(
            snapshot = snapshot,
            categoryScopeIds = categoryIds(snapshot.id),
            vendorScopeNames = vendorNames(snapshot.id),
        )
    }

    @Transaction
    open suspend fun upsert(
        snapshot: StatsSnapshotEntity,
        categoryScopeIds: List<Int>,
        vendorScopeNames: List<String>,
    ) {
        deleteCategories(snapshot.id)
        deleteVendors(snapshot.id)
        insertSnapshot(snapshot)
        insertCategories(
            categoryScopeIds.distinct().sorted().map { categoryId ->
                StatsSnapshotCategoryEntity(snapshot.id, categoryId)
            },
        )
        insertVendors(
            vendorScopeNames
                .map(String::trim)
                .filter(String::isNotEmpty)
                .distinct()
                .sorted()
                .map { vendorName -> StatsSnapshotVendorEntity(snapshot.id, vendorName) },
        )
    }
}
