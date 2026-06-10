package com.exptv2.app.expense

import android.content.Context
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlin.coroutines.resume

class ExpenseMethodChannel(
    private val activity: FragmentActivity,
    context: Context,
    private val scope: CoroutineScope,
) {
    private val repository = ExpenseRepository(context)
    private val textFileExporter = ExpenseTextFileExporter(activity, context.applicationContext)
    private val authenticators = BiometricManager.Authenticators.BIOMETRIC_WEAK

    fun handle(call: MethodCall, result: MethodChannel.Result): Boolean {
        when (call.method) {
            "expenseLoadBootstrap" -> scope.launchResult(result) { repository.bootstrap() }
            "expenseLoadSettings" -> scope.launchResult(result) {
                repository.loadSettings(
                    biometricAvailable = biometricAvailable(),
                    biometricLabel = biometricLabel(),
                )
            }
            "expenseUpdateThemeSettings" -> scope.launchResult(result) {
                repository.updateThemeSettings(call.argumentsMap())
            }
            "expenseUpdateFastInfoConfig" -> scope.launchResult(result) {
                repository.updateFastInfoConfig(call.argumentsMap())
            }
            "expenseUpdatePushRecurringSettings" -> scope.launchResult(result) {
                repository.updatePushRecurringSettings(call.argumentsMap())
            }
            "expenseUpdateNotificationSettings" -> scope.launchResult(result) {
                repository.updateNotificationSettings(call.argumentsMap())
            }
            "expenseSaveTextFile" -> scope.launchResult(result) {
                textFileExporter.saveTextFile(call.argumentsMap())
            }
            "expenseShareTextFile" -> scope.launchResult(result) {
                textFileExporter.shareTextFile(call.argumentsMap())
                null
            }
            "expenseSetSecurityPin" -> scope.launchResult(result) {
                val pin = call.argumentsMap()["pin"]?.toString()
                    ?: throw ExpenseValidationException("PIN_REQUIRED", "PIN is required")
                repository.setSecurityPin(pin)
            }
            "expenseChangeSecurityPin" -> scope.launchResult(result) {
                val args = call.argumentsMap()
                repository.changeSecurityPin(
                    args["currentPin"]?.toString() ?: "",
                    args["newPin"]?.toString() ?: "",
                )
            }
            "expenseClearSecurityPin" -> scope.launchResult(result) {
                repository.clearSecurityPin(call.argumentsMap()["currentPin"]?.toString() ?: "")
            }
            "expenseVerifySecurityPin" -> scope.launchResult(result) {
                repository.verifySecurityPin(call.argumentsMap()["pin"]?.toString() ?: "")
            }
            "expenseSetBiometricEnabled" -> scope.launchResult(result) {
                val enabled = call.argumentsMap()["enabled"] == true
                repository.setBiometricEnabled(
                    enabled = enabled,
                    biometricAvailable = biometricAvailable(),
                )
            }
            "expenseGetBiometricAvailability" -> scope.launchResult(result) {
                repository.loadSecuritySettings(
                    biometricAvailable = biometricAvailable(),
                    biometricLabel = biometricLabel(),
                )
            }
            "expenseAuthenticateBiometric" -> scope.launchResult(result) {
                withContext(Dispatchers.Main) { authenticateBiometric() }
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
            "expenseListRecurringRules" -> scope.launchResult(result) {
                repository.listRecurringRules()
            }
            "expenseAddRecurringRule" -> scope.launchResult(result) {
                repository.addRecurringRule(call.argumentsMap())
            }
            "expenseUpdateRecurringRule" -> scope.launchResult(result) {
                repository.updateRecurringRule(call.argumentsMap())
            }
            "expenseToggleRecurringRule" -> scope.launchResult(result) {
                repository.toggleRecurringRule(call.argumentsMap())
            }
            "expenseDeleteRecurringRule" -> scope.launchResult(result) {
                val id = (call.argumentsMap()["id"] as? Number)?.toInt()
                    ?: call.argumentsMap()["id"]?.toString()?.toIntOrNull()
                    ?: throw ExpenseValidationException("INVALID_RECURRING_RULE", "Recurring rule id is required")
                repository.deleteRecurringRule(id)
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
            "expenseListTransactionPage" -> scope.launchResult(result) {
                repository.listTransactionPage(call.argumentsMap())
            }
            "expenseGetTransaction" -> scope.launchResult(result) {
                val id = (call.argumentsMap()["id"] as? Number)?.toInt()
                    ?: call.argumentsMap()["id"]?.toString()?.toIntOrNull()
                    ?: throw ExpenseValidationException("INVALID_TRANSACTION_ID", "Transaction id is required")
                repository.transactionById(id)
            }
            "expenseNotificationEventIdForTransaction" -> scope.launchResult(result) {
                val id = (call.argumentsMap()["id"] as? Number)?.toInt()
                    ?: call.argumentsMap()["id"]?.toString()?.toIntOrNull()
                    ?: throw ExpenseValidationException("INVALID_TRANSACTION_ID", "Transaction id is required")
                repository.notificationEventIdForTransaction(id)
            }
            "expenseTransactionsForNotificationEvents" -> scope.launchResult(result) {
                val eventIds = (call.argumentsMap()["eventIds"] as? List<*>)
                    .orEmpty()
                    .mapNotNull { value ->
                        (value as? Number)?.toLong() ?: value?.toString()?.toLongOrNull()
                    }
                repository.transactionRowsForNotificationEventIds(eventIds)
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
            "expenseRenameTransactionsByMerchant" -> scope.launchResult(result) {
                repository.renameTransactionsByMerchant(call.argumentsMap())
            }
            "expenseResetTransactionNamesByMerchant" -> scope.launchResult(result) {
                repository.resetTransactionNamesByMerchant(call.argumentsMap())
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

    private fun biometricAvailable(): Boolean {
        val manager = BiometricManager.from(activity)
        return manager.canAuthenticate(authenticators) == BiometricManager.BIOMETRIC_SUCCESS
    }

    private fun biometricLabel(): String {
        return if (biometricAvailable()) "Biometria elerheto" else "Nem elerheto"
    }

    private suspend fun authenticateBiometric(): Boolean = suspendCancellableCoroutine { continuation ->
        val executor = ContextCompat.getMainExecutor(activity)
        val prompt = BiometricPrompt(
            activity,
            executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    if (continuation.isActive) continuation.resume(true)
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    if (continuation.isActive) continuation.resume(false)
                }
            },
        )
        val info = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Exptv2 belepes")
            .setSubtitle("Azonositsd magad az alkalmazas megnyitasahoz")
            .setNegativeButtonText("PIN hasznalata")
            .setAllowedAuthenticators(authenticators)
            .build()
        prompt.authenticate(info)
        continuation.invokeOnCancellation { prompt.cancelAuthentication() }
    }

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
