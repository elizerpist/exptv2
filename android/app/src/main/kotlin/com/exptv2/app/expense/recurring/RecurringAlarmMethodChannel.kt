package com.exptv2.app.expense.recurring

import android.content.Context
import com.exptv2.app.expense.ExpenseRepository
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class RecurringAlarmMethodChannel(
    context: Context,
    private val scope: CoroutineScope,
) {
    private val appContext = context.applicationContext
    private val logger = RecurringAlarmDebugLogger(appContext)
    private val clock = RecurringDebugClockStore(appContext)
    private val scheduler = RecurringAlarmScheduler(appContext, logger)

    fun attach(channel: MethodChannel) {
        channel.setMethodCallHandler { call, result -> handle(call, result) }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "syncRecurringAlarms" -> scope.launchResult(result) {
                scheduler.sync()
                true
            }
            "processRecurringNow" -> scope.launchResult(result) {
                val target = (call.argumentsMap()["targetMillis"] as? Number)?.toLong() ?: clock.effectiveNow()
                logger.log("[RecurringAlarm] processing target=$target")
                val processed = ExpenseRepository(appContext).processDueRecurringTransactions(target)
                scheduler.sync()
                mapOf("state" to debugState(), "processedCount" to processed.size, "processed" to processed)
            }
            "setDebugDateOverride" -> scope.launchResult(result) {
                val target = (call.argumentsMap()["targetMillis"] as? Number)?.toLong()
                    ?: throw IllegalArgumentException("targetMillis is required")
                val normalized = clock.setOverride(target)
                logger.log("[RecurringAlarm] debug override set=$normalized")
                val processed = ExpenseRepository(appContext).processDueRecurringTransactions(normalized)
                scheduler.sync()
                mapOf("state" to debugState(), "processedCount" to processed.size)
            }
            "clearDebugDateOverride" -> scope.launchResult(result) {
                clock.clearOverride()
                logger.log("[RecurringAlarm] debug override cleared")
                scheduler.sync()
                debugState()
            }
            "scheduleRecurringDebugTestAlarm" -> scope.launchResult(result) {
                val delay = (call.argumentsMap()["delayMillis"] as? Number)?.toLong() ?: 120_000L
                val triggerMillis = scheduler.scheduleDebugTestAlarm(delay)
                debugState() + mapOf("scheduledDebugAlarmMillis" to triggerMillis)
            }
            "loadRecurringAlarmDebugState" -> scope.launchResult(result) {
                debugState()
            }
            "clearRecurringAlarmDebugLog" -> scope.launchResult(result) {
                logger.clear()
                true
            }
            else -> result.notImplemented()
        }
    }

    private fun debugState(): Map<String, Any?> {
        return clock.state() + mapOf("logs" to logger.entries())
    }

    private fun MethodCall.argumentsMap(): Map<*, *> = arguments as? Map<*, *> ?: emptyMap<String, Any?>()

    private fun CoroutineScope.launchResult(result: MethodChannel.Result, block: suspend () -> Any?) {
        launch {
            try {
                result.success(withContext(Dispatchers.IO) { block() })
            } catch (cancellation: CancellationException) {
                throw cancellation
            } catch (error: Exception) {
                result.error("RECURRING_ALARM_ERROR", error.message, null)
            }
        }
    }
}
