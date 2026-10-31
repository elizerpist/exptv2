package com.fluvi.core.usecase

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.fluvi.core.FluviCore
import com.fluvi.core.FluviCoreFactory
import com.fluvi.core.model.CapturedPushNotification
import com.fluvi.core.model.CreateRecurrenceRuleCommand
import com.fluvi.core.model.CreatePushProfileCommand
import com.fluvi.core.model.FluviSystemIds
import com.fluvi.core.model.LedgerCategorySelection
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.LedgerOriginKind
import com.fluvi.core.model.PushFieldRole
import com.fluvi.core.model.PushFieldSpan
import com.fluvi.core.model.PushTransactionDirection
import com.fluvi.core.model.UpdatePushRuleCommand
import com.fluvi.core.model.RecurrenceAmountPolicy
import com.fluvi.core.model.RecurrenceOccurrenceStatus
import com.fluvi.core.model.RecurrenceTriggerKind
import kotlinx.coroutines.runBlocking
import java.time.Instant
import java.time.ZoneId
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class FluviPushAutomationUseCaseTest {
    private lateinit var core: FluviCore

    @Before
    fun setUp() {
        core = FluviCoreFactory.createInMemory(
            ApplicationProvider.getApplicationContext<Context>(),
        )
    }

    @After
    fun tearDown() = core.close()

    @Test
    fun contextualRuleSeparatesTransactionAmountFromBalanceAndBooksOnce() = runBlocking {
        val profile = core.automation.createProfile(
            CreatePushProfileCommand(
                packageName = "com.bank.example",
                appLabel = "Teszt Bank",
                displayName = "Teszt Bank",
                defaultDirection = PushTransactionDirection.automatic,
                monitoringRequested = true,
                notificationAccessGranted = true,
            ),
        )
        val text = "1 085 Ft összeget fizettél itt: Csepp Bu:fe'. A(z) HUF Zseb egyenlege: 71 795,87 Ft."
        val first = CapturedPushNotification(
            packageName = profile.packageName,
            appLabel = profile.appLabel,
            title = "Kártyás vásárlás",
            text = text,
            notificationKey = "sample-1",
            receivedAtUtcMs = 1_700_000_000_000L,
        )
        core.automation.capture(first)
        val sample = core.automation.inbox(profile.profileId, 10, 0).single()
        val merchantStart = text.indexOf("Csepp Bu:fe'")
        val accountStart = text.indexOf("HUF Zseb")
        val balanceStart = text.indexOf("71 795,87")
        val rule = core.automation.createRule(
            com.fluvi.core.model.CreatePushRuleCommand(
                profileId = profile.profileId,
                notificationId = sample.notificationId,
                name = "Kártyás vásárlás",
                direction = LedgerDirection.expense,
                spans = listOf(
                    PushFieldSpan(0, "1 085".length, PushFieldRole.amount),
                    PushFieldSpan(merchantStart, merchantStart + "Csepp Bu:fe'".length, PushFieldRole.merchant),
                    PushFieldSpan(accountStart, accountStart + "HUF Zseb".length, PushFieldRole.account),
                    PushFieldSpan(balanceStart, balanceStart + "71 795,87".length, PushFieldRole.balance),
                ),
            ),
        )
        val report = core.automation.backtest(rule.ruleId)
        assertTrue(report.activationReady)
        core.automation.activateRule(rule.ruleId)

        val result = core.automation.capture(first.copy(notificationKey = "sample-2", receivedAtUtcMs = first.receivedAtUtcMs + 60_000L))
        assertTrue(result is com.fluvi.core.model.FluviPushCaptureResult.Booked)
        val bookedId = (result as com.fluvi.core.model.FluviPushCaptureResult.Booked).ledgerEntryId
        val entry = core.ledger.getLedgerEntryById(bookedId)
        assertEquals(108_500L, entry.amountScaled100)
        assertEquals(LedgerOriginKind.push, entry.originKind)
        assertEquals("Csepp Bu:fe'", core.partners.getPartnerById(entry.partnerId)?.displayName)
    }

    @Test
    fun captureRejectsUnknownSourcesAndDeduplicatesAnAllowedNotification() = runBlocking {
        val profile = core.automation.createProfile(
            CreatePushProfileCommand(
                packageName = "com.allowed.bank",
                appLabel = "Engedélyezett Bank",
                displayName = "Engedélyezett Bank",
                defaultDirection = PushTransactionDirection.automatic,
                monitoringRequested = true,
                notificationAccessGranted = true,
            ),
        )
        val unapproved = core.automation.capture(
            CapturedPushNotification(
                packageName = "com.other.application",
                appLabel = "Másik alkalmazás",
                title = null,
                text = "Ez az üzenet nem kerülhet az Inboxba.",
                notificationKey = "other-1",
                receivedAtUtcMs = 1_700_000_000_000L,
            ),
        )
        assertEquals(com.fluvi.core.model.FluviPushCaptureResult.IgnoredSource, unapproved)

        val allowed = CapturedPushNotification(
            packageName = profile.packageName,
            appLabel = profile.appLabel,
            title = "Értesítés",
            text = "Minta értesítés",
            notificationKey = "allowed-1",
            receivedAtUtcMs = 1_700_000_030_000L,
        )
        assertTrue(core.automation.capture(allowed) is com.fluvi.core.model.FluviPushCaptureResult.Stored)
        assertTrue(core.automation.capture(allowed) is com.fluvi.core.model.FluviPushCaptureResult.Duplicate)
        assertEquals(1, core.automation.inbox(profile.profileId, 10, 0).size)
    }

    @Test
    fun repeatedTrialEditsKeepOneRuleAndInvalidateTheOldBacktest() = runBlocking {
        val profile = core.automation.createProfile(
            CreatePushProfileCommand(
                packageName = "com.notification.test",
                appLabel = "Notification Test",
                displayName = "Notification Test",
                defaultDirection = PushTransactionDirection.automatic,
                monitoringRequested = true,
                notificationAccessGranted = true,
            ),
        )
        val text = "Vásárlás 8 500 Ft, partner SPAR."
        core.automation.capture(
            CapturedPushNotification(
                packageName = profile.packageName,
                appLabel = profile.appLabel,
                title = "Teszt",
                text = text,
                notificationKey = "repeat-test",
                receivedAtUtcMs = 1_700_000_000_000L,
            ),
        )
        val sample = core.automation.inbox(profile.profileId, 10, 0).single()
        val created = core.automation.createRule(
            com.fluvi.core.model.CreatePushRuleCommand(
                profileId = profile.profileId,
                notificationId = sample.notificationId,
                name = "SPAR",
                direction = LedgerDirection.expense,
                spans = listOf(
                    PushFieldSpan(text.indexOf("8 500"), text.indexOf("8 500") + 5, PushFieldRole.amount),
                    PushFieldSpan(text.indexOf("SPAR"), text.indexOf("SPAR") + 4, PushFieldRole.merchant),
                ),
            ),
        )
        core.automation.backtest(created.ruleId)
        val updated = core.automation.updateRule(
            UpdatePushRuleCommand(
                ruleId = created.ruleId,
                expectedVersion = created.version,
                notificationId = sample.notificationId,
                name = "SPAR vásárlás",
                direction = LedgerDirection.expense,
                spans = listOf(
                    PushFieldSpan(text.indexOf("8 500"), text.indexOf("8 500") + 5, PushFieldRole.amount),
                    PushFieldSpan(text.indexOf("SPAR"), text.indexOf("SPAR") + 4, PushFieldRole.merchant),
                ),
            ),
        )
        assertEquals(created.ruleId, updated.ruleId)
        assertEquals(created.version + 1, updated.version)
        assertEquals(1, core.automation.rules(profile.profileId).size)
        assertTrue(runCatching { core.automation.activateRule(updated.ruleId) }.isFailure)
    }

    @Test
    fun ruleAllowsSeveralIgnoredVariableFragmentsWithoutDuplicateRegexGroups() = runBlocking {
        val profile = core.automation.createProfile(
            CreatePushProfileCommand(
                packageName = "com.variable.test",
                appLabel = "Variable Test",
                displayName = "Variable Test",
                defaultDirection = PushTransactionDirection.automatic,
                monitoringRequested = true,
                notificationAccessGranted = true,
            ),
        )
        val text = "Vásárlás 8 500 Ft, partner SPAR, egyenleg 50 000 Ft, azonosító ABC-42."
        core.automation.capture(
            CapturedPushNotification(
                packageName = profile.packageName,
                appLabel = profile.appLabel,
                title = "Teszt",
                text = text,
                notificationKey = "variables",
                receivedAtUtcMs = 1_700_000_100_000L,
            ),
        )
        val sample = core.automation.inbox(profile.profileId, 10, 0).single()
        val rule = core.automation.createRule(
            com.fluvi.core.model.CreatePushRuleCommand(
                profileId = profile.profileId,
                notificationId = sample.notificationId,
                name = "Változó részek",
                direction = LedgerDirection.expense,
                spans = listOf(
                    PushFieldSpan(text.indexOf("8 500"), text.indexOf("8 500") + 5, PushFieldRole.amount),
                    PushFieldSpan(text.indexOf("SPAR"), text.indexOf("SPAR") + 4, PushFieldRole.merchant),
                    PushFieldSpan(text.indexOf("50 000"), text.indexOf("50 000") + 6, PushFieldRole.ignore),
                    PushFieldSpan(text.indexOf("ABC-42"), text.indexOf("ABC-42") + 6, PushFieldRole.ignore),
                ),
            ),
        )
        assertTrue(core.automation.backtest(rule.ruleId).activationReady)
    }

    @Test
    fun activeParserRealizesOneMatchingGhostAndLaterPushIsOnlyEvidence() = runBlocking {
        val profile = core.automation.createProfile(
            CreatePushProfileCommand(
                packageName = "com.ghost.bank",
                appLabel = "Ghost Bank",
                displayName = "Ghost Bank",
                defaultDirection = PushTransactionDirection.automatic,
                monitoringRequested = true,
                notificationAccessGranted = true,
            ),
        )
        val text = "4 690 Ft összeget fizettél itt: Netflix. A(z) HUF Zseb egyenlege: 71 795,87 Ft."
        val receivedAt = System.currentTimeMillis()
        val trainingEvent = CapturedPushNotification(
            packageName = profile.packageName,
            appLabel = profile.appLabel,
            title = "Kártyás vásárlás",
            text = text,
            notificationKey = "ghost-training",
            receivedAtUtcMs = receivedAt,
        )
        core.automation.capture(trainingEvent)
        val sample = core.automation.inbox(profile.profileId, 10, 0).single()
        val rule = core.automation.createRule(
            com.fluvi.core.model.CreatePushRuleCommand(
                profileId = profile.profileId,
                notificationId = sample.notificationId,
                name = "Netflix terhelés",
                direction = LedgerDirection.expense,
                spans = listOf(
                    PushFieldSpan(0, "4 690".length, PushFieldRole.amount),
                    PushFieldSpan(
                        text.indexOf("Netflix"),
                        text.indexOf("Netflix") + "Netflix".length,
                        PushFieldRole.merchant,
                    ),
                    PushFieldSpan(
                        text.indexOf("HUF Zseb"),
                        text.indexOf("HUF Zseb") + "HUF Zseb".length,
                        PushFieldRole.account,
                    ),
                    PushFieldSpan(
                        text.indexOf("71 795,87"),
                        text.indexOf("71 795,87") + "71 795,87".length,
                        PushFieldRole.balance,
                    ),
                ),
            ),
        )
        assertTrue(core.automation.backtest(rule.ruleId).activationReady)
        core.automation.activateRule(rule.ruleId)
        val partnerId = core.partners.findOrCreate("Netflix", FluviSystemIds.UNCATEGORIZED_CATEGORY)
        val local = Instant.ofEpochMilli(receivedAt).atZone(ZoneId.of("Europe/Budapest"))
        val recurring = core.recurrences.create(
            CreateRecurrenceRuleCommand(
                name = "Netflix", partnerId = partnerId,
                categorySelection = LedgerCategorySelection.PartnerDefault,
                direction = LedgerDirection.expense, note = null,
                triggerKind = RecurrenceTriggerKind.push,
                amountPolicy = RecurrenceAmountPolicy.estimated,
                amountScaled100 = 449_000L,
                dayOfMonth = local.dayOfMonth,
                localTimeMinutes = local.hour * 60 + local.minute,
                startLocalEpochDay = local.toLocalDate().toEpochDay(),
                endLocalEpochDay = null,
                timezoneId = "Europe/Budapest",
                pushProfileId = profile.profileId,
                pushRuleId = rule.ruleId,
                amountToleranceScaled100 = 25_000L,
                dayWindow = 2,
            ),
        )
        val booked = core.automation.capture(
            trainingEvent.copy(notificationKey = "ghost-realize", receivedAtUtcMs = receivedAt + 60_000L),
        ) as com.fluvi.core.model.FluviPushCaptureResult.Booked
        val entry = core.ledger.getLedgerEntryById(booked.ledgerEntryId)
        assertEquals(469_000L, entry.amountScaled100)
        assertEquals(LedgerOriginKind.push, entry.originKind)
        assertTrue(entry.recurrenceOccurrenceId != null)
        assertEquals(
            RecurrenceOccurrenceStatus.realized,
            core.recurrences.occurrences().single { it.ruleId == recurring.ruleId && it.occurrenceId == entry.recurrenceOccurrenceId }.status,
        )

        val evidence = core.automation.capture(
            trainingEvent.copy(notificationKey = "ghost-evidence", receivedAtUtcMs = receivedAt + 120_000L),
        ) as com.fluvi.core.model.FluviPushCaptureResult.Booked
        assertEquals(booked.ledgerEntryId, evidence.ledgerEntryId)
        assertEquals(1L, core.query.total(com.fluvi.core.query.FluviQueryScope(
            direction = LedgerDirection.expense,
        )).entryCount)
    }
}
