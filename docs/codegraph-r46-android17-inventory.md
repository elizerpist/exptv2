# R46 exact-source public recording and route inventory

Application source: `9a283a723d4dcbfcdb7550aeb11d9bc9f8042d91`

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
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:133:        val clear = KeyguardR448Admission.Presence.CLEAR
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:134:        val exclusions = KeyguardR448Admission.Exclusions(7028, clear, clear, clear, clear)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:135:        val admission = KeyguardR449AdmissionObservation(owner, 5, 3, 8, 4, "ONE_WAKE", 7010,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:137:            exclusions, "CLEAR", KeyguardR448Admission.Decision.ALLOW, 7029)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:138:        KeyguardCardDiagnostics.recordR449Admission(admission)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:139:        val waOutput = KeyguardR446Observation(owner, 6990, 7, 0, "NOT_REQUIRED", "CLEAR", "WA_SHADER_DRAW",
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:141:        KeyguardCardDiagnostics.recordR446(waOutput)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:142:        KeyguardCardDiagnostics.recordR45(KeyguardR45Observation(owner, "WIDGETS_ANYWHERE", "INTENT", 7005, detail = "ORB"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:143:        KeyguardCardDiagnostics.recordR45(KeyguardR45Observation(owner, "WIDGETS_ANYWHERE", "INGRESS", 7071,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:146:        KeyguardCardDiagnostics.recordR45(KeyguardR45Observation(owner, "WIDGETS_ANYWHERE", "RECOVERY", 7075,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:151:            KeyguardCardDiagnostics.recordR45(KeyguardR45Observation(owner, "WIDGETS_ANYWHERE", stage, at, detail = "test"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:155:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:156:        val read = report.lineSequence().single { it.startsWith("R44_8_READ_BOUNDARY ") }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:157:        val gate = report.lineSequence().single { it.startsWith("R44_8_SYSTEM_VETO ") }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:158:        val wa = report.lineSequence().single { it.startsWith("R44_8_WA ") }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:159:        val admitted = report.lineSequence().single { it.startsWith("R44_9_ADMISSION ") }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:160:        val sample = report.lineSequence().single { it.startsWith("R44_6_SAMPLE ") }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:161:        val life = report.lineSequence().single { it.startsWith("R45_LIFECYCLE ") }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:162:        val event = report.lineSequence().single { it.startsWith("R45_EVENT ") }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:163:        val recovery = report.lineSequence().single { it.startsWith("R45_RECOVERY ") }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:180:        KeyguardCardDiagnostics.recordR448SystemVeto(veto.copy(requestId = 101))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:181:        KeyguardCardDiagnostics.recordR449Admission(admission.copy(reason = "LATE"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:182:        KeyguardCardDiagnostics.recordR45(KeyguardR45Observation(owner, "WIDGETS_ANYWHERE", "TERMINAL", 9999, detail = "LATE"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:189:    private fun r447LatestDecision(mode: String) {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:190:        KeyguardCardDiagnostics.startCapture(context, "r447-pressure", "profile", mode,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:195:        val first = KeyguardR446Observation(owner, 990, 3, 40,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:198:        KeyguardCardDiagnostics.recordR446(first)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:199:        KeyguardCardDiagnostics.recordR446(first.copy(request = 43, eligibility = "SCENE_CHANGED"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:200:        KeyguardCardDiagnostics.recordR446(first.copy(request = 44, eligibility = "NEWER_COMPLETED"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:201:        KeyguardCardDiagnostics.recordR446(first.copy(request = 45, eligibility = "NEWER_BARRIER_REQUIRED"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:204:        val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:205:        val row = frozen.lineSequence().single { it.startsWith("R44_6_SAMPLE ") }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:210:        KeyguardCardDiagnostics.recordR446(first.copy(request = 46, eligibility = "LATE_CALLBACK"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:214:    @Test fun r447ProgressAndTerminalRemainWithTheirOriginalRequest() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:215:        KeyguardCardDiagnostics.startCapture(context, "r447-order", "profile", "FULL",
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:220:        val first = KeyguardR446Observation(owner, 6990, 7, 40, "UNKNOWN/NO_MAIN_MARKER",
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:222:            armGeneration = 2, decisionOrdinal = 1, handoff = KeyguardR447Disposition.NEWER_BARRIER_REQUIRED)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:223:        val issued = first.copy(request = 44, decisionOrdinal = 2, handoff = KeyguardR447Disposition.ISSUED,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:225:        KeyguardCardDiagnostics.recordR446(first)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:226:        KeyguardCardDiagnostics.recordR446(issued)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:227:        KeyguardCardDiagnostics.recordR446(first.copy(request = 45, decisionOrdinal = 3,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:228:            handoff = KeyguardR447Disposition.ARM_MISMATCH))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:230:        KeyguardCardDiagnostics.recordR446(laterFrame)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:231:        KeyguardCardDiagnostics.recordR446(laterFrame.retireOnce(7090, "duplicate", null, null, null))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:234:        KeyguardCardDiagnostics.recordR446(first.copy(request = 99, decisionOrdinal = 99, armGeneration = 1))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:238:        KeyguardCardDiagnostics.recordR446(first.copy(context = unarmed, wake = 8, request = 0,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:240:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:241:        val rows = report.lineSequence().filter { it.startsWith("R44_6_SAMPLE ") }.toList()
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:254:    @Test fun r447TerminalBeforeAnyWakeSurvivesFreezeAndLateCleanup() {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:255:        KeyguardCardDiagnostics.startCapture(context, "r447-arm", "profile", "LIGHT",
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:258:        KeyguardCardDiagnostics.recordR447ArmTerminal(capture, 4, 111, "serviceLost")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:259:        KeyguardCardDiagnostics.recordR447ArmTerminal(capture, 4, 222, "duplicateCleanup")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:260:        val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:261:        assertTrue(frozen, frozen.contains("R44_7_ARM generation=4 terminal=111/serviceLost"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:262:        KeyguardCardDiagnostics.recordR447ArmTerminal(capture, 4, 333, "lateCallback")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:267:        KeyguardCardDiagnostics.startCapture(context, "r446-pressure", "profile", mode,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:269:        var first: KeyguardR446Observation? = null
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:275:            val missing = KeyguardR446Observation(owner, base - 10, wake, base + 1,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:279:            KeyguardCardDiagnostics.recordR446(missing)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:285:            KeyguardCardDiagnostics.recordR446(shown)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:292:        val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:294:        assertEquals(6, frozen.lineSequence().count { it.startsWith("R44_6_SAMPLE ") })
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:301:        KeyguardCardDiagnostics.recordR446(checkNotNull(first).copy(backend = "LATE_CALLBACK"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:306:        KeyguardCardDiagnostics.startCapture(context, "r444-reason", "profile", "LIGHT", r442ExpectedSession = 9444)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:312:            KeyguardCardDiagnostics.recordR44(KeyguardR44ReadObservation(owner, base + 20, wake, wake,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:315:                KeyguardR44Witness(KeyguardR44Markers.Marker.HOST, KeyguardR44Markers.Carrier.EXTRA_LAZY, 20),
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:318:                r443Candidates = if (failed > 0) listOf(KeyguardR443CandidateObservation(
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:323:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:334:        KeyguardCardDiagnostics.startCapture(context, "r444-pressure", "profile", mode, r442ExpectedSession = 9445)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:344:            val candidates = (1..7).map { n -> KeyguardR443CandidateObservation(969, n, "HOST", n,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:346:            KeyguardCardDiagnostics.recordR44(KeyguardR44ReadObservation(owner, base + 30, wake, wake,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:350:                KeyguardR44Witness(KeyguardR44Markers.Marker.HOST, KeyguardR44Markers.Carrier.EXTRA_LAZY, 20),
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:353:                appliedGate = if (empty) KeyguardR444Gate.INCOMPLETE else KeyguardR444Gate.NO_CONTENT,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:358:                    KeyguardR445IndexCall("SMALL", "EMPTY", 12, 123, 0),
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:359:                    KeyguardR445IndexCall("LARGE", "INELIGIBLE", 13, 136, 0),
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:360:                    KeyguardR445IndexCall("ENTRY", "EMPTY", 17, 150, 3)),
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:361:                r444Windows = listOf(KeyguardR444WindowObservation(972, 0, 3, false, false,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:364:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:366:        assertEquals(8, report.lineSequence().count { it.startsWith("R44_4_HU ") })
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:367:        assertEquals(3, report.lineSequence().count { it.startsWith("R44_WAKE ") && it.contains("firstPostRead=missing") })
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:372:        assertEquals(5, report.lineSequence().count { it.startsWith("R44_5_INDEX ") })
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:373:        assertEquals(15, report.lineSequence().count { it.startsWith("R44_5_ID ") })
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:378:        KeyguardCardDiagnostics.startCapture(context, "r442-fixture", "profile", "LIGHT", r442ExpectedSession = 945)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:382:        KeyguardCardDiagnostics.recordR442Handoff(KeyguardR442HandoffObservation(
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:385:            KeyguardCardDiagnostics.recordR44(KeyguardR44ReadObservation(owner, id, 1, 1,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:391:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:394:        val handoff = report.lineSequence().single { it.startsWith("R44_2_HANDOFF ") }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:401:    private fun r44EvidencePressure(mode: String) {
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:402:        KeyguardCardDiagnostics.startCapture(context, "r44-fixture", "profile", mode, r442ExpectedSession = 944)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:411:            fun record(request: Long, start: Long, verdict: KeyguardSurface) = KeyguardCardDiagnostics.recordR44(
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:412:                KeyguardR44ReadObservation(owner, request, wake, wake + 50, start, start + 5,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:416:                    KeyguardR44Witness(KeyguardR44Markers.Marker.HOST, KeyguardR44Markers.Carrier.VIEW_ID, 1),
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:417:                    KeyguardR44Witness(KeyguardR44Markers.Marker.DEVICE_ENTRY, KeyguardR44Markers.Carrier.EXTRA_EAGER, 2),
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:423:                    firstCandidate = KeyguardR44Markers.Marker.DEVICE_ENTRY,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:424:                    firstCarrier = KeyguardR44Markers.Carrier.VIEW_ID, cover = "VETO_UNKNOWN_OR_COVER", receipt = "armed",
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:425:                    r443Windows = listOf(KeyguardR443WindowObservation(10, 7, 7, 0, true)),
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:426:                    r443Candidates = (1..7).map { n -> KeyguardR443CandidateObservation(
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:429:            KeyguardCardDiagnostics.recordR442Handoff(KeyguardR442HandoffObservation(
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:432:            KeyguardCardDiagnostics.recordR443Boundary(KeyguardR443BoundaryObservation(
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:449:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:452:            val row = report.lineSequence().single { it.startsWith("R44_WAKE ") && it.contains("wake=$wake ") }
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:455:            assertTrue(report, report.contains("R44_2_HANDOFF old=${wake * 1000 + 1} next=${wake * 1000 + 2} "))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:456:            assertTrue(report, report.contains("R44_2_EVIDENCE req=${wake * 1000 + 2} lookup=VERIFIED"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:457:            assertTrue(report, report.contains("R44_3_JEL req=${wake * 1000 + 2} window=10 ordinal=7"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:458:            assertTrue(report, report.contains("R44_3_BOUNDARY old=${wake * 1000 + 1}"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:461:        assertEquals(6, report.lineSequence().count { it.startsWith("R44_HU ") })
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:464:        KeyguardCardDiagnostics.recordR44(KeyguardR44ReadObservation(checkNotNull(firstOwner), 9999, 0, null,
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:478:                KeyguardCardDiagnostics.startCapture(context, "r26-pressure", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:530:                val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:571:        KeyguardCardDiagnostics.startCapture(context, "r25-fixture", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:599:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:608:        KeyguardCardDiagnostics.startCapture(context, "r25-new", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:611:        val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:619:        KeyguardCardDiagnostics.startCapture(context, "r22-4", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:638:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:649:        KeyguardCardDiagnostics.startCapture(context, "r22-4-new", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:653:        val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:661:        KeyguardCardDiagnostics.startCapture(context, "r22-2", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:676:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:696:        KeyguardCardDiagnostics.startCapture(context, "r22-1", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:748:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:760:        KeyguardCardDiagnostics.startCapture(context, "new", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:763:        val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:781:            KeyguardCardDiagnostics.startCapture(context, "r31", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:821:            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:832:            KeyguardCardDiagnostics.startCapture(context, "r31-next", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:835:            val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:853:            KeyguardCardDiagnostics.startCapture(context, "r32", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:878:            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:892:            KeyguardCardDiagnostics.startCapture(context, "r32-next", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:897:            val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:915:            KeyguardCardDiagnostics.startCapture(context, "r34", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:942:            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:957:            KeyguardCardDiagnostics.startCapture(context, "r34-next", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:961:            assertFalse((KeyguardCardDiagnostics.freezeCapture(context)["report"] as String).contains("reservation=704"))
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:975:        KeyguardCardDiagnostics.startCapture(context, "r18-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1017:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1036:        KeyguardCardDiagnostics.startCapture(context, "r18-new", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1040:        val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1048:        KeyguardCardDiagnostics.startCapture(context, "r19-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1094:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1118:            KeyguardCardDiagnostics.startCapture(context, "r22-token-pressure", "profile", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1144:            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1169:            KeyguardCardDiagnostics.startCapture(context, "r21-pressure", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1289:            val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1354:            KeyguardCardDiagnostics.startCapture(context, "r20-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1381:            val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1406:            KeyguardCardDiagnostics.startCapture(context, "r13-pressure", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1431:            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1443:        KeyguardCardDiagnostics.startCapture(context, "r13-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1462:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1474:        KeyguardCardDiagnostics.startCapture(context, "r13-new", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1477:        val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1482:        KeyguardCardDiagnostics.startCapture(context, "r12-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1509:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1530:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1542:        val frozen = KeyguardCardDiagnostics.freezeCapture(context)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1555:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1557:        val before = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1572:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1581:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1589:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1621:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1638:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1675:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1691:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug", "FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1723:        val frozen = KeyguardCardDiagnostics.freezeCapture(context)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1746:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug", "FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1779:        val frozen = KeyguardCardDiagnostics.freezeCapture(context)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1792:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1825:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1839:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1851:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1856:        KeyguardCardDiagnostics.startCapture(context, "old-sha", "debug")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1860:        KeyguardCardDiagnostics.startCapture(context, "new-sha", "debug")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1870:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1876:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1896:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1902:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1943:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1950:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug", "FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1973:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1981:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1990:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:1999:        KeyguardCardDiagnostics.startCapture(context, "test-sha", "debug")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2000:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2014:        KeyguardCardDiagnostics.startCapture(context, "light-sha", "debug", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2018:        KeyguardCardDiagnostics.freezeCapture(context)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2020:        KeyguardCardDiagnostics.startCapture(context, "full-sha", "debug", "FULL")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2022:        KeyguardCardDiagnostics.freezeCapture(context)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2029:        KeyguardCardDiagnostics.startCapture(context, "async-sha", "debug", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2054:        val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2086:            val captureId = KeyguardCardDiagnostics.startCapture(context, source, "profile", mode)["captureId"].toString()
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2152:            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2181:        KeyguardCardDiagnostics.startCapture(context, source, "profile", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2183:        val off = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2191:            KeyguardCardDiagnostics.startCapture(context, "r15-owner", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2202:            val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2215:        KeyguardCardDiagnostics.startCapture(context, source, "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2283:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2312:        KeyguardCardDiagnostics.startCapture(context, source, "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2334:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2351:        KeyguardCardDiagnostics.startCapture(context, "$source-rotated", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2354:        val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2360:        KeyguardCardDiagnostics.startCapture(context, source, "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2413:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2436:        KeyguardCardDiagnostics.startCapture(context, "$source-rotated", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2439:        val rotated = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2446:        KeyguardCardDiagnostics.startCapture(context, source, "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2522:        val frozen = KeyguardCardDiagnostics.freezeCapture(context)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2576:            KeyguardCardDiagnostics.startCapture(context, "r07-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2630:            val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2656:            KeyguardCardDiagnostics.startCapture(context, "new-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2659:            val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2668:        KeyguardCardDiagnostics.startCapture(context, "r08-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2708:        val frozen = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2717:        KeyguardCardDiagnostics.startCapture(context, "r08-next-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2721:        val next = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2726:        KeyguardCardDiagnostics.startCapture(context, "identity-check", "debug", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2737:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2743:        KeyguardCardDiagnostics.startCapture(context, "draw-gap-identity", "profile", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2758:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2790:        KeyguardCardDiagnostics.startCapture(context, "r11-visible-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2817:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2828:        KeyguardCardDiagnostics.startCapture(context, "r11-new-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2835:        val nextReport = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2842:        KeyguardCardDiagnostics.startCapture(context, "r10-export-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2895:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2911:        KeyguardCardDiagnostics.startCapture(context, "r09-gap-$mode", "profile", mode)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2939:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2950:        KeyguardCardDiagnostics.startCapture(context, "draw-owner", "profile", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2953:        KeyguardCardDiagnostics.freezeCapture(context)
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2955:        KeyguardCardDiagnostics.startCapture(context, "draw-owner", "profile", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2961:        KeyguardCardDiagnostics.startCapture(context, "gap-bounds", "debug", "LIGHT")
android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt:2968:        val report = KeyguardCardDiagnostics.freezeCapture(context)["report"] as String
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
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:383:                                    val saved = withContext(Dispatchers.IO) { KeyguardR46RecordingStore.status(applicationContext) }
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:392:                                    val before = withContext(Dispatchers.IO) { KeyguardR46RecordingStore.status(applicationContext) }
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:404:                                        val text = KeyguardR46RecordingStore.seal(applicationContext, id, summary,
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:412:                                        "report" to KeyguardR46RecordingStore.sealedReport(applicationContext, id)) }
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:416:                                    withContext(Dispatchers.IO) { KeyguardR46RecordingStore.copied(applicationContext, id) }
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:420:                        }.onSuccess(result::success).onFailure { result.error("R46_RECORDING", it.message, null) }
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:452:                if (call.method == "getR44SyntheticTrial" || call.method == "setR44SyntheticTrial") {
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:457:                        if (call.method == "setR44SyntheticTrial") {
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:459:                            if (!available || service == null || enabled == null || !service.setR44SyntheticTrial(enabled)) {
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:460:                                result.error("R44_TRIAL", "A próba csak feloldott telefonon, bekapcsolt ORB-szolgáltatással indítható.", null)
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:464:                        result.success(mapOf("available" to available, "enabled" to com.fluvi.app.lockscreen.KeyguardR44Trial.active))
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:500:                            val requested = KeyguardR448DisplayRoute.entries.firstOrNull { it.name == value }
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:501:                            val old = KeyguardR448DisplayRouteStore.read(applicationContext)
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:508:                            if (!KeyguardR448DisplayRouteStore.write(applicationContext, requested)) {
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:514:                        val configured = KeyguardR448DisplayRouteStore.read(applicationContext)
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:515:                        val native = service?.r448DisplayRouteStatus() ?: mapOf(
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:517:                            "sampleOnly" to KeyguardR448Safety.sampleOnly(applicationContext))
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:525:                            KeyguardR448ComparisonStore.export(applicationContext) else ""
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:543:                                    "startKeyguardDiagnosticCapture" -> KeyguardCardDiagnostics.startCapture(
android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt:549:                                    "freezeKeyguardDiagnosticCapture" -> KeyguardCardDiagnostics.freezeCapture(applicationContext)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:66:        KeyguardR444ProfileOwner(AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:85:    private val r445WakeBudget = KeyguardR445WakeBudget()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:151:    @Volatile private var r448DisplayRoute = KeyguardR448DisplayRoute.FLUVI_STREAM
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:152:    private var r448RouteGeneration = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:153:    private val r448SampleOnly by lazy { KeyguardR448Safety.sampleOnly(applicationContext) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:155:    private fun localPresentationAllowed(): Boolean = !r448SampleOnly && r444ConfigurationReady &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:156:        referenceOwnership?.appMayShow() != false && r448DisplayRoute == KeyguardR448DisplayRoute.FLUVI_STREAM &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:157:        r448Frame == null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:190:        if (r448SampleOnly) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:271:    internal fun r447ScheduleOutputReadyForTest() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:272:        check(KeyguardR447TestHooks.CONTROLLED_TOPOLOGY)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:275:    internal fun r447SampleOrderForTest(request: Long): KeyguardFirstAuthorizedOrb.SampleOrder = synchronized(queueLock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:278:    internal fun r447SamplerIdleForTest(): Boolean = !systemSampler.hasOutstandingWork()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:287:    internal fun r448SafetyForInstrumentation(): Triple<Boolean, Boolean, Boolean> =
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:288:        Triple(r448SampleOnly, localPresentationAllowed(), lastMaterialProfile != null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:291:    internal fun setR448DisplayRoute(route: KeyguardR448DisplayRoute): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:295:        if (r448DisplayRoute == route) return true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:296:        if ((KeyguardR44Trial.active || r446CaptureId != null) && !stopR444Trial("ROUTE_CHANGED")) return false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:297:        if (r448Frame != null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:299:            if (r448Frame != null) return false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:301:        hideImmediately("r448RouteChanged")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:303:        r448RouteGeneration++
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:304:        r448DisplayRoute = route
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:307:        if (route == KeyguardR448DisplayRoute.FLUVI_STREAM)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:308:            requestSystemCheck("r448RouteChanged", evaluate = true)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:312:    internal fun r448DisplayRouteStatus(): Map<String, Any> {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:315:            r448DisplayRoute == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE && r448Frame?.isAttached() == true -> "WIDGETS_ANYWHERE"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:316:            r448DisplayRoute == KeyguardR448DisplayRoute.FLUVI_STREAM &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:318:                    (r446Owner.state == KeyguardR446PrintOwner.State.ISSUED && r446Observation?.submittedAt != null)) -> "FLUVI_STREAM"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:321:        return mapOf("configured" to r448DisplayRoute.name, "active" to active,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:322:            "generation" to r448RouteGeneration,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:323:            "sampleOnly" to r448SampleOnly,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:324:            "reason" to if (r448SampleOnly && !KeyguardR44Trial.active) "SAMPLE_ONLY_NORMAL_DISABLED"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:325:                else if (r448DisplayRoute == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE) "PUBLIC_SAMPLE_ONLY" else "NONE")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:352:    internal fun setR44SyntheticTrial(enabled: Boolean, expanded: Boolean = false): Boolean {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:361:        if (enabled && KeyguardR44Trial.active &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:362:            ((expanded && current.kind == KeyguardR444ProfileOwner.Kind.EXPANDED) ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:363:                (!expanded && current.kind in setOf(KeyguardR444ProfileOwner.Kind.STANDARD,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:364:                    KeyguardR444ProfileOwner.Kind.STANDARD_ALREADY_INCLUDED)))) return true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:376:        KeyguardR44Trial.set(false, false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:380:        KeyguardR44Trial.set(true, r442Lookup.verified)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:385:            KeyguardR44Trial.set(false, false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:396:        r449Session = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:399:        val active = KeyguardR44Trial.active || r444ProfileOwner.snapshot.kind != KeyguardR444ProfileOwner.Kind.INACTIVE
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:413:            KeyguardR44Trial.set(false, false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:446:        r46Request: String? = null, r46Route: String? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:453:        if (previousReceipt != null && KeyguardR44Trial.active && !stopR444Trial("captureReplaced"))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:472:            if (!setR44SyntheticTrial(true, expanded) || !KeyguardR44Trial.active ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:473:                KeyguardR44Trial.profile(null) == null || KeyguardR44Trial.settings(settings).showFinancialDetails ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:481:                KeyguardCardDiagnostics.startCapture(applicationContext, build, buildMode, captureMode, r46Request != null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:483:                    r46Request = r46Request, r46Route = r46Route)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:490:                KeyguardCardDiagnostics.currentProcessInstanceId() != expectedProcess || !KeyguardR44Trial.active ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:507:            if (!accepted && KeyguardR44Trial.active &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:524:            KeyguardR444ProfileOwner.Kind.EXPANDED, KeyguardR444ProfileOwner.Kind.STANDARD_ALREADY_INCLUDED -> included
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:525:            KeyguardR444ProfileOwner.Kind.STANDARD -> !included
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:531:                KeyguardCardDiagnostics.activeCaptureId() != receipt.capture || !KeyguardR44Trial.active ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:533:            if (KeyguardR44Trial.active) stopR444Trial("serviceOrCaptureChanged")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:538:        val printState = if (r448DisplayRoute == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE) when (r45Wa.phase) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:539:            KeyguardR45Phase.PREPARED -> "WAIT_OFF"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:540:            KeyguardR45Phase.WAIT_WAKE -> "WAIT_WAKE"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:541:            KeyguardR45Phase.OPENING -> "WAIT_READ"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:542:            KeyguardR45Phase.ATTACHED_HIDDEN, KeyguardR45Phase.VISIBLE, KeyguardR45Phase.SUSPENDED -> "ISSUED"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:543:            KeyguardR45Phase.RETIRED -> "CONSUMED"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:551:            "routeConfirmed" to r448DisplayRoute.name, "actionKind" to r449Action,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:552:            "sampleShape" to if (r45Circle) "CIRCLE" else "ORB",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:553:            "printState" to printState, "printReason" to r449LastTerminal,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:554:            "sessionExpiresAt" to r449Session?.expiresAt,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:561:    private val r446Owner = KeyguardR446PrintOwner()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:562:    @Volatile private var r446ReadArm: KeyguardR446PrintOwner.Arm? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:570:    private var r447SystemBarrier = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:571:    private var r447SystemSatisfied = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:572:    private var r447DecisionOrdinal = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:573:    private var r446Presenter: KeyguardR446WindowPresenter? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:574:    @Volatile private var r448Frame: KeyguardR448WidgetsAnywhereFrame? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:575:    private var r448FrameOwner: KeyguardR448WidgetsAnywhereFrame.Owner? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:576:    private var r448FrameGeneration = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:577:    private var r448HideAt: Long? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:578:    private var r448RemoveAt: Long? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:579:    private var r448RetireError: String? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:580:    private fun r446HasBackend() = r446Presenter != null || r448Frame != null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:585:    private val r45Wa = KeyguardR45WaLifetime()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:586:    private val r45Direct = KeyguardR45DirectLifetime()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:587:    private val r45IngressSequence = AtomicLong(0)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:588:    private val r45DirectRevision = AtomicLong(0)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:589:    @Volatile private var r45WaOwnIdentity: KeyguardOwnOverlayIdentity? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:590:    private var r45DirectReadActive = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:591:    private var r45DirectReadPending = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:592:    private var r45DirectLower: List<KeyguardR45LowerWindow> = emptyList()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:593:    private var r45Circle = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:596:        val arm: KeyguardR45SampleIntent, val context: KeyguardDiagnosticContext,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:597:        val owner: KeyguardR448WidgetsAnywhereFrame.Owner, val screenAt: Long, var expiresAt: Long = Long.MAX_VALUE,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:599:        var lower: List<KeyguardR45LowerWindow> = emptyList(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:603:    @Volatile private var r449Wake: R449Wake? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:604:    private val r449RestrictionRevision = AtomicLong(0)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:605:    private var r449ReadActive = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:606:    private var r449ReadPending = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:607:    private var r449FirstRead = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:608:    private var r449Action = "ONE_WAKE"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:609:    private var r449LastTerminal = "UNOBSERVED"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:610:    private data class R449FluviRecovery(val observation: KeyguardR449RecoveryObservation,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:611:                                          val arm: KeyguardR446PrintOwner.Arm, var consumed: Boolean = false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:612:    private var r449FluviRecovery: R449FluviRecovery? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:613:    private data class R449Session(val capture: String, val serviceSession: Long, val route: KeyguardR448DisplayRoute,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:615:    private var r449Session: R449Session? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:616:    private var r449SessionPreparing = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:618:    private fun r449Current(wake: R449Wake, revision: Long): Boolean =
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:619:        r449Wake === wake && r449RestrictionRevision.get() == revision &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:620:            r448DisplayRoute == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:621:            r448RouteGeneration == wake.owner.route && FluviKeyguardCardServiceRegistry.connected &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:622:            r448FrameOwner == wake.owner && r45Wa.current(wake.arm, wake.owner.wake, wake.owner.material) &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:625:            KeyguardR44Trial.active && SystemClock.uptimeMillis() < wake.expiresAt
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:627:    private fun r449BeginWake(arm: KeyguardR45SampleIntent, screenAt: Long) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:629:        if (r448DisplayRoute != KeyguardR448DisplayRoute.WIDGETS_ANYWHERE) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:630:        val frame = r448Frame ?: return r446Cancel("wa:missingFrame")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:631:        val prepared = r448FrameOwner ?: return r446Cancel("wa:missingOwner")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:637:        if (!r45Wa.bind(arm, bound.wake, bound.material)) return r446Cancel("wa:lifetimeBindFailed")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:638:        r448FrameOwner = bound
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:640:        r449Wake = wake
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:641:        r449RestrictionRevision.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:642:        r449ReadPending = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:643:        r449FirstRead = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:644:        runCatching { KeyguardCardDiagnostics.recordR446(KeyguardR446Observation(context, r446ArmAt,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:647:        r45RecordStage(context, "WIDGETS_ANYWHERE", "INTENT", SystemClock.uptimeMillis(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:649:        r449ScheduleRead()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:652:    private fun r45TryBeginWaWake() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:653:        val arm = r45Wa.intent ?: return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:655:        if (r448DisplayRoute != KeyguardR448DisplayRoute.WIDGETS_ANYWHERE || r449Wake != null ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:656:            r45Wa.phase != KeyguardR45Phase.OPENING || screen.session != arm.session ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:658:        r449BeginWake(arm, screen.uptime)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:661:    private fun r45RecordStage(context: KeyguardDiagnosticContext?, route: String, stage: String, at: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:665:        runCatching { KeyguardCardDiagnostics.recordR45(KeyguardR45Observation(context, route, stage, at,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:669:    private fun r45RecordIngress(context: KeyguardDiagnosticContext?, route: String, sequence: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:671:                                 decision: KeyguardR45IngressAction, phase: String, revision: Long) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:675:            decision == KeyguardR45IngressAction.IGNORE && meta.displayId > 0 -> "OTHER_DISPLAY"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:676:            decision == KeyguardR45IngressAction.IGNORE -> "VERIFIED_LOWER"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:682:        runCatching { KeyguardCardDiagnostics.recordR45(KeyguardR45Observation(context, route, "INGRESS", receivedAt,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:687:    private fun r45DirectCurrent(lease: KeyguardR45DirectLifetime.Lease): Boolean =
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:688:        r45Direct.current(lease, SystemClock.uptimeMillis()) &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:690:            r448DisplayRoute == KeyguardR448DisplayRoute.FLUVI_STREAM && r448RouteGeneration == lease.route &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:692:            KeyguardCardDiagnostics.activeCaptureId() == lease.capture && KeyguardR44Trial.active &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:697:    private fun r45ScheduleDirectRead(lease: KeyguardR45DirectLifetime.Lease) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:699:        if (!r45DirectCurrent(lease)) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:700:        if (r45DirectReadActive) { r45DirectReadPending = true; return }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:701:        val revision = r45DirectRevision.get()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:702:        r45DirectReadActive = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:703:        r449Scope.launch {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:707:                KeyguardWindowSnapshotReader(this@FluviKeyguardCardService, packageName).read(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:708:                    KeyguardWindowSnapshotReader.Request(knownOwn = null, attachGeneration = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:710:                        strictOwnAttribution = true, r44Enabled = true, r443Sample = true,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:712:                    authorityIsCurrent = { r45Direct.lease === lease && r45DirectRevision.get() == revision &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:713:                        session.get() == lease.session && KeyguardR44Trial.active },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:719:            val classification = read?.let { KeyguardR44SurfaceClassifier.classify(it.snapshots,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:722:                KeyguardR446PrintPolicy.evaluate(read.snapshots, classification, read.rootUnavailable, read.walkTruncated)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:724:            val restrictions = KeyguardR449RestrictionEvidence.fromInventory(read?.snapshots.orEmpty(), ended,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:728:                values.any { it == KeyguardR448Admission.Presence.PRESENT }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:730:                values.all { it == KeyguardR448Admission.Presence.CLEAR }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:732:                r45DirectReadActive = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:733:                if (r45DirectCurrent(lease) && r45DirectRevision.get() == revision) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:735:                    r45RecordStage(r446Observation?.context, "FLUVI_STREAM", "RECOVERY", SystemClock.uptimeMillis(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:738:                    else if (allowed && r45Direct.phase == KeyguardR45Phase.SUSPENDED) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:739:                        r45DirectLower = restrictions.lower
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:740:                        r45Direct.visible(lease)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:741:                        val valid = { r45DirectCurrent(lease) && r45DirectRevision.get() == revision }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:743:                            if (r45Direct.lease === lease && r45Direct.phase != KeyguardR45Phase.SUSPENDED)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:746:                        if (resumed) r45RecordStage(r446Observation?.context, "FLUVI_STREAM", "REVEAL",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:748:                        else r45Direct.suspend(lease)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:751:                if (r45DirectReadPending && r45Direct.lease != null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:752:                    r45DirectReadPending = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:753:                    r45Direct.lease?.let(::r45ScheduleDirectRead)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:761:    private fun r449ScheduleRead() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:763:        val wake = r449Wake ?: return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:764:        if (r449ReadActive) { r449ReadPending = true; return }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:765:        val revision = r449RestrictionRevision.get()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:766:        if (!r449Current(wake, revision)) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:767:        val own = r448Frame?.ownIdentity(wake.owner)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:768:        r45WaOwnIdentity = own
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:769:        val freshness = if (r449FirstRead) KeyguardWindowFreshness.LIFECYCLE_BOUNDARY
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:771:        r449FirstRead = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:772:        r449ReadActive = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:773:        r449Scope.launch {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:779:                KeyguardWindowSnapshotReader(this@FluviKeyguardCardService, packageName).read(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:780:                    KeyguardWindowSnapshotReader.Request(knownOwn = own, attachGeneration = wake.owner.material,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:781:                        knownOwnAtInventory = { r45WaOwnIdentity },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:782:                        freshness = freshness, strictOwnAttribution = true, r44Enabled = true,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:784:                    authorityIsCurrent = { r449Wake === wake && r449RestrictionRevision.get() == revision &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:785:                        session.get() == wake.arm.session && wakeEpoch == wake.owner.wake && KeyguardR44Trial.active },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:790:                KeyguardR449RestrictionEvidence.fromInventory(inventory?.snapshots.orEmpty(), ended,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:794:                KeyguardR449RestrictionEvidence.fromInventory(emptyList(), ended, unavailable = true, truncated = true)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:797:                r449ReadActive = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:798:                if (r449Current(wake, revision)) r449Apply(wake, revision, started, ended, system, evidence)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:799:                if (r449ReadPending && r449Wake != null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:800:                    r449ReadPending = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:801:                    r449ScheduleRead()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:807:    private fun r449Apply(wake: R449Wake, revision: Long, started: Long, ended: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:808:                          system: KeyguardSystemState, evidence: KeyguardR449RestrictionEvidence.Result) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:809:        val stamp = KeyguardR448Admission.Stamp(wake.owner.route, wake.owner.wake, wake.owner.material)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:810:        val decision = KeyguardR448Admission.evaluate(KeyguardR448Admission.Inputs(stamp, wake.screenAt,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:811:            system, evidence.exclusions, KeyguardR448Admission.Domain.PUBLIC_SAMPLE, materialAuthorized = true),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:813:        if (r45Wa.phase == KeyguardR45Phase.SUSPENDED)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:814:            r45RecordStage(wake.context, "WIDGETS_ANYWHERE", "RECOVERY", SystemClock.uptimeMillis(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:816:        runCatching { KeyguardCardDiagnostics.recordR449Admission(KeyguardR449AdmissionObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:817:            wake.context, wake.arm.generation, wake.owner.route, wake.owner.material, revision, r449Action,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:819:        if (decision != KeyguardR448Admission.Decision.ALLOW) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:820:            if (decision == KeyguardR448Admission.Decision.RESTRICTED ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:821:                decision == KeyguardR448Admission.Decision.SYSTEM_EXCLUDED) r446Cancel("wa:${evidence.reason}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:828:        if (pendingValidation != null) r449ValidateSystem(wake, pendingValidation)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:833:            if (r45Wa.phase == KeyguardR45Phase.SUSPENDED) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:834:                val frame = r448Frame ?: return r446Cancel("wa:missingFrame")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:835:                val valid = { val current = r449RestrictionRevision.get()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:836:                    r449Current(wake, current) && wake.allowedRevision == current }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:837:                val checkSystem: ((Boolean) -> Unit) -> Unit = { done -> r449ValidateSystem(wake, done) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:839:                else if (!frame.hasOwnedWindow()) r449RequestFrame(wake, frame, valid, checkSystem)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:843:        val frame = r448Frame ?: return r446Cancel("wa:missingFrame")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:848:        runCatching { KeyguardCardDiagnostics.recordR449Admission(KeyguardR449AdmissionObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:849:            wake.context, wake.arm.generation, wake.owner.route, wake.owner.material, revision, r449Action,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:851:        r446Observation = KeyguardR446Observation(wake.context, r446ArmAt, wake.owner.wake, 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:855:        runCatching { KeyguardCardDiagnostics.recordR446(requireNotNull(r446Observation)) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:856:        val valid = { val current = r449RestrictionRevision.get()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:857:            r449Current(wake, current) && wake.allowedRevision == current }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:858:        val checkSystem: ((Boolean) -> Unit) -> Unit = { done -> r449ValidateSystem(wake, done) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:859:        r449RequestFrame(wake, frame, valid, checkSystem)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:860:        mainHandler.postDelayed({ if (r449Wake === wake) r446Cancel("deadline") },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:864:    private fun r449RequestFrame(wake: R449Wake, frame: KeyguardR448WidgetsAnywhereFrame,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:879:    private fun r449ValidateSystem(wake: R449Wake, done: (Boolean) -> Unit) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:881:        val revision = r449RestrictionRevision.get()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:882:        if (!r449Current(wake, revision)) { done(false); return }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:884:        r449Scope.launch {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:888:                val current = r449RestrictionRevision.get()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:889:                if (!r449Current(wake, current)) done(false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:899:    private fun r448RecordFrameEvent(event: KeyguardR448WidgetsAnywhereFrame.Event) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:900:        if (event.owner != r448FrameOwner) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:902:            "ATTACHED" -> r449Wake?.let {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:903:                r45Wa.attached(it.arm)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:904:                if (r45Wa.phase == KeyguardR45Phase.SUSPENDED) mainHandler.post { r449ScheduleRead() }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:906:            "REVEAL" -> r449Wake?.let { r45Wa.visible(it.arm) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:907:            "CONCEAL" -> r449Wake?.let { r45Wa.suspend(it.arm) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:908:            "PRE_ADD_UNVERIFIED", "POST_ADD_UNVERIFIED", "RESUME_UNVERIFIED" -> r449Wake?.let { wake ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:909:                val revision = r449RestrictionRevision.get()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:912:                    mainHandler.post { if (r449Wake === wake) r449ScheduleRead() }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:915:            "HIDE" -> if (r448HideAt == null) r448HideAt = event.at
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:916:            "REMOVE_RETURN" -> if (r448RemoveAt == null) r448RemoveAt = event.at
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:917:            "REMOVE_FAILED" -> r448RetireError = event.detail ?: "UNKNOWN"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:921:            KeyguardCardDiagnostics.recordR448Frame(KeyguardR448FrameObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:924:        if (previous != null) r45RecordStage(previous.context, "WIDGETS_ANYWHERE", event.stage, event.at,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:926:        if (previous != null && r449Wake?.issued == true) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:936:                runCatching { KeyguardCardDiagnostics.recordR446(next) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:941:                if (event.owner == r448FrameOwner &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:942:                    r449Wake?.issued == true)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:948:    private var r446Observation: KeyguardR446Observation? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:951:    private var r448StartedRequest: Long? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:952:    private var r448StartedArm: Long? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:955:    internal fun r446PreparePresenterForInstrumentation(timeSource: KeyguardMaterialTimeSource): KeyguardR446WindowPresenter {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:957:        return KeyguardR446WindowPresenter(this, timeSource).also { r446Presenter = it }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:962:                                              r46Request: String? = null): Map<String, Any?> {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:965:        if (r448Frame != null || r446Presenter != null) return mapOf("active" to false, "reason" to "retirementPending")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:966:        r449Action = sampleAction
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:967:        r45Circle = diagnosticCircle
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:968:        val route = r448DisplayRoute
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:969:        val routeGeneration = r448RouteGeneration
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:973:                r46Request = r46Request, r46Route = route.name)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:976:            val sample = KeyguardR44Trial.profile(null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:983:                KeyguardCardDiagnostics.activeCaptureId() != capture || !KeyguardR44Trial.active ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:984:                r448DisplayRoute != route || r448RouteGeneration != routeGeneration ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:989:            r46DisplayFacts = currentR46DisplayFacts()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:990:            if (route == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:991:                val frame = KeyguardR448WidgetsAnywhereFrame(this)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:992:                val prepared = KeyguardR448WidgetsAnywhereFrame.Owner(routeGeneration, 0, ++r448FrameGeneration)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:993:                r448HideAt = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:994:                r448RemoveAt = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:995:                r448RetireError = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:996:                if (!frame.preparePublic(prepared, KeyguardR46PublicMaterial.demo(), artifact, diagnosticCircle, ::r448RecordFrameEvent)) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1000:                r448Frame = frame
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1001:                r448FrameOwner = prepared
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1003:                val presenter = KeyguardR446WindowPresenter(this)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1004:                presenter.onR46Interval = { detail -> r45RecordStage(r446Observation?.context, "FLUVI_STREAM",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1008:                if (!presenter.preparePublic(display, KeyguardR46PublicMaterial.demo(), artifact, diagnosticCircle)) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1022:                !KeyguardR44Trial.active || r448DisplayRoute != route || r448RouteGeneration != routeGeneration ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1028:            r447DecisionOrdinal = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1033:            if (route == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1034:                r45Wa.prepare(capture, session.get(), routeGeneration, sampleAction, diagnosticCircle)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1036:            r449LastTerminal = "UNOBSERVED"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1050:                                               r46Request: String? = null): Map<String, Any?> {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1053:        val route = r448DisplayRoute.name
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1056:        val result = startR446PrintCapture(build, buildMode, mode, action, diagnosticCircle, r46Request)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1057:        if (result["active"] == true && result["printArmed"] == true && r448DisplayRoute.name == route) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1058:            r449Action = action
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1060:            KeyguardCardDiagnostics.recordR449Intent(capture, action, route, SystemClock.uptimeMillis())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1061:            val newSession = if (action == "SESSION") R449Session(capture, session.get(), r448DisplayRoute,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1062:                r448RouteGeneration, if (r46Request == null) SystemClock.uptimeMillis() + 120_000L else Long.MAX_VALUE,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1064:            r449Session = newSession
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1065:            if (newSession != null && r46Request == null) mainHandler.postDelayed({
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1066:                if (r449Session === newSession) stopR444Trial("sampleSessionExpired")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1071:        return result + mapOf("routeRequested" to requestedRoute, "routeConfirmed" to r448DisplayRoute.name,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1075:    private var r46StartingRequest: String? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1076:    private var r46StartedRequest: String? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1077:    private var r46StartedReceipt: Map<String, Any?>? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1080:        val partial = withContext(Dispatchers.IO) { KeyguardR46RecordingStore.status(applicationContext) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1083:            stopR444Trial("r46StartFailed")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1087:                KeyguardR46RecordingStore.abort(applicationContext, partialId)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1099:        if (r46StartedRequest == request && r46StartedReceipt != null &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1100:            r442SampleStatus()["active"] == true) return requireNotNull(r46StartedReceipt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1101:        if (r46StartingRequest != null || r442Receipt != null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1103:        if (route != r448DisplayRoute.name) return mapOf("active" to false, "reason" to "routeChanged")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1104:        r46StartingRequest = request
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1107:                diagnosticCircle = false, r46Request = request)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1110:                val receipt = result + mapOf("state" to "RECORDING", "policy" to "R46_ALL", "requestId" to request)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1111:                r46StartedRequest = request
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1112:                r46StartedReceipt = receipt
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1121:            r46StartingRequest = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1127:        if (r46StartingRequest != null) return false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1128:        if (r442Receipt?.capture == capture && !stopR444Trial("r46UserStop")) return false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1129:        r46StartedRequest = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1130:        r46StartedReceipt = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1137:    private fun r449PrepareSessionWake() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1139:        val active = r449Session ?: return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1140:        if (r449SessionPreparing || r446HasBackend() || r448Frame != null ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1141:            (active.route == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE && r45Wa.phase != KeyguardR45Phase.RETIRED) ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1142:            (active.route == KeyguardR448DisplayRoute.FLUVI_STREAM && r446Owner.state in setOf(KeyguardR446PrintOwner.State.WAIT_OFF,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1143:                KeyguardR446PrintOwner.State.WAIT_WAKE, KeyguardR446PrintOwner.State.WAIT_READ,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1144:                KeyguardR446PrintOwner.State.ISSUED))) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1145:        fun current() = r449Session === active && SystemClock.uptimeMillis() < active.expiresAt &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1147:            active.serviceSession == session.get() && KeyguardR44Trial.active &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1148:            r448DisplayRoute == active.route && r448RouteGeneration == active.routeGeneration
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1150:        r449SessionPreparing = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1153:                val sample = KeyguardR44Trial.profile(null) ?: return@launch
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1160:                if (active.route == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1161:                    val frame = KeyguardR448WidgetsAnywhereFrame(this@FluviKeyguardCardService)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1162:                    val owner = KeyguardR448WidgetsAnywhereFrame.Owner(active.routeGeneration, 0, ++r448FrameGeneration)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1163:                    if (!frame.preparePublic(owner, KeyguardR46PublicMaterial.demo(), artifact, active.circle, ::r448RecordFrameEvent)) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1167:                    r448Frame = frame
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1168:                    r448FrameOwner = owner
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1170:                    val presenter = KeyguardR446WindowPresenter(this@FluviKeyguardCardService)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1171:                    presenter.onR46Interval = { detail -> r45RecordStage(r446Observation?.context, "FLUVI_STREAM",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1174:                    if (!presenter.preparePublic(display, KeyguardR46PublicMaterial.demo(), artifact, active.circle) || !presenter.awaitInputReady()) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1177:                    if (!current() || r446Presenter !== presenter || r448Frame != null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1182:                r448HideAt = null; r448RemoveAt = null; r448RetireError = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1183:                r446Observation = null; r447DecisionOrdinal = 0L; r446RestrictionSeen = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1185:                if (active.route == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1186:                    r45Wa.prepare(active.capture, active.serviceSession, active.routeGeneration, "SESSION", active.circle)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1188:                r449LastTerminal = "UNOBSERVED"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1190:                    if (active.route == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE) r45Wa.screenOff()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1195:                r449SessionPreparing = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1203:        val r45Context = r449Wake?.context ?: r446Observation?.context
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1204:        val r45Route = if (r449Wake != null) "WIDGETS_ANYWHERE" else "FLUVI_STREAM"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1205:        r45RecordStage(r45Context, r45Route, "TERMINAL", at, detail = reason.take(80))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1207:        if (cancelledArm != null) r449LastTerminal = reason
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1208:        r449FluviRecovery?.let { recovery ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1209:            runCatching { KeyguardCardDiagnostics.recordR449Recovery(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1212:        r449FluviRecovery = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1213:        val pendingValidation = r449Wake?.pendingValidation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1214:        r449Wake?.pendingValidation = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1215:        r45Wa.retire()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1216:        r45Direct.retire()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1217:        r45WaOwnIdentity = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1218:        r45DirectRevision.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1219:        r45DirectReadPending = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1220:        r45DirectLower = emptyList()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1221:        r449RestrictionRevision.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1222:        r449Wake = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1224:        r449ReadPending = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1232:        if (retired?.hideReturn != null) r45RecordStage(r45Context, r45Route, "CONCEAL", retired.hideReturn, detail = reason.take(80))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1233:        if (retired?.releaseReturn != null) r45RecordStage(r45Context, r45Route, "REMOVE_RETURN", retired.releaseReturn, detail = reason.take(80))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1234:        val frame = r448Frame
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1235:        val frameOwner = r448FrameOwner
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1238:            if (removed) { r448Frame = null; r448FrameOwner = null }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1239:            else if (r448RetireError == null) r448RetireError = "REMOVAL_UNCONFIRMED"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1244:            KeyguardCardDiagnostics.recordR447ArmTerminal(cancelledArm.capture, cancelledArm.generation, at, reason)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1249:            val next = previous.retireOnce(at, reason, retired?.hideReturn ?: r448HideAt,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1250:                retired?.releaseReturn ?: r448RemoveAt, retired?.errorClass ?: r448RetireError)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1252:            KeyguardCardDiagnostics.recordR446(next)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1258:                val terminal = KeyguardR446Observation(context, r446ArmAt, context.originWakeEpoch, 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1260:                    null, null, at, reason, retired?.hideReturn ?: r448HideAt,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1261:                    retired?.releaseReturn ?: r448RemoveAt, retired?.errorClass ?: r448RetireError,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1263:                KeyguardCardDiagnostics.recordR446(terminal)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1268:    private fun r447RecordWakeArm() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1274:        val waArm = if (r448DisplayRoute == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE) r45Wa.intent else null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1275:        val armed = if (waArm != null) r45Wa.phase in setOf(KeyguardR45Phase.OPENING,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1276:            KeyguardR45Phase.ATTACHED_HIDDEN, KeyguardR45Phase.VISIBLE, KeyguardR45Phase.SUSPENDED) &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1278:        else r446Owner.state == KeyguardR446PrintOwner.State.WAIT_READ && arm != null &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1281:        KeyguardCardDiagnostics.recordR446(KeyguardR446Observation(context, if (armed) r446ArmAt else 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1288:        val disposition: KeyguardR447Disposition, val order: KeyguardFirstAuthorizedOrb.SampleOrder,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1289:        val systemBarrier: Long, val ownerState: String, val ticket: KeyguardR446PrintOwner.Ticket?, val at: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1295:        if (r448DisplayRoute != KeyguardR448DisplayRoute.FLUVI_STREAM) return false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1301:        val stamp = inspection.r447Stamp
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1302:        val ordinal = ++r447DecisionOrdinal
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1309:        val route = r448DisplayRoute
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1310:        val routeGeneration = r448RouteGeneration
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1317:                    r446Owner.state != KeyguardR446PrintOwner.State.WAIT_READ -> KeyguardR447Disposition.ARM_MISMATCH
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1318:                !authorityIsCurrent(request) || inspection.abortedStale -> KeyguardR447Disposition.STALE_AUTHORITY
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1319:                disposition == CompletedDisposition.R32_RESTRICTION_ONLY -> KeyguardR447Disposition.RESTRICTION_ONLY
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1321:                    KeyguardR447Disposition.RESTRICTION_OBSERVED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1322:                target == null -> KeyguardR447Disposition.TARGET_MISSING
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1324:                    stamp.target != target || stamp.scene != scene -> KeyguardR447Disposition.FRESHNESS_UNESTABLISHED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1325:                order.result == KeyguardFirstAuthorizedOrb.SampleResult.SCENE_CHANGED -> KeyguardR447Disposition.SCENE_CHANGED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1326:                order.result == KeyguardFirstAuthorizedOrb.SampleResult.NEWER_COMPLETED -> KeyguardR447Disposition.NEWER_COMPLETED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1327:                order.result == KeyguardFirstAuthorizedOrb.SampleResult.NEWER_BARRIER_REQUIRED || stamp.barrier > request.id ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1328:                    KeyguardR447Disposition.NEWER_BARRIER_REQUIRED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1330:                    stamp.systemBarrier != stamp.systemSatisfied || stamp.systemBarrier != r447SystemBarrier ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1331:                    r447SystemBarrier != r447SystemSatisfied || currentSystem?.eligible != true ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1332:                    KeyguardR447Disposition.FRESHNESS_UNESTABLISHED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1333:                presenter == null -> KeyguardR447Disposition.PRESENTER_UNAVAILABLE
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1342:            R447Decision(reject ?: if (ticket == null) KeyguardR447Disposition.ISSUE_REJECTED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1343:                else KeyguardR447Disposition.ISSUED, order, r447SystemBarrier, state, ticket, decidedAt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1345:        var observation = KeyguardR446Observation(context, r446ArmAt, request.wakeGeneration, request.id,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1355:        KeyguardCardDiagnostics.recordR446(observation)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1356:        if (route == KeyguardR448DisplayRoute.FLUVI_STREAM && decision.disposition == KeyguardR447Disposition.TARGET_MISSING &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1357:            r449FluviRecovery == null && !r446RestrictionSeen && r446Owner.arm == arm &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1358:            r446Owner.state == KeyguardR446PrintOwner.State.WAIT_READ && authorityIsCurrent(request)) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1359:            val unresolved = inspection.r449UnresolvedUpper
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1362:                val initial = KeyguardR449RecoveryObservation(context, arm.generation, request.wakeGeneration,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1365:                r449FluviRecovery = recovery
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1366:                KeyguardCardDiagnostics.recordR449Recovery(initial)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1378:                    KeyguardCardDiagnostics.recordR449Recovery(initial.copy(stage = "ADOPT_CURRENT_SUCCESSOR",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1386:            observation = observation.copy(handoff = KeyguardR447Disposition.SETTINGS_UNAVAILABLE)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1388:            KeyguardCardDiagnostics.recordR446(observation)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1397:        fun openingOwned(): Boolean = !r446RestrictionSeen && KeyguardR44Trial.active &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1398:            r448DisplayRoute == route && r448RouteGeneration == routeGeneration &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1404:                    stamp.systemBarrier == r447SystemBarrier && r447SystemBarrier == r447SystemSatisfied
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1409:        val lease = KeyguardR45DirectLifetime.Lease(ticket, arm.capture, request.session, request.wakeGeneration,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1411:        r45Direct.open(lease)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1412:        r45DirectLower = inspection.r45Lower
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1413:        r45RecordStage(context, "FLUVI_STREAM", "INTENT", decision.at,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1414:            detail = if (r45Circle) "CIRCLE" else "ORB")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1415:        fun stillOwned(): Boolean = r45DirectCurrent(lease) &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1416:            r45Direct.phase != KeyguardR45Phase.SUSPENDED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1418:            attachBegin = if (route == KeyguardR448DisplayRoute.FLUVI_STREAM) SystemClock.uptimeMillis() else null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1419:            backend = if (route == KeyguardR448DisplayRoute.FLUVI_STREAM) "ATTEMPTED" else "WA_WAITING")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1421:        KeyguardCardDiagnostics.recordR446(observation)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1422:        runCatching { inspectionProbeForTest?.r447PresenterInvoked(request.id) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1425:            onInvalidated = { if (r45Direct.lease === lease && r45Direct.phase != KeyguardR45Phase.SUSPENDED)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1427:            onFirstTraversal = { at -> r45RecordStage(context, "FLUVI_STREAM", "FIRST_DRAW", at) }) { at ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1432:                KeyguardCardDiagnostics.recordR446(next)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1433:                r45RecordStage(context, "FLUVI_STREAM", "FIRST_SHADER_DRAW", at)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1439:            KeyguardCardDiagnostics.recordR446(requireNotNull(r446Observation))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1443:        r45Direct.visible(lease)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1444:        r45RecordStage(context, "FLUVI_STREAM", "REVEAL", requireNotNull(receipt.submittedAt), detail = "directSubmission")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1447:        KeyguardCardDiagnostics.recordR446(observation)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1448:        mainHandler.postDelayed({ if (r45Direct.lease === lease) r446Cancel("deadline") },
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1480:    private val r449Scope = CoroutineScope(serviceJob + Dispatchers.IO)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1533:                                KeyguardWindowSnapshotReader.Request(knownOwnOverlayIdentity,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1541:                            val classification = KeyguardSurfaceClassifier.classifyDetailed(result.snapshots,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1674:        var firstProof: KeyguardFirstAuthorizedOrb.Proof? = null // Main
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1703:    private val firstAuthorizedOrb = KeyguardFirstAuthorizedOrb(queueLock)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1767:    private val inspectionFreshness = KeyguardInspectionFreshness()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1772:        KeyguardWindowSnapshotReader(this, packageName)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1832:                r447Duplicate = null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1974:        val eligible = r448DisplayRoute == KeyguardR448DisplayRoute.FLUVI_STREAM &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2178:        val previous: KeyguardFirstAuthorizedOrb.Proof?
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2371:        if (KeyguardCardVisibilityPolicy.decide(signalsFromSystemState(settings, KeyguardSurface.MAIN_KEYGUARD, system)) !=
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2959:                    if (r448DisplayRoute == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE && r45Wa.screenOff()) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2961:                    } else if (r446Owner.state == KeyguardR446PrintOwner.State.WAIT_OFF) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2968:                    if (r449Session != null) r449PrepareSessionWake()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2983:                    if (r449Session != null) r449PrepareSessionWake()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2990:                    if (r448DisplayRoute == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2991:                        r45Wa.screenOn(session.get(), KeyguardCardDiagnostics.activeCaptureId())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:2995:                    r447RecordWakeArm()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3001:                        r448RecordBoundary(boundaryArm, receivedAt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3002:                        scheduleEvaluation("r448ScreenBoundary", triggerReceivedUptimeMs = receivedAt,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3005:                    r45TryBeginWaWake()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3013:    private var r46DisplayFacts: R46DisplayFacts? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3023:    private fun r46ReconcileDisplay() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3024:        val before = r46DisplayFacts
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3026:        r46DisplayFacts = after
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3027:        val wake = r449Wake
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3028:        val direct = r45Direct.lease
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3029:        if (wake == null && direct == null && r446Owner.state != KeyguardR446PrintOwner.State.ISSUED) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3034:        val waCurrent = wake != null && r449Current(wake, r449RestrictionRevision.get()) &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3035:            wake.allowedRevision == r449RestrictionRevision.get()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3036:        val directCurrent = direct != null && r45Direct.phase == KeyguardR45Phase.VISIBLE && r45DirectCurrent(direct)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3038:            r45RecordStage(wake?.context ?: r446Observation?.context,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3044:            r449RestrictionRevision.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3048:            r45Wa.suspend(wake.arm)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3049:            if (r448Frame?.conceal(wake.owner, "displayRecheck") != true) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3053:            r449ScheduleRead()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3055:            r45DirectRevision.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3056:            r45Direct.suspend(direct)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3060:            r45ScheduleDirectRead(direct)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3076:            r46ReconcileDisplay()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3101:        KeyguardR44Trial.set(false, false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3108:        r448DisplayRoute = KeyguardR448DisplayRouteStore.read(applicationContext)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3109:        r448RouteGeneration++
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3300:        val profile = if (r444ConfigurationReady && !r448SampleOnly) FluviKeyguardMaterialStore.read(applicationContext) else null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3358:        val eventSequence = r45IngressSequence.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3359:        val waWake = r449Wake
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3361:            val ownWa = r448Frame?.isOwnWindow(meta.windowId, meta.displayId) == true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3362:            val action = KeyguardR45IngressPolicy.decide(meta, ownWa, null, waWake.lower)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3363:            r45RecordIngress(waWake.context, "WIDGETS_ANYWHERE", eventSequence, meta, callbackReceivedAt,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3364:                ownWa, action, r45Wa.phase.name, r449RestrictionRevision.get())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3365:            if (action == KeyguardR45IngressAction.IGNORE) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3366:            if (action == KeyguardR45IngressAction.OWN_REMOVED) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3370:            r449RestrictionRevision.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3374:            r45Wa.suspend(waWake.arm)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3375:            if (r448Frame?.conceal(waWake.owner, "unclassifiedEvent") != true) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3380:            r449ScheduleRead()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3383:        val direct = r45Direct.lease
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3384:        if (direct != null && r448DisplayRoute == KeyguardR448DisplayRoute.FLUVI_STREAM) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3385:            val action = KeyguardR45IngressPolicy.decide(meta, false, direct.target.windowId, r45DirectLower)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3386:            r45RecordIngress(r446Observation?.context, "FLUVI_STREAM", eventSequence, meta, callbackReceivedAt,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3387:                false, action, r45Direct.phase.name, r45DirectRevision.get())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3388:            if (action == KeyguardR45IngressAction.IGNORE) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3389:            if (action == KeyguardR45IngressAction.TARGET_REMOVED) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3393:            r45DirectRevision.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3394:            r45Direct.suspend(direct)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3399:            r45RecordStage(r446Observation?.context, "FLUVI_STREAM", "CONCEAL", SystemClock.uptimeMillis(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3400:                revision = r45DirectRevision.get(), detail = "unclassifiedEvent")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3401:            r45ScheduleDirectRead(direct)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3404:        if (r446Owner.state == KeyguardR446PrintOwner.State.ISSUED) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3407:            val ownSampleEvent = if (r448DisplayRoute == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3408:                r448Frame?.isOwnWindow(meta.windowId, meta.displayId) == true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3419:        if (KeyguardR441RestrictionIngress.mustWithdraw(Build.VERSION.SDK_INT, meta, own,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3517:                r449FluviRecovery?.let { recovery ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3520:                        r446Owner.arm == recovery.arm && r446Owner.state == KeyguardR446PrintOwner.State.WAIT_READ &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3527:                        KeyguardCardDiagnostics.recordR449Recovery(initial.copy(stage = "REAL_CHANGE_OFFERED",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3694:        if (r448SampleOnly) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3696:            if (r448SampleOnly) return@post
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3829:        if (r442ScreenOn?.session == session.get()) r447RecordWakeArm()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3841:        r45TryBeginWaWake()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3884:    private fun r448BoundaryDecisionLocked(arm: KeyguardR446PrintOwner.Arm,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3885:                                           authority: KeyguardInspectionAuthority): KeyguardR448WakeReadBoundary.Decision {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3887:            KeyguardR448WakeReadBoundary.Work(it.id, authority.matches(it),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3890:        return KeyguardR448WakeReadBoundary.decide(work(inspectionQueue.activeRequest()),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3891:            work(inspectionQueue.pendingRequest()), r448StartedRequest, r448StartedArm == arm.generation)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3894:    private fun r448RecordBoundary(arm: KeyguardR446PrintOwner.Arm, screenAt: Long) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3899:            KeyguardR448BoundaryObservation(context, arm.generation, screenAt,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3901:                r448StartedRequest, r448StartedArm == arm.generation,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3902:                r448BoundaryDecisionLocked(arm, inspectionAuthority))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3904:        runCatching { KeyguardCardDiagnostics.recordR448Boundary(observation) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3939:                r447SystemBarrier == r447SystemSatisfied) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3940:                KeyguardR447DuplicateProof(inspectionAuthority, scene, revision, active.id, order.required,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3941:                    order.barrier, r447SystemBarrier, arm.generation, readAheadStateRevision, r18RouteRevision)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3943:            if (proof == null && r446CaptureId != null) r447SystemBarrier += 1L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3944:            r447SystemBarrier to proof
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3951:            r447SystemBarrier = sampleBarrier, r447Duplicate = duplicate))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3965:            val vetoWa = r449Wake
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3969:                    r446Owner.state in setOf(KeyguardR446PrintOwner.State.WAIT_READ, KeyguardR446PrintOwner.State.ISSUED)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3972:            if (vetoWa != null || r446Owner.state == KeyguardR446PrintOwner.State.WAIT_READ ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3973:                r446Owner.state == KeyguardR446PrintOwner.State.ISSUED) r446Cancel("systemGate")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3978:                state.interactive && state.displayOn && !state.keyguardLocked && r449Session != null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3979:                r449PrepareSessionWake()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3983:                KeyguardCardDiagnostics.recordR448SystemVeto(KeyguardR448SystemVeto(vetoContext,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3996:            if (request.r447SystemBarrier == r447SystemBarrier && request.authority == inspectionAuthority)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3997:                r447SystemSatisfied = request.r447SystemBarrier
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4016:            sampleDuplicate = request.r447Duplicate)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4148:        freshness: KeyguardWindowFreshness, sampleDuplicate: KeyguardR447DuplicateProof?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4166:        sampleDuplicate: KeyguardR447DuplicateProof? = null): Long? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4197:        if (request.trigger != "surfaceRetry" && request.trigger != "r448ScreenBoundary")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4199:        wakeTiming?.takeIf { it.wakeGeneration == request.wakeGeneration && request.trigger != "r448ScreenBoundary" }?.let {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4207:            if (trigger == "r448ScreenBoundary") {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4213:                    r446Owner.state != KeyguardR446PrintOwner.State.WAIT_READ) return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4214:                val decision = r448BoundaryDecisionLocked(arm, authority)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4215:                if (decision != KeyguardR448WakeReadBoundary.Decision.OFFER) return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4224:                    sampleDuplicate.systemBarrier == r447SystemBarrier && r447SystemBarrier == r447SystemSatisfied &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4232:                KeyguardFirstAuthorizedOrb.SampleOffer.INTERNAL_DUPLICATE else KeyguardFirstAuthorizedOrb.SampleOffer.BARRIER)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4258:        if (request.trigger == "r448ScreenBoundary") {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4461:            r448StartedRequest = request.id
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4462:            r448StartedArm = arm?.takeIf { screen != null && screen.session == request.session &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4465:            now to r448StartedArm
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4486:            inspectSurface(request, started, r38MilestoneOrdered, r40Read).also {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4492:                runCatching { KeyguardCardDiagnostics.recordR448Worker(KeyguardR448WorkerObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4511:            runCatching { KeyguardCardDiagnostics.recordR448Worker(KeyguardR448WorkerObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4538:                    KeyguardCardDiagnostics.recordR442Handoff(KeyguardR442HandoffObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4583:        runCatching { inspectionProbeForTest?.r447SampleReadCompleted(request, inspection.r446Eligibility, inspection.abortedStale) }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5482:        timing: KeyguardWindowSnapshotReader.Timing? = null, result: Inspection? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5659:        val arm: KeyguardR446PrintOwner.Arm, val request: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5662:        val systemSatisfied: Long, val inventoryAt: Long, val target: KeyguardR446Target? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5677:        val windowTiming: KeyguardWindowSnapshotReader.Timing = KeyguardWindowSnapshotReader.Timing(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5685:        val r446Arm: KeyguardR446PrintOwner.Arm? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5686:        val r446Eligibility: KeyguardR446Eligibility? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5688:        val r447Stamp: R447InventoryStamp? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5689:        val r449UnresolvedUpper: KeyguardR449RestrictionEvidence.UnresolvedUpper? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5690:        val r45Lower: List<KeyguardR45LowerWindow> = emptyList(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5713:        val timing: KeyguardWindowSnapshotReader.Timing = KeyguardWindowSnapshotReader.Timing(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5726:        val r447Stamp: R447InventoryStamp? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5764:        fun snapshot(treeElapsedMs: Long): KeyguardWindowSnapshotReader.Timing = KeyguardWindowSnapshotReader.Timing(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5785:    private fun inspectSurface(request: KeyguardCardInspectionRequest, startedAt: Long,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5794:            return InspectionOutcome.Completed(Inspection(baseline, KeyguardCardVisibilityPolicy.decide(baseline), KeyguardSurfaceReason.NO_WINDOWS))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5812:        val r44Mode = Build.VERSION.SDK_INT == 37 && settings.presentationMode == KeyguardCardPresentationMode.ORB
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5813:        val syntheticAtRead = r44Mode && KeyguardR44Trial.active
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5822:        val read = readSystemWindows(request, startedAt, r38MilestoneOrdered, r40Read, lookupAtRead,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5829:            if (r44Mode) recordR44Read(request, read, sceneAtRead, startedAt, syntheticAtRead, true,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5853:        val classification = if (r44Mode) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5854:            KeyguardR44SurfaceClassifier.classify(snapshots, read.rootUnavailable, read.walkTruncated,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5856:        } else KeyguardSurfaceClassifier.classifyDetailed(snapshots,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5859:        if (r44Mode) recordR44Read(request, read, sceneAtRead, startedAt, syntheticAtRead, false, classification,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5863:        val controlledSample = printArm != null && KeyguardR447TestHooks.CONTROLLED_TOPOLOGY &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5864:            inspectionProbeForTest?.r447ControlledSampleTopology() == true &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5868:            KeyguardR446PrintPolicy.evaluate(if (controlledSample) snapshots else read.snapshots,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5871:        val printNormal = if (printArm != null) KeyguardR44SurfaceClassifier.classify(read.snapshots,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5876:            KeyguardCardVisibilityPolicy.decide(signals),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5895:            r447Stamp = read.r447Stamp?.copy(target = printEligibility?.target),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5896:            r449UnresolvedUpper = if (printArm != null) KeyguardR449RestrictionEvidence.unresolvedUpper(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5898:                    KeyguardR44SurfaceClassifier.classify(read.snapshots, read.rootUnavailable, read.walkTruncated,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5900:            r45Lower = if (printEligibility?.target != null) KeyguardR449RestrictionEvidence.fromInventory(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5905:    private fun recordR44Read(request: KeyguardCardInspectionRequest, read: SystemWindowsRead,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5911:                              profile: KeyguardR444ProfileOwner.Snapshot? = null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5918:        val legacy = KeyguardSurfaceClassifier.classifyDetailed(windows,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5921:        val shadow = if (stale) null else KeyguardR44SurfaceClassifier.classify(windows,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5936:        fun describe(w: KeyguardWindowSnapshot): KeyguardR444WindowObservation {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5944:            return KeyguardR444WindowObservation(w.windowId, w.layer - (host?.layer ?: w.layer),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5952:        KeyguardCardDiagnostics.recordR44(KeyguardR44ReadObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5965:            windows.mapNotNull { w -> w.r44?.let { e -> KeyguardR443WindowObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5998:            showFinancialDetails = settings.showFinancialDetails && !KeyguardR44Trial.active,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6004:    private fun readSystemWindows(request: KeyguardCardInspectionRequest, startedAt: Long, r38MilestoneOrdered: Boolean,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6006:                                  profileAtRead: KeyguardR444ProfileOwner.Snapshot?, printAtRead: KeyguardR446PrintOwner.Arm?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6051:                KeyguardR442YieldPolicy.permits(Build.VERSION.SDK_INT, r442Enabled, screen?.uptime,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6060:        var r447Stamp: R447InventoryStamp? = null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6075:            request = KeyguardWindowSnapshotReader.Request(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6078:                r44Enabled = Build.VERSION.SDK_INT == 37 &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6080:                r44DeviceEntryResourceVerified = lookup.verified,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6096:                            !KeyguardR44Trial.active || r444ProfileOwner.snapshot.revision != profileAtRead?.revision) null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6190:                            r447Stamp = R447InventoryStamp(printAtRead, request.id, inspectionAuthority, scene,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6191:                                freshness?.revision, order.barrier, r447SystemBarrier, r447SystemSatisfied,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6349:            if (owner != null) KeyguardCardDiagnostics.recordR443Boundary(KeyguardR443BoundaryObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6382:            r447Stamp = r447Stamp,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6391:    private fun readSystemWindowsLegacy(request: KeyguardCardInspectionRequest): SystemWindowsRead = runCatching {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6647:        if (r448SampleOnly && !KeyguardR44Trial.active) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6649:                hideImmediately("r448SampleOnly")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6654:            if (r446Owner.state == KeyguardR446PrintOwner.State.ISSUED) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6655:            if (r448DisplayRoute != KeyguardR448DisplayRoute.WIDGETS_ANYWHERE &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6659:            if (r448DisplayRoute == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6663:            showFinancialDetails = settings.showFinancialDetails && !KeyguardR44Trial.active)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6664:        var decision = KeyguardCardVisibilityPolicy.decide(signals)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6674:            decision = KeyguardCardVisibilityPolicy.decide(signals)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6679:            traceKeyguard("INSPECTION_REJECTED", "r44SceneChanged", request,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6680:                fields = mapOf("rejectionReason" to "r44SceneChanged"))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:6681:            requestSystemCheck("r44SceneChanged")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:7051:        if (r448SampleOnly || !r444ConfigurationReady || KeyguardR44Trial.active) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:7099:        if (r448SampleOnly || !r444ConfigurationReady || KeyguardR44Trial.active) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:7133:        if (r448SampleOnly || !r444ConfigurationReady || KeyguardR44Trial.active) return
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:7292:        if (KeyguardR44Trial.active && presentation.full) return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:8078:        val profile = if (r448SampleOnly) null else FluviKeyguardMaterialStore.read(applicationContext)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:8240:        KeyguardR44Trial.set(false, false)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardEventGate.kt:45:internal object KeyguardR441RestrictionIngress {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:108:    fun r447ControlledSampleTopology(): Boolean = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:109:    fun r447SampleReadCompleted(request: KeyguardCardInspectionRequest, eligibility: KeyguardR446Eligibility?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardInspectionQueue.kt:111:    fun r447PresenterInvoked(request: Long) {}
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:480:    private val r46OfferLock = Any()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:490:        val r46: Boolean = false,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:494:        val r44Dropped = AtomicLong()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:525:        if (token?.r46 != true) return reduction.offer(work)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:526:        return synchronized(r46OfferLock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:801:        val r44Reads: ArrayDeque<KeyguardR44ReadObservation> = ArrayDeque(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:802:        var r44Last: KeyguardR44ReadObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:803:        var r44FirstPostScreen: KeyguardR44ReadObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:804:        var r44FirstGrant: KeyguardR44ReadObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:805:        var r44FirstRestriction: KeyguardR44ReadObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:806:        var r44ReadsOmitted: Int = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:807:        var r442Handoff: KeyguardR442HandoffObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:808:        var r443Boundary: KeyguardR443BoundaryObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:809:        var r446: KeyguardR446Observation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:810:        var r446Last: KeyguardR446Observation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:811:        var r447FirstEligible: KeyguardR446Observation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:812:        var r447Best: KeyguardR446Observation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:813:        var r447FirstTerminal: KeyguardR446Observation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:814:        var r447Arm: KeyguardR446Observation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:815:        var r447ArmGeneration: Long = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:816:        var r448SystemVeto: KeyguardR448SystemVeto? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:817:        var r448Boundary: KeyguardR448BoundaryObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:818:        var r448Worker: KeyguardR448WorkerObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:819:        var r448Frame: KeyguardR448FrameTrace? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:820:        var r449First: KeyguardR449AdmissionObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:821:        var r449Last: KeyguardR449AdmissionObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:822:        var r449RecoveryFirst: KeyguardR449RecoveryObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:823:        var r449RecoveryLast: KeyguardR449RecoveryObservation? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:824:        var r45Trace: KeyguardR45Trace? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:825:        var r447LatestOrdinal: Long = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:826:        var r447DecisionCount: Int = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:980:        var r449Action: String? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:981:        var r449ConfirmedRoute: String? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:982:        var r449IntentAt: Long? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:992:        var r44Dropped: Long = 0,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:993:        var r447ArmTerminal: R447ArmTerminal? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1479:    fun startCapture(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1487:        r46Request: String? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1488:        r46Route: String? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1496:        if (r46Request != null) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1498:            require(r46Route in setOf("FLUVI_STREAM", "WIDGETS_ANYWHERE"))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1499:            KeyguardR46RecordingStore.begin(context, id, requireNotNull(r46Route), r46Request)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1526:                "r448DisplayRoute" to KeyguardR448DisplayRouteStore.read(context).name,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1527:                "r448SampleOnly" to KeyguardR448Safety.sampleOnly(context).toString(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1528:                "r448WaSource" to "9c7fed25ec833197656dec57427be4c26fc66138",
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1533:                "r46Recording" to (r46Request != null).toString(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1544:            r46 = r46Request != null).also {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1557:    fun freezeCapture(context: Context): Map<String, Any?> = freezeCaptureAfterCut(context, null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1560:        val token = synchronized(r46OfferLock) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1561:            ingress?.takeIf { it.r46 }?.also {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1566:        return freezeCaptureAfterCut(context, token)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1569:    private fun freezeCaptureAfterCut(context: Context, cutToken: CaptureIngress?): Map<String, Any?> = reduction.read {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1606:            val route = frozen.configuration["r448DisplayRoute"]
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1609:                KeyguardR448ComparisonStore.save(context, route, frozen.id, report)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1749:    internal fun recordR44(observation: KeyguardR44ReadObservation) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1757:                if (active.configuration["r46Recording"] == "true")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1758:                    KeyguardR46RecordingStore.offer(active.id, "R44_READ $observation")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1763:                    token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1766:                if (attempt.r44Reads.any { it.request == observation.request }) return@synchronized
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1769:                    (attempt.r44FirstPostScreen == null || observation.start < attempt.r44FirstPostScreen!!.start))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1770:                    attempt.r44FirstPostScreen = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1772:                    observation.verdict == KeyguardSurface.MAIN_KEYGUARD && attempt.r44FirstGrant == null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1773:                    attempt.r44FirstGrant = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1776:                    attempt.r44FirstRestriction == null) attempt.r44FirstRestriction = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1777:                if (attempt.r44Reads.size < 12) attempt.r44Reads.addLast(observation)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1778:                else { attempt.r44ReadsOmitted += 1; attempt.r44Last = observation }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1781:        if (!accepted) token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1784:    internal fun recordR449Admission(observation: KeyguardR449AdmissionObservation) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1791:                if (active.configuration["r46Recording"] == "true")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1792:                    KeyguardR46RecordingStore.offer(active.id, "R449_ADMISSION $observation")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1797:                    if (attempt.r449First == null) attempt.r449First = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1798:                    attempt.r449Last = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1802:        if (!accepted) token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1805:    internal fun recordR449Intent(captureId: String, action: String, route: String, at: Long) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1811:                if (active.configuration["r46Recording"] == "true")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1812:                    KeyguardR46RecordingStore.offer(active.id, "R449_INTENT capture=$captureId action=$action route=$route up=$at")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1813:                active.r449Action = action
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1814:                active.r449ConfirmedRoute = route
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1815:                active.r449IntentAt = at
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1818:        if (!accepted) token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1821:    internal fun recordR449Recovery(observation: KeyguardR449RecoveryObservation) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1828:                if (active.configuration["r46Recording"] == "true")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1829:                    KeyguardR46RecordingStore.offer(active.id, "R449_RECOVERY $observation")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1834:                    if (attempt.r449RecoveryFirst == null) attempt.r449RecoveryFirst = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1835:                    attempt.r449RecoveryLast = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1839:        if (!accepted) token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1842:    internal fun recordR45(observation: KeyguardR45Observation) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1849:                if (active.configuration["r46Recording"] == "true")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1850:                    KeyguardR46RecordingStore.offer(active.id, "R45_EVENT $observation")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1855:                val trace = attempt.r45Trace ?: KeyguardR45Trace().also { attempt.r45Trace = it }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1883:        if (!accepted) token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1886:    internal fun recordR448Frame(observation: KeyguardR448FrameObservation) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1894:                if (active.configuration["r46Recording"] == "true")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1895:                    KeyguardR46RecordingStore.offer(active.id, "R448_FRAME $observation")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1900:                val trace = attempt.r448Frame ?: KeyguardR448FrameTrace(observation.owner).also { attempt.r448Frame = it }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1928:        if (!accepted) token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1931:    internal fun recordR448Boundary(observation: KeyguardR448BoundaryObservation) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1938:                if (active.configuration["r46Recording"] == "true")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1939:                    KeyguardR46RecordingStore.offer(active.id, "R448_BOUNDARY $observation")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1943:                    attempt.wakeEpoch == owner.originWakeEpoch && attempt.r448Boundary == null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1944:                    attempt.r448Boundary = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1947:        if (!accepted) token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1950:    internal fun recordR448Worker(observation: KeyguardR448WorkerObservation) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1957:                if (active.configuration["r46Recording"] == "true")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1958:                    KeyguardR46RecordingStore.offer(active.id, "R448_WORKER $observation")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1962:                    attempt.wakeEpoch == owner.originWakeEpoch && attempt.r448Worker == null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1963:                    attempt.r448Worker = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1966:        if (!accepted) token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1970:    internal fun recordR448SystemVeto(observation: KeyguardR448SystemVeto) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1977:                if (active.configuration["r46Recording"] == "true")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1978:                    KeyguardR46RecordingStore.offer(active.id, "R448_SYSTEM_VETO $observation")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1982:                    attempt.wakeEpoch == owner.originWakeEpoch && attempt.r448SystemVeto == null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1983:                    attempt.r448SystemVeto = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1986:        if (!accepted) token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1989:    internal fun recordR446(observation: KeyguardR446Observation) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1996:                if (active.configuration["r46Recording"] == "true")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1997:                    KeyguardR46RecordingStore.offer(active.id, "R446_OUTPUT $observation")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2002:                    if (observation.armGeneration > 0 && attempt.r447ArmGeneration > 0 &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2003:                        observation.armGeneration != attempt.r447ArmGeneration) return@synchronized
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2004:                    if (observation.armGeneration > 0) attempt.r447ArmGeneration = observation.armGeneration
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2008:                        if (attempt.r447Arm == null || (attempt.r447Arm?.wakeArmState != "ARMED" &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2009:                                observation.wakeArmState == "ARMED")) attempt.r447Arm = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2010:                        if (observation.withdrawAt != null && attempt.r447FirstTerminal == null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2011:                            attempt.r447FirstTerminal = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2016:                    if (observation.eligibility == "ELIGIBLE_SAMPLE" && attempt.r447FirstEligible == null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2017:                        attempt.r447FirstEligible = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2019:                    if (ordinal > attempt.r447LatestOrdinal) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2020:                        attempt.r447LatestOrdinal = ordinal
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2021:                        attempt.r447DecisionCount = (attempt.r447DecisionCount + 1).coerceAtMost(9999)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2023:                    } else if (ordinal == attempt.r447LatestOrdinal &&
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2025:                    fun progress(o: KeyguardR446Observation): Int = when {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2032:                    val best = attempt.r447Best
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2035:                        attempt.r447Best = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2036:                    if (observation.withdrawAt != null && attempt.r447FirstTerminal == null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2037:                        attempt.r447FirstTerminal = observation
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2041:        if (!accepted) token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2046:    internal fun recordR447ArmTerminal(captureId: String, generation: Long, at: Long, reason: String) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2052:                if (active.configuration["r46Recording"] == "true")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2053:                    KeyguardR46RecordingStore.offer(active.id, "R447_TERMINAL generation=$generation up=$at reason=${technicalValue(reason).take(80)}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2054:                if (active.r447ArmTerminal == null)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2055:                    active.r447ArmTerminal = R447ArmTerminal(generation, at, technicalValue(reason).take(80))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2058:        if (!accepted) token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2061:    internal fun recordR442Handoff(observation: KeyguardR442HandoffObservation) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2068:                if (active.configuration["r46Recording"] == "true")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2069:                    KeyguardR46RecordingStore.offer(active.id, "R442_HANDOFF $observation")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2077:        if (!accepted) token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2080:    internal fun recordR443Boundary(observation: KeyguardR443BoundaryObservation) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2087:                if (active.configuration["r46Recording"] == "true")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2088:                    KeyguardR46RecordingStore.offer(active.id, "R443_BOUNDARY $observation")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2096:        if (!accepted) token.r44Dropped.incrementAndGet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2141:                if (active.configuration["r46Recording"] == "true")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2142:                    KeyguardR46RecordingStore.offer(active.id, row.trim())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2467:        if (active.configuration["r46Recording"] == "true")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2468:            KeyguardR46RecordingStore.offer(active.id, "EVENT ${event.toLine(compact = false)}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3065:        if (active.configuration["r46Recording"] == "true") return false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3102:            val report = formatReport(snapshot, recoveredFromDisk = false, exportLimitBytes = 32 * 1024)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3302:        r44Dropped = r41Token?.r44Dropped?.get() ?: active.r44Dropped,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3311:        r448Frame = attempt.r448Frame?.copy(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3312:        r44Reads = ArrayDeque(attempt.r44Reads),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3368:        val report = formatReport(active, recoveredFromDisk = false, exportLimitBytes = 32 * 1024)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3412:    private fun formatReport(active: TimingCapture, recoveredFromDisk: Boolean, exportLimitBytes: Int): String {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3428:            if (Build.VERSION.SDK_INT == 37) appendLine("R44_CAPTURE dropped=${active.r44Dropped} physicalPixels=UNOBSERVED")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3547:        active.r447ArmTerminal?.let { terminal ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3548:            select("r447:armTerminal", "R44_7_ARM generation=${terminal.generation} terminal=${terminal.at}/${terminal.reason} clock=uptimeMs\n")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3550:        val r44Attempts = (listOfNotNull(active.firstAttempt) + active.attempts).distinctBy { it.id }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3551:        r44Attempts.forEach { attempt ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3552:            val route = active.configuration["r448DisplayRoute"] ?: "UNOBSERVED"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3553:            val action = active.r449Action ?: if (active.configuration["r446PrintRequested"] == "true") "LEGACY_ONE_WAKE" else "PASSIVE"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3554:            val progress = attempt.r447Best ?: attempt.r446Last ?: attempt.r446
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3555:            val terminal = attempt.r447FirstTerminal
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3563:            select("a${attempt.id}:r449outcome", "R44_9_OUTCOME capture=${active.id} wake=${attempt.wakeEpoch} routeRequested=$route routeConfirmed=${active.r449ConfirmedRoute ?: "UNOBSERVED"} action=$action intent=${active.r449IntentAt ?: "UNOBSERVED"} arm=${attempt.r447Arm?.wakeArmState ?: "UNOBSERVED"} backend=${progress?.backend ?: "NOT_ATTEMPTED"} issue=${progress?.issuedAt ?: "UNOBSERVED"} frame=${progress?.frameAt ?: "UNOBSERVED"} terminal=${terminal?.withdrawReason ?: "UNOBSERVED"} physical=UNOBSERVED clock=uptimeMs\nR44_9_HU $status\n", attempt.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3564:            attempt.r45Trace?.let { t ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3573:                select("a${attempt.id}:r45life", "R45_LIFECYCLE wake=${attempt.wakeEpoch} route=${active.r449ConfirmedRoute ?: "UNOBSERVED"} shape=${t.shape ?: "UNOBSERVED"} attachedHidden=${t.attachedHidden ?: "UNOBSERVED"} postCheck=${t.postCheckBegin ?: "UNOBSERVED"}/${t.postCheckEnd ?: "UNOBSERVED"}/${t.postCheckResult ?: "UNOBSERVED"} reveal=${t.reveal ?: "UNOBSERVED"} revealState=${t.revealState ?: "UNOBSERVED"} firstDraw=${t.firstDraw ?: "UNOBSERVED"} firstShader=${t.firstShader ?: "UNOBSERVED"} conceal=${t.conceal ?: "UNOBSERVED"} remove=${t.remove ?: "UNOBSERVED"} ignored=${t.ignored} unknown=${t.unknown} terminalEvents=${t.terminalEvents} suspended=${t.suspended} resumed=${t.resumed} terminal=${stopped?.detail ?: "UNOBSERVED"} terminalAt=${stopped?.at ?: "UNOBSERVED"} optical=UNOBSERVED clock=uptimeMs\nR45_HU $hu\n", attempt.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3574:                if (first != null) select("a${attempt.id}:r45event", "R45_EVENT wake=${attempt.wakeEpoch} seq=${first.sequence ?: "UNOBSERVED"} source=${first.sourceAt ?: "UNOBSERVED"} received=${first.at} type=${first.eventType ?: "UNOBSERVED"} mask=${first.changes ?: "UNOBSERVED"} window=${first.window ?: "UNOBSERVED"} display=${first.display ?: "UNOBSERVED"} origin=${first.attribution} decision=${first.decision} phase=${first.phase} revision=${first.revision} clock=uptimeMs\n", attempt.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3575:                if (recovery != null) select("a${attempt.id}:r45recovery", "R45_RECOVERY wake=${attempt.wakeEpoch} route=${recovery.route} revision=${recovery.revision} read=${recovery.readStart ?: "UNOBSERVED"}/${recovery.readEnd ?: "UNOBSERVED"} result=${recovery.decision} reason=${recovery.detail} clock=uptimeMs\n", attempt.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3577:            listOfNotNull(attempt.r449RecoveryFirst, attempt.r449RecoveryLast).distinct().forEachIndexed { index, r ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3578:                select("a${attempt.id}:r449retry:$index", "R44_9_FLUVI_RECOVERY wake=${r.wake} arm=${r.arm} initialReq=${r.initialRequest} host=${r.host} upper=${r.upper} inventory=${r.inventoryAt} stage=${r.stage} at=${r.at} successor=${r.successor ?: "UNOBSERVED"} clock=uptimeMs\n", attempt.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3580:            listOfNotNull(attempt.r449First, attempt.r449Last).distinct().forEachIndexed { index, o ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3583:                    attempt.r448Frame?.firstShader != null -> "Widgets Anywhere: a mintaablak rajzolt; a képernyőn való láthatóság nem mért."
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3584:                    o.decision == KeyguardR448Admission.Decision.ALLOW -> "Widgets Anywhere: a minta engedélyezve; a láthatóság nem mért."
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3587:                select("a${attempt.id}:r449:$index", "R44_9_HU $summary\nR44_9_ADMISSION wake=${attempt.wakeEpoch} arm=${o.arm} routeRequested=WIDGETS_ANYWHERE routeConfirmed=WIDGETS_ANYWHERE routeGeneration=${o.routeGeneration} materialGeneration=${o.materialGeneration} restrictionRevision=${o.restrictionRevision} domain=PUBLIC_SAMPLE action=${o.action} screenOn=${o.screenAt} readStart=${o.readStart} readEnd=${o.readEnd} systemRead=${o.system.startedAt}/${o.system.finishedAt} available=${o.system.available} interactive=${o.system.interactive} displayOn=${o.system.displayOn} locked=${o.system.keyguardLocked} credential=${e.credential} shade=${e.shade} foreign=${e.foreign} power=${e.powerMenu} evidenceAt=${e.observedAt} reason=${o.reason} decision=${o.decision} issue=${o.issueAt ?: "UNOBSERVED"} physical=UNOBSERVED clock=uptimeMs\n", attempt.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3589:            attempt.r448Frame?.let { f ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3590:                select("a${attempt.id}:r448frame", "R44_8_WA wake=${attempt.wakeEpoch} routeGeneration=${f.owner.route} materialGeneration=${f.owner.material} firstAllowed=${f.firstAllowed ?: "UNOBSERVED"} debounceScheduled=${f.scheduled ?: "UNOBSERVED"} requestedDue=${f.scheduled?.plus(50) ?: "UNOBSERVED"} debounceFired=${f.fired ?: "UNOBSERVED"} debounceCanceled=${f.canceled ?: "UNOBSERVED"} coalesced=${f.coalesced} secondAllowed=${f.secondAllowed ?: "UNOBSERVED"} addBegin=${f.addBegin ?: "UNOBSERVED"} addReturn=${f.addReturn ?: "UNOBSERVED"} attached=${f.attached ?: "UNOBSERVED"} firstShader=${f.firstShader ?: "UNOBSERVED"} hide=${f.hide ?: "UNOBSERVED"} removeReturn=${f.removeReturn ?: "UNOBSERVED"} detached=${f.detached ?: "UNOBSERVED"} geometry=${f.geometry ?: "UNOBSERVED"} terminal=${f.terminal ?: "UNOBSERVED"} terminalAt=${f.terminalAt ?: "UNOBSERVED"} physical=UNOBSERVED clock=uptimeMs\n", attempt.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3592:            attempt.r448Boundary?.let { b ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3593:                val w = attempt.r448Worker
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3594:                select("a${attempt.id}:r448boundary", "R44_8_READ_BOUNDARY wake=${attempt.wakeEpoch} arm=${b.arm} screenOn=${b.screenAt} active=${b.active ?: "UNOBSERVED"} pending=${b.pending ?: "UNOBSERVED"} started=${b.started ?: "UNOBSERVED"} startedForArm=${b.startedForArm} boundaryDecision=${b.decision} workerRequest=${w?.request ?: "UNOBSERVED"} workerQueued=${w?.queued ?: "UNOBSERVED"} workerStart=${w?.started ?: "UNOBSERVED"} workerEnd=${w?.finished ?: "UNOBSERVED"} workerOutcome=${w?.outcome ?: "UNOBSERVED"} eligibility=${w?.eligibility ?: "UNOBSERVED"} authorityAtEnd=${w?.authorityAtEnd ?: "UNOBSERVED"} clock=uptimeMs\n", attempt.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3596:            attempt.r448SystemVeto?.let { v ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3598:                select("a${attempt.id}:r448gate", "R44_8_SYSTEM_VETO wake=${attempt.wakeEpoch} arm=${v.armGeneration} request=${v.requestId} requestCaptureMatched=${v.requestCaptureMatched} reason=${technicalValue(v.reason)} screenOn=${v.screenOnAt ?: "UNOBSERVED"} received=${v.receivedAt} queued=${v.queuedAt} readStart=${s.startedAt} readEnd=${s.finishedAt} main=${v.mainAt} available=${s.available} primaryDisplay=${s.primaryDisplay} interactive=${s.interactive} displayOn=${s.displayOn} displayOff=${s.displayOff} keyguardLocked=${s.keyguardLocked} userUnlocked=${s.userUnlocked} excluded=${s.excluded} clock=uptimeMs\n", attempt.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3602:        r44Attempts.forEach { attempt ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3606:                    val armState = attempt.r447Arm?.wakeArmState ?: "UNOBSERVED"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3612:                    val terminal = attempt.r447FirstTerminal
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3613:                    select("a${attempt.id}:r446", "R44_6_HU $message\nR44_6_SAMPLE wake=${attempt.wakeEpoch} arm=UNOBSERVED firstReq=UNOBSERVED firstNormal=UNOBSERVED firstEligible=UNOBSERVED firstBackend=NOT_ATTEMPTED req=UNOBSERVED normal=UNOBSERVED eligible=UNOBSERVED backend=NOT_ATTEMPTED host=UNOBSERVED scene=UNOBSERVED issue=UNOBSERVED attachBegin=UNOBSERVED attachEnd=UNOBSERVED submit=UNOBSERVED frame=UNOBSERVED withdraw=${terminal?.withdrawAt ?: "UNOBSERVED"}/${terminal?.withdrawReason ?: "UNOBSERVED"} hideReturn=${terminal?.hideReturn ?: "UNOBSERVED"} releaseReturn=${terminal?.releaseReturn ?: "UNOBSERVED"} retireError=${terminal?.retireError ?: "none"} armState=$armState physical=UNOBSERVED clock=uptimeMs\n", attempt.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3618:            val p = attempt.r447Best ?: o
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3619:            val terminal = attempt.r447FirstTerminal ?: p
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3627:            select("a${attempt.id}:r446", "R44_6_HU $status\nR44_6_SAMPLE wake=${o.wake} arm=${o.armAt} firstReq=${first.request} firstNormal=${first.normal} firstEligible=${first.eligibility} firstBackend=${first.backend} req=${o.request} normal=${o.normal} eligible=${o.eligibility} backend=${o.backend} host=${o.host ?: "UNOBSERVED"} scene=${o.scene ?: "UNOBSERVED"} issue=${p.issuedAt ?: "UNOBSERVED"} attachBegin=${p.attachBegin ?: "UNOBSERVED"} attachEnd=${p.attachEnd ?: "UNOBSERVED"} submit=${p.submittedAt ?: "UNOBSERVED"} frame=${p.frameAt ?: "UNOBSERVED"} withdraw=${terminal.withdrawAt ?: "UNOBSERVED"}/${terminal.withdrawReason} hideReturn=${terminal.hideReturn ?: "UNOBSERVED"} releaseReturn=${terminal.releaseReturn ?: "UNOBSERVED"} retireError=${terminal.retireError ?: "none"} firstEligibleReq=${attempt.r447FirstEligible?.request ?: "UNOBSERVED"} firstEligibleHandoff=${attempt.r447FirstEligible?.handoff ?: "UNOBSERVED"} firstHandoff=${first.handoff} progressReq=${p.request} terminalReq=${if (terminal.withdrawAt != null) terminal.request else "UNOBSERVED"} decisions=${attempt.r447DecisionCount} ordinal=${o.decisionOrdinal} handoff=${o.handoff} order=${o.order?.result ?: "UNOBSERVED"} completed=${o.order?.completed ?: "UNOBSERVED"} required=${o.order?.required ?: "UNOBSERVED"} barrier=${o.order?.barrier ?: "UNOBSERVED"} origin=${o.order?.origin ?: "UNOBSERVED"} sceneNow=${o.order?.scene ?: "UNOBSERVED"} inventory=${o.inventoryAt ?: "UNOBSERVED"} readEnd=${o.readFinishedAt ?: "UNOBSERVED"} mainEntry=${o.mainEnteredAt ?: "UNOBSERVED"} decide=${o.decisionAt ?: "UNOBSERVED"} freshness=${o.freshnessRevision ?: "UNOBSERVED"} sysAtRead=${o.systemBarrierAtRead ?: "UNOBSERVED"} sysNow=${o.systemBarrierAtDecision ?: "UNOBSERVED"} owner=${o.ownerState} physical=UNOBSERVED clock=uptimeMs\n", attempt.id)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3629:        r44Attempts.filter { it.r44Reads.isNotEmpty() ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3631:            select("a${attempt.id}:r44Core", r44Record(active.id, attempt,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3984:            selected.filterKeys { it.endsWith(":r44Core") }.values.forEach(::append)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:3990:            selected.filterKeys { !it.endsWith(":summary") && !it.endsWith(":r44Core") && !it.endsWith(":spineRows") && !it.endsWith(":raw") && ":drawGap:" !in it }.values.forEach(::append)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4004:    private fun r44Record(captureId: String, attempt: TimingAttempt, trialRequested: Boolean): String = buildString {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4005:        val reads = attempt.r44Reads.toList()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4007:        val post = attempt.r44FirstPostScreen ?: screen?.let { t -> reads.filter {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4010:        val last = attempt.r44Last ?: reads.lastOrNull()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4015:        appendLine("R44_HU próba=${attempt.id} eredmény=$outcome első_ébredés_utáni_olvasás=${post?.request ?: "HIÁNYZIK"} fizikailag_látható=ISMERETLEN")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4016:        if (!trialRequested) appendLine("R44_2_HU A mintaorb-próba nem volt elindítva; ez csak rögzítés.")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4018:            appendLine("R44_2_HU FIGYELEM: a mintaorb-próba visszaigazolása vagy üzemmódja elveszett.")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4020:        appendLine("R44_2_TRIAL requested=$trialRequested receipt=${post?.receipt ?: "UNOBSERVED"} domain=$domain")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4028:            post.appliedGate == KeyguardR444Gate.COVER_VETO -> "Az elfogadott jel mellett egy másik ablak kizárja a megjelenítést."
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4029:            post.reason == KeyguardSurfaceReason.NO_MAIN_MARKER || post.appliedGate == KeyguardR444Gate.NO_CONTENT ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4037:        appendLine("R44_4_HU próba=${attempt.id} $reasonHu" +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4038:            if (additionalWindow && post?.appliedGate != KeyguardR444Gate.COVER_VETO)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4043:                post.appliedGate == KeyguardR444Gate.RESTRICTION -> "Tiltott képernyő: rejtve."
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4045:                post.appliedGate == KeyguardR444Gate.COVER_VETO && companion ->
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4047:                post.appliedGate == KeyguardR444Gate.COVER_VETO -> "Jel megvan; a felső ablak nem minősíthető."
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4052:            appendLine("R44_5_HU próba=${attempt.id} $status")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4056:            listOfNotNull(post, attempt.r44FirstGrant, attempt.r44FirstRestriction, last)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4059:        appendLine("R44_2_HANDOFF old=${handoff?.oldRequest ?: "UNOBSERVED"} next=${handoff?.nextRequest ?: "UNOBSERVED"} screen=${handoff?.screenAt ?: "UNOBSERVED"} offer=${handoff?.offerAt ?: "UNOBSERVED"} oldStart=${handoff?.oldStart ?: "UNOBSERVED"} boundary=${handoff?.boundaryAt ?: "UNOBSERVED"} oldReturn=${handoff?.oldReturn ?: "UNOBSERVED"} where=${handoff?.boundary ?: "UNOBSERVED"} newStart=${successorRead?.start ?: "UNOBSERVED"} newEnd=${successorRead?.end ?: "UNOBSERVED"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4061:        appendLine("R44_3_BOUNDARY old=${boundary?.oldRequest ?: "UNOBSERVED"} pending=${boundary?.pendingRequest ?: "UNOBSERVED"} screen=${boundary?.screenAt ?: "UNOBSERVED"} offer=${boundary?.offerAt ?: "UNOBSERVED"} oldStart=${boundary?.oldStart ?: "UNOBSERVED"} at=${boundary?.boundaryAt ?: "UNOBSERVED"} oldEnd=${boundary?.oldEnd ?: "UNOBSERVED"} reason=${boundary?.reason ?: "UNOBSERVED"} ingress=${boundary?.ingressKind ?: "UNOBSERVED"}/${boundary?.ingressStart ?: "UNOBSERVED"}/${boundary?.ingressEnd ?: "UNOBSERVED"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4062:        appendLine("R44_WAKE capture=$captureId session=${attempt.serviceSession} wake=${attempt.wakeEpoch} screenOn=${screen ?: "UNOBSERVED"} firstPostRead=${post?.request ?: "missing"} omitted=${attempt.r44ReadsOmitted} showRequest=${show?.requestId ?: "none"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4063:        fun line(kind: String, read: KeyguardR44ReadObservation) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4067:                appendLine("R44_READ kind=$kind wake=${attempt.wakeEpoch} req=${read.request} start=${read.start} end=${read.end} verdict=${read.verdict} reason=${read.reason} stale=${read.stale}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4070:            appendLine("R44_READ kind=$kind wake=${attempt.wakeEpoch} req=${read.request} epoch=${read.epoch} scene=${read.scene ?: "UNOBSERVED"} start=${read.start} end=${read.end} owner=${if (read.hostVerified) "verified" else "rejected"} hostWin=${read.hostWindow ?: "UNOBSERVED"} hostLayer=${read.hostLayer ?: "UNOBSERVED"} complete=${read.coverageComplete} legacy=${read.legacy} host=${host?.marker ?: "none"}/${host?.carrier ?: "none"} content=${content?.marker ?: "none"}/${content?.carrier ?: "none"} relation=${if (read.relation) "descendant" else "unknown"} extra=${read.advertised}/${read.fetched}/${read.failed} unsupported=${read.unsupported} budgetHit=${read.budgetHit} extraMs=${read.extraMs} stale=${read.stale} unavailable=${read.unavailable} truncated=${read.truncated}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4075:                appendLine("R44_3_ABLAK req=${read.request} window:advertised/fetched/overflow:state=$windowSummary")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4077:                    appendLine("R44_3_JEL req=${read.request} window=${c.window} ordinal=${c.ordinal} branch=${c.branch} rank=${c.rank} status=${c.status} role=${c.role} costMs=${c.costMs} remaining=${c.remaining} remainingMs=${c.remainingMs} parentChecks=${c.parentChecks} parentMs=${c.parentMs}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4081:                KeyguardR444Gate.COVER_VETO -> "VETO"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4082:                KeyguardR444Gate.ACCEPTED -> "CLEAR"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4085:            appendLine("R44_4_PROFILE req=${read.request} profile=${read.profile} revision=${read.profileRevision ?: "UNOBSERVED"} previousFlags=${read.previousFlags ?: "UNOBSERVED"} actualFlags=${read.actualFlags ?: "UNOBSERVED"} clockResource=${read.clockResourceVerified} hostNodes=${read.hostNodes} hostCarriers=${read.hostCarriers} hostParent=${read.hostParent ?: "UNOBSERVED"} contentParent=${read.contentParent ?: "UNOBSERVED"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4086:            appendLine("R44_4_GATE req=${read.request} applied=${read.appliedGate} coverReached=$coverReached structural=${read.cover} secondary=${read.secondaryCount} overflow=${read.secondaryOverflow}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4088:            appendLine("R44_5_INDEX req=${read.request} installedSmall=${read.r445SmallInstalled} installedLarge=${read.r445LargeInstalled} installedEntry=${read.r445EntryInstalled} status=${read.r445IndexStatus} backend=$backend pixel=UNOBSERVED")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4090:                appendLine("R44_5_ID req=${read.request} role=${call.role} outcome=${call.outcome} hitsCap9=${call.rawHits} reject=${call.firstRejection} durationMs=${call.durationMs} ageMs=${call.ageMs} overrunMs=${call.overrunMs}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4093:                appendLine("R44_4_WINDOW req=${read.request} id=${w.id} relativeLayer=${w.relativeLayer} type=${w.type} active=${w.active ?: "UNOBSERVED"} focused=${w.focused ?: "UNOBSERVED"} owner=${w.owner} ownGen=${w.ownGeneration ?: "UNOBSERVED"} verified=${w.verifiedRoot} visited=${w.visited ?: "UNOBSERVED"} root=${w.rootRole}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4095:            appendLine("R44_DECISION wake=${attempt.wakeEpoch} req=${read.request} mode=${if (read.synthetic) "syntheticTrial" else "normal"} testProbeInjected=${read.testProbeInjected} verdict=${read.verdict} reason=${read.reason}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4096:            appendLine("R44_2_EVIDENCE req=${read.request} lookup=${read.lookupStatus} lookupIdentity=${read.lookupIdentity ?: "UNOBSERVED"} rawHost=${read.rawHost} rawEntry=${read.rawEntry} rawClock=${read.rawClock} candidate=${read.firstCandidate ?: "none"}/${read.firstCarrier ?: "none"} rejectUnverified=${read.rejectedUnverified} rejectAncestry=${read.rejectedAncestry} rejectExcluded=${read.rejectedExcluded} rejectForeign=${read.rejectedForeign} rejectHidden=${read.rejectedHidden} cover=${read.cover} shadow=${read.shadowVerdict ?: "UNOBSERVED"}/${read.shadowReason ?: "UNOBSERVED"}")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4101:        fun unique(kind: String, read: KeyguardR44ReadObservation?) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4104:        unique("firstMainClassification", attempt.r44FirstGrant)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4105:        unique("firstRestrictionClassification", attempt.r44FirstRestriction)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:4108:        appendLine("R44_END wake=${attempt.wakeEpoch} last=${attempt.finalState} grant=${show?.decisionAtUptimeMs ?: "UNOBSERVED"} attach=${show?.addReturnAtUptimeMs ?: "UNOBSERVED"} post=${show?.r12Evidence?.get("firstPost") ?: "UNOBSERVED"} postDelivery=${show?.r12Evidence?.get("firstPostMain") ?: "UNOBSERVED"} ack=${show?.r11Evidence?.get("ack") ?: "UNOBSERVED"} remove=${hide?.removeReturnAtUptimeMs ?: "UNOBSERVED"} physicalPixels=UNOBSERVED")
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
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446PrintPolicy.kt:86:              target: KeyguardR446Target, now: Long): Ticket? {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:26:internal class KeyguardR446WindowPresenter(private val service: AccessibilityService,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:37:    private var r46PublicTelemetry = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:43:    fun preparePublic(display: Display, sample: KeyguardR46PublicMaterial, artifact: KeyguardShaderArtifact,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:46:        r46PublicTelemetry = prepared
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:123:    fun show(token: Any, target: KeyguardR446Target, geometry: KeyguardOverlayGeometry,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:173:        if (r46PublicTelemetry) material.beginR46SampleInterval()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR446WindowPresenter.kt:245:        r46PublicTelemetry = false
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
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:30:internal class KeyguardR448WidgetsAnywhereFrame(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:48:    private var r46PublicTelemetry = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:49:    private val openingDelay = KeyguardR46OpeningDelay()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:102:    fun preparePublic(owner: Owner, sample: KeyguardR46PublicMaterial,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:106:        r46PublicTelemetry = prepared
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:271:        if (r46PublicTelemetry) material.beginR46SampleInterval()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR448WidgetsAnywhereFrame.kt:383:        r46PublicTelemetry = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidence.kt:8:internal object KeyguardR449RestrictionEvidence {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidence.kt:9:    data class Result(val exclusions: KeyguardR448Admission.Exclusions, val reason: String,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidence.kt:10:                      val lower: List<KeyguardR45LowerWindow> = emptyList())
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidence.kt:17:        if (truncated || classification.r444Gate != KeyguardR444Gate.INCOMPLETE) return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidence.kt:33:                .any { it == KeyguardR448Admission.Presence.PRESENT }) return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidence.kt:39:        val P = KeyguardR448Admission.Presence.PRESENT
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidence.kt:40:        val U = KeyguardR448Admission.Presence.UNKNOWN
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidence.kt:41:        val C = KeyguardR448Admission.Presence.CLEAR
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidence.kt:45:        val markers = ids.mapNotNull(KeyguardR44Markers::exact).toSet()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidence.kt:46:        val legacy = KeyguardSurfaceClassifier.classifyDetailed(primary,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidence.kt:48:        val credential = KeyguardR44Markers.Marker.BOUNCER in markers ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidence.kt:50:        val shade = KeyguardR44Markers.Marker.SHADE in markers ||
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidence.kt:51:            KeyguardR44Markers.Marker.QUICK_SETTINGS in markers || legacy.surface == KeyguardSurface.SHADE
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidence.kt:74:        val result = KeyguardR448Admission.Exclusions(at, value(credential), value(shade), value(foreign), value(power))
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR449RestrictionEvidence.kt:91:            .take(8).map { KeyguardR45LowerWindow(it.windowId, it.displayId, requireNotNull(it.packageName)) }.toList()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:4:internal data class KeyguardR449AdmissionObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:8:    val exclusions: KeyguardR448Admission.Exclusions, val reason: String,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:9:    val decision: KeyguardR448Admission.Decision, val issueAt: Long?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:14:internal data class KeyguardR449RecoveryObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:20:internal data class KeyguardR448FrameObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:21:    val context: KeyguardDiagnosticContext, val owner: KeyguardR448WidgetsAnywhereFrame.Owner,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:26:internal data class KeyguardR448FrameTrace(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:27:    val owner: KeyguardR448WidgetsAnywhereFrame.Owner,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:37:internal data class KeyguardR448BoundaryObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:40:    val startedForArm: Boolean, val decision: KeyguardR448WakeReadBoundary.Decision,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:43:internal data class KeyguardR448WorkerObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:51:internal data class KeyguardR448SystemVeto(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:65:internal data class KeyguardR445IndexCall(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:73:internal data class KeyguardR446Observation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:81:    val handoff: KeyguardR447Disposition = KeyguardR447Disposition.UNOBSERVED,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:82:    val order: KeyguardFirstAuthorizedOrb.SampleOrder? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:91:    fun retireOnce(at: Long, reason: String, hide: Long?, release: Long?, error: String?): KeyguardR446Observation =
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:98:internal data class KeyguardR443CandidateObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:103:internal data class KeyguardR443WindowObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:108:internal data class KeyguardR444WindowObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:114:internal data class KeyguardR44ReadObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:132:    val host: KeyguardR44Witness?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:133:    val content: KeyguardR44Witness?,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:154:    val firstCandidate: KeyguardR44Markers.Marker? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:155:    val firstCarrier: KeyguardR44Markers.Carrier? = null,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:158:    val r443Windows: List<KeyguardR443WindowObservation> = emptyList(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:159:    val r443Candidates: List<KeyguardR443CandidateObservation> = emptyList(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:160:    val appliedGate: KeyguardR444Gate = KeyguardR444Gate.UNOBSERVED,
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:167:    val r444Windows: List<KeyguardR444WindowObservation> = emptyList(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:170:    val r445IndexCalls: List<KeyguardR445IndexCall> = emptyList(),
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:173:internal data class KeyguardR442HandoffObservation(
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR44ReadObservation.kt:186:internal data class KeyguardR443BoundaryObservation(
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
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:171:internal object KeyguardR45IngressPolicy {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:173:               lower: List<KeyguardR45LowerWindow> = emptyList()): KeyguardR45IngressAction {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:174:        if (meta.displayId != Display.DEFAULT_DISPLAY && meta.displayId >= 0) return KeyguardR45IngressAction.IGNORE
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:175:        if (meta.displayId < 0) return KeyguardR45IngressAction.REASSESS
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:178:            if (exactOwn) return KeyguardR45IngressAction.OWN_REMOVED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:179:            if (targetWindow != null && meta.windowId == targetWindow) return KeyguardR45IngressAction.TARGET_REMOVED
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:182:            return KeyguardR45IngressAction.IGNORE
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:185:            return KeyguardR45IngressAction.IGNORE
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:188:            return KeyguardR45IngressAction.IGNORE
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR45Presentation.kt:189:        return KeyguardR45IngressAction.REASSESS
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR46RecordingStore.kt:16:internal object KeyguardR46RecordingStore {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR46RecordingStore.kt:17:    private const val PREFS = "fluvi_r46_recording"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR46RecordingStore.kt:18:    private val writer = Executors.newSingleThreadExecutor { r -> Thread(r, "fluvi-r46-spool").apply { isDaemon = true } }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR46RecordingStore.kt:31:    private fun dir(context: Context) = File(context.applicationContext.filesDir, "r46-recordings")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR46RecordingStore.kt:107:            line("FLUVI_R46_RECORDING_V1")
android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR46RecordingStore.kt:123:            output.write("bodyBytes=$bodyBytes bodySha256=$hash\nEND_FLUVI_R46_RECORDING_V1\n".toByteArray(Charsets.UTF_8))
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
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:245:    private var r46SampleActive = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:246:    private var r46SampleStartedAt = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:247:    private var r46FirstFrameNs = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:248:    private var r46SecondFrameNs = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:249:    private var r46FirstPhase = Float.NaN
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:250:    private var r46SecondPhase = Float.NaN
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:251:    private var r46LastDrawAt = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:252:    private var r46MaxGap = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:253:    private var r46ShaderFrames = 0
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:254:    private var r46FallbackFrames = 0
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:255:    private var r46CircleFrames = 0
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:258:        r46SampleActive = true
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:259:        r46SampleStartedAt = SystemClock.uptimeMillis()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:260:        r46FirstFrameNs = 0L; r46SecondFrameNs = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:261:        r46FirstPhase = Float.NaN; r46SecondPhase = Float.NaN
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:262:        r46LastDrawAt = 0L; r46MaxGap = 0L
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:263:        r46ShaderFrames = 0; r46FallbackFrames = 0; r46CircleFrames = 0
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:266:    private fun r46CountDraw() {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:268:        if (r46LastDrawAt > 0L) r46MaxGap = maxOf(r46MaxGap, at - r46LastDrawAt)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:269:        r46LastDrawAt = at
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:273:        if (!r46SampleActive) return null
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:274:        r46SampleActive = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:275:        val second = if (r46SecondFrameNs == 0L) "UNOBSERVED" else r46SecondFrameNs.toString()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:277:            r46ShaderFrames == 0 -> "NO_SHADER_FRAME"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:278:            r46ShaderFrames == 1 -> "ONE_SHADER_FRAME"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:279:            r46SecondFrameNs == 0L -> "NO_DISTINCT_PHASE"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:282:        return "palette=compiled_public_v1 start=$r46SampleStartedAt end=${SystemClock.uptimeMillis()} " +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:283:            "shader=$r46ShaderFrames fallback=$r46FallbackFrames circle=$r46CircleFrames " +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:284:            "firstFrameNs=${if (r46FirstFrameNs == 0L) "UNOBSERVED" else r46FirstFrameNs} " +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:285:            "firstPhase=$r46FirstPhase secondFrameNs=$second secondPhase=$r46SecondPhase " +
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:286:            "secondReason=$missingSecond maxGapMs=$r46MaxGap frameClock=choreographer"
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:320:    private val r45CirclePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:321:    private var r45DiagnosticCircle = false
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:325:        r45DiagnosticCircle = enabled
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:684:        if (r45DiagnosticCircle) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:685:            if (r46SampleActive) { r46CircleFrames++; r46CountDraw() }
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:686:            drawKeyguardOrbCircle(canvas, r45CirclePaint, width, height)
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:768:        if (r46SampleActive && scene === current && alpha > 0f) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:769:            r46ShaderFrames++
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:770:            r46CountDraw()
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:771:            if (r46FirstFrameNs == 0L) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:772:                r46FirstFrameNs = frameNanos; r46FirstPhase = time.phase
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:773:            } else if (r46SecondFrameNs == 0L && frameNanos != r46FirstFrameNs && time.phase != r46FirstPhase) {
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:774:                r46SecondFrameNs = frameNanos; r46SecondPhase = time.phase
android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt:801:        if (r46SampleActive) { r46FallbackFrames++; r46CountDraw() }
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

```
