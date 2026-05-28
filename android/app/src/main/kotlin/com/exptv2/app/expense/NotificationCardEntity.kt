package com.exptv2.app.expense

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "notification_cards",
    indices = [
        Index("timestamp"),
        Index("type"),
        Index("isRead"),
        Index("isActive"),
    ],
)
data class NotificationCardEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val type: String,
    val title: String,
    val message: String,
    val timestamp: Long,
    val isRead: Boolean,
    val isActive: Boolean,
    val priority: String,
    val categoryId: Int?,
    val categoryName: String?,
    val categoryColor: String?,
    val categoryIconSlot: Int?,
    val recurringTransactionId: Int?,
    val transactionId: Int?,
    val amount: Double?,
    val triggerDate: String?,
    val nextDueDate: String?,
    val createdAt: Long,
    val updatedAt: Long,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "id" to id,
        "type" to type,
        "title" to title,
        "message" to message,
        "timestamp" to timestamp,
        "isRead" to isRead,
        "isActive" to isActive,
        "priority" to priority,
        "categoryId" to categoryId,
        "categoryName" to categoryName,
        "categoryColor" to categoryColor,
        "categoryIconSlot" to categoryIconSlot,
        "recurringTransactionId" to recurringTransactionId,
        "transactionId" to transactionId,
        "amount" to amount,
        "triggerDate" to triggerDate,
        "nextDueDate" to nextDueDate,
        "createdAt" to createdAt,
        "updatedAt" to updatedAt,
    )
}
