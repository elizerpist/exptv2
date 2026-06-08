package com.exptv2.app

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class NotificationParserRuleStoreTest {
    private lateinit var context: Context
    private lateinit var store: NotificationParserRuleStore

    @Before
    fun setUp() {
        context = ApplicationProvider.getApplicationContext()
        context.getSharedPreferences("pushparser_settings", Context.MODE_PRIVATE)
            .edit()
            .clear()
            .commit()
        store = NotificationParserRuleStore(context)
    }

    @Test
    fun saveProfilesKeepsAtLeastOneProfileEnabled() {
        val saved = store.saveProfiles(
            mapOf(
                "profiles" to listOf(
                    parserProfile("bank-a", enabled = false),
                    parserProfile("bank-b", enabled = false),
                ),
            ),
        )

        val profiles = saved["profiles"] as List<*>
        val first = profiles.first() as Map<*, *>
        val second = profiles[1] as Map<*, *>

        assertEquals(true, first["enabled"])
        assertEquals(false, second["enabled"])
    }

    @Test
    fun loadProfilesRepairsStoredDisabledProfiles() {
        context.getSharedPreferences("pushparser_settings", Context.MODE_PRIVATE)
            .edit()
            .putString(
                "parser_profiles_json",
                """
                [
                  {"id":"bank-a","name":"Bank A","enabled":false},
                  {"id":"bank-b","name":"Bank B","enabled":false}
                ]
                """.trimIndent(),
            )
            .commit()

        val loaded = store.loadProfiles()["profiles"] as List<*>
        val enabledCount = loaded.count { row ->
            (row as Map<*, *>)["enabled"] == true
        }

        assertEquals(1, enabledCount)
        assertTrue((loaded.first() as Map<*, *>)["enabled"] == true)
    }
}

private fun parserProfile(id: String, enabled: Boolean): Map<String, Any?> = mapOf(
    "id" to id,
    "name" to id,
    "enabled" to enabled,
    "appFilterText" to "",
    "packageName" to "hu.bank.app",
    "appLabel" to "Bank",
    "sampleText" to "Kártyás vásárlás: Tesco - 12 345 HUF",
    "includeKeyword" to "",
    "amountPattern" to "(?<amount>\\d[\\d\\s]*)\\s*HUF",
    "merchantPattern" to "vásárlás:\\s*(?<merchant>[^-]+)\\s*-",
    "amountSelection" to "12 345 HUF",
    "merchantSelection" to "Tesco",
    "transactionType" to "expense",
)
