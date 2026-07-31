package com.fluvi.core.query

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.FluviDatabaseFactory
import com.fluvi.core.database.entity.FluviCategoryEntity
import com.fluvi.core.database.entity.FluviLedgerEntryEntity
import com.fluvi.core.database.entity.FluviPartnerEntity
import com.fluvi.core.model.CategoryAssignmentMode
import com.fluvi.core.model.FluviClock
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.LedgerOriginKind
import com.fluvi.core.repository.FluviCategoryRepository
import com.fluvi.core.repository.FluviPartnerRepository
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class FluviLedgerLargeDatasetTest {
    private lateinit var database: FluviDatabase
    private lateinit var readService: FluviLedgerReadService

    @Before
    fun setUp() = runBlocking {
        val context = ApplicationProvider.getApplicationContext<Context>()
        database = FluviDatabaseFactory.createInMemory(
            context = context,
            clock = FluviClock { 1_700_000_000_000L },
        )
        val categoryId = "00000000000000000000000010"
        val partnerId = "00000000000000000000000011"
        database.categoryDao().insert(
            FluviCategoryEntity(
                id = categoryId,
                name = "Scale",
                colorId = "color_02",
                iconId = "icon_02",
                isSystemUncategorized = false,
                createdAtUtcMs = 1_700_000_000_000L,
                updatedAtUtcMs = 1_700_000_000_000L,
            ),
        )
        database.partnerDao().insert(
            FluviPartnerEntity(
                id = partnerId,
                originalName = "Scale Partner",
                displayNameOverride = null,
                defaultCategoryId = categoryId,
                mergedIntoPartnerId = null,
                createdAtUtcMs = 1_700_000_000_000L,
                updatedAtUtcMs = 1_700_000_000_000L,
            ),
        )
        val entries = (0 until ENTRY_COUNT).map { index ->
            FluviLedgerEntryEntity(
                id = (index + 100).toString().padStart(26, '0'),
                partnerId = partnerId,
                categoryId = categoryId,
                categoryAssignmentMode = CategoryAssignmentMode.partnerDefault,
                note = null,
                direction = LedgerDirection.expense,
                amountScaled100 = 100L,
                bookedLocalEpochDay = 20_000L + (index / 1_440),
                bookedLocalTimeMinutes = index % 1_440,
                occurredAtUtcMs = 1_700_000_000_000L + index,
                originKind = LedgerOriginKind.manual,
                notificationInboxId = null,
                createdAtUtcMs = 1_700_000_000_000L,
                updatedAtUtcMs = 1_700_000_000_000L,
                revision = 1L,
            )
        }
        entries.chunked(500).forEach { chunk -> database.ledgerDao().insertAll(chunk) }
        readService = FluviLedgerReadService(
            database = database,
            partnerRepository = FluviPartnerRepository(database),
            categoryRepository = FluviCategoryRepository(database),
        )
    }

    @After
    fun tearDown() {
        database.close()
    }

    @Test
    fun fiftyThousandRowsReturnABoundedKeysetPageAndSqlTotal() = runBlocking {
        val scope = FluviQueryScope(direction = LedgerDirection.expense)

        val firstPage = readService.timeline(scope, pageSize = 75)
        val secondPage = readService.timeline(
            scope = scope,
            after = requireNotNull(firstPage.nextCursor),
            pageSize = 75,
        )
        val total = readService.total(scope)

        assertEquals(75, firstPage.entries.size)
        assertEquals(75, secondPage.entries.size)
        assertEquals(ENTRY_COUNT.toLong(), total.entryCount)
        assertEquals(ENTRY_COUNT * 100L, total.amountScaled100)
    }

    private companion object {
        const val ENTRY_COUNT = 50_000
    }
}
