package com.fluvi.core.usecase

import androidx.room.withTransaction
import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.model.FluviClock
import com.fluvi.core.model.FluviFinancialLimit
import com.fluvi.core.model.FluviFinancialLimitKey
import com.fluvi.core.repository.FluviCoreRevisionRepository
import com.fluvi.core.repository.FluviFinancialLimitRepository

/** Public typed CRUD boundary for future editors; it is never a render hot path. */
class FluviFinancialLimitUseCase internal constructor(
    private val database: FluviDatabase,
    private val clock: FluviClock,
    private val repository: FluviFinancialLimitRepository = FluviFinancialLimitRepository(database),
    private val revisionRepository: FluviCoreRevisionRepository = FluviCoreRevisionRepository(database),
) {
    suspend fun get(key: FluviFinancialLimitKey): FluviFinancialLimit? = database.withTransaction {
        repository.find(key)
    }

    suspend fun list(): List<FluviFinancialLimit> = database.withTransaction { repository.all() }

    suspend fun upsert(key: FluviFinancialLimitKey, amountScaled100: Long): FluviFinancialLimit {
        require(amountScaled100 >= 0L)
        return database.withTransaction {
            val now = clock.nowUtcMs()
            val previous = repository.find(key)
            if (previous?.amountScaled100 == amountScaled100) return@withTransaction previous
            val limit = FluviFinancialLimit(
                key = key,
                amountScaled100 = amountScaled100,
                createdAtUtcMs = previous?.createdAtUtcMs ?: now,
                updatedAtUtcMs = now,
            )
            repository.upsert(limit)
            revisionRepository.advance(now)
            limit
        }
    }

    /** One YEAR interaction mutates a complete twelve-month override vector
     * atomically. The returned values reflect one revision advance, never a
     * sequence of externally observable partial years. */
    suspend fun upsertBatch(values: List<Pair<FluviFinancialLimitKey, Long>>): List<FluviFinancialLimit> {
        require(values.isNotEmpty())
        require(values.map { it.first }.toSet().size == values.size) {
            "A financial-limit batch cannot contain duplicate keys."
        }
        require(values.all { it.second >= 0L })
        return database.withTransaction {
            val now = clock.nowUtcMs()
            val previousByKey = values.associate { (key, _) ->
                key to repository.find(key)
            }
            val limits = values.map { (key, amount) ->
                val previous = previousByKey.getValue(key)
                FluviFinancialLimit(
                    key = key,
                    amountScaled100 = amount,
                    createdAtUtcMs = previous?.createdAtUtcMs ?: now,
                    updatedAtUtcMs = now,
                )
            }
            val changed = limits.filter { limit ->
                previousByKey.getValue(limit.key)?.amountScaled100 != limit.amountScaled100
            }
            if (changed.isNotEmpty()) {
                repository.upsertAll(changed)
                revisionRepository.advance(now)
            }
            limits
        }
    }

    suspend fun delete(key: FluviFinancialLimitKey): Boolean = database.withTransaction {
        val deleted = repository.delete(key)
        if (deleted) revisionRepository.advance(clock.nowUtcMs())
        deleted
    }
}
