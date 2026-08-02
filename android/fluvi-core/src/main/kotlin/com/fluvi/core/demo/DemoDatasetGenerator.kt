package com.fluvi.core.demo

import com.fluvi.core.catalog.FluviCategoryCatalog
import com.fluvi.core.model.CategoryAssignmentMode
import com.fluvi.core.model.LedgerDirection
import java.time.LocalDate
import java.time.ZoneId
import java.util.Random
import kotlin.math.max
import kotlin.math.min

class DemoDatasetGenerator(
    private val zoneId: ZoneId = ZoneId.of(DemoDatasetVersion.localZoneId),
) {
    fun generate(): DemoDatasetPlan {
        val categories = generateCategories()
        val partners = generatePartners(categories)
        val entries = buildList {
            var ordinal = 0
            for (month in 1..7) {
                val monthly = generateMonth(
                    month = month,
                    categories = categories,
                    partners = partners,
                    ordinalStart = ordinal,
                )
                ordinal += monthly.entries.size
                addAll(monthly.entries)
            }
        }
        val monthlyReports = entries.monthlyReports()
        validatePlan(categories, partners, entries, monthlyReports)
        return DemoDatasetPlan(
            version = DemoDatasetVersion.current,
            prngSeed = DemoDatasetVersion.prngSeed,
            categories = categories,
            partners = partners,
            entries = entries,
            monthlyReports = monthlyReports,
        )
    }

    private fun generateCategories(): List<DemoCategoryDraft> {
        val random = Random(DemoDatasetVersion.prngSeed)
        val colorIds = FluviCategoryCatalog.colorIds.toList().shuffled(random)
        val iconIds = FluviCategoryCatalog.iconIds.toList().shuffled(random)
        val names = listOf(
            "Fizetés",
            "Egyéb bevétel",
            "Lakhatás",
            "Élelmiszer",
            "Közlekedés",
            "Rezsi",
            "Egészség",
            "Szórakozás",
            "Vásárlás",
            "Előfizetések",
        )
        return names.mapIndexed { index, name ->
            DemoCategoryDraft(
                id = DemoDeterministicUlid.id(NAMESPACE_CATEGORY, index),
                name = name,
                colorId = colorIds[index],
                iconId = iconIds[index],
            )
        }
    }

    private fun generatePartners(
        categories: List<DemoCategoryDraft>,
    ): List<DemoPartnerDraft> {
        val byName = categories.associateBy { it.name }
        val definitions = listOf(
            "Fluvi Demo Employer Kft." to "Fizetés",
            "Northstar Freelance" to "Egyéb bevétel",
            "Adó-visszatérítés" to "Egyéb bevétel",
            "Marketplace eladás" to "Egyéb bevétel",
            "Mintalakás Bérbeadó" to "Lakhatás",
            "MVM" to "Rezsi",
            "Vízművek" to "Rezsi",
            "Telekom" to "Rezsi",
            "Biztosító" to "Rezsi",
            "Tesco" to "Élelmiszer",
            "Lidl" to "Élelmiszer",
            "Aldi" to "Élelmiszer",
            "SPAR" to "Élelmiszer",
            "Pékség" to "Élelmiszer",
            "Wolt" to "Élelmiszer",
            "BKK" to "Közlekedés",
            "MOL" to "Közlekedés",
            "MÁV" to "Közlekedés",
            "Parkolás" to "Közlekedés",
            "Netflix" to "Előfizetések",
            "Spotify" to "Előfizetések",
            "Mozi" to "Szórakozás",
            "Könyvesbolt" to "Szórakozás",
            "Gyógyszertár" to "Egészség",
            "Magánrendelő" to "Egészség",
            "Elektronikai üzlet" to "Vásárlás",
            "Ruházati üzlet" to "Vásárlás",
        )
        return definitions.mapIndexed { index, (name, categoryName) ->
            val category = requireNotNull(byName[categoryName])
            DemoPartnerDraft(
                id = DemoDeterministicUlid.id(NAMESPACE_PARTNER, index),
                aliasId = DemoDeterministicUlid.id(NAMESPACE_ALIAS, index),
                name = name,
                defaultCategoryId = category.id,
            )
        }
    }

    private fun generateMonth(
        month: Int,
        categories: List<DemoCategoryDraft>,
        partners: List<DemoPartnerDraft>,
        ordinalStart: Int,
    ): MonthlyEntries {
        val incomeTarget = incomeTargetsHuf[month - 1] * 100L
        val expenseTarget = expenseTargetsHuf[month - 1] * 100L
        val byName = categories.associateBy { it.name }
        val partnerByName = partners.associateBy { it.name }
        val salaryPartner = requireNotNull(partnerByName["Fluvi Demo Employer Kft."])
        val freelancePartner = requireNotNull(partnerByName["Northstar Freelance"])
        val refundPartner = requireNotNull(partnerByName["Adó-visszatérítés"])
        val salePartner = requireNotNull(partnerByName["Marketplace eladás"])
        val incomeAmounts = listOf(
            incomeTarget - 95_000L * 100L,
            40_000L * 100L,
            25_000L * 100L,
            15_000L * 100L,
            10_000L * 100L,
            5_000L * 100L,
        )
        val entries = mutableListOf<DemoEntryDraft>()
        var ordinal = ordinalStart
        val incomeDefinitions = listOf(
            Triple(salaryPartner, byName.getValue("Fizetés"), "Havi fizetés"),
            Triple(freelancePartner, byName.getValue("Egyéb bevétel"), "Freelance munka"),
            Triple(refundPartner, byName.getValue("Egyéb bevétel"), "Adó-visszatérítés"),
            Triple(salePartner, byName.getValue("Egyéb bevétel"), "Marketplace eladás"),
            Triple(freelancePartner, byName.getValue("Egyéb bevétel"), "Kisebb mellékes"),
            Triple(refundPartner, byName.getValue("Egyéb bevétel"), "Visszautalás"),
        )
        incomeDefinitions.forEachIndexed { index, (partner, category, note) ->
            entries += entry(
                ordinal = ordinal++,
                partner = partner,
                category = category,
                direction = LedgerDirection.income,
                amountScaled100 = incomeAmounts[index],
                date = dateFor(month, 5 + index * 4),
                minutes = 8 * 60 + index * 31,
                note = note,
                assignmentMode = CategoryAssignmentMode.partnerDefault,
            )
        }

        val fixedExpenses = listOf(
            FixedExpense("Mintalakás Bérbeadó", "Lakhatás", 260_000L, 2, 8 * 60, "Lakbér"),
            FixedExpense("MVM", "Rezsi", 18_000L, 10, 9 * 60, "Villanyszámla"),
            FixedExpense("Vízművek", "Rezsi", 9_000L, 14, 9 * 60 + 20, "Vízszámla"),
            FixedExpense("Telekom", "Rezsi", 9_000L, 18, 9 * 60 + 40, "Internet-előfizetés"),
            FixedExpense("Biztosító", "Rezsi", 24_000L, 21, 10 * 60, "Biztosítási díj"),
            FixedExpense("BKK", "Közlekedés", 12_000L, 1, 7 * 60 + 30, "Havi bérlet"),
            exceptionalExpenses[month - 1],
        )
        fixedExpenses.forEach { fixed ->
            val partner = requireNotNull(partnerByName[fixed.partnerName])
            val category = requireNotNull(byName[fixed.categoryName])
            entries += entry(
                ordinal = ordinal++,
                partner = partner,
                category = category,
                direction = LedgerDirection.expense,
                amountScaled100 = fixed.amountHuf * 100L,
                date = dateFor(month, fixed.day),
                minutes = fixed.minutes,
                note = fixed.note,
                assignmentMode = CategoryAssignmentMode.partnerDefault,
            )
        }

        val lowAmountsHuf = listOf(600L, 800L, 1_100L, 1_300L, 1_500L, 1_700L, 2_000L, 2_200L, 2_500L, 2_800L, 3_200L, 4_000L)
        val lowPartners = listOf("Pékség", "SPAR", "Parkolás", "Wolt", "Pékség", "Lidl")
        lowAmountsHuf.forEachIndexed { index, amountHuf ->
            val partnerName = lowPartners[index % lowPartners.size]
            val partner = partnerByName[partnerName] ?: partnerByName.getValue("SPAR")
            val categoryName = if (partnerName == "Parkolás") "Közlekedés" else "Élelmiszer"
            val category = byName.getValue(categoryName)
            entries += entry(
                ordinal = ordinal++,
                partner = partner,
                category = category,
                direction = LedgerDirection.expense,
                amountScaled100 = amountHuf * 100L,
                date = dateFor(month, 3 + index * 2),
                minutes = 7 * 60 + (index * 23) % 180,
                note = if (index % 3 == 0) "Kávé és péksütemény" else "Kisebb napi vásárlás",
                assignmentMode = if (index == 5) {
                    CategoryAssignmentMode.entryOverride
                } else {
                    CategoryAssignmentMode.partnerDefault
                },
            )
        }

        val fixedAndLow = entries
            .filter { it.direction == LedgerDirection.expense }
            .sumOf { it.amountScaled100 }
        val variableTarget = expenseTarget - fixedAndLow
        val variableAmounts = allocateVariableExpenses(variableTarget, month)
        val variablePartners = listOf(
            "Tesco", "Lidl", "Aldi", "SPAR", "Wolt", "MOL", "Mozi", "Gyógyszertár",
            "Könyvesbolt", "Elektronikai üzlet", "Ruházati üzlet", "Netflix", "Spotify",
        )
        variableAmounts.forEachIndexed { index, amountScaled100 ->
            val partnerName = variablePartners[(index + month) % variablePartners.size]
            val partner = partnerByName.getValue(partnerName)
            val assignmentMode = if (index % 11 == 0) {
                CategoryAssignmentMode.entryOverride
            } else {
                CategoryAssignmentMode.partnerDefault
            }
            val categoryName = if (assignmentMode == CategoryAssignmentMode.entryOverride) {
                "Vásárlás"
            } else {
                when {
                    partnerName in setOf("Tesco", "Lidl", "Aldi", "SPAR", "Wolt") -> "Élelmiszer"
                    partnerName in setOf("MOL") -> "Közlekedés"
                    partnerName in setOf("Mozi", "Könyvesbolt") -> "Szórakozás"
                    partnerName in setOf("Gyógyszertár") -> "Egészség"
                    partnerName in setOf("Netflix", "Spotify") -> "Előfizetések"
                    else -> "Vásárlás"
                }
            }
            val category = byName.getValue(categoryName)
            entries += entry(
                ordinal = ordinal++,
                partner = partner,
                category = category,
                direction = LedgerDirection.expense,
                amountScaled100 = amountScaled100,
                date = dateFor(month, 1 + ((index * 3 + month * 2) % dateFor(month, 1).lengthOfMonth())),
                minutes = if (index % 4 == 0) 8 * 60 + (index % 60) else 12 * 60 + (index * 17) % 600,
                note = variableNote(partnerName, index),
                assignmentMode = assignmentMode,
            )
        }

        return MonthlyEntries(entries)
    }

    private fun allocateVariableExpenses(
        targetScaled100: Long,
        month: Int,
    ): List<Long> {
        val count = 75
        val random = Random(DemoDatasetVersion.prngSeed + month * 997L)
        val average = targetScaled100 / count
        val amounts = MutableList(count) {
            max(80_000L, average + (random.nextInt(100_001) - 50_000L))
        }
        var delta = targetScaled100 - amounts.sum()
        var index = 0
        while (delta != 0L) {
            val current = amounts[index]
            val proposed = if (delta > 0L) {
                min(current + delta, 1_200_000L)
            } else {
                max(current + delta, 80_000L)
            }
            val applied = proposed - current
            amounts[index] = proposed
            delta -= applied
            index = (index + 1) % amounts.size
            check(applied != 0L) { "Unable to allocate demo expense remainder." }
        }
        return amounts
    }

    private fun entry(
        ordinal: Int,
        partner: DemoPartnerDraft,
        category: DemoCategoryDraft,
        direction: LedgerDirection,
        amountScaled100: Long,
        date: LocalDate,
        minutes: Int,
        note: String,
        assignmentMode: CategoryAssignmentMode,
    ): DemoEntryDraft {
        val localDateTime = date.atStartOfDay(zoneId).plusMinutes(minutes.toLong())
        return DemoEntryDraft(
            id = DemoDeterministicUlid.id(NAMESPACE_ENTRY, ordinal),
            partnerId = partner.id,
            categoryId = category.id,
            assignmentMode = assignmentMode,
            note = note,
            direction = direction,
            amountScaled100 = amountScaled100,
            bookedLocalEpochDay = date.toEpochDay(),
            bookedLocalTimeMinutes = minutes,
            occurredAtUtcMs = localDateTime.toInstant().toEpochMilli(),
        )
    }

    private fun dateFor(month: Int, requestedDay: Int): LocalDate {
        val first = LocalDate.of(2026, month, 1)
        return first.withDayOfMonth(min(requestedDay, first.lengthOfMonth()))
    }

    private fun variableNote(partnerName: String, index: Int): String = when {
        partnerName == "Tesco" || partnerName == "Lidl" || partnerName == "Aldi" || partnerName == "SPAR" -> "Bevásárlás ${index + 1}."
        partnerName == "MOL" -> "Üzemanyag"
        partnerName == "Wolt" -> "Ételrendelés"
        partnerName == "Gyógyszertár" -> "Gyógyszertári vásárlás"
        partnerName == "Mozi" -> "Mozi"
        partnerName == "Netflix" || partnerName == "Spotify" -> "Havi előfizetés"
        else -> "Háztartási vásárlás"
    }

    private fun List<DemoEntryDraft>.monthlyReports(): List<DemoMonthReport> =
        (1..7).map { month ->
            val monthEntries = filter {
                LocalDate.ofEpochDay(it.bookedLocalEpochDay).monthValue == month
            }
            val income = monthEntries.filter { it.direction == LedgerDirection.income }
            val expense = monthEntries.filter { it.direction == LedgerDirection.expense }
            DemoMonthReport(
                year = 2026,
                month = month,
                entryCount = monthEntries.size,
                incomeCount = income.size,
                expenseCount = expense.size,
                incomeTargetScaled100 = incomeTargetsHuf[month - 1] * 100L,
                expenseTargetScaled100 = expenseTargetsHuf[month - 1] * 100L,
                incomeTotalScaled100 = income.sumOf { it.amountScaled100 },
                expenseTotalScaled100 = expense.sumOf { it.amountScaled100 },
            )
        }

    private fun validatePlan(
        categories: List<DemoCategoryDraft>,
        partners: List<DemoPartnerDraft>,
        entries: List<DemoEntryDraft>,
        reports: List<DemoMonthReport>,
    ) {
        require(categories.size == 10)
        require(partners.size in 20..30)
        require(entries.size == 700)
        require(reports.all { it.entryCount == 100 })
        require(categories.all { it.colorId in FluviCategoryCatalog.colorIds })
        require(categories.all { it.iconId in FluviCategoryCatalog.iconIds })
        require(entries.all { it.amountScaled100 > 0L })
        require(entries.all { it.bookedLocalTimeMinutes in 0..1_439 })
        require(entries.all { it.bookedLocalEpochDay in DemoDatasetVersion.startInclusive.toEpochDay() until DemoDatasetVersion.endExclusive.toEpochDay() })
        require(entries.all { entry -> partners.any { it.id == entry.partnerId } })
        require(entries.all { entry -> categories.any { it.id == entry.categoryId } })
    }

    private data class MonthlyEntries(val entries: List<DemoEntryDraft>)

    private data class FixedExpense(
        val partnerName: String,
        val categoryName: String,
        val amountHuf: Long,
        val day: Int,
        val minutes: Int,
        val note: String,
    )

    private companion object {
        const val NAMESPACE_CATEGORY = 11
        const val NAMESPACE_PARTNER = 12
        const val NAMESPACE_ALIAS = 13
        const val NAMESPACE_ENTRY = 14

        val incomeTargetsHuf = listOf(705_000L, 694_000L, 712_000L, 701_000L, 698_000L, 721_000L, 707_000L)
        val expenseTargetsHuf = listOf(642_000L, 781_000L, 668_000L, 735_000L, 612_000L, 798_000L, 689_000L)
        val exceptionalExpenses = listOf(
            FixedExpense("Elektronikai üzlet", "Vásárlás", 120_000L, 12, 18 * 60, "Háztartási gép"),
            FixedExpense("Magánrendelő", "Egészség", 85_000L, 17, 15 * 60, "Fogászati kezelés"),
            FixedExpense("MÁV", "Közlekedés", 140_000L, 22, 7 * 60 + 15, "Utazás"),
            FixedExpense("Elektronikai üzlet", "Vásárlás", 100_000L, 11, 16 * 60, "Elektronikai vásárlás"),
            FixedExpense("Biztosító", "Rezsi", 80_000L, 25, 10 * 60 + 15, "Éves biztosítási díj"),
            FixedExpense("Mintalakás Bérbeadó", "Lakhatás", 160_000L, 20, 12 * 60, "Nyaralási előleg"),
            FixedExpense("Mintalakás Bérbeadó", "Lakhatás", 130_000L, 19, 12 * 60 + 20, "Nagyobb javítás"),
        )
    }
}
