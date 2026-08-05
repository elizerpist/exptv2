package com.fluvi.core.query

import android.database.Cursor
import androidx.room.withTransaction
import androidx.sqlite.db.SimpleSQLiteQuery
import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.dao.FluviLedgerAggregateBucketRow
import com.fluvi.core.database.entity.FluviCategoryEntity
import com.fluvi.core.database.entity.FluviLedgerEntryEntity
import com.fluvi.core.database.entity.FluviPartnerEntity
import com.fluvi.core.model.QueryPeriodKind
import com.fluvi.core.model.CategoryAssignmentMode
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.LedgerOriginKind
import com.fluvi.core.repository.FluviCategoryRepository
import com.fluvi.core.repository.FluviPartnerRepository
import com.fluvi.core.repository.expandPartnerSelection
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.mapLatest
import java.time.LocalDate
import java.util.Locale

/**
 * Read-only SQL boundary for the later Query screen. It intentionally returns
 * bounded pages and aggregates rather than a materialized ledger list.
 */
@OptIn(ExperimentalCoroutinesApi::class)
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
     * Builds the complete parent/child presentation deck with a constant six
     * database calls: one Partner snapshot, parent total, child aggregate, one
     * streaming ledger cursor, categories and core revision. The Partner
     * snapshot owns both canonical filter expansion and row projection, so
     * selected Partners cannot introduce extra DAO calls.
     *
     * The cursor is never materialized as a parent list. It retains at most
     * `pageSize + 1` rows for the parent and each child and stops as soon as
     * every non-empty bucket has enough rows for its first page and cursor.
     */
    suspend fun preparedDeck(
        scope: FluviQueryScope,
        childPeriodKind: QueryPeriodKind,
        previewPageSize: Int = DEFAULT_PAGE_SIZE,
        yearWindow: FluviPreparedYearWindow? = null,
        requestGeneration: Long = 0L,
    ): FluviPreparedDeck {
        require(previewPageSize in 1..MAX_PAGE_SIZE) {
            "Preview page size must be between 1 and 200."
        }
        require(requestGeneration >= 0L) { "Request generation must not be negative." }
        requireValidChildSummaryParent(scope, childPeriodKind)
        require((childPeriodKind == QueryPeriodKind.year) == (yearWindow != null)) {
            "An explicit year window is required only for an all-time year deck."
        }
        preparationCheckpoint()
        val queryStartedAtNanos = System.nanoTime()
        val native = database.withTransaction {
            val partnerEntities = partnerRepository.allEntities()
            val sqlWhere = where(
                scope = scope,
                expandedPartnerIdsOverride = expandPartnerSelection(
                    selectedPartnerIds = scope.partnerIds,
                    allPartners = partnerEntities,
                ),
            )
            val parentTotal = queryTotal(sqlWhere)
            val childValues = finiteChildValues(scope, childPeriodKind, yearWindow)
            val aggregateRows = queryTimeChildAggregateRows(
                sqlWhere = sqlWhere,
                childPeriodKind = childPeriodKind,
                yearWindow = yearWindow,
            )
            val aggregatesByValue = aggregateRows
                .filter { it.groupId in childValues }
                .associateBy { it.groupId }
            val retained = scanPreparedRows(
                sqlWhere = sqlWhere,
                childPeriodKind = childPeriodKind,
                childValues = childValues,
                requiredRowsByChild = aggregatesByValue.mapValues { (_, aggregate) ->
                    minOf(aggregate.entryCount, previewPageSize.toLong() + 1L).toInt()
                },
                previewPageSize = previewPageSize,
            )
            PreparedNativeRead(
                parentTotal = parentTotal,
                childValues = childValues,
                aggregatesByValue = aggregatesByValue,
                retained = retained,
                categories = categoryRepository.allEntities().associateBy { it.id },
                partners = partnerEntities.associateBy { it.id },
                coreRevision = currentCoreRevision(),
                aggregateBucketCount = aggregateRows.size,
            )
        }
        require(native.coreRevision > 0L) {
            "A seed-complete nonzero core revision is required for prepared decks."
        }
        val queryDurationNanos = System.nanoTime() - queryStartedAtNanos

        val mappingStartedAtNanos = System.nanoTime()
        val coroutineContext = currentCoroutineContext()
        val parentSlice = materializeSlice(
            scope = scope,
            coreRevision = native.coreRevision,
            totalMinor = native.parentTotal.amountScaled100,
            entryCount = native.parentTotal.entryCount,
            retainedRows = native.retained.parentRows,
            pageSize = previewPageSize,
            categories = native.categories,
            partners = native.partners,
        )
        val children = native.childValues.map { childPeriodValue ->
            coroutineContext.ensureActive()
            val childScope = childScope(scope, childPeriodKind, childPeriodValue)
            val aggregate = native.aggregatesByValue[childPeriodValue]
            FluviPreparedChildFrame(
                childPeriodValue = childPeriodValue,
                slice = materializeSlice(
                    scope = childScope,
                    coreRevision = native.coreRevision,
                    totalMinor = aggregate?.amountScaled100 ?: 0L,
                    entryCount = aggregate?.entryCount ?: 0L,
                    retainedRows = native.retained.childRows[childPeriodValue].orEmpty(),
                    pageSize = previewPageSize,
                    categories = native.categories,
                    partners = native.partners,
                ),
            )
        }
        val mappingDurationNanos = System.nanoTime() - mappingStartedAtNanos
        return FluviPreparedDeck(
            parentQueryKey = scope.canonicalKey,
            direction = scope.direction,
            childPeriodKind = childPeriodKind,
            coreRevision = native.coreRevision,
            previewPageSize = previewPageSize,
            requestGeneration = requestGeneration,
            parentSlice = parentSlice,
            children = children,
            buildMetrics = FluviPreparedDeckBuildMetrics(
                sqlCallCount = PREPARED_DECK_SQL_CALL_COUNT,
                aggregateBucketCount = native.aggregateBucketCount,
                scannedLedgerRowCount = native.retained.scannedRowCount,
                materializedPreviewRowCount = native.retained.materializedRowCount,
                queryDurationNanos = queryDurationNanos,
                mappingDurationNanos = mappingDurationNanos,
            ),
        )
    }

    private fun finiteChildValues(
        scope: FluviQueryScope,
        childPeriodKind: QueryPeriodKind,
        yearWindow: FluviPreparedYearWindow? = null,
    ): List<String> {
        val selection = scope.periodGroups.singleOrNull()
            ?.takeIf { it.key == "time" }
            ?.selections
            ?.singleOrNull()
        return when {
            childPeriodKind == QueryPeriodKind.year && scope.periodGroups.isEmpty() ->
                requireNotNull(yearWindow).values
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
        sqlWhere: SqlWhere,
        childPeriodKind: QueryPeriodKind,
        yearWindow: FluviPreparedYearWindow?,
    ): List<FluviLedgerAggregateBucketRow> {
        val bucketExpression = bucketExpression(childPeriodKind)
        val arguments = sqlWhere.arguments.toMutableList()
        val windowPredicate = if (yearWindow == null) {
            ""
        } else {
            arguments += yearWindow.startYear.toString().padStart(4, '0')
            arguments += yearWindow.endYearInclusive.toString().padStart(4, '0')
            " AND $bucketExpression BETWEEN ? AND ?"
        }
        return ledger.queryAggregateBuckets(
            SimpleSQLiteQuery(
                "SELECT $bucketExpression AS group_id, COUNT(*) AS entry_count, " +
                    "COALESCE(SUM(amount_scaled_100), 0) AS amount_scaled_100 " +
                    "FROM fluvi_ledger_entries " + sqlWhere.sql + windowPredicate +
                    " GROUP BY $bucketExpression ORDER BY group_id ASC",
                arguments.toTypedArray(),
            ),
        )
    }

    private fun bucketExpression(childPeriodKind: QueryPeriodKind): String =
        when (childPeriodKind) {
            QueryPeriodKind.year ->
                "strftime('%Y', booked_local_epoch_day * 86400, 'unixepoch')"
            QueryPeriodKind.month ->
                "strftime('%Y-%m', booked_local_epoch_day * 86400, 'unixepoch')"
            QueryPeriodKind.day ->
                "strftime('%Y-%m-%d', booked_local_epoch_day * 86400, 'unixepoch')"
        }

    private suspend fun queryTotal(sqlWhere: SqlWhere): FluviLedgerTotal {
        val row = ledger.queryAggregate(
            SimpleSQLiteQuery(
                "SELECT COUNT(*) AS entry_count, " +
                    "COALESCE(SUM(amount_scaled_100), 0) AS amount_scaled_100 " +
                    "FROM fluvi_ledger_entries " + sqlWhere.sql,
                sqlWhere.arguments.toTypedArray(),
            ),
        )
        return FluviLedgerTotal(row.entryCount, row.amountScaled100)
    }

    private suspend fun scanPreparedRows(
        sqlWhere: SqlWhere,
        childPeriodKind: QueryPeriodKind,
        childValues: List<String>,
        requiredRowsByChild: Map<String, Int>,
        previewPageSize: Int,
    ): PreparedRetainedRows {
        val childValueSet = childValues.toHashSet()
        val childRows = childValues.associateWith {
            mutableListOf<FluviLedgerEntryEntity>()
        }
        var incompleteChildCount = requiredRowsByChild.count { it.value > 0 }
        val parentRows = mutableListOf<FluviLedgerEntryEntity>()
        val parentLimit = previewPageSize + 1
        var scannedRowCount = 0
        val cursor = database.openHelper.readableDatabase.query(
            SimpleSQLiteQuery(
                "SELECT * FROM fluvi_ledger_entries " + sqlWhere.sql +
                    " ORDER BY booked_local_epoch_day DESC, " +
                    "booked_local_time_minutes DESC, id DESC",
                sqlWhere.arguments.toTypedArray(),
            ),
        )
        cursor.use {
            while (it.moveToNext()) {
                scannedRowCount += 1
                if (scannedRowCount % CANCELLATION_CHECK_INTERVAL == 0) {
                    currentCoroutineContext().ensureActive()
                }
                val epochDay = it.getLong(it.getColumnIndexOrThrow("booked_local_epoch_day"))
                val childValue = childValue(epochDay, childPeriodKind)
                val childRequired = requiredRowsByChild[childValue] ?: 0
                val retainedChildRows = childRows[childValue]
                val needsParent = parentRows.size < parentLimit
                val needsChild = childValue in childValueSet &&
                    retainedChildRows != null && retainedChildRows.size < childRequired
                if (needsParent || needsChild) {
                    val row = it.toLedgerEntry()
                    if (needsParent) parentRows += row
                    if (needsChild) {
                        retainedChildRows += row
                        if (retainedChildRows.size == childRequired) {
                            incompleteChildCount -= 1
                        }
                    }
                }
                if (parentRows.size >= parentLimit && incompleteChildCount == 0) break
            }
        }
        return PreparedRetainedRows(
            parentRows = parentRows,
            childRows = childRows,
            scannedRowCount = scannedRowCount,
            materializedRowCount = parentRows.size + childRows.values.sumOf { it.size },
        )
    }

    private fun materializeSlice(
        scope: FluviQueryScope,
        coreRevision: Long,
        totalMinor: Long,
        entryCount: Long,
        retainedRows: List<FluviLedgerEntryEntity>,
        pageSize: Int,
        categories: Map<String, FluviCategoryEntity>,
        partners: Map<String, FluviPartnerEntity>,
    ): FluviDashboardLedgerSlice {
        val pageRows = retainedRows.take(pageSize)
        return FluviDashboardLedgerSlice(
            queryKey = scope.canonicalKey,
            coreRevision = coreRevision,
            direction = scope.direction,
            timeScopeKey = scope.timeCanonicalKey,
            totalMinor = totalMinor,
            entryCount = entryCount,
            entries = pageRows.map { it.toDashboardRow(categories, partners) },
            nextCursor = if (retainedRows.size > pageSize) pageRows.last().toCursor() else null,
        )
    }

    private fun childValue(epochDay: Long, kind: QueryPeriodKind): String {
        val date = LocalDate.ofEpochDay(epochDay)
        return when (kind) {
            QueryPeriodKind.year -> "%04d".format(Locale.ROOT, date.year)
            QueryPeriodKind.month -> "%04d-%02d".format(
                Locale.ROOT,
                date.year,
                date.monthValue,
            )
            QueryPeriodKind.day -> "%04d-%02d-%02d".format(
                Locale.ROOT,
                date.year,
                date.monthValue,
                date.dayOfMonth,
            )
        }
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
        expandedPartnerIdsOverride: Set<String>? = null,
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
        (expandedPartnerIdsOverride ?: expandedPartnerIds(scope.partnerIds))
            .sorted()
            .takeIf { it.isNotEmpty() }
            ?.let { partnerIds ->
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

    private data class PreparedRetainedRows(
        val parentRows: List<FluviLedgerEntryEntity>,
        val childRows: Map<String, List<FluviLedgerEntryEntity>>,
        val scannedRowCount: Int,
        val materializedRowCount: Int,
    )

    private data class PreparedNativeRead(
        val parentTotal: FluviLedgerTotal,
        val childValues: List<String>,
        val aggregatesByValue: Map<String, FluviLedgerAggregateBucketRow>,
        val retained: PreparedRetainedRows,
        val categories: Map<String, FluviCategoryEntity>,
        val partners: Map<String, FluviPartnerEntity>,
        val coreRevision: Long,
        val aggregateBucketCount: Int,
    )

    private data class SqlWhere(
        val sql: String,
        val arguments: List<Any>,
    )

    private companion object {
        const val DEFAULT_PAGE_SIZE = 50
        const val MAX_PAGE_SIZE = 200
        const val PREPARED_DECK_SQL_CALL_COUNT = 6
        const val CANCELLATION_CHECK_INTERVAL = 128
    }
}
