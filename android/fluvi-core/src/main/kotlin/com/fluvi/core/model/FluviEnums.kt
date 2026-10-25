package com.fluvi.core.model

enum class LedgerDirection {
    income,
    expense,
}

enum class LedgerOriginKind {
    manual,
    push,
    recurring,
}

enum class CategoryAssignmentMode {
    partnerDefault,
    entryOverride,
}

enum class RecurrenceTriggerKind {
    time,
    push,
}

enum class RecurrenceAmountPolicy {
    fixed,
}

enum class NotificationParseStatus {
    unclassified,
    recognized,
    invalid,
}

enum class NotificationProcessingStatus {
    unprocessed,
    transaction_created,
    ignored,
    duplicate,
}

enum class NotificationTrainingStatus {
    unused,
    selected,
    incorporated,
}

/** Lifecycle is deliberately independent from the Android listener permission. */
enum class PushProfileState {
    waitingForPermission,
    waitingForTraining,
    testing,
    active,
    reviewRequired,
    paused,
}

enum class PushTransactionDirection {
    automatic,
    expenseOnly,
    incomeOnly,
}

enum class PushRuleState {
    draft,
    testing,
    active,
    paused,
    failed,
}

enum class PushSampleKind {
    transaction,
    nonTransaction,
    failedTransaction,
    ignored,
}

enum class PushFieldRole {
    amount,
    merchant,
    balance,
    account,
    currency,
    ignore,
}

enum class PushReviewStatus {
    none,
    pending,
    approved,
    ignored,
    rejected,
}

enum class QueryPeriodKind {
    month,
    year,
    day,
}

enum class QueryRefinementKind {
    minimumAmount,
    maximumAmount,
    noteContains,
}

enum class LedgerSyncOperation {
    upsert,
    delete,
}

enum class CheckpointKind {
    daily,
    beforeDestructive,
    manual,
    beforeRestore,
    beforeSchemaUpgrade,
}

enum class CheckpointRetentionClass {
    automaticDaily,
    automaticMonthly,
    manual,
}

enum class CheckpointStatus {
    prepared,
    uploading,
    acknowledged,
    failed,
}
