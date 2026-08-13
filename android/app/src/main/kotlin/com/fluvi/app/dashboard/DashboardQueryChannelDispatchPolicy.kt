package com.fluvi.app.dashboard

/**
 * Documents the thread contract for the one dashboard query transport.
 *
 * The Flutter engine owns serial background task-queue delivery.  This policy
 * is deliberately separate from prepared-index generation ownership: the
 * latter still determines which foreground Query build may survive.
 */
internal object DashboardQueryChannelDispatchPolicy {
    const val usesBackgroundTaskQueue: Boolean = true
    const val serializesIncomingCalls: Boolean = true
    const val requiresMainDispatcherForCommittedPages: Boolean = false
    const val requiresMainDispatcherForResultDelivery: Boolean = false
}
