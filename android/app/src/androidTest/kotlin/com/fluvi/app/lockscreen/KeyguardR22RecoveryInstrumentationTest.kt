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
            val authority = KeyguardInspectionAuthority(91, 2, attempt, 4, 5)
            val queue = KeyguardCardInspectionQueue()
            val gate = KeyguardOpeningInspectionHandoff()
            val token = Any()
            fun request(id: Long, external: Boolean) = KeyguardCardInspectionRequest(
                id, if (external) "window" else "wake", 91, 2, 4, 5, attempt, base,
                diagnosticContext = owner, r14Ingress = if (external) KeyguardR14Ingress(
                    id, true, 10, 0, 32, base + 3, base + 3, KeyguardR14Origin.SYSTEM_UI) else null)
            val opening = request(base + 1, false)
            val claimed = request(base + 4, true)
            val pending = request(base + 8, true)
            val safe = KeyguardOpeningInspectionHandoff.Conditions(
                true, true, true, true, true, true, true, true, true, true)
            queue.offer(opening)
            assertTrue(gate.arm(token, base + 2, opening, authority, 7))
            gate.readStarted(opening, 10, base + 2)
            gate.externalInvalidation(11, base + 3)
            queue.offer(claimed)
            gate.offered(claimed, queue.pendingRequest(), 11, 11, true)
            assertEquals(claimed, gate.claim(queue, opening, token, 7, 11, safe, "beforeChild", base + 5,
                observationCaptureId = owner.captureId))
            gate.readFinished(opening, base + 5)
            val previous = queue.pendingRequest()
            queue.offer(pending)
            val observed = checkNotNull(gate.observePostClaimOffer(
                pending, previous, queue.activeRequest(), queue.pendingRequest(), true))
            KeyguardCardDiagnostics.recordR22PostClaim(observed)
            KeyguardCardDiagnostics.recordR22PostClaim(checkNotNull(gate.successorStarted(claimed, base + 6)))
            KeyguardCardDiagnostics.recordR22PostClaim(checkNotNull(gate.successorFinished(claimed, base + 9)))
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
        for (attempt in 1..4) {
            val row = cores.single { it.startsWith(" R22_CORE ") && it.contains("attempt=$attempt ") }
            assertTrue(row, row.contains("postFirst=${attempt * 10_000L + 8}@"))
            assertTrue(row, row.contains("coverage=FINISHED"))
        }
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
