package com.exptv2.app.expense

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.exptv2.app.R

class ExpenseNotificationEmitter(context: Context) {
    private val appContext = context.applicationContext
    private val settingsStore = ExpenseSettingsStore(appContext)

    suspend fun emit(
        card: NotificationCardEntity,
        cards: NotificationCardDao,
    ): NotificationCardEntity {
        val startedAt = System.currentTimeMillis()
        val settings = settingsStore.loadNotificationSettings()
        if (!typeEnabled(card, settings)) {
            Log.d(TAG, "[Notification] emit skipped type=${card.type} reason=type_disabled")
            return card
        }
        val inAppEnabled = settings["inAppCardsEnabled"] as? Boolean ?: true
        val androidEnabled = settings["androidPushEnabled"] as? Boolean ?: true
        val saved = if (inAppEnabled) {
            val id = cards.insert(card).toInt()
            Log.d(TAG, "[Notification] card inserted id=$id type=${card.type}")
            card.copy(id = id)
        } else {
            Log.d(TAG, "[Notification] card insert skipped type=${card.type} reason=in_app_disabled")
            card
        }
        if (androidEnabled) {
            notifyAndroid(saved)
        } else {
            Log.d(TAG, "[Notification] android skipped type=${card.type} reason=setting_disabled")
        }
        Log.d(
            TAG,
            "[Perf] notification emit type=${card.type} id=${saved.id} elapsed=${System.currentTimeMillis() - startedAt}ms",
        )
        return saved
    }

    fun notifyAndroid(card: NotificationCardEntity) {
        ensureChannel()
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(
                appContext,
                Manifest.permission.POST_NOTIFICATIONS,
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            Log.d(TAG, "[Notification] android skipped type=${card.type} reason=missing_post_notifications")
            return
        }
        val notification = NotificationCompat.Builder(appContext, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(card.title)
            .setContentText(card.message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(card.message))
            .setPriority(priorityFor(card.priority))
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .build()
        runCatching {
            NotificationManagerCompat.from(appContext).notify(notificationId(card), notification)
            Log.d(TAG, "[Notification] android notify id=${notificationId(card)} type=${card.type}")
        }.onFailure { error ->
            Log.d(TAG, "[Notification] android failed type=${card.type} error=${error.message}")
        }
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < 26) return
        val manager = appContext.getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Expense alerts",
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = "Tranzakciók, limitek és ismétlődő tranzakciók értesítései"
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        manager.createNotificationChannel(channel)
    }

    private fun typeEnabled(card: NotificationCardEntity, settings: Map<String, Any?>): Boolean {
        return when (card.type) {
            "limit_75", "limit_100" -> settings["limitAlertsEnabled"] as? Boolean ?: true
            "recurring_transaction_alert" -> settings["recurringAlertsEnabled"] as? Boolean ?: true
            "transaction_created" -> settings["transactionAlertsEnabled"] as? Boolean ?: true
            else -> true
        }
    }

    private fun priorityFor(priority: String): Int {
        return when (priority) {
            "critical" -> NotificationCompat.PRIORITY_HIGH
            "warning" -> NotificationCompat.PRIORITY_DEFAULT
            else -> NotificationCompat.PRIORITY_DEFAULT
        }
    }

    private fun notificationId(card: NotificationCardEntity): Int {
        val seed = if (card.id > 0) card.id else (card.timestamp % 100000L).toInt().coerceAtLeast(0)
        return 12000 + seed
    }

    companion object {
        private const val TAG = "ExpenseNotification"
        private const val CHANNEL_ID = "expense_alerts"
    }
}
