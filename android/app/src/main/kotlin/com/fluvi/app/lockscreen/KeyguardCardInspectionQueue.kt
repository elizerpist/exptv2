package com.fluvi.app.lockscreen

/** Wake-opening sampler observation, not permission to reuse a system state. */
internal data class KeyguardWakeEligibilityEvidence(
    val sampleRequestId: Long?, val sampleAuthority: KeyguardInspectionAuthority?,
    val callbackAt: Long, val startedAt: Long, val finishedAt: Long, val deliveredAt: Long,
    val captureId: String,
)

/** A completed independent sampler observation, not reusable show authority. */
internal data class KeyguardSamplerEvidence(
    val requestId: Long, val authority: KeyguardInspectionAuthority,
    val startedAt: Long, val finishedAt: Long, val deliveredAt: Long,
    val eligible: Boolean, val excluded: Boolean,
    val captureId: String,
) {
    fun belongsTo(authority: KeyguardInspectionAuthority, captureId: String?): Boolean =
        captureId != null && this.captureId == captureId && this.authority == authority
}

/** Immutable authority captured when an inspection is requested, rather than
 * when its worker eventually gets CPU time. */
internal data class KeyguardCardInspectionRequest(
    val id: Long,
    val trigger: String,
    val session: Long,
    val visibilityEpoch: Long,
    val interactionEpoch: Long,
    val attachGeneration: Long,
    val wakeGeneration: Long,
    val queuedAtUptimeMs: Long,
    /** Freshness is captured with this request. It directs only reader cache
     * invalidation; it never grants visibility from a previous surface. */
    val windowFreshness: KeyguardWindowFreshness = KeyguardWindowFreshness.FRAMEWORK_EVENT,
    val eventTimeUptimeMs: Long? = null,
    /** Captured before the worker is queued; a late callback must not be
     * relabelled with the wake/attempt that happens to be current later. */
    val diagnosticContext: KeyguardDiagnosticContext? = null,
    val triggerReceivedUptimeMs: Long? = null,
    /** Original scalar ingress identity; copies retain it across reacquisition. */
    val r14Ingress: KeyguardR14Ingress? = null,
    val wakeEligibility: KeyguardWakeEligibilityEvidence? = null,
    val latestSamplerEvidence: KeyguardSamplerEvidence? = null,
    /** Actual framework ingress for this queue offer; copied reconciliation is not a new event. */
    val r32FrameworkIngressId: Long? = null,
    /** Scene assigned to this exact external framework offer; null for copied or synthetic work. */
    val r34SceneSerial: Long? = null,
) {
    /** Carry an unserved event, never an acquired answer, across a local
     * withdrawal in the SAME service/wake. The new request must reacquire
     * under current authority; event/callback origins remain immutable. */
    fun reacquireAfterWithdrawal(
        authority: KeyguardInspectionAuthority,
        newId: Long,
        queuedAt: Long,
        freshness: KeyguardWindowFreshness,
    ): KeyguardCardInspectionRequest? {
        if (session != authority.serviceSession || wakeGeneration != authority.wakeGeneration) return null
        require(newId != id)
        return copy(
            id = newId,
            visibilityEpoch = authority.visibilityEpoch,
            interactionEpoch = authority.interactionEpoch,
            attachGeneration = authority.attachGeneration,
            queuedAtUptimeMs = queuedAt,
            latestSamplerEvidence = null,
            r32FrameworkIngressId = null,
            r34SceneSerial = null,
            windowFreshness = if (windowFreshness.requiresCacheClear && !freshness.requiresCacheClear) windowFreshness else freshness,
        )
    }
}

/**
 * The worker never reads the service's individual mutable generation fields.
 * Its owner publishes this one immutable value whenever lifecycle authority
 * changes, so a Binder call that cannot be interrupted still stops before the
 * next platform/node request when it returns.
 */
internal data class KeyguardInspectionAuthority(
    val serviceSession: Long,
    val visibilityEpoch: Long,
    val wakeGeneration: Long,
    val interactionEpoch: Long,
    val attachGeneration: Long,
) {
    fun matches(request: KeyguardCardInspectionRequest): Boolean =
        serviceSession == request.session &&
            visibilityEpoch == request.visibilityEpoch &&
            wakeGeneration == request.wakeGeneration &&
            interactionEpoch == request.interactionEpoch &&
            attachGeneration == request.attachGeneration
}

/** Inert unless the Android instrumentation fixture installs it. Acquisition
 * and start observations are worker-owned; apply observations are Main-owned.
 * No live Event, node or View is retained in this boundary. */
internal interface KeyguardInspectionProbeForTest {
    fun snapshots(request: KeyguardCardInspectionRequest, actual: List<KeyguardWindowSnapshot>): List<KeyguardWindowSnapshot> = actual
    fun started(request: KeyguardCardInspectionRequest) {}
    /** Called only by an already-presented owner's optional worker read. */
    fun r40ProvenanceStarted(request: KeyguardCardInspectionRequest) {}
    /** Frozen choice for this physical read; does not grant presentation. */
    fun openingOrderSelected(request: KeyguardCardInspectionRequest, milestoneOrdered: Boolean) {}
    /** Observation only; callbacks run outside queueLock on the sampler/reader. */
    fun openingReserved(request: KeyguardCardInspectionRequest, reservationId: Long, armed: Boolean) {}
    fun openingChildBefore(request: KeyguardCardInspectionRequest, windowId: Int, index: Int) {}
    fun openingChildReturned(request: KeyguardCardInspectionRequest, windowId: Int, index: Int, present: Boolean) {}
    fun openingEligibleCheckpoint(request: KeyguardCardInspectionRequest, windowId: Int, nextIndex: Int) {}
    fun postClaimObserved(snapshot: KeyguardOpeningInspectionHandoff.PostClaimSnapshot) {}
    fun yielded(request: KeyguardCardInspectionRequest, successor: KeyguardCardInspectionRequest,
        startedAt: Long, finishedAt: Long, visited: Int) {}
    /** Test-only observation, after the queue lock has been released. */
    fun r37BoundaryClaimed(request: KeyguardCardInspectionRequest, successor: KeyguardCardInspectionRequest,
        boundary: String, at: Long) {}
    /** The physical read has completed; this callback runs on the reader,
     * before its Main handoff. A test may hold this worker without blocking
     * the event-ingress thread. The classifier and authority are unchanged. */
    fun readCompleted(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility,
        reason: KeyguardSurfaceReason, rootUnavailable: Boolean, walkTruncated: Boolean,
        abortedStale: Boolean, startedAt: Long, finishedAt: Long) {}
    fun ingress(meta: KeyguardAccessibilityEventMeta, receivedAt: Long,
        action: KeyguardEventAction, frameworkEvent: Boolean) {}
    fun frameworkCopy(meta: KeyguardAccessibilityEventMeta, type: Int, window: Int, display: Int,
        changes: Int, packageName: String?, eventTime: Long) {}
    fun ingressOffered(meta: KeyguardAccessibilityEventMeta, request: KeyguardCardInspectionRequest,
        previous: KeyguardCardInspectionRequest?, pending: KeyguardCardInspectionRequest?,
        startsWorker: Boolean, frameworkEvent: Boolean) {}
    fun queueOffered(request: KeyguardCardInspectionRequest, previous: KeyguardCardInspectionRequest?,
        pending: KeyguardCardInspectionRequest?, startsWorker: Boolean) {}
    /** Observation of the actual queue transition, not an admission. */
    fun r25QueueTransition(request: KeyguardCardInspectionRequest, pendingAtOffer: KeyguardCardInspectionRequest?,
        activeAfter: KeyguardCardInspectionRequest?, superseded: KeyguardCardInspectionRequest?) {}
    fun beforeApply(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility) {}
    fun positiveApplyAttempt(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility) {}
    fun beforeDecision(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility,
        pending: KeyguardCardInspectionRequest?, authority: KeyguardInspectionAuthority) {}
    fun readAheadDecision(request: KeyguardCardInspectionRequest, pendingId: Long?, reservedId: Long?,
        reason: String, snapshot: KeyguardReadAheadSnapshot?, currentFreshnessRevision: Long?,
        outstandingFreshness: KeyguardWindowFreshness?, negativeFreshnessRevision: Long?) {}
    fun afterApply(request: KeyguardCardInspectionRequest, decision: KeyguardCardVisibility) {}
    /** Test-only optional report boundary; never called while queueLock is held. */
    fun beforeOptionalInspectionReport(request: KeyguardCardInspectionRequest) {}
    /** Fixture-only R41 ownership observation; never grants presentation. */
    fun r41H2Boundary(request: KeyguardCardInspectionRequest, phase: String,
        successor: KeyguardCardInspectionRequest? = null) {}
}

internal data class KeyguardR22VisualIdentityForTest(
    val reservationId: Long,
    val openingRequestId: Long,
    val winningRequestId: Long?,
    val hostIdentity: Int,
    val attachment: Long,
    val outputGeneration: Long,
    val childIdentity: Int,
    val bounds: android.graphics.Rect,
)

internal data class KeyguardInspectionStateForTest(
    val authority: KeyguardInspectionAuthority,
    val pending: KeyguardCardInspectionRequest?,
    val wake: Long?,
    val attached: Boolean,
    val retryCount: Int,
)

/** Known, positively identified accessibility-overlay ownership.  It is
 * deliberately narrower than a package match: an Activity or another service
 * overlay must still follow the safe discovery path. */
internal data class KeyguardOwnOverlayIdentity(
    val windowId: Int,
    val displayId: Int,
    val attachGeneration: Long,
)

/** Pure owner for the one physical wake observed through several Android
 * callbacks. It has no knowledge of Views or accessibility nodes, so ordering
 * behaviour is testable without turning callbacks into a debounce. */
internal data class KeyguardWakeCycle(
    val id: Long,
    val firstSignal: String,
    val firstObservedAtUptimeMs: Long,
    val screenOnReceivedAtUptimeMs: Long? = null,
)

internal data class KeyguardWakeCycleTransition(
    val cycle: KeyguardWakeCycle,
    val started: Boolean,
    val screenOnJoined: Boolean,
)

internal class KeyguardWakeCycleOwner {
    private var open: KeyguardWakeCycle? = null

    fun beginOrJoin(nextId: Long, source: String, observedAtUptimeMs: Long): KeyguardWakeCycleTransition {
        val existing = open
        if (existing != null) {
            val updated = if (source == "wake" && existing.screenOnReceivedAtUptimeMs == null) {
                existing.copy(screenOnReceivedAtUptimeMs = observedAtUptimeMs)
            } else existing
            open = updated
            return KeyguardWakeCycleTransition(updated, started = false, screenOnJoined = source == "wake")
        }
        val created = KeyguardWakeCycle(
            id = nextId,
            firstSignal = source,
            firstObservedAtUptimeMs = observedAtUptimeMs,
            screenOnReceivedAtUptimeMs = observedAtUptimeMs.takeIf { source == "wake" },
        )
        open = created
        return KeyguardWakeCycleTransition(created, started = true, screenOnJoined = false)
    }

    fun current(): KeyguardWakeCycle? = open
    fun end() { open = null }
}

/** A service owns one of these behind its queue lock. It permits one Binder
 * walk and one latest replacement request; it can never grow a wake-event
 * backlog. */
internal class KeyguardCardInspectionQueue {
    private var active: KeyguardCardInspectionRequest? = null
    private var pending: KeyguardCardInspectionRequest? = null
    // Exact transfer recorded before the old reader begins unwinding.
    private var openingTransferFrom: KeyguardCardInspectionRequest? = null
    private var openingTransferTo: KeyguardCardInspectionRequest? = null
    // Only a completed detached negative may leave its ordered Main apply
    // behind the physical reader. The reserved successor remains separately
    // attributable to that decision even if a newer request is coalesced.
    private var preceding: KeyguardCardInspectionRequest? = null

    /** @return true only when the caller must start a worker immediately. */
    fun offer(request: KeyguardCardInspectionRequest): Boolean {
        // A parked obsolete read may leave an unperformed obligation in the
        // pending slot. Transfer that obligation to the next real offer, never
        // manufacture an event or silently lose a lifecycle cache clear.
        val previous = pending
        val actual = if (previous != null && previous.windowFreshness.requiresCacheClear &&
            !request.windowFreshness.requiresCacheClear &&
            previous.session == request.session && previous.wakeGeneration == request.wakeGeneration &&
            previous.visibilityEpoch == request.visibilityEpoch &&
            previous.interactionEpoch == request.interactionEpoch &&
            previous.attachGeneration == request.attachGeneration
        ) request.copy(windowFreshness = previous.windowFreshness) else request
        if (active == null) {
            pending = null
            active = actual
            return true
        }
        pending = actual
        return false
    }

    /** Completes [request] and returns exactly one coalesced successor. */
    fun complete(request: KeyguardCardInspectionRequest): KeyguardCardInspectionRequest? {
        if (active != request || preceding != null) return null
        if (openingTransferTo == request) {
            openingTransferFrom = null
            openingTransferTo = null
        }
        val next = pending
        pending = null
        active = next
        return next
    }

    /** Only after the physical reader has unwound. Keep an older pending
     * freshness obligation until the newer scene's actual request arrives. */
    fun parkObsoleteAfterRead(request: KeyguardCardInspectionRequest): Boolean {
        if (active != request || preceding != null) return false
        active = null
        openingTransferFrom = null
        openingTransferTo = null
        return true
    }

    /** A completed positive can hand the same reader to an exact pending
     * successor only before Main has claimed that completed request. */
    fun handoffCompleted(
        completed: KeyguardCardInspectionRequest,
        successor: KeyguardCardInspectionRequest,
    ): KeyguardCardInspectionRequest? {
        if (preceding != null || active != completed || pending != successor) return null
        return complete(completed)
    }

    fun canPublishCompleted(request: KeyguardCardInspectionRequest): Boolean =
        active == request && preceding == null

    /** A still-running opening walk may hand its one reader to an exact,
     * already offered successor. Unlike R12, no completed predecessor waits
     * for Main. The service validates opportunity/authority/freshness while
     * holding its queue lock before calling this scalar transition. */
    fun handoffOpening(
        opening: KeyguardCardInspectionRequest,
        successor: KeyguardCardInspectionRequest,
    ): KeyguardCardInspectionRequest? {
        if (preceding != null || active != opening || pending != successor) return null
        val promoted = complete(opening) ?: return null
        openingTransferFrom = opening
        openingTransferTo = promoted
        return promoted
    }

    data class UnwoundRecovery(val next: KeyguardCardInspectionRequest?)

    /** Called only when a failed/cancelled physical reader has fully unwound.
     * A transfer already claimed before unwinding must start its exact new
     * owner; otherwise complete only the failed owner and retain latest work. */
    fun recoverUnwoundReader(owner: KeyguardCardInspectionRequest): UnwoundRecovery? {
        if (preceding != null) return null
        if (openingTransferFrom == owner && active == openingTransferTo && openingTransferTo != null) {
            val claimed = active
            openingTransferFrom = null
            openingTransferTo = null
            return UnwoundRecovery(claimed)
        }
        if (active != owner) return null
        return UnwoundRecovery(complete(owner))
    }

    /** Used only after the owning service job was torn down while its reader
     * was unwinding. A late cleanup can never touch another active owner. */
    fun abandonSessionIfActive(owner: KeyguardCardInspectionRequest): Boolean {
        if (active != owner || preceding != null ||
            pending?.let { it.session != owner.session } == true) return false
        active = null
        pending = null
        openingTransferFrom = null
        openingTransferTo = null
        return true
    }

    /** Covers teardown during A's object recycling, before the typed result
     * has returned to its coroutine. Never follows a newer transfer or owner. */
    fun abandonOpeningTransferIfActive(opening: KeyguardCardInspectionRequest): Boolean {
        if (openingTransferFrom != opening) return false
        val successor = openingTransferTo ?: return false
        return abandonSessionIfActive(successor)
    }

    fun clearPending() {
        pending = null
    }

    fun activeRequest(): KeyguardCardInspectionRequest? = active
    fun pendingRequest(): KeyguardCardInspectionRequest? = pending

    /** Called under the service queue lock only after the completed answer is
     * proven eligible. The predicate checks immutable authority and freshness;
     * it must not call Android or perform work that can block. */
    fun reserveSuccessor(
        completed: KeyguardCardInspectionRequest,
        compatible: (KeyguardCardInspectionRequest) -> Boolean,
    ): KeyguardCardInspectionRequest? {
        if (preceding != null || active != completed) return null
        val next = pending ?: return null
        if (!compatible(next)) return null
        preceding = completed
        active = next
        pending = null
        return next
    }

    fun successorForPreceding(request: KeyguardCardInspectionRequest): KeyguardCardInspectionRequest? =
        active.takeIf { preceding == request }

    fun finishPreceding(request: KeyguardCardInspectionRequest): Boolean {
        if (preceding != request) return false
        preceding = null
        return true
    }

    /** R32 cleanup cannot release a later reader or a different wake. */
    fun finishPrecedingExact(request: KeyguardCardInspectionRequest,
                             successor: KeyguardCardInspectionRequest): Boolean {
        if (preceding != request || active != successor) return false
        preceding = null
        return true
    }

    /** Applying UNKNOWN has not released active yet. That completed cause is
     * not future work capable of replacing its fallback observation. */
    fun hasCurrentWork(authority: KeyguardInspectionAuthority, excludingId: Long? = null): Boolean =
        (preceding?.let { it.id != excludingId && authority.matches(it) } == true) ||
            (active?.let { it.id != excludingId && authority.matches(it) } == true) ||
            (pending?.let { it.id != excludingId && authority.matches(it) } == true)
}

/** Main publishes this immutable snapshot before visibility or relevant
 * preference changes. It permits a read only; the normal Main gate remains
 * the sole owner of any disclosure. */
internal data class KeyguardReadAheadSnapshot(
    val authority: KeyguardInspectionAuthority,
    val freshnessRevision: Long,
    val stateRevision: Long,
    val detached: Boolean,
    val showInProgress: Boolean,
    val surfaceState: KeyguardSurfacePresentationState,
)

internal data class KeyguardReadAheadNegative(
    val decision: KeyguardCardVisibility,
    val reason: KeyguardSurfaceReason,
    val rootUnavailable: Boolean,
    val walkTruncated: Boolean,
    val abortedStale: Boolean,
    val freshnessRevision: Long?,
)

internal object KeyguardReadAheadPolicy {
    fun permits(
        snapshot: KeyguardReadAheadSnapshot,
        negative: KeyguardReadAheadNegative,
        first: KeyguardCardInspectionRequest,
        successor: KeyguardCardInspectionRequest,
        currentFreshnessRevision: Long,
        outstandingFreshness: KeyguardWindowFreshness,
    ): Boolean = rejection(snapshot, negative, first, successor, currentFreshnessRevision, outstandingFreshness) == "eligible"

    fun rejection(
        snapshot: KeyguardReadAheadSnapshot,
        negative: KeyguardReadAheadNegative,
        first: KeyguardCardInspectionRequest,
        successor: KeyguardCardInspectionRequest,
        currentFreshnessRevision: Long,
        outstandingFreshness: KeyguardWindowFreshness,
    ): String {
        if (!snapshot.detached || snapshot.showInProgress) return "notDetachedOrShowing"
        if (snapshot.surfaceState != KeyguardSurfacePresentationState.AWAITING_MAIN_SURFACE &&
            snapshot.surfaceState != KeyguardSurfacePresentationState.WITHDRAWN_AWAITING_SURFACE) return "surfaceState"
        if (!snapshot.authority.matches(first) || !snapshot.authority.matches(successor) || first.id == successor.id) return "authority"
        if (snapshot.freshnessRevision != currentFreshnessRevision || snapshot.freshnessRevision != negative.freshnessRevision) return "freshnessRevision"
        if (successor.windowFreshness.requiresCacheClear || outstandingFreshness.requiresCacheClear) return "freshnessRequired"
        if (negative.abortedStale) return "stale"
        if (negative.rootUnavailable) return "rootUnavailable"
        if (negative.walkTruncated) return "walkTruncated"
        if (negative.decision != KeyguardCardVisibility.HIDDEN_UNKNOWN || negative.reason != KeyguardSurfaceReason.NO_MAIN_MARKER) return "classification"
        val transition = KeyguardAwaitingSurfacePolicy.onUnknown(
            current = snapshot.surfaceState,
            overlayAttached = false,
            hasCompatiblePendingRequest = true,
            retryAvailable = false,
        )
        return if (!transition.withdrawVisibleOverlay && !transition.invalidatesVisibleAuthority &&
            transition.followup == KeyguardUnknownSurfaceFollowup.CONTINUE_PENDING) "eligible" else "policy"
    }
}

/** Fast hide is intentionally based only on immediately knowable terminal
 * state. It never treats a Fluvi pointer event as exclusion. */
internal object KeyguardCardFastHideGate {
    fun shouldHide(displayInteractive: Boolean, displayOff: Boolean, keyguardLocked: Boolean): Boolean =
        !displayInteractive || displayOff || !keyguardLocked
}

/** Tracks a completed terminal exclusion separately from attachment state.
 * A detached root can still have a live inspection before the first hide;
 * only the same already-invalidated state is a genuine no-op. */
internal data class KeyguardTerminalHideState(
    val serviceSession: Long,
    val invalidatedVisibilityEpoch: Long,
)

internal object KeyguardTerminalHideGate {
    fun shouldProcess(
        terminalWake: Boolean,
        overlayAttached: Boolean,
        serviceSession: Long,
        visibilityEpoch: Long,
        previous: KeyguardTerminalHideState?,
    ): Boolean = !terminalWake || overlayAttached || previous?.serviceSession != serviceSession ||
        previous.invalidatedVisibilityEpoch != visibilityEpoch
}

/**
 * Surface uncertainty is not itself a terminal device transition.  Keep this
 * deliberately small and close to the inspection queue: it describes only
 * what an already-authorised inspection may do after it cannot prove the
 * main keyguard surface.  The service remains the owner of the actual Window
 * lifecycle and the terminal gates.
 */
internal enum class KeyguardSurfacePresentationState {
    AWAITING_MAIN_SURFACE,
    VISIBLE,
    WITHDRAWN_AWAITING_SURFACE,
    TERMINALLY_EXCLUDED,
}

internal enum class KeyguardUnknownSurfaceFollowup {
    CONTINUE_PENDING,
    SCHEDULE_FALLBACK,
    WAIT_FOR_EVENT,
}

internal data class KeyguardUnknownSurfaceTransition(
    val nextState: KeyguardSurfacePresentationState,
    val withdrawVisibleOverlay: Boolean,
    val invalidatesVisibleAuthority: Boolean,
    val followup: KeyguardUnknownSurfaceFollowup,
)

/** Production waiting policy for UNKNOWN and recoverable OCCLUDED, used by
 * [FluviKeyguardCardService]. Neither is permission to show. In
 * particular, the active request which is currently being applied is never
 * passed as [hasCompatiblePendingRequest]; only a queued successor counts as
 * future work. */
internal object KeyguardAwaitingSurfacePolicy {
    fun onUnknown(
        current: KeyguardSurfacePresentationState,
        overlayAttached: Boolean,
        hasCompatiblePendingRequest: Boolean,
        retryAvailable: Boolean,
    ): KeyguardUnknownSurfaceTransition {
        val withdrawing = overlayAttached
        val next = if (withdrawing) {
            KeyguardSurfacePresentationState.WITHDRAWN_AWAITING_SURFACE
        } else if (current == KeyguardSurfacePresentationState.WITHDRAWN_AWAITING_SURFACE) {
            KeyguardSurfacePresentationState.WITHDRAWN_AWAITING_SURFACE
        } else {
            KeyguardSurfacePresentationState.AWAITING_MAIN_SURFACE
        }
        val followup = when {
            hasCompatiblePendingRequest -> KeyguardUnknownSurfaceFollowup.CONTINUE_PENDING
            retryAvailable -> KeyguardUnknownSurfaceFollowup.SCHEDULE_FALLBACK
            else -> KeyguardUnknownSurfaceFollowup.WAIT_FOR_EVENT
        }
        return KeyguardUnknownSurfaceTransition(
            nextState = next,
            withdrawVisibleOverlay = withdrawing,
            invalidatesVisibleAuthority = withdrawing,
            followup = followup,
        )
    }
}
