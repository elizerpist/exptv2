package com.fluvi.core.database.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index

/**
 * A user override is deliberately sparse: the catalog owns defaults and this
 * table stores only an explicit value for an indicator/target/threshold key.
 * It has no relationship to alerting; Pulse V1 is read and configuration only.
 */
@Entity(
    tableName = "fluvi_pulse_indicator_settings",
    primaryKeys = ["indicator_id", "target_key", "threshold_key"],
    indices = [
        Index(value = ["indicator_id", "updated_at_utc_ms"]),
        Index(value = ["target_key"]),
    ],
)
data class FluviPulseIndicatorSettingEntity(
    @ColumnInfo(name = "indicator_id")
    val indicatorId: String,
    /** Empty string is the stable global target. Category/partner overrides use their canonical ID. */
    @ColumnInfo(name = "target_key")
    val targetKey: String,
    @ColumnInfo(name = "threshold_key")
    val thresholdKey: String,
    @ColumnInfo(name = "value")
    val value: Double,
    @ColumnInfo(name = "updated_at_utc_ms")
    val updatedAtUtcMs: Long,
)

/**
 * Current raw-signal state. This table deliberately does not participate in
 * Core's financial revision: updating diagnostic state must not trigger a
 * financial-query/evaluation loop.
 */
@Entity(
    tableName = "fluvi_pulse_signal_states",
    indices = [
        Index(value = ["indicator_id", "period_key"]),
        Index(value = ["activity_state", "updated_at_utc_ms"]),
        Index(value = ["situation_key"]),
    ],
)
data class FluviPulseSignalStateEntity(
    @androidx.room.PrimaryKey
    @ColumnInfo(name = "signal_key")
    val signalKey: String,
    @ColumnInfo(name = "indicator_id")
    val indicatorId: String,
    @ColumnInfo(name = "target_key")
    val targetKey: String,
    @ColumnInfo(name = "period_key")
    val periodKey: String,
    @ColumnInfo(name = "scenario_key")
    val scenarioKey: String,
    @ColumnInfo(name = "activity_state")
    val activityState: String,
    @ColumnInfo(name = "strength")
    val strength: String?,
    @ColumnInfo(name = "previous_strength")
    val previousStrength: String?,
    @ColumnInfo(name = "data_quality")
    val dataQuality: String,
    @ColumnInfo(name = "confirmation_count")
    val confirmationCount: Int,
    @ColumnInfo(name = "measured_value")
    val measuredValue: Double?,
    @ColumnInfo(name = "threshold_value")
    val thresholdValue: Double?,
    @ColumnInfo(name = "first_observed_at_utc_ms")
    val firstObservedAtUtcMs: Long?,
    @ColumnInfo(name = "last_evaluated_at_utc_ms")
    val lastEvaluatedAtUtcMs: Long,
    @ColumnInfo(name = "last_material_change_at_utc_ms")
    val lastMaterialChangeAtUtcMs: Long?,
    @ColumnInfo(name = "last_input_revision")
    val lastInputRevision: Long,
    @ColumnInfo(name = "last_config_revision")
    val lastConfigRevision: Long,
    @ColumnInfo(name = "evaluation_fingerprint")
    val evaluationFingerprint: String,
    @ColumnInfo(name = "situation_key")
    val situationKey: String,
    @ColumnInfo(name = "evidence_family")
    val evidenceFamily: String,
    /** Compact, versioned trace for audit; UI receives a typed live trace. */
    @ColumnInfo(name = "trace_payload")
    val tracePayload: String,
    @ColumnInfo(name = "updated_at_utc_ms")
    val updatedAtUtcMs: Long,
)

/** Only material state transitions are retained; duplicate fingerprints are ignored. */
@Entity(
    tableName = "fluvi_pulse_signal_events",
    indices = [
        Index(value = ["signal_key", "created_at_utc_ms"]),
        Index(value = ["signal_key", "evaluation_fingerprint", "event_kind"], unique = true),
        Index(value = ["created_at_utc_ms"]),
    ],
)
data class FluviPulseSignalEventEntity(
    @androidx.room.PrimaryKey
    @ColumnInfo(name = "event_id")
    val eventId: String,
    @ColumnInfo(name = "signal_key")
    val signalKey: String,
    @ColumnInfo(name = "event_kind")
    val eventKind: String,
    @ColumnInfo(name = "previous_state")
    val previousState: String?,
    @ColumnInfo(name = "next_state")
    val nextState: String,
    @ColumnInfo(name = "previous_strength")
    val previousStrength: String?,
    @ColumnInfo(name = "next_strength")
    val nextStrength: String?,
    @ColumnInfo(name = "measured_value")
    val measuredValue: Double?,
    @ColumnInfo(name = "threshold_value")
    val thresholdValue: Double?,
    @ColumnInfo(name = "input_revision")
    val inputRevision: Long,
    @ColumnInfo(name = "config_revision")
    val configRevision: Long,
    @ColumnInfo(name = "cause")
    val cause: String,
    @ColumnInfo(name = "evaluation_fingerprint")
    val evaluationFingerprint: String,
    @ColumnInfo(name = "trace_payload")
    val tracePayload: String,
    @ColumnInfo(name = "created_at_utc_ms")
    val createdAtUtcMs: Long,
)

/** Diagnostic triage state.  It never changes the financial Core revision. */
@Entity(
    tableName = "fluvi_pulse_situations",
    indices = [
        Index(value = ["state", "updated_at_utc_ms"]),
        Index(value = ["domain", "period_key"]),
        Index(value = ["period_key"]),
    ],
)
data class FluviPulseSituationEntity(
    @androidx.room.PrimaryKey
    @ColumnInfo(name = "situation_key")
    val situationKey: String,
    @ColumnInfo(name = "domain")
    val domain: String,
    @ColumnInfo(name = "target_key")
    val targetKey: String,
    @ColumnInfo(name = "period_key")
    val periodKey: String,
    @ColumnInfo(name = "state")
    val state: String,
    @ColumnInfo(name = "formation_rule")
    val formationRule: String?,
    @ColumnInfo(name = "related_signal_keys")
    val relatedSignalKeys: String,
    /** Versioned compact representation; Flutter receives the typed runtime snapshot. */
    @ColumnInfo(name = "evidence_snapshot")
    val evidenceSnapshot: String,
    @ColumnInfo(name = "decision_trace")
    val decisionTrace: String,
    @ColumnInfo(name = "first_observed_at_utc_ms")
    val firstObservedAtUtcMs: Long?,
    @ColumnInfo(name = "last_evaluated_at_utc_ms")
    val lastEvaluatedAtUtcMs: Long,
    @ColumnInfo(name = "last_material_change_at_utc_ms")
    val lastMaterialChangeAtUtcMs: Long?,
    @ColumnInfo(name = "source_core_revision")
    val sourceCoreRevision: Long,
    @ColumnInfo(name = "source_signal_generation")
    val sourceSignalGeneration: Long,
    @ColumnInfo(name = "policy_version")
    val policyVersion: Int,
    @ColumnInfo(name = "semantic_fingerprint")
    val semanticFingerprint: String,
    @ColumnInfo(name = "state_version")
    val stateVersion: Long,
    @ColumnInfo(name = "updated_at_utc_ms")
    val updatedAtUtcMs: Long,
)

@Entity(
    tableName = "fluvi_pulse_situation_events",
    indices = [
        Index(value = ["situation_key", "created_at_utc_ms"]),
        Index(value = ["next_state"]),
        Index(value = ["domain", "period_key"]),
        Index(value = ["situation_key", "transition_sequence"], unique = true),
    ],
)
data class FluviPulseSituationEventEntity(
    @androidx.room.PrimaryKey
    @ColumnInfo(name = "event_id")
    val eventId: String,
    @ColumnInfo(name = "situation_key")
    val situationKey: String,
    @ColumnInfo(name = "domain")
    val domain: String,
    @ColumnInfo(name = "period_key")
    val periodKey: String,
    @ColumnInfo(name = "event_kind")
    val eventKind: String,
    @ColumnInfo(name = "previous_state")
    val previousState: String?,
    @ColumnInfo(name = "next_state")
    val nextState: String,
    @ColumnInfo(name = "previous_formation_rule")
    val previousFormationRule: String?,
    @ColumnInfo(name = "next_formation_rule")
    val nextFormationRule: String?,
    @ColumnInfo(name = "previous_evidence_count")
    val previousEvidenceCount: Int,
    @ColumnInfo(name = "next_evidence_count")
    val nextEvidenceCount: Int,
    @ColumnInfo(name = "previous_fingerprint")
    val previousFingerprint: String?,
    @ColumnInfo(name = "next_fingerprint")
    val nextFingerprint: String,
    @ColumnInfo(name = "cause_code")
    val causeCode: String,
    @ColumnInfo(name = "explanation_payload")
    val explanationPayload: String,
    @ColumnInfo(name = "input_revision")
    val inputRevision: Long,
    @ColumnInfo(name = "policy_version")
    val policyVersion: Int,
    @ColumnInfo(name = "transition_sequence")
    val transitionSequence: Long,
    @ColumnInfo(name = "created_at_utc_ms")
    val createdAtUtcMs: Long,
)
