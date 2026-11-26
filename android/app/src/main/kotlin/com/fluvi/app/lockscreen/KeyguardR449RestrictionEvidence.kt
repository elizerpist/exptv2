package com.fluvi.app.lockscreen

import android.view.accessibility.AccessibilityWindowInfo

/** The result of one bounded, current window inventory. No node or user text
 * escapes the reader. Absence becomes CLEAR only when the relevant inventory
 * and all its SystemUI roots were actually read to completion. */
internal object KeyguardR449RestrictionEvidence {
    data class Result(val exclusions: KeyguardR448Admission.Exclusions, val reason: String,
                      val lower: List<KeyguardR45LowerWindow> = emptyList(),
                      val privateSurface: KeyguardSurface = KeyguardSurface.UNKNOWN)
    data class UnresolvedUpper(val host: Int, val upper: Int)

    /** A scheduling hint, never permission to draw. It is only produced when
     * one upper root is the sole unresolved member of this real inventory. */
    fun unresolvedUpper(windows: List<KeyguardWindowSnapshot>, classification: KeyguardSurfaceClassification,
                        truncated: Boolean): UnresolvedUpper? {
        if (truncated || classification.r444Gate != KeyguardR444Gate.INCOMPLETE) return null
        val primary = windows.filter { it.displayId == 0 && !it.ownOverlay }
        val hosts = primary.filter { it.packageName == "com.android.systemui" &&
            it.type == AccessibilityWindowInfo.TYPE_SYSTEM && it.r444Active == true && it.r444Focused == true &&
            it.r44?.let { e -> e.verifiedRoot && e.active && e.complete && !e.foreignNode } == true }
        val host = hosts.singleOrNull() ?: return null
        val unresolved = primary.filter { it !== host && it.layer >= host.layer &&
            (it.packageName == null || it.r44?.verifiedRoot != true) }
        val upper = unresolved.singleOrNull() ?: return null
        if (host.windowId < 0 || upper.windowId < 0 || primary.any {
                it !== upper && (it.packageName != "com.android.systemui" ||
                    it.type != AccessibilityWindowInfo.TYPE_SYSTEM ||
                    it.r44?.let { e -> !e.verifiedRoot || !e.complete || e.foreignNode } != false)
            }) return null
        val excludes = fromInventory(primary, 0L, unavailable = true, truncated = false).exclusions
        if (listOf(excludes.credential, excludes.shade, excludes.foreign, excludes.powerMenu)
                .any { it == KeyguardR448Admission.Presence.PRESENT }) return null
        return UnresolvedUpper(host.windowId, upper.windowId)
    }

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
        val hosts = primary.filter { it.type == AccessibilityWindowInfo.TYPE_SYSTEM &&
            it.packageName == "com.android.systemui" && it.r444Active == true && it.r444Focused == true &&
            it.r44?.let { e -> e.verifiedRoot && e.active && e.complete && !e.foreignNode } == true }
        val host = hosts.singleOrNull()
        // A known app behind a verified active SystemUI host cannot
        // cover that host. Unknown or higher windows remain fail-closed.
        val explicitForeign = primary.any { it.packageName != null && it.packageName != "com.android.systemui" &&
            (host == null || it.layer >= host.layer) }
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
        val lower = if (covered && !credential && !shade && !power && !foreign && host != null) primary.asSequence()
            .filter { it !== host && it.layer < host.layer && it.windowId >= 0 &&
                it.r444Active == false && it.r444Focused == false && it.packageName != null }
            .take(8).map { KeyguardR45LowerWindow(it.windowId, it.displayId, requireNotNull(it.packageName)) }.toList()
        else emptyList()
        // The public sample's CLEAR inventory is only an exclusion check.
        // Private data additionally requires the normal positive classifier.
        val privateSurface = if (covered) KeyguardR44SurfaceClassifier.classify(primary,
            unavailable, truncated, strictOwnAttribution = true, syntheticTrial = false).surface
        else KeyguardSurface.UNKNOWN
        return Result(result, reason, lower, privateSurface)
    }
}
