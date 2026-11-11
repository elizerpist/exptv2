package com.fluvi.app.lockscreen.material

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.RuntimeShader
import android.graphics.Shader
import android.os.Build
import android.os.SystemClock
import android.os.Debug
import com.fluvi.app.lockscreen.KeyguardMainWorkEvidence
import com.fluvi.app.lockscreen.keyguardThreadCpuDelta
import android.util.AttributeSet
import android.view.Choreographer
import android.view.View
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

/** Primitive SAM avoids boxing three timestamp Longs on every callback. */
internal fun interface KeyguardFrameCallbackObservation {
    fun observed(frameNs: Long, enteredNs: Long, exitedNs: Long)
}

/** The one card-owned, display-synchronised clock. It never performs IPC,
 * persistence, queries or WindowManager operations. */
internal class KeyguardMaterialClock(
    private val evidenceEnabled: () -> Boolean = { false },
    private val onCallbackObserved: KeyguardFrameCallbackObservation = KeyguardFrameCallbackObservation { _, _, _ -> },
    private val onFrame: (Long) -> Unit,
) : Choreographer.FrameCallback {
    private var running = false
    val isRunning: Boolean get() = running
    private var callbackPending = false
    private var lastFrameNanos = 0L
    var startCount = 0
        private set
    var stopCount = 0
        private set
    /** Number of display callbacks, deliberately not a Canvas-draw metric. */
    var callbackCount = 0
        private set
    var largeGapCount = 0
        private set
    private val intervalsMs = ArrayDeque<Long>(120)

    fun start() {
        if (running) return
        running = true
        startCount += 1
        schedule()
    }

    fun stop() {
        if (!running && !callbackPending) return
        running = false
        if (callbackPending) Choreographer.getInstance().removeFrameCallback(this)
        callbackPending = false
        lastFrameNanos = 0L
        stopCount += 1
    }

    override fun doFrame(frameTimeNanos: Long) {
        val observe = evidenceEnabled()
        val enteredNs = if (observe) System.nanoTime() else 0L
        callbackPending = false
        if (!running) return
        if (lastFrameNanos != 0L) {
            val interval = (frameTimeNanos - lastFrameNanos) / 1_000_000L
            if (interval > 0) {
                if (intervalsMs.size == 120) intervalsMs.removeFirst()
                intervalsMs.addLast(interval)
                if (interval > 34L) largeGapCount += 1
            }
        }
        lastFrameNanos = frameTimeNanos
        callbackCount += 1
        onFrame(frameTimeNanos)
        schedule()
        if (observe) onCallbackObserved.observed(frameTimeNanos, enteredNs, System.nanoTime())
    }

    fun framePercentile(percentile: Double): Long {
        if (intervalsMs.isEmpty()) return 0L
        val sorted = intervalsMs.sorted()
        return sorted[((sorted.size - 1) * percentile).toInt().coerceIn(0, sorted.lastIndex)]
    }

    private fun schedule() {
        if (!running || callbackPending) return
        callbackPending = true
        Choreographer.getInstance().postFrameCallback(this)
    }
}

/** `System.nanoTime()` and Choreographer frameTimeNanos share Android's
 * monotonic timebase.  Keeping the source injectable makes pause/resume and
 * handoff regressions deterministic without introducing wall-clock time. */
internal fun interface KeyguardAnimationTimeSource {
    fun nowNanos(): Long
}

internal val SystemKeyguardAnimationTimeSource = KeyguardAnimationTimeSource(System::nanoTime)

/**
 * The retained Canvas renderer normally derives its material time from its
 * immutable scene. Instrumentation can supply a constructor-captured source
 * for matched phase controls; production keeps the scene monotonic clock.
 */
internal fun interface KeyguardMaterialTimeSource {
    fun timeAt(scene: KeyguardMaterialScene, frameTimeNanos: Long): KeyguardMaterialTime
}

internal object SystemKeyguardMaterialTimeSource : KeyguardMaterialTimeSource {
    override fun timeAt(scene: KeyguardMaterialScene, frameTimeNanos: Long): KeyguardMaterialTime =
        scene.timeAt(frameTimeNanos)
}

/** Immutable clock anchor held by a view during a semantic scene. */
internal data class KeyguardMaterialScene(
    val profile: KeyguardMaterialProfile,
    val full: Boolean,
    val appliedAtNanos: Long,
) {
    val visualKey = "${profile.visualKey}|$full"
    fun timeAt(frameNanos: Long): KeyguardMaterialTime {
        // Keep the subtraction and division in Long/Double.  Converting the
        // absolute monotonic timestamp to Float first freezes animation after
        // sufficiently long uptime.
        val delta = (max(0L, frameNanos - appliedAtNanos).toDouble() / 1_000_000_000.0)
        return KeyguardMaterialTime(
            elapsedSeconds = (profile.elapsedSeconds.toDouble() + delta).toFloat(),
            phase = (profile.phase.toDouble() + delta * profile.phaseSpeed).toFloat(),
            backgroundPhase = (profile.background.phase.toDouble() + delta * profile.background.phaseSpeed).toFloat(),
            interiorPhase = (profile.interior.phase.toDouble() + delta * profile.interior.phaseSpeed).toFloat(),
        )
    }

    fun anchoredAt(time: KeyguardMaterialTime, nowNanos: Long) = KeyguardMaterialScene(
        profile = profile.copy(
            phase = time.phase,
            elapsedSeconds = time.elapsedSeconds,
            background = profile.background.copy(phase = time.backgroundPhase),
            interior = profile.interior.copy(phase = time.interiorPhase),
        ),
        full = full,
        appliedAtNanos = nowNanos,
    )
}

internal data class KeyguardMaterialRendererState(
    val viewAttached: Boolean,
    val positiveSize: Boolean,
    val lastCanvasHardwareAccelerated: Boolean?,
    val rendererReady: Boolean,
)

internal data class KeyguardMaterialTime(
    val elapsedSeconds: Float,
    val phase: Float,
    val backgroundPhase: Float,
    val interiorPhase: Float,
)

/**
 * Decorative retained view used only inside the already attached keyguard
 * root. It is intentionally non-interactive and accessibility silent.
 * API 33+ evaluates the canonical field through a retained RuntimeShader;
 * older systems and compilation failures draw the same static palette.
 */
internal class KeyguardHeaderMaterialView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    private val animationTime: KeyguardAnimationTimeSource = SystemKeyguardAnimationTimeSource,
    private val materialTimeSource: KeyguardMaterialTimeSource = SystemKeyguardMaterialTimeSource,
) : View(context, attrs) {
    enum class Shape { ORB, CARD_BACKGROUND }

    /** Preparation is deliberately distinct from attachment and first Canvas
     * use. A retained detached view can own one compiled candidate without
     * gaining visibility or scheduling an animation callback. */
    enum class ProgramPreparationResult { COMPILED, REUSED, STALE, NOT_APPLICABLE, FAILED }

    private data class PreparedProgram(
        val programKey: String,
        val effectId: String,
        val usesPortal: Boolean,
        val shader: KeyguardHeaderShader,
        val metadata: KeyguardHeaderShader.Metadata,
    )

    var shape: Shape = Shape.ORB
    private var current: KeyguardMaterialScene? = null
    private var previous: KeyguardMaterialScene? = null
    private var transitionStartedNanos = 0L
    private var frameNanos = animationTime.nowNanos()
    private var pausedTime: KeyguardMaterialTime? = null
    private var fallbackBitmap: Bitmap? = null
    private var materialEnabled = false
    private var shaderCurrent: KeyguardHeaderShader? = null
    private var shaderPrevious: KeyguardHeaderShader? = null
    private var shaderFailure: KeyguardMaterialRendererFailure? = null
    private var attemptedProgramKey: String? = null
    private var failedProgramKey: String? = null
    private var preparedProgram: PreparedProgram? = null
    /** Metadata belongs to the prepared immutable artifact, not to onDraw. */
    private var preparedMetadata: KeyguardHeaderShader.Metadata? = null
    private var lastCanvasHardwareAccelerated: Boolean? = null
    private var lastTime: KeyguardMaterialTime? = null
    private var onDrawCount = 0
    private var shaderDrawCount = 0
    private val attachmentCadence = KeyguardDrawCadence()
    private val drawGaps = KeyguardDrawGapEvidence()
    private var evidenceAttachment = 0L
    private var evidenceAttachmentActive = false
    var drawEvidenceEnabled: () -> Boolean = { false }
    var drawEvidenceOwner: () -> Any? = { null }
    private var lastEvidenceToken: Any? = null
    var mainWorkEvidence: KeyguardMainWorkEvidence? = null
    private var measuringShader = false
    private var configureNs = 0L
    private var submitNs = 0L
    private var attachmentShaderCallsStart = 0
    private var attachmentPhaseAdvancesStart = 0
    private var fallbackDrawCount = 0
    private var phaseAdvanceCount = 0
    private var shaderCompileAttempts = 0
    private var shaderCompileSuccesses = 0
    private var shaderCompileFailures = 0
    private var transitionCompletedCount = 0
    /** This is called only on main-thread view lifecycle/Canvas state changes. */
    var onRendererStateChanged: ((KeyguardMaterialRendererState) -> Unit)? = null
    /** One timestamp per physical attach is enough for wake diagnostics; this
     * is not a per-frame observation hook. */
    var onFirstShaderDraw: ((Long) -> Unit)? = null
    /** Main-thread-only observational hook. Promotion changes no visibility
     * state; the controller uses it solely for truthful diagnostics. */
    var onPreparedProgramPromoted: ((String) -> Unit)? = null
    private var firstShaderDrawForAttach = true
    /** The first attached traversal deliberately uses only this inexpensive,
     * palette-correct route.  The controller opens the gate only after the
     * matching bootstrap frame commit and worker-owned GPU preparation. */
    private var bootstrapActive = false
    private var firstBootstrapDrawForAttach = true
    private var bootstrapPaintKey: String? = null
    private var bootstrapPaintColor = Color.rgb(101, 116, 137)
    private var bootstrapPaintAlpha = 255
    private var bootstrapDrawCount = 0
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
    private val fallbackPaint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
    private val bootstrapPaint = Paint(Paint.ANTI_ALIAS_FLAG)

    init {
        isClickable = false
        isFocusable = false
        importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_NO
        contentDescription = null
        setWillNotDraw(false)
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        firstShaderDrawForAttach = true
        firstBootstrapDrawForAttach = true
        beginAttachmentDrawEvidence()
        notifyRendererState()
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        endAttachmentDrawEvidence()
        // `isAttachedToWindow` flips during the framework call.  Publishing
        // before it would let the controller retain a frame callback for a
        // root which has already been removed from the accessibility window.
        notifyRendererState()
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        rebuildBootstrapPaint()
        notifyRendererState()
    }

    fun setStaticBitmap(value: Bitmap?) {
        if (fallbackBitmap === value) return
        fallbackBitmap = value
        if (!materialEnabled) invalidate()
    }

    /** Main-thread gate for cold presentation. This does not alter the scene
     * or its monotonic clock anchor; it only chooses the first draw route. */
    fun setBootstrapActive(value: Boolean) {
        if (bootstrapActive == value) return
        bootstrapActive = value
        if (value) firstBootstrapDrawForAttach = true
        invalidate()
    }

    fun isBootstrapActive(): Boolean = bootstrapActive

    /** Functional acknowledgement for every non-empty bootstrap draw. It is
     * intentionally separate from the diagnostic first-draw callback: an
     * observer armed during attachment must still be able to acknowledge a
     * later bootstrap traversal if the diagnostic first draw came earlier. */
    var onBootstrapGeometryDrawn: (() -> Unit)? = null

    /** Called from Canvas.onDraw only after the cheap bootstrap geometry was
     * emitted. The owner posts all observation work after draw dispatch. */
    var onFirstBootstrapDraw: ((Long) -> Unit)? = null

    fun setScene(scene: KeyguardMaterialScene?, enabled: Boolean) {
        materialEnabled = enabled && scene != null
        if (scene == null) {
            current = null
            previous = null
            pausedTime = null
            invalidate()
            return
        }
        var next = scene
        val currentScene = current
        if (currentScene?.visualKey == next.visualKey) {
            // Keep the original monotonic anchor. Financial text updates and
            // the local main/event toggle must not restart Header motion.
            invalidate()
            return
        }
        // A speed/palette/settings publication for the same effect must not
        // restart at Flutter's old handoff phase. Preserve the material's
        // local monotonic position, then use the new profile from that point.
        // A privacy or effect change intentionally takes the incoming anchor.
        if (currentScene != null && currentScene.full == next.full &&
            currentScene.profile.effectId == next.profile.effectId
        ) {
            val now = animationTime.nowNanos()
            val at = pausedTime ?: currentScene.timeAt(now)
            next = KeyguardMaterialScene(
                profile = next.profile.copy(
                    phase = at.phase,
                    elapsedSeconds = at.elapsedSeconds,
                    background = next.profile.background.copy(phase = at.backgroundPhase),
                    interior = next.profile.interior.copy(phase = at.interiorPhase),
                ),
                full = next.full,
                appliedAtNanos = now,
            )
        }
        // Privacy redaction never crossfades financial colour into the
        // neutral scene. A semantic effect/palette change keeps the old field
        // as an opaque base and lays the new field over it.
        if (currentScene != null && currentScene.full == next.full) {
            previous = currentScene
            transitionStartedNanos = animationTime.nowNanos()
        } else {
            previous = null
        }
        // API 35 rejects the canonical all-effects program as too large. The
        // build therefore emits one compile-time-specialized program per
        // canonical effect. Retain the old program only as the transition
        // base; the new effect gets its own program on the next real draw.
        // This is strictly a retained View concern, never a WindowManager
        // operation, so rapid profile changes cannot recreate the overlay.
        val programChanged = currentScene?.profile?.effectId != next.profile.effectId ||
            currentScene?.profile?.usesPortal != next.profile.usesPortal
        if (programChanged) {
            // A null -> first scene used to clear the program which had just
            // been prepared by the detached retained root. Promote the exact
            // prepared candidate instead; only a real prior scene becomes a
            // transition base.
            if (currentScene != null) shaderPrevious = shaderCurrent
            shaderCurrent = null
            attemptedProgramKey = null
            shaderFailure = null
            failedProgramKey = null
            promotePreparedProgram(next.profile)
        }
        current = next
        rebuildBootstrapPaint()
        // Source and RuntimeShader preparation are requested by the retained
        // controller before attachment. A hardware Canvas is still required
        // before this view reports renderer readiness or FIRST_SHADER_DRAW.
        invalidate()
    }

    /**
     * Called on this View's main-thread owner after the artifact lane loaded
     * immutable source/metadata. RuntimeShader construction is intentionally
     * outside onDraw, so a first visible frame can never open or parse assets.
     */
    fun installPreparedShader(artifact: KeyguardShaderArtifact): ProgramPreparationResult {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return ProgramPreparationResult.NOT_APPLICABLE
        val profile = current?.profile
        // A hidden retained root may still remember its old scene. Its next
        // selected program is a valid detached candidate, not a stale result.
        // Conversely, an attached mismatched scene must never be replaced by
        // an asynchronous completion from another selection.
        if (profile != null && !matches(profile, artifact) && isAttachedToWindow) {
            return ProgramPreparationResult.STALE
        }
        if (shaderCurrent != null && attemptedProgramKey == artifact.programKey) return ProgramPreparationResult.REUSED
        if (preparedProgram?.programKey == artifact.programKey) return ProgramPreparationResult.REUSED
        if (shaderFailure != null && failedProgramKey == artifact.programKey) return ProgramPreparationResult.FAILED
        preparedMetadata = artifact.metadata
        shaderCompileAttempts += 1
        return runCatching { KeyguardHeaderShader(artifact) }
            .fold(
                onSuccess = { shader ->
                    val compiled = PreparedProgram(
                        programKey = artifact.programKey,
                        effectId = artifact.effectId,
                        usesPortal = artifact.usesPortal,
                        shader = shader,
                        metadata = artifact.metadata,
                    )
                    if (profile != null && matches(profile, artifact)) {
                        shaderCurrent = shader
                        attemptedProgramKey = artifact.programKey
                    } else {
                        // Exactly one detached candidate per View. It is
                        // promoted only when the first scene asks for this
                        // specialized source program.
                        preparedProgram = compiled
                    }
                    shaderCompileSuccesses += 1
                    shaderFailure = null
                    failedProgramKey = null
                    notifyRendererState()
                    invalidate()
                    ProgramPreparationResult.COMPILED
                },
                onFailure = { error ->
                    shaderCompileFailures += 1
                    shaderFailure = KeyguardMaterialRendererFailure.compile(error, artifact.metadata)
                    failedProgramKey = artifact.programKey
                    notifyRendererState()
                    invalidate()
                    ProgramPreparationResult.FAILED
                },
            )
    }

    private fun promotePreparedProgram(profile: KeyguardMaterialProfile): Boolean {
        val prepared = preparedProgram ?: return false
        if (prepared.effectId != profile.effectId || prepared.usesPortal != profile.usesPortal) return false
        preparedProgram = null
        shaderCurrent = prepared.shader
        attemptedProgramKey = prepared.programKey
        preparedMetadata = prepared.metadata
        shaderFailure = null
        failedProgramKey = null
        onPreparedProgramPromoted?.invoke(prepared.programKey)
        notifyRendererState()
        return true
    }

    private fun matches(profile: KeyguardMaterialProfile, artifact: KeyguardShaderArtifact): Boolean =
        profile.effectId == artifact.effectId && profile.usesPortal == artifact.usesPortal

    fun frame(frameTimeNanos: Long) {
        frameNanos = frameTimeNanos
        if (materialEnabled && visibility == VISIBLE && width > 0 && height > 0) invalidate()
    }

    /** Seeds the first live traversal after bootstrap without starting a
     * second clock or changing the scene anchor. */
    fun prepareFirstLiveFrame(frameTimeNanos: Long) {
        frameNanos = frameTimeNanos
    }

    fun pause() {
        drawGaps.samplingOff() // Intentional stopped time is not a live traversal gap.
        if (pausedTime != null) return
        val now = animationTime.nowNanos()
        pausedTime = current?.timeAt(now)
    }

    fun resume() {
        val paused = pausedTime ?: return
        val scene = current ?: return
        current = scene.anchoredAt(paused, animationTime.nowNanos())
        previous = null
        pausedTime = null
        invalidate()
    }

    fun rendererFailure(): String? = shaderFailure?.summary
    fun rendererFailureStage(): String? = shaderFailure?.stage
    fun rendererFailureMessage(): String? = shaderFailure?.message
    fun shaderCreationCount(): Int = (shaderCurrent?.creationCount ?: 0) +
        (shaderPrevious?.creationCount ?: 0) + (preparedProgram?.shader?.creationCount ?: 0)
    fun lastCanvasHardwareAcceleratedForDiagnostics(): Boolean = lastCanvasHardwareAccelerated ?: false
    fun isRendererReady(): Boolean = isAttachedToWindow && width > 0 && height > 0 &&
        lastCanvasHardwareAccelerated == true && shaderCurrent != null && shaderFailure == null
    fun canAnimateMaterial(): Boolean = isRendererReady() && !bootstrapActive

    fun attachmentDrawCadence(): KeyguardDrawCadence.Snapshot = attachmentCadence.snapshot()
    fun attachmentDrawGaps(): KeyguardDrawGapEvidence.Snapshot = drawGaps.snapshot()
    fun beginAttachmentDrawEvidence(attachment: Long = evidenceAttachment) {
        evidenceAttachment = attachment
        evidenceAttachmentActive = true
        attachmentCadence.reset()
        drawGaps.begin(attachment)
        lastEvidenceToken = null
        attachmentShaderCallsStart = shaderDrawCount
        attachmentPhaseAdvancesStart = phaseAdvanceCount
    }
    fun endAttachmentDrawEvidence() {
        evidenceAttachmentActive = false
        lastEvidenceToken = null
        drawGaps.end()
    }
    fun recordClockCallback(frameNs: Long, enteredNs: Long, exitedNs: Long) {
        if (!evidenceAttachmentActive) return
        val probeStart = System.nanoTime()
        prepareEvidenceSampling()
        drawGaps.callback(evidenceAttachment, frameNs, enteredNs, exitedNs)
        drawGaps.addObserverCost(System.nanoTime() - probeStart)
    }
    private fun prepareEvidenceSampling() {
        val token = drawEvidenceOwner() ?: this // stable owner for controlled instrumentation
        if (token !== lastEvidenceToken) {
            drawGaps.begin(evidenceAttachment)
            lastEvidenceToken = token
        }
    }
    fun attachmentShaderCalls(): Int = shaderDrawCount - attachmentShaderCallsStart
    fun attachmentPhaseAdvances(): Int = phaseAdvanceCount - attachmentPhaseAdvancesStart

    fun diagnostics(): KeyguardHeaderMaterialViewDiagnostics = KeyguardHeaderMaterialViewDiagnostics(
        onDrawCount = onDrawCount,
        shaderDrawCount = shaderDrawCount,
        fallbackDrawCount = fallbackDrawCount,
        phaseAdvanceCount = phaseAdvanceCount,
        shaderCompileAttempts = shaderCompileAttempts,
        shaderCompileSuccesses = shaderCompileSuccesses,
        shaderCompileFailures = shaderCompileFailures,
        assetOpenCountDuringDraw = 0,
        metadataParseCountDuringDraw = 0,
        shaderCompileCountDuringDraw = 0,
        bootstrapDrawCount = bootstrapDrawCount,
        transitionCompletedCount = transitionCompletedCount,
        lastCanvasHardwareAccelerated = lastCanvasHardwareAccelerated,
        failureStage = shaderFailure?.stage,
        failureClass = shaderFailure?.exceptionClass,
        failureMessage = shaderFailure?.message,
        generatedAgslHash = preparedMetadata?.generatedAgslHash,
        adapterVersion = preparedMetadata?.adapterVersion,
    )

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        onDrawCount += 1
        if (lastCanvasHardwareAccelerated != canvas.isHardwareAccelerated) {
            lastCanvasHardwareAccelerated = canvas.isHardwareAccelerated
            notifyRendererState()
        }
        val scene = current
        if (!materialEnabled || scene == null || width <= 0 || height <= 0) {
            drawFallback(canvas, scene)
            return
        }
        if (bootstrapActive) {
            drawBootstrap(canvas, scene)
            return
        }
        // The Dashboard's static Header is not the shader's static branch.
        // Preserve its audited 112° CSS-gradient route whenever neither
        // Portal layer is active, exactly as DashboardHeaderStaticColorRenderer
        // does on Flutter.
        if (scene.profile.effectId == "staticEffect" &&
            !scene.profile.background.enabled && !scene.profile.interior.enabled
        ) {
            drawStaticHeaderGradient(canvas, scene.profile)
            return
        }
        val currentShader = shaderCurrent
        if (currentShader == null || !canvas.isHardwareAccelerated) {
            drawFallback(canvas, scene)
            return
        }
        val old = previous
        val shaderCallsBeforeTraversal = shaderDrawCount
        measuringShader = evidenceAttachmentActive && drawEvidenceEnabled()
        if (measuringShader) prepareEvidenceSampling()
        val traversalStartNs = if (measuringShader) System.nanoTime() else 0L
        val cpuStartNs = if (measuringShader) Debug.threadCpuTimeNanos() else 0L
        configureNs = 0; submitNs = 0
        val progress = if (old == null) 1f else ((frameNanos - transitionStartedNanos) / 180_000_000f).coerceIn(0f, 1f)
        if (old != null && progress < 1f) {
            drawShader(canvas, shaderPrevious ?: currentShader, old, 1f)
            drawShader(canvas, currentShader, scene, progress)
        } else {
            if (old != null) transitionCompletedCount += 1
            previous = null
            drawShader(canvas, currentShader, scene, 1f)
        }
        if (shaderDrawCount > shaderCallsBeforeTraversal) {
            val traversalEndNs = if (measuringShader) System.nanoTime() else 0L
            val cpuNs = if (measuringShader) keyguardThreadCpuDelta(cpuStartNs, Debug.threadCpuTimeNanos()) else 0L
            // A transition can issue two shader calls in one traversal. Count
            // that traversal once, only after actual shader geometry was sent.
            attachmentCadence.drawn(SystemClock.uptimeMillis(), lastTime?.phase ?: Float.NaN)
            if (measuringShader) {
                val probeStart = System.nanoTime()
                drawGaps.drawn(evidenceAttachment, traversalStartNs, traversalEndNs, cpuNs,
                    configureNs, submitNs, mainWorkEvidence, attemptedProgramKey, width, height)
                drawGaps.addObserverCost(System.nanoTime() - probeStart)
            } else {
                drawGaps.samplingOff()
                lastEvidenceToken = null
            }
        }
        measuringShader = false
    }

    private fun drawShader(canvas: Canvas, shader: KeyguardHeaderShader, scene: KeyguardMaterialScene, alpha: Float) {
        val time = materialTimeSource.timeAt(scene, frameNanos)
        val configureStart = if (measuringShader) System.nanoTime() else 0L
        try {
            shader.configure(scene.profile, width, height, time)
        } catch (error: Throwable) {
            shaderFailure = KeyguardMaterialRendererFailure.uniform(error)
            notifyRendererState()
            drawFallback(canvas, scene)
            return
        }
        if (measuringShader) configureNs += System.nanoTime() - configureStart
        paint.shader = shader.runtimeShader
        paint.alpha = (alpha * 255).toInt().coerceIn(0, 255)
        val submitStart = if (measuringShader) System.nanoTime() else 0L
        when (shape) {
            Shape.ORB -> {
                val radius = min(width, height) / 2f
                canvas.drawCircle(width / 2f, height / 2f, radius, paint)
            }
            Shape.CARD_BACKGROUND -> canvas.drawRoundRect(0f, 0f, width.toFloat(), height.toFloat(), dp(22f), dp(22f), paint)
        }
        if (measuringShader) submitNs += System.nanoTime() - submitStart
        paint.shader = null
        paint.alpha = 255
        shaderDrawCount += 1
        if (firstShaderDrawForAttach) {
            firstShaderDrawForAttach = false
            // This callback is only a timestamp capture. Its owner posts any
            // diagnostics so no persistence, lifecycle, or WindowManager work
            // is performed from this Canvas draw stack.
            onFirstShaderDraw?.invoke(SystemClock.uptimeMillis())
        }
        val before = lastTime
        if (before != null && (before.phase != time.phase || before.elapsedSeconds != time.elapsedSeconds)) {
            phaseAdvanceCount += 1
        }
        lastTime = time
    }

    private fun drawFallback(canvas: Canvas, scene: KeyguardMaterialScene?) {
        drawGaps.samplingOff()
        fallbackDrawCount += 1
        val profile = scene?.profile
        val bitmap = fallbackBitmap
        if (shape == Shape.ORB && bitmap != null && !materialEnabled) {
            val source = android.graphics.Rect(0, 0, bitmap.width, bitmap.height)
            val size = min(width, height)
            val left = (width - size) / 2
            val top = (height - size) / 2
            canvas.drawCircle(width / 2f, height / 2f, size / 2f, fallbackPaint)
            canvas.save()
            canvas.clipPath(android.graphics.Path().apply { addCircle(width / 2f, height / 2f, size / 2f, android.graphics.Path.Direction.CW) })
            canvas.drawBitmap(bitmap, source, android.graphics.Rect(left, top, left + size, top + size), fallbackPaint)
            canvas.restore()
            return
        }
        val colors = profile?.colors ?: intArrayOf(0xff657489.toInt(), 0xff8592a4.toInt(), 0xff657489.toInt())
        val stops = profile?.stops ?: floatArrayOf(0f, .5f, 1f)
        val safeColors = colors.take(min(colors.size, stops.size)).toIntArray().takeIf { it.size >= 2 }
            ?: intArrayOf(0xff657489.toInt(), 0xff8592a4.toInt())
        val safeStops = stops.take(safeColors.size).toFloatArray()
        paint.shader = LinearGradient(0f, height.toFloat(), width.toFloat(), 0f, safeColors, safeStops, Shader.TileMode.CLAMP)
        paint.alpha = if (shape == Shape.CARD_BACKGROUND) 52 else 255
        if (shape == Shape.ORB) canvas.drawCircle(width / 2f, height / 2f, min(width, height) / 2f, paint)
        else canvas.drawRoundRect(0f, 0f, width.toFloat(), height.toFloat(), dp(22f), dp(22f), paint)
        paint.shader = null
        paint.alpha = 255
    }

    /** The bootstrap is intentionally independent of RuntimeShader readiness.
     * Its gradient is rebuilt when semantic input or size changes, never from
     * the draw loop. */
    private fun drawBootstrap(canvas: Canvas, scene: KeyguardMaterialScene) {
        drawGaps.samplingOff()
        bootstrapDrawCount += 1
        val activePaint = bootstrapPaint
        // `setScene` and `onSizeChanged` build the gradient.  A defensive
        // missing key uses the preallocated Paint's solid color rather than
        // allocating a Shader from Canvas.onDraw.
        if (bootstrapPaintKey == null) activePaint.shader = null
        activePaint.alpha = if (shape == Shape.CARD_BACKGROUND) {
            (bootstrapPaintAlpha * 52 / 255).coerceIn(0, 255)
        } else {
            bootstrapPaintAlpha
        }
        when (shape) {
            Shape.ORB -> canvas.drawCircle(width / 2f, height / 2f, min(width, height) / 2f, activePaint)
            Shape.CARD_BACKGROUND -> canvas.drawRoundRect(
                0f,
                0f,
                width.toFloat(),
                height.toFloat(),
                dp(22f),
                dp(22f),
                activePaint,
            )
        }
        activePaint.alpha = 255
        onBootstrapGeometryDrawn?.invoke()
        if (firstBootstrapDrawForAttach) {
            firstBootstrapDrawForAttach = false
            onFirstBootstrapDraw?.invoke(SystemClock.uptimeMillis())
        }
    }

    private fun rebuildBootstrapPaint() {
        val profile = current?.profile
        val colors = profile?.colors ?: intArrayOf(0xff657489.toInt(), 0xff8592a4.toInt(), 0xff657489.toInt())
        val stops = profile?.stops ?: floatArrayOf(0f, .5f, 1f)
        val safeColors = colors.take(min(colors.size, stops.size)).toIntArray().takeIf { it.size >= 2 }
            ?: intArrayOf(0xff657489.toInt(), 0xff8592a4.toInt())
        val safeStops = stops.take(safeColors.size).toFloatArray()
        bootstrapPaintKey = "${profile?.visualKey ?: "default"}|${width}x${height}|$shape"
        bootstrapPaintColor = safeColors.first()
        bootstrapPaintAlpha = ((profile?.opacity ?: 1f) * 255).toInt().coerceIn(0, 255)
        bootstrapPaint.shader = if (width > 0 && height > 0) {
            LinearGradient(
                0f,
                height.toFloat(),
                width.toFloat(),
                0f,
                safeColors,
                safeStops,
                Shader.TileMode.CLAMP,
            )
        } else {
            null
        }
        bootstrapPaint.color = bootstrapPaintColor
    }

    private fun drawStaticHeaderGradient(canvas: Canvas, profile: KeyguardMaterialProfile) {
        drawGaps.samplingOff()
        val count = min(profile.colors.size, profile.stops.size)
        if (count < 2) {
            paint.color = profile.colors.firstOrNull() ?: Color.rgb(101, 116, 137)
            paint.alpha = (profile.opacity * 255).toInt().coerceIn(0, 255)
            if (shape == Shape.ORB) {
                canvas.drawCircle(width / 2f, height / 2f, min(width, height) / 2f, paint)
            } else {
                canvas.drawRoundRect(0f, 0f, width.toFloat(), height.toFloat(), dp(22f), dp(22f), paint)
            }
            paint.alpha = 255
            return
        }
        val radians = 112f * (Math.PI.toFloat() / 180f)
        val directionX = sin(radians)
        val directionY = -cos(radians)
        val lineLength = width * kotlin.math.abs(directionX) + height * kotlin.math.abs(directionY)
        val half = lineLength / 2f
        val centerX = width / 2f
        val centerY = height / 2f
        val colors = profile.colors.copyOf(count)
        val stops = profile.stops.copyOf(count)
        paint.shader = LinearGradient(
            centerX - directionX * half,
            centerY - directionY * half,
            centerX + directionX * half,
            centerY + directionY * half,
            colors,
            stops,
            Shader.TileMode.CLAMP,
        )
        paint.alpha = (profile.opacity * 255).toInt().coerceIn(0, 255)
        if (shape == Shape.ORB) {
            canvas.drawCircle(width / 2f, height / 2f, min(width, height) / 2f, paint)
        } else {
            canvas.drawRoundRect(0f, 0f, width.toFloat(), height.toFloat(), dp(22f), dp(22f), paint)
        }
        paint.shader = null
        paint.alpha = 255
    }

    private fun dp(value: Float): Float = value * resources.displayMetrics.density

    private fun notifyRendererState() {
        onRendererStateChanged?.invoke(
            KeyguardMaterialRendererState(
                viewAttached = isAttachedToWindow,
                positiveSize = width > 0 && height > 0,
                lastCanvasHardwareAccelerated = lastCanvasHardwareAccelerated,
                rendererReady = isRendererReady(),
            ),
        )
    }
}

internal data class KeyguardHeaderMaterialViewDiagnostics(
    val onDrawCount: Int,
    val shaderDrawCount: Int,
    val fallbackDrawCount: Int,
    val phaseAdvanceCount: Int,
    val shaderCompileAttempts: Int,
    val shaderCompileSuccesses: Int,
    val shaderCompileFailures: Int,
    val assetOpenCountDuringDraw: Int,
    val metadataParseCountDuringDraw: Int,
    val shaderCompileCountDuringDraw: Int,
    val bootstrapDrawCount: Int,
    val transitionCompletedCount: Int,
    val lastCanvasHardwareAccelerated: Boolean?,
    val failureStage: String?,
    val failureClass: String?,
    val failureMessage: String?,
    val generatedAgslHash: String?,
    val adapterVersion: String?,
)

private data class KeyguardMaterialRendererFailure(
    val stage: String,
    val exceptionClass: String,
    val message: String?,
    val sourceShaderHash: String? = null,
    val generatedAgslHash: String? = null,
    val adapterVersion: String? = null,
) {
    val summary: String get() = listOfNotNull(stage, exceptionClass, message).joinToString(":")

    companion object {
        private fun bounded(error: Throwable): String? = error.message
            ?.replace(Regex("[\\r\\n\\t]+"), " ")
            ?.take(4096)

        fun compile(error: Throwable, metadata: KeyguardHeaderShader.Metadata) = KeyguardMaterialRendererFailure(
            stage = "COMPILE",
            exceptionClass = error.javaClass.simpleName,
            message = bounded(error),
            sourceShaderHash = metadata.sourceShaderHash,
            generatedAgslHash = metadata.generatedAgslHash,
            adapterVersion = metadata.adapterVersion,
        )

        fun uniform(error: Throwable) = KeyguardMaterialRendererFailure(
            stage = "UNIFORM_BIND",
            exceptionClass = error.javaClass.simpleName,
            message = bounded(error),
        )
    }
}

/** Writes the v6 Header uniform ABI into one retained RuntimeShader. */
internal class KeyguardHeaderShader(
    private val artifact: KeyguardShaderArtifact,
) {
    data class Metadata(
        val sourceShaderHash: String?,
        val generatedAgslHash: String?,
        val adapterVersion: String?,
    )

    companion object {
        fun metadata(context: Context, effectId: String?, usesPortal: Boolean?): Metadata = runCatching {
            val safeEffectId = effectId?.takeIf { it in KeyguardMaterialProfile.effectIds } ?: return@runCatching Metadata(null, null, null)
            val variant = if (usesPortal == true) "portal" else "plain"
            val values = context.assets.open("fluvi_keyguard_header_material_${safeEffectId}_$variant.meta")
                .bufferedReader().useLines { lines ->
                    lines.mapNotNull { line ->
                        line.indexOf('=').takeIf { it > 0 }?.let { index ->
                            line.substring(0, index) to line.substring(index + 1)
                        }
                    }.toMap()
                }
            Metadata(
                sourceShaderHash = values["source-sha256"],
                generatedAgslHash = values["generated-agsl-sha256"],
                adapterVersion = values["adapter-version"],
            )
        }.getOrDefault(Metadata(null, null, null))
    }

    /** Test and one-off tooling entry point. Production rendering receives a
     * prepared artifact from [KeyguardShaderArtifactStore] instead. */
    constructor(context: Context, effectId: String, usesPortal: Boolean) : this(
        AndroidKeyguardShaderArtifactReader.load(context, effectId, usesPortal),
    )

    val metadata: Metadata get() = artifact.metadata
    private val effectId: String get() = artifact.effectId
    private val usesPortal: Boolean get() = artifact.usesPortal

    val runtimeShader: RuntimeShader
    var creationCount = 1
        private set
    private var profileKey: String? = null
    private var sizeKey: Long = Long.MIN_VALUE
    private val deepDrift = KeyguardDeepDriftSkeleton()

    init {
        require(effectId in KeyguardMaterialProfile.effectIds) { "unknown-effect:$effectId" }
        runtimeShader = RuntimeShader(artifact.source)
    }

    fun configure(profile: KeyguardMaterialProfile, width: Int, height: Int, time: KeyguardMaterialTime) {
        val nextSize = (width.toLong() shl 32) or (height.toLong() and 0xffffffffL)
        if (profileKey != profile.visualKey || sizeKey != nextSize) {
            profileKey = profile.visualKey
            sizeKey = nextSize
            writeStatic(profile, width, height)
        }
        runtimeShader.setFloatUniform("uElapsed", time.elapsedSeconds)
        runtimeShader.setFloatUniform("uPhase", time.phase)
        runtimeShader.setFloatUniform("uBackgroundPhase", time.backgroundPhase)
        runtimeShader.setFloatUniform("uInteriorPhase", time.interiorPhase)
        if (profile.effectId == "deepDrift") {
            deepDrift.advance(time.elapsedSeconds, profile.commonSettings)
            for (index in 0 until 15) uniform4("uDeepBlob$index", deepDrift.blobs, index * 4)
            for (index in 0 until 3) uniform4("uDeepLayer$index", deepDrift.layers, index * 4)
        }
    }

    private fun writeStatic(profile: KeyguardMaterialProfile, width: Int, height: Int) {
        uniform2("uSize", profile.referenceWidth, profile.referenceHeight)
        uniform2("uRasterSize", width.toFloat(), height.toFloat())
        runtimeShader.setFloatUniform("uOpacity", profile.opacity)
        runtimeShader.setFloatUniform("uPaletteSplit", profile.paletteSplitPercent / 100f)
        // The generated artifact embeds the effect ID in executable source.
        // On API 35, a retained RuntimeShader uniform guard over a pruned
        // classic branch can freeze the phase path; the source literal lets
        // SkSL eliminate inactive members without freezing the selected one.
        runtimeShader.setFloatUniform("uPulse", 0f)
        runtimeShader.setFloatUniform("uRenderQuality", 1f)
        val fallback = profile.colors.last()
        for (index in 0 until 10) {
            val color = profile.colors.getOrElse(index) { fallback }
            uniform4("uGradient$index", Color.red(color) / 255f, Color.green(color) / 255f, Color.blue(color) / 255f, Color.alpha(color) / 255f)
        }
        // This mirrors DashboardHeaderFragmentUniformLayout exactly: slots
        // 0..9 are stop positions, slot 10 is the live-probe count, and slot
        // 11 remains padding.  Swapping the final two (as the first Android
        // port did) leaves the canonical shader with zero usable probes.
        val stops = FloatArray(12) { index -> if (index < 10) profile.stops.getOrElse(index) { 1f } else 1f }
        stops[10] = min(3, max(2, min(profile.colors.size, profile.stops.size))).toFloat()
        uniform4("uGradientStops0", stops, 0)
        uniform4("uGradientStops1", stops, 4)
        uniform4("uGradientStops2", stops, 8)
        for (index in 0 until 10) uniform4("uMain$index", profile.commonSettings, index * 4)
        // Non-Deep effects do not consume this bank; clear it only when the
        // profile changes so no old Deep Drift geometry can leak across scenes.
        if (profile.effectId != "deepDrift") {
            repeat(15) { runtimeShader.setFloatUniform("uDeepBlob$it", 0f, 0f, 0f, 0f) }
            repeat(3) { runtimeShader.setFloatUniform("uDeepLayer$it", 0f, 0f, 0f, 0f) }
        }
        writePortal("uBackground", profile.background)
        writePortal("uInterior", profile.interior)
        runtimeShader.setFloatUniform("uRippleCount", 0f)
        runtimeShader.setFloatUniform("uRippleRadiusTravel", 0f)
        runtimeShader.setFloatUniform("uRippleIntensity", 0f)
        runtimeShader.setFloatUniform("uTapPulseLight", 0f)
        repeat(10) { runtimeShader.setFloatUniform("uRipple$it", 0f, 0f, 0f, 0f) }
        runtimeShader.setFloatUniform("uTouchOverlayActive", 0f)
        uniform2("uTouchOverlayOrigin", 0f, 0f)
        runtimeShader.setFloatUniform("uTouchOverlayOpacity", 0f)
        runtimeShader.setFloatUniform("uTouchOverlayScale", 0f)
        runtimeShader.setFloatUniform("uTouchOverlayBlur", 0f)
        runtimeShader.setFloatUniform("uTouchInteractionOpacity", 0f)
        runtimeShader.setFloatUniform("uLiveTouchPointActive", 0f)
        uniform2("uLiveTouchPointOrigin", 0f, 0f)
        runtimeShader.setFloatUniform("uLiveTouchPointRadius", 0f)
        runtimeShader.setFloatUniform("uLiveTouchPointOpacity", 0f)
        runtimeShader.setFloatUniform("uTrailCount", 0f)
        runtimeShader.setFloatUniform("uTrailSize", 0f)
        repeat(26) { runtimeShader.setFloatUniform("uTrail$it", 0f, 0f, 0f, 0f) }
    }

    private fun writePortal(prefix: String, portal: KeyguardMaterialPortal) {
        // `effectIndex == 0` is the canonical no-material sentinel:
        // portalSample returns zero for it. Keep the selected Portal source
        // program (and its diagnostics) intact, but bind the channel as
        // inactive so a no-op portal cannot route the dynamic base field
        // through the corresponding runtime branch.
        val active = portal.enabled && portal.effectIndex > 0
        runtimeShader.setFloatUniform("${prefix}Enabled", if (active) 1f else 0f)
        runtimeShader.setFloatUniform("${prefix}Effect", portal.effectIndex.toFloat())
        // phase itself is dynamic; initialize before the first draw.
        runtimeShader.setFloatUniform("${prefix}Phase", portal.phase)
        runtimeShader.setFloatUniform("${prefix}Center", portal.paletteCenterPercent / 100f)
        runtimeShader.setFloatUniform("${prefix}Window", portal.paletteWindowPercent / 100f)
        runtimeShader.setFloatUniform("${prefix}RotationEnabled", if (portal.rotationEnabled) 1f else 0f)
        runtimeShader.setFloatUniform("${prefix}RotationSpeed", portal.rotationSpeed / 100f)
        repeat(3) { uniform4("$prefix$it", portal.settings, it * 4) }
    }

    private fun uniform2(name: String, x: Float, y: Float) = runtimeShader.setFloatUniform(name, x, y)
    private fun uniform4(name: String, x: Float, y: Float, z: Float, w: Float) = runtimeShader.setFloatUniform(name, x, y, z, w)
    private fun uniform4(name: String, values: FloatArray, offset: Int) = uniform4(name, values.getOrElse(offset) { 0f }, values.getOrElse(offset + 1) { 0f }, values.getOrElse(offset + 2) { 0f }, values.getOrElse(offset + 3) { 0f })
}

/** Exact compact CPU portion of dashboard_header_deep_drift.dart. */
private class KeyguardDeepDriftSkeleton {
    val blobs = FloatArray(60)
    val layers = FloatArray(12)
    private val baseX = floatArrayOf(.23f,.48f,.76f,.36f,.65f,.18f,.47f,.73f,.33f,.82f,.28f,.57f,.79f,.42f,.68f)
    private val baseY = floatArrayOf(.28f,.18f,.34f,.70f,.68f,.22f,.43f,.25f,.74f,.62f,.36f,.20f,.54f,.78f,.70f)
    private val baseRx = floatArrayOf(.30f,.37f,.32f,.34f,.29f,.38f,.33f,.40f,.29f,.36f,.43f,.39f,.35f,.46f,.41f)
    private val baseRy = floatArrayOf(.24f,.31f,.28f,.36f,.27f,.31f,.26f,.35f,.32f,.29f,.39f,.34f,.30f,.42f,.36f)

    fun advance(seconds: Float, values: FloatArray) {
        fun setting(index: Int, fallback: Float) = values.getOrElse(index) { fallback }.takeIf { it.isFinite() } ?: fallback
        val strength = setting(0, .82f); val speed = setting(1, .32f); val blobScale = setting(2, 1f)
        val anisotropy = setting(3, .55f); val separation = setting(8, .72f); val spread = setting(10, .62f)
        val breathingAmount = setting(13, .06f); val breathingSpeed = setting(14, .25f); val t = seconds * speed
        repeat(3) { layer ->
            val offset = layer * 4; val depth = layer / 2f; val layerPhase = .47f + layer * 1.73f
            val breathScale = if (layer == 0) 1f else if (layer == 1) .625f else .375f
            val breathing = sin(seconds * breathingSpeed * (.92f + layer * .11f) + layerPhase) * breathingAmount * breathScale
            val flow = strength * spread * (1f - depth * .42f)
            layers[offset] = flow * (.040f * sin(t * (.31f + layer * .037f) + layerPhase) + .014f * sin(t * (.67f + layer * .021f) + layerPhase * 1.8f))
            layers[offset + 1] = flow * (.032f * cos(t * (.27f + layer * .041f) + layerPhase * .7f) + .012f * sin(t * (.59f + layer * .016f) + layerPhase * 1.3f))
            layers[offset + 2] = breathing
            val migration = sin(seconds * breathingSpeed * (.29f + layer * .047f) + layerPhase * 1.61f) * separation * (.052f - layer * .011f)
            layers[offset + 3] = (separation * depth + migration).coerceIn(0f, 1f)
        }
        repeat(15) { index ->
            val layer = index / 5; val l = layer * 4; val out = index * 4; val depth = layer / 2f
            val layerMotion = 1f - depth * .46f; val p = .41f + index * 1.137f; val motion = spread * strength * layerMotion
            val dx = motion * (.055f * sin(t * (.63f + index * .017f) + p) + .018f * sin(t * (1.17f + index * .011f) + p * 2.1f))
            val dy = motion * (.046f * cos(t * (.53f + index * .019f) + p * 1.4f) + .015f * sin(t * (.97f + index * .013f) + p * .7f))
            val apparentDepth = layers[l + 3]; val scale = max(.08f, blobScale * (1f + layers[l + 2]) * (1f + (apparentDepth - .5f) * .14f))
            val stretch = 1f + anisotropy * (.20f + .16f * sin(.71f + index * .93f))
            blobs[out] = (baseX[index] + dx).coerceIn(0f, 1f); blobs[out + 1] = (baseY[index] + dy).coerceIn(0f, 1f)
            blobs[out + 2] = 1f / max(.04f, baseRx[index] * scale * stretch); blobs[out + 3] = 1f / max(.04f, baseRy[index] * scale / stretch)
        }
    }
}
