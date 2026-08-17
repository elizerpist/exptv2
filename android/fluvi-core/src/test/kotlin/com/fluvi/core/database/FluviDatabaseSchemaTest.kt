package com.fluvi.core.database

import android.content.Context
import android.database.sqlite.SQLiteConstraintException
import androidx.test.core.app.ApplicationProvider
import com.fluvi.core.database.entity.FluviLedgerEntryEntity
import com.fluvi.core.database.entity.FluviFinancialLimitEntity
import com.fluvi.core.database.entity.FluviPartnerEntity
import com.fluvi.core.model.CategoryAssignmentMode
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.LedgerOriginKind
import com.fluvi.core.model.FluviFinancialLimitPeriodKind
import com.fluvi.core.model.FluviFinancialLimitTargetKind
import com.fluvi.core.model.FluviSystemIds
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class FluviDatabaseSchemaTest {
    @Test
    fun freshV1DatabaseContainsTheCleanCoreSchemaAndSeedsSystemRows() {
        val database = createInMemoryDatabase()

        try {
            val tableNames = database.openHelper.writableDatabase
                .query("SELECT name FROM sqlite_master WHERE type = 'table'")
                .use { rows ->
                    generateSequence {
                        if (rows.moveToNext()) rows.getString(0) else null
                    }.toSet()
                }

            assertTrue(tableNames.containsAll(REQUIRED_TABLES))
            assertFalse(tableNames.contains("transactions"))

            val settings = database.openHelper.writableDatabase
                .query("SELECT currency_code, core_revision FROM fluvi_app_settings")
                .use { rows ->
                    rows.moveToFirst()
                    rows.getString(0) to rows.getLong(1)
                }
            val uncategorizedCount = database.openHelper.writableDatabase
                .query(
                    "SELECT COUNT(*) FROM fluvi_categories " +
                        "WHERE is_system_uncategorized = 1",
                ).use { rows ->
                    rows.moveToFirst()
                    rows.getInt(0)
                }

            assertEquals("HUF", settings.first)
            assertEquals(1L, settings.second)
            assertEquals(1, uncategorizedCount)
        } finally {
            database.close()
        }
    }

    @Test
    fun ledgerScalarConstraintsAreEnforcedEvenForDirectDatabaseWrites() {
        runBlocking {
            val database = createInMemoryDatabase()

            try {
                val partnerId = "00000000000000000000000002"
                database.partnerDao().insert(
                    FluviPartnerEntity(
                        id = partnerId,
                        originalName = "Constraint Test Partner",
                        displayNameOverride = null,
                        defaultCategoryId = FluviSystemIds.UNCATEGORIZED_CATEGORY,
                        mergedIntoPartnerId = null,
                        createdAtUtcMs = 1L,
                        updatedAtUtcMs = 1L,
                    ),
                )
                val valid = FluviLedgerEntryEntity(
                    id = "00000000000000000000000003",
                    partnerId = partnerId,
                    categoryId = FluviSystemIds.UNCATEGORIZED_CATEGORY,
                    categoryAssignmentMode = CategoryAssignmentMode.partnerDefault,
                    note = null,
                    direction = LedgerDirection.expense,
                    amountScaled100 = 1L,
                    bookedLocalEpochDay = 20_000L,
                    bookedLocalTimeMinutes = 0,
                    occurredAtUtcMs = 1L,
                    originKind = LedgerOriginKind.manual,
                    notificationInboxId = null,
                    createdAtUtcMs = 1L,
                    updatedAtUtcMs = 1L,
                    revision = 1L,
                )

                assertThrows(SQLiteConstraintException::class.java) {
                    runBlocking { database.ledgerDao().insert(valid.copy(id = "short")) }
                }
                assertThrows(SQLiteConstraintException::class.java) {
                    runBlocking { database.ledgerDao().insert(valid.copy(amountScaled100 = 0L)) }
                }
                assertThrows(SQLiteConstraintException::class.java) {
                    runBlocking { database.ledgerDao().insert(valid.copy(bookedLocalTimeMinutes = 1_440)) }
                }

                database.ledgerDao().insert(valid)
                assertThrows(SQLiteConstraintException::class.java) {
                    database.openHelper.writableDatabase.execSQL(
                        "UPDATE fluvi_ledger_entries SET amount_scaled_100 = 0 WHERE id = ?",
                        arrayOf(valid.id),
                    )
                }
            } finally {
                database.close()
            }
        }
    }

    @Test
    fun financialLimitScalarAndCanonicalKeyConstraintsAreEnforced() = runBlocking {
        val database = createInMemoryDatabase()
        try {
            val valid = FluviFinancialLimitEntity(
                direction = LedgerDirection.expense,
                targetKind = FluviFinancialLimitTargetKind.aggregate,
                targetKey = "aggregate",
                categoryId = null,
                periodKind = FluviFinancialLimitPeriodKind.sum,
                periodKey = "sum",
                year = null,
                month = null,
                limitAmountScaled100 = 0L,
                createdAtUtcMs = 1L,
                updatedAtUtcMs = 1L,
            )
            database.financialLimitDao().upsert(valid)
            assertThrows(SQLiteConstraintException::class.java) {
                runBlocking {
                    database.financialLimitDao().upsert(
                        valid.copy(
                            direction = LedgerDirection.income,
                            limitAmountScaled100 = -1L,
                        ),
                    )
                }
            }
            assertThrows(SQLiteConstraintException::class.java) {
                database.openHelper.writableDatabase.execSQL(
                    "INSERT INTO fluvi_financial_limits " +
                        "(direction, target_kind, target_key, category_id, period_kind, period_key, " +
                        "year, month, limit_amount_scaled_100, created_at_utc_ms, updated_at_utc_ms) " +
                        "VALUES ('income', 'aggregate', 'aggregate', NULL, 'month', 'month:2026-13', " +
                        "2026, 13, 1, 1, 1)",
                )
            }
            assertThrows(SQLiteConstraintException::class.java) {
                database.openHelper.writableDatabase.execSQL(
                    "INSERT INTO fluvi_financial_limits " +
                        "(direction, target_kind, target_key, category_id, period_kind, period_key, " +
                        "year, month, limit_amount_scaled_100, created_at_utc_ms, updated_at_utc_ms) " +
                        "VALUES ('income', 'aggregate', 'aggregate', 'uncategorized', 'sum', 'sum', " +
                        "NULL, NULL, 1, 1, 1)",
                )
            }
            assertThrows(SQLiteConstraintException::class.java) {
                database.openHelper.writableDatabase.execSQL(
                    "INSERT INTO fluvi_financial_limits " +
                        "(direction, target_kind, target_key, category_id, period_kind, period_key, " +
                        "year, month, limit_amount_scaled_100, created_at_utc_ms, updated_at_utc_ms) " +
                        "VALUES ('income', 'category', 'category-a', NULL, 'year', 'year:2026', " +
                        "2026, NULL, 1, 1, 1)",
                )
            }
            assertThrows(SQLiteConstraintException::class.java) {
                database.openHelper.writableDatabase.execSQL(
                    "INSERT INTO fluvi_financial_limits " +
                        "(direction, target_kind, target_key, category_id, period_kind, period_key, " +
                        "year, month, limit_amount_scaled_100, created_at_utc_ms, updated_at_utc_ms) " +
                        "VALUES ('income', 'aggregate', 'aggregate', NULL, 'year', 'year:not-2026', " +
                        "2026, NULL, 1, 1, 1)",
                )
            }
        } finally {
            database.close()
        }
    }

    private fun createInMemoryDatabase(): FluviDatabase {
        val context = ApplicationProvider.getApplicationContext<Context>()
        return FluviDatabaseFactory.createInMemory(context)
    }

    private companion object {
        val REQUIRED_TABLES = setOf(
            "fluvi_app_settings",
            "fluvi_categories",
            "fluvi_financial_limits",
            "fluvi_partners",
            "fluvi_partner_aliases",
            "fluvi_ledger_entries",
            "fluvi_ledger_deletion_archive",
            "fluvi_recurrence_rules",
            "fluvi_time_recurring_rule_config",
            "fluvi_push_recurring_rule_config",
            "fluvi_occurrence_overrides",
            "fluvi_notification_inbox",
            "fluvi_query_snapshots",
            "fluvi_query_snapshot_periods",
            "fluvi_query_snapshot_categories",
            "fluvi_query_snapshot_partners",
            "fluvi_query_snapshot_refinements",
            "fluvi_ledger_sync_outbox",
            "fluvi_ledger_sync_workspaces",
            "fluvi_ledger_backup_checkpoints",
        )
    }
}
