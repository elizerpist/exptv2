package com.exptv2.app

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class PushAccessibilityService : AccessibilityService() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

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

        scope.launch {
            val saved = NotificationEventRepository(this@PushAccessibilityService)
                .insertDraft(draft)
            EventBroadcaster.publish(saved)
        }
    }

    override fun onInterrupt() = Unit
}
