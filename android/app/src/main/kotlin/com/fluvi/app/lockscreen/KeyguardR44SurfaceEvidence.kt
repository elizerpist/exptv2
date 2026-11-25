package com.fluvi.app.lockscreen

import android.view.accessibility.AccessibilityWindowInfo

/** Bounded, technical facts from one physical tree walk.  No node, text,
 * content description, arbitrary Compose tag, or prior-wake fact is kept. */
internal object KeyguardR44Markers {
    const val EXTRA = "androidx.compose.ui.semantics.testTag"

    enum class Marker { HOST, DEVICE_ENTRY, LARGE_CLOCK, SMALL_CLOCK, BOUNCER, SHADE, QUICK_SETTINGS }
    enum class Carrier { VIEW_ID, EXTRA_EAGER, EXTRA_LAZY }

    fun exact(value: CharSequence?): Marker? = when (value?.toString()) {
        "element:lockscreen" -> Marker.HOST
        "com.android.systemui:id/device_entry_icon_view" -> Marker.DEVICE_ENTRY
        "element:LargeClock" -> Marker.LARGE_CLOCK
        "element:SmallClock" -> Marker.SMALL_CLOCK
        "overlay:bouncer" -> Marker.BOUNCER
        "overlay:notifications_shade", "scene:shade" -> Marker.SHADE
        "overlay:quick_settings_shade", "scene:quick_settings" -> Marker.QUICK_SETTINGS
        else -> null
    }

    fun exclusion(marker: Marker): String? = when (marker) {
        Marker.BOUNCER -> "overlay:bouncer"
        Marker.SHADE -> "scene:shade"
        Marker.QUICK_SETTINGS -> "scene:quick_settings"
        else -> null
    }
}

internal data class KeyguardR44Witness(
    val marker: KeyguardR44Markers.Marker,
    val carrier: KeyguardR44Markers.Carrier,
    val ordinal: Int,
)

internal data class KeyguardR44WindowEvidence(
    val verifiedRoot: Boolean,
    val active: Boolean,
    val host: KeyguardR44Witness?,
    val content: KeyguardR44Witness?,
    val contentBelowHost: Boolean,
    val complete: Boolean,
    val foreignNode: Boolean,
    /** True only for an independently verified non-covering SystemUI surface. */
    val verifiedPassive: Boolean = false,
    val advertised: Int = 0,
    val fetched: Int = 0,
    val failed: Int = 0,
    val budgetHit: Boolean = false,
    val extraMs: Long = 0,
)

internal object KeyguardR44SurfaceClassifier {
    /** All ordinary admission gates and the current request's authority are
     * still applied by the service before and after this function. */
    fun classify(
        windows: List<KeyguardWindowSnapshot>,
        unavailableRoot: Boolean,
        walkTruncated: Boolean,
        strictOwnAttribution: Boolean,
        syntheticTrial: Boolean,
    ): KeyguardSurfaceClassification {
        val legacy = KeyguardSurfaceClassifier.classifyDetailed(
            windows, unavailableRoot = unavailableRoot, walkTruncated = walkTruncated,
            strictOwnAttribution = strictOwnAttribution,
        )
        // Known restrictions remain useful even when a different root is
        // incomplete.  They always precede any positive proof.
        if (legacy.surface == KeyguardSurface.CREDENTIAL || legacy.surface == KeyguardSurface.SHADE ||
            legacy.surface == KeyguardSurface.OCCLUDED) return legacy
        if (unavailableRoot || walkTruncated) return legacy
        val primary = windows.filter { it.displayId == 0 && !it.ownOverlay }
        val observed = primary.mapNotNull { it.r44 }
        if (observed.any { !it.complete }) return KeyguardSurfaceClassification(
            KeyguardSurface.UNKNOWN, KeyguardSurfaceReason.WALK_TRUNCATED, legacy.markers)
        // A legacy positive also has to survive new global restriction and
        // occlusion checks relative to the active host on API 37.
        if (legacy.surface == KeyguardSurface.MAIN_KEYGUARD) {
            val active = primary.filter { w -> w.packageName == "com.android.systemui" &&
                w.type == AccessibilityWindowInfo.TYPE_SYSTEM &&
                w.r44?.let { it.verifiedRoot && it.active } == true }
            if (active.size != 1 || primary.any { it !== active.single() &&
                    it.layer >= active.single().layer && it.r44?.verifiedPassive != true }) {
                return KeyguardSurfaceClassification(KeyguardSurface.UNKNOWN,
                    KeyguardSurfaceReason.FOREIGN_ABOVE, legacy.markers)
            }
            return legacy
        }
        if (!syntheticTrial) return legacy
        val hosts = primary.filter { w ->
            w.type == AccessibilityWindowInfo.TYPE_SYSTEM && w.packageName == "com.android.systemui" &&
                w.r44?.let { it.verifiedRoot && it.active && it.host != null } == true
        }
        if (hosts.size != 1) return legacy
        val host = hosts.single()
        val evidence = requireNotNull(host.r44)
        val content = evidence.content ?: return legacy
        if (!evidence.complete || evidence.foreignNode || !evidence.contentBelowHost ||
            evidence.host?.ordinal == content.ordinal) return legacy
        if (content.marker != KeyguardR44Markers.Marker.DEVICE_ENTRY &&
            content.marker != KeyguardR44Markers.Marker.LARGE_CLOCK &&
            content.marker != KeyguardR44Markers.Marker.SMALL_CLOCK) return legacy
        // Compare against the actual host, not the highest SystemUI layer.
        // Unknown or covering windows are not assumed to be transparent.
        if (primary.any { it !== host && it.layer >= host.layer && it.r44?.verifiedPassive != true }) {
            return KeyguardSurfaceClassification(KeyguardSurface.UNKNOWN,
                KeyguardSurfaceReason.FOREIGN_ABOVE, legacy.markers)
        }
        return KeyguardSurfaceClassification(KeyguardSurface.MAIN_KEYGUARD,
            KeyguardSurfaceReason.MAIN_CONFIRMED, legacy.markers.copy(main = 1))
    }
}
