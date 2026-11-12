package com.fluvi.app.lockscreen

import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import java.util.ArrayDeque

/** Deterministic controls for the fixture-only terminal observation contract. */
@RunWith(AndroidJUnit4::class)
class TerminalReentryObservationInstrumentationTest {
    @Test fun acceptedObservationIsNotRequeried() {
        val keyguard = MutableKeyguard(false)
        val local = MutableLocal()
        val remote = MutableRemote()
        val collector = collector(keyguard::read, local::read, remote::read)

        val accepted = collector.collect(observationId = 1L, terminalDeadlineUptimeMs = 20L)
        assertTrue(accepted.accepted)
        assertEquals(2, keyguard.readCount)
        assertEquals(1, local.readCount)
        assertEquals(1, remote.readCount)

        keyguard.locked = true
        assertTrue("the accepted object is historical evidence", accepted.accepted)
        assertTrue(accepted.evidenceFields().contains("observationId=1"))
        assertEquals("validation/export must not query live state", 2, keyguard.readCount)
        assertEquals("validation/export must not query local ownership", 1, local.readCount)
        assertEquals("validation/export must not query remote metadata", 1, remote.readCount)

        val fresh = collector.collect(observationId = 2L, terminalDeadlineUptimeMs = 20L)
        assertFalse("a later sample must establish freshness again", fresh.accepted)
        assertEquals("keyguardLockedBefore", fresh.rejectionReason)
    }

    @Test fun relockDuringOwnedRootObservationIsRejected() {
        val values = ArrayDeque(listOf(false, true, false, false))
        val collector = collector({ values.removeFirst() }, MutableLocal()::read, { emptyList() })

        val relocked = collector.collect(observationId = 1L, terminalDeadlineUptimeMs = 20L)
        assertFalse(relocked.accepted)
        assertEquals("keyguardLockedAfter", relocked.rejectionReason)

        val later = collector.collect(observationId = 2L, terminalDeadlineUptimeMs = 20L)
        assertTrue("a separately numbered later sample may pass", later.accepted)
        assertEquals(1L, relocked.observationId)
        assertTrue(relocked.keyguardLockedAfter)
    }

    @Test fun transitionToUnlockedIsNotReusedAsStableSample() {
        val trueFalse = scriptedCollector(true, false)
        val trueTrue = scriptedCollector(true, true)

        assertFalse(trueFalse.collect(1L, 20L).accepted)
        assertFalse(trueTrue.collect(2L, 20L).accepted)
    }

    @Test fun ownedOverlayPreventsAcceptance() {
        val attached = collector({ false }, MutableLocal(serviceAttached = true)::read, { emptyList() })
        val rooted = collector({ false }, MutableLocal(rootCount = 1)::read, { emptyList() })

        assertFalse(attached.collect(1L, 20L).accepted)
        assertFalse(rooted.collect(2L, 20L).accepted)
    }

    @Test fun remoteMetadataIsRetainedWithoutWeakeningWithdrawal() {
        val remote = mutableListOf(71, 72)
        val observation = collector({ false }, MutableLocal()::read, { remote })
            .collect(observationId = 1L, terminalDeadlineUptimeMs = 20L)

        remote.clear()
        assertTrue(observation.accepted)
        assertEquals(listOf(71, 72), observation.remoteOverlayIds)
        assertFalse("remote metadata is evidence, not a locally-owned root", observation.serviceAttached)
        assertEquals(0, observation.processOverlayRootCount)
    }

    @Test fun failedAcquisitionCannotBecomeWithdrawal() {
        val collector = TerminalReentryObservationCollector(
            uptimeMillis = { 10L },
            keyguardLocked = { false },
            localObservation = { throw IllegalStateException("service disconnected") },
            remoteObservation = { TerminalReentryRemoteObservation(10L, emptyList()) },
        )

        var failure: Throwable? = null
        try {
            collector.collect(1L, 20L)
        } catch (error: Throwable) {
            failure = error
        }
        assertTrue("read failures must propagate instead of becoming an empty snapshot", failure is IllegalStateException)
        assertEquals("service disconnected", failure?.message)
    }

    @Test fun sampleFinishingAfterDeadlineCannotPass() {
        val clock = ScriptedClock(10L, 11L, 12L, 13L)
        val collector = TerminalReentryObservationCollector(
            uptimeMillis = clock::now,
            keyguardLocked = { false },
            localObservation = { TerminalReentryLocalObservation(clock.now(), false, 0) },
            remoteObservation = { TerminalReentryRemoteObservation(clock.now(), emptyList()) },
        )

        val observation = collector.collect(observationId = 1L, terminalDeadlineUptimeMs = 12L)
        assertFalse(observation.accepted)
        assertEquals("finishedAfterDeadline", observation.rejectionReason)
        assertEquals(13L, observation.finishedAtUptimeMs)
    }

    private fun scriptedCollector(before: Boolean, after: Boolean): TerminalReentryObservationCollector {
        val values = ArrayDeque(listOf(before, after))
        return collector({ values.removeFirst() }, MutableLocal()::read, { emptyList() })
    }

    private fun collector(
        keyguard: () -> Boolean,
        local: () -> TerminalReentryLocalObservation,
        remote: () -> List<Int>,
    ): TerminalReentryObservationCollector = TerminalReentryObservationCollector(
        uptimeMillis = { 10L },
        keyguardLocked = keyguard,
        localObservation = local,
        remoteObservation = { TerminalReentryRemoteObservation(10L, remote().toList()) },
    )

    private class MutableKeyguard(var locked: Boolean) {
        var readCount = 0
        fun read(): Boolean {
            readCount += 1
            return locked
        }
    }

    private class MutableLocal(
        private val serviceAttached: Boolean = false,
        private val rootCount: Int = 0,
    ) {
        var readCount = 0
        fun read(): TerminalReentryLocalObservation {
            readCount += 1
            return TerminalReentryLocalObservation(10L, serviceAttached, rootCount)
        }
    }

    private class MutableRemote(private val ids: List<Int> = emptyList()) {
        var readCount = 0
        fun read(): List<Int> {
            readCount += 1
            return ids
        }
    }

    private class ScriptedClock(private vararg val values: Long) {
        private var index = 0
        fun now(): Long = values[(index++).coerceAtMost(values.lastIndex)]
    }
}
