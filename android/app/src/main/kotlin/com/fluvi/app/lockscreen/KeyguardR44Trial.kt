package com.fluvi.app.lockscreen

import com.fluvi.app.lockscreen.material.KeyguardMaterialPortal
import com.fluvi.app.lockscreen.material.KeyguardMaterialProfile

/** Explicit, process-local synthetic-data trial. Never persists a grant or a
 * firmware qualification. A process restart returns to the existing policy. */
internal object KeyguardR44Trial {
    @Volatile var active: Boolean = false
        private set
    @Volatile var deviceEntryResourceVerified: Boolean = false
        private set

    fun set(enabled: Boolean, resourceVerified: Boolean) {
        deviceEntryResourceVerified = enabled && resourceVerified
        active = enabled
    }

    private val portal = KeyguardMaterialPortal(false, 0, 0f, 0f, 50f, 100f, false, 0f, FloatArray(12))
    private val demo = KeyguardMaterialProfile(
        KeyguardMaterialProfile.SCHEMA_VERSION, KeyguardMaterialProfile.SHADER_ABI_VERSION,
        KeyguardMaterialProfile.SOURCE_SHADER_HASH, "r44-synthetic", 0L, "r44-synthetic-only",
        "dualTide", 1, 0f, 0f, .4f,
        intArrayOf(0xff104f7c.toInt(), 0xff62c7dc.toInt(), 0xff8366dc.toInt()),
        floatArrayOf(0f, .5f, 1f), 1f, 50f, FloatArray(40) { .2f }, portal, portal, 400f, 400f,
    )

    /** A fresh copy of the compiled, public-only scene. Never accepts a
     * stored profile: this path is permitted to retain its demo colors even
     * though financial disclosure is disabled. */
    internal fun publicProfile(): KeyguardMaterialProfile = demo.copy(
        colors = demo.colors.clone(), stops = demo.stops.clone(),
        commonSettings = demo.commonSettings.clone(),
        background = demo.background.copy(settings = demo.background.settings.clone()),
        interior = demo.interior.copy(settings = demo.interior.settings.clone()),
    )

    fun profile(normal: KeyguardMaterialProfile?): KeyguardMaterialProfile? = if (active) demo else normal
    fun settings(normal: KeyguardCardSettings): KeyguardCardSettings =
        if (active) normal.copy(showFinancialDetails = false) else normal
}

/** Capability for a public sample, not a wrapper around caller data. */
internal class KeyguardR46PublicMaterial private constructor() {
    internal fun sceneProfile(): KeyguardMaterialProfile = KeyguardR44Trial.publicProfile()

    companion object {
        internal fun demo(): KeyguardR46PublicMaterial = KeyguardR46PublicMaterial()
    }
}
