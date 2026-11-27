package com.fluvi.app.widget.orb

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
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

    private fun refresh(context: Context, ids: IntArray) {
        val result = goAsync()
        val application = context.applicationContext
        val binding = HeaderOrbBinding.get(application)
        HeaderOrbWidgetContent.execute {
            try {
                if (binding.authority?.id?.let { it in ids } == true) {
                    HeaderOrbWidgetContent.refresh(application, binding)
                }
            } finally {
                result.finish()
            }
        }
    }
}

/** Serial frame preparation and delivery. The binding has independent revocation authority. */
internal object HeaderOrbWidgetContent {
    private val queue = Executors.newSingleThreadExecutor()
    private var preparation: Preparation? = null

    private data class Preparation(val owner: HeaderOrbBinding.Authority, val token: String, val key: String)

    fun execute(block: () -> Unit) {
        queue.execute {
            try {
                block()
            } catch (error: Exception) {
                Log.w("FluviBalanceOrb", "Widget operation failed: ${error.javaClass.simpleName}")
            }
        }
    }

    fun prepare(context: Context, binding: HeaderOrbBinding, signature: String): Map<String, Any> {
        val owner = binding.authority ?: return emptyMap()
        require(signature.length in 1..8192)
        val key = digest(signature.toByteArray()).joinToString("") { "%02x".format(it) }
        preparation = null
        if (read(context, owner)?.key == key) return mapOf("cached" to true)
        val request = Preparation(owner, UUID.randomUUID().toString(), key)
        preparation = request
        Log.i("FluviBalanceOrb", "stage=material-prepare id=${owner.id}")
        return mapOf("token" to request.token)
    }

    fun unavailable(token: String?, reason: String?) {
        val request = preparation ?: return
        if (request.token != token) return
        preparation = null
        val outcome = reason?.takeIf { it.matches(Regex("[a-zA-Z]{1,32}")) } ?: "unknown"
        Log.i("FluviBalanceOrb", "stage=material-unavailable id=${request.owner.id} reason=$outcome")
    }

    fun publish(
        context: Context,
        binding: HeaderOrbBinding,
        token: String?,
        size: Int?,
        intervalMs: Int?,
        origin: Long?,
        motion: Boolean?,
        frames: List<ByteArray>?,
    ): Boolean {
        val request = preparation ?: return false
        val owner = request.owner
        if (owner != binding.authority || request.token != token) return false
        preparation = null
        val packet = HeaderOrbPackage(
            request.key, owner.epoch, request.token,
            OrbFramePlan(
                sizePx = requireNotNull(size),
                frameCount = requireNotNull(frames).size,
                intervalMs = requireNotNull(intervalMs),
                phaseOriginUtcMs = requireNotNull(origin),
            ),
            requireNotNull(motion), frames,
        )
        val views = playback(context, owner.id, packet)
        val previous = read(context, owner)
        if (binding.authority != owner) return false
        write(context, packet)
        if (binding.authority != owner) return false
        try {
            AppWidgetManager.getInstance(context).updateAppWidget(owner.id, views)
        } catch (error: RuntimeException) {
            if (binding.authority == owner) {
                if (previous == null) store(context).delete() else write(context, previous)
            }
            throw error
        }
        binding.markReady(owner, true)
        Log.i("FluviBalanceOrb", "stage=material-ready id=${owner.id} frames=${packet.plan.frameCount}")
        return true
    }

    fun revoke(context: Context, widgetId: Int) {
        preparation = null
        store(context).delete()
        if (widgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
            AppWidgetManager.getInstance(context).updateAppWidget(widgetId, empty(context))
        }
    }

    fun refresh(context: Context, binding: HeaderOrbBinding) {
        val owner = binding.authority ?: return
        val packet = read(context, owner)
        val views = if (packet != null) playback(context, owner.id, packet) else empty(context)
        if (owner != binding.authority) return
        AppWidgetManager.getInstance(context).updateAppWidget(owner.id, views)
        binding.markReady(owner, packet != null)
    }

    private fun empty(context: Context) = RemoteViews(context.packageName, R.layout.fluvi_header_orb_empty)

    private fun playback(context: Context, id: Int, packet: HeaderOrbPackage): RemoteViews {
        val manager = AppWidgetManager.getInstance(context)
        val size = OrbWidgetDisplayDimensions.shortSidePx(context, manager.getAppWidgetOptions(id))
        val frames = packet.decode()
        return orbPlaybackViews(context, packet.plan, frames, size).also { views ->
            val parcel = Parcel.obtain()
            try {
                views.writeToParcel(parcel, 0)
                val wireBytes = parcel.dataSize()
                val rawBytes = packet.plan.estimatedRawBytes
                if (wireBytes + rawBytes > MAX_DELIVERY_BYTES) {
                    Log.w("FluviBalanceOrb", "stage=material-envelope-rejected parcel=$wireBytes decoded=$rawBytes")
                    throw IllegalArgumentException("AppWidget payload exceeds its envelope")
                }
            } finally {
                parcel.recycle()
            }
        }
    }

    private fun store(context: Context) = AtomicFile(File(context.noBackupFilesDir, "balance-orb-frames-v2"))

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

    private fun read(context: Context, owner: HeaderOrbBinding.Authority): HeaderOrbPackage? = runCatching {
        store(context).openRead().use { input ->
            require(input.channel.size() <= MAX_PACKAGE_BYTES)
            HeaderOrbPackage.read(input.readBytes()).takeIf { it.epoch == owner.epoch }
        }
    }.getOrNull()

    private const val MAX_DELIVERY_BYTES = 960 * 1024L
}

private const val PACKAGE_VERSION = 2
private const val DIGEST_BYTES = 32
private const val MAX_PACKAGE_BYTES = OrbMaterialPlaybackContract.maximumEncodedBytes + 4096L
private fun digest(bytes: ByteArray) = MessageDigest.getInstance("SHA-256").digest(bytes)

internal data class HeaderOrbPackage(
    val key: String,
    val epoch: String,
    val generation: String,
    val plan: OrbFramePlan,
    val animated: Boolean,
    val pngs: List<ByteArray>,
) {
    init {
        require(key.matches(Regex("[a-f0-9]{64}")))
        require(UUID.fromString(epoch).toString() == epoch)
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
            out.writeUTF(epoch)
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
                val epoch = input.readUTF()
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
                HeaderOrbPackage(key, epoch, generation, OrbFramePlan(size, count, interval, phaseOriginUtcMs = origin), motion, pngs)
            }
        }
    }
}
