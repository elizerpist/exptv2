package com.fluvi.app.lockscreen.material

import java.util.concurrent.atomic.AtomicReference

/** One already-produced first use, not a visibility or release grant.
 * The producer offers once; Main may claim once or revoke before transfer.
 * A claimed test continuation remains revocable until it actually settles. */
internal class KeyguardOrbFirstOffer<T : Any> {
    private sealed interface State<out T> {
        data object Open : State<Nothing>
        data class Pending<T>(val value: T, val offeredAt: Long) : State<T>
        data class Claimed<T>(val value: T, val offeredAt: Long) : State<T>
        data object Settled : State<Nothing>
        data object Revoked : State<Nothing>
    }

    internal data class Claim<T>(val value: T, val offeredAt: Long)

    private val state = AtomicReference<State<T>>(State.Open)

    fun offer(value: T, at: Long): Boolean =
        state.compareAndSet(State.Open, State.Pending(value, at))

    fun claim(): Claim<T>? {
        while (true) {
            val current = state.get()
            if (current !is State.Pending) return null
            if (state.compareAndSet(current, State.Claimed(current.value, current.offeredAt))) {
                return Claim(current.value, current.offeredAt)
            }
        }
    }

    fun isClaimed(value: T): Boolean = (state.get() as? State.Claimed)?.value === value

    /** Caller owns the returned exact value and must dispose it once. */
    fun revoke(): T? {
        while (true) {
            val current = state.get()
            if (current === State.Revoked || current === State.Settled) return null
            if (state.compareAndSet(current, State.Revoked)) {
                return when (current) {
                    is State.Pending -> current.value
                    is State.Claimed -> current.value
                    else -> null
                }
            }
        }
    }

    /** A failed notification on Worker must not revoke a Main claim that may
     * already be executing a transaction. Main alone can revoke that claim. */
    fun revokeUnclaimed(): T? {
        while (true) {
            val current = state.get()
            if (current !is State.Pending && current !== State.Open) return null
            if (state.compareAndSet(current, State.Revoked)) {
                return (current as? State.Pending)?.value
            }
        }
    }

    /** The exact claim has a single terminal disposition, including transfer. */
    fun settle(value: T): Boolean {
        while (true) {
            val current = state.get()
            if (current !is State.Claimed || current.value !== value) return false
            if (state.compareAndSet(current, State.Settled)) return true
        }
    }
}
