package com.exptv2.app.expense

import android.content.Context
import android.util.Log

class RecurringNotificationHelper(private val context: Context) {
    fun notifyProcessed(rows: List<RecurringTransactionEntity>) {
        if (rows.isEmpty()) return
        Log.d(
            "ExpenseNotification",
            "[Notification] legacy recurring notifyProcessed rows=${rows.size} context=${context.packageName}",
        )
    }
}
