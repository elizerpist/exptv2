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
import com.fluvi.core.database.dao.FluviPulseIndicatorSettingsDao
import com.fluvi.core.database.dao.FluviPulseSignalDao
import com.fluvi.core.database.dao.FluviPulseSituationDao
import com.fluvi.core.database.dao.FluviPulsePriorityDao
import com.fluvi.core.database.dao.FluviLedgerDeletionArchiveDao
import com.fluvi.core.database.dao.FluviLedgerDao
import com.fluvi.core.database.dao.FluviLedgerSyncOutboxDao
import com.fluvi.core.database.dao.FluviLedgerSyncWorkspaceDao
import com.fluvi.core.database.dao.FluviPartnerDao
import com.fluvi.core.database.dao.FluviQuerySnapshotDao
import com.fluvi.core.database.dao.FluviPushAutomationDao
import com.fluvi.core.database.dao.FluviRecurrenceDao
import com.fluvi.core.database.entity.FluviAppSettingsEntity
import com.fluvi.core.database.entity.FluviCategoryEntity
import com.fluvi.core.database.entity.FluviFinancialLimitEntity
import com.fluvi.core.database.entity.FluviPulseIndicatorSettingEntity
import com.fluvi.core.database.entity.FluviPulseSignalEventEntity
import com.fluvi.core.database.entity.FluviPulseSignalStateEntity
import com.fluvi.core.database.entity.FluviPulseSituationEntity
import com.fluvi.core.database.entity.FluviPulseSituationEventEntity
import com.fluvi.core.database.entity.FluviPulsePriorityEventEntity
import com.fluvi.core.database.entity.FluviPulsePriorityStateEntity
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
import com.fluvi.core.database.entity.FluviPushProfileEntity
import com.fluvi.core.database.entity.FluviPushRuleEntity
import com.fluvi.core.database.entity.FluviPushRuleTestResultEntity
import com.fluvi.core.database.entity.FluviPushTrainingSampleEntity
import com.fluvi.core.database.entity.FluviQuerySnapshotCategoryEntity
import com.fluvi.core.database.entity.FluviQuerySnapshotEntity
import com.fluvi.core.database.entity.FluviQuerySnapshotPartnerEntity
import com.fluvi.core.database.entity.FluviQuerySnapshotPeriodEntity
import com.fluvi.core.database.entity.FluviQuerySnapshotRefinementEntity
import com.fluvi.core.database.entity.FluviRecurrenceRuleEntity
import com.fluvi.core.database.entity.FluviRecurrenceOccurrenceEntity
import com.fluvi.core.database.entity.FluviTimeRecurringRuleConfigEntity
import com.fluvi.core.model.FluviClock
import com.fluvi.core.model.FluviSystemIds

@Database(
    entities = [
        FluviAppSettingsEntity::class,
        FluviCategoryEntity::class,
        FluviFinancialLimitEntity::class,
        FluviPulseIndicatorSettingEntity::class,
        FluviPulseSignalStateEntity::class,
        FluviPulseSignalEventEntity::class,
        FluviPulseSituationEntity::class,
        FluviPulseSituationEventEntity::class,
        FluviPulsePriorityStateEntity::class,
        FluviPulsePriorityEventEntity::class,
        FluviPartnerEntity::class,
        FluviPartnerAliasEntity::class,
        FluviLedgerEntryEntity::class,
        FluviLedgerDeletionArchiveEntity::class,
        FluviRecurrenceRuleEntity::class,
        FluviTimeRecurringRuleConfigEntity::class,
        FluviPushRecurringRuleConfigEntity::class,
        FluviOccurrenceOverrideEntity::class,
        FluviRecurrenceOccurrenceEntity::class,
        FluviNotificationInboxEntity::class,
        FluviPushProfileEntity::class,
        FluviPushRuleEntity::class,
        FluviPushTrainingSampleEntity::class,
        FluviPushRuleTestResultEntity::class,
        FluviQuerySnapshotEntity::class,
        FluviQuerySnapshotPeriodEntity::class,
        FluviQuerySnapshotCategoryEntity::class,
        FluviQuerySnapshotPartnerEntity::class,
        FluviQuerySnapshotRefinementEntity::class,
        FluviLedgerSyncOutboxEntity::class,
        FluviLedgerSyncWorkspaceEntity::class,
        FluviLedgerBackupCheckpointEntity::class,
    ],
    version = 15,
    exportSchema = true,
)
@TypeConverters(FluviRoomConverters::class)
internal abstract class FluviDatabase : RoomDatabase() {
    abstract fun appSettingsDao(): FluviAppSettingsDao

    abstract fun categoryDao(): FluviCategoryDao

    abstract fun financialLimitDao(): FluviFinancialLimitDao

    abstract fun pulseIndicatorSettingsDao(): FluviPulseIndicatorSettingsDao

    abstract fun pulseSignalDao(): FluviPulseSignalDao

    abstract fun pulseSituationDao(): FluviPulseSituationDao

    abstract fun pulsePriorityDao(): FluviPulsePriorityDao

    abstract fun partnerDao(): FluviPartnerDao

    abstract fun ledgerDao(): FluviLedgerDao

    abstract fun ledgerDeletionArchiveDao(): FluviLedgerDeletionArchiveDao

    abstract fun ledgerSyncOutboxDao(): FluviLedgerSyncOutboxDao

    abstract fun ledgerSyncWorkspaceDao(): FluviLedgerSyncWorkspaceDao

    abstract fun ledgerBackupCheckpointDao(): FluviLedgerBackupCheckpointDao

    abstract fun futureReferenceDao(): FluviFutureReferenceDao

    abstract fun pushAutomationDao(): FluviPushAutomationDao

    abstract fun recurrenceDao(): FluviRecurrenceDao

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
                createLegacyFinancialLimitIntegrityTriggers(db)
            }
        }

        /**
         * Retires independently writable SUM/YEAR rows. Month records win;
         * SUM becomes the base monthly fallback, and a legacy YEAR row seeds
         * only unresolved months by an exact deterministic even allocation.
         * The old table is replaced atomically by SQLite's migration
         * transaction, so subsequent launches can never read legacy truth.
         */
        val MIGRATION_5_6: Migration = object : Migration(5, 6) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL(
                    "CREATE TABLE fluvi_financial_limits_v6 (" +
                        "direction TEXT NOT NULL, target_kind TEXT NOT NULL, target_key TEXT NOT NULL, " +
                        "category_id TEXT, period_kind TEXT NOT NULL, period_key TEXT NOT NULL, " +
                        "year INTEGER, month INTEGER, limit_amount_scaled_100 INTEGER NOT NULL, " +
                        "created_at_utc_ms INTEGER NOT NULL, updated_at_utc_ms INTEGER NOT NULL, " +
                        "PRIMARY KEY(direction, target_key, period_key), " +
                        "FOREIGN KEY(category_id) REFERENCES fluvi_categories(id) ON DELETE CASCADE, " +
                        "CHECK(limit_amount_scaled_100 >= 0), " +
                        "CHECK((target_kind = 'aggregate' AND target_key = 'aggregate' AND category_id IS NULL) " +
                        "OR (target_kind = 'category' AND category_id IS NOT NULL AND target_key = category_id)), " +
                        "CHECK((period_kind = 'base' AND period_key = 'base' AND year IS NULL AND month IS NULL) " +
                        "OR (period_kind = 'month' AND year IS NOT NULL AND month BETWEEN 1 AND 12 " +
                        "AND period_key = ('month:' || year || '-' || month))))",
                )
                // Explicit legacy MONTH values are the highest-authority
                // source and are inserted before any derived values.
                db.execSQL(
                    "INSERT INTO fluvi_financial_limits_v6 " +
                        "SELECT direction, target_kind, target_key, category_id, 'month', " +
                        "('month:' || year || '-' || month), year, month, limit_amount_scaled_100, " +
                        "created_at_utc_ms, updated_at_utc_ms FROM fluvi_financial_limits " +
                        "WHERE period_kind = 'month'",
                )
                // A legacy SUM has the one compatible meaning: base monthly.
                db.execSQL(
                    "INSERT INTO fluvi_financial_limits_v6 " +
                        "SELECT direction, target_kind, target_key, category_id, 'base', 'base', " +
                        "NULL, NULL, limit_amount_scaled_100, created_at_utc_ms, updated_at_utc_ms " +
                        "FROM fluvi_financial_limits WHERE period_kind = 'sum'",
                )
                // Legacy yearly values seed only months lacking an explicit
                // record. Residual scaled units go to earliest unresolved
                // calendar months, making the migration deterministic and
                // exact without mutating an explicit month.
                db.execSQL(
                    "WITH RECURSIVE months(month) AS (VALUES(1) UNION ALL " +
                        "SELECT month + 1 FROM months WHERE month < 12), annual AS (" +
                        "SELECT y.*, COALESCE((SELECT SUM(m.limit_amount_scaled_100) " +
                        "FROM fluvi_financial_limits m WHERE m.direction = y.direction " +
                        "AND m.target_key = y.target_key AND m.period_kind = 'month' " +
                        "AND m.year = y.year), 0) AS explicit_sum, " +
                        "(SELECT COUNT(*) FROM months n WHERE NOT EXISTS (SELECT 1 " +
                        "FROM fluvi_financial_limits m WHERE m.direction = y.direction " +
                        "AND m.target_key = y.target_key AND m.period_kind = 'month' " +
                        "AND m.year = y.year AND m.month = n.month)) AS missing_count " +
                        "FROM fluvi_financial_limits y WHERE y.period_kind = 'year') " +
                        "INSERT OR IGNORE INTO fluvi_financial_limits_v6 " +
                        "(direction,target_kind,target_key,category_id,period_kind,period_key,year,month," +
                        "limit_amount_scaled_100,created_at_utc_ms,updated_at_utc_ms) " +
                        "SELECT a.direction,a.target_kind,a.target_key,a.category_id,'month'," +
                        "('month:' || a.year || '-' || n.month),a.year,n.month, " +
                        "((a.limit_amount_scaled_100 - a.explicit_sum) / a.missing_count) + " +
                        "CASE WHEN (SELECT COUNT(*) FROM months p WHERE p.month <= n.month " +
                        "AND NOT EXISTS (SELECT 1 FROM fluvi_financial_limits e " +
                        "WHERE e.direction=a.direction AND e.target_key=a.target_key " +
                        "AND e.period_kind='month' AND e.year=a.year AND e.month=p.month)) " +
                        "<= ((a.limit_amount_scaled_100 - a.explicit_sum) % a.missing_count) THEN 1 ELSE 0 END, " +
                        "a.created_at_utc_ms,a.updated_at_utc_ms FROM annual a CROSS JOIN months n " +
                        "WHERE a.limit_amount_scaled_100 > a.explicit_sum AND a.missing_count > 0 " +
                        "AND NOT EXISTS (SELECT 1 FROM fluvi_financial_limits e " +
                        "WHERE e.direction=a.direction AND e.target_key=a.target_key " +
                        "AND e.period_kind='month' AND e.year=a.year AND e.month=n.month)",
                )
                db.execSQL("DROP TABLE fluvi_financial_limits")
                db.execSQL("ALTER TABLE fluvi_financial_limits_v6 RENAME TO fluvi_financial_limits")
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

        /**
         * Replaces the v6 timeless `base` row with an effective-dated base
         * revision.  Every old base starts at the first representable month,
         * preserving all already-stored historical denominators.  The
         * migration is atomic and naturally idempotent: Room runs it exactly
         * once while moving a v6 database to v7, and the destination contains
         * no legacy `period_key = 'base'` row afterwards.
         */
        val MIGRATION_6_7: Migration = object : Migration(6, 7) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL(
                    "CREATE TABLE fluvi_financial_limits_v7 (" +
                        "direction TEXT NOT NULL, target_kind TEXT NOT NULL, target_key TEXT NOT NULL, " +
                        "category_id TEXT, period_kind TEXT NOT NULL, period_key TEXT NOT NULL, " +
                        "year INTEGER, month INTEGER, limit_amount_scaled_100 INTEGER NOT NULL, " +
                        "created_at_utc_ms INTEGER NOT NULL, updated_at_utc_ms INTEGER NOT NULL, " +
                        "PRIMARY KEY(direction, target_key, period_key), " +
                        "FOREIGN KEY(category_id) REFERENCES fluvi_categories(id) ON DELETE CASCADE, " +
                        "CHECK(limit_amount_scaled_100 >= 0), " +
                        "CHECK((target_kind = 'aggregate' AND target_key = 'aggregate' AND category_id IS NULL) " +
                        "OR (target_kind = 'category' AND category_id IS NOT NULL AND target_key = category_id)), " +
                        "CHECK((period_kind = 'base' AND year IS NOT NULL AND month BETWEEN 1 AND 12 " +
                        "AND period_key = ('base:' || year || '-' || month)) " +
                        "OR (period_kind = 'month' AND year IS NOT NULL AND month BETWEEN 1 AND 12 " +
                        "AND period_key = ('month:' || year || '-' || month))))",
                )
                // Explicit overrides retain their exact identity and values.
                db.execSQL(
                    "INSERT INTO fluvi_financial_limits_v7 " +
                        "SELECT direction, target_kind, target_key, category_id, period_kind, period_key, " +
                        "year, month, limit_amount_scaled_100, created_at_utc_ms, updated_at_utc_ms " +
                        "FROM fluvi_financial_limits WHERE period_kind = 'month'",
                )
                // A v6 base was timeless.  0001-01 is deliberately earlier
                // than any supported ledger month, so the upgrade preserves
                // historic resolution exactly while enabling later revisions.
                db.execSQL(
                    "INSERT INTO fluvi_financial_limits_v7 " +
                        "SELECT direction, target_kind, target_key, category_id, 'base', 'base:1-1', " +
                        "1, 1, limit_amount_scaled_100, created_at_utc_ms, updated_at_utc_ms " +
                        "FROM fluvi_financial_limits WHERE period_kind = 'base' AND period_key = 'base'",
                )
                db.execSQL("DROP TABLE fluvi_financial_limits")
                db.execSQL("ALTER TABLE fluvi_financial_limits_v7 RENAME TO fluvi_financial_limits")
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

        /** Adds the Parser v2 source of truth without touching existing ledger rows. */
        val MIGRATION_7_8: Migration = object : Migration(7, 8) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL(
                    "CREATE TABLE fluvi_push_profiles (id TEXT NOT NULL, package_name TEXT NOT NULL, " +
                        "app_label TEXT NOT NULL, display_name TEXT NOT NULL, default_direction TEXT NOT NULL, " +
                        "state TEXT NOT NULL, created_at_utc_ms INTEGER NOT NULL, updated_at_utc_ms INTEGER NOT NULL, " +
                        "revision INTEGER NOT NULL, PRIMARY KEY(id))",
                )
                db.execSQL("CREATE UNIQUE INDEX index_fluvi_push_profiles_package_name ON fluvi_push_profiles(package_name)")
                db.execSQL("CREATE INDEX index_fluvi_push_profiles_state_updated_at_utc_ms ON fluvi_push_profiles(state, updated_at_utc_ms)")
                db.execSQL(
                    "CREATE TABLE fluvi_push_rules (id TEXT NOT NULL, profile_id TEXT NOT NULL, name TEXT NOT NULL, " +
                        "direction TEXT NOT NULL, state TEXT NOT NULL, compiled_representation TEXT NOT NULL, version INTEGER NOT NULL, " +
                        "priority INTEGER NOT NULL, auto_accept_threshold REAL NOT NULL, created_at_utc_ms INTEGER NOT NULL, " +
                        "updated_at_utc_ms INTEGER NOT NULL, PRIMARY KEY(id), FOREIGN KEY(profile_id) REFERENCES fluvi_push_profiles(id) ON DELETE CASCADE)",
                )
                db.execSQL("CREATE INDEX index_fluvi_push_rules_profile_id_state_priority ON fluvi_push_rules(profile_id, state, priority)")
                // Inbox is recreated because the profile foreign key and uniqueness of fingerprints are part of capture safety.
                // `fluvi_ledger_entries` points back to this table with
                // ON DELETE SET NULL.  SQLite applies that action while the
                // legacy parent table is dropped, so retain the links and
                // restore them after the replacement table is in place.
                db.execSQL(
                    "CREATE TABLE fluvi_ledger_inbox_links_v8 AS " +
                        "SELECT id AS ledger_entry_id, notification_inbox_id " +
                        "FROM fluvi_ledger_entries WHERE notification_inbox_id IS NOT NULL",
                )
                db.execSQL(
                    "CREATE TABLE fluvi_notification_inbox_v8 (id TEXT NOT NULL, raw_notification_text TEXT NOT NULL, " +
                        "source_package_name TEXT, source_app_label TEXT, profile_id TEXT, notification_key TEXT, fingerprint TEXT, title TEXT, " +
                        "received_at_utc_ms INTEGER NOT NULL, parse_status TEXT NOT NULL, processing_status TEXT NOT NULL, training_status TEXT NOT NULL, " +
                        "review_status TEXT NOT NULL, confidence REAL, suggested_payload_json TEXT, diagnostics_json TEXT, ledger_entry_id TEXT, " +
                        "created_at_utc_ms INTEGER NOT NULL, updated_at_utc_ms INTEGER NOT NULL, PRIMARY KEY(id), " +
                        "FOREIGN KEY(ledger_entry_id) REFERENCES fluvi_ledger_entries(id) ON DELETE SET NULL, " +
                        "FOREIGN KEY(profile_id) REFERENCES fluvi_push_profiles(id) ON DELETE SET NULL)",
                )
                db.execSQL(
                    "INSERT INTO fluvi_notification_inbox_v8 (id,raw_notification_text,source_package_name,source_app_label,received_at_utc_ms,parse_status,processing_status,training_status,review_status,ledger_entry_id,created_at_utc_ms,updated_at_utc_ms) " +
                        "SELECT id,raw_notification_text,source_package_name,source_app_label,received_at_utc_ms,parse_status,processing_status,training_status,'none',ledger_entry_id,created_at_utc_ms,updated_at_utc_ms FROM fluvi_notification_inbox",
                )
                db.execSQL("DROP TABLE fluvi_notification_inbox")
                db.execSQL("ALTER TABLE fluvi_notification_inbox_v8 RENAME TO fluvi_notification_inbox")
                db.execSQL("CREATE INDEX index_fluvi_notification_inbox_ledger_entry_id ON fluvi_notification_inbox(ledger_entry_id)")
                db.execSQL("CREATE INDEX index_fluvi_notification_inbox_received_at_utc_ms ON fluvi_notification_inbox(received_at_utc_ms)")
                db.execSQL("CREATE INDEX index_fluvi_notification_inbox_training_status_received_at_utc_ms ON fluvi_notification_inbox(training_status, received_at_utc_ms)")
                db.execSQL("CREATE INDEX index_fluvi_notification_inbox_profile_id_received_at_utc_ms ON fluvi_notification_inbox(profile_id, received_at_utc_ms)")
                db.execSQL("CREATE UNIQUE INDEX index_fluvi_notification_inbox_fingerprint ON fluvi_notification_inbox(fingerprint)")
                db.execSQL(
                    "UPDATE fluvi_ledger_entries SET notification_inbox_id = " +
                        "(SELECT notification_inbox_id FROM fluvi_ledger_inbox_links_v8 " +
                        "WHERE ledger_entry_id = fluvi_ledger_entries.id) " +
                        "WHERE id IN (SELECT ledger_entry_id FROM fluvi_ledger_inbox_links_v8)",
                )
                db.execSQL("DROP TABLE fluvi_ledger_inbox_links_v8")
                db.execSQL(
                    "CREATE TABLE fluvi_push_training_samples (id TEXT NOT NULL, profile_id TEXT NOT NULL, notification_id TEXT NOT NULL, rule_id TEXT, sample_kind TEXT NOT NULL, spans_json TEXT NOT NULL, created_at_utc_ms INTEGER NOT NULL, PRIMARY KEY(id), " +
                        "FOREIGN KEY(profile_id) REFERENCES fluvi_push_profiles(id) ON DELETE CASCADE, FOREIGN KEY(rule_id) REFERENCES fluvi_push_rules(id) ON DELETE SET NULL, " +
                        "FOREIGN KEY(notification_id) REFERENCES fluvi_notification_inbox(id) ON DELETE CASCADE)",
                )
                db.execSQL("CREATE INDEX index_fluvi_push_training_samples_profile_id_created_at_utc_ms ON fluvi_push_training_samples(profile_id, created_at_utc_ms)")
                db.execSQL("CREATE INDEX index_fluvi_push_training_samples_notification_id ON fluvi_push_training_samples(notification_id)")
                db.execSQL("CREATE INDEX index_fluvi_push_training_samples_rule_id ON fluvi_push_training_samples(rule_id)")
                db.execSQL(
                    "CREATE TABLE fluvi_push_rule_test_results (id TEXT NOT NULL, rule_id TEXT NOT NULL, rule_version INTEGER NOT NULL, matched_count INTEGER NOT NULL, review_count INTEGER NOT NULL, rejected_count INTEGER NOT NULL, conflicted_count INTEGER NOT NULL, activation_ready INTEGER NOT NULL, created_at_utc_ms INTEGER NOT NULL, PRIMARY KEY(id), FOREIGN KEY(rule_id) REFERENCES fluvi_push_rules(id) ON DELETE CASCADE)",
                )
                db.execSQL("CREATE INDEX index_fluvi_push_rule_test_results_rule_id_rule_version_created_at_utc_ms ON fluvi_push_rule_test_results(rule_id, rule_version, created_at_utc_ms)")
            }
        }

        /** Adds persisted occurrence snapshots and ghost provenance without changing financial totals. */
        val MIGRATION_8_9: Migration = object : Migration(8, 9) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL("ALTER TABLE fluvi_app_settings ADD COLUMN show_pending_ghosts_in_ledger INTEGER NOT NULL DEFAULT 1")
                db.execSQL("ALTER TABLE fluvi_ledger_entries ADD COLUMN recurrence_occurrence_id TEXT")
                db.execSQL("CREATE UNIQUE INDEX index_fluvi_ledger_entries_recurrence_occurrence_id ON fluvi_ledger_entries(recurrence_occurrence_id)")
                db.execSQL("ALTER TABLE fluvi_recurrence_rules ADD COLUMN name TEXT NOT NULL DEFAULT ''")
                db.execSQL("ALTER TABLE fluvi_recurrence_rules ADD COLUMN day_of_month INTEGER NOT NULL DEFAULT 1")
                db.execSQL("ALTER TABLE fluvi_recurrence_rules ADD COLUMN local_time_minutes INTEGER NOT NULL DEFAULT 0")
                db.execSQL("ALTER TABLE fluvi_recurrence_rules ADD COLUMN start_local_epoch_day INTEGER NOT NULL DEFAULT 0")
                db.execSQL("ALTER TABLE fluvi_recurrence_rules ADD COLUMN end_local_epoch_day INTEGER")
                db.execSQL("ALTER TABLE fluvi_recurrence_rules ADD COLUMN timezone_id TEXT NOT NULL DEFAULT 'Europe/Budapest'")
                db.execSQL("ALTER TABLE fluvi_recurrence_rules ADD COLUMN rule_version INTEGER NOT NULL DEFAULT 1")
                db.execSQL("ALTER TABLE fluvi_recurrence_rules ADD COLUMN archived_at_utc_ms INTEGER")
                db.execSQL("CREATE TABLE fluvi_recurrence_occurrences (id TEXT NOT NULL, rule_id TEXT NOT NULL, occurrence_key TEXT NOT NULL, rule_version INTEGER NOT NULL, expected_local_epoch_day INTEGER NOT NULL, expected_local_time_minutes INTEGER NOT NULL, expected_at_utc_ms INTEGER NOT NULL, timezone_id TEXT NOT NULL, partner_id TEXT NOT NULL, category_id TEXT NOT NULL, category_assignment_mode TEXT NOT NULL, direction TEXT NOT NULL, expected_amount_scaled_100 INTEGER, amount_policy TEXT NOT NULL, note TEXT, trigger_kind TEXT NOT NULL, status TEXT NOT NULL, realization_kind TEXT, resolved_at_utc_ms INTEGER, created_at_utc_ms INTEGER NOT NULL, updated_at_utc_ms INTEGER NOT NULL, revision INTEGER NOT NULL, PRIMARY KEY(id), FOREIGN KEY(rule_id) REFERENCES fluvi_recurrence_rules(id) ON DELETE NO ACTION, FOREIGN KEY(partner_id) REFERENCES fluvi_partners(id) ON DELETE NO ACTION, FOREIGN KEY(category_id) REFERENCES fluvi_categories(id) ON DELETE NO ACTION)")
                db.execSQL("CREATE UNIQUE INDEX index_fluvi_recurrence_occurrences_rule_id_occurrence_key ON fluvi_recurrence_occurrences(rule_id, occurrence_key)")
                db.execSQL("CREATE INDEX index_fluvi_recurrence_occurrences_status_expected_local_epoch_day ON fluvi_recurrence_occurrences(status, expected_local_epoch_day)")
                db.execSQL("CREATE INDEX index_fluvi_recurrence_occurrences_direction_expected_local_epoch_day_expected_local_time_minutes_id ON fluvi_recurrence_occurrences(direction, expected_local_epoch_day, expected_local_time_minutes, id)")
                db.execSQL("CREATE INDEX index_fluvi_recurrence_occurrences_partner_id_status ON fluvi_recurrence_occurrences(partner_id, status)")
                db.execSQL("CREATE INDEX index_fluvi_recurrence_occurrences_category_id_status ON fluvi_recurrence_occurrences(category_id, status)")
                db.execSQL("CREATE INDEX index_fluvi_recurrence_occurrences_expected_at_utc_ms_status ON fluvi_recurrence_occurrences(expected_at_utc_ms, status)")
            }
        }

        /**
         * Binds a recurring push trigger to the exact Parser v2 profile and
         * recognition rule.  These deliberately remain nullable for legacy
         * drafts, which must never become automatically matchable.
         */
        val MIGRATION_9_10: Migration = object : Migration(9, 10) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL("ALTER TABLE fluvi_push_recurring_rule_config ADD COLUMN push_profile_id TEXT")
                db.execSQL("ALTER TABLE fluvi_push_recurring_rule_config ADD COLUMN push_rule_id TEXT")
                db.execSQL(
                    "CREATE INDEX index_fluvi_push_recurring_rule_config_push_profile_id_push_rule_id " +
                        "ON fluvi_push_recurring_rule_config(push_profile_id, push_rule_id)",
                )
            }
        }

        /**
         * SQLite cannot add a foreign key with ALTER TABLE. Rebuild only the
         * Ledger table, preserving every existing entry and its unique
         * recurrence relation while making the occurrence reference a genuine
         * database invariant.
         */
        val MIGRATION_10_11: Migration = object : Migration(10, 11) {
            override fun migrate(db: SupportSQLiteDatabase) {
                // Notification inbox rows may already reference Ledger rows.
                // Deferring the graph check keeps that intact while the parent
                // table is atomically replaced inside Room's migration txn.
                db.execSQL("PRAGMA defer_foreign_keys = TRUE")
                db.execSQL(
                    "CREATE TABLE fluvi_ledger_entries_v11 (" +
                        "id TEXT NOT NULL, partner_id TEXT NOT NULL, category_id TEXT NOT NULL, " +
                        "category_assignment_mode TEXT NOT NULL, note TEXT, direction TEXT NOT NULL, " +
                        "amount_scaled_100 INTEGER NOT NULL, booked_local_epoch_day INTEGER NOT NULL, " +
                        "booked_local_time_minutes INTEGER NOT NULL, occurred_at_utc_ms INTEGER NOT NULL, " +
                        "origin_kind TEXT NOT NULL, notification_inbox_id TEXT, recurrence_occurrence_id TEXT, " +
                        "created_at_utc_ms INTEGER NOT NULL, updated_at_utc_ms INTEGER NOT NULL, revision INTEGER NOT NULL, " +
                        "PRIMARY KEY(id), " +
                        "FOREIGN KEY(partner_id) REFERENCES fluvi_partners(id) ON DELETE NO ACTION, " +
                        "FOREIGN KEY(category_id) REFERENCES fluvi_categories(id) ON DELETE NO ACTION, " +
                        "FOREIGN KEY(notification_inbox_id) REFERENCES fluvi_notification_inbox(id) ON DELETE SET NULL, " +
                        "FOREIGN KEY(recurrence_occurrence_id) REFERENCES fluvi_recurrence_occurrences(id) ON DELETE NO ACTION)",
                )
                db.execSQL(
                    "INSERT INTO fluvi_ledger_entries_v11 (" +
                        "id, partner_id, category_id, category_assignment_mode, note, direction, amount_scaled_100, " +
                        "booked_local_epoch_day, booked_local_time_minutes, occurred_at_utc_ms, origin_kind, " +
                        "notification_inbox_id, recurrence_occurrence_id, created_at_utc_ms, updated_at_utc_ms, revision) " +
                        "SELECT id, partner_id, category_id, category_assignment_mode, note, direction, amount_scaled_100, " +
                        "booked_local_epoch_day, booked_local_time_minutes, occurred_at_utc_ms, origin_kind, " +
                        "notification_inbox_id, recurrence_occurrence_id, created_at_utc_ms, updated_at_utc_ms, revision " +
                        "FROM fluvi_ledger_entries",
                )
                db.execSQL("DROP TABLE fluvi_ledger_entries")
                db.execSQL("ALTER TABLE fluvi_ledger_entries_v11 RENAME TO fluvi_ledger_entries")
                db.execSQL("CREATE INDEX index_fluvi_ledger_entries_booked_local_epoch_day_booked_local_time_minutes_id ON fluvi_ledger_entries(booked_local_epoch_day, booked_local_time_minutes, id)")
                db.execSQL("CREATE INDEX index_fluvi_ledger_entries_direction_booked_local_epoch_day_booked_local_time_minutes_id ON fluvi_ledger_entries(direction, booked_local_epoch_day, booked_local_time_minutes, id)")
                db.execSQL("CREATE INDEX index_fluvi_ledger_entries_dashboard_preview ON fluvi_ledger_entries(direction ASC, booked_local_epoch_day DESC, booked_local_time_minutes DESC, id DESC)")
                db.execSQL("CREATE INDEX index_fluvi_ledger_entries_category_id_booked_local_epoch_day_booked_local_time_minutes_id ON fluvi_ledger_entries(category_id, booked_local_epoch_day, booked_local_time_minutes, id)")
                db.execSQL("CREATE INDEX index_fluvi_ledger_entries_partner_id_booked_local_epoch_day_booked_local_time_minutes_id ON fluvi_ledger_entries(partner_id, booked_local_epoch_day, booked_local_time_minutes, id)")
                db.execSQL("CREATE INDEX index_fluvi_ledger_entries_notification_inbox_id ON fluvi_ledger_entries(notification_inbox_id)")
                db.execSQL("CREATE UNIQUE INDEX index_fluvi_ledger_entries_recurrence_occurrence_id ON fluvi_ledger_entries(recurrence_occurrence_id)")
            }
        }

        /** Pulse V1 persists only user-configured chart references. */
        val MIGRATION_11_12: Migration = object : Migration(11, 12) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL(
                    "CREATE TABLE fluvi_pulse_indicator_settings (" +
                        "indicator_id TEXT NOT NULL, target_key TEXT NOT NULL, " +
                        "threshold_key TEXT NOT NULL, value REAL NOT NULL, " +
                        "updated_at_utc_ms INTEGER NOT NULL, " +
                        "PRIMARY KEY(indicator_id, target_key, threshold_key))",
                )
                db.execSQL(
                    "CREATE INDEX index_fluvi_pulse_indicator_settings_indicator_id_updated_at_utc_ms " +
                        "ON fluvi_pulse_indicator_settings(indicator_id, updated_at_utc_ms)",
                )
                db.execSQL(
                    "CREATE INDEX index_fluvi_pulse_indicator_settings_target_key " +
                        "ON fluvi_pulse_indicator_settings(target_key)",
                )
            }
        }

        /** Signal Engine A-phase state and bounded transition history. */
        val MIGRATION_12_13: Migration = object : Migration(12, 13) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL(
                    "CREATE TABLE fluvi_pulse_signal_states (" +
                        "signal_key TEXT NOT NULL, indicator_id TEXT NOT NULL, target_key TEXT NOT NULL, " +
                        "period_key TEXT NOT NULL, scenario_key TEXT NOT NULL, activity_state TEXT NOT NULL, " +
                        "strength TEXT, previous_strength TEXT, data_quality TEXT NOT NULL, confirmation_count INTEGER NOT NULL, " +
                        "measured_value REAL, threshold_value REAL, first_observed_at_utc_ms INTEGER, " +
                        "last_evaluated_at_utc_ms INTEGER NOT NULL, last_material_change_at_utc_ms INTEGER, " +
                        "last_input_revision INTEGER NOT NULL, last_config_revision INTEGER NOT NULL, " +
                        "evaluation_fingerprint TEXT NOT NULL, situation_key TEXT NOT NULL, evidence_family TEXT NOT NULL, " +
                        "trace_payload TEXT NOT NULL, updated_at_utc_ms INTEGER NOT NULL, PRIMARY KEY(signal_key))",
                )
                db.execSQL("CREATE INDEX index_fluvi_pulse_signal_states_indicator_id_period_key ON fluvi_pulse_signal_states(indicator_id, period_key)")
                db.execSQL("CREATE INDEX index_fluvi_pulse_signal_states_activity_state_updated_at_utc_ms ON fluvi_pulse_signal_states(activity_state, updated_at_utc_ms)")
                db.execSQL("CREATE INDEX index_fluvi_pulse_signal_states_situation_key ON fluvi_pulse_signal_states(situation_key)")
                db.execSQL(
                    "CREATE TABLE fluvi_pulse_signal_events (" +
                        "event_id TEXT NOT NULL, signal_key TEXT NOT NULL, event_kind TEXT NOT NULL, " +
                        "previous_state TEXT, next_state TEXT NOT NULL, previous_strength TEXT, next_strength TEXT, " +
                        "measured_value REAL, threshold_value REAL, input_revision INTEGER NOT NULL, " +
                        "config_revision INTEGER NOT NULL, cause TEXT NOT NULL, evaluation_fingerprint TEXT NOT NULL, " +
                        "trace_payload TEXT NOT NULL, created_at_utc_ms INTEGER NOT NULL, PRIMARY KEY(event_id))",
                )
                db.execSQL("CREATE INDEX index_fluvi_pulse_signal_events_signal_key_created_at_utc_ms ON fluvi_pulse_signal_events(signal_key, created_at_utc_ms)")
                db.execSQL("CREATE UNIQUE INDEX index_fluvi_pulse_signal_events_signal_key_evaluation_fingerprint_event_kind ON fluvi_pulse_signal_events(signal_key, evaluation_fingerprint, event_kind)")
                db.execSQL("CREATE INDEX index_fluvi_pulse_signal_events_created_at_utc_ms ON fluvi_pulse_signal_events(created_at_utc_ms)")
            }
        }

        /** B-phase triage state and bounded, idempotent situation history. */
        val MIGRATION_13_14: Migration = object : Migration(13, 14) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL(
                    "CREATE TABLE fluvi_pulse_situations (" +
                        "situation_key TEXT NOT NULL, domain TEXT NOT NULL, target_key TEXT NOT NULL, " +
                        "period_key TEXT NOT NULL, state TEXT NOT NULL, formation_rule TEXT, " +
                        "related_signal_keys TEXT NOT NULL, evidence_snapshot TEXT NOT NULL, decision_trace TEXT NOT NULL, " +
                        "first_observed_at_utc_ms INTEGER, last_evaluated_at_utc_ms INTEGER NOT NULL, " +
                        "last_material_change_at_utc_ms INTEGER, source_core_revision INTEGER NOT NULL, " +
                        "source_signal_generation INTEGER NOT NULL, policy_version INTEGER NOT NULL, " +
                        "semantic_fingerprint TEXT NOT NULL, state_version INTEGER NOT NULL, " +
                        "updated_at_utc_ms INTEGER NOT NULL, PRIMARY KEY(situation_key))",
                )
                db.execSQL("CREATE INDEX index_fluvi_pulse_situations_state_updated_at_utc_ms ON fluvi_pulse_situations(state, updated_at_utc_ms)")
                db.execSQL("CREATE INDEX index_fluvi_pulse_situations_domain_period_key ON fluvi_pulse_situations(domain, period_key)")
                db.execSQL("CREATE INDEX index_fluvi_pulse_situations_period_key ON fluvi_pulse_situations(period_key)")
                db.execSQL(
                    "CREATE TABLE fluvi_pulse_situation_events (" +
                        "event_id TEXT NOT NULL, situation_key TEXT NOT NULL, domain TEXT NOT NULL, period_key TEXT NOT NULL, " +
                        "event_kind TEXT NOT NULL, previous_state TEXT, next_state TEXT NOT NULL, " +
                        "previous_formation_rule TEXT, next_formation_rule TEXT, previous_evidence_count INTEGER NOT NULL, " +
                        "next_evidence_count INTEGER NOT NULL, previous_fingerprint TEXT, next_fingerprint TEXT NOT NULL, " +
                        "cause_code TEXT NOT NULL, explanation_payload TEXT NOT NULL, input_revision INTEGER NOT NULL, " +
                        "policy_version INTEGER NOT NULL, transition_sequence INTEGER NOT NULL, created_at_utc_ms INTEGER NOT NULL, " +
                        "PRIMARY KEY(event_id))",
                )
                db.execSQL("CREATE INDEX index_fluvi_pulse_situation_events_situation_key_created_at_utc_ms ON fluvi_pulse_situation_events(situation_key, created_at_utc_ms)")
                db.execSQL("CREATE INDEX index_fluvi_pulse_situation_events_next_state ON fluvi_pulse_situation_events(next_state)")
                db.execSQL("CREATE INDEX index_fluvi_pulse_situation_events_domain_period_key ON fluvi_pulse_situation_events(domain, period_key)")
                db.execSQL("CREATE UNIQUE INDEX index_fluvi_pulse_situation_events_situation_key_transition_sequence ON fluvi_pulse_situation_events(situation_key, transition_sequence)")
            }
        }

        /** C-phase priority state and bounded selection history. */
        val MIGRATION_14_15: Migration = object : Migration(14, 15) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL(
                    "CREATE TABLE fluvi_pulse_priority_state (" +
                        "id TEXT NOT NULL, selected_situation_key TEXT, selected_score INTEGER, " +
                        "source_core_revision INTEGER NOT NULL, source_triage_frame_id TEXT NOT NULL, " +
                        "policy_version INTEGER NOT NULL, selection_fingerprint TEXT NOT NULL, " +
                        "last_evaluated_at_utc_ms INTEGER NOT NULL, last_selection_change_at_utc_ms INTEGER, " +
                        "state_version INTEGER NOT NULL, PRIMARY KEY(id))",
                )
                db.execSQL(
                    "CREATE TABLE fluvi_pulse_priority_events (" +
                        "event_id TEXT NOT NULL, event_kind TEXT NOT NULL, " +
                        "previous_selected_situation_key TEXT, next_selected_situation_key TEXT, " +
                        "previous_score INTEGER, next_score INTEGER, selection_reason TEXT NOT NULL, " +
                        "source_core_revision INTEGER NOT NULL, source_triage_frame_id TEXT NOT NULL, " +
                        "policy_version INTEGER NOT NULL, transition_sequence INTEGER NOT NULL, " +
                        "created_at_utc_ms INTEGER NOT NULL, PRIMARY KEY(event_id))",
                )
                db.execSQL("CREATE INDEX index_fluvi_pulse_priority_events_created_at_utc_ms ON fluvi_pulse_priority_events(created_at_utc_ms)")
                db.execSQL("CREATE INDEX index_fluvi_pulse_priority_events_next_selected_situation_key ON fluvi_pulse_priority_events(next_selected_situation_key)")
                db.execSQL("CREATE UNIQUE INDEX index_fluvi_pulse_priority_events_transition_sequence ON fluvi_pulse_priority_events(transition_sequence)")
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
                        demo_seed_completed_at_utc_ms,
                        show_pending_ghosts_in_ledger
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
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
                        1,
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
                        OR NEW.period_kind NOT IN ('base', 'month')
                        OR (NEW.target_kind = 'aggregate' AND
                            (NEW.target_key != 'aggregate' OR NEW.category_id IS NOT NULL))
                        OR (NEW.target_kind = 'category' AND
                            (NEW.category_id IS NULL OR NEW.target_key != NEW.category_id))
                        OR (NEW.period_kind = 'base' AND
                            (NEW.year IS NULL OR NEW.month NOT BETWEEN 1 AND 12 OR
                             NEW.period_key != ('base:' || NEW.year || '-' || NEW.month)))
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

        /**
         * Version 5 was allowed to contain legacy SUM/YEAR/MONTH rows. Keep
         * its historical integrity contract valid for an in-place 4 → 5 → 6
         * upgrade; migration 5 → 6 replaces the table and installs the
         * canonical base/month-only triggers above.
         */
        private fun createLegacyFinancialLimitIntegrityTriggers(db: SupportSQLiteDatabase) {
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
                        SELECT RAISE(ABORT, 'Invalid legacy Fluvi financial limit.');
                    END
                    """.trimIndent(),
                )
            }
        }
    }
}
