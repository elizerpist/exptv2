package com.exptv2.app

import android.content.Context
import android.content.pm.PackageManager
import java.security.MessageDigest

class NotificationEventRepository(context: Context) {
    private val appContext = context.applicationContext
    private val dao = PushParserDatabase.get(appContext).events()

    suspend fun insertDraft(draft: EventDraft): NotificationEventEntity {
        val hash = stableHash(draft.packageName, draft.title, draft.text, draft.bigText)
        val duplicate = dao.countByHash(hash) > 0
        val entity = NotificationEventEntity(
            timestamp = draft.timestamp,
            source = draft.source,
            packageName = draft.packageName,
            appLabel = draft.appLabel.ifBlank { resolveAppLabel(draft.packageName) },
            title = draft.title,
            text = draft.text,
            bigText = draft.bigText,
            subText = draft.subText,
            category = draft.category,
            notificationKey = draft.notificationKey,
            accessibilityEventType = draft.accessibilityEventType,
            hash = hash,
            isDuplicate = duplicate,
        )
        val id = dao.insert(entity)
        return entity.copy(id = id)
    }

    suspend fun allEvents(): List<NotificationEventEntity> = dao.allEvents()

    suspend fun clear() = dao.clear()

    suspend fun totalCount(): Long = dao.count()

    suspend fun lastNotificationListenerEvent(): Long = dao.lastEventTime(SOURCE_NOTIFICATION_LISTENER) ?: 0L

    suspend fun lastAccessibilityEvent(): Long = dao.lastEventTime(SOURCE_ACCESSIBILITY) ?: 0L

    private fun resolveAppLabel(packageName: String): String {
        if (packageName.isBlank()) return ""
        return try {
            val pm = appContext.packageManager
            val info = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(info).toString()
        } catch (_: PackageManager.NameNotFoundException) {
            packageName
        }
    }

    companion object {
        const val SOURCE_NOTIFICATION_LISTENER = "notification_listener"
        const val SOURCE_ACCESSIBILITY = "accessibility"

        fun stableHash(packageName: String, title: String, text: String, bigText: String): String {
            val input = listOf(packageName, title, text, bigText)
                .joinToString("|") { it.trim().lowercase() }
            val digest = MessageDigest.getInstance("SHA-256").digest(input.toByteArray())
            return digest.joinToString("") { byte -> "%02x".format(byte) }
        }
    }
}

data class EventDraft(
    val timestamp: Long,
    val source: String,
    val packageName: String,
    val appLabel: String = "",
    val title: String = "",
    val text: String = "",
    val bigText: String = "",
    val subText: String = "",
    val category: String = "",
    val notificationKey: String = "",
    val accessibilityEventType: String = "",
)
