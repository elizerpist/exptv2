package com.fluvi.core.sync

import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.entity.FluviLedgerSyncOutboxEntity
import com.fluvi.core.model.FluviClock
import com.fluvi.core.model.LedgerSyncOperation
import java.security.MessageDigest

internal class LedgerSyncOutboxRepository(
    private val database: FluviDatabase,
    private val clock: FluviClock,
) {
    private val outbox = database.ledgerSyncOutboxDao()

    suspend fun enqueueUpsert(row: LedgerSheetRow) {
        enqueue(
            entryId = row.entryId,
            operation = LedgerSyncOperation.upsert,
            payloadJson = row.toPayloadJson(),
            revision = row.revision,
        )
    }

    suspend fun enqueueUpserts(rows: Iterable<LedgerSheetRow>) {
        val now = clock.nowUtcMs()
        val operations = rows.map { row ->
            val payloadJson = row.toPayloadJson()
            FluviLedgerSyncOutboxEntity(
                entryId = row.entryId,
                operation = LedgerSyncOperation.upsert,
                payloadJson = payloadJson,
                payloadHash = payloadJson.sha256Hex(),
                revision = row.revision,
                attemptCount = 0,
                nextAttemptAtUtcMs = null,
                createdAtUtcMs = now,
                updatedAtUtcMs = now,
            )
        }
        if (operations.isNotEmpty()) outbox.upsertAll(operations)
    }

    suspend fun enqueueDelete(row: LedgerSheetRow) {
        enqueue(
            entryId = row.entryId,
            operation = LedgerSyncOperation.delete,
            payloadJson = row.toPayloadJson(),
            revision = row.revision,
        )
    }

    suspend fun pendingFor(entryId: String): List<FluviLedgerSyncOutboxEntity> =
        listOfNotNull(outbox.pendingFor(entryId))

    suspend fun acknowledge(entryId: String) {
        outbox.acknowledge(entryId)
    }

    suspend fun deleteAll(entryIds: List<String>) {
        if (entryIds.isNotEmpty()) outbox.deleteAll(entryIds)
    }

    private suspend fun enqueue(
        entryId: String,
        operation: LedgerSyncOperation,
        payloadJson: String,
        revision: Long,
    ) {
        val now = clock.nowUtcMs()
        outbox.upsert(
            FluviLedgerSyncOutboxEntity(
                entryId = entryId,
                operation = operation,
                payloadJson = payloadJson,
                payloadHash = payloadJson.sha256Hex(),
                revision = revision,
                attemptCount = 0,
                nextAttemptAtUtcMs = null,
                createdAtUtcMs = now,
                updatedAtUtcMs = now,
            ),
        )
    }

    private fun String.sha256Hex(): String = MessageDigest
        .getInstance("SHA-256")
        .digest(toByteArray())
        .joinToString(separator = "") { byte ->
            (byte.toInt() and 0xff).toString(16).padStart(2, '0')
        }
}
