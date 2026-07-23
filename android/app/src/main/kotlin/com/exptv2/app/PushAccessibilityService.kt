package com.exptv2.app

import android.accessibilityservice.AccessibilityService
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import kotlinx.coroutines.Dispatchers

class PushAccessibilityService : AccessibilityService() {
    private val scope = LifecycleCoroutineScope(Dispatchers.IO)

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        val mode = CaptureModeStore(this).getMode()
        if (!mode.allowsAccessibility()) return

        val packageName = event.packageName?.toString().orEmpty()
        if (packageName.isBlank()) return

        val textParts = event.text.mapNotNull { it?.toString() }.filter { it.isNotBlank() }
        val contentDescription = event.contentDescription?.toString().orEmpty()
        val title = textParts.firstOrNull().orEmpty()
        val body = (textParts.drop(1) + contentDescription)
            .filter { it.isNotBlank() }
            .distinct()
            .joinToString("\n")

        val draft = EventDraft(
            timestamp = event.eventTime.takeIf { it > 0 } ?: System.currentTimeMillis(),
            source = NotificationEventRepository.SOURCE_ACCESSIBILITY,
            packageName = packageName,
            title = title,
            text = body,
            accessibilityEventType = event.eventType.toString(),
        )

        scope.launchGuarded(
            reportFailure = { error ->
                val message =
                    "[PushParser] accessibility failed package=${draft.packageName} error=${error.message}"
                Log.e(LOG_TAG, message, error)
                EventBroadcaster.publishDebugLog(message)
            },
        ) {
            val saved = NotificationEventRepository(this@PushAccessibilityService)
                .insertDraft(draft)
            if (saved != null) EventBroadcaster.publish(saved)
        }
    }

    override fun onInterrupt() = Unit

    override fun onDestroy() {
        scope.cancel()
        super.onDestroy()
    }

    companion object {
        private const val LOG_TAG = "ExpenseNotification"
    }
}
