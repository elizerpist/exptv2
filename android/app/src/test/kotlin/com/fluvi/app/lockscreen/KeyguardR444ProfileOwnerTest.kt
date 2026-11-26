package com.fluvi.app.lockscreen

import org.junit.Assert.*
import org.junit.Test

class KeyguardR444ProfileOwnerTest {
    private class Fixture(initial: Int = 0x10) {
        var flags: Int? = initial
        var pending: Boolean? = false
        var writeWorks = true
        val owner = KeyguardR444ProfileOwner(2, { flags }, { value ->
            if (writeWorks) { flags = value; true } else false
        }, { pending }, { value -> pending = value; true })
    }

    @Test fun restoreOnlyOwnedBitAndKeepConcurrentFlags() {
        val f = Fixture()
        assertTrue(f.owner.recover())
        assertTrue(f.owner.start(true))
        val active = f.owner.snapshot
        assertEquals(0x12, f.flags)
        assertTrue(active.changedByUs)
        f.flags = 0x32
        assertTrue(f.owner.stop())
        assertEquals(0x30, f.flags)
        assertEquals(false, f.pending)
        assertTrue(f.owner.snapshot.revision > active.revision)
    }

    @Test fun alreadyIncludedBitIsNeverClaimedOrCleared() {
        val f = Fixture(0x12)
        assertTrue(f.owner.recover())
        assertTrue(f.owner.start(true))
        assertFalse(f.owner.snapshot.changedByUs)
        assertTrue(f.owner.stop())
        assertEquals(0x12, f.flags)
        assertTrue(f.owner.start(false))
        assertEquals(KeyguardR444ProfileOwner.Kind.STANDARD_ALREADY_INCLUDED, f.owner.snapshot.kind)
    }

    @Test fun failedReadbackLeavesRecoveryObligationAndNoAuthority() {
        val f = Fixture()
        assertTrue(f.owner.recover())
        f.writeWorks = false
        assertFalse(f.owner.start(true))
        assertEquals(KeyguardR444ProfileOwner.Kind.ERROR, f.owner.snapshot.kind)
        assertFalse(f.owner.snapshot.expandedPolicy)
        f.writeWorks = true
        assertTrue(f.owner.recover())
        assertEquals(0x10, f.flags)
        assertEquals(false, f.pending)
    }

    @Test fun missingReadbackAfterSetRestoresAndInvalidatesTheRevision() {
        var flags = 0x10
        var pending = false
        var failOnce = false
        val owner = KeyguardR444ProfileOwner(2,
            { if (failOnce) { failOnce = false; null } else flags },
            { value -> flags = value; if (value and 2 != 0) failOnce = true; true },
            { pending }, { pending = it; true })
        assertTrue(owner.recover())
        val before = owner.snapshot.revision
        assertFalse(owner.start(true))
        assertEquals(0x10, flags)
        assertFalse(pending)
        assertFalse(owner.snapshot.expandedPolicy)
        assertTrue(owner.snapshot.revision > before)
    }

    @Test fun stopWithoutACaptureIsIdempotentAndFencesOldCallbacks() {
        val f = Fixture()
        assertTrue(f.owner.recover())
        assertTrue(f.owner.start(true))
        val stale = f.owner.snapshot.revision
        assertTrue(f.owner.stop())
        assertTrue(f.owner.stop())
        assertNotEquals(stale, f.owner.snapshot.revision)
        assertEquals(0x10, f.flags)
        assertEquals(false, f.pending)
    }

    @Test fun lostBinderKeepsRecoveryMarkerAcrossOwnerRecreation() {
        val f = Fixture()
        assertTrue(f.owner.recover())
        assertTrue(f.owner.start(true))
        f.flags = null
        assertFalse(f.owner.stop())
        assertEquals(true, f.pending)
        f.flags = 0x52
        val replacement = KeyguardR444ProfileOwner(2, { f.flags }, { f.flags = it; true },
            { f.pending }, { f.pending = it; true })
        assertTrue(replacement.recover())
        assertEquals(0x50, f.flags)
        assertEquals(false, f.pending)
    }
}
