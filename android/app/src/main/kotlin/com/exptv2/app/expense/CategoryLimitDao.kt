package com.exptv2.app.expense

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface CategoryLimitDao {
    @Query(
        """
        SELECT * FROM category_limits
        WHERE (:transactionType IS NULL OR transactionType = :transactionType)
          AND (:window IS NULL OR window = :window)
          AND (:periodKey IS NULL OR periodKey = :periodKey)
        ORDER BY targetType ASC, targetId ASC
        """,
    )
    suspend fun list(
        transactionType: String?,
        window: String?,
        periodKey: String?,
    ): List<CategoryLimitEntity>

    @Query(
        """
        SELECT * FROM category_limits
        WHERE targetType = :targetType
          AND targetId = :targetId
          AND transactionType = :transactionType
          AND window = :window
          AND periodKey = :periodKey
        LIMIT 1
        """,
    )
    suspend fun byKey(
        targetType: String,
        targetId: Int,
        transactionType: String,
        window: String,
        periodKey: String,
    ): CategoryLimitEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(limit: CategoryLimitEntity): Long
}
