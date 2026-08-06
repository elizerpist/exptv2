package com.fluvi.core.database.dao

import androidx.room.ColumnInfo

internal data class FluviLedgerAggregateRow(
    @ColumnInfo(name = "entry_count")
    val entryCount: Long,
    @ColumnInfo(name = "amount_scaled_100")
    val amountScaled100: Long,
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
