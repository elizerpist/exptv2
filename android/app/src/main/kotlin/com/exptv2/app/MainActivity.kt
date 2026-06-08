package com.exptv2.app

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Base64
import android.util.Log
import androidx.core.app.ActivityCompat
import com.exptv2.app.expense.ExpenseMethodChannel
import com.exptv2.app.expense.recurring.RecurringAlarmMethodChannel
import com.exptv2.app.expense.recurring.RecurringAlarmScheduler
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream

class MainActivity : FlutterFragmentActivity() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val repository = NotificationEventRepository(this)
        val modeStore = CaptureModeStore(this)
        val statusReader = PermissionStatusReader(this)
        val parserRuleStore = NotificationParserRuleStore(this)
        val expenseChannel = ExpenseMethodChannel(this, this, scope)
        val recurringAlarmScheduler = RecurringAlarmScheduler(this)
        RecurringAlarmMethodChannel(this, scope).attach(
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "exptv2/recurring_alarm"),
        )
        scope.launch(Dispatchers.IO) { recurringAlarmScheduler.sync() }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pushparser/methods")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "loadEvents" -> scope.launch {
                        val events = withContext(Dispatchers.IO) {
                            repository.allEvents().map { it.toMap() }
                        }
                        result.success(events)
                    }
                    "loadNotificationEventPage" -> scope.launch {
                        val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any?>()
                        val page = withContext(Dispatchers.IO) { repository.listPage(args).toMap() }
                        result.success(page)
                    }
                    "loadNotificationEvent" -> scope.launch {
                        val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any?>()
                        val id = (args["id"] as? Number)?.toLong()
                            ?: args["id"]?.toString()?.toLongOrNull()
                            ?: 0L
                        val row = withContext(Dispatchers.IO) { repository.eventById(id)?.toMap() }
                        result.success(row)
                    }
                    "markNotificationEventSystem" -> scope.launch {
                        val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any?>()
                        val id = (args["id"] as? Number)?.toLong()
                            ?: args["id"]?.toString()?.toLongOrNull()
                            ?: 0L
                        val updated = withContext(Dispatchers.IO) { repository.markSystem(id) }
                        result.success(updated)
                    }
                    "listInstalledApps" -> scope.launch {
                        val apps = withContext(Dispatchers.IO) { installedApps() }
                        result.success(apps)
                    }
                    "getStatus" -> scope.launch {
                        val status = withContext(Dispatchers.IO) {
                            statusReader.status(repository, modeStore)
                        }
                        result.success(status)
                    }
                    "setCaptureMode" -> {
                        val mode = CaptureMode.fromValue(call.arguments as? String)
                        modeStore.setMode(mode)
                        result.success(null)
                    }
                    "openNotificationAccessSettings" -> {
                        startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                        result.success(null)
                    }
                    "openAccessibilitySettings" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(null)
                    }
                    "openAppInfoSettings" -> {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.parse("package:$packageName")
                        }
                        startActivity(intent)
                        result.success(null)
                    }
                    "openAppNotificationSettings" -> {
                        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                            }
                        } else {
                            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = Uri.parse("package:$packageName")
                            }
                        }
                        startActivity(intent)
                        result.success(null)
                    }
                    "requestPostNotifications" -> {
                        requestPostNotificationsPermission()
                        result.success(null)
                    }
                    "requestPostNotificationsOnFirstLaunch" -> {
                        result.success(requestPostNotificationsOnFirstLaunch())
                    }
                    "sendTestNotification" -> {
                        TestNotificationHelper(this).send()
                        result.success(null)
                    }
                    "clearDatabase" -> scope.launch {
                        withContext(Dispatchers.IO) { repository.clear() }
                        result.success(null)
                    }
                    "loadNotificationParserProfiles" -> scope.launch {
                        val profiles = withContext(Dispatchers.IO) {
                            parserRuleStore.loadProfiles()
                        }
                        result.success(profiles)
                    }
                    "saveNotificationParserProfiles" -> scope.launch {
                        val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any?>()
                        val profiles = withContext(Dispatchers.IO) {
                            parserRuleStore.saveProfiles(args)
                        }
                        result.success(profiles)
                    }
                    "loadNotificationParserRule" -> scope.launch {
                        val rule = withContext(Dispatchers.IO) { parserRuleStore.load() }
                        result.success(rule)
                    }
                    "saveNotificationParserRule" -> scope.launch {
                        val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any?>()
                        val rule = withContext(Dispatchers.IO) { parserRuleStore.save(args) }
                        result.success(rule)
                    }
                    "loadAutomaticPushParserEnabled" -> scope.launch {
                        val enabled = withContext(Dispatchers.IO) {
                            parserRuleStore.automaticPushParserEnabled()
                        }
                        result.success(enabled)
                    }
                    "saveAutomaticPushParserEnabled" -> scope.launch {
                        val enabled = call.arguments as? Boolean ?: true
                        val saved = withContext(Dispatchers.IO) {
                            parserRuleStore.setAutomaticPushParserEnabled(enabled)
                        }
                        result.success(saved)
                    }
                    else -> {
                        if (!expenseChannel.handle(call, result)) {
                            result.notImplemented()
                        }
                    }
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "pushparser/events")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    EventBroadcaster.attach(events)
                }

                override fun onCancel(arguments: Any?) {
                    EventBroadcaster.detach()
                }
            })
    }

    private fun requestPostNotificationsOnFirstLaunch(): Boolean {
        val prefs = getSharedPreferences(
            NOTIFICATION_PERMISSION_PREFS,
            Context.MODE_PRIVATE,
        )
        if (prefs.getBoolean(POST_NOTIFICATIONS_ONBOARDING_REQUESTED, false)) {
            return false
        }
        prefs.edit()
            .putBoolean(POST_NOTIFICATIONS_ONBOARDING_REQUESTED, true)
            .apply()
        return requestPostNotificationsPermission()
    }

    private fun requestPostNotificationsPermission(): Boolean {
        if (Build.VERSION.SDK_INT < 33) {
            return false
        }
        if (ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS,
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            return false
        }
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            REQUEST_POST_NOTIFICATIONS,
        )
        return true
    }

    private fun installedApps(): List<Map<String, String>> {
        val pm = packageManager
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            PackageManager.MATCH_DISABLED_COMPONENTS
        } else {
            @Suppress("DEPRECATION")
            PackageManager.GET_DISABLED_COMPONENTS
        }
        val applications = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getInstalledApplications(PackageManager.ApplicationInfoFlags.of(flags.toLong()))
        } else {
            @Suppress("DEPRECATION")
            pm.getInstalledApplications(flags)
        }

        val filtered = applications
            .filter { app -> InstalledAppFilter.shouldShow(app.packageName, app.flags) }
        val message = "[AppPicker] installed apps raw=${applications.size} filtered=${filtered.size}"
        Log.d("ExpenseNotification", message)
        EventBroadcaster.publishDebugLog(message)

        return filtered
            .map { app ->
                mapOf(
                    "packageName" to app.packageName,
                    "label" to app.safeLabel(pm),
                    "iconBase64" to app.safeIconBase64(pm),
                )
            }
            .sortedWith { left, right ->
                val labelCompare = left["label"].orEmpty()
                    .compareTo(right["label"].orEmpty(), ignoreCase = true)
                if (labelCompare != 0) {
                    labelCompare
                } else {
                    left["packageName"].orEmpty()
                        .compareTo(right["packageName"].orEmpty(), ignoreCase = true)
                }
            }
    }

    private fun ApplicationInfo.safeLabel(pm: PackageManager): String {
        return runCatching { pm.getApplicationLabel(this).toString() }
            .getOrDefault(packageName)
    }

    private fun ApplicationInfo.safeIconBase64(pm: PackageManager): String {
        return runCatching { pm.getApplicationIcon(this).toPngBase64() }
            .getOrDefault("")
    }

    private fun Drawable.toPngBase64(): String {
        val bitmap = Bitmap.createBitmap(APP_ICON_SIZE, APP_ICON_SIZE, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val previousBounds = copyBounds()
        setBounds(0, 0, canvas.width, canvas.height)
        draw(canvas)
        setBounds(previousBounds)

        val output = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, output)
        return Base64.encodeToString(output.toByteArray(), Base64.NO_WRAP)
    }

    companion object {
        private const val REQUEST_POST_NOTIFICATIONS = 42
        private const val APP_ICON_SIZE = 96
        private const val NOTIFICATION_PERMISSION_PREFS =
            "notification_permission_onboarding"
        private const val POST_NOTIFICATIONS_ONBOARDING_REQUESTED =
            "post_notifications_onboarding_requested"
    }
}
