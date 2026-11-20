package com.fluvi.app.lockscreen

import android.content.Intent
import android.content.pm.ActivityInfo
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.Rect
import android.os.Build
import android.os.SystemClock
import android.view.Gravity
import android.widget.FrameLayout
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.fluvi.app.R
import com.fluvi.app.lockscreen.material.KeyguardMaterialProfile
import com.fluvi.app.lockscreen.material.KeyguardMaterialTestActivity
import com.fluvi.app.lockscreen.material.KeyguardOrbSurfacePresenter
import com.fluvi.app.lockscreen.material.KeyguardOrbSurfaceTarget
import com.fluvi.app.lockscreen.material.KeyguardOrbSurfaceWorkerTestHooks
import com.fluvi.app.lockscreen.material.KeyguardR16LayerTestHooks
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference
import org.junit.Assert.*
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

/** Real hardware SurfaceView panel controls. These are not service admission,
 * privacy-classification, release or physical-display acceptance gates. */
@RunWith(AndroidJUnit4::class)
class KeyguardR16OrbLayerRetirementInstrumentationTest {
    @Test fun ownedLayerRetiresWhileWorkerIsHeld() = heldPanel(stock = false)
    @Test fun stockHolderRetainsItsOldFrameWhileWorkerIsHeld() = heldPanel(stock = true)

    private fun heldPanel(stock: Boolean) {
        assumeTrue(Build.VERSION.SDK_INT == 35)
        val inst = InstrumentationRegistry.getInstrumentation()
        val args = InstrumentationRegistry.getArguments()
        val uuid = java.util.UUID.fromString(requireNotNull(args.getString("runUuid"))).toString()
        val source = requireNotNull(args.getString("sourceSha"))
        val harness = requireNotNull(args.getString("harnessSha"))
        val dir = File(inst.targetContext.filesDir, "keyguard-service-probe/r16/$uuid/${if (stock) "stock" else "owned"}")
        check(dir.mkdirs() || dir.isDirectory)
        val trace = StringBuilder("source=$source\nharness=$harness\nrunUuid=$uuid\nstock=$stock\n")
        fun event(value: String) { synchronized(trace) { trace.append("up=").append(SystemClock.uptimeMillis()).append(' ').append(value).append('\n') } }
        fun save(name: String, image: Bitmap) {
            File(dir, "$name.png").outputStream().use { check(image.compress(Bitmap.CompressFormat.PNG, 100, it)) }
        }
        fun difference(a: Bitmap, b: Bitmap, roi: Rect): Int {
            require(a.width == b.width && a.height == b.height && roi.left >= 0 && roi.top >= 0 && roi.right <= a.width && roi.bottom <= a.height)
            var changed = 0
            val cx = (roi.width() - 1) / 2.0; val cy = (roi.height() - 1) / 2.0
            val radius = minOf(roi.width(), roi.height()) * .42
            for (y in 0 until roi.height()) for (x in 0 until roi.width()) {
                if ((x-cx)*(x-cx)+(y-cy)*(y-cy) > radius*radius) continue
                val p = a.getPixel(roi.left+x, roi.top+y); val q = b.getPixel(roi.left+x, roi.top+y)
                if (kotlin.math.abs(Color.red(p)-Color.red(q)) > 8 || kotlin.math.abs(Color.green(p)-Color.green(q)) > 8 || kotlin.math.abs(Color.blue(p)-Color.blue(q)) > 8) changed++
            }
            return changed
        }
        val started = CountDownLatch(1); val locked = CountDownLatch(1); val release = CountDownLatch(1)
        val armed = AtomicBoolean(false); val targetRef = AtomicReference<KeyguardOrbSurfaceTarget?>()
        val failure = AtomicReference<String?>(); var activity: KeyguardMaterialTestActivity? = null
        var presenter: KeyguardOrbSurfacePresenter? = null
        var baseline: Bitmap? = null; var before: Bitmap? = null; var held: Bitmap? = null; var after: Bitmap? = null
        try {
            KeyguardR16LayerTestHooks.stockHolder = stock
            activity = inst.startActivitySync(Intent(inst.targetContext, KeyguardMaterialTestActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) as KeyguardMaterialTestActivity
            val a = activity
            lateinit var root: FrameLayout
            inst.runOnMainSync {
                a.requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
                root = FrameLayout(a).apply { setBackgroundColor(Color.rgb(8, 18, 32)) }
                a.setContentView(root)
            }
            inst.waitForIdleSync()
            baseline = requireNotNull(inst.uiAutomation.takeScreenshot()); save("baseline", baseline)
            val size = a.resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_orb_size)
            val profile = profile()
            inst.runOnMainSync {
                presenter = KeyguardOrbSurfacePresenter(a, root,
                    onFirstPosted = { _, _ -> event("FIRST_POST"); started.countDown() },
                    onFailure = { reason -> event("FAILURE $reason"); failure.set(reason) },
                    isCaptureActive = { true })
                presenter!!.show(1L, profile, full = true, live = true, width = size, height = size,
                    reporter = { observation -> event("OBS ${observation.generation} ${observation.stage} ${observation.detail}") })
            }
            assertTrue("real first producer post was not reached", started.await(30, TimeUnit.SECONDS))
            failure.get()?.let { fail("producer failure before held boundary: $it") }
            val roi = AtomicReference<Rect>()
            inst.runOnMainSync {
                val view = requireNotNull(presenter!!.surfaceForTest())
                assertTrue("real root and SurfaceView must be attached", root.isAttachedToWindow && view.isAttachedToWindow && view.holder.surface.isValid)
                val location = IntArray(2); view.getLocationOnScreen(location)
                roi.set(Rect(location[0], location[1], location[0]+view.width, location[1]+view.height))
                event("ROI ${roi.get()} view=${view.width}x${view.height}")
            }
            SystemClock.sleep(200)
            before = requireNotNull(inst.uiAutomation.takeScreenshot()); save("before", before)
            val rect = roi.get(); val initialDiff = difference(before, baseline, rect)
            event("BEFORE_INNER_DIFF $initialDiff")
            assertTrue("precondition: independently sampled orb must differ from baseline", initialDiff > size*size/10)
            KeyguardOrbSurfaceWorkerTestHooks.afterCanvasLock = { target ->
                if (target.attachment == 1L && armed.compareAndSet(true, false)) {
                    targetRef.set(target); event("WORKER_HELD generation=${target.generation} owns=${target.ownsOutput}"); locked.countDown()
                    check(release.await(12, TimeUnit.SECONDS)) { "external held-worker timeout" }
                    event("WORKER_RELEASED")
                }
            }
            armed.set(true)
            assertTrue("real worker did not reach lock boundary", locked.await(12, TimeUnit.SECONDS))
            val target = requireNotNull(targetRef.get())
            assertEquals("route must match the selected arm", !stock, target.ownsOutput)
            var retired = false
            inst.runOnMainSync { val t=SystemClock.uptimeMillis(); retired=presenter!!.revokeCurrent(hideChild=false); event("RETIRE returned=$retired duration=${SystemClock.uptimeMillis()-t}") }
            assertTrue("real retirement must return", retired)
            if (!stock) {
                val layer = requireNotNull(target.metrics).snapshot().ownedLayer
                assertTrue("the exact owned layer hide must have returned", layer.childId != 0 && layer.retireSucceeded && layer.retireEnd != null)
                event("LAYER host=${layer.hostId} child=${layer.childId} begin=${layer.retireBegin} end=${layer.retireEnd}")
            }
            SystemClock.sleep(250)
            held = requireNotNull(inst.uiAutomation.takeScreenshot()); save("held", held)
            val heldDiff = difference(held, baseline, rect); event("HELD_INNER_DIFF $heldDiff")
            if (stock) assertTrue("stock positive control must still show the old panel", heldDiff > size*size/10)
            else assertTrue("owned child should reveal the independently observed background while held", heldDiff < size*size/30)
            release.countDown(); KeyguardOrbSurfaceWorkerTestHooks.afterCanvasLock = null
            SystemClock.sleep(250)
            after = requireNotNull(inst.uiAutomation.takeScreenshot()); save("after-release", after)
            val afterDiff = difference(after, baseline, rect); event("AFTER_INNER_DIFF $afterDiff")
            if (!stock) assertTrue("late G1 completion must not reveal retired pixels", afterDiff < size*size/30)
            failure.get()?.let { fail("producer failure: $it") }
        } finally {
            release.countDown(); KeyguardOrbSurfaceWorkerTestHooks.afterCanvasLock = null
            inst.runOnMainSync { presenter?.dispose(); activity?.finish() }
            KeyguardR16LayerTestHooks.stockHolder = false
            baseline?.recycle(); before?.recycle(); held?.recycle(); after?.recycle()
            File(dir, "trace.txt").writeText(trace.toString())
        }
    }

    private fun profile(): KeyguardMaterialProfile {
        fun portal(enabled: Boolean) = mapOf("enabled" to enabled, "effectIndex" to 0, "phase" to 0.0,
            "phaseSpeed" to .2, "paletteCenterPercent" to 50.0, "paletteWindowPercent" to 68.0,
            "rotationEnabled" to false, "rotationSpeed" to 0.0, "settings" to List(12) { .2 })
        return requireNotNull(KeyguardMaterialProfile.fromMap(mapOf(
            "schemaVersion" to 1, "shaderAbiVersion" to 6, "sourceShaderHash" to KeyguardMaterialProfile.SOURCE_SHADER_HASH,
            "publisherSession" to "r16-panel", "publisherRevision" to 1L, "sceneIdentity" to "synthetic-panel",
            "effectId" to "dualTide", "effectShaderId" to 1, "phase" to .25, "elapsedSeconds" to 1.0,
            "phaseSpeed" to .4, "colors" to listOf(0xff104f7c.toInt(), 0xff62c7dc.toInt(), 0xff8366dc.toInt()),
            "stops" to listOf(0.0, .5, 1.0), "opacity" to 1.0, "paletteSplitPercent" to 50.0,
            "commonSettings" to List(40) { .2 }, "background" to portal(true), "interior" to portal(false),
            "referenceWidth" to 390.0, "referenceHeight" to 220.0)))
    }
}
