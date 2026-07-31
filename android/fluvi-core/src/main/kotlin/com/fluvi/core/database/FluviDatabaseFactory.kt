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
    ).addCallback(
        FluviDatabase.seedCallback(clock),
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
        ).build()
}
