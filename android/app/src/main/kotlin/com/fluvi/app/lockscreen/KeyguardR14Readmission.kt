package com.fluvi.app.lockscreen

internal enum class KeyguardR14Origin { SYSTEM_UI, OWN, AMBIGUOUS, OTHER }

internal object KeyguardR14IngressClassifier {
    fun classify(meta: KeyguardAccessibilityEventMeta, own: Boolean): KeyguardR14Origin = when {
        own -> KeyguardR14Origin.OWN
        meta.packageName == "com.android.systemui" && meta.windowId >= 0 && meta.displayId == 0 &&
            (meta.eventType == 32 || meta.eventType == 4_194_304) -> KeyguardR14Origin.SYSTEM_UI
        meta.packageName.isNullOrBlank() || meta.packageName == "com.android.systemui" -> KeyguardR14Origin.AMBIGUOUS
        else -> KeyguardR14Origin.OTHER
    }
}

/** A scalar copy of one original framework ingress. Reacquisition retains the
 * original id and times; synthetic queue work never receives this identity. */
internal data class KeyguardR14Ingress(
    val id: Long,
    val externalSystemUi: Boolean,
    val windowId: Int,
    val displayId: Int,
    val eventType: Int,
    val eventAt: Long?,
    val callbackAt: Long,
    val origin: KeyguardR14Origin = if (externalSystemUi) KeyguardR14Origin.SYSTEM_UI else KeyguardR14Origin.AMBIGUOUS,
)

/** Main owns exactly one of these after a real successful withdrawal. */
internal data class KeyguardR14Recovery(
    val id: Long,
    val authority: KeyguardInspectionAuthority,
    val settingsGeneration: Long,
    val layoutRevision: Long,
    val focusGeneration: Long,
    val full: Boolean,
    val previousFull: Boolean,
    val hideOperationId: Long?,
    val previousAttachment: Long,
    val diagnosticContext: KeyguardDiagnosticContext? = null,
    val used: Boolean = false,
    val deferredRequestId: Long? = null,
    val pendingRequestId: Long? = null,
    val replacements: Int = 0,
    val successorRecorded: Boolean = false,
)

internal object KeyguardR14ReadmissionPolicy {
    /** The caller supplies only the unstarted pending slot, never active or
     * reserved work. All timestamps are original SystemClock.uptimeMillis. */
    fun shouldDefer(
        recovery: KeyguardR14Recovery?, authority: KeyguardInspectionAuthority,
        settings: KeyguardCardSettings, eligibleRoute: Boolean, attached: Boolean,
        state: KeyguardSurfacePresentationState, completeMain: Boolean,
        proposed: KeyguardCardVisibility, request: KeyguardCardInspectionRequest,
        readStartedAt: Long, decisionAt: Long, pending: KeyguardCardInspectionRequest?,
    ): Boolean {
        if (recovery == null || recovery.used || attached || !eligibleRoute || !completeMain || !settings.requested ||
            state != KeyguardSurfacePresentationState.WITHDRAWN_AWAITING_SURFACE ||
            (proposed != KeyguardCardVisibility.SHOW_FULL && proposed != KeyguardCardVisibility.SHOW_DISCREET) ||
            recovery.authority != authority || !authority.matches(request) ||
            recovery.settingsGeneration != settings.generation || recovery.layoutRevision != settings.layoutRevision ||
            recovery.focusGeneration != settings.focus.generation || recovery.full != settings.showFinancialDetails ||
            recovery.previousFull != (proposed == KeyguardCardVisibility.SHOW_FULL) ||
            settings.presentationMode != KeyguardCardPresentationMode.ORB ||
            settings.animationMode != KeyguardCardAnimationMode.ORB_ONLY) return false
        val next = pending ?: return false
        val event = next.r14Ingress ?: return false
        val eventAt = event.eventAt ?: return false
        return next.id != request.id && authority.matches(next) && event.externalSystemUi && event.origin == KeyguardR14Origin.SYSTEM_UI &&
            event.windowId >= 0 && event.displayId == 0 && event.id > 0 &&
            (event.eventType == 32 || event.eventType == 4_194_304) &&
            event.id != request.r14Ingress?.id && next.trigger == "window" &&
            next.eventTimeUptimeMs == eventAt && next.triggerReceivedUptimeMs == event.callbackAt &&
            // Millisecond equality cannot prove the event followed the read.
            eventAt > 0 && eventAt <= event.callbackAt && eventAt > readStartedAt &&
            event.callbackAt > readStartedAt && event.callbackAt <= decisionAt &&
            next.queuedAtUptimeMs <= decisionAt
    }
}
