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

/**
 * Waits for the first completed non-interactive public read.  The read that
 * observes false is accepted only when its completion remains inside the
 * caller's fixed deadline; this deliberately does not alter the shared
 * fixture await helper used by other production assertions.
 */
internal fun awaitIndependentSleepNonInteractive(
    deadlineUptimeMs: Long,
    uptimeMillis: () -> Long,
    interactive: () -> Boolean,
    pauseMillis: (Long) -> Unit,
): Long? {
    while (uptimeMillis() < deadlineUptimeMs) {
        val isInteractive = interactive()
        val finishedAt = uptimeMillis()
        if (!isInteractive && finishedAt <= deadlineUptimeMs) return finishedAt
        val remaining = deadlineUptimeMs - finishedAt
        if (remaining <= 0L) break
        pauseMillis(minOf(100L, remaining))
    }
    return null
}

/** Bounded setup evidence; values are immutable observations, never authority. */
internal class IndependentSleepAdmissionRetention {
    private val retained = mutableListOf<IndependentSleepAdmissionObservation>()
    private var lastState: String? = null
    var totalCompleted: Int = 0
        private set

    fun retain(observation: IndependentSleepAdmissionObservation) {
        totalCompleted += 1
        val state = stateOf(observation)
        if (retained.isEmpty()) {
            retained += observation
            lastState = state
            return
        }

        // Preserve the first plus state transitions while reserving one slot
        // for the latest completed sample.  Additional transitions are counted
        // as omissions instead of silently turning into a success.
        if (state != lastState && retained.size < 7) {
            retained += observation
        }
        if (retained.last().observationId != observation.observationId) {
            if (retained.size < 8) retained += observation else retained[retained.lastIndex] = observation
        }
        lastState = state
    }

    fun observations(): List<IndependentSleepAdmissionObservation> = retained.toList()
    fun omittedCompleted(): Int = totalCompleted - retained.size

    private fun stateOf(observation: IndependentSleepAdmissionObservation) = listOf(
        observation.interactiveBefore,
        observation.displayStateBefore,
        observation.keyguardLockedBefore,
        observation.keyguardLockedAfter,
        observation.displayStateAfter,
        observation.interactiveAfter,
        observation.accepted,
        observation.rejectionReason,
    ).joinToString("|")
}
