package com.fluvi.core.sync

import androidx.room.withTransaction
import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.entity.FluviLedgerBackupCheckpointEntity
import com.fluvi.core.model.CheckpointKind
import com.fluvi.core.model.CheckpointRetentionClass
import com.fluvi.core.model.CheckpointStatus
import com.fluvi.core.model.FluviClock
import com.fluvi.core.model.FluviIdGenerator
import com.fluvi.core.repository.FluviCoreRevisionRepository
import com.fluvi.core.repository.FluviLedgerCheckpointRepository
import com.fluvi.core.repository.FluviLedgerDeletionArchiveRepository

data class LedgerCheckpointPreparation(
    val id: String,
    val kind: CheckpointKind,
    val sourceCoreRevision: Long,
    val preparedBundlePath: String?,
    val status: CheckpointStatus,
)

/**
 * Stores checkpoint intent and lifecycle metadata only. It never copies,
 * uploads, downloads, or restores a database; those are future adapter jobs.
 */
class LedgerCheckpointCoordinator internal constructor(
    private val database: FluviDatabase,
    private val idGenerator: FluviIdGenerator,
    private val clock: FluviClock,
    private val checkpointRepository: FluviLedgerCheckpointRepository =
        FluviLedgerCheckpointRepository(database),
    private val archiveRepository: FluviLedgerDeletionArchiveRepository =
        FluviLedgerDeletionArchiveRepository(database),
    private val revisionRepository: FluviCoreRevisionRepository =
        FluviCoreRevisionRepository(database),
) {
    suspend fun prepareDaily(localEpochDay: Long): LedgerCheckpointPreparation =
        database.withTransaction {
            val triggerKey = "daily:" + localEpochDay
            checkpointRepository.findByTriggerKey(triggerKey)?.toPreparation()
                ?: create(
                    kind = CheckpointKind.daily,
                    triggerKey = triggerKey,
                    retentionClass = CheckpointRetentionClass.automaticDaily,
                )
        }

    suspend fun prepareManual(): LedgerCheckpointPreparation = prepare(
        kind = CheckpointKind.manual,
        retentionClass = CheckpointRetentionClass.manual,
    )

    suspend fun prepareBeforeDestructive(): LedgerCheckpointPreparation = database.withTransaction {
        prepareBeforeDestructiveInTransaction()
    }

    /** Used by a destructive ledger write so checkpoint intent shares its transaction. */
    internal suspend fun prepareBeforeDestructiveInTransaction(): LedgerCheckpointPreparation {
        val checkpointId = idGenerator.next()
        return create(
            kind = CheckpointKind.beforeDestructive,
            triggerKey = CheckpointKind.beforeDestructive.name + ":" + checkpointId,
            retentionClass = CheckpointRetentionClass.automaticDaily,
            checkpointId = checkpointId,
        )
    }

    suspend fun prepareBeforeSchemaUpgrade(): LedgerCheckpointPreparation = prepare(
        kind = CheckpointKind.beforeSchemaUpgrade,
        retentionClass = CheckpointRetentionClass.automaticMonthly,
    )

    suspend fun markBundlePrepared(checkpointId: String, preparedBundlePath: String) {
        database.withTransaction {
            require(preparedBundlePath.isNotBlank()) { "Checkpoint bundle path must not be blank." }
            checkpointRepository.requireById(checkpointId)
            checkpointRepository.markBundlePrepared(
                checkpointId = checkpointId,
                preparedBundlePath = preparedBundlePath,
                updatedAtUtcMs = clock.nowUtcMs(),
            )
        }
    }

    suspend fun markAcknowledged(checkpointId: String, remoteBackupFileId: String?) {
        database.withTransaction {
            val checkpoint = checkpointRepository.requireById(checkpointId)
            val normalizedRemoteBackupFileId = remoteBackupFileId?.trim()?.ifEmpty { null }
            require(checkpoint.hasRestorableArtifact() || normalizedRemoteBackupFileId != null) {
                "An acknowledged checkpoint needs a prepared bundle or remote backup file ID."
            }
            checkpointRepository.updateStatus(
                checkpointId = checkpointId,
                status = CheckpointStatus.acknowledged,
                remoteBackupFileId = normalizedRemoteBackupFileId,
                updatedAtUtcMs = clock.nowUtcMs(),
            )
            archiveRepository.purgeForAcknowledgedCheckpoint(checkpointId)
        }
    }

    suspend fun markFailed(checkpointId: String) {
        database.withTransaction {
            checkpointRepository.requireById(checkpointId)
            checkpointRepository.updateStatus(
                checkpointId = checkpointId,
                status = CheckpointStatus.failed,
                remoteBackupFileId = null,
                updatedAtUtcMs = clock.nowUtcMs(),
            )
        }
    }

    /** Builds a guard plan; no restore is performed by this core. */
    suspend fun prepareRestore(targetCheckpointId: String): LedgerRestorePlan =
        database.withTransaction {
            val target = checkpointRepository.requireById(targetCheckpointId)
            require(target.status == CheckpointStatus.acknowledged) {
                "A restore target must be acknowledged before it can be used."
            }
            require(target.hasRestorableArtifact()) {
                "A restore target needs a prepared bundle or remote backup file ID."
            }
            LedgerRestorePlan(
                targetCheckpointId = target.id,
                preRestoreCheckpoint = create(
                    kind = CheckpointKind.beforeRestore,
                    triggerKey = "before-restore:" + idGenerator.next(),
                    retentionClass = CheckpointRetentionClass.automaticMonthly,
                ),
            )
        }

    private suspend fun prepare(
        kind: CheckpointKind,
        retentionClass: CheckpointRetentionClass,
    ): LedgerCheckpointPreparation = database.withTransaction {
        val checkpointId = idGenerator.next()
        create(
            kind = kind,
            triggerKey = kind.name + ":" + checkpointId,
            retentionClass = retentionClass,
            checkpointId = checkpointId,
        )
    }

    private suspend fun create(
        kind: CheckpointKind,
        triggerKey: String,
        retentionClass: CheckpointRetentionClass,
        checkpointId: String = idGenerator.next(),
    ): LedgerCheckpointPreparation {
        val now = clock.nowUtcMs()
        val checkpoint = FluviLedgerBackupCheckpointEntity(
            id = checkpointId,
            kind = kind,
            triggerKey = triggerKey,
            sourceCoreRevision = revisionRepository.current(),
            preparedBundlePath = null,
            remoteBackupFileId = null,
            retentionClass = retentionClass,
            status = CheckpointStatus.prepared,
            createdAtUtcMs = now,
            updatedAtUtcMs = now,
        )
        checkpointRepository.insert(checkpoint)
        return checkpoint.toPreparation()
    }

    private fun FluviLedgerBackupCheckpointEntity.toPreparation(): LedgerCheckpointPreparation =
        LedgerCheckpointPreparation(
            id = id,
            kind = kind,
            sourceCoreRevision = sourceCoreRevision,
            preparedBundlePath = preparedBundlePath,
            status = status,
        )

    private fun FluviLedgerBackupCheckpointEntity.hasRestorableArtifact(): Boolean =
        !preparedBundlePath.isNullOrBlank() || !remoteBackupFileId.isNullOrBlank()
}
