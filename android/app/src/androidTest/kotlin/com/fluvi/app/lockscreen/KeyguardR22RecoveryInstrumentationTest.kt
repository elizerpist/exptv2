package com.fluvi.app.lockscreen

import android.content.Context
import android.os.Process
import android.os.SystemClock
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

/** Two explicit invocations with a real force-stop between them. The first
 * leaves a frozen report in the production checkpoint; the second requires
 * another process to recover it. This is not a phone or optical test. */
@RunWith(AndroidJUnit4::class)
class KeyguardR22RecoveryInstrumentationTest {
    private val context get() = InstrumentationRegistry.getInstrumentation().targetContext
    private val fixture get() = context.getSharedPreferences("r22_recovery_fixture", Context.MODE_PRIVATE)
    private val settings get() = context.getSharedPreferences("fluvi_native_keyguard_card", Context.MODE_PRIVATE)
    private val durable get() = context.getSharedPreferences("fluvi_native_keyguard_card_diagnostics", Context.MODE_PRIVATE)

    @Test fun prepareFrozenCapture() {
        val args = InstrumentationRegistry.getArguments()
        val source = requireNotNull(args.getString("sourceSha"))
        require(source.matches(Regex("[0-9a-f]{40}")))
        val mode = args.getString("r22Mode") ?: "LIGHT"
        require(mode == "LIGHT" || mode == "FULL")
        check(fixture.edit().clear().putInt("pid", Process.myPid())
            .putBoolean("hadMode", settings.contains("presentationMode"))
            .putString("previousMode", settings.getString("presentationMode", null)).commit())
        check(settings.edit().putString("presentationMode", "orb").commit())
        KeyguardCardDiagnostics.clearCapture(context)
        KeyguardCardDiagnostics.startCapture(context, source, "profile", mode)
        repeat(4) { index ->
            val attempt = index + 1L
            val base = attempt * 10_000L
            val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 91, attempt, "wake", base))
            KeyguardCardDiagnostics.captureEvent(context, "R22_ACQUISITION", "YIELDED",
                diagnosticContext = owner, requestId = base + 1, observedUptimeMs = base + 5,
                fields = mapOf("r22Opening" to base + 1, "r22Reservation" to base + 2,
                    "r22AStart" to base + 2, "r22Scene" to 10, "r22IngressAt" to base + 3,
                    "r22FirstOffer" to base + 4, "r22LatestOffer" to base + 4,
                    "r22Claimed" to base + 4, "r22ClaimAt" to base + 5,
                    "r22AEnd" to base + 5, "r22Why" to "YIELDED", "r22Children" to 0))
        }
        val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        val cores = frozen.lineSequence().filter { it.startsWith(" R22_CORE ") || it.startsWith(" R21_CORE ") }.toList()
        assertEquals(8, cores.size)
        check(fixture.edit().putString("cores", cores.joinToString("\n")).putString("mode", mode).commit())
        val deadline = SystemClock.uptimeMillis() + 15_000
        while (SystemClock.uptimeMillis() < deadline &&
            (durable.getString("timingCapture.state", null) != "FROZEN" ||
                durable.getString("timingCapture.report", null)?.contains(" R22_CORE ") != true)) {
            SystemClock.sleep(25)
        }
        assertEquals("FROZEN", durable.getString("timingCapture.state", null))
        assertTrue(durable.getString("timingCapture.report", null)?.contains(" R22_CORE ") == true)
    }

    @Test fun verifyRecoveredCapture() {
        val originalPid = fixture.getInt("pid", 0)
        assertTrue("a separate real process is required", originalPid > 0 && Process.myPid() != originalPid)
        val expected = requireNotNull(fixture.getString("cores", null))
        try {
            val report = KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String
            assertTrue(report.contains("recoveredFromDisk=true"))
            assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32_768)
            val actual = report.lineSequence().filter { it.startsWith(" R22_CORE ") || it.startsWith(" R21_CORE ") }.joinToString("\n")
            assertEquals("recovered selected cores must retain exact ownership and values", expected, actual)
        } finally {
            KeyguardCardDiagnostics.clearCapture(context)
            val editor = settings.edit()
            if (fixture.getBoolean("hadMode", false)) editor.putString("presentationMode", fixture.getString("previousMode", null))
            else editor.remove("presentationMode")
            check(editor.commit())
            check(fixture.edit().clear().commit())
        }
    }
}
