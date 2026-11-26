package com.fluvi.app.lockscreen

import android.content.Context

/** Independent of the existing SURFACE_LIVE/SURFACE_STATIC render-mode knob. */
internal enum class KeyguardR448DisplayRoute {
    FLUVI_STREAM, WIDGETS_ANYWHERE;

    companion object {
        fun parse(value: String?): KeyguardR448DisplayRoute =
            entries.firstOrNull { it.name == value } ?: FLUVI_STREAM
    }
}

internal object KeyguardR448DisplayRouteStore {
    private const val PREFS = "fluvi_keyguard_r448_display_route"
    private const val ROUTE = "route"

    fun read(context: Context): KeyguardR448DisplayRoute =
        if (!KeyguardOrbRenderModeStore.diagnosticBuild(context)) KeyguardR448DisplayRoute.FLUVI_STREAM
        else KeyguardR448DisplayRoute.parse(context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(ROUTE, null))

    fun write(context: Context, route: KeyguardR448DisplayRoute): Boolean =
        KeyguardOrbRenderModeStore.diagnosticBuild(context) &&
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(ROUTE, route.name).commit()
}
