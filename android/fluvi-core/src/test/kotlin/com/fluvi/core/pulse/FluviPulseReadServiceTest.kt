package com.fluvi.core.pulse

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.fluvi.core.FluviCore
import com.fluvi.core.FluviCoreFactory
import com.fluvi.core.model.FluviClock
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.time.LocalDate
import java.time.ZoneId

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class FluviPulseReadServiceTest {
    private lateinit var core: FluviCore

    @Before
    fun setUp() {
        val instant = LocalDate.of(2025, 7, 15)
            .atTime(12, 0)
            .atZone(ZoneId.of("Europe/Budapest"))
            .toInstant()
            .toEpochMilli()
        core = FluviCoreFactory.createInMemory(
            ApplicationProvider.getApplicationContext<Context>(),
            FluviClock { instant },
        )
    }

    @After
    fun tearDown() = core.close()

    @Test
    fun catalogContainsTwentyOneStableIndicatorsInThreeBalancedGroups() {
        assertEquals(21, PulseIndicatorId.entries.size)
        assertEquals(21, PulseIndicatorId.entries.map { it.stableId }.toSet().size)
        PulseIndicatorGroup.entries.forEach { group ->
            assertEquals(7, PulseIndicatorId.entries.count { it.group == group })
        }
    }

    @Test
    fun dashboardUsesCoreLedgerDataAndPersistsOnlyAnExplicitThresholdOverride() = runBlocking {
        core.demoSeed.seed(financialLimitYearWindow = 2025..2025)

        val initial = core.pulse.dashboard(2025, 7)
        assertEquals(21, initial.indicators.size)
        assertTrue(initial.indicators.all { it.sources.isNotEmpty() })
        assertNotNull(initial.indicators.single { it.id == PulseIndicatorId.incomeExpenseRatio }.value)
        assertTrue(initial.indicators.single { it.id == PulseIndicatorId.monthEndForecast }.series.isNotEmpty())
        assertEquals(
            PulseAvailability.notApplicable,
            initial.indicators.single { it.id == PulseIndicatorId.reserveCoverDays }.availability,
        )

        core.pulseThresholds.set(
            indicatorId = PulseIndicatorId.spendingMomentum.stableId,
            value = 1.35,
        )
        val configured = core.pulse.dashboard(2025, 7)
        val threshold = configured.indicators.single { it.id == PulseIndicatorId.spendingMomentum }
            .thresholds.single()
        assertEquals(1.35, threshold.value, .0001)
        assertTrue(threshold.isUserDefined)
        assertTrue(configured.coreRevision > initial.coreRevision)

        core.pulseThresholds.reset(PulseIndicatorId.spendingMomentum.stableId)
        val reset = core.pulse.dashboard(2025, 7).indicators
            .single { it.id == PulseIndicatorId.spendingMomentum }.thresholds.single()
        assertEquals(PulseIndicatorId.spendingMomentum.threshold.defaultValue, reset.value, .0001)
        assertTrue(!reset.isUserDefined)
    }
}
