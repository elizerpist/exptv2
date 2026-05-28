package com.exptv2.app.expense

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "recurring_ghost_transactions",
    foreignKeys = [
        ForeignKey(
            entity = RecurringTransactionEntity::class,
            parentColumns = ["id"],
            childColumns = ["recurringTransactionId"],
            onDelete = ForeignKey.CASCADE,
        ),
        ForeignKey(
            entity = TransactionCategoryEntity::class,
            parentColumns = ["transactionCategoryID"],
            childColumns = ["categoryId"],
            onDelete = ForeignKey.RESTRICT,
        ),
    ],
    indices = [
        Index(value = ["recurringTransactionId", "periodKey"], unique = true),
        Index("categoryId"),
        Index("periodKey"),
        Index("triggerMillis"),
        Index("isActivated"),
    ],
)
data class RecurringGhostTransactionEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val recurringTransactionId: Int,
    val periodKey: String,
    val name: String,
    val amount: Double,
    val transactionType: String,
    val date: String,
    val time: String,
    val categoryId: Int,
    val categoryName: String,
    val categoryColor: String,
    val categoryIconSlot: Int,
    val triggerMillis: Long,
    val isActivated: Boolean,
    val activatedTransactionId: Int?,
    val createdAt: Long,
    val updatedAt: Long,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "id" to id,
        "recurringTransactionId" to recurringTransactionId,
        "periodKey" to periodKey,
        "name" to name,
        "amount" to amount,
        "transactionType" to transactionType,
        "date" to date,
        "time" to time,
        "categoryId" to categoryId,
        "categoryName" to categoryName,
        "categoryColor" to categoryColor,
        "categoryIconSlot" to categoryIconSlot,
        "triggerMillis" to triggerMillis,
        "isActivated" to isActivated,
        "activatedTransactionId" to activatedTransactionId,
        "createdAt" to createdAt,
        "updatedAt" to updatedAt,
    )
}
