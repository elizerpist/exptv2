package com.exptv2.app.expense

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.sqlite.db.SupportSQLiteDatabase
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class StatsSnapshotMigrationTest {
    @Test
    fun migration10To11PassesRoomSchemaValidationAndPreservesExistingData() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val databaseName = "stats-snapshot-migration-${System.nanoTime()}.db"
        val freshDatabaseName = "$databaseName-fresh"

        try {
            val version10Identity = createVersion10DatabaseWithExistingCategory(
                context = context,
                databaseName = databaseName,
            )
            val expectedVersion11Identity = createFreshVersion11Database(
                context = context,
                databaseName = freshDatabaseName,
            )

            val migratedDatabase = openMigratedVersion11Database(
                context = context,
                databaseName = databaseName,
            )
            try {
                val sqlite = migratedDatabase.openHelper.writableDatabase
                sqlite.query(
                    "SELECT name FROM transaction_categories WHERE transactionCategoryID = 42",
                ).use { cursor ->
                    assertTrue(cursor.moveToFirst())
                    assertEquals("Legacy category", cursor.getString(0))
                }

                val migratedIdentity = sqlite.roomIdentityHash()
                assertNotEquals(version10Identity, migratedIdentity)
                assertEquals(expectedVersion11Identity, migratedIdentity)
                assertEquals(11, sqlite.version)
            } finally {
                migratedDatabase.close()
            }
        } finally {
            context.deleteDatabase(databaseName)
            context.deleteDatabase(freshDatabaseName)
        }
    }

    private fun createVersion10DatabaseWithExistingCategory(
        context: Context,
        databaseName: String,
    ): String {
        val database = Room.databaseBuilder(
            context,
            ExpenseTrackerDatabaseV10ForMigrationTest::class.java,
            databaseName,
        ).allowMainThreadQueries().build()
        return try {
            val sqlite = database.openHelper.writableDatabase
            sqlite.execSQL(
                """
                INSERT INTO transaction_categories (
                    transactionCategoryID,
                    name,
                    type,
                    colorSlot,
                    iconSlot,
                    backgroundColor,
                    icon,
                    notification,
                    hasLimit,
                    limitAmount,
                    alertActive,
                    isCustomIcon,
                    originalIcon
                ) VALUES (42, 'Legacy category', 'expense', NULL, NULL, NULL, NULL, NULL, 0, 0, 0, 0, NULL)
                """.trimIndent(),
            )
            sqlite.roomIdentityHash()
        } finally {
            database.close()
        }
    }

    private fun createFreshVersion11Database(
        context: Context,
        databaseName: String,
    ): String {
        val database = Room.databaseBuilder(
            context,
            ExpenseTrackerDatabase::class.java,
            databaseName,
        ).allowMainThreadQueries().build()
        return try {
            database.openHelper.writableDatabase.roomIdentityHash()
        } finally {
            database.close()
        }
    }

    private fun openMigratedVersion11Database(
        context: Context,
        databaseName: String,
    ): ExpenseTrackerDatabase = Room.databaseBuilder(
        context,
        ExpenseTrackerDatabase::class.java,
        databaseName,
    ).addMigrations(ExpenseTrackerDatabase.MIGRATION_10_11)
        .allowMainThreadQueries()
        .build()
}

private fun SupportSQLiteDatabase.roomIdentityHash(): String =
    query("SELECT identity_hash FROM room_master_table WHERE id = 42").use { cursor ->
        check(cursor.moveToFirst()) { "Room identity hash is missing" }
        cursor.getString(0)
    }

@Database(
    entities = [
        TransactionCategoryEntity::class,
        ExpenseTransactionEntity::class,
        CategoryLimitEntity::class,
        RecurringTransactionEntity::class,
        RecurringGhostTransactionEntity::class,
        RecurringRuleEntity::class,
        RecurringRuleInstanceEntity::class,
        NotificationCardEntity::class,
    ],
    version = 10,
    exportSchema = false,
)
abstract class ExpenseTrackerDatabaseV10ForMigrationTest : RoomDatabase()
