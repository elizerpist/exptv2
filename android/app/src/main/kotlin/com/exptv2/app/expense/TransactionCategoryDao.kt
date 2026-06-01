package com.exptv2.app.expense

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update

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

    @Query("SELECT MAX(transactionCategoryID) FROM transaction_categories")
    suspend fun maxId(): Int?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(category: TransactionCategoryEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(categories: List<TransactionCategoryEntity>)

    @Update
    suspend fun update(category: TransactionCategoryEntity)

    @Delete
    suspend fun delete(category: TransactionCategoryEntity)

    @Query("DELETE FROM transaction_categories")
    suspend fun clearAll()
}
