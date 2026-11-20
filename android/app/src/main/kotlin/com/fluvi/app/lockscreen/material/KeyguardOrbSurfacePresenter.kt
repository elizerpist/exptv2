package com.fluvi.app.lockscreen.material

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PixelFormat
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.Gravity
import android.view.PixelCopy
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View
import android.widget.FrameLayout
import com.fluvi.app.lockscreen.KeyguardR14ForensicProbe

/** Main-owned bounded child of the existing accessibility root. The worker
 * cannot show a window or change this View's disclosure authority. */
internal class KeyguardOrbSurfacePresenter(
    private val context: Context,
    private val root: FrameLayout,
    private val onFirstPosted: (Long, Long) -> Unit,
    private val onFailure: (String) -> Unit,
    private val isCaptureActive: () -> Boolean,
) {
    private val main = Handler(Looper.getMainLooper())
    private val worker = KeyguardOrbSurfaceWorker(
        context = context.applicationContext,
        onFirstPosted = { target, at -> main.post { firstPosted(target, at) } },
        onFailure = { target, reason -> main.post { failIfCurrent(target, reason) } },
        isCaptureActive = isCaptureActive,
    )
    private var current: KeyguardOrbSurfaceTarget? = null
    private var surface: SurfaceView? = null
    private var guard: PrivacyGuard? = null
    private var currentProfile: KeyguardMaterialProfile? = null
    private var nextGeneration = 0L

    fun prepare(profile: KeyguardMaterialProfile?, width: Int, height: Int, allowFull: Boolean) {
        checkMain()
        if (profile != null) worker.prepare(profile, width, height, context.resources.displayMetrics.densityDpi, allowFull)
    }

    fun targetSize(): Pair<Int, Int> {
        checkMain()
        return (surface?.width ?: 0) to (surface?.height ?: 0)
    }

    internal fun surfaceForTest(): SurfaceView? { checkMain(); return surface }
    internal fun metricsForTest(): KeyguardOrbSurfaceMetrics.Snapshot? { checkMain(); return current?.metrics?.snapshot() }

    fun setMotionAllowed(allowed: Boolean) {
        checkMain()
        current?.let { worker.setMotionAllowed(it, allowed) }
    }

    /** Authorization comes only from the real service show/update path. */
    fun show(attachment: Long, profile: KeyguardMaterialProfile, full: Boolean, live: Boolean,
             width: Int, height: Int, reporter: ((KeyguardOrbSurfaceObservation) -> Unit)?) {
        checkMain()
        val old = current
        if (old != null && !old.revoked && old.attachment == attachment && old.full == full &&
            old.live == live && old.width == width && old.height == height
        ) {
            currentProfile = profile.copyForSurface()
            worker.update(old, profile)
            return
        }
        val privacyTightening = old?.full == true && !full
        if (old != null) revokeCurrent(privacyTightening)
        if (privacyTightening) installGuard(profile, width, height)
        removeSurface()
        nextGeneration += 1L
        val child = SurfaceView(context).apply {
            isClickable = false
            isFocusable = false
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
            holder.setFormat(PixelFormat.TRANSLUCENT)
        }
        val target = KeyguardOrbSurfaceTarget(attachment, nextGeneration, child.holder, width, height,
            context.resources.displayMetrics.densityDpi, full, live, reporter)
        current = target
        surface = child
        currentProfile = profile.copyForSurface()
        observe(target, "ROUTE_SELECTED", if (live) "SURFACE_LIVE" else "SURFACE_STATIC")
        child.holder.addCallback(object : SurfaceHolder.Callback2 {
            override fun surfaceCreated(holder: SurfaceHolder) {
                observe(target, "HOLDER_CREATED", "callback")
            }

            override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
                if (current !== target || target.revoked) return
                observe(target, "HOLDER_CHANGED", "${width}x$height")
                if (width != target.width || height != target.height || !holder.surface.isValid) {
                    failIfCurrent(target, "surfaceSizeOrValidity")
                    return
                }
                worker.surfaceReady(target)
            }

            override fun surfaceDestroyed(holder: SurfaceHolder) {
                val started = SystemClock.uptimeMillis()
                val unexpected = current === target && !target.revoked
                KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.DESTROY_ENTER, attachment = target.attachment, generation = target.generation, holder = System.identityHashCode(holder))
                worker.surfaceDestroyed(target)
                KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.DESTROY_EXIT, attachment = target.attachment, generation = target.generation, holder = System.identityHashCode(holder))
                observe(target, "HOLDER_DESTROYED", "drainMs:${SystemClock.uptimeMillis() - started}")
                if (unexpected) failIfCurrent(target, "surfaceDestroyedUnexpectedly")
            }

            override fun surfaceRedrawNeeded(holder: SurfaceHolder) {
                worker.requestRedraw(target, KeyguardOrbSurfaceRedrawCompletion {})
            }

            override fun surfaceRedrawNeededAsync(holder: SurfaceHolder, drawingFinished: Runnable) {
                worker.requestRedraw(target, KeyguardOrbSurfaceRedrawCompletion { drawingFinished.run() })
            }
        })
        root.addView(child, FrameLayout.LayoutParams(width, height, Gravity.CENTER))
        // The neutral guard, when needed, remains a sibling in the existing
        // root and above its SurfaceView hole; it is never an animation owner.
        guard?.bringToFront()
        worker.authorize(target, profile)
    }

    /** Called before root hide/remove. It never joins the render worker. */
    fun revokeCurrent(discardFull: Boolean = false, hideChild: Boolean = true) {
        checkMain()
        val old = current ?: return
        worker.revoke(old, discardFull)
        if (hideChild) surface?.visibility = View.INVISIBLE
    }

    fun detached() {
        checkMain()
        revokeCurrent()
        removeSurface()
        guard?.let(root::removeView)
        guard = null
        current = null
        currentProfile = null
    }

    fun dispose() {
        checkMain()
        detached()
        worker.dispose()
    }

    private fun removeSurface() {
        surface?.let(root::removeView)
        surface = null
        current = null
    }

    private fun installGuard(profile: KeyguardMaterialProfile, width: Int, height: Int) {
        guard?.let(root::removeView)
        guard = PrivacyGuard(context, profile.neutralized().copyForSurface()).also {
            root.addView(it, FrameLayout.LayoutParams(width, height, Gravity.CENTER))
        }
    }

    private fun firstPosted(target: KeyguardOrbSurfaceTarget, at: Long) {
        if (!isCurrent(target)) return
        // The worker's successful post and delivery to this Main callback
        // are different observations. Preserve both original uptime values.
        observe(target, "FIRST_POST", "producerNotPhysicalPresentation", at)
        observe(target, "FIRST_POST_MAIN_DELIVERY", "mainCallbackNotPhysicalPresentation")
        onFirstPosted(target.attachment, at)
        val heldGuard = guard ?: return
        val child = surface ?: return
        // This is a producer-content check only. Compositor presentation and
        // physical removal are independently measured by the device suite.
        val sample = Bitmap.createBitmap(target.width, target.height, Bitmap.Config.ARGB_8888)
        runCatching {
            PixelCopy.request(child, sample, { result ->
                try {
                    if (!isCurrent(target) || guard !== heldGuard) return@request
                    val center = Color.alpha(sample.getPixel(sample.width / 2, sample.height / 2))
                    val corners = intArrayOf(sample.getPixel(0, 0), sample.getPixel(sample.width - 1, 0),
                        sample.getPixel(0, sample.height - 1), sample.getPixel(sample.width - 1, sample.height - 1))
                    val valid = result == PixelCopy.SUCCESS && center >= 240 && corners.all { Color.alpha(it) <= 16 }
                    if (!valid) {
                        failIfCurrent(target, "privacyProducerUnconfirmed:$result")
                    } else {
                        observe(target, "GUARD_RETIRED", "producerSampleNotCompositor")
                        root.removeView(heldGuard)
                        guard = null
                    }
                } finally {
                    sample.recycle()
                }
            }, main)
        }.onFailure {
            sample.recycle()
            failIfCurrent(target, "privacyProducerSample:${it.javaClass.simpleName}")
        }
    }

    private fun isCurrent(target: KeyguardOrbSurfaceTarget): Boolean =
        current === target && !target.revoked && surface?.holder === target.holder && root.isAttachedToWindow

    private fun failIfCurrent(target: KeyguardOrbSurfaceTarget, reason: String) {
        if (current !== target) return
        worker.revoke(target, discardFull = target.full)
        surface?.visibility = View.INVISIBLE
        observe(target, "DEGRADED", reason)
        onFailure(reason)
    }

    private fun observe(target: KeyguardOrbSurfaceTarget, stage: String, detail: String,
                        observedAtUptimeMs: Long = SystemClock.uptimeMillis()) {
        if (isCaptureActive()) target.reporter?.invoke(KeyguardOrbSurfaceObservation(target.attachment, target.generation,
            stage, observedAtUptimeMs, detail, target.full, target.metrics))
    }

    private fun checkMain() = check(Looper.myLooper() == Looper.getMainLooper())

    /** Opaque neutral circle with transparent exterior, never an animator. */
    private class PrivacyGuard(context: Context, private val profile: KeyguardMaterialProfile) : View(context) {
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        init { importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_NO }
        override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
            super.onSizeChanged(w, h, oldw, oldh)
            configureKeyguardStaticOrbPaint(paint, profile, w, h)
            paint.alpha = 255
        }
        override fun onDraw(canvas: Canvas) = drawKeyguardOrbCircle(canvas, paint, width, height)
    }
}
