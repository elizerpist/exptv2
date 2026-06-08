package com.exptv2.app.expense

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

data class CategoryCountRow(
    val transactionCategoryID: Int,
    val count: Int,
)

@Dao
interface ExpenseTransactionDao {
    @Query("SELECT COUNT(*) FROM transactions")
    suspend fun count(): Int

    @Query("SELECT * FROM transactions ORDER BY date DESC, time DESC, id DESC")
    suspend fun all(): List<ExpenseTransactionEntity>

    @Query(
        """
        SELECT * FROM transactions
        WHERE (:type IS NULL
            OR (:type = 'income' AND amount > 0)
            OR (:type = 'expense' AND amount < 0))
          AND (:categoryId IS NULL OR transactionCategoryID = :categoryId)
          AND (:merchant = '' OR COALESCE(userAssignedName, merchant) = :merchant)
          AND (:searchQuery = '' OR COALESCE(userAssignedName, merchant) LIKE '%' || :searchQuery || '%')
          AND (:yearMonth = '' OR date LIKE :yearMonth || '%' OR REPLACE(date, '.', '-') LIKE :yearMonth || '%')
        ORDER BY date DESC, time DESC, id DESC
        LIMIT :limit OFFSET :offset
        """
    )
    suspend fun page(
        type: String?,
        categoryId: Int?,
        merchant: String,
        searchQuery: String,
        yearMonth: String,
        limit: Int,
        offset: Int,
    ): List<ExpenseTransactionEntity>

    @Query(
        """
        SELECT COUNT(*) FROM transactions
        WHERE (:type IS NULL
            OR (:type = 'income' AND amount > 0)
            OR (:type = 'expense' AND amount < 0))
          AND (:categoryId IS NULL OR transactionCategoryID = :categoryId)
          AND (:merchant = '' OR COALESCE(userAssignedName, merchant) = :merchant)
          AND (:searchQuery = '' OR COALESCE(userAssignedName, merchant) LIKE '%' || :searchQuery || '%')
          AND (:yearMonth = '' OR date LIKE :yearMonth || '%' OR REPLACE(date, '.', '-') LIKE :yearMonth || '%')
        """
    )
    suspend fun pageCount(
        type: String?,
        categoryId: Int?,
        merchant: String,
        searchQuery: String,
        yearMonth: String,
    ): Int

    @Query("SELECT * FROM transactions WHERE id = :id LIMIT 1")
    suspend fun byId(id: Int): ExpenseTransactionEntity?

    @Query("SELECT * FROM transactions WHERE id IN (:ids)")
    suspend fun byIds(ids: List<Int>): List<ExpenseTransactionEntity>

    @Query(
        """
        SELECT COALESCE(SUM(ABS(amount)), 0) FROM transactions
        WHERE amount < 0
          AND (:categoryId IS NULL OR transactionCategoryID = :categoryId)
          AND (:startDate = '' OR date >= :startDate)
          AND (:endDate = '' OR date <= :endDate)
        """,
    )
    suspend fun expenseSpentTotal(
        categoryId: Int?,
        startDate: String,
        endDate: String,
    ): Double

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(transaction: ExpenseTransactionEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(transactions: List<ExpenseTransactionEntity>)

    @Delete
    suspend fun delete(transaction: ExpenseTransactionEntity)

    @Query("UPDATE transactions SET userAssignedName = :userAssignedName WHERE TRIM(merchant) = TRIM(:originalMerchant)")
    suspend fun renameByMerchant(originalMerchant: String, userAssignedName: String): Int

    @Query("UPDATE transactions SET userAssignedName = NULL WHERE TRIM(merchant) = TRIM(:originalMerchant)")
    suspend fun resetNamesByMerchant(originalMerchant: String): Int

    @Query(
        """
        SELECT transactionCategoryID FROM transactions
        WHERE TRIM(merchant) = TRIM(:merchant)
          AND transactionCategoryID IS NOT NULL
        ORDER BY date DESC, time DESC, id DESC
        LIMIT 1
        """
    )
    suspend fun latestCategoryIdForMerchant(merchant: String): Int?

    @Query(
        """
        SELECT userAssignedName FROM transactions
        WHERE TRIM(merchant) = TRIM(:merchant)
          AND userAssignedName IS NOT NULL
          AND TRIM(userAssignedName) != ''
        ORDER BY date DESC, time DESC, id DESC
        LIMIT 1
        """
    )
    suspend fun latestUserAssignedNameForMerchant(merchant: String): String?

    @Query(
        """
        UPDATE transactions
        SET transactionCategoryID = :categoryId
        WHERE TRIM(merchant) = TRIM(:merchant)
        """
    )
    suspend fun updateCategoryByMerchant(merchant: String, categoryId: Int): Int

    @Query("SELECT MAX(id) FROM transactions WHERE CAST(id AS TEXT) LIKE :prefix || '%'")
    suspend fun maxIdForPrefix(prefix: String): Int?

    @Query("SELECT COUNT(*) FROM transactions WHERE transactionCategoryID = :categoryId")
    suspend fun countByCategory(categoryId: Int): Int

    @Query("SELECT transactionCategoryID, COUNT(*) AS count FROM transactions WHERE transactionCategoryID IS NOT NULL GROUP BY transactionCategoryID")
    suspend fun categoryCounts(): List<CategoryCountRow>

    @Query("SELECT * FROM transactions WHERE sourceNotificationEventId IN (:eventIds)")
    suspend fun bySourceNotificationEventIds(eventIds: List<Long>): List<ExpenseTransactionEntity>

    @Query("SELECT * FROM transactions WHERE sourceNotificationEventId = :eventId ORDER BY id DESC LIMIT 1")
    suspend fun bySourceNotificationEventId(eventId: Long): ExpenseTransactionEntity?

    @Query("DELETE FROM transactions")
    suspend fun clearAll()
}
