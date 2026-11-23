package com.fluvi.app.lockscreen

/** Immutable, non-pixel identity for a single prospective ORB lifetime.
 * A stamp is an owner, never a prior permission to display a frame. */
internal data class KeyguardOrbPresentationStamp(
    val authority: KeyguardInspectionAuthority,
    val firstRequestId: Long,
    val selectionRevision: Long,
    val materialRevision: Long,
    val dataRevision: Long,
    val width: Int,
    val height: Int,
    val densityDpi: Int,
    val full: Boolean,
    val hostGeneration: Long,
    val outputGeneration: Long,
    val displayId: Int,
) {
    fun structurallyValid(): Boolean = authority.serviceSession > 0 && authority.wakeGeneration > 0 &&
        firstRequestId > 0 && selectionRevision >= 0 && materialRevision >= 0 && dataRevision >= 0 &&
        width > 0 && height > 0 && densityDpi > 0 && hostGeneration > 0 && outputGeneration > 0 && displayId == 0
}

/** A compact reducer for the queue and the one compositor owner. All public
 * calls are scalar/reference comparisons under the caller-supplied queue lock.
 * No Android call, callback, transaction or wait occurs while this lock is held.
 * Native output disposal remains the responsibility of its real borrower. */
internal class KeyguardOrbPresentationCoordinator(private val lock: Any = Any()) {
    enum class Host { NONE, INERT, READY, INPUT_ARMED, REMOVAL_PENDING, REMOVED }
    enum class Grant { NONE, PENDING, REVEAL_QUEUED, PRESENTED, REVOKED, RETIRED }
    enum class SubmitPhase { NONE, PRE_CROSS, CROSSED, APPLIED, CANCELLED, ACKNOWLEDGED }
    enum class IngressAction { IGNORE, CANCEL_PENDING, KEEP_SUBMITTED }
    data class IngressDecision(val action: IngressAction, val phase: SubmitPhase, val ordinal: Long)
    class Reservation internal constructor(val id: Long, val stamp: KeyguardOrbPresentationStamp,
        val sampleId: Long, val sampleAuthority: KeyguardInspectionAuthority)
    class Reveal internal constructor(val reservation: Reservation, val proofRequestId: Long,
        val authority: KeyguardInspectionAuthority, val output: Any, val host: Any, val sequence: Long)
    class Withdrawal internal constructor(val reservation: Reservation, val output: Any?,
        val host: Any?, val crossedSubmitBoundary: Boolean)
    data class Replacement(val reservation: Reservation, val retiredOutput: Any?)
    data class Snapshot(val reservation: Reservation?, val host: Host, val grant: Grant,
        val adopted: Boolean, val imageReady: Boolean, val proofRequestId: Long?, val activeOutputs: Int)

    private class Entry(val reservation: Reservation) {
        var hostState = Host.NONE
        var grantState = Grant.NONE
        var adopted = false
        var activeAuthority = reservation.stamp.authority
        var host: Any? = null
        var output: Any? = null
        var imageReady = false
        var proofRequestId: Long? = null
        var revealSequence = 0L
        var crossedSubmitBoundary = false
        var submitPhase = SubmitPhase.NONE
        var transitionOrdinal = 0L
    }
    private class OutputSlot(val reservation: Reservation, val output: Any) { var retired = false }
    private val slots = arrayOfNulls<OutputSlot>(2)
    private var current: Entry? = null
    private var serial = 0L
    private var lastSampleId = 0L
    private var lastSampleSession = 0L

    /** The sampler's state permits a read/host preparation only. The proposed
     * wake must be the immediate successor of that exact sampled authority. */
    fun reserve(stamp: KeyguardOrbPresentationStamp, sampleId: Long,
                sampleAuthority: KeyguardInspectionAuthority, publishedAuthority: KeyguardInspectionAuthority,
                sampleEligible: Boolean, routeEligible: Boolean): Reservation? = synchronized(lock) {
        if (!sampleEligible || !routeEligible || sampleId <= 0 || !stamp.structurallyValid() ||
            sampleAuthority != publishedAuthority ||
            stamp.authority != sampleAuthority.copy(wakeGeneration = sampleAuthority.wakeGeneration + 1) ||
            current?.grantState?.let { it != Grant.RETIRED } == true || slots.all { it != null } ||
            (sampleId == lastSampleId && sampleAuthority.serviceSession == lastSampleSession)
        ) return@synchronized null
        val token = Reservation(++serial, stamp, sampleId, sampleAuthority)
        current = Entry(token)
        lastSampleId = sampleId
        lastSampleSession = sampleAuthority.serviceSession
        token
    }

    /** Main either adopts precisely the reserved wake or seals it. No earlier
     * result is ever copied into a different authority. */
    fun adopt(token: Reservation, actual: KeyguardOrbPresentationStamp): Boolean = synchronized(lock) {
        val entry = current ?: return@synchronized false
        if (entry.reservation != token || entry.grantState == Grant.REVOKED || entry.grantState == Grant.RETIRED ||
            token.stamp != actual || entry.adopted) return@synchronized false
        entry.adopted = true
        true
    }

    /** An actual same-wake re-entry must still receive a new complete read
     * and fresh final system proof. It never reuses the prior permission. */
    fun reserveReadmission(stamp: KeyguardOrbPresentationStamp, sampleId: Long,
                           publishedAuthority: KeyguardInspectionAuthority,
                           sampleEligible: Boolean, routeEligible: Boolean): Reservation? = synchronized(lock) {
        val previous = current ?: return@synchronized null
        if (previous.grantState != Grant.RETIRED || !sampleEligible || !routeEligible || sampleId <= 0 ||
            !stamp.structurallyValid() || stamp.authority != publishedAuthority ||
            stamp.authority.serviceSession != previous.reservation.stamp.authority.serviceSession ||
            stamp.authority.wakeGeneration != previous.reservation.stamp.authority.wakeGeneration ||
            slots.all { it != null } || (sampleId == lastSampleId && stamp.authority.serviceSession == lastSampleSession))
            return@synchronized null
        val token = Reservation(++serial, stamp, sampleId, publishedAuthority)
        current = Entry(token).also { it.adopted = true }
        lastSampleId = sampleId
        lastSampleSession = stamp.authority.serviceSession
        token
    }

    /** Replace an unshown neutral/full preparation while retaining the same
     * inert host. A fresh proof is required for the replacement; the old
     * output remains counted until its real native lifetime drains. */
    fun replaceUnshown(token: Reservation, replacement: KeyguardOrbPresentationStamp): Replacement? = synchronized(lock) {
        val entry = current ?: return@synchronized null
        val old = token.stamp
        if (entry.reservation != token || !entry.adopted || !replacement.structurallyValid() ||
            replacement.authority != entry.activeAuthority || replacement.hostGeneration != old.hostGeneration ||
            replacement.outputGeneration == old.outputGeneration || replacement.firstRequestId < old.firstRequestId ||
            replacement.width != old.width || replacement.height != old.height || replacement.densityDpi != old.densityDpi ||
            replacement.displayId != old.displayId || entry.crossedSubmitBoundary ||
            (entry.grantState != Grant.NONE && entry.grantState != Grant.PENDING) ||
            entry.hostState == Host.INPUT_ARMED || entry.hostState == Host.REMOVAL_PENDING || entry.hostState == Host.REMOVED)
            return@synchronized null
        val oldOutput = entry.output
        slots.firstOrNull { it?.reservation == token && it.output === oldOutput }?.retired = true
        val next = Reservation(++serial, replacement, token.sampleId, token.sampleAuthority)
        current = Entry(next).also {
            it.adopted = true
            it.host = entry.host
            it.hostState = entry.hostState
        }
        Replacement(next, oldOutput)
    }

    fun attachInertHost(token: Reservation, host: Any): Boolean = synchronized(lock) {
        val entry = current ?: return@synchronized false
        if (entry.reservation != token || entry.hostState != Host.NONE ||
            (entry.grantState != Grant.NONE && entry.grantState != Grant.PENDING)) return@synchronized false
        entry.host = host
        entry.hostState = Host.INERT
        true
    }

    fun hostReady(token: Reservation, host: Any): Boolean = synchronized(lock) {
        val entry = current ?: return@synchronized false
        if (entry.reservation != token || entry.host !== host || entry.hostState != Host.INERT ||
            entry.grantState == Grant.REVOKED || entry.grantState == Grant.RETIRED) return@synchronized false
        entry.hostState = Host.READY
        true
    }

    /** At most two actual native owners may exist, including old borrowers.
     * Each is matched by reference, never by its diagnostic identity hash. */
    fun attachPreparedOutput(token: Reservation, output: Any): Boolean = synchronized(lock) {
        val entry = current ?: return@synchronized false
        if (entry.reservation != token || entry.output != null ||
            (entry.grantState != Grant.NONE && entry.grantState != Grant.PENDING) ||
            slots.any { it?.output === output }) return@synchronized false
        val index = slots.indexOfFirst { it == null }
        if (index < 0) return@synchronized false
        slots[index] = OutputSlot(token, output)
        entry.output = output
        true
    }

    fun imageReady(token: Reservation, output: Any): Boolean = synchronized(lock) {
        val entry = current ?: return@synchronized false
        if (entry.reservation != token || entry.output !== output ||
            entry.grantState == Grant.REVOKED || entry.grantState == Grant.RETIRED) return@synchronized false
        entry.imageReady = true
        true
    }

    /** The caller supplies a current, complete MAIN and a fresh final system
     * check. A cached sample or a merely attached host can never authorize. */
    fun grant(token: Reservation, authority: KeyguardInspectionAuthority, requestId: Long,
              completeMain: Boolean, finalSystemEligible: Boolean, disclosedFull: Boolean,
              selectionRevision: Long, materialRevision: Long, dataRevision: Long): Boolean = synchronized(lock) {
        val entry = current ?: return@synchronized false
        val stamp = token.stamp
        if (entry.reservation != token || !entry.adopted || entry.grantState != Grant.NONE ||
            authority != stamp.authority || requestId < stamp.firstRequestId || !completeMain || !finalSystemEligible ||
            disclosedFull != stamp.full || selectionRevision != stamp.selectionRevision ||
            materialRevision != stamp.materialRevision || dataRevision != stamp.dataRevision) return@synchronized false
        entry.proofRequestId = requestId
        entry.grantState = Grant.PENDING
        true
    }

    fun discardUnpublishedGrant(token: Reservation): Boolean = synchronized(lock) {
        val entry = current ?: return@synchronized false
        if (entry.reservation != token || entry.grantState != Grant.PENDING ||
            entry.hostState == Host.INPUT_ARMED || entry.crossedSubmitBoundary) return@synchronized false
        entry.proofRequestId = null
        entry.grantState = Grant.NONE
        true
    }

    /** Main must enable input for the exact ready host before a visual reveal. */
    fun armInput(token: Reservation, host: Any): Boolean = synchronized(lock) {
        val entry = current ?: return@synchronized false
        if (entry.reservation != token || entry.host !== host || entry.hostState != Host.READY ||
            !entry.imageReady || entry.output == null || entry.grantState != Grant.PENDING) return@synchronized false
        entry.hostState = Host.INPUT_ARMED
        true
    }

    /** Readiness may arrive long after classification. Recheck the exact
     * revisions, current classification and fresh system state at publication. */
    fun queueReveal(token: Reservation, authority: KeyguardInspectionAuthority,
                    completeMainStillCurrent: Boolean, finalSystemEligible: Boolean,
                    selectionRevision: Long, materialRevision: Long, dataRevision: Long): Reveal? = synchronized(lock) {
        val entry = current ?: return@synchronized null
        val stamp = token.stamp
        if (authority != entry.activeAuthority || !completeMainStillCurrent || !finalSystemEligible ||
            selectionRevision != stamp.selectionRevision || materialRevision != stamp.materialRevision ||
            dataRevision != stamp.dataRevision) return@synchronized null
        val host = entry.host ?: return@synchronized null
        val output = entry.output ?: return@synchronized null
        val proof = entry.proofRequestId ?: return@synchronized null
        if (entry.reservation != token || !entry.adopted || !entry.imageReady ||
            entry.hostState != Host.INPUT_ARMED || entry.grantState != Grant.PENDING) return@synchronized null
        entry.grantState = Grant.REVEAL_QUEUED
        entry.submitPhase = SubmitPhase.PRE_CROSS
        entry.transitionOrdinal += 1
        Reveal(token, proof, entry.activeAuthority, output, host, ++entry.revealSequence)
    }

    /** Installing the already-authorized root advances only its attachment
     * generation. No external wake, session, privacy or interaction change
     * can be smuggled through this transition. */
    fun bindPresentedAttachment(token: Reservation, before: KeyguardInspectionAuthority,
                                after: KeyguardInspectionAuthority): Boolean = synchronized(lock) {
        val entry = current ?: return@synchronized false
        if (entry.reservation != token || entry.activeAuthority != before ||
            entry.grantState != Grant.PENDING || entry.hostState != Host.INPUT_ARMED ||
            after != before.copy(attachGeneration = before.attachGeneration + 1)) return@synchronized false
        entry.activeAuthority = after
        true
    }

    fun advanceInteraction(token: Reservation, before: KeyguardInspectionAuthority,
                           after: KeyguardInspectionAuthority): Boolean = synchronized(lock) {
        val entry = current ?: return@synchronized false
        if (entry.reservation != token || entry.activeAuthority != before ||
            (entry.grantState != Grant.PRESENTED && entry.grantState != Grant.REVEAL_QUEUED) ||
            entry.hostState != Host.INPUT_ARMED ||
            after != before.copy(interactionEpoch = before.interactionEpoch + 1)) return@synchronized false
        entry.activeAuthority = after
        true
    }

    /** Called immediately before the serial compositor owner submits. A seal
     * before this check rejects the show; a seal afterwards must queue the
     * matching hide after this in-flight transaction on that same executor. */
    fun crossSubmitBoundary(reveal: Reveal): Boolean = synchronized(lock) {
        val entry = current ?: return@synchronized false
        if (entry.reservation != reveal.reservation || entry.output !== reveal.output || entry.host !== reveal.host ||
            entry.proofRequestId != reveal.proofRequestId || entry.activeAuthority != reveal.authority ||
            entry.revealSequence != reveal.sequence || entry.grantState != Grant.REVEAL_QUEUED || entry.hostState != Host.INPUT_ARMED || entry.submitPhase != SubmitPhase.PRE_CROSS || entry.crossedSubmitBoundary
        ) return@synchronized false
        entry.crossedSubmitBoundary = true
        entry.submitPhase = SubmitPhase.CROSSED
        entry.transitionOrdinal += 1
        true
    }

    /** Non-mutating final check after crossing, before the native apply.
     * A concurrently cancelled permit must not submit a new private buffer. */
    fun isCrossedCurrent(reveal: Reveal): Boolean = synchronized(lock) {
        val entry = current ?: return@synchronized false
        entry.reservation === reveal.reservation && entry.output === reveal.output && entry.host === reveal.host &&
            entry.proofRequestId == reveal.proofRequestId && entry.activeAuthority == reveal.authority &&
            entry.revealSequence == reveal.sequence && entry.grantState == Grant.REVEAL_QUEUED &&
            entry.hostState == Host.INPUT_ARMED && entry.submitPhase == SubmitPhase.CROSSED
    }

    /** The compositor calls this only after its captured native apply returns.
     * A concurrently cancelled permit remains cancelled even if Android did
     * submit pixels. The return value is this owner's transition ordinal. */
    fun markNativeApplyReturned(reveal: Reveal): Long? = synchronized(lock) {
        val entry = current ?: return@synchronized null
        if (entry.reservation !== reveal.reservation || entry.output !== reveal.output || entry.host !== reveal.host ||
            entry.proofRequestId != reveal.proofRequestId || entry.revealSequence != reveal.sequence ||
            entry.grantState != Grant.REVEAL_QUEUED || entry.hostState != Host.INPUT_ARMED ||
            entry.submitPhase != SubmitPhase.CROSSED) return@synchronized null
        entry.submitPhase = SubmitPhase.APPLIED
        ++entry.transitionOrdinal
    }

    /** Proof expiration and this scalar decision may be called under the same
     * shared queue lock. The caller does all inspection and cleanup outside it. */
    fun arbitrateIngress(token: Reservation, host: Any?, output: Any?, retainApplied: Boolean): IngressDecision = synchronized(lock) {
        val entry = current
        if (entry == null || entry.reservation !== token || host == null || output == null ||
            entry.host !== host || entry.output !== output || entry.hostState != Host.INPUT_ARMED ||
            (entry.grantState != Grant.PENDING && entry.grantState != Grant.REVEAL_QUEUED))
            return@synchronized IngressDecision(IngressAction.IGNORE, entry?.submitPhase ?: SubmitPhase.NONE, 0L)
        val phase = entry.submitPhase
        entry.transitionOrdinal += 1
        if (phase == SubmitPhase.APPLIED && retainApplied)
            return@synchronized IngressDecision(IngressAction.KEEP_SUBMITTED, phase, entry.transitionOrdinal)
        entry.submitPhase = SubmitPhase.CANCELLED
        IngressDecision(IngressAction.CANCEL_PENDING, phase, entry.transitionOrdinal)
    }

    fun revealOrdinal(reveal: Reveal): Long? = synchronized(lock) {
        val entry = current ?: return@synchronized null
        if (entry.reservation !== reveal.reservation || entry.host !== reveal.host || entry.output !== reveal.output ||
            entry.revealSequence != reveal.sequence || entry.proofRequestId != reveal.proofRequestId) null
        else entry.transitionOrdinal
    }

    fun isAppliedPending(token: Reservation, host: Any?, output: Any?): Boolean = synchronized(lock) {
        val entry = current
        entry != null && entry.reservation === token && host != null && output != null &&
            entry.host === host && entry.output === output && entry.hostState == Host.INPUT_ARMED &&
            entry.grantState == Grant.REVEAL_QUEUED && entry.submitPhase == SubmitPhase.APPLIED
    }

    fun revealSubmitted(reveal: Reveal): Boolean = synchronized(lock) {
        val entry = current ?: return@synchronized false
        if (entry.reservation != reveal.reservation || entry.output !== reveal.output || entry.host !== reveal.host ||
            entry.revealSequence != reveal.sequence || entry.proofRequestId != reveal.proofRequestId ||
            entry.submitPhase != SubmitPhase.APPLIED || entry.grantState != Grant.REVEAL_QUEUED
        ) return@synchronized false
        entry.grantState = Grant.PRESENTED
        entry.submitPhase = SubmitPhase.ACKNOWLEDGED
        entry.transitionOrdinal += 1
        true
    }

    /** An authoritative negative belongs to the same authority and cannot
     * predate the proof that granted this image. Terminal callers may use the
     * current proof request when the system signal has no request ID. */
    fun seal(token: Reservation, authority: KeyguardInspectionAuthority, requestId: Long,
             authoritativeExclusion: Boolean): Withdrawal? = synchronized(lock) {
        val entry = current ?: return@synchronized null
        if (entry.reservation != token || authority != entry.activeAuthority || !authoritativeExclusion ||
            requestId < (entry.proofRequestId ?: token.stamp.firstRequestId) ||
            entry.grantState == Grant.REVOKED || entry.grantState == Grant.RETIRED) return@synchronized null
        entry.grantState = Grant.REVOKED
        entry.submitPhase = SubmitPhase.CANCELLED
        entry.transitionOrdinal += 1
        entry.hostState = if (entry.host == null) Host.REMOVED else Host.REMOVAL_PENDING
        slots.firstOrNull { it?.reservation == token && it.output === entry.output }?.retired = true
        Withdrawal(token, entry.output, entry.host, entry.crossedSubmitBoundary)
    }

    /** A late native callback may drain only its exact retired owner. */
    fun outputDrained(token: Reservation, output: Any): Boolean = synchronized(lock) {
        val index = slots.indexOfFirst { it?.reservation == token && it.output === output && it.retired }
        if (index < 0) return@synchronized false
        slots[index] = null
        true
    }

    /** Only the original host's actual removal can finish its lifecycle. */
    fun hostRemoved(token: Reservation, host: Any): Boolean = synchronized(lock) {
        val entry = current ?: return@synchronized false
        if (entry.reservation != token || entry.host !== host || entry.hostState != Host.REMOVAL_PENDING ||
            entry.grantState != Grant.REVOKED) return@synchronized false
        entry.hostState = Host.REMOVED
        true
    }

    fun retired(token: Reservation): Boolean = synchronized(lock) {
        val entry = current ?: return@synchronized false
        if (entry.reservation != token || entry.grantState != Grant.REVOKED || entry.hostState != Host.REMOVED)
            return@synchronized false
        entry.grantState = Grant.RETIRED
        entry.submitPhase = SubmitPhase.NONE
        entry.transitionOrdinal += 1
        true
    }

    fun mayAct(token: Reservation, host: Any): Boolean = synchronized(lock) {
        val entry = current
        entry != null && entry.reservation == token && entry.host === host && entry.hostState == Host.INPUT_ARMED &&
            (entry.grantState == Grant.PENDING || entry.grantState == Grant.REVEAL_QUEUED ||
                entry.grantState == Grant.PRESENTED)
    }

    fun snapshot(): Snapshot = synchronized(lock) {
        val entry = current
        Snapshot(entry?.reservation, entry?.hostState ?: Host.NONE, entry?.grantState ?: Grant.NONE,
            entry?.adopted == true, entry?.imageReady == true, entry?.proofRequestId, slots.count { it != null })
    }
}
