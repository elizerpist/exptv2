package com.fluvi.core

import android.content.Context
import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.FluviDatabaseFactory
import com.fluvi.core.model.FluviClock
import com.fluvi.core.model.FluviIdGenerator
import com.fluvi.core.model.MonotonicUlidGenerator
import com.fluvi.core.model.SystemFluviClock
import com.fluvi.core.query.FluviLedgerReadService
import com.fluvi.core.repository.FluviCategoryRepository
import com.fluvi.core.repository.FluviLedgerDeletionArchiveRepository
import com.fluvi.core.repository.FluviLedgerRepository
import com.fluvi.core.repository.FluviPartnerRepository
import com.fluvi.core.sync.LedgerChangePublisher
import com.fluvi.core.sync.LedgerCheckpointCoordinator
import com.fluvi.core.sync.LedgerSheetProjection
import com.fluvi.core.sync.LedgerSyncOutboxRepository
import com.fluvi.core.usecase.FluviCategoryUseCase
import com.fluvi.core.usecase.FluviLedgerWriteUseCase
import com.fluvi.core.usecase.FluviPartnerUseCase
import com.fluvi.core.usecase.FluviQuerySnapshotUseCase

/**
 * The supported Fluvi integration surface. It exposes typed operations while
 * keeping Room, DAOs, repositories, and transaction wiring inside this module.
 */
class FluviCore internal constructor(
    private val database: FluviDatabase,
    val categories: FluviCategoryUseCase,
    val partners: FluviPartnerUseCase,
    val ledger: FluviLedgerWriteUseCase,
    val query: FluviLedgerReadService,
    val snapshots: FluviQuerySnapshotUseCase,
    val checkpoints: LedgerCheckpointCoordinator,
) : AutoCloseable {
    override fun close() {
        database.close()
    }
}

/** Creates the only supported entry point for the clean Fluvi core. */
object FluviCoreFactory {
    @JvmOverloads
    fun create(
        context: Context,
        clock: FluviClock = SystemFluviClock,
        idGenerator: FluviIdGenerator = MonotonicUlidGenerator(clock),
    ): FluviCore = assemble(
        database = FluviDatabaseFactory.create(context, clock),
        clock = clock,
        idGenerator = idGenerator,
    )

    /** Test-oriented in-memory core with the same public write boundary. */
    @JvmOverloads
    fun createInMemory(
        context: Context,
        clock: FluviClock = SystemFluviClock,
        idGenerator: FluviIdGenerator = MonotonicUlidGenerator(clock),
    ): FluviCore = assemble(
        database = FluviDatabaseFactory.createInMemory(context, clock),
        clock = clock,
        idGenerator = idGenerator,
    )

    private fun assemble(
        database: FluviDatabase,
        clock: FluviClock,
        idGenerator: FluviIdGenerator,
    ): FluviCore {
        val categories = FluviCategoryRepository(database)
        val partners = FluviPartnerRepository(database)
        val ledger = FluviLedgerRepository(database)
        val outbox = LedgerSyncOutboxRepository(database, clock)
        val projection = LedgerSheetProjection(
            partnerRepository = partners,
            categoryRepository = categories,
        )
        val publisher = LedgerChangePublisher(projection, outbox)
        val checkpoints = LedgerCheckpointCoordinator(
            database = database,
            idGenerator = idGenerator,
            clock = clock,
        )

        return FluviCore(
            database = database,
            categories = FluviCategoryUseCase(
                database = database,
                repository = categories,
                ledgerRepository = ledger,
                changePublisher = publisher,
                idGenerator = idGenerator,
                clock = clock,
            ),
            partners = FluviPartnerUseCase(
                database = database,
                repository = partners,
                categoryRepository = categories,
                ledgerRepository = ledger,
                changePublisher = publisher,
                idGenerator = idGenerator,
                clock = clock,
            ),
            ledger = FluviLedgerWriteUseCase(
                database = database,
                ledgerRepository = ledger,
                archiveRepository = FluviLedgerDeletionArchiveRepository(database),
                partnerRepository = partners,
                categoryRepository = categories,
                changePublisher = publisher,
                checkpointCoordinator = checkpoints,
                idGenerator = idGenerator,
                clock = clock,
            ),
            query = FluviLedgerReadService(
                database = database,
                partnerRepository = partners,
                categoryRepository = categories,
            ),
            snapshots = FluviQuerySnapshotUseCase(
                database = database,
                idGenerator = idGenerator,
                clock = clock,
            ),
            checkpoints = checkpoints,
        )
    }
}
