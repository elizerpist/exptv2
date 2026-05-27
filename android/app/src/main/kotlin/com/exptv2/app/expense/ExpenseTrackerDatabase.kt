package com.exptv2.app.expense

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(
    entities = [TransactionCategoryEntity::class, ExpenseTransactionEntity::class],
    version = 1,
    exportSchema = false,
)
abstract class ExpenseTrackerDatabase : RoomDatabase() {
    abstract fun transactions(): ExpenseTransactionDao
    abstract fun categories(): TransactionCategoryDao

    companion object {
        @Volatile private var instance: ExpenseTrackerDatabase? = null

        fun get(context: Context): ExpenseTrackerDatabase {
            return instance ?: synchronized(this) {
                instance ?: Room.databaseBuilder(
                    context.applicationContext,
                    ExpenseTrackerDatabase::class.java,
                    "expense_tracker.db",
                ).build().also { instance = it }
            }
        }
    }
}
