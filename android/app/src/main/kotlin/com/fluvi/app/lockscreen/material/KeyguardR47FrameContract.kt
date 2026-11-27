package com.fluvi.app.lockscreen.material

/** Bounds shared with Dashboard's existing launcher material exporter. */
internal object KeyguardR47FrameContract {
    const val maxFrames = 175
    const val maxEncodedBytes = 2 * 1024 * 1024
    const val maxDecodedBytes = 700 * 1024

    fun validate(
        animated: Boolean,
        frameCount: Int,
        sizePx: Int,
        intervalMs: Int,
        encodedBytes: Long,
    ): String? {
        if (sizePx !in 32..128 || intervalMs !in 16..60_000 || frameCount !in 1..maxFrames)
            return "invalidGeometry"
        if ((animated && frameCount < 3) || (!animated && frameCount != 1))
            return "incompleteSequence"
        if (encodedBytes <= 0 || encodedBytes > maxEncodedBytes ||
            sizePx.toLong() * sizePx * 4L * frameCount > maxDecodedBytes)
            return "byteBudgetExceeded"
        return null
    }

    /** The initial frame is the captured Header's phase, not a wall-clock
     * restart. A resumed owner on the same source uses the same origin. */
    fun frameIndex(frameNanos: Long, originNanos: Long, intervalMs: Int, count: Int): Int {
        require(originNanos >= 0L && intervalMs > 0 && count > 0)
        val elapsedNanos = (frameNanos - originNanos).coerceAtLeast(0L)
        return ((elapsedNanos / 1_000_000L / intervalMs) % count).toInt()
    }
}
