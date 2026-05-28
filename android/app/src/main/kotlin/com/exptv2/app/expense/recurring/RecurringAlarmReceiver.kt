package com.exptv2.app.expense.recurring

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.exptv2.app.expense.ExpenseRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class RecurringAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != RecurringAlarmScheduler.ACTION_PROCESS) return
        val pending = goAsync()
        val appContext = context.applicationContext
        val logger = RecurringAlarmDebugLogger(appContext)
        CoroutineScope(SupervisorJob() + Dispatchers.IO).launch {
            try {
                val target = RecurringDebugClockStore(appContext).effectiveNow()
                logger.log("[RecurringAlarm] receiver fired now=$target")
                val processed = ExpenseRepository(appContext).processDueRecurringTransactions(target)
                logger.log("[RecurringAlarm] receiver processed=${processed.size}")
                RecurringAlarmScheduler(appContext, logger).sync()
            } catch (error: Exception) {
                logger.log("[RecurringAlarm] receiver error=${error.message}")
            } finally {
                pending.finish()
            }
        }
    }
}
