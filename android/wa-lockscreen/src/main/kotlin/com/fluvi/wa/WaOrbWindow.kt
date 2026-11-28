package com.fluvi.wa

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.animation.AnimatorSet
import android.animation.ObjectAnimator
import android.animation.ValueAnimator
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProviderInfo
import android.content.Context
import android.graphics.BitmapFactory
import android.graphics.PixelFormat
import android.graphics.Point
import android.graphics.Rect
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.view.ViewTreeObserver
import android.view.WindowInsets
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageView
import kotlin.math.roundToInt

/** WA accessibility overlay hosting one real AppWidget, at a root-owned position. */
class WaOrbWindow(
    private val context: Context,
    private val host: WaOrbHost,
    private val savePlacement: (OrbPlacement) -> Unit,
) {
    private val wm = context.getSystemService(WindowManager::class.java)
    private val fluviMask by lazy(LazyThreadSafetyMode.NONE) {
        requireNotNull(BitmapFactory.decodeResource(context.resources, R.drawable.wa_fluvi_logo_mask))
    }

    fun prepareStyles() {
        fluviMask
    }
    private val manager = AppWidgetManager.getInstance(context)
    private var root: OrbRoot? = null
    private var layout: WindowManager.LayoutParams? = null
    private var geometry: Geometry? = null
    private var placement = OrbPlacement.CENTER
    private var id = AppWidgetManager.INVALID_APPWIDGET_ID
    private var sizeDp = 0
    private var window = 0L
    private var hideId = 0L
    private var drag: Drag? = null
    private var dropPending = false
    private val handler = Handler(Looper.getMainLooper())
    private val slop = ViewConfiguration.get(context).scaledTouchSlop
    private val beginDrag = Runnable {
        val current = drag
        val frame = root
        if (current != null && frame != null && live(frame)) {
            current.held = true
            log(frame, "drag-start")
        }
    }

    private val attached get() = root?.let(::live) == true
    val hasAttachment get() = root?.let { it.isAttachedToWindow || it.parent != null } == true
    val owner: WaAttachment? get() = root?.takeIf(::live)?.owner

    private fun live(frame: OrbRoot): Boolean =
        root === frame && !frame.revoked && frame.isAttachedToWindow && frame.visibility == View.VISIBLE

    @Suppress("DEPRECATION")
    fun ownsEvent(windowId: Int): Boolean {
        val frame = root?.takeIf(::live) ?: return false
        if (windowId < 0) return false
        if (frame.nodeWindowId < 0) {
            val node = frame.createAccessibilityNodeInfo()
            frame.nodeWindowId = node.windowId
            node.recycle()
        }
        return windowId == frame.nodeWindowId
    }

    private data class Geometry(val display: Rect, val usable: OrbFrameBounds)

    private class Drag(val pointer: Int, val rawX: Float, val rawY: Float, val left: Int, val top: Int) {
        var held = false
    }

    fun show(
        session: Long, episode: Long, widgetId: Int, info: AppWidgetProviderInfo, dp: Int,
        center: OrbPlacement, animate: Boolean, style: WaOrbStyle, canEnter: () -> Boolean,
    ): Boolean {
        if (attached && owner?.service == session && owner?.episode == episode && id == widgetId) {
            resize(dp, style)
            return attached
        }
        hide(WaHideReason.REPLACE)
        if (root != null) return false
        val dimensions = measure(dp)
        if (!dimensions.usable.fits) return false
        id = widgetId
        sizeDp = dp
        geometry = dimensions
        placement = center
        val shouldAnimate = animate && animatorsEnabled()
        val frame = OrbRoot(context, WaAttachment(session, episode, ++window, widgetId, dp))
        if (shouldAnimate) {
            frame.visual.alpha = 0f
            frame.visual.scaleX = 0.95f
            frame.visual.scaleY = 0.95f
        }
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
            frame.visual.addView(content, FrameLayout.LayoutParams(-1, -1, Gravity.CENTER))
            frame.applyStyle(style)
            if (!canEnter() || root !== frame || frame.revoked) {
                if (root === frame) hide(WaHideReason.UNKNOWN)
                return false
            }
            frame.mark(WaStage.MATERIAL_READY)
            wm.addView(frame, params)
            frame.mark(WaStage.ATTACH)
            frame.listening = true
            host.startListening()
            if (shouldAnimate) waitForDraw(frame, canEnter)
            else frame.mark(if (animate) WaStage.ENTRANCE_DISABLED else WaStage.ENTRANCE_REUSED)
            log(frame, "attach", "dp=$dp diameter=$diameter x=${params.x} y=${params.y}")
            return true
        } catch (error: RuntimeException) {
            hide(WaHideReason.ATTACH_FAILED)
            Log.w(TAG, "attach failed: ${error.javaClass.simpleName}")
            return false
        }
    }

    private fun animatorsEnabled(): Boolean =
        if (Build.VERSION.SDK_INT >= 26) ValueAnimator.areAnimatorsEnabled()
        else Settings.Global.getFloat(context.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) > 0f

    private fun waitForDraw(frame: OrbRoot, allowed: () -> Boolean) {
        val observer = frame.viewTreeObserver
        val start = Runnable {
            val clear = frame.clearDrawWait ?: return@Runnable
            clear()
            if (live(frame) && allowed() && live(frame)) startEntrance(frame)
        }
        val listener = ViewTreeObserver.OnPreDrawListener {
            start.run()
            true
        }
        frame.clearDrawWait = {
            frame.clearDrawWait = null
            if (observer.isAlive) observer.removeOnPreDrawListener(listener)
            else frame.viewTreeObserver.removeOnPreDrawListener(listener)
            handler.removeCallbacks(start)
        }
        observer.addOnPreDrawListener(listener)
        handler.postDelayed(start, 50)
    }

    private fun startEntrance(frame: OrbRoot) {
        val visual = frame.visual
        val motion = AnimatorSet().apply {
            playTogether(
                ObjectAnimator.ofFloat(visual, View.SCALE_X, 1f),
                ObjectAnimator.ofFloat(visual, View.SCALE_Y, 1f),
                ObjectAnimator.ofFloat(visual, View.ALPHA, 1f),
            )
            duration = 300
            addListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) {
                    if (live(frame) && frame.entrance === animation) {
                        frame.entrance = null
                        frame.mark(WaStage.ENTRANCE_END)
                    }
                }
            })
        }
        frame.entrance = motion
        frame.mark(WaStage.ENTRANCE_BEGIN)
        motion.start()
    }

    fun resize(dp: Int, style: WaOrbStyle) {
        val frame = root?.takeIf(::live) ?: return
        val dimensions = measure(dp)
        if (sizeDp == dp && geometry == dimensions) {
            frame.applyStyle(style)
            return
        }
        cancelDrag(restore = false)
        if (!dimensions.usable.fits) {
            hide(WaHideReason.NO_FIT)
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
                hide(WaHideReason.RESIZE_OPTIONS_FAILED)
                return
            }
            sizeDp = dp
        }
        if (!safeUpdate(dimensions.usable.position(placement), dimensions)) hide(WaHideReason.RESIZE_FAILED)
        else {
            frame.applyStyle(style)
            frame.mark(WaStage.RESIZE, detail = dp.toLong())
        }
    }

    fun hide(reason: WaHideReason): Long {
        val frame = root ?: return 0
        if (frame.revoked) return 0
        frame.revoked = true
        frame.hide = ++hideId
        frame.hideReason = reason
        frame.mark(WaStage.REVOKE)
        val motion = frame.entrance
        frame.entrance = null
        motion?.removeAllListeners()
        frame.visual.alpha = 0f
        frame.alpha = 0f
        frame.visibility = View.INVISIBLE
        frame.localHideAt = SystemClock.uptimeMillis()
        WaLockscreenCapture.hidden(frame.owner)
        frame.mark(WaStage.LOCAL_HIDE)
        cancelDrag(restore = false)
        frame.clearDrawWait?.invoke()
        if (motion != null) {
            motion.cancel()
            frame.mark(WaStage.ENTRANCE_CANCEL)
        }
        remove(frame, retry = false)
        return frame.hide
    }

    private fun remove(frame: OrbRoot, retry: Boolean) {
        if (root !== frame) return
        frame.mark(WaStage.REMOVE_BEGIN, detail = if (retry) 1 else 0)
        var removeError: RuntimeException? = null
        try {
            if (frame.parent != null) wm.removeViewImmediate(frame)
        } catch (error: RuntimeException) {
            removeError = error
        }
        val removed = frame.parent == null && !frame.isAttachedToWindow
        frame.mark(
            if (removeError == null) WaStage.REMOVE_RETURN else WaStage.REMOVE_ERROR,
            detail = if (removed) 1 else 0,
        )
        if (frame.listening) {
            frame.listening = false
            frame.mark(WaStage.HOST_STOP_BEGIN)
            try {
                host.stopOrbListening()
                frame.mark(WaStage.HOST_STOP_END)
            } catch (error: RuntimeException) {
                frame.mark(WaStage.HOST_STOP_ERROR)
                Log.w(TAG, "stop listening failed: ${error.javaClass.simpleName}")
            }
        }
        if (removed) {
            root = null
            layout = null
            geometry = null
        } else if (!retry) {
            handler.post { remove(frame, retry = true) }
        }
        log(frame, "hide", "reason=${frame.hideReason}", frame.localHideAt)
        log(frame, "remove", "reason=${frame.hideReason} removed=$removed")
        if (removeError != null) Log.w(TAG, "remove failed: ${removeError.javaClass.simpleName}")
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
            geometry?.let { if (!safeUpdate(it.usable.position(placement), it)) hide(WaHideReason.DRAG_RESTORE_FAILED) }
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
                    log(frame, "drag-drop", "left=${location[0]} top=${location[1]}")
                } else cancelDrag(restore = true)
            }
        }
    }

    private inner class OrbRoot(context: Context, val owner: WaAttachment) : FrameLayout(context) {
        var revoked = false
        var hide = 0L
        var hideReason = WaHideReason.NONE
        var localHideAt = 0L
        var listening = false
        var nodeWindowId = -1
        var entrance: AnimatorSet? = null
        var clearDrawWait: (() -> Unit)? = null
        private var drawLogged = false
        private var nonzero = false
        private var maskView: ImageView? = null
        val visual = object : FrameLayout(context) {
            override fun setAlpha(alpha: Float) {
                if (revoked && alpha > 0f) return
                super.setAlpha(alpha)
                if (alpha > 0f) publishNonzero()
            }
        }

        init {
            addView(visual, LayoutParams(-1, -1, Gravity.CENTER))
        }

        fun applyStyle(style: WaOrbStyle) {
            if (style == WaOrbStyle.ORB) {
                maskView?.visibility = View.GONE
                return
            }
            val mask = maskView ?: ImageView(context).apply {
                importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
                scaleType = ImageView.ScaleType.FIT_XY
                setImageBitmap(fluviMask)
                visual.addView(this, LayoutParams(-1, -1))
                maskView = this
            }
            mask.visibility = View.VISIBLE
        }

        private fun publishNonzero() {
            if (!nonzero && live(this)) {
                nonzero = true
                WaLockscreenCapture.visible(owner)
                mark(WaStage.FIRST_NONZERO)
            }
        }

        fun mark(stage: WaStage, detail: Long = 0) = WaLockscreenCapture.record(
            stage, WaSource.WINDOW, owner.service, owner.episode, owner,
            reason = hideReason, hide = hide, detail = detail,
        )

        override fun dispatchDraw(canvas: android.graphics.Canvas) {
            super.dispatchDraw(canvas)
            if (live(this) && !drawLogged) {
                drawLogged = true
                mark(WaStage.ROOT_DRAW)
                if (visual.alpha > 0f) publishNonzero()
                log(this, "root-draw", "width=$width height=$height")
            }
        }

        override fun dispatchTouchEvent(event: MotionEvent): Boolean {
            if (!live(this)) return false
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

        override fun onAttachedToWindow() {
            super.onAttachedToWindow()
            mark(WaStage.ROOT_ATTACHED)
        }

        override fun onDetachedFromWindow() {
            WaLockscreenCapture.hidden(owner)
            mark(WaStage.DETACHED)
            clearDrawWait?.invoke()
            if (root === this && !revoked) {
                handler.post { if (root === this) hide(WaHideReason.DISPLAY) }
            }
            super.onDetachedFromWindow()
        }
    }

    private fun log(frame: OrbRoot, stage: String, detail: String = "", at: Long = SystemClock.uptimeMillis()) {
        val owner = frame.owner
        Log.i(TAG, "stage=$stage up=$at session=${owner.service} window=${owner.window} id=${owner.widget} $detail")
    }

    private companion object {
        const val TAG = "FluviBalanceOrb"
    }
}
