package com.fluvi.app

import com.fluvi.app.dashboard.DashboardQueryArguments
import com.fluvi.core.model.LedgerDirection
import org.junit.Assert.assertEquals
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

    private fun dashboardStreamArguments(): Map<String, Any?> = mapOf(
        "direction" to "INCOME",
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
