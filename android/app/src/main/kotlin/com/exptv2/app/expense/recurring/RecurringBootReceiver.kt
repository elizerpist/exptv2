package com.exptv2.app.expense.recurring

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class RecurringBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED && action != Intent.ACTION_MY_PACKAGE_REPLACED) return
        val pending = goAsync()
        val appContext = context.applicationContext
        val logger = RecurringAlarmDebugLogger(appContext)
        logger.log("[RecurringAlarm] boot/package receiver action=$action")
        CoroutineScope(SupervisorJob() + Dispatchers.IO).launch {
            try {
                RecurringAlarmScheduler(appContext, logger).sync()
            } finally {
                pending.finish()
            }
        }
    }
}
