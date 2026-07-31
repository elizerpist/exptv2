package com.fluvi.core.repository

import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.entity.FluviLedgerSyncWorkspaceEntity
import com.fluvi.core.model.FluviClock
import com.fluvi.core.model.FluviIdGenerator

/** Persistent year-to-workspace mapping; it deliberately contains no API client. */
internal class FluviLedgerSyncWorkspaceRepository(
    private val database: FluviDatabase,
    private val idGenerator: FluviIdGenerator,
    private val clock: FluviClock,
) {
    private val workspaces = database.ledgerSyncWorkspaceDao()

    suspend fun assign(bookingYear: Int, workspaceIdentifier: String): FluviLedgerSyncWorkspaceEntity {
        require(bookingYear in 1_000..9_999) { "Booking year must have four digits." }
        val cleanedIdentifier = workspaceIdentifier.trim()
        require(cleanedIdentifier.isNotEmpty()) { "Workspace identifier must not be blank." }
        val now = clock.nowUtcMs()
        val existing = workspaces.findByBookingYear(bookingYear)
        val workspace = FluviLedgerSyncWorkspaceEntity(
            id = existing?.id ?: idGenerator.next(),
            bookingYear = bookingYear,
            workspaceIdentifier = cleanedIdentifier,
            createdAtUtcMs = existing?.createdAtUtcMs ?: now,
            updatedAtUtcMs = now,
        )
        workspaces.upsert(workspace)
        return workspace
    }

    suspend fun find(bookingYear: Int): FluviLedgerSyncWorkspaceEntity? =
        workspaces.findByBookingYear(bookingYear)
}
