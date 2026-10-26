package com.fluvi.core.pulse

import androidx.room.withTransaction
import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.entity.FluviPulseDeliveryAttemptEntity
import com.fluvi.core.database.entity.FluviPulseDeliveryControlEntity
import com.fluvi.core.database.entity.FluviPulseDeliveryEventEntity
import com.fluvi.core.database.entity.FluviPulseDeliveryPreferencesEntity
import com.fluvi.core.database.entity.FluviPulseDeliveryReceiptEntity
import com.fluvi.core.model.FluviClock
import java.security.MessageDigest
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/**
 * E-phase delivery owner. It consumes one C/D frame, never recalculates
 * financial measurements, and writes only delivery tables. A lease is not a
 * receipt: a qualified exposure is the only path that records "shown".
 */
class FluviPulseDeliveryService internal constructor(
    private val database: FluviDatabase,
    private val priority: FluviPulsePriorityService,
    private val stories: FluviPulseStoryService,
    private val clock: FluviClock,
) {
    private val mutex = Mutex()

    suspend fun decision(
        year: Int,
        month: Int,
        surface: PulseDeliverySurfaceContext,
    ): PulseDeliveryDecision = mutex.withLock {
        evaluate(year, month, surface, clock.nowUtcMs()).decision
    }

    suspend fun inspection(
        year: Int,
        month: Int,
        surface: PulseDeliverySurfaceContext,
        historyLimit: Int = 30,
        historyOffset: Int = 0,
    ): PulseDeliveryInspectionSnapshot = mutex.withLock {
        require(historyLimit in 1..100) { "Delivery history limit must be 1..100." }
        val now = clock.nowUtcMs()
        val evaluated = evaluate(year, month, surface, now)
        val dao = database.pulseDeliveryDao()
        PulseDeliveryInspectionSnapshot(
            decision = evaluated.decision,
            preferences = evaluated.preferences,
            controls = dao.controls().map(::controlFromEntity),
            activeAttempt = dao.activeAttempt(now)?.let(::attemptFromEntity),
            events = dao.eventPage(historyLimit, historyOffset).map(::eventFromEntity),
        )
    }

    suspend fun preferences(): PulseDeliveryPreferences = mutex.withLock {
        preferencesFromEntity(database.pulseDeliveryDao().preferences(), clock.nowUtcMs())
    }

    suspend fun updatePreferences(
        automaticEnabled: Boolean,
        normalCooldownMillis: Long,
        commandKey: String,
    ): PulseDeliveryPreferences = mutex.withLock {
        require(normalCooldownMillis >= 0L) { "Cooldown cannot be negative." }
        require(commandKey.isNotBlank()) { "A delivery command key is required." }
        val now = clock.nowUtcMs()
        database.withTransaction {
            val dao = database.pulseDeliveryDao()
            val current = preferencesFromEntity(dao.preferences(), now)
            if (current.automaticEnabled == automaticEnabled && current.normalCooldownMillis == normalCooldownMillis) {
                return@withTransaction current
            }
            val next = current.copy(
                automaticEnabled = automaticEnabled,
                normalCooldownMillis = normalCooldownMillis,
                controlRevision = current.controlRevision + 1L,
                updatedAtUtcMs = now,
            )
            dao.upsertPreferences(next.toEntity())
            appendEvent(
                dao, now, PulseDeliveryEventKind.preferencesChanged, null,
                "preferences-changed:$commandKey", null,
            )
            next
        }
    }

    /** Atomically reserves the one header slot. It is safe to call again with
     * the same command key after a Flutter MethodChannel retry. */
    suspend fun reserveHeaderPresentation(
        year: Int,
        month: Int,
        surface: PulseDeliverySurfaceContext,
        commandKey: String,
    ): PulseHeaderPresentationReservation? = mutex.withLock {
        require(commandKey.isNotBlank()) { "A reservation command key is required." }
        val now = clock.nowUtcMs()
        val evaluated = evaluate(year, month, surface, now)
        val selected = evaluated.decision.candidates.firstOrNull {
            it.situationKey == evaluated.decision.deliverySelectedSituationKey &&
                it.eligibility == PulseDeliveryEligibility.eligible
        } ?: return@withLock null
        val draft = selected.story.draft ?: return@withLock null
        database.withTransaction {
            val dao = database.pulseDeliveryDao()
            expireStaleAttempts(dao, now)
            dao.attemptForRequest(commandKey)?.let { existing ->
                if (existing.state in ACTIVE_ATTEMPT_STATES && existing.hostSessionId == surface.hostSessionId) {
                    return@withTransaction reservation(existing, draft)
                }
                return@withTransaction null
            }
            if (dao.activeAttempt(now) != null || dao.receiptForDeliveryKey(requireNotNull(selected.deliveryKey)) != null) {
                return@withTransaction null
            }
            val currentPrefs = preferencesFromEntity(dao.preferences(), now)
            if (currentPrefs.controlRevision != evaluated.preferences.controlRevision) return@withTransaction null
            val attemptId = hash("attempt|$commandKey|${selected.deliveryKey}|$now")
            val token = hash("lease|$attemptId|${surface.hostSessionId}|$now")
            val entity = FluviPulseDeliveryAttemptEntity(
                attemptId = attemptId,
                leaseToken = token,
                requestKey = commandKey,
                hostSessionId = surface.hostSessionId,
                deliveryKey = requireNotNull(selected.deliveryKey),
                presentationIntentId = selected.presentationIntentId,
                situationKey = selected.situationKey,
                situationEpisodeId = selected.situationEpisodeId,
                targetScope = selected.targetScope,
                storyKey = draft.storyKey,
                contentFingerprint = requireNotNull(selected.contentFingerprint),
                materialSemanticKey = requireNotNull(selected.materialSemanticKey),
                sourceCoreRevision = evaluated.decision.input.sourceCoreRevision,
                sourceFrameId = evaluated.decision.input.sourceTriageFrameId,
                controlRevision = currentPrefs.controlRevision,
                state = PulseDeliveryAttemptState.reserved.name,
                validUntilUtcMs = now + PulseDeliveryPolicyCatalog.default.reservationLeaseMillis,
                reservedAtUtcMs = now,
                startedAtUtcMs = null,
                presentedAtUtcMs = null,
                qualifiedExposureAtUtcMs = null,
                endedAtUtcMs = null,
                endReason = null,
                transitionSequence = dao.latestEventSequence() + 1L,
            )
            dao.upsertAttempt(entity)
            appendEvent(dao, now, PulseDeliveryEventKind.reserved, entity, "header-reserved", entity.sourceCoreRevision)
            reservation(entity, draft)
        }
    }

    suspend fun reportPresentationStarted(
        attemptId: String,
        leaseToken: String,
        hostSessionId: String,
        contentFingerprint: String,
    ): Boolean = transitionAttempt(attemptId, leaseToken, hostSessionId, contentFingerprint, PulseDeliveryAttemptState.presenting, "presentation-started")

    suspend fun reportPresented(
        attemptId: String,
        leaseToken: String,
        hostSessionId: String,
        contentFingerprint: String,
    ): Boolean = transitionAttempt(attemptId, leaseToken, hostSessionId, contentFingerprint, PulseDeliveryAttemptState.presented, "presented")

    /**
     * Commits the durable shown fact. The caller is required to wait for the
     * policy's continuous visible duration; Core verifies the prior presented
     * state and independently guards all tokens and idempotency.
     */
    suspend fun confirmQualifiedExposure(
        attemptId: String,
        leaseToken: String,
        hostSessionId: String,
        contentFingerprint: String,
    ): PulseDeliveryReceipt? = mutex.withLock {
        val now = clock.nowUtcMs()
        database.withTransaction {
            val dao = database.pulseDeliveryDao()
            val attempt = dao.attempt(attemptId) ?: return@withTransaction null
            if (!validAttempt(attempt, leaseToken, hostSessionId, contentFingerprint, now) || attempt.state != PulseDeliveryAttemptState.presented.name) {
                return@withTransaction null
            }
            if (now - (attempt.presentedAtUtcMs ?: now) < PulseDeliveryPolicyCatalog.default.qualifiedExposureMillis) {
                return@withTransaction null
            }
            dao.receiptForDeliveryKey(attempt.deliveryKey)?.let { return@withTransaction receiptFromEntity(it) }
            val receipt = FluviPulseDeliveryReceiptEntity(
                receiptId = hash("receipt|${attempt.deliveryKey}"),
                deliveryKey = attempt.deliveryKey,
                situationEpisodeId = attempt.situationEpisodeId,
                storyKey = attempt.storyKey,
                materialSemanticKey = attempt.materialSemanticKey,
                attemptId = attempt.attemptId,
                qualifiedExposureAtUtcMs = now,
            )
            if (dao.insertReceipt(receipt) == -1L) return@withTransaction dao.receiptForDeliveryKey(attempt.deliveryKey)?.let(::receiptFromEntity)
            dao.upsertAttempt(attempt.copy(qualifiedExposureAtUtcMs = now))
            if (attempt.presentationIntentId != AUTOMATIC_INTENT) {
                dao.control(attempt.presentationIntentId)?.let { grant ->
                    dao.upsertControl(grant.copy(consumedAtUtcMs = now, updatedAtUtcMs = now))
                }
            }
            appendEvent(dao, now, PulseDeliveryEventKind.shown, attempt, "qualified-exposure", attempt.sourceCoreRevision)
            receiptFromEntity(receipt)
        }
    }

    suspend fun finishPresentation(
        attemptId: String,
        leaseToken: String,
        hostSessionId: String,
        contentFingerprint: String,
        reason: String = "readable-duration-ended",
    ): Boolean = endAttempt(attemptId, leaseToken, hostSessionId, contentFingerprint, PulseDeliveryAttemptState.ended, reason)

    suspend fun cancelPresentation(
        attemptId: String,
        leaseToken: String,
        hostSessionId: String,
        contentFingerprint: String,
        reason: String,
    ): Boolean = endAttempt(attemptId, leaseToken, hostSessionId, contentFingerprint, PulseDeliveryAttemptState.cancelled, reason)

    suspend fun dismissStory(attemptId: String, leaseToken: String, hostSessionId: String, contentFingerprint: String, commandKey: String): Boolean =
        mutex.withLock {
            val now = clock.nowUtcMs()
            database.withTransaction {
                val dao = database.pulseDeliveryDao()
                val attempt = dao.attempt(attemptId) ?: return@withTransaction false
                if (!validAttempt(attempt, leaseToken, hostSessionId, contentFingerprint, now)) return@withTransaction false
                val control = FluviPulseDeliveryControlEntity(
                    controlId = hash("dismiss|${attempt.situationEpisodeId}|${attempt.materialSemanticKey}"),
                    controlKind = PulseDeliveryControlKind.dismissed.name,
                    situationEpisodeId = attempt.situationEpisodeId,
                    materialSemanticKey = attempt.materialSemanticKey,
                    targetScope = null,
                    presentationIntentId = null,
                    expiresAtUtcMs = null,
                    consumedAtUtcMs = null,
                    createdAtUtcMs = now,
                    updatedAtUtcMs = now,
                )
                dao.upsertControl(control)
                bumpControlRevision(dao, now)
                val ended = attempt.copy(state = PulseDeliveryAttemptState.cancelled.name, endedAtUtcMs = now, endReason = "dismissed")
                dao.upsertAttempt(ended)
                appendEvent(dao, now, PulseDeliveryEventKind.dismissed, ended, "dismissed:$commandKey", ended.sourceCoreRevision)
                true
            }
        }

    /** Snooze is episode-wide. The explicit grant is consumed only by a
     * qualified future exposure, never by opening an inspector or a failed morph. */
    suspend fun snoozeSituation(
        attemptId: String,
        leaseToken: String,
        hostSessionId: String,
        contentFingerprint: String,
        untilUtcMs: Long,
        commandKey: String,
    ): Boolean = mutex.withLock {
        val now = clock.nowUtcMs()
        require(untilUtcMs > now) { "Snooze must end in the future." }
        database.withTransaction {
            val dao = database.pulseDeliveryDao()
            val attempt = dao.attempt(attemptId) ?: return@withTransaction false
            if (!validAttempt(attempt, leaseToken, hostSessionId, contentFingerprint, now)) return@withTransaction false
            val snoozeId = hash("snooze|${attempt.situationEpisodeId}")
            dao.upsertControl(
                FluviPulseDeliveryControlEntity(
                    snoozeId, PulseDeliveryControlKind.snooze.name, attempt.situationEpisodeId, null, null, null,
                    untilUtcMs, null, now, now,
                ),
            )
            val grantId = hash("snooze-grant|${attempt.situationEpisodeId}|$untilUtcMs|$commandKey")
            dao.upsertControl(
                FluviPulseDeliveryControlEntity(
                    grantId, PulseDeliveryControlKind.snoozePresentationGrant.name, attempt.situationEpisodeId,
                    null, null, grantId, untilUtcMs, null, now, now,
                ),
            )
            bumpControlRevision(dao, now)
            val ended = attempt.copy(state = PulseDeliveryAttemptState.cancelled.name, endedAtUtcMs = now, endReason = "snoozed")
            dao.upsertAttempt(ended)
            appendEvent(dao, now, PulseDeliveryEventKind.snoozed, ended, "snoozed:$commandKey", ended.sourceCoreRevision)
            true
        }
    }

    suspend fun muteTarget(targetScope: String, commandKey: String): Unit = mutex.withLock {
        require(targetScope.isNotBlank()) { "A target scope is required." }
        val now = clock.nowUtcMs()
        database.withTransaction {
            val dao = database.pulseDeliveryDao()
            val id = hash("mute|$targetScope")
            dao.upsertControl(FluviPulseDeliveryControlEntity(
                id, PulseDeliveryControlKind.mute.name, null, null, targetScope, null,
                null, null, now, now,
            ))
            bumpControlRevision(dao, now)
            appendEvent(dao, now, PulseDeliveryEventKind.muted, null, "muted:$commandKey", null, targetScope)
        }
    }

    suspend fun unmuteTarget(targetScope: String, commandKey: String): Boolean = mutex.withLock {
        val now = clock.nowUtcMs()
        database.withTransaction {
            val dao = database.pulseDeliveryDao()
            val removed = dao.deleteControl(hash("mute|$targetScope")) > 0
            if (removed) {
                bumpControlRevision(dao, now)
                appendEvent(dao, now, PulseDeliveryEventKind.unmuted, null, "unmuted:$commandKey", null, targetScope)
            }
            removed
        }
    }

    /** Clearing a user control never clears a durable shown receipt. */
    suspend fun clearControl(controlId: String, commandKey: String): Boolean = mutex.withLock {
        val now = clock.nowUtcMs()
        database.withTransaction {
            val dao = database.pulseDeliveryDao()
            val control = dao.control(controlId) ?: return@withTransaction false
            val removed = dao.deleteControl(controlId) > 0
            if (removed) {
                bumpControlRevision(dao, now)
                appendEvent(
                    dao, now, PulseDeliveryEventKind.unmuted, null,
                    "control-cleared:$commandKey", null, control.situationEpisodeId,
                )
            }
            removed
        }
    }

    private suspend fun transitionAttempt(
        attemptId: String,
        leaseToken: String,
        hostSessionId: String,
        contentFingerprint: String,
        state: PulseDeliveryAttemptState,
        reason: String,
    ): Boolean = mutex.withLock {
        val now = clock.nowUtcMs()
        database.withTransaction {
            val dao = database.pulseDeliveryDao()
            val attempt = dao.attempt(attemptId) ?: return@withTransaction false
            if (!validAttempt(attempt, leaseToken, hostSessionId, contentFingerprint, now)) return@withTransaction false
            if (attempt.state == state.name) return@withTransaction true
            val allowed = when (state) {
                PulseDeliveryAttemptState.presenting -> attempt.state == PulseDeliveryAttemptState.reserved.name
                PulseDeliveryAttemptState.presented -> attempt.state == PulseDeliveryAttemptState.presenting.name
                else -> false
            }
            if (!allowed) return@withTransaction false
            val next = when (state) {
                PulseDeliveryAttemptState.presenting -> attempt.copy(
                    state = state.name,
                    startedAtUtcMs = now,
                    // Once actual rendering begins, the short reservation may
                    // no longer expire during the guaranteed readable period.
                    validUntilUtcMs = now + PulseDeliveryPolicyCatalog.default.maxReadableMillis +
                        PulseDeliveryPolicyCatalog.default.qualifiedExposureMillis + 2_000L,
                )
                PulseDeliveryAttemptState.presented -> attempt.copy(state = state.name, presentedAtUtcMs = now)
                else -> attempt
            }
            dao.upsertAttempt(next)
            appendEvent(
                dao, now,
                if (state == PulseDeliveryAttemptState.presenting) PulseDeliveryEventKind.presentationStarted else PulseDeliveryEventKind.presented,
                next, reason, next.sourceCoreRevision,
            )
            true
        }
    }

    private suspend fun endAttempt(
        attemptId: String,
        leaseToken: String,
        hostSessionId: String,
        contentFingerprint: String,
        state: PulseDeliveryAttemptState,
        reason: String,
    ): Boolean = mutex.withLock {
        val now = clock.nowUtcMs()
        database.withTransaction {
            val dao = database.pulseDeliveryDao()
            val attempt = dao.attempt(attemptId) ?: return@withTransaction false
            if (!validAttempt(attempt, leaseToken, hostSessionId, contentFingerprint, now)) return@withTransaction false
            if (attempt.state !in ACTIVE_ATTEMPT_STATES) return@withTransaction attempt.state == state.name
            val next = attempt.copy(state = state.name, endedAtUtcMs = now, endReason = reason)
            dao.upsertAttempt(next)
            appendEvent(dao, now, if (state == PulseDeliveryAttemptState.ended) PulseDeliveryEventKind.ended else PulseDeliveryEventKind.cancelled, next, reason, next.sourceCoreRevision)
            true
        }
    }

    private data class Evaluation(
        val decision: PulseDeliveryDecision,
        val preferences: PulseDeliveryPreferences,
    )

    private suspend fun evaluate(
        year: Int,
        month: Int,
        surface: PulseDeliverySurfaceContext,
        now: Long,
    ): Evaluation {
        val prioritySnapshot = priority.inspection(year, month, historyLimit = 1)
        val dao = database.pulseDeliveryDao()
        val preferences = preferencesFromEntity(dao.preferences(), now)
        val controls = dao.controls()
        val app = requireNotNull(database.appSettingsDao().current())
        val candidates = prioritySnapshot.frame.rankedCandidates.map { priorityCandidate ->
            val situation = prioritySnapshot.situations.firstOrNull { it.situationKey == priorityCandidate.situation.situationKey }
                ?: priorityCandidate.situation
            val story = stories.composeFromPriorityInspection(prioritySnapshot, situation.situationKey).result
            assessCandidate(prioritySnapshot, priorityCandidate, situation, story, preferences, controls, dao, surface, now)
        }
        val selected = candidates.firstOrNull { it.eligibility == PulseDeliveryEligibility.eligible }
        val input = PulseDeliveryInputFrame(
            sourceCoreRevision = prioritySnapshot.frame.sourceCoreRevision,
            sourceTriageFrameId = prioritySnapshot.frame.sourceTriageFrameId,
            priorityPolicyVersion = prioritySnapshot.frame.policyVersion,
            storyTemplateVersion = PulseStoryTemplateCatalog.version,
            deliveryPolicyVersion = PulseDeliveryPolicyCatalog.version,
            evaluationMode = prioritySnapshot.frame.evaluationMode,
            evaluatedAtUtcMs = prioritySnapshot.frame.evaluatedAtUtcMs,
            canonicalTimezone = app.localZoneId,
            rankedCandidates = prioritySnapshot.frame.rankedCandidates,
            userControlRevision = preferences.controlRevision,
        )
        val reason = when {
            selected != null -> "first-eligible-priority-candidate"
            candidates.isEmpty() -> "no-priority-candidate"
            else -> "no-eligible-delivery-candidate"
        }
        return Evaluation(
            PulseDeliveryDecision(input, prioritySnapshot.frame.selectedSituationKey, selected?.situationKey, reason, candidates),
            preferences,
        )
    }

    private suspend fun assessCandidate(
        snapshot: PulsePriorityInspectionSnapshot,
        candidate: PulsePriorityCandidate,
        situation: PulseSituationSnapshot,
        story: PulseStoryCompositionResult,
        preferences: PulseDeliveryPreferences,
        controls: List<FluviPulseDeliveryControlEntity>,
        dao: com.fluvi.core.database.dao.FluviPulseDeliveryDao,
        surface: PulseDeliverySurfaceContext,
        now: Long,
    ): PulseDeliveryCandidate {
        val episode = PulseDeliveryIdentityResolver.situationEpisodeId(situation)
        val targetScope = "${situation.domain.name}:${situation.targetKey}"
        val draft = story.draft
        fun result(eligibility: PulseDeliveryEligibility, code: String, text: String, intent: String = AUTOMATIC_INTENT) =
            PulseDeliveryCandidate(
                situationKey = situation.situationKey,
                situationEpisodeId = episode,
                targetScope = targetScope,
                priorityRank = candidate.rank,
                priorityScore = candidate.finalScore,
                story = story,
                materialSemanticKey = draft?.materialFingerprint,
                contentFingerprint = draft?.contentFingerprint,
                deliveryKey = draft?.let {
                    PulseDeliveryIdentityResolver.deliveryKey(
                        episode,
                        it.storyKey,
                        it.materialFingerprint,
                        intent,
                    )
                },
                presentationIntentId = intent,
                eligibility = eligibility,
                reasonCode = code,
                explanationHu = text,
            )
        if (snapshot.frame.evaluationMode != PulseSignalEvaluationMode.live) {
            return result(PulseDeliveryEligibility.historicalOnly, "historical-inspection", "Történeti kiértékelésből nem indítható header-megjelenítés.")
        }
        if (story.status != PulseStoryCompositionStatus.composed || draft == null) {
            return result(PulseDeliveryEligibility.notComposable, story.reasonCode ?: "story-not-composed", story.explanationHu ?: "A Story nem állítható össze igazolható tényekből.")
        }
        if (draft.sourceCoreRevision != snapshot.frame.sourceCoreRevision || draft.priorityFrameId != snapshot.frame.sourceTriageFrameId) {
            return result(PulseDeliveryEligibility.stale, "stale-story-frame", "A Story forráskerete elavult.")
        }
        if (!preferences.automaticEnabled) return result(PulseDeliveryEligibility.automaticDisabled, "automatic-disabled", "Az automatikus headeres Pulse megjelenítés ki van kapcsolva.")
        if (controls.any { it.controlKind == PulseDeliveryControlKind.mute.name && it.targetScope == targetScope }) {
            return result(PulseDeliveryEligibility.muted, "target-muted", "A megnevezett cél automatikus Pulse jelzései némítva vannak.")
        }
        if (controls.any { it.controlKind == PulseDeliveryControlKind.snooze.name && it.situationEpisodeId == episode && (it.expiresAtUtcMs ?: 0L) > now }) {
            return result(PulseDeliveryEligibility.snoozed, "situation-snoozed", "A helyzet halasztása még aktív.")
        }
        if (controls.any { it.controlKind == PulseDeliveryControlKind.dismissed.name && it.situationEpisodeId == episode && it.materialSemanticKey == draft.materialFingerprint }) {
            return result(PulseDeliveryEligibility.dismissed, "material-dismissed", "Ezt az érdemi Story-változatot a felhasználó elrejtette.")
        }
        if (candidate.kind == PulsePriorityCandidateKind.recovery && dao.receiptsForEpisode(episode).none { it.storyKey.endsWith("/risk") }) {
            return result(PulseDeliveryEligibility.recoveryNotPreviouslyShown, "recovery-risk-not-shown", "A javulás előtt az eredeti kockázat nem kapott minősített megjelenítést.")
        }
        val grant = controls.firstOrNull {
            it.controlKind == PulseDeliveryControlKind.snoozePresentationGrant.name &&
                it.situationEpisodeId == episode && it.consumedAtUtcMs == null && (it.expiresAtUtcMs ?: Long.MAX_VALUE) <= now
        }
        val intent = grant?.presentationIntentId ?: AUTOMATIC_INTENT
        val key = PulseDeliveryIdentityResolver.deliveryKey(
            episode,
            draft.storyKey,
            draft.materialFingerprint,
            intent,
        )
        if (dao.receiptForDeliveryKey(key) != null) return result(PulseDeliveryEligibility.alreadyShown, "delivery-key-shown", "Azonos anyagi Story-változat már minősített megjelenítést kapott.", intent)
        if (grant == null) {
            dao.latestReceipt()?.let { receipt ->
                if (now - receipt.qualifiedExposureAtUtcMs < preferences.normalCooldownMillis) {
                    return result(PulseDeliveryEligibility.waitingForCooldown, "normal-cooldown", "A normál automatikus megjelenítési szünet még nem telt le.")
                }
            }
        }
        if (!surface.appActive || !surface.ledgerVisible || !surface.headerVisible || !surface.unobstructed) {
            return result(PulseDeliveryEligibility.waitingForSurface, "header-surface-not-available", "A Ledger fejléce jelenleg nem látható vagy nem használható.", intent)
        }
        if (!surface.interactionIdle || surface.interactionIdleSinceUtcMs?.let { now - it < PulseDeliveryPolicyCatalog.default.gestureQuietMillis } == true) {
            return result(PulseDeliveryEligibility.waitingForInteractionIdle, "header-interaction-active", "Aktív gesztus vagy friss interakció után várunk a stabil headerre.", intent)
        }
        if (!surface.headerLayoutSupported) {
            return result(PulseDeliveryEligibility.headerLayoutNotSupported, "header-layout-not-supported", "A Story nem fér el megbízhatóan a jelenlegi header-változatban.", intent)
        }
        return result(PulseDeliveryEligibility.eligible, "eligible", "A Story élő, érvényes és biztonságosan megjeleníthető a headerben.", intent)
    }

    private suspend fun expireStaleAttempts(dao: com.fluvi.core.database.dao.FluviPulseDeliveryDao, now: Long) {
        dao.staleAttempts(now).forEach { attempt ->
            val expired = attempt.copy(state = PulseDeliveryAttemptState.expired.name, endedAtUtcMs = now, endReason = "lease-expired")
            dao.upsertAttempt(expired)
            appendEvent(dao, now, PulseDeliveryEventKind.expired, expired, "lease-expired", expired.sourceCoreRevision)
        }
    }

    private suspend fun bumpControlRevision(
        dao: com.fluvi.core.database.dao.FluviPulseDeliveryDao,
        now: Long,
    ): PulseDeliveryPreferences {
        val current = preferencesFromEntity(dao.preferences(), now)
        val next = current.copy(controlRevision = current.controlRevision + 1L, updatedAtUtcMs = now)
        dao.upsertPreferences(next.toEntity())
        return next
    }

    private suspend fun appendEvent(
        dao: com.fluvi.core.database.dao.FluviPulseDeliveryDao,
        now: Long,
        kind: PulseDeliveryEventKind,
        attempt: FluviPulseDeliveryAttemptEntity?,
        reason: String,
        sourceCoreRevision: Long?,
        situationKey: String? = attempt?.situationKey,
    ) {
        val sequence = dao.latestEventSequence() + 1L
        dao.insertEvent(FluviPulseDeliveryEventEntity(
            eventId = hash("delivery-event|$sequence|${kind.name}|${attempt?.attemptId}|$reason"),
            eventKind = kind.name,
            attemptId = attempt?.attemptId,
            situationKey = situationKey,
            deliveryKey = attempt?.deliveryKey,
            reasonCode = reason,
            sourceCoreRevision = sourceCoreRevision,
            transitionSequence = sequence,
            createdAtUtcMs = now,
        ))
    }

    private fun reservation(entity: FluviPulseDeliveryAttemptEntity, draft: PulseStoryDraft) = PulseHeaderPresentationReservation(
        attemptId = entity.attemptId,
        leaseToken = entity.leaseToken,
        hostSessionId = entity.hostSessionId,
        deliveryKey = entity.deliveryKey,
        presentationIntentId = entity.presentationIntentId,
        situationEpisodeId = entity.situationEpisodeId,
        targetScope = entity.targetScope,
        validUntilUtcMs = entity.validUntilUtcMs,
        readableDurationMillis = PulseDeliveryPolicyCatalog.readableDurationMillis(draft),
        story = draft,
        sourceFrameId = entity.sourceFrameId,
        controlRevision = entity.controlRevision,
    )

    /** A callback after its lease is stale cannot revive an old header payload.
     * We choose the conservative outcome after process death or a late bridge
     * callback: no invented exposure receipt. */
    private fun validAttempt(
        entity: FluviPulseDeliveryAttemptEntity,
        token: String,
        host: String,
        contentFingerprint: String,
        now: Long,
    ): Boolean = entity.leaseToken == token &&
        entity.hostSessionId == host &&
        entity.contentFingerprint == contentFingerprint &&
        entity.state in ACTIVE_ATTEMPT_STATES &&
        entity.validUntilUtcMs >= now

    private fun preferencesFromEntity(entity: FluviPulseDeliveryPreferencesEntity?, now: Long): PulseDeliveryPreferences =
        entity?.let { PulseDeliveryPreferences(it.automaticEnabled, it.normalCooldownMs, it.controlRevision, it.updatedAtUtcMs) }
            ?: PulseDeliveryPreferences(true, PulseDeliveryPolicyCatalog.default.normalCooldownMillis, 0L, now)

    private fun PulseDeliveryPreferences.toEntity() = FluviPulseDeliveryPreferencesEntity(
        automaticEnabled = automaticEnabled,
        normalCooldownMs = normalCooldownMillis,
        controlRevision = controlRevision,
        updatedAtUtcMs = updatedAtUtcMs,
    )

    private fun controlFromEntity(entity: FluviPulseDeliveryControlEntity) = PulseDeliveryControl(
        entity.controlId, PulseDeliveryControlKind.valueOf(entity.controlKind), entity.situationEpisodeId,
        entity.materialSemanticKey, entity.targetScope, entity.presentationIntentId, entity.expiresAtUtcMs,
        entity.consumedAtUtcMs, entity.createdAtUtcMs,
    )

    private fun attemptFromEntity(entity: FluviPulseDeliveryAttemptEntity) = PulseDeliveryAttempt(
        entity.attemptId, entity.leaseToken, entity.hostSessionId, entity.deliveryKey, entity.situationKey,
        entity.situationEpisodeId, entity.storyKey, entity.contentFingerprint, entity.materialSemanticKey,
        PulseDeliveryAttemptState.valueOf(entity.state), entity.validUntilUtcMs, entity.reservedAtUtcMs,
        entity.startedAtUtcMs, entity.presentedAtUtcMs, entity.qualifiedExposureAtUtcMs, entity.endedAtUtcMs, entity.endReason,
    )

    private fun receiptFromEntity(entity: FluviPulseDeliveryReceiptEntity) = PulseDeliveryReceipt(
        entity.receiptId, entity.deliveryKey, entity.situationEpisodeId, entity.storyKey,
        entity.materialSemanticKey, entity.attemptId, entity.qualifiedExposureAtUtcMs,
    )

    private fun eventFromEntity(entity: FluviPulseDeliveryEventEntity) = PulseDeliveryEvent(
        entity.eventId, PulseDeliveryEventKind.valueOf(entity.eventKind), entity.attemptId, entity.situationKey,
        entity.deliveryKey, entity.reasonCode, entity.sourceCoreRevision, entity.transitionSequence, entity.createdAtUtcMs,
    )

    private fun hash(value: String): String = MessageDigest.getInstance("SHA-256")
        .digest(value.toByteArray()).joinToString("") { "%02x".format(it) }.take(32)

    private companion object {
        const val AUTOMATIC_INTENT = "automatic"
        val ACTIVE_ATTEMPT_STATES = setOf(
            PulseDeliveryAttemptState.reserved.name,
            PulseDeliveryAttemptState.presenting.name,
            PulseDeliveryAttemptState.presented.name,
        )
    }
}
