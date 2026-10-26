package com.fluvi.core.database

import androidx.room.testing.MigrationTestHelper
import androidx.sqlite.db.framework.FrameworkSQLiteOpenHelperFactory
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class FluviDatabaseMigrationTest {
    @get:Rule
    val helper = MigrationTestHelper(
        InstrumentationRegistry.getInstrumentation(),
        FluviDatabase::class.java,
        emptyList(),
        FrameworkSQLiteOpenHelperFactory(),
    )

    @Test
    fun migrationTwoToThreePromotesReadyRevisionAndCreatesPreviewIndex() {
        helper.createDatabase(DATABASE_NAME, 2).use { database ->
            database.execSQL(
                "INSERT INTO fluvi_app_settings (" +
                    "id, currency_code, local_zone_id, core_revision, " +
                    "created_at_utc_ms, updated_at_utc_ms, demo_seed_version, " +
                    "demo_seed_completed_at_utc_ms) VALUES " +
                    "('app-settings', 'HUF', 'Europe/Budapest', 0, 1, 1, NULL, NULL)",
            )
        }

        helper.runMigrationsAndValidate(
            DATABASE_NAME,
            3,
            true,
            FluviDatabase.MIGRATION_2_3,
        ).use { database ->
            val revision = database.query(
                "SELECT core_revision FROM fluvi_app_settings LIMIT 1",
            ).use { cursor ->
                assertTrue(cursor.moveToFirst())
                cursor.getLong(0)
            }
            val previewIndex = database.query(
                "SELECT COUNT(*) FROM sqlite_master " +
                    "WHERE type = 'index' AND " +
                    "name = 'index_fluvi_ledger_entries_dashboard_preview'",
            ).use { cursor ->
                assertTrue(cursor.moveToFirst())
                cursor.getInt(0)
            }

            assertEquals(1L, revision)
            assertEquals(1, previewIndex)
        }
    }

    @Test
    fun migrationThreeToFourPreservesLegacySlotsAsNamedSavedQueries() {
        helper.createDatabase(DATABASE_NAME, 3).use { database ->
            database.execSQL(
                "INSERT INTO fluvi_query_snapshots (" +
                    "id, slot, direction, format_version, created_at_utc_ms, updated_at_utc_ms" +
                ") VALUES ('saved-1', 'snapshot1', 'expense', 1, 1, 2)",
            )
            database.execSQL(
                "INSERT INTO fluvi_query_snapshot_periods " +
                    "(id, snapshot_id, group_key, period_kind, period_value) VALUES " +
                    "('period-1', 'saved-1', 'time', 'month', '2026-02')",
            )
        }

        helper.runMigrationsAndValidate(
            DATABASE_NAME,
            4,
            true,
            FluviDatabase.MIGRATION_3_4,
        ).use { database ->
            database.query(
                "SELECT name FROM fluvi_query_snapshots WHERE id = 'saved-1'",
            ).use { cursor ->
                assertTrue(cursor.moveToFirst())
                assertEquals("Snapshot 1", cursor.getString(0))
            }
            database.query(
                "SELECT period_value FROM fluvi_query_snapshot_periods " +
                    "WHERE snapshot_id = 'saved-1'",
            ).use { cursor ->
                assertTrue(cursor.moveToFirst())
                assertEquals("2026-02", cursor.getString(0))
            }
        }
    }

    @Test
    fun migrationFourToFivePreservesRowsAndAddsFinancialLimitsTable() {
        helper.createDatabase(DATABASE_NAME, 4).use { database ->
            database.execSQL(
                "INSERT INTO fluvi_app_settings (" +
                    "id, currency_code, local_zone_id, core_revision, " +
                    "created_at_utc_ms, updated_at_utc_ms, demo_seed_version, " +
                    "demo_seed_completed_at_utc_ms) VALUES " +
                    "('app-settings', 'HUF', 'Europe/Budapest', 41, 1, 1, NULL, NULL)",
            )
        }

        helper.runMigrationsAndValidate(
            DATABASE_NAME,
            5,
            true,
            FluviDatabase.MIGRATION_4_5,
        ).use { database ->
            val revision = database.query(
                "SELECT core_revision FROM fluvi_app_settings WHERE id = 'app-settings'",
            ).use { cursor ->
                assertTrue(cursor.moveToFirst())
                cursor.getLong(0)
            }
            val tableCount = database.query(
                "SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' " +
                    "AND name = 'fluvi_financial_limits'",
            ).use { cursor ->
                assertTrue(cursor.moveToFirst())
                cursor.getInt(0)
            }
            val indices = database.query(
                "SELECT COUNT(*) FROM sqlite_master WHERE type = 'index' " +
                    "AND name IN ('index_fluvi_financial_limits_category_id', " +
                    "'index_fluvi_financial_limits_direction_period_kind_year_month')",
            ).use { cursor ->
                assertTrue(cursor.moveToFirst())
                cursor.getInt(0)
            }
            val integrityTriggers = database.query(
                "SELECT COUNT(*) FROM sqlite_master WHERE type = 'trigger' " +
                    "AND name IN ('fluvi_financial_limits_validate_insert', " +
                    "'fluvi_financial_limits_validate_update')",
            ).use { cursor ->
                assertTrue(cursor.moveToFirst())
                cursor.getInt(0)
            }

            assertEquals(41L, revision)
            assertEquals(1, tableCount)
            assertEquals(2, indices)
            assertEquals(2, integrityTriggers)
        }
    }

    @Test
    fun migrationFiveToSixMakesMonthTheOnlyActiveLimitTruth() {
        helper.createDatabase(DATABASE_NAME, 5).use { database ->
            fun insert(
                periodKind: String,
                periodKey: String,
                year: Int?,
                month: Int?,
                amount: Long,
            ) {
                database.execSQL(
                    "INSERT INTO fluvi_financial_limits " +
                        "(direction,target_kind,target_key,category_id,period_kind,period_key," +
                        "year,month,limit_amount_scaled_100,created_at_utc_ms,updated_at_utc_ms) " +
                        "VALUES ('expense','aggregate','aggregate',NULL,'$periodKind','$periodKey'," +
                        "${year ?: "NULL"},${month ?: "NULL"},$amount,1,1)",
                )
            }
            insert("sum", "sum", null, null, 1_200L)
            insert("year", "year:2026", 2026, null, 2_400L)
            insert("month", "month:2026-1", 2026, 1, 300L)
        }

        helper.runMigrationsAndValidate(
            DATABASE_NAME,
            6,
            true,
            FluviDatabase.MIGRATION_5_6,
        ).use { database ->
            fun amount(periodKey: String): Long? = database.query(
                "SELECT limit_amount_scaled_100 FROM fluvi_financial_limits " +
                    "WHERE direction='expense' AND target_key='aggregate' AND period_key='$periodKey'",
            ).use { cursor ->
                if (!cursor.moveToFirst()) null else cursor.getLong(0)
            }
            val legacyCount = database.query(
                "SELECT COUNT(*) FROM fluvi_financial_limits " +
                    "WHERE period_kind IN ('sum','year')",
            ).use { cursor ->
                assertTrue(cursor.moveToFirst())
                cursor.getInt(0)
            }
            val monthCount = database.query(
                "SELECT COUNT(*) FROM fluvi_financial_limits " +
                    "WHERE period_kind='month' AND year=2026",
            ).use { cursor ->
                assertTrue(cursor.moveToFirst())
                cursor.getInt(0)
            }

            assertEquals(1_200L, amount("base"))
            assertEquals(300L, amount("month:2026-1"))
            // (2400 - 300) / 11 = 190, with the ten-unit residual assigned
            // to earliest unresolved months: Feb–Nov receive 191, Dec 190.
            assertEquals(191L, amount("month:2026-2"))
            assertEquals(190L, amount("month:2026-12"))
            assertEquals(12, monthCount)
            assertEquals(0, legacyCount)
        }
    }

    @Test
    fun migrationFiveToSixConvertsLegacySumIntoTheOnlyBaseMonthlyFallback() {
        migrateLegacyFinancialLimits(
            name = "$DATABASE_NAME-sum-only",
            rows = listOf(LegacyLimit("sum", "sum", null, null, 1_200L)),
        ) { database ->
            assertEquals(1_200L, amount(database, "base"))
            assertEquals(0, count(database, "period_kind='month'"))
            assertEquals(0, count(database, "period_kind IN ('sum','year')"))
        }
    }

    @Test
    fun migrationFiveToSixSeedsLegacyYearDeterministicallyWithoutAnnualTruth() {
        migrateLegacyFinancialLimits(
            name = "$DATABASE_NAME-year-only",
            rows = listOf(LegacyLimit("year", "year:2026", 2026, null, 25L)),
        ) { database ->
            assertEquals(0, count(database, "period_kind='base'"))
            assertEquals(12, count(database, "period_kind='month' AND year=2026"))
            // 25 / 12 leaves one scaled unit at the stable earliest month.
            assertEquals(3L, amount(database, "month:2026-1"))
            assertEquals(2L, amount(database, "month:2026-12"))
            assertEquals(25L, sum(database, "period_kind='month' AND year=2026"))
            assertEquals(0, count(database, "period_kind IN ('sum','year')"))
        }
    }

    @Test
    fun migrationFiveToSixLetsExplicitMonthsWinConflictingLegacyYear() {
        migrateLegacyFinancialLimits(
            name = "$DATABASE_NAME-explicit-wins",
            rows = listOf(
                LegacyLimit("year", "year:2026", 2026, null, 100L),
                LegacyLimit("month", "month:2026-1", 2026, 1, 300L),
            ),
        ) { database ->
            assertEquals(300L, amount(database, "month:2026-1"))
            // The conflict is deliberately resolved by preserving the explicit
            // user month and by not fabricating negative missing-month rows.
            assertEquals(1, count(database, "period_kind='month' AND year=2026"))
            assertEquals(0, count(database, "period_kind IN ('sum','year')"))
        }
    }

    @Test
    fun migrationSixToSevenTurnsLegacyBaseIntoAnEarliestEffectiveRevision() {
        val name = "$DATABASE_NAME-effective-base"
        helper.createDatabase(name, 6).use { database ->
            database.execSQL(
                "INSERT INTO fluvi_financial_limits " +
                    "(direction,target_kind,target_key,category_id,period_kind,period_key," +
                    "year,month,limit_amount_scaled_100,created_at_utc_ms,updated_at_utc_ms) " +
                    "VALUES ('expense','aggregate','aggregate',NULL,'base','base',NULL,NULL,18000,1,1)",
            )
            database.execSQL(
                "INSERT INTO fluvi_financial_limits " +
                    "(direction,target_kind,target_key,category_id,period_kind,period_key," +
                    "year,month,limit_amount_scaled_100,created_at_utc_ms,updated_at_utc_ms) " +
                    "VALUES ('expense','aggregate','aggregate',NULL,'month','month:2026-3',2026,3,22000,1,1)",
            )
        }
        helper.runMigrationsAndValidate(
            name,
            7,
            true,
            FluviDatabase.MIGRATION_6_7,
        ).use { database ->
            assertEquals(18000L, amount(database, "base:1-1"))
            assertEquals(22000L, amount(database, "month:2026-3"))
            assertEquals(0, count(database, "period_key='base'"))
        }
    }

    @Test
    fun migrationSevenToEightAddsParserV2TablesAndRetainsInboxRows() {
        val name = "$DATABASE_NAME-parser-v2"
        helper.createDatabase(name, 7).use { database ->
            database.execSQL(
                "INSERT INTO fluvi_categories (id,name,color_id,icon_id,is_system_uncategorized,created_at_utc_ms,updated_at_utc_ms) " +
                    "VALUES ('category-1','Teszt','gray','category',0,1,1)",
            )
            database.execSQL(
                "INSERT INTO fluvi_partners (id,original_name,display_name_override,default_category_id,merged_into_partner_id,created_at_utc_ms,updated_at_utc_ms) " +
                    "VALUES ('partner-1','Teszt partner',NULL,'category-1',NULL,1,1)",
            )
            database.execSQL(
                "INSERT INTO fluvi_notification_inbox (id,raw_notification_text,source_package_name," +
                    "source_app_label,received_at_utc_ms,parse_status,processing_status,training_status," +
                    "ledger_entry_id,created_at_utc_ms,updated_at_utc_ms) VALUES " +
                    "('inbox-1','legacy message','com.bank',NULL,1,'unclassified','unprocessed','unused',NULL,1,1)",
            )
            database.execSQL(
                "INSERT INTO fluvi_ledger_entries (id,partner_id,category_id,category_assignment_mode,note,direction,amount_scaled_100,booked_local_epoch_day,booked_local_time_minutes,occurred_at_utc_ms,origin_kind,notification_inbox_id,created_at_utc_ms,updated_at_utc_ms,revision) " +
                    "VALUES ('entry-1','partner-1','category-1','partnerDefault',NULL,'expense',100,1,1,1,'push','inbox-1',1,1,1)",
            )
        }
        helper.runMigrationsAndValidate(
            name,
            8,
            true,
            FluviDatabase.MIGRATION_7_8,
        ).use { database ->
            val profileTable = database.query(
                "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='fluvi_push_profiles'",
            ).use { cursor -> cursor.moveToFirst(); cursor.getInt(0) }
            val inbox = database.query(
                "SELECT raw_notification_text,review_status FROM fluvi_notification_inbox WHERE id='inbox-1'",
            ).use { cursor ->
                assertTrue(cursor.moveToFirst())
                cursor.getString(0) to cursor.getString(1)
            }
            assertEquals(1, profileTable)
            assertEquals("legacy message", inbox.first)
            assertEquals("none", inbox.second)
            val sourceLink = database.query(
                "SELECT notification_inbox_id FROM fluvi_ledger_entries WHERE id='entry-1'",
            ).use { cursor -> cursor.moveToFirst(); cursor.getString(0) }
            assertEquals("inbox-1", sourceLink)
        }
    }

    @Test
    fun migrationNineToTenAddsStableParserBindingToRecurringPushConfig() {
        val name = "$DATABASE_NAME-recurrence-push-binding"
        helper.createDatabase(name, 9).use { }

        helper.runMigrationsAndValidate(
            name,
            10,
            true,
            FluviDatabase.MIGRATION_9_10,
        ).use { database ->
            val columns = database.query(
                "PRAGMA table_info(fluvi_push_recurring_rule_config)",
            ).use { cursor ->
                buildSet {
                    val nameIndex = cursor.getColumnIndexOrThrow("name")
                    while (cursor.moveToNext()) add(cursor.getString(nameIndex))
                }
            }
            val indexCount = database.query(
                "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND " +
                    "name='index_fluvi_push_recurring_rule_config_push_profile_id_push_rule_id'",
            ).use { cursor -> cursor.moveToFirst(); cursor.getInt(0) }
            assertTrue("push_profile_id" in columns)
            assertTrue("push_rule_id" in columns)
            assertEquals(1, indexCount)
        }
    }

    @Test
    fun migrationTenToElevenRetainsLedgerSchemaAndAddsOccurrenceForeignKey() {
        val name = "$DATABASE_NAME-ledger-occurrence-foreign-key"
        helper.createDatabase(name, 10).use { }

        helper.runMigrationsAndValidate(
            name,
            11,
            true,
            FluviDatabase.MIGRATION_10_11,
        ).use { database ->
            val recurrenceForeignKey = database.query(
                "PRAGMA foreign_key_list(fluvi_ledger_entries)",
            ).use { cursor ->
                val tableIndex = cursor.getColumnIndexOrThrow("table")
                var found = false
                while (cursor.moveToNext()) {
                    if (cursor.getString(tableIndex) == "fluvi_recurrence_occurrences") found = true
                }
                found
            }
            val uniqueIndex = database.query(
                "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND " +
                    "name='index_fluvi_ledger_entries_recurrence_occurrence_id'",
            ).use { cursor -> cursor.moveToFirst(); cursor.getInt(0) }
            assertTrue(recurrenceForeignKey)
            assertEquals(1, uniqueIndex)
        }
    }

    @Test
    fun migrationElevenToTwelveAddsPulseThresholdSettings() {
        val name = "$DATABASE_NAME-pulse-threshold-settings"
        helper.createDatabase(name, 11).use { }

        helper.runMigrationsAndValidate(
            name,
            12,
            true,
            FluviDatabase.MIGRATION_11_12,
        ).use { database ->
            database.execSQL(
                "INSERT INTO fluvi_pulse_indicator_settings " +
                    "(indicator_id,target_key,threshold_key,value,updated_at_utc_ms) " +
                    "VALUES ('PULSE-003','','primary',1.25,4)",
            )
            val stored = database.query(
                "SELECT value FROM fluvi_pulse_indicator_settings " +
                    "WHERE indicator_id='PULSE-003' AND target_key='' AND threshold_key='primary'",
            ).use { cursor -> cursor.moveToFirst(); cursor.getDouble(0) }
            assertEquals(1.25, stored, .0001)
        }
    }

    @Test
    fun migrationTwelveToThirteenAddsSignalAuditTablesWithoutChangingThresholds() {
        val name = "$DATABASE_NAME-pulse-signal-audit"
        helper.createDatabase(name, 12).use { database ->
            database.execSQL(
                "INSERT INTO fluvi_pulse_indicator_settings " +
                    "(indicator_id,target_key,threshold_key,value,updated_at_utc_ms) " +
                    "VALUES ('PULSE-003','','primary',1.25,4)",
            )
        }

        helper.runMigrationsAndValidate(
            name,
            13,
            true,
            FluviDatabase.MIGRATION_12_13,
        ).use { database ->
            val stateTable = database.query(
                "SELECT COUNT(*) FROM sqlite_master WHERE type='table' " +
                    "AND name='fluvi_pulse_signal_states'",
            ).use { cursor -> cursor.moveToFirst(); cursor.getInt(0) }
            val eventFingerprintIndex = database.query(
                "SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND " +
                    "name='index_fluvi_pulse_signal_events_signal_key_evaluation_fingerprint_event_kind'",
            ).use { cursor -> cursor.moveToFirst(); cursor.getInt(0) }
            val threshold = database.query(
                "SELECT value FROM fluvi_pulse_indicator_settings " +
                    "WHERE indicator_id='PULSE-003' AND target_key='' AND threshold_key='primary'",
            ).use { cursor -> cursor.moveToFirst(); cursor.getDouble(0) }
            assertEquals(1, stateTable)
            assertEquals(1, eventFingerprintIndex)
            assertEquals(1.25, threshold, .0001)
        }
    }

    private fun migrateLegacyFinancialLimits(
        name: String,
        rows: List<LegacyLimit>,
        verify: (androidx.sqlite.db.SupportSQLiteDatabase) -> Unit,
    ) {
        helper.createDatabase(name, 5).use { database ->
            rows.forEach { row ->
                database.execSQL(
                    "INSERT INTO fluvi_financial_limits " +
                        "(direction,target_kind,target_key,category_id,period_kind,period_key," +
                        "year,month,limit_amount_scaled_100,created_at_utc_ms,updated_at_utc_ms) " +
                        "VALUES ('expense','aggregate','aggregate',NULL,'${row.periodKind}','${row.periodKey}'," +
                        "${row.year ?: "NULL"},${row.month ?: "NULL"},${row.amount},1,1)",
                )
            }
        }
        helper.runMigrationsAndValidate(
            name,
            6,
            true,
            FluviDatabase.MIGRATION_5_6,
        ).use(verify)
    }

    private fun amount(
        database: androidx.sqlite.db.SupportSQLiteDatabase,
        periodKey: String,
    ): Long? = database.query(
        "SELECT limit_amount_scaled_100 FROM fluvi_financial_limits " +
            "WHERE direction='expense' AND target_key='aggregate' AND period_key='$periodKey'",
    ).use { cursor ->
        if (!cursor.moveToFirst()) null else cursor.getLong(0)
    }

    private fun count(
        database: androidx.sqlite.db.SupportSQLiteDatabase,
        where: String,
    ): Int = database.query("SELECT COUNT(*) FROM fluvi_financial_limits WHERE $where").use { cursor ->
        assertTrue(cursor.moveToFirst())
        cursor.getInt(0)
    }

    private fun sum(
        database: androidx.sqlite.db.SupportSQLiteDatabase,
        where: String,
    ): Long = database.query(
        "SELECT COALESCE(SUM(limit_amount_scaled_100), 0) FROM fluvi_financial_limits WHERE $where",
    ).use { cursor ->
        assertTrue(cursor.moveToFirst())
        cursor.getLong(0)
    }

    private data class LegacyLimit(
        val periodKind: String,
        val periodKey: String,
        val year: Int?,
        val month: Int?,
        val amount: Long,
    )

    private companion object {
        const val DATABASE_NAME = "fluvi-dashboard-migration-test"
    }
}
