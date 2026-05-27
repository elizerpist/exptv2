package com.exptv2.app.expense

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "transaction_categories",
    indices = [Index("type")],
)
data class TransactionCategoryEntity(
    @PrimaryKey val transactionCategoryID: Int,
    val name: String,
    val type: String,
    val colorSlot: Int?,
    val iconSlot: Int?,
    val backgroundColor: String?,
    val icon: String?,
    val notification: String?,
    val hasLimit: Boolean,
    val limitAmount: Double,
    val alertActive: Boolean,
    val isCustomIcon: Boolean,
    val originalIcon: String?,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "transactionCategoryID" to transactionCategoryID,
        "name" to name,
        "type" to type,
        "colorSlot" to colorSlot,
        "iconSlot" to iconSlot,
        "backgroundColor" to backgroundColor,
        "icon" to icon,
        "notification" to notification,
        "hasLimit" to hasLimit,
        "limitAmount" to limitAmount,
        "alertActive" to alertActive,
        "isCustomIcon" to isCustomIcon,
        "originalIcon" to originalIcon,
    )
}
