package com.fluvi.core.repository

import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.entity.FluviCategoryEntity
import com.fluvi.core.model.FluviCategory
import com.fluvi.core.model.FluviCategoryNameNormalizer

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

    suspend fun deleteAll(categoryIds: List<String>) {
        if (categoryIds.isNotEmpty()) categories.deleteAll(categoryIds)
    }

    suspend fun all(): List<FluviCategory> = categories.allCategories().map(::toModel)

    suspend fun allEntities(): List<FluviCategoryEntity> = categories.allCategories()

    suspend fun findById(categoryId: String): FluviCategory? =
        categories.findById(categoryId)?.let(::toModel)

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

    suspend fun requireNameAvailable(name: String, excludingCategoryId: String? = null) {
        val normalized = FluviCategoryNameNormalizer.normalize(name)
        require(
            categories.allCategories().none { category ->
                category.id != excludingCategoryId &&
                    FluviCategoryNameNormalizer.normalize(category.name) == normalized
            },
        ) {
            "A category with the same name already exists."
        }
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

    private fun toModel(entity: FluviCategoryEntity): FluviCategory = FluviCategory(
        id = entity.id,
        name = entity.name,
        colorId = entity.colorId,
        iconId = entity.iconId,
        isSystemUncategorized = entity.isSystemUncategorized,
        createdAtUtcMs = entity.createdAtUtcMs,
        updatedAtUtcMs = entity.updatedAtUtcMs,
    )
}
