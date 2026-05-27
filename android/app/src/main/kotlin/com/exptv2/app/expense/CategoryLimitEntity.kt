package com.exptv2.app.expense

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "category_limits",
    indices = [
        Index(
            value = ["targetType", "targetId", "transactionType", "window", "periodKey"],
            unique = true,
        ),
        Index(value = ["transactionType", "window", "periodKey"]),
    ],
)
data class CategoryLimitEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val targetType: String,
    val targetId: Int,
    val transactionType: String,
    val window: String,
    val periodKey: String,
    val hasLimit: Boolean,
    val limitAmount: Double,
    val alertActive: Boolean,
    val createdAt: Long,
    val updatedAt: Long,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "id" to id,
        "targetType" to targetType,
        "targetId" to targetId,
        "transactionType" to transactionType,
        "window" to window,
        "periodKey" to periodKey,
        "hasLimit" to hasLimit,
        "limitAmount" to limitAmount,
        "alertActive" to alertActive,
        "createdAt" to createdAt,
        "updatedAt" to updatedAt,
    )
}
