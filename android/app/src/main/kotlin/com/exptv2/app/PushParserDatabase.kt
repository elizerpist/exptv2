package com.exptv2.app

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase

@Database(entities = [NotificationEventEntity::class], version = 2, exportSchema = false)
abstract class PushParserDatabase : RoomDatabase() {
    abstract fun events(): NotificationEventDao

    companion object {
        @Volatile private var instance: PushParserDatabase? = null

        private val MIGRATION_1_2 = object : Migration(1, 2) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL("ALTER TABLE notification_events ADD COLUMN manualStatus TEXT NOT NULL DEFAULT ''")
                db.execSQL("CREATE INDEX IF NOT EXISTS index_notification_events_timestamp_id ON notification_events(timestamp, id)")
                db.execSQL("CREATE INDEX IF NOT EXISTS index_notification_events_packageName ON notification_events(packageName)")
                db.execSQL("CREATE INDEX IF NOT EXISTS index_notification_events_manualStatus ON notification_events(manualStatus)")
            }
        }

        fun get(context: Context): PushParserDatabase {
            return instance ?: synchronized(this) {
                instance ?: Room.databaseBuilder(
                    context.applicationContext,
                    PushParserDatabase::class.java,
                    "pushparser_events.db",
                ).addMigrations(MIGRATION_1_2)
                    .build().also { instance = it }
            }
        }
    }
}
