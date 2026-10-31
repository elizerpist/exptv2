package com.fluvi.app

import android.Manifest
import android.app.Activity
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Base64
import java.io.ByteArrayOutputStream
import java.util.UUID

/**
 * Android-only permission, application-directory and test-notification boundary.
 * Notification contents never cross this class; diagnostics store only state
 * transitions, package names and probe ids.
 */
internal class FluviAutomationPlatform(private val activity: Activity) {
    fun permissionStatus(): Map<String, Any> = mapOf(
        "notificationListenerGranted" to notificationListenerGranted(),
        "postNotificationsGranted" to postNotificationsGranted(),
        "notificationListenerAvailable" to hasIntent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS),
        "appNotificationSettingsAvailable" to hasIntent(Settings.ACTION_APP_NOTIFICATION_SETTINGS),
        "appNotificationsEnabled" to notificationManager().areNotificationsEnabled(),
        "testChannelEnabled" to testChannelEnabled(notificationManager()),
        "listenerConnected" to (FluviPushDiagnostics.snapshot(activity)["listenerConnected"] as? Boolean ?: false),
    )

    fun openNotificationAccessSettings(): Boolean = start(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))

    fun openAppNotificationSettings(): Boolean = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        start(Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
            putExtra(Settings.EXTRA_APP_PACKAGE, activity.packageName)
        })
    } else openAppInfoSettings()

    fun openTestNotificationChannelSettings(): Boolean = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        start(Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS).apply {
            putExtra(Settings.EXTRA_APP_PACKAGE, activity.packageName)
            putExtra(Settings.EXTRA_CHANNEL_ID, TEST_CHANNEL)
        })
    } else openAppNotificationSettings()

    fun openAppInfoSettings(): Boolean = start(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
        data = Uri.fromParts("package", activity.packageName, null)
    })

    /** MainActivity resolves the actual Android runtime-permission callback. */
    fun requestPostNotifications(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU || postNotificationsGranted()) return true
        activity.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_POST_NOTIFICATIONS)
        return true
    }

    /**
     * Submit a local probe notification. "submitted" means Android accepted
     * the request; a listener callback later advances it to LISTENER_RECEIVED.
     */
    fun sendTestNotification(): Map<String, Any?> {
        val probeId = UUID.randomUUID().toString().take(12)
        FluviPushDiagnostics.beginTest(activity, probeId)
        if (!postNotificationsGranted()) {
            FluviPushDiagnostics.record(activity, "POST_PERMISSION_DENIED", "A Fluvi saját értesítési jogosultsága hiányzik.", activity.packageName, probeId)
            return testResult("permissionDenied", probeId, "A Fluvi értesítési engedélye hiányzik.")
        }
        val manager = notificationManager()
        if (!manager.areNotificationsEnabled()) {
            FluviPushDiagnostics.record(activity, "POST_PERMISSION_DENIED", "A Fluvi rendszerértesítései le vannak tiltva.", activity.packageName, probeId)
            return testResult("appNotificationsDisabled", probeId, "A Fluvi értesítései ki vannak kapcsolva.")
        }
        ensureTestChannel(manager)
        if (!testChannelEnabled(manager)) {
            FluviPushDiagnostics.record(activity, "CHANNEL_DISABLED", "A Fluvi tesztértesítési csatornája ki van kapcsolva.", activity.packageName, probeId)
            return testResult("channelDisabled", probeId, "A tesztértesítési csatorna ki van kapcsolva.")
        }
        return runCatching {
            val text = "Azonosító: $probeId"
            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(activity, TEST_CHANNEL)
            } else Notification.Builder(activity)
            manager.notify(
                TEST_NOTIFICATION_ID,
                builder
                    .setSmallIcon(R.drawable.ic_stat_fluvi)
                    .setContentTitle("Fluvi tesztértesítés")
                    .setContentText(text)
                    .setStyle(Notification.BigTextStyle().bigText("A Fluvi saját tesztértesítése. $text"))
                    .setAutoCancel(true)
                    .setOnlyAlertOnce(true)
                    .build(),
            )
            FluviPushDiagnostics.record(activity, "POST_SUBMITTED", "A tesztértesítés küldési kérése átadva.", activity.packageName, probeId)
            testResult("submitted", probeId, "Küldési kérés átadva.")
        }.getOrElse { error ->
            FluviPushDiagnostics.record(activity, "CAPTURE_ERROR", "A tesztértesítés küldése natív hibával leállt.", activity.packageName, probeId)
            testResult("error", probeId, error.message ?: "A tesztértesítés küldése nem sikerült.")
        }
    }

    /**
     * Uses installed applications instead of launcher activities, therefore it
     * includes notification sources with no default launcher activity. Icons
     * are loaded separately on demand so hundreds of base64 PNGs cannot delay
     * the first usable picker frame.
     */
    fun listInstalledApps(): List<Map<String, Any>> = runCatching {
        val packageManager = activity.packageManager
        val installed = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getInstalledApplications(
                PackageManager.ApplicationInfoFlags.of(PackageManager.MATCH_DISABLED_COMPONENTS.toLong()),
            )
        } else {
            @Suppress("DEPRECATION") packageManager.getInstalledApplications(PackageManager.MATCH_DISABLED_COMPONENTS)
        }
        val mapped = installed.asSequence().map { info ->
            val label = runCatching { packageManager.getApplicationLabel(info).toString().trim() }
                .getOrDefault("").ifBlank { info.packageName }
            mapOf(
                "packageName" to info.packageName,
                "label" to label,
                "isSystemApp" to ((info.flags and ApplicationInfo.FLAG_SYSTEM) != 0),
                "enabled" to info.enabled,
            )
        }.sortedWith(
            compareBy<Map<String, Any>> { it["isSystemApp"] as Boolean }
                .thenBy { (it["label"] as String).lowercase() }
                .thenBy { it["packageName"] as String },
        ).toList()
        FluviPushDiagnostics.appList(activity, installed.size, mapped.size)
        mapped
    }.getOrElse { error ->
        FluviPushDiagnostics.appList(activity, 0, 0, error.javaClass.simpleName)
        throw error
    }

    fun installedAppIcon(packageName: String): String? = runCatching {
        val packageManager = activity.packageManager
        val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getApplicationInfo(packageName, PackageManager.ApplicationInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION") packageManager.getApplicationInfo(packageName, 0)
        }
        iconBase64(info)
    }.getOrNull()

    fun pushDiagnostics(): Map<String, Any?> {
        val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            activity.packageManager.getPackageInfo(activity.packageName, PackageManager.PackageInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION") activity.packageManager.getPackageInfo(activity.packageName, 0)
        }
        return FluviPushDiagnostics.snapshot(activity).toMutableMap().apply {
            put("androidApi", Build.VERSION.SDK_INT)
            put("buildVersion", packageInfo.versionName ?: "ismeretlen")
            put("buildCode", buildCode(packageInfo))
            putAll(permissionStatus())
        }
    }
    fun clearPushDiagnostics(): Boolean {
        FluviPushDiagnostics.clear(activity)
        return true
    }

    fun postNotificationsGranted(): Boolean = Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
        activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED

    private fun testResult(status: String, probeId: String, message: String): Map<String, Any?> = mapOf(
        "status" to status,
        "probeId" to probeId,
        "message" to message,
    )

    @Suppress("DEPRECATION")
    private fun buildCode(packageInfo: PackageInfo): Long = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
        packageInfo.longVersionCode
    } else {
        packageInfo.versionCode.toLong()
    }

    private fun notificationListenerGranted(): Boolean {
        val enabled = Settings.Secure.getString(activity.contentResolver, "enabled_notification_listeners") ?: return false
        val component = ComponentName(activity, FluviPushNotificationListenerService::class.java).flattenToString()
        return enabled.split(':').any { it == component }
    }

    private fun notificationManager(): NotificationManager = activity.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    private fun ensureTestChannel(manager: NotificationManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && manager.getNotificationChannel(TEST_CHANNEL) == null) {
            manager.createNotificationChannel(
                NotificationChannel(TEST_CHANNEL, "Fluvi tesztértesítések", NotificationManager.IMPORTANCE_DEFAULT).apply {
                    description = "A Fluvi saját értesítési jogosultságának ellenőrzése."
                },
            )
        }
    }

    private fun testChannelEnabled(manager: NotificationManager): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.O || manager.getNotificationChannel(TEST_CHANNEL)?.importance != NotificationManager.IMPORTANCE_NONE

    private fun hasIntent(action: String): Boolean = activity.packageManager.resolveActivity(Intent(action), 0) != null

    private fun start(intent: Intent): Boolean = runCatching {
        if (activity.packageManager.resolveActivity(intent, 0) == null) return@runCatching false
        activity.startActivity(intent)
        true
    }.getOrDefault(false)

    private fun iconBase64(info: ApplicationInfo): String {
        val drawable = activity.packageManager.getApplicationIcon(info)
        val width = 48
        val bitmap = Bitmap.createBitmap(width, width, Bitmap.Config.ARGB_8888)
        Canvas(bitmap).also { canvas -> drawable.setBounds(0, 0, width, width); drawable.draw(canvas) }
        return ByteArrayOutputStream().use { output ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, output)
            Base64.encodeToString(output.toByteArray(), Base64.NO_WRAP)
        }
    }

    internal companion object {
        const val REQUEST_POST_NOTIFICATIONS = 8051
        const val TEST_CHANNEL = "fluvi_test_notifications"
        const val TEST_NOTIFICATION_ID = 4051
    }
}
