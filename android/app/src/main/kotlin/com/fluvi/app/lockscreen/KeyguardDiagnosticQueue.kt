package com.fluvi.app.lockscreen

import java.util.ArrayDeque
import java.util.concurrent.Executor
import java.util.concurrent.FutureTask
import java.util.concurrent.atomic.AtomicLong

/** One bounded consumer for the existing diagnostic reducer. Producers hold
 * only the mailbox lock while adding a reference; reduction, formatting and
 * disk work never run under that lock. The inspection/UI threads never wait
 * for the consumer. User snapshot commands are FIFO barriers on an IO caller. */
internal class KeyguardDiagnosticQueue(
    private val executor: Executor,
    private val capacity: Int = 512,
) {
    private val mailbox = ArrayDeque<() -> Unit>()
    private val lock = Any()
    private var draining = false
    private val consuming = ThreadLocal<Boolean>()
    val dropped = AtomicLong()
    val failed = AtomicLong()

    fun offer(work: () -> Unit): Boolean = enqueue(work, capacity)

    private fun enqueue(work: () -> Unit, limit: Int): Boolean {
        val schedule = synchronized(lock) {
            if (mailbox.size >= limit) {
                dropped.incrementAndGet()
                return false
            }
            mailbox.addLast(work)
            if (draining) false else {
                draining = true
                true
            }
        }
        if (schedule) executor.execute(::drain)
        return true
    }

    /** Only explicit debug-panel reads use this barrier. Never call it from
     * visibility, wake, rendering or inspection processing. Four reserved
     * control slots permit freeze/copy even when event recording overflows. */
    fun <T> read(block: () -> T): T {
        if (consuming.get() == true) return block()
        val task = FutureTask(block)
        check(enqueue({ task.run() }, capacity + 4)) { "Diagnostic commands busy; retry snapshot" }
        return task.get()
    }

    private fun drain() {
        consuming.set(true)
        try {
            while (true) {
                val next = synchronized(lock) {
                    if (mailbox.isEmpty()) {
                        draining = false
                        null
                    } else mailbox.removeFirst()
                } ?: return
                try {
                    next()
                } catch (_: Exception) {
                    // A failed diagnostic record must not stop future records
                    // or leave freeze blocked. Export the failure count.
                    failed.incrementAndGet()
                }
            }
        } finally {
            consuming.remove()
        }
    }
}
