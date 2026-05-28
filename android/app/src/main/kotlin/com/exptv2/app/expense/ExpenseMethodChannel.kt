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
            "expenseLoadSettings" -> scope.launchResult(result) { repository.loadSettings() }
            "expenseUpdateThemeSettings" -> scope.launchResult(result) {
                repository.updateThemeSettings(call.argumentsMap())
            }
            "expenseUpdateFastInfoConfig" -> scope.launchResult(result) {
                repository.updateFastInfoConfig(call.argumentsMap())
            }
            "expenseListNotificationCards" -> scope.launchResult(result) {
                repository.listNotificationCards()
            }
            "expenseMarkNotificationCardRead" -> scope.launchResult(result) {
                val id = (call.argumentsMap()["id"] as? Number)?.toInt()
                    ?: throw ExpenseValidationException("INVALID_NOTIFICATION_ID", "Notification id is required")
                repository.markNotificationCardRead(id)
            }
            "expenseDeleteNotificationCard" -> scope.launchResult(result) {
                val id = (call.argumentsMap()["id"] as? Number)?.toInt()
                    ?: throw ExpenseValidationException("INVALID_NOTIFICATION_ID", "Notification id is required")
                repository.deleteNotificationCard(id)
            }
            "expenseClearNotificationCards" -> scope.launchResult(result) {
                repository.clearNotificationCards(call.argumentsMap())
            }
            "expenseListRecurringTransactions" -> scope.launchResult(result) {
                repository.listRecurringTransactions()
            }
            "expenseListRecurringGhostTransactions" -> scope.launchResult(result) {
                repository.listRecurringGhostTransactions()
            }
            "expenseEnsureRecurringGhostTransactions" -> scope.launchResult(result) {
                val targetMillis = (call.argumentsMap()["targetMillis"] as? Number)?.toLong()
                    ?: System.currentTimeMillis()
                repository.ensureRecurringGhostTransactions(targetMillis)
            }
            "expenseAddRecurringTransaction" -> scope.launchResult(result) {
                repository.addRecurringTransaction(call.argumentsMap())
            }
            "expenseUpdateRecurringTransaction" -> scope.launchResult(result) {
                repository.updateRecurringTransaction(call.argumentsMap())
            }
            "expenseToggleRecurringTransaction" -> scope.launchResult(result) {
                repository.toggleRecurringTransaction(call.argumentsMap())
            }
            "expenseDeleteRecurringTransaction" -> scope.launchResult(result) {
                val id = (call.argumentsMap()["id"] as? Number)?.toInt()
                    ?: call.argumentsMap()["id"]?.toString()?.toIntOrNull()
                    ?: throw ExpenseValidationException("INVALID_RECURRING_ID", "Recurring transaction id is required")
                repository.deleteRecurringTransaction(id)
            }
            "expenseProcessRecurringTransactions" -> scope.launchResult(result) {
                val targetMillis = (call.argumentsMap()["targetMillis"] as? Number)?.toLong()
                    ?: System.currentTimeMillis()
                repository.processDueRecurringTransactions(targetMillis)
            }
            "expenseListTransactions" -> scope.launchResult(result) {
                repository.listTransactions(call.argumentsMap())
            }
            "expenseListCategories" -> scope.launchResult(result) {
                repository.listCategories(call.argumentsMap()["type"]?.toString())
            }
            "expenseAddTransaction" -> scope.launchResult(result) {
                repository.addTransaction(call.argumentsMap())
            }
            "expenseUpdateTransaction" -> scope.launchResult(result) {
                repository.updateTransaction(call.argumentsMap())
            }
            "expenseAddCategory" -> scope.launchResult(result) {
                repository.addCategory(call.argumentsMap())
            }
            "expenseUpdateCategory" -> scope.launchResult(result) {
                repository.updateCategory(call.argumentsMap())
            }
            "expenseDeleteCategory" -> scope.launchResult(result) {
                val id = (call.argumentsMap()["id"] as? Number)?.toInt()
                    ?: call.argumentsMap()["id"]?.toString()?.toIntOrNull()
                    ?: throw ExpenseValidationException("INVALID_CATEGORY", "Category id is required")
                repository.deleteCategory(id)
            }
            "expenseCategoryCounts" -> scope.launchResult(result) {
                repository.categoryCounts()
            }
            "expenseListCategoryLimits" -> scope.launchResult(result) {
                repository.listCategoryLimits(call.argumentsMap())
            }
            "expenseUpsertCategoryLimit" -> scope.launchResult(result) {
                repository.upsertCategoryLimit(call.argumentsMap())
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
