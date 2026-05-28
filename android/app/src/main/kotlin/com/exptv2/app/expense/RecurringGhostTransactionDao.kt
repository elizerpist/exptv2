package com.exptv2.app.expense

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface RecurringGhostTransactionDao {
    @Query("SELECT * FROM recurring_ghost_transactions WHERE isActivated = 0 ORDER BY date DESC, time DESC, id DESC")
    suspend fun pending(): List<RecurringGhostTransactionEntity>

    @Query("SELECT * FROM recurring_ghost_transactions WHERE isActivated = 0 AND triggerMillis <= :targetMillis ORDER BY triggerMillis ASC, id ASC")
    suspend fun due(targetMillis: Long): List<RecurringGhostTransactionEntity>

    @Query("SELECT * FROM recurring_ghost_transactions WHERE isActivated = 0 AND recurringTransactionId = :recurringId AND periodKey = :periodKey LIMIT 1")
    suspend fun pendingByRecurringAndPeriod(recurringId: Int, periodKey: String): RecurringGhostTransactionEntity?

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insert(row: RecurringGhostTransactionEntity): Long

    @Query("UPDATE recurring_ghost_transactions SET isActivated = 1, activatedTransactionId = :transactionId, updatedAt = :updatedAt WHERE id = :id")
    suspend fun markActivated(id: Int, transactionId: Int, updatedAt: Long)

    @Query("DELETE FROM recurring_ghost_transactions WHERE recurringTransactionId = :recurringId AND isActivated = 0")
    suspend fun deletePendingForRecurring(recurringId: Int)

    @Query("DELETE FROM recurring_ghost_transactions WHERE recurringTransactionId = :recurringId")
    suspend fun deleteForRecurring(recurringId: Int)
}
