package com.exptv2.app.expense.recurring

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.exptv2.app.LifecycleCoroutineScope
import com.exptv2.app.launchGuarded
import java.util.concurrent.atomic.AtomicBoolean
import kotlinx.coroutines.Dispatchers

class RecurringBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED && action != Intent.ACTION_MY_PACKAGE_REPLACED) return
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
                        message = "[RecurringAlarm] boot/package receiver error=${error.message}",
                        error = error,
                    )
                },
                onFinally = finisher::finish,
            ) {
                val appContext = context.applicationContext
                val logger = RecurringAlarmDebugLogger(appContext)
                logger.log("[RecurringAlarm] boot/package receiver action=$action")
                RecurringAlarmScheduler(appContext, logger).sync()
            }
        } catch (error: Throwable) {
            try {
                reportRecurringReceiverFailure(
                    context = context,
                    message = "[RecurringAlarm] boot/package receiver error=${error.message}",
                    error = error,
                )
            } finally {
                finisher.finish()
            }
            if (error !is Exception) throw error
        }
    }
}

internal fun reportRecurringReceiverFailure(
    context: Context,
    message: String,
    error: Throwable,
) {
    Log.e(RECURRING_LOG_TAG, message, error)
    try {
        RecurringAlarmDebugLogger(context.applicationContext).log(message)
    } catch (loggingError: Exception) {
        Log.e(RECURRING_LOG_TAG, "$message logFailure=${loggingError.message}", loggingError)
    }
}

internal class ReceiverPendingResultFinisher(
    private val finishPending: () -> Unit,
    private val cancelScope: () -> Unit,
) {
    private val finished = AtomicBoolean(false)

    fun finish() {
        if (!finished.compareAndSet(false, true)) return
        try {
            finishPending()
        } finally {
            cancelScope()
        }
    }
}

private const val RECURRING_LOG_TAG = "ExpenseNotification"
