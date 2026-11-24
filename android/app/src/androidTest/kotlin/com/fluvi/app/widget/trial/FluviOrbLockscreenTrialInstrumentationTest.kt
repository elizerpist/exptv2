package com.fluvi.app.widget.trial

import android.appwidget.AppWidgetHost
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProviderInfo
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.drawable.BitmapDrawable
import android.os.Bundle
import android.os.SystemClock
import android.view.ViewGroup
import android.widget.ImageView
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.fluvi.app.R
import com.fluvi.app.lockscreen.material.KeyguardMaterialTestActivity
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

/** Framework-host control only; it is not the phone's primary lockscreen. */
@RunWith(AndroidJUnit4::class)
class FluviOrbLockscreenTrialInstrumentationTest {
    @Test fun boundWidgetReceivesTheStaticSyntheticImage() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        val manager = AppWidgetManager.getInstance(context)
        val component = ComponentName(context, FluviOrbLockscreenTrialProvider::class.java)
        val info = requireNotNull(manager.installedProviders.firstOrNull { it.provider == component })
        assertTrue(info.widgetCategory and AppWidgetProviderInfo.WIDGET_CATEGORY_KEYGUARD != 0)
        assertTrue(info.widgetCategory and AppWidgetProviderInfo.WIDGET_CATEGORY_HOME_SCREEN != 0)
        assertEquals("Fluvi ORB – zárképernyőpróba", info.loadLabel(context.packageManager))
        assertEquals(0, info.updatePeriodMillis)
        assertNull(info.configure)
        val reference = requireNotNull(BitmapFactory.decodeResource(context.resources, R.drawable.fluvi_orb_lockscreen_trial))
        assertEquals(0, Color.alpha(reference.getPixel(0, 0)))
        assertTrue(Color.blue(reference.getPixel(96, 96)) > Color.red(reference.getPixel(96, 96)))
        assertTrue(Color.red(reference.getPixel(177, 14)) > 200)
        assertTrue(Color.blue(reference.getPixel(177, 14)) > 100)

        val automation = instrumentation.uiAutomation
        automation.adoptShellPermissionIdentity("android.permission.BIND_APPWIDGET")
        val activity = instrumentation.startActivitySync(
            Intent(context, KeyguardMaterialTestActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        ) as KeyguardMaterialTestActivity
        val host = AppWidgetHost(activity, 0x3636)
        val id = host.allocateAppWidgetId()
        try {
            val options = Bundle().apply {
                putInt(AppWidgetManager.OPTION_APPWIDGET_HOST_CATEGORY, AppWidgetProviderInfo.WIDGET_CATEGORY_KEYGUARD)
            }
            assertTrue("framework did not bind the trial provider", manager.bindAppWidgetIdIfAllowed(id, component, options))
            assertEquals(component, manager.getAppWidgetInfo(id).provider)
            instrumentation.runOnMainSync {
                host.startListening()
                val hostView = host.createView(activity, id, info)
                activity.setContentView(hostView, ViewGroup.LayoutParams(192, 192))
            }
            val deadline = SystemClock.uptimeMillis() + 20_000
            var received: Bitmap? = null
            var lastState = "not inspected"
            while (SystemClock.uptimeMillis() < deadline && received == null) {
                instrumentation.runOnMainSync {
                    val image = activity.findViewById<ImageView>(R.id.fluvi_orb_lockscreen_trial_image)
                    val drawable = image?.drawable
                    lastState = "image=${image?.javaClass?.name} drawable=${drawable?.javaClass?.name} size=${image?.width}x${image?.height}"
                    received = (drawable as? BitmapDrawable)?.bitmap
                }
                if (received == null) Thread.sleep(50)
            }
            if (received == null) {
                println("R36_DIAGNOSTIC naturalUpdateMissing=true $lastState ids=${manager.getAppWidgetIds(component).joinToString()}")
                val intent = Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE).setComponent(component)
                    .putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(id))
                context.sendBroadcast(intent)
                val explicitDeadline = SystemClock.uptimeMillis() + 10_000
                while (SystemClock.uptimeMillis() < explicitDeadline && received == null) {
                    instrumentation.runOnMainSync {
                        val image = activity.findViewById<ImageView>(R.id.fluvi_orb_lockscreen_trial_image)
                        lastState = "image=${image?.javaClass?.name} drawable=${image?.drawable?.javaClass?.name} size=${image?.width}x${image?.height}"
                        received = (image?.drawable as? BitmapDrawable)?.bitmap
                    }
                    if (received == null) Thread.sleep(50)
                }
                println("R36_DIAGNOSTIC explicitUpdateReceived=${received != null} $lastState")
                throw AssertionError("Natural framework binding did not produce a matching bitmap; see R36_DIAGNOSTIC")
            }
            val actual = requireNotNull(received)
            assertEquals(reference.width, actual.width)
            assertEquals(reference.height, actual.height)
            for ((x, y) in listOf(0 to 0, 96 to 96, 177 to 14)) {
                assertEquals("host image mismatch at $x,$y", reference.getPixel(x, y), actual.getPixel(x, y))
            }
            instrumentation.waitForIdleSync()
            val screen = requireNotNull(automation.takeScreenshot())
            try {
                context.openFileOutput("r36-framework-host.png", Context.MODE_PRIVATE).use {
                    assertTrue(screen.compress(Bitmap.CompressFormat.PNG, 100, it))
                }
            } finally { screen.recycle() }
            println("R36_FRAMEWORK_HOST bound=true category=KEYGUARD image=blue-cyan marker=magenta size=${actual.width}x${actual.height}")
        } finally {
            try {
                automation.takeScreenshot()?.let { screen ->
                    try { context.openFileOutput("r36-framework-host.png", Context.MODE_PRIVATE).use { screen.compress(Bitmap.CompressFormat.PNG, 100, it) } }
                    finally { screen.recycle() }
                }
            } catch (_: Throwable) { }
            instrumentation.runOnMainSync { host.stopListening(); activity.finish() }
            host.deleteAppWidgetId(id)
            automation.dropShellPermissionIdentity()
            reference.recycle()
        }
    }
}
