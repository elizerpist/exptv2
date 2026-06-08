package com.exptv2.app

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.exptv2.app.expense.ExpenseSeedData
import com.exptv2.app.expense.ExpenseTrackerDatabase
import com.exptv2.app.expense.ExpenseTransactionEntity
import com.exptv2.app.expense.RecurringRuleEntity
import com.exptv2.app.expense.RecurringRuleInstanceEntity
import com.exptv2.app.expense.RecurringRuleInstanceStatus
import com.exptv2.app.expense.TransactionCategoryEntity
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class NotificationEventRepositoryTest {
    private lateinit var context: Context

    @Before
    fun setUp() = runBlocking {
        context = ApplicationProvider.getApplicationContext()
        context.getSharedPreferences("pushparser_settings", Context.MODE_PRIVATE)
            .edit()
            .clear()
            .commit()
        PushParserDatabase.get(context).events().clear()
        context.getSharedPreferences("expense_seed", Context.MODE_PRIVATE)
            .edit()
            .putInt("demo_seed_version", ExpenseSeedData.version)
            .commit()
        val expenseDb = ExpenseTrackerDatabase.get(context)
        expenseDb.notificationCards().clearAllHard()
        expenseDb.recurringRuleInstances().clearAll()
        expenseDb.recurringRules().clearAll()
        expenseDb.recurringGhostTransactions().clearAll()
        expenseDb.recurringTransactions().clearAll()
        expenseDb.transactions().clearAll()
        expenseDb.categoryLimits().clearAll()
        expenseDb.categories().clearAll()
    }

    @Test
    fun globalAutomaticPushParserOffSkipsCaptureInsert() = runBlocking {
        val store = NotificationParserRuleStore(context)
        store.saveProfiles(
            mapOf(
                "profiles" to listOf(
                    mapOf(
                        "id" to "erste",
                        "name" to "Erste",
                        "enabled" to true,
                        "packageName" to "hu.erste.bank",
                        "appLabel" to "Erste",
                        "appFilterText" to "^Erste$",
                        "sampleText" to "Paid 999 Ft at Corner Shop",
                        "includeKeyword" to "Paid",
                        "amountPattern" to "(?<amount>\\d+)\\s*Ft",
                        "merchantPattern" to "at\\s+(?<merchant>.+)",
                        "amountSelection" to "999 Ft",
                        "merchantSelection" to "Corner Shop",
                        "transactionType" to "expense",
                    ),
                ),
            ),
        )
        store.setAutomaticPushParserEnabled(false)

        val saved = NotificationEventRepository(context).insertDraft(
            EventDraft(
                timestamp = 1780858800000L,
                source = NotificationEventRepository.SOURCE_NOTIFICATION_LISTENER,
                packageName = "hu.erste.bank",
                appLabel = "Erste",
                title = "Paid",
                text = "Paid 999 Ft at Corner Shop",
            ),
        )

        assertNull(saved)
        assertEquals(0L, PushParserDatabase.get(context).events().count())
    }


    @Test
    fun listPageMarksRecurringActivatedEventAsLinked() = runBlocking {
        val events = PushParserDatabase.get(context).events()
        val expenseDb = ExpenseTrackerDatabase.get(context)
        val event = NotificationEventEntity(
            id = 0,
            timestamp = 1_780_941_600_000L,
            source = NotificationEventRepository.SOURCE_NOTIFICATION_LISTENER,
            packageName = "test.package",
            appLabel = "Notification Test",
            title = "",
            text = "Hitel: 80000 Ft",
            bigText = "",
            subText = "",
            category = "",
            notificationKey = "key-hitel",
            accessibilityEventType = "",
            hash = "hash-hitel",
            isDuplicate = false,
            manualStatus = "",
        )
        val eventId = events.insert(event)
        expenseDb.categories().insert(
            TransactionCategoryEntity(
                transactionCategoryID = 42,
                name = "Teszt",
                type = "expense",
                colorSlot = 1,
                iconSlot = 0,
                backgroundColor = "#ffffff",
                icon = null,
                notification = null,
                hasLimit = false,
                limitAmount = 0.0,
                alertActive = false,
                isCustomIcon = true,
                originalIcon = null,
            ),
        )
        expenseDb.recurringRules().insert(recurringRule(id = 11, categoryId = 42))
        expenseDb.transactions().insert(
            ExpenseTransactionEntity(
                id = 26060801,
                date = "2026.06.08",
                time = "19:36",
                latitude = null,
                longitude = null,
                address = "Push recurring transaction",
                merchant = "Hitel",
                amount = -80000.0,
                userAssignedName = "hitel",
                transactionCategoryID = null,
                recurringRuleId = 11,
                recurringInstanceId = 22,
                sourceNotificationEventId = null,
            ),
        )
        expenseDb.recurringRuleInstances().insert(
            recurringInstance(
                id = 22,
                ruleId = 11,
                eventId = eventId,
                transactionId = 26060801,
            ),
        )

        val page = NotificationEventRepository(context).listPage(
            mapOf("limit" to 60, "offset" to 0, "status" to "linked"),
        )

        assertEquals(1, page.events.size)
        assertEquals(NotificationEventStatus.LINKED, page.events.single().status)
        assertEquals(26060801, page.events.single().linkedTransactionId)
    }

    private fun recurringRule(id: Int, categoryId: Int) = RecurringRuleEntity(
        id = id,
        triggerType = "push",
        transactionType = "expense",
        name = "hitel",
        estimatedAmount = 80000.0,
        expectedDayOfMonth = 8,
        categoryId = categoryId,
        categoryName = "Teszt",
        categoryColor = "#ffffff",
        categoryIconSlot = 0,
        isActive = true,
        appFilterText = "",
        packageName = "test.package",
        appLabel = "Notification Test",
        sampleText = "Hitel: 80000 Ft",
        includeKeyword = "",
        amountPattern = "(?<amount>\\d+)\\s*Ft",
        amountSelection = "80000 Ft",
        merchantPattern = "",
        merchantSelection = "Hitel",
        dateToleranceDays = 5,
        amountTolerancePercent = 20.0,
        amountToleranceMin = 5000.0,
        createdAt = 1L,
        updatedAt = 1L,
    )

    private fun recurringInstance(
        id: Int,
        ruleId: Int,
        eventId: Long,
        transactionId: Int,
    ) = RecurringRuleInstanceEntity(
        id = id,
        ruleId = ruleId,
        periodKey = "2026-06",
        status = RecurringRuleInstanceStatus.ACTIVATED,
        estimatedDate = "2026.06.08",
        estimatedAmount = 80000.0,
        triggerTypeSnapshot = "push",
        transactionTypeSnapshot = "expense",
        nameSnapshot = "hitel",
        categoryIdSnapshot = 0,
        categoryNameSnapshot = "",
        categoryColorSnapshot = "",
        categoryIconSlotSnapshot = 0,
        activatedTransactionId = transactionId,
        activatedAt = 1_780_941_600_000L,
        matchedNotificationEventId = eventId,
        matchConfidence = 1.0,
        createdAt = 1L,
        updatedAt = 1L,
    )
}
