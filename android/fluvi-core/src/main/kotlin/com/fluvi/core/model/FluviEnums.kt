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
