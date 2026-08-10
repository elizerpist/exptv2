package com.fluvi.app.query

import com.fluvi.app.dashboard.DashboardQueryArguments
import com.fluvi.core.FluviCore
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.query.FluviPeriodGroup
import com.fluvi.core.query.FluviQueryMenuFacets
import com.fluvi.core.query.FluviQueryScope
import com.fluvi.core.query.FluviSavedQuery
import io.flutter.plugin.common.MethodCall

/**
 * Small Android transport adapter for the production Query Menu.
 *
 * It deliberately maps typed core results only. Room, SQL and saved-query
 * workflows stay inside fluvi-core, while MainActivity stays a composition
 * point instead of becoming another repository.
 */
internal class QueryMenuMethodBridge {
    suspend fun handle(call: MethodCall, core: FluviCore): Any? = when (call.method) {
        "readQueryMenuFacets" -> core.query.queryMenuFacets(scope(call)).toMap()
        "createSavedQuery" -> core.snapshots.create(
            name = requireArgument(call, "name"),
            scope = scope(call),
        ).let(::savedQueryMap)
        "listSavedQueries" -> core.snapshots.list(
            LedgerDirection.valueOf(requireArgument(call, "direction")),
        ).map(::savedQueryMap)
        "loadSavedQuery" -> core.snapshots.load(
            snapshotId = requireArgument(call, "id"),
            activeDirection = LedgerDirection.valueOf(requireArgument(call, "direction")),
        ).let(::savedQueryMap)
        "updateSavedQuery" -> core.snapshots.update(
            snapshotId = requireArgument(call, "id"),
            name = requireArgument(call, "name"),
            scope = scope(call),
        ).let(::savedQueryMap)
        "renameSavedQuery" -> core.snapshots.rename(
            snapshotId = requireArgument(call, "id"),
            name = requireArgument(call, "name"),
        ).let(::savedQueryMap)
        "deleteSavedQuery" -> {
            core.snapshots.delete(requireArgument(call, "id"))
            null
        }
        else -> throw IllegalArgumentException("Unknown Query Menu method: ${call.method}")
    }

    private fun scope(call: MethodCall): FluviQueryScope = DashboardQueryArguments.scopeFrom(
        DashboardQueryArguments.requireMap(call.arguments, "Query Menu arguments"),
    )

    private fun FluviQueryMenuFacets.toMap(): Map<String, Any?> = mapOf(
        "result" to mapOf(
            "entryCount" to result.entryCount,
            "amountScaled100" to result.amountScaled100,
        ),
        "amountDomain" to mapOf(
            "minimumAmountScaled100" to amountDomain.minimumAmountScaled100,
            "maximumAmountScaled100" to amountDomain.maximumAmountScaled100,
        ),
        "availableMonths" to availableMonths.map { month ->
            mapOf("year" to month.year, "month" to month.month)
        },
        "categories" to categories.map { category ->
            mapOf(
                "id" to category.id,
                "displayName" to category.displayName,
                "colorId" to category.colorId,
                "iconId" to category.iconId,
                "entryCount" to category.entryCount,
            )
        },
        "partners" to partners.map { partner ->
            mapOf(
                "id" to partner.id,
                "displayName" to partner.displayName,
                "categoryId" to partner.categoryId,
                "categoryColorId" to partner.categoryColorId,
                "categoryIconId" to partner.categoryIconId,
                "entryCount" to partner.entryCount,
            )
        },
    )

    private fun savedQueryMap(savedQuery: FluviSavedQuery): Map<String, Any?> = mapOf(
        "id" to savedQuery.id,
        "name" to savedQuery.name,
        "direction" to savedQuery.scope.direction.name,
        "periodGroups" to savedQuery.scope.periodGroups.toMaps(),
        "categoryIds" to savedQuery.scope.categoryIds.sorted(),
        "partnerIds" to savedQuery.scope.partnerIds.sorted(),
        "refinements" to mapOf(
            "minimumAmountScaled100" to savedQuery.scope.refinements.minimumAmountScaled100,
            "maximumAmountScaled100" to savedQuery.scope.refinements.maximumAmountScaled100,
            "noteContains" to savedQuery.scope.refinements.noteContains,
        ),
        "createdAtUtcMs" to savedQuery.createdAtUtcMs,
        "updatedAtUtcMs" to savedQuery.updatedAtUtcMs,
    )

    private fun List<FluviPeriodGroup>.toMaps(): List<Map<String, Any>> = map { group ->
        mapOf(
            "key" to group.key,
            "selections" to group.selections
                .sortedWith(compareBy({ it.kind.ordinal }, { it.value }))
                .map { selection ->
                    mapOf("kind" to selection.kind.name, "value" to selection.value)
                },
        )
    }

    private inline fun <reified T> requireArgument(call: MethodCall, key: String): T =
        requireNotNull(call.argument<T>(key)) { "Missing Query Menu argument: $key" }
}
