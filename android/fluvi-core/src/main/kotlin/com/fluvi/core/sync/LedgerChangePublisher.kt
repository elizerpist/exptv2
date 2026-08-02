package com.fluvi.core.sync

import com.fluvi.core.database.entity.FluviLedgerEntryEntity

/**
 * The single semantic bridge between a changed ledger row and its durable
 * spreadsheet projection. Network delivery deliberately lives elsewhere.
 */
internal class LedgerChangePublisher(
    private val projection: LedgerSheetProjection,
    private val outbox: LedgerSyncOutboxRepository,
) {
    suspend fun project(entry: FluviLedgerEntryEntity): LedgerSheetRow =
        projection.project(entry)

    suspend fun publishUpsert(entry: FluviLedgerEntryEntity) {
        outbox.enqueueUpsert(project(entry))
    }

    suspend fun publishUpserts(entries: Iterable<FluviLedgerEntryEntity>) {
        outbox.enqueueUpserts(projection.projectBatch(entries))
    }

    suspend fun publishDelete(lastProjection: LedgerSheetRow) {
        outbox.enqueueDelete(lastProjection)
    }
}
