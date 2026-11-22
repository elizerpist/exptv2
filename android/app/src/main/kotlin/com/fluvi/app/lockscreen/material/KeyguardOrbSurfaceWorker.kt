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
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.atomic.AtomicReference

/** Immutable identity for the one authorized first FULL write. It carries
 * no bitmap, accessibility object or financial payload. */
internal data class KeyguardR19FirstPaintTicket(
    val attachment: Long, val generation: Long, val requestId: Long,
    val sceneSerial: Long, val dataRevision: Long, val visualKey: String,
)

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
    val firstDirectAuthorization = AtomicReference<KeyguardR19FirstPaintTicket?>()
    // Boundary-only public-program diagnostics; never carries profile data.
    val blankBindPending = AtomicBoolean(false)
    @Volatile var r27WarmStatus = "NOT_REQUESTED"
    @Volatile var r27WarmSelector: String? = null
    @Volatile var r27LoadNs = 0L
    @Volatile var r27WorkerQueueNs = 0L
    @Volatile var r27ConstructorNs = 0L
    @Volatile var r27Overlap = false
    // Worker-owned: transparent host submission happens only on create/redraw.
    var shellNeedsClear = true
}

/** First-write milestones use the monotonic nanosecond clock. Zero means
 * that the boundary was not observed, not that it took no time. */
internal data class KeyguardR20FirstFrameObservation(
    val requestId: Long, val method: String, val entryNs: Long,
    val painterStartNs: Long, val painterEndNs: Long, val configureEndNs: Long,
    val lockBeginNs: Long, val lockReturnNs: Long, val drawEndNs: Long,
    val postReturnNs: Long, val failure: String?,
    val warmStatus: String = "UNOBSERVED", val warmSelector: String? = null,
    val warmLoadNs: Long = 0L, val warmQueueNs: Long = 0L, val warmConstructorNs: Long = 0L,
    val warmOverlap: Boolean = false,
)

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
    val firstFrame: KeyguardR20FirstFrameObservation? = null,
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

    /** These objects are worker-owned and exist only during one authorized
     * first write; no private image or Android surface crosses this state. */
    private data class FirstSelection(
        val target: KeyguardOrbSurfaceTarget,
        val ticket: KeyguardR19FirstPaintTicket,
        val phase: KeyguardMaterialTime,
        val request: Long,
        val direct: Boolean,
    )
    private class FirstMeasurement(
        val target: KeyguardOrbSurfaceTarget,
        val ticket: KeyguardR19FirstPaintTicket,
        val entryNs: Long,
    ) {
        var method = "UNOBSERVED"
        var painterStartNs = 0L; var painterEndNs = 0L; var configureEndNs = 0L
        var lockBeginNs = 0L; var lockReturnNs = 0L; var drawEndNs = 0L; var postReturnNs = 0L
    }

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
    private var firstSelection: FirstSelection? = null
    private var firstMeasurement: FirstMeasurement? = null
    private data class WarmProgram(val target: KeyguardOrbSurfaceTarget,
        val selector: KeyguardOrbProgramSelector, val shader: KeyguardHeaderShader)
    // Only touched by the render worker. A mutable shader never crosses owners.
    private var warmProgram: WarmProgram? = null
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
        profile: KeyguardMaterialProfile?, full: Boolean, lane: KeyguardOrbPresentationLane,
        stillCurrent: () -> Boolean, created: (KeyguardOrbSurfaceTarget) -> Unit,
        failed: (String) -> Unit, emptyAwaitingDisclosure: Boolean = false,
        reporter: ((KeyguardOrbSurfaceObservation) -> Unit)? = null,
    ) {
        require(!emptyAwaitingDisclosure || (full && profile == null))
        val safe = profile?.let { (if (full) it else it.neutralized()).copyForSurface() }
        require(emptyAwaitingDisclosure || safe != null)
        val request = preparationGeneration.incrementAndGet()
        handler.post {
            if (disposed || request != preparationGeneration.get() || authorizedTarget.get() != null ||
                !runCatching { stillCurrent() }.getOrDefault(false)) return@post
            val output = try { lane.createDetached(attachment, width, height, generation) } catch (error: Throwable) {
                runCatching { failed("directCreate:${error.javaClass.simpleName}") }; return@post
            }
            if (output == null) { runCatching { failed("directCapacity") }; return@post }
            val target = KeyguardOrbSurfaceTarget(attachment, generation, null, width, height, densityDpi,
                full = full, live = true, reporter = reporter, directOutput = output)
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
            firstSelection = null
            firstMeasurement?.target?.let { finishFirstObservation(it, "REPLACED") }
            firstMeasurement = null
            firstPosted = false
            target.surfaceReady = true
            if (runCatching { created(target) }.isFailure) {
                revoke(target)
                lane.retire(output)
                return@post
            }
            if (safe != null) prepareAuthorized(target, safe, request)
        }
    }

    /** This work is speculative only while the exact virgin owner remains
     * idle. It never configures uniforms or touches a canvas or output. */
    fun prewarmDirect(target: KeyguardOrbSurfaceTarget, selector: KeyguardOrbProgramSelector,
                      artifact: KeyguardShaderArtifact, ownerCurrent: () -> Boolean) {
        val queuedAt = System.nanoTime()
        handler.post {
            target.r27WorkerQueueNs = System.nanoTime() - queuedAt
            if (disposed || target.revoked || currentTarget !== target || authorizedTarget.get() !== target ||
                !ownerCurrent() || target.firstDirectAuthorization.get() != null || target.blankBindPending.get()) {
                target.r27WarmStatus = "STALE_OR_BUSY"
                return@post
            }
            if (!selector.accepts(artifact)) { target.r27WarmStatus = "BAD_ARTIFACT"; return@post }
            if (target.firstDirectAuthorization.get() != null || target.blankBindPending.get()) {
                target.r27WarmStatus = "STALE_OR_BUSY"; return@post
            }
            val start = System.nanoTime()
            val shader = runCatching {
                if (KeyguardOrbSurfaceWorkerTestHooks.ENABLED)
                    KeyguardOrbSurfaceWorkerTestHooks.onDirectProgramConstructor?.invoke(target, "WARM")
                KeyguardHeaderShader(artifact)
            }.getOrNull()
            target.r27ConstructorNs = System.nanoTime() - start
            target.r27Overlap = target.firstDirectAuthorization.get() != null
            if (shader == null) { target.r27WarmStatus = "CONSTRUCTOR_FAILED"; return@post }
            if (disposed || target.revoked || currentTarget !== target || authorizedTarget.get() !== target || !ownerCurrent()) {
                target.r27WarmStatus = "STALE"; return@post
            }
            warmProgram = WarmProgram(target, selector, shader)
            target.r27WarmStatus = "READY"
            if (KeyguardOrbSurfaceWorkerTestHooks.ENABLED)
                KeyguardOrbSurfaceWorkerTestHooks.afterDirectProgramWarm?.invoke(target)
        }
    }

    /** One initial paint on the already allocated virgin target. The caller
     * holds a current complete disclosure proof; this method grants no show. */
    fun authorizeDirectFirst(target: KeyguardOrbSurfaceTarget, profile: KeyguardMaterialProfile,
                             ticket: KeyguardR19FirstPaintTicket): Boolean {
        if (target.directOutput == null || !target.full || target.revoked || ticket.attachment != target.attachment ||
            ticket.generation != target.generation || ticket.requestId <= 0 || ticket.visualKey != profile.visualKey ||
            authorizedTarget.get() !== target || !target.firstDirectAuthorization.compareAndSet(null, ticket)) return false
        val safe = profile.copyForSurface()
        val request = preparationGeneration.incrementAndGet()
        val accepted = handler.post {
            if (!disposed && !target.revoked && currentTarget === target && authorizedTarget.get() === target &&
                request == preparationGeneration.get() && target.firstDirectAuthorization.get() === ticket)
                prepareAuthorized(target, safe, request, ticket)
        }
        return accepted
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
            firstSelection = null
            firstMeasurement?.target?.let { finishFirstObservation(it, "REPLACED") }
            firstMeasurement = null
            firstPosted = false
            prepareAuthorized(target, safe, request)
        }
    }

    private fun prepareAuthorized(target: KeyguardOrbSurfaceTarget, safe: KeyguardMaterialProfile, request: Long,
                                  firstTicket: KeyguardR19FirstPaintTicket? = null) {
        val enteredNs = if (firstTicket != null && runCatching { isCaptureActive() }.getOrDefault(false)) System.nanoTime() else 0L
        if (target.directOutput != null) observe(target, "R19_PAINT_ENTER", "worker")
        val phase = if (lastPostedVisual == safe.visualKey && lastPostedFull == target.full) {
            KeyguardMaterialTime(lastPostedElapsed, lastPostedPhase, lastPostedBackground, lastPostedInterior)
        } else initialPhase(safe)
        val measurement = if (firstTicket != null && enteredNs != 0L)
            FirstMeasurement(target, firstTicket, enteredNs).also { firstMeasurement = it } else null
        val valid = {
            !disposed && authorizedTarget.get() === target && currentTarget === target && !target.revoked &&
                request == preparationGeneration.get() &&
                (firstTicket == null || target.firstDirectAuthorization.get() === firstTicket)
        }
        try {
            // The same exact supported size and complete cache key apply to
            // both the poster path and the ticket-qualified direct miss.
            validatePosterSize(target.width, target.height)
            if (!valid()) throw StalePreparation()
            val key = posterKey(safe, target.full, target.width, target.height, target.densityDpi, phase)
            val cached = posters[key]
            if (firstTicket != null) firstSelection = FirstSelection(target, firstTicket, phase, request, cached == null)
            if (firstTicket != null && cached == null) {
                measurement?.method = "DIRECT_MISS"
                if (measurement != null) measurement.painterStartNs = System.nanoTime()
                val now = System.nanoTime()
                val scene = KeyguardMaterialScene(safe, target.full, now).anchoredAt(phase, now)
                val selector = KeyguardOrbProgramSelector.forProfile(safe)
                val ready = warmProgram?.takeIf { it.target === target && it.selector == selector }
                if (ready != null) {
                    warmProgram = null
                    target.r27WarmStatus = "HIT"
                } else if (selector != null) {
                    if (target.r27WarmStatus == "READY") target.r27WarmStatus = "STALE"
                    else if (target.r27WarmStatus == "LOADING" || target.r27WarmStatus == "NOT_REQUESTED")
                        target.r27WarmStatus = "NO_READY"
                    if (KeyguardOrbSurfaceWorkerTestHooks.ENABLED)
                        KeyguardOrbSurfaceWorkerTestHooks.onDirectProgramConstructor?.invoke(target, "COLD")
                }
                val painter = KeyguardOrbSurfacePainter(context, safe, target.width, target.height, ready?.shader)
                if (measurement != null) measurement.painterEndNs = System.nanoTime()
                if (!valid()) throw StalePreparation()
                currentPoster = null
                currentPainter = painter
                currentScene = scene
            } else {
                if (measurement != null) measurement.method = "BITMAP_HIT"
                val poster = cached ?: getOrMakePoster(safe, target.full, target.width, target.height,
                    target.densityDpi, phase, valid)
                if (!valid()) throw StalePreparation()
                currentPoster = poster
                currentPainter = poster.painter
                currentScene = poster.scene.anchoredAt(poster.phase, System.nanoTime())
                observe(target, "POSTER", if (cached != null) "hit" else "missPreparedOnWorker")
            }
            drawIfReady(target)
        } catch (_: StalePreparation) {
            finishFirstObservation(target, "STALE_PREPARE")
        } catch (error: Throwable) {
            finishFirstObservation(target, "PREPARE:${error.javaClass.simpleName}")
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
                finishFirstObservation(target, "SUPERSEDED")
                firstSelection = null
                prepareAuthorized(target, safe, request)
                return@post
            }
            if (old.profile.visualKey == safe.visualKey) {
                val selection = firstSelection
                if (!firstPosted && selection?.target === target &&
                    target.firstDirectAuthorization.get() === selection.ticket) {
                    firstSelection = selection.copy(request = request)
                    drawIfReady(target)
                }
                return@post
            }
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
                val replacingFirst = firstSelection?.target === target
                if (replacingFirst) finishFirstObservation(target, "SUPERSEDED")
                firstSelection = null
                previousScene = if (target.live) old else null
                previousPainter = if (target.live) currentPainter else null
                transitionStartedNs = now
                currentScene = next
                currentPainter = poster.painter
                currentPoster = poster
                if (replacingFirst && !firstPosted) drawIfReady(target) else scheduleFrame()
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
            target.metrics?.beginDirectPresentation(SystemClock.uptimeMillis())
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
            if (warmProgram?.target === target) warmProgram = null
            val retiredScene = currentScene.takeIf { currentTarget === target }
            if (target.discardFullOnRetire) {
                posters.entries.removeAll { it.key.full }
                if (lastPostedFull) lastPostedVisual = null
            }
            if (currentTarget === target) {
                finishFirstObservation(target, "REVOKED")
                firstSelection = null
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
            currentTarget?.let { finishFirstObservation(it, "DISPOSED"); it.revoked = true; it.access.revoke() }
            firstSelection = null
            stopClock()
            cancelRedraw()
            currentTarget = null
            currentPoster = null
            currentPainter = null
            previousPainter = null
            warmProgram = null
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

    private fun validatePosterSize(width: Int, height: Int) {
        val supported = context.resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_orb_size)
        require(supported in 1..4096 && width == supported && height == supported)
    }

    private fun getOrMakePoster(profile: KeyguardMaterialProfile, full: Boolean, width: Int, height: Int,
                                densityDpi: Int, phase: KeyguardMaterialTime,
                                valid: () -> Boolean): Poster {
        validatePosterSize(width, height)
        if (!valid()) throw StalePreparation()
        val key = posterKey(profile, full, width, height, densityDpi, phase)
        posters[key]?.let { return it }
        val scene = KeyguardMaterialScene(profile, full, System.nanoTime()).anchoredAt(phase, System.nanoTime())
        val painter = KeyguardOrbSurfacePainter(context, profile, width, height)
        val poster = Poster(key, painter.makePoster(phase), painter, scene, phase)
        if (KeyguardOrbSurfaceWorkerTestHooks.ENABLED) {
            authorizedTarget.get()?.let { current ->
                runCatching { KeyguardOrbSurfaceWorkerTestHooks.afterPosterCreated?.invoke(current) }
            }
        }
        if (!valid()) {
            poster.bitmap.recycle()
            throw StalePreparation()
        }
        while (posters.size >= 2) posters.remove(posters.keys.first())
        posters[key] = poster
        if (KeyguardOrbSurfaceWorkerTestHooks.ENABLED) {
            runCatching { KeyguardOrbSurfaceWorkerTestHooks.afterWarmPosterCreated?.invoke(full) }
        }
        return poster
    }

    private fun drawIfReady(target: KeyguardOrbSurfaceTarget) {
        if (currentTarget !== target || target.revoked || !target.surfaceReady) return
        if (target.directOutput == null && target.ownsOutput && target.shellNeedsClear && !clearHost(target)) return
        if (currentPoster == null && firstSelection?.let { it.target === target && it.direct } != true) return
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
        val selection = if (first) firstSelection else null
        if (selection != null && (selection.target !== target || authorizedTarget.get() !== target ||
                target.firstDirectAuthorization.get() !== selection.ticket ||
                selection.request != preparationGeneration.get())) {
            finishFirstObservation(target, "STALE_SELECTION")
            return
        }
        val firstDirect = selection?.direct == true
        val firstTiming = if (first) firstMeasurement?.takeIf { it.target === target &&
            (selection == null || it.ticket === selection.ticket) } else null
        if (firstDirect) try {
            val phase = checkNotNull(selection).phase
            currentFrameTime.elapsedSeconds = phase.elapsedSeconds
            currentFrameTime.phase = phase.phase
            currentFrameTime.backgroundPhase = phase.backgroundPhase
            currentFrameTime.interiorPhase = phase.interiorPhase
            if (KeyguardOrbSurfaceWorkerTestHooks.ENABLED) {
                KeyguardOrbSurfaceWorkerTestHooks.fixedMaterialTime?.let {
                    currentFrameTime.elapsedSeconds = it.elapsedSeconds
                    currentFrameTime.phase = it.phase
                    currentFrameTime.backgroundPhase = it.backgroundPhase
                    currentFrameTime.interiorPhase = it.interiorPhase
                }
            }
            painter.prepare(currentFrameTime)
            if (firstTiming != null) firstTiming.configureEndNs = System.nanoTime()
        } catch (error: Throwable) {
            finishFirstObservation(target, "CONFIGURE:${error.javaClass.simpleName}")
            fail(target, "configure:${error.javaClass.simpleName}")
            return
        }
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
            if (KeyguardOrbSurfaceWorkerTestHooks.ENABLED) {
                KeyguardOrbSurfaceWorkerTestHooks.fixedMaterialTime?.let {
                    currentFrameTime.elapsedSeconds = it.elapsedSeconds
                    currentFrameTime.phase = it.phase
                    currentFrameTime.backgroundPhase = it.backgroundPhase
                    currentFrameTime.interiorPhase = it.interiorPhase
                }
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
        if (currentTarget !== target || target.revoked || !target.surfaceReady ||
            (selection != null && (authorizedTarget.get() !== target || !target.full ||
                selection.ticket.visualKey != scene.profile.visualKey ||
                target.firstDirectAuthorization.get() !== selection.ticket ||
                selection.request != preparationGeneration.get())) || !target.access.tryEnter()) {
            if (first) finishFirstObservation(target, "STALE_BEFORE_LOCK")
            return
        }
        val owned = target.ownedOutput
        val direct = target.directOutput
        val outputSurface: Surface? = when {
            direct != null -> direct.borrow()
            target.ownsOutput -> owned?.borrow()
            else -> null
        }
        if (target.ownsOutput && outputSurface == null) {
            target.access.leave()
            if (selection != null && !target.revoked && currentTarget === target) {
                finishFirstObservation(target, "BORROW")
                fail(target, "firstBorrowUnavailable")
            }
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
        var firstFailureStage = "LOCK"
        try {
            if (first && KeyguardOrbSurfaceWorkerTestHooks.ENABLED) KeyguardOrbSurfaceWorkerTestHooks.beforeFirstLock?.invoke(target)
            if (firstTiming != null) firstTiming.lockBeginNs = System.nanoTime()
            canvas = if (outputSurface != null) outputSurface.lockHardwareCanvas() else checkNotNull(target.holder).lockHardwareCanvas()
            if (firstTiming != null) firstTiming.lockReturnNs = System.nanoTime()
            if (firstDirect) check(canvas.isHardwareAccelerated) { "direct first frame requires hardware canvas" }
            if (measure) { lockEnd = System.nanoTime(); cpuLockEnd = Debug.threadCpuTimeNanos(); target.metrics?.holderLockReturned(SystemClock.uptimeMillis()) }
            if (KeyguardOrbSurfaceWorkerTestHooks.ENABLED) {
                KeyguardOrbSurfaceWorkerTestHooks.afterCanvasLock?.invoke(target)
            }
            firstFailureStage = "DRAW"
            canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)
            if (firstDirect) {
                painter.drawPrepared(canvas)
            } else if (first || !target.live) {
                canvas.drawBitmap(checkNotNull(currentPoster).bitmap, 0f, 0f, bitmapPaint)
            } else {
                previousForFrame?.drawPrepared(canvas)
                painter.drawPrepared(canvas)
            }
            if (firstTiming != null) firstTiming.drawEndNs = System.nanoTime()
            if (first && KeyguardOrbSurfaceWorkerTestHooks.ENABLED) {
                runCatching { KeyguardOrbSurfaceWorkerTestHooks.afterFirstFrameDraw?.invoke(target, if (firstDirect) "DIRECT_MISS" else "BITMAP") }
            }
            if (measure) { drawEnd = System.nanoTime(); cpuDrawEnd = Debug.threadCpuTimeNanos(); target.metrics?.holderDrawReturned(SystemClock.uptimeMillis()) }
            firstFailureStage = "POST"
            if (first && KeyguardOrbSurfaceWorkerTestHooks.ENABLED) KeyguardOrbSurfaceWorkerTestHooks.beforeFirstPost?.invoke(target)
            val submitted = canvas
            canvas = null
            if (measure) target.metrics?.holderPostEntered(SystemClock.uptimeMillis())
            if (outputSurface != null) outputSurface.unlockCanvasAndPost(submitted)
            else checkNotNull(target.holder).unlockCanvasAndPost(submitted)
            posted = true
            if (firstTiming != null) firstTiming.postReturnNs = System.nanoTime()
            if (KeyguardOrbSurfaceWorkerTestHooks.ENABLED) {
                KeyguardOrbSurfaceWorkerTestHooks.postedMaterialTime?.let { observer ->
                    val actual = if (first && !firstDirect) checkNotNull(currentPoster).phase else
                        KeyguardMaterialTime(currentFrameTime.elapsedSeconds, currentFrameTime.phase,
                            currentFrameTime.backgroundPhase, currentFrameTime.interiorPhase)
                    runCatching { observer(target, actual, SystemClock.uptimeMillis()) }
                }
                runCatching { KeyguardOrbSurfaceWorkerTestHooks.afterCanvasPost?.invoke(target) }
            }
            if (measure) { postEnd = System.nanoTime(); cpuPostEnd = Debug.threadCpuTimeNanos(); target.metrics?.holderPostReturned(SystemClock.uptimeMillis()) }
        } catch (error: Throwable) {
            if (first) finishFirstObservation(target, "$firstFailureStage:${error.javaClass.simpleName}")
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
        if (!posted || currentTarget !== target || target.revoked ||
            (selection != null && (authorizedTarget.get() !== target ||
                target.firstDirectAuthorization.get() !== selection.ticket ||
                selection.request != preparationGeneration.get()))) {
            if (first) finishFirstObservation(target, "STALE_AFTER_POST")
            return
        }
        if (!firstPosted) {
            firstPosted = true
            target.firstPostedVisualKey = scene.profile.visualKey
            target.firstPostedWasFull = scene.full
            val phase = selection?.phase ?: checkNotNull(currentPoster).phase
            currentScene = scene.anchoredAt(phase, System.nanoTime())
            lastPostedElapsed = phase.elapsedSeconds
            lastPostedPhase = phase.phase
            lastPostedBackground = phase.backgroundPhase
            lastPostedInterior = phase.interiorPhase
            lastPostedVisual = scene.profile.visualKey
            lastPostedFull = scene.full
            firstSelection = null
            runCatching { onFirstPosted(target, SystemClock.uptimeMillis()) }
            finishFirstObservation(target, null)
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

    private fun finishFirstObservation(target: KeyguardOrbSurfaceTarget, failure: String?) {
        val item = firstMeasurement?.takeIf { it.target === target } ?: return
        firstMeasurement = null
        runCatching {
            if (isCaptureActive()) {
                val snapshot = KeyguardR20FirstFrameObservation(item.ticket.requestId, item.method, item.entryNs,
                    item.painterStartNs, item.painterEndNs, item.configureEndNs, item.lockBeginNs, item.lockReturnNs,
                    item.drawEndNs, item.postReturnNs, failure, target.r27WarmStatus, target.r27WarmSelector,
                    target.r27LoadNs, target.r27WorkerQueueNs, target.r27ConstructorNs, target.r27Overlap)
                target.reporter?.invoke(KeyguardOrbSurfaceObservation(target.attachment, target.generation,
                    "R20_FIRST_FRAME", SystemClock.uptimeMillis(), "first", target.full, target.metrics, snapshot))
            }
        }
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
