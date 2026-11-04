package com.fluvi.app.lockscreen

/** Keeps same-surface accessibility noise separate from real financial
 * invalidation. Existing full content remains visible while a replacement is
 * resolved. */
internal data class KeyguardCardContentRefreshPlan(
    val publishLoading: Boolean,
    val startResolve: Boolean,
)

internal object KeyguardCardContentRefreshPolicy {
    fun firstOrSurfacePlan(
        focusChanged: Boolean,
        hasCurrentContent: Boolean,
        resolveInFlightForFocus: Boolean,
    ): KeyguardCardContentRefreshPlan = when {
        focusChanged -> KeyguardCardContentRefreshPlan(publishLoading = true, startResolve = true)
        hasCurrentContent -> KeyguardCardContentRefreshPlan(publishLoading = false, startResolve = false)
        resolveInFlightForFocus -> KeyguardCardContentRefreshPlan(publishLoading = false, startResolve = false)
        else -> KeyguardCardContentRefreshPlan(publishLoading = true, startResolve = true)
    }
}
