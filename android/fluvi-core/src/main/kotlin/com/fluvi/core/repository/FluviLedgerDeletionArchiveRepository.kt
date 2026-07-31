package com.fluvi.core.repository

import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.entity.FluviLedgerDeletionArchiveEntity

internal class FluviLedgerDeletionArchiveRepository(
    private val database: FluviDatabase,
) {
    private val archive = database.ledgerDeletionArchiveDao()

    suspend fun upsert(entity: FluviLedgerDeletionArchiveEntity) {
        archive.upsert(entity)
    }

    suspend fun purgeForAcknowledgedCheckpoint(checkpointId: String): Int =
        archive.purgeForAcknowledgedCheckpoint(checkpointId)
}
