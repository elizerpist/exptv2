package com.exptv2.app.expense

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.exptv2.app.R

class RecurringNotificationHelper(private val context: Context) {
    fun notifyProcessed(rows: List<RecurringTransactionEntity>) {
        if (rows.isEmpty()) return
        ensureChannel()
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        val total = rows.sumOf { kotlin.math.abs(it.amount) }
        val title = "Ismétlődő tranzakciók"
        val message = if (rows.size == 1) {
            "${rows.first().name}: ${total.toLong()} Ft automatikusan hozzáadva"
        } else {
            "${rows.size} ütemezett tranzakció automatikusan hozzáadva"
        }
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .build()
        runCatching {
            NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, notification)
        }
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < 26) return
        val manager = context.getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Ismétlődő tranzakciók",
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = "Automatikusan létrehozott ismétlődő tranzakciók jelzései"
        }
        manager.createNotificationChannel(channel)
    }

    companion object {
        private const val CHANNEL_ID = "recurring_transactions"
        private const val NOTIFICATION_ID = 9206
    }
}
