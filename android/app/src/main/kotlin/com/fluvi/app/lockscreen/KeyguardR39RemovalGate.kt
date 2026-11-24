package com.fluvi.app.lockscreen

import android.view.accessibility.AccessibilityEvent

/** Scalar provenance from one complete, uniquely attributable MAIN read. */
internal data class KeyguardR39WindowEvidence(
    val windowId: Int,
    val displayId: Int,
    val appUid: Int,
    val requestId: Long,
    val sceneSerial: Long,
    val readFinishedAt: Long,
)

/**
 * Optional negative-only edge. The same queue lock owns the witness and the
 * presentation coordinator, so an event cannot seal a replacement owner.
 * No View, Binder, node traversal, renderer operation, or callback runs here.
 */
internal class KeyguardR39RemovalGate(
    private val lock: Any,
    private val coordinator: KeyguardOrbPresentationCoordinator,
) {
    private data class Witness(
        val evidence: KeyguardR39WindowEvidence,
        val reveal: KeyguardOrbPresentationCoordinator.Reveal,
        val authority: KeyguardInspectionAuthority,
        val notBefore: Long,
    )
    private var witness: Witness? = null // lock

    /** Called only after this exact native apply returns, before its Main ACK. */
    fun arm(evidence: KeyguardR39WindowEvidence, reveal: KeyguardOrbPresentationCoordinator.Reveal,
            authority: KeyguardInspectionAuthority, scene: Long, appUid: Int, grantAt: Long): Boolean = synchronized(lock) {
        if (evidence.requestId != reveal.proofRequestId || grantAt < evidence.readFinishedAt ||
            !eligible(evidence, reveal, authority, scene, appUid, grantAt) ||
            !coordinator.isAppliedPending(reveal.reservation, reveal.host, reveal.output)) return@synchronized false
        witness = Witness(evidence, reveal, authority, maxOf(evidence.readFinishedAt, grantAt))
        true
    }

    /** A later complete current read can replace an invalidated witness on the
     * same already-presented generation. It never grants another reveal. */
    fun armPresented(evidence: KeyguardR39WindowEvidence, reveal: KeyguardOrbPresentationCoordinator.Reveal,
                     authority: KeyguardInspectionAuthority, scene: Long, appUid: Int, grantAt: Long): Boolean = synchronized(lock) {
        val state = coordinator.snapshot()
        if (!eligible(evidence, reveal, authority, scene, appUid, grantAt) ||
            state.reservation !== reveal.reservation || state.grant != KeyguardOrbPresentationCoordinator.Grant.PRESENTED ||
            !coordinator.mayAct(reveal.reservation, reveal.host)) return@synchronized false
        witness = Witness(evidence, reveal, authority, maxOf(evidence.readFinishedAt, grantAt))
        true
    }

    private fun eligible(e: KeyguardR39WindowEvidence, reveal: KeyguardOrbPresentationCoordinator.Reveal,
                         authority: KeyguardInspectionAuthority, scene: Long, uid: Int, grantAt: Long): Boolean =
        e.windowId >= 0 && e.displayId == reveal.reservation.stamp.displayId && e.appUid == uid && uid > 0 &&
            e.requestId > 0 && e.sceneSerial == scene && e.readFinishedAt > 0 && grantAt > 0 &&
            authority == reveal.authority && coordinator.snapshot().reservation === reveal.reservation

    /** Only genuine, later framework removal of the exact witnessed window can
     * revoke. Equal uptime ticks have unknown order and deliberately fall back. */
    fun remove(event: KeyguardAccessibilityEventMeta, callbackAt: Long, frameworkEvent: Boolean, own: Boolean,
               current: KeyguardOrbPresentationCoordinator.Reservation?, authority: KeyguardInspectionAuthority,
               appUid: Int): KeyguardOrbPresentationCoordinator.Withdrawal? = synchronized(lock) {
        val w = witness ?: return@synchronized null
        val eventAt = event.eventTimeUptimeMs ?: return@synchronized null
        if (!frameworkEvent || own || event.eventType != AccessibilityEvent.TYPE_WINDOWS_CHANGED ||
            event.windowChanges and AccessibilityEvent.WINDOWS_CHANGE_REMOVED == 0 ||
            event.windowId != w.evidence.windowId || event.displayId != w.evidence.displayId ||
            appUid != w.evidence.appUid || current !== w.reveal.reservation || authority != w.authority ||
            eventAt <= w.notBefore || eventAt > callbackAt) return@synchronized null
        val withdrawal = coordinator.seal(w.reveal.reservation, authority, Long.MAX_VALUE, true)
            ?: return@synchronized null
        witness = null
        withdrawal
    }

    fun clear() = synchronized(lock) { witness = null }
    fun clearFor(token: KeyguardOrbPresentationCoordinator.Reservation) = synchronized(lock) {
        if (witness?.reveal?.reservation === token) witness = null
    }
}
