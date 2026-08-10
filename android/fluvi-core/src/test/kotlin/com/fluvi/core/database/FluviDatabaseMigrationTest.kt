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

    private companion object {
        const val DATABASE_NAME = "fluvi-dashboard-migration-test"
    }
}
