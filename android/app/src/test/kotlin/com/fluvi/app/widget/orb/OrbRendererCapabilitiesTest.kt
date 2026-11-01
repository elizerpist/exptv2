package com.fluvi.app.widget.orb

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class OrbRendererCapabilitiesTest {
    @Test
    fun `Android 15 never pretends that a RemoteViews placeholder is live material`() {
        val state = OrbRendererCapabilities.forAndroidApi(35)

        assertFalse(state.liveHeaderSupported)
        assertTrue(state.reason.contains("igazolt élő orb-renderer"))
    }

    @Test
    fun `a newer SDK without a verified launcher player remains unavailable`() {
        val state = OrbRendererCapabilities.forAndroidApi(36)

        assertFalse(state.liveHeaderSupported)
        assertTrue(state.reason.contains("launcher Remote Compose"))
    }
}
