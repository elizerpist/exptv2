package com.fluvi.app.lockscreen.material

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import kotlin.math.max

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
        shaderAbiVersion, sourceShaderHash, sceneIdentity, effectId, effectShaderId,
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
        private const val MAX_VALUES = 40

        fun fromMap(values: Map<*, *>): KeyguardMaterialProfile? = runCatching {
            val schema = values.int("schemaVersion")
            val abi = values.int("shaderAbiVersion")
            val sourceHash = values["sourceShaderHash"] as? String ?: return null
            val session = values["publisherSession"] as? String ?: return null
            val revision = values.long("publisherRevision")
            val sceneIdentity = values["sceneIdentity"] as? String ?: return null
            val effect = values["effectId"] as? String ?: return null
            val colors = values.intArray("colors", 2, 10)
            val stops = values.floatArray("stops", 2, 10)
            val common = values.floatArray("commonSettings", 40, 40)
            val background = KeyguardMaterialPortal.fromMap(values["background"] as? Map<*, *> ?: emptyMap())
            val interior = KeyguardMaterialPortal.fromMap(values["interior"] as? Map<*, *> ?: emptyMap())
            KeyguardMaterialProfile(
                schemaVersion = schema,
                shaderAbiVersion = abi,
                sourceShaderHash = sourceHash,
                publisherSession = session.take(96),
                publisherRevision = max(0L, revision),
                sceneIdentity = sceneIdentity.take(256),
                effectId = effect.take(64),
                effectShaderId = values.int("effectShaderId"),
                phase = values.float("phase"),
                elapsedSeconds = values.float("elapsedSeconds").coerceAtLeast(0f),
                phaseSpeed = values.float("phaseSpeed").coerceAtLeast(0f),
                colors = colors,
                stops = stops,
                opacity = values.float("opacity").coerceIn(0f, 1f),
                paletteSplitPercent = values.float("paletteSplitPercent").coerceIn(0f, 100f),
                commonSettings = common,
                background = background,
                interior = interior,
                referenceWidth = values.float("referenceWidth").coerceAtLeast(1f),
                referenceHeight = values.float("referenceHeight").coerceAtLeast(1f),
            ).takeIf {
                it.schemaVersion == SCHEMA_VERSION &&
                    it.shaderAbiVersion == SHADER_ABI_VERSION &&
                    it.sourceShaderHash == SOURCE_SHADER_HASH &&
                    it.colors.size == it.stops.size
            }
        }.getOrNull()

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

        private fun Map<*, *>.int(key: String): Int = (this[key] as? Number)?.toInt() ?: 0
        private fun Map<*, *>.long(key: String): Long = (this[key] as? Number)?.toLong() ?: 0L
        private fun Map<*, *>.float(key: String): Float = ((this[key] as? Number)?.toFloat() ?: 0f).takeIf { it.isFinite() } ?: 0f
        private fun Map<*, *>.intArray(key: String, min: Int, max: Int): IntArray {
            val raw = this[key] as? List<*> ?: return IntArray(0)
            if (raw.size !in min..max) return IntArray(0)
            return IntArray(raw.size) { index -> (raw[index] as? Number)?.toInt() ?: 0 }
        }
        private fun Map<*, *>.floatArray(key: String, min: Int, max: Int): FloatArray {
            val raw = this[key] as? List<*> ?: return FloatArray(0)
            if (raw.size !in min..max || raw.size > MAX_VALUES) return FloatArray(0)
            return FloatArray(raw.size) { index -> ((raw[index] as? Number)?.toFloat() ?: 0f).takeIf { it.isFinite() } ?: 0f }
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
        fun fromMap(values: Map<*, *>): KeyguardMaterialPortal = KeyguardMaterialPortal(
            enabled = values["enabled"] as? Boolean ?: false,
            effectIndex = ((values["effectIndex"] as? Number)?.toInt() ?: 0).coerceIn(0, 4),
            phase = number(values, "phase"),
            phaseSpeed = number(values, "phaseSpeed").coerceAtLeast(0f),
            paletteCenterPercent = number(values, "paletteCenterPercent").coerceIn(0f, 100f),
            paletteWindowPercent = number(values, "paletteWindowPercent").coerceIn(10f, 100f),
            rotationEnabled = values["rotationEnabled"] as? Boolean ?: false,
            rotationSpeed = number(values, "rotationSpeed").coerceIn(0f, 100f),
            settings = (values["settings"] as? List<*>)?.take(12)?.let { raw ->
                FloatArray(12) { index -> ((raw.getOrNull(index) as? Number)?.toFloat() ?: 0f).takeIf { it.isFinite() } ?: 0f }
            } ?: FloatArray(12),
        )
        private fun number(values: Map<*, *>, key: String): Float = ((values[key] as? Number)?.toFloat() ?: 0f).takeIf { it.isFinite() } ?: 0f
    }
}

/** Native durability and publication ordering for the rendering profile. */
internal object FluviKeyguardMaterialStore {
    private const val PREFS = "fluvi_keyguard_header_material"
    private const val PROFILE = "profile"
    private const val SESSION = "publisherSession"
    private const val REVISION = "publisherRevision"

    fun read(context: Context): KeyguardMaterialProfile? = prefs(context).getString(PROFILE, null)
        ?.let(KeyguardMaterialProfile::fromJson)

    fun publish(context: Context, values: Map<*, *>): Boolean {
        val unredacted = KeyguardMaterialProfile.fromMap(values) ?: return false
        val candidate = if (com.fluvi.app.lockscreen.FluviKeyguardCardSettings
                .read(context).showFinancialDetails
        ) unredacted else unredacted.neutralized()
        val prefs = prefs(context)
        val oldSession = prefs.getString(SESSION, null)
        val oldRevision = prefs.getLong(REVISION, -1L)
        if (oldSession == candidate.publisherSession && candidate.publisherRevision <= oldRevision) return false
        prefs.edit()
            .putString(PROFILE, candidate.toJson().toString())
            .putString(SESSION, candidate.publisherSession)
            .putLong(REVISION, candidate.publisherRevision)
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

    fun connect(value: MethodChannel) {
        channel = value
    }

    fun disconnect(value: MethodChannel?) {
        if (channel === value) channel = null
    }

    fun requestSceneRefresh() {
        mainHandler.post { channel?.invokeMethod("refreshScene", null) }
    }
}
