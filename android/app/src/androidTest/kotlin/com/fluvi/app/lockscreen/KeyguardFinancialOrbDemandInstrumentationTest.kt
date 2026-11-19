package com.fluvi.app.lockscreen

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Shader
import android.util.Log
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.fluvi.app.runtime.FluviFinancialCardPresenter
import com.fluvi.app.runtime.FluviFinancialOrbPaintTestHook
import com.fluvi.app.runtime.FluviLockScreenCardContent
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicReference

/** Real Android Bitmap controls; the same old public entry points run on stock and candidate. */
@RunWith(AndroidJUnit4::class)
class KeyguardFinancialOrbDemandInstrumentationTest {
    private val paints = AtomicInteger()
    private fun fixture(color: Int = Color.rgb(210, 72, 43)) = FluviLockScreenCardContent(
        focus = "focus", primary = "123", secondary = "secondary", event = "event",
        eventLabel = "label", accentColor = color, available = true,
    )

    @Before fun armActualPainter() {
        paints.set(0)
        FluviFinancialOrbPaintTestHook.onPaint = { paints.incrementAndGet() }
    }

    @After fun clearActualPainter() { FluviFinancialOrbPaintTestHook.onPaint = null }

    @Test fun constructionAndFirstDemandCountActualPaints() {
        val content = fixture()
        val presentations = (1..32).map { FluviFinancialCardPresenter.full(content, false) }
        val loading = FluviFinancialCardPresenter.loading()
        val unavailable = FluviFinancialCardPresenter.unavailable("missingCategory")
        val discreet = FluviFinancialCardPresenter.discreet()
        val constructedPaints = paints.get()
        Log.i("R13FinancialOrb", "scope=construction full=32 other=3 actualPaints=$constructedPaints")
        assertEquals("real presentation construction must not paint", 0, constructedPaints)
        val first = presentations.first().orb
        assertEquals(1, paints.get())
        assertSame(first, presentations.first().orb)
        assertEquals(1, paints.get())
        assertTrue(loading.full)
        assertTrue(unavailable.full)
        assertFalse(discreet.full)
    }

    @Test fun concurrentFirstReadersShareOneRealBitmap() {
        val presentation = FluviFinancialCardPresenter.full(fixture(), true)
        val ready = CountDownLatch(2)
        val start = CountDownLatch(1)
        val done = CountDownLatch(2)
        val first = AtomicReference<Bitmap>()
        val second = AtomicReference<Bitmap>()
        val failure = AtomicReference<Throwable>()
        fun reader(target: AtomicReference<Bitmap>) = Thread {
            try {
                ready.countDown()
                check(start.await(5, TimeUnit.SECONDS))
                target.set(presentation.orb)
            } catch (error: Throwable) { failure.compareAndSet(null, error) }
            finally { done.countDown() }
        }.also { it.start() }
        reader(first); reader(second)
        try {
            assertTrue(ready.await(5, TimeUnit.SECONDS))
            start.countDown()
            assertTrue(done.await(10, TimeUnit.SECONDS))
            failure.get()?.let { throw AssertionError("concurrent reader failed", it) }
            assertSame(first.get(), second.get())
            assertEquals(1, paints.get())
            assertEquals(96, first.get().width)
        } finally { start.countDown() }
    }

    @Test fun demandPreservesIndependentReferencePixelsAndSemanticFields() {
        val colors = listOf(Color.rgb(210, 72, 43), Color.rgb(14, 155, 109))
        for (color in colors) {
            val content = fixture(color)
            for (event in listOf(false, true)) {
                val presentation = FluviFinancialCardPresenter.full(content, event)
                assertEquals("focus", presentation.focus)
                assertEquals(if (event) "event" else "123", presentation.primary)
                assertTrue(presentation.showToggle)
                assertTrue(presentation.full)
                assertTrue(presentation.visualKey.contains(color.toString()))
                val expected = reference(color)
                val actual = presentation.orb
                savePixels("full-${color.toUInt()}-event-$event-reference", expected)
                savePixels("full-${color.toUInt()}-event-$event-actual", actual)
                assertPixels(expected, actual)
            }
        }
        val neutral = Color.rgb(70, 105, 157)
        for ((label, presentation) in listOf("loading" to FluviFinancialCardPresenter.loading(),
                "unavailable" to FluviFinancialCardPresenter.unavailable("missingCategory"),
                "discreet" to FluviFinancialCardPresenter.discreet())) {
            val expected = reference(neutral)
            val actual = presentation.orb
            savePixels("$label-reference", expected)
            savePixels("$label-actual", actual)
            assertPixels(expected, actual)
        }
    }

    private fun savePixels(label: String, bitmap: Bitmap) {
        val context = androidx.test.platform.app.InstrumentationRegistry.getInstrumentation().targetContext
        val directory = java.io.File(context.filesDir, "r13-financial-pixels")
        check(directory.isDirectory || directory.mkdirs())
        java.io.File(directory, "$label.png").outputStream().use {
            check(bitmap.compress(Bitmap.CompressFormat.PNG, 100, it))
        }
    }

    private fun reference(color: Int): Bitmap {
        val image = Bitmap.createBitmap(96, 96, Bitmap.Config.ARGB_8888)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        paint.shader = LinearGradient(0f, 0f, 96f, 96f, color, Color.rgb(111, 178, 233), Shader.TileMode.CLAMP)
        Canvas(image).drawCircle(48f, 48f, 47f, paint)
        return image
    }

    private fun assertPixels(expected: Bitmap, actual: Bitmap) {
        assertEquals(96, actual.width)
        assertEquals(96, actual.height)
        assertEquals(Bitmap.Config.ARGB_8888, actual.config)
        val left = IntArray(96 * 96)
        val right = IntArray(96 * 96)
        expected.getPixels(left, 0, 96, 0, 0, 96, 96)
        actual.getPixels(right, 0, 96, 0, 0, 96, 96)
        assertEquals(0, Color.alpha(actual.getPixel(0, 0)))
        assertEquals(255, Color.alpha(actual.getPixel(48, 48)))
        assertArrayEquals(left, right)
    }
}
