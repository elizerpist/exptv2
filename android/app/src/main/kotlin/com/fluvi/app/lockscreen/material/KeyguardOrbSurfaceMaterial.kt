package com.fluvi.app.lockscreen.material

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Picture
import android.graphics.PorterDuff
import android.graphics.Shader
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.sin

/** Never share a publisher-owned mutable uniform array with the render lane. */
internal fun KeyguardMaterialProfile.copyForSurface(): KeyguardMaterialProfile = copy(
    colors = colors.copyOf(),
    stops = stops.copyOf(),
    commonSettings = commonSettings.copyOf(),
    background = background.copy(settings = background.settings.copyOf()),
    interior = interior.copy(settings = interior.settings.copyOf()),
)

/** Mutable only on the surface worker, avoiding frame-by-frame allocations. */
internal class KeyguardOrbSurfaceFrameTime(
    var elapsedSeconds: Float = 0f,
    var phase: Float = 0f,
    var backgroundPhase: Float = 0f,
    var interiorPhase: Float = 0f,
)

/** Identical ORB bounds for the retained View and the platform surface. */
internal fun drawKeyguardOrbCircle(canvas: Canvas, paint: Paint, width: Int, height: Int) {
    canvas.drawCircle(width / 2f, height / 2f, min(width, height) / 2f, paint)
}

/** Canonical static Header gradient, shared with the legacy ORB View. */
internal fun configureKeyguardStaticOrbPaint(paint: Paint, profile: KeyguardMaterialProfile, width: Int, height: Int) {
    val count = min(profile.colors.size, profile.stops.size)
    if (count < 2) {
        paint.shader = null
        paint.color = profile.colors.firstOrNull() ?: Color.rgb(101, 116, 137)
    } else {
        val radians = 112f * (Math.PI.toFloat() / 180f)
        val dx = sin(radians)
        val dy = -cos(radians)
        val half = (width * abs(dx) + height * abs(dy)) / 2f
        paint.shader = LinearGradient(width / 2f - dx * half, height / 2f - dy * half,
            width / 2f + dx * half, height / 2f + dy * half,
            profile.colors.copyOf(count), profile.stops.copyOf(count), Shader.TileMode.CLAMP)
    }
}

internal fun KeyguardMaterialProfile.usesStaticOrbGradient(): Boolean =
    effectId == "staticEffect" && !background.enabled && !interior.enabled

/** Worker-owned mutable shader/paint state. The same configured painter is
 * used to record the first picture and to draw subsequent hardware frames. */
internal class KeyguardOrbSurfacePainter(
    context: Context,
    val profile: KeyguardMaterialProfile,
    private val width: Int,
    private val height: Int,
    preparedShader: KeyguardHeaderShader? = null,
) {
    private val staticGradient = profile.usesStaticOrbGradient()
    private val shader = if (staticGradient) null else preparedShader ?:
        KeyguardHeaderShader(context, profile.effectId, profile.usesPortal)
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)

    init {
        require(width > 0 && height > 0)
        if (staticGradient) {
            configureKeyguardStaticOrbPaint(paint, profile, width, height)
        } else paint.shader = checkNotNull(shader).runtimeShader
    }

    fun draw(canvas: Canvas, time: KeyguardMaterialTime, blend: Float = 1f) {
        prepare(time.elapsedSeconds, time.phase, time.backgroundPhase, time.interiorPhase, blend)
        drawPrepared(canvas)
    }

    fun draw(canvas: Canvas, time: KeyguardOrbSurfaceFrameTime, blend: Float = 1f) {
        prepare(time, blend)
        drawPrepared(canvas)
    }

    /** Configure uniforms and paint before acquiring the holder. */
    fun prepare(time: KeyguardOrbSurfaceFrameTime, blend: Float = 1f) =
        prepare(time.elapsedSeconds, time.phase, time.backgroundPhase, time.interiorPhase, blend)

    private fun prepare(elapsed: Float, phase: Float, background: Float, interior: Float, blend: Float) {
        shader?.configure(profile, width, height, elapsed, phase, background, interior)
        val opacity = if (staticGradient) profile.opacity else 1f
        paint.alpha = (opacity * blend * 255f).toInt().coerceIn(0, 255)
    }

    fun drawPrepared(canvas: Canvas) {
        drawKeyguardOrbCircle(canvas, paint, width, height)
    }

    fun makePoster(time: KeyguardMaterialTime): Bitmap {
        val picture = Picture()
        val canvas = picture.beginRecording(width, height)
        try {
            canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)
            draw(canvas, time)
        } finally {
            picture.endRecording()
        }
        return Bitmap.createBitmap(picture, width, height, Bitmap.Config.HARDWARE)
    }
}
