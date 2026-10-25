package com.fluvi.core.database.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import com.fluvi.core.model.CategoryAssignmentMode
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.NotificationParseStatus
import com.fluvi.core.model.NotificationProcessingStatus
import com.fluvi.core.model.NotificationTrainingStatus
import com.fluvi.core.model.PushReviewStatus
import com.fluvi.core.model.RecurrenceAmountPolicy
import com.fluvi.core.model.RecurrenceTriggerKind
import com.fluvi.core.model.RecurrenceOccurrenceStatus
import com.fluvi.core.model.RecurrenceRealizationKind

@Entity(
    tableName = "fluvi_recurrence_rules",
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
    ],
    indices = [
        Index(value = ["partner_id"]),
        Index(value = ["category_id"]),
        Index(value = ["is_active"]),
    ],
)
data class FluviRecurrenceRuleEntity(
    @PrimaryKey
    @ColumnInfo(name = "id")
    val id: String,
    @ColumnInfo(name = "name")
    val name: String,
    @ColumnInfo(name = "trigger_kind")
    val triggerKind: RecurrenceTriggerKind,
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
    @ColumnInfo(name = "amount_policy")
    val amountPolicy: RecurrenceAmountPolicy,
    /** Zero is the legacy sentinel for UNKNOWN; occurrences keep a nullable expected amount. */
    @ColumnInfo(name = "amount_scaled_100")
    val amountScaled100: Long,
    @ColumnInfo(name = "day_of_month")
    val dayOfMonth: Int,
    @ColumnInfo(name = "local_time_minutes")
    val localTimeMinutes: Int,
    @ColumnInfo(name = "start_local_epoch_day")
    val startLocalEpochDay: Long,
    @ColumnInfo(name = "end_local_epoch_day")
    val endLocalEpochDay: Long?,
    @ColumnInfo(name = "timezone_id")
    val timezoneId: String,
    @ColumnInfo(name = "rule_version")
    val ruleVersion: Int,
    @ColumnInfo(name = "archived_at_utc_ms")
    val archivedAtUtcMs: Long?,
    @ColumnInfo(name = "is_active")
    val isActive: Boolean,
    @ColumnInfo(name = "created_at_utc_ms")
    val createdAtUtcMs: Long,
    @ColumnInfo(name = "updated_at_utc_ms")
    val updatedAtUtcMs: Long,
)

@Entity(
    tableName = "fluvi_time_recurring_rule_config",
    foreignKeys = [
        ForeignKey(
            entity = FluviRecurrenceRuleEntity::class,
            parentColumns = ["id"],
            childColumns = ["rule_id"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
)
data class FluviTimeRecurringRuleConfigEntity(
    @PrimaryKey
    @ColumnInfo(name = "rule_id")
    val ruleId: String,
    @ColumnInfo(name = "day_of_month")
    val dayOfMonth: Int,
    @ColumnInfo(name = "local_time_minutes")
    val localTimeMinutes: Int,
)

@Entity(
    tableName = "fluvi_push_recurring_rule_config",
    foreignKeys = [
        ForeignKey(
            entity = FluviRecurrenceRuleEntity::class,
            parentColumns = ["id"],
            childColumns = ["rule_id"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [Index(value = ["push_profile_id", "push_rule_id"])],
)
data class FluviPushRecurringRuleConfigEntity(
    @PrimaryKey
    @ColumnInfo(name = "rule_id")
    val ruleId: String,
    /** Stable Parser v2 source; both identifiers are nullable for imported legacy drafts. */
    @ColumnInfo(name = "push_profile_id")
    val pushProfileId: String?,
    @ColumnInfo(name = "push_rule_id")
    val pushRuleId: String?,
    @ColumnInfo(name = "expected_local_time_minutes")
    val expectedLocalTimeMinutes: Int,
    @ColumnInfo(name = "amount_tolerance_scaled_100")
    val amountToleranceScaled100: Long,
    @ColumnInfo(name = "day_window")
    val dayWindow: Int,
    @ColumnInfo(name = "parser_match_text")
    val parserMatchText: String?,
)

@Entity(
    tableName = "fluvi_occurrence_overrides",
    foreignKeys = [
        ForeignKey(
            entity = FluviRecurrenceRuleEntity::class,
            parentColumns = ["id"],
            childColumns = ["rule_id"],
            onDelete = ForeignKey.CASCADE,
        ),
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
    ],
    indices = [
        Index(value = ["rule_id"]),
        Index(value = ["partner_id"]),
        Index(value = ["category_id"]),
        Index(value = ["rule_id", "occurrence_key"], unique = true),
    ],
)
data class FluviOccurrenceOverrideEntity(
    @PrimaryKey
    @ColumnInfo(name = "id")
    val id: String,
    @ColumnInfo(name = "rule_id")
    val ruleId: String,
    @ColumnInfo(name = "occurrence_key")
    val occurrenceKey: String,
    @ColumnInfo(name = "partner_id")
    val partnerId: String?,
    @ColumnInfo(name = "category_id")
    val categoryId: String?,
    @ColumnInfo(name = "category_assignment_mode")
    val categoryAssignmentMode: CategoryAssignmentMode?,
    @ColumnInfo(name = "note")
    val note: String?,
    @ColumnInfo(name = "amount_scaled_100")
    val amountScaled100: Long?,
    @ColumnInfo(name = "booked_local_epoch_day")
    val bookedLocalEpochDay: Long?,
    @ColumnInfo(name = "booked_local_time_minutes")
    val bookedLocalTimeMinutes: Int?,
    @ColumnInfo(name = "is_dismissed")
    val isDismissed: Boolean,
    @ColumnInfo(name = "is_overdue")
    val isOverdue: Boolean,
    @ColumnInfo(name = "created_at_utc_ms")
    val createdAtUtcMs: Long,
    @ColumnInfo(name = "updated_at_utc_ms")
    val updatedAtUtcMs: Long,
)

@Entity(
    tableName = "fluvi_recurrence_occurrences",
    foreignKeys = [
        ForeignKey(entity = FluviRecurrenceRuleEntity::class, parentColumns = ["id"], childColumns = ["rule_id"], onDelete = ForeignKey.NO_ACTION),
        ForeignKey(entity = FluviPartnerEntity::class, parentColumns = ["id"], childColumns = ["partner_id"], onDelete = ForeignKey.NO_ACTION),
        ForeignKey(entity = FluviCategoryEntity::class, parentColumns = ["id"], childColumns = ["category_id"], onDelete = ForeignKey.NO_ACTION),
    ],
    indices = [
        Index(value = ["rule_id", "occurrence_key"], unique = true),
        Index(value = ["status", "expected_local_epoch_day"]),
        Index(value = ["direction", "expected_local_epoch_day", "expected_local_time_minutes", "id"]),
        Index(value = ["partner_id", "status"]),
        Index(value = ["category_id", "status"]),
        Index(value = ["expected_at_utc_ms", "status"]),
    ],
)
data class FluviRecurrenceOccurrenceEntity(
    @PrimaryKey @ColumnInfo(name = "id") val id: String,
    @ColumnInfo(name = "rule_id") val ruleId: String,
    @ColumnInfo(name = "occurrence_key") val occurrenceKey: String,
    @ColumnInfo(name = "rule_version") val ruleVersion: Int,
    @ColumnInfo(name = "expected_local_epoch_day") val expectedLocalEpochDay: Long,
    @ColumnInfo(name = "expected_local_time_minutes") val expectedLocalTimeMinutes: Int,
    @ColumnInfo(name = "expected_at_utc_ms") val expectedAtUtcMs: Long,
    @ColumnInfo(name = "timezone_id") val timezoneId: String,
    @ColumnInfo(name = "partner_id") val partnerId: String,
    @ColumnInfo(name = "category_id") val categoryId: String,
    @ColumnInfo(name = "category_assignment_mode") val categoryAssignmentMode: CategoryAssignmentMode,
    @ColumnInfo(name = "direction") val direction: LedgerDirection,
    @ColumnInfo(name = "expected_amount_scaled_100") val expectedAmountScaled100: Long?,
    @ColumnInfo(name = "amount_policy") val amountPolicy: RecurrenceAmountPolicy,
    @ColumnInfo(name = "note") val note: String?,
    @ColumnInfo(name = "trigger_kind") val triggerKind: RecurrenceTriggerKind,
    @ColumnInfo(name = "status") val status: RecurrenceOccurrenceStatus,
    @ColumnInfo(name = "realization_kind") val realizationKind: RecurrenceRealizationKind?,
    @ColumnInfo(name = "resolved_at_utc_ms") val resolvedAtUtcMs: Long?,
    @ColumnInfo(name = "created_at_utc_ms") val createdAtUtcMs: Long,
    @ColumnInfo(name = "updated_at_utc_ms") val updatedAtUtcMs: Long,
    @ColumnInfo(name = "revision") val revision: Long,
)

@Entity(
    tableName = "fluvi_notification_inbox",
    foreignKeys = [
        ForeignKey(
            entity = FluviLedgerEntryEntity::class,
            parentColumns = ["id"],
            childColumns = ["ledger_entry_id"],
            onDelete = ForeignKey.SET_NULL,
        ),
        ForeignKey(
            entity = FluviPushProfileEntity::class,
            parentColumns = ["id"],
            childColumns = ["profile_id"],
            onDelete = ForeignKey.SET_NULL,
        ),
    ],
    indices = [
        Index(value = ["ledger_entry_id"]),
        Index(value = ["received_at_utc_ms"]),
        Index(value = ["training_status", "received_at_utc_ms"]),
        Index(value = ["profile_id", "received_at_utc_ms"]),
        Index(value = ["fingerprint"], unique = true),
    ],
)
data class FluviNotificationInboxEntity(
    @PrimaryKey
    @ColumnInfo(name = "id")
    val id: String,
    @ColumnInfo(name = "raw_notification_text")
    val rawNotificationText: String,
    @ColumnInfo(name = "source_package_name")
    val sourcePackageName: String?,
    @ColumnInfo(name = "source_app_label")
    val sourceAppLabel: String?,
    @ColumnInfo(name = "profile_id")
    val profileId: String?,
    @ColumnInfo(name = "notification_key")
    val notificationKey: String?,
    @ColumnInfo(name = "fingerprint")
    val fingerprint: String?,
    @ColumnInfo(name = "title")
    val title: String?,
    @ColumnInfo(name = "received_at_utc_ms")
    val receivedAtUtcMs: Long,
    @ColumnInfo(name = "parse_status")
    val parseStatus: NotificationParseStatus,
    @ColumnInfo(name = "processing_status")
    val processingStatus: NotificationProcessingStatus,
    @ColumnInfo(name = "training_status")
    val trainingStatus: NotificationTrainingStatus,
    @ColumnInfo(name = "review_status")
    val reviewStatus: PushReviewStatus,
    @ColumnInfo(name = "confidence")
    val confidence: Double?,
    @ColumnInfo(name = "suggested_payload_json")
    val suggestedPayloadJson: String?,
    @ColumnInfo(name = "diagnostics_json")
    val diagnosticsJson: String?,
    @ColumnInfo(name = "ledger_entry_id")
    val ledgerEntryId: String?,
    @ColumnInfo(name = "created_at_utc_ms")
    val createdAtUtcMs: Long,
    @ColumnInfo(name = "updated_at_utc_ms")
    val updatedAtUtcMs: Long,
)
