package com.exptv2.app.expense

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface NotificationCardDao {
    @Query("SELECT * FROM notification_cards WHERE isActive = 1 ORDER BY timestamp DESC, id DESC")
    suspend fun active(): List<NotificationCardEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(row: NotificationCardEntity): Long

    @Query("UPDATE notification_cards SET isRead = 1, updatedAt = :updatedAt WHERE id = :id AND isActive = 1")
    suspend fun markRead(id: Int, updatedAt: Long): Int

    @Query("UPDATE notification_cards SET isActive = 0, updatedAt = :updatedAt WHERE id = :id")
    suspend fun delete(id: Int, updatedAt: Long): Int

    @Query("UPDATE notification_cards SET isActive = 0, updatedAt = :updatedAt WHERE strftime('%Y-%m', timestamp / 1000, 'unixepoch') = :monthKey")
    suspend fun clearMonth(monthKey: String, updatedAt: Long): Int

    @Query("UPDATE notification_cards SET isActive = 0, updatedAt = :updatedAt")
    suspend fun clearAll(updatedAt: Long): Int

    @Query("DELETE FROM notification_cards")
    suspend fun clearAllHard()
}
