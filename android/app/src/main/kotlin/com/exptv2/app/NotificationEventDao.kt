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

    @Query("SELECT * FROM notification_events WHERE id > :afterId ORDER BY timestamp ASC, id ASC")
    suspend fun eventsAfterId(afterId: Long): List<NotificationEventEntity>

    @Query("DELETE FROM notification_events")
    suspend fun clear()

    @Query("SELECT COUNT(*) FROM notification_events")
    suspend fun count(): Long

    @Query("SELECT COUNT(*) FROM notification_events WHERE hash = :hash")
    suspend fun countByHash(hash: String): Long

    @Query("SELECT MAX(timestamp) FROM notification_events WHERE source = :source")
    suspend fun lastEventTime(source: String): Long?

    @Query(
        """
        SELECT * FROM notification_events
        WHERE (:startMillis IS NULL OR timestamp >= :startMillis)
          AND (:endMillis IS NULL OR timestamp < :endMillis)
          AND (:packageName = '' OR packageName = :packageName)
          AND (:query = ''
            OR appLabel LIKE '%' || :query || '%'
            OR packageName LIKE '%' || :query || '%'
            OR title LIKE '%' || :query || '%'
            OR text LIKE '%' || :query || '%'
            OR bigText LIKE '%' || :query || '%'
            OR subText LIKE '%' || :query || '%')
          AND (:systemOnly = 0 OR manualStatus = 'system')
          AND (:excludeSystem = 0 OR manualStatus != 'system')
        ORDER BY timestamp DESC, id DESC
        LIMIT :limit OFFSET :offset
        """
    )
    suspend fun pageCandidates(
        startMillis: Long?,
        endMillis: Long?,
        packageName: String,
        query: String,
        systemOnly: Int,
        excludeSystem: Int,
        limit: Int,
        offset: Int,
    ): List<NotificationEventEntity>

    @Query("SELECT * FROM notification_events WHERE id = :id LIMIT 1")
    suspend fun byId(id: Long): NotificationEventEntity?

    @Query("UPDATE notification_events SET manualStatus = :manualStatus WHERE id = :id")
    suspend fun updateManualStatus(id: Long, manualStatus: String): Int
}
