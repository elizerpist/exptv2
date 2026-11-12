package com.fluvi.app.lockscreen

import android.view.Display

/** Test-only fixed admission budget. Deadlines are absolute and never restart. */
internal data class IndependentSleepAdmissionBudget(
    val startedAtUptimeMs: Long,
    val globalDeadlineUptimeMs: Long,
) {
    val nonInteractiveDeadlineUptimeMs = minOf(globalDeadlineUptimeMs, startedAtUptimeMs + 3_000L)
    val admissionDeadlineUptimeMs = minOf(globalDeadlineUptimeMs, startedAtUptimeMs + 6_000L)
}

/** Immutable public-platform bracket for one synchronized sleep admission. */
internal data class IndependentSleepAdmissionObservation(
    val episodeId: Long,
    val observationId: Long,
    val startedAtUptimeMs: Long,
    val finishedAtUptimeMs: Long,
    val admissionDeadlineUptimeMs: Long,
    val interactiveBefore: Boolean,
    val displayStateBefore: Int,
    val keyguardLockedBefore: Boolean,
    val keyguardLockedAfter: Boolean,
    val displayStateAfter: Int,
    val interactiveAfter: Boolean,
) {
    val accepted: Boolean get() = !interactiveBefore && !interactiveAfter &&
        displayStateBefore == Display.STATE_OFF && displayStateAfter == Display.STATE_OFF &&
        keyguardLockedBefore && keyguardLockedAfter && finishedAtUptimeMs <= admissionDeadlineUptimeMs
    val rejectionReason: String get() = when {
        interactiveBefore || interactiveAfter -> "interactive"
        displayStateBefore != Display.STATE_OFF || displayStateAfter != Display.STATE_OFF -> "displayNotOff"
        !keyguardLockedBefore || !keyguardLockedAfter -> "keyguardNotLocked"
        finishedAtUptimeMs > admissionDeadlineUptimeMs -> "finishedAfterDeadline"
        else -> "accepted"
    }
    fun evidenceFields() = "episodeId=$episodeId observationId=$observationId startedAtUptimeMs=$startedAtUptimeMs finishedAtUptimeMs=$finishedAtUptimeMs admissionDeadlineUptimeMs=$admissionDeadlineUptimeMs interactiveBefore=$interactiveBefore displayStateBefore=$displayStateBefore keyguardLockedBefore=$keyguardLockedBefore keyguardLockedAfter=$keyguardLockedAfter displayStateAfter=$displayStateAfter interactiveAfter=$interactiveAfter accepted=$accepted reason=$rejectionReason"
}

internal class IndependentSleepAdmissionCollector(
    private val uptimeMillis: () -> Long,
    private val interactive: () -> Boolean,
    private val displayState: () -> Int,
    private val keyguardLocked: () -> Boolean,
) {
    fun collect(episodeId: Long, observationId: Long, deadline: Long): IndependentSleepAdmissionObservation {
        val start = uptimeMillis()
        val interactiveBefore = interactive()
        val displayBefore = displayState()
        val lockedBefore = keyguardLocked()
        val lockedAfter = keyguardLocked()
        val displayAfter = displayState()
        val interactiveAfter = interactive()
        return IndependentSleepAdmissionObservation(episodeId, observationId, start, uptimeMillis(), deadline,
            interactiveBefore, displayBefore, lockedBefore, lockedAfter, displayAfter, interactiveAfter)
    }
}
