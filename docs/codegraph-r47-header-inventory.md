# R47 exact-source active header and route inventory

Application source: `af20365a5ec96ff92b35321a03c0a2679ee7d2fd`

The SCIP graph covers Dart only. Kotlin lines below are direct source navigation, not generated edges or proof of runtime behavior. Native submission and transaction receipts are not physical pixels.

```text
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:30:    @Test fun r44PerWakeEvidenceSurvivesLightPressure() = r44EvidencePressure("LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:31:    @Test fun r44PerWakeEvidenceSurvivesFullPressure() = r44EvidencePressure("FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:36:    @Test fun r447LatestPreIssueDecisionSurvivesLightPressure() = r447LatestDecision("LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:37:    @Test fun r447LatestPreIssueDecisionSurvivesFullPressure() = r447LatestDecision("FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:39:    @Test fun r448BoundaryAndVetoSurviveLightPressure() = r448Pressure("LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:40:    @Test fun r448BoundaryAndVetoSurviveFullPressure() = r448Pressure("FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:42:    @Test fun r448TwoFrozenRouteSummariesRemainDistinct() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:43:        val routePrefs = context.getSharedPreferences("fluvi_keyguard_r448_display_route", android.content.Context.MODE_PRIVATE)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:44:        val summaryPrefs = context.getSharedPreferences("fluvi_keyguard_r448_comparison", android.content.Context.MODE_PRIVATE)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:49:        fun capture(route: KeyguardR448DisplayRoute, session: Long, wake: Long): String {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:50:            assertTrue(KeyguardR448DisplayRouteStore.write(context, route))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:51:            val started = KeyguardCardDiagnostics.startCapture(context, "r448-ab", "profile", "LIGHT",
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:55:            KeyguardCardDiagnostics.recordR446(KeyguardR446Observation(owner, 990, wake, 11,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:58:            KeyguardCardDiagnostics.recordR45(KeyguardR45Observation(owner, route.name, "INTENT", 1001, detail = "ORB"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:59:            KeyguardCardDiagnostics.recordR45(KeyguardR45Observation(owner, route.name, "REVEAL", 1002, detail = "visible"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:60:            KeyguardCardDiagnostics.freezeCapture(context)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:64:            val a = capture(KeyguardR448DisplayRoute.FLUVI_STREAM, 9448, 1)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:65:            val b = capture(KeyguardR448DisplayRoute.WIDGETS_ANYWHERE, 9449, 2)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:67:            val combined = KeyguardR448ComparisonStore.export(context)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:70:            assertEquals(combined, 2, combined.lineSequence().count { it.startsWith("R45_LIFECYCLE ") && it.contains("shape=ORB") })
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:73:            assertEquals(combined, KeyguardR448ComparisonStore.export(context))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:85:    @Test fun r45ComparisonKeepsThreeWakeReceiptsBeforeVerboseRows() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:89:                append("R44_9_ADMISSION wake=$i ").append("x".repeat(1400)).append('\n')
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:90:                append("R45_LIFECYCLE wake=$i shape=ORB reveal=1000\n")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:91:                append("R45_EVENT wake=$i decision=REASSESS\n")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:92:                append("R45_RECOVERY wake=$i result=ALLOW\n")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:95:        val summary = KeyguardR448ComparisonStore.summarize("capture", report)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:97:            assertTrue(summary, summary.contains("R45_LIFECYCLE wake=$i "))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:98:            assertTrue(summary, summary.contains("R45_EVENT wake=$i "))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:99:            assertTrue(summary, summary.contains("R45_RECOVERY wake=$i "))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:104:    private fun r448Pressure(mode: String) {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:105:        KeyguardCardDiagnostics.startCapture(context, "r448-pressure", "profile", mode,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:110:        val boundary = KeyguardR448BoundaryObservation(owner, 5, 7010, 40, null, 40, false,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:111:            KeyguardR448WakeReadBoundary.Decision.OFFER)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:112:        KeyguardCardDiagnostics.recordR448Boundary(boundary)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:113:        KeyguardCardDiagnostics.recordR448Worker(KeyguardR448WorkerObservation(owner, 5, 41, 7011,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:115:        val veto = KeyguardR448SystemVeto(owner, 5, 99, false, "display", 7020, 7021,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:117:        KeyguardCardDiagnostics.recordR448SystemVeto(veto)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:118:        KeyguardCardDiagnostics.recordR448SystemVeto(veto.copy(requestId = 100, reason = "later"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:119:        val frameOwner = KeyguardR448WidgetsAnywhereFrame.Owner(3, 7, 8)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:120:        fun frame(stage: String, at: Long) = KeyguardCardDiagnostics.recordR448Frame(
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:121:            KeyguardR448FrameObservation(owner, frameOwner, stage, at, null))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:134:        val clear = KeyguardR448Admission.Presence.CLEAR
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:135:        val exclusions = KeyguardR448Admission.Exclusions(7028, clear, clear, clear, clear)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:136:        val admission = KeyguardR449AdmissionObservation(owner, 5, 3, 8, 4, "ONE_WAKE", 7010,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:138:            exclusions, "CLEAR", KeyguardR448Admission.Decision.ALLOW, 7029,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:139:            KeyguardR448Admission.Domain.PRIVATE)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:140:        KeyguardCardDiagnostics.recordR449Admission(admission)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:141:        val waOutput = KeyguardR446Observation(owner, 6990, 7, 0, "NOT_REQUIRED", "CLEAR", "WA_SHADER_DRAW",
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:143:        KeyguardCardDiagnostics.recordR446(waOutput)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:144:        KeyguardCardDiagnostics.recordR45(KeyguardR45Observation(owner, "WIDGETS_ANYWHERE", "INTENT", 7005, detail = "ORB"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:145:        KeyguardCardDiagnostics.recordR45(KeyguardR45Observation(owner, "WIDGETS_ANYWHERE", "INGRESS", 7071,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:148:        KeyguardCardDiagnostics.recordR45(KeyguardR45Observation(owner, "WIDGETS_ANYWHERE", "RECOVERY", 7075,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:153:            KeyguardCardDiagnostics.recordR45(KeyguardR45Observation(owner, "WIDGETS_ANYWHERE", stage, at, detail = "test"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:157:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:158:        val read = report.lineSequence().single { it.startsWith("R44_8_READ_BOUNDARY ") }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:159:        val gate = report.lineSequence().single { it.startsWith("R44_8_SYSTEM_VETO ") }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:160:        val wa = report.lineSequence().single { it.startsWith("R44_8_WA ") }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:161:        val admitted = report.lineSequence().single { it.startsWith("R44_9_ADMISSION ") }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:162:        val sample = report.lineSequence().single { it.startsWith("R44_6_SAMPLE ") }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:163:        val life = report.lineSequence().single { it.startsWith("R45_LIFECYCLE ") }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:164:        val event = report.lineSequence().single { it.startsWith("R45_EVENT ") }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:165:        val recovery = report.lineSequence().single { it.startsWith("R45_RECOVERY ") }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:183:        KeyguardCardDiagnostics.recordR448SystemVeto(veto.copy(requestId = 101))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:184:        KeyguardCardDiagnostics.recordR449Admission(admission.copy(reason = "LATE"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:185:        KeyguardCardDiagnostics.recordR45(KeyguardR45Observation(owner, "WIDGETS_ANYWHERE", "TERMINAL", 9999, detail = "LATE"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:192:    private fun r447LatestDecision(mode: String) {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:193:        KeyguardCardDiagnostics.startCapture(context, "r447-pressure", "profile", mode,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:198:        val first = KeyguardR446Observation(owner, 990, 3, 40,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:201:        KeyguardCardDiagnostics.recordR446(first)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:202:        KeyguardCardDiagnostics.recordR446(first.copy(request = 43, eligibility = "SCENE_CHANGED"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:203:        KeyguardCardDiagnostics.recordR446(first.copy(request = 44, eligibility = "NEWER_COMPLETED"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:204:        KeyguardCardDiagnostics.recordR446(first.copy(request = 45, eligibility = "NEWER_BARRIER_REQUIRED"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:207:        val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:208:        val row = frozen.lineSequence().single { it.startsWith("R44_6_SAMPLE ") }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:213:        KeyguardCardDiagnostics.recordR446(first.copy(request = 46, eligibility = "LATE_CALLBACK"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:217:    @Test fun r447ProgressAndTerminalRemainWithTheirOriginalRequest() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:218:        KeyguardCardDiagnostics.startCapture(context, "r447-order", "profile", "FULL",
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:223:        val first = KeyguardR446Observation(owner, 6990, 7, 40, "UNKNOWN/NO_MAIN_MARKER",
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:225:            armGeneration = 2, decisionOrdinal = 1, handoff = KeyguardR447Disposition.NEWER_BARRIER_REQUIRED)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:226:        val issued = first.copy(request = 44, decisionOrdinal = 2, handoff = KeyguardR447Disposition.ISSUED,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:228:        KeyguardCardDiagnostics.recordR446(first)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:229:        KeyguardCardDiagnostics.recordR446(issued)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:230:        KeyguardCardDiagnostics.recordR446(first.copy(request = 45, decisionOrdinal = 3,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:231:            handoff = KeyguardR447Disposition.ARM_MISMATCH))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:233:        KeyguardCardDiagnostics.recordR446(laterFrame)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:234:        KeyguardCardDiagnostics.recordR446(laterFrame.retireOnce(7090, "duplicate", null, null, null))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:237:        KeyguardCardDiagnostics.recordR446(first.copy(request = 99, decisionOrdinal = 99, armGeneration = 1))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:241:        KeyguardCardDiagnostics.recordR446(first.copy(context = unarmed, wake = 8, request = 0,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:243:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:244:        val rows = report.lineSequence().filter { it.startsWith("R44_6_SAMPLE ") }.toList()
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:257:    @Test fun r447TerminalBeforeAnyWakeSurvivesFreezeAndLateCleanup() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:258:        KeyguardCardDiagnostics.startCapture(context, "r447-arm", "profile", "LIGHT",
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:261:        KeyguardCardDiagnostics.recordR447ArmTerminal(capture, 4, 111, "serviceLost")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:262:        KeyguardCardDiagnostics.recordR447ArmTerminal(capture, 4, 222, "duplicateCleanup")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:263:        val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:264:        assertTrue(frozen, frozen.contains("R44_7_ARM generation=4 terminal=111/serviceLost"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:265:        KeyguardCardDiagnostics.recordR447ArmTerminal(capture, 4, 333, "lateCallback")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:270:        KeyguardCardDiagnostics.startCapture(context, "r446-pressure", "profile", mode,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:272:        var first: KeyguardR446Observation? = null
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:278:            val missing = KeyguardR446Observation(owner, base - 10, wake, base + 1,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:282:            KeyguardCardDiagnostics.recordR446(missing)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:288:            KeyguardCardDiagnostics.recordR446(shown)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:295:        val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:297:        assertEquals(6, frozen.lineSequence().count { it.startsWith("R44_6_SAMPLE ") })
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:304:        KeyguardCardDiagnostics.recordR446(checkNotNull(first).copy(backend = "LATE_CALLBACK"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:309:        KeyguardCardDiagnostics.startCapture(context, "r444-reason", "profile", "LIGHT", r442ExpectedSession = 9444)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:315:            KeyguardCardDiagnostics.recordR44(KeyguardR44ReadObservation(owner, base + 20, wake, wake,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:318:                KeyguardR44Witness(KeyguardR44Markers.Marker.HOST, KeyguardR44Markers.Carrier.EXTRA_LAZY, 20),
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:321:                r443Candidates = if (failed > 0) listOf(KeyguardR443CandidateObservation(
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:326:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:337:        KeyguardCardDiagnostics.startCapture(context, "r444-pressure", "profile", mode, r442ExpectedSession = 9445)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:347:            val candidates = (1..7).map { n -> KeyguardR443CandidateObservation(969, n, "HOST", n,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:349:            KeyguardCardDiagnostics.recordR44(KeyguardR44ReadObservation(owner, base + 30, wake, wake,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:353:                KeyguardR44Witness(KeyguardR44Markers.Marker.HOST, KeyguardR44Markers.Carrier.EXTRA_LAZY, 20),
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:356:                appliedGate = if (empty) KeyguardR444Gate.INCOMPLETE else KeyguardR444Gate.NO_CONTENT,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:361:                    KeyguardR445IndexCall("SMALL", "EMPTY", 12, 123, 0),
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:362:                    KeyguardR445IndexCall("LARGE", "INELIGIBLE", 13, 136, 0),
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:363:                    KeyguardR445IndexCall("ENTRY", "EMPTY", 17, 150, 3)),
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:364:                r444Windows = listOf(KeyguardR444WindowObservation(972, 0, 3, false, false,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:367:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:369:        assertEquals(8, report.lineSequence().count { it.startsWith("R44_4_HU ") })
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:370:        assertEquals(3, report.lineSequence().count { it.startsWith("R44_WAKE ") && it.contains("firstPostRead=missing") })
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:375:        assertEquals(5, report.lineSequence().count { it.startsWith("R44_5_INDEX ") })
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:376:        assertEquals(15, report.lineSequence().count { it.startsWith("R44_5_ID ") })
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:381:        KeyguardCardDiagnostics.startCapture(context, "r442-fixture", "profile", "LIGHT", r442ExpectedSession = 945)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:385:        KeyguardCardDiagnostics.recordR442Handoff(KeyguardR442HandoffObservation(
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:388:            KeyguardCardDiagnostics.recordR44(KeyguardR44ReadObservation(owner, id, 1, 1,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:394:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:397:        val handoff = report.lineSequence().single { it.startsWith("R44_2_HANDOFF ") }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:404:    private fun r44EvidencePressure(mode: String) {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:405:        KeyguardCardDiagnostics.startCapture(context, "r44-fixture", "profile", mode, r442ExpectedSession = 944)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:414:            fun record(request: Long, start: Long, verdict: KeyguardSurface) = KeyguardCardDiagnostics.recordR44(
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:415:                KeyguardR44ReadObservation(owner, request, wake, wake + 50, start, start + 5,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:419:                    KeyguardR44Witness(KeyguardR44Markers.Marker.HOST, KeyguardR44Markers.Carrier.VIEW_ID, 1),
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:420:                    KeyguardR44Witness(KeyguardR44Markers.Marker.DEVICE_ENTRY, KeyguardR44Markers.Carrier.EXTRA_EAGER, 2),
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:426:                    firstCandidate = KeyguardR44Markers.Marker.DEVICE_ENTRY,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:427:                    firstCarrier = KeyguardR44Markers.Carrier.VIEW_ID, cover = "VETO_UNKNOWN_OR_COVER", receipt = "armed",
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:428:                    r443Windows = listOf(KeyguardR443WindowObservation(10, 7, 7, 0, true)),
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:429:                    r443Candidates = (1..7).map { n -> KeyguardR443CandidateObservation(
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:432:            KeyguardCardDiagnostics.recordR442Handoff(KeyguardR442HandoffObservation(
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:435:            KeyguardCardDiagnostics.recordR443Boundary(KeyguardR443BoundaryObservation(
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:452:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:455:            val row = report.lineSequence().single { it.startsWith("R44_WAKE ") && it.contains("wake=$wake ") }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:458:            assertTrue(report, report.contains("R44_2_HANDOFF old=${wake * 1000 + 1} next=${wake * 1000 + 2} "))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:459:            assertTrue(report, report.contains("R44_2_EVIDENCE req=${wake * 1000 + 2} lookup=VERIFIED"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:460:            assertTrue(report, report.contains("R44_3_JEL req=${wake * 1000 + 2} window=10 ordinal=7"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:461:            assertTrue(report, report.contains("R44_3_BOUNDARY old=${wake * 1000 + 1}"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:464:        assertEquals(6, report.lineSequence().count { it.startsWith("R44_HU ") })
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:467:        KeyguardCardDiagnostics.recordR44(KeyguardR44ReadObservation(checkNotNull(firstOwner), 9999, 0, null,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:481:                KeyguardCardDiagnostics.startCapture(context, "r26-pressure", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:533:                val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:574:        KeyguardCardDiagnostics.startCapture(context, "r25-fixture", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:602:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:611:        KeyguardCardDiagnostics.startCapture(context, "r25-new", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:614:        val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:622:        KeyguardCardDiagnostics.startCapture(context, "r22-4", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:641:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:652:        KeyguardCardDiagnostics.startCapture(context, "r22-4-new", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:656:        val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:664:        KeyguardCardDiagnostics.startCapture(context, "r22-2", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:679:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:699:        KeyguardCardDiagnostics.startCapture(context, "r22-1", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:751:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:763:        KeyguardCardDiagnostics.startCapture(context, "new", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:766:        val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:784:            KeyguardCardDiagnostics.startCapture(context, "r31", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:824:            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:835:            KeyguardCardDiagnostics.startCapture(context, "r31-next", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:838:            val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:856:            KeyguardCardDiagnostics.startCapture(context, "r32", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:881:            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:895:            KeyguardCardDiagnostics.startCapture(context, "r32-next", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:900:            val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:918:            KeyguardCardDiagnostics.startCapture(context, "r34", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:945:            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:960:            KeyguardCardDiagnostics.startCapture(context, "r34-next", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:964:            assertFalse((KeyguardCardDiagnostics.freezeCapture(context)["report"] as String).contains("reservation=704"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:978:        KeyguardCardDiagnostics.startCapture(context, "r18-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1020:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1039:        KeyguardCardDiagnostics.startCapture(context, "r18-new", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1043:        val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1051:        KeyguardCardDiagnostics.startCapture(context, "r19-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1097:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1121:            KeyguardCardDiagnostics.startCapture(context, "r22-token-pressure", "profile", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1147:            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1172:            KeyguardCardDiagnostics.startCapture(context, "r21-pressure", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1292:            val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1357:            KeyguardCardDiagnostics.startCapture(context, "r20-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1384:            val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1409:            KeyguardCardDiagnostics.startCapture(context, "r13-pressure", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1434:            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1446:        KeyguardCardDiagnostics.startCapture(context, "r13-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1465:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1477:        KeyguardCardDiagnostics.startCapture(context, "r13-new", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1480:        val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1485:        KeyguardCardDiagnostics.startCapture(context, "r12-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1512:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1533:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1545:        val frozen = KeyguardCardDiagnostics.freezeCapture(context)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1558:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1560:        val before = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1575:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1584:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1592:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1624:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1641:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1678:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1694:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug", "FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1726:        val frozen = KeyguardCardDiagnostics.freezeCapture(context)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1749:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug", "FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1782:        val frozen = KeyguardCardDiagnostics.freezeCapture(context)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1795:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1828:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1842:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1854:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1859:        KeyguardCardDiagnostics.startCapture(context, "old-sha", "debug")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1863:        KeyguardCardDiagnostics.startCapture(context, "new-sha", "debug")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1873:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1879:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1899:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1905:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1946:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1953:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug", "FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1976:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1984:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1993:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2002:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2003:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2017:        KeyguardCardDiagnostics.startCapture(context, "light-sha", "debug", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2021:        KeyguardCardDiagnostics.freezeCapture(context)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2023:        KeyguardCardDiagnostics.startCapture(context, "full-sha", "debug", "FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2025:        KeyguardCardDiagnostics.freezeCapture(context)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2032:        KeyguardCardDiagnostics.startCapture(context, "async-sha", "debug", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2057:        val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2089:            val captureId = KeyguardCardDiagnostics.startCapture(context, source, "profile", mode)["captureId"].toString()
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2155:            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2184:        KeyguardCardDiagnostics.startCapture(context, source, "profile", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2186:        val off = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2194:            KeyguardCardDiagnostics.startCapture(context, "r15-owner", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2205:            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2218:        KeyguardCardDiagnostics.startCapture(context, source, "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2286:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2315:        KeyguardCardDiagnostics.startCapture(context, source, "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2337:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2354:        KeyguardCardDiagnostics.startCapture(context, "$source-rotated", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2357:        val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2363:        KeyguardCardDiagnostics.startCapture(context, source, "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2416:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2439:        KeyguardCardDiagnostics.startCapture(context, "$source-rotated", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2442:        val rotated = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2449:        KeyguardCardDiagnostics.startCapture(context, source, "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2525:        val frozen = KeyguardCardDiagnostics.freezeCapture(context)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2579:            KeyguardCardDiagnostics.startCapture(context, "r07-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2633:            val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2659:            KeyguardCardDiagnostics.startCapture(context, "new-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2662:            val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2671:        KeyguardCardDiagnostics.startCapture(context, "r08-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2711:        val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2720:        KeyguardCardDiagnostics.startCapture(context, "r08-next-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2724:        val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2729:        KeyguardCardDiagnostics.startCapture(context, "identity-check", "debug", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2740:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2746:        KeyguardCardDiagnostics.startCapture(context, "draw-gap-identity", "profile", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2761:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2793:        KeyguardCardDiagnostics.startCapture(context, "r11-visible-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2820:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2831:        KeyguardCardDiagnostics.startCapture(context, "r11-new-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2838:        val nextReport = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2845:        KeyguardCardDiagnostics.startCapture(context, "r10-export-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2898:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2914:        KeyguardCardDiagnostics.startCapture(context, "r09-gap-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2942:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2953:        KeyguardCardDiagnostics.startCapture(context, "draw-owner", "profile", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2956:        KeyguardCardDiagnostics.freezeCapture(context)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2958:        KeyguardCardDiagnostics.startCapture(context, "draw-owner", "profile", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2964:        KeyguardCardDiagnostics.startCapture(context, "gap-bounds", "debug", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2971:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:40:class KeyguardFirstAuthorizedOrbInstrumentationTest {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:126:            KeyguardCardDiagnostics.startCapture(context, source, "debug", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:268:            report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:301:                report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:374:            KeyguardCardDiagnostics.startCapture(context, source, "debug", "LIGHT"); capture = true
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbInstrumentationTest.kt:495:            if(capture) runCatching { File(dir,"frozen.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"] as String) }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationPipelineInstrumentationTest.kt:867:                val positive = KeyguardCardVisibilityPolicy.decide(KeyguardCardSignals(true, true, true, true,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationPipelineInstrumentationTest.kt:917:                val negative = KeyguardCardVisibilityPolicy.decide(KeyguardCardSignals(true, true, true, true,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR12ServiceTimingInstrumentationTest.kt:249:            val capture = KeyguardCardDiagnostics.startCapture(context, source, "debug", "FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR12ServiceTimingInstrumentationTest.kt:341:                File(output, "capture.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"].toString())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR15HeldCanvasInstrumentationTest.kt:120:            val capture = KeyguardCardDiagnostics.startCapture(context, source, "debug", "FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR15HeldCanvasInstrumentationTest.kt:263:                File(output, "capture.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"].toString())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:212:            KeyguardCardDiagnostics.startCapture(context, source, "debug", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt:860:                    report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22RecoveryInstrumentationTest.kt:33:        KeyguardCardDiagnostics.startCapture(context, source, "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22RecoveryInstrumentationTest.kt:75:        val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR25ServiceInstrumentationTest.kt:187:            KeyguardCardDiagnostics.startCapture(context, source, "debug", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR25ServiceInstrumentationTest.kt:399:                File(dir, "capture.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"] as String)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR26DirectOrderingInstrumentationTest.kt:136:            KeyguardCardDiagnostics.startCapture(context,source,"debug","LIGHT"); capture=true
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR26DirectOrderingInstrumentationTest.kt:251:                        val proof=(gateField.get(actual) as KeyguardFirstAuthorizedOrb).current()
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR26DirectOrderingInstrumentationTest.kt:407:            if(capture) runCatching { File(dir,"frozen.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"] as String) }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:35:        KeyguardCardDiagnostics.startCapture(context, "r42-winning-offer", "profile", "FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:50:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:65:        KeyguardCardDiagnostics.startCapture(context, "r42-raw-pressure", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:84:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:108:            KeyguardCardDiagnostics.startCapture(context, "r41-empty-r22", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:113:            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:124:            KeyguardCardDiagnostics.startCapture(context, "r41-shared-cause", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:160:            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:178:        KeyguardCardDiagnostics.startCapture(context, "r41-direct-pressure", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:217:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:229:        KeyguardCardDiagnostics.startCapture(context, "r41-25-requests", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:242:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:255:        KeyguardCardDiagnostics.startCapture(context, "r41-raw-owner", "profile", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:289:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:307:        KeyguardCardDiagnostics.startCapture(context, "r41-new-owner", "profile", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:314:        val newReport = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:322:        KeyguardCardDiagnostics.startCapture(context, "r41-burst", "profile", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:341:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:350:        KeyguardCardDiagnostics.startCapture(context, "r41-pressure", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR41DiagnosticsInstrumentationTest.kt:377:        val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR43DiagnosticsInstrumentationTest.kt:16:        KeyguardCardDiagnostics.startCapture(context, "r43-busy", "debug", "LIGHT", true)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR43DiagnosticsInstrumentationTest.kt:33:            val after = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR43DiagnosticsInstrumentationTest.kt:45:        KeyguardCardDiagnostics.startCapture(context, "r43-old", "debug", "LIGHT", true)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR43DiagnosticsInstrumentationTest.kt:51:            KeyguardCardDiagnostics.freezeCapture(context)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR43DiagnosticsInstrumentationTest.kt:53:            KeyguardCardDiagnostics.startCapture(context, "r43-new", "debug", "LIGHT", true)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR43DiagnosticsInstrumentationTest.kt:55:            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR43DiagnosticsInstrumentationTest.kt:66:        KeyguardCardDiagnostics.startCapture(context, "r43-test", "debug", "LIGHT", true)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR43DiagnosticsInstrumentationTest.kt:90:            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR441HolderReproInstrumentationTest.kt:28:class KeyguardR441HolderReproInstrumentationTest {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR442OwnerInstrumentationTest.kt:27:class KeyguardR442OwnerInstrumentationTest {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR442OwnerInstrumentationTest.kt:99:            assertTrue(KeyguardR44Trial.active)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR442OwnerInstrumentationTest.kt:100:            assertNotNull(KeyguardR44Trial.profile(null))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR442OwnerInstrumentationTest.kt:101:            assertFalse(KeyguardR44Trial.settings(KeyguardCardSettings(showFinancialDetails = true)).showFinancialDetails)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR442OwnerInstrumentationTest.kt:108:            KeyguardCardDiagnostics.startCapture(context, "other", "debug", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR442OwnerInstrumentationTest.kt:114:            assertFalse(KeyguardR44Trial.active)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR442OwnerInstrumentationTest.kt:115:            assertTrue(main { service.setR44SyntheticTrial(false) })
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR442OwnerInstrumentationTest.kt:121:            assertFalse(KeyguardR44Trial.active)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR445WindowCompositionTest.kt:45:class KeyguardR445WindowCompositionTest {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR445WindowCompositionTest.kt:97:            KeyguardR44Trial.set(true, true)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR445WindowCompositionTest.kt:98:            if (capture) KeyguardCardDiagnostics.startCapture(context, "r445-composition", "debug", "FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR445WindowCompositionTest.kt:99:            val profile = checkNotNull(KeyguardR44Trial.profile(null))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR445WindowCompositionTest.kt:257:            KeyguardR44Trial.set(false, false)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR446StockServiceInstrumentationTest.kt:31:class KeyguardR446StockServiceInstrumentationTest {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR446StockServiceInstrumentationTest.kt:97:            assertTrue(KeyguardR44Trial.active)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR446StockServiceInstrumentationTest.kt:98:            assertFalse(KeyguardR44Trial.settings(KeyguardCardSettings(showFinancialDetails = true)).showFinancialDetails)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR446StockServiceInstrumentationTest.kt:112:            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR446StockServiceInstrumentationTest.kt:114:            assertTrue("NOT REACHED: actual stock wake sample observation\n$report", report.contains("R44_6_SAMPLE"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenterInstrumentationTest.kt:44:class KeyguardR446WindowPresenterInstrumentationTest {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenterInstrumentationTest.kt:83:        var presenter: KeyguardR446WindowPresenter? = null
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenterInstrumentationTest.kt:97:            KeyguardR44Trial.set(true, true)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenterInstrumentationTest.kt:98:            if (capture) KeyguardCardDiagnostics.startCapture(context, "r446-composition", "debug", "FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenterInstrumentationTest.kt:99:            val profile = checkNotNull(KeyguardR44Trial.profile(null))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenterInstrumentationTest.kt:190:            val target = KeyguardR446Target(hostId, 0,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenterInstrumentationTest.kt:191:                KeyguardR446Bounds(hostBounds.left, hostBounds.top, hostBounds.right, hostBounds.bottom))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenterInstrumentationTest.kt:250:                    save("r45-direct-concealed-${hiddenAttempt++}", shot)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenterInstrumentationTest.kt:300:            KeyguardR44Trial.set(false, false)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:35:class KeyguardR447HandoffServiceInstrumentationTest {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:70:                try { result.set(owner.startR446PrintCapture("r447-fixture", "debug", "FULL")) }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:112:                owner.setR448DisplayRoute(KeyguardR448DisplayRoute.WIDGETS_ANYWHERE)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:119:                override fun r447ControlledSampleTopology() = true
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:128:                override fun r447SampleReadCompleted(request: KeyguardCardInspectionRequest,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:129:                    eligibility: KeyguardR446Eligibility?, stale: Boolean) {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:142:                override fun r447PresenterInvoked(request: Long) {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:163:                    report.lineSequence().any { it.startsWith("R44_6_SAMPLE ") &&
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:169:                    File(out, "r448-controlled-service.png").outputStream().use { shot.compress(Bitmap.CompressFormat.PNG, 100, it) }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:174:            waitFor("sampler idle") { main { owner.r447SamplerIdleForTest() } }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:175:            main { owner.r447ScheduleOutputReadyForTest() }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:177:            val order = main { owner.r447SampleOrderForTest(first.get()) }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:179:            assertEquals("NOT REACHED: proven internal offer", KeyguardFirstAuthorizedOrb.SampleOffer.INTERNAL_DUPLICATE, order.origin)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:187:                    report.lineSequence().any { it.startsWith("R44_6_SAMPLE ") &&
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:197:                    report.lineSequence().any { it.startsWith("R44_6_SAMPLE ") &&
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:204:                    File(out, "r447-controlled-sample.png").outputStream().use { shot.compress(Bitmap.CompressFormat.PNG, 100, it) }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:217:                runCatching { File(out, "r447-report.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"] as String) }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR447HandoffServiceInstrumentationTest.kt:220:            File(out, "r447-evidence.txt").writeText(synchronized(note) { note.toString() } +
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448DisplayRouteInstrumentationTest.kt:14:class KeyguardR448DisplayRouteInstrumentationTest {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448DisplayRouteInstrumentationTest.kt:17:        val prefs = context.getSharedPreferences("fluvi_keyguard_r448_display_route", Context.MODE_PRIVATE)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448DisplayRouteInstrumentationTest.kt:23:            assertEquals(KeyguardR448DisplayRoute.FLUVI_STREAM, KeyguardR448DisplayRouteStore.read(context))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448DisplayRouteInstrumentationTest.kt:24:            assertTrue(KeyguardR448DisplayRouteStore.write(context, KeyguardR448DisplayRoute.WIDGETS_ANYWHERE))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448DisplayRouteInstrumentationTest.kt:25:            assertEquals(KeyguardR448DisplayRoute.WIDGETS_ANYWHERE, KeyguardR448DisplayRouteStore.read(context))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448DisplayRouteInstrumentationTest.kt:27:            assertTrue(KeyguardR448DisplayRouteStore.write(context, KeyguardR448DisplayRoute.FLUVI_STREAM))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448DisplayRouteInstrumentationTest.kt:28:            assertEquals(KeyguardR448DisplayRoute.FLUVI_STREAM, KeyguardR448DisplayRouteStore.read(context))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448FrameInstrumentationTest.kt:34:class KeyguardR448FrameInstrumentationTest {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448FrameInstrumentationTest.kt:61:        val events = mutableListOf<KeyguardR448WidgetsAnywhereFrame.Event>()
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448FrameInstrumentationTest.kt:66:        var frame: KeyguardR448WidgetsAnywhereFrame? = null
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448FrameInstrumentationTest.kt:67:        val owner = KeyguardR448WidgetsAnywhereFrame.Owner(1, 1, 1)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448FrameInstrumentationTest.kt:68:        val cancelledOwner = KeyguardR448WidgetsAnywhereFrame.Owner(2, 1, 1)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448FrameInstrumentationTest.kt:69:        val postAddOwner = KeyguardR448WidgetsAnywhereFrame.Owner(3, 1, 1)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448FrameInstrumentationTest.kt:70:        val recheckedOwner = KeyguardR448WidgetsAnywhereFrame.Owner(4, 1, 1)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448FrameInstrumentationTest.kt:78:            KeyguardR44Trial.set(true, true)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448FrameInstrumentationTest.kt:79:            val original = checkNotNull(KeyguardR44Trial.profile(null))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448FrameInstrumentationTest.kt:106:                val sample = reference.captureCrop("r448-controlled-underlay-${underlayIndex++}", bounds)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448FrameInstrumentationTest.kt:121:                frame = KeyguardR448WidgetsAnywhereFrame(service, KeyguardMaterialTimeSource { _, _ -> phase.get() })
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448FrameInstrumentationTest.kt:184:            val parkedOwner = KeyguardR448WidgetsAnywhereFrame.Owner(5, 1, 1)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448FrameInstrumentationTest.kt:220:            reference.awaitServiceMatch("r448-controlled-A", bounds, reference.a, stableUnderlay)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448FrameInstrumentationTest.kt:238:            reference.awaitServiceMatch("r45-controlled-resume-A", bounds, reference.a, stableUnderlay)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448FrameInstrumentationTest.kt:240:            reference.awaitServiceMatch("r448-controlled-B", bounds, reference.b, stableUnderlay)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448FrameInstrumentationTest.kt:248:                reference.captureCrop("r448-controlled-after-$index", bounds)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448FrameInstrumentationTest.kt:250:            File(out, "r448-controlled-withdrawal.txt").writeText(samples.mapIndexed { index, sample ->
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448FrameInstrumentationTest.kt:265:            File(out, "r448-controlled-events.txt").writeText(synchronized(events) { events.joinToString("\n", postfix = "\n") })
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448FrameInstrumentationTest.kt:266:            KeyguardR44Trial.set(false, false)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448SampleOnlyInstrumentationTest.kt:26:class KeyguardR448SampleOnlyInstrumentationTest {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448SampleOnlyInstrumentationTest.kt:27:    @Test fun normalPresentationIsClosedAndFixedSampleCanArm() = exercise(KeyguardR448DisplayRoute.FLUVI_STREAM)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448SampleOnlyInstrumentationTest.kt:28:    @Test fun waSampleSessionKeepsItsOwnWakeAuthority() = exercise(KeyguardR448DisplayRoute.WIDGETS_ANYWHERE)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448SampleOnlyInstrumentationTest.kt:30:    private fun exercise(route: KeyguardR448DisplayRoute) {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448SampleOnlyInstrumentationTest.kt:55:        val routePrefs = context.getSharedPreferences("fluvi_keyguard_r448_display_route", android.content.Context.MODE_PRIVATE)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448SampleOnlyInstrumentationTest.kt:62:            assertTrue("NOT REACHED: sample-only variant resource", KeyguardR448Safety.sampleOnly(context))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448SampleOnlyInstrumentationTest.kt:67:            assertTrue(KeyguardR448DisplayRouteStore.write(context, route))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448SampleOnlyInstrumentationTest.kt:75:            assertEquals(Triple(true, false, false), main { owner.r448SafetyForInstrumentation() })
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448SampleOnlyInstrumentationTest.kt:77:                KeyguardR44Trial.set(true, true)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448SampleOnlyInstrumentationTest.kt:78:                val p = checkNotNull(KeyguardR44Trial.profile(null))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448SampleOnlyInstrumentationTest.kt:79:                KeyguardR44Trial.set(false, false)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448SampleOnlyInstrumentationTest.kt:85:                main { owner.r448SafetyForInstrumentation() })
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448SampleOnlyInstrumentationTest.kt:90:                try { receipt.set(owner.startR446PrintCapture("r448-safe-test", "debug", "LIGHT")) }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448SampleOnlyInstrumentationTest.kt:103:                try { sessionReceipt.set(owner.startR449SampleCapture("r449-session-test", "debug", "LIGHT",
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR448SampleOnlyInstrumentationTest.kt:113:            if (route == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44LazyProviderInstrumentationTest.kt:26:class KeyguardR44LazyProviderInstrumentationTest {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44LazyProviderInstrumentationTest.kt:144:                if (node.availableExtraData.contains(KeyguardR44Markers.EXTRA)) return AccessibilityNodeInfo.obtain(node)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44LazyProviderInstrumentationTest.kt:162:                assertNull(node.extras.getCharSequence(KeyguardR44Markers.EXTRA))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44LazyProviderInstrumentationTest.kt:164:                val beforeIdentity = try { KeyguardR443ParentIdentity.of(beforeParent) }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44LazyProviderInstrumentationTest.kt:167:                assertTrue(node.refreshWithExtraData(KeyguardR44Markers.EXTRA, Bundle()))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44LazyProviderInstrumentationTest.kt:168:                assertEquals("element:lockscreen", node.extras.getCharSequence(KeyguardR44Markers.EXTRA).toString())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44LazyProviderInstrumentationTest.kt:171:                val afterIdentity = try { KeyguardR443ParentIdentity.of(afterParent) }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44LazyProviderInstrumentationTest.kt:200:                    availableExtraData = listOf(KeyguardR44Markers.EXTRA)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44LazyProviderInstrumentationTest.kt:205:                if (virtualViewId == 1 && extraDataKey == KeyguardR44Markers.EXTRA && arguments != null) {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44ServiceInstrumentationTest.kt:37:class KeyguardR44ServiceInstrumentationTest {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44ServiceInstrumentationTest.kt:94:        val host = KeyguardR44Witness(KeyguardR44Markers.Marker.HOST, KeyguardR44Markers.Carrier.VIEW_ID, 1)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44ServiceInstrumentationTest.kt:95:        val entry = KeyguardR44Witness(KeyguardR44Markers.Marker.DEVICE_ENTRY, KeyguardR44Markers.Carrier.VIEW_ID, 2)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44ServiceInstrumentationTest.kt:96:        val proof = KeyguardR44WindowEvidence(true, true, host, entry, true, true, false)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44ServiceInstrumentationTest.kt:121:            assertTrue("NOT REACHED: unlocked synthetic trial", main { owner.setR44SyntheticTrial(true) })
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44ServiceInstrumentationTest.kt:122:            assertTrue(KeyguardR44Trial.active)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44ServiceInstrumentationTest.kt:125:                    checkNotNull(KeyguardR44Trial.profile(null)), discloseFull = false).also { it.calibrate() }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44ServiceInstrumentationTest.kt:146:            if (capture) KeyguardCardDiagnostics.startCapture(context, "r44-fixture", "debug", "FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44ServiceInstrumentationTest.kt:281:                val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR44ServiceInstrumentationTest.kt:296:                out.resolve("r44-partial-report.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"] as String)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR46RecordingStoreInstrumentationTest.kt:15:class KeyguardR46RecordingStoreInstrumentationTest {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR46RecordingStoreInstrumentationTest.kt:21:            override fun getFilesDir(): File = File(target.filesDir, "r46-test-$suffix").apply { mkdirs() }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR46RecordingStoreInstrumentationTest.kt:25:        KeyguardR46RecordingStore.begin(isolated, id, "WIDGETS_ANYWHERE", "instrumentation")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR46RecordingStoreInstrumentationTest.kt:26:        repeat(400) { KeyguardR46RecordingStore.offer(id, "wake=$it detail=${"ár".repeat(120)}") }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR46RecordingStoreInstrumentationTest.kt:27:        val report = KeyguardR46RecordingStore.seal(isolated, id, "summary", "USER_STOP")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR46RecordingStoreInstrumentationTest.kt:36:        assertEquals(report, KeyguardR46RecordingStore.sealedReport(isolated, id))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR46RecordingStoreInstrumentationTest.kt:37:        assertEquals(report, KeyguardR46RecordingStore.seal(isolated, id, "different", "RETRY"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR46RecordingStoreInstrumentationTest.kt:38:        KeyguardR46RecordingStore.copied(isolated, id)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR46RecordingStoreInstrumentationTest.kt:39:        assertEquals("COPIED", KeyguardR46RecordingStore.status(isolated)["state"])
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47PreparedFrameInstrumentationTest.kt:21:import com.fluvi.app.lockscreen.material.FluviActiveHeaderMaterialStore
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47PreparedFrameInstrumentationTest.kt:43:class KeyguardR47PreparedFrameInstrumentationTest {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47PreparedFrameInstrumentationTest.kt:92:        fun bytes(name: String): ByteArray = ins.context.assets.open("r47_reference/$name.png").use { it.readBytes() }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47PreparedFrameInstrumentationTest.kt:133:        val channel = MethodChannel(messenger, "r47-prepared-control")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47PreparedFrameInstrumentationTest.kt:140:        var presenter: KeyguardR446WindowPresenter? = null
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47PreparedFrameInstrumentationTest.kt:141:        var frame: KeyguardR448WidgetsAnywhereFrame? = null
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47PreparedFrameInstrumentationTest.kt:142:        var frameOwner: KeyguardR448WidgetsAnywhereFrame.Owner? = null
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47PreparedFrameInstrumentationTest.kt:188:            val profile = value(JSONObject(ins.context.assets.open("r47_reference/tide.json").bufferedReader().use { it.readText() }))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47PreparedFrameInstrumentationTest.kt:192:            assertTrue(FluviActiveHeaderMaterialStore.bindPublisher(epoch, 1, session))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47PreparedFrameInstrumentationTest.kt:193:            val receipt = FluviActiveHeaderMaterialStore.publish(app, input, epoch, true)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47PreparedFrameInstrumentationTest.kt:199:            val admission = FluviActiveHeaderMaterialStore.admitFrames(app, frameInput, epoch)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47PreparedFrameInstrumentationTest.kt:201:            val decoded = requireNotNull(FluviActiveHeaderMaterialStore.decodeFrames(request))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47PreparedFrameInstrumentationTest.kt:202:            assertTrue(FluviActiveHeaderMaterialStore.commitFrames(app, request, decoded))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47PreparedFrameInstrumentationTest.kt:203:            val snapshot = checkNotNull(FluviActiveHeaderMaterialStore.applicable(app))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47PreparedFrameInstrumentationTest.kt:208:                main { presenter = KeyguardR446WindowPresenter(service)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47PreparedFrameInstrumentationTest.kt:213:                val target = KeyguardR446Target(hostId, 0,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47PreparedFrameInstrumentationTest.kt:214:                    KeyguardR446Bounds(hostBounds.left, hostBounds.top, hostBounds.right, hostBounds.bottom))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47PreparedFrameInstrumentationTest.kt:219:                val owner = KeyguardR448WidgetsAnywhereFrame.Owner(1, 1, 1); frameOwner = owner
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47PreparedFrameInstrumentationTest.kt:220:                main { frame = KeyguardR448WidgetsAnywhereFrame(service)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47PreparedFrameInstrumentationTest.kt:262:            FluviActiveHeaderMaterialStore.invalidate()
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47PreparedFrameInstrumentationTest.kt:266:            File(out, "r47-prepared-visual.txt").writeText(log.toString() + failures.joinToString("\n", prefix = "failures=\n", postfix = "\n"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47VisualInstrumentationTest.kt:20:import com.fluvi.app.lockscreen.material.FluviActiveHeaderMaterialStore
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47VisualInstrumentationTest.kt:40:class KeyguardR47VisualInstrumentationTest {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47VisualInstrumentationTest.kt:101:            val input = ins.context.assets.open("r47_reference/$name.png")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47VisualInstrumentationTest.kt:117:        var presenter: KeyguardR446WindowPresenter? = null
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47VisualInstrumentationTest.kt:118:        var frame: KeyguardR448WidgetsAnywhereFrame? = null
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47VisualInstrumentationTest.kt:119:        var frameOwner: KeyguardR448WidgetsAnywhereFrame.Owner? = null
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47VisualInstrumentationTest.kt:172:                val json = ins.context.assets.open("r47_reference/$name.json").bufferedReader().use { it.readText() }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47VisualInstrumentationTest.kt:174:                val snapshot = FluviActiveHeaderMaterialStore.Snapshot.create(profile, 1, "balance", 0, true)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47VisualInstrumentationTest.kt:195:                        presenter = KeyguardR446WindowPresenter(service, source)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47VisualInstrumentationTest.kt:199:                    val target = KeyguardR446Target(hostId, 0,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47VisualInstrumentationTest.kt:200:                        KeyguardR446Bounds(hostBounds.left, hostBounds.top, hostBounds.right, hostBounds.bottom))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47VisualInstrumentationTest.kt:207:                    val owner = KeyguardR448WidgetsAnywhereFrame.Owner(100L + index, 1, 200L + index)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47VisualInstrumentationTest.kt:210:                        frame = KeyguardR448WidgetsAnywhereFrame(service, source)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR47VisualInstrumentationTest.kt:289:            File(out, "r47-visual.txt").writeText(log.toString() + failures.joinToString("\n", prefix = "failures=\n", postfix = "\n"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardRecoveryAdmissionInstrumentationTest.kt:291:            captureId = KeyguardCardDiagnostics.startCapture(context, source, "debug", "FULL")["captureId"].toString()
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardRecoveryAdmissionInstrumentationTest.kt:684:                File(output, "capture.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"].toString())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:158:        val mainIds = @Suppress("UNCHECKED_CAST") (KeyguardSurfaceClassifier::class.java
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:180:                val unmasked = KeyguardSurfaceClassifier.classifyDetailed(actual)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:184:                val synthetic = KeyguardSurfaceClassifier.classifyDetailed(masked)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:221:                            .apply { isAccessible = true }.get(owner) as KeyguardInspectionFreshness
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:250:                        .apply { isAccessible = true }.get(owner) as KeyguardInspectionFreshness
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:299:            val capture = KeyguardCardDiagnostics.startCapture(context, appSha, "debug", "FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:397:            if (captureStarted) runCatching { File(output, "capture.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"].toString()) }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:592:            val startedCapture = KeyguardCardDiagnostics.startCapture(context,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:702:                File(output, "capture.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"].toString())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:814:            val started = KeyguardCardDiagnostics.startCapture(context,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:838:                File(output, "capture.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"].toString())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:920:            val started = KeyguardCardDiagnostics.startCapture(context,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:1141:                val report = KeyguardCardDiagnostics.freezeCapture(context)["report"].toString()
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:1232:            val capture = KeyguardCardDiagnostics.startCapture(context,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt:1298:                File(output, "capture.txt").writeText(KeyguardCardDiagnostics.freezeCapture(context)["report"].toString())
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:34:import com.fluvi.app.lockscreen.KeyguardInspectionFreshness
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:126:            KeyguardInspectionFreshness.Ticket(owner, 1, KeyguardWindowFreshness.LIFECYCLE_BOUNDARY)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:388:        KeyguardCardDiagnostics.startCapture(context, "r12-panel-control", "debug", "FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt:972:            KeyguardCardDiagnostics.startCapture(activity, "r10-panel", "debug", "FULL")
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:76:import com.fluvi.app.lockscreen.KeyguardR448DisplayRoute
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:77:import com.fluvi.app.lockscreen.KeyguardR448DisplayRouteStore
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:78:import com.fluvi.app.lockscreen.KeyguardR448ComparisonStore
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:79:import com.fluvi.app.lockscreen.KeyguardR448Safety
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:80:import com.fluvi.app.lockscreen.KeyguardR46RecordingStore
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:82:import com.fluvi.app.lockscreen.material.FluviActiveHeaderMaterialStore
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:385:                                    val saved = withContext(Dispatchers.IO) { KeyguardR46RecordingStore.status(applicationContext) }
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:394:                                    val before = withContext(Dispatchers.IO) { KeyguardR46RecordingStore.status(applicationContext) }
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:406:                                        val text = KeyguardR46RecordingStore.seal(applicationContext, id, summary,
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:414:                                        "report" to KeyguardR46RecordingStore.sealedReport(applicationContext, id)) }
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:418:                                    withContext(Dispatchers.IO) { KeyguardR46RecordingStore.copied(applicationContext, id) }
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:422:                        }.onSuccess(result::success).onFailure { result.error("R46_RECORDING", it.message, null) }
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:454:                if (call.method == "getR44SyntheticTrial" || call.method == "setR44SyntheticTrial") {
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:459:                        if (call.method == "setR44SyntheticTrial") {
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:461:                            if (!available || service == null || enabled == null || !service.setR44SyntheticTrial(enabled)) {
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:462:                                result.error("R44_TRIAL", "A próba csak feloldott telefonon, bekapcsolt ORB-szolgáltatással indítható.", null)
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:466:                        result.success(mapOf("available" to available, "enabled" to com.fluvi.app.lockscreen.KeyguardR44Trial.active))
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:502:                            val requested = KeyguardR448DisplayRoute.entries.firstOrNull { it.name == value }
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:503:                            val old = KeyguardR448DisplayRouteStore.read(applicationContext)
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:510:                            if (!KeyguardR448DisplayRouteStore.write(applicationContext, requested)) {
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:516:                        val configured = KeyguardR448DisplayRouteStore.read(applicationContext)
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:517:                        val native = service?.r448DisplayRouteStatus() ?: mapOf(
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:519:                            "sampleOnly" to KeyguardR448Safety.sampleOnly(applicationContext))
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:527:                            KeyguardR448ComparisonStore.export(applicationContext) else ""
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:545:                                    "startKeyguardDiagnosticCapture" -> KeyguardCardDiagnostics.startCapture(
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:551:                                    "freezeKeyguardDiagnosticCapture" -> KeyguardCardDiagnostics.freezeCapture(applicationContext)
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:1365:                        if (FluviActiveHeaderMaterialStore.applicable(applicationContext) == null)
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:1376:                            FluviActiveHeaderMaterialStore.bindPublisher(keyguardMaterialPublisherEpoch, instance, publisherSession)
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:1377:                        else FluviActiveHeaderMaterialStore.invalidatePublisher(keyguardMaterialPublisherEpoch, instance, publisherSession, revision)
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:1388:                            val receipt = FluviActiveHeaderMaterialStore.publish(applicationContext, values,
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:1400:                            FluviActiveHeaderMaterialStore.noteFrameStatus(applicationContext, token, status)
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:1416:                                    val admission = FluviActiveHeaderMaterialStore.admitFrames(
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:1419:                                    if (request != null) decoded = FluviActiveHeaderMaterialStore.decodeFrames(request)
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:1426:                                            FluviActiveHeaderMaterialStore.commitFrames(applicationContext, request, frames)
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:1530:        if (FluviActiveHeaderMaterialStore.applicable(applicationContext) == null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:28:import com.fluvi.app.lockscreen.material.FluviActiveHeaderMaterialStore
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:67:        KeyguardR444ProfileOwner(AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:86:    private val r445WakeBudget = KeyguardR445WakeBudget()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:152:    @Volatile private var r448DisplayRoute = KeyguardR448DisplayRoute.FLUVI_STREAM
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:153:    private var r448RouteGeneration = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:154:    private val r448SampleOnly by lazy { KeyguardR448Safety.sampleOnly(applicationContext) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:156:    private fun localPresentationAllowed(): Boolean = !r448SampleOnly && r444ConfigurationReady &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:157:        referenceOwnership?.appMayShow() != false && r448DisplayRoute == KeyguardR448DisplayRoute.FLUVI_STREAM &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:158:        r448Frame == null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:191:        if (r448SampleOnly) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:272:    internal fun r447ScheduleOutputReadyForTest() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:273:        check(KeyguardR447TestHooks.CONTROLLED_TOPOLOGY)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:276:    internal fun r447SampleOrderForTest(request: Long): KeyguardFirstAuthorizedOrb.SampleOrder = synchronized(queueLock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:279:    internal fun r447SamplerIdleForTest(): Boolean = !systemSampler.hasOutstandingWork()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:288:    internal fun r448SafetyForInstrumentation(): Triple<Boolean, Boolean, Boolean> =
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:289:        Triple(r448SampleOnly, localPresentationAllowed(), lastMaterialProfile != null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:292:    internal fun setR448DisplayRoute(route: KeyguardR448DisplayRoute): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:296:        if (r448DisplayRoute == route) return true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:297:        if ((KeyguardR44Trial.active || r446CaptureId != null) && !stopR444Trial("ROUTE_CHANGED")) return false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:298:        if (r448Frame != null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:300:            if (r448Frame != null) return false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:302:        hideImmediately("r448RouteChanged")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:304:        r448RouteGeneration++
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:305:        r448DisplayRoute = route
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:308:        if (route == KeyguardR448DisplayRoute.FLUVI_STREAM)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:309:            requestSystemCheck("r448RouteChanged", evaluate = true)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:313:    internal fun r448DisplayRouteStatus(): Map<String, Any> {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:316:            r448DisplayRoute == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE && r448Frame?.isAttached() == true -> "WIDGETS_ANYWHERE"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:317:            r448DisplayRoute == KeyguardR448DisplayRoute.FLUVI_STREAM &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:319:                    (r446Owner.state == KeyguardR446PrintOwner.State.ISSUED && r446Observation?.submittedAt != null)) -> "FLUVI_STREAM"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:322:        return mapOf("configured" to r448DisplayRoute.name, "active" to active,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:323:            "generation" to r448RouteGeneration,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:324:            "sampleOnly" to r448SampleOnly,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:325:            "reason" to if (r448SampleOnly && !KeyguardR44Trial.active) "SAMPLE_ONLY_NORMAL_DISABLED"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:326:                else if (r448DisplayRoute == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE) "PUBLIC_SAMPLE_ONLY" else "NONE")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:353:    internal fun setR44SyntheticTrial(enabled: Boolean, expanded: Boolean = false): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:362:        if (enabled && KeyguardR44Trial.active &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:363:            ((expanded && current.kind == KeyguardR444ProfileOwner.Kind.EXPANDED) ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:364:                (!expanded && current.kind in setOf(KeyguardR444ProfileOwner.Kind.STANDARD,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:365:                    KeyguardR444ProfileOwner.Kind.STANDARD_ALREADY_INCLUDED)))) return true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:377:        KeyguardR44Trial.set(false, false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:381:        KeyguardR44Trial.set(true, r442Lookup.verified)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:386:            KeyguardR44Trial.set(false, false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:397:        r449Session = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:399:        r47RecordingHeader = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:400:        r47Header = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:402:        val active = KeyguardR44Trial.active || r444ProfileOwner.snapshot.kind != KeyguardR444ProfileOwner.Kind.INACTIVE
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:416:            KeyguardR44Trial.set(false, false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:449:        r46Request: String? = null, r46Route: String? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:456:        if (previousReceipt != null && KeyguardR44Trial.active && !stopR444Trial("captureReplaced"))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:475:            if (!setR44SyntheticTrial(true, expanded) || !KeyguardR44Trial.active ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:476:                KeyguardR44Trial.profile(null) == null || KeyguardR44Trial.settings(settings).showFinancialDetails ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:484:                KeyguardCardDiagnostics.startCapture(applicationContext, build, buildMode, captureMode, r46Request != null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:486:                    r46Request = r46Request, r46Route = r46Route)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:493:                KeyguardCardDiagnostics.currentProcessInstanceId() != expectedProcess || !KeyguardR44Trial.active ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:510:            if (!accepted && KeyguardR44Trial.active &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:527:            KeyguardR444ProfileOwner.Kind.EXPANDED, KeyguardR444ProfileOwner.Kind.STANDARD_ALREADY_INCLUDED -> included
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:528:            KeyguardR444ProfileOwner.Kind.STANDARD -> !included
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:534:                KeyguardCardDiagnostics.activeCaptureId() != receipt.capture || !KeyguardR44Trial.active ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:536:            if (KeyguardR44Trial.active) stopR444Trial("serviceOrCaptureChanged")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:541:        val printState = if (r448DisplayRoute == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE) when (r45Wa.phase) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:542:            KeyguardR45Phase.PREPARED -> "WAIT_OFF"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:543:            KeyguardR45Phase.WAIT_WAKE -> "WAIT_WAKE"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:544:            KeyguardR45Phase.OPENING -> "WAIT_READ"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:545:            KeyguardR45Phase.ATTACHED_HIDDEN, KeyguardR45Phase.VISIBLE, KeyguardR45Phase.SUSPENDED -> "ISSUED"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:546:            KeyguardR45Phase.RETIRED -> "CONSUMED"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:554:            "routeConfirmed" to r448DisplayRoute.name, "actionKind" to r449Action,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:555:            "sampleShape" to if (r45Circle) "CIRCLE" else "ORB",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:556:            "printState" to printState, "printReason" to r449LastTerminal,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:557:            "sessionExpiresAt" to r449Session?.expiresAt,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:564:    private val r446Owner = KeyguardR446PrintOwner()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:565:    @Volatile private var r446ReadArm: KeyguardR446PrintOwner.Arm? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:573:    private var r447SystemBarrier = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:574:    private var r447SystemSatisfied = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:575:    private var r447DecisionOrdinal = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:576:    private var r446Presenter: KeyguardR446WindowPresenter? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:577:    @Volatile private var r47RecordingHeader = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:578:    @Volatile private var r47Header: FluviActiveHeaderMaterialStore.Snapshot? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:580:    private fun r47HeaderCurrent(): Boolean = !r47RecordingHeader || r47Header?.let {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:581:        FluviActiveHeaderMaterialStore.isCurrentReference(it)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:584:    private fun r47PrivateAllowed(surface: KeyguardSurface, state: KeyguardSystemState?, complete: Boolean): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:585:        if (!r47RecordingHeader) return true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:586:        val material = r47Header ?: return false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:590:            !FluviActiveHeaderMaterialStore.isCurrentReference(material)) return false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:595:        return KeyguardR47PrivateAdmission.allows(signals, complete, materialCurrent = true)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:597:    @Volatile private var r448Frame: KeyguardR448WidgetsAnywhereFrame? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:598:    private var r448FrameOwner: KeyguardR448WidgetsAnywhereFrame.Owner? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:599:    private var r448FrameGeneration = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:600:    private var r448HideAt: Long? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:601:    private var r448RemoveAt: Long? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:602:    private var r448RetireError: String? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:603:    private fun r446HasBackend() = r446Presenter != null || r448Frame != null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:608:    private val r45Wa = KeyguardR45WaLifetime()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:609:    private val r45Direct = KeyguardR45DirectLifetime()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:610:    private val r45IngressSequence = AtomicLong(0)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:611:    private val r45DirectRevision = AtomicLong(0)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:612:    @Volatile private var r45WaOwnIdentity: KeyguardOwnOverlayIdentity? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:613:    private var r45DirectReadActive = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:614:    private var r45DirectReadPending = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:615:    private var r45DirectLower: List<KeyguardR45LowerWindow> = emptyList()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:616:    private var r45Circle = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:619:        val arm: KeyguardR45SampleIntent, val context: KeyguardDiagnosticContext,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:620:        val owner: KeyguardR448WidgetsAnywhereFrame.Owner, val screenAt: Long, var expiresAt: Long = Long.MAX_VALUE,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:622:        var lower: List<KeyguardR45LowerWindow> = emptyList(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:627:    @Volatile private var r449Wake: R449Wake? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:628:    private val r449RestrictionRevision = AtomicLong(0)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:629:    private var r449ReadActive = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:630:    private var r449ReadPending = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:631:    private var r449FirstRead = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:632:    private var r449Action = "ONE_WAKE"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:633:    private var r449LastTerminal = "UNOBSERVED"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:634:    private data class R449FluviRecovery(val observation: KeyguardR449RecoveryObservation,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:635:                                          val arm: KeyguardR446PrintOwner.Arm, var consumed: Boolean = false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:636:    private var r449FluviRecovery: R449FluviRecovery? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:637:    private data class R449Session(val capture: String, val serviceSession: Long, val route: KeyguardR448DisplayRoute,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:639:    private var r449Session: R449Session? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:640:    private var r449SessionPreparing = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:642:    private fun r449Current(wake: R449Wake, revision: Long): Boolean =
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:643:        r449Wake === wake && r449RestrictionRevision.get() == revision &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:644:            r448DisplayRoute == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:645:            r448RouteGeneration == wake.owner.route && FluviKeyguardCardServiceRegistry.connected &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:646:            r448FrameOwner == wake.owner && r45Wa.current(wake.arm, wake.owner.wake, wake.owner.material) &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:649:            KeyguardR44Trial.active && r47HeaderCurrent() && SystemClock.uptimeMillis() < wake.expiresAt
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:651:    private fun r449BeginWake(arm: KeyguardR45SampleIntent, screenAt: Long) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:653:        if (r448DisplayRoute != KeyguardR448DisplayRoute.WIDGETS_ANYWHERE) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:654:        val frame = r448Frame ?: return r446Cancel("wa:missingFrame")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:655:        val prepared = r448FrameOwner ?: return r446Cancel("wa:missingOwner")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:661:        if (!r45Wa.bind(arm, bound.wake, bound.material)) return r446Cancel("wa:lifetimeBindFailed")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:662:        r448FrameOwner = bound
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:664:        r449Wake = wake
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:665:        r449RestrictionRevision.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:666:        r449ReadPending = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:667:        r449FirstRead = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:668:        runCatching { KeyguardCardDiagnostics.recordR446(KeyguardR446Observation(context, r446ArmAt,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:671:        r45RecordStage(context, "WIDGETS_ANYWHERE", "INTENT", SystemClock.uptimeMillis(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:673:        r449ScheduleRead()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:676:    private fun r45TryBeginWaWake() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:677:        val arm = r45Wa.intent ?: return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:679:        if (r448DisplayRoute != KeyguardR448DisplayRoute.WIDGETS_ANYWHERE || r449Wake != null ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:680:            r45Wa.phase != KeyguardR45Phase.OPENING || screen.session != arm.session ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:682:        r449BeginWake(arm, screen.uptime)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:685:    private fun r45RecordStage(context: KeyguardDiagnosticContext?, route: String, stage: String, at: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:689:        runCatching { KeyguardCardDiagnostics.recordR45(KeyguardR45Observation(context, route, stage, at,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:693:    private fun r45RecordIngress(context: KeyguardDiagnosticContext?, route: String, sequence: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:695:                                 decision: KeyguardR45IngressAction, phase: String, revision: Long) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:699:            decision == KeyguardR45IngressAction.IGNORE && meta.displayId > 0 -> "OTHER_DISPLAY"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:700:            decision == KeyguardR45IngressAction.IGNORE -> "VERIFIED_LOWER"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:706:        runCatching { KeyguardCardDiagnostics.recordR45(KeyguardR45Observation(context, route, "INGRESS", receivedAt,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:711:    private fun r45DirectCurrent(lease: KeyguardR45DirectLifetime.Lease): Boolean =
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:712:        r45Direct.current(lease, SystemClock.uptimeMillis()) &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:714:            r448DisplayRoute == KeyguardR448DisplayRoute.FLUVI_STREAM && r448RouteGeneration == lease.route &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:716:            KeyguardCardDiagnostics.activeCaptureId() == lease.capture && KeyguardR44Trial.active &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:717:            r47HeaderCurrent() && r446Presenter != null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:721:    private fun r45ScheduleDirectRead(lease: KeyguardR45DirectLifetime.Lease) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:723:        if (!r45DirectCurrent(lease)) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:724:        if (r45DirectReadActive) { r45DirectReadPending = true; return }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:725:        val revision = r45DirectRevision.get()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:726:        r45DirectReadActive = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:727:        r449Scope.launch {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:731:                KeyguardWindowSnapshotReader(this@FluviKeyguardCardService, packageName).read(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:732:                    KeyguardWindowSnapshotReader.Request(knownOwn = null, attachGeneration = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:734:                        strictOwnAttribution = true, r44Enabled = true, r443Sample = true,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:736:                    authorityIsCurrent = { r45Direct.lease === lease && r45DirectRevision.get() == revision &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:737:                        session.get() == lease.session && KeyguardR44Trial.active },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:743:            val classification = read?.let { KeyguardR44SurfaceClassifier.classify(it.snapshots,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:746:                KeyguardR446PrintPolicy.evaluate(read.snapshots, classification, read.rootUnavailable, read.walkTruncated)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:748:            val restrictions = KeyguardR449RestrictionEvidence.fromInventory(read?.snapshots.orEmpty(), ended,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:752:                values.any { it == KeyguardR448Admission.Presence.PRESENT }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:753:            val normal = read?.let { KeyguardR44SurfaceClassifier.classify(it.snapshots, it.rootUnavailable,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:757:                values.all { it == KeyguardR448Admission.Presence.CLEAR } &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:758:                r47PrivateAllowed(normal, state, read != null && !read.rootUnavailable && !read.walkTruncated && !read.abortedStale)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:760:                r45DirectReadActive = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:761:                if (r45DirectCurrent(lease) && r45DirectRevision.get() == revision) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:763:                    r45RecordStage(r446Observation?.context, "FLUVI_STREAM", "RECOVERY", SystemClock.uptimeMillis(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:766:                    else if (allowed && r45Direct.phase == KeyguardR45Phase.SUSPENDED) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:767:                        r45DirectLower = restrictions.lower
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:768:                        r45Direct.visible(lease)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:769:                        val valid = { r45DirectCurrent(lease) && r45DirectRevision.get() == revision }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:771:                            if (r45Direct.lease === lease && r45Direct.phase != KeyguardR45Phase.SUSPENDED)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:774:                        if (resumed) r45RecordStage(r446Observation?.context, "FLUVI_STREAM", "REVEAL",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:776:                        else r45Direct.suspend(lease)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:779:                if (r45DirectReadPending && r45Direct.lease != null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:780:                    r45DirectReadPending = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:781:                    r45Direct.lease?.let(::r45ScheduleDirectRead)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:789:    private fun r449ScheduleRead() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:791:        val wake = r449Wake ?: return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:792:        if (r449ReadActive) { r449ReadPending = true; return }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:793:        val revision = r449RestrictionRevision.get()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:794:        if (!r449Current(wake, revision)) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:795:        val own = r448Frame?.ownIdentity(wake.owner)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:796:        r45WaOwnIdentity = own
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:797:        val freshness = if (r449FirstRead) KeyguardWindowFreshness.LIFECYCLE_BOUNDARY
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:799:        r449FirstRead = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:800:        r449ReadActive = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:801:        r449Scope.launch {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:807:                KeyguardWindowSnapshotReader(this@FluviKeyguardCardService, packageName).read(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:808:                    KeyguardWindowSnapshotReader.Request(knownOwn = own, attachGeneration = wake.owner.material,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:809:                        knownOwnAtInventory = { r45WaOwnIdentity },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:810:                        freshness = freshness, strictOwnAttribution = true, r44Enabled = true,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:812:                    authorityIsCurrent = { r449Wake === wake && r449RestrictionRevision.get() == revision &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:813:                        session.get() == wake.arm.session && wakeEpoch == wake.owner.wake && KeyguardR44Trial.active },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:818:                KeyguardR449RestrictionEvidence.fromInventory(inventory?.snapshots.orEmpty(), ended,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:822:                KeyguardR449RestrictionEvidence.fromInventory(emptyList(), ended, unavailable = true, truncated = true)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:825:                r449ReadActive = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:826:                if (r449Current(wake, revision)) r449Apply(wake, revision, started, ended, system, evidence)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:827:                if (r449ReadPending && r449Wake != null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:828:                    r449ReadPending = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:829:                    r449ScheduleRead()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:835:    private fun r449Apply(wake: R449Wake, revision: Long, started: Long, ended: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:836:                          system: KeyguardSystemState, evidence: KeyguardR449RestrictionEvidence.Result) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:837:        val stamp = KeyguardR448Admission.Stamp(wake.owner.route, wake.owner.wake, wake.owner.material)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:838:        val privateAllowed = r47PrivateAllowed(evidence.privateSurface, system, evidence.reason == "CLEAR")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:839:        val decision = KeyguardR448Admission.evaluate(KeyguardR448Admission.Inputs(stamp, wake.screenAt,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:841:            if (r47RecordingHeader) KeyguardR448Admission.Domain.PRIVATE else KeyguardR448Admission.Domain.PUBLIC_SAMPLE,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:844:        if (r45Wa.phase == KeyguardR45Phase.SUSPENDED)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:845:            r45RecordStage(wake.context, "WIDGETS_ANYWHERE", "RECOVERY", SystemClock.uptimeMillis(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:847:        runCatching { KeyguardCardDiagnostics.recordR449Admission(KeyguardR449AdmissionObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:848:            wake.context, wake.arm.generation, wake.owner.route, wake.owner.material, revision, r449Action,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:850:            if (r47RecordingHeader) KeyguardR448Admission.Domain.PRIVATE else KeyguardR448Admission.Domain.PUBLIC_SAMPLE)) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:851:        if (decision != KeyguardR448Admission.Decision.ALLOW) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:852:            if (r47RecordingHeader) r45RecordStage(wake.context, "WIDGETS_ANYWHERE", "MATERIAL_DENIED",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:855:            if (decision == KeyguardR448Admission.Decision.RESTRICTED ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:856:                decision == KeyguardR448Admission.Decision.SYSTEM_EXCLUDED) r446Cancel("wa:${evidence.reason}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:864:        if (pendingValidation != null) r449ValidateSystem(wake, pendingValidation)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:869:            if (r45Wa.phase == KeyguardR45Phase.SUSPENDED) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:870:                val frame = r448Frame ?: return r446Cancel("wa:missingFrame")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:871:                val valid = { val current = r449RestrictionRevision.get()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:872:                    r449Current(wake, current) && wake.allowedRevision == current }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:873:                val checkSystem: ((Boolean) -> Unit) -> Unit = { done -> r449ValidateSystem(wake, done) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:875:                else if (!frame.hasOwnedWindow()) r449RequestFrame(wake, frame, valid, checkSystem)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:879:        val frame = r448Frame ?: return r446Cancel("wa:missingFrame")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:883:        wake.expiresAt = if (r47RecordingHeader) Long.MAX_VALUE else issueAt + 2_000L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:884:        runCatching { KeyguardCardDiagnostics.recordR449Admission(KeyguardR449AdmissionObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:885:            wake.context, wake.arm.generation, wake.owner.route, wake.owner.material, revision, r449Action,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:887:            if (r47RecordingHeader) KeyguardR448Admission.Domain.PRIVATE else KeyguardR448Admission.Domain.PUBLIC_SAMPLE)) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:888:        r446Observation = KeyguardR446Observation(wake.context, r446ArmAt, wake.owner.wake, 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:892:        runCatching { KeyguardCardDiagnostics.recordR446(requireNotNull(r446Observation)) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:893:        val valid = { val current = r449RestrictionRevision.get()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:894:            r449Current(wake, current) && wake.allowedRevision == current }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:895:        val checkSystem: ((Boolean) -> Unit) -> Unit = { done -> r449ValidateSystem(wake, done) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:896:        r449RequestFrame(wake, frame, valid, checkSystem)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:897:        if (!r47RecordingHeader) mainHandler.postDelayed({ if (r449Wake === wake) r446Cancel("deadline") },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:901:    private fun r449RequestFrame(wake: R449Wake, frame: KeyguardR448WidgetsAnywhereFrame,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:916:    private fun r449ValidateSystem(wake: R449Wake, done: (Boolean) -> Unit) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:918:        val revision = r449RestrictionRevision.get()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:919:        if (!r449Current(wake, revision)) { done(false); return }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:921:        r449Scope.launch {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:925:                val current = r449RestrictionRevision.get()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:926:                if (!r449Current(wake, current)) done(false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:932:                    r47PrivateAllowed(wake.privateSurface, state, complete = true))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:937:    private fun r448RecordFrameEvent(event: KeyguardR448WidgetsAnywhereFrame.Event) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:938:        if (event.owner != r448FrameOwner) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:940:            "ATTACHED" -> r449Wake?.let {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:941:                r45Wa.attached(it.arm)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:942:                if (r45Wa.phase == KeyguardR45Phase.SUSPENDED) mainHandler.post { r449ScheduleRead() }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:944:            "REVEAL" -> r449Wake?.let { r45Wa.visible(it.arm) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:945:            "CONCEAL" -> r449Wake?.let { r45Wa.suspend(it.arm) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:946:            "PRE_ADD_UNVERIFIED", "POST_ADD_UNVERIFIED", "RESUME_UNVERIFIED" -> r449Wake?.let { wake ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:947:                val revision = r449RestrictionRevision.get()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:950:                    mainHandler.post { if (r449Wake === wake) r449ScheduleRead() }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:953:            "HIDE" -> if (r448HideAt == null) r448HideAt = event.at
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:954:            "REMOVE_RETURN" -> if (r448RemoveAt == null) r448RemoveAt = event.at
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:955:            "REMOVE_FAILED" -> r448RetireError = event.detail ?: "UNKNOWN"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:959:            KeyguardCardDiagnostics.recordR448Frame(KeyguardR448FrameObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:962:        if (previous != null) r45RecordStage(previous.context, "WIDGETS_ANYWHERE", event.stage, event.at,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:964:        if (previous != null && r449Wake?.issued == true) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:975:                runCatching { KeyguardCardDiagnostics.recordR446(next) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:980:                if (event.owner == r448FrameOwner &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:981:                    r449Wake?.issued == true)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:987:    private var r446Observation: KeyguardR446Observation? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:990:    private var r448StartedRequest: Long? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:991:    private var r448StartedArm: Long? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:994:    internal fun r446PreparePresenterForInstrumentation(timeSource: KeyguardMaterialTimeSource): KeyguardR446WindowPresenter {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:996:        return KeyguardR446WindowPresenter(this, timeSource).also { r446Presenter = it }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1001:                                              r46Request: String? = null): Map<String, Any?> {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1004:        if (r448Frame != null || r446Presenter != null) return mapOf("active" to false, "reason" to "retirementPending")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1005:        r449Action = sampleAction
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1006:        r45Circle = diagnosticCircle
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1007:        val route = r448DisplayRoute
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1008:        val routeGeneration = r448RouteGeneration
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1012:                r46Request = r46Request, r46Route = route.name)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1015:            val useHeader = r46Request != null && !r448SampleOnly
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1016:            val header = if (useHeader) FluviActiveHeaderMaterialStore.applicable(applicationContext) else null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1020:                r47RecordingHeader = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1021:                r47Header = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1024:                r442Reason = FluviActiveHeaderMaterialStore.unavailableReason(applicationContext)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1025:                KeyguardR46RecordingStore.offer(capture,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1026:                    "R47_MATERIAL origin=missing reason=$r442Reason")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1030:            r47RecordingHeader = useHeader
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1031:            r47Header = header
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1032:            val sample = header?.profile ?: KeyguardR44Trial.profile(null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1039:                KeyguardCardDiagnostics.activeCaptureId() != capture || !KeyguardR44Trial.active ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1040:                !r47HeaderCurrent() ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1041:                r448DisplayRoute != route || r448RouteGeneration != routeGeneration ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1046:            r46DisplayFacts = currentR46DisplayFacts()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1047:            if (route == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1048:                val frame = KeyguardR448WidgetsAnywhereFrame(this)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1049:                val prepared = KeyguardR448WidgetsAnywhereFrame.Owner(routeGeneration, 0, ++r448FrameGeneration)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1050:                r448HideAt = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1051:                r448RemoveAt = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1052:                r448RetireError = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1053:                val preparedOk = if (header != null) frame.prepareActiveHeader(prepared, header, artifact, ::r448RecordFrameEvent)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1054:                    else frame.preparePublic(prepared, KeyguardR46PublicMaterial.demo(), artifact, diagnosticCircle, ::r448RecordFrameEvent)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1059:                r448Frame = frame
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1060:                r448FrameOwner = prepared
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1062:                val presenter = KeyguardR446WindowPresenter(this)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1063:                presenter.onR46Interval = { detail -> r45RecordStage(r446Observation?.context, "FLUVI_STREAM",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1068:                    else presenter.preparePublic(display, KeyguardR46PublicMaterial.demo(), artifact, diagnosticCircle)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1083:                !KeyguardR44Trial.active || !r47HeaderCurrent() || r448DisplayRoute != route || r448RouteGeneration != routeGeneration ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1089:                val telemetry = if (route == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1090:                    r448Frame?.activeHeaderTelemetry() else r446Presenter?.activeHeaderTelemetry()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1091:                if (telemetry != null) KeyguardR46RecordingStore.offer(capture, "R47_MATERIAL $telemetry")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1094:            r447DecisionOrdinal = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1099:            if (route == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1100:                r45Wa.prepare(capture, session.get(), routeGeneration, sampleAction, diagnosticCircle)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1102:            r449LastTerminal = "UNOBSERVED"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1116:                                               r46Request: String? = null): Map<String, Any?> {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1119:        val route = r448DisplayRoute.name
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1122:        val result = startR446PrintCapture(build, buildMode, mode, action, diagnosticCircle, r46Request)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1123:        if (result["active"] == true && result["printArmed"] == true && r448DisplayRoute.name == route) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1124:            r449Action = action
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1126:            KeyguardCardDiagnostics.recordR449Intent(capture, action, route, SystemClock.uptimeMillis())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1127:            val newSession = if (action == "SESSION") R449Session(capture, session.get(), r448DisplayRoute,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1128:                r448RouteGeneration, if (r46Request == null) SystemClock.uptimeMillis() + 120_000L else Long.MAX_VALUE,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1130:            r449Session = newSession
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1131:            if (newSession != null && r46Request == null) mainHandler.postDelayed({
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1132:                if (r449Session === newSession) stopR444Trial("sampleSessionExpired")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1137:        return result + mapOf("routeRequested" to requestedRoute, "routeConfirmed" to r448DisplayRoute.name,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1141:    private var r46StartingRequest: String? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1142:    private var r46StartedRequest: String? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1143:    private var r46StartedReceipt: Map<String, Any?>? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1146:        val partial = withContext(Dispatchers.IO) { KeyguardR46RecordingStore.status(applicationContext) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1149:            stopR444Trial("r46StartFailed")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1153:                KeyguardR46RecordingStore.abort(applicationContext, partialId)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1165:        if (r46StartedRequest == request && r46StartedReceipt != null &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1166:            r442SampleStatus()["active"] == true) return requireNotNull(r46StartedReceipt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1167:        if (r46StartingRequest != null || r442Receipt != null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1169:        if (route != r448DisplayRoute.name) return mapOf("active" to false, "reason" to "routeChanged")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1170:        r46StartingRequest = request
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1173:                diagnosticCircle = false, r46Request = request)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1176:                val receipt = result + mapOf("state" to "RECORDING", "policy" to "R46_ALL", "requestId" to request)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1177:                r46StartedRequest = request
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1178:                r46StartedReceipt = receipt
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1187:            r46StartingRequest = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1193:        if (r46StartingRequest != null) return false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1194:        if (r442Receipt?.capture == capture && !stopR444Trial("r46UserStop")) return false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1195:        r46StartedRequest = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1196:        r46StartedReceipt = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1203:    private fun r449PrepareSessionWake() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1205:        val active = r449Session ?: return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1206:        if (r449SessionPreparing || r446HasBackend() || r448Frame != null ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1207:            (active.route == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE && r45Wa.phase != KeyguardR45Phase.RETIRED) ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1208:            (active.route == KeyguardR448DisplayRoute.FLUVI_STREAM && r446Owner.state in setOf(KeyguardR446PrintOwner.State.WAIT_OFF,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1209:                KeyguardR446PrintOwner.State.WAIT_WAKE, KeyguardR446PrintOwner.State.WAIT_READ,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1210:                KeyguardR446PrintOwner.State.ISSUED))) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1211:        fun current() = r449Session === active && SystemClock.uptimeMillis() < active.expiresAt &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1213:            active.serviceSession == session.get() && KeyguardR44Trial.active &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1214:            r448DisplayRoute == active.route && r448RouteGeneration == active.routeGeneration
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1216:        r449SessionPreparing = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1219:                val header = if (r47RecordingHeader) FluviActiveHeaderMaterialStore.applicable(applicationContext) else null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1220:                if (r47RecordingHeader && header == null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1221:                    r442Reason = FluviActiveHeaderMaterialStore.unavailableReason(applicationContext)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1222:                    KeyguardR46RecordingStore.offer(active.capture, "R47_MATERIAL origin=missing reason=$r442Reason")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1225:                r47Header = header
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1226:                val sample = header?.profile ?: KeyguardR44Trial.profile(null) ?: return@launch
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1230:                if (!current() || !r47HeaderCurrent() || r446HasBackend()) return@launch
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1233:                if (active.route == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1234:                    val frame = KeyguardR448WidgetsAnywhereFrame(this@FluviKeyguardCardService)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1235:                    val owner = KeyguardR448WidgetsAnywhereFrame.Owner(active.routeGeneration, 0, ++r448FrameGeneration)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1236:                    val preparedOk = if (header != null) frame.prepareActiveHeader(owner, header, artifact, ::r448RecordFrameEvent)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1237:                        else frame.preparePublic(owner, KeyguardR46PublicMaterial.demo(), artifact, active.circle, ::r448RecordFrameEvent)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1241:                    if (!current() || !r47HeaderCurrent() || r446HasBackend()) { frame.retire(owner, "SESSION_REPLACED"); return@launch }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1242:                    r448Frame = frame
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1243:                    r448FrameOwner = owner
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1245:                    val presenter = KeyguardR446WindowPresenter(this@FluviKeyguardCardService)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1246:                    presenter.onR46Interval = { detail -> r45RecordStage(r446Observation?.context, "FLUVI_STREAM",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1250:                        else presenter.preparePublic(display, KeyguardR46PublicMaterial.demo(), artifact, active.circle)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1254:                    if (!current() || !r47HeaderCurrent() || r446Presenter !== presenter || r448Frame != null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1260:                    val telemetry = if (active.route == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1261:                        r448Frame?.activeHeaderTelemetry() else r446Presenter?.activeHeaderTelemetry()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1262:                    if (telemetry != null) KeyguardR46RecordingStore.offer(active.capture, "R47_MATERIAL $telemetry")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1264:                r448HideAt = null; r448RemoveAt = null; r448RetireError = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1265:                r446Observation = null; r447DecisionOrdinal = 0L; r446RestrictionSeen = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1267:                if (active.route == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1268:                    r45Wa.prepare(active.capture, active.serviceSession, active.routeGeneration, "SESSION", active.circle)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1270:                r449LastTerminal = "UNOBSERVED"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1272:                    if (active.route == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE) r45Wa.screenOff()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1277:                r449SessionPreparing = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1285:        val r45Context = r449Wake?.context ?: r446Observation?.context
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1286:        val r45Route = if (r449Wake != null) "WIDGETS_ANYWHERE" else "FLUVI_STREAM"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1287:        r45RecordStage(r45Context, r45Route, "TERMINAL", at, detail = reason.take(80))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1289:        if (cancelledArm != null) r449LastTerminal = reason
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1290:        r449FluviRecovery?.let { recovery ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1291:            runCatching { KeyguardCardDiagnostics.recordR449Recovery(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1294:        r449FluviRecovery = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1295:        val pendingValidation = r449Wake?.pendingValidation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1296:        r449Wake?.pendingValidation = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1297:        r45Wa.retire()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1298:        r45Direct.retire()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1299:        r45WaOwnIdentity = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1300:        r45DirectRevision.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1301:        r45DirectReadPending = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1302:        r45DirectLower = emptyList()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1303:        r449RestrictionRevision.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1304:        r449Wake = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1306:        r449ReadPending = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1314:        if (retired?.hideReturn != null) r45RecordStage(r45Context, r45Route, "CONCEAL", retired.hideReturn, detail = reason.take(80))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1315:        if (retired?.releaseReturn != null) r45RecordStage(r45Context, r45Route, "REMOVE_RETURN", retired.releaseReturn, detail = reason.take(80))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1316:        val frame = r448Frame
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1317:        val frameOwner = r448FrameOwner
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1320:            if (removed) { r448Frame = null; r448FrameOwner = null }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1321:            else if (r448RetireError == null) r448RetireError = "REMOVAL_UNCONFIRMED"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1326:            KeyguardCardDiagnostics.recordR447ArmTerminal(cancelledArm.capture, cancelledArm.generation, at, reason)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1331:            val next = previous.retireOnce(at, reason, retired?.hideReturn ?: r448HideAt,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1332:                retired?.releaseReturn ?: r448RemoveAt, retired?.errorClass ?: r448RetireError)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1334:            KeyguardCardDiagnostics.recordR446(next)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1340:                val terminal = KeyguardR446Observation(context, r446ArmAt, context.originWakeEpoch, 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1342:                    null, null, at, reason, retired?.hideReturn ?: r448HideAt,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1343:                    retired?.releaseReturn ?: r448RemoveAt, retired?.errorClass ?: r448RetireError,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1345:                KeyguardCardDiagnostics.recordR446(terminal)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1350:    private fun r447RecordWakeArm() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1356:        val waArm = if (r448DisplayRoute == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE) r45Wa.intent else null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1357:        val armed = if (waArm != null) r45Wa.phase in setOf(KeyguardR45Phase.OPENING,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1358:            KeyguardR45Phase.ATTACHED_HIDDEN, KeyguardR45Phase.VISIBLE, KeyguardR45Phase.SUSPENDED) &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1360:        else r446Owner.state == KeyguardR446PrintOwner.State.WAIT_READ && arm != null &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1363:        KeyguardCardDiagnostics.recordR446(KeyguardR446Observation(context, if (armed) r446ArmAt else 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1370:        val disposition: KeyguardR447Disposition, val order: KeyguardFirstAuthorizedOrb.SampleOrder,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1371:        val systemBarrier: Long, val ownerState: String, val ticket: KeyguardR446PrintOwner.Ticket?, val at: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1377:        if (r448DisplayRoute != KeyguardR448DisplayRoute.FLUVI_STREAM) return false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1383:        val stamp = inspection.r447Stamp
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1384:        val ordinal = ++r447DecisionOrdinal
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1391:        val route = r448DisplayRoute
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1392:        val routeGeneration = r448RouteGeneration
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1399:                    r446Owner.state != KeyguardR446PrintOwner.State.WAIT_READ -> KeyguardR447Disposition.ARM_MISMATCH
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1400:                !authorityIsCurrent(request) || inspection.abortedStale -> KeyguardR447Disposition.STALE_AUTHORITY
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1401:                disposition == CompletedDisposition.R32_RESTRICTION_ONLY -> KeyguardR447Disposition.RESTRICTION_ONLY
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1403:                    KeyguardR447Disposition.RESTRICTION_OBSERVED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1404:                target == null -> KeyguardR447Disposition.TARGET_MISSING
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1406:                    stamp.target != target || stamp.scene != scene -> KeyguardR447Disposition.FRESHNESS_UNESTABLISHED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1407:                order.result == KeyguardFirstAuthorizedOrb.SampleResult.SCENE_CHANGED -> KeyguardR447Disposition.SCENE_CHANGED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1408:                order.result == KeyguardFirstAuthorizedOrb.SampleResult.NEWER_COMPLETED -> KeyguardR447Disposition.NEWER_COMPLETED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1409:                order.result == KeyguardFirstAuthorizedOrb.SampleResult.NEWER_BARRIER_REQUIRED || stamp.barrier > request.id ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1410:                    KeyguardR447Disposition.NEWER_BARRIER_REQUIRED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1412:                    stamp.systemBarrier != stamp.systemSatisfied || stamp.systemBarrier != r447SystemBarrier ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1413:                    r447SystemBarrier != r447SystemSatisfied || currentSystem?.eligible != true ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1414:                    KeyguardR447Disposition.FRESHNESS_UNESTABLISHED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1415:                !r47PrivateAllowed(inspection.r446Normal?.surface ?: KeyguardSurface.UNKNOWN, currentSystem,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1417:                    KeyguardR447Disposition.PRIVATE_NOT_AUTHORIZED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1418:                presenter == null -> KeyguardR447Disposition.PRESENTER_UNAVAILABLE
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1422:                request.id, requireNotNull(scene), requireNotNull(target), decidedAt, publicFixture = !r47RecordingHeader) else null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1427:            R447Decision(reject ?: if (ticket == null) KeyguardR447Disposition.ISSUE_REJECTED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1428:                else KeyguardR447Disposition.ISSUED, order, r447SystemBarrier, state, ticket, decidedAt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1430:        var observation = KeyguardR446Observation(context, r446ArmAt, request.wakeGeneration, request.id,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1440:        KeyguardCardDiagnostics.recordR446(observation)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1441:        if (route == KeyguardR448DisplayRoute.FLUVI_STREAM && decision.disposition == KeyguardR447Disposition.TARGET_MISSING &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1442:            r449FluviRecovery == null && !r446RestrictionSeen && r446Owner.arm == arm &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1443:            r446Owner.state == KeyguardR446PrintOwner.State.WAIT_READ && authorityIsCurrent(request)) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1444:            val unresolved = inspection.r449UnresolvedUpper
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1447:                val initial = KeyguardR449RecoveryObservation(context, arm.generation, request.wakeGeneration,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1450:                r449FluviRecovery = recovery
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1451:                KeyguardCardDiagnostics.recordR449Recovery(initial)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1463:                    KeyguardCardDiagnostics.recordR449Recovery(initial.copy(stage = "ADOPT_CURRENT_SUCCESSOR",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1471:            observation = observation.copy(handoff = KeyguardR447Disposition.SETTINGS_UNAVAILABLE)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1473:            KeyguardCardDiagnostics.recordR446(observation)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1482:        fun openingOwned(): Boolean = !r446RestrictionSeen && KeyguardR44Trial.active &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1483:            r448DisplayRoute == route && r448RouteGeneration == routeGeneration &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1489:                    stamp.systemBarrier == r447SystemBarrier && r447SystemBarrier == r447SystemSatisfied
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1492:            state.eligible && r47PrivateAllowed(inspection.r446Normal?.surface ?: KeyguardSurface.UNKNOWN, state,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1497:        val lease = KeyguardR45DirectLifetime.Lease(ticket, arm.capture, request.session, request.wakeGeneration,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1499:        r45Direct.open(lease)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1500:        r45DirectLower = inspection.r45Lower
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1501:        r45RecordStage(context, "FLUVI_STREAM", "INTENT", decision.at,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1502:            detail = if (r45Circle) "CIRCLE" else "ORB")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1503:        fun stillOwned(): Boolean = r45DirectCurrent(lease) &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1504:            r45Direct.phase != KeyguardR45Phase.SUSPENDED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1506:            attachBegin = if (route == KeyguardR448DisplayRoute.FLUVI_STREAM) SystemClock.uptimeMillis() else null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1507:            backend = if (route == KeyguardR448DisplayRoute.FLUVI_STREAM) "ATTEMPTED" else "WA_WAITING")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1509:        KeyguardCardDiagnostics.recordR446(observation)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1510:        runCatching { inspectionProbeForTest?.r447PresenterInvoked(request.id) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1513:            onInvalidated = { if (r45Direct.lease === lease && r45Direct.phase != KeyguardR45Phase.SUSPENDED)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1515:            onFirstTraversal = { at -> r45RecordStage(context, "FLUVI_STREAM", "FIRST_DRAW", at) }) { at ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1520:                KeyguardCardDiagnostics.recordR446(next)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1521:                r45RecordStage(context, "FLUVI_STREAM",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1528:            KeyguardCardDiagnostics.recordR446(requireNotNull(r446Observation))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1532:        r45Direct.visible(lease)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1533:        r45RecordStage(context, "FLUVI_STREAM", "REVEAL", requireNotNull(receipt.submittedAt), detail = "directSubmission")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1536:        KeyguardCardDiagnostics.recordR446(observation)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1537:        if (!r47RecordingHeader) mainHandler.postDelayed({ if (r45Direct.lease === lease) r446Cancel("deadline") },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1569:    private val r449Scope = CoroutineScope(serviceJob + Dispatchers.IO)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1622:                                KeyguardWindowSnapshotReader.Request(knownOwnOverlayIdentity,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1630:                            val classification = KeyguardSurfaceClassifier.classifyDetailed(result.snapshots,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1763:        var firstProof: KeyguardFirstAuthorizedOrb.Proof? = null // Main
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1792:    private val firstAuthorizedOrb = KeyguardFirstAuthorizedOrb(queueLock)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1856:    private val inspectionFreshness = KeyguardInspectionFreshness()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1861:        KeyguardWindowSnapshotReader(this, packageName)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1921:                r447Duplicate = null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2063:        val eligible = r448DisplayRoute == KeyguardR448DisplayRoute.FLUVI_STREAM &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2267:        val previous: KeyguardFirstAuthorizedOrb.Proof?
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2460:        if (KeyguardCardVisibilityPolicy.decide(signalsFromSystemState(settings, KeyguardSurface.MAIN_KEYGUARD, system)) !=
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3048:                    if (r448DisplayRoute == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE && r45Wa.screenOff()) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3050:                    } else if (r446Owner.state == KeyguardR446PrintOwner.State.WAIT_OFF) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3057:                    if (r449Session != null) r449PrepareSessionWake()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3072:                    if (r449Session != null) r449PrepareSessionWake()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3079:                    if (r448DisplayRoute == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3080:                        r45Wa.screenOn(session.get(), KeyguardCardDiagnostics.activeCaptureId())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3084:                    r447RecordWakeArm()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3090:                        r448RecordBoundary(boundaryArm, receivedAt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3091:                        scheduleEvaluation("r448ScreenBoundary", triggerReceivedUptimeMs = receivedAt,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3094:                    r45TryBeginWaWake()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3102:    private var r46DisplayFacts: R46DisplayFacts? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3112:    private fun r46ReconcileDisplay() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3113:        val before = r46DisplayFacts
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3115:        r46DisplayFacts = after
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3116:        val wake = r449Wake
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3117:        val direct = r45Direct.lease
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3118:        if (wake == null && direct == null && r446Owner.state != KeyguardR446PrintOwner.State.ISSUED) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3123:        val waCurrent = wake != null && r449Current(wake, r449RestrictionRevision.get()) &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3124:            wake.allowedRevision == r449RestrictionRevision.get()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3125:        val directCurrent = direct != null && r45Direct.phase == KeyguardR45Phase.VISIBLE && r45DirectCurrent(direct)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3127:            r45RecordStage(wake?.context ?: r446Observation?.context,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3133:            r449RestrictionRevision.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3137:            r45Wa.suspend(wake.arm)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3138:            if (r448Frame?.conceal(wake.owner, "displayRecheck") != true) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3142:            r449ScheduleRead()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3144:            r45DirectRevision.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3145:            r45Direct.suspend(direct)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3149:            r45ScheduleDirectRead(direct)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3165:            r46ReconcileDisplay()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3190:        KeyguardR44Trial.set(false, false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3197:        r448DisplayRoute = KeyguardR448DisplayRouteStore.read(applicationContext)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3198:        r448RouteGeneration++
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3389:        val profile = if (r444ConfigurationReady && !r448SampleOnly) FluviKeyguardMaterialStore.read(applicationContext) else null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3447:        val eventSequence = r45IngressSequence.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3448:        val waWake = r449Wake
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3450:            val ownWa = r448Frame?.isOwnWindow(meta.windowId, meta.displayId) == true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3451:            val action = KeyguardR45IngressPolicy.decide(meta, ownWa, null, waWake.lower)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3452:            r45RecordIngress(waWake.context, "WIDGETS_ANYWHERE", eventSequence, meta, callbackReceivedAt,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3453:                ownWa, action, r45Wa.phase.name, r449RestrictionRevision.get())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3454:            if (action == KeyguardR45IngressAction.IGNORE) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3455:            if (action == KeyguardR45IngressAction.OWN_REMOVED) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3459:            r449RestrictionRevision.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3463:            r45Wa.suspend(waWake.arm)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3464:            if (r448Frame?.conceal(waWake.owner, "unclassifiedEvent") != true) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3469:            r449ScheduleRead()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3472:        val direct = r45Direct.lease
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3473:        if (direct != null && r448DisplayRoute == KeyguardR448DisplayRoute.FLUVI_STREAM) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3474:            val action = KeyguardR45IngressPolicy.decide(meta, false, direct.target.windowId, r45DirectLower)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3475:            r45RecordIngress(r446Observation?.context, "FLUVI_STREAM", eventSequence, meta, callbackReceivedAt,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3476:                false, action, r45Direct.phase.name, r45DirectRevision.get())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3477:            if (action == KeyguardR45IngressAction.IGNORE) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3478:            if (action == KeyguardR45IngressAction.TARGET_REMOVED) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3482:            r45DirectRevision.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3483:            r45Direct.suspend(direct)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3488:            r45RecordStage(r446Observation?.context, "FLUVI_STREAM", "CONCEAL", SystemClock.uptimeMillis(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3489:                revision = r45DirectRevision.get(), detail = "unclassifiedEvent")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3490:            r45ScheduleDirectRead(direct)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3493:        if (r446Owner.state == KeyguardR446PrintOwner.State.ISSUED) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3496:            val ownSampleEvent = if (r448DisplayRoute == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3497:                r448Frame?.isOwnWindow(meta.windowId, meta.displayId) == true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3508:        if (KeyguardR441RestrictionIngress.mustWithdraw(Build.VERSION.SDK_INT, meta, own,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3606:                r449FluviRecovery?.let { recovery ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3609:                        r446Owner.arm == recovery.arm && r446Owner.state == KeyguardR446PrintOwner.State.WAIT_READ &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3616:                        KeyguardCardDiagnostics.recordR449Recovery(initial.copy(stage = "REAL_CHANGE_OFFERED",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3701:            if (r47RecordingHeader && !r47HeaderCurrent() && r446HasBackend())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3785:        if (r448SampleOnly) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3787:            if (r448SampleOnly) return@post
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3807:        if (!r47RecordingHeader || r47HeaderCurrent()) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3809:        r47Header = FluviActiveHeaderMaterialStore.applicable(applicationContext)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3810:        r449PrepareSessionWake()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3930:        if (r442ScreenOn?.session == session.get()) r447RecordWakeArm()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3942:        r45TryBeginWaWake()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3985:    private fun r448BoundaryDecisionLocked(arm: KeyguardR446PrintOwner.Arm,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3986:                                           authority: KeyguardInspectionAuthority): KeyguardR448WakeReadBoundary.Decision {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3988:            KeyguardR448WakeReadBoundary.Work(it.id, authority.matches(it),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3991:        return KeyguardR448WakeReadBoundary.decide(work(inspectionQueue.activeRequest()),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3992:            work(inspectionQueue.pendingRequest()), r448StartedRequest, r448StartedArm == arm.generation)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3995:    private fun r448RecordBoundary(arm: KeyguardR446PrintOwner.Arm, screenAt: Long) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4000:            KeyguardR448BoundaryObservation(context, arm.generation, screenAt,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4002:                r448StartedRequest, r448StartedArm == arm.generation,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4003:                r448BoundaryDecisionLocked(arm, inspectionAuthority))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4005:        runCatching { KeyguardCardDiagnostics.recordR448Boundary(observation) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4040:                r447SystemBarrier == r447SystemSatisfied) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4041:                KeyguardR447DuplicateProof(inspectionAuthority, scene, revision, active.id, order.required,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4042:                    order.barrier, r447SystemBarrier, arm.generation, readAheadStateRevision, r18RouteRevision)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4044:            if (proof == null && r446CaptureId != null) r447SystemBarrier += 1L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4045:            r447SystemBarrier to proof
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4052:            r447SystemBarrier = sampleBarrier, r447Duplicate = duplicate))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4066:            val vetoWa = r449Wake
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4070:                    r446Owner.state in setOf(KeyguardR446PrintOwner.State.WAIT_READ, KeyguardR446PrintOwner.State.ISSUED)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4073:            if (vetoWa != null || r446Owner.state == KeyguardR446PrintOwner.State.WAIT_READ ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4074:                r446Owner.state == KeyguardR446PrintOwner.State.ISSUED) r446Cancel("systemGate")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4079:                state.interactive && state.displayOn && !state.keyguardLocked && r449Session != null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4080:                r449PrepareSessionWake()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4084:                KeyguardCardDiagnostics.recordR448SystemVeto(KeyguardR448SystemVeto(vetoContext,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4097:            if (request.r447SystemBarrier == r447SystemBarrier && request.authority == inspectionAuthority)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4098:                r447SystemSatisfied = request.r447SystemBarrier
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4117:            sampleDuplicate = request.r447Duplicate)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4249:        freshness: KeyguardWindowFreshness, sampleDuplicate: KeyguardR447DuplicateProof?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4267:        sampleDuplicate: KeyguardR447DuplicateProof? = null): Long? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4298:        if (request.trigger != "surfaceRetry" && request.trigger != "r448ScreenBoundary")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4300:        wakeTiming?.takeIf { it.wakeGeneration == request.wakeGeneration && request.trigger != "r448ScreenBoundary" }?.let {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4308:            if (trigger == "r448ScreenBoundary") {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4314:                    r446Owner.state != KeyguardR446PrintOwner.State.WAIT_READ) return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4315:                val decision = r448BoundaryDecisionLocked(arm, authority)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4316:                if (decision != KeyguardR448WakeReadBoundary.Decision.OFFER) return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4325:                    sampleDuplicate.systemBarrier == r447SystemBarrier && r447SystemBarrier == r447SystemSatisfied &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4333:                KeyguardFirstAuthorizedOrb.SampleOffer.INTERNAL_DUPLICATE else KeyguardFirstAuthorizedOrb.SampleOffer.BARRIER)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4359:        if (request.trigger == "r448ScreenBoundary") {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4562:            r448StartedRequest = request.id
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4563:            r448StartedArm = arm?.takeIf { screen != null && screen.session == request.session &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4566:            now to r448StartedArm
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4587:            inspectSurface(request, started, r38MilestoneOrdered, r40Read).also {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4593:                runCatching { KeyguardCardDiagnostics.recordR448Worker(KeyguardR448WorkerObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4612:            runCatching { KeyguardCardDiagnostics.recordR448Worker(KeyguardR448WorkerObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4639:                    KeyguardCardDiagnostics.recordR442Handoff(KeyguardR442HandoffObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4684:        runCatching { inspectionProbeForTest?.r447SampleReadCompleted(request, inspection.r446Eligibility, inspection.abortedStale) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5583:        timing: KeyguardWindowSnapshotReader.Timing? = null, result: Inspection? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5760:        val arm: KeyguardR446PrintOwner.Arm, val request: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5763:        val systemSatisfied: Long, val inventoryAt: Long, val target: KeyguardR446Target? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5778:        val windowTiming: KeyguardWindowSnapshotReader.Timing = KeyguardWindowSnapshotReader.Timing(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5786:        val r446Arm: KeyguardR446PrintOwner.Arm? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5787:        val r446Eligibility: KeyguardR446Eligibility? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5789:        val r447Stamp: R447InventoryStamp? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5790:        val r449UnresolvedUpper: KeyguardR449RestrictionEvidence.UnresolvedUpper? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5791:        val r45Lower: List<KeyguardR45LowerWindow> = emptyList(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5814:        val timing: KeyguardWindowSnapshotReader.Timing = KeyguardWindowSnapshotReader.Timing(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5827:        val r447Stamp: R447InventoryStamp? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5865:        fun snapshot(treeElapsedMs: Long): KeyguardWindowSnapshotReader.Timing = KeyguardWindowSnapshotReader.Timing(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5886:    private fun inspectSurface(request: KeyguardCardInspectionRequest, startedAt: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5895:            return InspectionOutcome.Completed(Inspection(baseline, KeyguardCardVisibilityPolicy.decide(baseline), KeyguardSurfaceReason.NO_WINDOWS))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5913:        val r44Mode = Build.VERSION.SDK_INT == 37 && settings.presentationMode == KeyguardCardPresentationMode.ORB
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5914:        val syntheticAtRead = r44Mode && KeyguardR44Trial.active
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5923:        val read = readSystemWindows(request, startedAt, r38MilestoneOrdered, r40Read, lookupAtRead,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5930:            if (r44Mode) recordR44Read(request, read, sceneAtRead, startedAt, syntheticAtRead, true,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5954:        val classification = if (r44Mode) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5955:            KeyguardR44SurfaceClassifier.classify(snapshots, read.rootUnavailable, read.walkTruncated,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5957:        } else KeyguardSurfaceClassifier.classifyDetailed(snapshots,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5960:        if (r44Mode) recordR44Read(request, read, sceneAtRead, startedAt, syntheticAtRead, false, classification,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5964:        val controlledSample = printArm != null && KeyguardR447TestHooks.CONTROLLED_TOPOLOGY &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5965:            inspectionProbeForTest?.r447ControlledSampleTopology() == true &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5969:            KeyguardR446PrintPolicy.evaluate(if (controlledSample) snapshots else read.snapshots,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5972:        val printNormal = if (printArm != null) KeyguardR44SurfaceClassifier.classify(read.snapshots,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5977:            KeyguardCardVisibilityPolicy.decide(signals),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5996:            r447Stamp = read.r447Stamp?.copy(target = printEligibility?.target),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5997:            r449UnresolvedUpper = if (printArm != null) KeyguardR449RestrictionEvidence.unresolvedUpper(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5999:                    KeyguardR44SurfaceClassifier.classify(read.snapshots, read.rootUnavailable, read.walkTruncated,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6001:            r45Lower = if (printEligibility?.target != null) KeyguardR449RestrictionEvidence.fromInventory(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6006:    private fun recordR44Read(request: KeyguardCardInspectionRequest, read: SystemWindowsRead,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6012:                              profile: KeyguardR444ProfileOwner.Snapshot? = null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6019:        val legacy = KeyguardSurfaceClassifier.classifyDetailed(windows,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6022:        val shadow = if (stale) null else KeyguardR44SurfaceClassifier.classify(windows,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6037:        fun describe(w: KeyguardWindowSnapshot): KeyguardR444WindowObservation {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6045:            return KeyguardR444WindowObservation(w.windowId, w.layer - (host?.layer ?: w.layer),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6053:        KeyguardCardDiagnostics.recordR44(KeyguardR44ReadObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6066:            windows.mapNotNull { w -> w.r44?.let { e -> KeyguardR443WindowObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6099:            showFinancialDetails = settings.showFinancialDetails && !KeyguardR44Trial.active,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6105:    private fun readSystemWindows(request: KeyguardCardInspectionRequest, startedAt: Long, r38MilestoneOrdered: Boolean,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6107:                                  profileAtRead: KeyguardR444ProfileOwner.Snapshot?, printAtRead: KeyguardR446PrintOwner.Arm?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6152:                KeyguardR442YieldPolicy.permits(Build.VERSION.SDK_INT, r442Enabled, screen?.uptime,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6161:        var r447Stamp: R447InventoryStamp? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6176:            request = KeyguardWindowSnapshotReader.Request(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6179:                r44Enabled = Build.VERSION.SDK_INT == 37 &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6181:                r44DeviceEntryResourceVerified = lookup.verified,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6197:                            !KeyguardR44Trial.active || r444ProfileOwner.snapshot.revision != profileAtRead?.revision) null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6291:                            r447Stamp = R447InventoryStamp(printAtRead, request.id, inspectionAuthority, scene,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6292:                                freshness?.revision, order.barrier, r447SystemBarrier, r447SystemSatisfied,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6450:            if (owner != null) KeyguardCardDiagnostics.recordR443Boundary(KeyguardR443BoundaryObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6483:            r447Stamp = r447Stamp,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6492:    private fun readSystemWindowsLegacy(request: KeyguardCardInspectionRequest): SystemWindowsRead = runCatching {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6748:        if (r448SampleOnly && !KeyguardR44Trial.active) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6750:                hideImmediately("r448SampleOnly")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6755:            if (r446Owner.state == KeyguardR446PrintOwner.State.ISSUED) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6756:            if (r448DisplayRoute != KeyguardR448DisplayRoute.WIDGETS_ANYWHERE &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6760:            if (r448DisplayRoute == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6764:            showFinancialDetails = settings.showFinancialDetails && !KeyguardR44Trial.active)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6765:        var decision = KeyguardCardVisibilityPolicy.decide(signals)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6775:            decision = KeyguardCardVisibilityPolicy.decide(signals)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6780:            traceKeyguard("INSPECTION_REJECTED", "r44SceneChanged", request,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6781:                fields = mapOf("rejectionReason" to "r44SceneChanged"))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6782:            requestSystemCheck("r44SceneChanged")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:7152:        if (r448SampleOnly || !r444ConfigurationReady || KeyguardR44Trial.active) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:7200:        if (r448SampleOnly || !r444ConfigurationReady || KeyguardR44Trial.active) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:7234:        if (r448SampleOnly || !r444ConfigurationReady || KeyguardR44Trial.active) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:7393:        if (KeyguardR44Trial.active && presentation.full) return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:8179:        val profile = if (r448SampleOnly) null else FluviKeyguardMaterialStore.read(applicationContext)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:8341:        KeyguardR44Trial.set(false, false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardEventGate.kt:45:internal object KeyguardR441RestrictionIngress {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:108:    fun r447ControlledSampleTopology(): Boolean = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:109:    fun r447SampleReadCompleted(request: KeyguardCardInspectionRequest, eligibility: KeyguardR446Eligibility?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:111:    fun r447PresenterInvoked(request: Long) {}
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:202:        com.fluvi.app.lockscreen.material.FluviActiveHeaderMaterialStore.invalidate()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:270:            com.fluvi.app.lockscreen.material.FluviActiveHeaderMaterialStore.invalidate()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:488:    private val r46OfferLock = Any()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:498:        val r46: Boolean = false,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:502:        val r44Dropped = AtomicLong()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:533:        if (token?.r46 != true) return reduction.offer(work)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:534:        return synchronized(r46OfferLock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:809:        val r44Reads: ArrayDeque<KeyguardR44ReadObservation> = ArrayDeque(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:810:        var r44Last: KeyguardR44ReadObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:811:        var r44FirstPostScreen: KeyguardR44ReadObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:812:        var r44FirstGrant: KeyguardR44ReadObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:813:        var r44FirstRestriction: KeyguardR44ReadObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:814:        var r44ReadsOmitted: Int = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:815:        var r442Handoff: KeyguardR442HandoffObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:816:        var r443Boundary: KeyguardR443BoundaryObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:817:        var r446: KeyguardR446Observation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:818:        var r446Last: KeyguardR446Observation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:819:        var r447FirstEligible: KeyguardR446Observation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:820:        var r447Best: KeyguardR446Observation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:821:        var r447FirstTerminal: KeyguardR446Observation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:822:        var r447Arm: KeyguardR446Observation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:823:        var r447ArmGeneration: Long = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:824:        var r448SystemVeto: KeyguardR448SystemVeto? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:825:        var r448Boundary: KeyguardR448BoundaryObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:826:        var r448Worker: KeyguardR448WorkerObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:827:        var r448Frame: KeyguardR448FrameTrace? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:828:        var r449First: KeyguardR449AdmissionObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:829:        var r449Last: KeyguardR449AdmissionObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:830:        var r449RecoveryFirst: KeyguardR449RecoveryObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:831:        var r449RecoveryLast: KeyguardR449RecoveryObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:832:        var r45Trace: KeyguardR45Trace? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:833:        var r447LatestOrdinal: Long = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:834:        var r447DecisionCount: Int = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:988:        var r449Action: String? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:989:        var r449ConfirmedRoute: String? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:990:        var r449IntentAt: Long? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1000:        var r44Dropped: Long = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1001:        var r447ArmTerminal: R447ArmTerminal? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1487:    fun startCapture(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1495:        r46Request: String? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1496:        r46Route: String? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1504:        if (r46Request != null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1506:            require(r46Route in setOf("FLUVI_STREAM", "WIDGETS_ANYWHERE"))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1507:            KeyguardR46RecordingStore.begin(context, id, requireNotNull(r46Route), r46Request)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1534:                "r448DisplayRoute" to KeyguardR448DisplayRouteStore.read(context).name,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1535:                "r448SampleOnly" to KeyguardR448Safety.sampleOnly(context).toString(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1536:                "r448WaSource" to "9c7fed25ec833197656dec57427be4c26fc66138",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1541:                "r46Recording" to (r46Request != null).toString(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1552:            r46 = r46Request != null).also {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1565:    fun freezeCapture(context: Context): Map<String, Any?> = freezeCaptureAfterCut(context, null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1568:        val token = synchronized(r46OfferLock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1569:            ingress?.takeIf { it.r46 }?.also {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1574:        return freezeCaptureAfterCut(context, token)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1577:    private fun freezeCaptureAfterCut(context: Context, cutToken: CaptureIngress?): Map<String, Any?> = reduction.read {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1614:            val route = frozen.configuration["r448DisplayRoute"]
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1617:                KeyguardR448ComparisonStore.save(context, route, frozen.id, report)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1757:    internal fun recordR44(observation: KeyguardR44ReadObservation) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1765:                if (active.configuration["r46Recording"] == "true")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1766:                    KeyguardR46RecordingStore.offer(active.id, "R44_READ $observation")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1771:                    token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1774:                if (attempt.r44Reads.any { it.request == observation.request }) return@synchronized
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1777:                    (attempt.r44FirstPostScreen == null || observation.start < attempt.r44FirstPostScreen!!.start))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1778:                    attempt.r44FirstPostScreen = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1780:                    observation.verdict == KeyguardSurface.MAIN_KEYGUARD && attempt.r44FirstGrant == null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1781:                    attempt.r44FirstGrant = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1784:                    attempt.r44FirstRestriction == null) attempt.r44FirstRestriction = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1785:                if (attempt.r44Reads.size < 12) attempt.r44Reads.addLast(observation)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1786:                else { attempt.r44ReadsOmitted += 1; attempt.r44Last = observation }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1789:        if (!accepted) token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1792:    internal fun recordR449Admission(observation: KeyguardR449AdmissionObservation) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1799:                if (active.configuration["r46Recording"] == "true")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1800:                    KeyguardR46RecordingStore.offer(active.id, "R449_ADMISSION $observation")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1805:                    if (attempt.r449First == null) attempt.r449First = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1806:                    attempt.r449Last = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1810:        if (!accepted) token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1813:    internal fun recordR449Intent(captureId: String, action: String, route: String, at: Long) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1819:                if (active.configuration["r46Recording"] == "true")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1820:                    KeyguardR46RecordingStore.offer(active.id, "R449_INTENT capture=$captureId action=$action route=$route up=$at")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1821:                active.r449Action = action
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1822:                active.r449ConfirmedRoute = route
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1823:                active.r449IntentAt = at
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1826:        if (!accepted) token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1829:    internal fun recordR449Recovery(observation: KeyguardR449RecoveryObservation) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1836:                if (active.configuration["r46Recording"] == "true")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1837:                    KeyguardR46RecordingStore.offer(active.id, "R449_RECOVERY $observation")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1842:                    if (attempt.r449RecoveryFirst == null) attempt.r449RecoveryFirst = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1843:                    attempt.r449RecoveryLast = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1847:        if (!accepted) token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1850:    internal fun recordR45(observation: KeyguardR45Observation) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1857:                if (active.configuration["r46Recording"] == "true")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1858:                    KeyguardR46RecordingStore.offer(active.id, "R45_EVENT $observation")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1863:                val trace = attempt.r45Trace ?: KeyguardR45Trace().also { attempt.r45Trace = it }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1892:        if (!accepted) token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1895:    internal fun recordR448Frame(observation: KeyguardR448FrameObservation) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1903:                if (active.configuration["r46Recording"] == "true")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1904:                    KeyguardR46RecordingStore.offer(active.id, "R448_FRAME $observation")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1909:                val trace = attempt.r448Frame ?: KeyguardR448FrameTrace(observation.owner).also { attempt.r448Frame = it }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1938:        if (!accepted) token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1941:    internal fun recordR448Boundary(observation: KeyguardR448BoundaryObservation) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1948:                if (active.configuration["r46Recording"] == "true")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1949:                    KeyguardR46RecordingStore.offer(active.id, "R448_BOUNDARY $observation")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1953:                    attempt.wakeEpoch == owner.originWakeEpoch && attempt.r448Boundary == null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1954:                    attempt.r448Boundary = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1957:        if (!accepted) token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1960:    internal fun recordR448Worker(observation: KeyguardR448WorkerObservation) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1967:                if (active.configuration["r46Recording"] == "true")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1968:                    KeyguardR46RecordingStore.offer(active.id, "R448_WORKER $observation")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1972:                    attempt.wakeEpoch == owner.originWakeEpoch && attempt.r448Worker == null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1973:                    attempt.r448Worker = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1976:        if (!accepted) token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1980:    internal fun recordR448SystemVeto(observation: KeyguardR448SystemVeto) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1987:                if (active.configuration["r46Recording"] == "true")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1988:                    KeyguardR46RecordingStore.offer(active.id, "R448_SYSTEM_VETO $observation")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1992:                    attempt.wakeEpoch == owner.originWakeEpoch && attempt.r448SystemVeto == null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1993:                    attempt.r448SystemVeto = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1996:        if (!accepted) token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1999:    internal fun recordR446(observation: KeyguardR446Observation) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2006:                if (active.configuration["r46Recording"] == "true")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2007:                    KeyguardR46RecordingStore.offer(active.id, "R446_OUTPUT $observation")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2012:                    if (observation.armGeneration > 0 && attempt.r447ArmGeneration > 0 &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2013:                        observation.armGeneration != attempt.r447ArmGeneration) return@synchronized
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2014:                    if (observation.armGeneration > 0) attempt.r447ArmGeneration = observation.armGeneration
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2018:                        if (attempt.r447Arm == null || (attempt.r447Arm?.wakeArmState != "ARMED" &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2019:                                observation.wakeArmState == "ARMED")) attempt.r447Arm = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2020:                        if (observation.withdrawAt != null && attempt.r447FirstTerminal == null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2021:                            attempt.r447FirstTerminal = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2026:                    if (observation.eligibility == "ELIGIBLE_SAMPLE" && attempt.r447FirstEligible == null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2027:                        attempt.r447FirstEligible = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2029:                    if (ordinal > attempt.r447LatestOrdinal) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2030:                        attempt.r447LatestOrdinal = ordinal
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2031:                        attempt.r447DecisionCount = (attempt.r447DecisionCount + 1).coerceAtMost(9999)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2033:                    } else if (ordinal == attempt.r447LatestOrdinal &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2035:                    fun progress(o: KeyguardR446Observation): Int = when {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2042:                    val best = attempt.r447Best
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2045:                        attempt.r447Best = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2046:                    if (observation.withdrawAt != null && attempt.r447FirstTerminal == null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2047:                        attempt.r447FirstTerminal = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2051:        if (!accepted) token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2056:    internal fun recordR447ArmTerminal(captureId: String, generation: Long, at: Long, reason: String) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2062:                if (active.configuration["r46Recording"] == "true")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2063:                    KeyguardR46RecordingStore.offer(active.id, "R447_TERMINAL generation=$generation up=$at reason=${technicalValue(reason).take(80)}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2064:                if (active.r447ArmTerminal == null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2065:                    active.r447ArmTerminal = R447ArmTerminal(generation, at, technicalValue(reason).take(80))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2068:        if (!accepted) token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2071:    internal fun recordR442Handoff(observation: KeyguardR442HandoffObservation) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2078:                if (active.configuration["r46Recording"] == "true")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2079:                    KeyguardR46RecordingStore.offer(active.id, "R442_HANDOFF $observation")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2087:        if (!accepted) token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2090:    internal fun recordR443Boundary(observation: KeyguardR443BoundaryObservation) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2097:                if (active.configuration["r46Recording"] == "true")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2098:                    KeyguardR46RecordingStore.offer(active.id, "R443_BOUNDARY $observation")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2106:        if (!accepted) token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2151:                if (active.configuration["r46Recording"] == "true")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2152:                    KeyguardR46RecordingStore.offer(active.id, row.trim())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2477:        if (active.configuration["r46Recording"] == "true")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2478:            KeyguardR46RecordingStore.offer(active.id, "EVENT ${event.toLine(compact = false)}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3075:        if (active.configuration["r46Recording"] == "true") return false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3112:            val report = formatReport(snapshot, recoveredFromDisk = false, exportLimitBytes = 32 * 1024)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3312:        r44Dropped = r41Token?.r44Dropped?.get() ?: active.r44Dropped,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3321:        r448Frame = attempt.r448Frame?.copy(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3322:        r44Reads = ArrayDeque(attempt.r44Reads),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3378:        val report = formatReport(active, recoveredFromDisk = false, exportLimitBytes = 32 * 1024)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3422:    private fun formatReport(active: TimingCapture, recoveredFromDisk: Boolean, exportLimitBytes: Int): String {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3438:            if (Build.VERSION.SDK_INT == 37) appendLine("R44_CAPTURE dropped=${active.r44Dropped} physicalPixels=UNOBSERVED")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3557:        active.r447ArmTerminal?.let { terminal ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3558:            select("r447:armTerminal", "R44_7_ARM generation=${terminal.generation} terminal=${terminal.at}/${terminal.reason} clock=uptimeMs\n")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3560:        val r44Attempts = (listOfNotNull(active.firstAttempt) + active.attempts).distinctBy { it.id }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3561:        r44Attempts.forEach { attempt ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3562:            val route = active.configuration["r448DisplayRoute"] ?: "UNOBSERVED"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3563:            val action = active.r449Action ?: if (active.configuration["r446PrintRequested"] == "true") "LEGACY_ONE_WAKE" else "PASSIVE"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3564:            val progress = attempt.r447Best ?: attempt.r446Last ?: attempt.r446
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3565:            val terminal = attempt.r447FirstTerminal
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3573:            select("a${attempt.id}:r449outcome", "R44_9_OUTCOME capture=${active.id} wake=${attempt.wakeEpoch} routeRequested=$route routeConfirmed=${active.r449ConfirmedRoute ?: "UNOBSERVED"} action=$action intent=${active.r449IntentAt ?: "UNOBSERVED"} arm=${attempt.r447Arm?.wakeArmState ?: "UNOBSERVED"} backend=${progress?.backend ?: "NOT_ATTEMPTED"} issue=${progress?.issuedAt ?: "UNOBSERVED"} frame=${progress?.frameAt ?: "UNOBSERVED"} terminal=${terminal?.withdrawReason ?: "UNOBSERVED"} physical=UNOBSERVED clock=uptimeMs\nR44_9_HU $status\n", attempt.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3574:            attempt.r45Trace?.let { t ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3583:                select("a${attempt.id}:r45life", "R45_LIFECYCLE wake=${attempt.wakeEpoch} route=${active.r449ConfirmedRoute ?: "UNOBSERVED"} shape=${t.shape ?: "UNOBSERVED"} attachedHidden=${t.attachedHidden ?: "UNOBSERVED"} postCheck=${t.postCheckBegin ?: "UNOBSERVED"}/${t.postCheckEnd ?: "UNOBSERVED"}/${t.postCheckResult ?: "UNOBSERVED"} reveal=${t.reveal ?: "UNOBSERVED"} revealState=${t.revealState ?: "UNOBSERVED"} firstDraw=${t.firstDraw ?: "UNOBSERVED"} firstShader=${t.firstShader ?: "UNOBSERVED"} firstPreparedFrame=${t.firstPreparedFrame ?: "UNOBSERVED"} conceal=${t.conceal ?: "UNOBSERVED"} remove=${t.remove ?: "UNOBSERVED"} ignored=${t.ignored} unknown=${t.unknown} terminalEvents=${t.terminalEvents} suspended=${t.suspended} resumed=${t.resumed} terminal=${stopped?.detail ?: "UNOBSERVED"} terminalAt=${stopped?.at ?: "UNOBSERVED"} optical=UNOBSERVED clock=uptimeMs\nR45_HU $hu\n", attempt.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3584:                if (first != null) select("a${attempt.id}:r45event", "R45_EVENT wake=${attempt.wakeEpoch} seq=${first.sequence ?: "UNOBSERVED"} source=${first.sourceAt ?: "UNOBSERVED"} received=${first.at} type=${first.eventType ?: "UNOBSERVED"} mask=${first.changes ?: "UNOBSERVED"} window=${first.window ?: "UNOBSERVED"} display=${first.display ?: "UNOBSERVED"} origin=${first.attribution} decision=${first.decision} phase=${first.phase} revision=${first.revision} clock=uptimeMs\n", attempt.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3585:                if (recovery != null) select("a${attempt.id}:r45recovery", "R45_RECOVERY wake=${attempt.wakeEpoch} route=${recovery.route} revision=${recovery.revision} read=${recovery.readStart ?: "UNOBSERVED"}/${recovery.readEnd ?: "UNOBSERVED"} result=${recovery.decision} reason=${recovery.detail} clock=uptimeMs\n", attempt.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3587:            listOfNotNull(attempt.r449RecoveryFirst, attempt.r449RecoveryLast).distinct().forEachIndexed { index, r ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3588:                select("a${attempt.id}:r449retry:$index", "R44_9_FLUVI_RECOVERY wake=${r.wake} arm=${r.arm} initialReq=${r.initialRequest} host=${r.host} upper=${r.upper} inventory=${r.inventoryAt} stage=${r.stage} at=${r.at} successor=${r.successor ?: "UNOBSERVED"} clock=uptimeMs\n", attempt.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3590:            listOfNotNull(attempt.r449First, attempt.r449Last).distinct().forEachIndexed { index, o ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3593:                    attempt.r448Frame?.firstShader != null || attempt.r448Frame?.firstPreparedFrame != null -> "Widgets Anywhere: a mintaablak rajzolt; a képernyőn való láthatóság nem mért."
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3594:                    o.decision == KeyguardR448Admission.Decision.ALLOW -> "Widgets Anywhere: a minta engedélyezve; a láthatóság nem mért."
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3597:                select("a${attempt.id}:r449:$index", "R44_9_HU $summary\nR44_9_ADMISSION wake=${attempt.wakeEpoch} arm=${o.arm} routeRequested=WIDGETS_ANYWHERE routeConfirmed=WIDGETS_ANYWHERE routeGeneration=${o.routeGeneration} materialGeneration=${o.materialGeneration} restrictionRevision=${o.restrictionRevision} domain=${o.domain} action=${o.action} screenOn=${o.screenAt} readStart=${o.readStart} readEnd=${o.readEnd} systemRead=${o.system.startedAt}/${o.system.finishedAt} available=${o.system.available} interactive=${o.system.interactive} displayOn=${o.system.displayOn} locked=${o.system.keyguardLocked} credential=${e.credential} shade=${e.shade} foreign=${e.foreign} power=${e.powerMenu} evidenceAt=${e.observedAt} reason=${o.reason} decision=${o.decision} issue=${o.issueAt ?: "UNOBSERVED"} physical=UNOBSERVED clock=uptimeMs\n", attempt.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3599:            attempt.r448Frame?.let { f ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3600:                select("a${attempt.id}:r448frame", "R44_8_WA wake=${attempt.wakeEpoch} routeGeneration=${f.owner.route} materialGeneration=${f.owner.material} firstAllowed=${f.firstAllowed ?: "UNOBSERVED"} debounceScheduled=${f.scheduled ?: "UNOBSERVED"} requestedDue=${f.scheduled?.plus(50) ?: "UNOBSERVED"} debounceFired=${f.fired ?: "UNOBSERVED"} debounceCanceled=${f.canceled ?: "UNOBSERVED"} coalesced=${f.coalesced} secondAllowed=${f.secondAllowed ?: "UNOBSERVED"} addBegin=${f.addBegin ?: "UNOBSERVED"} addReturn=${f.addReturn ?: "UNOBSERVED"} attached=${f.attached ?: "UNOBSERVED"} firstShader=${f.firstShader ?: "UNOBSERVED"} firstPreparedFrame=${f.firstPreparedFrame ?: "UNOBSERVED"} hide=${f.hide ?: "UNOBSERVED"} removeReturn=${f.removeReturn ?: "UNOBSERVED"} detached=${f.detached ?: "UNOBSERVED"} geometry=${f.geometry ?: "UNOBSERVED"} terminal=${f.terminal ?: "UNOBSERVED"} terminalAt=${f.terminalAt ?: "UNOBSERVED"} physical=UNOBSERVED clock=uptimeMs\n", attempt.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3602:            attempt.r448Boundary?.let { b ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3603:                val w = attempt.r448Worker
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3604:                select("a${attempt.id}:r448boundary", "R44_8_READ_BOUNDARY wake=${attempt.wakeEpoch} arm=${b.arm} screenOn=${b.screenAt} active=${b.active ?: "UNOBSERVED"} pending=${b.pending ?: "UNOBSERVED"} started=${b.started ?: "UNOBSERVED"} startedForArm=${b.startedForArm} boundaryDecision=${b.decision} workerRequest=${w?.request ?: "UNOBSERVED"} workerQueued=${w?.queued ?: "UNOBSERVED"} workerStart=${w?.started ?: "UNOBSERVED"} workerEnd=${w?.finished ?: "UNOBSERVED"} workerOutcome=${w?.outcome ?: "UNOBSERVED"} eligibility=${w?.eligibility ?: "UNOBSERVED"} authorityAtEnd=${w?.authorityAtEnd ?: "UNOBSERVED"} clock=uptimeMs\n", attempt.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3606:            attempt.r448SystemVeto?.let { v ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3608:                select("a${attempt.id}:r448gate", "R44_8_SYSTEM_VETO wake=${attempt.wakeEpoch} arm=${v.armGeneration} request=${v.requestId} requestCaptureMatched=${v.requestCaptureMatched} reason=${technicalValue(v.reason)} screenOn=${v.screenOnAt ?: "UNOBSERVED"} received=${v.receivedAt} queued=${v.queuedAt} readStart=${s.startedAt} readEnd=${s.finishedAt} main=${v.mainAt} available=${s.available} primaryDisplay=${s.primaryDisplay} interactive=${s.interactive} displayOn=${s.displayOn} displayOff=${s.displayOff} keyguardLocked=${s.keyguardLocked} userUnlocked=${s.userUnlocked} excluded=${s.excluded} clock=uptimeMs\n", attempt.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3612:        r44Attempts.forEach { attempt ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3616:                    val armState = attempt.r447Arm?.wakeArmState ?: "UNOBSERVED"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3622:                    val terminal = attempt.r447FirstTerminal
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3623:                    select("a${attempt.id}:r446", "R44_6_HU $message\nR44_6_SAMPLE wake=${attempt.wakeEpoch} arm=UNOBSERVED firstReq=UNOBSERVED firstNormal=UNOBSERVED firstEligible=UNOBSERVED firstBackend=NOT_ATTEMPTED req=UNOBSERVED normal=UNOBSERVED eligible=UNOBSERVED backend=NOT_ATTEMPTED host=UNOBSERVED scene=UNOBSERVED issue=UNOBSERVED attachBegin=UNOBSERVED attachEnd=UNOBSERVED submit=UNOBSERVED frame=UNOBSERVED withdraw=${terminal?.withdrawAt ?: "UNOBSERVED"}/${terminal?.withdrawReason ?: "UNOBSERVED"} hideReturn=${terminal?.hideReturn ?: "UNOBSERVED"} releaseReturn=${terminal?.releaseReturn ?: "UNOBSERVED"} retireError=${terminal?.retireError ?: "none"} armState=$armState physical=UNOBSERVED clock=uptimeMs\n", attempt.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3628:            val p = attempt.r447Best ?: o
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3629:            val terminal = attempt.r447FirstTerminal ?: p
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3637:            select("a${attempt.id}:r446", "R44_6_HU $status\nR44_6_SAMPLE wake=${o.wake} arm=${o.armAt} firstReq=${first.request} firstNormal=${first.normal} firstEligible=${first.eligibility} firstBackend=${first.backend} req=${o.request} normal=${o.normal} eligible=${o.eligibility} backend=${o.backend} host=${o.host ?: "UNOBSERVED"} scene=${o.scene ?: "UNOBSERVED"} issue=${p.issuedAt ?: "UNOBSERVED"} attachBegin=${p.attachBegin ?: "UNOBSERVED"} attachEnd=${p.attachEnd ?: "UNOBSERVED"} submit=${p.submittedAt ?: "UNOBSERVED"} frame=${p.frameAt ?: "UNOBSERVED"} withdraw=${terminal.withdrawAt ?: "UNOBSERVED"}/${terminal.withdrawReason} hideReturn=${terminal.hideReturn ?: "UNOBSERVED"} releaseReturn=${terminal.releaseReturn ?: "UNOBSERVED"} retireError=${terminal.retireError ?: "none"} firstEligibleReq=${attempt.r447FirstEligible?.request ?: "UNOBSERVED"} firstEligibleHandoff=${attempt.r447FirstEligible?.handoff ?: "UNOBSERVED"} firstHandoff=${first.handoff} progressReq=${p.request} terminalReq=${if (terminal.withdrawAt != null) terminal.request else "UNOBSERVED"} decisions=${attempt.r447DecisionCount} ordinal=${o.decisionOrdinal} handoff=${o.handoff} order=${o.order?.result ?: "UNOBSERVED"} completed=${o.order?.completed ?: "UNOBSERVED"} required=${o.order?.required ?: "UNOBSERVED"} barrier=${o.order?.barrier ?: "UNOBSERVED"} origin=${o.order?.origin ?: "UNOBSERVED"} sceneNow=${o.order?.scene ?: "UNOBSERVED"} inventory=${o.inventoryAt ?: "UNOBSERVED"} readEnd=${o.readFinishedAt ?: "UNOBSERVED"} mainEntry=${o.mainEnteredAt ?: "UNOBSERVED"} decide=${o.decisionAt ?: "UNOBSERVED"} freshness=${o.freshnessRevision ?: "UNOBSERVED"} sysAtRead=${o.systemBarrierAtRead ?: "UNOBSERVED"} sysNow=${o.systemBarrierAtDecision ?: "UNOBSERVED"} owner=${o.ownerState} physical=UNOBSERVED clock=uptimeMs\n", attempt.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3639:        r44Attempts.filter { it.r44Reads.isNotEmpty() ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3641:            select("a${attempt.id}:r44Core", r44Record(active.id, attempt,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3994:            selected.filterKeys { it.endsWith(":r44Core") }.values.forEach(::append)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4000:            selected.filterKeys { !it.endsWith(":summary") && !it.endsWith(":r44Core") && !it.endsWith(":spineRows") && !it.endsWith(":raw") && ":drawGap:" !in it }.values.forEach(::append)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4014:    private fun r44Record(captureId: String, attempt: TimingAttempt, trialRequested: Boolean): String = buildString {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4015:        val reads = attempt.r44Reads.toList()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4017:        val post = attempt.r44FirstPostScreen ?: screen?.let { t -> reads.filter {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4020:        val last = attempt.r44Last ?: reads.lastOrNull()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4025:        appendLine("R44_HU próba=${attempt.id} eredmény=$outcome első_ébredés_utáni_olvasás=${post?.request ?: "HIÁNYZIK"} fizikailag_látható=ISMERETLEN")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4026:        if (!trialRequested) appendLine("R44_2_HU A mintaorb-próba nem volt elindítva; ez csak rögzítés.")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4028:            appendLine("R44_2_HU FIGYELEM: a mintaorb-próba visszaigazolása vagy üzemmódja elveszett.")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4030:        appendLine("R44_2_TRIAL requested=$trialRequested receipt=${post?.receipt ?: "UNOBSERVED"} domain=$domain")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4038:            post.appliedGate == KeyguardR444Gate.COVER_VETO -> "Az elfogadott jel mellett egy másik ablak kizárja a megjelenítést."
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4039:            post.reason == KeyguardSurfaceReason.NO_MAIN_MARKER || post.appliedGate == KeyguardR444Gate.NO_CONTENT ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4047:        appendLine("R44_4_HU próba=${attempt.id} $reasonHu" +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4048:            if (additionalWindow && post?.appliedGate != KeyguardR444Gate.COVER_VETO)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4053:                post.appliedGate == KeyguardR444Gate.RESTRICTION -> "Tiltott képernyő: rejtve."
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4055:                post.appliedGate == KeyguardR444Gate.COVER_VETO && companion ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4057:                post.appliedGate == KeyguardR444Gate.COVER_VETO -> "Jel megvan; a felső ablak nem minősíthető."
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4062:            appendLine("R44_5_HU próba=${attempt.id} $status")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4066:            listOfNotNull(post, attempt.r44FirstGrant, attempt.r44FirstRestriction, last)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4069:        appendLine("R44_2_HANDOFF old=${handoff?.oldRequest ?: "UNOBSERVED"} next=${handoff?.nextRequest ?: "UNOBSERVED"} screen=${handoff?.screenAt ?: "UNOBSERVED"} offer=${handoff?.offerAt ?: "UNOBSERVED"} oldStart=${handoff?.oldStart ?: "UNOBSERVED"} boundary=${handoff?.boundaryAt ?: "UNOBSERVED"} oldReturn=${handoff?.oldReturn ?: "UNOBSERVED"} where=${handoff?.boundary ?: "UNOBSERVED"} newStart=${successorRead?.start ?: "UNOBSERVED"} newEnd=${successorRead?.end ?: "UNOBSERVED"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4071:        appendLine("R44_3_BOUNDARY old=${boundary?.oldRequest ?: "UNOBSERVED"} pending=${boundary?.pendingRequest ?: "UNOBSERVED"} screen=${boundary?.screenAt ?: "UNOBSERVED"} offer=${boundary?.offerAt ?: "UNOBSERVED"} oldStart=${boundary?.oldStart ?: "UNOBSERVED"} at=${boundary?.boundaryAt ?: "UNOBSERVED"} oldEnd=${boundary?.oldEnd ?: "UNOBSERVED"} reason=${boundary?.reason ?: "UNOBSERVED"} ingress=${boundary?.ingressKind ?: "UNOBSERVED"}/${boundary?.ingressStart ?: "UNOBSERVED"}/${boundary?.ingressEnd ?: "UNOBSERVED"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4072:        appendLine("R44_WAKE capture=$captureId session=${attempt.serviceSession} wake=${attempt.wakeEpoch} screenOn=${screen ?: "UNOBSERVED"} firstPostRead=${post?.request ?: "missing"} omitted=${attempt.r44ReadsOmitted} showRequest=${show?.requestId ?: "none"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4073:        fun line(kind: String, read: KeyguardR44ReadObservation) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4077:                appendLine("R44_READ kind=$kind wake=${attempt.wakeEpoch} req=${read.request} start=${read.start} end=${read.end} verdict=${read.verdict} reason=${read.reason} stale=${read.stale}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4080:            appendLine("R44_READ kind=$kind wake=${attempt.wakeEpoch} req=${read.request} epoch=${read.epoch} scene=${read.scene ?: "UNOBSERVED"} start=${read.start} end=${read.end} owner=${if (read.hostVerified) "verified" else "rejected"} hostWin=${read.hostWindow ?: "UNOBSERVED"} hostLayer=${read.hostLayer ?: "UNOBSERVED"} complete=${read.coverageComplete} legacy=${read.legacy} host=${host?.marker ?: "none"}/${host?.carrier ?: "none"} content=${content?.marker ?: "none"}/${content?.carrier ?: "none"} relation=${if (read.relation) "descendant" else "unknown"} extra=${read.advertised}/${read.fetched}/${read.failed} unsupported=${read.unsupported} budgetHit=${read.budgetHit} extraMs=${read.extraMs} stale=${read.stale} unavailable=${read.unavailable} truncated=${read.truncated}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4085:                appendLine("R44_3_ABLAK req=${read.request} window:advertised/fetched/overflow:state=$windowSummary")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4087:                    appendLine("R44_3_JEL req=${read.request} window=${c.window} ordinal=${c.ordinal} branch=${c.branch} rank=${c.rank} status=${c.status} role=${c.role} costMs=${c.costMs} remaining=${c.remaining} remainingMs=${c.remainingMs} parentChecks=${c.parentChecks} parentMs=${c.parentMs}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4091:                KeyguardR444Gate.COVER_VETO -> "VETO"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4092:                KeyguardR444Gate.ACCEPTED -> "CLEAR"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4095:            appendLine("R44_4_PROFILE req=${read.request} profile=${read.profile} revision=${read.profileRevision ?: "UNOBSERVED"} previousFlags=${read.previousFlags ?: "UNOBSERVED"} actualFlags=${read.actualFlags ?: "UNOBSERVED"} clockResource=${read.clockResourceVerified} hostNodes=${read.hostNodes} hostCarriers=${read.hostCarriers} hostParent=${read.hostParent ?: "UNOBSERVED"} contentParent=${read.contentParent ?: "UNOBSERVED"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4096:            appendLine("R44_4_GATE req=${read.request} applied=${read.appliedGate} coverReached=$coverReached structural=${read.cover} secondary=${read.secondaryCount} overflow=${read.secondaryOverflow}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4098:            appendLine("R44_5_INDEX req=${read.request} installedSmall=${read.r445SmallInstalled} installedLarge=${read.r445LargeInstalled} installedEntry=${read.r445EntryInstalled} status=${read.r445IndexStatus} backend=$backend pixel=UNOBSERVED")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4100:                appendLine("R44_5_ID req=${read.request} role=${call.role} outcome=${call.outcome} hitsCap9=${call.rawHits} reject=${call.firstRejection} durationMs=${call.durationMs} ageMs=${call.ageMs} overrunMs=${call.overrunMs}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4103:                appendLine("R44_4_WINDOW req=${read.request} id=${w.id} relativeLayer=${w.relativeLayer} type=${w.type} active=${w.active ?: "UNOBSERVED"} focused=${w.focused ?: "UNOBSERVED"} owner=${w.owner} ownGen=${w.ownGeneration ?: "UNOBSERVED"} verified=${w.verifiedRoot} visited=${w.visited ?: "UNOBSERVED"} root=${w.rootRole}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4105:            appendLine("R44_DECISION wake=${attempt.wakeEpoch} req=${read.request} mode=${if (read.synthetic) "syntheticTrial" else "normal"} testProbeInjected=${read.testProbeInjected} verdict=${read.verdict} reason=${read.reason}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4106:            appendLine("R44_2_EVIDENCE req=${read.request} lookup=${read.lookupStatus} lookupIdentity=${read.lookupIdentity ?: "UNOBSERVED"} rawHost=${read.rawHost} rawEntry=${read.rawEntry} rawClock=${read.rawClock} candidate=${read.firstCandidate ?: "none"}/${read.firstCarrier ?: "none"} rejectUnverified=${read.rejectedUnverified} rejectAncestry=${read.rejectedAncestry} rejectExcluded=${read.rejectedExcluded} rejectForeign=${read.rejectedForeign} rejectHidden=${read.rejectedHidden} cover=${read.cover} shadow=${read.shadowVerdict ?: "UNOBSERVED"}/${read.shadowReason ?: "UNOBSERVED"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4111:        fun unique(kind: String, read: KeyguardR44ReadObservation?) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4114:        unique("firstMainClassification", attempt.r44FirstGrant)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4115:        unique("firstRestrictionClassification", attempt.r44FirstRestriction)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4118:        appendLine("R44_END wake=${attempt.wakeEpoch} last=${attempt.finalState} grant=${show?.decisionAtUptimeMs ?: "UNOBSERVED"} attach=${show?.addReturnAtUptimeMs ?: "UNOBSERVED"} post=${show?.r12Evidence?.get("firstPost") ?: "UNOBSERVED"} postDelivery=${show?.r12Evidence?.get("firstPostMain") ?: "UNOBSERVED"} ack=${show?.r11Evidence?.get("ack") ?: "UNOBSERVED"} remove=${hide?.removeReturnAtUptimeMs ?: "UNOBSERVED"} physicalPixels=UNOBSERVED")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSurface.kt:27:internal enum class KeyguardR444Gate { UNOBSERVED, RESTRICTION, INCOMPLETE, NO_HOST, NO_CONTENT, INVALID_PAIR, COVER_VETO, ACCEPTED, LEGACY }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSurface.kt:34:    val r444Gate: KeyguardR444Gate = KeyguardR444Gate.UNOBSERVED,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSurface.kt:55:    val r44: KeyguardR44WindowEvidence? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSurface.kt:62:    val r446Bounds: KeyguardR446Bounds? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSurface.kt:65:internal object KeyguardSurfaceClassifier {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSurface.kt:200:internal object KeyguardCardVisibilityPolicy {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:430:        val settings = KeyguardR44Trial.settings(requestedSettings)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:431:        val profile = KeyguardR44Trial.profile(requestedProfile)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:457:        return !isAttached && root != null && KeyguardR44Trial.active &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:458:            materialProfile === KeyguardR44Trial.profile(null) &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:469:        val intent = KeyguardFirstAuthorizedOrb.intent(materialSettings.showFinancialDetails)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:470:        val wantsFull = full ?: (intent == KeyguardFirstAuthorizedOrb.Intent.EMPTY_AWAITING_DISCLOSURE)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:616:        if (KeyguardR44Trial.active && (presentation.full || materialProfile !== KeyguardR44Trial.profile(null)))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:1028:        val profile = KeyguardR44Trial.profile(requestedProfile)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:1029:        val settings = KeyguardR44Trial.settings(requestedSettings)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAcquisition.kt:24:        ticket: KeyguardInspectionFreshness.Ticket?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrb.kt:6:internal class KeyguardFirstAuthorizedOrb(private val lock: Any = Any()) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshness.kt:8:internal class KeyguardInspectionFreshness {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR40RemovalGate.kt:86:        if (KeyguardSurfaceClassifier.isMainMarker(id)) main = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR40RemovalGate.kt:87:        if (KeyguardSurfaceClassifier.isClockMarker(id)) clock = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR43SurfaceEvidence.kt:78:            if (snapshot != null) window.markers = KeyguardSurfaceClassifier.classifyDetailed(listOf(snapshot)).markers
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR442YieldPolicy.kt:4:internal object KeyguardR442YieldPolicy {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR443Inventory.kt:12:internal object KeyguardR443ParentIdentity {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR443Inventory.kt:32:internal class KeyguardR443Inventory(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR443Inventory.kt:33:    private val budget: KeyguardR44ExtraBudget,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR443Inventory.kt:37:        val owner: KeyguardR44TreeReader,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR443Inventory.kt:49:    fun collect(owner: KeyguardR44TreeReader, node: AccessibilityNodeInfo,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR443Inventory.kt:65:                else KeyguardR443ParentIdentity.of(currentParent)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR443Inventory.kt:87:    fun resolve(canExtend: (KeyguardR44TreeReader) -> Boolean) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR444ProfileOwner.kt:10:internal class KeyguardR444ProfileOwner(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR445WakeBudget.kt:5:internal class KeyguardR445WakeBudget {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicy.kt:7:internal data class KeyguardR446Bounds(val left: Int, val top: Int, val right: Int, val bottom: Int) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicy.kt:16:internal data class KeyguardR446Target(val windowId: Int, val displayId: Int, val bounds: KeyguardR446Bounds)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicy.kt:17:internal data class KeyguardR446Eligibility(val target: KeyguardR446Target?, val reason: String)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicy.kt:20:internal enum class KeyguardR447Disposition {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicy.kt:27:internal object KeyguardR446PrintPolicy {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicy.kt:31:    ): KeyguardR446Eligibility {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicy.kt:32:        fun denied(reason: String) = KeyguardR446Eligibility(null, reason)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicy.kt:34:            classification.r444Gate == KeyguardR444Gate.RESTRICTION) return denied("RESTRICTION")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicy.kt:35:        if (unavailable || truncated || classification.r444Gate == KeyguardR444Gate.INCOMPLETE)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicy.kt:41:                classification.r444Gate in setOf(KeyguardR444Gate.NO_CONTENT, KeyguardR444Gate.NO_HOST,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicy.kt:42:                    KeyguardR444Gate.COVER_VETO))) return denied("UNKNOWN_SCENE")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicy.kt:57:        return KeyguardR446Eligibility(KeyguardR446Target(host.windowId, host.displayId, bounds), "ELIGIBLE_SAMPLE")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicy.kt:63:internal class KeyguardR446PrintOwner {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicy.kt:67:                      val target: KeyguardR446Target, val deadline: Long)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicy.kt:86:              target: KeyguardR446Target, now: Long, publicFixture: Boolean = true): Ticket? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:17:import com.fluvi.app.lockscreen.material.FluviActiveHeaderMaterialStore
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:27:internal class KeyguardR446WindowPresenter(private val service: AccessibilityService,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:38:    private var r46PublicTelemetry = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:39:    private var r47Telemetry: String? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:40:    private var r47Animated: Boolean? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:41:    private var r47FramePlayback = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:47:    fun preparePublic(display: Display, sample: KeyguardR46PublicMaterial, artifact: KeyguardShaderArtifact,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:50:        r46PublicTelemetry = prepared
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:56:    fun prepareActiveHeader(display: Display, material: FluviActiveHeaderMaterialStore.Snapshot,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:61:            r47Animated = material.motionEnabled && material.profile.animated
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:62:            r47FramePlayback = view?.setActiveHeaderFrames(material) == true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:63:            val origin = if (r47FramePlayback) "active_header_frame_package" else "active_header_semantic"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:64:            val playback = if (r47FramePlayback) "verified_frames" else "shader"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:65:            val interval = material.preparedFrames?.takeIf { r47FramePlayback }?.intervalMs
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:66:            r47Telemetry = "origin=$origin token=${material.correlation} " +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:67:                "sourceRevision=${material.profile.publisherRevision} animated=$r47Animated playback=$playback " +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:149:    fun show(token: Any, target: KeyguardR446Target, geometry: KeyguardOverlayGeometry,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:177:            if (r47FramePlayback) material.onNextPreparedFrameDrawForDiagnostic = contentDraw
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:196:    internal fun usesPreparedFrames(): Boolean = r47FramePlayback
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:197:    internal fun activeHeaderTelemetry(): String? = r47Telemetry
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:203:        if (r46PublicTelemetry) material.beginR46SampleInterval()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:204:        else r47Telemetry?.let { material.beginR46SampleInterval(it) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:205:        if (r47Animated == false) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:281:        r46PublicTelemetry = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:282:        r47Telemetry = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:283:        r47Animated = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:284:        r47FramePlayback = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448Admission.kt:4:internal object KeyguardR448Admission {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448ComparisonStore.kt:6:internal object KeyguardR448ComparisonStore {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448ComparisonStore.kt:7:    private const val PREFS = "fluvi_keyguard_r448_comparison"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448ComparisonStore.kt:11:        "startedAt=", "durationElapsedMs=", "r448DisplayRoute=", "r448SampleOnly=", "r448WaSource=",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448ComparisonStore.kt:12:        "R45_LIFECYCLE ", "R45_EVENT ", "R45_RECOVERY ", "R45_HU ",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448ComparisonStore.kt:13:        "R44_9_HU ", "R44_9_OUTCOME ", "R44_9_ADMISSION ", "R44_9_FLUVI_RECOVERY ", "R44_8_READ_BOUNDARY ", "R44_8_SYSTEM_VETO ", "R44_8_WA ", "R44_6_SAMPLE ", "attemptId=",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448ComparisonStore.kt:20:        if (route == KeyguardR448DisplayRoute.FLUVI_STREAM.name) fluviWriteFailed = failed
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448ComparisonStore.kt:47:        if (route !in KeyguardR448DisplayRoute.entries.map { it.name }) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448ComparisonStore.kt:56:        val a = prefs.getString(KeyguardR448DisplayRoute.FLUVI_STREAM.name, null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448ComparisonStore.kt:57:        val b = prefs.getString(KeyguardR448DisplayRoute.WIDGETS_ANYWHERE.name, null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448ComparisonStore.kt:59:        return "FLUVI_R44_8_AB_SUMMARY fluviWriteFailure=$fluviWriteFailed widgetsWriteFailure=$widgetsWriteFailed\nFLUVI_STREAM\n${a ?: "UNOBSERVED\n"}" +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448ComparisonStore.kt:60:            "WIDGETS_ANYWHERE\n${b ?: "UNOBSERVED\n"}END_FLUVI_R44_8_AB_SUMMARY\n"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448DisplayRoute.kt:6:internal enum class KeyguardR448DisplayRoute {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448DisplayRoute.kt:10:        fun parse(value: String?): KeyguardR448DisplayRoute =
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448DisplayRoute.kt:15:internal object KeyguardR448DisplayRouteStore {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448DisplayRoute.kt:16:    private const val PREFS = "fluvi_keyguard_r448_display_route"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448DisplayRoute.kt:19:    fun read(context: Context): KeyguardR448DisplayRoute =
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448DisplayRoute.kt:20:        if (!KeyguardOrbRenderModeStore.diagnosticBuild(context)) KeyguardR448DisplayRoute.FLUVI_STREAM
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448DisplayRoute.kt:21:        else KeyguardR448DisplayRoute.parse(context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(ROUTE, null))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448DisplayRoute.kt:23:    fun write(context: Context, route: KeyguardR448DisplayRoute): Boolean =
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448Safety.kt:6:internal object KeyguardR448Safety {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448Safety.kt:8:        val id = context.resources.getIdentifier("fluvi_r448_sample_only", "bool", context.packageName)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WakeReadBoundary.kt:4:internal object KeyguardR448WakeReadBoundary {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:14:import com.fluvi.app.lockscreen.material.FluviActiveHeaderMaterialStore
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:31:internal class KeyguardR448WidgetsAnywhereFrame(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:49:    private var r46PublicTelemetry = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:50:    private var r47Telemetry: String? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:51:    private var r47Animated: Boolean? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:52:    private var r47FramePlayback = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:53:    private val openingDelay = KeyguardR46OpeningDelay()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:59:    internal fun activeHeaderTelemetry(): String? = r47Telemetry
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:108:    fun preparePublic(owner: Owner, sample: KeyguardR46PublicMaterial,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:112:        r46PublicTelemetry = prepared
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:117:    fun prepareActiveHeader(owner: Owner, material: FluviActiveHeaderMaterialStore.Snapshot,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:122:            r47Animated = material.motionEnabled && material.profile.animated
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:123:            r47FramePlayback = view?.setActiveHeaderFrames(material) == true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:124:            val origin = if (r47FramePlayback) "active_header_frame_package" else "active_header_semantic"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:125:            val playback = if (r47FramePlayback) "verified_frames" else "shader"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:126:            val interval = material.preparedFrames?.takeIf { r47FramePlayback }?.intervalMs
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:127:            r47Telemetry = "origin=$origin token=${material.correlation} " +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:128:                "sourceRevision=${material.profile.publisherRevision} animated=$r47Animated playback=$playback " +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:222:                        if (r47FramePlayback) "FIRST_FRAME_DRAW" else "FIRST_SHADER_DRAW", at)) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:225:            if (r47FramePlayback) material.onNextPreparedFrameDrawForDiagnostic = contentDraw
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:300:        if (r46PublicTelemetry) material.beginR46SampleInterval()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:301:        else r47Telemetry?.let { material.beginR46SampleInterval(it) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:305:        if (r47Animated == false) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:422:        r46PublicTelemetry = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:423:        r47Telemetry = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:424:        r47Animated = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:425:        r47FramePlayback = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidence.kt:8:internal object KeyguardR449RestrictionEvidence {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidence.kt:9:    data class Result(val exclusions: KeyguardR448Admission.Exclusions, val reason: String,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidence.kt:10:                      val lower: List<KeyguardR45LowerWindow> = emptyList(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidence.kt:18:        if (truncated || classification.r444Gate != KeyguardR444Gate.INCOMPLETE) return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidence.kt:34:                .any { it == KeyguardR448Admission.Presence.PRESENT }) return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidence.kt:40:        val P = KeyguardR448Admission.Presence.PRESENT
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidence.kt:41:        val U = KeyguardR448Admission.Presence.UNKNOWN
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidence.kt:42:        val C = KeyguardR448Admission.Presence.CLEAR
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidence.kt:46:        val markers = ids.mapNotNull(KeyguardR44Markers::exact).toSet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidence.kt:47:        val legacy = KeyguardSurfaceClassifier.classifyDetailed(primary,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidence.kt:49:        val credential = KeyguardR44Markers.Marker.BOUNCER in markers ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidence.kt:51:        val shade = KeyguardR44Markers.Marker.SHADE in markers ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidence.kt:52:            KeyguardR44Markers.Marker.QUICK_SETTINGS in markers || legacy.surface == KeyguardSurface.SHADE
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidence.kt:75:        val result = KeyguardR448Admission.Exclusions(at, value(credential), value(shade), value(foreign), value(power))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidence.kt:92:            .take(8).map { KeyguardR45LowerWindow(it.windowId, it.displayId, requireNotNull(it.packageName)) }.toList()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidence.kt:96:        val privateSurface = if (covered) KeyguardR44SurfaceClassifier.classify(primary,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:4:internal data class KeyguardR449AdmissionObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:8:    val exclusions: KeyguardR448Admission.Exclusions, val reason: String,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:9:    val decision: KeyguardR448Admission.Decision, val issueAt: Long?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:10:    val domain: KeyguardR448Admission.Domain = KeyguardR448Admission.Domain.PUBLIC_SAMPLE,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:15:internal data class KeyguardR449RecoveryObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:21:internal data class KeyguardR448FrameObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:22:    val context: KeyguardDiagnosticContext, val owner: KeyguardR448WidgetsAnywhereFrame.Owner,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:27:internal data class KeyguardR448FrameTrace(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:28:    val owner: KeyguardR448WidgetsAnywhereFrame.Owner,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:38:internal data class KeyguardR448BoundaryObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:41:    val startedForArm: Boolean, val decision: KeyguardR448WakeReadBoundary.Decision,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:44:internal data class KeyguardR448WorkerObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:52:internal data class KeyguardR448SystemVeto(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:66:internal data class KeyguardR445IndexCall(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:74:internal data class KeyguardR446Observation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:82:    val handoff: KeyguardR447Disposition = KeyguardR447Disposition.UNOBSERVED,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:83:    val order: KeyguardFirstAuthorizedOrb.SampleOrder? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:92:    fun retireOnce(at: Long, reason: String, hide: Long?, release: Long?, error: String?): KeyguardR446Observation =
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:99:internal data class KeyguardR443CandidateObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:104:internal data class KeyguardR443WindowObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:109:internal data class KeyguardR444WindowObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:115:internal data class KeyguardR44ReadObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:133:    val host: KeyguardR44Witness?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:134:    val content: KeyguardR44Witness?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:155:    val firstCandidate: KeyguardR44Markers.Marker? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:156:    val firstCarrier: KeyguardR44Markers.Carrier? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:159:    val r443Windows: List<KeyguardR443WindowObservation> = emptyList(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:160:    val r443Candidates: List<KeyguardR443CandidateObservation> = emptyList(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:161:    val appliedGate: KeyguardR444Gate = KeyguardR444Gate.UNOBSERVED,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:168:    val r444Windows: List<KeyguardR444WindowObservation> = emptyList(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:171:    val r445IndexCalls: List<KeyguardR445IndexCall> = emptyList(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:174:internal data class KeyguardR442HandoffObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:187:internal data class KeyguardR443BoundaryObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:7:internal object KeyguardR44Markers {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:41:internal data class KeyguardR44Witness(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:42:    val marker: KeyguardR44Markers.Marker,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:43:    val carrier: KeyguardR44Markers.Carrier,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:47:internal data class KeyguardR44WindowEvidence(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:50:    val host: KeyguardR44Witness?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:51:    val content: KeyguardR44Witness?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:71:    val firstCandidate: KeyguardR44Markers.Marker? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:72:    val firstCarrier: KeyguardR44Markers.Carrier? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:74:    val r443Candidates: List<KeyguardR443CandidateObservation> = emptyList(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:81:    val r445IndexCalls: List<KeyguardR445IndexCall> = emptyList(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:84:internal object KeyguardR44SurfaceClassifier {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:95:        val legacy = KeyguardSurfaceClassifier.classifyDetailed(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:102:        val r44Restrictions = systemIds.mapNotNull(KeyguardR44Markers::exact).toSet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:103:        if (KeyguardR44Markers.Marker.BOUNCER in r44Restrictions) return KeyguardSurfaceClassification(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:104:            KeyguardSurface.CREDENTIAL, KeyguardSurfaceReason.CREDENTIAL_MARKER, legacy.markers, KeyguardR444Gate.RESTRICTION)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:105:        if (KeyguardR44Markers.Marker.SHADE in r44Restrictions ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:106:            KeyguardR44Markers.Marker.QUICK_SETTINGS in r44Restrictions) return KeyguardSurfaceClassification(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:107:            KeyguardSurface.SHADE, KeyguardSurfaceReason.SHADE_MARKER, legacy.markers, KeyguardR444Gate.RESTRICTION)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:111:            legacy.surface == KeyguardSurface.OCCLUDED) return legacy.copy(r444Gate = KeyguardR444Gate.RESTRICTION)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:112:        if (unavailableRoot || walkTruncated) return legacy.copy(r444Gate = KeyguardR444Gate.INCOMPLETE)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:116:            KeyguardSurface.UNKNOWN, KeyguardSurfaceReason.WALK_TRUNCATED, legacy.markers, KeyguardR444Gate.INCOMPLETE)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:121:                KeyguardSurfaceReason.WALK_TRUNCATED, legacy.markers, KeyguardR444Gate.INCOMPLETE)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:131:                    KeyguardSurfaceReason.FOREIGN_ABOVE, legacy.markers, KeyguardR444Gate.COVER_VETO)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:133:            return legacy.copy(r444Gate = KeyguardR444Gate.LEGACY)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:135:        if (!syntheticTrial) return legacy.copy(r444Gate = KeyguardR444Gate.LEGACY)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:143:        if (hosts.size != 1) return fallback.copy(r444Gate = KeyguardR444Gate.NO_HOST)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:146:        val content = evidence.content ?: return fallback.copy(r444Gate = KeyguardR444Gate.NO_CONTENT)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:148:            evidence.host?.ordinal == content.ordinal) return fallback.copy(r444Gate = KeyguardR444Gate.INVALID_PAIR)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:149:        if (content.marker != KeyguardR44Markers.Marker.DEVICE_ENTRY &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:150:            content.marker != KeyguardR44Markers.Marker.LARGE_CLOCK &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:151:            content.marker != KeyguardR44Markers.Marker.SMALL_CLOCK &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:153:                content.marker == KeyguardR44Markers.Marker.CLOCK_SWITCH &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:154:                content.carrier == KeyguardR44Markers.Carrier.VIEW_ID))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:155:            return fallback.copy(r444Gate = KeyguardR444Gate.INVALID_PAIR)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:160:                KeyguardSurfaceReason.FOREIGN_ABOVE, legacy.markers, KeyguardR444Gate.COVER_VETO)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceEvidence.kt:163:            KeyguardSurfaceReason.MAIN_CONFIRMED, legacy.markers.copy(main = 1), KeyguardR444Gate.ACCEPTED)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:8:internal class KeyguardR44ExtraBudget {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:30:internal class KeyguardR44TreeReader(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:35:    private val budget: KeyguardR44ExtraBudget,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:36:    private val deferred: KeyguardR443Inventory? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:44:    private var host: KeyguardR44Witness? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:45:    private var content: KeyguardR44Witness? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:67:    private var firstCandidate: KeyguardR44Markers.Marker? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:68:    private var firstCarrier: KeyguardR44Markers.Carrier? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:73:    private val facts = arrayOfNulls<MutableList<Pair<KeyguardR44Markers.Marker, KeyguardR44Markers.Carrier>>>(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:82:    private var indexedContent: KeyguardR44Witness? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:84:    private var indexedCalls: List<KeyguardR445IndexCall> = emptyList()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:93:    private fun verifiedContent(marker: KeyguardR44Markers.Marker, carrier: KeyguardR44Markers.Carrier,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:95:        KeyguardR44Markers.Marker.DEVICE_ENTRY -> genuineDeviceEntryResource && carrier == KeyguardR44Markers.Carrier.VIEW_ID
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:96:        KeyguardR44Markers.Marker.CLOCK_SWITCH -> expanded && genuineClockResource && carrier == KeyguardR44Markers.Carrier.VIEW_ID
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:97:        KeyguardR44Markers.Marker.SMALL_CLOCK -> !actualClockId || genuineSmallClockResource
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:98:        KeyguardR44Markers.Marker.LARGE_CLOCK -> !actualClockId || genuineLargeClockResource
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:123:            remainingMs = (KeyguardR44ExtraBudget.MAX_ELAPSED_MS - budget.elapsedMs).coerceAtLeast(0)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:155:    private fun addFact(ordinal: Int, marker: KeyguardR44Markers.Marker, carrier: KeyguardR44Markers.Carrier) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:157:            val entries = facts[ordinal] ?: mutableListOf<Pair<KeyguardR44Markers.Marker, KeyguardR44Markers.Carrier>>().also { facts[ordinal] = it }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:179:                            parent.isVisibleToUser && KeyguardR443ParentIdentity.of(parent) == parentId
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:197:        val refreshed = runCatching { node.refreshWithExtraData(KeyguardR44Markers.EXTRA, Bundle()) }.getOrDefault(false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:206:        val value = runCatching { node.extras.getCharSequence(KeyguardR44Markers.EXTRA) }.getOrNull()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:211:        val marker = KeyguardR44Markers.exact(value)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:213:            candidateDone(ordinal, "READ", if (KeyguardR44Markers.unknownMayRestrict(value,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:222:        observe(marker, KeyguardR44Markers.Carrier.EXTRA_LAZY, ordinal)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:223:        addFact(ordinal, marker, KeyguardR44Markers.Carrier.EXTRA_LAZY)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:224:        if (marker == KeyguardR44Markers.Marker.HOST) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:227:                host = KeyguardR44Witness(marker, KeyguardR44Markers.Carrier.EXTRA_LAZY, ordinal)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:232:        KeyguardR44Markers.exclusion(marker)?.let {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:243:            !hasExcludedAncestor(ordinal) && facts[ordinal]?.any { it.first == KeyguardR44Markers.Marker.HOST } == true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:248:            val item = facts[hostOrdinal]!!.first { it.first == KeyguardR44Markers.Marker.HOST }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:249:            host = KeyguardR44Witness(item.first, item.second, hostOrdinal)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:262:                it.first == KeyguardR44Markers.Marker.LARGE_CLOCK || it.first == KeyguardR44Markers.Marker.SMALL_CLOCK ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:263:                    it.first == KeyguardR44Markers.Marker.DEVICE_ENTRY || it.first == KeyguardR44Markers.Marker.CLOCK_SWITCH
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:268:                    item.second == KeyguardR44Markers.Carrier.VIEW_ID) -> rejectedUnverified++
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:271:                    content = KeyguardR44Witness(item.first, item.second, ordinal)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:279:    private fun observe(marker: KeyguardR44Markers.Marker, carrier: KeyguardR44Markers.Carrier, ordinal: Int = 0) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:280:        if (marker == KeyguardR44Markers.Marker.HOST && r444HostOrdinals != null && ordinal in 1 until r444HostOrdinals.size) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:285:            KeyguardR44Markers.Marker.HOST -> rawHost = (rawHost + 1).coerceAtMost(255)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:286:            KeyguardR44Markers.Marker.DEVICE_ENTRY -> rawEntry = (rawEntry + 1).coerceAtMost(255)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:287:            KeyguardR44Markers.Marker.LARGE_CLOCK, KeyguardR44Markers.Marker.SMALL_CLOCK,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:288:            KeyguardR44Markers.Marker.CLOCK_SWITCH ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:292:        if (firstCandidate == null && marker != KeyguardR44Markers.Marker.HOST) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:299:        val marker = KeyguardR44Markers.exact(viewId) ?: return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:300:        observe(marker, KeyguardR44Markers.Carrier.VIEW_ID)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:324:        val calls = ArrayList<KeyguardR445IndexCall>(3)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:328:            if (SystemClock.uptimeMillis() - batchStart >= KeyguardR44ExtraBudget.MAX_ELAPSED_MS) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:375:                                    val tag = current.extras.getCharSequence(KeyguardR44Markers.EXTRA)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:384:                                            viewId != null && KeyguardSurfaceClassifier.isDecisiveExclusionMarker(viewId) -> viewId
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:385:                                            KeyguardR44Markers.exact(tag)?.let(KeyguardR44Markers::exclusion) != null ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:386:                                                KeyguardR44Markers.exact(tag)?.let(KeyguardR44Markers::exclusion)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:392:                                            (tag != null && KeyguardR44Markers.exact(tag) == null &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:393:                                                KeyguardR44Markers.unknownMayRestrict(tag, true))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:424:            calls += KeyguardR445IndexCall(role, outcome, returned - start,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:426:                (SystemClock.uptimeMillis() - batchStart - KeyguardR44ExtraBudget.MAX_ELAPSED_MS).coerceAtLeast(0),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:442:                val marker = requireNotNull(KeyguardR44Markers.exact(id))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:443:                indexedContent = KeyguardR44Witness(marker, KeyguardR44Markers.Carrier.VIEW_ID, 97)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:484:            KeyguardR44Markers.exact(viewId)?.let {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:485:                observe(it, KeyguardR44Markers.Carrier.VIEW_ID)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:496:        val markers = ArrayList<Pair<KeyguardR44Markers.Marker, KeyguardR44Markers.Carrier>>(2)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:497:        val directMarker = KeyguardR44Markers.exact(viewId)?.takeIf {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:498:            expanded || it != KeyguardR44Markers.Marker.CLOCK_SWITCH
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:500:        directMarker?.let { markers += it to KeyguardR44Markers.Carrier.VIEW_ID }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:502:            KeyguardR44Markers.unknownMayRestrict(viewId, ancestor != null)) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:509:            val eager = node.extras.getCharSequence(KeyguardR44Markers.EXTRA)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:510:            val eagerMarker = KeyguardR44Markers.exact(eager)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:511:            eagerMarker?.let { markers += it to KeyguardR44Markers.Carrier.EXTRA_EAGER }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:514:                val nestedInHost = ancestor != null || markers.any { it.first == KeyguardR44Markers.Marker.HOST }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:517:                else if (KeyguardR44Markers.unknownMayRestrict(eager, nestedInHost)) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:522:            val hasDirectTag = markers.any { it.second == KeyguardR44Markers.Carrier.VIEW_ID &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:523:                it.first != KeyguardR44Markers.Marker.DEVICE_ENTRY }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:525:            val knownRestriction = markers.any { KeyguardR44Markers.exclusion(it.first) != null }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:532:                node.availableExtraData.contains(KeyguardR44Markers.EXTRA)) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:549:                    val refreshed = try { node.refreshWithExtraData(KeyguardR44Markers.EXTRA, Bundle()) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:570:                        val value = node.extras.getCharSequence(KeyguardR44Markers.EXTRA)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:573:                            val marker = KeyguardR44Markers.exact(value)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:576:                                val nestedInHost = ancestor != null || markers.any { it.first == KeyguardR44Markers.Marker.HOST }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:577:                                if (KeyguardR44Markers.unknownMayRestrict(value, nestedInHost)) complete = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:579:                            else markers += marker to KeyguardR44Markers.Carrier.EXTRA_LAZY
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:588:        val exclusions = markers.mapNotNull { KeyguardR44Markers.exclusion(it.first) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:600:            if (marker == KeyguardR44Markers.Marker.DEVICE_ENTRY ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:601:                marker == KeyguardR44Markers.Marker.LARGE_CLOCK || marker == KeyguardR44Markers.Marker.SMALL_CLOCK ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:602:                marker == KeyguardR44Markers.Marker.CLOCK_SWITCH) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:605:                    !verifiedContent(marker, carrier, actualClockId && carrier == KeyguardR44Markers.Carrier.VIEW_ID) ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:614:            val nodeHost = markers.firstOrNull { it.first == KeyguardR44Markers.Marker.HOST }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:618:                    host = KeyguardR44Witness(nodeHost.first, nodeHost.second, ordinal)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:625:                verifiedContent(it.first, it.second, actualClockId && it.second == KeyguardR44Markers.Carrier.VIEW_ID)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:628:                content = KeyguardR44Witness(candidate.first, candidate.second, ordinal)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:636:    fun finish(): KeyguardR44WindowEvidence {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:642:        return KeyguardR44WindowEvidence(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44TreeReader.kt:656:        r443Candidates = candidateMetrics.orEmpty().map { metric -> KeyguardR443CandidateObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44Trial.kt:8:internal object KeyguardR44Trial {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44Trial.kt:44:internal class KeyguardR46PublicMaterial private constructor() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44Trial.kt:45:    internal fun sceneProfile(): KeyguardMaterialProfile = KeyguardR44Trial.publicProfile()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44Trial.kt:48:        internal fun demo(): KeyguardR46PublicMaterial = KeyguardR46PublicMaterial()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:8:internal data class KeyguardR45SampleIntent(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:17:internal enum class KeyguardR45Phase {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:23:internal class KeyguardR46OpeningDelay {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:43:internal class KeyguardR45WaLifetime {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:45:    @Volatile var intent: KeyguardR45SampleIntent? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:47:    @Volatile var phase = KeyguardR45Phase.RETIRED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:54:    fun prepare(capture: String, session: Long, route: Long, action: String, circle: Boolean): KeyguardR45SampleIntent {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:55:        val next = KeyguardR45SampleIntent(++nextGeneration, capture, session, route, action, circle)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:57:        phase = KeyguardR45Phase.PREPARED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:64:        if (phase == KeyguardR45Phase.WAIT_WAKE && intent != null) return true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:65:        if (phase != KeyguardR45Phase.PREPARED || intent == null) return false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:66:        phase = KeyguardR45Phase.WAIT_WAKE
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:70:    fun screenOn(session: Long, capture: String?): KeyguardR45SampleIntent? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:72:        if (phase != KeyguardR45Phase.WAIT_WAKE || current.session != session || current.capture != capture) return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:73:        phase = KeyguardR45Phase.OPENING
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:77:    fun bind(value: KeyguardR45SampleIntent, wake: Long, material: Long): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:78:        if (intent !== value || phase != KeyguardR45Phase.OPENING || this.wake != 0L || wake <= 0L || material <= 0L) return false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:84:    fun current(value: KeyguardR45SampleIntent, wake: Long, material: Long): Boolean =
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:86:            phase != KeyguardR45Phase.RETIRED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:88:    fun attached(value: KeyguardR45SampleIntent) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:89:        if (intent === value && phase == KeyguardR45Phase.OPENING) phase = KeyguardR45Phase.ATTACHED_HIDDEN
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:91:    fun visible(value: KeyguardR45SampleIntent) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:92:        if (intent === value && phase in setOf(KeyguardR45Phase.ATTACHED_HIDDEN, KeyguardR45Phase.SUSPENDED,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:93:                KeyguardR45Phase.VISIBLE)) phase = KeyguardR45Phase.VISIBLE
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:95:    fun suspend(value: KeyguardR45SampleIntent) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:96:        if (intent === value && phase in setOf(KeyguardR45Phase.OPENING, KeyguardR45Phase.ATTACHED_HIDDEN,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:97:                KeyguardR45Phase.VISIBLE, KeyguardR45Phase.SUSPENDED)) phase = KeyguardR45Phase.SUSPENDED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:99:    fun retire() { intent = null; phase = KeyguardR45Phase.RETIRED; wake = 0L; material = 0L }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:104:internal class KeyguardR45DirectLifetime {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:107:        val route: Long, val target: KeyguardR446Target, val screenAt: Long, val expiresAt: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:111:    @Volatile var phase = KeyguardR45Phase.RETIRED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:113:    fun open(value: Lease) { lease = value; phase = KeyguardR45Phase.OPENING }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:114:    fun current(value: Lease, now: Long): Boolean = lease === value && phase != KeyguardR45Phase.RETIRED && now < value.expiresAt
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:115:    fun visible(value: Lease) { if (lease === value && phase != KeyguardR45Phase.RETIRED) phase = KeyguardR45Phase.VISIBLE }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:116:    fun suspend(value: Lease) { if (lease === value && phase != KeyguardR45Phase.RETIRED) phase = KeyguardR45Phase.SUSPENDED }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:117:    fun retire() { lease = null; phase = KeyguardR45Phase.RETIRED }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:120:internal enum class KeyguardR45IngressAction { IGNORE, REASSESS, OWN_REMOVED, TARGET_REMOVED }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:123:internal data class KeyguardR45LowerWindow(val window: Int, val display: Int, val packageName: String)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:126:internal data class KeyguardR45Observation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:146:internal data class KeyguardR45Trace(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:147:    var firstEvent: KeyguardR45Observation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:148:    var firstRecovery: KeyguardR45Observation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:149:    var terminal: KeyguardR45Observation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:172:internal object KeyguardR45IngressPolicy {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:174:               lower: List<KeyguardR45LowerWindow> = emptyList()): KeyguardR45IngressAction {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:175:        if (meta.displayId != Display.DEFAULT_DISPLAY && meta.displayId >= 0) return KeyguardR45IngressAction.IGNORE
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:176:        if (meta.displayId < 0) return KeyguardR45IngressAction.REASSESS
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:179:            if (exactOwn) return KeyguardR45IngressAction.OWN_REMOVED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:180:            if (targetWindow != null && meta.windowId == targetWindow) return KeyguardR45IngressAction.TARGET_REMOVED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:183:            return KeyguardR45IngressAction.IGNORE
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:186:            return KeyguardR45IngressAction.IGNORE
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:189:            return KeyguardR45IngressAction.IGNORE
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:190:        return KeyguardR45IngressAction.REASSESS
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR46RecordingStore.kt:16:internal object KeyguardR46RecordingStore {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR46RecordingStore.kt:17:    private const val PREFS = "fluvi_r46_recording"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR46RecordingStore.kt:18:    private val writer = Executors.newSingleThreadExecutor { r -> Thread(r, "fluvi-r46-spool").apply { isDaemon = true } }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR46RecordingStore.kt:31:    private fun dir(context: Context) = File(context.applicationContext.filesDir, "r46-recordings")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR46RecordingStore.kt:107:            line("FLUVI_R46_RECORDING_V1")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR46RecordingStore.kt:123:            output.write("bodyBytes=$bodyBytes bodySha256=$hash\nEND_FLUVI_R46_RECORDING_V1\n".toByteArray(Charsets.UTF_8))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR47PrivateAdmission.kt:6:internal object KeyguardR47PrivateAdmission {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR47PrivateAdmission.kt:8:        complete && materialCurrent && KeyguardCardVisibilityPolicy.decide(signals) == KeyguardCardVisibility.SHOW_FULL
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:34:internal data class KeyguardR447DuplicateProof(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:61:    val r447SystemBarrier: Long = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:62:    val r447Duplicate: KeyguardR447DuplicateProof? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardSystemState.kt:136:            if (previous != null) pending = pending?.copy(r447Duplicate = null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:47:internal object KeyguardWindowSnapshotReaderPolicy {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:163:        call(KeyguardWindowSnapshotReaderPolicy.activeRootPrefetchFlags(initialRootOnly, apiLevel))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:166:        call(KeyguardWindowSnapshotReaderPolicy.activeRootPrefetchFlags(strategy, apiLevel))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:181:internal class KeyguardWindowSnapshotReader(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:222:        val r44Enabled: Boolean = false,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:223:        val r44DeviceEntryResourceVerified: Boolean = false,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:225:        val r443Sample: Boolean = r44Enabled && KeyguardR44Trial.active,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:314:        val r44: KeyguardR44WindowEvidence? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:475:        val cacheClearResult = KeyguardWindowSnapshotReaderPolicy.establishFreshness(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:493:        val r44Budget = if (request.r44Enabled) KeyguardR44ExtraBudget() else null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:494:        val r443Inventory = if (r44Budget != null && request.r443Sample && !request.r443Live)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:495:            KeyguardR443Inventory(r44Budget) { authorityIsCurrent() && KeyguardR44Trial.active } else null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:496:        val deferredReaders = mutableMapOf<Int, KeyguardR44TreeReader>()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:512:        val prefetch = KeyguardWindowSnapshotReaderPolicy.batchedPrefetchFlags()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:526:        val activeCandidate = KeyguardWindowSnapshotReaderPolicy.activeCandidate(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:534:        val freshnessBoundaryEstablished = !KeyguardWindowSnapshotReaderPolicy.shouldClearCache(request.freshness) ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:536:        val canBatch = KeyguardWindowSnapshotReaderPolicy.canUseBatchedActiveRoot(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:541:        ) && KeyguardWindowSnapshotReaderPolicy.canUseCandidateWithStrictOwnAttribution(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:553:            return KeyguardWindowSnapshotReaderPolicy.cleanOpeningInventory(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:567:            KeyguardWindowSnapshotReaderPolicy.cleanOpeningInventory(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:581:                    (root.viewIdResourceName?.let { KeyguardSurfaceClassifier.isDecisiveExclusionMarker(it) } != true &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:582:                        (!request.r44Enabled || root.viewIdResourceName?.let { id ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:583:                            KeyguardR44Markers.exact(id)?.let(KeyguardR44Markers::exclusion) != null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:624:            val accepted = authorityIsCurrent() && KeyguardWindowSnapshotReaderPolicy.acceptsActiveRoot(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:634:                val next = if (!request.r44Enabled && request.r37YieldHint?.invoke() == true)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:658:                activeCandidate == null && metadata.none { it.active && !KeyguardWindowSnapshotReaderPolicy.isExactKnownOwn(it, observedOwn, request.attachGeneration) } -> "noActiveCandidate"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:660:                !KeyguardWindowSnapshotReaderPolicy.canUseCandidateWithStrictOwnAttribution(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:756:            val r44Window = if (r44Budget != null && root != null && rootPackage in SYSTEM_PACKAGES) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:760:                KeyguardR44TreeReader(window.id, verified, window.isActive,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:761:                    request.r44DeviceEntryResourceVerified, r44Budget, r443Inventory,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:781:            if (r443Inventory != null && root != null && r44Window?.isVerifiedActiveRoot() == true) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:788:            val rootNext = if (!request.r44Enabled && request.r37YieldHint?.invoke() == true && root != null &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:837:                    } else null, r43Window, r44Window,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:873:                    KeyguardR446Bounds(rect.left, rect.top, rect.right, rect.bottom)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:891:                    authorityIsCurrent() && KeyguardR44Trial.active
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:904:            val legacy = KeyguardSurfaceClassifier.classifyDetailed(snapshots,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:913:                    KeyguardR44Markers.exact(id)?.let(KeyguardR44Markers::exclusion) != null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:914:                } } && authorityIsCurrent() && KeyguardR44Trial.active
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:920:                    request.r44DeviceEntryResourceVerified
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:931:            if (!authorityIsCurrent() || !KeyguardR44Trial.active) return Result(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:938:                KeyguardSurfaceClassifier.isDecisiveExclusionMarker(it) ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:939:                    (request.r44Enabled && KeyguardR44Markers.exact(it)?.let(KeyguardR44Markers::exclusion) != null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:941:            val incompleteR44 = request.r44Enabled && snapshots.any { snap ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:981:        r44Window: KeyguardR44TreeReader?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:989:            val r44Restriction = r44Window != null &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:990:                KeyguardR44Markers.exact(id)?.let(KeyguardR44Markers::exclusion) != null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:991:            if (!decisiveReported && (KeyguardSurfaceClassifier.isDecisiveExclusionMarker(id) || r44Restriction) && authorityIsCurrent()) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:993:                r44Window?.restrictionObserved()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:998:        r44Window?.onDeferredRestriction(::recordId)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:999:        r44Window?.onOptionalTiming(observeIngressCall)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:1013:                  parent: AccessibilityNodeInfo?, r44Ancestor: Int?, r44Excluded: Boolean) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:1028:                    r44Window?.hiddenNode(node.viewIdResourceName)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:1039:                val r44Node = r44Window?.readNode(node, parent, nodeOrdinal, parentOrdinal, r44Ancestor, r44Excluded,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:1043:                r44Node?.exclusions?.forEach(::recordId)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:1044:                if (r44Node?.yieldedTo != null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:1045:                    yieldedTo = r44Node.yieldedTo
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:1050:                r443Boundary?.invoke(!decisiveReported && !truncated && r44Window?.safeToYield() != false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:1054:                    r44Window?.safeToYield() != false) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:1070:                        r44Window?.safeToYield() != false) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:1085:                            "SKIPPED_DECISIVE" else if (r44Window?.safeToYield() == false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:1086:                            "SKIPPED_R44_INCOMPLETE" else "NOT_INSTALLED"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:1135:                            r44Node?.hostAncestor ?: r44Ancestor, r44Node?.excluded ?: r44Excluded)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:1157:            if (r44Window?.isDeferred() == true) null else r44Window?.finish())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:1161:        return KeyguardWindowSnapshotReaderPolicy.isExactKnownOwn(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/FluviActiveHeaderMaterialStore.kt:16:internal object FluviActiveHeaderMaterialStore {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/FluviActiveHeaderMaterialStore.kt:57:    private val order = KeyguardR47SourceOrder()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/FluviActiveHeaderMaterialStore.kt:122:        if (raw.size !in 1..KeyguardR47FrameContract.maxFrames)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/FluviActiveHeaderMaterialStore.kt:127:        val error = KeyguardR47FrameContract.validate(animated, encoded.size, size, interval, bytes)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/FluviActiveHeaderMaterialStore.kt:146:                require(allocated <= KeyguardR47FrameContract.maxDecodedBytes)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:247:    private var r46SampleActive = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:248:    private var r46SampleStartedAt = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:249:    private var r46FirstFrameNs = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:250:    private var r46SecondFrameNs = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:251:    private var r46LastFrameNs = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:252:    private var r46FirstPhase = Float.NaN
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:253:    private var r46SecondPhase = Float.NaN
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:254:    private var r46LastDrawAt = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:255:    private var r46MaxGap = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:256:    private var r46ShaderFrames = 0
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:257:    private var r46FallbackFrames = 0
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:258:    private var r46CircleFrames = 0
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:259:    private var r47PreparedFrameDraws = 0
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:260:    private var r47FirstFrameIndex = -1
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:261:    private var r47LastFrameIndex = -1
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:262:    private var r47FrameIndexChanges = 0
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:263:    private var r47Frames: FluviActiveHeaderMaterialStore.PreparedFrames? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:264:    private var r47FrameOwner: FluviActiveHeaderMaterialStore.Snapshot? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:265:    private val r47FramePaint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:266:    private val r47FrameBounds = RectF()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:267:    private val r47FrameClip = Path()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:268:    private var r46SourceDescription = "palette=compiled_public_v1"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:271:        r46SampleActive = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:272:        r46SourceDescription = sourceDescription
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:273:        r46SampleStartedAt = SystemClock.uptimeMillis()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:274:        r46FirstFrameNs = 0L; r46SecondFrameNs = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:275:        r46LastFrameNs = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:276:        r46FirstPhase = Float.NaN; r46SecondPhase = Float.NaN
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:277:        r46LastDrawAt = 0L; r46MaxGap = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:278:        r46ShaderFrames = 0; r46FallbackFrames = 0; r46CircleFrames = 0
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:279:        r47PreparedFrameDraws = 0; r47FirstFrameIndex = -1; r47LastFrameIndex = -1; r47FrameIndexChanges = 0
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:282:    private fun r46CountDraw() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:284:        if (r46LastDrawAt > 0L) r46MaxGap = maxOf(r46MaxGap, at - r46LastDrawAt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:285:        r46LastDrawAt = at
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:286:        r46LastFrameNs = frameNanos
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:290:        if (!r46SampleActive) return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:291:        r46SampleActive = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:292:        val second = if (r46SecondFrameNs == 0L) "UNOBSERVED" else r46SecondFrameNs.toString()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:294:            r47PreparedFrameDraws > 0 && r47FrameIndexChanges == 0 -> "NO_DISTINCT_FRAME"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:295:            r47PreparedFrameDraws > 0 -> "none"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:296:            r46ShaderFrames == 0 -> "NO_SHADER_FRAME"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:297:            r46ShaderFrames == 1 -> "ONE_SHADER_FRAME"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:298:            r46SecondFrameNs == 0L -> "NO_DISTINCT_PHASE"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:301:        return "$r46SourceDescription start=$r46SampleStartedAt end=${SystemClock.uptimeMillis()} " +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:302:            "shader=$r46ShaderFrames fallback=$r46FallbackFrames circle=$r46CircleFrames " +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:303:            "preparedFrames=$r47PreparedFrameDraws firstFrameIndex=${if (r47FirstFrameIndex < 0) "UNOBSERVED" else r47FirstFrameIndex} " +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:304:            "lastFrameIndex=${if (r47LastFrameIndex < 0) "UNOBSERVED" else r47LastFrameIndex} frameIndexChanges=$r47FrameIndexChanges " +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:305:            "firstFrameNs=${if (r46FirstFrameNs == 0L) "UNOBSERVED" else r46FirstFrameNs} " +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:306:            "lastFrameNs=${if (r46LastFrameNs == 0L) "UNOBSERVED" else r46LastFrameNs} " +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:307:            "firstPhase=$r46FirstPhase secondFrameNs=$second secondPhase=$r46SecondPhase " +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:308:            "secondReason=$missingSecond maxGapMs=$r46MaxGap frameClock=choreographer"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:344:    private val r45CirclePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:345:    private var r45DiagnosticCircle = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:349:        r45DiagnosticCircle = enabled
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:380:        r47FrameBounds.set(0f, 0f, w.toFloat(), h.toFloat())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:381:        r47FrameClip.reset()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:382:        r47FrameClip.addCircle(w / 2f, h / 2f, min(w, h) / 2f, Path.Direction.CW)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:422:        r47Frames = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:423:        r47FrameOwner = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:499:    internal fun setActiveHeaderFrames(owner: FluviActiveHeaderMaterialStore.Snapshot): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:502:        if (!scene.full || !FluviActiveHeaderMaterialStore.isCurrentReference(owner) ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:506:        r47Frames = frames
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:507:        r47FrameOwner = owner
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:729:        if (r45DiagnosticCircle) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:730:            if (r46SampleActive) { r46CircleFrames++; r46CountDraw() }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:731:            drawKeyguardOrbCircle(canvas, r45CirclePaint, width, height)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:738:        val preparedFrames = r47Frames
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:740:            val owner = r47FrameOwner ?: return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:741:            if (!FluviActiveHeaderMaterialStore.isCurrentReference(owner)) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:796:        canvas: Canvas, frames: FluviActiveHeaderMaterialStore.PreparedFrames,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:798:        val index = KeyguardR47FrameContract.frameIndex(frameNanos, frames.originNanos,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:803:        canvas.clipPath(r47FrameClip)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:804:        canvas.drawBitmap(bitmap, null, r47FrameBounds, r47FramePaint)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:806:        if (r46SampleActive) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:807:            r47PreparedFrameDraws++
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:808:            r46CountDraw()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:809:            if (r47FirstFrameIndex < 0) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:810:                r47FirstFrameIndex = index
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:811:                r46FirstFrameNs = frameNanos
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:812:            } else if (r47LastFrameIndex >= 0 && r47LastFrameIndex != index) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:813:                r47FrameIndexChanges++
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:814:                if (r46SecondFrameNs == 0L) r46SecondFrameNs = frameNanos
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:816:            r47LastFrameIndex = index
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:849:        if (r46SampleActive && scene === current && alpha > 0f) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:850:            r46ShaderFrames++
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:851:            r46CountDraw()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:852:            if (r46FirstFrameNs == 0L) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:853:                r46FirstFrameNs = frameNanos; r46FirstPhase = time.phase
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:854:            } else if (r46SecondFrameNs == 0L && frameNanos != r46FirstFrameNs && time.phase != r46FirstPhase) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:855:                r46SecondFrameNs = frameNanos; r46SecondPhase = time.phase
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:882:        if (r46SampleActive) { r46FallbackFrames++; r46CountDraw() }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardR47FrameContract.kt:4:internal object KeyguardR47FrameContract {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardR47SourceOrder.kt:6:internal class KeyguardR47SourceOrder {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueueTest.kt:17:        val freshness = KeyguardInspectionFreshness().also {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueueTest.kt:410:            assertEquals(KeyguardSurface.OCCLUDED, KeyguardSurfaceClassifier.classify(listOf(main, foreign)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueueTest.kt:423:        assertEquals(KeyguardSurface.MAIN_KEYGUARD, KeyguardSurfaceClassifier.classify(listOf(main)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:7:class KeyguardCardVisibilityPolicyTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:23:        assertEquals(KeyguardCardVisibility.HIDDEN_OPT_OUT, KeyguardCardVisibilityPolicy.decide(signals(requested = false)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:24:        assertEquals(KeyguardCardVisibility.HIDDEN_DISCONNECTED, KeyguardCardVisibilityPolicy.decide(signals(connected = false)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:25:        assertEquals(KeyguardCardVisibility.HIDDEN_BEFORE_FIRST_UNLOCK, KeyguardCardVisibilityPolicy.decide(signals(unlockedSinceBoot = false)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:26:        assertEquals(KeyguardCardVisibility.HIDDEN_OTHER_DISPLAY, KeyguardCardVisibilityPolicy.decide(signals(primary = false)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:27:        assertEquals(KeyguardCardVisibility.HIDDEN_SCREEN, KeyguardCardVisibilityPolicy.decide(signals(interactive = false)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:28:        assertEquals(KeyguardCardVisibility.HIDDEN_SCREEN, KeyguardCardVisibilityPolicy.decide(signals(displayOn = false)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:29:        assertEquals(KeyguardCardVisibility.HIDDEN_UNLOCKED, KeyguardCardVisibilityPolicy.decide(signals(keyguard = false)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:33:        assertEquals(KeyguardCardVisibility.HIDDEN_CREDENTIAL, KeyguardCardVisibilityPolicy.decide(signals(surface = KeyguardSurface.CREDENTIAL, full = true)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:34:        assertEquals(KeyguardCardVisibility.HIDDEN_SHADE, KeyguardCardVisibilityPolicy.decide(signals(surface = KeyguardSurface.SHADE, full = true)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:35:        assertEquals(KeyguardCardVisibility.HIDDEN_OCCLUDED, KeyguardCardVisibilityPolicy.decide(signals(surface = KeyguardSurface.OCCLUDED, full = true)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:36:        assertEquals(KeyguardCardVisibility.HIDDEN_UNKNOWN, KeyguardCardVisibilityPolicy.decide(signals(surface = KeyguardSurface.UNKNOWN, full = true)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:40:        assertEquals(KeyguardCardVisibility.SHOW_DISCREET, KeyguardCardVisibilityPolicy.decide(signals()))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:41:        assertEquals(KeyguardCardVisibility.SHOW_FULL, KeyguardCardVisibilityPolicy.decide(signals(full = true)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:45:        val read = KeyguardSurfaceClassifier.classifyDetailed(listOf(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:51:        assertEquals(KeyguardCardVisibility.HIDDEN_UNKNOWN, KeyguardCardVisibilityPolicy.decide(signals(surface = read.surface, full = true)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:52:        assertEquals(KeyguardCardVisibility.HIDDEN_UNKNOWN, KeyguardCardVisibilityPolicy.decide(signals(surface = read.surface, full = false)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:59:        assertEquals(KeyguardSurface.CREDENTIAL, KeyguardSurfaceClassifier.classify(mainAndPin))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:60:        assertEquals(KeyguardSurface.SHADE, KeyguardSurfaceClassifier.classify(listOf(system("com.android.systemui:id/keyguard_carrier_text", "com.android.systemui:id/quick_settings_panel"))))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:61:        assertEquals(KeyguardSurface.OCCLUDED, KeyguardSurfaceClassifier.classify(listOf(system("com.android.systemui:id/keyguard_carrier_text"), KeyguardWindowSnapshot("com.android.camera", 1, 99, 0))))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:67:            KeyguardSurfaceClassifier.classify(listOf(system("com.android.systemui:id/keyguard_carrier_text"), KeyguardWindowSnapshot("com.fluvi.app", 2032, 100, 0, ownOverlay = true))),
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:162:            KeyguardSurfaceClassifier.classifyDetailed(emptyList(), unavailableRoot = true).reason,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:166:            KeyguardSurfaceClassifier.classifyDetailed(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:177:            KeyguardSurfaceClassifier.classifyDetailed(main, unavailableRoot = true).surface,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:181:            KeyguardSurfaceClassifier.classifyDetailed(main, unavailableRoot = true).reason,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:185:            KeyguardSurfaceClassifier.classifyDetailed(main, walkTruncated = true).surface,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:189:            KeyguardSurfaceClassifier.classifyDetailed(main, walkTruncated = true).reason,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardCardVisibilityPolicyTest.kt:195:            KeyguardSurfaceClassifier.classifyDetailed(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAcquisitionTest.kt:13:        KeyguardInspectionFreshness.Ticket(authority, 1L, reason)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:8:class KeyguardFirstAuthorizedOrbTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:10:    private fun proof(gate: KeyguardFirstAuthorizedOrb, request: Long = 10,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:16:        val owner = KeyguardFirstAuthorizedOrb()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:29:        val owner = KeyguardFirstAuthorizedOrb()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:45:        assertEquals(KeyguardFirstAuthorizedOrb.Intent.EMPTY_AWAITING_DISCLOSURE,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:46:            KeyguardFirstAuthorizedOrb.intent(true))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:47:        assertEquals(KeyguardFirstAuthorizedOrb.Intent.DISCREET_PREPOSTED,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:48:            KeyguardFirstAuthorizedOrb.intent(false))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:49:        val gate = KeyguardFirstAuthorizedOrb()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:59:        val gate = KeyguardFirstAuthorizedOrb(); val readScene = gate.sceneSerial()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:74:        val gate = KeyguardFirstAuthorizedOrb()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:86:        val gate = KeyguardFirstAuthorizedOrb()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:99:        val gate = KeyguardFirstAuthorizedOrb(lock)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:124:        val gate = KeyguardFirstAuthorizedOrb(lock)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:147:        val lock = Any(); val gate = KeyguardFirstAuthorizedOrb(lock); val coordinator = KeyguardOrbPresentationCoordinator(lock)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardFirstAuthorizedOrbTest.kt:167:        val gate = KeyguardFirstAuthorizedOrb(); val first = requireNotNull(proof(gate))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:6:class KeyguardInspectionFreshnessTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:14:        val freshness = KeyguardInspectionFreshness().also { it.publish(authority) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:26:        val freshness = KeyguardInspectionFreshness().also { it.publish(authority) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:41:        val failed = KeyguardWindowSnapshotReaderPolicy.establishFreshness(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:52:        val cleared = KeyguardWindowSnapshotReaderPolicy.establishFreshness(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:61:        KeyguardWindowSnapshotReaderPolicy.establishFreshness(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:68:        val freshness = KeyguardInspectionFreshness().also { it.publish(authority) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:88:        val freshness = KeyguardInspectionFreshness().also { it.publish(authority) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:112:        val freshness = KeyguardInspectionFreshness().also { it.publish(authority) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:127:        val freshness = KeyguardInspectionFreshness().also { it.publish(authority) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:136:        val freshness = KeyguardInspectionFreshness().also { it.publish(authority) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:147:        val freshness = KeyguardInspectionFreshness().also { it.publish(authority) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardInspectionFreshnessTest.kt:153:        KeyguardWindowSnapshotReaderPolicy.establishFreshness(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinatorTest.kt:33:        val lock = Any(); val c = KeyguardOrbPresentationCoordinator(lock); val proof = KeyguardFirstAuthorizedOrb(lock)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:14:        KeyguardInspectionFreshness.Ticket(authority, 1L, KeyguardWindowFreshness.LIFECYCLE_BOUNDARY)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:37:        val empty = KeyguardWindowSnapshotReaderPolicy.activeCandidate(emptyList(), null, owner.attachGeneration)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:39:        assertFalse(KeyguardWindowSnapshotReaderPolicy.canUseBatchedActiveRoot(35, true, false, true))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:40:        assertFalse(KeyguardWindowSnapshotReaderPolicy.canUseBatchedActiveRoot(35, false, true, true))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:61:        assertEquals(36, KeyguardWindowSnapshotReaderPolicy.activeRootPrefetchFlags(KeyguardActiveRootStrategy.R18_INITIAL_HYBRID, 34))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:62:        assertEquals(4, KeyguardWindowSnapshotReaderPolicy.activeRootPrefetchFlags(KeyguardActiveRootStrategy.R18_INITIAL_HYBRID, 35))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:63:        assertEquals(36, KeyguardWindowSnapshotReaderPolicy.activeRootPrefetchFlags(KeyguardActiveRootStrategy.STOCK, 35))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:64:        assertEquals(0, KeyguardWindowSnapshotReaderPolicy.activeRootPrefetchFlags(KeyguardActiveRootStrategy.R15_HISTORICAL_ZERO, 35))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:70:        assertFalse(KeyguardWindowSnapshotReaderPolicy.canUseCandidateWithStrictOwnAttribution(true, overlay))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:71:        assertTrue(KeyguardWindowSnapshotReaderPolicy.canUseCandidateWithStrictOwnAttribution(true, system))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:72:        assertTrue(KeyguardWindowSnapshotReaderPolicy.canUseCandidateWithStrictOwnAttribution(false, overlay))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:79:        decisive.forEach { assertTrue(it, KeyguardSurfaceClassifier.isDecisiveExclusionMarker(it)) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:80:        assertFalse(KeyguardSurfaceClassifier.isDecisiveExclusionMarker("com.android.systemui:id/keyguard_clock_switch"))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:81:        assertFalse(KeyguardSurfaceClassifier.isDecisiveExclusionMarker("com.example:id/ordinary"))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:89:            KeyguardSurfaceClassifier.classifyDetailed(listOf(system, otherFluvi)).surface)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:91:            KeyguardSurfaceClassifier.classifyDetailed(listOf(system, otherFluvi), strictOwnAttribution = true).surface)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR18FirstAcquisitionTest.kt:94:            KeyguardSurfaceClassifier.classifyDetailed(listOf(system, exactOwn), strictOwnAttribution = true).surface)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:115:            if (checkNotNull(Platform.nodes[real]).advertised) listOf(KeyguardR44Markers.EXTRA) else emptyList()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:133:            if (!node.refreshSucceeds || key != KeyguardR44Markers.EXTRA || arguments == null) return false
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:151:    private lateinit var reader: KeyguardWindowSnapshotReader
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:157:        reader = KeyguardWindowSnapshotReader(service, "com.fluvi.app")
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:172:        val baseline = reader.read(KeyguardWindowSnapshotReader.Request(null, 5), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:174:        val originalClass = KeyguardSurfaceClassifier.classifyDetailed(baseline.snapshots)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:178:        val observed = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r43Evidence = evidence), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:181:        assertEquals(originalClass, KeyguardSurfaceClassifier.classifyDetailed(observed.snapshots))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:190:    @Test fun r44ExplicitLockscreenAndDeviceEntryNeedAnOrdinarySurfaceDecision() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:198:        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:199:            r44Enabled = true, r44DeviceEntryResourceVerified = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:204:        val decision = KeyguardR44SurfaceClassifier.classify(read.snapshots,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:216:        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:217:            r44Enabled = true, r44DeviceEntryResourceVerified = false), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:222:        assertEquals(KeyguardR44Markers.Marker.DEVICE_ENTRY, evidence.firstCandidate)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:223:        assertEquals(KeyguardSurface.UNKNOWN, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:225:        assertEquals(KeyguardSurface.UNKNOWN, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:235:                if (restrictive) extras.putCharSequence(KeyguardR44Markers.EXTRA, "scene:shade")
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:244:            val request = KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:249:                assertEquals(KeyguardSurface.SHADE, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:262:        checkNotNull(Platform.nodes[unknown]).extras.putCharSequence(KeyguardR44Markers.EXTRA, "overlay:unrecognised")
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:269:        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:273:        assertEquals(KeyguardSurface.UNKNOWN, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:287:        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:298:        checkNotNull(Platform.nodes[unknown]).extras.putCharSequence(KeyguardR44Markers.EXTRA, "overlay:unrecognised")
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:306:        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:336:        KeyguardR44Trial.set(true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:338:            val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:339:                r44Enabled = true, r44DeviceEntryResourceVerified = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:340:            KeyguardR44SurfaceClassifier.classify(read.snapshots, read.rootUnavailable,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:342:        } finally { KeyguardR44Trial.set(false, false) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:379:        KeyguardR44Trial.set(false, false)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:380:        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:382:        assertEquals(KeyguardSurface.UNKNOWN, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:399:        KeyguardR44Trial.set(true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:401:            val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:405:            assertEquals(KeyguardSurface.UNKNOWN, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:407:        } finally { KeyguardR44Trial.set(false, false) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:429:        KeyguardR44Trial.set(true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:431:            val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:434:            assertEquals(KeyguardSurface.UNKNOWN, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:437:        } finally { KeyguardR44Trial.set(false, false) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:459:            KeyguardR44Trial.set(true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:461:                val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:465:                assertEquals(KeyguardSurface.SHADE, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:467:            } finally { KeyguardR44Trial.set(false, false) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:489:        KeyguardR44Trial.set(true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:491:            val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:493:            assertEquals(KeyguardSurface.SHADE, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:495:        } finally { KeyguardR44Trial.set(false, false) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:508:        KeyguardR44Trial.set(true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:510:            val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:512:            assertFalse(KeyguardR44SurfaceClassifier.classify(read.snapshots,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:514:        } finally { KeyguardR44Trial.set(false, false) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:525:        KeyguardR44Trial.set(true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:527:            val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:529:            assertEquals(KeyguardSurface.CREDENTIAL, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:531:        } finally { KeyguardR44Trial.set(false, false) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:542:            KeyguardR44Trial.set(true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:544:                val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:546:                val decision = KeyguardR44SurfaceClassifier.classify(read.snapshots,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:549:            } finally { KeyguardR44Trial.set(false, false) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:565:            KeyguardR44Trial.set(true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:567:                val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:569:                val result = KeyguardR44SurfaceClassifier.classify(read.snapshots,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:572:            } finally { KeyguardR44Trial.set(false, false) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:591:            KeyguardR44Trial.set(true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:593:                val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:595:                val result = KeyguardR44SurfaceClassifier.classify(read.snapshots,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:598:            } finally { KeyguardR44Trial.set(false, false) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:610:        KeyguardR44Trial.set(true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:612:            val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:613:            assertEquals(KeyguardSurface.MAIN_KEYGUARD, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:615:        } finally { KeyguardR44Trial.set(false, false) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:618:    @Test fun r44EagerAndLazyTagsTraverseTheActualReader() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:626:            else rootData.extras.putCharSequence(KeyguardR44Markers.EXTRA, "element:lockscreen")
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:629:            val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:630:                r44Enabled = true, r44DeviceEntryResourceVerified = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:631:            assertEquals(KeyguardSurface.MAIN_KEYGUARD, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:634:            assertEquals(if (lazy) KeyguardR44Markers.Carrier.EXTRA_LAZY else KeyguardR44Markers.Carrier.EXTRA_EAGER,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:639:    @Test fun r44BudgetOrStaleExtraNeverCreatesAuthority() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:649:        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:650:            r44Enabled = true, r44DeviceEntryResourceVerified = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:653:        assertEquals(KeyguardSurface.UNKNOWN, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:663:        val stale = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:664:            r44Enabled = true, r44DeviceEntryResourceVerified = true), { current })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:668:    @Test fun r44ReaderRejectsSpoofedSiblingAndSameNodePairs() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:672:            val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:673:                r44Enabled = true, r44DeviceEntryResourceVerified = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:674:            return KeyguardR44SurfaceClassifier.classify(read.snapshots, read.rootUnavailable,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:678:        checkNotNull(Platform.nodes[same]).extras.putCharSequence(KeyguardR44Markers.EXTRA, "element:LargeClock")
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:692:    @Test fun r44ReaderDeniesShadeAfterAnOtherwiseValidPair() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:699:        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:700:            r44Enabled = true, r44DeviceEntryResourceVerified = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:701:        assertEquals(KeyguardSurface.SHADE, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:705:    @Test fun r44UnsupportedOrFailedAdvertisedExtraFailsClosed() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:719:            val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:720:                r44Enabled = true, r44DeviceEntryResourceVerified = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:721:            assertEquals(KeyguardSurface.UNKNOWN, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:730:    @Test fun r44InspectedUnrelatedTagIsCountedWithoutBeingARestriction() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:734:        checkNotNull(Platform.nodes[unrelated]).extras.putCharSequence(KeyguardR44Markers.EXTRA, "component:example")
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:738:        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:739:            r44Enabled = true, r44DeviceEntryResourceVerified = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:742:        assertEquals(KeyguardSurface.MAIN_KEYGUARD, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:746:    @Test fun r44NestedClockSceneDoesNotDisqualifyTheVerifiedHost() {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:750:        checkNotNull(Platform.nodes[localScene]).extras.putCharSequence(KeyguardR44Markers.EXTRA, "scene:localClock")
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:755:        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:756:        assertEquals(KeyguardSurface.MAIN_KEYGUARD, KeyguardR44SurfaceClassifier.classify(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:786:        fun request(wrongToken: Boolean = false): KeyguardWindowSnapshotReader.Request =
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:787:            KeyguardWindowSnapshotReader.Request(null, 5,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:812:        val fresh = reader.read(KeyguardWindowSnapshotReader.Request(null, 5), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:816:        assertEquals(KeyguardSurface.MAIN_KEYGUARD, KeyguardSurfaceClassifier.classify(fresh.snapshots))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:858:        assertEquals(KeyguardSurface.SHADE, KeyguardSurfaceClassifier.classify(result.snapshots))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:877:        assertEquals(KeyguardSurface.OCCLUDED, KeyguardSurfaceClassifier.classify(ambiguous.snapshots))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:908:            KeyguardSurfaceClassifier.classifyDetailed(result.snapshots,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:924:        assertEquals(KeyguardSurface.UNKNOWN, KeyguardSurfaceClassifier.classifyDetailed(result.snapshots,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:942:        assertEquals(KeyguardSurface.UNKNOWN, KeyguardSurfaceClassifier.classifyDetailed(result.snapshots,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:988:        assertEquals(KeyguardSurface.UNKNOWN, KeyguardSurfaceClassifier.classifyDetailed(result.snapshots,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1016:        val fresh = reader.read(KeyguardWindowSnapshotReader.Request(null, 5), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1019:        assertEquals(KeyguardSurface.MAIN_KEYGUARD, KeyguardSurfaceClassifier.classify(fresh.snapshots))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1041:        val readingB = KeyguardWindowSnapshotReader.Request(null, 5,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1071:        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1081:        assertEquals(KeyguardSurface.SHADE, KeyguardSurfaceClassifier.classify(read.snapshots))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1096:        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1101:        assertEquals(KeyguardSurface.UNKNOWN, KeyguardSurfaceClassifier.classifyDetailed(read.snapshots,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1116:        val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1126:    private fun r445EmptyOrFailedQuery(fail: Boolean): Pair<KeyguardWindowSnapshotReader.Result, Int> {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1129:        checkNotNull(Platform.nodes[host]).extras.putCharSequence(KeyguardR44Markers.EXTRA, "element:lockscreen")
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1134:        KeyguardR44Trial.set(true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1136:            reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1139:        } finally { KeyguardR44Trial.set(false, false) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1171:        fun sample(kind: String): Pair<KeyguardWindowSnapshotReader.Result, Int> {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1175:            checkNotNull(Platform.nodes[host]).extras.putCharSequence(KeyguardR44Markers.EXTRA, "element:lockscreen")
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1204:            KeyguardR44Trial.set(true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1206:                val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1209:            } finally { KeyguardR44Trial.set(false, false) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1215:        assertEquals(KeyguardR44Markers.Marker.SMALL_CLOCK, positive.first.snapshots.single().r44?.content?.marker)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1244:        checkNotNull(Platform.nodes[host]).extras.putCharSequence(KeyguardR44Markers.EXTRA, "element:lockscreen")
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1251:        KeyguardR44Trial.set(true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1253:            val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1257:            assertEquals(KeyguardSurface.CREDENTIAL, KeyguardR44SurfaceClassifier.classify(read.snapshots,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1259:        } finally { KeyguardR44Trial.set(false, false) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1265:        checkNotNull(Platform.nodes[host]).extras.putCharSequence(KeyguardR44Markers.EXTRA, "element:lockscreen")
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1271:            extras.putCharSequence(KeyguardR44Markers.EXTRA, "overlay:bouncer")
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1280:        KeyguardR44Trial.set(true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1282:            val read = reader.read(KeyguardWindowSnapshotReader.Request(null, 5, r44Enabled = true,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1288:            assertEquals(KeyguardSurface.CREDENTIAL, KeyguardR44SurfaceClassifier.classify(read.snapshots,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1290:        } finally { KeyguardR44Trial.set(false, false) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1296:        val result = reader.read(KeyguardWindowSnapshotReader.Request(null, 5), { true })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR22ReaderHandoffTest.kt:1299:            KeyguardSurfaceClassifier.classifyDetailed(result.snapshots,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR441ExtraBudgetTest.kt:9:class KeyguardR441ExtraBudgetTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR441ExtraBudgetTest.kt:11:        val budget = KeyguardR44ExtraBudget()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR441ExtraBudgetTest.kt:19:        val budget = KeyguardR44ExtraBudget()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR441ExtraBudgetTest.kt:24:        val slow = KeyguardR44ExtraBudget()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR441ExtraBudgetTest.kt:32:        val budget = KeyguardR44ExtraBudget()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR441ExtraBudgetTest.kt:41:        val budget = KeyguardR44ExtraBudget()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR441ExtraBudgetTest.kt:49:        assertTrue(KeyguardR44Markers.unknownMayRestrict("overlay:future", true))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR441ExtraBudgetTest.kt:50:        assertTrue(KeyguardR44Markers.unknownMayRestrict("scene:future", false))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR441ExtraBudgetTest.kt:51:        assertFalse(KeyguardR44Markers.unknownMayRestrict("element:clock-decoration", true))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR441ExtraBudgetTest.kt:58:            assertTrue(KeyguardR441RestrictionIngress.mustWithdraw(37, event, ownWindow = false, attached = true))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR441ExtraBudgetTest.kt:59:            assertFalse(KeyguardR441RestrictionIngress.mustWithdraw(35, event, ownWindow = false, attached = true))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR441ExtraBudgetTest.kt:60:            assertFalse(KeyguardR441RestrictionIngress.mustWithdraw(37, event, ownWindow = true, attached = true))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR441ExtraBudgetTest.kt:61:            assertFalse(KeyguardR441RestrictionIngress.mustWithdraw(37, event, ownWindow = false, attached = false))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR441ExtraBudgetTest.kt:62:            assertFalse(KeyguardR441RestrictionIngress.mustWithdraw(37, event.copy(displayId = 2), ownWindow = false, attached = true))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR442YieldPolicyTest.kt:7:class KeyguardR442YieldPolicyTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR442YieldPolicyTest.kt:21:        KeyguardR442YieldPolicy.permits(api, orb, screen, session, started, authority, active, old, next)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR444ProfileOwnerTest.kt:6:class KeyguardR444ProfileOwnerTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR444ProfileOwnerTest.kt:16:        val owner = KeyguardR444ProfileOwner(2, { flags }, { value ->
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR444ProfileOwnerTest.kt:43:        assertEquals(KeyguardR444ProfileOwner.Kind.STANDARD_ALREADY_INCLUDED, f.owner.snapshot.kind)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR444ProfileOwnerTest.kt:51:        assertEquals(KeyguardR444ProfileOwner.Kind.ERROR, f.owner.snapshot.kind)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR444ProfileOwnerTest.kt:63:        val owner = KeyguardR444ProfileOwner(2,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR444ProfileOwnerTest.kt:96:        val replacement = KeyguardR444ProfileOwner(2, { f.flags }, { f.flags = it; true },
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR445FirstFrameTest.kt:8:class KeyguardR445FirstFrameTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR445FirstFrameTest.kt:10:        val budget = KeyguardR445WakeBudget()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR445FirstFrameTest.kt:18:        assertEquals(KeyguardR44Markers.Marker.SMALL_CLOCK,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR445FirstFrameTest.kt:19:            KeyguardR44Markers.exact("com.android.systemui:id/lockscreen_clock_view"))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR445FirstFrameTest.kt:23:        assertEquals(KeyguardR44Markers.Marker.LARGE_CLOCK,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR445FirstFrameTest.kt:24:            KeyguardR44Markers.exact("com.android.systemui:id/lockscreen_clock_view_large"))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR445FirstFrameTest.kt:28:        val host = KeyguardR44Witness(KeyguardR44Markers.Marker.HOST,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR445FirstFrameTest.kt:29:            KeyguardR44Markers.Carrier.EXTRA_LAZY, 2)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR445FirstFrameTest.kt:30:        val hostEvidence = KeyguardR44WindowEvidence(true, true, host, null, false, true, false)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR445FirstFrameTest.kt:31:        val sensorEvidence = KeyguardR44WindowEvidence(true, false, null, null, false, true, false)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR445FirstFrameTest.kt:38:            val decision = KeyguardR44SurfaceClassifier.classify(listOf(hostWindow, sensorWindow),
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR445FirstFrameTest.kt:41:            assertEquals(KeyguardR444Gate.NO_CONTENT, decision.r444Gate)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:7:class KeyguardR446PrintPolicyTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:8:    private val bounds = KeyguardR446Bounds(0, 0, 1080, 2400)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:12:            r44 = KeyguardR44WindowEvidence(verified, active, null, null, false, true, false),
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:15:        KeyguardSurfaceReason.NO_MAIN_MARKER, r444Gate = KeyguardR444Gate.NO_CONTENT)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:22:                val result = KeyguardR446PrintPolicy.evaluate(windows, missingPositive, false, false)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:29:        assertNotNull(KeyguardR446PrintPolicy.evaluate(listOf(host),
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:30:            missingPositive.copy(r444Gate = KeyguardR444Gate.NO_HOST), false, false).target)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:31:        assertNotNull(KeyguardR446PrintPolicy.evaluate(listOf(host, window(88, 9, false)),
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:32:            missingPositive.copy(r444Gate = KeyguardR444Gate.COVER_VETO), false, false).target)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:41:            missingPositive.copy(r444Gate = KeyguardR444Gate.INCOMPLETE),
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:43:        bad.forEach { assertNull(KeyguardR446PrintPolicy.evaluate(listOf(host), it, false, false).target) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:44:        assertNull(KeyguardR446PrintPolicy.evaluate(listOf(host), missingPositive, true, false).target)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:45:        assertNull(KeyguardR446PrintPolicy.evaluate(listOf(host), missingPositive, false, true).target)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:46:        assertNull(KeyguardR446PrintPolicy.evaluate(listOf(host, window(3, 8, false, owner = "other")), missingPositive, false, false).target)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:47:        assertNull(KeyguardR446PrintPolicy.evaluate(listOf(host, window(3, 8, false, verified = false)), missingPositive, false, false).target)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:48:        assertNull(KeyguardR446PrintPolicy.evaluate(listOf(host, window(3, 8, false, focused = true)), missingPositive, false, false).target)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:49:        assertNull(KeyguardR446PrintPolicy.evaluate(listOf(host, window(3, 8, false), window(4, 9, false)), missingPositive, false, false).target)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:53:        val owner = KeyguardR446PrintOwner()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:59:        val target = KeyguardR446Target(7, 0, bounds)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:74:        val owner = KeyguardR446PrintOwner()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicyTest.kt:78:        val target = KeyguardR446Target(7, 0, bounds)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR447ReadOrderTest.kt:9:class KeyguardR447ReadOrderTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR447ReadOrderTest.kt:11:        val owner = KeyguardFirstAuthorizedOrb()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR447ReadOrderTest.kt:15:        owner.requireRead(43, KeyguardFirstAuthorizedOrb.SampleOffer.INTERNAL_DUPLICATE)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR447ReadOrderTest.kt:17:        assertEquals(KeyguardFirstAuthorizedOrb.SampleResult.REDUNDANT_OFFER_ACCEPTED,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR447ReadOrderTest.kt:22:        val owner = KeyguardFirstAuthorizedOrb()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR447ReadOrderTest.kt:27:        owner.requireRead(44, KeyguardFirstAuthorizedOrb.SampleOffer.INTERNAL_DUPLICATE)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR447ReadOrderTest.kt:28:        assertEquals(KeyguardFirstAuthorizedOrb.SampleResult.NEWER_BARRIER_REQUIRED,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR447ReadOrderTest.kt:31:        assertEquals(KeyguardFirstAuthorizedOrb.SampleResult.NEWER_COMPLETED,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR447ReadOrderTest.kt:36:        val owner = KeyguardFirstAuthorizedOrb()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR447ReadOrderTest.kt:41:        owner.requireRead(43, KeyguardFirstAuthorizedOrb.SampleOffer.INTERNAL_DUPLICATE)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR447ReadOrderTest.kt:42:        assertEquals(KeyguardFirstAuthorizedOrb.SampleResult.SCENE_CHANGED,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448AdmissionTest.kt:6:class KeyguardR448AdmissionTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448AdmissionTest.kt:7:    private val stamp = KeyguardR448Admission.Stamp(2, 3, 4)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448AdmissionTest.kt:8:    private val clear = KeyguardR448Admission.Presence.CLEAR
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448AdmissionTest.kt:9:    private val present = KeyguardR448Admission.Presence.PRESENT
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448AdmissionTest.kt:10:    private val unknown = KeyguardR448Admission.Presence.UNKNOWN
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448AdmissionTest.kt:12:    private val exclusions = KeyguardR448Admission.Exclusions(103, clear, clear, clear, clear)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448AdmissionTest.kt:13:    private val base = KeyguardR448Admission.Inputs(stamp, 100, system, exclusions,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448AdmissionTest.kt:14:        KeyguardR448Admission.Domain.PUBLIC_SAMPLE, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448AdmissionTest.kt:15:    private fun decide(inputs: KeyguardR448Admission.Inputs = base, current: KeyguardR448Admission.Stamp = stamp) =
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448AdmissionTest.kt:16:        KeyguardR448Admission.evaluate(inputs, current, 110)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448AdmissionTest.kt:19:        assertEquals(KeyguardR448Admission.Decision.ALLOW, decide())
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448AdmissionTest.kt:25:        restrictions.forEach { assertEquals(KeyguardR448Admission.Decision.RESTRICTED, decide(base.copy(exclusions = it))) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448AdmissionTest.kt:29:        assertEquals(KeyguardR448Admission.Decision.EXCLUSION_UNKNOWN,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448AdmissionTest.kt:31:        assertEquals(KeyguardR448Admission.Decision.EXCLUSION_UNKNOWN,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448AdmissionTest.kt:33:        assertEquals(KeyguardR448Admission.Decision.SYSTEM_UNKNOWN,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448AdmissionTest.kt:35:        assertEquals(KeyguardR448Admission.Decision.OWNER_CHANGED, decide(current = stamp.copy(wake = 5)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448AdmissionTest.kt:39:        val private = base.copy(domain = KeyguardR448Admission.Domain.PRIVATE)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448AdmissionTest.kt:40:        assertEquals(KeyguardR448Admission.Decision.MATERIAL_UNAUTHORIZED,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448AdmissionTest.kt:42:        assertEquals(KeyguardR448Admission.Decision.MATERIAL_UNAUTHORIZED,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448ComparisonStoreTest.kt:7:class KeyguardR448ComparisonStoreTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448ComparisonStoreTest.kt:9:        val text = KeyguardR448ComparisonStore.summarize("capture-a",
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448ComparisonStoreTest.kt:10:            "R44_8_SYSTEM_VETO request=9\nPRIVATE_SCREEN_TEXT\nR44_6_SAMPLE wake=1\n")
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448ComparisonStoreTest.kt:12:        assertTrue(text.contains("R44_8_SYSTEM_VETO request=9"))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448ComparisonStoreTest.kt:13:        assertTrue(text.contains("R44_6_SAMPLE wake=1"))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448ComparisonStoreTest.kt:18:        val text = KeyguardR448ComparisonStore.summarize("capture-b",
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448ComparisonStoreTest.kt:19:            (1..100).joinToString("\n") { "R44_6_SAMPLE wake=$it value=" + "x".repeat(500) })
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448DisplayRouteTest.kt:6:class KeyguardR448DisplayRouteTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448DisplayRouteTest.kt:8:        assertEquals(KeyguardR448DisplayRoute.FLUVI_STREAM, KeyguardR448DisplayRoute.parse(null))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448DisplayRouteTest.kt:9:        assertEquals(KeyguardR448DisplayRoute.FLUVI_STREAM, KeyguardR448DisplayRoute.parse("unknown"))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448DisplayRouteTest.kt:13:        KeyguardR448DisplayRoute.entries.forEach { assertEquals(it, KeyguardR448DisplayRoute.parse(it.name)) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448WakeReadBoundaryTest.kt:6:class KeyguardR448WakeReadBoundaryTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448WakeReadBoundaryTest.kt:7:    private val current = KeyguardR448WakeReadBoundary.Work(1, true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448WakeReadBoundaryTest.kt:10:        assertEquals(KeyguardR448WakeReadBoundary.Decision.OFFER,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448WakeReadBoundaryTest.kt:11:            KeyguardR448WakeReadBoundary.decide(current, null, 1, false))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448WakeReadBoundaryTest.kt:15:        assertEquals(KeyguardR448WakeReadBoundary.Decision.ACTIVE_NOT_STARTED,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448WakeReadBoundaryTest.kt:16:            KeyguardR448WakeReadBoundary.decide(current, null, null, false))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448WakeReadBoundaryTest.kt:17:        assertEquals(KeyguardR448WakeReadBoundary.Decision.ACTIVE_AFTER_BOUNDARY,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448WakeReadBoundaryTest.kt:18:            KeyguardR448WakeReadBoundary.decide(current, null, 1, true))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448WakeReadBoundaryTest.kt:22:        val pending = KeyguardR448WakeReadBoundary.Work(2, true, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448WakeReadBoundaryTest.kt:23:        assertEquals(KeyguardR448WakeReadBoundary.Decision.CURRENT_PENDING,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448WakeReadBoundaryTest.kt:24:            KeyguardR448WakeReadBoundary.decide(current, pending, 1, false))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448WakeReadBoundaryTest.kt:28:        val oldCapture = KeyguardR448WakeReadBoundary.Work(1, true, false)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448WakeReadBoundaryTest.kt:29:        val oldWake = KeyguardR448WakeReadBoundary.Work(2, false, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448WakeReadBoundaryTest.kt:30:        assertEquals(KeyguardR448WakeReadBoundary.Decision.OFFER,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448WakeReadBoundaryTest.kt:31:            KeyguardR448WakeReadBoundary.decide(oldCapture, oldWake, 1, true))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448WakeReadBoundaryTest.kt:32:        assertEquals(KeyguardR448WakeReadBoundary.Decision.OFFER,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR448WakeReadBoundaryTest.kt:33:            KeyguardR448WakeReadBoundary.decide(null, oldWake, null, false))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidenceTest.kt:8:class KeyguardR449RestrictionEvidenceTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidenceTest.kt:12:        r44 = KeyguardR44WindowEvidence(true, true, null, null, false, complete, false))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidenceTest.kt:15:        val result = KeyguardR449RestrictionEvidence.fromInventory(listOf(host()), 50, false, false)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidenceTest.kt:17:        assertEquals(KeyguardR448Admission.Presence.CLEAR, result.exclusions.credential)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidenceTest.kt:18:        assertEquals(KeyguardR448Admission.Presence.CLEAR, result.exclusions.shade)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidenceTest.kt:19:        assertEquals(KeyguardR448Admission.Presence.CLEAR, result.exclusions.foreign)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidenceTest.kt:20:        assertEquals(KeyguardR448Admission.Presence.CLEAR, result.exclusions.powerMenu)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidenceTest.kt:26:            val result = KeyguardR449RestrictionEvidence.fromInventory(windows, 50, false, false)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidenceTest.kt:27:            assertEquals(KeyguardR448Admission.Presence.UNKNOWN, result.exclusions.foreign)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidenceTest.kt:32:        val pin = KeyguardR449RestrictionEvidence.fromInventory(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidenceTest.kt:34:        assertEquals(KeyguardR448Admission.Presence.PRESENT, pin.exclusions.credential)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidenceTest.kt:35:        val shade = KeyguardR449RestrictionEvidence.fromInventory(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidenceTest.kt:37:        assertEquals(KeyguardR448Admission.Presence.PRESENT, shade.exclusions.shade)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidenceTest.kt:38:        val power = KeyguardR449RestrictionEvidence.fromInventory(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidenceTest.kt:40:        assertEquals(KeyguardR448Admission.Presence.PRESENT, power.exclusions.powerMenu)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidenceTest.kt:45:        val result = KeyguardR449RestrictionEvidence.fromInventory(listOf(host(), other), 50, false, false)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidenceTest.kt:46:        assertEquals(KeyguardR448Admission.Presence.PRESENT, result.exclusions.foreign)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidenceTest.kt:51:        val result = KeyguardR449RestrictionEvidence.fromInventory(listOf(host(), behind), 50, false, false)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidenceTest.kt:52:        assertEquals(KeyguardR448Admission.Presence.CLEAR, result.exclusions.foreign)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidenceTest.kt:53:        val equalLayer = KeyguardR449RestrictionEvidence.fromInventory(listOf(host(), behind.copy(layer = 1)), 50, false, false)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidenceTest.kt:54:        assertEquals(KeyguardR448Admission.Presence.PRESENT, equalLayer.exclusions.foreign)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidenceTest.kt:60:            r444Gate = KeyguardR444Gate.INCOMPLETE)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidenceTest.kt:61:        assertNotNull(KeyguardR449RestrictionEvidence.unresolvedUpper(listOf(host(), upper), incomplete, false))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidenceTest.kt:62:        assertNull(KeyguardR449RestrictionEvidence.unresolvedUpper(listOf(host(), upper), incomplete, true))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidenceTest.kt:63:        assertNull(KeyguardR449RestrictionEvidence.unresolvedUpper(listOf(host(), upper, upper.copy(windowId = 9)), incomplete, false))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidenceTest.kt:64:        assertNull(KeyguardR449RestrictionEvidence.unresolvedUpper(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidenceTest.kt:66:        assertNull(KeyguardR449RestrictionEvidence.unresolvedUpper(listOf(host(), upper.copy(layer = 0)), incomplete, false))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:8:class KeyguardR44SurfaceClassifierTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:9:    private val host = KeyguardR44Witness(KeyguardR44Markers.Marker.HOST, KeyguardR44Markers.Carrier.VIEW_ID, 1)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:10:    private val entry = KeyguardR44Witness(KeyguardR44Markers.Marker.DEVICE_ENTRY, KeyguardR44Markers.Carrier.VIEW_ID, 2)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:12:        host: KeyguardR44Witness? = this.host, content: KeyguardR44Witness? = entry,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:15:    ) = KeyguardR44WindowEvidence(verified, active, host, content, below, complete, foreign, passive)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:18:                       e: KeyguardR44WindowEvidence? = evidence()) = KeyguardWindowSnapshot(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:23:        KeyguardR44SurfaceClassifier.classify(windows.toList(), unavailable, truncated, false, trial).surface
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:60:        val missing = KeyguardR44SurfaceClassifier.classify(listOf(legacyOnly), false, false,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:63:        assertEquals(KeyguardR444Gate.NO_CONTENT, missing.r444Gate)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:64:        val covered = KeyguardR44SurfaceClassifier.classify(listOf(window(),
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:68:        assertEquals(KeyguardR444Gate.COVER_VETO, covered.r444Gate)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:89:        assertEquals(KeyguardR44Markers.Marker.HOST, KeyguardR44Markers.exact("element:lockscreen"))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:90:        assertEquals(KeyguardR44Markers.Marker.LARGE_CLOCK, KeyguardR44Markers.exact("element:LargeClock"))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:91:        assertEquals(null, KeyguardR44Markers.exact("element:largeclock"))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:92:        assertEquals(null, KeyguardR44Markers.exact("com.fake:id/element:lockscreen"))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR44SurfaceClassifierTest.kt:93:        assertEquals(null, KeyguardR44Markers.exact("com.android.systemui:id/udfps_view"))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR45PresentationTest.kt:7:class KeyguardR45PresentationTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR45PresentationTest.kt:12:        assertEquals(KeyguardR45IngressAction.IGNORE, KeyguardR45IngressPolicy.decide(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR45PresentationTest.kt:14:        assertEquals(KeyguardR45IngressAction.IGNORE, KeyguardR45IngressPolicy.decide(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR45PresentationTest.kt:20:        assertEquals(KeyguardR45IngressAction.REASSESS, KeyguardR45IngressPolicy.decide(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR45PresentationTest.kt:22:        assertEquals(KeyguardR45IngressAction.REASSESS, KeyguardR45IngressPolicy.decide(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR45PresentationTest.kt:25:        assertEquals(KeyguardR45IngressAction.REASSESS, KeyguardR45IngressPolicy.decide(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR45PresentationTest.kt:31:        assertEquals(KeyguardR45IngressAction.OWN_REMOVED,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR45PresentationTest.kt:32:            KeyguardR45IngressPolicy.decide(removed, exactOwn = true, targetWindow = null))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR45PresentationTest.kt:33:        assertEquals(KeyguardR45IngressAction.TARGET_REMOVED,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR45PresentationTest.kt:34:            KeyguardR45IngressPolicy.decide(removed, exactOwn = false, targetWindow = 42))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR45PresentationTest.kt:35:        assertEquals(KeyguardR45IngressAction.REASSESS,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR45PresentationTest.kt:36:            KeyguardR45IngressPolicy.decide(removed, exactOwn = false, targetWindow = 43))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR45PresentationTest.kt:40:        val lower = listOf(KeyguardR45LowerWindow(42, 0, "example.background"))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR45PresentationTest.kt:42:        assertEquals(KeyguardR45IngressAction.IGNORE, KeyguardR45IngressPolicy.decide(content, false, null, lower))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR45PresentationTest.kt:43:        assertEquals(KeyguardR45IngressAction.REASSESS,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR45PresentationTest.kt:44:            KeyguardR45IngressPolicy.decide(content.copy(windowId = 43), false, null, lower))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR45PresentationTest.kt:45:        assertEquals(KeyguardR45IngressAction.REASSESS,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR45PresentationTest.kt:46:            KeyguardR45IngressPolicy.decide(content.copy(eventType = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED), false, null, lower))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR45PresentationTest.kt:50:        val owner = KeyguardR45WaLifetime()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR45PresentationTest.kt:60:        assertEquals(KeyguardR45Phase.SUSPENDED, owner.phase)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR45PresentationTest.kt:66:        assertEquals("a late reveal cannot change a newer owner", KeyguardR45Phase.PREPARED, owner.phase)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR45PresentationTest.kt:70:        val owner = KeyguardR45DirectLifetime()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR45PresentationTest.kt:71:        val target = KeyguardR446Target(7, 0, KeyguardR446Bounds(0, 0, 100, 100))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR45PresentationTest.kt:72:        val first = KeyguardR45DirectLifetime.Lease(Any(), "capture", 1, 2, 3, target, 100, 500)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR46OpeningDelayTest.kt:7:class KeyguardR46OpeningDelayTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR46OpeningDelayTest.kt:9:        val owner = KeyguardR46OpeningDelay()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR46PublicMaterialTest.kt:9:class KeyguardR46PublicMaterialTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR46PublicMaterialTest.kt:11:        val first = KeyguardR46PublicMaterial.demo().sceneProfile()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR46PublicMaterialTest.kt:17:        val second = KeyguardR46PublicMaterial.demo().sceneProfile()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR46PublicMaterialTest.kt:25:        KeyguardR44Trial.set(true, false)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR46PublicMaterialTest.kt:26:        try { assertFalse(KeyguardR44Trial.settings(KeyguardCardSettings(showFinancialDetails = true)).showFinancialDetails) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR46PublicMaterialTest.kt:27:        finally { KeyguardR44Trial.set(false, false) }
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR47PrivateAdmissionTest.kt:7:class KeyguardR47PrivateAdmissionTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR47PrivateAdmissionTest.kt:16:        assertTrue(KeyguardR47PrivateAdmission.allows(main, complete = true, materialCurrent = true))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR47PrivateAdmissionTest.kt:17:        assertFalse(KeyguardR47PrivateAdmission.allows(main, complete = false, materialCurrent = true))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR47PrivateAdmissionTest.kt:18:        assertFalse(KeyguardR47PrivateAdmission.allows(main, complete = true, materialCurrent = false))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR47PrivateAdmissionTest.kt:19:        assertFalse(KeyguardR47PrivateAdmission.allows(main.copy(showFinancialDetails = false), true, true))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR47PrivateAdmissionTest.kt:20:        assertFalse(KeyguardR47PrivateAdmission.allows(main.copy(requested = false), true, true))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR47PrivateAdmissionTest.kt:26:            assertFalse(KeyguardR47PrivateAdmission.allows(main.copy(surface = surface), true, true))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR47PrivateAdmissionTest.kt:28:        assertFalse(KeyguardR47PrivateAdmission.allows(main.copy(keyguardLocked = false), true, true))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR47PrivateAdmissionTest.kt:29:        assertFalse(KeyguardR47PrivateAdmission.allows(main.copy(userUnlocked = false), true, true))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardR47PrivateAdmissionTest.kt:30:        assertFalse(KeyguardR47PrivateAdmission.allows(main.copy(displayOn = false, displayOff = true), true, true))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardSystemStateSamplerTest.kt:221:        assertEquals(KeyguardCardVisibility.HIDDEN_UNKNOWN, KeyguardCardVisibilityPolicy.decide(unknown))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardSystemStateSamplerTest.kt:223:            KeyguardCardVisibilityPolicy.decide(unknown.copy(systemStateAvailable = false)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardSystemStateSamplerTest.kt:238:        assertEquals(KeyguardCardVisibility.HIDDEN_UNLOCKED, KeyguardCardVisibilityPolicy.decide(admitted))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:11:class KeyguardWindowSnapshotReaderPolicyTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:14:        val selected = KeyguardWindowSnapshotReaderPolicy.activeCandidate(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:20:            KeyguardWindowSnapshotReaderPolicy.acceptsActiveRoot(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:26:            KeyguardWindowSnapshotReaderPolicy.acceptsActiveRoot(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:37:        assertNull(KeyguardWindowSnapshotReaderPolicy.activeCandidate(listOf(own), identity, 9L))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:40:        assertEquals(own, KeyguardWindowSnapshotReaderPolicy.activeCandidate(listOf(own), identity, 10L))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:48:        assertNull(KeyguardWindowSnapshotReaderPolicy.activeCandidate(listOf(first, second), null, 1L))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:49:        assertNull(KeyguardWindowSnapshotReaderPolicy.activeCandidate(listOf(secondary), null, 1L))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:55:            KeyguardWindowSnapshotReaderPolicy.acceptsActiveRoot(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:64:            KeyguardWindowSnapshotReaderPolicy.shouldClearCache(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:69:            KeyguardWindowSnapshotReaderPolicy.shouldClearCache(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:74:            KeyguardWindowSnapshotReaderPolicy.shouldClearCache(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:79:            KeyguardWindowSnapshotReaderPolicy.shouldClearCache(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:89:            KeyguardWindowSnapshotReaderPolicy.canUseBatchedActiveRoot(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:97:            KeyguardWindowSnapshotReaderPolicy.canUseBatchedActiveRoot(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:105:            KeyguardWindowSnapshotReaderPolicy.canUseBatchedActiveRoot(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:116:            KeyguardWindowSnapshotReaderPolicy.canUseBatchedActiveRoot(
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:126:        val flags = KeyguardWindowSnapshotReaderPolicy.batchedPrefetchFlags(apiLevel = 35)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:133:        assertEquals(0, KeyguardWindowSnapshotReaderPolicy.batchedPrefetchFlags(apiLevel = 32))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:137:        val childFlags = KeyguardWindowSnapshotReaderPolicy.batchedPrefetchFlags(apiLevel = 35)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:139:        assertEquals(0, KeyguardWindowSnapshotReaderPolicy.activeRootPrefetchFlags(true, apiLevel = 35))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:140:        assertEquals(childFlags, KeyguardWindowSnapshotReaderPolicy.activeRootPrefetchFlags(false, apiLevel = 35))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:141:        assertEquals(0, KeyguardWindowSnapshotReaderPolicy.activeRootPrefetchFlags(true, apiLevel = 32))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:175:        assertTrue(KeyguardWindowSnapshotReaderPolicy.cleanOpeningInventory(true, listOf(system), null, 7, system))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:176:        assertTrue(KeyguardWindowSnapshotReaderPolicy.cleanOpeningInventory(true, listOf(system, own), identity, 7, system))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:177:        assertFalse(KeyguardWindowSnapshotReaderPolicy.cleanOpeningInventory(false, listOf(system), null, 7, system))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:178:        assertFalse(KeyguardWindowSnapshotReaderPolicy.cleanOpeningInventory(true, listOf(system, own), null, 7, system))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:179:        assertFalse(KeyguardWindowSnapshotReaderPolicy.cleanOpeningInventory(true, listOf(system, own), identity, 8, system))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:180:        assertFalse(KeyguardWindowSnapshotReaderPolicy.cleanOpeningInventory(true,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:182:        assertFalse(KeyguardWindowSnapshotReaderPolicy.cleanOpeningInventory(true, listOf(own), null, 7, own))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReaderPolicyTest.kt:183:        assertFalse(KeyguardWindowSnapshotReaderPolicy.cleanOpeningInventory(true, emptyList(), null, 7, null))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR47ActiveFrameStoreTest.kt:16:class KeyguardR47ActiveFrameStoreTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR47ActiveFrameStoreTest.kt:19:    private val session = "r47-frame-store-$epoch"
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR47ActiveFrameStoreTest.kt:25:        assertTrue(FluviActiveHeaderMaterialStore.bindPublisher(epoch, 1, session))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR47ActiveFrameStoreTest.kt:29:        FluviActiveHeaderMaterialStore.invalidate()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR47ActiveFrameStoreTest.kt:36:        val admitted = FluviActiveHeaderMaterialStore.admitFrames(context, payload(first, 1, listOf(bytes, bytes, bytes)), epoch)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR47ActiveFrameStoreTest.kt:44:        assertFalse(FluviActiveHeaderMaterialStore.commitFrames(context, request, bitmaps))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR47ActiveFrameStoreTest.kt:47:        assertNull(FluviActiveHeaderMaterialStore.applicable(context)?.preparedFrames)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR47ActiveFrameStoreTest.kt:48:        assertEquals("staleSource", FluviActiveHeaderMaterialStore.admitFrames(context,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR47ActiveFrameStoreTest.kt:54:        val starter = FluviActiveHeaderMaterialStore.admitFrames(context, payload(token, 1, listOf(byteArrayOf(1))), epoch)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR47ActiveFrameStoreTest.kt:56:        val admitted = FluviActiveHeaderMaterialStore.admitFrames(context,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR47ActiveFrameStoreTest.kt:58:        assertNull(FluviActiveHeaderMaterialStore.decodeFrames(requireNotNull(admitted.request)))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR47ActiveFrameStoreTest.kt:61:        assertEquals("sourceUnavailable", FluviActiveHeaderMaterialStore.admitFrames(context,
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR47ActiveFrameStoreTest.kt:85:        val receipt = FluviActiveHeaderMaterialStore.publish(context, values, epoch, true)
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR47FrameContractTest.kt:7:class KeyguardR47FrameContractTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR47FrameContractTest.kt:9:        assertEquals("incompleteSequence", KeyguardR47FrameContract.validate(true, 1, 32, 32, 100))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR47FrameContractTest.kt:10:        assertEquals("incompleteSequence", KeyguardR47FrameContract.validate(false, 3, 32, 32, 100))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR47FrameContractTest.kt:11:        assertEquals("byteBudgetExceeded", KeyguardR47FrameContract.validate(true, 175, 128, 32, 100))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR47FrameContractTest.kt:12:        assertEquals("byteBudgetExceeded", KeyguardR47FrameContract.validate(true, 3, 32, 32, 2_097_153))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR47FrameContractTest.kt:13:        assertEquals("invalidGeometry", KeyguardR47FrameContract.validate(true, 3, 32, 0, 100))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR47FrameContractTest.kt:14:        assertNull(KeyguardR47FrameContract.validate(true, 3, 32, 32, 100))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR47FrameContractTest.kt:15:        assertNull(KeyguardR47FrameContract.validate(false, 1, 128, 1000, 100))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR47FrameContractTest.kt:20:        assertEquals(0, KeyguardR47FrameContract.frameIndex(origin - 1, origin, 100, 3))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR47FrameContractTest.kt:21:        assertEquals(1, KeyguardR47FrameContract.frameIndex(origin + 100_000_000L, origin, 100, 3))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR47FrameContractTest.kt:22:        assertEquals(2, KeyguardR47FrameContract.frameIndex(origin + 500_000_000L, origin, 100, 3))
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR47SourceOrderTest.kt:6:class KeyguardR47SourceOrderTest {
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR47SourceOrderTest.kt:8:        val order = KeyguardR47SourceOrder()
android/app/src/test/kotlin/com/fluvi/app/lockscreen/material/KeyguardR47SourceOrderTest.kt:19:        val order = KeyguardR47SourceOrder()

```
