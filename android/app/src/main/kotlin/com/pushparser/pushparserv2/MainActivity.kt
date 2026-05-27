package com.pushparser.pushparserv2

import android.Manifest
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterActivity() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val repository = NotificationEventRepository(this)
        val modeStore = CaptureModeStore(this)
        val statusReader = PermissionStatusReader(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pushparser/methods")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "loadEvents" -> scope.launch {
                        val events = withContext(Dispatchers.IO) {
                            repository.allEvents().map { it.toMap() }
                        }
                        result.success(events)
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
                    "requestPostNotifications" -> {
                        if (Build.VERSION.SDK_INT >= 33) {
                            ActivityCompat.requestPermissions(
                                this,
                                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                                REQUEST_POST_NOTIFICATIONS,
                            )
                        }
                        result.success(null)
                    }
                    "sendTestNotification" -> {
                        TestNotificationHelper(this).send()
                        result.success(null)
                    }
                    "clearDatabase" -> scope.launch {
                        withContext(Dispatchers.IO) { repository.clear() }
                        result.success(null)
                    }
                    else -> result.notImplemented()
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

    private fun installedApps(): List<Map<String, String>> {
        val launcherIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        val pm = packageManager
        val seenPackages = mutableSetOf<String>()

        return pm.queryIntentActivities(launcherIntent, 0)
            .mapNotNull { resolveInfo ->
                val applicationInfo = resolveInfo.activityInfo?.applicationInfo ?: return@mapNotNull null
                val packageName = applicationInfo.packageName
                if (packageName.isNullOrBlank() || !seenPackages.add(packageName)) {
                    return@mapNotNull null
                }
                mapOf(
                    "packageName" to packageName,
                    "label" to pm.getApplicationLabel(applicationInfo).toString(),
                )
            }
            .sortedWith(compareBy(String.CASE_INSENSITIVE_ORDER) { it["label"].orEmpty() })
    }

    companion object {
        private const val REQUEST_POST_NOTIFICATIONS = 42
    }
}
