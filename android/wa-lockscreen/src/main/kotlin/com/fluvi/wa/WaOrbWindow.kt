package com.fluvi.wa

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.animation.AnimatorSet
import android.animation.ObjectAnimator
import android.animation.ValueAnimator
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProviderInfo
import android.content.Context
import android.graphics.Bitmap
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
import android.view.Display
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
    private val product by lazy(LazyThreadSafetyMode.NONE) { WaUnlockProduct.read(context) }
    private val fluviMask by lazy(LazyThreadSafetyMode.NONE) {
        requireNotNull(BitmapFactory.decodeResource(context.resources, R.drawable.wa_fluvi_logo_mask))
    }

    fun prepareStyles() {
        fluviMask
        product
    }

    fun ambientMask(): Bitmap = fluviMask

    fun ambientLayout(material: WaAmbientMaterial): WindowManager.LayoutParams? {
        val dimensions = measure(material.sizeDp)
        if (!dimensions.usable.fits) return null
        return overlayLayout(
            dimensions, material.placement, "Fluvi Ambient ORB", WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
        )
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
        frame.entry = {
            if (shouldAnimate) startEntrance(frame)
            else {
                frame.mark(if (animate) WaStage.ENTRANCE_DISABLED else WaStage.ENTRANCE_REUSED)
                frame.visual.alpha = 1f
            }
        }
        if (shouldAnimate) {
            frame.visual.alpha = 0f
            frame.visual.scaleX = 0.95f
            frame.visual.scaleY = 0.95f
        }
        val diameter = dimensions.usable.diameter
        val params = overlayLayout(dimensions, center, "Fluvi Balance ORB")
        root = frame
        layout = params
        try {
            manager.updateAppWidgetOptions(widgetId, WaOrbHost.options(dp))
            val content = host.createView(context, widgetId, info)
            frame.visual.addView(content, FrameLayout.LayoutParams(-1, -1, Gravity.CENTER))
            frame.applyStyle(style)
            frame.canEnter = canEnter
            if (Build.VERSION.SDK_INT >= 34) {
                val child = WaSurfaceChild(context, handler, { bindChild(frame, it) }, {
                    embeddingFailed(frame, it, "SURFACE_LOST")
                })
                frame.child = child
                frame.presenter = WaPresenter.SURFACE_CHILD
                frame.visual.alpha = 0f
                frame.addView(child.surface, FrameLayout.LayoutParams(-1, -1, Gravity.CENTER))
            } else frame.addVisual()
            if (!canEnter() || root !== frame || frame.revoked) {
                if (root === frame) hide(WaHideReason.UNKNOWN)
                return false
            }
            frame.mark(WaStage.MATERIAL_READY)
            wm.addView(frame, params)
            if (root !== frame || frame.revoked) return false
            frame.mark(WaStage.ATTACH)
            frame.listening = true
            host.startListening()
            if (frame.child == null) {
                if (shouldAnimate) waitForDraw(frame)
                else frame.mark(if (animate) WaStage.ENTRANCE_DISABLED else WaStage.ENTRANCE_REUSED)
            }
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

    private fun bindChild(frame: OrbRoot, child: WaSurfaceChild) {
        if (!live(frame) || frame.child !== child) return
        try {
            child.attach(frame.visual, checkNotNull(layout).width)
            check(child.ready)
            log(frame, "child-bound", "presenter=${frame.presenter}")
            waitForDraw(frame)
        } catch (error: RuntimeException) {
            embeddingFailed(frame, child, error.javaClass.simpleName)
        }
    }

    private fun embeddingFailed(frame: OrbRoot, child: WaSurfaceChild, reason: String) {
        if (!live(frame) || frame.child !== child) return
        frame.presenterFailure = reason
        log(frame, "child-unavailable", "reason=$reason")
        if (frame.hasPublished || frame.canEnter?.invoke() != true) {
            if (live(frame)) hide(WaHideReason.ATTACH_FAILED)
            return
        }
        if (!live(frame) || frame.child !== child) return
        frame.clearDrawWait?.invoke()
        frame.entrance?.removeAllListeners()
        frame.entrance?.cancel()
        frame.entrance = null
        frame.child = null
        try {
            child.dispose()
            frame.removeView(child.surface)
            frame.presenter = WaPresenter.LEGACY_FALLBACK
            frame.addVisual()
            waitForDraw(frame)
        } catch (error: RuntimeException) {
            if (live(frame)) hide(WaHideReason.ATTACH_FAILED)
            Log.w(TAG, "fallback attach failed: ${error.javaClass.simpleName}")
        }
    }

    private fun waitForDraw(frame: OrbRoot) {
        val view = frame.visual
        val observer = view.viewTreeObserver
        lateinit var clear: () -> Unit
        val start = Runnable {
            if (frame.clearDrawWait !== clear || !view.isAttachedToWindow) return@Runnable
            clear()
            val child = frame.child
            if (child != null && !child.ready) {
                embeddingFailed(frame, child, "INVALID_SURFACE")
                return@Runnable
            }
            if (live(frame) && frame.canEnter?.invoke() == true && live(frame) && frame.child === child) {
                frame.entry?.invoke()
            }
        }
        val listener = ViewTreeObserver.OnPreDrawListener {
            start.run()
            true
        }
        clear = {
            frame.clearDrawWait = null
            if (observer.isAlive) observer.removeOnPreDrawListener(listener)
            else view.viewTreeObserver.removeOnPreDrawListener(listener)
            handler.removeCallbacks(start)
        }
        frame.clearDrawWait = clear
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
            val child = frame.child
            try {
                child?.resize(current.width)
            } catch (error: RuntimeException) {
                if (child != null) embeddingFailed(frame, child, error.javaClass.simpleName)
                if (!live(frame)) return
            }
            frame.applyStyle(style)
            frame.mark(WaStage.RESIZE, detail = dp.toLong())
        }
    }

    fun hide(reason: WaHideReason, trigger: WaUnlockTrigger? = null): Long {
        val frame = root ?: return 0
        if (frame.revoked) return 0
        frame.revoked = true
        frame.hide = ++hideId
        frame.hideReason = reason
        val unlock = trigger?.takeIf {
            it.owner == frame.owner && it.reason == reason && frame.isAttachedToWindow &&
                (reason == WaHideReason.UNLOCKED || reason == WaHideReason.USER_PRESENT ||
                    (reason == WaHideReason.RESTRICTED && it.cause == WaWithdrawalCause.APP_WINDOW_PRESENT))
        }
        val child = frame.child
        val draft = unlock?.let { WaUnlockDraft(context.applicationContext) }
        val childHide = child?.withdraw(draft?.let { it::committed })
        frame.mark(WaStage.REVOKE)
        val motion = frame.entrance
        frame.entrance = null
        motion?.removeAllListeners()
        frame.visual.alpha = 0f
        frame.alpha = 0f
        frame.visibility = View.INVISIBLE
        val localHide = WaTime.now()
        frame.localHideAt = localHide.uptimeMs
        if (draft != null) {
            draft.record = WaUnlockRecord(
                product, unlock, frame.displayId, frame.presenter, frame.presenterFailure, sizeDp, frame.style,
                frame.hide, frame.attachedAt, childHide ?: WaChildHide(
                    if (frame.presenter == WaPresenter.LEGACY_API) "UNSUPPORTED" else "FALLBACK",
                ), localHide = localHide, scans = WaLastUnlock.tracking.history(unlock.owner)?.snapshot(),
            )
            frame.unlock = draft
            WaLastUnlock.tracking.withdrew(draft)
        }
        if (childHide != null) log(frame, "child-hide", "status=${childHide.status}", localHide.uptimeMs)
        WaLockscreenCapture.hidden(frame.owner)
        frame.mark(WaStage.LOCAL_HIDE)
        cancelDrag(restore = false)
        frame.clearDrawWait?.invoke()
        frame.canEnter = null
        frame.entry = null
        if (motion != null) {
            motion.cancel()
            frame.mark(WaStage.ENTRANCE_CANCEL)
        }
        remove(frame, retry = false)
        return frame.hide
    }

    private fun remove(frame: OrbRoot, retry: Boolean) {
        if (root !== frame) return
        val began = WaTime.now()
        frame.mark(WaStage.REMOVE_BEGIN, detail = if (retry) 1 else 0)
        var removeError: RuntimeException? = null
        try {
            if (frame.parent != null) wm.removeViewImmediate(frame)
        } catch (error: RuntimeException) {
            removeError = error
        }
        val returned = WaTime.now()
        val removed = frame.parent == null && !frame.isAttachedToWindow
        val removal = WaRemoval(began, returned, removed, removeError?.javaClass?.simpleName)
        frame.mark(
            if (removeError == null) WaStage.REMOVE_RETURN else WaStage.REMOVE_ERROR,
            detail = if (removed) 1 else 0,
        )
        val child = frame.child
        frame.child = null
        try {
            child?.dispose()
        } catch (error: RuntimeException) {
            Log.w(TAG, "child release failed: ${error.javaClass.simpleName}")
        }
        var hostStop: WaTime? = null
        var stopStatus = "UNOBSERVED"
        if (frame.listening) {
            frame.listening = false
            frame.mark(WaStage.HOST_STOP_BEGIN)
            try {
                host.stopOrbListening()
                hostStop = WaTime.now()
                stopStatus = "STOPPED"
                frame.mark(WaStage.HOST_STOP_END)
            } catch (error: RuntimeException) {
                hostStop = WaTime.now()
                stopStatus = "ERROR"
                frame.mark(WaStage.HOST_STOP_ERROR)
                Log.w(TAG, "stop listening failed: ${error.javaClass.simpleName}")
            }
        }
        frame.unlock?.update {
            if (retry) it.copy(retry = removal)
            else it.copy(firstRemove = removal, hostStop = hostStop, hostStopStatus = stopStatus)
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

    private fun overlayLayout(
        dimensions: Geometry, center: OrbPlacement, windowTitle: String, extraFlags: Int = 0,
    ) = WindowManager.LayoutParams(
        dimensions.usable.diameter, dimensions.usable.diameter, WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or extraFlags,
        PixelFormat.TRANSLUCENT,
    ).apply {
        gravity = Gravity.CENTER
        title = windowTitle
        if (Build.VERSION.SDK_INT >= 30) {
            setFitInsetsTypes(0)
            layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
        }
        updateOffsets(this, dimensions.usable.position(center), dimensions)
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
        var canEnter: (() -> Boolean)? = null
        var entry: (() -> Unit)? = null
        var child: WaSurfaceChild? = null
        var presenter = WaPresenter.LEGACY_API
        var presenterFailure: String? = null
        var style = WaOrbStyle.ORB
            private set
        var attachedAt: WaTime? = null
        var displayId = Display.DEFAULT_DISPLAY
        var unlock: WaUnlockDraft? = null
        private var drawLogged = false
        var hasPublished = false
            private set
        private var maskView: ImageView? = null
        val visual = object : FrameLayout(context) {
            override fun setAlpha(alpha: Float) {
                if (revoked && alpha > 0f) return
                super.setAlpha(alpha)
                if (alpha > 0f) publishNonzero()
            }

            override fun dispatchDraw(canvas: android.graphics.Canvas) {
                super.dispatchDraw(canvas)
                if (live(this@OrbRoot) && !drawLogged) {
                    drawLogged = true
                    mark(WaStage.ROOT_DRAW)
                    if (alpha > 0f) publishNonzero()
                    log(this@OrbRoot, "root-draw", "width=$width height=$height")
                }
            }

            override fun dispatchTouchEvent(event: MotionEvent): Boolean = dragEvent(event)
        }

        fun addVisual() {
            addView(visual, LayoutParams(-1, -1, Gravity.CENTER))
        }

        fun applyStyle(style: WaOrbStyle) {
            this.style = style
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
            if (!hasPublished && live(this)) {
                hasPublished = true
                WaLockscreenCapture.visible(owner)
                mark(WaStage.FIRST_NONZERO)
            }
        }

        fun mark(stage: WaStage, detail: Long = 0) = WaLockscreenCapture.record(
            stage, WaSource.WINDOW, owner.service, owner.episode, owner,
            reason = hideReason, hide = hide, detail = detail,
        )

        private fun dragEvent(event: MotionEvent): Boolean {
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
            attachedAt = WaTime.now()
            displayId = display?.displayId ?: Display.DEFAULT_DISPLAY
            WaLastUnlock.tracking.attached(owner, displayId)
            mark(WaStage.ROOT_ATTACHED)
        }

        override fun onDetachedFromWindow() {
            unlock?.update { it.copy(detached = it.detached ?: WaTime.now()) }
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
