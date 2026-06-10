package com.exptv2.app

import android.content.Context
import android.content.pm.PackageManager
import android.util.Log
import com.exptv2.app.expense.ExpenseRepository
import java.security.MessageDigest
import java.util.Calendar

class NotificationEventRepository(context: Context) {
    private val appContext = context.applicationContext
    private val dao = PushParserDatabase.get(appContext).events()
    private val expenseRepository = ExpenseRepository(appContext)
    private val parserRuleStore = NotificationParserRuleStore(appContext)

    suspend fun insertDraft(draft: EventDraft): NotificationEventEntity? {
        val appLabel = draft.appLabel.ifBlank { resolveAppLabel(draft.packageName) }
        if (!parserRuleStore.automaticPushParserEnabled()) {
            logCaptureSkip(draft, appLabel, "global_disabled")
            return null
        }
        val eligibility = NotificationCaptureEligibility.evaluate(
            profiles = parserRuleStore.activeCaptureProfiles(),
            packageName = draft.packageName,
            appLabel = appLabel,
        )
        logCaptureDecision(draft, appLabel, eligibility)
        if (!eligibility.allowed) return null

        val hash = stableHash(draft.packageName, draft.title, draft.text, draft.bigText)
        val duplicate = dao.countByHash(hash) > 0
        val entity = NotificationEventEntity(
            timestamp = draft.timestamp,
            source = draft.source,
            packageName = draft.packageName,
            appLabel = appLabel,
            title = draft.title,
            text = draft.text,
            bigText = draft.bigText,
            subText = draft.subText,
            category = draft.category,
            notificationKey = draft.notificationKey,
            accessibilityEventType = draft.accessibilityEventType,
            hash = hash,
            isDuplicate = duplicate,
            manualStatus = "",
        )
        val id = dao.insert(entity)
        val saved = entity.copy(id = id)
        runCatching {
            expenseRepository.processNotificationEventForRecurring(saved)
        }.onFailure { error ->
            Log.d(
                "ExpenseNotification",
                "[RecurringPush] event=${saved.id} processing failed: ${error.message}",
            )
        }
        runCatching {
            expenseRepository.processNotificationEventForParserProfiles(
                event = saved,
                profiles = parserRuleStore.activeParserProfiles(),
            )
        }.onFailure { error ->
            Log.d(
                "ExpenseNotification",
                "[PushParser] event=${saved.id} auto processing failed: ${error.message}",
            )
            EventBroadcaster.publishDebugLog(
                "[PushParser] event=${saved.id} auto processing failed: ${error.message}",
            )
        }
        return saved
    }

    private fun logCaptureSkip(
        draft: EventDraft,
        appLabel: String,
        reason: String,
    ) {
        val message = "[PushParser] capture skipped source=${draft.source} " +
            "package=${draft.packageName} label=$appLabel reason=$reason"
        Log.d("ExpenseNotification", message)
        EventBroadcaster.publishDebugLog(message)
    }

    private fun logCaptureDecision(
        draft: EventDraft,
        appLabel: String,
        eligibility: NotificationCaptureEligibilityResult,
    ) {
        val decision = if (eligibility.allowed) "accepted" else "skipped"
        val profile = eligibility.profileId.takeIf { it.isNotBlank() }
            ?.let { " profile=$it" }
            .orEmpty()
        val message = "[PushParser] capture $decision source=${draft.source} " +
            "package=${draft.packageName} label=$appLabel reason=${eligibility.reason}$profile"
        Log.d("ExpenseNotification", message)
        EventBroadcaster.publishDebugLog(message)
    }

    suspend fun allEvents(): List<NotificationEventEntity> = dao.allEvents()

    suspend fun eventsAfterId(afterId: Long): List<NotificationEventEntity> =
        dao.eventsAfterId(afterId)

    suspend fun listPage(args: Map<*, *>): NotificationEventPage {
        val pageQuery = pageQuery(args)
        val scanLimit = maxOf(pageQuery.limit * 4, 64).coerceAtMost(500)
        val rows = mutableListOf<NotificationEventPageRow>()
        var total = 0
        var skipped = 0
        var candidateOffset = 0
        while (true) {
            val candidates = dao.pageCandidates(
                startMillis = pageQuery.startMillis,
                endMillis = pageQuery.endMillis,
                packageName = pageQuery.packageName,
                query = pageQuery.query,
                systemOnly = if (pageQuery.status == NotificationEventStatus.SYSTEM) 1 else 0,
                excludeSystem = if (pageQuery.status == NotificationEventStatus.MISSING) 1 else 0,
                limit = scanLimit,
                offset = candidateOffset,
            )
            if (candidates.isEmpty()) break
            val linked = expenseRepository.transactionsByNotificationEventIds(candidates.map { it.id })
            for (event in candidates) {
                val transaction = linked[event.id]
                val status = NotificationEventStatus.forEvent(event.manualStatus, transaction?.id)
                if (!NotificationEventStatus.matchesFilter(pageQuery.status, status)) continue
                total += 1
                if (skipped < pageQuery.offset) {
                    skipped += 1
                    continue
                }
                if (rows.size < pageQuery.limit) {
                    rows.add(NotificationEventPageRow(event, status, transaction?.id))
                }
            }
            candidateOffset += candidates.size
        }
        return NotificationEventPage(rows, total, pageQuery.limit, pageQuery.offset)
    }

    suspend fun eventById(id: Long): NotificationEventPageRow? {
        val event = dao.byId(id) ?: return null
        val transaction = expenseRepository.transactionsByNotificationEventIds(listOf(id))[id]
        val status = NotificationEventStatus.forEvent(event.manualStatus, transaction?.id)
        return NotificationEventPageRow(event, status, transaction?.id)
    }

    suspend fun markSystem(id: Long): Boolean {
        return dao.updateManualStatus(id, NotificationEventStatus.SYSTEM) > 0
    }

    suspend fun clear() = dao.clear()

    suspend fun totalCount(): Long = dao.count()

    suspend fun lastNotificationListenerEvent(): Long = dao.lastEventTime(SOURCE_NOTIFICATION_LISTENER) ?: 0L

    suspend fun lastAccessibilityEvent(): Long = dao.lastEventTime(SOURCE_ACCESSIBILITY) ?: 0L

    private fun resolveAppLabel(packageName: String): String {
        if (packageName.isBlank()) return ""
        return try {
            val pm = appContext.packageManager
            val info = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(info).toString()
        } catch (_: PackageManager.NameNotFoundException) {
            packageName
        }
    }

    private fun pageQuery(args: Map<*, *>): NotificationEventPageQuery {
        val limit = optionalInt(args["limit"])?.coerceIn(1, 120) ?: 60
        val offset = optionalInt(args["offset"])?.coerceAtLeast(0) ?: 0
        val year = optionalInt(args["year"])
        val month = optionalInt(args["month"])
        val range = millisRange(year, month)
        return NotificationEventPageQuery(
            limit = limit,
            offset = offset,
            startMillis = range.first,
            endMillis = range.second,
            query = args["query"]?.toString()?.trim().orEmpty(),
            status = NotificationEventStatus.normalizeFilter(args["status"]),
            packageName = args["packageName"]?.toString()?.trim().orEmpty(),
        )
    }

    private fun millisRange(year: Int?, month: Int?): Pair<Long?, Long?> {
        if (year == null) return null to null
        val normalizedMonth = month?.takeIf { it in 1..12 }
        val start = Calendar.getInstance().apply {
            clear()
            set(Calendar.YEAR, year)
            set(Calendar.MONTH, (normalizedMonth ?: 1) - 1)
            set(Calendar.DAY_OF_MONTH, 1)
        }
        val end = (start.clone() as Calendar).apply {
            if (normalizedMonth == null) {
                add(Calendar.YEAR, 1)
            } else {
                add(Calendar.MONTH, 1)
            }
        }
        return start.timeInMillis to end.timeInMillis
    }

    private fun optionalInt(value: Any?): Int? {
        return (value as? Number)?.toInt() ?: value?.toString()?.toIntOrNull()
    }

    companion object {
        const val SOURCE_NOTIFICATION_LISTENER = "notification_listener"
        const val SOURCE_ACCESSIBILITY = "accessibility"

        fun stableHash(packageName: String, title: String, text: String, bigText: String): String {
            val input = listOf(packageName, title, text, bigText)
                .joinToString("|") { it.trim().lowercase() }
            val digest = MessageDigest.getInstance("SHA-256").digest(input.toByteArray())
            return digest.joinToString("") { byte -> "%02x".format(byte) }
        }
    }
}

data class EventDraft(
    val timestamp: Long,
    val source: String,
    val packageName: String,
    val appLabel: String = "",
    val title: String = "",
    val text: String = "",
    val bigText: String = "",
    val subText: String = "",
    val category: String = "",
    val notificationKey: String = "",
    val accessibilityEventType: String = "",
)
