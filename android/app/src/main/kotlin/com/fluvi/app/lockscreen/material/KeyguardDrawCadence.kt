package com.fluvi.app.lockscreen.material

/** Numeric, attachment-local observations of successful shader traversals.
 * This is neither a Choreographer callback counter nor physical frame pacing.
 * No allocation, formatting, persistence or listener publication per draw. */
internal class KeyguardDrawCadence {
    private var frames = 0L
    private var firstAt = 0L
    private var lastAt = 0L
    private var firstPhase = Float.NaN
    private var lastPhase = Float.NaN
    private var gaps = 0L
    private var gapTotal = 0L
    private var gapMax = 0L
    private var invalidOrder = 0L

    fun reset() {
        frames = 0; firstAt = 0; lastAt = 0; firstPhase = Float.NaN; lastPhase = Float.NaN
        gaps = 0; gapTotal = 0; gapMax = 0; invalidOrder = 0
    }

    fun drawn(atUptimeMs: Long, phase: Float) {
        val previous = lastAt
        if (frames > 0) {
            val gap = atUptimeMs - previous
            if (gap < 0) invalidOrder++ else {
                gaps++
                gapTotal += gap
                if (gap > gapMax) gapMax = gap
            }
        } else {
            firstAt = atUptimeMs
            firstPhase = phase
        }
        frames++
        lastAt = atUptimeMs
        lastPhase = phase
    }

    fun snapshot() = Snapshot(
        frames, firstAt.takeIf { frames > 0 }, lastAt.takeIf { frames > 0 },
        firstPhase.takeUnless { it.isNaN() }, lastPhase.takeUnless { it.isNaN() },
        gaps, gapTotal, gapMax, invalidOrder,
    )

    data class Snapshot(
        val frames: Long, val firstAt: Long?, val lastAt: Long?,
        val firstPhase: Float?, val lastPhase: Float?, val gaps: Long,
        val gapTotalMs: Long, val gapMaxMs: Long, val invalidOrder: Long,
    )
}
