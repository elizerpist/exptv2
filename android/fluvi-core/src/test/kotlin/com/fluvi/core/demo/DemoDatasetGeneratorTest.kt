package com.fluvi.core.demo

import com.fluvi.core.model.CategoryAssignmentMode
import com.fluvi.core.model.LedgerDirection
import java.time.LocalDate
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class DemoDatasetGeneratorTest {
    @Test
    fun generatesSevenMonthsWithExactlyOneHundredEntriesPerMonth() {
        val plan = DemoDatasetGenerator().generate()

        assertEquals(DemoDatasetVersion.current, plan.version)
        assertEquals(10, plan.categories.size)
        assertEquals(700, plan.entries.size)

        val countsByMonth = plan.entries.groupingBy { entry ->
            LocalDate.ofEpochDay(entry.bookedLocalEpochDay).withDayOfMonth(1)
        }.eachCount()

        assertEquals(
            (1..7).associate { month ->
                LocalDate.of(2026, month, 1) to 100
            },
            countsByMonth,
        )
    }

    @Test
    fun eachMonthHasSixIncomeAndNinetyFourExpenseEntriesAtExactTargets() {
        val plan = DemoDatasetGenerator().generate()

        plan.monthlyReports.forEach { report ->
            assertEquals(100, report.entryCount)
            assertEquals(6, report.incomeCount)
            assertEquals(94, report.expenseCount)
            assertEquals(report.incomeTargetScaled100, report.incomeTotalScaled100)
            assertEquals(report.expenseTargetScaled100, report.expenseTotalScaled100)
            assertTrue(report.expenseTotalScaled100 in 600_000L * 100..800_000L * 100)
        }
    }

    @Test
    fun containsLowMediumRecurringHighAndOverrideEntries() {
        val plan = DemoDatasetGenerator().generate()
        val expenses = plan.entries
            .filter { it.direction == LedgerDirection.expense }
            .map { it.amountScaled100 }

        assertTrue(expenses.any { it <= 1_500L * 100 })
        assertTrue(expenses.any { it in 5_000L * 100..30_000L * 100 })
        assertTrue(expenses.any { it >= 70_000L * 100 })
        assertTrue(
            plan.entries.any {
                it.assignmentMode == CategoryAssignmentMode.entryOverride
            },
        )
        val categoryById = plan.categories.associateBy { it.id }
        val partnerCategoryById = plan.partners.associate { it.id to it.defaultCategoryId }
        assertTrue(
            plan.entries.any { entry ->
                entry.assignmentMode == CategoryAssignmentMode.entryOverride &&
                    entry.categoryId != partnerCategoryById.getValue(entry.partnerId) &&
                    categoryById.containsKey(entry.categoryId)
            },
        )
    }

    @Test
    fun generatedPlansAreDeterministicAndUseOnlyCatalogIds() {
        val first = DemoDatasetGenerator().generate()
        val second = DemoDatasetGenerator().generate()

        assertEquals(first, second)
        assertEquals(
            first.categories.map { it.id }.toSet().size,
            first.categories.size,
        )
        assertNotEquals(first.categories.map { it.colorId }.toSet().size, 1)
        assertNotEquals(first.categories.map { it.iconId }.toSet().size, 1)
        assertTrue(first.categories.all { it.colorId.matches(Regex("color_[0-9]{2}")) })
        assertTrue(first.categories.all { it.iconId.matches(Regex("icon_[0-9]{2}")) })
        assertTrue(first.entries.all { it.id.length == 26 })
    }

    @Test
    fun everyEntryFallsInsideTheClosedDemoMonthsAndHasARealisticTime() {
        val plan = DemoDatasetGenerator().generate()
        val start = LocalDate.of(2026, 1, 1).toEpochDay()
        val end = LocalDate.of(2026, 8, 1).toEpochDay()

        assertTrue(plan.entries.all { it.bookedLocalEpochDay in start until end })
        assertTrue(plan.entries.all { it.bookedLocalTimeMinutes in 0..1_439 })
        assertTrue(plan.entries.any { it.bookedLocalTimeMinutes != 0 })
        assertTrue(plan.entries.all { it.amountScaled100 > 0L })
    }
}
