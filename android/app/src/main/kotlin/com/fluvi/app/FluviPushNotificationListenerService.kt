package com.fluvi.app

import android.os.Bundle
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import com.fluvi.core.FluviCoreFactory
import com.fluvi.core.model.CapturedPushNotification
import com.fluvi.core.model.FluviPushCaptureResult
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * Captures notification snapshots only after Android has delivered them to the
 * listener. The privacy-safe diagnostic trail is intentionally written before
 * every early return, so an empty Inbox is explainable without logging a bank
 * message body.
 */
class FluviPushNotificationListenerService : NotificationListenerService() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun onListenerConnected() {
        super.onListenerConnected()
        FluviPushDiagnostics.listenerConnected(applicationContext)
    }

    override fun onListenerDisconnected() {
        FluviPushDiagnostics.listenerDisconnected(applicationContext)
        super.onListenerDisconnected()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName
        FluviPushDiagnostics.record(
            applicationContext,
            "LISTENER_RECEIVED",
            "Értesítés megérkezett a listenerhez.",
            packageName,
        )
        val notification = sbn.notification
        val extras = notification.extras
        if (extras == null) {
            FluviPushDiagnostics.record(applicationContext, "EMPTY_BODY", "Az értesítéshez nincs feldolgozható extra.", packageName)
            return
        }
        val body = extractBody(extras)
        if (body == null) {
            FluviPushDiagnostics.record(applicationContext, "EMPTY_BODY", "Az értesítésnek nincs feldolgozható szövege.", packageName)
            return
        }
        val title = extras.getCharSequence("android.title")?.toString()?.trim()?.takeIf(String::isNotEmpty)
        val ownProbeId = FluviPushDiagnostics.isCurrentOwnTest(
            applicationContext,
            packageName,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) notification.channelId else null,
            body,
        )
        FluviPushDiagnostics.record(
            applicationContext,
            "CONTENT_EXTRACTED",
            "Az értesítés szövege feldolgozható.",
            packageName,
            ownProbeId,
        )
        // A local Fluvi probe proves delivery only. It never enters the Inbox,
        // cannot match a banking rule and cannot create a financial entry.
        if (ownProbeId != null) {
            FluviPushDiagnostics.record(
                applicationContext,
                "SELF_TEST_RECEIVED",
                "A listener fogadta a saját tesztértesítést.",
                packageName,
                ownProbeId,
            )
            return
        }
        val label = runCatching {
            packageManager.getApplicationLabel(packageManager.getApplicationInfo(packageName, 0)).toString()
        }.getOrNull()
        scope.launch {
            val core = FluviCoreFactory.create(applicationContext)
            try {
                when (val result = core.automation.capture(
                    CapturedPushNotification(
                        packageName = packageName,
                        appLabel = label,
                        title = title,
                        text = body,
                        notificationKey = sbn.key,
                        receivedAtUtcMs = sbn.postTime,
                    ),
                )) {
                    FluviPushCaptureResult.IgnoredSource -> FluviPushDiagnostics.record(
                        applicationContext, "SOURCE_NOT_CONFIGURED", "A forráshoz nincs push profil.", packageName,
                    )
                    FluviPushCaptureResult.Paused -> FluviPushDiagnostics.record(
                        applicationContext, "PROFILE_PAUSED", "A forrás push profilja szünetel.", packageName,
                    )
                    is FluviPushCaptureResult.Duplicate -> FluviPushDiagnostics.record(
                        applicationContext, "DUPLICATE", "Az értesítés már korábban feldolgozásra került.", packageName,
                    )
                    is FluviPushCaptureResult.Stored -> {
                        FluviPushDiagnostics.record(applicationContext, "PROFILE_MATCHED", "A forrás push profilja illeszkedik.", packageName)
                        FluviPushDiagnostics.record(applicationContext, "INBOX_STORED", "Az értesítés bekerült az Inboxba.", packageName)
                    }
                    is FluviPushCaptureResult.ReviewRequired -> {
                        FluviPushDiagnostics.record(applicationContext, "PROFILE_MATCHED", "A forrás push profilja illeszkedik.", packageName)
                        FluviPushDiagnostics.record(applicationContext, "INBOX_STORED", "Az értesítés bekerült az Inboxba.", packageName)
                        FluviPushDiagnostics.record(applicationContext, "REVIEW_REQUIRED", "Az értesítés ellenőrzést igényel.", packageName)
                    }
                    is FluviPushCaptureResult.Booked -> {
                        FluviPushDiagnostics.record(applicationContext, "PROFILE_MATCHED", "A forrás push profilja illeszkedik.", packageName)
                        FluviPushDiagnostics.record(applicationContext, "INBOX_STORED", "Az értesítés bekerült az Inboxba.", packageName)
                        FluviPushDiagnostics.record(applicationContext, "BOOKED", "Az értesítésből tranzakció rögzült.", packageName)
                    }
                }
                FluviRecurrenceScheduler.scheduleNext(applicationContext, core)
            } catch (_: Throwable) {
                FluviPushDiagnostics.record(applicationContext, "CAPTURE_ERROR", "Az értesítés feldolgozása hibával leállt.", packageName)
            } finally {
                core.close()
            }
        }
    }

    private fun extractBody(extras: Bundle): String? {
        val lines = extras.getCharSequenceArray("android.textLines")
            ?.mapNotNull { it?.toString()?.trim()?.takeIf(String::isNotEmpty) }
            ?.joinToString("\n")
        return sequenceOf(
            extras.getCharSequence("android.bigText")?.toString(),
            extras.getCharSequence("android.text")?.toString(),
            lines,
            extras.getCharSequence("android.subText")?.toString(),
        ).mapNotNull { it?.trim()?.takeIf(String::isNotEmpty) }.firstOrNull()
    }

    override fun onDestroy() {
        scope.cancel()
        super.onDestroy()
    }
}
