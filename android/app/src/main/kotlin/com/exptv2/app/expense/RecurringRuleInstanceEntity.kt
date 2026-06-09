package com.exptv2.app.expense

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import java.util.Calendar

object RecurringRuleInstanceStatus {
    const val PENDING = "pending"
    const val ACTIVATED = "activated"
    const val EXPIRED = "expired"
}

@Entity(
    tableName = "recurring_rule_instances",
    foreignKeys = [
        ForeignKey(
            entity = RecurringRuleEntity::class,
            parentColumns = ["id"],
            childColumns = ["ruleId"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [
        Index(value = ["ruleId", "periodKey"], unique = true),
        Index("status"),
        Index("periodKey"),
        Index("estimatedDate"),
        Index(value = ["estimatedDate", "estimatedTime"]),
        Index("matchedNotificationEventId"),
    ],
)
data class RecurringRuleInstanceEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val ruleId: Int,
    val periodKey: String,
    val status: String,
    val estimatedDate: String,
    val estimatedTime: String = "00:00",
    val estimatedAmount: Double,
    val triggerTypeSnapshot: String,
    val transactionTypeSnapshot: String,
    val nameSnapshot: String,
    val categoryIdSnapshot: Int,
    val categoryNameSnapshot: String,
    val categoryColorSnapshot: String,
    val categoryIconSlotSnapshot: Int,
    val activatedTransactionId: Int?,
    val activatedAt: Long?,
    val matchedNotificationEventId: Long?,
    val matchConfidence: Double?,
    val createdAt: Long,
    val updatedAt: Long,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "id" to id,
        "ruleId" to ruleId,
        "periodKey" to periodKey,
        "status" to status,
        "estimatedDate" to estimatedDate,
        "estimatedTime" to estimatedTime,
        "estimatedAmount" to estimatedAmount,
        "triggerTypeSnapshot" to triggerTypeSnapshot,
        "transactionTypeSnapshot" to transactionTypeSnapshot,
        "nameSnapshot" to nameSnapshot,
        "categoryIdSnapshot" to categoryIdSnapshot,
        "categoryNameSnapshot" to categoryNameSnapshot,
        "categoryColorSnapshot" to categoryColorSnapshot,
        "categoryIconSlotSnapshot" to categoryIconSlotSnapshot,
        "activatedTransactionId" to activatedTransactionId,
        "activatedAt" to activatedAt,
        "matchedNotificationEventId" to matchedNotificationEventId,
        "matchConfidence" to matchConfidence,
        "createdAt" to createdAt,
        "updatedAt" to updatedAt,
    )

    fun toLegacyGhostMap(): Map<String, Any?> = mapOf(
        "id" to id,
        "recurringTransactionId" to ruleId,
        "periodKey" to periodKey,
        "name" to nameSnapshot,
        "amount" to estimatedAmount,
        "triggerTypeSnapshot" to triggerTypeSnapshot,
        "transactionType" to transactionTypeSnapshot,
        "date" to estimatedDate,
        "estimatedTime" to estimatedTime,
        "time" to estimatedTime,
        "categoryId" to categoryIdSnapshot,
        "categoryName" to categoryNameSnapshot,
        "categoryColor" to categoryColorSnapshot,
        "categoryIconSlot" to categoryIconSlotSnapshot,
        "triggerMillis" to triggerMillisForDateTime(estimatedDate, estimatedTime),
        "isActivated" to (status == RecurringRuleInstanceStatus.ACTIVATED),
        "activatedTransactionId" to activatedTransactionId,
        "createdAt" to createdAt,
        "updatedAt" to updatedAt,
    )
}

private fun triggerMillisForDateTime(date: String, time: String): Long {
    val parts = date.trim().replace('.', '-').split("-")
    if (parts.size != 3) return 0L
    val year = parts[0].toIntOrNull() ?: return 0L
    val month = parts[1].toIntOrNull() ?: return 0L
    val day = parts[2].toIntOrNull() ?: return 0L
    val timeParts = time.trim().split(":")
    val hour = timeParts.getOrNull(0)?.toIntOrNull() ?: 0
    val minute = timeParts.getOrNull(1)?.toIntOrNull() ?: 0
    return Calendar.getInstance().apply {
        set(Calendar.YEAR, year)
        set(Calendar.MONTH, month - 1)
        set(Calendar.DAY_OF_MONTH, day)
        set(Calendar.HOUR_OF_DAY, hour.coerceIn(0, 23))
        set(Calendar.MINUTE, minute.coerceIn(0, 59))
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
    }.timeInMillis
}
