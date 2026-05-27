package com.exptv2.app.expense

object ExpenseSeedData {
    val categories = listOf(
        TransactionCategoryEntity(5, "Rr", "bevétel", 2, 0, "#3b82f6", "./assets/broccoli.png", null, false, 0.0, false, true, null),
        TransactionCategoryEntity(6, "Q", "kiadás", 7, 2, "#dc2626", "./assets/broccoli.png", null, false, 0.0, false, true, null),
        TransactionCategoryEntity(7, "Io", "kiadás", 2, 1, "#ef4444", "./assets/broccoli.png", null, false, 0.0, false, true, null),
        TransactionCategoryEntity(8, "Gg", "kiadás", 1, 0, "#dc2626", "./assets/broccoli.png", null, false, 0.0, false, true, null),
        TransactionCategoryEntity(9, "T", "kiadás", 3, 2, "#16a34a", "./assets/broccoli.png", null, false, 0.0, false, true, null),
        TransactionCategoryEntity(10, "Hadfer", "kiadás", 17, 17, "#ef4444", "./assets/broccoli.png", null, true, 555.0, false, true, null),
        TransactionCategoryEntity(11, "U", "kiadás", 5, 0, "#b45309", "./assets/broccoli.png", null, false, 0.0, false, true, null),
        TransactionCategoryEntity(12, "Ggz", "kiadás", 9, 0, "#22c55e", "./assets/broccoli.png", null, false, 0.0, false, true, null),
        TransactionCategoryEntity(13, "TestBroccoli", "kiadás", 4, 0, "#ea580c", "./assets/broccoli.png", null, false, 0.0, false, true, null),
    )

    val transactions = listOf(
        ExpenseTransactionEntity(250901, "2025.09.24", "20:31", null, null, "Unknown location", "Tt", -66.0, null, 9),
        ExpenseTransactionEntity(250902, "2025.09.24", "20:51", null, null, "Unknown location", "Ttqq", -22.0, null, 6),
        ExpenseTransactionEntity(250903, "2025.09.24", "21:14", null, null, "Unknown location", "Tt", -65.0, null, 9),
        ExpenseTransactionEntity(250904, "2025.09.24", "21:18", null, null, "Unknown location", "Uu", -55.0, null, 10),
        ExpenseTransactionEntity(250905, "2025.09.24", "21:56", null, null, "Unknown location", "Rrteeaawwq", 5555.0, "Gguu", 5),
        ExpenseTransactionEntity(250906, "2025.09.24", "22:39", null, null, "Unknown location", "Errr", -6513.0, null, 7),
        ExpenseTransactionEntity(250907, "2025.09.25", "5:29", null, null, "Unknown location", "Zzz", -6555.0, "Rrr", 6),
        ExpenseTransactionEntity(250908, "2025.09.25", "5:29", null, null, "Unknown location", "Zzz", -6580.0, "Rrr", 6),
        ExpenseTransactionEntity(250909, "2025.09.25", "20:30:00", null, null, "Unknown location", "Test Store", -505.0, null, 6),
        ExpenseTransactionEntity(250910, "2025.09.26", "7:03", null, null, "Unknown location", "Ii", 55.0, "Ggzz", 5),
        ExpenseTransactionEntity(250911, "2025.09.26", "7:16", null, null, "Unknown location", "Gg", -55.0, null, 7),
        ExpenseTransactionEntity(250912, "2025.09.26", "8:00", null, null, "Unknown location", "Tt", -2.0, null, 13),
        ExpenseTransactionEntity(250913, "2025.09.26", "8:00", null, null, "Unknown location", "Gf", -2.0, null, 13),
    )
}
