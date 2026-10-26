package com.fluvi.core.pulse

/**
 * E-phase deliberately keeps financial state, delivery eligibility, and a
 * concrete header attempt on separate axes. None of these types changes a
 * signal, situation, priority score, or Story draft.
 */
enum class PulseDeliveryEligibility {
    eligible,
    waitingForSurface,
    waitingForInteractionIdle,
    waitingForCooldown,
    snoozed,
    muted,
    alreadyShown,
    dismissed,
    stale,
    notComposable,
    historicalOnly,
    recoveryNotPreviouslyShown,
    headerLayoutNotSupported,
    automaticDisabled,
}

enum class PulseDeliveryAttemptState { reserved, presenting, presented, ended, cancelled, expired }

enum class PulseDeliveryEventKind {
    reserved,
    presentationStarted,
    presented,
    shown,
    ended,
    cancelled,
    expired,
    dismissed,
    snoozed,
    muted,
    unmuted,
    preferencesChanged,
}

enum class PulseDeliveryControlKind { dismissed, snooze, mute, snoozePresentationGrant }

data class PulseDeliverySurfaceContext(
    val appActive: Boolean,
    val ledgerVisible: Boolean,
    val headerVisible: Boolean,
    val unobstructed: Boolean,
    val interactionIdle: Boolean,
    val headerLayoutSupported: Boolean,
    val hostSessionId: String,
    /** The shell reports this only while the header is stable after a gesture. */
    val interactionIdleSinceUtcMs: Long? = null,
)

data class PulseDeliveryPolicy(
    val version: Int = PulseDeliveryPolicyCatalog.version,
    val gestureQuietMillis: Long = 500L,
    val qualifiedExposureMillis: Long = 1_500L,
    val normalCooldownMillis: Long = 10L * 60L * 1_000L,
    val contentTransitionMillis: Long = 420L,
    val baseReadableMillis: Long = 8_000L,
    val maxReadableMillis: Long = 14_000L,
    val reservationLeaseMillis: Long = 15_000L,
)

data class PulseDeliveryPreferences(
    val automaticEnabled: Boolean,
    val normalCooldownMillis: Long,
    val controlRevision: Long,
    val updatedAtUtcMs: Long,
)

data class PulseDeliveryControl(
    val controlId: String,
    val kind: PulseDeliveryControlKind,
    val situationEpisodeId: String?,
    val materialSemanticKey: String?,
    val targetScope: String?,
    val presentationIntentId: String?,
    val expiresAtUtcMs: Long?,
    val consumedAtUtcMs: Long?,
    val createdAtUtcMs: Long,
)

data class PulseDeliveryCandidate(
    val situationKey: String,
    val situationEpisodeId: String,
    val targetScope: String,
    val priorityRank: Int,
    val priorityScore: Int,
    val story: PulseStoryCompositionResult,
    val materialSemanticKey: String?,
    val contentFingerprint: String?,
    val deliveryKey: String?,
    val presentationIntentId: String,
    val eligibility: PulseDeliveryEligibility,
    val reasonCode: String,
    val explanationHu: String,
)

data class PulseDeliveryInputFrame(
    val sourceCoreRevision: Long,
    val sourceTriageFrameId: String,
    val priorityPolicyVersion: Int,
    val storyTemplateVersion: Int,
    val deliveryPolicyVersion: Int,
    val evaluationMode: PulseSignalEvaluationMode,
    val evaluatedAtUtcMs: Long,
    val canonicalTimezone: String,
    val rankedCandidates: List<PulsePriorityCandidate>,
    val userControlRevision: Long,
)

data class PulseDeliveryDecision(
    val input: PulseDeliveryInputFrame,
    val prioritySelectedSituationKey: String?,
    val deliverySelectedSituationKey: String?,
    val deliverySelectionReason: String,
    val candidates: List<PulseDeliveryCandidate>,
)

data class PulseHeaderPresentationReservation(
    val attemptId: String,
    val leaseToken: String,
    val hostSessionId: String,
    val deliveryKey: String,
    val presentationIntentId: String,
    val situationEpisodeId: String,
    val targetScope: String,
    val validUntilUtcMs: Long,
    /** Starts when Flutter confirms the content is fully presented. */
    val readableDurationMillis: Long,
    val story: PulseStoryDraft,
    val sourceFrameId: String,
    val controlRevision: Long,
)

data class PulseDeliveryAttempt(
    val attemptId: String,
    val leaseToken: String,
    val hostSessionId: String,
    val deliveryKey: String,
    val situationKey: String,
    val situationEpisodeId: String,
    val storyKey: String,
    val contentFingerprint: String,
    val materialSemanticKey: String,
    val state: PulseDeliveryAttemptState,
    val validUntilUtcMs: Long,
    val reservedAtUtcMs: Long,
    val startedAtUtcMs: Long?,
    val presentedAtUtcMs: Long?,
    val qualifiedExposureAtUtcMs: Long?,
    val endedAtUtcMs: Long?,
    val endReason: String?,
)

data class PulseDeliveryReceipt(
    val receiptId: String,
    val deliveryKey: String,
    val situationEpisodeId: String,
    val storyKey: String,
    val materialSemanticKey: String,
    val attemptId: String,
    val qualifiedExposureAtUtcMs: Long,
)

data class PulseDeliveryEvent(
    val eventId: String,
    val kind: PulseDeliveryEventKind,
    val attemptId: String?,
    val situationKey: String?,
    val deliveryKey: String?,
    val reasonCode: String,
    val sourceCoreRevision: Long?,
    val transitionSequence: Long,
    val createdAtUtcMs: Long,
)

data class PulseDeliveryInspectionSnapshot(
    val decision: PulseDeliveryDecision,
    val preferences: PulseDeliveryPreferences,
    val controls: List<PulseDeliveryControl>,
    val activeAttempt: PulseDeliveryAttempt?,
    val events: List<PulseDeliveryEvent>,
)
