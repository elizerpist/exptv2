package com.fluvi.app.dashboard

import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.QueryPeriodKind
import com.fluvi.core.query.FluviPeriodGroup
import com.fluvi.core.query.FluviPeriodSelection
import com.fluvi.core.query.FluviQueryRefinements
import com.fluvi.core.query.FluviQueryScope
import com.fluvi.core.query.FluviTimelineCursor

/**
 * The single platform-adapter decoder for dashboard query payloads.
 *
 * Both the MethodChannel read and the EventChannel observer call this object,
 * so transport metadata (for example `subscriptionId`) cannot leak into the
 * domain [FluviQueryRefinements] contract.
 */
object DashboardQueryArguments {
    fun requireMap(raw: Any?, label: String): Map<*, *> {
        require(raw is Map<*, *>) { "$label must be a map." }
        return raw
    }

    fun scopeFrom(arguments: Map<*, *>): FluviQueryScope {
        val direction = LedgerDirection.valueOf(
            requireValue<String>(arguments, "direction"),
        )
        val periodGroups = queryList(arguments, "periodGroups").map { rawGroup ->
            val group = requireMap(rawGroup, "period group")
            val selections = queryList(group, "selections").map { rawSelection ->
                val selection = requireMap(rawSelection, "period selection")
                FluviPeriodSelection(
                    kind = QueryPeriodKind.valueOf(
                        requireValue<String>(selection, "kind"),
                    ),
                    value = requireValue(selection, "value"),
                )
            }.toSet()
            FluviPeriodGroup(
                key = requireValue(group, "key"),
                selections = selections,
            )
        }
        val refinements = requireMap(arguments["refinements"], "refinements")
        val supportedRefinements = setOf(
            "minimumAmountScaled100",
            "maximumAmountScaled100",
            "noteContains",
        )
        require(refinements.keys.all { it.toString() in supportedRefinements }) {
            "Unsupported query refinements: " +
                refinements.keys.filterNot { it.toString() in supportedRefinements }
        }

        return FluviQueryScope(
            direction = direction,
            periodGroups = periodGroups,
            categoryIds = queryStringSet(arguments, "categoryIds"),
            partnerIds = queryStringSet(arguments, "partnerIds"),
            refinements = FluviQueryRefinements(
                minimumAmountScaled100 = queryNumber(
                    refinements,
                    "minimumAmountScaled100",
                )?.toLong(),
                maximumAmountScaled100 = queryNumber(
                    refinements,
                    "maximumAmountScaled100",
                )?.toLong(),
                noteContains = refinements["noteContains"] as String?,
            ),
        )
    }

    fun pageSize(arguments: Map<*, *>): Int {
        val raw = queryNumber(arguments, "pageSize")?.toInt() ?: 50
        require(raw in 1..200) { "pageSize must be between 1 and 200." }
        return raw
    }

    fun maxDayGroups(arguments: Map<*, *>): Int {
        val raw = queryNumber(arguments, "maxDayGroups")?.toInt() ?: 7
        require(raw in 1..31) { "maxDayGroups must be between 1 and 31." }
        return raw
    }

    fun beforeLocalEpochDayExclusive(arguments: Map<*, *>): Long? =
        queryNumber(arguments, "beforeLocalEpochDayExclusive")?.toLong()

    fun childPeriodKind(arguments: Map<*, *>): QueryPeriodKind =
        QueryPeriodKind.valueOf(requireValue(arguments, "childPeriod"))

    fun cursor(arguments: Map<*, *>): FluviTimelineCursor? {
        val raw = arguments["after"] ?: return null
        val cursor = requireMap(raw, "dashboard cursor")
        return FluviTimelineCursor(
            bookedLocalEpochDay = requireNotNull(
                queryNumber(cursor, "bookedLocalEpochDay"),
            ).toLong(),
            bookedLocalTimeMinutes = requireNotNull(
                queryNumber(cursor, "bookedLocalTimeMinutes"),
            ).toInt(),
            entryId = requireValue(cursor, "entryId"),
        )
    }

    private fun queryList(arguments: Map<*, *>, key: String): List<Any?> {
        val raw = arguments[key]
        require(raw is List<*>) { "$key must be a list." }
        return raw
    }

    private fun queryStringSet(arguments: Map<*, *>, key: String): Set<String> =
        queryList(arguments, key).map { value ->
            require(value is String) { "$key must contain strings." }
            value
        }.toSet()

    private fun queryNumber(arguments: Map<*, *>, key: String): Number? {
        val raw = arguments[key] ?: return null
        require(raw is Number) { "$key must be numeric." }
        return raw
    }

    @Suppress("UNCHECKED_CAST")
    fun <T> requireValue(arguments: Map<*, *>, key: String): T =
        requireNotNull(arguments[key]) { "Missing query argument: $key" } as T
}
