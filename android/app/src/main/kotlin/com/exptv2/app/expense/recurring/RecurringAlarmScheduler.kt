package com.exptv2.app.expense.recurring

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import com.exptv2.app.MainActivity
import com.exptv2.app.expense.ExpenseRepository

class RecurringAlarmScheduler(
    context: Context,
    private val logger: RecurringAlarmDebugLogger = RecurringAlarmDebugLogger(context),
) {
    private val appContext = context.applicationContext
    private val alarmManager = appContext.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    suspend fun sync() {
        val next = ExpenseRepository(appContext).nextRecurringTriggerMillis()
        if (next == null) {
            cancel()
            logger.log("[RecurringAlarm] sync start active=0")
            return
        }
        schedule(next)
    }

    fun schedule(triggerMillis: Long) {
        val intent = PendingIntent.getBroadcast(
            appContext,
            REQUEST_CODE,
            Intent(appContext, RecurringAlarmReceiver::class.java).setAction(ACTION_PROCESS),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val canExact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarmManager.canScheduleExactAlarms()
        val mode = when {
            canExact && Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP -> {
                val showIntent = PendingIntent.getActivity(
                    appContext,
                    REQUEST_CODE_OPEN,
                    appContext.packageManager.getLaunchIntentForPackage(appContext.packageName)
                        ?: Intent(appContext, MainActivity::class.java),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                alarmManager.setAlarmClock(AlarmManager.AlarmClockInfo(triggerMillis, showIntent), intent)
                "setAlarmClock"
            }
            canExact && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerMillis, intent)
                "setExactAndAllowWhileIdle"
            }
            canExact -> {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerMillis, intent)
                "setExact"
            }
            else -> {
                alarmManager.set(AlarmManager.RTC_WAKEUP, triggerMillis, intent)
                "set"
            }
        }
        logger.log("[RecurringAlarm] scheduled next=$triggerMillis mode=$mode exact=$canExact")
    }

    fun cancel() {
        val intent = PendingIntent.getBroadcast(
            appContext,
            REQUEST_CODE,
            Intent(appContext, RecurringAlarmReceiver::class.java).setAction(ACTION_PROCESS),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        alarmManager.cancel(intent)
        logger.log("[RecurringAlarm] cancelled")
    }

    companion object {
        const val ACTION_PROCESS = "com.exptv2.app.RECURRING_ALARM_PROCESS"
        private const val REQUEST_CODE = 92601
        private const val REQUEST_CODE_OPEN = 92602
    }
}
