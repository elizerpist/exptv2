package com.fluvi.app.lockscreen

/** One scalar opportunity for the original, unpublished wake-opening walk.
 * Every mutating method is called while the service's queueLock is held. The
 * volatile hint makes the ordinary node-walk path a single cheap read. It is
 * never authority to display; the promoted request must perform a fresh read. */
internal class KeyguardOpeningInspectionHandoff {
    /** Facts about one actual pending queue occupant. These never grant display
     * authority and are not a replacement for the pre-claim B evidence. */
    data class PendingObservation(
        val id: Long, val queuedAt: Long, val trigger: String,
        val origin: String, val ingressId: Long?, val ingressOrigin: String?,
        val eventType: Int?, val display: Int?, val eventAt: Long?,
        val callbackAt: Long?, val freshness: KeyguardWindowFreshness,
        val freshnessCopied: Boolean, val displacedId: Long?,
    )
    data class PostClaimSnapshot(
        val context: KeyguardDiagnosticContext,
        val openingId: Long, val reservationId: Long,
        val authority: KeyguardInspectionAuthority, val claimedId: Long,
        val ordinal: Long, val first: PendingObservation?, val latest: PendingObservation?,
        val offers: Int, val replacements: Int,
        val bStartedAt: Long?, val bFinishedAt: Long?, val closedReason: String?,
    )

    data class Snapshot(
        val openingId: Long,
        val reservationId: Long,
        val wake: Long,
        val startedAt: Long?,
        val sceneAtRead: Long?,
        val firstIngressAt: Long?,
        val firstIngressScene: Long?,
        val firstOfferedId: Long?,
        val firstOfferedAt: Long?,
        val latestOfferedId: Long?,
        val latestOfferedAt: Long?,
        val latestFrameworkEvent: Boolean?,
        val latestIngressId: Long?,
        val latestEventType: Int?,
        val latestDisplay: Int?,
        val latestEventAt: Long?,
        val replacedId: Long?,
        val replacementId: Long?,
        val claimedId: Long?,
        val claimedAt: Long?,
        val completedAt: Long?,
        val lastCheckpoint: String?,
        val lastCheckpointAt: Long?,
        val checkpointVisited: Int?,
        val checkpointRoots: Int?,
        val checkpointChildren: Int?,
        val lastReason: String?,
        val consumed: Boolean,
        val diagnosticContext: KeyguardDiagnosticContext?,
        val postClaim: PostClaimSnapshot?,
        val incompleteChecks: Int, val incompleteEligible: Int, val incompleteRejected: Int,
        val incompleteYielded: Int, val firstIncompleteRejection: String?,
    )

    data class Conditions(
        val reservationCurrent: Boolean,
        val routeCurrent: Boolean,
        val authorityCurrent: Boolean,
        val hostSafe: Boolean,
        val grantNone: Boolean,
        val noPaint: Boolean,
        val noVisibleOrShowing: Boolean,
        val freshnessEstablished: Boolean,
        val noObservedDisqualifier: Boolean,
        val workRemaining: Boolean,
        val virginDirect: Boolean = false,
        val noRetainedProof: Boolean = false,
    )

    private data class Hint(val requestId: Long, val ingressId: Long, val scene: Long)
    private class PostClaim(
        val context: KeyguardDiagnosticContext,
        val claimedId: Long,
        var ordinal: Long,
    ) {
        var first: PendingObservation? = null
        var latest: PendingObservation? = null
        var offers = 0
        var replacements = 0
        var bStartedAt: Long? = null
        var bFinishedAt: Long? = null
        var closedReason: String? = null
    }
    private class Opportunity(
        val token: Any,
        val reservationId: Long,
        val opening: KeyguardCardInspectionRequest,
        val authority: KeyguardInspectionAuthority,
        val routeRevision: Long,
    ) {
        var startedAt: Long? = null
        var sceneAtRead: Long? = null
        var firstIngressAt: Long? = null
        @Volatile var firstIngressForReader = 0L
        var firstIngressScene: Long? = null
        var pendingIngressScene: Long? = null
        var firstOfferedId: Long? = null
        var firstOfferedAt: Long? = null
        var latestOfferedId: Long? = null
        var latestOfferedAt: Long? = null
        var latestFrameworkEvent: Boolean? = null
        var latestIngressId: Long? = null
        var latestEventType: Int? = null
        var latestDisplay: Int? = null
        var latestEventAt: Long? = null
        var replacedId: Long? = null
        var replacementId: Long? = null
        var previousHintId: Long? = null
        var hint: Hint? = null
        var claimedId: Long? = null
        var claimedAt: Long? = null
        var completedAt: Long? = null
        var lastCheckpoint: String? = null
        var lastCheckpointAt: Long? = null
        var checkpointVisited: Int? = null
        var checkpointRoots: Int? = null
        var checkpointChildren: Int? = null
        var lastReason: String? = null
        var consumed = false
        var invalidated = false
        var postClaim: PostClaim? = null
        var incompleteChecks = 0
        var incompleteEligible = 0
        var incompleteRejected = 0
        var incompleteYielded = 0
        var firstIncompleteRejection: String? = null
    }

    private var current: Opportunity? = null
    // Incremented under queueLock, including ties in SystemClock uptime.
    private var nextObservationOrdinal = 0L
    @Volatile var hasHint: Boolean = false
        private set
    @Volatile var openingRequestId: Long = 0L
        private set
    @Volatile var claimedRequestId: Long = 0L
        private set
    @Volatile var offeredRequestId: Long = 0L
        private set

    fun arm(token: Any, reservationId: Long, opening: KeyguardCardInspectionRequest,
            authority: KeyguardInspectionAuthority, routeRevision: Long): Boolean {
        val old = current
        if (old != null && old.authority.serviceSession == authority.serviceSession &&
            old.authority.wakeGeneration == authority.wakeGeneration) return false
        current = Opportunity(token, reservationId, opening, authority, routeRevision)
        openingRequestId = opening.id
        claimedRequestId = 0L
        offeredRequestId = 0L
        hasHint = false
        return true
    }

    fun readStarted(opening: KeyguardCardInspectionRequest, scene: Long, at: Long) {
        val op = current ?: return
        if (op.opening != opening || op.consumed || op.invalidated || op.completedAt != null || op.startedAt != null) return
        op.startedAt = at
        op.sceneAtRead = scene
    }

    /** Called at the same ordered scene advancement, before a real offer. */
    fun externalInvalidation(scene: Long, at: Long) {
        val op = current ?: return
        if (op.consumed || op.invalidated || op.completedAt != null ||
            op.startedAt == null || op.sceneAtRead == null || scene <= requireNotNull(op.sceneAtRead)) return
        if (op.firstIngressAt == null) {
            op.firstIngressAt = at
            op.firstIngressScene = scene
            op.firstIngressForReader = at
        }
        op.pendingIngressScene = scene
        op.previousHintId = op.hint?.requestId ?: op.previousHintId
        op.hint = null
        hasHint = false
    }

    /** A synthetic/non-ingress replacement cannot inherit an old event hint. */
    fun offered(request: KeyguardCardInspectionRequest, pending: KeyguardCardInspectionRequest?,
                externalScene: Long?, currentScene: Long, frameworkEvent: Boolean = false) {
        val op = current ?: return
        if (op.consumed || op.invalidated || op.completedAt != null) return
        val ingress = request.r14Ingress
        val oldHintId = op.hint?.requestId ?: op.previousHintId
        if (oldHintId != null && pending != null && oldHintId != pending.id) {
            op.replacedId = oldHintId
            op.replacementId = pending.id
        }
        op.previousHintId = null
        val eligible = externalScene != null && externalScene == currentScene &&
            externalScene == op.pendingIngressScene && ingress != null &&
            ingress.origin != KeyguardR14Origin.OWN &&
            pending?.id == request.id && pending.r14Ingress?.id == ingress.id &&
            op.authority.matches(request) && op.authority.matches(pending) && request.id > op.opening.id
        if (eligible) {
            op.hint = Hint(request.id, requireNotNull(ingress).id, requireNotNull(externalScene))
            if (op.firstOfferedId == null) { op.firstOfferedId = request.id; op.firstOfferedAt = request.queuedAtUptimeMs }
            op.latestOfferedId = request.id
            offeredRequestId = request.id
            op.latestOfferedAt = request.queuedAtUptimeMs
            op.latestFrameworkEvent = frameworkEvent
            op.latestIngressId = ingress.id
            op.latestEventType = ingress.eventType
            op.latestDisplay = ingress.displayId
            op.latestEventAt = ingress.eventAt
        } else if (op.hint?.requestId != pending?.id || externalScene != null) {
            op.hint = null
        }
        hasHint = op.hint != null
    }

    /** The queue transition and one-use claim are a single scalar critical
     * section. A replacement must itself carry the newer event identity. */
    fun claim(queue: KeyguardCardInspectionQueue, opening: KeyguardCardInspectionRequest,
              currentToken: Any?, currentRouteRevision: Long, currentScene: Long,
              conditions: Conditions, checkpoint: String, at: Long,
              visited: Int = 0, roots: Int = 0, children: Int = 0,
              observationCaptureId: String? = null,
              yieldReason: KeyguardOpeningYieldReason = KeyguardOpeningYieldReason.CLEAN_OPENING): KeyguardCardInspectionRequest? {
        val op = current ?: return null
        // A late callback must not write a checkpoint into a newer owner,
        // even if local request IDs happen to match.
        if (op.opening != opening || currentToken !== op.token) return null
        val hint = op.hint ?: return null
        op.lastCheckpoint = checkpoint
        op.lastCheckpointAt = at
        op.checkpointVisited = visited
        op.checkpointRoots = roots
        op.checkpointChildren = children
        val next = queue.pendingRequest()
        val reason = when {
            op.opening != opening || op.startedAt == null || op.sceneAtRead == null -> "notOpeningRead"
            op.completedAt != null || op.consumed || op.invalidated -> "alreadyFinished"
            currentToken !== op.token || !conditions.reservationCurrent -> "reservation"
            currentRouteRevision != op.routeRevision || !conditions.routeCurrent -> "route"
            !conditions.authorityCurrent || !op.authority.matches(opening) ||
                next == null || !op.authority.matches(next) -> "authority"
            !conditions.hostSafe || !conditions.grantNone || !conditions.noPaint ||
                !conditions.noVisibleOrShowing -> "presentation"
            !conditions.freshnessEstablished -> "freshness"
            !conditions.noObservedDisqualifier -> if (checkpoint == "beforeActiveRoot")
                "rootIdentityUnverified" else "observedDisqualifier"
            !conditions.workRemaining -> "noRemainingWork"
            yieldReason == KeyguardOpeningYieldReason.INCOMPLETE_NULL_CHILD &&
                (!conditions.virginDirect || !conditions.noRetainedProof) -> "incompleteNotVirgin"
            yieldReason == KeyguardOpeningYieldReason.INCOMPLETE_NULL_CHILD && op.latestFrameworkEvent != true -> "incompleteNotFramework"
            hint.scene <= requireNotNull(op.sceneAtRead) || hint.scene != currentScene -> "scene"
            next.id != hint.requestId || next.r14Ingress?.id != hint.ingressId -> "replaced"
            else -> null
        }
        val incomplete = yieldReason == KeyguardOpeningYieldReason.INCOMPLETE_NULL_CHILD
        if (incomplete) op.incompleteChecks += 1
        if (reason != null) {
            if (incomplete) {
                op.incompleteRejected += 1
                if (op.firstIncompleteRejection == null) op.firstIncompleteRejection = reason
            }
            op.lastReason = reason; return null
        }
        if (incomplete) op.incompleteEligible += 1
        val successor = queue.handoffOpening(opening, requireNotNull(next))
        if (successor == null) {
            if (incomplete) {
                op.incompleteRejected += 1
                if (op.firstIncompleteRejection == null) op.firstIncompleteRejection = "queueChanged"
            }
            op.lastReason = "queueChanged"; return null
        }
        if (incomplete) op.incompleteYielded += 1
        op.claimedId = successor.id
        claimedRequestId = successor.id
        val originalContext = op.opening.diagnosticContext
        if (observationCaptureId != null && originalContext?.captureId == observationCaptureId &&
            originalContext.attemptId != null) {
            op.postClaim = PostClaim(originalContext, successor.id, ++nextObservationOrdinal)
        }
        op.claimedAt = at
        op.lastReason = if (yieldReason == KeyguardOpeningYieldReason.INCOMPLETE_NULL_CHILD)
            "YIELDED_INCOMPLETE_NULL_CHILD" else "YIELDED"
        op.consumed = true
        op.hint = null
        hasHint = false
        return successor
    }

    /** Observe the actual post-offer queue state. This is independent from
     * the already-consumed one-shot scheduling opportunity. Call under the
     * same queueLock immediately after queue.offer; emit its value elsewhere. */
    fun observePostClaimOffer(
        request: KeyguardCardInspectionRequest,
        previous: KeyguardCardInspectionRequest?,
        active: KeyguardCardInspectionRequest?,
        pending: KeyguardCardInspectionRequest?,
        frameworkEvent: Boolean,
        metadataPresent: Boolean = request.r14Ingress != null,
    ): PostClaimSnapshot? {
        val op = current ?: return null
        val observation = op.postClaim ?: return null
        if (observation.closedReason != null || active?.id != observation.claimedId ||
            !op.authority.matches(active) || pending?.id != request.id ||
            observation.latest?.id == request.id) return null
        val ingress = request.r14Ingress
        val fact = PendingObservation(
            id = pending.id, queuedAt = pending.queuedAtUptimeMs, trigger = pending.trigger,
            origin = if (!metadataPresent) "SYNTHETIC" else if (frameworkEvent) "FRAMEWORK" else "CONTROLLED",
            ingressId = ingress?.id, ingressOrigin = ingress?.origin?.name,
            eventType = ingress?.eventType, display = ingress?.displayId,
            eventAt = ingress?.eventAt, callbackAt = ingress?.callbackAt,
            freshness = pending.windowFreshness,
            freshnessCopied = pending.windowFreshness != request.windowFreshness,
            displacedId = previous?.id?.takeIf { it != pending.id },
        )
        if (observation.first == null) observation.first = fact
        observation.latest = fact
        observation.offers += 1
        if (fact.displacedId != null) observation.replacements += 1
        observation.ordinal = ++nextObservationOrdinal
        return postClaimSnapshot(op)
    }

    fun successorStarted(request: KeyguardCardInspectionRequest, at: Long): PostClaimSnapshot? {
        val op = current ?: return null
        val observation = op.postClaim ?: return null
        if (observation.closedReason != null || observation.claimedId != request.id ||
            !op.authority.matches(request)) return null
        if (observation.bStartedAt == null) {
            observation.bStartedAt = at
            observation.ordinal = ++nextObservationOrdinal
        }
        return postClaimSnapshot(op)
    }

    fun successorFinished(request: KeyguardCardInspectionRequest, at: Long,
                          reason: String = "FINISHED"): PostClaimSnapshot? {
        val op = current ?: return null
        val observation = op.postClaim ?: return null
        if (observation.closedReason != null || observation.claimedId != request.id ||
            !op.authority.matches(request)) return null
        observation.bFinishedAt = at
        observation.closedReason = reason
        observation.ordinal = ++nextObservationOrdinal
        return postClaimSnapshot(op)
    }

    private fun postClaimSnapshot(op: Opportunity): PostClaimSnapshot? = op.postClaim?.let {
        PostClaimSnapshot(it.context, op.opening.id, op.reservationId, op.authority, it.claimedId,
            it.ordinal, it.first, it.latest, it.offers, it.replacements,
            it.bStartedAt, it.bFinishedAt, it.closedReason)
    }

    fun readFinished(request: KeyguardCardInspectionRequest, at: Long) {
        val op = current ?: return
        if (op.opening != request || op.completedAt != null) return
        op.completedAt = at
        if (!op.consumed && op.lastReason == null) op.lastReason = if (op.hint == null) "noQualifyingOffer" else "noUsefulCheckpoint"
        op.hint = null
        hasHint = false
    }

    fun invalidate() {
        current?.let { it.invalidated = true; it.lastReason = it.lastReason ?: "ownerInvalidated"; it.hint = null }
        hasHint = false
    }

    /** A lightweight immutable handle for the particular original walk. */
    class YieldHandle internal constructor(
        internal val token: Any,
        internal val opening: KeyguardCardInspectionRequest,
    )

    fun yieldHandle(request: KeyguardCardInspectionRequest): YieldHandle? =
        current?.takeIf { it.opening == request && !it.consumed && !it.invalidated &&
            it.completedAt == null && it.startedAt != null }?.let { YieldHandle(it.token, it.opening) }

    /** Volatile hint only. Claim still validates the exact token under queueLock. */
    fun hasHint(handle: YieldHandle): Boolean = hasHint && openingRequestId == handle.opening.id

    fun isCurrent(handle: YieldHandle): Boolean = current?.let {
        it.token === handle.token && it.opening == handle.opening && !it.consumed &&
            !it.invalidated && it.completedAt == null
    } == true

    /** Captures the original owner; later wakes cannot relabel an old call. */
    fun ingressReader(request: KeyguardCardInspectionRequest): (() -> Long)? =
        current?.takeIf { it.opening == request }?.let { owner -> { owner.firstIngressForReader } }

    fun snapshotForSuccessor(request: KeyguardCardInspectionRequest): Snapshot? = current?.let {
        val exact = it.claimedId ?: it.latestOfferedId
        if (exact == request.id && it.authority.matches(request)) snapshot(it.opening.id) else null
    }

    fun snapshot(openingId: Long): Snapshot? = current?.takeIf { it.opening.id == openingId }?.let {
        Snapshot(it.opening.id, it.reservationId, it.authority.wakeGeneration, it.startedAt,
            it.sceneAtRead, it.firstIngressAt, it.firstIngressScene, it.firstOfferedId, it.firstOfferedAt,
            it.latestOfferedId, it.latestOfferedAt, it.latestFrameworkEvent,
            it.latestIngressId, it.latestEventType, it.latestDisplay, it.latestEventAt,
            it.replacedId, it.replacementId, it.claimedId, it.claimedAt, it.completedAt, it.lastCheckpoint, it.lastCheckpointAt,
            it.checkpointVisited, it.checkpointRoots, it.checkpointChildren, it.lastReason, it.consumed,
            it.opening.diagnosticContext, postClaimSnapshot(it), it.incompleteChecks, it.incompleteEligible,
            it.incompleteRejected, it.incompleteYielded, it.firstIncompleteRejection)
    }
}
