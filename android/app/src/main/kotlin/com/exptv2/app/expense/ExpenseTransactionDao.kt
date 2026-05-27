package com.exptv2.app.expense

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

data class CategoryCountRow(
    val transactionCategoryID: Int,
    val count: Int,
)

@Dao
interface ExpenseTransactionDao {
    @Query("SELECT COUNT(*) FROM transactions")
    suspend fun count(): Int

    @Query("SELECT * FROM transactions ORDER BY date DESC, time DESC, id DESC")
    suspend fun all(): List<ExpenseTransactionEntity>

    @Query("SELECT * FROM transactions WHERE id = :id LIMIT 1")
    suspend fun byId(id: Int): ExpenseTransactionEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(transaction: ExpenseTransactionEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(transactions: List<ExpenseTransactionEntity>)

    @Delete
    suspend fun delete(transaction: ExpenseTransactionEntity)

    @Query("SELECT MAX(id) FROM transactions WHERE CAST(id AS TEXT) LIKE :prefix || '%'")
    suspend fun maxIdForPrefix(prefix: String): Int?

    @Query("SELECT COUNT(*) FROM transactions WHERE transactionCategoryID = :categoryId")
    suspend fun countByCategory(categoryId: Int): Int

    @Query("SELECT transactionCategoryID, COUNT(*) AS count FROM transactions GROUP BY transactionCategoryID")
    suspend fun categoryCounts(): List<CategoryCountRow>
}
