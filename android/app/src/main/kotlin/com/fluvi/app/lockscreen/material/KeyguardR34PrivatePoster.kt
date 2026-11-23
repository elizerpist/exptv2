package com.fluvi.app.lockscreen.material

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.ColorSpace
import android.graphics.HardwareBufferRenderer
import android.graphics.PorterDuff
import android.graphics.RenderNode
import android.hardware.HardwareBuffer
import android.hardware.SyncFence
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.SystemClock
import com.fluvi.app.R
import java.time.Duration
import java.util.concurrent.Executor
import java.util.concurrent.atomic.AtomicBoolean

/** Detached, app-private pixels. This class neither owns a Surface nor grants
 * disclosure; a later current lockscreen decision is still mandatory. */
internal class KeyguardR34PrivatePoster(private val context: Context) {
    data class Identity(
        val profile: String,
        val width: Int,
        val height: Int,
        val densityDpi: Int,
        val settingsGeneration: Long,
        val focusGeneration: Long,
    )
    data class Image(val identity: Identity, val ticket: KeyguardR34PrivateAssetCache.Ticket<Identity>,
                     val bitmap: Bitmap, val phase: KeyguardMaterialTime, val buffer: HardwareBuffer?,
                     val bufferStatus: String, val readyAtUptimeMs: Long)
    private data class Work(
        val ticket: KeyguardR34PrivateAssetCache.Ticket<Identity>,
        val profile: KeyguardMaterialProfile,
    )
    private data class GpuWork(val buffer: HardwareBuffer, val renderer: HardwareBufferRenderer,
                               val node: RenderNode, val bitmap: Bitmap, val fence: SyncFence? = null)

    private val cache = KeyguardR34PrivateAssetCache<Identity, Image> { image ->
        // Closing a transferred buffer is allowed only after its last real
        // consumer lease ends. Do not recycle a bitmap submitted to Canvas:
        // Android's retained drawing commands may still reference it.
        runCatching { image.buffer?.close() }
    }
    private val lock = Any()
    private val thread = HandlerThread("Fluvi-private-orb-poster").apply { start() }
    private val handler = Handler(thread.looper)
    private val callbackExecutor = Executor { command -> handler.post(command) }
    private var pending: Work? = null
    private var scheduled = false
    private var closed = false
    private var quarantined: GpuWork? = null // worker-only, at most one unproven GPU use
    @Volatile private var desiredIdentity: Identity? = null

    companion object {
        /** The phase belongs to the prepared image, not a wake-time lookup.
         * The remaining serialized fields preserve full value identity. */
        fun identity(profile: KeyguardMaterialProfile, width: Int, height: Int, densityDpi: Int,
                     settingsGeneration: Long, focusGeneration: Long): Identity {
            val value = profile.toJson().apply {
                remove("phase")
                remove("elapsedSeconds")
                getJSONObject("background").remove("phase")
                getJSONObject("interior").remove("phase")
            }.toString()
            return Identity(value, width, height, densityDpi, settingsGeneration, focusGeneration)
        }
    }

    fun prepare(profile: KeyguardMaterialProfile, width: Int, height: Int, densityDpi: Int,
                settingsGeneration: Long, focusGeneration: Long) {
        val safe = profile.copyForSurface()
        val identity = identity(safe, width, height, densityDpi, settingsGeneration, focusGeneration)
        val ticket = cache.request(identity)
        desiredIdentity = identity
        if (ticket == null) return
        val post = synchronized(lock) {
            if (closed) return@synchronized false
            pending = Work(ticket, safe)
            if (scheduled) false else { scheduled = true; true }
        }
        if (post && !handler.post(::drain)) {
            synchronized(lock) { scheduled = false; pending = null }
            cache.failed(ticket)
        }
    }

    /** A ready lease is not disclosure permission. Its scene and focus must
     * still match the current, independently-authorized first-paint ticket. */
    fun acquire(profile: KeyguardMaterialProfile, width: Int, height: Int, densityDpi: Int,
                focusGeneration: Long): KeyguardR34PrivateAssetCache.Lease<Image>? {
        val expected = desiredIdentity ?: return null
        if (expected.focusGeneration != focusGeneration) return null
        val actual = identity(profile, width, height, densityDpi, expected.settingsGeneration, focusGeneration)
        return if (actual == expected) cache.acquire(expected) else null
    }

    /** One producer and at most one latest waiting request. */
    private fun drain() {
        val work = synchronized(lock) {
            pending?.also { pending = null } ?: run {
                scheduled = false
                if (closed) thread.quitSafely()
                return
            }
        }
        if (!cache.isCurrent(work.ticket)) { continueDrain(); return }
        val key = work.ticket.key
        val generated = runCatching {
            val supported = context.resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_orb_size)
            require(supported in 1..4096 && key.width == supported && key.height == supported)
            val profile = work.profile
            val phase = KeyguardMaterialTime(profile.elapsedSeconds, profile.phase,
                profile.background.phase, profile.interior.phase)
            val bitmap = KeyguardOrbSurfacePainter(context, profile, key.width, key.height).makePoster(phase)
            bitmap to phase
        }.getOrNull()
        if (generated == null) { cache.failed(work.ticket); continueDrain(); return }
        val (bitmap, phase) = generated
        if (!cache.isCurrent(work.ticket)) { bitmap.recycle(); continueDrain(); return }
        if (Build.VERSION.SDK_INT < 34 || quarantined != null) {
            finish(work, bitmap, phase, null, if (quarantined != null) "GPU_QUARANTINED" else "API_UNSUPPORTED")
            return
        }
        val usage = HardwareBuffer.USAGE_GPU_COLOR_OUTPUT or HardwareBuffer.USAGE_GPU_SAMPLED_IMAGE or
            HardwareBuffer.USAGE_COMPOSER_OVERLAY
        if (!runCatching { HardwareBuffer.isSupported(key.width, key.height, HardwareBuffer.RGBA_8888, 1, usage) }.getOrDefault(false)) {
            finish(work, bitmap, phase, null, "BUFFER_UNSUPPORTED")
            return
        }
        val buffer = runCatching { HardwareBuffer.create(key.width, key.height, HardwareBuffer.RGBA_8888, 1, usage) }.getOrNull()
        if (buffer == null) { finish(work, bitmap, phase, null, "BUFFER_CREATE_FAILED"); return }
        val node = runCatching { RenderNode("fluvi-private-orb-poster").apply { setPosition(0, 0, key.width, key.height) } }.getOrNull()
        if (node == null) { buffer.close(); finish(work, bitmap, phase, null, "NODE_UNAVAILABLE"); return }
        val renderer = runCatching { HardwareBufferRenderer(buffer) }.getOrNull()
        if (renderer == null) {
            buffer.close(); node.discardDisplayList()
            finish(work, bitmap, phase, null, "RENDERER_UNAVAILABLE")
            return
        }
        val gpu = GpuWork(buffer, renderer, node, bitmap)
        val settled = AtomicBoolean(false)
        var submitted = false
        try {
            val canvas = node.beginRecording()
            try {
                canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)
                canvas.drawBitmap(bitmap, 0f, 0f, null)
            } finally { node.endRecording() }
            renderer.setContentRoot(node)
            val request = renderer.obtainRenderRequest().setColorSpace(ColorSpace.get(ColorSpace.Named.SRGB))
            submitted = true // throwing draw does not prove that ownership stayed local
            request.draw(callbackExecutor) { result ->
                val fence = result.fence
                val complete = runCatching { fence != null && fence.isValid && fence.await(Duration.ofSeconds(1)) }.getOrDefault(false)
                if (!settled.compareAndSet(false, true)) {
                    // A draw that threw after transfer may still deliver its
                    // real receipt. Drain only after its actual fence signals.
                    if (complete) {
                        runCatching { fence?.close() }
                        runCatching { renderer.close() }
                        runCatching { node.discardDisplayList() }
                        runCatching { buffer.close() }
                        if (quarantined?.buffer === buffer) quarantined = null
                    } else if (quarantined?.buffer === buffer) quarantined = gpu.copy(fence = fence)
                    return@draw
                }
                if (complete) {
                    runCatching { fence?.close() }
                    runCatching { renderer.close() }
                    runCatching { node.discardDisplayList() }
                    if (result.status == HardwareBufferRenderer.RenderResult.SUCCESS) {
                        finish(work, bitmap, phase, buffer, "COMPOSITOR_READY")
                    } else {
                        buffer.close()
                        finish(work, bitmap, phase, null, "GPU_RENDER_FAILED")
                    }
                } else {
                    // Neither timeout nor an invalid/missing fence proves the
                    // GPU finished. Keep this one use and stop allocating
                    // more compositor buffers; the Canvas route remains safe.
                    quarantined = gpu.copy(fence = fence)
                    finish(work, bitmap, phase, null, "GPU_FENCE_UNPROVEN")
                }
            }
        } catch (_: Throwable) {
            if (settled.compareAndSet(false, true)) {
                if (submitted) quarantined = gpu
                else { runCatching { renderer.close() }; runCatching { node.discardDisplayList() }; runCatching { buffer.close() } }
                finish(work, bitmap, phase, null, if (submitted) "GPU_TRANSFER_UNKNOWN" else "GPU_SETUP_FAILED")
            }
        }
    }

    private fun finish(work: Work, bitmap: Bitmap, phase: KeyguardMaterialTime,
                       buffer: HardwareBuffer?, status: String) {
        val image = Image(work.ticket.key, work.ticket, bitmap, phase, buffer, status, SystemClock.uptimeMillis())
        if (cache.publish(work.ticket, image) && KeyguardOrbSurfaceWorkerTestHooks.ENABLED) {
            runCatching { KeyguardOrbSurfaceWorkerTestHooks.afterWarmPosterCreated?.invoke(true) }
        }
        continueDrain()
    }

    private fun continueDrain() {
        if (!handler.post(::drain)) synchronized(lock) { scheduled = false; pending = null }
    }

    fun isCurrent(image: Image): Boolean = desiredIdentity == image.identity && cache.isCurrent(image.ticket)

    fun clear() {
        desiredIdentity = null
        synchronized(lock) { pending = null }
        cache.clear()
    }

    fun dispose() {
        desiredIdentity = null
        val quit = synchronized(lock) { closed = true; pending = null; !scheduled }
        cache.close()
        if (quit) thread.quitSafely()
    }
}
