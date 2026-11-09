package com.fluvi.app.lockscreen

/** Pure, data-minimised surface classification.  Snapshots only contain
 * visible resource identifiers and window metadata; no application text or
 * accessibility content descriptions are read or retained. */
internal enum class KeyguardSurface {
    MAIN_KEYGUARD,
    CREDENTIAL,
    SHADE,
    OCCLUDED,
    UNKNOWN,
}

/** Why a surface decision was made. These are technical only: no node text,
 * app name, or accessibility payload is retained in diagnostics. */
internal enum class KeyguardSurfaceReason {
    NO_WINDOWS,
    ROOT_UNAVAILABLE,
    WALK_TRUNCATED,
    NO_MAIN_MARKER,
    CREDENTIAL_MARKER,
    SHADE_MARKER,
    FOREIGN_ABOVE,
    MAIN_CONFIRMED,
}

internal data class KeyguardSurfaceClassification(
    val surface: KeyguardSurface,
    val reason: KeyguardSurfaceReason,
    /** Counts only classifier marker categories, never screen text. */
    val markers: KeyguardSurfaceMarkers = KeyguardSurfaceMarkers(),
)

internal data class KeyguardSurfaceMarkers(
    val main: Int = 0,
    val credential: Int = 0,
    val shade: Int = 0,
    val occlusion: Int = 0,
) {
    fun compact(): String = "main:$main,credential:$credential,shade:$shade,occlusion:$occlusion"
}

internal data class KeyguardWindowSnapshot(
    val packageName: String?,
    val type: Int,
    val layer: Int,
    val displayId: Int,
    val ownOverlay: Boolean = false,
    val visibleViewIds: Set<String> = emptySet(),
    val windowId: Int = -1,
)

internal object KeyguardSurfaceClassifier {
    private const val SYSTEM_UI = "com.android.systemui"
    private val systemPackages = setOf(SYSTEM_UI, "com.android.keyguard", "android")
    private val mainIds = setOf(
        "com.android.systemui:id/keyguard_carrier_text",
        "com.android.systemui:id/keyguard_indication_text_bottom",
        "com.android.systemui:id/keyguard_status_view",
        "com.android.systemui:id/keyguard_clock_switch",
        "com.android.systemui:id/left_button",
        "com.android.systemui:id/camera_button",
    )
    private val credentialIds = setOf(
        "com.android.systemui:id/keyguard_security_container",
        "com.android.systemui:id/keyguard_host_view",
        "com.android.systemui:id/password_entry",
        "element:BouncerContent",
    )
    private val shadeIds = setOf(
        "com.android.systemui:id/quick_settings_panel",
        "com.android.systemui:id/quick_qs_panel",
        "com.android.systemui:id/qs_frame",
        "com.android.systemui:id/settings_button",
        "com.android.systemui:id/notification_shade_shortcut",
        "com.android.systemui:id/split_shade_status_bar",
    )
    private val occludedIds = setOf(
        "com.android.systemui:id/global_actions_container",
        "com.android.systemui:id/emergency_call_button",
        "com.android.systemui:id/keyguard_camera_view",
        "com.android.systemui:id/keyguard_camera_preview",
        "com.android.systemui:id/camera_preview",
    )

    fun classify(windows: List<KeyguardWindowSnapshot>, primaryDisplayId: Int = 0): KeyguardSurface =
        classifyDetailed(windows, primaryDisplayId).surface

    fun classifyDetailed(
        windows: List<KeyguardWindowSnapshot>,
        primaryDisplayId: Int = 0,
        unavailableRoot: Boolean = false,
        walkTruncated: Boolean = false,
    ): KeyguardSurfaceClassification {
        val visible = windows.filter { it.displayId == primaryDisplayId && !it.ownOverlay }
        if (visible.isEmpty()) return KeyguardSurfaceClassification(
            KeyguardSurface.UNKNOWN,
            if (unavailableRoot) KeyguardSurfaceReason.ROOT_UNAVAILABLE else KeyguardSurfaceReason.NO_WINDOWS,
        )
        val system = visible.filter { it.packageName in systemPackages }
        val ids = system.flatMapTo(linkedSetOf()) { it.visibleViewIds }
        val markers = KeyguardSurfaceMarkers(
            main = ids.count { it in mainIds },
            credential = ids.count { it in credentialIds || it.contains("bouncer", ignoreCase = true) },
            shade = ids.count { it in shadeIds },
            occlusion = ids.count { it in occludedIds || it.contains("global_actions", ignoreCase = true) },
        )
        // Priority is deliberately security-first. A positive clock/carrier
        // marker can never override a visible bouncer or shade marker.
        if (ids.any { it in credentialIds || it.contains("bouncer", ignoreCase = true) }) {
            return KeyguardSurfaceClassification(KeyguardSurface.CREDENTIAL, KeyguardSurfaceReason.CREDENTIAL_MARKER, markers)
        }
        if (ids.any { it in occludedIds || it.contains("global_actions", ignoreCase = true) }) {
            return KeyguardSurfaceClassification(KeyguardSurface.OCCLUDED, KeyguardSurfaceReason.FOREIGN_ABOVE, markers)
        }
        if (ids.any { it in shadeIds }) return KeyguardSurfaceClassification(KeyguardSurface.SHADE, KeyguardSurfaceReason.SHADE_MARKER, markers)
        val foreignAboveSystem = visible.any { window ->
            window.packageName != null &&
                window.packageName !in systemPackages &&
                window.packageName != "com.fluvi.app" &&
                window.layer >= (system.maxOfOrNull { it.layer } ?: Int.MAX_VALUE)
        }
        if (foreignAboveSystem) return KeyguardSurfaceClassification(KeyguardSurface.OCCLUDED, KeyguardSurfaceReason.FOREIGN_ABOVE, markers)
        if (ids.any { it in mainIds }) return KeyguardSurfaceClassification(KeyguardSurface.MAIN_KEYGUARD, KeyguardSurfaceReason.MAIN_CONFIRMED, markers)
        return KeyguardSurfaceClassification(
            KeyguardSurface.UNKNOWN,
            if (walkTruncated) KeyguardSurfaceReason.WALK_TRUNCATED else KeyguardSurfaceReason.NO_MAIN_MARKER,
            markers,
        )
    }
}

internal enum class KeyguardCardVisibility {
    HIDDEN_OPT_OUT,
    HIDDEN_DISCONNECTED,
    HIDDEN_BEFORE_FIRST_UNLOCK,
    HIDDEN_OTHER_DISPLAY,
    HIDDEN_SCREEN,
    HIDDEN_UNLOCKED,
    HIDDEN_CREDENTIAL,
    HIDDEN_SHADE,
    HIDDEN_OCCLUDED,
    HIDDEN_UNKNOWN,
    SHOW_DISCREET,
    SHOW_FULL,
}

internal data class KeyguardCardSignals(
    val requested: Boolean,
    val serviceConnected: Boolean,
    val userUnlocked: Boolean,
    val primaryDisplay: Boolean,
    val interactive: Boolean,
    val displayOn: Boolean,
    val keyguardLocked: Boolean,
    val surface: KeyguardSurface,
    val showFinancialDetails: Boolean,
)

internal object KeyguardCardVisibilityPolicy {
    fun decide(signals: KeyguardCardSignals): KeyguardCardVisibility = when {
        !signals.requested -> KeyguardCardVisibility.HIDDEN_OPT_OUT
        !signals.serviceConnected -> KeyguardCardVisibility.HIDDEN_DISCONNECTED
        !signals.userUnlocked -> KeyguardCardVisibility.HIDDEN_BEFORE_FIRST_UNLOCK
        !signals.primaryDisplay -> KeyguardCardVisibility.HIDDEN_OTHER_DISPLAY
        !signals.interactive || !signals.displayOn -> KeyguardCardVisibility.HIDDEN_SCREEN
        !signals.keyguardLocked -> KeyguardCardVisibility.HIDDEN_UNLOCKED
        signals.surface == KeyguardSurface.CREDENTIAL -> KeyguardCardVisibility.HIDDEN_CREDENTIAL
        signals.surface == KeyguardSurface.SHADE -> KeyguardCardVisibility.HIDDEN_SHADE
        signals.surface == KeyguardSurface.OCCLUDED -> KeyguardCardVisibility.HIDDEN_OCCLUDED
        signals.surface != KeyguardSurface.MAIN_KEYGUARD -> KeyguardCardVisibility.HIDDEN_UNKNOWN
        signals.showFinancialDetails -> KeyguardCardVisibility.SHOW_FULL
        else -> KeyguardCardVisibility.SHOW_DISCREET
    }
}

/** Pure publication guard for slow financial resolves. Its input is the
 * generation captured at request start and the state immediately before a
 * View mutation on the main thread. */
internal data class KeyguardCardContentPublication(
    val requestSession: Long,
    val currentSession: Long,
    val requestEpoch: Long,
    val currentEpoch: Long,
    val requestFocusGeneration: Long,
    val currentFocusGeneration: Long,
    val currentlyFull: Boolean,
    val detailsStillAllowed: Boolean,
    val displayStillEligible: Boolean,
)

internal object KeyguardCardContentPublicationPolicy {
    fun canApply(value: KeyguardCardContentPublication): Boolean =
        value.requestSession == value.currentSession &&
            value.requestEpoch == value.currentEpoch &&
            value.requestFocusGeneration == value.currentFocusGeneration &&
            value.currentlyFull && value.detailsStillAllowed && value.displayStillEligible
}
