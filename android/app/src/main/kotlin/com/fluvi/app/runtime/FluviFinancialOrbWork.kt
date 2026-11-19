package com.fluvi.app.runtime

import android.os.Debug
import android.os.SystemClock

/** Numeric, per-operation evidence. Only the keyguard service arms a scope;
 * launcher and notification work cannot be charged to a keyguard request. */
internal object FluviFinancialOrbWork {
    internal class Scope internal constructor(internal val previous: Scope?) {
        val startUptimeMs = SystemClock.uptimeMillis()
        private val startNs = System.nanoTime()
        private val startCpuNs = Debug.threadCpuTimeNanos()
        var constructions = 0L
        var demands = 0L
        var paints = 0L
        var paintCompletions = 0L
        var legacyBinds = 0L
        var paintWallNs = 0L
        var paintCpuNs = 0L
        var paintMaxWallNs = 0L
        var paintMaxCpuNs = 0L
        var attachment: Long? = null
        var routeCode = -1
        var endUptimeMs = 0L
        var wallNs = 0L
        var cpuNs = 0L
        var noOp = false
        var completed = false
        var resultReturned = false
        var successful = false

        fun finish(resultNoOp: Boolean, resultSuccessful: Boolean, returned: Boolean = true) {
            if (completed) return
            endUptimeMs = SystemClock.uptimeMillis()
            wallNs = (System.nanoTime() - startNs).coerceAtLeast(0L)
            cpuNs = (Debug.threadCpuTimeNanos() - startCpuNs).coerceAtLeast(0L)
            noOp = resultNoOp
            resultReturned = returned
            successful = resultSuccessful
            completed = true
        }
    }

    private val active = ThreadLocal<Scope?>()
    fun begin(): Scope = Scope(active.get()).also { active.set(it) }
    fun current(): Scope? = active.get()
    fun end(scope: Scope) {
        if (active.get() === scope) active.set(scope.previous) else active.remove()
    }

    fun construction() { active.get()?.let { it.constructions++ } }
    fun demand() { active.get()?.let { it.demands++ } }
    fun legacyBind() { active.get()?.let { it.legacyBinds++ } }

    inline fun <T> paint(block: () -> T): T {
        val scope = current() ?: return block()
        val start = System.nanoTime()
        val cpu = Debug.threadCpuTimeNanos()
        scope.paints++
        try {
            return block().also { scope.paintCompletions++ }
        } finally {
            val wall = (System.nanoTime() - start).coerceAtLeast(0L)
            val thread = (Debug.threadCpuTimeNanos() - cpu).coerceAtLeast(0L)
            scope.paintWallNs += wall
            scope.paintCpuNs += thread
            scope.paintMaxWallNs = maxOf(scope.paintMaxWallNs, wall)
            scope.paintMaxCpuNs = maxOf(scope.paintMaxCpuNs, thread)
        }
    }
}
