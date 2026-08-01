package com.fluvi.core.usecase

import androidx.room.withTransaction
import com.fluvi.core.catalog.FluviCategoryCatalog
import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.entity.FluviCategoryEntity
import com.fluvi.core.model.FluviClock
import com.fluvi.core.model.FluviCategory
import com.fluvi.core.model.FluviIdGenerator
import com.fluvi.core.repository.FluviCategoryRepository
import com.fluvi.core.repository.FluviCoreRevisionRepository
import com.fluvi.core.repository.FluviLedgerRepository
import com.fluvi.core.sync.LedgerChangePublisher

class FluviCategoryUseCase internal constructor(
    private val database: FluviDatabase,
    private val repository: FluviCategoryRepository,
    private val ledgerRepository: FluviLedgerRepository,
    private val changePublisher: LedgerChangePublisher,
    private val idGenerator: FluviIdGenerator,
    private val clock: FluviClock,
    private val revisionRepository: FluviCoreRevisionRepository = FluviCoreRevisionRepository(database),
) {
    suspend fun list(): List<FluviCategory> = repository.all()

    suspend fun getById(categoryId: String): FluviCategory? = repository.findById(categoryId)

    suspend fun create(
        name: String,
        colorId: String,
        iconId: String,
    ): String = database.withTransaction {
        val cleanedName = name.trim()
        require(cleanedName.isNotEmpty()) { "Category name must not be blank." }
        repository.requireNameAvailable(cleanedName)
        require(colorId in FluviCategoryCatalog.colorIds) {
            "Unknown Fluvi category color ID: " + colorId
        }
        require(iconId in FluviCategoryCatalog.iconIds) {
            "Unknown Fluvi category icon ID: " + iconId
        }

        val now = clock.nowUtcMs()
        val id = idGenerator.next()
        repository.insert(
            FluviCategoryEntity(
                id = id,
                name = cleanedName,
                colorId = colorId,
                iconId = iconId,
                isSystemUncategorized = false,
                createdAtUtcMs = now,
                updatedAtUtcMs = now,
            ),
        )
        revisionRepository.advance(now)
        id
    }

    suspend fun delete(categoryId: String) {
        database.withTransaction {
            val category = repository.requireById(categoryId)
            require(!category.isSystemUncategorized) {
                "The system Uncategorized category cannot be deleted."
            }
            val fallback = repository.requireSystemUncategorized()
            require(fallback.id != category.id) {
                "A category cannot be redirected to itself."
            }

            val now = clock.nowUtcMs()
            val changedEntries = ledgerRepository.retargetCategory(
                fromCategoryId = category.id,
                toCategoryId = fallback.id,
                updatedAtUtcMs = now,
            )
            repository.retargetReferencesBeforeDelete(
                fromCategoryId = category.id,
                toCategoryId = fallback.id,
                updatedAtUtcMs = now,
            )
            changePublisher.publishUpserts(changedEntries)
            repository.delete(category.id)
            revisionRepository.advance(now)
        }
    }

    suspend fun update(
        categoryId: String,
        name: String,
        colorId: String,
        iconId: String,
    ) {
        database.withTransaction {
            val category = repository.requireById(categoryId)
            require(!category.isSystemUncategorized) {
                "The system Uncategorized category cannot be edited."
            }
            val cleanedName = name.trim()
            require(cleanedName.isNotEmpty()) { "Category name must not be blank." }
            repository.requireNameAvailable(cleanedName, excludingCategoryId = category.id)
            require(colorId in FluviCategoryCatalog.colorIds) {
                "Unknown Fluvi category color ID: " + colorId
            }
            require(iconId in FluviCategoryCatalog.iconIds) {
                "Unknown Fluvi category icon ID: " + iconId
            }
            val now = clock.nowUtcMs()
            repository.update(
                categoryId = category.id,
                name = cleanedName,
                colorId = colorId,
                iconId = iconId,
                updatedAtUtcMs = now,
            )
            changePublisher.publishUpserts(ledgerRepository.entriesByCategory(category.id))
            revisionRepository.advance(now)
        }
    }
}
