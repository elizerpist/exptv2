package com.fluvi.core.database

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import com.fluvi.core.catalog.FluviCategoryCatalog
import com.fluvi.core.database.dao.FluviCategoryDao
import com.fluvi.core.database.dao.FluviAppSettingsDao
import com.fluvi.core.database.dao.FluviLedgerBackupCheckpointDao
import com.fluvi.core.database.dao.FluviFutureReferenceDao
import com.fluvi.core.database.dao.FluviLedgerDeletionArchiveDao
import com.fluvi.core.database.dao.FluviLedgerDao
import com.fluvi.core.database.dao.FluviLedgerSyncOutboxDao
import com.fluvi.core.database.dao.FluviLedgerSyncWorkspaceDao
import com.fluvi.core.database.dao.FluviPartnerDao
import com.fluvi.core.database.dao.FluviQuerySnapshotDao
import com.fluvi.core.database.entity.FluviAppSettingsEntity
import com.fluvi.core.database.entity.FluviCategoryEntity
import com.fluvi.core.database.entity.FluviLedgerBackupCheckpointEntity
import com.fluvi.core.database.entity.FluviLedgerDeletionArchiveEntity
import com.fluvi.core.database.entity.FluviLedgerEntryEntity
import com.fluvi.core.database.entity.FluviLedgerSyncOutboxEntity
import com.fluvi.core.database.entity.FluviLedgerSyncWorkspaceEntity
import com.fluvi.core.database.entity.FluviNotificationInboxEntity
import com.fluvi.core.database.entity.FluviOccurrenceOverrideEntity
import com.fluvi.core.database.entity.FluviPartnerAliasEntity
import com.fluvi.core.database.entity.FluviPartnerEntity
import com.fluvi.core.database.entity.FluviPushRecurringRuleConfigEntity
import com.fluvi.core.database.entity.FluviQuerySnapshotCategoryEntity
import com.fluvi.core.database.entity.FluviQuerySnapshotEntity
import com.fluvi.core.database.entity.FluviQuerySnapshotPartnerEntity
import com.fluvi.core.database.entity.FluviQuerySnapshotPeriodEntity
import com.fluvi.core.database.entity.FluviQuerySnapshotRefinementEntity
import com.fluvi.core.database.entity.FluviRecurrenceRuleEntity
import com.fluvi.core.database.entity.FluviTimeRecurringRuleConfigEntity
import com.fluvi.core.model.FluviClock
import com.fluvi.core.model.FluviSystemIds

@Database(
    entities = [
        FluviAppSettingsEntity::class,
        FluviCategoryEntity::class,
        FluviPartnerEntity::class,
        FluviPartnerAliasEntity::class,
        FluviLedgerEntryEntity::class,
        FluviLedgerDeletionArchiveEntity::class,
        FluviRecurrenceRuleEntity::class,
        FluviTimeRecurringRuleConfigEntity::class,
        FluviPushRecurringRuleConfigEntity::class,
        FluviOccurrenceOverrideEntity::class,
        FluviNotificationInboxEntity::class,
        FluviQuerySnapshotEntity::class,
        FluviQuerySnapshotPeriodEntity::class,
        FluviQuerySnapshotCategoryEntity::class,
        FluviQuerySnapshotPartnerEntity::class,
        FluviQuerySnapshotRefinementEntity::class,
        FluviLedgerSyncOutboxEntity::class,
        FluviLedgerSyncWorkspaceEntity::class,
        FluviLedgerBackupCheckpointEntity::class,
    ],
    version = 2,
    exportSchema = true,
)
@TypeConverters(FluviRoomConverters::class)
internal abstract class FluviDatabase : RoomDatabase() {
    abstract fun appSettingsDao(): FluviAppSettingsDao

    abstract fun categoryDao(): FluviCategoryDao

    abstract fun partnerDao(): FluviPartnerDao

    abstract fun ledgerDao(): FluviLedgerDao

    abstract fun ledgerDeletionArchiveDao(): FluviLedgerDeletionArchiveDao

    abstract fun ledgerSyncOutboxDao(): FluviLedgerSyncOutboxDao

    abstract fun ledgerSyncWorkspaceDao(): FluviLedgerSyncWorkspaceDao

    abstract fun ledgerBackupCheckpointDao(): FluviLedgerBackupCheckpointDao

    abstract fun futureReferenceDao(): FluviFutureReferenceDao

    abstract fun querySnapshotDao(): FluviQuerySnapshotDao

    internal companion object {
        const val DATABASE_FILE_NAME = "fluvi_core.db"

        val MIGRATION_1_2: Migration = object : Migration(1, 2) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL(
                    "ALTER TABLE fluvi_app_settings ADD COLUMN demo_seed_version INTEGER",
                )
                db.execSQL(
                    "ALTER TABLE fluvi_app_settings " +
                        "ADD COLUMN demo_seed_completed_at_utc_ms INTEGER",
                )
            }
        }

        fun seedCallback(clock: FluviClock): Callback = object : Callback() {
            override fun onCreate(db: SupportSQLiteDatabase) {
                val now = clock.nowUtcMs()

                db.execSQL(
                    """
                    INSERT INTO fluvi_app_settings (
                        id,
                        currency_code,
                        local_zone_id,
                        core_revision,
                        created_at_utc_ms,
                        updated_at_utc_ms,
                        demo_seed_version,
                        demo_seed_completed_at_utc_ms
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    """.trimIndent(),
                    arrayOf<Any?>(
                        FluviSystemIds.APP_SETTINGS,
                        "HUF",
                        "Europe/Budapest",
                        0L,
                        now,
                        now,
                        null,
                        null,
                    ),
                )
                db.execSQL(
                    """
                    INSERT INTO fluvi_categories (
                        id,
                        name,
                        color_id,
                        icon_id,
                        is_system_uncategorized,
                        created_at_utc_ms,
                        updated_at_utc_ms
                    ) VALUES (?, ?, ?, ?, ?, ?, ?)
                    """.trimIndent(),
                    arrayOf<Any>(
                        FluviSystemIds.UNCATEGORIZED_CATEGORY,
                        "Uncategorized",
                        FluviCategoryCatalog.SYSTEM_UNCATEGORIZED_COLOR_ID,
                        FluviCategoryCatalog.SYSTEM_UNCATEGORIZED_ICON_ID,
                        1,
                        now,
                        now,
                    ),
                )
                db.execSQL(
                    """
                    CREATE TRIGGER fluvi_ledger_entries_validate_insert
                    BEFORE INSERT ON fluvi_ledger_entries
                    FOR EACH ROW
                    WHEN length(NEW.id) != 26
                        OR NEW.id GLOB '*[^0123456789ABCDEFGHJKMNPQRSTVWXYZ]*'
                        OR NEW.amount_scaled_100 <= 0
                        OR NEW.booked_local_time_minutes < 0
                        OR NEW.booked_local_time_minutes > 1439
                        OR NEW.revision <= 0
                    BEGIN
                        SELECT RAISE(ABORT, 'Invalid Fluvi ledger entry scalar value.');
                    END
                    """.trimIndent(),
                )
                db.execSQL(
                    """
                    CREATE TRIGGER fluvi_ledger_entries_validate_update
                    BEFORE UPDATE ON fluvi_ledger_entries
                    FOR EACH ROW
                    WHEN length(NEW.id) != 26
                        OR NEW.id GLOB '*[^0123456789ABCDEFGHJKMNPQRSTVWXYZ]*'
                        OR NEW.amount_scaled_100 <= 0
                        OR NEW.booked_local_time_minutes < 0
                        OR NEW.booked_local_time_minutes > 1439
                        OR NEW.revision <= 0
                    BEGIN
                        SELECT RAISE(ABORT, 'Invalid Fluvi ledger entry scalar value.');
                    END
                    """.trimIndent(),
                )
            }
        }
    }
}
