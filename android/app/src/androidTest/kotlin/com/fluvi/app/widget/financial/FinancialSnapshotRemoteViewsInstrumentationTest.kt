package com.fluvi.app.widget.financial

import android.appwidget.AppWidgetManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Shader
import android.graphics.drawable.BitmapDrawable
import android.view.View
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.RemoteViews
import android.widget.TextView
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.fluvi.app.R
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/** Exercises the provider’s real RemoteViews and its painter. */
@RunWith(AndroidJUnit4::class)
class FinancialSnapshotRemoteViewsInstrumentationTest {
    @Test fun remoteViewsKeepRealPixelsAndText() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        val content = FinancialSnapshotContent("focus", "123 Ft", "secondary", "event", "label",
            Color.rgb(210, 72, 43), true)
        val full = FluviFinancialSnapshotWidgetConfiguration(categoryId = "test-category",
            privacy = FinancialSnapshotFocus.Privacy.full)
        val discreet = full.copy(privacy = FinancialSnapshotFocus.Privacy.discreet)
        val method = FluviFinancialSnapshotWidgetProvider.Companion.javaClass.declaredMethods.single { it.name == "remoteViews" }
        method.isAccessible = true
        fun view(configuration: FluviFinancialSnapshotWidgetConfiguration, model: FinancialSnapshotContent?, event: Boolean): View {
            val remote = method.invoke(FluviFinancialSnapshotWidgetProvider.Companion, context,
                AppWidgetManager.INVALID_APPWIDGET_ID, configuration, model, event) as RemoteViews
            var applied: View? = null
            instrumentation.runOnMainSync { applied = remote.apply(context, FrameLayout(context)) }
            return requireNotNull(applied)
        }
        fun bitmap(view: View): Bitmap = (view.findViewById<ImageView>(R.id.fluvi_financial_snapshot_orb)
            .drawable as BitmapDrawable).bitmap
        fun compare(expected: Bitmap, actual: Bitmap) {
            val a = IntArray(96 * 96); val b = IntArray(96 * 96)
            assertEquals(96, actual.width); assertEquals(96, actual.height)
            expected.getPixels(a, 0, 96, 0, 0, 96, 96)
            actual.getPixels(b, 0, 96, 0, 0, 96, 96)
            assertArrayEquals(a, b)
        }
        fun reference(color: Int): Bitmap {
            val image = Bitmap.createBitmap(96, 96, Bitmap.Config.ARGB_8888)
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                shader = LinearGradient(0f, 0f, 96f, 96f, color, Color.rgb(111, 178, 233), Shader.TileMode.CLAMP)
            }
            Canvas(image).drawCircle(48f, 48f, 47f, paint)
            return image
        }
        val fullView = view(full, content, false)
        compare(reference(content.accentColor), bitmap(fullView))
        assertEquals("123 Ft", fullView.findViewById<TextView>(R.id.fluvi_financial_snapshot_primary).text.toString())
        assertEquals(View.VISIBLE, fullView.findViewById<View>(R.id.fluvi_financial_snapshot_toggle).visibility)
        assertTrue(fullView.findViewById<View>(R.id.fluvi_financial_snapshot_root).hasOnClickListeners())
        val eventView = view(full, content, true)
        assertEquals("event", eventView.findViewById<TextView>(R.id.fluvi_financial_snapshot_primary).text.toString())
        val privateView = view(discreet, content, false)
        compare(reference(Color.rgb(70, 105, 157)), bitmap(privateView))
        assertEquals(View.GONE, privateView.findViewById<View>(R.id.fluvi_financial_snapshot_toggle).visibility)
        assertTrue(!privateView.findViewById<TextView>(R.id.fluvi_financial_snapshot_primary).text.toString().contains("123 Ft"))
        val loadingView = view(full, null, false)
        compare(reference(Color.rgb(70, 105, 157)), bitmap(loadingView))
        assertEquals("Adatok frissítése", loadingView.findViewById<TextView>(R.id.fluvi_financial_snapshot_primary).text.toString())
        compare(reference(content.accentColor), renderFinancialOrbBitmap(content.accentColor))
    }
}
