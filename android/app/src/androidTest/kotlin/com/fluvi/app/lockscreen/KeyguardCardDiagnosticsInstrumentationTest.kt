package com.fluvi.app.lockscreen

import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.fluvi.app.lockscreen.material.KeyguardOrbSurfaceMetrics
import java.io.File
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

    @Test fun r44PerWakeEvidenceSurvivesLightPressure() = r44EvidencePressure("LIGHT")
    @Test fun r44PerWakeEvidenceSurvivesFullPressure() = r44EvidencePressure("FULL")

    @Test fun r446ProtectedSampleEndpointsSurviveLightPressure() = r446Pressure("LIGHT")
    @Test fun r446ProtectedSampleEndpointsSurviveFullPressure() = r446Pressure("FULL")

    @Test fun r447LatestPreIssueDecisionSurvivesLightPressure() = r447LatestDecision("LIGHT")
    @Test fun r447LatestPreIssueDecisionSurvivesFullPressure() = r447LatestDecision("FULL")

    @Test fun r448BoundaryAndVetoSurviveLightPressure() = r448Pressure("LIGHT")
    @Test fun r448BoundaryAndVetoSurviveFullPressure() = r448Pressure("FULL")

    private fun r448Pressure(mode: String) {
        KeyguardCardDiagnostics.startCapture(context, "r448-pressure", "profile", mode,
            r442ExpectedSession = 9448, r446PrintRequested = true)
        val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 9448, 7, "wake", 7000))
        KeyguardCardDiagnostics.captureEvent(context, "SCREEN_ON_RECEIVED", "test",
            diagnosticContext = owner, observedUptimeMs = 7010)
        val boundary = KeyguardR448BoundaryObservation(owner, 5, 7010, 40, null, 40, false,
            KeyguardR448WakeReadBoundary.Decision.OFFER)
        KeyguardCardDiagnostics.recordR448Boundary(boundary)
        KeyguardCardDiagnostics.recordR448Worker(KeyguardR448WorkerObservation(owner, 5, 41, 7011,
            7012, 7030, "COMPLETED", "ELIGIBLE_SAMPLE", true))
        val veto = KeyguardR448SystemVeto(owner, 5, 99, false, "display", 7020, 7021,
            7010, 7040, KeyguardSystemState(7022, 7035, true, true, false, false, true, true, false))
        KeyguardCardDiagnostics.recordR448SystemVeto(veto)
        KeyguardCardDiagnostics.recordR448SystemVeto(veto.copy(requestId = 100, reason = "later"))
        repeat(150) { n -> KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_QUEUED", "pressure",
            diagnosticContext = owner, requestId = 1000L + n, observedUptimeMs = 7100L + n) }
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        val read = report.lineSequence().single { it.startsWith("R44_8_READ_BOUNDARY ") }
        val gate = report.lineSequence().single { it.startsWith("R44_8_SYSTEM_VETO ") }
        assertTrue(read, read.contains("active=40 pending=UNOBSERVED"))
        assertTrue(read, read.contains("boundaryDecision=OFFER workerRequest=41"))
        assertTrue(read, read.contains("workerStart=7012 workerEnd=7030 workerOutcome=COMPLETED"))
        assertTrue(gate, gate.contains("request=99 requestCaptureMatched=false"))
        assertTrue(gate, gate.contains("readStart=7022 readEnd=7035 main=7040"))
        assertTrue(gate, gate.contains("interactive=false") && gate.contains("displayOff=true"))
        assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32_768)
        KeyguardCardDiagnostics.recordR448SystemVeto(veto.copy(requestId = 101))
        assertEquals(report, KeyguardCardDiagnostics.captureSnapshot(context)["report"])
    }

    /** Each observation is a different physical request on the same armed
     * wake. A later failed attempt must not disappear behind the first two. */
    private fun r447LatestDecision(mode: String) {
        KeyguardCardDiagnostics.startCapture(context, "r447-pressure", "profile", mode,
            r442ExpectedSession = 9447, r446PrintRequested = true)
        val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 9447, 3, "wake", 1000))
        KeyguardCardDiagnostics.captureEvent(context, "SCREEN_ON_RECEIVED", "test",
            diagnosticContext = owner, observedUptimeMs = 1010)
        val first = KeyguardR446Observation(owner, 990, 3, 40,
            "UNKNOWN/NO_MAIN_MARKER", "ELIGIBLE_SAMPLE", "NOT_ATTEMPTED", 9, 109,
            null, null, null, null, null, null, "UNOBSERVED")
        KeyguardCardDiagnostics.recordR446(first)
        KeyguardCardDiagnostics.recordR446(first.copy(request = 43, eligibility = "SCENE_CHANGED"))
        KeyguardCardDiagnostics.recordR446(first.copy(request = 44, eligibility = "NEWER_COMPLETED"))
        KeyguardCardDiagnostics.recordR446(first.copy(request = 45, eligibility = "NEWER_BARRIER_REQUIRED"))
        repeat(150) { n -> KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_QUEUED", "pressure",
            diagnosticContext = owner, requestId = 1000L + n, observedUptimeMs = 1100L + n) }
        val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        val row = frozen.lineSequence().single { it.startsWith("R44_6_SAMPLE ") }
        assertTrue(row, row.contains("firstReq=40"))
        assertTrue(row, row.contains("req=45"))
        assertTrue(row, row.contains("eligible=NEWER_BARRIER_REQUIRED"))
        assertTrue(frozen.toByteArray(Charsets.UTF_8).size <= 32_768)
        KeyguardCardDiagnostics.recordR446(first.copy(request = 46, eligibility = "LATE_CALLBACK"))
        assertEquals(frozen, KeyguardCardDiagnostics.captureSnapshot(context)["report"])
    }

    @Test fun r447ProgressAndTerminalRemainWithTheirOriginalRequest() {
        KeyguardCardDiagnostics.startCapture(context, "r447-order", "profile", "FULL",
            r442ExpectedSession = 9448, r446PrintRequested = true)
        val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 9448, 7, "wake", 7000))
        KeyguardCardDiagnostics.captureEvent(context, "SCREEN_ON_RECEIVED", "test",
            diagnosticContext = owner, observedUptimeMs = 7010)
        val first = KeyguardR446Observation(owner, 6990, 7, 40, "UNKNOWN/NO_MAIN_MARKER",
            "ELIGIBLE_SAMPLE", "NOT_ATTEMPTED", 9, 109, null, null, null, null, null, null, "UNOBSERVED",
            armGeneration = 2, decisionOrdinal = 1, handoff = KeyguardR447Disposition.NEWER_BARRIER_REQUIRED)
        val issued = first.copy(request = 44, decisionOrdinal = 2, handoff = KeyguardR447Disposition.ISSUED,
            backend = "SUBMITTED", issuedAt = 7020, attachBegin = 7021, attachEnd = 7022, submittedAt = 7023)
        KeyguardCardDiagnostics.recordR446(first)
        KeyguardCardDiagnostics.recordR446(issued)
        KeyguardCardDiagnostics.recordR446(first.copy(request = 45, decisionOrdinal = 3,
            handoff = KeyguardR447Disposition.ARM_MISMATCH))
        val laterFrame = issued.copy(frameAt = 7024).retireOnce(7050, "restriction", 7051, 7052, null)
        KeyguardCardDiagnostics.recordR446(laterFrame)
        KeyguardCardDiagnostics.recordR446(laterFrame.retireOnce(7090, "duplicate", null, null, null))
        // A callback from a different arm in this same attempt is not allowed
        // to relabel the retained record, even when it has a larger ordinal.
        KeyguardCardDiagnostics.recordR446(first.copy(request = 99, decisionOrdinal = 99, armGeneration = 1))
        val unarmed = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 9448, 8, "wake", 8000))
        KeyguardCardDiagnostics.captureEvent(context, "SCREEN_ON_RECEIVED", "test",
            diagnosticContext = unarmed, observedUptimeMs = 8010)
        KeyguardCardDiagnostics.recordR446(first.copy(context = unarmed, wake = 8, request = 0,
            armGeneration = 0, decisionOrdinal = 0, wakeArmState = "NOT_ARMED"))
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        val rows = report.lineSequence().filter { it.startsWith("R44_6_SAMPLE ") }.toList()
        val row = rows.single { it.contains("wake=7 ") }
        assertTrue(row, row.contains("req=45"))
        assertTrue(row, row.contains("firstEligibleReq=40"))
        assertTrue(row, row.contains("firstEligibleHandoff=NEWER_BARRIER_REQUIRED"))
        assertTrue(row, row.contains("progressReq=44"))
        assertTrue(row, row.contains("frame=7024"))
        assertTrue(row, row.contains("withdraw=7050/restriction"))
        assertTrue(row, row.contains("terminalReq=44"))
        assertTrue(rows.single { it.contains("wake=8 ") }.contains("armState=NOT_ARMED"))
        assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32_768)
    }

    @Test fun r447TerminalBeforeAnyWakeSurvivesFreezeAndLateCleanup() {
        KeyguardCardDiagnostics.startCapture(context, "r447-arm", "profile", "LIGHT",
            r442ExpectedSession = 9449, r446PrintRequested = true)
        val capture = checkNotNull(KeyguardCardDiagnostics.activeCaptureId())
        KeyguardCardDiagnostics.recordR447ArmTerminal(capture, 4, 111, "serviceLost")
        KeyguardCardDiagnostics.recordR447ArmTerminal(capture, 4, 222, "duplicateCleanup")
        val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertTrue(frozen, frozen.contains("R44_7_ARM generation=4 terminal=111/serviceLost"))
        KeyguardCardDiagnostics.recordR447ArmTerminal(capture, 4, 333, "lateCallback")
        assertEquals(frozen, KeyguardCardDiagnostics.captureSnapshot(context)["report"])
    }

    private fun r446Pressure(mode: String) {
        KeyguardCardDiagnostics.startCapture(context, "r446-pressure", "profile", mode,
            r442ExpectedSession = 9446, r446PrintRequested = true)
        var first: KeyguardR446Observation? = null
        repeat(5) { index ->
            val wake = index + 1L; val base = wake * 1000
            val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 9446, wake, "wake", base))
            KeyguardCardDiagnostics.captureEvent(context, "SCREEN_ON_RECEIVED", "test",
                diagnosticContext = owner, observedUptimeMs = base + 10)
            val missing = KeyguardR446Observation(owner, base - 10, wake, base + 1,
                "UNKNOWN/NO_MAIN_MARKER", "HOST_BOUNDS", "NOT_ATTEMPTED", null, 1,
                null, null, null, null, null, null, "UNOBSERVED")
            if (first == null) first = missing
            KeyguardCardDiagnostics.recordR446(missing)
            val submitted = missing.copy(request = base + 2, eligibility = "ELIGIBLE_SAMPLE", backend = "SUBMITTED",
                host = 30, issuedAt = base + 20, attachBegin = base + 21, attachEnd = base + 22,
                submittedAt = base + 23, frameAt = if (index == 0) null else base + 24)
            val shown = submitted.retireOnce(base + 50, "externalWindowTransition", base + 51, base + 52, null)
            assertEquals(shown, shown.retireOnce(base + 90, "captureBoundary", null, null, null))
            KeyguardCardDiagnostics.recordR446(shown)
            repeat(50) { n -> KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_QUEUED", "pressure",
                diagnosticContext = owner, requestId = base + 100 + n, observedUptimeMs = base + 100 + n) }
        }
        val pending = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 9446, 6, "wake", 6000))
        KeyguardCardDiagnostics.captureEvent(context, "SCREEN_ON_RECEIVED", "test",
            diagnosticContext = pending, observedUptimeMs = 6010)
        val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertTrue(frozen.toByteArray(Charsets.UTF_8).size <= 32_768)
        assertEquals(6, frozen.lineSequence().count { it.startsWith("R44_6_SAMPLE ") })
        assertTrue(frozen, frozen.contains("wake=1 arm=990 firstReq=1001 firstNormal=UNKNOWN/NO_MAIN_MARKER firstEligible=HOST_BOUNDS firstBackend=NOT_ATTEMPTED req=1002"))
        assertTrue(frozen, frozen.contains("wake=6 arm=UNOBSERVED firstReq=UNOBSERVED"))
        assertTrue(frozen, frozen.contains("backend=SUBMITTED"))
        assertTrue(frozen, frozen.contains("frame=UNOBSERVED"))
        assertTrue(frozen, frozen.contains("hideReturn=1051 releaseReturn=1052"))
        assertTrue(frozen, frozen.contains("physical=UNOBSERVED"))
        KeyguardCardDiagnostics.recordR446(checkNotNull(first).copy(backend = "LATE_CALLBACK"))
        assertEquals(frozen, KeyguardCardDiagnostics.captureSnapshot(context)["report"])
    }

    @Test fun r444AppliedReasonIsSeparateFromASeparateUpperWindow() {
        KeyguardCardDiagnostics.startCapture(context, "r444-reason", "profile", "LIGHT", r442ExpectedSession = 9444)
        fun add(wake: Long, reason: KeyguardSurfaceReason, complete: Boolean, failed: Int) {
            val base = wake * 1000
            val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 9444, wake, "wake", base))
            KeyguardCardDiagnostics.captureEvent(context, "SCREEN_ON_RECEIVED", "test",
                diagnosticContext = owner, observedUptimeMs = base + 10)
            KeyguardCardDiagnostics.recordR44(KeyguardR44ReadObservation(owner, base + 20, wake, wake,
                base + 11, base + 20, KeyguardSurface.UNKNOWN, KeyguardSurface.UNKNOWN, reason,
                true, false, false, false, false, 969, 0, true,
                KeyguardR44Witness(KeyguardR44Markers.Marker.HOST, KeyguardR44Markers.Carrier.EXTRA_LAZY, 20),
                null, false, complete, 1, 1, failed, 0, false, 2,
                cover = "VETO_UNKNOWN_OR_COVER", receipt = "armed",
                r443Candidates = if (failed > 0) listOf(KeyguardR443CandidateObservation(
                    969, 20, "HOST", 1, "EMPTY", "UNOBSERVED", 2, 6, 48, 3, 1)) else emptyList()))
        }
        add(1, KeyguardSurfaceReason.NO_MAIN_MARKER, true, 0)
        add(2, KeyguardSurfaceReason.WALK_TRUNCATED, false, 1)
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertTrue(report, report.contains("Hiányzik a külön óra- vagy belépési jel"))
        assertTrue(report, report.contains("Üres kiegészítő adat miatt hiányos az olvasás"))
        assertTrue(report, report.contains("további, nem minősített ablak"))
        assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32_768)
    }

    @Test fun r444EightWakeLightSummaryRetainsMissingAndAppliedReasons() = r444Pressure("LIGHT")
    @Test fun r444EightWakeFullSummaryRetainsMissingAndAppliedReasons() = r444Pressure("FULL")

    private fun r444Pressure(mode: String) {
        KeyguardCardDiagnostics.startCapture(context, "r444-pressure", "profile", mode, r442ExpectedSession = 9445)
        repeat(8) { index ->
            val wake = index + 1L
            val base = wake * 1000
            val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 9445, wake, "wake", base))
            KeyguardCardDiagnostics.captureEvent(context, "SCREEN_ON_RECEIVED", "test",
                diagnosticContext = owner, observedUptimeMs = base + 20)
            val missing = index >= 5
            val empty = index % 2 == 1
            val start = if (missing) base + 5 else base + 21
            val candidates = (1..7).map { n -> KeyguardR443CandidateObservation(969, n, "HOST", n,
                if (empty && n == 7) "EMPTY" else "READ", "UNRELATED", n.toLong(), 7 - n, 50L - n, 3, 2) }
            KeyguardCardDiagnostics.recordR44(KeyguardR44ReadObservation(owner, base + 30, wake, wake,
                start, start + 5, KeyguardSurface.UNKNOWN, KeyguardSurface.UNKNOWN,
                if (empty) KeyguardSurfaceReason.WALK_TRUNCATED else KeyguardSurfaceReason.NO_MAIN_MARKER,
                true, false, false, false, false, 969, 0, true,
                KeyguardR44Witness(KeyguardR44Markers.Marker.HOST, KeyguardR44Markers.Carrier.EXTRA_LAZY, 20),
                null, false, !empty, 7, 7, if (empty) 1 else 0, 4, false, 5,
                cover = "VETO_UNKNOWN_OR_COVER", receipt = "armed", r443Candidates = candidates,
                appliedGate = if (empty) KeyguardR444Gate.INCOMPLETE else KeyguardR444Gate.NO_CONTENT,
                profile = "EXPANDED", profileRevision = 5, previousFlags = 48, actualFlags = 50,
                hostNodes = 1, hostCarriers = 5, hostParent = 2, secondaryCount = 1,
                r445SmallInstalled = true, r445LargeInstalled = true, r445EntryInstalled = true,
                r445IndexStatus = "NO_WITNESS", r445IndexCalls = listOf(
                    KeyguardR445IndexCall("SMALL", "EMPTY", 12, 123, 0),
                    KeyguardR445IndexCall("LARGE", "INELIGIBLE", 13, 136, 0),
                    KeyguardR445IndexCall("ENTRY", "EMPTY", 17, 150, 3)),
                r444Windows = listOf(KeyguardR444WindowObservation(972, 0, 3, false, false,
                    "SYSTEMUI", null, true, 4, "UDFPS_NODE_VERIFIED"))))
        }
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32_768)
        assertEquals(8, report.lineSequence().count { it.startsWith("R44_4_HU ") })
        assertEquals(3, report.lineSequence().count { it.startsWith("R44_WAKE ") && it.contains("firstPostRead=missing") })
        assertTrue(report.contains("Hiányzik a külön óra- vagy belépési jel"))
        assertTrue(report.contains("Üres kiegészítő adat miatt hiányos az olvasás"))
        assertTrue(report.contains("további, nem minősített ablak"))
        assertTrue(report.contains("root=UDFPS_NODE_VERIFIED"))
        assertEquals(5, report.lineSequence().count { it.startsWith("R44_5_INDEX ") })
        assertEquals(15, report.lineSequence().count { it.startsWith("R44_5_ID ") })
        assertTrue(report.contains("backend=SENSOR_UNQUALIFIED pixel=UNOBSERVED"))
    }

    @Test fun r442FirstIncompleteReadAndMissingSuccessorRemainExplicit() {
        KeyguardCardDiagnostics.startCapture(context, "r442-fixture", "profile", "LIGHT", r442ExpectedSession = 945)
        val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 945, 7, "wake", 1000))
        KeyguardCardDiagnostics.captureEvent(context, "SCREEN_ON_RECEIVED", "test",
            diagnosticContext = owner, observedUptimeMs = 1020)
        KeyguardCardDiagnostics.recordR442Handoff(KeyguardR442HandoffObservation(
            owner, 1, 3, 1020, 1021, 1005, 1022, 1023, "R442_AFTER_NODE"))
        fun record(id: Long, start: Long, unavailable: Boolean, verdict: KeyguardSurface) =
            KeyguardCardDiagnostics.recordR44(KeyguardR44ReadObservation(owner, id, 1, 1,
                start, start + 5, KeyguardSurface.UNKNOWN, verdict, KeyguardSurfaceReason.NO_MAIN_MARKER,
                true, false, false, unavailable, false, null, null, false, null, null,
                false, false, 0, 0, 0, 0, false, 0, receipt = "armed"))
        record(2, 1024, true, KeyguardSurface.UNKNOWN)
        record(4, 1035, false, KeyguardSurface.MAIN_KEYGUARD)
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertTrue(report.contains("firstPostRead=2"))
        assertTrue(report.contains("kind=firstPost wake=7 req=2"))
        val handoff = report.lineSequence().single { it.startsWith("R44_2_HANDOFF ") }
        assertTrue(handoff, handoff.contains("next=3 "))
        assertTrue(handoff, handoff.contains("newStart=UNOBSERVED newEnd=UNOBSERVED"))
        assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32_768)
        assertEquals(report, report.toByteArray(Charsets.UTF_8).toString(Charsets.UTF_8))
    }

    private fun r44EvidencePressure(mode: String) {
        KeyguardCardDiagnostics.startCapture(context, "r44-fixture", "profile", mode, r442ExpectedSession = 944)
        var firstOwner: KeyguardDiagnosticContext? = null
        repeat(6) { i ->
            val wake = i + 1L
            val base = wake * 1000L
            val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 944, wake, "wake", base))
            if (firstOwner == null) firstOwner = owner
            KeyguardCardDiagnostics.captureEvent(context, "SCREEN_ON_RECEIVED", "test",
                diagnosticContext = owner, observedUptimeMs = base + 20)
            fun record(request: Long, start: Long, verdict: KeyguardSurface) = KeyguardCardDiagnostics.recordR44(
                KeyguardR44ReadObservation(owner, request, wake, wake + 50, start, start + 5,
                    KeyguardSurface.UNKNOWN, verdict,
                    if (verdict == KeyguardSurface.MAIN_KEYGUARD) KeyguardSurfaceReason.MAIN_CONFIRMED else KeyguardSurfaceReason.NO_MAIN_MARKER,
                    true, false, false, false, false, 10, 2, true,
                    KeyguardR44Witness(KeyguardR44Markers.Marker.HOST, KeyguardR44Markers.Carrier.VIEW_ID, 1),
                    KeyguardR44Witness(KeyguardR44Markers.Marker.DEVICE_ENTRY, KeyguardR44Markers.Carrier.EXTRA_EAGER, 2),
                    true, true, 1, 1, 0, 0, false, 2,
                    lookupStatus = "VERIFIED", lookupIdentity = "17000001:1780000000000",
                    shadowVerdict = verdict, shadowReason = KeyguardSurfaceReason.NO_MAIN_MARKER,
                    rawHost = 1, rawEntry = 2, rawClock = 1, rejectedUnverified = 1,
                    rejectedAncestry = 1, rejectedExcluded = 1, rejectedForeign = 1, rejectedHidden = 1,
                    firstCandidate = KeyguardR44Markers.Marker.DEVICE_ENTRY,
                    firstCarrier = KeyguardR44Markers.Carrier.VIEW_ID, cover = "VETO_UNKNOWN_OR_COVER", receipt = "armed",
                    r443Windows = listOf(KeyguardR443WindowObservation(10, 7, 7, 0, true)),
                    r443Candidates = (1..7).map { n -> KeyguardR443CandidateObservation(
                        10, n, "HOST", n, "READ", if (n == 7) "LARGE_CLOCK" else "UNRELATED",
                        n.toLong(), 7 - n, 50L - n, 3, n.toLong()) }))
            KeyguardCardDiagnostics.recordR442Handoff(KeyguardR442HandoffObservation(
                owner, base + 1, base + 2, base + 20, base + 22, base + 10,
                base + 23, base + 24, "R442_AFTER_NODE:3/1/2"))
            KeyguardCardDiagnostics.recordR443Boundary(KeyguardR443BoundaryObservation(
                owner, base + 1, base + 2, base + 20, base + 22, base + 10,
                base + 23, base + 24, "UNRESOLVED_RESTRICTION", "optional", base + 18, base + 22))
            // Exhaust the verbose ring before the first post-screen read.
            repeat(14) { n -> record(base + 500 + n, base + 1 + n, KeyguardSurface.UNKNOWN) }
            record(base + 1, base + 10, KeyguardSurface.UNKNOWN)
            record(base + 2, base + 21, KeyguardSurface.MAIN_KEYGUARD)
            repeat(16) { n -> record(base + 300 + n, base + 60 + n, KeyguardSurface.UNKNOWN) }
            record(base + 400, base + 90, KeyguardSurface.SHADE)
            record(base + 401, base + 95, KeyguardSurface.UNKNOWN)
            val show = KeyguardCardDiagnostics.newShowOperation(owner, wake + 10, base + 2)
            KeyguardCardDiagnostics.captureEvent(context, "SHOW_FOR_ATTACH", "test", operation = show,
                observedUptimeMs = base + 30)
            repeat(40) { n -> KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_QUEUED", "pressure",
                diagnosticContext = owner, requestId = base + 100 + n, observedUptimeMs = base + 50 + n) }
            if (i % 2 == 1) KeyguardCardDiagnostics.captureSnapshot(context)
        }
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32_768)
        for (wake in 1L..6L) {
            val row = report.lineSequence().single { it.startsWith("R44_WAKE ") && it.contains("wake=$wake ") }
            assertTrue(row, row.contains("screenOn=${wake * 1000 + 20}"))
            assertTrue(row, row.contains("firstPostRead=${wake * 1000 + 2}"))
            assertTrue(report, report.contains("R44_2_HANDOFF old=${wake * 1000 + 1} next=${wake * 1000 + 2} "))
            assertTrue(report, report.contains("R44_2_EVIDENCE req=${wake * 1000 + 2} lookup=VERIFIED"))
            assertTrue(report, report.contains("R44_3_JEL req=${wake * 1000 + 2} window=10 ordinal=7"))
            assertTrue(report, report.contains("R44_3_BOUNDARY old=${wake * 1000 + 1}"))
            assertTrue(report, report.contains("kind=firstRestrictionClassification wake=$wake req=${wake * 1000 + 400} "))
        }
        assertEquals(6, report.lineSequence().count { it.startsWith("R44_HU ") })
        assertTrue(report.contains("physicalPixels=UNOBSERVED"))
        val frozen = report
        KeyguardCardDiagnostics.recordR44(KeyguardR44ReadObservation(checkNotNull(firstOwner), 9999, 0, null,
            9999, 10000, KeyguardSurface.UNKNOWN, KeyguardSurface.UNKNOWN, KeyguardSurfaceReason.NO_MAIN_MARKER,
            true, false, false, false, false, null, null, false, null, null, false, false, 0, 0, 0, 0, false, 0))
        assertEquals(frozen, KeyguardCardDiagnostics.captureSnapshot(context)["report"])
    }

    @Test fun r26ExactDirectEvidenceSurvivesLightAndFullPressure() {
        val settings = context.getSharedPreferences("fluvi_native_keyguard_card", android.content.Context.MODE_PRIVATE)
        val hadMode = settings.contains("presentationMode")
        val savedMode = settings.getString("presentationMode", null)
        check(settings.edit().putString("presentationMode", "orb").commit())
        try {
            for (mode in listOf("LIGHT", "FULL")) {
                KeyguardCardDiagnostics.clearCapture(context)
                KeyguardCardDiagnostics.startCapture(context, "r26-pressure", "profile", mode)
                var oldOwner: KeyguardDiagnosticContext? = null
                repeat(8) { i ->
                    val wake = i + 1L; val base = wake * 10_000; val attach = wake + 100
                    val request = base + 7; val reservation = wake + 500
                    val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 926, wake, "wake", base))
                    if (i == 0) oldOwner = owner
                    val identity = mapOf<String, Any>("r18Host" to attach, "r18Output" to wake + 200,
                        "r18ReservationId" to reservation, "r18Privacy" to "full")
                    fun edge(phase: String, at: Long, extra: Map<String, Any> = emptyMap()) {
                        KeyguardCardDiagnostics.captureEvent(context, "R18_PIPELINE", phase,
                            serviceSession = 926, wakeEpoch = wake, requestId = request,
                            attachGeneration = attach, diagnosticContext = owner, observedUptimeMs = at,
                            fields = identity + extra)
                    }
                    edge("WAKE_ADOPTED", base + 1)
                    edge("R19_PROOF_ACCEPTED", base + 2)
                    edge("R20_FIRST_FRAME", base + 3, mapOf("r20Method" to "DIRECT_MISS", "r20EntryNs" to 1001,
                        "r27WarmStatus" to "HIT", "r27WarmSelector" to "dualTide_plain", "r27WarmLoadNs" to 100,
                        "r27WarmQueueNs" to 200, "r27WarmConstructorNs" to 300, "r27WarmOverlap" to false))
                    edge("R19_PROOF_CONSUMED", base + 4)
                    edge("REVEAL_RECEIPT", base + 6, mapOf("r18ApplyBegin" to base + 5,
                        "r18ApplyEnd" to base + 6, "r18Commit" to base + 7))
                    if (wake != 6L) {
                        edge(if (wake == 1L) "R40_UNATTRIBUTED" else "R40_ARMED", base + 7,
                            mapOf("r40Window" to wake + 300, "r40Request" to request + 1))
                        if (wake >= 7L) edge(if (wake == 8L) "R40_REMOVAL_MATCH" else "R40_REMOVAL_FALLBACK", base + 9)
                    }
                    val show = KeyguardCardDiagnostics.newShowOperation(owner, attach, request)
                    KeyguardCardDiagnostics.captureEvent(context, "SHOW_FOR_ATTACH", "wake", operation = show, observedUptimeMs = base + 8)
                    val hide = KeyguardCardDiagnostics.newHideOperation(owner, attach, base + 9, base + 10)
                    KeyguardCardDiagnostics.captureEvent(context, "HIDE_DECIDED", "test", operation = hide, observedUptimeMs = base + 11)
                    KeyguardCardDiagnostics.captureEvent(context, "LOCAL_HIDE_BEGIN", "test", operation = hide,
                        observedUptimeMs = base + 11, fields = mapOf("attachedBefore" to true))
                    KeyguardCardDiagnostics.captureEvent(context, "LOCAL_HIDE_APPLIED", "test", operation = hide, observedUptimeMs = base + 12)
                    KeyguardCardDiagnostics.captureEvent(context, "REMOVE_VIEW_RETURN", "test", operation = hide, observedUptimeMs = base + 13)
                    edge("SEALED:systemSample", base + 11)
                    if (wake != 6L) edge("R26_SYSTEM_SEAL", base + 11, mapOf("r26SystemRequest" to wake + 700,
                        "r26SystemReason" to "screenOff", "r26SystemReceived" to base + 9,
                        "r26SystemStart" to base + 10, "r26SystemEnd" to base + 11))
                    edge("RETIRE_RECEIPT", base + 14, mapOf("r18ApplyBegin" to base + 12,
                        "r18ApplyEnd" to base + 14, "r18Commit" to base + 15))
                    // Same host/output but a contradictory reservation cannot
                    // relabel the old owner's sampler evidence.
                    edge("R26_SYSTEM_SEAL", base + 20, mapOf("r18ReservationId" to reservation + 1000,
                        "r26SystemRequest" to 9999, "r26SystemReason" to "wrong"))
                    repeat(90) { n ->
                        KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_QUEUED", "pressure",
                            diagnosticContext = owner, observedUptimeMs = base + 100 + n, requestId = base + 1000 + n)
                        if (n % 30 == 29) KeyguardCardDiagnostics.captureSnapshot(context)
                    }
                }
                val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
                assertTrue(frozen.toByteArray(Charsets.UTF_8).size <= 32_768)
                val rows = frozen.lineSequence().filter { it.startsWith(" R26_DIRECT ") }.toList()
                assertEquals("$mode requires first and latest-three records", 4, rows.size)
                for (wake in listOf(1L, 6L, 7L, 8L)) {
                    val base = wake * 10_000
                    val row = rows.single { it.contains("attempt=$wake ") }
                    assertTrue(row, row.contains("owner=${wake + 500}/${wake + 100}/${wake + 200}/${wake + 100}"))
                    assertTrue(row, row.contains("accepted=${base + 7}@${base + 2}"))
                    assertTrue(row, row.contains("warm=HIT/dualTide_plain warmNs=100/200/300 overlap=false"))
                    assertTrue(row, row.contains("consumed=${base + 7}@${base + 4} showing=${base + 7}/"))
                    assertTrue(row, row.contains("localRemove=${base + 12}/${base + 13}"))
                    val witness = when (wake) {
                        1L -> "witness=UNATTRIBUTED/1/301/${base + 8}"
                        6L -> "witness=UNOBSERVED/UNOBSERVED/UNOBSERVED/UNOBSERVED"
                        else -> "witness=ARMED/1/${wake + 300}/${base + 8}"
                    }
                    assertTrue(row, row.contains(witness))
                    if (wake == 7L) assertTrue(row, row.contains("removal=UNOBSERVED/1"))
                    if (wake == 8L) assertTrue(row, row.contains("removal=1/UNOBSERVED"))
                    assertTrue(row, row.contains(if (wake == 6L) "sample=UNOBSERVED/UNOBSERVED@" else
                        "sample=${wake + 700}/screenOff@${base + 9}/${base + 10}/${base + 11}"))
                    assertFalse(row, row.contains("9999/wrong"))
                    assertTrue(row, row.contains("physicalFirstPixel=UNOBSERVED physicalLastPixel=UNOBSERVED"))
                }
                KeyguardCardDiagnostics.captureEvent(context, "R18_PIPELINE", "R26_SYSTEM_SEAL", diagnosticContext = oldOwner,
                    fields = mapOf("r18Host" to 101, "r18Output" to 201, "r18ReservationId" to 501, "r26SystemRequest" to 9999))
                assertEquals(frozen, KeyguardCardDiagnostics.captureSnapshot(context)["report"])
            }
        } finally {
            KeyguardCardDiagnostics.clearCapture(context)
            val edit = settings.edit()
            if (hadMode) edit.putString("presentationMode", savedMode) else edit.remove("presentationMode")
            check(edit.commit())
        }
    }

    @Test fun r25OpeningSummarySurvivesLightPressureAndCaptureRotation() = r25OpeningSummary("LIGHT")
    @Test fun r25OpeningSummarySurvivesFullPressureAndCaptureRotation() = r25OpeningSummary("FULL")

    private fun r25OpeningSummary(mode: String) {
        KeyguardCardDiagnostics.startCapture(context, "r25-fixture", "profile", mode)
        val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 925, 7, "wake", 100))
        fun event(phase: String, original: Long, successor: Long?, at: Long, end: Long) {
            KeyguardCardDiagnostics.captureEvent(context, "R25_OPENING", phase, requestId = original,
                diagnosticContext = owner, observedUptimeMs = at,
                fields = mapOf("r25Original" to original, "r25Successor" to (successor ?: "UNOBSERVED"),
                    "r25Backend" to "STOCK", "r25ReadEnd" to end, "r25Reason" to "OFFER_BEFORE_CLAIM",
                    "r25SuccessorQueued" to (successor?.plus(200) ?: "UNOBSERVED"),
                    "r25ReaderHigh" to 1, "r25TicketHigh" to 1))
        }
        event("PARKED", 10, null, 110, 109)
        event("POST_REQUESTED", 10, null, 111, 109)
        event("SUPERSEDED", 10, 11, 112, 109)
        KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_STARTED", "window", requestId = 11,
            diagnosticContext = owner, observedUptimeMs = 113)
        KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_FINISHED", "MAIN_CONFIRMED", requestId = 11,
            diagnosticContext = owner, observedUptimeMs = 114)
        event("SUPERSEDED", 11, 12, 115, 114)
        KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_STARTED", "window", requestId = 12,
            diagnosticContext = owner, observedUptimeMs = 116)
        KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_FINISHED", "MAIN_CONFIRMED", requestId = 12,
            diagnosticContext = owner, observedUptimeMs = 117)
        event("MAIN_CLAIM", 12, null, 118, 117)
        repeat(800) { index ->
            KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_QUEUED", "pressure", requestId = 1000L + index,
                diagnosticContext = owner, observedUptimeMs = 300L + index)
            if (index % 80 == 79) KeyguardCardDiagnostics.captureSnapshot(context)
        }
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        val row = report.lineSequence().single { it.startsWith(" R25_CORE ") }
        assertTrue(row, row.contains("session=925 wake=7") && row.contains("backend=STOCK"))
        assertTrue(row, row.contains("first=10@109->11@211/112/113/114/OFFER_BEFORE_CLAIM"))
        assertTrue(row, row.contains("last=11@114->12@212/115/116/117/OFFER_BEFORE_CLAIM"))
        assertTrue(row, row.contains("supersessions=2") && row.contains("physical=UNOBSERVED"))
        assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32_768)
        event("SUPERSEDED", 90, 91, 2000, 1999)
        assertEquals(report, KeyguardCardDiagnostics.captureSnapshot(context)["report"])
        KeyguardCardDiagnostics.startCapture(context, "r25-new", "profile", mode)
        KeyguardCardDiagnostics.beginLockAttempt(context, 926, 8, "wake", 2100)
        event("SUPERSEDED", 90, 91, 2101, 2100)
        val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertFalse(next.contains("->91@"))
    }

    @Test fun r224RestrictionEvidenceSurvivesLightPressureAndRestart() = r224RestrictionEvidence("LIGHT")
    @Test fun r224RestrictionEvidenceSurvivesFullPressureAndRestart() = r224RestrictionEvidence("FULL")

    private fun r224RestrictionEvidence(mode: String) {
        KeyguardCardDiagnostics.startCapture(context, "r22-4", "profile", mode)
        val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 924, 1, "wake", 100))
        val show = KeyguardCardDiagnostics.newShowOperation(owner, 11, 22)
        val hide = KeyguardCardDiagnostics.newHideOperation(owner, 11, 23, 160)
        KeyguardCardDiagnostics.captureEvent(context, "SHOW_FOR_ATTACH", "show", operation = show, observedUptimeMs = 110)
        val facts = mapOf("root" to 123, "generation" to 7, "child" to 456,
            "oldFirstSlot" to 1, "oldFirstUse" to 8, "oldFirstSubmit" to 119,
            "oldLastSubmit" to "UNOBSERVED", "revoke" to 121, "hideSubmit" to 122,
            "hideReturn" to 123, "hideApplied" to true, "localHide" to "UNOBSERVED",
            "bind" to "OK", "layout" to "FAILED", "outcome" to "FAILED")
        KeyguardCardDiagnostics.captureEvent(context, "R22_4_TRANSITION", "DOWNGRADE", operation = show,
            observedUptimeMs = 120, fields = facts)
        KeyguardCardDiagnostics.captureEvent(context, "HIDE_DECIDED", "hide", operation = hide, observedUptimeMs = 160)
        KeyguardCardDiagnostics.captureEvent(context, "R22_4_TRANSITION", "HIDE", operation = hide,
            observedUptimeMs = 161, fields = facts + mapOf("localHide" to 162, "outcome" to "REMOVED"))
        repeat(600) { n ->
            KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_QUEUED", "pressure", diagnosticContext = owner,
                requestId = 1000L + n, observedUptimeMs = 200L + n)
        }
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32_768)
        val rows = report.lineSequence().filter { it.startsWith(" R22_4_TRANSITION ") }.toList()
        assertEquals("$mode transition records must survive raw-ring pressure", 2, rows.size)
        assertTrue(rows[0], rows[0].contains("kind=DOWNGRADE") && rows[0].contains("root=123 generation=7 child=456"))
        assertTrue(rows[0], rows[0].contains("first=1/8@119 lastSubmit=UNOBSERVED ingress=120 revoke=121"))
        assertTrue(rows[0], rows[0].contains("bind=OK layout=FAILED outcome=FAILED"))
        assertTrue(rows[1], rows[1].contains("kind=HIDE") && rows[1].contains("localHide=162"))
        KeyguardCardDiagnostics.captureEvent(context, "R22_4_TRANSITION", "LATE", operation = show,
            observedUptimeMs = 1000, fields = facts)
        assertEquals(report, KeyguardCardDiagnostics.captureSnapshot(context)["report"])
        KeyguardCardDiagnostics.startCapture(context, "r22-4-new", "profile", mode)
        KeyguardCardDiagnostics.beginLockAttempt(context, 925, 1, "wake", 2000)
        KeyguardCardDiagnostics.captureEvent(context, "R22_4_TRANSITION", "OLD_OWNER", operation = show,
            observedUptimeMs = 2001, fields = facts)
        val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertFalse(next.contains("kind=OLD_OWNER"))
    }

    @Test fun r22PassiveStandbySummarySurvivesLightExport() = passiveStandbyExport("LIGHT")
    @Test fun r22PassiveStandbySummarySurvivesFullExport() = passiveStandbyExport("FULL")

    private fun passiveStandbyExport(mode: String) {
        KeyguardCardDiagnostics.startCapture(context, "r22-2", "profile", mode)
        val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 901, 1, "wake", 100))
        val show = KeyguardCardDiagnostics.newShowOperation(owner, 11, 22)
        val hide = KeyguardCardDiagnostics.newHideOperation(owner, 11, 23, 150)
        KeyguardCardDiagnostics.captureEvent(context, "SHOW_FOR_ATTACH", "show", operation = show, observedUptimeMs = 110)
        KeyguardCardDiagnostics.captureEvent(context, "ADD_VIEW_RETURN", "added", operation = show, observedUptimeMs = 111)
        KeyguardCardDiagnostics.captureEvent(context, "HIDE_DECIDED", "hide", operation = hide, observedUptimeMs = 150)
        KeyguardCardDiagnostics.captureEvent(context, "REMOVE_VIEW_RETURN", "removed", operation = hide, observedUptimeMs = 151)
        val fact = "backend:ISOLATED,eligible:DISARMED,lease:11/7,draw:121,exit:privacy"
        KeyguardCardDiagnostics.captureEvent(context, "ATTACHMENT_RENDER_SUMMARY", "withdrawal", operation = hide,
            observedUptimeMs = 152, fields = mapOf("r22Passive" to fact, "isolatedTranslucentSteadySkipped" to 17))
        repeat(250) { index ->
            KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_QUEUED", "pressure", diagnosticContext = owner,
                observedUptimeMs = 200L + index, requestId = 1000L + index)
        }
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertTrue("$mode export exceeded its UTF-8 budget", report.toByteArray(Charsets.UTF_8).size <= 32_768)
        assertTrue("missing explicitly named omission metadata", report.contains("omittedPassiveStandbyRecordIds="))
        assertTrue("exact attachment's standby record must survive or name its omission",
            report.contains("r22Passive=$fact") || !report.contains("omittedPassiveStandbyRecordIds=none"))
        assertTrue("translucent tick count must be retained or its episode explicitly omitted",
            report.contains("isolatedTranslucentSteadySkipped=17") || !report.contains("omittedPassiveStandbyRecordIds=none"))
    }

    @Test fun r22PostClaimQueueEvidenceSurvivesLightPressureAndFreeze() = r22PostClaimQueueEvidence("LIGHT")
    @Test fun r22PostClaimQueueEvidenceSurvivesFullPressureAndFreeze() = r22PostClaimQueueEvidence("FULL")

    /** This boundary uses real queue offers and the production observer; it
     * does not synthesize an Android window or a visibility decision. */
    private fun r22PostClaimQueueEvidence(mode: String) {
        val settings = context.getSharedPreferences("fluvi_native_keyguard_card", android.content.Context.MODE_PRIVATE)
        val hadMode = settings.contains("presentationMode")
        val savedMode = settings.getString("presentationMode", null)
        check(settings.edit().putString("presentationMode", "orb").commit())
        try {
        KeyguardCardDiagnostics.startCapture(context, "r22-1", "profile", mode)
        val oldSnapshots = mutableListOf<KeyguardOpeningInspectionHandoff.PostClaimSnapshot>()
        for (wake in 1L..8L) {
            val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 778, wake, "wake", wake * 1000))
            val authority = KeyguardInspectionAuthority(778, 2, wake, 4, 5)
            val queue = KeyguardCardInspectionQueue()
            val gate = KeyguardOpeningInspectionHandoff()
            val token = Any()
            val safe = KeyguardOpeningInspectionHandoff.Conditions(
                true, true, true, true, true, true, true, true, true, true)
            fun req(id: Long, external: Boolean) = KeyguardCardInspectionRequest(
                id, if (external) "window" else "wake", 778, 2, 4, 5, wake, wake * 1000,
                diagnosticContext = owner, r14Ingress = if (external) KeyguardR14Ingress(
                    id, true, 10, 0, 32, wake * 1000, wake * 1000, KeyguardR14Origin.SYSTEM_UI) else null)
            val a = req(wake * 1000 + 1, false)
            val b = req(wake * 1000 + 2, true)
            val c = req(wake * 1000 + 3, true)
            queue.offer(a)
            assertTrue(gate.arm(token, 700 + wake, a, authority, 7))
            gate.readStarted(a, 10, wake * 1000 + 1)
            gate.externalInvalidation(11, wake * 1000 + 2)
            queue.offer(b)
            gate.offered(b, queue.pendingRequest(), 11, 11, true)
            assertEquals(b, gate.claim(queue, a, token, 7, 11, safe, "beforeChild", wake * 1000 + 3,
                observationCaptureId = owner.captureId))
            gate.readFinished(a, wake * 1000 + 4)
            val previous = queue.pendingRequest()
            queue.offer(c)
            val first = checkNotNull(gate.observePostClaimOffer(c, previous, queue.activeRequest(), queue.pendingRequest(), true))
            KeyguardCardDiagnostics.recordR22PostClaim(first)
            // A later ordinal from a different authority or reservation is
            // never allowed to evict this capture's actual owner.
            KeyguardCardDiagnostics.recordR22PostClaim(first.copy(
                authority = first.authority.copy(visibilityEpoch = 999), ordinal = Long.MAX_VALUE))
            KeyguardCardDiagnostics.recordR22PostClaim(first.copy(
                reservationId = first.reservationId + 1000, ordinal = Long.MAX_VALUE))
            oldSnapshots += first
            if (wake < 8) {
                val started = checkNotNull(gate.successorStarted(b, wake * 1000 + 5))
                KeyguardCardDiagnostics.recordR22PostClaim(started)
                val closed = checkNotNull(gate.successorFinished(b, wake * 1000 + 6))
                KeyguardCardDiagnostics.recordR22PostClaim(closed)
                // A delayed older update must not replace the closed result.
                KeyguardCardDiagnostics.recordR22PostClaim(first)
            }
            repeat(180) { index ->
                KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_QUEUED", "pressure",
                    diagnosticContext = owner, requestId = wake * 1000 + 100 + index,
                    observedUptimeMs = wake * 1000 + 100 + index)
                if (index % 45 == 44) KeyguardCardDiagnostics.captureSnapshot(context)
            }
        }
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertTrue("$mode export exceeded 32 KiB", report.toByteArray(Charsets.UTF_8).size <= 32_768)
        for (wake in listOf(1L, 6L, 7L, 8L)) {
            val row = report.lineSequence().single { it.startsWith(" R22_CORE ") && it.contains("attempt=$wake ") }
            assertTrue(row, row.contains("opening=${wake * 1000 + 1}/${700 + wake}"))
            assertTrue(row, row.contains("claimed=${wake * 1000 + 2}@"))
            assertTrue(row, row.contains("postFirst=${wake * 1000 + 3}@"))
            assertTrue(row, row.contains("postCount=1/0"))
            assertTrue(row, row.contains(if (wake < 8) "coverage=FINISHED" else "coverage=INCOMPLETE_OPEN"))
        }
        KeyguardCardDiagnostics.recordR22PostClaim(oldSnapshots.first())
        assertEquals(report, KeyguardCardDiagnostics.captureSnapshot(context)["report"])
        KeyguardCardDiagnostics.startCapture(context, "new", "profile", mode)
        KeyguardCardDiagnostics.beginLockAttempt(context, 779, 1, "wake", 20_000)
        KeyguardCardDiagnostics.recordR22PostClaim(oldSnapshots.first())
        val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertFalse(next.contains("postFirst=1003@"))
        } finally {
            val editor = settings.edit()
            if (hadMode) editor.putString("presentationMode", savedMode) else editor.remove("presentationMode")
            check(editor.commit())
        }
    }

    @Test fun r31FollowOnEvidenceSurvivesLightPressure() = r31FollowOnEvidence("LIGHT")
    @Test fun r31FollowOnEvidenceSurvivesFullPressure() = r31FollowOnEvidence("FULL")

    private fun r31FollowOnEvidence(mode: String) {
        val settings = context.getSharedPreferences("fluvi_native_keyguard_card", android.content.Context.MODE_PRIVATE)
        val hadMode = settings.contains("presentationMode")
        val savedMode = settings.getString("presentationMode", null)
        check(settings.edit().putString("presentationMode", "orb").commit())
        try {
            KeyguardCardDiagnostics.startCapture(context, "r31", "profile", mode)
            var old: KeyguardOpeningInspectionHandoff.PostClaimSnapshot? = null
            repeat(4) { index ->
                val wake = index + 1L; val base = wake * 1000
                val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 778, wake, "wake", base))
                val authority = KeyguardInspectionAuthority(778, 2, wake, 4, 5)
                val queue = KeyguardCardInspectionQueue(); val gate = KeyguardOpeningInspectionHandoff(); val token = Any()
                val safe = KeyguardOpeningInspectionHandoff.Conditions(true, true, true, true, true,
                    true, true, true, true, true, virginDirect = true, noRetainedProof = true)
                fun req(id: Long, external: Boolean) = KeyguardCardInspectionRequest(id,
                    if (external) "window" else "wake", 778, 2, 4, 5, wake, base,
                    diagnosticContext = owner, r14Ingress = if (external) KeyguardR14Ingress(id, true, 10, 0,
                        32, base, base, KeyguardR14Origin.SYSTEM_UI) else null)
                val a = req(base + 1, false); val b = req(base + 2, true); val c = req(base + 3, true)
                queue.offer(a); assertTrue(gate.arm(token, 700 + wake, a, authority, 7))
                gate.readStarted(a, 10, base + 1); gate.externalInvalidation(11, base + 2)
                queue.offer(b); gate.offered(b, queue.pendingRequest(), 11, 11, true)
                assertEquals(b, gate.claim(queue, a, token, 7, 11, safe, "beforeChild", base + 3,
                    observationCaptureId = owner.captureId))
                gate.readFinished(a, base + 4)
                gate.successorStarted(b, base + 5)?.let(KeyguardCardDiagnostics::recordR22PostClaim)
                gate.followReadStarted(queue, b, 11, base + 6)
                gate.externalInvalidation(12, base + 7); val previous = queue.pendingRequest(); queue.offer(c)
                gate.offered(c, queue.pendingRequest(), 12, 12, true, previous)
                gate.observePostClaimOffer(c, previous, queue.activeRequest(), queue.pendingRequest(), true)
                    ?.let(KeyguardCardDiagnostics::recordR22PostClaim)
                val handle = checkNotNull(gate.followHandle(b))
                assertEquals(c, gate.claimFollow(queue, handle, token, 7, 12, safe, "beforeChild", base + 8, 1))
                gate.successorFinished(b, base + 9, "YIELDED_TO_C")
                old = checkNotNull(gate.followReadFinished(b, base + 10, base + 8, "YIELDED_TO_C"))
                KeyguardCardDiagnostics.recordR22PostClaim(checkNotNull(old))
                gate.followCObservation(c, base + 11, null)?.let(KeyguardCardDiagnostics::recordR22PostClaim)
                gate.followCObservation(c, base + 12, "SHOW_FULL/MAIN_CONFIRMED/false/false/false")
                    ?.let(KeyguardCardDiagnostics::recordR22PostClaim)
                repeat(100) { n ->
                    KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_QUEUED", "pressure", diagnosticContext = owner,
                        requestId = base + 100 + n, observedUptimeMs = base + 100 + n)
                    if (n % 40 == 39) KeyguardCardDiagnostics.captureSnapshot(context)
                }
            }
            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
            assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32_768)
            for (wake in 1L..4L) {
                val row = report.lineSequence().single { it.startsWith(" R22_CORE ") && it.contains("attempt=$wake ") }
                assertTrue(row, row.contains("opening=${wake * 1000 + 1}/${700 + wake}"))
                assertTrue(row, row.contains("claimed=${wake * 1000 + 2}@"))
                assertTrue(row, row.contains("transfer=YIELDED_TO_C/${wake * 1000 + 3}/"))
                assertTrue(row, row.contains("c=${wake * 1000 + 11}/${wake * 1000 + 12}/SHOW_FULL"))
            }
            KeyguardCardDiagnostics.recordR22PostClaim(checkNotNull(old))
            assertEquals(report, KeyguardCardDiagnostics.captureSnapshot(context)["report"])
            KeyguardCardDiagnostics.startCapture(context, "r31-next", "profile", mode)
            KeyguardCardDiagnostics.beginLockAttempt(context, 779, 1, "wake", 20_000)
            KeyguardCardDiagnostics.recordR22PostClaim(checkNotNull(old))
            val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
            assertFalse(next.contains("YIELDED_TO_C/4003"))
        } finally {
            val editor = settings.edit()
            if (hadMode) editor.putString("presentationMode", savedMode) else editor.remove("presentationMode")
            check(editor.commit())
        }
    }

    @Test fun r32OverlapEvidenceSurvivesLightPressure() = r32OverlapEvidence("LIGHT")
    @Test fun r32OverlapEvidenceSurvivesFullPressure() = r32OverlapEvidence("FULL")

    private fun r32OverlapEvidence(mode: String) {
        val settings = context.getSharedPreferences("fluvi_native_keyguard_card", android.content.Context.MODE_PRIVATE)
        val hadMode = settings.contains("presentationMode")
        val savedMode = settings.getString("presentationMode", null)
        check(settings.edit().putString("presentationMode", "orb").commit())
        try {
            KeyguardCardDiagnostics.startCapture(context, "r32", "profile", mode)
            var old: KeyguardDiagnosticContext? = null
            repeat(4) { index ->
                val wake = index + 1L; val base = wake * 1000
                val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 778, wake, "wake", base))
                old = owner
                fun edge(phase: String, at: Long, extra: Map<String, Any?> = emptyMap()) {
                    KeyguardCardDiagnostics.captureEvent(context, "R32_OVERLAP", phase,
                        diagnosticContext = owner, requestId = base + 1, observedUptimeMs = at,
                        fields = mapOf("r32A" to base + 1, "r32B" to base + 2,
                            "r32Reservation" to 700 + wake, "r32ReadScene" to 10, "r32CurrentScene" to 11,
                            "r32Reserve" to base + 1, "r32Backend" to "R18_DIRECT") + extra)
                }
                edge("RESERVED", base + 1)
                edge("B_READ_START", base + 2)
                edge("A_MAIN_ENTER", base + 3)
                edge("B_READ_END", base + 4, mapOf("r32C" to base + 3, "r32BScene" to 11, "r32Outcome" to "SHOW_FULL"))
                edge("A_MAIN_EXIT", base + 5, mapOf("r32Outcome" to "RESTRICTION_ONLY"))
                edge("B_REJECTED", base + 6, mapOf("r32Outcome" to "REVALIDATION"))
                repeat(100) { n ->
                    KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_QUEUED", "pressure", diagnosticContext = owner,
                        requestId = base + 100 + n, observedUptimeMs = base + 100 + n)
                    if (n % 40 == 39) KeyguardCardDiagnostics.captureSnapshot(context)
                }
            }
            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
            assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32_768)
            for (wake in 1L..4L) {
                val row = report.lineSequence().single { it.startsWith(" R32_CORE ") && it.contains("attempt=$wake ") }
                val base = wake * 1000
                assertTrue(row, row.contains("pair=${base + 1}/${base + 2}/${base + 3} reservation=${700 + wake}"))
                assertTrue(row, row.contains("aMain=${base + 3}/${base + 5}/RESTRICTION_ONLY"))
                assertTrue(row, row.contains("bRead=${base + 2}/${base + 4}/SHOW_FULL"))
                assertTrue(row, row.contains("physical=UNOBSERVED"))
            }
            KeyguardCardDiagnostics.captureEvent(context, "R32_OVERLAP", "B_MAIN_PATH", diagnosticContext = old,
                requestId = 4001, observedUptimeMs = 4999, fields = mapOf("r32A" to 4001, "r32B" to 4002,
                    "r32Reservation" to 704, "r32Outcome" to "LATE"))
            assertEquals(report, KeyguardCardDiagnostics.captureSnapshot(context)["report"])
            KeyguardCardDiagnostics.startCapture(context, "r32-next", "profile", mode)
            KeyguardCardDiagnostics.beginLockAttempt(context, 779, 1, "wake", 20_000)
            KeyguardCardDiagnostics.captureEvent(context, "R32_OVERLAP", "B_MAIN_PATH", diagnosticContext = old,
                requestId = 4001, observedUptimeMs = 4999, fields = mapOf("r32A" to 4001, "r32B" to 4002,
                    "r32Reservation" to 704, "r32Outcome" to "LATE"))
            val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
            assertFalse(next.contains("pair=4001/4002"))
        } finally {
            val editor = settings.edit()
            if (hadMode) editor.putString("presentationMode", savedMode) else editor.remove("presentationMode")
            check(editor.commit())
        }
    }

    @Test fun r34CoreSurvivesLightPressureAndFreeze() = r34CoreEvidence("LIGHT")
    @Test fun r34CoreSurvivesFullPressureAndFreeze() = r34CoreEvidence("FULL")

    private fun r34CoreEvidence(mode: String) {
        val settings = context.getSharedPreferences("fluvi_native_keyguard_card", android.content.Context.MODE_PRIVATE)
        val hadMode = settings.contains("presentationMode")
        val savedMode = settings.getString("presentationMode", null)
        check(settings.edit().putString("presentationMode", "orb").commit())
        try {
            KeyguardCardDiagnostics.startCapture(context, "r34", "profile", mode)
            var old: KeyguardDiagnosticContext? = null
            repeat(4) { index ->
                val wake = index + 1L; val base = wake * 1000L; val reservation = 700 + wake
                val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 778, wake, "wake", base))
                old = owner
                KeyguardCardDiagnostics.captureEvent(context, "R18_PIPELINE", "R19_POSTER",
                    diagnosticContext = owner, requestId = base + 1, attachGeneration = wake,
                    observedUptimeMs = base + 10, fields = mapOf("r18Host" to 10 + wake, "r18Output" to 20 + wake,
                        "r18ReservationId" to reservation, "r19Poster" to "R34_PRIVATE_COMPOSITOR_READY",
                        "r34AssetGeneration" to 80 + wake, "r34PrepareStart" to base - 20, "r34Ready" to base - 10))
                fun edge(phase: String, request: Long, at: Long, next: Any, outcome: String) {
                    KeyguardCardDiagnostics.captureEvent(context, "R34_OPENING", phase, diagnosticContext = owner,
                        requestId = request, observedUptimeMs = at, fields = mapOf(
                            "r34Request" to request, "r34Next" to next, "r34Reservation" to reservation,
                            "r34Host" to 10 + wake, "r34Output" to 20 + wake, "r34Scene" to 10,
                            "r34Inventory" to base + 1, "r34Start" to base, "r34End" to at,
                            "r34Outcome" to outcome, "r34ReaderHigh" to 1))
                }
                edge("TRANSFER", base + 1, base + 3, base + 2, "SAFE_CHILD")
                edge("READ_END", base + 2, base + 6, "UNOBSERVED", "SHOW_FULL")
                repeat(100) { n ->
                    KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_QUEUED", "pressure", diagnosticContext = owner,
                        requestId = base + 100 + n, observedUptimeMs = base + 100 + n)
                    if (n % 40 == 39) KeyguardCardDiagnostics.captureSnapshot(context)
                }
            }
            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
            assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32_768)
            for (wake in 1L..4L) {
                val base = wake * 1000L
                val row = report.lineSequence().single { it.startsWith(" R34_CORE ") && it.contains("attempt=$wake ") }
                assertTrue(row, row.contains("reservation=${700 + wake}"))
                assertTrue(row, row.contains("asset=${80 + wake}"))
                assertTrue(row, row.contains("readyBeforeWake=true"))
                assertTrue(row, row.contains("last=TRANSFER/${base + 1}->${base + 2}"))
                assertTrue(row, row.contains("firstFull=${base + 2}@${base + 6}"))
                assertTrue(row, row.contains("physicalFirst=UNOBSERVED physicalLast=UNOBSERVED"))
            }
            KeyguardCardDiagnostics.captureEvent(context, "R34_OPENING", "TRANSFER", diagnosticContext = old,
                requestId = 4001, observedUptimeMs = 4999, fields = mapOf("r34Request" to 4001, "r34Reservation" to 704))
            assertEquals(report, KeyguardCardDiagnostics.captureSnapshot(context)["report"])
            KeyguardCardDiagnostics.startCapture(context, "r34-next", "profile", mode)
            KeyguardCardDiagnostics.beginLockAttempt(context, 779, 1, "wake", 20_000)
            KeyguardCardDiagnostics.captureEvent(context, "R34_OPENING", "TRANSFER", diagnosticContext = old,
                requestId = 4001, observedUptimeMs = 4999, fields = mapOf("r34Request" to 4001, "r34Reservation" to 704))
            assertFalse((KeyguardCardDiagnostics.freezeCapture(context)["report"] as String).contains("reservation=704"))
        } finally {
            val editor = settings.edit()
            if (hadMode) editor.putString("presentationMode", savedMode) else editor.remove("presentationMode")
            check(editor.commit())
        }
    }

    @Test fun r18PipelineEvidenceRemainsBoundedAndOwnedInLight() = r18PipelineEvidence("LIGHT")
    @Test fun r18PipelineEvidenceRemainsBoundedAndOwnedInFull() = r18PipelineEvidence("FULL")

    private fun r18PipelineEvidence(mode: String) {
        KeyguardCardDiagnostics.clearCapture(context)
        assertFalse(KeyguardCardDiagnostics.wantsEvent("R18_PIPELINE"))
        KeyguardCardDiagnostics.startCapture(context, "r18-$mode", "profile", mode)
        var oldOwner: KeyguardDiagnosticContext? = null
        repeat(4) { wake ->
            val base = 10_000L * (wake + 1)
            val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 51, wake + 1L, "wake", base))
            if (wake == 0) oldOwner = owner
            fun edge(phase: String, at: Long, host: Int = wake + 1, output: Int = wake + 20,
                     extra: Map<String, Any> = emptyMap()) {
                KeyguardCardDiagnostics.captureEvent(context, "R18_PIPELINE", phase,
                    serviceSession = 51, wakeEpoch = wake + 1L, requestId = base + 1,
                    attachGeneration = wake + 1L, diagnosticContext = owner, observedUptimeMs = at,
                    fields = mapOf<String, Any>("r18Host" to host, "r18Output" to output,
                        "r18Child" to (900 + output), "r18Privacy" to "discreet") + extra)
            }
            edge("WAKE_ADOPTED", base, extra = mapOf("r18SampleStart" to base - 2, "r18SampleEnd" to base - 1,
                "r18AlignUptime" to base, "r18AlignNano" to base * 1_000_000, "r18AlignUncertaintyNs" to 1_000_100))
            edge("HOST_ADDED", base + 1); edge("HOST_READY", base + 2); edge("BUFFER_READY", base + 3)
            edge("HIDDEN_BOUND", base + 4); edge("GRANT", base + 5, extra = mapOf("r18Proof" to base + 77))
            val show = KeyguardCardDiagnostics.newShowOperation(owner, wake + 1L, base + 77)
            KeyguardCardDiagnostics.captureEvent(context, "SHOW_FOR_ATTACH", "r18", operation = show,
                observedUptimeMs = base + 5)
            edge("INPUT_ARMED", base + 6); edge("REVEAL_QUEUED", base + 7)
            // Receipt delivery may be out of order; it must not overwrite the
            // observed apply endpoints or synthesize a pixel presentation.
            edge("REVEAL_RECEIPT", base + 12, extra = mapOf("r18Commit" to base + 12))
            edge("REVEAL_RECEIPT", base + 10, extra = mapOf("r18ApplyBegin" to base + 8, "r18ApplyEnd" to base + 10))
            edge("RETIRE_RECEIPT", base + 23, extra = mapOf("r18Commit" to base + 23))
            edge("RETIRE_RECEIPT", base + 22, extra = mapOf("r18ApplyBegin" to base + 21, "r18ApplyEnd" to base + 22,
                "r18LatchNs" to 234567890123L, "r18PresentState" to "PENDING"))
            // The original seal occurrence remains earlier even when its
            // diagnostic event is consumed after both native receipts.
            edge("SEALED:window", base + 20)
            edge("OUTPUT_DRAINED", base + 24)
            if (wake == 0) {
                edge("HOST_ADDED", base + 30, host = 99, output = 99)
                edge("BUFFER_READY", base + 31, host = 99, output = 99)
            }
            repeat(80) { index ->
                KeyguardCardDiagnostics.captureEvent(context, "ACCESSIBILITY_EVENT", "pressure", diagnosticContext = owner,
                    observedUptimeMs = base + 100 + index, fields = mapOf("eventAgeMs" to index))
            }
        }
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        // Keep the exact synthetic frozen report when the test driver supplies
        // a run identity, including on a failed assertion. This does not alter
        // the original export or its required assertions.
        InstrumentationRegistry.getArguments().getString("runUuid")?.let { uuid ->
            val dir = File(context.filesDir, "keyguard-service-probe/r41/$uuid")
            check(dir.mkdirs() || dir.isDirectory)
            File(dir, "legacy-r18-$mode.txt").writeText(report, Charsets.UTF_8)
        }
        assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32_768)
        for (attempt in 1..4) assertTrue("missing R18 attempt $attempt in $mode", report.contains("R18_PIPELINE attempt=$attempt"))
        assertTrue(report.contains("proof=10077"))
        assertTrue(report.contains("revealApply=10008/10010 revealCommit=10012"))
        assertTrue(report.contains("seal=10020/SEALED:window retireApply=10021/10022 retireCommit=10023"))
        assertTrue(report.contains("physicalFirstPixel=UNOBSERVED physicalLastPixel=UNOBSERVED"))
        assertTrue(report.contains("omittedCriticalRecordIds="))
        KeyguardCardDiagnostics.captureEvent(context, "R18_PIPELINE", "REVEAL_RECEIPT", diagnosticContext = oldOwner,
            fields = mapOf("r18Host" to 1, "r18Output" to 20, "r18Commit" to 99999))
        assertEquals(report, KeyguardCardDiagnostics.captureSnapshot(context)["report"])
        KeyguardCardDiagnostics.startCapture(context, "r18-new", "profile", mode)
        KeyguardCardDiagnostics.beginLockAttempt(context, 52, 1, "wake", 100)
        KeyguardCardDiagnostics.captureEvent(context, "R18_PIPELINE", "REVEAL_RECEIPT", diagnosticContext = oldOwner,
            fields = mapOf("r18Host" to 1, "r18Output" to 20, "r18Commit" to 99999))
        val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertFalse(next.contains("99999"))
    }

    @Test fun r19FirstAndMotionEvidenceSurvivesLightPressure() = r19Evidence("LIGHT")
    @Test fun r19FirstAndMotionEvidenceSurvivesFullPressure() = r19Evidence("FULL")

    private fun r19Evidence(mode: String) {
        KeyguardCardDiagnostics.startCapture(context, "r19-$mode", "profile", mode)
        var firstOwner: KeyguardDiagnosticContext? = null
        var firstMetrics: KeyguardOrbSurfaceMetrics? = null
        repeat(4) { wake ->
            val base = 100_000L * (wake + 1)
            val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 901, wake + 1L, "wake", base))
            if (wake == 0) firstOwner = owner
            val metrics = KeyguardOrbSurfaceMetrics()
            if (wake == 0) firstMetrics = metrics
            metrics.record(base - 44_000, (base - 44_000) * 1_000_000, false, 1, 1, 1, 1, 1, 1)
            metrics.beginDirectPresentation(base + 20)
            metrics.record(base + 36, (base + 36) * 1_000_000, true, 1, 1, 1, 1, 1, 1)
            metrics.record(base + 52, (base + 52) * 1_000_000, true, 1, 1, 1, 1, 1, 1)
            fun edge(phase: String, at: Long, request: Long, extra: Map<String, Any> = emptyMap(),
                     metric: KeyguardOrbSurfaceMetrics? = null) {
                KeyguardCardDiagnostics.captureEvent(context, "R18_PIPELINE", phase,
                    serviceSession = 901, wakeEpoch = wake + 1L, requestId = request,
                    attachGeneration = wake + 1L, diagnosticContext = owner, observedUptimeMs = at,
                    surfaceMetrics = metric, fields = mapOf<String, Any>("r18Host" to wake + 1,
                        "r18Output" to wake + 10, "r18Privacy" to "full", "r19Intent" to "EMPTY") + extra)
            }
            edge("WAKE_ADOPTED", base, base + 1)
            // Reducer delivery order need not equal the physical reader order.
            KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_COALESCED", "newer", requestId = base + 3,
                diagnosticContext = owner, observedUptimeMs = base + 4)
            KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_STARTED", "wake", requestId = base + 2,
                diagnosticContext = owner, observedUptimeMs = base + 3, fields = mapOf("authorityCurrentAtStart" to true))
            KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_FINISHED", "NO_MAIN_MARKER", requestId = base + 2,
                diagnosticContext = owner, observedUptimeMs = base + 6,
                fields = mapOf("surfaceClassification" to "HIDDEN_UNKNOWN", "rootUnavailable" to false,
                    "walkTruncated" to false, "activeRootTotalMs" to 2, "activeRootFlags" to 4, "acceptedChildFlags" to 36))
            edge("R19_ALLOCATED", base - 10, base + 1)
            edge("HIDDEN_BOUND", base + 2, base + 1)
            edge("R19_FIRST_POSITIVE", base + 8, base + 7, mapOf("r18Proof" to base + 7,
                "r19SceneRead" to 44, "r19Freshness" to 5, "r19ReadStart" to base + 3,
                "r19RootMs" to 4, "r19RootFlags" to 4, "r19ChildFlags" to 36))
            edge("R19_PAINT_REQUEST", base + 9, base + 7)
            edge("R19_PAINT_ENTER", base + 10, base + 7, metric = metrics)
            edge("R19_POSTER", base + 11, base + 7, mapOf("r19Poster" to "hit"))
            edge("BUFFER_READY", base + 12, base + 7)
            edge("R19_PROOF_CONSUMED", base + 13, base + 7, mapOf("r19SceneNow" to 44))
            edge("GRANT", base + 14, base + 7)
            edge("SEALED:test", base + 80, base + 8)
            repeat(60) { index -> KeyguardCardDiagnostics.captureEvent(context, "ACCESSIBILITY_EVENT", "pressure",
                diagnosticContext = owner, observedUptimeMs = base + 100 + index, fields = mapOf("eventAgeMs" to index)) }
        }
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32_768)
        val rows = report.lineSequence().filter { it.startsWith(" R18_PIPELINE ") }.toList()
        assertEquals(4, rows.size)
        assertTrue(rows.first().contains("alloc=99990 reservedReq=100001"))
        assertTrue(rows.first().contains("firstRead=100002@100003/100006:HIDDEN_UNKNOWN/NO_MAIN_MARKER"))
        assertTrue(rows.first().contains("firstReadRootMs=2 firstReadChildMs=UNOBSERVED firstReadFlags=4/36 firstReadIncomplete=false/false"))
        assertTrue(rows.first().contains("firstPositive=100007@100008"))
        assertTrue(rows.first().contains("scene=44/44 freshness=5"))
        assertTrue(rows.first().contains("firstMotion=100036 activePosts=2 gaps=1/16000000/16000000/0"))
        assertFalse(rows.first().contains("44000000000"))
        firstMetrics?.record(999_999, 999_999_000_000, true, 1, 1, 1, 1, 1, 1)
        KeyguardCardDiagnostics.captureEvent(context, "R18_PIPELINE", "R19_PROOF_CONSUMED", diagnosticContext = firstOwner,
            fields = mapOf("r18Host" to 1, "r18Output" to 10, "r19SceneNow" to 99999))
        assertEquals(report, KeyguardCardDiagnostics.captureSnapshot(context)["report"])
    }

    @Test fun r22CoreJoinsOnlyTheExactReservationWithinAnAttempt() {
        val settings = context.getSharedPreferences("fluvi_native_keyguard_card", android.content.Context.MODE_PRIVATE)
        val hadMode = settings.contains("presentationMode")
        val savedMode = settings.getString("presentationMode", null)
        check(settings.edit().putString("presentationMode", "orb").commit())
        try {
            KeyguardCardDiagnostics.clearCapture(context)
            KeyguardCardDiagnostics.startCapture(context, "r22-token-pressure", "profile", "LIGHT")
            val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 921, 1, "wake", 1000))
            fun pipeline(host: Long, token: Long, request: Long, at: Long) {
                val fields = mapOf<String, Any>("r18Host" to host, "r18Output" to host + 100,
                    "r18Privacy" to "full", "r21Reservation" to token,
                    "r21Ordinal" to 1, "r21Result" to "ACCEPTED")
                KeyguardCardDiagnostics.captureEvent(context, "R18_PIPELINE", "R19_PROOF_CONSUMED",
                    diagnosticContext = owner, requestId = request, attachGeneration = host,
                    observedUptimeMs = at, fields = fields)
                KeyguardCardDiagnostics.captureEvent(context, "R18_PIPELINE", "R21_NATIVE_APPLY",
                    diagnosticContext = owner, requestId = request, attachGeneration = host,
                    observedUptimeMs = at + 1, fields = fields)
            }
            pipeline(11, 12, 111, 1100)
            pipeline(22, 23, 333, 1400)
            KeyguardCardDiagnostics.captureEvent(context, "R22_ACQUISITION", "PROOF_REJECTED",
                diagnosticContext = owner, observedUptimeMs = 1450,
                fields = mapOf("r22Reservation" to 12, "r22Positive" to 111, "r22Reject" to "SCENE_CHANGED"))
            KeyguardCardDiagnostics.captureEvent(context, "R22_ACQUISITION", "YIELDED",
                diagnosticContext = owner, requestId = 301, observedUptimeMs = 1451,
                fields = mapOf("r22Opening" to 301, "r22Reservation" to 23,
                    "r22Claimed" to 333, "r22Why" to "YIELDED",
                    "r27FirstIncomplete" to "NULL_ADVERTISED_CHILD", "r27YieldReason" to "INCOMPLETE_NULL_CHILD"))
            KeyguardCardDiagnostics.captureEvent(context, "R22_ACQUISITION", "PROOF_ACCEPTED",
                diagnosticContext = owner, observedUptimeMs = 1452,
                fields = mapOf("r22Reservation" to 23, "r22Positive" to 333, "r22Reject" to "ACCEPTED"))
            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
            val row = report.lineSequence().single { it.startsWith(" R22_CORE ") }
            assertTrue(row, row.contains("opening=301/23"))
            assertTrue(row, row.contains("r27v=1 incomplete=NULL_ADVERTISED_CHILD yield=INCOMPLETE_NULL_CHILD"))
            assertTrue(row, row.contains("positive=333@1452/ACCEPTED"))
            assertTrue(row, row.contains("consumed=333"))
            assertTrue(row, row.contains("apply=1401"))
            assertFalse(row, row.contains("SCENE_CHANGED"))
        } finally {
            KeyguardCardDiagnostics.clearCapture(context)
            val editor = settings.edit()
            if (hadMode) editor.putString("presentationMode", savedMode) else editor.remove("presentationMode")
            check(editor.commit())
        }
    }

    @Test fun r21PhoneShapeProtectsDirectAndFinalWithdrawalCore() {
        val modeFailures = mutableListOf<String>()
        val settings = context.getSharedPreferences("fluvi_native_keyguard_card", android.content.Context.MODE_PRIVATE)
        val hadMode = settings.contains("presentationMode")
        val savedMode = settings.getString("presentationMode", null)
        check(settings.edit().putString("presentationMode", "orb").commit())
        try {
        for (mode in listOf("LIGHT", "FULL")) {
            KeyguardCardDiagnostics.clearCapture(context)
            KeyguardCardDiagnostics.startCapture(context, "r21-pressure", "profile", mode)
            val expected = linkedMapOf<Long, Pair<Long, Long>>()
            var oldOwner: KeyguardDiagnosticContext? = null
            var latestOwner: KeyguardDiagnosticContext? = null
            repeat(8) { index ->
                val attempt = index + 1L; val base = attempt * 10_000L; val attach = 100 + attempt
                val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 921, attempt, "wake", base))
                if (index == 0) oldOwner = owner
                latestOwner = owner
                val request = base + 1
                val metric = KeyguardOrbSurfaceMetrics().apply { beginDirectPresentation(base + 13) }
                fun edge(phase: String, at: Long, extra: Map<String, Any> = emptyMap()) {
                    KeyguardCardDiagnostics.captureEvent(context, "R18_PIPELINE", phase,
                        serviceSession = 921, wakeEpoch = attempt, requestId = request,
                        attachGeneration = attach, diagnosticContext = owner, observedUptimeMs = at,
                        surfaceMetrics = metric, fields = mapOf<String, Any>("r18Host" to attach,
                            "r18Output" to 200 + attempt, "r18Child" to 300 + attempt,
                            "r18Privacy" to "full", "r19Intent" to "EMPTY") + extra)
                }
                if (attempt != 6L) {
                edge("WAKE_ADOPTED", base, mapOf("r18Reservation" to base - 100))
                edge("R19_ALLOCATED", base - 100)
                edge("R19_PROOF_CONSUMED", base + 9, mapOf("r19SceneNow" to 4))
                edge("R20_FIRST_FRAME", base + 10, mapOf("r20Method" to "DIRECT_MISS", "r20EntryNs" to 1001L))
                val facts = mapOf<String, Any>("r21Reservation" to 500 + attempt, "r21Reveal" to 1,
                    "r21Proof" to base + 2, "r21Ordinal" to 2, "r21SubmitPhase" to "CROSSED", "r21Result" to "ACCEPTED")
                edge("R21_CROSS", base + 11, facts)
                edge("R21_NATIVE_APPLY", base + 12, facts + mapOf("r21Ordinal" to 3, "r21SubmitPhase" to "APPLIED"))
                if (attempt == 8L) edge("R21_INGRESS", base + 13, facts + mapOf("r21Ordinal" to 9,
                    "r21Result" to "LATER_DELIVERY", "r21Offered" to base + 99))
                edge("R21_INGRESS", base + 13, facts + mapOf("r21Ordinal" to 4, "r21SubmitPhase" to "APPLIED",
                    "r21Result" to "RECHECK_OFFERED", "r21EventAt" to base + 12, "r21CallbackAt" to base + 13,
                    "r21Offered" to base + 3, "r21EventType" to 4194304, "r21WindowChanges" to 1, "r21Own" to false))
                edge("R21_ACK", base + 14, facts + mapOf("r21Ordinal" to 5, "r21SubmitPhase" to "ACKNOWLEDGED"))
                }
                // Real reducer/formatter pressure control. A yielded walk has
                // no fabricated completion classification. Attempt 6 has no
                // qualifying offer; 7 is a real completed exclusion; 8 records
                // B replaced by independently offered C before the claim.
                val isYield = attempt == 1L || attempt == 8L
                val successor = if (attempt == 8L) base + 9 else base + 3
                val r22 = mapOf<String, Any>(
                    "r22Opening" to request, "r22Reservation" to (500 + attempt), "r22AStart" to (base + 2),
                    "r22Scene" to 10, "r22IngressAt" to (base + 3), "r22IngressScene" to 11,
                    "r22FirstOffer" to (if (attempt == 6L) "UNOBSERVED" else base + 3),
                    "r22FirstOfferAt" to (if (attempt == 6L) "UNOBSERVED" else base + 4),
                    "r22LatestOffer" to (if (attempt == 6L) "UNOBSERVED" else successor),
                    "r22LatestOfferAt" to (if (attempt == 6L) "UNOBSERVED" else base + 4),
                    "r22Framework" to true, "r22Claimed" to (if (isYield) successor else "UNOBSERVED"),
                    "r22ClaimAt" to (if (isYield) base + 5 else "UNOBSERVED"),
                    "r22AEnd" to (base + 5), "r22Checkpoint" to (if (isYield) "beforeChild" else "UNOBSERVED"),
                    "r22Visited" to (if (isYield) 1 else "UNOBSERVED"), "r22Roots" to 1,
                    "r22Children" to (if (attempt == 1L) 0 else 1),
                    "r22Why" to (if (isYield) "YIELDED" else if (attempt == 6L) "noQualifyingOffer" else "observedDisqualifier"),
                    "r22AFirstRoot" to "10/ACTIVE_ROOT_BATCHED_PLUS_PER_WINDOW/7/7",
                    "r22AFirstChild" to "1/1/1/0/PRESENT",
                    "r22AInvalid" to "2/1/1/1/CHILD_ACQUISITION_EXCEPTION/IllegalStateException",
                    "r22ACheckpoint" to "true/SKIPPED_TRUNCATED/10/1",
                    "r22ADecisive" to false,
                    "r22Decision" to (if (isYield) "UNOBSERVED" else if (attempt == 7L) "HIDDEN_SHADE" else "SHOW_FULL"),
                    "r22Reason" to (if (attempt == 7L) "SHADE_MARKER" else "UNOBSERVED"),
                )
                KeyguardCardDiagnostics.captureEvent(context, "R22_ACQUISITION", if (isYield) "YIELDED" else "A_FINISHED",
                    diagnosticContext = owner, requestId = request, observedUptimeMs = base + 5, fields = r22)
                if (isYield) KeyguardCardDiagnostics.captureEvent(context, "R22_ACQUISITION", "B_FINISHED",
                    diagnosticContext = owner, requestId = successor, observedUptimeMs = base + 9,
                    fields = r22 + mapOf("r22BStart" to base + 6, "r22BEnd" to base + 9,
                        "r22Decision" to "SHOW_FULL", "r22Reason" to "MAIN_CONFIRMED", "r22Incomplete" to "false/false/false"))
                val first = KeyguardCardDiagnostics.newShowOperation(owner, attach, request)
                KeyguardCardDiagnostics.captureEvent(context, "SHOW_FOR_ATTACH", "wake", operation = first, observedUptimeMs = base + 15)
                KeyguardCardDiagnostics.captureEvent(context, "ADD_VIEW_RETURN", "wake", operation = first, observedUptimeMs = base + 16)
                val firstHide = KeyguardCardDiagnostics.newHideOperation(owner, attach, base + 4, base + 18)
                KeyguardCardDiagnostics.captureEvent(context, "HIDE_DECIDED", "first", operation = firstHide, observedUptimeMs = base + 19)
                KeyguardCardDiagnostics.captureEvent(context, "LOCAL_HIDE_BEGIN", "first", operation = firstHide,
                    observedUptimeMs = base + 19, fields = mapOf("attachedBefore" to true))
                KeyguardCardDiagnostics.captureEvent(context, "LOCAL_HIDE_APPLIED", "first", operation = firstHide, observedUptimeMs = base + 20)
                KeyguardCardDiagnostics.captureEvent(context, "REMOVE_VIEW_RETURN", "first", operation = firstHide, observedUptimeMs = base + 21)
                val finalHide = if (attempt == 6L) firstHide else {
                    val nextAttach = 1000 + attempt
                    val next = KeyguardCardDiagnostics.newShowOperation(owner, nextAttach, base + 5)
                    KeyguardCardDiagnostics.captureEvent(context, "SHOW_FOR_ATTACH", "successor", operation = next, observedUptimeMs = base + 25)
                    KeyguardCardDiagnostics.captureEvent(context, "ADD_VIEW_RETURN", "successor", operation = next, observedUptimeMs = base + 26)
                    val holder = KeyguardOrbSurfaceMetrics().apply { record(base + 27, (base + 27) * 1_000_000, true, 1, 1, 1, 1, 1, 1) }
                    KeyguardCardDiagnostics.captureEvent(context, "R12_SURFACE", "ROUTE_SELECTED", operation = next,
                        observedUptimeMs = base + 27, fields = mapOf("r12Generation" to nextAttach, "r12Detail" to "SURFACE_LIVE"), surfaceMetrics = holder)
                    val hide = KeyguardCardDiagnostics.newHideOperation(owner, nextAttach, base + 6, base + 29)
                    KeyguardCardDiagnostics.captureEvent(context, "HIDE_DECIDED", "final", operation = hide, observedUptimeMs = base + 30)
                    KeyguardCardDiagnostics.captureEvent(context, "LOCAL_HIDE_BEGIN", "final", operation = hide,
                        observedUptimeMs = base + 30, fields = mapOf("attachedBefore" to true))
                    KeyguardCardDiagnostics.captureEvent(context, "LOCAL_HIDE_APPLIED", "final", operation = hide, observedUptimeMs = base + 31)
                    KeyguardCardDiagnostics.captureEvent(context, "REMOVE_VIEW_RETURN", "final", operation = hide, observedUptimeMs = base + 32)
                    hide
                }
                expected[attempt] = requireNotNull(first.showOperationId) to requireNotNull(finalHide.hideOperationId)
                val cleanup = KeyguardCardDiagnostics.newHideOperation(owner, if (attempt == 6L) attach else 1000 + attempt, null, base + 33)
                KeyguardCardDiagnostics.captureEvent(context, "HIDE_DECIDED", "cleanup", operation = cleanup, observedUptimeMs = base + 34)
                KeyguardCardDiagnostics.captureEvent(context, "LOCAL_HIDE_BEGIN", "cleanup", operation = cleanup,
                    observedUptimeMs = base + 35, fields = mapOf("attachedBefore" to false))
                repeat(210) { sample ->
                    KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_QUEUED", "pressure", requestId = base + 1000 + sample,
                        diagnosticContext = owner, observedUptimeMs = base + 100 + sample,
                        fields = mapOf("latestSampler" to "123456789:${base + sample}/123456789/123456789:true/false"))
                    if (sample % 35 == 34) KeyguardCardDiagnostics.captureSnapshot(context)
                }
                if (attempt == 8L) {
                    // A displaced owner's late receipt must not relabel the
                    // newer attempt, even with identical synthetic uptime.
                    KeyguardCardDiagnostics.captureEvent(context, "R18_PIPELINE", "R21_ACK", diagnosticContext = oldOwner,
                        attachGeneration = 101, observedUptimeMs = base + 13,
                        fields = mapOf("r18Host" to 101, "r18Output" to 201, "r21Ordinal" to 9999))
                }
            }
            // LIGHT must face at least the phone's observed 173 skipped
            // diagnostics; FULL retains the same bounded observational load.
            repeat(200) { sample ->
                KeyguardCardDiagnostics.captureEvent(context, "ACCESSIBILITY_EVENT", "pressure",
                    diagnosticContext = latestOwner, observedUptimeMs = 90_000L + sample,
                    fields = mapOf("eventAgeMs" to sample))
            }
            val live = KeyguardCardDiagnostics.captureSnapshot(context)["report"] as String
            val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
            val args = androidx.test.platform.app.InstrumentationRegistry.getArguments()
            args.getString("runUuid")?.let { id ->
                val dir = java.io.File(context.filesDir, "keyguard-service-probe/r21/$id").apply { mkdirs() }
                java.io.File(dir, "$mode-live.txt").writeText(live)
                java.io.File(dir, "$mode-frozen.txt").writeText(frozen)
            }
            try {
            val bytes = frozen.toByteArray(Charsets.UTF_8).size
            assertTrue("budget $bytes", bytes <= 32_768 && frozen.contains("exportBytes=$bytes\n"))
            val rows = frozen.lineSequence().filter { it.startsWith(" R21_CORE ") }.toList()
            assertEquals("four protected selected cores required", 4, rows.size)
            for (id in listOf(1L, 6L, 7L, 8L)) {
                val row = rows.single { it.contains("attempt=$id ") }
                val (show, hide) = checkNotNull(expected[id])
                assertTrue(row.contains("firstShow=$show/")); assertTrue(row.contains("finalHide=$hide/"))
                if (id == 6L) {
                    assertTrue("missing direct evidence must remain missing", row.contains("direct=UNOBSERVED/"))
                    assertTrue(row.contains("first=UNOBSERVED/UNOBSERVED/"))
                } else {
                    assertTrue(row.contains("reservation=${500 + id}")); assertTrue(row.contains("ingress=${id * 10_000 + 13}/4/APPLIED/RECHECK_OFFERED"))
                    assertTrue(row.contains("first=${id * 10_000 + 1}/DIRECT_MISS/")); assertTrue(row.contains("/0 firstPostNs="))
                }
            }
            val openingRows = frozen.lineSequence().filter { it.startsWith(" R22_CORE ") }.toList()
            assertEquals("four protected acquisition cores required", 4, openingRows.size)
            for (id in listOf(1L, 6L, 7L, 8L)) {
                val row = openingRows.single { it.contains("attempt=$id ") }
                assertTrue(row.contains("opening=${id * 10_000 + 1}/${500 + id}"))
                assertTrue(row, row.contains("aRoot=10/ACTIVE_ROOT_BATCHED_PLUS_PER_WINDOW/7/7"))
                assertTrue(row, row.contains("aFirst=1/1/1/0/PRESENT"))
                assertTrue(row, row.contains("aInvalid=2/1/1/1/CHILD_ACQUISITION_EXCEPTION/IllegalStateException"))
                assertTrue(row, row.contains("aCheckpoint=true/SKIPPED_TRUNCATED/10/1"))
                assertTrue(row, row.contains("aDecisive=false"))
                when (id) {
                    1L -> { assertTrue(row.contains("outcome=YIELDED/YIELDED")); assertTrue(row.contains("counts=1/1/0")); assertTrue(row.contains("claimed=10003@10005")) }
                    6L -> { assertTrue(row.contains("noQualifyingOffer")); assertTrue(row.contains("claimed=UNOBSERVED@")) }
                    7L -> assertTrue(row.contains("aResult=HIDDEN_SHADE/SHADE_MARKER/"))
                    8L -> { assertTrue(row.contains("offered=80003@80004/80009@80004")); assertTrue(row.contains("claimed=80009@80005")) }
                }
            }
            val omissions = frozen.lineSequence().first { it.startsWith("omittedCriticalRecordIds=") }
            assertFalse(omissions.contains("r21Core"))
            assertFalse(omissions.contains("r22Core"))
            assertTrue("pressure must actually omit raw evidence", frozen.contains("rawEventsTruncated=true"))
            if (mode == "LIGHT") {
                val dropped = frozen.lineSequence().first { it.startsWith("diagnosticDroppedRecords=") }
                    .substringAfter('=').toInt()
                assertTrue("LIGHT did not reproduce the phone's dropped-record pressure: $dropped", dropped >= 173)
            }
            KeyguardCardDiagnostics.captureEvent(context, "R18_PIPELINE", "R21_ACK", diagnosticContext = oldOwner,
                observedUptimeMs = 999_999, fields = mapOf("r18Host" to 101, "r18Output" to 201, "r21Ordinal" to 9999))
            assertEquals(frozen, KeyguardCardDiagnostics.captureSnapshot(context)["report"])
            } catch (error: AssertionError) { modeFailures += "$mode: ${error.message}" }
        }
        assertTrue(modeFailures.joinToString("; "), modeFailures.isEmpty())
        } finally {
            val editor = settings.edit()
            if (hadMode) editor.putString("presentationMode", savedMode) else editor.remove("presentationMode")
            check(editor.commit())
        }
    }

    @Test fun r20FirstFrameBreakdownSurvivesFreezeAndReplacement() {
        for (mode in listOf("LIGHT", "FULL")) {
            KeyguardCardDiagnostics.startCapture(context, "r20-$mode", "profile", mode)
            val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 921, 4, "wake", 20_000))
            fun edge(phase: String, at: Long, req: Long, attachment: Long, output: Long,
                     extra: Map<String, Any> = emptyMap()) {
                KeyguardCardDiagnostics.captureEvent(context, "R18_PIPELINE", phase,
                    serviceSession = 921, wakeEpoch = 4, requestId = req, attachGeneration = attachment,
                    diagnosticContext = owner, observedUptimeMs = at,
                    fields = mapOf<String, Any>("r18Host" to 7, "r18Output" to output,
                        "r18Child" to 500 + output, "r18Privacy" to "full", "r19Intent" to "EMPTY") + extra)
            }
            edge("WAKE_ADOPTED", 20_000, 201, 8, 30)
            edge("R19_ALLOCATED", 19_000, 201, 8, 30)
            edge("FALLBACK:first", 20_040, 201, 8, 30)
            // A late delivery retains G1 and its actual ticket, even if the
            // eventual grant came from a later compatible request.
            edge("R19_PROOF_CONSUMED", 20_025, 209, 8, 30, mapOf("r19SceneNow" to 77))
            edge("R20_FIRST_FRAME", 20_020, 201, 8, 30, mapOf(
                "r20Method" to "DIRECT_MISS", "r20EntryNs" to 1001L, "r20PainterStartNs" to 1002L,
                "r20PainterEndNs" to 1003L, "r20ConfigureEndNs" to 1004L,
                "r20LockBeginNs" to 1005L, "r20LockReturnNs" to 1006L,
                "r20DrawEndNs" to 1007L, "r20PostReturnNs" to 1008L))
            edge("WAKE_ADOPTED", 20_100, 301, 9, 31)
            edge("R20_FIRST_FRAME", 20_110, 301, 9, 31, mapOf(
                "r20Method" to "BITMAP_HIT", "r20EntryNs" to 2001L,
                "r20LockBeginNs" to 2005L, "r20Failure" to "LOCK"))
            repeat(80) { index -> KeyguardCardDiagnostics.captureEvent(context, "ACCESSIBILITY_EVENT", "pressure",
                diagnosticContext = owner, observedUptimeMs = 20_200L + index, fields = mapOf("eventAgeMs" to index)) }
            val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
            assertTrue("UTF-8 report exceeds budget", frozen.toByteArray(Charsets.UTF_8).size <= 32_768)
            val rows = frozen.lineSequence().filter { it.startsWith(" R18_PIPELINE ") }.toList()
            assertEquals(2, rows.size)
            assertTrue(rows[0].contains("alloc=19000"))
            assertTrue(rows[0].contains("firstMethod=DIRECT_MISS firstTicket=201"))
            assertTrue(rows[0].contains("firstNs=1001/1002/1003/1004/1005/1006/1007/1008"))
            assertTrue(rows[0].contains("consumedReq=209"))
            assertTrue(rows[1].contains("firstMethod=BITMAP_HIT firstTicket=301"))
            assertTrue(rows[1].contains("firstFailure=LOCK"))
            assertTrue(rows[1].contains("firstNs=2001/UNOBSERVED/UNOBSERVED/UNOBSERVED/2005/UNOBSERVED/UNOBSERVED/UNOBSERVED"))
            edge("R20_FIRST_FRAME", 20_300, 999, 8, 30, mapOf("r20Method" to "STALE"))
            assertEquals(frozen, KeyguardCardDiagnostics.captureSnapshot(context)["report"])
            KeyguardCardDiagnostics.clearCapture(context)
        }
    }

    @Test fun r12SurfaceEvidenceRetainsItsShowOwnerInLight() = r12SurfaceEvidence("LIGHT")
    @Test fun r12SurfaceEvidenceRetainsItsShowOwnerInFull() = r12SurfaceEvidence("FULL")

    @Test fun r13FinancialWorkRetainsOwnedCountsInLight() = r13FinancialWork("LIGHT")
    @Test fun r13FinancialWorkRetainsOwnedCountsInFull() = r13FinancialWork("FULL")

    @Test fun r13FinancialWorkSurvivesPressureAndRemainsCaptureBounded() {
        for (mode in listOf("LIGHT", "FULL")) {
            KeyguardCardDiagnostics.startCapture(context, "r13-pressure", "profile", mode)
            repeat(4) { wake ->
                val base = (wake + 1) * 10_000L
                val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 44, wake + 1L, "wake", base))
                val attach = wake + 1L
                val show = KeyguardCardDiagnostics.newShowOperation(owner, attach, base + 1)
                KeyguardCardDiagnostics.captureEvent(context, "SHOW_FOR_ATTACH", "wake", observedUptimeMs = base + 1, operation = show)
                repeat(40) { index ->
                    val at = base + 100 + index
                    val fields = mapOf<String, Any>("r13Start" to at, "r13End" to at + 1,
                        "r13WallNs" to 123456789012L, "r13CpuNs" to 12345678901L,
                        "r13Construct" to 1, "r13Demand" to 0, "r13Paint" to 0, "r13PaintDone" to 0,
                        "r13Bind" to 0, "r13PaintWallNs" to 0, "r13PaintCpuNs" to 0,
                        "r13PaintMaxWallNs" to 0, "r13PaintMaxCpuNs" to 0, "r13Returned" to true,
                        "r13Noop" to true, "r13Success" to true, "r13Route" to 0)
                    KeyguardCardDiagnostics.captureEvent(context, "R13_FINANCIAL", "scoped", requestId = base + index + 2,
                        attachGeneration = attach, diagnosticContext = owner, observedUptimeMs = at + 1, fields = fields)
                    if (index % 10 == 0) KeyguardCardDiagnostics.captureSnapshot(context) // fixture drain
                }
                val hide = KeyguardCardDiagnostics.newHideOperation(owner, attach, base + 80, base + 130)
                KeyguardCardDiagnostics.captureEvent(context, "HIDE_DECIDED", "window", observedUptimeMs = base + 150, operation = hide)
                KeyguardCardDiagnostics.captureEvent(context, "LOCAL_HIDE_BEGIN", "window", observedUptimeMs = base + 150,
                    operation = hide, fields = mapOf("attachedBefore" to true))
                KeyguardCardDiagnostics.captureEvent(context, "LOCAL_HIDE_APPLIED", "invisible", observedUptimeMs = base + 151, operation = hide)
            }
            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
            assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32_768)
            for (attempt in 1..4) {
                assertTrue("missing owned pressure aggregate for $mode attempt $attempt",
                    report.contains("R13_FINANCIAL attempt=$attempt coverage=keyguardScopesOnly scopes=40 invalid=0 returned=40 noops=40"))
            }
            assertTrue(report.contains("retainedEvicted=8"))
            assertTrue(report.contains("physical=UNOBSERVED"))
        }
    }

    private fun r13FinancialWork(mode: String) {
        KeyguardCardDiagnostics.startCapture(context, "r13-$mode", "profile", mode)
        val attempt = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 4, 1, "wake", 100))
        val first = KeyguardCardDiagnostics.newShowOperation(attempt, 1, 21)
        KeyguardCardDiagnostics.captureEvent(context, "SHOW_FOR_ATTACH", "wake", observedUptimeMs = 101, operation = first)
        val fields = mapOf<String, Any>("r13Start" to 102, "r13End" to 103, "r13WallNs" to 10,
            "r13CpuNs" to 7, "r13Construct" to 1, "r13Demand" to 0, "r13Paint" to 0,
            "r13PaintDone" to 0, "r13Bind" to 0, "r13PaintWallNs" to 0, "r13PaintCpuNs" to 0,
            "r13PaintMaxWallNs" to 0, "r13PaintMaxCpuNs" to 0, "r13Returned" to true,
            "r13Noop" to false, "r13Success" to true, "r13Route" to 0)
        KeyguardCardDiagnostics.captureEvent(context, "R13_FINANCIAL", "scoped", operation = first,
            observedUptimeMs = 103, fields = fields)
        KeyguardCardDiagnostics.captureEvent(context, "R13_FINANCIAL", "scoped", diagnosticContext = attempt,
            requestId = 22, attachGeneration = 1, observedUptimeMs = 110,
            fields = fields + mapOf("r13Noop" to true, "r13Start" to 109, "r13End" to 110))
        val hide = KeyguardCardDiagnostics.newHideOperation(attempt, 1, 23, 109)
        KeyguardCardDiagnostics.captureEvent(context, "HIDE_DECIDED", "window", observedUptimeMs = 110, operation = hide)
        KeyguardCardDiagnostics.captureEvent(context, "LOCAL_HIDE_BEGIN", "window", observedUptimeMs = 110,
            operation = hide, fields = mapOf("attachedBefore" to true))
        KeyguardCardDiagnostics.captureEvent(context, "LOCAL_HIDE_APPLIED", "invisible", observedUptimeMs = 112, operation = hide)
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertTrue(report.contains("R13_FINANCIAL attempt=${attempt.attemptId} coverage=keyguardScopesOnly scopes=2"))
        assertTrue(report.contains("constructions=2 demands=0 paints=0 paintCompleted=0 legacyBinds=0"))
        assertTrue(report.contains("noops=1"))
        assertTrue(report.contains("req=21 showOp=${first.showOperationId} attach=1 route=SURFACE_LIVE"))
        assertTrue(report.contains("overlap=UNOBSERVED physical=UNOBSERVED"))
        assertTrue(report.contains("hideOp=${hide.hideOperationId} attach=1 req=23 event=UNOBSERVED callback=109 local=112"))
        assertTrue(report.contains("callbackToLocalScopeLowerMs=1"))
        assertTrue(report.contains("readStart=UNOBSERVED readEnd=UNOBSERVED handoff=UNOBSERVED mainEntry=UNOBSERVED decision=110"))
        assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32_768)
        KeyguardCardDiagnostics.captureEvent(context, "R13_FINANCIAL", "late", operation = first, fields = fields)
        assertEquals(report, KeyguardCardDiagnostics.captureSnapshot(context)["report"])
        KeyguardCardDiagnostics.startCapture(context, "r13-new", "profile", mode)
        KeyguardCardDiagnostics.beginLockAttempt(context, 5, 1, "wake", 200)
        KeyguardCardDiagnostics.captureEvent(context, "R13_FINANCIAL", "old-owner", operation = first, fields = fields)
        val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertTrue(next.contains("R13_FINANCIAL attempt=1 coverage=UNOBSERVED"))
    }

    private fun r12SurfaceEvidence(mode: String) {
        KeyguardCardDiagnostics.startCapture(context, "r12-$mode", "profile", mode)
        val attempt = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 9, 3, "wake", 100))
        val first = KeyguardCardDiagnostics.newShowOperation(attempt, 1, 7)
        val metrics = KeyguardOrbSurfaceMetrics()
        KeyguardCardDiagnostics.captureEvent(context, "R12_ADMISSION", "eligible", requestId = 7,
            diagnosticContext = attempt, observedUptimeMs = 99, fields = mapOf("r12Pending" to 8,
                "r12Reserved" to 8, "r12FreshnessRevision" to 4, "r12PriorApplyQueued" to 102))
        fun emit(operation: KeyguardDiagnosticOperation, reason: String, generation: Long, at: Long, detail: String) {
            KeyguardCardDiagnostics.captureEvent(context, "R12_SURFACE", reason, observedUptimeMs = at,
                attachGeneration = operation.attachGeneration, operation = operation,
                fields = mapOf("r12Generation" to generation, "r12Detail" to detail),
                surfaceMetrics = if (operation == first) metrics else null)
        }
        // The real worker can reach the reducer before the show decision.
        emit(first, "ROUTE_SELECTED", 11, 101, "SURFACE_LIVE")
        emit(first, "HOLDER_CREATED", 11, 103, "callback")
        KeyguardCardDiagnostics.captureEvent(context, "SHOW_FOR_ATTACH", "wake", observedUptimeMs = 100, operation = first)
        emit(first, "HOLDER_CHANGED", 11, 104, "168x168")
        emit(first, "POSTER", 11, 105, "hit")
        emit(first, "FIRST_POST", 11, 110, "producerNotPhysicalPresentation")
        emit(first, "FIRST_POST_MAIN_DELIVERY", 11, 115, "mainCallbackNotPhysicalPresentation")
        metrics.record(110, 110_000_000, false, 1, 2, 3, 4, 5, 6)
        metrics.record(126, 126_000_000, true, 2, 3, 4, 5, 6, 7)
        val second = KeyguardCardDiagnostics.newShowOperation(attempt, 2, 8)
        KeyguardCardDiagnostics.captureEvent(context, "SHOW_FOR_ATTACH", "wake", observedUptimeMs = 200, operation = second)
        emit(second, "ROUTE_SELECTED", 12, 201, "SURFACE_STATIC")
        emit(first, "HOLDER_DESTROYED", 11, 220, "drainMs:2")
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        val firstLine = report.lineSequence().first { it.startsWith(" R12_SURFACE ") && it.contains("showOp=${first.showOperationId}") }
        val secondLine = report.lineSequence().first { it.startsWith(" R12_SURFACE ") && it.contains("showOp=${second.showOperationId}") }
        assertTrue(firstLine.contains("route=SURFACE_LIVE"))
        assertTrue(firstLine.contains("generation=11"))
        assertTrue(firstLine.contains("firstPost=110"))
        assertTrue(firstLine.contains("firstPostMainDelivery=115"))
        assertTrue(firstLine.contains("destroyed=220"))
        assertTrue(secondLine.contains("route=SURFACE_STATIC"))
        assertTrue(secondLine.contains("firstPost=UNOBSERVED"))
        val cadence = report.lineSequence().first { it.startsWith(" R12_CADENCE ") && it.contains("showOp=${first.showOperationId}") }
        assertTrue(cadence.contains("submissions=2"))
        assertTrue(cadence.contains("distinct=126"))
        assertTrue(cadence.contains("presentation=UNOBSERVED"))
        assertTrue(report.contains("readAhead=eligible:8/8:rev4:applyQueued102"))
        assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32_768)
        emit(first, "FIRST_POST", 11, 999, "late")
        assertEquals(report, KeyguardCardDiagnostics.captureSnapshot(context)["report"])
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
        KeyguardCardDiagnostics.captureEvent(context, "ISOLATED_LAYER_HIDE_SUBMITTED", "isolatedSurfaceControl", requestId = 150L,
            observedUptimeMs = 331_508_962L, diagnosticContext = attempt, operation = withdrawal,
            fields = mapOf("leaseGeneration" to 88L, "transactionApplied" to true))
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
        assertTrue(report.contains("triggerToLayerHideSubmitMs=169"))
        assertTrue(report.contains("triggerToRemoveReturnMs=179"))
        assertTrue(report.contains("localHideToLayerHideSubmitMs=1"))
        assertTrue(report.contains("layerHideSubmitToRemoveBeginMs=0"))
        assertTrue(report.contains("hideDecisionToLocalHideMs=4"))
        assertTrue(report.contains("removeViewCallMs=10"))
        assertTrue(report.contains("layerSubmit=331508962/true"))
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

    @Test fun fullCapturePinsBoundedSlowMainHandoffEvidenceInTheCausalSpine() {
        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug", "FULL")
        val attempt = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 42L, 1L, "wake", 0L))
        KeyguardCardDiagnostics.captureEvent(
            context, "INSPECTION_MAIN_APPLY_STARTED", "unlock", requestId = 71L,
            observedUptimeMs = 230L, diagnosticContext = attempt,
            fields = mapOf(
                "mainHandoffRequestedAtUptimeMs" to 140L,
                "mainApplyEnteredAtUptimeMs" to 230L,
                "mainHandoffEvidenceMode" to "ownedMainScopesOnly",
                "mainHandoffClock" to "System.nanoTime",
                "mainHandoffDurationNs" to 90_000_000L,
                "mainHandoffWorkSession" to 42L,
                "mainHandoffWorkThreadId" to 991L,
                "mainHandoffWorkOmitted" to 1,
                "mainHandoffWorkEvicted" to 2L,
                "mainHandoffWorkCoverageIncomplete" to true,
                "mainHandoffWorkInvalid" to 0L,
                "mainHandoffWorkSpan0" to "systemGate:71:1:2:3:1",
                "mainHandoffWorkSpan1" to "NONE",
                "mainHandoffWorkSpan2" to "NONE",
            ),
        )

        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertTrue(report.contains("mainHandoffEvidenceMode=ownedMainScopesOnly"))
        assertTrue(report.contains("mainHandoffDurationNs=90000000"))
        assertTrue(report.contains("mainHandoffWorkCoverageIncomplete=true"))
        assertTrue(report.contains("mainHandoffWorkSpan0=systemGate:71:1:2:3:1"))
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

    @Test fun lightAndFullPressureRetainEverySelectedEpisodeCauseAndFitTheWholeUtf8Budget() {
        for (mode in listOf("LIGHT", "FULL")) pressureRetainsEverySelectedEpisode(mode)
    }

    @Test fun r14LightPressureRetainsEverySelectedEpisode() = pressureRetainsEverySelectedEpisode("LIGHT")

    @Test fun r14FullPressureRetainsEverySelectedEpisode() = pressureRetainsEverySelectedEpisode("FULL")

    @Test fun r14PairedEpisodesWithFinancialPressureLight() = pairedEpisodesWithFinancialPressure("LIGHT")
    @Test fun r14PairedEpisodesWithFinancialPressureFull() = pairedEpisodesWithFinancialPressure("FULL")
    @Test fun r14DeferredRecoveryWithoutShowLight() = deferredRecoveryWithoutShow("LIGHT")
    @Test fun r14DeferredRecoveryWithoutShowFull() = deferredRecoveryWithoutShow("FULL")

    /** One capture per mode contains the paired show/hide and recovery edges.
     * Queue replacement is exercised by the real coalescing owner; the
     * resulting immutable identities are then offered to the real reducer. */
    @Test fun r14PairedRecoveryEdgesRemainOwnedUnderPressureAndRotation() {
        val source = androidx.test.platform.app.InstrumentationRegistry.getArguments().getString("sourceSha") ?: "r14-combined"
        val runId = androidx.test.platform.app.InstrumentationRegistry.getArguments().getString("runUuid")
        val captureIds = mutableSetOf<String>()
        var previousOwner: KeyguardDiagnosticContext? = null
        for (mode in listOf("LIGHT", "FULL")) {
            KeyguardCardDiagnostics.clearCapture(context)
            val captureId = KeyguardCardDiagnostics.startCapture(context, source, "profile", mode)["captureId"].toString()
            assertTrue(captureIds.add(captureId))
            val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 917, 2, "wake", 100))
            previousOwner?.let { stale ->
                KeyguardCardDiagnostics.captureEvent(context, "R14_RECOVERY", "DEFERRED", diagnosticContext = stale,
                    observedUptimeMs = 101, fields = mapOf("r14Recovery" to 999_999))
            }
            fun request(id: Long) = KeyguardCardInspectionRequest(id = id, trigger = "window", session = 917,
                visibilityEpoch = 3, interactionEpoch = 4, attachGeneration = 4, wakeGeneration = 2,
                queuedAtUptimeMs = 120 + id, diagnosticContext = owner)
            val a = request(20)
            val b = request(21)
            val successor = request(22)
            val queue = KeyguardCardInspectionQueue()
            assertTrue(queue.offer(a))
            assertFalse(queue.offer(b))
            assertEquals(b.id, queue.pendingRequest()?.id)

            val first = KeyguardCardDiagnostics.newShowOperation(owner, 4, 19)
            KeyguardCardDiagnostics.captureEvent(context, "SHOW_FOR_ATTACH", "paired", operation = first, observedUptimeMs = 110)
            KeyguardCardDiagnostics.captureEvent(context, "ADD_VIEW_RETURN", "paired", operation = first, observedUptimeMs = 111)
            val firstHide = KeyguardCardDiagnostics.newHideOperation(owner, 4, 18, 112)
            KeyguardCardDiagnostics.captureEvent(context, "HIDE_DECIDED", "paired", operation = firstHide, observedUptimeMs = 113)
            KeyguardCardDiagnostics.captureEvent(context, "LOCAL_HIDE_BEGIN", "paired", operation = firstHide,
                observedUptimeMs = 114, fields = mapOf("attachedBefore" to true))
            KeyguardCardDiagnostics.captureEvent(context, "LOCAL_HIDE_APPLIED", "paired", operation = firstHide, observedUptimeMs = 115)
            KeyguardCardDiagnostics.captureEvent(context, "REMOVE_VIEW_RETURN", "paired", operation = firstHide, observedUptimeMs = 116)

            val base = mapOf("r14Recovery" to 9, "r14PreviousHide" to firstHide.hideOperationId,
                "r14PreviousAttach" to 4, "r14Authority" to "917/2/3/4/4", "r14DeferredA" to a.id,
                "r14OriginalB" to b.id, "r14Pending" to checkNotNull(queue.pendingRequest()).id,
                "r14Physical" to "UNOBSERVED")
            KeyguardCardDiagnostics.captureEvent(context, "R14_RECOVERY", "DEFERRED", requestId = a.id,
                diagnosticContext = owner, observedUptimeMs = 135, fields = base)
            val displaced = checkNotNull(queue.pendingRequest()).id
            assertFalse(queue.offer(successor))
            val pending = checkNotNull(queue.pendingRequest()).id
            assertEquals(successor.id, pending)
            KeyguardCardDiagnostics.captureEvent(context, "R14_RECOVERY", "REPLACED", requestId = pending,
                diagnosticContext = owner, observedUptimeMs = 136,
                fields = base + mapOf("r14Pending" to pending, "r14Displaced" to displaced))

            val second = KeyguardCardDiagnostics.newShowOperation(owner, 5, 24)
            KeyguardCardDiagnostics.captureEvent(context, "SHOW_FOR_ATTACH", "paired", operation = second, observedUptimeMs = 140)
            KeyguardCardDiagnostics.captureEvent(context, "ADD_VIEW_RETURN", "paired", operation = second, observedUptimeMs = 141)
            val secondHide = KeyguardCardDiagnostics.newHideOperation(owner, 5, 25, 142)
            KeyguardCardDiagnostics.captureEvent(context, "HIDE_DECIDED", "paired", operation = secondHide, observedUptimeMs = 143)
            KeyguardCardDiagnostics.captureEvent(context, "LOCAL_HIDE_BEGIN", "paired", operation = secondHide,
                observedUptimeMs = 144, fields = mapOf("attachedBefore" to true))
            KeyguardCardDiagnostics.captureEvent(context, "LOCAL_HIDE_APPLIED", "paired", operation = secondHide, observedUptimeMs = 145)
            KeyguardCardDiagnostics.captureEvent(context, "REMOVE_VIEW_RETURN", "paired", operation = secondHide, observedUptimeMs = 146)
            repeat(40) { index ->
                val at = 200L + index
                KeyguardCardDiagnostics.captureEvent(context, "R13_FINANCIAL", "scoped", requestId = 300L + index,
                    attachGeneration = 5, diagnosticContext = owner, observedUptimeMs = at + 1,
                    fields = mapOf("r13Start" to at, "r13End" to at + 1, "r13WallNs" to 10, "r13CpuNs" to 5,
                        "r13Construct" to 1, "r13Demand" to 0, "r13Paint" to 0, "r13PaintDone" to 0,
                        "r13Bind" to 0, "r13PaintWallNs" to 0, "r13PaintCpuNs" to 0,
                        "r13PaintMaxWallNs" to 0, "r13PaintMaxCpuNs" to 0,
                        "r13Returned" to true, "r13Noop" to true, "r13Success" to true, "r13Route" to 0))
            }
            repeat(800) { index ->
                KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_QUEUED", "pressure", requestId = 1_000L + index,
                    diagnosticContext = owner, observedUptimeMs = 1_000L + index)
                if (index % 80 == 79) KeyguardCardDiagnostics.captureSnapshot(context)
            }
            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
            if (runId != null) {
                val directory = java.io.File(context.filesDir, "keyguard-service-probe/r14/$runId/combined-pressure")
                check(directory.mkdirs() || directory.isDirectory)
                java.io.File(directory, "$mode-report.txt").writeText(report)
            }
            val bytes = report.toByteArray(Charsets.UTF_8).size
            assertTrue(bytes <= 32_768 && report.contains("exportBytes=$bytes\n"))
            assertTrue(report.endsWith("END_FLUVI_KEYGUARD_TIMING_CAPTURE_V1\n"))
            assertTrue(report.contains("captureId=$captureId\n") && report.contains("captureMode=$mode\n"))
            assertTrue(report.contains("omittedCriticalRecordIds=none"))
            assertEquals(2, report.lineSequence().count { it.startsWith(" EPISODE ") })
            val recovery = report.lineSequence().filter { it.startsWith(" R14_RECOVERY ") }.toList()
            val deferred = recovery.single { it.contains("phase=DEFERRED") }
            val replacement = recovery.single { it.contains("phase=REPLACED") }
            assertTrue(deferred.contains("r14Recovery=9 r14PreviousHide=${firstHide.hideOperationId} r14PreviousAttach=4"))
            assertTrue(deferred.contains("r14DeferredA=${a.id}") && deferred.contains("r14OriginalB=${b.id}") && deferred.contains("r14Pending=${b.id}"))
            assertTrue(replacement.contains("r14Pending=$pending") && replacement.contains("r14Displaced=$displaced"))
            assertTrue(report.contains("R13_FINANCIAL attempt=1 coverage=keyguardScopesOnly scopes=40 invalid=0"))
            assertFalse(report.contains("r14Recovery=999999"))
            KeyguardCardDiagnostics.captureEvent(context, "R14_RECOVERY", "late", diagnosticContext = owner, fields = base)
            assertEquals(report, KeyguardCardDiagnostics.captureSnapshot(context)["report"])
            previousOwner = owner
        }
        KeyguardCardDiagnostics.clearCapture(context)
        previousOwner?.let { stale ->
            KeyguardCardDiagnostics.captureEvent(context, "R14_RECOVERY", "off", diagnosticContext = stale,
                fields = mapOf("r14Recovery" to 888_888))
        }
        KeyguardCardDiagnostics.startCapture(context, source, "profile", "LIGHT")
        KeyguardCardDiagnostics.beginLockAttempt(context, 918, 3, "wake", 5_000)
        val off = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertFalse(off.contains("r14Recovery=888888"))
    }

    @Test fun r15PhoneShapeKeepsFinancialAndActualWithdrawalLight() = r15PhoneShape("LIGHT")
    @Test fun r15PhoneShapeKeepsFinancialAndActualWithdrawalFull() = r15PhoneShape("FULL")
    @Test fun r15WrongRetiredAttachmentNeverInheritsHolderEvidence() {
        for (mode in listOf("LIGHT", "FULL")) {
            KeyguardCardDiagnostics.startCapture(context, "r15-owner", "profile", mode)
            val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 30, 1, "wake", 100))
            val hide = KeyguardCardDiagnostics.newHideOperation(owner, 4, 1, 101)
            val metrics = KeyguardOrbSurfaceMetrics().apply {
                beginHolderOperation(111); holderLockReturned(112); revokeStarted(113); revokeReturned(114)
                holderPostEntered(115); holderPostReturned(116)
            }
            KeyguardCardDiagnostics.captureEvent(context, "HIDE_DECIDED", "window", operation = hide, observedUptimeMs = 105)
            KeyguardCardDiagnostics.captureEvent(context, "R15_SURFACE_REVOKED", "mismatch", operation = hide,
                observedUptimeMs = 117, fields = mapOf("r15TargetAttachment" to 5, "r15Generation" to 9,
                    "r15AtRevoke" to "test-mismatch"), surfaceMetrics = metrics)
            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
            val row = report.lineSequence().first { it.startsWith(" WITHDRAWAL ") }
            assertTrue(row.contains("attach=4") && row.contains("holderTarget=5/9"))
            assertTrue(row.contains("holderCoherent=UNOBSERVED") && row.contains("post=UNOBSERVED/UNOBSERVED"))
            metrics.holderPostReturned(999_999)
            assertEquals(report, KeyguardCardDiagnostics.captureSnapshot(context)["report"])
        }
    }

    /** Four retained phone-shaped attempts with raw pressure. Attempts 1, 6,
     * 7 and 8 reproduce the identifiers omitted by the R14 phone export. */
    private fun r15PhoneShape(mode: String) {
        val source = androidx.test.platform.app.InstrumentationRegistry.getArguments().getString("sourceSha") ?: "r15-phone-shape"
        KeyguardCardDiagnostics.startCapture(context, source, "profile", mode)
        val metricOwners = mutableListOf<KeyguardOrbSurfaceMetrics>()
        repeat(8) { index ->
            val base = (index + 1L) * 10_000L
            val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 91, index + 1L, "wake", base))
            val request = base + 1
            val attach = index + 1L
            KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_QUEUED", "wake", requestId = request,
                diagnosticContext = owner, observedUptimeMs = base + 1)
            KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_FINISHED", "MAIN_CONFIRMED", requestId = request,
                diagnosticContext = owner, observedUptimeMs = base + 10,
                fields = readerFields(main = true) + mapOf("activeRootFlags" to 0, "acceptedChildFlags" to 36,
                    "firstChildAcquisitionMs" to 2, "firstNullRootId" to 735, "firstNullRootType" to 3,
                    "firstNullRootDisplay" to 0, "firstNullRootLayer" to -1, "firstNullRootSource" to "window",
                    "latestSampler" to "123456789:${base - 7}/${base - 5}/${base - 4}:true/false",
                    "latestSamplerAuthority" to "91/${index + 1}/123456/123456/$attach"))
            val show = KeyguardCardDiagnostics.newShowOperation(owner, attach, request)
            KeyguardCardDiagnostics.captureEvent(context, "SHOW_FOR_ATTACH", "wake", operation = show, observedUptimeMs = base + 11)
            KeyguardCardDiagnostics.captureEvent(context, "ADD_VIEW_RETURN", "wake", operation = show, observedUptimeMs = base + 12)
            val metrics = KeyguardOrbSurfaceMetrics()
            metricOwners += metrics
            metrics.beginHolderOperation(base + 13); metrics.holderLockReturned(base + 14)
            metrics.revokeStarted(base + 20); metrics.revokeReturned(base + 21)
            metrics.holderDrawReturned(base + 22); metrics.holderPostEntered(base + 23)
            metrics.holderPostReturned(base + 24); metrics.holderRecordObserved(base + 25)
            metrics.record(base + 25, (base + 25) * 1_000_000, true, 1, 2, 3, 4, 5, 6)
            KeyguardCardDiagnostics.captureEvent(context, "R12_SURFACE", "ROUTE_SELECTED", operation = show,
                observedUptimeMs = base + 13, fields = mapOf("r12Generation" to attach, "r12Detail" to "SURFACE_LIVE"), surfaceMetrics = metrics)
            val hideRequest = base + 2
            KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_FINISHED", "FOREIGN_ABOVE", requestId = hideRequest,
                diagnosticContext = owner, observedUptimeMs = base + 19, fields = readerFields() + mapOf(
                    "latestSampler" to "123456790:${base + 13}/${base + 15}/${base + 16}:true/false",
                    "latestSamplerAuthority" to "91/${index + 1}/123456/123456/$attach"))
            val hide = KeyguardCardDiagnostics.newHideOperation(owner, attach, hideRequest, base + 18)
            KeyguardCardDiagnostics.captureEvent(context, "HIDE_DECIDED", "window", operation = hide, observedUptimeMs = base + 20)
            KeyguardCardDiagnostics.captureEvent(context, "R15_SURFACE_REVOKED", "synchronousAccessClosure", operation = hide,
                observedUptimeMs = base + 21, fields = mapOf("r15TargetAttachment" to attach, "r15Generation" to attach,
                    "r15AtRevoke" to "true:1:${base + 13}/${base + 14}:UNOBSERVED:UNOBSERVED/UNOBSERVED:UNOBSERVED"), surfaceMetrics = metrics)
            KeyguardCardDiagnostics.captureEvent(context, "LOCAL_HIDE_BEGIN", "window", operation = hide,
                observedUptimeMs = base + 21, fields = mapOf("attachedBefore" to true))
            KeyguardCardDiagnostics.captureEvent(context, "LOCAL_HIDE_APPLIED", "window", operation = hide, observedUptimeMs = base + 22)
            KeyguardCardDiagnostics.captureEvent(context, "REMOVE_VIEW_RETURN", "window", operation = hide, observedUptimeMs = base + 26)
            val recovery = mapOf("r14Recovery" to attach, "r14PreviousHide" to hide.hideOperationId,
                "r14PreviousAttach" to attach, "r14Physical" to "UNOBSERVED")
            for ((phase, at) in listOf("WITHDRAWN" to 27L, "END_terminal" to 28L)) {
                KeyguardCardDiagnostics.captureEvent(context, "R14_RECOVERY", phase, diagnosticContext = owner,
                    observedUptimeMs = base + at, fields = recovery)
            }
            val cleanup = KeyguardCardDiagnostics.newHideOperation(owner, attach, null, base + 29)
            KeyguardCardDiagnostics.captureEvent(context, "HIDE_DECIDED", "cleanup", operation = cleanup, observedUptimeMs = base + 30)
            KeyguardCardDiagnostics.captureEvent(context, "LOCAL_HIDE_BEGIN", "cleanup", operation = cleanup,
                observedUptimeMs = base + 31, fields = mapOf("attachedBefore" to false))
            repeat(40) { sample ->
                val at = base + 100 + sample
                KeyguardCardDiagnostics.captureEvent(context, "R13_FINANCIAL", "scoped", diagnosticContext = owner,
                    requestId = base + 1000 + sample, attachGeneration = attach, observedUptimeMs = at + 1,
                    fields = mapOf("r13Start" to at, "r13End" to at + 1, "r13WallNs" to 123456789012L,
                        "r13CpuNs" to 12345678901L, "r13Construct" to 1, "r13Demand" to 0, "r13Paint" to 0,
                        "r13PaintDone" to 0, "r13Bind" to 0, "r13PaintWallNs" to 0, "r13PaintCpuNs" to 0,
                        "r13PaintMaxWallNs" to 0, "r13PaintMaxCpuNs" to 0, "r13Returned" to true,
                        "r13Noop" to true, "r13Success" to true, "r13Route" to 0))
            }
            repeat(80) { sample ->
                KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_QUEUED", "pressure", requestId = base + 2000 + sample,
                    diagnosticContext = owner, observedUptimeMs = base + 500 + sample)
                if (sample % 40 == 39) KeyguardCardDiagnostics.captureSnapshot(context)
            }
        }
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        androidx.test.platform.app.InstrumentationRegistry.getArguments().getString("runUuid")?.let { runId ->
            val directory = java.io.File(context.filesDir, "keyguard-service-probe/r15/$runId/phone-pressure")
            check(directory.mkdirs() || directory.isDirectory)
            java.io.File(directory, "$mode-report.txt").writeText(report)
        }
        assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32_768)
        assertTrue(report.contains("build=$source\n"))
        assertTrue(report.contains("retainedAttemptIds=1,6,7,8"))
        val omissions = report.lineSequence().first { it.startsWith("omittedCriticalRecordIds=") }
        assertTrue("critical record lost under phone-shaped pressure: $omissions", omissions == "omittedCriticalRecordIds=none")
        assertTrue(report.contains("incompleteExportAttemptIds=none"))
        for (id in listOf(1, 6, 7, 8)) {
            assertTrue("missing financial core for attempt $id", report.contains("R13_FINANCIAL attempt=$id coverage=keyguardScopesOnly scopes=40"))
            assertFalse("incorrectly omitted a$id:r13Financial", omissions.contains("a$id:r13Financial"))
            assertTrue(report.contains("R14_RECOVERY_META attempt=$id retained=2 omitted=0"))
            assertTrue(report.contains("holderTarget=$id/$id"))
        }
        assertTrue(report.contains("rootFlags=0 acceptedChildFlags=36"))
        assertTrue(report.contains("latestSampler=123456789:"))
        assertTrue(report.contains("latestSampler=123456790:"))
        assertTrue(report.contains("physical=UNOBSERVED"))
        metricOwners.last().holderPostReturned(999_999)
        assertEquals(report, KeyguardCardDiagnostics.captureSnapshot(context)["report"])
    }

    private fun deferredRecoveryWithoutShow(mode: String) {
        KeyguardCardDiagnostics.clearCapture(context)
        val source = androidx.test.platform.app.InstrumentationRegistry.getArguments().getString("sourceSha") ?: "r14-deferred"
        KeyguardCardDiagnostics.startCapture(context, source, "profile", mode)
        val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 917, 2, "wake", 100))
        val hide = KeyguardCardDiagnostics.newHideOperation(owner, 4, 10, 110)
        KeyguardCardDiagnostics.captureEvent(context, "HIDE_DECIDED", "previous", operation = hide, observedUptimeMs = 111)
        KeyguardCardDiagnostics.captureEvent(context, "LOCAL_HIDE_BEGIN", "previous", operation = hide,
            observedUptimeMs = 112, fields = mapOf("attachedBefore" to true))
        val base = mapOf("r14Recovery" to 7, "r14PreviousHide" to hide.hideOperationId,
            "r14PreviousAttach" to 4, "r14Authority" to "917/2/3/4/4", "r14DeferredA" to 20,
            "r14OriginalB" to 21, "r14Pending" to 21, "r14Ingress" to 8,
            "r14Origin" to "systemUi", "r14Event" to 130, "r14Callback" to 131,
            "r14ReadStart" to 120, "r14ReadEnd" to 125, "r14Physical" to "UNOBSERVED")
        KeyguardCardDiagnostics.captureEvent(context, "R14_RECOVERY", "DEFERRED", requestId = 20,
            diagnosticContext = owner, observedUptimeMs = 135, fields = base)
        KeyguardCardDiagnostics.captureEvent(context, "R14_RECOVERY", "REPLACED", requestId = 22,
            diagnosticContext = owner, observedUptimeMs = 136, fields = base + mapOf("r14Pending" to 22, "r14Displaced" to 21))
        KeyguardCardDiagnostics.captureEvent(context, "R14_RECOVERY", "REPLACED", requestId = 23,
            diagnosticContext = owner, observedUptimeMs = 137, fields = base + mapOf("r14Pending" to 23, "r14Displaced" to 22))
        repeat(1_200) { index ->
            KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_QUEUED", "pressure", requestId = 100L + index,
                diagnosticContext = owner, observedUptimeMs = 200L + index)
            if (index % 100 == 99) KeyguardCardDiagnostics.captureSnapshot(context)
        }
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        androidx.test.platform.app.InstrumentationRegistry.getArguments().getString("runUuid")?.let { runId ->
            val directory = java.io.File(context.filesDir, "keyguard-service-probe/r14/$runId/deferred-pressure")
            check(directory.mkdirs() || directory.isDirectory)
            java.io.File(directory, "$mode-report.txt").writeText(report)
        }
        val bytes = report.toByteArray(Charsets.UTF_8).size
        assertTrue(bytes <= 32_768 && report.contains("exportBytes=$bytes\n"))
        assertTrue(report.contains("omittedCriticalRecordIds=none"))
        assertTrue(report.contains("phase=DEFERRED r14Recovery=7 r14PreviousHide=${hide.hideOperationId}"))
        assertTrue(report.contains("r14DeferredA=20") && report.contains("r14OriginalB=21"))
        val replacements = report.lineSequence().filter { it.startsWith(" R14_RECOVERY ") && it.contains("phase=REPLACED") }.toList()
        assertTrue(replacements.any { it.contains("r14Pending=22") && it.contains("r14Displaced=21") })
        assertTrue(replacements.any { it.contains("r14Pending=23") && it.contains("r14Displaced=22") })
        assertEquals(0, report.lineSequence().count { it.startsWith(" EPISODE ") })
        assertEquals(report, KeyguardCardDiagnostics.captureSnapshot(context)["report"])
        KeyguardCardDiagnostics.clearCapture(context)
        KeyguardCardDiagnostics.startCapture(context, "$source-rotated", "profile", mode)
        KeyguardCardDiagnostics.beginLockAttempt(context, 917, 3, "wake", 3_000)
        KeyguardCardDiagnostics.captureEvent(context, "R14_RECOVERY", "stale", diagnosticContext = owner, fields = base)
        val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertFalse(next.contains("r14Recovery=7"))
    }

    private fun pairedEpisodesWithFinancialPressure(mode: String) {
        val source = androidx.test.platform.app.InstrumentationRegistry.getArguments().getString("sourceSha") ?: "r14-paired"
        KeyguardCardDiagnostics.startCapture(context, source, "profile", mode)
        val allShows = mutableListOf<KeyguardDiagnosticOperation>()
        val allHides = mutableListOf<KeyguardDiagnosticOperation>()
        repeat(2) { wake ->
            val base = 1_000L + wake * 10_000L
            val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 814, wake + 2L, "wake", base))
            repeat(2) { index ->
                val attachment = wake * 2L + index + 1L
                val at = base + 100 + index * 400
                val showRequest = base + 40 + index
                val show = KeyguardCardDiagnostics.newShowOperation(owner, attachment, showRequest)
                allShows += show
                fun emit(stage: String, whenMs: Long, operation: KeyguardDiagnosticOperation, fields: Map<String, Any?> = emptyMap()) =
                    KeyguardCardDiagnostics.captureEvent(context, stage, "paired", operation = operation,
                        observedUptimeMs = whenMs, fields = fields)
                KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_FINISHED", "MAIN_CONFIRMED", requestId = showRequest,
                    diagnosticContext = owner, observedUptimeMs = at - 1, fields = readerFields(main = true))
                emit("SHOW_FOR_ATTACH", at, show)
                emit("ADD_VIEW_RETURN", at + 1, show)
                val metrics = KeyguardOrbSurfaceMetrics()
                if (index == 0) repeat(4) { frame ->
                    val time = at + 10 + frame * 16
                    metrics.record(time, time * 1_000_000, frame > 0, 1, 2, 3, 4, 5, 6)
                }
                KeyguardCardDiagnostics.captureEvent(context, "R12_SURFACE", "ROUTE_SELECTED", operation = show,
                    observedUptimeMs = at + 2, fields = mapOf("r12Generation" to attachment, "r12Detail" to "SURFACE_LIVE"), surfaceMetrics = metrics)
                val hideRequest = base + 60 + index
                KeyguardCardDiagnostics.captureEvent(context, "INSPECTION_FINISHED", "FOREIGN_ABOVE", requestId = hideRequest,
                    diagnosticContext = owner, observedUptimeMs = at + 99, fields = readerFields())
                val hide = KeyguardCardDiagnostics.newHideOperation(owner, attachment, hideRequest, at + 100)
                allHides += hide
                emit("HIDE_DECIDED", at + 101, hide)
                emit("LOCAL_HIDE_BEGIN", at + 102, hide, mapOf("attachedBefore" to true))
                emit("LOCAL_HIDE_APPLIED", at + 103, hide)
                emit("REMOVE_VIEW_RETURN", at + 104, hide)
            }
            val cleanup = KeyguardCardDiagnostics.newHideOperation(owner, wake * 2L + 2L, null, base + 999)
            allHides += cleanup
            KeyguardCardDiagnostics.captureEvent(context, "HIDE_DECIDED", "cleanup", operation = cleanup, observedUptimeMs = base + 1_000)
            KeyguardCardDiagnostics.captureEvent(context, "LOCAL_HIDE_BEGIN", "cleanup", operation = cleanup,
                observedUptimeMs = base + 1_001, fields = mapOf("attachedBefore" to false))
            repeat(40) { index ->
                val at = base + 1_100 + index
                KeyguardCardDiagnostics.captureEvent(context, "R13_FINANCIAL", "scoped", requestId = base + 100 + index,
                    attachGeneration = wake * 2L + 2L, diagnosticContext = owner, observedUptimeMs = at + 1,
                    fields = mapOf("r13Start" to at, "r13End" to at + 1, "r13WallNs" to 10,
                        "r13CpuNs" to 5, "r13Construct" to 1, "r13Demand" to 0, "r13Paint" to 0,
                        "r13PaintDone" to 0, "r13Bind" to 0, "r13PaintWallNs" to 0, "r13PaintCpuNs" to 0,
                        "r13PaintMaxWallNs" to 0, "r13PaintMaxCpuNs" to 0, "r13Returned" to true, "r13Noop" to true,
                        "r13Success" to true, "r13Route" to 0))
                if (index % 10 == 0) KeyguardCardDiagnostics.captureSnapshot(context)
            }
        }
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        val bytes = report.toByteArray(Charsets.UTF_8).size
        androidx.test.platform.app.InstrumentationRegistry.getArguments().getString("runUuid")?.let { runId ->
            val directory = java.io.File(context.filesDir, "keyguard-service-probe/r14/$runId/paired-pressure")
            check(directory.mkdirs() || directory.isDirectory)
            java.io.File(directory, "$mode-report.txt").writeText(report)
        }
        assertTrue(bytes <= 32_768 && report.contains("exportBytes=$bytes\n"))
        assertTrue(report.contains("omittedCriticalRecordIds=none"))
        assertEquals(4, report.lineSequence().count { it.startsWith(" EPISODE ") })
        val withdrawals = report.lineSequence().filter { it.startsWith(" WITHDRAWAL ") }.toList()
        assertEquals(6, withdrawals.size)
        for (hide in allHides) assertEquals(1, withdrawals.count { it.contains("hideOp=${hide.hideOperationId} ") })
        val cadence = report.lineSequence().filter { it.startsWith(" R12_CADENCE ") }.toList()
        allShows.forEachIndexed { index, show ->
            assertTrue(cadence.any { it.contains("showOp=${show.showOperationId} ") && it.contains("submissions=${if (index % 2 == 0) 4 else 0} ") })
        }
        for (attempt in 1..2) assertTrue(report.contains("R13_FINANCIAL attempt=$attempt coverage=keyguardScopesOnly scopes=40 invalid=0"))
        for (show in allShows) assertTrue(report.lineSequence().any { (it.startsWith(" SHOWING_INSPECTION ") || it.startsWith(" SHOW_CAUSE ")) && it.contains("req=${show.causingInspectionRequestId} ") })
        for (hide in allHides.filter { it.causingInspectionRequestId != null }) assertTrue(report.lineSequence().any { (it.startsWith(" ACTUAL_WITHDRAWAL_INSPECTION ") || it.startsWith(" WITHDRAWAL_CAUSE ")) && it.contains("req=${hide.causingInspectionRequestId} ") })
        assertEquals(report, KeyguardCardDiagnostics.captureSnapshot(context)["report"])
        KeyguardCardDiagnostics.clearCapture(context)
        KeyguardCardDiagnostics.captureEvent(context, "R13_FINANCIAL", "off", operation = allShows[0], fields = mapOf("r13Start" to 9999))
        KeyguardCardDiagnostics.startCapture(context, "$source-rotated", "profile", mode)
        KeyguardCardDiagnostics.beginLockAttempt(context, 815, 3, "wake", 30_000)
        KeyguardCardDiagnostics.captureEvent(context, "SHOW_FOR_ATTACH", "stale", operation = allShows[0], observedUptimeMs = 99_999)
        val rotated = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertFalse(rotated.contains("decision=99999"))
    }

    private fun pressureRetainsEverySelectedEpisode(mode: String) {
        KeyguardCardDiagnostics.clearCapture(context)
        val source = androidx.test.platform.app.InstrumentationRegistry.getArguments().getString("sourceSha") ?: "episode-pressure-sha"
        KeyguardCardDiagnostics.startCapture(context, source, "profile", mode)
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
                        "isolatedFirstIdentity" to "first/direct:attach=$attach,generation=123456,slot=3,use=123456,child=123456789",
                        "isolatedFirstReady" to "ready=653328111,post=653328112,main=653328113,applyBegin=653328114,applyEnd=653328115",
                        "isolatedFirstCommit" to "receipt=653328116,main=653328117,bootstrapRetired=653328118",
                        "r08Route" to "PRESSURE_VIEW",
                        "r08Origin" to "entered:renderer:123456,attach:123456,gen:123456,child:123456789,grant:123456789,cause:NO_SUCCESSOR",
                        "r08Times" to "start:653328111,offer:653328162,claim:653328163,draw:653328180,restore:UNOBSERVED,n:3",
                        "r08Anchor" to "elapsed:12345.123,phase:123.25,background:999.75,interior:44.5",
                        "r08Transition" to false,
                        "r08Slot0" to "slot:1,use:123456,lease:3/8,state:PUBLISHED,retired:true,receipt:false,fence:false",
                        "r08Slot1" to "slot:2,use:123457,lease:4/11,state:PUBLISHED,retired:true,receipt:false,fence:false",
                        "r08Slot2" to "slot:3,use:123458,lease:11/19,state:PUBLISHED,retired:false,receipt:false,fence:false",
                        "r08Worker" to "seq:123456,age:123,desired:11/19,attached:11/19,reason:noFree",
                        "r08Grant" to "id:123456789,lease:11/19,active:true,running:true",
                        "r08Progress" to "completedAt:653328117,inFlight:0,ready:0,owned:3",
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
        androidx.test.platform.app.InstrumentationRegistry.getArguments().getString("runUuid")?.let { runId ->
            val directory = java.io.File(context.filesDir, "keyguard-service-probe/r14/$runId/existing-pressure")
            check(directory.mkdirs() || directory.isDirectory)
            java.io.File(directory, "$mode-report.txt").writeText(report)
        }
        android.util.Log.i("FluviExportBudget", "$mode retainedEpisodes=5 events=${frozen["eventsRecorded"]} UTF8Bytes=$bytes")
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
        assertEquals(5, report.lineSequence().count { it.startsWith(" RENDER ") &&
            it.contains("isolatedFirstIdentity=") && it.contains("isolatedFirstReady=") &&
            it.contains("isolatedFirstCommit=") })
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
        assertTrue(report.lineSequence().any {
            it.startsWith(" RENDER ") && it.contains("shaderFrames=11") && it.contains("shaderCalls=13")
        })
        assertEquals(report, KeyguardCardDiagnostics.captureSnapshot(context)["report"])
    }

    /** The reducer may see the commit before the delayed HIDE_DECIDED record.
     * Keep it on the original capture/attempt/hide owner, including after B
     * attaches, and never let a late A callback enter a new frozen capture. */
    @Test fun firstDirectAndHideCommitEvidenceKeepTheirOriginalOperations() {
        for (mode in listOf("LIGHT", "FULL")) {
            KeyguardCardDiagnostics.clearCapture(context)
            KeyguardCardDiagnostics.startCapture(context, "r07-$mode", "profile", mode)
            val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 123L, 4L, "wake", 100L))
            fun emit(stage: String, at: Long, operation: KeyguardDiagnosticOperation, fields: Map<String, Any?> = emptyMap()) {
                KeyguardCardDiagnostics.captureEvent(context, stage, "r07-fixture", observedUptimeMs = at,
                    diagnosticContext = owner, operation = operation, fields = fields)
            }
            val showA = KeyguardCardDiagnostics.newShowOperation(owner, 11L, null)
            val hideA = KeyguardCardDiagnostics.newHideOperation(owner, 11L, null, 200L)
            emit("SHOW_FOR_ATTACH", 110L, showA)
            emit("ADD_VIEW_RETURN", 120L, showA)
            emit("POST_ADD_SETUP_COMPLETE", 122L, showA)
            emit("VIEW_ATTACH_STATE", 123L, showA)
            emit("FIRST_ROOT_PREDRAW", 124L, showA, mapOf("r09RootSize" to "1080x2400",
                "r09TargetSize" to "168x168", "r09AttachState" to "alreadyAttached"))
            emit("USER_PRESENT_RECEIVED", 199L, hideA)
            // Same original operation, deliberately reduced out of order.
            emit("R09_RETIREMENT", 214L, hideA, mapOf("r09Stage" to "final-clear-committed",
                "r09Lease" to "11/7", "r09Child" to 12345, "r09Slot" to "UNOBSERVED", "r09Use" to "UNOBSERVED"))
            emit("ISOLATED_LAYER_HIDE_COMMIT_RECEIVED", 215L, hideA)
            emit("HIDE_DECIDED", 201L, hideA)
            emit("LOCAL_HIDE_BEGIN", 202L, hideA, mapOf("attachedBefore" to true))
            emit("ISOLATED_LAYER_HIDE_SUBMITTED", 203L, hideA,
                mapOf("transactionApplied" to true, "applyReturnedAtUptimeMs" to 204L))
            emit("REMOVE_VIEW_RETURN", 210L, hideA)
            emit("ATTACHMENT_RENDER_SUMMARY", 211L, hideA, mapOf(
                "isolatedFirstIdentity" to "first/direct:attach:11,generation:7,slot:2,use:9,child:12345",
                "isolatedFirstReady" to "ready:130,post:131,main:132,applyBegin:133,applyEnd:134",
                "isolatedFirstCommit" to "receipt:UNOBSERVED,main:UNOBSERVED,bootstrapRetired:UNOBSERVED",
                "r09FirstFrames" to "workerAck:135:2/9,steadyApply:140:3/10",
            ))
            val showB = KeyguardCardDiagnostics.newShowOperation(owner, 12L, null)
            val hideB = KeyguardCardDiagnostics.newHideOperation(owner, 12L, null, 300L)
            emit("SHOW_FOR_ATTACH", 220L, showB)
            emit("ADD_VIEW_RETURN", 221L, showB)
            emit("HIDE_DECIDED", 301L, hideB)
            emit("LOCAL_HIDE_BEGIN", 302L, hideB, mapOf("attachedBefore" to true))
            emit("ISOLATED_LAYER_HIDE_SUBMITTED", 303L, hideB,
                mapOf("transactionApplied" to true, "applyReturnedAtUptimeMs" to 304L))
            emit("REMOVE_VIEW_RETURN", 310L, hideB)
            emit("ATTACHMENT_RENDER_SUMMARY", 311L, hideB, mapOf(
                "isolatedFirstIdentity" to "first/direct:attach:12,generation:8,slot:3,use:10,child:67890",
                "isolatedFirstReady" to "ready:230,post:231,main:232,applyBegin:233,applyEnd:234",
                "isolatedFirstCommit" to "receipt:235,main:236,bootstrapRetired:237",
            ))
            // B is already gone, but this is still B's actual commit receipt.
            emit("ISOLATED_LAYER_HIDE_COMMIT_RECEIVED", 315L, hideB)
            val showC = KeyguardCardDiagnostics.newShowOperation(owner, 13L, null)
            val hideC = KeyguardCardDiagnostics.newHideOperation(owner, 13L, null, 350L)
            emit("SHOW_FOR_ATTACH", 320L, showC)
            emit("HIDE_DECIDED", 351L, hideC)
            emit("LOCAL_HIDE_BEGIN", 352L, hideC, mapOf("attachedBefore" to true))
            emit("ISOLATED_LAYER_HIDE_SUBMITTED", 353L, hideC,
                mapOf("transactionApplied" to true, "applyReturnedAtUptimeMs" to 354L))
            emit("REMOVE_VIEW_RETURN", 360L, hideC)
            val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
            assertTrue(frozen.lineSequence().any { it.startsWith(" EPISODE ") &&
                it.contains("attach=11 ") && it.contains("postAdd=122 ") &&
                    it.contains("preDraw=124 ") && it.contains("targetSize=168x168 ") })
            assertTrue(frozen.contains("firstExclusionSignal=USER_PRESENT_RECEIVED@199"))
            val renders = frozen.lineSequence().filter { it.startsWith(" RENDER ") }.toList()
            // C intentionally has a show but no summary; the exporter still
            // emits its empty RENDER record rather than dropping the episode.
            assertEquals(3, renders.size)
            assertTrue(renders.single { it.contains("attach=11 ") }.contains("isolatedFirstIdentity=first/direct:attach:11"))
            assertTrue(renders.single { it.contains("attach=11 ") }.contains("receipt:UNOBSERVED"))
            assertTrue(renders.single { it.contains("attach=11 ") }.contains("r09FirstFrames=workerAck:135:2/9,steadyApply:140:3/10"))
            assertTrue(renders.single { it.contains("attach=12 ") }.contains("bootstrapRetired:237"))
            val withdrawals = frozen.lineSequence().filter { it.startsWith(" WITHDRAWAL ") }.toList()
            assertTrue(withdrawals.single { it.contains("hideOp=${hideA.hideOperationId} ") }
                .contains("layerApplyReturn=204 layerCommit=215"))
            assertTrue(withdrawals.single { it.contains("hideOp=${hideA.hideOperationId} ") }
                .contains("final-clear-committed@214:11/7:12345"))
            assertTrue(withdrawals.single { it.contains("hideOp=${hideB.hideOperationId} ") }
                .contains("layerApplyReturn=304 layerCommit=315"))
            assertTrue(withdrawals.single { it.contains("hideOp=${hideC.hideOperationId} ") }
                .contains("layerApplyReturn=354 layerCommit=UNOBSERVED"))
            assertTrue(frozen.toByteArray(Charsets.UTF_8).size <= 32 * 1024)
            assertTrue(frozen.contains("omittedCriticalRecordIds=none"))
            emit("ISOLATED_LAYER_HIDE_COMMIT_RECEIVED", 400L, hideA)
            assertEquals(frozen, KeyguardCardDiagnostics.captureSnapshot(context)["report"])
            KeyguardCardDiagnostics.startCapture(context, "new-$mode", "profile", mode)
            KeyguardCardDiagnostics.beginLockAttempt(context, 124L, 5L, "wake", 500L)
            emit("ISOLATED_LAYER_HIDE_COMMIT_RECEIVED", 501L, hideA)
            val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
            assertFalse(next.contains("layerCommit=501"))
        }
    }

    @Test fun r08LightRecoveryExportRetainsItsOwnerAndBudget() = recoveryExport("LIGHT")
    @Test fun r08FullRecoveryExportRetainsItsOwnerAndBudget() = recoveryExport("FULL")

    private fun recoveryExport(mode: String) {
        KeyguardCardDiagnostics.startCapture(context, "r08-$mode", "profile", mode)
        val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 824L, 1L, "wake", 100L))
        fun emit(stage: String, at: Long, operation: KeyguardDiagnosticOperation,
                 fields: Map<String, Any?> = emptyMap()) {
            KeyguardCardDiagnostics.captureEvent(context, stage, "r08-fixture", observedUptimeMs = at,
                diagnosticContext = owner, operation = operation, fields = fields)
        }
        fun episode(attachment: Long, route: String, origin: String, at: Long) {
            val show = KeyguardCardDiagnostics.newShowOperation(owner, attachment, null)
            val hide = KeyguardCardDiagnostics.newHideOperation(owner, attachment, null, at + 30)
            emit("SHOW_FOR_ATTACH", at, show)
            emit("ADD_VIEW_RETURN", at + 1, show)
            emit("HIDE_DECIDED", at + 31, hide)
            emit("LOCAL_HIDE_BEGIN", at + 32, hide, mapOf("attachedBefore" to true))
            emit("LOCAL_HIDE_APPLIED", at + 33, hide)
            emit("REMOVE_VIEW_RETURN", at + 34, hide)
            emit("ATTACHMENT_RENDER_SUMMARY", at + 35, hide, mapOf(
                "r08Route" to route,
                "r08Origin" to origin,
                "r08Times" to "start:653328111,offer:653328162,claim:653328163,draw:653328180,restore:UNOBSERVED,n:3",
                "r08Anchor" to "elapsed:12345.123,phase:123.25,background:999.75,interior:44.5",
                "r08Transition" to false,
                "r08Slot0" to "slot:1,use:123456,lease:3/8,state:PUBLISHED,retired:true,receipt:false,fence:false",
                "r08Slot1" to "slot:2,use:123457,lease:4/11,state:PUBLISHED,retired:true,receipt:false,fence:false",
                "r08Slot2" to "slot:3,use:123458,lease:11/19,state:PUBLISHED,retired:false,receipt:false,fence:false",
                "r08Worker" to "seq:123456,age:123,desired:11/19,attached:11/19,reason:noFree",
                "r08Grant" to "id:123456789,lease:11/19,active:true,running:true",
                "r08Progress" to "completedAt:653328117,inFlight:0,ready:0,owned:3",
                "shaderFrames" to 100, "shaderCalls" to 101, "phaseAdvances" to 99,
            ))
        }
        val firstOrigin = "entered:renderer:7,attach:11,gen:19,child:123456789,grant:123456790,cause:NO_SUCCESSOR"
        episode(11, "PRESSURE_VIEW", firstOrigin, 110)
        episode(12, "PRESSURE_VIEW", "inherited:renderer:7,attach:11,gen:19,child:123456789,grant:123456790,cause:NO_SUCCESSOR", 210)
        episode(13, "ISOLATED", "UNOBSERVED", 310)
        repeat(200) { index ->
            KeyguardCardDiagnostics.captureEvent(context, "ACCESSIBILITY_EVENT", "noise", observedUptimeMs = 500L + index,
                diagnosticContext = owner, fields = mapOf("eventType" to 2048))
            if (index % 40 == 0) KeyguardCardDiagnostics.captureSnapshot(context)
        }
        val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        val renders = frozen.lineSequence().filter { it.startsWith(" RENDER ") }.toList()
        assertEquals(3, renders.size)
        assertTrue(renders.single { it.contains("attach=11 ") }.contains("r08Origin=$firstOrigin"))
        assertTrue(renders.single { it.contains("attach=12 ") }.contains("r08Origin=inherited:renderer:7,attach:11"))
        assertTrue(renders.single { it.contains("attach=13 ") }.contains("r08Origin=UNOBSERVED"))
        assertTrue(renders.first().contains("receipt:false,fence:false"))
        assertTrue(frozen.contains("omittedCriticalRecordIds=none"))
        assertTrue(frozen.toByteArray(Charsets.UTF_8).size <= 32_768)
        KeyguardCardDiagnostics.startCapture(context, "r08-next-$mode", "profile", mode)
        KeyguardCardDiagnostics.beginLockAttempt(context, 825L, 2L, "wake", 900L)
        val oldHide = KeyguardCardDiagnostics.newHideOperation(owner, 11L, null, 950L)
        emit("ATTACHMENT_RENDER_SUMMARY", 951L, oldHide, mapOf("r08Origin" to "STALE_OLD_CAPTURE"))
        val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        assertFalse(next.contains("STALE_OLD_CAPTURE"))
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

    @Test fun r09WorstGapSurvivesFullExportPressure() = r09WorstGapSurvivesExportPressure("FULL")
    @Test fun r09WorstGapSurvivesLightExportPressure() = r09WorstGapSurvivesExportPressure("LIGHT")

    @Test fun r10CompactColdAndWorstGapSurviveFullPressure() = r10CompactColdAndWorstGap("FULL")
    @Test fun r10CompactColdAndWorstGapSurviveLightPressure() = r10CompactColdAndWorstGap("LIGHT")

    @Test fun r11FirstOfferSurvivesVisibleFreezeAndPressureFull() = r11FirstOfferSurvivesVisibleFreezeAndPressure("FULL")
    @Test fun r11FirstOfferSurvivesVisibleFreezeAndPressureLight() = r11FirstOfferSurvivesVisibleFreezeAndPressure("LIGHT")

    private fun r11FirstOfferSurvivesVisibleFreezeAndPressure(mode: String) {
        KeyguardCardDiagnostics.startCapture(context, "r11-visible-$mode", "profile", mode)
        val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 1111L, 1L, "wake", 100L))
        val show = KeyguardCardDiagnostics.newShowOperation(owner, 1L, null)
        val identity = mapOf("r11Renderer" to 7, "r11Attachment" to 1, "r11Generation" to 9,
            "r11Slot" to 2, "r11Use" to 4, "r11Ready" to 105, "r11Offer" to 110)
        fun emit(reason: String, at: Long, fields: Map<String, Any?> = emptyMap()) {
            KeyguardCardDiagnostics.captureEvent(context, "R11_FIRST", reason, observedUptimeMs = at,
                diagnosticContext = owner, operation = show, fields = identity + fields)
        }
        // A synchronous grant callback can precede SHOW's reduction.
        emit("offer", 110, mapOf("r11ShaderHit" to false, "r11ShaderConstructed" to true,
            "r11ShaderWallNs" to 8000, "r11ShaderCpuNs" to 5000))
        emit("grant", 120, mapOf("r11Grant" to 120, "r11Child" to 77, "r11GrantId" to 88))
        emit("claim", 121, mapOf("r11Origin" to "grant"))
        emit("applyBegin", 123)
        emit("applyEnd", 125)
        emit("commit", 129, mapOf("r11ExtraAt" to 128))
        emit("ack", 130)
        emit("steady", 150, mapOf("r11Slot" to 3, "r11Use" to 2, "r11ShaderHit" to true,
            "r11ShaderConstructed" to false, "r11ShaderWallNs" to 100, "r11ShaderCpuNs" to 50))
        KeyguardCardDiagnostics.captureEvent(context, "SHOW_FOR_ATTACH", "main", operation = show,
            observedUptimeMs = 101)
        repeat(550) { index ->
            KeyguardCardDiagnostics.captureEvent(context, "R11_FIXTURE_NOISE", "é".repeat(80),
                observedUptimeMs = 200L + index, diagnosticContext = owner, fields = mapOf("n" to index))
            if (index % 100 == 99) KeyguardCardDiagnostics.captureSnapshot(context)
        }
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        val line = report.lineSequence().first { it.startsWith(" R11_FIRST ") }
        assertTrue(line.contains("lease=1/9") && line.contains("first=2/4"))
        assertTrue(line.contains("claim=121/grant") && line.contains("bothReadyToApplyBeginMs=3") &&
            line.contains("bothReadyToApplyEndMs=5"))
        assertTrue(line.contains("commitReceipt=128") && line.contains("ack=130"))
        assertTrue(line.contains("successor=3/2@150") && line.contains("directToSuccessorMs=25"))
        assertTrue(line.contains("shader0=false/true/8000/5000") && line.contains("shader1=true/false/100/50"))
        assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32 * 1024)

        // A late old callback must not acquire the new capture's owner.
        KeyguardCardDiagnostics.startCapture(context, "r11-new-$mode", "profile", mode)
        val next = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 1112L, 2L, "wake", 500L))
        val nextShow = KeyguardCardDiagnostics.newShowOperation(next, 2L, null)
        KeyguardCardDiagnostics.captureEvent(context, "R11_FIRST", "commit", operation = show,
            observedUptimeMs = 501, fields = identity)
        KeyguardCardDiagnostics.captureEvent(context, "SHOW_FOR_ATTACH", "main", operation = nextShow,
            observedUptimeMs = 502)
        val nextReport = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        val nextLine = nextReport.lineSequence().first { it.startsWith(" R11_FIRST ") }
        assertTrue(nextLine.contains("lease=UNOBSERVED") && nextLine.contains("commitReceipt=UNOBSERVED"))
        assertFalse(nextLine.contains("lease=1/9"))
    }

    private fun r10CompactColdAndWorstGap(mode: String) {
        KeyguardCardDiagnostics.startCapture(context, "r10-export-$mode", "profile", mode)
        val hideIds = mutableListOf<Long>()
        val cleanupIds = mutableListOf<Long>()
        repeat(4) { index ->
            val attach = index + 1L
            val at = 20_000L * attach
            val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 1010L, attach, "wake", at))
            val show = KeyguardCardDiagnostics.newShowOperation(owner, attach, null)
            val hide = KeyguardCardDiagnostics.newHideOperation(owner, attach, null, at + 50)
            val cleanup = KeyguardCardDiagnostics.newHideOperation(owner, attach, null, at + 70)
            hideIds += checkNotNull(hide.hideOperationId)
            cleanupIds += checkNotNull(cleanup.hideOperationId)
            fun emit(stage: String, time: Long, operation: KeyguardDiagnosticOperation,
                     fields: Map<String, Any?> = emptyMap()) {
                KeyguardCardDiagnostics.captureEvent(context, stage, "r10-verbose-é".repeat(20),
                    observedUptimeMs = time, diagnosticContext = owner, operation = operation, fields = fields)
            }
            emit("SHOW_FOR_ATTACH", at + 1, show, mapOf("presentationMode" to "ORB"))
            emit("ADD_VIEW_BEGIN", at + 2, show)
            emit("ADD_VIEW_RETURN", at + 3, show)
            emit("POST_ADD_SETUP_COMPLETE", at + 4, show)
            emit("FIRST_ROOT_DRAW", at + 5, show)
            emit("HIDE_DECIDED", at + 51, hide)
            emit("LOCAL_HIDE_BEGIN", at + 52, hide, mapOf("attachedBefore" to true))
            emit("LOCAL_HIDE_APPLIED", at + 53, hide)
            emit("REMOVE_VIEW_RETURN", at + 54, hide)
            repeat(8) { event ->
                emit("R09_RETIREMENT", at + 55 + event, hide,
                    mapOf("r09Stage" to "final-clear-$event", "r09Lease" to "$attach/7",
                        "r09Child" to 10000 + index, "r09Slot" to event, "r09Use" to event + 10))
            }
            emit("HIDE_DECIDED", at + 71, cleanup)
            emit("LOCAL_HIDE_BEGIN", at + 72, cleanup, mapOf("attachedBefore" to false))
            emit("HIDE_COMPLETED", at + 73, cleanup, mapOf("attachedAfter" to false))
            val gaps = when (index) {
                0 -> listOf(20_000_000L, 19_000_000L, 18_000_000L)
                1 -> listOf(35_000_000L, 30_000_000L)
                2 -> listOf(118_000_000L, 40_000_000L)
                else -> listOf(177_000_000L, 60_000_000L)
            }.mapIndexed { sample, gap ->
                "gapNs=$gap cbIn=100 cbOut=200 drawStart=300 drawEnd=400 attach=$attach sample=$sample " + "x=1 ".repeat(240)
            }.joinToString("\n")
            emit("ATTACHMENT_RENDER_SUMMARY", at + 74, hide,
                mapOf("r08Route" to "ISOLATED", "r09FirstWork" to "attach:1,gen:2,request:20001,start:20002,result:20003",
                    "r10Cold0" to "a:1,g:2,request:20001,submit:20002,result:20003",
                    "orbDrawGaps" to gaps, "drawGapCount" to gaps.lines().size))
            repeat(if (index == 3) 549 else 550) { event ->
                KeyguardCardDiagnostics.captureEvent(context, "R10_FIXTURE_NOISE", "é".repeat(160),
                    observedUptimeMs = at + 100 + event, diagnosticContext = owner,
                    fields = mapOf("sample" to event, "long" to "á".repeat(400)))
                if (event % 100 == 99) KeyguardCardDiagnostics.captureSnapshot(context)
            }
        }
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        val recorded = Regex("eventsRecorded=([0-9]+)").find(report)?.groupValues?.get(1)?.toLongOrNull() ?: 0L
        assertTrue("fixture must exercise at least 2199 real queued records: $recorded", recorded >= 2199L)
        assertTrue("actual global worst detailed gap must survive", report.lineSequence().any {
            it.startsWith(" DRAW_GAP ") && it.contains("attempt=4 ") && it.contains("gapNs=177000000 ") &&
                it.contains("cbIn=100") && it.contains("drawEnd=400")
        })
        hideIds.forEach { assertTrue("actual withdrawal $it missing", report.contains("hideOp=$it ")) }
        cleanupIds.forEach { assertTrue("terminal cleanup $it missing", report.contains("hideOp=$it ")) }
        assertTrue(report.contains("R10_COMPACT"))
        assertTrue(report.contains("r10Cold0="))
        assertTrue(report.contains("omittedEvidenceRecords="))
        assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32 * 1024)
    }

    private fun r09WorstGapSurvivesExportPressure(mode: String) {
        KeyguardCardDiagnostics.startCapture(context, "r09-gap-$mode", "profile", mode)
        repeat(4) { index ->
            val attach = index + 1L
            val at = 10_000L * attach
            val owner = checkNotNull(KeyguardCardDiagnostics.beginLockAttempt(context, 909L, attach, "wake", at))
            val show = KeyguardCardDiagnostics.newShowOperation(owner, attach, null)
            val hide = KeyguardCardDiagnostics.newHideOperation(owner, attach, null, at + 50)
            fun emit(stage: String, time: Long, operation: KeyguardDiagnosticOperation, fields: Map<String, Any?> = emptyMap()) {
                KeyguardCardDiagnostics.captureEvent(context, stage, "r09-gap-fixture", observedUptimeMs = time,
                    diagnosticContext = owner, operation = operation, fields = fields)
            }
            emit("SHOW_FOR_ATTACH", at + 1, show)
            emit("ADD_VIEW_RETURN", at + 2, show)
            emit("HIDE_DECIDED", at + 51, hide)
            emit("LOCAL_HIDE_BEGIN", at + 52, hide, mapOf("attachedBefore" to true))
            emit("LOCAL_HIDE_APPLIED", at + 53, hide)
            emit("REMOVE_VIEW_RETURN", at + 54, hide)
            val worst = when (index) { 3 -> 177_000_000L; 2 -> 118_000_000L; else -> 20_000_000L }
            val orb = (0..2).joinToString("\n") { sample ->
                "gapNs=${worst - sample} attach=$attach sample=$sample " + "x=1 ".repeat(260)
            }
            val background = (0..2).joinToString("\n") { sample ->
                "gapNs=${1_000_000L - sample} attach=$attach sample=$sample " + "x=1 ".repeat(260)
            }
            emit("ATTACHMENT_RENDER_SUMMARY", at + 55, hide,
                mapOf("drawEvidenceMode" to mode, "orbDrawGaps" to orb, "backgroundDrawGaps" to background,
                    "r08Route" to "PRESSURE_VIEW", "drawGapCount" to 3))
        }
        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
        val gaps = report.lineSequence().filter { it.startsWith(" DRAW_GAP ") }.toList()
        assertTrue("largest final attachment gap must survive: $gaps", gaps.isNotEmpty())
        assertTrue(gaps.first().contains("attempt=4 ") && gaps.first().contains("gapNs=177000000 "))
        if (gaps.size > 1) assertTrue(gaps[1].contains("attempt=3 ") && gaps[1].contains("gapNs=118000000 "))
        assertTrue(report.contains("omittedDrawGapRecordIds="))
        assertTrue(report.toByteArray(Charsets.UTF_8).size <= 32 * 1024)
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
