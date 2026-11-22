package com.fluvi.app.lockscreen.material

import android.content.Context
import android.os.Handler
import android.os.Looper
import java.security.MessageDigest

/** Public shader identity only: no palette, financial values, profile, or phase. */
internal data class KeyguardOrbProgramSelector(val effectId: String, val usesPortal: Boolean) {
    companion object {
        fun forProfile(profile: KeyguardMaterialProfile): KeyguardOrbProgramSelector? =
            if (profile.animated && !profile.usesStaticOrbGradient())
                KeyguardOrbProgramSelector(profile.effectId, profile.usesPortal) else null
    }

    /** The packaged generator hashes the AGSL body after these four headers. */
    fun accepts(artifact: KeyguardShaderArtifact): Boolean {
        if (artifact.effectId != effectId || artifact.usesPortal != usesPortal ||
            effectId !in KeyguardMaterialProfile.effectIds ||
            artifact.metadata.sourceShaderHash != KeyguardMaterialProfile.SOURCE_SHADER_HASH ||
            artifact.metadata.adapterVersion != "9") return false
        val variant = if (usesPortal) "portal" else "plain"
        val header = "// generated-from=shaders/dashboard_header_field.frag\n" +
            "// source-sha256=${KeyguardMaterialProfile.SOURCE_SHADER_HASH}\n" +
            "// effect-id=$effectId\n// variant=$variant\n"
        if (!artifact.source.startsWith(header)) return false
        val hash = MessageDigest.getInstance("SHA-256")
            .digest(artifact.source.substring(header.length).toByteArray(Charsets.UTF_8))
            .joinToString("") { "%02x".format(it.toInt() and 0xff) }
        return artifact.metadata.generatedAgslHash == hash &&
            artifact.programKey == "$effectId|$usesPortal|$hash|9"
    }
}

/** One active immutable asset request and, while it drains, one latest desired
 * owner. Neither stale completion nor asset loading can grant disclosure. */
internal class KeyguardOrbDirectProgramWarmup(
    private val context: Context,
    private val submit: (KeyguardOrbSurfaceTarget, KeyguardOrbProgramSelector, KeyguardShaderArtifact, () -> Boolean) -> Unit,
    private val newStore: (KeyguardOrbSurfaceTarget) -> KeyguardShaderArtifactStore = { target ->
        if (KeyguardOrbSurfaceWorkerTestHooks.ENABLED) {
            KeyguardShaderArtifactStore(context, KeyguardShaderArtifactReader { ctx, effect, portal ->
                KeyguardOrbSurfaceWorkerTestHooks.beforeDirectArtifactLoad?.invoke(target)
                AndroidKeyguardShaderArtifactReader.load(ctx, effect, portal)
            })
        } else KeyguardShaderArtifactStore(context)
    },
) {
    private data class Request(val target: KeyguardOrbSurfaceTarget, val selector: KeyguardOrbProgramSelector,
        val current: () -> Boolean)
    private data class Active(val request: Request, val store: KeyguardShaderArtifactStore, val startedNs: Long,
        var retired: Boolean = false)
    private val main = Handler(Looper.getMainLooper())
    private var active: Active? = null
    private var desired: Request? = null
    private var closed = false

    fun request(target: KeyguardOrbSurfaceTarget, selector: KeyguardOrbProgramSelector, current: () -> Boolean) {
        check(Looper.myLooper() == Looper.getMainLooper())
        if (closed || target.revoked || !current() || target.firstDirectAuthorization.get() != null) return
        val request = Request(target, selector, current)
        target.r27WarmSelector = "${selector.effectId}|${selector.usesPortal}"
        target.r27WarmStatus = "LOADING"
        if (active != null) desired = request else start(request)
    }

    private fun start(request: Request) {
        if (closed || request.target.revoked || !request.current() ||
            request.target.firstDirectAuthorization.get() != null) return
        val entry = Active(request, newStore(request.target), System.nanoTime())
        active = entry
        val failure = runCatching {
            entry.store.prepare(request.selector.effectId, request.selector.usesPortal) { result ->
                if (active !== entry) return@prepare
                active = null
                request.target.r27LoadNs = System.nanoTime() - entry.startedNs
                val artifact = result.getOrNull()
                if (!closed && artifact != null && !request.target.revoked && request.current() &&
                    request.target.firstDirectAuthorization.get() == null) {
                    submit(request.target, request.selector, artifact, request.current)
                } else if (request.target.r27WarmStatus == "LOADING") {
                    request.target.r27WarmStatus = if (artifact == null) "LOAD_FAILED" else "STALE_OR_BUSY"
                }
                // If the owner retired during I/O, release as soon as the one
                // outstanding load settles; never start a second concurrent load.
                entry.store.dispose()
                val next = desired
                desired = null
                if (next != null) start(next)
            }
        }.exceptionOrNull()
        if (failure != null && active === entry) {
            active = null
            request.target.r27WarmStatus = "LOAD_FAILED"
            entry.store.dispose()
            val next = desired
            desired = null
            if (next != null) start(next)
        }
    }

    private fun retireActive(entry: Active) {
        if (entry.retired) return
        entry.retired = true
        entry.request.target.r27WarmStatus = "STALE"
        entry.store.retireWhenSettled {
            if (active === entry) {
                active = null
                val next = desired
                desired = null
                if (next != null) start(next)
            }
        }
    }

    /** May be called on any thread; target revocation itself is immediate. */
    fun retire(target: KeyguardOrbSurfaceTarget) {
        main.post {
            if (desired?.target === target) desired = null
            active?.takeIf { it.request.target === target }?.let(::retireActive)
        }
    }

    fun dispose() {
        check(Looper.myLooper() == Looper.getMainLooper())
        closed = true
        desired = null
        active?.let(::retireActive)
    }
}
