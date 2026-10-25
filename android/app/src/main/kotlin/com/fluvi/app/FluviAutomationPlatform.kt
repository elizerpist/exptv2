package com.fluvi.app

import android.Manifest
import android.app.Activity
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.os.Build
import android.provider.Settings
import android.net.Uri
import android.util.Base64
import java.io.ByteArrayOutputStream

/** Small, auditable Android boundary.  It never reads notification contents. */
internal class FluviAutomationPlatform(private val activity: Activity) {
    fun permissionStatus(): Map<String, Any> = mapOf(
        "notificationListenerGranted" to notificationListenerGranted(),
        "postNotificationsGranted" to postNotificationsGranted(),
        "notificationListenerAvailable" to hasIntent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS),
        "appNotificationSettingsAvailable" to hasIntent(Settings.ACTION_APP_NOTIFICATION_SETTINGS),
    )

    fun openNotificationAccessSettings(): Boolean = start(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))

    fun openAppNotificationSettings(): Boolean = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        start(Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
            putExtra(Settings.EXTRA_APP_PACKAGE, activity.packageName)
        })
    } else openAppInfoSettings()

    fun openAppInfoSettings(): Boolean = start(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
        data = Uri.fromParts("package", activity.packageName, null)
    })

    fun requestPostNotifications(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU || postNotificationsGranted()) return true
        activity.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_POST_NOTIFICATIONS)
        return true
    }

    fun sendTestNotification(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && !postNotificationsGranted()) return false
        val manager = activity.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(NotificationChannel(
                TEST_CHANNEL, "Fluvi tesztértesítések", NotificationManager.IMPORTANCE_DEFAULT,
            ).apply { description = "A Fluvi saját értesítési jogosultságának ellenőrzése." })
        }
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(activity, TEST_CHANNEL)
        } else Notification.Builder(activity)
        manager.notify(TEST_NOTIFICATION_ID, builder
            .setSmallIcon(activity.applicationInfo.icon)
            .setContentTitle("Fluvi tesztértesítés")
            .setContentText("A Fluvi saját értesítései működnek.")
            .setAutoCancel(true)
            .build())
        return true
    }

    /** Launcher-visible packages only; no QUERY_ALL_PACKAGES permission is used. */
    fun listInstalledApps(): List<Map<String, String>> {
        val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        return activity.packageManager.queryIntentActivities(launcher, PackageManager.MATCH_DEFAULT_ONLY)
            .asSequence()
            .map { it.activityInfo.applicationInfo }
            .distinctBy { it.packageName }
            .map { info ->
                val icon = runCatching { iconBase64(info) }.getOrNull()
                buildMap {
                    put("packageName", info.packageName)
                    put("label", activity.packageManager.getApplicationLabel(info).toString())
                    if (icon != null) put("iconPngBase64", icon)
                }
            }
            .sortedBy { it.getValue("label").lowercase() }
            .toList()
    }

    private fun notificationListenerGranted(): Boolean {
        val enabled = Settings.Secure.getString(activity.contentResolver, "enabled_notification_listeners") ?: return false
        val component = ComponentName(activity, FluviPushNotificationListenerService::class.java).flattenToString()
        return enabled.split(':').any { it == component }
    }

    private fun postNotificationsGranted(): Boolean = Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
        activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED

    private fun hasIntent(action: String): Boolean = activity.packageManager.resolveActivity(Intent(action), 0) != null

    private fun start(intent: Intent): Boolean = runCatching {
        if (activity.packageManager.resolveActivity(intent, 0) == null) return@runCatching false
        activity.startActivity(intent); true
    }.getOrDefault(false)

    private fun iconBase64(info: android.content.pm.ApplicationInfo): String {
        val drawable = activity.packageManager.getApplicationIcon(info)
        val width = 48
        val bitmap = Bitmap.createBitmap(width, width, Bitmap.Config.ARGB_8888)
        Canvas(bitmap).also { canvas -> drawable.setBounds(0, 0, width, width); drawable.draw(canvas) }
        return ByteArrayOutputStream().use { output ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, output)
            Base64.encodeToString(output.toByteArray(), Base64.NO_WRAP)
        }
    }

    private companion object {
        const val REQUEST_POST_NOTIFICATIONS = 8051
        const val TEST_CHANNEL = "fluvi_test_notifications"
        const val TEST_NOTIFICATION_ID = 4051
    }
}
