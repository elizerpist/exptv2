package com.exptv2.app

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.ComponentName
import android.content.Context
import android.provider.Settings
import android.view.accessibility.AccessibilityManager

class PermissionStatusReader(private val context: Context) {
    fun isNotificationListenerEnabled(): Boolean {
        val enabled = Settings.Secure.getString(
            context.contentResolver,
            "enabled_notification_listeners",
        ) ?: return false
        val expected = ComponentName(
            context,
            PushNotificationListenerService::class.java,
        ).flattenToString()
        return enabled.split(':').any { it.equals(expected, ignoreCase = true) }
    }

    fun isAccessibilityEnabled(): Boolean {
        val manager = context.getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        val enabledServices = manager.getEnabledAccessibilityServiceList(
            AccessibilityServiceInfo.FEEDBACK_ALL_MASK,
        )
        val expected = ComponentName(context, PushAccessibilityService::class.java)
        return enabledServices.any { info ->
            val serviceInfo = info.resolveInfo.serviceInfo
            ComponentName(serviceInfo.packageName, serviceInfo.name) == expected
        }
    }

    suspend fun status(
        repository: NotificationEventRepository,
        modeStore: CaptureModeStore,
    ): Map<String, Any?> {
        val mode = modeStore.getMode()
        val notificationEnabled = isNotificationListenerEnabled()
        val accessibilityEnabled = isAccessibilityEnabled()
        return mapOf(
            "captureMode" to mode.value,
            "notificationListenerEnabled" to notificationEnabled,
            "accessibilityEnabled" to accessibilityEnabled,
            "notificationListenerActive" to (notificationEnabled && mode.allowsNotificationListener()),
            "accessibilityActive" to (accessibilityEnabled && mode.allowsAccessibility()),
            "lastNotificationListenerEvent" to repository.lastNotificationListenerEvent(),
            "lastAccessibilityEvent" to repository.lastAccessibilityEvent(),
            "totalEvents" to repository.totalCount(),
        )
    }
}
