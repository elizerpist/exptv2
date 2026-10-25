package com.fluvi.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import com.fluvi.core.FluviCore
import com.fluvi.core.FluviCoreFactory
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

/**
 * One-shot, persisted-alarm scheduler for due TIME occurrences. The database
 * remains authoritative: every delivery reconciles all due snapshots, and the
 * unique occurrence-to-ledger link makes retries harmless.
 */
object FluviRecurrenceScheduler {
    private const val REQUEST_CODE = 741_903
    private const val ACTION_DUE = "com.fluvi.app.action.REALIZE_DUE_RECURRENCES"

    suspend fun scheduleNext(context: Context, core: FluviCore) {
        val manager = context.getSystemService(AlarmManager::class.java) ?: return
        val pendingIntent = pendingIntent(context)
        manager.cancel(pendingIntent)
        val nextAtUtcMs = core.recurrences.nextActiveTimeOccurrenceAtUtcMs() ?: return
        val triggerAt = nextAtUtcMs.coerceAtLeast(System.currentTimeMillis())
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // Inexact allow-while-idle is intentional: Android may defer this
            // alarm, then the receiver reconciles due work atomically.
            manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
        } else {
            manager.set(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
        }
    }

    fun scheduleNextFromFreshCore(context: Context) {
        CoroutineScope(SupervisorJob() + Dispatchers.IO).launch {
            val core = FluviCoreFactory.create(context.applicationContext)
            try {
                scheduleNext(context.applicationContext, core)
            } finally {
                core.close()
            }
        }
    }

    private fun pendingIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context,
        REQUEST_CODE,
        Intent(context, FluviRecurrenceDueReceiver::class.java).setAction(ACTION_DUE),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
}

/** Runs out of process or after idle delay without relying on Flutter being alive. */
class FluviRecurrenceDueReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val pending = goAsync()
        CoroutineScope(SupervisorJob() + Dispatchers.IO).launch {
            val core = FluviCoreFactory.create(context.applicationContext)
            try {
                core.recurrences.realizeDueTimeOccurrences()
                FluviRecurrenceScheduler.scheduleNext(context.applicationContext, core)
            } finally {
                core.close()
                pending.finish()
            }
        }
    }
}

/** Repairs a one-shot alarm after boot, clock changes, and timezone changes. */
class FluviRecurrenceSystemEventReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        FluviRecurrenceScheduler.scheduleNextFromFreshCore(context.applicationContext)
    }
}
