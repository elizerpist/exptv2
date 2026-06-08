package com.exptv2.app

import android.content.Context
import androidx.test.core.app.ApplicationProvider
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
}
