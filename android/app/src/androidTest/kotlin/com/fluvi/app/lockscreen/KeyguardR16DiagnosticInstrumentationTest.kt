package com.fluvi.app.lockscreen

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.fluvi.app.lockscreen.material.KeyguardOrbSurfaceMetrics
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

/** Typed export/ownership pressure control. It does not synthesize or claim
 * a real transaction receipt or physical presentation. */
@RunWith(AndroidJUnit4::class)
class KeyguardR16DiagnosticInstrumentationTest {
    @Test fun lightAndFullKeepOwnedRetirementAndFreezeItsOwner() {
        val inst = InstrumentationRegistry.getInstrumentation()
        val context = inst.targetContext
        val source = requireNotNull(InstrumentationRegistry.getArguments().getString("sourceSha"))
        val runId = java.util.UUID.fromString(requireNotNull(InstrumentationRegistry.getArguments().getString("runUuid"))).toString()
        val directory = java.io.File(context.filesDir, "keyguard-service-probe/r16/$runId/diagnostics")
        check(directory.mkdirs() || directory.isDirectory)
        for (mode in listOf("LIGHT", "FULL")) {
            KeyguardCardDiagnostics.startCapture(context, source, "profile", mode)
            val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 11, 2, "wake", 100))
            val show = KeyguardCardDiagnostics.newShowOperation(owner, 4, 101)
            KeyguardCardDiagnostics.captureEvent(context, "SHOW_FOR_ATTACH", "wake", operation = show, observedUptimeMs = 105)
            KeyguardCardDiagnostics.captureEvent(context, "ADD_VIEW_RETURN", "wake", operation = show, observedUptimeMs = 106)
            val metrics = KeyguardOrbSurfaceMetrics()
            metrics.r16Created(111, 222, 107)
            metrics.beginHolderOperation(108); metrics.holderLockReturned(109)
            metrics.revokeStarted(110); metrics.revokeReturned(111)
            metrics.r16RetireStarted(112); metrics.r16RetireReturned(113, true)
            metrics.r16RetireCommitted(114, 115)
            metrics.holderDrawReturned(116); metrics.holderPostEntered(117); metrics.holderPostReturned(118)
            metrics.holderRecordObserved(119); metrics.r16PinLateOperation()
            metrics.record(119, 119_000_000, true, 1, 2, 3, 4, 5, 6)
            KeyguardCardDiagnostics.captureEvent(context, "R12_SURFACE", "ROUTE_SELECTED", operation = show,
                observedUptimeMs = 107, fields = mapOf("r12Generation" to 7, "r12Detail" to "SURFACE_LIVE", "r12Privacy" to "full"), surfaceMetrics = metrics)
            val hide = KeyguardCardDiagnostics.newHideOperation(owner, 4, 102, 110)
            KeyguardCardDiagnostics.captureEvent(context, "HIDE_DECIDED", "window", operation = hide, observedUptimeMs = 111)
            KeyguardCardDiagnostics.captureEvent(context, "R15_SURFACE_REVOKED", "r16", operation = hide,
                observedUptimeMs = 113, fields = mapOf("r15TargetAttachment" to 4, "r15Generation" to 7,
                    "r15AtRevoke" to "true:1:108/109:UNOBSERVED:UNOBSERVED/UNOBSERVED:UNOBSERVED"), surfaceMetrics = metrics)
            KeyguardCardDiagnostics.captureEvent(context, "LOCAL_HIDE_BEGIN", "window", operation = hide,
                observedUptimeMs = 114, fields = mapOf("attachedBefore" to true))
            KeyguardCardDiagnostics.captureEvent(context, "LOCAL_HIDE_APPLIED", "window", operation = hide, observedUptimeMs = 115)
            KeyguardCardDiagnostics.captureEvent(context, "REMOVE_VIEW_RETURN", "window", operation = hide, observedUptimeMs = 120)
            repeat(600) { index ->
                KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_QUEUED", "pressure", requestId = 1_000L + index,
                    diagnosticContext = owner, observedUptimeMs = 1_000L + index)
                if (index % 100 == 99) KeyguardCardDiagnostics.captureSnapshot(context)
            }
            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
            java.io.File(directory, "$mode-report.txt").writeText(report)
            val bytes = report.toByteArray(Charsets.UTF_8).size
            assertTrue("$mode export exceeds budget: $bytes", bytes <= 32_768 && report.contains("exportBytes=$bytes\n"))
            assertTrue(report.endsWith("END_FLUVI_KEYGUARD_TIMING_CAPTURE_V1\n"))
            val line = report.lineSequence().firstOrNull { it.startsWith(" R16_LAYER ") }
            assertNotNull("$mode lost the original owned-layer record", line)
            assertTrue(line!!.contains("attach=4") && line.contains("generation=7") && line.contains("host=111 child=222"))
            assertTrue(line.contains("retire=112/113/true") && line.contains("commitReceipt=114") && line.contains("commitMain=115"))
            assertTrue(line.contains("lateOp=1") && line.contains("latePost=117/118") && line.contains("physical=UNOBSERVED"))
            metrics.r16RetireCommitted(999_998, 999_999)
            assertEquals("$mode frozen capture changed after a late receipt", report, KeyguardCardDiagnostics.captureSnapshot(context)["report"])
            KeyguardCardDiagnostics.clearCapture(context)
        }
    }
}
