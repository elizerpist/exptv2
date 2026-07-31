package com.fluvi.core.repository

import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.entity.FluviQuerySnapshotCategoryEntity
import com.fluvi.core.database.entity.FluviQuerySnapshotEntity
import com.fluvi.core.database.entity.FluviQuerySnapshotPartnerEntity
import com.fluvi.core.database.entity.FluviQuerySnapshotPeriodEntity
import com.fluvi.core.database.entity.FluviQuerySnapshotRefinementEntity
import com.fluvi.core.model.QuerySnapshotSlot

internal class FluviQuerySnapshotRepository(
    private val database: FluviDatabase,
) {
    private val snapshots = database.querySnapshotDao()

    suspend fun insert(
        snapshot: FluviQuerySnapshotEntity,
        periods: List<FluviQuerySnapshotPeriodEntity>,
        categories: List<FluviQuerySnapshotCategoryEntity>,
        partners: List<FluviQuerySnapshotPartnerEntity>,
        refinements: List<FluviQuerySnapshotRefinementEntity>,
    ) {
        snapshots.insertSnapshot(snapshot)
        if (periods.isNotEmpty()) snapshots.insertPeriods(periods)
        if (categories.isNotEmpty()) snapshots.insertCategories(categories)
        if (partners.isNotEmpty()) snapshots.insertPartners(partners)
        if (refinements.isNotEmpty()) snapshots.insertRefinements(refinements)
    }

    suspend fun requireSnapshot(snapshotId: String): FluviQuerySnapshotEntity = requireNotNull(
        snapshots.findSnapshot(snapshotId),
    ) {
        "Unknown Fluvi Query snapshot ID: " + snapshotId
    }

    suspend fun requireSnapshot(slot: QuerySnapshotSlot): FluviQuerySnapshotEntity = requireNotNull(
        snapshots.findSnapshotBySlot(slot),
    ) {
        "No saved Fluvi Query exists in " + slot.name + "."
    }

    suspend fun deleteBySlotIfPresent(slot: QuerySnapshotSlot) {
        snapshots.deleteSnapshotBySlot(slot)
    }

    suspend fun periods(snapshotId: String): List<FluviQuerySnapshotPeriodEntity> =
        snapshots.periods(snapshotId)

    suspend fun categories(snapshotId: String): List<FluviQuerySnapshotCategoryEntity> =
        snapshots.categories(snapshotId)

    suspend fun partners(snapshotId: String): List<FluviQuerySnapshotPartnerEntity> =
        snapshots.partners(snapshotId)

    suspend fun refinements(snapshotId: String): List<FluviQuerySnapshotRefinementEntity> =
        snapshots.refinements(snapshotId)

    suspend fun delete(snapshotId: String) {
        check(snapshots.deleteSnapshot(snapshotId) == 1) {
            "Fluvi Query snapshot delete did not affect exactly one row."
        }
    }
}
