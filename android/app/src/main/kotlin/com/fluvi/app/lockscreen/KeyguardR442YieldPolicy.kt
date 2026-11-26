package com.fluvi.app.lockscreen

/** Scheduling only: neither a pending request nor SCREEN_ON grants a pixel. */
internal object KeyguardR442YieldPolicy {
    fun permits(
        api: Int, orb: Boolean, screenAt: Long?, screenSession: Long?, readStarted: Long,
        authority: KeyguardInspectionAuthority, active: KeyguardCardInspectionRequest?,
        old: KeyguardCardInspectionRequest, pending: KeyguardCardInspectionRequest?,
    ): Boolean {
        if (api != 37 || !orb || screenAt == null || screenSession != old.session ||
            readStarted >= screenAt || old.queuedAtUptimeMs >= screenAt ||
            active !== old || pending == null || pending.id <= old.id ||
            !authority.matches(old) || !authority.matches(pending)) return false
        val received = pending.triggerReceivedUptimeMs ?: return false
        return received >= screenAt && pending.queuedAtUptimeMs >= received &&
            pending.trigger != "surfaceRetry"
    }
}
