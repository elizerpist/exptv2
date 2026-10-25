package com.fluvi.core.usecase

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.fluvi.core.FluviCore
import com.fluvi.core.FluviCoreFactory
import com.fluvi.core.model.CapturedPushNotification
import com.fluvi.core.model.CreatePushProfileCommand
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.model.LedgerOriginKind
import com.fluvi.core.model.PushFieldRole
import com.fluvi.core.model.PushFieldSpan
import com.fluvi.core.model.PushTransactionDirection
import kotlinx.coroutines.runBlocking
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
}
