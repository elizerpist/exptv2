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
import com.fluvi.core.repository.FluviCoreRevisionRepository
import com.fluvi.core.repository.FluviFinancialLimitRepository
import com.fluvi.core.repository.FluviPartnerRepository
import java.time.LocalDate
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
class FluviBudgetPartnerDistributionReadServiceTest {
    private lateinit var database: FluviDatabase
    private lateinit var budget: FluviBudgetReadService
    private lateinit var revisions: FluviCoreRevisionRepository

    @Before
    fun setUp() = runBlocking {
        val context = ApplicationProvider.getApplicationContext<Context>()
        database = FluviDatabaseFactory.createInMemory(context, FluviClock { NOW })
        for (category in listOf(
            category(FOOD, "Food"),
            category(HOUSING, "Housing"),
            category(SALARY, "Salary"),
        )) {
            database.categoryDao().insert(category)
        }
        for (partner in listOf(
            partner(SHOP, "Bolt", FOOD, override = "Bolt partner"),
            partner(RENT, "Rent", HOUSING),
            partner(EMPLOYER, "Employer", SALARY),
        )) {
            database.partnerDao().insert(partner)
        }
        database.ledgerDao().insertAll(
            listOf(
                entry(1, LedgerDirection.expense, SHOP, FOOD, LocalDate.of(2026, 1, 10), 300),
                entry(2, LedgerDirection.expense, SHOP, HOUSING, LocalDate.of(2026, 1, 11), 300),
                entry(3, LedgerDirection.expense, RENT, HOUSING, LocalDate.of(2026, 2, 1), 500),
                entry(4, LedgerDirection.income, EMPLOYER, SALARY, LocalDate.of(2026, 1, 5), 1_000),
            ),
        )
        revisions = FluviCoreRevisionRepository(database)
        revisions.advance(NOW)
        budget = FluviBudgetReadService(
            database = database,
            categories = FluviCategoryRepository(database),
            financialLimits = FluviFinancialLimitRepository(database),
            partners = FluviPartnerRepository(database),
        )
    }

    @After
    fun tearDown() = database.close()

    @Test
    fun preparesBothDirectionsAndEveryPeriodWithOneBoundedGroupedScan() = runBlocking {
        val snapshot = budget.preparedPartnerDistributionSnapshot(
            expectedRevision = revisions.current(),
            yearWindow = FluviPreparedYearWindow(2026, 2026),
        )

        assertEquals(4, snapshot.sqlCallCount)
        assertEquals(listOf(EMPLOYER), snapshot.incomeBank.orderedPartnerIds)
        assertEquals(listOf(RENT, SHOP), snapshot.expenseBank.orderedPartnerIds)
        assertEquals("Bolt partner", snapshot.expenseBank.orderedPartnerTitles[1])
        val januarySlice = 2
        val shopJanuary = snapshot.expenseBank.cells[januarySlice * 2 + 1]
        assertEquals(600L, shopJanuary.actualScaled100)
        assertEquals(
            "equal category contribution resolves by stable category ID",
            FOOD,
            shopJanuary.dominantCategoryId,
        )
        assertEquals(
            "SUM remains independent of a current Query/month selection",
            1_100L,
            snapshot.expenseBank.cells[1].actualScaled100 +
                snapshot.expenseBank.cells[0].actualScaled100,
        )
        val yearSlice = 1
        assertEquals(600L, snapshot.expenseBank.cells[yearSlice * 2 + 1].actualScaled100)
        assertEquals(500L, snapshot.expenseBank.cells[yearSlice * 2].actualScaled100)
    }

    private fun category(id: String, name: String) = FluviCategoryEntity(
        id = id,
        name = name,
        colorId = "color_02",
        iconId = "icon_02",
        isSystemUncategorized = false,
        createdAtUtcMs = NOW,
        updatedAtUtcMs = NOW,
    )

    private fun partner(
        id: String,
        name: String,
        categoryId: String,
        override: String? = null,
    ) = FluviPartnerEntity(
        id = id,
        originalName = name,
        displayNameOverride = override,
        defaultCategoryId = categoryId,
        mergedIntoPartnerId = null,
        createdAtUtcMs = NOW,
        updatedAtUtcMs = NOW,
    )

    private fun entry(
        ordinal: Int,
        direction: LedgerDirection,
        partnerId: String,
        categoryId: String,
        date: LocalDate,
        amount: Long,
    ) = FluviLedgerEntryEntity(
        id = ordinal.toString().padStart(26, '0'),
        partnerId = partnerId,
        categoryId = categoryId,
        categoryAssignmentMode = CategoryAssignmentMode.partnerDefault,
        note = null,
        direction = direction,
        amountScaled100 = amount,
        bookedLocalEpochDay = date.toEpochDay(),
        bookedLocalTimeMinutes = 600 + ordinal,
        occurredAtUtcMs = NOW + ordinal,
        originKind = LedgerOriginKind.manual,
        notificationInboxId = null,
        createdAtUtcMs = NOW,
        updatedAtUtcMs = NOW,
        revision = 1L,
    )

    private companion object {
        const val NOW = 1_700_000_000_000L
        const val FOOD = "00000000000000000000000010"
        const val HOUSING = "00000000000000000000000011"
        const val SALARY = "00000000000000000000000012"
        const val SHOP = "00000000000000000000000020"
        const val RENT = "00000000000000000000000021"
        const val EMPLOYER = "00000000000000000000000022"
    }
}
