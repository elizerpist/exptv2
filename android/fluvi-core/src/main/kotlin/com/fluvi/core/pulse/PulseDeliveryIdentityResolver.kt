package com.fluvi.core.pulse

import java.security.MessageDigest

/**
 * Stable delivery identities deliberately exclude Core revisions, template
 * versions and rendered copy. Those values can change without creating a new
 * financial episode or a new automatic delivery entitlement.
 */
object PulseDeliveryIdentityResolver {
    fun situationEpisodeId(situation: PulseSituationSnapshot): String = hash(
        "episode|${situation.situationKey}|" +
            (situation.firstObservedAtUtcMs
                ?: situation.lastMaterialChangeAtUtcMs
                ?: situation.lastEvaluatedAtUtcMs),
    )

    fun deliveryKey(
        situationEpisodeId: String,
        storyKey: String,
        materialSemanticKey: String,
        presentationIntentId: String,
        channel: String = "header",
    ): String = "$channel|$situationEpisodeId|$storyKey|$materialSemanticKey|$presentationIntentId"

    fun hash(value: String): String = MessageDigest.getInstance("SHA-256")
        .digest(value.toByteArray())
        .joinToString("") { "%02x".format(it) }
        .take(32)
}
