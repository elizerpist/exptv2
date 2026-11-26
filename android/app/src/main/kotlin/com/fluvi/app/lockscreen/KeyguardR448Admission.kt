package com.fluvi.app.lockscreen

/** Scalar observations from real system/window readers; UNKNOWN never grants. */
internal object KeyguardR448Admission {
    enum class Presence { CLEAR, PRESENT, UNKNOWN }
    enum class Domain { PUBLIC_SAMPLE, PRIVATE }
    enum class Decision {
        ALLOW, OWNER_CHANGED, SYSTEM_UNKNOWN, SYSTEM_EXCLUDED, DISPLAY_UNKNOWN,
        EXCLUSION_UNKNOWN, RESTRICTED, MATERIAL_UNAUTHORIZED,
    }

    data class Stamp(val route: Long, val wake: Long, val material: Long)
    data class Exclusions(
        val observedAt: Long,
        val credential: Presence,
        val shade: Presence,
        val foreign: Presence,
        val powerMenu: Presence,
    )
    data class Inputs(
        val stamp: Stamp,
        val screenAt: Long,
        val system: KeyguardSystemState,
        val exclusions: Exclusions,
        val domain: Domain,
        val materialAuthorized: Boolean,
    )

    /** No clock/entry marker is used. Evidence still has to be current for
     * this wake and all restrictive states must be explicitly clear. */
    fun evaluate(inputs: Inputs, current: Stamp, now: Long): Decision {
        if (inputs.stamp != current || current.route <= 0 || current.wake <= 0 || current.material <= 0)
            return Decision.OWNER_CHANGED
        val system = inputs.system
        if (!system.available || system.startedAt < inputs.screenAt ||
            system.finishedAt < system.startedAt || system.finishedAt > now) return Decision.SYSTEM_UNKNOWN
        if (system.excluded || system.displayOff) return Decision.SYSTEM_EXCLUDED
        if (!system.primaryDisplay || !system.displayOn) return Decision.DISPLAY_UNKNOWN
        val exclusion = inputs.exclusions
        if (exclusion.observedAt < inputs.screenAt || exclusion.observedAt > now)
            return Decision.EXCLUSION_UNKNOWN
        val values = listOf(exclusion.credential, exclusion.shade, exclusion.foreign, exclusion.powerMenu)
        if (values.any { it == Presence.PRESENT }) return Decision.RESTRICTED
        if (values.any { it != Presence.CLEAR }) return Decision.EXCLUSION_UNKNOWN
        if (!inputs.materialAuthorized || (inputs.domain == Domain.PRIVATE && !system.userUnlocked))
            return Decision.MATERIAL_UNAUTHORIZED
        return Decision.ALLOW
    }
}
