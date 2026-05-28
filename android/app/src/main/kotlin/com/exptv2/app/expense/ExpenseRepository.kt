package com.exptv2.app.expense

import android.content.Context
import com.exptv2.app.expense.recurring.RecurringAlarmScheduler
import com.exptv2.app.expense.recurring.RecurringDebugClockStore
import java.util.Calendar

class ExpenseRepository(context: Context) {
    private val appContext = context.applicationContext
    private val db = ExpenseTrackerDatabase.get(appContext)
    private val transactions = db.transactions()
    private val categories = db.categories()
    private val categoryLimits = db.categoryLimits()
    private val recurringTransactions = db.recurringTransactions()
    private val recurringGhosts = db.recurringGhostTransactions()
    private val notificationCards = db.notificationCards()
    private val settingsStore = ExpenseSettingsStore(appContext)
    private val notificationHelper = RecurringNotificationHelper(appContext)
    private val debugClockStore = RecurringDebugClockStore(appContext)

    suspend fun bootstrap(): Map<String, Any?> {
        seedIfEmpty()
        syncRecurringGhosts(recurringTargetMillis())
        val categoryRows = categories.all()
        val transactionRows = transactions.all()
        val limitRows = categoryLimits.list(null, null, null)
        val ghostRows = recurringGhosts.pending()
        return mapOf(
            "categories" to categoryRows.map { it.toMap() },
            "transactions" to transactionRows.map { it.toMap() },
            "limits" to limitRows.map { it.toMap() },
            "recurringGhostTransactions" to ghostRows.map { it.toMap() },
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




    fun loadSettings(): Map<String, Any?> = settingsStore.loadSettings()

    fun updateThemeSettings(args: Map<*, *>): Map<String, Any?> = settingsStore.updateThemeSettings(args)

    fun updateFastInfoConfig(args: Map<*, *>): Map<String, Any?> = settingsStore.updateFastInfoConfig(args)


    suspend fun listNotificationCards(): List<Map<String, Any?>> {
        seedIfEmpty()
        return notificationCards.active().map { it.toMap() }
    }

    suspend fun markNotificationCardRead(id: Int): Boolean {
        seedIfEmpty()
        return notificationCards.markRead(id, System.currentTimeMillis()) > 0
    }

    suspend fun deleteNotificationCard(id: Int): Boolean {
        seedIfEmpty()
        return notificationCards.delete(id, System.currentTimeMillis()) > 0
    }

    suspend fun clearNotificationCards(args: Map<*, *>): Int {
        seedIfEmpty()
        val now = System.currentTimeMillis()
        val monthKey = args["monthKey"]?.toString()?.trim()?.takeIf { it.isNotEmpty() }
        return if (monthKey == null) notificationCards.clearAll(now) else notificationCards.clearMonth(monthKey, now)
    }

    suspend fun listRecurringTransactions(): List<Map<String, Any?>> {
        seedIfEmpty()
        syncRecurringGhosts(recurringTargetMillis())
        return recurringTransactions.all().map { it.toMap() }
    }

    suspend fun listRecurringGhostTransactions(): List<Map<String, Any?>> {
        seedIfEmpty()
        syncRecurringGhosts(recurringTargetMillis())
        return recurringGhosts.pending().map { it.toMap() }
    }

    suspend fun ensureRecurringGhostTransactions(targetMillis: Long = recurringTargetMillis()): List<Map<String, Any?>> {
        seedIfEmpty()
        ensureRecurringGhostsForActivePeriod(targetMillis)
        return recurringGhosts.pending().map { it.toMap() }
    }

    suspend fun addRecurringTransaction(args: Map<*, *>): Map<String, Any?> {
        seedIfEmpty()
        val row = buildRecurringRow(args, null)
        val id = recurringTransactions.insert(row).toInt()
        val saved = row.copy(id = id)
        ensureRecurringGhost(saved, recurringTargetMillis())
        syncRecurringGhosts(recurringTargetMillis())
        RecurringAlarmScheduler(appContext).sync()
        return saved.toMap()
    }

    suspend fun updateRecurringTransaction(args: Map<*, *>): Map<String, Any?> {
        seedIfEmpty()
        val id = optionalInt(args["id"])
            ?: throw ExpenseValidationException("INVALID_RECURRING_ID", "Recurring transaction id is required")
        val existing = recurringTransactions.byId(id)
            ?: throw ExpenseValidationException("INVALID_RECURRING_ID", "Recurring transaction does not exist")
        val row = buildRecurringRow(args, existing)
        recurringTransactions.update(row)
        recurringGhosts.deletePendingForRecurring(row.id)
        syncRecurringGhosts(recurringTargetMillis())
        RecurringAlarmScheduler(appContext).sync()
        return row.toMap()
    }

    suspend fun toggleRecurringTransaction(args: Map<*, *>): Map<String, Any?> {
        seedIfEmpty()
        val id = optionalInt(args["id"])
            ?: throw ExpenseValidationException("INVALID_RECURRING_ID", "Recurring transaction id is required")
        val existing = recurringTransactions.byId(id)
            ?: throw ExpenseValidationException("INVALID_RECURRING_ID", "Recurring transaction does not exist")
        val row = existing.copy(
            isActive = boolArg(args["isActive"], !existing.isActive),
            updatedAt = System.currentTimeMillis(),
        )
        recurringTransactions.update(row)
        if (row.isActive) {
            syncRecurringGhosts(recurringTargetMillis())
        } else {
            recurringGhosts.deletePendingForRecurring(row.id)
        }
        RecurringAlarmScheduler(appContext).sync()
        return row.toMap()
    }

    suspend fun deleteRecurringTransaction(id: Int): Boolean {
        seedIfEmpty()
        val existing = recurringTransactions.byId(id) ?: return false
        recurringGhosts.deleteForRecurring(id)
        recurringTransactions.delete(existing)
        RecurringAlarmScheduler(appContext).sync()
        return true
    }

    suspend fun processDueRecurringTransactions(targetMillis: Long = recurringTargetMillis()): List<Map<String, Any?>> {
        seedIfEmpty()
        val processed = syncRecurringGhosts(targetMillis)
        notificationHelper.notifyProcessed(processed)
        return processed.map { it.toMap() }
    }

    suspend fun nextRecurringTriggerMillis(targetMillis: Long = recurringTargetMillis()): Long? {
        seedIfEmpty()
        ensureRecurringGhostsForActivePeriod(targetMillis)
        nextPendingRecurringTriggerAtOrAfter(targetMillis)?.let { return it }
        ensureRecurringGhostsForActivePeriod(nextRecurringMonthMillis(targetMillis))
        return nextPendingRecurringTriggerAtOrAfter(targetMillis)
    }

    private suspend fun nextPendingRecurringTriggerAtOrAfter(targetMillis: Long): Long? {
        return recurringGhosts.pending()
            .asSequence()
            .filter { !it.isActivated }
            .map { it.triggerMillis }
            .filter { it >= targetMillis }
            .minOrNull()
    }

    private fun nextRecurringMonthMillis(targetMillis: Long): Long {
        return Calendar.getInstance().apply {
            timeInMillis = targetMillis
            add(Calendar.MONTH, 1)
            set(Calendar.DAY_OF_MONTH, 1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 1)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
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
        val snapshotColor = row.backgroundColor ?: colorForSlot(row.colorSlot)
        val snapshotIconSlot = row.iconSlot ?: 0
        val now = System.currentTimeMillis()
        recurringTransactions.updateCategorySnapshot(
            categoryId = row.transactionCategoryID,
            categoryName = row.name,
            categoryColor = snapshotColor,
            categoryIconSlot = snapshotIconSlot,
            updatedAt = now,
        )
        recurringGhosts.updatePendingCategorySnapshot(
            categoryId = row.transactionCategoryID,
            categoryName = row.name,
            categoryColor = snapshotColor,
            categoryIconSlot = snapshotIconSlot,
            updatedAt = now,
        )
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

    suspend fun updateTransaction(args: Map<*, *>): Map<String, Any?> {
        seedIfEmpty()
        val id = optionalInt(args["id"])
            ?: throw ExpenseValidationException("INVALID_TRANSACTION_ID", "Transaction id is required")
        val existing = transactions.byId(id)
            ?: throw ExpenseValidationException("INVALID_TRANSACTION_ID", "Transaction does not exist")
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

        val type = args["type"]?.toString() ?: typeFromAmount(existing.amount)
        if (type != "income" && type != "expense") {
            throw ExpenseValidationException("INVALID_TRANSACTION_TYPE", "Type must be income or expense")
        }

        val categoryId = optionalInt(args["transactionCategoryID"]) ?: existing.transactionCategoryID
        categories.byId(categoryId)
            ?: throw ExpenseValidationException("INVALID_CATEGORY", "Category does not exist")

        val signedAmount = if (type == "income") kotlin.math.abs(rawAmount) else -kotlin.math.abs(rawAmount)
        val row = existing.copy(
            date = formatDate(args["date"]?.toString() ?: existing.date),
            time = args["time"]?.toString()?.trim().takeUnless { it.isNullOrEmpty() } ?: existing.time,
            merchant = merchant,
            amount = signedAmount,
            userAssignedName = if (args.containsKey("userAssignedName")) {
                args["userAssignedName"]?.toString()?.trim()?.takeIf { it.isNotEmpty() }
            } else {
                existing.userAssignedName
            },
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


    suspend fun renameTransactionsByMerchant(args: Map<*, *>): Int {
        seedIfEmpty()
        val originalMerchant = args["originalMerchant"]?.toString()?.trim()?.takeIf { it.isNotEmpty() }
            ?: throw ExpenseValidationException("INVALID_MERCHANT", "Original merchant is required")
        val userAssignedName = args["userAssignedName"]?.toString()?.trim()?.takeIf { it.isNotEmpty() }
            ?: throw ExpenseValidationException("INVALID_MERCHANT_NAME", "Custom merchant name is required")
        return transactions.renameByMerchant(originalMerchant, userAssignedName)
    }

    suspend fun resetTransactionNamesByMerchant(args: Map<*, *>): Int {
        seedIfEmpty()
        val originalMerchant = args["originalMerchant"]?.toString()?.trim()?.takeIf { it.isNotEmpty() }
            ?: throw ExpenseValidationException("INVALID_MERCHANT", "Original merchant is required")
        return transactions.resetNamesByMerchant(originalMerchant)
    }



    private fun recurringTargetMillis(): Long = debugClockStore.effectiveNow()

    private suspend fun syncRecurringGhosts(targetMillis: Long): List<RecurringTransactionEntity> {
        ensureRecurringGhostsForActivePeriod(targetMillis)
        return activateDueRecurringGhosts(targetMillis)
    }

    private suspend fun ensureRecurringGhostsForActivePeriod(targetMillis: Long) {
        for (recurring in recurringTransactions.active()) {
            ensureRecurringGhost(recurring, targetMillis)
        }
    }

    private suspend fun ensureRecurringGhost(recurring: RecurringTransactionEntity, targetMillis: Long) {
        if (!recurring.isActive) {
            recurringGhosts.deletePendingForRecurring(recurring.id)
            return
        }
        val plan = RecurringGhostPlanner.plan(
            targetMillis = targetMillis,
            dayOfMonth = recurring.dayOfMonth,
            lastProcessedPeriodKey = recurring.lastProcessedPeriodKey,
        )
        if (!plan.shouldShowGhost) {
            recurringGhosts.deletePendingForRecurring(recurring.id)
            return
        }
        if (recurringGhosts.pendingByRecurringAndPeriod(recurring.id, plan.periodKey) != null) return
        val now = System.currentTimeMillis()
        recurringGhosts.insert(
            RecurringGhostTransactionEntity(
                recurringTransactionId = recurring.id,
                periodKey = plan.periodKey,
                name = recurring.name,
                amount = recurring.amount,
                transactionType = recurring.transactionType,
                date = plan.date,
                time = "00:00",
                categoryId = recurring.categoryId,
                categoryName = recurring.categoryName,
                categoryColor = recurring.categoryColor,
                categoryIconSlot = recurring.categoryIconSlot,
                triggerMillis = plan.triggerMillis,
                isActivated = false,
                activatedTransactionId = null,
                createdAt = now,
                updatedAt = now,
            ),
        )
    }

    private suspend fun activateDueRecurringGhosts(targetMillis: Long): List<RecurringTransactionEntity> {
        val processed = mutableListOf<RecurringTransactionEntity>()
        for (ghost in recurringGhosts.due(targetMillis)) {
            val recurring = recurringTransactions.byId(ghost.recurringTransactionId) ?: continue
            if (!recurring.isActive) {
                recurringGhosts.deletePendingForRecurring(recurring.id)
                continue
            }
            val plan = RecurringGhostPlanner.plan(
                targetMillis = targetMillis,
                dayOfMonth = recurring.dayOfMonth,
                lastProcessedPeriodKey = recurring.lastProcessedPeriodKey,
            )
            if (!plan.shouldActivate || plan.periodKey != ghost.periodKey) continue
            val signedAmount = if (ghost.transactionType == "income") {
                kotlin.math.abs(ghost.amount)
            } else {
                -kotlin.math.abs(ghost.amount)
            }
            val transaction = ExpenseTransactionEntity(
                id = nextId(ghost.date),
                date = ghost.date,
                time = recurringTime(targetMillis),
                latitude = null,
                longitude = null,
                address = "Recurring transaction",
                merchant = ghost.name,
                amount = signedAmount,
                userAssignedName = ghost.name,
                transactionCategoryID = ghost.categoryId,
            )
            transactions.insert(transaction)
            val now = System.currentTimeMillis()
            val updated = recurring.copy(
                lastProcessedPeriodKey = ghost.periodKey,
                lastProcessedAt = now,
                updatedAt = now,
            )
            recurringTransactions.update(updated)
            recurringGhosts.markActivated(ghost.id, transaction.id, now)
            notificationCards.insert(
                RecurringNotificationCardFactory.activationCard(
                    recurring = updated,
                    ghost = ghost,
                    transaction = transaction,
                    now = now,
                ),
            )
            processed.add(updated)
        }
        return processed
    }


    private suspend fun buildRecurringRow(args: Map<*, *>, existing: RecurringTransactionEntity?): RecurringTransactionEntity {
        val name = args["name"]?.toString()?.trim()?.takeIf { it.isNotEmpty() }
            ?: existing?.name
            ?: throw ExpenseValidationException("INVALID_RECURRING_NAME", "Recurring transaction name is required")
        val amount = doubleArg(args["amount"], existing?.amount ?: 0.0)
        if (amount <= 0.0) {
            throw ExpenseValidationException("INVALID_RECURRING_AMOUNT", "Recurring transaction amount must be greater than zero")
        }
        val transactionType = normalizeNativeTransactionType(args["transactionType"]?.toString())
            ?: existing?.transactionType
            ?: "expense"
        val dayOfMonth = optionalInt(args["dayOfMonth"]) ?: existing?.dayOfMonth
            ?: throw ExpenseValidationException("INVALID_RECURRING_DAY", "Day of month is required")
        if (dayOfMonth !in 1..31) {
            throw ExpenseValidationException("INVALID_RECURRING_DAY", "Day of month must be between 1 and 31")
        }
        val categoryId = optionalInt(args["categoryId"]) ?: existing?.categoryId
            ?: throw ExpenseValidationException("INVALID_CATEGORY", "Category is required")
        val category = categories.byId(categoryId)
            ?: throw ExpenseValidationException("INVALID_CATEGORY", "Category does not exist")
        val now = System.currentTimeMillis()
        return RecurringTransactionEntity(
            id = existing?.id ?: 0,
            name = name,
            amount = kotlin.math.abs(amount),
            transactionType = transactionType,
            dayOfMonth = dayOfMonth,
            categoryId = category.transactionCategoryID,
            categoryName = category.name,
            categoryColor = category.backgroundColor ?: colorForSlot(category.colorSlot ?: 4),
            categoryIconSlot = category.iconSlot ?: 0,
            isActive = boolArg(args["isActive"], existing?.isActive ?: true),
            lastProcessedPeriodKey = existing?.lastProcessedPeriodKey,
            lastProcessedAt = existing?.lastProcessedAt,
            createdAt = existing?.createdAt ?: now,
            updatedAt = now,
        )
    }

    private fun recurringDate(targetMillis: Long, effectiveDayOfMonth: Int): String {
        val calendar = Calendar.getInstance().apply {
            timeInMillis = targetMillis
            set(Calendar.DAY_OF_MONTH, effectiveDayOfMonth)
        }
        return "%04d.%02d.%02d".format(
            calendar.get(Calendar.YEAR),
            calendar.get(Calendar.MONTH) + 1,
            calendar.get(Calendar.DAY_OF_MONTH),
        )
    }

    private fun recurringTime(targetMillis: Long): String {
        val calendar = Calendar.getInstance().apply { timeInMillis = targetMillis }
        return "%02d:%02d".format(
            calendar.get(Calendar.HOUR_OF_DAY),
            calendar.get(Calendar.MINUTE),
        )
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

    private fun colorForSlot(slot: Int?): String = CategoryColorSlotManager.colorForSlot(slot)

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
