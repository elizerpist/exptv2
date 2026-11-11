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

    @Test fun recoverableOcclusionKeepsItsIdentityWithoutIncrementingUnknownCounters() {
        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug", "LIGHT")
        val attempt = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 1L, 1L, "wake"))
        for ((id, decision) in listOf(35L to "HIDDEN_OCCLUDED", 37L to "HIDDEN_UNKNOWN")) {
            KeyguardCardDiagnostics.captureEvent(context, "AWAITING_MAIN_SURFACE", if (decision == "HIDDEN_OCCLUDED") "FOREIGN_ABOVE" else "NO_MAIN_MARKER",
                requestId = id, diagnosticContext = attempt, fields = mapOf(
                    "decision" to decision, "overlayAttached" to false, "followupAction" to "CONTINUE_PENDING",
                    "visibilityEpochBefore" to 5, "visibilityEpochAfter" to 5,
                ))
        }
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertTrue(report.contains("unknownWhileHidden:1"))
        assertTrue(report.contains("unknownWhileHiddenEpochChanges:0"))
        assertTrue(report.contains("pendingPreservedAfterUnknown:1"))
        assertTrue(report.contains("HIDDEN_OCCLUDED"))
    }

    @Test fun cycleFirstLiveSurvivesLaterAttachmentRemovedWithoutDrawing() {
        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
        val attempt = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(
            context, 3L, 6L, "display", receivedAtUptimeMs = 416204935L,
        ))
        fun event(stage: String, at: Long, operation: KeyguardDiagnosticOperation, fields: Map<String, Any?> = emptyMap()) {
            KeyguardCardDiagnostics.captureEvent(
                context, stage, "test", observedUptimeMs = at,
                diagnosticContext = attempt, operation = operation, fields = fields,
            )
        }
        val first = KeyguardCardDiagnostics.newShowOperation(attempt, 6L, 60L)
        event("SHOW_FOR_ATTACH", 416205200L, first)
        event("ADD_VIEW_BEGIN", 416205210L, first)
        event("ADD_VIEW_RETURN", 416205220L, first)
        event("FIRST_ROOT_DRAW", 416205240L, first)
        event("FIRST_SHADER_DRAW", 416205244L, first)
        event("FIRST_LIVE_DRAW", 416205244L, first)
        val firstHide = KeyguardCardDiagnostics.newHideOperation(attempt, 6L, 61L, 416205300L)
        event("HIDE_DECIDED", 416205310L, firstHide)
        event("LOCAL_HIDE_BEGIN", 416205311L, firstHide, mapOf("attachedBefore" to true))
        event("LOCAL_HIDE_APPLIED", 416205312L, firstHide)
        event("REMOVE_VIEW_RETURN", 416205320L, firstHide)
        val second = KeyguardCardDiagnostics.newShowOperation(attempt, 7L, 62L)
        event("SHOW_FOR_ATTACH", 416205400L, second)
        event("ADD_VIEW_BEGIN", 416205410L, second)
        event("ADD_VIEW_RETURN", 416205420L, second)
        val secondHide = KeyguardCardDiagnostics.newHideOperation(attempt, 7L, 63L, 416205421L)
        event("HIDE_DECIDED", 416205422L, secondHide)
        event("LOCAL_HIDE_BEGIN", 416205423L, secondHide, mapOf("attachedBefore" to true))
        event("LOCAL_HIDE_APPLIED", 416205424L, secondHide)
        event("REMOVE_VIEW_RETURN", 416205430L, secondHide)

        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertTrue(report.contains("cycleToFirstLiveDrawMs=309"))
        assertTrue(report.contains("cycleToFirstShaderDrawMs=309"))
        assertTrue(report.contains("firstRootDrawObserved=true"))
        assertTrue(report.contains("actualWithdrawalHideOp=${firstHide.hideOperationId}"))
        val episodes = report.lineSequence().filter { it.startsWith(" EPISODE ") }.toList()
        assertEquals(2, episodes.size)
        assertTrue(episodes[0].contains("attach=6"))
        assertTrue(episodes[0].contains("live=416205244"))
        assertTrue(episodes[0].contains("withdrawal=${firstHide.hideOperationId}"))
        assertTrue(episodes[1].contains("attach=7"))
        assertTrue(episodes[1].contains("live=NO_DRAW_OBSERVED"))
        assertTrue(episodes[1].contains("withdrawal=${secondHide.hideOperationId}"))
        assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32 * 1024)
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
        KeyguardCardDiagnostics.captureEvent(context, "FIRST_ROOT_DRAW", "duplicate", requestId = 44L, observedUptimeMs = 700L, diagnosticContext = attempt, operation = show)
        KeyguardCardDiagnostics.captureEvent(context, "BOOTSTRAP_DRAW", "observed", observedUptimeMs = 151L, diagnosticContext = attempt, operation = show)
        KeyguardCardDiagnostics.captureEvent(context, "BOOTSTRAP_DRAW", "duplicate", observedUptimeMs = 701L, diagnosticContext = attempt, operation = show)
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
        assertTrue(report.contains("bootstrapDrawAt=151"))
        assertTrue(report.contains("hideSignalToDecisionMs=2"))
        assertTrue(report.contains("hideSignalToRemoveReturnMs=5"))
        assertTrue(report.contains("actualWithdrawalHideOp=${hide.hideOperationId}"))
        assertTrue(report.contains("terminalCleanupHideOp=${cleanup.hideOperationId}"))
        assertTrue(report.contains("FIRST_INSPECTION req=44"))
        assertTrue(report.contains("SHOWING_INSPECTION req=44"))
        assertTrue(report.contains("ACTUAL_WITHDRAWAL_INSPECTION req=44"))
        assertTrue(report.contains("triggerToLocalHideMs=3"))
        assertFalse(report.contains("showDecisionToAddViewBeginMs=-"))
    }

    @Test fun hiddenAccessibilityFloodCoalescesWithoutEvictingThreeAttempts() {
        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug", "FULL")
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
        assertTrue(report.contains("hiddenNoopCount=500"))
        // The reducer, not an optional bounded raw-export block, owns the
        // coalescing contract. Exactly 499 joins prove that the 500 accepted
        // hidden observations formed one retained aggregate. The export may
        // legitimately omit that raw row after protected episode evidence.
        assertEquals(499, frozen["eventsCoalesced"] as Int)
        assertTrue(report.contains("diagnosticQueueOverflow=0"))
        assertTrue(report.contains("diagnosticConsumerFailures=0"))
        if (report.contains("count=500")) {
            assertTrue(report.contains("rawEventsTruncated=false"))
        } else {
            assertTrue(report.contains("rawEventsTruncated=true"))
            assertTrue(report.contains("omittedEventLines="))
        }
    }

    @Test fun boundedRawExportPressurePreservesAttemptsAndReportsItsOmissions() {
        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug", "FULL")
        val attempts = (1L..3L).map { wake ->
            checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 9L, wake, "wake", wake * 100L))
        }
        attempts.forEachIndexed { index, attempt ->
            val request = index + 1L
            val show = KeyguardCardDiagnostics.newShowOperation(attempt, request, request)
            KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_QUEUED", "wake", requestId = request,
                observedUptimeMs = 100L + index, diagnosticContext = attempt)
            KeyguardCardDiagnostics.captureEvent(context, "SHOW_FOR_ATTACH", "wake", requestId = request,
                observedUptimeMs = 110L + index, diagnosticContext = attempt, operation = show)
            KeyguardCardDiagnostics.captureEvent(context, "ADD_VIEW_BEGIN", "window", requestId = request,
                observedUptimeMs = 120L + index, diagnosticContext = attempt, operation = show)
            KeyguardCardDiagnostics.captureEvent(context, "ADD_VIEW_RETURN", "success", requestId = request,
                observedUptimeMs = 130L + index, diagnosticContext = attempt, operation = show)
        }
        // Deliberately defeat hidden-event coalescing. This exercises the
        // fixed raw ring and report budget without changing either capacity.
        repeat(700) { index ->
            KeyguardCardDiagnostics.captureEvent(
                context, "ACCESSIBILITY_EVENT", "surface", observedUptimeMs = 2_000L + index,
                diagnosticContext = attempts[index % attempts.size],
                fields = mapOf(
                    "eventType" to 2048,
                    "windowChanges" to 0,
                    "windowId" to (1_000 + index),
                    "displayId" to 0,
                    "classification" to "unclassified",
                    "overlayState" to "hidden",
                ),
            )
        }

        val frozen = KeyguardCardDiagnostics.freezeCapture(context)
        val report = frozen["report"] as String
        assertEquals(3, frozen["attemptCount"])
        assertTrue((frozen["eventsEvicted"] as Int) > 0)
        assertTrue(report.contains("attemptId=1"))
        assertTrue(report.contains("attemptId=2"))
        assertTrue(report.contains("attemptId=3"))
        assertTrue(report.contains("rawEventsTruncated=true"))
        assertTrue(report.contains("omittedEventLines="))
        assertTrue(report.contains("omittedEvidenceRecords="))
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

    @Test fun handoffTimingUsesTheDispatchBoundaryRatherThanDiagnosticArrivalOrder() {
        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug", "LIGHT")
        val attempt = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 41L, 1L, "wake", 0L))
        KeyguardCardDiagnostics.captureEvent(
            context, "INSPECTION_QUEUED", "wake", requestId = 8L,
            observedUptimeMs = 10L, diagnosticContext = attempt,
            fields = mapOf("queuedAtUptimeMs" to 10L),
        )
        KeyguardCardDiagnostics.captureEvent(
            context, "INSPECTION_STARTED", "wake", requestId = 8L,
            observedUptimeMs = 20L, diagnosticContext = attempt,
            fields = mapOf("authorityCurrentAtStart" to true),
        )
        KeyguardCardDiagnostics.captureEvent(
            context, "INSPECTION_FINISHED", "mainKeyguard", requestId = 8L,
            observedUptimeMs = 100L, diagnosticContext = attempt,
        )
        // The reporting calls can arrive later than their original observed
        // timestamps. The immutable requested handoff remains the boundary.
        KeyguardCardDiagnostics.captureEvent(
            context, "INSPECTION_MAIN_APPLY_STARTED", "wake", requestId = 8L,
            observedUptimeMs = 130L, diagnosticContext = attempt,
            fields = mapOf(
                "diagnosticPreparationFinishedAtUptimeMs" to 108L,
                "mainHandoffRequestedAtUptimeMs" to 110L,
                "mainApplyEnteredAtUptimeMs" to 130L,
            ),
        )
        KeyguardCardDiagnostics.captureEvent(
            context, "INSPECTION_MAIN_APPLY_POSTED", "wake", requestId = 8L,
            observedUptimeMs = 110L, diagnosticContext = attempt,
            fields = mapOf(
                "inspectionFinishedAtUptimeMs" to 100L,
                "diagnosticPreparationFinishedAtUptimeMs" to 108L,
                "mainHandoffRequestedAtUptimeMs" to 110L,
            ),
        )
        val show = KeyguardCardDiagnostics.newShowOperation(attempt, 1L, 8L)
        KeyguardCardDiagnostics.captureEvent(context, "SHOW_FOR_ATTACH", "wake", requestId = 8L, observedUptimeMs = 140L, diagnosticContext = attempt, operation = show)
        KeyguardCardDiagnostics.captureEvent(context, "ADD_VIEW_BEGIN", "window", requestId = 8L, observedUptimeMs = 145L, diagnosticContext = attempt, operation = show)
        KeyguardCardDiagnostics.captureEvent(context, "ADD_VIEW_RETURN", "window", requestId = 8L, observedUptimeMs = 150L, diagnosticContext = attempt, operation = show)

        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertTrue(report.contains("inspectionFinishToHandoffMs=10"))
        assertTrue(report.contains("handoffToMainEntryMs=20"))
        assertTrue(report.contains("mainEntryToDecisionMs=10"))
    }

    @Test fun lightCaptureKeepsMilestonesWithoutRawAccessibilityFlood() {
        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug", "LIGHT")
        val attempt = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 42L, 1L, "wake", 0L))
        repeat(300) { index ->
            KeyguardCardDiagnostics.captureEvent(
                context, "ACCESSIBILITY_EVENT", "surface", observedUptimeMs = 100L + index,
                diagnosticContext = attempt,
                fields = mapOf("overlayState" to "hidden", "eventType" to 2048),
            )
        }
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertTrue(report.contains("captureMode=LIGHT"))
        assertTrue(report.contains("diagnosticDroppedRecords="))
        assertFalse(report.contains("stage=ACCESSIBILITY_EVENT"))
    }

    @Test fun serviceColdPreparationSurvivesACaptureStartedLater() {
        KeyguardCardDiagnostics.recordColdPreparation(77L, "SERVICE_CONNECTED", 10L)
        KeyguardCardDiagnostics.recordColdPreparation(77L, "MATERIAL_PROGRAM_PREPARED", 20L)
        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String

        assertTrue(report.contains("COLD_PREPARATION"))
        assertTrue(report.contains("serviceSession=77"))
        assertTrue(report.contains("SERVICE_CONNECTED=10"))
        assertTrue(report.contains("MATERIAL_PROGRAM_PREPARED=20"))
    }

    @Test fun lightAndOffSkipVerboseBuildersBeforeReduction() {
        val builds = java.util.concurrent.atomic.AtomicInteger()
        val fields = { builds.incrementAndGet(); mapOf<String, Any?>("windowId" to 17) }
        KeyguardCardDiagnostics.captureEvent(context, "ACCESSIBILITY_EVENT", "off", deferredFields = fields)
        KeyguardCardDiagnostics.captureSnapshot(context)
        assertEquals(0, builds.get())
        KeyguardCardDiagnostics.startCapture(context, "light-sha", "debug", "LIGHT")
        repeat(100) {
            KeyguardCardDiagnostics.captureEvent(context, "ACCESSIBILITY_EVENT", "light", deferredFields = fields)
        }
        KeyguardCardDiagnostics.freezeCapture(context)
        assertEquals(0, builds.get())
        KeyguardCardDiagnostics.startCapture(context, "full-sha", "debug", "FULL")
        KeyguardCardDiagnostics.captureEvent(context, "ACCESSIBILITY_EVENT", "full", deferredFields = fields)
        KeyguardCardDiagnostics.freezeCapture(context)
        assertEquals(1, builds.get())
    }

    @Test fun blockedReductionDoesNotBlockProducersAndFreezeKeepsOriginalOwnership() {
        val entered = java.util.concurrent.CountDownLatch(1)
        val release = java.util.concurrent.CountDownLatch(1)
        KeyguardCardDiagnostics.startCapture(context, "async-sha", "debug", "LIGHT")
        val attempt = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 9L, 1L, "wake", 100L))
        KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_QUEUED", "wake", requestId = 7L, diagnosticContext = attempt, observedUptimeMs = 101L)
        KeyguardCardDiagnostics.captureEvent(
            context, "INSPECTION_FINISHED", "main", requestId = 7L,
            diagnosticContext = attempt, observedUptimeMs = 200L,
            deferredFields = {
                entered.countDown()
                check(release.await(10, java.util.concurrent.TimeUnit.SECONDS))
                mapOf("inspectionTotalMs" to 90L)
            },
        )
        try {
            assertTrue(entered.await(5, java.util.concurrent.TimeUnit.SECONDS))
            // These are the exact production ingress methods used by window
            // and service callbacks. The consumer remains deliberately held.
            androidx.test.platform.app.InstrumentationRegistry.getInstrumentation().runOnMainSync {
                KeyguardCardDiagnostics.record(context, "KG|TEST", "stillResponsive", false)
                KeyguardCardDiagnostics.recordHiddenNoop(context)
                KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_STARTED", "pending", requestId = 8L, diagnosticContext = attempt, observedUptimeMs = 201L)
            }
            assertEquals(1L, release.count)
        } finally {
            release.countDown()
        }
        val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertTrue(frozen.contains("req=7"))
        assertTrue(frozen.contains("finished=200"))
        assertTrue(frozen.contains("hiddenNoopCount=1"))
        assertTrue(frozen.contains("diagnosticQueueOverflow=0"))
        assertTrue(frozen.contains("diagnosticConsumerFailures=0"))
        assertEquals(frozen, KeyguardCardDiagnostics.captureSnapshot(context)["report"])
    }

    @Test fun lightPressureRetainsEverySelectedEpisodeCauseAndFitsTheWholeUtf8Budget() {
        KeyguardCardDiagnostics.startCapture(context, "episode-pressure-sha", "profile", "LIGHT")
        val showRequests = mutableListOf<Long>()
        val withdrawalRequests = mutableListOf<Long>()
        repeat(4) { wake ->
            val base = 10_000L * (wake + 1)
            val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 81L, wake + 1L, "display", base))
            fun emit(stage: String, req: Long?, at: Long, fields: Map<String, Any?> = emptyMap(), operation: KeyguardDiagnosticOperation? = null) {
                KeyguardCardDiagnostics.captureEvent(context, stage, "surface", requestId = req,
                    observedUptimeMs = at, diagnosticContext = owner, operation = operation, fields = fields)
            }
            fun inspection(req: Long, at: Long, finish: Boolean = true) {
                emit("INSPECTION_QUEUED", req, at, mapOf("queuedAtUptimeMs" to at, "requestVisibilityEpoch" to wake + 1, "eventTimeUptimeMs" to at - 2))
                emit("INSPECTION_STARTED", req, at + 1, mapOf("authorityCurrentAtStart" to true))
                emit("INSPECTION_MAIN_APPLY_STARTED", req, at + 30, mapOf("mainHandoffRequestedAtUptimeMs" to at + 29))
                emit("INSPECTION_APPLIED", req, at + 31, mapOf("visibilityEpochAtApply" to wake + 1, "pendingRequestIdAtApply" to req + 1))
                if (finish) emit("INSPECTION_FINISHED", req, at + 25, readerFields())
            }
            // Attempt 3 has the retained same-wake withdrawal/reappearance
            // analogous to the device report. Its second add genuinely has
            // no FIRST_* publication; no timestamp is invented by export.
            repeat(if (wake == 2) 2 else 1) { episode ->
                val request = base + episode * 100
                val at = base + episode * 200
                val attach = wake * 10L + episode + 1
                inspection(request, at, finish = false)
                val show = KeyguardCardDiagnostics.newShowOperation(owner, attach, request)
                emit("SHOW_FOR_ATTACH", request, at + 32, operation = show)
                emit("ADD_VIEW_BEGIN", request, at + 33, operation = show)
                emit("ADD_VIEW_RETURN", request, at + 34, operation = show)
                if (episode == 0) {
                    emit("FIRST_ROOT_DRAW", request, at + 40, operation = show)
                    emit("FIRST_SHADER_DRAW", request, at + 41, operation = show)
                    emit("FIRST_LIVE_DRAW", request, at + 41, operation = show)
                }
                // Deliberately late detailed completion uses the original
                // acquisition occurrence time, just like production.
                emit("INSPECTION_FINISHED", request, at + 25, readerFields(main = true))
                showRequests += request
                inspection(request + 1, at + 60)
                val hide = KeyguardCardDiagnostics.newHideOperation(owner, attach, request + 1, at + 60)
                emit("HIDE_DECIDED", request + 1, at + 92, operation = hide)
                emit("LOCAL_HIDE_BEGIN", request + 1, at + 93, mapOf("attachedBefore" to true), hide)
                emit("LOCAL_HIDE_APPLIED", request + 1, at + 94, operation = hide)
                emit("REMOVE_VIEW_BEGIN", request + 1, at + 95, operation = hide)
                emit("REMOVE_VIEW_RETURN", request + 1, at + 96, operation = hide)
                emit("ATTACHMENT_RENDER_SUMMARY", request + 1, at + 97,
                    mapOf("clockCallbacks" to 12, "shaderFrames" to if (episode == 0) 11 else 0,
                        "shaderCalls" to if (episode == 0) 13 else 0, "phaseAdvances" to 10,
                        "drawGapCount" to 10, "drawGapMaxMs" to 22, "clockRunning" to false,
                        "drawEvidenceMode" to "LIGHT", "drawEvidenceOmitted" to 7,
                        "drawObservedFrames" to 11, "drawObserverNs" to 1900,
                        "drawUnpairedFrames" to 0, "drawCoalescedCallbacks" to 1,
                        "orbDrawGaps" to (0..2).joinToString("\n") { gapFixture(it, 1_100) },
                        "backgroundDrawGaps" to (0..2).joinToString("\n") { gapFixture(it + 3, 1_100) }), hide)
                withdrawalRequests += request + 1
            }
            repeat(90) { index ->
                val request = base + 1_000 + index
                inspection(request, base + 500 + index)
                if (index % 20 == 0) KeyguardCardDiagnostics.captureSnapshot(context) // drain fixture pressure; not production polling
            }
        }
        val frozen = KeyguardCardDiagnostics.freezeCapture(context)
        val report = frozen["report"] as String
        val bytes = report.toByteArray(Charsets.UTF_8).size
        android.util.Log.i("FluviExportBudget", "LIGHT retainedEpisodes=5 events=${frozen["eventsRecorded"]} UTF8Bytes=$bytes")
        assertTrue((frozen["eventsRecorded"] as Long) >= 1_507L)
        assertTrue("complete export was $bytes bytes", bytes <= 32 * 1024)
        assertTrue(report.contains("exportBytes=$bytes\n"))
        assertTrue(report.contains("retainedAttemptIds=1,2,3,4"))
        assertTrue(report.contains("omittedCriticalRecordIds=none"))
        assertTrue(report.contains("incompleteExportAttemptIds=none"))
        assertTrue(report.contains("drawGapEvidenceOmitted="))
        assertFalse(report.contains("omittedDrawGapRecordIds=none"))
        val selectedGaps = report.lineSequence().filter { it.startsWith(" DRAW_GAP ") }.toList()
        assertEquals((1..4).take(selectedGaps.size), selectedGaps.take(4).map {
            it.substringAfter("attempt=").substringBefore(' ').toInt()
        })
        assertTrue(selectedGaps.take(4).all { it.contains("surface=orb sample=0 ") })
        assertTrue(report.lineSequence().filter { it.startsWith(" RENDER ") }.all {
            !it.contains("orbDrawGaps=") && !it.contains("backgroundDrawGaps=")
        })
        showRequests.forEach { request ->
            assertTrue("missing showing cause $request", report.lineSequence().any {
                (it.startsWith(" SHOWING_INSPECTION ") || it.startsWith(" SHOW_CAUSE ")) && it.contains("req=$request ") && it.contains("finished=") && it.contains("freshness=FRAMEWORK_EVENT")
            })
        }
        withdrawalRequests.forEach { request ->
            assertTrue("missing withdrawal cause $request", report.lineSequence().any {
                (it.startsWith(" ACTUAL_WITHDRAWAL_INSPECTION ") || it.startsWith(" WITHDRAWAL_CAUSE ")) && it.contains("req=$request ")
            })
        }
        val episodes = report.lineSequence().filter { it.startsWith(" EPISODE ") }.toList()
        assertEquals(5, episodes.size)
        assertTrue(episodes.single { it.contains("req=30100 ") }.contains("shader=NO_DRAW_OBSERVED"))
        assertTrue(report.contains("truncationReasons=NULL_CHILD"))
        assertTrue(report.contains("shaderFrames=11 shaderCalls=13"))
        assertEquals(report, KeyguardCardDiagnostics.captureSnapshot(context)["report"])
    }

    @Test fun oneCompleteEpisodeCannotConcealAMissingSecondOperationBoundary() {
        KeyguardCardDiagnostics.startCapture(context, "identity-check", "debug", "LIGHT")
        val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 91L, 1L, "wake", 10L))
        val first = KeyguardCardDiagnostics.newShowOperation(owner, 1L, null)
        val second = KeyguardCardDiagnostics.newShowOperation(owner, 2L, null)
        fun emit(stage: String, at: Long, operation: KeyguardDiagnosticOperation) {
            KeyguardCardDiagnostics.captureEvent(context, stage, "test", operation = operation, observedUptimeMs = at)
        }
        emit("SHOW_FOR_ATTACH", 11L, first)
        emit("ADD_VIEW_RETURN", 12L, first)
        emit("FIRST_ROOT_DRAW", 13L, first)
        emit("SHOW_FOR_ATTACH", 20L, second)
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertTrue(report.contains("causalSpineComplete=false"))
        assertTrue(report.contains("firstRootDrawObserved=true"))
    }

    @Test fun optionalDrawGapRecordsKeepWholeLinesAndTheirAttachmentIdentity() {
        KeyguardCardDiagnostics.startCapture(context, "draw-gap-identity", "profile", "LIGHT")
        val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 92L, 1L, "wake", 100L))
        val shows = (1L..2L).map { attach ->
            val show = KeyguardCardDiagnostics.newShowOperation(owner, attach, null)
            KeyguardCardDiagnostics.captureEvent(context, "SHOW_FOR_ATTACH", "main", operation = show, observedUptimeMs = attach * 100)
            KeyguardCardDiagnostics.captureEvent(context, "ADD_VIEW_RETURN", "added", operation = show, observedUptimeMs = attach * 100 + 1)
            val hide = KeyguardCardDiagnostics.newHideOperation(owner, attach, null, attach * 100 + 50)
            KeyguardCardDiagnostics.captureEvent(context, "ATTACHMENT_RENDER_SUMMARY", "withdrawal", operation = hide,
                fields = mapOf("drawEvidenceMode" to "LIGHT", "drawEvidenceOmitted" to 5,
                    "drawObserverNs" to 100, "drawObservedFrames" to 12, "drawUnpairedFrames" to 1,
                    "drawCoalescedCallbacks" to 2, "drawEvidenceBreaks" to 1, "drawEvidenceRejected" to 3,
                    "orbDrawGaps" to "${gapFixture(1, 320)}\n${gapFixture(2, 340)}",
                    "backgroundDrawGaps" to gapFixture(3, 360)))
            show
        }
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        val gaps = report.lineSequence().filter { it.startsWith(" DRAW_GAP ") }.toList()
        assertEquals(6, gaps.size)
        assertEquals(shows.map { it.showOperationId }, gaps.take(2).map {
            it.substringAfter("showOp=").substringBefore(' ').toLong()
        })
        assertTrue(gaps.take(2).all { it.contains("surface=orb sample=0 ") })
        shows.forEach { show ->
            val owned = gaps.filter { it.contains("showOp=${show.showOperationId} attach=${show.attachGeneration} ") }
            assertEquals(3, owned.size)
            assertTrue(owned.any { it.endsWith("end=3") })
            assertTrue(owned.all { it.contains("attempt=1 ") })
        }
        assertTrue(report.contains("drawGapEvidenceExported=6"))
        assertTrue(report.contains("omittedDrawGapRecordIds=none"))
        assertTrue(report.contains("drawEvidenceOmitted=5"))
        assertTrue(report.contains("drawEvidenceBreaks=1"))
        assertTrue(report.contains("drawEvidenceRejected=3"))
        assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32 * 1024)
        assertTrue(report.lineSequence().filter { it.startsWith(" RENDER ") }.none { it.contains("end=") })
    }

    @Test fun drawEvidenceOwnerChangesAcrossCapturesWithoutAnInterveningFrame() {
        assertEquals(null, KeyguardCardDiagnostics.drawEvidenceOwner())
        KeyguardCardDiagnostics.startCapture(context, "draw-owner", "profile", "LIGHT")
        val first = checkNotNull(KeyguardCardDiagnostics.drawEvidenceOwner())
        assertTrue(first === KeyguardCardDiagnostics.drawEvidenceOwner())
        KeyguardCardDiagnostics.freezeCapture(context)
        assertEquals(null, KeyguardCardDiagnostics.drawEvidenceOwner())
        KeyguardCardDiagnostics.startCapture(context, "draw-owner", "profile", "LIGHT")
        val second = checkNotNull(KeyguardCardDiagnostics.drawEvidenceOwner())
        assertFalse(first === second)
    }

    @Test fun malformedOrExcessGapRecordsAreOmittedWholeAndCounted() {
        KeyguardCardDiagnostics.startCapture(context, "gap-bounds", "debug", "LIGHT")
        val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 93L, 1L, "wake", 100L))
        val show = KeyguardCardDiagnostics.newShowOperation(owner, 1L, null)
        KeyguardCardDiagnostics.captureEvent(context, "SHOW_FOR_ATTACH", "main", operation = show)
        KeyguardCardDiagnostics.captureEvent(context, "ADD_VIEW_RETURN", "added", operation = show)
        KeyguardCardDiagnostics.captureEvent(context, "ATTACHMENT_RENDER_SUMMARY", "withdrawal", operation = show,
            fields = mapOf("orbDrawGaps" to (listOf(gapFixture(99, 1_400)) + (1..4).map { gapFixture(it, 300) }).joinToString("\n")))
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        val gaps = report.lineSequence().filter { it.startsWith(" DRAW_GAP ") }.toList()
        assertEquals(3, gaps.size)
        assertTrue(gaps.all { it.endsWith("end=1") || it.endsWith("end=2") || it.endsWith("end=3") })
        assertTrue(report.contains("drawGapCaptureOmitted=2"))
        assertFalse(report.contains("gap=99"))
        assertFalse(report.contains("end=4"))
    }

    private fun gapFixture(index: Int, length: Int): String =
        "gap=$index dt=48 " + "x=1 ".repeat((length - 30) / 4) + "end=$index"

    private fun readerFields(main: Boolean = false): Map<String, Any?> = mapOf(
        "surfaceClassification" to if (main) "SHOW_FULL" else "HIDDEN_UNKNOWN",
        "surfaceMarkers" to if (main) "main:1,credential:0,shade:0,occlusion:0" else "main:0,credential:0,shade:0,occlusion:0",
        "readerStrategy" to "ACTIVE_ROOT_BATCHED_PLUS_PER_WINDOW", "freshnessPolicy" to "FRAMEWORK_EVENT",
        "cacheClearResult" to "notRequiredFrameworkManaged", "activeCandidateWindowId" to 73,
        "returnedRootWindowId" to 73, "activeRootAccepted" to true, "activeRootTotalMs" to 8,
        "perWindowRootTotalMs" to 2, "childAcquisitionCount" to 12, "childAcquisitionTotalMs" to 10,
        "childAcquisitionMaxMs" to 6, "localProcessingMs" to 2, "visitedNodeCount" to 43,
        "rootUnavailable" to false, "walkTruncated" to !main, "walkTruncationReasons" to if (main) "none" else "NULL_CHILD",
        "slowWindowCalls" to "child:w=73,i=3,6",
    )
}
