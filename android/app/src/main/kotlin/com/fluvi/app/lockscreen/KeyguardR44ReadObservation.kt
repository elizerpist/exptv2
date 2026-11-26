package com.fluvi.app.lockscreen

/** Only allowlisted role and timings are exported; hierarchy data stays on the reader. */
internal data class KeyguardR445IndexCall(
    val role: String, val outcome: String, val durationMs: Long, val ageMs: Long, val overrunMs: Long,
    /** Nine denotes nine or more; no node identity or content is retained. */
    val rawHits: Int = 0, val firstRejection: String = "NONE",
)

/** Immutable, bounded sample-only telemetry associated with the original
 * wake/capture. All endpoints use uptime; none claim physical visibility. */
internal data class KeyguardR446Observation(
    val context: KeyguardDiagnosticContext, val armAt: Long, val wake: Long, val request: Long,
    val normal: String, val eligibility: String, val backend: String,
    val host: Int?, val scene: Long?, val issuedAt: Long?, val attachBegin: Long?,
    val attachEnd: Long?, val submittedAt: Long?, val frameAt: Long?,
    val withdrawAt: Long?, val withdrawReason: String,
)

/** Immutable, capture-owned scalars from the same physical inspection used
 * for authorization. No tree, arbitrary tag, text or foreign name survives. */
internal data class KeyguardR443CandidateObservation(
    val window: Int, val ordinal: Int, val branch: String, val rank: Int,
    val status: String, val role: String, val costMs: Long, val remaining: Int,
    val remainingMs: Long, val parentChecks: Int, val parentMs: Long,
)
internal data class KeyguardR443WindowObservation(
    val window: Int, val advertised: Int, val fetched: Int, val overflow: Int,
    val complete: Boolean,
)

internal data class KeyguardR444WindowObservation(
    val id: Int, val relativeLayer: Int, val type: Int, val active: Boolean?, val focused: Boolean?,
    val owner: String, val ownGeneration: Long?, val verifiedRoot: Boolean,
    val visited: Int?, val rootRole: String,
)

internal data class KeyguardR44ReadObservation(
    val context: KeyguardDiagnosticContext,
    val request: Long,
    val epoch: Long,
    val scene: Long?,
    val start: Long,
    val end: Long,
    val legacy: KeyguardSurface,
    val verdict: KeyguardSurface,
    val reason: KeyguardSurfaceReason,
    val synthetic: Boolean,
    val testProbeInjected: Boolean,
    val stale: Boolean,
    val unavailable: Boolean,
    val truncated: Boolean,
    val hostWindow: Int?,
    val hostLayer: Int?,
    val hostVerified: Boolean,
    val host: KeyguardR44Witness?,
    val content: KeyguardR44Witness?,
    val relation: Boolean,
    val coverageComplete: Boolean,
    val advertised: Int,
    val fetched: Int,
    val failed: Int,
    val unsupported: Int,
    val budgetHit: Boolean,
    val extraMs: Long,
    val lookupStatus: String = "UNOBSERVED",
    val lookupIdentity: String? = null,
    val shadowVerdict: KeyguardSurface? = null,
    val shadowReason: KeyguardSurfaceReason? = null,
    val rawHost: Int = 0,
    val rawEntry: Int = 0,
    val rawClock: Int = 0,
    val rejectedUnverified: Int = 0,
    val rejectedAncestry: Int = 0,
    val rejectedExcluded: Int = 0,
    val rejectedForeign: Int = 0,
    val rejectedHidden: Int = 0,
    val firstCandidate: KeyguardR44Markers.Marker? = null,
    val firstCarrier: KeyguardR44Markers.Carrier? = null,
    val cover: String = "UNOBSERVED",
    val receipt: String = "UNOBSERVED",
    val r443Windows: List<KeyguardR443WindowObservation> = emptyList(),
    val r443Candidates: List<KeyguardR443CandidateObservation> = emptyList(),
    val appliedGate: KeyguardR444Gate = KeyguardR444Gate.UNOBSERVED,
    val profile: String = "UNOBSERVED", val profileRevision: Long? = null,
    val previousFlags: Int? = null, val actualFlags: Int? = null,
    val clockResourceVerified: Boolean = false,
    val hostNodes: Int = 0, val hostCarriers: Int = 0,
    val hostParent: Int? = null, val contentParent: Int? = null,
    val secondaryCount: Int = 0, val secondaryOverflow: Int = 0,
    val r444Windows: List<KeyguardR444WindowObservation> = emptyList(),
    val r445SmallInstalled: Boolean = false, val r445LargeInstalled: Boolean = false,
    val r445EntryInstalled: Boolean = false, val r445IndexStatus: String = "NOT_REQUESTED",
    val r445IndexCalls: List<KeyguardR445IndexCall> = emptyList(),
)

internal data class KeyguardR442HandoffObservation(
    val context: KeyguardDiagnosticContext,
    val oldRequest: Long,
    val nextRequest: Long,
    val screenAt: Long,
    val offerAt: Long,
    val oldStart: Long,
    val boundaryAt: Long,
    val oldReturn: Long,
    val boundary: String,
)

/** Capture-only explanation of the first observed post-screen boundary. */
internal data class KeyguardR443BoundaryObservation(
    val context: KeyguardDiagnosticContext, val oldRequest: Long, val pendingRequest: Long?,
    val screenAt: Long, val offerAt: Long?, val oldStart: Long, val boundaryAt: Long,
    val oldEnd: Long, val reason: String, val ingressKind: String?,
    val ingressStart: Long?, val ingressEnd: Long?,
)
