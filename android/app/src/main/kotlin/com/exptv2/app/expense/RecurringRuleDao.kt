package com.exptv2.app.expense

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update

@Dao
interface RecurringRuleDao {
    @Query("SELECT * FROM recurring_rules ORDER BY expectedDayOfMonth ASC, name ASC")
    suspend fun all(): List<RecurringRuleEntity>

    @Query("SELECT * FROM recurring_rules WHERE isActive = 1 ORDER BY expectedDayOfMonth ASC, name ASC")
    suspend fun active(): List<RecurringRuleEntity>

    @Query("SELECT * FROM recurring_rules WHERE id = :id LIMIT 1")
    suspend fun byId(id: Int): RecurringRuleEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(row: RecurringRuleEntity): Long

    @Update
    suspend fun update(row: RecurringRuleEntity)

    @Delete
    suspend fun delete(row: RecurringRuleEntity)

    @Query("UPDATE recurring_rules SET categoryName = :categoryName, categoryColor = :categoryColor, categoryIconSlot = :categoryIconSlot, updatedAt = :updatedAt WHERE categoryId = :categoryId")
    suspend fun updateCategorySnapshot(categoryId: Int, categoryName: String, categoryColor: String, categoryIconSlot: Int, updatedAt: Long)

    @Query("DELETE FROM recurring_rules")
    suspend fun clearAll()
}
