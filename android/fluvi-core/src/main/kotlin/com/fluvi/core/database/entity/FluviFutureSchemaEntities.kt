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
import com.fluvi.core.model.RecurrenceAmountPolicy
import com.fluvi.core.model.RecurrenceTriggerKind

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
    @ColumnInfo(name = "amount_scaled_100")
    val amountScaled100: Long,
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
)
data class FluviPushRecurringRuleConfigEntity(
    @PrimaryKey
    @ColumnInfo(name = "rule_id")
    val ruleId: String,
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
    tableName = "fluvi_notification_inbox",
    foreignKeys = [
        ForeignKey(
            entity = FluviLedgerEntryEntity::class,
            parentColumns = ["id"],
            childColumns = ["ledger_entry_id"],
            onDelete = ForeignKey.SET_NULL,
        ),
    ],
    indices = [
        Index(value = ["ledger_entry_id"]),
        Index(value = ["received_at_utc_ms"]),
        Index(value = ["training_status", "received_at_utc_ms"]),
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
    @ColumnInfo(name = "received_at_utc_ms")
    val receivedAtUtcMs: Long,
    @ColumnInfo(name = "parse_status")
    val parseStatus: NotificationParseStatus,
    @ColumnInfo(name = "processing_status")
    val processingStatus: NotificationProcessingStatus,
    @ColumnInfo(name = "training_status")
    val trainingStatus: NotificationTrainingStatus,
    @ColumnInfo(name = "ledger_entry_id")
    val ledgerEntryId: String?,
    @ColumnInfo(name = "created_at_utc_ms")
    val createdAtUtcMs: Long,
    @ColumnInfo(name = "updated_at_utc_ms")
    val updatedAtUtcMs: Long,
)
