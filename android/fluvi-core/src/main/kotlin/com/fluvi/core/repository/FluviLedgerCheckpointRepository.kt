package com.fluvi.core.repository

import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.entity.FluviLedgerBackupCheckpointEntity
import com.fluvi.core.model.CheckpointStatus

internal class FluviLedgerCheckpointRepository(
    private val database: FluviDatabase,
) {
    private val checkpoints = database.ledgerBackupCheckpointDao()

    suspend fun findById(checkpointId: String): FluviLedgerBackupCheckpointEntity? =
        checkpoints.findById(checkpointId)

    suspend fun requireById(checkpointId: String): FluviLedgerBackupCheckpointEntity = requireNotNull(
        checkpoints.findById(checkpointId),
    ) {
        "Unknown Fluvi backup checkpoint ID: " + checkpointId
    }

    suspend fun findByTriggerKey(triggerKey: String): FluviLedgerBackupCheckpointEntity? =
        checkpoints.findByTriggerKey(triggerKey)

    suspend fun insert(checkpoint: FluviLedgerBackupCheckpointEntity) {
        checkpoints.insert(checkpoint)
    }

    suspend fun markBundlePrepared(
        checkpointId: String,
        preparedBundlePath: String,
        updatedAtUtcMs: Long,
    ) {
        check(
            checkpoints.setPreparedBundlePath(
                checkpointId = checkpointId,
                preparedBundlePath = preparedBundlePath,
                updatedAtUtcMs = updatedAtUtcMs,
            ) == 1,
        ) {
            "Checkpoint bundle update did not affect exactly one row."
        }
    }

    suspend fun updateStatus(
        checkpointId: String,
        status: CheckpointStatus,
        remoteBackupFileId: String?,
        updatedAtUtcMs: Long,
    ) {
        check(
            checkpoints.updateStatus(
                checkpointId = checkpointId,
                status = status,
                remoteBackupFileId = remoteBackupFileId,
                updatedAtUtcMs = updatedAtUtcMs,
            ) == 1,
        ) {
            "Checkpoint status update did not affect exactly one row."
        }
    }
}
