package com.fluvi.core.model

sealed interface LedgerCategorySelection {
    data object PartnerDefault : LedgerCategorySelection

    data class EntryOverride(
        val categoryId: String,
    ) : LedgerCategorySelection
}

data class CreateLedgerEntryCommand(
    val partnerId: String,
    val categorySelection: LedgerCategorySelection,
    val note: String?,
    val direction: LedgerDirection,
    val amountScaled100: Long,
    val bookedLocalEpochDay: Long,
    val bookedLocalTimeMinutes: Int,
    val occurredAtUtcMs: Long,
    val originKind: LedgerOriginKind,
    val notificationInboxId: String?,
)
