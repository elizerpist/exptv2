package com.exptv2.app.expense

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "transactions",
    foreignKeys = [
        ForeignKey(
            entity = TransactionCategoryEntity::class,
            parentColumns = ["transactionCategoryID"],
            childColumns = ["transactionCategoryID"],
            onDelete = ForeignKey.RESTRICT,
        ),
    ],
    indices = [
        Index("transactionCategoryID"),
        Index("date"),
        Index("merchant"),
        Index("amount"),
        Index("recurringTransactionId"),
        Index("recurringRuleId"),
        Index("recurringInstanceId"),
        Index(value = ["date", "time", "id"]),
        Index(value = ["amount", "date", "time", "id"]),
        Index(value = ["transactionCategoryID", "date", "time", "id"]),
    ],
)
data class ExpenseTransactionEntity(
    @PrimaryKey val id: Int,
    val date: String,
    val time: String,
    val latitude: Double?,
    val longitude: Double?,
    val address: String?,
    val merchant: String,
    val amount: Double,
    val userAssignedName: String?,
    val transactionCategoryID: Int,
    val recurringTransactionId: Int? = null,
    val recurringRuleId: Int? = null,
    val recurringInstanceId: Int? = null,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "id" to id,
        "date" to date,
        "time" to time,
        "latitude" to latitude,
        "longitude" to longitude,
        "address" to address,
        "merchant" to merchant,
        "amount" to amount,
        "userAssignedName" to userAssignedName,
        "transactionCategoryID" to transactionCategoryID,
        "recurringTransactionId" to recurringTransactionId,
        "recurringRuleId" to recurringRuleId,
        "recurringInstanceId" to recurringInstanceId,
    )
}
