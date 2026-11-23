package com.fluvi.app.lockscreen.host

import android.content.Context

/**
 * The paired reference owner has its own opt-in state; it does not alter the
 * normal keyguard setting. A single synchronous preferences commit stores the
 * suppression bit and its epoch together before a handover may begin.
 */
internal class R29OwnershipStore(context: Context) : R29Ownership.Store {
    private val preferences = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    override fun read(): R29Ownership.Persisted = runCatching {
        val values = preferences.all
        if (values.isEmpty()) return@runCatching R29Ownership.Persisted(false, 0)
        val version = values[VERSION] as? Int
        val suppressed = values[SUPPRESSED] as? Boolean
        val epoch = values[EPOCH] as? Long
        if (version != 1 || suppressed == null || epoch == null || epoch < 0) {
            R29Ownership.Persisted(suppressed = true, epoch = 0, valid = false)
        } else {
            R29Ownership.Persisted(suppressed, epoch)
        }
    }.getOrElse { R29Ownership.Persisted(suppressed = true, epoch = 0, valid = false) }

    override fun write(value: R29Ownership.Persisted): Boolean {
        if (!value.valid || value.epoch < 0) return false
        return runCatching {
            preferences.edit().putInt(VERSION, 1)
                .putBoolean(SUPPRESSED, value.suppressed)
                .putLong(EPOCH, value.epoch)
                .commit()
        }.getOrDefault(false)
    }

    companion object {
        internal const val PREFS = "fluvi_r29_reference_ownership"
        internal const val VERSION = "version"
        internal const val SUPPRESSED = "suppressed"
        internal const val EPOCH = "epoch"
    }
}
