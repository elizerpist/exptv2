package com.fluvi.app.lockscreen

/** Pure final gate for a completed Binder inspection. A stale inspection is
 * discarded, never converted into a destructive window operation. */
internal enum class KeyguardInspectionAction { DROP_STALE, HIDE_CURRENT_GATE, APPLY }

internal object KeyguardCardInspectionGate {
    fun decide(
        expectedSession: Long,
        currentSession: Long,
        expectedEpoch: Long,
        currentEpoch: Long,
        displayEligibleNow: Boolean,
        keyguardLockedNow: Boolean,
        expectedInteractionEpoch: Long = 0L,
        currentInteractionEpoch: Long = 0L,
        expectedAttachGeneration: Long = 0L,
        currentAttachGeneration: Long = 0L,
    ): KeyguardInspectionAction = when {
        expectedSession != currentSession ||
            expectedEpoch != currentEpoch ||
            expectedInteractionEpoch != currentInteractionEpoch ||
            expectedAttachGeneration != currentAttachGeneration -> KeyguardInspectionAction.DROP_STALE
        !displayEligibleNow || !keyguardLockedNow -> KeyguardInspectionAction.HIDE_CURRENT_GATE
        else -> KeyguardInspectionAction.APPLY
    }
}
