package com.fluvi.app.widget.orb

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class OrbRendererCapabilitiesTest {
    @Test
    fun `Android 15 exposes the standard ViewFlipper compatibility backend`() {
        val state = OrbRendererCapabilities.forAndroidApi(35)

        assertTrue(state.liveHeaderSupported)
        assertEquals("remoteviews-flutter-material-v2", state.backend)
        assertTrue(state.reason.contains("ViewFlipper"))
        assertTrue(!state.isShaderIdentical)
    }

    @Test
    fun `the finite transport plan falls back below the conservative RemoteViews budget`() {
        assertTrue(OrbCompatibilityFrameRenderer.requestedPlan.estimatedRawBytes > 700L * 1024L)
        assertTrue(OrbCompatibilityFrameRenderer.activePlan.estimatedRawBytes <= 700L * 1024L)
        assertEquals(24, OrbCompatibilityFrameRenderer.activePlan.frameCount)
        assertEquals(80, OrbCompatibilityFrameRenderer.activePlan.intervalMs)
    }

    @Test
    fun `higher density cell keeps the orb sharp while reducing frame count within budget`() {
        val plan = OrbCompatibilityFrameRenderer.planFor(180)

        assertEquals(96, plan.sizePx)
        assertTrue(plan.frameCount in 12..31)
        assertTrue(plan.estimatedRawBytes <= 700L * 1024L)
    }

    @Test
    fun `old unsupported API remains explicitly unavailable`() {
        val state = OrbRendererCapabilities.forAndroidApi(23)

        assertTrue(!state.liveHeaderSupported)
        assertEquals("unsupported", state.backend)
    }

    @Test
    fun `material profile identifies the Flutter-header frame source`() {
        val profile = OrbCompatibilityVisualProfile(
            configurationRevision = 7,
            mode = FluviOrbConfiguration.Mode.balance,
            timeAxis = FluviOrbConfiguration.TimeAxis.month,
            direction = FluviOrbConfiguration.Direction.expense,
            ghostFilter = FluviOrbConfiguration.GhostFilter.both,
            categoryId = null,
            paletteIndex = 0,
            paletteVariant = 1,
            palettePositionPercent = 50,
            paletteWindowWidthPercent = 15,
            colors = intArrayOf(0xff5cd6ff.toInt(), 0xffff89e9.toInt(), 0xff8cff98.toInt()),
            stops = floatArrayOf(0f, .5f, 1f),
            visualProfileRevision = 3,
        )

        assertEquals("flutter-header-material-v2", profile.effectId)
        assertTrue(profile.cacheKey.contains("flutter-header-material-v2"))
    }
}
