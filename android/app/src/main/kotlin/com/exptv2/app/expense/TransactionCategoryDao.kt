package com.exptv2.app.expense

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface TransactionCategoryDao {
    @Query("SELECT COUNT(*) FROM transaction_categories")
    suspend fun count(): Int

    @Query("SELECT * FROM transaction_categories ORDER BY transactionCategoryID ASC")
    suspend fun all(): List<TransactionCategoryEntity>

    @Query("SELECT * FROM transaction_categories WHERE type = :type ORDER BY transactionCategoryID ASC")
    suspend fun byType(type: String): List<TransactionCategoryEntity>

    @Query("SELECT * FROM transaction_categories WHERE transactionCategoryID = :id LIMIT 1")
    suspend fun byId(id: Int): TransactionCategoryEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(categories: List<TransactionCategoryEntity>)
}
