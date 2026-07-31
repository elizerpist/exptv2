package com.fluvi.core.repository

import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.entity.FluviCategoryEntity

internal class FluviCategoryRepository(
    private val database: FluviDatabase,
) {
    private val categories = database.categoryDao()
    private val partners = database.partnerDao()
    private val futureReferences = database.futureReferenceDao()
    private val querySnapshots = database.querySnapshotDao()

    suspend fun insert(category: FluviCategoryEntity) {
        categories.insert(category)
    }

    suspend fun requireById(categoryId: String): FluviCategoryEntity = requireNotNull(
        categories.findById(categoryId),
    ) {
        "Unknown category ID: " + categoryId
    }

    suspend fun requireSystemUncategorized(): FluviCategoryEntity = requireNotNull(
        categories.systemUncategorized(),
    ) {
        "The Fluvi system Uncategorized category is missing."
    }

    suspend fun update(
        categoryId: String,
        name: String,
        colorId: String,
        iconId: String,
        updatedAtUtcMs: Long,
    ) {
        check(
            categories.update(
                categoryId = categoryId,
                name = name,
                colorId = colorId,
                iconId = iconId,
                updatedAtUtcMs = updatedAtUtcMs,
            ) == 1,
        ) {
            "Category update did not affect exactly one row."
        }
    }

    suspend fun retargetReferencesBeforeDelete(
        fromCategoryId: String,
        toCategoryId: String,
        updatedAtUtcMs: Long,
    ) {
        partners.retargetDefaultCategories(
            fromCategoryId = fromCategoryId,
            toCategoryId = toCategoryId,
            updatedAtUtcMs = updatedAtUtcMs,
        )
        futureReferences.retargetRecurrenceCategories(
            fromCategoryId = fromCategoryId,
            toCategoryId = toCategoryId,
            updatedAtUtcMs = updatedAtUtcMs,
        )
        futureReferences.retargetOccurrenceOverrideCategories(
            fromCategoryId = fromCategoryId,
            toCategoryId = toCategoryId,
            updatedAtUtcMs = updatedAtUtcMs,
        )
        querySnapshots.removeTargetCategoryFiltersThatWouldCollide(
            sourceCategoryId = fromCategoryId,
            targetCategoryId = toCategoryId,
        )
        querySnapshots.retargetCategoryFilters(
            fromCategoryId = fromCategoryId,
            toCategoryId = toCategoryId,
        )
    }

    suspend fun delete(categoryId: String) {
        categories.delete(categoryId)
    }
}
