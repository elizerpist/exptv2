package com.fluvi.app.lockscreen

import org.junit.Assert.*
import org.junit.Test

class KeyguardDrawPublicationTest {
    @Test fun twoDrawnAttachmentsPublishBothStagesButKeepCycleFirst() {
        val publisher = KeyguardDrawPublication()
        val published = mutableListOf<String>()
        for (attach in 1L..2L) {
            val identity = KeyguardDrawIdentity(1, 5, attach)
            publisher.attach(identity)
            for (stage in KeyguardDrawPublication.Stage.values()) {
                assertTrue(publisher.record(identity, stage, attach * 100 + stage.ordinal) {
                    published += "$attach:$stage"
                })
            }
            publisher.detach()
        }
        assertEquals(listOf("1:ROOT", "1:SHADER", "2:ROOT", "2:SHADER"), published)
        assertEquals(100L, publisher.firstRootAt)
        assertEquals(101L, publisher.firstShaderAt)
    }

    @Test fun removedSecondAttachmentDoesNotInventDraws() {
        val publisher = KeyguardDrawPublication()
        val first = KeyguardDrawIdentity(1, 5, 1)
        var publications = 0
        publisher.attach(first)
        publisher.record(first, KeyguardDrawPublication.Stage.ROOT, 100) { publications++ }
        publisher.detach()
        publisher.attach(first.copy(attach = 2))
        publisher.detach()
        assertEquals(1, publications)
        assertEquals(100L, publisher.firstRootAt)
        assertNull(publisher.firstShaderAt)
    }

    @Test fun staleCancelledAndDuplicateCallbacksNeverPublish() {
        val publisher = KeyguardDrawPublication()
        val old = KeyguardDrawIdentity(1, 5, 1)
        val next = old.copy(attach = 2)
        var publications = 0
        fun draw(identity: KeyguardDrawIdentity, at: Long) = publisher.record(
            identity, KeyguardDrawPublication.Stage.SHADER, at,
        ) { publications++ }
        publisher.attach(old)
        publisher.detach()
        assertFalse(draw(old, 90))
        publisher.attach(next)
        assertFalse(draw(old, 91))
        assertFalse(draw(next.copy(session = 2), 92))
        assertFalse(draw(next.copy(wake = 6), 93))
        assertTrue(draw(next, 110))
        assertFalse(draw(next, 111))
        publisher.attach(next) // idempotent same-owner activation
        assertFalse(draw(next, 112))
        assertEquals(1, publications)
        assertEquals(110L, publisher.firstShaderAt)
        val newWake = KeyguardDrawPublication()
        newWake.attach(next.copy(wake = 6))
        assertFalse(newWake.record(next, KeyguardDrawPublication.Stage.ROOT, 113) { publications++ })
        assertNull(newWake.firstRootAt)
    }
}
