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
import android.view.Display
import android.view.Gravity
import android.view.PixelCopy
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View
import android.widget.FrameLayout

/** Main-owned bounded child of the existing accessibility root. The worker
 * cannot show a window or change this View's disclosure authority. */
internal class KeyguardOrbSurfacePresenter(
    private val context: Context,
    private val root: FrameLayout,
    private val onFirstPosted: (Long, Long) -> Unit,
    private val onFailure: (String) -> Unit,
    private val isCaptureActive: () -> Boolean,
    private val onR18Prepared: (Long, Long, Long) -> Unit = { _, _, _ -> },
    private val onR18Failure: (Long, Long, String, () -> Unit) -> Unit = { _, _, _, done -> done() },
    private val onR18Receipt: (Long, Long, KeyguardOrbPresentationLane.Receipt) -> Unit = { _, _, _ -> },
    private val onR18Drained: (Long, Long, Any) -> Unit = { _, _, _ -> },
) {
    private val main = Handler(Looper.getMainLooper())
    @Volatile private var direct: KeyguardOrbR18Presenter? = null
    private val worker = KeyguardOrbSurfaceWorker(
        context = context.applicationContext,
        onFirstPosted = { target, at ->
            if (target.directOutput != null) direct?.onWorkerFirstPosted(target, at)
            else main.post { firstPosted(target, at) }
        },
        onFailure = { target, reason ->
            if (target.directOutput != null) direct?.onWorkerFailure(target, reason)
            else main.post { failIfCurrent(target, reason) }
        },
        isCaptureActive = isCaptureActive,
    )
    private var current: KeyguardOrbSurfaceTarget? = null
    private var surface: SurfaceView? = null
    private var guard: PrivacyGuard? = null
    private var currentProfile: KeyguardMaterialProfile? = null
    private var nextGeneration = 0L
    // One draining predecessor is allowed while G2 runs. A second draining
    // predecessor closes admission until both native owners have drained.
    private var retiringOutput: KeyguardOrbOwnedOutput? = null
    private var overflowOutput: KeyguardOrbOwnedOutput? = null

    fun prepare(profile: KeyguardMaterialProfile?, width: Int, height: Int, allowFull: Boolean) {
        checkMain()
        if (profile != null) worker.prepare(profile, width, height, context.resources.displayMetrics.densityDpi, allowFull)
    }

    /** These methods expose the R18 path through the same render worker.
     * The caller remains responsible for fresh privacy/input authority. */
    private fun directOnMain(): KeyguardOrbR18Presenter {
        checkMain()
        return direct ?: KeyguardOrbR18Presenter(worker, isCaptureActive, onR18Prepared,
            onR18Failure, onR18Receipt, onR18Drained).also { direct = it }
    }

    fun prepareR18(attachment: Long, generation: Long, profile: KeyguardMaterialProfile,
                   width: Int, height: Int, full: Boolean = false, authorizedFull: Boolean = false): Boolean {
        checkMain()
        // A stock child still draining counts against the native bound.
        if (current != null || retiringOutput != null || overflowOutput != null) return false
        directOnMain().prepare(attachment, generation, profile, width, height,
            context.resources.displayMetrics.densityDpi, full, authorizedFull)
        return true
    }

    fun r18ReadyAt(attachment: Long, generation: Long): Long? = direct?.readyAt(attachment, generation)

    fun r18PreparedOutput(attachment: Long, generation: Long, profile: KeyguardMaterialProfile,
                          full: Boolean, width: Int, height: Int): Any? {
        checkMain()
        return direct?.preparedOutput(attachment, generation, profile, full, width, height,
            context.resources.displayMetrics.densityDpi)
    }

    fun bindR18(host: View, attachment: Long, generation: Long, done: (Boolean) -> Unit) {
        checkMain()
        val presenter = direct ?: run { done(false); return }
        presenter.bind(host, attachment, generation, done)
    }

    fun revealR18(attachment: Long, generation: Long, crossGrantBoundary: () -> Boolean, done: (Boolean) -> Unit) {
        checkMain()
        val presenter = direct ?: run { done(false); return }
        presenter.reveal(attachment, generation, crossGrantBoundary, done)
    }

    /** This seal is thread-safe and uses the exact currently-owned target. */
    fun r18OutputsOutstanding(): Boolean = direct?.hasLiveOutputs() == true
    fun sealR18() { direct?.seal() }
    fun sealR18(attachment: Long, generation: Long) { direct?.sealMatching(attachment, generation) }

    fun targetSize(): Pair<Int, Int> {
        checkMain()
        return (surface?.width ?: 0) to (surface?.height ?: 0)
    }

    internal fun surfaceForTest(): SurfaceView? { checkMain(); return surface }
    internal fun metricsForTest(): KeyguardOrbSurfaceMetrics.Snapshot? { checkMain(); return current?.metrics?.snapshot() }

    fun setMotionAllowed(allowed: Boolean) {
        checkMain()
        current?.let { worker.setMotionAllowed(it, allowed) }
        direct?.setMotionAllowed(allowed)
    }

    /** Authorization comes only from the real service show/update path. */
    fun show(attachment: Long, profile: KeyguardMaterialProfile, full: Boolean, live: Boolean,
             width: Int, height: Int, reporter: ((KeyguardOrbSurfaceObservation) -> Unit)?) {
        checkMain()
        sealR18()
        val old = current
        if (old != null && !old.revoked && old.attachment == attachment && old.full == full &&
            old.live == live && old.width == width && old.height == height
        ) {
            currentProfile = profile.copyForSurface()
            worker.update(old, profile)
            return
        }
        val privacyTightening = old?.full == true && !full
        if (old != null && !revokeCurrent(privacyTightening)) {
            main.post { onFailure("r16RetirementFailedOrBusy") }
            return
        }
        if (overflowOutput != null) {
            main.post { onFailure("r16RetirementCapacity") }
            return
        }
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
                if (KeyguardOrbSurfaceWorkerTestHooks.ENABLED) {
                    KeyguardOrbSurfaceWorkerTestHooks.holderBoundary?.invoke(target, "CREATED", 0L)
                }
                observe(target, "HOLDER_CREATED", "callback")
            }

            override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
                if (KeyguardOrbSurfaceWorkerTestHooks.ENABLED) {
                    KeyguardOrbSurfaceWorkerTestHooks.holderBoundary?.invoke(target, "CHANGED", 0L)
                }
                if (current !== target || target.revoked) return
                observe(target, "HOLDER_CHANGED", "${width}x$height")
                if (width != target.width || height != target.height || !holder.surface.isValid) {
                    failIfCurrent(target, "surfaceSizeOrValidity")
                    return
                }
                if (target.ownsOutput && target.ownedOutput == null) {
                    val prepared = runCatching {
                        check(child.display?.displayId == Display.DEFAULT_DISPLAY)
                        check(current === target && !target.revoked && child.holder === holder)
                        val parent = child.surfaceControl
                        check(parent.isValid)
                        KeyguardOrbOwnedOutput.create(parent, width, height, target.generation, main) { output ->
                            if (output.disposeIfReady()) {
                                target.metrics?.r16Disposed(SystemClock.uptimeMillis())
                                if (retiringOutput === output) retiringOutput = null
                                if (overflowOutput === output) overflowOutput = null
                            }
                        }
                    }.getOrElse {
                        failIfCurrent(target, "r16OutputCreate:${it.javaClass.simpleName}")
                        return
                    }
                    if (current !== target || target.revoked) {
                        prepared.retire(target.metrics)
                        prepared.disposeIfReady()
                        return
                    }
                    target.ownedOutput = prepared
                    target.metrics?.r16Created(System.identityHashCode(child), prepared.childId, SystemClock.uptimeMillis())
                    observe(target, "R16_OUTPUT_CREATED", "host:${System.identityHashCode(child)},child:${prepared.childId}")
                }
                worker.surfaceReady(target)
            }

            override fun surfaceDestroyed(holder: SurfaceHolder) {
                val started = SystemClock.uptimeMillis()
                val unexpected = current === target && !target.revoked
                if (unexpected) revokeCurrent(hideChild = false)
                if (KeyguardOrbSurfaceWorkerTestHooks.ENABLED) {
                    KeyguardOrbSurfaceWorkerTestHooks.holderBoundary?.invoke(target, "DESTROY_BEGIN", 0L)
                }
                worker.surfaceDestroyed(target)
                if (KeyguardOrbSurfaceWorkerTestHooks.ENABLED) {
                    KeyguardOrbSurfaceWorkerTestHooks.holderBoundary?.invoke(target, "DESTROY_RETURN", 0L)
                }
                observe(target, "HOLDER_DESTROYED", "drainMs:${SystemClock.uptimeMillis() - started}")
                if (unexpected) failIfCurrent(target, "surfaceDestroyedUnexpectedly")
            }

            override fun surfaceRedrawNeeded(holder: SurfaceHolder) {
                worker.requestRedraw(target, KeyguardOrbSurfaceRedrawCompletion {})
            }

            override fun surfaceRedrawNeededAsync(holder: SurfaceHolder, drawingFinished: Runnable) {
                if (KeyguardOrbSurfaceWorkerTestHooks.ENABLED) {
                    worker.requestRedraw(target, KeyguardOrbSurfaceWorkerTestHooks.redrawCompletion(target, drawingFinished))
                } else {
                    worker.requestRedraw(target, KeyguardOrbSurfaceRedrawCompletion { drawingFinished.run() })
                }
            }
        })
        root.addView(child, FrameLayout.LayoutParams(width, height, Gravity.CENTER))
        // The neutral guard, when needed, remains a sibling in the existing
        // root and above its SurfaceView hole; it is never an animation owner.
        guard?.bringToFront()
        worker.authorize(target, profile)
    }

    /** Called before root hide/remove. It never joins the render worker. */
    fun revokeCurrent(discardFull: Boolean = false, hideChild: Boolean = true,
                      onRevoked: ((Long, Long, KeyguardOrbSurfaceMetrics, KeyguardOrbSurfaceMetrics.HolderOperation) -> Unit)? = null): Boolean {
        checkMain()
        val old = current ?: return true
        worker.revoke(old, discardFull)
        val output = old.ownedOutput
        var retired = true
        if (output != null) {
            val alreadyRetired = output.isRetired()
            retired = runCatching { output.retire(old.metrics) }.getOrDefault(false)
            if (!alreadyRetired) observe(old, "R16_OUTPUT_RETIRE", "child:${output.childId},submitted:$retired")
            if (!alreadyRetired && output.disposeIfReady()) {
                old.metrics?.r16Disposed(SystemClock.uptimeMillis())
            } else if (!alreadyRetired && retiringOutput == null) {
                retiringOutput = output
            } else if (!alreadyRetired && retiringOutput !== output && overflowOutput == null) {
                overflowOutput = output
                retired = false
            } else if (!alreadyRetired && retiringOutput !== output && overflowOutput !== output) {
                // Admission is already closed when overflow is occupied.
                retired = false
            }
        }
        if (onRevoked != null) old.metrics?.let { metrics ->
            // Diagnostics must never prevent the already-revoked root from
            // becoming invisible or being removed.
            runCatching { onRevoked(old.attachment, old.generation, metrics, metrics.holderSnapshot()) }
        }
        if (hideChild || !retired) surface?.visibility = View.INVISIBLE
        return retired
    }

    fun detached() {
        checkMain()
        sealR18()
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
        direct?.dispose()
        direct = null
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
        val sample = runCatching { Bitmap.createBitmap(target.width, target.height, Bitmap.Config.ARGB_8888) }
            .getOrElse { failIfCurrent(target, "privacySampleAllocation:${it.javaClass.simpleName}"); return }
        val owned = target.ownedOutput
        val ownedSource = if (target.ownsOutput) owned?.borrow() else null
        if (target.ownsOutput && ownedSource == null) {
            sample.recycle()
            failIfCurrent(target, "r16PrivacyOutputUnavailable")
            return
        }
        // This is a producer-content check only. Compositor presentation and
        // physical removal are independently measured by the device suite.
        runCatching {
            val completed = PixelCopy.OnPixelCopyFinishedListener completed@{ result ->
                try {
                    if (!isCurrent(target) || guard !== heldGuard) return@completed
                    val center = Color.alpha(sample.getPixel(sample.width / 2, sample.height / 2))
                    val corners = intArrayOf(sample.getPixel(0, 0), sample.getPixel(sample.width - 1, 0),
                        sample.getPixel(0, sample.height - 1), sample.getPixel(sample.width - 1, sample.height - 1))
                    val expectedNeutral = currentProfile?.neutralized()?.visualKey
                    val valid = result == PixelCopy.SUCCESS && center >= 240 && corners.all { Color.alpha(it) <= 16 } &&
                        !target.full && !target.firstPostedWasFull && target.firstPostedVisualKey == expectedNeutral &&
                        (!target.ownsOutput || owned != null && target.ownedOutput === owned && !owned.isRetired())
                    if (!valid) {
                        failIfCurrent(target, "privacyProducerUnconfirmed:$result")
                    } else {
                        observe(target, "GUARD_RETIRED", "producerSampleNotCompositor")
                        root.removeView(heldGuard)
                        guard = null
                    }
                } finally {
                    if (ownedSource != null) owned?.releaseBorrow()
                    sample.recycle()
                }
            }
            if (ownedSource != null) PixelCopy.request(ownedSource, sample, completed, main)
            else PixelCopy.request(child, sample, completed, main)
        }.onFailure {
            if (ownedSource != null) owned?.releaseBorrow()
            sample.recycle()
            failIfCurrent(target, "privacyProducerSample:${it.javaClass.simpleName}")
        }
    }

    private fun isCurrent(target: KeyguardOrbSurfaceTarget): Boolean =
        current === target && !target.revoked && surface?.holder === target.holder && root.isAttachedToWindow

    private fun failIfCurrent(target: KeyguardOrbSurfaceTarget, reason: String) {
        if (current !== target) return
        revokeCurrent(discardFull = target.full, hideChild = true)
        observe(target, "DEGRADED", reason)
        onFailure(reason)
    }

    private fun observe(target: KeyguardOrbSurfaceTarget, stage: String, detail: String,
                        observedAtUptimeMs: Long = SystemClock.uptimeMillis()) {
        if (isCaptureActive()) runCatching { target.reporter?.invoke(KeyguardOrbSurfaceObservation(target.attachment, target.generation,
            stage, observedAtUptimeMs, detail, target.full, target.metrics)) }
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
