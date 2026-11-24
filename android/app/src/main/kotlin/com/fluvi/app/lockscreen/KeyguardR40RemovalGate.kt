package com.fluvi.app.lockscreen

import android.view.accessibility.AccessibilityEvent

/** Bounded scalar evidence from a distinct, complete post-ACK physical read. */
internal data class KeyguardR40WindowEvidence(
    val windowId: Int,
    val displayId: Int,
    val appUid: Int,
    val requestId: Long,
    val sceneSerial: Long,
    val readStartedAt: Long,
    val readFinishedAt: Long,
)

/** Negative-only optional withdrawal. All ownership and sealing are serialized
 * with the presentation coordinator. A missing witness never grants display. */
internal class KeyguardR40RemovalGate(
    private val lock: Any,
    private val coordinator: KeyguardOrbPresentationCoordinator,
) {
    private data class Witness(val evidence: KeyguardR40WindowEvidence,
                               val reveal: KeyguardOrbPresentationCoordinator.Reveal,
                               val authority: KeyguardInspectionAuthority)
    private var witness: Witness? = null // lock
    @Volatile var hasWitness: Boolean = false
        private set

    fun armPresented(evidence: KeyguardR40WindowEvidence, reveal: KeyguardOrbPresentationCoordinator.Reveal,
                     authority: KeyguardInspectionAuthority, scene: Long, appUid: Int): Boolean = synchronized(lock) {
        val state = coordinator.snapshot()
        if (evidence.windowId < 0 || evidence.displayId != reveal.reservation.stamp.displayId ||
            evidence.appUid != appUid || appUid <= 0 || evidence.requestId <= 0 ||
            evidence.sceneSerial != scene || evidence.readStartedAt <= 0 ||
            evidence.readFinishedAt < evidence.readStartedAt || authority != reveal.authority ||
            state.reservation !== reveal.reservation || state.grant != KeyguardOrbPresentationCoordinator.Grant.PRESENTED ||
            coordinator.revealOrdinal(reveal) == null || !coordinator.mayAct(reveal.reservation, reveal.host))
            return@synchronized false
        witness = Witness(evidence, reveal, authority)
        hasWitness = true
        true
    }

    fun remove(event: KeyguardAccessibilityEventMeta, callbackAt: Long, frameworkEvent: Boolean, own: Boolean,
               current: KeyguardOrbPresentationCoordinator.Reservation?, authority: KeyguardInspectionAuthority,
               appUid: Int): KeyguardOrbPresentationCoordinator.Withdrawal? = synchronized(lock) {
        val w = witness ?: return@synchronized null
        val at = event.eventTimeUptimeMs ?: return@synchronized null
        if (!frameworkEvent || own || event.eventType != AccessibilityEvent.TYPE_WINDOWS_CHANGED ||
            event.windowChanges and AccessibilityEvent.WINDOWS_CHANGE_REMOVED == 0 ||
            event.windowId != w.evidence.windowId || event.displayId != w.evidence.displayId ||
            appUid != w.evidence.appUid || current !== w.reveal.reservation || authority != w.authority ||
            at <= w.evidence.readFinishedAt || at > callbackAt) return@synchronized null
        val withdrawal = coordinator.seal(w.reveal.reservation, authority, Long.MAX_VALUE, true)
            ?: return@synchronized null
        witness = null
        hasWitness = false
        withdrawal
    }

    fun clear() = synchronized(lock) { witness = null; hasWitness = false }
    fun clearFor(token: KeyguardOrbPresentationCoordinator.Reservation) = synchronized(lock) {
        if (witness?.reveal?.reservation === token) { witness = null; hasWitness = false }
    }
}

/** Runs only when a physical read started after the exact owner's ACK. It
 * accumulates scalar markers while the existing tree walk is already active. */
internal class KeyguardR40ClockProvenance {
    private var mainSources = 0
    private var candidate = -1
    private var windowId = -1
    private var eligible = false
    private var main = false
    private var clock = false

    fun beginWindow(id: Int, display: Int, pkg: String?, type: Int, verifiedRoot: Boolean) {
        windowId = id
        eligible = id >= 0 && display == 0 && pkg == "com.android.systemui" &&
            type == 3 /* AccessibilityWindowInfo.TYPE_SYSTEM */ && verifiedRoot
        main = false
        clock = false
    }

    fun marker(id: String) {
        if (KeyguardSurfaceClassifier.isMainMarker(id)) main = true
        if (KeyguardSurfaceClassifier.isClockMarker(id)) clock = true
    }

    fun endWindow() {
        if (main) {
            mainSources++
            if (eligible && clock) candidate = windowId
        }
    }

    var clockWindowId: Int? = null
        private set

    fun result(uniqueWindow: (Int) -> Boolean): Int? =
        candidate.takeIf { mainSources == 1 && it >= 0 && uniqueWindow(it) }

    fun finish(uniqueWindow: (Int) -> Boolean) { clockWindowId = result(uniqueWindow) }
}
