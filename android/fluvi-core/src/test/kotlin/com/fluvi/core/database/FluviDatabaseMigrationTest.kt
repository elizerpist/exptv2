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
