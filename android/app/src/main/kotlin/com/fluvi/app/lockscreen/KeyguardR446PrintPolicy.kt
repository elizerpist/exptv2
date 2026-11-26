package com.fluvi.app.lockscreen

import android.view.accessibility.AccessibilityWindowInfo

/** Screen coordinates copied from the same authoritative window inventory.
 * These are geometry only, never node or application content. */
internal data class KeyguardR446Bounds(val left: Int, val top: Int, val right: Int, val bottom: Int) {
    val width: Int get() = right - left
    val height: Int get() = bottom - top
    val valid: Boolean get() = width > 0 && height > 0
}

/** A sample-only target. It is deliberately not a KeyguardSurface or a
 * financial visibility grant. The caller must still validate its read and
 * system authority immediately before use. */
internal data class KeyguardR446Target(val windowId: Int, val displayId: Int, val bounds: KeyguardR446Bounds)
internal data class KeyguardR446Eligibility(val target: KeyguardR446Target?, val reason: String)

/** Causal result of the actual Main handoff, not a later diagnostic replay. */
internal enum class KeyguardR447Disposition {
    UNOBSERVED, SCENE_CHANGED, NEWER_COMPLETED, NEWER_BARRIER_REQUIRED,
    REDUNDANT_OFFER_ACCEPTED, FRESHNESS_UNESTABLISHED, RESTRICTION_OBSERVED,
    RESTRICTION_ONLY, STALE_AUTHORITY, ARM_MISMATCH, TARGET_MISSING,
    PRESENTER_UNAVAILABLE, ISSUE_REJECTED, SETTINGS_UNAVAILABLE, PRIVATE_NOT_AUTHORIZED, ISSUED,
}

internal object KeyguardR446PrintPolicy {
    fun evaluate(
        windows: List<KeyguardWindowSnapshot>, classification: KeyguardSurfaceClassification,
        unavailable: Boolean, truncated: Boolean,
    ): KeyguardR446Eligibility {
        fun denied(reason: String) = KeyguardR446Eligibility(null, reason)
        if (classification.surface in setOf(KeyguardSurface.CREDENTIAL, KeyguardSurface.SHADE, KeyguardSurface.OCCLUDED) ||
            classification.r444Gate == KeyguardR444Gate.RESTRICTION) return denied("RESTRICTION")
        if (unavailable || truncated || classification.r444Gate == KeyguardR444Gate.INCOMPLETE)
            return denied("INCOMPLETE")
        // Only the lack of a positive marker is relaxed. Unknown owner,
        // ancestry, additional restrictions and incomplete walks are not.
        if (classification.surface != KeyguardSurface.MAIN_KEYGUARD &&
            !(classification.surface == KeyguardSurface.UNKNOWN &&
                classification.r444Gate in setOf(KeyguardR444Gate.NO_CONTENT, KeyguardR444Gate.NO_HOST,
                    KeyguardR444Gate.COVER_VETO))) return denied("UNKNOWN_SCENE")
        val primary = windows.filter { it.displayId == 0 && !it.ownOverlay }
        if (primary.isEmpty()) return denied("NO_WINDOWS")
        if (primary.any { w -> w.type != AccessibilityWindowInfo.TYPE_SYSTEM ||
                w.packageName != "com.android.systemui" || w.r44?.let { !it.verifiedRoot || !it.complete || it.foreignNode } != false })
            return denied("UNVERIFIED_WINDOW")
        val hosts = primary.filter { it.r444Active == true && it.r444Focused == true && it.r44?.active == true }
        if (hosts.size != 1) return denied("HOST_NOT_UNIQUE")
        val host = hosts.single()
        if (host.windowId < 0) return denied("HOST_ID")
        val bounds = host.r446Bounds?.takeIf { it.valid } ?: return denied("HOST_BOUNDS")
        val others = primary.filter { it !== host }
        if (others.any { it.layer == host.layer || it.r444Active != false || it.r444Focused != false })
            return denied("AMBIGUOUS_WINDOW")
        if (others.count { it.layer > host.layer } > 1) return denied("UPPER_WINDOWS")
        return KeyguardR446Eligibility(KeyguardR446Target(host.windowId, host.displayId, bounds), "ELIGIBLE_SAMPLE")
    }
}

/** Main-thread single-use capability, valid only after the next screen-off
 * and its associated wake. The deadline can revoke but never grant output. */
internal class KeyguardR446PrintOwner {
    enum class State { INACTIVE, WAIT_OFF, WAIT_WAKE, WAIT_READ, ISSUED, CONSUMED }
    data class Arm(val generation: Long, val session: Long, val capture: String)
    data class Ticket(val arm: Arm, val wake: Long, val request: Long, val scene: Long,
                      val target: KeyguardR446Target, val deadline: Long)
    var state = State.INACTIVE; private set
    var arm: Arm? = null; private set
    var ticket: Ticket? = null; private set
    private var generation = 0L

    fun arm(session: Long, capture: String): Arm {
        revoke()
        return Arm(++generation, session, capture).also { arm = it; state = State.WAIT_OFF }
    }
    fun screenOff() {
        if (state == State.WAIT_OFF) state = State.WAIT_WAKE else if (state != State.INACTIVE) revoke()
    }
    fun wake(session: Long, capture: String?): Boolean {
        if (state != State.WAIT_WAKE || arm?.session != session || arm?.capture != capture) return false
        state = State.WAIT_READ
        return true
    }
    fun issue(session: Long, capture: String?, wake: Long, request: Long, scene: Long,
              target: KeyguardR446Target, now: Long, publicFixture: Boolean = true): Ticket? {
        val current = arm ?: return null
        if (state != State.WAIT_READ || current.session != session || current.capture != capture ||
            wake <= 0 || request <= 0 || scene < 0 || !target.bounds.valid) return null
        return Ticket(current, wake, request, scene, target, if (publicFixture) now + 2_000L else Long.MAX_VALUE).also {
            ticket = it; state = State.ISSUED
        }
    }
    fun current(value: Ticket, session: Long, capture: String?, wake: Long, scene: Long, now: Long): Boolean =
        state == State.ISSUED && ticket === value && arm === value.arm && session == value.arm.session &&
            capture == value.arm.capture && wake == value.wake && scene == value.scene && now < value.deadline
    fun revoke() { generation++; ticket = null; arm = null; state = State.CONSUMED }
}
