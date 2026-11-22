package com.android.systemui.keyguard.fluvi

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.HardwareBufferRenderer
import android.graphics.Paint
import android.graphics.RenderNode
import android.hardware.HardwareBuffer
import com.fluvi.app.lockscreen.material.KeyguardMaterialScene
import com.fluvi.app.lockscreen.material.KeyguardMaterialTime
import com.fluvi.app.lockscreen.material.KeyguardOrbSurfaceFrameTime
import com.fluvi.app.lockscreen.material.KeyguardOrbSurfacePainter
import com.fluvi.app.lockscreen.material.R29MaterialMapper
import com.fluvi.r29.contract.R29Descriptor
import com.fluvi.r29.contract.R29Disclosure
import com.fluvi.r29.contract.R29Motion
import java.util.concurrent.Executor

/**
 * Prepared away from the composition thread. Ownership of [livePainter]
 * transfers once to the display owner after successful GPU preparation.
 */
internal class R29PreparedOrb(
    val descriptor: R29Descriptor,
    private val poster: Bitmap,
    private val scene: KeyguardMaterialScene,
    private val livePainter: KeyguardOrbSurfacePainter,
) {
    private val bitmapPaint = Paint(Paint.FILTER_BITMAP_FLAG)
    private val time = KeyguardOrbSurfaceFrameTime()
    private var visibleScene: KeyguardMaterialScene? = null

    /** Called only by the current, already-authorized host display owner. */
    fun draw(canvas: Canvas, left: Float, top: Float, nowNanos: Long) {
        val save = canvas.save()
        try {
            canvas.translate(left, top)
            val active = visibleScene
            if (active == null || descriptor.motion == R29Motion.STATIC) {
                canvas.drawBitmap(poster, 0f, 0f, bitmapPaint)
                if (active == null) visibleScene = scene.copy(appliedAtNanos = nowNanos)
            } else {
                active.timeAtInto(nowNanos, time)
                livePainter.draw(canvas, time)
            }
        } finally {
            canvas.restoreToCount(save)
        }
    }

    /** Re-entering after exclusion starts again from the retained poster. */
    fun resetVisiblePhase() { visibleScene = null }
}

/**
 * One semantic preparation at a time, invoked on the host's worker. The
 * hardware-buffer render samples the actual poster before success is reported.
 * It says nothing about physical display presentation or later GPU residency.
 */
internal class R29HostRenderer(private val context: Context, private val worker: Executor) {
    private data class PendingGpu(val renderer: HardwareBufferRenderer, val buffer: HardwareBuffer, val node: RenderNode)
    private var pending: PendingGpu? = null
    private var quarantined: PendingGpu? = null

    /** All calls and [finished] execute on [worker]; [finished] is not a display acknowledgement. */
    fun prepare(descriptor: R29Descriptor, finished: (Result<R29PreparedOrb>) -> Unit) {
        if (pending != null || quarantined != null) {
            finished(Result.failure(IllegalStateException("host GPU preparation unavailable")))
            return
        }
        val size = descriptor.orbSizePx
        val result = runCatching {
            val profile = R29MaterialMapper.toProfile(descriptor.material, descriptor.session, descriptor.sequence)
            val first = KeyguardMaterialTime(profile.elapsedSeconds, profile.phase,
                profile.background.phase, profile.interior.phase)
            val posterPainter = KeyguardOrbSurfacePainter(context, profile, size, size)
            val poster = posterPainter.makePoster(first)
            // Independent mutable shader/paint owner for later host motion.
            val livePainter = KeyguardOrbSurfacePainter(context, profile, size, size)
            val scene = KeyguardMaterialScene(profile, descriptor.disclosure == R29Disclosure.FULL, 0L)
            R29PreparedOrb(descriptor, poster, scene, livePainter) to poster
        }
        val (prepared, poster) = result.getOrElse { finished(Result.failure(it)); return }
        val buffer = try {
            HardwareBuffer.create(size, size, HardwareBuffer.RGBA_8888, 1,
                HardwareBuffer.USAGE_GPU_COLOR_OUTPUT or HardwareBuffer.USAGE_GPU_SAMPLED_IMAGE)
        } catch (error: Throwable) {
            finished(Result.failure(error)); return
        }
        val node = RenderNode("fluvi-r29-poster-warm").apply { setPosition(0, 0, size, size) }
        val renderer = try { HardwareBufferRenderer(buffer) } catch (error: Throwable) {
            buffer.close(); finished(Result.failure(error)); return
        }
        val gpu = PendingGpu(renderer, buffer, node)
        try {
            val canvas = node.beginRecording()
            try {
                canvas.drawColor(Color.TRANSPARENT, android.graphics.PorterDuff.Mode.CLEAR)
                canvas.drawBitmap(poster, 0f, 0f, null)
            } finally { node.endRecording() }
            renderer.setContentRoot(node)
            pending = gpu
            renderer.obtainRenderRequest().draw(worker) { render ->
                // A missing/invalid/unsignalled fence never becomes READY and
                // never frees an allocation whose GPU ownership is unknown.
                val safe = runCatching {
                    render.status == HardwareBufferRenderer.RenderResult.SUCCESS &&
                        render.fence?.use { it.isValid && it.awaitForever() } == true
                }.getOrDefault(false)
                pending = null
                if (safe) {
                    node.discardDisplayList()
                    renderer.close()
                    buffer.close()
                    finished(Result.success(prepared))
                } else {
                    quarantined = gpu
                    finished(Result.failure(IllegalStateException("poster GPU fence unconfirmed")))
                }
            }
        } catch (error: Throwable) {
            // Transfer may have happened before an exception. Retain this one
            // allocation and refuse future work rather than speculate on reuse.
            pending = null
            quarantined = gpu
            finished(Result.failure(error))
        }
    }
}
