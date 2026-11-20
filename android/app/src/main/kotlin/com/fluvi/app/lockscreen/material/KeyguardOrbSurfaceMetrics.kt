package com.fluvi.app.lockscreen.material

/** Worker-owned numeric ring. Snapshot/percentile work runs only at capture
 * export, and a volatile sequence makes concurrent snapshots fail closed. */
internal class KeyguardOrbSurfaceMetrics {
    private val gaps = LongArray(720)
    @Volatile private var sequence = 0L
    private var submissions = 0L
    private var firstPost = 0L
    private var firstDistinct = 0L
    private var activeStartedAt = 0L
    private var activeSubmissions = 0L
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
    // One worker writes the latest holder operation. These scalar fields are
    // sampled only for an active capture, and never retain a Canvas or View.
    @Volatile private var operationVersion = 0L
    private var operationId = 0L
    private var lockEnter = 0L
    private var lockReturn = 0L
    private var drawReturn = 0L
    private var postEnter = 0L
    private var postReturn = 0L
    private var recordAt = 0L
    // Main's revocation bracket has a separate writer from the worker.
    @Volatile private var revokeBegin = 0L
    @Volatile private var revokeReturn = 0L
    @Volatile private var r16HostId = 0
    @Volatile private var r16ChildId = 0
    @Volatile private var r16CreatedAt = 0L
    @Volatile private var r16RetireBegin = 0L
    @Volatile private var r16RetireEnd = 0L
    @Volatile private var r16RetireSucceeded = false
    @Volatile private var r16CommitReceipt = 0L
    @Volatile private var r16CommitMain = 0L
    @Volatile private var r16DisposedAt = 0L
    @Volatile private var r16LateOperation: HolderOperation? = null

    data class OwnedLayer(
        val hostId: Int, val childId: Int, val createdAt: Long?, val retireBegin: Long?,
        val retireEnd: Long?, val retireSucceeded: Boolean, val commitReceipt: Long?,
        val commitMain: Long?, val disposedAt: Long?, val lateOperation: HolderOperation?,
    )

    data class HolderOperation(
        val coherent: Boolean, val id: Long, val lockEnter: Long?, val lockReturn: Long?,
        val drawReturn: Long?, val postEnter: Long?, val postReturn: Long?, val recordAt: Long?,
        val revokeBegin: Long?, val revokeReturn: Long?,
    )

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
        val holderOperation: HolderOperation,
        val ownedLayer: OwnedLayer,
        val activeStartedAtUptimeMs: Long?,
        val activeSubmissions: Long,
    )

    fun beginHolderOperation(at: Long) {
        operationVersion += 1L
        operationId += 1L
        lockEnter = at; lockReturn = 0L; drawReturn = 0L
        postEnter = 0L; postReturn = 0L; recordAt = 0L
        operationVersion += 1L
    }

    fun holderLockReturned(at: Long) { operationVersion += 1L; lockReturn = at; operationVersion += 1L }
    fun holderDrawReturned(at: Long) { operationVersion += 1L; drawReturn = at; operationVersion += 1L }
    fun holderPostEntered(at: Long) { operationVersion += 1L; postEnter = at; operationVersion += 1L }
    fun holderPostReturned(at: Long) { operationVersion += 1L; postReturn = at; operationVersion += 1L }
    fun holderRecordObserved(at: Long) { operationVersion += 1L; recordAt = at; operationVersion += 1L }
    fun revokeStarted(at: Long) { if (revokeBegin == 0L) revokeBegin = at }
    fun revokeReturned(at: Long) { if (revokeReturn == 0L) revokeReturn = at }
    fun r16Created(hostId: Int, childId: Int, at: Long) {
        r16HostId = hostId; r16ChildId = childId; r16CreatedAt = at
    }
    fun r16RetireStarted(at: Long) { if (r16RetireBegin == 0L) r16RetireBegin = at }
    fun r16RetireReturned(at: Long, success: Boolean) { r16RetireSucceeded = success; r16RetireEnd = at }
    fun r16RetireCommitted(receipt: Long, delivered: Long) { r16CommitReceipt = receipt; r16CommitMain = delivered }
    fun r16Disposed(at: Long) { if (r16DisposedAt == 0L) r16DisposedAt = at }
    fun r16PinLateOperation() { if (r16LateOperation == null) r16LateOperation = holderSnapshot() }
    private fun ownedLayer() = OwnedLayer(r16HostId, r16ChildId, r16CreatedAt.takeIf { it > 0 },
        r16RetireBegin.takeIf { it > 0 }, r16RetireEnd.takeIf { it > 0 }, r16RetireSucceeded,
        r16CommitReceipt.takeIf { it > 0 }, r16CommitMain.takeIf { it > 0 },
        r16DisposedAt.takeIf { it > 0 }, r16LateOperation)

    fun holderSnapshot(): HolderOperation {
        repeat(3) {
            val before = operationVersion
            if (before and 1L != 0L) return@repeat
            val id = operationId
            val a = lockEnter; val b = lockReturn; val c = drawReturn
            val d = postEnter; val e = postReturn; val f = recordAt
            val revokeA = revokeBegin; val revokeB = revokeReturn
            if (before == operationVersion) return HolderOperation(true, id,
                a.takeIf { it > 0 }, b.takeIf { it > 0 }, c.takeIf { it > 0 },
                d.takeIf { it > 0 }, e.takeIf { it > 0 }, f.takeIf { it > 0 },
                revokeA.takeIf { it > 0 }, revokeB.takeIf { it > 0 })
        }
        return HolderOperation(false, 0L, null, null, null, null, null, null,
            revokeBegin.takeIf { it > 0 }, revokeReturn.takeIf { it > 0 })
    }

    /** Called by the worker after the direct reveal is submitted, before
     * starting its clock. Prewake poster age is never an active-frame gap. */
    fun beginDirectPresentation(at: Long) {
        sequence += 1L
        activeStartedAt = at
        activeSubmissions = 0L
        firstDistinct = 0L
        previousPostNs = 0L
        gapCount = 0
        gapWrites = 0L
        worstGap = 0L
        over50 = 0L
        sequence += 1L
    }

    fun record(postUptimeMs: Long, postNs: Long, distinct: Boolean,
               lockWallNs: Long, drawWallNs: Long, postWallNs: Long,
               lockCpuNs: Long, drawCpuNs: Long, postCpuNs: Long) {
        sequence += 1L
        submissions += 1L
        if (activeStartedAt > 0L) activeSubmissions += 1L
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
            val activeStart = activeStartedAt.takeIf { it > 0 }
            val activeCount = activeSubmissions
            val lockWall = maxLockWall; val drawWall = maxDrawWall; val postWall = maxPostWall
            val lockCpu = maxLockCpu; val drawCpu = maxDrawCpu; val postCpu = maxPostCpu
            if (before == sequence) return Snapshot(true, count, first, distinct, last, retained,
                values.takeIf { it.isNotEmpty() }?.get(((values.size - 1) * .95).toInt()), worst, over,
                lockWall, drawWall, postWall, lockCpu, drawCpu, postCpu, holderSnapshot(), ownedLayer(),
                activeStart, activeCount)
        }
        return Snapshot(false, 0, null, null, null, 0, null, null, 0, 0, 0, 0, 0, 0, 0,
            holderSnapshot(), ownedLayer(), null, 0)
    }
}
