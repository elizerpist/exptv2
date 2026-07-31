package com.fluvi.core.repository

import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.model.FluviSystemIds

/**
 * Monotonic watermark for user-owned core state. Sync acknowledgements and
 * checkpoint transport bookkeeping intentionally do not advance it.
 */
internal class FluviCoreRevisionRepository(
    private val database: FluviDatabase,
) {
    private val settings = database.appSettingsDao()

    suspend fun current(): Long = requireNotNull(settings.current()) {
        "The Fluvi app settings row is missing."
    }.coreRevision

    suspend fun advance(updatedAtUtcMs: Long): Long {
        check(
            settings.incrementCoreRevision(
                settingsId = FluviSystemIds.APP_SETTINGS,
                updatedAtUtcMs = updatedAtUtcMs,
            ) == 1,
        ) {
            "Fluvi core revision update did not affect exactly one row."
        }
        return current()
    }
}
