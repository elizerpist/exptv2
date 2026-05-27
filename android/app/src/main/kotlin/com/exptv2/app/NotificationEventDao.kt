package com.exptv2.app

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query

@Dao
interface NotificationEventDao {
    @Insert
    suspend fun insert(event: NotificationEventEntity): Long

    @Query("SELECT * FROM notification_events ORDER BY timestamp ASC, id ASC")
    suspend fun allEvents(): List<NotificationEventEntity>

    @Query("DELETE FROM notification_events")
    suspend fun clear()

    @Query("SELECT COUNT(*) FROM notification_events")
    suspend fun count(): Long

    @Query("SELECT COUNT(*) FROM notification_events WHERE hash = :hash")
    suspend fun countByHash(hash: String): Long

    @Query("SELECT MAX(timestamp) FROM notification_events WHERE source = :source")
    suspend fun lastEventTime(source: String): Long?
}
