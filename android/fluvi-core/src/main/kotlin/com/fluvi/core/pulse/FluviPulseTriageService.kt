package com.fluvi.core.pulse

import androidx.room.withTransaction
import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.entity.FluviPulseSituationEntity
import com.fluvi.core.database.entity.FluviPulseSituationEventEntity
import com.fluvi.core.model.FluviClock
import java.security.MessageDigest
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/**
 * B-phase situation assembler.  It consumes exactly one signal frame, never
 * reads the Ledger itself, and persists diagnostic state without publishing a
 * financial Core revision.
 */
class FluviPulseTriageService internal constructor(
    private val database: FluviDatabase,
    private val signals: FluviPulseSignalService,
    private val clock: FluviClock,
) {
    private val evaluationMutex = Mutex()

    /** Lifecycle reconciliation is diagnostic-only and does not publish a financial revision. */
    suspend fun reevaluateCurrent(): PulseTriageDashboardSnapshot {
        val app = requireNotNull(database.appSettingsDao().current())
        val today = java.time.Instant.ofEpochMilli(clock.nowUtcMs())
            .atZone(java.time.ZoneId.of(app.localZoneId)).toLocalDate()
        return evaluate(today.year, today.monthValue)
    }

    suspend fun dashboard(year: Int, month: Int): PulseTriageDashboardSnapshot = evaluate(year, month)

    suspend fun inspection(
        year: Int,
        month: Int,
        situationKey: String,
        historyLimit: Int = 30,
        historyOffset: Int = 0,
    ): PulseSituationInspectionSnapshot {
        require(historyLimit in 1..100) { "Situation history limit must be 1..100." }
        val triage = evaluate(year, month)
        val situation = triage.situations.firstOrNull { it.situationKey == situationKey }
            ?: throw IllegalArgumentException("Unknown Pulse situation: $situationKey")
        val events = database.pulseSituationDao().eventPage(situationKey, historyLimit, historyOffset)
            .map(::eventFromEntity)
        return PulseSituationInspectionSnapshot(situation, events)
    }

    suspend fun history(
        year: Int,
        month: Int,
    ): List<PulseSituationSnapshot> = evaluate(year, month).situations

    private suspend fun evaluate(year: Int, month: Int): PulseTriageDashboardSnapshot = evaluationMutex.withLock {
        val frame = signals.frame(year, month)
        val persisted = if (frame.evaluationMode == PulseSignalEvaluationMode.live) {
            database.pulseSituationDao().statesForPeriod(periodKey(year, month)).associateBy { it.situationKey }
        } else {
            emptyMap()
        }
        val grouped = linkedMapOf<String, MutableList<PulseEvidenceIndependenceEvaluator.Input>>()
        frame.signals.forEach { signal ->
            PulseSituationCatalog.descriptors(signal).forEach { descriptor ->
                grouped.getOrPut(descriptor.situationKey, ::mutableListOf)
                    .add(PulseEvidenceIndependenceEvaluator.Input(signal, descriptor))
            }
        }
        val snapshots = grouped.entries.sortedBy { it.key }.map { (_, inputs) ->
            val descriptor = inputs.first().descriptor
            val previous = persisted[descriptor.situationKey]
            val independence = PulseEvidenceIndependenceEvaluator.evaluate(inputs)
            val trace = PulseTriageEvaluator.evaluate(
                descriptor = descriptor,
                signals = inputs.map { it.signal },
                units = independence.units,
                exclusions = independence.exclusions,
                previousState = previous?.state?.let(PulseSituationState::valueOf),
                configurationOnlyChange = previous != null &&
                    previous.sourceCoreRevision == frame.coreRevision &&
                    previous.sourceSignalGeneration != frame.signalGeneration,
            )
            val proposed = assembleSnapshot(descriptor, inputs.map { it.signal }, independence, trace, frame, previous)
            if (frame.evaluationMode == PulseSignalEvaluationMode.live &&
                !(previous == null && proposed.state == PulseSituationState.resolved)
            ) {
                persist(proposed, previous)
            } else {
                proposed
            }
        }
        PulseTriageDashboardSnapshot(
            dashboard = signals.dashboardFor(frame),
            situations = snapshots.filter {
                it.state != PulseSituationState.resolved ||
                    it.historicalInspection ||
                    persisted.containsKey(it.situationKey)
            }
                .sortedWith(compareBy<PulseSituationSnapshot> { it.domain.ordinal }.thenBy { it.targetKey }.thenBy { it.situationKey }),
            frame = frame,
        )
    }

    private fun assembleSnapshot(
        descriptor: PulseSituationDescriptor,
        signals: List<PulseRawSignal>,
        independence: PulseEvidenceIndependenceEvaluator.Result,
        trace: PulseTriageDecisionTrace,
        frame: PulseSignalFrame,
        previous: FluviPulseSituationEntity?,
    ): PulseSituationSnapshot {
        val previousState = previous?.state?.let(PulseSituationState::valueOf)
        val configurationOnly = previous != null &&
            previous.sourceCoreRevision == frame.coreRevision &&
            previous.sourceSignalGeneration != frame.signalGeneration
        val hasEvaluable = signals.any {
            it.dataQuality == PulseSignalDataQuality.sufficient || it.dataQuality == PulseSignalDataQuality.limited
        }
        val hasActive = independence.units.any { it.countableForFormation }
        val hasFormationEvidence = hasActive || signals.any {
            it.activityState == PulseSignalActivityState.pendingConfirmation
        }
        val state = PulseSituationStateReducer.reduce(
            PulseSituationStateReducer.Input(
                previous = previousState,
                hasEvaluableInputs = hasEvaluable,
                hasFormationEvidence = hasFormationEvidence,
                matchedRule = trace.matchedRule,
                configurationOnlyChange = configurationOnly,
            ),
        )
        val regularMatch = trace.matchedRule?.takeUnless { it == PulseTriageRuleCatalog.verifiedRecovery }
        val formationRule = if (state == PulseSituationState.ready) regularMatch else null
        val semantic = fingerprint(
            listOf(
                descriptor.situationKey,
                state.name,
                formationRule,
                trace.countedEvidenceKeys.sorted().joinToString(","),
                independence.units.sortedBy { it.evidenceKey }.joinToString("|") {
                    listOf(it.evidenceKey, it.strength, it.role, it.independence, it.actualImpactMinor, it.projectedImpactMinor).joinToString(":")
                },
                trace.missingRequirements.sorted().joinToString(","),
            ).joinToString("|"),
        )
        val changed = previous?.semanticFingerprint != semantic
        val now = frame.evaluatedAtUtcMs
        return PulseSituationSnapshot(
            situationKey = descriptor.situationKey,
            domain = descriptor.domain,
            targetKey = descriptor.targetKey,
            periodKey = descriptor.periodKey,
            state = state,
            formationRule = formationRule,
            relatedSignalKeys = signals.map(PulseRawSignal::signalKey).sorted(),
            leadingSignalKey = independence.units.firstOrNull { it.role == PulseEvidenceRole.leading }?.sourceSignalKeys?.firstOrNull(),
            supportingSignalKeys = independence.units.filter { it.role != PulseEvidenceRole.leading }
                .flatMap { it.sourceSignalKeys }.sorted(),
            evidenceUnits = independence.units,
            independentEvidenceCount = trace.independentEvidenceCount,
            decisionTrace = trace,
            sourceCoreRevision = frame.coreRevision,
            sourceSignalGeneration = frame.signalGeneration,
            policyVersion = PulseTriageRuleCatalog.policyVersion,
            firstObservedAtUtcMs = previous?.firstObservedAtUtcMs ?: if (state != PulseSituationState.resolved) now else null,
            lastEvaluatedAtUtcMs = now,
            lastMaterialChangeAtUtcMs = if (changed) now else previous?.lastMaterialChangeAtUtcMs,
            semanticFingerprint = semantic,
            historicalInspection = frame.evaluationMode == PulseSignalEvaluationMode.historicalInspection,
        )
    }

    private suspend fun persist(
        proposed: PulseSituationSnapshot,
        previous: FluviPulseSituationEntity?,
    ): PulseSituationSnapshot = database.withTransaction {
        // The mutex serializes local callers; this equality guard makes retries
        // and same-frame re-evaluations no-ops as well.
        val current = database.pulseSituationDao().state(proposed.situationKey)
        if (current?.semanticFingerprint == proposed.semanticFingerprint &&
            current.sourceSignalGeneration == proposed.sourceSignalGeneration &&
            current.policyVersion == proposed.policyVersion
        ) {
            return@withTransaction proposed.copy(
                firstObservedAtUtcMs = current.firstObservedAtUtcMs,
                lastMaterialChangeAtUtcMs = current.lastMaterialChangeAtUtcMs,
            )
        }
        val prior = current ?: previous
        val version = (prior?.stateVersion ?: 0L) + 1L
        val entity = situationEntity(proposed, version)
        database.pulseSituationDao().upsertState(entity)
        eventFor(prior, proposed, version)?.let { database.pulseSituationDao().insertEvent(it) }
        proposed.copy(
            firstObservedAtUtcMs = entity.firstObservedAtUtcMs,
            lastMaterialChangeAtUtcMs = entity.lastMaterialChangeAtUtcMs,
        )
    }

    private fun situationEntity(snapshot: PulseSituationSnapshot, version: Long) = FluviPulseSituationEntity(
        situationKey = snapshot.situationKey,
        domain = snapshot.domain.name,
        targetKey = snapshot.targetKey,
        periodKey = snapshot.periodKey,
        state = snapshot.state.name,
        formationRule = snapshot.formationRule,
        relatedSignalKeys = "v1|" + snapshot.relatedSignalKeys.joinToString(","),
        evidenceSnapshot = "v1|" + snapshot.evidenceUnits.joinToString(";") { unit ->
            listOf(unit.evidenceKey, unit.indicatorId, unit.role, unit.independence, unit.strength).joinToString(":")
        },
        decisionTrace = "v1|${snapshot.decisionTrace.matchedRule ?: ""}|${snapshot.decisionTrace.missingRequirements.joinToString(",")}",
        firstObservedAtUtcMs = snapshot.firstObservedAtUtcMs,
        lastEvaluatedAtUtcMs = snapshot.lastEvaluatedAtUtcMs,
        lastMaterialChangeAtUtcMs = snapshot.lastMaterialChangeAtUtcMs,
        sourceCoreRevision = snapshot.sourceCoreRevision,
        sourceSignalGeneration = snapshot.sourceSignalGeneration,
        policyVersion = snapshot.policyVersion,
        semanticFingerprint = snapshot.semanticFingerprint,
        stateVersion = version,
        updatedAtUtcMs = snapshot.lastEvaluatedAtUtcMs,
    )

    private fun eventFor(
        previous: FluviPulseSituationEntity?,
        next: PulseSituationSnapshot,
        sequence: Long,
    ): FluviPulseSituationEventEntity? {
        if (previous?.semanticFingerprint == next.semanticFingerprint) return null
        val old = previous?.state?.let(PulseSituationState::valueOf)
        val kind = when {
            old == null && next.state == PulseSituationState.resolved -> return null
            previous != null && previous.sourceCoreRevision == next.sourceCoreRevision &&
                previous.sourceSignalGeneration != next.sourceSignalGeneration -> PulseSituationEventKind.configurationChanged
            old == null && next.state == PulseSituationState.forming -> PulseSituationEventKind.formed
            old == null && next.state == PulseSituationState.ready -> PulseSituationEventKind.ready
            old == PulseSituationState.resolved && next.state == PulseSituationState.ready -> PulseSituationEventKind.reopened
            next.state == PulseSituationState.ready && old != PulseSituationState.ready -> PulseSituationEventKind.ready
            next.state == PulseSituationState.improving -> PulseSituationEventKind.improving
            next.state == PulseSituationState.resolved -> PulseSituationEventKind.resolved
            next.state == PulseSituationState.suspended -> PulseSituationEventKind.suspended
            old == next.state && previous?.sourceCoreRevision == next.sourceCoreRevision -> PulseSituationEventKind.configurationChanged
            next.independentEvidenceCount > parseEvidenceCount(previous?.evidenceSnapshot) -> PulseSituationEventKind.strengthened
            else -> PulseSituationEventKind.weakened
        }
        return FluviPulseSituationEventEntity(
            eventId = fingerprint(next.situationKey + "|" + sequence),
            situationKey = next.situationKey,
            domain = next.domain.name,
            periodKey = next.periodKey,
            eventKind = kind.name,
            previousState = old?.name,
            nextState = next.state.name,
            previousFormationRule = previous?.formationRule,
            nextFormationRule = next.formationRule,
            previousEvidenceCount = parseEvidenceCount(previous?.evidenceSnapshot),
            nextEvidenceCount = next.independentEvidenceCount,
            previousFingerprint = previous?.semanticFingerprint,
            nextFingerprint = next.semanticFingerprint,
            causeCode = next.decisionTrace.matchedRule ?: next.decisionTrace.missingRequirements.firstOrNull() ?: "state-change",
            explanationPayload = "v1|" + next.decisionTrace.explanationHu.joinToString("\u001f"),
            inputRevision = next.sourceCoreRevision,
            policyVersion = next.policyVersion,
            transitionSequence = sequence,
            createdAtUtcMs = next.lastEvaluatedAtUtcMs,
        )
    }

    private fun parseEvidenceCount(payload: String?): Int = payload
        ?.removePrefix("v1|")?.takeIf { it.isNotBlank() }?.split(';')?.size ?: 0

    private fun eventFromEntity(entity: FluviPulseSituationEventEntity) = PulseSituationEvent(
        eventId = entity.eventId,
        situationKey = entity.situationKey,
        kind = PulseSituationEventKind.valueOf(entity.eventKind),
        previousState = entity.previousState?.let(PulseSituationState::valueOf),
        nextState = PulseSituationState.valueOf(entity.nextState),
        previousFormationRule = entity.previousFormationRule,
        nextFormationRule = entity.nextFormationRule,
        previousEvidenceCount = entity.previousEvidenceCount,
        nextEvidenceCount = entity.nextEvidenceCount,
        causeCode = entity.causeCode,
        explanationHu = entity.explanationPayload.removePrefix("v1|").split("\u001f").filter(String::isNotBlank),
        sourceCoreRevision = entity.inputRevision,
        policyVersion = entity.policyVersion,
        transitionSequence = entity.transitionSequence,
        createdAtUtcMs = entity.createdAtUtcMs,
    )

    private fun periodKey(year: Int, month: Int) = "%04d-%02d".format(java.util.Locale.ROOT, year, month)

    private fun fingerprint(value: String): String = MessageDigest.getInstance("SHA-256")
        .digest(value.toByteArray())
        .joinToString("") { "%02x".format(it) }
}
