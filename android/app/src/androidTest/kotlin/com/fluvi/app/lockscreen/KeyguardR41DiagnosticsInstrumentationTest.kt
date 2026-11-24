package com.fluvi.app.lockscreen

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
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

    @Test fun allAttemptsSurviveVerboseLightPressure() = exercise("LIGHT")
    @Test fun allAttemptsSurviveVerboseFullPressure() = exercise("FULL")

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
