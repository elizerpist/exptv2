package com.fluvi.wa

import java.security.MessageDigest
import java.util.concurrent.atomic.AtomicLong
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class WaCaptureTraceTest {
    @Test fun reservesTerminalRowsAndHashesFrozenBodyWithinTheByteBudget() {
        val sequence = AtomicLong()
        val ordinary = WaTraceRing(900, sequence)
        val terminal = WaTraceRing(16, sequence)
        val owner = WaAttachment(123, 7, 11, 8, 56)
        terminal.write(WaStage.LOCAL_HIDE, owner, time = 1, hide = 42)
        terminal.write(WaStage.REMOVE_RETURN, owner, time = 2, hide = 42)
        for (i in 3..1000) ordinary.write(WaStage.SCAN_RESULT, owner, i.toLong())
        val header = "$WA_CAPTURE_MAGIC\nobserved=1000 ringTruncated=true\n"
        val rows = ordinary.rows() + terminal.rows()
        val (text, omitted) = waCaptureText(header, rows)
        assertEquals(98, ordinary.dropped)
        assertTrue(omitted > 0)
        assertTrue(text.toByteArray().size <= WA_CAPTURE_BYTES)
        assertTrue(text.contains("LOCAL_HIDE") && text.contains("REMOVE_RETURN") && text.contains("hide=42"))
        val end = text.lastIndexOf("\nsha256=") + 1
        val body = text.substring(0, end)
        val hash = MessageDigest.getInstance("SHA-256")
            .digest(body.toByteArray()).joinToString("") { "%02x".format(it) }
        assertEquals("sha256=$hash\n", text.substring(end))
        ordinary.write(WaStage.ATTACH, owner, 1001)
        assertFalse(text.contains(" ATTACH "))
    }

    @Test fun coalescesRepeatIngressAndPreservesOwnerChanges() {
        val ring = WaTraceRing(8, AtomicLong())
        val owner = WaAttachment(123, 7, 11, 8, 56)
        ring.write(WaStage.INGRESS, owner, time = 1, merge = true)
        ring.write(WaStage.INGRESS, owner, time = 2, merge = true)
        ring.write(WaStage.INGRESS, owner.copy(window = 12), time = 3, merge = true)
        assertEquals(3, ring.observed)
        assertEquals(1, ring.coalesced)
        assertEquals(2, ring.rows().size)
        assertTrue(ring.rows().first().line().contains("repeat=2 lastUp=2"))
    }

    private fun WaTraceRing.write(stage: WaStage, owner: WaAttachment, time: Long, hide: Long = 0, merge: Boolean = false) =
        add(stage, WaSource.WINDOW, owner.service, owner.episode, owner, time, hide, WaHideReason.SCREEN_OFF,
            WaSystemState(2, true, true), WaLockscreenScene.MAIN, WaBarrier.OPEN,
            time, time * 1_000_000, time - 1, 2048, 0, time, time + 1, merge)
}
