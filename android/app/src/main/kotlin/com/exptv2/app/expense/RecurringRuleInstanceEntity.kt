package com.exptv2.app.expense

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

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
        Index("matchedNotificationEventId"),
    ],
)
data class RecurringRuleInstanceEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val ruleId: Int,
    val periodKey: String,
    val status: String,
    val estimatedDate: String,
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
}
