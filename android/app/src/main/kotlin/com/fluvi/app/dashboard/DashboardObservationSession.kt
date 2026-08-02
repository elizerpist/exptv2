package com.fluvi.app.dashboard

/**
 * Owns exactly one native dashboard observation at a time.
 *
 * Flutter's EventChannel deactivation is asynchronous. A cancellation for an
 * older listener may therefore arrive after a newer listener has subscribed.
 * The listener identity is the boundary that prevents that stale cancellation
 * from terminating the current Room observer.
 */
internal class DashboardObservationSession<T>(
    private val cancelObservation: (T) -> Unit,
) {
    private var active: ActiveObservation<T>? = null

    val activeSubscriptionId: String?
        get() = active?.subscriptionId

    fun replace(subscriptionId: String, observation: T) {
        active?.let { cancelObservation(it.observation) }
        active = ActiveObservation(
            subscriptionId = subscriptionId,
            observation = observation,
        )
    }

    fun isActive(subscriptionId: String): Boolean =
        active?.subscriptionId == subscriptionId

    fun cancelIfActive(subscriptionId: String): Boolean {
        val current = active
        if (current?.subscriptionId != subscriptionId) return false
        active = null
        cancelObservation(current.observation)
        return true
    }

    fun cancelActive() {
        active?.let { cancelObservation(it.observation) }
        active = null
    }
}

private data class ActiveObservation<T>(
    val subscriptionId: String,
    val observation: T,
)
