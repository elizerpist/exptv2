package com.fluvi.core.pulse

/** Single, versioned V1 delivery policy. User preferences only tune the
 * documented normal cooldown; financial priority never bypasses controls. */
object PulseDeliveryPolicyCatalog {
    const val version: Int = 1

    val default: PulseDeliveryPolicy = PulseDeliveryPolicy()

    fun readableDurationMillis(story: PulseStoryDraft): Long {
        val visibleCharacters = story.headline.length + (story.detail?.length ?: 0)
        // Hungarian copy has a stable base exposure. Extra text increases the
        // dwell time gently but never creates a long-lived header banner.
        val additional = (((visibleCharacters - 90).coerceAtLeast(0) + 29) / 30) * 1_000L
        return (default.baseReadableMillis + additional).coerceAtMost(default.maxReadableMillis)
    }
}
