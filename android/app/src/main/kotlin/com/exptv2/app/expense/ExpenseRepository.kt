package com.exptv2.app.expense

import android.content.Context
import java.util.Calendar

class ExpenseRepository(context: Context) {
    private val db = ExpenseTrackerDatabase.get(context)
    private val transactions = db.transactions()
    private val categories = db.categories()

    suspend fun bootstrap(): Map<String, Any?> {
        seedIfEmpty()
        val categoryRows = categories.all()
        val transactionRows = transactions.all()
        return mapOf(
            "categories" to categoryRows.map { it.toMap() },
            "transactions" to transactionRows.map { it.toMap() },
        )
    }

    suspend fun listCategories(type: String?): List<Map<String, Any?>> {
        seedIfEmpty()
        val normalizedType = normalizeHungarianType(type)
        val rows = if (normalizedType == null) {
            categories.all()
        } else {
            categories.byType(normalizedType)
        }
        return rows.map { it.toMap() }
    }

    suspend fun listTransactions(args: Map<*, *>): List<Map<String, Any?>> {
        seedIfEmpty()
        val type = args["type"]?.toString()
        val searchQuery = args["searchQuery"]?.toString()?.trim().orEmpty()
        val merchant = args["merchant"]?.toString()?.trim().orEmpty()
        val categoryId = (args["categoryId"] as? Number)?.toInt()
        val yearMonth = args["yearMonth"]?.toString()?.trim().orEmpty()
        return transactions.all()
            .asSequence()
            .filter { row -> type == null || typeFromAmount(row.amount) == type }
            .filter { row -> categoryId == null || row.transactionCategoryID == categoryId }
            .filter { row -> merchant.isEmpty() || displayMerchant(row) == merchant }
            .filter { row -> searchQuery.isEmpty() || displayMerchant(row).contains(searchQuery, ignoreCase = true) }
            .filter { row -> yearMonth.isEmpty() || row.date.replace('.', '-').startsWith(yearMonth) }
            .map { it.toMap() }
            .toList()
    }

    suspend fun addTransaction(args: Map<*, *>): Map<String, Any?> {
        seedIfEmpty()
        val merchant = args["merchant"]?.toString()?.trim().orEmpty()
        if (merchant.isEmpty()) {
            throw ExpenseValidationException("INVALID_TRANSACTION_NAME", "Transaction name is required")
        }

        val rawAmount = (args["amount"] as? Number)?.toDouble()
            ?: args["amount"]?.toString()?.toDoubleOrNull()
            ?: throw ExpenseValidationException("INVALID_AMOUNT", "Amount must be numeric")
        if (rawAmount <= 0.0) {
            throw ExpenseValidationException("INVALID_AMOUNT", "Amount must be greater than zero")
        }

        val type = args["type"]?.toString() ?: "expense"
        if (type != "income" && type != "expense") {
            throw ExpenseValidationException("INVALID_TRANSACTION_TYPE", "Type must be income or expense")
        }

        val categoryId = (args["transactionCategoryID"] as? Number)?.toInt()
            ?: args["transactionCategoryID"]?.toString()?.toIntOrNull()
            ?: throw ExpenseValidationException("INVALID_CATEGORY", "Category is required")
        categories.byId(categoryId)
            ?: throw ExpenseValidationException("INVALID_CATEGORY", "Category does not exist")

        val date = formatDate(args["date"]?.toString())
        val time = args["time"]?.toString()?.trim().takeUnless { it.isNullOrEmpty() } ?: "00:00"
        val signedAmount = if (type == "income") kotlin.math.abs(rawAmount) else -kotlin.math.abs(rawAmount)
        val row = ExpenseTransactionEntity(
            id = nextId(date),
            date = date,
            time = time,
            latitude = (args["latitude"] as? Number)?.toDouble(),
            longitude = (args["longitude"] as? Number)?.toDouble(),
            address = args["address"]?.toString() ?: "Unknown location",
            merchant = merchant,
            amount = signedAmount,
            userAssignedName = args["userAssignedName"]?.toString(),
            transactionCategoryID = categoryId,
        )
        transactions.insert(row)
        return row.toMap()
    }

    suspend fun deleteTransaction(id: Int): Boolean {
        seedIfEmpty()
        val row = transactions.byId(id) ?: return false
        transactions.delete(row)
        return true
    }

    private suspend fun seedIfEmpty() {
        if (categories.count() == 0) categories.insertAll(ExpenseSeedData.categories)
        if (transactions.count() == 0) transactions.insertAll(ExpenseSeedData.transactions)
    }

    private suspend fun nextId(date: String): Int {
        val parts = date.split(".")
        val prefix = parts[0].takeLast(2) + parts[1].padStart(2, '0')
        val max = transactions.maxIdForPrefix(prefix)
        return if (max == null) "${prefix}01".toInt() else max + 1
    }

    private fun typeFromAmount(amount: Double): String = if (amount > 0) "income" else "expense"

    private fun displayMerchant(row: ExpenseTransactionEntity): String {
        return row.userAssignedName?.takeIf { it.isNotBlank() } ?: row.merchant
    }

    private fun normalizeHungarianType(type: String?): String? = when (type) {
        null, "" -> null
        "income", "bevétel" -> "bevétel"
        "expense", "kiadás" -> "kiadás"
        else -> null
    }

    private fun formatDate(value: String?): String {
        val input = value?.trim().takeUnless { it.isNullOrEmpty() }
        if (input == null) {
            val now = Calendar.getInstance()
            return "%04d.%02d.%02d".format(
                now.get(Calendar.YEAR),
                now.get(Calendar.MONTH) + 1,
                now.get(Calendar.DAY_OF_MONTH),
            )
        }
        val parts = input.replace('/', '-').replace('.', '-').split('-')
        if (parts.size != 3) {
            throw ExpenseValidationException("INVALID_DATE", "Date must be YYYY-MM-DD or YYYY.MM.DD")
        }
        val year = parts[0].toIntOrNull()
            ?: throw ExpenseValidationException("INVALID_DATE", "Date year is invalid")
        val month = parts[1].toIntOrNull()
            ?: throw ExpenseValidationException("INVALID_DATE", "Date month is invalid")
        val day = parts[2].toIntOrNull()
            ?: throw ExpenseValidationException("INVALID_DATE", "Date day is invalid")
        return "%04d.%02d.%02d".format(year, month, day)
    }
}

class ExpenseValidationException(val code: String, message: String) : IllegalArgumentException(message)
