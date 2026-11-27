package com.fluvi.app.lockscreen.material

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import com.fluvi.app.lockscreen.FluviKeyguardCardSettings
import java.util.UUID
import kotlin.math.abs

/**
 * The last frame that the foreground dashboard actually committed.  Header
 * colours can encode private data, so this store has no public-material API.
 * It is bounded to one in-memory scene and is lost on process death.
 * A retained scene is an input to a later admission check, never an admission.
 */
internal object FluviActiveHeaderMaterialStore {
    internal class Snapshot private constructor(
        val profile: KeyguardMaterialProfile,
        val settingsGeneration: Long,
        val activeMode: String,
        val modeEpoch: Long,
        val motionEnabled: Boolean,
        val publisherInstance: Long,
        val correlation: String,
        val receivedAtNanos: Long,
    ) {
        @Volatile internal var preparedFrames: PreparedFrames? = null
        @Volatile internal var frameStatus: String = "pending"

        companion object {
            internal fun create(profile: KeyguardMaterialProfile, settingsGeneration: Long,
                                activeMode: String, modeEpoch: Long, motionEnabled: Boolean,
                                publisherInstance: Long = 0): Snapshot = Snapshot(
                profile.copy(
                    colors = profile.colors.clone(), stops = profile.stops.clone(),
                    commonSettings = profile.commonSettings.clone(),
                    background = profile.background.copy(settings = profile.background.settings.clone()),
                    interior = profile.interior.copy(settings = profile.interior.settings.clone()),
                ), settingsGeneration, activeMode, modeEpoch, motionEnabled, publisherInstance,
                UUID.randomUUID().toString(), System.nanoTime(),
            )
        }
    }

    internal data class PreparedFrames(
        val bitmaps: List<Bitmap>, val intervalMs: Int, val animated: Boolean,
        val originNanos: Long, val token: String,
    )
    internal data class FrameRequest(
        val owner: Snapshot, val encoded: List<ByteArray>, val sizePx: Int,
        val intervalMs: Int, val animated: Boolean,
    )
    internal data class FrameAdmission(val request: FrameRequest?, val reason: String)
    internal data class Receipt(val accepted: Boolean, val reason: String, val token: String? = null)

    @Volatile private var current: Snapshot? = null
    private val order = KeyguardR47SourceOrder()

    @Synchronized
    fun bindPublisher(epoch: Long, instance: Long, session: String): Boolean {
        val alreadyBound = order.owns(epoch, instance, session)
        if (!order.bind(epoch, instance, session)) return false
        if (!alreadyBound) current = null
        return true
    }

    @Synchronized
    fun invalidatePublisher(epoch: Long, instance: Long, session: String, revision: Long): Boolean {
        if (!order.invalidate(epoch, instance, session, revision)) return false
        if ((current?.profile?.publisherRevision ?: -1L) < revision) current = null
        return true
    }

    /** Called only on the Activity channel; a background/locked callback is
     * rejected before it can replace the last committed foreground frame. */
    @Synchronized
    fun publish(context: Context, values: Map<*, *>, epoch: Long,
                foregroundAndUnlocked: Boolean): Receipt {
        if (!foregroundAndUnlocked || epoch <= 0) return Receipt(false, "foregroundUnavailable")
        val settings = FluviKeyguardCardSettings.read(context)
        if (!settings.requested || !settings.showFinancialDetails) return Receipt(false, "disclosureDisabled")
        val profile = (KeyguardMaterialProfile.decode(values) as? KeyguardMaterialProfile.Companion.DecodeResult.Accepted)
            ?.profile ?: return Receipt(false, "invalidProfile")
        val mode = values["activeMode"] as? String ?: return Receipt(false, "missingMode")
        val modeEpoch = (values["modeEpoch"] as? Number)?.toLong() ?: return Receipt(false, "missingModeEpoch")
        val instance = (values["publisherInstance"] as? Number)?.toLong() ?: return Receipt(false, "missingPublisherInstance")
        val motionEnabled = values["motionEnabled"] as? Boolean ?: return Receipt(false, "missingMotionPreference")
        if (mode !in setOf("balance", "budget", "mind") || modeEpoch < 0 ||
            profile.sceneIdentity != "active-header:$mode:$modeEpoch" ||
            values["sourceAnimated"] != (motionEnabled && profile.animated)) return Receipt(false, "sourceMismatch")
        if (!order.accept(epoch, instance, profile.publisherSession, profile.publisherRevision)) return Receipt(false, "stalePublisher")
        val snapshot = Snapshot.create(profile, settings.generation, mode, modeEpoch, motionEnabled, instance)
        current = snapshot
        return Receipt(true, "accepted", snapshot.correlation)
    }

    /** Validate identity and byte bounds before any PNG decoding. The exact
     * immutable owner is retained so completion cannot install into a newer
     * mode, Activity publisher, privacy revision or attachment generation. */
    @Synchronized
    fun admitFrames(context: Context, values: Map<*, *>, epoch: Long): FrameAdmission {
        val snapshot = applicable(context) ?: return FrameAdmission(null, "sourceUnavailable")
        val token = values["token"] as? String ?: return FrameAdmission(null, "missingToken")
        val session = values["publisherSession"] as? String ?: return FrameAdmission(null, "missingSession")
        val instance = (values["publisherInstance"] as? Number)?.toLong()
            ?: return FrameAdmission(null, "missingInstance")
        val revision = (values["publisherRevision"] as? Number)?.toLong()
            ?: return FrameAdmission(null, "missingRevision")
        if (token != snapshot.correlation || session != snapshot.profile.publisherSession ||
            revision != snapshot.profile.publisherRevision || instance != snapshot.publisherInstance ||
            !order.owns(epoch, instance, session)) return FrameAdmission(null, "staleSource")
        val animated = values["animated"] as? Boolean ?: return FrameAdmission(null, "missingMotion")
        if (animated != (snapshot.motionEnabled && snapshot.profile.animated))
            return FrameAdmission(null, "motionMismatch")
        if (values["loopStatus"] != (if (animated) "accepted" else "static"))
            return FrameAdmission(null, "unverifiedLoop")
        val interval = (values["intervalMs"] as? Number)?.toInt()
            ?: return FrameAdmission(null, "missingInterval")
        val size = (values["frameSizePx"] as? Number)?.toInt()
            ?: return FrameAdmission(null, "missingSize")
        val raw = values["frames"] as? List<*> ?: return FrameAdmission(null, "missingFrames")
        if (raw.size !in 1..KeyguardR47FrameContract.maxFrames)
            return FrameAdmission(null, "invalidGeometry")
        if (raw.any { it !is ByteArray }) return FrameAdmission(null, "invalidFrame")
        val encoded = raw.filterIsInstance<ByteArray>()
        val bytes = encoded.sumOf { it.size.toLong() }
        val error = KeyguardR47FrameContract.validate(animated, encoded.size, size, interval, bytes)
        if (error != null || encoded.any { it.isEmpty() }) return FrameAdmission(null, error ?: "invalidFrame")
        return FrameAdmission(FrameRequest(snapshot, encoded.map { it.clone() }, size, interval, animated), "accepted")
    }

    /** Decode only the already bounded payload, on a background dispatcher. */
    fun decodeFrames(request: FrameRequest): List<Bitmap>? {
        val decoded = ArrayList<Bitmap>(request.encoded.size)
        return try {
            var allocated = 0L
            for (bytes in request.encoded) {
                val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
                require(bounds.outMimeType == "image/png" && bounds.outWidth == request.sizePx && bounds.outHeight == request.sizePx)
                val options = BitmapFactory.Options().apply { inPreferredConfig = Bitmap.Config.ARGB_8888 }
                val image = requireNotNull(BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options))
                decoded.add(image)
                require(image.width == request.sizePx && image.height == request.sizePx)
                allocated += image.allocationByteCount.toLong()
                require(allocated <= KeyguardR47FrameContract.maxDecodedBytes)
            }
            require(!request.animated || hasInteriorMotion(decoded, request.sizePx))
            decoded.toList()
        } catch (_: Exception) {
            decoded.forEach { it.recycle() }
            null
        } catch (_: OutOfMemoryError) {
            decoded.forEach { it.recycle() }
            null
        }
    }

    /** A bad encoder/transport cannot promote identical animated frames.
     * Only pixels inside the Orb count; transparent edges and wallpaper do not. */
    private fun hasInteriorMotion(frames: List<Bitmap>, size: Int): Boolean {
        if (frames.size < 3) return false
        val first = IntArray(size * size)
        val next = IntArray(size * size)
        frames.first().getPixels(first, 0, size, 0, 0, size, size)
        for (frame in frames.drop(1)) {
            frame.getPixels(next, 0, size, 0, 0, size, size)
            var changed = 0
            for (y in 0 until size) for (x in 0 until size) {
                val dx = x + .5 - size / 2.0
                val dy = y + .5 - size / 2.0
                if (dx * dx + dy * dy >= size * size * .1764) continue
                val a = first[y * size + x]; val b = next[y * size + x]
                if ((a ushr 24) == 0 || (b ushr 24) == 0) continue
                if (abs(((a ushr 16) and 255) - ((b ushr 16) and 255)) >= 3 ||
                    abs(((a ushr 8) and 255) - ((b ushr 8) and 255)) >= 3 ||
                    abs((a and 255) - (b and 255)) >= 3) changed++
                if (changed >= 64) return true
            }
        }
        return false
    }

    @Synchronized
    fun commitFrames(context: Context, request: FrameRequest, frames: List<Bitmap>): Boolean {
        if (applicable(context) !== request.owner || current !== request.owner || frames.size != request.encoded.size) {
            frames.forEach { it.recycle() }
            return false
        }
        request.owner.preparedFrames = PreparedFrames(frames.toList(), request.intervalMs,
            request.animated, request.owner.receivedAtNanos, request.owner.correlation)
        request.owner.frameStatus = "ready"
        return true
    }

    @Synchronized
    fun noteFrameStatus(context: Context, token: String, status: String): Boolean {
        val owner = applicable(context) ?: return false
        if (owner.correlation != token || status !in setOf("stale", "invalidFrame", "byteBudgetExceeded",
                "animatedButStationary", "unverifiedLoop", "rendererUnavailable", "nativeRejected")) return false
        owner.frameStatus = status
        return true
    }

    /** Returns only the exact still-current generation. No settings value or
     * public-sample result on its own grants permission to present it. */
    fun applicable(context: Context): Snapshot? {
        val candidate = current ?: return null
        val settings = FluviKeyguardCardSettings.read(context)
        return candidate.takeIf { current === it && settings.requested && settings.showFinancialDetails &&
            settings.generation == it.settingsGeneration }
    }

    fun unavailableReason(context: Context): String {
        val settings = FluviKeyguardCardSettings.read(context)
        if (!settings.requested) return "orbDisabled"
        if (!settings.showFinancialDetails) return "disclosureDisabled"
        val candidate = current ?: return "activeHeaderNotPublished"
        if (candidate.settingsGeneration != settings.generation) return "settingsGenerationChanged"
        return "activeHeaderChanged"
    }

    fun isCurrent(context: Context, snapshot: Snapshot): Boolean = applicable(context) === snapshot

    /** Cheap per-owner check; settings changes invalidate the reference first. */
    fun isCurrentReference(snapshot: Snapshot): Boolean = current === snapshot

    @Synchronized
    fun invalidate() { current = null }
}
