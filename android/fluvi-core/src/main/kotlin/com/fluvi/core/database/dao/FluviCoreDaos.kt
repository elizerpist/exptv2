package com.fluvi.core.database.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.RawQuery
import androidx.room.Upsert
import androidx.sqlite.db.SupportSQLiteQuery
import com.fluvi.core.database.entity.FluviCategoryEntity
import com.fluvi.core.database.entity.FluviAppSettingsEntity
import com.fluvi.core.database.entity.FluviLedgerBackupCheckpointEntity
import com.fluvi.core.database.entity.FluviLedgerDeletionArchiveEntity
import com.fluvi.core.database.entity.FluviLedgerEntryEntity
import com.fluvi.core.database.entity.FluviLedgerSyncOutboxEntity
import com.fluvi.core.database.entity.FluviLedgerSyncWorkspaceEntity
import com.fluvi.core.database.entity.FluviFinancialLimitEntity
import com.fluvi.core.database.entity.FluviPulseIndicatorSettingEntity
import com.fluvi.core.database.entity.FluviPulseSignalEventEntity
import com.fluvi.core.database.entity.FluviPulseSignalStateEntity
import com.fluvi.core.database.entity.FluviPulseSituationEntity
import com.fluvi.core.database.entity.FluviPulseSituationEventEntity
import com.fluvi.core.model.FluviFinancialLimitPeriodKind
import com.fluvi.core.model.FluviFinancialLimitTargetKind
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.database.entity.FluviPartnerAliasEntity
import com.fluvi.core.database.entity.FluviPartnerEntity
import com.fluvi.core.model.CategoryAssignmentMode
import com.fluvi.core.model.LedgerSyncOperation
import com.fluvi.core.model.CheckpointStatus
import com.fluvi.core.database.entity.FluviNotificationInboxEntity
import com.fluvi.core.database.entity.FluviPushProfileEntity
import com.fluvi.core.database.entity.FluviPushRuleEntity
import com.fluvi.core.database.entity.FluviPushRuleTestResultEntity
import com.fluvi.core.database.entity.FluviPushTrainingSampleEntity
import com.fluvi.core.model.NotificationProcessingStatus
import com.fluvi.core.model.PushProfileState
import com.fluvi.core.model.PushReviewStatus
import com.fluvi.core.model.PushRuleState
import kotlinx.coroutines.flow.Flow

@Dao
internal interface FluviAppSettingsDao {
    @Query("SELECT * FROM fluvi_app_settings LIMIT 1")
    suspend fun current(): FluviAppSettingsEntity?

    @Query("SELECT core_revision FROM fluvi_app_settings LIMIT 1")
    fun observeCoreRevision(): Flow<Long>

    @Query(
        "UPDATE fluvi_app_settings SET core_revision = core_revision + 1, " +
            "updated_at_utc_ms = :updatedAtUtcMs WHERE id = :settingsId",
    )
    suspend fun incrementCoreRevision(settingsId: String, updatedAtUtcMs: Long): Int

    @Query(
        "UPDATE fluvi_app_settings SET demo_seed_version = :version, " +
            "demo_seed_completed_at_utc_ms = :completedAtUtcMs, " +
            "updated_at_utc_ms = :updatedAtUtcMs WHERE id = :settingsId",
    )
    suspend fun markDemoSeedCompleted(
        settingsId: String,
        version: Int,
        completedAtUtcMs: Long,
        updatedAtUtcMs: Long,
    ): Int

    @Query(
        "UPDATE fluvi_app_settings SET demo_seed_version = NULL, " +
            "demo_seed_completed_at_utc_ms = NULL, updated_at_utc_ms = :updatedAtUtcMs " +
            "WHERE id = :settingsId",
    )
    suspend fun clearDemoSeedMetadata(settingsId: String, updatedAtUtcMs: Long): Int
}

@Dao
internal interface FluviCategoryDao {
    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(category: FluviCategoryEntity)

    @Query("SELECT * FROM fluvi_categories WHERE id = :categoryId LIMIT 1")
    suspend fun findById(categoryId: String): FluviCategoryEntity?

    @Query(
        "SELECT * FROM fluvi_categories " +
            "ORDER BY is_system_uncategorized DESC, name COLLATE NOCASE ASC, id ASC",
    )
    suspend fun allCategories(): List<FluviCategoryEntity>

    @Query(
        "SELECT * FROM fluvi_categories " +
            "WHERE is_system_uncategorized = 1 LIMIT 1",
    )
    suspend fun systemUncategorized(): FluviCategoryEntity?

    @Query("DELETE FROM fluvi_categories WHERE id = :categoryId")
    suspend fun delete(categoryId: String)

    @Query("DELETE FROM fluvi_categories WHERE id IN (:categoryIds)")
    suspend fun deleteAll(categoryIds: List<String>): Int

    @Query(
        "UPDATE fluvi_categories SET name = :name, color_id = :colorId, icon_id = :iconId, " +
            "updated_at_utc_ms = :updatedAtUtcMs WHERE id = :categoryId",
    )
    suspend fun update(
        categoryId: String,
        name: String,
        colorId: String,
        iconId: String,
        updatedAtUtcMs: Long,
    ): Int
}

@Dao
internal interface FluviFinancialLimitDao {
    @Query(
        "SELECT * FROM fluvi_financial_limits " +
            "WHERE direction = :direction AND target_key = :targetKey AND period_key = :periodKey " +
            "LIMIT 1",
    )
    suspend fun find(
        direction: LedgerDirection,
        targetKey: String,
        periodKey: String,
    ): FluviFinancialLimitEntity?

    @Query(
        "SELECT * FROM fluvi_financial_limits " +
            "ORDER BY direction ASC, target_kind ASC, target_key ASC, period_kind ASC, year ASC, month ASC",
    )
    suspend fun all(): List<FluviFinancialLimitEntity>

    @Query(
        "SELECT * FROM fluvi_financial_limits " +
        "WHERE (period_kind = 'base' AND year <= :endYear) " +
            "OR (period_kind = 'month' AND year BETWEEN :startYear AND :endYear) " +
            "ORDER BY direction ASC, target_kind ASC, target_key ASC, period_kind ASC, year ASC, month ASC",
    )
    suspend fun forPreparedYearWindow(
        startYear: Int,
        endYear: Int,
    ): List<FluviFinancialLimitEntity>

    @Upsert
    suspend fun upsert(entity: FluviFinancialLimitEntity)

    @Upsert
    suspend fun upsertAll(entities: List<FluviFinancialLimitEntity>)

    @Query(
        "DELETE FROM fluvi_financial_limits " +
            "WHERE direction = :direction AND target_key = :targetKey AND period_key = :periodKey",
    )
    suspend fun delete(
        direction: LedgerDirection,
        targetKey: String,
        periodKey: String,
    ): Int

    @Query("DELETE FROM fluvi_financial_limits")
    suspend fun deleteAll(): Int

    @Query("SELECT COUNT(*) FROM fluvi_financial_limits")
    suspend fun count(): Long
}

/** Pulse settings are independent from financial limits and never alter them. */
@Dao
internal interface FluviPulseIndicatorSettingsDao {
    @Query(
        "SELECT * FROM fluvi_pulse_indicator_settings " +
            "WHERE indicator_id = :indicatorId AND target_key = :targetKey " +
            "ORDER BY threshold_key ASC",
    )
    suspend fun forIndicator(
        indicatorId: String,
        targetKey: String,
    ): List<FluviPulseIndicatorSettingEntity>

    @Query("SELECT * FROM fluvi_pulse_indicator_settings ORDER BY indicator_id, target_key, threshold_key")
    suspend fun all(): List<FluviPulseIndicatorSettingEntity>

    @androidx.room.Upsert
    suspend fun upsert(setting: FluviPulseIndicatorSettingEntity)

    @Query(
        "DELETE FROM fluvi_pulse_indicator_settings " +
            "WHERE indicator_id = :indicatorId AND target_key = :targetKey AND threshold_key = :thresholdKey",
    )
    suspend fun delete(
        indicatorId: String,
        targetKey: String,
        thresholdKey: String,
    ): Int
}

/** Signal persistence is diagnostic-only and intentionally independent from Core revision. */
@Dao
internal interface FluviPulseSignalDao {
    @Query("SELECT * FROM fluvi_pulse_signal_states WHERE signal_key = :signalKey LIMIT 1")
    suspend fun state(signalKey: String): FluviPulseSignalStateEntity?

    @Query(
        "SELECT * FROM fluvi_pulse_signal_events WHERE signal_key = :signalKey " +
            "ORDER BY created_at_utc_ms DESC, event_id DESC LIMIT :limit OFFSET :offset",
    )
    suspend fun eventPage(signalKey: String, limit: Int, offset: Int = 0): List<FluviPulseSignalEventEntity>

    @Upsert
    suspend fun upsertState(state: FluviPulseSignalStateEntity)

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertEvent(event: FluviPulseSignalEventEntity): Long
}

/** Situation persistence is triage-only and deliberately excluded from financial Core revision. */
@Dao
internal interface FluviPulseSituationDao {
    @Query("SELECT * FROM fluvi_pulse_situations WHERE situation_key = :situationKey LIMIT 1")
    suspend fun state(situationKey: String): FluviPulseSituationEntity?

    @Query(
        "SELECT * FROM fluvi_pulse_situations WHERE period_key = :periodKey " +
            "ORDER BY domain ASC, target_key ASC, situation_key ASC",
    )
    suspend fun statesForPeriod(periodKey: String): List<FluviPulseSituationEntity>

    @Query(
        "SELECT * FROM fluvi_pulse_situation_events WHERE situation_key = :situationKey " +
            "ORDER BY transition_sequence DESC LIMIT :limit OFFSET :offset",
    )
    suspend fun eventPage(situationKey: String, limit: Int, offset: Int = 0): List<FluviPulseSituationEventEntity>

    @Upsert
    suspend fun upsertState(state: FluviPulseSituationEntity)

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertEvent(event: FluviPulseSituationEventEntity): Long
}

@Dao
internal interface FluviPartnerDao {
    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(partner: FluviPartnerEntity)

    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insertAlias(alias: FluviPartnerAliasEntity)

    @Query("SELECT * FROM fluvi_partners WHERE id = :partnerId LIMIT 1")
    suspend fun findById(partnerId: String): FluviPartnerEntity?

    @Query("SELECT * FROM fluvi_partners")
    suspend fun allPartners(): List<FluviPartnerEntity>

    @Query("SELECT * FROM fluvi_partner_aliases WHERE partner_id IN (:partnerIds)")
    suspend fun aliasesForPartnerIds(partnerIds: List<String>): List<FluviPartnerAliasEntity>

    @Query(
        """
        SELECT partners.*
        FROM fluvi_partner_aliases AS aliases
        INNER JOIN fluvi_partners AS partners ON partners.id = aliases.partner_id
        WHERE aliases.normalized_alias = :normalizedAlias
        LIMIT 1
        """,
    )
    suspend fun findByNormalizedAlias(normalizedAlias: String): FluviPartnerEntity?

    @Query(
        "UPDATE fluvi_partners " +
            "SET default_category_id = :categoryId, updated_at_utc_ms = :updatedAtUtcMs " +
            "WHERE id = :partnerId",
    )
    suspend fun changeDefaultCategory(
        partnerId: String,
        categoryId: String,
        updatedAtUtcMs: Long,
    ): Int

    @Query(
        "UPDATE fluvi_partners " +
            "SET display_name_override = :displayNameOverride, updated_at_utc_ms = :updatedAtUtcMs " +
            "WHERE id = :partnerId",
    )
    suspend fun setDisplayNameOverride(
        partnerId: String,
        displayNameOverride: String?,
        updatedAtUtcMs: Long,
    ): Int

    @Query(
        "UPDATE fluvi_partners " +
            "SET merged_into_partner_id = :recipientId, updated_at_utc_ms = :updatedAtUtcMs " +
            "WHERE id = :donorId",
    )
    suspend fun setMergeTarget(
        donorId: String,
        recipientId: String?,
        updatedAtUtcMs: Long,
    ): Int

    @Query(
        "UPDATE fluvi_partners " +
            "SET default_category_id = :toCategoryId, updated_at_utc_ms = :updatedAtUtcMs " +
            "WHERE default_category_id = :fromCategoryId",
    )
    suspend fun retargetDefaultCategories(
        fromCategoryId: String,
        toCategoryId: String,
        updatedAtUtcMs: Long,
    ): Int

    @Query("DELETE FROM fluvi_partner_aliases WHERE partner_id IN (:partnerIds)")
    suspend fun deleteAliases(partnerIds: List<String>): Int

    @Query("DELETE FROM fluvi_partners WHERE id IN (:partnerIds)")
    suspend fun deleteAll(partnerIds: List<String>): Int
}

@Dao
internal interface FluviLedgerDao {
    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(entry: FluviLedgerEntryEntity)

    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insertAll(entries: List<FluviLedgerEntryEntity>)

    @Query("SELECT * FROM fluvi_ledger_entries WHERE id = :entryId LIMIT 1")
    suspend fun findById(entryId: String): FluviLedgerEntryEntity?

    @Query(
        "SELECT * FROM fluvi_ledger_entries " +
            "WHERE recurrence_occurrence_id = :occurrenceId LIMIT 1",
    )
    suspend fun findByRecurrenceOccurrenceId(occurrenceId: String): FluviLedgerEntryEntity?

    @Query("SELECT COUNT(*) FROM fluvi_ledger_entries")
    suspend fun queryEntriesCount(): Long

    @Query(
        "SELECT * FROM fluvi_ledger_entries " +
            "WHERE partner_id = :partnerId AND category_assignment_mode = :mode",
    )
    suspend fun entriesByPartnerAndMode(
        partnerId: String,
        mode: CategoryAssignmentMode,
    ): List<FluviLedgerEntryEntity>

    @Query("SELECT * FROM fluvi_ledger_entries WHERE category_id = :categoryId")
    suspend fun entriesByCategory(categoryId: String): List<FluviLedgerEntryEntity>

    @Query("SELECT * FROM fluvi_ledger_entries WHERE partner_id IN (:partnerIds)")
    suspend fun entriesByPartnerIds(partnerIds: List<String>): List<FluviLedgerEntryEntity>

    @Query(
        "UPDATE fluvi_ledger_entries " +
            "SET category_id = :categoryId, updated_at_utc_ms = :updatedAtUtcMs, revision = revision + 1 " +
            "WHERE partner_id IN (:partnerIds) AND category_assignment_mode = :mode",
    )
    suspend fun retargetInheritedPartnerEntries(
        partnerIds: List<String>,
        categoryId: String,
        mode: CategoryAssignmentMode,
        updatedAtUtcMs: Long,
    ): Int

    @Query(
        "UPDATE fluvi_ledger_entries " +
            "SET category_id = :toCategoryId, updated_at_utc_ms = :updatedAtUtcMs, revision = revision + 1 " +
            "WHERE category_id = :fromCategoryId",
    )
    suspend fun retargetCategory(
        fromCategoryId: String,
        toCategoryId: String,
        updatedAtUtcMs: Long,
    ): Int

    @Query(
        "UPDATE fluvi_ledger_entries " +
            "SET amount_scaled_100 = :amountScaled100, updated_at_utc_ms = :updatedAtUtcMs, " +
            "revision = revision + 1 WHERE id = :entryId",
    )
    suspend fun updateAmount(
        entryId: String,
        amountScaled100: Long,
        updatedAtUtcMs: Long,
    ): Int

    @Query(
        "UPDATE fluvi_ledger_entries " +
            "SET category_id = :categoryId, category_assignment_mode = :mode, " +
            "updated_at_utc_ms = :updatedAtUtcMs, revision = revision + 1 " +
            "WHERE id = :entryId",
    )
    suspend fun updateCategory(
        entryId: String,
        categoryId: String,
        mode: CategoryAssignmentMode,
        updatedAtUtcMs: Long,
    ): Int

    @Query(
        "UPDATE fluvi_ledger_entries SET " +
            "partner_id = :partnerId, category_id = :categoryId, " +
            "category_assignment_mode = :categoryAssignmentMode, note = :note, " +
            "amount_scaled_100 = :amountScaled100, " +
            "booked_local_epoch_day = :bookedLocalEpochDay, " +
            "booked_local_time_minutes = :bookedLocalTimeMinutes, " +
            "occurred_at_utc_ms = :occurredAtUtcMs, updated_at_utc_ms = :updatedAtUtcMs, " +
            "revision = revision + 1 WHERE id = :entryId AND revision = :expectedRevision",
    )
    suspend fun updateEditorEntry(
        entryId: String,
        expectedRevision: Long,
        partnerId: String,
        categoryId: String,
        categoryAssignmentMode: CategoryAssignmentMode,
        note: String?,
        amountScaled100: Long,
        bookedLocalEpochDay: Long,
        bookedLocalTimeMinutes: Int,
        occurredAtUtcMs: Long,
        updatedAtUtcMs: Long,
    ): Int

    @Query("DELETE FROM fluvi_ledger_entries WHERE id = :entryId")
    suspend fun delete(entryId: String): Int

    @Query("DELETE FROM fluvi_ledger_entries WHERE id IN (:entryIds)")
    suspend fun deleteAll(entryIds: List<String>): Int

    @RawQuery(observedEntities = [FluviLedgerEntryEntity::class])
    suspend fun queryEntries(query: SupportSQLiteQuery): List<FluviLedgerEntryEntity>

    @RawQuery(observedEntities = [FluviLedgerEntryEntity::class])
    suspend fun queryCommittedDashboardRows(
        query: SupportSQLiteQuery,
    ): List<FluviCommittedDashboardRow>

    @RawQuery(observedEntities = [FluviLedgerEntryEntity::class])
    suspend fun queryAggregate(query: SupportSQLiteQuery): FluviLedgerAggregateRow

    @RawQuery(observedEntities = [FluviLedgerEntryEntity::class])
    suspend fun queryAmountDomain(query: SupportSQLiteQuery): FluviLedgerAmountDomainRow

    @RawQuery(observedEntities = [FluviLedgerEntryEntity::class])
    suspend fun queryAggregateBuckets(
        query: SupportSQLiteQuery,
    ): List<FluviLedgerAggregateBucketRow>

    @RawQuery(observedEntities = [FluviLedgerEntryEntity::class])
    suspend fun queryDashboardDailyAggregates(
        query: SupportSQLiteQuery,
    ): List<FluviLedgerDailyAggregateRow>

    @RawQuery(observedEntities = [FluviLedgerEntryEntity::class])
    suspend fun queryStringIds(query: SupportSQLiteQuery): List<FluviStringIdRow>
}

@Dao
internal interface FluviLedgerDeletionArchiveDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(archive: FluviLedgerDeletionArchiveEntity)

    @Query(
        "SELECT * FROM fluvi_ledger_deletion_archive " +
            "WHERE entry_id = :entryId LIMIT 1",
    )
    suspend fun findByEntryId(entryId: String): FluviLedgerDeletionArchiveEntity?

    @Query(
        "DELETE FROM fluvi_ledger_deletion_archive " +
            "WHERE required_checkpoint_id = :checkpointId",
    )
    suspend fun purgeForAcknowledgedCheckpoint(checkpointId: String): Int
}

@Dao
internal interface FluviLedgerBackupCheckpointDao {
    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(checkpoint: FluviLedgerBackupCheckpointEntity)

    @Query("SELECT * FROM fluvi_ledger_backup_checkpoints WHERE id = :checkpointId LIMIT 1")
    suspend fun findById(checkpointId: String): FluviLedgerBackupCheckpointEntity?

    @Query(
        "SELECT * FROM fluvi_ledger_backup_checkpoints WHERE trigger_key = :triggerKey LIMIT 1",
    )
    suspend fun findByTriggerKey(triggerKey: String): FluviLedgerBackupCheckpointEntity?

    @Query(
        "UPDATE fluvi_ledger_backup_checkpoints SET prepared_bundle_path = :preparedBundlePath, " +
            "updated_at_utc_ms = :updatedAtUtcMs WHERE id = :checkpointId",
    )
    suspend fun setPreparedBundlePath(
        checkpointId: String,
        preparedBundlePath: String,
        updatedAtUtcMs: Long,
    ): Int

    @Query(
        "UPDATE fluvi_ledger_backup_checkpoints SET status = :status, " +
            "remote_backup_file_id = :remoteBackupFileId, updated_at_utc_ms = :updatedAtUtcMs " +
            "WHERE id = :checkpointId",
    )
    suspend fun updateStatus(
        checkpointId: String,
        status: CheckpointStatus,
        remoteBackupFileId: String?,
        updatedAtUtcMs: Long,
    ): Int
}

@Dao
internal interface FluviLedgerSyncOutboxDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(operation: FluviLedgerSyncOutboxEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAll(operations: List<FluviLedgerSyncOutboxEntity>)

    @Query(
        "SELECT * FROM fluvi_ledger_sync_outbox " +
            "WHERE entry_id = :entryId LIMIT 1",
    )
    suspend fun pendingFor(entryId: String): FluviLedgerSyncOutboxEntity?

    @Query("DELETE FROM fluvi_ledger_sync_outbox WHERE entry_id = :entryId")
    suspend fun acknowledge(entryId: String): Int

    @Query("DELETE FROM fluvi_ledger_sync_outbox WHERE entry_id IN (:entryIds)")
    suspend fun deleteAll(entryIds: List<String>): Int

    @Query(
        "SELECT * FROM fluvi_ledger_sync_outbox " +
            "WHERE operation = :operation ORDER BY updated_at_utc_ms ASC LIMIT :limit",
    )
    suspend fun pendingByOperation(
        operation: LedgerSyncOperation,
        limit: Int,
    ): List<FluviLedgerSyncOutboxEntity>
}

@Dao
internal interface FluviLedgerSyncWorkspaceDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(workspace: FluviLedgerSyncWorkspaceEntity)

    @Query("SELECT * FROM fluvi_ledger_sync_workspaces WHERE booking_year = :bookingYear LIMIT 1")
    suspend fun findByBookingYear(bookingYear: Int): FluviLedgerSyncWorkspaceEntity?
}

@Dao
internal interface FluviFutureReferenceDao {
    @Query(
        "UPDATE fluvi_recurrence_rules " +
            "SET category_id = :categoryId, updated_at_utc_ms = :updatedAtUtcMs " +
            "WHERE partner_id IN (:partnerIds) AND category_assignment_mode = :mode",
    )
    suspend fun retargetInheritedRecurrenceRules(
        partnerIds: List<String>,
        categoryId: String,
        mode: CategoryAssignmentMode,
        updatedAtUtcMs: Long,
    ): Int

    @Query(
        "UPDATE fluvi_recurrence_rules " +
            "SET category_id = :toCategoryId, updated_at_utc_ms = :updatedAtUtcMs " +
            "WHERE category_id = :fromCategoryId",
    )
    suspend fun retargetRecurrenceCategories(
        fromCategoryId: String,
        toCategoryId: String,
        updatedAtUtcMs: Long,
    ): Int

    @Query(
        "UPDATE fluvi_occurrence_overrides " +
            "SET category_id = :toCategoryId, updated_at_utc_ms = :updatedAtUtcMs " +
            "WHERE category_id = :fromCategoryId",
    )
    suspend fun retargetOccurrenceOverrideCategories(
        fromCategoryId: String,
        toCategoryId: String,
        updatedAtUtcMs: Long,
    ): Int
}

/** The single persisted source for notification capture, profiles and parser state. */
@Dao
internal interface FluviPushAutomationDao {
    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insertProfile(profile: FluviPushProfileEntity)

    @Query("SELECT * FROM fluvi_push_profiles ORDER BY updated_at_utc_ms DESC, id ASC")
    suspend fun allProfiles(): List<FluviPushProfileEntity>

    @Query("SELECT * FROM fluvi_push_profiles WHERE id = :profileId LIMIT 1")
    suspend fun profile(profileId: String): FluviPushProfileEntity?

    @Query("SELECT * FROM fluvi_push_profiles WHERE package_name = :packageName LIMIT 1")
    suspend fun profileForPackage(packageName: String): FluviPushProfileEntity?

    @Query("UPDATE fluvi_push_profiles SET display_name = :name, default_direction = :direction, state = :state, updated_at_utc_ms = :updatedAtUtcMs, revision = revision + 1 WHERE id = :profileId")
    suspend fun updateProfile(profileId: String, name: String, direction: com.fluvi.core.model.PushTransactionDirection, state: PushProfileState, updatedAtUtcMs: Long): Int

    @Query("DELETE FROM fluvi_push_profiles WHERE id = :profileId")
    suspend fun deleteProfile(profileId: String): Int

    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insertRule(rule: FluviPushRuleEntity)

    @Query("SELECT * FROM fluvi_push_rules WHERE profile_id = :profileId ORDER BY priority ASC, created_at_utc_ms ASC")
    suspend fun rulesForProfile(profileId: String): List<FluviPushRuleEntity>

    @Query("SELECT * FROM fluvi_push_rules WHERE profile_id = :profileId AND state = :state ORDER BY priority ASC, id ASC")
    suspend fun rulesForProfileAndState(profileId: String, state: PushRuleState): List<FluviPushRuleEntity>

    @Query("SELECT * FROM fluvi_push_rules WHERE id = :ruleId LIMIT 1")
    suspend fun rule(ruleId: String): FluviPushRuleEntity?

    @Query("UPDATE fluvi_push_rules SET state = :state, updated_at_utc_ms = :updatedAtUtcMs WHERE id = :ruleId")
    suspend fun updateRuleState(ruleId: String, state: PushRuleState, updatedAtUtcMs: Long): Int

    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insertSample(sample: FluviPushTrainingSampleEntity)

    @Query("SELECT * FROM fluvi_push_training_samples WHERE rule_id = :ruleId ORDER BY created_at_utc_ms DESC")
    suspend fun samplesForRule(ruleId: String): List<FluviPushTrainingSampleEntity>

    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insertTestResult(result: FluviPushRuleTestResultEntity)

    @Query("SELECT * FROM fluvi_push_rule_test_results WHERE rule_id = :ruleId ORDER BY created_at_utc_ms DESC LIMIT 1")
    suspend fun latestTestResult(ruleId: String): FluviPushRuleTestResultEntity?

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertInbox(event: FluviNotificationInboxEntity): Long

    @Query("SELECT * FROM fluvi_notification_inbox WHERE id = :eventId LIMIT 1")
    suspend fun inbox(eventId: String): FluviNotificationInboxEntity?

    @Query("SELECT * FROM fluvi_notification_inbox WHERE fingerprint = :fingerprint LIMIT 1")
    suspend fun inboxByFingerprint(fingerprint: String): FluviNotificationInboxEntity?

    @Query("SELECT * FROM fluvi_notification_inbox WHERE profile_id = :profileId ORDER BY received_at_utc_ms DESC, id DESC LIMIT :limit OFFSET :offset")
    suspend fun inboxForProfile(profileId: String, limit: Int, offset: Int): List<FluviNotificationInboxEntity>

    @Query("SELECT * FROM fluvi_notification_inbox ORDER BY received_at_utc_ms DESC, id DESC LIMIT :limit OFFSET :offset")
    suspend fun inboxPage(limit: Int, offset: Int): List<FluviNotificationInboxEntity>

    @Query("SELECT COUNT(*) FROM fluvi_notification_inbox WHERE review_status = :status")
    suspend fun inboxCountByReviewStatus(status: PushReviewStatus): Long

    @Query("SELECT COUNT(*) FROM fluvi_notification_inbox WHERE profile_id = :profileId")
    suspend fun inboxCountForProfile(profileId: String): Long

    @Query("UPDATE fluvi_notification_inbox SET parse_status = :parseStatus, processing_status = :processingStatus, review_status = :reviewStatus, confidence = :confidence, suggested_payload_json = :payload, diagnostics_json = :diagnostics, ledger_entry_id = :ledgerEntryId, updated_at_utc_ms = :updatedAtUtcMs WHERE id = :eventId")
    suspend fun updateInboxDecision(
        eventId: String,
        parseStatus: com.fluvi.core.model.NotificationParseStatus,
        processingStatus: NotificationProcessingStatus,
        reviewStatus: PushReviewStatus,
        confidence: Double?,
        payload: String?,
        diagnostics: String?,
        ledgerEntryId: String?,
        updatedAtUtcMs: Long,
    ): Int

    @Query("UPDATE fluvi_notification_inbox SET training_status = :status, updated_at_utc_ms = :updatedAtUtcMs WHERE id = :eventId")
    suspend fun updateTrainingStatus(eventId: String, status: com.fluvi.core.model.NotificationTrainingStatus, updatedAtUtcMs: Long): Int
}

@Dao
internal interface FluviQuerySnapshotDao {
    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insertSnapshot(snapshot: com.fluvi.core.database.entity.FluviQuerySnapshotEntity)

    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insertPeriods(periods: List<com.fluvi.core.database.entity.FluviQuerySnapshotPeriodEntity>)

    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insertCategories(categories: List<com.fluvi.core.database.entity.FluviQuerySnapshotCategoryEntity>)

    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insertPartners(partners: List<com.fluvi.core.database.entity.FluviQuerySnapshotPartnerEntity>)

    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insertRefinements(refinements: List<com.fluvi.core.database.entity.FluviQuerySnapshotRefinementEntity>)

    @Query("SELECT * FROM fluvi_query_snapshots WHERE id = :snapshotId LIMIT 1")
    suspend fun findSnapshot(snapshotId: String): com.fluvi.core.database.entity.FluviQuerySnapshotEntity?

    @Query(
        "SELECT * FROM fluvi_query_snapshots " +
            "ORDER BY updated_at_utc_ms DESC, created_at_utc_ms ASC, id ASC",
    )
    suspend fun allSnapshots(): List<com.fluvi.core.database.entity.FluviQuerySnapshotEntity>

    @Query(
        "SELECT * FROM fluvi_query_snapshots WHERE direction = :direction " +
            "ORDER BY updated_at_utc_ms DESC, created_at_utc_ms ASC, id ASC",
    )
    suspend fun snapshotsForDirection(
        direction: com.fluvi.core.model.LedgerDirection,
    ): List<com.fluvi.core.database.entity.FluviQuerySnapshotEntity>

    @Query("SELECT * FROM fluvi_query_snapshot_periods WHERE snapshot_id = :snapshotId")
    suspend fun periods(snapshotId: String): List<com.fluvi.core.database.entity.FluviQuerySnapshotPeriodEntity>

    @Query("SELECT * FROM fluvi_query_snapshot_periods WHERE snapshot_id IN (:snapshotIds)")
    suspend fun periodsForSnapshots(
        snapshotIds: List<String>,
    ): List<com.fluvi.core.database.entity.FluviQuerySnapshotPeriodEntity>

    @Query("SELECT * FROM fluvi_query_snapshot_categories WHERE snapshot_id = :snapshotId")
    suspend fun categories(snapshotId: String): List<com.fluvi.core.database.entity.FluviQuerySnapshotCategoryEntity>

    @Query("SELECT * FROM fluvi_query_snapshot_categories WHERE snapshot_id IN (:snapshotIds)")
    suspend fun categoriesForSnapshots(
        snapshotIds: List<String>,
    ): List<com.fluvi.core.database.entity.FluviQuerySnapshotCategoryEntity>

    @Query("SELECT * FROM fluvi_query_snapshot_partners WHERE snapshot_id = :snapshotId")
    suspend fun partners(snapshotId: String): List<com.fluvi.core.database.entity.FluviQuerySnapshotPartnerEntity>

    @Query("SELECT * FROM fluvi_query_snapshot_partners WHERE snapshot_id IN (:snapshotIds)")
    suspend fun partnersForSnapshots(
        snapshotIds: List<String>,
    ): List<com.fluvi.core.database.entity.FluviQuerySnapshotPartnerEntity>

    @Query("SELECT * FROM fluvi_query_snapshot_refinements WHERE snapshot_id = :snapshotId")
    suspend fun refinements(snapshotId: String): List<com.fluvi.core.database.entity.FluviQuerySnapshotRefinementEntity>

    @Query("SELECT * FROM fluvi_query_snapshot_refinements WHERE snapshot_id IN (:snapshotIds)")
    suspend fun refinementsForSnapshots(
        snapshotIds: List<String>,
    ): List<com.fluvi.core.database.entity.FluviQuerySnapshotRefinementEntity>

    @Query("DELETE FROM fluvi_query_snapshot_periods WHERE snapshot_id = :snapshotId")
    suspend fun deletePeriods(snapshotId: String): Int

    @Query("DELETE FROM fluvi_query_snapshot_categories WHERE snapshot_id = :snapshotId")
    suspend fun deleteCategories(snapshotId: String): Int

    @Query("DELETE FROM fluvi_query_snapshot_partners WHERE snapshot_id = :snapshotId")
    suspend fun deletePartners(snapshotId: String): Int

    @Query("DELETE FROM fluvi_query_snapshot_refinements WHERE snapshot_id = :snapshotId")
    suspend fun deleteRefinements(snapshotId: String): Int

    @Query(
        "UPDATE fluvi_query_snapshots SET name = :name, direction = :direction, " +
            "updated_at_utc_ms = :updatedAtUtcMs WHERE id = :snapshotId",
    )
    suspend fun updateSnapshotMetadata(
        snapshotId: String,
        name: String,
        direction: com.fluvi.core.model.LedgerDirection,
        updatedAtUtcMs: Long,
    ): Int

    @Query(
        "UPDATE fluvi_query_snapshots SET name = :name, " +
            "updated_at_utc_ms = :updatedAtUtcMs WHERE id = :snapshotId",
    )
    suspend fun renameSnapshot(
        snapshotId: String,
        name: String,
        updatedAtUtcMs: Long,
    ): Int

    @Query("DELETE FROM fluvi_query_snapshots WHERE id = :snapshotId")
    suspend fun deleteSnapshot(snapshotId: String): Int

    @Query(
        "DELETE FROM fluvi_query_snapshot_categories " +
            "WHERE category_id = :targetCategoryId AND snapshot_id IN (" +
            "SELECT snapshot_id FROM fluvi_query_snapshot_categories " +
            "WHERE category_id = :sourceCategoryId)",
    )
    suspend fun removeTargetCategoryFiltersThatWouldCollide(
        sourceCategoryId: String,
        targetCategoryId: String,
    ): Int

    @Query(
        "UPDATE fluvi_query_snapshot_categories " +
            "SET category_id = :toCategoryId " +
            "WHERE category_id = :fromCategoryId",
    )
    suspend fun retargetCategoryFilters(
        fromCategoryId: String,
        toCategoryId: String,
    ): Int
}

/** Persisted rules and occurrence snapshots. Kept outside Ledger DAO so previews cannot leak into aggregates. */
@Dao
internal interface FluviRecurrenceDao {
    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insertRule(rule: com.fluvi.core.database.entity.FluviRecurrenceRuleEntity)

    @Query("SELECT * FROM fluvi_recurrence_rules WHERE id = :ruleId LIMIT 1")
    suspend fun rule(ruleId: String): com.fluvi.core.database.entity.FluviRecurrenceRuleEntity?

    @Query("SELECT * FROM fluvi_recurrence_rules WHERE archived_at_utc_ms IS NULL ORDER BY is_active DESC, updated_at_utc_ms DESC, id ASC")
    suspend fun rules(): List<com.fluvi.core.database.entity.FluviRecurrenceRuleEntity>

    @Query(
        "UPDATE fluvi_recurrence_rules SET is_active = :isActive, updated_at_utc_ms = :now " +
            "WHERE id = :ruleId AND archived_at_utc_ms IS NULL",
    )
    suspend fun setRuleActive(ruleId: String, isActive: Boolean, now: Long): Int

    /**
     * Retains the rule, completed occurrences and their Ledger foreign keys
     * for audit/restore, while removing it from active generation and lists.
     */
    @Query(
        "UPDATE fluvi_recurrence_rules SET is_active = 0, archived_at_utc_ms = :now, " +
            "updated_at_utc_ms = :now WHERE id = :ruleId AND archived_at_utc_ms IS NULL",
    )
    suspend fun archiveRule(ruleId: String, now: Long): Int

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertTimeConfig(
        config: com.fluvi.core.database.entity.FluviTimeRecurringRuleConfigEntity,
    )

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertPushConfig(
        config: com.fluvi.core.database.entity.FluviPushRecurringRuleConfigEntity,
    )

    @Query("SELECT * FROM fluvi_push_recurring_rule_config WHERE rule_id = :ruleId LIMIT 1")
    suspend fun pushConfig(
        ruleId: String,
    ): com.fluvi.core.database.entity.FluviPushRecurringRuleConfigEntity?

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertOccurrence(occurrence: com.fluvi.core.database.entity.FluviRecurrenceOccurrenceEntity): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertOccurrenceOverride(
        occurrenceOverride: com.fluvi.core.database.entity.FluviOccurrenceOverrideEntity,
    )

    @Query(
        "SELECT * FROM fluvi_occurrence_overrides " +
            "WHERE rule_id = :ruleId AND occurrence_key = :occurrenceKey LIMIT 1",
    )
    suspend fun occurrenceOverride(
        ruleId: String,
        occurrenceKey: String,
    ): com.fluvi.core.database.entity.FluviOccurrenceOverrideEntity?

    @Query("SELECT * FROM fluvi_recurrence_occurrences WHERE id = :occurrenceId LIMIT 1")
    suspend fun occurrence(occurrenceId: String): com.fluvi.core.database.entity.FluviRecurrenceOccurrenceEntity?

    @Query("SELECT * FROM fluvi_recurrence_occurrences WHERE rule_id = :ruleId ORDER BY expected_at_utc_ms ASC, id ASC")
    suspend fun occurrencesForRule(ruleId: String): List<com.fluvi.core.database.entity.FluviRecurrenceOccurrenceEntity>

    @Query(
        "SELECT * FROM fluvi_recurrence_occurrences " +
            "WHERE expected_local_epoch_day BETWEEN :fromEpochDay AND :toEpochDay " +
            "ORDER BY expected_local_epoch_day ASC, expected_local_time_minutes ASC, id ASC",
    )
    suspend fun occurrencesBetweenDays(
        fromEpochDay: Long,
        toEpochDay: Long,
    ): List<com.fluvi.core.database.entity.FluviRecurrenceOccurrenceEntity>

    @Query("SELECT * FROM fluvi_recurrence_occurrences WHERE status = :status ORDER BY expected_at_utc_ms ASC, id ASC LIMIT :limit OFFSET :offset")
    suspend fun occurrencesByStatus(status: com.fluvi.core.model.RecurrenceOccurrenceStatus, limit: Int, offset: Int): List<com.fluvi.core.database.entity.FluviRecurrenceOccurrenceEntity>

    /** Bounded rolling-window source for the dashboard's presentation-only ghost lane. */
    @Query(
        "SELECT occurrence.* FROM fluvi_recurrence_occurrences AS occurrence " +
            "JOIN fluvi_recurrence_rules AS rule ON rule.id = occurrence.rule_id " +
            "WHERE occurrence.status = 'pending' AND rule.is_active = 1 AND rule.archived_at_utc_ms IS NULL " +
            "AND EXISTS (SELECT 1 FROM fluvi_app_settings " +
            "WHERE id = :settingsId AND show_pending_ghosts_in_ledger = 1) " +
            "ORDER BY occurrence.direction ASC, occurrence.expected_local_epoch_day DESC, " +
            "occurrence.expected_local_time_minutes DESC, occurrence.id DESC",
    )
    suspend fun activeVisiblePendingOccurrences(
        settingsId: String,
    ): List<com.fluvi.core.database.entity.FluviRecurrenceOccurrenceEntity>

    /** Pulse uses pending occurrence truth independently from Ledger visibility. */
    @Query(
        "SELECT occurrence.* FROM fluvi_recurrence_occurrences AS occurrence " +
            "JOIN fluvi_recurrence_rules AS rule ON rule.id = occurrence.rule_id " +
            "WHERE occurrence.status = 'pending' AND rule.is_active = 1 " +
            "AND rule.archived_at_utc_ms IS NULL " +
            "AND occurrence.expected_at_utc_ms BETWEEN :fromUtcMs AND :toUtcMs " +
            "ORDER BY occurrence.expected_at_utc_ms ASC, occurrence.id ASC",
    )
    suspend fun activePendingBetween(
        fromUtcMs: Long,
        toUtcMs: Long,
    ): List<com.fluvi.core.database.entity.FluviRecurrenceOccurrenceEntity>

    @Query("SELECT * FROM fluvi_recurrence_occurrences ORDER BY expected_at_utc_ms ASC, id ASC LIMIT :limit OFFSET :offset")
    suspend fun occurrencePage(limit: Int, offset: Int): List<com.fluvi.core.database.entity.FluviRecurrenceOccurrenceEntity>

    @Query("SELECT COUNT(*) FROM fluvi_recurrence_occurrences WHERE status = :status")
    suspend fun countByStatus(status: com.fluvi.core.model.RecurrenceOccurrenceStatus): Long

    @Query("SELECT COUNT(*) FROM fluvi_recurrence_occurrences WHERE status = 'pending' AND expected_at_utc_ms <= :now")
    suspend fun dueCount(now: Long): Long

    @Query("SELECT * FROM fluvi_recurrence_occurrences WHERE status = 'pending' AND expected_at_utc_ms <= :now ORDER BY expected_at_utc_ms ASC")
    suspend fun duePending(now: Long): List<com.fluvi.core.database.entity.FluviRecurrenceOccurrenceEntity>

    @Query(
        "SELECT occurrence.* FROM fluvi_recurrence_occurrences AS occurrence " +
            "JOIN fluvi_recurrence_rules AS rule ON rule.id = occurrence.rule_id " +
            "WHERE occurrence.status = 'pending' AND occurrence.trigger_kind = 'time' " +
            "AND rule.is_active = 1 AND rule.archived_at_utc_ms IS NULL " +
            "ORDER BY occurrence.expected_at_utc_ms ASC, occurrence.id ASC LIMIT 1",
    )
    suspend fun nextActiveTimeOccurrence(): com.fluvi.core.database.entity.FluviRecurrenceOccurrenceEntity?

    /**
     * The parser has already extracted amount and merchant.  SQL narrows by
     * profile/rule, direction, date window, amount tolerance and active rule;
     * canonical partner identity is checked by the use case afterwards.
     */
    @Query(
        "SELECT occurrence.* FROM fluvi_recurrence_occurrences AS occurrence " +
            "JOIN fluvi_recurrence_rules AS rule ON rule.id = occurrence.rule_id " +
            "JOIN fluvi_push_recurring_rule_config AS config ON config.rule_id = rule.id " +
            "WHERE occurrence.status = 'pending' AND rule.is_active = 1 AND rule.archived_at_utc_ms IS NULL " +
            "AND occurrence.trigger_kind = 'push' " +
            "AND config.push_profile_id = :profileId AND config.push_rule_id = :pushRuleId " +
            "AND occurrence.direction = :direction " +
            "AND ABS(occurrence.expected_at_utc_ms - :receivedAtUtcMs) <= config.day_window * 86400000 " +
            "AND (occurrence.expected_amount_scaled_100 IS NULL " +
            "OR ABS(occurrence.expected_amount_scaled_100 - :amountScaled100) <= config.amount_tolerance_scaled_100) " +
            "ORDER BY occurrence.expected_at_utc_ms ASC, occurrence.id ASC",
    )
    suspend fun pendingPushCandidates(
        profileId: String,
        pushRuleId: String,
        direction: LedgerDirection,
        amountScaled100: Long,
        receivedAtUtcMs: Long,
    ): List<com.fluvi.core.database.entity.FluviRecurrenceOccurrenceEntity>

    /**
     * Human review has no need to re-run parser matching. It may resolve a
     * single eligible pending/review occurrence for the notification's
     * profile, while multiple candidates deliberately remain unresolved.
     */
    @Query(
        "SELECT occurrence.* FROM fluvi_recurrence_occurrences AS occurrence " +
            "JOIN fluvi_recurrence_rules AS rule ON rule.id = occurrence.rule_id " +
            "JOIN fluvi_push_recurring_rule_config AS config ON config.rule_id = rule.id " +
            "WHERE occurrence.status IN ('pending', 'review') AND rule.is_active = 1 AND rule.archived_at_utc_ms IS NULL " +
            "AND occurrence.trigger_kind = 'push' " +
            "AND config.push_profile_id = :profileId AND config.push_rule_id IS NOT NULL " +
            "AND occurrence.direction = :direction " +
            "AND ABS(occurrence.expected_at_utc_ms - :receivedAtUtcMs) <= config.day_window * 86400000 " +
            "AND (occurrence.expected_amount_scaled_100 IS NULL " +
            "OR ABS(occurrence.expected_amount_scaled_100 - :amountScaled100) <= config.amount_tolerance_scaled_100) " +
            "ORDER BY occurrence.expected_at_utc_ms ASC, occurrence.id ASC",
    )
    suspend fun reviewPushCandidates(
        profileId: String,
        direction: LedgerDirection,
        amountScaled100: Long,
        receivedAtUtcMs: Long,
    ): List<com.fluvi.core.database.entity.FluviRecurrenceOccurrenceEntity>

    @Query(
        "SELECT occurrence.* FROM fluvi_recurrence_occurrences AS occurrence " +
            "JOIN fluvi_recurrence_rules AS rule ON rule.id = occurrence.rule_id " +
            "JOIN fluvi_push_recurring_rule_config AS config ON config.rule_id = rule.id " +
            "WHERE occurrence.status = 'realized' AND occurrence.trigger_kind = 'push' " +
            "AND config.push_profile_id = :profileId AND config.push_rule_id = :pushRuleId " +
            "AND occurrence.direction = :direction " +
            "AND ABS(occurrence.expected_at_utc_ms - :receivedAtUtcMs) <= config.day_window * 86400000 " +
            "AND (occurrence.expected_amount_scaled_100 IS NULL " +
            "OR ABS(occurrence.expected_amount_scaled_100 - :amountScaled100) <= config.amount_tolerance_scaled_100) " +
            "ORDER BY occurrence.expected_at_utc_ms ASC, occurrence.id ASC",
    )
    suspend fun realizedPushEvidenceCandidates(
        profileId: String,
        pushRuleId: String,
        direction: LedgerDirection,
        amountScaled100: Long,
        receivedAtUtcMs: Long,
    ): List<com.fluvi.core.database.entity.FluviRecurrenceOccurrenceEntity>

    /**
     * Time-triggered rules intentionally have no Push Parser binding.  This
     * narrow date/direction candidate set lets a later bank notification act
     * as evidence instead of manufacturing a second booked entry.
     */
    @Query(
        "SELECT occurrence.* FROM fluvi_recurrence_occurrences AS occurrence " +
            "WHERE occurrence.status = 'realized' AND occurrence.trigger_kind = 'time' " +
            "AND occurrence.direction = :direction " +
            "AND ABS(occurrence.expected_at_utc_ms - :receivedAtUtcMs) <= :windowMs " +
            "ORDER BY occurrence.expected_at_utc_ms ASC, occurrence.id ASC",
    )
    suspend fun realizedTimeEvidenceCandidates(
        direction: LedgerDirection,
        receivedAtUtcMs: Long,
        windowMs: Long,
    ): List<com.fluvi.core.database.entity.FluviRecurrenceOccurrenceEntity>

    @Query(
        "UPDATE fluvi_recurrence_occurrences SET status = 'review', updated_at_utc_ms = :now, " +
            "revision = revision + 1 WHERE id IN (:occurrenceIds) AND status = 'pending'",
    )
    suspend fun markReview(occurrenceIds: List<String>, now: Long): Int

    @Query("UPDATE fluvi_recurrence_occurrences SET status = :status, realization_kind = :kind, resolved_at_utc_ms = :resolvedAt, updated_at_utc_ms = :now, revision = revision + 1 WHERE id = :occurrenceId AND status = :expected")
    suspend fun transition(
        occurrenceId: String,
        expected: com.fluvi.core.model.RecurrenceOccurrenceStatus,
        status: com.fluvi.core.model.RecurrenceOccurrenceStatus,
        kind: com.fluvi.core.model.RecurrenceRealizationKind?,
        resolvedAt: Long?,
        now: Long,
    ): Int

    @Query(
        "UPDATE fluvi_recurrence_occurrences SET status = 'cancelled', realization_kind = NULL, " +
            "resolved_at_utc_ms = :now, updated_at_utc_ms = :now, revision = revision + 1 " +
            "WHERE rule_id = :ruleId AND status IN ('pending', 'review')",
    )
    suspend fun cancelOpenOccurrencesForArchivedRule(ruleId: String, now: Long): Int

    @Query("UPDATE fluvi_recurrence_occurrences SET expected_amount_scaled_100 = :amount, expected_local_epoch_day = :epochDay, expected_local_time_minutes = :minutes, expected_at_utc_ms = :atUtc, partner_id = :partnerId, category_id = :categoryId, category_assignment_mode = :mode, note = :note, updated_at_utc_ms = :now, revision = revision + 1 WHERE id = :occurrenceId AND status = 'pending'")
    suspend fun updatePendingOccurrence(
        occurrenceId: String,
        amount: Long?,
        epochDay: Long,
        minutes: Int,
        atUtc: Long,
        partnerId: String,
        categoryId: String,
        mode: CategoryAssignmentMode,
        note: String?,
        now: Long,
    ): Int

    @Query("UPDATE fluvi_app_settings SET show_pending_ghosts_in_ledger = :show, updated_at_utc_ms = :now WHERE id = :settingsId")
    suspend fun setShowPendingGhosts(settingsId: String, show: Boolean, now: Long): Int

    @Query("SELECT show_pending_ghosts_in_ledger FROM fluvi_app_settings LIMIT 1")
    suspend fun showPendingGhosts(): Boolean?
}
