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
import com.fluvi.core.query.FluviPeriodGroup
import com.fluvi.core.query.FluviPeriodSelection
import com.fluvi.core.query.FluviQueryRefinements
import com.fluvi.core.query.FluviQueryScope
import com.fluvi.core.query.FluviSavedQuery
import com.fluvi.core.repository.FluviQuerySnapshotRepository

/** Named saved Query configurations only. The current Query is never persisted implicitly. */
class FluviQuerySnapshotUseCase internal constructor(
    private val database: FluviDatabase,
    private val idGenerator: FluviIdGenerator,
    private val clock: FluviClock,
    private val repository: FluviQuerySnapshotRepository = FluviQuerySnapshotRepository(database),
) {
    suspend fun create(name: String, scope: FluviQueryScope): FluviSavedQuery = database.withTransaction {
        val normalizedName = name.trim().also {
            require(it.isNotEmpty()) { "A saved Query needs a name." }
        }
        val now = clock.nowUtcMs()
        val snapshotId = idGenerator.next()
        repository.insert(
            snapshot = FluviQuerySnapshotEntity(
                id = snapshotId,
                name = normalizedName,
                direction = scope.direction,
                formatVersion = FORMAT_VERSION,
                createdAtUtcMs = now,
                updatedAtUtcMs = now,
            ),
            periods = scope.periodEntities(snapshotId),
            categories = scope.categoryEntities(snapshotId),
            partners = scope.partnerEntities(snapshotId),
            refinements = scope.refinements.toEntities(snapshotId, idGenerator),
        )
        FluviSavedQuery(
            id = snapshotId,
            name = normalizedName,
            scope = scope,
            createdAtUtcMs = now,
            updatedAtUtcMs = now,
        )
    }

    suspend fun load(
        snapshotId: String,
        activeDirection: com.fluvi.core.model.LedgerDirection,
    ): FluviSavedQuery = database.withTransaction {
        loadSnapshot(repository.requireSnapshot(snapshotId), activeDirection)
    }

    suspend fun list(
        activeDirection: com.fluvi.core.model.LedgerDirection,
    ): List<FluviSavedQuery> = database.withTransaction {
        val snapshots = repository.allForDirection(activeDirection)
        snapshots.forEach(::requireSupportedFormat)
        val ids = snapshots.map { it.id }
        val periods = repository.periodsForSnapshots(ids).groupBy { it.snapshotId }
        val categories = repository.categoriesForSnapshots(ids).groupBy { it.snapshotId }
        val partners = repository.partnersForSnapshots(ids).groupBy { it.snapshotId }
        val refinements = repository.refinementsForSnapshots(ids).groupBy { it.snapshotId }
        snapshots.map { snapshot ->
            snapshot.toSavedQuery(
                periods = periods[snapshot.id].orEmpty(),
                categories = categories[snapshot.id].orEmpty(),
                partners = partners[snapshot.id].orEmpty(),
                refinements = refinements[snapshot.id].orEmpty(),
            )
        }
    }

    suspend fun update(snapshotId: String, name: String, scope: FluviQueryScope): FluviSavedQuery =
        database.withTransaction { updateInTransaction(snapshotId, name, scope) }

    suspend fun rename(snapshotId: String, name: String): FluviSavedQuery =
        database.withTransaction {
            val normalizedName = name.trim().also {
                require(it.isNotEmpty()) { "A saved Query needs a name." }
            }
            val now = clock.nowUtcMs()
            repository.rename(snapshotId, normalizedName, now)
            val renamed = repository.requireSnapshot(snapshotId)
            loadSnapshot(renamed, renamed.direction)
        }

    private suspend fun updateInTransaction(
        snapshotId: String,
        name: String,
        scope: FluviQueryScope,
    ): FluviSavedQuery {
        val normalizedName = name.trim().also {
            require(it.isNotEmpty()) { "A saved Query needs a name." }
        }
        val now = clock.nowUtcMs()
        repository.replaceConfiguration(
            snapshotId = snapshotId,
            name = normalizedName,
            scope = scope,
            updatedAtUtcMs = now,
            periods = scope.periodEntities(snapshotId),
            categories = scope.categoryEntities(snapshotId),
            partners = scope.partnerEntities(snapshotId),
            refinements = scope.refinements.toEntities(snapshotId, idGenerator),
        )
        return loadSnapshot(repository.requireSnapshot(snapshotId), scope.direction)
    }

    private suspend fun loadSnapshot(
        snapshot: FluviQuerySnapshotEntity,
        activeDirection: com.fluvi.core.model.LedgerDirection,
    ): FluviSavedQuery {
        require(snapshot.direction == activeDirection) {
            "A " + snapshot.direction.name + " Query snapshot cannot be active for " +
                activeDirection.name + "."
        }
        requireSupportedFormat(snapshot)
        return snapshot.toSavedQuery(
            periods = repository.periods(snapshot.id),
            categories = repository.categories(snapshot.id),
            partners = repository.partners(snapshot.id),
            refinements = repository.refinements(snapshot.id),
        )
    }

    private fun requireSupportedFormat(snapshot: FluviQuerySnapshotEntity) {
        require(snapshot.formatVersion == FORMAT_VERSION) {
            "Unsupported Fluvi Query snapshot format: " + snapshot.formatVersion
        }
    }

    private fun FluviQuerySnapshotEntity.toSavedQuery(
        periods: List<FluviQuerySnapshotPeriodEntity>,
        categories: List<FluviQuerySnapshotCategoryEntity>,
        partners: List<FluviQuerySnapshotPartnerEntity>,
        refinements: List<FluviQuerySnapshotRefinementEntity>,
    ): FluviSavedQuery =
        FluviSavedQuery(
            id = id,
            name = name,
            scope = FluviQueryScope(
                direction = direction,
                periodGroups = periods
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
                categoryIds = categories.mapTo(linkedSetOf()) { it.categoryId },
                partnerIds = partners.mapTo(linkedSetOf()) { it.partnerId },
                refinements = refinements.toRefinements(),
            ),
            createdAtUtcMs = this.createdAtUtcMs,
            updatedAtUtcMs = this.updatedAtUtcMs,
        )

    private fun FluviQueryScope.periodEntities(
        snapshotId: String,
    ): List<FluviQuerySnapshotPeriodEntity> = periodGroups.flatMap { group ->
        group.selections.map { selection ->
            FluviQuerySnapshotPeriodEntity(
                id = idGenerator.next(),
                snapshotId = snapshotId,
                groupKey = group.key,
                periodKind = selection.kind,
                periodValue = selection.value,
            )
        }
    }

    private fun FluviQueryScope.categoryEntities(
        snapshotId: String,
    ): List<FluviQuerySnapshotCategoryEntity> = categoryIds.sorted().map { categoryId ->
        FluviQuerySnapshotCategoryEntity(
            id = idGenerator.next(),
            snapshotId = snapshotId,
            categoryId = categoryId,
        )
    }

    private fun FluviQueryScope.partnerEntities(
        snapshotId: String,
    ): List<FluviQuerySnapshotPartnerEntity> = partnerIds.sorted().map { partnerId ->
        FluviQuerySnapshotPartnerEntity(
            id = idGenerator.next(),
            snapshotId = snapshotId,
            partnerId = partnerId,
        )
    }

    suspend fun delete(snapshotId: String) {
        database.withTransaction {
            repository.delete(snapshotId)
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
