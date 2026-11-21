package com.fluvi.app.lockscreen

import android.app.Instrumentation
import android.app.UiAutomation
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.Rect
import android.os.SystemClock
import android.view.View
import android.widget.FrameLayout
import com.fluvi.app.R
import com.fluvi.app.lockscreen.material.AndroidKeyguardShaderArtifactReader
import com.fluvi.app.lockscreen.material.FluviKeyguardMaterialStore
import com.fluvi.app.lockscreen.material.KeyguardHeaderMaterialView
import com.fluvi.app.lockscreen.material.KeyguardMaterialScene
import com.fluvi.app.lockscreen.material.KeyguardMaterialTestActivity
import com.fluvi.app.lockscreen.material.KeyguardMaterialTime
import com.fluvi.app.lockscreen.material.KeyguardMaterialTimeSource
import java.io.File
import java.util.concurrent.atomic.AtomicReference
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue

/** Hardware-View reference for the same published demo material. Compositor
 * crops are sampled independently of production grants and are never used as
 * visibility authority. */
internal class KeyguardR22VisualCalibration(
    private val instrumentation: Instrumentation,
    private val directory: File,
    private val automation: UiAutomation,
) : AutoCloseable {
    data class Delta(val changed: Int, val total: Long, val max: Int) {
        fun nearlyEqual(): Boolean = max <= 2 && total <= 2048L
        fun meaningful(): Boolean = changed >= 64 && total >= 2048L
    }
    companion object {
        val timeA = KeyguardMaterialTime(1.196795f, 1.196795f, 1.196795f, 1.196795f)
        val timeC = KeyguardMaterialTime(1.5234617f, 1.5234617f, 1.5234617f, 1.5234617f)
        val timeB = KeyguardMaterialTime(3.75f, 3.75f, 3.75f, 3.75f)

        fun compare(a: Bitmap, b: Bitmap): Delta {
            require(a.width == b.width && a.height == b.height)
            var changed = 0; var total = 0L; var max = 0
            for (y in 0 until a.height) for (x in 0 until a.width) {
                val dx = x + .5f - a.width / 2f
                val dy = y + .5f - a.height / 2f
                if (dx * dx + dy * dy >= a.width * a.width * .1764f) continue
                val aa = a.getPixel(x, y); val bb = b.getPixel(x, y)
                val delta = maxOf(kotlin.math.abs(Color.red(aa) - Color.red(bb)),
                    kotlin.math.abs(Color.green(aa) - Color.green(bb)),
                    kotlin.math.abs(Color.blue(aa) - Color.blue(bb)))
                if (delta >= 7) changed += 1
                total += delta; max = maxOf(max, delta)
            }
            return Delta(changed, total, max)
        }
        private fun distance(a: Int, b: Int) = kotlin.math.abs(Color.red(a) - Color.red(b)) +
            kotlin.math.abs(Color.green(a) - Color.green(b)) + kotlin.math.abs(Color.blue(a) - Color.blue(b))
    }

    lateinit var a: Bitmap
        private set
    lateinit var b: Bitmap
        private set
    lateinit var neutral: Bitmap
        private set
    private val allocated = mutableListOf<Bitmap>()
    private val events = mutableListOf<String>()
    private fun save(label: String, bitmap: Bitmap) {
        File(directory, "$label.png").outputStream().use { check(bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)) }
    }
    private fun screenshot(): Bitmap = checkNotNull(automation.takeScreenshot())
    private fun crop(screen: Bitmap, bounds: Rect): Bitmap {
        check(bounds.left >= 0 && bounds.top >= 0 && bounds.right <= screen.width && bounds.bottom <= screen.height &&
            bounds.width() > 0 && bounds.height() > 0) { "invalid physical bounds $bounds for ${screen.width}x${screen.height}" }
        return Bitmap.createBitmap(screen, bounds.left, bounds.top, bounds.width(), bounds.height())
    }
    private fun waitUntil(label: String, timeout: Long = 8_000, check: () -> Boolean) {
        val end = SystemClock.uptimeMillis() + timeout
        while (SystemClock.uptimeMillis() < end) {
            if (check()) return
            SystemClock.sleep(25)
        }
        throw AssertionError("NOT REACHED: $label")
    }

    fun calibrate() {
        val context = instrumentation.targetContext
        val profile = checkNotNull(FluviKeyguardMaterialStore.read(context))
        val activity = instrumentation.startActivitySync(Intent(context, KeyguardMaterialTestActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) as KeyguardMaterialTestActivity
        val fixed = AtomicReference(timeA)
        val returned = AtomicReference<KeyguardMaterialTime?>()
        val size = context.resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_orb_size)
        val underlay = Color.rgb(11, 177, 67)
        lateinit var reference: KeyguardHeaderMaterialView
        try {
            val artifact = AndroidKeyguardShaderArtifactReader.load(context, profile.effectId, profile.usesPortal)
            instrumentation.runOnMainSync {
                reference = KeyguardHeaderMaterialView(activity,
                    materialTimeSource = KeyguardMaterialTimeSource { _, _ -> fixed.get().also { returned.set(it) } })
                reference.layoutParams = FrameLayout.LayoutParams(size, size).apply { leftMargin = 100; topMargin = 250 }
                reference.setScene(KeyguardMaterialScene(profile, true, 0L), enabled = true)
                reference.setBootstrapActive(false)
                assertEquals(KeyguardHeaderMaterialView.ProgramPreparationResult.COMPILED, reference.installPreparedShader(artifact))
                val root = FrameLayout(activity).apply { setBackgroundColor(underlay); addView(reference) }
                activity.setContentView(root)
                reference.frame(System.nanoTime())
            }
            waitUntil("canonical hardware View draw") {
                var ready = false
                instrumentation.runOnMainSync { ready = reference.diagnostics().lastCanvasHardwareAccelerated == true &&
                    reference.diagnostics().shaderDrawCount > 0 && reference.width == size && reference.height == size }
                ready
            }
            fun render(time: KeyguardMaterialTime, label: String, predicate: (Bitmap) -> Boolean): Bitmap {
                var previousDraw = 0
                instrumentation.runOnMainSync {
                    previousDraw = reference.diagnostics().shaderDrawCount
                    fixed.set(time)
                    reference.frame(System.nanoTime())
                }
                waitUntil("canonical $label draw") {
                    var current = 0
                    instrumentation.runOnMainSync { current = reference.diagnostics().shaderDrawCount }
                    current > previousDraw && returned.get() == time
                }
                var result: Bitmap? = null
                var lastFull: Bitmap? = null
                var lastCrop: Bitmap? = null
                var bounds = Rect()
                try {
                    waitUntil("canonical $label compositor reference") {
                        val loc = IntArray(2)
                        instrumentation.runOnMainSync { reference.getLocationOnScreen(loc) }
                        bounds = Rect(loc[0], loc[1], loc[0] + size, loc[1] + size)
                        val before = SystemClock.uptimeMillis()
                        val full = screenshot()
                        val sample = crop(full, bounds)
                        val after = SystemClock.uptimeMillis()
                        val accepted = predicate(sample)
                        events += "$label before=$before after=$after requested=$time sourceReturned=${returned.get()} bounds=$bounds corner=${sample.getPixel(0, 0)} center=${sample.getPixel(size / 2, size / 2)} accepted=$accepted"
                        if (accepted) {
                            save("reference-$label-full", full)
                            save("reference-$label", sample)
                            result = sample
                            full.recycle()
                            true
                        } else {
                            lastFull?.recycle(); lastCrop?.recycle()
                            lastFull = full; lastCrop = sample
                            false
                        }
                    }
                } catch (failure: Throwable) {
                    lastFull?.let { save("reference-$label-last-rejected-full", it) }
                    lastCrop?.let { save("reference-$label-last-rejected", it) }
                    File(directory, "reference-$label-failure.txt").writeText(
                        "requested=$time sourceReturned=${returned.get()} bounds=$bounds events=${events.takeLast(2)} failure=${failure.message}\n")
                    throw failure
                } finally { lastFull?.recycle(); lastCrop?.recycle() }
                return checkNotNull(result).also { allocated += it }
            }
            a = render(timeA, "A") { sample ->
                distance(underlay, sample.getPixel(0, 0)) <= 15 &&
                    distance(underlay, sample.getPixel(size / 2, size / 2)) > 45 &&
                    distance(Color.WHITE, sample.getPixel(size / 2, size / 2)) > 45 &&
                    distance(Color.BLACK, sample.getPixel(size / 2, size / 2)) > 45
            }
            val c = render(timeC, "C") { compare(a, it).nearlyEqual() }
            b = render(timeB, "B") { compare(a, it).meaningful() }
            val again = render(timeA, "A-return") { compare(a, it).nearlyEqual() }
            assertTrue("A/C plateau not calibrated", compare(a, c).nearlyEqual())
            assertTrue("A/B motion not calibrated", compare(a, b).meaningful())
            assertTrue("return-A not calibrated", compare(a, again).nearlyEqual())
            instrumentation.runOnMainSync {
                reference.setScene(KeyguardMaterialScene(profile.neutralized(), false, 0L), enabled = true)
                reference.frame(System.nanoTime())
            }
            SystemClock.sleep(250)
            neutral = render(timeA, "neutral") { compare(a, it).meaningful() }
            val black = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888).apply { eraseColor(Color.BLACK) }
            val green = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888).apply { eraseColor(underlay) }
            try { save("reference-black", black); save("reference-underlay", green) }
            finally { black.recycle(); green.recycle() }
            File(directory, "reference-events.txt").writeText(events.joinToString("\n", postfix = "\n"))
        } finally {
            instrumentation.runOnMainSync { activity.finish() }
            instrumentation.waitForIdleSync()
        }
    }

    /** Save every sampled full frame and matching crop with real acquisition
     * times. No recorded sample is discarded merely because it mismatched. */
    fun awaitServiceMatch(label: String, bounds: Rect, reference: Bitmap, underlay: Bitmap): Bitmap {
        assertEquals(reference.width, bounds.width())
        assertEquals(reference.height, bounds.height())
        assertEquals(reference.width, underlay.width)
        assertEquals(reference.height, underlay.height)
        var accepted: Bitmap? = null
        val details = mutableListOf<String>()
        repeat(24) { index ->
            if (accepted != null) return@repeat
            val before = SystemClock.uptimeMillis()
            val full = screenshot()
            val sample = crop(full, bounds)
            val after = SystemClock.uptimeMillis()
            try {
                val delta = compare(reference, sample)
                val points = listOf(1 to 1, sample.width - 2 to 1, 1 to sample.height - 2,
                    sample.width - 2 to sample.height - 2)
                val exterior = points.all { (x, y) -> distance(sample.getPixel(x, y), underlay.getPixel(x, y)) <= 15 }
                save("$label-$index-full", full)
                save("$label-$index-crop", sample)
                details += "index=$index before=$before after=$after bounds=$bounds delta=$delta exterior=$exterior"
                if (delta.nearlyEqual() && exterior) accepted = sample.copy(Bitmap.Config.ARGB_8888, false)
            } finally { sample.recycle(); full.recycle() }
            if (accepted == null) SystemClock.sleep(100)
        }
        File(directory, "$label-samples.txt").writeText(details.joinToString("\n", postfix = "\n"))
        return checkNotNull(accepted) { "NOT REACHED: calibrated $label compositor match" }.also { allocated += it }
    }

    fun captureCrop(label: String, bounds: Rect): Bitmap {
        val before = SystemClock.uptimeMillis()
        val full = screenshot()
        val after = SystemClock.uptimeMillis()
        try {
            save("$label-full", full)
            return crop(full, bounds).also {
                save(label, it)
                File(directory, "$label-time.txt").writeText("before=$before after=$after bounds=$bounds\n")
                allocated += it
            }
        } finally { full.recycle() }
    }

    /** Returns explicit observed categories; no callback is treated as a
     * pixel disappearance. An unclassified sample cannot pass safety. */
    fun classifyAfterExclusion(samples: List<Bitmap>, finalUnderlay: Bitmap): List<String> =
        samples.map { sample ->
            when {
                compare(a, sample).nearlyEqual() || compare(b, sample).nearlyEqual() -> "OLD_FULL"
                compare(neutral, sample).nearlyEqual() -> "NEUTRAL"
                compare(finalUnderlay, sample).nearlyEqual() -> "UNDERLAY"
                else -> "UNCLASSIFIED"
            }
        }

    override fun close() { allocated.forEach { if (!it.isRecycled) it.recycle() } }
}
