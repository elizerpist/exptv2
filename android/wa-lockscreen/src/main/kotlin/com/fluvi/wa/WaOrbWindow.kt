package com.fluvi.wa

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProviderInfo
import android.content.Context
import android.graphics.PixelFormat
import android.graphics.Point
import android.graphics.Rect
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.view.WindowInsets
import android.view.WindowManager
import android.widget.FrameLayout
import kotlin.math.roundToInt

/** WA accessibility overlay hosting one real AppWidget, at a root-owned position. */
class WaOrbWindow(
    private val context: Context,
    private val host: WaOrbHost,
    private val savePlacement: (OrbPlacement) -> Unit,
) {
    private val wm = context.getSystemService(WindowManager::class.java)
    private val manager = AppWidgetManager.getInstance(context)
    private var root: OrbRoot? = null
    private var layout: WindowManager.LayoutParams? = null
    private var geometry: Geometry? = null
    private var placement = OrbPlacement.CENTER
    private var id = AppWidgetManager.INVALID_APPWIDGET_ID
    private var sizeDp = 0
    private var session = 0L
    private var window = 0L
    private var drag: Drag? = null
    private var dropPending = false
    private var drawLogged = false
    private val handler = Handler(Looper.getMainLooper())
    private val slop = ViewConfiguration.get(context).scaledTouchSlop
    private val beginDrag = Runnable {
        drag?.held = true
        record("drag-start")
    }

    val attached: Boolean get() = root?.let { it.isAttachedToWindow && it.visibility == View.VISIBLE } == true

    private data class Geometry(val display: Rect, val usable: OrbFrameBounds)

    private class Drag(val pointer: Int, val rawX: Float, val rawY: Float, val left: Int, val top: Int) {
        var held = false
    }

    fun show(
        session: Long, widgetId: Int, info: AppWidgetProviderInfo, dp: Int, center: OrbPlacement,
    ) {
        this.session = session
        if (attached && id == widgetId) {
            if (sizeDp != dp || geometry != measure(dp)) resize(dp)
            return
        }
        hide("replace")
        if (root != null) return
        val dimensions = measure(dp)
        if (!dimensions.usable.fits) {
            record("no-fit")
            return
        }
        id = widgetId
        sizeDp = dp
        geometry = dimensions
        placement = center
        window++
        val frame = OrbRoot(context)
        val diameter = dimensions.usable.diameter
        val params = WindowManager.LayoutParams(
            diameter, diameter, WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.CENTER
            title = "Fluvi Balance ORB"
            if (Build.VERSION.SDK_INT >= 30) {
                setFitInsetsTypes(0)
                layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
            }
        }
        updateOffsets(params, dimensions.usable.position(center), dimensions)
        root = frame
        layout = params
        try {
            manager.updateAppWidgetOptions(widgetId, WaOrbHost.options(dp))
            val content = host.createView(context, widgetId, info)
            frame.addView(content, FrameLayout.LayoutParams(-1, -1, Gravity.CENTER))
            drawLogged = false
            wm.addView(frame, params)
            host.startListening()
            record("attach", "dp=$dp diameter=$diameter x=${params.x} y=${params.y}")
        } catch (error: RuntimeException) {
            Log.w(TAG, "attach failed: ${error.javaClass.simpleName}")
            hide("attachFailure")
        }
    }

    fun resize(dp: Int = sizeDp) {
        if (!attached) return
        val dimensions = measure(dp)
        if (sizeDp == dp && geometry == dimensions) return
        cancelDrag(restore = false)
        if (!dimensions.usable.fits) {
            hide("no-fit")
            return
        }
        geometry = dimensions
        val current = layout ?: return
        current.width = dimensions.usable.diameter
        current.height = current.width
        if (sizeDp != dp) {
            try {
                manager.updateAppWidgetOptions(id, WaOrbHost.options(dp))
            } catch (error: RuntimeException) {
                hide("resizeOptionsFailure")
                return
            }
            sizeDp = dp
        }
        if (!safeUpdate(dimensions.usable.position(placement), dimensions)) hide("resizeFailure")
    }

    fun hide(reason: String) {
        val frame = root ?: return
        cancelDrag(restore = false)
        frame.visibility = View.INVISIBLE
        record("hide", "reason=$reason")
        try {
            if (frame.parent != null) wm.removeViewImmediate(frame)
        } catch (error: RuntimeException) {
            Log.w(TAG, "remove failed: ${error.javaClass.simpleName}")
        } finally {
            try {
                host.stopOrbListening()
            } catch (error: RuntimeException) {
                Log.w(TAG, "stop listening failed: ${error.javaClass.simpleName}")
            }
            if (frame.parent == null) {
                root = null
                layout = null
                geometry = null
            }
            record("remove", "reason=$reason removed=${frame.parent == null}")
        }
    }

    @Suppress("DEPRECATION")
    private fun measure(dp: Int): Geometry {
        val diameter = (dp * context.resources.displayMetrics.density).roundToInt()
        if (Build.VERSION.SDK_INT >= 30) {
            val metrics = wm.currentWindowMetrics
            val display = metrics.bounds
            val insets = metrics.windowInsets.getInsetsIgnoringVisibility(
                WindowInsets.Type.systemBars() or WindowInsets.Type.displayCutout(),
            )
            return Geometry(display, OrbFrameBounds(
                display.left + insets.left, display.top + insets.top,
                display.right - insets.right, display.bottom - insets.bottom, diameter,
            ))
        }
        val size = Point()
        wm.defaultDisplay.getRealSize(size)
        val insets = root?.rootWindowInsets
        val cutout = if (Build.VERSION.SDK_INT >= 28) insets?.displayCutout else null
        return Geometry(Rect(0, 0, size.x, size.y), OrbFrameBounds(
            maxOf(insets?.stableInsetLeft ?: 0, cutout?.safeInsetLeft ?: 0),
            maxOf(insets?.stableInsetTop ?: 0, cutout?.safeInsetTop ?: 0),
            size.x - maxOf(insets?.stableInsetRight ?: 0, cutout?.safeInsetRight ?: 0),
            size.y - maxOf(insets?.stableInsetBottom ?: 0, cutout?.safeInsetBottom ?: 0),
            diameter,
        ))
    }

    private fun updateOffsets(
        params: WindowManager.LayoutParams, position: Pair<Int, Int>, dimensions: Geometry,
    ) {
        params.x = position.first - dimensions.display.left - (dimensions.display.width() - params.width) / 2
        params.y = position.second - dimensions.display.top - (dimensions.display.height() - params.height) / 2
    }

    private fun safeUpdate(position: Pair<Int, Int>, dimensions: Geometry): Boolean {
        val frame = root ?: return false
        val params = layout ?: return false
        if (!attached) return false
        return try {
            updateOffsets(params, position, dimensions)
            wm.updateViewLayout(frame, params)
            true
        } catch (error: RuntimeException) {
            Log.w(TAG, "update failed: ${error.javaClass.simpleName}")
            false
        }
    }

    private fun cancelDrag(restore: Boolean) {
        handler.removeCallbacks(beginDrag)
        val restoreNeeded = drag?.held == true || dropPending
        drag = null
        dropPending = false
        if (restore && restoreNeeded) {
            geometry?.let { if (!safeUpdate(it.usable.position(placement), it)) hide("dragRestoreFailure") }
        }
    }

    private fun drop(frame: OrbRoot, dimensions: Geometry, position: Pair<Int, Int>) {
        cancelDrag(restore = false)
        dropPending = true
        val expectedWindow = window
        // WM applies a new LayoutParams before the next composition. Persist only
        // the actually applied root location, once, under the same window owner.
        frame.postOnAnimation {
            frame.postOnAnimation verify@{
                if (!dropPending || !attached || root !== frame || window != expectedWindow ||
                    geometry != dimensions) return@verify
                val location = IntArray(2).also(frame::getLocationOnScreen)
                if ((location[0] to location[1]) == position) {
                    dropPending = false
                    placement = dimensions.usable.center(location[0], location[1])
                    savePlacement(placement)
                    record("drag-drop", "left=${location[0]} top=${location[1]}")
                } else cancelDrag(restore = true)
            }
        }
    }

    private inner class OrbRoot(context: Context) : FrameLayout(context) {
        override fun dispatchDraw(canvas: android.graphics.Canvas) {
            super.dispatchDraw(canvas)
            if (!drawLogged) {
                drawLogged = true
                record("root-draw", "width=$width height=$height")
            }
        }

        override fun dispatchTouchEvent(event: MotionEvent): Boolean {
            val dimensions = geometry ?: return false
            if (event.actionMasked == MotionEvent.ACTION_DOWN) {
                cancelDrag(restore = true)
                if (!attached || event.pointerCount != 1) return false
                val radius = width / 2f
                val dx = event.x - radius
                val dy = event.y - radius
                if (dx * dx + dy * dy > radius * radius) return false
                val location = IntArray(2).also(::getLocationOnScreen)
                drag = Drag(event.getPointerId(0), event.rawX, event.rawY, location[0], location[1])
                handler.postDelayed(beginDrag, ViewConfiguration.getLongPressTimeout().toLong())
                return true
            }
            val current = drag ?: return true
            if (event.actionMasked == MotionEvent.ACTION_CANCEL || event.pointerCount != 1 ||
                event.getPointerId(0) != current.pointer) {
                cancelDrag(restore = true)
                return true
            }
            val dx = event.rawX - current.rawX
            val dy = event.rawY - current.rawY
            when (event.actionMasked) {
                MotionEvent.ACTION_MOVE, MotionEvent.ACTION_UP -> {
                    if (current.held) {
                        val next = dimensions.usable.clamp(
                            current.left + dx.roundToInt(), current.top + dy.roundToInt(),
                        )
                        if (!safeUpdate(next, dimensions)) cancelDrag(restore = true)
                        else if (event.actionMasked == MotionEvent.ACTION_UP) drop(this, dimensions, next)
                    } else if (event.actionMasked == MotionEvent.ACTION_UP ||
                        dx * dx + dy * dy > slop * slop) cancelDrag(restore = false)
                }
            }
            return true
        }

        override fun onDetachedFromWindow() {
            cancelDrag(restore = false)
            super.onDetachedFromWindow()
        }
    }

    private fun record(stage: String, detail: String = "") {
        Log.i(TAG, "stage=$stage up=${SystemClock.uptimeMillis()} session=$session window=$window id=$id $detail")
    }

    private companion object {
        const val TAG = "FluviBalanceOrb"
    }
}
