package com.fluvi.app.lockscreen

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import java.io.File
import java.util.UUID
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/** Reducer/export control: it does not claim a real Android wake or grant. */
@RunWith(AndroidJUnit4::class)
class KeyguardR41DiagnosticsInstrumentationTest {
    private val context get() = InstrumentationRegistry.getInstrumentation().targetContext

    @After fun clear() { KeyguardCardDiagnostics.clearCapture(context) }

    private fun retain(name: String, report: String) {
        val uuid = InstrumentationRegistry.getArguments().getString("runUuid")?.let(UUID::fromString)?.toString()
            ?: UUID.randomUUID().toString()
        val directory = File(context.filesDir, "keyguard-service-probe/r41/$uuid")
        check(directory.mkdirs() || directory.isDirectory)
        File(directory, name).writeText(report, Charsets.UTF_8)
    }

    @Test fun allAttemptsSurviveVerboseLightPressure() = exercise("LIGHT")
    @Test fun allAttemptsSurviveVerboseFullPressure() = exercise("FULL")

    @Test fun r42LateCriticalWakeSurvivesRawLightPressure() = r42LateCriticalWakeSurvivesRawPressure("LIGHT")
    @Test fun r42LateCriticalWakeSurvivesRawFullPressure() = r42LateCriticalWakeSurvivesRawPressure("FULL")
    @Test fun r42LateWinnerOfferAndReadSurviveRawPressure() {
        KeyguardCardDiagnostics.startCapture(context, "r42-winning-offer", "profile", "FULL")
        val capture = checkNotNull(KeyguardCardDiagnostics.activeCaptureId())
        val first = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 943, 1, "wake", 1000))
        repeat(2_200) { index ->
            KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.OFFER, first, 10_000L + index, atNs = 1_000_000L + index)
        }
        val receipt = KeyguardCardDiagnostics.r41Provisional(capture, 1, 943, 2000, 2_000_000L)
        val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 943, 2, "wake", 2000))
        KeyguardCardDiagnostics.r41Bind(owner, receipt)
        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.OFFER, owner, 201, atNs = 2_000_001L)
        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.WORKER, owner, 201, atNs = 2_000_002L)
        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.READ_START, owner, 201, atNs = 2_000_003L)
        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.READ_END, owner, 201, atNs = 2_000_004L)
        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.GRANT, owner, 201, 102, 202, atNs = 2_000_005L)
        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.WINNER, owner, 201, 102, 202, atNs = 2_000_006L)
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        retain("FULL-r42-late-winner-offer.txt", report)
        val row = report.lineSequence().single { it.startsWith(" R41_CORE attempt=2 ") }
        assertTrue("raw loss must remain explicit", Regex("rawOverflow=[1-9][0-9]*").containsMatchIn(report))
        assertTrue(row, row.contains("wakeNs=2000000") && row.contains("offerNs=2000001") &&
            row.contains("workerNs=2000002") && row.contains("readStartNs=2000003") &&
            row.contains("readEndNs=2000004") && row.contains("outcome=SUCCESS") && row.contains("owner=102/202/201"))
        assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32_768)
    }

    /** The supplied R41 phone capture lost its complete last attempt after
     * raw overflow. This fixture keeps the original raw loss visible while
     * requiring independent compact wake/grant/owner evidence for later
     * attempts. These timestamps are synthetic and do not measure speed. */
    private fun r42LateCriticalWakeSurvivesRawPressure(mode: String) {
        KeyguardCardDiagnostics.startCapture(context, "r42-raw-pressure", "profile", mode)
        val capture = checkNotNull(KeyguardCardDiagnostics.activeCaptureId())
        val receipts = mutableListOf<Long>()
        for (attempt in 1L..6L) {
            val base = attempt * 1_000_000_000L
            val receipt = KeyguardCardDiagnostics.r41Provisional(capture, 1, 942, attempt * 1000, base)
            receipts += receipt
            val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 942, attempt, "wake", attempt * 1000))
            KeyguardCardDiagnostics.r41Bind(owner, receipt)
            val request = attempt * 100 + 1
            KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.ELIGIBLE, owner, atNs = base + 1)
            KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.READ_START, owner, request, atNs = base + 2)
            KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.READ_END, owner, request, atNs = base + 3)
            KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.GRANT, owner, request, 100 + attempt, 200 + attempt, atNs = base + 4)
            KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.WINNER, owner, request, 100 + attempt, 200 + attempt, atNs = base + 5)
            if (attempt == 1L) repeat(2_200) { index ->
                KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.OFFER, owner, 10_000L + index, atNs = base + 100 + index)
            }
        }
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        retain("$mode-r42-raw-pressure-frozen.txt", report)
        assertTrue("$mode overflow must be reported", Regex("rawOverflow=[1-9][0-9]*").containsMatchIn(report))
        assertTrue("$mode export must fit the native byte limit", report.toByteArray(Charsets.UTF_8).size <= 32_768)
        val rows = report.lineSequence().filter { it.startsWith(" R41_CORE ") }.toList()
        assertEquals("$mode must retain the six independently owned attempts", 6, rows.size)
        for (attempt in 1L..6L) {
            val row = rows.single { it.contains("attempt=$attempt ") }
            assertTrue("$mode attempt $attempt has no protected receipt: $receipts", receipts[(attempt - 1).toInt()] > 0)
            assertTrue("$mode lost wake identity: $row", row.contains("wakeNs=${attempt * 1_000_000_000L}"))
            assertTrue("$mode lost the exact terminal owner: $row", row.contains("outcome=SUCCESS") &&
                row.contains("owner=${100 + attempt}/${200 + attempt}/${attempt * 100 + 1}"))
            assertTrue("raw loss cannot be reported as complete: $row", row.contains("coverage=INCOMPLETE"))
        }
    }

    @Test fun twentyFiveRequestWakeSurvivesLightExport() = exportTwentyFiveRequests("LIGHT")
    @Test fun twentyFiveRequestWakeSurvivesFullExport() = exportTwentyFiveRequests("FULL")

    @Test fun directAndWithdrawalEvidenceSurvivesR41LightPressure() = protectedDirectUnderPressure("LIGHT")
    @Test fun directAndWithdrawalEvidenceSurvivesR41FullPressure() = protectedDirectUnderPressure("FULL")

    @Test fun absentR22BoundariesRemainExplicitlyUnknown() {
        for (mode in listOf("LIGHT", "FULL")) {
            KeyguardCardDiagnostics.startCapture(context, "r41-empty-r22", "profile", mode)
            val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 941, 1, "wake", 10))
            KeyguardCardDiagnostics.captureEvent(context, "R18_PIPELINE", "WAKE_ADOPTED", serviceSession = 941,
                wakeEpoch = 1, requestId = 77, attachGeneration = 2, diagnosticContext = owner,
                observedUptimeMs = 11, fields = mapOf<String, Any>("r18Host" to 2, "r18Output" to 3))
            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
            val row = report.lineSequence().single { it.startsWith(" R22_CORE ") }
            assertTrue(row, row.contains("v=2 attempt=1 session=941 wake=1 wakeAt=10"))
            assertTrue(row, row.contains("opening=UNOBSERVED/UNOBSERVED outcome=UNOBSERVED/UNOBSERVED"))
            assertTrue(row, row.contains("missing=ALL_R22_BOUNDARIES"))
            assertTrue(row, row.contains("physical=UNOBSERVED"))
        }
    }

    @Test fun duplicateFirstCauseReferencesOnlyTheExactSelectedShowingCause() {
        for (mode in listOf("LIGHT", "FULL")) {
            KeyguardCardDiagnostics.startCapture(context, "r41-shared-cause", "profile", mode)
            val capture = checkNotNull(KeyguardCardDiagnostics.activeCaptureId())
            val owners = (1L..2L).map { attempt ->
                val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 941, attempt, "wake", attempt * 1000))
                val first = attempt * 100 + 1
                fun read(request: Long, at: Long) {
                    KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_QUEUED", "wake", requestId = request,
                        diagnosticContext = owner, observedUptimeMs = at)
                    KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_FINISHED", "MAIN_CONFIRMED", requestId = request,
                        diagnosticContext = owner, observedUptimeMs = at + 1,
                        fields = mapOf("activeRootFlags" to 0, "acceptedChildFlags" to 36,
                            "surfaceClassification" to "SHOW_FULL", "surfaceReason" to "MAIN_CONFIRMED"))
                }
                read(first, attempt * 1000 + 1)
                val showing = if (attempt == 1L) first else first + 1
                if (showing != first) read(showing, attempt * 1000 + 3)
                val show = KeyguardCardDiagnostics.newShowOperation(owner, attempt, showing)
                KeyguardCardDiagnostics.captureEvent(context, "SHOW_FOR_ATTACH", "wake", operation = show,
                    observedUptimeMs = attempt * 1000 + 5)
                owner
            }
            for ((index, owner) in owners.withIndex()) {
                for (request in 1L..29L) KeyguardCardDiagnostics.r41Mark(
                    KeyguardR41RawLedger.OFFER, owner, 10_000L * (index + 1) + request,
                    atNs = 1_234_567_890_000_000L + request)
            }
            for (id in 1L..60L) {
                val sample = KeyguardSystemGateRequest(1000 + id, KeyguardInspectionAuthority(941, 1, 1, 1, 1),
                    "wake", 10, 10, evaluate = true, wakeSource = "wake", diagnosticCaptureId = capture)
                listOf(KeyguardR41RawLedger.SAMPLE_OFFER, KeyguardR41RawLedger.SAMPLE_SUBMIT,
                    KeyguardR41RawLedger.SAMPLE_WORKER, KeyguardR41RawLedger.SAMPLE_READ_START,
                    KeyguardR41RawLedger.SAMPLE_READ_END, KeyguardR41RawLedger.SAMPLE_DISPATCH,
                    KeyguardR41RawLedger.SAMPLE_MAIN, KeyguardR41RawLedger.SAMPLE_DELIVER).forEach {
                    KeyguardCardDiagnostics.r41SamplerMark(it, sample, 0)
                }
            }
            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
            retain("$mode-shared-cause-frozen.txt", report)
            val summaries = report.substringAfter("ATTEMPT_SUMMARIES\n").substringBefore("EPISODES\n")
            val first = summaries.substringAfter("attemptId=1 ").substringBefore("attemptId=2 ")
                .lineSequence().single { it.startsWith(" FIRST_INSPECTION ") }
            val second = summaries.substringAfter("attemptId=2 ")
                .lineSequence().single { it.startsWith(" FIRST_INSPECTION ") }
            assertTrue(first, first.contains("req=101 ") && first.contains("rootFlags=0 acceptedChildFlags=36"))
            assertTrue(first, first.contains("sameAs=SHOWING_INSPECTION"))
            assertTrue(report, report.lineSequence().any { it.startsWith(" SHOWING_INSPECTION req=101 ") &&
                it.contains("rootFlags=0 acceptedChildFlags=36") })
            assertTrue(second, second.contains("req=201 "))
            assertFalse(second, second.contains("sameAs=SHOWING_INSPECTION"))
            assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32_768)
        }
    }

    private fun protectedDirectUnderPressure(mode: String) {
        KeyguardCardDiagnostics.startCapture(context, "r41-direct-pressure", "profile", mode)
        val capture = checkNotNull(KeyguardCardDiagnostics.activeCaptureId())
        val receipt = KeyguardCardDiagnostics.r41Provisional(capture, 1, 941, 10, 10_000L)
        val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 941, 1, "wake", 10))
        KeyguardCardDiagnostics.r41Bind(owner, receipt)
        fun edge(phase: String, time: Long, extra: Map<String, Any> = emptyMap()) {
            KeyguardCardDiagnostics.captureEvent(context, "R18_PIPELINE", phase, serviceSession = 941,
                wakeEpoch = 1, requestId = 77, attachGeneration = 2, diagnosticContext = owner,
                observedUptimeMs = time, fields = mapOf<String, Any>("r18Host" to 2, "r18Output" to 3,
                    "r18Privacy" to "full", "r19Intent" to "EMPTY") + extra)
        }
        edge("WAKE_ADOPTED", 10_000)
        edge("BUFFER_READY", 10_003)
        edge("GRANT", 10_005, mapOf("r18Proof" to 77))
        edge("REVEAL_RECEIPT", 10_010, mapOf("r18ApplyBegin" to 10_008, "r18ApplyEnd" to 10_010))
        val show = KeyguardCardDiagnostics.newShowOperation(owner, 2, 77)
        KeyguardCardDiagnostics.captureEvent(context, "SHOW_FOR_ATTACH", "test", operation = show,
            observedUptimeMs = 10_005)
        val hide = KeyguardCardDiagnostics.newHideOperation(owner, 2, 10_020, 10_021)
        KeyguardCardDiagnostics.captureEvent(context, "HIDE_DECIDED", "test", operation = hide,
            observedUptimeMs = 10_022)
        KeyguardCardDiagnostics.captureEvent(context, "LOCAL_HIDE_APPLIED", "test", operation = hide,
            observedUptimeMs = 10_023)
        KeyguardCardDiagnostics.captureEvent(context, "REMOVE_VIEW_RETURN", "test", operation = hide,
            observedUptimeMs = 10_024)
        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.ELIGIBLE, owner, atNs = 10_001L)
        for (id in 1L..29L) KeyguardCardDiagnostics.r41Mark(
            KeyguardR41RawLedger.OFFER, owner, id, atNs = 1_234_567_890_000_000L + id)
        for (id in 1L..60L) {
            val sample = KeyguardSystemGateRequest(1_000 + id, KeyguardInspectionAuthority(941, 1, 1, 1, 1),
                "wake", 10, 10, evaluate = true, wakeSource = "wake", diagnosticCaptureId = capture,
                r41WakeOrdinal = receipt, r41ScreenOrdinal = receipt)
            listOf(KeyguardR41RawLedger.SAMPLE_OFFER, KeyguardR41RawLedger.SAMPLE_SUBMIT,
                KeyguardR41RawLedger.SAMPLE_WORKER, KeyguardR41RawLedger.SAMPLE_READ_START,
                KeyguardR41RawLedger.SAMPLE_READ_END, KeyguardR41RawLedger.SAMPLE_DISPATCH,
                KeyguardR41RawLedger.SAMPLE_MAIN, KeyguardR41RawLedger.SAMPLE_DELIVER).forEach {
                KeyguardCardDiagnostics.r41SamplerMark(it, sample, 0)
            }
        }
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        retain("$mode-direct-pressure-frozen.txt", report)
        assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32_768)
        assertTrue("$mode lost its R41 compact core", report.contains(" R41_CORE attempt=1 "))
        assertTrue("$mode lost its prior R18 direct evidence", report.contains(" R18_PIPELINE attempt=1 "))
        assertTrue("$mode lost its show", report.contains(" EPISODE attempt=1 "))
        assertTrue("$mode lost its withdrawal", report.contains(" WITHDRAWAL hideOp="))
        assertTrue("$mode must explicitly identify omitted details", report.contains("omittedCriticalRecordIds=") &&
            !report.contains("omittedCriticalRecordIds=none"))
    }

    private fun exportTwentyFiveRequests(mode: String) {
        KeyguardCardDiagnostics.startCapture(context, "r41-25-requests", "profile", mode)
        val capture = checkNotNull(KeyguardCardDiagnostics.activeCaptureId())
        val receipt = KeyguardCardDiagnostics.r41Provisional(capture, 1, 941, 1, 1_000L)
        val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 941, 1, "wake", 1))
        KeyguardCardDiagnostics.r41Bind(owner, receipt)
        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.ELIGIBLE, owner, atNs = 1_001L)
        for (id in 1L..25L) {
            KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.OFFER, owner, id, atNs = 2_000L + id)
        }
        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.READ_START, owner, 1, atNs = 3_000L)
        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.READ_END, owner, 1, atNs = 4_000L)
        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.READ_START, owner, 25, atNs = 5_000L)
        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.READ_END, owner, 25, atNs = 6_000L)
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        retain("$mode-25-requests-frozen.txt", report)
        val core = report.lineSequence().single { it.startsWith(" R41_CORE ") }
        assertTrue(core, core.contains("requests=25 omitted=0"))
        val rows = report.lineSequence().filter { it.startsWith(" R41_REQ ") }.toList()
        assertEquals("$mode must export every retained request", 25, rows.size)
        for (id in 1L..25L) assertEquals("request $id", 1, rows.count { it.contains("req=$id ") })
        assertTrue(rows.single { it.contains("req=1 ") }.contains("read=3000/4000"))
        assertTrue(rows.single { it.contains("req=25 ") }.contains("read=5000/6000"))
        assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32_768)
    }

    @Test fun rawWinnerAndCancellationRetainTheirCaptureAndRequestOwners() {
        KeyguardCardDiagnostics.startCapture(context, "r41-raw-owner", "profile", "LIGHT")
        val capture = checkNotNull(KeyguardCardDiagnostics.activeCaptureId())
        val receipt = KeyguardCardDiagnostics.r41Provisional(capture, 1, 941, 10, 10_000L)
        assertTrue("a real raw receipt must be retained", receipt > 0)
        val old = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 941, 1, "wake", 10))
        KeyguardCardDiagnostics.r41Bind(old, receipt)
        KeyguardCardDiagnostics.r41Bind(old, receipt, screen = true)
        val sample = KeyguardSystemGateRequest(55, KeyguardInspectionAuthority(941, 1, 1, 1, 1),
            "wake", 10, 10, evaluate = true, wakeSource = "wake", diagnosticCaptureId = capture,
            r41WakeOrdinal = receipt, r41ScreenOrdinal = receipt)
        listOf(KeyguardR41RawLedger.SAMPLE_OFFER, KeyguardR41RawLedger.SAMPLE_SUBMIT,
            KeyguardR41RawLedger.SAMPLE_WORKER, KeyguardR41RawLedger.SAMPLE_READ_START,
            KeyguardR41RawLedger.SAMPLE_READ_END, KeyguardR41RawLedger.SAMPLE_DISPATCH,
            KeyguardR41RawLedger.SAMPLE_MAIN, KeyguardR41RawLedger.SAMPLE_DELIVER).forEach {
            KeyguardCardDiagnostics.r41SamplerMark(it, sample, if (it == KeyguardR41RawLedger.SAMPLE_READ_END) 5 else 0)
        }
        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.ELIGIBLE, old, atNs = 10_001L)
        fun mark(phase: Int, request: Long, at: Long, reservation: Long = 0, output: Long = 0) {
            KeyguardCardDiagnostics.r41Mark(phase, old, request, reservation, output, atNs = at)
        }
        mark(KeyguardR41RawLedger.OFFER, 101, 11_000L)
        mark(KeyguardR41RawLedger.ORDERED_SHADOW_OFFER, 101, 11_500L, 102, 15)
        mark(KeyguardR41RawLedger.GRANT, 101, 12_000L, 1001, 2001)
        mark(KeyguardR41RawLedger.CANCEL, 101, 13_000L)
        mark(KeyguardR41RawLedger.OFFER, 102, 14_000L)
        mark(KeyguardR41RawLedger.WORKER, 102, 15_000L)
        mark(KeyguardR41RawLedger.READ_START, 102, 16_000L)
        mark(KeyguardR41RawLedger.READ_END, 102, 17_000L)
        mark(KeyguardR41RawLedger.DISPATCH, 102, 18_000L)
        mark(KeyguardR41RawLedger.MAIN, 102, 19_000L)
        mark(KeyguardR41RawLedger.GRANT, 102, 20_000L, 1002, 2002)
        mark(KeyguardR41RawLedger.WINNER, 102, 21_000L, 1002, 2002)
        mark(KeyguardR41RawLedger.FALLBACK_CANDIDATE, 103, 22_000L, 1003, 3003)
        mark(KeyguardR41RawLedger.FALLBACK_POST_RECEIPT, 103, 23_000L, 1003, 4003)
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        retain("raw-original-frozen.txt", report)
        val row = report.lineSequence().single { it.startsWith(" R41_CORE ") }
        assertTrue(row, row.contains("outcome=SUCCESS") && row.contains("owner=1002/2002/102"))
        assertTrue(row, row.contains("wakeNs=10000") && row.contains("screenNs=10000"))
        assertTrue(row, row.contains("grantNs=20000") && row.contains("winnerNs=21000"))
        assertTrue(row, row.contains("h2ShadowOffers=1 h2PartialMatches=1") && row.contains("h2Enabled=false"))
        assertTrue(row, row.contains("fallbackCandidateAndPostReceipt=103/1003/3003/4003/22000/23000") &&
            row.contains("fallbackGrant=UNOBSERVED"))
        assertTrue(report, report.lineSequence().any {
            it.startsWith(" R41_SAMPLE ") && it.contains("sample=55 ") &&
                it.contains("attempt=1 ") && it.contains("receipt=$receipt ") && it.contains("stateFlags=5 ")
        })
        assertTrue(report, report.lineSequence().any {
            it.startsWith(" R41_REQ ") && it.contains("req=101 ") && it.contains("cancel=13000")
        })
        assertTrue(row, row.contains("coverage=INCOMPLETE"))

        KeyguardCardDiagnostics.startCapture(context, "r41-new-owner", "profile", "LIGHT")
        val newCapture = checkNotNull(KeyguardCardDiagnostics.activeCaptureId())
        assertTrue(capture != newCapture)
        val newReceipt = KeyguardCardDiagnostics.r41Provisional(newCapture, 1, 941, 30, 30_000L)
        val current = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 941, 2, "wake", 30))
        KeyguardCardDiagnostics.r41Bind(current, newReceipt)
        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.GRANT, old, 101, 1001, 2001, atNs = 99_000L)
        val newReport = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        retain("raw-replacement-frozen.txt", newReport)
        val newRow = newReport.lineSequence().single { it.startsWith(" R41_CORE ") }
        assertTrue(newRow, newRow.contains("wakeNs=30000") && newRow.contains("grantNs=UNOBSERVED"))
        assertFalse(newReport, newReport.contains("grantNs=99000"))
    }

    @Test fun burstOfPendingOffersPreservesWinningOwnerAndReportsLoss() {
        KeyguardCardDiagnostics.startCapture(context, "r41-burst", "profile", "LIGHT")
        val capture = checkNotNull(KeyguardCardDiagnostics.activeCaptureId())
        val receipt = KeyguardCardDiagnostics.r41Provisional(capture, 1, 941, 1, 1_000L)
        val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 941, 1, "wake", 1))
        KeyguardCardDiagnostics.r41Bind(owner, receipt)
        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.ELIGIBLE, owner, atNs = 1_001L)
        fun mark(phase: Int, request: Long, at: Long, reservation: Long = 0, output: Long = 0) {
            KeyguardCardDiagnostics.r41Mark(phase, owner, request, reservation, output, atNs = at)
        }
        mark(KeyguardR41RawLedger.OFFER, 1, 2_000L)
        mark(KeyguardR41RawLedger.WORKER, 1, 2_001L)
        for (id in 2L..75L) mark(KeyguardR41RawLedger.OFFER, id, 2_001L + id)
        mark(KeyguardR41RawLedger.WORKER, 75, 3_000L)
        mark(KeyguardR41RawLedger.READ_START, 75, 3_100L)
        mark(KeyguardR41RawLedger.READ_END, 75, 3_200L)
        mark(KeyguardR41RawLedger.DISPATCH, 75, 3_300L)
        mark(KeyguardR41RawLedger.MAIN, 75, 3_400L)
        mark(KeyguardR41RawLedger.GRANT, 75, 3_500L, 4, 5)
        mark(KeyguardR41RawLedger.WINNER, 75, 3_600L, 4, 5)
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        retain("pending-burst-frozen.txt", report)
        val row = report.lineSequence().single { it.startsWith(" R41_CORE ") }
        assertTrue(row, row.contains("outcome=SUCCESS") && row.contains("owner=4/5/75"))
        assertTrue(row, row.contains("coverage=INCOMPLETE") && !row.contains("omitted=0"))
        assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32_768)
    }

    private fun exercise(mode: String) {
        KeyguardCardDiagnostics.startCapture(context, "r41-pressure", "profile", mode)
        repeat(11) { index ->
            val attempt = index + 1L
            val base = attempt * 10_000L
            val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 941, attempt, "wake", base))
            fun mark(phase: String, atNs: Long, request: Long? = null) {
                KeyguardCardDiagnostics.captureEvent(context, "R41_BOUNDARY", phase, requestId = request,
                    diagnosticContext = owner, observedUptimeMs = atNs / 1_000_000L,
                    fields = mapOf("r41Ns" to atNs, "r41Tid" to 42L) +
                        if (phase == "GRANT" || phase == "WINNER")
                            mapOf("r41Reservation" to 100 + attempt, "r41Output" to 200 + attempt) else emptyMap())
            }
            mark("WAKE", base * 1_000_000L)
            mark("ELIGIBLE", base * 1_000_000L)
            mark("READ_START", (base + 1) * 1_000_000L, base + 7)
            mark("READ_END", (base + if (attempt == 6L) 501 else 2) * 1_000_000L, base + 7)
            if (attempt != 7L) {
                mark("GRANT", (base + 600) * 1_000_000L, base + 7)
                mark("WINNER", (base + 601) * 1_000_000L, base + 7)
            }
            repeat(60) { noise ->
                KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_QUEUED", "pressure",
                    diagnosticContext = owner, requestId = base + 100 + noise,
                    observedUptimeMs = base + 700 + noise)
                if (noise % 30 == 29) KeyguardCardDiagnostics.captureSnapshot(context)
            }
        }
        val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        retain("$mode-frozen.txt", frozen)
        assertTrue(frozen.toByteArray(Charsets.UTF_8).size <= 32_768)
        val rows = frozen.lineSequence().filter { it.startsWith(" R41_CORE ") }.toList()
        assertEquals("$mode must retain every scheduled compact attempt", 11, rows.size)
        for (attempt in 1..11) assertEquals(1, rows.count { it.contains("attempt=$attempt ") })
        val slow = rows.single { it.contains("attempt=6 ") }
        assertTrue(slow, slow.contains("readStartNs=60001000000") && slow.contains("readEndNs=60501000000"))
        assertTrue(slow, slow.contains("outcome=SUCCESS") && slow.contains("dropped=0"))
        val missing = rows.single { it.contains("attempt=7 ") }
        assertTrue(missing, missing.contains("grantNs=UNOBSERVED"))
        assertFalse(missing, missing.contains("grantNs=0"))
        assertEquals(frozen, KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String)
    }
}
