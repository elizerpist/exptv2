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
import android.util.AttributeSet
import android.view.Choreographer
import android.view.View
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

/** The one card-owned, display-synchronised clock. It never performs IPC,
 * persistence, queries or WindowManager operations. */
internal class KeyguardMaterialClock(
    private val onFrame: (Long) -> Unit,
) : Choreographer.FrameCallback {
    private var running = false
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
) : View(context, attrs) {
    enum class Shape { ORB, CARD_BACKGROUND }

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
    private var lastCanvasHardwareAccelerated: Boolean? = null
    private var lastTime: KeyguardMaterialTime? = null
    private var onDrawCount = 0
    private var shaderDrawCount = 0
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
    var onFirstShaderDraw: (() -> Unit)? = null
    private var firstShaderDrawForAttach = true
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
    private val fallbackPaint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)

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
        notifyRendererState()
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        // `isAttachedToWindow` flips during the framework call.  Publishing
        // before it would let the controller retain a frame callback for a
        // root which has already been removed from the accessibility window.
        notifyRendererState()
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        notifyRendererState()
    }

    fun setStaticBitmap(value: Bitmap?) {
        fallbackBitmap = value
        if (!materialEnabled) invalidate()
    }

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
        if (currentScene?.profile?.effectId != next.profile.effectId ||
            currentScene?.profile?.usesPortal != next.profile.usesPortal
        ) {
            shaderPrevious = shaderCurrent
            shaderCurrent = null
            attemptedProgramKey = null
        }
        current = next
        // RuntimeShader construction deliberately waits for the first real
        // hardware Canvas.  `addView()` and even View attachment are not a
        // rendering-readiness signal for an accessibility overlay.
        invalidate()
    }

    fun frame(frameTimeNanos: Long) {
        frameNanos = frameTimeNanos
        if (materialEnabled && visibility == VISIBLE && width > 0 && height > 0) invalidate()
    }

    fun pause() {
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
    fun shaderCreationCount(): Int = (shaderCurrent?.creationCount ?: 0) + (shaderPrevious?.creationCount ?: 0)
    fun lastCanvasHardwareAcceleratedForDiagnostics(): Boolean = lastCanvasHardwareAccelerated ?: false
    fun isRendererReady(): Boolean = isAttachedToWindow && width > 0 && height > 0 &&
        lastCanvasHardwareAccelerated == true && shaderCurrent != null && shaderFailure == null
    fun canAnimateMaterial(): Boolean {
        ensureShaders(current)
        return isRendererReady()
    }

    fun diagnostics(): KeyguardHeaderMaterialViewDiagnostics = KeyguardHeaderMaterialViewDiagnostics(
        onDrawCount = onDrawCount,
        shaderDrawCount = shaderDrawCount,
        fallbackDrawCount = fallbackDrawCount,
        phaseAdvanceCount = phaseAdvanceCount,
        shaderCompileAttempts = shaderCompileAttempts,
        shaderCompileSuccesses = shaderCompileSuccesses,
        shaderCompileFailures = shaderCompileFailures,
        transitionCompletedCount = transitionCompletedCount,
        lastCanvasHardwareAccelerated = lastCanvasHardwareAccelerated,
        failureStage = shaderFailure?.stage,
        failureClass = shaderFailure?.exceptionClass,
        failureMessage = shaderFailure?.message,
        generatedAgslHash = KeyguardHeaderShader.metadata(context, current?.profile?.effectId, current?.profile?.usesPortal).generatedAgslHash,
        adapterVersion = KeyguardHeaderShader.metadata(context, current?.profile?.effectId, current?.profile?.usesPortal).adapterVersion,
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
        ensureShaders(scene)
        val currentShader = shaderCurrent
        if (currentShader == null || !canvas.isHardwareAccelerated) {
            drawFallback(canvas, scene)
            return
        }
        val old = previous
        val progress = if (old == null) 1f else ((frameNanos - transitionStartedNanos) / 180_000_000f).coerceIn(0f, 1f)
        if (old != null && progress < 1f) {
            drawShader(canvas, shaderPrevious ?: currentShader, old, 1f)
            drawShader(canvas, currentShader, scene, progress)
        } else {
            if (old != null) transitionCompletedCount += 1
            previous = null
            drawShader(canvas, currentShader, scene, 1f)
        }
    }

    private fun ensureShaders(scene: KeyguardMaterialScene?) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        val profile = scene?.profile ?: return
        val metadata = KeyguardHeaderShader.metadata(context, profile.effectId, profile.usesPortal)
        val programKey = "${profile.effectId}|${profile.usesPortal}|${metadata.generatedAgslHash}|${metadata.adapterVersion}"
        if (shaderFailure != null && attemptedProgramKey == programKey) return
        if (shaderCurrent == null) {
            attemptedProgramKey = programKey
            shaderCompileAttempts += 1
            runCatching { KeyguardHeaderShader(context, profile.effectId, profile.usesPortal, metadata) }
                .onSuccess {
                    shaderCurrent = it
                    shaderCompileSuccesses += 1
                    shaderFailure = null
                    notifyRendererState()
                }
                .onFailure { error ->
                    shaderCompileFailures += 1
                    shaderFailure = KeyguardMaterialRendererFailure.compile(error, metadata)
                    notifyRendererState()
                }
        }
    }

    private fun drawShader(canvas: Canvas, shader: KeyguardHeaderShader, scene: KeyguardMaterialScene, alpha: Float) {
        val time = scene.timeAt(frameNanos)
        try {
            shader.configure(scene.profile, width, height, time)
        } catch (error: Throwable) {
            shaderFailure = KeyguardMaterialRendererFailure.uniform(error)
            notifyRendererState()
            drawFallback(canvas, scene)
            return
        }
        paint.shader = shader.runtimeShader
        paint.alpha = (alpha * 255).toInt().coerceIn(0, 255)
        when (shape) {
            Shape.ORB -> {
                val radius = min(width, height) / 2f
                canvas.drawCircle(width / 2f, height / 2f, radius, paint)
            }
            Shape.CARD_BACKGROUND -> canvas.drawRoundRect(0f, 0f, width.toFloat(), height.toFloat(), dp(22f), dp(22f), paint)
        }
        paint.shader = null
        paint.alpha = 255
        shaderDrawCount += 1
        if (firstShaderDrawForAttach) {
            firstShaderDrawForAttach = false
            onFirstShaderDraw?.invoke()
        }
        val before = lastTime
        if (before != null && (before.phase != time.phase || before.elapsedSeconds != time.elapsedSeconds)) {
            phaseAdvanceCount += 1
        }
        lastTime = time
    }

    private fun drawFallback(canvas: Canvas, scene: KeyguardMaterialScene?) {
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

    private fun drawStaticHeaderGradient(canvas: Canvas, profile: KeyguardMaterialProfile) {
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
    context: Context,
    private val effectId: String,
    private val usesPortal: Boolean,
    private val metadata: Metadata = metadata(context, effectId, usesPortal),
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

    val runtimeShader: RuntimeShader
    var creationCount = 1
        private set
    private var profileKey: String? = null
    private var sizeKey: Long = Long.MIN_VALUE
    private val deepDrift = KeyguardDeepDriftSkeleton()

    init {
        require(effectId in KeyguardMaterialProfile.effectIds) { "unknown-effect:$effectId" }
        val variant = if (usesPortal) "portal" else "plain"
        val source = context.assets.open("fluvi_keyguard_header_material_${effectId}_$variant.agsl").bufferedReader().use { it.readText() }
        runtimeShader = RuntimeShader(source)
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
        runtimeShader.setFloatUniform("${prefix}Enabled", if (portal.enabled) 1f else 0f)
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
