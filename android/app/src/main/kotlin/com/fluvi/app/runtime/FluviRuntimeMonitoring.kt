package com.fluvi.app.runtime

import android.Manifest
import android.app.Activity
import android.app.ActivityManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.graphics.drawable.Icon
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.service.notification.NotificationListenerService
import com.fluvi.app.FluviNotificationIconResolver
import com.fluvi.app.FluviPushNotificationListenerService
import com.fluvi.app.MainActivity

/**
 * Persistent user intent for notification monitoring. It deliberately lives
 * outside dashboard presentation preferences: this state must be usable while
 * Flutter and every Activity are absent.
 */
internal data class FluviRuntimePreferences(
    val foregroundRequested: Boolean = false,
    val backgroundRequested: Boolean = false,
    val stoppedByUser: Boolean = false,
)

internal data class FluviRuntimeStatus(
    val foregroundRequested: Boolean,
    val backgroundRequested: Boolean,
    val foregroundServiceRunning: Boolean,
    val notificationListenerGranted: Boolean,
    val listenerConnected: Boolean,
    val postNotificationsGranted: Boolean,
    val statusChannelEnabled: Boolean,
    val appSurfaceVisible: Boolean,
    val stoppedByUser: Boolean,
    val captureAllowed: Boolean,
    val state: String,
    val message: String,
    val lastReceivedAtUtcMs: Long?,
    val lastProcessedAtUtcMs: Long?,
    val lastWidgetRefreshAtUtcMs: Long?,
    val lockScreenCardEnabled: Boolean,
    val lockScreenCardValid: Boolean,
    val lockScreenCardPrivacy: String,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "foregroundRequested" to foregroundRequested,
        "backgroundRequested" to backgroundRequested,
        "foregroundServiceRunning" to foregroundServiceRunning,
        "notificationListenerGranted" to notificationListenerGranted,
        "listenerConnected" to listenerConnected,
        "postNotificationsGranted" to postNotificationsGranted,
        "statusChannelEnabled" to statusChannelEnabled,
        "appSurfaceVisible" to appSurfaceVisible,
        "stoppedByUser" to stoppedByUser,
        "captureAllowed" to captureAllowed,
        "state" to state,
        "message" to message,
        "lastReceivedAtUtcMs" to lastReceivedAtUtcMs,
        "lastProcessedAtUtcMs" to lastProcessedAtUtcMs,
        "lastWidgetRefreshAtUtcMs" to lastWidgetRefreshAtUtcMs,
        "lockScreenCardEnabled" to lockScreenCardEnabled,
        "lockScreenCardValid" to lockScreenCardValid,
        "lockScreenCardPrivacy" to lockScreenCardPrivacy,
    )
}

internal data class RuntimeMonitoringEvaluation(
    val captureAllowed: Boolean,
    val state: String,
    val message: String,
)

/** Pure policy used by the coordinator and native regression tests. */
internal object RuntimeMonitoringPolicy {
    fun evaluate(
        preferences: FluviRuntimePreferences,
        listenerGranted: Boolean,
        foregroundServiceRunning: Boolean,
        foregroundStartFailed: Boolean,
        postNotificationsGranted: Boolean,
        statusChannelEnabled: Boolean,
        appSurfaceVisible: Boolean,
        listenerConnected: Boolean,
    ): RuntimeMonitoringEvaluation {
        val captureAllowed = !preferences.stoppedByUser && listenerGranted &&
            (appSurfaceVisible || preferences.backgroundRequested || foregroundServiceRunning)
        val (state, message) = when {
            preferences.stoppedByUser -> "stopped" to "Felhasználó által leállítva"
            !preferences.foregroundRequested && !preferences.backgroundRequested && !appSurfaceVisible ->
                "off" to "Kikapcsolva"
            !listenerGranted -> "notificationAccessRequired" to "Értesítési hozzáférés szükséges"
            preferences.foregroundRequested && foregroundStartFailed ->
                "foregroundStartFailed" to "A rendszer nem engedte az előtérszolgáltatás indítását"
            preferences.foregroundRequested && !foregroundServiceRunning ->
                "foregroundStarting" to "Előtérszolgáltatás indítása folyamatban"
            preferences.foregroundRequested && foregroundServiceRunning && !postNotificationsGranted ->
                "activeWithoutStatusNotification" to "Előtérszolgáltatás aktív, az állapotértesítések tiltva vannak"
            preferences.foregroundRequested && foregroundServiceRunning && !statusChannelEnabled ->
                "activeStatusChannelDisabled" to "Előtérszolgáltatás aktív, a háttérfigyelési csatorna ki van kapcsolva"
            preferences.foregroundRequested && foregroundServiceRunning ->
                "active" to "Előtérszolgáltatás aktív"
            (preferences.foregroundRequested || preferences.backgroundRequested) && !postNotificationsGranted ->
                "statusNotificationsDisabled" to "Az állapotértesítések megjelenítése tiltva"
            (preferences.foregroundRequested || preferences.backgroundRequested) && !statusChannelEnabled ->
                "statusChannelDisabled" to "A háttérfigyelési értesítési csatorna ki van kapcsolva"
            preferences.backgroundRequested && listenerConnected ->
                "active" to "Háttérfigyelés aktív"
            preferences.backgroundRequested ->
                "listenerConnecting" to "Kapcsolódás az Android értesítésfigyelőjéhez"
            appSurfaceVisible -> "active" to "Figyelés a megnyitott Fluvi felületén"
            else -> "off" to "Kikapcsolva"
        }
        return RuntimeMonitoringEvaluation(captureAllowed, state, message)
    }
}

/**
 * Single activity-independent authority for the two runtime switches. The
 * notification listener remains Android-owned; an optional foreground service
 * only represents an explicitly requested monitoring session and never starts
 * a second capture pipeline.
 */
internal object FluviRuntimeCoordinator {
    private const val PREFERENCES = "fluvi_runtime_monitoring"
    private const val FOREGROUND_REQUESTED = "foregroundRequested"
    private const val BACKGROUND_REQUESTED = "backgroundRequested"
    private const val STOPPED_BY_USER = "stoppedByUser"
    private const val LAST_RECEIVED = "lastReceivedAtUtcMs"
    private const val LAST_PROCESSED = "lastProcessedAtUtcMs"
    private const val LAST_WIDGET_REFRESH = "lastWidgetRefreshAtUtcMs"
    private const val LAST_HANDLED_USER_STOP = "lastHandledUserStopUtcMs"

    @Volatile private var appSurfaceVisible: Boolean = false
    @Volatile private var listenerConnected: Boolean = false
    @Volatile private var foregroundServiceRunning: Boolean = false
    @Volatile private var foregroundStartFailed: Boolean = false

    fun status(context: Context): FluviRuntimeStatus {
        val preferenceStore = preferences(context)
        val preferences = preferenceStore.read()
        val lockScreenCard = FluviLockScreenCardCoordinator.configuration(context)
        val listenerGranted = notificationListenerGranted(context)
        val postGranted = postNotificationsGranted(context)
        val channelEnabled = FluviRuntimeNotificationController.statusChannelEnabled(context)
        val evaluation = RuntimeMonitoringPolicy.evaluate(
            preferences = preferences,
            listenerGranted = listenerGranted,
            foregroundServiceRunning = foregroundServiceRunning,
            foregroundStartFailed = foregroundStartFailed,
            postNotificationsGranted = postGranted,
            statusChannelEnabled = channelEnabled,
            appSurfaceVisible = appSurfaceVisible,
            listenerConnected = listenerConnected,
        )
        return FluviRuntimeStatus(
            foregroundRequested = preferences.foregroundRequested,
            backgroundRequested = preferences.backgroundRequested,
            foregroundServiceRunning = foregroundServiceRunning,
            notificationListenerGranted = listenerGranted,
            listenerConnected = listenerConnected,
            postNotificationsGranted = postGranted,
            statusChannelEnabled = channelEnabled,
            appSurfaceVisible = appSurfaceVisible,
            stoppedByUser = preferences.stoppedByUser,
            captureAllowed = evaluation.captureAllowed,
            state = evaluation.state,
            message = evaluation.message,
            lastReceivedAtUtcMs = preferenceStore.store.getLong(LAST_RECEIVED, 0).takeIf { it > 0 },
            lastProcessedAtUtcMs = preferenceStore.store.getLong(LAST_PROCESSED, 0).takeIf { it > 0 },
            lastWidgetRefreshAtUtcMs = preferenceStore.store.getLong(LAST_WIDGET_REFRESH, 0).takeIf { it > 0 },
            lockScreenCardEnabled = lockScreenCard.enabled,
            lockScreenCardValid = lockScreenCard.isValid,
            lockScreenCardPrivacy = lockScreenCard.privacy.name,
        )
    }

    fun setForegroundRequested(context: Context, requested: Boolean): FluviRuntimeStatus {
        foregroundStartFailed = false
        preferences(context).write { putBoolean(FOREGROUND_REQUESTED, requested) }
        if (requested) clearStopped(context)
        reconcile(context, allowForegroundStart = requested)
        return status(context)
    }

    fun setBackgroundRequested(context: Context, requested: Boolean): FluviRuntimeStatus {
        preferences(context).write { putBoolean(BACKGROUND_REQUESTED, requested) }
        if (requested) clearStopped(context)
        reconcile(context, allowForegroundStart = false)
        return status(context)
    }

    fun stopMonitoring(context: Context): FluviRuntimeStatus {
        preferences(context).write {
            putBoolean(FOREGROUND_REQUESTED, false)
            putBoolean(BACKGROUND_REQUESTED, false)
            putBoolean(STOPPED_BY_USER, true)
        }
        foregroundServiceRunning = false
        foregroundStartFailed = false
        context.stopService(Intent(context, FluviMonitoringForegroundService::class.java))
        requestListenerUnbind(context)
        FluviRuntimeNotificationController.reconcileVisible(context, status(context))
        return status(context)
    }

    fun onAppSurfaceVisibilityChanged(context: Context, visible: Boolean) {
        appSurfaceVisible = visible
        // A restored foreground request may only restart from this visible UI
        // transition, never from an arbitrary background callback.
        reconcile(context, allowForegroundStart = visible)
    }

    /**
     * Android's Task Manager Stop kills the process without a callback. On the
     * next legitimate UI entry, honour a newer USER_REQUESTED exit instead of
     * silently reviving the requested foreground/background session.
     */
    fun reconcileHistoricalUserStop(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return
        val store = preferences(context)
        val exit = (context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager)
            .getHistoricalProcessExitReasons(null, 0, 1)
            .firstOrNull { it.reason == android.app.ApplicationExitInfo.REASON_USER_REQUESTED }
            ?: return
        if (exit.timestamp <= store.store.getLong(LAST_HANDLED_USER_STOP, 0)) return
        store.write {
            putLong(LAST_HANDLED_USER_STOP, exit.timestamp)
            putBoolean(FOREGROUND_REQUESTED, false)
            putBoolean(BACKGROUND_REQUESTED, false)
            putBoolean(STOPPED_BY_USER, true)
        }
        foregroundServiceRunning = false
    }

    fun onListenerConnected(context: Context) {
        listenerConnected = true
        reconcile(context, allowForegroundStart = false)
    }

    fun onListenerDisconnected(context: Context) {
        listenerConnected = false
        FluviRuntimeNotificationController.publish(context, status(context))
    }

    fun onForegroundServiceChanged(context: Context, running: Boolean) {
        foregroundServiceRunning = running
        if (running) foregroundStartFailed = false
        FluviRuntimeNotificationController.publish(context, status(context))
    }

    fun onNotificationReceived(context: Context) {
        preferences(context).write { putLong(LAST_RECEIVED, System.currentTimeMillis()) }
        FluviRuntimeNotificationController.publish(context, status(context))
    }

    fun onNotificationProcessed(context: Context) {
        preferences(context).write { putLong(LAST_PROCESSED, System.currentTimeMillis()) }
        FluviRuntimeNotificationController.publish(context, status(context))
    }

    fun onWidgetRefreshRequested(context: Context) {
        preferences(context).write { putLong(LAST_WIDGET_REFRESH, System.currentTimeMillis()) }
        FluviRuntimeNotificationController.publish(context, status(context))
    }

    /** True only for a live system listener callback that may enter Core. */
    fun mayCapture(context: Context): Boolean = status(context).captureAllowed

    fun applyRecentsVisibility(activity: Activity) {
        val exclude = preferences(activity).read().backgroundRequested
        val manager = activity.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        manager.appTasks
            .firstOrNull { it.taskInfo?.baseIntent?.component?.packageName == activity.packageName }
            ?.setExcludeFromRecents(exclude)
    }

    fun reconcile(context: Context, allowForegroundStart: Boolean) {
        val settings = preferences(context).read()
        if (settings.foregroundRequested && !settings.stoppedByUser && allowForegroundStart) {
            runCatching {
                val intent = Intent(context, FluviMonitoringForegroundService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            }.onFailure {
                foregroundServiceRunning = false
                foregroundStartFailed = true
            }
        } else if (!settings.foregroundRequested || settings.stoppedByUser) {
            context.stopService(Intent(context, FluviMonitoringForegroundService::class.java))
            foregroundServiceRunning = false
        }

        if (notificationListenerGranted(context) && !settings.stoppedByUser &&
            (appSurfaceVisible || settings.backgroundRequested || foregroundServiceRunning) &&
            !listenerConnected
        ) {
            requestListenerRebind(context)
        } else if (!appSurfaceVisible) {
            requestListenerUnbind(context)
        }

        if (settings.foregroundRequested || settings.backgroundRequested ||
            FluviLockScreenCardCoordinator.configuration(context).enabled
        ) {
            FluviRuntimeNotificationController.publish(context, status(context))
        } else {
            FluviRuntimeNotificationController.cancel(context)
        }
    }

    internal fun resetEphemeralState() {
        appSurfaceVisible = false
        listenerConnected = false
        foregroundServiceRunning = false
        foregroundStartFailed = false
    }

    private fun clearStopped(context: Context) = preferences(context).write {
        putBoolean(STOPPED_BY_USER, false)
    }

    private fun preferences(context: Context): RuntimePreferencesStore = RuntimePreferencesStore(
        context.applicationContext.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE),
    )

    private fun notificationListenerGranted(context: Context): Boolean {
        val enabled = Settings.Secure.getString(
            context.contentResolver,
            "enabled_notification_listeners",
        ) ?: return false
        val component = ComponentName(context, FluviPushNotificationListenerService::class.java)
            .flattenToString()
        return enabled.split(':').any { it == component }
    }

    private fun postNotificationsGranted(context: Context): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED

    private fun requestListenerRebind(context: Context) = runCatching {
        NotificationListenerService.requestRebind(
            ComponentName(context, FluviPushNotificationListenerService::class.java),
        )
    }

    private fun requestListenerUnbind(context: Context) = runCatching {
        NotificationListenerService.requestUnbind(
            ComponentName(context, FluviPushNotificationListenerService::class.java),
        )
    }
}

private class RuntimePreferencesStore(val store: SharedPreferences) {
    fun read(): FluviRuntimePreferences = FluviRuntimePreferences(
        foregroundRequested = store.getBoolean("foregroundRequested", false),
        backgroundRequested = store.getBoolean("backgroundRequested", false),
        stoppedByUser = store.getBoolean("stoppedByUser", false),
    )

    fun write(block: SharedPreferences.Editor.() -> Unit) {
        store.edit().apply(block).apply()
    }
}

internal object FluviRuntimeNotificationController {
    const val CHANNEL_ID = "fluvi_runtime_status"
    private const val NOTIFICATION_ID = 4052
    const val ACTION_STOP = "com.fluvi.app.runtime.STOP"
    const val ACTION_OPEN = "com.fluvi.app.runtime.OPEN"

    fun notification(
        context: Context,
        status: FluviRuntimeStatus,
        originalPostTimeUtcMs: Long? = null,
    ): Notification {
        ensureChannel(context)
        val lockScreen = FluviLockScreenCardCoordinator.configuration(context)
        if (lockScreen.enabled) {
            return lockScreenNotification(context, status, lockScreen, originalPostTimeUtcMs)
        }
        val content = when {
            status.foregroundRequested && status.foregroundServiceRunning -> "Előtérszolgáltatás aktív"
            status.backgroundRequested && status.notificationListenerGranted -> status.lastProcessedAtUtcMs
                ?.let { "Engedélyezve · utolsó feldolgozás: ${android.text.format.DateFormat.format("HH:mm", it)}" }
                ?: "Engedélyezve"
            else -> status.message
        }
        val open = PendingIntent.getActivity(
            context,
            4052,
            Intent(context, MainActivity::class.java).apply {
                action = ACTION_OPEN
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val stop = PendingIntent.getBroadcast(
            context,
            4053,
            Intent(context, FluviRuntimeActionReceiver::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val publicVersionBuilder = builder(context)
            .setSmallIcon(FluviNotificationIconResolver.smallIconRes(context))
            .setContentTitle("Fluvi · Háttérfigyelés engedélyezve")
            .setContentText("A Fluvi figyelési állapota aktív.")
            .setCategory(Notification.CATEGORY_SERVICE)
        originalPostTimeUtcMs?.let(publicVersionBuilder::setWhen)
        val publicVersion = publicVersionBuilder.build()
        val notificationBuilder = builder(context)
            .setSmallIcon(FluviNotificationIconResolver.smallIconRes(context))
            .setContentTitle(
                if (status.foregroundRequested) "Fluvi · Értesítésfigyelés" else "Fluvi · Háttérfigyelés",
            )
            .setContentText(content)
            .setStyle(Notification.BigTextStyle().bigText(content))
            .setCategory(Notification.CATEGORY_SERVICE)
            .setOnlyAlertOnce(true)
            .setOngoing(status.foregroundRequested && status.foregroundServiceRunning)
            .setVisibility(Notification.VISIBILITY_PRIVATE)
            .setPublicVersion(publicVersion)
            .setContentIntent(open)
            .addAction(
                Notification.Action.Builder(
                    Icon.createWithResource(
                        context,
                        FluviNotificationIconResolver.smallIconRes(context),
                    ),
                    "Figyelés leállítása",
                    stop,
                ).build(),
            )
        originalPostTimeUtcMs?.let(notificationBuilder::setWhen)
        return notificationBuilder.build()
    }

    fun publish(context: Context, status: FluviRuntimeStatus) {
        if (!status.foregroundRequested && !status.backgroundRequested && !status.lockScreenCardEnabled) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) return
        (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
            .notify(NOTIFICATION_ID, notification(context, status))
    }

    fun cancel(context: Context) {
        (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
            .cancel(NOTIFICATION_ID)
    }

    /** Applies the single visible-notification decision after a switch change:
     * a standalone financial card survives monitoring shutdown, while an off
     * card never revives a monitoring-only notification. */
    fun reconcileVisible(context: Context, status: FluviRuntimeStatus) {
        if (status.foregroundRequested || status.backgroundRequested || status.lockScreenCardEnabled) {
            publish(context, status)
        } else {
            cancel(context)
        }
    }

    /** Updates only an existing status notification, never reviving one. */
    fun refreshVisibleIcon(context: Context) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val active = manager.activeNotifications.firstOrNull { notification ->
            notification.packageName == context.packageName &&
                notification.id == NOTIFICATION_ID &&
                (Build.VERSION.SDK_INT < Build.VERSION_CODES.O ||
                    notification.notification.channelId == CHANNEL_ID)
        } ?: return
        val replacement = notification(
            context,
            FluviRuntimeCoordinator.status(context),
            originalPostTimeUtcMs = active.postTime,
        )
        if (active.tag == null) {
            manager.notify(NOTIFICATION_ID, replacement)
        } else {
            manager.notify(active.tag, NOTIFICATION_ID, replacement)
        }
    }

    fun statusChannelEnabled(context: Context): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.O ||
            (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                .getNotificationChannel(CHANNEL_ID)?.importance != NotificationManager.IMPORTANCE_NONE

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) == null) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "Háttérfigyelés állapota",
                    NotificationManager.IMPORTANCE_LOW,
                ).apply {
                    description = "A Fluvi értesítésfigyelésének állapota."
                    setSound(null, null)
                    enableVibration(false)
                    setShowBadge(false)
                    lockscreenVisibility = Notification.VISIBILITY_PRIVATE
                },
            )
        }
    }

    private fun lockScreenNotification(
        context: Context,
        status: FluviRuntimeStatus,
        configuration: FluviLockScreenCardConfiguration,
        originalPostTimeUtcMs: Long?,
    ): Notification {
        val content = FluviLockScreenCardContentStore(context).read()
        val isFull = configuration.privacy == FluviLockScreenCardConfiguration.Privacy.full &&
            content != null && configuration.isValid
        val open = PendingIntent.getActivity(
            context,
            4052,
            Intent(context, MainActivity::class.java).apply {
                action = ACTION_OPEN
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val discreetEvent = content?.event?.substringAfterLast("·")?.trim()
        val discreetText = discreetEvent?.takeIf { it.matches(Regex("[0-2][0-9]:[0-5][0-9]")) }
            ?.let { "Új tranzakció könyvelve · $it" }
            ?: "Nincs új könyvelt tranzakció"
        val publicVersion = builder(context)
            .setSmallIcon(FluviNotificationIconResolver.smallIconRes(context))
            .setContentTitle("Fluvi · Pénzügyi pillanatkép")
            .setContentText(discreetText)
            .setStyle(Notification.BigTextStyle().bigText(discreetText))
            .setCategory(Notification.CATEGORY_SERVICE)
            .setVisibility(Notification.VISIBILITY_PRIVATE)
        originalPostTimeUtcMs?.let(publicVersion::setWhen)
        val title = if (isFull) content!!.focus else "Fluvi · Pénzügyi pillanatkép"
        val text = if (isFull) content!!.primary else discreetText
        val expanded = if (isFull) buildString {
            append(content!!.secondary)
            content.event?.let { event ->
                append("\n")
                append(content.eventLabel ?: "Utolsó könyvelt tranzakció")
                append(": ")
                append(event)
            }
            monitoringExpansion(status)?.let { state -> append("\nFigyelés: ").append(state) }
        } else monitoringExpansion(status)?.let { "$discreetText\nFigyelés: $it" } ?: discreetText
        val notification = builder(context)
            .setSmallIcon(FluviNotificationIconResolver.smallIconRes(context))
            .setContentTitle(title)
            .setContentText(text)
            .setStyle(Notification.BigTextStyle().bigText(expanded))
            .setCategory(Notification.CATEGORY_SERVICE)
            .setOnlyAlertOnce(true)
            .setOngoing(status.foregroundRequested && status.foregroundServiceRunning)
            .setVisibility(Notification.VISIBILITY_PRIVATE)
            .setPublicVersion(publicVersion.build())
            .setContentIntent(open)
        if (isFull) notification.setLargeIcon(content!!.orbBitmap())
        if (status.foregroundRequested || status.backgroundRequested) {
            notification.addAction(stopAction(context))
        }
        originalPostTimeUtcMs?.let(notification::setWhen)
        return notification.build()
    }

    private fun monitoringExpansion(status: FluviRuntimeStatus): String? = when {
        status.foregroundRequested || status.backgroundRequested -> status.message
        else -> null
    }

    private fun stopAction(context: Context): Notification.Action = Notification.Action.Builder(
        Icon.createWithResource(context, FluviNotificationIconResolver.smallIconRes(context)),
        "Figyelés leállítása",
        PendingIntent.getBroadcast(
            context,
            4053,
            Intent(context, FluviRuntimeActionReceiver::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        ),
    ).build()

    private fun builder(context: Context): Notification.Builder =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            Notification.Builder(context)
        }

    fun notificationId(): Int = NOTIFICATION_ID
}

/** User-started status companion. It never receives notification payloads. */
internal class FluviMonitoringForegroundService : Service() {
    override fun onCreate() {
        super.onCreate()
        val status = FluviRuntimeCoordinator.status(applicationContext)
        val notification = FluviRuntimeNotificationController.notification(applicationContext, status)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                FluviRuntimeNotificationController.notificationId(),
                notification,
                if (Build.VERSION.SDK_INT >= 34) android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE else 0,
            )
        } else {
            startForeground(FluviRuntimeNotificationController.notificationId(), notification)
        }
        FluviRuntimeCoordinator.onForegroundServiceChanged(applicationContext, true)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val status = FluviRuntimeCoordinator.status(applicationContext)
        val notification = FluviRuntimeNotificationController.notification(applicationContext, status)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                FluviRuntimeNotificationController.notificationId(),
                notification,
                if (Build.VERSION.SDK_INT >= 34) android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE else 0,
            )
        } else {
            startForeground(FluviRuntimeNotificationController.notificationId(), notification)
        }
        FluviRuntimeCoordinator.onForegroundServiceChanged(applicationContext, true)
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        FluviRuntimeCoordinator.onForegroundServiceChanged(applicationContext, false)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}

internal class FluviRuntimeActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == FluviRuntimeNotificationController.ACTION_STOP) {
            FluviRuntimeCoordinator.stopMonitoring(context)
        }
    }
}
