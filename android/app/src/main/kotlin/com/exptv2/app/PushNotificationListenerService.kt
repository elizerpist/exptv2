package com.exptv2.app

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class PushNotificationListenerService : NotificationListenerService() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val mode = CaptureModeStore(this).getMode()
        if (!mode.allowsNotificationListener()) return

        val extras = sbn.notification.extras
        val draft = EventDraft(
            timestamp = sbn.postTime,
            source = NotificationEventRepository.SOURCE_NOTIFICATION_LISTENER,
            packageName = sbn.packageName,
            title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString().orEmpty(),
            text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString().orEmpty(),
            bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString().orEmpty(),
            subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString().orEmpty(),
            category = sbn.notification.category.orEmpty(),
            notificationKey = sbn.key,
        )

        scope.launch {
            val saved = NotificationEventRepository(this@PushNotificationListenerService)
                .insertDraft(draft)
            EventBroadcaster.publish(saved)
        }
    }
}
