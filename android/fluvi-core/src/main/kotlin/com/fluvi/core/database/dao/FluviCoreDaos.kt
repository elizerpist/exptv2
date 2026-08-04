package com.fluvi.core.database.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.RawQuery
import androidx.sqlite.db.SupportSQLiteQuery
import com.fluvi.core.database.entity.FluviCategoryEntity
import com.fluvi.core.database.entity.FluviAppSettingsEntity
import com.fluvi.core.database.entity.FluviLedgerBackupCheckpointEntity
import com.fluvi.core.database.entity.FluviLedgerDeletionArchiveEntity
import com.fluvi.core.database.entity.FluviLedgerEntryEntity
import com.fluvi.core.database.entity.FluviLedgerSyncOutboxEntity
import com.fluvi.core.database.entity.FluviLedgerSyncWorkspaceEntity
import com.fluvi.core.database.entity.FluviPartnerAliasEntity
import com.fluvi.core.database.entity.FluviPartnerEntity
import com.fluvi.core.model.CategoryAssignmentMode
import com.fluvi.core.model.LedgerSyncOperation
import com.fluvi.core.model.CheckpointStatus
import com.fluvi.core.model.QuerySnapshotSlot
import kotlinx.coroutines.flow.Flow

@Dao
internal interface FluviAppSettingsDao {
    @Query("SELECT * FROM fluvi_app_settings LIMIT 1")
    suspend fun current(): FluviAppSettingsEntity?

    @Query("SELECT core_revision FROM fluvi_app_settings LIMIT 1")
    fun observeCoreRevision(): Flow<Long>

    @Query(
        "UPDATE fluvi_app_settings SET core_revision = core_revision + 1, " +
            "updated_at_utc_ms = :updatedAtUtcMs WHERE id = :settingsId",
    )
    suspend fun incrementCoreRevision(settingsId: String, updatedAtUtcMs: Long): Int

    @Query(
        "UPDATE fluvi_app_settings SET demo_seed_version = :version, " +
            "demo_seed_completed_at_utc_ms = :completedAtUtcMs, " +
            "updated_at_utc_ms = :updatedAtUtcMs WHERE id = :settingsId",
    )
    suspend fun markDemoSeedCompleted(
        settingsId: String,
        version: Int,
        completedAtUtcMs: Long,
        updatedAtUtcMs: Long,
    ): Int

    @Query(
        "UPDATE fluvi_app_settings SET demo_seed_version = NULL, " +
            "demo_seed_completed_at_utc_ms = NULL, updated_at_utc_ms = :updatedAtUtcMs " +
            "WHERE id = :settingsId",
    )
    suspend fun clearDemoSeedMetadata(settingsId: String, updatedAtUtcMs: Long): Int
}

@Dao
internal interface FluviCategoryDao {
    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(category: FluviCategoryEntity)

    @Query("SELECT * FROM fluvi_categories WHERE id = :categoryId LIMIT 1")
    suspend fun findById(categoryId: String): FluviCategoryEntity?

    @Query(
        "SELECT * FROM fluvi_categories " +
            "ORDER BY is_system_uncategorized DESC, name COLLATE NOCASE ASC, id ASC",
    )
    suspend fun allCategories(): List<FluviCategoryEntity>

    @Query(
        "SELECT * FROM fluvi_categories " +
            "WHERE is_system_uncategorized = 1 LIMIT 1",
    )
    suspend fun systemUncategorized(): FluviCategoryEntity?

    @Query("DELETE FROM fluvi_categories WHERE id = :categoryId")
    suspend fun delete(categoryId: String)

    @Query("DELETE FROM fluvi_categories WHERE id IN (:categoryIds)")
    suspend fun deleteAll(categoryIds: List<String>): Int

    @Query(
        "UPDATE fluvi_categories SET name = :name, color_id = :colorId, icon_id = :iconId, " +
            "updated_at_utc_ms = :updatedAtUtcMs WHERE id = :categoryId",
    )
    suspend fun update(
        categoryId: String,
        name: String,
        colorId: String,
        iconId: String,
        updatedAtUtcMs: Long,
    ): Int
}

@Dao
internal interface FluviPartnerDao {
    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(partner: FluviPartnerEntity)

    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insertAlias(alias: FluviPartnerAliasEntity)

    @Query("SELECT * FROM fluvi_partners WHERE id = :partnerId LIMIT 1")
    suspend fun findById(partnerId: String): FluviPartnerEntity?

    @Query("SELECT * FROM fluvi_partners")
    suspend fun allPartners(): List<FluviPartnerEntity>

    @Query(
        """
        SELECT partners.*
        FROM fluvi_partner_aliases AS aliases
        INNER JOIN fluvi_partners AS partners ON partners.id = aliases.partner_id
        WHERE aliases.normalized_alias = :normalizedAlias
        LIMIT 1
        """,
    )
    suspend fun findByNormalizedAlias(normalizedAlias: String): FluviPartnerEntity?

    @Query(
        "UPDATE fluvi_partners " +
            "SET default_category_id = :categoryId, updated_at_utc_ms = :updatedAtUtcMs " +
            "WHERE id = :partnerId",
    )
    suspend fun changeDefaultCategory(
        partnerId: String,
        categoryId: String,
        updatedAtUtcMs: Long,
    ): Int

    @Query(
        "UPDATE fluvi_partners " +
            "SET display_name_override = :displayNameOverride, updated_at_utc_ms = :updatedAtUtcMs " +
            "WHERE id = :partnerId",
    )
    suspend fun setDisplayNameOverride(
        partnerId: String,
        displayNameOverride: String?,
        updatedAtUtcMs: Long,
    ): Int

    @Query(
        "UPDATE fluvi_partners " +
            "SET merged_into_partner_id = :recipientId, updated_at_utc_ms = :updatedAtUtcMs " +
            "WHERE id = :donorId",
    )
    suspend fun setMergeTarget(
        donorId: String,
        recipientId: String?,
        updatedAtUtcMs: Long,
    ): Int

    @Query(
        "UPDATE fluvi_partners " +
            "SET default_category_id = :toCategoryId, updated_at_utc_ms = :updatedAtUtcMs " +
            "WHERE default_category_id = :fromCategoryId",
    )
    suspend fun retargetDefaultCategories(
        fromCategoryId: String,
        toCategoryId: String,
        updatedAtUtcMs: Long,
    ): Int

    @Query("DELETE FROM fluvi_partner_aliases WHERE partner_id IN (:partnerIds)")
    suspend fun deleteAliases(partnerIds: List<String>): Int

    @Query("DELETE FROM fluvi_partners WHERE id IN (:partnerIds)")
    suspend fun deleteAll(partnerIds: List<String>): Int
}

@Dao
internal interface FluviLedgerDao {
    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(entry: FluviLedgerEntryEntity)

    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insertAll(entries: List<FluviLedgerEntryEntity>)

    @Query("SELECT * FROM fluvi_ledger_entries WHERE id = :entryId LIMIT 1")
    suspend fun findById(entryId: String): FluviLedgerEntryEntity?

    @Query("SELECT COUNT(*) FROM fluvi_ledger_entries")
    suspend fun queryEntriesCount(): Long

    @Query(
        "SELECT * FROM fluvi_ledger_entries " +
            "WHERE partner_id = :partnerId AND category_assignment_mode = :mode",
    )
    suspend fun entriesByPartnerAndMode(
        partnerId: String,
        mode: CategoryAssignmentMode,
    ): List<FluviLedgerEntryEntity>

    @Query("SELECT * FROM fluvi_ledger_entries WHERE category_id = :categoryId")
    suspend fun entriesByCategory(categoryId: String): List<FluviLedgerEntryEntity>

    @Query("SELECT * FROM fluvi_ledger_entries WHERE partner_id IN (:partnerIds)")
    suspend fun entriesByPartnerIds(partnerIds: List<String>): List<FluviLedgerEntryEntity>

    @Query(
        "UPDATE fluvi_ledger_entries " +
            "SET category_id = :categoryId, updated_at_utc_ms = :updatedAtUtcMs, revision = revision + 1 " +
            "WHERE partner_id IN (:partnerIds) AND category_assignment_mode = :mode",
    )
    suspend fun retargetInheritedPartnerEntries(
        partnerIds: List<String>,
        categoryId: String,
        mode: CategoryAssignmentMode,
        updatedAtUtcMs: Long,
    ): Int

    @Query(
        "UPDATE fluvi_ledger_entries " +
            "SET category_id = :toCategoryId, updated_at_utc_ms = :updatedAtUtcMs, revision = revision + 1 " +
            "WHERE category_id = :fromCategoryId",
    )
    suspend fun retargetCategory(
        fromCategoryId: String,
        toCategoryId: String,
        updatedAtUtcMs: Long,
    ): Int

    @Query(
        "UPDATE fluvi_ledger_entries " +
            "SET amount_scaled_100 = :amountScaled100, updated_at_utc_ms = :updatedAtUtcMs, " +
            "revision = revision + 1 WHERE id = :entryId",
    )
    suspend fun updateAmount(
        entryId: String,
        amountScaled100: Long,
        updatedAtUtcMs: Long,
    ): Int

    @Query(
        "UPDATE fluvi_ledger_entries " +
            "SET category_id = :categoryId, category_assignment_mode = :mode, " +
            "updated_at_utc_ms = :updatedAtUtcMs, revision = revision + 1 " +
            "WHERE id = :entryId",
    )
    suspend fun updateCategory(
        entryId: String,
        categoryId: String,
        mode: CategoryAssignmentMode,
        updatedAtUtcMs: Long,
    ): Int

    @Query("DELETE FROM fluvi_ledger_entries WHERE id = :entryId")
    suspend fun delete(entryId: String): Int

    @Query("DELETE FROM fluvi_ledger_entries WHERE id IN (:entryIds)")
    suspend fun deleteAll(entryIds: List<String>): Int

    @RawQuery(observedEntities = [FluviLedgerEntryEntity::class])
    suspend fun queryEntries(query: SupportSQLiteQuery): List<FluviLedgerEntryEntity>

    @RawQuery(observedEntities = [FluviLedgerEntryEntity::class])
    suspend fun queryAggregate(query: SupportSQLiteQuery): FluviLedgerAggregateRow

    @RawQuery(observedEntities = [FluviLedgerEntryEntity::class])
    suspend fun queryAggregateBuckets(
        query: SupportSQLiteQuery,
    ): List<FluviLedgerAggregateBucketRow>

    @RawQuery(observedEntities = [FluviLedgerEntryEntity::class])
    suspend fun queryStringIds(query: SupportSQLiteQuery): List<FluviStringIdRow>
}

@Dao
internal interface FluviLedgerDeletionArchiveDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(archive: FluviLedgerDeletionArchiveEntity)

    @Query(
        "SELECT * FROM fluvi_ledger_deletion_archive " +
            "WHERE entry_id = :entryId LIMIT 1",
    )
    suspend fun findByEntryId(entryId: String): FluviLedgerDeletionArchiveEntity?

    @Query(
        "DELETE FROM fluvi_ledger_deletion_archive " +
            "WHERE required_checkpoint_id = :checkpointId",
    )
    suspend fun purgeForAcknowledgedCheckpoint(checkpointId: String): Int
}

@Dao
internal interface FluviLedgerBackupCheckpointDao {
    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(checkpoint: FluviLedgerBackupCheckpointEntity)

    @Query("SELECT * FROM fluvi_ledger_backup_checkpoints WHERE id = :checkpointId LIMIT 1")
    suspend fun findById(checkpointId: String): FluviLedgerBackupCheckpointEntity?

    @Query(
        "SELECT * FROM fluvi_ledger_backup_checkpoints WHERE trigger_key = :triggerKey LIMIT 1",
    )
    suspend fun findByTriggerKey(triggerKey: String): FluviLedgerBackupCheckpointEntity?

    @Query(
        "UPDATE fluvi_ledger_backup_checkpoints SET prepared_bundle_path = :preparedBundlePath, " +
            "updated_at_utc_ms = :updatedAtUtcMs WHERE id = :checkpointId",
    )
    suspend fun setPreparedBundlePath(
        checkpointId: String,
        preparedBundlePath: String,
        updatedAtUtcMs: Long,
    ): Int

    @Query(
        "UPDATE fluvi_ledger_backup_checkpoints SET status = :status, " +
            "remote_backup_file_id = :remoteBackupFileId, updated_at_utc_ms = :updatedAtUtcMs " +
            "WHERE id = :checkpointId",
    )
    suspend fun updateStatus(
        checkpointId: String,
        status: CheckpointStatus,
        remoteBackupFileId: String?,
        updatedAtUtcMs: Long,
    ): Int
}

@Dao
internal interface FluviLedgerSyncOutboxDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(operation: FluviLedgerSyncOutboxEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAll(operations: List<FluviLedgerSyncOutboxEntity>)

    @Query(
        "SELECT * FROM fluvi_ledger_sync_outbox " +
            "WHERE entry_id = :entryId LIMIT 1",
    )
    suspend fun pendingFor(entryId: String): FluviLedgerSyncOutboxEntity?

    @Query("DELETE FROM fluvi_ledger_sync_outbox WHERE entry_id = :entryId")
    suspend fun acknowledge(entryId: String): Int

    @Query("DELETE FROM fluvi_ledger_sync_outbox WHERE entry_id IN (:entryIds)")
    suspend fun deleteAll(entryIds: List<String>): Int

    @Query(
        "SELECT * FROM fluvi_ledger_sync_outbox " +
            "WHERE operation = :operation ORDER BY updated_at_utc_ms ASC LIMIT :limit",
    )
    suspend fun pendingByOperation(
        operation: LedgerSyncOperation,
        limit: Int,
    ): List<FluviLedgerSyncOutboxEntity>
}

@Dao
internal interface FluviLedgerSyncWorkspaceDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(workspace: FluviLedgerSyncWorkspaceEntity)

    @Query("SELECT * FROM fluvi_ledger_sync_workspaces WHERE booking_year = :bookingYear LIMIT 1")
    suspend fun findByBookingYear(bookingYear: Int): FluviLedgerSyncWorkspaceEntity?
}

@Dao
internal interface FluviFutureReferenceDao {
    @Query(
        "UPDATE fluvi_recurrence_rules " +
            "SET category_id = :categoryId, updated_at_utc_ms = :updatedAtUtcMs " +
            "WHERE partner_id IN (:partnerIds) AND category_assignment_mode = :mode",
    )
    suspend fun retargetInheritedRecurrenceRules(
        partnerIds: List<String>,
        categoryId: String,
        mode: CategoryAssignmentMode,
        updatedAtUtcMs: Long,
    ): Int

    @Query(
        "UPDATE fluvi_recurrence_rules " +
            "SET category_id = :toCategoryId, updated_at_utc_ms = :updatedAtUtcMs " +
            "WHERE category_id = :fromCategoryId",
    )
    suspend fun retargetRecurrenceCategories(
        fromCategoryId: String,
        toCategoryId: String,
        updatedAtUtcMs: Long,
    ): Int

    @Query(
        "UPDATE fluvi_occurrence_overrides " +
            "SET category_id = :toCategoryId, updated_at_utc_ms = :updatedAtUtcMs " +
            "WHERE category_id = :fromCategoryId",
    )
    suspend fun retargetOccurrenceOverrideCategories(
        fromCategoryId: String,
        toCategoryId: String,
        updatedAtUtcMs: Long,
    ): Int
}

@Dao
internal interface FluviQuerySnapshotDao {
    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insertSnapshot(snapshot: com.fluvi.core.database.entity.FluviQuerySnapshotEntity)

    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insertPeriods(periods: List<com.fluvi.core.database.entity.FluviQuerySnapshotPeriodEntity>)

    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insertCategories(categories: List<com.fluvi.core.database.entity.FluviQuerySnapshotCategoryEntity>)

    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insertPartners(partners: List<com.fluvi.core.database.entity.FluviQuerySnapshotPartnerEntity>)

    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insertRefinements(refinements: List<com.fluvi.core.database.entity.FluviQuerySnapshotRefinementEntity>)

    @Query("SELECT * FROM fluvi_query_snapshots WHERE id = :snapshotId LIMIT 1")
    suspend fun findSnapshot(snapshotId: String): com.fluvi.core.database.entity.FluviQuerySnapshotEntity?

    @Query("SELECT * FROM fluvi_query_snapshots WHERE slot = :slot LIMIT 1")
    suspend fun findSnapshotBySlot(
        slot: QuerySnapshotSlot,
    ): com.fluvi.core.database.entity.FluviQuerySnapshotEntity?

    @Query("SELECT * FROM fluvi_query_snapshots ORDER BY created_at_utc_ms ASC, id ASC")
    suspend fun allSnapshots(): List<com.fluvi.core.database.entity.FluviQuerySnapshotEntity>

    @Query("SELECT * FROM fluvi_query_snapshot_periods WHERE snapshot_id = :snapshotId")
    suspend fun periods(snapshotId: String): List<com.fluvi.core.database.entity.FluviQuerySnapshotPeriodEntity>

    @Query("SELECT * FROM fluvi_query_snapshot_categories WHERE snapshot_id = :snapshotId")
    suspend fun categories(snapshotId: String): List<com.fluvi.core.database.entity.FluviQuerySnapshotCategoryEntity>

    @Query("SELECT * FROM fluvi_query_snapshot_partners WHERE snapshot_id = :snapshotId")
    suspend fun partners(snapshotId: String): List<com.fluvi.core.database.entity.FluviQuerySnapshotPartnerEntity>

    @Query("SELECT * FROM fluvi_query_snapshot_refinements WHERE snapshot_id = :snapshotId")
    suspend fun refinements(snapshotId: String): List<com.fluvi.core.database.entity.FluviQuerySnapshotRefinementEntity>

    @Query("DELETE FROM fluvi_query_snapshots WHERE id = :snapshotId")
    suspend fun deleteSnapshot(snapshotId: String): Int

    @Query("DELETE FROM fluvi_query_snapshots WHERE slot = :slot")
    suspend fun deleteSnapshotBySlot(slot: QuerySnapshotSlot): Int

    @Query(
        "DELETE FROM fluvi_query_snapshot_categories " +
            "WHERE category_id = :targetCategoryId AND snapshot_id IN (" +
            "SELECT snapshot_id FROM fluvi_query_snapshot_categories " +
            "WHERE category_id = :sourceCategoryId)",
    )
    suspend fun removeTargetCategoryFiltersThatWouldCollide(
        sourceCategoryId: String,
        targetCategoryId: String,
    ): Int

    @Query(
        "UPDATE fluvi_query_snapshot_categories " +
            "SET category_id = :toCategoryId " +
            "WHERE category_id = :fromCategoryId",
    )
    suspend fun retargetCategoryFilters(
        fromCategoryId: String,
        toCategoryId: String,
    ): Int
}
