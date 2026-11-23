package com.fluvi.app.lockscreen

/** Eligibility for overlapping one physical successor read with ordered,
 * restriction-only disposal. This value is never a visibility grant. */
internal object KeyguardR32OverlapPolicy {
    data class Facts(
        val first: KeyguardCardInspectionRequest,
        val successor: KeyguardCardInspectionRequest,
        val authority: KeyguardInspectionAuthority,
        val actualActive: KeyguardCardInspectionRequest?,
        val actualPending: KeyguardCardInspectionRequest?,
        val noPreceding: Boolean,
        val genuineFrameworkIngress: Boolean,
        val ingressDisplay: Int?,
        val ingressOrigin: KeyguardR14Origin?,
        val detached: Boolean,
        val noShowInProgress: Boolean,
        val direct: Boolean,
        val emptyAwaitingDisclosure: Boolean,
        val reservationCurrent: Boolean,
        val routeCurrent: Boolean,
        val hostSafe: Boolean,
        val grantNone: Boolean,
        val noPaintOrProof: Boolean,
        val noRecovery: Boolean,
        val noQueuedPublication: Boolean,
        val freshnessEstablished: Boolean,
        val firstFreshnessRevision: Long?,
        val currentFreshnessRevision: Long,
        val completeFullMain: Boolean,
        val systemEligible: Boolean,
        val ownUnambiguous: Boolean,
        val readScene: Long?,
        val currentScene: Long,
    )

    fun rejection(facts: Facts): String? {
        if (!facts.noPreceding || facts.actualActive != facts.first || facts.actualPending != facts.successor ||
            facts.successor.id <= facts.first.id || !facts.authority.matches(facts.first) ||
            !facts.authority.matches(facts.successor)) return "queueOrAuthority"
        if (!facts.genuineFrameworkIngress || facts.ingressDisplay != 0 ||
            (facts.ingressOrigin != KeyguardR14Origin.SYSTEM_UI && facts.ingressOrigin != KeyguardR14Origin.AMBIGUOUS)) return "ingress"
        if (!facts.detached || !facts.noShowInProgress || !facts.direct || !facts.emptyAwaitingDisclosure ||
            !facts.reservationCurrent || !facts.routeCurrent || !facts.hostSafe || !facts.grantNone ||
            !facts.noPaintOrProof || !facts.noRecovery || !facts.noQueuedPublication) return "owner"
        if (!facts.freshnessEstablished || facts.firstFreshnessRevision == null ||
            facts.firstFreshnessRevision != facts.currentFreshnessRevision ||
            facts.successor.windowFreshness.requiresCacheClear) return "freshness"
        if (!facts.completeFullMain || !facts.systemEligible || !facts.ownUnambiguous) return "inspection"
        if (facts.readScene == null || facts.readScene >= facts.currentScene) return "scene"
        return null
    }
}
