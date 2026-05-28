package com.exptv2.app.expense

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update

@Dao
interface RecurringTransactionDao {
    @Query("SELECT * FROM recurring_transactions ORDER BY dayOfMonth ASC, name ASC")
    suspend fun all(): List<RecurringTransactionEntity>

    @Query("SELECT * FROM recurring_transactions WHERE isActive = 1 ORDER BY dayOfMonth ASC, name ASC")
    suspend fun active(): List<RecurringTransactionEntity>

    @Query("SELECT * FROM recurring_transactions WHERE id = :id LIMIT 1")
    suspend fun byId(id: Int): RecurringTransactionEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(row: RecurringTransactionEntity): Long

    @Update
    suspend fun update(row: RecurringTransactionEntity)

    @Delete
    suspend fun delete(row: RecurringTransactionEntity)
}
