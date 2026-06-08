package com.exptv2.app.expense

import java.util.Calendar
import java.util.GregorianCalendar
import java.util.Random

object ExpenseSeedData {
    const val version = 2026060801

    private const val seedStartYear = 2021
    private const val seedStartMonth = 6
    private const val seedMonthCount = 61

    private const val icon = "./assets/broccoli.png"
    private const val now = 1780272000000L

    val categories = listOf(
        TransactionCategoryEntity(1, "Fizetes", "bevétel", 2, 0, "#2563eb", icon, null, false, 0.0, false, true, null),
        TransactionCategoryEntity(2, "Mellekbevetel", "bevétel", 9, 1, "#16a34a", icon, null, false, 0.0, false, true, null),
        TransactionCategoryEntity(3, "Visszaterites", "bevétel", 4, 2, "#0ea5e9", icon, null, false, 0.0, false, true, null),
        TransactionCategoryEntity(10, "Elelmiszer", "kiadás", 7, 2, "#dc2626", icon, null, true, 180000.0, true, true, null),
        TransactionCategoryEntity(11, "Lakas", "kiadás", 5, 5, "#8b5cf6", icon, null, true, 240000.0, true, true, null),
        TransactionCategoryEntity(12, "Kozlekedes", "kiadás", 4, 4, "#f59e0b", icon, null, true, 80000.0, true, true, null),
        TransactionCategoryEntity(13, "Rezsi", "kiadás", 3, 6, "#0891b2", icon, null, true, 90000.0, true, true, null),
        TransactionCategoryEntity(14, "Egeszseg", "kiadás", 1, 7, "#10b981", icon, null, true, 50000.0, true, true, null),
        TransactionCategoryEntity(15, "Szorakozas", "kiadás", 8, 8, "#db2777", icon, null, true, 90000.0, true, true, null),
        TransactionCategoryEntity(16, "Ruhazat", "kiadás", 12, 9, "#7c3aed", icon, null, true, 70000.0, true, true, null),
        TransactionCategoryEntity(17, "Oktatas", "kiadás", 11, 10, "#0284c7", icon, null, true, 60000.0, true, true, null),
        TransactionCategoryEntity(18, "Utazas", "kiadás", 10, 11, "#ea580c", icon, null, true, 120000.0, true, true, null),
        TransactionCategoryEntity(19, "Elofizetesek", "kiadás", 6, 12, "#475569", icon, null, true, 45000.0, true, true, null),
        TransactionCategoryEntity(20, "Etterem es kave", "kiadás", 13, 13, "#b45309", icon, null, true, 95000.0, true, true, null),
        TransactionCategoryEntity(21, "Egyeb", "kiadás", 14, 14, "#64748b", icon, null, true, 50000.0, true, true, null),
    )

    val transactions: List<ExpenseTransactionEntity> by lazy { buildTransactions() }

    val limits: List<CategoryLimitEntity> by lazy { buildLimits() }

    private data class ExpenseTemplate(
        val categoryId: Int,
        val merchants: List<String>,
        val minAmount: Int,
        val maxAmount: Int,
        val weight: Int,
    )

    private val expenseTemplates = listOf(
        ExpenseTemplate(10, listOf("Lidl", "Aldi", "Spar", "Tesco", "Penny", "Piac"), 1200, 18500, 42),
        ExpenseTemplate(11, listOf("Alberlet", "Kozos koltseg", "Lakasbiztositas", "Lakberendezes"), 3500, 280000, 12),
        ExpenseTemplate(12, listOf("BKK", "MOL", "Shell", "Parkolas", "Taxi", "Vonatjegy"), 450, 32000, 15),
        ExpenseTemplate(13, listOf("EON", "MVM", "Digi", "Telekom", "Vizmuvek", "Tavho"), 2500, 48000, 12),
        ExpenseTemplate(14, listOf("Gyogyszertar", "Fogorvos", "Optika", "Labor", "Sportberlet"), 1200, 65000, 7),
        ExpenseTemplate(15, listOf("Mozi", "Koncert", "Steam", "Konyv", "Tarsasjatek"), 1500, 42000, 10),
        ExpenseTemplate(16, listOf("H&M", "Reserved", "Decathlon", "Cipo", "Ruhajavitas"), 2500, 56000, 8),
        ExpenseTemplate(17, listOf("Udemy", "Nyelvtanar", "Konyvesbolt", "Workshop"), 2500, 85000, 5),
        ExpenseTemplate(18, listOf("Szallas", "Repulojegy", "Autopalya matrica", "Kirandulas", "Hotel"), 3000, 160000, 6),
        ExpenseTemplate(19, listOf("Netflix", "Spotify", "iCloud", "Google One", "HBO", "YouTube Premium"), 1290, 8990, 9),
        ExpenseTemplate(20, listOf("Kavezo", "Menza", "Wolt", "Foodora", "Etterem", "Pekseg"), 750, 18000, 24),
        ExpenseTemplate(21, listOf("Posta", "Ajandek", "Haztartas", "Allateledel", "Adomany"), 500, 45000, 10),
    )

    private fun buildTransactions(): List<ExpenseTransactionEntity> {
        val random = Random(20260601L)
        val weighted = expenseTemplates.flatMap { template -> List(template.weight) { template } }
        val rows = mutableListOf<ExpenseTransactionEntity>()
        var monthOffset = 0
        while (monthOffset < seedMonthCount) {
            val absoluteMonth = seedStartMonth + monthOffset
            val year = seedStartYear + (absoluteMonth - 1) / 12
            val month = ((absoluteMonth - 1) % 12) + 1
            val days = daysInMonth(year, month)
            val idBase = ((year % 100) * 100000) + (month * 1000)
            if (year == 2026 && month == 6) {
                monthOffset += 1
                continue
            }
            val expenseCount = 225 + random.nextInt(36)
            for (index in 1..expenseCount) {
                val template = weighted[random.nextInt(weighted.size)]
                val day = 1 + random.nextInt(days)
                val hour = if (template.categoryId == 20) 7 + random.nextInt(15) else 6 + random.nextInt(17)
                val minute = random.nextInt(60)
                val amount = roundedAmount(random, template.minAmount, template.maxAmount)
                rows += ExpenseTransactionEntity(
                    id = idBase + index,
                    date = "%04d.%02d.%02d".format(year, month, day),
                    time = "%02d:%02d".format(hour, minute),
                    latitude = null,
                    longitude = null,
                    address = "Seeded demo data",
                    merchant = template.merchants[random.nextInt(template.merchants.size)],
                    amount = -amount.toDouble(),
                    userAssignedName = null,
                    transactionCategoryID = template.categoryId,
                )
            }

            val salary = 560000 + random.nextInt(160000)
            rows += ExpenseTransactionEntity(
                id = idBase + 801,
                date = "%04d.%02d.%02d".format(year, month, minOf(5, days)),
                time = "08:30",
                latitude = null,
                longitude = null,
                address = "Seeded demo data",
                merchant = "Munkaber",
                amount = salary.toDouble(),
                userAssignedName = "Fizetes",
                transactionCategoryID = 1,
            )
            if (month % 3 == 0) {
                rows += ExpenseTransactionEntity(
                    id = idBase + 802,
                    date = "%04d.%02d.%02d".format(year, month, minOf(18, days)),
                    time = "18:15",
                    latitude = null,
                    longitude = null,
                    address = "Seeded demo data",
                    merchant = "Szabaduszo projekt",
                    amount = (65000 + random.nextInt(150000)).toDouble(),
                    userAssignedName = null,
                    transactionCategoryID = 2,
                )
            }
            if (month == 12 || month == 5) {
                rows += ExpenseTransactionEntity(
                    id = idBase + 803,
                    date = "%04d.%02d.%02d".format(year, month, minOf(24, days)),
                    time = "12:05",
                    latitude = null,
                    longitude = null,
                    address = "Seeded demo data",
                    merchant = "Visszaterites",
                    amount = (12000 + random.nextInt(65000)).toDouble(),
                    userAssignedName = null,
                    transactionCategoryID = 3,
                )
            }
            monthOffset += 1
        }
        return rows.sortedWith(compareByDescending<ExpenseTransactionEntity> { it.date }.thenByDescending { it.time }.thenByDescending { it.id })
    }

    private fun buildLimits(): List<CategoryLimitEntity> {
        val rows = mutableListOf<CategoryLimitEntity>()
        fun add(
            targetType: String,
            targetId: Int,
            transactionType: String,
            window: String,
            periodKey: String,
            amount: Double,
        ) {
            rows += CategoryLimitEntity(
                targetType = targetType,
                targetId = targetId,
                transactionType = transactionType,
                window = window,
                periodKey = periodKey,
                hasLimit = amount > 0.0,
                limitAmount = amount,
                alertActive = amount > 0.0,
                createdAt = now,
                updatedAt = now,
            )
        }

        add("overview", 0, "expense", "all_time", "all", 52000000.0)
        add("overview", 0, "income", "all_time", "all", 41000000.0)
        add("overview", 0, "saving", "all_time", "all", 6000000.0)

        var monthOffset = 0
        while (monthOffset < seedMonthCount) {
            val absoluteMonth = seedStartMonth + monthOffset
            val year = seedStartYear + (absoluteMonth - 1) / 12
            val month = ((absoluteMonth - 1) % 12) + 1
            val periodKey = "%04d-%02d".format(year, month)
            add("overview", 0, "expense", "monthly", periodKey, 840000.0)
            add("overview", 0, "income", "monthly", periodKey, 620000.0)
            for (category in categories.filter { it.type == "kiadás" }) {
                add(
                    "category",
                    category.transactionCategoryID,
                    "expense",
                    "monthly",
                    periodKey,
                    category.limitAmount,
                )
            }
            monthOffset += 1
        }
        return rows
    }

    private fun roundedAmount(random: Random, minAmount: Int, maxAmount: Int): Int {
        val raw = minAmount + random.nextInt(maxAmount - minAmount + 1)
        return ((raw + 5) / 10) * 10
    }

    private fun daysInMonth(year: Int, month: Int): Int {
        return GregorianCalendar(year, month - 1, 1).getActualMaximum(Calendar.DAY_OF_MONTH)
    }
}
