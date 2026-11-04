package com.fluvi.app.widget.orb

import android.content.Context
import android.appwidget.AppWidgetManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.os.Build
import java.io.File
import java.util.LinkedHashMap
import kotlin.math.floor
import kotlin.math.sqrt

/**
 * The first AppWidget renderer deliberately has a small, explicit contract:
 * one finite ARGB frame bundle is published through RemoteViews and a
 * ViewFlipper repeats it inside the launcher.  It is not a timer, service or
 * bitmap-IPC animation loop.
 *
 * RemoteViews cannot execute Flutter's FragmentProgram. Its normal source is
 * therefore a pre-rendered [OrbMaterialFrameStore] package produced by the
 * Dashboard material renderer. This class remains only as an interaction-free
 * static fallback until the first source package is available.
 */
internal data class OrbCompatibilityVisualProfile(
    val configurationRevision: Long,
    val mode: FluviOrbConfiguration.Mode,
    val timeAxis: FluviOrbConfiguration.TimeAxis,
    val direction: FluviOrbConfiguration.Direction,
    val ghostFilter: FluviOrbConfiguration.GhostFilter,
    val categoryId: String?,
    val paletteIndex: Int,
    val paletteVariant: Int,
    val palettePositionPercent: Int,
    val paletteWindowWidthPercent: Int,
    val colors: IntArray,
    val stops: FloatArray,
    val visualProfileRevision: Int,
    val rendererContractVersion: Int = 2,
    val effectId: String = "flutter-header-material-v2",
) {
    init {
        require(colors.size >= 2) { "An orb profile needs at least two colour stops." }
        require(colors.size == stops.size) { "Orb colours and stops must match." }
    }

    val cacheKey: String = listOf(
        rendererContractVersion,
        configurationRevision,
        mode.name,
        timeAxis.name,
        direction.name,
        ghostFilter.name,
        categoryId.orEmpty(),
        paletteIndex,
        paletteVariant,
        palettePositionPercent,
        paletteWindowWidthPercent,
        colors.contentHashCode(),
        stops.contentHashCode(),
        visualProfileRevision,
        effectId,
    ).joinToString("|")
}

/**
 * Lifecycle-independent read of the part of the persisted dashboard
 * presentation state that is currently reconstructable outside Flutter.
 *
 * Full header tuning/effect banks are not persisted yet, so this does not
 * pretend to reconstruct Deep Drift, Portal or Flutter FragmentProgram
 * effects. It faithfully follows the durable Balance palette window and
 * carries the selected orb target into the deterministic material seed.
 */
internal object OrbCompatibilityVisualProfileResolver {
    private const val dashboardPreferences = "dashboard_presentation"

    fun resolve(context: Context, configuration: FluviOrbConfiguration): OrbCompatibilityVisualProfile {
        val preferences = context.applicationContext.getSharedPreferences(
            dashboardPreferences,
            Context.MODE_PRIVATE,
        )
        val palette = preferences.getInt("balanceHeaderPalette", 0).coerceIn(0, 9)
        val variant = preferences.getInt("balanceHeaderPaletteVariant", 1).coerceIn(0, 2)
        val position = preferences.getInt("balanceHeaderPalettePositionPercent", 50).coerceIn(0, 100)
        val width = preferences.getInt("balanceHeaderPaletteWindowWidthPercent", 15).coerceIn(10, 100)
        val sampled = OrbBalancePaletteCompatibility.sampleWindow(
            palette = palette,
            variant = variant,
            positionPercent = position,
            widthPercent = width,
        )
        val revision = listOf(palette, variant, position, width, sampled.contentHashCode()).hashCode()
        return OrbCompatibilityVisualProfile(
            configurationRevision = configuration.configurationRevision,
            mode = configuration.mode,
            timeAxis = configuration.timeAxis,
            direction = configuration.direction,
            ghostFilter = configuration.ghostFilter,
            categoryId = configuration.categoryId,
            paletteIndex = palette,
            paletteVariant = variant,
            palettePositionPercent = position,
            paletteWindowWidthPercent = width,
            colors = sampled,
            stops = floatArrayOf(0f, .5f, 1f),
            visualProfileRevision = revision,
        )
    }
}

/**
 * Exact authored Balance anchor colours copied from the dashboard palette
 * catalog. The compatibility sampler is deliberately simple sRGB sampling;
 * Dashboard's perceptual sampler remains authoritative for the Flutter
 * header. Keeping the source anchors here makes palette changes observable in
 * a widget even while the complete effect/profile persistence is introduced.
 */
internal object OrbBalancePaletteCompatibility {
    fun sampleWindow(
        palette: Int,
        variant: Int,
        positionPercent: Int,
        widthPercent: Int,
    ): IntArray {
        val scale = scaleFor(palette, variant)
        val center = positionPercent / 100f
        val halfWindow = widthPercent / 200f
        return intArrayOf(
            sample(scale, (center - halfWindow).coerceIn(0f, 1f)),
            sample(scale, center),
            sample(scale, (center + halfWindow).coerceIn(0f, 1f)),
        )
    }

    private fun sample(colors: IntArray, position: Float): Int {
        if (colors.size == 1) return colors.single()
        val scaled = position.coerceIn(0f, 1f) * (colors.lastIndex)
        val lower = floor(scaled).toInt().coerceIn(0, colors.lastIndex)
        val upper = (lower + 1).coerceAtMost(colors.lastIndex)
        val fraction = scaled - lower
        return blend(colors[lower], colors[upper], fraction)
    }

    private fun blend(left: Int, right: Int, fraction: Float): Int = Color.rgb(
        (Color.red(left) + (Color.red(right) - Color.red(left)) * fraction).toInt(),
        (Color.green(left) + (Color.green(right) - Color.green(left)) * fraction).toInt(),
        (Color.blue(left) + (Color.blue(right) - Color.blue(left)) * fraction).toInt(),
    )

    private fun scaleFor(palette: Int, requestedVariant: Int): IntArray {
        val variant = if (palette >= 8) 0 else requestedVariant
        return scales[palette.coerceIn(0, scales.lastIndex)][variant]
    }

    // palette -> original / saturated / vivid. The last two authored palettes
    // are original-only, exactly like DashboardBalanceHeaderPaletteCatalog.
    private val scales: Array<Array<IntArray>> = arrayOf(
        arrayOf(
            ints("fbf8cc", "fde4cf", "ffcfd2", "f1c0e8", "cfbaf0", "a3c4f3", "90dbf4", "8eecf5", "98f5e1", "b9fbc0"),
            ints("fff99f", "ffcea4", "ffa6ac", "ff89e9", "b382ff", "6eaaff", "5cd6ff", "5bf1ff", "65ffde", "8cff98"),
            ints("ffd81a", "ff9d45", "ff6674", "f044c7", "8a5cff", "3d84f7", "27c0eb", "20dde4", "28ddb4", "58e66b"),
        ),
        arrayOf(
            ints("af99ff", "caadff", "ffc2e2", "ffadc7", "ff99b6"),
            ints("9678ff", "b388ff", "ff9ed6", "ff7fae", "ff6a95"),
            ints("7a52ff", "9f66ff", "ff78cb", "ff4f96", "ff3380"),
        ),
        arrayOf(
            ints("6d28d9", "8b5cf6", "a78bfa", "d8b4fe", "fbcfe8", "f9a8d4", "f472b6", "ec4899", "e23883", "db2777"),
            ints("5b1acf", "7c3ff2", "9568f7", "c99afd", "f8a8d8", "f678bf", "ec409f", "e51e7e", "d81f6e", "c9165f"),
            ints("4a0fbf", "6829e8", "7e3ef5", "b876fb", "f48ace", "f43ea8", "e91a85", "d7006b", "c10058", "ad004b"),
        ),
        arrayOf(
            ints("7c5cff", "9b7bff", "b794ff", "d9a1f3", "f08bd6", "ff7bb7", "ff6ea4", "ff8a7a", "ff9b5f", "ffb36b"),
            ints("6842ff", "8758ff", "a272ff", "ca78ec", "ed5ac6", "ff4ba4", "ff3b8a", "ff6a58", "ff7f36", "ffa74a"),
            ints("5628ff", "7139ff", "924eff", "bb4fe8", "e331b7", "ff228c", "ff0f6e", "ff4b36", "ff6a14", "ff9526"),
        ),
        arrayOf(
            ints("a3c4f3", "af99ff", "b794ff", "cfbaf0", "f1c0e8", "fbf8cc", "fde4cf", "ffcfd2", "ffc2e2", "ffadc7", "ff99b6"),
            ints("6eaaff", "9678ff", "a272ff", "b382ff", "ff89e9", "fff99f", "ffcea4", "ffa6ac", "ff9ed6", "ff7fae", "ff6a95"),
            ints("3d84f7", "7a52ff", "8a5cff", "924eff", "f044c7", "ffd81a", "ff9d45", "ff6674", "ff78cb", "ff4f96", "ff3380"),
        ),
        arrayOf(
            ints("6d28d9", "8b5cf6", "9b7bff", "b794ff", "d9a1f3", "f08bd6", "ff7bb7", "ff6ea4", "f472b6", "ec4899"),
            ints("5b1acf", "7c3ff2", "8758ff", "a272ff", "ca78ec", "ed5ac6", "f678bf", "ff4ba4", "ec409f", "e51e7e"),
            ints("4a0fbf", "6829e8", "7139ff", "924eff", "bb4fe8", "e331b7", "f43ea8", "ff228c", "e91a85", "d7006b"),
        ),
        arrayOf(
            ints("fde4cf", "ffcfd2", "f1c0e8", "cfbaf0", "caadff", "a3c4f3", "90dbf4", "8eecf5", "98f5e1", "b9fbc0"),
            ints("ffcea4", "ffa6ac", "ff89e9", "b382ff", "9678ff", "6eaaff", "5cd6ff", "5bf1ff", "65ffde", "8cff98"),
            ints("ff9d45", "ff6674", "f044c7", "8a5cff", "7a52ff", "3d84f7", "27c0eb", "20dde4", "28ddb4", "58e66b"),
        ),
        arrayOf(
            ints("af99ff", "cfbaf0", "a3c4f3", "90dbf4", "f1c0e8", "ffcfd2", "ffadc7", "fbf8cc", "98f5e1", "b9fbc0"),
            ints("9678ff", "b382ff", "6eaaff", "5cd6ff", "ff89e9", "ff9ed6", "ff7fae", "fff99f", "65ffde", "8cff98"),
            ints("7a52ff", "8a5cff", "3d84f7", "27c0eb", "f044c7", "ff78cb", "ff4f96", "ffd81a", "28ddb4", "58e66b"),
        ),
        arrayOf(
            ints("f4f7fb", "ffeeda", "ffd5af", "ffb15c", "ff8d64", "ff6b6b", "f536bd", "d03cb0", "a237bf", "821ac2"),
            ints("f4f7fb", "ffeeda", "ffd5af", "ffb15c", "ff8d64", "ff6b6b", "f536bd", "d03cb0", "a237bf", "821ac2"),
            ints("f4f7fb", "ffeeda", "ffd5af", "ffb15c", "ff8d64", "ff6b6b", "f536bd", "d03cb0", "a237bf", "821ac2"),
        ),
        arrayOf(
            ints("fff0e4", "ffe0c8", "fec7a6", "fda77f", "f7866c", "f26862", "e95276", "d33f8d", "b433a0", "9227a8"),
            ints("fff0e4", "ffe0c8", "fec7a6", "fda77f", "f7866c", "f26862", "e95276", "d33f8d", "b433a0", "9227a8"),
            ints("fff0e4", "ffe0c8", "fec7a6", "fda77f", "f7866c", "f26862", "e95276", "d33f8d", "b433a0", "9227a8"),
        ),
    )

    private fun ints(vararg colors: String): IntArray =
        colors.map { Color.parseColor("#$it") }.toIntArray()
}

/** v4 removes crossfades and decouples physical diameter from texture size.
 * Keep earlier packages readable so an already-installed widget remains
 * visible until Flutter has successfully committed a complete v4 package. */
internal object OrbMaterialPlaybackContract {
    const val cacheVersion = 4
    const val legacyCacheVersion = 2
    const val minimumFrameCount = 1
    // 175 × 32² × 4 = 716,800 bytes, exactly the 700 KiB decoded cap.
    const val maximumFrameCount = 175
    const val minimumFrameSizePx = 32
    const val maximumFrameSizePx = 128
    const val minimumFlipIntervalMs = 16
    const val maximumFlipIntervalMs = 60_000
    const val maximumEncodedBytes = 2 * 1024 * 1024
    const val maximumDecodedBytes = 700L * 1024L

}

internal data class OrbFramePlan(
    val sizePx: Int,
    val frameCount: Int,
    val intervalMs: Int,
    val transitionDurationMs: Int = 0,
    val displaySizePx: Int = sizePx,
    val cacheVersion: Int = OrbMaterialPlaybackContract.cacheVersion,
) {
    val estimatedRawBytes: Long get() = sizePx.toLong() * sizePx * frameCount * 4L
}

internal data class OrbFrameSequence(
    val profileKey: String,
    val plan: OrbFramePlan,
    val frames: List<Bitmap>,
    /** PNG bytes crossing Flutter's method channel before they are decoded. */
    val encodedBytes: Long = plan.estimatedRawBytes,
    /** Records whether these pixels came from Flutter's Header or fallback. */
    val sourceDescription: String = "native-static-fallback",
)

/**
 * Persists the last known-good Flutter material package per widget.  Android
 * may refresh an AppWidget after Flutter has been closed; it must then replay
 * this exact finite package rather than synthesising a new wave field from a
 * partial palette preference.
 */
internal object OrbMaterialFrameStore {
    private const val preferencesName = "fluvi_orb_material_frames"
    private const val directoryName = "fluvi-orb-material-frames"

    data class Target(
        val widgetId: Int,
        val configurationRevision: Long,
        val mode: String,
        val axis: String,
        val direction: String,
        val categoryId: String?,
        val preferredSizePx: Int,
        val cacheVersion: Int,
        val maximumFrameCount: Int,
        val maximumDecodedBytes: Long,
        val requiresAlphaMask: Boolean,
    )

    fun targets(context: Context): List<Target> {
        val store = FluviOrbConfigurationStore(context)
        val manager = AppWidgetManager.getInstance(context.applicationContext)
        return store.configuredIds().map { widgetId ->
            store.get(widgetId)?.let { configuration ->
                Target(
                    widgetId = widgetId,
                    configurationRevision = configuration.configurationRevision,
                    mode = configuration.mode.name,
                    axis = configuration.timeAxis.name,
                    direction = configuration.direction.name,
                    categoryId = configuration.categoryId,
                    preferredSizePx = framePlanFor(
                        context = context,
                        options = manager.getAppWidgetOptions(widgetId),
                    ).sizePx,
                    cacheVersion = OrbMaterialPlaybackContract.cacheVersion,
                    maximumFrameCount = OrbMaterialPlaybackContract.maximumFrameCount,
                    maximumDecodedBytes = OrbMaterialPlaybackContract.maximumDecodedBytes,
                    // API 31 supplies RemoteViews layout/outline actions. It
                    // is the normal Nothing/API 35 path; older hosts retain
                    // a filtered alpha mask in their source texture.
                    requiresAlphaMask = Build.VERSION.SDK_INT < Build.VERSION_CODES.S,
                )
            }
        }.filterNotNull()
    }

    fun write(
        context: Context,
        widgetId: Int,
        configurationRevision: Long,
        cacheVersion: Int,
        intervalMs: Int,
        transitionDurationMs: Int,
        displaySizePx: Int,
        frames: List<ByteArray>,
        sourceDescription: String,
    ) {
        require(cacheVersion == OrbMaterialPlaybackContract.cacheVersion) {
            "Unexpected orb material cache version $cacheVersion."
        }
        require(frames.size in OrbMaterialPlaybackContract.minimumFrameCount..OrbMaterialPlaybackContract.maximumFrameCount) {
            "An orb material package needs ${OrbMaterialPlaybackContract.minimumFrameCount}..${OrbMaterialPlaybackContract.maximumFrameCount} frames."
        }
        require(frames.sumOf { it.size } <= OrbMaterialPlaybackContract.maximumEncodedBytes) {
            "Orb material package exceeds its bounded transport budget."
        }
        require(intervalMs in OrbMaterialPlaybackContract.minimumFlipIntervalMs..OrbMaterialPlaybackContract.maximumFlipIntervalMs) {
            "Orb material interval is outside its launcher-safe range."
        }
        require(transitionDurationMs == 0) {
            "Orb v4 plays opaque complete frames and does not support crossfades."
        }
        val application = context.applicationContext
        val directory = File(application.filesDir, directoryName).apply { mkdirs() }
        val preferences = application.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        // Never overwrite the active package in place. Flutter can be closed
        // while a new export is incomplete, and the launcher must keep the
        // last good package playable in that case.
        val packageId = "$widgetId-${System.nanoTime()}"
        val staged = frames.mapIndexed { index, bytes ->
            val temporary = File(directory, "$packageId-$index.pending")
            temporary.outputStream().use { it.write(bytes) }
            temporary
        }
        val published = mutableListOf<File>()
        try {
            val decoded = staged.map { file ->
                BitmapFactory.decodeFile(file.absolutePath)
                    ?: throw IllegalArgumentException("Invalid orb material PNG.")
            }
            try {
                require(decoded.all { bitmap ->
                    bitmap.width == bitmap.height &&
                        bitmap.width in OrbMaterialPlaybackContract.minimumFrameSizePx..OrbMaterialPlaybackContract.maximumFrameSizePx
                }) {
                    "Orb frames must be square ${OrbMaterialPlaybackContract.minimumFrameSizePx}..${OrbMaterialPlaybackContract.maximumFrameSizePx}px images."
                }
                require(decoded.map { it.width }.distinct().size == 1) {
                    "Orb material frames must share one square size."
                }
                val decodedBytes = decoded.sumOf { bitmap ->
                    bitmap.width.toLong() * bitmap.height * 4L
                }
                require(decodedBytes <= OrbMaterialPlaybackContract.maximumDecodedBytes) {
                    "Orb material package exceeds its decoded bitmap budget."
                }
            } finally {
                decoded.forEach { it.recycle() }
            }
            staged.forEachIndexed { index, temporary ->
                val target = File(directory, "$packageId-$index.png")
                check(temporary.renameTo(target)) { "Unable to publish orb frame $index." }
                published += target
            }
        } catch (failure: Throwable) {
            staged.forEach(File::delete)
            published.forEach(File::delete)
            throw failure
        }
        val previousPackage = preferences.getString("$widgetId.package", null)
        val committed = preferences.edit()
            .putString("$widgetId.package", packageId)
            .putLong("$widgetId.revision", configurationRevision)
            .putInt("$widgetId.format", cacheVersion)
            .putInt("$widgetId.count", frames.size)
            .putInt("$widgetId.interval", intervalMs)
            .putInt("$widgetId.transition", 0)
            // A package never owns physical display geometry. Keep this key
            // only for v2/v3 preference compatibility; rendering derives the
            // current cell's unmodified short side on every update.
            .putInt("$widgetId.displaySize", displaySizePx)
            .putLong("$widgetId.encodedBytes", frames.sumOf { it.size.toLong() })
            .putString("$widgetId.source", sourceDescription)
            .putLong("$widgetId.renderedAt", System.currentTimeMillis())
            .commit()
        if (!committed) {
            published.forEach(File::delete)
            throw IllegalStateException("Unable to commit orb material package.")
        }
        previousPackage?.let { deletePackage(directory, it) }
    }

    fun sequenceFor(
        context: Context,
        configuration: FluviOrbConfiguration,
    ): OrbFrameSequence? {
        val application = context.applicationContext
        val preferences = application.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        if (preferences.getLong("${configuration.appWidgetId}.revision", -1) != configuration.configurationRevision) {
            return null
        }
        val packageId = preferences.getString("${configuration.appWidgetId}.package", null)
            ?: return null
        val cacheVersion = preferences.getInt(
            "${configuration.appWidgetId}.format",
            OrbMaterialPlaybackContract.legacyCacheVersion,
        )
        if (cacheVersion !in OrbMaterialPlaybackContract.legacyCacheVersion..OrbMaterialPlaybackContract.cacheVersion) {
            return null
        }
        val count = preferences.getInt("${configuration.appWidgetId}.count", 0)
        if (count !in OrbMaterialPlaybackContract.minimumFrameCount..OrbMaterialPlaybackContract.maximumFrameCount) return null
        val directory = File(application.filesDir, directoryName)
        val frames = (0 until count).map { index ->
            BitmapFactory.decodeFile(File(directory, "$packageId-$index.png").absolutePath)
        }
        if (frames.any { it == null }) return null
        val bitmaps = frames.filterNotNull()
        val size = bitmaps.first().width
        if (
            bitmaps.any {
                it.width != size || it.height != size ||
                    it.width !in OrbMaterialPlaybackContract.minimumFrameSizePx..OrbMaterialPlaybackContract.maximumFrameSizePx
            }
        ) return null
        val decodedBytes = bitmaps.sumOf { bitmap -> bitmap.width.toLong() * bitmap.height * 4L }
        if (decodedBytes > OrbMaterialPlaybackContract.maximumDecodedBytes) return null
        val interval = preferences.getInt("${configuration.appWidgetId}.interval", 80)
            .coerceIn(
                OrbMaterialPlaybackContract.minimumFlipIntervalMs,
                OrbMaterialPlaybackContract.maximumFlipIntervalMs,
            )
        return OrbFrameSequence(
            profileKey = "stored|${configuration.appWidgetId}|${configuration.configurationRevision}|$packageId",
            plan = OrbFramePlan(
                sizePx = size,
                frameCount = count,
                intervalMs = interval,
                transitionDurationMs = 0,
                displaySizePx = size,
                cacheVersion = cacheVersion,
            ),
            frames = bitmaps,
            encodedBytes = preferences.getLong(
                "${configuration.appWidgetId}.encodedBytes",
                (0 until count).sumOf { index ->
                    File(directory, "$packageId-$index.png").length()
                },
            ),
            sourceDescription = preferences.getString(
                "${configuration.appWidgetId}.source",
                "flutter-header-material",
            ) ?: "flutter-header-material",
        )
    }

    fun delete(context: Context, ids: IntArray) {
        val application = context.applicationContext
        val directory = File(application.filesDir, directoryName)
        val preferences = application.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        preferences.edit().also { editor ->
            ids.forEach { widgetId ->
                preferences.getString("$widgetId.package", null)?.let {
                    deletePackage(directory, it)
                }
                listOf(
                    "package", "revision", "format", "count", "interval", "transition",
                    "displaySize", "encodedBytes", "source", "renderedAt",
                )
                    .forEach { suffix -> editor.remove("$widgetId.$suffix") }
            }
        }.apply()
    }

    private fun deletePackage(directory: File, packageId: String) {
        directory.listFiles { file ->
            file.name.startsWith("$packageId-") &&
                (file.name.endsWith(".png") || file.name.endsWith(".pending"))
        }?.forEach(File::delete)
    }

    private fun framePlanFor(
        context: Context,
        options: android.os.Bundle,
    ): OrbFramePlan = OrbCompatibilityFrameRenderer.planFor(
        OrbWidgetDisplayDimensions.shortSidePx(context, options),
    )
}

/** AppWidget options are already the host's usable cell dimensions. Never
 * subtract launcher padding again and never clamp this physical diameter to
 * the smaller internal texture budget. */
internal object OrbWidgetDisplayDimensions {
    fun shortSidePx(context: Context, options: android.os.Bundle): Int {
        val widthDp = options.getInt(
            AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH,
            options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 56),
        )
        val heightDp = options.getInt(
            AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT,
            options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 56),
        )
        return (minOf(widthDp, heightDp).coerceAtLeast(1) *
            context.resources.displayMetrics.density).toInt().coerceAtLeast(1)
    }
}

/** Small, non-financial delivery diagnostics. A successful updateAppWidget is
 * deliberately recorded as "published", never as launcher-visible proof. */
internal object OrbFrameRenderDiagnostics {
    private const val preferencesName = "fluvi_orb_renderer_diagnostics"

    fun published(
        context: Context,
        widgetId: Int,
        profile: OrbCompatibilityVisualProfile,
        sequence: OrbFrameSequence,
    ) {
        context.applicationContext.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            .edit()
            .putLong("$widgetId.snapshotResolvedAt", System.currentTimeMillis())
            .putLong("$widgetId.framesRenderedAt", System.currentTimeMillis())
            .putLong("$widgetId.remoteViewsPublishedAt", System.currentTimeMillis())
            .putString("$widgetId.profile", profile.cacheKey.hashCode().toString())
            .putString("$widgetId.backend", sequence.sourceDescription)
            .putInt("$widgetId.frameCount", sequence.plan.frameCount)
            .putInt("$widgetId.frameSizePx", sequence.plan.sizePx)
            .putInt("$widgetId.displaySizePx", sequence.plan.displaySizePx)
            .putInt("$widgetId.cacheVersion", sequence.plan.cacheVersion)
            .putInt("$widgetId.intervalMs", sequence.plan.intervalMs)
            .putInt("$widgetId.transitionDurationMs", sequence.plan.transitionDurationMs)
            .putLong("$widgetId.channelEncodedBytes", sequence.encodedBytes)
            .putLong("$widgetId.estimatedRawBytes", sequence.plan.estimatedRawBytes)
            .putLong("$widgetId.threeWidgetEstimatedRawBytes", sequence.plan.estimatedRawBytes * 3L)
            .remove("$widgetId.lastFailure")
            .apply()
    }

    fun failed(context: Context, widgetId: Int, failure: Throwable) {
        context.applicationContext.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            .edit()
            .putLong("$widgetId.lastFailureAt", System.currentTimeMillis())
            .putString("$widgetId.lastFailure", failure.javaClass.simpleName)
            .apply()
    }
}

internal object OrbCompatibilityFrameRenderer {
    private const val safeRemoteViewsBytes = OrbMaterialPlaybackContract.maximumDecodedBytes
    private const val requestedSizePx = 96
    private const val requestedFrameCount = 1
    private const val frameIntervalMs = 1000
    private const val fallbackSizePx = 80
    private const val fallbackFrameCount = 1
    private const val maxCachedSequences = 3

    val requestedPlan = OrbFramePlan(requestedSizePx, requestedFrameCount, frameIntervalMs)
    val activePlan: OrbFramePlan = planFor(fallbackSizePx)

    private val cache = object : LinkedHashMap<String, OrbFrameSequence>(maxCachedSequences, .75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, OrbFrameSequence>?): Boolean =
            size > maxCachedSequences
    }

    @Synchronized
    fun sequenceFor(
        profile: OrbCompatibilityVisualProfile,
        plan: OrbFramePlan = activePlan,
    ): OrbFrameSequence {
        val cacheKey = "${profile.cacheKey}|${plan.sizePx}|${plan.frameCount}|${plan.intervalMs}"
        cache[cacheKey]?.let { return it }
        val generated = OrbFrameSequence(
            profileKey = cacheKey,
            plan = plan,
            frames = List(plan.frameCount) { index ->
                renderFrame(profile, index.toFloat() / plan.frameCount, plan.sizePx)
            },
        )
        cache[cacheKey] = generated
        return generated
    }

    /**
     * The widget host reports its cell dimensions in dp. We use the actual
     * short side, while reducing the frame count rather than exceeding the
     * bounded raw bitmap transport budget on high-density launchers.
     */
    fun planFor(shortSidePx: Int): OrbFramePlan {
        val size = shortSidePx.coerceIn(64, requestedSizePx)
        val maximumFrames = (safeRemoteViewsBytes / (size.toLong() * size * 4L))
            .toInt()
            .coerceAtLeast(12)
        // This renderer is only the non-animated palette fallback until the
        // Dashboard Header export arrives. A static fallback intentionally
        // owns one frame; normal animation is always the Flutter package.
        val frameCount = minOf(fallbackFrameCount, maximumFrames)
        return OrbFramePlan(size, frameCount, frameIntervalMs)
    }

    internal fun renderFrame(
        profile: OrbCompatibilityVisualProfile,
        time: Float,
        sizePx: Int,
    ): Bitmap {
        val pixels = IntArray(sizePx * sizePx)
        val centre = (sizePx - 1) / 2f
        val radius = sizePx * .478f
        for (y in 0 until sizePx) {
            for (x in 0 until sizePx) {
                val nx = (x - centre) / radius
                val ny = (y - centre) / radius
                val target = y * sizePx + x
                pixels[target] = staticPixelAt(profile, nx, ny)
            }
        }
        return Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888).apply {
            setPixels(pixels, 0, sizePx, 0, 0, sizePx, sizePx)
        }
    }
    private fun staticPixelAt(profile: OrbCompatibilityVisualProfile, nx: Float, ny: Float): Int {
        val distance = sqrt(nx * nx + ny * ny)
        if (distance > 1f) return 0
        // Fallback only: preserve the full palette across the circle with no
        // travelling/curl/radial bands, highlight or edge darkening. The
        // normal path above is the Flutter-rendered Header material package.
        val coordinate = ((nx + 1f) * .5f).coerceIn(0f, 1f)
        val color = colorAt(profile.colors, profile.stops, coordinate)
        val alpha = ((1f - ((distance - .955f) / .045f).coerceIn(0f, 1f)) * 255f).toInt()
        return argb(alpha, red(color), green(color), blue(color))
    }

    private fun colorAt(colors: IntArray, stops: FloatArray, value: Float): Int {
        val position = value.coerceIn(0f, 1f)
        val upper = stops.indexOfFirst { it >= position }.let { if (it < 0) stops.lastIndex else it }
        if (upper == 0) return colors.first()
        val lower = upper - 1
        val span = (stops[upper] - stops[lower]).takeIf { it > 0f } ?: 1f
        val fraction = ((position - stops[lower]) / span).coerceIn(0f, 1f)
        return rgb(
            (red(colors[lower]) + (red(colors[upper]) - red(colors[lower])) * fraction).toInt(),
            (green(colors[lower]) + (green(colors[upper]) - green(colors[lower])) * fraction).toInt(),
            (blue(colors[lower]) + (blue(colors[upper]) - blue(colors[lower])) * fraction).toInt(),
        )
    }

    private fun red(color: Int): Int = (color shr 16) and 0xff
    private fun green(color: Int): Int = (color shr 8) and 0xff
    private fun blue(color: Int): Int = color and 0xff
    private fun rgb(red: Int, green: Int, blue: Int): Int =
        argb(255, red.coerceIn(0, 255), green.coerceIn(0, 255), blue.coerceIn(0, 255))
    private fun argb(alpha: Int, red: Int, green: Int, blue: Int): Int =
        ((alpha and 0xff) shl 24) or ((red and 0xff) shl 16) or ((green and 0xff) shl 8) or (blue and 0xff)
}
