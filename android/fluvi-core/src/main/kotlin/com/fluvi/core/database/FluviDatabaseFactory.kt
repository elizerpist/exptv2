package com.fluvi.core.database

import android.content.Context
import androidx.room.Room
import com.fluvi.core.model.FluviClock
import com.fluvi.core.model.SystemFluviClock

internal object FluviDatabaseFactory {
    @JvmOverloads
    fun create(
        context: Context,
        clock: FluviClock = SystemFluviClock,
    ): FluviDatabase = Room.databaseBuilder(
        context.applicationContext,
        FluviDatabase::class.java,
        FluviDatabase.DATABASE_FILE_NAME,
    ).enableMultiInstanceInvalidation().addCallback(
        FluviDatabase.seedCallback(clock),
    ).addMigrations(
        FluviDatabase.MIGRATION_1_2,
        FluviDatabase.MIGRATION_2_3,
        FluviDatabase.MIGRATION_3_4,
        FluviDatabase.MIGRATION_4_5,
        FluviDatabase.MIGRATION_5_6,
        FluviDatabase.MIGRATION_6_7,
        FluviDatabase.MIGRATION_7_8,
        FluviDatabase.MIGRATION_8_9,
        FluviDatabase.MIGRATION_9_10,
        FluviDatabase.MIGRATION_10_11,
        FluviDatabase.MIGRATION_11_12,
        FluviDatabase.MIGRATION_12_13,
        FluviDatabase.MIGRATION_13_14,
        FluviDatabase.MIGRATION_14_15,
    ).build()

    @JvmOverloads
    fun createInMemory(
        context: Context,
        clock: FluviClock = SystemFluviClock,
    ): FluviDatabase = Room.inMemoryDatabaseBuilder(
        context.applicationContext,
        FluviDatabase::class.java,
    ).allowMainThreadQueries()
        .addCallback(
            FluviDatabase.seedCallback(clock),
        ).addMigrations(
            FluviDatabase.MIGRATION_1_2,
            FluviDatabase.MIGRATION_2_3,
            FluviDatabase.MIGRATION_3_4,
            FluviDatabase.MIGRATION_4_5,
            FluviDatabase.MIGRATION_5_6,
            FluviDatabase.MIGRATION_6_7,
            FluviDatabase.MIGRATION_7_8,
            FluviDatabase.MIGRATION_8_9,
            FluviDatabase.MIGRATION_9_10,
            FluviDatabase.MIGRATION_10_11,
            FluviDatabase.MIGRATION_11_12,
            FluviDatabase.MIGRATION_12_13,
            FluviDatabase.MIGRATION_13_14,
            FluviDatabase.MIGRATION_14_15,
        ).build()
}
