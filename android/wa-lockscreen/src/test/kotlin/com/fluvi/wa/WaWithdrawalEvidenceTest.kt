package com.fluvi.wa

import java.util.concurrent.atomic.AtomicLong
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class WaWithdrawalEvidenceTest {
    private val evidence = WaWithdrawalEvidence()
    private val ring = WaTraceRing(10, AtomicLong())
    private val locked = WaSystemState(2, true, true)
    private val unlocked = WaSystemState(2, true, false)

    @Test fun phonePatternsRetainEveryOwnedOperationAfterLoss() {
        val ages = listOf(563, 52, 553, 51, 51)
        for ((i, age) in ages.withIndex()) {
            val id = i + 1L
            val owner = WaAttachment(7, id, id, 33, 112)
            val up = id * 1000
            val type = if (i in listOf(0, 2)) 32 else 2048
            add(WaStage.ATTACH, owner, up - 610)
            add(WaStage.ROOT_ATTACHED, owner, up - 609)
            if (i in listOf(3, 4)) {
                add(WaStage.CALLBACK, owner, up - 8, type = 32, eventUp = up - 560)
                add(WaStage.STATE_READ, owner, up - 8, type = 32, state = locked)
            }
            if (i < 3) {
                val sample = if (i == 1) unlocked else locked
                evidence.probe(owner, up - 22, (up - 22) * MS, (up - 21) * MS, sample, false, 6000L + id)
            }
            add(WaStage.CALLBACK, owner, up, type = type, eventUp = up - age)
            add(WaStage.STATE_READ, owner, up, type = type, eventUp = up - age, state = unlocked)
            add(WaStage.DECISION, owner, up + 1, received = up)
            add(WaStage.LOCAL_HIDE, owner, up + 1, hide = id)
            add(WaStage.DETACHED, owner, up + 2, hide = id)
            add(WaStage.REMOVE_RETURN, owner, up + 13, hide = id, detail = 1)
            add(WaStage.HOST_STOP_END, owner, up + 14, hide = id)
            add(WaStage.TERMINAL, owner, up + 14, hide = id)
            evidence.probe(owner, up + 16, (up + 16) * MS, (up + 17) * MS, unlocked, true, 7000L + id)
        }
        repeat(2400) { i -> add(WaStage.TERMINAL, null, i + 10000L) }
        assertTrue(ring.dropped > 2203)
        val lines = evidence.lines().lineSequence().filter { it.startsWith("WINDOW_SUMMARY ") }.toList()
        assertEquals(5, lines.size)
        for ((i, row) in lines.withIndex()) {
            val id = i + 1L
            assertTrue(row.contains("hide=$id reason=UNLOCKED"))
            assertFalse(row.contains("detach=UNOBSERVED"))
            assertFalse(row.contains("terminal=UNOBSERVED"))
            assertTrue(row.contains("crossedProbe=true"))
            val trigger = field(row, "trigger").split(',')
            assertEquals(ages[i].toLong(), trigger[1].toLong() - trigger[5].toLong())
            assertEquals(
                i == 1,
                field(row, "probeNegative").let { it != "UNOBSERVED" && it.endsWith(",2,true,false") },
            )
        }
        assertTrue(lines[3].contains("lockedControl=") && !lines[3].contains("lockedControl=UNOBSERVED"))
        assertTrue(lines[4].contains("lockedControl=") && !lines[4].contains("lockedControl=UNOBSERVED"))
        assertEquals("UNOBSERVED", field(lines[4], "probeAllowed"))
    }

    @Test fun sixSlotsSurviveOverflowAndOldServiceCompletion() {
        val owners = (1L..8L).map { WaAttachment(1, it, it, 4, 112) }
        owners.forEach {
            add(WaStage.ROOT_ATTACHED, it, it.window)
            add(WaStage.ATTACH, it, it.window)
        }
        add(WaStage.LOCAL_HIDE, owners[0], 20, hide = 7)
        add(WaStage.DETACHED, owners[0].copy(service = 2), 21, hide = 7)
        add(WaStage.EPISODE_OPEN, owners[1], 22)
        add(WaStage.TERMINAL, null, 23)
        val text = evidence.lines()
        assertTrue(text.contains("summaryWindows=6 summaryOmittedWindows=2"))
        val first = text.lines()[1]
        assertTrue(first.contains("hide=7"))
        assertEquals("UNOBSERVED", field(first, "detach"))
        assertEquals("UNOBSERVED", field(first, "terminal"))
        assertTrue(field(first, "nextWake").endsWith(",2,2"))
    }

    @Test fun frozenV1AndV2KeepExactBytesAndRejectCorruption() {
        for (magic in listOf(WA_CAPTURE_MAGIC, WA_CAPTURE_MAGIC_V2)) {
            val body = "$magic\ncapture=fixture state=FROZEN\nstartUp=1 durationMs=2345\n" +
                "observed=11 ringDrops=3\nWINDOW_SUMMARY e=1\nretained=8 textDropped=2\n"
            val text = body + "sha256=${waCaptureDigest(body)}\n"
            val parsed = WaLockscreenCapture.Frozen.parse(text)!!
            assertEquals(text, parsed.text)
            assertEquals(5, parsed.drops)
            assertNull(WaLockscreenCapture.Frozen.parse(text.replace("drops", "lost") + " "))
        }
    }

    private fun field(row: String, key: String) = row.split(' ').first { it.startsWith("$key=") }.substringAfter('=')

    private fun add(stage: WaStage, owner: WaAttachment?, up: Long, hide: Long = 0,
                    type: Int = 0, eventUp: Long = 0, received: Long = 0,
                    state: WaSystemState? = null, detail: Long = 0) {
        val row = ring.add(
            stage, WaSource.ACCESSIBILITY, owner?.service ?: 1L, owner?.episode ?: 1L, owner,
            0, hide, if (hide != 0L) WaHideReason.UNLOCKED else WaHideReason.NONE, state, null, WaBarrier.OPEN,
            up, up * MS, received, type, eventUp, detail, up * MS, allowMerge = false,
        )
        evidence.observe(row)
    }

    companion object { private const val MS = 1_000_000L }
}
