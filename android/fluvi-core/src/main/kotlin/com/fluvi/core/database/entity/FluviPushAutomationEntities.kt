package com.fluvi.core.database.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.PushProfileState
import com.fluvi.core.model.PushRuleState
import com.fluvi.core.model.PushSampleKind
import com.fluvi.core.model.PushTransactionDirection

@Entity(
    tableName = "fluvi_push_profiles",
    indices = [Index(value = ["package_name"], unique = true), Index(value = ["state", "updated_at_utc_ms"])],
)
data class FluviPushProfileEntity(
    @PrimaryKey @ColumnInfo(name = "id") val id: String,
    @ColumnInfo(name = "package_name") val packageName: String,
    @ColumnInfo(name = "app_label") val appLabel: String,
    @ColumnInfo(name = "display_name") val displayName: String,
    @ColumnInfo(name = "default_direction") val defaultDirection: PushTransactionDirection,
    @ColumnInfo(name = "state") val state: PushProfileState,
    @ColumnInfo(name = "created_at_utc_ms") val createdAtUtcMs: Long,
    @ColumnInfo(name = "updated_at_utc_ms") val updatedAtUtcMs: Long,
    @ColumnInfo(name = "revision") val revision: Long,
)

@Entity(
    tableName = "fluvi_push_rules",
    foreignKeys = [ForeignKey(
        entity = FluviPushProfileEntity::class,
        parentColumns = ["id"], childColumns = ["profile_id"], onDelete = ForeignKey.CASCADE,
    )],
    indices = [Index(value = ["profile_id", "state", "priority"])],
)
data class FluviPushRuleEntity(
    @PrimaryKey @ColumnInfo(name = "id") val id: String,
    @ColumnInfo(name = "profile_id") val profileId: String,
    @ColumnInfo(name = "name") val name: String,
    @ColumnInfo(name = "direction") val direction: LedgerDirection,
    @ColumnInfo(name = "state") val state: PushRuleState,
    /** Versioned JSON template with literal context and named field spans. */
    @ColumnInfo(name = "compiled_representation") val compiledRepresentation: String,
    @ColumnInfo(name = "version") val version: Int,
    @ColumnInfo(name = "priority") val priority: Int,
    @ColumnInfo(name = "auto_accept_threshold") val autoAcceptThreshold: Double,
    @ColumnInfo(name = "created_at_utc_ms") val createdAtUtcMs: Long,
    @ColumnInfo(name = "updated_at_utc_ms") val updatedAtUtcMs: Long,
)

@Entity(
    tableName = "fluvi_push_training_samples",
    foreignKeys = [
        ForeignKey(entity = FluviPushProfileEntity::class, parentColumns = ["id"], childColumns = ["profile_id"], onDelete = ForeignKey.CASCADE),
        ForeignKey(entity = FluviPushRuleEntity::class, parentColumns = ["id"], childColumns = ["rule_id"], onDelete = ForeignKey.SET_NULL),
        ForeignKey(entity = FluviNotificationInboxEntity::class, parentColumns = ["id"], childColumns = ["notification_id"], onDelete = ForeignKey.CASCADE),
    ],
    indices = [
        Index(value = ["profile_id", "created_at_utc_ms"]),
        Index(value = ["notification_id"]),
        Index(value = ["rule_id"]),
    ],
)
data class FluviPushTrainingSampleEntity(
    @PrimaryKey @ColumnInfo(name = "id") val id: String,
    @ColumnInfo(name = "profile_id") val profileId: String,
    @ColumnInfo(name = "notification_id") val notificationId: String,
    @ColumnInfo(name = "rule_id") val ruleId: String?,
    @ColumnInfo(name = "sample_kind") val sampleKind: PushSampleKind,
    /** JSON list of original UTF-16 offsets and semantic roles. */
    @ColumnInfo(name = "spans_json") val spansJson: String,
    @ColumnInfo(name = "created_at_utc_ms") val createdAtUtcMs: Long,
)

@Entity(
    tableName = "fluvi_push_rule_test_results",
    foreignKeys = [ForeignKey(entity = FluviPushRuleEntity::class, parentColumns = ["id"], childColumns = ["rule_id"], onDelete = ForeignKey.CASCADE)],
    indices = [Index(value = ["rule_id", "rule_version", "created_at_utc_ms"])],
)
data class FluviPushRuleTestResultEntity(
    @PrimaryKey @ColumnInfo(name = "id") val id: String,
    @ColumnInfo(name = "rule_id") val ruleId: String,
    @ColumnInfo(name = "rule_version") val ruleVersion: Int,
    @ColumnInfo(name = "matched_count") val matchedCount: Int,
    @ColumnInfo(name = "review_count") val reviewCount: Int,
    @ColumnInfo(name = "rejected_count") val rejectedCount: Int,
    @ColumnInfo(name = "conflicted_count") val conflictedCount: Int,
    @ColumnInfo(name = "activation_ready") val activationReady: Boolean,
    @ColumnInfo(name = "created_at_utc_ms") val createdAtUtcMs: Long,
)
