package com.fluvi.app.lockscreen.host

/**
 * Enrollment does not grant a frame. This first integration admits only the
 * verifiably first service on a fresh reference install, while unlocked and
 * before any local output or reservation exists. All uncertain handovers stay
 * on the old path; an already suppressed owner never becomes stock on failure.
 */
internal class R38ReferenceAdmission(private val owner: R29Ownership) {
    data class Evidence(
        val trustedHost: Boolean,
        val firstServiceOnFreshInstall: Boolean,
        val unlocked: Boolean,
        val noLocalPresentation: Boolean,
        val noReservation: Boolean,
        val noOwnedOutput: Boolean,
    )

    fun begin(evidence: Evidence, stillEmpty: () -> Boolean = { true }): Long? {
        if (!evidence.trustedHost || !evidence.firstServiceOnFreshInstall || !evidence.unlocked ||
            !evidence.noLocalPresentation || !evidence.noReservation || !evidence.noOwnedOutput) return null
        // Durable suppression is committed before the host can be requested.
        val epoch = owner.beginEnrollment() ?: return null
        // A wake or competing output may have appeared while preferences were
        // committed. Such a race is not evidence of drain.
        if (!stillEmpty()) return null
        // The exact evidence means there was no previous borrower to wait for.
        // A failed transition remains durably suppressed rather than guessing.
        return epoch.takeIf { owner.oldOwnerDrained(it) }
    }
}
