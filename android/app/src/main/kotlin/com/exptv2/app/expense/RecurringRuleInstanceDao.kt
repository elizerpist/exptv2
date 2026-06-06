package com.exptv2.app.expense

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface RecurringRuleInstanceDao {
    @Query("SELECT * FROM recurring_rule_instances WHERE status = 'pending' ORDER BY estimatedDate DESC, id DESC")
    suspend fun pending(): List<RecurringRuleInstanceEntity>

    @Query("SELECT * FROM recurring_rule_instances WHERE status = 'pending' AND periodKey = :periodKey ORDER BY estimatedDate ASC, id ASC")
    suspend fun pendingForPeriod(periodKey: String): List<RecurringRuleInstanceEntity>

    @Query("SELECT * FROM recurring_rule_instances WHERE status = 'pending' AND triggerTypeSnapshot = 'date' AND estimatedDate <= :date ORDER BY estimatedDate ASC, id ASC")
    suspend fun dueDateTriggered(date: String): List<RecurringRuleInstanceEntity>

    @Query("SELECT * FROM recurring_rule_instances WHERE ruleId = :ruleId AND periodKey = :periodKey LIMIT 1")
    suspend fun byRuleAndPeriod(ruleId: Int, periodKey: String): RecurringRuleInstanceEntity?

    @Query("SELECT COUNT(*) FROM recurring_rule_instances WHERE matchedNotificationEventId = :eventId AND status = 'activated'")
    suspend fun activatedCountForNotificationEvent(eventId: Long): Int

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insert(row: RecurringRuleInstanceEntity): Long

    @Query("UPDATE recurring_rule_instances SET status = :status, updatedAt = :updatedAt WHERE id = :id")
    suspend fun updateStatus(id: Int, status: String, updatedAt: Long)

    @Query("UPDATE recurring_rule_instances SET status = 'activated', activatedTransactionId = :transactionId, activatedAt = :activatedAt, matchedNotificationEventId = :eventId, matchConfidence = :confidence, updatedAt = :activatedAt WHERE id = :id")
    suspend fun markActivated(id: Int, transactionId: Int, activatedAt: Long, eventId: Long?, confidence: Double?)

    @Query("UPDATE recurring_rule_instances SET status = 'expired', updatedAt = :updatedAt WHERE status = 'pending' AND periodKey < :currentPeriodKey")
    suspend fun expirePastPending(currentPeriodKey: String, updatedAt: Long)

    @Query("DELETE FROM recurring_rule_instances WHERE ruleId = :ruleId AND status = 'pending'")
    suspend fun deletePendingForRule(ruleId: Int)

    @Query("DELETE FROM recurring_rule_instances")
    suspend fun clearAll()
}
