package com.fluvi.core.demo

import com.fluvi.core.model.CategoryAssignmentMode
import com.fluvi.core.model.LedgerDirection
import java.time.LocalDate
import java.security.MessageDigest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class DemoDatasetGeneratorTest {
    @Test
    fun preservesRegressionYearsAndAddsTheExact2027FastfoodMirror() {
        val plan = DemoDatasetGenerator().generate()

        assertEquals(DemoDatasetVersion.current, plan.version)
        assertEquals(11, plan.categories.size)
        assertEquals(5_519, plan.entries.size)

        val countsByMonth = plan.entries.groupingBy { entry ->
            LocalDate.ofEpochDay(entry.bookedLocalEpochDay).withDayOfMonth(1)
        }.eachCount()

        assertEquals(
            (1..7).associate { month -> LocalDate.of(2026, month, 1) to 100 } +
                (LocalDate.of(2026, 9, 1) to 1_115),
            countsByMonth.filterKeys { it.year == 2026 },
        )
        assertEquals(
            listOf(288, 296, 304, 312, 291, 299, 307, 315, 286, 294, 302, 310),
            (1..12).map { month ->
                countsByMonth.getValue(LocalDate.of(2025, month, 1))
            },
        )
        assertEquals(
            listOf(16, 15, 14, 12, 8, 7, 8, 6, 3, 4, 3, 4),
            (1..12).map { month ->
                countsByMonth.getValue(LocalDate.of(2027, month, 1))
            },
        )
    }

    @Test
    fun eachMonthHasSixIncomeAndNinetyFourExpenseEntriesAtExactTargets() {
        val plan = DemoDatasetGenerator().generate()

        plan.monthlyReports.filter { it.year == 2026 && it.month in 1..7 }.forEach { report ->
            assertEquals(100, report.entryCount)
            assertEquals(6, report.incomeCount)
            assertEquals(94, report.expenseCount)
            assertEquals(report.incomeTargetScaled100, report.incomeTotalScaled100)
            assertEquals(report.expenseTargetScaled100, report.expenseTotalScaled100)
            assertTrue(report.expenseTotalScaled100 in 600_000L * 100..800_000L * 100)
        }
        val september = plan.monthlyReports.single { it.year == 2026 && it.month == 9 }
        assertEquals(1_115, september.entryCount)
        assertEquals(0, september.incomeCount)
        assertEquals(1_115, september.expenseCount)
        assertEquals(september.expenseTargetScaled100, september.expenseTotalScaled100)
    }

    @Test
    fun directionalYearAndAllTimeCountsRemainAuthoritative() {
        val plan = DemoDatasetGenerator().generate()
        val counts = plan.entries
            .groupBy { entry ->
                LocalDate.ofEpochDay(entry.bookedLocalEpochDay).year to entry.direction
            }
            .mapValues { (_, entries) -> entries.size }

        assertEquals(42, counts.getValue(2026 to LedgerDirection.income))
        assertEquals(1_773, counts.getValue(2026 to LedgerDirection.expense))
        assertEquals(1_804, counts.getValue(2025 to LedgerDirection.income))
        assertEquals(1_800, counts.getValue(2025 to LedgerDirection.expense))
        assertEquals(100, counts.getValue(2027 to LedgerDirection.expense))
        assertEquals(
            1_846,
            plan.entries.count { it.direction == LedgerDirection.income },
        )
        assertEquals(
            3_673,
            plan.entries.count { it.direction == LedgerDirection.expense },
        )
        assertEquals(
            plan.entries.count { it.direction == LedgerDirection.income },
            counts.filterKeys { it.second == LedgerDirection.income }.values.sum(),
        )
        assertEquals(
            plan.entries.count { it.direction == LedgerDirection.expense },
            counts.filterKeys { it.second == LedgerDirection.expense }.values.sum(),
        )
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
    fun generatesTwelveDeterministicHighDensity2025MonthsWithinMonthlyBudgets() {
        val first = DemoDatasetGenerator().generate()
        val second = DemoDatasetGenerator().generate()
        val reports = first.monthlyReports.filter { it.year == 2025 }

        assertEquals(12, reports.size)
        assertEquals(first, second)
        reports.forEach { report ->
            assertTrue(report.entryCount in 280..320)
            assertTrue(report.incomeTotalScaled100 in 600_000L * 100..700_000L * 100)
            assertTrue(report.expenseTotalScaled100 in 600_000L * 100..700_000L * 100)
            assertTrue(
                kotlin.math.abs(
                    report.incomeTotalScaled100 - report.expenseTotalScaled100,
                ) <= 50_000L * 100,
            )

            val entries = first.entries.filter { entry ->
                val date = LocalDate.ofEpochDay(entry.bookedLocalEpochDay)
                date.year == report.year && date.monthValue == report.month
            }
            val entriesPerDay = entries.groupingBy { it.bookedLocalEpochDay }.eachCount()
            assertTrue(entriesPerDay.size >= 26)
            assertTrue(entriesPerDay.values.max() >= 15)
            assertTrue(entriesPerDay.values.min() <= 6)
        }
    }

    @Test
    fun everyEntryFallsInsideTheClosedDemoWindowAndHasARealisticTime() {
        val plan = DemoDatasetGenerator().generate()
        val start = LocalDate.of(2025, 1, 1).toEpochDay()
        val end = LocalDate.of(2028, 1, 1).toEpochDay()

        assertTrue(plan.entries.all { it.bookedLocalEpochDay in start until end })
        assertTrue(plan.entries.all { it.bookedLocalTimeMinutes in 0..1_439 })
        assertTrue(plan.entries.any { it.bookedLocalTimeMinutes != 0 })
        assertTrue(plan.entries.all { it.amountScaled100 > 0L })
    }

    @Test
    fun addsASeptember2026ExpenseFixtureWithDenseHourlySliderThresholds() {
        val plan = DemoDatasetGenerator().generate()
        val september = plan.entries.filter { entry ->
            val date = LocalDate.ofEpochDay(entry.bookedLocalEpochDay)
            date.year == 2026 && date.monthValue == 9
        }
        val expenses = september.filter { it.direction == LedgerDirection.expense }
        val expenseCategoryNames = setOf(
            "Lakhatás", "Élelmiszer", "Közlekedés", "Rezsi", "Egészség",
            "Szórakozás", "Vásárlás", "Előfizetések", "Gyorsétterem",
        )
        val categoryNames = plan.categories.associate { it.id to it.name }
        val byDay = expenses.groupBy { LocalDate.ofEpochDay(it.bookedLocalEpochDay) }
        val byHour = expenses.groupBy { entry ->
            entry.bookedLocalEpochDay to entry.bookedLocalTimeMinutes / 60
        }

        assertEquals(30, byDay.size)
        assertEquals(0, september.count { it.direction == LedgerDirection.income })
        val activeHoursByDay = byDay.values.map { dayEntries ->
            dayEntries.map { it.bookedLocalTimeMinutes / 60 }.toSet().size
        }
        assertTrue(activeHoursByDay.min() >= 8)
        assertTrue(activeHoursByDay.max() <= 14)
        assertTrue(byHour.values.all { it.size in 2..5 })
        assertTrue(byHour.values.count { it.size == 2 } >= 20)
        assertTrue(byHour.values.count { it.size == 3 } >= 20)
        assertTrue(byHour.values.count { it.size == 4 } >= 20)
        assertTrue(byHour.values.count { it.size == 5 } >= 20)
        assertEquals(
            expenseCategoryNames,
            expenses.map { categoryNames.getValue(it.categoryId) }.toSet(),
        )
        assertEquals(expenses.size, expenses.map { it.id }.toSet().size)
        assertEquals(plan.entries.size, plan.entries.map { it.id }.toSet().size)
        assertTrue(expenses.all { entry ->
            LocalDate.ofEpochDay(entry.bookedLocalEpochDay) in
                LocalDate.of(2026, 9, 1)..LocalDate.of(2026, 9, 30)
        })

        val wideSpreadHours = byHour.values.count { hour ->
            val amounts = hour.map { it.amountScaled100 / 100L }
            amounts.min() <= 2_000L && amounts.max() >= 50_000L
        }
        val tightClusterHours = byHour.values.count { hour ->
            val amounts = hour.map { it.amountScaled100 / 100L }
            amounts.size >= 3 && amounts.min() >= 8_000L && amounts.max() - amounts.min() <= 5_000L
        }
        assertTrue(wideSpreadHours >= 24)
        assertTrue(tightClusterHours >= 24)
        assertTrue(expenses.minOf { it.amountScaled100 } <= 800L * 100L)
        assertTrue(expenses.maxOf { it.amountScaled100 } >= 120_000L * 100L)
        assertTrue(activeHoursByDay.count { it >= 12 } >= 2)
        assertTrue(byDay.values.count { entries -> longestConsecutiveHourRun(entries) >= 8 } >= 3)
    }

    @Test
    fun mirrorsTheExactCommitted2025FastfoodPrototypeRowsInto2027() {
        val source = FastfoodPrototype2025Rows.rows
        assertEquals(100, source.size)
        assertEquals(
            "cd8ec0a6bb2e5558a11e3dddd7aa6a087d9edde897b13fceea1da4eb82e5a65e",
            source.normalizedSha256(),
        )

        val plan = DemoDatasetGenerator().generate()
        val category = plan.categories.single { it.name == "Gyorsétterem" }
        val partnerById = plan.partners.associateBy { it.id }
        val actual = plan.entries
            .filter { entry ->
                entry.categoryId == category.id &&
                    LocalDate.ofEpochDay(entry.bookedLocalEpochDay).year == 2027
            }
            .map { entry ->
                val date = LocalDate.ofEpochDay(entry.bookedLocalEpochDay)
                listOf(
                    date.monthValue.toString(),
                    date.dayOfMonth.toString(),
                    "%02d:%02d".format(
                        entry.bookedLocalTimeMinutes / 60,
                        entry.bookedLocalTimeMinutes % 60,
                    ),
                    partnerById.getValue(entry.partnerId).name,
                    (entry.amountScaled100 / 100L).toString(),
                    category.name,
                    entry.direction.name,
                ).joinToString("|")
            }
        val expected = source.map { row ->
            listOf(
                row.month.toString(),
                row.day.toString(),
                row.time,
                row.merchant,
                row.amountHuf.toString(),
                category.name,
                LedgerDirection.expense.name,
            ).joinToString("|")
        }

        assertEquals(expected, actual)
        assertTrue(
            "The source 2025 list remains a source fixture; only its 2027 mirror enters this demo plan.",
            plan.entries.none { entry ->
                entry.categoryId == category.id &&
                    LocalDate.ofEpochDay(entry.bookedLocalEpochDay).year == 2025
            },
        )
    }
}

private fun longestConsecutiveHourRun(entries: List<DemoEntryDraft>): Int {
    val hours = entries.map { it.bookedLocalTimeMinutes / 60 }.toSortedSet()
    var best = 0
    var current = 0
    var previous: Int? = null
    hours.forEach { hour ->
        current = if (previous == null || hour == previous!! + 1) current + 1 else 1
        best = maxOf(best, current)
        previous = hour
    }
    return best
}

private fun List<FastfoodPrototype2025Row>.normalizedSha256(): String {
    val normalized = joinToString("\n") { row ->
        listOf(
            row.month,
            row.day,
            row.time,
            row.merchant,
            row.amountHuf,
            22,
            "expense",
        ).joinToString("|")
    }
    return MessageDigest.getInstance("SHA-256")
        .digest(normalized.toByteArray(Charsets.UTF_8))
        .joinToString("") { byte -> "%02x".format(byte) }
}
