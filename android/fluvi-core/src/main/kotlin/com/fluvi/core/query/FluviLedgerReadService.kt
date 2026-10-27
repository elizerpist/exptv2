package com.fluvi.core.query

import android.database.Cursor
import androidx.room.withTransaction
import androidx.sqlite.db.SimpleSQLiteQuery
import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.dao.FluviLedgerAggregateBucketRow
import com.fluvi.core.database.dao.FluviCommittedDashboardRow
import com.fluvi.core.database.dao.FluviLedgerDailyAggregateRow
import com.fluvi.core.database.entity.FluviCategoryEntity
import com.fluvi.core.database.entity.FLUVI_LEDGER_CHRONOLOGICAL_INDEX
import com.fluvi.core.database.entity.FLUVI_LEDGER_DASHBOARD_PREVIEW_INDEX
import com.fluvi.core.database.entity.FluviLedgerEntryEntity
import com.fluvi.core.database.entity.FluviPartnerEntity
import com.fluvi.core.model.QueryPeriodKind
import com.fluvi.core.model.CategoryAssignmentMode
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.LedgerOriginKind
import com.fluvi.core.model.FluviSystemIds
import com.fluvi.core.repository.FluviCategoryRepository
import com.fluvi.core.repository.FluviPartnerRepository
import com.fluvi.core.repository.canonicalPartnerIdOf
import com.fluvi.core.repository.expandPartnerSelection
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged
import java.time.LocalDate
import java.util.Locale

/**
 * Read-only SQL boundary for the later Query screen. It intentionally returns
 * bounded pages and aggregates rather than a materialized ledger list.
 */
class FluviLedgerReadService internal constructor(
    private val database: FluviDatabase,
    private val partnerRepository: FluviPartnerRepository,
    private val categoryRepository: FluviCategoryRepository,
    private val preparationCheckpoint: suspend () -> Unit = {
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

    /**
     * Bounded SQL/metadata read for the Query Menu. The ledger is never
     * materialized in Flutter: result count, range domain and represented
     * facets are aggregated in this core boundary.
     */
    suspend fun queryMenuFacets(scope: FluviQueryScope): FluviQueryMenuFacets =
        database.withTransaction {
            val temporalScope = FluviQueryScope(
                direction = scope.direction,
                periodGroups = scope.periodGroups,
                ghostFilterMode = scope.ghostFilterMode,
            )
            val availableMonths = queryDashboardDailyAggregates(
                SqlWhere(
                    sql = "WHERE direction = ?",
                    arguments = listOf(scope.direction.name),
                ),
            ).asSequence()
                .map { LocalDate.ofEpochDay(it.bookedLocalEpochDay) }
                .map { FluviQueryAvailableMonth(year = it.year, month = it.monthValue) }
                .distinct()
                .sortedWith(compareBy<FluviQueryAvailableMonth> { it.year }.thenBy { it.month })
                .toList()
            val representedCategories = groupedSummary(temporalScope, "category_id")
            val representedPartners = groupedSummary(temporalScope, "partner_id")
            val categoriesById = categoryRepository.allEntities().associateBy { it.id }
            val partnersById = partnerRepository.allEntities().associateBy { it.id }
            val categories = representedCategories.map { summary ->
                val category = requireNotNull(categoriesById[summary.id]) {
                    "Unknown category ID in Query facet: ${summary.id}"
                }
                FluviQueryFacetCategory(
                    id = category.id,
                    displayName = category.name,
                    colorId = category.colorId,
                    iconId = category.iconId,
                    entryCount = summary.entryCount,
                )
            }
            val partners = representedPartners
                .groupBy { summary -> canonicalPartnerIdOf(partnersById, summary.id) }
                .map { (canonicalId, summaries) ->
                    val partner = requireNotNull(partnersById[canonicalId]) {
                        "Unknown partner ID in Query facet: $canonicalId"
                    }
                    val category = requireNotNull(categoriesById[partner.defaultCategoryId]) {
                        "Unknown partner category in Query facet: ${partner.defaultCategoryId}"
                    }
                    FluviQueryFacetPartner(
                        id = partner.id,
                        displayName = partner.displayNameOverride ?: partner.originalName,
                        categoryId = category.id,
                        categoryColorId = category.colorId,
                        categoryIconId = category.iconId,
                        entryCount = summaries.sumOf { it.entryCount },
                    )
                }
                .sortedWith(compareByDescending<FluviQueryFacetPartner> { it.entryCount }.thenBy { it.displayName })
            val rangeScope = scope.copy(
                refinements = scope.refinements.copy(
                    minimumAmountScaled100 = null,
                    maximumAmountScaled100 = null,
                ),
            )
            FluviQueryMenuFacets(
                result = total(scope),
                amountDomain = amountDomain(rangeScope),
                availableMonths = availableMonths,
                categories = categories,
                partners = partners,
            )
        }

    private suspend fun amountDomain(scope: FluviQueryScope): FluviQueryAmountDomain {
        val where = where(scope)
        val row = ledger.queryAmountDomain(
            SimpleSQLiteQuery(
                "SELECT COALESCE(MIN(amount_scaled_100), 0) AS minimum_amount_scaled_100, " +
                    "COALESCE(MAX(amount_scaled_100), 0) AS maximum_amount_scaled_100 " +
                    "FROM fluvi_ledger_entries " + where.sql,
                where.arguments.toTypedArray(),
            ),
        )
        return FluviQueryAmountDomain(
            minimumAmountScaled100 = row.minimumAmountScaled100,
            maximumAmountScaled100 = row.maximumAmountScaled100,
        )
    }

    suspend fun readSlice(
        scope: FluviQueryScope,
        pageSize: Int = DEFAULT_PAGE_SIZE,
        after: FluviTimelineCursor? = null,
    ): FluviDashboardLedgerSlice {
        val identity = FluviDashboardScopeIdentity.forCommitted(scope)
        val aggregate = total(scope)
        // `readSlice` is retained for small, direct consumers. It must use the
        // same presentation timeline as committed paging: using the historical
        // Ledger-only helper here would make ghost-only future scopes disappear
        // depending on which dashboard reader happened to be active.
        val rowsWithLookahead = mergedPresentationPage(
            scope = scope,
            after = after,
            limit = pageSize + 1,
        )
        val rows = rowsWithLookahead.take(pageSize)
        val nextCursor = if (rowsWithLookahead.size > pageSize) {
            rows.last().toCursor()
        } else {
            null
        }
        val presentationEntryCount = aggregate.entryCount + pendingGhostPresentationCount(scope)
        val coreRevision = currentCoreRevision()
        return FluviDashboardLedgerSlice(
            queryKey = identity.queryKey,
            coreRevision = coreRevision,
            direction = scope.direction,
            timeScopeKey = identity.timeScopeKey,
            totalMinor = aggregate.amountScaled100,
            entryCount = aggregate.entryCount,
            presentationEntryCount = presentationEntryCount,
            entries = rows,
            nextCursor = nextCursor,
        )
    }

    /**
     * Dedicated bounded acquisition for committed vertical paging.
     *
     * The exact committed frame already owns the aggregate. Recomputing it
     * for every keyset page would both duplicate SQL work and open a second
     * aggregate snapshot. This read therefore verifies the revision and maps
     * only its requested page rows in one database transaction.
     */
    suspend fun readCommittedPage(
        scope: FluviQueryScope,
        pageSize: Int,
        after: FluviTimelineCursor?,
        expectedRevision: Long,
        authoritativeTotalMinor: Long,
        authoritativeEntryCount: Long,
        authoritativePresentationEntryCount: Long = authoritativeEntryCount,
    ): FluviCommittedDashboardPageRead {
        require(expectedRevision > 0L) { "Committed page requires a revision." }
        require(authoritativeEntryCount >= 0L) {
            "Committed page count must not be negative."
        }
        require(authoritativePresentationEntryCount >= authoritativeEntryCount) {
            "Committed presentation count must include every booked entry."
        }
        require(pageSize in 1..MAX_PAGE_SIZE) {
            "Page size must be between 1 and $MAX_PAGE_SIZE."
        }
        val identity = FluviDashboardScopeIdentity.forCommitted(scope)
        return database.withTransaction {
            val revisionBefore = currentCoreRevision()
            require(revisionBefore == expectedRevision) {
                "Committed page revision changed before reading."
            }
            val sqlStartedAtNanos = System.nanoTime()
            val rows = mergedPresentationPage(
                scope = scope,
                after = after,
                limit = pageSize + 1,
            )
            val sqlDurationNanos = (System.nanoTime() - sqlStartedAtNanos)
                .coerceAtLeast(0L)
            val pageRows = rows.take(pageSize)
            val nextCursor = if (rows.size > pageSize) {
                pageRows.last().toCursor()
            } else {
                null
            }
            val revisionAfter = currentCoreRevision()
            require(revisionAfter == expectedRevision) {
                "Committed page revision changed while reading."
            }
            val mappingStartedAtNanos = System.nanoTime()
            val slice = FluviDashboardLedgerSlice(
                queryKey = identity.queryKey,
                coreRevision = revisionAfter,
                direction = scope.direction,
                timeScopeKey = identity.timeScopeKey,
                totalMinor = authoritativeTotalMinor,
                entryCount = authoritativeEntryCount,
                presentationEntryCount = authoritativePresentationEntryCount,
                entries = pageRows,
                nextCursor = nextCursor,
            )
            FluviCommittedDashboardPageRead(
                slice = slice,
                sqlDurationNanos = sqlDurationNanos,
                mappingDurationNanos = (System.nanoTime() - mappingStartedAtNanos)
                    .coerceAtLeast(0L),
            )
        }
    }

    /**
     * The sole long-lived dashboard invalidation observer. It emits only the
     * canonical core revision and never materializes an exact-scope slice.
     */
    fun observeCoreRevision(): Flow<Long> = database.appSettingsDao()
        .observeCoreRevision()
        .distinctUntilChanged()

    suspend fun currentCoreRevision(): Long = requireNotNull(
        database.appSettingsDao().current(),
    ) { "The Fluvi app settings row is missing." }.coreRevision

    /**
     * Builds the sole immutable dashboard interaction index for both
     * directions and every represented all/year/month/day scope.
     *
     * The database-call shape is constant: Partners, Categories, one daily
     * aggregate, one ordered preview cursor and the core revision. Month,
     * year and all-time aggregates are folded from the daily batch in Kotlin.
     */
    suspend fun preparedDashboardIndex(
        periodGroups: List<FluviPeriodGroup> = emptyList(),
        categoryIds: Set<String>,
        partnerIds: Set<String>,
        refinements: FluviQueryRefinements,
        previewPageSize: Int = DEFAULT_PAGE_SIZE,
        yearWindow: FluviPreparedYearWindow,
        requestGeneration: Long = 1L,
    ): FluviPreparedDashboardIndex = preparedDashboardIndex(
        directionalFilters = FluviDashboardDirectionalQuerySet(
            income = FluviQueryScope(
                direction = LedgerDirection.income,
                periodGroups = periodGroups,
                categoryIds = categoryIds,
                partnerIds = partnerIds,
                refinements = refinements,
            ),
            expense = FluviQueryScope(
                direction = LedgerDirection.expense,
                periodGroups = periodGroups,
                categoryIds = categoryIds,
                partnerIds = partnerIds,
                refinements = refinements,
            ),
        ),
        previewPageSize = previewPageSize,
        yearWindow = yearWindow,
        requestGeneration = requestGeneration,
    )

    /**
     * One bounded SQL acquisition with a direction-specific predicate for
     * each requested half of the active immutable dashboard index.
     */
    suspend fun preparedDashboardIndex(
        directionalFilters: FluviDashboardDirectionalQuerySet,
        previewPageSize: Int = DEFAULT_PAGE_SIZE,
        yearWindow: FluviPreparedYearWindow,
        requestGeneration: Long = 1L,
        directions: Set<LedgerDirection> = LedgerDirection.entries.toSet(),
    ): FluviPreparedDashboardIndex {
        require(previewPageSize in 1..MAX_PAGE_SIZE) {
            "Preview page size must be between 1 and 200."
        }
        require(requestGeneration > 0L) { "Request generation must be positive." }
        require(directions.isNotEmpty()) {
            "Prepared dashboard index needs at least one direction."
        }
        preparationCheckpoint()
        val queryStartedAtNanos = System.nanoTime()
        val native = database.withTransaction {
            val sqlCalls = DashboardSqlCallCounter()
            val partnerEntities = sqlCalls.record {
                partnerRepository.allEntities()
            }
            preparationCheckpoint()
            val expandedPartnerIdsByDirection = directions.associateWith { direction ->
                expandPartnerSelection(
                    selectedPartnerIds = directionalFilters.scopeFor(direction).partnerIds,
                    allPartners = partnerEntities,
                )
            }
            val sqlWhere = dashboardIndexWhere(
                directionalFilters = directionalFilters,
                expandedPartnerIdsByDirection = expandedPartnerIdsByDirection,
                directions = directions,
            )
            val categories = sqlCalls.record {
                categoryRepository.allEntities()
            }
            preparationCheckpoint()
            val aggregationStartedAtNanos = System.nanoTime()
            val aggregateRows = sqlCalls.record {
                queryDashboardDailyAggregates(sqlWhere)
            }
            preparationCheckpoint()
            val aggregationDurationNanos = System.nanoTime() - aggregationStartedAtNanos
            val aggregates = foldDashboardAggregates(
                dailyRows = aggregateRows,
                yearWindow = yearWindow,
            )
            preparationCheckpoint()
            val realRows = sqlCalls.record {
                scanPreparedLedgerRows(sqlWhere)
            }
            preparationCheckpoint()
            val pendingOccurrences = sqlCalls.record {
                database.recurrenceDao().activeVisiblePendingOccurrences(FluviSystemIds.APP_SETTINGS)
            }
            preparationCheckpoint()
            val categoriesById = categories.associateBy { it.id }
            val partnersById = partnerEntities.associateBy { it.id }
            val presentationRows = ArrayList<FluviDashboardLedgerRow>(
                realRows.size + pendingOccurrences.size,
            )
            realRows.forEach { entry ->
                presentationRows += entry.toDashboardRow(categoriesById, partnersById)
            }
            pendingOccurrences.forEach { occurrence ->
                val filter = directionalFilters.scopeFor(occurrence.direction)
                val partnerIds = requireNotNull(expandedPartnerIdsByDirection[occurrence.direction])
                val ghost = occurrence.toPendingGhostRow(categoriesById, partnersById)
                if (ghost.matchesDashboardFilter(filter, partnerIds)) {
                    presentationRows += ghost
                }
            }
            val presentationNow = System.currentTimeMillis()
            presentationRows.sortWith(presentationRowComparator(presentationNow))
            val retained = retainPreparedRows(
                rows = presentationRows,
                previewCapacity = previewPageSize + 1,
                yearWindow = yearWindow,
            )
            val coreRevision = sqlCalls.record {
                currentCoreRevision()
            }
            preparationCheckpoint()
            check(sqlCalls.count == PREPARED_DASHBOARD_INDEX_SQL_CALL_COUNT) {
                "Prepared dashboard index SQL shape changed: ${sqlCalls.count}."
            }
            PreparedDashboardIndexNativeRead(
                aggregates = aggregates,
                verticalGeometryBuckets = retained.presentationDailyCounts
                    .entries
                    .sortedWith(compareBy({ it.key.direction.name }, { -it.key.epochDay }))
                    .map { (key, count) ->
                        FluviPreparedDashboardGeometryDayBucket(
                            direction = key.direction,
                            bookedLocalEpochDay = key.epochDay,
                            entryCount = count,
                        )
                    },
                retained = retained,
                categories = categoriesById,
                partners = partnersById,
                coreRevision = coreRevision,
                sqlCallCount = sqlCalls.count,
                sqlDurationNanos = sqlCalls.durationNanos,
                dailyAggregateBucketCount = aggregateRows.size,
                aggregationDurationNanos = aggregationDurationNanos,
            )
        }
        require(native.coreRevision > 0L) {
            "A seed-complete nonzero core revision is required for a dashboard index."
        }
        val queryDurationNanos = System.nanoTime() - queryStartedAtNanos
        val mappingStartedAtNanos = System.nanoTime()
        val pageRowIds = linkedSetOf<String>()
        native.retained.rowIdsByBucket.values.forEachIndexed { index, ids ->
            if (index % CANCELLATION_CHECK_INTERVAL == 0) preparationCheckpoint()
            pageRowIds.addAll(ids.take(previewPageSize))
        }
        preparationCheckpoint()
        val retainedEntities = native.retained.rowsById
        val rows = ArrayList<FluviDashboardLedgerRow>(pageRowIds.size)
        pageRowIds.forEachIndexed { index, entryId ->
            if (index % CANCELLATION_CHECK_INTERVAL == 0) preparationCheckpoint()
            rows += requireNotNull(retainedEntities[entryId])
        }
        preparationCheckpoint()
        val focusRows = ArrayList<FluviDashboardLedgerRow>(
            native.retained.focusRowIdsByDirection.values.sumOf { it.size },
        )
        native.retained.focusRowIdsByDirection.values.forEachIndexed { directionIndex, ids ->
            if (directionIndex % CANCELLATION_CHECK_INTERVAL == 0) preparationCheckpoint()
            ids.forEachIndexed { rowIndex, entryId ->
                if (rowIndex % CANCELLATION_CHECK_INTERVAL == 0) preparationCheckpoint()
                focusRows += requireNotNull(retainedEntities[entryId])
            }
        }
        preparationCheckpoint()
        val rowIndexById = linkedMapOf<String, Int>()
        rows.forEachIndexed { index, row ->
            if (index % CANCELLATION_CHECK_INTERVAL == 0) preparationCheckpoint()
            rowIndexById[row.entryId] = index
        }
        preparationCheckpoint()
        val frames = ArrayList<FluviPreparedDashboardIndexFrame>()
        (native.aggregates.keys + native.retained.presentationCounts.keys)
            .distinct()
            .sortedWith(compareBy({ it.direction.name }, { it.timeScopeKey }))
            .forEachIndexed { index, bucket ->
                if (index % CANCELLATION_CHECK_INTERVAL == 0) preparationCheckpoint()
                val filter = directionalFilters.scopeFor(bucket.direction)
                val queryKey = FluviDashboardScopeIdentity.forPreparedFrame(
                    direction = bucket.direction,
                    timeScopeKey = bucket.timeScopeKey,
                    queryPeriodGroups = filter.periodGroups,
                    categoryIds = filter.categoryIds,
                    partnerIds = filter.partnerIds,
                    refinements = filter.refinements,
                    ghostFilterMode = filter.ghostFilterMode,
                ).queryKey
                val retainedIds = native.retained.rowIdsByBucket[bucket].orEmpty()
                val visibleIds = retainedIds.take(previewPageSize)
                val aggregate = native.aggregates[bucket] ?: DashboardAggregateAccumulator()
                val presentationEntryCount = native.retained.presentationCounts[bucket] ?: 0L
                if (presentationEntryCount <= 0L) return@forEachIndexed
                frames += FluviPreparedDashboardIndexFrame(
                    queryKey = queryKey,
                    direction = bucket.direction,
                    timeScopeKey = bucket.timeScopeKey,
                    totalMinor = aggregate.amountScaled100,
                    entryCount = aggregate.entryCount,
                    presentationEntryCount = presentationEntryCount,
                    rowIndices = visibleIds.map { entryId ->
                        requireNotNull(rowIndexById[entryId])
                    },
                    nextCursor = if (presentationEntryCount > previewPageSize) {
                        requireNotNull(retainedEntities[visibleIds.last()]).toCursor()
                    } else {
                        null
                    },
                )
            }
        preparationCheckpoint()
        val mappingDurationNanos = System.nanoTime() - mappingStartedAtNanos
        return FluviPreparedDashboardIndex(
            coreRevision = native.coreRevision,
            previewPageSize = previewPageSize,
            requestGeneration = requestGeneration,
            yearWindow = yearWindow,
            rows = rows,
            focusRows = focusRows,
            frames = frames,
            verticalGeometryBuckets = native.verticalGeometryBuckets,
            buildMetrics = FluviPreparedDashboardIndexBuildMetrics(
                sqlCallCount = native.sqlCallCount,
                sqlDurationNanos = native.sqlDurationNanos,
                aggregateBucketCount = native.dailyAggregateBucketCount,
                scannedLedgerRowCount = native.retained.scannedRowCount,
                uniquePreviewRowCount = rows.size,
                frameCount = frames.size,
                queryDurationNanos = queryDurationNanos,
                aggregationDurationNanos = native.aggregationDurationNanos,
                mappingDurationNanos = mappingDurationNanos,
            ),
        )
    }

    /**
     * Acquires one exact direction for a new immutable composite index. The
     * other direction is retained by the caller only when its revision and
     * filter identity are exact; it is never reconstructed from this result.
     */
    suspend fun preparedDashboardIndexPartition(
        direction: LedgerDirection,
        directionalFilters: FluviDashboardDirectionalQuerySet,
        previewPageSize: Int = DEFAULT_PAGE_SIZE,
        yearWindow: FluviPreparedYearWindow,
        requestGeneration: Long = 1L,
    ): FluviPreparedDashboardIndex = preparedDashboardIndex(
            directionalFilters = directionalFilters,
            previewPageSize = previewPageSize,
            yearWindow = yearWindow,
            requestGeneration = requestGeneration,
            directions = setOf(direction),
        )

    suspend fun summaryByCategory(scope: FluviQueryScope): List<FluviLedgerGroupedSummary> =
        groupedSummary(scope, "category_id")

    suspend fun summaryByPartner(scope: FluviQueryScope): List<FluviLedgerGroupedSummary> =
        groupedSummary(scope, "partner_id")

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


    private suspend fun queryDashboardDailyAggregates(
        sqlWhere: SqlWhere,
    ): List<FluviLedgerDailyAggregateRow> = ledger.queryDashboardDailyAggregates(
        SimpleSQLiteQuery(
            "SELECT direction AS direction, " +
                "booked_local_epoch_day AS booked_local_epoch_day, " +
                "COUNT(*) AS entry_count, " +
                "COALESCE(SUM(amount_scaled_100), 0) AS amount_scaled_100 " +
                dashboardAggregateSource(sqlWhere) +
                " GROUP BY direction, booked_local_epoch_day " +
                "ORDER BY direction ASC, booked_local_epoch_day ASC",
            sqlWhere.arguments.toTypedArray(),
        ),
    )

    private suspend fun foldDashboardAggregates(
        dailyRows: List<FluviLedgerDailyAggregateRow>,
        yearWindow: FluviPreparedYearWindow,
    ): Map<DashboardIndexBucket, DashboardAggregateAccumulator> {
        val aggregates = linkedMapOf<DashboardIndexBucket, DashboardAggregateAccumulator>()
        dailyRows.forEachIndexed { index, row ->
            if (index % CANCELLATION_CHECK_INTERVAL == 0) preparationCheckpoint()
            val direction = LedgerDirection.valueOf(row.direction)
            val date = LocalDate.ofEpochDay(row.bookedLocalEpochDay)
            val year = "%04d".format(Locale.ROOT, date.year)
            val month = "%04d-%02d".format(Locale.ROOT, date.year, date.monthValue)
            val day = "%04d-%02d-%02d".format(
                Locale.ROOT,
                date.year,
                date.monthValue,
                date.dayOfMonth,
            )
            val timeScopeKeys = mutableListOf("all")
            if (year.toInt() in yearWindow.startYear..yearWindow.endYearInclusive) {
                timeScopeKeys += "year:$year"
                timeScopeKeys += "month:$month"
                timeScopeKeys += "day:$day"
            }
            timeScopeKeys.forEach { timeScopeKey ->
                val bucket = DashboardIndexBucket(direction, timeScopeKey)
                val aggregate = aggregates.getOrPut(bucket) {
                    DashboardAggregateAccumulator()
                }
                aggregate.entryCount += row.entryCount
                aggregate.amountScaled100 += row.amountScaled100
            }
        }
        preparationCheckpoint()
        return aggregates
    }

    private suspend fun scanPreparedLedgerRows(
        sqlWhere: SqlWhere,
    ): List<FluviLedgerEntryEntity> {
        val rows = mutableListOf<FluviLedgerEntryEntity>()
        val cursor = database.openHelper.readableDatabase.query(
            SimpleSQLiteQuery(
                "SELECT * " + dashboardPreviewSource(sqlWhere) +
                    " ORDER BY direction ASC, booked_local_epoch_day DESC, " +
                    "booked_local_time_minutes DESC, id DESC",
                sqlWhere.arguments.toTypedArray(),
            ),
        )
        cursor.use {
            while (it.moveToNext()) {
                if (rows.size % CANCELLATION_CHECK_INTERVAL == 0) {
                    preparationCheckpoint()
                }
                rows += it.toLedgerEntry()
            }
        }
        return rows
    }

    private fun retainPreparedRows(
        rows: List<FluviDashboardLedgerRow>,
        previewCapacity: Int,
        yearWindow: FluviPreparedYearWindow,
    ): PreparedDashboardIndexRetainedRows {
        val rowIdsByBucket = linkedMapOf<DashboardIndexBucket, MutableList<String>>()
        val rowsById = linkedMapOf<String, FluviDashboardLedgerRow>()
        val focusRowIdsByDirection = LedgerDirection.entries.associateWith {
            mutableListOf<String>()
        }
        val presentationCounts = linkedMapOf<DashboardIndexBucket, Long>()
        val presentationDailyCounts = linkedMapOf<DashboardPresentationDayBucket, Long>()
        rows.forEach { row ->
            rowsById.putIfAbsent(row.entryId, row)
            // The retained focus universe is intentionally ghost-neutral.
            // Pending occurrences are presentation-only rows, but they must
            // still be retained here so a Dart-side membership projection can
            // switch between non-ghost, ghost-only and both without a second
            // Room query. Financial aggregation continues to use the booked
            // ledger aggregate path above and never consumes these rows.
            focusRowIdsByDirection.getValue(row.direction) += row.entryId
            val date = LocalDate.ofEpochDay(row.bookedLocalEpochDay)
            val year = "%04d".format(Locale.ROOT, date.year)
            val month = "%04d-%02d".format(Locale.ROOT, date.year, date.monthValue)
            val day = "%04d-%02d-%02d".format(Locale.ROOT, date.year, date.monthValue, date.dayOfMonth)
            val buckets = buildList {
                add(DashboardIndexBucket(row.direction, "all"))
                if (date.year in yearWindow.startYear..yearWindow.endYearInclusive) {
                    add(DashboardIndexBucket(row.direction, "year:$year"))
                    add(DashboardIndexBucket(row.direction, "month:$month"))
                    add(DashboardIndexBucket(row.direction, "day:$day"))
                }
            }
            buckets.forEach { bucket ->
                presentationCounts[bucket] = (presentationCounts[bucket] ?: 0L) + 1L
                val retained = rowIdsByBucket.getOrPut(bucket) { mutableListOf() }
                if (retained.size < previewCapacity) retained += row.entryId
            }
            val dayBucket = DashboardPresentationDayBucket(row.direction, row.bookedLocalEpochDay)
            presentationDailyCounts[dayBucket] = (presentationDailyCounts[dayBucket] ?: 0L) + 1L
        }
        return PreparedDashboardIndexRetainedRows(
            rowsById = rowsById,
            rowIdsByBucket = rowIdsByBucket,
            focusRowIdsByDirection = focusRowIdsByDirection,
            presentationCounts = presentationCounts,
            presentationDailyCounts = presentationDailyCounts,
            scannedRowCount = rows.size,
        )
    }

    private fun FluviDashboardLedgerRow.matchesDashboardFilter(
        scope: FluviQueryScope,
        expandedPartnerIds: Set<String>,
    ): Boolean {
        if (direction != scope.direction) return false
        if (scope.ghostFilterMode == FluviGhostFilterMode.nonGhost) return false
        if (scope.categoryIds.isNotEmpty() && categoryId !in scope.categoryIds) return false
        if (expandedPartnerIds.isNotEmpty() && partnerId !in expandedPartnerIds) return false
        if (!scope.periodGroups.all { group ->
                group.selections.any { selection ->
                    val range = selection.epochDayRange()
                    bookedLocalEpochDay in range.startInclusive until range.endExclusive
                }
            }) return false
        scope.refinements.minimumAmountScaled100?.let { minimum ->
            if (amountIsUnknown || amountMinor < minimum) return false
        }
        scope.refinements.maximumAmountScaled100?.let { maximum ->
            if (amountIsUnknown || amountMinor > maximum) return false
        }
        val needle = scope.refinements.noteContains?.trim()?.lowercase(Locale.ROOT)
        if (!needle.isNullOrEmpty()) {
            val haystack = listOf(partnerDisplayName, categoryDisplayName, note.orEmpty())
                .joinToString(" ")
                .lowercase(Locale.ROOT)
            if (!haystack.contains(needle)) return false
        }
        return true
    }

    private fun dashboardIndexWhere(
        directionalFilters: FluviDashboardDirectionalQuerySet,
        expandedPartnerIdsByDirection: Map<LedgerDirection, Set<String>>,
        directions: Set<LedgerDirection>,
    ): SqlWhere {
        val directionClauses = mutableListOf<String>()
        val arguments = mutableListOf<Any>()
        LedgerDirection.entries.filter(directions::contains).forEach { direction ->
            val filter = directionalFilters.scopeFor(direction)
            val clauses = mutableListOf<String>()
            clauses += "direction = ?"
            arguments += direction.name
            appendPeriodGroups(clauses, arguments, filter.periodGroups)
            appendDashboardFilterClauses(
                clauses = clauses,
                arguments = arguments,
                categoryIds = filter.categoryIds,
                expandedPartnerIds = requireNotNull(expandedPartnerIdsByDirection[direction]),
                refinements = filter.refinements,
                ghostFilterMode = filter.ghostFilterMode,
            )
            directionClauses += "(" + clauses.joinToString(" AND ") + ")"
        }
        return SqlWhere(
            sql = "WHERE " + directionClauses.joinToString(" OR "),
            arguments = arguments,
        )
    }

    private fun appendDashboardFilterClauses(
        clauses: MutableList<String>,
        arguments: MutableList<Any>,
        categoryIds: Set<String>,
        expandedPartnerIds: Set<String>,
        refinements: FluviQueryRefinements,
        ghostFilterMode: FluviGhostFilterMode = FluviGhostFilterMode.both,
        tableAlias: String? = null,
    ) {
        fun column(name: String): String = tableAlias?.let { "$it.$name" } ?: name
        when (ghostFilterMode) {
            FluviGhostFilterMode.nonGhost -> clauses += "${column("recurrence_occurrence_id")} IS NULL"
            FluviGhostFilterMode.onlyGhost -> clauses += "${column("recurrence_occurrence_id")} IS NOT NULL"
            FluviGhostFilterMode.both -> Unit
        }
        categoryIds.sorted().takeIf { it.isNotEmpty() }?.let { values ->
            clauses += "${column("category_id")} IN (" + values.placeholders() + ")"
            arguments.addAll(values)
        }
        expandedPartnerIds.sorted().takeIf { it.isNotEmpty() }?.let { values ->
            clauses += "${column("partner_id")} IN (" + values.placeholders() + ")"
            arguments.addAll(values)
        }
        refinements.minimumAmountScaled100?.let { minimum ->
            clauses += "${column("amount_scaled_100")} >= ?"
            arguments += minimum
        }
        refinements.maximumAmountScaled100?.let { maximum ->
            clauses += "${column("amount_scaled_100")} <= ?"
            arguments += maximum
        }
        appendTextSearch(
            clauses,
            arguments,
            refinements.noteContains,
            tableAlias = tableAlias,
        )
    }

    private fun dashboardAggregateSource(sqlWhere: SqlWhere): String =
        "FROM fluvi_ledger_entries " +
            if (sqlWhere.sql.isEmpty()) {
                "INDEXED BY $FLUVI_LEDGER_CHRONOLOGICAL_INDEX "
            } else {
                sqlWhere.sql
            }

    private fun dashboardPreviewSource(sqlWhere: SqlWhere): String =
        "FROM fluvi_ledger_entries " +
            if (sqlWhere.sql.isEmpty()) {
                "INDEXED BY $FLUVI_LEDGER_DASHBOARD_PREVIEW_INDEX "
            } else {
                sqlWhere.sql
            }

    /**
     * The committed LogBox uses one SQL-ordered timeline for booked entries
     * and pending recurrence snapshots.  Financial aggregates are never read
     * from this union; it is presentation data only.
     */
    private suspend fun mergedPresentationPage(
        scope: FluviQueryScope,
        after: FluviTimelineCursor?,
        limit: Int,
    ): List<FluviDashboardLedgerRow> {
        require(limit in 1..MAX_PAGE_SIZE + 1)
        val expandedPartners = expandedPartnerIds(scope.partnerIds)
        val ledgerWhere = where(
            scope = scope,
            expandedPartnerIdsOverride = expandedPartners,
            tableAlias = "ledger",
        )
        val ghostWhere = ghostPresentationWhere(scope, expandedPartners)
        val presentationNow = System.currentTimeMillis()
        val arguments = ArrayList<Any>(ledgerWhere.arguments.size + ghostWhere.arguments.size + 20)
        arguments.addAll(ledgerWhere.arguments)
        // This placeholder occurs in the ghost SELECT before its WHERE
        // predicates. Keep bind order identical to the SQL text: swapping
        // these would make a valid pending-ghost count render an empty page.
        arguments += presentationNow
        arguments.addAll(ghostWhere.arguments)
        val outerCursor = after?.let { cursor ->
            require(cursor.timelineSegment in 0..1) { "Invalid presentation cursor segment." }
            arguments += cursor.timelineSegment
            arguments += cursor.timelineSegment
            arguments += cursor.pendingSortBucket
            arguments += cursor.pendingSortBucket
            arguments += cursor.pendingExpectedAtUtcMs
            arguments += cursor.pendingExpectedAtUtcMs
            arguments += cursor.pendingExpectedAtUtcMs
            arguments += cursor.entryId
            arguments += cursor.timelineSegment
            arguments += cursor.bookedLocalEpochDay
            arguments += cursor.bookedLocalEpochDay
            arguments += cursor.bookedLocalTimeMinutes
            arguments += cursor.bookedLocalEpochDay
            arguments += cursor.bookedLocalTimeMinutes
            arguments += cursor.entryId
            " WHERE (timeline_segment > ? OR " +
                "(timeline_segment = 0 AND ? = 0 AND (" +
                "pending_sort_bucket > ? OR " +
                "(pending_sort_bucket = ? AND ((pending_sort_bucket = 0 AND pending_expected_at_utc_ms < ?) OR " +
                "(pending_sort_bucket = 1 AND pending_expected_at_utc_ms > ?) OR " +
                "(pending_expected_at_utc_ms = ? AND timeline_id > ?))))) OR " +
                "(timeline_segment = 1 AND ? = 1 AND (booked_local_epoch_day < ? OR " +
                "(booked_local_epoch_day = ? AND booked_local_time_minutes < ?) OR " +
                "(booked_local_epoch_day = ? AND booked_local_time_minutes = ? AND timeline_id < ?))))"
        }.orEmpty()
        arguments += limit
        val sql = "SELECT * FROM (" +
            "SELECT ledger.id AS timeline_id, ledger.direction AS direction, " +
            "ledger.amount_scaled_100 AS amount_minor, " +
            "ledger.booked_local_epoch_day AS booked_local_epoch_day, " +
            "ledger.booked_local_time_minutes AS booked_local_time_minutes, " +
            "ledger.occurred_at_utc_ms AS occurred_at_utc_ms, ledger.partner_id AS partner_id, " +
            "COALESCE(partner.display_name_override, partner.original_name) AS partner_display_name, " +
            "ledger.category_id AS category_id, category.name AS category_display_name, " +
            "category.color_id AS category_color_id, category.icon_id AS category_icon_id, " +
            "ledger.category_assignment_mode AS assignment_mode, ledger.origin_kind AS origin_kind, " +
            "ledger.note AS note, 0 AS is_pending_ghost, " +
            "ledger.recurrence_occurrence_id AS recurrence_occurrence_id, 0 AS amount_is_unknown, " +
            "1 AS timeline_segment, 2 AS pending_sort_bucket, 0 AS pending_expected_at_utc_ms " +
            "FROM fluvi_ledger_entries AS ledger " +
            "JOIN fluvi_partners AS partner ON partner.id = ledger.partner_id " +
            "JOIN fluvi_categories AS category ON category.id = ledger.category_id " +
            ledgerWhere.sql +
            " UNION ALL " +
            "SELECT 'ghost:' || occurrence.id AS timeline_id, occurrence.direction AS direction, " +
            "COALESCE(occurrence.expected_amount_scaled_100, 0) AS amount_minor, " +
            "occurrence.expected_local_epoch_day AS booked_local_epoch_day, " +
            "occurrence.expected_local_time_minutes AS booked_local_time_minutes, " +
            "occurrence.expected_at_utc_ms AS occurred_at_utc_ms, occurrence.partner_id AS partner_id, " +
            "COALESCE(ghost_partner.display_name_override, ghost_partner.original_name) AS partner_display_name, " +
            "occurrence.category_id AS category_id, ghost_category.name AS category_display_name, " +
            "ghost_category.color_id AS category_color_id, ghost_category.icon_id AS category_icon_id, " +
            "occurrence.category_assignment_mode AS assignment_mode, 'recurring' AS origin_kind, " +
            "occurrence.note AS note, 1 AS is_pending_ghost, occurrence.id AS recurrence_occurrence_id, " +
            "CASE WHEN occurrence.expected_amount_scaled_100 IS NULL THEN 1 ELSE 0 END AS amount_is_unknown, " +
            "0 AS timeline_segment, CASE WHEN occurrence.expected_at_utc_ms <= ? THEN 0 ELSE 1 END AS pending_sort_bucket, " +
            "occurrence.expected_at_utc_ms AS pending_expected_at_utc_ms " +
            "FROM fluvi_recurrence_occurrences AS occurrence " +
            "JOIN fluvi_recurrence_rules AS rule ON rule.id = occurrence.rule_id " +
            "JOIN fluvi_partners AS ghost_partner ON ghost_partner.id = occurrence.partner_id " +
            "JOIN fluvi_categories AS ghost_category ON ghost_category.id = occurrence.category_id " +
            ghostWhere.sql +
            ")" + outerCursor +
            " ORDER BY timeline_segment ASC, pending_sort_bucket ASC, " +
            "CASE WHEN timeline_segment = 0 AND pending_sort_bucket = 0 THEN pending_expected_at_utc_ms END DESC, " +
            "CASE WHEN timeline_segment = 0 AND pending_sort_bucket = 1 THEN pending_expected_at_utc_ms END ASC, " +
            "CASE WHEN timeline_segment = 0 THEN timeline_id END ASC, " +
            "booked_local_epoch_day DESC, booked_local_time_minutes DESC, timeline_id DESC LIMIT ?"
        val rows = mutableListOf<FluviDashboardLedgerRow>()
        database.openHelper.readableDatabase.query(SimpleSQLiteQuery(sql, arguments.toTypedArray())).use { cursor ->
            while (cursor.moveToNext()) rows += cursor.toPresentationRow()
        }
        return rows
    }

    private fun ghostPresentationWhere(
        scope: FluviQueryScope,
        expandedPartnerIds: Set<String>,
    ): SqlWhere {
        if (scope.ghostFilterMode == FluviGhostFilterMode.nonGhost) {
            // Keep the union SQL valid while making this branch empty. This
            // remains a native predicate, not a Dart-side row removal.
            return SqlWhere("WHERE 0", emptyList())
        }
        val clauses = mutableListOf(
            "occurrence.status = 'pending'",
            "rule.is_active = 1",
            "rule.archived_at_utc_ms IS NULL",
            "EXISTS (SELECT 1 FROM fluvi_app_settings AS settings " +
                "WHERE settings.id = '${FluviSystemIds.APP_SETTINGS}' " +
                "AND settings.show_pending_ghosts_in_ledger = 1)",
            "occurrence.direction = ?",
        )
        val arguments = mutableListOf<Any>(scope.direction.name)
        appendPeriodGroups(
            clauses,
            arguments,
            scope.periodGroups,
            epochDayColumn = "occurrence.expected_local_epoch_day",
        )
        scope.categoryIds.sorted().takeIf { it.isNotEmpty() }?.let { ids ->
            clauses += "occurrence.category_id IN (" + ids.placeholders() + ")"
            arguments.addAll(ids)
        }
        expandedPartnerIds.sorted().takeIf { it.isNotEmpty() }?.let { ids ->
            clauses += "occurrence.partner_id IN (" + ids.placeholders() + ")"
            arguments.addAll(ids)
        }
        scope.refinements.minimumAmountScaled100?.let { value ->
            clauses += "occurrence.expected_amount_scaled_100 >= ?"
            arguments += value
        }
        scope.refinements.maximumAmountScaled100?.let { value ->
            clauses += "occurrence.expected_amount_scaled_100 <= ?"
            arguments += value
        }
        scope.refinements.noteContains?.trim()?.takeIf { it.isNotEmpty() }?.let { needle ->
            val pattern = "%" + needle.escapeForLike() + "%"
            clauses += "(COALESCE(occurrence.note, '') LIKE ? ESCAPE '\\' OR " +
                "COALESCE(ghost_partner.display_name_override, ghost_partner.original_name) LIKE ? ESCAPE '\\' OR " +
                "ghost_category.name LIKE ? ESCAPE '\\')"
            repeat(3) { arguments += pattern }
        }
        return SqlWhere("WHERE " + clauses.joinToString(" AND "), arguments)
    }

    /**
     * Counts only projected pending occurrences. Financial count and amount
     * remain Ledger-only; callers use this value solely to size the timeline.
     */
    private suspend fun pendingGhostPresentationCount(scope: FluviQueryScope): Long {
        val ghostWhere = ghostPresentationWhere(scope, expandedPartnerIds(scope.partnerIds))
        return ledger.queryAggregate(
            SimpleSQLiteQuery(
                "SELECT COUNT(*) AS entry_count, 0 AS amount_scaled_100 " +
                    "FROM fluvi_recurrence_occurrences AS occurrence " +
                    "JOIN fluvi_recurrence_rules AS rule ON rule.id = occurrence.rule_id " +
                    "JOIN fluvi_partners AS ghost_partner ON ghost_partner.id = occurrence.partner_id " +
                    "JOIN fluvi_categories AS ghost_category ON ghost_category.id = occurrence.category_id " +
                    ghostWhere.sql,
                ghostWhere.arguments.toTypedArray(),
            ),
        ).entryCount
    }

    private fun appendPeriodGroups(
        clauses: MutableList<String>,
        arguments: MutableList<Any>,
        periodGroups: List<FluviPeriodGroup>,
        tableAlias: String? = null,
        epochDayColumn: String? = null,
    ) {
        val epochDay = epochDayColumn
            ?: tableAlias?.let { "$it.booked_local_epoch_day" }
            ?: "booked_local_epoch_day"
        val predicate = periodGroupEpochDayPredicate(periodGroups, epochDay)
            ?: return
        clauses += predicate.sql
        arguments.addAll(predicate.arguments)
    }

    /**
     * Canonical period-group SQL: alternatives within a Query group are ORed,
     * independent groups are ANDed by the enclosing where builder. Every
     * selection is normalized to an indexed half-open epoch-day range.
     */
    internal fun periodGroupEpochDayPredicate(
        periodGroups: List<FluviPeriodGroup>,
        epochDayColumn: String = "booked_local_epoch_day",
    ): FluviEpochDayPredicate? {
        if (periodGroups.isEmpty()) return null
        val arguments = mutableListOf<Any>()
        val groupClauses = periodGroups.map { group ->
            val alternatives = group.selections
                .sortedWith(compareBy({ it.kind.ordinal }, { it.value }))
                .map { selection ->
                    val range = selection.epochDayRange()
                    arguments += range.startInclusive
                    arguments += range.endExclusive
                    "($epochDayColumn >= ? AND $epochDayColumn < ?)"
                }
            "(" + alternatives.joinToString(" OR ") + ")"
        }
        return FluviEpochDayPredicate(
            sql = groupClauses.joinToString(" AND "),
            arguments = arguments,
        )
    }

    private fun Cursor.toLedgerEntry(): FluviLedgerEntryEntity = FluviLedgerEntryEntity(
        id = string("id"),
        partnerId = string("partner_id"),
        categoryId = string("category_id"),
        categoryAssignmentMode = CategoryAssignmentMode.valueOf(string("category_assignment_mode")),
        note = nullableString("note"),
        direction = LedgerDirection.valueOf(string("direction")),
        amountScaled100 = long("amount_scaled_100"),
        bookedLocalEpochDay = long("booked_local_epoch_day"),
        bookedLocalTimeMinutes = int("booked_local_time_minutes"),
        occurredAtUtcMs = long("occurred_at_utc_ms"),
        originKind = LedgerOriginKind.valueOf(string("origin_kind")),
        notificationInboxId = nullableString("notification_inbox_id"),
        recurrenceOccurrenceId = nullableString("recurrence_occurrence_id"),
        createdAtUtcMs = long("created_at_utc_ms"),
        updatedAtUtcMs = long("updated_at_utc_ms"),
        revision = long("revision"),
    )

    private fun Cursor.string(column: String): String =
        getString(getColumnIndexOrThrow(column))

    private fun Cursor.nullableString(column: String): String? {
        val index = getColumnIndexOrThrow(column)
        return if (isNull(index)) null else getString(index)
    }

    private fun Cursor.long(column: String): Long = getLong(getColumnIndexOrThrow(column))

    private fun Cursor.int(column: String): Int = getInt(getColumnIndexOrThrow(column))

    private fun Cursor.boolean(column: String): Boolean = int(column) != 0

    private fun Cursor.toPresentationRow(): FluviDashboardLedgerRow = FluviDashboardLedgerRow(
        entryId = string("timeline_id"),
        direction = LedgerDirection.valueOf(string("direction")),
        amountMinor = long("amount_minor"),
        bookedLocalEpochDay = long("booked_local_epoch_day"),
        bookedLocalTimeMinutes = int("booked_local_time_minutes"),
        occurredAtUtcMs = long("occurred_at_utc_ms"),
        partnerId = string("partner_id"),
        partnerDisplayName = string("partner_display_name"),
        categoryId = string("category_id"),
        categoryDisplayName = string("category_display_name"),
        categoryColorId = string("category_color_id"),
        categoryIconId = string("category_icon_id"),
        assignmentMode = CategoryAssignmentMode.valueOf(string("assignment_mode")),
        originKind = LedgerOriginKind.valueOf(string("origin_kind")),
        note = nullableString("note"),
        isPendingGhost = boolean("is_pending_ghost"),
        recurrenceOccurrenceId = nullableString("recurrence_occurrence_id"),
        amountIsUnknown = boolean("amount_is_unknown"),
    )


    private suspend fun where(
        scope: FluviQueryScope,
        after: FluviTimelineCursor? = null,
        expandedPartnerIdsOverride: Set<String>? = null,
        tableAlias: String? = null,
    ): SqlWhere {
        fun column(name: String): String = tableAlias?.let { "$it.$name" } ?: name
        val clauses = mutableListOf<String>()
        val arguments = mutableListOf<Any>()
        clauses += "${column("direction")} = ?"
        arguments += scope.direction.name
        when (scope.ghostFilterMode) {
            FluviGhostFilterMode.nonGhost -> clauses += "${column("recurrence_occurrence_id")} IS NULL"
            FluviGhostFilterMode.onlyGhost -> clauses += "${column("recurrence_occurrence_id")} IS NOT NULL"
            FluviGhostFilterMode.both -> Unit
        }

        appendPeriodGroups(clauses, arguments, scope.periodGroups, tableAlias)

        scope.categoryIds.sorted().takeIf { it.isNotEmpty() }?.let { categoryIds ->
            clauses += "${column("category_id")} IN (" + categoryIds.placeholders() + ")"
            arguments.addAll(categoryIds)
        }
        (expandedPartnerIdsOverride ?: expandedPartnerIds(scope.partnerIds))
            .sorted()
            .takeIf { it.isNotEmpty() }
            ?.let { partnerIds ->
                clauses += "${column("partner_id")} IN (" + partnerIds.placeholders() + ")"
                arguments.addAll(partnerIds)
            }
        scope.refinements.minimumAmountScaled100?.let { minimum ->
            clauses += "${column("amount_scaled_100")} >= ?"
            arguments += minimum
        }
        scope.refinements.maximumAmountScaled100?.let { maximum ->
            clauses += "${column("amount_scaled_100")} <= ?"
            arguments += maximum
        }
        appendTextSearch(
            clauses,
            arguments,
            scope.refinements.noteContains,
            tableAlias = tableAlias,
        )
        after?.let { cursor ->
            val epochDay = column("booked_local_epoch_day")
            val timeMinutes = column("booked_local_time_minutes")
            val id = column("id")
            clauses += "($epochDay < ? OR " +
                "($epochDay = ? AND $timeMinutes < ?) OR " +
                "($epochDay = ? AND $timeMinutes = ? AND $id < ?))"
            arguments += cursor.bookedLocalEpochDay
            arguments += cursor.bookedLocalEpochDay
            arguments += cursor.bookedLocalTimeMinutes
            arguments += cursor.bookedLocalEpochDay
            arguments += cursor.bookedLocalTimeMinutes
            arguments += cursor.entryId
        }
        return SqlWhere("WHERE " + clauses.joinToString(" AND "), arguments)
    }

    private suspend fun expandedPartnerIds(selectedPartnerIds: Set<String>): Set<String> {
        val expanded = linkedSetOf<String>()
        selectedPartnerIds.sorted().forEach { selectedPartnerId ->
            val canonicalId = partnerRepository.resolveCanonicalPartnerId(selectedPartnerId)
            expanded += partnerRepository.partnerIdsResolvingTo(canonicalId)
        }
        return expanded
    }

    private fun Collection<String>.placeholders(): String = joinToString(",") { "?" }

    private fun appendTextSearch(
        clauses: MutableList<String>,
        arguments: MutableList<Any>,
        rawNeedle: String?,
        tableAlias: String? = null,
    ) {
        fun column(name: String): String = tableAlias?.let { "$it.$name" } ?: name
        val pattern = rawNeedle?.trim()?.takeIf { it.isNotEmpty() }
            ?.let { "%" + it.escapeForLike() + "%" }
            ?: return
        clauses += "(" +
            "COALESCE(${column("note")}, '') LIKE ? ESCAPE '\\' OR " +
            "EXISTS (SELECT 1 FROM fluvi_partners " +
                "WHERE fluvi_partners.id = ${column("partner_id")} AND " +
                "(fluvi_partners.original_name LIKE ? ESCAPE '\\' OR " +
                "COALESCE(fluvi_partners.display_name_override, '') LIKE ? ESCAPE '\\')) OR " +
            "EXISTS (SELECT 1 FROM fluvi_categories " +
                "WHERE fluvi_categories.id = ${column("category_id")} AND " +
                "fluvi_categories.name LIKE ? ESCAPE '\\')" +
            ")"
        repeat(4) { arguments += pattern }
    }

    private fun String.escapeForLike(): String =
        replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")

    private fun FluviLedgerEntryEntity.toCursor(): FluviTimelineCursor = FluviTimelineCursor(
        bookedLocalEpochDay = bookedLocalEpochDay,
        bookedLocalTimeMinutes = bookedLocalTimeMinutes,
        entryId = id,
    )

    private fun FluviCommittedDashboardRow.toCursor(): FluviTimelineCursor = FluviTimelineCursor(
        bookedLocalEpochDay = bookedLocalEpochDay,
        bookedLocalTimeMinutes = bookedLocalTimeMinutes,
        entryId = entryId,
    )

    private fun toDashboardRow(row: FluviCommittedDashboardRow): FluviDashboardLedgerRow =
        FluviDashboardLedgerRow(
            entryId = row.entryId,
            direction = LedgerDirection.valueOf(row.direction),
            amountMinor = row.amountMinor,
            bookedLocalEpochDay = row.bookedLocalEpochDay,
            bookedLocalTimeMinutes = row.bookedLocalTimeMinutes,
            occurredAtUtcMs = row.occurredAtUtcMs,
            partnerId = row.partnerId,
            partnerDisplayName = row.partnerDisplayName,
            categoryId = row.categoryId,
            categoryDisplayName = row.categoryDisplayName,
            categoryColorId = row.categoryColorId,
            categoryIconId = row.categoryIconId,
            assignmentMode = CategoryAssignmentMode.valueOf(row.assignmentMode),
            originKind = LedgerOriginKind.valueOf(row.originKind),
            note = row.note,
            recurrenceOccurrenceId = row.recurrenceOccurrenceId,
        )

    private fun committedDashboardPageSql(whereSql: String): String =
        "SELECT ledger.id AS entry_id, ledger.direction AS direction, " +
            "ledger.amount_scaled_100 AS amount_minor, " +
            "ledger.booked_local_epoch_day AS booked_local_epoch_day, " +
            "ledger.booked_local_time_minutes AS booked_local_time_minutes, " +
            "ledger.occurred_at_utc_ms AS occurred_at_utc_ms, " +
            "ledger.partner_id AS partner_id, " +
            "COALESCE(partner.display_name_override, partner.original_name) " +
            "AS partner_display_name, ledger.category_id AS category_id, " +
            "category.name AS category_display_name, " +
            "category.color_id AS category_color_id, category.icon_id AS category_icon_id, " +
            "ledger.category_assignment_mode AS assignment_mode, " +
            "ledger.origin_kind AS origin_kind, ledger.note AS note, " +
            "ledger.recurrence_occurrence_id AS recurrence_occurrence_id " +
            "FROM fluvi_ledger_entries AS ledger " +
            "JOIN fluvi_partners AS partner ON partner.id = ledger.partner_id " +
            "JOIN fluvi_categories AS category ON category.id = ledger.category_id " +
            whereSql +
            " ORDER BY ledger.booked_local_epoch_day DESC, " +
            "ledger.booked_local_time_minutes DESC, ledger.id DESC LIMIT ?"

    internal fun FluviPeriodSelection.epochDayRange(): FluviEpochDayRange = when (kind) {
        QueryPeriodKind.year -> {
            val year = value.toIntOrNull()
                ?: throw IllegalArgumentException("Invalid year period: $value")
            FluviEpochDayRange(
                LocalDate.of(year, 1, 1).toEpochDay(),
                LocalDate.of(year + 1, 1, 1).toEpochDay(),
            )
        }
        QueryPeriodKind.month -> {
            val date = try {
                java.time.YearMonth.parse(value)
            } catch (error: java.time.format.DateTimeParseException) {
                throw IllegalArgumentException("Invalid month period: $value", error)
            }
            FluviEpochDayRange(
                date.atDay(1).toEpochDay(),
                date.plusMonths(1).atDay(1).toEpochDay(),
            )
        }
        QueryPeriodKind.day -> {
            val date = try {
                LocalDate.parse(value)
            } catch (error: java.time.format.DateTimeParseException) {
                throw IllegalArgumentException("Invalid day period: $value", error)
            }
            FluviEpochDayRange(date.toEpochDay(), date.plusDays(1).toEpochDay())
        }
    }

    internal data class FluviEpochDayRange(
        val startInclusive: Long,
        val endExclusive: Long,
    )

    internal data class FluviEpochDayPredicate(
        val sql: String,
        val arguments: List<Any>,
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
            recurrenceOccurrenceId = recurrenceOccurrenceId,
        )
    }

    private fun com.fluvi.core.database.entity.FluviRecurrenceOccurrenceEntity.toPendingGhostRow(
        categories: Map<String, FluviCategoryEntity>,
        partners: Map<String, FluviPartnerEntity>,
    ): FluviDashboardLedgerRow {
        val category = requireNotNull(categories[categoryId]) {
            "Unknown category ID in recurrence occurrence: $categoryId"
        }
        val partner = requireNotNull(partners[partnerId]) {
            "Unknown partner ID in recurrence occurrence: $partnerId"
        }
        return FluviDashboardLedgerRow(
            entryId = "ghost:$id",
            direction = direction,
            amountMinor = expectedAmountScaled100 ?: 0L,
            bookedLocalEpochDay = expectedLocalEpochDay,
            bookedLocalTimeMinutes = expectedLocalTimeMinutes,
            occurredAtUtcMs = expectedAtUtcMs,
            partnerId = partnerId,
            partnerDisplayName = partner.displayNameOverride ?: partner.originalName,
            categoryId = category.id,
            categoryDisplayName = category.name,
            categoryColorId = category.colorId,
            categoryIconId = category.iconId,
            assignmentMode = categoryAssignmentMode,
            originKind = LedgerOriginKind.recurring,
            note = note,
            isPendingGhost = true,
            recurrenceOccurrenceId = id,
            amountIsUnknown = expectedAmountScaled100 == null,
        )
    }

    private fun FluviDashboardLedgerRow.toCursor(
        nowUtcMs: Long = System.currentTimeMillis(),
    ): FluviTimelineCursor = FluviTimelineCursor(
        bookedLocalEpochDay = bookedLocalEpochDay,
        bookedLocalTimeMinutes = bookedLocalTimeMinutes,
        entryId = entryId,
        timelineSegment = if (isPendingGhost) 0 else 1,
        pendingSortBucket = if (!isPendingGhost) 2 else if (occurredAtUtcMs <= nowUtcMs) 0 else 1,
        pendingExpectedAtUtcMs = if (isPendingGhost) occurredAtUtcMs else 0L,
    )

    private fun presentationRowComparator(
        nowUtcMs: Long,
    ): Comparator<FluviDashboardLedgerRow> = Comparator { left, right ->
        val direction = left.direction.name.compareTo(right.direction.name)
        if (direction != 0) return@Comparator direction
        val leftSegment = if (left.isPendingGhost) 0 else 1
        val rightSegment = if (right.isPendingGhost) 0 else 1
        val segment = leftSegment.compareTo(rightSegment)
        if (segment != 0) return@Comparator segment
        if (leftSegment == 0) {
            val leftBucket = if (left.occurredAtUtcMs <= nowUtcMs) 0 else 1
            val rightBucket = if (right.occurredAtUtcMs <= nowUtcMs) 0 else 1
            val bucket = leftBucket.compareTo(rightBucket)
            if (bucket != 0) return@Comparator bucket
            val expected = if (leftBucket == 0) {
                right.occurredAtUtcMs.compareTo(left.occurredAtUtcMs)
            } else {
                left.occurredAtUtcMs.compareTo(right.occurredAtUtcMs)
            }
            if (expected != 0) return@Comparator expected
            return@Comparator left.entryId.compareTo(right.entryId)
        }
        val day = right.bookedLocalEpochDay.compareTo(left.bookedLocalEpochDay)
        if (day != 0) return@Comparator day
        val minute = right.bookedLocalTimeMinutes.compareTo(left.bookedLocalTimeMinutes)
        if (minute != 0) return@Comparator minute
        right.entryId.compareTo(left.entryId)
    }

    private data class MaterializedTimelinePage(
        val page: FluviLedgerTimelinePage<FluviLedgerEntryEntity>,
        val materializedRowCount: Int,
    )


    private data class DashboardIndexBucket(
        val direction: LedgerDirection,
        val timeScopeKey: String,
    )

    private data class DashboardAggregateAccumulator(
        var entryCount: Long = 0L,
        var amountScaled100: Long = 0L,
    )

    private data class PreparedDashboardIndexRetainedRows(
        val rowsById: Map<String, FluviDashboardLedgerRow>,
        val rowIdsByBucket: Map<DashboardIndexBucket, List<String>>,
        val focusRowIdsByDirection: Map<LedgerDirection, List<String>>,
        val presentationCounts: Map<DashboardIndexBucket, Long>,
        val presentationDailyCounts: Map<DashboardPresentationDayBucket, Long>,
        val scannedRowCount: Int,
    )

    private data class DashboardPresentationDayBucket(
        val direction: LedgerDirection,
        val epochDay: Long,
    )

    private data class PreparedDashboardIndexNativeRead(
        val aggregates: Map<DashboardIndexBucket, DashboardAggregateAccumulator>,
        val verticalGeometryBuckets: List<FluviPreparedDashboardGeometryDayBucket>,
        val retained: PreparedDashboardIndexRetainedRows,
        val categories: Map<String, FluviCategoryEntity>,
        val partners: Map<String, FluviPartnerEntity>,
        val coreRevision: Long,
        val sqlCallCount: Int,
        val sqlDurationNanos: Long,
        val dailyAggregateBucketCount: Int,
        val aggregationDurationNanos: Long,
    )

    private data class SqlWhere(
        val sql: String,
        val arguments: List<Any>,
    )

    private class DashboardSqlCallCounter {
        var count: Int = 0
            private set
        var durationNanos: Long = 0L
            private set

        suspend fun <T> record(block: suspend () -> T): T {
            count += 1
            val startedAt = System.nanoTime()
            return try {
                block()
            } finally {
                durationNanos += (System.nanoTime() - startedAt).coerceAtLeast(0L)
            }
        }
    }

    private companion object {
        const val DEFAULT_PAGE_SIZE = 50
        const val MAX_PAGE_SIZE = 200
        const val PREPARED_DASHBOARD_INDEX_SQL_CALL_COUNT = 6
        const val CANCELLATION_CHECK_INTERVAL = 128
    }
}
