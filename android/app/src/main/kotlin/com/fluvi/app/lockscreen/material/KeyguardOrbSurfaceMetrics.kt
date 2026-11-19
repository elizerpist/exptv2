package com.fluvi.app.lockscreen.material

/** Worker-owned numeric ring. Snapshot/percentile work runs only at capture
 * export, and a volatile sequence makes concurrent snapshots fail closed. */
internal class KeyguardOrbSurfaceMetrics {
    private val gaps = LongArray(720)
    @Volatile private var sequence = 0L
    private var submissions = 0L
    private var firstPost = 0L
    private var firstDistinct = 0L
    private var lastPost = 0L
    private var previousPostNs = 0L
    private var gapCount = 0
    private var gapWrites = 0L
    private var worstGap = 0L
    private var over50 = 0L
    private var maxLockWall = 0L
    private var maxDrawWall = 0L
    private var maxPostWall = 0L
    private var maxLockCpu = 0L
    private var maxDrawCpu = 0L
    private var maxPostCpu = 0L

    data class Snapshot(
        val coherent: Boolean,
        val submissions: Long,
        val firstPostUptimeMs: Long?,
        val firstDistinctUptimeMs: Long?,
        val lastPostUptimeMs: Long?,
        val retainedGaps: Int,
        val p95GapNs: Long?,
        val worstGapNs: Long?,
        val gapsOver50Ms: Long,
        val maxLockWallNs: Long,
        val maxDrawWallNs: Long,
        val maxPostWallNs: Long,
        val maxLockCpuNs: Long,
        val maxDrawCpuNs: Long,
        val maxPostCpuNs: Long,
    )

    fun record(postUptimeMs: Long, postNs: Long, distinct: Boolean,
               lockWallNs: Long, drawWallNs: Long, postWallNs: Long,
               lockCpuNs: Long, drawCpuNs: Long, postCpuNs: Long) {
        sequence += 1L
        submissions += 1L
        if (firstPost == 0L) firstPost = postUptimeMs
        if (distinct && firstDistinct == 0L) firstDistinct = postUptimeMs
        lastPost = postUptimeMs
        if (previousPostNs > 0 && postNs > previousPostNs) {
            val gap = postNs - previousPostNs
            gaps[(gapWrites % gaps.size).toInt()] = gap
            gapWrites += 1L
            if (gapCount < gaps.size) gapCount += 1
            worstGap = maxOf(worstGap, gap)
            if (gap > 50_000_000L) over50 += 1L
        }
        previousPostNs = postNs
        maxLockWall = maxOf(maxLockWall, lockWallNs)
        maxDrawWall = maxOf(maxDrawWall, drawWallNs)
        maxPostWall = maxOf(maxPostWall, postWallNs)
        maxLockCpu = maxOf(maxLockCpu, lockCpuNs)
        maxDrawCpu = maxOf(maxDrawCpu, drawCpuNs)
        maxPostCpu = maxOf(maxPostCpu, postCpuNs)
        sequence += 1L
    }

    fun snapshot(): Snapshot {
        repeat(3) {
            val before = sequence
            if (before and 1L != 0L) return@repeat
            val count = submissions
            val first = firstPost.takeIf { it > 0 }
            val distinct = firstDistinct.takeIf { it > 0 }
            val last = lastPost.takeIf { it > 0 }
            val retained = gapCount
            val values = gaps.copyOf(retained).sortedArray()
            val worst = worstGap.takeIf { retained > 0 }
            val over = over50
            val lockWall = maxLockWall; val drawWall = maxDrawWall; val postWall = maxPostWall
            val lockCpu = maxLockCpu; val drawCpu = maxDrawCpu; val postCpu = maxPostCpu
            if (before == sequence) return Snapshot(true, count, first, distinct, last, retained,
                values.takeIf { it.isNotEmpty() }?.get(((values.size - 1) * .95).toInt()), worst, over,
                lockWall, drawWall, postWall, lockCpu, drawCpu, postCpu)
        }
        return Snapshot(false, 0, null, null, null, 0, null, null, 0, 0, 0, 0, 0, 0, 0)
    }
}
