package com.exptv2.app.expense

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class ExpenseMethodChannel(
    context: Context,
    private val scope: CoroutineScope,
) {
    private val repository = ExpenseRepository(context)

    fun handle(call: MethodCall, result: MethodChannel.Result): Boolean {
        when (call.method) {
            "expenseLoadBootstrap" -> scope.launchResult(result) { repository.bootstrap() }
            "expenseListTransactions" -> scope.launchResult(result) {
                repository.listTransactions(call.argumentsMap())
            }
            "expenseListCategories" -> scope.launchResult(result) {
                repository.listCategories(call.argumentsMap()["type"]?.toString())
            }
            "expenseAddTransaction" -> scope.launchResult(result) {
                repository.addTransaction(call.argumentsMap())
            }
            "expenseDeleteTransaction" -> scope.launchResult(result) {
                val id = (call.argumentsMap()["id"] as? Number)?.toInt()
                    ?: throw ExpenseValidationException("INVALID_TRANSACTION_ID", "Transaction id is required")
                repository.deleteTransaction(id)
            }
            else -> return false
        }
        return true
    }

    private fun MethodCall.argumentsMap(): Map<*, *> = arguments as? Map<*, *> ?: emptyMap<String, Any?>()

    private fun CoroutineScope.launchResult(result: MethodChannel.Result, block: suspend () -> Any?) {
        launch {
            try {
                val payload = withContext(Dispatchers.IO) { block() }
                result.success(payload)
            } catch (error: ExpenseValidationException) {
                result.error(error.code, error.message, null)
            } catch (error: Exception) {
                result.error("EXPENSE_DB_ERROR", error.message, null)
            }
        }
    }
}
