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
