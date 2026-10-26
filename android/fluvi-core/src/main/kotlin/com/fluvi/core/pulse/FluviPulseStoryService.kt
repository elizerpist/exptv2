package com.fluvi.core.pulse

import com.fluvi.core.database.FluviDatabase
import java.util.LinkedHashMap
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/**
 * Offline D-phase facade. Story results are immutable projections of a single
 * Priority inspection snapshot; opening a preview never mutates persistence.
 */
class FluviPulseStoryService internal constructor(
    private val database: FluviDatabase,
    private val priority: FluviPulsePriorityService,
) {
    private val mutex = Mutex()
    private val cache = object : LinkedHashMap<String, PulseStoryInspectionSnapshot>(24, .75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, PulseStoryInspectionSnapshot>?): Boolean = size > 24
    }

    suspend fun selectedStoryPreview(year: Int, month: Int): PulseStoryCompositionResult =
        selectedInspection(year, month).result

    suspend fun candidateStoryPreview(year: Int, month: Int, situationKey: String): PulseStoryCompositionResult =
        candidateInspection(year, month, situationKey).result

    suspend fun storyInspection(year: Int, month: Int, situationKey: String?): PulseStoryInspectionSnapshot =
        if (situationKey == null) selectedInspection(year, month) else candidateInspection(year, month, situationKey)

    /**
     * Composes from an already coherent C-phase inspection. Delivery uses
     * this path for every ranked candidate, so a header lease never reruns
     * the signal, triage, or priority engines candidate by candidate.
     */
    internal suspend fun composeFromPriorityInspection(
        snapshot: PulsePriorityInspectionSnapshot,
        situationKey: String,
    ): PulseStoryInspectionSnapshot = mutex.withLock {
        compose(snapshot, situationKey)
    }

    private suspend fun selectedInspection(year: Int, month: Int): PulseStoryInspectionSnapshot = mutex.withLock {
        val snapshot = priority.inspection(year, month, historyLimit = 1)
        val key = snapshot.frame.selectedSituationKey
            ?: return@withLock empty(snapshot.frame, "no-selected-candidate", "Nincs kiválasztott Priority helyzet.")
        compose(snapshot, key)
    }

    private suspend fun candidateInspection(year: Int, month: Int, situationKey: String): PulseStoryInspectionSnapshot = mutex.withLock {
        val snapshot = priority.inspection(year, month, historyLimit = 1)
        compose(snapshot, situationKey)
    }

    private suspend fun compose(snapshot: PulsePriorityInspectionSnapshot, situationKey: String): PulseStoryInspectionSnapshot {
        val candidate = snapshot.frame.rankedCandidates.firstOrNull { it.situation.situationKey == situationKey }
            ?: return empty(snapshot.frame, "candidate-not-ready", "Ehhez a helyzethez nincs rangsorolható, kész Story-jelölt.")
        val situation = snapshot.situations.firstOrNull { it.situationKey == situationKey }
            ?: return empty(snapshot.frame, "missing-situation", "A Priority jelölthöz tartozó helyzet nem található.")
        if (situation.sourceCoreRevision != snapshot.frame.sourceCoreRevision || candidate.situation.sourceCoreRevision != snapshot.frame.sourceCoreRevision) {
            return empty(snapshot.frame, "stale-snapshot", "A Story forrásai közben megváltoztak; az előnézetet újra kell tölteni.", PulseStoryCompositionStatus.staleSnapshot)
        }
        val localZoneId = requireNotNull(database.appSettingsDao().current()).localZoneId
        val cacheKey = listOf(snapshot.frame.sourceTriageFrameId, situationKey, snapshot.frame.sourceCoreRevision,
            PulseStoryTemplateCatalog.version, snapshot.frame.evaluationMode, localZoneId).joinToString("|")
        cache[cacheKey]?.let { return it }
        val facts = PulseStoryFactResolver.resolve(situation, candidate)
        val context = PulseStoryContext(snapshot.frame.sourceTriageFrameId, situation, candidate, facts,
            snapshot.frame.evaluationMode, snapshot.frame.evaluatedAtUtcMs, localZoneId)
        return PulseStoryInspectionSnapshot(PulseStoryComposer.compose(context), facts, snapshot.frame.sourceTriageFrameId, snapshot.frame.sourceCoreRevision)
            .also { cache[cacheKey] = it }
    }

    private fun empty(
        frame: PulsePriorityFrame,
        reason: String,
        explanation: String,
        status: PulseStoryCompositionStatus = PulseStoryCompositionStatus.insufficientFacts,
    ) = PulseStoryInspectionSnapshot(
        PulseStoryCompositionResult(status, reasonCode = reason, explanationHu = explanation), null,
        frame.sourceTriageFrameId, frame.sourceCoreRevision,
    )
}
