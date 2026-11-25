package com.fluvi.app.lockscreen

import android.os.Build
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.*
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class KeyguardR43DiagnosticsInstrumentationTest {
    @Test fun namedHoldsSurvivePressureWithoutUnverifiedOrForeignIds() {
        assumeTrue("genuine API 37 device required", Build.VERSION.SDK_INT >= 37)
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        KeyguardCardDiagnostics.startCapture(context, "r43-test", "debug", "LIGHT", true)
        val capture = requireNotNull(KeyguardCardDiagnostics.activeCaptureId())
        try {
            val labels = listOf("CLOCK_1", "PIN", "CLOCK_2", "SHADE")
            labels.forEachIndexed { i, label ->
                val evidence = KeyguardR43SurfaceEvidence()
                val w = requireNotNull(evidence.window(100 + i, 3, 4, 0, true, false, "com.android.systemui", true))
                w.node(true, true, "com.android.systemui:id/PRIVATE_NOT_A_REAL_RESOURCE", 1, 0, 0)
                w.node(true, false, "com.example.private:id/ACCOUNT_SECRET", 2, 1, 1)
                val o = KeyguardR43Observation(capture, 1, i + 1L, i + 10L, i + 20L,
                    1000L + i, "TEST", label, 66, false,
                    KeyguardSurfaceClassification(KeyguardSurface.UNKNOWN, KeyguardSurfaceReason.NO_MAIN_MARKER),
                    false, false, false, 2, 3, 2, evidence)
                assertTrue(KeyguardCardDiagnostics.recordR43(context, o))
                KeyguardCardDiagnostics.captureSnapshot(context)
            }
            repeat(6) { attempt ->
                val owner = KeyguardCardDiagnostics.beginLockAttempt(context, 1, (attempt + 1).toLong(), "pressure")
                repeat(400) { index ->
                    KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_QUEUED", "pressure",
                        diagnosticContext = owner, requestId = index.toLong() + 1)
                }
                KeyguardCardDiagnostics.captureSnapshot(context)
            }
            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
            assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32_768)
            labels.forEach { assertTrue("missing hold $it", report.contains("hold=$it")) }
            assertFalse(report.contains("PRIVATE_NOT_A_REAL_RESOURCE"))
            assertFalse(report.contains("ACCOUNT_SECRET"))
            assertTrue(report.contains("labelIsNotAuthority=true"))
            assertEquals(report, KeyguardCardDiagnostics.captureSnapshot(context)["report"])
        } finally {
            KeyguardCardDiagnostics.clearCapture(context)
        }
    }
}
