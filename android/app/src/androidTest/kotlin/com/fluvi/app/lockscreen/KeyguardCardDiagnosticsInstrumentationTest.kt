package com.fluvi.app.lockscreen

import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

/** Uses the real Android preference implementation because persistence and
 * capture ownership must survive an Activity/Flutter panel absence. */
@RunWith(AndroidJUnit4::class)
class KeyguardCardDiagnosticsInstrumentationTest {
    private val context get() = ApplicationProvider.getApplicationContext<android.content.Context>()

    @Before fun clearBefore() {
        KeyguardCardDiagnostics.clearCapture(context)
    }

    @After fun clearAfter() {
        KeyguardCardDiagnostics.clearCapture(context)
    }

    @Test fun threeWakeAttemptsRemainInOneFrozenReport() {
        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
        repeat(3) { index ->
            KeyguardCardDiagnostics.beginLockAttempt(context, 7L, index + 1L, "wake")
            KeyguardCardDiagnostics.captureEvent(
                context,
                stage = "INSPECTION_QUEUED",
                reason = "wake",
                serviceSession = 7L,
                wakeEpoch = index + 1L,
                requestId = index + 1L,
            )
        }
        val frozen = KeyguardCardDiagnostics.freezeCapture(context)
        val report = frozen["report"] as String

        assertEquals("FROZEN", frozen["captureState"])
        assertEquals(3, frozen["attemptCount"])
        assertTrue(report.contains("attemptId=1"))
        assertTrue(report.contains("attemptId=2"))
        assertTrue(report.contains("attemptId=3"))
        assertTrue(report.contains("uptimeMs=monotonic_excludes_deep_sleep"))
        assertTrue(report.contains("elapsedMs=monotonic_includes_deep_sleep"))
    }

    @Test fun frozenSnapshotDoesNotAcceptLaterHotPathEvents() {
        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
        KeyguardCardDiagnostics.beginLockAttempt(context, 1L, 1L, "wake")
        val before = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        KeyguardCardDiagnostics.captureEvent(
            context,
            stage = "ADD_VIEW_BEGIN",
            reason = "late",
            serviceSession = 1L,
            wakeEpoch = 1L,
        )
        val after = KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String

        assertEquals(before, after)
        assertTrue(after.contains("captureState=FROZEN"))
    }

    @Test fun attachAndHideTimingsKeepTheirOriginalOperations() {
        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
        val attempt = checkNotNull(
            KeyguardCardDiagnostics.beginLockAttempt(
                context, session = 3L, wakeEpoch = 9L, source = "wake", receivedAtUptimeMs = 0L,
            ),
        )
        KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_QUEUED", "wake", requestId = 44L, observedUptimeMs = 10L, diagnosticContext = attempt)
        KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_STARTED", "wake", requestId = 44L, observedUptimeMs = 20L, diagnosticContext = attempt)
        KeyguardCardDiagnostics.captureEvent(
            context, "INSPECTION_FINISHED", "mainKeyguard", requestId = 44L, observedUptimeMs = 90L,
            diagnosticContext = attempt, fields = mapOf("windowsReadMs" to 30, "treeScanMs" to 40),
        )
        KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_MAIN_APPLY_STARTED", "wake", requestId = 44L, observedUptimeMs = 95L, diagnosticContext = attempt)
        val show = KeyguardCardDiagnostics.newShowOperation(attempt, 1L, 44L)
        KeyguardCardDiagnostics.captureEvent(context, "SHOW_FOR_ATTACH", "wake", requestId = 44L, observedUptimeMs = 100L, diagnosticContext = attempt, operation = show)
        KeyguardCardDiagnostics.captureEvent(context, "ADD_VIEW_BEGIN", "window", requestId = 44L, observedUptimeMs = 110L, diagnosticContext = attempt, operation = show)
        KeyguardCardDiagnostics.captureEvent(context, "ADD_VIEW_RETURN", "success", requestId = 44L, observedUptimeMs = 130L, diagnosticContext = attempt, operation = show)
        KeyguardCardDiagnostics.captureEvent(context, "FIRST_ROOT_DRAW", "observed", requestId = 44L, observedUptimeMs = 150L, diagnosticContext = attempt, operation = show)
        KeyguardCardDiagnostics.captureEvent(context, "SURFACE_RECONFIRMED", "laterInspection", requestId = 45L, observedUptimeMs = 800L, diagnosticContext = attempt)

        // An unrelated accessibility callback must not become the hide start.
        KeyguardCardDiagnostics.captureEvent(context, "ACCESSIBILITY_EVENT", "surface", observedUptimeMs = 20L, diagnosticContext = attempt)
        val hide = KeyguardCardDiagnostics.newHideOperation(attempt, 1L, 44L, 1000L)
        KeyguardCardDiagnostics.captureEvent(context, "HIDE_DECIDED", "userPresent", requestId = 44L, observedUptimeMs = 1002L, diagnosticContext = attempt, operation = hide)
        KeyguardCardDiagnostics.captureEvent(context, "LOCAL_HIDE_BEGIN", "userPresent", requestId = 44L, observedUptimeMs = 1002L, diagnosticContext = attempt, operation = hide, fields = mapOf("attachedBefore" to true))
        KeyguardCardDiagnostics.captureEvent(context, "LOCAL_HIDE_APPLIED", "invisible", requestId = 44L, observedUptimeMs = 1003L, diagnosticContext = attempt, operation = hide)
        KeyguardCardDiagnostics.captureEvent(context, "REMOVE_VIEW_BEGIN", "window", requestId = 44L, observedUptimeMs = 1004L, diagnosticContext = attempt, operation = hide)
        KeyguardCardDiagnostics.captureEvent(context, "REMOVE_VIEW_RETURN", "success", requestId = 44L, observedUptimeMs = 1005L, diagnosticContext = attempt, operation = hide)
        // A later terminal cleanup is diagnostically useful but must not
        // replace the timing of the actual attached-root withdrawal above.
        val cleanup = KeyguardCardDiagnostics.newHideOperation(attempt, 1L, 45L, 1010L)
        KeyguardCardDiagnostics.captureEvent(context, "HIDE_DECIDED", "lateCleanup", requestId = 45L, observedUptimeMs = 1012L, diagnosticContext = attempt, operation = cleanup)
        KeyguardCardDiagnostics.captureEvent(context, "LOCAL_HIDE_BEGIN", "lateCleanup", requestId = 45L, observedUptimeMs = 1013L, diagnosticContext = attempt, operation = cleanup, fields = mapOf("attachedBefore" to false))

        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertTrue(report.contains("showDecisionToAddViewBeginMs=10"))
        assertTrue(report.contains("wakeCallbackToFirstRootDrawMs=150"))
        assertTrue(report.contains("hideSignalToDecisionMs=2"))
        assertTrue(report.contains("hideSignalToRemoveReturnMs=5"))
        assertTrue(report.contains("actualWithdrawalHideOp=${hide.hideOperationId}"))
        assertTrue(report.contains("terminalCleanupHideOp=${cleanup.hideOperationId}"))
        assertTrue(report.contains("triggerToLocalHideMs=3"))
        assertFalse(report.contains("showDecisionToAddViewBeginMs=-"))
    }

    @Test fun hiddenAccessibilityFloodCoalescesWithoutEvictingThreeAttempts() {
        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
        val attempts = (1L..3L).map { wake ->
            checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 8L, wake, "wake", wake * 100L))
        }
        attempts.forEachIndexed { index, attempt ->
            val request = index + 1L
            val show = KeyguardCardDiagnostics.newShowOperation(attempt, request, request)
            KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_QUEUED", "wake", requestId = request, observedUptimeMs = 100L + index, diagnosticContext = attempt)
            KeyguardCardDiagnostics.captureEvent(context, "SHOW_FOR_ATTACH", "wake", requestId = request, observedUptimeMs = 110L + index, diagnosticContext = attempt, operation = show)
            KeyguardCardDiagnostics.captureEvent(context, "ADD_VIEW_BEGIN", "window", requestId = request, observedUptimeMs = 120L + index, diagnosticContext = attempt, operation = show)
            KeyguardCardDiagnostics.captureEvent(context, "ADD_VIEW_RETURN", "success", requestId = request, observedUptimeMs = 130L + index, diagnosticContext = attempt, operation = show)
        }
        repeat(500) { index ->
            KeyguardCardDiagnostics.captureEvent(
                context,
                "ACCESSIBILITY_EVENT",
                "surface",
                observedUptimeMs = 1_000L + index,
                diagnosticContext = attempts.last(),
                fields = mapOf(
                    "eventType" to 2048,
                    "windowChanges" to 0,
                    "windowId" to 702,
                    "displayId" to 0,
                    "classification" to "unclassified",
                    "overlayState" to "hidden",
                    "eventAgeMs" to index,
                ),
            )
        }
        repeat(500) { KeyguardCardDiagnostics.recordHiddenNoop(context) }

        val frozen = KeyguardCardDiagnostics.freezeCapture(context)
        val report = frozen["report"] as String
        assertEquals(3, frozen["attemptCount"])
        assertTrue(report.contains("attemptId=1"))
        assertTrue(report.contains("attemptId=2"))
        assertTrue(report.contains("attemptId=3"))
        assertTrue(report.contains("count=500"))
        assertTrue(report.contains("hiddenNoopCount=500"))
        assertTrue((frozen["eventsCoalesced"] as Int) >= 499)
    }

    @Test fun actualWithdrawalKeepsItsTimingWhenLaterCleanupIsDetached() {
        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
        val attempt = checkNotNull(
            KeyguardCardDiagnostics.beginLockAttempt(
                context, 6L, 14L, "wake", 331_507_499L,
            ),
        )
        val withdrawal = KeyguardCardDiagnostics.newHideOperation(
            attempt, attachGeneration = 9L, causingInspectionRequestId = 150L,
            triggerReceivedUptimeMs = 331_508_793L,
        )
        KeyguardCardDiagnostics.captureEvent(context, "HIDE_DECIDED", "inspection", requestId = 150L,
            observedUptimeMs = 331_508_957L, diagnosticContext = attempt, operation = withdrawal)
        KeyguardCardDiagnostics.captureEvent(context, "LOCAL_HIDE_BEGIN", "inspection", requestId = 150L,
            observedUptimeMs = 331_508_959L, diagnosticContext = attempt, operation = withdrawal,
            fields = mapOf("attachedBefore" to true))
        KeyguardCardDiagnostics.captureEvent(context, "LOCAL_HIDE_APPLIED", "invisible", requestId = 150L,
            observedUptimeMs = 331_508_961L, diagnosticContext = attempt, operation = withdrawal)
        KeyguardCardDiagnostics.captureEvent(context, "REMOVE_VIEW_BEGIN", "window", requestId = 150L,
            observedUptimeMs = 331_508_962L, diagnosticContext = attempt, operation = withdrawal)
        KeyguardCardDiagnostics.captureEvent(context, "REMOVE_VIEW_RETURN", "success", requestId = 150L,
            observedUptimeMs = 331_508_972L, diagnosticContext = attempt, operation = withdrawal)
        val cleanup = KeyguardCardDiagnostics.newHideOperation(
            attempt, attachGeneration = 9L, causingInspectionRequestId = null,
            triggerReceivedUptimeMs = 331_509_006L,
        )
        KeyguardCardDiagnostics.captureEvent(context, "HIDE_DECIDED", "terminal", observedUptimeMs = 331_509_008L,
            diagnosticContext = attempt, operation = cleanup)
        KeyguardCardDiagnostics.captureEvent(context, "LOCAL_HIDE_BEGIN", "terminal", observedUptimeMs = 331_509_009L,
            diagnosticContext = attempt, operation = cleanup, fields = mapOf("attachedBefore" to false))

        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertTrue(report.contains("actualWithdrawalHideOp=${withdrawal.hideOperationId}"))
        assertTrue(report.contains("terminalCleanupHideOp=${cleanup.hideOperationId}"))
        assertTrue(report.contains("triggerToLocalHideMs=168"))
        assertTrue(report.contains("triggerToRemoveReturnMs=179"))
        assertTrue(report.contains("hideDecisionToLocalHideMs=4"))
        assertTrue(report.contains("removeViewCallMs=10"))
    }

    @Test fun retryAccountingRetainsFiredCancelledAndPendingTokens() {
        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
        val attempt = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 12L, 4L, "wake", 10L))
        repeat(3) { index ->
            KeyguardCardDiagnostics.captureEvent(
                context, "RETRY_SCHEDULED", "hiddenUnknown", requestId = 99L,
                observedUptimeMs = 20L + index, diagnosticContext = attempt,
                fields = mapOf("retryId" to index + 1, "retryIndex" to index + 1),
            )
        }
        KeyguardCardDiagnostics.captureEvent(context, "RETRY_FIRED", "timer", requestId = 99L, observedUptimeMs = 40L, diagnosticContext = attempt)
        KeyguardCardDiagnostics.captureEvent(context, "RETRY_CANCELLED", "shown", requestId = 99L, observedUptimeMs = 41L, diagnosticContext = attempt)

        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertTrue(report.contains("retries=scheduled:3,fired:1,cancelled:1,pending:1"))
    }

    @Test fun staleCaptureContextCannotRelabelAnEventInANewCapture() {
        KeyguardCardDiagnostics.startCapture(context, "old-sha", "debug")
        val oldAttempt = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 21L, 1L, "wake", 10L))

        KeyguardCardDiagnostics.clearCapture(context)
        KeyguardCardDiagnostics.startCapture(context, "new-sha", "debug")
        KeyguardCardDiagnostics.beginLockAttempt(context, 22L, 2L, "wake", 20L)
        KeyguardCardDiagnostics.captureEvent(
            context,
            stage = "ADD_VIEW_BEGIN",
            reason = "lateOldCapture",
            observedUptimeMs = 30L,
            diagnosticContext = oldAttempt,
        )

        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertFalse(report.contains("lateOldCapture"))
        assertTrue(report.contains("build=new-sha"))
    }

    @Test fun immutableRequestEnqueueTimeWinsWhenDiagnosticAppendArrivesLate() {
        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
        val attempt = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 40L, 1L, "wake", 0L))
        // Worker start can be recorded before a contended capture lock accepts
        // the producer's queue line. The immutable request timestamp is the
        // only valid queue boundary.
        KeyguardCardDiagnostics.captureEvent(
            context, "INSPECTION_STARTED", "wake", requestId = 7L,
            observedUptimeMs = 101L, diagnosticContext = attempt,
            fields = mapOf("authorityCurrentAtStart" to true),
        )
        KeyguardCardDiagnostics.captureEvent(
            context, "INSPECTION_QUEUED", "wake", requestId = 7L,
            observedUptimeMs = 105L, diagnosticContext = attempt,
            fields = mapOf("queuedAtUptimeMs" to 100L),
        )
        val show = KeyguardCardDiagnostics.newShowOperation(attempt, 1L, 7L)
        KeyguardCardDiagnostics.captureEvent(context, "SHOW_FOR_ATTACH", "wake", requestId = 7L, observedUptimeMs = 110L, diagnosticContext = attempt, operation = show)
        KeyguardCardDiagnostics.captureEvent(context, "ADD_VIEW_BEGIN", "window", requestId = 7L, observedUptimeMs = 111L, diagnosticContext = attempt, operation = show)
        KeyguardCardDiagnostics.captureEvent(context, "ADD_VIEW_RETURN", "window", requestId = 7L, observedUptimeMs = 112L, diagnosticContext = attempt, operation = show)

        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertTrue(report.contains("queueMs=1"))
        assertFalse(report.contains("queueMs=INVALID_EVENT_ORDER"))
    }

    @Test fun serviceColdPreparationSurvivesACaptureStartedLater() {
        KeyguardCardDiagnostics.recordColdPreparation(77L, "SERVICE_CONNECTED", 10L)
        KeyguardCardDiagnostics.recordColdPreparation(77L, "MATERIAL_SHADER_PREPARED", 20L)
        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String

        assertTrue(report.contains("COLD_PREPARATION"))
        assertTrue(report.contains("serviceSession=77"))
        assertTrue(report.contains("SERVICE_CONNECTED=10"))
        assertTrue(report.contains("MATERIAL_SHADER_PREPARED=20"))
    }
}
