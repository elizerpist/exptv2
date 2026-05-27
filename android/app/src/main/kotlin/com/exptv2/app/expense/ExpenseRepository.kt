package com.exptv2.app.expense

import android.content.Context
import java.util.Calendar

class ExpenseRepository(context: Context) {
    private val db = ExpenseTrackerDatabase.get(context)
    private val transactions = db.transactions()
    private val categories = db.categories()
    private val categoryLimits = db.categoryLimits()

    suspend fun bootstrap(): Map<String, Any?> {
        seedIfEmpty()
        val categoryRows = categories.all()
        val transactionRows = transactions.all()
        val limitRows = categoryLimits.list(null, null, null)
        return mapOf(
            "categories" to categoryRows.map { it.toMap() },
            "transactions" to transactionRows.map { it.toMap() },
            "limits" to limitRows.map { it.toMap() },
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

    suspend fun categoryCounts(): Map<Int, Int> {
        seedIfEmpty()
        return transactions.categoryCounts().associate { it.transactionCategoryID to it.count }
    }


    suspend fun listCategoryLimits(args: Map<*, *>): List<Map<String, Any?>> {
        seedIfEmpty()
        val transactionType = normalizeNativeTransactionType(args["transactionType"]?.toString())
        val window = normalizeLimitWindow(args["window"]?.toString())
        val periodKey = args["periodKey"]?.toString()?.trim()?.takeIf { it.isNotEmpty() }
        return categoryLimits.list(transactionType, window, periodKey).map { it.toMap() }
    }

    suspend fun upsertCategoryLimit(args: Map<*, *>): Map<String, Any?> {
        seedIfEmpty()
        val targetType = normalizeTargetType(args["targetType"]?.toString())
            ?: throw ExpenseValidationException("INVALID_LIMIT_TARGET", "Limit target type is required")
        val targetId = optionalInt(args["targetId"])
            ?: throw ExpenseValidationException("INVALID_LIMIT_TARGET", "Limit target id is required")
        if (targetType == "overview" && targetId != 0) {
            throw ExpenseValidationException("INVALID_LIMIT_TARGET", "Overview limit target id must be 0")
        }
        if (targetType == "category" && categories.byId(targetId) == null) {
            throw ExpenseValidationException("INVALID_CATEGORY", "Category does not exist")
        }
        val transactionType = normalizeNativeTransactionType(args["transactionType"]?.toString())
            ?: throw ExpenseValidationException("INVALID_LIMIT_TYPE", "Limit transaction type is required")
        val window = normalizeLimitWindow(args["window"]?.toString())
            ?: throw ExpenseValidationException("INVALID_LIMIT_WINDOW", "Limit window is required")
        val periodKey = args["periodKey"]?.toString()?.trim()?.takeIf { it.isNotEmpty() }
            ?: throw ExpenseValidationException("INVALID_LIMIT_PERIOD", "Limit period key is required")
        val amount = doubleArg(args["limitAmount"], 0.0)
        if (amount < 0.0) {
            throw ExpenseValidationException("INVALID_LIMIT_AMOUNT", "Limit amount cannot be negative")
        }
        val hasLimit = boolArg(args["hasLimit"], amount > 0.0) && amount > 0.0
        val alertActive = hasLimit && boolArg(args["alertActive"], false)
        val existing = categoryLimits.byKey(targetType, targetId, transactionType, window, periodKey)
        val now = System.currentTimeMillis()
        val row = CategoryLimitEntity(
            id = existing?.id ?: 0,
            targetType = targetType,
            targetId = targetId,
            transactionType = transactionType,
            window = window,
            periodKey = periodKey,
            hasLimit = hasLimit,
            limitAmount = if (hasLimit) amount else 0.0,
            alertActive = alertActive,
            createdAt = existing?.createdAt ?: now,
            updatedAt = now,
        )
        val newId = categoryLimits.insert(row).toInt()
        return row.copy(id = if (row.id == 0) newId else row.id).toMap()
    }

    suspend fun addCategory(args: Map<*, *>): Map<String, Any?> {
        seedIfEmpty()
        val name = args["name"]?.toString()?.trim().orEmpty()
        if (name.isEmpty()) {
            throw ExpenseValidationException("INVALID_CATEGORY_NAME", "Category name is required")
        }
        val type = normalizeHungarianType(args["type"]?.toString())
            ?: throw ExpenseValidationException("INVALID_CATEGORY_TYPE", "Category type is required")
        val colorSlot = optionalInt(args["colorSlot"]) ?: 4
        val iconSlot = optionalInt(args["iconSlot"]) ?: 0
        val row = TransactionCategoryEntity(
            transactionCategoryID = nextCategoryId(),
            name = name,
            type = type,
            colorSlot = colorSlot,
            iconSlot = iconSlot,
            backgroundColor = args["backgroundColor"]?.toString() ?: colorForSlot(colorSlot),
            icon = args["icon"]?.toString(),
            notification = args["notification"]?.toString(),
            hasLimit = boolArg(args["hasLimit"], false),
            limitAmount = doubleArg(args["limitAmount"], 0.0),
            alertActive = boolArg(args["alertActive"], false),
            isCustomIcon = boolArg(args["isCustomIcon"], true),
            originalIcon = args["originalIcon"]?.toString(),
        )
        categories.insert(row)
        return row.toMap()
    }

    suspend fun updateCategory(args: Map<*, *>): Map<String, Any?> {
        seedIfEmpty()
        val id = optionalInt(args["id"])
            ?: throw ExpenseValidationException("INVALID_CATEGORY", "Category id is required")
        val existing = categories.byId(id)
            ?: throw ExpenseValidationException("INVALID_CATEGORY", "Category does not exist")
        val name = args["name"]?.toString()?.trim()?.takeIf { it.isNotEmpty() }
            ?: throw ExpenseValidationException("INVALID_CATEGORY_NAME", "Category name is required")
        val type = normalizeHungarianType(args["type"]?.toString()) ?: existing.type
        val colorSlot = optionalInt(args["colorSlot"]) ?: existing.colorSlot
        val iconSlot = optionalInt(args["iconSlot"]) ?: existing.iconSlot
        val row = existing.copy(
            name = name,
            type = type,
            colorSlot = colorSlot,
            iconSlot = iconSlot,
            backgroundColor = args["backgroundColor"]?.toString()
                ?: colorSlot?.let { colorForSlot(it) }
                ?: existing.backgroundColor,
            icon = args["icon"]?.toString() ?: existing.icon,
            notification = args["notification"]?.toString() ?: existing.notification,
            hasLimit = boolArg(args["hasLimit"], existing.hasLimit),
            limitAmount = doubleArg(args["limitAmount"], existing.limitAmount),
            alertActive = boolArg(args["alertActive"], existing.alertActive),
            isCustomIcon = boolArg(args["isCustomIcon"], existing.isCustomIcon),
            originalIcon = args["originalIcon"]?.toString() ?: existing.originalIcon,
        )
        categories.update(row)
        return row.toMap()
    }

    suspend fun deleteCategory(id: Int): Boolean {
        seedIfEmpty()
        val row = categories.byId(id) ?: return false
        if (transactions.countByCategory(id) > 0) {
            throw ExpenseValidationException("CATEGORY_IN_USE", "Category has transactions")
        }
        categories.delete(row)
        return true
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

    private suspend fun nextCategoryId(): Int = (categories.maxId() ?: 0) + 1

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

    private fun normalizeNativeTransactionType(type: String?): String? = when (type) {
        null, "" -> null
        "income", "bevétel" -> "income"
        "expense", "kiadás" -> "expense"
        else -> null
    }

    private fun normalizeLimitWindow(window: String?): String? = when (window) {
        null, "" -> null
        "monthly" -> "monthly"
        "yearly" -> "yearly"
        "all_time", "allTime", "sum" -> "all_time"
        else -> null
    }

    private fun normalizeTargetType(targetType: String?): String? = when (targetType) {
        "overview" -> "overview"
        "category" -> "category"
        else -> null
    }

    private fun optionalInt(value: Any?): Int? {
        return (value as? Number)?.toInt() ?: value?.toString()?.toIntOrNull()
    }

    private fun doubleArg(value: Any?, fallback: Double): Double {
        return (value as? Number)?.toDouble() ?: value?.toString()?.toDoubleOrNull() ?: fallback
    }

    private fun boolArg(value: Any?, fallback: Boolean): Boolean {
        return when (value) {
            null -> fallback
            is Boolean -> value
            is Number -> value.toInt() != 0
            else -> value.toString() == "true"
        }
    }

    private fun colorForSlot(slot: Int): String = slotColors[slot] ?: slotColors[4]!!

    private val slotColors = mapOf(
        0 to "#ef4444",
        1 to "#f97316",
        2 to "#eab308",
        3 to "#84cc16",
        4 to "#22c55e",
        5 to "#10b981",
        6 to "#06b6d4",
        7 to "#0ea5e9",
        8 to "#3b82f6",
        9 to "#6366f1",
        10 to "#8b5cf6",
        11 to "#a855f7",
        12 to "#d946ef",
        13 to "#ec4899",
        14 to "#f43f5e",
        15 to "#6b7280",
        16 to "#374151",
        17 to "#1f2937",
        18 to "#064e3b",
        19 to "#7c2d12",
        20 to "#4c1d95",
    )

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
