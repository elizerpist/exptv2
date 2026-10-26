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
