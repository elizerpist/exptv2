package com.fluvi.core.query

import androidx.sqlite.db.SimpleSQLiteQuery
import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.dao.FluviLedgerAggregateBucketRow
import com.fluvi.core.database.entity.FluviCategoryEntity
import com.fluvi.core.database.entity.FluviLedgerEntryEntity
import com.fluvi.core.database.entity.FluviPartnerEntity
import com.fluvi.core.model.QueryPeriodKind
import com.fluvi.core.repository.FluviCategoryRepository
import com.fluvi.core.repository.FluviPartnerRepository
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.mapLatest

/**
 * Read-only SQL boundary for the later Query screen. It intentionally returns
 * bounded pages and aggregates rather than a materialized ledger list.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class FluviLedgerReadService internal constructor(
    private val database: FluviDatabase,
    private val partnerRepository: FluviPartnerRepository,
    private val categoryRepository: FluviCategoryRepository,
    private val childPreviewCheckpoint: suspend () -> Unit = {
        currentCoroutineContext().ensureActive()
    },
) {
    private val ledger = database.ledgerDao()

    suspend fun timeline(
        scope: FluviQueryScope,
        after: FluviTimelineCursor? = null,
        pageSize: Int = DEFAULT_PAGE_SIZE,
    ): FluviLedgerTimelinePage<FluviLedgerEntryEntity> =
        queryTimelinePage(scope, after, pageSize).page

    private suspend fun queryTimelinePage(
        scope: FluviQueryScope,
        after: FluviTimelineCursor? = null,
        pageSize: Int = DEFAULT_PAGE_SIZE,
    ): MaterializedTimelinePage {
        require(pageSize in 1..MAX_PAGE_SIZE) { "Page size must be between 1 and 200." }
        val where = where(scope, after)
        val args = where.arguments.toMutableList()
        args += pageSize + 1
        val rows = ledger.queryEntries(
            SimpleSQLiteQuery(
                "SELECT * FROM fluvi_ledger_entries " + where.sql +
                    " ORDER BY booked_local_epoch_day DESC, booked_local_time_minutes DESC, id DESC " +
                    "LIMIT ?",
                args.toTypedArray(),
            ),
        )
        val pageEntries = rows.take(pageSize)
        val nextCursor = if (rows.size > pageSize) {
            pageEntries.last().toCursor()
        } else {
            null
        }
        return MaterializedTimelinePage(
            page = FluviLedgerTimelinePage(pageEntries, nextCursor),
            materializedRowCount = rows.size,
        )
    }

    suspend fun total(scope: FluviQueryScope): FluviLedgerTotal {
        val where = where(scope)
        val row = ledger.queryAggregate(
            SimpleSQLiteQuery(
                "SELECT COUNT(*) AS entry_count, " +
                    "COALESCE(SUM(amount_scaled_100), 0) AS amount_scaled_100 " +
                    "FROM fluvi_ledger_entries " + where.sql,
                where.arguments.toTypedArray(),
            ),
        )
        return FluviLedgerTotal(row.entryCount, row.amountScaled100)
    }

    suspend fun readSlice(
        scope: FluviQueryScope,
        pageSize: Int = DEFAULT_PAGE_SIZE,
        after: FluviTimelineCursor? = null,
    ): FluviDashboardLedgerSlice {
        val aggregate = total(scope)
        val page = timeline(scope, after, pageSize)
        val categories = categoryRepository.allEntities().associateBy { it.id }
        val partners = partnerRepository.allEntities().associateBy { it.id }
        val rows = page.entries.map { it.toDashboardRow(categories, partners) }
        val coreRevision = currentCoreRevision()
        return FluviDashboardLedgerSlice(
            queryKey = scope.canonicalKey,
            coreRevision = coreRevision,
            direction = scope.direction,
            timeScopeKey = scope.timeCanonicalKey,
            totalMinor = aggregate.amountScaled100,
            entryCount = aggregate.entryCount,
            entries = rows,
            nextCursor = page.nextCursor,
        )
    }

    fun observeSlice(
        scope: FluviQueryScope,
        pageSize: Int = DEFAULT_PAGE_SIZE,
    ): Flow<FluviDashboardLedgerSlice> = database.appSettingsDao()
        .observeCoreRevision()
        .distinctUntilChanged()
        .mapLatest { readSlice(scope, pageSize = pageSize) }

    /**
     * Stable, payload-light invalidation owner for dashboard caches.
     *
     * Unlike [observeSlice], this flow never executes an exact-scope query or
     * materializes ledger rows when the user changes the visible child.
     */
    fun observeCoreRevision(): Flow<Long> = database.appSettingsDao()
        .observeCoreRevision()
        .distinctUntilChanged()

    suspend fun currentCoreRevision(): Long = requireNotNull(
        database.appSettingsDao().current(),
    ) { "The Fluvi app settings row is missing." }.coreRevision

    suspend fun summaryByCategory(scope: FluviQueryScope): List<FluviLedgerGroupedSummary> =
        groupedSummary(scope, "category_id")

    suspend fun summaryByPartner(scope: FluviQueryScope): List<FluviLedgerGroupedSummary> =
        groupedSummary(scope, "partner_id")

    /**
     * Returns a compact, sparse summary index for direct children of a time
     * parent. The predicate is intentionally the same [where] predicate used
     * by totals, pages and all other summaries; Flutter never aggregates
     * detailed rows for a rail preview.
     *
     * `booked_local_epoch_day` already stores a local civil date. Formatting
     * that day value as UTC therefore preserves the persisted Europe/Budapest
     * calendar bucket without applying a second timezone conversion.
     */
    suspend fun timeChildSummaryIndex(
        scope: FluviQueryScope,
        childPeriodKind: QueryPeriodKind,
    ): FluviDashboardTimeChildSummaryIndex {
        requireValidChildSummaryParent(scope, childPeriodKind)
        val values = queryTimeChildAggregateRows(scope, childPeriodKind).map { row ->
            val childScope = scope.copy(
                periodGroups = listOf(
                    FluviPeriodGroup(
                        key = "time",
                        selections = setOf(
                            FluviPeriodSelection(childPeriodKind, row.groupId),
                        ),
                    ),
                ),
            )
            FluviDashboardTimeChildSummary(
                childPeriodValue = row.groupId,
                childQueryKey = childScope.canonicalKey,
                totalMinor = row.amountScaled100,
                entryCount = row.entryCount,
            )
        }
        return FluviDashboardTimeChildSummaryIndex(
            parentQueryKey = scope.canonicalKey,
            direction = scope.direction,
            childPeriodKind = childPeriodKind,
            coreRevision = currentCoreRevision(),
            isComplete = true,
            values = values,
        )
    }

    /**
     * Reads one SQL aggregate index and at most `previewPageSize + 1` rows for
     * each non-empty child. No full parent transaction list crosses the Room
     * boundary or gets grouped in Kotlin.
     */
    suspend fun childPreviewBundle(
        scope: FluviQueryScope,
        childPeriodKind: QueryPeriodKind,
        previewPageSize: Int = DEFAULT_PAGE_SIZE,
    ): FluviDashboardChildPreviewBundle {
        require(previewPageSize in 1..MAX_PAGE_SIZE) {
            "Preview page size must be between 1 and 200."
        }
        requireValidChildSummaryParent(scope, childPeriodKind)
        val queryStartedAtNanos = System.nanoTime()
        val aggregateRows = queryTimeChildAggregateRows(scope, childPeriodKind)
        childPreviewCheckpoint()
        val aggregatesByValue = aggregateRows.associateBy { it.groupId }
        val childValues = (aggregatesByValue.keys + finiteChildValues(scope, childPeriodKind))
            .toSortedSet()
        val pagesByValue = linkedMapOf<String, MaterializedTimelinePage>()
        childValues.forEach { childPeriodValue ->
            childPreviewCheckpoint()
            pagesByValue[childPeriodValue] = if (aggregatesByValue[childPeriodValue] == null) {
                MaterializedTimelinePage(
                    page = FluviLedgerTimelinePage(emptyList(), null),
                    materializedRowCount = 0,
                )
            } else {
                queryTimelinePage(
                    scope = childScope(scope, childPeriodKind, childPeriodValue),
                    pageSize = previewPageSize,
                )
            }
        }
        val categories = categoryRepository.allEntities().associateBy { it.id }
        val partners = partnerRepository.allEntities().associateBy { it.id }
        val coreRevision = currentCoreRevision()
        val queryDurationNanos = System.nanoTime() - queryStartedAtNanos

        val mappingStartedAtNanos = System.nanoTime()
        val coroutineContext = currentCoroutineContext()
        val children = childValues.map { childPeriodValue ->
            coroutineContext.ensureActive()
            val childScope = childScope(scope, childPeriodKind, childPeriodValue)
            val aggregate = aggregatesByValue[childPeriodValue]
            val page = pagesByValue.getValue(childPeriodValue).page
            val mappedRows = page.entries.map { entry ->
                coroutineContext.ensureActive()
                entry.toDashboardRow(categories, partners)
            }
            FluviDashboardChildPreview(
                childPeriodValue = childPeriodValue,
                slice = FluviDashboardLedgerSlice(
                    queryKey = childScope.canonicalKey,
                    coreRevision = coreRevision,
                    direction = scope.direction,
                    timeScopeKey = childScope.timeCanonicalKey,
                    totalMinor = aggregate?.amountScaled100 ?: 0L,
                    entryCount = aggregate?.entryCount ?: 0L,
                    entries = mappedRows,
                    nextCursor = page.nextCursor,
                ),
            )
        }
        val mappingDurationNanos = System.nanoTime() - mappingStartedAtNanos
        return FluviDashboardChildPreviewBundle(
            parentQueryKey = scope.canonicalKey,
            direction = scope.direction,
            childPeriodKind = childPeriodKind,
            coreRevision = coreRevision,
            previewPageSize = previewPageSize,
            children = children,
            buildMetrics = FluviDashboardChildPreviewBuildMetrics(
                aggregateBucketCount = aggregateRows.size,
                materializedPreviewRowCount = pagesByValue.values.sumOf {
                    it.materializedRowCount
                },
                queryDurationNanos = queryDurationNanos,
                mappingDurationNanos = mappingDurationNanos,
            ),
        )
    }

    private fun finiteChildValues(
        scope: FluviQueryScope,
        childPeriodKind: QueryPeriodKind,
    ): List<String> {
        val selection = scope.periodGroups.singleOrNull()
            ?.takeIf { it.key == "time" }
            ?.selections
            ?.singleOrNull()
        return when {
            childPeriodKind == QueryPeriodKind.month &&
                selection?.kind == QueryPeriodKind.year ->
                (1..12).map { "%04d-%02d".format(selection.value.toInt(), it) }
            childPeriodKind == QueryPeriodKind.day &&
                selection?.kind == QueryPeriodKind.month -> {
                val parts = selection.value.split('-')
                val days = java.time.YearMonth.of(parts[0].toInt(), parts[1].toInt())
                    .lengthOfMonth()
                (1..days).map { "%s-%02d".format(selection.value, it) }
            }
            else -> emptyList()
        }
    }

    private fun childScope(
        parent: FluviQueryScope,
        childPeriodKind: QueryPeriodKind,
        childPeriodValue: String,
    ): FluviQueryScope = parent.copy(
        periodGroups = listOf(
            FluviPeriodGroup(
                key = "time",
                selections = setOf(
                    FluviPeriodSelection(childPeriodKind, childPeriodValue),
                ),
            ),
        ),
    )

    /**
     * The time menu is deliberately evaluated before category and Partner
     * selection. It exposes only IDs represented by that temporal slice.
     */
    suspend fun timePrefilteredFacets(
        direction: com.fluvi.core.model.LedgerDirection,
        periodGroups: List<FluviPeriodGroup>,
    ): FluviTimePrefilteredFacets {
        val timeScope = FluviQueryScope(direction = direction, periodGroups = periodGroups)
        val where = where(timeScope)
        val categoryIds = ledger.queryStringIds(
            SimpleSQLiteQuery(
                "SELECT DISTINCT category_id AS id FROM fluvi_ledger_entries " + where.sql +
                    " ORDER BY category_id ASC",
                where.arguments.toTypedArray(),
            ),
        ).mapTo(linkedSetOf()) { it.id }
        val rawPartnerIds = ledger.queryStringIds(
            SimpleSQLiteQuery(
                "SELECT DISTINCT partner_id AS id FROM fluvi_ledger_entries " + where.sql +
                    " ORDER BY partner_id ASC",
                where.arguments.toTypedArray(),
            ),
        ).map { it.id }
        val canonicalPartnerIds = rawPartnerIds.mapTo(linkedSetOf()) { partnerId ->
            partnerRepository.resolveCanonicalPartnerId(partnerId)
        }

        // Resolve the references now so a dangling foreign key can never be
        // silently returned to a later UI adapter.
        categoryIds.forEach { categoryRepository.requireById(it) }
        canonicalPartnerIds.forEach { partnerRepository.requireById(it) }
        return FluviTimePrefilteredFacets(categoryIds, canonicalPartnerIds)
    }

    private suspend fun groupedSummary(
        scope: FluviQueryScope,
        groupColumn: String,
    ): List<FluviLedgerGroupedSummary> {
        val where = where(scope)
        return ledger.queryAggregateBuckets(
            SimpleSQLiteQuery(
                "SELECT " + groupColumn + " AS group_id, COUNT(*) AS entry_count, " +
                    "COALESCE(SUM(amount_scaled_100), 0) AS amount_scaled_100 " +
                    "FROM fluvi_ledger_entries " + where.sql + " GROUP BY " + groupColumn +
                    " ORDER BY amount_scaled_100 DESC, group_id ASC",
                where.arguments.toTypedArray(),
            ),
        ).map { row ->
            FluviLedgerGroupedSummary(
                id = row.groupId,
                entryCount = row.entryCount,
                amountScaled100 = row.amountScaled100,
            )
        }
    }

    private suspend fun queryTimeChildAggregateRows(
        scope: FluviQueryScope,
        childPeriodKind: QueryPeriodKind,
    ): List<FluviLedgerAggregateBucketRow> {
        val where = where(scope)
        val bucketExpression = when (childPeriodKind) {
            QueryPeriodKind.year ->
                "strftime('%Y', booked_local_epoch_day * 86400, 'unixepoch')"
            QueryPeriodKind.month ->
                "strftime('%Y-%m', booked_local_epoch_day * 86400, 'unixepoch')"
            QueryPeriodKind.day ->
                "strftime('%Y-%m-%d', booked_local_epoch_day * 86400, 'unixepoch')"
        }
        return ledger.queryAggregateBuckets(
            SimpleSQLiteQuery(
                "SELECT $bucketExpression AS group_id, COUNT(*) AS entry_count, " +
                    "COALESCE(SUM(amount_scaled_100), 0) AS amount_scaled_100 " +
                    "FROM fluvi_ledger_entries " + where.sql +
                    " GROUP BY $bucketExpression ORDER BY group_id ASC",
                where.arguments.toTypedArray(),
            ),
        )
    }

    private fun requireValidChildSummaryParent(
        scope: FluviQueryScope,
        childPeriodKind: QueryPeriodKind,
    ) {
        val selections = scope.periodGroups.singleOrNull()
            ?.takeIf { it.key == "time" }
            ?.selections
            ?.singleOrNull()
        val valid = when (childPeriodKind) {
            QueryPeriodKind.year -> scope.periodGroups.isEmpty()
            QueryPeriodKind.month -> selections?.kind == QueryPeriodKind.year
            QueryPeriodKind.day -> selections?.kind == QueryPeriodKind.month
        }
        require(valid) {
            "Child period $childPeriodKind is incompatible with parent scope " +
                scope.timeCanonicalKey
        }
    }

    private suspend fun where(
        scope: FluviQueryScope,
        after: FluviTimelineCursor? = null,
    ): SqlWhere {
        val clauses = mutableListOf<String>()
        val arguments = mutableListOf<Any>()
        clauses += "direction = ?"
        arguments += scope.direction.name

        scope.periodGroups.forEach { group ->
            val groupClauses = group.selections
                .sortedWith(compareBy({ it.kind.name }, { it.value }))
                .map { selection ->
                    arguments += selection.value
                    when (selection.kind) {
                        QueryPeriodKind.year ->
                            "strftime('%Y', booked_local_epoch_day * 86400, 'unixepoch') = ?"
                        QueryPeriodKind.month ->
                            "strftime('%Y-%m', booked_local_epoch_day * 86400, 'unixepoch') = ?"
                        QueryPeriodKind.day ->
                            "strftime('%Y-%m-%d', booked_local_epoch_day * 86400, 'unixepoch') = ?"
                    }
                }
            clauses += "(" + groupClauses.joinToString(" OR ") + ")"
        }

        scope.categoryIds.sorted().takeIf { it.isNotEmpty() }?.let { categoryIds ->
            clauses += "category_id IN (" + categoryIds.placeholders() + ")"
            arguments.addAll(categoryIds)
        }
        expandedPartnerIds(scope.partnerIds).sorted().takeIf { it.isNotEmpty() }?.let { partnerIds ->
            clauses += "partner_id IN (" + partnerIds.placeholders() + ")"
            arguments.addAll(partnerIds)
        }
        scope.refinements.minimumAmountScaled100?.let { minimum ->
            clauses += "amount_scaled_100 >= ?"
            arguments += minimum
        }
        scope.refinements.maximumAmountScaled100?.let { maximum ->
            clauses += "amount_scaled_100 <= ?"
            arguments += maximum
        }
        scope.refinements.noteContains?.trim()?.takeIf { it.isNotEmpty() }?.let { needle ->
            clauses += "COALESCE(note, '') LIKE ? ESCAPE '\\'"
            arguments += "%" + needle.escapeForLike() + "%"
        }
        after?.let { cursor ->
            clauses += "(booked_local_epoch_day < ? OR " +
                "(booked_local_epoch_day = ? AND booked_local_time_minutes < ?) OR " +
                "(booked_local_epoch_day = ? AND booked_local_time_minutes = ? AND id < ?))"
            arguments += cursor.bookedLocalEpochDay
            arguments += cursor.bookedLocalEpochDay
            arguments += cursor.bookedLocalTimeMinutes
            arguments += cursor.bookedLocalEpochDay
            arguments += cursor.bookedLocalTimeMinutes
            arguments += cursor.entryId
        }
        return SqlWhere("WHERE " + clauses.joinToString(" AND "), arguments)
    }

    private val FluviQueryScope.canonicalKey: String
        get() = listOf(
            direction.name,
            timeCanonicalKey,
            "categories:${categoryIds.sorted().joinToString(",")}",
            "partners:${partnerIds.sorted().joinToString(",")}",
            "refinements:${refinements.canonicalKey}",
        ).joinToString("|")

    private val FluviQueryScope.timeCanonicalKey: String
        get() = if (periodGroups.size == 1 && periodGroups.single().key == "time") {
            periodGroups.single().selections.singleOrNull()?.canonicalKey
                ?: periodGroups.single().selections
                    .sortedWith(compareBy({ it.kind.name }, { it.value }))
                    .joinToString(",") { it.canonicalKey }
        } else {
            periodGroups.sortedBy { it.key }.joinToString(";") { group ->
                group.key + "=" + group.selections
                    .sortedWith(compareBy({ it.kind.name }, { it.value }))
                    .joinToString(",") { it.canonicalKey }
            }
        }.ifEmpty { "all" }

    private val FluviPeriodSelection.canonicalKey: String
        get() = when (kind) {
            QueryPeriodKind.year -> "year:$value"
            QueryPeriodKind.month -> "month:$value"
            QueryPeriodKind.day -> "day:$value"
        }

    private val FluviQueryRefinements.canonicalKey: String
        get() = listOfNotNull(
            minimumAmountScaled100?.let { "minimumAmountScaled100=$it" },
            maximumAmountScaled100?.let { "maximumAmountScaled100=$it" },
            noteContains?.let { "noteContains=$it" },
        ).joinToString(",")

    private suspend fun expandedPartnerIds(selectedPartnerIds: Set<String>): Set<String> {
        val expanded = linkedSetOf<String>()
        selectedPartnerIds.sorted().forEach { selectedPartnerId ->
            val canonicalId = partnerRepository.resolveCanonicalPartnerId(selectedPartnerId)
            expanded += partnerRepository.partnerIdsResolvingTo(canonicalId)
        }
        return expanded
    }

    private fun Collection<String>.placeholders(): String = joinToString(",") { "?" }

    private fun String.escapeForLike(): String =
        replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")

    private fun FluviLedgerEntryEntity.toCursor(): FluviTimelineCursor = FluviTimelineCursor(
        bookedLocalEpochDay = bookedLocalEpochDay,
        bookedLocalTimeMinutes = bookedLocalTimeMinutes,
        entryId = id,
    )

    private fun FluviLedgerEntryEntity.toDashboardRow(
        categories: Map<String, FluviCategoryEntity>,
        partners: Map<String, FluviPartnerEntity>,
    ): FluviDashboardLedgerRow {
        val category = requireNotNull(categories[categoryId]) {
            "Unknown category ID in dashboard row: $categoryId"
        }
        val partner = requireNotNull(partners[partnerId]) {
            "Unknown partner ID in dashboard row: $partnerId"
        }
        return FluviDashboardLedgerRow(
            entryId = id,
            direction = direction,
            amountMinor = amountScaled100,
            bookedLocalEpochDay = bookedLocalEpochDay,
            bookedLocalTimeMinutes = bookedLocalTimeMinutes,
            occurredAtUtcMs = occurredAtUtcMs,
            partnerId = partnerId,
            partnerDisplayName = partner.displayNameOverride ?: partner.originalName,
            categoryId = category.id,
            categoryDisplayName = category.name,
            categoryColorId = category.colorId,
            categoryIconId = category.iconId,
            assignmentMode = categoryAssignmentMode,
            originKind = originKind,
            note = note,
        )
    }

    private data class MaterializedTimelinePage(
        val page: FluviLedgerTimelinePage<FluviLedgerEntryEntity>,
        val materializedRowCount: Int,
    )

    private data class SqlWhere(
        val sql: String,
        val arguments: List<Any>,
    )

    private companion object {
        const val DEFAULT_PAGE_SIZE = 50
        const val MAX_PAGE_SIZE = 200
    }
}
