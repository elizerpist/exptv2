package com.fluvi.core.model

/** A canonical partner snapshot for editor and directory consumers. */
data class FluviPartnerDirectoryEntry(
    val partnerId: String,
    val displayName: String,
    val originalName: String,
    val defaultCategoryId: String,
    val defaultCategoryName: String,
    val categoryColorId: String,
    val categoryIconId: String,
    val isUncategorized: Boolean,
    /** Display, original and persisted aliases for local selector search. */
    val searchNames: List<String>,
)

/** Complete persisted record required to hydrate one transaction editor. */
data class FluviLedgerEntryDetail(
    val entryId: String,
    val partnerId: String,
    val categoryId: String,
    val categoryAssignmentMode: CategoryAssignmentMode,
    val direction: LedgerDirection,
    val amountScaled100: Long,
    val bookedLocalEpochDay: Long,
    val bookedLocalTimeMinutes: Int,
    val occurredAtUtcMs: Long,
    val note: String?,
    val originKind: LedgerOriginKind,
    val notificationInboxId: String?,
    val recurrenceOccurrenceId: String? = null,
    val revision: Long,
)

sealed interface ManualTransactionPartnerSelection {
    data class Existing(val partnerId: String) : ManualTransactionPartnerSelection

    /** Only persisted if the enclosing transaction succeeds. */
    data class New(
        val displayName: String,
        val defaultCategoryId: String,
    ) : ManualTransactionPartnerSelection
}

data class CreateManualTransactionCommand(
    val partner: ManualTransactionPartnerSelection,
    val categorySelection: LedgerCategorySelection,
    val direction: LedgerDirection,
    val amountScaled100: Long,
    val bookedLocalEpochDay: Long,
    val bookedLocalTimeMinutes: Int,
    val occurredAtUtcMs: Long,
    val note: String?,
)

data class UpdateLedgerEntryCommand(
    val entryId: String,
    val expectedRevision: Long,
    val partner: ManualTransactionPartnerSelection,
    val categorySelection: LedgerCategorySelection,
    val amountScaled100: Long,
    val bookedLocalEpochDay: Long,
    val bookedLocalTimeMinutes: Int,
    /** Preserve source occurrence time for imported entries. */
    val occurredAtUtcMs: Long,
    val note: String?,
)

data class UpdatePartnerCommand(
    val partnerId: String,
    val displayNameOverride: String?,
    val defaultCategoryId: String,
)

class LedgerRevisionConflictException(entryId: String) : IllegalStateException(
    "Ledger entry $entryId changed before this editor could save it.",
)
