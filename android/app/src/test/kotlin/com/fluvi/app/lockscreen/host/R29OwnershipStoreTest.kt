package com.fluvi.app.lockscreen.host

import android.content.Context
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class R29OwnershipStoreTest {
    private val context get() = RuntimeEnvironment.getApplication()
    private fun clear() { context.getSharedPreferences(R29OwnershipStore.PREFS, Context.MODE_PRIVATE).edit().clear().commit() }
    @Before fun before() = clear()
    @After fun after() = clear()

    @Test fun freshInstallAllowsStockAndRestartRetainsSuppressedEpoch() {
        val first = R29Ownership(R29OwnershipStore(context))
        assertTrue(first.appMayShow())
        assertEquals(1L, first.beginEnrollment())
        val restarted = R29Ownership(R29OwnershipStore(context))
        assertEquals(1L, restarted.epoch())
        assertFalse(restarted.appMayShow())
        assertFalse(restarted.hostMayBeRequested())
        assertFalse(restarted.oldOwnerDrained(2L))
    }

    @Test fun tornOrWrongTypeStateFailsClosed() {
        context.getSharedPreferences(R29OwnershipStore.PREFS, Context.MODE_PRIVATE).edit()
            .putInt(R29OwnershipStore.VERSION, 1)
            .putBoolean(R29OwnershipStore.SUPPRESSED, false)
            .putString(R29OwnershipStore.EPOCH, "1")
            .commit()
        val restored = R29Ownership(R29OwnershipStore(context))
        assertEquals(R29Ownership.Phase.BLOCKED, restored.phase())
        assertFalse(restored.appMayShow())
        assertFalse(restored.hostMayBeRequested())
    }
}
