package com.fluvi.app.lockscreen

/** Called only under the queue owner lock. Re-publishing equal scalar state
 * must not manufacture a new reference; an intervening change still does. */
internal object KeyguardR34SnapshotIdentity {
    fun <T : Any> publish(previous: T?, candidate: T?, same: (T, T) -> Boolean): T? =
        if (previous != null && candidate != null && same(previous, candidate)) previous else candidate
}
