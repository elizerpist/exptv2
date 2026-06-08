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
        var configuredEnabledProfileCount = 0
        for (profile in enabledProfiles) {
            val match = matchProfile(profile, packageName, appLabel)
            if (match.configured) configuredEnabledProfileCount += 1
            if (match.matches) {
                return NotificationCaptureEligibilityResult(
                    allowed = true,
                    reason = match.reason,
                    profileId = profile.id,
                    profileName = profile.name,
                )
            }
        }

        for (profile in profiles.filterNot { it.enabled }) {
            val match = matchProfile(profile, packageName, appLabel)
            if (match.matches) {
                return NotificationCaptureEligibilityResult(
                    allowed = false,
                    reason = "profile_disabled",
                    profileId = profile.id,
                    profileName = profile.name,
                )
            }
        }

        if (enabledProfiles.isEmpty()) {
            return NotificationCaptureEligibilityResult(false, "no_enabled_profiles")
        }

        return NotificationCaptureEligibilityResult(
            allowed = false,
            reason = if (configuredEnabledProfileCount == 0) {
                "no_profile_app"
            } else {
                "no_profile_match"
            },
        )
    }

    private fun matchProfile(
        profile: NotificationCaptureProfile,
        packageName: String,
        appLabel: String,
    ): ProfileMatch {
        val configuredPackage = profile.packageName.trim()
        if (configuredPackage.isNotEmpty()) {
            return ProfileMatch(
                configured = true,
                matches = configuredPackage == packageName,
                reason = "package",
            )
        }

        val filter = profile.appFilterText.trim()
        if (filter.isEmpty()) return ProfileMatch(configured = false)
        val matches = runCatching {
            val regex = Regex(filter, RegexOption.IGNORE_CASE)
            regex.containsMatchIn(appLabel) || regex.containsMatchIn(packageName)
        }.getOrDefault(false)
        return ProfileMatch(
            configured = true,
            matches = matches,
            reason = "app_filter",
        )
    }

    private data class ProfileMatch(
        val configured: Boolean,
        val matches: Boolean = false,
        val reason: String = "",
    )
}
