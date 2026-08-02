package com.fluvi.core.query

import androidx.sqlite.db.SimpleSQLiteQuery
import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.entity.FluviLedgerEntryEntity
import com.fluvi.core.model.QueryPeriodKind
import com.fluvi.core.repository.FluviCategoryRepository
import com.fluvi.core.repository.FluviPartnerRepository
import kotlinx.coroutines.ExperimentalCoroutinesApi
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
) {
    private val ledger = database.ledgerDao()

    suspend fun timeline(
        scope: FluviQueryScope,
        after: FluviTimelineCursor? = null,
        pageSize: Int = DEFAULT_PAGE_SIZE,
    ): FluviLedgerTimelinePage<FluviLedgerEntryEntity> {
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
        return FluviLedgerTimelinePage(pageEntries, nextCursor)
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
        val rows = page.entries.map { entry ->
            val category = requireNotNull(categories[entry.categoryId]) {
                "Unknown category ID in dashboard row: ${entry.categoryId}"
            }
            val partner = requireNotNull(partners[entry.partnerId]) {
                "Unknown partner ID in dashboard row: ${entry.partnerId}"
            }
            FluviDashboardLedgerRow(
                entryId = entry.id,
                direction = entry.direction,
                amountMinor = entry.amountScaled100,
                bookedLocalEpochDay = entry.bookedLocalEpochDay,
                bookedLocalTimeMinutes = entry.bookedLocalTimeMinutes,
                occurredAtUtcMs = entry.occurredAtUtcMs,
                partnerId = entry.partnerId,
                partnerDisplayName = partner.displayNameOverride ?: partner.originalName,
                categoryId = category.id,
                categoryDisplayName = category.name,
                categoryColorId = category.colorId,
                categoryIconId = category.iconId,
                assignmentMode = entry.categoryAssignmentMode,
                originKind = entry.originKind,
                note = entry.note,
            )
        }
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

    suspend fun currentCoreRevision(): Long = requireNotNull(
        database.appSettingsDao().current(),
    ) { "The Fluvi app settings row is missing." }.coreRevision

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
        return ledger.queryGroupedSummaries(
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

    private data class SqlWhere(
        val sql: String,
        val arguments: List<Any>,
    )

    private companion object {
        const val DEFAULT_PAGE_SIZE = 50
        const val MAX_PAGE_SIZE = 200
    }
}
