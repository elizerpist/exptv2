package com.fluvi.app.lockscreen.material

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PorterDuff
import android.os.Handler
import android.os.HandlerThread
import android.os.SystemClock
import android.os.Debug
import android.os.Build
import android.view.Choreographer
import android.view.Surface
import android.view.SurfaceHolder
import com.fluvi.app.R
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.atomic.AtomicReference

/** A distinct instance is created for each authorized Surface lifetime. */
internal class KeyguardOrbSurfaceTarget(
    val attachment: Long,
    val generation: Long,
    val holder: SurfaceHolder?,
    val width: Int,
    val height: Int,
    val densityDpi: Int,
    val full: Boolean,
    val live: Boolean,
    val reporter: ((KeyguardOrbSurfaceObservation) -> Unit)? = null,
    val access: KeyguardOrbSurfaceAccessGate = KeyguardOrbSurfaceAccessGate(),
    val metrics: KeyguardOrbSurfaceMetrics? = if (reporter == null) null else KeyguardOrbSurfaceMetrics(),
    val directOutput: KeyguardOrbDirectOutput? = null,
) {
    @Volatile var revoked = false
    @Volatile var surfaceReady = false
    @Volatile var discardFullOnRetire = false
    @Volatile var motionAllowed = true
    val ownsOutput = directOutput != null || (live && Build.VERSION.SDK_INT == 35 &&
        (!KeyguardR16LayerTestHooks.ENABLED || !KeyguardR16LayerTestHooks.stockHolder))
    // A staged direct output may receive one poster, but cannot animate until
    // the exact presentation grant is armed by the host.
    @Volatile var presentationGranted = directOutput == null
    @Volatile var ownedOutput: KeyguardOrbOwnedOutput? = null
    val shellAccess = KeyguardOrbSurfaceAccessGate()
    @Volatile var firstPostedVisualKey: String? = null
    @Volatile var firstPostedWasFull = false
    // Worker-owned: transparent host submission happens only on create/redraw.
    var shellNeedsClear = true
}

/** Immutable, once-per-boundary observations. A post is not a physical
 * presentation or an independently sampled composited pixel. */
internal data class KeyguardOrbSurfaceObservation(
    val attachment: Long,
    val generation: Long,
    val stage: String,
    val observedAtUptimeMs: Long,
    val detail: String,
    val full: Boolean,
    val metrics: KeyguardOrbSurfaceMetrics? = null,
)

/** Owns the single platform-managed holder producer and its frame clock.
 * It creates no app-owned buffer pool, does not wait on Main, and has one
 * current target and at most one pending Choreographer callback. */
internal class KeyguardOrbSurfaceWorker(
    private val context: Context,
    private val onFirstPosted: (KeyguardOrbSurfaceTarget, Long) -> Unit,
    private val onFailure: (KeyguardOrbSurfaceTarget, String) -> Unit,
    private val isCaptureActive: () -> Boolean = { false },
) {
    private class StalePreparation : RuntimeException()
    private data class PosterKey(
        val visualKey: String,
        val full: Boolean,
        val width: Int,
        val height: Int,
        val densityDpi: Int,
        val elapsed: Float,
        val phase: Float,
        val background: Float,
        val interior: Float,
    )

    private data class Poster(
        val key: PosterKey,
        val bitmap: Bitmap,
        val painter: KeyguardOrbSurfacePainter,
        val scene: KeyguardMaterialScene,
        val phase: KeyguardMaterialTime,
    )

    private val thread = HandlerThread("Fluvi-orb-surface").apply { start() }
    private val handler = Handler(thread.looper)
    private val preparationGeneration = AtomicLong()
    private val authorizedTarget = AtomicReference<KeyguardOrbSurfaceTarget?>()
    private val bitmapPaint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
    private val currentFrameTime = KeyguardOrbSurfaceFrameTime()
    private val previousFrameTime = KeyguardOrbSurfaceFrameTime()
    private val posters = LinkedHashMap<PosterKey, Poster>(2)
    private var clock: Choreographer? = null
    private var currentTarget: KeyguardOrbSurfaceTarget? = null
    private var currentScene: KeyguardMaterialScene? = null
    private var currentPainter: KeyguardOrbSurfacePainter? = null
    private var previousScene: KeyguardMaterialScene? = null
    private var previousPainter: KeyguardOrbSurfacePainter? = null
    private var transitionStartedNs = 0L
    private var currentPoster: Poster? = null
    private var firstPosted = false
    private var framePending = false
    private var pendingRedraw: KeyguardOrbSurfaceRedrawCompletion? = null
    private var lastPostedVisual: String? = null
    private var lastPostedFull = false
    private var lastPostedElapsed = 0f
    private var lastPostedPhase = 0f
    private var lastPostedBackground = 0f
    private var lastPostedInterior = 0f
    private var disposed = false

    private val frameCallback = Choreographer.FrameCallback { frameNanos ->
        framePending = false
        val target = currentTarget
        if (target != null && !target.revoked && target.surfaceReady) {
            draw(target, frameNanos)
            if (target.live && target.motionAllowed && currentTarget === target && !target.revoked) scheduleFrame()
        }
    }

    init {
        handler.post {
            clock = Choreographer.getInstance()
            currentTarget?.takeIf { !it.revoked && (pendingRedraw != null || it.live && it.motionAllowed && firstPosted) }
                ?.let { scheduleFrame() }
        }
    }

    /** Detached precomputation never creates or attaches a Surface. Superseded
     * work is discarded and no detached animation callback is scheduled. */
    fun prepare(profile: KeyguardMaterialProfile, width: Int, height: Int, densityDpi: Int, allowFull: Boolean) {
        if (authorizedTarget.get() != null) return
        val safe = profile.copyForSurface()
        val request = preparationGeneration.incrementAndGet()
        handler.post {
            if (disposed || request != preparationGeneration.get() || authorizedTarget.get() != null) return@post
            if (!allowFull) {
                posters.entries.removeAll { it.key.full }
                if (lastPostedFull) lastPostedVisual = null
            }
            val neutral = safe.neutralized().copyForSurface()
            val valid = { request == preparationGeneration.get() && authorizedTarget.get() == null }
            runCatching { getOrMakePoster(neutral, false, width, height, densityDpi, initialPhase(neutral), valid) }
            if (allowFull && request == preparationGeneration.get() && authorizedTarget.get() == null) {
                runCatching { getOrMakePoster(safe, true, width, height, densityDpi, initialPhase(safe), valid) }
            }
        }
    }

    /** Prepare exactly one neutral image in an unparented hidden output.
     * The eligibility callback is a scalar/token check and cannot use Views.
     * A created output remains private and has no animation grant. */
    fun prepareHiddenDirect(
        attachment: Long, generation: Long, width: Int, height: Int, densityDpi: Int,
        profile: KeyguardMaterialProfile, full: Boolean, lane: KeyguardOrbPresentationLane,
        stillCurrent: () -> Boolean, created: (KeyguardOrbSurfaceTarget) -> Unit,
        failed: (String) -> Unit,
    ) {
        val safe = (if (full) profile else profile.neutralized()).copyForSurface()
        val request = preparationGeneration.incrementAndGet()
        handler.post {
            if (disposed || request != preparationGeneration.get() || authorizedTarget.get() != null ||
                !runCatching { stillCurrent() }.getOrDefault(false)) return@post
            val output = try { lane.createDetached(attachment, width, height, generation) } catch (error: Throwable) {
                runCatching { failed("directCreate:${error.javaClass.simpleName}") }; return@post
            }
            if (output == null) { runCatching { failed("directCapacity") }; return@post }
            val target = KeyguardOrbSurfaceTarget(attachment, generation, null, width, height, densityDpi,
                full = full, live = true, directOutput = output)
            if (disposed || request != preparationGeneration.get() ||
                !runCatching { stillCurrent() }.getOrDefault(false) || !authorizedTarget.compareAndSet(null, target)) {
                lane.retire(output)
                return@post
            }
            stopClock()
            cancelRedraw()
            currentTarget = target
            currentScene = null
            currentPainter = null
            previousScene = null
            previousPainter = null
            currentPoster = null
            firstPosted = false
            target.surfaceReady = true
            if (runCatching { created(target) }.isFailure) {
                revoke(target)
                lane.retire(output)
                return@post
            }
            prepareAuthorized(target, safe, request)
        }
    }

    /** Main has already granted this exact lifetime; the worker still waits
     * for its real SurfaceHolder callback and verifies size before drawing. */
    fun authorize(target: KeyguardOrbSurfaceTarget, profile: KeyguardMaterialProfile) {
        val safe = (if (target.full) profile else profile.neutralized()).copyForSurface()
        val request = preparationGeneration.incrementAndGet()
        authorizedTarget.set(target)
        handler.postAtFrontOfQueue {
            if (disposed || target.revoked) return@postAtFrontOfQueue
            stopClock()
            cancelRedraw()
            currentTarget = target
            currentScene = null
            currentPainter = null
            previousScene = null
            previousPainter = null
            currentPoster = null
            firstPosted = false
            prepareAuthorized(target, safe, request)
        }
    }

    private fun prepareAuthorized(target: KeyguardOrbSurfaceTarget, safe: KeyguardMaterialProfile, request: Long) {
            val phase = if (lastPostedVisual == safe.visualKey && lastPostedFull == target.full) {
                KeyguardMaterialTime(lastPostedElapsed, lastPostedPhase, lastPostedBackground, lastPostedInterior)
            } else initialPhase(safe)
            try {
                val key = posterKey(safe, target.full, target.width, target.height, target.densityDpi, phase)
                val hit = posters.containsKey(key)
                val poster = getOrMakePoster(safe, target.full, target.width, target.height, target.densityDpi, phase) {
                    authorizedTarget.get() === target && !target.revoked && request == preparationGeneration.get()
                }
                if (target.revoked || currentTarget !== target || authorizedTarget.get() !== target ||
                    request != preparationGeneration.get()) return
                currentPoster = poster
                currentPainter = poster.painter
                currentScene = poster.scene.anchoredAt(poster.phase, System.nanoTime())
                observe(target, "POSTER", if (hit) "hit" else "missPreparedOnWorker")
                drawIfReady(target)
            } catch (_: StalePreparation) {
                // A newer material/lifetime owns the next worker message.
            } catch (error: Throwable) {
                fail(target, "prepare:${error.javaClass.simpleName}")
            }
    }

    /** A compatible palette/effect update retains the running phase and the
     * existing 180 ms transition on this one producer. */
    fun update(target: KeyguardOrbSurfaceTarget, profile: KeyguardMaterialProfile) {
        val safe = (if (target.full) profile else profile.neutralized()).copyForSurface()
        val request = preparationGeneration.incrementAndGet()
        handler.post {
            if (disposed || currentTarget !== target || target.revoked || request != preparationGeneration.get()) return@post
            val old = currentScene
            if (old == null) {
                prepareAuthorized(target, safe, request)
                return@post
            }
            if (old.profile.visualKey == safe.visualKey) return@post
            try {
                val now = System.nanoTime()
                old.timeAtInto(now, currentFrameTime)
                val phase = if (old.profile.effectId == safe.effectId) {
                    KeyguardMaterialTime(currentFrameTime.elapsedSeconds, currentFrameTime.phase,
                        currentFrameTime.backgroundPhase, currentFrameTime.interiorPhase)
                } else initialPhase(safe)
                val next = KeyguardMaterialScene(safe, target.full, now).anchoredAt(phase, now)
                val poster = getOrMakePoster(safe, target.full, target.width, target.height, target.densityDpi, phase) {
                    authorizedTarget.get() === target && !target.revoked && request == preparationGeneration.get()
                }
                if (target.revoked || currentTarget !== target || authorizedTarget.get() !== target ||
                    request != preparationGeneration.get()) return@post
                previousScene = if (target.live) old else null
                previousPainter = if (target.live) currentPainter else null
                transitionStartedNs = now
                currentScene = next
                currentPainter = poster.painter
                currentPoster = poster
                scheduleFrame()
            } catch (_: StalePreparation) {
                // The most recent queued semantic update will prepare instead.
            } catch (error: Throwable) {
                fail(target, "materialUpdate:${error.javaClass.simpleName}")
            }
        }
    }

    fun surfaceReady(target: KeyguardOrbSurfaceTarget) {
        target.surfaceReady = true
        handler.postAtFrontOfQueue {
            if (!disposed && currentTarget === target && !target.revoked) drawIfReady(target)
        }
    }

    fun setMotionAllowed(target: KeyguardOrbSurfaceTarget, allowed: Boolean) {
        target.motionAllowed = allowed
        handler.postAtFrontOfQueue {
            if (currentTarget !== target || target.revoked || !target.live) return@postAtFrontOfQueue
            if (!allowed) {
                stopClock()
            } else {
                val scene = currentScene ?: return@postAtFrontOfQueue
                if (lastPostedVisual == scene.profile.visualKey && lastPostedFull == scene.full) {
                    val phase = KeyguardMaterialTime(lastPostedElapsed, lastPostedPhase, lastPostedBackground, lastPostedInterior)
                    currentScene = scene.anchoredAt(phase, System.nanoTime())
                }
                scheduleFrame()
            }
        }
    }

    /** The detached first frame is only a preparation. This separate call
     * starts motion after the current host and disclosure have been granted. */
    fun grantPresentation(target: KeyguardOrbSurfaceTarget) {
        if (target.revoked || target.directOutput == null) return
        target.presentationGranted = true
        handler.postAtFrontOfQueue {
            if (currentTarget !== target || target.revoked || !target.presentationGranted) return@postAtFrontOfQueue
            val scene = currentScene ?: return@postAtFrontOfQueue
            if (lastPostedVisual == scene.profile.visualKey && lastPostedFull == scene.full) {
                val phase = KeyguardMaterialTime(lastPostedElapsed, lastPostedPhase, lastPostedBackground, lastPostedInterior)
                currentScene = scene.anchoredAt(phase, System.nanoTime())
            }
            if (target.live && target.motionAllowed && firstPosted) scheduleFrame()
        }
    }

    fun requestRedraw(target: KeyguardOrbSurfaceTarget, completion: KeyguardOrbSurfaceRedrawCompletion) {
        handler.post {
            if (disposed || currentTarget !== target || target.revoked) {
                completion.complete()
                return@post
            }
            cancelRedraw()
            pendingRedraw = completion
            if (target.ownsOutput) target.shellNeedsClear = true
            if (target.surfaceReady) scheduleFrame()
        }
    }

    /** Revocation is synchronous and never waits for a holder operation. */
    fun revoke(target: KeyguardOrbSurfaceTarget, discardFull: Boolean = false) {
        if (discardFull) target.discardFullOnRetire = true
        val measuredRevoke = !target.revoked && target.metrics != null && isCaptureActive()
        if (measuredRevoke) target.metrics?.revokeStarted(SystemClock.uptimeMillis())
        target.revoked = true
        target.access.revoke()
        if (target.ownsOutput) target.shellAccess.revoke()
        if (measuredRevoke) target.metrics?.revokeReturned(SystemClock.uptimeMillis())
        if (authorizedTarget.compareAndSet(target, null)) preparationGeneration.incrementAndGet()
        handler.postAtFrontOfQueue {
            val retiredScene = currentScene.takeIf { currentTarget === target }
            if (target.discardFullOnRetire) {
                posters.entries.removeAll { it.key.full }
                if (lastPostedFull) lastPostedVisual = null
            }
            if (currentTarget === target) {
                stopClock()
                cancelRedraw()
                currentTarget = null
                currentScene = null
                currentPainter = null
                previousScene = null
                previousPainter = null
                currentPoster = null
                observe(target, "REVOKED", "noFurtherHolderAdmission")
            }
            // A warm poster represents the last actually submitted phase;
            // no detached frame callback or live Surface is retained.
            if (!target.discardFullOnRetire && retiredScene != null && lastPostedVisual == retiredScene.profile.visualKey &&
                lastPostedFull == retiredScene.full && authorizedTarget.get() == null
            ) runCatching {
                val phase = KeyguardMaterialTime(lastPostedElapsed, lastPostedPhase, lastPostedBackground, lastPostedInterior)
                val request = preparationGeneration.get()
                getOrMakePoster(retiredScene.profile, retiredScene.full, target.width, target.height,
                    target.densityDpi, phase) { authorizedTarget.get() == null && request == preparationGeneration.get() }
            }
        }
    }

    /** Called from the holder callback after invalidating authority. */
    fun surfaceDestroyed(target: KeyguardOrbSurfaceTarget) {
        target.surfaceReady = false
        revoke(target)
        // The system may destroy its holder only after shell operations end.
        // A draw on the separately owned child must not block this callback.
        if (target.ownsOutput) target.shellAccess.destroyAndAwait() else target.access.destroyAndAwait()
    }

    fun dispose() {
        preparationGeneration.incrementAndGet()
        authorizedTarget.getAndSet(null)?.let { it.revoked = true; it.access.revoke() }
        handler.postAtFrontOfQueue {
            disposed = true
            currentTarget?.let { it.revoked = true; it.access.revoke() }
            stopClock()
            cancelRedraw()
            currentTarget = null
            currentPoster = null
            currentPainter = null
            previousPainter = null
            posters.clear()
            thread.quitSafely()
        }
    }

    private fun initialPhase(profile: KeyguardMaterialProfile) = KeyguardMaterialTime(
        profile.elapsedSeconds, profile.phase, profile.background.phase, profile.interior.phase,
    )

    private fun posterKey(profile: KeyguardMaterialProfile, full: Boolean, width: Int, height: Int,
                          densityDpi: Int, phase: KeyguardMaterialTime) = PosterKey(
        profile.visualKey, full, width, height, densityDpi, phase.elapsedSeconds, phase.phase,
        phase.backgroundPhase, phase.interiorPhase,
    )

    private fun getOrMakePoster(profile: KeyguardMaterialProfile, full: Boolean, width: Int, height: Int,
                                densityDpi: Int, phase: KeyguardMaterialTime,
                                valid: () -> Boolean): Poster {
        val supported = context.resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_orb_size)
        require(supported in 1..4096 && width == supported && height == supported)
        if (!valid()) throw StalePreparation()
        val key = posterKey(profile, full, width, height, densityDpi, phase)
        posters[key]?.let { return it }
        val scene = KeyguardMaterialScene(profile, full, System.nanoTime()).anchoredAt(phase, System.nanoTime())
        val painter = KeyguardOrbSurfacePainter(context, profile, width, height)
        val poster = Poster(key, painter.makePoster(phase), painter, scene, phase)
        if (!valid()) {
            poster.bitmap.recycle()
            throw StalePreparation()
        }
        while (posters.size >= 2) posters.remove(posters.keys.first())
        posters[key] = poster
        return poster
    }

    private fun drawIfReady(target: KeyguardOrbSurfaceTarget) {
        if (currentTarget !== target || target.revoked || !target.surfaceReady) return
        if (target.directOutput == null && target.ownsOutput && target.shellNeedsClear && !clearHost(target)) return
        if (currentPoster == null) return
        if (!firstPosted) draw(target, System.nanoTime())
        if (target.live && target.motionAllowed && firstPosted && !target.revoked) scheduleFrame()
    }

    private fun scheduleFrame() {
        if (currentTarget?.let { it.directOutput != null && !it.presentationGranted } == true) return
        if (framePending || disposed) return
        val choreographer = clock ?: return
        framePending = true
        choreographer.postFrameCallback(frameCallback)
    }

    private fun stopClock() {
        if (framePending) clock?.removeFrameCallback(frameCallback)
        framePending = false
    }

    private fun cancelRedraw() {
        val completion = pendingRedraw
        pendingRedraw = null
        completion?.complete()
    }

    /** The framework host gets only a transparent buffer, never ORB pixels. */
    private fun clearHost(target: KeyguardOrbSurfaceTarget): Boolean {
        if (!target.shellAccess.tryEnter()) return false
        var canvas: Canvas? = null
        try {
            canvas = checkNotNull(target.holder).lockHardwareCanvas()
            canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)
            val posted = canvas
            canvas = null
            checkNotNull(target.holder).unlockCanvasAndPost(posted)
            target.shellNeedsClear = false
            return true
        } catch (error: Throwable) {
            fail(target, "hostClear:${error.javaClass.simpleName}")
            return false
        } finally {
            if (canvas != null) runCatching { checkNotNull(target.holder).unlockCanvasAndPost(canvas) }
            target.shellAccess.leave()
        }
    }

    private fun draw(target: KeyguardOrbSurfaceTarget, frameNanos: Long) {
        if (target.directOutput == null && target.ownsOutput && target.shellNeedsClear && !clearHost(target)) return
        val scene = currentScene ?: return
        val painter = currentPainter ?: return
        if (currentTarget !== target || target.revoked || !target.surfaceReady) return
        val first = !firstPosted
        var distinct = false
        var previousForFrame: KeyguardOrbSurfacePainter? = null
        // Scene arithmetic and RuntimeShader uniform updates are worker-only,
        // but must not extend the holder operation surfaceDestroyed drains.
        if (!first && target.live) try {
            if (target.motionAllowed) scene.timeAtInto(frameNanos, currentFrameTime)
            else {
                currentFrameTime.elapsedSeconds = lastPostedElapsed
                currentFrameTime.phase = lastPostedPhase
                currentFrameTime.backgroundPhase = lastPostedBackground
                currentFrameTime.interiorPhase = lastPostedInterior
            }
            distinct = currentFrameTime.elapsedSeconds != lastPostedElapsed || currentFrameTime.phase != lastPostedPhase ||
                currentFrameTime.backgroundPhase != lastPostedBackground || currentFrameTime.interiorPhase != lastPostedInterior
            val old = previousScene
            val oldPainter = previousPainter
            val progress = if (old == null) 1f else ((frameNanos - transitionStartedNs) / 180_000_000f).coerceIn(0f, 1f)
            if (old != null && oldPainter != null && progress < 1f) {
                old.timeAtInto(frameNanos, previousFrameTime)
                oldPainter.prepare(previousFrameTime)
                previousForFrame = oldPainter
                painter.prepare(currentFrameTime, progress)
            } else {
                previousScene = null
                previousPainter = null
                painter.prepare(currentFrameTime)
            }
        } catch (error: Throwable) {
            fail(target, "configure:${error.javaClass.simpleName}")
            return
        }
        if (currentTarget !== target || target.revoked || !target.surfaceReady || !target.access.tryEnter()) return
        val owned = target.ownedOutput
        val direct = target.directOutput
        val outputSurface: Surface? = when {
            direct != null -> direct.borrow()
            target.ownsOutput -> owned?.borrow()
            else -> null
        }
        if (target.ownsOutput && outputSurface == null) {
            target.access.leave()
            return
        }
        var canvas: Canvas? = null
        var posted = false
        val measure = target.metrics != null && isCaptureActive()
        if (measure) target.metrics?.beginHolderOperation(SystemClock.uptimeMillis())
        val lockStart = if (measure) System.nanoTime() else 0L
        val cpuStart = if (measure) Debug.threadCpuTimeNanos() else 0L
        var lockEnd = 0L; var drawEnd = 0L; var postEnd = 0L
        var cpuLockEnd = 0L; var cpuDrawEnd = 0L; var cpuPostEnd = 0L
        try {
            canvas = if (outputSurface != null) outputSurface.lockHardwareCanvas() else checkNotNull(target.holder).lockHardwareCanvas()
            if (measure) { lockEnd = System.nanoTime(); cpuLockEnd = Debug.threadCpuTimeNanos(); target.metrics?.holderLockReturned(SystemClock.uptimeMillis()) }
            if (KeyguardOrbSurfaceWorkerTestHooks.ENABLED) {
                KeyguardOrbSurfaceWorkerTestHooks.afterCanvasLock?.invoke(target)
            }
            canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)
            if (!firstPosted || !target.live) {
                canvas.drawBitmap(checkNotNull(currentPoster).bitmap, 0f, 0f, bitmapPaint)
            } else {
                previousForFrame?.drawPrepared(canvas)
                painter.drawPrepared(canvas)
            }
            if (measure) { drawEnd = System.nanoTime(); cpuDrawEnd = Debug.threadCpuTimeNanos(); target.metrics?.holderDrawReturned(SystemClock.uptimeMillis()) }
            val submitted = canvas
            canvas = null
            if (measure) target.metrics?.holderPostEntered(SystemClock.uptimeMillis())
            if (outputSurface != null) outputSurface.unlockCanvasAndPost(submitted)
            else checkNotNull(target.holder).unlockCanvasAndPost(submitted)
            posted = true
            if (KeyguardOrbSurfaceWorkerTestHooks.ENABLED) {
                runCatching { KeyguardOrbSurfaceWorkerTestHooks.afterCanvasPost?.invoke(target) }
            }
            if (measure) { postEnd = System.nanoTime(); cpuPostEnd = Debug.threadCpuTimeNanos(); target.metrics?.holderPostReturned(SystemClock.uptimeMillis()) }
        } catch (error: Throwable) {
            fail(target, "draw:${error.javaClass.simpleName}")
        } finally {
            if (canvas != null) runCatching {
                if (outputSurface != null) outputSurface.unlockCanvasAndPost(canvas)
                else checkNotNull(target.holder).unlockCanvasAndPost(canvas)
            }
            if (outputSurface != null) {
                if (direct != null) direct.releaseBorrow() else owned?.releaseBorrow()
            }
            target.access.leave()
        }
        if (posted && measure) {
            target.metrics?.record(SystemClock.uptimeMillis(), postEnd, !first && distinct,
                (lockEnd - lockStart).coerceAtLeast(0L), (drawEnd - lockEnd).coerceAtLeast(0L),
                (postEnd - drawEnd).coerceAtLeast(0L), (cpuLockEnd - cpuStart).coerceAtLeast(0L),
                (cpuDrawEnd - cpuLockEnd).coerceAtLeast(0L), (cpuPostEnd - cpuDrawEnd).coerceAtLeast(0L))
            target.metrics?.holderRecordObserved(SystemClock.uptimeMillis())
            if (target.revoked) target.metrics?.r16PinLateOperation()
        }
        if (!posted || currentTarget !== target || target.revoked) return
        if (!firstPosted) {
            firstPosted = true
            target.firstPostedVisualKey = scene.profile.visualKey
            target.firstPostedWasFull = scene.full
            val phase = checkNotNull(currentPoster).phase
            currentScene = scene.anchoredAt(phase, System.nanoTime())
            lastPostedElapsed = phase.elapsedSeconds
            lastPostedPhase = phase.phase
            lastPostedBackground = phase.backgroundPhase
            lastPostedInterior = phase.interiorPhase
            lastPostedVisual = scene.profile.visualKey
            lastPostedFull = scene.full
            runCatching { onFirstPosted(target, SystemClock.uptimeMillis()) }
        } else if (target.live) {
            lastPostedElapsed = currentFrameTime.elapsedSeconds
            lastPostedPhase = currentFrameTime.phase
            lastPostedBackground = currentFrameTime.backgroundPhase
            lastPostedInterior = currentFrameTime.interiorPhase
            lastPostedVisual = scene.profile.visualKey
            lastPostedFull = scene.full
        } else {
            val phase = checkNotNull(currentPoster).phase
            lastPostedElapsed = phase.elapsedSeconds
            lastPostedPhase = phase.phase
            lastPostedBackground = phase.backgroundPhase
            lastPostedInterior = phase.interiorPhase
            lastPostedVisual = scene.profile.visualKey
            lastPostedFull = scene.full
        }
        cancelRedraw()
    }

    private fun observe(target: KeyguardOrbSurfaceTarget, stage: String, detail: String) {
        if (isCaptureActive()) runCatching {
            target.reporter?.invoke(KeyguardOrbSurfaceObservation(target.attachment, target.generation, stage,
                SystemClock.uptimeMillis(), detail, target.full, target.metrics))
        }
    }

    private fun fail(target: KeyguardOrbSurfaceTarget, reason: String) {
        if (currentTarget !== target || target.revoked) return
        target.revoked = true
        target.access.revoke()
        stopClock()
        cancelRedraw()
        onFailure(target, reason)
    }
}
