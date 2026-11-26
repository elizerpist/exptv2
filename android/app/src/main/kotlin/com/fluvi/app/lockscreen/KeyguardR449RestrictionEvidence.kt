package com.fluvi.app.lockscreen

import android.view.accessibility.AccessibilityWindowInfo

/** The result of one bounded, current window inventory. No node or user text
 * escapes the reader. Absence becomes CLEAR only when the relevant inventory
 * and all its SystemUI roots were actually read to completion. */
internal object KeyguardR449RestrictionEvidence {
    data class Result(val exclusions: KeyguardR448Admission.Exclusions, val reason: String)

    fun fromInventory(windows: List<KeyguardWindowSnapshot>, at: Long,
                      unavailable: Boolean, truncated: Boolean): Result {
        val P = KeyguardR448Admission.Presence.PRESENT
        val U = KeyguardR448Admission.Presence.UNKNOWN
        val C = KeyguardR448Admission.Presence.CLEAR
        val primary = windows.filter { it.displayId == 0 && !it.ownOverlay }
        val ids = primary.filter { it.packageName == "com.android.systemui" }
            .flatMapTo(linkedSetOf()) { it.visibleViewIds }
        val markers = ids.mapNotNull(KeyguardR44Markers::exact).toSet()
        val legacy = KeyguardSurfaceClassifier.classifyDetailed(primary,
            unavailableRoot = unavailable, walkTruncated = truncated, strictOwnAttribution = true)
        val credential = KeyguardR44Markers.Marker.BOUNCER in markers ||
            legacy.surface == KeyguardSurface.CREDENTIAL
        val shade = KeyguardR44Markers.Marker.SHADE in markers ||
            KeyguardR44Markers.Marker.QUICK_SETTINGS in markers || legacy.surface == KeyguardSurface.SHADE
        val power = ids.any { it.contains("global_actions", ignoreCase = true) }
        val explicitForeign = primary.any { it.packageName != null && it.packageName != "com.android.systemui" }
        val hosts = primary.filter { it.type == AccessibilityWindowInfo.TYPE_SYSTEM &&
            it.packageName == "com.android.systemui" && it.r444Active == true && it.r444Focused == true &&
            it.r44?.let { e -> e.verifiedRoot && e.active && e.complete && !e.foreignNode } == true }
        val host = hosts.singleOrNull()
        val incomplete = unavailable || truncated || primary.isEmpty() || host == null || primary.any {
            it.packageName == null || (it.packageName == "com.android.systemui" &&
                (it.type != AccessibilityWindowInfo.TYPE_SYSTEM ||
                    it.r44?.let { e -> !e.verifiedRoot || !e.complete || e.foreignNode } != false))
        }
        val ambiguousUpper = host != null && primary.any {
            it !== host && it.layer >= host.layer && !(it.packageName == "com.android.systemui" &&
                it.r444RootRole == "UDFPS_VERIFIED" && it.r444Active == false && it.r444Focused == false &&
                it.r44?.let { e -> e.verifiedRoot && e.complete && !e.foreignNode } == true)
        }
        val covered = !incomplete && !ambiguousUpper
        fun value(present: Boolean) = if (present) P else if (covered) C else U
        val foreign = explicitForeign || (legacy.surface == KeyguardSurface.OCCLUDED && !power)
        val result = KeyguardR448Admission.Exclusions(at, value(credential), value(shade), value(foreign), value(power))
        val reason = when {
            credential -> "CREDENTIAL"
            shade -> "SHADE"
            power -> "POWER_MENU"
            foreign -> "FOREIGN"
            unavailable -> "ROOT_UNAVAILABLE"
            truncated -> "TRUNCATED"
            primary.isEmpty() -> "NO_WINDOWS"
            host == null -> "HOST_UNKNOWN"
            incomplete -> "INCOMPLETE"
            ambiguousUpper -> "UPPER_UNKNOWN"
            else -> "CLEAR"
        }
        return Result(result, reason)
    }
}
