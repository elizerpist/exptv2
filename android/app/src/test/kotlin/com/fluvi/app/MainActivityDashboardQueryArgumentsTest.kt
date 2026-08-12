package com.fluvi.app

import com.fluvi.app.dashboard.DashboardQueryArguments
import com.fluvi.app.dashboard.DashboardPreparedIndexAcquisitionReasons
import com.fluvi.core.model.LedgerDirection
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Locks the platform-channel contract used by global index and explicit page
 * reads. Transport metadata must not be interpreted as query refinements.
 */
class MainActivityDashboardQueryArgumentsTest {
    @Test
    fun `prepared index acquisition allow list accepts query and rejects unknown reasons`() {
        assertTrue(DashboardPreparedIndexAcquisitionReasons.isAllowed("bootstrap"))
        assertTrue(DashboardPreparedIndexAcquisitionReasons.isAllowed("databaseRevision"))
        assertTrue(DashboardPreparedIndexAcquisitionReasons.isAllowed("query"))
        assertThrows(IllegalArgumentException::class.java) {
            DashboardPreparedIndexAcquisitionReasons.requireAllowed("illegal")
        }
    }

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
    fun `prepared index arguments decode independent income and expense filters`() {
        val income = dashboardArguments().toMutableMap().apply {
            put("direction", "income")
            put("periodGroups", emptyList<Map<String, Any?>>())
            put("categoryIds", emptyList<String>())
        }
        val expense = dashboardArguments().toMutableMap().apply {
            put("direction", "expense")
            put(
                "periodGroups",
                listOf(
                    mapOf(
                        "key" to "time",
                        "selections" to listOf(
                            mapOf("kind" to "month", "value" to "2026-06"),
                            mapOf("kind" to "month", "value" to "2026-08"),
                        ),
                    ),
                ),
            )
            put("categoryIds", listOf("food"))
        }

        val filters = DashboardQueryArguments.directionalFiltersFrom(
            mapOf("incomeFilter" to income, "expenseFilter" to expense),
        )

        assertEquals(LedgerDirection.income, filters.income.direction)
        assertEquals(emptySet<String>(), filters.income.categoryIds)
        assertEquals(LedgerDirection.expense, filters.expense.direction)
        assertEquals(setOf("food"), filters.expense.categoryIds)
        assertEquals(2, filters.expense.periodGroups.single().selections.size)
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
