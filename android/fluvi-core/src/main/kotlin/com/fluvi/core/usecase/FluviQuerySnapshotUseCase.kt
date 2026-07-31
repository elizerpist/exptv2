package com.fluvi.core.usecase

import androidx.room.withTransaction
import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.entity.FluviQuerySnapshotCategoryEntity
import com.fluvi.core.database.entity.FluviQuerySnapshotEntity
import com.fluvi.core.database.entity.FluviQuerySnapshotPartnerEntity
import com.fluvi.core.database.entity.FluviQuerySnapshotPeriodEntity
import com.fluvi.core.database.entity.FluviQuerySnapshotRefinementEntity
import com.fluvi.core.model.FluviClock
import com.fluvi.core.model.FluviIdGenerator
import com.fluvi.core.model.QueryRefinementKind
import com.fluvi.core.model.QuerySnapshotSlot
import com.fluvi.core.query.FluviPeriodGroup
import com.fluvi.core.query.FluviPeriodSelection
import com.fluvi.core.query.FluviQueryRefinements
import com.fluvi.core.query.FluviQueryScope
import com.fluvi.core.query.FluviSavedQuerySnapshot
import com.fluvi.core.repository.FluviQuerySnapshotRepository
import com.fluvi.core.repository.FluviCoreRevisionRepository

/** Saved snapshots only. The current unsaved Query has no persistence owner. */
class FluviQuerySnapshotUseCase internal constructor(
    private val database: FluviDatabase,
    private val idGenerator: FluviIdGenerator,
    private val clock: FluviClock,
    private val repository: FluviQuerySnapshotRepository = FluviQuerySnapshotRepository(database),
    private val revisionRepository: FluviCoreRevisionRepository = FluviCoreRevisionRepository(database),
) {
    suspend fun save(slot: QuerySnapshotSlot, scope: FluviQueryScope): String = database.withTransaction {
        repository.deleteBySlotIfPresent(slot)
        val now = clock.nowUtcMs()
        val snapshotId = idGenerator.next()
        repository.insert(
            snapshot = FluviQuerySnapshotEntity(
                id = snapshotId,
                slot = slot,
                direction = scope.direction,
                formatVersion = FORMAT_VERSION,
                createdAtUtcMs = now,
                updatedAtUtcMs = now,
            ),
            periods = scope.periodGroups.flatMap { group ->
                group.selections.map { selection ->
                    FluviQuerySnapshotPeriodEntity(
                        id = idGenerator.next(),
                        snapshotId = snapshotId,
                        groupKey = group.key,
                        periodKind = selection.kind,
                        periodValue = selection.value,
                    )
                }
            },
            categories = scope.categoryIds.sorted().map { categoryId ->
                FluviQuerySnapshotCategoryEntity(
                    id = idGenerator.next(),
                    snapshotId = snapshotId,
                    categoryId = categoryId,
                )
            },
            partners = scope.partnerIds.sorted().map { partnerId ->
                FluviQuerySnapshotPartnerEntity(
                    id = idGenerator.next(),
                    snapshotId = snapshotId,
                    partnerId = partnerId,
                )
            },
            refinements = scope.refinements.toEntities(snapshotId, idGenerator),
        )
        revisionRepository.advance(now)
        snapshotId
    }

    suspend fun load(
        snapshotId: String,
        activeDirection: com.fluvi.core.model.LedgerDirection,
    ): FluviSavedQuerySnapshot = database.withTransaction {
        loadSnapshot(repository.requireSnapshot(snapshotId), activeDirection)
    }

    suspend fun load(
        slot: QuerySnapshotSlot,
        activeDirection: com.fluvi.core.model.LedgerDirection,
    ): FluviSavedQuerySnapshot = database.withTransaction {
        loadSnapshot(repository.requireSnapshot(slot), activeDirection)
    }

    private suspend fun loadSnapshot(
        snapshot: FluviQuerySnapshotEntity,
        activeDirection: com.fluvi.core.model.LedgerDirection,
    ): FluviSavedQuerySnapshot {
        require(snapshot.direction == activeDirection) {
            "A " + snapshot.direction.name + " Query snapshot cannot be active for " +
                activeDirection.name + "."
        }
        require(snapshot.formatVersion == FORMAT_VERSION) {
            "Unsupported Fluvi Query snapshot format: " + snapshot.formatVersion
        }
        return FluviSavedQuerySnapshot(
            id = snapshot.id,
            slot = snapshot.slot,
            scope = FluviQueryScope(
                direction = snapshot.direction,
                periodGroups = repository.periods(snapshot.id)
                    .groupBy { it.groupKey }
                    .toSortedMap()
                    .map { (key, periods) ->
                        FluviPeriodGroup(
                            key = key,
                            selections = periods.mapTo(linkedSetOf()) { period ->
                                FluviPeriodSelection(period.periodKind, period.periodValue)
                            },
                        )
                    },
                categoryIds = repository.categories(snapshot.id).mapTo(linkedSetOf()) { it.categoryId },
                partnerIds = repository.partners(snapshot.id).mapTo(linkedSetOf()) { it.partnerId },
                refinements = repository.refinements(snapshot.id).toRefinements(),
            ),
        )
    }

    suspend fun delete(snapshotId: String) {
        database.withTransaction {
            repository.delete(snapshotId)
            revisionRepository.advance(clock.nowUtcMs())
        }
    }

    private fun FluviQueryRefinements.toEntities(
        snapshotId: String,
        ids: FluviIdGenerator,
    ): List<FluviQuerySnapshotRefinementEntity> = buildList {
        minimumAmountScaled100?.let { value ->
            add(
                FluviQuerySnapshotRefinementEntity(
                    id = ids.next(),
                    snapshotId = snapshotId,
                    refinementKind = QueryRefinementKind.minimumAmount,
                    valueText = null,
                    valueScaled100 = value,
                ),
            )
        }
        maximumAmountScaled100?.let { value ->
            add(
                FluviQuerySnapshotRefinementEntity(
                    id = ids.next(),
                    snapshotId = snapshotId,
                    refinementKind = QueryRefinementKind.maximumAmount,
                    valueText = null,
                    valueScaled100 = value,
                ),
            )
        }
        noteContains?.trim()?.takeIf { it.isNotEmpty() }?.let { value ->
            add(
                FluviQuerySnapshotRefinementEntity(
                    id = ids.next(),
                    snapshotId = snapshotId,
                    refinementKind = QueryRefinementKind.noteContains,
                    valueText = value,
                    valueScaled100 = null,
                ),
            )
        }
    }

    private fun List<FluviQuerySnapshotRefinementEntity>.toRefinements(): FluviQueryRefinements {
        fun one(kind: QueryRefinementKind): FluviQuerySnapshotRefinementEntity? =
            singleOrNull { it.refinementKind == kind }

        return FluviQueryRefinements(
            minimumAmountScaled100 = one(QueryRefinementKind.minimumAmount)?.valueScaled100,
            maximumAmountScaled100 = one(QueryRefinementKind.maximumAmount)?.valueScaled100,
            noteContains = one(QueryRefinementKind.noteContains)?.valueText,
        )
    }

    private companion object {
        const val FORMAT_VERSION = 1
    }
}
