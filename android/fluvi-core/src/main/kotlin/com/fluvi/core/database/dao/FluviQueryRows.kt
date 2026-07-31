package com.fluvi.core.database.dao

import androidx.room.ColumnInfo

internal data class FluviLedgerAggregateRow(
    @ColumnInfo(name = "entry_count")
    val entryCount: Long,
    @ColumnInfo(name = "amount_scaled_100")
    val amountScaled100: Long,
)

internal data class FluviLedgerGroupedSummaryRow(
    @ColumnInfo(name = "group_id")
    val groupId: String,
    @ColumnInfo(name = "entry_count")
    val entryCount: Long,
    @ColumnInfo(name = "amount_scaled_100")
    val amountScaled100: Long,
)

internal data class FluviStringIdRow(
    @ColumnInfo(name = "id")
    val id: String,
)
