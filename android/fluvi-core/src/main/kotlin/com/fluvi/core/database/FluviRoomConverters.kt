package com.fluvi.core.database

import androidx.room.TypeConverter
import com.fluvi.core.model.CategoryAssignmentMode
import com.fluvi.core.model.CheckpointKind
import com.fluvi.core.model.CheckpointRetentionClass
import com.fluvi.core.model.CheckpointStatus
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.LedgerOriginKind
import com.fluvi.core.model.LedgerSyncOperation
import com.fluvi.core.model.NotificationParseStatus
import com.fluvi.core.model.NotificationProcessingStatus
import com.fluvi.core.model.NotificationTrainingStatus
import com.fluvi.core.model.QueryPeriodKind
import com.fluvi.core.model.QueryRefinementKind
import com.fluvi.core.model.QuerySnapshotSlot
import com.fluvi.core.model.RecurrenceAmountPolicy
import com.fluvi.core.model.RecurrenceTriggerKind

internal class FluviRoomConverters {
    @TypeConverter
    fun ledgerDirectionToStored(value: LedgerDirection?): String? = value?.name

    @TypeConverter
    fun storedToLedgerDirection(value: String?): LedgerDirection? = value?.let(LedgerDirection::valueOf)

    @TypeConverter
    fun ledgerOriginKindToStored(value: LedgerOriginKind?): String? = value?.name

    @TypeConverter
    fun storedToLedgerOriginKind(value: String?): LedgerOriginKind? = value?.let(LedgerOriginKind::valueOf)

    @TypeConverter
    fun categoryAssignmentModeToStored(value: CategoryAssignmentMode?): String? = value?.name

    @TypeConverter
    fun storedToCategoryAssignmentMode(value: String?): CategoryAssignmentMode? =
        value?.let(CategoryAssignmentMode::valueOf)

    @TypeConverter
    fun recurrenceTriggerKindToStored(value: RecurrenceTriggerKind?): String? = value?.name

    @TypeConverter
    fun storedToRecurrenceTriggerKind(value: String?): RecurrenceTriggerKind? =
        value?.let(RecurrenceTriggerKind::valueOf)

    @TypeConverter
    fun recurrenceAmountPolicyToStored(value: RecurrenceAmountPolicy?): String? = value?.name

    @TypeConverter
    fun storedToRecurrenceAmountPolicy(value: String?): RecurrenceAmountPolicy? =
        value?.let(RecurrenceAmountPolicy::valueOf)

    @TypeConverter
    fun notificationParseStatusToStored(value: NotificationParseStatus?): String? = value?.name

    @TypeConverter
    fun storedToNotificationParseStatus(value: String?): NotificationParseStatus? =
        value?.let(NotificationParseStatus::valueOf)

    @TypeConverter
    fun notificationProcessingStatusToStored(value: NotificationProcessingStatus?): String? = value?.name

    @TypeConverter
    fun storedToNotificationProcessingStatus(value: String?): NotificationProcessingStatus? =
        value?.let(NotificationProcessingStatus::valueOf)

    @TypeConverter
    fun notificationTrainingStatusToStored(value: NotificationTrainingStatus?): String? = value?.name

    @TypeConverter
    fun storedToNotificationTrainingStatus(value: String?): NotificationTrainingStatus? =
        value?.let(NotificationTrainingStatus::valueOf)

    @TypeConverter
    fun queryPeriodKindToStored(value: QueryPeriodKind?): String? = value?.name

    @TypeConverter
    fun storedToQueryPeriodKind(value: String?): QueryPeriodKind? = value?.let(QueryPeriodKind::valueOf)

    @TypeConverter
    fun queryRefinementKindToStored(value: QueryRefinementKind?): String? = value?.name

    @TypeConverter
    fun storedToQueryRefinementKind(value: String?): QueryRefinementKind? =
        value?.let(QueryRefinementKind::valueOf)

    @TypeConverter
    fun querySnapshotSlotToStored(value: QuerySnapshotSlot?): String? = value?.name

    @TypeConverter
    fun storedToQuerySnapshotSlot(value: String?): QuerySnapshotSlot? =
        value?.let(QuerySnapshotSlot::valueOf)

    @TypeConverter
    fun ledgerSyncOperationToStored(value: LedgerSyncOperation?): String? = value?.name

    @TypeConverter
    fun storedToLedgerSyncOperation(value: String?): LedgerSyncOperation? =
        value?.let(LedgerSyncOperation::valueOf)

    @TypeConverter
    fun checkpointKindToStored(value: CheckpointKind?): String? = value?.name

    @TypeConverter
    fun storedToCheckpointKind(value: String?): CheckpointKind? = value?.let(CheckpointKind::valueOf)

    @TypeConverter
    fun checkpointRetentionClassToStored(value: CheckpointRetentionClass?): String? = value?.name

    @TypeConverter
    fun storedToCheckpointRetentionClass(value: String?): CheckpointRetentionClass? =
        value?.let(CheckpointRetentionClass::valueOf)

    @TypeConverter
    fun checkpointStatusToStored(value: CheckpointStatus?): String? = value?.name

    @TypeConverter
    fun storedToCheckpointStatus(value: String?): CheckpointStatus? =
        value?.let(CheckpointStatus::valueOf)
}
