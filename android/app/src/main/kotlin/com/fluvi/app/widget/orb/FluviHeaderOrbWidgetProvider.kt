package com.fluvi.app.widget.orb

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Bundle
import android.os.Parcel
import android.util.AtomicFile
import android.util.Log
import android.widget.RemoteViews
import com.fluvi.app.R
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.DataInputStream
import java.io.DataOutputStream
import java.io.File
import java.security.MessageDigest
import java.util.UUID
import java.util.concurrent.Executors

/** All view delivery goes through Android's normal AppWidget protocol. */
class FluviHeaderOrbWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, appWidgetIds: IntArray) {
        refresh(context, appWidgetIds)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        manager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        refresh(context, intArrayOf(appWidgetId))
    }

    companion object {
        /** Called by the embedded host when its frame or access is disabled. */
        fun revokeSharing(context: Context) {
            val application = context.applicationContext
            HeaderOrbWidgetContent.execute {
                HeaderOrbWidgetContent.setSharing(application, false)
            }
        }
    }

    private fun refresh(context: Context, ids: IntArray) {
        val pending = goAsync()
        val application = context.applicationContext
        HeaderOrbWidgetContent.execute {
            try {
                HeaderOrbWidgetContent.refresh(application, ids)
            } finally {
                pending.finish()
            }
        }
    }
}

/** One process-local queue orders consent, preparation, writes and delivery. */
internal object HeaderOrbWidgetContent {
    private val queue = Executors.newSingleThreadExecutor()
    private var preparation: Preparation? = null
    private var outcome = "waitingForHeader"

    private data class Preparation(val token: String, val mode: String, val key: String)

    fun execute(block: () -> Unit) {
        queue.execute {
            try {
                block()
            } catch (error: Exception) {
                Log.w("FluviHeaderOrb", "Widget operation failed: ${error.javaClass.simpleName}")
            }
        }
    }

    fun setupIntent(context: Context): Intent = Intent().setClassName(
        context.packageName, "tk.zwander.lockscreenwidgets.MainActivity",
    )

    fun status(context: Context): Map<String, Any> {
        val service = ComponentName(context.packageName, "tk.zwander.lockscreenwidgets.services.Accessibility")
        val installed = runCatching { context.packageManager.getServiceInfo(service, 0) }.isSuccess
        val enabled = android.provider.Settings.Secure.getString(
            context.contentResolver, android.provider.Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        ).orEmpty().split(':').any { ComponentName.unflattenFromString(it) == service }
        val sharing = optedIn(context)
        val packet = if (sharing) read(context) else null
        return mapOf(
            "hostAvailable" to installed,
            "accessibilityEnabled" to enabled,
            "sharing" to sharing,
            "ready" to (packet != null),
            "state" to if (packet == null) outcome else "ready",
            "widgetCount" to widgetIds(context).size,
        )
    }

    fun setSharing(context: Context, sharing: Boolean) {
        val marker = consent(context)
        if (sharing) {
            check(context.packageManager.resolveActivity(setupIntent(context), 0) != null)
            if (!marker.exists()) check(marker.createNewFile())
        } else {
            // Revoke the disk authority before any queued refresh can use it.
            preparation = null
            check(!marker.exists() || marker.delete())
            store(context).delete()
            deliver(context, widgetIds(context), null, emptyList())
            outcome = "waitingForHeader"
        }
    }

    fun prepare(context: Context, mode: String, signature: String): Map<String, Any> {
        if (!optedIn(context)) return emptyMap()
        require(mode in setOf("mind", "balance", "budget") && signature.length in 1..8192)
        val key = digest(signature.toByteArray()).joinToString("") { "%02x".format(it) }
        val current = read(context)
        if (current?.key == key && current.mode == mode) return mapOf("cached" to true)

        preparation = null
        if (current != null || store(context).baseFile.exists()) {
            store(context).delete()
            deliver(context, widgetIds(context), null, emptyList())
        }
        val request = Preparation(UUID.randomUUID().toString(), mode, key)
        preparation = request
        outcome = "preparing"
        return mapOf("token" to request.token)
    }

    fun unavailable(token: String?) {
        if (preparation?.token == token && token != null) {
            preparation = null
            outcome = "materialUnavailable"
        }
    }

    fun publish(
        context: Context,
        token: String?,
        size: Int?,
        intervalMs: Int?,
        origin: Long?,
        motion: Boolean?,
        frames: List<ByteArray>?,
    ): Boolean {
        val request = preparation ?: return false
        if (!optedIn(context) || request.token != token) return false
        preparation = null
        val packet = HeaderOrbPackage(
            request.key, request.mode, request.token,
            OrbFramePlan(
                sizePx = requireNotNull(size),
                frameCount = requireNotNull(frames).size,
                intervalMs = requireNotNull(intervalMs),
                phaseOriginUtcMs = requireNotNull(origin),
            ),
            requireNotNull(motion), frames,
        )
        return try {
            val bitmaps = packet.decode()
            write(context, packet)
            deliver(context, widgetIds(context), packet, bitmaps)
            outcome = "ready"
            true
        } catch (error: Exception) {
            store(context).delete()
            deliver(context, widgetIds(context), null, emptyList())
            outcome = "materialUnavailable"
            throw error
        }
    }

    fun refresh(context: Context, requested: IntArray = widgetIds(context)) {
        val ids = widgetIds(context).toSet()
        val packet = if (optedIn(context)) read(context) else null
        val frames = runCatching { packet?.decode().orEmpty() }.getOrDefault(emptyList())
        deliver(context, requested.filter(ids::contains).toIntArray(), packet, frames)
    }

    private fun deliver(
        context: Context,
        ids: IntArray,
        packet: HeaderOrbPackage?,
        frames: List<Bitmap>,
    ) {
        val manager = AppWidgetManager.getInstance(context)
        for (id in ids) {
            val empty = RemoteViews(context.packageName, R.layout.fluvi_header_orb_empty)
            val views = if (packet != null && frames.size == packet.plan.frameCount) {
                val size = OrbWidgetDisplayDimensions.shortSidePx(context, manager.getAppWidgetOptions(id))
                orbPlaybackViews(context, packet.plan, frames, size).also {
                    val parcel = Parcel.obtain()
                    try {
                        it.writeToParcel(parcel, 0)
                        // Include action/layout overhead as well as out-of-line bitmap storage.
                        require(parcel.dataSize() + packet.plan.estimatedRawBytes <= MAX_DELIVERY_BYTES)
                    } finally {
                        parcel.recycle()
                    }
                }
            } else {
                empty
            }
            manager.updateAppWidget(id, views)
        }
    }

    private fun widgetIds(context: Context): IntArray =
        AppWidgetManager.getInstance(context).getAppWidgetIds(ComponentName(context, FluviHeaderOrbWidgetProvider::class.java))

    private fun consent(context: Context) = File(context.noBackupFilesDir, "header-orb-sharing-v1")
    private fun optedIn(context: Context) = consent(context).isFile

    private fun store(context: Context) = AtomicFile(File(context.noBackupFilesDir, "header-orb-frames-v1"))

    private fun write(context: Context, packet: HeaderOrbPackage) {
        val file = store(context)
        val encoded = packet.encode()
        val stream = file.startWrite()
        try {
            stream.write(encoded)
            file.finishWrite(stream)
        } catch (error: Exception) {
            file.failWrite(stream)
            throw error
        }
    }

    private fun read(context: Context): HeaderOrbPackage? = runCatching {
        store(context).openRead().use { input ->
            require(input.channel.size() <= MAX_PACKAGE_BYTES)
            HeaderOrbPackage.read(input.readBytes())
        }
    }.getOrNull()

    private const val MAX_DELIVERY_BYTES = 960 * 1024L
}

private val modeNames = setOf("mind", "balance", "budget")
private const val PACKAGE_VERSION = 1
private const val DIGEST_BYTES = 32
private const val MAX_PACKAGE_BYTES = OrbMaterialPlaybackContract.maximumEncodedBytes + 4096L
private fun digest(bytes: ByteArray) = MessageDigest.getInstance("SHA-256").digest(bytes)

internal data class HeaderOrbPackage(
    val key: String,
    val mode: String,
    val generation: String,
    val plan: OrbFramePlan,
    val animated: Boolean,
    val pngs: List<ByteArray>,
) {
    init {
        require(mode in modeNames && key.matches(Regex("[a-f0-9]{64}")))
        require(UUID.fromString(generation).toString() == generation)
        require(plan.frameCount in 1..OrbMaterialPlaybackContract.maximumFrameCount)
        require(plan.sizePx in OrbMaterialPlaybackContract.minimumFrameSizePx..OrbMaterialPlaybackContract.maximumFrameSizePx)
        require(plan.intervalMs in OrbMaterialPlaybackContract.minimumFlipIntervalMs..OrbMaterialPlaybackContract.maximumFlipIntervalMs)
        require(plan.phaseOriginUtcMs > 0 && animated == (plan.frameCount > 1))
        require(!animated || plan.frameCount >= 3)
        require(pngs.size == plan.frameCount && pngs.all { it.isNotEmpty() })
        require(plan.estimatedRawBytes <= OrbMaterialPlaybackContract.maximumDecodedBytes)
        require(pngs.sumOf { it.size.toLong() } <= OrbMaterialPlaybackContract.maximumEncodedBytes)
    }

    fun decode(): List<Bitmap> = pngs.map { png ->
        val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(png, 0, png.size, options)
        require(options.outMimeType == "image/png" && options.outWidth == plan.sizePx && options.outHeight == plan.sizePx)
        requireNotNull(BitmapFactory.decodeByteArray(png, 0, png.size))
    }.also { bitmaps ->
        require(bitmaps.sumOf { it.allocationByteCount.toLong() } <= OrbMaterialPlaybackContract.maximumDecodedBytes)
        require(!animated || bitmaps.drop(1).any { !it.sameAs(bitmaps.first()) })
    }

    fun encode(): ByteArray {
        val content = ByteArrayOutputStream()
        DataOutputStream(content).use { out ->
            out.writeInt(PACKAGE_VERSION)
            out.writeUTF(key)
            out.writeUTF(mode)
            out.writeUTF(generation)
            out.writeInt(plan.sizePx)
            out.writeInt(plan.intervalMs)
            out.writeLong(plan.phaseOriginUtcMs)
            out.writeBoolean(animated)
            out.writeInt(pngs.size)
            for (png in pngs) {
                out.writeInt(png.size)
                out.write(png)
            }
        }
        val body = content.toByteArray()
        return body + digest(body)
    }

    companion object {
        fun read(bytes: ByteArray): HeaderOrbPackage {
            require(bytes.size > DIGEST_BYTES && bytes.size <= MAX_PACKAGE_BYTES)
            val end = bytes.size - DIGEST_BYTES
            require(MessageDigest.isEqual(bytes.copyOfRange(end, bytes.size), digest(bytes.copyOf(end))))
            return DataInputStream(ByteArrayInputStream(bytes, 0, end)).use { input ->
                require(input.readInt() == PACKAGE_VERSION)
                val key = input.readUTF()
                val mode = input.readUTF()
                val generation = input.readUTF()
                val size = input.readInt()
                val interval = input.readInt()
                val origin = input.readLong()
                val motion = input.readBoolean()
                val count = input.readInt()
                require(count in 1..OrbMaterialPlaybackContract.maximumFrameCount)
                val pngs = List(count) {
                    val sizeBytes = input.readInt()
                    require(sizeBytes in 1..input.available())
                    ByteArray(sizeBytes).also(input::readFully)
                }
                require(input.available() == 0)
                HeaderOrbPackage(key, mode, generation, OrbFramePlan(size, count, interval, phaseOriginUtcMs = origin), motion, pngs)
            }
        }
    }
}
