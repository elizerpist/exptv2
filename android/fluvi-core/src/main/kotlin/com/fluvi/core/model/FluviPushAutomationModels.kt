package com.fluvi.core.model

data class FluviPushProfile(
    val profileId: String,
    val packageName: String,
    val appLabel: String,
    val displayName: String,
    val defaultDirection: PushTransactionDirection,
    val state: PushProfileState,
    val ruleCount: Int,
    val inboxCount: Long,
    val revision: Long,
)

data class FluviPushRule(
    val ruleId: String,
    val profileId: String,
    val name: String,
    val direction: LedgerDirection,
    val state: PushRuleState,
    val version: Int,
    val priority: Int,
    val autoAcceptThreshold: Double,
)

data class FluviNotificationInboxItem(
    val notificationId: String,
    val profileId: String?,
    val sourcePackageName: String?,
    val sourceAppLabel: String?,
    val title: String?,
    val rawText: String,
    val receivedAtUtcMs: Long,
    val parseStatus: NotificationParseStatus,
    val processingStatus: NotificationProcessingStatus,
    val trainingStatus: NotificationTrainingStatus,
    val reviewStatus: PushReviewStatus,
    val confidence: Double?,
    val suggestedPayloadJson: String?,
    val diagnosticsJson: String?,
    val ledgerEntryId: String?,
)

data class FluviPushDashboardSnapshot(
    val profiles: List<FluviPushProfile>,
    val pendingReviewCount: Long,
    val capturedLast30Days: Long,
    val recentInbox: List<FluviNotificationInboxItem>,
)

data class CreatePushProfileCommand(
    val packageName: String,
    val appLabel: String,
    val displayName: String,
    val defaultDirection: PushTransactionDirection,
    val monitoringRequested: Boolean,
    val notificationAccessGranted: Boolean,
)

data class UpdatePushProfileCommand(
    val profileId: String,
    val displayName: String,
    val defaultDirection: PushTransactionDirection,
    val state: PushProfileState,
)

data class PushFieldSpan(
    val start: Int,
    val endExclusive: Int,
    val role: PushFieldRole,
)

data class CreatePushRuleCommand(
    val profileId: String,
    val notificationId: String,
    val name: String,
    val direction: LedgerDirection,
    val spans: List<PushFieldSpan>,
    val priority: Int = 100,
    val autoAcceptThreshold: Double = 0.90,
)

data class CapturedPushNotification(
    val packageName: String,
    val appLabel: String?,
    val title: String?,
    val text: String,
    val notificationKey: String?,
    val receivedAtUtcMs: Long,
)

sealed interface FluviPushCaptureResult {
    data object IgnoredSource : FluviPushCaptureResult
    data object Paused : FluviPushCaptureResult
    data class Duplicate(val notificationId: String) : FluviPushCaptureResult
    data class Stored(val notificationId: String) : FluviPushCaptureResult
    data class ReviewRequired(val notificationId: String) : FluviPushCaptureResult
    data class Booked(val notificationId: String, val ledgerEntryId: String) : FluviPushCaptureResult
}

data class PushRuleTestReport(
    val ruleId: String,
    val matchedCount: Int,
    val reviewCount: Int,
    val rejectedCount: Int,
    val conflictedCount: Int,
    val activationReady: Boolean,
)

data class ApprovePushReviewCommand(
    val notificationId: String,
    val merchantName: String,
    val direction: LedgerDirection,
    val amountScaled100: Long,
    val bookedLocalEpochDay: Long,
    val bookedLocalTimeMinutes: Int,
    val occurredAtUtcMs: Long,
    val note: String? = null,
    /** A user may retain the correction as a future parser-training sample. */
    val trainingCorrectionJson: String? = null,
)
