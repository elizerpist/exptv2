package com.fluvi.app.lockscreen.material

import android.content.Context
import android.os.Handler
import android.os.Looper
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Immutable, build-scoped shader input.  The source and metadata can safely
 * cross threads; a RuntimeShader created from it remains owned by exactly one
 * [KeyguardHeaderMaterialView].
 */
internal data class KeyguardShaderArtifact(
    val effectId: String,
    val usesPortal: Boolean,
    val source: String,
    val metadata: KeyguardHeaderShader.Metadata,
) {
    val programKey: String = "$effectId|$usesPortal|${metadata.generatedAgslHash}|${metadata.adapterVersion}"
}

/** Kept injectable so the draw-path test can prove asset reads are absent. */
internal fun interface KeyguardShaderArtifactReader {
    fun load(context: Context, effectId: String, usesPortal: Boolean): KeyguardShaderArtifact
}

internal object AndroidKeyguardShaderArtifactReader : KeyguardShaderArtifactReader {
    override fun load(context: Context, effectId: String, usesPortal: Boolean): KeyguardShaderArtifact {
        require(effectId in KeyguardMaterialProfile.effectIds) { "unknown-effect:$effectId" }
        val variant = if (usesPortal) "portal" else "plain"
        val metadata = KeyguardHeaderShader.metadata(context, effectId, usesPortal)
        val source = context.assets
            .open("fluvi_keyguard_header_material_${effectId}_$variant.agsl")
            .bufferedReader()
            .use { it.readText() }
        return KeyguardShaderArtifact(effectId, usesPortal, source, metadata)
    }
}

/**
 * One bounded lane per retained keyguard root.  It performs source/metadata
 * loading away from the accessibility Binder lane.  It deliberately caches
 * only immutable source artifacts; mutable RuntimeShader uniforms are never
 * shared between the orb and the card background.
 */
internal class KeyguardShaderArtifactStore(
    private val context: Context,
    private val reader: KeyguardShaderArtifactReader = AndroidKeyguardShaderArtifactReader,
    private val executor: ExecutorService = Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "fluvi-keyguard-shader-prepare").apply { isDaemon = true }
    },
    private val mainHandler: Handler = Handler(Looper.getMainLooper()),
) {
    private val lock = Any()
    private val artifacts = object : LinkedHashMap<String, KeyguardShaderArtifact>(4, .75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, KeyguardShaderArtifact>?): Boolean = size > 3
    }
    private val callbacks = mutableMapOf<String, MutableList<(Result<KeyguardShaderArtifact>) -> Unit>>()
    @Volatile private var closed = false
    private var loadCount = 0
    private var metadataParseCount = 0

    fun prepare(effectId: String, usesPortal: Boolean, callback: (Result<KeyguardShaderArtifact>) -> Unit) {
        val key = "$effectId|$usesPortal"
        val ready = synchronized(lock) {
            if (closed) return
            artifacts[key]?.also { return@synchronized Result.success(it) }
            callbacks.getOrPut(key) { mutableListOf() }.add(callback)
            if (callbacks[key]?.size == 1) {
                executor.execute {
                    val result = runCatching {
                        val artifact = reader.load(context, effectId, usesPortal)
                        synchronized(lock) {
                            loadCount += 1
                            metadataParseCount += 1
                            artifacts[key] = artifact
                        }
                        artifact
                    }
                    val pending = synchronized(lock) { callbacks.remove(key).orEmpty() }
                    mainHandler.post {
                        if (!closed) pending.forEach { it(result) }
                    }
                }
            }
            null
        }
        if (ready != null) callback(ready)
    }

    fun diagnostics(): KeyguardShaderArtifactStoreDiagnostics = synchronized(lock) {
        KeyguardShaderArtifactStoreDiagnostics(loadCount, metadataParseCount, artifacts.size, callbacks.size)
    }

    fun dispose() {
        synchronized(lock) {
            closed = true
            callbacks.clear()
            artifacts.clear()
        }
        executor.shutdownNow()
    }
}

internal data class KeyguardShaderArtifactStoreDiagnostics(
    val assetLoadCount: Int,
    val metadataParseCount: Int,
    val cachedArtifactCount: Int,
    val pendingPreparationCount: Int,
)
