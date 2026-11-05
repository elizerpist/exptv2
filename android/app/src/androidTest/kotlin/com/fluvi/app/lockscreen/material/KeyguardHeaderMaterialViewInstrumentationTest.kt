package com.fluvi.app.lockscreen.material

import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.widget.FrameLayout
import android.view.PixelCopy
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.fluvi.app.lockscreen.KeyguardCardAnimationMode
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * This is deliberately a production-asset smoke, not a toy AGSL string.  It
 * proves RuntimeShader construction and one actual hardware Canvas draw on
 * an API-33+ device/emulator; PixelCopy observes the window rather than a
 * software Bitmap Canvas substitute.
 */
@RunWith(AndroidJUnit4::class)
class KeyguardHeaderMaterialViewInstrumentationTest {
    @Test fun productionAssetCompilesAndDrawsOnHardwareCanvas() {
        assumeTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        // The exact generated, packaged production program must construct.
        KeyguardHeaderShader(context, "dualTide")

        lateinit var view: KeyguardHeaderMaterialView
        lateinit var controller: KeyguardCardMaterialController
        val scenario = ActivityScenario.launch(KeyguardMaterialTestActivity::class.java)
        scenario.onActivity { activity ->
            activity.window.setFormat(PixelFormat.TRANSLUCENT)
            val root = FrameLayout(activity)
            val background = KeyguardHeaderMaterialView(activity).apply {
                layoutParams = FrameLayout.LayoutParams(240, 180)
            }
            val veil = android.view.View(activity).apply {
                layoutParams = FrameLayout.LayoutParams(240, 180)
            }
            view = KeyguardHeaderMaterialView(activity).apply {
                layoutParams = FrameLayout.LayoutParams(160, 160)
            }
            root.addView(background)
            root.addView(veil)
            root.addView(view)
            controller = KeyguardCardMaterialController(view, background, veil)
            controller.update(
                profile = profile(),
                animationMode = KeyguardCardAnimationMode.ORB_ONLY,
                isFull = true,
                staticOrb = null,
            )
            activity.setContentView(root)
            controller.onAttached()
        }
        assertTrue("production View never reached a hardware Canvas", waitForRenderer(scenario, view))
        instrumentation.waitForIdleSync()
        val first = copyWindow(scenario)
        Thread.sleep(220)
        val second = copyWindow(scenario)
        val diagnostics = view.diagnostics()
        assertTrue(diagnostics.lastCanvasHardwareAccelerated == true)
        assertTrue("production shader did not draw", diagnostics.shaderDrawCount > 0)
        assertTrue("retained controller did not advance phase", diagnostics.phaseAdvanceCount > 0)
        assertTrue("two clock samples produced identical pixels", first.sameAs(second).not())
        scenario.onActivity { controller.onDetached("test") }
        scenario.close()
    }

    private fun copyWindow(scenario: ActivityScenario<KeyguardMaterialTestActivity>): Bitmap {
        val copied = CountDownLatch(1)
        var result = PixelCopy.ERROR_UNKNOWN
        lateinit var bitmap: Bitmap
        scenario.onActivity { activity ->
            val root = activity.window.decorView
            bitmap = Bitmap.createBitmap(root.width, root.height, Bitmap.Config.ARGB_8888)
            PixelCopy.request(activity.window, bitmap, { value ->
                result = value
                copied.countDown()
            }, Handler(Looper.getMainLooper()))
        }
        assertTrue("PixelCopy did not finish", copied.await(8, TimeUnit.SECONDS))
        assertEquals(PixelCopy.SUCCESS, result)
        return bitmap
    }

    private fun waitForRenderer(
        scenario: ActivityScenario<KeyguardMaterialTestActivity>,
        view: KeyguardHeaderMaterialView,
    ): Boolean {
        val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(8)
        while (System.nanoTime() < deadline) {
            var ready = false
            scenario.onActivity { ready = view.diagnostics().lastCanvasHardwareAccelerated == true }
            if (ready) return true
            Thread.sleep(32)
        }
        return false
    }

    private fun profile() = requireNotNull(
        KeyguardMaterialProfile.fromMap(
            mapOf(
                "schemaVersion" to 1,
                "shaderAbiVersion" to 6,
                "sourceShaderHash" to KeyguardMaterialProfile.SOURCE_SHADER_HASH,
                "publisherSession" to "instrumentation",
                "publisherRevision" to 1L,
                "sceneIdentity" to "instrumentation|balance|month",
                "effectId" to "dualTide",
                "effectShaderId" to 1,
                "phase" to .25,
                "elapsedSeconds" to 1.0,
                "phaseSpeed" to .4,
                "colors" to listOf(0xff104f7c.toInt(), 0xff62c7dc.toInt(), 0xff8366dc.toInt()),
                "stops" to listOf(0.0, .5, 1.0),
                "opacity" to 1.0,
                "paletteSplitPercent" to 50.0,
                "commonSettings" to List(40) { .2 },
                "background" to portal(false),
                "interior" to portal(false),
                "referenceWidth" to 390.0,
                "referenceHeight" to 220.0,
            ),
        ),
    )

    private fun portal(enabled: Boolean) = mapOf(
        "enabled" to enabled,
        "effectIndex" to 0,
        "phase" to 0.0,
        "phaseSpeed" to 0.0,
        "paletteCenterPercent" to 50.0,
        "paletteWindowPercent" to 68.0,
        "rotationEnabled" to false,
        "rotationSpeed" to 0.0,
        "settings" to List(12) { 0.0 },
    )
}
