package com.fluvi.app.lockscreen

import java.util.ArrayDeque
import java.util.concurrent.Executor
import org.junit.Assert.*
import org.junit.Test

class KeyguardDiagnosticQueueTest {
    private class PausedConsumer : Executor {
        val tasks = ArrayDeque<Runnable>()
        override fun execute(command: Runnable) { tasks.addLast(command) }
        fun run() { while (tasks.isNotEmpty()) tasks.removeFirst().run() }
    }

    @Test fun stoppedConsumerDoesNotBlockTheNextInspection() {
        val executor = PausedConsumer()
        val diagnostics = KeyguardDiagnosticQueue(executor, capacity = 4)
        val queue = KeyguardCardInspectionQueue()
        val first = request(1)
        val pending = request(2)
        assertTrue(queue.offer(first))
        assertFalse(queue.offer(pending))
        val reduced = mutableListOf<Long>()
        diagnostics.offer { reduced += first.id }
        val successor = queue.complete(first)
        assertEquals(pending, successor)
        // The real queue can advance; no diagnostic consumer has run.
        diagnostics.offer { reduced += pending.id }
        assertTrue(reduced.isEmpty())
        assertEquals(1, executor.tasks.size)
        executor.run()
        assertEquals(listOf(1L, 2L), reduced)
    }

    @Test fun overflowIsBoundedAndDoesNotCreateMoreWorkerTasks() {
        val executor = PausedConsumer()
        val diagnostics = KeyguardDiagnosticQueue(executor, capacity = 3)
        var reduced = 0
        repeat(1000) { diagnostics.offer { reduced += 1 } }
        assertEquals(997L, diagnostics.dropped.get())
        assertEquals(1, executor.tasks.size)
        executor.run()
        assertEquals(3, reduced)
        assertTrue(diagnostics.offer { reduced += 1 })
        executor.run()
        assertEquals(4, reduced)
    }

    @Test fun aFailedRecordDoesNotStrandTheConsumer() {
        val executor = PausedConsumer()
        val diagnostics = KeyguardDiagnosticQueue(executor)
        var finalRecord = false
        diagnostics.offer { error("injected reducer failure") }
        diagnostics.offer { finalRecord = true }
        executor.run()
        assertTrue(finalRecord)
        assertEquals(1L, diagnostics.failed.get())
    }

    private fun request(id: Long) = KeyguardCardInspectionRequest(
        id, "window", 1, 1, 1, 1, 1, id,
    )
}
