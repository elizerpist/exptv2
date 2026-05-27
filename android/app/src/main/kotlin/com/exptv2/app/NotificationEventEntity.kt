package com.exptv2.app

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "notification_events")
data class NotificationEventEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val timestamp: Long,
    val source: String,
    val packageName: String,
    val appLabel: String,
    val title: String,
    val text: String,
    val bigText: String,
    val subText: String,
    val category: String,
    val notificationKey: String,
    val accessibilityEventType: String,
    val hash: String,
    val isDuplicate: Boolean,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "id" to id,
        "timestamp" to timestamp,
        "source" to source,
        "packageName" to packageName,
        "appLabel" to appLabel,
        "title" to title,
        "text" to text,
        "bigText" to bigText,
        "subText" to subText,
        "category" to category,
        "notificationKey" to notificationKey,
        "accessibilityEventType" to accessibilityEventType,
        "hash" to hash,
        "isDuplicate" to isDuplicate,
    )
}
