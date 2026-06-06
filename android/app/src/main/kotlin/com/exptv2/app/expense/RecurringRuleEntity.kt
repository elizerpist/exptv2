package com.exptv2.app.expense

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "recurring_rules",
    foreignKeys = [
        ForeignKey(
            entity = TransactionCategoryEntity::class,
            parentColumns = ["transactionCategoryID"],
            childColumns = ["categoryId"],
            onDelete = ForeignKey.RESTRICT,
        ),
    ],
    indices = [
        Index("triggerType"),
        Index("transactionType"),
        Index("categoryId"),
        Index("expectedDayOfMonth"),
        Index("isActive"),
    ],
)
data class RecurringRuleEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val triggerType: String,
    val transactionType: String,
    val name: String,
    val estimatedAmount: Double,
    val expectedDayOfMonth: Int,
    val categoryId: Int,
    val categoryName: String,
    val categoryColor: String,
    val categoryIconSlot: Int,
    val isActive: Boolean,
    val appFilterText: String,
    val packageName: String,
    val appLabel: String,
    val sampleText: String,
    val includeKeyword: String,
    val amountPattern: String,
    val amountSelection: String,
    val merchantPattern: String,
    val merchantSelection: String,
    val dateToleranceDays: Int,
    val amountTolerancePercent: Double,
    val amountToleranceMin: Double,
    val createdAt: Long,
    val updatedAt: Long,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "id" to id,
        "triggerType" to triggerType,
        "transactionType" to transactionType,
        "name" to name,
        "estimatedAmount" to estimatedAmount,
        "expectedDayOfMonth" to expectedDayOfMonth,
        "categoryId" to categoryId,
        "categoryName" to categoryName,
        "categoryColor" to categoryColor,
        "categoryIconSlot" to categoryIconSlot,
        "isActive" to isActive,
        "appFilterText" to appFilterText,
        "packageName" to packageName,
        "appLabel" to appLabel,
        "sampleText" to sampleText,
        "includeKeyword" to includeKeyword,
        "amountPattern" to amountPattern,
        "amountSelection" to amountSelection,
        "merchantPattern" to merchantPattern,
        "merchantSelection" to merchantSelection,
        "dateToleranceDays" to dateToleranceDays,
        "amountTolerancePercent" to amountTolerancePercent,
        "amountToleranceMin" to amountToleranceMin,
        "createdAt" to createdAt,
        "updatedAt" to updatedAt,
    )
}
