package com.exptv2.app.expense

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase

@Database(
    entities = [
        TransactionCategoryEntity::class,
        ExpenseTransactionEntity::class,
        CategoryLimitEntity::class,
    ],
    version = 2,
    exportSchema = false,
)
abstract class ExpenseTrackerDatabase : RoomDatabase() {
    abstract fun transactions(): ExpenseTransactionDao
    abstract fun categories(): TransactionCategoryDao
    abstract fun categoryLimits(): CategoryLimitDao

    companion object {
        @Volatile private var instance: ExpenseTrackerDatabase? = null

        private val MIGRATION_1_2 = object : Migration(1, 2) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL(
                    """
                    CREATE TABLE IF NOT EXISTS category_limits (
                        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                        targetType TEXT NOT NULL,
                        targetId INTEGER NOT NULL,
                        transactionType TEXT NOT NULL,
                        window TEXT NOT NULL,
                        periodKey TEXT NOT NULL,
                        hasLimit INTEGER NOT NULL,
                        limitAmount REAL NOT NULL,
                        alertActive INTEGER NOT NULL,
                        createdAt INTEGER NOT NULL,
                        updatedAt INTEGER NOT NULL
                    )
                    """.trimIndent(),
                )
                db.execSQL(
                    """
                    CREATE UNIQUE INDEX IF NOT EXISTS index_category_limits_targetType_targetId_transactionType_window_periodKey
                    ON category_limits(targetType, targetId, transactionType, window, periodKey)
                    """.trimIndent(),
                )
                db.execSQL(
                    """
                    CREATE INDEX IF NOT EXISTS index_category_limits_transactionType_window_periodKey
                    ON category_limits(transactionType, window, periodKey)
                    """.trimIndent(),
                )
            }
        }

        fun get(context: Context): ExpenseTrackerDatabase {
            return instance ?: synchronized(this) {
                instance ?: Room.databaseBuilder(
                    context.applicationContext,
                    ExpenseTrackerDatabase::class.java,
                    "expense_tracker.db",
                ).addMigrations(MIGRATION_1_2)
                    .build().also { instance = it }
            }
        }
    }
}
