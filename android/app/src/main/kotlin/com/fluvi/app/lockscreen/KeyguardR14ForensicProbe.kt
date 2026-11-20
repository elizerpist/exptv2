package com.fluvi.app.lockscreen

import android.os.Process
import android.os.SystemClock
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.atomic.AtomicReferenceArray

/** Observation-only stock-harness seam. Disabled in normal service operation.
 * Owners never wait for this probe and no event contains a View or holder. */
internal object KeyguardR14ForensicProbe {
    const val READ_START = 1
    const val READ_END = 2
    const val HANDOFF = 3
    const val MAIN_ENTER = 4
    const val MAIN_EXIT = 5
    const val REJECT = 6
    const val DECISION = 7
    const val HIDE_ENTER = 8
    const val HIDE_RETURN = 9
    const val REVOKE = 10
    const val INVISIBLE = 11
    const val REMOVE_BEGIN = 12
    const val REMOVE_RETURN = 13
    const val DESTROY_ENTER = 14
    const val DESTROY_EXIT = 15
    const val DRAIN_ENTER = 16
    const val DRAIN_EXIT = 17
    const val CLEANUP_ENTER = 18
    const val CLEANUP_EXIT = 19
    const val WORKER_ENTERED = 20
    const val CANVAS_LOCK_BEGIN = 21
    const val CANVAS_LOCK_RETURN = 22
    const val POST_BEGIN = 23
    const val POST_RETURN = 24
    const val WORKER_LEFT = 25

    internal data class Mark(val sequence: Long, val uptimeMs: Long, val threadId: Int,
        val stage: Int, val request: Long, val attachment: Long, val generation: Long, val holder: Int, val extra: Int)
    private const val CAPACITY = 128
    private val sequence = AtomicLong()
    private val marks = AtomicReferenceArray<Mark?>(CAPACITY)
    @Volatile private var armed = false
    @Volatile private var selectedAttachment = 0L
    @Volatile var workerStage = 0
        private set
    @Volatile var workerAt = 0L
        private set
    @Volatile var workerThreadId = 0
        private set
    @Volatile var workerAttachment = 0L
        private set
    @Volatile var workerGeneration = 0L
        private set
    @Volatile var workerHolder = 0
        private set

    fun arm(attachment: Long) {
        require(attachment > 0)
        armed = false
        for (index in 0 until CAPACITY) marks.set(index, null)
        sequence.set(0)
        selectedAttachment = attachment
        workerStage = 0; workerAt = 0; workerThreadId = 0
        workerAttachment = 0; workerGeneration = 0; workerHolder = 0
        armed = true
    }
    fun disarm() { armed = false }
    fun observes(attachment: Long): Boolean = armed && attachment == selectedAttachment

    fun mark(stage: Int, request: Long = 0, attachment: Long = 0, generation: Long = 0, holder: Int = 0, extra: Int = 0) {
        if (!armed) return
        val next = sequence.incrementAndGet()
        marks.set(((next - 1) % CAPACITY).toInt(), Mark(next, SystemClock.uptimeMillis(), Process.myTid(), stage, request, attachment, generation, holder, extra))
    }

    /** Latest in-flight holder phase only: no per-frame objects or strings. */
    fun holder(stage: Int, attachment: Long, generation: Long, holder: Int) {
        if (!armed || attachment != selectedAttachment) return
        workerThreadId = Process.myTid()
        workerAttachment = attachment
        workerGeneration = generation
        workerHolder = holder
        workerAt = SystemClock.uptimeMillis()
        workerStage = stage
    }

    fun snapshot(): List<Mark> = (0 until CAPACITY).mapNotNull { marks.get(it) }.sortedBy { it.sequence }
}
