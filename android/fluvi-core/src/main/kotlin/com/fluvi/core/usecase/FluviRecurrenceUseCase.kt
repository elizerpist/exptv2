package com.fluvi.core.usecase

import androidx.room.withTransaction
import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.entity.FluviRecurrenceOccurrenceEntity
import com.fluvi.core.database.entity.FluviRecurrenceRuleEntity
import com.fluvi.core.database.entity.FluviOccurrenceOverrideEntity
import com.fluvi.core.database.entity.FluviPushRecurringRuleConfigEntity
import com.fluvi.core.database.entity.FluviTimeRecurringRuleConfigEntity
import com.fluvi.core.database.entity.FluviPartnerAliasEntity
import com.fluvi.core.database.entity.FluviPartnerEntity
import com.fluvi.core.model.CategoryAssignmentMode
import com.fluvi.core.model.CreateRecurrenceRuleCommand
import com.fluvi.core.model.UpdateRecurrenceRuleCommand
import com.fluvi.core.model.RecurrencePreviewRequest
import com.fluvi.core.model.FluviRecurrencePreview
import com.fluvi.core.model.CreateRecurringLedgerEntryCommand
import com.fluvi.core.model.FluviClock
import com.fluvi.core.model.FluviIdGenerator
import com.fluvi.core.model.FluviRecurrenceDashboardSnapshot
import com.fluvi.core.model.FluviRecurrenceOccurrence
import com.fluvi.core.model.FluviRecurrenceRule
import com.fluvi.core.model.FluviTimeRecurrenceEvidence
import com.fluvi.core.model.FluviSystemIds
import com.fluvi.core.model.LedgerCategorySelection
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.LedgerOriginKind
import com.fluvi.core.model.RecurrenceAmountPolicy
import com.fluvi.core.model.RecurrenceOccurrenceStatus
import com.fluvi.core.model.RecurrenceRealizationKind
import com.fluvi.core.model.RecurrenceTriggerKind
import com.fluvi.core.model.UpdateOccurrenceOverrideCommand
import com.fluvi.core.model.ManualTransactionPartnerSelection
import com.fluvi.core.repository.FluviPartnerRepository
import com.fluvi.core.repository.PartnerAliasNormalizer
import java.time.Instant
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId
import java.time.ZonedDateTime

/**
 * Owns recurrence snapshots. Pending occurrences never go through Ledger DAO,
 * which is the invariant that prevents preview amounts from entering totals.
 */
class FluviRecurrenceUseCase internal constructor(
    private val database: FluviDatabase,
    private val ledger: FluviLedgerWriteUseCase,
    private val partners: FluviPartnerRepository,
    private val idGenerator: FluviIdGenerator,
    private val clock: FluviClock,
) {
    suspend fun dashboard(): FluviRecurrenceDashboardSnapshot = database.withTransaction {
        ensureRollingWindowInTransaction()
        val dao = database.recurrenceDao()
        FluviRecurrenceDashboardSnapshot(
            rules = dao.rules().map { ruleModel(it) },
            pendingCount = dao.countByStatus(RecurrenceOccurrenceStatus.pending),
            dueCount = dao.dueCount(clock.nowUtcMs()),
            realizedCount = dao.countByStatus(RecurrenceOccurrenceStatus.realized),
            showPendingGhostsInLedger = dao.showPendingGhosts() ?: true,
        )
    }

    suspend fun rules(): List<FluviRecurrenceRule> = database.withTransaction {
        ensureRollingWindowInTransaction()
        database.recurrenceDao().rules().map { ruleModel(it) }
    }

    suspend fun rule(ruleId: String): FluviRecurrenceRule = database.withTransaction {
        ensureRollingWindowInTransaction()
        ruleModel(requireNotNull(database.recurrenceDao().rule(ruleId)) { "Unknown recurrence rule." })
    }

    suspend fun occurrences(
        status: RecurrenceOccurrenceStatus? = null,
        ruleId: String? = null,
        fromUtcMs: Long? = null,
        toUtcMs: Long? = null,
        limit: Int = 100,
        offset: Int = 0,
    ): List<FluviRecurrenceOccurrence> = database.withTransaction {
        require(limit in 1..200) { "Occurrence page size must be 1..200." }
        val dao = database.recurrenceDao()
        dao.occurrencePageFiltered(ruleId, status, fromUtcMs, toUtcMs, limit, offset)
            .map(::occurrenceModel)
    }

    suspend fun occurrence(occurrenceId: String): FluviRecurrenceOccurrence = database.withTransaction {
        occurrenceModel(requireOccurrence(occurrenceId))
    }

    /**
     * Resolves the one Ledger record that realizes an occurrence without
     * materialising a second transaction list.  Pending previews deliberately
     * return null: opening one of those must remain an occurrence-detail flow.
     */
    suspend fun realizedLedgerEntryId(occurrenceId: String): String? = database.withTransaction {
        val occurrence = database.recurrenceDao().occurrence(occurrenceId)
            ?: return@withTransaction null
        if (occurrence.status != RecurrenceOccurrenceStatus.realized) {
            return@withTransaction null
        }
        database.ledgerDao().findByRecurrenceOccurrenceId(occurrenceId)?.id
    }

    suspend fun create(command: CreateRecurrenceRuleCommand): FluviRecurrenceRule = database.withTransaction {
        validate(command)
        val partnerId = resolvePartnerInTransaction(command)
        val category = resolveCategory(partnerId, command.categorySelection)
        val now = clock.nowUtcMs()
        val rule = FluviRecurrenceRuleEntity(
            id = idGenerator.next(), name = command.name.trim(), triggerKind = command.triggerKind,
            partnerId = partnerId, categoryId = category.first, categoryAssignmentMode = category.second,
            note = command.note?.trim()?.ifEmpty { null }, direction = command.direction,
            amountPolicy = command.amountPolicy, amountScaled100 = command.amountScaled100 ?: 0L,
            dayOfMonth = command.dayOfMonth, localTimeMinutes = command.localTimeMinutes,
            startLocalEpochDay = command.startLocalEpochDay, endLocalEpochDay = command.endLocalEpochDay,
            timezoneId = command.timezoneId, ruleVersion = 1, archivedAtUtcMs = null,
            isActive = true, createdAtUtcMs = now, updatedAtUtcMs = now,
        )
        database.recurrenceDao().insertRule(rule)
        if (command.triggerKind == RecurrenceTriggerKind.time) {
            database.recurrenceDao().upsertTimeConfig(
                FluviTimeRecurringRuleConfigEntity(
                    ruleId = rule.id,
                    dayOfMonth = rule.dayOfMonth,
                    localTimeMinutes = rule.localTimeMinutes,
                ),
            )
        } else {
            database.recurrenceDao().upsertPushConfig(
                FluviPushRecurringRuleConfigEntity(
                    ruleId = rule.id,
                    pushProfileId = command.pushProfileId,
                    pushRuleId = command.pushRuleId,
                    expectedLocalTimeMinutes = rule.localTimeMinutes,
                    amountToleranceScaled100 = command.amountToleranceScaled100,
                    dayWindow = command.dayWindow,
                    parserMatchText = null,
                ),
            )
        }
        generateForRuleInTransaction(rule, months = 12)
        publishPresentationMutation(now)
        ruleModel(rule)
    }

    /**
     * Updates only future, non-overridden schedule truth. Existing Ledger
     * rows and occurrence override records are intentionally untouched.
     */
    suspend fun update(command: UpdateRecurrenceRuleCommand): FluviRecurrenceRule = database.withTransaction {
        val current = requireNotNull(database.recurrenceDao().rule(command.ruleId)) {
            "Unknown recurrence rule."
        }
        validate(command, current.direction)
        val partnerId = partners.resolveCanonicalPartnerId(command.partnerId)
        val category = resolveCategory(partnerId, command.categorySelection)
        val now = clock.nowUtcMs()
        check(database.recurrenceDao().updateRuleIfVersion(
            ruleId = current.id,
            expectedVersion = command.expectedRuleVersion,
            name = command.name.trim(),
            triggerKind = command.triggerKind,
            partnerId = partnerId,
            categoryId = category.first,
            categoryMode = category.second,
            note = command.note?.trim()?.ifEmpty { null },
            amountPolicy = command.amountPolicy,
            amountScaled100 = command.amountScaled100 ?: 0L,
            dayOfMonth = command.dayOfMonth,
            localTimeMinutes = command.localTimeMinutes,
            startLocalEpochDay = command.startLocalEpochDay,
            endLocalEpochDay = command.endLocalEpochDay,
            timezoneId = command.timezoneId,
            now = now,
        ) == 1) { "The recurrence rule changed elsewhere. Reload it and try again." }
        if (command.triggerKind == RecurrenceTriggerKind.time) {
            database.recurrenceDao().upsertTimeConfig(
                FluviTimeRecurringRuleConfigEntity(current.id, command.dayOfMonth, command.localTimeMinutes),
            )
            database.recurrenceDao().deletePushConfig(current.id)
        } else {
            database.recurrenceDao().upsertPushConfig(
                FluviPushRecurringRuleConfigEntity(
                    ruleId = current.id,
                    pushProfileId = command.pushProfileId,
                    pushRuleId = command.pushRuleId,
                    expectedLocalTimeMinutes = command.localTimeMinutes,
                    amountToleranceScaled100 = command.amountToleranceScaled100,
                    dayWindow = command.dayWindow,
                    parserMatchText = null,
                ),
            )
            database.recurrenceDao().deleteTimeConfig(current.id)
        }
        val updated = requireNotNull(database.recurrenceDao().rule(current.id))
        // Existing generated rows carry their own revision. Refresh only the
        // open rows which have no explicit exception; the exception table is
        // left as the durable boundary of user-authored occurrence changes.
        refreshFutureOpenOccurrencesInTransaction(updated)
        generateForRuleInTransaction(updated, months = 12)
        publishPresentationMutation(now)
        ruleModel(requireNotNull(database.recurrenceDao().rule(current.id)))
    }

    suspend fun preview(request: RecurrencePreviewRequest): List<FluviRecurrencePreview> = database.withTransaction {
        require(request.dayOfMonth in 1..31)
        require(request.localTimeMinutes in 0..1439)
        require(request.count in 1..12)
        require(request.endLocalEpochDay == null || request.endLocalEpochDay >= request.startLocalEpochDay)
        scheduleDates(
            dayOfMonth = request.dayOfMonth,
            startLocalEpochDay = request.startLocalEpochDay,
            endLocalEpochDay = request.endLocalEpochDay,
            timezoneId = request.timezoneId,
            count = request.count,
            fromEpochDay = maxOf(
                request.startLocalEpochDay,
                Instant.ofEpochMilli(clock.nowUtcMs())
                    .atZone(ZoneId.of(request.timezoneId))
                    .toLocalDate()
                    .toEpochDay(),
            ),
        ).map { day ->
            FluviRecurrencePreview(day, request.localTimeMinutes, localInstant(day, request.localTimeMinutes, request.timezoneId))
        }
    }

    suspend fun setRuleActive(ruleId: String, active: Boolean) = database.withTransaction {
        val rule = requireNotNull(database.recurrenceDao().rule(ruleId)) { "Unknown recurrence rule." }
        require(rule.archivedAtUtcMs == null) { "Archived recurrence rules cannot be reactivated." }
        check(database.recurrenceDao().setRuleActive(ruleId, active, clock.nowUtcMs()) == 1)
        if (active) {
            // Resuming starts from the next future opportunity. A paused
            // period must not become an accidental catch-up booking burst.
            database.recurrenceDao().skipPastPendingForResumedRule(ruleId, clock.nowUtcMs())
            generateForRuleInTransaction(rule, months = 12)
        }
        publishPresentationMutation(clock.nowUtcMs())
    }

    /**
     * Archive is intentionally not a destructive delete.  Historical
     * REALIZED occurrences continue to own their immutable Ledger links;
     * only open previews/reviews become CANCELLED and no future generation or
     * trigger matching can see the rule.
     */
    suspend fun archiveRule(ruleId: String) = database.withTransaction {
        requireNotNull(database.recurrenceDao().rule(ruleId)) { "Unknown recurrence rule." }
        val now = clock.nowUtcMs()
        check(database.recurrenceDao().archiveRule(ruleId, now) == 1) {
            "Recurrence rule is already archived."
        }
        database.recurrenceDao().cancelOpenOccurrencesForArchivedRule(ruleId, now)
        publishPresentationMutation(now)
    }

    suspend fun setShowPendingGhostsInLedger(show: Boolean) = database.withTransaction {
        check(database.recurrenceDao().setShowPendingGhosts(FluviSystemIds.APP_SETTINGS, show, clock.nowUtcMs()) == 1)
        // This is a presentation revision, not a Ledger entry. The current
        // dashboard transport uses one invalidation stream for both sources.
        publishPresentationMutation(clock.nowUtcMs())
    }

    suspend fun skip(occurrenceId: String) = database.withTransaction {
        transition(occurrenceId, RecurrenceOccurrenceStatus.skipped, null)
        publishPresentationMutation(clock.nowUtcMs())
    }

    suspend fun updateOccurrence(command: UpdateOccurrenceOverrideCommand): FluviRecurrenceOccurrence = database.withTransaction {
        val current = requireOccurrence(command.occurrenceId)
        require(current.status == RecurrenceOccurrenceStatus.pending) { "Only pending occurrences can be changed." }
        val partnerId = command.partnerId?.let { partners.resolveCanonicalPartnerId(it) } ?: current.partnerId
        val category = command.categorySelection?.let { resolveCategory(partnerId, it) }
            ?: (current.categoryId to current.categoryAssignmentMode)
        val day = command.expectedLocalEpochDay ?: current.expectedLocalEpochDay
        val minutes = command.expectedLocalTimeMinutes ?: current.expectedLocalTimeMinutes
        require(minutes in 0..1439)
        val amount = command.expectedAmountScaled100 ?: current.expectedAmountScaled100
        require(amount == null || amount > 0L)
        val note = if (command.noteChanged) {
            command.note?.trim()?.ifEmpty { null }
        } else {
            current.note
        }
        val at = localInstant(day, minutes, current.timezoneId)
        val now = clock.nowUtcMs()
        check(database.recurrenceDao().updatePendingOccurrence(
            current.id, amount, day, minutes, at, partnerId, category.first, category.second,
            note, now,
        ) == 1)
        val previousOverride = database.recurrenceDao()
            .occurrenceOverride(current.ruleId, current.occurrenceKey)
        database.recurrenceDao().upsertOccurrenceOverride(
            FluviOccurrenceOverrideEntity(
                id = previousOverride?.id ?: idGenerator.next(),
                ruleId = current.ruleId,
                occurrenceKey = current.occurrenceKey,
                partnerId = partnerId,
                categoryId = category.first,
                categoryAssignmentMode = category.second,
                note = note,
                amountScaled100 = amount,
                bookedLocalEpochDay = day,
                bookedLocalTimeMinutes = minutes,
                isDismissed = false,
                isOverdue = false,
                createdAtUtcMs = previousOverride?.createdAtUtcMs ?: now,
                updatedAtUtcMs = now,
            ),
        )
        publishPresentationMutation(now)
        occurrenceModel(requireOccurrence(current.id))
    }

    /** Runs after scheduler repair/app launch. It deliberately does no catch-up for paused rules. */
    suspend fun realizeDueTimeOccurrences(nowUtcMs: Long = clock.nowUtcMs()): List<String> = database.withTransaction {
        val realized = mutableListOf<String>()
        database.recurrenceDao().duePending(nowUtcMs).forEach { occurrence ->
            val rule = database.recurrenceDao().rule(occurrence.ruleId) ?: return@forEach
            if (!rule.isActive || occurrence.triggerKind != RecurrenceTriggerKind.time ||
                occurrence.expectedAmountScaled100 == null || occurrence.expectedAmountScaled100 <= 0L) return@forEach
            val entry = realizeInTransaction(occurrence, RecurrenceRealizationKind.time, LedgerOriginKind.recurring,
                occurrence.expectedAmountScaled100, occurrence.expectedAtUtcMs, null)
            realized += entry
        }
        realized
    }

    /** Scheduler-safe read; rolling generation happens before the next alarm is selected. */
    suspend fun nextActiveTimeOccurrenceAtUtcMs(): Long? = database.withTransaction {
        ensureRollingWindowInTransaction()
        database.recurrenceDao().nextActiveTimeOccurrence()?.expectedAtUtcMs
    }

    /** Push matcher supplies already structured parser output; it never re-parses notification text. */
    suspend fun realizePushOccurrence(
        occurrenceId: String,
        amountScaled100: Long,
        occurredAtUtcMs: Long,
        notificationInboxId: String,
    ): String = database.withTransaction {
        val occurrence = requireOccurrence(occurrenceId)
        require(occurrence.triggerKind == RecurrenceTriggerKind.push)
        require(amountScaled100 > 0)
        realizeInTransaction(occurrence, RecurrenceRealizationKind.push, LedgerOriginKind.push,
            amountScaled100, occurredAtUtcMs, notificationInboxId)
    }

    /** A human-reviewed parser result may resolve exactly one review ghost. */
    suspend fun reviewPushCandidates(
        profileId: String,
        merchantName: String,
        direction: LedgerDirection,
        amountScaled100: Long,
        receivedAtUtcMs: Long,
    ): List<FluviRecurrenceOccurrence> = database.withTransaction {
        val matchedPartner = partners.findByNormalizedAlias(
            PartnerAliasNormalizer.normalize(merchantName),
        ) ?: return@withTransaction emptyList()
        val canonicalPartnerId = partners.resolveCanonicalPartnerId(matchedPartner.id)
        database.recurrenceDao().reviewPushCandidates(
            profileId = profileId,
            direction = direction,
            amountScaled100 = amountScaled100,
            receivedAtUtcMs = receivedAtUtcMs,
        ).filter {
            it.partnerId == canonicalPartnerId && matchesPushLocalDayWindow(it, receivedAtUtcMs)
        }.map(::occurrenceModel)
    }

    /**
     * Finds only unambiguous eligible monthly occurrences from a structured
     * Parser v2 result. No raw notification text is inspected here.
     */
    suspend fun pushCandidates(
        profileId: String,
        pushRuleId: String,
        merchantName: String,
        direction: com.fluvi.core.model.LedgerDirection,
        amountScaled100: Long,
        receivedAtUtcMs: Long,
    ): List<FluviRecurrenceOccurrence> = database.withTransaction {
        val matchedPartner = partners.findByNormalizedAlias(
            PartnerAliasNormalizer.normalize(merchantName),
        ) ?: return@withTransaction emptyList()
        val canonicalPartnerId = partners.resolveCanonicalPartnerId(matchedPartner.id)
        database.recurrenceDao().pendingPushCandidates(
            profileId = profileId,
            pushRuleId = pushRuleId,
            direction = direction,
            amountScaled100 = amountScaled100,
            receivedAtUtcMs = receivedAtUtcMs,
        ).filter {
            it.partnerId == canonicalPartnerId && matchesPushLocalDayWindow(it, receivedAtUtcMs)
        }.map(::occurrenceModel)
    }

    /** Ambiguous parser matches are visible in Ghost Manager and cannot book automatically. */
    suspend fun markPushCandidatesForReview(occurrenceIds: List<String>) = database.withTransaction {
        if (occurrenceIds.isNotEmpty()) {
            database.recurrenceDao().markReview(occurrenceIds.distinct(), clock.nowUtcMs())
            publishPresentationMutation(clock.nowUtcMs())
        }
    }

    /**
     * A time-triggered occurrence can later receive the bank push as evidence.
     * Return the existing ledger IDs so the caller can attach the inbox event
     * without manufacturing a second financial transaction.
     */
    suspend fun realizedPushEvidenceEntryIds(
        profileId: String,
        pushRuleId: String,
        merchantName: String,
        direction: com.fluvi.core.model.LedgerDirection,
        amountScaled100: Long,
        receivedAtUtcMs: Long,
    ): List<String> = database.withTransaction {
        val matchedPartner = partners.findByNormalizedAlias(
            PartnerAliasNormalizer.normalize(merchantName),
        ) ?: return@withTransaction emptyList()
        val canonicalPartnerId = partners.resolveCanonicalPartnerId(matchedPartner.id)
        val occurrences = database.recurrenceDao().realizedPushEvidenceCandidates(
            profileId = profileId,
            pushRuleId = pushRuleId,
            direction = direction,
            amountScaled100 = amountScaled100,
            receivedAtUtcMs = receivedAtUtcMs,
        ).filter {
            it.partnerId == canonicalPartnerId && matchesPushLocalDayWindow(it, receivedAtUtcMs)
        }
        buildList {
            occurrences.forEach { occurrence ->
                database.ledgerDao().findByRecurrenceOccurrenceId(occurrence.id)?.id?.let(::add)
            }
        }
    }

    /**
     * Matches the structured parser result to a nearby time-triggered
     * realization.  The original recurring Ledger entry is deliberately kept
     * immutable; callers either attach the notification as evidence or send a
     * conflicting amount to review.
     */
    suspend fun realizedTimeEvidence(
        merchantName: String,
        direction: LedgerDirection,
        amountScaled100: Long,
        receivedAtUtcMs: Long,
    ): List<FluviTimeRecurrenceEvidence> = database.withTransaction {
        val matchedPartner = partners.findByNormalizedAlias(
            PartnerAliasNormalizer.normalize(merchantName),
        ) ?: return@withTransaction emptyList()
        val canonicalPartnerId = partners.resolveCanonicalPartnerId(matchedPartner.id)
        val candidates = database.recurrenceDao().realizedTimeEvidenceCandidates(
            direction = direction,
            receivedAtUtcMs = receivedAtUtcMs,
            windowMs = TIME_PUSH_EVIDENCE_WINDOW_MS,
        )
        val evidence = mutableListOf<FluviTimeRecurrenceEvidence>()
        candidates.forEach { occurrence ->
            if (occurrence.partnerId == canonicalPartnerId) {
                database.ledgerDao().findByRecurrenceOccurrenceId(occurrence.id)?.let { entry ->
                    evidence += FluviTimeRecurrenceEvidence(
                        entryId = entry.id,
                        amountMatchesExpected = occurrence.expectedAmountScaled100 == amountScaled100,
                    )
                }
            }
        }
        evidence
    }

    private suspend fun realizeInTransaction(
        occurrence: FluviRecurrenceOccurrenceEntity,
        kind: RecurrenceRealizationKind,
        origin: LedgerOriginKind,
        amount: Long,
        occurredAt: Long,
        notificationInboxId: String?,
    ): String {
        require(
            occurrence.status == RecurrenceOccurrenceStatus.pending ||
                occurrence.status == RecurrenceOccurrenceStatus.review,
        ) { "Occurrence is already resolved." }
        val local = Instant.ofEpochMilli(occurredAt).atZone(ZoneId.of(occurrence.timezoneId))
        val entry = ledger.createRecurring(CreateRecurringLedgerEntryCommand(
            occurrenceId = occurrence.id, partnerId = occurrence.partnerId,
            categorySelection = if (occurrence.categoryAssignmentMode == CategoryAssignmentMode.partnerDefault)
                LedgerCategorySelection.PartnerDefault else LedgerCategorySelection.EntryOverride(occurrence.categoryId),
            note = occurrence.note, direction = occurrence.direction, amountScaled100 = amount,
            bookedLocalEpochDay = local.toLocalDate().toEpochDay(),
            bookedLocalTimeMinutes = local.toLocalTime().toSecondOfDay() / 60,
            occurredAtUtcMs = occurredAt, originKind = origin, notificationInboxId = notificationInboxId,
        ))
        check(database.recurrenceDao().transition(
            occurrence.id, occurrence.status, RecurrenceOccurrenceStatus.realized,
            kind, clock.nowUtcMs(), clock.nowUtcMs(),
        ) == 1) { "Occurrence state changed before realization." }
        return entry.id
    }

    private suspend fun transition(id: String, status: RecurrenceOccurrenceStatus, kind: RecurrenceRealizationKind?) {
        check(database.recurrenceDao().transition(id, RecurrenceOccurrenceStatus.pending, status, kind,
            if (status == RecurrenceOccurrenceStatus.skipped) clock.nowUtcMs() else null, clock.nowUtcMs()) == 1) {
            "Occurrence is not pending."
        }
    }

    private suspend fun publishPresentationMutation(now: Long) {
        check(
            database.appSettingsDao().incrementCoreRevision(
                FluviSystemIds.APP_SETTINGS,
                now,
            ) == 1,
        ) { "Could not publish recurring presentation mutation." }
    }

    private suspend fun ensureRollingWindowInTransaction() {
        database.recurrenceDao().rules().filter { it.isActive }.forEach { generateForRuleInTransaction(it, 12) }
    }

    private suspend fun generateForRuleInTransaction(rule: FluviRecurrenceRuleEntity, months: Int) {
        val today = Instant.ofEpochMilli(clock.nowUtcMs()).atZone(ZoneId.of(rule.timezoneId)).toLocalDate().toEpochDay()
        scheduleDates(
            dayOfMonth = rule.dayOfMonth,
            startLocalEpochDay = rule.startLocalEpochDay,
            endLocalEpochDay = rule.endLocalEpochDay,
            timezoneId = rule.timezoneId,
            count = months,
            fromEpochDay = today,
        ).forEach { day ->
            val localDate = LocalDate.ofEpochDay(day)
            val expected = localInstant(day, rule.localTimeMinutes, rule.timezoneId)
            database.recurrenceDao().insertOccurrence(FluviRecurrenceOccurrenceEntity(
                id = idGenerator.next(), ruleId = rule.id, occurrenceKey = "%04d-%02d".format(localDate.year, localDate.monthValue),
                ruleVersion = rule.ruleVersion, expectedLocalEpochDay = day,
                expectedLocalTimeMinutes = rule.localTimeMinutes, expectedAtUtcMs = expected, timezoneId = rule.timezoneId,
                partnerId = rule.partnerId, categoryId = rule.categoryId, categoryAssignmentMode = rule.categoryAssignmentMode,
                direction = rule.direction, expectedAmountScaled100 = rule.amountScaled100.takeIf { it > 0L },
                amountPolicy = rule.amountPolicy, note = rule.note, triggerKind = rule.triggerKind,
                status = RecurrenceOccurrenceStatus.pending, realizationKind = null, resolvedAtUtcMs = null,
                createdAtUtcMs = clock.nowUtcMs(), updatedAtUtcMs = clock.nowUtcMs(), revision = 1,
            ))
        }
    }

    private fun scheduleDates(
        dayOfMonth: Int,
        startLocalEpochDay: Long,
        endLocalEpochDay: Long?,
        timezoneId: String,
        count: Int,
        fromEpochDay: Long,
    ): List<Long> {
        val zone = ZoneId.of(timezoneId)
        val first = LocalDate.ofEpochDay(startLocalEpochDay).withDayOfMonth(1)
        val from = LocalDate.ofEpochDay(fromEpochDay).atStartOfDay(zone).toLocalDate().withDayOfMonth(1)
        val start = if (first.isAfter(from)) first else from
        val result = mutableListOf<Long>()
        var offset = 0L
        // Need tolerate an early end date while still producing every valid
        // month requested. The bounded guard also prevents a malformed draft
        // from spinning indefinitely.
        while (result.size < count && offset < 240) {
            val ym = YearMonth.from(start).plusMonths(offset++)
            val day = ym.atDay(minOf(dayOfMonth, ym.lengthOfMonth())).toEpochDay()
            if (day < startLocalEpochDay) continue
            if (endLocalEpochDay != null && day > endLocalEpochDay) break
            result += day
        }
        return result
    }

    private suspend fun refreshFutureOpenOccurrencesInTransaction(rule: FluviRecurrenceRuleEntity) {
        // Overrides have explicit persisted state and must never be silently
        // overwritten. New monthly slots are generated separately afterwards.
        val now = clock.nowUtcMs()
        database.recurrenceDao().occurrencesForRule(rule.id)
            .filter { it.status == RecurrenceOccurrenceStatus.pending && it.expectedAtUtcMs >= now }
            .forEach { occurrence ->
                if (database.recurrenceDao().occurrenceOverride(rule.id, occurrence.occurrenceKey) != null) return@forEach
                val ym = YearMonth.of(
                    occurrence.occurrenceKey.substring(0, 4).toInt(),
                    occurrence.occurrenceKey.substring(5, 7).toInt(),
                )
                val day = ym.atDay(minOf(rule.dayOfMonth, ym.lengthOfMonth())).toEpochDay()
                if (day < rule.startLocalEpochDay || (rule.endLocalEpochDay != null && day > rule.endLocalEpochDay)) {
                    // This remains visible as a stopped historical slot instead
                    // of silently disappearing. Explicit overrides above are
                    // deliberately excluded from this transition.
                    database.recurrenceDao().transition(
                        occurrenceId = occurrence.id,
                        expected = RecurrenceOccurrenceStatus.pending,
                        status = RecurrenceOccurrenceStatus.cancelled,
                        kind = null,
                        resolvedAt = now,
                        now = now,
                    )
                    return@forEach
                }
                database.recurrenceDao().updatePendingOccurrence(
                    occurrenceId = occurrence.id,
                    amount = rule.amountScaled100.takeIf { it > 0L },
                    epochDay = day,
                    minutes = rule.localTimeMinutes,
                    atUtc = localInstant(day, rule.localTimeMinutes, rule.timezoneId),
                    partnerId = rule.partnerId,
                    categoryId = rule.categoryId,
                    mode = rule.categoryAssignmentMode,
                    note = rule.note,
                    now = now,
                )
            }
    }

    private suspend fun requireOccurrence(id: String) = requireNotNull(database.recurrenceDao().occurrence(id)) { "Unknown occurrence ID." }

    private suspend fun resolveCategory(partnerId: String, selection: LedgerCategorySelection): Pair<String, CategoryAssignmentMode> = when (selection) {
        LedgerCategorySelection.PartnerDefault -> partners.requireById(partnerId).defaultCategoryId to CategoryAssignmentMode.partnerDefault
        is LedgerCategorySelection.EntryOverride -> {
            requireNotNull(database.categoryDao().findById(selection.categoryId)) { "Unknown category ID." }
            selection.categoryId to CategoryAssignmentMode.entryOverride
        }
    }

    private suspend fun validate(command: CreateRecurrenceRuleCommand) {
        require(command.name.trim().isNotEmpty()) { "Recurrence name is required." }
        require(command.partner != null || !command.partnerId.isNullOrBlank()) { "A recurrence needs a partner." }
        require(command.dayOfMonth in 1..31)
        require(command.localTimeMinutes in 0..1439)
        require(command.endLocalEpochDay == null || command.endLocalEpochDay >= command.startLocalEpochDay)
        require(command.amountScaled100 == null || command.amountScaled100 > 0L)
        require(command.dayWindow in 0..31) { "Push date window must be between zero and 31 days." }
        require(command.amountToleranceScaled100 >= 0L) { "Push amount tolerance cannot be negative." }
        if (command.triggerKind == RecurrenceTriggerKind.push) {
            require((command.pushProfileId == null) == (command.pushRuleId == null)) {
                "A prepared push recurrence needs both a profile and a parser rule."
            }
            if (command.pushProfileId != null) {
                val profile = database.pushAutomationDao().profile(command.pushProfileId)
                require(profile != null) { "Unknown push profile." }
                val pushRule = requireNotNull(
                    database.pushAutomationDao().rule(requireNotNull(command.pushRuleId)),
                ) { "Unknown parser rule." }
                require(pushRule.profileId == profile.id) { "The parser rule does not belong to the selected profile." }
                require(pushRule.direction == command.direction) {
                    "The parser rule direction does not match the recurrence."
                }
            }
        }
        if (command.triggerKind == RecurrenceTriggerKind.time) {
            require(command.amountPolicy != RecurrenceAmountPolicy.unknown && command.amountScaled100 != null) {
                "Time recurrences require a positive known amount."
            }
        }
    }

    private suspend fun validate(command: UpdateRecurrenceRuleCommand, direction: LedgerDirection) {
        validate(
            CreateRecurrenceRuleCommand(
                name = command.name,
                partnerId = command.partnerId,
                categorySelection = command.categorySelection,
                direction = direction,
                note = command.note,
                triggerKind = command.triggerKind,
                amountPolicy = command.amountPolicy,
                amountScaled100 = command.amountScaled100,
                dayOfMonth = command.dayOfMonth,
                localTimeMinutes = command.localTimeMinutes,
                startLocalEpochDay = command.startLocalEpochDay,
                endLocalEpochDay = command.endLocalEpochDay,
                timezoneId = command.timezoneId,
                pushProfileId = command.pushProfileId,
                pushRuleId = command.pushRuleId,
                amountToleranceScaled100 = command.amountToleranceScaled100,
                dayWindow = command.dayWindow,
            ),
        )
    }

    private suspend fun resolvePartnerInTransaction(command: CreateRecurrenceRuleCommand): String = when (
        val selection = command.partner
    ) {
        is ManualTransactionPartnerSelection.Existing -> partners.resolveCanonicalPartnerId(selection.partnerId)
        is ManualTransactionPartnerSelection.New -> findOrCreatePartnerInTransaction(
            selection.displayName,
            selection.defaultCategoryId,
        )
        null -> partners.resolveCanonicalPartnerId(requireNotNull(command.partnerId))
    }

    private suspend fun findOrCreatePartnerInTransaction(name: String, defaultCategoryId: String): String {
        val displayName = PartnerAliasNormalizer.displayName(name)
        val normalizedAlias = PartnerAliasNormalizer.normalize(displayName)
        val existing = partners.findByNormalizedAlias(normalizedAlias)
        if (existing != null) return partners.resolveCanonicalPartnerId(existing.id)
        requireNotNull(database.categoryDao().findById(defaultCategoryId)) { "Unknown category ID." }
        val now = clock.nowUtcMs()
        val partnerId = idGenerator.next()
        partners.insert(
            FluviPartnerEntity(partnerId, displayName, null, defaultCategoryId, null, now, now),
            FluviPartnerAliasEntity(idGenerator.next(), partnerId, normalizedAlias, displayName, now, now),
        )
        return partnerId
    }

    private fun localInstant(epochDay: Long, minutes: Int, zoneId: String): Long = ZonedDateTime.of(
        LocalDate.ofEpochDay(epochDay), java.time.LocalTime.of(minutes / 60, minutes % 60), ZoneId.of(zoneId),
    ).toInstant().toEpochMilli()

    /** A zero push day window means the same *local calendar day*, not the
     * same millisecond. Wider windows remain narrowed in SQL. */
    private suspend fun matchesPushLocalDayWindow(
        occurrence: FluviRecurrenceOccurrenceEntity,
        receivedAtUtcMs: Long,
    ): Boolean {
        val config = database.recurrenceDao().pushConfig(occurrence.ruleId)
            ?: return false
        if (config.dayWindow != 0) return true
        val receivedDay = Instant.ofEpochMilli(receivedAtUtcMs)
            .atZone(ZoneId.of(occurrence.timezoneId))
            .toLocalDate()
            .toEpochDay()
        return occurrence.expectedLocalEpochDay == receivedDay
    }

    private suspend fun ruleModel(value: FluviRecurrenceRuleEntity): FluviRecurrenceRule {
        val config = database.recurrenceDao().pushConfig(value.id)
        return FluviRecurrenceRule(
        value.id, value.name, value.partnerId, value.categoryId, value.categoryAssignmentMode, value.direction,
        value.note, value.triggerKind, value.amountPolicy, value.amountScaled100.takeIf { it > 0L }, value.dayOfMonth,
        value.localTimeMinutes, value.startLocalEpochDay, value.endLocalEpochDay, value.timezoneId, value.isActive, value.ruleVersion,
        config?.pushProfileId, config?.pushRuleId, config?.amountToleranceScaled100 ?: 0L, config?.dayWindow ?: 0,
    )
    }
    private fun occurrenceModel(value: FluviRecurrenceOccurrenceEntity) = FluviRecurrenceOccurrence(
        value.id, value.ruleId, value.occurrenceKey, value.expectedLocalEpochDay, value.expectedLocalTimeMinutes,
        value.expectedAtUtcMs, value.timezoneId, value.partnerId, value.categoryId, value.categoryAssignmentMode,
        value.direction, value.expectedAmountScaled100, value.amountPolicy, value.note, value.triggerKind,
        value.status, value.realizationKind, value.resolvedAtUtcMs,
    )

    private companion object {
        const val TIME_PUSH_EVIDENCE_WINDOW_MS = 2L * 24L * 60L * 60L * 1000L
    }
}
