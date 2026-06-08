package com.exptv2.app.expense

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.exptv2.app.NotificationEventEntity
import com.exptv2.app.NotificationParserProfileRule
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class ExpenseRepositoryMerchantCategoryTest {
    private lateinit var context: Context
    private lateinit var db: ExpenseTrackerDatabase
    private lateinit var repository: ExpenseRepository

    @Before
    fun setUp() = runBlocking {
        context = ApplicationProvider.getApplicationContext()
        context.getSharedPreferences("expense_seed", Context.MODE_PRIVATE)
            .edit()
            .putInt("demo_seed_version", ExpenseSeedData.version)
            .commit()
        db = ExpenseTrackerDatabase.get(context)
        db.notificationCards().clearAllHard()
        db.recurringRuleInstances().clearAll()
        db.recurringRules().clearAll()
        db.recurringGhostTransactions().clearAll()
        db.recurringTransactions().clearAll()
        db.transactions().clearAll()
        db.categoryLimits().clearAll()
        db.categories().clearAll()
        db.categories().insertAll(testCategories())
        repository = ExpenseRepository(context)
    }

    @Test
    fun updateTransactionPropagatesCategoryToSameOriginalMerchant() = runBlocking {
        db.transactions().insertAll(
            listOf(
                transaction(id = 260101, merchant = "nyírő", categoryId = 6),
                transaction(id = 260102, merchant = "nyírő", categoryId = null),
                transaction(id = 260103, merchant = "másik", categoryId = null),
            ),
        )

        repository.updateTransaction(
            mapOf(
                "id" to 260101,
                "merchant" to "nyírő",
                "amount" to 3085.0,
                "type" to "expense",
                "transactionCategoryID" to 7,
                "date" to "2026-01-01",
                "time" to "10:00",
            ),
        )

        assertEquals(7, db.transactions().byId(260101)?.transactionCategoryID)
        assertEquals(7, db.transactions().byId(260102)?.transactionCategoryID)
        assertNull(db.transactions().byId(260103)?.transactionCategoryID)
    }

    @Test
    fun addTransactionInheritsCategoryFromSameOriginalMerchant() = runBlocking {
        db.transactions().insert(
            transaction(id = 260101, merchant = "nyírő", categoryId = 7),
        )

        val saved = repository.addTransaction(
            mapOf(
                "merchant" to "nyírő",
                "amount" to 4500.0,
                "type" to "expense",
                "date" to "2026-01-02",
                "time" to "11:00",
            ),
        )

        assertEquals(7, saved["transactionCategoryID"])
    }

    @Test
    fun addTransactionWithoutMerchantMemoryStaysUncategorized() = runBlocking {
        db.transactions().insert(
            transaction(id = 260101, merchant = "másik", categoryId = 7),
        )

        val saved = repository.addTransaction(
            mapOf(
                "merchant" to "új bolt",
                "amount" to 1200.0,
                "type" to "expense",
                "date" to "2026-01-02",
                "time" to "11:00",
            ),
        )

        assertNull(saved["transactionCategoryID"])
    }

    @Test
    fun pushParserTransactionInheritsCategoryFromSameOriginalMerchant() = runBlocking {
        db.transactions().insert(
            transaction(id = 260101, merchant = "nyírő", categoryId = 7),
        )

        val saved = repository.processNotificationEventForParserProfiles(
            event = NotificationEventEntity(
                id = 77,
                timestamp = 1_767_264_000_000,
                source = "notification",
                packageName = "hu.bank.app",
                appLabel = "Bank",
                title = "",
                text = "🍽️ 3\u00A0085\u00A0Ft összeget fizettél itt: nyírő.\n" +
                    "A(z) HUF Zseb egyenlege: 71\u00A0795,87\u00A0Ft.",
                bigText = "",
                subText = "",
                category = "",
                notificationKey = "key-77",
                accessibilityEventType = "",
                hash = "hash-77",
                isDuplicate = false,
            ),
            profiles = listOf(
                NotificationParserProfileRule(
                    id = "profile-1",
                    name = "Bank",
                    enabled = true,
                    appFilterText = "",
                    packageName = "hu.bank.app",
                    appLabel = "Bank",
                    sampleText = "",
                    includeKeyword = "fizettél",
                    amountPattern = "(?<amount>\\d[\\d\\s.,]*)(?:\\s*(?:Ft|HUF))(?=\\s+összeget\\s+fizettél)",
                    merchantPattern = "itt:\\s*(?<merchant>.+?)(?:\\.|$)",
                    amountSelection = "",
                    merchantSelection = "",
                    transactionType = "expense",
                ),
            ),
        )

        assertEquals(7, saved?.get("transactionCategoryID"))
    }

    private fun testCategories(): List<TransactionCategoryEntity> = listOf(
        TransactionCategoryEntity(
            6,
            "Egyéb",
            "kiadás",
            0,
            0,
            "#64748b",
            null,
            null,
            false,
            0.0,
            false,
            true,
            null,
        ),
        TransactionCategoryEntity(
            7,
            "Étterem",
            "kiadás",
            1,
            1,
            "#ef4444",
            null,
            null,
            false,
            0.0,
            false,
            true,
            null,
        ),
    )

    private fun transaction(
        id: Int,
        merchant: String,
        categoryId: Int?,
    ): ExpenseTransactionEntity = ExpenseTransactionEntity(
        id = id,
        date = "2026.01.01",
        time = "10:00",
        latitude = null,
        longitude = null,
        address = "Test",
        merchant = merchant,
        amount = -1000.0,
        userAssignedName = null,
        transactionCategoryID = categoryId,
    )
}
