package com.fluvi.core.model

/** User-authored monthly recurrence.  A rule does not itself affect financial totals. */
data class FluviRecurrenceRule(
    val ruleId: String,
    val name: String,
    val partnerId: String,
    val categoryId: String,
    val categoryAssignmentMode: CategoryAssignmentMode,
    val direction: LedgerDirection,
    val note: String?,
    val triggerKind: RecurrenceTriggerKind,
    val amountPolicy: RecurrenceAmountPolicy,
    val amountScaled100: Long?,
    val dayOfMonth: Int,
    val localTimeMinutes: Int,
    val startLocalEpochDay: Long,
    val endLocalEpochDay: Long?,
    val timezoneId: String,
    val isActive: Boolean,
    val ruleVersion: Int,
)

data class FluviRecurrenceOccurrence(
    val occurrenceId: String,
    val ruleId: String,
    val occurrenceKey: String,
    val expectedLocalEpochDay: Long,
    val expectedLocalTimeMinutes: Int,
    val expectedAtUtcMs: Long,
    val timezoneId: String,
    val partnerId: String,
    val categoryId: String,
    val categoryAssignmentMode: CategoryAssignmentMode,
    val direction: LedgerDirection,
    val expectedAmountScaled100: Long?,
    val amountPolicy: RecurrenceAmountPolicy,
    val note: String?,
    val triggerKind: RecurrenceTriggerKind,
    val status: RecurrenceOccurrenceStatus,
    val realizationKind: RecurrenceRealizationKind?,
    val resolvedAtUtcMs: Long?,
)

data class FluviRecurrenceDashboardSnapshot(
    val rules: List<FluviRecurrenceRule>,
    val pendingCount: Long,
    val dueCount: Long,
    val realizedCount: Long,
    val showPendingGhostsInLedger: Boolean,
)

/**
 * A banki push késői bizonyíték lehet egy időtriggerrel már könyvelt
 * occurrence-hez.  A `amountMatchesExpected` külön jelzi azokat az eseteket,
 * amelyeknél nem szabad a már könyvelt pénzügyi adatot automatikusan felülírni.
 */
data class FluviTimeRecurrenceEvidence(
    val entryId: String,
    val amountMatchesExpected: Boolean,
)

data class CreateRecurrenceRuleCommand(
    val name: String,
    val partnerId: String,
    val categorySelection: LedgerCategorySelection,
    val direction: LedgerDirection,
    val note: String?,
    val triggerKind: RecurrenceTriggerKind,
    val amountPolicy: RecurrenceAmountPolicy,
    val amountScaled100: Long?,
    val dayOfMonth: Int,
    val localTimeMinutes: Int,
    val startLocalEpochDay: Long,
    val endLocalEpochDay: Long?,
    val timezoneId: String,
    val pushProfileId: String? = null,
    val pushRuleId: String? = null,
    val amountToleranceScaled100: Long = 0L,
    val dayWindow: Int = 2,
)

data class UpdateOccurrenceOverrideCommand(
    val occurrenceId: String,
    val expectedAmountScaled100: Long? = null,
    val expectedLocalEpochDay: Long? = null,
    val expectedLocalTimeMinutes: Int? = null,
    val partnerId: String? = null,
    val categorySelection: LedgerCategorySelection? = null,
    /** Allows an intentional empty note to clear a previous override. */
    val noteChanged: Boolean = false,
    val note: String? = null,
)

data class CreateRecurringLedgerEntryCommand(
    val occurrenceId: String,
    val partnerId: String,
    val categorySelection: LedgerCategorySelection,
    val note: String?,
    val direction: LedgerDirection,
    val amountScaled100: Long,
    val bookedLocalEpochDay: Long,
    val bookedLocalTimeMinutes: Int,
    val occurredAtUtcMs: Long,
    val originKind: LedgerOriginKind,
    val notificationInboxId: String? = null,
)
