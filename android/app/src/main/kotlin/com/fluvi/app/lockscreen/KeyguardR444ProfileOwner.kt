package com.fluvi.app.lockscreen

/** Main-thread owner of one accessibility flag bit. The persisted marker is
 * solely a crash-recovery obligation; it never enables a profile or grants
 * display authority. Other service flags are merged from the latest read. */
internal class KeyguardR444ProfileOwner(
    private val bit: Int,
    private val readFlags: () -> Int?,
    private val writeFlags: (Int) -> Boolean,
    private val pendingRestore: () -> Boolean?,
    private val setPendingRestore: (Boolean) -> Boolean,
) {
    enum class Kind { INACTIVE, STANDARD, STANDARD_ALREADY_INCLUDED, EXPANDED, ERROR }
    data class Snapshot(val revision: Long, val kind: Kind, val before: Int?, val actual: Int?,
                        val changedByUs: Boolean, val ready: Boolean) {
        val expandedPolicy: Boolean get() = kind == Kind.EXPANDED || kind == Kind.STANDARD_ALREADY_INCLUDED
    }
    @Volatile var snapshot = Snapshot(0, Kind.INACTIVE, null, null, false, true)
        private set

    /** Called before a reconnected service can observe financial data. */
    fun recover(): Boolean {
        val revision = snapshot.revision + 1
        val pending = runCatching { pendingRestore() }.getOrNull()
        if (pending == null) {
            snapshot = Snapshot(revision, Kind.ERROR, null, null, false, false)
            return false
        }
        if (pending && !restoreOwnedBit()) {
            snapshot = Snapshot(revision, Kind.ERROR, null, readFlags(), true, false)
            return false
        }
        val current = runCatching { readFlags() }.getOrNull()
        snapshot = Snapshot(revision, if (current == null) Kind.ERROR else Kind.INACTIVE,
            current, current, false, current != null)
        return current != null
    }

    fun start(expanded: Boolean): Boolean {
        if (!stop()) return false
        val revision = snapshot.revision + 1
        val before = runCatching { readFlags() }.getOrNull()
        if (before == null) {
            snapshot = Snapshot(revision, Kind.ERROR, null, null, false, false)
            return false
        }
        val changed = expanded && before and bit == 0
        if (changed && !runCatching { setPendingRestore(true) }.getOrDefault(false)) {
            snapshot = Snapshot(revision, Kind.ERROR, before, before, false, false)
            return false
        }
        val applied = !changed || runCatching { writeFlags(before or bit) }.getOrDefault(false)
        val actual = runCatching { readFlags() }.getOrNull()
        if (!applied || actual == null || (expanded && actual and bit == 0)) {
            snapshot = Snapshot(revision, Kind.ERROR, before, actual, changed, false)
            if (changed && restoreOwnedBit()) snapshot = snapshot.copy(changedByUs = false, ready = true)
            return false
        }
        val kind = if (expanded) Kind.EXPANDED else if (actual and bit != 0)
            Kind.STANDARD_ALREADY_INCLUDED else Kind.STANDARD
        snapshot = Snapshot(revision, kind, before, actual, changed, true)
        return true
    }

    fun stop(): Boolean {
        val old = snapshot
        val revision = old.revision + 1
        // Invalidate all old owners before any platform call can re-enter.
        snapshot = Snapshot(revision, Kind.INACTIVE, old.before, old.actual, old.changedByUs, false)
        val pending = runCatching { pendingRestore() }.getOrNull()
        val success = pending != null && (!pending || restoreOwnedBit())
        val actual = runCatching { readFlags() }.getOrNull()
        val ready = success && actual != null
        snapshot = Snapshot(revision, if (ready) Kind.INACTIVE else Kind.ERROR,
            old.before, actual, !success, ready)
        return ready
    }

    private fun restoreOwnedBit(): Boolean {
        val current = runCatching { readFlags() }.getOrNull() ?: return false
        if (current and bit != 0 && !runCatching { writeFlags(current and bit.inv()) }.getOrDefault(false)) return false
        val actual = runCatching { readFlags() }.getOrNull() ?: return false
        if (actual and bit != 0) return false
        return runCatching { setPendingRestore(false) }.getOrDefault(false)
    }
}
