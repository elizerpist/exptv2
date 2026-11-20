package com.fluvi.app.lockscreen

import org.junit.Assert.*
import org.junit.Test

/** These are scheduler/identity controls; they do not replace Android service
 * tests for a real accessibility reader or for WMS privacy/input behavior. */
class KeyguardR18SystemSamplerTest {
    private val eligible = KeyguardSystemState(10, 11, true, true, true, true, false, true, true)
    private val authority = KeyguardInspectionAuthority(1, 2, 3, 4, 5)

    @Test fun `eligible sample queues adoption then starts reader while Main is held`() {
        val workers = ArrayDeque<() -> Unit>()
        val main = ArrayDeque<() -> Unit>()
        val trace = mutableListOf<String>()
        val sampler = KeyguardSystemStateSampler(
            reader = { KeyguardSystemStateReader { eligible } },
            worker = { workers.addLast(it) }, main = { main.addLast(it); trace += "mainPosted" },
            current = { authority }, receive = { _, _ -> trace += "mainAdopt" },
            reserveBeforeMain = { _, state ->
                assertTrue(state.eligible)
                trace += "reserved"
                { trace += "readStarted" }
            },
        )
        sampler.offer(KeyguardSystemGateRequest(1, authority, "wake", 1, 1, true, "wake"))
        workers.removeFirst().invoke()
        assertEquals(listOf("reserved", "mainPosted", "readStarted"), trace)
        assertEquals(1, main.size)
        main.removeFirst().invoke()
        assertEquals("mainAdopt", trace.last())
    }

    @Test fun `invalidation before sample completion prevents reservation`() {
        var liveAuthority = authority
        val workers = ArrayDeque<() -> Unit>()
        val main = ArrayDeque<() -> Unit>()
        var reserved = 0
        var started = 0
        val sampler = KeyguardSystemStateSampler(
            reader = { KeyguardSystemStateReader { eligible } },
            worker = { workers.addLast(it) }, main = { main.addLast(it) },
            current = { liveAuthority }, receive = { _, _ -> fail("stale sample delivered") },
            reserveBeforeMain = { _, _ -> reserved++; { started++ } },
        )
        sampler.offer(KeyguardSystemGateRequest(1, authority, "wake", 1, 1, true, "wake"))
        liveAuthority = authority.copy(visibilityEpoch = authority.visibilityEpoch + 1)
        sampler.clearPending()
        workers.removeFirst().invoke()
        main.removeFirst().invoke()
        assertEquals(0, reserved)
        assertEquals(0, started)
    }

    @Test fun `a synchronous Main adoption cannot suppress the exact reserved starter`() {
        var liveAuthority = authority
        var starts = 0
        val workers = ArrayDeque<() -> Unit>()
        val sampler = KeyguardSystemStateSampler(
            reader = { KeyguardSystemStateReader { eligible } }, worker = { workers.addLast(it) },
            main = { it() }, current = { liveAuthority },
            receive = { _, _ -> liveAuthority = authority.copy(wakeGeneration = authority.wakeGeneration + 1) },
            reserveBeforeMain = { _, _ -> { starts++ } },
        )
        sampler.offer(KeyguardSystemGateRequest(1, authority, "wake", 1, 1, true, "wake"))
        workers.removeFirst().invoke()
        assertEquals(1, starts)
    }
}
