package com.fluvi.app

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import com.fluvi.core.FluviCoreFactory
import com.fluvi.core.model.CapturedPushNotification
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * The callback extracts only a compact snapshot then returns immediately.
 * Profile filtering happens in Core before any inbox row is persisted.
 */
class FluviPushNotificationListenerService : NotificationListenerService() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val notification = sbn.notification
        val extras = notification.extras ?: return
        val body = sequenceOf(
            extras.getCharSequence("android.bigText"),
            extras.getCharSequence("android.text"),
            extras.getCharSequence("android.subText"),
        ).mapNotNull { it?.toString()?.trim()?.takeIf(String::isNotEmpty) }.firstOrNull() ?: return
        val packageName = sbn.packageName
        val title = extras.getCharSequence("android.title")?.toString()
        val label = runCatching {
            packageManager.getApplicationLabel(packageManager.getApplicationInfo(packageName, 0)).toString()
        }.getOrNull()
        scope.launch {
            val core = FluviCoreFactory.create(applicationContext)
            try {
                core.automation.capture(CapturedPushNotification(
                    packageName = packageName, appLabel = label, title = title, text = body,
                    notificationKey = sbn.key, receivedAtUtcMs = sbn.postTime,
                ))
                FluviRecurrenceScheduler.scheduleNext(applicationContext, core)
            } finally {
                core.close()
            }
        }
    }

    override fun onDestroy() {
        scope.cancel()
        super.onDestroy()
    }
}
