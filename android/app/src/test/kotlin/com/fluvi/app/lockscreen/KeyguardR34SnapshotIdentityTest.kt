package com.fluvi.app.lockscreen

import org.junit.Assert.*
import org.junit.Test

class KeyguardR34SnapshotIdentityTest {
    private data class Snapshot(val route: String, val scene: Long, val owner: Any)
    private fun publish(old: Snapshot?, next: Snapshot?) = KeyguardR34SnapshotIdentity.publish(old, next) { a, b ->
        a.route == b.route && a.scene == b.scene && a.owner === b.owner
    }

    @Test fun equalRepublishRetainsReservationButInterveningSceneDoesNot() {
        val owner = Any()
        val a1 = Snapshot("A", 10, owner)
        assertSame(a1, publish(a1, Snapshot("A", 10, owner)))
        val b = checkNotNull(publish(a1, Snapshot("B", 11, owner)))
        val a2 = checkNotNull(publish(b, Snapshot("A", 12, owner)))
        assertNotSame(a1, a2)
        assertNotSame(a1, publish(a1, Snapshot("A", 10, Any())))
        assertNull(publish(a1, null))
        assertNotSame(a1, publish(null, Snapshot("A", 10, owner)))
    }
}
