package com.fluvi.core.query

import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.QueryPeriodKind

/**
 * Canonical identity for one dashboard presentation scope.
 *
 * A committed dashboard read contains two independently meaningful time
 * inputs: the structural scope currently navigated by the dashboard and an
 * optional Query Menu temporal restriction. The former is transported as the
 * `navigation` period group so SQL can intersect it with the latter, but that
 * transport key must never become part of the dashboard [timeScopeKey].
 *
 * Prepared dashboard frames already receive their structural scope separately;
 * both paths deliberately enter this owner so their identities cannot drift.
 */
internal data class FluviDashboardScopeIdentity(
    val timeScopeKey: String,
    val queryKey: String,
) {
    companion object {
        internal const val NAVIGATION_PERIOD_GROUP_KEY = "navigation"

        fun forCommitted(scope: FluviQueryScope): FluviDashboardScopeIdentity {
            val navigationGroups = scope.periodGroups.filter {
                it.key == NAVIGATION_PERIOD_GROUP_KEY
            }
            require(navigationGroups.size <= 1) {
                "Dashboard scope may contain at most one navigation period group."
            }
            val navigationSelection = navigationGroups.singleOrNull()
                ?.selections
                ?.singleOrNull()
            require(navigationGroups.isEmpty() || navigationSelection != null) {
                "Dashboard navigation period group must contain exactly one selection."
            }
            return create(
                direction = scope.direction,
                timeScopeKey = navigationSelection?.canonicalDashboardTimeScopeKey ?: "all",
                queryPeriodGroups = scope.periodGroups.filterNot {
                    it.key == NAVIGATION_PERIOD_GROUP_KEY
                },
                categoryIds = scope.categoryIds,
                partnerIds = scope.partnerIds,
                refinements = scope.refinements,
            )
        }

        fun forPreparedFrame(
            direction: LedgerDirection,
            timeScopeKey: String,
            queryPeriodGroups: List<FluviPeriodGroup>,
            categoryIds: Set<String>,
            partnerIds: Set<String>,
            refinements: FluviQueryRefinements,
        ): FluviDashboardScopeIdentity {
            require(timeScopeKey.isCanonicalDashboardTimeScopeKey()) {
                "Invalid dashboard structural time scope: $timeScopeKey"
            }
            require(queryPeriodGroups.none { it.key == NAVIGATION_PERIOD_GROUP_KEY }) {
                "Prepared dashboard frames cannot contain a navigation period group."
            }
            return create(
                direction = direction,
                timeScopeKey = timeScopeKey,
                queryPeriodGroups = queryPeriodGroups,
                categoryIds = categoryIds,
                partnerIds = partnerIds,
                refinements = refinements,
            )
        }

        private fun create(
            direction: LedgerDirection,
            timeScopeKey: String,
            queryPeriodGroups: List<FluviPeriodGroup>,
            categoryIds: Set<String>,
            partnerIds: Set<String>,
            refinements: FluviQueryRefinements,
        ): FluviDashboardScopeIdentity {
            val queryKey = buildList {
                add(direction.name)
                add(timeScopeKey)
                add("categories:${categoryIds.sorted().joinToString(",")}")
                add("partners:${partnerIds.sorted().joinToString(",")}")
                add("refinements:${refinements.canonicalDashboardKey}")
                queryPeriodGroups.takeIf { it.isNotEmpty() }?.let { groups ->
                    add("periods:${groups.canonicalDashboardFilterKey}")
                }
            }.joinToString("|")
            return FluviDashboardScopeIdentity(timeScopeKey, queryKey)
        }

        private val FluviPeriodSelection.canonicalDashboardTimeScopeKey: String
            get() = when (kind) {
                QueryPeriodKind.year -> "year:$value"
                QueryPeriodKind.month -> "month:$value"
                QueryPeriodKind.day -> "day:$value"
            }

        private val List<FluviPeriodGroup>.canonicalDashboardFilterKey: String
            get() = sortedBy { it.key }.joinToString(";") { group ->
                group.key + "=" + group.selections
                    .sortedWith(compareBy({ it.kind.ordinal }, { it.value }))
                    .joinToString(",") { it.canonicalDashboardTimeScopeKey }
            }

        private val FluviQueryRefinements.canonicalDashboardKey: String
            get() = listOfNotNull(
                minimumAmountScaled100?.let { "minimumAmountScaled100=$it" },
                maximumAmountScaled100?.let { "maximumAmountScaled100=$it" },
                noteContains?.let { "noteContains=$it" },
            ).joinToString(",")

        private fun String.isCanonicalDashboardTimeScopeKey(): Boolean =
            this == "all" ||
                Regex("year:[0-9]{4}").matches(this) ||
                Regex("month:[0-9]{4}-(0[1-9]|1[0-2])").matches(this) ||
                Regex("day:[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])")
                    .matches(this)
    }
}
