package com.fluvi.app.lockscreen.material

import android.content.Context
import android.graphics.Bitmap
import android.os.Handler
import android.os.HandlerThread
import android.os.SystemClock
import com.fluvi.app.R

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
    data class Image(val identity: Identity, val bitmap: Bitmap, val phase: KeyguardMaterialTime,
                     val readyAtUptimeMs: Long)
    private data class Work(
        val ticket: KeyguardR34PrivateAssetCache.Ticket<Identity>,
        val profile: KeyguardMaterialProfile,
    )

    private val cache = KeyguardR34PrivateAssetCache<Identity, Image> { image ->
        // A consumer must retain its lease until the platform is finished.
        image.bitmap.recycle()
    }
    private val lock = Any()
    private val thread = HandlerThread("Fluvi-private-orb-poster").apply { start() }
    private val handler = Handler(thread.looper)
    private var pending: Work? = null
    private var scheduled = false
    private var closed = false

    companion object {
        /** The phase belongs to the prepared image, not a wake-time lookup.
         * The remaining serialized fields preserve the full value identity,
         * including publisher/data revisions and all palette parameters. */
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
        val ticket = cache.request(identity) ?: return
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

    /** The queue stores only the latest not-yet-started request. An older
     * completed render may not replace a later A/B/A generation. */
    private fun drain() {
        while (true) {
            val work = synchronized(lock) {
                pending?.also { pending = null } ?: run { scheduled = false; return }
            }
            if (!cache.isCurrent(work.ticket)) continue
            val key = work.ticket.key
            val image = runCatching {
                val supported = context.resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_orb_size)
                require(supported in 1..4096 && key.width == supported && key.height == supported)
                val profile = work.profile
                val phase = KeyguardMaterialTime(profile.elapsedSeconds, profile.phase,
                    profile.background.phase, profile.interior.phase)
                val bitmap = KeyguardOrbSurfacePainter(context, profile, key.width, key.height).makePoster(phase)
                Image(key, bitmap, phase, SystemClock.uptimeMillis())
            }.getOrNull()
            if (image == null) cache.failed(work.ticket)
            else if (cache.publish(work.ticket, image) && KeyguardOrbSurfaceWorkerTestHooks.ENABLED) {
                runCatching { KeyguardOrbSurfaceWorkerTestHooks.afterWarmPosterCreated?.invoke(true) }
            }
        }
    }

    fun acquire(identity: Identity): KeyguardR34PrivateAssetCache.Lease<Image>? = cache.acquire(identity)

    fun clear() {
        synchronized(lock) { pending = null }
        cache.clear()
    }

    fun dispose() {
        synchronized(lock) { closed = true; pending = null }
        cache.close()
        thread.quitSafely()
    }
}
