package com.exptv2.app.expense

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "recurring_transactions",
    foreignKeys = [
        ForeignKey(
            entity = TransactionCategoryEntity::class,
            parentColumns = ["transactionCategoryID"],
            childColumns = ["categoryId"],
            onDelete = ForeignKey.RESTRICT,
        ),
    ],
    indices = [
        Index("categoryId"),
        Index("transactionType"),
        Index("dayOfMonth"),
        Index("isActive"),
    ],
)
data class RecurringTransactionEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val name: String,
    val amount: Double,
    val transactionType: String,
    val dayOfMonth: Int,
    val categoryId: Int,
    val categoryName: String,
    val categoryColor: String,
    val categoryIconSlot: Int,
    val isActive: Boolean,
    val lastProcessedPeriodKey: String?,
    val lastProcessedAt: Long?,
    val createdAt: Long,
    val updatedAt: Long,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "id" to id,
        "name" to name,
        "amount" to amount,
        "transactionType" to transactionType,
        "dayOfMonth" to dayOfMonth,
        "categoryId" to categoryId,
        "categoryName" to categoryName,
        "categoryColor" to categoryColor,
        "categoryIconSlot" to categoryIconSlot,
        "isActive" to isActive,
        "lastProcessedPeriodKey" to lastProcessedPeriodKey,
        "lastProcessedAt" to lastProcessedAt,
        "createdAt" to createdAt,
        "updatedAt" to updatedAt,
    )
}
