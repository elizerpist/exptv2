package com.fluvi.app

import com.fluvi.app.dashboard.DashboardQueryArguments
import com.fluvi.core.model.LedgerDirection
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

/**
 * Locks the platform-channel contract used by global index and explicit page
 * reads. Transport metadata must not be interpreted as query refinements.
 */
class MainActivityDashboardQueryArgumentsTest {
    @Test
    fun `runtime arguments read refinements from their nested map`() {
        val scope = DashboardQueryArguments.scopeFrom(dashboardArguments())

        assertEquals(LedgerDirection.income, scope.direction)
        assertEquals(emptySet<String>(), scope.categoryIds)
        assertEquals(emptySet<String>(), scope.partnerIds)
        assertEquals(null, scope.refinements.minimumAmountScaled100)
        assertEquals(null, scope.refinements.maximumAmountScaled100)
        assertEquals(null, scope.refinements.noteContains)
    }

    @Test
    fun `index generation is decoded without entering query scope`() {
        val arguments = dashboardArguments() + mapOf("requestGeneration" to 17)

        assertEquals(17L, DashboardQueryArguments.requestGeneration(arguments))
    }

    @Test
    fun `prepared year window requires both explicit bounds`() {
        val arguments = dashboardArguments() + mapOf(
            "yearWindowStart" to 2014,
            "yearWindowEndInclusive" to 2038,
        )

        val window = DashboardQueryArguments.preparedYearWindow(arguments)

        assertEquals(2014, window?.startYear)
        assertEquals(2038, window?.endYearInclusive)
        assertThrows(IllegalArgumentException::class.java) {
            DashboardQueryArguments.preparedYearWindow(
                dashboardArguments() + mapOf("yearWindowStart" to 2014),
            )
        }
    }

    private fun dashboardArguments(): Map<String, Any?> = mapOf(
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
        // Runtime transport metadata must not be validated as a refinement.
        "scopeKey" to "income|month:2026-07|categories:|partners:|refinements:",
        "pageSize" to 50,
        "acquisitionReason" to "bootstrap",
    )
}
