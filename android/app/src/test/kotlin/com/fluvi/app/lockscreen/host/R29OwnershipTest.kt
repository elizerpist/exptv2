package com.fluvi.app.lockscreen.host

import org.junit.Assert.*
import org.junit.Test

class R29OwnershipTest {
    private class MemoryStore(var saved: R29Ownership.Persisted = R29Ownership.Persisted(false, 0)) : R29Ownership.Store {
        var allowWrite = true
        override fun read() = saved
        override fun write(value: R29Ownership.Persisted): Boolean {
            if (!allowWrite) return false
            saved = value
            return true
        }
    }

    @Test fun oldOwnerMustDrainBeforeTheHostCanBeRequested() {
        val store = MemoryStore()
        val machine = R29Ownership(store)
        assertTrue(machine.appMayShow())
        val epoch = requireNotNull(machine.beginEnrollment())
        assertTrue(store.saved.suppressed)
        assertFalse(machine.appMayShow())
        assertFalse(machine.hostMayBeRequested())
        assertFalse(machine.oldOwnerDrained(epoch - 1))
        assertTrue(machine.oldOwnerDrained(epoch))
        assertTrue(machine.hostMayBeRequested())
        assertFalse(machine.appMayShow())
        assertTrue(machine.hostOwns(epoch))
    }

    @Test fun restartAndHostDeathNeverAutomaticallyRestoreOldOwner() {
        val store = MemoryStore()
        val a = R29Ownership(store)
        val epoch = requireNotNull(a.beginEnrollment())
        assertTrue(a.oldOwnerDrained(epoch))
        assertTrue(a.hostOwns(epoch))
        a.hostUnavailable()
        assertFalse(a.appMayShow())
        assertFalse(a.hostMayBeRequested())
        val restarted = R29Ownership(store)
        assertFalse(restarted.appMayShow())
        assertFalse(restarted.hostMayBeRequested())
        assertTrue(restarted.oldOwnerDrained(epoch))
    }

    @Test fun onlyMatchingHostEmptyAckCanPersistStockFallback() {
        val store = MemoryStore()
        val machine = R29Ownership(store)
        val epoch = requireNotNull(machine.beginEnrollment())
        machine.oldOwnerDrained(epoch)
        machine.hostOwns(epoch)
        assertEquals(epoch, machine.beginExit())
        assertFalse(machine.appMayShow())
        assertFalse(machine.hostConfirmedEmpty(epoch + 1))
        store.allowWrite = false
        assertFalse(machine.hostConfirmedEmpty(epoch))
        assertTrue(store.saved.suppressed)
        assertFalse(machine.appMayShow())
        store.allowWrite = true
        assertTrue(machine.hostConfirmedEmpty(epoch))
        assertFalse(store.saved.suppressed)
        assertTrue(machine.appMayShow())
    }

    @Test fun failedEnrollmentNeverAuthorizesTheHost() {
        val store = MemoryStore().apply { allowWrite = false }
        val machine = R29Ownership(store)
        assertNull(machine.beginEnrollment())
        assertTrue(machine.appMayShow())
        assertFalse(machine.hostMayBeRequested())
    }

    @Test fun invalidPersistenceAndEpochOverflowFailClosed() {
        val invalid = R29Ownership(MemoryStore(R29Ownership.Persisted(false, 1, valid = false)))
        assertFalse(invalid.appMayShow())
        assertFalse(invalid.hostMayBeRequested())
        val overflow = R29Ownership(MemoryStore(R29Ownership.Persisted(false, Long.MAX_VALUE)))
        assertNull(overflow.beginEnrollment())
        assertFalse(overflow.hostMayBeRequested())
    }
}
