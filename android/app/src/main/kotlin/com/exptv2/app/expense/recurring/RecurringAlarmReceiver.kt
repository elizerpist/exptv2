package com.exptv2.app.expense.recurring

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.exptv2.app.LifecycleCoroutineScope
import com.exptv2.app.launchGuarded
import com.exptv2.app.expense.ExpenseRepository
import kotlinx.coroutines.Dispatchers

class RecurringAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != RecurringAlarmScheduler.ACTION_PROCESS) return
        val pending = goAsync()
        var scope: LifecycleCoroutineScope? = null
        val finisher = ReceiverPendingResultFinisher(
            finishPending = pending::finish,
            cancelScope = { scope?.cancel() },
        )
        try {
            scope = LifecycleCoroutineScope(Dispatchers.IO)
            scope.launchGuarded(
                reportFailure = { error ->
                    reportRecurringReceiverFailure(
                        context = context,
                        message = "[RecurringAlarm] receiver error=${error.message}",
                        error = error,
                    )
                },
                onFinally = finisher::finish,
            ) {
                val appContext = context.applicationContext
                val logger = RecurringAlarmDebugLogger(appContext)
                val target = RecurringDebugClockStore(appContext).effectiveNow()
                logger.log("[RecurringAlarm] receiver fired now=$target")
                val processed = ExpenseRepository(appContext).processDueRecurringTransactions(target)
                logger.log("[RecurringAlarm] receiver processed=${processed.size}")
                RecurringAlarmScheduler(appContext, logger).sync()
            }
        } catch (error: Throwable) {
            try {
                reportRecurringReceiverFailure(
                    context = context,
                    message = "[RecurringAlarm] receiver error=${error.message}",
                    error = error,
                )
            } finally {
                finisher.finish()
            }
            if (error !is Exception) throw error
        }
    }
}
