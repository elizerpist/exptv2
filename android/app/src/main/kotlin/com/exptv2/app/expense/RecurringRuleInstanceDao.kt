package com.exptv2.app.expense

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

data class RecurringNotificationTransactionLink(
    val matchedNotificationEventId: Long,
    val activatedTransactionId: Int,
)

@Dao
interface RecurringRuleInstanceDao {
    @Query("SELECT * FROM recurring_rule_instances WHERE status = 'pending' ORDER BY estimatedDate DESC, id DESC")
    suspend fun pending(): List<RecurringRuleInstanceEntity>

    @Query("SELECT * FROM recurring_rule_instances WHERE status = 'pending' AND periodKey = :periodKey ORDER BY estimatedDate ASC, id ASC")
    suspend fun pendingForPeriod(periodKey: String): List<RecurringRuleInstanceEntity>

    @Query("SELECT * FROM recurring_rule_instances WHERE status = 'pending' AND triggerTypeSnapshot = 'date' AND estimatedDate <= :date ORDER BY estimatedDate ASC, id ASC")
    suspend fun dueDateTriggered(date: String): List<RecurringRuleInstanceEntity>

    @Query("SELECT * FROM recurring_rule_instances WHERE status = 'pending' AND triggerTypeSnapshot = 'date' AND estimatedDate >= :date ORDER BY estimatedDate ASC, id ASC LIMIT 1")
    suspend fun nextDateTriggeredAtOrAfter(date: String): RecurringRuleInstanceEntity?

    @Query("SELECT * FROM recurring_rule_instances WHERE ruleId = :ruleId AND periodKey = :periodKey LIMIT 1")
    suspend fun byRuleAndPeriod(ruleId: Int, periodKey: String): RecurringRuleInstanceEntity?

    @Query("SELECT COUNT(*) FROM recurring_rule_instances WHERE matchedNotificationEventId = :eventId AND status = 'activated'")
    suspend fun activatedCountForNotificationEvent(eventId: Long): Int

    @Query(
        """
        SELECT matchedNotificationEventId, activatedTransactionId
        FROM recurring_rule_instances
        WHERE status = 'activated'
          AND matchedNotificationEventId IN (:eventIds)
          AND activatedTransactionId IS NOT NULL
        """
    )
    suspend fun activatedTransactionLinksForNotificationEvents(
        eventIds: List<Long>,
    ): List<RecurringNotificationTransactionLink>

    @Query(
        """
        SELECT matchedNotificationEventId
        FROM recurring_rule_instances
        WHERE status = 'activated'
          AND activatedTransactionId = :transactionId
          AND matchedNotificationEventId IS NOT NULL
        ORDER BY activatedAt DESC, id DESC
        LIMIT 1
        """
    )
    suspend fun notificationEventIdForActivatedTransaction(transactionId: Int): Long?

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

    @Query("UPDATE recurring_rule_instances SET categoryNameSnapshot = :categoryName, categoryColorSnapshot = :categoryColor, categoryIconSlotSnapshot = :categoryIconSlot, updatedAt = :updatedAt WHERE categoryIdSnapshot = :categoryId AND status = 'pending'")
    suspend fun updatePendingCategorySnapshot(categoryId: Int, categoryName: String, categoryColor: String, categoryIconSlot: Int, updatedAt: Long)

    @Query("DELETE FROM recurring_rule_instances")
    suspend fun clearAll()
}
