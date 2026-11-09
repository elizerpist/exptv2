package com.fluvi.app.lockscreen.material

import android.app.Instrumentation
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.view.PixelCopy
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.fluvi.app.lockscreen.KeyguardCardAnimationMode
import com.fluvi.app.lockscreen.KeyguardCardContentOverflow
import com.fluvi.app.lockscreen.keyguardCardWindowParameters
import com.fluvi.app.lockscreen.resolveKeyguardCardGeometry
import com.fluvi.app.R
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
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
    @Test fun preparedProductionViewDoesNoAssetOrCompileWorkAcrossFrames() {
        assumeTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val activity = instrumentation.startActivitySync(
            Intent(instrumentation.targetContext, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        lateinit var view: KeyguardHeaderMaterialView
        var controller: KeyguardCardMaterialController? = null
        val artifactLoads = AtomicInteger(0)
        try {
            instrumentation.runOnMainSync {
                view = KeyguardHeaderMaterialView(activity).apply {
                    layoutParams = FrameLayout.LayoutParams(160, 160)
                }
                val background = KeyguardHeaderMaterialView(activity)
                val reader = KeyguardShaderArtifactReader { context, effectId, usesPortal ->
                    artifactLoads.incrementAndGet()
                    AndroidKeyguardShaderArtifactReader.load(context, effectId, usesPortal)
                }
                controller = KeyguardCardMaterialController(
                    view, background, View(activity),
                    artifacts = KeyguardShaderArtifactStore(activity, reader),
                )
                controller!!.update(
                    profile = profile(), animationMode = KeyguardCardAnimationMode.ORB_ONLY,
                    presentationMode = com.fluvi.app.lockscreen.KeyguardCardPresentationMode.ORB,
                    isFull = true, staticOrb = null,
                )
                activity.setContentView(FrameLayout(activity).apply { addView(view) })
                controller!!.onAttached()
            }
            assertTrue("prepared view never reached a shader draw", waitForRenderer(instrumentation, view))
            val before = view.diagnostics()
            val loadsBeforeFrames = artifactLoads.get()
            instrumentation.runOnMainSync {
                val canvas = Canvas(Bitmap.createBitmap(160, 160, Bitmap.Config.ARGB_8888))
                repeat(120) { view.draw(canvas) }
            }
            val after = view.diagnostics()
            assertEquals(loadsBeforeFrames, artifactLoads.get())
            assertEquals(before.shaderCompileAttempts, after.shaderCompileAttempts)
            assertEquals(0, after.assetOpenCountDuringDraw)
            assertEquals(0, after.metadataParseCountDuringDraw)
            assertEquals(0, after.shaderCompileCountDuringDraw)
            assertTrue(after.phaseAdvanceCount >= before.phaseAdvanceCount)
        } finally {
            instrumentation.runOnMainSync {
                controller?.dispose()
                activity.finish()
            }
        }
    }

    @Test fun identicalMaterialInputDoesNotReplaceTheRetainedScene() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val activity = instrumentation.startActivitySync(
            Intent(instrumentation.targetContext, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        try {
            instrumentation.runOnMainSync {
                val controller = KeyguardCardMaterialController(
                    KeyguardHeaderMaterialView(activity),
                    KeyguardHeaderMaterialView(activity),
                    View(activity),
                )
                repeat(10) {
                    controller.update(
                        profile = profile(),
                        animationMode = KeyguardCardAnimationMode.ORB_ONLY,
                        presentationMode = com.fluvi.app.lockscreen.KeyguardCardPresentationMode.ORB,
                        isFull = true,
                        staticOrb = null,
                    )
                }
                val same = controller.diagnostics()
                assertEquals(1, same.configurationUpdateCount)
                assertEquals(9, same.configurationNoOpCount)
                controller.update(
                    profile = profile(),
                    animationMode = KeyguardCardAnimationMode.ORB_ONLY,
                    presentationMode = com.fluvi.app.lockscreen.KeyguardCardPresentationMode.ORB,
                    isFull = false,
                    staticOrb = null,
                )
                assertEquals(2, controller.diagnostics().configurationUpdateCount)
                controller.dispose()
            }
        } finally {
            instrumentation.runOnMainSync { activity.finish() }
        }
    }

    @Test fun productionKeyguardCardHasOneFixedMeasuredWindowExtent() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val activity = instrumentation.startActivitySync(
            Intent(instrumentation.targetContext, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        try {
            instrumentation.runOnMainSync {
                val resources = activity.resources
                val height = resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_card_height)
                val geometry = resolveKeyguardCardGeometry(
                    displayWidthPx = (392 * resources.displayMetrics.density).toInt(),
                    density = resources.displayMetrics.density,
                    heightPx = height,
                    verticalOffsetDp = 0,
                )
                assertEquals(height, keyguardCardWindowParameters(geometry).height)
                val narrow = resolveKeyguardCardGeometry(
                    displayWidthPx = (200 * resources.displayMetrics.density).toInt(),
                    density = resources.displayMetrics.density,
                    heightPx = height,
                    verticalOffsetDp = 0,
                )
                assertEquals(
                    (200 * resources.displayMetrics.density).toInt() -
                        (16 * resources.displayMetrics.density).toInt() * 2,
                    narrow.width,
                )

                // These cover every presentation and material state that can
                // change visibility.  They are measured inside the same fixed
                // parent extent used by the real WindowManager window.
                listOf(
                    CardState("loading", false, false, "Betöltés", "…", ""),
                    CardState("discreet", false, false, "Fluvi", "Rejtett", ""),
                    CardState("full", true, true, "Balance · Hónap", "+15 200 Ft", "Hónap nettó"),
                    CardState("last-item", true, true, "Balance · Hónap", "+15 200 Ft", "Hónap nettó"),
                    CardState("no-data", false, false, "Balance", "Nincs adat", "Frissítés után megjelenik"),
                    CardState("content-error", false, false, "Balance", "Nem elérhető", "Próbáld újra az appban"),
                    CardState("orb-only", false, false, "Balance", "+15 200 Ft", "Hónap nettó"),
                    CardState("orb-and-background", false, false, "Balance", "+15 200 Ft", "Hónap nettó"),
                    CardState("animation-off", false, false, "Balance", "+15 200 Ft", "Hónap nettó"),
                ).forEach { state ->
                    val card = inflatedCard(activity)
                    populate(card, state)
                    measureFromXmlDefinition(card, geometry.width, height)
                    assertCardExtent(card, height, state.name)
                    measureInWindowParent(card, geometry.width, height)
                    assertCardExtent(card, height, state.name)
                    assertNoReservedAreaOverlap(card, state.name)
                }

                // Font scaling remains enabled. The two optional lines yield
                // in priority order rather than changing the card extent or
                // wrapping the primary value.
                val largeTextContext = activity.createConfigurationContext(
                    Configuration(resources.configuration).apply { fontScale = 2f },
                )
                val longCard = inflatedCard(largeTextContext)
                populate(
                    longCard,
                    CardState(
                        "large-text",
                        true,
                        true,
                        "Balance · Hónap · nagyon hosszú fókuszcímke",
                        "+15 200 000 Ft nagyon hosszú elsődleges érték",
                        "Hosszú másodlagos magyarázó sor",
                    ),
                )
                measureFromXmlDefinition(longCard, geometry.width, height)
                assertCardExtent(longCard, height, "large-text")
                measureInWindowParent(longCard, geometry.width, height)
                KeyguardCardContentOverflow.fit(longCard)
                measureInWindowParent(longCard, geometry.width, height)
                KeyguardCardContentOverflow.fit(longCard)
                measureInWindowParent(longCard, geometry.width, height)
                assertCardExtent(longCard, height, "large-text")
                assertNoReservedAreaOverlap(longCard, "large-text")
            }
        } finally {
            instrumentation.runOnMainSync { activity.finish() }
        }
    }

    @Test fun productionAssetCompilesAndDrawsOnHardwareCanvas() {
        assumeTrue(Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        // Every generated, packaged production effect program must construct.
        // This catches a strict-SkSL program-size or syntax regression in a
        // less-common Header effect before the selected profile reaches a
        // physical lockscreen.
        KeyguardMaterialProfile.effectIds.forEach { effectId ->
            KeyguardHeaderShader(context, effectId, false)
        }

        lateinit var view: KeyguardHeaderMaterialView
        var controller: KeyguardCardMaterialController? = null
        val activity = instrumentation.startActivitySync(
            // startActivitySync launches in the target application. This
            // debug-only host is consequently declared in src/debug rather
            // than in the instrumentation APK's manifest.
            Intent(context, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        try {
            instrumentation.runOnMainSync {
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
                controller!!.update(
                    profile = profile(),
                    animationMode = KeyguardCardAnimationMode.ORB_ONLY,
                    isFull = true,
                    staticOrb = null,
                )
                activity.setContentView(root)
                controller!!.onAttached()
            }
            assertTrue("production View never reached a hardware Canvas", waitForRenderer(instrumentation, view))
            instrumentation.waitForIdleSync()
            val first = copyWindow(instrumentation, activity)
            // PixelCopy can return the same already-composited buffer once
            // even while the retained renderer has advanced. Sample a short
            // run rather than turning one stale copy into a shader failure.
            val observedMotion = (1..5).any {
                Thread.sleep(220)
                first.sameAs(copyWindow(instrumentation, activity)).not()
            }
            val diagnostics = view.diagnostics()
            assertTrue(diagnostics.lastCanvasHardwareAccelerated == true)
            assertTrue("production shader did not draw", diagnostics.shaderDrawCount > 0)
            assertTrue("retained controller did not advance phase", diagnostics.phaseAdvanceCount > 0)
            assertTrue("production shader produced no motion across five samples", observedMotion)
        } finally {
            instrumentation.runOnMainSync {
                controller?.onDetached("test")
                activity.finish()
            }
        }
    }

    private fun copyWindow(instrumentation: Instrumentation, activity: KeyguardMaterialTestActivity): Bitmap {
        val copied = CountDownLatch(1)
        var result = PixelCopy.ERROR_UNKNOWN
        lateinit var bitmap: Bitmap
        instrumentation.runOnMainSync {
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
        instrumentation: Instrumentation,
        view: KeyguardHeaderMaterialView,
    ): Boolean {
        val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(8)
        while (System.nanoTime() < deadline) {
            var ready = false
            instrumentation.runOnMainSync { ready = view.diagnostics().lastCanvasHardwareAccelerated == true }
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

    private data class CardState(
        val name: String,
        val eventVisible: Boolean,
        val toggleVisible: Boolean,
        val focus: String,
        val primary: String,
        val secondary: String,
    )

    private fun inflatedCard(context: android.content.Context): View {
        // Supplying the real parent type makes Android parse the root's
        // layout_height into FrameLayout.LayoutParams. Inflating against null
        // would discard that production XML contract before measurement.
        val parent = FrameLayout(context)
        return LayoutInflater.from(context).inflate(R.layout.fluvi_keyguard_card, parent, false)
    }

    private fun populate(card: View, state: CardState) {
        card.findViewById<android.widget.TextView>(R.id.fluvi_financial_snapshot_focus).text = state.focus
        card.findViewById<android.widget.TextView>(R.id.fluvi_financial_snapshot_primary).text = state.primary
        card.findViewById<android.widget.TextView>(R.id.fluvi_financial_snapshot_secondary).text = state.secondary
        card.findViewById<android.widget.TextView>(R.id.fluvi_financial_snapshot_event).apply {
            text = "Utolsó tétel: rendkívül hosszú tranzakciós kategória és megjegyzés"
            visibility = if (state.eventVisible) View.VISIBLE else View.GONE
        }
        card.findViewById<android.widget.TextView>(R.id.fluvi_financial_snapshot_toggle).apply {
            text = "Utolsó tétel"
            visibility = if (state.toggleVisible) View.VISIBLE else View.GONE
        }
    }

    private fun measureInWindowParent(card: View, width: Int, height: Int) {
        (card.parent as? ViewGroup)?.removeView(card)
        val parent = FrameLayout(card.context).apply {
            addView(
                card,
                FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT,
                ),
            )
        }
        parent.measure(
            View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.EXACTLY),
        )
        parent.layout(0, 0, width, height)
    }

    private fun measureFromXmlDefinition(card: View, width: Int, height: Int) {
        (card.parent as? ViewGroup)?.removeView(card)
        val parent = FrameLayout(card.context).apply { addView(card) }
        parent.measure(
            View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(height * 3, View.MeasureSpec.AT_MOST),
        )
        parent.layout(0, 0, width, parent.measuredHeight)
    }

    private fun assertCardExtent(card: View, expectedHeight: Int, label: String) {
        assertEquals("$label root height", expectedHeight, card.measuredHeight)
        assertEquals(
            "$label material background height",
            expectedHeight,
            card.findViewById<View>(R.id.fluvi_keyguard_material_background).measuredHeight,
        )
        assertEquals(
            "$label veil height",
            expectedHeight,
            card.findViewById<View>(R.id.fluvi_keyguard_material_veil).measuredHeight,
        )
    }

    private fun assertNoReservedAreaOverlap(card: View, label: String) {
        val orb = card.findViewById<View>(R.id.fluvi_financial_snapshot_orb)
        val toggle = card.findViewById<View>(R.id.fluvi_financial_snapshot_toggle)
        listOf(
            R.id.fluvi_financial_snapshot_focus,
            R.id.fluvi_financial_snapshot_primary,
            R.id.fluvi_financial_snapshot_secondary,
        ).map { card.findViewById<View>(it) }
            .filter { it.visibility == View.VISIBLE }
            .forEach { text ->
                assertTrue("$label text reached orb", text.right <= orb.left)
            }
        val event = card.findViewById<View>(R.id.fluvi_financial_snapshot_event)
        if (event.visibility == View.VISIBLE && toggle.visibility == View.VISIBLE) {
            assertTrue("$label event reached toggle", event.right <= toggle.left)
        }
        if (event.visibility == View.VISIBLE) {
            val secondary = card.findViewById<View>(R.id.fluvi_financial_snapshot_secondary)
            assertTrue("$label event overlaps secondary", event.top >= secondary.bottom)
        }
        assertTrue("$label orb and toggle overlap", orb.bottom <= toggle.top || toggle.bottom <= orb.top)
    }
}
