package com.fluvi.app.lockscreen

/** Immutable, capture-owned scalars from the same physical inspection used
 * for authorization. No tree, arbitrary tag, text or foreign name survives. */
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
    val budgetHit: Boolean,
    val extraMs: Long,
)
