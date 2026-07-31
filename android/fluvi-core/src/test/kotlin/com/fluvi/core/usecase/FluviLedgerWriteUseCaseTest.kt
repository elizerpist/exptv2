package com.fluvi.core.usecase

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.FluviDatabaseFactory
import com.fluvi.core.model.CategoryAssignmentMode
import com.fluvi.core.model.FluviClock
import com.fluvi.core.model.FluviIdGenerator
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.LedgerOriginKind
import com.fluvi.core.model.LedgerCategorySelection
import com.fluvi.core.model.CreateLedgerEntryCommand
import com.fluvi.core.repository.FluviCategoryRepository
import com.fluvi.core.repository.FluviLedgerDeletionArchiveRepository
import com.fluvi.core.repository.FluviLedgerRepository
import com.fluvi.core.repository.FluviPartnerRepository
import com.fluvi.core.sync.LedgerChangePublisher
import com.fluvi.core.sync.LedgerCheckpointCoordinator
import com.fluvi.core.sync.LedgerSheetProjection
import com.fluvi.core.sync.LedgerSyncOutboxRepository
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class FluviLedgerWriteUseCaseTest {
    private lateinit var database: FluviDatabase
    private lateinit var categories: FluviCategoryUseCase
    private lateinit var partners: FluviPartnerUseCase
    private lateinit var ledger: FluviLedgerWriteUseCase
    private lateinit var outbox: LedgerSyncOutboxRepository
    private lateinit var checkpoints: LedgerCheckpointCoordinator
    private lateinit var idGenerator: TestIdGenerator

    private lateinit var foodId: String
    private lateinit var clothesId: String
    private lateinit var transportId: String
    private lateinit var tescoId: String

    @Before
    fun setUp() = runBlocking {
        idGenerator = TestIdGenerator()
        val clock = FluviClock { 1_700_000_000_000L }
        val context = ApplicationProvider.getApplicationContext<Context>()
        database = FluviDatabaseFactory.createInMemory(context, clock)
        val categoryRepository = FluviCategoryRepository(database)
        val partnerRepository = FluviPartnerRepository(database)
        val ledgerRepository = FluviLedgerRepository(database)
        val projection = LedgerSheetProjection(
            partnerRepository = partnerRepository,
            categoryRepository = categoryRepository,
        )
        outbox = LedgerSyncOutboxRepository(database, clock)
        val changePublisher = LedgerChangePublisher(projection, outbox)
        checkpoints = LedgerCheckpointCoordinator(database, idGenerator, clock)
        categories = FluviCategoryUseCase(
            database = database,
            repository = categoryRepository,
            ledgerRepository = ledgerRepository,
            changePublisher = changePublisher,
            idGenerator = idGenerator,
            clock = clock,
        )
        partners = FluviPartnerUseCase(
            database = database,
            repository = partnerRepository,
            categoryRepository = categoryRepository,
            ledgerRepository = ledgerRepository,
            changePublisher = changePublisher,
            idGenerator = idGenerator,
            clock = clock,
        )
        ledger = FluviLedgerWriteUseCase(
            database = database,
            ledgerRepository = ledgerRepository,
            archiveRepository = FluviLedgerDeletionArchiveRepository(database),
            partnerRepository = partnerRepository,
            categoryRepository = categoryRepository,
            changePublisher = changePublisher,
            checkpointCoordinator = checkpoints,
            idGenerator = idGenerator,
            clock = clock,
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
    fun clearingOverrideReappliesCurrentPartnerDefaultAndKeepsOneUpsert() = runBlocking {
        val entry = ledger.create(command(selection = LedgerCategorySelection.EntryOverride(clothesId)))
        partners.changeDefaultCategory(tescoId, transportId)

        ledger.clearCategoryOverride(entry.id)

        val updated = requireNotNull(database.ledgerDao().findById(entry.id))
        assertEquals(transportId, updated.categoryId)
        assertEquals(CategoryAssignmentMode.partnerDefault, updated.categoryAssignmentMode)
        assertEquals(1, outbox.pendingFor(entry.id).size)
        assertEquals("upsert", outbox.pendingFor(entry.id).single().operation.name)
    }

    @Test
    fun repeatedUnsyncedEditsCoalesceToOneFinalUpsertPayload() = runBlocking {
        val entry = ledger.create(command())

        repeat(5) { index ->
            ledger.updateAmount(entry.id, 100L + index)
        }

        val pending = outbox.pendingFor(entry.id)
        assertEquals(1, pending.size)
        assertEquals("upsert", pending.single().operation.name)
        assertTrue(pending.single().payloadJson.contains("\"amountScaled100\":104"))
    }

    @Test
    fun deleteRemovesActiveEntryStoresLastProjectionAndEnqueuesDelete() = runBlocking {
        val entry = ledger.create(command())

        ledger.delete(entry.id)

        assertNull(database.ledgerDao().findById(entry.id))
        val archive = database.ledgerDeletionArchiveDao().findByEntryId(entry.id)
        assertTrue(archive?.ledgerSheetRowPayload?.isNotEmpty() == true)
        assertTrue(archive?.requiredCheckpointId != null)
        val checkpoint = database.ledgerBackupCheckpointDao()
            .findById(requireNotNull(archive?.requiredCheckpointId))
        assertEquals(
            "beforeDestructive",
            checkpoint?.kind?.name,
        )
        assertTrue(requireNotNull(checkpoint).sourceCoreRevision > 0L)
        assertEquals("delete", outbox.pendingFor(entry.id).single().operation.name)
    }

    @Test
    fun createRejectsNonPositiveMoneyAndInvalidLocalTime() {
        assertThrows(IllegalArgumentException::class.java) {
            runBlocking {
                ledger.create(command(amountScaled100 = 0L))
            }
        }
        assertThrows(IllegalArgumentException::class.java) {
            runBlocking {
                ledger.create(command(bookedLocalTimeMinutes = 1_440))
            }
        }
    }

    private fun command(
        selection: LedgerCategorySelection = LedgerCategorySelection.PartnerDefault,
        amountScaled100: Long = 1_000L,
        bookedLocalTimeMinutes: Int = 600,
    ) = CreateLedgerEntryCommand(
        partnerId = tescoId,
        categorySelection = selection,
        note = "Core test",
        direction = LedgerDirection.expense,
        amountScaled100 = amountScaled100,
        bookedLocalEpochDay = 20_000L,
        bookedLocalTimeMinutes = bookedLocalTimeMinutes,
        occurredAtUtcMs = 1_700_000_000_000L,
        originKind = LedgerOriginKind.manual,
        notificationInboxId = null,
    )

    private class TestIdGenerator : FluviIdGenerator {
        private var nextValue = 100L

        override fun next(): String = nextValue++.toString().padStart(26, '0')
    }
}
