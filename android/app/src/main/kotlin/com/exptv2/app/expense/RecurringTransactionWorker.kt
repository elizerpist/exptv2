package com.exptv2.app.expense

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters

class RecurringTransactionWorker(
    appContext: Context,
    params: WorkerParameters,
) : CoroutineWorker(appContext, params) {
    override suspend fun doWork(): Result {
        return runCatching {
            ExpenseRepository(applicationContext).processDueRecurringTransactions(System.currentTimeMillis())
            Result.success()
        }.getOrElse {
            Result.retry()
        }
    }
}
