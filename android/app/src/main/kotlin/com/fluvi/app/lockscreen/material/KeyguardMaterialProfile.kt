package com.fluvi.app.lockscreen.material

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.atomic.AtomicLong

/**
 * Versioned, durable copy of the Header's visual input.  It contains no
 * transaction, category label, amount or accessibility data.  Flutter is the
 * authority for this profile; native code only validates and renders it after
 * the Activity has gone away.
 */
internal data class KeyguardMaterialProfile(
    val schemaVersion: Int,
    val shaderAbiVersion: Int,
    val sourceShaderHash: String,
    val publisherSession: String,
    val publisherRevision: Long,
    val sceneIdentity: String,
    val effectId: String,
    val effectShaderId: Int,
    val phase: Float,
    val elapsedSeconds: Float,
    val phaseSpeed: Float,
    val colors: IntArray,
    val stops: FloatArray,
    val opacity: Float,
    val paletteSplitPercent: Float,
    val commonSettings: FloatArray,
    val background: KeyguardMaterialPortal,
    val interior: KeyguardMaterialPortal,
    val referenceWidth: Float,
    val referenceHeight: Float,
) {
    val animated: Boolean
        get() = effectId != "staticEffect" && phaseSpeed > 0f || background.hasMotion || interior.hasMotion

    /** The visual identity excludes the handoff clock so an identical scene
     * from a restarted Flutter publisher never restarts the native clock. */
    val visualKey: String = listOf(
        shaderAbiVersion, sourceShaderHash, sceneIdentity, effectId, effectShaderId, phaseSpeed,
        colors.contentHashCode(), stops.contentHashCode(), opacity,
        paletteSplitPercent, commonSettings.contentHashCode(), background.visualKey,
        interior.visualKey, referenceWidth, referenceHeight,
    ).joinToString("|")

    fun neutralized(): KeyguardMaterialProfile = copy(
        colors = intArrayOf(0xff657489.toInt(), 0xff8592a4.toInt(), 0xff657489.toInt()),
        stops = floatArrayOf(0f, .5f, 1f),
        opacity = 1f,
    )

    fun toJson(): JSONObject = JSONObject().apply {
        put("schemaVersion", schemaVersion)
        put("shaderAbiVersion", shaderAbiVersion)
        put("sourceShaderHash", sourceShaderHash)
        put("publisherSession", publisherSession)
        put("publisherRevision", publisherRevision)
        put("sceneIdentity", sceneIdentity)
        put("effectId", effectId)
        put("effectShaderId", effectShaderId)
        put("phase", phase.toDouble())
        put("elapsedSeconds", elapsedSeconds.toDouble())
        put("phaseSpeed", phaseSpeed.toDouble())
        put("colors", JSONArray(colors.toList()))
        put("stops", JSONArray(stops.toList()))
        put("opacity", opacity.toDouble())
        put("paletteSplitPercent", paletteSplitPercent.toDouble())
        put("commonSettings", JSONArray(commonSettings.toList()))
        put("background", background.toJson())
        put("interior", interior.toJson())
        put("referenceWidth", referenceWidth.toDouble())
        put("referenceHeight", referenceHeight.toDouble())
    }

    companion object {
        const val SCHEMA_VERSION = 1
        const val SHADER_ABI_VERSION = 6
        // SHA-256 of shaders/dashboard_header_field.frag. The Gradle adapter
        // emits the same value into the packaged asset; changing the source
        // requires deliberately updating this transport contract too.
        const val SOURCE_SHADER_HASH = "6be3e84d3e3ae6bffde549171b7319524768d67dbab1d55b74d565a4c76d4e7f"
        /** Stable IDs copied from DashboardHeaderEffectCatalog.shaderId, not
         * derived at runtime from enum order. */
        private val effectShaderIds = mapOf(
            "staticEffect" to 0, "dualTide" to 1, "magneticMembrane" to 2,
            "breathingLens" to 3, "cellularField" to 4, "balanceMembrane" to 5,
            "balanceCounterflow" to 6, "balanceCharges" to 7, "deepDrift" to 8,
            "freeFlow" to 9, "chaoticAdvection" to 10, "elasticSpace" to 11,
            "braidedCurrent" to 12, "volumetricCurrent" to 13, "metricBloom" to 14,
            "gravitationalFabric" to 15, "breathingMetric" to 16, "tidalCurvature" to 17,
        )

        sealed interface DecodeResult {
            data class Accepted(val profile: KeyguardMaterialProfile) : DecodeResult
            data class Rejected(val reason: String) : DecodeResult
            data class Unavailable(val reason: String) : DecodeResult
        }

        fun decode(values: Map<*, *>): DecodeResult {
            return try {
            fun finite(name: String): Float = ((values[name] as? Number)?.toFloat()
                ?: throw IllegalArgumentException("missing:$name")).also {
                require(it.isFinite()) { "nonFinite:$name" }
            }
            fun text(name: String, maxLength: Int): String = (values[name] as? String)
                ?.takeIf { it.isNotBlank() && it.length <= maxLength }
                ?: throw IllegalArgumentException("invalid:$name")
            fun floats(name: String, size: Int): FloatArray {
                val raw = values[name] as? List<*> ?: throw IllegalArgumentException("missing:$name")
                require(raw.size == size) { "size:$name" }
                return FloatArray(size) { index ->
                    (raw[index] as? Number)?.toFloat()?.also { require(it.isFinite()) { "nonFinite:$name" } }
                        ?: throw IllegalArgumentException("invalid:$name")
                }
            }
            fun colors(): IntArray {
                val raw = values["colors"] as? List<*> ?: throw IllegalArgumentException("missing:colors")
                require(raw.size in 2..10) { "size:colors" }
                return IntArray(raw.size) { index ->
                    (raw[index] as? Number)?.toInt() ?: throw IllegalArgumentException("invalid:colors")
                }
            }
            val schema = (values["schemaVersion"] as? Number)?.toInt() ?: throw IllegalArgumentException("missing:schema")
            val abi = (values["shaderAbiVersion"] as? Number)?.toInt() ?: throw IllegalArgumentException("missing:abi")
            require(schema == SCHEMA_VERSION) { "schema" }
            require(abi == SHADER_ABI_VERSION) { "abi" }
            val sourceHash = text("sourceShaderHash", 64)
            require(sourceHash == SOURCE_SHADER_HASH) { "sourceHash" }
            val effect = text("effectId", 64)
            val effectShaderId = (values["effectShaderId"] as? Number)?.toInt()
                ?: throw IllegalArgumentException("missing:effectShaderId")
            require(effectShaderIds[effect] == effectShaderId) { "effectMapping" }
            val stops = floats("stops", (values["stops"] as? List<*>)?.size ?: 0)
            val colors = colors()
            require(stops.size == colors.size) { "stops" }
            require(stops.indices.all { index ->
                stops[index] in 0f..1f && (index == 0 || stops[index] >= stops[index - 1])
            }) { "stopRange" }
            val background = KeyguardMaterialPortal.decode(values["background"] as? Map<*, *>)
            val interior = KeyguardMaterialPortal.decode(values["interior"] as? Map<*, *>)
            if (background is KeyguardMaterialPortal.Companion.DecodeResult.Rejected) return DecodeResult.Rejected("background:${background.reason}")
            if (interior is KeyguardMaterialPortal.Companion.DecodeResult.Rejected) return DecodeResult.Rejected("interior:${interior.reason}")
            val bg = (background as KeyguardMaterialPortal.Companion.DecodeResult.Accepted).portal
            val inside = (interior as KeyguardMaterialPortal.Companion.DecodeResult.Accepted).portal
            val profile = KeyguardMaterialProfile(
                schemaVersion = schema,
                shaderAbiVersion = abi,
                sourceShaderHash = sourceHash,
                publisherSession = text("publisherSession", 96),
                publisherRevision = (values["publisherRevision"] as? Number)?.toLong()?.also { require(it >= 0L) { "revision" } }
                    ?: throw IllegalArgumentException("missing:revision"),
                sceneIdentity = text("sceneIdentity", 256),
                effectId = effect,
                effectShaderId = effectShaderId,
                phase = finite("phase"),
                elapsedSeconds = finite("elapsedSeconds").also { require(it >= 0f) { "elapsed" } },
                phaseSpeed = finite("phaseSpeed").also { require(it >= 0f) { "speed" } },
                colors = colors,
                stops = stops,
                opacity = finite("opacity").also { require(it in 0f..1f) { "opacity" } },
                paletteSplitPercent = finite("paletteSplitPercent").also { require(it in 0f..100f) { "split" } },
                commonSettings = floats("commonSettings", 40),
                background = bg,
                interior = inside,
                referenceWidth = finite("referenceWidth").also { require(it > 0f && it <= 10000f) { "width" } },
                referenceHeight = finite("referenceHeight").also { require(it > 0f && it <= 10000f) { "height" } },
            )
            DecodeResult.Accepted(profile)
            } catch (error: IllegalArgumentException) {
                DecodeResult.Rejected(error.message?.take(96) ?: "invalid")
            } catch (error: Throwable) {
                DecodeResult.Unavailable(error.javaClass.simpleName)
            }
        }

        fun fromMap(values: Map<*, *>): KeyguardMaterialProfile? =
            (decode(values) as? DecodeResult.Accepted)?.profile

        fun fromJson(raw: String): KeyguardMaterialProfile? = runCatching {
            val value = JSONObject(raw)
            fromMap(value.toMap())
        }.getOrNull()

        private fun JSONObject.toMap(): Map<String, Any?> = keys().asSequence().associateWith { key ->
            when (val value = opt(key)) {
                is JSONObject -> value.toMap()
                is JSONArray -> List(value.length()) { index -> value.opt(index) }
                JSONObject.NULL -> null
                else -> value
            }
        }

    }
}

internal data class KeyguardMaterialPortal(
    val enabled: Boolean,
    val effectIndex: Int,
    val phase: Float,
    val phaseSpeed: Float,
    val paletteCenterPercent: Float,
    val paletteWindowPercent: Float,
    val rotationEnabled: Boolean,
    val rotationSpeed: Float,
    val settings: FloatArray,
) {
    val hasMotion get() = enabled && phaseSpeed > 0f
    val visualKey: String = listOf(enabled, effectIndex, paletteCenterPercent, paletteWindowPercent, rotationEnabled, rotationSpeed, settings.contentHashCode()).joinToString("|")

    fun toJson(): JSONObject = JSONObject().apply {
        put("enabled", enabled)
        put("effectIndex", effectIndex)
        put("phase", phase.toDouble())
        put("phaseSpeed", phaseSpeed.toDouble())
        put("paletteCenterPercent", paletteCenterPercent.toDouble())
        put("paletteWindowPercent", paletteWindowPercent.toDouble())
        put("rotationEnabled", rotationEnabled)
        put("rotationSpeed", rotationSpeed.toDouble())
        put("settings", JSONArray(settings.toList()))
    }

    companion object {
        sealed interface DecodeResult {
            data class Accepted(val portal: KeyguardMaterialPortal) : DecodeResult
            data class Rejected(val reason: String) : DecodeResult
        }

        fun decode(values: Map<*, *>?): DecodeResult = try {
            requireNotNull(values) { "missing" }
            fun finite(key: String): Float = ((values[key] as? Number)?.toFloat()
                ?: throw IllegalArgumentException("missing:$key")).also { require(it.isFinite()) { "nonFinite:$key" } }
            val rawSettings = values["settings"] as? List<*> ?: throw IllegalArgumentException("missing:settings")
            require(rawSettings.size == 12) { "size:settings" }
            val settings = FloatArray(12) { index ->
                (rawSettings[index] as? Number)?.toFloat()?.also { require(it.isFinite()) { "nonFinite:settings" } }
                    ?: throw IllegalArgumentException("invalid:settings")
            }
            val effect = (values["effectIndex"] as? Number)?.toInt()
                ?: throw IllegalArgumentException("missing:effect")
            require(effect in 0..4) { "effect" }
            DecodeResult.Accepted(
                KeyguardMaterialPortal(
                    enabled = values["enabled"] as? Boolean ?: throw IllegalArgumentException("missing:enabled"),
                    effectIndex = effect,
                    phase = finite("phase"),
                    phaseSpeed = finite("phaseSpeed").also { require(it >= 0f) { "phaseSpeed" } },
                    paletteCenterPercent = finite("paletteCenterPercent").also { require(it in 0f..100f) { "center" } },
                    paletteWindowPercent = finite("paletteWindowPercent").also { require(it in 10f..100f) { "window" } },
                    rotationEnabled = values["rotationEnabled"] as? Boolean ?: throw IllegalArgumentException("missing:rotationEnabled"),
                    rotationSpeed = finite("rotationSpeed").also { require(it in 0f..100f) { "rotationSpeed" } },
                    settings = settings,
                ),
            )
        } catch (error: IllegalArgumentException) {
            DecodeResult.Rejected(error.message?.take(96) ?: "invalid")
        }

        fun fromMap(values: Map<*, *>): KeyguardMaterialPortal =
            (decode(values) as? DecodeResult.Accepted)?.portal
                ?: KeyguardMaterialPortal(false, 0, 0f, 0f, 50f, 68f, false, 0f, FloatArray(12))
    }
}

/** Ordering is intentionally independent of Flutter's per-engine revision:
 * every new MethodChannel session starts its Dart counter again at one. */
internal object KeyguardMaterialPublicationOrder {
    fun accepts(
        storedEpoch: Long,
        storedSession: String?,
        storedRevision: Long,
        incomingEpoch: Long,
        incomingSession: String,
        incomingRevision: Long,
    ): Boolean = incomingEpoch > storedEpoch ||
        (incomingEpoch == storedEpoch &&
            (storedSession != incomingSession || incomingRevision > storedRevision))
}

/** Native durability and publication ordering for the rendering profile. */
internal object FluviKeyguardMaterialStore {
    private const val PREFS = "fluvi_keyguard_header_material"
    private const val PROFILE = "profile"
    private const val SESSION = "publisherSession"
    private const val REVISION = "publisherRevision"
    private const val PUBLISHER_EPOCH = "publisherEpoch"
    private const val PROFILE_STATUS = "profileStatus"

    fun read(context: Context): KeyguardMaterialProfile? = prefs(context).getString(PROFILE, null)
        ?.let(KeyguardMaterialProfile::fromJson)

    fun status(context: Context): String = prefs(context).getString(PROFILE_STATUS, "unavailable") ?: "unavailable"

    fun publish(context: Context, values: Map<*, *>, publisherEpoch: Long): Boolean {
        val decoded = KeyguardMaterialProfile.decode(values)
        val unredacted = (decoded as? KeyguardMaterialProfile.Companion.DecodeResult.Accepted)?.profile
        if (unredacted == null) {
            prefs(context).edit().putString(PROFILE_STATUS, when (decoded) {
                is KeyguardMaterialProfile.Companion.DecodeResult.Rejected -> "rejected:${decoded.reason}"
                is KeyguardMaterialProfile.Companion.DecodeResult.Unavailable -> "unavailable:${decoded.reason}"
                else -> "unavailable"
            }).apply()
            return false
        }
        val candidate = if (com.fluvi.app.lockscreen.FluviKeyguardCardSettings
                .read(context).showFinancialDetails
        ) unredacted else unredacted.neutralized()
        val prefs = prefs(context)
        val oldSession = prefs.getString(SESSION, null)
        val oldRevision = prefs.getLong(REVISION, -1L)
        val oldEpoch = prefs.getLong(PUBLISHER_EPOCH, -1L)
        // A Flutter bridge starts its local revision at one after Activity
        // recreation. The native connection epoch orders those sessions, so
        // a late call from a detached engine cannot overwrite a newer scene.
        if (!KeyguardMaterialPublicationOrder.accepts(
                storedEpoch = oldEpoch,
                storedSession = oldSession,
                storedRevision = oldRevision,
                incomingEpoch = publisherEpoch,
                incomingSession = candidate.publisherSession,
                incomingRevision = candidate.publisherRevision,
            )
        ) return false
        prefs.edit()
            .putString(PROFILE, candidate.toJson().toString())
            .putString(SESSION, candidate.publisherSession)
            .putLong(REVISION, candidate.publisherRevision)
            .putLong(PUBLISHER_EPOCH, publisherEpoch)
            .putString(PROFILE_STATUS, "accepted")
            .apply()
        com.fluvi.app.lockscreen.FluviKeyguardCardServiceRegistry.notifyMaterialChanged(candidate)
        return true
    }

    /** A privacy tightening scrubs the durable presentation input as well as
     * the retained View. A late Full profile may never become a future scene
     * just because it survived in SharedPreferences. */
    fun redact(context: Context) {
        val current = read(context) ?: return
        val neutral = current.neutralized()
        if (neutral.colors.contentEquals(current.colors) && neutral.opacity == current.opacity) return
        prefs(context).edit().putString(PROFILE, neutral.toJson().toString()).apply()
        com.fluvi.app.lockscreen.FluviKeyguardCardServiceRegistry.notifyMaterialChanged(neutral)
    }

    private fun prefs(context: Context) = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}

/**
 * Narrow Activity-to-Dart wake-up path for semantic focus/privacy changes.
 * It has no frame API: one callback asks Flutter to publish one replacement
 * scene, and is cleared with the Activity's channel.
 */
internal object FluviKeyguardMaterialBridgeRegistry {
    private val mainHandler = Handler(Looper.getMainLooper())
    @Volatile private var channel: MethodChannel? = null
    private val publisherEpoch = AtomicLong(0L)

    fun connect(value: MethodChannel): Long {
        channel = value
        return publisherEpoch.incrementAndGet()
    }

    fun disconnect(value: MethodChannel?) {
        if (channel === value) channel = null
    }

    fun requestSceneRefresh() {
        mainHandler.post { channel?.invokeMethod("refreshScene", null) }
    }
}
