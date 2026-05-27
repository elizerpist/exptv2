package com.pushparser.pushparserv2

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(entities = [NotificationEventEntity::class], version = 1, exportSchema = false)
abstract class PushParserDatabase : RoomDatabase() {
    abstract fun events(): NotificationEventDao

    companion object {
        @Volatile private var instance: PushParserDatabase? = null

        fun get(context: Context): PushParserDatabase {
            return instance ?: synchronized(this) {
                instance ?: Room.databaseBuilder(
                    context.applicationContext,
                    PushParserDatabase::class.java,
                    "pushparser_events.db",
                ).build().also { instance = it }
            }
        }
    }
}
