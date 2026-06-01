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
        RecurringTransactionEntity::class,
        RecurringGhostTransactionEntity::class,
        NotificationCardEntity::class,
    ],
    version = 6,
    exportSchema = false,
)
abstract class ExpenseTrackerDatabase : RoomDatabase() {
    abstract fun transactions(): ExpenseTransactionDao
    abstract fun categories(): TransactionCategoryDao
    abstract fun categoryLimits(): CategoryLimitDao
    abstract fun recurringTransactions(): RecurringTransactionDao
    abstract fun recurringGhostTransactions(): RecurringGhostTransactionDao
    abstract fun notificationCards(): NotificationCardDao

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



        private val MIGRATION_2_3 = object : Migration(2, 3) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL(
                    """
                    CREATE TABLE IF NOT EXISTS recurring_transactions (
                        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                        name TEXT NOT NULL,
                        amount REAL NOT NULL,
                        transactionType TEXT NOT NULL,
                        dayOfMonth INTEGER NOT NULL,
                        categoryId INTEGER NOT NULL,
                        categoryName TEXT NOT NULL,
                        categoryColor TEXT NOT NULL,
                        categoryIconSlot INTEGER NOT NULL,
                        isActive INTEGER NOT NULL,
                        lastProcessedPeriodKey TEXT,
                        lastProcessedAt INTEGER,
                        createdAt INTEGER NOT NULL,
                        updatedAt INTEGER NOT NULL,
                        FOREIGN KEY(categoryId) REFERENCES transaction_categories(transactionCategoryID) ON UPDATE NO ACTION ON DELETE RESTRICT
                    )
                    """.trimIndent(),
                )
                db.execSQL("CREATE INDEX IF NOT EXISTS index_recurring_transactions_categoryId ON recurring_transactions(categoryId)")
                db.execSQL("CREATE INDEX IF NOT EXISTS index_recurring_transactions_transactionType ON recurring_transactions(transactionType)")
                db.execSQL("CREATE INDEX IF NOT EXISTS index_recurring_transactions_dayOfMonth ON recurring_transactions(dayOfMonth)")
                db.execSQL("CREATE INDEX IF NOT EXISTS index_recurring_transactions_isActive ON recurring_transactions(isActive)")
            }
        }

        private val MIGRATION_3_4 = object : Migration(3, 4) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL(
                    """
                    CREATE TABLE IF NOT EXISTS recurring_ghost_transactions (
                        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                        recurringTransactionId INTEGER NOT NULL,
                        periodKey TEXT NOT NULL,
                        name TEXT NOT NULL,
                        amount REAL NOT NULL,
                        transactionType TEXT NOT NULL,
                        date TEXT NOT NULL,
                        time TEXT NOT NULL,
                        categoryId INTEGER NOT NULL,
                        categoryName TEXT NOT NULL,
                        categoryColor TEXT NOT NULL,
                        categoryIconSlot INTEGER NOT NULL,
                        triggerMillis INTEGER NOT NULL,
                        isActivated INTEGER NOT NULL,
                        activatedTransactionId INTEGER,
                        createdAt INTEGER NOT NULL,
                        updatedAt INTEGER NOT NULL,
                        FOREIGN KEY(recurringTransactionId) REFERENCES recurring_transactions(id) ON UPDATE NO ACTION ON DELETE CASCADE,
                        FOREIGN KEY(categoryId) REFERENCES transaction_categories(transactionCategoryID) ON UPDATE NO ACTION ON DELETE RESTRICT
                    )
                    """.trimIndent(),
                )
                db.execSQL(
                    """
                    CREATE UNIQUE INDEX IF NOT EXISTS index_recurring_ghost_transactions_recurringTransactionId_periodKey
                    ON recurring_ghost_transactions(recurringTransactionId, periodKey)
                    """.trimIndent(),
                )
                db.execSQL("CREATE INDEX IF NOT EXISTS index_recurring_ghost_transactions_categoryId ON recurring_ghost_transactions(categoryId)")
                db.execSQL("CREATE INDEX IF NOT EXISTS index_recurring_ghost_transactions_periodKey ON recurring_ghost_transactions(periodKey)")
                db.execSQL("CREATE INDEX IF NOT EXISTS index_recurring_ghost_transactions_triggerMillis ON recurring_ghost_transactions(triggerMillis)")
                db.execSQL("CREATE INDEX IF NOT EXISTS index_recurring_ghost_transactions_isActivated ON recurring_ghost_transactions(isActivated)")
            }
        }

        private val MIGRATION_4_5 = object : Migration(4, 5) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL(
                    """
                    CREATE TABLE IF NOT EXISTS notification_cards (
                        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                        type TEXT NOT NULL,
                        title TEXT NOT NULL,
                        message TEXT NOT NULL,
                        timestamp INTEGER NOT NULL,
                        isRead INTEGER NOT NULL,
                        isActive INTEGER NOT NULL,
                        priority TEXT NOT NULL,
                        categoryId INTEGER,
                        categoryName TEXT,
                        categoryColor TEXT,
                        categoryIconSlot INTEGER,
                        recurringTransactionId INTEGER,
                        transactionId INTEGER,
                        amount REAL,
                        triggerDate TEXT,
                        nextDueDate TEXT,
                        createdAt INTEGER NOT NULL,
                        updatedAt INTEGER NOT NULL
                    )
                    """.trimIndent(),
                )
                db.execSQL("CREATE INDEX IF NOT EXISTS index_notification_cards_timestamp ON notification_cards(timestamp)")
                db.execSQL("CREATE INDEX IF NOT EXISTS index_notification_cards_type ON notification_cards(type)")
                db.execSQL("CREATE INDEX IF NOT EXISTS index_notification_cards_isRead ON notification_cards(isRead)")
                db.execSQL("CREATE INDEX IF NOT EXISTS index_notification_cards_isActive ON notification_cards(isActive)")
            }
        }

        private val MIGRATION_5_6 = object : Migration(5, 6) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL("CREATE INDEX IF NOT EXISTS index_transactions_date_time_id ON transactions(date, time, id)")
                db.execSQL("CREATE INDEX IF NOT EXISTS index_transactions_amount_date_time_id ON transactions(amount, date, time, id)")
                db.execSQL("CREATE INDEX IF NOT EXISTS index_transactions_transactionCategoryID_date_time_id ON transactions(transactionCategoryID, date, time, id)")
            }
        }

        fun get(context: Context): ExpenseTrackerDatabase {
            return instance ?: synchronized(this) {
                instance ?: Room.databaseBuilder(
                    context.applicationContext,
                    ExpenseTrackerDatabase::class.java,
                    "expense_tracker.db",
                ).addMigrations(
                        MIGRATION_1_2,
                        MIGRATION_2_3,
                        MIGRATION_3_4,
                        MIGRATION_4_5,
                        MIGRATION_5_6,
                    )
                    .build().also { instance = it }
            }
        }
    }
}
