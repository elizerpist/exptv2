package com.fluvi.core.repository

import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.entity.FluviQuerySnapshotCategoryEntity
import com.fluvi.core.database.entity.FluviQuerySnapshotEntity
import com.fluvi.core.database.entity.FluviQuerySnapshotPartnerEntity
import com.fluvi.core.database.entity.FluviQuerySnapshotPeriodEntity
import com.fluvi.core.database.entity.FluviQuerySnapshotRefinementEntity

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

    suspend fun allForDirection(direction: com.fluvi.core.model.LedgerDirection):
        List<FluviQuerySnapshotEntity> = snapshots.snapshotsForDirection(direction)

    suspend fun all(): List<FluviQuerySnapshotEntity> = snapshots.allSnapshots()

    suspend fun periods(snapshotId: String): List<FluviQuerySnapshotPeriodEntity> =
        snapshots.periods(snapshotId)

    suspend fun categories(snapshotId: String): List<FluviQuerySnapshotCategoryEntity> =
        snapshots.categories(snapshotId)

    suspend fun partners(snapshotId: String): List<FluviQuerySnapshotPartnerEntity> =
        snapshots.partners(snapshotId)

    suspend fun refinements(snapshotId: String): List<FluviQuerySnapshotRefinementEntity> =
        snapshots.refinements(snapshotId)

    suspend fun periodsForSnapshots(snapshotIds: List<String>):
        List<FluviQuerySnapshotPeriodEntity> =
        if (snapshotIds.isEmpty()) emptyList() else snapshots.periodsForSnapshots(snapshotIds)

    suspend fun categoriesForSnapshots(snapshotIds: List<String>):
        List<FluviQuerySnapshotCategoryEntity> =
        if (snapshotIds.isEmpty()) emptyList() else snapshots.categoriesForSnapshots(snapshotIds)

    suspend fun partnersForSnapshots(snapshotIds: List<String>):
        List<FluviQuerySnapshotPartnerEntity> =
        if (snapshotIds.isEmpty()) emptyList() else snapshots.partnersForSnapshots(snapshotIds)

    suspend fun refinementsForSnapshots(snapshotIds: List<String>):
        List<FluviQuerySnapshotRefinementEntity> =
        if (snapshotIds.isEmpty()) emptyList() else snapshots.refinementsForSnapshots(snapshotIds)

    suspend fun replaceConfiguration(
        snapshotId: String,
        name: String,
        scope: com.fluvi.core.query.FluviQueryScope,
        updatedAtUtcMs: Long,
        periods: List<FluviQuerySnapshotPeriodEntity>,
        categories: List<FluviQuerySnapshotCategoryEntity>,
        partners: List<FluviQuerySnapshotPartnerEntity>,
        refinements: List<FluviQuerySnapshotRefinementEntity>,
    ) {
        check(
            snapshots.updateSnapshotMetadata(
                snapshotId = snapshotId,
                name = name,
                direction = scope.direction,
                updatedAtUtcMs = updatedAtUtcMs,
            ) == 1,
        ) { "Unknown Fluvi saved Query ID: $snapshotId" }
        snapshots.deletePeriods(snapshotId)
        snapshots.deleteCategories(snapshotId)
        snapshots.deletePartners(snapshotId)
        snapshots.deleteRefinements(snapshotId)
        if (periods.isNotEmpty()) snapshots.insertPeriods(periods)
        if (categories.isNotEmpty()) snapshots.insertCategories(categories)
        if (partners.isNotEmpty()) snapshots.insertPartners(partners)
        if (refinements.isNotEmpty()) snapshots.insertRefinements(refinements)
    }

    suspend fun rename(
        snapshotId: String,
        name: String,
        updatedAtUtcMs: Long,
    ) {
        check(snapshots.renameSnapshot(snapshotId, name, updatedAtUtcMs) == 1) {
            "Unknown Fluvi saved Query ID: $snapshotId"
        }
    }

    suspend fun delete(snapshotId: String) {
        check(snapshots.deleteSnapshot(snapshotId) == 1) {
            "Fluvi Query snapshot delete did not affect exactly one row."
        }
    }
}
