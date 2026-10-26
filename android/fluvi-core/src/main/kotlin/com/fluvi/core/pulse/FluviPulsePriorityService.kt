package com.fluvi.core.pulse

import androidx.room.withTransaction
import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.entity.FluviPulsePriorityEventEntity
import com.fluvi.core.database.entity.FluviPulsePriorityStateEntity
import com.fluvi.core.model.FluviClock
import java.security.MessageDigest
import java.time.Instant
import java.time.ZoneId
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/**
 * C-phase coordinator. It consumes a single B-phase frame and never reads or
 * aggregates Ledger data. Its own Room writes are diagnostic state only.
 */
class FluviPulsePriorityService internal constructor(
    private val database: FluviDatabase,
    private val triage: FluviPulseTriageService,
    private val clock: FluviClock,
) {
    private val evaluationMutex = Mutex()

    suspend fun dashboard(year: Int, month: Int): PulsePriorityDashboardSnapshot = evaluationMutex.withLock {
        val triageSnapshot = triage.dashboard(year, month)
        PulsePriorityDashboardSnapshot(triageSnapshot, evaluate(triageSnapshot))
    }

    suspend fun reevaluateCurrent(): PulsePriorityDashboardSnapshot = evaluationMutex.withLock {
        val app = requireNotNull(database.appSettingsDao().current())
        val today = Instant.ofEpochMilli(clock.nowUtcMs()).atZone(ZoneId.of(app.localZoneId)).toLocalDate()
        val triageSnapshot = triage.dashboard(today.year, today.monthValue)
        PulsePriorityDashboardSnapshot(triageSnapshot, evaluate(triageSnapshot))
    }

    suspend fun inspection(
        year: Int,
        month: Int,
        historyLimit: Int = 30,
        historyOffset: Int = 0,
    ): PulsePriorityInspectionSnapshot = evaluationMutex.withLock {
        require(historyLimit in 1..100) { "Priority history limit must be 1..100." }
        val triageSnapshot = triage.dashboard(year, month)
        val frame = evaluate(triageSnapshot)
        val events = if (frame.evaluationMode == PulseSignalEvaluationMode.live) {
            database.pulsePriorityDao().eventPage(historyLimit, historyOffset).map(::eventFromEntity)
        } else emptyList()
        PulsePriorityInspectionSnapshot(frame, triageSnapshot.situations, events)
    }

    private suspend fun evaluate(triageSnapshot: PulseTriageDashboardSnapshot): PulsePriorityFrame {
        val frame = triageSnapshot.frame
        val frameId = triageFrameId(triageSnapshot)
        val app = requireNotNull(database.appSettingsDao().current())
        val todayEpochDay = Instant.ofEpochMilli(clock.nowUtcMs()).atZone(ZoneId.of(app.localZoneId)).toLocalDate().toEpochDay()
        val recoveryKeys = if (frame.evaluationMode == PulseSignalEvaluationMode.live) {
            triageSnapshot.situations.filter { it.state == PulseSituationState.improving }
                .filter { situation ->
                    database.pulseSituationDao().eventPage(situation.situationKey, 1).firstOrNull()?.let {
                        it.eventKind == PulseSituationEventKind.improving.name && it.causeCode != "configurationChanged"
                    } == true
                }.mapTo(linkedSetOf()) { it.situationKey }
        } else emptySet()
        val candidates = PulsePriorityCandidateResolver.resolve(triageSnapshot.situations, recoveryKeys)
            .map { PulsePriorityScorer.score(it, todayEpochDay) }
        val priority = PulsePrioritySelector.select(
            sourceCoreRevision = frame.coreRevision,
            sourceTriageFrameId = frameId,
            mode = frame.evaluationMode,
            evaluatedAtUtcMs = frame.evaluatedAtUtcMs,
            candidates = candidates,
        )
        return if (frame.evaluationMode == PulseSignalEvaluationMode.live) persist(priority) else priority
    }

    private suspend fun persist(proposed: PulsePriorityFrame): PulsePriorityFrame = database.withTransaction {
        val dao = database.pulsePriorityDao()
        val current = dao.current()
        // A stale asynchronous frame must not supersede a newer financial frame.
        if (current != null && current.sourceCoreRevision > proposed.sourceCoreRevision) return@withTransaction proposed
        val selected = proposed.rankedCandidates.firstOrNull()
        val fingerprint = fingerprint(
            listOf(
                proposed.sourceTriageFrameId,
                proposed.policyVersion,
                proposed.selectedSituationKey.orEmpty(),
                selected?.finalScore ?: "",
            ).joinToString("|"),
        )
        val reduced = PulsePriorityStateReducer.reduce(
            current?.let { PulsePriorityStateReducer.Previous(it.selectedSituationKey, it.selectionFingerprint) },
            proposed.selectedSituationKey,
            fingerprint,
        )
        if (!reduced.write) return@withTransaction proposed
        val changed = reduced.eventKind != null
        val version = (current?.stateVersion ?: 0L) + 1L
        val state = FluviPulsePriorityStateEntity(
            selectedSituationKey = proposed.selectedSituationKey,
            selectedScore = selected?.finalScore,
            sourceCoreRevision = proposed.sourceCoreRevision,
            sourceTriageFrameId = proposed.sourceTriageFrameId,
            policyVersion = proposed.policyVersion,
            selectionFingerprint = fingerprint,
            lastEvaluatedAtUtcMs = proposed.evaluatedAtUtcMs,
            lastSelectionChangeAtUtcMs = if (changed || current == null) proposed.evaluatedAtUtcMs else current.lastSelectionChangeAtUtcMs,
            stateVersion = version,
        )
        dao.upsertState(state)
        if (reduced.eventKind != null) {
            eventFor(current, proposed, version, reduced.eventKind)?.let { event -> dao.insertEvent(event) }
        }
        proposed
    }

    private fun eventFor(
        previous: FluviPulsePriorityStateEntity?,
        next: PulsePriorityFrame,
        sequence: Long,
        kind: PulsePriorityEventKind,
    ): FluviPulsePriorityEventEntity? {
        val selected = next.rankedCandidates.firstOrNull()
        return FluviPulsePriorityEventEntity(
            eventId = fingerprint("${next.sourceTriageFrameId}|$sequence|${next.selectedSituationKey}"),
            eventKind = kind.name,
            previousSelectedSituationKey = previous?.selectedSituationKey,
            nextSelectedSituationKey = next.selectedSituationKey,
            previousScore = previous?.selectedScore,
            nextScore = selected?.finalScore,
            selectionReason = next.selectionReason?.reasonCode ?: "no-eligible-candidate",
            sourceCoreRevision = next.sourceCoreRevision,
            sourceTriageFrameId = next.sourceTriageFrameId,
            policyVersion = next.policyVersion,
            transitionSequence = sequence,
            createdAtUtcMs = next.evaluatedAtUtcMs,
        )
    }

    private fun triageFrameId(snapshot: PulseTriageDashboardSnapshot): String = fingerprint(
        listOf(
            snapshot.frame.coreRevision,
            snapshot.frame.signalGeneration,
            snapshot.frame.configurationRevision,
            PulseTriageRuleCatalog.policyVersion,
            snapshot.situations.sortedBy { it.situationKey }.joinToString("|") {
                "${it.situationKey}:${it.semanticFingerprint}:${it.state}"
            },
        ).joinToString("|"),
    )

    private fun eventFromEntity(entity: FluviPulsePriorityEventEntity) = PulsePriorityEvent(
        eventId = entity.eventId,
        kind = PulsePriorityEventKind.valueOf(entity.eventKind),
        previousSelectedSituationKey = entity.previousSelectedSituationKey,
        nextSelectedSituationKey = entity.nextSelectedSituationKey,
        previousScore = entity.previousScore,
        nextScore = entity.nextScore,
        selectionReason = entity.selectionReason,
        sourceCoreRevision = entity.sourceCoreRevision,
        sourceTriageFrameId = entity.sourceTriageFrameId,
        policyVersion = entity.policyVersion,
        transitionSequence = entity.transitionSequence,
        createdAtUtcMs = entity.createdAtUtcMs,
    )

    private fun fingerprint(value: String): String = MessageDigest.getInstance("SHA-256")
        .digest(value.toByteArray()).joinToString("") { "%02x".format(it) }.take(24)
}
