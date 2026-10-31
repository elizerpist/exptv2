package com.fluvi.core.usecase

import androidx.room.withTransaction
import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.entity.FluviNotificationInboxEntity
import com.fluvi.core.database.entity.FluviPushProfileEntity
import com.fluvi.core.database.entity.FluviPushRuleEntity
import com.fluvi.core.database.entity.FluviPushRuleTestResultEntity
import com.fluvi.core.database.entity.FluviPushTrainingSampleEntity
import com.fluvi.core.model.ApprovePushReviewCommand
import com.fluvi.core.model.CapturedPushNotification
import com.fluvi.core.model.CreatePushLedgerEntryCommand
import com.fluvi.core.model.CreatePushProfileCommand
import com.fluvi.core.model.CreatePushRuleCommand
import com.fluvi.core.model.FluviClock
import com.fluvi.core.model.FluviIdGenerator
import com.fluvi.core.model.FluviNotificationInboxItem
import com.fluvi.core.model.FluviPushCaptureResult
import com.fluvi.core.model.FluviPushDashboardSnapshot
import com.fluvi.core.model.FluviPushProfile
import com.fluvi.core.model.FluviPushRule
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.NotificationParseStatus
import com.fluvi.core.model.NotificationProcessingStatus
import com.fluvi.core.model.NotificationTrainingStatus
import com.fluvi.core.model.PushFieldRole
import com.fluvi.core.model.PushProfileState
import com.fluvi.core.model.PushReviewStatus
import com.fluvi.core.model.PushRuleState
import com.fluvi.core.model.PushRuleTestReport
import com.fluvi.core.model.PushSampleKind
import com.fluvi.core.model.PushTransactionDirection
import com.fluvi.core.model.UpdatePushProfileCommand
import com.fluvi.core.model.UpdatePushRuleCommand
import java.security.MessageDigest
import java.time.Instant
import java.time.ZoneId
import java.util.Locale
import java.util.regex.Pattern
import org.json.JSONArray
import org.json.JSONObject

/**
 * Parser v2's one persisted data path.  Capture only writes an inbox row for
 * an explicitly configured package; training, testing and booking all read
 * that same row set.
 */
class FluviPushAutomationUseCase internal constructor(
    private val database: FluviDatabase,
    private val ledger: FluviLedgerWriteUseCase,
    private val recurrences: FluviRecurrenceUseCase,
    private val idGenerator: FluviIdGenerator,
    private val clock: FluviClock,
) {
    suspend fun dashboard(): FluviPushDashboardSnapshot = database.withTransaction {
        val profiles = database.pushAutomationDao().allProfiles().map { profileModel(it) }
        val all = database.pushAutomationDao().inboxPage(limit = 12, offset = 0).map(::inboxModel)
        val cutoff = clock.nowUtcMs() - THIRTY_DAYS_MS
        val captured = database.pushAutomationDao().inboxPage(limit = 10_000, offset = 0)
            .count { it.receivedAtUtcMs >= cutoff }.toLong()
        FluviPushDashboardSnapshot(
            profiles = profiles,
            pendingReviewCount = database.pushAutomationDao().inboxCountByReviewStatus(PushReviewStatus.pending),
            capturedLast30Days = captured,
            recentInbox = all,
        )
    }

    /** A bounded read model for the daily Automation tab. */
    suspend fun homeDashboard(): FluviPushDashboardSnapshot = database.withTransaction {
        FluviPushDashboardSnapshot(
            profiles = database.pushAutomationDao().allProfiles().map { profileModel(it) },
            pendingReviewCount = database.pushAutomationDao().inboxCountByReviewStatus(PushReviewStatus.pending),
            // This legacy-only statistic is intentionally not computed for the
            // home overview, where a 10k-row scan would add no visible value.
            capturedLast30Days = 0,
            recentInbox = database.pushAutomationDao().inboxPage(limit = 2, offset = 0).map(::inboxModel),
        )
    }

    suspend fun listProfiles(): List<FluviPushProfile> = database.withTransaction {
        database.pushAutomationDao().allProfiles().map { profileModel(it) }
    }

    suspend fun profile(profileId: String): FluviPushProfile = database.withTransaction {
        profileModel(requireProfile(profileId))
    }

    suspend fun rules(profileId: String): List<FluviPushRule> = database.withTransaction {
        requireProfile(profileId)
        database.pushAutomationDao().rulesForProfile(profileId).map(::ruleModel)
    }

    suspend fun inbox(
        profileId: String?,
        limit: Int,
        offset: Int,
        reviewStatus: PushReviewStatus? = null,
    ): List<FluviNotificationInboxItem> =
        database.withTransaction {
            require(limit in 1..200) { "Inbox page size must be 1..200." }
            require(offset >= 0) { "Inbox offset must be non-negative." }
            database.pushAutomationDao()
                .inboxPageFiltered(profileId, reviewStatus, limit, offset)
                .map(::inboxModel)
        }

    /** Does not create a profile twice for a source package. */
    suspend fun createProfile(command: CreatePushProfileCommand): FluviPushProfile = database.withTransaction {
        require(command.packageName.isNotBlank()) { "Package name is required." }
        require(command.appLabel.isNotBlank()) { "App label is required." }
        val displayName = command.displayName.trim().ifEmpty { command.appLabel.trim() }
        val dao = database.pushAutomationDao()
        val duplicate = dao.profileForPackage(command.packageName)
        require(duplicate == null) { "A push profile already exists for this application: ${duplicate?.id}" }
        val now = clock.nowUtcMs()
        val state = when {
            !command.monitoringRequested -> PushProfileState.paused
            !command.notificationAccessGranted -> PushProfileState.waitingForPermission
            else -> PushProfileState.waitingForTraining
        }
        val entity = FluviPushProfileEntity(
            id = idGenerator.next(), packageName = command.packageName, appLabel = command.appLabel.trim(),
            displayName = displayName, defaultDirection = command.defaultDirection, state = state,
            createdAtUtcMs = now, updatedAtUtcMs = now, revision = 1L,
        )
        dao.insertProfile(entity)
        profileModel(entity)
    }

    suspend fun updateProfile(command: UpdatePushProfileCommand): FluviPushProfile = database.withTransaction {
        requireProfile(command.profileId)
        require(command.displayName.isNotBlank()) { "Profile name is required." }
        check(database.pushAutomationDao().updateProfile(
            command.profileId, command.displayName.trim(), command.defaultDirection, command.state, clock.nowUtcMs(),
        ) == 1)
        profileModel(requireProfile(command.profileId))
    }

    suspend fun deleteProfile(profileId: String) = database.withTransaction {
        requireProfile(profileId)
        check(database.pushAutomationDao().deleteProfile(profileId) == 1)
    }

    /** Called by NotificationListenerService on Dispatchers.IO; never logs notification text. */
    suspend fun capture(notification: CapturedPushNotification): FluviPushCaptureResult = database.withTransaction {
        require(notification.text.isNotBlank()) { "Notification text is required." }
        val dao = database.pushAutomationDao()
        val storedProfile = dao.profileForPackage(notification.packageName) ?: return@withTransaction FluviPushCaptureResult.IgnoredSource
        // Reaching the listener proves Android permission at this instant. A
        // profile saved before the user granted it can therefore begin safe
        // capture, but still cannot book until it has an active rule.
        val profile = if (storedProfile.state == PushProfileState.waitingForPermission) {
            dao.updateProfile(
                storedProfile.id,
                storedProfile.displayName,
                storedProfile.defaultDirection,
                PushProfileState.waitingForTraining,
                clock.nowUtcMs(),
            )
            requireProfile(storedProfile.id)
        } else {
            storedProfile
        }
        if (profile.state == PushProfileState.paused) {
            return@withTransaction FluviPushCaptureResult.Paused
        }
        val fingerprint = fingerprint(notification)
        dao.inboxByFingerprint(fingerprint)?.let { return@withTransaction FluviPushCaptureResult.Duplicate(it.id) }
        val now = clock.nowUtcMs()
        val event = FluviNotificationInboxEntity(
            id = idGenerator.next(), rawNotificationText = notification.text, sourcePackageName = notification.packageName,
            sourceAppLabel = notification.appLabel, profileId = profile.id, notificationKey = notification.notificationKey,
            fingerprint = fingerprint, title = notification.title, receivedAtUtcMs = notification.receivedAtUtcMs,
            parseStatus = NotificationParseStatus.unclassified, processingStatus = NotificationProcessingStatus.unprocessed,
            trainingStatus = NotificationTrainingStatus.unused, reviewStatus = PushReviewStatus.none,
            confidence = null, suggestedPayloadJson = null, diagnosticsJson = null, ledgerEntryId = null,
            createdAtUtcMs = now, updatedAtUtcMs = now,
        )
        if (dao.insertInbox(event) == -1L) {
            return@withTransaction FluviPushCaptureResult.Duplicate(requireNotNull(dao.inboxByFingerprint(fingerprint)).id)
        }
        if (profile.state != PushProfileState.active) return@withTransaction FluviPushCaptureResult.Stored(event.id)
        val candidates = dao.rulesForProfileAndState(profile.id, PushRuleState.active)
            .mapNotNull { rule -> parse(rule, notification.text)?.let { rule to it } }
        if (candidates.size != 1) {
            updateReview(event.id, candidates.firstOrNull()?.second, "ambiguous_or_no_active_rule")
            return@withTransaction FluviPushCaptureResult.ReviewRequired(event.id)
        }
        val (rule, proposal) = candidates.single()
        val direction = forcedDirection(profile.defaultDirection, rule.direction)
        if (!proposal.isBookable || proposal.confidence < rule.autoAcceptThreshold) {
            updateReview(event.id, proposal, "validation_or_confidence_gate")
            return@withTransaction FluviPushCaptureResult.ReviewRequired(event.id)
        }
        val recurrenceCandidates = recurrences.pushCandidates(
            profileId = profile.id,
            pushRuleId = rule.id,
            merchantName = proposal.merchant,
            direction = direction,
            amountScaled100 = proposal.amountScaled100,
            receivedAtUtcMs = notification.receivedAtUtcMs,
        )
        if (recurrenceCandidates.size > 1) {
            recurrences.markPushCandidatesForReview(
                recurrenceCandidates.map { it.occurrenceId },
            )
            updateReview(event.id, proposal, "ambiguous_recurrence_occurrence")
            return@withTransaction FluviPushCaptureResult.ReviewRequired(event.id)
        }
        val entry = recurrenceCandidates.singleOrNull()?.let { occurrence ->
            recurrences.realizePushOccurrence(
                occurrenceId = occurrence.occurrenceId,
                amountScaled100 = proposal.amountScaled100,
                occurredAtUtcMs = notification.receivedAtUtcMs,
                notificationInboxId = event.id,
            ).let { entryId ->
                requireNotNull(database.ledgerDao().findById(entryId))
            }
        } ?: run {
            val priorEvidence = recurrences.realizedPushEvidenceEntryIds(
                profileId = profile.id,
                pushRuleId = rule.id,
                merchantName = proposal.merchant,
                direction = direction,
                amountScaled100 = proposal.amountScaled100,
                receivedAtUtcMs = notification.receivedAtUtcMs,
            )
            if (priorEvidence.size > 1) {
                updateReview(event.id, proposal, "ambiguous_realized_recurrence_evidence")
                return@withTransaction FluviPushCaptureResult.ReviewRequired(event.id)
            }
            val timeEvidence = recurrences.realizedTimeEvidence(
                merchantName = proposal.merchant,
                direction = direction,
                amountScaled100 = proposal.amountScaled100,
                receivedAtUtcMs = notification.receivedAtUtcMs,
            )
            val matchingTimeEvidence = timeEvidence.filter { it.amountMatchesExpected }
            // A second, nearby time realization is meaningful ambiguity even
            // when only one amount happens to match. Never silently pick one
            // occurrence just because the other carries a different amount.
            if (timeEvidence.size > 1 ||
                (priorEvidence.isNotEmpty() && timeEvidence.isNotEmpty()) ||
                matchingTimeEvidence.size > 1) {
                updateReview(event.id, proposal, "ambiguous_realized_recurrence_evidence")
                return@withTransaction FluviPushCaptureResult.ReviewRequired(event.id)
            }
            priorEvidence.singleOrNull()?.let { existingEntryId ->
                requireNotNull(database.ledgerDao().findById(existingEntryId))
            } ?: matchingTimeEvidence.singleOrNull()?.let { evidence ->
                requireNotNull(database.ledgerDao().findById(evidence.entryId))
            } ?: if (timeEvidence.isNotEmpty()) {
                updateReview(event.id, proposal, "time_recurrence_amount_conflict")
                return@withTransaction FluviPushCaptureResult.ReviewRequired(event.id)
            } else {
                book(event.id, proposal, direction, notification.receivedAtUtcMs)
            }
        }
        dao.updateInboxDecision(event.id, NotificationParseStatus.recognized, NotificationProcessingStatus.transaction_created,
            PushReviewStatus.approved, proposal.confidence, proposal.toJson(), null, entry.id, clock.nowUtcMs())
        FluviPushCaptureResult.Booked(event.id, entry.id)
    }

    suspend fun addTrainingSample(
        profileId: String,
        notificationId: String,
        kind: PushSampleKind,
        spansJson: String,
    ) = database.withTransaction {
        requireProfile(profileId)
        val event = requireNotNull(database.pushAutomationDao().inbox(notificationId)) { "Unknown notification ID." }
        require(event.profileId == profileId) { "Training event belongs to another profile." }
        database.pushAutomationDao().insertSample(
            FluviPushTrainingSampleEntity(idGenerator.next(), profileId, notificationId, null, kind, spansJson, clock.nowUtcMs()),
        )
        database.pushAutomationDao().updateTrainingStatus(notificationId, NotificationTrainingStatus.selected, clock.nowUtcMs())
    }

    suspend fun createRule(command: CreatePushRuleCommand): FluviPushRule = database.withTransaction {
        requireProfile(command.profileId)
        require(command.name.isNotBlank()) { "Rule name is required." }
        require(command.autoAcceptThreshold in 0.5..1.0) { "Auto accept threshold must be between 0.50 and 1.00." }
        val event = requireNotNull(database.pushAutomationDao().inbox(command.notificationId)) { "Unknown notification ID." }
        require(event.profileId == command.profileId) { "Training event belongs to another profile." }
        // This normalization preserves UTF-16 offsets, so the spans selected
        // in Flutter continue to address the original notification while a
        // later NBSP/tab/CR spelling of the same bank copy still matches.
        val representation = templateFor(normalizeRuleText(event.rawNotificationText), command.spans)
        val now = clock.nowUtcMs()
        val entity = FluviPushRuleEntity(
            id = idGenerator.next(), profileId = command.profileId, name = command.name.trim(), direction = command.direction,
            state = PushRuleState.draft, compiledRepresentation = representation, version = 1, priority = command.priority,
            autoAcceptThreshold = command.autoAcceptThreshold, createdAtUtcMs = now, updatedAtUtcMs = now,
        )
        database.pushAutomationDao().insertRule(entity)
        database.pushAutomationDao().insertSample(
            FluviPushTrainingSampleEntity(idGenerator.next(), command.profileId, command.notificationId, entity.id,
                PushSampleKind.transaction, spansToJson(command.spans), now),
        )
        database.pushAutomationDao().updateTrainingStatus(command.notificationId, NotificationTrainingStatus.incorporated, now)
        database.pushAutomationDao().updateRuleState(entity.id, PushRuleState.testing, now)
        ruleModel(entity.copy(state = PushRuleState.testing))
    }

    /** Replaces a trial representation in place, preserving its stable rule id
     * and ensuring that an older test report cannot activate new spans. */
    suspend fun updateRule(command: UpdatePushRuleCommand): FluviPushRule = database.withTransaction {
        val dao = database.pushAutomationDao()
        val existing = requireNotNull(dao.rule(command.ruleId)) { "Unknown push rule." }
        require(existing.state != PushRuleState.active) { "An active rule must be edited as a separate draft." }
        require(existing.version == command.expectedVersion) { "A szabály közben megváltozott. Töltsd újra a próbát." }
        require(command.name.isNotBlank()) { "Rule name is required." }
        val event = requireNotNull(dao.inbox(command.notificationId)) { "Unknown notification ID." }
        require(event.profileId == existing.profileId) { "Training event belongs to another profile." }
        val representation = templateFor(normalizeRuleText(event.rawNotificationText), command.spans)
        val now = clock.nowUtcMs()
        check(
            dao.updateRuleDraftIfVersion(
                ruleId = existing.id,
                expectedVersion = command.expectedVersion,
                name = command.name.trim(),
                direction = command.direction,
                representation = representation,
                state = PushRuleState.testing,
                updatedAtUtcMs = now,
            ) == 1,
        ) { "A szabály közben megváltozott. Töltsd újra a próbát." }
        ruleModel(requireNotNull(dao.rule(existing.id)))
    }

    suspend fun backtest(ruleId: String): PushRuleTestReport = database.withTransaction {
        val dao = database.pushAutomationDao()
        val rule = requireNotNull(dao.rule(ruleId)) { "Unknown push rule." }
        val events = dao.inboxForProfile(rule.profileId, 10_000, 0)
        var matched = 0
        var review = 0
        var rejected = 0
        var conflicts = 0
        val activeOthers = dao.rulesForProfileAndState(rule.profileId, PushRuleState.active).filter { it.id != rule.id }
        events.forEach { event ->
            val proposal = parse(rule, event.rawNotificationText)
            when {
                proposal == null -> rejected++
                activeOthers.any { parse(it, event.rawNotificationText) != null } -> conflicts++
                proposal.isBookable && proposal.confidence >= rule.autoAcceptThreshold -> matched++
                else -> review++
            }
        }
        val ready = matched > 0 && review == 0 && conflicts == 0
        val report = PushRuleTestReport(rule.id, matched, review, rejected, conflicts, ready)
        dao.insertTestResult(FluviPushRuleTestResultEntity(idGenerator.next(), rule.id, rule.version, matched, review, rejected, conflicts, ready, clock.nowUtcMs()))
        dao.updateRuleState(rule.id, if (ready) PushRuleState.testing else PushRuleState.failed, clock.nowUtcMs())
        report
    }

    suspend fun activateRule(ruleId: String): FluviPushRule = database.withTransaction {
        val dao = database.pushAutomationDao()
        val rule = requireNotNull(dao.rule(ruleId)) { "Unknown push rule." }
        val test = requireNotNull(dao.latestTestResult(ruleId)) { "Run a backtest before activation." }
        require(test.ruleVersion == rule.version) { "A szabály módosult az utolsó próba óta. Futtass új próbát." }
        require(test.activationReady) { "This rule has not passed its backtest." }
        dao.updateRuleState(ruleId, PushRuleState.active, clock.nowUtcMs())
        val profile = requireProfile(rule.profileId)
        if (profile.state != PushProfileState.active) {
            dao.updateProfile(profile.id, profile.displayName, profile.defaultDirection, PushProfileState.active, clock.nowUtcMs())
        }
        ruleModel(requireNotNull(dao.rule(ruleId)))
    }

    suspend fun approveReview(command: ApprovePushReviewCommand): String = database.withTransaction {
        val dao = database.pushAutomationDao()
        val event = requireNotNull(dao.inbox(command.notificationId)) { "Unknown notification ID." }
        require(event.ledgerEntryId == null) { "This notification was already booked." }
        val candidates = event.profileId?.let { profileId ->
            recurrences.reviewPushCandidates(
                profileId = profileId,
                merchantName = command.merchantName,
                direction = command.direction,
                amountScaled100 = command.amountScaled100,
                receivedAtUtcMs = event.receivedAtUtcMs,
            )
        }.orEmpty()
        require(candidates.size <= 1) {
            "Több ismétlődő előfordulás illeszkedik; az értesítés felülvizsgálatban marad."
        }
        val entry = candidates.singleOrNull()?.let { occurrence ->
            val id = recurrences.realizePushOccurrence(
                occurrenceId = occurrence.occurrenceId,
                amountScaled100 = command.amountScaled100,
                occurredAtUtcMs = command.occurredAtUtcMs,
                notificationInboxId = event.id,
            )
            requireNotNull(database.ledgerDao().findById(id))
        } ?: ledger.createPush(CreatePushLedgerEntryCommand(
            merchantName = command.merchantName, direction = command.direction, amountScaled100 = command.amountScaled100,
            bookedLocalEpochDay = command.bookedLocalEpochDay, bookedLocalTimeMinutes = command.bookedLocalTimeMinutes,
            occurredAtUtcMs = command.occurredAtUtcMs, notificationInboxId = event.id, note = command.note,
        ))
        command.trainingCorrectionJson?.let { correction ->
            database.pushAutomationDao().insertSample(
                FluviPushTrainingSampleEntity(
                    id = idGenerator.next(),
                    profileId = requireNotNull(event.profileId) {
                        "Only profiled notifications can become training samples."
                    },
                    notificationId = event.id,
                    ruleId = null,
                    sampleKind = PushSampleKind.transaction,
                    spansJson = correction,
                    createdAtUtcMs = clock.nowUtcMs(),
                ),
            )
            database.pushAutomationDao().updateTrainingStatus(
                event.id,
                NotificationTrainingStatus.selected,
                clock.nowUtcMs(),
            )
        }
        dao.updateInboxDecision(event.id, NotificationParseStatus.recognized, NotificationProcessingStatus.transaction_created,
            PushReviewStatus.approved, event.confidence, event.suggestedPayloadJson, null, entry.id, clock.nowUtcMs())
        entry.id
    }

    suspend fun ignoreReview(notificationId: String) = database.withTransaction {
        val event = requireNotNull(database.pushAutomationDao().inbox(notificationId)) { "Unknown notification ID." }
        require(event.ledgerEntryId == null) { "A booked notification cannot be ignored." }
        database.pushAutomationDao().updateInboxDecision(event.id, NotificationParseStatus.invalid, NotificationProcessingStatus.ignored,
            PushReviewStatus.ignored, event.confidence, event.suggestedPayloadJson, "user_ignored", null, clock.nowUtcMs())
    }

    private suspend fun book(eventId: String, proposal: Proposal, direction: LedgerDirection, received: Long) =
        ledger.createPush(CreatePushLedgerEntryCommand(
            merchantName = proposal.merchant, direction = direction, amountScaled100 = proposal.amountScaled100,
            bookedLocalEpochDay = Instant.ofEpochMilli(received).atZone(ZoneId.systemDefault()).toLocalDate().toEpochDay(),
            bookedLocalTimeMinutes = Instant.ofEpochMilli(received).atZone(ZoneId.systemDefault()).toLocalTime().toSecondOfDay() / 60,
            occurredAtUtcMs = received, notificationInboxId = eventId,
        ))

    private suspend fun updateReview(eventId: String, proposal: Proposal?, diagnostic: String) {
        database.pushAutomationDao().updateInboxDecision(eventId,
            if (proposal == null) NotificationParseStatus.unclassified else NotificationParseStatus.recognized,
            NotificationProcessingStatus.unprocessed, PushReviewStatus.pending, proposal?.confidence,
            proposal?.toJson(), diagnostic, null, clock.nowUtcMs())
    }

    private suspend fun requireProfile(profileId: String): FluviPushProfileEntity = requireNotNull(database.pushAutomationDao().profile(profileId)) {
        "Unknown push profile ID."
    }

    private suspend fun profileModel(entity: FluviPushProfileEntity): FluviPushProfile {
        val dao = database.pushAutomationDao()
        return FluviPushProfile(entity.id, entity.packageName, entity.appLabel, entity.displayName, entity.defaultDirection,
            entity.state, dao.rulesForProfile(entity.id).size, dao.inboxCountForProfile(entity.id), entity.revision)
    }

    private fun ruleModel(entity: FluviPushRuleEntity) = FluviPushRule(entity.id, entity.profileId, entity.name, entity.direction,
        entity.state, entity.version, entity.priority, entity.autoAcceptThreshold)

    private fun inboxModel(entity: FluviNotificationInboxEntity) = FluviNotificationInboxItem(entity.id, entity.profileId,
        entity.sourcePackageName, entity.sourceAppLabel, entity.title, entity.rawNotificationText, entity.receivedAtUtcMs,
        entity.parseStatus, entity.processingStatus, entity.trainingStatus, entity.reviewStatus, entity.confidence,
        entity.suggestedPayloadJson, entity.diagnosticsJson, entity.ledgerEntryId)

    private fun forcedDirection(profile: PushTransactionDirection, rule: LedgerDirection): LedgerDirection = when (profile) {
        PushTransactionDirection.automatic -> rule
        PushTransactionDirection.expenseOnly -> LedgerDirection.expense
        PushTransactionDirection.incomeOnly -> LedgerDirection.income
    }

    private data class Proposal(val amountScaled100: Long, val merchant: String, val confidence: Double, val fields: Map<String, String>) {
        val isBookable get() = amountScaled100 > 0 && merchant.isNotBlank()
        fun toJson(): String = JSONObject().apply {
            put("amountScaled100", amountScaled100); put("merchant", merchant); put("confidence", confidence)
            put("fields", JSONObject(fields))
        }.toString()
    }

    private fun parse(rule: FluviPushRuleEntity, text: String): Proposal? {
        val parts = JSONArray(rule.compiledRepresentation)
        val groups = linkedMapOf<String, String>()
        val regex = StringBuilder("^")
        for (i in 0 until parts.length()) {
            val part = parts.getJSONObject(i)
            when (part.getString("kind")) {
                "literal" -> regex.append(Pattern.quote(part.getString("value")))
                "field" -> {
                    val role = part.getString("role")
                    // "ignore" marks an arbitrary variable fragment (balance,
                    // reference, account suffix, …) which does not feed a
                    // proposal. It may occur more than once, so it must not
                    // create duplicate named regex groups.
                    if (role == PushFieldRole.ignore.name) {
                        regex.append("(?:.+?)")
                    } else {
                        regex.append("(?<").append(role).append(">.+?)")
                    }
                }
            }
        }
        regex.append("$")
        val matcher = Pattern.compile(
            regex.toString(),
            Pattern.DOTALL or Pattern.CASE_INSENSITIVE or Pattern.UNICODE_CASE,
        ).matcher(normalizeRuleText(text))
        if (!matcher.matches()) return null
        listOf("amount", "merchant", "balance", "account", "currency").forEach { role ->
            runCatching { matcher.group(role) }.getOrNull()?.trim()?.takeIf(String::isNotEmpty)?.let { groups[role] = it }
        }
        val amount = groups["amount"]?.let(::parseAmountScaled100) ?: return null
        val merchant = groups["merchant"] ?: return null
        if (merchant.length !in 2..120) return null
        val literalCount = (0 until parts.length()).count { parts.getJSONObject(it).getString("kind") == "literal" && parts.getJSONObject(it).getString("value").length >= 3 }
        return Proposal(amount, merchant, (0.90 + minOf(0.08, literalCount * 0.02)), groups)
    }

    private fun templateFor(text: String, spans: List<com.fluvi.core.model.PushFieldSpan>): String {
        require(spans.isNotEmpty()) { "At least one field is required." }
        val sorted = spans.sortedBy { it.start }
        require(sorted.all { it.start >= 0 && it.endExclusive > it.start && it.endExclusive <= text.length }) { "Field span is outside the notification." }
        require(sorted.zipWithNext().all { (a, b) -> a.endExclusive <= b.start }) { "Field spans overlap." }
        require(sorted.count { it.role == PushFieldRole.amount } == 1) { "Exactly one transaction amount is required." }
        require(sorted.count { it.role == PushFieldRole.merchant } == 1) { "Exactly one merchant is required." }
        require(
            sorted.filter { it.role != PushFieldRole.ignore }
                .groupingBy { it.role }
                .eachCount()
                .values
                .all { it == 1 },
        ) { "Each role can be selected once." }
        val parts = JSONArray(); var cursor = 0
        sorted.forEach { span ->
            if (span.start > cursor) parts.put(JSONObject().put("kind", "literal").put("value", text.substring(cursor, span.start)))
            parts.put(JSONObject().put("kind", "field").put("role", span.role.name))
            cursor = span.endExclusive
        }
        if (cursor < text.length) parts.put(JSONObject().put("kind", "literal").put("value", text.substring(cursor)))
        return parts.toString()
    }

    /** One UTF-16 code unit in, one code unit out: UI selection offsets stay valid. */
    private fun normalizeRuleText(value: String): String = buildString(value.length) {
        value.forEach { character ->
            append(
                when (character) {
                    '\u00a0', '\u202f', '\t' -> ' '
                    '\r' -> '\n'
                    else -> character
                },
            )
        }
    }

    private fun spansToJson(spans: List<com.fluvi.core.model.PushFieldSpan>): String = JSONArray().apply {
        spans.forEach { put(JSONObject().put("start", it.start).put("end", it.endExclusive).put("role", it.role.name)) }
    }.toString()

    private fun parseAmountScaled100(value: String): Long? {
        val token = MONEY.find(value.replace('\u00a0', ' ').replace('\u202f', ' '))?.value ?: return null
        val compact = token.replace(" ", "").replace("'", "")
        val comma = compact.lastIndexOf(',')
        val dot = compact.lastIndexOf('.')
        val decimalAt = when {
            comma >= 0 -> comma
            dot >= 0 && compact.length - dot - 1 in 1..2 -> dot
            else -> -1
        }
        val major: String
        val minor: String
        if (decimalAt >= 0) {
            major = compact.substring(0, decimalAt).replace(".", "")
            minor = compact.substring(decimalAt + 1).padEnd(2, '0').take(2)
        } else { major = compact.replace(".", ""); minor = "00" }
        val whole = major.toLongOrNull() ?: return null
        return runCatching { Math.addExact(Math.multiplyExact(whole, 100L), minor.toLong()) }.getOrNull()
    }

    private fun fingerprint(notification: CapturedPushNotification): String {
        val stable = listOf(notification.packageName, notification.notificationKey ?: "", notification.receivedAtUtcMs / 30_000L, notification.title ?: "", notification.text).joinToString("\u0000")
        return MessageDigest.getInstance("SHA-256").digest(stable.toByteArray(Charsets.UTF_8)).joinToString("") { "%02x".format(Locale.ROOT, it) }
    }

    private companion object {
        const val THIRTY_DAYS_MS = 30L * 24L * 60L * 60L * 1000L
        val MONEY = Regex("[0-9][0-9 .\\u00a0\\u202f']*(?:,[0-9]{1,2})?")
    }
}
