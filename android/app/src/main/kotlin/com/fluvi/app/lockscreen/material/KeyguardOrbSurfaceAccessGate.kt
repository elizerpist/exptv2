package com.fluvi.app.lockscreen.material

import java.util.concurrent.atomic.AtomicBoolean

/** One holder lifetime. Main can revoke without waiting; surfaceDestroyed
 * subsequently drains the single operation which had already entered. This
 * monitor never covers shader preparation, callbacks or a cross-thread join. */
internal class KeyguardOrbSurfaceAccessGate {
    private val monitor = java.lang.Object()
    private var authorized = true
    private var entered = false

    fun tryEnter(): Boolean = synchronized(monitor) {
        if (!authorized || entered) false else {
            entered = true
            true
        }
    }

    fun leave() = synchronized(monitor) {
        check(entered) { "surface holder operation was not entered" }
        entered = false
        monitor.notifyAll()
    }

    fun revoke() = synchronized(monitor) { authorized = false }

    fun destroyAndAwait() {
        var interrupted = false
        synchronized(monitor) {
            authorized = false
            while (entered) {
                try {
                    monitor.wait()
                } catch (_: InterruptedException) {
                    // A callback must not return while an entered operation
                    // can still touch the old holder, even if interrupted.
                    interrupted = true
                }
            }
        }
        if (interrupted) Thread.currentThread().interrupt()
    }
}

/** The OS redraw completion belongs to one callback, including cancellation. */
internal class KeyguardOrbSurfaceRedrawCompletion(private val callback: () -> Unit) {
    private val completed = AtomicBoolean(false)
    fun complete() {
        if (completed.compareAndSet(false, true)) callback()
    }
}
