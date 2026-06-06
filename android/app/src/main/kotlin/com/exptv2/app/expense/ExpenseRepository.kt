package com.exptv2.app.expense

import android.content.Context
import android.util.Log
import androidx.room.withTransaction
import com.exptv2.app.NotificationEventEntity
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
    private val recurringRules = db.recurringRules()
    private val recurringRuleInstances = db.recurringRuleInstances()
    private val notificationCards = db.notificationCards()
    private val notificationEmitter = ExpenseNotificationEmitter(appContext)
    private val settingsStore = ExpenseSettingsStore(appContext)
    private val debugClockStore = RecurringDebugClockStore(appContext)
    private val seedPrefs = appContext.getSharedPreferences("expense_seed", Context.MODE_PRIVATE)

    suspend fun bootstrap(): Map<String, Any?> {
        seedIfEmpty()
        val targetMillis = recurringTargetMillis()
        ensureRecurringRuleInstancesForPeriod(targetMillis)
        val categoryRows = categories.all()
        val transactionRows = transactions.all()
        val limitRows = categoryLimits.list(null, null, null)
        val instanceRows = recurringRuleInstances.pendingForPeriod(periodKeyFromMillis(targetMillis))
        return mapOf(
            "categories" to categoryRows.map { it.toMap() },
            "transactions" to transactionRows.map { it.toMap() },
            "limits" to limitRows.map { it.toMap() },
            "recurringGhostTransactions" to instanceRows.map { it.toLegacyGhostMap() },
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

    fun updatePushRecurringSettings(args: Map<*, *>): Map<String, Any?> = settingsStore.updatePushRecurringSettings(args)


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
        return recurringTransactions.all().map { it.toMap() }
    }

    suspend fun listRecurringRules(): List<Map<String, Any?>> {
        seedIfEmpty()
        ensureRecurringRuleInstancesForPeriod(recurringTargetMillis())
        return recurringRules.all().map { it.toMap() }
    }

    suspend fun addRecurringRule(args: Map<*, *>): Map<String, Any?> {
        seedIfEmpty()
        val row = buildRecurringRule(args, null)
        val id = recurringRules.insert(row).toInt()
        val saved = row.copy(id = id)
        ensureRecurringRuleInstancesForPeriod(recurringTargetMillis())
        RecurringAlarmScheduler(appContext).sync()
        return saved.toMap()
    }

    suspend fun updateRecurringRule(args: Map<*, *>): Map<String, Any?> {
        seedIfEmpty()
        val id = optionalInt(args["id"])
            ?: throw ExpenseValidationException("INVALID_RECURRING_RULE", "Recurring rule id is required")
        val existing = recurringRules.byId(id)
            ?: throw ExpenseValidationException("INVALID_RECURRING_RULE", "Recurring rule does not exist")
        val row = buildRecurringRule(args, existing)
        recurringRules.update(row)
        recurringRuleInstances.deletePendingForRule(row.id)
        if (row.isActive) {
            ensureRecurringRuleInstancesForPeriod(recurringTargetMillis())
        }
        RecurringAlarmScheduler(appContext).sync()
        return row.toMap()
    }

    suspend fun toggleRecurringRule(args: Map<*, *>): Map<String, Any?> {
        seedIfEmpty()
        val id = optionalInt(args["id"])
            ?: throw ExpenseValidationException("INVALID_RECURRING_RULE", "Recurring rule id is required")
        val existing = recurringRules.byId(id)
            ?: throw ExpenseValidationException("INVALID_RECURRING_RULE", "Recurring rule does not exist")
        val row = existing.copy(
            isActive = boolArg(args["isActive"], !existing.isActive),
            updatedAt = System.currentTimeMillis(),
        )
        recurringRules.update(row)
        if (row.isActive) {
            ensureRecurringRuleInstancesForPeriod(recurringTargetMillis())
        } else {
            recurringRuleInstances.deletePendingForRule(row.id)
        }
        RecurringAlarmScheduler(appContext).sync()
        return row.toMap()
    }

    suspend fun deleteRecurringRule(id: Int): Boolean {
        seedIfEmpty()
        val existing = recurringRules.byId(id) ?: return false
        recurringRuleInstances.deletePendingForRule(id)
        recurringRules.delete(existing)
        RecurringAlarmScheduler(appContext).sync()
        return true
    }

    suspend fun listRecurringGhostTransactions(): List<Map<String, Any?>> {
        seedIfEmpty()
        val targetMillis = recurringTargetMillis()
        ensureRecurringRuleInstancesForPeriod(targetMillis)
        return recurringRuleInstances.pendingForPeriod(periodKeyFromMillis(targetMillis)).map { it.toLegacyGhostMap() }
    }

    suspend fun ensureRecurringGhostTransactions(targetMillis: Long = recurringTargetMillis()): List<Map<String, Any?>> {
        seedIfEmpty()
        val currentMillis = recurringTargetMillis()
        val currentPeriod = periodKeyFromMillis(currentMillis)
        val targetPeriod = periodKeyFromMillis(targetMillis)
        ensureRecurringRuleInstancesForPeriod(currentMillis)
        if (targetPeriod < currentPeriod) return emptyList()
        if (targetPeriod != currentPeriod) {
            ensureRecurringRuleInstancesForPeriod(
                targetMillis = targetMillis,
                expirePastPending = false,
            )
        }
        return recurringRuleInstances.pendingForPeriod(targetPeriod).map { it.toLegacyGhostMap() }
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
        ensureRecurringRuleInstancesForPeriod(targetMillis)
        return activateDueDateTriggeredRuleInstances(targetMillis).map { it.toMap() }
    }

    suspend fun processNotificationEventForRecurring(event: NotificationEventEntity): Map<String, Any?>? {
        seedIfEmpty()
        if (event.isDuplicate) return null
        if (recurringRuleInstances.activatedCountForNotificationEvent(event.id) > 0) return null
        val targetMillis = event.timestamp
        ensureRecurringRuleInstancesForPeriod(targetMillis)
        val periodKey = RecurringRuleInstancePlanner.plan(targetMillis, 1, 0.0).periodKey
        val activePushRules = recurringRules.active()
            .filter { RecurringTriggerType.normalize(it.triggerType) == RecurringTriggerType.PUSH }
            .associateBy { it.id }
        if (activePushRules.isEmpty()) return null
        val notificationText = notificationText(event)
        val eventDate = dateFromMillis(targetMillis)
        val candidates = mutableListOf<PushRecurringCandidate>()
        for (instance in recurringRuleInstances.pendingForPeriod(periodKey)) {
            if (instance.triggerTypeSnapshot != RecurringTriggerType.PUSH) continue
            val rule = activePushRules[instance.ruleId] ?: continue
            val parsed = PushRecurringParser.parse(
                text = notificationText,
                amountPattern = rule.amountPattern,
                merchantPattern = rule.merchantPattern,
                includeKeyword = rule.includeKeyword,
            )
            val amount = parsed.amount ?: continue
            val merchant = parsed.merchant?.takeIf { it.isNotBlank() } ?: continue
            if (parsed.error != null) continue
            val score = PushRecurringMatcher.score(
                rule = PushRecurringMatchRule(
                    ruleId = rule.id,
                    instanceId = instance.id,
                    estimatedDate = instance.estimatedDate,
                    estimatedAmount = instance.estimatedAmount,
                    transactionType = rule.transactionType,
                    appFilterText = rule.appFilterText,
                    packageName = rule.packageName,
                    appLabel = rule.appLabel,
                    dateToleranceDays = rule.dateToleranceDays,
                    amountTolerancePercent = rule.amountTolerancePercent,
                    amountToleranceMin = rule.amountToleranceMin,
                    merchantSelection = rule.merchantSelection,
                ),
                event = PushRecurringMatchEvent(
                    notificationEventId = event.id,
                    appLabel = event.appLabel,
                    packageName = event.packageName,
                    date = eventDate,
                    amount = amount,
                    merchant = merchant,
                    transactionType = rule.transactionType,
                ),
            )
            if (score.matches) {
                candidates.add(PushRecurringCandidate(rule, instance, parsed, score))
            }
        }
        if (candidates.isEmpty()) return null
        if (settingsStore.loadPushRecurringConflictPolicy() == ExpenseSettingsStore.PUSH_RECURRING_POLICY_ASK_ON_MULTIPLE && candidates.size > 1) {
            Log.d(
                "ExpenseNotification",
                "[RecurringPush] ambiguous notification=${event.id} matches=${candidates.map { it.instance.id }}",
            )
            return mapOf("status" to "ambiguous", "matchCount" to candidates.size)
        }
        val selected = candidates.maxByOrNull { it.score.confidence } ?: return null
        return activatePushRecurringCandidate(selected, event).toMap()
    }

    suspend fun nextRecurringTriggerMillis(targetMillis: Long = recurringTargetMillis()): Long? {
        seedIfEmpty()
        ensureRecurringRuleInstancesForPeriod(targetMillis)
        nextPendingRuleTriggerAtOrAfter(targetMillis)?.let { return it }
        ensureRecurringRuleInstancesForPeriod(
            targetMillis = nextRecurringMonthMillis(targetMillis),
            expirePastPending = false,
        )
        return nextPendingRuleTriggerAtOrAfter(targetMillis)
    }

    private suspend fun nextPendingRuleTriggerAtOrAfter(targetMillis: Long): Long? {
        val date = dateFromMillis(targetMillis)
        return recurringRuleInstances.nextDateTriggeredAtOrAfter(date)
            ?.let { triggerMillisFromDate(it.estimatedDate) }
            ?.let { if (it < targetMillis) targetMillis else it }
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
        Log.d("ExpenseNotification", "[Notification] limit upsert requested args=$args")
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
        val rawTransactionType = args["transactionType"]?.toString()
        val transactionType = if (targetType == "overview" && rawTransactionType == "saving") {
            "saving"
        } else {
            normalizeNativeTransactionType(rawTransactionType)
                ?: throw ExpenseValidationException("INVALID_LIMIT_TYPE", "Limit transaction type is required")
        }
        if (targetType == "category" && transactionType == "saving") {
            throw ExpenseValidationException("INVALID_LIMIT_TYPE", "Saving limits are only valid for overview targets")
        }
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
        val saved = row.copy(id = if (row.id == 0) newId else row.id)
        Log.d(
            "ExpenseNotification",
            "[Notification] limit upsert saved id=${saved.id} target=${saved.targetType}:${saved.targetId} type=${saved.transactionType} window=${saved.window} period=${saved.periodKey} hasLimit=${saved.hasLimit} alertActive=${saved.alertActive} amount=${saved.limitAmount}",
        )
        emitLimitAlertForLimitChange(saved)
        return saved.toMap()
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
        recurringRules.updateCategorySnapshot(
            categoryId = row.transactionCategoryID,
            categoryName = row.name,
            categoryColor = snapshotColor,
            categoryIconSlot = snapshotIconSlot,
            updatedAt = now,
        )
        recurringRuleInstances.updatePendingCategorySnapshot(
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
        val query = transactionPageQuery(args, defaultLimit = Int.MAX_VALUE, maxLimit = Int.MAX_VALUE)
        return transactions.page(
            query.type,
            query.categoryId,
            query.merchant,
            query.searchQuery,
            query.yearMonth,
            query.limit,
            query.offset,
        ).map { it.toMap() }
    }

    suspend fun listTransactionPage(args: Map<*, *>): Map<String, Any?> {
        seedIfEmpty()
        val query = transactionPageQuery(args, defaultLimit = 96, maxLimit = 500)
        val startedAt = System.currentTimeMillis()
        val rows = transactions.page(
            query.type,
            query.categoryId,
            query.merchant,
            query.searchQuery,
            query.yearMonth,
            query.limit,
            query.offset,
        )
        val totalCount = transactions.pageCount(
            query.type,
            query.categoryId,
            query.merchant,
            query.searchQuery,
            query.yearMonth,
        )
        Log.d(
            "ExpenseRepository",
            "[Perf] transaction page type=${query.type ?: "all"} offset=${query.offset} limit=${query.limit} rows=${rows.size} total=$totalCount elapsed=${System.currentTimeMillis() - startedAt}ms",
        )
        return mapOf(
            "transactions" to rows.map { it.toMap() },
            "totalCount" to totalCount,
            "limit" to query.limit,
            "offset" to query.offset,
        )
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
        val category = categories.byId(categoryId)
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
        Log.d(
            "ExpenseNotification",
            "[Notification] transaction saved id=${row.id} amount=${row.amount} category=${row.transactionCategoryID}",
        )
        if (row.amount < 0) {
            emitLimitAlertsForTransaction(row, category)
        } else {
            Log.d("ExpenseNotification", "[Notification] transaction limit evaluation skipped id=${row.id} reason=non_expense")
        }
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
        val category = categories.byId(categoryId)
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
        Log.d(
            "ExpenseNotification",
            "[Notification] transaction update saved id=${row.id} oldAmount=${existing.amount} newAmount=${row.amount} oldCategory=${existing.transactionCategoryID} newCategory=${row.transactionCategoryID} oldDate=${existing.date} newDate=${row.date}",
        )
        if (row.amount < 0) {
            emitLimitAlertsForTransaction(row, category)
        } else {
            Log.d(
                "ExpenseNotification",
                "[Notification] transaction update limit evaluation skipped id=${row.id} reason=non_expense",
            )
        }
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



    private suspend fun emitLimitAlertForLimitChange(limit: CategoryLimitEntity) {
        if (limit.transactionType != "expense") {
            Log.d(
                "ExpenseNotification",
                "[Notification] limit change skipped id=${limit.id} reason=non_expense type=${limit.transactionType}",
            )
            return
        }
        if (!limit.hasLimit || !limit.alertActive || limit.limitAmount <= 0.0) {
            Log.d(
                "ExpenseNotification",
                "[Notification] limit change skipped id=${limit.id} reason=inactive hasLimit=${limit.hasLimit} alertActive=${limit.alertActive} amount=${limit.limitAmount}",
            )
            return
        }
        val category = when (limit.targetType) {
            "category" -> categories.byId(limit.targetId)
            else -> null
        }
        if (limit.targetType == "category" && category == null) {
            Log.d(
                "ExpenseNotification",
                "[Notification] limit change skipped id=${limit.id} reason=missing_category category=${limit.targetId}",
            )
            return
        }
        val dateRange = dateRangeForStoredLimit(limit)
        val spent = transactions.expenseSpentTotal(
            categoryId = if (limit.targetType == "category") limit.targetId else null,
            startDate = dateRange.first,
            endDate = dateRange.second,
        )
        val label = if (limit.targetType == "overview") "Kiadási budget" else category?.name ?: "Limit"
        val alert = ExpenseLimitNotificationEvaluator.evaluate(
            limit = limit,
            targetLabel = label,
            category = category,
            transaction = null,
            spentAmount = spent,
            triggerDate = limit.periodKey,
        )
        Log.d(
            "ExpenseNotification",
            "[Notification] limit change result id=${limit.id} target=${limit.targetType}:${limit.targetId} spent=$spent limit=${limit.limitAmount} range=${dateRange.first}..${dateRange.second} threshold=${alert?.type ?: "none"}",
        )
        if (alert != null) {
            notificationEmitter.emit(
                ExpenseNotificationCardFactory.limitAlert(alert, System.currentTimeMillis()),
                notificationCards,
            )
        }
    }

    private fun dateRangeForStoredLimit(limit: CategoryLimitEntity): Pair<String, String> {
        return when (limit.window) {
            "monthly" -> {
                val periods = ExpenseLimitNotificationEvaluator.periodsFor("${limit.periodKey}.01")
                periods.monthStart to periods.monthEnd
            }
            "yearly" -> {
                val year = limit.periodKey.toIntOrNull()
                if (year == null) "" to "" else "%04d.01.01".format(year) to "%04d.12.31".format(year)
            }
            else -> "" to ""
        }
    }

    private suspend fun emitLimitAlertsForTransaction(
        transaction: ExpenseTransactionEntity,
        transactionCategory: TransactionCategoryEntity,
    ) {
        val startedAt = System.currentTimeMillis()
        val periods = ExpenseLimitNotificationEvaluator.periodsFor(transaction.date)
        val limits = categoryLimits.activeExpenseLimitsForTransaction(
            categoryId = transaction.transactionCategoryID,
            monthKey = periods.monthKey,
            yearKey = periods.yearKey,
        )
        Log.d(
            "ExpenseNotification",
            "[Notification] limit evaluation start transaction=${transaction.id} category=${transaction.transactionCategoryID} limits=${limits.size}",
        )
        for (limit in limits) {
            val categoryId = if (limit.targetType == "category") limit.targetId else null
            val dateRange = dateRangeForLimit(limit, periods)
            val spent = transactions.expenseSpentTotal(
                categoryId = categoryId,
                startDate = dateRange.first,
                endDate = dateRange.second,
            )
            val label = if (limit.targetType == "overview") "Kiadási budget" else transactionCategory.name
            val category = if (limit.targetType == "category") transactionCategory else null
            val alert = ExpenseLimitNotificationEvaluator.evaluate(
                limit = limit,
                targetLabel = label,
                category = category,
                transaction = transaction,
                spentAmount = spent,
            )
            Log.d(
                "ExpenseNotification",
                "[Notification] limit result id=${limit.id} target=${limit.targetType}:${limit.targetId} spent=$spent limit=${limit.limitAmount} threshold=${alert?.type ?: "none"}",
            )
            if (alert != null) {
                notificationEmitter.emit(
                    ExpenseNotificationCardFactory.limitAlert(alert, System.currentTimeMillis()),
                    notificationCards,
                )
            }
        }
        Log.d(
            "ExpenseNotification",
            "[Perf] limit evaluation complete transaction=${transaction.id} elapsed=${System.currentTimeMillis() - startedAt}ms",
        )
    }

    private fun dateRangeForLimit(
        limit: CategoryLimitEntity,
        periods: ExpenseLimitPeriods,
    ): Pair<String, String> {
        return when (limit.window) {
            "monthly" -> periods.monthStart to periods.monthEnd
            "yearly" -> periods.yearStart to periods.yearEnd
            else -> "" to ""
        }
    }

    private fun recurringTargetMillis(): Long = debugClockStore.effectiveNow()

    private suspend fun ensureRecurringRuleInstancesForPeriod(
        targetMillis: Long,
        expirePastPending: Boolean = true,
    ) {
        val now = System.currentTimeMillis()
        val currentPeriod = RecurringRuleInstancePlanner.plan(targetMillis, 1, 0.0).periodKey
        if (expirePastPending) recurringRuleInstances.expirePastPending(currentPeriod, now)
        for (rule in recurringRules.active()) {
            val plan = RecurringRuleInstancePlanner.plan(
                targetMillis = targetMillis,
                expectedDayOfMonth = rule.expectedDayOfMonth,
                estimatedAmount = rule.estimatedAmount,
            )
            if (recurringRuleInstances.byRuleAndPeriod(rule.id, plan.periodKey) != null) continue
            recurringRuleInstances.insert(
                RecurringRuleInstanceEntity(
                    ruleId = rule.id,
                    periodKey = plan.periodKey,
                    status = RecurringRuleInstanceStatus.PENDING,
                    estimatedDate = plan.estimatedDate,
                    estimatedAmount = plan.estimatedAmount,
                    triggerTypeSnapshot = rule.triggerType,
                    transactionTypeSnapshot = rule.transactionType,
                    nameSnapshot = rule.name,
                    categoryIdSnapshot = rule.categoryId,
                    categoryNameSnapshot = rule.categoryName,
                    categoryColorSnapshot = rule.categoryColor,
                    categoryIconSlotSnapshot = rule.categoryIconSlot,
                    activatedTransactionId = null,
                    activatedAt = null,
                    matchedNotificationEventId = null,
                    matchConfidence = null,
                    createdAt = now,
                    updatedAt = now,
                ),
            )
        }
    }

    private suspend fun activateDueDateTriggeredRuleInstances(targetMillis: Long): List<RecurringRuleEntity> {
        val processed = mutableListOf<RecurringRuleEntity>()
        val now = System.currentTimeMillis()
        for (instance in recurringRuleInstances.dueDateTriggered(dateFromMillis(targetMillis))) {
            val rule = recurringRules.byId(instance.ruleId) ?: continue
            if (!rule.isActive) {
                recurringRuleInstances.updateStatus(instance.id, RecurringRuleInstanceStatus.EXPIRED, now)
                continue
            }
            if (RecurringTriggerType.normalize(rule.triggerType) != RecurringTriggerType.DATE) continue
            val signedAmount = if (instance.transactionTypeSnapshot == "income") {
                kotlin.math.abs(instance.estimatedAmount)
            } else {
                -kotlin.math.abs(instance.estimatedAmount)
            }
            val transaction = ExpenseTransactionEntity(
                id = nextId(instance.estimatedDate),
                date = instance.estimatedDate,
                time = recurringTime(targetMillis),
                latitude = null,
                longitude = null,
                address = "Recurring rule transaction",
                merchant = instance.nameSnapshot,
                amount = signedAmount,
                userAssignedName = instance.nameSnapshot,
                transactionCategoryID = instance.categoryIdSnapshot,
                recurringTransactionId = rule.id,
                recurringRuleId = rule.id,
                recurringInstanceId = instance.id,
            )
            transactions.insert(transaction)
            recurringRuleInstances.markActivated(
                id = instance.id,
                transactionId = transaction.id,
                activatedAt = now,
                eventId = null,
                confidence = null,
            )
            Log.d(
                "ExpenseNotification",
                "[RecurringRule] date activation instance=${instance.id} rule=${rule.id} transaction=${transaction.id} amount=${transaction.amount}",
            )
            notificationEmitter.emit(
                ExpenseNotificationCardFactory.recurringRuleActivated(
                    rule = rule,
                    instance = instance,
                    transaction = transaction,
                    now = now,
                ),
                notificationCards,
            )
            categories.byId(transaction.transactionCategoryID)?.let { emitLimitAlertsForTransaction(transaction, it) }
            processed.add(rule.copy(updatedAt = now))
        }
        return processed
    }

    private suspend fun activatePushRecurringCandidate(
        candidate: PushRecurringCandidate,
        event: NotificationEventEntity,
    ): ExpenseTransactionEntity {
        val rule = candidate.rule
        val instance = candidate.instance
        val merchant = candidate.parsed.merchant?.takeIf { it.isNotBlank() } ?: rule.name
        val parsedAmount = candidate.parsed.amount ?: rule.estimatedAmount
        val date = dateFromMillis(event.timestamp)
        val signedAmount = if (rule.transactionType == "income") {
            kotlin.math.abs(parsedAmount)
        } else {
            -kotlin.math.abs(parsedAmount)
        }
        val transaction = ExpenseTransactionEntity(
            id = nextId(date),
            date = date,
            time = timeFromMillis(event.timestamp),
            latitude = null,
            longitude = null,
            address = "Push recurring transaction",
            merchant = merchant,
            amount = signedAmount,
            userAssignedName = rule.name,
            transactionCategoryID = rule.categoryId,
            recurringTransactionId = rule.id,
            recurringRuleId = rule.id,
            recurringInstanceId = instance.id,
        )
        transactions.insert(transaction)
        val now = System.currentTimeMillis()
        recurringRuleInstances.markActivated(
            id = instance.id,
            transactionId = transaction.id,
            activatedAt = now,
            eventId = event.id,
            confidence = candidate.score.confidence,
        )
        notificationEmitter.emit(
            ExpenseNotificationCardFactory.recurringRuleActivated(
                rule = rule,
                instance = instance,
                transaction = transaction,
                now = now,
            ),
            notificationCards,
        )
        categories.byId(transaction.transactionCategoryID)?.let { emitLimitAlertsForTransaction(transaction, it) }
        return transaction
    }

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
                recurringTransactionId = recurring.id,
            )
            transactions.insert(transaction)
            Log.d(
                "ExpenseNotification",
                "[Notification] recurring activation requested ghost=${ghost.id} recurring=${recurring.id} transaction=${transaction.id} amount=${transaction.amount}",
            )
            val now = System.currentTimeMillis()
            val updated = recurring.copy(
                lastProcessedPeriodKey = ghost.periodKey,
                lastProcessedAt = now,
                updatedAt = now,
            )
            recurringTransactions.update(updated)
            recurringGhosts.markActivated(ghost.id, transaction.id, now)
            notificationEmitter.emit(
                ExpenseNotificationCardFactory.recurringActivated(
                    recurring = updated,
                    ghost = ghost,
                    transaction = transaction,
                    now = now,
                ),
                notificationCards,
            )
            if (transaction.amount < 0) {
                val category = categories.byId(transaction.transactionCategoryID)
                if (category != null) {
                    emitLimitAlertsForTransaction(transaction, category)
                } else {
                    Log.d(
                        "ExpenseNotification",
                        "[Notification] recurring limit evaluation skipped transaction=${transaction.id} reason=missing_category category=${transaction.transactionCategoryID}",
                    )
                }
            } else {
                Log.d(
                    "ExpenseNotification",
                    "[Notification] recurring limit evaluation skipped transaction=${transaction.id} reason=non_expense",
                )
            }
            processed.add(updated)
        }
        return processed
    }


    private suspend fun buildRecurringRule(args: Map<*, *>, existing: RecurringRuleEntity?): RecurringRuleEntity {
        val name = args["name"]?.toString()?.trim()?.takeIf { it.isNotEmpty() }
            ?: existing?.name
            ?: throw ExpenseValidationException("INVALID_RECURRING_RULE_NAME", "Recurring rule name is required")
        val estimatedAmount = doubleArg(args["estimatedAmount"], existing?.estimatedAmount ?: 0.0)
        if (estimatedAmount <= 0.0) {
            throw ExpenseValidationException("INVALID_RECURRING_RULE_AMOUNT", "Estimated amount must be greater than zero")
        }
        val expectedDay = optionalInt(args["expectedDayOfMonth"]) ?: existing?.expectedDayOfMonth
            ?: throw ExpenseValidationException("INVALID_RECURRING_RULE_DAY", "Expected day is required")
        if (expectedDay !in 1..31) {
            throw ExpenseValidationException("INVALID_RECURRING_RULE_DAY", "Expected day must be between 1 and 31")
        }
        val categoryId = optionalInt(args["categoryId"]) ?: existing?.categoryId
            ?: throw ExpenseValidationException("INVALID_CATEGORY", "Category is required")
        val category = categories.byId(categoryId)
            ?: throw ExpenseValidationException("INVALID_CATEGORY", "Category does not exist")
        val triggerType = RecurringTriggerType.normalize(args["triggerType"]?.toString() ?: existing?.triggerType)
        val transactionType = normalizeNativeTransactionType(args["transactionType"]?.toString()) ?: existing?.transactionType ?: "expense"
        val appFilterText = args["appFilterText"]?.toString() ?: existing?.appFilterText ?: ""
        val packageName = args["packageName"]?.toString() ?: existing?.packageName ?: ""
        val appLabel = args["appLabel"]?.toString() ?: existing?.appLabel ?: ""
        val sampleText = args["sampleText"]?.toString() ?: existing?.sampleText ?: ""
        val includeKeyword = args["includeKeyword"]?.toString() ?: existing?.includeKeyword ?: ""
        val amountPattern = args["amountPattern"]?.toString() ?: existing?.amountPattern ?: ""
        val amountSelection = args["amountSelection"]?.toString() ?: existing?.amountSelection ?: ""
        val merchantPattern = args["merchantPattern"]?.toString() ?: existing?.merchantPattern ?: ""
        val merchantSelection = args["merchantSelection"]?.toString() ?: existing?.merchantSelection ?: ""
        val dateToleranceDays = optionalInt(args["dateToleranceDays"]) ?: existing?.dateToleranceDays ?: 5
        val amountTolerancePercent = doubleArg(args["amountTolerancePercent"], existing?.amountTolerancePercent ?: 20.0)
        val amountToleranceMin = doubleArg(args["amountToleranceMin"], existing?.amountToleranceMin ?: 5000.0)
        validateRecurringRulePushSettings(
            triggerType = triggerType,
            appFilterText = appFilterText,
            sampleText = sampleText,
            includeKeyword = includeKeyword,
            amountPattern = amountPattern,
            amountSelection = amountSelection,
            merchantPattern = merchantPattern,
            merchantSelection = merchantSelection,
            dateToleranceDays = dateToleranceDays,
            amountTolerancePercent = amountTolerancePercent,
            amountToleranceMin = amountToleranceMin,
        )
        val now = System.currentTimeMillis()
        return RecurringRuleEntity(
            id = existing?.id ?: 0,
            triggerType = triggerType,
            transactionType = transactionType,
            name = name,
            estimatedAmount = kotlin.math.abs(estimatedAmount),
            expectedDayOfMonth = expectedDay,
            categoryId = category.transactionCategoryID,
            categoryName = category.name,
            categoryColor = category.backgroundColor ?: colorForSlot(category.colorSlot ?: 4),
            categoryIconSlot = category.iconSlot ?: 0,
            isActive = boolArg(args["isActive"], existing?.isActive ?: true),
            appFilterText = appFilterText,
            packageName = packageName,
            appLabel = appLabel,
            sampleText = sampleText,
            includeKeyword = includeKeyword,
            amountPattern = amountPattern,
            amountSelection = amountSelection,
            merchantPattern = merchantPattern,
            merchantSelection = merchantSelection,
            dateToleranceDays = dateToleranceDays,
            amountTolerancePercent = amountTolerancePercent,
            amountToleranceMin = amountToleranceMin,
            createdAt = existing?.createdAt ?: now,
            updatedAt = now,
        )
    }

    private fun validateRecurringRulePushSettings(
        triggerType: String,
        appFilterText: String,
        sampleText: String,
        includeKeyword: String,
        amountPattern: String,
        amountSelection: String,
        merchantPattern: String,
        merchantSelection: String,
        dateToleranceDays: Int,
        amountTolerancePercent: Double,
        amountToleranceMin: Double,
    ) {
        if (dateToleranceDays < 0 || amountTolerancePercent < 0.0 || amountToleranceMin < 0.0) {
            throw ExpenseValidationException(
                "INVALID_RECURRING_RULE_PUSH",
                "Push recurring tolerances cannot be negative",
            )
        }
        if (RecurringTriggerType.normalize(triggerType) != RecurringTriggerType.PUSH) return
        if (appFilterText.isBlank()) {
            throw ExpenseValidationException(
                "INVALID_RECURRING_RULE_PUSH",
                "Push recurring app filter is required",
            )
        }
        if (amountSelection.isBlank() || merchantSelection.isBlank()) {
            throw ExpenseValidationException(
                "INVALID_RECURRING_RULE_PUSH",
                "Push recurring amount and merchant selections are required",
            )
        }
        val parsed = PushRecurringParser.parse(
            text = sampleText,
            amountPattern = amountPattern,
            merchantPattern = merchantPattern,
            includeKeyword = includeKeyword,
        )
        if (parsed.error != null || parsed.amount == null || parsed.merchant.isNullOrBlank()) {
            throw ExpenseValidationException(
                "INVALID_RECURRING_RULE_PUSH",
                "Push recurring sample must extract amount and merchant",
            )
        }
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

    private fun dateFromMillis(targetMillis: Long): String {
        val calendar = Calendar.getInstance().apply { timeInMillis = targetMillis }
        return "%04d.%02d.%02d".format(
            calendar.get(Calendar.YEAR),
            calendar.get(Calendar.MONTH) + 1,
            calendar.get(Calendar.DAY_OF_MONTH),
        )
    }

    private fun periodKeyFromMillis(targetMillis: Long): String {
        val calendar = Calendar.getInstance().apply { timeInMillis = targetMillis }
        return "%04d-%02d".format(
            calendar.get(Calendar.YEAR),
            calendar.get(Calendar.MONTH) + 1,
        )
    }

    private fun timeFromMillis(targetMillis: Long): String {
        val calendar = Calendar.getInstance().apply { timeInMillis = targetMillis }
        return "%02d:%02d".format(calendar.get(Calendar.HOUR_OF_DAY), calendar.get(Calendar.MINUTE))
    }

    private fun triggerMillisFromDate(value: String): Long {
        val parts = value.trim().replace('.', '-').split("-")
        if (parts.size != 3) return 0L
        val year = parts[0].toIntOrNull() ?: return 0L
        val month = parts[1].toIntOrNull() ?: return 0L
        val day = parts[2].toIntOrNull() ?: return 0L
        return Calendar.getInstance().apply {
            set(Calendar.YEAR, year)
            set(Calendar.MONTH, month - 1)
            set(Calendar.DAY_OF_MONTH, day)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
    }

    private fun notificationText(event: NotificationEventEntity): String = listOf(event.title, event.text, event.bigText, event.subText)
        .filter { it.isNotBlank() }
        .joinToString("\n")

    private suspend fun seedIfEmpty() {
        val currentVersion = seedPrefs.getInt("demo_seed_version", 0)
        if (currentVersion < ExpenseSeedData.version) {
            resetDemoData()
            seedPrefs.edit().putInt("demo_seed_version", ExpenseSeedData.version).apply()
            return
        }
        db.withTransaction {
            if (categories.count() == 0) categories.insertAll(ExpenseSeedData.categories)
            if (transactions.count() == 0) transactions.insertAll(ExpenseSeedData.transactions)
            if (categoryLimits.list(null, null, null).isEmpty()) {
                categoryLimits.insertAll(ExpenseSeedData.limits)
            }
        }
    }

    private suspend fun resetDemoData() {
        db.withTransaction {
            notificationCards.clearAllHard()
            recurringRuleInstances.clearAll()
            recurringRules.clearAll()
            recurringGhosts.clearAll()
            recurringTransactions.clearAll()
            transactions.clearAll()
            categoryLimits.clearAll()
            categories.clearAll()
            categories.insertAll(ExpenseSeedData.categories)
            transactions.insertAll(ExpenseSeedData.transactions)
            categoryLimits.insertAll(ExpenseSeedData.limits)
        }
        Log.d(
            "ExpenseRepository",
            "Reset demo data version=${ExpenseSeedData.version} categories=${ExpenseSeedData.categories.size} transactions=${ExpenseSeedData.transactions.size} limits=${ExpenseSeedData.limits.size}",
        )
    }

    private suspend fun nextId(date: String): Int {
        val parts = date.split(".")
        val prefix = parts[0].takeLast(2) + parts[1].padStart(2, '0')
        val max = transactions.maxIdForPrefix(prefix)
        return if (max == null) "${prefix}01".toInt() else max + 1
    }

    private suspend fun nextCategoryId(): Int = (categories.maxId() ?: 0) + 1

    private fun typeFromAmount(amount: Double): String = if (amount > 0) "income" else "expense"

    private data class PushRecurringCandidate(
        val rule: RecurringRuleEntity,
        val instance: RecurringRuleInstanceEntity,
        val parsed: PushRecurringParseResult,
        val score: PushRecurringMatchScore,
    )

    private data class TransactionPageQuery(
        val type: String?,
        val categoryId: Int?,
        val merchant: String,
        val searchQuery: String,
        val yearMonth: String,
        val limit: Int,
        val offset: Int,
    )

    private fun transactionPageQuery(
        args: Map<*, *>,
        defaultLimit: Int,
        maxLimit: Int,
    ): TransactionPageQuery {
        val type = normalizeNativeTransactionType(args["type"]?.toString())
        val categoryId = optionalInt(args["categoryId"])
        val merchant = args["merchant"]?.toString()?.trim().orEmpty()
        val searchQuery = args["searchQuery"]?.toString()?.trim().orEmpty()
        val yearMonth = args["yearMonth"]?.toString()?.trim().orEmpty()
        val requestedLimit = optionalInt(args["limit"]) ?: defaultLimit
        val limit = requestedLimit.coerceIn(1, maxLimit)
        val offset = (optionalInt(args["offset"]) ?: 0).coerceAtLeast(0)
        return TransactionPageQuery(
            type = type,
            categoryId = categoryId,
            merchant = merchant,
            searchQuery = searchQuery,
            yearMonth = yearMonth,
            limit = limit,
            offset = offset,
        )
    }

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
