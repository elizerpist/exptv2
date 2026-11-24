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
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        retain("raw-original-frozen.txt", report)
        val row = report.lineSequence().single { it.startsWith(" R41_CORE ") }
        assertTrue(row, row.contains("outcome=SUCCESS") && row.contains("owner=1002/2002/102"))
        assertTrue(row, row.contains("wakeNs=10000") && row.contains("screenNs=10000"))
        assertTrue(row, row.contains("grantNs=20000") && row.contains("winnerNs=21000"))
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
