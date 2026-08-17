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
import com.fluvi.core.database.dao.FluviFinancialLimitDao
import com.fluvi.core.database.dao.FluviLedgerDeletionArchiveDao
import com.fluvi.core.database.dao.FluviLedgerDao
import com.fluvi.core.database.dao.FluviLedgerSyncOutboxDao
import com.fluvi.core.database.dao.FluviLedgerSyncWorkspaceDao
import com.fluvi.core.database.dao.FluviPartnerDao
import com.fluvi.core.database.dao.FluviQuerySnapshotDao
import com.fluvi.core.database.entity.FluviAppSettingsEntity
import com.fluvi.core.database.entity.FluviCategoryEntity
import com.fluvi.core.database.entity.FluviFinancialLimitEntity
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
        FluviFinancialLimitEntity::class,
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
    version = 5,
    exportSchema = true,
)
@TypeConverters(FluviRoomConverters::class)
internal abstract class FluviDatabase : RoomDatabase() {
    abstract fun appSettingsDao(): FluviAppSettingsDao

    abstract fun categoryDao(): FluviCategoryDao

    abstract fun financialLimitDao(): FluviFinancialLimitDao

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

        val MIGRATION_2_3: Migration = object : Migration(2, 3) {
            override fun migrate(db: SupportSQLiteDatabase) {
                // Revision zero represented the pre-bootstrap sentinel in v2.
                // Once Room has opened successfully, even an empty ledger is a
                // complete canonical dataset and must expose a publishable
                // positive revision to the global dashboard runtime.
                db.execSQL(
                    "UPDATE fluvi_app_settings SET core_revision = 1 " +
                        "WHERE core_revision = 0",
                )
                db.execSQL(
                    "CREATE INDEX IF NOT EXISTS " +
                        "index_fluvi_ledger_entries_dashboard_preview ON " +
                        "fluvi_ledger_entries (direction ASC, " +
                        "booked_local_epoch_day DESC, " +
                        "booked_local_time_minutes DESC, id DESC)",
                )
            }
        }

        /**
         * Evolves the old two-slot table into a named saved-Query table.
         *
         * The old `slot` column is deliberately not retained: it encoded a
         * product limit that no longer exists. Snapshot children are copied
         * through temporary tables so their typed configuration survives the
         * schema replacement intact.
         */
        val MIGRATION_3_4: Migration = object : Migration(3, 4) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL(
                    "CREATE TABLE fluvi_query_snapshot_periods_v4 AS " +
                        "SELECT id, snapshot_id, group_key, period_kind, period_value " +
                        "FROM fluvi_query_snapshot_periods",
                )
                db.execSQL(
                    "CREATE TABLE fluvi_query_snapshot_categories_v4 AS " +
                        "SELECT id, snapshot_id, category_id " +
                        "FROM fluvi_query_snapshot_categories",
                )
                db.execSQL(
                    "CREATE TABLE fluvi_query_snapshot_partners_v4 AS " +
                        "SELECT id, snapshot_id, partner_id " +
                        "FROM fluvi_query_snapshot_partners",
                )
                db.execSQL(
                    "CREATE TABLE fluvi_query_snapshot_refinements_v4 AS " +
                        "SELECT id, snapshot_id, refinement_kind, value_text, value_scaled_100 " +
                        "FROM fluvi_query_snapshot_refinements",
                )
                db.execSQL("DROP TABLE fluvi_query_snapshot_periods")
                db.execSQL("DROP TABLE fluvi_query_snapshot_categories")
                db.execSQL("DROP TABLE fluvi_query_snapshot_partners")
                db.execSQL("DROP TABLE fluvi_query_snapshot_refinements")
                db.execSQL("ALTER TABLE fluvi_query_snapshots RENAME TO fluvi_query_snapshots_v3")
                db.execSQL(
                    "CREATE TABLE fluvi_query_snapshots (" +
                        "id TEXT NOT NULL, " +
                        "name TEXT NOT NULL, " +
                        "direction TEXT NOT NULL, " +
                        "format_version INTEGER NOT NULL, " +
                        "created_at_utc_ms INTEGER NOT NULL, " +
                        "updated_at_utc_ms INTEGER NOT NULL, " +
                        "PRIMARY KEY(id))",
                )
                db.execSQL(
                    "INSERT INTO fluvi_query_snapshots " +
                        "(id, name, direction, format_version, created_at_utc_ms, updated_at_utc_ms) " +
                        "SELECT id, CASE slot " +
                        "WHEN 'snapshot1' THEN 'Snapshot 1' " +
                        "WHEN 'snapshot2' THEN 'Snapshot 2' " +
                        "ELSE 'Mentett szűrő' END, " +
                        "direction, format_version, created_at_utc_ms, updated_at_utc_ms " +
                        "FROM fluvi_query_snapshots_v3",
                )
                db.execSQL("DROP TABLE fluvi_query_snapshots_v3")
                db.execSQL(
                    "CREATE TABLE fluvi_query_snapshot_periods (" +
                        "id TEXT NOT NULL, snapshot_id TEXT NOT NULL, group_key TEXT NOT NULL, " +
                        "period_kind TEXT NOT NULL, period_value TEXT NOT NULL, PRIMARY KEY(id), " +
                        "FOREIGN KEY(snapshot_id) REFERENCES fluvi_query_snapshots(id) ON DELETE CASCADE)",
                )
                db.execSQL(
                    "CREATE TABLE fluvi_query_snapshot_categories (" +
                        "id TEXT NOT NULL, snapshot_id TEXT NOT NULL, category_id TEXT NOT NULL, " +
                        "PRIMARY KEY(id), FOREIGN KEY(snapshot_id) REFERENCES fluvi_query_snapshots(id) ON DELETE CASCADE, " +
                        "FOREIGN KEY(category_id) REFERENCES fluvi_categories(id) ON DELETE CASCADE)",
                )
                db.execSQL(
                    "CREATE TABLE fluvi_query_snapshot_partners (" +
                        "id TEXT NOT NULL, snapshot_id TEXT NOT NULL, partner_id TEXT NOT NULL, " +
                        "PRIMARY KEY(id), FOREIGN KEY(snapshot_id) REFERENCES fluvi_query_snapshots(id) ON DELETE CASCADE, " +
                        "FOREIGN KEY(partner_id) REFERENCES fluvi_partners(id) ON DELETE CASCADE)",
                )
                db.execSQL(
                    "CREATE TABLE fluvi_query_snapshot_refinements (" +
                        "id TEXT NOT NULL, snapshot_id TEXT NOT NULL, refinement_kind TEXT NOT NULL, " +
                        "value_text TEXT, value_scaled_100 INTEGER, PRIMARY KEY(id), " +
                        "FOREIGN KEY(snapshot_id) REFERENCES fluvi_query_snapshots(id) ON DELETE CASCADE)",
                )
                db.execSQL(
                    "INSERT INTO fluvi_query_snapshot_periods " +
                        "SELECT id, snapshot_id, group_key, period_kind, period_value " +
                        "FROM fluvi_query_snapshot_periods_v4",
                )
                db.execSQL(
                    "INSERT INTO fluvi_query_snapshot_categories SELECT id, snapshot_id, category_id " +
                        "FROM fluvi_query_snapshot_categories_v4",
                )
                db.execSQL(
                    "INSERT INTO fluvi_query_snapshot_partners SELECT id, snapshot_id, partner_id " +
                        "FROM fluvi_query_snapshot_partners_v4",
                )
                db.execSQL(
                    "INSERT INTO fluvi_query_snapshot_refinements " +
                        "SELECT id, snapshot_id, refinement_kind, value_text, value_scaled_100 " +
                        "FROM fluvi_query_snapshot_refinements_v4",
                )
                db.execSQL("DROP TABLE fluvi_query_snapshot_periods_v4")
                db.execSQL("DROP TABLE fluvi_query_snapshot_categories_v4")
                db.execSQL("DROP TABLE fluvi_query_snapshot_partners_v4")
                db.execSQL("DROP TABLE fluvi_query_snapshot_refinements_v4")
                db.execSQL(
                    "CREATE INDEX index_fluvi_query_snapshots_direction_updated_at_utc_ms " +
                        "ON fluvi_query_snapshots (direction, updated_at_utc_ms)",
                )
                db.execSQL("CREATE INDEX index_fluvi_query_snapshot_periods_snapshot_id ON fluvi_query_snapshot_periods(snapshot_id)")
                db.execSQL("CREATE UNIQUE INDEX index_fluvi_query_snapshot_periods_snapshot_id_group_key_period_value ON fluvi_query_snapshot_periods(snapshot_id, group_key, period_value)")
                db.execSQL("CREATE INDEX index_fluvi_query_snapshot_categories_snapshot_id ON fluvi_query_snapshot_categories(snapshot_id)")
                db.execSQL("CREATE INDEX index_fluvi_query_snapshot_categories_category_id ON fluvi_query_snapshot_categories(category_id)")
                db.execSQL("CREATE UNIQUE INDEX index_fluvi_query_snapshot_categories_snapshot_id_category_id ON fluvi_query_snapshot_categories(snapshot_id, category_id)")
                db.execSQL("CREATE INDEX index_fluvi_query_snapshot_partners_snapshot_id ON fluvi_query_snapshot_partners(snapshot_id)")
                db.execSQL("CREATE INDEX index_fluvi_query_snapshot_partners_partner_id ON fluvi_query_snapshot_partners(partner_id)")
                db.execSQL("CREATE UNIQUE INDEX index_fluvi_query_snapshot_partners_snapshot_id_partner_id ON fluvi_query_snapshot_partners(snapshot_id, partner_id)")
                db.execSQL("CREATE INDEX index_fluvi_query_snapshot_refinements_snapshot_id ON fluvi_query_snapshot_refinements(snapshot_id)")
                db.execSQL("CREATE UNIQUE INDEX index_fluvi_query_snapshot_refinements_snapshot_id_refinement_kind ON fluvi_query_snapshot_refinements(snapshot_id, refinement_kind)")
            }
        }

        /** Dedicated typed financial-limit storage. Existing core rows remain
         * untouched; canonical non-null keys make aggregate/sum uniqueness
         * reliable even though category/year/month are nullable by design. */
        val MIGRATION_4_5: Migration = object : Migration(4, 5) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL(
                    "CREATE TABLE fluvi_financial_limits (" +
                        "direction TEXT NOT NULL, " +
                        "target_kind TEXT NOT NULL, " +
                        "target_key TEXT NOT NULL, " +
                        "category_id TEXT, " +
                        "period_kind TEXT NOT NULL, " +
                        "period_key TEXT NOT NULL, " +
                        "year INTEGER, " +
                        "month INTEGER, " +
                        "limit_amount_scaled_100 INTEGER NOT NULL, " +
                        "created_at_utc_ms INTEGER NOT NULL, " +
                        "updated_at_utc_ms INTEGER NOT NULL, " +
                        "PRIMARY KEY(direction, target_key, period_key), " +
                        "FOREIGN KEY(category_id) REFERENCES fluvi_categories(id) ON DELETE CASCADE, " +
                        "CHECK(limit_amount_scaled_100 >= 0), " +
                        "CHECK((target_kind = 'aggregate' AND target_key = 'aggregate' AND category_id IS NULL) " +
                        "OR (target_kind = 'category' AND category_id IS NOT NULL AND target_key = category_id)), " +
                        "CHECK((period_kind = 'sum' AND period_key = 'sum' AND year IS NULL AND month IS NULL) " +
                        "OR (period_kind = 'year' AND year IS NOT NULL AND month IS NULL " +
                        "AND period_key = ('year:' || year)) " +
                        "OR (period_kind = 'month' AND year IS NOT NULL AND month BETWEEN 1 AND 12 " +
                        "AND period_key = ('month:' || year || '-' || month)))" +
                        ")",
                )
                db.execSQL(
                    "CREATE INDEX index_fluvi_financial_limits_category_id " +
                        "ON fluvi_financial_limits(category_id)",
                )
                db.execSQL(
                    "CREATE INDEX index_fluvi_financial_limits_direction_period_kind_year_month " +
                        "ON fluvi_financial_limits(direction, period_kind, year, month)",
                )
                createFinancialLimitIntegrityTriggers(db)
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
                        1L,
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
                createFinancialLimitIntegrityTriggers(db)
            }
        }

        private fun createFinancialLimitIntegrityTriggers(db: SupportSQLiteDatabase) {
            for (operation in listOf("INSERT", "UPDATE")) {
                db.execSQL(
                    """
                    CREATE TRIGGER IF NOT EXISTS fluvi_financial_limits_validate_${operation.lowercase()}
                    BEFORE $operation ON fluvi_financial_limits
                    FOR EACH ROW
                    WHEN NEW.limit_amount_scaled_100 < 0
                        OR NEW.target_kind NOT IN ('aggregate', 'category')
                        OR NEW.period_kind NOT IN ('sum', 'year', 'month')
                        OR (NEW.target_kind = 'aggregate' AND
                            (NEW.target_key != 'aggregate' OR NEW.category_id IS NOT NULL))
                        OR (NEW.target_kind = 'category' AND
                            (NEW.category_id IS NULL OR NEW.target_key != NEW.category_id))
                        OR (NEW.period_kind = 'sum' AND
                            (NEW.period_key != 'sum' OR NEW.year IS NOT NULL OR NEW.month IS NOT NULL))
                        OR (NEW.period_kind = 'year' AND
                            (NEW.year IS NULL OR NEW.month IS NOT NULL OR
                             NEW.period_key != ('year:' || NEW.year)))
                        OR (NEW.period_kind = 'month' AND
                            (NEW.year IS NULL OR NEW.month NOT BETWEEN 1 AND 12 OR
                             NEW.period_key != ('month:' || NEW.year || '-' || NEW.month)))
                    BEGIN
                        SELECT RAISE(ABORT, 'Invalid Fluvi financial limit.');
                    END
                    """.trimIndent(),
                )
            }
        }
    }
}
