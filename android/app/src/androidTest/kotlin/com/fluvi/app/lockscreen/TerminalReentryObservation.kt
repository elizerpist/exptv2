package com.fluvi.app.lockscreen

/**
 * Test-only, immutable record of one terminal-fixture observation.
 *
 * This is deliberately an accepted observation, rather than an assertion that
 * Android will remain unlocked after it was sampled. The independent episode
 * which follows it still establishes a fresh locked admission and current
 * attachment/output of its own.
 */
internal data class TerminalReentryObservation(
    val observationId: Long,
    val startedAtUptimeMs: Long,
    val localObservedAtUptimeMs: Long,
    val remoteObservedAtUptimeMs: Long,
    val finishedAtUptimeMs: Long,
    val terminalDeadlineUptimeMs: Long,
    val keyguardLockedBefore: Boolean,
    val keyguardLockedAfter: Boolean,
    val serviceAttached: Boolean,
    val processOverlayRootCount: Int,
    val remoteOverlayIds: List<Int>,
) {
    /** Uses only captured fields. It never reads a clock, KeyguardManager, or
     * window state after the observation completed. */
    val accepted: Boolean
        get() = !keyguardLockedBefore &&
            !keyguardLockedAfter &&
            !serviceAttached &&
            processOverlayRootCount == 0 &&
            finishedAtUptimeMs <= terminalDeadlineUptimeMs

    val rejectionReason: String
        get() = when {
            keyguardLockedBefore -> "keyguardLockedBefore"
            keyguardLockedAfter -> "keyguardLockedAfter"
            serviceAttached -> "serviceAttached"
            processOverlayRootCount != 0 -> "processOverlayRootCount=$processOverlayRootCount"
            finishedAtUptimeMs > terminalDeadlineUptimeMs -> "finishedAfterDeadline"
            else -> "accepted"
        }

    fun evidenceFields(): String =
        "observationId=$observationId startedAtUptimeMs=$startedAtUptimeMs " +
            "localObservedAtUptimeMs=$localObservedAtUptimeMs " +
            "remoteObservedAtUptimeMs=$remoteObservedAtUptimeMs " +
            "finishedAtUptimeMs=$finishedAtUptimeMs terminalDeadlineUptimeMs=$terminalDeadlineUptimeMs " +
            "keyguardLockedBefore=$keyguardLockedBefore keyguardLockedAfter=$keyguardLockedAfter " +
            "serviceAttached=$serviceAttached processOverlayRootCount=$processOverlayRootCount " +
            "remoteOverlayIds=$remoteOverlayIds accepted=$accepted reason=$rejectionReason"
}

/** Main-owned local state, captured in exactly one runOnMainSync block by the
 * real-service fixture. */
internal data class TerminalReentryLocalObservation(
    val observedAtUptimeMs: Long,
    val serviceAttached: Boolean,
    val processOverlayRootCount: Int,
)

/** Remote UiAutomation metadata is retained for evidence but is not part of
 * this narrow local terminal-setup predicate. */
internal data class TerminalReentryRemoteObservation(
    val observedAtUptimeMs: Long,
    val overlayIds: List<Int>,
)

/**
 * Keeps the two KeyguardManager reads on the instrumentation thread around
 * the Main-owned local-root read. Remote metadata is sampled afterwards and
 * its own timestamp prevents it from being misrepresented as part of an
 * atomic platform snapshot.
 */
internal class TerminalReentryObservationCollector(
    private val uptimeMillis: () -> Long,
    private val keyguardLocked: () -> Boolean,
    private val localObservation: () -> TerminalReentryLocalObservation,
    private val remoteObservation: () -> TerminalReentryRemoteObservation,
) {
    fun collect(
        observationId: Long,
        terminalDeadlineUptimeMs: Long,
    ): TerminalReentryObservation {
        val startedAtUptimeMs = uptimeMillis()
        val keyguardLockedBefore = keyguardLocked()
        val local = localObservation()
        val keyguardLockedAfter = keyguardLocked()
        val remote = remoteObservation()
        val finishedAtUptimeMs = uptimeMillis()
        return TerminalReentryObservation(
            observationId = observationId,
            startedAtUptimeMs = startedAtUptimeMs,
            localObservedAtUptimeMs = local.observedAtUptimeMs,
            remoteObservedAtUptimeMs = remote.observedAtUptimeMs,
            finishedAtUptimeMs = finishedAtUptimeMs,
            terminalDeadlineUptimeMs = terminalDeadlineUptimeMs,
            keyguardLockedBefore = keyguardLockedBefore,
            keyguardLockedAfter = keyguardLockedAfter,
            serviceAttached = local.serviceAttached,
            processOverlayRootCount = local.processOverlayRootCount,
            remoteOverlayIds = remote.overlayIds.toList(),
        )
    }
}
