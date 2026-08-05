package com.fluvi.app

import com.fluvi.app.dashboard.DashboardQueryArguments
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.QueryPeriodKind
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

/**
 * Locks the platform-channel contract used by both the one-shot dashboard read
 * and the EventChannel observer. Transport/debug metadata must not be
 * interpreted as query refinements.
 */
class MainActivityDashboardQueryArgumentsTest {
    @Test
    fun `event channel arguments read refinements from their nested map`() {
        val scope = DashboardQueryArguments.scopeFrom(dashboardStreamArguments())

        assertEquals(LedgerDirection.income, scope.direction)
        assertEquals(emptySet<String>(), scope.categoryIds)
        assertEquals(emptySet<String>(), scope.partnerIds)
        assertEquals(null, scope.refinements.minimumAmountScaled100)
        assertEquals(null, scope.refinements.maximumAmountScaled100)
        assertEquals(null, scope.refinements.noteContains)
    }

    @Test
    fun `child summary period is decoded separately from refinements`() {
        val arguments = dashboardStreamArguments() + ("childPeriod" to "day")

        assertEquals(QueryPeriodKind.day, DashboardQueryArguments.childPeriodKind(arguments))
    }

    @Test
    fun `child preview request identity is decoded without entering query scope`() {
        val arguments = dashboardStreamArguments() + mapOf(
            "requestGeneration" to 17,
            "requestId" to "expense|month:2026-03|child:day|page:24|generation:17",
        )

        assertEquals(17L, DashboardQueryArguments.requestGeneration(arguments))
        assertEquals(
            "expense|month:2026-03|child:day|page:24|generation:17",
            DashboardQueryArguments.requestId(arguments),
        )
    }

    @Test
    fun `prepared year window requires both explicit bounds`() {
        val arguments = dashboardStreamArguments() + mapOf(
            "yearWindowStart" to 2014,
            "yearWindowEndInclusive" to 2038,
        )

        val window = DashboardQueryArguments.preparedYearWindow(arguments)

        assertEquals(2014, window?.startYear)
        assertEquals(2038, window?.endYearInclusive)
        assertThrows(IllegalArgumentException::class.java) {
            DashboardQueryArguments.preparedYearWindow(
                dashboardStreamArguments() + mapOf("yearWindowStart" to 2014),
            )
        }
    }

    private fun dashboardStreamArguments(): Map<String, Any?> = mapOf(
        "direction" to "income",
        "periodGroups" to listOf(
            mapOf(
                "key" to "time",
                "selections" to listOf(
                    mapOf(
                        "kind" to "month",
                        "value" to "2026-07",
                    ),
                ),
            ),
        ),
        "categoryIds" to emptyList<String>(),
        "partnerIds" to emptyList<String>(),
        "refinements" to emptyMap<String, Any?>(),
        // EventChannel metadata is deliberately present: it must not be
        // validated as a refinement.
        "scopeKey" to "income|month:2026-07|categories:|partners:|refinements:",
        "pageSize" to 50,
        "debugFlowId" to "Q-income|month:2026-07",
        "subscriptionId" to "Q-income|month:2026-07:#1",
    )
}
