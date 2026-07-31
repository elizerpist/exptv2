package com.fluvi.core.usecase

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.FluviDatabaseFactory
import com.fluvi.core.database.entity.FluviLedgerEntryEntity
import com.fluvi.core.model.CategoryAssignmentMode
import com.fluvi.core.model.FluviClock
import com.fluvi.core.model.FluviIdGenerator
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.LedgerOriginKind
import com.fluvi.core.model.FluviSystemIds
import com.fluvi.core.repository.FluviCategoryRepository
import com.fluvi.core.repository.FluviLedgerRepository
import com.fluvi.core.repository.FluviPartnerRepository
import com.fluvi.core.sync.LedgerChangePublisher
import com.fluvi.core.sync.LedgerSheetProjection
import com.fluvi.core.sync.LedgerSyncOutboxRepository
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class FluviPartnerAndCategoryUseCaseTest {
    private lateinit var database: FluviDatabase
    private lateinit var categories: FluviCategoryUseCase
    private lateinit var partners: FluviPartnerUseCase
    private lateinit var ledger: FluviLedgerRepository
    private lateinit var outbox: LedgerSyncOutboxRepository
    private lateinit var idGenerator: TestIdGenerator

    private lateinit var foodId: String
    private lateinit var clothesId: String
    private lateinit var transportId: String
    private lateinit var tescoId: String

    @Before
    fun setUp() = runBlocking {
        idGenerator = TestIdGenerator()
        val context = ApplicationProvider.getApplicationContext<Context>()
        database = FluviDatabaseFactory.createInMemory(
            context = context,
            clock = FluviClock { 1_700_000_000_000L },
        )
        ledger = FluviLedgerRepository(database)
        val categoryRepository = FluviCategoryRepository(database)
        val partnerRepository = FluviPartnerRepository(database)
        val projection = LedgerSheetProjection(
            partnerRepository = partnerRepository,
            categoryRepository = categoryRepository,
        )
        outbox = LedgerSyncOutboxRepository(database, FluviClock { 1_700_000_000_000L })
        val changePublisher = LedgerChangePublisher(projection, outbox)
        categories = FluviCategoryUseCase(
            database = database,
            repository = categoryRepository,
            ledgerRepository = ledger,
            changePublisher = changePublisher,
            idGenerator = idGenerator,
            clock = FluviClock { 1_700_000_000_000L },
        )
        partners = FluviPartnerUseCase(
            database = database,
            repository = partnerRepository,
            categoryRepository = categoryRepository,
            ledgerRepository = ledger,
            changePublisher = changePublisher,
            idGenerator = idGenerator,
            clock = FluviClock { 1_700_000_000_000L },
        )

        foodId = categories.create("Food", "color_02", "icon_02")
        clothesId = categories.create("Clothes", "color_03", "icon_03")
        transportId = categories.create("Transport", "color_04", "icon_04")
        tescoId = partners.findOrCreate("Tesco", foodId)
    }

    @After
    fun tearDown() {
        database.close()
    }

    @Test
    fun changingPartnerDefaultChangesOnlyInheritedLedgerEntries() = runBlocking {
        val inheritedId = insertEntry(
            categoryId = foodId,
            mode = CategoryAssignmentMode.partnerDefault,
        )
        val overrideId = insertEntry(
            categoryId = clothesId,
            mode = CategoryAssignmentMode.entryOverride,
        )

        partners.changeDefaultCategory(tescoId, transportId)

        assertEquals(transportId, database.ledgerDao().findById(inheritedId)?.categoryId)
        assertEquals(clothesId, database.ledgerDao().findById(overrideId)?.categoryId)
        assertEquals(transportId, database.partnerDao().findById(tescoId)?.defaultCategoryId)
        assertEquals(1, outbox.pendingFor(inheritedId).size)
        assertTrue(outbox.pendingFor(inheritedId).single().payloadJson.contains(transportId))
    }

    @Test
    fun deletingCategoryRetargetsReferencesAndPreservesOverrideMode() = runBlocking {
        val overriddenId = insertEntry(
            categoryId = foodId,
            mode = CategoryAssignmentMode.entryOverride,
        )

        categories.delete(foodId)

        val updated = requireNotNull(database.ledgerDao().findById(overriddenId))
        assertEquals(FluviSystemIds.UNCATEGORIZED_CATEGORY, updated.categoryId)
        assertEquals(CategoryAssignmentMode.entryOverride, updated.categoryAssignmentMode)
        assertEquals(
            FluviSystemIds.UNCATEGORIZED_CATEGORY,
            database.partnerDao().findById(tescoId)?.defaultCategoryId,
        )
    }

    @Test
    fun changingCategoryMetadataRepublishesAffectedLedgerProjection() = runBlocking {
        val entryId = insertEntry(
            categoryId = foodId,
            mode = CategoryAssignmentMode.partnerDefault,
        )

        categories.update(
            categoryId = foodId,
            name = "Groceries",
            colorId = "color_05",
            iconId = "icon_05",
        )

        assertTrue(
            outbox.pendingFor(entryId).single().payloadJson.contains("Groceries"),
        )
    }

    @Test
    fun aliasNormalizationFindsTheSamePartnerAndMergeRemainsReversible() = runBlocking {
        val sameTesco = partners.findOrCreate("  tesco   ", clothesId)
        val sparId = partners.findOrCreate("Spar", clothesId)

        partners.merge(tescoId, sparId)

        assertEquals(sparId, partners.resolveCanonicalPartnerId(tescoId))
        assertEquals(sparId, partners.findOrCreate("TESCO", foodId))

        partners.unmerge(tescoId)

        assertEquals(tescoId, partners.resolveCanonicalPartnerId(tescoId))
        assertNotEquals(sparId, partners.findOrCreate("Tesco", foodId))
    }

    @Test
    fun renamingOrMergingAPartnerRepublishesAffectedLedgerProjection() = runBlocking {
        val entryId = insertEntry(
            categoryId = foodId,
            mode = CategoryAssignmentMode.partnerDefault,
        )

        partners.setDisplayNameOverride(tescoId, "Tesco Hypermarket")

        assertTrue(
            outbox.pendingFor(entryId).single().payloadJson.contains("Tesco Hypermarket"),
        )

        val sparId = partners.findOrCreate("Spar", clothesId)
        partners.merge(tescoId, sparId)

        val pending = outbox.pendingFor(entryId).single()
        assertEquals("upsert", pending.operation.name)
        assertTrue(pending.payloadJson.contains("Spar"))
    }

    @Test
    fun canonicalPartnerDefaultAlsoRetargetsInheritedRowsKeptUnderMergedIdentities() = runBlocking {
        val inheritedId = insertEntry(
            categoryId = foodId,
            mode = CategoryAssignmentMode.partnerDefault,
        )
        val sparId = partners.findOrCreate("Spar", clothesId)

        partners.merge(tescoId, sparId)
        partners.changeDefaultCategory(sparId, transportId)

        assertEquals(transportId, database.ledgerDao().findById(inheritedId)?.categoryId)
        assertTrue(outbox.pendingFor(inheritedId).single().payloadJson.contains(transportId))
    }

    @Test
    fun systemUncategorizedCategoryCannotBeDeleted() {
        assertThrows(IllegalArgumentException::class.java) {
            runBlocking {
                categories.delete(FluviSystemIds.UNCATEGORIZED_CATEGORY)
            }
        }
    }

    private suspend fun insertEntry(
        categoryId: String,
        mode: CategoryAssignmentMode,
    ): String {
        val id = idGenerator.next()
        database.ledgerDao().insert(
            FluviLedgerEntryEntity(
                id = id,
                partnerId = tescoId,
                categoryId = categoryId,
                categoryAssignmentMode = mode,
                note = null,
                direction = LedgerDirection.expense,
                amountScaled100 = 1_000L,
                bookedLocalEpochDay = 20_000L,
                bookedLocalTimeMinutes = 600,
                occurredAtUtcMs = 1_700_000_000_000L,
                originKind = LedgerOriginKind.manual,
                notificationInboxId = null,
                createdAtUtcMs = 1_700_000_000_000L,
                updatedAtUtcMs = 1_700_000_000_000L,
                revision = 1L,
            ),
        )
        return id
    }

    private class TestIdGenerator : FluviIdGenerator {
        private var nextValue = 10L

        override fun next(): String = nextValue++.toString().padStart(26, '0')
    }
}
