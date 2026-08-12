package com.fluvi.core.database.dao

import androidx.room.ColumnInfo

internal data class FluviLedgerAggregateRow(
    @ColumnInfo(name = "entry_count")
    val entryCount: Long,
    @ColumnInfo(name = "amount_scaled_100")
    val amountScaled100: Long,
)

internal data class FluviLedgerAmountDomainRow(
    @ColumnInfo(name = "minimum_amount_scaled_100")
    val minimumAmountScaled100: Long,
    @ColumnInfo(name = "maximum_amount_scaled_100")
    val maximumAmountScaled100: Long,
)

/** Neutral SQL aggregate bucket shared by facets and time-child previews. */
internal data class FluviLedgerAggregateBucketRow(
    @ColumnInfo(name = "group_id")
    val groupId: String,
    @ColumnInfo(name = "entry_count")
    val entryCount: Long,
    @ColumnInfo(name = "amount_scaled_100")
    val amountScaled100: Long,
)

internal data class FluviLedgerDailyAggregateRow(
    @ColumnInfo(name = "direction")
    val direction: String,
    @ColumnInfo(name = "booked_local_epoch_day")
    val bookedLocalEpochDay: Long,
    @ColumnInfo(name = "entry_count")
    val entryCount: Long,
    @ColumnInfo(name = "amount_scaled_100")
    val amountScaled100: Long,
)

internal data class FluviStringIdRow(
    @ColumnInfo(name = "id")
    val id: String,
)

/**
 * Bounded committed-vertical row projection.  Unlike the general dashboard
 * index this is deliberately one page wide, so the SQL join supplies exactly
 * the display metadata needed for those rows without loading full catalogs.
 */
internal data class FluviCommittedDashboardRow(
    @ColumnInfo(name = "entry_id")
    val entryId: String,
    @ColumnInfo(name = "direction")
    val direction: String,
    @ColumnInfo(name = "amount_minor")
    val amountMinor: Long,
    @ColumnInfo(name = "booked_local_epoch_day")
    val bookedLocalEpochDay: Long,
    @ColumnInfo(name = "booked_local_time_minutes")
    val bookedLocalTimeMinutes: Int,
    @ColumnInfo(name = "occurred_at_utc_ms")
    val occurredAtUtcMs: Long,
    @ColumnInfo(name = "partner_id")
    val partnerId: String,
    @ColumnInfo(name = "partner_display_name")
    val partnerDisplayName: String,
    @ColumnInfo(name = "category_id")
    val categoryId: String,
    @ColumnInfo(name = "category_display_name")
    val categoryDisplayName: String,
    @ColumnInfo(name = "category_color_id")
    val categoryColorId: String,
    @ColumnInfo(name = "category_icon_id")
    val categoryIconId: String,
    @ColumnInfo(name = "assignment_mode")
    val assignmentMode: String,
    @ColumnInfo(name = "origin_kind")
    val originKind: String,
    @ColumnInfo(name = "note")
    val note: String?,
)
