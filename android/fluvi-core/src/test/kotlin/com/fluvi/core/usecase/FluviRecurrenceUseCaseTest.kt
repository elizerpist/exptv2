package com.fluvi.core.usecase

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.fluvi.core.FluviCore
import com.fluvi.core.FluviCoreFactory
import com.fluvi.core.model.CreateRecurrenceRuleCommand
import com.fluvi.core.model.FluviSystemIds
import com.fluvi.core.model.LedgerCategorySelection
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.LedgerOriginKind
import com.fluvi.core.model.RecurrenceAmountPolicy
import com.fluvi.core.model.RecurrenceOccurrenceStatus
import com.fluvi.core.model.RecurrenceTriggerKind
import com.fluvi.core.model.UpdateOccurrenceOverrideCommand
import com.fluvi.core.query.FluviPeriodGroup
import com.fluvi.core.query.FluviPeriodSelection
import com.fluvi.core.query.FluviQueryScope
import kotlinx.coroutines.runBlocking
import java.time.Instant
import java.time.ZoneId
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class FluviRecurrenceUseCaseTest {
    private lateinit var core: FluviCore
    @Before fun setUp() { core = FluviCoreFactory.createInMemory(ApplicationProvider.getApplicationContext<Context>()) }
    @After fun tearDown() = core.close()

    @Test
    fun createsOneMonthlyGhostThenRealizesItExactlyOnceWithoutChangingGhostPreference() = runBlocking {
        val partner = core.partners.findOrCreate("Netflix", FluviSystemIds.UNCATEGORIZED_CATEGORY)
        val rule = core.recurrences.create(CreateRecurrenceRuleCommand(
            name = "Netflix", partnerId = partner, categorySelection = LedgerCategorySelection.PartnerDefault,
            direction = LedgerDirection.expense, note = null, triggerKind = RecurrenceTriggerKind.time,
            amountPolicy = RecurrenceAmountPolicy.fixed, amountScaled100 = 449_000L,
            dayOfMonth = 15, localTimeMinutes = 8 * 60, startLocalEpochDay = 0L,
            endLocalEpochDay = null, timezoneId = "Europe/Budapest",
        ))
        val ghosts = core.recurrences.occurrences(limit = 24)
        assertEquals(12, ghosts.size)
        assertEquals(12, ghosts.map { it.occurrenceKey }.distinct().size)
        assertTrue(ghosts.all { it.status == RecurrenceOccurrenceStatus.pending })
        assertEquals(0L, core.query.total(com.fluvi.core.query.FluviQueryScope(direction = LedgerDirection.expense)).amountScaled100)
        val preview = core.query.readSlice(
            com.fluvi.core.query.FluviQueryScope(direction = LedgerDirection.expense),
        )
        assertEquals(0L, preview.entryCount)
        assertEquals(12L, preview.presentationEntryCount)
        assertTrue(preview.entries.all { it.isPendingGhost })
        val firstGhostDay = java.time.LocalDate.ofEpochDay(ghosts.first().expectedLocalEpochDay)
        val dayScopedPreview = core.query.readSlice(
            FluviQueryScope(
                direction = LedgerDirection.expense,
                periodGroups = listOf(
                    FluviPeriodGroup(
                        key = "selected-day",
                        selections = setOf(FluviPeriodSelection.day(firstGhostDay.toString())),
                    ),
                ),
            ),
        )
        assertEquals(1L, dayScopedPreview.presentationEntryCount)
        assertTrue(dayScopedPreview.entries.single().isPendingGhost)

        val realized = core.recurrences.realizeDueTimeOccurrences(Long.MAX_VALUE)
        assertEquals(12, realized.size)
        val entry = core.ledger.getLedgerEntryById(realized.first())
        assertEquals(LedgerOriginKind.recurring, entry.originKind)
        assertNotNull(entry.recurrenceOccurrenceId)
        assertEquals(
            entry.entryId,
            core.recurrences.realizedLedgerEntryId(requireNotNull(entry.recurrenceOccurrenceId)),
        )
        assertTrue(core.recurrences.realizeDueTimeOccurrences(Long.MAX_VALUE).isEmpty())

        core.recurrences.setShowPendingGhostsInLedger(false)
        assertFalse(core.recurrences.dashboard().showPendingGhostsInLedger)
        assertEquals(rule.ruleId, core.recurrences.rules().single().ruleId)
    }

    @Test
    fun pendingOccurrenceOverrideCanChangePartnerAndClearItsNoteWithoutChangingTheRule() = runBlocking {
        val originalPartner = core.partners.findOrCreate("Netflix", FluviSystemIds.UNCATEGORIZED_CATEGORY)
        val replacementPartner = core.partners.findOrCreate("Netflix családi", FluviSystemIds.UNCATEGORIZED_CATEGORY)
        val rule = core.recurrences.create(CreateRecurrenceRuleCommand(
            name = "Netflix", partnerId = originalPartner,
            categorySelection = LedgerCategorySelection.PartnerDefault,
            direction = LedgerDirection.expense, note = "eredeti megjegyzés",
            triggerKind = RecurrenceTriggerKind.time, amountPolicy = RecurrenceAmountPolicy.fixed,
            amountScaled100 = 449_000L, dayOfMonth = 15, localTimeMinutes = 8 * 60,
            startLocalEpochDay = 0L, endLocalEpochDay = null, timezoneId = "Europe/Budapest",
        ))
        val pending = core.recurrences.occurrences(limit = 1).single()

        val updated = core.recurrences.updateOccurrence(UpdateOccurrenceOverrideCommand(
            occurrenceId = pending.occurrenceId,
            partnerId = replacementPartner,
            categorySelection = LedgerCategorySelection.PartnerDefault,
            noteChanged = true,
            note = null,
        ))

        assertEquals(replacementPartner, updated.partnerId)
        assertNull(updated.note)
        assertEquals(originalPartner, core.recurrences.rules().single { it.ruleId == rule.ruleId }.partnerId)
    }

    @Test
    fun archivePreservesHistoryButCancelsOpenGhostsAndStopsFutureGeneration() = runBlocking {
        val partner = core.partners.findOrCreate("Archivált előfizetés", FluviSystemIds.UNCATEGORIZED_CATEGORY)
        val rule = core.recurrences.create(CreateRecurrenceRuleCommand(
            name = "Archivált előfizetés", partnerId = partner,
            categorySelection = LedgerCategorySelection.PartnerDefault,
            direction = LedgerDirection.expense, note = null,
            triggerKind = RecurrenceTriggerKind.time, amountPolicy = RecurrenceAmountPolicy.fixed,
            amountScaled100 = 1_000L, dayOfMonth = 1, localTimeMinutes = 0,
            startLocalEpochDay = 0L, endLocalEpochDay = null, timezoneId = "Europe/Budapest",
        ))

        core.recurrences.archiveRule(rule.ruleId)

        assertTrue(core.recurrences.rules().isEmpty())
        assertEquals(
            setOf(RecurrenceOccurrenceStatus.cancelled),
            core.recurrences.occurrences(limit = 24).map { it.status }.toSet(),
        )
        assertTrue(core.recurrences.realizeDueTimeOccurrences(Long.MAX_VALUE).isEmpty())
        try {
            core.recurrences.setRuleActive(rule.ruleId, true)
            throw AssertionError("An archived rule must not be reactivated.")
        } catch (_: IllegalArgumentException) {
            // Expected: archiving is irreversible through the normal toggle.
        }
    }

    @Test
    fun laterPushCanBecomeEvidenceForTimeRealizedGhostAndAmountConflictStaysVisible() = runBlocking {
        val partner = core.partners.findOrCreate("Lakbér", FluviSystemIds.UNCATEGORIZED_CATEGORY)
        val instant = System.currentTimeMillis()
        val local = Instant.ofEpochMilli(instant).atZone(ZoneId.of("Europe/Budapest"))
        core.recurrences.create(CreateRecurrenceRuleCommand(
            name = "Lakbér", partnerId = partner,
            categorySelection = LedgerCategorySelection.PartnerDefault,
            direction = LedgerDirection.expense, note = null,
            triggerKind = RecurrenceTriggerKind.time, amountPolicy = RecurrenceAmountPolicy.fixed,
            amountScaled100 = 18_000_000L, dayOfMonth = local.dayOfMonth,
            localTimeMinutes = local.hour * 60 + local.minute,
            startLocalEpochDay = local.toLocalDate().toEpochDay(), endLocalEpochDay = null,
            timezoneId = "Europe/Budapest",
        ))
        core.recurrences.realizeDueTimeOccurrences(Long.MAX_VALUE)

        val matching = core.recurrences.realizedTimeEvidence(
            merchantName = "Lakbér", direction = LedgerDirection.expense,
            amountScaled100 = 18_000_000L, receivedAtUtcMs = instant,
        )
        assertEquals(1, matching.size)
        assertTrue(matching.single().amountMatchesExpected)
        val conflicting = core.recurrences.realizedTimeEvidence(
            merchantName = "Lakbér", direction = LedgerDirection.expense,
            amountScaled100 = 18_100_000L, receivedAtUtcMs = instant,
        )
        assertEquals(1, conflicting.size)
        assertFalse(conflicting.single().amountMatchesExpected)
    }
}
