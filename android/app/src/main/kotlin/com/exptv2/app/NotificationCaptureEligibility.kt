package com.exptv2.app

data class NotificationCaptureProfile(
    val id: String,
    val name: String,
    val enabled: Boolean,
    val packageName: String,
    val appLabel: String,
    val appFilterText: String,
)

data class NotificationCaptureEligibilityResult(
    val allowed: Boolean,
    val reason: String,
    val profileId: String = "",
    val profileName: String = "",
)

object NotificationCaptureEligibility {
    fun evaluate(
        profiles: List<NotificationCaptureProfile>,
        packageName: String,
        appLabel: String,
    ): NotificationCaptureEligibilityResult {
        val enabledProfiles = profiles.filter { it.enabled }
        if (enabledProfiles.isEmpty()) {
            return NotificationCaptureEligibilityResult(false, "no_enabled_profiles")
        }

        var configuredProfileCount = 0
        for (profile in enabledProfiles) {
            val configuredPackage = profile.packageName.trim()
            if (configuredPackage.isNotEmpty()) {
                configuredProfileCount += 1
                if (configuredPackage == packageName) {
                    return NotificationCaptureEligibilityResult(
                        allowed = true,
                        reason = "package",
                        profileId = profile.id,
                        profileName = profile.name,
                    )
                }
                continue
            }

            val filter = profile.appFilterText.trim()
            if (filter.isEmpty()) continue
            configuredProfileCount += 1
            val matches = runCatching {
                val regex = Regex(filter, RegexOption.IGNORE_CASE)
                regex.containsMatchIn(appLabel) || regex.containsMatchIn(packageName)
            }.getOrDefault(false)
            if (matches) {
                return NotificationCaptureEligibilityResult(
                    allowed = true,
                    reason = "app_filter",
                    profileId = profile.id,
                    profileName = profile.name,
                )
            }
        }

        return NotificationCaptureEligibilityResult(
            allowed = false,
            reason = if (configuredProfileCount == 0) {
                "no_profile_app"
            } else {
                "no_profile_match"
            },
        )
    }
}
