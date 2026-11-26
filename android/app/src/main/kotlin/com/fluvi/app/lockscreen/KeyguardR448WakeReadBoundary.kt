package com.fluvi.app.lockscreen

/** Scheduling only: a matching read is never itself permission to show. */
internal object KeyguardR448WakeReadBoundary {
    data class Work(val id: Long, val currentAuthority: Boolean, val sameCapture: Boolean) {
        val suitable get() = currentAuthority && sameCapture
    }

    enum class Decision { OFFER, CURRENT_PENDING, ACTIVE_NOT_STARTED, ACTIVE_AFTER_BOUNDARY }

    /** Called under the inspection queue lock at the actual offer boundary.
     * A pending read cannot have started while the serial reader is occupied. */
    fun decide(active: Work?, pending: Work?, startedId: Long?, startedForArm: Boolean): Decision {
        if (pending?.suitable == true) return Decision.CURRENT_PENDING
        if (active?.suitable == true) {
            if (startedId != active.id) return Decision.ACTIVE_NOT_STARTED
            if (startedForArm) return Decision.ACTIVE_AFTER_BOUNDARY
        }
        return Decision.OFFER
    }
}
