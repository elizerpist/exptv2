package com.fluvi.app.lockscreen

import android.view.accessibility.AccessibilityWindowInfo

/** Bounded, technical facts from one physical tree walk.  No node, text,
 * content description, arbitrary Compose tag, or prior-wake fact is kept. */
internal object KeyguardR44Markers {
    const val EXTRA = "androidx.compose.ui.semantics.testTag"

    enum class Marker { HOST, DEVICE_ENTRY, LARGE_CLOCK, SMALL_CLOCK, BOUNCER, SHADE, QUICK_SETTINGS }
    enum class Carrier { VIEW_ID, EXTRA_EAGER, EXTRA_LAZY }

    fun exact(value: CharSequence?): Marker? = when {
        value == null -> null
        value.contentEquals("element:lockscreen") -> Marker.HOST
        value.contentEquals("com.android.systemui:id/device_entry_icon_view") -> Marker.DEVICE_ENTRY
        value.contentEquals("element:LargeClock") -> Marker.LARGE_CLOCK
        value.contentEquals("element:SmallClock") -> Marker.SMALL_CLOCK
        value.contentEquals("overlay:bouncer") -> Marker.BOUNCER
        value.contentEquals("overlay:notifications_shade") || value.contentEquals("scene:shade") -> Marker.SHADE
        value.contentEquals("overlay:quick_settings_shade") || value.contentEquals("scene:quick_settings") -> Marker.QUICK_SETTINGS
        else -> null
    }

    fun exclusion(marker: Marker): String? = when (marker) {
        Marker.BOUNCER -> "overlay:bouncer"
        Marker.SHADE -> "scene:shade"
        Marker.QUICK_SETTINGS -> "scene:quick_settings"
        else -> null
    }

    /** Unknown names never grant. An unresolved scene/overlay role may
     * conceal a restriction; ordinary unrelated inspected tags are counted. */
    fun unknownMayRestrict(value: CharSequence, nestedInHost: Boolean): Boolean =
        value.startsWith("overlay:") || (!nestedInHost && value.startsWith("scene:"))
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
    val unsupported: Int = 0,
    val budgetHit: Boolean = false,
    val extraMs: Long = 0,
    val rawHost: Int = 0,
    val rawEntry: Int = 0,
    val rawClock: Int = 0,
    val rejectedUnverified: Int = 0,
    val rejectedAncestry: Int = 0,
    val rejectedExcluded: Int = 0,
    val rejectedForeign: Int = 0,
    val rejectedHidden: Int = 0,
    val firstCandidate: KeyguardR44Markers.Marker? = null,
    val firstCarrier: KeyguardR44Markers.Carrier? = null,
    val r443Overflow: Int = 0,
    val r443Candidates: List<KeyguardR443CandidateObservation> = emptyList(),
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
        val systemIds = windows.asSequence().filter {
            it.displayId == 0 && !it.ownOverlay && it.packageName == "com.android.systemui"
        }.flatMap { it.visibleViewIds.asSequence() }
        val r44Restrictions = systemIds.mapNotNull(KeyguardR44Markers::exact).toSet()
        if (KeyguardR44Markers.Marker.BOUNCER in r44Restrictions) return KeyguardSurfaceClassification(
            KeyguardSurface.CREDENTIAL, KeyguardSurfaceReason.CREDENTIAL_MARKER, legacy.markers)
        if (KeyguardR44Markers.Marker.SHADE in r44Restrictions ||
            KeyguardR44Markers.Marker.QUICK_SETTINGS in r44Restrictions) return KeyguardSurfaceClassification(
            KeyguardSurface.SHADE, KeyguardSurfaceReason.SHADE_MARKER, legacy.markers)
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
        // Multiple verified lockscreen hosts are ambiguous even if only one
        // is currently marked active. Do not infer ownership from the layer.
        if (observed.count { it.verifiedRoot && it.host != null } > 1) return KeyguardSurfaceClassification(
            KeyguardSurface.UNKNOWN, KeyguardSurfaceReason.WALK_TRUNCATED, legacy.markers)
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
