package com.fluvi.core.database.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import com.fluvi.core.model.CategoryAssignmentMode
import com.fluvi.core.model.CheckpointKind
import com.fluvi.core.model.CheckpointRetentionClass
import com.fluvi.core.model.CheckpointStatus
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.LedgerOriginKind
import com.fluvi.core.model.LedgerSyncOperation
import com.fluvi.core.model.QueryPeriodKind
import com.fluvi.core.model.QueryRefinementKind
import com.fluvi.core.model.QuerySnapshotSlot

internal const val FLUVI_LEDGER_CHRONOLOGICAL_INDEX =
    "index_fluvi_ledger_entries_direction_booked_local_epoch_day_booked_local_time_minutes_id"
internal const val FLUVI_LEDGER_DASHBOARD_PREVIEW_INDEX =
    "index_fluvi_ledger_entries_dashboard_preview"

@Entity(tableName = "fluvi_app_settings")
data class FluviAppSettingsEntity(
    @PrimaryKey
    @ColumnInfo(name = "id")
    val id: String,
    @ColumnInfo(name = "currency_code")
    val currencyCode: String,
    @ColumnInfo(name = "local_zone_id")
    val localZoneId: String,
    @ColumnInfo(name = "core_revision")
    val coreRevision: Long,
    @ColumnInfo(name = "created_at_utc_ms")
    val createdAtUtcMs: Long,
    @ColumnInfo(name = "updated_at_utc_ms")
    val updatedAtUtcMs: Long,
    @ColumnInfo(name = "demo_seed_version")
    val demoSeedVersion: Int?,
    @ColumnInfo(name = "demo_seed_completed_at_utc_ms")
    val demoSeedCompletedAtUtcMs: Long?,
)

@Entity(
    tableName = "fluvi_categories",
    indices = [
        Index(value = ["name"]),
    ],
)
data class FluviCategoryEntity(
    @PrimaryKey
    @ColumnInfo(name = "id")
    val id: String,
    @ColumnInfo(name = "name")
    val name: String,
    @ColumnInfo(name = "color_id")
    val colorId: String,
    @ColumnInfo(name = "icon_id")
    val iconId: String,
    @ColumnInfo(name = "is_system_uncategorized")
    val isSystemUncategorized: Boolean,
    @ColumnInfo(name = "created_at_utc_ms")
    val createdAtUtcMs: Long,
    @ColumnInfo(name = "updated_at_utc_ms")
    val updatedAtUtcMs: Long,
)

@Entity(
    tableName = "fluvi_partners",
    foreignKeys = [
        ForeignKey(
            entity = FluviCategoryEntity::class,
            parentColumns = ["id"],
            childColumns = ["default_category_id"],
            onDelete = ForeignKey.NO_ACTION,
        ),
        ForeignKey(
            entity = FluviPartnerEntity::class,
            parentColumns = ["id"],
            childColumns = ["merged_into_partner_id"],
            onDelete = ForeignKey.SET_NULL,
        ),
    ],
    indices = [
        Index(value = ["default_category_id"]),
        Index(value = ["merged_into_partner_id"]),
    ],
)
data class FluviPartnerEntity(
    @PrimaryKey
    @ColumnInfo(name = "id")
    val id: String,
    @ColumnInfo(name = "original_name")
    val originalName: String,
    @ColumnInfo(name = "display_name_override")
    val displayNameOverride: String?,
    @ColumnInfo(name = "default_category_id")
    val defaultCategoryId: String,
    @ColumnInfo(name = "merged_into_partner_id")
    val mergedIntoPartnerId: String?,
    @ColumnInfo(name = "created_at_utc_ms")
    val createdAtUtcMs: Long,
    @ColumnInfo(name = "updated_at_utc_ms")
    val updatedAtUtcMs: Long,
)

@Entity(
    tableName = "fluvi_partner_aliases",
    foreignKeys = [
        ForeignKey(
            entity = FluviPartnerEntity::class,
            parentColumns = ["id"],
            childColumns = ["partner_id"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [
        Index(value = ["partner_id"]),
        Index(value = ["normalized_alias"], unique = true),
    ],
)
data class FluviPartnerAliasEntity(
    @PrimaryKey
    @ColumnInfo(name = "id")
    val id: String,
    @ColumnInfo(name = "partner_id")
    val partnerId: String,
    @ColumnInfo(name = "normalized_alias")
    val normalizedAlias: String,
    @ColumnInfo(name = "source_name")
    val sourceName: String,
    @ColumnInfo(name = "created_at_utc_ms")
    val createdAtUtcMs: Long,
    @ColumnInfo(name = "updated_at_utc_ms")
    val updatedAtUtcMs: Long,
)

@Entity(
    tableName = "fluvi_ledger_entries",
    foreignKeys = [
        ForeignKey(
            entity = FluviPartnerEntity::class,
            parentColumns = ["id"],
            childColumns = ["partner_id"],
            onDelete = ForeignKey.NO_ACTION,
        ),
        ForeignKey(
            entity = FluviCategoryEntity::class,
            parentColumns = ["id"],
            childColumns = ["category_id"],
            onDelete = ForeignKey.NO_ACTION,
        ),
        ForeignKey(
            entity = FluviNotificationInboxEntity::class,
            parentColumns = ["id"],
            childColumns = ["notification_inbox_id"],
            onDelete = ForeignKey.SET_NULL,
        ),
    ],
    indices = [
        Index(value = ["booked_local_epoch_day", "booked_local_time_minutes", "id"]),
        Index(
            name = FLUVI_LEDGER_CHRONOLOGICAL_INDEX,
            value = [
                "direction",
                "booked_local_epoch_day",
                "booked_local_time_minutes",
                "id",
            ],
        ),
        Index(
            name = FLUVI_LEDGER_DASHBOARD_PREVIEW_INDEX,
            value = [
                "direction",
                "booked_local_epoch_day",
                "booked_local_time_minutes",
                "id",
            ],
            orders = [
                Index.Order.ASC,
                Index.Order.DESC,
                Index.Order.DESC,
                Index.Order.DESC,
            ],
        ),
        Index(
            value = [
                "category_id",
                "booked_local_epoch_day",
                "booked_local_time_minutes",
                "id",
            ],
        ),
        Index(
            value = [
                "partner_id",
                "booked_local_epoch_day",
                "booked_local_time_minutes",
                "id",
            ],
        ),
        Index(value = ["notification_inbox_id"]),
    ],
)
data class FluviLedgerEntryEntity(
    @PrimaryKey
    @ColumnInfo(name = "id")
    val id: String,
    @ColumnInfo(name = "partner_id")
    val partnerId: String,
    @ColumnInfo(name = "category_id")
    val categoryId: String,
    @ColumnInfo(name = "category_assignment_mode")
    val categoryAssignmentMode: CategoryAssignmentMode,
    @ColumnInfo(name = "note")
    val note: String?,
    @ColumnInfo(name = "direction")
    val direction: LedgerDirection,
    @ColumnInfo(name = "amount_scaled_100")
    val amountScaled100: Long,
    @ColumnInfo(name = "booked_local_epoch_day")
    val bookedLocalEpochDay: Long,
    @ColumnInfo(name = "booked_local_time_minutes")
    val bookedLocalTimeMinutes: Int,
    @ColumnInfo(name = "occurred_at_utc_ms")
    val occurredAtUtcMs: Long,
    @ColumnInfo(name = "origin_kind")
    val originKind: LedgerOriginKind,
    @ColumnInfo(name = "notification_inbox_id")
    val notificationInboxId: String?,
    @ColumnInfo(name = "created_at_utc_ms")
    val createdAtUtcMs: Long,
    @ColumnInfo(name = "updated_at_utc_ms")
    val updatedAtUtcMs: Long,
    @ColumnInfo(name = "revision")
    val revision: Long,
)

@Entity(
    tableName = "fluvi_ledger_deletion_archive",
    indices = [
        Index(value = ["required_checkpoint_id"]),
        Index(value = ["deleted_at_utc_ms"]),
    ],
)
data class FluviLedgerDeletionArchiveEntity(
    @PrimaryKey
    @ColumnInfo(name = "entry_id")
    val entryId: String,
    @ColumnInfo(name = "ledger_sheet_row_payload")
    val ledgerSheetRowPayload: String,
    @ColumnInfo(name = "deleted_at_utc_ms")
    val deletedAtUtcMs: Long,
    @ColumnInfo(name = "required_checkpoint_id")
    val requiredCheckpointId: String?,
)

@Entity(
    tableName = "fluvi_query_snapshots",
    indices = [
        Index(value = ["slot"], unique = true),
    ],
)
data class FluviQuerySnapshotEntity(
    @PrimaryKey
    @ColumnInfo(name = "id")
    val id: String,
    @ColumnInfo(name = "slot")
    val slot: QuerySnapshotSlot,
    @ColumnInfo(name = "direction")
    val direction: LedgerDirection,
    @ColumnInfo(name = "format_version")
    val formatVersion: Int,
    @ColumnInfo(name = "created_at_utc_ms")
    val createdAtUtcMs: Long,
    @ColumnInfo(name = "updated_at_utc_ms")
    val updatedAtUtcMs: Long,
)

@Entity(
    tableName = "fluvi_query_snapshot_periods",
    foreignKeys = [
        ForeignKey(
            entity = FluviQuerySnapshotEntity::class,
            parentColumns = ["id"],
            childColumns = ["snapshot_id"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [
        Index(value = ["snapshot_id"]),
        Index(value = ["snapshot_id", "group_key", "period_value"], unique = true),
    ],
)
data class FluviQuerySnapshotPeriodEntity(
    @PrimaryKey
    @ColumnInfo(name = "id")
    val id: String,
    @ColumnInfo(name = "snapshot_id")
    val snapshotId: String,
    @ColumnInfo(name = "group_key")
    val groupKey: String,
    @ColumnInfo(name = "period_kind")
    val periodKind: QueryPeriodKind,
    @ColumnInfo(name = "period_value")
    val periodValue: String,
)

@Entity(
    tableName = "fluvi_query_snapshot_categories",
    foreignKeys = [
        ForeignKey(
            entity = FluviQuerySnapshotEntity::class,
            parentColumns = ["id"],
            childColumns = ["snapshot_id"],
            onDelete = ForeignKey.CASCADE,
        ),
        ForeignKey(
            entity = FluviCategoryEntity::class,
            parentColumns = ["id"],
            childColumns = ["category_id"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [
        Index(value = ["snapshot_id"]),
        Index(value = ["category_id"]),
        Index(value = ["snapshot_id", "category_id"], unique = true),
    ],
)
data class FluviQuerySnapshotCategoryEntity(
    @PrimaryKey
    @ColumnInfo(name = "id")
    val id: String,
    @ColumnInfo(name = "snapshot_id")
    val snapshotId: String,
    @ColumnInfo(name = "category_id")
    val categoryId: String,
)

@Entity(
    tableName = "fluvi_query_snapshot_partners",
    foreignKeys = [
        ForeignKey(
            entity = FluviQuerySnapshotEntity::class,
            parentColumns = ["id"],
            childColumns = ["snapshot_id"],
            onDelete = ForeignKey.CASCADE,
        ),
        ForeignKey(
            entity = FluviPartnerEntity::class,
            parentColumns = ["id"],
            childColumns = ["partner_id"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [
        Index(value = ["snapshot_id"]),
        Index(value = ["partner_id"]),
        Index(value = ["snapshot_id", "partner_id"], unique = true),
    ],
)
data class FluviQuerySnapshotPartnerEntity(
    @PrimaryKey
    @ColumnInfo(name = "id")
    val id: String,
    @ColumnInfo(name = "snapshot_id")
    val snapshotId: String,
    @ColumnInfo(name = "partner_id")
    val partnerId: String,
)

@Entity(
    tableName = "fluvi_query_snapshot_refinements",
    foreignKeys = [
        ForeignKey(
            entity = FluviQuerySnapshotEntity::class,
            parentColumns = ["id"],
            childColumns = ["snapshot_id"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [
        Index(value = ["snapshot_id"]),
        Index(value = ["snapshot_id", "refinement_kind"], unique = true),
    ],
)
data class FluviQuerySnapshotRefinementEntity(
    @PrimaryKey
    @ColumnInfo(name = "id")
    val id: String,
    @ColumnInfo(name = "snapshot_id")
    val snapshotId: String,
    @ColumnInfo(name = "refinement_kind")
    val refinementKind: QueryRefinementKind,
    @ColumnInfo(name = "value_text")
    val valueText: String?,
    @ColumnInfo(name = "value_scaled_100")
    val valueScaled100: Long?,
)

@Entity(tableName = "fluvi_ledger_sync_outbox")
data class FluviLedgerSyncOutboxEntity(
    @PrimaryKey
    @ColumnInfo(name = "entry_id")
    val entryId: String,
    @ColumnInfo(name = "operation")
    val operation: LedgerSyncOperation,
    @ColumnInfo(name = "payload_json")
    val payloadJson: String,
    @ColumnInfo(name = "payload_hash")
    val payloadHash: String,
    @ColumnInfo(name = "revision")
    val revision: Long,
    @ColumnInfo(name = "attempt_count")
    val attemptCount: Int,
    @ColumnInfo(name = "next_attempt_at_utc_ms")
    val nextAttemptAtUtcMs: Long?,
    @ColumnInfo(name = "created_at_utc_ms")
    val createdAtUtcMs: Long,
    @ColumnInfo(name = "updated_at_utc_ms")
    val updatedAtUtcMs: Long,
)

@Entity(
    tableName = "fluvi_ledger_sync_workspaces",
    indices = [
        Index(value = ["booking_year"], unique = true),
    ],
)
data class FluviLedgerSyncWorkspaceEntity(
    @PrimaryKey
    @ColumnInfo(name = "id")
    val id: String,
    @ColumnInfo(name = "booking_year")
    val bookingYear: Int,
    @ColumnInfo(name = "workspace_identifier")
    val workspaceIdentifier: String,
    @ColumnInfo(name = "created_at_utc_ms")
    val createdAtUtcMs: Long,
    @ColumnInfo(name = "updated_at_utc_ms")
    val updatedAtUtcMs: Long,
)

@Entity(
    tableName = "fluvi_ledger_backup_checkpoints",
    indices = [
        Index(value = ["trigger_key"], unique = true),
        Index(value = ["kind", "created_at_utc_ms"]),
    ],
)
data class FluviLedgerBackupCheckpointEntity(
    @PrimaryKey
    @ColumnInfo(name = "id")
    val id: String,
    @ColumnInfo(name = "kind")
    val kind: CheckpointKind,
    @ColumnInfo(name = "trigger_key")
    val triggerKey: String?,
    @ColumnInfo(name = "source_core_revision")
    val sourceCoreRevision: Long,
    @ColumnInfo(name = "prepared_bundle_path")
    val preparedBundlePath: String?,
    @ColumnInfo(name = "remote_backup_file_id")
    val remoteBackupFileId: String?,
    @ColumnInfo(name = "retention_class")
    val retentionClass: CheckpointRetentionClass,
    @ColumnInfo(name = "status")
    val status: CheckpointStatus,
    @ColumnInfo(name = "created_at_utc_ms")
    val createdAtUtcMs: Long,
    @ColumnInfo(name = "updated_at_utc_ms")
    val updatedAtUtcMs: Long,
)
