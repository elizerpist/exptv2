package com.exptv2.app

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import kotlinx.coroutines.Dispatchers

class PushNotificationListenerService : NotificationListenerService() {
    private val scope = LifecycleCoroutineScope(Dispatchers.IO)

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val startedAt = System.currentTimeMillis()
        val mode = CaptureModeStore(this).getMode()
        if (!mode.allowsNotificationListener()) {
            publishDebug("[PushParser] listener skipped package=${sbn.packageName} reason=capture_mode_${mode.value}")
            return
        }

        publishDebug("[PushParser] listener received package=${sbn.packageName} timestamp=${sbn.postTime}")
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

        scope.launchGuarded(
            reportFailure = { error ->
                val message =
                    "[PushParser] listener failed package=${draft.packageName} error=${error.message}"
                Log.e(LOG_TAG, message, error)
                EventBroadcaster.publishDebugLog(message)
            },
        ) {
            val saved = NotificationEventRepository(this@PushNotificationListenerService)
                .insertDraft(draft)
            if (saved != null) EventBroadcaster.publish(saved)
            publishDebug(
                "[PushParser] listener completed package=${draft.packageName} " +
                    "saved=${saved?.id ?: 0} elapsed=${System.currentTimeMillis() - startedAt}ms",
            )
        }
    }

    override fun onDestroy() {
        scope.cancel()
        super.onDestroy()
    }

    private fun publishDebug(message: String) {
        Log.d(LOG_TAG, message)
        EventBroadcaster.publishDebugLog(message)
    }

    companion object {
        private const val LOG_TAG = "ExpenseNotification"
    }
}
