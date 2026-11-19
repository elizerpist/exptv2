package com.fluvi.app.lockscreen

import android.content.Context
import android.content.pm.ApplicationInfo

internal enum class KeyguardOrbRenderMode {
    SURFACE_LIVE, SURFACE_STATIC, LEGACY_R11;

    companion object {
        fun parse(value: String?): KeyguardOrbRenderMode =
            entries.firstOrNull { it.name == value } ?: SURFACE_LIVE
    }
}

internal data class KeyguardOrbRenderModeStatus(
    val configured: KeyguardOrbRenderMode,
    val effective: KeyguardOrbRenderMode,
    val visible: Boolean,
    val attachedSelection: KeyguardOrbRenderMode = effective,
) {
    val pendingBoundary: Boolean get() = visible && configured != attachedSelection
    fun toMap(): Map<String, Any> = mapOf(
        "available" to true,
        "configured" to configured.name,
        "effective" to effective.name,
        "pendingBoundary" to pendingBoundary,
    )
}

/** Diagnostic override only; eligibility and disclosure remain service-owned. */
internal object KeyguardOrbRenderModeStore {
    private const val PREFS = "fluvi_keyguard_orb_diagnostic_route"
    private const val MODE = "mode"

    fun diagnosticBuild(context: Context): Boolean =
        context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0

    fun read(context: Context): KeyguardOrbRenderMode =
        if (!diagnosticBuild(context)) KeyguardOrbRenderMode.SURFACE_LIVE
        else KeyguardOrbRenderMode.parse(context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(MODE, null))

    fun write(context: Context, mode: KeyguardOrbRenderMode): Boolean {
        if (!diagnosticBuild(context)) return false
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(MODE, mode.name).apply()
        return true
    }
}
